extends Control
## Экран Level Up: 3 карты на выбор (клавиши 1–3 или мышь), Q — реролл.
## Модуль и патроны требуют второго шага — выбрать ствол (1–4), Esc — назад.
## Работает на паузе (process_mode = ALWAYS), рисуется в «игровых» пикселях, как HUD.

signal chosen(card: Dictionary, slot: int)
signal reroll_requested

const Style := preload("res://scripts/ui/zera_style.gd")
const CARD_W := 180.0
const CARD_H := 224.0
const GAP := 12.0
const FONT := 10

var progression: Progression
var sfx: Sfx
var weapons: Weapons
var cards: Array = []
var _card: Dictionary = {} # выбранная карта на шаге выбора ствола
var _offset := Vector2.ZERO
var _layout: SettingsLayout.Scroll
var _reveal := true
var _ui := 3.0
var _rects: Array[Rect2] = []
var _hover := -1 # карта под мышью или выбранная стрелками: для неё видны подробности
var _t := 0.0
var _pad := ChoiceInput.new()
var _title := "" # режим награды (контейнер, деталь): свой заголовок вместо «УРОВЕНЬ N»
var _subtitle := ""


func _ready() -> void:
	_layout = SettingsLayout.Scroll.new(self)
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
	_hover = 0
	_reveal = true
	_layout.horizontal.value = 0
	_layout.vertical.value = 0
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
	if _layout.pointer(event):
		accept_event()
		return
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_pad.read(event)
	var mm := event as InputEventMouseMotion
	if mm:
		_hover = _rect_at((mm.position - _offset) / _ui)
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _t > 0.25:
		var i := _rect_at((mb.position - _offset) / _ui)
		if i != -1:
			_pick(i)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var command := _pad.read(event)
	if _t >= 0.25 and command != "":
		match command:
			"left", "up": _focus(-1)
			"right", "down": _focus(1)
			"accept": _pick(maxi(_hover, 0))
			"cancel":
				_card = {}
				_hover = 0
			"reroll":
				if _card.is_empty() and progression.rerolls > 0 and _title == "":
					reroll_requested.emit()
		get_viewport().set_input_as_handled()
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
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_pick(maxi(_hover, 0))
		KEY_Q:
			if _card.is_empty() and progression.rerolls > 0 and _title == "":
				_sound("confirm")
				reroll_requested.emit()
			else:
				_sound("deny")
		KEY_ESCAPE:
			_sound("click")
			_card = {}
		KEY_F:
			progression.focus_overflow = not progression.focus_overflow
		KEY_B:
			for s in weapons.slots:
				var m := s.module(WeaponDefs.Module.LINK)
				if not m.is_empty() and not m["active"]:
					_card = {"type": "link", "id": WeaponDefs.Module.LINK, "rebind": m["instance_id"]}
					_hover = 0
					break
	get_viewport().set_input_as_handled()


## Навигация пропускает недоступные стволы.
func _focus(step: int) -> void:
	var count := cards.size() if _card.is_empty() else _target_count()
	if count == 0:
		return
	var next := clampi(maxi(_hover, 0) + step, 0, count - 1)
	while next >= 0 and next < count:
		if _card.is_empty() or progression.slot_status(_card, next) != "":
			_hover = next
			_reveal = true
			return
		next += step

func _target_count() -> int:
	if progression.link_replacing(_card):
		return weapons.slots[weapons.slot_by_uid(int(_card["receiver_uid"]))].modules.size()
	return weapons.slots.size()



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
			_reveal = true
			_hover = 0
			while _hover < weapons.slots.size() - 1 and progression.slot_status(_card, _hover) == "":
				_hover += 1
		else:
			_sound("confirm")
			chosen.emit(card, -1)
	else:
		if i >= _target_count() or progression.slot_status(_card, i) == "":
			_sound("deny")
			return
		_sound("confirm")
		if _card["type"] == "link":
			if progression.link_replacing(_card):
				_card["replacement"] = weapons.slots[weapons.slot_by_uid(int(_card["receiver_uid"]))].modules[i].duplicate(true)
				_hover = 0
				return
			if not _card.has("receiver_uid"):
				_card = _card.duplicate()
				_card["receiver_uid"] = weapons.slots[i].uid
				_hover = 0
				return
			_card["partner_uid"] = weapons.slots[i].uid
			if _card.has("rebind"):
				progression.apply(_card, weapons.slot_by_uid(int(_card["receiver_uid"])))
				_card = {}
				_hover = 0
				return
			chosen.emit(_card, weapons.slot_by_uid(int(_card["receiver_uid"])))
			return
		chosen.emit(_card, i)


