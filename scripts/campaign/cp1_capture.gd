class_name CP1Capture
extends RefCounted
## Воспроизводимый обзор кампании; профиль только в памяти.


static func shot(base: Control, state: Dictionary, slot: int, label: String, journal: bool = false) -> void:
	var tree := base.get_tree()
	Meta.campaign = state.duplicate(true)
	base._open_operations()
	base._select_operation(slot)
	base._globe.skip_motion()
	await tree.create_timer(0.4).timeout
	if journal:
		base._click("op_journal")
		await tree.process_frame
	await RenderingServer.frame_post_draw
	var path := "res://design/tasks/reports/cp1_%s.png" % label
	assert(tree.root.get_texture().get_image().save_png(path) == OK)
	print("CP1SHOT " + path)


static func run(base: Control) -> void:
	var tree := base.get_tree()
	Meta.persist = false
	Meta.reset()
	tree.root.mode = Window.MODE_WINDOWED
	tree.root.size = Vector2i(1920, 1080)
	var state := CampaignRules.initial(20261017)
	var captured_assault := false
	for turn in 18:
		if state["phase"] in ["victory", "defeat"]:
			break
		if turn == 2:
			await shot(base, state, 2, "globe_after")
		if turn == 4:
			await shot(base, state, 1, "briefing")
			await shot(base, state, 1, "forecast", true)
			await shot(base, state, 0, "outposts")
			await shot(base, state, 1, "samples")
			await shot(base, state, 2, "history")
			tree.root.size = Vector2i(1280, 720)
			await shot(base, state, 2, "720p")
			tree.root.size = Vector2i(1920, 1080)
		if state["war"]["assault_unlocked"] and not captured_assault:
			captured_assault = true
			await shot(base, state, 2, "assault")
		var op := CP1Test.choose(state)
		var old := CampaignRules.average(state)
		state = CampaignRules.advance(state, op, "victory")["world"]
		print("CP1TURN %d choice=%s:%s average=%.2f->%.2f outposts=%d samples=%d unlocked=%s lost=%d phase=%s" % [turn + 1, op["region_id"], op["type"], old, CampaignRules.average(state), state["war"]["outposts"].size(), state["war"]["samples"].size(), state["war"]["assault_unlocked"], CampaignRules.lost_keys(state), state["phase"]])
	await shot(base, state, 0, "victory")
	state = CampaignRules.initial(20261017)
	for turn in 2:
		state = CampaignRules.advance(state, state["offers"][0], "victory")["world"]
	await shot(base, state, 2, "front")
	state = CampaignRules.initial(20261017)
	var captured_risk := false
	for turn in 12:
		if CampaignRules.lost_keys(state) == 2 and not captured_risk:
			await shot(base, state, 1, "risk")
			captured_risk = true
		state = CampaignRules.advance(state, state["offers"][0], "defeat")["world"]
		if state["phase"] == "defeat":
			break
	await shot(base, state, 0, "defeat")
	print("CP1CAPTURE complete=true viewport=true profile_untouched=true")
	tree.quit()
