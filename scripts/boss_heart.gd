class_name BossHeart
extends Boss
## Сердце неподвижно; пол, атаки и стены — три постоянных слоя, без нод на атаку.

enum Attack { WAVE, WHIP, ACID }
const HEART_HP := 80000.0
const CORE_RADIUS := 26.0
const CORE_DAMAGE := 3.0
const WARNING := [1.15, 1.05, 1.4]
const DAMAGE := [25.0, 25.0, 25.0]
const HALF := [Vector2(350, 230), Vector2(320, 210), Vector2(290, 190), Vector2(265, 170)]
const LIMIT := 28
var sfx: Sfx
var _from := PackedVector2Array()
var _to := PackedVector2Array()
var _ages := PackedFloat32Array()
var _kinds := PackedByteArray()
var _hits := PackedByteArray()
var _rng := RandomNumberGenerator.new()
var _attack_cd := 2.0
var _brood_cd := 9.0
var _pulse_cd := 0.0
var _wall_cd := 0.0
var _cage_half: Vector2 = HALF[0]
var _phase_age := 0.0
var _dead_age := -1.0
var _death_step := 0
var _sequence := 0
var direct_damage := 0.0
var damage_sources := PackedFloat32Array([0, 0, 0, 0, 0])
var spawned := 0
var swallowed := 0
var attacks_fired := PackedInt32Array([0, 0, 0])
var _textures: Array[Texture2D] = []
var _wall: Texture2D
var _wave: Texture2D
var _whip: Texture2D
var _bubble: Texture2D
var _rot: Texture2D
var _dead: Texture2D
var _ground: Node2D
var _ground_material: ShaderMaterial
var _walls: Node2D
var _wall_mesh: ArrayMesh


func _ready() -> void:
	for k in 4:
		_textures.append(PixelArt.tex("boss_heart_%d" % (k + 1)))
	_wall = PixelArt.tex("hive_wall")
	_build_wall_mesh()
	_wave = PixelArt.tex("hive_wave")
	_whip = PixelArt.tex("hive_whip")
	_bubble = PixelArt.tex("hive_bubble")
	_rot = PixelArt.tex("boss_rot")
	_dead = PixelArt.tex("boss_heart_dead")
	z_index = 5
	_ground = Node2D.new()
	_ground.z_as_relative = false
	_ground.z_index = -1
	_ground_material = ShaderMaterial.new()
	_ground_material.shader = preload("res://shaders/hive_floor.gdshader")
	_ground.material = _ground_material
	_ground.draw.connect(_draw_floor)
	add_child(_ground)
	_walls = Node2D.new()
	_walls.z_as_relative = false
	_walls.z_index = 3
	_walls.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_walls.draw.connect(_draw_walls)
	add_child(_walls)
	visible = false


func display_name() -> String:
	return "Сердце Улья"


func body_radius() -> float:
	return 60.0


func set_mission_profile(hp_mul: float, _shed_fraction: float) -> void:
	max_hp = HEART_HP * clampf(hp_mul, 1.0, 1.25)


func start(p: Vector2) -> void:
	max_hp = HEART_HP if max_hp == MAX_HP else max_hp
	super.start(p)
	# Сердце всегда в центральном свободном месте существующего плана.
	global_position = arena.get_center() if arena.has_area() else p
	if obstacles:
		global_position = obstacles.free_point(global_position, body_radius() + 12.0)
	_rng.seed = int(arena.size.x * 13.0 + arena.size.y * 91.0) ^ 20261020
	_clear_attacks()
	_attack_cd = 2.0
	_brood_cd = 9.0
	_pulse_cd = 0.0
	_wall_cd = 0.0
	_cage_half = HALF[0]
	_phase_age = 0.0
	_dead_age = -1.0
	_death_step = 0
	_sequence = 0
	direct_damage = 0.0
	damage_sources = PackedFloat32Array([0, 0, 0, 0, 0])
	spawned = 0
	swallowed = 0
	attacks_fired = PackedInt32Array([0, 0, 0])
	if camera:
		camera.target = self
		camera.zoom = Vector2.ONE * 1.8
		camera.position = global_position
		camera.reset_smoothing()
	if _ground:
		_ground.queue_redraw()
		_ground_material.set_shader_parameter("alive", 1.0)
	queue_redraw()


