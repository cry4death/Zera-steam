class_name CampaignCombatTest
extends RefCounted
## Бот проходит настоящую сетку и стреляет обычным оружием; цель не подменяется.


static func route(obstacles: Obstacles, from: Vector2, to: Vector2) -> PackedVector2Array:
	var first := obstacles.cell_at(from)
	var last := obstacles.cell_at(to)
	var previous := PackedInt32Array()
	previous.resize(obstacles.blocked.size())
	previous.fill(-1)
	var queue := PackedInt32Array([first])
	previous[first] = first
	var read := 0
	while read < queue.size() and previous[last] < 0:
		var c := queue[read]
		read += 1
		for other: int in [c - 1, c + 1, c - obstacles.grid_w, c + obstacles.grid_w]:
			if other < 0 or other >= previous.size() or absi(other % obstacles.grid_w - c % obstacles.grid_w) > 1:
				continue
			if previous[other] < 0 and obstacles.blocked[other] == 0:
				previous[other] = c
				queue.append(other)
	var points := PackedVector2Array()
	if previous[last] < 0:
		return points
	var c := last
	while c != first:
		points.append(obstacles.cell_center(c))
		c = previous[c]
	points.reverse()
	points.append(to)
	return points


static func run(game: Node) -> void:
	var tree := game.get_tree()
	if game.objective == null or Campaign.pending().is_empty():
		push_error("C6TEST: нужен --campaign-op=clearance или extract")
		return
	var objective: CampaignObjective = game.objective
	game.player.god_mode = true
	game._full_loadout()
	Engine.time_scale = 12.0
	Engine.max_physics_steps_per_frame = 32
	var goal := Vector2.INF
	var points := PackedVector2Array()
	var index := 0
	var screenshot := false
	var departed := false
	var paused_hold := -1.0
	var checked_pause := false
	var pad := OS.get_cmdline_user_args().has("--c6-pad")
	if pad:
		Engine.time_scale = 4.0
	var fail_after_pickup := OS.get_cmdline_user_args().has("--c6-fail")
	var old_runs := Meta.runs
	var old_turn := int(Meta.campaign["turn"])
	var wall_start := Time.get_ticks_msec()
	while not game.results.visible and game.time < 780.0:
		await tree.physics_frame
		if Time.get_ticks_msec() - wall_start > 240000:
			push_error("C6TEST: превышено время бота")
			return
		var desired := objective.target + Vector2(0, 15 if objective.picked else 25) if objective.type == "extract" else objective.target + Vector2(0, 65)
		if desired != goal:
			goal = desired
			points = route(game.obstacles, game.player.position, goal)
			index = 0
			assert(not points.is_empty(), "C6TEST: нет пути бота")
		if index < points.size():
			if game.player.position.distance_to(points[index]) < 7.0:
				index += 1
			if index < points.size():
				game.player.autopilot = true
				game.player.auto_target = points[index]
		else:
			game.player.autopilot = false
		if pad:
			game.player.autopilot = false
			stick((points[index] - game.player.position).normalized() if index < points.size() else Vector2.ZERO)
		if fail_after_pickup and objective.picked and not game.player.is_dead:
			game.player.god_mode = false
			game.player._iframes = 0.0
			game.player.take_damage(99999.0)
		# Проверяем, что выход из зоны действительно останавливает погрузку.
		if objective.type == "extract" and objective.picked and objective.hold > 5.0 and not departed:
			departed = true
			paused_hold = objective.hold
			goal = Vector2.INF
			game.player.position = game.obstacles.free_point(objective.exit_point + Vector2(100, 0), 10.0)
			game.player.autopilot = false
			stick(Vector2.ZERO)
			await tree.create_timer(2.0).timeout
			checked_pause = is_equal_approx(objective.hold, paused_hold)
			assert(checked_pause, "C6TEST: удержание вне зоны")
		if not screenshot and ((objective.type == "extract" and objective.hold > 8.0 and game.time - objective.guard_stamp < 0.3) or (objective.type != "extract" and objective.spawned and game.boss.hp < game.boss.max_hp * 0.9)):
			screenshot = true
			if OS.get_cmdline_user_args().has("--c6-shots"):
				await CampaignCapture.shot(tree, "extract" if objective.type == "extract" else "node")
	print("C6BOT time=%.2f pos=%s goal=%s waypoint=%d/%d picked=%s results=%s dead=%s" % [game.time, game.player.position, goal, index, points.size(), objective.picked, game.results.visible, game.player.is_dead])
	assert(game.results.visible and game.results._stats["victory"] == (not fail_after_pickup), "C6TEST: неправильный исход")
	assert(Meta.runs == old_runs + 1 and int(Meta.campaign["turn"]) == old_turn + 1)
	var snapshot := Meta.to_dict()
	game.results.open(game._result_stats(not fail_after_pickup))
	assert(Meta.to_dict() == snapshot, "C6TEST: повторная награда")
	assert(objective.type != "extract" or (objective.picked and (checked_pause or fail_after_pickup)))
	print("C6TEST type=%s victory=%s time=%.2f picked=%s hold=%.2f node_hp=%.0f once=true pause_outside=%s" % [objective.type, not fail_after_pickup, game.time, objective.picked, objective.hold, game.boss.hp, checked_pause])
	stick(Vector2.ZERO)
	await tree.create_timer(0.3, true).timeout
	await MetaTest._cycle_button(tree, JOY_BUTTON_B)
	await MetaTest._cycle_button(tree, JOY_BUTTON_B)
	await tree.create_timer(0.3, true).timeout
	assert(tree.current_scene.scene_file_path == "res://scenes/base.tscn" and Campaign.pending().is_empty())
	print("C6TEST pad_movement=%s pad_return=true" % pad)
	Meta.finish_test()


static func stick(direction: Vector2) -> void:
	for axis: int in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var event := InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = direction.x if axis == JOY_AXIS_LEFT_X else direction.y
		Input.parse_input_event(event)
	Input.flush_buffered_events()
