extends Node
## Музыка автора: фазы боя, фильтр и кроссфейд. Автозагрузка «Music».
## База и глобус продолжаются с прежнего места; пауза приглушает, но не обрывает трек.

enum State { CALM, BUILD, PEAK, DECAY, EVAC, BOSS }
const STATES := ["calm", "build", "peak", "decay", "evac", "boss"]
const DIR := "res://music/"
const BASE := "protocol_zero"
const GLOBE := "orbit_of_extinction"
const BOSS := "descent_into_madness_a"
const EVAC := "sirenes_des_cendres"
const FADE := 2.5
const OVERLAP := 3.0
const MIN_STATE := 8.0 ## с игрового времени для обычной смены интенсивности
const MIN_TRACK := 75.0 ## запас звучания после точки входа до перекрытия
const LONG_QUIET := 40.0
const CONFIRM := 2.0 ## краткий всплеск плотности не меняет состояние
const RESULTS_DB := -9.0
const DUCK_DB := -8.0
const STATE_DB := [-7.0, -3.0, -1.0, -4.0, -2.0, -1.0]
const CUTOFF := [3200.0, 11000.0, 20500.0, 6500.0, 20500.0, 20500.0]

var state := State.CALM
var _players: Array[AudioStreamPlayer] = []
var _gain := [0.0, 0.0]
var _active := 0
var _context := &""
var _bags: Dictionary = {}
var _drawn := ""
var _resume: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _map: Dictionary = {}
var _track := ""
var _position := 0.0
var _entry := 0.0
var _level_db := 0.0
var _cutoff := 20500.0
var _filter: AudioEffectLowPassFilter
var _duck := false
var _low_hp := false
var _last_usec := 0
var _enabled := true
var _age := 0.0
var _candidate := State.CALM
var _candidate_age := 0.0
var _dense := false
var _trace := false
var _trace_at := 0.0
var _streams: Dictionary = {}
var _track_age := 0.0
var _track_serial := 0
var _track_reason := ""
var _quiet_age := 0.0
var _quiet_peak := false
var _alarm := false
var _evac := false
var _boss := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_enabled = DisplayServer.get_name() != "headless"
	_load_map()
	_rng.seed = 0x4d5531
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = &"Music"
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	var bus := AudioServer.get_bus_index(&"Music")
	if bus >= 0 and AudioServer.get_bus_effect_count(bus) > 0:
		_filter = AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter
	_last_usec = Time.get_ticks_usec()
	# OGG остаются сжатыми; загрузка при старте сцены исключает чтение диска на пике.
	if _enabled:
		for id: String in _map:
			_streams[id] = load(DIR + id + ".ogg")


func _load_map() -> void:
	if _map.is_empty():
		_map = JSON.parse_string(FileAccess.get_file_as_string(DIR + "music_map.json"))


func begin_combat(run_seed: int, trace := false) -> void:
	_load_map()
	_rng.seed = run_seed ^ 0x4d5531
	_bags.clear()
	_drawn = ""
	_context = &"combat"
	_duck = false
	_low_hp = false
	_dense = false
	state = State.CALM
	_candidate = state
	_candidate_age = 0.0
	_age = 0.0
	_trace = trace
	_trace_at = 0.0
	_track_serial = 0
	_quiet_age = 0.0
	_quiet_peak = false
	_alarm = false
	_evac = false
	_boss = false
	_start(_pick(), true, "begin")


## Только снимок боевых сигналов; RNG орды и оружия здесь не используется.
func combat_step(dt: float, now: float, phase: int, alarm: bool, activity: bool,
	evac: bool, boss: bool, nearby: int, hp: float) -> void:
	if _context != &"combat":
		return
	_age += dt
	_candidate_age += dt
	if not _enabled:
		_position += dt
		_track_age += dt
	var serial := _track_serial
	_low_hp = hp < (0.4 if _low_hp else 0.3)
	_dense = nearby >= (10 if _dense else 16)
	var wanted := State.CALM
	if boss:
		wanted = State.BOSS
	elif evac:
		wanted = State.EVAC
	elif alarm or _dense or phase == HordeDirector.Phase.PEAK:
		wanted = State.PEAK
	elif activity or phase == HordeDirector.Phase.BUILD:
		wanted = State.BUILD
	elif phase == HordeDirector.Phase.DECAY:
		wanted = State.DECAY
	if wanted == State.CALM:
		_quiet_age += dt
		if _quiet_age >= LONG_QUIET:
			_quiet_peak = true
	else:
		_quiet_age = 0.0
	if wanted != _candidate:
		_candidate = wanted
		_candidate_age = 0.0
	var urgent := boss or evac or alarm
	var changed := wanted != state and (urgent or (_age >= MIN_STATE and _candidate_age >= CONFIRM))
	if changed:
		state = wanted
		_age = 0.0
	# Фазы меняют только микс. События запускают трек один раз, по фронту сигнала.
	var reason := ""
	if boss and not _boss:
		reason = "boss"
	elif evac and not _evac and not boss:
		reason = "evac"
	elif alarm and not _alarm and not boss and not evac:
		reason = "alarm"
	elif changed and state == State.PEAK and _quiet_peak:
		reason = "long_quiet_peak"
	_alarm = alarm
	_evac = evac
	_boss = boss
	if not reason.is_empty():
		_start(_pick(), true, reason)
	if state in [State.PEAK, State.EVAC, State.BOSS]:
		_quiet_peak = false
	if not _enabled:
		if _position >= float(_map[_track]["length"]) - OVERLAP:
			_start(_pick(), true, "ended")
	if _trace and (changed or serial != _track_serial or now >= _trace_at):
		_trace_at = now + 1.0
		print("MUSIC ", JSON.stringify({"time": snappedf(now, 0.01), "phase": HordeDirector.PHASES[phase],
			"alarm": alarm, "activity": activity, "evac": evac, "boss": boss, "nearby": nearby,
			"state": STATES[state], "track": _track, "entry": _entry, "age": snappedf(_age, 0.01),
			"track_age": snappedf(_track_age, 0.01), "track_serial": _track_serial,
			"track_reason": _track_reason, "track_changed": serial != _track_serial,
			"low_hp": _low_hp, "db": target_db(), "cutoff": CUTOFF[state], "changed": changed}))


