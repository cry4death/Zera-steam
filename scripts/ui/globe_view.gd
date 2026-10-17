class_name GlobeView
extends Control
## Изолированный 3D-дисплей; ввод и карточки принадлежат базе.

signal region_selected(id: String)

const COLORS := [Color("7da38c"), Color("c6b965"), Color("d58a4b"), Color("e04643"), Color("712d42")]
const SHADER := """
shader_type spatial;
render_mode specular_disabled;
uniform sampler2D land : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 centers[8];
uniform vec4 zones[8];
uniform float motion_time = 0.0;
uniform vec3 hive_center;
uniform bool hive_alive = true;
varying vec3 local_point;
void vertex() { local_point = VERTEX; }
void fragment() {
    vec3 n = normalize(local_point);
    vec2 uv = vec2((atan(n.x, n.z) + PI) / (2.0 * PI), 0.5 - asin(n.y) / PI);
    vec3 base = texture(land, uv).rgb;
    vec3 color = base;
    vec3 glow = vec3(0.0);
    for (int i = 0; i < 8; i++) {
        float d = dot(n, centers[i]);
        float area = smoothstep(0.975, 0.999, d);
        float pulse = zones[i].a > 0.5 ? 0.9 + 0.1 * sin(motion_time * 3.5) : 1.0;
        color = mix(color, zones[i].rgb * 0.62, area * 0.78 * pulse);
        glow += zones[i].rgb * area * 0.12 * pulse;
    }
    if (hive_alive) {
        float halo = smoothstep(0.985, 1.0, dot(n, hive_center));
        glow += vec3(0.55, 0.09, 0.25) * halo * (0.75 + 0.15 * sin(motion_time * 2.0));
    }
    ALBEDO = color;
    EMISSION = color * 0.25 + glow;
    ROUGHNESS = 1.0;
}
"""

var viewport: SubViewport
var sphere: MeshInstance3D
var camera: Camera3D
var globe_material: ShaderMaterial
var active := false
var input_enabled := true
var selected := "east_europe"
var filter := 0
var yaw := -0.52
var pitch := 0.48
var zoom := 2.65
var _target := Vector2.ZERO
var _turning := false
var _dragging := false
var _moved := 0.0
var _time := 0.0
var _flash := 0.0
var _changed: Array[String] = []
var _hits: Array[Dictionary] = []
var _regions: Array[Dictionary] = []
var _offers: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	viewport = SubViewport.new()
	viewport.size = Vector2i(768, 768)
	viewport.own_world_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("080d0e")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b3b3b3")
	environment.environment.ambient_light_energy = 0.6
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	viewport.add_child(environment)
	sphere = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 96
	mesh.rings = 48
	sphere.mesh = mesh
	var shader := Shader.new()
	shader.code = SHADER
	globe_material = ShaderMaterial.new()
	globe_material.shader = shader
	globe_material.set_shader_parameter("land", load("res://art/globe_land.png"))
	sphere.material_override = globe_material
	viewport.add_child(sphere)
	camera = Camera3D.new()
	camera.position = Vector3(0, 0, 4)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = zoom
	viewport.add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, -30, 0)
	light.light_color = Color("dce0dc")
	light.light_energy = 1.2
	viewport.add_child(light)
	refresh()
	set_active(false)


static func point(lat: float, lon: float) -> Vector3:
	var a := deg_to_rad(lat)
	var b := deg_to_rad(lon)
	return Vector3(cos(a) * sin(b), sin(a), cos(a) * cos(b))


func refresh() -> void:
	_regions.clear()
	_offers = Campaign.offers()
	var centers := PackedVector3Array()
	var zones := PackedVector4Array()
	for id: String in CampaignCatalog.REGIONS:
		var info := Campaign.region_info(id)
		_regions.append(info)
		centers.append(point(info["lat"], info["lon"]))
		var c: Color = COLORS[int(info["stage"])].srgb_to_linear()
		zones.append(Vector4(c.r, c.g, c.b, 1.0 if int(info["stage"]) >= 3 else 0.0))
	globe_material.set_shader_parameter("centers", centers)
	globe_material.set_shader_parameter("zones", zones)
	globe_material.set_shader_parameter("hive_center", point(52.0, 30.0))
	globe_material.set_shader_parameter("hive_alive", Campaign.world()["nests"]["object_7"]["alive"])


