class_name Obstacles
extends Node2D
## O1: общая сетка, packed-строки, ограниченная очередь детонаций и один атлас.

enum Kind { SEDAN, HATCH, POLICE, JEEP, TRUCK, RED, ACID, JERSEY, BAGS, FENCE, WOOD, TIRES, RUBBISH, PAPER, BOARDS, GLASS, CONE, STRUCTURE }
enum State { INTACT, DAMAGED, BURNING, WRECK, GONE }
const CELL := 8.0
const ART_CELL := Vector2(288, 144)
const TILES := 34
const CAR_RADIUS := 90.0
const CAR_DAMAGE := 60.0
const BARREL_RADIUS := 65.0
const BARREL_DAMAGE := 40.0
const FLOW_BUDGET := 600 # было 200: поле на большой карте пересчитывалось ~12 с
const CLASS_RADII := [4.6, 5.4, 7.95]
const STEPS := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
const NO_PATH := 2147483647
## Частый пересчёт основного класса — только в окрестности игрока (≈720 px пути); дальше остаются прежние
## направления, их обновляет полный пересчёт раз в три цикла.
const LOCAL_COST := 900
const BLOOD_LIMIT := 1024
const BLOOD_PER_OBJECT := 64
const BLOOD_BATCH := 64

var player: Player
var horde: Horde
var hazards: Hazards
var explosions: Explosions
var sfx: Sfx
var arena := Rect2()
var count := 0
var pos := PackedVector2Array()
var half := PackedVector2Array()
var axis := PackedVector2Array()
var rotation_angle := PackedFloat32Array()
var kind := PackedByteArray()
var state := PackedByteArray()
var hp := PackedFloat32Array()
var burn := PackedFloat32Array()
var blood := PackedByteArray()
var high := PackedByteArray()
var round_shape := PackedByteArray()
var grid_w := 0
var grid_h := 0
var near_head := PackedInt32Array()
var blocked := PackedByteArray()
var flow := PackedVector2Array()
var nav_worst_usec := 0
var collision_worst_usec := 0
var detonations := 0
var nav_completed := 0
var nav_total_usec := 0 # суммарное время navigation_step (профиль)
var nav_calls := 0
var blood_events := 0

var _link_obj := PackedInt32Array()
var _link_next := PackedInt32Array()
var distance := PackedInt32Array()
var _distance_build := PackedInt32Array()
var _out_distance := PackedInt32Array() # выходное поле: в ограниченном пересчёте вне окрестности — прежние значения
var _local_build := false
## Живая игра: поле путей считается в фоновых потоках (по задаче на класс), основной поток только забирает
## готовые слои. Тесты и симуляции остаются на пошаговом расчёте — он детерминирован по seed.
var threaded_nav := false
var _task_ids := PackedInt64Array()
var _task_out: Array[Dictionary] = []
var _task_target := -1
var _task_generation := 0
var _nav_generation := 0
var _unbounded := true # текущий цикл пересчитывает всю карту
var _pending_target := -1
var nav_revision := 0
var _nav_layers: Dictionary = {}
var _clearance := PackedFloat32Array()
var obstacle_distance := PackedFloat32Array()
var wall_normal := PackedVector2Array()
var _solid_state := PackedByteArray()
var _buckets: Array[Array] = []
var _bucket_cost := 0
var _bucket_count := 0
var _build_class := 0
## Обычный класс (1) — основная толпа — строится каждый пересчёт и первым; мелкий и крупный — раз в три
## пересчёта или после изменения карты. Иначе поле отставало от игрока на секунды и толпа шла к старой точке.
var _build_order := PackedInt32Array([1, 0, 2])
var _build_pos := 0
var _rebuild_serial := 0
var _next_anchor := PackedVector2Array()
var _next_capacity := PackedFloat32Array()
var _sample_capacity := INF
var _offsets := PackedInt32Array()
var _dirty := true
var _next_flow := PackedVector2Array()
var _adjacency := PackedInt32Array()
var _building := false
var _target_cell := -1
var _flow_target := Vector2.ZERO
var _flow_ready := false
var _nav_cd := 0.0
var _blast_queue := PackedInt32Array()
var _burning := PackedInt32Array()
var _smoking := PackedInt32Array()
var _fire_tick := 0.0
var _visual_tick := 0.0
var _view_cell := Vector2i(-999, -999)
var _atlas: Texture2D
var _fire: Texture2D
var _smoke: Texture2D
var _fx: Node2D
var _rng := RandomNumberGenerator.new()
var _structure_tex: Array[Texture2D] = []
var hive_skin: Texture2D # Только облицовка O2; форма, прочность и навигация прежние.
var _extent := PackedVector2Array()
var _blood_at := PackedVector2Array()
var _blood_object := PackedInt32Array()
var _blood_angle := PackedFloat32Array()
var _blood_size := PackedVector2Array()
var _blood_time := PackedFloat32Array()
var _blood_clock := 0.0
var _blood_node: Node2D
var _blood_material: ShaderMaterial
var _blood_meshes: Array[ArrayMesh] = []
var _blood_dirty := PackedByteArray()
var _blood_built := PackedInt32Array()
var _blood_vertices: Array[PackedVector2Array] = []
var _blood_colors: Array[PackedColorArray] = []
var _blood_times: Array[PackedVector2Array] = []
var _blood_indices: Array[PackedInt32Array] = []
var _blood_masks: Array[Image] = []
var _atlas_mask: Image
var _ray_seen := PackedInt32Array()
var _ray_stamp := 0
var profile_enabled := false
var resolve_usec := 0
var move_usec := 0
var ray_usec := 0
var resolve_calls := 0
var move_calls := 0
var ray_calls := 0
var body_usec := 0
var body_calls := 0
var path_calls := 0
var _art: MultiMesh
var _art_node: MultiMeshInstance2D
var _art_buffer := PackedFloat32Array()
var _art_rows := PackedInt32Array()
var _art_slot := PackedInt32Array()
var _art_dirty := PackedByteArray()
var _art_pending := PackedInt32Array()
var _structures := PackedInt32Array()
var draw_usec := 0


func _ready() -> void:
	_atlas = PixelArt.tex("map_vehicles")
	_fire = PixelArt.tex("fx_explosion_medium")
	_smoke = PixelArt.tex("fx_smoke")
	process_priority = -20
	_fx = Node2D.new()
	_fx.draw.connect(_draw_fx)
	add_child(_fx)
	_rng.seed = 17081
	_art_node = MultiMeshInstance2D.new()
	_art = MultiMesh.new()
	_art.transform_format = MultiMesh.TRANSFORM_2D
	_art.use_custom_data = true
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector2Array([Vector2(-48, -24), Vector2(48, -24), Vector2(48, 24), Vector2(-48, 24)])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_art.mesh = mesh
	_art_node.multimesh = _art
	_art_node.texture = _atlas
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
varying vec2 cell;
void vertex() { cell = INSTANCE_CUSTOM.xy; }
void fragment() {
	COLOR = texture(TEXTURE, (cell + UV) / vec2(8.0, 17.0));
}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	_art_node.material = material
	add_child(_art_node)
	_blood_node = Node2D.new()
	_blood_node.draw.connect(_draw_blood)
	_blood_material = ShaderMaterial.new()
	var blood_shader := Shader.new()
	blood_shader.code = """shader_type canvas_item;
uniform float blood_clock = 0.0;
void fragment() {
	float wet = exp(-max(0.0, blood_clock - UV.x) / 18.0);
	COLOR.rgb *= mix(vec3(0.16, 0.022, 0.016), vec3(0.34, 0.035, 0.028), wet);
}"""
	_blood_material.shader = blood_shader
	_blood_node.material = _blood_material
	add_child(_blood_node)
	move_child(_fx, -1)


