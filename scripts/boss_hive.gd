class_name BossHive
extends Boss
## Два органических улья. Все атаки — фиксированные массивы, враги — общий Horde.

enum Hive { MOTHER, MEAT }
enum Attack { TENTACLE, BIOMASS, ROT, PIECE }
const MARK_LIMIT := 24
const HIVE_HP := [28000.0, 34000.0]
const SAC_HP := 600.0
const MARK_WARNING := [1.05, 1.35, 1.0, 0.85]
const MARK_RADIUS := [24.0, 34.0, 31.0, 12.0]
const MARK_DAMAGE := [25.0, 25.0, 0.0, 0.0]
const SAC_OFFSETS := [Vector2(-36, -26), Vector2(34, -25), Vector2(-35, 27), Vector2(35, 28)]

var hive := Hive.MOTHER
var sfx: Sfx
var _sacs := PackedFloat32Array()
var _marks := PackedVector2Array()
var _mark_age := PackedFloat32Array()
var _mark_kind := PackedInt32Array()
var _mark_hit := PackedByteArray()
var _mark_origin := PackedVector2Array()
var _attack_cd := 1.5
var _birth_cd := 5.0
var _birth_age := -1.0
var _roll_age := -1.0
var _roll_from := Vector2.ZERO
var _roll_to := Vector2.ZERO
var _roll_hit := false
var _rot_cd := 0.0
var _dead_age := -1.0
var _shed_layers := 0
var _slow_factor := 1.0
var _speed_before_slow := 0.0
var _speed_while_slow := 0.0
var _rng := RandomNumberGenerator.new()
var attacks_fired := PackedInt32Array([0, 0, 0, 0])
var births := 0
var pieces := 0
var rolls := 0
var direct_damage := 0.0
var _textures: Array[Texture2D] = []
var _sac_tex: Texture2D
var _tentacle_tex: Texture2D
var _piece_tex: Texture2D
var _rot_tex: Texture2D


func _ready() -> void:
	for k in 3:
		_textures.append(PixelArt.tex("boss_%s_%d" % ["mother" if hive == Hive.MOTHER else "meat", k + 1]))
	_sac_tex = PixelArt.tex("boss_sac")
	_tentacle_tex = PixelArt.tex("boss_tentacle")
	_piece_tex = PixelArt.tex("boss_piece")
	_rot_tex = PixelArt.tex("boss_rot")
	visible = false
	z_index = 5


func display_name() -> String:
	return "Матка" if hive == Hive.MOTHER else "Мясная гора"


func body_radius() -> float:
	return 31.0 if hive == Hive.MOTHER else [39.0, 29.0, 16.0][phase - 1]


## ZAI6 (З5): гора мягкая — для стен и пути радиус не больше MOVE_RADIUS_MAX, иначе в 1-й фазе (39 px) ей нужны
## улицы шире 80 px и из-за дома она не доходит. Попадания и касание — по полному радиусу.
const MOVE_RADIUS_MAX := 26.0


func move_radius() -> float:
	return minf(body_radius(), MOVE_RADIUS_MAX)


func set_mission_profile(hp_mul: float, _shed_fraction: float) -> void:
	# Гора ловит больше дроби и взрывов; больший запас компенсирует размер мишени.
	max_hp = HIVE_HP[hive] * clampf(hp_mul, 1.0, 1.25)


func start(p: Vector2) -> void:
	_restore_speed()
	max_hp = HIVE_HP[hive] if max_hp == MAX_HP else max_hp
	super.start(p)
	_rng.seed = int(global_position.x * 91.0 + global_position.y * 17.0) ^ 20261019
	_sacs = PackedFloat32Array([SAC_HP, SAC_HP, SAC_HP, SAC_HP])
	_marks.clear()
	_mark_age.clear()
	_mark_kind.clear()
	_mark_hit.clear()
	_mark_origin.clear()
	_attack_cd = 1.5
	_birth_cd = 4.0
	_birth_age = -1.0
	_roll_age = -1.0
	_dead_age = -1.0
	_rot_cd = 0.0
	_shed_layers = 0
	attacks_fired = PackedInt32Array([0, 0, 0, 0])
	births = 0
	pieces = 0
	rolls = 0
	direct_damage = 0.0
	global_position = _bounded(p)
	if obstacles:
		global_position = _bounded(obstacles.free_point(global_position, move_radius()))


