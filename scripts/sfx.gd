class_name Sfx
extends Node
## Фиксированные пулы голосов. Отсутствующая механика A2 — тишина.

const VOICES := 24
var played := 0
var dropped := 0
var played_by_id: Dictionary = {}
var _silent := false
var _bank: Dictionary = {}
var _scan_list: Array = []
var _last: Dictionary = {}
var _when: Dictionary = {}
var _flat: Array[AudioStreamPlayer] = []
var _world: Array[AudioStreamPlayer2D] = []
var _ids: Array[String] = []
var _started := PackedFloat64Array()
var _casing_at := -1.0
var _rng := RandomNumberGenerator.new()
var _loops: Array[AudioStreamPlayer2D] = []
var _heart: AudioStreamPlayer
var _filters: Array[AudioEffectLowPassFilter] = []
var lowpass := 20500.0
var hits_s := 0
var _hit_window := -1.0
var _hit_times := PackedFloat64Array()
var _pending_hit := Vector2.INF
var listener: Player
var _heart_gain := 0.0
var _ambience_started := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_silent = DisplayServer.get_name() == "headless" or OS.get_cmdline_user_args().has("--mute-sfx")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sim") or arg.ends_with("-test") and arg not in ["--weapons-test", "--audio-test"]:
			_silent = true
	# В визуальном тесте голоса работают для проверки пула, но наружу звук не идёт.
	if OS.get_cmdline_user_args().has("--weapons-test"):
		AudioServer.set_bus_mute(0, true)
	_scan("res://sfx", "")
	_finish_scan()
	if _silent:
		return
	for i in VOICES:
		var a := AudioStreamPlayer.new()
		a.bus = &"Weapons"
		add_child(a)
		_flat.append(a)
		var w := AudioStreamPlayer2D.new()
		w.process_mode = Node.PROCESS_MODE_PAUSABLE
		w.bus = &"World"
		w.max_distance = 600.0
		add_child(w)
		_world.append(w)
		_ids.append("")
		_started.append(-100.0)
	for n in 2:
		var loop := AudioStreamPlayer2D.new()
		loop.bus = &"World"
		loop.process_mode = Node.PROCESS_MODE_PAUSABLE
		loop.max_distance = 100000.0
		loop.attenuation = 0.0
		loop.volume_db = -80.0
		add_child(loop)
		var bank: Array = _bank.get("ambience/horde", [])
		if bank.size() > n:
			loop.stream = bank[n]
			loop.play()
		_loops.append(loop)
	_heart = AudioStreamPlayer.new()
	_heart.bus = &"UI" # сердце остаётся ясным, когда мир приглушён
	_heart.process_mode = Node.PROCESS_MODE_PAUSABLE
	_heart.volume_db = -80.0
	add_child(_heart)
	if has("player/heartbeat"):
		_heart.stream = _bank["player/heartbeat"][0]
		_heart.play()
	for bus_name: String in ["World", "Weapons"]:
		var bus := AudioServer.get_bus_index(bus_name)
		for effect in AudioServer.get_bus_effect_count(bus):
			var filter := AudioServer.get_bus_effect(bus, effect) as AudioEffectLowPassFilter
			if filter != null:
				_filters.append(filter)


func _process(delta: float) -> void:
	if _silent or get_tree().paused:
		return
	var danger := 0.0
	if is_instance_valid(listener) and not listener.is_dead:
		danger = clampf(1.0 - listener.hp / listener.max_hp / 0.3, 0.0, 1.0)
	lowpass = lerpf(lowpass, lerpf(20500.0, 1100.0, sqrt(danger)), 1.0 - exp(-delta * 4.0))
	for filter in _filters:
		filter.cutoff_hz = lowpass
	_heart_gain = lerpf(_heart_gain, danger * 0.8, 1.0 - exp(-delta * 4.0))
	_heart.volume_db = linear_to_db(maxf(_heart_gain, 0.0001))
	var now := Time.get_ticks_msec() * 0.001
	# Сначала собираем события кадра, затем озвучиваем ближайшее. Не более 12 за скользящую секунду.
	while not _hit_times.is_empty() and now - _hit_times[0] >= 1.0:
		_hit_times.remove_at(0)
	hits_s = _hit_times.size()
	if _pending_hit != Vector2.INF and now - _hit_window >= 1.0 / 12.0:
		if hits_s < 12:
			play("gore/hit", _pending_hit, -2.0)
			_hit_times.append(now)
			_hit_window = now
		else:
			dropped += 1
		_pending_hit = Vector2.INF


func queue_hit(at: Vector2, _dir: Vector2, _variant: int) -> void:
	if _silent or listener == null or at.distance_squared_to(listener.position) > 360000.0:
		return
	if _pending_hit == Vector2.INF or at.distance_squared_to(listener.position) < _pending_hit.distance_squared_to(listener.position):
		if _pending_hit != Vector2.INF:
			dropped += 1
		_pending_hit = at
	else:
		dropped += 1


