class_name Boss
extends Node2D
## «Объект-7»: отдельный босс, без физических тел и нод на атаки.

const RADIUS := 18.0
const MAX_HP := 24000.0
const CHARGE_SPEED := 400.0
const CHARGE_COOLDOWN := 6.0
const CHARGE_OVERSHOOT := 200.0
const SLAM_COOLDOWN := 9.0
const ROAR_COOLDOWN := 15.0
const SLAM_WINDUP := 0.5
const SLAM_TIME := 0.6
const SLAM_RADIUS := 150.0
const SLAM_WIDTH := 20.0
const ROAR_TIME := 0.8
const SHED_TIME := 1.2
const CELL := Vector2(144.0, 144.0)

signal phase_changed(phase: int)
signal died(pos: Vector2)
signal charge_telegraph(from: Vector2, to: Vector2, time: float)
signal slam_started(pos: Vector2)
signal roar(count: int)
signal crushed(pos: Vector2, dir: Vector2)
signal armor_plate(pos: Vector2, dir: Vector2)

var horde: Horde
var player: Player
var effects: Effects
var floor_decals: FloorDecals
var camera: GameCamera
var arena: Rect2
var minutes := 0.0

var hp := MAX_HP
var phase := 1

enum State { WALK, TELEGRAPH, CHARGE, RECOVER, SLAM, ROAR, SHED }

var _alive := false
var _state := State.WALK
var _last_attack := -1
var _age := 0.0
var _time := 0.0
var _walk := 0.0
var _facing := Vector2.RIGHT
var _charge_cd := 0.0
var _slam_cd := 0.0
var _roar_cd := 0.0
var _contact_cd := 0.0
var _flash := 0.0
var _plate_damage := 0.0
var _blood_time := 0.0
var _charges_left := 0
var _charge_target := Vector2.ZERO
var _charge_from := Vector2.ZERO
var _charge_hit := false
var _telegraph_time := 1.0
var _recover_time := 0.6
var _slam_pos := Vector2.ZERO
var _slam_hit := false
var _slam_wave := false
var _wave_previous := 0.0
var _sheet: Texture2D
var _flash_material: ShaderMaterial
var _body: Node2D


func _ready() -> void:
	if ResourceLoader.exists("res://art/boss.png"):
		_sheet = PixelArt.tex("boss")
	# Один слой тела отделяет белую вспышку от телеграфов и тени.
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform float hit = 0.0; void fragment() { COLOR.rgb = mix(COLOR.rgb, vec3(1.0), hit); }"
	_flash_material = ShaderMaterial.new()
	_flash_material.shader = shader
	_body = Node2D.new()
	_body.material = _flash_material
	_body.draw.connect(_draw_sprite)
	add_child(_body)
	visible = _alive


func start(p: Vector2) -> void:
	hp = MAX_HP
	phase = 1
	_alive = true
	_state = State.WALK
	_last_attack = -1
	_age = 0.0
	_time = 0.0
	_walk = 0.0
	_facing = Vector2.RIGHT
	_charge_cd = 0.0
	_slam_cd = 0.0
	_roar_cd = 0.0
	_contact_cd = 0.0
	_flash = 0.0
	_plate_damage = 0.0
	_blood_time = 0.0
	_charges_left = 0
	_charge_hit = false
	_slam_hit = false
	_slam_wave = false
	global_position = _bounded(p)
	visible = true
	queue_redraw()


func take_damage(amount: float, dir: Vector2, at: Vector2) -> bool:
	if not _alive or _state == State.SHED or amount <= 0.0:
		return false
	var damage := amount * (0.75 if phase == 1 else 1.0)
	hp = maxf(hp - damage, 0.0)
	_flash = 0.08
	if hp <= 0.0:
		_alive = false
		visible = false
		_charges_left = 0
		_slam_wave = false
		died.emit(global_position)
		return true
	if phase == 1:
		_plate_damage += damage
		while _plate_damage >= 1500.0:
			_plate_damage -= 1500.0
			armor_plate.emit(at, dir.normalized() if dir != Vector2.ZERO else _facing)
		if hp <= MAX_HP * 0.5:
			_shed_armor()
	elif effects:
		effects.blood_hit(at, dir, false)
	queue_redraw()
	return false


func hit_test(p: Vector2, r: float) -> bool:
	return _alive and p.distance_squared_to(global_position) <= pow(RADIUS + maxf(r, 0.0), 2.0)


