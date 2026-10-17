extends Control
## Лавка торговца: рисует состояние и передаёт действия в Trader.
## Паузой и удалением экрана управляет игра через сигнал closed.

signal closed

enum Step { SHOP, INSTALL, MOVE_SOURCE, MOVE_MODULE, MOVE_TARGET }
enum Action { HEAL = 100, REROLL, MOVE, CLOSE, BACK }

const GOLD := Color(1.0, 0.82, 0.35)
const WHITE := Color(0.92, 0.90, 0.85)
const MUTED := Color(0.65, 0.65, 0.62)
const RED := Color(0.92, 0.43, 0.40)
const GREEN := Color(0.60, 0.90, 0.60)
const GAP := 8.0
const INPUT_DELAY := 0.25

var _trader: Trader
var _progression: Progression
var _weapons: Weapons
var _minutes := 0.0
var _step: Step = Step.SHOP
var _offer := -1
var _source := -1
var _module := -1
var _ui := 1.0
var _t := 0.0
var _anim := 0.0
var _hover := -1
var _scroll := 0.0
var _scroll_max := 0.0
var _rects: Array[Rect2] = []
var _actions: Array[int] = []
var _offer_cache: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(_mouse_left)


func open(trader: Trader, progression: Progression, weapons: Weapons, minutes: float) -> void:
	var same_trader := _trader == trader
	_disconnect_trader()
	_trader = trader
	_progression = progression
	_weapons = weapons
	_minutes = minutes
	_offer = -1
	_source = -1
	_module = -1
	_t = 0.0
	if not same_trader:
		_offer_cache.clear()
	_sync_offers()
	if not _trader.changed.is_connected(_on_changed):
		_trader.changed.connect(_on_changed)
	_set_step(Step.SHOP)
	visible = true


func close() -> void:
	if not visible:
		return
	visible = false
	_disconnect_trader()
	_rects.clear()
	_actions.clear()
	closed.emit()


func _exit_tree() -> void:
	_disconnect_trader()


func _disconnect_trader() -> void:
	if is_instance_valid(_trader) and _trader.changed.is_connected(_on_changed):
		_trader.changed.disconnect(_on_changed)


func _sync_offers() -> void:
	# Проданные карты сохраняют описание до покупки, включая прежний уровень.
	var next_cache: Array[Dictionary] = []
	for i in _trader.offers.size():
		var card: Dictionary = _trader.offers[i]["card"]
		if i < _offer_cache.size() and _offer_cache[i]["card"] == card:
			next_cache.append(_offer_cache[i])
		else:
			next_cache.append({"card": card.duplicate(true), "description": _describe_offer(i)})
	_offer_cache = next_cache


func _describe_offer(index: int) -> Dictionary:
	var offer: Dictionary = _trader.offers[index]
	var card: Dictionary = offer["card"]
	# Экран может впервые открыться уже после покупки максимального уровня.
	if offer["sold"] and card["type"] == "level":
		var slot: Weapons.Slot = _weapons.slots[int(card["slot"])]
		return {"kind": "УЛУЧШЕНИЕ СТВОЛА", "title": "%s · ур. %d" % [WeaponDefs.BASES[slot.base]["short"], slot.level], "lines": ["Улучшение приобретено"], "color": WHITE}
	if offer["sold"] and card["type"] == "passive":
		var passive: Dictionary = WeaponDefs.PASSIVES[int(card["id"])]
		return {"kind": "ПАССИВКА", "title": passive["name"], "lines": [passive["text"]], "color": GREEN}
	return _progression.describe(card)


func _on_changed() -> void:
	_sync_offers()
	if _step == Step.INSTALL and not _trader.can_buy(_offer):
		_set_step(Step.SHOP)
	elif _step in [Step.MOVE_MODULE, Step.MOVE_TARGET]:
		if _source < 0 or _source >= _weapons.slots.size():
			_set_step(Step.MOVE_SOURCE)
		elif _step == Step.MOVE_TARGET and (_module < 0 or _module >= _weapons.slots[_source].modules.size()):
			_set_step(Step.MOVE_MODULE)
	queue_redraw()


