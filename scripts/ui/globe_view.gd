class_name GlobeView
extends Control
## Изолированный 3D-дисплей; ввод и карточки принадлежат базе.

signal region_selected(id: String)

const Style := preload("res://scripts/ui/zera_style.gd")

const COLORS := [Style.BETTER, Style.ACTION, Color("b7957c"), Style.DANGER, Color("743f49")]
const SHADER := """
shader_type spatial;
render_mode unshaded;
uniform sampler2D land : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D region_map : filter_nearest, repeat_enable;
uniform sampler2D cities : filter_linear_mipmap, repeat_enable;
uniform vec4 zones[8];
uniform float infections[8];
uniform bool hive_alive = true;
uniform vec3 sun_direction = vec3(-0.68, 0.35, 0.64);
varying vec3 local_point;
void vertex() { local_point = VERTEX; }
void fragment() {
    vec3 n = normalize(local_point);
    vec2 uv = vec2((atan(n.x, n.z) + PI) / (2.0 * PI), 0.5 - asin(n.y) / PI);
    vec4 region = texture(region_map, uv);
    int id = int(round(region.r * 255.0)) - 1;
    vec3 color = texture(land, uv).rgb;
    float infection = 0.0;
    if (id >= 0 && id < 8) {
        infection = infections[id];
        float area = smoothstep(0.18, 0.70, infection) * region.g * 0.72;
        // Удерживаемая суша без цветного ореола; улей матовый, только в своей зоне.
        vec3 zone = zones[id].rgb;
        if (id == 0 && hive_alive) { zone = mix(zone, vec3(0.17, 0.045, 0.09), 0.7); }
        color = mix(color, zone * 0.45, area);
        color = mix(color, vec3(0.22, 0.25, 0.22), region.b * 0.36);
    }
    vec3 world_n = normalize((MODEL_MATRIX * vec4(n, 0.0)).xyz);
    float day = dot(world_n, normalize(sun_direction));
    color *= 0.48 + 0.72 * max(day, 0.0);
    float night = 1.0 - smoothstep(-0.15, 0.3, day);
    color += vec3(0.65, 0.52, 0.28) * texture(cities, uv).r * night * pow(1.0 - infection, 2.0) * 0.9;
    float rim = pow(1.0 - max(world_n.z, 0.0), 5.0);
    ALBEDO = color + vec3(0.018, 0.026, 0.028) * rim;
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
var zoom := 2.22
var _focus_zoom := 2.22
var _hovered := ""
var _idle := 0.0
var _routes: Array[PackedVector3Array] = []
var _front: Dictionary = {}
var _front_route := PackedVector3Array()
var _outposts: Array = []
var _source_alive := true
var _phase := "active"
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
var _nest_texture: Texture2D


func _ready() -> void:
	_nest_texture = load("res://art/ops_nest.png") as Texture2D
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	viewport = SubViewport.new()
	viewport.size = Vector2i(768, 768)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
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
	globe_material.set_shader_parameter("region_map", load("res://art/globe_regions.png"))
	globe_material.set_shader_parameter("cities", load("res://art/globe_cities.png"))
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
	var world := Campaign.world()
	_source_alive = world["nests"]["object_7"]["alive"]
	_phase = world["phase"]
	_front = world["war"]["front"].duplicate()
	_outposts = world["war"]["outposts"].duplicate()
	_front_route.clear()
	if not _front.is_empty():
		var from: Dictionary = CampaignCatalog.REGIONS[_front["source"]]
		var to: Dictionary = CampaignCatalog.REGIONS[_front["target"]]
		for step in 49:
			_front_route.append(point(from["lat"], from["lon"]).slerp(point(to["lat"], to["lon"]), step / 48.0) * 1.008)
	var zones := PackedVector4Array()
	var infections := PackedFloat32Array()
	_routes.clear()
	for id: String in CampaignCatalog.REGIONS:
		var info := Campaign.region_info(id)
		_regions.append(info)
		var c: Color = COLORS[int(info["stage"])].srgb_to_linear()
		zones.append(Vector4(c.r, c.g, c.b, 1.0 if int(info["stage"]) >= 3 else 0.0))
		infections.append(float(info["infection"]) / 100.0)
		if int(info["infection"]) >= 60:
			for neighbor: String in info["neighbors"]:
				var other := Campaign.region_info(neighbor)
				var arc := PackedVector3Array()
				var a := point(info["lat"], info["lon"])
				var b := point(other["lat"], other["lon"])
				for step in 49:
					arc.append(a.slerp(b, step / 48.0) * 1.006)
				_routes.append(arc)
	globe_material.set_shader_parameter("zones", zones)
	globe_material.set_shader_parameter("infections", infections)
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
	_idle = 0.0
	_focus_zoom = 2.22
	if Meta.settings["reduce_motion"]:
		skip_motion()


func skip_motion() -> void:
	if _turning:
		yaw = _target.x
		pitch = _target.y
		zoom = _focus_zoom
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
	_idle += delta
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
				_idle = 0.0
			var trigger := Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT)
			if absf(trigger) > 0.05:
				_turning = false
				_idle = 0.0
				zoom = clampf(zoom - trigger * delta, 2.08, 3.5)
	if _turning:
		if reduced:
			skip_motion()
		else:
			yaw = lerp_angle(yaw, _target.x, 1.0 - exp(-delta * 7.0))
			pitch = lerpf(pitch, _target.y, 1.0 - exp(-delta * 7.0))
			zoom = lerpf(zoom, _focus_zoom, 1.0 - exp(-delta * 5.0))
			if absf(angle_difference(yaw, _target.x)) + absf(pitch - _target.y) + absf(zoom - _focus_zoom) < 0.002:
				_turning = false
	elif not _dragging and not reduced and _idle > 8.0 and _hovered.is_empty():
		yaw += delta * 0.012
	_update_pose()
	queue_redraw()


## Экранная проекция и отсев по нормали, без коллайдеров и физики.
func project_region(id: String) -> Vector2:
	var info: Dictionary = CampaignCatalog.REGIONS[id]
	var p := sphere.basis * point(info["lat"], info["lon"])
	if p.z <= 0.12:
		return Vector2.INF
	var at := camera.unproject_position(p)
	return (at / Vector2(viewport.size) - Vector2(0.5, 0.5)) * _display_side() + _display_center()


func _display_side() -> float:
	# Весь диск помещается между сводкой фронта и нижними счётчиками даже при максимальном приближении.
	var k := size.y / 238.0
	return minf(size.x - 12 * k, size.y - 40 * k)


func _display_center() -> Vector2:
	return size * 0.5 + Vector2(0, 12.0 * size.y / 238.0)


func pointer(event: InputEvent, at: Vector2) -> bool:
	var button := event as InputEventMouseButton
	if button != null:
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed and Rect2(Vector2.ZERO, size).has_point(at):
				_dragging = true
				_idle = 0.0
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
			_turning = false
			_idle = 0.0
			zoom = clampf(zoom + (-0.16 if button.button_index == MOUSE_BUTTON_WHEEL_UP else 0.16), 2.08, 3.5)
			return true
	var motion := event as InputEventMouseMotion
	if motion != null:
		_hovered = ""
		for hit: Dictionary in _hits:
			if at.distance_to(hit["point"]) < 9.0 * size.y / 238.0 or hit["rect"].has_point(at):
				_hovered = hit["id"]
		_idle = 0.0
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



## Сначала резервируем все значки, затем подписи: выбранная, операции, остальные.
func _layout_labels() -> void:
	_hits.clear()
	var k := size.y / 238.0
	var occupied: Array[Rect2] = []
	for info: Dictionary in _regions:
		if not matches_filter(info):
			continue
		var at := project_region(info["id"])
		if not at.is_finite():
			continue
		var number := ""
		for i in _offers.size():
			if _offers[i]["region_id"] == info["id"]:
				if filter == 2 and int(_offers[i]["threat"]) > 2 or filter == 3 and _offers[i]["type"] != "nest":
					continue
				number += ("/" if not number.is_empty() else "") + str(i + 1)
		var threatened: bool = not _front.is_empty() and _front["target"] == info["id"]
		_hits.append({"id": info["id"], "point": at, "rect": Rect2(), "label": "",
			"stage": info["stage"], "number": number, "priority": 0 if selected == info["id"] else (1 if number != "" or threatened else 2)})
		occupied.append(Rect2(at + Vector2(-11, -10) * k, Vector2(22, 30 if threatened else 20) * k))
	_hits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["priority"]) < int(b["priority"]))
	var font := Style.BODY_FONT
	var fs := maxi(1, roundi(8 * k))
	var bounds := Rect2(Vector2(3, 31) * k, size - Vector2(6, 48) * k)
	var icons: Array[Rect2] = occupied.duplicate()
	var labels: Array[Rect2] = []
	var leaders: Array[PackedVector2Array] = []
	for hit: Dictionary in _hits:
		if hit["priority"] >= 2 and hit["id"] != _hovered:
			continue
		var name_text: String = CampaignCatalog.REGIONS[hit["id"]]["name"]
		var prefix := "[" + str(hit["number"]) + "] " if hit["number"] != "" else ""
		var normal := (Vector2(hit["point"]) - size * 0.5).normalized()
		if normal.length_squared() < 0.01:
			normal = Vector2.RIGHT
		# Короткое имя — запасной вариант, без потери номера операции.
		var short_name := name_text.replace("Северная", "Сев.").replace("Восточная", "Вост.").replace("Западная", "Зап.").replace("Ближний", "Бл.").replace("Южная", "Юж.")
		var variants: Array[String] = [prefix + short_name]
		# Сначала ищем место с чистой выноской (не режет чужие подписи и значки),
		# и только если его нет — любое свободное место.
		for strict: bool in [true, false]:
			for label: String in variants:
				var extent := Vector2(font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 6 * k, 12 * k)
				var rect := _find_slot(hit, normal, extent, bounds, k, strict, occupied, icons, labels, leaders)
				if rect.has_area():
					_commit_label(hit, label, rect, k, occupied, labels, leaders)
					break
			if not str(hit["label"]).is_empty():
				break

		# У горизонта нормаль может вести за край: приоритетной подписи ищем
		# ближайшее свободное место внутри дисплея. Обычную допустимо скрыть.
		if str(hit["label"]).is_empty() and hit["priority"] < 2:
			var label := prefix + short_name
			var extent := Vector2(font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 6 * k, 12 * k)
			for strict: bool in [true, false]:
				var best := INF
				var fallback := Rect2()
				for row in maxi(0, floori((bounds.size.y - extent.y) / (14 * k)) + 1):
					for column in maxi(0, floori((bounds.size.x - extent.x) / (8 * k)) + 1):
						var rect := Rect2(bounds.position + Vector2(column * 8, row * 14) * k, extent)
						var distance := rect.get_center().distance_squared_to(hit["point"])
						if distance < best and _slot_free(hit, rect, k, strict, occupied, icons, labels, leaders):
							best = distance
							fallback = rect
				if fallback.has_area():
					_commit_label(hit, label, fallback, k, occupied, labels, leaders)
					break


## Первое свободное место подписи: по нормали от центра шара, со сдвигом вдоль касательной.
func _find_slot(hit: Dictionary, normal: Vector2, extent: Vector2, bounds: Rect2, k: float, strict: bool,
		occupied: Array[Rect2], icons: Array[Rect2], labels: Array[Rect2], leaders: Array[PackedVector2Array]) -> Rect2:
	var tangent := normal.orthogonal()
	for distance in [16, 30, 46, 64, 86]:
		for slide in [0, -1, 1, -2, 2, -3, 3]:
			var anchor := Vector2(hit["point"]) + normal * float(distance) * k + tangent * float(slide) * 14 * k
			var offset := Vector2(extent.x if normal.x < -0.15 else (0.0 if normal.x > 0.15 else extent.x * 0.5), extent.y * 0.5)
			var rect := Rect2(anchor - offset, extent)
			if bounds.encloses(rect) and _slot_free(hit, rect, k, strict, occupied, icons, labels, leaders):
				return rect
	return Rect2()


## Прямоугольник свободен; в строгом режиме ещё и выноска не пересекает чужие подписи, значки и выноски.
func _slot_free(hit: Dictionary, rect: Rect2, k: float, strict: bool,
		occupied: Array[Rect2], icons: Array[Rect2], labels: Array[Rect2], leaders: Array[PackedVector2Array]) -> bool:
	var grown := rect.grow(k)
	for other: Rect2 in occupied:
		if grown.intersects(other):
			return false
	if not strict:
		return true
	var from: Vector2 = hit["point"]
	var to := from.clamp(rect.position, rect.end)
	for other: Rect2 in labels:
		if _segment_hits_rect(from, to, other):
			return false
	for other: Rect2 in icons:
		if not other.has_point(from) and _segment_hits_rect(from, to, other):
			return false
	for leader: PackedVector2Array in leaders:
		if _segment_hits_rect(leader[0], leader[1], rect):
			return false
	return true


func _commit_label(hit: Dictionary, label: String, rect: Rect2, k: float,
		occupied: Array[Rect2], labels: Array[Rect2], leaders: Array[PackedVector2Array]) -> void:
	hit["rect"] = rect
	hit["label"] = label
	occupied.append(rect.grow(k))
	labels.append(rect)
	leaders.append(PackedVector2Array([Vector2(hit["point"]), Vector2(hit["point"]).clamp(rect.position, rect.end)]))


static func _segment_hits_rect(a: Vector2, b: Vector2, r: Rect2) -> bool:
	if r.has_point(a) or r.has_point(b):
		return true
	var c := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(a, b, c[i], c[(i + 1) % 4]) != null:
			return true
	return false


func _draw() -> void:
	if not active or size.x < 2.0 or size.y < 2.0:
		return
	var k := size.y / 238.0
	var side := _display_side()
	draw_texture_rect(viewport.get_texture(), Rect2(_display_center() - Vector2.ONE * side * 0.5, Vector2.ONE * side), false)
	# Дуги лежат на поверхности; обратная полусфера отсекается тем же порогом, что метки.
	for arc: PackedVector3Array in _routes:
		for i in range(1, arc.size()):
			if i % 5 >= 3:
				continue
			var a := sphere.basis * arc[i - 1]
			var b := sphere.basis * arc[i]
			if a.z <= 0.12 or b.z <= 0.12:
				continue
			var screen_a := (camera.unproject_position(a) / Vector2(viewport.size) - Vector2.ONE * 0.5) * side + _display_center()
			var screen_b := (camera.unproject_position(b) / Vector2(viewport.size) - Vector2.ONE * 0.5) * side + _display_center()
			draw_line(screen_a, screen_b, Color("9d8870"), k * 0.65, true)
			if i == 28:
				var direction := (screen_b - screen_a).normalized()
				draw_colored_polygon(PackedVector2Array([screen_b + direction * 2 * k, screen_b - direction * 5 * k + direction.orthogonal() * 3 * k, screen_b - direction * 3 * k - direction.orthogonal() * 2 * k]), Color("9d8870"))
	_layout_labels()
	if not _front_route.is_empty():
		var color := Style.BETTER if _front["stopped"] else Style.DANGER
		for i in range(1, _front_route.size()):
			var a := sphere.basis * _front_route[i - 1]
			var b := sphere.basis * _front_route[i]
			if a.z <= 0.12 or b.z <= 0.12:
				continue
			var screen_a := (camera.unproject_position(a) / Vector2(viewport.size) - Vector2.ONE * 0.5) * side + _display_center()
			var screen_b := (camera.unproject_position(b) / Vector2(viewport.size) - Vector2.ONE * 0.5) * side + _display_center()
			draw_line(screen_a, screen_b, color, k * 2.5, true)
			if i in [20, 36]:
				var direction := (screen_b - screen_a).normalized()
				draw_colored_polygon(PackedVector2Array([screen_b + direction * 3 * k, screen_b - direction * 3 * k + direction.orthogonal() * 2 * k, screen_b - direction * 3 * k - direction.orthogonal() * 2 * k]), color)
	if not _front.is_empty() and not _front["stopped"]:
		var target := project_region(_front["target"])
		if target.is_finite():
			PixelArt.draw_dot(self, target, 25 * k, Color(Style.DANGER, 0.15))
			draw_arc(target, 25 * k, 0, TAU, 32, Color(Style.DANGER, 0.7), k)
			for stripe in range(-2, 3):
				var y := stripe * 8.0 * k
				var width := sqrt(maxf(0, pow(23 * k, 2) - y * y))
				draw_line(target + Vector2(-width, y), target + Vector2(width, y), Color(Style.DANGER, 0.18), k)
	for info: Dictionary in _regions:
		if not matches_filter(info):
			continue
		var at := project_region(info["id"])
		if not at.is_finite():
			continue
		var number := ""
		var nest: bool = info["nests"].any(func(n: Dictionary) -> bool: return n["playable"] and n["alive"] and n["discovered"])
		for i in _offers.size():
			if _offers[i]["region_id"] == info["id"]:
				if filter == 2 and int(_offers[i]["threat"]) > 2 or filter == 3 and _offers[i]["type"] != "nest":
					continue
				number += ("/" if not number.is_empty() else "") + str(i + 1)
				nest = nest or _offers[i]["type"] == "nest"
		var c: Color = COLORS[int(info["stage"])]
		var chosen: bool = selected == info["id"]
		if _outposts.has(info["id"]):
			var flag := at + Vector2(-7, -8) * k
			draw_line(flag, flag + Vector2(0, 12) * k, Color("a4b592"), k)
			draw_colored_polygon(PackedVector2Array([flag, flag + Vector2(8, 1) * k, flag + Vector2(6, 5) * k, flag + Vector2(0, 5) * k]), Color("8e9e7e"))
		if not _front.is_empty() and _front["target"] == info["id"]:
			var r := Rect2(at + Vector2(-11, 9) * k, Vector2(22, 10) * k)
			draw_rect(r, Color("181714"))
			draw_string(Style.BODY_FONT, r.position + Vector2(2, 8) * k, "×" if _front["stopped"] else "+%d" % int(CampaignCatalog.BALANCE["front_infection"]), HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(1, roundi(8 * k)), Color("a4b592") if _front["stopped"] else Color("cf8e68"))
		var r := 4.0 * k
		var diamond := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r), at + Vector2(-r, 0), at + Vector2(0, -r)])
		draw_colored_polygon(diamond, Color("090d0c"))
		var blink := 1.0
		if int(info["stage"]) >= 3 and not Meta.settings["reduce_motion"]:
			blink = 0.85 + 0.15 * pow(maxf(0.0, sin(_time * 0.9)), 8.0)
		var mark_color := Color(Color.WHITE, blink) if number != "" else Color(c, blink)
		if CampaignCatalog.KEY_REGIONS.has(info["id"]) and int(info["stage"]) == 4:
			draw_line(at + Vector2(-7, -7) * k, at + Vector2(7, 7) * k, Color("c2a88b", blink), k * 2)
		if nest:
			draw_texture_rect(_nest_texture, Rect2(at - Vector2.ONE * 7 * k, Vector2.ONE * 14 * k), false)
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
		if not nest and int(info["stage"]) >= 3:
			draw_line(at + Vector2(0, -2 * k), at + Vector2(0, 2 * k), c, 2 * k)
		if chosen or (_flash > 0.0 and _changed.has(info["id"])):
			draw_arc(at, 8 * k, 0.0, TAU, 24, Color(0.95, 0.85, 0.57, 0.8), k, true)
	for hit: Dictionary in _hits:
		if str(hit["label"]).is_empty():
			continue
		var rect: Rect2 = hit["rect"]
		var at: Vector2 = hit["point"]
		var edge := at.clamp(rect.position, rect.end)
		if at.distance_to(edge) > 20 * k:
			draw_line(at, edge, Color("68736c"), k * 0.7)
		draw_rect(rect, Color(0.025, 0.04, 0.04, 0.93))
		draw_string(Style.BODY_FONT, rect.position + Vector2(3 * k, 9 * k), hit["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(8 * k), Color("e5e3d8") if hit["priority"] < 2 else Color("a3aca7"))
	if _flash > 0.0:
		draw_string(Style.BODY_FONT, Vector2(8, size.y - 6 * k), "ФРОНТ ОБНОВЛЁН · Esc / B — пропустить", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(8 * k), Color("e4ce87"))
	# Сводка рисуется поверх шара, подписи не занимают её полосу.
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 29 * k)), Color("0b1010"))
	if not _front.is_empty():
		var tone := Style.BETTER if _front["stopped"] else Style.DANGER
		var title := "УДАР СОРВАН" if _front["stopped"] else "УДАР ФРОНТА   +%d%%   ·   ХОД %d" % [int(CampaignCatalog.BALANCE["front_infection"]), _front["due_turn"]]
		draw_string(Style.BODY_FONT, Vector2(8, 11) * k, title, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(8 * k), tone)
		var route := "%s → %s" % [CampaignCatalog.REGIONS[_front["source"]]["name"], CampaignCatalog.REGIONS[_front["target"]]["name"]]
		draw_string(Style.BODY_FONT, Vector2(8, 23) * k, route, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(8 * k), Color("bdc0b3"))
	else:
		var title := "ВОЙНА ОКОНЧЕНА" if _phase == "victory" else ("ПУТЬ К СЕРДЦУ ОТКРЫТ" if not _source_alive else ("СВЯЗЬ ПОТЕРЯНА" if _phase == "defeat" else "ФРОНТ"))
		draw_string(Style.BODY_FONT, Vector2(8, 18) * k, title, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(8 * k), Style.BETTER)


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
	if OS.get_cmdline_user_args().has("--ops-benchmark"):
		await _benchmark(base)
		tree.quit.call_deferred()
		return
	if OS.get_cmdline_user_args().has("--ops-capture"):
		await _capture(base, path)
		tree.quit.call_deferred()
		return
	_check_test(state, "isolated_before_ready", not Meta.persist and Meta.runs == 0 and Meta.save_path == Meta.SAVE_PATH)
	var globe: GlobeView = base.get("_globe")
	_check_test(state, "viewport_active", globe.active and globe.viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS)
	_check_test(state, "eight_zones_three_offers", globe._regions.size() == 8 and globe._offers.size() == 3)
	var art_ok := true
	for id: String in CampaignCatalog.REGIONS:
		art_ok = art_ok and ResourceLoader.exists("res://art/ops_region_%s.png" % id)
	for id: String in CampaignCatalog.MODIFIERS + ["clearance", "nest", "dispatcher", "threat", "infection_down", "infection_up", "neighbors"]:
		art_ok = art_ok and ResourceLoader.exists("res://art/ops_%s.png" % id)
	_check_test(state, "briefing_art_catalog_complete", art_ok)
	var mask := (load("res://art/globe_regions.png") as Texture2D).get_image()
	var mask_ok := mask.get_size() == Vector2i(2048, 1024) and mask.get_pixel(1024, 512).r == 0.0
	var index := 0
	for info: Dictionary in globe._regions:
		var x := floori((float(info["lon"]) + 180.0) / 360.0 * mask.get_width())
		var y := floori((90.0 - float(info["lat"])) / 180.0 * mask.get_height())
		mask_ok = mask_ok and roundi(mask.get_pixel(x, y).r * 255.0) == index + 1
		index += 1
	_check_test(state, "land_mask_all_eight_centers_and_ocean", mask_ok)
	_check_test(state, "spread_routes_present", not globe._routes.is_empty())
	globe._layout_labels()
	var sparse_labels := true
	for hit: Dictionary in globe._hits:
		if int(hit["priority"]) == 2:
			sparse_labels = sparse_labels and str(hit["label"]).is_empty()
	_check_test(state, "quiet_regions_have_no_permanent_labels", sparse_labels)
	globe.zoom = 3.2
	globe.focus_region("east_asia")
	globe.skip_motion()
	_check_test(state, "focus_zooms_to_operation", globe.zoom < 2.3)
	var idle_yaw := globe.yaw
	globe._idle = 9.0
	globe._process(0.1)
	_check_test(state, "idle_rotation", globe.yaw > idle_yaw)
	Meta.set_setting("reduce_motion", true)
	idle_yaw = globe.yaw
	globe._process(0.1)
	_check_test(state, "reduced_motion_stops_idle_rotation", globe.yaw == idle_yaw)
	Meta.set_setting("reduce_motion", false)
	base.call("_select_region", "east_europe", false)
	globe.skip_motion()
	await base.call("_test_key", KEY_Q)
	_check_test(state, "keyboard_filter_cycle", globe.filter == 1)
	base.call("_click", "op_filter:0")
	await base.call("_test_key", KEY_J)
	_check_test(state, "keyboard_journal", base.get("_op_journal"))
	await base.call("_test_key", KEY_J)
	# Плотный перебор проекций, фильтров, масштабов и размеров дисплея.
	var pose := Vector3(globe.yaw, globe.pitch, globe.zoom)
	var original_size := globe.size
	var labels_clear := true
	var priority_visible := true
	var crossings := 0 # выноска режет чужую подпись (допустимо только когда чистого места нет)
	var cases := 0
	for display_size: Vector2 in [Vector2(238, 238), Vector2(714, 714), Vector2(580, 400)]:
		globe.size = display_size
		for test_zoom in [2.25, 2.65, 3.5]:
			globe.zoom = test_zoom
			for test_pitch in [-1.4, 0.0, 1.4]:
				globe.pitch = test_pitch
				for turn in 24:
					globe.yaw = turn * TAU / 24.0
					globe.selected = CampaignCatalog.REGIONS.keys()[turn % 8]
					globe._update_pose()
					for test_filter in 4:
						globe.filter = test_filter
						globe._layout_labels()
						cases += 1
						var k := globe.size.y / 238.0
						for hit: Dictionary in globe._hits:
							var rect: Rect2 = hit["rect"]
							if hit["priority"] < 2 and str(hit["label"]).is_empty():
								priority_visible = false
							if not rect.has_area():
								continue
							labels_clear = labels_clear and Rect2(Vector2.ZERO, globe.size).encloses(rect)
							for other: Dictionary in globe._hits:
								labels_clear = labels_clear and not rect.intersects(Rect2(Vector2(other["point"]) - Vector2.ONE * 9 * k, Vector2.ONE * 18 * k))
								if other != hit and Rect2(other["rect"]).has_area():
									labels_clear = labels_clear and not rect.intersects(other["rect"])
									if _segment_hits_rect(hit["point"], Vector2(hit["point"]).clamp(rect.position, rect.end), other["rect"]):
										crossings += 1
	print("GLOBETEST label_projection_cases=%d leader_crossings=%d" % [cases, crossings])
	_check_test(state, "labels_no_overlap_or_clipping", labels_clear)
	_check_test(state, "selected_and_operation_labels_visible", priority_visible)
	globe.size = original_size
	globe.zoom = pose.z
	globe.filter = 0
	for id: String in ["east_europe", "east_asia", "north_america"]:
		base.call("_select_region", id)
		globe.skip_motion()
		await tree.process_frame
		await _test_shot(tree, path, id)
	base.call("_select_region", "east_europe")
	globe.skip_motion()

	var before := Campaign.world()
	await _test_shot(tree, path, "globe")
	base.call("_select_operation", 2)
	await tree.create_timer(0.8).timeout
	_check_test(state, "briefing_third_offer", int(base.get("_op_sel")) == 2 and base.get("_op_region") == Campaign.offers()[2]["region_id"])
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
	_check_test(state, "back_autoturn", globe.project_region("east_europe").distance_to(globe._display_center()) < 20.0)
	await _test_shot(tree, path, "back")
	# Крестовина обходит все регионы; A сначала выбирает, затем начинает.
	var visited: Array[String] = []
	for i in CampaignCatalog.REGIONS.size() + Campaign.offers().size():
		await MetaTest._cycle_button(tree, JOY_BUTTON_DPAD_RIGHT)
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
	settings._selected = PauseMenu.KEYS.find("reduce_motion")
	settings._change(1)
	settings.queue_redraw()
	_check_test(state, "settings_ui_motion_toggle", settings.visible and Meta.settings["reduce_motion"])
	await _test_shot(tree, path, "settings")
	await base.call("_test_key", KEY_ESCAPE)
	Meta.set_setting("reduce_motion", true)
	Meta.persist = true
	DirAccess.make_dir_recursive_absolute("res://design/tasks/reports/cp1_userdata/fixtures")
	Meta.save_path = "res://design/tasks/reports/cp1_userdata/fixtures/globe_settings.json"
	Meta.save()
	var loaded := Meta.load_save()
	_check_test(state, "motion_setting_disk_roundtrip", loaded and Meta.settings["reduce_motion"])
	Meta.persist = false
	Meta.save_path = Meta.SAVE_PATH
	base.call("_select_region", "north_america")
	_check_test(state, "reduced_motion_instant_focus", not globe._turning and globe.project_region("north_america").distance_to(globe._display_center()) < 1.0)
	globe.show_changes({"changes": [{"region_id": "north_america", "from": 10, "to": 20}]})
	_check_test(state, "reduced_motion_no_flash", is_zero_approx(globe._flash))
	Meta.set_setting("reduce_motion", false)
	base.call("_set_tab", 0)
	_check_test(state, "hidden_viewport_disabled", not globe.active and not globe.is_processing() and globe.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED)
	base.call("_set_tab", 4)
	_check_test(state, "viewing_does_not_advance", Campaign.world() == before)
	# Щелчок списка и метки, затем настоящий переход база → боевая сцена.
	await base.call("_test_click", Vector2(60, 318))
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
	await tree.create_timer(0.12).timeout
	await MetaTest._cycle_button(tree, JOY_BUTTON_A)
	_check_test(state, "pending_before_scene", not Campaign.pending().is_empty() and (tree.current_scene != base or not globe.active))
	await tree.create_timer(0.8).timeout
	var game := tree.current_scene
	_check_test(state, "battle_config_and_globe_unloaded", game.scene_file_path == "res://scenes/main.tscn" and not Dictionary(game.get("mission_config")).is_empty() and game.find_children("GlobeView", "", true, false).is_empty())
	if game.scene_file_path != "res://scenes/main.tscn":
		Meta.finish_test(1)
		return
	var dispatch: Dictionary = game.get_script().get_script_constant_map()["DISPATCH"]
	var radio_ok := true
	for event: String in dispatch:
		var variants: Array = dispatch[event]
		radio_ok = radio_ok and variants.size() >= 2 and variants.size() <= 3
		for line: String in variants:
			radio_ok = radio_ok and not line.contains("\n") and Style.BODY_FONT.get_string_size("ДИСПЕТЧЕР: " + line, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x <= 608.0
		var first := str(game.call("_dispatch_line", event))
		var second := str(game.call("_dispatch_line", event))
		radio_ok = radio_ok and first != second
	_check_test(state, "dispatcher_variants_fit_one_line", radio_ok)

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
	_check_test(state, "reward_factors_separate", results.multiplier_text() == "×1,5 · ×" + String.num(float(results._stats["reward"]["dna_mul"]), 2).replace(".", ","))

	var receipt := RunResults.new()
	receipt._report = {"run_id": "test"}
	receipt._stats = {"victory": true, "dna_mult": 2.1, "reward": {"dna_mul": 1.4}}
	_check_test(state, "reward_factors_exact", receipt.multiplier_text() == "×1,5 · ×1,4")
	receipt._stats = {"victory": false, "dna_mult": 1.0, "reward": {"dna_mul": 1.4}}
	_check_test(state, "defeat_no_operation_bonus", receipt.multiplier_text().is_empty())
	receipt._report = {}
	receipt._stats = {"victory": true, "dna_mult": 1.5}
	_check_test(state, "free_victory_factor", receipt.multiplier_text() == "×1,5")
	receipt.free()

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


## Одинаковый маршрут до и после правок, без снимков и смен сцен в замере.
static func _benchmark(base: Control) -> void:
	var tree := base.get_tree()
	var globe: GlobeView = base.get("_globe")
	for id: String in ["east_europe", "east_asia", "north_america"]:
		base.call("_select_region", id, false)
		globe.skip_motion()
		await tree.create_timer(0.5).timeout
		var start := Time.get_ticks_usec()
		var worst := 0
		var previous := start
		for frame in 240:
			await tree.process_frame
			var now := Time.get_ticks_usec()
			worst = maxi(worst, now - previous)
			previous = now
		var elapsed := (Time.get_ticks_usec() - start) / 1000000.0
		print("OPSBENCH region=%s frames=240 avg_fps=%.1f worst_ms=%.2f viewport=%s" % [id, 240.0 / elapsed, worst / 1000.0, globe.viewport.size])


## Реальные viewport-снимки обеих компоновок; состояние кампании не меняется.
static func _capture(base: Control, path: String) -> void:
	var tree := base.get_tree()
	var globe: GlobeView = base.get("_globe")
	tree.root.mode = Window.MODE_WINDOWED
	tree.root.size = Vector2i(1920, 1080)
	base.call("_select_operation", 2)
	globe.skip_motion()
	await tree.create_timer(0.4).timeout
	await _test_shot(tree, path, "ops_1080")
	for id: String in ["east_europe", "east_asia", "north_america"]:
		base.call("_select_region", id, false)
		globe.skip_motion()
		await tree.create_timer(0.2).timeout
		await _test_shot(tree, path, "globe_" + id)
	base.call("_select_operation", 2)
	globe.skip_motion()
	await tree.create_timer(0.2).timeout
	await _test_shot(tree, path, "brief_nest")
	base.call("_select_region", "north_america", false)
	globe.skip_motion()
	globe.globe_material.set_shader_parameter("sun_direction", Vector3(-0.7, 0.2, -0.6))
	await tree.create_timer(0.2).timeout
	await _test_shot(tree, path, "night")
	globe.globe_material.set_shader_parameter("sun_direction", Vector3(-0.68, 0.35, 0.64))
	tree.root.size = Vector2i(1280, 720)
	base.call("_select_operation", 2)
	globe.skip_motion()
	await tree.create_timer(0.3).timeout
	await _test_shot(tree, path, "ops_720")
	print("OPSCAPTURE screenshots=7 complete=true")
