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
signal enemy_impact(pos: Vector2, dir: Vector2, variant: int, damage: float, impulse: float, id: int, explosive: bool)
signal impact_geometry(id: int, entry: Vector2, facing: float, weapon: int, through: bool, killed: bool)
signal player_touched(damage: float)
signal armor_hit(at: Vector2, dir: Vector2)
signal armor_detached(at: Vector2, dir: Vector2, facing: float, code: int, part: int)

enum Kind { SHAMBLER, RUNNER, FAT, SPITTER, INFANTRY, RIOT, JUGGERNAUT }
const GROUP_CAPACITY := 64

const KINDS := [
	{"hp": 10.0, "speed": 28.0, "damage": 6.0, "xp": 1, "credit_chance": 0.06, "credits": 1},
	{"hp": 6.0, "speed": 88.0, "damage": 4.0, "xp": 1, "credit_chance": 0.06, "credits": 1},
	{"hp": 60.0, "speed": 20.0, "damage": 10.0, "xp": 4, "credit_chance": 0.40, "credits": 2},
	{"hp": 15.0, "speed": 34.0, "damage": 5.0, "xp": 2, "credit_chance": 0.20, "credits": 2},
	{"hp": 18.0, "speed": 20.0, "damage": 6.0, "xp": 4, "credit_chance": 0.45, "credits": 2},
	{"hp": 22.0, "speed": 18.0, "damage": 6.0, "xp": 5, "credit_chance": 0.50, "credits": 2},
	{"hp": 65.0, "speed": 16.0, "damage": 10.0, "xp": 8, "credit_chance": 0.60, "credits": 3},
]
const ARMOR_HP := [[10.0, 22.0, 0.0, 0.0], [10.0, 14.0, 0.0, 55.0], [18.0, 40.0, 25.0, 0.0]]
var armor_mask := PackedByteArray()
var armor_head := PackedFloat32Array()
var armor_chest := PackedFloat32Array()
var armor_limbs := PackedFloat32Array()
var armor_shield := PackedFloat32Array()
var last_armor_blocked := false

## Результат одного удара сохраняется до сигналов смерти (они могут нанести другой урон).
class DamageResult:
	var target_uid := 0
	var armor_damage := 0.0
	var broken_mask := 0
	var wound_mask := 0
	var death_mask := 0
	var hp_damage := 0.0
	var hp_lost := 0.0
	var bonus_hp_lost := 0.0
	var overkill := 0.0
	var killed := false
