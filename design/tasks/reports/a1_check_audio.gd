extends SceneTree


func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://sfx/manifest.json"))
	var qoa_count := 0
	var pcm_count := 0
	for entry: Dictionary in manifest["files"]:
		var path: String = "res://sfx/" + str(entry["file"])
		var clip: AudioStreamWAV = load(path) as AudioStreamWAV
		assert(clip != null, path)
		assert(clip.mix_rate == 48000, path)
		assert(clip.loop_mode == AudioStreamWAV.LOOP_DISABLED, path)
		assert(clip.stereo == path.begins_with("res://sfx/weapons/"), path)
		if path.begins_with("res://sfx/casings/"):
			assert(clip.format == AudioStreamWAV.FORMAT_16_BITS, path)
			pcm_count += 1
		else:
			assert(clip.format == AudioStreamWAV.FORMAT_QOA, path)
			qoa_count += 1
	print("GODOT AUDIO: PASS; loaded=", qoa_count + pcm_count, "; QOA=", qoa_count, "; PCM16=", pcm_count, "; rate=48000; channels correct; loops disabled")
	quit(0)