func hit_test(p: Vector2, r: float) -> bool:
	if super.hit_test(p, r):
		return true
	if _alive and hive == Hive.MOTHER:
		for k in _sacs.size():
			if _sacs[k] > 0.0 and p.distance_to(global_position + SAC_OFFSETS[k]) <= 12.0 + maxf(r, 0.0):
				return true
	return false


func take_damage(amount: float, dir: Vector2, at: Vector2) -> bool:
	if not _alive or amount <= 0.0:
		return false
	if hive == Hive.MOTHER:
		for k in _sacs.size():
			if _sacs[k] > 0.0 and at.distance_to(global_position + SAC_OFFSETS[k]) < 15.0:
				_sacs[k] = maxf(0.0, _sacs[k] - amount)
				if _sacs[k] == 0.0:
					_birth_cd = minf(_birth_cd, 2.0)
					if effects:
						effects.blood_burst(at, dir, 18, 95.0, 1.4)
					_sound("gore/hit", -2.0)
				# Урон мешку не теряется для общего времени боя.
				break
	if hp <= amount:
		if OS.get_cmdline_user_args().has("--boss-sim"):
			print("BOSS hive_direct_damage=%.2f births=%d pieces=%d rolls=%d" % [direct_damage, births, pieces, rolls])
		_restore_speed()
		_marks.clear()
		_mark_age.clear()
		_mark_kind.clear()
		_mark_hit.clear()
		_mark_origin.clear()
		_birth_age = -1.0
		_roll_age = -1.0
		_dead_age = 0.0
		if floor_decals:
			floor_decals.stamp(_textures[2], global_position, 0.0, Color("693329"), 1.0 / 3.0)
	if _lose_hp(amount):
		visible = true # Разорванное тело остаётся на полу после сигнала смерти.
		return true
	var next_phase := 3 if hp <= max_hp * 0.30 else (2 if hp <= max_hp * 0.65 else 1)
	if hive == Hive.MEAT:
		var layers := mini(6, int((1.0 - hp / max_hp) / 0.115))
		while _shed_layers < layers:
			_shed_layers += 1
			_shed_piece(_shed_layers)
	if next_phase != phase:
		_set_phase(next_phase)
		_attack_cd = minf(_attack_cd, 0.7)
		_sound("zombies/boss_roar", -1.0)
		if effects:
			effects.blood_burst(global_position, dir, 36, 140.0, PI)
	if effects:
		effects.blood_hit(at, dir, false)
	queue_redraw()
	return false


func _physics_process(delta: float) -> void:
	_restore_speed()
	if not _alive:
		if _dead_age >= 0.0:
			_dead_age += delta
			queue_redraw()
		return
	_time += delta
	_flash = maxf(0.0, _flash - delta)
	_contact_cd = maxf(0.0, _contact_cd - delta)
	global_position = _bounded(global_position)
	if not player or player.is_dead:
		return
	_tick_marks(delta)
	_attack_cd -= delta
	if hive == Hive.MOTHER:
		_mother_step(delta)
	else:
		_meat_step(delta)
	queue_redraw()