func _sound(id: String) -> void:
	if sfx != null:
		sfx.play("ui/" + id)


func _draw() -> void:
	if not visible:
		return
	_ui = SettingsLayout.scale_for(size)
	var columns := SettingsLayout.columns(size, _ui, CARD_W, GAP, cards.size())
	var rows := ceili(float(cards.size()) / columns)
	var minimum := Vector2(columns * (CARD_W + GAP) - GAP + 24, 94 + rows * (CARD_H + GAP) + 24)
	if not _card.is_empty():
		minimum = Vector2(minf(540, size.x / _ui - 14), 150 + weapons.slots.size() * 48)
	var virtual_view := _layout.view(size, minimum, _ui)
	_offset = _layout.offset
	draw_set_transform(_offset, 0.0, Vector2(_ui, _ui))
	var w := virtual_view.x
	var h := virtual_view.y
	var font := Style.BODY_FONT
	draw_rect(Rect2(0, 0, w, h), Color(Style.RECESS, 0.92))
	_rects.clear()
	if _card.is_empty():
		_draw_cards(font, w, h)
	else:
		_draw_slots(font, w, h)
	if _reveal and _hover >= 0 and _hover < _rects.size():
		_layout.reveal(_rects[_hover].grow(3))
		_reveal = false


func _draw_cards(font: Font, w: float, h: float) -> void:
	var title := "УРОВЕНЬ %d" % (progression.level - progression.pending + 1) if _title == "" else _title
	var columns := SettingsLayout.columns(size, _ui, CARD_W, GAP, cards.size())
	var rows := ceili(float(cards.size()) / columns)
	var total := columns * CARD_W + (columns - 1) * GAP
	var x0 := (w - total) * 0.5
	_text(font, Vector2(x0, 44), "Z.E.R.A. / ПОЛЕВАЯ ПОДГОТОВКА", Style.MUTED, 8)
	_text(font, Vector2(x0, 68), title, Style.TEXT, 20)
	if _subtitle != "":
		_text(font, Vector2(x0, 82), _subtitle, Style.MUTED, 9)
	var y0 := 94.0
	for i in cards.size():
		var d := progression.describe(cards[i])
		var r := Rect2(x0 + (i % columns) * (CARD_W + GAP), y0 + floorf(float(i) / columns) * (CARD_H + GAP), CARD_W, CARD_H)
		_rects.append(r)
		var col := Style.card_color(cards[i])
		var hover := _hover == i
		Style.cloth(self, r)
		if hover:
			Style.surface(self, r, Style.State.SELECTED)
		_text(font, r.position + Vector2(12, 18), str(d["kind"]), col, 8)
		_text(font, r.position + Vector2(CARD_W - 19, 18), ("A" if hover else "") if ChoiceInput.pad_mode else str(i + 1), Style.MUTED, 9)
		var plate := Rect2(r.position + Vector2(12, 28), Vector2(CARD_W - 24, 48))
		_draw_icon(d, plate, 1.0)
		var y := 94.0
		for part in _wrap(font, str(d["title"]), CARD_W - 24, 13):
			_text(font, r.position + Vector2(12, y), part, Style.TEXT, 13)
			y += 15.0
		draw_choice(self, font, cards[i], progression, r.position + Vector2(12, 127), CARD_W - 24)
		var lines: Array = d["details"]
		var detail := " · ".join(lines) if hover else ""
		var dy := 184.0
		if hover and cards[i]["type"] in ["weapon", "level"]:
			_text(font, r.position + Vector2(12, 172), "DPS · с перезарядкой" + (" / дальность" if cards[i]["type"] == "weapon" else ""), Style.MUTED, 8)
		for line in _wrap(font, detail, CARD_W - 24, 8):
			if dy <= 202:
				_text(font, r.position + Vector2(12, dy), line, Style.MUTED, 8)
			dy += 9
		_text(font, r.position + Vector2(12, 214), ("A · ВЫБРАТЬ" if ChoiceInput.pad_mode else "Enter · ВЫБРАТЬ") if hover else ("ОБЫЧНАЯ" if not str(d["kind"]).contains("РЕДК") else "РЕДКАЯ"), Style.SELECTED, 8)
	var hint := "D-pad · выбор   A · принять" if ChoiceInput.pad_mode else "1–%d / клик · выбрать   ← → · фокус" % cards.size()
	if progression.rerolls > 0 and _title == "":
		hint += ("   X" if ChoiceInput.pad_mode else "   Q") + " · заменить (%d)" % progression.rerolls
	hint += "   F · Батарея" + (" ✓" if progression.focus_overflow else "")
	for s in weapons.slots:
		var m := s.module(WeaponDefs.Module.LINK)
		if not m.is_empty() and not m["active"]: hint += "   B · восстановить связь"
	_text_c(font, Vector2(w * 0.5, minf(h - 12, y0 + rows * (CARD_H + GAP) + 8)), hint, Style.MUTED, 8)


