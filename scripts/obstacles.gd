class_name Obstacles
extends Node2D
## O1: общая сетка, packed-строки, ограниченная очередь детонаций и один атлас.

enum Kind { SEDAN, HATCH, POLICE, JEEP, TRUCK, RED, ACID, JERSEY, BAGS, FENCE, WOOD, TIRES, RUBBISH, PAPER, BOARDS, GLASS, CONE, STRUCTURE }
enum State { INTACT, DAMAGED, BURNING, WRECK, GONE }
const CELL := 16.0
const ART_CELL := Vector2(288, 144)
const TILES := 34
const CAR_RADIUS := 90.0
const CAR_DAMAGE := 60.0
const BARREL_RADIUS := 65.0
const BARREL_DAMAGE := 40.0
const FLOW_BUDGET := 400
const NO_PATH := 2147483647

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
var blood_events := 0

var _link_obj := PackedInt32Array()
var _link_next := PackedInt32Array()
var distance := PackedInt32Array()
var _distance_build := PackedInt32Array()
var _pending_target := -1
var _dirty := true
var _next_flow := PackedVector2Array()
var _adjacency := PackedInt32Array()
var _queue := PackedInt32Array()
var _qread := 0
var _qwrite := 0
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
var _wall_blood: Texture2D
var _fire: Texture2D
var _smoke: Texture2D
var _fx: Node2D
var _rng := RandomNumberGenerator.new()
var _structure_tex: Array[Texture2D] = []
var _extent := PackedVector2Array()
var _blood_at := PackedVector2Array()
var _ray_seen := PackedInt32Array()
var _ray_stamp := 0
var profile_enabled := false
var resolve_usec := 0
var move_usec := 0
var ray_usec := 0
var resolve_calls := 0
var move_calls := 0
var ray_calls := 0
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
	_wall_blood = PixelArt.tex("map_wall_blood")
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
	shader.code = "shader_type canvas_item; varying vec2 cell; void vertex() { cell = INSTANCE_CUSTOM.xy; } void fragment() { COLOR = texture(TEXTURE, (cell + UV) / vec2(8.0, 17.0)); }"
	var material := ShaderMaterial.new()
	material.shader = shader
	_art_node.material = material
	add_child(_art_node)
	move_child(_fx, -1)


func setup(rect: Rect2, layout: Array[Dictionary]) -> void:
	arena = rect
	count = layout.size()
	_structure_tex.resize(count)
	_extent.resize(count)
	_blood_at.resize(count)
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
	_queue.resize(n)
	_adjacency.resize(n * 4)
	_flow_ready = false
	_building = false
	_target_cell = -1
	_nav_cd = 0.0
	rebuild_grid()
	queue_redraw()


func cell_at(p: Vector2) -> int:
	return clampi(int((p.x - arena.position.x) / CELL), 0, grid_w - 1) + clampi(int((p.y - arena.position.y) / CELL), 0, grid_h - 1) * grid_w


func cell_center(c: int) -> Vector2:
	return arena.position + Vector2(float(c % grid_w) + 0.5, float(c / grid_w) + 0.5) * CELL


func rebuild_grid() -> void:
	near_head.fill(-1)
	blocked.fill(0)
	_link_obj.clear()
	_link_next.clear()
	for i in count:
		if (kind[i] >= Kind.TIRES and kind[i] != Kind.STRUCTURE) or state[i] == State.GONE:
			continue
		var a := axis[i].abs()
		var extent := a * half[i].x + Vector2(a.y, a.x) * half[i].y + Vector2.ONE * 34.0
		var lo := Vector2i((pos[i] - extent - arena.position) / CELL).max(Vector2i.ZERO)
		var hi := Vector2i((pos[i] + extent - arena.position) / CELL).min(Vector2i(grid_w - 1, grid_h - 1))
		for y in range(lo.y, hi.y + 1):
			for x in range(lo.x, hi.x + 1):
				var c := x + y * grid_w
				_link_obj.append(i)
				_link_next.append(near_head[c])
				near_head[c] = _link_obj.size() - 1
				# Запас для элитки и диагонали клетки: поток не срезает углы.
				if _overlaps(i, cell_center(c), 18.9):
					blocked[c] = 1
	_building = false
	_dirty = true # старое поле остаётся в работе, пока строится новое
	# Связи неизменны между разрушениями: горячий BFS не считает границы и координаты.
	_adjacency.fill(-1)
	for c in blocked.size():
		if blocked[c] != 0:
			continue
		var x := c % grid_w
		for direction_index in 4:
			var offset: int = [-1, 1, -grid_w, grid_w][direction_index]
			var next := c + offset
			if next < 0 or next >= blocked.size() or (direction_index == 0 and x == 0) or (direction_index == 1 and x == grid_w - 1):
				continue
			if blocked[next] == 0:
				_adjacency[c * 4 + direction_index] = next
	queue_redraw()


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


