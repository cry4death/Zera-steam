class_name SettingsLayout
extends RefCounted
## Масштаб интерфейса непрерывный; шрифты растрируются в физических пикселях.

static func scale_for(view: Vector2) -> float:
	return maxf(1.0, minf(view.x / 640.0, view.y / 360.0)) * float(Meta.settings["ui_scale"])

static func fit_scale(view: Vector2, content: Vector2) -> float:
	return minf(scale_for(view), minf(view.x / content.x, view.y / content.y))

static func columns(view: Vector2, factor: float, width: float, gap: float, count: int) -> int:
	return clampi(floori((view.x / factor - 38 + gap) / (width + gap)), 1, maxi(1, count))


class Scroll extends RefCounted:
	var horizontal := HScrollBar.new()
	var vertical := VScrollBar.new()
	var offset := Vector2.ZERO
	var _owner: Control
	var _scale := 1.0
	var _view := Vector2.ZERO

	func _init(owner: Control) -> void:
		_owner = owner
		for bar: ScrollBar in [horizontal, vertical]:
			bar.focus_mode = Control.FOCUS_NONE
			bar.process_mode = Node.PROCESS_MODE_ALWAYS
			owner.add_child(bar)
			bar.value_changed.connect(func(_value: float) -> void: owner.queue_redraw())
			bar.hide()

	func view(viewport: Vector2, minimum: Vector2, factor: float) -> Vector2:
		# До первой раскладки Control и headless-стенды могут дать пустую область.
		viewport = viewport.max(Vector2(32, 32))
		minimum = minimum.max(Vector2(320, 180))
		_scale = factor
		_view = viewport
		horizontal.visible = minimum.x * factor > viewport.x
		vertical.visible = minimum.y * factor > viewport.y
		# Одна полоса может вызвать переполнение по второй оси.
		horizontal.visible = minimum.x * factor > viewport.x - (14 if vertical.visible else 0)
		vertical.visible = minimum.y * factor > viewport.y - (14 if horizontal.visible else 0)
		var available := viewport - Vector2(14 if vertical.visible else 0, 14 if horizontal.visible else 0)
		var content := (available / factor).max(minimum)
		horizontal.position = Vector2(0, viewport.y - 14)
		horizontal.size = Vector2(available.x, 14)
		vertical.position = Vector2(viewport.x - 14, 0)
		vertical.size = Vector2(14, available.y)
		horizontal.max_value = content.x * factor
		horizontal.page = available.x
		vertical.max_value = content.y * factor
		vertical.page = available.y
		if not horizontal.visible:
			horizontal.value = 0
		if not vertical.visible:
			vertical.value = 0
		offset = -Vector2(horizontal.value, vertical.value).round()
		return content

	func pointer(event: InputEvent) -> bool:
		var wheel := event as InputEventMouseButton
		if wheel == null or not wheel.pressed:
			return false
		var step := 1 if wheel.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT] else -1
		if wheel.button_index not in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
			return false
		var bar: ScrollBar = horizontal if wheel.shift_pressed or wheel.button_index in [MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT] else vertical
		if not bar.visible:
			bar = horizontal
		if not bar.visible:
			return false
		bar.value += step * 36 * _scale
		return true

	func reveal(rect: Rect2) -> void:
		var start := rect.position * _scale
		var end := rect.end * _scale
		for axis in 2:
			var bar: ScrollBar = horizontal if axis == 0 else vertical
			if not bar.visible:
				continue
			var value := bar.value
			if end[axis] > value + bar.page:
				value = end[axis] - bar.page + 8
			if start[axis] < value:
				value = start[axis] - 8
			bar.value = value
