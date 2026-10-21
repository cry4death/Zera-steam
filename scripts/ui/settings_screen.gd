class_name SettingsScreen
extends Control
## Вкладки, прокрутка и захват назначения не передают ввод в бой.

signal back
const Style := preload("res://scripts/ui/zera_style.gd")
const TABS := ["УПРАВЛЕНИЕ", "ЭКРАН", "ЗВУК", "ИГРА"]
const KEYS := [[], ["ui_scale", "shake", "screen_flashes", "screen_blood", "camera_recoil", "alarm_blink", "fullscreen", "reduce_motion"], ["master", "music", "effects", "ui", "weapons", "world"], ["auto_fire", "gore"]]
const NAMES := {"ui_scale": "Масштаб интерфейса", "shake": "Тряска камеры", "screen_flashes": "Вспышки экрана", "screen_blood": "Кровь на экране", "camera_recoil": "Отдача камеры", "alarm_blink": "Мигание тревоги", "fullscreen": "Полный экран", "reduce_motion": "Меньше анимации", "master": "Общая", "music": "Музыка", "effects": "Эффекты", "ui": "Интерфейс", "weapons": "Оружие", "world": "Мир", "auto_fire": "Автострельба", "gore": "Жестокость"}
var tab := 0
var selected := 0
var column := 0
var scroll := 0
var capture := false
var pending := 0
var _conflicts: Array[String] = []
var _ui := 1.0
var _panel := Rect2()
var _rows: Array[Rect2] = []
var _tabs: Array[Rect2] = []
var _back_rect := Rect2()
var _reset_rect := Rect2()
var _cancel_rect := Rect2()
var _drag := -1
var _capacity := 1
var _pad := ChoiceInput.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Meta.settings_changed.connect(queue_redraw)
	resized.connect(queue_redraw)
	hide()

func open() -> void:
	selected = 0
	scroll = 0
	capture = false
	pending = 0
	show()
	queue_redraw()

func _count() -> int:
	return SettingsBindings.ACTIONS.size() if tab == 0 else KEYS[tab].size()

func _select(value: int) -> void:
	selected = posmod(value, _count())
	column = mini(column, Meta.settings["bindings"][SettingsBindings.ACTIONS[selected]].size() - 1) if tab == 0 else 0
	scroll = clampi(scroll, maxi(0, selected - _capacity + 1), selected)
	queue_redraw()

func _tab(value: int) -> void:
	tab = posmod(value, 4)
	selected = 0
	column = 0
	scroll = 0
	queue_redraw()

func _leave() -> void:
	_drag = -1
	Meta.flush_settings()
	hide()
	back.emit()

func _activate() -> void:
	if tab == 0:
		capture = true
		pending = 0
		_conflicts.clear()
	else:
		_change(1)
	queue_redraw()

func _change(direction: int) -> void:
	if tab == 0:
		var codes: Array = Meta.settings["bindings"][SettingsBindings.ACTIONS[selected]]
		column = posmod(column + direction, codes.size())
	else:
		var key: String = KEYS[tab][selected]
		var value: Variant = Meta.settings[key]
		if value is bool:
			Meta.set_setting(key, not value)
		elif key == "gore":
			Meta.set_setting(key, posmod(int(value) + direction, 3))
		else:
			Meta.set_setting(key, snappedf(float(value) + direction * 0.05, 0.05), true)
	queue_redraw()

func _assign() -> void:
	var action: String = SettingsBindings.ACTIONS[selected]
	Meta.set_setting("bindings", SettingsBindings.rebind(Meta.settings["bindings"], action, column, pending))
	capture = false
	pending = 0
	queue_redraw()

