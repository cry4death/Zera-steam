class_name GunLabAudio
extends Node
## Четыре слоя, фиксированный пул и кэш обрезки. Смешивание и эффекты — во время игры.

const GUNS := ["pistol", "revolver", "smg", "rifle", "shotgun", "sniper", "rail", "launcher", "lmg", "minigun", "flamer", "saw", "crossbow", "auto_shotgun", "dmr", "tesla"]
const NAMES := ["Пистолет", "Револьвер", "ППШ", "АК", "Дробовик", "Мосин", "Рельса", "Гранатомёт", "Пулемёт", "Миниган", "Огнемёт", "Пила", "Арбалет", "Автодробовик", "СВД", "Разрядник"]
const ALIASES := {"guard":"pistol", "cowboy":"revolver", "osa":"smg", "m4":"rifle", "shkval":"shotgun", "winchester":"sniper", "spear":"rail", "hive":"launcher"}
const LIMITS := {"volume":[-24.0,12.0], "low_cut":[20.0,1200.0], "high_cut":[1500.0,20500.0], "bass":[-12.0,12.0], "mid":[-12.0,12.0], "drive":[0.0,1.0], "attack":[0.0,1.0], "room":[0.0,1.0], "wet":[0.0,.7], "shake":[0.0,2.0], "recoil":[0.0,2.0], "flash":[0.0,2.0]}
const LAYER_LIMITS := {"gain":[-48.0,12.0], "pitch":[.35,2.5], "start":[0.0,1.45], "length":[.01,1.5], "fade":[.002,.6], "delay":[0.0,.5], "pitch_random":[0.0,.15], "gain_random":[0.0,6.0]}
const PROJECT_PATH := "res://sfx/gun_tuning.json"
const USER_PATH := "user://gun_tuning.json"
const POOL := 160 # 20 выстрелов/с × 4 слоя × до 1,5 с + задержка.
var catalog: Dictionary
var defaults: Dictionary
var tuning: Dictionary
var saved: Dictionary
var compare := false
var audible := true
var played := 0
var dropped := 0
var layer_plays := PackedInt32Array([0,0,0,0])
var _voices: Array[AudioStreamPlayer] = []
var _pending: Array[Dictionary] = []
var _cache: Dictionary = {}
var _sources: Dictionary = {}
var _effects: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _buses: Array[StringName] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rng.seed = 104729
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://sfx/gunlab/library.json"))
	catalog = data.catalog
	defaults = data.guns
	tuning = defaults.duplicate(true)
	var path := PROJECT_PATH if not OS.has_feature("standalone") or OS.has_feature("editor") else USER_PATH
	if not FileAccess.file_exists(path):
		path = PROJECT_PATH
	if FileAccess.file_exists(path):
		tuning = decode(FileAccess.get_file_as_string(path))
	saved = tuning.duplicate(true)
	if not audible:
		return
	for gun: String in GUNS:
		_make_bus(gun)
		apply(gun)
	for i in POOL:
		var voice := AudioStreamPlayer.new()
		voice.max_polyphony = 1
		add_child(voice)
		_voices.append(voice)
		_pending.append({})
	for gun: String in GUNS:
		prepare(gun)

static func canonical(gun: String) -> String:
	return str(ALIASES.get(gun, gun))

func values(gun: String) -> Dictionary:
	return (saved if compare else tuning)[canonical(gun)]

func decode(json: String) -> Dictionary:
	var result := defaults.duplicate(true)
	var parser := JSON.new()
	if parser.parse(json) != OK:
		return result
	var data: Variant = parser.data
	if not data is Dictionary or data.get("version") != 1 or not data.get("guns") is Dictionary:
		return result
	for gun: String in GUNS:
		var incoming: Variant = data.guns.get(gun)
		if not incoming is Dictionary:
			continue
		for key: String in LIMITS:
			result[gun][key] = _number(incoming.get(key), result[gun][key], LIMITS[key])
		var layers: Variant = incoming.get("layers")
		if not layers is Array or layers.size() != 4:
			continue
		for i in 4:
			if not layers[i] is Dictionary:
				continue
			var source: Variant = layers[i].get("source")
			if source is String and (source == "" or _known_source(source)):
				result[gun].layers[i].source = source
			for key: String in LAYER_LIMITS:
				result[gun].layers[i][key] = _number(layers[i].get(key), result[gun].layers[i][key], LAYER_LIMITS[key])
	return result