var military_spawned := PackedInt32Array([0, 0, 0])
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
const SPAWN_EDGE := 40.0 # ZAI3/R5: появление сразу за краем экрана, по пути от входа к игроку
const FAR_GRACE := 4.0 # ZAI3/R4: столько секунд отставший дальше far_distance, прежде чем его перенесут
const FAR_MOVES_PER_TICK := 4
const CELL := 16.0
const MAX_COLLISION_RADIUS := RADIUS * ELITE_SCALE * 1.06
const SPRITE_SIZE := 16.0
const FLOATS_PER_INSTANCE := 12 # Transform2D (8) + custom (4)
const STEP_LENGTH := 6.0
const BLOODY_STEPS := 8
# стадии ран по доле HP: целый > 75% > ранен > 50% > изувечен > 25% > еле жив
const STAGE_THRESHOLDS := [0.75, 0.5, 0.25]
enum Trait { ORDINARY, LIMP, FRESH, CRAWLER, STUBBORN }
# Вероятности: 5% хромых, 5% свежих, 5% упорных, 4% ползунов у шаркунов.
const TRAIT_SPEED := [0.0036, -0.0564, 0.1036, -0.1364, 0.0036]
const DIRECT_RANGE := 700.0 # ближе — при свободном коридоре идём к игроку напрямую, мимо поля путей
const BASE_SPEED_MEAN := 1.025 # Среднее прежних диапазонов 0.85..1.20 и 0.95..1.10.

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
var _progress_pos := PackedVector2Array()
var _stuck_time := PackedFloat32Array()
var _far_time := PackedFloat32Array() # сколько секунд особь дальше far_distance (R4)
var _last_player := Vector2.INF
var player_velocity := Vector2.ZERO # сглаженная скорость игрока: перенос отставших «по ходу»
var separation_usec := 0
var collision_usec := 0
var profile_ticks := 0
var group_id := PackedInt32Array() # жетон события строя: участник пачки до конца окна (маршрутов нет)
var _group_serial := PackedInt32Array()
var _group_until := PackedFloat32Array()
var _next_group_id := 1
## Тесты (--crowd-test): снимки внутри тика — 0 до шага, 1 после шага, 2 после разделения, 3 итог.
var tick_probe := Callable()
var hp := PackedFloat32Array()
var max_hp := PackedFloat32Array()
var speed := PackedFloat32Array()
var body_scale := PackedFloat32Array()
var damage_mult := PackedFloat32Array()
var quirk := PackedByteArray()
var visual_code := PackedInt32Array()
var _variety_rng := RandomNumberGenerator.new()
var _variety_seeded := false
var angle := PackedFloat32Array()
var flash := PackedFloat32Array()
var _hit_push := PackedVector2Array()
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
var _blood_at := PackedVector2Array()
var _blood_amount := PackedFloat32Array()
var _blood_time := PackedFloat32Array()
var seed_value := PackedFloat32Array()
var feet := PackedByteArray() # сколько ещё шагов оставлять кровавые следы
var step_acc := PackedFloat32Array()
var uid := PackedInt32Array() # постоянный номер зомби (индексы меняются при уплотнении)
# статусы от патронов
var burn_t := PackedFloat32Array()
var burn_dps := PackedFloat32Array()
var burn_spread := PackedFloat32Array() # шанс поджечь соседей при смерти
var burn_r := PackedFloat32Array()
var shock_until := PackedFloat32Array() # Только поза и дым, без оглушения.
var bolt_dir := PackedVector2Array()
var _burn_started := PackedFloat32Array()
var _fire_previous := PackedVector2Array()
var _fire_drift := PackedVector2Array()
var _fire_render_time := 0.0
var _fire_mm: MultiMesh
var _fire_mat: ShaderMaterial
var _smoke_mat: ShaderMaterial
var _fire_light_mat: ShaderMaterial
var _fire_buf := PackedFloat32Array()
var chill := PackedFloat32Array() # замедление 0..0.6
var chill_hits := PackedByteArray()
var freeze_t := PackedFloat32Array()
var shatter := PackedByteArray() # Крио III: раскол ранит соседей
var cryo_contributors := PackedInt32Array()
var freeze_contributors := PackedInt32Array()
var freeze_epoch := PackedInt32Array()
var freeze_primary := PackedByteArray()
var freeze_used := PackedByteArray()

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
	armor_mask.resize(MAX_ENEMIES)
	armor_head.resize(MAX_ENEMIES)
	armor_chest.resize(MAX_ENEMIES)
	armor_limbs.resize(MAX_ENEMIES)
	armor_shield.resize(MAX_ENEMIES)
	process_priority = -10 # обновляемся раньше оружия, чтобы сетка была свежей
	pos.resize(MAX_ENEMIES)
	knock.resize(MAX_ENEMIES)
	steer.resize(MAX_ENEMIES)
	_progress_pos.resize(MAX_ENEMIES)
	_stuck_time.resize(MAX_ENEMIES)
	_far_time.resize(MAX_ENEMIES)
	group_id.resize(MAX_ENEMIES)
	_group_serial.resize(GROUP_CAPACITY)
	_group_until.resize(GROUP_CAPACITY)
	hp.resize(MAX_ENEMIES)
	max_hp.resize(MAX_ENEMIES)
	speed.resize(MAX_ENEMIES)
	body_scale.resize(MAX_ENEMIES)
	damage_mult.resize(MAX_ENEMIES)
	quirk.resize(MAX_ENEMIES)
	visual_code.resize(MAX_ENEMIES)
	angle.resize(MAX_ENEMIES)
	flash.resize(MAX_ENEMIES)
	_hit_push.resize(MAX_ENEMIES)
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
	_blood_at.resize(MAX_ENEMIES)
	_blood_amount.resize(MAX_ENEMIES)
	_blood_time.resize(MAX_ENEMIES)
	seed_value.resize(MAX_ENEMIES)
	feet.resize(MAX_ENEMIES)
	step_acc.resize(MAX_ENEMIES)
	uid.resize(MAX_ENEMIES)
	burn_t.resize(MAX_ENEMIES)
	burn_dps.resize(MAX_ENEMIES)
	burn_spread.resize(MAX_ENEMIES)
	burn_r.resize(MAX_ENEMIES)
	shock_until.resize(MAX_ENEMIES)
	bolt_dir.resize(MAX_ENEMIES)
	_burn_started.resize(MAX_ENEMIES)
	_fire_previous.resize(MAX_ENEMIES)
	_fire_drift.resize(MAX_ENEMIES)
	_fire_buf.resize(MAX_ENEMIES * FLOATS_PER_INSTANCE)
	chill.resize(MAX_ENEMIES)
	chill_hits.resize(MAX_ENEMIES)
	freeze_t.resize(MAX_ENEMIES)
	shatter.resize(MAX_ENEMIES)
	cryo_contributors.resize(MAX_ENEMIES)
	freeze_contributors.resize(MAX_ENEMIES)
	freeze_epoch.resize(MAX_ENEMIES)
	freeze_primary.resize(MAX_ENEMIES)
	freeze_used.resize(MAX_ENEMIES)
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
	mat.set_shader_parameter("military_atlas", PixelArt.tex("zombie_military_atlas"))
	mmi.material = mat
	add_child(mmi)
	_fire_mm = MultiMesh.new()
	_fire_mm.transform_format = MultiMesh.TRANSFORM_2D
	_fire_mm.use_custom_data = true
	_fire_mm.mesh = _make_fire_mesh()
	_fire_mm.instance_count = MAX_ENEMIES
	_fire_mm.visible_instance_count = 0
	var fire := MultiMeshInstance2D.new()
	fire.multimesh = _fire_mm
	_fire_mat = ShaderMaterial.new()
	_fire_mat.shader = preload("res://shaders/body_fire.gdshader")
	_fire_mat.set_shader_parameter("noise_tex", preload("res://shaders/fire_noise.tres"))
	fire.material = _fire_mat
	fire.z_index = 2
	add_child(fire)
	# Один буфер на три партии, без отдельной ноды на горящего.
	var smoke := MultiMeshInstance2D.new()
	smoke.multimesh = _fire_mm
	_smoke_mat = ShaderMaterial.new()
	_smoke_mat.shader = preload("res://shaders/fire_smoke.gdshader")
	_smoke_mat.set_shader_parameter("noise_tex", preload("res://shaders/fire_noise.tres"))
	smoke.material = _smoke_mat
	smoke.z_index = 3
	add_child(smoke)
	var light := MultiMeshInstance2D.new()
	light.multimesh = _fire_mm
	_fire_light_mat = ShaderMaterial.new()
	_fire_light_mat.shader = preload("res://shaders/fire_light.gdshader")
	light.material = _fire_light_mat
	light.z_index = 1
	add_child(light)


