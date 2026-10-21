class_name CampaignNode
extends Boss
## Неподвижная структура; использует общий протокол попаданий оружия.
## NP1: чем меньше HP, тем сильнее давление орды; на порогах 75/50/25 % узел «зовёт» орду,
## на последней четверти ещё и огрызается кислотными плевками с предупреждением.

signal call_started(step: int) # узел набирает воздух: начало предупреждения зова
signal call_released(step: int) # зов закончился: всплеск орды
signal bite_started # замах плевка
signal bite_launched # плевки вылетели

var _node_tex: Texture2D
var _damaged_tex: Texture2D
var _critical_tex: Texture2D
var _ruined_tex: Texture2D
var _roots_tex: Texture2D
var _collapse := -1.0
var _obstacle := -1
const NODE_RADIUS := 28.0
const NODE_RECT := Rect2(-40, -52, 80, 72)
const THRESHOLDS := [0.75, 0.5, 0.25] # доли HP, на которых узел зовёт орду
const PRESSURE_LOSS := 0.85 # прибавка давления за всё потерянное HP
const PRESSURE_AGITATION := 0.25 # прибавка за недавний урон; вместе с потерей даёт 2,1 в конце
const AGITATION_SCALE := 0.04 # доля HP узла, снятая «залпом», до полного возбуждения
const AGITATION_DECAY := 1.0 / 60.0 # возбуждение стекает за минуту
const RISE := 0.5 # давление растёт быстро (в секунду)
const FALL := 0.01 # и спадает медленно: отойти и вернуться не сбрасывает его
const CALL_WARNING := 1.6
const CALL_GAP := 3.0 # зовы не идут впритык, даже если один удар снял несколько порогов
const BITE_PERIOD := [7.0, 5.0] # огрызание: последняя четверть / последняя десятая
const BITE_WINDUP := 0.8
const BITE_DAMAGE := 9.0
const BITE_RANGE := 420.0
const BITE_COUNT := 3
const WARN_COLOR := Color(0.72, 0.2, 0.13)

var pressure := 1.0 # множитель давления орды: 1,0 при полном HP, до ~2,1 к концу
var agitation := 0.0 # 0..1: недавний урон по узлу, стекает медленно
var steps := 0 # сколько зовов уже начато (0..3), каждый — один раз
var call_left := 0.0 # >0 пока идёт предупреждение зова
var call_step := 0
var windup_left := 0.0 # >0 пока узел замахивается плевком
var hazards: Hazards
var _crossed := 0
var _call_gap := 0.0
var _bite_in := 0.0
var _bite_rng := RandomNumberGenerator.new()
var _marks := PackedVector2Array()
var _mark_age := PackedFloat32Array()
var _mark_life := PackedFloat32Array()


func _ready() -> void:
	_node_tex = PixelArt.tex("campaign_node")
	_damaged_tex = PixelArt.tex("campaign_node_damaged")
	_critical_tex = PixelArt.tex("campaign_node_critical")
	_ruined_tex = PixelArt.tex("campaign_node_ruined")
	_roots_tex = PixelArt.tex("campaign_node_roots")
	visible = false
	z_index = 5


func set_mission_profile(hp_mul: float, _shed_fraction: float) -> void:
	max_hp = float(CampaignCatalog.BALANCE["node_hp"]) * hp_mul


## Давление по доле HP и возбуждению: монотонно растёт с потерей HP.
static func pressure_for(fraction: float, excitement: float) -> float:
	return 1.0 + PRESSURE_LOSS * (1.0 - clampf(fraction, 0.0, 1.0)) + PRESSURE_AGITATION * clampf(excitement, 0.0, 1.0)


func hp_fraction() -> float:
	return hp / maxf(max_hp, 1.0)


func start(p: Vector2) -> void:
	if obstacles and _obstacle >= 0:
		obstacles.remove_body(_obstacle)
	global_position = p
	hp = max_hp
	_alive = true
	_collapse = -1.0
	pressure = 1.0
	agitation = 0.0
	steps = 0
	_crossed = 0
	call_left = 0.0
	call_step = 0
	windup_left = 0.0
	_call_gap = 0.0
	_bite_in = float(BITE_PERIOD[0])
	_bite_rng.seed = 20261020
	_marks.clear()
	_mark_age.clear()
	_mark_life.clear()
	visible = true
	if obstacles:
		_obstacle = obstacles.add_body(p, NODE_RADIUS)
	queue_redraw()


