class_name Sfx
extends Node
## Фиксированные пулы голосов. Отсутствующая механика A2 — тишина.

const VOICES := 24
## W4: отдельный резерв голосов для выстрелов игрока и его боли — орда, gore и гильзы их не вытесняют.
const SHOT_VOICES := 20
const SHOT_SAME_MAX := 14 # одинаковых выстрелов подряд: темп 60/с × хвост 0.18 с не доходит до вытеснения
const SHOT_PITCH_JITTER := 0.015
const SHOT_GAIN_JITTER := 0.7
const DUCK_DB := 7.0 # мир уступает атаке; ползунок World остаётся базой
const OPTIONAL := ["weapons/rail/dry", "weapons/launcher/dry"] # механика этих стволов пока без A2
const DIRECTOR_CUES := {"front": "zombies/groan", "fast": "zombies/runner"}
const ACTIVITY_CUES := {"offer": "ui/click", "start": "ui/click", "powered": "ui/confirm", "success": "ui/confirm", "failure": "ui/deny"}
const ALIASES := {"zombies/mother_roar": "zombies/boss_roar", "zombies/meat_roar": "zombies/boss_roar", "gore/armor": "casings/mag_drop", "zombies/heart_roar": "zombies/boss_roar", "hive/flesh": "gore/splat", "ui/combo": "ui/confirm", "zombies/node_call": "zombies/boss_roar", "zombies/node_spit": "gore/splat"}
const REQUIRED := ["weapons/rifle/shot", "weapons/shotgun/shot", "weapons/rail/shot", "weapons/launcher/shot",
	"weapons/pistol/shot", "weapons/revolver/shot", "weapons/smg/shot", "weapons/sniper/shot",
	"ui/click", "ui/confirm", "ui/deny", "gore/hit", "player/hurt", "player/heartbeat", "ambience/horde"]
var played := 0
var dropped := 0
var played_by_id: Dictionary = {}
var _silent := false
var _bank: Dictionary = {}
var _missing: Dictionary = {}
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
var _pending_hit_id := -1
var _pending_damage := 0.0
var _pending_impulse := 0.0
var _pending_packet := 0.0
var _pending_frame := -1
var _impact_audio := false
var listener: Player
var _heart_gain := 0.0
var _ambience_started := false
var _world_db := -12.0
var _duck := 0.0
var _duck_hold := 0.0
var gun_lab: GunLabAudio


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 104729 # отдельный поток: звук не меняет случайность боя
	_silent = DisplayServer.get_name() == "headless" or OS.get_cmdline_user_args().has("--mute-sfx")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sim") or arg.ends_with("-test") and arg not in ["--weapons-test", "--audio-test"]:
			_silent = true
	# В визуальном тесте голоса работают для проверки пула, но наружу звук не идёт.
	if OS.get_cmdline_user_args().has("--weapons-test"):
		AudioServer.set_bus_mute(0, true)
	gun_lab = GunLabAudio.new()
	gun_lab.audible = not _silent or OS.get_cmdline_user_args().has("--gunlab-test") or OS.get_cmdline_user_args().has("--gunlab-render")
	add_child(gun_lab)
	_scan("res://sfx", "")
	_finish_scan()
	var horde := get_parent().get_node_or_null("World/Horde") as Horde
	if horde:
		horde.enemy_impact.connect(queue_impact)
		_impact_audio = true
	if _silent:
		return
	_refresh_world_db()
	Meta.settings_changed.connect(_refresh_world_db)
	for i in VOICES + SHOT_VOICES:
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
	# W4: при низком HP глохнет только мир; оружие и выстрелы остаются чёткими.
	var world_bus := AudioServer.get_bus_index(&"World")
	for effect in AudioServer.get_bus_effect_count(world_bus):
		var filter := AudioServer.get_bus_effect(world_bus, effect) as AudioEffectLowPassFilter
		if filter != null:
			_filters.append(filter)


## База громкости World без прижатия: берём из настроек, а не из шины, которую мы же и двигаем.
func _refresh_world_db() -> void:
	_world_db = linear_to_db(maxf(float(Meta.settings.get("world", 1.0)), 0.0001)) - 12.0