func setup(rect: Rect2, layout: Array[Dictionary]) -> void:
	arena = rect
	count = layout.size()
	_structure_tex.resize(count)
	_extent.resize(count)
	_blood_at.clear()
	_blood_object.clear()
	_blood_angle.clear()
	_blood_size.clear()
	_blood_time.clear()
	_blood_meshes.clear()
	_blood_dirty.clear()
	_blood_built.clear()
	_blood_vertices.clear()
	_blood_colors.clear()
	_blood_times.clear()
	_blood_indices.clear()
	_blood_masks.clear()
	_blood_masks.resize(count)
	_blood_clock = 0.0
	if _blood_node:
		_blood_node.queue_redraw()
	_ray_seen.resize(count)
	_ray_seen.fill(0)
	_ray_stamp = 0
	profile_enabled = OS.get_cmdline_user_args().has("--obstacle-profile")
	pos.resize(count)
	half.resize(count)
	axis.resize(count)
	rotation_angle.resize(count)
	kind.resize(count)
	state.resize(count)
	hp.resize(count)
	burn.resize(count)
	blood.resize(count)
	high.resize(count)
	round_shape.resize(count)
	_burning.clear()
	_smoking.clear()
	_blast_queue.clear()
	_structures.clear()
	_art_rows.clear()
	_art_slot.resize(count)
	_art_slot.fill(-1)
	_art_dirty.resize(count)
	_art_dirty.fill(0)
	_art_pending.clear()
	for i in count:
		kind[i] = int(layout[i]["kind"])
		pos[i] = layout[i]["pos"]
		rotation_angle[i] = float(layout[i].get("angle", 0.0))
		axis[i] = Vector2.from_angle(rotation_angle[i])
		state[i] = int(layout[i].get("state", State.INTACT))
		blood[i] = 0
		burn[i] = 0.0
		var k := kind[i]
		half[i] = Vector2(32, 14) if k < Kind.TRUCK else Vector2(42, 16)
		if k >= Kind.RED:
			half[i] = Vector2(5.8, 5.8) if k <= Kind.ACID else Vector2(22, 5)
		if k == Kind.BAGS:
			half[i] = Vector2(12, 12)
		if k == Kind.WOOD:
			half[i] = Vector2(16, 5)
		if k == Kind.STRUCTURE:
			_structures.append(i)
			half[i] = layout[i]["half"]
			var size := Vector2i(half[i] * 2.0)
			_structure_tex[i] = PixelArt.tex("map_roof_%d_%d_%d_%d" % [int(layout[i]["skin"]), size.x, size.y, i % 3])
		else:
			_structure_tex[i] = null
		_extent[i] = axis[i].abs() * half[i].x + axis[i].orthogonal().abs() * half[i].y
		high[i] = 1 if k == Kind.STRUCTURE or k <= Kind.TRUCK or k == Kind.JERSEY or k == Kind.FENCE else 0
		round_shape[i] = 1 if k in [Kind.RED, Kind.ACID, Kind.BAGS] else 0
		hp[i] = 120.0 if k <= Kind.TRUCK else 12.0
		if k <= Kind.TRUCK:
			if state[i] == State.DAMAGED:
				hp[i] = 60.0
				_smoking.append(i)
			elif state[i] == State.BURNING:
				burn[i] = 4.0 + float(i % 3)
				_burning.append(i)
	# Сначала мусор, затем корпуса; один draw call на весь старый атлас O1.
	for layer in 2:
		for i in count:
			if kind[i] != Kind.STRUCTURE and (kind[i] >= Kind.TIRES) == (layer == 0):
				_art_slot[i] = _art_rows.size()
				_art_rows.append(i)
				_mark_art(i)
	_art_buffer.resize(_art_rows.size() * 12)
	if _art:
		_art.instance_count = _art_rows.size()
	grid_w = ceili(rect.size.x / CELL)
	grid_h = ceili(rect.size.y / CELL)
	var n := grid_w * grid_h
	near_head.resize(n)
	blocked.resize(n)
	flow.resize(n)
	_next_flow.resize(n)
	distance.resize(n)
	_distance_build.resize(n)
	_out_distance.resize(n)
	_adjacency.resize(n * 4)
	_clearance.resize(n)
	obstacle_distance.resize(n)
	wall_normal.resize(n)
	_next_anchor.resize(n)
	_next_capacity.resize(n)
	_offsets = PackedInt32Array([-1, 1, -grid_w, grid_w, -grid_w - 1, -grid_w + 1, grid_w - 1, grid_w + 1])
	nav_completed = 0
	_rebuild_serial = 0
	_nav_generation += 1
	_flow_ready = false
	_building = false
	_target_cell = -1
	_nav_cd = 0.0
	rebuild_grid()
	queue_redraw()


## Невидимое тело структуры: общий обход и коллизия, попадания обслуживает сама цель.
func add_body(at: Vector2, radius: float) -> int:
	var i := count
	pos.append(at)
	half.append(Vector2.ONE * radius)
	axis.append(Vector2.RIGHT)
	rotation_angle.append(0.0)
	kind.append(Kind.STRUCTURE)
	state.append(State.INTACT)
	hp.append(INF)
	burn.append(0.0)
	blood.append(0)
	high.append(0) # Не перекрывает луч к боевой цели собственным телом.
	round_shape.append(1)
	_extent.append(Vector2.ONE * radius)
	_structure_tex.append(null)
	_blood_masks.append(null)
	_ray_seen.append(0)
	_art_slot.append(-1)
	_art_dirty.append(0)
	count += 1
	rebuild_grid()
	return i


func remove_body(i: int) -> void:
	if i < 0 or i >= count or state[i] == State.GONE:
		return
	state[i] = State.GONE
	rebuild_grid(true)


func cell_at(p: Vector2) -> int:
	return clampi(int((p.x - arena.position.x) / CELL), 0, grid_w - 1) + clampi(int((p.y - arena.position.y) / CELL), 0, grid_h - 1) * grid_w


func cell_center(c: int) -> Vector2:
	return arena.position + Vector2(float(c % grid_w) + 0.5, float(c / grid_w) + 0.5) * CELL


