class_name Player
extends Node2D
## Штурмовик: движение, рывок с неуязвимостью, урон и смерть.
## Статы — BALANCE.md §1.

signal hurt(amount: float)
signal died
signal dashed
signal grenade_landed(at: Vector2) # граната приземлилась: взрыв делает игра
signal adrenaline_fired # «Адреналин» (дерево класса): рывок зарядил все стволы

const RADIUS := 5.0
# граната (BALANCE.md §1): бросок на 100 px, дугой за 0.45 с
const GRENADE_DAMAGE := 40.0
const GRENADE_RADIUS := 50.0
const GRENADE_DISTANCE := 100.0
const GRENADE_COOLDOWN := 8.0
const GRENADE_TIME := 0.45
const GRENADE_ARC := 16.0 # высота дуги

@export var max_hp := 100.0
@export var move_speed := 80.0
@export var dash_distance := 60.0
@export var dash_time := 0.15
@export var dash_iframes := 0.25
@export var dash_cooldown := 2.0
@export var hit_iframes := 0.4

var hp := 100.0
var arena := Rect2()
var is_dead := false
var god_mode := false
var damage_taken := 0.0 # весь урон, дошедший до бойца (в бессмертии тоже считается — для отчёта --sim)
var autopilot := false # для бенчмарка: бегает по кругу сам
var auto_target := Vector2.INF # симуляция: бежать к образцам
var effects: Effects
var obstacles: Obstacles
var sfx: Sfx

var facing := Vector2.RIGHT
var aim_dir := Vector2.ZERO # направление оружия: выстрел или ручной прицел
const AIM_DEADZONE := 0.35
const STICK_AIM_DISTANCE := 140.0
var force_auto_aim := false # старые тесты не зависят от мыши и настроек
var manual_aim := false
var fire_requested := true
var aim_point := Vector2.ZERO # мировая точка прицела
var aim_gamepad := false
var aim_mouse_position := Vector2.ZERO # координаты viewport; камера применяется каждый тик
var _manual_dir := Vector2.RIGHT
var dash_cd := 0.0 # время до возврата следующего заряда рывка
var dash_max := 1 # зарядов рывка (дерево класса: «Рефлексы» +1)
var dash_left := 1
var adrenaline := false # «Адреналин»: рывок мгновенно перезаряжает все стволы
var adrenaline_cd := 0.0
var grenade_cd := 0.0
var class_id := "assault"
var class_active_t := 0.0
var class_anchor := Vector2.ZERO
var class_facing := Vector2.RIGHT
var stability := 0.0
var _close_return_cd := 0.0
var turret_mark := Vector2.INF
var turret_mark_t := 0.0
var tree_bonuses: Dictionary = ClassTree.DEFAULTS.duplicate()
var tree_still := 0.0
var _tree_unhurt := 0.0
var _tree_dash_t := 0.0
var _tree_grenade_t := 0.0
var _tree_heal_cd := 0.0
var _tree_cover_cd := 0.0
var _tree_rescued := false
var tree_reloading := false # Weapons обновляет один раз за кадр, без сигналов на каждый ствол
var dirt := 0.0 # насколько боец перемазан кровью
var _blood_at := Vector2(0.5, 0.5)
var _blood_amount := 0.0
var _blood_age := 1000.0
var _blood_material: ShaderMaterial

var _dash_t := 0.0
var _dash_dir := Vector2.RIGHT
var _iframes := 0.0
var _hurt_t := 0.0
var _auto_t := 0.0
var _dirt_stage := 0
var _frames: Array[Texture2D] = [] # стадия грязи × 4 + кадр ходьбы
var _walk := 0.0
var _kick := 0.0
var _moving := false
var _gren_t := -1.0 # время полёта гранаты, < 0 — не летит
var _gren_from := Vector2.ZERO
var _gren_to := Vector2.ZERO
var _gren_tex: Texture2D