func _process(delta: float) -> void:
	if _silent:
		return
	if get_tree().paused:
		_duck = 0.0
		_duck_hold = 0.0
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"World"), _world_db)
		return
	# Короткое прижатие мира под выстрелом: быстро вниз, плавно назад.
	_duck_hold = maxf(_duck_hold - delta, 0.0)
	var duck_to := 1.0 if _duck_hold > 0.0 else 0.0
	_duck = lerpf(_duck, duck_to, 1.0 - exp(-delta * (70.0 if duck_to > _duck else 9.0)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"World"), _world_db - DUCK_DB * _duck)
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
			var force := clampf(_pending_damage / 42.0 + _pending_impulse / 500.0, 0.0, 1.0)
			var distance := listener.global_position.distance_to(_pending_hit)
			var proximity := 1.0 - clampf(distance / 600.0, 0.0, 1.0)
			play("gore/hit", _pending_hit, lerpf(-4.0, 3.0, force) + 4.0 * proximity * proximity, 0.025)
			_hit_times.append(now)
			_hit_window = now
		else:
			dropped += 1
		_pending_hit = Vector2.INF
		_pending_hit_id = -1
		_pending_damage = 0.0
		_pending_impulse = 0.0


func queue_hit(at: Vector2, _dir: Vector2, _variant: int) -> void:
	if _impact_audio:
		return
	queue_impact(at, _dir, _variant, 8.0, 10.0)


## Дробь одного тела складывает вес, весь кадр даёт один ближайший мокрый удар.
func queue_impact(at: Vector2, _dir: Vector2, _variant: int, damage: float, impulse: float, id := -1, explosive := false) -> void:
	if _silent or listener == null or at.distance_squared_to(listener.position) > 360000.0:
		return
	if explosive:
		return # у взрыва уже есть отдельные звук и смерть
	if _pending_hit != Vector2.INF and id >= 0 and id == _pending_hit_id:
		var frame := Engine.get_process_frames()
		_pending_packet = _pending_packet + damage if frame == _pending_frame else damage
		_pending_frame = frame
		_pending_damage = maxf(_pending_damage, _pending_packet)
		_pending_impulse = maxf(_pending_impulse, impulse)
		return
	if _pending_hit == Vector2.INF or at.distance_squared_to(listener.position) < _pending_hit.distance_squared_to(listener.position):
		if _pending_hit != Vector2.INF:
			dropped += 1
		_pending_hit = at
		_pending_hit_id = id
		_pending_damage = damage
		_pending_packet = damage
		_pending_frame = Engine.get_process_frames()
		_pending_impulse = impulse
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
	if not _silent:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"World"), _world_db)


func _scan(path: String, prefix: String) -> void:
	var entries := ResourceLoader.list_directory(path)
	entries.sort()
	for file in entries:
		if file == "gunlab/":
			continue # Исходники пульта не входят в общий банк событий.
		if file.ends_with("/"):
			var folder := file.trim_suffix("/")
			_scan(path.path_join(folder), prefix + folder + "/")
			continue
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
		var stream := ResourceLoader.load_threaded_get(e[1]) as AudioStream
		if stream != null:
			_bank[id].append(stream)
		else:
			push_warning("Sfx: не загружен ресурс " + str(e[1]))
	_scan_list.clear()
	# Пульс органа — одиночный удар из прежней петли низкого HP, без наложения вечных петель.
	_bank["hive/pulse"] = []
	for source: AudioStream in _bank.get("player/heartbeat", []):
		var pulse := source.duplicate() as AudioStreamWAV
		if pulse:
			pulse.loop_mode = AudioStreamWAV.LOOP_DISABLED
			_bank["hive/pulse"].append(pulse)
	for id: String in REQUIRED:
		if not has(id):
			_warn_missing(id)


func has(id: String) -> bool:
	if _lab_gun(id) != "":
		return true
	var source: String = ALIASES.get(id, id)
	return _bank.has(source) and not _bank[source].is_empty()


func _lab_gun(id: String) -> String:
	var parts := id.split("/")
	if parts.size() == 3 and parts[0] == "weapons" and parts[2] == "shot":
		var gun := GunLabAudio.canonical(parts[1])
		if GunLabAudio.GUNS.has(gun):
			return gun
	return ""


func _warn_missing(id: String) -> void:
	if not _missing.has(id):
		_missing[id] = true
		push_warning("Sfx: отсутствует обязательный sound ID: " + id)