func rebuild_grid(removed_only := false) -> void:
	nav_revision += 1
	var dirty_rect := Rect2i(0, 0, grid_w, grid_h)
	if removed_only:
		dirty_rect = Rect2i()
		for i in count:
			if _solid_state[i] != state[i] and state[i] == State.GONE:
				var extent := _extent[i] + Vector2.ONE * 48.0
				var lo := Vector2i((pos[i] - extent - arena.position) / CELL).max(Vector2i.ZERO)
				var hi := Vector2i((pos[i] + extent - arena.position) / CELL).min(Vector2i(grid_w - 1, grid_h - 1))
				var area := Rect2i(lo, hi - lo + Vector2i.ONE)
				dirty_rect = area if not dirty_rect.has_area() else dirty_rect.merge(area)
	_solid_state = state.duplicate()
	if not removed_only:
		near_head.fill(-1)
		_link_obj.clear()
		_link_next.clear()
		_nav_layers.clear()
		for i in count:
			if (kind[i] >= Kind.TIRES and kind[i] != Kind.STRUCTURE) or state[i] == State.GONE:
				continue
			var extent := _extent[i] + Vector2.ONE * 42.0
			var lo := Vector2i((pos[i] - extent - arena.position) / CELL).max(Vector2i.ZERO)
			var hi := Vector2i((pos[i] + extent - arena.position) / CELL).min(Vector2i(grid_w - 1, grid_h - 1))
			for y in range(lo.y, hi.y + 1):
				for x in range(lo.x, hi.x + 1):
					var c := x + y * grid_w
					_link_obj.append(i)
					_link_next.append(near_head[c])
					near_head[c] = _link_obj.size() - 1
		for k in 3:
			var points := PackedVector2Array()
			points.resize(blocked.size())
			var valid := PackedByteArray()
			valid.resize(blocked.size())
			var edges := PackedByteArray()
			edges.resize(blocked.size())
			var capacity := PackedFloat32Array()
			capacity.resize(blocked.size())
			var weights := PackedByteArray()
			weights.resize(blocked.size() * 8)
			_nav_layers[k] = {"points": points, "valid": valid, "edges": edges, "weights": weights, "capacity": capacity, "ready": false, "flow": PackedVector2Array(), "anchor": PackedVector2Array(), "distance": PackedInt32Array(), "path_capacity": PackedFloat32Array()}
	# Усечённое поле расстояния: точная граница OBB/кругов в полосе 40 ед.
	# В дальней зоне расстояние насыщено; разрушение обновляет только эту полосу.
	for y in range(dirty_rect.position.y, dirty_rect.end.y):
		for x in range(dirty_rect.position.x, dirty_rect.end.x):
			var c := x + y * grid_w
			var center := cell_center(c)
			var gap := 40.0
			var normal := Vector2.ZERO
			var link := near_head[c]
			while link != -1:
				var i := _link_obj[link]
				link = _link_next[link]
				if state[i] == State.GONE:
					continue
				var q := _local(i, center)
				var v := q.abs() - half[i]
				var d := q.length() - half[i].x if round_shape[i] == 1 else v.max(Vector2.ZERO).length() + minf(maxf(v.x, v.y), 0.0)
				if d < gap:
					gap = d
					var n := q.normalized() if round_shape[i] == 1 else (q - q.clamp(-half[i], half[i])).normalized()
					if n == Vector2.ZERO:
						n = Vector2(signf(q.x), 0) if v.x > v.y else Vector2(0, signf(q.y))
					normal = axis[i] * n.x + axis[i].orthogonal() * n.y
			obstacle_distance[c] = gap
			wall_normal[c] = normal
			_clearance[c] = gap - CELL * 0.707107 - 0.025
	for k in 3:
		var layer: Dictionary = _nav_layers[k]
		var points: PackedVector2Array = layer["points"]
		var valid: PackedByteArray = layer["valid"]
		var edges: PackedByteArray = layer["edges"]
		var weights: PackedByteArray = layer["weights"]
		var capacity: PackedFloat32Array = layer["capacity"]
		var r: float = CLASS_RADII[k]
		for y in range(dirty_rect.position.y, dirty_rect.end.y):
			for x in range(dirty_rect.position.x, dirty_rect.end.x):
				var c := x + y * grid_w
				var center := cell_center(c)
				var at := center
				# Перекрывающиеся подшаги сохраняют диагональный проход у угла клетки.
				var lo := center - Vector2.ONE * (CELL * 0.9)
				var hi := center + Vector2.ONE * (CELL * 0.9)
				if obstacle_distance[c] < r + 0.04:
					# Подшаг внутри клетки сохраняет узкую щель при смещении сетки.
					for attempt in 8:
						at = resolve(at, r + 0.025).clamp(lo, hi)
				_sample_capacity = INF
				if near_head[c] != -1:
					at = _corridor_center(at, lo, hi, r)
				capacity[c] = _sample_capacity
				valid[c] = 1 if at.is_finite() and arena.grow(-r).has_point(at) and not contains(at, r + 0.01) else 0
				points[c] = at
		var edge_rect := dirty_rect.grow(1).intersection(Rect2i(0, 0, grid_w, grid_h))
		for y in range(edge_rect.position.y, edge_rect.end.y):
			for x in range(edge_rect.position.x, edge_rect.end.x):
				var c := x + y * grid_w
				edges[c] = 0
				if valid[c] == 0:
					continue
				for d in 8:
					var q: Vector2i = Vector2i(x, y) + STEPS[d]
					if q.x < 0 or q.x >= grid_w or q.y < 0 or q.y >= grid_h:
						continue
					var next := c + _offsets[d]
					if valid[next] == 0:
						continue
					# Диагональ проверяется диском тела по всему отрезку: угол не срезается.
					# У уточнённых точек боковые центры могут лежать внутри стены.
					# Запас покрывает выход уточнённых точек за исходную клетку.
					if minf(_clearance[c], _clearance[next]) >= r + CELL * 1.5 or _body_clear(points[c], points[next], r):
						edges[c] |= 1 << d
						weights[c * 8 + d] = maxi(1, roundi(points[c].distance_to(points[next]) * 1.25))
		layer["points"] = points
		layer["valid"] = valid
		layer["edges"] = edges
		layer["weights"] = weights
		layer["capacity"] = capacity
		_nav_layers[k] = layer
	var ordinary: Dictionary = _nav_layers[1]
	var valid: PackedByteArray = ordinary["valid"]
	var edges: PackedByteArray = ordinary["edges"]
	for y in range(dirty_rect.position.y, dirty_rect.end.y):
		for x in range(dirty_rect.position.x, dirty_rect.end.x):
			var c := x + y * grid_w
			blocked[c] = 1 - valid[c]
	# Четыре связи остаются для независимых проверок и ограниченных маршрутов HD1.
	var adjacency_rect := dirty_rect.grow(1).intersection(Rect2i(0, 0, grid_w, grid_h))
	for y in range(adjacency_rect.position.y, adjacency_rect.end.y):
		for x in range(adjacency_rect.position.x, adjacency_rect.end.x):
			var c := x + y * grid_w
			for d in 4:
				_adjacency[c * 4 + d] = c + _offsets[d] if edges[c] & (1 << d) else -1
	_building = false
	_dirty = true
	queue_redraw()


## Баланс двух встречных стенок считается только при перестройке клетки.
func _corridor_center(at: Vector2, lo: Vector2, hi: Vector2, r: float) -> Vector2:
	# Продолжаем среднюю линию параллельных граней до входа в проход.
	# Равные расстояния до скруглённых углов сами по себе дают излом у входа.
	var first := near_head[cell_at(at)]
	while first != -1:
		var i := _link_obj[first]
		var second := _link_next[first]
		first = second
		if state[i] == State.GONE or round_shape[i] != 0:
			continue
		while second != -1:
			var j := _link_obj[second]
			second = _link_next[second]
			if state[j] == State.GONE or round_shape[j] != 0 or absf(axis[i].dot(axis[j])) < 0.9999:
				continue
			for dim in 2:
				var normal := axis[i] if dim == 0 else axis[i].orthogonal()
				var span := (pos[j] - pos[i]).dot(normal)
				var gap := absf(span) - half[i][dim] - half[j][dim]
				if gap < r * 2.0 + 0.05 or gap > r * 2.0 + CELL * 1.5:
					continue
				var middle := (pos[i].dot(normal) + signf(span) * half[i][dim] + pos[j].dot(normal) - signf(span) * half[j][dim]) * 0.5
				var centered := (at + normal * (middle - at.dot(normal))).clamp(lo, hi)
				if not contains(centered, r + 0.025):
					_sample_capacity = gap * 0.5
					return centered
	for attempt in 4:
		var gaps := PackedFloat32Array()
		var normals := PackedVector2Array()
		var link := near_head[cell_at(at)]
		while link != -1:
			var i := _link_obj[link]
			link = _link_next[link]
			if state[i] == State.GONE:
				continue
			var q := _local(i, at)
			var v := q.abs() - half[i]
			var gap := q.length() - half[i].x if round_shape[i] == 1 else v.max(Vector2.ZERO).length() + minf(maxf(v.x, v.y), 0.0)
			if gap > r + CELL * 1.5:
				continue
			var n := q.normalized() if round_shape[i] == 1 else (q - q.clamp(-half[i], half[i])).normalized()
			if n == Vector2.ZERO:
				continue
			gaps.append(gap)
			normals.append(axis[i] * n.x + axis[i].orthogonal() * n.y)
		var adjusted := false
		for a in gaps.size():
			for b in range(a + 1, gaps.size()):
				if normals[a].dot(normals[b]) < 0.8:
					_sample_capacity = minf(_sample_capacity, (gaps[a] + gaps[b]) * 0.5)
					var gradient := normals[a] - normals[b]
					at = (at + gradient * ((gaps[b] - gaps[a]) / gradient.length_squared())).clamp(lo, hi)
					adjusted = true
		if not adjusted:
			break
	return at


func _local(i: int, p: Vector2) -> Vector2:
	var rel := p - pos[i]
	if rotation_angle[i] == 0.0:
		return Vector2(rel.x, -rel.y)
	var a := axis[i]
	return Vector2(rel.dot(a), rel.dot(a.orthogonal()))


func _overlaps(i: int, p: Vector2, r: float) -> bool:
	if round_shape[i] == 1:
		return pos[i].distance_squared_to(p) < (half[i].x + r) * (half[i].x + r)
	var q := _local(i, p).abs() - half[i]
	return q.max(Vector2.ZERO).length_squared() < r * r


func contains(p: Vector2, r := 0.1) -> bool:
	var link := near_head[cell_at(p)]
	while link != -1:
		var i := _link_obj[link]
		if state[i] != State.GONE and _overlaps(i, p, r):
			return true
		link = _link_next[link]
	return false