const DIRT_STAGES := [0.0, 15.0, 50.0, 120.0]

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	aim_mouse_position = get_viewport().get_mouse_position()
	apply_bonuses(Meta.run_bonuses())
	var sheet := PixelArt.tex("player")
	# Убираем запечённый кончик старого автомата: модели теперь рисует Weapons.
	# Чистим каждый кадр один раз, сохраняя каску, рукава и стадии крови.
	var image := sheet.get_image()
	for y in 4:
		for x in PixelArt.ANIM_FRAMES:
			image.fill_rect(Rect2i(x * 48 + 34, y * 48 + 25, 14, 8), Color.TRANSPARENT)
			# Светлая ткань погон остаётся различима на всех стадиях крови.
			for patch: Rect2i in [Rect2i(18, 10, 5, 3), Rect2i(14, 32, 4, 3), Rect2i(7, 19, 2, 10)]:
				for py in range(patch.position.y, patch.end.y):
					for px in range(patch.position.x, patch.end.x):
						var point := Vector2i(x * 48 + px, y * 48 + py)
						if image.get_pixelv(point).a > 0.5:
							image.set_pixelv(point, Color("d0cdb4") if px > patch.position.x else Color("999c8c"))
	sheet = ImageTexture.create_from_image(image)
	for d in DIRT_STAGES.size():
		for a in PixelArt.ANIM_FRAMES:
			_frames.append(PixelArt.frame(sheet, a, d))
	sprite.texture = _frames[0]
	_blood_material = ShaderMaterial.new()
	_blood_material.shader = preload("res://shaders/flash.gdshader")
	_blood_material.set_shader_parameter("surface_mode", true)
	sprite.material = _blood_material
	sprite.scale = Vector2(PixelArt.ART_SCALE, PixelArt.ART_SCALE)
	_gren_tex = PixelArt.tex("grenade")
	queue_redraw()


var weapon_speed_mul := 1.0
## Давка (ZAI4, решение автора 2Б): орда ставит число касаний за тик; при ≥3 касаниях боец замедляется на 15 % за
## касание сверх двух, не больше −45 %. Рывок проходит сквозь толпу без замедления.
var crowd_contacts := 0
var crowd_slow := 0.0
const CROWD_SLOW_STEP := 0.15
const CROWD_SLOW_MAX := 0.45


func _physics_process(delta: float) -> void:
	class_tick(delta)
	_blood_age += delta
	if _blood_amount > 0.0:
		_blood_material.set_shader_parameter("surface_stain", Vector4(_blood_at.x, _blood_at.y, _blood_amount, exp(-_blood_age / 18.0)))
	_update_grenade(delta)
	if is_dead:
		return
	_recharge_dash(delta)
	adrenaline_cd = maxf(adrenaline_cd - delta, 0.0)
	grenade_cd = maxf(grenade_cd - delta, 0.0)
	_tree_dash_t = maxf(0.0, _tree_dash_t - delta)
	_tree_grenade_t = maxf(0.0, _tree_grenade_t - delta)
	_tree_heal_cd = maxf(0.0, _tree_heal_cd - delta)
	_tree_cover_cd = maxf(0.0, _tree_cover_cd - delta)
	_tree_unhurt += delta
	if _tree_unhurt >= 6.0:
		hp = minf(max_hp, hp + float(tree_bonuses["rest_heal"]) * delta)
	_iframes = maxf(_iframes - delta, 0.0)
	_hurt_t = maxf(_hurt_t - delta, 0.0)

	var input := _read_input(delta)
	_moving = input != Vector2.ZERO
	tree_still = 0.0 if _moving or _dash_t > 0.0 else tree_still + delta
	if _moving:
		facing = input.normalized()
	_update_aim()
	if Input.is_action_just_pressed("grenade"):
		throw_grenade()

	if Input.is_action_just_pressed("dash"):
		try_dash()

	var before := position
	if _dash_t > 0.0:
		_dash_t -= delta
		position += _dash_dir * (dash_distance / dash_time) * delta
		if effects:
			effects.ghost(position, sprite.rotation, sprite.texture)
	else:
		var want_slow := clampf(float(crowd_contacts - 2) * CROWD_SLOW_STEP, 0.0, CROWD_SLOW_MAX)
		crowd_slow = move_toward(crowd_slow, want_slow, delta * 3.0)
		position += input * move_speed * tree_speed_multiplier() * weapon_speed_mul * (1.0 - crowd_slow) * delta
	if obstacles:
		position = obstacles.move_actor(before, position, RADIUS)
	_walk += position.distance_to(before)
	_kick *= exp(-delta * 28.0)
	position = position.clamp(arena.position + Vector2.ONE * 8.0, arena.end - Vector2.ONE * 8.0)
	if manual_aim:
		_update_aim() # после движения курсор остаётся в той же мировой точке

	var look := aim_dir if aim_dir != Vector2.ZERO else facing
	sprite.rotation = look.angle()
	sprite.position = -look * minf(_kick * 0.8, 2.0) # откат плеч, прицел неподвижен
	sprite.texture = _frames[_dirt_stage * PixelArt.ANIM_FRAMES + int(_walk / 5.0) % PixelArt.ANIM_FRAMES]
	# мигание после удара + красная вспышка
	sprite.visible = _hurt_t <= 0.0 or int(_hurt_t * 20.0) % 2 == 0
	sprite.modulate = Color(1.0, 0.4, 0.4) if _hurt_t > hit_iframes - 0.1 else Color.WHITE