## ZERO — идти прямо. Иначе направление поля потока. Прямой путь есть, если расстояние
## по сетке равно манхэттенскому (ступенчатая дорожка без обхода): O(1), без трассировки.
func steering(p: Vector2, direct: Vector2) -> Vector2:
	if not _flow_ready:
		return Vector2.ZERO
	var c := cell_at(p)
	var d := distance[c]
	if d != NO_PATH:
		if d == absi(c % grid_w - _target_cell % grid_w) + absi(c / grid_w - _target_cell / grid_w):
			if near_head[c] == -1 or (blocked[cell_at(p + direct * 20.0)] == 0 and blocked[cell_at(p + direct * 40.0)] == 0):
				return Vector2.ZERO
		return flow[c]
	# Агент мог быть растолкнут в запас сетки: берёт ближайшую свободную клетку.
	var best := NO_PATH
	var direction := Vector2.ZERO
	for offset: int in [-1, 1, -grid_w, grid_w]:
		var next := c + offset
		if next >= 0 and next < blocked.size() and blocked[next] == 0 and distance[next] < best:
			best = distance[next]
			direction = (cell_center(next) - p).normalized()
	return direction


## Поле пересчитывается, когда игрок ушёл от цели поля больше чем на 3 клетки; BFS размазан по тикам.
func navigation_step(delta: float, target: Vector2) -> void:
	var start := Time.get_ticks_usec()
	_nav_cd -= delta
	var c := cell_at(free_point(target, 19.0))
	if not _building and _nav_cd <= 0.0 and (_dirty or _target_cell < 0 or absi(c % grid_w - _target_cell % grid_w) > 2 or absi(c / grid_w - _target_cell / grid_w) > 2):
		_pending_target = c
		_dirty = false
		_nav_cd = 0.15
		_distance_build.fill(NO_PATH)
		_next_flow.fill(Vector2.ZERO)
		_distance_build[c] = 0
		_queue[0] = c
		_qread = 0
		_qwrite = 1
		_building = true
	if _building:
		var end := _qread + FLOW_BUDGET
		while _qread < _qwrite and _qread < end:
			var at := _queue[_qread]
			_qread += 1
			var nd := _distance_build[at] + 1
			var base := at * 4
			var next := _adjacency[base]
			if next >= 0 and _distance_build[next] == NO_PATH:
				_distance_build[next] = nd
				_next_flow[next] = Vector2.RIGHT
				_queue[_qwrite] = next
				_qwrite += 1
			next = _adjacency[base + 1]
			if next >= 0 and _distance_build[next] == NO_PATH:
				_distance_build[next] = nd
				_next_flow[next] = Vector2.LEFT
				_queue[_qwrite] = next
				_qwrite += 1
			next = _adjacency[base + 2]
			if next >= 0 and _distance_build[next] == NO_PATH:
				_distance_build[next] = nd
				_next_flow[next] = Vector2.DOWN
				_queue[_qwrite] = next
				_qwrite += 1
			next = _adjacency[base + 3]
			if next >= 0 and _distance_build[next] == NO_PATH:
				_distance_build[next] = nd
				_next_flow[next] = Vector2.UP
				_queue[_qwrite] = next
				_qwrite += 1
		if _qread == _qwrite:
			_building = false
			_flow_ready = true
			_target_cell = _pending_target
			_flow_target = cell_center(_target_cell)
			nav_completed += 1
			var previous := flow
			flow = _next_flow
			_next_flow = previous
			var previous_distance := distance
			distance = _distance_build
			_distance_build = previous_distance
	nav_worst_usec = maxi(nav_worst_usec, Time.get_ticks_usec() - start)


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
		rebuild_grid()
	return stopped


## Кровь выбирает заранее обрезанную по альфе ступень того же атласа.
func splatter(at: Vector2, _dir := Vector2.ZERO, _death := 0, _facing := 0.0, _variant := 0) -> void:
	var link := near_head[cell_at(at)]
	var changed := false
	while link != -1:
		var i := _link_obj[link]
		link = _link_next[link]
		if (kind[i] >= Kind.TIRES and kind[i] != Kind.STRUCTURE) or state[i] == State.GONE or blood[i] >= 3:
			continue
		if _overlaps(i, at, 30.0):
			var local := _local(i, at)
			_blood_at[i] = Vector2(local.x, -local.y).clamp(-half[i] + Vector2.ONE * 3, half[i] - Vector2.ONE * 3)
			blood[i] += 1
			_mark_art(i)
			blood_events += 1
			changed = true
	if changed:
		queue_redraw()


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
		rebuild_grid()
	_mark_art(i)
	queue_redraw()


func _process(delta: float) -> void:
	_visual_tick += delta
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
		draw_texture_rect(_structure_tex[i], Rect2(-half[i], half[i] * 2.0), false)
		if blood[i] > 0:
			var mark := Rect2(_blood_at[i] - Vector2(8, 3), Vector2(16, 10)).intersection(Rect2(-half[i], half[i] * 2.0))
			draw_texture_rect_region(_wall_blood, mark, Rect2(0, 0, 128, 32))
	draw_set_transform(Vector2.ZERO)
	if profile_enabled:
		draw_usec += Time.get_ticks_usec() - started


func _mark_art(i: int) -> void:
	if _art_slot[i] < 0 or _art_dirty[i] != 0:
		return
	_art_dirty[i] = 1
	_art_pending.append(i)


func _sync_art() -> void:
	if _art == null or _art_pending.is_empty():
		return
	# Только изменившиеся строки; кровь на одном кузове не пересобирает весь пакет.
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
		var tile := _tile(i) + int(blood[i]) * TILES
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