func _set_step(value: Step) -> void:
	_step = value
	_hover = -1
	_scroll = 0.0
	_scroll_max = 0.0
	_anim = 0.0
	_rects.clear()
	_actions.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if visible:
		_t += delta
		_anim += delta
		queue_redraw()


func _mouse_left() -> void:
	_hover = -1
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	var motion := event as InputEventMouseMotion
	var button := event as InputEventMouseButton
	if motion == null and button == null:
		return
	get_viewport().set_input_as_handled()
	if _t < INPUT_DELAY:
		return
	if motion != null:
		_hover = _rect_at(motion.position / _ui)
	elif button.pressed:
		if button.button_index == MOUSE_BUTTON_LEFT:
			_activate(_rect_at(button.position / _ui))
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll = minf(_scroll + 20.0, _scroll_max)
		elif button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll = maxf(_scroll - 20.0, 0.0)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	var code := key.keycode
	# Буквенные команды доступны и при русской раскладке.
	if code not in [KEY_H, KEY_Q, KEY_M] and key.physical_keycode in [KEY_H, KEY_Q, KEY_M]:
		code = key.physical_keycode
	var action := -1
	match code:
		KEY_1, KEY_KP_1: action = 0
		KEY_2, KEY_KP_2: action = 1
		KEY_3, KEY_KP_3: action = 2
		KEY_4, KEY_KP_4: action = 3
		KEY_5, KEY_KP_5: action = 4
		KEY_H: action = Action.HEAL
		KEY_Q: action = Action.REROLL
		KEY_M: action = Action.MOVE
		KEY_ESCAPE: action = Action.BACK
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER: action = Action.CLOSE
		KEY_DOWN, KEY_PAGEDOWN: action = 200
		KEY_UP, KEY_PAGEUP: action = 201
		_: return
	get_viewport().set_input_as_handled()
	if key.echo or _t < INPUT_DELAY:
		return
	if action == 200:
		_scroll = minf(_scroll + 30.0, _scroll_max)
	elif action == 201:
		_scroll = maxf(_scroll - 30.0, 0.0)
	else:
		_activate(action)
	queue_redraw()


func _rect_at(point: Vector2) -> int:
	for i in _rects.size():
		if _rects[i].has_point(point):
			return _actions[i]
	return -1


func _activate(action: int) -> void:
	if action == Action.CLOSE:
		close()
	elif action == Action.BACK:
		match _step:
			Step.SHOP: close()
			Step.INSTALL, Step.MOVE_SOURCE: _set_step(Step.SHOP)
			Step.MOVE_MODULE: _set_step(Step.MOVE_SOURCE)
			Step.MOVE_TARGET: _set_step(Step.MOVE_MODULE)
	elif action >= 0 and action < 5:
		_pick(action)
	elif _step == Step.SHOP:
		match action:
			Action.HEAL:
				_trader.buy_heal()
			Action.REROLL:
				if _trader.can_afford(_trader.reroll_price):
					_offer_cache.clear()
					if _trader.reroll(_minutes):
						_set_step(Step.SHOP)
			Action.MOVE:
				if _any_moves():
					_set_step(Step.MOVE_SOURCE)
	queue_redraw()


func _pick(index: int) -> void:
	match _step:
		Step.SHOP:
			if not _trader.can_buy(index):
				return
			var card: Dictionary = _trader.offers[index]["card"]
			if Progression.needs_slot(card):
				_offer = index
				_set_step(Step.INSTALL)
			else:
				_trader.buy(index)
		Step.INSTALL:
			if index < _weapons.slots.size() and _trader.buy(_offer, index):
				_set_step(Step.SHOP)
		Step.MOVE_SOURCE:
			if index < _weapons.slots.size() and _source_can_move(index):
				_source = index
				_set_step(Step.MOVE_MODULE)
		Step.MOVE_MODULE:
			if _module_can_move(_source, index):
				_module = index
				_set_step(Step.MOVE_TARGET)
		Step.MOVE_TARGET:
			if _trader.can_move(_source, _module, index) and _trader.move_module(_source, _module, index):
				_set_step(Step.SHOP)


