class_name Horde
extends Node2D
## Орда: каждый зомби — строка в packed-массивах, без отдельных нод.
## Движение к игроку, расталкивание через spatial hash, рендер одним MultiMesh.
## Статы — BALANCE.md §2 (пока только шаркающий). Раны — GDD §6.4.

signal enemy_killed(pos: Vector2, dir: Vector2, death: int, facing: float, variant: int)
signal enemy_wounded(pos: Vector2, dir: Vector2, facing: float, variant: int, stage: int, wound: int)
signal enemy_hit(pos: Vector2, dir: Vector2, variant: int)
signal player_touched(damage: float)

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

@export var base_hp := 10.0
@export var base_speed := 28.0
@export var contact_damage := 6.0
@export var hp_growth_per_min := 0.12
@export var damage_growth_per_min := 0.05

var arena := Rect2()
var player: Player
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
var hp := PackedFloat32Array()
var max_hp := PackedFloat32Array()
var speed := PackedFloat32Array()
var angle := PackedFloat32Array()
var flash := PackedFloat32Array()
var dead := PackedByteArray()
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
var _head := PackedInt32Array()
var _next := PackedInt32Array()
var _frame := 0
var _next_uid := 1
var _time := 0.0

var _mm: MultiMesh
var _buf := PackedFloat32Array()


func _ready() -> void:
	process_priority = -10 # обновляемся раньше оружия, чтобы сетка была свежей
	pos.resize(MAX_ENEMIES)
	knock.resize(MAX_ENEMIES)
	hp.resize(MAX_ENEMIES)
	max_hp.resize(MAX_ENEMIES)
	speed.resize(MAX_ENEMIES)
	angle.resize(MAX_ENEMIES)
	flash.resize(MAX_ENEMIES)
	dead.resize(MAX_ENEMIES)
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
	mmi.material = mat
	add_child(mmi)


func setup(arena_rect: Rect2, target: Player, floor_layer: FloorDecals) -> void:
	arena = arena_rect
	player = target
	floor_decals = floor_layer
	_grid_w = ceili(arena.size.x / CELL)
	_grid_h = ceili(arena.size.y / CELL)
	_head.resize(_grid_w * _grid_h)


func spawn(p: Vector2) -> void:
	if count >= MAX_ENEMIES:
		return
	var i := count
	count += 1
	pos[i] = p.clamp(arena.position + Vector2.ONE * RADIUS, arena.end - Vector2.ONE * RADIUS)
	knock[i] = Vector2.ZERO
	hp[i] = base_hp * (1.0 + hp_growth_per_min * minutes)
	max_hp[i] = hp[i]
	speed[i] = base_speed * randf_range(0.85, 1.2)
	angle[i] = 0.0
	flash[i] = 0.0
	dead[i] = 0
	variant[i] = _pick_variant()
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


static func _pick_variant() -> int:
	var r := randf()
	for v in VARIANT_WEIGHTS.size():
		r -= VARIANT_WEIGHTS[v]
		if r <= 0.0:
			return v
	return 0


## Точка на кольце за краем экрана, внутри арены.
func spawn_point(center: Vector2) -> Vector2:
	var inner := arena.grow(-RADIUS * 2.0)
	for attempt in 12:
		var p := center + Vector2.from_angle(randf() * TAU) * spawn_ring
		if inner.has_point(p):
			return p
	return (center + Vector2.from_angle(randf() * TAU) * spawn_ring).clamp(inner.position, inner.end)


func spawn_group(center: Vector2, n: int) -> void:
	var origin := spawn_point(center)
	for k in n:
		spawn(origin + Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0)))


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
	knock[i] += dir * knockback
	holes[i] = minf(holes[i] + 0.12, 1.0)
	if hp[i] <= 0.0:
		dead[i] = 1
		var death := death_override if death_override >= 0 else _death_type(ammo, crit, amount >= max_hp[i] or explosive)
		if freeze_t[i] > 0.0 and death_override < 0:
			death = Gore.Death.ICE # замёрзший всегда раскалывается
		enemy_killed.emit(pos[i], dir, death, angle[i], variant[i])
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
		for j in query_radius(pos[i], 24.0):
			chill_hit(j, 0.3, 3, true)
			damage(j, 5.0, (pos[j] - pos[i]).normalized(), 40.0, WeaponDefs.Ammo.CRYO)


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
	var rr := (r + RADIUS) * (r + RADIUS)
	var cr := ceili((r + RADIUS) / CELL)
	var cx := int(p.x / CELL)
	var cy := int(p.y / CELL)
	for y in range(maxi(cy - cr, 0), mini(cy + cr + 1, _grid_h)):
		for x in range(maxi(cx - cr, 0), mini(cx + cr + 1, _grid_w)):
			var j := _head[x + y * _grid_w]
			while j != -1:
				if j < count and dead[j] == 0 and pos[j].distance_squared_to(p) <= rr:
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
	var rr := (RADIUS + r) * (RADIUS + r)
	var cx := int(p.x / CELL)
	var cy := int(p.y / CELL)
	for y in range(cy - 1, cy + 2):
		if y < 0 or y >= _grid_h:
			continue
		for x in range(cx - 1, cx + 2):
			if x < 0 or x >= _grid_w:
				continue
			var j := _head[x + y * _grid_w]
			while j != -1:
				if j < count and dead[j] == 0 and pos[j].distance_squared_to(p) <= rr:
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
	_compact()
	_move(delta)
	_rebuild_grid()
	_separate()
	_render()
	queue_redraw()
	update_ms = (Time.get_ticks_usec() - t0) / 1000.0


