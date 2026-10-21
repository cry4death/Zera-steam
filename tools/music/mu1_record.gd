extends SceneTree
## Звуковой стенд: настоящий микс Music, без постановочного видео и изменения игры.
## --headless --audio-driver WASAPI --path . -s res://tools/music/mu1_record.gd -- --fresh-save

var music: Node
var record: AudioEffectRecord
var elapsed := 0.0
var segment := 0
var last_usec := 0
const NAMES := ["calm_alarm", "boss", "evac_lowhp"]


func _initialize() -> void:
	call_deferred("start")


func start() -> void:
	music = root.get_node("Music")
	music._enabled = true
	music.begin_combat(81073, true)
	record = AudioEffectRecord.new()
	record.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, record)
	record.set_recording_active(true)
	last_usec = Time.get_ticks_usec()


func _process(_delta: float) -> bool:
	if last_usec == 0:
		return false
	var usec := Time.get_ticks_usec()
	var dt := minf((usec - last_usec) / 1.0e6, 0.1)
	last_usec = usec
	elapsed += dt
	# Числа фаз SCOUT/PEAK: не загружаем классы боя до автозагрузки Meta.
	var phase := 0
	var alarm := segment == 0 and elapsed >= 10.0
	var boss := segment == 1 and elapsed >= 10.0
	var evac := segment == 2 and elapsed >= 10.0
	if segment == 1:
		phase = 2
	music.combat_step(dt, elapsed, phase, alarm, false, evac, boss, 0,
		0.2 if segment == 2 and elapsed >= 18.0 else 1.0)
	if elapsed >= 26.0:
		record.set_recording_active(false)
		var wav := record.get_recording()
		var path: String = "res://design/tasks/reports/mu1_" + NAMES[segment] + ".wav"
		var error := wav.save_to_wav(path)
		print("MUSIC_RECORD path=", path, " seconds=", wav.get_length(), " bytes=", wav.data.size(), " error=", error)
		var samples := wav.data
		for window: Vector2 in [Vector2(4, 8), Vector2(20, 24)]:
			var energy := 0.0
			var peak := 0.0
			var count := 0
			var channels := 2 if wav.stereo else 1
			for offset in range(int(window.x * wav.mix_rate * channels) * 2,
				mini(samples.size(), int(window.y * wav.mix_rate * channels) * 2), 2):
				var sample := samples.decode_s16(offset) / 32768.0
				energy += sample * sample
				peak = maxf(peak, absf(sample))
				count += 1
			print("MUSIC_RECORD_LEVEL name=", NAMES[segment], " window=", window,
				" rms_db=", snappedf(linear_to_db(sqrt(energy / maxi(count, 1))), 0.1),
				" peak_db=", snappedf(linear_to_db(peak), 0.1))
		segment += 1
		if segment >= NAMES.size():
			quit()
		else:
			elapsed = 0.0
			music.begin_combat(81073 + segment, true)
			record.set_recording_active(true)
	return false
