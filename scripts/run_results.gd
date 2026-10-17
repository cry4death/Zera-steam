class_name RunResults
extends Control
## Итоги забега. Данные и перезапуск принадлежат игре; чек работает на паузе.

signal restart_requested
signal base_requested

const GOLD := Color(1.0, 0.82, 0.35)
const WHITE := Color(0.92, 0.90, 0.85)
const MUTED := Color(0.65, 0.65, 0.62)
const RED := Color(0.68, 0.23, 0.21)
const LINE_DELAY := 0.25
const COUNT_TIME := 0.3
const INPUT_DELAY := 0.25

var _stats: Dictionary = {}
var _report: Dictionary = {}
var _retry_button := Rect2()
var sfx: Sfx
var _ui := 1.0
var _t := 0.0
var _finished := false
var _requested := false
var _hover := -1
var _selected := 0 # основная кнопка — на базу, R всегда повторяет забег
var _button := Rect2()
var _base_button := Rect2()
var _body := Rect2()
var _scroll := 0.0
var _scroll_max := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false


func open(stats: Dictionary) -> void:
	_stats = stats.duplicate(true)
	_report = {}
	# Итоги забега уходят в мету: ДНК, ящики; сохранение пишется сразу, до нажатия кнопки.
	var config := Campaign.pending()
	# Снимок хранится в stats: повторное открытие после снятия pending тоже идемпотентно.
	if not config.is_empty() and not _stats.has("run_id"):
		for key: String in ["run_id", "operation_id", "region_id", "type"]:
			_stats[key] = config[key]
		_stats["outcome"] = "victory" if _stats.get("victory", false) else "defeat"
		stats.merge(_stats, true)
	if Campaign.enabled() and (not config.is_empty() or _stats.has("run_id")):
		var report := Campaign.complete_operation(_stats)
		_report = report
		if not _report.is_empty() and not Meta.last_save_ok:
			_report["save_error"] = Meta.last_error
		if report.has("stats"):
			_stats = report["stats"].duplicate(true)
	else:
		Meta.add_run(_stats)
	_stats["dna_bank"] = Meta.dna
	_t = 0.0
	_finished = false
	_requested = false
	_hover = -1
	_selected = 0
	_scroll = 0.0
	_scroll_max = 0.0
	visible = true
	queue_redraw()


func _duration() -> float:
	var lines: Array = _stats.get("dna_lines", [])
	return lines.size() * LINE_DELAY + COUNT_TIME * 2.0


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_finished = _t >= _duration()
	queue_redraw()