func _mother_step(delta: float) -> void:
	# Туша только дышит; игрок сам выбирает сторону и мешки.
	_birth_cd -= delta
	if _birth_age >= 0.0:
		_birth_age += delta
		if _birth_age >= 1.5:
			_birth_age = -1.0
			var live := 0
			for k in _sacs.size():
				if _sacs[k] <= 0.0:
					continue
				live += 1
				for n in (2 if phase == 1 else 3):
					_spawn_enemy(global_position + SAC_OFFSETS[k] * 1.6 + Vector2(n * 7.0, 0), Horde.Kind.RUNNER if phase == 3 else Horde.Kind.SHAMBLER)
			if live == 0:
				# Повреждённые мешки больше не рожают: остаётся слабый выводок из пасти.
				for n in 2:
					_spawn_enemy(global_position + Vector2(0, 42 + n * 8), Horde.Kind.RUNNER)
			births += 1
			_birth_cd = maxf(3.2, 10.0 - float(phase - 1) * 1.5 - float(4 - live) * 0.9)
			_sound("gore/hit", -1.0)
	elif _birth_cd <= 0.0:
		_birth_age = 0.0
		_sound("zombies/boss_roar", -5.0)
	if _attack_cd <= 0.0:
		var kind := Attack.TENTACLE if _last_attack != Attack.TENTACLE else Attack.BIOMASS
		_last_attack = kind
		_begin_mark(player.global_position, kind)
		if kind == Attack.TENTACLE and phase >= 2:
			var side := (player.global_position - global_position).normalized().orthogonal()
			_begin_mark(player.global_position + side * 62.0, kind)
			if phase == 3:
				_begin_mark(player.global_position - side * 62.0, kind)
		_attack_cd = 3.8 - float(phase - 1) * 0.55
	_contact()


func _meat_step(delta: float) -> void:
	if _roll_age >= 0.0:
		_roll_age += delta
		var warning := 1.2 if phase < 3 else 0.8
		if _roll_age >= warning:
			var before := global_position
			_move_to(global_position.move_toward(_roll_to, (190.0 if phase < 3 else 290.0) * delta))
			if not _roll_hit:
				var hit := Geometry2D.get_closest_point_to_segment(player.global_position, before, global_position)
				if hit.distance_to(player.global_position) <= body_radius() + Player.RADIUS:
					_roll_hit = true
					_hurt_player(35.0)
			_rot_cd -= delta
			if _rot_cd <= 0.0 and phase < 3:
				_rot_cd = 0.65
				_begin_mark(global_position, Attack.ROT)
			if global_position.distance_to(_roll_to) < 1.0 or global_position == before:
				_roll_age = -1.0
				_attack_cd = 4.5 if phase < 3 else 2.6
		return
	# В ядре больше нет тяжёлого навала и следа гнили: короткие быстрые броски.
	_move_to(_walk_point(player.global_position, [18.0, 30.0, 96.0][phase - 1] * delta, delta))
	_contact()
	if _attack_cd <= 0.0 and _ram_open(player.global_position):
		_begin_roll()


func _begin_roll() -> void:
	_roll_age = 0.0
	_roll_hit = false
	_roll_from = global_position
	var dir := global_position.direction_to(player.global_position)
	_roll_to = _bounded(player.global_position + dir * (70.0 if phase < 3 else 35.0))
	_facing = dir
	_rot_cd = 0.0
	rolls += 1
	charge_telegraph.emit(_roll_from, _roll_to, 1.2 if phase < 3 else 0.8)
	_sound("zombies/boss_roar", -3.0)


func _begin_mark(at: Vector2, kind: int) -> void:
	if _marks.size() >= MARK_LIMIT:
		return
	_marks.append(at.clamp(arena.position + Vector2.ONE * MARK_RADIUS[kind], arena.end - Vector2.ONE * MARK_RADIUS[kind]))
	_mark_age.append(0.0)
	_mark_kind.append(kind)
	_mark_hit.append(0)
	_mark_origin.append(global_position)
	_sound("gore/hit", -5.0)


