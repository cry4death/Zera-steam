extends SceneTree
## Воспроизводимые профили базы: --script ... -- --fresh-save --shot=<префикс>.

const Defs := preload("res://scripts/weapon_defs.gd")
const Rules := preload("res://scripts/campaign/campaign_rules.gd")
const TreeDefs := preload("res://scripts/class_tree.gd")
var base: Control
var meta: Node
var prefix := "res://design/tasks/reports/u4"
var checks := 0
var failed := 0

func _initialize() -> void:
	run.call_deferred()

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: failed += 1
	print("BASESECTIONS %s %s" % [label, "ok" if ok else "FAIL"])

func settle() -> void:
	await create_timer(0.45).timeout
	await RenderingServer.frame_post_draw

func shot(name: String, wait := true) -> void:
	if wait: await settle()
	else: await RenderingServer.frame_post_draw
	check("shot " + name, root.get_texture().get_image().save_png(prefix + "_" + name + ".png") == OK)

func pad(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	base._unhandled_input(event)
	event.pressed = false
	base._unhandled_input(event)
	await process_frame

func profiles(suffix: String) -> void:
	for i in [4, 3, 2, 1, 0]:
		base._set_tab(i)
		await shot(["barracks", "workshop", "arsenal", "crates", "operations"][i] + "_" + suffix)

func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="): prefix = arg.trim_prefix("--shot=").get_basename()
	meta = root.get_node("Meta")
	meta.persist = false
	meta.reset()
	var initial_world: Dictionary = meta.campaign.duplicate(true)
	meta.rng.seed = 60606
	set_meta("s6_return_to_base", true)
	base = load("res://scenes/base.tscn").instantiate()
	root.add_child(base)
	current_scene = base
	if OS.get_cmdline_user_args().has("--check-ui"):
		check("base presentation loaded", base.has_method("_ars_rows"))
		for c in 3:
			base._tree_class(c)
			var panels_fit := true
			var icons_valid := true
			for node: Dictionary in TreeDefs.catalog().values():
				icons_valid = icons_valid and base.TREE_ICONS.has(base._skill_icon(node))
				var title_lines: int = base._wrap(base.Style.TITLE_FONT, node["name"], 145, 13).size()
				var body_lines: int = base._wrap(base.Style.BODY_FONT, node["text"], 144, 10).size()
				var cost_y := maxf(180, 143 + title_lines * 16 + 9 + body_lines * 13 + 14)
				var reason: String = meta.unlock_reason(node["id"])
				var bottom := cost_y + 36
				if not reason.is_empty() and not meta.tree.has(node["id"]):
					bottom = cost_y + 50 + (base._wrap(base.Style.BODY_FONT, reason, 144, 8).size() - 1) * 10
				if bottom >= 320:
					print("BASESECTIONS panel overflow %s bottom=%s" % [node["id"], bottom])
					panels_fit = false
			check("skill panels fit class=%d" % c, panels_fit)
			check("skill icons valid class=%d" % c, icons_valid)
			for cluster in 3:
				base._focus_cluster(cluster)
				var visible_nodes := 0
				for i in TreeDefs.ids().size():
					if int(TreeDefs.node(base._node_id(i))["cluster"]) != cluster: continue
					if Rect2(128, 95, 330, 249).grow(-12).has_point(base._tree_pos(i)): visible_nodes += 1
				check("all 24 nodes class=%d cluster=%d" % [c, cluster], visible_nodes == 24)
		print("BASESECTIONS checks=%d failed=%d temporary_save=%s" % [checks, failed, not meta.persist])
		meta.finish_test(0 if failed == 0 else 1)
		return
	await settle()
	check("default available operation", base._op_sel >= 0)
	# Профиль после семи операций. Мир меняется тем же расчётом, что в кампании.
	for i in 7:
		var world: Dictionary = meta.campaign
		if world["offers"].is_empty(): break
		var result := Rules.advance(world, world["offers"][i % world["offers"].size()], "victory")
		meta.campaign = result["world"]
		meta.campaign["last_report"] = result["report"]
	meta.dna_earned = meta.dna_for_level(18) + 60
	meta.dna = 760
	meta.runs = 7
	meta.crates = 3
	meta.military_crates = 1
	for id: String in ["m4", "guard", "osa"]:
		if not meta.owned.has(id): meta.owned.append(id)
	for id: String in ["fire_1", "mag_1", "fire_2", "fire_3"]:
		if meta.can_unlock(id): meta.unlock(id)
	meta.workshop["m4"] = {"damage": 2, "rate": 1, "mag": 1, "reload": 0}
	base._ws_sel = base._ws_models().find("m4")
	base._set_tab(4)
	base._op_sel = -1
	base._open_operations()
	base._globe.skip_motion()
	await create_timer(1.2).timeout
	await shot("operations")
	check("zero infection explained", base._infection_outcome("Победа", 0, 0) == "Победа: регион очищен")
	check("infection units on both values", base._infection_outcome("Провал", 30, 37) == "Провал: заражение 30% → 37%")
	var globe_side: float = base._globe._display_side()
	var globe_center: Vector2 = base._globe._display_center()
	check("whole globe fits", Rect2(Vector2.ZERO, base._globe.size).encloses(Rect2(globe_center - Vector2.ONE * globe_side / 2, Vector2.ONE * globe_side)))
	var progress_world: Dictionary = meta.campaign.duplicate(true)
	meta.campaign = initial_world
	base._set_tab(4)
	base._open_operations()
	var front: Dictionary = meta.campaign["war"]["front"]
	if not front.is_empty():
		base._select_region(front["target"], false)
		base._globe.skip_motion()
	await shot("operations_strike")
	meta.campaign = progress_world
	base._set_tab(3)
	base._crate_sel = 1
	await settle()
	await base._test_click(Vector2(402, 273))
	check("mouse expands odds", base._crate_odds)
	base._crate_odds = false
	await pad(JOY_BUTTON_DPAD_LEFT)
	check("pad crate selection", base._crate_sel == 0)
	# Фиксируем сид новой модели, а саму награду выдаёт обычный Meta.open_crate.
	var probe := RandomNumberGenerator.new()
	for seed_value in 4096:
		probe.seed = seed_value
		if probe.randf() >= meta.CRATE_MODEL_CHANCE: continue
		var rare: bool = probe.randf() < meta.CRATE_RARE_CHANCE
		var pool := Defs.crate_models(Defs.Rarity.RARE if rare else Defs.Rarity.COMMON)
		var candidate: String = pool[probe.randi() % pool.size()]
		if meta.is_owned(candidate) or int(Defs.MODELS[candidate]["base"]) < 8: continue
		meta.rng.seed = seed_value
		break
	base._open_selected()
	check("crate consumed once", meta.crates == 2)
	check("crate reveals new weapon", base._open_res["kind"] == "model" and not base._open_res["duplicate"])
	while base._open != 4: await process_frame
	await create_timer(0.22).timeout
	check("crate new weapon category", int(Defs.MODELS[base._open_res["model"]]["base"]) >= 8)
	await shot("crate_card_new_type", false)
	base._advance()
	check("crate history", base._history.size() == 1)
	base._set_tab(1)
	base._ws_stat = 0
	var dna: int = meta.dna
	await base._test_key(KEY_E)
	check("keyboard buys upgrade", meta.dna < dna)
	await pad(JOY_BUTTON_DPAD_RIGHT)
	check("pad workshop parameter", base._ws_stat == 1)
	await base._test_click(Vector2(159, 222))
	check("mouse workshop parameter", base._ws_stat == 0)
	base._set_tab(0)
	base._focus_cluster(2)
	await shot("barracks")
	var grenade_icons: Dictionary = {}
	for id: String in ["gren_ready", "gren_radius", "gren_charge", "gren_throw", "gren_knock", "gren_push", "mag_grenade", "dash_smoke", "dash_fuse"]:
		grenade_icons[base._skill_icon(TreeDefs.node(id))] = true
	check("nine grenade effect silhouettes", grenade_icons.size() == 9)
	base._focus_cluster(0)
	var unlocked := false
	for i in TreeDefs.ids().size():
		var id: String = base._node_id(i)
		if not meta.can_unlock(id): continue
		base._focus_cluster(int(TreeDefs.node(id)["cluster"]))
		base._sel_node = i
		await pad(JOY_BUTTON_A)
		await pad(JOY_BUTTON_A)
		unlocked = meta.tree.has(id)
		break
	check("pad buys skill", unlocked)
	var old: int = base._sel_node
	await pad(JOY_BUTTON_DPAD_DOWN)
	check("pad tree navigation", base._sel_node != old)
	await base._test_click(Vector2(64, 276))
	check("mouse focuses cluster", base._tree_focus == 2)
	# Реальные модели W7: коллекция, ввод и мастерская без подмены каталога.
	base._set_tab(2)
	base._ars_sel = base._grid_model(1, base._ars_rows().size() - 1)
	base._ars_scroll = maxi(0, base._ars_rows().size() - 8)
	var seen: Dictionary = {}
	var categories: Dictionary = {}
	for row: Dictionary in base._ars_rows():
		categories[row["category"]] = true
		for index: int in row["models"]: seen[index] = true
	check("48 real entries reachable once", seen.size() == 48 and base._ars_order.size() == 48)
	check("16 real categories", categories.size() == 16)
	var silhouettes_fit := true
	for id: String in Defs.MODEL_ORDER:
		var image_size: Vector2 = base._tex[id].get_size() * 2.0
		silhouettes_fit = silhouettes_fit and image_size.x <= 332 and image_size.y <= 88
	check("48 large silhouettes fit above descriptions", silhouettes_fit)
	await shot("arsenal_48")
	var last_model: int = base._ars_sel
	await pad(JOY_BUTTON_DPAD_UP)
	check("last category pad navigation", base._ars_sel != last_model)
	var visited: Dictionary = {}
	for y in base._ars_rows().size():
		for x in 2:
			base._ars_sel = base._grid_model(x, y)
			base._nav(0, 0)
			visited[base._ars_sel] = true
			check("selection visible %d,%d" % [x, y], y >= base._ars_scroll and y < base._ars_scroll + 8)
			await process_frame
	check("all models navigated", visited.size() == 48)
	for id: String in Defs.MODEL_ORDER:
		if not meta.owned.has(id): meta.owned.append(id)
	base._set_tab(1)
	base._ws_sel = 47
	await shot("workshop_48")
	check("workshop all owned", base._ws_models().size() == 48)
	await pad(JOY_BUTTON_DPAD_UP)
	check("workshop last models pad", base._ws_sel == 46)
	await base._test_click(Vector2(90, 336))
	check("workshop down button", base._ws_scroll == 41)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	meta.settings["reduce_motion"] = true
	await profiles("720p")
	print("BASESECTIONS checks=%d failed=%d temporary_save=%s" % [checks, failed, not meta.persist])
	meta.finish_test(0 if failed == 0 else 1)

