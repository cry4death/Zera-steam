extends GdUnitTestSuite
## FR1: начало без базы, миграция без сброса и постоянные одноразовые действия.

const Profile := preload("res://scripts/meta.gd")

func _profile() -> Node:
	var profile: Node = auto_free(Profile.new())
	profile.persist = false
	profile.reset()
	return profile


func test_new_profile_requires_intro_and_persists_hints() -> void:
	var profile := _profile()
	assert_bool(profile.needs_first_run()).is_true()
	assert_bool(profile.hint_done("move")).is_false()
	profile.begin_first_run()
	var entered := _profile()
	assert_bool(entered.from_dict(profile.to_dict())).is_true()
	assert_bool(entered.needs_first_run()).is_true()
	profile.complete_hint("move")
	profile.complete_hint("unknown")
	var restored := _profile()
	assert_bool(restored.from_dict(profile.to_dict())).is_true()
	assert_bool(restored.needs_first_run()).is_true()
	assert_bool(restored.hint_done("move")).is_true()
	assert_bool(restored.hint_done("ability")).is_false()
	assert_bool(restored.first_run["hints"].has("unknown")).is_false()


func test_main_v8_profile_keeps_progress_and_all_tabs() -> void:
	var profile := _profile()
	profile.dna = 127
	profile.dna_earned = 900
	profile.runs = 0 # даже игравший без завершений не должен попасть во вводную
	profile.crates = 3
	profile.workshop = {"m4": {"damage": 2}}
	profile.owned.append("m4")
	var before: Dictionary = profile.to_dict()
	before["version"] = 8
	before.erase("first_run")
	var restored := _profile()
	assert_bool(restored.from_dict(before)).is_true()
	assert_bool(restored.needs_first_run()).is_false()
	for id: String in profile.FIRST_HINTS:
		assert_bool(restored.hint_done(id)).is_true()
	for id in 5:
		assert_bool(restored.tab_open(id)).is_true()
		assert_bool(restored.tab_new(id)).is_false()
	var after: Dictionary = restored.to_dict()
	for key: String in ["dna", "dna_earned", "runs", "crates", "military_crates", "tree", "class_id", "class_trees", "tree_gates", "workshop", "owned", "favorite", "settings", "campaign"]:
		assert_that(after[key]).is_equal(before[key])


func test_base_opens_progressively_and_never_relocks() -> void:
	var profile := _profile()
	profile.finish_first_run()
	profile.add_run({"dna_total": 0, "crates": 1})
	for id in [2, 3]:
		assert_bool(profile.tab_open(id)).is_true()
		assert_bool(profile.tab_new(id)).is_true()
	for id in [0, 1, 4]:
		assert_bool(profile.tab_open(id)).is_false()
	profile.visit_tab(2)
	profile.add_run({"dna_total": 80})
	assert_bool(profile.tab_open(0)).is_true()
	assert_bool(profile.tab_open(1)).is_true()
	assert_bool(profile.tab_open(4)).is_true()
	profile.dna_earned = 0 # имитируем расход всех очков: допуск уже сохранён
	var restored := _profile()
	assert_bool(restored.from_dict(profile.to_dict())).is_true()
	assert_bool(restored.tab_open(0)).is_true()
	assert_bool(restored.tab_new(2)).is_false()
	assert_bool(restored.tab_new(3)).is_true()


func test_skip_is_permanent_and_reveals_everything() -> void:
	var profile := _profile()
	profile.finish_first_run(true)
	var restored := _profile()
	assert_bool(restored.from_dict(profile.to_dict())).is_true()
	assert_bool(restored.needs_first_run()).is_false()
	for id in 5:
		assert_bool(restored.tab_open(id)).is_true()
	for id: String in profile.FIRST_HINTS:
		assert_bool(restored.hint_done(id)).is_true()


func test_hint_survives_actual_file_reload() -> void:
	var profile := _profile()
	profile.save_path = "res://tmp/test_results/fr1_profile.json"
	profile.persist = true
	profile.complete_hint("pickup")
	assert_bool(profile.last_save_ok).is_true()
	var restored := _profile()
	restored.save_path = profile.save_path
	assert_bool(restored.load_save()).is_true()
	assert_bool(restored.hint_done("pickup")).is_true()
	assert_bool(restored.hint_done("aim")).is_false()
	DirAccess.remove_absolute(profile.save_path)


func test_every_legacy_version_bypasses_intro() -> void:
	var profile := _profile()
	for version in range(1, 9):
		var legacy: Dictionary = profile.to_dict()
		legacy["version"] = version
		legacy.erase("first_run")
		var restored := _profile()
		assert_bool(restored.from_dict(legacy)).is_true()
		assert_bool(restored.needs_first_run()).is_false()
		# Повторный запуск уже мигрированного файла также не включает вводную.
		var reloaded := _profile()
		assert_bool(reloaded.from_dict(restored.to_dict())).is_true()
		assert_bool(reloaded.needs_first_run()).is_false()
		for tab in 5:
			assert_bool(reloaded.tab_open(tab)).is_true()