func play(id: String, pos := Vector2.INF, volume_db := 0.0, pitch_jitter := 0.05, gun_pitch := 1.0) -> void:
	var gun := _lab_gun(id)
	if gun != "":
		if not _silent:
			gun_lab.play_shot(gun, volume_db, gun in ["smg","rifle"], false, gun_pitch)
			played += 1
			played_by_id[id] = int(played_by_id.get(id, 0)) + 1
			_duck_hold = 0.12
			_duck = 1.0
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"World"), _world_db - DUCK_DB)
		return
	if id.begins_with("weapons/") and id.ends_with("/tail"):
		var tail_gun := GunLabAudio.canonical(id.split("/")[1])
		# У автоматов отражение принадлежит концу очереди, как в W5.
		if not _silent and tail_gun in ["smg","rifle"]:
			gun_lab.play_shot(tail_gun,volume_db,false,true)
			played += 1
			played_by_id[id] = int(played_by_id.get(id,0))+1
		return
	if not has(id):
		if not OPTIONAL.has(id):
			_warn_missing(id)
		return
	if _silent:
		return
	var now := Time.get_ticks_msec() * 0.001
	var zombie := id.begins_with("zombies/")
	if zombie and active_voices(true) >= 6:
		if id not in ["zombies/boss_roar", "zombies/mother_roar", "zombies/meat_roar", "zombies/heart_roar"]:
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
	# Выстрелы игрока и его боль идут в резерв голосов и на отдельную шину.
	var priority := pos == Vector2.INF and (id.begins_with("weapons/") and (shot or id.ends_with("/tail")) or id == "player/hurt")
	# Выстрелы не прореживаем по интервалу: быстрые стволы и два одинаковых в кадре должны звучать все.
	var interval := 0.0 if shot else 0.06
	if now - float(_when.get(id, -100.0)) < interval or casing and now - _casing_at < 0.1:
		dropped += 1
		return
	var chosen := -1
	var oldest := 1.0e20
	var same := 0
	var same_oldest := -1
	var first := VOICES if priority else 0
	var last := VOICES + SHOT_VOICES if priority else VOICES
	for i in range(first, last):
		var busy := _flat[i].playing or _world[i].playing
		if busy and _ids[i] == id:
			same += 1
			if same_oldest < 0 or _started[i] < _started[same_oldest]:
				same_oldest = i
		var age := _started[i] if busy else -1.0e10
		if age < oldest:
			oldest = age
			chosen = i
	if same >= (SHOT_SAME_MAX if shot else 3):
		chosen = same_oldest
		dropped += 1
	_flat[chosen].stop()
	_world[chosen].stop()
	var variants: Array = _bank[ALIASES.get(id, id)]
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
	if id == "zombies/mother_roar":
		pitch *= 1.28
	elif id == "zombies/meat_roar":
		pitch *= 0.69
	elif id == "zombies/heart_roar":
		pitch *= 0.56
	elif id == "zombies/node_call":
		pitch *= 0.7
	elif id == "hive/pulse":
		pitch *= 0.75
	if id == "gore/hit":
		pitch *= lerpf(1.05, 0.78, clampf((volume_db + 4.0) / 7.0, 0.0, 1.0))
	if zombie and volume_db >= 2.0:
		pitch *= 0.83 # элитки: громче и ниже
	# Мокрая гильза звучит ниже, без изменения публичного API.
	if casing and volume_db < -5.0:
		pitch *= 0.82
	var gain := volume_db + _rng.randf_range(-1.5, 1.5)
	if shot and priority:
		# Огнестрел с ±5 % по высоте слышен как игрушка: ±1.5 % и ±0.7 dB.
		var jitter := minf(pitch_jitter, SHOT_PITCH_JITTER)
		pitch = _rng.randf_range(1.0 - jitter, 1.0 + jitter)
		gain = volume_db + _rng.randf_range(-SHOT_GAIN_JITTER, SHOT_GAIN_JITTER)
		_duck_hold = 0.12
		# Прижатие начинается в том же кадре, а не после уже прозвучавшей атаки.
		_duck = 1.0
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"World"), _world_db - DUCK_DB)
	if pos == Vector2.INF:
		var voice := _flat[chosen]
		if id.begins_with("ui/") or id.begins_with("player/"):
			voice.bus = &"UI"
		else:
			voice.bus = &"Shots" if priority else &"Weapons"
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
