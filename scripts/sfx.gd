class_name Sfx
extends Node
## Фиксированные пулы голосов. Отсутствующая механика A2 — тишина.

const VOICES := 24
var played := 0
var dropped := 0
var played_by_id: Dictionary = {}
var _silent := false
var _bank: Dictionary = {}
var _last: Dictionary = {}
var _when: Dictionary = {}
var _flat: Array[AudioStreamPlayer] = []
var _world: Array[AudioStreamPlayer2D] = []
var _ids: Array[String] = []
var _started := PackedFloat64Array()
var _casing_at := -1.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_silent = DisplayServer.get_name() == "headless" or OS.get_cmdline_user_args().has("--mute-sfx")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sim") or arg.ends_with("-test") and arg != "--weapons-test":
			_silent = true
	# В визуальном тесте голоса работают для проверки пула, но наружу звук не идёт.
	if OS.get_cmdline_user_args().has("--weapons-test"):
		AudioServer.set_bus_mute(0, true)
	_scan("res://sfx", "")
	if _silent:
		return
	for i in VOICES:
		var a := AudioStreamPlayer.new()
		a.bus = &"Weapons"
		add_child(a)
		_flat.append(a)
		var w := AudioStreamPlayer2D.new()
		w.bus = &"World"
		w.max_distance = 600.0
		add_child(w)
		_world.append(w)
		_ids.append("")
		_started.append(-100.0)


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
		if not _bank.has(id):
			_bank[id] = []
		_bank[id].append(load(path.path_join(file)))


func has(id: String) -> bool:
	return _bank.has(id)


func play(id: String, pos := Vector2.INF, volume_db := 0.0, pitch_jitter := 0.05) -> void:
	if _silent or not has(id):
		return
	var now := Time.get_ticks_msec() * 0.001
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
	# Мокрая гильза звучит ниже, без изменения публичного API.
	if casing and volume_db < -5.0:
		pitch *= 0.82
	var gain := volume_db + _rng.randf_range(-1.5, 1.5)
	if pos == Vector2.INF:
		var voice := _flat[chosen]
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