func _clear_attacks() -> void:
	_from.clear()
	_to.clear()
	_ages.clear()
	_kinds.clear()
	_hits.clear()


func take_damage(amount: float, dir: Vector2, at: Vector2) -> bool:
	if not _alive or amount <= 0.0:
		return false
	var damage := amount * (0.72 if phase == 1 else 1.0)
	# Глубокое попадание или взрыв достают камеры даже под рёбрами оболочки.
	if at.distance_squared_to(global_position) <= CORE_RADIUS * CORE_RADIUS:
		damage *= CORE_DAMAGE
	if hp <= damage:
		if OS.get_cmdline_user_args().has("--boss-sim"):
			print("HEART direct_damage=%.2f sources=%s spawned=%d swallowed=%d attacks=%s" % [direct_damage, damage_sources, spawned, swallowed, attacks_fired])
		_clear_attacks()
		_dead_age = 0.0
		if _ground_material:
			_ground_material.set_shader_parameter("alive", 0.0)
		if floor_decals and floor_decals.hive_material:
			floor_decals.hive_material.set_shader_parameter("alive", 0.0)
		if sfx:
			sfx.play("zombies/heart_roar", global_position, 2.0, 0.0)
	if _lose_hp(damage):
		visible = true
		return true
	var next_phase := 4 if hp <= max_hp * 0.12 else (3 if hp <= max_hp * 0.40 else (2 if hp <= max_hp * 0.75 else 1))
	if next_phase != phase:
		_set_phase(next_phase)
		_phase_age = 0.0
		# Смена фазы даёт передышку, прежние предупреждения не превращаются в внезапный удар.
		_clear_attacks()
		_attack_cd = 2.0
		if effects:
			effects.blood_burst(global_position, dir, 36, 160.0, PI)
		if floor_decals:
			floor_decals.stamp(PixelArt.tex("boss_piece"), at, dir.angle(), Color.WHITE, 0.6)
		if camera:
			camera.shake(7.0)
	queue_redraw()
	return false


func _physics_process(delta: float) -> void:
	if not _alive:
		if _dead_age >= 0.0:
			_dead_age += delta
			# Последовательный обвал камер использует штатные кровь и останки R1e.
			if _death_step < 5 and _dead_age >= 0.22 * float(_death_step + 1):
				var at := global_position + Vector2.from_angle(float(_death_step) * 2.4) * (18.0 + _death_step * 8.0)
				if effects:
					effects.blood_burst(at, (at - global_position).normalized(), 26, 180.0, PI)
				if floor_decals:
					floor_decals.stamp(PixelArt.tex("boss_piece"), at, float(_death_step) * 2.4, Color("8e5142"), 0.7)
				_death_step += 1
			_walls.queue_redraw()
			queue_redraw()
		return
	_time += delta
	_phase_age += delta
	_flash = maxf(0.0, _flash - delta)
	_contact_cd = maxf(0.0, _contact_cd - delta)
	if not player or player.is_dead:
		return
	_tick_attacks(delta)
	_tick_walls(delta)
	_attack_cd -= delta
	_brood_cd -= delta
	_pulse_cd -= delta
	if _pulse_cd <= 0.0:
		_pulse_cd = [1.9, 1.5, 1.1, 0.8][phase - 1]
		if sfx:
			sfx.play("hive/pulse", global_position, -4.0, 0.0)
	if _attack_cd <= 0.0:
		_choose_heart_attack()
	if _brood_cd <= 0.0:
		_summon()
		_brood_cd = [22.0, 20.0, 17.0, 999.0][phase - 1]
	if _contact_cd <= 0.0 and player.global_position.distance_to(global_position) < body_radius() + Player.RADIUS:
		_contact_cd = 1.2
		_hurt(25.0)
	_walls.queue_redraw()
	queue_redraw()


func cage() -> Rect2:
	return Rect2(global_position - _cage_half, _cage_half * 2.0)


## Одна и та же неровная кромка используется рисунком и уроном стен.
func _wall_shape(angle: float) -> float:
	return 0.94 + 0.055 * sin(angle * 3.0 + 0.4) + 0.035 * sin(angle * 7.0 - 0.8) + 0.018 * sin(angle * 13.0 + 1.3)