## Сравнение без изменения сборки, с текущими усилениями ствола.
static func draw_link(canvas: CanvasItem, font: Font, card: Dictionary, prog: Progression, at: Vector2, width: float, target := -1) -> void:
	var moving := prog.link_instance(int(card.get("rebind", 0)))
	var receiver := prog.weapons.slot_by_uid(int(card.get("receiver_uid", 0)))
	var partner := target if receiver >= 0 else -1
	if receiver < 0 and target >= 0: receiver = target
	if receiver < 0:
		for i in prog.weapons.slots.size():
			if prog.weapons.link_available(i, -1, moving):
				receiver = i
				break
	if receiver < 0: return
	if partner < 0:
		for i in prog.weapons.slots.size():
			if prog.weapons.link_available(receiver, i, moving):
				partner = i
				break
	if partner < 0: return
	var guns := prog.weapons
	var x := at.x + (52.0 if target >= 0 else width * 0.5)
	for pair: Array in [[partner, -51.0], [receiver, 16.0]]:
		var tex := Progression.card_icon("gun_" + guns.slots[pair[0]].model)
		var scale := minf(36.0 / tex.get_width(), 18.0 / tex.get_height())
		canvas.draw_texture_rect(tex, Rect2(Vector2(x + pair[1], at.y - 12), tex.get_size() * scale), false)
	choice_icon(canvas, "sy2_overflow", Vector2(x - 8, at.y - 13))
	var data := prog.comparison(card, receiver)
	choice_text(canvas, at + (Vector2(125, 3) if target >= 0 else Vector2(0, 28)), "+≤%s · %s с" % [Progression._num(data["cap"]), Progression._num(data["seconds"])], width - (125.0 if target >= 0 else 0.0), 12 if target >= 0 else 15, Style.BETTER)
	if card.has("replacement"):
		choice_text(canvas, at + Vector2(0, 21 if target >= 0 else 46), "− " + str(WeaponDefs.MODULES[card["replacement"]["id"]]["name"]), width, 9, Style.DANGER)


static func preview(card: Dictionary, prog: Progression, guns: Weapons) -> Array[String]:
	if card["type"] == "level":
		var row: Array = prog.comparison(card)["rows"][0]
		return ["%s → %s" % [row[1], row[2]], "DPS · с перезарядкой"]
	if card["type"] == "passive":
		var id: int = card["id"]
		var level: int = prog.passives.get(id, 0)
		var step := float(WeaponDefs.PASSIVES[id]["per_level"])
		if id == WeaponDefs.Passive.HP:
			return ["%d → %d" % [prog.player.max_hp, prog.player.max_hp + step], "максимальное здоровье"]
		var sign := "−" if id == WeaponDefs.Passive.RELOAD else "+"
		return ["%s%d → %s%d%%" % [sign, roundi(level * step * 100), sign, roundi((level + 1) * step * 100)], "общий бонус · " + str(WeaponDefs.PASSIVES[id]["big"][1])]
	return []


