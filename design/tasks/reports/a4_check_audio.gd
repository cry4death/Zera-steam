extends SceneTree


func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://sfx/manifest.json"))
	var count := 0
	var loops := 0
	for entry: Dictionary in manifest["files"]:
		var relative: String = str(entry["file"])
		if not relative.split("/")[0] in ["zombies", "ambience", "gore", "player", "ui"]:
			continue
		var path := "res://sfx/" + relative
		var clip: AudioStreamWAV = load(path) as AudioStreamWAV
		if clip == null or clip.mix_rate != 48000 or clip.stereo or clip.format != AudioStreamWAV.FORMAT_16_BITS:
			push_error("A4 invalid imported audio: " + path)
			quit(1)
			return
		var is_loop := relative.begins_with("ambience/horde_") or relative.begins_with("player/heartbeat_")
		var expected := AudioStreamWAV.LOOP_FORWARD if is_loop else AudioStreamWAV.LOOP_DISABLED
		if clip.loop_mode != expected:
			push_error("A4 invalid loop mode: " + path)
			quit(1)
			return
		if is_loop:
			# Импортёр преобразует edit/loop_end=-1 в индекс последнего отсчёта N-1.
			if clip.loop_begin != 0 or clip.loop_end != clip.data.size() / 2 - 1:
				push_error("A4 invalid loop bounds: %s begin=%d end=%d frames=%d" % [path, clip.loop_begin, clip.loop_end, clip.data.size() / 2])
				quit(1)
				return
			loops += 1
		count += 1
	if count != 93 or loops != 3:
		push_error("A4 incomplete audio set")
		quit(1)
		return
	print("A4 GODOT AUDIO: PASS; loaded=", count, "; PCM16 mono 48000 Hz; forward loops=", loops, "; full loop bounds correct")
	quit(0)
