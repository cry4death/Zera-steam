class_name BossGeneral
extends Boss
## Командир держит строй щитом, накрывает отход миномётами и зовёт военных Z2.

const GENERAL_HP := 28000.0
const PLATES := [900.0, 2200.0, 1200.0, 1800.0]
const MORTAR_WARNING := 1.5
const MORTAR_RADIUS := 38.0
const MILITARY_CODE := PixelArt.MILITARY_CODE + (2 << 15) + 2
var sfx: Sfx
var explosions: Explosions
var armor := PackedFloat32Array(PLATES)
var armor_mask := 15
var _targets := PackedVector2Array()
var _timers := PackedFloat32Array()
var _struck := PackedByteArray()
var _mortar_cd := 2.5
var _squad_cd := 16.0
var _order_age := -1.0
var _attack_turn := 0
var summoned := 0
var _tex: Texture2D
var _gear: Array[Texture2D] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_tex = PixelArt.tex("boss_general")
	for part in 4:
		_gear.append(PixelArt.tex("boss_general_plate_%d" % part))
	z_index = 5
	visible = false


func display_name() -> String:
	return "Генерал"


func body_radius() -> float:
	return 26.0


func set_mission_profile(hp_mul: float, _shed_fraction: float) -> void:
	max_hp = GENERAL_HP * clampf(hp_mul, 1.0, 1.25)


func start(p: Vector2) -> void:
	max_hp = GENERAL_HP if max_hp == MAX_HP else max_hp
	super.start(p)
	if obstacles:
		global_position = obstacles.free_point(global_position, body_radius())
	armor = PackedFloat32Array(PLATES)
	armor_mask = 15
	_targets.clear()
	_timers.clear()
	_struck.clear()
	_mortar_cd = 2.5
	_squad_cd = 16.0
	_order_age = -1.0
	_attack_turn = 0
	summoned = 0
	_rng.seed = int(arena.size.x * 17.0 + arena.size.y * 41.0) ^ 20261020
	_charge_cd = 7.0
	_summon_squad()


func take_damage(amount: float, dir: Vector2, at: Vector2) -> bool:
	return take_armored_damage(amount, dir, at, 0.0, false)


func take_armored_damage(amount: float, dir: Vector2, at: Vector2, penetration: float, explosive: bool) -> bool:
	if not _alive or amount <= 0.0:
		return false
	var front := dir != Vector2.ZERO and dir.normalized().dot(_facing) < -0.35
	var local := (at - global_position).rotated(-_facing.angle())
	var part := 3 if front and armor_mask & 8 else (0 if local.x > 7.0 else (2 if absf(local.y) > 12.0 else 1))
	var damage := amount
	if explosive:
		for k in 4:
			_damage_plate(k, amount, dir)
	elif dir != Vector2.ZERO and armor_mask & (1 << part):
		var absorbed := minf(armor[part], amount * (1.0 - clampf(penetration, 0.0, 1.0)))
		_damage_plate(part, maxf(absorbed, amount * 0.55), dir)
		damage -= absorbed
		if absorbed > 0.0 and effects:
			effects.armor_impact(at, dir)
	if damage > 0.001:
		if effects:
			effects.blood_hit(at, dir, false)
		if _lose_hp(damage):
			_targets.clear()
			_timers.clear()
			_struck.clear()
			for k in 4:
				_damage_plate(k, PLATES[k], dir)
			if floor_decals:
				floor_decals.stamp(PixelArt.tex("boss_general_dead"), global_position, _facing.angle(), Color.WHITE, 1.0)
			return true
	var next := 3 if hp <= max_hp * 0.3 else (2 if hp <= max_hp * 0.65 else 1)
	if next != phase:
		_set_phase(next)
		_targets.clear()
		_timers.clear()
		_struck.clear()
		_mortar_cd = 2.0
		_squad_cd = minf(_squad_cd, 3.0)
	queue_redraw()
	return false


func _damage_plate(part: int, amount: float, dir: Vector2) -> void:
	if not (armor_mask & (1 << part)):
		return
	armor[part] = maxf(0.0, armor[part] - amount)
	if armor[part] <= 0.0:
		armor_mask &= ~(1 << part)
		# Тот же физический пул и детали, что у тяжёлого военного Z2.
		if horde:
			horde.armor_detached.emit(global_position, dir, _facing.angle(), MILITARY_CODE, part)


func _physics_process(delta: float) -> void:
	if not _alive or not player or player.is_dead:
		return
	_time += delta
	_age += delta
	_flash = maxf(0.0, _flash - delta)
	_contact_cd = maxf(0.0, _contact_cd - delta)
	_charge_cd -= delta
	_mortar_cd -= delta
	_squad_cd -= delta
	_tick_mortars(delta)
	if _order_age >= 0.0:
		_order_age += delta
		if _order_age >= 1.2:
			_order_age = -1.0
			_summon_squad()
	match _state:
		State.TELEGRAPH:
			if _age >= 1.0:
				_enter(State.CHARGE)
		State.CHARGE:
			var previous := global_position
			_move_to(global_position.move_toward(_charge_target, 330.0 * delta))
			var near := Geometry2D.get_closest_point_to_segment(player.global_position, previous, global_position)
			if not _charge_hit and near.distance_to(player.global_position) < body_radius() + Player.RADIUS:
				_charge_hit = true
				player.take_damage(35.0)
			if global_position.distance_to(_charge_target) < 3.0 or global_position.distance_to(previous) < 0.01 or _age > 1.4:
				_enter(State.RECOVER)
		State.RECOVER:
			if _age >= 1.0:
				_enter(State.WALK)
		_:
			var direction := player.global_position - global_position
			# ZAI6: поворачивается по пути в обход домов; вблизи и на открытом — к игроку, как раньше.
			var heading := _walk_point(player.global_position, 24.0, delta) - global_position
			if heading == Vector2.ZERO:
				heading = direction
			_facing = _facing.rotated(wrapf(heading.angle() - _facing.angle(), -PI, PI) * minf(1.0, delta * 1.6))
			if direction.length() > 125.0 and _order_age < 0.0:
				_move_to(global_position + _facing * 24.0 * delta)
			if _contact_cd <= 0.0 and direction.length() < body_radius() + Player.RADIUS:
				_contact_cd = 1.2
				player.take_damage(20.0)
			if _charge_cd <= 0.0 and _order_age < 0.0 and _ram_open(player.global_position):
				_begin_shield_charge()
			elif _mortar_cd <= 0.0:
				_begin_barrage()
			elif _squad_cd <= 0.0 and _order_age < 0.0:
				_order_age = 0.0
				_squad_cd = 23.0
	queue_redraw()


