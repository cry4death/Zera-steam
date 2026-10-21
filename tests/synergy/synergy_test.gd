extends GdUnitTestSuite
## Контракты SY2: ресурс корня, броня, происхождение, жизненный цикл и реальные карты.

var guns: Weapons
var prog: Progression
var crowd: Horde


func before_test() -> void:
	guns = auto_free(Weapons.new())
	guns.player = auto_free(Player.new())
	prog = auto_free(Progression.new())
	prog.weapons = guns
	prog.player = guns.player
	for model: String in ["mosin", "butcher"]:
		add_gun(model)
	crowd = auto_free(Horde.new())
	crowd._ready()
	crowd.setup(Rect2(0, 0, 1000, 1000), guns.player, null)
	guns.horde = crowd


func add_gun(model: String) -> Weapons.Slot:
	var s := Weapons.Slot.new()
	s.set_model(model)
	s.uid = guns.slots.size() + 1
	s.visual_model = model
	guns.slots.append(s)
	guns.refresh(guns.slots.size() - 1)
	s.stats["crit"] = -1.0
	s.mag = s.stats["mag"]
	return s


func enemy(health := 10.0) -> int:
	var e := crowd.spawn(Vector2(120, 100))
	crowd.hp[e] = health
	crowd.max_hp[e] = health
	return e


func donate(c: Weapons.HitContext, excess := 38.0) -> void:
	var result := Horde.DamageResult.new()
	result.killed = true
	result.overkill = excess
	guns._donate(c, result, Vector2(120, 100))


func test_damage_result_excludes_armor_and_counts_excess_after_freeze() -> void:
	var e := enemy()
	crowd.armor_mask[e] = 2
	crowd.armor_chest[e] = 100.0
	crowd.angle[e] = PI
	var result := Horde.DamageResult.new()
	crowd.damage(e, 48.0, Vector2.RIGHT, 0.0, 0, false, crowd.pos[e], false, 7, false, 0.5, result)
	assert_float(result.hp_damage).is_equal_approx(24.0, 0.001)
	assert_float(result.hp_lost).is_equal(10.0)
	assert_float(result.overkill).is_equal_approx(14.0, 0.001)
	assert_bool(result.killed).is_true()
	assert_float(result.armor_damage).is_greater(0.0)
	e = enemy(100.0)
	crowd.freeze_t[e] = 1.5
	result = Horde.DamageResult.new()
	crowd.damage(e, 8.0, Vector2.RIGHT, 0.0, 0, false, crowd.pos[e], false, -1, false, 1.0, result, 4.0)
	assert_float(result.hp_lost).is_equal_approx(14.0, 0.001) # 8 × 1,25 + 4


func test_first_positive_direct_kill_only_and_busy_does_not_extend() -> void:
	assert_bool(guns.install_link(1, 0)).is_true()
	var c := guns._begin_shot(0)
	donate(c, 0.0)
	donate(c)
	var m := guns.slots[1].module(WeaponDefs.Module.LINK)
	assert_float(m["charge"]).is_equal(28.5)
	guns._update_links(2.0)
	donate(c, 100.0)
	assert_float(m["left"]).is_equal(4.0)
	donate(guns._begin_shot(0), 100.0)
	assert_float(m["charge"]).is_equal(28.5)
	assert_float(m["left"]).is_equal(4.0)
	assert_int(guns.link_metrics["procs"]).is_equal(1)
	assert_float(guns.link_metrics["busy"]).is_equal(75.0)


func test_secondary_events_and_closed_root_never_feed_links() -> void:
	guns.install_link(1, 0)
	var c := guns._begin_shot(0)
	for kind: String in ["shard", "chain", "detonator", "dot", "cryo_shatter"]:
		var child := c.child(kind).child(kind)
		assert_int(child.root.id).is_equal(c.root.id)
		assert_int(child.generation).is_equal(2)
		donate(child)
	c.root.closed = true
	donate(c)
	assert_float(guns.slots[1].module(WeaponDefs.Module.LINK)["charge"]).is_equal(0.0)


