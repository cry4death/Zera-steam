extends GdUnitTestSuite
## Музыкальный ритм: выдержка, приоритеты, воспроизводимость и входы в сильные части.

const MusicScript := preload("res://scripts/music.gd")
var music: Node
var now := 0.0


func before_test() -> void:
	music = auto_free(MusicScript.new())
	music._enabled = false
	music.begin_combat(81073)
	now = 0.0


func step(seconds: float, phase := HordeDirector.Phase.SCOUT, alarm := false,
	activity := false, evac := false, boss := false, nearby := 0, hp := 1.0) -> void:
	for i in int(round(seconds * 10.0)):
		now += 0.1
		music.combat_step(0.1, now, phase, alarm, activity, evac, boss, nearby, hp)


func test_director_cycle() -> void:
	var track: String = music.current()
	var entry: float = music._entry
	step(10.0)
	assert_int(music.state).is_equal(MusicScript.State.CALM)
	step(24.0, HordeDirector.Phase.BUILD)
	assert_int(music.state).is_equal(MusicScript.State.BUILD)
	assert_float(music.target_db()).is_equal(-3.0)
	step(10.0, HordeDirector.Phase.PEAK)
	assert_int(music.state).is_equal(MusicScript.State.PEAK)
	assert_float(music.target_db()).is_equal(-1.0)
	var peak_track: String = music.current()
	step(20.0, HordeDirector.Phase.DECAY)
	assert_int(music.state).is_equal(MusicScript.State.DECAY)
	assert_str(music.current()).is_equal(peak_track)
	step(16.0, HordeDirector.Phase.RELAX)
	assert_int(music.state).is_equal(MusicScript.State.CALM)
	assert_str(music.current()).is_equal(track)
	assert_float(music._entry).is_equal(entry)
	assert_int(music._track_serial).is_equal(1)


func test_ordinary_states_respect_minimum_without_replacing_track() -> void:
	var previous: int = music.state
	var last_change := 0.0
	var transitions := 0
	var track: String = music.current()
	for i in 1200:
		var phase := HordeDirector.Phase.BUILD if i / 27 % 2 == 0 else HordeDirector.Phase.PEAK
		step(0.1, phase)
		if music.state != previous:
			assert_float(now - last_change).is_greater_equal(MusicScript.MIN_STATE - 0.001)
			last_change = now
			previous = music.state
			transitions += 1
	assert_int(transitions).is_greater(3)
	assert_str(music.current()).is_equal(track)
	assert_int(music._track_serial).is_equal(1)


func test_boss_then_evac_then_alarm_priority_and_strong_entries() -> void:
	step(0.1, HordeDirector.Phase.PEAK, true, true, true, true)
	assert_int(music.state).is_equal(MusicScript.State.BOSS)
	assert_str(music.current()).is_equal(MusicScript.BOSS)
	assert_str(music._track_reason).is_equal("boss")
	var serial: int = music._track_serial
	# Исчезновение босса не запускает уже звучавшие под ним сигналы.
	step(9.0, HordeDirector.Phase.PEAK, true, true, true)
	assert_int(music.state).is_equal(MusicScript.State.EVAC)
	assert_int(music._track_serial).is_equal(serial)
	step(0.1)
	step(0.1, HordeDirector.Phase.SCOUT, false, false, true)
	assert_str(music.current()).is_equal(MusicScript.EVAC)
	assert_str(music._track_reason).is_equal("evac")
	step(0.1)
	step(0.1, HordeDirector.Phase.SCOUT, true)
	assert_int(music.state).is_equal(MusicScript.State.PEAK)
	assert_str(music._track_reason).is_equal("alarm")
	var row: Dictionary = music._map[music.current()]
	assert_float(music._entry).is_equal(minf(float(row["strong_entry"]), float(row["length"]) - MusicScript.OVERLAP - MusicScript.MIN_TRACK))
	serial = music._track_serial
	step(20.0, HordeDirector.Phase.SCOUT, true)
	assert_int(music._track_serial).is_equal(serial)


func test_long_quiet_arms_one_peak_transition_through_build() -> void:
	step(41.0)
	step(10.0, HordeDirector.Phase.BUILD)
	step(3.0, HordeDirector.Phase.PEAK)
	assert_int(music._track_serial).is_equal(2)
	assert_str(music._track_reason).is_equal("long_quiet_peak")
	step(10.0, HordeDirector.Phase.DECAY)
	step(30.0)
	step(10.0, HordeDirector.Phase.BUILD)
	step(3.0, HordeDirector.Phase.PEAK)
	assert_int(music._track_serial).is_equal(2)