## Дерево класса на этот забег (Meta.run_bonuses): +HP, заряды рывка, «Адреналин».
func apply_bonuses(bonuses: Dictionary) -> void:
	class_id = Meta.class_id
	class_active_t = 0.0
	stability = 0.0
	turret_mark_t = 0.0
	_close_return_cd = 0.0
	tree_bonuses = ClassTree.DEFAULTS.duplicate()
	tree_bonuses.merge(bonuses, true)
	max_hp = 100.0 + float(bonuses["hp_add"])
	hp = max_hp
	dash_max = int(bonuses["dash_charges"])
	dash_left = dash_max
	dash_cd = 0.0
	adrenaline = bool(bonuses["adrenaline"])
	adrenaline_cd = 0.0
	move_speed = 80.0 * float(tree_bonuses["speed_mul"])
	dash_distance = 60.0 + float(tree_bonuses["dash_distance"])
	dash_cooldown = 2.0 * float(tree_bonuses["dash_cd_mul"])
	dash_iframes = 0.25 + float(tree_bonuses["dash_guard"])
	_tree_rescued = false
	_tree_unhurt = 0.0
	tree_still = 0.0
	_tree_dash_t = 0.0
	_tree_grenade_t = 0.0
	_tree_heal_cd = 0.0
	_tree_cover_cd = 0.0
	tree_reloading = false


func tree_speed_multiplier() -> float:
	return 1.0 + (float(tree_bonuses.get("bastion_move", 0.0)) if class_id == "gunner" and class_active_t > 0.0 else 0.0) + (float(tree_bonuses["reload_move"]) if tree_reloading else 0.0) + (float(tree_bonuses["dash_speed"]) if _tree_dash_t > 0.0 else 0.0) + (float(tree_bonuses["grenade_speed"]) if _tree_grenade_t > 0.0 else 0.0)


func tree_damage_multiplier(distance: float) -> float:
	var mul := tree_range_multiplier(distance)
	if class_id == "gunner":
		mul *= 1.0 + stability * (0.08 + float(tree_bonuses.get("brace_damage", 0.0)))
		if class_active_t > 0.0: mul *= 1.0 + float(tree_bonuses.get("bastion_rate", 0.0))
	if tree_still >= 1.0:
		mul *= 1.0 + float(tree_bonuses["standing_damage"])
	if hp < max_hp * 0.35:
		mul *= 1.0 + float(tree_bonuses["low_damage"])
	return mul


func tree_range_multiplier(distance: float) -> float:
	if distance >= 0.0 and distance <= 70.0:
		return 1.0 + float(tree_bonuses["close_damage"])
	if distance >= 140.0:
		return (1.0 + float(tree_bonuses["far_damage"])) * (1.0 + stability * float(tree_bonuses.get("brace_range", 0.0)) if class_id == "gunner" else 1.0)
	return 1.0


