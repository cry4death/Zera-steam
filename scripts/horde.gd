class_name Horde
extends Node2D
## Орда: каждый зомби — строка в packed-массивах, без отдельных нод.
## Движение к игроку, расталкивание через spatial hash, рендер одним MultiMesh.
## Статы — BALANCE.md §2. Раны — GDD §6.4.

signal enemy_killed(pos: Vector2, dir: Vector2, death: int, facing: float, variant: int)
signal enemy_died(pos: Vector2, kind: int, is_elite: bool)
signal spit_fired(from: Vector2, to: Vector2, damage: float)
signal fat_burst(pos: Vector2, is_elite: bool)
signal enemy_wounded(pos: Vector2, dir: Vector2, facing: float, variant: int, stage: int, wound: int)
signal enemy_hit(pos: Vector2, dir: Vector2, variant: int)
signal player_touched(damage: float)

enum Kind { SHAMBLER, RUNNER, FAT, SPITTER }
## Что зомби сейчас делает (чувства, задачи Z1–Z2): преследует игрока, бродит, идёт на звук.
enum Mind { CHASE, WANDER, INVESTIGATE }

const KINDS := [
	{"hp": 10.0, "speed": 28.0, "damage": 6.0, "xp": 1, "credit_chance": 0.06, "credits": 1},
	{"hp": 6.0, "speed": 88.0, "damage": 4.0, "xp": 1, "credit_chance": 0.06, "credits": 1},
	{"hp": 60.0, "speed": 20.0, "damage": 10.0, "xp": 4, "credit_chance": 0.40, "credits": 2},
	{"hp": 15.0, "speed": 34.0, "damage": 5.0, "xp": 2, "credit_chance": 0.20, "credits": 2},
]
const ELITE_HP := 5.0
const ELITE_DAMAGE := 1.3
const ELITE_SCALE := 1.5
const ELITE_SPEED := 1.1
const ELITE_XP := 25
const ELITE_CREDITS := 10
const TOUCH_COOLDOWN := 0.8
const SPIT_COOLDOWN := 3.0
const SPIT_WINDUP := 0.3

const MAX_ENEMIES := 2000
const RADIUS := 5.0
const CELL := 16.0
const SPRITE_SIZE := 16.0
const FLOATS_PER_INSTANCE := 12 # Transform2D (8) + custom (4)
const STEP_LENGTH := 6.0
const BLOODY_STEPS := 8
# стадии ран по доле HP: целый > 75% > ранен > 50% > изувечен > 25% > еле жив
const STAGE_THRESHOLDS := [0.75, 0.5, 0.25]
const VARIANT_WEIGHTS := [0.4, 0.2, 0.2, 0.2]
# Поведение «напролом»: зомби не боятся и не хитрят — прут на игрока, лезут через машины,
# задние ряды давят на передние. Обходят только здания и заборы.
const CLIMB_SPEED := 0.45 # доля скорости, пока лезет через машину или блок
const CLIMB_SCALE := 1.15 # на крыше машины зомби выше — спрайт крупнее
const LUNGE_DIST := 44.0 # ближе — бросается на игрока
const LUNGE_SPEED := 1.35
const TURN_RATE := 7.0 # плавность поворота (1/с): нет «поворотов под прямым углом»
const RUNNER_TURN_RATE := 11.0
const FRONT_PUSH := 0.3 # доля расталкивания, которую получает тот, кто ближе к игроку
# Чувства (BALANCE.md §13): зрение со стенами, слух, память, стая.
const VISION_RANGE := 320.0
const VISION_COS := 0.34 # конус ±70° по направлению взгляда
const VISION_NEAR := 90.0 # ближе — видит во все стороны
const SMELL_RANGE := 70.0 # вплотную чует всегда
const ROOF_VISION := 1.3 # с крыши машины видно дальше
const SEE_FRESH := 0.5 # столько секунд после взгляда идёт прямо на игрока
const MEMORY := 5.0 # потерял из виду — столько ищет у последней точки
const WANDER_SPEED := 0.5
const INVESTIGATE_SPEED := 0.9
const PACK_RADIUS := 220.0 # крик заметившего слышат соседи
const SCREAM_COOLDOWN := 0.4
const HIDE_LIMIT := 12.0 # игрока никто не видел и не слышал — орда идёт «по запаху»
const SCENT_RADIUS := 700.0
const RAYS_PER_TICK := 48
const ARRIVE := 28.0

@export var hp_growth_per_min := 0.12
@export var damage_growth_per_min := 0.05

var arena := Rect2()
var player: Player
var obstacles: Obstacles
var benchmark_spawn := false # Стресс боя сохраняет плотность кольца O1 на всех картах.
var map_entries := PackedVector2Array()
var floor_decals: FloorDecals
var minutes := 0.0
var update_ms := 0.0
var death_override := -1 # отладка (F6): принудительный тип смерти
# кольцо спавна — сразу за краем экрана; зависит от разрешения (задаёт игра)
var spawn_ring := 380.0
var far_distance := 600.0

