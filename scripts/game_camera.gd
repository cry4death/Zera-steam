class_name GameCamera
extends Camera2D
## Следит за игроком, умеет трястись.

var target: Node2D
var _shake := 0.0
var _kick := Vector2.ZERO
var shake_multiplier := 1.0
var view_shift := Vector2.ZERO # место слева для открытого авторского пульта


func setup(rect: Rect2, follow: Node2D) -> void:
	target = follow
	limit_left = int(rect.position.x)
	limit_top = int(rect.position.y)
	limit_right = int(rect.end.x)
	limit_bottom = int(rect.end.y)
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	global_position = follow.global_position
	reset_smoothing()


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## Толчок против выстрела; экспонента даёт устойчивый возврат при любом FPS.
func kick(dir: Vector2, amount: float) -> void:
	# Сила в пикселях экрана; одновременные стволы не складывают толчки.
	if amount >= _kick.length():
		_kick = -dir.normalized() * minf(amount, 3.5)


func _process(delta: float) -> void:
	if target:
		global_position = target.global_position + view_shift
	_shake = move_toward(_shake, 0.0, delta * 25.0)
	var tremor := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
	var impulse := _kick * float(Meta.settings["camera_recoil"]) + tremor.limit_length(4.0) * shake_multiplier
	offset = impulse.limit_length(4.0) / maxf(zoom.x, 0.001)
	# Первый кадр показывает весь удар; возврат применяется уже после вывода.
	_kick *= exp(-delta * 30.0)
