class_name GunLabTest
extends RefCounted
## Проверки слышимого выхода, сохранения и фиксированного пула.

static var checks := 0
static var failed := 0

static func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		failed += 1
		print("GUNLAB FAIL " + label)

static func run(game: Node) -> void:
	var audio: GunLabAudio = game.sfx.gun_lab
	game.spawner.enabled = false
	game.weapons.set_physics_process(false)
	if game.gun_lab_range:
		game.gun_lab_controller.set_physics_process(false)
	var original := audio.tuning.duplicate(true)
	for gun: String in GunLabAudio.GUNS:
		var before := audio.layer_plays.duplicate()
		audio.play_shot(gun)
		await game.get_tree().create_timer(.65).timeout
		for i in 4:
			check(gun+" layer "+str(i),audio.layer_plays[i] == before[i]+1)
	check("all sources loaded",audio._sources.size() >= 32)
	for source: AudioStreamWAV in audio._sources.values():
		check("PCM16 mono 44100",source.format == AudioStreamWAV.FORMAT_16_BITS and source.mix_rate == 44100 and not source.stereo)
	check("corrupt tuning fallback",audio.decode("{") == audio.defaults)
	check("unknown version fallback",audio.decode('{"version":99,"guns":{}}') == audio.defaults)
	var panel: GunLabPanel = game.gun_lab_controller.panel
	var was_visible := panel.root.visible
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_F9
	game._unhandled_input(key)
	check("F9 open",panel.root.visible != was_visible)
	game._unhandled_input(key)
	check("F9 close",panel.root.visible == was_visible)
	check("range invulnerability",not game.gun_lab_range or game.player.god_mode)
	var record := AudioEffectRecord.new()
	AudioServer.add_bus_effect(0,record)
	await game.get_tree().create_timer(1.6).timeout
	var first := await _record(game,audio,record,0.0)
	var second := await _record(game,audio,record,-18.0)
	var first_rms := _rms(first)
	var second_rms := _rms(second)
	check("output gain responds",first_rms > .00001 and second_rms < first_rms*.25)
	print("GUNLAB output rms_before=%.6f rms_gain_minus18=%.6f" % [first_rms,second_rms])
	audio.tuning.shotgun.high_cut = 1500.0
	var filtered := await _record(game,audio,record,0.0)
	check("output filter responds",_brightness(filtered) < _brightness(first)*.5)
	print("GUNLAB output brightness_before=%.6f brightness_lowpass=%.6f" % [_brightness(first),_brightness(filtered)])
	audio.tuning.shotgun.high_cut = original.shotgun.high_cut
	audio.tuning.shotgun.volume = original.shotgun.volume
	audio.apply("shotgun")
	var baseline := audio.played
	var losses := audio.dropped
	for i in 40:
		audio.play_shot("shotgun")
		await game.get_tree().create_timer(.05).timeout
	await game.get_tree().create_timer(.6).timeout
	check("20 shots/s accepted",audio.played-baseline == 40)
	check("20 shots/s no stealing",audio.dropped == losses)
	print("GUNLAB stress shots=%d layer_dropped=%d pool=%d" % [audio.played-baseline,audio.dropped-losses,audio._voices.size()])
	var tail_before := audio.layer_plays[3]
	audio.play_shot("smg",0.0,true)
	await game.get_tree().create_timer(.2).timeout
	check("burst holds reflection",audio.layer_plays[3] == tail_before)
	audio.play_shot("smg",0.0,false,true)
	await game.get_tree().create_timer(.1).timeout
	check("burst ends with reflection",audio.layer_plays[3] == tail_before+1)
	audio.tuning.shotgun.layers[0].gain = -9.125
	audio.tuning.shotgun.layers[1].source = audio.catalog.rifle[0]
	check("write fixture",audio._write("res://design/tasks/reports/w6_reload.json") == OK)
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://scripts/gun_lab_reload_test.gd","--","--fresh-save"],output,true)
	check("restart load exact",code == 0)
	if code != 0:
		print("GUNLAB RELOAD output="+str(output).left(2600))
	for line: String in output:
		for part: String in line.split("\n"):
			if part.begins_with("GUNLAB RELOAD"):
				print(part)
	DirAccess.remove_absolute("res://design/tasks/reports/w6_reload.json")
	audio.tuning = original
	for gun: String in GunLabAudio.GUNS:
		audio.apply(gun)
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	print("GUNLABTEST checks=%d failed=%d" % [checks,failed])
	game.get_tree().quit(0 if failed == 0 else 1)

