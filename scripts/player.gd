class_name Player
extends Node2D
## Штурмовик: движение, рывок с неуязвимостью, урон и смерть.
## Статы — BALANCE.md §1.

signal hurt(amount: float)
signal died
signal dashed

const RADIUS := 5.0

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
var autopilot := false # для бенчмарка: бегает по кругу сам
var auto_target := Vector2.INF # симуляция: бежать к образцам
var effects: Effects

var facing := Vector2.RIGHT
var aim_dir := Vector2.ZERO # куда смотрит ствол; задаёт оружие при выстреле
var dash_cd := 0.0
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

const DIRT_STAGES := [0.0, 15.0, 50.0, 120.0]

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	hp = max_hp
	var sheet := PixelArt.tex("player")
	for d in DIRT_STAGES.size():
		for a in PixelArt.ANIM_FRAMES:
			_frames.append(PixelArt.frame(sheet, a, d))
	sprite.texture = _frames[0]
	sprite.scale = Vector2(PixelArt.ART_SCALE, PixelArt.ART_SCALE)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	dash_cd = maxf(dash_cd - delta, 0.0)
	_iframes = maxf(_iframes - delta, 0.0)
	_hurt_t = maxf(_hurt_t - delta, 0.0)

	var input := _read_input(delta)
	if input != Vector2.ZERO:
		facing = input.normalized()

	if Input.is_action_just_pressed("dash") and dash_cd <= 0.0:
		_dash_dir = facing
		_dash_t = dash_time
		dash_cd = dash_cooldown
		_iframes = maxf(_iframes, dash_iframes)
		dashed.emit()

	var before := position
	if _dash_t > 0.0:
		_dash_t -= delta
		position += _dash_dir * (dash_distance / dash_time) * delta
		if effects:
			effects.ghost(position, sprite.rotation, sprite.texture)
	else:
		position += input * move_speed * delta
	_walk += position.distance_to(before)
	_kick = maxf(_kick - delta * 12.0, 0.0)
	position = position.clamp(arena.position + Vector2.ONE * 8.0, arena.end - Vector2.ONE * 8.0)

	var look := aim_dir if aim_dir != Vector2.ZERO else facing
	sprite.rotation = look.angle()
	sprite.position = -look * _kick * 1.2 # отдача
	sprite.texture = _frames[_dirt_stage * PixelArt.ANIM_FRAMES + int(_walk / 5.0) % PixelArt.ANIM_FRAMES]
	# мигание после удара + красная вспышка
	sprite.visible = _hurt_t <= 0.0 or int(_hurt_t * 20.0) % 2 == 0
	sprite.modulate = Color(1.0, 0.4, 0.4) if _hurt_t > hit_iframes - 0.1 else Color.WHITE


func _read_input(delta: float) -> Vector2:
	if autopilot:
		_auto_t += delta
		if auto_target != Vector2.INF and position.distance_to(auto_target) > 2.0:
			return (auto_target - position).normalized()
		return Vector2.from_angle(_auto_t * 0.5).orthogonal()
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func take_damage(amount: float) -> void:
	if is_dead or god_mode or _iframes > 0.0:
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
func kick() -> void:
	_kick = 1.0


func is_dashing() -> bool:
	return _dash_t > 0.0