func tree_reload_cover() -> void:
	if _tree_cover_cd <= 0.0 and float(tree_bonuses["reload_cover"]) > 0.0:
		_iframes = maxf(_iframes, float(tree_bonuses["reload_cover"]))
		_tree_cover_cd = 3.0


## Рывок по текущему направлению; false — нет заряда. Заряды восстанавливаются по одному за dash_cooldown.
func try_dash() -> bool:
	if is_dead or dash_left <= 0:
		return false
	_dash_dir = facing
	_dash_t = dash_time
	dash_left -= 1
	if dash_cd <= 0.0:
		dash_cd = dash_cooldown
	_iframes = maxf(_iframes, dash_iframes)
	_tree_dash_t = 1.0
	grenade_cd = maxf(0.0, grenade_cd - float(tree_bonuses["dash_grenade"]))
	if _tree_heal_cd <= 0.0 and float(tree_bonuses["dash_heal"]) > 0.0:
		hp = minf(max_hp, hp + float(tree_bonuses["dash_heal"]))
		_tree_heal_cd = 10.0
	dashed.emit()
	if adrenaline and adrenaline_cd <= 0.0:
		adrenaline_cd = Meta.ADRENALINE_COOLDOWN
		adrenaline_fired.emit()
	return true


func _recharge_dash(delta: float) -> void:
	if dash_left >= dash_max:
		dash_cd = 0.0
		return
	dash_cd = maxf(dash_cd - delta, 0.0)
	if dash_cd <= 0.0:
		dash_left += 1
		if dash_left < dash_max:
			dash_cd = dash_cooldown


func _read_input(delta: float) -> Vector2:
	if autopilot:
		_auto_t += delta
		if auto_target != Vector2.INF and position.distance_to(auto_target) > 2.0:
			return (auto_target - position).normalized()
		return Vector2.from_angle(_auto_t * 0.5).orthogonal()
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


## Последнее устройство выбирает прицел; отклонённый правый стик всегда перехватывает авто.
func _input(event: InputEvent) -> void:
	if force_auto_aim or autopilot:
		return
	if event is InputEventMouseMotion:
		aim_mouse_position = event.position
		if event.relative.length_squared() > 0.25:
			aim_gamepad = false
	elif event is InputEventMouseButton:
		aim_mouse_position = event.position
		aim_gamepad = false
	elif event is InputEventJoypadMotion:
		if event.axis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y] and absf(event.axis_value) > AIM_DEADZONE:
			aim_gamepad = true
		elif event.axis == JOY_AXIS_TRIGGER_RIGHT and event.axis_value > 0.25:
			aim_gamepad = true


## Единственный источник направления для бойца, всех стволов и HUD.
func _update_aim() -> void:
	manual_aim = false
	fire_requested = true
	if force_auto_aim or autopilot:
		return
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", 0.0)
	var stick_active := stick.length() > AIM_DEADZONE
	if stick_active:
		aim_gamepad = true
		_manual_dir = stick.normalized()
	var auto_fire: bool = Meta.settings["auto_fire"]
	manual_aim = not auto_fire or stick_active or Input.is_action_pressed("aim_override")
	fire_requested = auto_fire or Input.is_action_pressed("fire")
	if aim_gamepad:
		aim_point = global_position + _manual_dir * STICK_AIM_DISTANCE
	else:
		aim_point = get_canvas_transform().affine_inverse() * aim_mouse_position
		var offset := aim_point - global_position
		if offset.length_squared() > 0.01:
			_manual_dir = offset.normalized()
	if manual_aim:
		aim_dir = _manual_dir


func take_damage(amount: float, source: Vector2 = Vector2.INF) -> void:
	if is_dead or _iframes > 0.0:
		return
	amount *= float(tree_bonuses["hurt_mul"])
	if class_id == "gunner" and class_active_t > 0.0 and source != Vector2.INF and (source - position).normalized().dot(class_facing) > 0.25:
		amount *= 0.25
	_tree_unhurt = 0.0
	damage_taken += amount
	if god_mode:
		return
	hp -= amount
	if hp <= 0.0 and not _tree_rescued and float(tree_bonuses["rescue_hp"]) > 0.0:
		hp = minf(max_hp, float(tree_bonuses["rescue_hp"]))
		_tree_rescued = true
		_iframes = 1.0
	_iframes = maxf(_iframes, hit_iframes)
	_hurt_t = hit_iframes
	hurt.emit(amount)
	if hp <= 0.0:
		hp = 0.0
		is_dead = true
		sprite.visible = false
		died.emit()