func body_radius() -> float:
	return NODE_RADIUS


func display_name() -> String:
	return "Узел заражения"


func take_damage(amount: float, _dir: Vector2, at: Vector2) -> bool:
	if not _alive or amount <= 0.0:
		return false
	hp = maxf(0.0, hp - amount)
	_flash = 0.1
	agitation = minf(1.0, agitation + amount / (max_hp * AGITATION_SCALE))
	while _crossed < THRESHOLDS.size() and hp_fraction() <= float(THRESHOLDS[_crossed]):
		_crossed += 1
	if effects:
		effects.blood_hit(at, _dir, false)
	if hp <= 0.0:
		_alive = false
		_collapse = 0.0 # Останки видимы, но больше не принимают урон.
		_calm()
		if obstacles and _obstacle >= 0:
			obstacles.remove_body(_obstacle)
			_obstacle = -1
		died.emit(global_position)
		return true
	return false


## Узел разрушен: давление и атаки снимаются целиком.
func _calm() -> void:
	pressure = 0.0
	agitation = 0.0
	call_left = 0.0
	windup_left = 0.0
	_marks.clear()
	_mark_age.clear()
	_mark_life.clear()


## Логика давления без отрисовки: каждый физический шаг (и тесты напрямую).
func tick(delta: float) -> void:
	if not _alive:
		return
	agitation = maxf(0.0, agitation - AGITATION_DECAY * delta)
	var target := pressure_for(hp_fraction(), agitation)
	pressure = move_toward(pressure, target, (RISE if target > pressure else FALL) * delta)
	_call_gap = maxf(0.0, _call_gap - delta)
	if call_left > 0.0:
		call_left = maxf(0.0, call_left - delta)
		if call_left == 0.0:
			_call_gap = CALL_GAP
			call_released.emit(call_step)
	elif steps < _crossed and _call_gap <= 0.0 and windup_left <= 0.0:
		steps += 1
		call_step = steps
		call_left = CALL_WARNING
		call_started.emit(steps)
	_tick_bite(delta)


func _tick_bite(delta: float) -> void:
	var i := 0
	while i < _marks.size():
		_mark_age[i] += delta
		if _mark_age[i] >= _mark_life[i]:
			_marks.remove_at(i)
			_mark_age.remove_at(i)
			_mark_life.remove_at(i)
		else:
			i += 1
	if steps < THRESHOLDS.size() or call_left > 0.0:
		return
	if windup_left > 0.0:
		windup_left = maxf(0.0, windup_left - delta)
		if windup_left == 0.0:
			_launch_bite()
		return
	_bite_in -= delta
	if _bite_in <= 0.0:
		_bite_in = float(BITE_PERIOD[1 if hp_fraction() < 0.1 else 0])
		if player and not player.is_dead and player.global_position.distance_to(global_position) <= BITE_RANGE:
			windup_left = BITE_WINDUP
			bite_started.emit()


## Три плевка: один в игрока, два рядом; метки лежат на земле, пока плевок в воздухе.
func _launch_bite() -> void:
	if not player or player.is_dead:
		return
	var at := player.global_position
	var turn := _bite_rng.randf() * TAU
	for k in BITE_COUNT:
		var spot := at if k == 0 else at + Vector2.from_angle(turn + PI * float(k - 1)) * 62.0
		if obstacles:
			spot = obstacles.free_point(spot, 8.0)
		_marks.append(spot)
		_mark_age.append(0.0)
		_mark_life.append(global_position.distance_to(spot) / Hazards.SPIT_SPEED)
		if hazards:
			hazards.spit(global_position + Vector2(0, -8), spot, BITE_DAMAGE)
	bite_launched.emit()


func hit_test(p: Vector2, r: float) -> bool:
	return _alive and p.distance_squared_to(global_position) <= pow(NODE_RADIUS + maxf(r, 0.0), 2.0)