## Узкая фаза только в занятых окрестностях; повтор нужен в стыке двух блоков.
func resolve(p: Vector2, r: float) -> Vector2:
	var started := Time.get_ticks_usec() if profile_enabled else 0
	if profile_enabled:
		resolve_calls += 1
	for pass_index in 4:
		var changed := false
		var link := near_head[cell_at(p)]
		while link != -1:
			var i := _link_obj[link]
			link = _link_next[link]
			if state[i] == State.GONE:
				continue
			# AABB отсеивает дальнюю часть расширенного бакета крови.
			var rel := (p - pos[i]).abs() - _extent[i]
			if rel.x >= r + 0.02 or rel.y >= r + 0.02:
				continue
			var q := _local(i, p)
			if round_shape[i] == 1:
				var distance := q.length()
				var reach := half[i].x + r + 0.02
				if distance >= reach:
					continue
				q = q / distance * reach if distance > 0.0001 else Vector2(reach, 0)
			else:
				var closest := q.clamp(-half[i], half[i])
				var away := q - closest
				var d2 := away.length_squared()
				if d2 >= (r + 0.02) * (r + 0.02):
					continue
				if d2 > 0.000001:
					q = closest + away * ((r + 0.02) / sqrt(d2))
				else:
					var depth := half[i] - q.abs()
					if depth.x < depth.y:
						q.x = (half[i].x + r + 0.02) * (1.0 if q.x >= 0 else -1.0)
					else:
						q.y = (half[i].y + r + 0.02) * (1.0 if q.y >= 0 else -1.0)
			p = pos[i] + axis[i] * q.x + axis[i].orthogonal() * q.y
			changed = true
		if not changed:
			break
	if profile_enabled:
		resolve_usec += Time.get_ticks_usec() - started
	return p


## Подшаги исключают туннелирование рывка, тарана и сильного отброса.
func move_actor(from: Vector2, to: Vector2, r: float) -> Vector2:
	var started := Time.get_ticks_usec() if profile_enabled else 0
	if profile_enabled:
		move_calls += 1
	# Обычный тик — один resolve; рывок и сильный отброс — подшаги.
	var steps := maxi(1, ceili(from.distance_to(to) / maxf(4.0, r * 0.8)))
	var step := (to - from) / float(steps)
	var p := from
	for j in steps:
		p = resolve(p + step, r)
	if profile_enabled:
		move_usec += Time.get_ticks_usec() - started
	return p


func free_point(p: Vector2, r := 8.0) -> Vector2:
	p = p.clamp(arena.position + Vector2.ONE * (r + 4.0), arena.end - Vector2.ONE * (r + 4.0))
	if not contains(p, r):
		return p
	var c := Vector2i((p - arena.position) / CELL)
	for ring in 32:
		for dy in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if absi(dx) != ring and absi(dy) != ring:
					continue
				var q := c + Vector2i(dx, dy)
				if q.x < 1 or q.y < 1 or q.x >= grid_w - 1 or q.y >= grid_h - 1:
					continue
				var at := cell_center(q.x + q.y * grid_w)
				if not contains(at, r):
					return at
	return arena.get_center()


## Сегмент против OBB/круга. Возвращает долю луча или INF.
func _segment(i: int, from: Vector2, to: Vector2, radius: float) -> float:
	var p := _local(i, from)
	var v := _local(i, to) - p
	if round_shape[i] == 1:
		var rr := half[i].x + radius
		var a := v.length_squared()
		var b := p.dot(v)
		var c := p.length_squared() - rr * rr
		if c <= 0.0:
			return 0.0
		var discriminant := b * b - a * c
		if a <= 0.000001 or discriminant < 0.0:
			return INF
		var t := (-b - sqrt(discriminant)) / a
		return t if t >= 0.0 and t <= 1.0 else INF
	var extent := half[i] + Vector2.ONE * radius
	var low := 0.0
	var upper := 1.0
	for dim in 2:
		if absf(v[dim]) < 0.000001:
			if absf(p[dim]) > extent[dim]:
				return INF
		else:
			var a := (-extent[dim] - p[dim]) / v[dim]
			var b := (extent[dim] - p[dim]) / v[dim]
			low = maxf(low, minf(a, b))
			upper = minf(upper, maxf(a, b))
			if low > upper:
				return INF
	return low


## Для коротких пуль достаточно бакета середины; длинные лучи проходят сетку.
func ray_hit(from: Vector2, to: Vector2, only_high := false, radius := 1.0, ignore := -1) -> int:
	var started := Time.get_ticks_usec() if profile_enabled else 0
	if profile_enabled:
		ray_calls += 1
	_ray_stamp += 1
	var steps := maxi(1, ceili(from.distance_to(to) / CELL))
	var best := -1
	var best_t := INF
	var previous := -1
	for step_index in steps + 1:
		var c := cell_at(from.lerp(to, float(step_index) / float(steps)))
		if c == previous:
			continue
		previous = c
		var link := near_head[c]
		while link != -1:
			var i := _link_obj[link]
			link = _link_next[link]
			if _ray_seen[i] == _ray_stamp:
				continue
			_ray_seen[i] = _ray_stamp
			if i == ignore or state[i] == State.GONE or (only_high and high[i] == 0):
				continue
			if not only_high and high[i] == 0 and kind[i] != Kind.RED and kind[i] != Kind.ACID:
				continue
			var t := _segment(i, from, to, radius)
			if t < best_t:
				best_t = t
				best = i
	if profile_enabled:
		ray_usec += Time.get_ticks_usec() - started
	return best


func line_clear(from: Vector2, to: Vector2) -> bool:
	return ray_hit(from, to, true, 0.0) == -1


## Класс и четыре выборки общего поля; ни маршрутов, ни лучей у тела.
func radius_class(r: float) -> int:
	return 0 if r <= 4.625 else (1 if r <= 5.425 else 2)


func steering(p: Vector2, direct: Vector2, r := 5.0, _target := Vector2.INF) -> Vector2:
	var k := radius_class(r)
	var c := cell_at(p)
	for candidate in k:
		if not _nav_layers[candidate]["ready"]:
			continue
		var capacity: PackedFloat32Array = _nav_layers[candidate]["path_capacity"]
		if capacity[c] < INF and capacity[c] >= r + 0.025:
			k = candidate
			break
	var layer: Dictionary = _nav_layers[k]
	if not layer["ready"]:
		return slide_wall(p, direct, r)
	var dirs: PackedVector2Array = layer["flow"]
	var anchors: PackedVector2Array = layer["anchor"]
	var points: PackedVector2Array = layer["points"]
	var costs: PackedInt32Array = layer["distance"]
	if costs[c] == NO_PATH:
		return slide_wall(p, direct, r)
	if p.distance_squared_to(_flow_target) < CELL * CELL * 2.0:
		return slide_wall(p, direct, r)
	var direction := dirs[c]
	if near_head[c] != -1:
		# Уточнённая точка ведёт в щель; толпа не тянет тело к центру кузова.
		var on_path := Geometry2D.get_closest_point_to_segment(p, points[c], anchors[c])
		direction = (direction + (on_path - p) * 0.25).normalized()
	else:
		var grid := (p - arena.position) / CELL - Vector2.ONE * 0.5
		var x := clampi(floori(grid.x), 0, grid_w - 2)
		var y := clampi(floori(grid.y), 0, grid_h - 2)
		var f := (grid - Vector2(x, y)).clamp(Vector2.ZERO, Vector2.ONE)
		var a := x + y * grid_w
		var smooth := dirs[a].lerp(dirs[a + 1], f.x).lerp(dirs[a + grid_w].lerp(dirs[a + grid_w + 1], f.x), f.y)
		if smooth.dot(direction) > 0.0:
			direction = smooth.normalized()
	return slide_wall(p, direction, r, true)


func slide_wall(p: Vector2, direction: Vector2, r: float, hold_contour := false) -> Vector2:
	var c := cell_at(p)
	if obstacle_distance[c] > r + CELL:
		return direction
	var normal := wall_normal[c]
	var gap := obstacle_distance[c] + normal.dot(p - cell_center(c))
	var into := direction.dot(normal)
	# Поле держит контур; общий маршрут пачки разрешает возвращение наружу к отрезку.
	if gap < r + 1.0 and into < (0.8 if hold_contour else 0.0):
		var tangent := direction - normal * into
		if tangent.length_squared() > 0.001:
			return tangent.normalized()
	return direction