## Боец пачкается от близких убийств и ранений; спрайт меняется по стадиям.
func add_dirt(amount: float) -> void:
	dirt += amount
	var st := 0
	for i in DIRT_STAGES.size():
		if dirt >= DIRT_STAGES[i]:
			st = i
	_dirt_stage = st


## Пятно от упавшей капли привязано к ткани, не к мировой точке.
func stain_blood(at: Vector2, size: float) -> void:
	_blood_at = ((at - global_position).rotated(-sprite.rotation) / 16.0 + Vector2(0.5, 0.5)).clamp(Vector2(0.2, 0.2), Vector2(0.8, 0.8))
	_blood_amount = minf(0.72, _blood_amount + size * 0.12)
	_blood_age = 0.0
	_blood_material.set_shader_parameter("surface_stain", Vector4(_blood_at.x, _blood_at.y, _blood_amount, 1.0))


## Отдача при выстреле.
func kick(strength := 1.0) -> void:
	_kick = minf(_kick + strength, 3.0)


func is_dashing() -> bool:
	return _dash_t > 0.0


## Бросок гранаты: в ручной прицел; в авто — по движению, стоя — по стволу.
## Возвращает false, если граната ещё на перезарядке.
func throw_grenade() -> bool:
	if is_dead or grenade_cd > 0.0 or _gren_t >= 0.0:
		return false
	grenade_cd = ability_cooldown()
	class_facing = grenade_dir()
	if class_id == "gunner":
		class_active_t = 3.0 + float(tree_bonuses.get("bastion_time", 0.0))
		if bool(tree_bonuses.get("bastion_reload", false)): adrenaline_fired.emit()
		return true
	if class_id == "engineer":
		class_active_t = 8.0 + float(tree_bonuses.get("turret_time", 0.0))
		class_anchor = position + class_facing * 25.0
		if obstacles: class_anchor = obstacles.free_point(class_anchor, 5.0)
		hp = minf(max_hp, hp + float(tree_bonuses.get("turret_heal", 0.0)))
		_iframes = maxf(_iframes, float(tree_bonuses.get("turret_guard", 0.0)))
		if bool(tree_bonuses.get("turret_refill", false)): adrenaline_fired.emit()
		return true
	_tree_grenade_t = 2.0
	_gren_t = 0.0
	_gren_from = position
	_gren_to = grenade_target()
	return true


func ability_cooldown() -> float:
	return (8.0 if class_id == "assault" else (18.0 * float(tree_bonuses.get("bastion_cd_mul", 1.0)) if class_id == "gunner" else 16.0 * float(tree_bonuses.get("turret_cd_mul", 1.0)))) * float(tree_bonuses["grenade_cd_mul"])


func class_tick(delta: float) -> void:
	class_active_t = maxf(0.0, class_active_t - delta)
	_close_return_cd = maxf(0.0, _close_return_cd - delta)
	turret_mark_t = maxf(0.0, turret_mark_t - delta)
	if class_id == "gunner":
		var rate := -1.0 / (1.25 + float(tree_bonuses.get("brace_persist", 0.0))) if _moving else (1.0 + float(tree_bonuses.get("brace_gain", 0.0))) / 1.25
		stability = clampf(stability + delta * rate, 0.0, 1.0)
	queue_redraw()


func class_hit(at: Vector2) -> float:
	if class_id == "assault" and position.distance_to(at) <= 70.0 and _close_return_cd <= 0.0:
		dash_cd = maxf(0.0, dash_cd - 0.25 - float(tree_bonuses.get("assault_return", 0.0)))
		_close_return_cd = 1.0
	if class_id == "engineer" and turret_mark_t > 0.0 and at.distance_to(turret_mark) < 20.0 and (position - at).normalized().dot((class_anchor - at).normalized()) < -0.2:
		return 1.18 + float(tree_bonuses.get("crossfire", 0.0))
	return 1.0