func setup(arena_rect: Rect2, target: Player, floor_layer: FloorDecals) -> void:
	arena = arena_rect
	# Статичная граница партии не зависит от пустого пула в первом кадре.
	var fire_bounds := arena_rect.grow(96.0)
	_fire_mm.custom_aabb = AABB(Vector3(fire_bounds.position.x, fire_bounds.position.y, -1.0), Vector3(fire_bounds.size.x, fire_bounds.size.y, 2.0))
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
	if not _variety_seeded:
		reset_variety_seed(randi())
	var body := _variety_rng.randf_range(-1.0, 1.0)
	var noise := _variety_rng.randf_range(-1.0, 1.0)
	var roll := _variety_rng.randf()
	quirk[i] = Trait.LIMP if roll < 0.05 else Trait.FRESH if roll < 0.10 else Trait.STUBBORN if roll < 0.15 else Trait.ORDINARY
	if k == Kind.SHAMBLER and roll >= 0.15 and roll < 0.19:
		quirk[i] = Trait.CRAWLER
	body_scale[i] = 1.0 + float(roundi(body * 8.0)) * 0.01
	if k >= Kind.INFANTRY:
		quirk[i] = Trait.ORDINARY
		body_scale[i] = 1.20 if k == Kind.JUGGERNAUT else 1.08 if k == Kind.RIOT else body_scale[i]
	damage_mult[i] = 1.0 + body * 0.07 + noise * 0.03
	# Диаметр элиты остаётся меньше ячейки: соседнего кольца расталкивания хватает.
	var collision_scale := 1.0 + (body_scale[i] - 1.0) * (0.75 if is_elite else 1.0)
	radius[i] = RADIUS * collision_scale * (ELITE_SCALE if is_elite else 1.0)
	if k >= Kind.INFANTRY:
		radius[i] = 6.9 if k == Kind.JUGGERNAUT else 5.4 if k == Kind.RIOT else radius[i]
	touch_cd[i] = 0.0
	spit_cd[i] = randf_range(SPIT_WINDUP, SPIT_COOLDOWN) if k == Kind.SPITTER else 0.0
	spit_windup[i] = 0.0
	pos[i] = p.clamp(arena.position + Vector2.ONE * radius[i], arena.end - Vector2.ONE * radius[i])
	if obstacles:
		pos[i] = obstacles.free_point(pos[i], radius[i])
	knock[i] = Vector2.ZERO
	steer[i] = Vector2.ZERO
	_progress_pos[i] = pos[i]
	_stuck_time[i] = 0.0
	_far_time[i] = 0.0
	group_id[i] = 0
	hp[i] = (1.0 + body * 0.16 + noise * 0.04) * KINDS[k]["hp"] * (1.0 + hp_growth_per_min * minutes) * (ELITE_HP if is_elite else 1.0)
	max_hp[i] = hp[i]
	var spread := 1.0 - body * (0.17 if k == Kind.RUNNER else 0.08) + noise * (0.05 if k == Kind.RUNNER else 0.03)
	# Поправка компенсирует редкие замедления, без дрейфа среднего типа.
	spread += TRAIT_SPEED[quirk[i]] - (0.0056 if k != Kind.SHAMBLER else 0.0)
	speed[i] = KINDS[k]["speed"] * BASE_SPEED_MEAN * spread * (ELITE_SPEED if is_elite else 1.0)
	angle[i] = 0.0
	flash[i] = 0.0
	_hit_push[i] = Vector2.ZERO
	dead[i] = 0
	var choices: Array = PixelArt.KIND_VARIANTS[mini(k, Kind.SPITTER)] if k < Kind.INFANTRY else [2 if k != Kind.RIOT else 9]
	variant[i] = choices[_variety_rng.randi_range(0, choices.size() - 1)]
	if quirk[i] == Trait.CRAWLER:
		variant[i] = 20
	elif quirk[i] == Trait.FRESH and k == Kind.SHAMBLER:
		variant[i] = 13 # спортсмен почти без старой крови
	elif quirk[i] == Trait.STUBBORN and k == Kind.SHAMBLER:
		variant[i] = 2 if _variety_rng.randf() < 0.5 else 9 # плотная форма и жилет
	var tone := _variety_rng.randi_range(0, PixelArt.CLOTH_TONES - 1)
	if k >= Kind.INFANTRY: tone = 0 # Одна ткань совпадает с собственными останками военных.
	var flags := roundi((body_scale[i] - 1.0) * 100.0) + 8 + (32 if _variety_rng.randf() < 0.5 else 0) + (64 if is_elite else 0)
	visual_code[i] = variant[i] + tone * PixelArt.VARIANT_COUNT + 64 * (flags + 1)
	armor_mask[i] = 0
	armor_head[i] = 0.0
	armor_chest[i] = 0.0
	armor_limbs[i] = 0.0
	armor_shield[i] = 0.0
	if k >= Kind.INFANTRY:
		var t := k - Kind.INFANTRY
		military_spawned[t] += 1
		var armor_scale := 1.0 + hp_growth_per_min * minutes
		armor_head[i] = ARMOR_HP[t][0] * armor_scale
		armor_chest[i] = ARMOR_HP[t][1] * armor_scale
		armor_limbs[i] = ARMOR_HP[t][2] * armor_scale
		armor_shield[i] = ARMOR_HP[t][3] * armor_scale
		armor_mask[i] = 7 if t == 2 else 11 if t == 1 else 3
		visual_code[i] = variant[i] + 64 * (flags + 1) + PixelArt.MILITARY_CODE + (t << 15)
	stage[i] = 0
	wounds[i] = PixelArt.WOUND_ARM_L if variant[i] == 15 else 0
	holes[i] = 0.0
	_blood_amount[i] = 0.0
	_blood_time[i] = -1000.0
	_blood_at[i] = Vector2(0.5, 0.5)
	seed_value[i] = (float(tone) + _variety_rng.randf() * 0.999) / float(PixelArt.CLOTH_TONES)
	feet[i] = 0
	step_acc[i] = 0.0
	uid[i] = _next_uid
	_next_uid += 1
	burn_t[i] = 0.0
	burn_dps[i] = 0.0
	burn_spread[i] = 0.0
	burn_r[i] = 0.0
	shock_until[i] = 0.0
	bolt_dir[i] = Vector2.ZERO
	_burn_started[i] = -1000.0
	_fire_previous[i] = pos[i]
	_fire_drift[i] = Vector2.ZERO
	chill[i] = 0.0
	chill_hits[i] = 0
	freeze_t[i] = 0.0
	cryo_contributors[i] = 0
	freeze_contributors[i] = 0
	freeze_epoch[i] = 0
	freeze_primary[i] = 0
	freeze_used[i] = 0
	shatter[i] = 0
	return i