func _known_source(source: String) -> bool:
	for items: Array in catalog.values():
		if items.has(source):
			return true
	return false

func _number(value: Variant, fallback: float, bounds: Array) -> float:
	if (value is int or value is float) and is_finite(float(value)):
		return clampf(float(value), bounds[0], bounds[1])
	return fallback

func serialize() -> String:
	return JSON.stringify({"version":1,"guns":tuning}, "\t") + "\n"

func _write(path: String) -> Error:
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(serialize())
	file.close()
	return DirAccess.rename_absolute(temp, path)

func save_tuning() -> String:
	# Проект — источник для коммита; в сборке доступна пользовательская копия.
	var project_error := ERR_UNAVAILABLE if OS.has_feature("standalone") and not OS.has_feature("editor") else _write(PROJECT_PATH)
	var user_error := _write(USER_PATH)
	if project_error == OK or user_error == OK:
		saved = tuning.duplicate(true)
		compare = false
		for gun: String in GUNS:
			apply(gun)
	if project_error == OK:
		return "Сохранено в проект" + (" и в профиль" if user_error == OK else "; копия в профиль недоступна")
	if user_error == OK:
		return "Сохранено в профиль; файл проекта недоступен"
	return "Не удалось сохранить: проект и профиль недоступны"

func _make_bus(gun: String) -> void:
	var name := StringName("GunLab_" + gun)
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, name)
	AudioServer.set_bus_send(index, &"Shots")
	_buses.append(name)
	var hp := AudioEffectHighPassFilter.new()
	var lp := AudioEffectLowPassFilter.new()
	# Низкая полка и широкая середина эквалайзера.
	var shelf := AudioEffectLowShelfFilter.new()
	shelf.cutoff_hz = 180.0
	var eq10 := AudioEffectEQ10.new()
	var drive := AudioEffectDistortion.new()
	drive.mode = AudioEffectDistortion.MODE_OVERDRIVE
	var compressor := AudioEffectCompressor.new()
	for effect: AudioEffect in [hp,lp,shelf,eq10,drive,compressor]:
		AudioServer.add_bus_effect(index,effect)
	AudioServer.add_bus()
	var tail := AudioServer.bus_count - 1
	var tail_name := StringName("GunLabTail_" + gun)
	AudioServer.set_bus_name(tail,tail_name)
	AudioServer.set_bus_send(tail,name)
	_buses.append(tail_name)
	var reverb := AudioEffectReverb.new()
	AudioServer.add_bus_effect(tail,reverb)
	_effects[gun] = [hp,lp,shelf,eq10,drive,compressor,reverb]

func apply(gun: String) -> void:
	if not audible:
		return
	var p := values(gun)
	var fx: Array = _effects[gun]
	fx[0].cutoff_hz = p.low_cut
	fx[1].cutoff_hz = p.high_cut
	fx[2].gain = db_to_linear(p.bass)
	for band in 10:
		fx[3].set_band_gain_db(band, float(p.mid) * ([0.0,0.0,0.0,.15,.6,1.0,.6,.15,0.0,0.0][band]))
	fx[4].drive = p.drive
	fx[4].keep_hf_hz = 16000.0
	fx[4].post_gain = -float(p.drive) * 5.0
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("GunLab_"+gun),4,float(p.drive)>.001)
	fx[5].threshold = lerpf(0.0,-18.0,p.attack)
	fx[5].ratio = lerpf(1.0,4.0,p.attack)
	fx[5].attack_us = lerpf(20000.0,3000.0,p.attack)
	fx[5].release_ms = 90.0
	fx[6].room_size = p.room
	fx[6].wet = p.wet
	fx[6].dry = 1.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("GunLab_"+gun),p.volume)