static func _record(game: Node, audio: GunLabAudio, record: AudioEffectRecord, gain: float) -> PackedByteArray:
	audio.tuning.shotgun.volume = gain
	audio.apply("shotgun")
	audio._rng.seed = 104729
	record.set_recording_active(true)
	await game.get_tree().create_timer(.08).timeout
	audio.play_shot("shotgun")
	await game.get_tree().create_timer(1.8).timeout
	record.set_recording_active(false)
	return record.get_recording().data

static func _rms(data: PackedByteArray) -> float:
	var sum := 0.0
	for i in data.size()/2:
		var v := data.decode_s16(i*2)/32768.0
		sum += v*v
	return sqrt(sum/maxi(1,data.size()/2))

static func _brightness(data: PackedByteArray) -> float:
	var energy := 0.0
	var difference := 0.0
	for i in range(2,data.size()/2):
		var sample := float(data.decode_s16(i*2))
		var previous := float(data.decode_s16((i-2)*2))
		energy += sample*sample
		difference += (sample-previous)*(sample-previous)
	return difference/maxf(energy,1.0)

static func capture(game: Node) -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--gunlab-shots"):
		if not game.gun_lab_range:
			game.player.god_mode = true
			game._full_loadout()
			for i in 40:
				game.horde.spawn(game.player.global_position+Vector2.from_angle(i*TAU/40.0)*160.0)
		await game.get_tree().create_timer(2.0).timeout
		if not game.gun_lab_range:
			var key := InputEventKey.new()
			key.pressed = true
			key.keycode = KEY_F9
			game._unhandled_input(key)
			await RenderingServer.frame_post_draw
			game.get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/w6_f9_battle.png")
			print("GUNLABSHOTS battle=true")
			game.get_tree().quit()
			return
		game.gun_lab_controller.panel.root.hide()
		await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/w6_range.png")
		game.gun_lab_controller.panel.root.show()
		await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/w6_panel.png")
		print("GUNLABSHOTS range=true panel=true")
		game.get_tree().quit()
		return
	game.spawner.enabled = false
	game.weapons.set_physics_process(false)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),true)
	for voice in game.sfx._loops:
		voice.stop()
	var record := AudioEffectRecord.new()
	AudioServer.add_bus_effect(0,record)
	DirAccess.make_dir_recursive_absolute("res://design/tasks/reports/w6_ab")
	var render_guns: Array = GunLabAudio.GUNS.duplicate()
	for arg: String in args:
		if arg.begins_with("--gunlab-gun=") and GunLabAudio.GUNS.has(arg.trim_prefix("--gunlab-gun=")):
			render_guns = [arg.trim_prefix("--gunlab-gun=")]
	for gun: String in render_guns:
		record.set_recording_active(true)
		await game.get_tree().create_timer(.1).timeout
		game.sfx.gun_lab.play_shot(gun)
		await game.get_tree().create_timer(2.5).timeout
		record.set_recording_active(false)
		var err := record.get_recording().save_to_wav("res://design/tasks/reports/w6_ab/"+gun+"_preset.wav")
		print("GUNLABRENDER gun=%s result=%d" % [gun,err])
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	var current_layout := AudioServer.generate_bus_layout()
	var reference_path := "res://design/tasks/reports/w6_ab/reference/"
	if FileAccess.file_exists(reference_path+"bus.tres"):
		var reference_layout := load(reference_path+"bus.tres") as AudioBusLayout
		AudioServer.set_bus_layout(reference_layout)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Shots"),-7.0)
		AudioServer.add_bus_effect(0,record)
		var voice := AudioStreamPlayer.new()
		voice.bus = &"Shots"
		game.add_child(voice)
		for gun: String in render_guns:
			voice.stream = AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(reference_path+gun+".wav"))
			record.set_recording_active(true)
			await game.get_tree().create_timer(.1).timeout
			voice.play()
			await game.get_tree().create_timer(2.5).timeout
			record.set_recording_active(false)
			record.get_recording().save_to_wav("res://design/tasks/reports/w6_ab/"+gun+"_main.wav")
		voice.queue_free()
		AudioServer.set_bus_layout(current_layout)
	game.get_tree().quit()
