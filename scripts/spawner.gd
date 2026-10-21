class_name Spawner
extends Node
## Кривая спавна из BALANCE.md §7.1: темп, лимит и доли типов по времени забега.
## Шаркающие идут группами 5–15, бегуны — пачками 8–12, толстяки и плевальщики
## (по 1–3) подмешаны в общие группы. Элитки: с 5:00 раз в 30 с.

# [начало_сек, спавн/сек, лимит живых, доли [шарк, бегун, толстяк, плевальщик]]
const CURVE := [
	[0.0, 1.5, 60, [100, 0, 0, 0]],
	[60.0, 3.0, 100, [100, 0, 0, 0]],
	[120.0, 4.0, 150, [80, 20, 0, 0]],
	[210.0, 5.0, 200, [70, 20, 10, 0]],
	[240.0, 6.0, 250, [70, 20, 10, 0]],
	[300.0, 7.0, 300, [60, 20, 10, 10]],
	[360.0, 8.0, 350, [60, 20, 10, 10]],
	[450.0, 9.0, 400, [55, 25, 10, 10]],
	[480.0, 11.0, 500, [55, 25, 10, 10]],
	[540.0, 3.0, 100, [70, 30, 0, 0]], # 9:00 затишье + торговец
	[570.0, 4.0, 150, [70, 30, 0, 0]], # 9:30 предупреждение о боссе
	[600.0, 4.0, 150, [70, 30, 0, 0]], # 10:00 босс
]
# строка «7:00 тревога»: подменяет кривую, пока идут 30 с тревоги (BloodAlarm)
const ALARM_ROW := [420.0, 24.0, 500, [50, 35, 10, 5]]

const RUNNER_PACK := Vector2i(8, 12)
const GROUP_EARLY := Vector2i(3, 6) # до 1:00
const GROUP_NORMAL := Vector2i(5, 15)
const SPECIAL_MAX := 3 # толстяков и плевальщиков в одной группе не больше
const DIRECTIONAL_CHANCE := 0.2 # доля групп «стеной» с одной стороны
const WAVE_WIDTH := 120.0 # длина стены направленной волны
const ELITE_START := 300.0
const ELITE_PERIOD := 30.0
# Профиль операции: лимиты и здоровье врагов остаются из исходной кривой.
const MISSION_BALANCE := {
	"rate": [1.0, 1.075, 1.15, 1.225, 1.3], "runner_step": 3.0, "spitter_step": 1.0,
	"elite_step": 2.0, "direction_step": 0.05, "runner_bonus": 25.0, "runner_rate": 1.12,
	"acid_bonus": 18.0, "hunt_start": 180.0, "hunt_period": 90.0, "hunt_count": 3,
	"acid_life": 1.75, "boss_hp": 1.25, "boss_shed": 0.35,
}
# NP1: строка операции «узел». Опорная кривая на полном HP узла (давление 1,0);
# рост давления множит темп и лимит, а доли бегунов и особых растут вместе с ним.
const NODE_BASE := {"rate": 4.2, "cap": 130, "cap_end": 360, "runners": 12.0, "runners_end": 35.0,
	"fat_from": 1.3, "fat_end": 12.0, "spit_from": 1.5, "spit_end": 12.0, "max": 2.1}
# Зов узла на порогах 75/50/25 %: размер всплеска, доля бегунов, число элиток.
const NODE_CALLS := [{"size": 14, "runners": 0.0, "elites": 0}, {"size": 20, "runners": 0.4, "elites": 1},
	{"size": 28, "runners": 0.4, "elites": 3}]

var horde: Horde
var player: Player
var time := 0.0
var endless := false
const ENDLESS_START := 480.0
const ENDLESS_RATE := 9.0
const ENDLESS_RATE_GROWTH := 0.9
const ENDLESS_RATE_ACCELERATION := 0.03
const ENDLESS_INTRO := 0.85 # До сборки арсенала меньше массы, типы открываются вовремя.
const ENDLESS_SHARES := [55, 25, 10, 10]
const STORM_PERIOD := 300.0
const STORM_DURATION := 20.0
const STORM_MULTIPLIER := 1.5
var _endless_row: Array = [0.0, 9.0, 500, [55, 25, 10, 10]]
var enabled := true
var alarm := false # идёт кровавая тревога: берём ALARM_ROW (ставит BloodAlarm)
var elites_spawned := 0 # для отчёта --sim