## База, глобус, итоги; combat/boss оставлены для прежних вызовов сцен.
func play(context: StringName) -> void:
	if context == _context:
		return
	if context == &"combat":
		begin_combat(0)
		return
	_context = context
	_duck = false
	_low_hp = false
	if context == &"boss":
		state = State.BOSS
	if context != &"results":
		_start(_pick())


func duck(on: bool) -> void:
	_duck = on


func current() -> String:
	return _track


func target_db() -> float:
	var level := RESULTS_DB if _context == &"results" else (float(STATE_DB[state]) if _context in [&"combat", &"boss"] else 0.0)
	return level + (-5.0 if _low_hp else 0.0) + (DUCK_DB if _duck else 0.0)


func _pick() -> String:
	match _context:
		&"base": return BASE
		&"globe": return GLOBE
		&"boss": return BOSS
	if state == State.BOSS:
		return BOSS
	if state == State.EVAC:
		return EVAC
	var group := "build" if state in [State.BUILD, State.DECAY] else ("peak" if state == State.PEAK else "calm")
	var bag: Array = _bags.get(group, [])
	if bag.is_empty():
		for id: String in _map:
			if _map[id]["group"] == group:
				bag.append(id)
		# Собственный Fisher–Yates: музыка не меняет случайность боя.
		for i in range(bag.size() - 1, 0, -1):
			var j := _rng.randi_range(0, i)
			var swap: String = bag[i]
			bag[i] = bag[j]
			bag[j] = swap
		if bag.size() > 1 and bag[-1] == _drawn:
			bag.reverse()
	_drawn = str(bag.pop_back())
	_bags[group] = bag
	return _drawn


func _start(id: String, restart := false, reason := "context") -> void:
	if _track == id and not restart:
		return
	var from := 0.0
	if _context in [&"combat", &"boss"]:
		# Следующая песня входит с основной части; её интенсивность задаёт микс.
		var strong := reason == "ended" or state in [State.PEAK, State.EVAC, State.BOSS]
		from = float(_map[id]["strong_entry" if strong else "quiet_entry"])
		# Поздний сильный вход не должен оставлять лишь короткий хвост песни.
		from = minf(from, maxf(0.0, float(_map[id]["length"]) - OVERLAP - MIN_TRACK))
	elif not restart:
		from = float(_resume.get(id, 0.0))
	_track = id
	_position = from
	_entry = from
	_track_age = 0.0
	_track_serial += 1
	_track_reason = reason
	if not _enabled:
		return
	var cur := _players[_active]
	var cur_id := str(cur.get_meta("id", ""))
	if cur.playing and cur_id in [BASE, GLOBE]:
		_resume[cur_id] = 0.0 if restart else cur.get_playback_position()
	_active = 1 - _active
	var p := _players[_active]
	p.stream = _streams.get(id) as AudioStream
	if p.stream == null:
		p.stream = load(DIR + id + ".ogg")
	p.set_meta("id", id)
	_gain[_active] = 0.0
	p.volume_db = -80.0
	p.play(from)


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var dt := minf((now - _last_usec) / 1.0e6, 0.25)
	_last_usec = now
	if not _enabled or _context.is_empty():
		return
	_track_age += dt
	_level_db = move_toward(_level_db, target_db(), dt * 4.0)
	var cutoff := float(CUTOFF[state]) if _context == &"combat" else 20500.0
	_cutoff = lerpf(_cutoff, cutoff, 1.0 - exp(-dt * 1.5))
	if _filter != null:
		_filter.cutoff_hz = _cutoff
	for i in 2:
		var p := _players[i]
		_gain[i] = move_toward(_gain[i], 1.0 if i == _active else 0.0, dt / FADE)
		if not p.playing:
			continue
		if _gain[i] <= 0.0 and i != _active:
			p.stop()
			continue
		p.volume_db = linear_to_db(maxf(_gain[i], 0.0001)) + _level_db
	var a := _players[_active]
	if a.stream == null:
		return
	_position = a.get_playback_position()
	if not a.playing or a.stream.get_length() - _position < OVERLAP:
		_start(_pick(), true, "ended")