## Куда полетит граната.
func grenade_dir() -> Vector2:
	if manual_aim:
		return aim_dir
	if _dash_t > 0.0:
		return _dash_dir
	if _moving or aim_dir == Vector2.ZERO:
		return facing
	return aim_dir


## Точка, куда упадёт граната, брошенная сейчас.
func grenade_target() -> Vector2:
	var at := (position + grenade_dir() * (GRENADE_DISTANCE + float(tree_bonuses["grenade_distance"]))).clamp(arena.position + Vector2.ONE * 8.0, arena.end - Vector2.ONE * 8.0)
	return obstacles.free_point(at, 3.0) if obstacles else at


func _update_grenade(delta: float) -> void:
	if _gren_t < 0.0:
		return
	_gren_t += delta
	if _gren_t >= GRENADE_TIME:
		_gren_t = -1.0
		grenade_landed.emit(_gren_to)
		if not is_dead:
			hp = minf(max_hp, hp + float(tree_bonuses["grenade_heal"]))
	queue_redraw()


## Граната в полёте: тень на полу, спрайт приподнят дугой и вращается, метка радиуса.
func _draw() -> void:
	if class_active_t > 0.0:
		if class_id == "gunner":
			var perpendicular := class_facing.orthogonal() * 14.0
			var front := class_facing * 12.0
			draw_line(front - perpendicular, front + perpendicular, Color("343b34"), 5.0)
			draw_line(front - perpendicular, front + perpendicular, Color("8c957f"), 3.0)
			draw_line(front - perpendicular * 0.65, front + perpendicular * 0.65, Color("40483f"), 1.0)
		elif class_id == "engineer":
			var at := to_local(class_anchor).round()
			for leg: Vector2 in [Vector2(-7, -6), Vector2(7, -6), Vector2(-7, 6), Vector2(7, 6)]:
				draw_line(at, at + leg, Color("252b28"), 3.0)
				draw_line(at, at + leg, Color("69745e"), 1.0)
			draw_rect(Rect2(at - Vector2(5, 5), Vector2(10, 10)), Color("252b28"))
			draw_rect(Rect2(at - Vector2(4, 4), Vector2(8, 8)), Color("747e67"))
			draw_rect(Rect2(at - Vector2(3, 3), Vector2(6, 2)), Color("939b81"))
			draw_rect(Rect2(at + Vector2(-3, 1), Vector2(6, 2)), Color("485345"))
			draw_line(at, at + class_facing * 11.0, Color("252b28"), 4.0)
			draw_line(at, at + class_facing * 10.0, Color("8a9585"), 2.0)
			draw_line(at + class_facing * 9.0, at + class_facing * 12.0, Color("414c46"), 2.0)
	if not is_dead:
		draw_texture_rect(PixelArt.dot(), Rect2(-7.0, -5.0, 14.0, 10.0), false, Color(0.025, 0.02, 0.018, 0.65))
	if _gren_t < 0.0:
		return
	var k := _gren_t / GRENADE_TIME
	var ground := to_local(_gren_from.lerp(_gren_to, k))
	var lift := sin(k * PI) * GRENADE_ARC
	draw_arc(to_local(_gren_to), GRENADE_RADIUS * float(tree_bonuses["grenade_radius_mul"]), 0.0, TAU, 32, Color(1.0, 0.45, 0.2, 0.18 + 0.2 * k), 1.0)
	PixelArt.draw_dot(self, ground, 2.6 - lift * 0.05, Color(0, 0, 0, 0.4))
	var sc := PixelArt.ART_SCALE * 2.0
	var air := ground + Vector2(0.0, -lift - 2.0)
	PixelArt.draw_dot(self, air, 4.0, Color(1.0, 0.55, 0.2, 0.25 + 0.25 * k)) # подсветка: на крови олива не видна
	draw_set_transform(air, k * TAU * 3.0, Vector2(sc, sc))
	draw_texture(_gren_tex, -_gren_tex.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO)