var count := 0
var pos := PackedVector2Array()
var knock := PackedVector2Array()
var steer := PackedVector2Array() # кэш направления обхода (O1), ZERO — прямо
var heading := PackedVector2Array() # куда зомби сейчас идёт (поворачивает плавно)
var climb := PackedByteArray() # 1 — лезет через машину или блок
var mind := PackedByteArray() # Mind
var goal := PackedVector2Array() # куда идёт: точка шума, последняя точка игрока, точка брожения
var goal_t := PackedFloat32Array() # <0 — идёт к цели; >=0 — стоит у цели (осталось, с)
var seen_at := PackedFloat32Array() # когда последний раз видел игрока (время орды)
var noise_lvl := PackedFloat32Array() # сила звука, за которым идёт (громче — перебивает)
var prev := PackedVector2Array() # позиция на прошлом «обдумывании» — для «застрял»
var stuck := PackedByteArray()
var senses := true # false (--no-senses) — все всегда знают, где игрок (старое поведение)
var global_alert := false # тревога, босс: все преследуют
var poi := PackedVector2Array() # точки брожения (сценки, входы, круги карты)
var known_t := 0.0 # сколько секунд игрока никто не видел и не слышал
var player_known_at := Vector2.INF
var sfx: Sfx
var debug_senses := false
var spotted_total := 0 # для теста и отчёта
var _rays := 0
var _scream_cd := 0.0
var _noise_at := PackedVector2Array()
var _noise_to := PackedVector2Array()
var _noise_r := PackedFloat32Array()
var _noise_s := PackedFloat32Array()
var _rings: Array[Vector3] = [] # отладка: кольца шума (x, y, радиус) и их возраст
var _ring_age := PackedFloat32Array()
var hp := PackedFloat32Array()
var max_hp := PackedFloat32Array()
var speed := PackedFloat32Array()
var angle := PackedFloat32Array()
var flash := PackedFloat32Array()
var dead := PackedByteArray()
var kind := PackedByteArray()
var elite := PackedByteArray()
var radius := PackedFloat32Array()
var touch_cd := PackedFloat32Array()
var spit_cd := PackedFloat32Array()
var spit_windup := PackedFloat32Array()
var variant := PackedByteArray()
var stage := PackedByteArray()
var wounds := PackedByteArray() # биты PixelArt.WOUND_*
var holes := PackedFloat32Array()
var seed_value := PackedFloat32Array()
var feet := PackedByteArray() # сколько ещё шагов оставлять кровавые следы
var step_acc := PackedFloat32Array()
var uid := PackedInt32Array() # постоянный номер зомби (индексы меняются при уплотнении)
# статусы от патронов
var burn_t := PackedFloat32Array()
var burn_dps := PackedFloat32Array()
var burn_spread := PackedFloat32Array() # шанс поджечь соседей при смерти
var burn_r := PackedFloat32Array()
var chill := PackedFloat32Array() # замедление 0..0.6
var chill_hits := PackedByteArray()
var freeze_t := PackedFloat32Array()
var shatter := PackedByteArray() # Крио III: раскол ранит соседей

var _grid_w := 0
var _grid_h := 0
var _stride := 0 # ширина сетки с пустой рамкой в одну ячейку: соседей можно читать без проверки границ
var _noff := PackedInt32Array()
var _head := PackedInt32Array()
var _next := PackedInt32Array()
var _frame := 0
var _next_uid := 1
var _time := 0.0

const SHATTER_PER_TICK := 6
var _shatter_queue := PackedVector2Array()

var _mm: MultiMesh
var _buf := PackedFloat32Array()


func _ready() -> void:
	process_priority = -10 # обновляемся раньше оружия, чтобы сетка была свежей
	pos.resize(MAX_ENEMIES)
	knock.resize(MAX_ENEMIES)
	steer.resize(MAX_ENEMIES)
	heading.resize(MAX_ENEMIES)
	climb.resize(MAX_ENEMIES)
	mind.resize(MAX_ENEMIES)
	goal.resize(MAX_ENEMIES)
	goal_t.resize(MAX_ENEMIES)
	seen_at.resize(MAX_ENEMIES)
	noise_lvl.resize(MAX_ENEMIES)
	prev.resize(MAX_ENEMIES)
	stuck.resize(MAX_ENEMIES)
	hp.resize(MAX_ENEMIES)
	max_hp.resize(MAX_ENEMIES)
	speed.resize(MAX_ENEMIES)
	angle.resize(MAX_ENEMIES)
	flash.resize(MAX_ENEMIES)
	dead.resize(MAX_ENEMIES)
	kind.resize(MAX_ENEMIES)
	elite.resize(MAX_ENEMIES)
	radius.resize(MAX_ENEMIES)
	touch_cd.resize(MAX_ENEMIES)
	spit_cd.resize(MAX_ENEMIES)
	spit_windup.resize(MAX_ENEMIES)
	variant.resize(MAX_ENEMIES)
	stage.resize(MAX_ENEMIES)
	wounds.resize(MAX_ENEMIES)
	holes.resize(MAX_ENEMIES)
	seed_value.resize(MAX_ENEMIES)
	feet.resize(MAX_ENEMIES)
	step_acc.resize(MAX_ENEMIES)
	uid.resize(MAX_ENEMIES)
	burn_t.resize(MAX_ENEMIES)
	burn_dps.resize(MAX_ENEMIES)
	burn_spread.resize(MAX_ENEMIES)
	burn_r.resize(MAX_ENEMIES)
	chill.resize(MAX_ENEMIES)
	chill_hits.resize(MAX_ENEMIES)
	freeze_t.resize(MAX_ENEMIES)
	shatter.resize(MAX_ENEMIES)
	_next.resize(MAX_ENEMIES)
	_buf.resize(MAX_ENEMIES * FLOATS_PER_INSTANCE)

	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_2D
	_mm.use_colors = false # оттенок считается в шейдере из зерна
	_mm.use_custom_data = true
	_mm.mesh = _make_quad(SPRITE_SIZE)
	_mm.instance_count = MAX_ENEMIES
	_mm.visible_instance_count = 0

	var mmi := MultiMeshInstance2D.new()
	mmi.multimesh = _mm
	mmi.texture = PixelArt.tex("zombie_atlas")
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/flash.gdshader")
	mat.set_shader_parameter("rows", float(PixelArt.VARIANT_COUNT * PixelArt.ANIM_FRAMES))
	mmi.material = mat
	add_child(mmi)


func setup(arena_rect: Rect2, target: Player, floor_layer: FloorDecals) -> void:
	arena = arena_rect
	player = target
	floor_decals = floor_layer
	_grid_w = ceili(arena.size.x / CELL)
	_grid_h = ceili(arena.size.y / CELL)
	_stride = _grid_w + 2
	_head.resize(_stride * (_grid_h + 2))
	_head.fill(-1)
	_noff = PackedInt32Array([1, _stride - 1, _stride, _stride + 1]) # E, SW, S, SE
	# Границы MultiMesh — вся арена. Иначе Godot отсекает орду целиком по устаревшему
	# прямоугольнику, и зомби пропадают, стоит уйти от места, где он был посчитан.
	var r := arena.grow(SPRITE_SIZE)
	_mm.custom_aabb = AABB(Vector3(r.position.x, r.position.y, -1.0), Vector3(r.size.x, r.size.y, 2.0))