func _tick_marks(delta: float) -> void:
	for i in range(_marks.size() - 1, -1, -1):
		_mark_age[i] += delta
		var kind := _mark_kind[i]
		var age := _mark_age[i]
		var warn: float = MARK_WARNING[kind]
		if age >= warn:
			if _mark_hit[i] == 0:
				_mark_hit[i] = 1
				attacks_fired[kind] += 1
				if kind == Attack.PIECE:
					for n in 5:
						var offset := Vector2.from_angle(float(n) * TAU / 5.0) * 14.0
						if _spawn_enemy(_marks[i] + offset, Horde.Kind.SHAMBLER if n == 4 else Horde.Kind.RUNNER):
							pieces += 1
				elif kind != Attack.ROT:
					if player.global_position.distance_to(_marks[i]) <= MARK_RADIUS[kind] + Player.RADIUS:
						_hurt_player(MARK_DAMAGE[kind])
					if effects:
						effects.blood_burst(_marks[i], Vector2.UP, 12, 90.0, PI)
					_sound("gore/hit", 0.0)
			if kind == Attack.ROT and player.global_position.distance_to(_marks[i]) <= MARK_RADIUS[kind] + Player.RADIUS:
				_apply_slow()
		if age > warn + (6.0 if kind == Attack.ROT else 0.45):
			_marks.remove_at(i)
			_mark_age.remove_at(i)
			_mark_kind.remove_at(i)
			_mark_hit.remove_at(i)
			_mark_origin.remove_at(i)


func _spawn_enemy(at: Vector2, kind: int) -> bool:
	if horde:
		return horde.spawn(at, kind) >= 0
	return false


func _shed_piece(layer: int) -> void:
	var dir := Vector2.from_angle(float(layer) * 2.4 + _rng.randf_range(-0.15, 0.15))
	var at := global_position + dir * (body_radius() + 17.0)
	_begin_mark(at, Attack.PIECE)
	if effects:
		effects.blood_burst(at, dir, 18, 120.0, 0.8)
	if floor_decals:
		floor_decals.stamp(_piece_tex, at, dir.angle(), Color.WHITE, 1.0 / 3.0)


func _apply_slow() -> void:
	if _slow_factor == 1.0:
		_slow_factor = 0.60
		_speed_before_slow = player.move_speed
		player.move_speed *= _slow_factor
		_speed_while_slow = player.move_speed


func _restore_speed() -> void:
	if _slow_factor != 1.0 and is_instance_valid(player):
		if is_equal_approx(player.move_speed, _speed_while_slow):
			player.move_speed = _speed_before_slow
	_slow_factor = 1.0


func _exit_tree() -> void:
	_restore_speed()


func _inner_arena() -> Rect2:
	var margin := Vector2.ONE * body_radius()
	return Rect2(arena.position + margin, (arena.size - margin * 2.0).max(Vector2.ZERO))


func _move_to(p: Vector2) -> void:
	var before := global_position
	if obstacles:
		p = obstacles.move_actor(before, p, move_radius())
	global_position = _bounded(p)
	_walk += before.distance_to(global_position)


func _contact() -> void:
	if _contact_cd <= 0.0 and global_position.distance_to(player.global_position) <= body_radius() + Player.RADIUS:
		_contact_cd = 1.2 if hive == Hive.MEAT and phase == 3 else 0.8
		_hurt_player(20.0 if phase == 1 else 25.0)


func _hurt_player(amount: float) -> void:
	var before := player.damage_taken
	player.take_damage(amount)
	direct_damage += player.damage_taken - before


func _sound(id: String, volume: float) -> void:
	if sfx:
		if id == "zombies/boss_roar":
			id = "zombies/mother_roar" if hive == Hive.MOTHER else "zombies/meat_roar"
		sfx.play(id, global_position, volume, 0.02)