func flow_steering(p: Vector2, direct: Vector2) -> Vector2:
	return steering(p, direct)


func _heap_push(value: int) -> void:
	# Вес ребра не больше 80: кольцевая очередь Дайла без двоичной кучи.
	var cost := value / blocked.size()
	_buckets[cost % 97].append(value)
	_bucket_count += 1


func _heap_pop() -> int:
	while _buckets[_bucket_cost % 97].is_empty():
		_bucket_cost += 1
	_bucket_count -= 1
	return _buckets[_bucket_cost % 97].pop_back()


func _begin_class() -> void:
	var layer: Dictionary = _nav_layers[_build_class]
	var valid: PackedByteArray = layer["valid"]
	var c := _pending_target
	if valid[c] == 0:
		c = cell_at(free_point(cell_center(c), CLASS_RADII[_build_class] + 0.1))
	_distance_build.fill(NO_PATH)
	_local_build = layer["ready"] and not _unbounded
	if _local_build:
		_next_flow = (layer["flow"] as PackedVector2Array).duplicate()
		_next_anchor = (layer["anchor"] as PackedVector2Array).duplicate()
		_next_capacity = (layer["path_capacity"] as PackedFloat32Array).duplicate()
		_out_distance = (layer["distance"] as PackedInt32Array).duplicate()
	else:
		_next_flow.fill(Vector2.ZERO)
		_next_anchor.fill(cell_center(c))
		_next_capacity.fill(INF)
		_out_distance.fill(NO_PATH)
	_next_flow[c] = Vector2.ZERO
	_next_anchor[c] = cell_center(c)
	_next_capacity[c] = INF
	_distance_build[c] = 0
	_out_distance[c] = 0
	_buckets.clear()
	for j in 97:
		_buckets.append([])
	_bucket_cost = 0
	_bucket_count = 0
	_heap_push(c)


## Dijkstra общий на цель и класс; старые поля работают до атомарной смены слоя.
func navigation_step(delta: float, target: Vector2) -> void:
	if threaded_nav:
		_navigation_threaded(delta, target)
		return
	var start := Time.get_ticks_usec()
	_nav_cd -= delta
	var c := cell_at(target)
	if not _building and _nav_cd <= 0.0 and (_dirty or _target_cell < 0 or absi(c % grid_w - _target_cell % grid_w) > 2 or absi(c / grid_w - _target_cell / grid_w) > 2):
		_pending_target = c
		# Вся карта — после изменения препятствий и раз в 8 циклов; иначе окрестность игрока:
		# основной класс каждый цикл, мелкий и крупный — раз в три.
		_unbounded = _dirty or not _flow_ready or _rebuild_serial % 8 == 0
		var all_classes := _unbounded or _rebuild_serial % 3 == 0
		_rebuild_serial += 1
		_build_order = PackedInt32Array([1, 0, 2]) if all_classes else PackedInt32Array([1])
		_build_pos = 0
		_dirty = false
		_nav_cd = 0.15
		_build_class = _build_order[0]
		_building = true
		_begin_class()
	if _building:
		var layer: Dictionary = _nav_layers[_build_class]
		var edges: PackedByteArray = layer["edges"]
		var weights: PackedByteArray = layer["weights"]
		var points: PackedVector2Array = layer["points"]
		var capacity: PackedFloat32Array = layer["capacity"]
		var n := blocked.size()
		for work in FLOW_BUDGET:
			if _bucket_count == 0:
				break
			var entry := _heap_pop()
			var at := entry % n
			var cost := entry / n
			if cost != _distance_build[at]:
				continue
			if _local_build and cost > LOCAL_COST:
				_bucket_count = 0
				break
			for d in 8:
				if edges[at] & (1 << d) == 0:
					continue
				var next := at + _offsets[d]
				var nd := cost + weights[at * 8 + d]
				if nd < _distance_build[next]:
					_distance_build[next] = nd
					_out_distance[next] = nd
					_next_flow[next] = (points[at] - points[next]).normalized()
					_next_anchor[next] = points[at]
					_next_capacity[next] = minf(_next_capacity[at], minf(capacity[at], capacity[next]))
					_heap_push(nd * n + next)
		if _bucket_count == 0:
			layer["flow"] = _next_flow.duplicate()
			layer["anchor"] = _next_anchor.duplicate()
			layer["distance"] = _out_distance.duplicate()
			layer["path_capacity"] = _next_capacity.duplicate()
			layer["ready"] = true
			_nav_layers[_build_class] = layer
			if _build_class == 1:
				flow = layer["flow"]
				distance = layer["distance"]
				_target_cell = _pending_target
				_flow_target = cell_center(_target_cell)
			_build_pos += 1
			if _build_pos >= _build_order.size():
				_building = false
				if _nav_layers[0]["ready"] and _nav_layers[1]["ready"] and _nav_layers[2]["ready"]:
					_flow_ready = true
				nav_completed += 1
			else:
				_build_class = _build_order[_build_pos]
				_begin_class()
	var spent := Time.get_ticks_usec() - start
	nav_worst_usec = maxi(nav_worst_usec, spent)
	nav_total_usec += spent
	nav_calls += 1



## Фоновый пересчёт: три задачи (по классу радиуса) считают полный Дейкстра по всей карте параллельно;
## основной поток раз в тик проверяет готовность и атомарно подменяет слои.
func _navigation_threaded(delta: float, target: Vector2) -> void:
	var start := Time.get_ticks_usec()
	_nav_cd -= delta
	if not _task_ids.is_empty():
		for id in _task_ids:
			if not WorkerThreadPool.is_task_completed(id):
				_note_nav_time(start)
				return
		for id in _task_ids:
			WorkerThreadPool.wait_for_task_completion(id)
		_task_ids.clear()
		if _task_generation == _nav_generation:
			for k in 3:
				var layer: Dictionary = _nav_layers[k]
				var out: Dictionary = _task_out[k]
				layer["flow"] = out["flow"]
				layer["anchor"] = out["anchor"]
				layer["distance"] = out["distance"]
				layer["path_capacity"] = out["path_capacity"]
				layer["ready"] = true
				_nav_layers[k] = layer
			flow = _nav_layers[1]["flow"]
			distance = _nav_layers[1]["distance"]
			_target_cell = _task_target
			_flow_target = cell_center(_target_cell)
			_flow_ready = true
			nav_completed += 1
	var c := cell_at(target)
	if _nav_cd <= 0.0 and (_dirty or _target_cell < 0 or c != _target_cell):
		_dirty = false
		_nav_cd = 0.05
		_task_target = c
		_task_generation = _nav_generation
		_task_out = []
		for k in 3:
			var layer: Dictionary = _nav_layers[k]
			var valid: PackedByteArray = layer["valid"]
			var seed_cell := c
			if valid[seed_cell] == 0:
				seed_cell = cell_at(free_point(cell_center(seed_cell), CLASS_RADII[k] + 0.1))
			var out := {}
			_task_out.append(out)
			var job := _flow_layer.bind(layer["edges"], layer["weights"], layer["points"], layer["capacity"], _offsets, seed_cell, cell_center(seed_cell), out)
			_task_ids.append(WorkerThreadPool.add_task(job, false, "flow field"))
	_note_nav_time(start)


func _note_nav_time(start: int) -> void:
	var spent := Time.get_ticks_usec() - start
	nav_worst_usec = maxi(nav_worst_usec, spent)
	nav_total_usec += spent
	nav_calls += 1


