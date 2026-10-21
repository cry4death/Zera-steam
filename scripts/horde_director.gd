class_name HordeDirector
extends RefCounted
## Кривая задаёт объём; строй — редкое событие, обычная орда преследует игрока.

enum Pattern { PINCER, RING, COLUMN, RUSH, AMBUSH, TIDE, FLANK, REST }
enum Phase { SCOUT, BUILD, PEAK, DECAY, RELAX }
const NAMES := ["pincer", "ring", "column", "rush", "ambush", "tide", "flank", "rest"]
const PHASES := ["scout", "build", "peak", "decay", "relax"]
const ENDS := [10.0, 34.0, 44.0, 64.0, 80.0]
const PACE := [0.95, 1.10, 1.15, 0.95, 0.85]
const NORMALIZE := 1.0 # Взвешенная сумма за 80 с уже равна 80.
const WARNING := 3.0
const EVENT_FIRST := 87.0
const EVENT_PERIOD := 160.0
const EVENT_DURATION := 27.0
const DANGEROUS := [Pattern.PINCER, Pattern.RING, Pattern.RUSH, Pattern.AMBUSH, Pattern.FLANK]
const FORM_LIMIT := [28, 14] # опасная форма: нарастание / пик
const FRONT_LIMIT := [18, 6]
# Роль расширяется типами, а геометрия остаётся прежней.
const ROLES := {"mass": [Horde.Kind.SHAMBLER], "fast": [Horde.Kind.RUNNER],
	"heavy": [Horde.Kind.FAT], "ranged": [Horde.Kind.SPITTER],
	"armored": [Horde.Kind.INFANTRY, Horde.Kind.RIOT, Horde.Kind.JUGGERNAUT]}

var horde: Horde
var player: Player
var run_seed := 0
var map_id := ""
var endless := false
var phase := Phase.SCOUT
var _activity_rest_until := 0.0
var pattern := Pattern.COLUMN
var intensity := 0.0
var nearby := 0
var cornered := false
var moving := false
var suspended := false
var warning_left := 0.0
var warning_points := PackedVector2Array()
var warning_fast := PackedByteArray()
var warning_serial := 0
var angle := 0.0
var gap_angle := 0.0
var planned := 0.0
var issued := 0
var dropped := 0.0
var _cycle := -1
var _last := -1
var _previous := -1
var _sample_at := -1.0
var _hurt_at := -100.0
var _damage_seen := 0.0
var _kills_seen := 0
var _position_seen := Vector2.ZERO
var _roles := PackedByteArray([0, 0, 0, 0])
var _rng := RandomNumberGenerator.new()
var _choose := RandomNumberGenerator.new()
var _plan_rng := RandomNumberGenerator.new()
var _origins := PackedVector2Array()
var _groups := PackedInt32Array()
var _center := Vector2.INF
var _min_distance := 0.0 # ближе к игроку пачка события не появляется (1,5 кольца; запасной вход — кольцо)
var _plan_at := -100.0
var _lane := 0
var _announced := false
var _forced := false
var _lead_until := -100.0
var _danger_cycle := -3
var _shape_build := 0
var _shape_peak := 0
var _suppressed := false
var fast_origin := Vector2.INF
var _fast_until := -100.0
var _now := 0.0
var _event_slot := -1
var _event_until := -100.0
var form_counts := PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0])


func setup(source: Horde, target: Player, value: int, id: String) -> void:
	horde = source
	player = target
	run_seed = value
	map_id = id
	_position_seen = player.position
	_damage_seen = player.damage_taken
	_rng.seed = value ^ 0x484431


static func phase_at(now: float) -> int:
	var age := fposmod(now, 80.0)
	for i in ENDS.size():
		if age < ENDS[i]:
			return i
	return Phase.RELAX


func activity_window(now: float) -> bool:
	return now < 60.0 or phase_at(now) != Phase.PEAK


func activity_finished(now: float) -> void:
	_activity_rest_until = now + 12.0
	warning_left = 0.0
	warning_points.clear()
	horde.release_groups()
	_event_until = -100.0


