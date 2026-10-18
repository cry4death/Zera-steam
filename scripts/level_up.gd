extends Control
## Экран Level Up: 3 карты на выбор (клавиши 1–3 или мышь), Q — реролл.
## Модуль и патроны требуют второго шага — выбрать ствол (1–4), Esc — назад.
## Работает на паузе (process_mode = ALWAYS), рисуется в «игровых» пикселях, как HUD.

signal chosen(card: Dictionary, slot: int)
signal reroll_requested

const CARD_W := 150.0
const CARD_H := 184.0
const GAP := 12.0
const FONT := 10

var progression: Progression
var sfx: Sfx
var weapons: Weapons
var cards: Array = []
var _card: Dictionary = {} # выбранная карта на шаге выбора ствола
var _ui := 3.0
var _rects: Array[Rect2] = []
var _hover := -1 # карта под мышью или выбранная стрелками: для неё видны подробности
var _t := 0.0
var _title := "" # режим награды (контейнер, деталь): свой заголовок вместо «УРОВЕНЬ N»
var _subtitle := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	Progression.preload_icons()


## title != "" — режим награды: свой заголовок, реролла нет (выбор не из Level Up).
func open(new_cards: Array, title := "", subtitle := "") -> void:
	cards = new_cards
	_title = title
	_subtitle = subtitle
	_card = {}
	_t = 0.0
	visible = true
	queue_redraw()


func close() -> void:
	visible = false


func _process(delta: float) -> void:
	if visible:
		_t += delta
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	var mm := event as InputEventMouseMotion
	if mm:
		_hover = _rect_at(mm.position / _ui)
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _t > 0.25:
		var i := _rect_at(mb.position / _ui)
		if i != -1:
			_pick(i)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or _t < 0.25:
		return
	match key.keycode:
		KEY_1, KEY_KP_1:
			_pick(0)
		KEY_2, KEY_KP_2:
			_pick(1)
		KEY_3, KEY_KP_3:
			_pick(2)
		KEY_4, KEY_KP_4:
			_pick(3)
		KEY_LEFT, KEY_A:
			_focus(-1)
		KEY_RIGHT, KEY_D:
			_focus(1)
		KEY_Q:
			if _card.is_empty() and progression.rerolls > 0 and _title == "":
				_sound("confirm")
				reroll_requested.emit()
			else:
				_sound("deny")
		KEY_ESCAPE:
			_sound("click")
			_card = {}
	get_viewport().set_input_as_handled()


## Стрелки двигают выделение карты (подробности ранга), выбор остаётся на клавишах 1–4 и мыши.
func _focus(step: int) -> void:
	if not _card.is_empty() or cards.is_empty():
		return
	_hover = 0 if _hover < 0 else clampi(_hover + step, 0, cards.size() - 1)


func _rect_at(p: Vector2) -> int:
	for i in _rects.size():
		if _rects[i].has_point(p):
			return i
	return -1


func _pick(i: int) -> void:
	if _card.is_empty():
		if i >= cards.size():
			_sound("deny")
			return
		var card: Dictionary = cards[i]
		if Progression.needs_slot(card):
			_sound("click")
			_card = card
			_hover = -1
		else:
			_sound("confirm")
			chosen.emit(card, -1)
	else:
		if i >= weapons.slots.size() or progression.slot_status(_card, i) == "":
			_sound("deny")
			return
		_sound("confirm")
		chosen.emit(_card, i)


func _sound(id: String) -> void:
	if sfx != null:
		sfx.play("ui/" + id)


func _draw() -> void:
	if not visible:
		return
	_ui = maxf(1.0, roundf(size.y / 360.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))
	var w := size.x / _ui
	var h := size.y / _ui
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, w, h), Color(0.03, 0.0, 0.0, 0.72))
	_rects.clear()
	if _card.is_empty():
		_draw_cards(font, w, h)
	else:
		_draw_slots(font, w, h)