var _budget := 0.0
var _next_group := 4
var _next_pack := false # следующая группа — пачка бегунов
var _next_elite := ELITE_START
var _wave_angle := 0.0
var _last_directional := false
var profile: Dictionary = {}
var _rows: Array = []
var _alarm_row: Array = []
var _next_hunt := INF
var _objective_row: Array = []
var director: HordeDirector
var director_exclusive := false # События и цели имеют приоритет над обычным циклом.
var total_spawned := 0
var curve_budget := 0.0
var _was_exclusive := false
var node_pressure := 0.0 # 0 — узла нет; иначе множитель давления от HP узла (1,0..2,1)
var node_call_origin := Vector2.INF # откуда придёт всплеск зова (для стрелки HUD)
var node_call_left := 0.0 # >0 от начала предупреждения до падения следующего всплеска
var node_calls := 0 # выпущенных всплесков (для отчёта и тестов)
var node_called := 0 # зомби, выпущенных зовами
var _node_row_p := -1.0


## Бой знает только параметры; география и состояние мира сюда не попадают.
static func combat_profile(config: Dictionary) -> Dictionary:
	if config.is_empty():
		return {}
	var tier := clampi(int(config["threat"]), 1, 5) - 1
	var mods: Array = config["modifiers"]
	return {"extract": config.get("type") == "extract", "rate_mul": float(MISSION_BALANCE["rate"][tier]) * (float(MISSION_BALANCE["runner_rate"]) if mods.has("runner_surge") else 1.0),
		"runner_add": tier * float(MISSION_BALANCE["runner_step"]) + (float(MISSION_BALANCE["runner_bonus"]) if mods.has("runner_surge") else 0.0),
		"spitter_add": tier * float(MISSION_BALANCE["spitter_step"]), "acid": mods.has("acid_rain"),
		"elite_period": ELITE_PERIOD - tier * float(MISSION_BALANCE["elite_step"]),
		"directional": DIRECTIONAL_CHANCE + tier * float(MISSION_BALANCE["direction_step"]),
		"hunt": mods.has("elite_hunt"), "extra_alarm": mods.has("blood_frenzy"),
		"acid_life_mul": float(MISSION_BALANCE["acid_life"]) if mods.has("acid_rain") else 1.0,
		"boss_hp_mul": float(MISSION_BALANCE["boss_hp"]) if mods.has("hardened_boss") else 1.0,
		"boss_shed": float(MISSION_BALANCE["boss_shed"]) if mods.has("hardened_boss") else 0.5}


func set_profile(value: Dictionary) -> void:
	profile = value.duplicate(true)
	_rows.clear()
	_alarm_row.clear()
	_next_elite = ELITE_START
	_next_hunt = float(MISSION_BALANCE["hunt_start"]) if profile.get("hunt", false) else INF
	if profile.is_empty():
		return
	# Строки считаются один раз, без словарей и копирования в горячем цикле.
	for row: Array in CURVE:
		_rows.append(_mission_row(row))
	_alarm_row = _mission_row(ALARM_ROW)


func _mission_row(source: Array) -> Array:
	var row := source.duplicate(true)
	var shares: Array = row[3]
	var runners := float(profile["runner_add"])
	var spitters := float(profile["spitter_add"]) if float(source[0]) >= 300.0 else 0.0
	if profile["acid"] and float(source[0]) >= 120.0:
		spitters += float(MISSION_BALANCE["acid_bonus"])
	shares[0] = maxi(10, int(shares[0]) - int(runners + spitters))
	shares[1] = int(shares[1]) + int(runners)
	shares[3] = int(shares[3]) + int(spitters)
	row[1] = float(row[1]) * float(profile["rate_mul"])
	return row


