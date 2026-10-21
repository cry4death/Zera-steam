extends Node
## Оконный стенд: 25 кадров с шагом 1 с, одинаковый сценарий до и после.


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	var root := get_tree().root
	root.add_child(game)
	game._director_freeze()
	game.time = 300.0
	game.horde.far_distance = 5000.0
	var suffix := "after"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-label="):
			suffix = arg.trim_prefix("--capture-label=")
	for pattern in [HordeDirector.Pattern.PINCER, HordeDirector.Pattern.COLUMN, HordeDirector.Pattern.RING, HordeDirector.Pattern.FLANK]:
		var data := MapLoader.load_map(game._map_id)
		var start: Vector2 = game.obstacles.free_point(data["start"] + Vector2(160, 80), 32.0)
		game.player.position = start
		game.camera.position = start
		game.camera.force_update_scroll()
		for warm in 40:
			game.obstacles.navigation_step(0.2, start)
		game.horde.count = 0
		game.horde.release_groups()
		game.horde.reset_variety_seed(81073)
		seed(81073)
		var director := HordeDirector.new()
		director.setup(game.horde, game.player, 81073, game._map_id)
		game.spawner.director = director
		director.force_pattern(pattern, 0.0, 300.0)
		director.spawn_group(80, [100, 0, 0, 0], false, 303.0)
		# Сбрасываем отрисовку предыдущего узора до первого кадра новой серии.
		game.horde._render()
		game.horde.queue_redraw()
		var sheet := Image.create(1600, 900, false, Image.FORMAT_RGB8)
		var closest := INF
		for second in 25:
			if second > 0:
				for frame in 60:
					var age := float((second - 1) * 60 + frame) / 60.0
					var want := start + Vector2(sin(age * 0.22) * 90.0, sin(age * 0.16) * 70.0)
					game.player.position = game.obstacles.move_actor(game.player.position, want, Player.RADIUS)
					game.obstacles.navigation_step(1.0 / 60.0, game.player.position)
					game.horde._physics_process(1.0 / 60.0)
					if frame % 10 == 9:
						await get_tree().process_frame
			game.camera.position = game.player.position
			game.camera.force_update_scroll()
			await RenderingServer.frame_post_draw
			var shot := root.get_texture().get_image()
			shot.resize(320, 180, Image.INTERPOLATE_NEAREST)
			sheet.blit_rect(shot, Rect2i(0, 0, 320, 180), Vector2i(second % 5 * 320, second / 5 * 180))
			for i in game.horde.count:
				closest = minf(closest, game.horde.pos[i].distance_to(game.player.position))
		var path := "res://design/tasks/reports/pt1b_%s_%s_seq_%s.png" % [HordeDirector.NAMES[pattern], game._map_id, suffix]
		sheet.save_png(path)
		print("DIRECTORCAPTURE map=%s pattern=%s frames=25 step=1s closest=%.2f path=%s" % [game._map_id, HordeDirector.NAMES[pattern], closest, path])
	get_tree().quit()
