extends Node2D
## Пол арены: тайл асфальта + разметка и бетонная граница.

var arena := Rect2()


func setup(rect: Rect2) -> void:
	arena = rect
	var floor_sprite := Sprite2D.new()
	floor_sprite.texture = PixelArt.tex("asphalt")
	floor_sprite.centered = false
	floor_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor_sprite.region_enabled = true
	floor_sprite.region_rect = Rect2(Vector2.ZERO, rect.size * PixelArt.ART_DENSITY)
	floor_sprite.position = rect.position
	floor_sprite.scale = Vector2(PixelArt.ART_SCALE, PixelArt.ART_SCALE)
	floor_sprite.show_behind_parent = true
	add_child(floor_sprite)
	queue_redraw()


func _draw() -> void:
	if arena.size == Vector2.ZERO:
		return
	var paint := Color(0.75, 0.62, 0.2, 0.55)
	# пунктирная разметка: две дороги крест-накрест
	var cy := arena.get_center().y
	var cx := arena.get_center().x
	var x := arena.position.x
	while x < arena.end.x:
		draw_rect(Rect2(x, cy - 1.0, 24.0, 2.0), paint)
		x += 48.0
	var y := arena.position.y
	while y < arena.end.y:
		draw_rect(Rect2(cx - 1.0, y, 2.0, 24.0), paint)
		y += 48.0
	# бетонная стена по краю
	draw_rect(arena.grow(-4.0), Color(0.42, 0.42, 0.4), false, 8.0)
