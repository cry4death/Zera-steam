extends GdUnitTestSuite
## Характеристики оружия: уровни L1–L5, эффективный DPS, пробитие брони, модули.
## Числа АК-С — design/BALANCE.md §3.2–3.3.

const STAT_KEYS := ["damage", "rate", "mag", "reload", "proj"]


func test_rifle_levels_match_balance() -> void:
	var l1 := WeaponDefs.base_stats(WeaponDefs.Base.RIFLE, 1)
	assert_float(l1["damage"]).is_equal(7.0)
	assert_float(l1["rate"]).is_equal(6.0)
	assert_int(l1["mag"]).is_equal(30)
	assert_float(l1["reload"]).is_equal(1.5)
	assert_int(l1["proj"]).is_equal(1)
	# L2 урон +2, L3 магазин +15 и темп +15%, L4 +1 пуля, L5 урон +4 и перезарядка −30%.
	var l5 := WeaponDefs.base_stats(WeaponDefs.Base.RIFLE, 5)
	assert_float(l5["damage"]).is_equal(13.0)
	assert_int(l5["mag"]).is_equal(45)
	assert_float(l5["rate"]).is_equal_approx(6.9, 0.0001)
	assert_int(l5["proj"]).is_equal(2)
	assert_float(l5["reload"]).is_equal_approx(1.05, 0.0001)


func test_level_above_max_is_capped() -> void:
	for base: int in WeaponDefs.BASES:
		assert_dict(WeaponDefs.base_stats(base, WeaponDefs.MAX_LEVEL + 3)).is_equal(WeaponDefs.base_stats(base, WeaponDefs.MAX_LEVEL))


func test_every_model_has_sane_stats() -> void:
	for model: String in WeaponDefs.MODEL_ORDER:
		for level in range(1, WeaponDefs.MAX_LEVEL + 1):
			var s := WeaponDefs.model_stats(model, level)
			for key: String in STAT_KEYS:
				var v := float(s[key])
				assert_bool(is_finite(v) and v > 0.0).override_failure_message("%s L%d %s=%s" % [model, level, key, v]).is_true()


## Известные уровни, на которых эффективный DPS падает (модель → уровень). Гарпун: last_round даёт бонус
## одному патрону, и «магазин +2» на L3 размазывает его — 37.33 → 36.52. Находка баланса, см. отчёт godot-tooling.
const KNOWN_DPS_DROPS := {"harpoon": 3}


# Уровень в забеге — усиление: DPS не падает (кроме известных исключений), а к L5 растёт.
func test_levels_never_lower_dps() -> void:
	for model: String in WeaponDefs.MODEL_ORDER:
		var prev := WeaponDefs.effective_dps(model, 1)
		for level in range(2, WeaponDefs.MAX_LEVEL + 1):
			var dps := WeaponDefs.effective_dps(model, level)
			var drops := dps < prev - 0.0001
			var known: bool = int(KNOWN_DPS_DROPS.get(model, 0)) == level
			assert_bool(drops).override_failure_message("%s L%d: %.2f → %.2f, исключение %s" % [model, level, prev, dps, known]).is_equal(known)
			prev = dps
		assert_float(WeaponDefs.effective_dps(model, WeaponDefs.MAX_LEVEL)).is_greater(WeaponDefs.effective_dps(model, 1))


func test_model_order_covers_all_models() -> void:
	var seen := {}
	for model: String in WeaponDefs.MODEL_ORDER:
		assert_bool(seen.has(model)).override_failure_message("дубль %s" % model).is_false()
		seen[model] = true
	assert_array(seen.keys()).contains_exactly_in_any_order(WeaponDefs.MODELS.keys())


# models_of: серийная модель категории идёт первой.
func test_serial_model_comes_first() -> void:
	for base: int in WeaponDefs.Base.values():
		var models := WeaponDefs.models_of(base)
		if models.is_empty():
			continue
		assert_str(models[0]).is_equal(WeaponDefs.serial_model(base))
		assert_int(WeaponDefs.MODELS[models[0]]["rarity"]).is_equal(WeaponDefs.Rarity.SERIAL)


func test_armor_penetration_in_range() -> void:
	for model: String in WeaponDefs.MODEL_ORDER:
		var base: int = WeaponDefs.MODELS[model]["base"]
		for rank in WeaponDefs.MAX_RANK + 1:
			for distance: float in [0.0, 45.0, 46.0, 400.0]:
				var p := WeaponDefs.armor_penetration(base, model, rank, distance)
				assert_float(p).override_failure_message("%s r%d d%.0f p=%.2f" % [model, rank, distance, p]).is_between(0.0, 1.0)


func test_shotgun_penetrates_only_point_blank() -> void:
	assert_float(WeaponDefs.armor_penetration(WeaponDefs.Base.SHOTGUN, "", 0, 45.0)).is_equal(0.8)
	assert_float(WeaponDefs.armor_penetration(WeaponDefs.Base.SHOTGUN, "", 0, 46.0)).is_equal(0.0)
	# Каждый ранг модуля +25%, но не больше 100%.
	assert_float(WeaponDefs.armor_penetration(WeaponDefs.Base.RIFLE, "", 3)).is_equal(0.75)
	assert_float(WeaponDefs.armor_penetration(WeaponDefs.Base.RAIL, "", 3)).is_equal(1.0)


func test_module_slots_by_level(level: int, slots: int, test_parameters := [[1, 1], [2, 1], [3, 2], [4, 2], [5, 3]]) -> void:
	assert_int(WeaponDefs.module_slots(level)).is_equal(slots)


func test_special_bases_limit_modules_and_ammo() -> void:
	assert_bool(WeaponDefs.supports_ammo(WeaponDefs.Base.FLAMER, WeaponDefs.Ammo.CRYO)).is_false()
	assert_bool(WeaponDefs.supports_ammo(WeaponDefs.Base.FLAMER, WeaponDefs.Ammo.INCENDIARY)).is_true()
	assert_bool(WeaponDefs.supports_ammo(WeaponDefs.Base.SAW, WeaponDefs.Ammo.INCENDIARY)).is_false()
	assert_bool(WeaponDefs.supports_module(WeaponDefs.Base.SAW, WeaponDefs.Module.TWIN)).is_false()
	assert_bool(WeaponDefs.supports_module(WeaponDefs.Base.TESLA, WeaponDefs.Module.TWIN)).is_true()
	assert_bool(WeaponDefs.supports_module(WeaponDefs.Base.RIFLE, WeaponDefs.Module.RICOCHET)).is_true()