func _wall_point(angle: float, half: Vector2) -> Vector2:
	return Vector2.from_angle(angle) * half * _wall_shape(angle)


func inside_tissue(at: Vector2, margin: float = 0.0) -> bool:
	var local := (at - global_position) / (_cage_half - Vector2.ONE * margin)
	return local.length() < _wall_shape(local.angle())


func _build_wall_mesh() -> void:
	var vertices := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for k in 129:
		var angle := TAU * k / 128.0
		var dir := Vector2.from_angle(angle)
		var inner := _wall_point(angle, HALF[0])
		var width := 49.0 + 17.0 * sin(angle * 5.0 + 0.5) + 12.0 * sin(angle * 9.0)
		for band in 2:
			var p := inner + dir * width * band
			vertices.append(Vector3(p.x, p.y, 0.0))
			uv.append(Vector2(float(k) / 128.0 * 8.0, float(band)))
		if k < 128:
			var n := k * 2
			indices.append_array(PackedInt32Array([n, n + 1, n + 2, n + 1, n + 3, n + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	_wall_mesh = ArrayMesh.new()
	_wall_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _tick_walls(delta: float) -> void:
	# Складки движутся медленно; светлый край точно совпадает с опасной границей.
	_cage_half = _cage_half.move_toward(HALF[phase - 1], 13.0 * delta)
	_wall_cd -= delta
	if _wall_cd > 0.0:
		return
	_wall_cd = 1.2
	if not inside_tissue(player.global_position, Player.RADIUS):
		_hurt(25.0, 3)
		if effects:
			effects.blood_hit(player.global_position, (global_position - player.global_position).normalized(), false)
	if horde:
		var eaten := 0
		for i in horde.count:
			if horde.dead[i] == 0 and not inside_tissue(horde.pos[i], -18.0):
				# Едим только у кромки; далёкие подкрепления продолжают идти на арену.
				if inside_tissue(horde.pos[i], -42.0):
					horde.damage(i, 99999.0, (global_position - horde.pos[i]).normalized(), 30.0)
					swallowed += 1
					eaten += 1
					if eaten >= 4:
						break


func _choose_heart_attack() -> void:
	_sequence += 1
	var target := player.global_position.clamp(cage().position + Vector2.ONE * 30.0, cage().end - Vector2.ONE * 30.0)
	if phase == 1:
		_begin_attack(target, Attack.WAVE if _sequence % 2 else Attack.WHIP)
	elif phase == 2:
		_begin_attack(target, Attack.ACID if _sequence % 2 else Attack.WAVE)
		if _sequence % 2:
			_begin_attack(target + Vector2(72, 0), Attack.ACID)
	elif phase == 3:
		_begin_attack(target, Attack.WAVE if _sequence % 2 else Attack.WHIP)
		_begin_attack(target + Vector2(0, 65), Attack.ACID)
	else:
		_begin_attack(target, Attack.WAVE)
		_begin_attack(target + Vector2(80, 0), Attack.WHIP)
	_attack_cd = [3.8, 3.4, 3.0, 2.7][phase - 1]


func _begin_attack(target: Vector2, kind: int) -> void:
	if _from.size() >= LIMIT:
		return
	var rect := cage().grow(-16.0)
	target = target.clamp(rect.position, rect.end)
	var origin := Vector2(rect.position.x, target.y)
	var end := Vector2(rect.end.x, target.y)
	if kind == Attack.WAVE and _sequence % 2 == 0:
		origin = Vector2(target.x, rect.position.y)
		end = Vector2(target.x, rect.end.y)
	elif kind == Attack.WHIP:
		# Щупальце идёт с ближайшего края до зафиксированной точки, никогда не доводится за игроком.
		var local := target - global_position
		origin = Vector2(rect.position.x if local.x < 0.0 else rect.end.x, target.y - 45.0)
		end = target
	elif kind == Attack.ACID:
		origin = target
		end = target
	_from.append(origin)
	_to.append(end)
	_ages.append(0.0)
	_kinds.append(kind)
	_hits.append(0)
	attacks_fired[kind] += 1
	if sfx:
		sfx.play("hive/flesh", target, -5.0, 0.0)


func _tick_attacks(delta: float) -> void:
	for i in range(_from.size() - 1, -1, -1):
		var kind := _kinds[i]
		var before := _ages[i]
		_ages[i] += delta
		var age := _ages[i]
		var warning: float = WARNING[kind]
		if age >= warning:
			var hit := false
			if kind == Attack.WAVE:
				var length := _from[i].distance_to(_to[i])
				var a := _from[i].move_toward(_to[i], maxf(0.0, before - warning) * 240.0)
				var b := _from[i].move_toward(_to[i], (age - warning) * 240.0)
				var dir := (_to[i] - _from[i]).normalized()
				var near := Geometry2D.get_closest_point_to_segment(player.global_position, a, b)
				var offset := player.global_position - near
				hit = absf(offset.dot(dir)) <= 10.0 + Player.RADIUS and absf(offset.dot(dir.orthogonal())) <= 33.0 + Player.RADIUS
				if age > warning + length / 240.0 + 0.3:
					_remove_attack(i)
					continue
			elif kind == Attack.WHIP:
				var closest := Geometry2D.get_closest_point_to_segment(player.global_position, _from[i], _to[i])
				hit = age <= warning + 0.25 and closest.distance_to(player.global_position) <= 13.0 + Player.RADIUS
				if age > warning + 0.55:
					_remove_attack(i)
					continue
			else:
				hit = player.global_position.distance_to(_to[i]) <= 27.0 + Player.RADIUS
				if before < warning:
					if sfx:
						sfx.play("hive/flesh", _to[i], 0.0, 0.0)
				if age > warning + 3.0:
					_remove_attack(i)
					continue
			if hit and _hits[i] == 0:
				_hits[i] = 1
				_hurt(DAMAGE[kind], kind)


func _remove_attack(i: int) -> void:
	_from.remove_at(i)
	_to.remove_at(i)
	_ages.remove_at(i)
	_kinds.remove_at(i)
	_hits.remove_at(i)


func _hurt(amount: float, source: int = 4) -> void:
	var before := player.damage_taken
	player.take_damage(amount)
	direct_damage += player.damage_taken - before
	damage_sources[source] += player.damage_taken - before


func _summon() -> void:
	if phase == 4 or not horde:
		return
	var count: int = [8, 10, 12, 0][phase - 1]
	for k in count:
		var angle := TAU * float(k) / count + _rng.randf_range(-0.08, 0.08)
		# Выводок вырывается из корней органа: взрывы по нему задевают и Сердце.
		var at := global_position + Vector2.from_angle(angle) * (body_radius() + 24.0)
		if obstacles:
			at = obstacles.free_point(at, 8.0)
		if horde.spawn(at, k % 4) >= 0:
			spawned += 1
	if sfx:
		sfx.play("zombies/heart_roar", global_position, -2.0, 0.0)


func _draw_floor() -> void:
	if not floor_decals or not floor_decals.hive_material:
		_ground.draw_texture_rect(PixelArt.tex("hive_floor"), Rect2(-HALF[0] - Vector2.ONE * 64, (HALF[0] + Vector2.ONE * 64) * 2.0), true)
	var vessels := PackedVector2Array()
	var branches := PackedVector2Array()
	for k in 8:
		var dir := Vector2.from_angle(float(k) * TAU / 8.0 + 0.13)
		var reach := minf(HALF[0].x / maxf(absf(dir.x), 0.001), HALF[0].y / maxf(absf(dir.y), 0.001)) + 20.0
		var a := dir * 58.0
		for n in 18:
			var progress := float(n + 1) / 18.0
			var b := dir * lerpf(60.0, reach, progress) + dir.orthogonal() * (sin(progress * 7.0 + k * 2.2) * 10.0 + sin(progress * 19.0 + k) * 3.0)
			vessels.append_array(PackedVector2Array([a, b]))
			if n % 5 == 2:
				var end := b + dir * 10.0 + dir.orthogonal() * (18.0 if n % 2 else -22.0)
				branches.append_array(PackedVector2Array([b, end]))
			a = b
	_ground.draw_multiline(vessels, Color("291c1b"), 8.0)
	_ground.draw_multiline(vessels, Color("58362f"), 4.0)
	_ground.draw_multiline(branches, Color("4d3030"), 1.3)


func _draw_walls() -> void:
	var collapse := clampf(_dead_age / 1.4, 0.0, 1.0) if not _alive else 0.0
	var half := _cage_half + Vector2.ONE * collapse * 35.0
	var tint := Color.WHITE.lerp(Color("4c3830"), collapse)
	var breath := 1.0 + (sin(_time * (3.0 + phase)) * 0.003 if _alive else 0.0)
	# 256 треугольников одним mesh; в кадре не пересобираем геометрию кольца.
	_walls.draw_set_transform(Vector2.ZERO, 0.0, half / HALF[0] * breath)
	_walls.draw_mesh(_wall_mesh, _wall, Transform2D.IDENTITY, tint)
	_walls.draw_set_transform(Vector2.ZERO)
	# Вросшие остовы: геометрия и проходимость существующей карты остаются прежними.
	for k in 3:
		var angle: float = [3.65, 5.68, 1.18][k]
		var at := _wall_point(angle, half) + Vector2.from_angle(angle) * 18.0
		_walls.draw_set_transform(at, angle + 0.7)
		_walls.draw_texture_rect_region(PixelArt.tex("map_vehicles"), Rect2(-38, -19, 76, 38), Rect2(3 * 288, 0, 288, 144), Color("777365"))
		_walls.draw_texture_rect(_wall, Rect2(-30, 0, 60, 24), false, tint)
	_walls.draw_set_transform(Vector2.ZERO)


func _draw() -> void:
	if _textures.is_empty():
		return
	if not _alive:
		var collapse := clampf(_dead_age / 1.5, 0.0, 1.0)
		draw_texture_rect(_dead, Rect2(-93, -34, 186, 68), false, Color.WHITE.lerp(Color("6b4138"), collapse))
		return
	_draw_attacks()
	var beat := pow(maxf(0.0, sin(_time * (3.2 + phase * 0.6))), 5.0)
	if phase < 4 and _brood_cd < 1.4:
		beat = maxf(beat, (1.4 - _brood_cd) / 1.4 * 2.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 + beat * 0.035, 1.0 - beat * 0.025))
	draw_texture_rect(_textures[phase - 1], Rect2(-90, -76, 180, 152), false, Color(1.22, 0.95, 0.85) if _flash > 0.0 else Color.WHITE)
	draw_set_transform(Vector2.ZERO)


func _draw_attacks() -> void:
	for i in _from.size():
		var kind := _kinds[i]
		var age := _ages[i]
		var warning: float = WARNING[kind]
		var a := to_local(_from[i])
		var b := to_local(_to[i])
		if kind == Attack.ACID:
			if age < warning:
				_warn_ground(_to[i], 28.0, age / warning, true)
				var size := Vector2.ONE * (16.0 + 28.0 * age / warning)
				draw_texture_rect(_bubble, Rect2(b - size * 0.5, size), false)
			else:
				draw_texture_rect(_rot, Rect2(b - Vector2(30, 26), Vector2(60, 52)), false)
			continue
		var dir := (b - a).normalized()
		var side := dir.orthogonal() * (34.0 if kind == Attack.WAVE else 14.0)
		if age < warning:
			draw_colored_polygon(PackedVector2Array([a - side, b - side, b + side, a + side]), Color(0.09, 0.025, 0.02, 0.55))
			draw_multiline(PackedVector2Array([a - side, b - side, a + side, b + side]), Color("c2a18a"), 0.8)
			# Нарастающие сухожилия у начала показывают направление выхода.
			draw_texture_rect(_wave, Rect2(a - Vector2(16, 12), Vector2(32, 24)), false, Color(1, 1, 1, 0.4 + age / warning * 0.6))
		elif kind == Attack.WAVE:
			var at := a.move_toward(b, (age - warning) * 240.0)
			draw_set_transform(at, dir.angle() - PI * 0.5)
			draw_texture_rect(_wave, Rect2(-36, -12, 72, 24), false)
			draw_set_transform(Vector2.ZERO)
		else:
			draw_set_transform(a, dir.angle() + PI * 0.5)
			draw_texture_rect(_whip, Rect2(-14, -a.distance_to(b), 28, a.distance_to(b)), false)
			draw_set_transform(Vector2.ZERO)