## Чистая функция для потока: только аргументы, без узлов и полей объекта. Повторяет пошаговый Дейкстра
## (кольцевая очередь Дайла на 97 корзин; вес ребра ≤ 80) целиком за один вызов.
static func _flow_layer(edges: PackedByteArray, weights: PackedByteArray, points: PackedVector2Array, capacity: PackedFloat32Array,
		offsets: PackedInt32Array, seed_cell: int, seed_point: Vector2, out: Dictionary) -> void:
	var n := edges.size()
	var dist := PackedInt32Array()
	dist.resize(n)
	dist.fill(NO_PATH)
	var dirs := PackedVector2Array()
	dirs.resize(n)
	var anchors := PackedVector2Array()
	anchors.resize(n)
	anchors.fill(seed_point)
	var caps := PackedFloat32Array()
	caps.resize(n)
	caps.fill(INF)
	var buckets: Array[Array] = []
	for j in 97:
		buckets.append([])
	dist[seed_cell] = 0
	buckets[0].append(seed_cell)
	var count := 1
	var cost := 0
	while count > 0:
		var bucket: Array = buckets[cost % 97]
		if bucket.is_empty():
			cost += 1
			continue
		var at: int = bucket.pop_back()
		count -= 1
		if dist[at] != cost:
			continue
		var mask := edges[at]
		for d in 8:
			if mask & (1 << d) == 0:
				continue
			var next := at + offsets[d]
			var nd := cost + weights[at * 8 + d]
			if nd < dist[next]:
				dist[next] = nd
				dirs[next] = (points[at] - points[next]).normalized()
				anchors[next] = points[at]
				caps[next] = minf(caps[at], minf(capacity[at], capacity[next]))
				buckets[nd % 97].append(next)
				count += 1
	out["flow"] = dirs
	out["anchor"] = anchors
	out["distance"] = dist
	out["path_capacity"] = caps


func _exit_tree() -> void:
	for id in _task_ids:
		WorkerThreadPool.wait_for_task_completion(id)
	_task_ids.clear()

func connected() -> bool:
	return unreachable_cell() == -1


func unreachable_cell() -> int:
	# Независимый flood-fill для проверки профиля, без изменения активного поля.
	var seen := PackedByteArray()
	seen.resize(blocked.size())
	var todo := PackedInt32Array([cell_at(arena.get_center())])
	seen[todo[0]] = 1
	var head := 0
	while head < todo.size():
		var c := todo[head]
		head += 1
		for offset: int in [-1, 1, -grid_w, grid_w]:
			var next := c + offset
			if next < 0 or next >= blocked.size() or (offset == -1 and c % grid_w == 0) or (offset == 1 and c % grid_w == grid_w - 1):
				continue
			if blocked[next] == 0 and seen[next] == 0:
				seen[next] = 1
				todo.append(next)
	for c in blocked.size():
		if blocked[c] == 0 and seen[c] == 0:
			return c
	return -1


func damage(i: int, amount: float, fire := false) -> void:
	if i < 0 or i >= count or kind[i] > Kind.ACID or state[i] >= State.BURNING:
		return
	hp[i] -= amount
	if hp[i] <= 60.0:
		if state[i] == State.INTACT and kind[i] <= Kind.TRUCK:
			_smoking.append(i)
		state[i] = State.DAMAGED
	if hp[i] <= 0.0 or (fire and kind[i] <= Kind.TRUCK):
		if kind[i] <= Kind.TRUCK:
			var smoking_index := _smoking.find(i)
			if smoking_index >= 0:
				_smoking.remove_at(smoking_index)
			state[i] = State.BURNING
			burn[i] = 4.0 + float(i % 3)
			_burning.append(i)
			_fx.queue_redraw()
		else:
			state[i] = State.BURNING
			_blast_queue.append(i)
	_mark_art(i)
	queue_redraw()


func blast(at: Vector2, radius: float, amount: float) -> void:
	for i in count:
		if state[i] == State.GONE:
			continue
		var d2 := pos[i].distance_squared_to(at)
		if d2 > (radius + half[i].x) * (radius + half[i].x):
			continue
		if kind[i] >= Kind.TIRES and kind[i] != Kind.STRUCTURE:
			var away := (pos[i] - at).normalized()
			pos[i] += away * 12.0
			rotation_angle[i] += 0.7
			axis[i] = Vector2.from_angle(rotation_angle[i])
			_mark_art(i)
		elif kind[i] <= Kind.ACID:
			damage(i, amount * (1.0 - 0.5 * minf(sqrt(d2) / radius, 1.0)), amount >= 100.0)
	queue_redraw()


func charge(at: Vector2, radius: float) -> bool:
	var stopped := false
	var dirty := false
	var link := near_head[cell_at(at)]
	while link != -1:
		var i := _link_obj[link]
		link = _link_next[link]
		if state[i] == State.GONE or not _overlaps(i, at, radius):
			continue
		if kind[i] == Kind.BAGS or kind[i] == Kind.WOOD:
			state[i] = State.GONE
			_mark_art(i)
			dirty = true
		else:
			damage(i, 180.0, true)
			stopped = true
	if dirty:
		rebuild_grid(true)
	return stopped


## Брызги летят к поверхности по направлению удара, каждый след хранится отдельно.
func splatter(at: Vector2, dir := Vector2.ZERO, _death := 0, _facing := 0.0, _variant := 0) -> void:
	var link := near_head[cell_at(at)]
	while link != -1:
		var i := _link_obj[link]
		link = _link_next[link]
		if (kind[i] >= Kind.TIRES and kind[i] != Kind.STRUCTURE) or state[i] == State.GONE:
			continue
		if _overlaps(i, at, 30.0):
			var local := (at - pos[i]).rotated(-rotation_angle[i])
			var direction := dir.rotated(-rotation_angle[i]).normalized()
			if direction != Vector2.ZERO and not Rect2(-half[i], half[i] * 2.0).has_point(local):
				var enter := 0.0
				var leave := 30.0
				for dimension in 2:
					if absf(direction[dimension]) < 0.0001:
						if absf(local[dimension]) > half[i][dimension]:
							leave = -1.0
					else:
						var a := (-half[i][dimension] - local[dimension]) / direction[dimension]
						var b := (half[i][dimension] - local[dimension]) / direction[dimension]
						enter = maxf(enter, minf(a, b))
						leave = minf(leave, maxf(a, b))
				if enter > leave:
					continue
				local += direction * enter
			_add_blood(i, local.clamp(-half[i] + Vector2.ONE, half[i] - Vector2.ONE), direction, 1.0)


## Капля при падении оставляет локальное пятно, старые следы не освежает.
func stain_blood(at: Vector2, r: float) -> void:
	var link := near_head[cell_at(at)]
	while link != -1:
		var i := _link_obj[link]
		link = _link_next[link]
		if (kind[i] >= Kind.TIRES and kind[i] != Kind.STRUCTURE) or state[i] == State.GONE:
			continue
		if _overlaps(i, at, r):
			var local := (at - pos[i]).rotated(-rotation_angle[i])
			_add_blood(i, local.clamp(-half[i] + Vector2.ONE, half[i] - Vector2.ONE), Vector2.ZERO, clampf(r / 7.0, 0.4, 1.0))


func _add_blood(i: int, at: Vector2, direction: Vector2, size: float) -> void:
	if _blood_at.size() >= BLOOD_LIMIT or blood[i] >= BLOOD_PER_OBJECT:
		return
	# тело без текстуры постройки (узел кампании, add_body) — пятна не рисуем
	if kind[i] == Kind.STRUCTURE and _structure_tex[i] == null and not hive_skin:
		return
	# В одной точке не растим неограниченную стопку одинаковых декалей.
	for j in _blood_at.size():
		if _blood_object[j] == i and _blood_at[j].distance_squared_to(at) < 4.0:
			return
	var serial := _blood_at.size()
	_blood_object.append(i)
	_blood_at.append(at)
	_blood_angle.append(direction.angle() if direction != Vector2.ZERO else float(serial) * 2.39996)
	_blood_size.append(Vector2(6.0 + float(serial % 4), 3.0 + float(serial % 3)) * size)
	_blood_time.append(_blood_clock)
	blood[i] += 1
	blood_events += 1
	var batch := serial / BLOOD_BATCH
	if batch == _blood_meshes.size():
		_blood_meshes.append(ArrayMesh.new())
		_blood_dirty.append(0)
		_blood_built.append(serial)
		_blood_vertices.append(PackedVector2Array())
		_blood_colors.append(PackedColorArray())
		_blood_times.append(PackedVector2Array())
		_blood_indices.append(PackedInt32Array())
	_blood_dirty[batch] = maxi(_blood_dirty[batch], 1)