func _activate(restart := false) -> void:
	if _t < INPUT_DELAY or _requested:
		return
	if sfx != null:
		sfx.play("ui/click" if not _finished else "ui/confirm")
	if not _finished:
		_t = _duration()
		_finished = true
		queue_redraw()
	else:
		_requested = true
		if restart:
			if _report.is_empty():
				restart_requested.emit()
			else:
				get_tree().set_meta("c3_base_return", true)
				base_requested.emit()
		else:
			if not _report.is_empty():
				get_tree().set_meta("c3_map_return", str(_stats.get("region_id", "east_europe")))
			base_requested.emit()


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		var at := motion.position / _ui
		_hover = 0 if _base_button.has_point(at) else (1 if _button.has_point(at) else -1)
	var button := event as InputEventMouseButton
	if button != null and button.pressed:
		if button.button_index == MOUSE_BUTTON_LEFT:
			if not _report.is_empty() and _retry_button.has_point(button.position / _ui):
				_retry_save()
			elif _base_button.has_point(button.position / _ui):
				_activate()
			elif _button.has_point(button.position / _ui):
				_activate(true)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll = minf(_scroll + 22.0, _scroll_max)
		elif button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll = maxf(_scroll - 22.0, 0.0)
	accept_event()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var pad := event as InputEventJoypadButton
	if pad != null and pad.pressed:
		_hover = -1
		match pad.button_index:
			JOY_BUTTON_DPAD_LEFT: _selected = 0
			JOY_BUTTON_DPAD_RIGHT: _selected = 1
			JOY_BUTTON_A, JOY_BUTTON_START: _activate(_selected == 1)
			JOY_BUTTON_X: _activate(true)
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	var code := key.keycode
	if key.physical_keycode in [KEY_R, KEY_S]:
		code = key.physical_keycode
	if code not in [KEY_R, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_LEFT, KEY_RIGHT, KEY_DOWN, KEY_UP, KEY_PAGEDOWN, KEY_PAGEUP, KEY_S]:
		return
	get_viewport().set_input_as_handled()
	if key.echo:
		return
	_hover = -1
	match code:
		KEY_S: if not _report.is_empty(): _retry_save()
		KEY_R: _activate(true)
		KEY_LEFT: _selected = 0
		KEY_RIGHT: _selected = 1
		KEY_DOWN, KEY_PAGEDOWN: _scroll = minf(_scroll + 33.0, _scroll_max)
		KEY_UP, KEY_PAGEUP: _scroll = maxf(_scroll - 33.0, 0.0)
		_: _activate(_selected == 1)
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	_ui = maxf(1.0, roundf(size.y / 360.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))
	var view := size / _ui
	var panel := Rect2((view - Vector2(260.0, 316.0)) * 0.5, Vector2(260.0, 316.0))
	if not _report.is_empty():
		panel.position.x = (view.x - 536.0) * 0.5
	var p := panel.position
	var font := ThemeDB.fallback_font
	var victory: bool = _stats.get("victory", false)
	var accent := GOLD if victory else RED
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.03, 0.0, 0.0, 0.76))
	draw_rect(Rect2(p + Vector2(3, 4), panel.size), Color(0, 0, 0, 0.4))
	draw_rect(panel, Color(0.08, 0.07, 0.07, 0.97))
	draw_rect(panel, Color(accent, 0.55), false, 1.0)
	draw_rect(Rect2(p, Vector2(260, 3)), accent)
	var title := "ОБЪЕКТ-7 УНИЧТОЖЕН" if victory else "ВЫ ПОГИБЛИ"
	if not _report.is_empty():
		title = "ОПЕРАЦИЯ ВЫПОЛНЕНА" if victory else "ЕДИНИЦА ЭВАКУИРОВАНА"
	_text_c(font, p + Vector2(130, 23), title, accent, 13 if not _report.is_empty() else 14)
	_body = Rect2(p + Vector2(12, 34), Vector2(236, 205))
	_draw_receipt(font)
	draw_line(p + Vector2(12, 244), p + Vector2(248, 244), Color(GOLD, 0.4))
	var lines: Array = _stats.get("dna_lines", [])
	var total_progress := clampf((_t - lines.size() * LINE_DELAY - COUNT_TIME) / COUNT_TIME, 0.0, 1.0)
	_pair(font, p + Vector2(12, 258), 236.0, "ИТОГО ДНК", str(roundi(int(_stats.get("dna_total", 0)) * total_progress)), GOLD, 13)
	if total_progress >= 1.0:
		_text_c(font, p + Vector2(130, 268), "ДНК всего: %d" % int(_stats.get("dna_bank", 0)), MUTED, 8)
	_base_button = Rect2(p + Vector2(12, 274), Vector2(116, 24))
	_button = Rect2(p + Vector2(134, 274), Vector2(114, 24))
	for i in 2:
		var r := _base_button if i == 0 else _button
		var hot := _hover == i or (_hover < 0 and _selected == i)
		var c := GOLD if i == 0 else WHITE
		draw_rect(r, Color(0.19, 0.15, 0.08) if hot else Color(0.10, 0.09, 0.07))
		draw_rect(r, Color(c, 1.0 if hot else 0.45), false, 1.0)
		var label := "НА БАЗУ" if i == 0 else "ЕЩЁ РАЗ [R]"
		if not _report.is_empty():
			label = "К КАРТЕ ОПЕРАЦИЙ" if i == 0 else "БАЗА"
		_text_c(font, r.get_center() + Vector2(0, 4), label, c, 8 if not _report.is_empty() else 10)
	var hint := "Enter · допечатать" if not _finished else "←→ / A / Enter · R — ещё раз"
	if _scroll_max > 0.0:
		hint += " · ↑↓ / колесо — чек"
	if not _report.is_empty():
		hint = "←→ / A / Enter · ↑↓ / колесо — чек"
	_text_c(font, p + Vector2(130, 309), hint, MUTED, 8)
	if not _report.is_empty():
		_draw_consequences(font, Rect2(p + Vector2(272, 0), Vector2(264, 316)))


