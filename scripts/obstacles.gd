class_name Obstacles
extends Node2D
## O1: общая сетка, packed-строки, ограниченная очередь детонаций и один атлас.

enum Kind { SEDAN, HATCH, POLICE, JEEP, TRUCK, RED, ACID, JERSEY, BAGS, FENCE, WOOD, TIRES, RUBBISH, PAPER, BOARDS, GLASS, CONE }
enum State { INTACT, DAMAGED, BURNING, WRECK, GONE }
const CELL := 16.0
const ART_CELL := Vector2(288, 144)
const TILES := 34
const CAR_RADIUS := 90.0
const CAR_DAMAGE := 60.0
const BARREL_RADIUS := 65.0
const BARREL_DAMAGE := 40.0
const FLOW_BUDGET := 700
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
var _distance := PackedInt32Array()
var _next_flow := PackedVector2Array()
var _adjacency := PackedInt32Array()
var _directions := PackedVector2Array([Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP])
var _queue := PackedInt32Array()
var _qread := 0
var _qwrite := 0
var _building := false
var _target_cell := -1
var _flow_target := Vector2.ZERO
var _flow_ready := false
var _nav_cd := 0.0
var _los_version := 1
var _los_stamp := PackedInt32Array()
var _los_clear := PackedByteArray()
var _blast_queue := PackedInt32Array()
var _burning := PackedInt32Array()
var _smoking := PackedInt32Array()
var _fire_tick := 0.0
var _visual_tick := 0.0
var _view_cell := Vector2i(-999, -999)
var _atlas: Texture2D
var _fire: Texture2D
var _smoke: Texture2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_atlas = PixelArt.tex("obst_atlas")
	_fire = PixelArt.tex("fx_explosion_medium")
	_smoke = PixelArt.tex("fx_smoke")
	process_priority = -20
	_rng.seed = 17081


func setup(rect: Rect2, layout: Array[Dictionary]) -> void:
	arena = rect
	count = layout.size()
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
	for i in count:
		kind[i] = int(layout[i]["kind"])
		pos[i] = layout[i]["pos"]
		rotation_angle[i] = float(layout[i].get("angle", 0.0))
		axis[i] = Vector2.from_angle(rotation_angle[i])
		state[i] = State.INTACT
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
		high[i] = 1 if k <= Kind.TRUCK or k == Kind.JERSEY or k == Kind.FENCE else 0
		round_shape[i] = 1 if k in [Kind.RED, Kind.ACID, Kind.BAGS] else 0
		hp[i] = 120.0 if k <= Kind.TRUCK else 12.0
	grid_w = ceili(rect.size.x / CELL)
	grid_h = ceili(rect.size.y / CELL)
	var n := grid_w * grid_h
	near_head.resize(n)
	blocked.resize(n)
	flow.resize(n)
	_next_flow.resize(n)
	_distance.resize(n)
	_queue.resize(n)
	_los_stamp.resize(n)
	_los_clear.resize(n)
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
		if kind[i] >= Kind.TIRES or state[i] == State.GONE:
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
	_flow_ready = false
	_building = false
	_target_cell = -1
	_los_version += 1
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
	for pass_index in 4:
		var changed := false
		var link := near_head[cell_at(p)]
		while link != -1:
			var i := _link_obj[link]
			link = _link_next[link]
			if state[i] == State.GONE:
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
	return p


## Подшаги исключают туннелирование рывка, тарана и сильного отброса.
func move_actor(from: Vector2, to: Vector2, r: float) -> Vector2:
	var steps := maxi(1, ceili(from.distance_to(to) / 4.0))
	var step := (to - from) / float(steps)
	var p := from
	for j in steps:
		p = resolve(p + step, r)
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
			if i == ignore or state[i] == State.GONE or (only_high and high[i] == 0):
				continue
			if not only_high and high[i] == 0 and kind[i] != Kind.RED and kind[i] != Kind.ACID:
				continue
			var t := _segment(i, from, to, radius)
			if t < best_t:
				best_t = t
				best = i
	return best


func line_clear(from: Vector2, to: Vector2) -> bool:
	return ray_hit(from, to, true, 0.0) == -1


func steering(p: Vector2, direct: Vector2) -> Vector2:
	if not _flow_ready:
		return direct
	var c := cell_at(p)
	if _los_stamp[c] != _los_version:
		_los_stamp[c] = _los_version
		_los_clear[c] = 1 if _nav_line_clear(cell_center(c), _flow_target) else 0
	if _los_clear[c] == 1:
		return direct
	var direction := flow[c]
	if direction == Vector2.ZERO:
		# Агент мог быть растолкнут в запас сетки: берёт ближайшую свободную клетку.
		var best := INF
		for offset: int in [-1, 1, -grid_w, grid_w]:
			var next := c + offset
			if next >= 0 and next < blocked.size() and blocked[next] == 0 and _distance[next] < best:
				best = _distance[next]
				direction = (cell_center(next) - p).normalized()
	return direction.normalized() if direction != Vector2.ZERO else direct


