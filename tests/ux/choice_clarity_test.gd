extends GdUnitTestSuite
## UX1: гарантия по seed, прогноз реальной покупки и серия тяжёлого оружия.

const GameScript := preload("res://scripts/game.gd")
var _workshop: Dictionary


func before_test() -> void:
	_workshop = Meta.workshop.duplicate(true)


func after_test() -> void:
	Meta.workshop = _workshop


func guns() -> Weapons:
	var result := Weapons.new()
	var slot := Weapons.Slot.new()
	slot.set_model("ak_s")
	slot.visual_model = slot.model
	result.slots.append(slot)
	result.refresh(0)
	return result


func test_guaranteed_weapon_varies_and_replays() -> void:
	var weapons := guns()
	var prog := Progression.new()
	prog.weapons = weapons
	var seen := {}
	for choosing_level in [2, 4]:
		prog.level = choosing_level
		prog.pending = 1
		for value in range(1, 25):
			seed(value)
			var first := prog.make_cards(0.0)
			seed(value)
			assert_array(prog.make_cards(0.0)).is_equal(first)
			assert_str(first[0]["type"]).is_equal("weapon")
			assert_int(first[0]["id"]).is_not_equal(WeaponDefs.Base.RIFLE)
			seen[first[0]["id"]] = true
	assert_int(seen.size()).is_greater(3)
	prog.free()
	weapons.free()


func test_trader_preview_matches_purchase_with_existing_build() -> void:
	Meta.workshop["ak_s"] = {"damage": 3, "mag": 2, "rate": 4, "reload": 2}
	var weapons := guns()
	weapons.bonuses = {"damage_mul": 1.2, "mag_mul": 1.1, "range_mul": 1.15}
	weapons.passives = {WeaponDefs.Passive.DAMAGE: 2, WeaponDefs.Passive.FIRE_RATE: 1}
	var slot := weapons.slots[0]
	slot.level = 3
	slot.modules.append({"id": WeaponDefs.Module.TWIN, "rank": 1, "rare": false})
	slot.ammo = WeaponDefs.Ammo.INCENDIARY
	weapons.refresh(0)
	var prog := Progression.new()
	prog.weapons = weapons
	prog.credits = 1000
	var trader := Trader.new()
	trader.weapons = weapons
	trader.progression = prog
	for card: Dictionary in [{"type": "level", "slot": 0, "rare": false},
		{"type": "module", "id": WeaponDefs.Module.TWIN, "rare": true},
		{"type": "ammo", "id": WeaponDefs.Ammo.CRYO, "rare": false}]:
		var before := slot.stats.duplicate(true)
		var before_modules := slot.modules.duplicate(true)
		var preview := prog.comparison(card, 0)
		assert_dict(slot.stats).is_equal(before)
		assert_array(slot.modules).is_equal(before_modules)
		assert_dict(preview["before"]).is_equal(before)
		trader.offers.assign([{"card": card, "price": 40, "sold": false}])
		assert_bool(trader.buy(0, 0)).is_true()
		assert_dict(slot.stats).is_equal(preview["after"])
		if card["type"] == "ammo":
			assert_str(preview["old_icon"]).is_equal("card_ammo_2")
			assert_int(slot.ammo).is_equal(WeaponDefs.Ammo.CRYO)
	trader.free()
	prog.free()
	weapons.free()


func test_weapon_dps_matches_shared_model_formula() -> void:
	for model: String in WeaponDefs.MODEL_ORDER:
		var s := Weapons.Slot.new()
		s.set_model(model)
		s.stats = WeaponDefs.model_stats(model, 1)
		assert_float(Progression.sustained_dps(s)).is_equal_approx(WeaponDefs.effective_dps(model, 1), 0.0001)


func test_ammo_preview_uses_current_critical_chance() -> void:
	var weapons := guns()
	var prog := Progression.new()
	prog.weapons = weapons
	var slot := weapons.slots[0]
	slot.ammo_rank = 3
	slot.ammo_rare = true
	var card := {"type": "ammo", "id": WeaponDefs.Ammo.CRYO, "rare": false}
	var before := Progression.sustained_dps(slot)
	var preview := prog.comparison(card, 0)
	prog.apply(card, 0, false)
	var after := Progression.sustained_dps(slot)
	assert_float(before / after).is_equal_approx((1.0 + (0.05 + 0.15 * WeaponDefs.RARE_MULT) * 1.5) / 1.05, 0.0001)
	assert_str(preview["rows"][1][1]).is_equal(Progression._num(before))
	assert_str(preview["rows"][1][2]).is_equal(Progression._num(after))
	prog.free()
	weapons.free()


func test_preview_invalidates_after_purchase_and_shows_radius() -> void:
	var weapons := guns()
	var slot := weapons.slots[0]
	slot.set_model(Meta.model_for(WeaponDefs.Base.LAUNCHER))
	slot.visual_model = slot.model
	weapons.refresh(0)
	var prog := Progression.new()
	prog.weapons = weapons
	var card := {"type": "module", "id": WeaponDefs.Module.PIERCE, "rare": false}
	var first := prog.comparison(card, 0)
	assert_str(first["rows"][1][0]).is_equal("blast")
	assert_float(float(first["after"]["radius"])).is_greater(float(first["before"]["radius"]))
	prog.apply(card, 0, false)
	assert_dict(prog.comparison(card, 0)["before"]).is_equal(first["after"])
	prog.free()
	weapons.free()


func test_heavy_multikills_survive_gap_and_expire_individually() -> void:
	var game := GameScript.new()
	for k in 4:
		game._combo_add()
	game._combo_step(3.0)
	assert_int(game.combo).is_equal(4)
	assert_int(game._combo_add()).is_equal(5)
	game._combo_step(3.01)
	assert_int(game.combo).is_equal(1)
	game._combo_step(3.0)
	assert_int(game.combo).is_equal(0)
	assert_int(game.best_combo).is_equal(5)
	game.free()


func test_combo_threshold_cannot_repeat_until_silence() -> void:
	var game := GameScript.new()
	for k in 5:
		game._combo_add()
	game._combo_step(3.0)
	game._combo_add()
	game._combo_step(3.01)
	for k in 4:
		assert_int(game._combo_add()).is_equal(0)
	game._combo_step(6.01)
	for k in 4:
		game._combo_add()
	assert_int(game._combo_add()).is_equal(5)
	game.free()