func _slider(index: int, x: float) -> void:
	var key: String = KEYS[tab][index]
	var t := clampf((x - _panel.position.x - _panel.size.x * 0.59) / (_panel.size.x * 0.26), 0.0, 1.0)
	Meta.set_setting(key, snappedf(0.8 + t * 0.7 if key == "ui_scale" else t, 0.01), true)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	var command := _pad.read(event)
	get_viewport().set_input_as_handled()
	var mouse := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	var key := event as InputEventKey
	var pad := event as InputEventJoypadButton
	var pressed := (key != null and key.pressed and not key.echo) or (mouse != null and mouse.pressed) or (pad != null and pad.pressed)
	var at: Vector2 = event.position / _ui if event is InputEventMouse else Vector2.INF
	if capture:
		if (pad != null and pad.pressed and pad.button_index == JOY_BUTTON_B) or (mouse != null and mouse.pressed and _cancel_rect.has_point(at)):
			capture = false
		elif pressed and pending != 0:
			if (key != null and key.keycode in [KEY_ENTER, KEY_KP_ENTER]) or (pad != null and pad.button_index == JOY_BUTTON_A) or (mouse != null and _reset_rect.has_point(at)):
				_assign()
			elif key != null and key.keycode == KEY_ESCAPE:
				capture = false
		elif pressed:
			pending = SettingsBindings.code(event)
			if SettingsBindings.valid(pending):
				_conflicts = SettingsBindings.conflicts(Meta.settings["bindings"], SettingsBindings.ACTIONS[selected], pending)
				if _conflicts.is_empty():
					_assign()
			else:
				pending = 0
		queue_redraw()
		return
	if motion != null:
		if _drag >= 0:
			_slider(_drag, at.x)
		else:
			for i in _rows.size():
				if _rows[i].has_point(at):
					_select(i + scroll)
		return
	if mouse != null:
		if not mouse.pressed:
			_drag = -1
			Meta.flush_settings()
			return
		if mouse.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_select(selected + (1 if mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1))
			return
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		for i in _tabs.size():
			if _tabs[i].has_point(at):
				_tab(i)
		if _back_rect.has_point(at):
			_leave()
		elif tab == 0 and _reset_rect.has_point(at):
			Meta.set_setting("bindings", SettingsBindings.defaults())
			column = 0
		for i in _rows.size():
			if _rows[i].has_point(at):
				_select(i + scroll)
				if tab == 0:
					column = clampi(int((at.x - _panel.position.x - _panel.size.x * 0.49) / 48.0), 0, Meta.settings["bindings"][SettingsBindings.ACTIONS[selected]].size() - 1)
					_activate()
				else:
					var value: Variant = Meta.settings[KEYS[tab][selected]]
					if value is float and at.x >= _panel.position.x + _panel.size.x * 0.59:
						_drag = selected
						_slider(selected, at.x)
					else:
						_activate()
		queue_redraw()
		return
	if not pressed and not event is InputEventJoypadMotion:
		return
	var code := key.keycode if key != null else KEY_NONE
	var button := pad.button_index if pad != null else -1
	if code == KEY_ESCAPE or button in [JOY_BUTTON_B, JOY_BUTTON_START]:
		_leave()
	elif code == KEY_TAB or button in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
		_tab(tab + (-1 if (key != null and key.shift_pressed) or button == JOY_BUTTON_LEFT_SHOULDER else 1))
	elif code in [KEY_1, KEY_2, KEY_3, KEY_4]:
		_tab(code - KEY_1)
	elif command in ["up", "down"] or code in [KEY_UP, KEY_DOWN]:
		_select(selected + (-1 if command == "up" or code == KEY_UP else 1))
	elif command in ["left", "right"] or code in [KEY_LEFT, KEY_RIGHT]:
		_change(-1 if command == "left" or code == KEY_LEFT else 1)
	elif code in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] or button == JOY_BUTTON_A:
		_activate()
	elif (code == KEY_DELETE or button == JOY_BUTTON_Y) and tab == 0:
		Meta.set_setting("bindings", SettingsBindings.defaults())
		column = 0
	queue_redraw()

func _text(at: Vector2, value: String, fs: int, color := Style.TEXT) -> void:
	draw_set_transform(Vector2.ZERO)
	draw_string(Style.TITLE_FONT if fs >= 13 else Style.BODY_FONT, (at * _ui).round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(fs * _ui), color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * _ui)