## Общие пакеты пиксельных декалей. Альфа кузова обрезается один раз при попадании.
func _build_blood(batch: int) -> void:
	# Старые пиксели уже обрезаны; пересборка нужна только при смене корпуса.
	if _blood_dirty[batch] == 2:
		_blood_vertices[batch] = PackedVector2Array()
		_blood_colors[batch] = PackedColorArray()
		_blood_times[batch] = PackedVector2Array()
		_blood_indices[batch] = PackedInt32Array()
		_blood_built[batch] = batch * BLOOD_BATCH
	var vertices := _blood_vertices[batch]
	var colors := _blood_colors[batch]
	var times := _blood_times[batch]
	var indices := _blood_indices[batch]
	var end := mini((batch + 1) * BLOOD_BATCH, _blood_at.size())
	for j in range(_blood_built[batch], end):
		var i := _blood_object[j]
		if state[i] == State.GONE:
			continue
		if kind[i] == Kind.STRUCTURE and _blood_masks[i] == null:
			_blood_masks[i] = (hive_skin if hive_skin else _structure_tex[i]).get_image()
		var bounds := Rect2(_blood_at[j] - Vector2.ONE * _blood_size[j].x * 1.5, Vector2.ONE * _blood_size[j].x * 3.0)
		var cosine := cos(_blood_angle[j])
		var sine := sin(_blood_angle[j])
		var right := ceili(bounds.end.x)
		for y in range(floori(bounds.position.y), ceili(bounds.end.y)):
			var start := right
			for x in range(floori(bounds.position.x), right + 1):
				var inside := false
				if x < right:
					var p := Vector2(x, y) + Vector2.ONE * 0.5
					var offset := p - _blood_at[j]
					var q := Vector2(offset.x * cosine + offset.y * sine, offset.y * cosine - offset.x * sine) / _blood_size[j]
					var noise := posmod(x * 73 + y * 151 + j * 199 + x * y * 31, 101)
					var radius_squared := q.length_squared()
					var edge := 0.65 + float(noise) * 0.0035
					inside = (radius_squared <= edge * edge or (radius_squared <= 1.8225 and noise >= 97)) and _blood_pixel_inside(i, p)
				if inside:
					start = mini(start, x)
					continue
				if start == right:
					continue
				# Соседние пиксели строки — один прямоугольник, без геометрии на каждый пиксель.
				var base := vertices.size()
				for corner: Vector2 in [Vector2(start, y), Vector2(x, y), Vector2(x, y + 1), Vector2(start, y + 1)]:
					vertices.append(pos[i] + corner.rotated(rotation_angle[i]))
					colors.append(Color(0.8, 1.0, 1.0, 0.9))
					times.append(Vector2(_blood_time[j], 0))
				indices.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))
				start = right
	_blood_vertices[batch] = vertices
	_blood_colors[batch] = colors
	_blood_times[batch] = times
	_blood_indices[batch] = indices
	_blood_built[batch] = end
	var mesh := _blood_meshes[batch]
	mesh.clear_surfaces()
	if not vertices.is_empty():
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_TEX_UV] = times
		arrays[Mesh.ARRAY_INDEX] = indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_blood_dirty[batch] = 0


func _blood_pixel_inside(i: int, p: Vector2) -> bool:
	var uv := p / (half[i] * 2.0) + Vector2.ONE * 0.5 if kind[i] == Kind.STRUCTURE else p / Vector2(96, 48) + Vector2.ONE * 0.5
	if uv.x <= 0.0 or uv.y <= 0.0 or uv.x >= 1.0 or uv.y >= 1.0:
		return false
	if kind[i] != Kind.STRUCTURE and _atlas_mask == null:
		_atlas_mask = _atlas.get_image()
	var image := _blood_masks[i] if kind[i] == Kind.STRUCTURE else _atlas_mask
	var pixel := Vector2i(uv * Vector2(image.get_size()))
	if kind[i] != Kind.STRUCTURE:
		var tile := _tile(i)
		pixel = Vector2i(Vector2(tile % 8, tile / 8) * ART_CELL + uv * ART_CELL)
	return image.get_pixelv(pixel).a > 0.9


func _draw_blood() -> void:
	for mesh in _blood_meshes:
		if mesh.get_surface_count() > 0:
			_blood_node.draw_mesh(mesh, null)


func _physics_process(delta: float) -> void:
	if player:
		navigation_step(delta, player.global_position)
	_fire_tick -= delta
	var fire_tick := _fire_tick <= 0.0
	if fire_tick:
		_fire_tick = 0.25
	for n in range(_burning.size() - 1, -1, -1):
		var i := _burning[n]
		burn[i] -= delta
		if burn[i] <= 0.0:
			_blast_queue.append(i)
			_burning.remove_at(n)
		elif fire_tick and horde:
			for j in horde.query_radius(pos[i], half[i].x + 18.0):
				if _overlaps(i, horde.pos[j], 18.0):
					horde.ignite(j, 6.0, 2.0)
	# Снимок FIFO: цепь не рекурсивна, максимум четыре детонации за тик.
	var n := mini(4, _blast_queue.size())
	for j in n:
		var i := _blast_queue[0]
		_blast_queue.remove_at(0)
		_detonate(i)


func _detonate(i: int) -> void:
	var car := kind[i] <= Kind.TRUCK
	state[i] = State.WRECK if car else State.GONE
	detonations += 1
	if kind[i] == Kind.ACID:
		if hazards:
			hazards.acid_pool(pos[i], 32.0, 8.0, 6.0)
	else:
		var radius := CAR_RADIUS if car else BARREL_RADIUS
		var amount := CAR_DAMAGE if car else BARREL_DAMAGE
		if explosions:
			explosions.spawn(pos[i], radius, Explosions.Kind.CAR if car else Explosions.Kind.GRENADE)
		if sfx:
			sfx.play("explosions/grenade", pos[i], -1.0, 0.02)
		if horde:
			var previous := horde.death_override
			horde.death_override = Gore.Death.GIBS
			for j in horde.query_radius(pos[i], radius):
				var offset := horde.pos[j] - pos[i]
				var falloff := 1.0 - 0.5 * minf(offset.length() / radius, 1.0)
				horde.damage(j, amount * falloff, offset.normalized(), 210.0, WeaponDefs.Ammo.STANDARD, false, horde.pos[j], true)
			horde.death_override = previous
		if player and player.global_position.distance_squared_to(pos[i]) < radius * radius:
			player.take_damage(amount)
		blast(pos[i], radius, amount * 3.0)
		splatter(pos[i])
	if not car:
		rebuild_grid(true)
	_mark_art(i)
	queue_redraw()


func _process(delta: float) -> void:
	_visual_tick += delta
	_blood_clock += delta
	_blood_material.set_shader_parameter("blood_clock", _blood_clock)
	var blood_changed := false
	for batch in _blood_meshes.size():
		if _blood_dirty[batch] != 0:
			_build_blood(batch)
			blood_changed = true
	if blood_changed:
		_blood_node.queue_redraw()
	var view := PixelArt.view_rect(self)
	var cell := Vector2i(view.position / 48.0)
	if cell != _view_cell:
		_view_cell = cell
		queue_redraw()
	# Огонь и дым — отдельный слой: корпуса не перерисовываются на каждом кадре анимации.
	if (not _burning.is_empty() or not _smoking.is_empty()) and _visual_tick >= 0.083:
		_visual_tick = 0.0
		_fx.queue_redraw()


func _tile(i: int) -> int:
	var k := kind[i]
	if k <= Kind.TRUCK:
		return k * 4 + mini(state[i], 3)
	if k <= Kind.ACID:
		return 20 + (k - Kind.RED) * 2 + (1 if state[i] == State.DAMAGED else 0)
	return 24 + k - Kind.JERSEY


func _draw() -> void:
	if _atlas == null:
		return
	var started := Time.get_ticks_usec() if profile_enabled else 0
	_sync_art()
	var view := PixelArt.view_rect(self, 130.0)
	for i in _structures:
		if not view.intersects(Rect2(pos[i] - _extent[i], _extent[i] * 2.0)):
			continue
		draw_set_transform(pos[i], rotation_angle[i])
		draw_texture_rect(hive_skin if hive_skin else _structure_tex[i], Rect2(-half[i], half[i] * 2.0), false)
	draw_set_transform(Vector2.ZERO)
	if profile_enabled:
		draw_usec += Time.get_ticks_usec() - started


