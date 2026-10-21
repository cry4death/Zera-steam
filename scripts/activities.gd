class_name Activities
extends Node2D
## Один необязательный эпизод. Расписание и география не расходуют боевой RNG.

enum Kind { SUPPLY, CARRIER, FUEL, APC, TURRET, ARTILLERY }
enum Phase { IDLE, OFFER, ACTIVE, RESOLVED }

const HOLD := 18.0
const HOLD_RADIUS := 46.0
const FUSE := 6.0
const BLAST_RADIUS := 72.0
const BLAST_DAMAGE := 80.0
const CARRIER_SPEED := 42.0
const HACK_TIME := 12.0
const GENERATOR_TIME := 4.0
const TURRET_TIME := 20.0
const TURRET_RATE := 0.125
const TURRET_DAMAGE := 22.0
const STRIKE_DELAY := 6.0
const STRIKE_RADIUS := 46.0
const STRIKE_DAMAGE := 180.0
const NAMES := ["supply", "carrier", "fuel", "apc", "turret", "artillery"]
const ICONS := ["crate", "med", "flame", "activity_apc", "activity_turret", "activity_artillery"]
const COLORS := [Color("c1bc93"), Color("c1ccaf"), Color("d1a86b"), Color("c1bc93"), Color("c1ccaf"), Color("d1a86b")]

var game: Node
var phase := Phase.IDLE
var kind := Kind.SUPPLY
var target := Vector2.INF
var schedule: Array[Dictionary] = []
var enabled := true
var verbose := false
var offered := 0
var succeeded := 0
var failed := 0
var rewards := 0
var _rng := RandomNumberGenerator.new()
var _next := 0
var _age := 0.0
var _work := 0.0
var _fuse := -1.0
var _wave_at := 0.0
var _cool_until := 0.0
var _defer_until := -1.0
var _last_hurt := -100.0
var _carrier_uid := -1
var _carrier_speed := 0.0
var _route := PackedVector2Array()
var _waypoint := 0
var _textures: Array[Texture2D] = []
var _zone: Texture2D
var _parachute: Texture2D
var _smoke: Texture2D
var _spent: Texture2D
var _spent_at := Vector2.INF
var _spent_life := 0.0
var _bot_path := PackedVector2Array()
var _bot_at := 0.0
var _shot_start := false
var _shot_peak := false
var _floor: Node2D
var _fuel_zone: Texture2D
var _barrel: Texture2D
var _support := -1.0
var _shot_cd := 0.0
var _aim := Vector2.RIGHT
var _flash := 0.0
var _bullet_pos := PackedVector2Array()
var _bullet_vel := PackedVector2Array()
var _bullet_life := PackedFloat32Array()
var _strike_axis := Vector2.RIGHT
var _marked := false
var _beep_second := 6
var _salvo := 0
var _strike_safe := true
var support_shots := 0
var support_hits := 0
var artillery_blasts := 0


func setup(owner_game: Node, run_seed: int) -> void:
	game = owner_game
	z_index = 4
	process_priority = -20 # До движения орды и перестройки её сетки.
	_rng.seed = run_seed
	schedule = make_schedule(run_seed, game._map_id)
	for n: String in NAMES:
		_textures.append(PixelArt.tex("activity_" + n))
	_zone = PixelArt.tex("activity_zone")
	_parachute = PixelArt.tex("activity_parachute")
	_smoke = PixelArt.tex("activity_smoke")
	_spent = PixelArt.tex("activity_fuel_spent")
	_fuel_zone = PixelArt.tex("activity_fuel_zone")
	_barrel = PixelArt.tex("activity_turret_barrel")
	if not game.mission_config.is_empty():
		schedule = operation_schedule(run_seed, str(game.mission_config.get("type", "")))
	_floor = Node2D.new()
	game.get_node("World").add_child(_floor)
	game.get_node("World").move_child(_floor, game.horde.get_index())
	_floor.draw.connect(_draw_floor)
	game.player.hurt.connect(_on_hurt)
	verbose = game._sim or OS.get_cmdline_user_args().has("--activities-test")
	if verbose:
		print("ACTIVITIES seed=%d map=%s schedule=%s" % [run_seed, game._map_id, schedule])