func spawn(p: Vector2, k := Kind.SHAMBLER, is_elite := false) -> int:
	if count >= MAX_ENEMIES:
		return -1
	var i := count
	count += 1
	kind[i] = k
	elite[i] = 1 if is_elite else 0
	radius[i] = RADIUS * (ELITE_SCALE if is_elite else 1.0)
	touch_cd[i] = 0.0
	spit_cd[i] = randf_range(SPIT_WINDUP, SPIT_COOLDOWN) if k == Kind.SPITTER else 0.0
	spit_windup[i] = 0.0
	pos[i] = p.clamp(arena.position + Vector2.ONE * radius[i], arena.end - Vector2.ONE * radius[i])
	if obstacles:
		pos[i] = obstacles.free_point(pos[i], radius[i])
	knock[i] = Vector2.ZERO
	steer[i] = Vector2.ZERO
	heading[i] = (player.global_position - pos[i]).normalized() if player else Vector2.ZERO
	climb[i] = 0
	# По умолчанию новый зомби знает, где игрок (группы спавнера потом решает arrive()).
	mind[i] = Mind.CHASE
	goal[i] = player.global_position if player else pos[i]
	goal_t[i] = -1.0
	seen_at[i] = _time
	noise_lvl[i] = 0.0
	prev[i] = pos[i]
	stuck[i] = 0
	hp[i] = KINDS[k]["hp"] * (1.0 + hp_growth_per_min * minutes) * (ELITE_HP if is_elite else 1.0)
	max_hp[i] = hp[i]
	# Даже самый медленный бегун быстрее базовых 80 px/с игрока.
	var spread := randf_range(0.95, 1.1) if k == Kind.RUNNER else randf_range(0.85, 1.2)
	speed[i] = KINDS[k]["speed"] * spread * (ELITE_SPEED if is_elite else 1.0)
	angle[i] = 0.0
	flash[i] = 0.0
	dead[i] = 0
	variant[i] = _pick_variant() if k == Kind.SHAMBLER else k + 3
	stage[i] = 0
	wounds[i] = 0
	holes[i] = 0.0
	seed_value[i] = randf()
	feet[i] = 0
	step_acc[i] = 0.0
	uid[i] = _next_uid
	_next_uid += 1
	burn_t[i] = 0.0
	burn_dps[i] = 0.0
	burn_spread[i] = 0.0
	burn_r[i] = 0.0
	chill[i] = 0.0
	chill_hits[i] = 0
	freeze_t[i] = 0.0
	shatter[i] = 0
	return i


static func _pick_variant() -> int:
	var r := randf()
	for v in VARIANT_WEIGHTS.size():
		r -= VARIANT_WEIGHTS[v]
		if r <= 0.0:
			return v
	return 0


## Тихо убирает живых дальше r от center: без сигналов смерти, гибов и дропа (затишье 9:00).
## Возвращает, сколько убрано; сами строки вычистит _compact().
func despawn_far(center: Vector2, r: float) -> int:
	var removed := 0
	var r2 := r * r
	for i in count:
		if dead[i] == 0 and pos[i].distance_squared_to(center) > r2:
			dead[i] = 1
			removed += 1
	return removed


## Точка на кольце за краем экрана, внутри арены.
func spawn_point(center: Vector2) -> Vector2:
	if not benchmark_spawn and not map_entries.is_empty():
		var view := PixelArt.view_rect(self, 88.0)
		var best := Vector2.INF
		var best_distance := INF
		# Ближайший вход за экраном; небольшой разброс сохраняет несколько направлений.
		for entry in map_entries:
			if view.has_point(entry):
				continue
			var d := center.distance_squared_to(entry) * randf_range(0.85, 1.15)
			if d < best_distance:
				best = entry
				best_distance = d
		if best != Vector2.INF:
			return obstacles.free_point(best, RADIUS * 2.0) if obstacles else best
	var inner := arena.grow(-RADIUS * 2.0)
	for attempt in 12:
		var p := center + Vector2.from_angle(randf() * TAU) * spawn_ring
		if inner.has_point(p):
			return p
	return (center + Vector2.from_angle(randf() * TAU) * spawn_ring).clamp(inner.position, inner.end)


func spawn_group(center: Vector2, n: int, k := Kind.SHAMBLER) -> void:
	var origin := spawn_point(center)
	for j in n:
		spawn(origin + Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0)), k)


## Возвращает true, если враг умер. Тип смерти зависит от патронов, крита и оверкилла.
## hit_pos — где пуля коснулась зомби: по нему выбирается, какую руку оторвать.
func damage(i: int, amount: float, dir: Vector2, knockback: float, ammo := WeaponDefs.Ammo.STANDARD,
		crit := false, hit_pos := Vector2.INF, explosive := false) -> bool:
	if dead[i] == 1:
		return false
	if freeze_t[i] > 0.0:
		amount *= 1.25 # замёрзших бьёт сильнее
	hp[i] -= amount
	flash[i] = 1.0
	knock[i] += dir * knockback * (0.3 if kind[i] == Kind.FAT else 1.0)
	holes[i] = minf(holes[i] + 0.12, 1.0)
	if hp[i] <= 0.0:
		dead[i] = 1
		var death := death_override if death_override >= 0 else _death_type(ammo, crit, amount >= max_hp[i] or explosive)
		if freeze_t[i] > 0.0 and death_override < 0:
			death = Gore.Death.ICE # замёрзший всегда раскалывается
		if kind[i] == Kind.FAT:
			death = Gore.Death.GIBS # лопается даже от огня, крио и отладочной смерти
		enemy_killed.emit(pos[i], dir, death, angle[i], variant[i])
		enemy_died.emit(pos[i], kind[i], elite[i] == 1)
		if kind[i] == Kind.FAT:
			fat_burst.emit(pos[i], elite[i] == 1)
		_on_death_status(i)
		return true
	if dir != Vector2.ZERO: # от огня (без направления) клочья не летят
		enemy_hit.emit(pos[i], dir, variant[i])
	var ratio := hp[i] / max_hp[i]
	var new_stage := 0
	for t: float in STAGE_THRESHOLDS:
		if ratio <= t:
			new_stage += 1
	while stage[i] < new_stage:
		stage[i] += 1
		_apply_wound(i, stage[i], dir, hit_pos)
	return false


## Новая стадия раны: что отрывается, решает сторона попадания.
func _apply_wound(i: int, st: int, dir: Vector2, hit_pos: Vector2) -> void:
	var wound := 0
	if st == 2:
		var side := 0
		if hit_pos != Vector2.INF:
			var local := (hit_pos - pos[i]).rotated(-angle[i])
			if absf(local.y) > 1.0:
				side = -1 if local.y < 0.0 else 1
		if side == 0:
			side = -1 if randf() < 0.5 else 1
		wound = PixelArt.WOUND_ARM_L if side < 0 else PixelArt.WOUND_ARM_R
		if wounds[i] & wound:
			wound = PixelArt.WOUND_CHEST
		wound |= PixelArt.WOUND_CHEST if randf() < 0.4 else 0
	elif st == 3:
		wound = PixelArt.WOUND_HEAD | PixelArt.WOUND_CHEST
		speed[i] *= 0.75 # шатается
	wounds[i] |= wound
	enemy_wounded.emit(pos[i], dir, angle[i], variant[i], st, wound)