func _mark_art(i: int) -> void:
	if blood[i] > 0:
		for j in _blood_object.size():
			if _blood_object[j] == i:
				_blood_dirty[j / BLOOD_BATCH] = 2
	if _art_slot[i] < 0 or _art_dirty[i] != 0:
		return
	_art_dirty[i] = 1
	_art_pending.append(i)


func _sync_art() -> void:
	if _art == null or _art_pending.is_empty():
		return
	# Только изменившиеся корпуса; декали не меняют ячейку спрайта.
	for i in _art_pending:
		var slot := _art_slot[i]
		_art_dirty[i] = 0
		var o := slot * 12
		var a := axis[i] if state[i] != State.GONE else Vector2.ZERO
		_art_buffer[o] = a.x
		_art_buffer[o + 1] = -a.y
		_art_buffer[o + 2] = 0.0
		_art_buffer[o + 3] = pos[i].x
		_art_buffer[o + 4] = a.y
		_art_buffer[o + 5] = a.x
		_art_buffer[o + 6] = 0.0
		_art_buffer[o + 7] = pos[i].y
		var tile := _tile(i)
		_art_buffer[o + 8] = float(tile % 8)
		_art_buffer[o + 9] = float(tile / 8)
		_art_buffer[o + 10] = 0.0
		_art_buffer[o + 11] = 0.0
	_art_pending.clear()
	_art.buffer = _art_buffer


func _draw_fx() -> void:
	var view := PixelArt.view_rect(self, 130.0)
	for i in _smoking:
		if not view.has_point(pos[i]):
			continue
		var frame := int(Time.get_ticks_msec() / 180 + i) % 8
		var at := pos[i] + axis[i] * (12.0 + float(i % 4) * 5.0) + axis[i].orthogonal() * float(i % 3 - 1) * 7.0
		_fx.draw_texture_rect_region(_smoke, Rect2(at + Vector2(-14, -30), Vector2(28, 32)), Rect2(frame * 96, 0, 96, 96), Color(0.55, 0.55, 0.52, 0.45))
	for i in _burning:
		if not view.has_point(pos[i]):
			continue
		var frame := int(Time.get_ticks_msec() / 80 + i) % 8
		var at := pos[i] + axis[i] * (8.0 + float(i % 5) * 5.0) + axis[i].orthogonal() * float(i % 3 - 1) * 7.0
		_fx.draw_texture_rect_region(_smoke, Rect2(at + Vector2(-24, -50), Vector2(48, 52)), Rect2(frame * 96, 0, 96, 96), Color(0.55, 0.54, 0.51, 0.65))
		_fx.draw_texture_rect_region(_fire, Rect2(at - Vector2(16, 30), Vector2(32, 36)), Rect2((frame + 2) * 144, (i % 3) * 144, 144, 144))


## Луч тела включает низкие мешки/дерево и скругления OBB; баллистический луч не меняется.
func body_clear(from: Vector2, to: Vector2, r: float) -> bool:
	if not profile_enabled:
		return _body_clear(from, to, r)
	var started := Time.get_ticks_usec()
	var result := _body_clear(from, to, r)
	body_usec += Time.get_ticks_usec() - started
	body_calls += 1
	return result


func _body_clear(from: Vector2, to: Vector2, r: float) -> bool:
	var c := cell_at(from)
	var end := cell_at(to)
	if c == end and _clearance[c] >= r:
		return true
	_ray_stamp += 1
	var p := (from - arena.position).clamp(Vector2.ZERO, arena.size - Vector2.ONE * 0.001)
	var q := (to - arena.position).clamp(Vector2.ZERO, arena.size - Vector2.ONE * 0.001)
	var v := q - p
	var cx: int = c % grid_w
	var cy: int = c / grid_w
	var ex: int = end % grid_w
	var ey: int = end / grid_w
	var sx := 1 if ex > cx else -1
	var sy := grid_w if ey > cy else -grid_w
	var dx := CELL / absf(v.x) if v.x != 0 else INF
	var dy := CELL / absf(v.y) if v.y != 0 else INF
	var tx := (((cx + (1 if v.x > 0 else 0)) * CELL - p.x) / v.x) if v.x != 0 else INF
	var ty := (((cy + (1 if v.y > 0 else 0)) * CELL - p.y) / v.y) if v.y != 0 else INF
	# DDA посещает каждую пересечённую клетку, включая короткий срез её угла.
	for step in absi(ex - cx) + absi(ey - cy) + 1:
		if _clearance[c] < r:
			var link := near_head[c]
			while link != -1:
				var i := _link_obj[link]
				link = _link_next[link]
				if _ray_seen[i] == _ray_stamp or state[i] == State.GONE:
					continue
				_ray_seen[i] = _ray_stamp
				if _body_segment(i, from, to, r):
					return false
		if c == end:
			return true
		if cx != ex and (cy == ey or tx < ty):
			c += sx
			cx += sx
			tx += dx
		else:
			c += sy
			cy += 1 if sy > 0 else -1
			ty += dy
	return true


func _body_segment(i: int, from: Vector2, to: Vector2, r: float) -> bool:
	if _segment(i, from, to, r) == INF:
		return false
	if round_shape[i] == 1:
		return true
	# Сумма прямоугольника и диска: две полосы и четыре круглых угла.
	var p := _local(i, from)
	var q := _local(i, to)
	if _nav_rect_segment(p, q, Rect2(-half[i] - Vector2(r, 0), half[i] * 2.0 + Vector2(r * 2.0, 0))):
		return true
	if _nav_rect_segment(p, q, Rect2(-half[i] - Vector2(0, r), half[i] * 2.0 + Vector2(0, r * 2.0))):
		return true
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			var corner := half[i] * Vector2(sx, sy)
			if Geometry2D.get_closest_point_to_segment(corner, p, q).distance_squared_to(corner) < r * r:
				return true
	return false


## Редкий маршрут пачки HD1, никогда не вызывается из движения отдельного тела.
func body_path(from: Vector2, to: Vector2, r: float) -> PackedVector2Array:
	path_calls += 1
	if body_clear(from, to, r):
		return PackedVector2Array([to])
	var k := radius_class(r)
	var layer: Dictionary = _nav_layers[k]
	var edges: PackedByteArray = layer["edges"]
	var points: PackedVector2Array = layer["points"]
	var first := cell_at(free_point(from, r))
	var last := cell_at(free_point(to, r))
	var parents := PackedInt32Array()
	parents.resize(blocked.size())
	parents.fill(-1)
	parents[first] = first
	var todo := PackedInt32Array([first])
	var read := 0
	while read < todo.size() and parents[last] == -1:
		var at := todo[read]
		read += 1
		for d in 8:
			if edges[at] & (1 << d) == 0:
				continue
			var next := at + _offsets[d]
			if parents[next] == -1:
				parents[next] = at
				todo.append(next)
	if parents[last] == -1:
		return PackedVector2Array()
	var raw := PackedVector2Array([to])
	var at := last
	while at != first:
		raw.append(points[at])
		at = parents[at]
	raw.reverse()
	var path := PackedVector2Array()
	var p := from
	var j := 0
	while j < raw.size():
		var end := j
		while end + 1 < raw.size() and body_clear(p, raw[end + 1], r):
			end += 1
		path.append(raw[end])
		p = raw[end]
		j = end + 1
	return path


func _nav_rect_segment(p: Vector2, q: Vector2, rect: Rect2) -> bool:
	var v := q - p
	var low := 0.0
	var high_t := 1.0
	for dim in 2:
		if absf(v[dim]) < 0.000001:
			if p[dim] < rect.position[dim] or p[dim] > rect.end[dim]:
				return false
		else:
			var a := (rect.position[dim] - p[dim]) / v[dim]
			var b := (rect.end[dim] - p[dim]) / v[dim]
			low = maxf(low, minf(a, b))
			high_t = minf(high_t, maxf(a, b))
			if low > high_t:
				return false
	return true