static func make_schedule(run_seed: int, map_id: String) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	var result: Array[Dictionary] = []
	var pool := [Kind.SUPPLY, Kind.CARRIER, Kind.FUEL, Kind.APC, Kind.TURRET, Kind.ARTILLERY]
	var weights := [4.0, 3.0, 3.0, 4.0, 3.0, 4.0] if map_id == "quarantine_checkpoint" else ([3.0, 4.0, 2.0, 3.0, 4.0, 3.0] if map_id == "old_town" else [3.0, 2.0, 4.0, 3.0, 4.0, 4.0])
	var slots := [Vector2(50, 60), Vector2(130, 140), Vector2(210, 220), Vector2(330, 340), Vector2(465, 475)]
	var count := 4 + int(rng.randf() < 0.5)
	for i in count:
		var total := 0.0
		for k: int in pool:
			total += weights[k]
		var roll := rng.randf() * total
		var chosen: int = pool.back()
		for k: int in pool:
			roll -= weights[k]
			if roll < 0.0:
				chosen = k
				break
		pool.erase(chosen)
		result.append({"time": rng.randf_range(slots[i].x, slots[i].y), "kind": chosen})
	return result


static func operation_schedule(run_seed: int, type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if type in ["clearance", "reclaim"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = run_seed ^ 0x455632
		result.append({"time": rng.randf_range(130.0, 140.0), "kind": rng.randi_range(Kind.APC, Kind.ARTILLERY)})
	return result


func _on_hurt(_amount: float) -> void:
	_last_hurt = game.time


func is_active() -> bool:
	return phase == Phase.OFFER or phase == Phase.ACTIVE


func progress() -> float:
	if kind == Kind.APC:
		return _work / HACK_TIME
	if kind == Kind.TURRET:
		return 1.0 - _support / TURRET_TIME if _support >= 0.0 else _work / GENERATOR_TIME
	if kind == Kind.ARTILLERY:
		return 1.0 - maxf(0.0, _fuse) / STRIKE_DELAY if _marked else _work / 2.0
	if kind == Kind.SUPPLY:
		return clampf(_work / HOLD, 0.0, 1.0)
	if kind == Kind.FUEL:
		return clampf(1.0 - _fuse / FUSE, 0.0, 1.0) if _fuse >= 0.0 else _work / 2.0
	var i := carrier_index()
	return 1.0 - game.horde.hp[i] / game.horde.max_hp[i] if i >= 0 else 1.0


## Сайт от 240 до 520 ед. по дороге; большой предмет не перекрывает узкий проход.
func find_site() -> Vector2:
	var origin: Vector2 = game.player.position
	# Авторские площадки задают характер места; при удалении игрока работает обычный поиск.
	var sockets: Array = game._map_data.get("activity_sockets", [])
	if not sockets.is_empty():
		var first := _rng.randi_range(0, sockets.size() - 1)
		for offset in sockets.size():
			var at := MapLoader.point(sockets[(first + offset) % sockets.size()])
			var distance := at.distance_to(origin)
			if distance >= 240.0 and distance <= 520.0 and valid_site(at):
				return at
	for attempt in 96:
		var at := origin + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(240.0, 520.0)
		if not game.ARENA.grow(-80.0).has_point(at):
			continue
		if game.obstacles:
			at = game.obstacles.free_point(at, 54.0)
		if valid_site(at) and at.distance_to(origin) >= 200.0 and at.distance_to(origin) <= 550.0:
			return at
	# Детерминированный полный поиск, если случайные точки попали на дома.
	if game.obstacles:
		var best := Vector2.INF
		var score := INF
		for c in game.obstacles.blocked.size():
			if game.obstacles.blocked[c] != 0 or game.obstacles.distance[c] == Obstacles.NO_PATH:
				continue
			var at: Vector2 = game.obstacles.cell_center(c)
			var d := absf(at.distance_to(origin) - 340.0)
			if d < score and valid_site(at):
				score = d
				best = at
		return best
	return origin + Vector2(180, 0)


func valid_site(at: Vector2) -> bool:
	if at == Vector2.INF or not game.ARENA.grow(-75.0).has_point(at):
		return false
	var obs: Obstacles = game.obstacles
	if obs != null and (obs.contains(at, 54.0) or obs.distance[obs.cell_at(at)] == Obstacles.NO_PATH):
		return false
	if game.objective != null and (at.distance_to(game.objective.target) < 180.0 or at.distance_to(game.objective.exit_point) < 140.0):
		return false
	return kind != Kind.ARTILLERY or strike_axis(at) != Vector2.ZERO


## Полоса целиком в свободном коридоре; доступ к треноге остаётся сбоку.
func strike_axis(at: Vector2) -> Vector2:
	for axis: Vector2 in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		var center := at - axis.orthogonal() * 80.0
		var good := true
		for j in 7:
			var p := center + axis * (float(j) * 40.0 - 120.0)
			if not game.ARENA.grow(-STRIKE_RADIUS).has_point(p) or (game.obstacles and game.obstacles.contains(p, STRIKE_RADIUS)):
				good = false
				break
		if good:
			return axis
	return Vector2.ZERO


## Маршрут только по связным клеткам, без изменения поля потока орды.
func make_route(at: Vector2) -> PackedVector2Array:
	var path := PackedVector2Array()
	var obs: Obstacles = game.obstacles
	if obs == null:
		path.append(at)
		path.append((at + Vector2(260, 0)).clamp(game.ARENA.position + Vector2(80, 80), game.ARENA.end - Vector2(80, 80)))
		return path
	var parent := PackedInt32Array()
	parent.resize(obs.blocked.size())
	parent.fill(-1)
	var todo := PackedInt32Array()
	var start := obs.cell_at(at)
	parent[start] = start
	todo.append(start)
	var read := 0
	var goal := start
	var best := 0.0
	while read < todo.size() and read < 1500:
		var c := todo[read]
		read += 1
		var p := obs.cell_center(c)
		var distance := p.distance_to(at)
		if distance > 320.0:
			continue
		var score := p.distance_to(game.player.position) + distance * 0.2
		if distance >= 180.0 and score > best:
			goal = c
			best = score
		for next: int in [c - 1, c + 1, c - obs.grid_w, c + obs.grid_w]:
			if next < 0 or next >= parent.size() or parent[next] >= 0 or obs.blocked[next] != 0:
				continue
			if absi(next % obs.grid_w - c % obs.grid_w) + absi(next / obs.grid_w - c / obs.grid_w) != 1:
				continue
			if obs.contains(obs.cell_center(next), 14.0):
				continue
			parent[next] = c
			todo.append(next)
	while goal != start:
		path.append(obs.cell_center(goal))
		goal = parent[goal]
	path.append(at)
	path.reverse()
	return path


func begin(value: int, at := Vector2.INF) -> bool:
	if is_active():
		return false
	kind = value as Kind
	target = find_site() if at == Vector2.INF else at
	if not valid_site(target):
		return false
	phase = Phase.OFFER
	_age = 0.0
	_work = 0.0
	_fuse = -1.0
	_wave_at = 0.0
	_carrier_uid = -1
	_route.clear()
	_waypoint = 1
	_shot_start = false
	_shot_peak = false
	_support = -1.0
	_shot_cd = 0.0
	_flash = 0.0
	_bullet_pos.clear()
	_bullet_vel.clear()
	_bullet_life.clear()
	_marked = false
	_beep_second = 6
	_salvo = 0
	_strike_safe = true
	if kind == Kind.ARTILLERY:
		_strike_axis = strike_axis(target)
	if kind == Kind.CARRIER:
		_route = make_route(target)
		if _route.size() < 5:
			phase = Phase.IDLE
			return false
		# Резервируем место в прежнем cap, без скрытой прибавки плотности.
		if game.horde.count >= int(game.spawner.current_row()[2]):
			phase = Phase.IDLE
			return false
		var i: int = game.horde.spawn(target, Horde.Kind.RUNNER)
		if i < 0:
			phase = Phase.IDLE
			return false
		_carrier_uid = game.horde.uid[i]
		_carrier_speed = game.horde.speed[i]
		game.horde.speed[i] = 0.0
		# Достаточно времени догнать, но обычная пуля всё ещё эффективна.
		game.horde.hp[i] *= 8.0
		game.horde.max_hp[i] = game.horde.hp[i]
	offered += 1
	game.sfx.play(Sfx.ACTIVITY_CUES["offer"], target, -6.0)
	_log("start")
	_floor.queue_redraw()
	queue_redraw()
	return true


func _physics_process(delta: float) -> void:
	if game == null:
		return
	if game.game_over or game.player.is_dead:
		clear()
		return
	if _spent_life > 0.0:
		_spent_life = maxf(0.0, _spent_life - delta)
		queue_redraw()
	if not enabled:
		return
	# Бесконечный режим хранит только ближайшее предложение, без растущего журнала.
	if game.endless and _next >= schedule.size() and game.time >= 535.0:
		schedule.assign([{"time": game.time + _rng.randf_range(110.0, 150.0), "kind": _rng.randi_range(Kind.SUPPLY, Kind.ARTILLERY)}])
		_next = 0
	if priority_event():
		if is_active():
			finish(false)
		elif _next < schedule.size() and game.time >= float(schedule[_next]["time"]) + 45.0:
			_next += 1
			_defer_until = -1.0
		return
	if not is_active():
		if _next < schedule.size() and game.time >= float(schedule[_next]["time"]) and game.time >= _cool_until:
			if game.time >= float(schedule[_next]["time"]) + 45.0:
				_next += 1 # Перемотка не создаёт очередь просроченных эпизодов.
				_defer_until = -1.0
				return
			if _defer_until < 0.0:
				_defer_until = game.time + 15.0
			if game.spawner.director and not game.spawner.director.activity_window(game.time):
				return
			var dangerous: bool = game.player.hp < game.player.max_hp * 0.35 or game.time - _last_hurt < 5.0 or game.horde.query_radius(game.player.position, 90.0).size() >= 12
			if not dangerous:
				begin(int(schedule[_next]["kind"]))
			elif game.time < _defer_until:
				return
			else:
				begin(int(schedule[_next]["kind"])) # Предложение не добавляет волн; вход в риск добровольный.
			_next += 1
			_defer_until = -1.0
		return
	advance(delta)


## Отдельный шаг позволяет тестировать настоящие переходы без перемотки дерева.
func advance(delta: float) -> void:
	if not is_active():
		return
	_age += delta
	_flash = maxf(0.0, _flash - delta)
	update_bullets(delta)
	# Эпизод не залезает на снабжение, тревогу, выход и босса.
	if priority_event():
		finish(false)
		return
	var near: bool = game.player.position.distance_to(target) <= HOLD_RADIUS
	match kind:
		Kind.SUPPLY:
			if near:
				phase = Phase.ACTIVE
				_work += delta
			if phase == Phase.ACTIVE:
				pressure()
			if _work >= HOLD:
				finish(true)
		Kind.CARRIER:
			var i := carrier_index()
			if i < 0 or game.horde.dead[i] == 1:
				finish(true)
				return
			if phase == Phase.OFFER and game.player.position.distance_to(target) > 240.0:
				if _age >= 55.0:
					finish(false)
				return
			phase = Phase.ACTIVE
			target = game.horde.pos[i]
			if game.horde.freeze_t[i] <= 0.0:
				var destination := _route[_waypoint]
				var to := target.move_toward(destination, CARRIER_SPEED * (1.0 - game.horde.chill[i]) * delta)
				game.horde.pos[i] = game.obstacles.move_actor(target, to, game.horde.radius[i]) if game.obstacles else to
				game.horde.angle[i] = (destination - target).angle()
				target = game.horde.pos[i]
				if target.distance_to(destination) < 8.0:
					_waypoint += 1
					if _waypoint >= _route.size():
						finish(false)
		Kind.FUEL:
			# Рычаг смещён к правому краю топливной группы.
			var lever := target + Vector2(28, 16)
			if _fuse < 0.0:
				if game.player.position.distance_to(lever) < 25.0:
					_work += delta
				else:
					_work = 0.0
				if _work >= 2.0:
					phase = Phase.ACTIVE
					_fuse = FUSE
					game.sfx.play("ui/click", Vector2.INF, -4.0)
					pressure()
			else:
				_fuse -= delta
				if _fuse <= 0.0:
					detonate()
		Kind.APC:
			var panel := target + Vector2(25, 40)
			if game.player.position.distance_to(panel) < 22.0:
				activate()
				_work += delta
			if phase == Phase.ACTIVE:
				pressure()
			if _work >= HACK_TIME:
				finish(true)
		Kind.TURRET:
			if _support < 0.0:
				if game.player.position.distance_to(target + Vector2(-18, 16)) < 25.0:
					activate()
					_work += delta
				else:
					_work = maxf(0.0, _work - delta)
				if _work >= GENERATOR_TIME:
					_support = TURRET_TIME
					game.sfx.play(Sfx.ACTIVITY_CUES["powered"], target, -3.0)
			else:
				_support -= delta
				turret_fire(delta)
				if _support <= 0.0:
					finish(true)
			if phase == Phase.ACTIVE:
				pressure()
		Kind.ARTILLERY:
			if not _marked:
				if near:
					activate()
					_work += delta
				if _work >= 2.0:
					_marked = true
					_fuse = STRIKE_DELAY
					_floor.queue_redraw()
					game.sfx.play(Sfx.ACTIVITY_CUES["powered"], target, -3.0)
			else:
				_fuse -= delta
				var second := ceili(_fuse)
				if second > 0 and second < _beep_second:
					_beep_second = second
					game.sfx.play(Sfx.ACTIVITY_CUES["start"], target, -8.0)
				_floor.queue_redraw()
				if _fuse <= -float(_salvo) * 0.32:
					artillery_strike()
			if phase == Phase.ACTIVE:
				pressure()
	if is_active() and _age >= (55.0 if kind == Kind.CARRIER else 70.0):
		finish(false)
	if is_active() and OS.get_cmdline_user_args().has("--activities-capture") and DisplayServer.get_name() != "headless":
		if not _shot_start and PixelArt.view_rect(self, -25.0).has_point(target):
			_shot_start = true
			_live_shot.call_deferred("start")
		var peak := _fuse >= 0.0 and _fuse <= 2.0 if kind == Kind.FUEL else progress() >= 0.65
		if kind == Kind.ARTILLERY:
			peak = _salvo >= 2
		elif kind == Kind.TURRET:
			peak = _support >= 0.0 and _support <= TURRET_TIME * 0.6
		if not _shot_peak and peak:
			_shot_peak = true
			_live_shot.call_deferred("peak")
	queue_redraw()


func _live_shot(stage: String) -> void:
	var path := "res://design/tasks/reports/ev2_live_%s_%d_%s.png" % [NAMES[kind], offered, stage]
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("ACTIVITYSHOT live=true ", path)


func pressure() -> void:
	if game.spawner.director and not game.spawner.director.activity_window(game.time):
		return
	if _age < _wave_at:
		return
	_wave_at = _age + 6.0 # Пропущенные волны не догоняют игрока очередью.
	game.spawner.activity_wave(6 if game.time < 180.0 else 10)


func priority_event() -> bool:
	if game.endless:
		return Spawner.storm_pending(game.time) or game.spawner.alarm or game.blood_alarm.phase in [BloodAlarm.Phase.WARN, BloodAlarm.Phase.ACTIVE]
	return (game.time >= 285.0 and game.time < 315.0) or (game.time >= 405.0 and game.time < 460.0) or game.time >= 535.0 or game.spawner.alarm or game.blood_alarm.phase in [BloodAlarm.Phase.WARN, BloodAlarm.Phase.ACTIVE] or game.boss.is_alive() or (game.objective != null and game.objective.spawned)


func activate() -> void:
	if phase == Phase.OFFER:
		phase = Phase.ACTIVE
		game.sfx.play(Sfx.ACTIVITY_CUES["start"], target, -4.0)
		_log("contact")


func turret_fire(delta: float) -> void:
	_shot_cd -= delta
	if _shot_cd > 0.0:
		return
	_shot_cd = TURRET_RATE # Ни залпа накопленного долга, ни Node на пулю.
	var origin := target + Vector2(13, -5)
	var best := 260.0 * 260.0
	var victim := -1
	for i in game.horde.query_radius(origin, 260.0):
		var d: float = origin.distance_squared_to(game.horde.pos[i])
		if game.horde.dead[i] == 0 and d < best and (game.obstacles == null or game.obstacles.line_clear(origin, game.horde.pos[i])):
			best = d
			victim = i
	if victim < 0 or _bullet_pos.size() >= 24:
		return
	_aim = (game.horde.pos[victim] - origin).normalized()
	_bullet_pos.append(origin + _aim * 4.0)
	_bullet_vel.append(_aim * 620.0)
	_bullet_life.append(0.45)
	_flash = 0.065
	support_shots += 1
	game.sfx.play("weapons/rifle/shot", origin, -9.0)


func update_bullets(delta: float) -> void:
	for b in range(_bullet_pos.size() - 1, -1, -1):
		var from := _bullet_pos[b]
		var to := from + _bullet_vel[b] * delta
		_bullet_life[b] -= delta
		var victim := -1
		var nearest := INF
		for i in game.horde.query_radius((from + to) * 0.5, from.distance_to(to) * 0.5 + 18.0):
			if game.horde.dead[i] != 0:
				continue
			var p := Geometry2D.get_closest_point_to_segment(game.horde.pos[i], from, to)
			if p.distance_to(game.horde.pos[i]) <= game.horde.radius[i] + 2.0 and from.distance_squared_to(p) < nearest:
				nearest = from.distance_squared_to(p)
				victim = i
		if game.obstacles and not game.obstacles.line_clear(from, to):
			_bullet_life[b] = 0.0
		elif victim >= 0:
			game.horde.damage(victim, TURRET_DAMAGE, _bullet_vel[b].normalized(), 35.0, WeaponDefs.Ammo.STANDARD, false, game.horde.pos[victim])
			support_hits += 1
			_bullet_life[b] = 0.0
		_bullet_pos[b] = to
		if _bullet_life[b] <= 0.0:
			_bullet_pos.remove_at(b)
			_bullet_vel.remove_at(b)
			_bullet_life.remove_at(b)


func strike_center() -> Vector2:
	return target - _strike_axis.orthogonal() * 80.0


func artillery_strike() -> void:
	var at := strike_center() + _strike_axis * (float(_salvo) * 40.0 - 100.0)
	game.explosions.spawn(at, STRIKE_RADIUS, Explosions.Kind.LAUNCHER)
	game.sfx.play("explosions/grenade", at, -3.0)
	area_damage(at, STRIKE_RADIUS, STRIKE_DAMAGE)
	if game.player.position.distance_to(at) < STRIKE_RADIUS + Player.RADIUS:
		game.player.take_damage(40.0)
		_strike_safe = false
	_salvo += 1
	artillery_blasts += 1
	if _salvo >= 6:
		finish(_strike_safe)


func area_damage(at: Vector2, radius: float, damage: float) -> void:
	# Уплотнение и взрывы толстяков не меняют список целей текущего удара.
	var victims := PackedInt32Array()
	for i in game.horde.query_radius(at, radius):
		victims.append(game.horde.uid[i])
	for id: int in victims:
		for i in game.horde.count:
			if game.horde.uid[i] == id:
				game.horde.damage(i, damage, (game.horde.pos[i] - at).normalized(), 230.0, WeaponDefs.Ammo.EXPANSIVE, false, game.horde.pos[i], true)
				break


func carrier_index() -> int:
	if _carrier_uid < 0:
		return -1
	for i in game.horde.count:
		if game.horde.uid[i] == _carrier_uid:
			return i
	return -1


## Только бот --sim: кратчайший путь пересчитывается не чаще двух раз в секунду.
func bot_target(delta: float) -> Vector2:
	var goal := target
	if kind == Kind.FUEL:
		goal += Vector2(115, 30) if _fuse >= 0.0 else Vector2(28, 16)
	elif kind == Kind.APC:
		goal += Vector2(25, 40)
	elif kind == Kind.TURRET:
		goal += Vector2(-18, 16)
	elif kind == Kind.ARTILLERY and _marked:
		goal += _strike_axis.orthogonal() * 65.0
	var obs: Obstacles = game.obstacles
	if obs == null or obs.line_clear(game.player.position, goal):
		return goal
	_bot_at -= delta
	if _bot_at <= 0.0:
		_bot_at = 0.5
		_bot_path = path_between(game.player.position, goal)
	while _bot_path.size() > 1 and game.player.position.distance_to(_bot_path[0]) < 18.0:
		_bot_path.remove_at(0)
	return _bot_path[0] if not _bot_path.is_empty() else goal


func path_between(from: Vector2, to: Vector2) -> PackedVector2Array:
	var obs: Obstacles = game.obstacles
	var path := PackedVector2Array()
	if obs == null:
		path.append(to)
		return path
	var parent := PackedInt32Array()
	parent.resize(obs.blocked.size())
	parent.fill(-1)
	var first := obs.cell_at(obs.free_point(from, 19.0))
	var last := obs.cell_at(obs.free_point(to, 19.0))
	parent[first] = first
	var todo := PackedInt32Array([first])
	var read := 0
	while read < todo.size() and parent[last] < 0:
		var c := todo[read]
		read += 1
		for next: int in [c - 1, c + 1, c - obs.grid_w, c + obs.grid_w]:
			if next < 0 or next >= parent.size() or parent[next] >= 0 or obs.blocked[next] != 0:
				continue
			if absi(next % obs.grid_w - c % obs.grid_w) + absi(next / obs.grid_w - c / obs.grid_w) != 1:
				continue
			parent[next] = c
			todo.append(next)
	if parent[last] < 0:
		return path
	while last != first:
		path.append(obs.cell_center(last))
		last = parent[last]
	path.reverse()
	return path


func detonate() -> void:
	var safe: bool = game.player.position.distance_to(target) > BLAST_RADIUS + Player.RADIUS
	game.explosions.spawn(target, BLAST_RADIUS, Explosions.Kind.GRENADE)
	game.sfx.play("explosions/grenade", target, -3.0)
	# Сначала сохраняем uid: цепная реакция может уплотнить строки орды.
	var victims := PackedInt32Array()
	for i in game.horde.query_radius(target, BLAST_RADIUS):
		victims.append(game.horde.uid[i])
	for id: int in victims:
		for i in game.horde.count:
			if game.horde.uid[i] == id:
				game.horde.damage(i, BLAST_DAMAGE, (game.horde.pos[i] - target).normalized(), 160.0, WeaponDefs.Ammo.EXPANSIVE, false, game.horde.pos[i], true)
				break
	if not safe:
		game.player.take_damage(40.0)
	_spent_at = target
	_spent_life = 12.0
	finish(safe)


func finish(success: bool) -> void:
	if not is_active():
		return
	if phase == Phase.ACTIVE and game.spawner.director:
		game.spawner.director.activity_finished(game.time)
	phase = Phase.RESOLVED # До выдачи награды и её сигналов.
	_bullet_pos.clear()
	_bullet_vel.clear()
	_bullet_life.clear()
	_restore_carrier()
	if success:
		succeeded += 1
		rewards += 1
		match kind:
			Kind.SUPPLY, Kind.APC:
				game.pickups.spawn(target, Pickups.Kind.ACTIVITY_MODULE)
			Kind.CARRIER:
				game.pickups.spawn(target, Pickups.Kind.MEDKIT)
				game.gems.spawn(target, 35)
			Kind.FUEL:
				game.credit_drops.spawn(target + Vector2(0, 20), 18)
		game.sfx.play(Sfx.ACTIVITY_CUES["success"], Vector2.INF, -6.0)
	else:
		failed += 1
		game.sfx.play(Sfx.ACTIVITY_CUES["failure"], Vector2.INF, -8.0)
	_cool_until = game.time + 25.0
	_log("success" if success else "failed")
	_floor.queue_redraw()
	_route.clear()
	_bot_path.clear()
	target = Vector2.INF
	queue_redraw()


func _restore_carrier() -> void:
	var i := carrier_index()
	if i >= 0:
		game.horde.speed[i] = _carrier_speed
	_carrier_uid = -1


func clear() -> void:
	_restore_carrier()
	phase = Phase.IDLE
	target = Vector2.INF
	_route.clear()
	_bot_path.clear()
	_defer_until = -1.0
	_next = schedule.size()
	_fuse = -1.0
	_work = 0.0
	_support = -1.0
	_bullet_pos.clear()
	_bullet_vel.clear()
	_bullet_life.clear()
	_spent_life = 0.0
	_spent_at = Vector2.INF
	enabled = false
	for i in range(game.pickups.count - 1, -1, -1):
		if game.pickups._kind[i] == Pickups.Kind.ACTIVITY_MODULE:
			game.pickups._remove(i)
	set_physics_process(false)
	_floor.queue_redraw()
	queue_redraw()


func _exit_tree() -> void:
	if is_instance_valid(_floor):
		_floor.queue_free()


## Топливо и матовая разметка находятся под живыми телами, не закрашивают героя.
func _draw_floor() -> void:
	if not is_active():
		return
	if kind == Kind.SUPPLY:
		_floor.draw_texture_rect(_zone, Rect2(target - Vector2(52, 52), Vector2(104, 104)), false)
	elif kind == Kind.FUEL:
		_floor.draw_texture_rect(_fuel_zone, Rect2(target - Vector2(76, 76), Vector2(152, 152)), false)
	elif kind == Kind.ARTILLERY:
		_floor.draw_set_transform(strike_center(), _strike_axis.angle())
		# Краска с просветами: тела и кислота остаются видны.
		var color := Color("c4b38c") if not _marked else Color("d99362")
		for x in range(-140, 141, 20):
			for y: float in [-46.0, 46.0]:
				_floor.draw_line(Vector2(x, y), Vector2(x + 8, y), Color("242821"), 5.0)
				_floor.draw_line(Vector2(x, y), Vector2(x + 8, y), color, 2.0)
		for j in 6:
			var at := Vector2(float(j) * 40.0 - 100.0, 0)
			var mark := Color("625e4c") if _marked and (j < _salvo or float(j) > STRIKE_DELAY - _fuse) else color
			_floor.draw_line(at - Vector2(5, 0), at + Vector2(5, 0), mark, 2.0)
			_floor.draw_line(at - Vector2(0, 5), at + Vector2(0, 5), mark, 2.0)
		_floor.draw_set_transform(Vector2.ZERO)


func _log(event: String) -> void:
	if verbose:
		print("ACTIVITY event=%s kind=%s time=%.2f age=%.2f pos=%s offered=%d success=%d failed=%d rewards=%d shots=%d hits=%d blasts=%d" % [event, NAMES[kind], game.time, _age, target, offered, succeeded, failed, rewards, support_shots, support_hits, artillery_blasts])


func _draw() -> void:
	for b in _bullet_pos.size():
		var at := _bullet_pos[b]
		draw_line(at - _bullet_vel[b].normalized() * 10.0, at, Color("f0dab0"), 1.4)
	if _spent_life > 0.0:
		draw_texture_rect(_spent, Rect2(_spent_at - Vector2(39, 32), Vector2(78, 64)), false, Color(1, 1, 1, minf(1.0, _spent_life)))
	if not is_active():
		return
	match kind:
		Kind.SUPPLY:
			# Дым остаётся сбоку от бойца; максимум три полупрозрачных спрайта.
			if phase == Phase.OFFER:
				var sway := sin(_age * 1.5) * 3.0
				draw_texture_rect(_smoke, Rect2(target + Vector2(-38 + sway, -65), Vector2(42, 64)), false)
			var descent := (1.0 - _work / HOLD) * 50.0 if phase == Phase.ACTIVE else 50.0
			draw_texture_rect(_parachute, Rect2(target + Vector2(-38, -79 - descent), Vector2(76, 76)), false)
			draw_texture_rect(_textures[kind], Rect2(target + Vector2(-26, -21 - descent), Vector2(52, 42)), false)
			# Реальные лампы на мешках включаются по мере удержания.
			for j in 4:
				var at := target + Vector2(-35 if j % 2 == 0 else 35, -35 if j < 2 else 35)
				draw_rect(Rect2(at - Vector2(2, 1), Vector2(4, 2)), Color("c8bd81") if _work / HOLD >= float(j + 1) / 4.0 else Color("484b3b"))
		Kind.CARRIER:
			var i := carrier_index()
			if i >= 0:
				# Кофр прикреплён к спине, не висит над врагом как HUD.
				draw_set_transform(target, game.horde.angle[i] + PI * 0.5)
				draw_texture_rect(_textures[kind], Rect2(-6, 0, 12, 13), false)
				draw_set_transform(Vector2.ZERO)
		Kind.FUEL:
			draw_texture_rect(_textures[kind], Rect2(target - Vector2(39, 32), Vector2(78, 64)), false)
			if _fuse >= 0.0:
				var blink := fmod(_fuse, maxf(0.15, _fuse * 0.15)) < 0.08
				draw_rect(Rect2(target + Vector2(29, 10), Vector2(2, 2)), Color("e1a25e") if blink else Color("534b32"))
		Kind.APC:
			draw_texture_rect(_textures[kind], Rect2(target - Vector2(44, 29), Vector2(88, 58)), false)
			for j in 6:
				draw_rect(Rect2(target + Vector2(20 + j * 2, 24), Vector2(1, 3)), Color("d3c68f") if progress() >= float(j + 1) / 6.0 else Color("2b352a"))
		Kind.TURRET:
			draw_texture_rect(_textures[kind], Rect2(target - Vector2(30, 22), Vector2(60, 44)), false)
			for j in 4:
				draw_rect(Rect2(target + Vector2(-24 + j * 3, 2), Vector2(2, 1)), Color("d3c68f") if _work >= float(j + 1) else Color("29392c"))
			var pivot := target + Vector2(13, -5)
			draw_set_transform(pivot, _aim.angle())
			draw_texture_rect(_barrel, Rect2(-3, -4.5, 35, 9), false)
			if _flash > 0.0:
				draw_line(Vector2(32, 0), Vector2(39, -1), Color("ffdc9a"), 3.0)
				draw_line(Vector2(34, -4), Vector2(36, 4), Color("e7b475"), 2.0)
			draw_set_transform(Vector2.ZERO)
			draw_rect(Rect2(target + Vector2(-10, 6), Vector2(3, 2)), Color("cfbc7d") if _support >= 0.0 else Color("514d34"))
		Kind.ARTILLERY:
			draw_texture_rect(_textures[kind], Rect2(target - Vector2(19, 22), Vector2(38, 44)), false)
			if _fuse >= 0.0:
				draw_rect(Rect2(target + Vector2(-8, 7), Vector2(5, 2)), Color("d4b875") if fmod(_age, 0.5) < 0.25 else Color("3a4432"))
