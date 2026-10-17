class_name GameCamera
extends Camera2D
## Следит за игроком, умеет трястись.

var target: Node2D
var _shake := 0.0


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


func _process(delta: float) -> void:
	if target:
		global_position = target.global_position
	_shake = move_toward(_shake, 0.0, delta * 25.0)
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