func _draw_cards(font: Font, w: float, h: float) -> void:
	if _title == "":
		_text_c(font, Vector2(w * 0.5, 60), "УРОВЕНЬ %d" % (progression.level - progression.pending + 1), Color(0.95, 0.85, 0.5), 18)
		_text_c(font, Vector2(w * 0.5, 76), "выбери улучшение", Color(0.7, 0.7, 0.66))
	else:
		_text_c(font, Vector2(w * 0.5, 60), _title, Color(0.9, 0.2, 0.15), 18)
		_text_c(font, Vector2(w * 0.5, 76), _subtitle, Color(0.7, 0.7, 0.66))
	var total := cards.size() * CARD_W + (cards.size() - 1) * GAP
	var x0 := (w - total) * 0.5
	var y0 := h * 0.5 - CARD_H * 0.5 + 6.0
	var pop := clampf(_t * 8.0, 0.0, 1.0) # короткое общее появление, без выезда по очереди
	for i in cards.size():
		var d := progression.describe(cards[i])
		var r := Rect2(x0 + i * (CARD_W + GAP), y0 + (1.0 - pop) * 8.0, CARD_W, CARD_H)
		_rects.append(r)
		var col: Color = d["color"]
		var hover := _hover == i
		draw_rect(r, Color(0.07, 0.065, 0.065, 0.96 * pop))
		draw_rect(r, Color(col if hover else Color(0.6, 0.6, 0.58), (0.9 if hover else 0.25) * pop), false, 1.0)
		_text(font, r.position + Vector2(8, 16), d["kind"], Color(col, 0.8 * pop), 8)
		_text(font, r.position + Vector2(CARD_W - 14, 16), str(i + 1), Color(1, 1, 1, 0.5 * pop), 10)
		# пиктограмма на тёмной плите
		var plate := Rect2(r.position + Vector2(8, 24), Vector2(CARD_W - 16, 44))
		draw_rect(plate, Color(0.03, 0.03, 0.03, 0.9 * pop))
		_draw_icon(d, plate, pop)
		var y := 84.0
		for part in _wrap(font, str(d["title"]), CARD_W - 16.0, 11):
			_text(font, r.position + Vector2(8, y), part, Color(col, pop), 11)
			y += 13.0
		y += 1.0
		if d["sub"] != "":
			for part in _wrap(font, str(d["sub"]), CARD_W - 16.0, 8):
				_text(font, r.position + Vector2(8, y), part, Color(0.62, 0.62, 0.58, pop), 8)
				y += 9.5
			y += 2.0
		for line: String in d["front"]:
			for part in _wrap(font, line, CARD_W - 16.0, 9):
				_text(font, r.position + Vector2(8, y), part, Color(0.9, 0.88, 0.82, pop), 9)
				y += 11.0
		# подробности: по наведению или выбору стрелками
		var more: Array = d["more"]
		if not more.is_empty():
			var dy := maxf(CARD_H - 40.0, y + 10.0)
			draw_rect(Rect2(r.position + Vector2(8, dy - 8), Vector2(CARD_W - 16, 1)), Color(1, 1, 1, 0.12 * pop))
			if hover:
				for line: String in more:
					for part in _wrap(font, line, CARD_W - 16.0, 8):
						_text(font, r.position + Vector2(8, dy + 2), part, Color(0.72, 0.74, 0.78, pop), 8)
						dy += 9.5
			else:
				_text(font, r.position + Vector2(8, dy + 2), "подробнее: наведи / ← →", Color(0.5, 0.5, 0.47, pop), 7)
	var hint := "1–%d / клик — выбрать" % cards.size()
	if progression.rerolls > 0 and _title == "":
		hint += " · Q — реролл (%d)" % progression.rerolls
	_text_c(font, Vector2(w * 0.5, y0 + CARD_H + 22.0), hint, Color(0.6, 0.6, 0.56), 9)


