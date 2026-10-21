class_name SettingsBindings
extends RefCounted
## Единый источник назначений: физическая клавиша или кнопка мыши; оси геймпада сохраняются.

const ACTIONS := ["move_up", "move_down", "move_left", "move_right", "grenade", "dash", "reload", "aim_override", "fire", "pause", "interact", "intro_skip"]
const LABELS := ["Вперёд", "Назад", "Влево", "Вправо", "Способность / граната", "Рывок", "Перезарядка", "Свой прицел", "Огонь", "Пауза", "Взаимодействие", "Пропустить вводную"]
const PAD := ["LS ↑", "LS ↓", "LS ←", "LS →", "RB", "A", "X", "RS", "RT", "Start", "A", "Back"]
const DEFAULTS := {"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "grenade": [KEY_Q, KEY_G, -MOUSE_BUTTON_MIDDLE], "dash": [KEY_SPACE, KEY_SHIFT], "reload": [KEY_R], "aim_override": [-MOUSE_BUTTON_RIGHT], "fire": [-MOUSE_BUTTON_LEFT], "pause": [KEY_ESCAPE], "interact": [KEY_E], "intro_skip": [KEY_TAB]}

static func defaults() -> Dictionary:
	return DEFAULTS.duplicate(true)

static func valid(code: Variant) -> bool:
	return (code is int or code is float) and is_finite(float(code)) and float(code) == int(code) and ((int(code) > 0 and int(code) < KEY_UNKNOWN) or (int(code) <= -1 and int(code) >= -9))

static func clean(value: Variant) -> Dictionary:
	var result := defaults()
	if not value is Dictionary:
		return result
	for action: String in ACTIONS:
		if not value.get(action) is Array or value[action].is_empty():
			continue
		var codes: Array = []
		for code: Variant in value[action]:
			if valid(code) and not codes.has(int(code)) and codes.size() < 3:
				codes.append(int(code))
		if not codes.is_empty():
			result[action] = codes
	return result

static func code(event: InputEvent) -> int:
	if event is InputEventKey:
		return event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if event is InputEventMouseButton:
		return -event.button_index
	return 0

static func label(value: int) -> String:
	if value < 0:
		return {1: "ЛКМ", 2: "ПКМ", 3: "СКМ", 4: "Колесо ↑", 5: "Колесо ↓", 6: "Колесо ←", 7: "Колесо →", 8: "Мышь 4", 9: "Мышь 5"}.get(-value, "Мышь")
	return OS.get_keycode_string(value)

static func hint(action: String) -> String:
	var meta: Node = (Engine.get_main_loop() as SceneTree).root.get_node("Meta")
	var codes: Array = meta.settings["bindings"].get(action, [])
	return label(int(codes[0])) if not codes.is_empty() else "—"

static func movement_hint() -> String:
	return " ".join([hint("move_up"), hint("move_left"), hint("move_down"), hint("move_right")])

static func conflicts(bindings: Dictionary, action: String, value: int) -> Array[String]:
	var result: Array[String] = []
	for other: String in ACTIONS:
		if other != action and bindings[other].has(value):
			result.append(other)
	return result

static func rebind(bindings: Dictionary, action: String, slot: int, value: int) -> Dictionary:
	var result := clean(bindings)
	if not ACTIONS.has(action) or not valid(value) or slot < 0 or slot >= result[action].size():
		return result
	var old: int = result[action][slot]
	# Обмен оставляет каждое действие доступным, в том числе при замене единственной кнопки.
	for other: String in conflicts(result, action, value):
		var at: int = result[other].find(value)
		result[other][at] = old
		if result[other].count(old) > 1:
			result[other].remove_at(at)
	var existing: int = result[action].find(value)
	if existing >= 0 and existing != slot:
		result[action][existing] = old
	result[action][slot] = value
	return result

static func apply(bindings: Dictionary) -> void:
	# Сначала создаём штатные оси/кнопки, затем меняем только клавиатуру и мышь.
	load("res://scripts/game.gd")._setup_input()
	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")
		var start := InputEventJoypadButton.new()
		start.button_index = JOY_BUTTON_START
		InputMap.action_add_event("pause", start)
	for action: String in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey or event is InputEventMouseButton:
				InputMap.action_erase_event(action, event)
		for value: int in bindings[action]:
			var event: InputEvent
			if value > 0:
				event = InputEventKey.new()
				event.physical_keycode = value
			else:
				event = InputEventMouseButton.new()
				event.button_index = -value
			InputMap.action_add_event(action, event)