func _physics_process(delta: float) -> void:
	node_call_left = maxf(0.0, node_call_left - delta)
	if not enabled or horde == null or player.is_dead:
		return
	var row := current_row()
	var rate: float = row[1]
	var cap: int = row[2]
	var shares: Array = row[3]
	curve_budget += rate * delta
	if director:
		var exclusive := director_exclusive or alarm or not _objective_row.is_empty()
		if exclusive != _was_exclusive:
			_budget = 0.0
			_was_exclusive = exclusive
		var multiplier := director.advance(time, delta, shares, exclusive)
		rate *= multiplier
		director.planned += rate * delta

	if time >= _next_elite:
		var period := float(profile.get("elite_period", ELITE_PERIOD))
		if endless and time >= 720.0:
			period = maxf(8.0, 24.0 - (time - 720.0) / 60.0)
		_next_elite += period
		if _next_elite < time: # перемотка времени — не выдаём очередь элиток
			_next_elite = time + period
		var amount := mini(6, 3 + floori((time - 720.0) / 360.0)) if endless and time >= 720.0 else 1
		spawn_elites(amount)
	if time >= _next_hunt:
		_next_hunt = time + float(MISSION_BALANCE["hunt_period"])
		spawn_elites(int(MISSION_BALANCE["hunt_count"]))

	_budget += rate * delta
	# копим «бюджет» и выпускаем зомби группами — так орда читается как волна
	if _budget >= _next_group:
		var room := cap - horde.count
		if room <= 0:
			_budget = minf(_budget, float(_next_group))
			return
		var n := mini(_next_group, room)
		var made := n
		if director and time >= 60.0 and not _was_exclusive and director.phase in [HordeDirector.Phase.BUILD, HordeDirector.Phase.PEAK]:
			var shaped := director.shape_count(n, time)
			made = director.spawn_group(shaped, shares, _next_pack, time) if shaped > 0 else 0
			if made < n:
				_spawn_group(n - made, shares)
				made = n
		else:
			_spawn_group(n, shares)
		total_spawned += made
		if director:
			director.dropped += n - made
		_budget -= n
		_roll_group(shares)


## Строка кривой для текущего момента (тревога подменяет её).
func current_row() -> Array:
	if not _objective_row.is_empty():
		return _objective_row
	if alarm:
		return ALARM_ROW if profile.is_empty() else _alarm_row
	if endless and time >= ENDLESS_START:
		_endless_row[1] = endless_rate(time)
		_endless_row[2] = 500
		_endless_row[3] = ENDLESS_SHARES
		return _endless_row
	var curve: Array = CURVE if profile.is_empty() else _rows
	var row: Array = curve[0]
	for p: Array in curve:
		if time * (1.5 if profile.get("extract", false) else 1.0) >= p[0]:
			row = p
	if endless and time >= 120.0:
		_endless_row[1] = float(row[1]) * ENDLESS_INTRO * (STORM_MULTIPLIER if storm_active(time) else 1.0)
		_endless_row[2] = row[2]
		_endless_row[3] = row[3]
		return _endless_row
	return row


static func storm_active(now: float) -> bool:
	return now >= STORM_PERIOD and fposmod(now, STORM_PERIOD) < STORM_DURATION


static func storm_pending(now: float) -> bool:
	return now >= STORM_PERIOD - 5.0 and fposmod(now + 5.0, STORM_PERIOD) < STORM_DURATION + 5.0


static func endless_rate(now: float) -> float:
	var late := maxf(0.0, (now - 600.0) / 60.0)
	var rate := ENDLESS_RATE + late * ENDLESS_RATE_GROWTH + late * late * ENDLESS_RATE_ACCELERATION
	return rate * (STORM_MULTIPLIER if storm_active(now) else 1.0)


func current_rate() -> float:
	return current_row()[1]


## Короткий штурм активности: прежний cap, без накопленного долга и спавна под ногами.
func activity_wave(want: int) -> int:
	if not enabled or alarm or player.is_dead:
		return 0
	var room := maxi(0, int(current_row()[2]) - horde.count)
	var n := mini(want, room)
	if n > 0:
		_spawn_group(n, current_row()[3])
	return n