func _physics_process(delta: float) -> void:
	if not _alive:
		if _collapse >= 0.0 and _collapse < 1.0:
			_collapse = minf(1.0, _collapse + delta * 1.8)
			queue_redraw()
		return
	_time += delta
	_flash = maxf(0.0, _flash - delta)
	tick(delta)
	queue_redraw()


func _draw() -> void:
	if not _alive:
		if _collapse >= 0.0:
			draw_texture_rect(_ruined_tex, NODE_RECT, false)
			if _collapse < 1.0:
				var height := lerpf(72.0, 19.0, _collapse)
				draw_texture_rect(_critical_tex, Rect2(-40, 20.0 - height, 80, height), false, Color(0.7, 0.45, 0.4, 1.0 - _collapse))
		return
	_draw_warnings()
	# Корни держатся за землю; дышит только мягкая масса, и тем чаще, чем выше давление.
	draw_texture_rect(_roots_tex, NODE_RECT, false)
	var heat := clampf(pressure - 1.0, 0.0, 1.1) / 1.1
	var pulse := sin(_time * (2.8 + 3.4 * heat)) * (0.012 + 0.016 * heat)
	var swell := 0.0
	if call_left > 0.0:
		swell = 0.06 * (1.0 - call_left / CALL_WARNING) # перед зовом масса надувается
	elif windup_left > 0.0:
		swell = 0.045 * (1.0 - windup_left / BITE_WINDUP)
	var fraction := hp / max_hp
	var tex := _critical_tex if fraction < 0.34 else (_damaged_tex if fraction < 0.68 else _node_tex)
	draw_set_transform(Vector2(0, -12), 0.0, Vector2(1.0 + pulse + swell, 1.0 - pulse + swell))
	var tint := Color.WHITE.lerp(Color(1.1, 0.78, 0.7), heat * 0.6 + (0.4 if call_left > 0.0 or windup_left > 0.0 else 0.0))
	draw_texture_rect(tex, Rect2(-40, -40, 80, 72), false, Color(1.08, 0.63, 0.52) if _flash > 0.0 else tint)
	draw_set_transform(Vector2.ZERO)
	if fraction < 0.68:
		# Несколько тяжёлых капель из разрывов, без новых частиц/декалей.
		for i in (5 if fraction < 0.34 else 3):
			var t := fmod(_time * 0.75 + float(i) * 0.31, 1.0)
			var x := -14.0 + float(i) * 5.3
			var at := Vector2(x + sin(float(i) * 3.0), 3.0 + t * 11.0)
			draw_line(at - Vector2(0, 2.1), at, Color("651d18"), 0.6)
			PixelArt.draw_dot(self, at, 0.65, Color("6a221b"))


## Предупреждения лежат на земле: кольца зова от узла и метки плевков у цели.
func _draw_warnings() -> void:
	if call_left > 0.0:
		var progress := 1.0 - call_left / CALL_WARNING
		for k in 2:
			var t := fposmod(progress * 1.6 - float(k) * 0.5, 1.0)
			if progress * 1.6 - float(k) * 0.5 < 0.0:
				continue
			draw_arc(Vector2(0, -6), lerpf(NODE_RADIUS + 6.0, 150.0, t), 0.0, TAU, 48, Color(WARN_COLOR, 0.75 * (1.0 - t)), 1.0)
	if windup_left > 0.0:
		var fill := 1.0 - windup_left / BITE_WINDUP
		draw_arc(Vector2(0, -6), NODE_RADIUS + 8.0, -PI * 0.5, -PI * 0.5 + TAU * fill, 32, Color(WARN_COLOR, 0.9), 1.5)
	for i in _marks.size():
		var local := _marks[i] - global_position
		var fill := clampf(_mark_age[i] / maxf(_mark_life[i], 0.001), 0.0, 1.0)
		draw_arc(local, 22.0, 0.0, TAU, 28, Color(WARN_COLOR, 0.8), 1.0)
		draw_arc(local, 11.0, -PI * 0.5, -PI * 0.5 + TAU * fill, 20, Color(WARN_COLOR, 0.95), 11.0)
