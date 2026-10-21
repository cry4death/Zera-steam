class_name RunResults
extends Control
## Итоги забега. Данные и перезапуск принадлежат игре; чек работает на паузе.

signal restart_requested
signal base_requested

const Style := preload("res://scripts/ui/zera_style.gd")
const GOLD := Style.ACTION
const WHITE := Style.TEXT
const MUTED := Style.MUTED
const RED := Style.DANGER
const INPUT_DELAY := 0.25
# Хронометраж чека: крупные числа считаются с щелчками, затем по очереди появляются значки, ДНК и итог (U3).
const HERO_TIME := 0.45 # «убито» и «время»
const CHIP_AT := 0.3 # плашки: элитки, серия, кровь, ящики
const CHIP_STEP := 0.08
const GUN_AT := 0.5 # стволы
const DNA_AT := 0.6 # строки ДНК по 0.2 с, затем множители и итог
const DNA_STEP := 0.1
const TOTAL_TIME := 0.35
const BLOOD := Style.DANGER
const GREEN := Style.BETTER
const HP_RED := Style.DANGER
const RED_UP := Style.DANGER
const ICON_BG := Style.RECESS
const GUN_K := 2.0 / 3.0 # масштаб иконки ствола: 2 пикселя экрана на пиксель арта на 1080p

var _stats: Dictionary = {}
var _report: Dictionary = {}
var _retry_button := Rect2()
var sfx: Sfx
var _offset := Vector2.ZERO
var _layout: SettingsLayout.Scroll
var _reveal := true
var _ui := 1.0
var _t := 0.0
var _finished := false
var _requested := false
var _hover := -1
var _selected := 0 # основная кнопка — на базу, R всегда повторяет забег
var _button := Rect2()
var _base_button := Rect2()
var _scroll := 0.0 # прокрутка журнала в панели последствий
var _scroll_max := 0.0
var _journal := false # панель последствий показывает полный журнал
var _journal_button := Rect2()
var _icons := {}
var _tick_seen := {} # счётчик → сколько щелчков уже сыграно


var _choice_input := ChoiceInput.new()

