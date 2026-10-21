extends Node
## Настоящие карты и боевые обработчики; результаты не подменяют время победы над боссом.

var guns: Weapons
var crowd: Horde
var player: Player
var hazards: Hazards
var kills := 0
var useful_hp := 0.0
var generated: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	for action: String in ["grenade", "dash", "reload", "fire", "aim_override", "move_left", "move_right", "move_up", "move_down", "aim_left", "aim_right", "aim_up", "aim_down"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	Meta.persist = false
	Meta.reset()
	get_tree().paused = true
	if OS.get_cmdline_user_args().has("--generator"):
		generator()
	else:
		for size in ([] if OS.get_cmdline_user_args().has("--cryo-only") else [2, 4]):
			for variant in ["empty", "link", "twin", "split", "chain", "passive", "level"]:
				for run_seed in [92027, 92028, 92029]:
					combat("overflow", variant, size, run_seed, true)
		for build in ([] if OS.get_cmdline_user_args().has("--overflow-only") else ["brittle", "thermoshock"]):
			for size in [2, 4]:
				for rank in [1, 2]:
					for immortal in [true, false]: combat(build, "cryo%d" % rank, size, 92027, immortal)
	var name := "SY2_generator.csv" if OS.get_cmdline_user_args().has("--generator") else "SY2_scenarios.csv"
	FileAccess.open("res://design/tasks/reports/" + name, FileAccess.WRITE).store_string("\n".join(generated) + "\n")
	print("SYNERGY_SCENARIOS rows=%d" % generated.size())
	get_tree().quit()


func world(models: Array) -> void:
	player = Player.new()
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	player.add_child(sprite)
	add_child(player)
	player.position = Vector2(1200, 900)
	player.arena = Rect2(0, 0, 2560, 1800)
	player.force_auto_aim = true
	player.autopilot = true
	crowd = Horde.new()
	add_child(crowd)
	crowd.setup(player.arena, player, null)
	crowd.enemy_impact.connect(func(_at: Vector2, _dir: Vector2, _code: int, amount: float, _knock: float, uid: int, _blast: bool) -> void:
		var e := crowd.uid.find(uid)
		if e >= 0: useful_hp += minf(amount, amount + crowd.hp[e]))
	crowd.enemy_died.connect(func(_p: Vector2, _k: int, _elite: bool) -> void: kills += 1)
	hazards = Hazards.new()
	hazards.horde = crowd
	hazards.player = player
	add_child(hazards)
	crowd.fat_burst.connect(hazards.fat_explosion)
	crowd.spit_fired.connect(hazards.spit)
	guns = Weapons.new()
	guns.player = player
	guns.horde = crowd
	add_child(guns)
	guns.slots.clear()
	guns._weapon_uid = 0
	for model: String in models: guns.add_weapon(WeaponDefs.MODELS[model]["base"], model)


func combat(build: String, variant: String, size: int, run_seed: int, immortal: bool) -> void:
	seed(run_seed)
	var models: Array = ["mosin", "butcher"] if build == "overflow" else ["ppsh", "druzhba" if build == "brittle" else "lpo"]
	if size == 4: models.append_array(["ak_s", "colt"])
	world(models)
	player.god_mode = immortal
	if build == "overflow":
		match variant:
			"link": guns.install_link(1, 0)
			"twin", "split", "chain":
				var module: int = {"twin": WeaponDefs.Module.TWIN, "split": WeaponDefs.Module.SPLIT, "chain": WeaponDefs.Module.CHAIN}[variant]
				guns.slots[1].modules.append({"id": module, "rank": 1, "rare": false})
			"passive": guns.passives[WeaponDefs.Passive.DAMAGE] = 1
			"level": guns.slots[1].level = 2
	else:
		guns.slots[0].ammo = WeaponDefs.Ammo.CRYO
		guns.slots[0].ammo_rank = 1 if variant == "cryo1" else 2
	guns.refresh_all()
	for s in guns.slots: s.mag = s.stats["mag"]
	kills = 0
	useful_hp = 0.0
	var spawns := RandomNumberGenerator.new()
	spawns.seed = run_seed
	var prepared := {}
	var accessible := {}
	var survived := 60.0
	var contacts := 0
	var lowest := 100.0
	for frame in 3600:
		if frame % 30 == 0:
			while crowd.count < 200:
				var k := crowd.count % 10
				crowd.spawn(player.position + Vector2.from_angle(spawns.randf() * TAU) * spawns.randf_range(130, 240), Horde.Kind.FAT if k == 0 else Horde.Kind.SPITTER if k == 1 else Horde.Kind.SHAMBLER)
		player._physics_process(1.0 / 60.0)
		crowd._physics_process(1.0 / 60.0)
		if build != "overflow":
			var receiver := guns.slots[1]
			for e in crowd.count:
				if crowd.dead[e] != 0 or crowd.freeze_t[e] <= 0.0 or crowd.freeze_primary[e] == 0: continue
				if crowd.freeze_contributors[e] & (1 << (guns.slots[0].uid - 1)) == 0: continue
				var key := "%d:%d" % [crowd.uid[e], crowd.freeze_epoch[e]]
				prepared[key] = true
				var to := crowd.pos[e] - player.position
				if to.length() <= float(receiver.stats["range"]) and not receiver.reloading and receiver.cooldown <= 0.0 and Vector2.from_angle(receiver.angle).dot(to.normalized()) >= cos(deg_to_rad(float(receiver.stats["spread"]) * 0.5)):
					accessible[key] = true # верхняя оценка: до отсечения восьми целей сектора
		guns._physics_process(1.0 / 60.0)
		hazards._physics_process(1.0 / 60.0)
		lowest = minf(lowest, player.hp)
		if player._hurt_t > 0.0: contacts += 1
		if player.is_dead:
			survived = float(frame + 1) / 60.0
			break
	var row := "combat,%s,%s,%d,%d,%s,seconds=%.2f,kills=%d,hp_damage=%.2f,prepared=%d,accessible_upper=%d,lowest_hp=%.2f,hurt_frames=%d,metrics=%s,cryo=%s" % [build, variant, size, run_seed, immortal, survived, kills, useful_hp, prepared.size(), accessible.size(), lowest, contacts, JSON.stringify(guns.link_metrics), JSON.stringify(guns.cryo_metrics)]
	generated.append(row)
	print(row)
	guns.free()
	hazards.free()
	crowd.free()
	player.free()


func generator() -> void:
	var meta_guns: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/guns_meta.json"))["models"]
	meta_guns.merge(JSON.parse_string(FileAccess.get_file_as_string("res://art/gun_meta_w7.json"))["models"])
	for developed in [false, true]:
		Meta.reset()
		if developed:
			for model: String in WeaponDefs.MODEL_ORDER:
				Meta.owned.append(model)
				Meta.workshop[model] = {"damage": 5, "rate": 5, "mag": 5, "reload": 5}
		for starter in ["mosin", "ak_s"]:
			for size in [2, 4]:
				for strategy in ["targeted", "survival", "unfocused"]:
					var found: Array[int] = []
					for run_seed in 1000:
						seed(92000 + run_seed)
						var w := Weapons.new()
						w._gun_meta = meta_guns
						w.add_weapon(WeaponDefs.MODELS[starter]["base"], starter)
						var p := Progression.new()
						p.weapons = w
						p.player = Player.new()
						p.gems = Gems.new()
						p.focus_overflow = strategy != "unfocused"
						var assembled := 99
						for choice in range(1, 26):
							p.level = choice + 1
							p.pending = 1
							var cards := p.make_cards(float(choice) * 10.0 / 25.0)
							var selected := pick_card(cards, p, size, strategy, choice)
							var card: Dictionary = cards[selected]
							var target := -1
							if Progression.needs_slot(card):
								for i in w.slots.size():
									if p.slot_status(card, i) != "":
										target = i
										break
								if card["type"] == "link":
									if w.slots[target].modules.size() >= WeaponDefs.module_slots(w.slots[target].level): card["replacement"] = w.slots[target].modules[0].duplicate(true)
									for i in w.slots.size():
										if w.link_available(target, i):
											card["partner_uid"] = w.slots[i].uid
											break
							if card["type"] != "weapon" or w.slots.size() < size: p.apply(card, target)
							if w.link_count() > 0:
								assembled = choice
								break
							if choice == 13:
								var trader := Trader.new()
								trader.progression = p
								trader.weapons = w
								trader.player = p.player
								p.credits = 100
								trader.start_visit(0, 5.0)
								for offer in trader.offers.size():
									if trader.offers[offer]["card"]["type"] != "link": continue
									for r in w.slots.size():
										for donor in w.slots.size():
											if w.link_available(r, donor):
												trader.offers[offer]["card"]["partner_uid"] = w.slots[donor].uid
												if trader.buy(offer, r): assembled = choice
								trader.free()
								if assembled != 99: break
						found.append(assembled)
						p.player.free()
						p.gems.free()
						p.free()
						w.free()
					found.sort()
					var by5 := 0
					var by8 := 0
					var failed := 0
					for n in found:
						if n <= 13: by5 += 1
						if n <= 22: by8 += 1
						if n == 99: failed += 1
					var row := "generator,%s,%s,%d,%s,seeds=1000,by_choice13=%d,by_choice22=%d,unbuilt=%d,p10=%d,p50=%d,p90=%d" % [developed, starter, size, strategy, by5, by8, failed, found[100], found[500], found[900]]
					generated.append(row)
					print(row)
	# Записанные кривые подбора HD1: не выдаём номер выбора за минуту забега.
	for curve: String in ["low_pickup", "mid_pickup", "high_pickup"]:
		for developed in [false, true]:
			for starter in ["mosin", "ak_s"]:
				for strategy in ["targeted", "survival", "unfocused"]:
					generator_timed(meta_guns, curve, developed, starter, strategy)


func generator_timed(meta_guns: Dictionary, curve: String, developed: bool, starter: String, strategy: String) -> void:
	var trace := "res://design/tasks/reports/hd1_sim_%s_final.log" % {"low_pickup": "full", "mid_pickup": "w1", "high_pickup": "starter"}[curve]
	var xp_curve: Array[float] = [0.0]
	var credit_curve: Array[int] = [0]
	var pattern := RegEx.create_from_string("^SIM [0-9]+:00.*xp=([0-9]+)/[0-9]+ credits=([0-9]+)/")
	for line: String in FileAccess.get_file_as_string(trace).split("\n"):
		var hit := pattern.search(line)
		if hit:
			xp_curve.append(float(hit.get_string(1)))
			credit_curve.append(int(hit.get_string(2)))
	assert(xp_curve.size() == 11)
	Meta.reset()
	if developed:
		for model: String in WeaponDefs.MODEL_ORDER:
			Meta.owned.append(model)
			Meta.workshop[model] = {"damage": 5, "rate": 5, "mag": 5, "reload": 5}
	var times: Array[float] = []
	var choices: Array[int] = []
	var by5 := 0
	var by8 := 0
	var failed := 0
	for run_seed in 1000:
		seed(92000 + run_seed)
		var w := Weapons.new()
		w._gun_meta = meta_guns
		w.add_weapon(WeaponDefs.MODELS[starter]["base"], starter)
		var p := Progression.new()
		p.weapons = w
		p.player = Player.new()
		p.gems = Gems.new()
		p.focus_overflow = strategy != "unfocused"
		var assembled := 99.0
		var assembled_choice := 99
		var total_xp := 0
		var visited := false
		for choice in range(1, 40):
			total_xp += Progression.xp_to_next(choice)
			if total_xp > xp_curve.back(): break
			var minute := 1
			while xp_curve[minute] < total_xp: minute += 1
			var at := minute - 1 + (float(total_xp) - xp_curve[minute - 1]) / (xp_curve[minute] - xp_curve[minute - 1])
			if at >= 5.0 and not visited:
				visited = true
				p.credits = credit_curve[5]
				var trader := Trader.new()
				trader.progression = p
				trader.weapons = w
				trader.player = p.player
				trader.start_visit(0, 5.0)
				for offer in trader.offers.size():
					var card: Dictionary = trader.offers[offer]["card"]
					if card["type"] != "link": continue
					for receiver in w.slots.size():
						if p.slot_status(card, receiver) == "": continue
						p.auto_link(card, receiver)
						if trader.buy(offer, receiver):
							assembled = 5.0
							assembled_choice = choice - 1
				trader.free()
				if assembled != 99.0: break
			p.level = choice + 1
			p.pending = 1
			var cards := p.make_cards(at)
			var card: Dictionary = cards[pick_card(cards, p, 4, strategy, choice)]
			var target := -1
			if Progression.needs_slot(card):
				for receiver in w.slots.size():
					if p.slot_status(card, receiver) != "":
						target = receiver
						break
			p.auto_link(card, target)
			p.apply(card, target)
			if w.link_count() > 0:
				assembled = at
				assembled_choice = choice
				break
		times.append(assembled)
		choices.append(assembled_choice)
		if assembled <= 5.0: by5 += 1
		if assembled <= 8.0: by8 += 1
		if assembled == 99.0: failed += 1
		p.player.free()
		p.gems.free()
		p.free()
		w.free()
	times.sort()
	choices.sort()
	var row := "timed,%s,%s,%s,4,%s,seeds=1000,by5=%d,by8=%d,unbuilt=%d,choice_p10=%d,choice_p50=%d,choice_p90=%d,min_p10=%.3f,min_p50=%.3f,min_p90=%.3f" % [curve, developed, starter, strategy, by5, by8, failed, choices[100], choices[500], choices[900], times[100], times[500], times[900]]
	generated.append(row)
	print(row)


func pick_card(cards: Array, p: Progression, size: int, strategy: String, choice: int) -> int:
	var best := -1000
	var selected := 0
	for k in cards.size():
		var c: Dictionary = cards[k]
		var score := 0
		if c["type"] == "link": score = 100
		if c["type"] == "weapon":
			score = -20
			if p.weapons.slots.size() < size:
				var s := Weapons.Slot.new()
				s.set_model(Meta.model_for(c["id"]))
				var heavy := false
				var pellets := false
				for held in p.weapons.slots:
					heavy = heavy or Weapons.overflow_donor(held)
					pellets = pellets or Weapons.overflow_receiver(held)
				if not heavy and Weapons.overflow_donor(s) or not pellets and Weapons.overflow_receiver(s): score = 90
		if c["type"] == "level": score = 30
		if c["type"] == "passive":
			score = 20
			if strategy == "survival" and choice % 2 == 0 and c["id"] in [WeaponDefs.Passive.HP, WeaponDefs.Passive.SPEED]: score = 110
		if score > best:
			best = score
			selected = k
	return selected