## n элиток сразу (тип — по долям текущей фазы), кольцо вокруг точки спавна.
func spawn_elites(n: int) -> void:
	var shares: Array = current_row()[3]
	var origin := horde.spawn_point(player.global_position)
	var base := randf() * TAU
	for j in n:
		if horde.count >= int(current_row()[2]):
			break
		var p := origin + Vector2.from_angle(base + TAU * j / maxf(n, 1.0)) * (24.0 if n > 1 else 0.0)
		var k := _pick_kind(shares, true)
		if director and time >= 60.0 and (endless or not _was_exclusive):
			k = director.accept_kind(k)
			if k == Horde.Kind.RUNNER:
				var source := director.fast_source(p)
				if source == Vector2.INF:
					k = Horde.Kind.SHAMBLER
				else:
					p = source
		if horde.spawn(p, k, true) >= 0:
			elites_spawned += 1


## Фиксированная плотность бенчмарка, но настоящий состав профиля операции.
func fill_benchmark(n: int) -> void:
	var shares: Array = current_row()[3]
	_roll_group(shares)
	_spawn_group(n, shares)


## Решаем, чем будет следующая группа: пачка бегунов или общая.
func _roll_group(shares: Array) -> void:
	var runners: float = shares[Horde.Kind.RUNNER]
	var general: float = shares[Horde.Kind.SHAMBLER] + shares[Horde.Kind.FAT] + shares[Horde.Kind.SPITTER]
	# средний размер пачки и общей группы близок (≈10), поэтому вероятность пачки = доле бегунов
	_next_pack = runners > 0.0 and randf() * (runners + general) < runners
	if _next_pack:
		_next_group = randi_range(RUNNER_PACK.x, RUNNER_PACK.y)
	else:
		var size := GROUP_EARLY if time < 60.0 else GROUP_NORMAL
		_next_group = randi_range(size.x, size.y)


func _spawn_group(n: int, shares: Array) -> void:
	var runner_pack := _next_pack
	var center := player.global_position
	var directional := randf() < float(profile.get("directional", DIRECTIONAL_CHANCE))
	var origin := Vector2.ZERO
	var tangent := Vector2.ZERO
	if not horde.benchmark_spawn and not horde.map_entries.is_empty():
		origin = horde.spawn_point(center)
		_wave_angle = (center - origin).angle()
		tangent = Vector2.from_angle(_wave_angle).orthogonal()
	elif directional:
		# подряд идущие стены держатся одной стороны, новая — со случайной
		_wave_angle = _wave_angle + randf_range(-0.3, 0.3) if _last_directional else randf() * TAU
		var inner := horde.arena.grow(-Horde.RADIUS * 2.0)
		origin = (center + Vector2.from_angle(_wave_angle) * horde.spawn_ring).clamp(inner.position, inner.end)
		tangent = Vector2.from_angle(_wave_angle).orthogonal()
	else:
		origin = horde.spawn_point(center)
	# Остаточные быстрые пачки держат тот же край, пока доживает выбранная атака.
	if director and time >= 60.0 and (endless or not _was_exclusive) and runner_pack:
		var source := director.fast_source(origin)
		if source != Vector2.INF:
			origin = source
			_wave_angle = (center - origin).angle()
			tangent = Vector2.from_angle(_wave_angle).orthogonal()
		else:
			# Закрытый край не переносит смертельную пачку за спину.
			runner_pack = false
	_last_directional = directional

	var fats := 0
	var spitters := 0
	for j in n:
		var k := Horde.Kind.RUNNER
		if not runner_pack:
			k = _pick_kind(shares, false)
			if k == Horde.Kind.FAT:
				fats += 1
				if fats > SPECIAL_MAX:
					k = Horde.Kind.SHAMBLER
			elif k == Horde.Kind.SPITTER:
				spitters += 1
				if spitters > SPECIAL_MAX:
					k = Horde.Kind.SHAMBLER
		var off := Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
		if director and time >= 60.0 and (endless or not _was_exclusive):
			k = director.accept_kind(k)
		if directional:
			off = tangent * randf_range(-WAVE_WIDTH * 0.5, WAVE_WIDTH * 0.5) + Vector2.from_angle(_wave_angle) * randf_range(0.0, 20.0)
		horde.spawn(origin + off, k)


## Тип по долям; для общих групп бегунов исключаем (они идут пачками).
func _pick_kind(shares: Array, with_runners: bool) -> int:
	var total := 0.0
	for k in shares.size():
		if with_runners or k != Horde.Kind.RUNNER:
			total += shares[k]
	var r := randf() * total
	for k in shares.size():
		if not with_runners and k == Horde.Kind.RUNNER:
			continue
		r -= shares[k]
		if r < 0.0:
			return k
	return Horde.Kind.SHAMBLER


