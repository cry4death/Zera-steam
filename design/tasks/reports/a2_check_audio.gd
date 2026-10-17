extends SceneTree


func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://design/tasks/reports/a2_manifest.json"))
	var count := 0
	for entry: Dictionary in manifest["files"]:
		var path: String = "res://sfx/" + str(entry["file"])
		var clip := load(path) as AudioStreamWAV
		if clip == null or clip.mix_rate != 48000 or clip.stereo or clip.format != AudioStreamWAV.FORMAT_16_BITS or clip.loop_mode != AudioStreamWAV.LOOP_DISABLED:
			push_error("A2 resource mismatch: " + path)
			quit(1)
			return
		count += 1
	if count != 48:
		push_error("A2 count mismatch: " + str(count))
		quit(1)
		return
	print("A2 GODOT AUDIO: PASS; loaded=48; PCM16; 48000 Hz; mono; loops disabled")
	quit(0)