func _module_can_move(source: int, module_index: int) -> bool:
	if source < 0 or source >= _weapons.slots.size():
		return false
	for target in _weapons.slots.size():
		if _trader.can_move(source, module_index, target):
			return true
	return false


func _source_can_move(source: int) -> bool:
	for module_index in _weapons.slots[source].modules.size():
		if _module_can_move(source, module_index):
			return true
	return false


func _any_moves() -> bool:
	for source in _weapons.slots.size():
		if _source_can_move(source):
			return true
	return false


func _draw() -> void:
	if not visible or not is_instance_valid(_trader):
		return
	_ui = maxf(1.0, roundf(size.y / 360.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))
	var w := size.x / _ui
	var h := size.y / _ui
	var font := ThemeDB.fallback_font
	_rects.clear()
	_actions.clear()
	_scroll_max = 0.0
	draw_rect(Rect2(0.0, 0.0, w, h), Color(0.03, 0.0, 0.0, 0.86))
	_text_c(font, Vector2(w * 0.5, 29.0), "ТОРГОВЕЦ", GOLD, 18)
	_text_c(font, Vector2(w * 0.5, 48.0), "КРЕДИТЫ: %d" % _trader.credits(), GOLD, 13)
	if _step == Step.SHOP:
		_draw_offers(font, w, h)
	else:
		_draw_selection(font, w, h)
	_draw_actions(font, w, h)


func _panel(rect: Rect2, action: int, color: Color, enabled: bool, alpha: float = 1.0) -> void:
	_rects.append(rect)
	_actions.append(action)
	var hover := _hover == action and enabled
	draw_rect(rect, Color(0.13 if hover else 0.08, 0.10 if hover else 0.07, 0.07, 0.96 * alpha))
	draw_rect(rect, Color(color, (0.95 if hover else 0.45) * alpha), false, 1.0)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2.0)), Color(color, 0.8 * alpha))


func _draw_offers(font: Font, w: float, h: float) -> void:
	var count := _trader.offers.size()
	if count == 0:
		_text_c(font, Vector2(w * 0.5, h * 0.5), "Товаров пока нет", MUTED)
		return
	var card_w := minf(150.0, (w - 24.0 - GAP * (count - 1)) / count)
	var card_h := h - 156.0
	var x0 := (w - count * card_w - (count - 1) * GAP) * 0.5
	for i in count:
		var offer: Dictionary = _trader.offers[i]
		var description: Dictionary = _offer_cache[i]["description"]
		var sold: bool = offer["sold"]
		var enabled := _trader.can_buy(i)
		var color: Color = description["color"]
		var pop := clampf(_anim * 7.0 - i * 0.35, 0.0, 1.0)
		var alpha := pop * (0.38 if sold else 1.0)
		var rect := Rect2(x0 + i * (card_w + GAP), 76.0 + (1.0 - pop) * 14.0, card_w, card_h)
		_panel(rect, i, color, enabled, alpha)
		var p := rect.position + Vector2(7.0, 16.0)
		_text(font, p, _fit(font, str(description["kind"]), card_w - 28.0, 8), Color(color, alpha), 8)
		_text(font, rect.position + Vector2(card_w - 13.0, 16.0), str(i + 1), Color(WHITE, alpha), 9)
		var y := 33.0
		for title_line in _wrap(font, str(description["title"]), card_w - 14.0, 11):
			_text(font, rect.position + Vector2(7.0, y), title_line, Color(color, alpha), 11)
			y += 13.0
		var body: Array[String] = []
		for line: String in description["lines"]:
			body.append_array(_wrap(font, line, card_w - 14.0, 8))
		if description.has("ranks"):
			body.append("")
			var ranks: Array = description["ranks"]
			for rank_index in mini(3, ranks.size()):
				body.append_array(_wrap(font, "%s: %s" % [WeaponDefs.ROMAN[rank_index + 1], ranks[rank_index]], card_w - 14.0, 8))
		var bottom := card_h - 34.0
		_scroll_max = maxf(_scroll_max, body.size() * 10.0 - (bottom - y))
		for line_index in body.size():
			var line_y := y + line_index * 10.0 - _scroll
			if line_y >= y and line_y <= bottom:
				_text(font, rect.position + Vector2(7.0, line_y), body[line_index], Color(WHITE, alpha * 0.9), 8)
		draw_line(rect.position + Vector2(7.0, card_h - 28.0), rect.position + Vector2(card_w - 7.0, card_h - 28.0), Color(color, alpha * 0.3))
		var price := "ПРОДАНО" if sold else "%d кр." % int(offer["price"])
		_text_c(font, rect.position + Vector2(card_w * 0.5, card_h - 12.0), price, Color(GOLD if enabled else (MUTED if sold else RED), alpha), 11)
	if _scroll_max > 0.0:
		_text_c(font, Vector2(w * 0.5, h - 67.0), "Колесо / ↑↓ — описание", MUTED, 8)
	_scroll = minf(_scroll, _scroll_max)