func ambience(at: Vector2, density: float, mix: float, delta: float) -> void:
	for n in _loops.size():
		var gain := density * (sqrt(1.0 - mix) if n == 0 else sqrt(mix)) * 0.65
		var voice := _loops[n]
		voice.global_position = voice.global_position.lerp(at, 1.0 - exp(-delta * 3.0)) if _ambience_started else at
		voice.volume_db = linear_to_db(lerpf(db_to_linear(voice.volume_db), gain, 1.0 - exp(-delta * 2.0)) + 0.00001)
	_ambience_started = true


func active_voices(horde_only := false) -> int:
	var count := 0
	for i in _ids.size():
		if (_flat[i].playing or _world[i].playing) and (not horde_only or _ids[i].begins_with("zombies/")):
			count += 1
	return count


func _exit_tree() -> void:
	for filter in _filters:
		filter.cutoff_hz = 20500.0


func _scan(path: String, prefix: String) -> void:
	for folder in DirAccess.get_directories_at(path):
		_scan(path.path_join(folder), prefix + folder + "/")
	for file in DirAccess.get_files_at(path):
		if not file.ends_with(".wav"):
			continue
		var stem := file.get_basename()
		var cut := stem.rfind("_")
		if cut < 0 or not stem.substr(cut + 1).is_valid_int():
			continue
		var id := prefix + stem.left(cut)
		var full := path.path_join(file)
		# P1: 290 файлов (20 МБ) грузим пачкой в потоках — раньше по одному, ~0.3–0.7 с заморозки на старте
		ResourceLoader.load_threaded_request(full)
		_scan_list.append([id, full])


## Забирает загруженное в прежнем порядке файлов (варианты одного звука — по номеру).
func _finish_scan() -> void:
	for e: Array in _scan_list:
		# ждём без блокирующего get: он прогоняет очередь сообщений и рисует недособранные узлы
		while ResourceLoader.load_threaded_get_status(e[1]) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			OS.delay_usec(300)
		var id: String = e[0]
		if not _bank.has(id):
			_bank[id] = []
		_bank[id].append(ResourceLoader.load_threaded_get(e[1]))
	_scan_list.clear()


func has(id: String) -> bool:
	return _bank.has(id)


func play(id: String, pos := Vector2.INF, volume_db := 0.0, pitch_jitter := 0.05) -> void:
	if _silent or not has(id):
		return
	var now := Time.get_ticks_msec() * 0.001
	var zombie := id.begins_with("zombies/")
	if zombie and active_voices(true) >= 6:
		if id != "zombies/boss_roar":
			dropped += 1
			return
		# Рёв босса вытесняет самый старый обычный голос, сохраняя общий предел шесть.
		var oldest_zombie := -1
		for i in _ids.size():
			if _ids[i].begins_with("zombies/") and (_flat[i].playing or _world[i].playing):
				if oldest_zombie < 0 or _started[i] < _started[oldest_zombie]:
					oldest_zombie = i
		if oldest_zombie >= 0:
			_flat[oldest_zombie].stop()
			_world[oldest_zombie].stop()
			dropped += 1
	var casing := id.begins_with("casings/")
	var shot := id.ends_with("/shot")
	var interval := 0.035 if shot else 0.06
	if now - float(_when.get(id, -100.0)) < interval or casing and now - _casing_at < 0.1:
		dropped += 1
		return
	var chosen := -1
	var oldest := 1.0e20
	var same := 0
	var same_oldest := -1
	for i in VOICES:
		var busy := _flat[i].playing or _world[i].playing
		if busy and _ids[i] == id:
			same += 1
			if same_oldest < 0 or _started[i] < _started[same_oldest]:
				same_oldest = i
		var age := _started[i] if busy else -1.0e10
		if age < oldest:
			oldest = age
			chosen = i
	if same >= (6 if shot else 3):
		chosen = same_oldest
		dropped += 1
	_flat[chosen].stop()
	_world[chosen].stop()
	var variants: Array = _bank[id]
	var n := _rng.randi_range(0, variants.size() - 1)
	if variants.size() > 1 and n == int(_last.get(id, -1)):
		n = (n + _rng.randi_range(1, variants.size() - 1)) % variants.size()
	_last[id] = n
	_when[id] = now
	if casing:
		_casing_at = now
	_ids[chosen] = id
	_started[chosen] = now
	var pitch := _rng.randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	if zombie and volume_db >= 2.0:
		pitch *= 0.83 # элитки: громче и ниже
	# Мокрая гильза звучит ниже, без изменения публичного API.
	if casing and volume_db < -5.0:
		pitch *= 0.82
	var gain := volume_db + _rng.randf_range(-1.5, 1.5)
	if pos == Vector2.INF:
		var voice := _flat[chosen]
		voice.bus = &"UI" if id.begins_with("ui/") or id.begins_with("player/") else &"Weapons"
		voice.process_mode = Node.PROCESS_MODE_ALWAYS if id.begins_with("ui/") else Node.PROCESS_MODE_PAUSABLE
		voice.stream = variants[n]
		voice.volume_db = gain
		voice.pitch_scale = pitch
		voice.play()
	else:
		var voice := _world[chosen]
		voice.global_position = pos
		voice.stream = variants[n]
		voice.volume_db = gain
		voice.pitch_scale = pitch
		voice.play()
	played += 1
	played_by_id[id] = int(played_by_id.get(id, 0)) + 1
