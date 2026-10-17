class_name AlarmOverlay
extends Control
## Кровавая тревога: сирена, двойное сердцебиение и затухание результата.

enum Phase { IDLE, WARN, ACTIVE, FINISH }

const TITLE := "КРОВАВАЯ ТРЕВОГА"
const RESULT := "ТРЕВОГА ОТБИТА"
const BONUS := "опыт и кредиты x2"
const ENTER_TIME := 0.25
const EXIT_TIME := 0.4
const FINISH_TIME := 1.5
const FLASH_TIME := 0.3
const CENTER_FLASH_ALPHA := 30.0 / 255.0 # не выше 0.12 после округления RGBA8
const STRIPE_HEIGHT := 7.0
const STRIPE_PERIOD := 32.0
const GOLD := Color(1.0, 0.82, 0.35)
const RED := Color(0.55, 0.0, 0.02)

@export var reduced_motion := false

var _phase: Phase = Phase.IDLE
var _remaining := 0.0
var _duration := 0.0
var _elapsed := 0.0
var _heartbeat_phase := 0.0
var _edge_alpha := 0.0
var _finish_edge := 0.0
var _flash_alpha := 0.0
var _stripe_amount := 0.0
var _stripe_exit_from := 1.0
var _stripe_offset := 0.0
var _blink := true
var _shown_seconds := -1
var _detail := ""
var _detail_width := 0.0
var _title_width := 0.0
var _active_title_width := 0.0
var _result_width := 0.0
var _ui := 3.0
var _font: Font
var _vignette: ImageTexture
var _stripes: GradientTexture2D


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	process_mode = Node.PROCESS_MODE_PAUSABLE # слой меню может работать на паузе
	clip_contents = true
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_font = ThemeDB.fallback_font
	_title_width = _font.get_string_size(TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	_active_title_width = _font.get_string_size(TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	_result_width = _font.get_string_size(RESULT, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	_make_textures()
	visible = false
	set_process(false)
	resized.connect(_on_resized)
	if _phase != Phase.IDLE:
		visible = true
		set_process(true)
		_update_detail()


func warn(seconds: float) -> void:
	if seconds <= 0.0 or not is_finite(seconds):
		stop()
		return
	_begin(Phase.WARN, seconds)
	_update_visuals(0.0)
	queue_redraw()


func start(seconds: float) -> void:
	if seconds <= 0.0 or not is_finite(seconds):
		stop()
		return
	_stripe_exit_from = _stripe_amount if _phase == Phase.WARN else 1.0
	_begin(Phase.ACTIVE, seconds)
	_update_visuals(0.0)
	queue_redraw()


func finish() -> void:
	if _phase == Phase.FINISH:
		return
	_finish_edge = _edge_alpha
	_begin(Phase.FINISH, FINISH_TIME)
	_stripe_amount = 0.0
	_flash_alpha = 0.0
	queue_redraw()


func stop() -> void:
	_phase = Phase.IDLE
	_remaining = 0.0
	_duration = 0.0
	_elapsed = 0.0
	_heartbeat_phase = 0.0
	_edge_alpha = 0.0
	_finish_edge = 0.0
	_flash_alpha = 0.0
	_stripe_amount = 0.0
	_stripe_offset = 0.0
	_shown_seconds = -1
	_detail = ""
	visible = false
	set_process(false)


func is_active() -> bool:
	return _phase == Phase.WARN or _phase == Phase.ACTIVE


func _begin(phase: Phase, seconds: float) -> void:
	_phase = phase
	_duration = seconds
	_remaining = seconds
	_elapsed = 0.0
	_heartbeat_phase = 0.0
	_shown_seconds = -1
	visible = true
	set_process(true)
	_update_detail()


func _process(delta: float) -> void:
	if _phase == Phase.IDLE:
		return
	_elapsed += delta
	_remaining = maxf(_remaining - delta, 0.0)
	if _remaining <= 0.0:
		if _phase == Phase.ACTIVE:
			var overflow := maxf(_elapsed - _duration, 0.0)
			finish()
			_elapsed = minf(overflow, FINISH_TIME)
			_remaining = maxf(FINISH_TIME - overflow, 0.0)
			if _remaining <= 0.0:
				stop()
				return
		else:
			stop() # предупреждение не запускает игровое событие самостоятельно
			return
	_update_visuals(delta)
	_update_detail()
	queue_redraw()


func _update_visuals(delta: float) -> void:
	_flash_alpha = 0.0
	_stripe_offset = 0.0 if reduced_motion else fposmod(_elapsed * 6.0, STRIPE_PERIOD)
	match _phase:
		Phase.WARN:
			_blink = reduced_motion or fposmod(_elapsed, 0.5) < 0.25
			_stripe_amount = 1.0 if reduced_motion else _ease_out(_elapsed / ENTER_TIME)
			var flash := 0.0 if reduced_motion else maxf(1.0 - fposmod(_elapsed, 0.5) / 0.12, 0.0)
			_edge_alpha = 0.14 + flash * 0.3
		Phase.ACTIVE:
			var period := 0.6 if _remaining <= 5.0 else 1.1
			_heartbeat_phase = fposmod(_heartbeat_phase + delta / period, 1.0)
			var beat := maxf(_thump(_heartbeat_phase, 0.1, 0.1), _thump(_heartbeat_phase, 0.3, 0.08) * 0.7)
			_edge_alpha = 0.58 if reduced_motion else 0.46 + beat * 0.24
			_stripe_amount = 0.0 if reduced_motion else _stripe_exit_from * (1.0 - _ease_out(_elapsed / EXIT_TIME))
			if not reduced_motion:
				_flash_alpha = CENTER_FLASH_ALPHA * clampf(1.0 - _elapsed / FLASH_TIME, 0.0, 1.0)
		Phase.FINISH:
			_edge_alpha = _finish_edge * clampf(_remaining / FINISH_TIME, 0.0, 1.0)
			_stripe_amount = 0.0


func _update_detail() -> void:
	if _font == null:
		return
	var seconds := maxi(0, ceili(_remaining))
	if seconds == _shown_seconds:
		return
	_shown_seconds = seconds
	if _phase == Phase.WARN:
		_detail = "через %d" % maxi(1, seconds)
	elif _phase == Phase.ACTIVE:
		_detail = "%s    %d:%02d" % [BONUS, int(seconds / 60.0), seconds % 60]
	else:
		_detail = ""
	_detail_width = _font.get_string_size(_detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x


func _on_resized() -> void:
	if visible:
		queue_redraw()


func _ease_out(t: float) -> float:
	return float(Tween.interpolate_value(0.0, 1.0, clampf(t, 0.0, 1.0), 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT))


func _thump(phase: float, center: float, width: float) -> float:
	var t := maxf(1.0 - absf(phase - center) / width, 0.0)
	return t * t


func _make_textures() -> void:
	# Два краевых спада запекаются один раз: один draw, без плоских углов.
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 0.6625, 0.775, 0.8875, 1.0])
	gradient.colors = PackedColorArray([
		Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.015625),
		Color(0, 0, 0, 0.125), Color(0, 0, 0, 0.421875), Color(0, 0, 0, 1),
	])
	var image := Image.create(1024, 576, false, Image.FORMAT_RGBA8)
	var horizontal := PackedFloat32Array()
	horizontal.resize(1024)
	for x in 1024:
		# В 16:9 ширина спада в пикселях одинакова у всех четырёх краёв.
		var radius := 1.0 - (1.0 - absf(2.0 * float(x) / 1023.0 - 1.0)) * (16.0 / 9.0)
		horizontal[x] = gradient.sample(clampf(radius, 0.0, 1.0)).a
	for y in 576:
		var vertical := gradient.sample(absf(2.0 * float(y) / 575.0 - 1.0)).a
		for x in 1024:
			var side := horizontal[x]
			var corner := side * vertical
			var color := Color(0.35, 0.0, 0.02).lerp(Color(0.12, 0.0, 0.01), corner)
			# При среднем пульсе: 0.40 у середины края, 0.58 в углу.
			color.a = (0.4 * (side + vertical) - 0.22 * corner) / 0.58
			image.set_pixel(x, y, color)
	_vignette = ImageTexture.create_from_image(image)
	var stripes := Gradient.new()
	stripes.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	stripes.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	stripes.colors = PackedColorArray([Color(0.025, 0.015, 0.015), Color(0.48, 0.025, 0.035), Color(0.025, 0.015, 0.015)])
	_stripes = GradientTexture2D.new()
	_stripes.width = int(STRIPE_PERIOD)
	_stripes.height = int(STRIPE_HEIGHT)
	_stripes.gradient = stripes
	_stripes.fill_from = Vector2.ZERO
	_stripes.fill_to = Vector2(0.5, 0.5)
	_stripes.repeat = GradientTexture2D.REPEAT


func _draw() -> void:
	if _phase == Phase.IDLE or _font == null:
		return
	_ui = maxf(1.0, roundf(size.y / 360.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))
	var w := size.x / _ui
	var h := size.y / _ui
	var view := Rect2(0.0, 0.0, w, h)
	draw_texture_rect(_vignette, view, false, Color(1.0, 1.0, 1.0, _edge_alpha))
	if _flash_alpha > 0.0:
		draw_rect(view, Color(RED, _flash_alpha))
	if _stripe_amount > 0.0:
		var top := -STRIPE_HEIGHT * (1.0 - _stripe_amount)
		var bottom := h - STRIPE_HEIGHT * _stripe_amount
		draw_texture_rect(_stripes, Rect2(-_stripe_offset, top, w + STRIPE_PERIOD, STRIPE_HEIGHT), true)
		draw_texture_rect(_stripes, Rect2(_stripe_offset - STRIPE_PERIOD, bottom, w + STRIPE_PERIOD, STRIPE_HEIGHT), true)
	match _phase:
		Phase.WARN:
			if _blink:
				_text(Vector2(w * 0.5, h / 6.0 - 6.0), TITLE, Color(0.83, 0.16, 0.13), 20, _title_width)
			_text(Vector2(w * 0.5, h / 6.0 + 8.0), _detail, Color(0.82, 0.45, 0.4), 10, _detail_width)
		Phase.ACTIVE:
			_text(Vector2(w * 0.5, 45.0), TITLE, Color(0.42, 0.015, 0.025), 16, _active_title_width, Color(0.87, 0.28, 0.22, 0.95))
			var bar_width := minf(160.0, w - 32.0)
			var bar := Rect2((w - bar_width) * 0.5, 52.0, bar_width, 3.0)
			draw_rect(bar.grow(1.0), Color(0.035, 0.01, 0.015, 0.9))
			draw_rect(Rect2(bar.position, Vector2(bar_width * clampf(_remaining / _duration, 0.0, 1.0), bar.size.y)), Color(0.63, 0.065, 0.055))
			_text(Vector2(w * 0.5, 68.0), _detail, Color(0.82, 0.48, 0.42), 10, _detail_width)
		Phase.FINISH:
			var t := clampf(_elapsed / FINISH_TIME, 0.0, 1.0)
			var scale_factor := 1.0 if reduced_motion else lerpf(1.0, 1.04, _ease_out(t))
			_text(Vector2(w * 0.5, h / 6.0 + 5.0), RESULT, Color(GOLD, 1.0 - t), 20, _result_width, Color(0, 0, 0, 0.8 * (1.0 - t)), scale_factor)
	draw_set_transform(Vector2.ZERO)


func _text(p: Vector2, s: String, color: Color, fs: int, width: float,
		outline := Color(0, 0, 0, 0.8), scale_factor := 1.0) -> void:
	# Положение — в игровых пикселях, глифы — в полном разрешении, как в HUD.
	draw_set_transform(p * _ui, 0.0, Vector2.ONE * scale_factor)
	var k := int(_ui)
	var origin := Vector2(-width * 0.5 * _ui, 0.0)
	draw_string_outline(_font, origin, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * k, 2 * k, outline)
	draw_string(_font, origin, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * k, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))


# Ручная проверка: Control со скриптом AlarmOverlay под CanvasLayer.
# В _ready() другой ноды (alarm — ссылка на этот Control):
# alarm.warn(3.0)
# await get_tree().create_timer(3.0).timeout
# alarm.start(30.0)
# await get_tree().create_timer(30.0).timeout
# alarm.finish() # повторный finish во время затухания его не перезапускает
# await get_tree().create_timer(1.5).timeout
# alarm.stop()
# На warn/start/finish включить get_tree().paused = true: время и рисунок замрут.