## Одинаковые числа и знаки на картах и в лавке. Подробности остаются у фокуса.
static func draw_choice(canvas: CanvasItem, font: Font, card: Dictionary, prog: Progression, at: Vector2, width: float, fs := 18, target := -1) -> void:
	if card["type"] == "link":
		draw_link(canvas, font, card, prog, at, width, target)
		return
	var data := prog.comparison(card, target)
	if not data.is_empty():
		var rows: Array = data["rows"]
		for k in mini(2, rows.size()):
			var row: Array = rows[k]
			var p := at + Vector2(0, k * 23)
			choice_icon(canvas, "ux1_" + str(row[0]), p - Vector2(0, 12))
			var value := str(row[2]) if row[1] == "" else "%s → %s" % [row[1], row[2]]
			var color := Style.TEXT
			if row[1] != "" and row[1] != row[2]:
				var better := float(row[2]) > float(row[1])
				if row[0] == "reload":
					better = not better
				color = Style.BETTER if better else Style.DANGER
			choice_text(canvas, p + Vector2(22, 0), value, width - 22, fs, color)
		if card["type"] == "weapon":
			var base: int = WeaponDefs.MODELS[data["model"]]["base"]
			choice_icon(canvas, "ux1_" + Progression.role(base), at + Vector2(width - 37, -58))
			var model: Dictionary = WeaponDefs.MODELS[data["model"]]
			var pattern := "line" if model["trait"] == "slug" else Progression.pattern(base)
			choice_icon(canvas, "ux1_" + pattern, at + Vector2(width - 16, -58))
		elif data["old_icon"] != "":
			choice_icon(canvas, data["old_icon"], at + Vector2(width - 68, 8))
			choice_text(canvas, at + Vector2(width - 45, 21), "→", 20, 12, Style.DANGER)
			choice_icon(canvas, "card_ammo_%d" % card["id"], at + Vector2(width - 24, 8))
		if float(data.get("lost_charge", -1.0)) >= 0.0:
			choice_icon(canvas, "sy2_overflow", at + Vector2(width - 80, -12))
			choice_text(canvas, at + Vector2(width - 60, 0), "−%s" % Progression._num(data["lost_charge"]), 60, 12, Style.DANGER)
		return
	var d := prog.describe(card)
	var text := preview(card, prog, prog.weapons)
	if card["type"] == "module" and card["id"] == WeaponDefs.Module.TWIN:
		# Сдвоенный ствол даёт разное число дробин и учитывает редкость уже стоящего модуля.
		var gains: Array[float] = []
		var units: Array[String] = []
		for i in prog.weapons.slots.size():
			if prog.slot_status(card, i) == "":
				continue
			var change := prog.comparison(card, i)
			var slug: bool = prog.weapons.slots[i].trait_id == "slug"
			var key := "damage" if slug else "proj"
			gains.append(float(change["after"][key]) - float(change["before"][key]))
			var unit := "урон" if slug else "снаряда за выстрел"
			if unit not in units:
				units.append(unit)
		if not gains.is_empty() and units.size() == 1:
			gains.sort()
			d["big"] = "+" + Progression._num(gains[0]) + ("–" + Progression._num(gains[-1]) if gains[0] != gains[-1] else "")
			d["unit"] = units[0]
		elif units.size() > 1:
			d["big"] = "+1"
			d["unit"] = "ранг · урон / снаряды"
	choice_text(canvas, at, str(d["big"]) if text.is_empty() else text[0], width, fs, Style.TEXT)
	choice_text(canvas, at + Vector2(0, 12), str(d["unit"]) if text.is_empty() else text[1], width, 8, Style.MUTED)
	if Progression.needs_slot(card):
		var n := 0
		for i in prog.weapons.slots.size():
			if prog.slot_status(card, i) == "":
				continue
			var s: Weapons.Slot = prog.weapons.slots[i]
			var p := at + Vector2((n % 2) * width * 0.5, 22 + floorf(n / 2.0) * 17)
			var tex := Progression.card_icon("gun_" + s.model)
			var scale := minf(36.0 / tex.get_width(), 12.0 / tex.get_height())
			canvas.draw_texture_rect(tex, Rect2(p, tex.get_size() * scale), false)
			choice_text(canvas, p + Vector2(38, 10), str(i + 1), 15, 9, Style.SELECTED)
			n += 1


static func choice_icon(canvas: CanvasItem, name: String, at: Vector2) -> void:
	var tex := Progression.card_icon(name)
	if tex:
		canvas.draw_texture_rect(tex, Rect2(at, Vector2(16, 16)), false)