func is_alive() -> bool:
	return _alive


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	global_position = _bounded(global_position)
	_time += delta
	_age += delta
	_flash = maxf(_flash - delta, 0.0)
	_charge_cd = maxf(_charge_cd - delta, 0.0)
	_slam_cd = maxf(_slam_cd - delta, 0.0)
	_roar_cd = maxf(_roar_cd - delta, 0.0)
	_contact_cd = maxf(_contact_cd - delta, 0.0)
	if _state == State.SHED:
		if _age + 0.000001 >= SHED_TIME:
			_enter(State.WALK)
	elif player and not player.is_dead:
		match _state:
			State.WALK:
				_choose_attack()
				if _state == State.WALK:
					_move_to(global_position.move_toward(player.global_position, (40.0 if phase == 1 else 60.0) * delta))
					_contact()
			State.TELEGRAPH:
				if _age + 0.000001 >= _telegraph_time:
					_charge_hit = false
					_enter(State.CHARGE)
			State.CHARGE:
				_charge(delta)
			State.RECOVER:
				if _age + 0.000001 >= _recover_time:
					if _charges_left > 0:
						_begin_telegraph()
					else:
						_enter(State.WALK)
			State.SLAM:
				_slam()
			State.ROAR:
				if _age + 0.000001 >= ROAR_TIME:
					_roar_cd = ROAR_COOLDOWN
					_enter(State.WALK)
					roar.emit(15 if phase == 1 else 25)
	var moving := _state == State.WALK or _state == State.CHARGE
	if phase == 2 and moving and effects:
		_blood_time += delta
		if _blood_time >= 0.1:
			_blood_time = 0.0
			effects.emit(global_position + Vector2.from_angle(randf() * TAU) * 10.0, -_facing * 12.0, 0.3, Effects.BLOOD, 2.5, 5.0, true)
	queue_redraw()


func _choose_attack() -> void:
	var distance := global_position.distance_to(player.global_position)
	if distance > 180.0 and _charge_cd <= 0.0 and _last_attack != State.CHARGE:
		_begin_charge_series()
	elif distance < 120.0 and _slam_cd <= 0.0 and _last_attack != State.SLAM:
		_last_attack = State.SLAM
		_slam_pos = global_position
		_slam_hit = false
		_slam_wave = false
		_enter(State.SLAM)
	elif _roar_cd <= 0.0 and _last_attack != State.ROAR and _few_runners():
		_last_attack = State.ROAR
		_enter(State.ROAR)
		if effects:
			effects.blood_burst(global_position + _facing * 18.0, _facing, 18, 80.0, 0.8)
	elif _charge_cd <= 0.0 and _last_attack != State.CHARGE and distance > RADIUS + Player.RADIUS:
		# Дистанция задаёт приоритет, но не блокирует чередование при живых бегунах.
		_begin_charge_series()


func _begin_charge_series() -> void:
	_last_attack = State.CHARGE
	_charges_left = 1 if phase == 1 else 3
	_begin_telegraph()


func _few_runners() -> bool:
	if horde == null:
		return true
	var runners := 0
	for j in horde.query_radius(global_position, 260.0):
		if j >= 0 and j < horde.count and horde.dead[j] == 0 and horde.kind[j] == Horde.Kind.RUNNER:
			runners += 1
			if runners >= 8:
				return false
	return true


func _begin_telegraph() -> void:
	var offset := player.global_position - global_position
	if offset.length_squared() > 0.000001:
		_facing = offset.normalized()
	_charge_from = global_position
	# Луч до внутренней границы: вся туша остаётся в арене.
	var inner := _inner_arena()
	# Пролёт на CHARGE_OVERSHOOT за игрока, но не дальше края арены: босс не уезжает за экран.
	var distance := offset.length() + CHARGE_OVERSHOOT
	if absf(_facing.x) > 0.000001:
		var edge := inner.end.x if _facing.x > 0.0 else inner.position.x
		distance = minf(distance, maxf((edge - global_position.x) / _facing.x, 0.0))
	if absf(_facing.y) > 0.000001:
		var edge := inner.end.y if _facing.y > 0.0 else inner.position.y
		distance = minf(distance, maxf((edge - global_position.y) / _facing.y, 0.0))
	_charge_target = _bounded(global_position + _facing * distance)
	_telegraph_time = 1.0 if phase == 1 else 0.7
	_enter(State.TELEGRAPH)
	charge_telegraph.emit(_charge_from, _charge_target, _telegraph_time)


