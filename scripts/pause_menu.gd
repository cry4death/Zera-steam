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
const KEYS := ["master", "weapons", "world", "ui", "music", "gore", "shake", "fullscreen", "auto_fire", "reduce_motion"]
const LABELS := ["Общая", "Оружие", "Мир", "Интерфейс", "Музыка", "Жестокость", "Тряска экрана", "Полный экран", "Автострельба", "Меньше анимации"]
## Разделы настроек: первые SOUND_ROWS строк — звук, остальные — изображение и управление.
const SOUND_ROWS := 5
## Подсказка к выбранной строке (до двух строк); у ползунков её нет.
const HELP := {
	"gore": ["Мало: меньше крови и останков; без брызг на экране."],
	"auto_fire": ["Авто: огонь без кнопки, ПКМ или правый стик — свой прицел.", "Выкл.: ЛКМ или правый курок — огонь, мышь или стик — прицел."],
	"reduce_motion": ["Меньше анимации интерфейса: без пульсации и плавного", "поворота глобуса. Тряска экрана настраивается отдельно."],
}
const SLIDERS := ["master", "weapons", "world", "ui", "music", "shake"]
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
	Music.duck(true)
	if game != null:
		get_tree().paused = true
	_sound("click")
	queue_redraw()


func close() -> void:
	visible = false
	_drag = -1
	Music.duck(false)
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
		_selected = posmod(_selected + step, KEYS.size() + 1 if settings_open else (2 if confirming else 3))
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
					if settings_open and i < KEYS.size() and KEYS[i] in SLIDERS and button.position.x / _ui >= _rows[i].position.x + 145.0:
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
	elif key in ["fullscreen", "auto_fire", "reduce_motion"]:
		Meta.set_setting(key, not Meta.settings[key])
		if key == "fullscreen" and DisplayServer.get_name() != "headless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if Meta.settings[key] else DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		Meta.set_setting(key, float(Meta.settings[key]) + direction * 0.05)
	_sound("click")


func _activate(i: int) -> void:
	_sound("confirm")
	if settings_open:
		if i == KEYS.size():
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
		_selected = 1 # случайный Enter не прерывает бой
	queue_redraw()


func _draw() -> void:
	_ui = maxf(1.0, floorf(size.y / 360.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * _ui)
	var view := size / _ui
	# на главном экране паузы в бою добавляется сборка: стволы, патроны, модули и пассивки полными названиями
	var build: Array[Array] = []
	if not settings_open and not confirming:
		build = _build_rows()
	var dimensions := Vector2(350, 354) if settings_open else Vector2(280, 208)
	if not build.is_empty():
		dimensions = Vector2(350, 206.0 + build.size() * 10.0 + 22.0)
	var panel := Rect2((view - dimensions) * 0.5, dimensions)
	var p := panel.position
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.025, 0.02, 0.02, 0.78))
	draw_rect(Rect2(p + Vector2(3, 4), dimensions), Color(0, 0, 0, 0.45))
	draw_rect(panel, Color(0.075, 0.065, 0.06, 0.98))
	draw_rect(panel, Color(GOLD, 0.55), false)
	draw_rect(Rect2(p, Vector2(dimensions.x, 3)), GOLD)
	_text(p + Vector2(18, 29), "НАСТРОЙКИ" if settings_open else (("ПРЕРВАТЬ ОПЕРАЦИЮ?" if _in_operation() else "ЗАВЕРШИТЬ ВЫЛАЗКУ?") if confirming else "ПАУЗА"), GOLD, 17)
	# регион операции одной строкой; в свободной вылазке и в настройках подзаголовка нет
	if not settings_open and _in_operation():
		_text(p + Vector2(18, 45), str(game.mission_config.get("region_name", "")), DIM, 9)
	_rows.clear()
	if settings_open:
		var y := 64.0
		for i in KEYS.size():
			if i == 0 or i == SOUND_ROWS:
				if i == SOUND_ROWS:
					y += 12.0
				_text(p + Vector2(18, y), "ЗВУК" if i == 0 else "ИЗОБРАЖЕНИЕ И УПРАВЛЕНИЕ", DIM, 8)
				y += 4.0
			var r := Rect2(p + Vector2(18, y), Vector2(314, 18))
			y += 19.0
			_rows.append(r)
			if i == _selected:
				draw_rect(r, Color(0.18, 0.15, 0.10))
			_text(r.position + Vector2(4, 14), LABELS[i], WHITE, 10)
			var value: Variant = Meta.settings[KEYS[i]]
			if KEYS[i] in SLIDERS:
				var bar := Rect2(r.position + Vector2(148, 9), Vector2(126, 4))
				draw_rect(bar, Color(0.25, 0.22, 0.18))
				draw_rect(Rect2(bar.position, Vector2(126 * float(value), 4)), GOLD)
				draw_rect(Rect2(bar.position + Vector2(126 * float(value) - 1, -3), Vector2(3, 10)), WHITE)
				_text(r.position + Vector2(281, 14), str(roundi(float(value) * 100)), GOLD, 9)
			else:
				_text(r.position + Vector2(148, 14), ["Мало", "Средне", "Максимум"][int(value)] if KEYS[i] == "gore" else ("Вкл." if value else "Выкл."), GOLD, 10)
		var help: Array = HELP.get(KEYS[_selected], []) if _selected < KEYS.size() else []
		for j in help.size():
			_text(p + Vector2(22, 300 + j * 11), str(help[j]), DIM, 8)
		_button(Rect2(p + Vector2(18, 322), Vector2(314, 22)), "НАЗАД", KEYS.size())
	else:
		if confirming:
			var campaign := _in_operation()
			_text(p + Vector2(18, 69), "Операция будет отмечена как провал." if campaign else "Вылазка будет прервана.", WHITE, 10)
			_text(p + Vector2(18, 84), "Заработанные образцы сохранятся.", DIM, 9)
			for i in 2:
				_button(Rect2(p + Vector2(18, 103 + i * 35), Vector2(244, 28)), (["ПРЕРВАТЬ", "ПРОДОЛЖИТЬ"] if campaign else ["ЗАВЕРШИТЬ", "ПРОДОЛЖИТЬ"])[i], i)
		else:
			for i in 3:
				_button(Rect2(p + Vector2(18, 67 + i * 35), Vector2(dimensions.x - 36.0 if not build.is_empty() else 244.0, 28)), ["ПРОДОЛЖИТЬ", "НАСТРОЙКИ", "НА БАЗУ"][i], i)
		if not build.is_empty():
			draw_rect(Rect2(p + Vector2(18, 181), Vector2(dimensions.x - 36.0, 1)), Color(DIM, 0.4))
			_text(p + Vector2(18, 195), "СБОРКА", DIM, 8)
			for j in build.size():
				var row: Array = build[j]
				_text(p + Vector2(18 + float(row[3]), 207 + j * 10), str(row[0]), row[1], int(row[2]))
	draw_set_transform(Vector2.ZERO)