## Давление от HP узла: 0 снимает его (узел разрушен), иначе пересобирает строку операции.
func set_node_pressure(value: float) -> void:
	node_pressure = value
	if value <= 0.0:
		_objective_row.clear()
		_node_row_p = -1.0
		return
	if absf(value - _node_row_p) < 0.01 and not _objective_row.is_empty():
		return
	_node_row_p = value
	_objective_row = _mission_row(node_row(value))


## Строка кривой для давления p (1,0 — полное HP узла). Чистая функция для тестов и графика.
static func node_row(p: float) -> Array:
	var k := clampf((p - 1.0) / (float(NODE_BASE["max"]) - 1.0), 0.0, 1.0)
	var runners := lerpf(float(NODE_BASE["runners"]), float(NODE_BASE["runners_end"]), k)
	var fat := float(NODE_BASE["fat_end"]) * clampf((p - float(NODE_BASE["fat_from"])) / (float(NODE_BASE["max"]) - float(NODE_BASE["fat_from"])), 0.0, 1.0)
	var spit := float(NODE_BASE["spit_end"]) * clampf((p - float(NODE_BASE["spit_from"])) / (float(NODE_BASE["max"]) - float(NODE_BASE["spit_from"])), 0.0, 1.0)
	return [0.0, float(NODE_BASE["rate"]) * p, int(lerpf(float(NODE_BASE["cap"]), float(NODE_BASE["cap_end"]), k)),
		[int(100.0 - runners - fat - spit), int(runners), int(fat), int(spit)]]


## Узел начинает звать: точка входа выбирается заранее, чтобы HUD показал сторону.
func node_call_prepare(node_at: Vector2, warning: float) -> void:
	node_call_origin = _node_call_point(node_at)
	node_call_left = warning + 2.5


## Всплеск зова: порция орды из-за края экрана со стороны узла, в пределах лимита.
func node_call(step: int) -> int:
	var spec: Dictionary = NODE_CALLS[clampi(step, 1, NODE_CALLS.size()) - 1]
	var origin := node_call_origin if node_call_origin.is_finite() else horde.spawn_point(player.global_position)
	var room := int(current_row()[2]) + 40 - horde.count
	var n := mini(int(spec["size"]), room)
	var shares: Array = current_row()[3]
	var made := 0
	var runners := int(round(n * float(spec["runners"])))
	for j in n:
		var kind := Horde.Kind.RUNNER if j < runners else _pick_kind(shares, false)
		var off := Vector2(randf_range(-WAVE_WIDTH * 0.5, WAVE_WIDTH * 0.5), randf_range(-24.0, 24.0))
		if horde.spawn(origin + off, kind) >= 0:
			made += 1
	for j in int(spec["elites"]):
		if horde.spawn(origin + Vector2.from_angle(TAU * float(j) / 3.0) * 24.0, Horde.Kind.RUNNER, true) >= 0:
			elites_spawned += 1
			made += 1
	node_calls += 1
	node_called += made
	total_spawned += made
	node_call_left = 2.5
	return made


## Ближайший к узлу вход за краем экрана; без входов — обычная точка спавна.
func _node_call_point(node_at: Vector2) -> Vector2:
	if not horde.benchmark_spawn and not horde.map_entries.is_empty():
		var view := PixelArt.view_rect(horde, 88.0)
		var best := Vector2.INF
		var best_distance := INF
		for entry in horde.map_entries:
			if view.has_point(entry):
				continue
			var d := node_at.distance_squared_to(entry)
			if d < best_distance:
				best = entry
				best_distance = d
		if best != Vector2.INF:
			return horde.obstacles.free_point(best, Horde.RADIUS * 2.0) if horde.obstacles else best
	return horde.spawn_point(player.global_position)


## После открытия цели — усиленный штурм в пределах прежнего лимита.
func objective_pressure(extraction: bool) -> void:
	_objective_row = _mission_row(CURVE[6]) if not profile.is_empty() else CURVE[6].duplicate(true)
	_objective_row[3][1] += 25 if extraction else 10
	_next_hunt = time
	profile["hunt"] = true