func _retry_save() -> void:
	Meta.save()
	_report["save_error"] = "" if Meta.last_save_ok else Meta.last_error
	queue_redraw()


func _draw_consequences(font: Font, panel: Rect2) -> void:
	var p := panel.position
	draw_rect(panel, Color("0e1514"))
	draw_rect(panel, Color(GOLD, 0.45), false)
	draw_rect(Rect2(p, Vector2(panel.size.x, 3)), GOLD)
	_text(font, p + Vector2(14, 24), "ПОСЛЕДСТВИЯ", GOLD, 14)
	_text(font, p + Vector2(14, 40), "ДИСПЕТЧЕР / ФРОНТ ОБНОВЛЁН", MUTED, 8)
	var y := 63.0
	for event: String in _report.get("events", []):
		for line in _wrap_words(font, event, 234, 10):
			_text(font, p + Vector2(14, y), line, WHITE, 10)
			y += 13
		y += 12
	draw_line(p + Vector2(14, 201), p + Vector2(250, 201), Color(GOLD, 0.3))
	_text(font, p + Vector2(14, 220), "Активных ульев: %d" % int(_report.get("nests_alive", 0)), GOLD, 11)
	_text(font, p + Vector2(14, 237), "Регионов в критическом: %d" % int(_report.get("critical", 0)), MUTED, 9)
	_text(font, p + Vector2(14, 256), "Причины изменений — в журнале региона", MUTED, 8)
	_text(font, p + Vector2(14, 268), "на оперативной карте.", MUTED, 8)
	_retry_button = Rect2()
	if not str(_report.get("save_error", "")).is_empty():
		_text(font, p + Vector2(14, 285), "НЕТ ЗАПИСИ НА ДИСК. Прогресс в памяти.", Color("ef7770"), 8)
		_retry_button = Rect2(p + Vector2(14, 291), Vector2(236, 18))
		draw_rect(_retry_button, Color("412824"))
		_text_c(font, _retry_button.get_center() + Vector2(0, 3), "ПОВТОРИТЬ СОХРАНЕНИЕ [S]", GOLD, 8)


func _wrap_words(font: Font, value: String, width: float, fs: int) -> Array[String]:
	var lines: Array[String] = []
	var line := ""
	for word: String in value.split(" "):
		var next := word if line.is_empty() else line + " " + word
		if not line.is_empty() and _width(font, next, fs) > width:
			lines.append(line)
			line = word
		else:
			line = next
	if not line.is_empty():
		lines.append(line)
	return lines


