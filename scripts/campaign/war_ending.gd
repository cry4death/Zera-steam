class_name WarEnding
extends Control
## Итог завершённой войны: орган затихает, тактическая Земля очищается.

signal base_requested
const Style := preload("res://scripts/ui/zera_style.gd")
var world: Dictionary = {}
var _age := 0.0
var _button: Button
var _losses := 0
var _lost_regions := 0
var _globe: GlobeView
var _infections := PackedFloat32Array()
var _ui_scale := 1.0
var _origin := Vector2.ZERO
var _finished := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for report: Dictionary in world.get("completed_reports", {}).values():
		if report.get("stats", {}).get("outcome") == "defeat":
			_losses += 1
	for region: Dictionary in world.get("regions", {}).values():
		if int(region.get("infection", 0)) >= 80:
			_lost_regions += 1
	_globe = GlobeView.new()
	add_child(_globe)
	_globe.set_active(true)
	_globe.hide()
	_globe.set_process(false)
	_globe.input_enabled = false
	_globe.yaw = -0.7
	_globe.pitch = 0.35
	_globe.zoom = 2.32
	_globe._update_pose()
	for id: String in CampaignCatalog.REGIONS:
		_infections.append(float(world.get("regions", {}).get(id, {}).get("infection", 0)) / 100.0)
	_button = Button.new()
	_button.text = "НА БАЗУ"
	_button.flat = true
	_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_button.add_theme_font_override("font", Style.TITLE_FONT)
	_button.add_theme_color_override("font_color", Style.METAL)
	_button.add_theme_color_override("font_hover_color", Style.METAL)
	_button.add_theme_color_override("font_focus_color", Style.METAL)
	_button.pressed.connect(func() -> void: base_requested.emit())
	_button.visible = false
	add_child(_button)


func _process(delta: float) -> void:
	_age += delta
	_ui_scale = minf(size.x / 640.0, size.y / 360.0)
	_origin = (size - Vector2(640, 360) * _ui_scale) * 0.5
	_button.position = _origin + Vector2(320, 292) * _ui_scale
	_button.size = Vector2(292, 34) * _ui_scale
	_button.add_theme_font_size_override("font_size", roundi(Style.SUBTITLE * _ui_scale))
	var quiet := 1.0 if Meta.settings["reduce_motion"] else clampf((_age - 0.5) / 1.9, 0.0, 1.0)
	if not _finished:
		var clean := PackedFloat32Array()
		for value in _infections:
			clean.append(value * (1.0 - quiet))
		_globe.globe_material.set_shader_parameter("infections", clean)
		_globe.globe_material.set_shader_parameter("hive_alive", false)
		if quiet >= 1.0:
			_finished = true
			_globe.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	if _age >= 2.5 and not _button.visible:
		_button.visible = true
		_button.grab_focus()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Style.METAL)
	draw_set_transform(_origin, 0.0, Vector2.ONE * _ui_scale)
	draw_texture_rect(preload("res://art/ui_steel.png"), Rect2(0, 0, 640, 360), true)
	_label("Z.E.R.A. / КАРАНТИННАЯ СЛУЖБА", Vector2(28, 25), Style.SMALL, Style.MUTED)
	Style.cut_rect(self, Rect2(530, 12, 82, 20), Style.BETTER)
	_label("ПОБЕДА", Vector2(544, 26), Style.SMALL, Style.METAL, true)
	_label("ВОЙНА ОКОНЧЕНА", Vector2(28, 75), Style.TITLE, Style.TEXT, true)
	_label("Сердце Улья уничтожено. Группы возвращаются.", Vector2(28, 96), Style.BODY, Style.MUTED)
	if _globe:
		draw_texture_rect(_globe.viewport.get_texture(), Rect2(28, 101, 250, 250), false)
	var quiet := 1.0 if Meta.settings["reduce_motion"] else clampf(_age / 2.4, 0.0, 1.0)
	if quiet < 1.0:
		draw_texture_rect(PixelArt.tex("boss_heart_dead"), Rect2(54, 216 + 12 * quiet, 202, 70 * (1.0 - quiet * 0.2)), false, Color(0.55, 0.43, 0.37, 1.0 - quiet))
	_label("ИСТОЧНИК ЗАРАЖЕНИЯ УНИЧТОЖЕН", Vector2(29, 342), Style.SMALL, Style.BETTER)
	Style.cloth(self, Rect2(308, 115, 304, 161))
	var war: Dictionary = world.get("war", {})
	var values := [int(world.get("turn", 0)), war.get("outposts", []).size(), war.get("samples", []).size(), _losses, _lost_regions]
	var labels := ["ХОДОВ", "ФОРПОСТЫ", "ОБРАЗЦЫ", "ПРОВАЛЫ", "РЕГИОНОВ ПОТЕРЯНО"]
	for k in 5:
		var at := Vector2(324 + (k % 3) * 96, 157 + (k / 3) * 77)
		_label(str(values[k]), at, Style.NUMBER, Style.TEXT, true)
		_label(labels[k], at + Vector2(0, 19), Style.SMALL, Style.MUTED)
	if _button and _button.visible:
		Style.cut_rect(self, Rect2(320, 292, 292, 34), Style.ACTION.lightened(0.1) if _button.is_hovered() else Style.ACTION)
		if _button.has_focus():
			draw_rect(Rect2(320, 292, 3, 34), Style.TEXT)
	draw_set_transform(Vector2.ZERO)


func _label(value: String, at: Vector2, pixels: int, color: Color, title: bool = false) -> void:
	draw_string(Style.TITLE_FONT if title else Style.BODY_FONT, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, color)