func _charge(delta: float) -> void:
	var from := global_position
	_move_to(from.move_toward(_charge_target, CHARGE_SPEED * delta))
	var to := global_position
	if not _charge_hit:
		var nearest := Geometry2D.get_closest_point_to_segment(player.global_position, from, to)
		if nearest.distance_squared_to(player.global_position) <= pow(RADIUS + Player.RADIUS, 2.0):
			_charge_hit = true # один запрос урона на проход, даже при неуязвимости
			player.take_damage(35.0)
	if not _alive or _state != State.CHARGE:
		return
	if horde:
		var middle := (from + to) * 0.5
		for j in horde.query_radius(middle, from.distance_to(to) * 0.5 + RADIUS):
			if j < 0 or j >= horde.count or horde.dead[j] != 0:
				continue
			var p := horde.pos[j]
			var nearest := Geometry2D.get_closest_point_to_segment(p, from, to)
			if nearest.distance_squared_to(p) <= pow(RADIUS + horde.radius[j], 2.0):
				if horde.damage(j, 9999.0, _facing, 300.0, WeaponDefs.Ammo.STANDARD, false, horde.pos[j], true):
					crushed.emit(p, _facing)
				if not _alive or _state != State.CHARGE:
					return
	if to.distance_squared_to(_charge_target) < 0.000001 or to == from:
		_charges_left -= 1
		_recover_time = 0.4 if _charges_left > 0 else 0.6
		if _charges_left == 0:
			_charge_cd = CHARGE_COOLDOWN
		_enter(State.RECOVER)


func _slam() -> void:
	if _age + 0.000001 < SLAM_WINDUP:
		return
	if not _slam_wave:
		_slam_wave = true
		_slam_cd = SLAM_COOLDOWN * (0.7 if phase == 2 else 1.0)
		if camera:
			camera.shake(6.0)
		slam_started.emit(_slam_pos)
		if not _alive or _state != State.SLAM:
			return
	var radius := SLAM_RADIUS * clampf((_age - SLAM_WINDUP) / SLAM_TIME, 0.0, 1.0)
	# Относительное движение игрока и фронта волны между двумя тиками.
	var relative := player.global_position.distance_to(_slam_pos) - radius
	if not _slam_hit:
		if absf(relative) <= SLAM_WIDTH * 0.5 + Player.RADIUS or _wave_previous * relative < 0.0:
			_slam_hit = true
			player.take_damage(25.0)
	_wave_previous = relative
	if _age + 0.000001 >= SLAM_WINDUP + SLAM_TIME:
		_slam_wave = false
		_enter(State.WALK)


func _contact() -> void:
	if _contact_cd <= 0.0 and global_position.distance_squared_to(player.global_position) <= pow(RADIUS + Player.RADIUS, 2.0):
		_contact_cd = 0.8
		player.take_damage(20.0 if phase == 1 else 25.0)


func _shed_armor() -> void:
	phase = 2
	_charges_left = 0
	_slam_wave = false
	_enter(State.SHED)
	if camera:
		camera.shake(9.0)
	if effects:
		effects.blood_burst(global_position, _facing, 100, 190.0, PI)
	for k in 8:
		var dir := Vector2.from_angle(float(k) * TAU / 8.0)
		armor_plate.emit(global_position + dir * 12.0, dir)
	phase_changed.emit(2)


func _enter(state: State) -> void:
	_state = state
	_age = 0.0
	if state == State.SLAM:
		_wave_previous = player.global_position.distance_to(global_position)


func _move_to(p: Vector2) -> void:
	var before := global_position
	global_position = _bounded(p)
	var step := global_position - before
	_walk += step.length()
	if step.length_squared() > 0.000001:
		_facing = step.normalized()


func _inner_arena() -> Rect2:
	var margin := Vector2(minf(RADIUS, maxf(arena.size.x, 0.0) * 0.5), minf(RADIUS, maxf(arena.size.y, 0.0) * 0.5))
	return Rect2(arena.position + margin, (arena.size - margin * 2.0).max(Vector2.ZERO))


func _bounded(p: Vector2) -> Vector2:
	var inner := _inner_arena()
	return p.clamp(inner.position, inner.end)


func _draw() -> void:
	if not _alive:
		return
	_draw_attacks()
	PixelArt.draw_dot(self, Vector2(1.0, 4.0), 20.0, Color(0.015, 0.012, 0.012, 0.55))
	if _body:
		_body.queue_redraw()