func _draw_receipt(font: Font) -> void:
	var x := _body.position.x
	var y := _body.position.y + 9.0 - _scroll
	var seconds := maxi(0, int(_stats.get("time", 0.0)))
	var rows: Array = [
		["Время", "%d:%02d" % [seconds / 60, seconds % 60]],
		["Убито", str(_stats.get("kills", 0))],
		["Элиток", str(_stats.get("elites", 0))],
		["Лучшая серия", str(_stats.get("best_combo", 0))],
		["Литров крови", "%.1f л" % float(_stats.get("blood_liters", 0.0))],
		["Ящики / военные", "%d / %d" % [int(_stats.get("crates", 0)), int(_stats.get("military_crates", 0))]],
	]
	for row: Array in rows:
		_body_pair(font, Vector2(x, y), _body.size.x, str(row[0]), str(row[1]), WHITE)
		y += 10.0
	y += 2.0
	_body_text(font, Vector2(x, y), "СОБРАННЫЕ СТВОЛЫ", MUTED, 8)
	y += 10.0
	var weapons: Array = _stats.get("weapons", [])
	var columns := 2 if weapons.size() > 4 else 1
	var width := (_body.size.x - (columns - 1) * 10.0) / columns
	for i in range(0, weapons.size(), columns):
		var wrapped: Array = []
		var height := 1
		for column in mini(columns, weapons.size() - i):
			var parts := _wrap(font, str(weapons[i + column]), width, 8)
			wrapped.append(parts)
			height = maxi(height, parts.size())
		for column in wrapped.size():
			var parts: Array = wrapped[column]
			for j in parts.size():
				_body_text(font, Vector2(x + column * (width + 10.0), y + j * 9.0), str(parts[j]), WHITE, 8)
		y += height * 9.0
	if weapons.is_empty():
		_body_text(font, Vector2(x, y), "—", MUTED, 8)
		y += 10.0
	y += 2.0
	_body_text(font, Vector2(x + _body.size.x * 0.5 - _width(font, "— ДНК —", 9) * 0.5, y), "— ДНК —", GOLD, 9)
	y += 13.0
	var lines: Array = _stats.get("dna_lines", [])
	columns = 2 if lines.size() > 8 else 1
	width = (_body.size.x - (columns - 1) * 10.0) / columns
	for i in lines.size():
		var progress := clampf((_t - i * LINE_DELAY) / COUNT_TIME, 0.0, 1.0)
		if _t >= i * LINE_DELAY:
			var line: Array = lines[i]
			var at := Vector2(x + (i % columns) * (width + 10.0), y + floorf(float(i) / columns) * 10.0)
			_body_pair(font, at, width, str(line[0]), str(roundi(int(line[1]) * progress)), WHITE, 8)
	y += ceili(float(lines.size()) / columns) * 10.0
	var mult := float(_stats.get("dna_mult", 1.0))
	if mult > 1.0:
		if _t >= lines.size() * LINE_DELAY:
			_body_text(font, Vector2(x, y), "× %.1f победа" % mult, GOLD, 9)
		y += 12.0
	_scroll_max = maxf(0.0, y + _scroll - _body.end.y + 3.0)
	_scroll = minf(_scroll, _scroll_max)


func _body_text(font: Font, p: Vector2, value: String, color: Color, fs: int) -> void:
	# Полные строки не пересекают заголовок, итог и кнопку при прокрутке.
	if p.y - fs >= _body.position.y and p.y + 3.0 <= _body.end.y:
		_text(font, p, value, color, fs)


func _body_pair(font: Font, p: Vector2, width: float, label: String, value: String, color: Color, fs: int = 9) -> void:
	if p.y - fs >= _body.position.y and p.y + 3.0 <= _body.end.y:
		_pair(font, p, width, label, value, color, fs)


func _pair(font: Font, p: Vector2, width: float, label: String, value: String, color: Color, fs: int) -> void:
	var value_w := _width(font, value, fs)
	var label_size := fs
	while label_size > 6 and _width(font, label, label_size) > width - value_w - 10.0:
		label_size -= 1
	var fitted := label
	while not fitted.is_empty() and _width(font, fitted, label_size) > width - value_w - 10.0:
		fitted = fitted.left(fitted.length() - 1)
	if fitted != label:
		fitted = fitted.left(maxi(0, fitted.length() - 1)) + "…"
	_text(font, p, fitted, color, label_size)
	var start := _width(font, fitted, label_size) + 4.0
	var end := width - value_w - 4.0
	for dot in maxi(0, int((end - start) / 4.0)):
		draw_rect(Rect2(p + Vector2(start + dot * 4.0, -2), Vector2.ONE), Color(MUTED, 0.35))
	_text(font, p + Vector2(width - value_w, 0), value, color, fs)


func _wrap(font: Font, value: String, width: float, fs: int) -> Array[String]:
	var result: Array[String] = []
	var line := ""
	for character in value.replace("\n", " "):
		if not line.is_empty() and _width(font, line + character, fs) > width:
			result.append(line)
			line = ""
		line += character
	result.append(line)
	return result


func _width(font: Font, value: String, fs: int) -> float:
	return font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * int(_ui)).x / _ui


func _text(font: Font, p: Vector2, value: String, color: Color, fs: int) -> void:
	var k := int(_ui)
	draw_set_transform(Vector2.ZERO)
	draw_string_outline(font, p * _ui, value, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * k, 2 * k, Color(0, 0, 0, 0.8 * color.a))
	draw_string(font, p * _ui, value, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * k, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))


func _text_c(font: Font, p: Vector2, value: String, color: Color, fs: int) -> void:
	_text(font, p - Vector2(_width(font, value, fs) * 0.5, 0), value, color, fs)


