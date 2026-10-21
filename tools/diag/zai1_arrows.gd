extends Node2D
## ZAI1 (временный): у каждого зомби в кадре — штрих скорости за 0,1 с (×4) и точка взгляда.
## Голубой — идёт прямо к игроку, жёлтый — по полю путей, белый — ближе 90 px, красный — счётчик застревания.

var horde
var _prev := {}
var _vel := {}
var _acc := 0.0


func _process(delta: float) -> void:
	_acc += delta
	if _acc >= 0.1:
		_acc = 0.0
		var cur := {}
		for i in horde.count:
			if horde.dead[i] == 1:
				continue
			var u: int = horde.uid[i]
			cur[u] = horde.pos[i]
			if _prev.has(u):
				_vel[u] = horde.pos[i] - _prev[u]
		_prev = cur
	queue_redraw()


func _draw() -> void:
	if horde == null or horde.player == null:
		return
	var view: Rect2 = PixelArt.view_rect(self, 8.0)
	var pp: Vector2 = horde.player.global_position
	for i in horde.count:
		if horde.dead[i] == 1:
			continue
		var p: Vector2 = horde.pos[i]
		if not view.has_point(p):
			continue
		var c := Color(1, 1, 1, 0.9)
		if horde._stuck_time[i] > 0.0:
			c = Color(1, 0.15, 0.15)
		elif p.distance_to(pp) > 90.0:
			c = Color(0.3, 0.9, 1.0) if horde.steer[i] == Vector2.ZERO else Color(1.0, 0.85, 0.1)
		var v: Vector2 = _vel.get(horde.uid[i], Vector2.ZERO)
		draw_line(p, p + v * 4.0, c, 1.0)
		draw_rect(Rect2(p + Vector2.from_angle(horde.angle[i]) * 4.0 - Vector2.ONE * 0.75, Vector2.ONE * 1.5), Color(1, 0, 1))