func test_salvo_budget_cannot_multiply_by_pierce_ricochet_split_or_crit() -> void:
	guns.slots[1].level = 5
	guns.slots[1].modules = [{"id": WeaponDefs.Module.PIERCE, "rank": 3, "rare": false}, {"id": WeaponDefs.Module.SPLIT, "rank": 3, "rare": false}]
	guns.refresh(1)
	guns.slots[1].stats["crit"] = -1.0
	guns.install_link(1, 0)
	guns.slots[1].stats["crit"] = -1.0
	donate(guns._begin_shot(0), 1000.0)
	var cap := guns.overflow_limit(guns.slots[1])
	guns._event = guns._begin_shot(1)
	guns._fire_bullets(1, Vector2(100, 100), Vector2.RIGHT)
	var total := 0.0
	var primary := guns.bullet_count
	for i in primary: total += guns._boverflow[i]
	assert_float(total).is_equal_approx(cap, 0.001)
	assert_bool(guns._event.root.closed).is_true()
	var e := enemy(10000.0)
	crowd.freeze_t[e] = 1.5
	var before := crowd.hp[e]
	guns._bullet_hit(0, e, crowd.pos[e])
	var first := before - crowd.hp[e]
	assert_float(first).is_equal_approx(guns._bdmg[0] / 1.2 * 1.25 + cap / primary, 0.001)
	before = crowd.hp[e]
	var base := guns._bdmg[0]
	guns._bullet_hit(0, e, crowd.pos[e])
	assert_float(before - crowd.hp[e]).is_equal_approx(base * 1.25, 0.001)
	for i in range(primary, guns.bullet_count):
		assert_float(guns._boverflow[i]).is_equal(0.0)
		assert_bool(guns._bcontext[i].root.closed).is_true()
		assert_int(guns._bcontext[i].generation).is_greater(0)
	guns._event = null


func test_snapshot_survives_ammo_change_and_old_binding_is_rejected() -> void:
	guns.install_link(1, 0)
	var c := guns._begin_shot(0)
	guns.slots[0].ammo = WeaponDefs.Ammo.CRYO
	guns.refresh(0)
	assert_int(c.source.ammo).is_equal(WeaponDefs.Ammo.STANDARD)
	var m := guns.slots[1].module(WeaponDefs.Module.LINK)
	add_gun("saiga")
	assert_bool(guns.rebind_link(m, 2, 0)).is_true()
	donate(c)
	assert_float(m["charge"]).is_equal(0.0)
	donate(guns._begin_shot(0))
	assert_float(m["charge"]).is_greater(0.0)


func test_refresh_keeps_resource_expiry_and_breakup_destroys_it() -> void:
	guns.install_link(1, 0)
	donate(guns._begin_shot(0))
	guns._update_links(1.0)
	var m := guns.slots[1].module(WeaponDefs.Module.LINK)
	guns.refresh_all()
	assert_float(m["charge"]).is_equal(28.5)
	assert_float(m["left"]).is_equal(5.0)
	guns.slots[1].set_model("coach")
	guns.slots[1].visual_model = guns.slots[1].model
	guns.refresh(1)
	assert_bool(m["active"]).is_false()
	assert_float(m["charge"]).is_equal(0.0)
	assert_int(guns.link_count()).is_equal(1)
	guns.slots[1].set_model("butcher")
	guns.slots[1].visual_model = "butcher"
	guns.refresh(1)
	assert_bool(m["active"]).is_true()
	assert_float(m["charge"]).is_equal(0.0)


func test_expiry_and_refill_never_create_resource() -> void:
	guns.install_link(1, 0)
	donate(guns._begin_shot(0))
	guns.refill_all()
	assert_int(guns.link_metrics["procs"]).is_equal(1)
	guns._update_links(6.0)
	assert_float(guns.link_metrics["expired"]).is_equal(28.5)
	assert_float(guns.slots[1].module(WeaponDefs.Module.LINK)["charge"]).is_equal(0.0)


func test_all_models_use_actual_pattern() -> void:
	for model: String in WeaponDefs.MODEL_ORDER:
		var s := Weapons.Slot.new()
		s.set_model(model)
		var expected := s.base in [WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.AUTO_SHOTGUN] and s.trait_id != "slug"
		assert_bool(Weapons.overflow_receiver(s)).is_equal(expected)
		assert_bool(Weapons.overflow_receiver(s) and s.trait_id == "slug").is_false()


