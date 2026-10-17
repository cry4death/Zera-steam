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
var dirt := 0.0 # насколько боец перемазан кровью

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
	sheet = ImageTexture.create_from_image(image)
	for d in DIRT_STAGES.size():
		for a in PixelArt.ANIM_FRAMES:
			_frames.append(PixelArt.frame(sheet, a, d))
	sprite.texture = _frames[0]
	sprite.scale = Vector2(PixelArt.ART_SCALE, PixelArt.ART_SCALE)
	_gren_tex = PixelArt.tex("grenade")


func _physics_process(delta: float) -> void:
	_update_grenade(delta)
	if is_dead:
		return
	_recharge_dash(delta)
	adrenaline_cd = maxf(adrenaline_cd - delta, 0.0)
	grenade_cd = maxf(grenade_cd - delta, 0.0)
	_iframes = maxf(_iframes - delta, 0.0)
	_hurt_t = maxf(_hurt_t - delta, 0.0)

	var input := _read_input(delta)
	_moving = input != Vector2.ZERO
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
		position += input * move_speed * delta
	_walk += position.distance_to(before)
	_kick *= exp(-delta * 28.0)
	position = position.clamp(arena.position + Vector2.ONE * 8.0, arena.end - Vector2.ONE * 8.0)
	if manual_aim:
		_update_aim() # после движения курсор остаётся в той же мировой точке

	var look := aim_dir if aim_dir != Vector2.ZERO else facing
	sprite.rotation = look.angle()
	sprite.position = -look * _kick * 1.2 # отдача
	sprite.texture = _frames[_dirt_stage * PixelArt.ANIM_FRAMES + int(_walk / 5.0) % PixelArt.ANIM_FRAMES]
	# мигание после удара + красная вспышка
	sprite.visible = _hurt_t <= 0.0 or int(_hurt_t * 20.0) % 2 == 0
	sprite.modulate = Color(1.0, 0.4, 0.4) if _hurt_t > hit_iframes - 0.1 else Color.WHITE


## Дерево класса на этот забег (Meta.run_bonuses): +HP, заряды рывка, «Адреналин».
func apply_bonuses(bonuses: Dictionary) -> void:
	max_hp = 100.0 + float(bonuses["hp_add"])
	hp = max_hp
	dash_max = int(bonuses["dash_charges"])
	dash_left = dash_max
	dash_cd = 0.0
	adrenaline = bool(bonuses["adrenaline"])
	adrenaline_cd = 0.0


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


func take_damage(amount: float) -> void:
	if is_dead or _iframes > 0.0:
		return
	damage_taken += amount
	if god_mode:
		return
	hp -= amount
	_iframes = hit_iframes
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
	grenade_cd = GRENADE_COOLDOWN
	_gren_t = 0.0
	_gren_from = position
	_gren_to = grenade_target()
	return true


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
	return (position + grenade_dir() * GRENADE_DISTANCE).clamp(arena.position + Vector2.ONE * 8.0, arena.end - Vector2.ONE * 8.0)


func _update_grenade(delta: float) -> void:
	if _gren_t < 0.0:
		return
	_gren_t += delta
	if _gren_t >= GRENADE_TIME:
		_gren_t = -1.0
		grenade_landed.emit(_gren_to)
	queue_redraw()


## Граната в полёте: тень на полу, спрайт приподнят дугой и вращается, метка радиуса.
func _draw() -> void:
	if _gren_t < 0.0:
		return
	var k := _gren_t / GRENADE_TIME
	var ground := to_local(_gren_from.lerp(_gren_to, k))
	var lift := sin(k * PI) * GRENADE_ARC
	draw_arc(to_local(_gren_to), GRENADE_RADIUS, 0.0, TAU, 32, Color(1.0, 0.45, 0.2, 0.18 + 0.2 * k), 1.0)
	PixelArt.draw_dot(self, ground, 2.6 - lift * 0.05, Color(0, 0, 0, 0.4))
	var sc := PixelArt.ART_SCALE * 2.0
	var air := ground + Vector2(0.0, -lift - 2.0)
	PixelArt.draw_dot(self, air, 4.0, Color(1.0, 0.55, 0.2, 0.25 + 0.25 * k)) # подсветка: на крови олива не видна
	draw_set_transform(air, k * TAU * 3.0, Vector2(sc, sc))
	draw_texture(_gren_tex, -_gren_tex.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO)