## Огонь перекидывается с горящего трупа, замёрзший раскалывается осколками.
func _on_death_status(i: int) -> void:
	if burn_t[i] > 0.0 and burn_spread[i] > 0.0:
		for j in query_radius(pos[i], burn_r[i]):
			if randf() < burn_spread[i]:
				ignite(j, burn_dps[i], 3.0, burn_spread[i], burn_r[i])
	if freeze_t[i] > 0.0 and shatter[i] == 1:
		# Раскол не рекурсивный: цепочка замёрзших раньше разворачивалась за один кадр (десятки мс),
		# теперь точки раскола встают в очередь и разбираются по SHATTER_PER_TICK за тик.
		_shatter_queue.append(pos[i])


func ignite(i: int, dps: float, duration: float, spread_chance := 0.0, spread_r := 16.0) -> void:
	if dead[i] == 1:
		return
	burn_t[i] = maxf(burn_t[i], duration)
	burn_dps[i] = maxf(burn_dps[i], dps)
	burn_spread[i] = maxf(burn_spread[i], spread_chance)
	burn_r[i] = maxf(burn_r[i], spread_r)


## Попадание Крио: замедление копится, после need попаданий — заморозка на 1.5 с.
func chill_hit(i: int, slow: float, need: int, shatter_on := false, instant := false) -> void:
	if dead[i] == 1:
		return
	chill[i] = minf(chill[i] + slow, 0.6)
	chill_hits[i] = mini(chill_hits[i] + 1, 255)
	if shatter_on:
		shatter[i] = 1
	if instant or chill_hits[i] >= need:
		freeze_t[i] = 1.5
		chill_hits[i] = 0