func reset_variety_seed(value: int) -> void:
	_variety_rng.seed = value
	_variety_seeded = true


## Жетон пачки события: только срок жизни. Полный id защищает от повторного использования слота пула.
func make_group(lifetime: float) -> int:
	var id := _next_group_id
	_next_group_id += 1
	var slot := id % GROUP_CAPACITY
	_group_serial[slot] = id
	_group_until[slot] = _time + lifetime
	return id


func attach_group(i: int, id: int) -> void:
	group_id[i] = id
	steer[i] = Vector2.ZERO


func release_groups() -> void:
	_group_until.fill(-1.0)


## Форма задаёт стороны появления, а не маршрут: участник идёт к игроку как все. Истёкший жетон снимается.
func _group_direction(i: int, direct: Vector2) -> Vector2:
	var id := group_id[i]
	var slot := id % GROUP_CAPACITY
	if _group_serial[slot] != id or _time >= _group_until[slot]:
		group_id[i] = 0
		steer[i] = Vector2.ZERO
	return direct


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


## Точка появления за краем экрана, внутри арены. На карте со входами вход задаёт направление (ZAI3, R5):
## ближайший к center + ahead вход за экраном, затем шаги по полю путей к игроку до края экрана + SPAWN_EDGE.
func spawn_point(center: Vector2, ahead := Vector2.ZERO) -> Vector2:
	if not benchmark_spawn and not map_entries.is_empty():
		var view := PixelArt.view_rect(self, 88.0)
		var best := Vector2.INF
		var best_distance := INF
		var pick := center + ahead
		# Ближайший вход за экраном; небольшой разброс сохраняет несколько направлений.
		for entry in map_entries:
			if view.has_point(entry):
				continue
			var d := pick.distance_squared_to(entry) * randf_range(0.85, 1.15)
			if d < best_distance:
				best = entry
				best_distance = d
		if best != Vector2.INF:
			best = approach_point(best, PixelArt.view_rect(self, SPAWN_EDGE))
			return obstacles.free_point(best, RADIUS * 2.0) if obstacles else best
	var inner := arena.grow(-RADIUS * 2.0)
	for attempt in 12:
		var p := center + Vector2.from_angle(randf() * TAU) * spawn_ring
		if inner.has_point(p):
			return p
	return (center + Vector2.from_angle(randf() * TAU) * spawn_ring).clamp(inner.position, inner.end)


## Шаги по готовому полю путей (класс 1, якорь клетки — следующая точка к игроку), пока следующая точка
## не войдёт в view. Поле ещё не готово или путь не найден — точка остаётся на месте.
func approach_point(from: Vector2, view: Rect2) -> Vector2:
	if obstacles == null or not obstacles._nav_layers.has(1) or not obstacles._nav_layers[1]["ready"]:
		return from
	var layer: Dictionary = obstacles._nav_layers[1]
	var anchors: PackedVector2Array = layer["anchor"]
	var costs: PackedInt32Array = layer["distance"]
	if anchors.size() != obstacles.blocked.size() or costs.size() != anchors.size():
		return from
	var p := from
	for step in 512:
		var c := obstacles.cell_at(p)
		if costs[c] == Obstacles.NO_PATH or costs[c] == 0:
			break
		var next := anchors[c]
		if view.has_point(next) or next == p:
			break
		p = next
	return p


func spawn_group(center: Vector2, n: int, k := Kind.SHAMBLER) -> void:
	var origin := spawn_point(center)
	for j in n:
		spawn(origin + Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0)), k)


## Возвращает true, если враг умер. Тип смерти зависит от патронов, крита и оверкилла.
## hit_pos — где пуля коснулась зомби: по нему выбирается, какую руку оторвать.
func damage(i: int, amount: float, dir: Vector2, knockback: float, ammo := WeaponDefs.Ammo.STANDARD,
		crit := false, hit_pos := Vector2.INF, explosive := false, weapon := -1, through := false, armor_pen := -1.0,
		result: DamageResult = null, flat_bonus := 0.0) -> bool:
	last_armor_blocked = false
	if dead[i] == 1:
		return false
	if result: result.target_uid = uid[i]
	var total := amount + flat_bonus
	var freeze_mult := 1.25 if freeze_t[i] > 0.0 else 1.0
	var weighted := (amount * freeze_mult + flat_bonus) / maxf(total, 0.00001)
	amount = total
	if armor_mask[i] != 0 and (dir != Vector2.ZERO or explosive):
		var mask_before := armor_mask[i]
		var armor_before := armor_head[i] + armor_chest[i] + armor_limbs[i] + armor_shield[i]
		var pen := armor_pen if armor_pen >= 0.0 else WeaponDefs.armor_penetration(weapon)
		amount = _absorb_armor(i, amount, dir, hit_pos, 1.0 if explosive else pen, explosive)
		if result:
			result.armor_damage = armor_before - armor_head[i] - armor_chest[i] - armor_limbs[i] - armor_shield[i]
			result.broken_mask = mask_before & ~armor_mask[i]
		if last_armor_blocked:
			knock[i] += dir * knockback * 0.15
			return false
	amount *= weighted # прибавка Перелива не получает множитель льда
	if result:
		result.hp_damage = amount
		result.hp_lost = minf(amount, hp[i])
		var bonus_after_armor := amount * flat_bonus / maxf(total * weighted, 0.00001)
		result.bonus_hp_lost = result.hp_lost - minf(maxf(0.0, amount - bonus_after_armor), hp[i])
		result.overkill = maxf(0.0, amount - hp[i])
		result.killed = amount >= hp[i]
	hp[i] -= amount
	flash[i] = 1.0
	_hit_push[i] = dir * clampf(amount * 0.055 + knockback * 0.012, 0.5, 3.0)
	if dir != Vector2.ZERO:
		impact_geometry.emit(uid[i], hit_pos, angle[i], weapon, through, hp[i] <= 0.0)
		enemy_impact.emit(pos[i], dir, visual_code[i], amount, knockback, uid[i], explosive)
	knock[i] += dir * knockback * (0.3 if kind[i] == Kind.FAT or kind[i] == Kind.JUGGERNAUT else 1.0) * (0.45 if quirk[i] == Trait.STUBBORN else 1.0)
	holes[i] = clampf(maxf(holes[i] + 0.12, 1.0 - hp[i] / max_hp[i]), 0.0, 1.0)
	if hp[i] <= 0.0:
		dead[i] = 1
		if result: result.death_mask = armor_mask[i]
		for part in 4:
			_detach_armor(i, part, dir)
		var death := death_override if death_override >= 0 else _death_type(ammo, crit, amount >= max_hp[i] or explosive)
		if freeze_t[i] > 0.0 and death_override < 0:
			death = Gore.Death.ICE # замёрзший всегда раскалывается
		if kind[i] == Kind.FAT:
			death = Gore.Death.GIBS # лопается даже от огня, крио и отладочной смерти
		enemy_killed.emit(pos[i], dir, death, angle[i], visual_code[i])
		enemy_died.emit(pos[i], kind[i], elite[i] == 1)
		if kind[i] == Kind.FAT:
			fat_burst.emit(pos[i], elite[i] == 1)
		_on_death_status(i)
		return true
	if dir != Vector2.ZERO: # от огня (без направления) клочья не летят
		enemy_hit.emit(pos[i], dir, visual_code[i])
	var ratio := hp[i] / max_hp[i]
	var new_stage := 0
	for t: float in STAGE_THRESHOLDS:
		if ratio <= t:
			new_stage += 1
	var mask_before_wound := armor_mask[i]
	while stage[i] < new_stage:
		stage[i] += 1
		_apply_wound(i, stage[i], dir, hit_pos)
	if result: result.wound_mask = mask_before_wound & ~armor_mask[i]
	return false