## Пиктограмма карты по центру плиты: спрайт ствола вписывается, иконка детали — крупнее в 4/3.
func _draw_icon(d: Dictionary, plate: Rect2, alpha: float) -> void:
	var icon_name: String = d["icon"]
	if icon_name == "":
		return
	var tex := Progression.card_icon(icon_name)
	if tex == null:
		return
	var k := 4.0 / 3.0
	if d.get("icon_gun", false):
		k = 1.0
		while k > 0.34 and (tex.get_width() * k > plate.size.x - 8.0 or tex.get_height() * k > plate.size.y - 4.0):
			k -= 1.0 / 3.0
	var sz := tex.get_size() * k
	var pos := ((plate.get_center() - sz * 0.5) * _ui).round() / _ui
	draw_texture_rect(tex, Rect2(pos, sz), false, Color(1, 1, 1, alpha))


func _draw_slots(font: Font, w: float, h: float) -> void:
	var d := progression.describe(_card)
	_text_c(font, Vector2(w * 0.5, 70), "КУДА ПОСТАВИТЬ: %s" % d["title"], d["color"], 14)
	var row_w := 300.0
	var row_h := 30.0
	var x0 := (w - row_w) * 0.5
	var y0 := 96.0
	for i in weapons.slots.size():
		var s: Weapons.Slot = weapons.slots[i]
		var status := progression.slot_status(_card, i)
		var ok := status != ""
		var r := Rect2(x0, y0 + i * (row_h + 6.0), row_w, row_h)
		_rects.append(r)
		var col := Color(0.92, 0.9, 0.85) if ok else Color(0.45, 0.45, 0.43)
		draw_rect(r, Color(0.08, 0.07, 0.07, 0.95))
		draw_rect(r, Color(col, 0.9 if (_hover == i and ok) else 0.4), false, 1.0)
		_text(font, r.position + Vector2(8, 13), "%d. %s ур.%d" % [i + 1, s.short_name(), s.level], col, 11)
		_text(font, r.position + Vector2(8, 25), slot_summary(s), Color(col, 0.7), 8)
		var right := status if ok else "нет места"
		var tw := font.get_string_size(right, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		_text(font, r.position + Vector2(row_w - 8 - tw, 13), right, Color(0.6, 0.9, 0.6) if ok else Color(0.7, 0.4, 0.4), 10)
		var proto := progression.prototype_hint(_card, i)
		if proto != "" and ok:
			var pw := font.get_string_size(proto, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			_text(font, r.position + Vector2(row_w - 8 - pw, 25), proto, Color(1.0, 0.55, 0.3), 8)
	_text_c(font, Vector2(w * 0.5, y0 + weapons.slots.size() * (row_h + 6.0) + 16.0), "1–4 / клик — выбрать ствол · Esc — назад", Color(0.6, 0.6, 0.56), 9)


## Короткая сводка ствола: патроны и модули.
static func slot_summary(s: Weapons.Slot) -> String:
	var parts: Array[String] = ["%s %s" % [WeaponDefs.AMMO[s.ammo]["name"], WeaponDefs.ROMAN[s.ammo_rank]]]
	for m in s.modules:
		parts.append("%s %s" % [WeaponDefs.MODULES[m["id"]]["name"], WeaponDefs.ROMAN[m["rank"]]])
	parts.append("слоты %d/%d" % [s.modules.size(), WeaponDefs.module_slots(s.level)])
	return " · ".join(parts)


func _wrap(font: Font, s: String, max_w: float, fs: int) -> Array[String]:
	var out: Array[String] = []
	var line := ""
	for word in s.split(" "):
		var test := word if line == "" else line + " " + word
		if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w and line != "":
			out.append(line)
			line = word
		else:
			line = test
	if line != "":
		out.append(line)
	return out


func _text(font: Font, p: Vector2, s: String, c: Color, fs := FONT) -> void:
	var k := int(_ui)
	draw_set_transform(Vector2.ZERO)
	draw_string_outline(font, p * _ui, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * k, 2 * k, Color(0, 0, 0, 0.8 * c.a))
	draw_string(font, p * _ui, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * k, c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))


func _text_c(font: Font, p: Vector2, s: String, c: Color, fs := FONT) -> void:
	var tw := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_text(font, Vector2(p.x - tw * 0.5, p.y), s, c, fs)