func sample(now: float, kills: int) -> void:
	_now = now
	if now < _sample_at:
		return
	_sample_at = now + 0.5
	nearby = 0
	_roles.fill(0)
	for i in horde.count:
		if horde.dead[i] != 0:
			continue
		_roles[_role_of(horde.kind[i])] = 1
		if horde.kind[i] == Horde.Kind.RUNNER and fast_origin == Vector2.INF:
			fast_origin = horde.pos[i]
		if horde.pos[i].distance_squared_to(player.position) < 8100.0:
			nearby += 1
	if _roles[1] == 0:
		fast_origin = Vector2.INF
		_fast_until = -100.0
	if player.damage_taken > _damage_seen:
		_hurt_at = now
	_damage_seen = player.damage_taken
	moving = player.position.distance_squared_to(_position_seen) > 225.0
	_position_seen = player.position
	var exits := 0
	for j in 8:
		var to := player.position + Vector2.from_angle(TAU * j / 8.0) * 90.0
		if horde.arena.grow(-24).has_point(to) and (horde.obstacles == null or horde.obstacles.move_actor(player.position, to, 14.0).distance_to(to) < 2.0):
			exits += 1
	cornered = exits < 3
	var hurt := 1.0 if now - _hurt_at < 5.0 else 0.0
	var health := 1.0 - player.hp / maxf(player.max_hp, 1.0)
	var killing := clampf(float(kills - _kills_seen) / 12.0, 0.0, 1.0)
	_kills_seen = kills
	intensity = clampf(health * 0.3 + hurt * 0.3 + minf(1.0, nearby / 16.0) * 0.25 + float(cornered) * 0.1 + killing * 0.05, 0.0, 1.0)
	_suppressed = player.hp < player.max_hp * 0.35 or intensity >= 0.45 or now - _hurt_at < 5.0
	if not suspended and not _forced and _suppressed and not _groups.is_empty():
		# После удара снимаем сжатие, не заменяя его новой плотной стеной.
		horde.release_groups()
		_groups.clear()
		_origins.clear()
		warning_points.clear()
		warning_left = 0.0
		_announced = false
		_event_until = -100.0


## Один временной слот, без очереди пропущенных атак при перемотке и событиях.
func advance(now: float, delta: float, shares: Array, exclusive: bool) -> float:
	_now = now
	if horde.count == 0:
		fast_origin = Vector2.INF
	warning_left = maxf(0.0, warning_left - delta)
	var cycle := floori(now / 80.0)
	var next_phase := phase_at(now)
	# Пропущенное из-за тревоги/ранения окно не накапливается в очередь атак.
	var slot := floori((now - EVENT_FIRST) / EVENT_PERIOD)
	var event_due := slot >= 0 and slot > _event_slot
	if event_due:
		_event_slot = slot
	if now >= _event_until and not _groups.is_empty():
		horde.release_groups()
		_groups.clear()
		_origins.clear()
		_fast_until = -100.0
	if exclusive:
		if not suspended:
			_origins.clear()
			_groups.clear()
			warning_left = 0.0
			warning_points.clear()
			horde.release_groups()
		_event_until = -100.0
		suspended = true
		_cycle = cycle
		phase = next_phase
		return 1.0
	if now < _activity_rest_until:
		warning_left = 0.0
		warning_points.clear()
		horde.release_groups()
		phase = Phase.RELAX
		return 0.85
	if suspended or cycle != _cycle:
		suspended = false
		_cycle = cycle
		select_pattern(now, shares)
	phase = next_phase
	# Первая минута знакомит с оружием; её исходный ритм сохраняется.
	if now < 60.0:
		return 1.0
	if event_due and not _suppressed and now < 535.0 and fposmod(now - EVENT_FIRST, EVENT_PERIOD) < 10.0:
		prepare(now)
		announce()
		_event_until = now + WARNING + EVENT_DURATION
	if phase == Phase.RELAX:
		warning_left = 0.0
	# Сигналы сглаживают контраст, не меняя среднее и не создавая долг.
	var contrast := lerpf(1.0, 0.45, intensity)
	if player.hp < player.max_hp * 0.35:
		return 1.0
	return 1.0 + (float(PACE[phase]) * NORMALIZE - 1.0) * contrast


## Внешнее событие (зов узла, ZAI3/R8): ближайший слот строя пропускается, чтобы две волны не легли друг на друга.
func external_event(now: float) -> void:
	_event_slot = maxi(_event_slot, floori((now + EVENT_DURATION - EVENT_FIRST) / EVENT_PERIOD))