## Щит имеет переднюю дугу; жилет пехоты открыт сзади. Пробитие не равно числу целей.
func _absorb_armor(i: int, amount: float, dir: Vector2, at: Vector2, pen: float, explosive: bool) -> float:
	var front := dir != Vector2.ZERO and dir.normalized().dot(Vector2.from_angle(angle[i])) < -0.35
	var local := Vector2.ZERO if at == Vector2.INF else (at - pos[i]).rotated(-angle[i])
	var part := 3 if front and armor_mask[i] & 8 else 0 if local.x > 1.0 else 2 if absf(local.y) > 2.7 else 1
	if not explosive and (not (armor_mask[i] & (1 << part)) or kind[i] != Kind.JUGGERNAUT and part != 3 and not front):
		return amount
	if explosive:
		for p in 4:
			if armor_mask[i] & (1 << p):
				var fragment_hp := maxf(0.0, _armor_hp(i, p) - amount)
				_set_armor_hp(i, p, fragment_hp)
				if fragment_hp <= 0.0: _detach_armor(i, p, dir)
		return amount
	var pool := _armor_hp(i, part)
	var absorbed := minf(pool, amount * (1.0 - clampf(pen, 0.0, 1.0)))
	# Даже пробивающая пуля разрушает крепления, а очередь постепенно снимает всю защиту.
	var remaining := maxf(0.0, pool - maxf(absorbed, amount * 0.55))
	_set_armor_hp(i, part, remaining)
	if remaining <= 0.0: _detach_armor(i, part, dir)
	if absorbed > 0.0:
		armor_hit.emit(pos[i] - dir.normalized() * radius[i] if at == Vector2.INF else at, dir)
	last_armor_blocked = amount - absorbed < 0.001
	return maxf(0.0, amount - absorbed)


func _armor_hp(i: int, part: int) -> float:
	match part:
		0: return armor_head[i]
		1: return armor_chest[i]
		2: return armor_limbs[i]
	return armor_shield[i]


func _set_armor_hp(i: int, part: int, value: float) -> void:
	match part:
		0: armor_head[i] = value
		1: armor_chest[i] = value
		2: armor_limbs[i] = value
		3: armor_shield[i] = value


func _detach_armor(i: int, part: int, dir: Vector2) -> void:
	if not (armor_mask[i] & (1 << part)):
		return
	armor_mask[i] &= ~(1 << part)
	armor_detached.emit(pos[i], dir, angle[i], visual_code[i], part)


## Новая стадия раны: что отрывается, решает сторона попадания.
func _apply_wound(i: int, st: int, dir: Vector2, hit_pos: Vector2) -> void:
	var wound := 0
	if st == 2:
		var side := 0
		if hit_pos != Vector2.INF:
			var local := (hit_pos - pos[i]).rotated(-angle[i]) / PixelArt.corpse_scale(visual_code[i])
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
	if kind[i] >= Kind.INFANTRY:
		if wound & PixelArt.WOUND_HEAD: _detach_armor(i, 0, dir)
		if wound & (PixelArt.WOUND_ARM_L | PixelArt.WOUND_ARM_R): _detach_armor(i, 2, dir)
		if st >= 3: _detach_armor(i, 1, dir)
	enemy_wounded.emit(pos[i], dir, angle[i], visual_code[i], st, wound)


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
	if burn_t[i] <= 0.0: _burn_started[i] = _time
	burn_t[i] = maxf(burn_t[i], duration)
	burn_dps[i] = maxf(burn_dps[i], dps)
	burn_spread[i] = maxf(burn_spread[i], spread_chance)
	burn_r[i] = maxf(burn_r[i], spread_r)


## Попадание Крио: замедление копится, после need попаданий — заморозка на 1.5 с.
func chill_hit(i: int, slow: float, need: int, shatter_on := false, instant := false, source_uid := 0, primary := false) -> void:
	if dead[i] == 1:
		return
	chill[i] = minf(chill[i] + slow, 0.6)
	chill_hits[i] = mini(chill_hits[i] + 1, 255)
	if primary and source_uid > 0 and source_uid <= WeaponDefs.MAX_SLOTS:
		cryo_contributors[i] |= 1 << (source_uid - 1)
	if shatter_on:
		shatter[i] = 1
	if instant or chill_hits[i] >= need:
		if freeze_t[i] <= 0.0:
			freeze_epoch[i] += 1
			freeze_contributors[i] = cryo_contributors[i]
			freeze_primary[i] = 1 if primary else 0
			freeze_used[i] = 0
		cryo_contributors[i] = 0
		freeze_t[i] = 1.5
		chill_hits[i] = 0