func _move(delta: float) -> void:
	var ppos := player.global_position
	var touch_r := Player.RADIUS + RADIUS
	var touch_r2 := (touch_r + 1.0) * (touch_r + 1.0)
	var lo := arena.position + Vector2.ONE * RADIUS
	var hi := arena.end - Vector2.ONE * RADIUS
	var decay := exp(-10.0 * delta)
	var touching := false
	for i in count:
		var p := pos[i]
		var old := p
		var to := ppos - p
		var d := to.length()
		if d > far_distance:
			# отставших возвращаем в кольцо, чтобы орда не терялась позади
			p = spawn_point(ppos)
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
		p += dir * spd * delta + k * delta
		knock[i] = k * decay
		# игрок «тяжёлый»: выталкивает зомби из себя
		var away := p - ppos
		var ad2 := away.length_squared()
		if ad2 < touch_r2:
			touching = true
			if ad2 > 0.0001 and ad2 < touch_r * touch_r:
				p = ppos + away / sqrt(ad2) * touch_r
		p = p.clamp(lo, hi)
		pos[i] = p
		var a := dir.angle() if freeze_t[i] <= 0.0 else angle[i]
		if stage[i] == 3 and freeze_t[i] <= 0.0:
			a += sin(_time * 7.0 + seed_value[i] * 20.0) * 0.35 # еле живые шатаются
		angle[i] = a
		flash[i] = maxf(flash[i] - delta * 10.0, 0.0)
		_feet_and_drips(i, p, old, a)
	if touching:
		player_touched.emit(contact_damage * (1.0 + damage_growth_per_min * minutes))


## Кровавые следы, если зомби прошёл по луже, и капли с раненых.
func _feet_and_drips(i: int, p: Vector2, old: Vector2, a: float) -> void:
	if floor_decals == null:
		return
	if (i + _frame) & 3 == 0 and floor_decals.is_wet(p):
		feet[i] = BLOODY_STEPS
	step_acc[i] += p.distance_to(old)
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
		var c := clampi(int(p.x / CELL), 0, _grid_w - 1) + clampi(int(p.y / CELL), 0, _grid_h - 1) * _grid_w
		_next[i] = _head[c]
		_head[c] = i


func _separate() -> void:
	var min_d := RADIUS * 2.0
	var min_d2 := min_d * min_d
	for i in count:
		var p := pos[i]
		var cx := int(p.x / CELL)
		var cy := int(p.y / CELL)
		for y in range(cy - 1, cy + 2):
			if y < 0 or y >= _grid_h:
				continue
			for x in range(cx - 1, cx + 2):
				if x < 0 or x >= _grid_w:
					continue
				var j := _head[x + y * _grid_w]
				while j != -1:
					if j > i:
						var q := pos[j]
						var dv := p - q
						var d2 := dv.length_squared()
						if d2 < min_d2:
							if d2 < 0.0001:
								dv = Vector2.from_angle(randf() * TAU) * 0.1
								d2 = 0.01
							var d := sqrt(d2)
							var push := dv * ((min_d - d) / d * 0.5)
							p += push
							pos[j] = q - push
					j = _next[j]
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
				hp[i] = hp[count]
				max_hp[i] = max_hp[count]
				speed[i] = speed[count]
				angle[i] = angle[count]
				flash[i] = flash[count]
				dead[i] = dead[count]
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
	for i in count:
		var o := i * FLOATS_PER_INSTANCE
		var a := angle[i]
		var c := cos(a)
		var s := sin(a)
		var p := pos[i]
		# Transform2D в буфере: x.x, y.x, 0, origin.x, x.y, y.y, 0, origin.y
		_buf[o] = c
		_buf[o + 1] = -s
		_buf[o + 3] = p.x
		_buf[o + 4] = s
		_buf[o + 5] = c
		_buf[o + 7] = p.y
		# вспышка + статусы для шейдера: +2 — заморожен, +4 — горит
		_buf[o + 8] = flash[i] * 0.99 + (2.0 if freeze_t[i] > 0.0 else 0.0) + (4.0 if burn_t[i] > 0.0 else 0.0)
		var anim := int(_time * speed[i] * 0.2 + seed_value[i] * 4.0) % PixelArt.ANIM_FRAMES # шаги
		_buf[o + 9] = wounds[i] + 16 * (variant[i] * PixelArt.ANIM_FRAMES + anim) # кадр атласа
		_buf[o + 10] = holes[i]
		_buf[o + 11] = seed_value[i]
	_mm.buffer = _buf
	_mm.visible_instance_count = count


## Кишки у еле живых волочатся за спиной (рисуются под спрайтами орды).
func _draw() -> void:
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
