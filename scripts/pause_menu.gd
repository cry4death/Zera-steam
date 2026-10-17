class_name PauseMenu
extends Control
## Общие настройки базы и забега; паузой владеет только открывшее её меню.

signal surrendered
var game: Node2D
var sfx: Sfx
var settings_open := false
var confirming := false
var _selected := 0
var _ui := 3.0
var _rows: Array[Rect2] = []
var _drag := -1
const KEYS := ["master", "weapons", "world", "ui", "gore", "shake", "fullscreen"]
const LABELS := ["Общая", "Оружие", "Мир", "Интерфейс", "Жестокость", "Тряска экрана", "Полный экран"]
const GOLD := Color(1.0, 0.82, 0.35)
const WHITE := Color(0.92, 0.90, 0.85)
const DIM := Color(0.60, 0.60, 0.57)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	resized.connect(queue_redraw)


func open(as_settings := false) -> void:
	settings_open = as_settings
	confirming = false
	_selected = 0
	visible = true
	if game != null:
		get_tree().paused = true
	_sound("click")
	queue_redraw()


func close() -> void:
	visible = false
	_drag = -1
	Meta.save()
	if game != null:
		get_tree().paused = false
	_sound("confirm")


func _sound(id: String) -> void:
	if sfx != null:
		sfx.play("ui/" + id)


func _back() -> void:
	_sound("click")
	if confirming:
		confirming = false
	elif settings_open and game != null:
		settings_open = false
	else:
		close()
	_selected = 0
	queue_redraw()


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	var pad := event as InputEventJoypadButton
	var esc := key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE
	var start := pad != null and pad.pressed and pad.button_index == JOY_BUTTON_START
	if not visible:
		if game != null and (esc or start) and not game.game_over and not get_tree().paused:
			open()
			get_viewport().set_input_as_handled()
		return
	if key == null and pad == null:
		return
	get_viewport().set_input_as_handled()
	if key != null and (not key.pressed or key.echo) or pad != null and not pad.pressed:
		return
	var code := key.keycode if key != null else KEY_NONE
	var button := pad.button_index if pad != null else -1
	if esc or start or button == JOY_BUTTON_B:
		_back()
	elif code in [KEY_UP, KEY_DOWN, KEY_TAB] or button in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]:
		var step := -1 if code == KEY_UP or button == JOY_BUTTON_DPAD_UP else 1
		_selected = posmod(_selected + step, 8 if settings_open else (2 if confirming else 3))
		_sound("click")
	elif code in [KEY_LEFT, KEY_RIGHT] or button in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
		_change(-1 if code == KEY_LEFT or button == JOY_BUTTON_DPAD_LEFT else 1)
	elif code in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] or button == JOY_BUTTON_A:
		_activate(_selected)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	var button := event as InputEventMouseButton
	if motion != null:
		if _drag >= 0:
			_slider(_drag, motion.position.x / _ui)
		else:
			for i in _rows.size():
				if _rows[i].has_point(motion.position / _ui):
					_selected = i
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if not button.pressed:
			_drag = -1
		else:
			for i in _rows.size():
				if _rows[i].has_point(button.position / _ui):
					_selected = i
					if settings_open and i in [0, 1, 2, 3, 5] and button.position.x / _ui >= _rows[i].position.x + 145.0:
						_drag = i
						_slider(i, button.position.x / _ui)
					else:
						_activate(i)
	queue_redraw()
	accept_event()


func _slider(i: int, x: float) -> void:
	var r := _rows[i]
	Meta.set_setting(KEYS[i], clampf((x - r.position.x - 148.0) / 126.0, 0.0, 1.0))


func _change(direction: int) -> void:
	if not settings_open or _selected >= KEYS.size():
		return
	var key: String = KEYS[_selected]
	if key == "gore":
		Meta.set_setting(key, posmod(int(Meta.settings[key]) + direction, 3))
	elif key == "fullscreen":
		Meta.set_setting(key, not Meta.settings[key])
		if DisplayServer.get_name() != "headless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if Meta.settings[key] else DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		Meta.set_setting(key, float(Meta.settings[key]) + direction * 0.05)
	_sound("click")