func _draw_selection(font: Font, w: float, h: float) -> void:
	var heading := ""
	var subtitle := ""
	var count := _weapons.slots.size()
	match _step:
		Step.INSTALL:
			heading = "КУДА ПОСТАВИТЬ"
			subtitle = str(_offer_cache[_offer]["description"]["title"])
		Step.MOVE_SOURCE:
			heading = "ПЕРЕСТАВИТЬ МОДУЛЬ · 1/3"
			subtitle = "Выбери ствол-источник · " + _move_cost()
		Step.MOVE_MODULE:
			heading = "ВЫБЕРИ МОДУЛЬ · 2/3"
			subtitle = str(WeaponDefs.BASES[_weapons.slots[_source].base]["short"]) + " · " + _move_cost()
			count = _weapons.slots[_source].modules.size()
		Step.MOVE_TARGET:
			heading = "КУДА ПЕРЕСТАВИТЬ · 3/3"
			subtitle = _module_name(_weapons.slots[_source].modules[_module]) + " · " + _move_cost()
	_text_c(font, Vector2(w * 0.5, 67.0), _fit(font, heading, w - 24.0, 12), WHITE, 12)
	_text_c(font, Vector2(w * 0.5, 82.0), _fit(font, subtitle, w - 24.0, 9), GOLD, 9)
	var columns := 2 if count > 2 and (h - 166.0) / count - 5.0 < 43.0 else 1
	var rows := ceili(float(count) / columns)
	var total_w := minf(600.0 if columns == 2 else 560.0, w - 28.0)
	var row_w := (total_w - GAP * (columns - 1)) / columns
	var row_h := minf(70.0 if columns == 2 else 48.0, (h - 166.0) / maxi(rows, 1) - 5.0)
	for i in count:
		var rect := Rect2((w - total_w) * 0.5 + (i % columns) * (row_w + GAP), 94.0 + floorf(float(i) / columns) * (row_h + 5.0), row_w, row_h)
		if _step == Step.MOVE_MODULE:
			var module: Dictionary = _weapons.slots[_source].modules[i]
			var enabled := _module_can_move(_source, i)
			_panel(rect, i, WHITE if enabled else MUTED, enabled)
			_text(font, rect.position + Vector2(8.0, 14.0), "%d. %s" % [i + 1, _module_name(module)], WHITE if enabled else MUTED)
			var detail := "Выбрать ствол-цель" if enabled else "Нет доступной цели или кредитов"
			_text(font, rect.position + Vector2(8.0, 28.0), _fit(font, detail, row_w - 16.0, 8), GREEN if enabled else RED, 8)
		else:
			_draw_weapon_row(font, rect, i)
	if count == 0:
		_text_c(font, Vector2(w * 0.5, 122.0), "Нет доступных стволов или модулей", MUTED)


