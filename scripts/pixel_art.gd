class_name PixelArt
## Доступ к спрайтам из art/ (их рисует tools/gen_art.py) и общие константы арта.
##
## Арт нарисован с тройной детализацией: 3 пикселя спрайта на 1 игровую единицу
## (персонаж — 48×48 px = 16 единиц). Всё рисуется с масштабом ART_SCALE,
## камера на 1080p показывает мир с zoom 3 — пиксель арта = пиксель экрана.

const ART_SCALE := 1.0 / 3.0
const ART_DENSITY := 3.0 # пикселей арта на игровую единицу
const CELL := Vector2(48, 48) # ячейка персонажа в листах
const VARIANT_COUNT := 4
const ANIM_FRAMES := 4
const VARIANT_NAMES := ["гражданский", "учёный", "солдат", "рабочий"]
const CORPSE_POSES := 3

## Биты ран на живом зомби (столбец атласа).
const WOUND_ARM_L := 1
const WOUND_ARM_R := 2
const WOUND_CHEST := 4
const WOUND_HEAD := 8


static var _dot: Texture2D


## Круглая маска для капель и брызг. draw_circle в Godot 4.7 каждый раз
## триангулирует многоугольник на CPU — сотни кругов за кадр стоят десятки мс,
## поэтому капли рисуются этой текстурой через draw_texture_rect.
static func dot() -> Texture2D:
	if _dot == null:
		var img := Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
		for y in 8:
			for x in 8:
				var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(4, 4))
				if d <= 3.9:
					img.set_pixel(x, y, Color(1, 1, 1, 1.0 if d < 3.2 else 0.6))
		_dot = ImageTexture.create_from_image(img)
	return _dot


## Капля радиуса r с центром p на любом CanvasItem.
static func draw_dot(ci: CanvasItem, p: Vector2, r: float, color: Color) -> void:
	ci.draw_texture_rect(dot(), Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false, color)


static func tex(name: String) -> Texture2D:
	return load("res://art/%s.png" % name)


## Кадр из листа: cols × rows ячеек одинакового размера.
static func frame(sheet: Texture2D, col: int, row: int, cell := CELL) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2(Vector2(col, row) * cell, cell)
	return at