func _key(layer: Dictionary) -> String:
	return "%s:%.4f:%.4f:%.4f" % [layer.source,layer.start,layer.length,layer.fade]

func prepare(gun: String) -> void:
	for layer: Dictionary in values(gun).layers:
		if layer.source == "":
			continue
		var key := _key(layer)
		if _cache.has(key):
			continue
		if not _sources.has(layer.source):
			_sources[layer.source] = load("res://sfx/gunlab/" + str(layer.source)) as AudioStreamWAV
		var source: AudioStreamWAV = _sources[layer.source]
		if source == null or source.format != AudioStreamWAV.FORMAT_16_BITS:
			push_warning("GunLab: нужен импорт PCM16: " + str(layer.source))
			continue
		var raw := source.data
		var begin := mini(int(float(layer.start)*44100),raw.size()/2-1)
		var count := mini(int(float(layer.length)*44100),raw.size()/2-begin)
		var cut := raw.slice(begin*2,(begin+count)*2)
		var fade := mini(count, int(float(layer.fade)*44100))
		for j in count:
			var gain := minf(1.0,float(count-j)/maxi(1,fade)) * minf(1.0,float(j)/44.0)
			if gain < 1.0:
				cut.encode_s16(j*2,int(cut.decode_s16(j*2)*gain))
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 44100
		stream.data = cut
		_cache[key] = stream
	# Голоса держат свои ссылки; старые положения ползунков не раздувают кэш.
	if _cache.size() > 96:
		_cache.clear()
		prepare(gun)

func play_shot(gun: String, gain := 0.0, defer_tail := false, only_tail := false, pitch_mul := 1.0) -> bool:
	gun = canonical(gun)
	if not GUNS.has(gun):
		return false
	if not audible:
		return true
	var p := values(gun)
	for layer_index in 4:
		if (only_tail and layer_index != 3) or (defer_tail and layer_index == 3):
			continue
		var layer: Dictionary = p.layers[layer_index]
		if layer.source == "":
			continue
		var chosen := -1
		for i in _voices.size():
			if _pending[i].is_empty() and not _voices[i].playing:
				chosen = i
				break
		if chosen < 0:
			dropped += 1
			continue
		var key := _key(layer)
		if not _cache.has(key):
			prepare(gun)
		if not _cache.has(key):
			continue
		var v := _voices[chosen]
		v.stream = _cache[key]
		v.bus = StringName(("GunLabTail_" if layer_index == 3 else "GunLab_") + gun)
		v.pitch_scale = float(layer.pitch)*pitch_mul*(1.0+_rng.randf_range(-layer.pitch_random,layer.pitch_random))
		v.volume_db = float(layer.gain)+gain+_rng.randf_range(-layer.gain_random,layer.gain_random)
		_pending[chosen] = {"delay":float(layer.delay),"layer":layer_index}
		if float(layer.delay) <= 0.0:
			_start(chosen)
	if not only_tail:
		played += 1
	return true

func _start(i: int) -> void:
	layer_plays[int(_pending[i].layer)] += 1
	_voices[i].play()
	_pending[i] = {}

func _process(delta: float) -> void:
	for i in _pending.size():
		if not _pending[i].is_empty():
			_pending[i].delay -= delta
			if _pending[i].delay <= 0.0:
				_start(i)

func preview(source: String) -> void:
	if source == "" or not audible:
		return
	for i in _voices.size():
		if not _voices[i].playing and _pending[i].is_empty():
			_voices[i].stream = load("res://sfx/gunlab/"+source)
			_voices[i].bus = &"Shots"
			_voices[i].pitch_scale = 1.0
			_voices[i].volume_db = -6.0
			_voices[i].play()
			return

func _exit_tree() -> void:
	for voice in _voices:
		voice.stop()
	for name in _buses.duplicate():
		var index := AudioServer.get_bus_index(name)
		if index >= 0:
			AudioServer.remove_bus(index)
