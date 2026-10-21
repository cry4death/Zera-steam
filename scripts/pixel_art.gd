class_name PixelArt
## Доступ к спрайтам из art/ (их рисует tools/gen_art.py) и общие константы арта.
##
## Арт нарисован с тройной детализацией: 3 пикселя спрайта на 1 игровую единицу
## (персонаж — 48×48 px = 16 единиц). Всё рисуется с масштабом ART_SCALE,
## камера на 1080p показывает мир с zoom 3 — пиксель арта = пиксель экрана.

const ART_SCALE := 1.0 / 3.0
const ART_DENSITY := 3.0 # пикселей арта на игровую единицу
const CELL := Vector2(48, 48) # ячейка персонажа в листах
const VARIANT_COUNT := 21
const CLOTH_TONES := 3
const APPEARANCE_COUNT := VARIANT_COUNT * CLOTH_TONES
const ANIM_FRAMES := 4
const VARIANT_NAMES := ["гражданский", "учёный", "солдат", "строитель", "бегун", "толстяк", "плевун", "офисный", "медик", "полицейский", "механик", "капюшон", "пожилой", "спортсмен", "платье", "бездомный", "курьер", "бегун: атлет", "толстяк: фартук", "плевун: халат", "ползун"]
const SHAMBLERS := [0, 1, 2, 3, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
const KIND_VARIANTS := [SHAMBLERS, [4, 17], [5, 18], [6, 19]]
const CORPSE_POSES := 3
const MILITARY_CODE := 16384

## Биты ран на живом зомби (столбец атласа).
const WOUND_ARM_L := 1
const WOUND_ARM_R := 2
const WOUND_CHEST := 4
const WOUND_HEAD := 8


static var _dot: Texture2D


## Сигналы несут индекс внешности и масштаб; старые стенды 0..6 совместимы.
static func appearance(code: int) -> int:
	if code & MILITARY_CODE:
		return APPEARANCE_COUNT + ((code >> 15) & 3)
	return code & 63


static func base_variant(code: int) -> int:
	if code & MILITARY_CODE:
		return 9 if (appearance(code) - APPEARANCE_COUNT) == 1 else 2
	return appearance(code) % VARIANT_COUNT


static func variant_kind(code: int) -> int:
	var v := base_variant(code)
	return 1 if v in [4, 17] else 2 if v in [5, 18] else 3 if v in [6, 19] else 0


static func corpse_scale(code: int) -> Vector2:
	if code < 64:
		return Vector2.ONE
	var flags := (code >> 6) - 1
	var size := (1.0 + float((flags & 31) - 8) * 0.01) * (1.5 if flags & 64 else 1.0)
	return Vector2(size, -size if flags & 32 else size)


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


## Без окна (headless) окно 64×64, а логика (зум, кольцо и точки появления орды, «в кадре») должна видеть
## экран живой игры 1080p — иначе тесты и --sim считают иную геометрию (ZAI2, R2).
const HEADLESS_SCREEN := Vector2(1920, 1080)


static func screen_size(vp: Viewport) -> Vector2:
	return HEADLESS_SCREEN if DisplayServer.get_name() == "headless" else vp.get_visible_rect().size


## Видимая часть мира в локальных координатах узла (с запасом): всё, что вне её, не рисуем (P1).
## В headless — виртуальный экран 1080p с тем же центром, что у камеры.
static func view_rect(ci: CanvasItem, margin := 16.0) -> Rect2:
	var real := ci.get_viewport().get_visible_rect().size
	var size := screen_size(ci.get_viewport())
	var screen := Rect2((real - size) * 0.5, size)
	return (ci.get_global_transform_with_canvas().affine_inverse() * screen).grow(margin)


static func tex(name: String) -> Texture2D:
	return load("res://art/%s.png" % name)


## Кадр из листа: cols × rows ячеек одинакового размера.
static func frame(sheet: Texture2D, col: int, row: int, cell := CELL) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2(Vector2(col, row) * cell, cell)
	return at