func _begin_shield_charge() -> void:
	_facing = (player.global_position - global_position).normalized()
	_charge_from = global_position
	_charge_target = _bounded(player.global_position + _facing * 95.0)
	_charge_hit = false
	_charge_cd = 10.0 if phase == 1 else 8.0
	_enter(State.TELEGRAPH)
	charge_telegraph.emit(_charge_from, _charge_target, 1.0)


func _inner_arena() -> Rect2:
	return arena.grow(-body_radius()) if arena.has_area() else arena


func _move_to(p: Vector2) -> void:
	var before := global_position
	if obstacles:
		p = obstacles.move_actor(before, p, body_radius())
	global_position = _bounded(p)
	_walk += global_position.distance_to(before)


func _begin_barrage() -> void:
	_attack_turn += 1
	var target := player.global_position
	var across := (target - global_position).normalized().orthogonal()
	for k in 2 + phase:
		if _targets.size() >= 12:
			break
		var lane := 0 if k == 0 else ((k + 1) / 2) * (1 if k % 2 == 0 else -1)
		_targets.append(_bounded(target + across * lane * 88.0 + _facing * (35.0 if k % 2 else 0.0)))
		_timers.append(-float(k) * 0.28)
		_struck.append(0)
	_mortar_cd = 6.0 if phase == 1 else 4.8
	if sfx:
		sfx.play("casings/mag_drop", global_position, 0.0, 0.0)


func _tick_mortars(delta: float) -> void:
	for i in range(_targets.size() - 1, -1, -1):
		_timers[i] += delta
		if _timers[i] >= MORTAR_WARNING and _struck[i] == 0:
			_struck[i] = 1
			if player.global_position.distance_to(_targets[i]) < MORTAR_RADIUS + Player.RADIUS:
				player.take_damage(30.0)
			if explosions:
				explosions.spawn(_targets[i], MORTAR_RADIUS, Explosions.Kind.GRENADE)
			if sfx:
				sfx.play("explosions/grenade", _targets[i], -5.0, 0.0)
		if _timers[i] > MORTAR_WARNING + 0.5:
			_targets.remove_at(i)
			_timers.remove_at(i)
			_struck.remove_at(i)


func _summon_squad() -> void:
	if not horde:
		return
	for k in 4 + phase:
		var offset := Vector2(-60.0 - (k / 3) * 27.0, (k % 3 - 1) * 34.0).rotated(_facing.angle())
		var at := _bounded(global_position + offset + Vector2.ONE * _rng.randf_range(-3, 3))
		if obstacles:
			at = obstacles.free_point(at, 9.0)
		if horde.spawn(at, Horde.Kind.JUGGERNAUT if k == 0 else (Horde.Kind.RIOT if k % 3 == 1 else Horde.Kind.INFANTRY)) >= 0:
			summoned += 1


func _draw() -> void:
	if not _alive:
		return
	for i in _targets.size():
		if _timers[i] < 0.0 or _struck[i] != 0:
			continue
		var p := to_local(_targets[i])
		var progress := clampf(_timers[i] / MORTAR_WARNING, 0.0, 1.0)
		var edge := Color("d4bb88")
		_ground_patch(p, MORTAR_RADIUS, Color(0.07, 0.06, 0.035, 0.65))
		var lines := PackedVector2Array()
		for side in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
			lines.append_array(PackedVector2Array([p + side * MORTAR_RADIUS, p + side * (MORTAR_RADIUS - 10.0)]))
		draw_multiline(lines, edge, 1.5)
		draw_arc(p, MORTAR_RADIUS * (1.0 - progress), 0, TAU, 24, edge, 0.8)
	if _state == State.TELEGRAPH:
		var a := to_local(_charge_from)
		var b := to_local(_charge_target)
		var side := _facing.orthogonal() * body_radius()
		draw_colored_polygon(PackedVector2Array([a - side, b - side, b + side, a + side]), Color(0.13, 0.13, 0.10, 0.65))
		draw_multiline(PackedVector2Array([a - side, b - side, a + side, b + side]), Color("d4bb88"), 1.0)
	draw_set_transform(Vector2.ZERO, _facing.angle())
	var rect := Rect2(-48, -48, 96, 96)
	draw_texture_rect(_tex, rect, false, Color(1.5, 1.4, 1.25) if _flash > 0 else Color.WHITE)
	for part in 4:
		if armor_mask & (1 << part):
			draw_texture_rect(_gear[part], rect, false)
	if _order_age >= 0.0:
		# Поднятая командирская рука — предвестник подхода отряда.
		draw_texture_rect_region(_tex, Rect2(4, -34 - 6 * sin(_order_age * PI / 1.2), 24, 19), Rect2(78, 45, 48, 38))
	draw_set_transform(Vector2.ZERO)
