class_name ChoiceInput
extends RefCounted
## Один переход на отклонение стика; новое нажатие после отпускания.

static var pad_mode := false
var _stick := Vector2i.ZERO
var _held := PackedInt32Array()


func read(event: InputEvent) -> String:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		pad_mode = false
	var button := event as InputEventJoypadButton
	if button != null:
		pad_mode = true
		var id := int(button.button_index)
		if not button.pressed:
			_held.erase(id)
			return ""
		if _held.has(id):
			return ""
		_held.append(id)
		match id:
			JOY_BUTTON_A: return "accept"
			JOY_BUTTON_B: return "cancel"
			JOY_BUTTON_X: return "reroll"
			JOY_BUTTON_START: return "pause"
			JOY_BUTTON_LEFT_SHOULDER: return "prev_tab"
			JOY_BUTTON_RIGHT_SHOULDER: return "next_tab"
			JOY_BUTTON_Y: return "alternate"
			JOY_BUTTON_BACK: return "journal"
			JOY_BUTTON_DPAD_LEFT: return "left"
			JOY_BUTTON_DPAD_RIGHT: return "right"
			JOY_BUTTON_DPAD_UP: return "up"
			JOY_BUTTON_DPAD_DOWN: return "down"
	var axis := event as InputEventJoypadMotion
	if axis != null and absf(axis.axis_value) > 0.22:
		pad_mode = true
	if axis != null and axis.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var horizontal := axis.axis == JOY_AXIS_LEFT_X
		var old := _stick.x if horizontal else _stick.y
		var value := 0 if absf(axis.axis_value) < 0.55 else (1 if axis.axis_value > 0.0 else -1)
		if horizontal:
			_stick.x = value
		else:
			_stick.y = value
		if value == 0 or value == old:
			return ""
		pad_mode = true
		return ("right" if value > 0 else "left") if horizontal else ("down" if value > 0 else "up")
	return ""