func _draw() -> void:
	if _textures.is_empty():
		return
	if not _alive:
		if _dead_age >= 0.0:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.25, 0.5))
			draw_texture_rect(_textures[2], Rect2(-48, -44, 96, 88), false, Color("743b32"))
			draw_set_transform(Vector2.ZERO)
		return
	_draw_hive_attacks()
	_ground_patch(Vector2(0, 6), body_radius() + 5.0, Color(0.025, 0.015, 0.012, 0.5), 0.8)
	var breath := 1.0 + sin(_time * (4.8 if phase == 3 else 2.4)) * 0.018
	var roll := 0.0
	if hive == Hive.MEAT and _roll_age > 1.2:
		roll = sin(_walk / 12.0) * 0.18
	draw_set_transform(Vector2.ZERO, roll, Vector2(breath, 1.0 / breath))
	draw_texture_rect(_textures[phase - 1], Rect2(-48, -44, 96, 88), false, Color(1.3, 0.85, 0.8) if _flash > 0.0 else Color.WHITE)
	draw_set_transform(Vector2.ZERO)
	if hive == Hive.MOTHER:
		for k in _sacs.size():
			var broken := _sacs[k] <= 0.0
			var torn := _sacs[k] <= SAC_HP * 0.5 or _birth_age >= 1.1
			var frame := 2 if broken else (1 if torn else 0)
			var swell := 1.0 if broken else 1.0 + (0.22 * _birth_age / 1.5 if _birth_age >= 0.0 else sin(_time * 2.0 + k) * 0.025)
			draw_texture_rect_region(_sac_tex, Rect2(SAC_OFFSETS[k] - Vector2(12, 15) * swell, Vector2(24, 30) * swell), Rect2(frame * 72, 0, 72, 90))


func _draw_hive_attacks() -> void:
	for i in _marks.size():
		var kind := _mark_kind[i]
		var age := _mark_age[i]
		var warning: float = MARK_WARNING[kind]
		var p := to_local(_marks[i])
		if kind == Attack.PIECE:
			if age < warning:
				var rise := sin(age / warning * PI) * 10.0
				draw_texture_rect(_piece_tex, Rect2(p - Vector2(12, 11 + rise), Vector2(24, 22)), false)
		elif age < warning:
			_warn_ground(_marks[i], MARK_RADIUS[kind], age / warning, kind == Attack.ROT)
			if kind == Attack.BIOMASS:
				var t := clampf(age / warning, 0.0, 1.0)
				var blob := to_local(_mark_origin[i]).lerp(p, t) + Vector2(0, -sin(t * PI) * 45.0)
				PixelArt.draw_dot(self, blob, 7.0, Color("291b16"))
				PixelArt.draw_dot(self, blob + Vector2(-1, -2), 5.0, Color("8c7850"))
		elif kind == Attack.TENTACLE:
			draw_texture_rect(_tentacle_tex, Rect2(p - Vector2(13, 48), Vector2(26, 58)), false)
		elif kind == Attack.BIOMASS:
			_ground_patch(p, MARK_RADIUS[kind], Color("736346"))
		else:
			var size: Vector2 = Vector2.ONE * MARK_RADIUS[kind] * 2.3 # прозрачное поле текстуры не уменьшает опасную область
			draw_texture_rect(_rot_tex, Rect2(p - size * 0.5, size), false)
	if _roll_age >= 0.0:
		var a := to_local(_roll_from)
		var b := to_local(_roll_to)
		var side := (b - a).normalized().orthogonal() * body_radius()
		draw_colored_polygon(PackedVector2Array([a - side, b - side, b + side, a + side]), Color(0.12, 0.045, 0.035, 0.28))
		draw_line(a - side, b - side, Color("c2a18c"), 1.0)
		draw_line(a + side, b + side, Color("c2a18c"), 1.0)
		var arrows := PackedVector2Array()
		for k in 5:
			var p := a.lerp(b, float(k + 1) / 6.0)
			var back := (a - b).normalized() * 7.0
			arrows.append_array(PackedVector2Array([p + back + side * 0.25, p, p, p + back - side * 0.25]))
		draw_multiline(arrows, Color("c2a18c"), 1.0)