## Живые зомби в радиусе r от точки p.
func query_radius(p: Vector2, r: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	var cr := ceili((r + RADIUS * ELITE_SCALE) / CELL)
	var cx := int(p.x / CELL)
	var cy := int(p.y / CELL)
	for y in range(maxi(cy - cr, 0), mini(cy + cr + 1, _grid_h)):
		for x in range(maxi(cx - cr, 0), mini(cx + cr + 1, _grid_w)):
			var j := _head[(x + 1) + (y + 1) * _stride]
			while j != -1:
				if j < count and dead[j] == 0 and pos[j].distance_squared_to(p) <= (r + radius[j]) * (r + radius[j]):
					out.append(j)
				j = _next[j]
	return out


## Ближайший живой в радиусе, кроме тех, чьи uid в exclude.
func find_nearest_except(p: Vector2, max_dist: float, exclude: PackedInt32Array) -> int:
	var best := -1
	var best_d := max_dist * max_dist
	for j in query_radius(p, max_dist):
		if exclude.has(uid[j]):
			continue
		var d := pos[j].distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = j
	return best


func _death_type(ammo: int, crit: bool, overkill: bool) -> int:
	match ammo:
		WeaponDefs.Ammo.EXPANSIVE:
			return Gore.Death.GIBS
		WeaponDefs.Ammo.INCENDIARY:
			return Gore.Death.BURN
		WeaponDefs.Ammo.CRYO:
			return Gore.Death.ICE
	if overkill:
		return Gore.Death.GIBS
	if crit:
		return Gore.Death.HEADSHOT if randf() < 0.5 else Gore.Death.DECAP
	return Gore.Death.NORMAL


## Первый живой враг, пересекающий круг (p, r), или -1.
func find_hit(p: Vector2, r: float) -> int:
	var cr := ceili((r + RADIUS * ELITE_SCALE) / CELL)
	var cx := int(p.x / CELL)
	var cy := int(p.y / CELL)
	for y in range(cy - cr, cy + cr + 1):
		if y < 0 or y >= _grid_h:
			continue
		for x in range(cx - cr, cx + cr + 1):
			if x < 0 or x >= _grid_w:
				continue
			var j := _head[(x + 1) + (y + 1) * _stride]
			while j != -1:
				if j < count and dead[j] == 0 and pos[j].distance_squared_to(p) <= (r + radius[j]) * (r + radius[j]):
					return j
				j = _next[j]
	return -1


## Ближайший живой враг в радиусе max_dist, или -1.
func find_nearest(p: Vector2, max_dist: float) -> int:
	var best := -1
	var best_d := max_dist * max_dist
	for i in count:
		if dead[i] == 1:
			continue
		var d := pos[i].distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = i
	return best


func _physics_process(delta: float) -> void:
	if player == null:
		return
	var t0 := Time.get_ticks_usec()
	_frame += 1
	_time += delta
	_run_shatter()
	_compact()
	_rays = 0
	_scream_cd = maxf(_scream_cd - delta, 0.0)
	if senses:
		known_t += delta
		if known_t > HIDE_LIMIT and not global_alert:
			# Спрятался и молчит: ближние идут «по запаху» туда, где он сейчас, — но должны ещё увидеть.
			noise(player.global_position, SCENT_RADIUS, 1.5)
			known_t = HIDE_LIMIT - 4.0
		_hear()
	if debug_senses:
		for n in range(_ring_age.size() - 1, -1, -1):
			_ring_age[n] += delta
			if _ring_age[n] > 0.6:
				_ring_age.remove_at(n)
				_rings.remove_at(n)
	_move(delta)
	_rebuild_grid()
	_separate()
	if obstacles:
		var near := obstacles.wall
		var ogw := obstacles.grid_w
		var gw1 := ogw - 1
		var gh1 := obstacles.grid_h - 1
		for i in count:
			var p := pos[i]
			if near[clampi(int(p.x / CELL), 0, gw1) + clampi(int(p.y / CELL), 0, gh1) * ogw] != 0:
				pos[i] = obstacles.resolve(p, radius[i], true)
	_render()
	queue_redraw()
	update_ms = (Time.get_ticks_usec() - t0) / 1000.0


## Раскол замёрзших: осколки ранят соседей в радиусе 24; убитые замёрзшие добавляют свои точки в очередь.
func _run_shatter() -> void:
	var n := mini(_shatter_queue.size(), SHATTER_PER_TICK)
	if n == 0:
		return
	var batch := _shatter_queue.slice(0, n)
	_shatter_queue = _shatter_queue.slice(n)
	for p in batch:
		for j in query_radius(p, 24.0):
			chill_hit(j, 0.3, 3, true)
			damage(j, 5.0, (pos[j] - p).normalized(), 40.0, WeaponDefs.Ammo.CRYO)


func _move(delta: float) -> void:
	var ppos := player.global_position
	var decay := exp(-10.0 * delta)
	var touch_damage := 0.0
	var damage_scale := 1.0 + damage_growth_per_min * minutes
	var near := obstacles.wall if obstacles else PackedByteArray()
	var any_near := obstacles.blocked if obstacles else PackedByteArray()
	var ogw := obstacles.grid_w if obstacles else 1
	var gw1 := ogw - 1
	var gh1 := (obstacles.grid_h if obstacles else 1) - 1
	for i in count:
		if dead[i] == 1:
			continue
		touch_cd[i] = maxf(touch_cd[i] - delta, 0.0)
		var frozen := freeze_t[i] > 0.0
		var p := pos[i]
		var old := p
		var to := ppos - p
		var d := to.length()
		if d > far_distance and (benchmark_spawn or map_entries.is_empty()):
			# отставших возвращаем в кольцо, чтобы орда не терялась позади
			p = spawn_point(ppos)
			if obstacles:
				p = obstacles.free_point(p, radius[i])
			old = p
			to = ppos - p
			d = to.length()
		var dir := to / d if d > 0.001 else Vector2.ZERO
		var k := knock[i]
		var spd := speed[i] * (1.0 - chill[i])
		if freeze_t[i] > 0.0:
			freeze_t[i] -= delta
			spd = 0.0
			k *= 0.2
		chill[i] = maxf(chill[i] - 0.3 * delta, 0.0)
		if burn_t[i] > 0.0:
			burn_t[i] -= delta
			if dead[i] == 0:
				damage(i, burn_dps[i] * delta, Vector2.ZERO, 0.0, WeaponDefs.Ammo.INCENDIARY)
		if dead[i] == 1: # огонь мог убить в этом кадре
			continue
		# Чувства: зомби думает раз в 8 тиков, вразбивку.
		if senses and (i + _frame) & 7 == 0:
			_think(i, p, ppos, d)
		var m := mind[i] if senses else Mind.CHASE
		var chasing := m == Mind.CHASE
		var target := ppos
		var mul := 1.0
		if chasing:
			if senses and _time - seen_at[i] > SEE_FRESH:
				target = goal[i] # потерял из виду — к последней точке
		else:
			target = goal[i]
			mul = INVESTIGATE_SPEED if m == Mind.INVESTIGATE else WANDER_SPEED
		var tto := target - p
		var td := tto.length()
		var tdir := tto / td if td > 0.001 else Vector2.ZERO
		var move_dir := tdir
		if not chasing and goal_t[i] >= 0.0:
			move_dir = Vector2.ZERO # стоит у цели и оглядывается
			heading[i] = heading[i].rotated(sin(_time * 0.7 + seed_value[i] * 30.0) * 1.2 * delta)
		elif chasing and target != ppos and td < ARRIVE:
			move_dir = Vector2.ZERO
		if move_dir != Vector2.ZERO and obstacles and (td > 90.0 or near[clampi(int(p.x / CELL), 0, gw1) + clampi(int(p.y / CELL), 0, gh1) * ogw] != 0):
			# Направление поля обходов обновляется раз в 4 тика на зомби: ZERO — идти прямо.
			if (i + _frame) & 3 == 0:
				steer[i] = obstacles.steering(p, tdir) if target == ppos else obstacles.steer_to(p, tdir, target)
			if steer[i] != Vector2.ZERO:
				move_dir = steer[i]
		if kind[i] == Kind.SPITTER and chasing:
			spit_cd[i] = maxf(spit_cd[i] - delta, 0.0)
			if not frozen:
				if spit_windup[i] > 0.0:
					spit_windup[i] = maxf(spit_windup[i] - delta, 0.0)
					move_dir = Vector2.ZERO
					if spit_windup[i] == 0.0:
						if d >= 90.0 and d <= 260.0 and (obstacles == null or climb[i] == 1 or obstacles.line_clear(p, ppos)):
							spit_fired.emit(p, ppos, 10.0 * damage_scale * (ELITE_DAMAGE if elite[i] == 1 else 1.0))
				elif spit_cd[i] <= 0.0 and d >= 90.0 and d <= 260.0:
					spit_windup[i] = SPIT_WINDUP
					spit_cd[i] = SPIT_COOLDOWN
					move_dir = Vector2.ZERO
		# Поворот с запаздыванием: дуги вместо ступенек поля обхода и рывков за игроком.
		var h := heading[i]
		if move_dir != Vector2.ZERO:
			if td > 70.0 and steer[i] == Vector2.ZERO:
				# издалека бредут неровно, вблизи цель захвачена
				var wob := sin(_time * (0.9 + seed_value[i]) + seed_value[i] * 40.0) * (0.22 if chasing else 0.45) * clampf((td - 70.0) / 150.0, 0.0, 1.0)
				move_dir = move_dir.rotated(wob)
			var rate := RUNNER_TURN_RATE if kind[i] == Kind.RUNNER else TURN_RATE
			# Вращение по углу, а не смешивание векторов: разворот на 180° тоже срабатывает.
			if h == Vector2.ZERO:
				h = move_dir
			else:
				h = h.rotated(h.angle_to(move_dir) * (1.0 - exp(-rate * delta)))
			heading[i] = h
			# Походка рывками: шаг — толчок, между шагами медленнее. В среднем скорость прежняя.
			if kind[i] == Kind.RUNNER:
				spd *= 0.95 + 0.1 * sin(_time * 14.0 + seed_value[i] * TAU)
			else:
				spd *= 0.89 + 0.35 * maxf(sin(_time * (7.0 + seed_value[i] * 3.0) + seed_value[i] * TAU), 0.0)
			spd *= mul
			if chasing and d < LUNGE_DIST and kind[i] != Kind.SPITTER:
				spd *= LUNGE_SPEED # последний бросок на игрока
			if climb[i] == 1:
				spd *= CLIMB_SPEED
		else:
			h = Vector2.ZERO
		p += h * spd * delta + k * delta
		# Обычный шаг разрешается один раз после расталкивания; быстрый отброс — со свипом.
		if obstacles and old.distance_squared_to(p) > 16.0:
			p = obstacles.move_actor(old, p, radius[i], true)
		if obstacles:
			var on := 0
			if any_near[clampi(int(p.x / CELL), 0, gw1) + clampi(int(p.y / CELL), 0, gh1) * ogw] != 0 and obstacles.climb_at(p):
				on = 1
			climb[i] = on
		knock[i] = k * decay
		# игрок «тяжёлый»: выталкивает зомби из себя
		var away := p - ppos
		var ad2 := away.length_squared()
		var touch_r := Player.RADIUS + radius[i]
		if ad2 < (touch_r + 1.0) * (touch_r + 1.0):
			if touch_cd[i] <= 0.0 and not frozen:
				var hit_damage: float = KINDS[kind[i]]["damage"] * damage_scale * (ELITE_DAMAGE if elite[i] == 1 else 1.0)
				touch_damage = maxf(touch_damage, hit_damage)
				touch_cd[i] = TOUCH_COOLDOWN
			if ad2 > 0.0001 and ad2 < touch_r * touch_r:
				p = ppos + away / sqrt(ad2) * touch_r
		p = p.clamp(arena.position + Vector2.ONE * radius[i], arena.end - Vector2.ONE * radius[i])
		pos[i] = p
		# Смотрит туда, куда идёт; вблизи — на игрока.
		var a := angle[i]
		if freeze_t[i] <= 0.0:
			a = dir.angle() if (chasing and d < 60.0) or heading[i] == Vector2.ZERO else heading[i].angle()
		if stage[i] == 3 and freeze_t[i] <= 0.0:
			a += sin(_time * 7.0 + seed_value[i] * 20.0) * 0.35 # еле живые шатаются
		angle[i] = a
		flash[i] = maxf(flash[i] - delta * 10.0, 0.0)
		# следы и капли: функцию зовём только когда что-то нужно (раньше — 500 вызовов за тик впустую)
		if floor_decals != null:
			var sa := step_acc[i] + p.distance_to(old)
			if sa >= STEP_LENGTH or stage[i] > 0 or (i + _frame) & 3 == 0:
				step_acc[i] = sa
				_feet_and_drips(i, p, a)
			else:
				step_acc[i] = sa
	if touch_damage > 0.0:
		player_touched.emit(touch_damage)


## Шум: всех в радиусе, кто не преследует, тянет к target (по умолчанию — к источнику).
## strength: 1 — крик стаи, 1.5 — «запах», 2 — выстрел, 3 — взрыв, граната, сигнализация.
## Шумы одного тика с близкой целью склеиваются (автострельба не создаёт сотни событий).
func noise(at: Vector2, radius_px: float, strength: float, target := Vector2.INF) -> void:
	if not senses or radius_px <= 0.0:
		return
	if target == Vector2.INF:
		target = at
	for n in _noise_to.size():
		if _noise_to[n].distance_squared_to(target) < 2304.0 and _noise_at[n].distance_squared_to(at) < 2304.0:
			_noise_r[n] = maxf(_noise_r[n], radius_px)
			_noise_s[n] = maxf(_noise_s[n], strength)
			return
	_noise_at.append(at)
	_noise_to.append(target)
	_noise_r.append(radius_px)
	_noise_s.append(strength)


## Все сразу знают, где игрок (рёв босса, тревога).
func alert_all() -> void:
	if player == null:
		return
	for i in count:
		if dead[i] == 0:
			mind[i] = Mind.CHASE
			seen_at[i] = _time
			goal[i] = player.global_position
	known_t = 0.0


## Новая группа спавнера: бегуны сразу преследуют; остальные идут на последний шум игрока или бродят.
func arrive(i: int) -> void:
	if i < 0 or not senses or global_alert or kind[i] == Kind.RUNNER:
		return
	if known_t < 6.0 and player_known_at != Vector2.INF:
		mind[i] = Mind.INVESTIGATE
		goal[i] = player_known_at + _jitter(i, 50.0)
		goal_t[i] = -1.0
		noise_lvl[i] = 2.0
	else:
		mind[i] = Mind.WANDER
		_pick_poi(i)


## Группы на карте с самого старта: стоят и бродят у сценок, подальше от игрока.
func spawn_idle_groups(start: Vector2, groups: int, size: Vector2i, min_dist := 520.0) -> int:
	var places := PackedVector2Array()
	for q in poi:
		if q.distance_to(start) >= min_dist:
			places.append(q)
	var spawned := 0
	for g in mini(groups, places.size()):
		var pick := randi() % places.size()
		var center := places[pick]
		places.remove_at(pick)
		var linger := randf_range(3.0, 20.0)
		for j in randi_range(size.x, size.y):
			var e := spawn(center + Vector2.from_angle(randf() * TAU) * randf_range(4.0, 26.0), Kind.FAT if randf() < 0.08 else Kind.SHAMBLER)
			if e < 0:
				return spawned
			mind[e] = Mind.WANDER
			goal[e] = center
			goal_t[e] = linger + randf_range(0.0, 3.0)
			heading[e] = Vector2.from_angle(randf() * TAU)
			angle[e] = heading[e].angle()
			seen_at[e] = -100.0
			spawned += 1
	known_t = 0.0
	return spawned


func _jitter(i: int, r: float) -> Vector2:
	return Vector2.from_angle(seed_value[i] * TAU * 7.0) * r * seed_value[i]


## Слух: шумы этого тика будят всех в радиусе, кто не видит игрока прямо сейчас.
func _hear() -> void:
	if _noise_at.is_empty() or player == null:
		return
	var ppos := player.global_position
	for n in _noise_at.size():
		var at := _noise_at[n]
		var to := _noise_to[n]
		var r2 := _noise_r[n] * _noise_r[n]
		var st := _noise_s[n]
		var from_player := to.distance_squared_to(ppos) < 9216.0
		if from_player and st >= 2.0:
			known_t = 0.0
			player_known_at = ppos
		if obstacles and st >= 2.5 and not from_player:
			obstacles.request_noise_field(to)
		if debug_senses:
			_rings.append(Vector3(at.x, at.y, _noise_r[n]))
			_ring_age.append(0.0)
		for i in count:
			if dead[i] == 1 or pos[i].distance_squared_to(at) > r2:
				continue
			if mind[i] == Mind.CHASE and _time - seen_at[i] < MEMORY:
				continue
			if mind[i] == Mind.INVESTIGATE and goal_t[i] < 0.0 and st < noise_lvl[i]:
				continue
			mind[i] = Mind.INVESTIGATE
			goal[i] = to + _jitter(i, 40.0)
			goal_t[i] = -1.0
			noise_lvl[i] = st
			stuck[i] = 0
	_noise_at.clear()
	_noise_to.clear()
	_noise_r.clear()
	_noise_s.clear()


## Зрение и решения одного зомби. Дешёвые проверки первыми, луч — последним и с бюджетом на тик.
func _think(i: int, p: Vector2, ppos: Vector2, d: float) -> void:
	var dt := 8.0 / 60.0
	if global_alert:
		mind[i] = Mind.CHASE
		seen_at[i] = _time
		goal[i] = ppos
		return
	var sees := d < SMELL_RANGE
	if not sees:
		var on_roof := climb[i] == 1
		var vr := VISION_RANGE * (ROOF_VISION if on_roof else 1.0)
		if d < vr and d > 0.001:
			var look := (ppos - p) / d
			if d < VISION_NEAR or mind[i] == Mind.CHASE or heading[i].dot(look) > VISION_COS:
				if obstacles == null:
					sees = true
				elif _rays < RAYS_PER_TICK:
					_rays += 1
					sees = obstacles.sight_clear(p, ppos, on_roof)
				elif mind[i] == Mind.CHASE and _time - seen_at[i] < 1.0:
					sees = true # лучи этого тика кончились: недавно видевший продолжает преследовать
				else:
					return # проверит в следующий раз
	if sees:
		if mind[i] != Mind.CHASE or _time - seen_at[i] > MEMORY:
			_spotted(i, p, ppos)
		mind[i] = Mind.CHASE
		seen_at[i] = _time
		goal[i] = ppos
		known_t = 0.0
		player_known_at = ppos
		return
	noise_lvl[i] = maxf(noise_lvl[i] - 0.5 * dt, 0.0)
	var m := mind[i]
	if m == Mind.CHASE:
		if _time - seen_at[i] > MEMORY or p.distance_squared_to(goal[i]) < ARRIVE * ARRIVE:
			# дошёл до места, где видел, — стоит и оглядывается
			mind[i] = Mind.INVESTIGATE
			goal_t[i] = randf_range(1.5, 3.5)
			noise_lvl[i] = 0.5
		prev[i] = p
		return
	if goal_t[i] >= 0.0:
		goal_t[i] -= dt
		if goal_t[i] < 0.0:
			mind[i] = Mind.WANDER
			_pick_poi(i)
	elif p.distance_squared_to(goal[i]) < ARRIVE * ARRIVE:
		goal_t[i] = randf_range(2.0, 4.0) if m == Mind.INVESTIGATE else randf_range(2.0, 7.0)
	elif steer[i] == Vector2.ZERO and p.distance_squared_to(prev[i]) < 0.25 and knock[i].length_squared() < 1.0:
		# Сдаётся, только если шёл напрямик без маршрута и упёрся; с маршрутом — давит дальше, как толпа.
		stuck[i] += 1
		if stuck[i] >= 6: # упёрся в стену — ищет другое место
			mind[i] = Mind.WANDER
			_pick_poi(i)
	else:
		stuck[i] = 0
	prev[i] = p


## Заметил: рывок головой и телом к игроку, крик для стаи.
func _spotted(i: int, p: Vector2, ppos: Vector2) -> void:
	spotted_total += 1
	var look := (ppos - p).normalized()
	heading[i] = look
	knock[i] += look * 45.0
	if _scream_cd <= 0.0:
		_scream_cd = SCREAM_COOLDOWN
		noise(p, PACK_RADIUS, 1.0, ppos)
		if sfx:
			sfx.play("zombies/runner", p, -6.0, 0.08)


## Новая точка брожения: чаще за соседом-бродягой (держатся кучками), иначе ближайшая из трёх случайных.
func _pick_poi(i: int) -> void:
	var p := pos[i]
	goal_t[i] = -1.0
	stuck[i] = 0
	noise_lvl[i] = 0.0
	if randf() < 0.5 and _grid_w > 0:
		var c := clampi(int(p.x / CELL), 0, _grid_w - 1) + 1 + (clampi(int(p.y / CELL), 0, _grid_h - 1) + 1) * _stride
		var j := _head[c]
		while j != -1:
			if j != i and j < count and dead[j] == 0 and mind[j] == Mind.WANDER and goal_t[j] < 0.0:
				goal[i] = goal[j] + _jitter(i, 30.0)
				return
			j = _next[j]
	if poi.is_empty():
		goal[i] = Vector2(randf_range(arena.position.x + 40.0, arena.end.x - 40.0), randf_range(arena.position.y + 40.0, arena.end.y - 40.0))
		return
	var best := poi[randi() % poi.size()]
	for t in 2:
		var q := poi[randi() % poi.size()]
		if q.distance_squared_to(p) < best.distance_squared_to(p) and q.distance_squared_to(p) > 4096.0:
			best = q
	goal[i] = best + _jitter(i, 40.0)


## Кровавые следы, если зомби прошёл по луже, и капли с раненых.
func _feet_and_drips(i: int, p: Vector2, a: float) -> void:
	if (i + _frame) & 3 == 0 and floor_decals.is_wet(p):
		feet[i] = BLOODY_STEPS
	if step_acc[i] >= STEP_LENGTH:
		step_acc[i] = 0.0
		if feet[i] > 0:
			var side := 1.5 if feet[i] % 2 == 0 else -1.5
			floor_decals.stamp_print(p + Vector2.from_angle(a + PI * 0.5) * side, a, feet[i] / float(BLOODY_STEPS))
			feet[i] -= 1
	var st := stage[i]
	if st > 0 and randf() < 0.012 * st:
		floor_decals.stamp_dot(p + Vector2(randf_range(-3, 3), randf_range(-3, 3)), 1.0, Color(0.38, 0.03, 0.03, 0.85))


func _rebuild_grid() -> void:
	_head.fill(-1)
	for i in count:
		var p := pos[i]
		var c := clampi(int(p.x / CELL), 0, _grid_w - 1) + 1 + (clampi(int(p.y / CELL), 0, _grid_h - 1) + 1) * _stride
		_next[i] = _head[c]
		_head[c] = i


func _separate() -> void:
	# Каждая пара обходится один раз: хвост своей ячейки + четыре «передние» соседки (E, SW, S, SE).
	# Раньше обходили все 9 ячеек с проверкой j > i и границ — вдвое больше проходов по спискам.
	var gw := _grid_w - 1
	var gh := _grid_h - 1
	var stride := _stride
	# Давка: задние ряды напирают, передние не отступают назад — толпа растекается по бокам и окружает.
	var ppos := player.global_position
	for i in count:
		if dead[i] == 1:
			continue
		var p := pos[i]
		var ri := radius[i]
		var di2 := p.distance_squared_to(ppos)
		var base := clampi(int(p.x / CELL), 0, gw) + 1 + (clampi(int(p.y / CELL), 0, gh) + 1) * stride
		var j := _next[i]
		var k := 0
		while true:
			while j != -1:
				if dead[j] == 0:
					var q := pos[j]
					var dv := p - q
					var d2 := dv.length_squared()
					var min_d := ri + radius[j]
					if d2 < min_d * min_d:
						if d2 < 0.0001:
							dv = Vector2.from_angle(randf() * TAU) * 0.1
							d2 = 0.01
						var d := sqrt(d2)
						var push := dv * ((min_d - d) / d)
						var wi := FRONT_PUSH if di2 < q.distance_squared_to(ppos) else 1.0 - FRONT_PUSH
						p += push * wi
						pos[j] = q - push * (1.0 - wi)
				j = _next[j]
			if k == 4:
				break
			j = _head[base + _noff[k]]
			k += 1
		pos[i] = p


## Убираем мёртвых: последний живой переезжает на место убитого.
func _compact() -> void:
	var i := 0
	while i < count:
		if dead[i] == 1:
			count -= 1
			if i != count:
				pos[i] = pos[count]
				knock[i] = knock[count]
				steer[i] = steer[count]
				heading[i] = heading[count]
				climb[i] = climb[count]
				mind[i] = mind[count]
				goal[i] = goal[count]
				goal_t[i] = goal_t[count]
				seen_at[i] = seen_at[count]
				noise_lvl[i] = noise_lvl[count]
				prev[i] = prev[count]
				stuck[i] = stuck[count]
				hp[i] = hp[count]
				max_hp[i] = max_hp[count]
				speed[i] = speed[count]
				angle[i] = angle[count]
				flash[i] = flash[count]
				dead[i] = dead[count]
				kind[i] = kind[count]
				elite[i] = elite[count]
				radius[i] = radius[count]
				touch_cd[i] = touch_cd[count]
				spit_cd[i] = spit_cd[count]
				spit_windup[i] = spit_windup[count]
				variant[i] = variant[count]
				stage[i] = stage[count]
				wounds[i] = wounds[count]
				holes[i] = holes[count]
				seed_value[i] = seed_value[count]
				feet[i] = feet[count]
				step_acc[i] = step_acc[count]
				uid[i] = uid[count]
				burn_t[i] = burn_t[count]
				burn_dps[i] = burn_dps[count]
				burn_spread[i] = burn_spread[count]
				burn_r[i] = burn_r[count]
				chill[i] = chill[count]
				chill_hits[i] = chill_hits[count]
				freeze_t[i] = freeze_t[count]
				shatter[i] = shatter[count]
			dead[count] = 0
		else:
			i += 1


func _render() -> void:
	var front := 0
	var back := count - 1
	for i in count:
		# Элитки поверх обычной толпы: обводку не перекрывают поздние спавны.
		var slot := front
		if elite[i] == 1:
			slot = back
			back -= 1
		else:
			front += 1
		var o := slot * FLOATS_PER_INSTANCE
		var a := angle[i]
		var scale_factor := (ELITE_SCALE if elite[i] == 1 else 1.0) * (CLIMB_SCALE if climb[i] == 1 else 1.0)
		var c := cos(a) * scale_factor
		var s := sin(a) * scale_factor
		var p := pos[i]
		# Transform2D в буфере: x.x, y.x, 0, origin.x, x.y, y.y, 0, origin.y
		_buf[o] = c
		_buf[o + 1] = -s
		_buf[o + 3] = p.x
		_buf[o + 4] = s
		_buf[o + 5] = c
		_buf[o + 7] = p.y
		# вспышка + флаги: +2 — заморожен, +4 — горит, +8 — элитка
		_buf[o + 8] = flash[i] * 0.99 + (2.0 if freeze_t[i] > 0.0 else 0.0) + (4.0 if burn_t[i] > 0.0 else 0.0) + (8.0 if elite[i] == 1 else 0.0)
		var anim := int(_time * speed[i] * 0.2 + seed_value[i] * 4.0) % PixelArt.ANIM_FRAMES # шаги
		_buf[o + 9] = wounds[i] + 16 * (variant[i] * PixelArt.ANIM_FRAMES + anim) # кадр атласа
		_buf[o + 10] = holes[i]
		_buf[o + 11] = seed_value[i]
	_mm.buffer = _buf
	_mm.visible_instance_count = count


## Кишки у еле живых волочатся за спиной (рисуются под спрайтами орды).
func _draw() -> void:
	if debug_senses:
		_draw_senses()
	for i in count:
		if stage[i] < 3:
			continue
		var a := angle[i]
		var back := Vector2.from_angle(a + PI)
		var side := back.orthogonal()
		var p := pos[i] + back * 3.0
		var pts := PackedVector2Array([p])
		for k in range(1, 5):
			var wobble := sin(_time * 6.0 + seed_value[i] * 30.0 + k * 1.3) * 1.5
			pts.append(p + back * (k * 2.5) + side * wobble)
		draw_polyline(pts, Color(0.62, 0.32, 0.34), 1.0)
		PixelArt.draw_dot(self, pts[4], 0.9, Color(0.45, 0.06, 0.06))


## Отладка (F3): цвет состояния, конус взгляда у ближних, кольца шума.
func _draw_senses() -> void:
	var view := PixelArt.view_rect(self, 40.0)
	for n in _rings.size():
		var r := _rings[n]
		draw_arc(Vector2(r.x, r.y), r.z, 0.0, TAU, 48, Color(1.0, 0.9, 0.3, 0.5 * (1.0 - _ring_age[n] / 0.6)), 1.0)
	for i in count:
		var p := pos[i]
		if not view.has_point(p):
			continue
		var c := Color(1.0, 0.25, 0.2) if mind[i] == Mind.CHASE else (Color(1.0, 0.8, 0.2) if mind[i] == Mind.INVESTIGATE else Color(0.4, 0.8, 1.0))
		draw_circle(p + Vector2(0, -9), 1.5, c)
		if mind[i] != Mind.CHASE and player and p.distance_squared_to(player.global_position) < 250000.0:
			var h := heading[i]
			var vr := VISION_RANGE * (ROOF_VISION if climb[i] == 1 else 1.0)
			draw_line(p, p + h.rotated(acos(VISION_COS)) * vr, Color(c, 0.25), 1.0)
			draw_line(p, p + h.rotated(-acos(VISION_COS)) * vr, Color(c, 0.25), 1.0)


static func _make_quad(size: float) -> ArrayMesh:
	var h := size * 0.5
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