func _activate(i: int) -> void:
	_sound("confirm")
	if settings_open:
		if i == 7:
			_back()
		else:
			_change(1)
	elif confirming:
		if i == 0:
			visible = false
			surrendered.emit()
		else:
			_back()
	elif i == 0:
		close()
	elif i == 1:
		settings_open = true
		_selected = 0
	else:
		confirming = true
		_selected = 1 # случайный Enter не завершает забег
	queue_redraw()


func _draw() -> void:
	_ui = maxf(1.0, floorf(size.y / 360.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * _ui)
	var view := size / _ui
	var dimensions := Vector2(350, 316) if settings_open else Vector2(280, 208)
	var panel := Rect2((view - dimensions) * 0.5, dimensions)
	var p := panel.position
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.025, 0.02, 0.02, 0.78))
	draw_rect(Rect2(p + Vector2(3, 4), dimensions), Color(0, 0, 0, 0.45))
	draw_rect(panel, Color(0.075, 0.065, 0.06, 0.98))
	draw_rect(panel, Color(GOLD, 0.55), false)
	draw_rect(Rect2(p, Vector2(dimensions.x, 3)), GOLD)
	_text(p + Vector2(18, 29), "НАСТРОЙКИ" if settings_open else ("ЗАВЕРШИТЬ ЗАБЕГ?" if confirming else "ПАУЗА"), GOLD, 17)
	_text(p + Vector2(18, 45), "Изменения сохраняются сразу" if settings_open else "Карантинная зона · сектор 07", DIM, 9)
	_rows.clear()
	if settings_open:
		_text(p + Vector2(18, 64), "ГРОМКОСТЬ", DIM, 8)
		for i in 7:
			var r := Rect2(p + Vector2(18, 70 + i * 28), Vector2(314, 25))
			_rows.append(r)
			if i == _selected:
				draw_rect(r, Color(0.18, 0.15, 0.10))
			_text(r.position + Vector2(4, 16), LABELS[i], WHITE, 10)
			var value: Variant = Meta.settings[KEYS[i]]
			if i in [0, 1, 2, 3, 5]:
				var bar := Rect2(r.position + Vector2(148, 11), Vector2(126, 4))
				draw_rect(bar, Color(0.25, 0.22, 0.18))
				draw_rect(Rect2(bar.position, Vector2(126 * float(value), 4)), GOLD)
				draw_rect(Rect2(bar.position + Vector2(126 * float(value) - 1, -3), Vector2(3, 10)), WHITE)
				_text(r.position + Vector2(281, 16), str(roundi(float(value) * 100)), GOLD, 9)
			else:
				_text(r.position + Vector2(148, 16), ["Мало", "Средне", "Максимум"][int(value)] if i == 4 else ("Вкл." if value else "Выкл."), GOLD, 10)
		_text(p + Vector2(22, 275), "Мало: меньше крови и гибов, без брызг на экране", DIM, 8)
		_button(Rect2(p + Vector2(18, 285), Vector2(314, 22)), "НАЗАД", 7)
	else:
		if confirming:
			_text(p + Vector2(18, 69), "Забег будет засчитан как смерть.", WHITE, 10)
			_text(p + Vector2(18, 84), "Заработанная ДНК попадёт в итоги.", DIM, 9)
			for i in 2:
				_button(Rect2(p + Vector2(18, 103 + i * 35), Vector2(244, 28)), ["ЗАВЕРШИТЬ", "ОСТАТЬСЯ"][i], i)
		else:
			for i in 3:
				_button(Rect2(p + Vector2(18, 67 + i * 35), Vector2(244, 28)), ["ПРОДОЛЖИТЬ", "НАСТРОЙКИ", "НА БАЗУ"][i], i)
		_text(p + Vector2(18, 194), "↑↓ · ←→ · Enter / A · Esc / Start", DIM, 8)
	draw_set_transform(Vector2.ZERO)


func _button(r: Rect2, label: String, index: int) -> void:
	_rows.append(r)
	draw_rect(r, Color(0.22, 0.17, 0.09) if _selected == index else Color(0.11, 0.095, 0.075))
	draw_rect(r, Color(GOLD, 1.0 if _selected == index else 0.4), false)
	_text(r.position + Vector2(10, r.size.y * 0.5 + 4), label, GOLD if _selected == index else WHITE, 10)


func _text(p: Vector2, label: String, color: Color, fs: int) -> void:
	draw_set_transform(Vector2.ZERO)
	draw_string(ThemeDB.fallback_font, p * _ui, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * int(_ui), color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * _ui)
