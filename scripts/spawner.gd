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

var horde: Horde
var player: Player
var time := 0.0
var enabled := true
var alarm := false # идёт кровавая тревога: берём ALARM_ROW (ставит BloodAlarm)
var elites_spawned := 0 # для отчёта --sim

var _budget := 0.0
var _next_group := 4
var _next_pack := false # следующая группа — пачка бегунов
var _next_elite := ELITE_START
var _wave_angle := 0.0
var _last_directional := false


func _physics_process(delta: float) -> void:
	if not enabled or horde == null or player.is_dead:
		return
	var row := current_row()
	var rate: float = row[1]
	var cap: int = row[2]
	var shares: Array = row[3]

	if time >= _next_elite:
		_next_elite += ELITE_PERIOD
		if _next_elite < time: # перемотка времени — не выдаём очередь элиток
			_next_elite = time + ELITE_PERIOD
		spawn_elites(1)

	_budget += rate * delta
	# копим «бюджет» и выпускаем зомби группами — так орда читается как волна
	if _budget >= _next_group:
		var room := cap - horde.count
		if room <= 0:
			_budget = minf(_budget, float(_next_group))
			return
		var n := mini(_next_group, room)
		_spawn_group(n, shares)
		_budget -= n
		_roll_group(shares)


## Строка кривой для текущего момента (тревога подменяет её).
func current_row() -> Array:
	if alarm:
		return ALARM_ROW
	var row: Array = CURVE[0]
	for p: Array in CURVE:
		if time >= p[0]:
			row = p
	return row


func current_rate() -> float:
	return current_row()[1]


## n элиток сразу (тип — по долям текущей фазы), кольцо вокруг точки спавна.
func spawn_elites(n: int) -> void:
	var shares: Array = current_row()[3]
	var origin := horde.spawn_point(player.global_position)
	var base := randf() * TAU
	for j in n:
		var p := origin + Vector2.from_angle(base + TAU * j / maxf(n, 1.0)) * (24.0 if n > 1 else 0.0)
		horde.spawn(p, _pick_kind(shares, true), true)
		elites_spawned += 1


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
	var center := player.global_position
	var directional := randf() < DIRECTIONAL_CHANCE
	var origin := Vector2.ZERO
	var tangent := Vector2.ZERO
	if directional:
		# подряд идущие стены держатся одной стороны, новая — со случайной
		_wave_angle = _wave_angle + randf_range(-0.3, 0.3) if _last_directional else randf() * TAU
		var inner := horde.arena.grow(-Horde.RADIUS * 2.0)
		origin = (center + Vector2.from_angle(_wave_angle) * horde.spawn_ring).clamp(inner.position, inner.end)
		tangent = Vector2.from_angle(_wave_angle).orthogonal()
	else:
		origin = horde.spawn_point(center)
	_last_directional = directional

	var fats := 0
	var spitters := 0
	for j in n:
		var k := Horde.Kind.RUNNER
		if not _next_pack:
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