func set_active(value: bool) -> void:
	active = value
	visible = value
	_dragging = false
	set_process(value)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if value else SubViewport.UPDATE_DISABLED


func focus_region(id: String) -> void:
	if not CampaignCatalog.REGIONS.has(id):
		return
	selected = id
	var info: Dictionary = CampaignCatalog.REGIONS[id]
	_target = Vector2(-deg_to_rad(float(info["lon"])), deg_to_rad(float(info["lat"])))
	_turning = true
	if Meta.settings["reduce_motion"]:
		skip_motion()


func skip_motion() -> void:
	if _turning:
		yaw = _target.x
		pitch = _target.y
	_turning = false
	_flash = 0.0
	_update_pose()


func show_changes(report: Dictionary) -> void:
	_changed.clear()
	for change: Dictionary in report.get("changes", []):
		if change["from"] != change["to"]:
			_changed.append(change["region_id"])
	_flash = 3.5 if not Meta.settings["reduce_motion"] else 0.0


func _update_pose() -> void:
	sphere.basis = Basis(Vector3.RIGHT, pitch) * Basis(Vector3.UP, yaw)
	camera.size = zoom


func _process(delta: float) -> void:
	var reduced: bool = Meta.settings["reduce_motion"]
	if not input_enabled:
		_dragging = false
	if not reduced:
		_time += delta
	_flash = maxf(0.0, _flash - delta)
	if input_enabled:
		for device: int in Input.get_connected_joypads():
			var stick := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
			if stick.length() > 0.22:
				yaw += stick.x * delta * 1.5
				pitch = clampf(pitch + stick.y * delta, -1.4, 1.4)
				_turning = false
			var trigger := Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT)
			zoom = clampf(zoom - trigger * delta, 2.25, 3.5)
	if _turning:
		if reduced:
			skip_motion()
		else:
			yaw = lerp_angle(yaw, _target.x, 1.0 - exp(-delta * 7.0))
			pitch = lerpf(pitch, _target.y, 1.0 - exp(-delta * 7.0))
			if absf(angle_difference(yaw, _target.x)) + absf(pitch - _target.y) < 0.002:
				_turning = false
	elif not _dragging and not reduced:
		yaw += delta * 0.018
	_update_pose()
	globe_material.set_shader_parameter("motion_time", 0.0 if reduced else _time)
	queue_redraw()


## Экранная проекция и отсев по нормали, без коллайдеров и физики.
func project_region(id: String) -> Vector2:
	var info: Dictionary = CampaignCatalog.REGIONS[id]
	var p := sphere.basis * point(info["lat"], info["lon"])
	if p.z <= 0.12:
		return Vector2.INF
	var at := camera.unproject_position(p)
	return (at / Vector2(viewport.size) - Vector2(0.5, 0.5)) * _display_side() + size * 0.5


func _display_side() -> float:
	return minf(size.x, size.y)


func pointer(event: InputEvent, at: Vector2) -> bool:
	var button := event as InputEventMouseButton
	if button != null:
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed and Rect2(Vector2.ZERO, size).has_point(at):
				_dragging = true
				_moved = 0.0
				return true
			if not button.pressed and _dragging:
				_dragging = false
				if _moved < 6.0:
					var nearest := ""
					var distance := 12.0 * size.y / 238.0
					for hit: Dictionary in _hits:
						var candidate := at.distance_to(hit["point"])
						if candidate < distance:
							distance = candidate
							nearest = hit["id"]
					if nearest.is_empty():
						for hit: Dictionary in _hits:
							if hit["rect"].has_point(at):
								nearest = hit["id"]
					if not nearest.is_empty():
						region_selected.emit(nearest)
				return true
		if button.pressed and Rect2(Vector2.ZERO, size).has_point(at) and button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			zoom = clampf(zoom + (-0.16 if button.button_index == MOUSE_BUTTON_WHEEL_UP else 0.16), 2.25, 3.5)
			return true
	var motion := event as InputEventMouseMotion
	if motion != null and _dragging:
		_moved += motion.relative.length()
		yaw += motion.relative.x / maxf(size.x, 1.0) * 3.0
		pitch = clampf(pitch + motion.relative.y / maxf(size.y, 1.0) * 2.0, -1.4, 1.4)
		_turning = false
		return true
	return false