## Живые зомби в радиусе r от точки p.
func query_radius(p: Vector2, r: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	var cr := ceili((r + MAX_COLLISION_RADIUS) / CELL)
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
	var cr := ceili((r + MAX_COLLISION_RADIUS) / CELL)
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
	var probing := tick_probe.is_valid()
	if probing:
		tick_probe.call(0)
	_move(delta)
	if probing:
		tick_probe.call(1)
	_rebuild_grid()
	var before_separation := pos
	var profile_start := Time.get_ticks_usec() if obstacles and obstacles.profile_enabled else 0
	_separate()
	if probing:
		tick_probe.call(2)
	if profile_start:
		separation_usec += Time.get_ticks_usec() - profile_start
		profile_start = Time.get_ticks_usec()
	if obstacles:
		var near := obstacles.near_head
		for i in count:
			var p := pos[i]
			# Ограничиваем суммарный сдвиг толпы один раз на тело, а не каждую пару.
			if before_separation[i].distance_squared_to(p) > 16.0:
				p = obstacles.move_actor(obstacles.resolve(before_separation[i], radius[i]), p, radius[i])
			else:
				var c := obstacles.cell_at(p)
				if near[c] != -1 and obstacles._clearance[c] < radius[i]:
					p = obstacles.resolve(p, radius[i])
			pos[i] = p.clamp(arena.position + Vector2.ONE * radius[i], arena.end - Vector2.ONE * radius[i])
	if profile_start:
		collision_usec += Time.get_ticks_usec() - profile_start
		profile_ticks += 1
	if probing:
		tick_probe.call(3)
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
	var near := obstacles.near_head if obstacles else PackedInt32Array()
	if _last_player.is_finite() and delta > 0.0:
		player_velocity = player_velocity.lerp((ppos - _last_player) / delta, minf(1.0, delta * 2.0))
	_last_player = ppos
	var spit_view := PixelArt.view_rect(self, 16.0)
	var far_moves := 0
	for i in count:
		if dead[i] == 1:
			continue
		touch_cd[i] = maxf(touch_cd[i] - delta, 0.0)
		var frozen := freeze_t[i] > 0.0
		var p := pos[i]
		var old := p
		var to := ppos - p
		var d := to.length()
		if d > far_distance:
			_far_time[i] += delta
			# Отставший вне кадра дольше FAR_GRACE переносится к краю экрана по ходу игрока (R4, BALANCE §7.2):
			# роль, HP и черты остаются, лимит работает на экране, а не бредёт через карту.
			var instant := benchmark_spawn or map_entries.is_empty()
			if instant or (_far_time[i] >= FAR_GRACE and far_moves < FAR_MOVES_PER_TICK):
				far_moves += 0 if instant else 1
				p = spawn_point(ppos, player_velocity * 2.0)
				if obstacles:
					p = obstacles.free_point(p, radius[i])
				old = p
				to = ppos - p
				d = to.length()
				_far_time[i] = 0.0
				knock[i] = Vector2.ZERO
				steer[i] = Vector2.ZERO
				_progress_pos[i] = p
				_stuck_time[i] = 0.0
		else:
			_far_time[i] = 0.0
		var dir := to / d if d > 0.001 else Vector2.ZERO
		var k := knock[i]
		var spd := speed[i] * (1.0 - chill[i])
		if quirk[i] == Trait.LIMP:
			spd *= 1.0 + sin(_time * 7.0 + seed_value[i] * TAU) * 0.55
		elif quirk[i] == Trait.CRAWLER:
			spd *= 1.0 + sin(_time * 5.0 + seed_value[i] * TAU) * 0.20
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
		var move_dir := dir
		if group_id[i] != 0:
			move_dir = _group_direction(i, dir)
		if obstacles and (d > 90.0 or near[obstacles.cell_at(p)] != -1):
			# Запрос обхода распределён между четырьмя тиками орды.
			if (i + _frame) & 3 == 0:
				# Видно игрока — идём прямо к нему. Поле путей пересчитывается секундами и ведёт к точке,
				# где игрок был раньше: толпа копилась там и у стен (плейтест автора 2026-10-20).
				if d < DIRECT_RANGE and obstacles.body_clear(p, ppos, radius[i]):
					steer[i] = Vector2.ZERO
				else:
					steer[i] = obstacles.steering(p, dir, radius[i])
			if steer[i] != Vector2.ZERO:
				move_dir = steer[i]
		if obstacles and not frozen and d > 80.0 and (i + _frame) & 15 == 0:
			var progress_goal := ppos
			# Считаем приближение к цели: бег на месте вокруг угла тоже застревание.
			var progressed := p.distance_to(progress_goal) + 1.0 < _progress_pos[i].distance_to(progress_goal)
			_stuck_time[i] = 0.0 if progressed else _stuck_time[i] + delta * 16.0
			if progressed:
				_progress_pos[i] = p
			if _stuck_time[i] > 0.5:
				var normal := obstacles.wall_normal[obstacles.cell_at(p)]
				p += normal * 2.0
				_stuck_time[i] = 0.25
		if kind[i] == Kind.SPITTER:
			spit_cd[i] = maxf(spit_cd[i] - delta, 0.0)
			move_dir = -dir if d < 130.0 else (move_dir if d > 170.0 else Vector2.ZERO)
			if not frozen:
				if spit_windup[i] > 0.0:
					spit_windup[i] = maxf(spit_windup[i] - delta, 0.0)
					move_dir = Vector2.ZERO
					if spit_windup[i] == 0.0:
						# Плевок только из кадра: кислота не прилетает из-за края экрана (ZAI3, М2).
						if d >= 90.0 and d <= 260.0 and spit_view.has_point(p) and (obstacles == null or obstacles.line_clear(p, ppos)):
							spit_fired.emit(p, ppos, 10.0 * damage_mult[i] * damage_scale * (ELITE_DAMAGE if elite[i] == 1 else 1.0))
				elif spit_cd[i] <= 0.0 and d >= 90.0 and d <= 260.0 and spit_view.has_point(p):
					spit_windup[i] = SPIT_WINDUP
					spit_cd[i] = SPIT_COOLDOWN
					move_dir = Vector2.ZERO
		p += move_dir * spd * delta + k * delta
		# Обычный шаг разрешается один раз после расталкивания; быстрый отброс — со свипом.
		if obstacles and old.distance_squared_to(p) > 16.0:
			p = obstacles.move_actor(old, p, radius[i])
		knock[i] = k * decay
		# игрок «тяжёлый»: выталкивает зомби из себя
		var away := p - ppos
		var ad2 := away.length_squared()
		var touch_r := Player.RADIUS + radius[i]
		if ad2 < (touch_r + 1.0) * (touch_r + 1.0):
			if touch_cd[i] <= 0.0 and not frozen:
				var hit_damage: float = KINDS[kind[i]]["damage"] * damage_mult[i] * damage_scale * (ELITE_DAMAGE if elite[i] == 1 else 1.0)
				touch_damage = maxf(touch_damage, hit_damage)
				touch_cd[i] = TOUCH_COOLDOWN
			if ad2 > 0.0001 and ad2 < touch_r * touch_r:
				p = ppos + away / sqrt(ad2) * touch_r
		p = p.clamp(arena.position + Vector2.ONE * radius[i], arena.end - Vector2.ONE * radius[i])
		pos[i] = p
		var a := dir.angle() if freeze_t[i] <= 0.0 else angle[i]
		if group_id[i] != 0 and freeze_t[i] <= 0.0 and move_dir != Vector2.ZERO:
			a = move_dir.angle()
		if stage[i] == 3 and freeze_t[i] <= 0.0:
			a += sin(_time * 7.0 + seed_value[i] * 20.0) * 0.35 # еле живые шатаются
		angle[i] = rotate_toward(angle[i], a, delta * (0.85 if kind[i] == Kind.RIOT else 1.2)) if kind[i] >= Kind.INFANTRY else a
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
	for i in count:
		if dead[i] == 1:
			continue
		var p := pos[i]
		var ri := radius[i]
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
							dv = Vector2.from_angle(fposmod(seed_value[i] * 31.0 + seed_value[j] * 17.0, TAU)) * 0.1
							d2 = 0.01
						var d := sqrt(d2)
						var push := dv * ((min_d - d) / d * 0.5)
						p += push
						pos[j] = q - push
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
				_progress_pos[i] = _progress_pos[count]
				_stuck_time[i] = _stuck_time[count]
				_far_time[i] = _far_time[count]
				group_id[i] = group_id[count]
				hp[i] = hp[count]
				max_hp[i] = max_hp[count]
				speed[i] = speed[count]
				body_scale[i] = body_scale[count]
				damage_mult[i] = damage_mult[count]
				quirk[i] = quirk[count]
				visual_code[i] = visual_code[count]
				armor_mask[i] = armor_mask[count]
				armor_head[i] = armor_head[count]
				armor_chest[i] = armor_chest[count]
				armor_limbs[i] = armor_limbs[count]
				armor_shield[i] = armor_shield[count]
				angle[i] = angle[count]
				flash[i] = flash[count]
				_hit_push[i] = _hit_push[count]
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
				_blood_at[i] = _blood_at[count]
				_blood_amount[i] = _blood_amount[count]
				_blood_time[i] = _blood_time[count]
				seed_value[i] = seed_value[count]
				feet[i] = feet[count]
				step_acc[i] = step_acc[count]
				uid[i] = uid[count]
				burn_t[i] = burn_t[count]
				burn_dps[i] = burn_dps[count]
				burn_spread[i] = burn_spread[count]
				burn_r[i] = burn_r[count]
				shock_until[i] = shock_until[count]
				bolt_dir[i] = bolt_dir[count]
				_burn_started[i] = _burn_started[count]
				_fire_previous[i] = _fire_previous[count]
				_fire_drift[i] = _fire_drift[count]
				chill[i] = chill[count]
				chill_hits[i] = chill_hits[count]
				freeze_t[i] = freeze_t[count]
				shatter[i] = shatter[count]
				cryo_contributors[i] = cryo_contributors[count]
				freeze_contributors[i] = freeze_contributors[count]
				freeze_epoch[i] = freeze_epoch[count]
				freeze_primary[i] = freeze_primary[count]
				freeze_used[i] = freeze_used[count]
			dead[count] = 0
		else:
			i += 1


func _render() -> void:
	var front := 0
	var back := count - 1
	var fire_count := 0
	var fire_dt := _time - _fire_render_time
	_fire_render_time = _time
	var fire_view := arena if DisplayServer.get_name() == "headless" else PixelArt.view_rect(self, 80.0)
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
		if burn_t[i] > 0.0: a += sin(_time * 23.0 + seed_value[i] * 71.0) * 0.18
		if shock_until[i] > _time: a += sin(_time * 90.0 + seed_value[i] * 31.0) * 0.22
		var scale_factor := body_scale[i] * (ELITE_SCALE if elite[i] == 1 else 1.0)
		var mirror := -1.0 if ((visual_code[i] >> 6) - 1) & 32 else 1.0
		var c := cos(a) * scale_factor
		var s := sin(a) * scale_factor
		var p := pos[i] + _hit_push[i] * sin(flash[i] * PI)
		if shock_until[i] > _time: p += Vector2(sin(_time * 113.0), cos(_time * 97.0)) * 0.8
		if fire_dt > 0.0:
			# Фактическое движение, включая обход и отброс; переносы не дают длинного хвоста.
			if burn_t[i] > 0.0:
				var displacement := pos[i] - _fire_previous[i]
				var target_drift := Vector2.ZERO
				if fire_dt < 0.25 and displacement.length_squared() < 400.0:
					target_drift = -displacement / fire_dt * 0.07
				_fire_drift[i] = _fire_drift[i].lerp(target_drift, minf(1.0, fire_dt * 15.0))
			else:
				_fire_drift[i] = Vector2.ZERO
			_fire_previous[i] = pos[i]
		if burn_t[i] > 0.0 and fire_view.has_point(p):
			var f := fire_count * FLOATS_PER_INSTANCE
			var fire_size := scale_factor * (0.88 + seed_value[i] * 0.25)
			_fire_buf[f] = fire_size * (32.0 / 24.0)
			_fire_buf[f + 3] = p.x
			_fire_buf[f + 5] = fire_size * 2.0
			_fire_buf[f + 7] = p.y - 12.0 * fire_size
			_fire_buf[f + 8] = seed_value[i]
			var flare := maxf(0.0, 1.0 - (_time - _burn_started[i]) / 0.4)
			var intensity := (0.06 + 0.94 * minf(1.0, burn_t[i] / 0.8)) * (0.72 + seed_value[i] * 0.28 + flare * 0.65)
			_fire_buf[f + 9] = minf(1.0, burn_t[i] * 4.0)
			_fire_buf[f + 10] = a
			# Два бита LOD, выше — дрейф, в дробной части — интенсивность / 4.
			var far_fire := count > 300 and p.distance_squared_to(player.position) > 10000.0
			var drift := _fire_drift[i] / fire_size
			var dx := clampi(roundi(drift.x * 4.0), -16, 16) + 16
			var dy := clampi(roundi(drift.y * 4.0), -16, 16) + 16
			_fire_buf[f + 11] = float((2 if far_fire else 0) + (0 if far_fire and seed_value[i] > 0.25 else 1) + 4 * (dx + 33 * dy)) + intensity * 0.25
			fire_count += 1
		# Transform2D в буфере: x.x, y.x, 0, origin.x, x.y, y.y, 0, origin.y
		_buf[o] = c
		_buf[o + 1] = -s * mirror
		_buf[o + 3] = p.x
		_buf[o + 4] = s
		_buf[o + 5] = c * mirror
		_buf[o + 7] = p.y
		# вспышка + флаги: +2 — заморожен, +4 — горит, +8 — элитка
		_buf[o + 8] = flash[i] * 0.99 + (2.0 if freeze_t[i] > 0.0 else 0.0) + (4.0 if burn_t[i] > 0.0 else 0.0) + (8.0 if elite[i] == 1 else 0.0)
		if _burn_started[i] > -999.0: _buf[o + 8] += float(clampi(int((_time - _burn_started[i]) * 1.5), 0, 3)) * 16.0
		if shock_until[i] > _time: _buf[o + 8] += 64.0
		var anim := int(_time * speed[i] * (0.13 if quirk[i] == Trait.LIMP else 0.2) + seed_value[i] * 4.0) % PixelArt.ANIM_FRAMES # шаги
		_buf[o + 9] = wounds[i] + 16 * (variant[i] * PixelArt.ANIM_FRAMES + anim) # кадр атласа
		if kind[i] >= Kind.INFANTRY:
			_buf[o + 8] += 128.0
			_buf[o + 9] = armor_mask[i] + 16 * wounds[i] + 256 * ((kind[i] - Kind.INFANTRY) * 4 + anim)
		var stain := 0
		var wet := 0.0
		if _blood_amount[i] > 0.0:
			stain = clampi(roundi(_blood_at[i].x * 15.0), 0, 15) + clampi(roundi(_blood_at[i].y * 15.0), 0, 15) * 16 + clampi(ceili(_blood_amount[i] * 7.0), 1, 7) * 256
			wet = float(roundi(exp(-maxf(0.0, _time - _blood_time[i]) / 18.0) * 3.0) * 2)
		_buf[o + 10] = float(stain) + holes[i] * 0.99
		_buf[o + 11] = seed_value[i] + wet
	_mm.buffer = _buf
	_mm.visible_instance_count = count
	_fire_mm.visible_instance_count = fire_count
	if fire_count > 0:
		_fire_mm.buffer = _fire_buf
		_fire_mat.set_shader_parameter("fx_time", _time)
		_smoke_mat.set_shader_parameter("fx_time", _time)
		_fire_light_mat.set_shader_parameter("fx_time", _time)


## Кишки у еле живых волочатся за спиной (рисуются под спрайтами орды).
func _draw() -> void:
	for i in count:
		if bolt_dir[i] != Vector2.ZERO:
			var shaft := bolt_dir[i].rotated(angle[i])
			var tip := pos[i] + shaft * 3.0
			draw_line(tip - shaft * 10.0, tip, Color("ab9c77"), 0.65)
			draw_line(tip - shaft * 10.0, tip - shaft * 8.0 + shaft.orthogonal() * 1.5, Color("c9c7b5"), 0.7)
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


## Пятно на теле, два коротких языка, отрыв и уголь в одном экземпляре партии.
static func _make_fire_mesh() -> ArrayMesh:
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for part in 5:
		vertices.append_array(PackedVector2Array([Vector2(-12, -12), Vector2(12, -12), Vector2(12, 12), Vector2(-12, 12)]))
		var u := float(part * 2)
		uvs.append_array(PackedVector2Array([Vector2(u, 0), Vector2(u + 1, 0), Vector2(u + 1, 1), Vector2(u, 1)]))
		for corner in [0, 1, 2, 0, 2, 3]:
			indices.append(part * 4 + corner)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


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


## Только визуальный канал; пространственная сетка уже построена ордой.
func stain_blood(at: Vector2, r: float) -> void:
	for i in query_radius(at, r):
		_blood_at[i] = ((at - pos[i]).rotated(-angle[i]) / (SPRITE_SIZE * PixelArt.corpse_scale(visual_code[i])) + Vector2(0.5, 0.5)).clamp(Vector2(0.2, 0.2), Vector2(0.8, 0.8))
		_blood_amount[i] = minf(0.75, _blood_amount[i] + 0.22)
		_blood_time[i] = _time
