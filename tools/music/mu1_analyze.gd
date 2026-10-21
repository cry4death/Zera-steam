extends SceneTree
## Разметка готовых OGG без перекодирования; запасной путь при недоступном Python.

const IDS := ["descent_into_madness_b", "delirious_charge", "delirium_charge", "infected_among_us",
	"mechanical_suffocation", "mechanical_survival", "obsessive_groove", "pressurized_chamber", "quarantine_zone",
	"rattling_machine", "sirenes_des_cendres", "suffocating_tension", "por", "descent_into_madness_a"]
const GROUPS := {"calm": ["infected_among_us", "quarantine_zone", "suffocating_tension"],
	"build": ["delirious_charge", "mechanical_survival", "rattling_machine", "por"],
	"peak": ["descent_into_madness_b", "delirium_charge", "mechanical_suffocation", "obsessive_groove", "pressurized_chamber"],
	"evac": ["sirenes_des_cendres"], "boss": ["descent_into_madness_a"]}


func _initialize() -> void:
	call_deferred("analyze")


func analyze() -> void:
	var rows: Dictionary = {}
	var map: Dictionary = {}
	var sr := float(AudioServer.get_mix_rate()) / 4.0
	var frames := int(sr * 0.02)
	var step := float(frames) / sr
	for id: String in IDS:
		var stream := AudioStreamOggVorbis.load_from_file("res://music/" + id + ".ogg")
		var playback := stream.instantiate_playback()
		playback.start()
		var envelope := PackedFloat32Array()
		var seconds := PackedFloat32Array()
		var acc := 0.0
		var count := 0
		var total := 0.0
		var peak := 0.0
		for block in int(stream.get_length() / step):
			var samples := playback.mix_audio(4.0, frames)
			var energy := 0.0
			for sample: Vector2 in samples:
				energy += sample.length_squared() * 0.5
				peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
			energy /= frames
			total += energy
			envelope.append(sqrt(energy))
			acc += energy
			count += 1
			if count >= int(1.0 / step):
				seconds.append(linear_to_db(sqrt(acc / count)))
				acc = 0.0
				count = 0
		playback.stop()
		var sorted := seconds.duplicate()
		sorted.sort()
		var q65 := sorted[int(sorted.size() * 0.65)]
		var strong := 8
		var quiet := 8
		var best := -100.0
		var least := 0.0
		for at in range(8, seconds.size() - 20):
			var mean := 0.0
			for k in 8:
				mean += seconds[at + k] / 8.0
			if mean < least:
				least = mean
				quiet = at
			if mean > best:
				best = mean
				strong = at
		# Первый устойчивый подъём до громкого участка; избегаем тихого вступления.
		for at in range(4, strong):
			var mean := 0.0
			for k in 8:
				mean += seconds[at + k] / 8.0
			if mean >= q65 and mean >= best - 1.5:
				strong = at
				break
		var flux := PackedFloat32Array()
		var hits := 0
		for k in envelope.size():
			var jump := maxf(0.0, envelope[k] - envelope[maxi(0, k - 1)])
			flux.append(jump)
			if k > 0 and jump > 0.012 and envelope[k] > envelope[k - 1] * 1.18:
				hits += 1
		var best_corr := -1.0
		var bpm := 120.0
		for lag in range(int(60.0 / 180.0 / step), int(60.0 / 75.0 / step) + 1):
			var corr := 0.0
			for k in range(lag, flux.size()):
				corr += flux[k] * flux[k - lag]
			if corr > best_corr:
				best_corr = corr
				bpm = 60.0 / (lag * step)
		var row := {"length": snappedf(stream.get_length(), 0.01), "rms_db": snappedf(linear_to_db(sqrt(total / envelope.size())), 0.1),
			"peak_db": snappedf(linear_to_db(peak), 0.1), "density": snappedf(hits / stream.get_length(), 0.01),
			"bpm_estimate": snappedf(bpm, 0.1), "quiet_entry": quiet, "strong_entry": strong,
			"quiet_db": snappedf(least, 0.1), "strong_db": snappedf(best, 0.1), "rms_seconds": Array(seconds)}
		rows[id] = row
		var group := ""
		for name: String in GROUPS:
			if id in GROUPS[name]:
				group = name
		var entry := row.duplicate()
		entry.erase("rms_seconds")
		entry["group"] = group
		# Окно содержит 50 блоков по 220/11025 с, а не ровно секунду.
		entry["quiet_entry"] = snappedf(quiet * int(1.0 / step) * step, 0.01)
		entry["strong_entry"] = snappedf(strong * int(1.0 / step) * step, 0.01)
		var entry_db := 0.0
		for k in 8:
			entry_db += seconds[strong + k] / 8.0
		entry["strong_db"] = snappedf(entry_db, 0.1)
		map[id] = entry
		print("MUSIC_ANALYSIS ", id, " rms=", row.rms_db, " density=", row.density, " bpm~=", row.bpm_estimate, " quiet=", quiet, " strong=", strong)
	var file := FileAccess.open("res://design/tasks/reports/mu1_analysis_before.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(rows, "\t"))
	file.close()
	file = FileAccess.open("res://music/music_map.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(map, "\t"))
	quit()