func _draw_weapon_row(font: Font, rect: Rect2, index: int) -> void:
	var slot: Weapons.Slot = _weapons.slots[index]
	var status := ""
	var hint := ""
	var enabled := false
	match _step:
		Step.INSTALL:
			var card: Dictionary = _trader.offers[_offer]["card"]
			status = _progression.slot_status(card, index)
			enabled = status != "" and _trader.can_buy(_offer)
			hint = _progression.prototype_hint(card, index)
			if status == "":
				status = "нет места"
		Step.MOVE_SOURCE:
			enabled = _source_can_move(index)
			status = "выбрать источник" if enabled else ("нет модулей" if slot.modules.is_empty() else "нет доступной цели")
		Step.MOVE_TARGET:
			enabled = _trader.can_move(_source, _module, index)
			status = _move_status(index) if enabled else ("ствол-источник" if index == _source else "нет места / кредитов")
	_panel(rect, index, WHITE if enabled else MUTED, enabled)
	var color := WHITE if enabled else MUTED
	var title := "%d. %s ур.%d" % [index + 1, WeaponDefs.BASES[slot.base]["short"], slot.level]
	_text(font, rect.position + Vector2(8.0, 13.0), _fit(font, title, rect.size.x * 0.44, 10), color)
	_text_right(font, rect.position + Vector2(rect.size.x - 8.0, 13.0), _fit(font, status, rect.size.x * 0.52, 9), GREEN if enabled else RED, 9)
	var summary := _wrap(font, slot_summary(slot), rect.size.x - 16.0, 8)
	for line_index in summary.size():
		var y := 22.0 + line_index * 9.0
		if y <= rect.size.y - (12.0 if hint != "" else 3.0):
			_text(font, rect.position + Vector2(8.0, y), summary[line_index], color, 8)
	if hint != "":
		_text_right(font, rect.position + Vector2(rect.size.x - 8.0, rect.size.y - 3.0), _fit(font, hint, rect.size.x - 16.0, 8), Color(1.0, 0.55, 0.3), 8)


func _move_status(target: int) -> String:
	var module: Dictionary = _weapons.slots[_source].modules[_module]
	var have := _weapons.slots[target].module(int(module["id"]))
	if have.is_empty():
		return "новый слот · " + str(WeaponDefs.ROMAN[int(module["rank"])])
	var rank := mini(int(have["rank"]) + int(module["rank"]), WeaponDefs.MAX_RANK)
	return "%s + %s → %s" % [WeaponDefs.ROMAN[int(have["rank"])], WeaponDefs.ROMAN[int(module["rank"])], WeaponDefs.ROMAN[rank]]


func _move_cost() -> String:
	var price := _trader.move_price()
	return "бесплатно" if price == 0 else "%d кр." % price