func select_pattern(now: float, shares: Array) -> void:
	_choose.seed = run_seed + floori(now / 80.0) * 7919
	var weights := [1.2, 1.0, 2.0 if map_id == "old_town" else 1.0, 0.8, 0.8, 1.0, 1.3 if moving else 0.8]
	for k: int in DANGEROUS:
		weights[k] *= 0.35
		# Живое быстрое плечо и соседний цикл не получают встречную атаку.
		if fast_origin != Vector2.INF or _cycle - _danger_cycle < 2:
			weights[k] = 0.0
	if now < 180.0 or cornered:
		weights[Pattern.RING] = 0.0
	if now < 60.0 or cornered:
		weights[Pattern.AMBUSH] = 0.0
	if float(shares[Horde.Kind.RUNNER]) <= 0.0:
		weights[Pattern.RUSH] = 0.0
		weights[Pattern.FLANK] = 0.0
	if intensity >= 0.55:
		for k in [Pattern.PINCER, Pattern.RING, Pattern.RUSH, Pattern.AMBUSH, Pattern.FLANK]:
			weights[k] = 0.0
	var total := 0.0
	for k in weights.size():
		if k == _last or k == _previous:
			weights[k] = 0.0
		total += float(weights[k])
	var roll := _choose.randf() * total
	var selected := Pattern.COLUMN
	for k in weights.size():
		roll -= float(weights[k])
		if roll < 0.0:
			selected = k
			break
	_previous = _last
	_last = selected
	pattern = selected
	if pattern in DANGEROUS:
		_danger_cycle = _cycle
	angle = _choose.randf() * TAU
	_plan_rng.seed = run_seed + _cycle * 104729 + 17
	_origins.clear()
	_groups.clear()
	_announced = false
	_forced = false
	_plan_at = -100.0
	_lane = 0
	_shape_build = 0
	_shape_peak = 0


## Форма — короткая порция внутри прежнего потока, а не весь поток 42 секунды.
func shape_count(n: int, now: float) -> int:
	if _suppressed or now >= _event_until or now < _lead_until:
		return 0
	var limits: Array = FORM_LIMIT if pattern in DANGEROUS else FRONT_LIMIT
	var amount := 0
	if phase == Phase.BUILD:
		amount = mini(n, maxi(0, int(limits[0]) - _shape_build))
		_shape_build += amount
	elif phase == Phase.PEAK:
		amount = mini(n, maxi(0, int(limits[1]) - _shape_peak))
		_shape_peak += amount
	return amount


## Пока бегуны живы, новые быстрые пачки и элитки выходят с того же края.
func fast_source(want: Vector2) -> Vector2:
	# Обычный поток не наследует сторону закончившейся атаки.
	if _now >= _fast_until:
		return want
	if fast_origin == Vector2.INF:
		fast_origin = want
		return want
	var dir := (fast_origin - player.position).angle()
	# Сохраняем край, но берём текущую дальность обычного входа карты.
	var distance := maxf(horde.spawn_ring, want.distance_to(player.position))
	var source := _hidden_point(player.position + Vector2.from_angle(dir) * distance, dir, distance, PixelArt.view_rect(horde, 60.0))
	if source != Vector2.INF:
		fast_origin = source
	return source


## Стенд использует те же точки, роли и маршруты, что обычный спавн.
func force_pattern(value: int, direction: float, now: float) -> void:
	pattern = value
	angle = direction
	phase = Phase.PEAK
	_forced = true
	_event_until = now + WARNING + EVENT_DURATION
	_plan_rng.seed = run_seed + value * 104729
	_origins.clear()
	_groups.clear()
	prepare(now)
	announce()


func announce() -> void:
	_announced = true
	warning_points = _origins.duplicate()
	warning_fast.resize(_origins.size())
	for lane in _origins.size():
		warning_fast[lane] = 1 if pattern == Pattern.RUSH or pattern == Pattern.FLANK and lane == 1 else 0
	warning_left = WARNING + 1.5 if pattern != Pattern.REST else 0.0
	warning_serial += 1
	_lead_until = _plan_at + WARNING


