extends Node
## Оконный стенд NP1: кадры боя у узла при 100 / 50 / 20 % HP, зов и плевок. HP держим на метке.
## Запуск: res://tests/campaign/node_pressure_capture.tscn -- --fresh-save --campaign-op=clearance

const SHOTS := "res://design/tasks/reports/"


func _ready() -> void:
	_run.call_deferred()


func _pin(game: Node2D, fraction: float) -> void:
	var node: CampaignNode = game.boss
	node.hp = node.max_hp * fraction
	node.agitation = 1.0


func _snap(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_tree().root.get_texture().get_image()
	image.save_png(SHOTS + name + ".png")
	print("NP1SHOT ", name)


func _run() -> void:
	seed(20261017)
	var game: Node2D = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().create_timer(0.5).timeout
	get_tree().root.size = Vector2i(1280, 720)
	var node: CampaignNode = game.boss
	game.player.god_mode = true
	game.player.autopilot = true
	game.gems.collected.disconnect(game.progression.add_xp) # без меню уровня посреди кадра
	game.mission_banner_t = 0.0
	game.get_node("HUD/Hud").show_debug = false
	var taken := {}
	Engine.time_scale = 2.0
	# Бот стоит рядом с узлом и стреляет по орде; HP узла закреплено на метке этапа.
	var stage := [[1.0, 14.0, "np1_hp100"], [0.5, 24.0, "np1_hp50"], [0.2, 40.0, "np1_hp20"]]
	for entry: Array in stage:
		var fraction: float = entry[0]
		if fraction < 1.0:
			node.take_damage(node.hp - node.max_hp * fraction, Vector2.UP, node.global_position)
		var left: float = entry[1]
		while left > 0.0:
			await get_tree().physics_frame
			left -= get_physics_process_delta_time() * Engine.time_scale
			_pin(game, fraction)
			game.player.hp = game.player.max_hp
			game.player.auto_target = node.global_position + Vector2(40, 120)
			var tag := "np1_call_%d" % int(fraction * 100.0)
			if node.call_left > 0.5 and node.call_left < 0.9 and not taken.has(tag) and fraction < 1.0:
				taken[tag] = true
				await _snap(tag)
			if node.windup_left > 0.2 and node.windup_left < 0.5 and not taken.has("np1_bite"):
				taken["np1_bite"] = true
				await _snap("np1_bite")
			if not node._marks.is_empty() and node._mark_age[0] > 0.3 and not taken.has("np1_marks"):
				taken["np1_marks"] = true
				await _snap("np1_marks")
		await _snap(entry[2])
	Engine.time_scale = 1.0
	get_tree().quit()