func matches_filter(info: Dictionary) -> bool:
	if filter == 1:
		return int(info["stage"]) >= 3
	if filter == 2:
		for op: Dictionary in _offers:
			if op["region_id"] == info["id"] and int(op["threat"]) <= 2:
				return true
		return false
	if filter == 3:
		return not info["nests"].is_empty()
	return true


func _draw() -> void:
	if not active or size.x < 2.0 or size.y < 2.0:
		return
	var k := size.y / 238.0
	var side := _display_side()
	draw_texture_rect(viewport.get_texture(), Rect2((size - Vector2.ONE * side) * 0.5, Vector2.ONE * side), false)
	var center := size * 0.5
	var radius := side / zoom
	draw_arc(center, radius + 4 * k, 0.0, TAU, 96, Color(0.37, 0.45, 0.4, 0.45), k, true)
	for i in 4:
		var direction := Vector2.from_angle(i * PI * 0.5)
		draw_line(center + direction * (radius + 8 * k), center + direction * (radius + 15 * k), Color("71877c"), k)
	_hits.clear()
	var occupied: Array[Rect2] = []
	for info: Dictionary in _regions:
		if not matches_filter(info):
			continue
		var at := project_region(info["id"])
		if not at.is_finite():
			continue
		var number := ""
		var nest := false
		for i in _offers.size():
			if _offers[i]["region_id"] == info["id"]:
				if filter == 2 and int(_offers[i]["threat"]) > 2 or filter == 3 and _offers[i]["type"] != "nest":
					continue
				number += ("/" if not number.is_empty() else "") + str(i + 1)
				nest = nest or _offers[i]["type"] == "nest"
		var c: Color = COLORS[int(info["stage"])]
		var chosen: bool = selected == info["id"]
		var r := 4.0 * k
		var diamond := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r), at + Vector2(-r, 0), at + Vector2(0, -r)])
		draw_colored_polygon(diamond, Color("090d0c"))
		var blink := 1.0 if Meta.settings["reduce_motion"] else 0.8 + 0.2 * sin(_time * 3.0)
		var mark_color := Color(Color.WHITE, blink) if number != "" else c
		if nest:
			var hexagon := PackedVector2Array()
			for corner in 7:
				hexagon.append(at + Vector2.from_angle(corner * TAU / 6.0) * 6 * k)
			draw_polyline(hexagon, Color("e165a0"), 1.5 * k, true)
		elif int(info["stage"]) == 0:
			draw_arc(at, r, 0, TAU, 20, mark_color, k, true)
		elif int(info["stage"]) == 2:
			draw_rect(Rect2(at - Vector2.ONE * r, Vector2.ONE * r * 2), mark_color, false, k)
		elif int(info["stage"]) >= 3:
			# Критический — треугольник; потерянный — разорванный ромб.
			if int(info["stage"]) == 3:
				draw_polyline(PackedVector2Array([at + Vector2(0, -r * 1.3), at + Vector2(r, r), at + Vector2(-r, r), at + Vector2(0, -r * 1.3)]), mark_color, k, true)
			else:
				draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2]]), mark_color, k, true)
				draw_line(diamond[3], diamond[4], mark_color, k, true)
		else:
			draw_polyline(diamond, mark_color, k * (1.5 if chosen else 1.0), true)
		if nest:
			draw_rect(Rect2(at - Vector2.ONE * 2 * k, Vector2.ONE * 4 * k), Color("e165a0"))
		elif int(info["stage"]) >= 3:
			draw_line(at + Vector2(0, -2 * k), at + Vector2(0, 2 * k), c, 2 * k)
		if chosen or (_flash > 0.0 and _changed.has(info["id"])):
			draw_arc(at, 8 * k, 0.0, TAU, 24, Color(0.95, 0.85, 0.57, 0.8), k, true)
		var label := ("[" + number + "] " if number != "" else "") + str(info["name"])
		var font := ThemeDB.fallback_font
		var fs := roundi(7 * k)
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var rect := Rect2(at + Vector2(8 * k, -6 * k), Vector2(width + 6 * k, 12 * k))
		rect.position.x = clampf(rect.position.x, 3 * k, size.x - rect.size.x - 3 * k)
		for attempt in 8:
			var overlap := false
			for other: Rect2 in occupied:
				if rect.intersects(other):
					overlap = true
					break
			if not overlap:
				break
			rect.position.y += 13 * k
		occupied.append(rect)
		draw_line(at, rect.get_center(), Color(c, 0.55), k)
		draw_rect(rect, Color(0.025, 0.04, 0.04, 0.93))
		draw_string(font, rect.position + Vector2(3 * k, 9 * k), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE if chosen or number != "" else c)
		_hits.append({"id": info["id"], "rect": rect, "point": at})
	if _flash > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(8, size.y - 6 * k), "ФРОНТ ОБНОВЛЁН · Esc / B — пропустить", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(7 * k), Color("e4ce87"))


