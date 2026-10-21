class_name CampaignCapture
extends RefCounted
## Снимки реального viewport и проверка кнопок исхода событиями геймпада.


static func shot(tree: SceneTree, suffix: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await tree.process_frame
	await RenderingServer.frame_post_draw
	var path := "res://design/tasks/reports/c6_%s.png" % suffix
	assert(tree.root.get_texture().get_image().save_png(path) == OK)
	print("C6SHOT " + path)


static func run(base: Control) -> void:
	var tree := base.get_tree()
	tree.root.mode = Window.MODE_WINDOWED
	tree.root.size = Vector2i(1920, 1080)
	Meta.campaign = CampaignRules.initial(20261017)
	Meta.campaign["regions"]["west_europe"]["infection"] = 82
	Meta.campaign["regions"]["siberia"]["infection"] = 85
	Meta.campaign["offers"] = CampaignDirector.generate(Meta.campaign)
	base._open_operations()
	base._select_operation(0)
	base._globe.skip_motion()
	await tree.create_timer(0.3).timeout
	await shot(tree, "globe")
	await shot(tree, "brief_clear")
	# D-pad выбирает все предложения, включая одинаковые регионы.
	for n in 6:
		if base._op_sel == 1:
			break
		await MetaTest._cycle_button(tree, JOY_BUTTON_DPAD_DOWN)
	assert(base._op_sel == 1)
	assert(Campaign.offers()[1]["type"] == "extract")
	base._globe.skip_motion()
	await shot(tree, "brief_extract")
	Meta.campaign = CampaignRules.initial(20261017)
	Meta.campaign = CampaignRules.advance(Meta.campaign, Meta.campaign["offers"][2], "victory")["world"]
	assert(Meta.campaign["phase"] == "victory")
	base._open_operations()
	await shot(tree, "victory")
	await MetaTest._cycle_button(tree, JOY_BUTTON_A)
	assert(Meta.campaign["phase"] == "free")
	var before := Meta.to_dict()
	for id: String in CampaignCatalog.KEY_REGIONS.slice(0, 3):
		Meta.campaign["regions"][id]["infection"] = 85
	Meta.campaign["phase"] = "active"
	Meta.campaign["phase"] = CampaignRules.phase(Meta.campaign)
	Meta.campaign["offers"] = CampaignDirector.generate(Meta.campaign)
	base._open_operations()
	await shot(tree, "defeat")
	await MetaTest._cycle_button(tree, JOY_BUTTON_A)
	assert(Meta.campaign["phase"] == "active" and Meta.campaign["turn"] == 0)
	var after := Meta.to_dict()
	before.erase("campaign")
	after.erase("campaign")
	assert(before == after)
	print("C6CAPTURE shots=5 pad_offers=true victory_continue=true defeat_restart=true profile_preserved=true")
	Meta.finish_test()