func test_stale_or_duplicate_card_does_not_spend_choice_or_money() -> void:
	prog.pending = 2
	prog.apply({"type": "link", "id": WeaponDefs.Module.LINK}, 1)
	assert_int(guns.link_count()).is_equal(0)
	assert_int(prog.pending).is_equal(2)
	var card := {"type": "link", "id": WeaponDefs.Module.LINK, "rare": false, "partner_uid": guns.slots[0].uid}
	prog.pending = 2
	prog.apply(card, 1)
	assert_int(prog.pending).is_equal(1)
	prog.apply(card, 1)
	assert_int(prog.pending).is_equal(1)
	var trader: Trader = auto_free(Trader.new())
	trader.weapons = guns
	trader.progression = prog
	prog.credits = 100
	trader.offers = [{"card": card, "price": 40, "sold": false}]
	assert_bool(trader.buy(0, 1)).is_false()
	assert_int(prog.credits).is_equal(100)
	assert_bool(guns.install_link(1, 0)).is_false()


func test_real_generator_deterministic_and_only_enabled_recipe() -> void:
	seed(92027)
	var first := prog.make_cards(3.0)
	seed(92027)
	assert_array(prog.make_cards(3.0)).is_equal(first)
	for run in 100:
		for card: Dictionary in prog.make_cards(3.0):
			assert_bool(card["type"] == "module" and card["id"] == WeaponDefs.Module.LINK).is_false()
			if card["type"] == "link":
				assert_bool(card["rare"]).is_false()
				assert_int(card["id"]).is_equal(WeaponDefs.Module.LINK)
	prog = auto_free(Progression.new())
	prog.weapons = guns
	prog.focus_overflow = true
	var offered := false
	for screen in 4:
		prog.level = screen + 6
		prog.pending = 1
		for card: Dictionary in prog.make_cards(3.0):
			offered = offered or card["type"] == "link"
	assert_bool(offered).is_true()


func test_freeze_epoch_keeps_contributors_and_cannot_reopen_on_refresh() -> void:
	var e := enemy(100.0)
	crowd.chill_hit(e, 0.2, 3, false, false, 1, true)
	crowd.chill_hit(e, 0.2, 3, false, false, 2, true)
	crowd.chill_hit(e, 0.2, 3, false, false, 2, true)
	assert_int(crowd.freeze_contributors[e]).is_equal(3)
	assert_int(crowd.freeze_epoch[e]).is_equal(1)
	assert_int(crowd.freeze_primary[e]).is_equal(1)
	crowd.freeze_used[e] = 1
	for k in 3: crowd.chill_hit(e, 0.2, 3, false, false, 1, true)
	assert_int(crowd.freeze_epoch[e]).is_equal(1)
	assert_int(crowd.freeze_used[e]).is_equal(1)
	crowd.freeze_t[e] = 0.0
	for k in 3: crowd.chill_hit(e, 0.2, 3) # вторичный раскол
	assert_int(crowd.freeze_epoch[e]).is_equal(2)
	assert_int(crowd.freeze_primary[e]).is_equal(0)


func test_no_live_ice_from_nominal_early_shambler() -> void:
	var e := enemy()
	for hit in 3:
		crowd.chill_hit(e, 0.2, 4, false, false, 1, true)
		crowd.damage(e, 4.0, Vector2.RIGHT, 0.0)
	assert_int(crowd.dead[e]).is_equal(1)
	assert_int(crowd.freeze_epoch[e]).is_equal(0)


func test_replacement_is_explicit_atomic_and_preview_matches_charge() -> void:
	var module := {"id": WeaponDefs.Module.TWIN, "rank": 1, "rare": false}
	guns.slots[1].modules.append(module)
	guns.refresh(1)
	assert_bool(guns.install_link(1, 0)).is_false()
	assert_int(guns.slots[1].modules.size()).is_equal(1)
	var card := {"type": "link", "id": WeaponDefs.Module.LINK, "receiver_uid": guns.slots[1].uid, "partner_uid": guns.slots[0].uid}
	assert_bool(prog.link_replacing(card)).is_true()
	card["replacement"] = module.duplicate(true)
	module["rank"] = 2
	prog.pending = 1
	prog.apply(card, 1)
	assert_int(prog.pending).is_equal(1)
	module["rank"] = 1
	prog.apply(card, 1)
	assert_int(prog.pending).is_equal(0)
	assert_int(guns.slots[1].modules.size()).is_equal(1)
	donate(guns._begin_shot(0), 10000.0)
	assert_float(prog.comparison(card, 1)["cap"]).is_equal(guns.slots[1].module(WeaponDefs.Module.LINK)["charge"])