func _draw_actions(font: Font, w: float, h: float) -> void:
	var labels: Array[String] = []
	var details: Array[String] = []
	var ids: Array[int] = []
	var enabled: Array[bool] = []
	if _step == Step.SHOP:
		labels = ["H · Лечение", "Q · Реролл", "M · Переставить модуль", "В бой"]
		details = ["+50 HP · %d кр." % _trader.heal_price(), "%d кр." % _trader.reroll_price, _move_cost(), "Space / Enter"]
		ids = [Action.HEAL, Action.REROLL, Action.MOVE, Action.CLOSE]
		enabled = [_trader.can_heal(), _trader.can_afford(_trader.reroll_price), _any_moves(), true]
	else:
		labels = ["Назад", "В бой"]
		details = ["Esc", "Space / Enter"]
		ids = [Action.BACK, Action.CLOSE]
		enabled = [true, true]
	var total_w := minf(w - 24.0, 620.0 if _step == Step.SHOP else 300.0)
	var button_w := (total_w - GAP * (ids.size() - 1)) / ids.size()
	for i in ids.size():
		var rect := Rect2((w - total_w) * 0.5 + i * (button_w + GAP), h - 57.0, button_w, 34.0)
		var color := (GOLD if ids[i] == Action.CLOSE else WHITE) if enabled[i] else MUTED
		_panel(rect, ids[i], color, enabled[i])
		_text_c(font, rect.position + Vector2(button_w * 0.5, 14.0), _fit(font, labels[i], button_w - 10.0, 9), color, 9)
		_text_c(font, rect.position + Vector2(button_w * 0.5, 27.0), _fit(font, details[i], button_w - 10.0, 8), GOLD if enabled[i] else MUTED, 8)
	var hint := "1–5 / клик — купить · H — лечение · Q — реролл · M — перестановка · Esc — в бой"
	if _step != Step.SHOP:
		hint = "1–4 / клик — выбрать · Esc — назад · Space / Enter — в бой"
	_text_c(font, Vector2(w * 0.5, h - 8.0), _fit(font, hint, w - 16.0, 8), MUTED, 8)


static func _module_name(module: Dictionary) -> String:
	return "%s %s%s" % [WeaponDefs.MODULES[int(module["id"])]["name"], WeaponDefs.ROMAN[int(module["rank"])], " (редкий)" if module.get("rare", false) else ""]


static func slot_summary(slot: Weapons.Slot) -> String:
	var parts: Array[String] = ["%s %s%s" % [WeaponDefs.AMMO[slot.ammo]["name"], WeaponDefs.ROMAN[slot.ammo_rank], " (редкие)" if slot.ammo_rare else ""]]
	for module in slot.modules:
		parts.append(_module_name(module))
	parts.append("слоты %d/%d" % [slot.modules.size(), WeaponDefs.module_slots(slot.level)])
	return " · ".join(parts)


func _width(font: Font, value: String, font_size: int) -> float:
	# Измерение тем же размером, которым текст рисуется в полном разрешении.
	return font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size * int(_ui)).x / _ui


func _fit(font: Font, value: String, max_width: float, font_size: int) -> String:
	if _width(font, value, font_size) <= max_width:
		return value
	var result := value
	while not result.is_empty() and _width(font, result + "…", font_size) > max_width:
		result = result.left(result.length() - 1)
	return result + "…"


func _wrap(font: Font, value: String, max_width: float, font_size: int) -> Array[String]:
	var result: Array[String] = []
	var line := ""
	# Посимвольный запасной перенос не выпускает длинное слово за рамку.
	for paragraph in value.split("\n"):
		line = ""
		for word in paragraph.split(" ", false):
			var test := word if line.is_empty() else line + " " + word
			if not line.is_empty() and _width(font, test, font_size) > max_width:
				result.append(line)
				line = ""
			elif not line.is_empty():
				line += " "
			for character in word:
				if not line.is_empty() and _width(font, line + character, font_size) > max_width:
					result.append(line)
					line = ""
				line += character
		result.append(line)
	return result


func _text(font: Font, position_px: Vector2, value: String, color: Color, font_size: int = 10) -> void:
	var scale_int := int(_ui)
	draw_set_transform(Vector2.ZERO)
	draw_string_outline(font, position_px * _ui, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size * scale_int, 2 * scale_int, Color(0.0, 0.0, 0.0, 0.8 * color.a))
	draw_string(font, position_px * _ui, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size * scale_int, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))


func _text_c(font: Font, position_px: Vector2, value: String, color: Color, font_size: int = 10) -> void:
	_text(font, position_px - Vector2(_width(font, value, font_size) * 0.5, 0.0), value, color, font_size)


func _text_right(font: Font, position_px: Vector2, value: String, color: Color, font_size: int = 10) -> void:
	_text(font, position_px - Vector2(_width(font, value, font_size), 0.0), value, color, font_size)