func prepare(now: float) -> void:
	_origins.clear()
	_groups.clear()
	_center = player.position
	_plan_at = now
	_min_distance = horde.spawn_ring * 1.5
	if pattern == Pattern.REST:
		return
	var obs := horde.obstacles
	var distance := horde.spawn_ring * 1.5
	var entry := Vector2.INF
	var nearest := INF
	var view := PixelArt.view_rect(horde, 40.0)
	for at in horde.map_entries:
		var d := at.distance_to(_center)
		if not view.has_point(at) and d < nearest:
			nearest = d
			entry = at
	if entry != Vector2.INF:
		distance = maxf(distance, nearest)
		if pattern == Pattern.COLUMN:
			angle = (entry - _center).angle()
	gap_angle = _escape_angle()
	if pattern in [Pattern.PINCER, Pattern.FLANK]:
		# Пара выбирается целиком: дом не должен незаметно убрать второе плечо.
		for turn in 16:
			var a := angle + float(turn) * PI / 8.0
			var other := a + (PI if pattern == Pattern.PINCER else PI * 0.5)
			if _hidden_point(_center + Vector2.from_angle(a) * distance, a, distance, view) != Vector2.INF and _hidden_point(_center + Vector2.from_angle(other) * distance, other, distance, view) != Vector2.INF:
				angle = a
				break
	var lanes := 2 if pattern in [Pattern.PINCER, Pattern.FLANK] else (7 if pattern == Pattern.RING else (5 if pattern == Pattern.TIDE else 1))
	for lane in lanes:
		var a := angle
		if pattern == Pattern.PINCER:
			a += PI * lane
		elif pattern == Pattern.FLANK:
			a += PI * 0.5 * lane
		elif pattern == Pattern.RING:
			a = gap_angle + PI * 0.30 + (TAU - PI * 0.60) * float(lane) / 6.0
		var dir := Vector2.from_angle(a)
		var lateral := (float(lane) - 2.0) * 45.0 if pattern == Pattern.TIDE else 0.0
		var want := _center + dir * distance + dir.orthogonal() * lateral
		if pattern == Pattern.AMBUSH:
			want = _ambush(view, dir, distance)
		var source := _hidden_point(want, a, distance, view)
		if source == Vector2.INF:
			continue
		# Плечо — только точка появления: участники идут к игроку по общему полю путей (PT1b), маршрутов нет.
		_origins.append(source)
		_groups.append(horde.make_group(WARNING + EVENT_DURATION))
	# Если сектор закрыт домом или краем карты, берём ближайший вход за экраном; в стену не спавним.
	if _origins.is_empty() and entry != Vector2.INF and entry.distance_to(_center) >= horde.spawn_ring:
		if obs == null or obs.distance[obs.cell_at(entry)] != Obstacles.NO_PATH:
			_origins.append(entry)
			_groups.append(horde.make_group(WARNING + EVENT_DURATION))
			_min_distance = horde.spawn_ring


func _escape_angle() -> float:
	var best := -INF
	var result := angle + PI
	for j in 16:
		var a := TAU * j / 16.0
		var at := player.position + Vector2.from_angle(a) * 180.0
		if not horde.arena.grow(-24).has_point(at):
			continue
		var reached := horde.obstacles.move_actor(player.position, at, 19.0) if horde.obstacles else at
		var score := reached.distance_to(player.position)
		if score > best:
			best = score
			result = a
	return result


func _ambush(view: Rect2, dir: Vector2, distance: float) -> Vector2:
	var obs := horde.obstacles
	if obs:
		var best := INF
		var result := Vector2.INF
		for i in obs.count:
			if obs.kind[i] > Obstacles.Kind.TRUCK or obs.state[i] == Obstacles.State.GONE:
				continue
			var away := (obs.pos[i] - player.position).normalized()
			var at := obs.pos[i] + away * (obs.half[i].length() + 30.0)
			var d := at.distance_to(player.position)
			if not view.has_point(at) and d >= distance and d < best and not obs.contains(at, 22.0):
				result = at
				best = d
		if result != Vector2.INF:
			return result
	return player.position + dir * distance


func _hidden_point(want: Vector2, a: float, distance: float, view: Rect2) -> Vector2:
	for attempt in 144:
		var at := want
		if attempt > 0:
			var ring := (attempt - 1) / 12
			var side := float((attempt - 1) % 12 - 6) * 0.065
			var reach := maxf(horde.spawn_ring * 1.5, distance + (float(ring) - 6.0) * 40.0)
			at = player.position + Vector2.from_angle(a + side) * reach
		if not horde.arena.grow(-24).has_point(at) or view.has_point(at) or at.distance_to(player.position) + 0.01 < horde.spawn_ring * 1.5:
			continue
		if pattern == Pattern.RING and absf(angle_difference(gap_angle, (at - player.position).angle())) < PI * 0.25:
			continue
		var obs := horde.obstacles
		if obs and (obs.contains(at, 23.0) or obs.blocked[obs.cell_at(at)] != 0 or obs.distance[obs.cell_at(at)] == Obstacles.NO_PATH):
			continue
		return at
	return Vector2.INF