func test_trader_stale_replacement_preserves_credits_and_free_rebind_preserves_instance() -> void:
	var module := {"id": WeaponDefs.Module.PIERCE, "rank": 1, "rare": false}
	guns.slots[1].modules.append(module)
	var card := {"type": "link", "id": WeaponDefs.Module.LINK, "partner_uid": guns.slots[0].uid, "replacement": module.duplicate(true)}
	var trader: Trader = auto_free(Trader.new())
	trader.weapons = guns
	trader.progression = prog
	prog.credits = 100
	trader.offers = [{"card": card, "price": 40, "sold": false}]
	module["rank"] = 2
	assert_bool(trader.buy(0, 1)).is_false()
	assert_int(prog.credits).is_equal(100)
	module["rank"] = 1
	assert_bool(trader.buy(0, 1)).is_true()
	assert_int(prog.credits).is_equal(60)
	var m := guns.slots[1].module(WeaponDefs.Module.LINK)
	var identity: int = m["instance_id"]
	guns.slots[1].set_model("coach")
	guns.slots[1].visual_model = "coach"
	guns.refresh(1)
	add_gun("saiga")
	prog.credits = 0
	assert_bool(trader.move_module(1, 0, 2, 0)).is_true()
	assert_int(m["instance_id"]).is_equal(identity)
	assert_int(prog.credits).is_equal(0)
	assert_int(m["binding_revision"]).is_equal(3)


func test_compaction_keeps_freeze_provenance_at_its_uid() -> void:
	var removed := enemy()
	var kept := enemy(100.0)
	var identity := crowd.uid[kept]
	for k in 3: crowd.chill_hit(kept, 0.2, 3, true, false, 2, true)
	crowd.freeze_used[kept] = 1
	crowd.damage(removed, 100.0, Vector2.RIGHT, 0.0)
	crowd._compact()
	var index := crowd.uid.find(identity)
	assert_int(index).is_equal(0)
	assert_int(crowd.freeze_contributors[index]).is_equal(2)
	assert_int(crowd.freeze_epoch[index]).is_equal(1)
	assert_int(crowd.freeze_used[index]).is_equal(1)
	assert_int(crowd.freeze_primary[index]).is_equal(1)


func test_pellets_share_root_but_separate_ammo_expenses_do_not() -> void:
	var c := guns._begin_shot(1)
	guns._event = c
	guns._fire_bullets(1, Vector2.ZERO, Vector2.RIGHT)
	for i in guns.bullet_count:
		assert_int(guns._bcontext[i].root.id).is_equal(c.root.id)
	assert_int(guns._begin_shot(1).root.id).is_not_equal(c.root.id)
	guns._event = null


func test_useless_launcher_modules_are_not_offered() -> void:
	add_gun("grom")
	assert_str(prog.module_status(2, WeaponDefs.Module.RICOCHET)).is_empty()
	assert_str(prog.module_status(2, WeaponDefs.Module.CHAIN)).is_empty()
	guns.slots[2].modules.append({"id": WeaponDefs.Module.DETONATOR, "rank": 1, "rare": false})
	guns.slots[2].level = 3
	assert_str(prog.module_status(2, WeaponDefs.Module.CHAIN)).is_not_empty()


func test_bot_completes_pair_and_replacement_before_spending_choice() -> void:
	guns.slots[1].modules.append({"id": WeaponDefs.Module.TWIN, "rank": 1, "rare": false})
	var card := {"type": "link", "id": WeaponDefs.Module.LINK}
	prog.pending = 1
	prog.auto_link(card, 1)
	prog.apply(card, 1)
	assert_int(prog.pending).is_equal(0)
	assert_int(guns.link_count()).is_equal(1)
	assert_int(guns.slots[1].modules.size()).is_equal(1)