func _draw() -> void:
	if size.x < 320 or size.y < 180:
		return
	_ui = SettingsLayout.scale_for(size)
	var view := size / _ui
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * _ui)
	draw_rect(Rect2(Vector2.ZERO, view), Color(Style.RECESS, 0.96))
	_panel = Rect2((view - Vector2(minf(600, view.x - 24), view.y - 24)) * 0.5, Vector2(minf(600, view.x - 24), view.y - 24))
	Style.cloth(self, _panel)
	var p := _panel.position
	var w := _panel.size.x
	_text(p + Vector2(12, 26), "НАСТРОЙКИ", 20, Style.ACTION)
	_tabs.clear()
	for i in 4:
		var r := Rect2(p + Vector2(12 + i * (w - 24) / 4.0, 38), Vector2((w - 24) / 4.0 - 3, 22))
		_tabs.append(r)
		Style.surface(self, r, Style.State.SELECTED if tab == i else Style.State.NORMAL)
		_text(r.position + Vector2(6, 15), TABS[i], 8, Style.TEXT if tab == i else Style.MUTED)
	_capacity = maxi(1, floori((_panel.size.y - 126) / 24))
	scroll = clampi(scroll, maxi(0, selected - _capacity + 1), selected)
	_rows.clear()
	for i in mini(_capacity, _count() - scroll):
		var index := i + scroll
		var r := Rect2(p + Vector2(12, 68 + i * 24), Vector2(w - 24, 23))
		_rows.append(r)
		if selected == index:
			Style.surface(self, r, Style.State.SELECTED)
		if tab == 0:
			_text(r.position + Vector2(6, 16), SettingsBindings.LABELS[index], 10)
			var values: Array = Meta.settings["bindings"][SettingsBindings.ACTIONS[index]]
			for j in values.size():
				var at := Vector2(p.x + w * 0.49 + j * 48, r.position.y + 16)
				_text(at, SettingsBindings.label(values[j]), 8, Style.ACTION if selected == index and column == j else Style.TEXT)
			if w >= 500:
				_text(Vector2(p.x + w - 57, r.position.y + 16), SettingsBindings.PAD[index], 8, Style.MUTED)
		else:
			var id: String = KEYS[tab][index]
			var value: Variant = Meta.settings[id]
			_text(r.position + Vector2(6, 16), NAMES[id], 10)
			var at := Vector2(p.x + w * 0.59, r.position.y + 16)
			if value is bool or id == "gore":
				_text(at, ["Мало", "Средне", "Максимум"][value] if id == "gore" else ("Вкл." if value else "Выкл."), 10, Style.ACTION)
			else:
				var t := (float(value) - 0.8) / 0.7 if id == "ui_scale" else float(value)
				var bar := Rect2(at + Vector2(0, -7), Vector2(w * 0.26, 3))
				draw_rect(bar, Style.DISABLED)
				draw_rect(Rect2(bar.position, Vector2(bar.size.x * t, 3)), Style.ACTION)
				draw_rect(Rect2(bar.position + Vector2(bar.size.x * t - 1, -3), Vector2(2, 9)), Style.TEXT)
				_text(at + Vector2(w * 0.26 + 8, 0), "%d%%" % roundi(float(value) * 100), 8, Style.ACTION)
	var y := _panel.end.y - 41
	_text(Vector2(p.x + 18, y - 7), "%d–%d / %d · ↑ ↓ прокрутка" % [scroll + 1, mini(scroll + _capacity, _count()), _count()], 8, Style.MUTED)
	if tab == 0 and w < 500:
		_text(Vector2(_panel.end.x - 80, y - 7), "PAD · " + SettingsBindings.PAD[selected], 8, Style.MUTED)
	_back_rect = Rect2(p.x + 12, y, 90, 25)
	Style.surface(self, _back_rect, Style.State.NORMAL)
	_text(_back_rect.position + Vector2(8, 17), "НАЗАД · B" if ChoiceInput.pad_mode else "НАЗАД · Esc", 8)
	_reset_rect = Rect2(_panel.end.x - 160, y, 148, 25)
	if tab == 0:
		Style.surface(self, _reset_rect, Style.State.NORMAL)
		_text(_reset_rect.position + Vector2(8, 17), "СБРОСИТЬ · Y" if ChoiceInput.pad_mode else "СБРОСИТЬ · Delete", 8)
		if w >= 500:
			_text(Vector2(p.x + 112, y + 16), "Enter · назначить   ← → · кнопка", 8, Style.MUTED)
	if capture:
		draw_rect(Rect2(Vector2.ZERO, view), Color(Style.RECESS, 0.97))
		var modal := Rect2(Vector2(16, view.y * 0.5 - 65), Vector2(view.x - 32, 130))
		Style.cloth(self, modal)
		_text(modal.position + Vector2(12, 22), SettingsBindings.LABELS[selected], 13, Style.ACTION)
		_text(modal.position + Vector2(12, 44), "Нажмите клавишу или кнопку мыши" if pending == 0 else SettingsBindings.label(pending) + " · уже назначено:", 10)
		var names: Array[String] = []
		for action: String in _conflicts:
			names.append(SettingsBindings.LABELS[SettingsBindings.ACTIONS.find(action)])
		if pending != 0:
			_text(modal.position + Vector2(12, 63), ", ".join(names), 10, Style.DANGER)
			_reset_rect = Rect2(modal.position + Vector2(12, 83), Vector2(172, 28))
			Style.surface(self, _reset_rect, Style.State.SELECTED)
			_text(_reset_rect.position + Vector2(8, 18), "ОБМЕНЯТЬ · Enter / A", 10)
		_cancel_rect = Rect2(modal.end - Vector2(128, 47), Vector2(116, 28))
		Style.surface(self, _cancel_rect, Style.State.NORMAL)
		_text(_cancel_rect.position + Vector2(8, 18), "ОТМЕНА · B", 10)
	draw_set_transform(Vector2.ZERO)