static func choice_text(canvas: CanvasItem, at: Vector2, value: String, width: float, fs: int, color: Color) -> void:
	var scale := float(canvas.get("_ui"))
	var offset: Vector2 = canvas.get("_offset")
	var font := Style.TITLE_FONT if fs >= 13 else Style.BODY_FONT
	while fs > 10 and font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(fs * scale)).x / scale > width:
		fs -= 1
	canvas.draw_set_transform(offset)
	canvas.draw_string(font, at * scale, value, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(fs * scale), color)
	canvas.draw_set_transform(offset, 0.0, Vector2(scale, scale))


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
	if progression.link_replacing(_card):
		var s := weapons.slots[weapons.slot_by_uid(int(_card["receiver_uid"]))]
		_text_c(font, Vector2(w * 0.5, 70), "Перелив: какую деталь заменить?", Style.TEXT, 14)
		for i in s.modules.size():
			var m: Dictionary = s.modules[i]
			var r := Rect2((w - minf(500, w - 24)) * 0.5, 106 + i * 48, minf(500, w - 24), 42)
			_rects.append(r)
			Style.surface(self, r, Style.State.SELECTED if _hover == i else Style.State.NORMAL)
			_text(font, r.position + Vector2(12, 26), "%d. − %s %s" % [i + 1, WeaponDefs.MODULES[m["id"]]["name"], WeaponDefs.ROMAN[m["rank"]]], Style.DANGER, 12)
		_text_c(font, Vector2(w * 0.5, 106 + s.modules.size() * 48 + 16), "1–3 / клик · Esc — отмена", Style.MUTED, 9)
		return
	_text_c(font, Vector2(w * 0.5, 70), "%s: %s" % [d["title"], "партнёр?" if _card.has("receiver_uid") else "куда?"], Style.TEXT, 14)
	var row_w := minf(500, w - 24)
	var row_h := 42.0
	var x0 := (w - row_w) * 0.5
	var y0 := 106.0
	for i in weapons.slots.size():
		var s: Weapons.Slot = weapons.slots[i]
		var status := progression.slot_status(_card, i)
		var ok := status != ""
		var r := Rect2(x0, y0 + i * (row_h + 6.0), row_w, row_h)
		_rects.append(r)
		var col := Style.TEXT if ok else Style.DISABLED
		Style.surface(self, r, Style.State.SELECTED if _hover == i and ok else (Style.State.NORMAL if ok else Style.State.DISABLED))
		_text(font, r.position + Vector2(8, 13), "%d. %s ур.%d" % [i + 1, s.short_name(), s.level], col, 11)
		if ok:
			draw_choice(self, font, _card, progression, r.position + Vector2(row_w * 0.45, 17), row_w * 0.53 - 8, 12, i)
		else:
			_text(font, r.position + Vector2(8, 29), slot_summary(s), Color(col, 0.7), 8)
		if not ok:
			var right := "нет места"
			var tw := font.get_string_size(right, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			_text(font, r.position + Vector2(row_w - 8 - tw, 13), right, Style.DANGER, 10)
		var proto := progression.prototype_hint(_card, i)
		if proto != "" and ok:
			_text(font, r.position + Vector2(8, 29), proto, Style.ACTION, 8)
	_text_c(font, Vector2(w * 0.5, y0 + weapons.slots.size() * (row_h + 6.0) + 16.0), "Ⓐ   Ⓑ   ▲ ▼" if ChoiceInput.pad_mode else "1–4 / клик · Esc — назад", Style.MUTED, 9)


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
		if (Style.TITLE_FONT if fs >= 13 else font).get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(fs * _ui)).x / _ui > max_w and line != "":
			out.append(line)
			line = word
		else:
			line = test
	if line != "":
		out.append(line)
	return out


func _text(font: Font, p: Vector2, s: String, c: Color, fs := FONT) -> void:
	font = Style.TITLE_FONT if fs >= 13 else Style.BODY_FONT
	var k := int(_ui)
	draw_set_transform(_offset)
	draw_string(font, p * _ui, s, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(fs * _ui), c)
	draw_set_transform(_offset, 0.0, Vector2(_ui, _ui))


func _text_c(font: Font, p: Vector2, s: String, c: Color, fs := FONT) -> void:
	font = Style.TITLE_FONT if fs >= 13 else Style.BODY_FONT
	var tw := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(fs * _ui)).x / _ui
	_text(font, Vector2(p.x - tw * 0.5, p.y), s, c, fs)