## Строки сборки для паузы: [текст, цвет, размер, отступ]. Пусто — на базе или без игры.
func _build_rows() -> Array[Array]:
	var rows: Array[Array] = []
	if game == null:
		return rows
	var rare := Color(0.45, 0.72, 1.0)
	for slot: Weapons.Slot in game.weapons.slots:
		rows.append(["%s · ур. %d" % [WeaponDefs.MODELS[slot.model]["name"], slot.level], WHITE, 8, 0.0])
		var parts: Array[String] = ["%s %s" % [WeaponDefs.AMMO[slot.ammo]["name"], WeaponDefs.ROMAN[slot.ammo_rank]]]
		for m: Dictionary in slot.modules:
			parts.append("%s %s%s" % [WeaponDefs.MODULES[m["id"]]["name"], WeaponDefs.ROMAN[m["rank"]], " (редк.)" if m["rare"] else ""])
		for line in _wrap(" · ".join(parts), 300.0, 7):
			rows.append([line, DIM, 7, 8.0])
	var passives: Array[String] = []
	for id: int in game.progression.passives:
		passives.append("%s %d" % [WeaponDefs.PASSIVES[id]["name"], game.progression.passives[id]])
	if not passives.is_empty():
		for line in _wrap("Пассивки: " + " · ".join(passives), 314.0, 7):
			rows.append([line, Color(0.55, 0.95, 0.6), 7, 0.0])
	return rows


func _wrap(value: String, width: float, fs: int) -> Array[String]:
	var lines: Array[String] = []
	var line := ""
	for word: String in value.split(" "):
		var next := word if line.is_empty() else line + " " + word
		if not line.is_empty() and ThemeDB.fallback_font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width:
			lines.append(line)
			line = word
		else:
			line = next
	if not line.is_empty():
		lines.append(line)
	return lines


## Бой по заданию кампании (не свободная вылазка).
func _in_operation() -> bool:
	return game != null and not game.mission_config.is_empty()


func _button(r: Rect2, label: String, index: int) -> void:
	_rows.append(r)
	draw_rect(r, Color(0.22, 0.17, 0.09) if _selected == index else Color(0.11, 0.095, 0.075))
	draw_rect(r, Color(GOLD, 1.0 if _selected == index else 0.4), false)
	_text(r.position + Vector2(10, r.size.y * 0.5 + 4), label, GOLD if _selected == index else WHITE, 10)


func _text(p: Vector2, label: String, color: Color, fs: int) -> void:
	draw_set_transform(Vector2.ZERO)
	draw_string(ThemeDB.fallback_font, p * _ui, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * int(_ui), color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * _ui)