func _nav_line_clear(from: Vector2, to: Vector2) -> bool:
	var steps := maxi(1, ceili(from.distance_to(to) / (CELL * 0.65)))
	for j in steps + 1:
		if blocked[cell_at(from.lerp(to, float(j) / float(steps)))] != 0:
			return false
	return true


func navigation_step(delta: float, target: Vector2) -> void:
	var start := Time.get_ticks_usec()
	_nav_cd -= delta
	var c := cell_at(free_point(target, 19.0))
	if not _building and _nav_cd <= 0.0 and c != _target_cell:
		_target_cell = c
		_flow_target = cell_center(c)
		_nav_cd = 0.2
		_distance.fill(NO_PATH)
		_next_flow.fill(Vector2.ZERO)
		_distance[c] = 0
		_queue[0] = c
		_qread = 0
		_qwrite = 1
		_building = true
	if _building:
		var end := _qread + FLOW_BUDGET
		while _qread < _qwrite and _qread < end:
			var at := _queue[_qread]
			_qread += 1
			for direction_index in 4:
				var next := _adjacency[at * 4 + direction_index]
				if next < 0 or _distance[next] != NO_PATH:
					continue
				_distance[next] = _distance[at] + 1
				_next_flow[next] = _directions[direction_index]
				_queue[_qwrite] = next
				_qwrite += 1
		if _qread == _qwrite:
			_building = false
			_flow_ready = true
			_los_version += 1
			nav_completed += 1
			var previous := flow
			flow = _next_flow
			_next_flow = previous
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
		else:
			state[i] = State.BURNING
			_blast_queue.append(i)
	queue_redraw()


func blast(at: Vector2, radius: float, amount: float) -> void:
	for i in count:
		if state[i] == State.GONE:
			continue
		var d2 := pos[i].distance_squared_to(at)
		if d2 > (radius + half[i].x) * (radius + half[i].x):
			continue
		if kind[i] >= Kind.TIRES:
			var away := (pos[i] - at).normalized()
			pos[i] += away * 12.0
			rotation_angle[i] += 0.7
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
			dirty = true
		else:
			damage(i, 180.0, true)
			stopped = true
	if dirty:
		rebuild_grid()
	return stopped


## Кровь выбирает заранее обрезанную по альфе ступень того же атласа.
func splatter(at: Vector2, _dir := Vector2.ZERO, _death := 0, _facing := 0.0, _variant := 0) -> void:
	var changed := false
	for i in count:
		if kind[i] >= Kind.TIRES or state[i] == State.GONE or blood[i] >= 3:
			continue
		if _overlaps(i, at, 42.0):
			blood[i] += 1
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
	queue_redraw()


func _process(delta: float) -> void:
	_visual_tick += delta
	var view := PixelArt.view_rect(self)
	var cell := Vector2i(view.position / 48.0)
	if cell != _view_cell or ((not _burning.is_empty() or not _smoking.is_empty()) and _visual_tick >= 0.083):
		_view_cell = cell
		_visual_tick = 0.0
		queue_redraw()


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
	var view := PixelArt.view_rect(self, 130.0)
	# Мусор в том же пакете, перед высокими объектами.
	for layer in 2:
		for i in count:
			if state[i] == State.GONE or not view.has_point(pos[i]) or (kind[i] >= Kind.TIRES) != (layer == 0):
				continue
			var tile := _tile(i) + int(blood[i]) * TILES
			var source := Rect2(Vector2(tile % 8, tile / 8) * ART_CELL, ART_CELL)
			draw_set_transform(pos[i], rotation_angle[i], Vector2.ONE * PixelArt.ART_SCALE)
			draw_texture_rect_region(_atlas, Rect2(-ART_CELL * 0.5, ART_CELL), source)
	draw_set_transform(Vector2.ZERO)
	for i in _smoking:
		if not view.has_point(pos[i]):
			continue
		var frame := int(Time.get_ticks_msec() / 180 + i) % 8
		var at := pos[i] + axis[i] * 20.0
		draw_texture_rect_region(_smoke, Rect2(at + Vector2(-14, -30), Vector2(28, 32)), Rect2(frame * 96, 0, 96, 96), Color(0.55, 0.55, 0.52, 0.45))
	for i in _burning:
		if not view.has_point(pos[i]):
			continue
		var frame := int(Time.get_ticks_msec() / 80 + i) % 8
		var at := pos[i] + axis[i] * 18.0
		draw_texture_rect_region(_smoke, Rect2(at + Vector2(-24, -50), Vector2(48, 52)), Rect2(frame * 96, 0, 96, 96), Color(0.55, 0.54, 0.51, 0.65))
		draw_texture_rect_region(_fire, Rect2(at - Vector2(16, 30), Vector2(32, 36)), Rect2((frame + 2) * 144, (i % 3) * 144, 144, 144))
