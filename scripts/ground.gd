extends Node2D
## Земля собирается один раз из ASCII-слоя. В кадре четыре текстуры вместо 3600 тайлов.

const SYMBOLS := "=-.,:~*#"
const CHUNK := Vector2i(40, 23)
var arena := Rect2()


func setup(rect: Rect2, data: Dictionary = {}) -> void:
	arena = rect
	for child in get_children():
		child.queue_free()
	if data.is_empty():
		var floor_sprite := Sprite2D.new()
		floor_sprite.texture = PixelArt.tex("asphalt")
		floor_sprite.centered = false
		floor_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		floor_sprite.region_enabled = true
		floor_sprite.region_rect = Rect2(Vector2.ZERO, rect.size * PixelArt.ART_DENSITY)
		floor_sprite.scale = Vector2.ONE * PixelArt.ART_SCALE
		add_child(floor_sprite)
		return
	# Песчаная карта не требует мелкого зерна: её фон занимает вчетверо меньше VRAM.
	var density := 1 if data.has("road_path") else 2
	var tile := int(MapLoader.CELL) * density
	var tiles := PixelArt.tex("map_ground").get_image()
	var road := PixelArt.tex("map_road").get_image()
	var decals := PixelArt.tex("map_decals").get_image()
	var edges := PixelArt.tex("map_edges").get_image()
	if density == 1:
		tiles.resize(tile * 16, tile * 8, Image.INTERPOLATE_NEAREST)
		road.resize(tile * 16, tile * 16, Image.INTERPOLATE_NEAREST)
		edges.resize(tile * 4, tile * 5, Image.INTERPOLATE_NEAREST)
		decals.resize(tile * 8, tile * 2, Image.INTERPOLATE_NEAREST)
	var rows: Array = data["ground"]
	var overlay: Image
	if data.has("road_path"):
		overlay = PixelArt.tex("map_road_overlay_" + str(data["id"])).get_image()
		overlay.resize(String(rows[0]).length() * tile, rows.size() * tile, Image.INTERPOLATE_NEAREST)
	var width := String(rows[0]).length()
	for cy in range(0, rows.size(), CHUNK.y):
		for cx in range(0, width, CHUNK.x):
			var size := Vector2i(mini(CHUNK.x, width - cx), mini(CHUNK.y, rows.size() - cy))
			var image := Image.create_empty(size.x * tile, size.y * tile, false, Image.FORMAT_RGBA8)
			for y in size.y:
				for x in size.x:
					var gx := cx + x
					var gy := cy + y
					var symbol := String(rows[gy]).substr(gx, 1)
					var material := SYMBOLS.find(symbol)
					if overlay != null and symbol in "=-":
						symbol = "~"
						material = 5
					var variant := (gx * 13 + gy * 7 + gx * gy) % 16
					var at := Vector2i(x, y) * tile
					if symbol in "=-":
						image.blit_rect(road, Rect2i((gx * tile) % (tile * 16), (gy * tile) % (tile * 16), tile, tile), at)
						if symbol == "-":
							image.blend_rect(tiles, Rect2i(variant * tile, material * tile, tile, tile), at)
					else:
						image.blit_rect(tiles, Rect2i(variant * tile, material * tile, tile, tile), at)
					for side in 4:
						var adjacent: Vector2i = Vector2i(gx, gy) + [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN][side]
						if adjacent.x < 0 or adjacent.y < 0 or adjacent.x >= width or adjacent.y >= rows.size():
							continue
						var other := String(rows[adjacent.y]).substr(adjacent.x, 1)
						if overlay != null and other in "=-":
							other = "~"
						if symbol == other or (symbol in "=-" and other in "=-"):
							continue
						if symbol in ".,:~*":
							var edge_type := 0 if symbol == "." else 1 + ",:~*".find(symbol)
							image.blend_rect(edges, Rect2i(side * tile, edge_type * tile, tile, tile), at)
			var chunk_origin := Vector2i(cx, cy) * tile
			if overlay != null:
				image.blend_rect(overlay, Rect2i(chunk_origin, image.get_size()), Vector2i.ZERO)
			for mark: Array in data.get("markings", []):
				var marking := Rect2i(int(float(mark[0]) * density), int(float(mark[1]) * density), int(float(mark[2]) * density), int(float(mark[3]) * density))
				marking.position -= chunk_origin
				marking = marking.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
				if marking.has_area():
					image.fill_rect(marking, Color(0.48, 0.46, 0.36, 1))
			for decal: Array in data.get("decals", []):
				var at := Vector2i(int(float(decal[0]) * density), int(float(decal[1]) * density)) - chunk_origin - Vector2i(tile, tile)
				image.blend_rect(decals, Rect2i(int(decal[2]) * tile * 2, 0, tile * 2, tile * 2), at)
			var sprite := Sprite2D.new()
			sprite.texture = ImageTexture.create_from_image(image)
			sprite.centered = false
			sprite.scale = Vector2.ONE / float(density)
			sprite.position = Vector2(cx, cy) * MapLoader.CELL
			add_child(sprite)
	queue_redraw()


func _draw() -> void:
	if arena.size != Vector2.ZERO:
		draw_rect(arena.grow(-2.0), Color(0.22, 0.22, 0.19), false, 4.0)