## Сквозная оконная проверка живёт в статическом корутинном вызове между сменами сцен.
static func _check_test(state: Dictionary, name: String, ok: bool) -> void:
	state["checks"] += 1
	if not ok:
		state["failed"] += 1
	print("GLOBETEST %s=%s" % [name, str(ok)])


static func _test_shot(tree: SceneTree, path: String, suffix: String) -> void:
	if path.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var target := path.get_basename() + "_" + suffix + ".png"
	var error := tree.root.get_texture().get_image().save_png(target)
	print("GLOBETEST screenshot=%s error=%d" % [target, error])


static func run_test(base: Control, path: String) -> void:
	var tree := base.get_tree()
	var state := {"checks": 0, "failed": 0}
	await tree.create_timer(1.0).timeout
	_check_test(state, "isolated_before_ready", not Meta.persist and Meta.runs == 0 and Meta.save_path == Meta.SAVE_PATH)
	var globe: GlobeView = base.get("_globe")
	_check_test(state, "viewport_active", globe.active and globe.viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS)
	_check_test(state, "eight_zones_three_offers", globe._regions.size() == 8 and globe._offers.size() == 3)
	var before := Campaign.world()
	await _test_shot(tree, path, "globe")
	base.call("_select_operation", 2)
	await tree.create_timer(0.8).timeout
	_check_test(state, "briefing_nest", int(base.get("_op_sel")) == 2 and base.get("_op_region") == "east_europe")
	await _test_shot(tree, path, "card")
	# Настоящий ввод мышью: перетаскивание не выбирает операцию и не запускает бой.
	var yaw0 := globe.yaw
	var at := globe.position + globe.size * 0.5
	var button := InputEventMouseButton.new()
	button.button_index = MOUSE_BUTTON_LEFT
	button.position = at
	button.pressed = true
	Input.parse_input_event(button)
	await tree.process_frame
	var motion := InputEventMouseMotion.new()
	motion.position = at + Vector2(90, 30)
	motion.relative = Vector2(90, 30)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await tree.process_frame
	button.position = motion.position
	button.pressed = false
	Input.parse_input_event(button)
	await tree.process_frame
	_check_test(state, "mouse_drag_no_launch", absf(globe.yaw - yaw0) > 0.05 and Campaign.pending().is_empty() and int(base.get("_op_sel")) == 2)
	var zoom0 := globe.zoom
	button.button_index = MOUSE_BUTTON_WHEEL_UP
	button.position = at
	button.pressed = true
	Input.parse_input_event(button)
	await tree.process_frame
	_check_test(state, "mouse_zoom", globe.zoom < zoom0)
	# Экранные координаты: на обратной стороне нет ни проекции, ни hit-test.
	globe.yaw = -PI
	globe.pitch = 0.0
	globe._turning = false
	globe._update_pose()
	_check_test(state, "horizon_culls_back", not globe.project_region("east_europe").is_finite())
	base.call("_select_region", "east_europe")
	await tree.create_timer(1.1).timeout
	_check_test(state, "back_autoturn", globe.project_region("east_europe").distance_to(globe.size * 0.5) < 20.0)
	await _test_shot(tree, path, "back")
	# Крестовина обходит все регионы; A сначала выбирает, затем начинает.
	var visited: Array[String] = []
	for i in 8:
		var pad := InputEventJoypadButton.new()
		pad.button_index = JOY_BUTTON_DPAD_RIGHT
		pad.pressed = true
		Input.parse_input_event(pad)
		await tree.process_frame
		visited.append(str(base.get("_op_region")))
	var unique := {}
	for id: String in visited:
		unique[id] = true
	_check_test(state, "dpad_all_eight_regions", unique.size() == 8)
	var duplicate_checked := false
	for seed in 100:
		var sample := CampaignRules.initial(seed)
		var targets := {}
		for op: Dictionary in sample["offers"]:
			targets[op["region_id"]] = true
		if targets.size() == 3:
			continue
		Meta.campaign = sample
		globe.refresh()
		base.call("_select_operation", 0)
		var reachable := {}
		for i in 3:
			reachable[int(base.get("_op_sel"))] = true
			base.call("_nav", 1, 0)
		duplicate_checked = reachable.has(0) and reachable.has(1) and reachable.has(2)
		break
	_check_test(state, "pad_all_offers_same_region", duplicate_checked)
	Meta.campaign = before.duplicate(true)
	globe.refresh()
	base.call("_select_region", "east_europe", false)
	for filter_id in 4:
		base.call("_click", "op_filter:%d" % filter_id)
		_check_test(state, "filter_%d" % filter_id, globe.filter == filter_id)
		var selected_index := int(base.get("_op_sel"))
		if selected_index >= 0:
			_check_test(state, "filter_selection_%d" % filter_id, bool(base.call("_operation_matches", Campaign.offers()[selected_index])))
	base.call("_click", "op_filter:0")
	base.call("_select_operation", 0)
	base.set("_op_armed", false)
	var a := InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	a.pressed = true
	Input.parse_input_event(a)
	await tree.process_frame
	_check_test(state, "pad_a_selects", base.get("_op_armed") and Campaign.pending().is_empty())
	base.call("_click", "op_journal")
	_check_test(state, "region_journal", base.get("_op_journal"))
	base.call("_click", "op_journal")
	var clean := Meta.clean_settings({"reduce_motion": true})
	_check_test(state, "motion_setting_sanitized", clean["reduce_motion"] and not Meta.clean_settings({"reduce_motion": "true"})["reduce_motion"])
	await base.call("_test_key", KEY_O)
	var settings: PauseMenu = base.get("_settings_menu")
	settings._selected = 8
	settings._change(1)
	settings.queue_redraw()
	_check_test(state, "settings_ui_motion_toggle", settings.visible and Meta.settings["reduce_motion"])
	await _test_shot(tree, path, "settings")
	await base.call("_test_key", KEY_ESCAPE)
	Meta.set_setting("reduce_motion", true)
	Meta.persist = true
	Meta.save_path = "res://tmp/c3_settings.json"
	Meta.save()
	var loaded := Meta.load_save()
	_check_test(state, "motion_setting_disk_roundtrip", loaded and Meta.settings["reduce_motion"])
	Meta.persist = false
	Meta.save_path = Meta.SAVE_PATH
	base.call("_select_region", "north_america")
	_check_test(state, "reduced_motion_instant_focus", not globe._turning and globe.project_region("north_america").distance_to(globe.size * 0.5) < 1.0)
	globe.show_changes({"changes": [{"region_id": "north_america", "from": 10, "to": 20}]})
	_check_test(state, "reduced_motion_no_flash", is_zero_approx(globe._flash))
	Meta.set_setting("reduce_motion", false)
	base.call("_set_tab", 0)
	_check_test(state, "hidden_viewport_disabled", not globe.active and not globe.is_processing() and globe.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED)
	base.call("_set_tab", 4)
	_check_test(state, "viewing_does_not_advance", Campaign.world() == before)
	# Щелчок списка и метки, затем настоящий переход база → боевая сцена.
	await base.call("_test_click", Vector2(60, 200))
	_check_test(state, "mouse_offer_select", int(base.get("_op_sel")) == 0)
	base.call("_select_operation", 2)
	globe.skip_motion()
	await tree.process_frame
	await tree.process_frame
	var projected := globe.project_region("east_europe")
	var local_at := (globe.position + projected) / float(base.get("_ui")) - Vector2(base.get("_origin"))
	await base.call("_test_click", local_at)
	_check_test(state, "mouse_marker_select", base.get("_op_region") == "east_europe")
	base.call("_select_operation", 2)
	a = a.duplicate()
	a.pressed = false
	Input.parse_input_event(a)
	await tree.process_frame
	a = a.duplicate()
	a.pressed = true
	Input.parse_input_event(a)
	await tree.process_frame
	_check_test(state, "pending_before_scene", not Campaign.pending().is_empty() and not globe.active)
	await tree.create_timer(0.8).timeout
	var game := tree.current_scene
	_check_test(state, "battle_config_and_globe_unloaded", game.scene_file_path == "res://scenes/main.tscn" and not Dictionary(game.get("mission_config")).is_empty() and game.find_children("GlobeView", "", true, false).is_empty())
	game.set("time", 640.0)
	game.set("kills", 3100)
	game.set("game_over", true)
	game.call("_open_results", true)
	await tree.create_timer(2.0, true).timeout
	var results := game.get_node("Overlay/RunResults") as RunResults
	_check_test(state, "results_committed_once", Meta.runs == 1 and int(Campaign.world()["turn"]) == 1 and not Campaign.last_report().is_empty())
	_check_test(state, "results_events_max_three", results._report["events"].size() <= 3 and not results._report["events"].is_empty())
	var dna0 := Meta.dna
	var repeated := results._stats.duplicate(true)
	Meta.last_save_ok = false
	Meta.last_error = "Проверка повторной записи"
	results.open(repeated)
	_check_test(state, "save_warning_survives_reopen", results._report["save_error"] == Meta.last_error)
	results._t = results._duration()
	results._finished = true
	_check_test(state, "results_reopen_idempotent", Meta.dna == dna0 and Meta.runs == 1 and int(Campaign.world()["turn"]) == 1)
	results._retry_save()
	_check_test(state, "save_retry_clears_warning", results._report["save_error"] == "" and Meta.runs == 1)
	await _test_shot(tree, path, "results")
	results._activate(false)
	await tree.create_timer(0.7).timeout
	base = tree.current_scene as Control
	globe = base.get("_globe")
	_check_test(state, "map_return_highlights", int(base.get("_tab")) == 4 and globe._flash > 0.0 and not globe._changed.is_empty())
	base.call("_click", "op_journal")
	await tree.create_timer(0.2).timeout
	await _test_shot(tree, path, "return")
	base.call("_cancel")
	globe.skip_motion()
	base.call("_click", "op_journal")
	if base.get("_op_journal"):
		base.call("_click", "op_journal")
	# Свободный забег не наследует завершённую операцию и не делает ход.
	var after := Campaign.world()
	base.call("_go_fight")
	await tree.create_timer(0.7).timeout
	game = tree.current_scene
	_check_test(state, "free_run_no_pending", Dictionary(game.get("mission_config")).is_empty())
	game.set("game_over", true)
	game.call("_open_results", false)
	_check_test(state, "free_result_no_world_change", Campaign.world() == after and (game.get_node("Overlay/RunResults") as RunResults)._report.is_empty())
	tree.paused = false
	print("GLOBETEST checks=%d failed=%d" % [state["checks"], state["failed"]])
	print("GLOBETEST ok=%s temporary_save=true" % str(state["failed"] == 0))
	tree.quit(0 if state["failed"] == 0 else 1)