func test_track_end_and_minimum_remaining_playtime() -> void:
	for id: String in music._map:
		for state: int in range(MusicScript.STATES.size()):
			music.state = state
			music._start(id, true, "ended")
			var row: Dictionary = music._map[id]
			assert_float(float(row["length"]) - music._entry - MusicScript.OVERLAP).is_greater_equal(MusicScript.MIN_TRACK - 0.001)
	music.begin_combat(81073)
	var duration: float = music._map[music.current()]["length"] - music._entry - MusicScript.OVERLAP
	step(duration - 0.2, HordeDirector.Phase.BUILD)
	assert_int(music._track_serial).is_equal(1)
	step(0.5, HordeDirector.Phase.BUILD)
	assert_int(music._track_serial).is_equal(2)
	assert_str(music._track_reason).is_equal("ended")
	var next_row: Dictionary = music._map[music.current()]
	assert_float(music._entry).is_equal(minf(float(next_row["strong_entry"]), float(next_row["length"]) - MusicScript.OVERLAP - MusicScript.MIN_TRACK))


func test_event_release_and_warn_to_active_do_not_replace_track() -> void:
	step(1.0, HordeDirector.Phase.SCOUT, true)
	var serial: int = music._track_serial
	# WARN и ACTIVE приходят как один непрерывный сигнал alarm.
	step(10.0, HordeDirector.Phase.PEAK, true)
	assert_int(music._track_serial).is_equal(serial)
	step(10.0)
	assert_int(music.state).is_equal(MusicScript.State.CALM)
	assert_int(music._track_serial).is_equal(serial)
	step(10.0, HordeDirector.Phase.BUILD)
	step(10.0, HordeDirector.Phase.PEAK)
	assert_int(music._track_serial).is_equal(serial)


func test_brief_density_spike_is_ignored_and_density_has_hysteresis() -> void:
	step(10.0)
	step(1.0, HordeDirector.Phase.SCOUT, false, false, false, false, 20)
	step(1.0)
	assert_int(music.state).is_equal(MusicScript.State.CALM)
	step(3.0, HordeDirector.Phase.SCOUT, false, false, false, false, 16)
	assert_int(music.state).is_equal(MusicScript.State.PEAK)
	step(10.0, HordeDirector.Phase.SCOUT, false, false, false, false, 12)
	assert_int(music.state).is_equal(MusicScript.State.PEAK)
	step(3.0)
	assert_int(music.state).is_equal(MusicScript.State.CALM)


func test_activity_builds_and_low_hp_ducks_without_silencing() -> void:
	step(10.0, HordeDirector.Phase.SCOUT, false, true)
	assert_int(music.state).is_equal(MusicScript.State.BUILD)
	var normal: float = music.target_db()
	step(0.1, HordeDirector.Phase.SCOUT, false, true, false, false, 0, 0.29)
	assert_float(music.target_db()).is_equal(normal - 5.0)
	step(0.1, HordeDirector.Phase.SCOUT, false, true, false, false, 0, 0.35)
	assert_float(music.target_db()).is_equal(normal - 5.0)
	step(0.1, HordeDirector.Phase.SCOUT, false, true, false, false, 0, 0.41)
	assert_float(music.target_db()).is_equal(normal)
	music.duck(true)
	assert_float(music.target_db()).is_equal(normal + MusicScript.DUCK_DB)
	music.play(&"results")
	assert_float(music.target_db()).is_equal(MusicScript.RESULTS_DB)


func test_playlist_seed_does_not_consume_global_rng() -> void:
	seed(1234)
	var expected := randi()
	seed(1234)
	music.begin_combat(42)
	var first: String = music.current()
	step(20.0, HordeDirector.Phase.PEAK)
	var second: String = music.current()
	assert_int(randi()).is_equal(expected)
	music.begin_combat(42)
	assert_str(music.current()).is_equal(first)
	step(20.0, HordeDirector.Phase.PEAK)
	assert_str(music.current()).is_equal(second)


func test_bags_do_not_repeat_at_refill() -> void:
	for state: int in [MusicScript.State.CALM, MusicScript.State.BUILD, MusicScript.State.PEAK]:
		music.state = state
		var last := ""
		for i in 30:
			var next: String = music._pick()
			assert_str(next).is_not_equal(last)
			last = next


func test_track_map_covers_combat_with_safe_entry_margins() -> void:
	assert_int(music._map.size()).is_equal(14)
	for id: String in music._map:
		var row: Dictionary = music._map[id]
		assert_bool(FileAccess.file_exists("res://music/" + id + ".ogg")).is_true()
		for key: String in ["quiet_entry", "strong_entry"]:
			assert_float(float(row[key])).is_greater_equal(0.0)
			assert_float(float(row[key])).is_less(float(row["length"]) - 20.0)