func _draw_sprite() -> void:
	var breath := 1.0 + 0.035 * sin(_time * (9.0 if _state == State.RECOVER else 3.0))
	var scale_factor := Vector2(breath, 1.0 / breath)
	if _state == State.SLAM and not _slam_wave:
		scale_factor *= Vector2(1.12, 0.8)
	if _state == State.SHED:
		scale_factor *= 1.0 + 0.07 * sin(_age * 45.0)
	if _sheet:
		var col := 4 if _state == State.CHARGE else int(_walk / 7.0) % 4
		_body.draw_set_transform(Vector2.ZERO, _facing.angle(), scale_factor * PixelArt.ART_SCALE)
		_body.draw_texture_rect_region(_sheet, Rect2(-CELL * 0.5, CELL), Rect2(Vector2(col, phase - 1) * CELL, CELL))
		_body.draw_set_transform(Vector2.ZERO)
	else:
		_body.draw_set_transform(Vector2.ZERO, _facing.angle(), scale_factor)
		_draw_body()
		_body.draw_set_transform(Vector2.ZERO)
	if _flash_material:
		_flash_material.set_shader_parameter("hit", 1.0 if _flash > 0.0 else 0.0)


func _draw_body() -> void:
	var armor := Color(0.32, 0.34, 0.22) if phase == 1 else Color(0.53, 0.07, 0.065)
	var light := Color(0.48, 0.48, 0.32) if phase == 1 else Color(0.76, 0.17, 0.13)
	PixelArt.draw_dot(_body, Vector2.ZERO, 18.5, Color(0.10, 0.065, 0.055))
	for side in [-1.0, 1.0]:
		var step := sin(_walk / 7.0 * PI * 0.5 + side * PI * 0.5) * 2.0
		PixelArt.draw_dot(_body, Vector2(-9.0 + step, side * 13.0), 7.0, armor.darkened(0.3))
		PixelArt.draw_dot(_body, Vector2(6.0, side * 12.0), 8.5, armor)
		PixelArt.draw_dot(_body, Vector2(7.0, side * 11.0), 5.5, light)
	PixelArt.draw_dot(_body, Vector2(-3.0, 0.0), 14.0, armor)
	PixelArt.draw_dot(_body, Vector2(-5.0, -2.0), 9.0, light)
	PixelArt.draw_dot(_body, Vector2(15.0, 0.0), 8.0, Color(0.18, 0.075, 0.045))
	PixelArt.draw_dot(_body, Vector2(18.0, 0.0), 5.0, light)
	PixelArt.draw_dot(_body, Vector2(19.0, -3.0), 1.5, Color(1.0, 0.35, 0.12))
	PixelArt.draw_dot(_body, Vector2(19.0, 3.0), 1.5, Color(1.0, 0.35, 0.12))
	if phase == 2:
		for k in 4:
			_body.draw_line(Vector2(-10.0 + k * 5.0, -5.0), Vector2(-7.0 + k * 5.0, 6.0), Color(0.22, 0.012, 0.012), 2.0)


func _draw_attacks() -> void:
	if _state == State.TELEGRAPH:
		var t := clampf(_age / _telegraph_time, 0.0, 1.0)
		# Интеграл растущей частоты: мигание ускоряется без скачков фазы.
		var alpha := 0.55 + 0.35 * sin(TAU * (2.0 * t + 5.0 * t * t))
		var a := to_local(_charge_from)
		var b := to_local(_charge_target)
		draw_line(a, b, Color(0.85, 0.025, 0.02, 0.1), RADIUS * 2.0)
		draw_line(a, b, Color(1.0, 0.12, 0.08, alpha), 2.0)
		draw_arc(b, 8.0, 0.0, TAU, 24, Color(1.0, 0.12, 0.08, alpha), 1.5)
	elif _state == State.SLAM:
		var p := to_local(_slam_pos)
		if not _slam_wave:
			draw_arc(p, SLAM_RADIUS, 0.0, TAU, 64, Color(1.0, 0.1, 0.05, 0.35 + 0.3 * _age / SLAM_WINDUP), 2.0)
		else:
			var t := clampf((_age - SLAM_WINDUP) / SLAM_TIME, 0.0, 1.0)
			draw_arc(p, maxf(0.1, SLAM_RADIUS * t), 0.0, TAU, 64, Color(0.85, 0.09, 0.035, 0.5), SLAM_WIDTH)
			draw_arc(p, maxf(0.1, SLAM_RADIUS * t), 0.0, TAU, 64, Color(1.0, 0.37, 0.18, 0.9), 2.0)
	elif _state == State.ROAR:
		for k in 3:
			var t := fposmod(_age / ROAR_TIME + float(k) / 3.0, 1.0)
			draw_arc(Vector2.ZERO, 20.0 + t * 100.0, 0.0, TAU, 48, Color(0.8, 0.25, 0.17, 0.5 * (1.0 - t)), 2.0)
