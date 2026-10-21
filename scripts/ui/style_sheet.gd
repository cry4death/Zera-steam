extends Control
## Лист стиля рисуется теми же шрифтами, материалами и состояниями, что база.
const Style := preload("res://scripts/ui/zera_style.gd")

func text_at(at: Vector2, value: String, font: Font, pixels: int, color: Color) -> void:
	var ui := size.y / 360.0
	draw_set_transform(Vector2.ZERO)
	draw_string(font, at * ui, value, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(pixels * ui), color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * ui)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * (size.y / 360.0))
	draw_texture_rect(load("res://art/ui_steel.png"), Rect2(0, 0, 640, 360), true)
	text_at(Vector2(20, 36), "Z.E.R.A. / ОРУЖЕЙНЫЙ ПОСТ", Style.TITLE_FONT, Style.SUBTITLE, Style.TEXT)
	text_at(Vector2(20, 73), "АРСЕНАЛ", Style.TITLE_FONT, Style.TITLE, Style.TEXT)
	text_at(Vector2(20, 94), "Карантинная служба · вооружение и снабжение", Style.BODY_FONT, Style.BODY, Style.MUTED)
	text_at(Vector2(20, 133), "ТИПОГРАФИКА", Style.TITLE_FONT, Style.SUBTITLE, Style.SELECTED)
	text_at(Vector2(20, 161), "Автомат АК-С", Style.TITLE_FONT, Style.SUBTITLE, Style.TEXT)
	text_at(Vector2(20, 182), "Держит толпу на дистанции", Style.BODY_FONT, Style.BODY, Style.TEXT)
	text_at(Vector2(20, 212), "30 / 360 / 1,50", Style.BODY_FONT, Style.NUMBER, Style.TEXT)
	text_at(Vector2(20, 230), "УРОН · ТЕМП · МАГАЗИН", Style.BODY_FONT, Style.SMALL, Style.MUTED)
	var colors := [Style.METAL, Style.RECESS, Style.CANVAS, Style.HOVER, Style.TEXT, Style.MUTED, Style.SELECTED, Style.ACTION, Style.DANGER, Style.BETTER, Style.RARE]
	var names := ["СТАЛЬ", "ПАЗ", "БРЕЗЕНТ", "ФОКУС", "ТЕКСТ", "ПОДПИСЬ", "ВЫБОР", "ДЕЙСТВИЕ", "УГРОЗА", "ЛУЧШЕ", "РЕДКАЯ"]
	for i in colors.size():
		var x := 20.0 + i * 55.0
		Style.cut_rect(self, Rect2(x, 270, 47, 32), colors[i])
		text_at(Vector2(x, 316), names[i], Style.BODY_FONT, 7, Style.MUTED)
	var states := ["ОБЫЧНАЯ", "НАВЕДЕНИЕ", "ВЫБРАНА", "НЕДОСТУПНО", "ЗАКРЫТА"]
	for i in states.size():
		var rect := Rect2(338, 116 + i * 25, 270, 21)
		Style.surface(self, rect, i)
		text_at(rect.position + Vector2(10, 14), states[i], Style.BODY_FONT, Style.SMALL, Style.DISABLED if i == 3 else Style.TEXT)
		if i == 4: Style.lock_icon(self, rect.end - Vector2(12, 12), Style.MUTED)
	text_at(Vector2(20, 346), "RUSSO ONE + FIRA SANS CONDENSED   /   640 × 360 → 1920 × 1080 / 1280 × 720", Style.BODY_FONT, Style.SMALL, Style.MUTED)
