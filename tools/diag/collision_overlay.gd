extends Node2D
## Отладочный слой: зелёные контуры коллизии препятствий, красные клетки с малым зазором для зомби (радиус 5).

var ob


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if ob == null:
		return
	var view := get_viewport_rect()
	var inv := get_canvas_transform().affine_inverse()
	var tl: Vector2 = inv * view.position
	var br: Vector2 = inv * view.end
	for i in ob.count:
		if ob.state[i] == 4:
			continue
		var c: Vector2 = ob.pos[i]
		if c.x < tl.x - 200 or c.x > br.x + 200 or c.y < tl.y - 200 or c.y > br.y + 200:
			continue
		var h: Vector2 = ob.half[i]
		var a: float = ob.rotation_angle[i]
		if ob.round_shape[i] == 1:
			draw_arc(c, h.x, 0, TAU, 24, Color(0, 1, 0, 0.9), 1.5)
			continue
		var pts := PackedVector2Array()
		for s in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]:
			pts.append(c + (s * h).rotated(a))
		draw_polyline(pts, Color(0, 1, 0, 0.9), 1.5)
	var cell: float = ob.CELL
	var x0 := int((tl.x - ob.arena.position.x) / cell)
	var y0 := int((tl.y - ob.arena.position.y) / cell)
	var x1 := int((br.x - ob.arena.position.x) / cell)
	var y1 := int((br.y - ob.arena.position.y) / cell)
	for y in range(maxi(y0, 0), mini(y1 + 1, ob.grid_h)):
		for x in range(maxi(x0, 0), mini(x1 + 1, ob.grid_w)):
			var k: int = x + y * ob.grid_w
			if ob._clearance[k] < 5.0:
				draw_rect(Rect2(ob.arena.position + Vector2(x, y) * cell, Vector2(cell, cell)), Color(1, 0, 0, 0.28))