func _ready() -> void:
	_layout = SettingsLayout.Scroll.new(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false


func open(stats: Dictionary) -> void:
	_reveal = true
	_stats = stats.duplicate(true)
	var class_before := Meta.class_level()
	_report = {}
	# Итоги забега уходят в мету: ДНК, ящики; сохранение пишется сразу, до нажатия кнопки.
	var config := Campaign.pending()
	# Снимок хранится в stats: повторное открытие после снятия pending тоже идемпотентно.
	if not _stats.get("endless", false) and not config.is_empty() and not _stats.has("run_id"):
		for key: String in ["run_id", "operation_id", "region_id", "type"]:
			_stats[key] = config[key]
		_stats["outcome"] = "victory" if _stats.get("victory", false) else "defeat"
		stats.merge(_stats, true)
	if not _stats.get("endless", false) and Campaign.enabled() and (not config.is_empty() or _stats.has("run_id")):
		var report := Campaign.complete_operation(_stats)
		_report = report
		if not _report.is_empty() and not Meta.last_save_ok:
			_report["save_error"] = Meta.last_error
		if report.has("stats"):
			_stats = report["stats"].duplicate(true)
	else:
		Meta.add_run(stats if _stats.get("endless", false) else _stats)
		if _stats.get("endless", false):
			_stats.merge(stats, true)
	_stats["dna_bank"] = Meta.dna
	_stats["class_before"] = class_before
	_stats["class_after"] = Meta.class_level()
	_t = 0.0
	_finished = false
	_requested = false
	_hover = -1
	_selected = 0
	_scroll = 0.0
	_scroll_max = 0.0
	_journal = false
	_tick_seen.clear()
	visible = true
	queue_redraw()


func _dna_lines() -> Array:
	return _stats.get("dna_lines", [])


func _total_at() -> float:
	return DNA_AT + _dna_lines().size() * DNA_STEP + 0.2


func _duration() -> float:
	return _total_at() + TOTAL_TIME


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_finished = _t >= _duration()
	_tick_sounds()
	queue_redraw()


## Щелчок на каждом шаге счёта: у каждого числа до 10 шагов, по одному щелчку на шаг.
func _tick_sounds() -> void:
	if sfx == null:
		return
	var counters: Array = [["kills", 0.0, HERO_TIME, int(_stats.get("kills", 0))], ["time", 0.0, HERO_TIME, int(_stats.get("time", 0.0))],
		["total", _total_at(), TOTAL_TIME, int(_stats.get("dna_total", 0))]]
	var clicked := false
	for c: Array in counters:
		var steps := mini(int(c[3]), 10)
		var step := int(clampf((_t - float(c[1])) / float(c[2]), 0.0, 1.0) * steps)
		if step > int(_tick_seen.get(c[0], 0)):
			_tick_seen[c[0]] = step
			clicked = true
	if clicked and not _finished:
		sfx.play("ui/click", Vector2.INF, -6.0, 0.12)


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
		if restart and not _stats.get("first_run", false):
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
	if _layout.pointer(event):
		accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		var at := (motion.position - _offset) / _ui
		_hover = 0 if _base_button.has_point(at) else (1 if _button.has_point(at) else -1)
	var button := event as InputEventMouseButton
	if button != null and button.pressed:
		if button.button_index == MOUSE_BUTTON_LEFT:
			if not _report.is_empty() and _retry_button.has_point((button.position - _offset) / _ui):
				_retry_save()
			elif not _report.is_empty() and _journal_button.has_point((button.position - _offset) / _ui):
				_toggle_journal()
			elif _base_button.has_point((button.position - _offset) / _ui):
				_activate()
			elif _button.has_point((button.position - _offset) / _ui):
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
	var command := _choice_input.read(event)
	if command in ["left", "right"] or event is InputEventKey and event.pressed and event.keycode in [KEY_LEFT, KEY_RIGHT]:
		_reveal = true
	if event is InputEventJoypadMotion and command != "":
		match command:
			"left": _selected = 0
			"right": _selected = 1
			"up": _scroll = maxf(_scroll - 33.0, 0.0)
			"down": _scroll = minf(_scroll + 33.0, _scroll_max)
		queue_redraw()
		get_viewport().set_input_as_handled()
		return
	var pad := event as InputEventJoypadButton
	if pad != null and pad.pressed:
		if command == "":
			return
		_hover = -1
		match pad.button_index:
			JOY_BUTTON_DPAD_LEFT: _selected = 0
			JOY_BUTTON_DPAD_RIGHT: _selected = 1
			JOY_BUTTON_A, JOY_BUTTON_START: _activate(_selected == 1)
			JOY_BUTTON_X: _activate(true)
			JOY_BUTTON_B: _activate(false)
			JOY_BUTTON_DPAD_UP: _scroll = maxf(_scroll - 33.0, 0.0)
			JOY_BUTTON_DPAD_DOWN: _scroll = minf(_scroll + 33.0, _scroll_max)
			JOY_BUTTON_BACK: if not _report.is_empty(): _toggle_journal()
			JOY_BUTTON_Y: if not _report.is_empty(): _retry_save()
		queue_redraw()
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	var code := key.keycode
	if key.physical_keycode in [KEY_R, KEY_S]:
		code = key.physical_keycode
	if key.physical_keycode == KEY_J:
		code = KEY_J
	if code not in [KEY_R, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_LEFT, KEY_RIGHT, KEY_DOWN, KEY_UP, KEY_PAGEDOWN, KEY_PAGEUP, KEY_S, KEY_J]:
		return
	get_viewport().set_input_as_handled()
	if key.echo:
		return
	_hover = -1
	match code:
		KEY_S: if not _report.is_empty(): _retry_save()
		KEY_J: if not _report.is_empty(): _toggle_journal()
		KEY_R: _activate(true)
		KEY_LEFT: _selected = 0
		KEY_RIGHT: _selected = 1
		KEY_DOWN, KEY_PAGEDOWN: _scroll = minf(_scroll + 33.0, _scroll_max)
		KEY_UP, KEY_PAGEUP: _scroll = maxf(_scroll - 33.0, 0.0)
		_: _activate(_selected == 1)
	queue_redraw()


func _toggle_journal() -> void:
	_journal = not _journal
	_scroll = 0.0
	if sfx != null:
		sfx.play("ui/click")


func _icon(icon_name: String) -> Texture2D:
	if not _icons.has(icon_name):
		_icons[icon_name] = PixelArt.tex(icon_name)
	return _icons[icon_name]


## Значок HUD по центру точки (единицы экрана), масштаб — целое число пикселей арта на пиксель игры.
func _icon_at(icon_name: String, center: Vector2, color: Color, scale := 1.0) -> void:
	var tex := _icon("hud_" + icon_name)
	var size := tex.get_size() * scale
	draw_texture_rect(tex, Rect2((center - size * 0.5).round(), size), false, color)


## Сколько показать у числа, которое считается от start за span секунд.
func _counted(value: int, start: float, span: float) -> int:
	return roundi(value * clampf((_t - start) / span, 0.0, 1.0))


func _draw() -> void:
	if not visible:
		return
	_ui = SettingsLayout.scale_for(size)
	var virtual_view := _layout.view(size, Vector2(560 if _stats.get("endless", false) else 284, 340), _ui)
	_offset = _layout.offset
	draw_set_transform(_offset, 0.0, Vector2(_ui, _ui))
	var view := virtual_view
	var panel := Rect2((view - Vector2(260.0, 316.0)) * 0.5, Vector2(260.0, 316.0))
	if _stats.get("endless", false):
		panel.position.x = (view.x - 536.0) * 0.5
	if not _report.is_empty():
		panel.position.x = (view.x - 536.0) * 0.5
	var p := panel.position
	var font := Style.BODY_FONT
	var victory: bool = _stats.get("victory", false)
	var accent := Style.BETTER if victory else Style.SELECTED
	draw_rect(Rect2(Vector2.ZERO, view), Color(Style.RECESS, 0.96))
	Style.cloth(self, panel)
	Style.reward(self, Rect2(p + Vector2(12, 218), Vector2(236, 42)), 1.0)
	_text_c(font, p + Vector2(130, 24), "ОПЕРАЦИЯ ВЫПОЛНЕНА" if victory else "ОПЕРАТИВНИК ЭВАКУИРОВАН", accent, 12)
	if _stats.get("endless", false):
		_draw_endless_record(font, p + Vector2(276, 0))
	_draw_receipt(font, p)
	_base_button = Rect2(p + Vector2(12, 274), Vector2(116, 24))
	_button = Rect2(p + Vector2(134, 274), Vector2(114, 24))
	if _reveal:
		_layout.reveal((_base_button if _selected == 0 else _button).grow(4))
		_reveal = false
	for i in 2:
		var r := _base_button if i == 0 else _button
		var hot := _hover == i or (_hover < 0 and _selected == i)
		var c := GOLD if i == 0 else WHITE
		Style.surface(self, r, Style.State.SELECTED if hot else Style.State.NORMAL)
		var label := "НА БАЗУ" if i == 0 else "ЕЩЁ РАЗ [R]"
		if not _report.is_empty():
			label = "К КАРТЕ ОПЕРАЦИЙ" if i == 0 else "БАЗА"
		_text_c(font, r.get_center() + Vector2(0, 4), label, c, 8 if not _report.is_empty() else 10)
	if not _finished:
		_text_c(font, p + Vector2(130, 309), "Ⓐ" if ChoiceInput.pad_mode else "Enter — пропустить", MUTED, 8)
	if not _report.is_empty():
		_draw_consequences(font, Rect2(p + Vector2(272, 0), Vector2(264, 316)))


func _retry_save() -> void:
	Meta.save()
	_report["save_error"] = "" if Meta.last_save_ok else Meta.last_error
	queue_redraw()


## Последствия для карты: 2–3 главных изменения регионов крупными числами, ульи и критические регионы значками;
## полный журнал — по кнопке «Журнал [J]».
func _draw_consequences(font: Font, panel: Rect2) -> void:
	var p := panel.position
	Style.cloth(self, panel)
	_text(font, p + Vector2(14, 24), "ПОСЛЕДСТВИЯ", GOLD, 14)
	_journal_button = Rect2(p + Vector2(14, 246), Vector2(236, 18))
	if _journal:
		_draw_journal(font, Rect2(p + Vector2(14, 34), Vector2(236, 206)))
	else:
		var y := 40.0
		for event: String in _report.get("events", []):
			y = _draw_event(font, p + Vector2(14, y), event)
		# ульи и критические регионы — значок и число
		draw_line(p + Vector2(14, 201), p + Vector2(250, 201), Color(GOLD, 0.3))
		_icon_at("skull", p + Vector2(24, 217), GOLD, 1.0)
		_text(font, p + Vector2(36, 224), str(int(_report.get("nests_alive", 0))), GOLD, 15)
		_icon_at("alarm", p + Vector2(132, 217), HP_RED, 1.0)
		_text(font, p + Vector2(146, 224), str(int(_report.get("critical", 0))), WHITE, 15)
	Style.surface(self, _journal_button, Style.State.NORMAL)
	_text_c(font, _journal_button.get_center() + Vector2(0, 3), ("К ИТОГАМ [Back]" if _journal else "ЖУРНАЛ [Back]") if ChoiceInput.pad_mode else ("К ИТОГАМ [J]" if _journal else "ЖУРНАЛ [J]"), MUTED, 8)
	_retry_button = Rect2()
	if not str(_report.get("save_error", "")).is_empty():
		_text(font, p + Vector2(14, 285), "НЕТ ЗАПИСИ НА ДИСК. Прогресс в памяти.", Style.DANGER, 8)
		_retry_button = Rect2(p + Vector2(14, 291), Vector2(236, 18))
		draw_rect(_retry_button, Style.HOVER)
		_text_c(font, _retry_button.get_center() + Vector2(0, 3), "ПОВТОРИТЬ СОХРАНЕНИЕ [Y]" if ChoiceInput.pad_mode else "ПОВТОРИТЬ СОХРАНЕНИЕ [S]", GOLD, 8)


## Событие «Регион: 62 → 48 · Стадия»: название, крупная динамика (падение заражения — зелёным), стадия справа.
## Строки другого вида выводятся как есть. Возвращает следующую y.
func _draw_event(font: Font, at: Vector2, event: String) -> float:
	var parts := event.split(": ", true, 1)
	var numbers: RegExMatch = null
	if parts.size() == 2:
		numbers = RegEx.create_from_string("^(\\d+) → (\\d+)(?: · (.+))?$").search(parts[1])
	if numbers == null:
		var y := at.y
		for line in _wrap_words(font, event, 234, 10):
			_text(font, Vector2(at.x, y + 10), line, WHITE, 10)
			y += 13
		return y + 8
	var before := int(numbers.get_string(1))
	var after := int(numbers.get_string(2))
	var col := GREEN if after < before else (RED_UP if after > before else MUTED)
	_text(font, at + Vector2(0, 10), parts[0], WHITE, 10)
	_text(font, at + Vector2(0, 31), "%d → %d" % [before, after], col, 16)
	if numbers.get_string(3) != "":
		_text_r(font, at + Vector2(236, 31), numbers.get_string(3), MUTED, 8)
	return at.y + 48.0


## Полный журнал: все изменения регионов с причинами, колесо и стрелки листают.
func _draw_journal(font: Font, area: Rect2) -> void:
	var lines: Array = []
	for change: Dictionary in _report.get("changes", []):
		lines.append([str(change["name"]) + ": %d → %d" % [int(change["from"]), int(change["to"])], WHITE, 9])
		for cause: String in change["causes"]:
			for part in _wrap_words(font, cause, 226, 8):
				lines.append(["  " + part, MUTED, 8])
	var row := 10.0
	_scroll_max = maxf(0.0, lines.size() * row - area.size.y)
	_scroll = minf(_scroll, _scroll_max)
	var y := area.position.y + 9.0 - _scroll
	for line: Array in lines:
		if y - 8.0 >= area.position.y and y + 2.0 <= area.end.y:
			_text(font, Vector2(area.position.x, y), str(line[0]), line[1], int(line[2]))
		y += row


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


## Чек без слов: крупные «убито» и «время», плашки значок+число, стволы иконками, ДНК значками и итог.
func _draw_endless_record(font: Font, p: Vector2) -> void:
	Style.cloth(self, Rect2(p, Vector2(260, 316)))
	var record: Dictionary = _stats.get("endless_record", {})
	var new_time: bool = record.get("time", false)
	var new_kills: bool = record.get("kills", false)
	var map := str(_stats.get("map_id", ""))
	var kind := str(_stats.get("class_id", ""))
	var best := Meta.endless_best(map, kind)
	var label := "НОВЫЙ РЕКОРД" if new_time or new_kills else "БЕСКОНЕЧНАЯ БОЙНЯ"
	_text_c(font, p + Vector2(130, 25), label, GREEN if new_time or new_kills else WHITE, 14)
	var index := Meta.ENDLESS_MAPS.find(map)
	_text(font, p + Vector2(16, 49), Meta.ENDLESS_MAP_NAMES[index] if index >= 0 else map, WHITE, 13)
	var class_index := ClassTree.CLASSES.find(kind)
	_text(font, p + Vector2(16, 65), ["Штурмовик", "Пулемётчик", "Инженер"][class_index] if class_index >= 0 else kind, MUTED, 10)
	for i in 2:
		var y := 82.0 + i * 80.0
		if (new_time if i == 0 else new_kills):
			Style.reward(self, Rect2(p + Vector2(12, y), Vector2(236, 67)), minf(_t, 1.0))
		_icon_at("clock" if i == 0 else "skull", p + Vector2(29, y + 32), GOLD, 2.0)
		_text(font, p + Vector2(50, y + 17), ("ВРЕМЯ" if i == 0 else "УБИЙСТВА") + (" · РЕКОРД" if (new_time if i == 0 else new_kills) else " · ЛУЧШЕЕ"), MUTED, 8)
		var value := int(best["time"] if i == 0 else best["kills"])
		_text(font, p + Vector2(50, y + 41), "%d:%02d" % [value / 60, value % 60] if i == 0 else str(value), WHITE, 24)
		var old := int(record.get("previous_time" if i == 0 else "previous_kills", 0))
		_text(font, p + Vector2(50, y + 57), "Прежний: " + ("%d:%02d" % [old / 60, old % 60] if i == 0 else str(old)), MUTED, 8)
	for i in 3:
		var at := p + Vector2(26 + i * 78, 262)
		var reached: bool = int(best["time"]) >= Meta.ENDLESS_MILESTONES[i]
		_icon_at("star", at, GOLD if reached else Style.DISABLED, 2.0)
		_text(font, at + Vector2(12, 4), "%d мин" % (Meta.ENDLESS_MILESTONES[i] / 60), WHITE if reached else Style.DISABLED, 10)
	_text_c(font, p + Vector2(130, 295), "Рекорды записаны" if Meta.last_save_ok else "Нет записи на диск. Рекорд в памяти.", MUTED if Meta.last_save_ok else RED, 8)


func _draw_receipt(font: Font, p: Vector2) -> void:
	var seconds := maxi(0, int(_stats.get("time", 0.0)))
	var kills := _counted(int(_stats.get("kills", 0)), 0.0, HERO_TIME)
	var shown := _counted(seconds, 0.0, HERO_TIME)
	for k in 2:
		var tile := Rect2(p + Vector2(12 + k * 122, 36), Vector2(114, 42))
		draw_rect(tile, ICON_BG)
		_icon_at("skull" if k == 0 else "clock", tile.position + Vector2(18, 21), GOLD if k == 0 else WHITE, 2.0)
		var value := str(kills) if k == 0 else "%d:%02d" % [shown / 60, shown % 60]
		_text_r(font, tile.position + Vector2(108, 31), value, WHITE, 22)
	# плашки: элитки, лучшая серия, кровь, ящики и военные ящики
	var chips: Array = [
		["star", Style.ACTION, str(_stats.get("elites", 0))], ["flame", Style.SELECTED, str(_stats.get("best_combo", 0))],
		["drop", BLOOD, "%.1f" % float(_stats.get("blood_liters", 0.0))], ["crate", GOLD, str(_stats.get("crates", 0))],
		["crate", GREEN, str(_stats.get("military_crates", 0))],
	]
	for i in chips.size():
		if _t < CHIP_AT + i * CHIP_STEP:
			break
		var chip: Array = chips[i]
		var r := Rect2(p + Vector2(12 + i * 48, 86), Vector2(44, 18))
		draw_rect(r, ICON_BG)
		if i >= 3:
			var crate := _icon("military_crate" if i == 4 else "weapon_crate")
			draw_texture_rect(crate, Rect2(r.position + Vector2(2, 2), Vector2(16, 14)), false)
		else:
			_icon_at(chip[0], r.position + Vector2(10, 9), chip[1])
		_text_r(font, r.position + Vector2(41, 13), str(chip[2]), WHITE, 10)
	_draw_guns(font, p + Vector2(12, 112))
	draw_line(p + Vector2(12, 188), p + Vector2(248, 188), Color(GOLD, 0.25))
	# ДНК: слагаемые значками, множители, итог
	var lines := _dna_lines()
	var x := 12.0
	for i in lines.size():
		if _t < DNA_AT + i * DNA_STEP:
			break
		var label := str(lines[i][0])
		var icon_name := "clock" if label.begins_with("Время") else ("skull" if label.begins_with("Убийства") else ("star" if label.begins_with("Элитки") else "dna"))
		var value := "+" + str(int(lines[i][1]))
		_icon_at(icon_name, p + Vector2(x + 5, 202), MUTED)
		_text(font, p + Vector2(x + 13, 206), value, WHITE, 9)
		x += 18.0 + _width(font, value, 9)
	var factors := multiplier_text()
	if not factors.is_empty() and _t >= DNA_AT + lines.size() * DNA_STEP:
		var pop := clampf((_t - DNA_AT - lines.size() * DNA_STEP) / 0.12, 0.0, 1.0)
		_text_r(font, p + Vector2(248, 207), factors, Color(GOLD, pop), 12)
		_icon_at("star", p + Vector2(240 - _width(font, factors, 12), 203), Color(GOLD, pop), 1.0)
	_icon_at("dna", p + Vector2(28, 238), GREEN, 2.0)
	_text(font, p + Vector2(170, 231), "ДНК", GREEN, 10)
	var total := _counted(int(_stats.get("dna_total", 0)), _total_at(), TOTAL_TIME)
	_text(font, p + Vector2(48, 244), str(total), GOLD, 26)
	if _t >= _duration():
		_text_r(font, p + Vector2(248, 248), "всего %d" % int(_stats.get("dna_bank", 0)), MUTED, 8)

	_text(font, p + Vector2(12, 269), "ПОДГОТОВКА · ур. %d → %d" % [int(_stats.get("class_before", 1)), int(_stats.get("class_after", 1))], GREEN, 8)


## Стволы забега иконками: ствол, уровень и значок патронов с рангом; до четырёх, сеткой 2×2.
func _draw_guns(font: Font, origin: Vector2) -> void:
	var guns: Array = _stats.get("guns", [])
	for i in mini(guns.size(), 4):
		if _t < GUN_AT + i * 0.1:
			break
		var gun: Array = guns[i] # [модель, уровень, патроны, ранг патронов]
		var at := origin + Vector2((i % 2) * 120, (i / 2) * 34)
		draw_rect(Rect2(at, Vector2(116, 32)), ICON_BG)
		var tex := Progression.card_icon("gun_" + str(gun[0]))
		var k := GUN_K
		while tex.get_width() * k > 66.0:
			k -= 1.0 / 3.0
		var size := tex.get_size() * k
		draw_texture_rect(tex, Rect2((at + Vector2(3, 16) - Vector2(0, size.y * 0.5)).round(), size), false, Color.WHITE)
		_text(font, at + Vector2(73, 13), "ур. %d" % int(gun[1]), WHITE, 9)
		var ammo := Progression.card_icon("card_ammo_%d" % int(gun[2]))
		draw_texture_rect(ammo, Rect2(at + Vector2(73, 17), ammo.get_size() * 0.5), false, Color.WHITE)
		for r in int(gun[3]):
			draw_rect(Rect2(at + Vector2(89 + r * 4, 25), Vector2(3, 3)), GOLD)


## Итоговый коэффициент уже включает операцию; награды не пересчитываем.
func multiplier_text() -> String:
	var victory: bool = _stats.get("victory", false)
	var operation := float(_stats.get("reward", {}).get("dna_mul", 1.0)) if victory and not _report.is_empty() else 1.0
	var base := float(_stats.get("dna_mult", 1.0)) / operation
	var parts: Array[String] = []
	if base > 1.0:
		parts.append("×" + String.num(base, 2).replace(".", ","))
	if operation > 1.0:
		parts.append("×" + String.num(operation, 2).replace(".", ","))
	return " · ".join(parts)


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
	font = Style.TITLE_FONT if fs >= 12 else Style.BODY_FONT
	return font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(fs * _ui)).x / _ui


func _text(font: Font, p: Vector2, value: String, color: Color, fs: int) -> void:
	font = Style.TITLE_FONT if fs >= 12 else Style.BODY_FONT
	var k := int(_ui)
	draw_set_transform(_offset)
	draw_string(font, p * _ui, value, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(fs * _ui), color)
	draw_set_transform(_offset, 0.0, Vector2(_ui, _ui))


func _text_r(font: Font, p: Vector2, value: String, color: Color, fs: int) -> void:
	_text(font, p - Vector2(_width(font, value, fs), 0), value, color, fs)


func _text_c(font: Font, p: Vector2, value: String, color: Color, fs: int) -> void:
	_text(font, p - Vector2(_width(font, value, fs) * 0.5, 0), value, color, fs)