func spawn_group(n: int, shares: Array, runner_pack: bool, now: float) -> int:
	_now = now
	if pattern == Pattern.REST or now >= _event_until:
		return 0
	if not _forced and now < _lead_until:
		return 0
	# Точки события неподвижны: движение игрока не пересобирает вокруг него строй.
	if _origins.is_empty():
		prepare(now)
	if _origins.is_empty():
		return 0
	var issued_now := 0
	var role_count := 0
	for k in range(1, _roles.size()):
		role_count += _roles[k]
	var fats := 0
	var spitters := 0
	var view := PixelArt.view_rect(horde, 22.0)
	for j in n:
		var lane := _lane % _origins.size()
		_lane += 1
		if not _forced and pattern == Pattern.PINCER and now < _lead_until + 2.5:
			lane = 0
		# Быстрый удар только с одного края; другое плечо медленное.
		if runner_pack:
			lane = 1 if pattern == Pattern.FLANK and _origins.size() > 1 else 0
		var k := _armored_kind(_pick_kind(shares, runner_pack), now)
		var role := _role_of(k)
		if role == 2:
			fats += 1
		elif role == 3:
			spitters += 1
		if role > 0 and (_roles[role] == 0 and role_count >= 2 or fats > 3 or spitters > 3):
			k = Horde.Kind.SHAMBLER
			role = 0
		if role > 0 and _roles[role] == 0:
			_roles[role] = 1
			role_count += 1
		var width := 26.0 if pattern == Pattern.COLUMN else 48.0
		var inward := (_center - _origins[lane]).normalized()
		var at := _origins[lane]
		# Не стягиваем пачку в одну точку, если первый разброс попал в машину.
		for attempt in 12:
			var candidate := _origins[lane] + inward.orthogonal() * _rng.randf_range(-width, width) - inward * _rng.randf_range(0.0, 72.0)
			if view.has_point(candidate) or not horde.arena.grow(-24.0).has_point(candidate) or candidate.distance_to(player.position) + 0.01 < _min_distance:
				continue
			if horde.obstacles and (horde.obstacles.contains(candidate, 23.0) or horde.obstacles.distance[horde.obstacles.cell_at(candidate)] == Obstacles.NO_PATH):
				continue
			at = candidate
			break
		if view.has_point(at) or at.distance_to(player.position) + 0.01 < _min_distance:
			continue
		var i := horde.spawn(at, k)
		if i >= 0:
			horde.attach_group(i, _groups[lane])
			if runner_pack:
				fast_origin = _origins[lane]
				_fast_until = _event_until
			issued_now += 1
	issued += issued_now
	form_counts[pattern] += issued_now
	return issued_now


func _pick_kind(shares: Array, runner_pack: bool) -> int:
	if runner_pack:
		return ROLES["fast"][0] if float(shares[Horde.Kind.RUNNER]) > 0.0 else ROLES["mass"][0]
	var total := 0.0
	for k in shares.size():
		if not ROLES["fast"].has(k):
			total += float(shares[k])
	var roll := _rng.randf() * total
	for k in shares.size():
		if ROLES["fast"].has(k):
			continue
		roll -= float(shares[k])
		if roll < 0.0:
			return k
	return Horde.Kind.SHAMBLER


## Элитки и остаточный спавн не открывают третью особую роль между выборками.
## Одинаковый состав для групп и одиночных выдач между пиками; RNG формы не сдвигается.
func _armored_kind(value: int, now: float) -> int:
	if value != Horde.Kind.SHAMBLER or now < 300.0:
		return value
	var ticket := posmod(run_seed + horde._next_uid * 7919, 1000)
	var military := map_id in ["quarantine_checkpoint", "open_perimeter"]
	var threshold := 20 if military else 10
	if endless and now >= 720.0:
		threshold += mini(100, 20 + floori((now - 720.0) / 60.0) * 4)
	if ticket >= threshold:
		return value
	var heavy := mini(12, 2 + floori((now - 720.0) / 120.0)) if endless and now >= 720.0 else 1
	return Horde.Kind.JUGGERNAUT if ticket < heavy and now >= 420.0 else Horde.Kind.RIOT if pattern in [Pattern.COLUMN, Pattern.TIDE] and ticket % 3 == 0 else Horde.Kind.INFANTRY


func accept_kind(value: int) -> int:
	value = _armored_kind(value, _now)
	var role := _role_of(value)
	if role == 0:
		return value
	var active := 0
	for k in range(1, _roles.size()):
		active += _roles[k]
	if _roles[role] == 0 and active >= 2:
		return Horde.Kind.SHAMBLER
	_roles[role] = 1
	return value


static func _role_of(value: int) -> int:
	if ROLES["armored"].has(value):
		return 2
	if ROLES["fast"].has(value):
		return 1
	if ROLES["heavy"].has(value):
		return 2
	if ROLES["ranged"].has(value):
		return 3
	return 0
