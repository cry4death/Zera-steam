extends GdUnitTestSuite
## NP1: давление орды растёт с потерей HP узла, пороги срабатывают по разу, спад медленный.

const DT := 1.0 / 60.0

var _snapshot: Dictionary
var _persist: bool
var _game: Node2D
var _paused: bool
var _time_scale: float


func before_test() -> void:
	_paused = get_tree().paused
	_time_scale = Engine.time_scale
	_snapshot = Meta.to_dict().duplicate(true)
	_persist = Meta.persist
	Meta.persist = false


func after_test() -> void:
	if _game:
		_game.free()
		_game = null
	get_tree().paused = _paused
	Engine.time_scale = _time_scale
	Meta.from_dict(_snapshot)
	Meta.persist = _persist


func _node(hp := 1000.0) -> CampaignNode:
	var node := CampaignNode.new()
	node.max_hp = hp
	add_child(node)
	node.start(Vector2(400, 300))
	return auto_free(node)


func _run(node: CampaignNode, seconds: float) -> void:
	for step in int(seconds / DT):
		node.tick(DT)


func _hit(node: CampaignNode, to_fraction: float) -> void:
	node.take_damage(maxf(0.0, node.hp - node.max_hp * to_fraction), Vector2.UP, node.global_position)


func test_pressure_formula_grows_with_lost_hp() -> void:
	for excitement in [0.0, 0.5, 1.0]:
		var previous := 0.0
		for k in 101:
			var value := CampaignNode.pressure_for(1.0 - float(k) / 100.0, excitement)
			assert_float(value).is_greater_equal(previous)
			previous = value
	assert_float(CampaignNode.pressure_for(1.0, 0.0)).is_equal(1.0)
	# К концу узла давление в 1,8–2,2 раза выше опорного.
	assert_float(CampaignNode.pressure_for(0.0, 1.0)).is_between(1.8, 2.2)
	# Бюджет орды растёт вместе с давлением: темп, лимит и доля бегунов не убывают.
	var row_before := Spawner.node_row(1.0)
	for k in 12:
		var row := Spawner.node_row(1.0 + float(k) * 0.1)
		assert_float(float(row[1])).is_greater_equal(float(row_before[1]))
		assert_int(int(row[2])).is_greater_equal(int(row_before[2]))
		assert_int(int(row[3][1])).is_greater_equal(int(row_before[3][1]))
		assert_int(int(row[3][0]) + int(row[3][1]) + int(row[3][2]) + int(row[3][3])).is_between(95, 100)
		row_before = row
	var end_rate := float(Spawner.node_row(2.1)[1]) / float(Spawner.node_row(1.0)[1])
	assert_float(end_rate).is_between(1.8, 2.2)


func test_running_pressure_is_monotonic_while_hp_falls() -> void:
	var node := _node()
	var previous := node.pressure
	for percent in range(99, -1, -1):
		node.take_damage(node.max_hp * 0.01, Vector2.UP, node.global_position)
		_run(node, 0.7)
		if percent > 0:
			assert_float(node.pressure).is_greater_equal(previous - 0.000001)
			previous = node.pressure
	assert_float(previous).is_greater(1.9)


func test_thresholds_fire_once_each() -> void:
	var node := _node()
	var started := {"steps": [], "released": []}
	node.call_started.connect(func(step: int) -> void: started["steps"].append(step))
	node.call_released.connect(func(step: int) -> void: started["released"].append(step))
	_run(node, 5.0)
	assert_array(started["steps"]).is_empty()
	_hit(node, 0.76)
	_run(node, 5.0)
	assert_array(started["steps"]).is_empty()
	_hit(node, 0.74)
	_run(node, 0.5)
	assert_array(started["steps"]).is_equal([1])
	assert_float(node.call_left).is_greater(0.0)
	_run(node, CampaignNode.CALL_WARNING)
	assert_array(started["released"]).is_equal([1])
	# Дальнейшие удары выше следующего порога зов не повторяют.
	_hit(node, 0.55)
	_run(node, 10.0)
	assert_array(started["steps"]).is_equal([1])
	_hit(node, 0.45)
	_run(node, 6.0)
	_hit(node, 0.2)
	_run(node, 12.0)
	assert_array(started["steps"]).is_equal([1, 2, 3])
	assert_array(started["released"]).is_equal([1, 2, 3])
	_hit(node, 0.1)
	_run(node, 20.0)
	assert_int(node.steps).is_equal(3)
	assert_array(started["steps"]).is_equal([1, 2, 3])


func test_one_big_hit_makes_calls_in_turn_not_at_once() -> void:
	var node := _node()
	var log := {"started": [], "released": []}
	node.call_started.connect(func(step: int) -> void: log["started"].append(step))
	node.call_released.connect(func(step: int) -> void: log["released"].append(step))
	_hit(node, 0.2)
	_run(node, 0.1)
	# Три порога разом: идёт только один зов, остальные ждут своей очереди.
	assert_array(log["started"]).is_equal([1])
	_run(node, 30.0)
	assert_array(log["started"]).is_equal([1, 2, 3])
	assert_array(log["released"]).is_equal([1, 2, 3])


func test_pressure_falls_slowly_when_player_backs_off() -> void:
	var node := _node(10000.0)
	_hit(node, 0.6)
	node.agitation = 1.0
	_run(node, 6.0)
	var peak := node.pressure
	assert_float(peak).is_greater(1.5)
	var floor_value := CampaignNode.pressure_for(0.6, 0.0)
	# Десять секунд без стрельбы почти не снимают давление.
	_run(node, 10.0)
	assert_float(peak - node.pressure).is_less(0.06)
	assert_float(node.pressure).is_greater(floor_value)
	# Рост быстрее спада в разы: тот же прирост набирается за доли времени спада.
	var rise_time := 0.25 / CampaignNode.RISE
	var fall_time := 0.25 / CampaignNode.FALL
	assert_float(fall_time).is_greater(rise_time * 10.0)
	# Но давление от потерянного HP остаётся навсегда: отойти и вернуться нельзя.
	_run(node, 240.0)
	assert_float(node.pressure).is_equal_approx(floor_value, 0.001)
	assert_float(node.pressure).is_greater(1.3)


func test_bite_only_on_last_quarter_and_with_warning() -> void:
	var game := await _integration_game()
	var node: CampaignNode = game.boss
	var bites := {"windup": 0, "launched": 0}
	node.bite_started.connect(func() -> void: bites["windup"] += 1)
	node.bite_launched.connect(func() -> void: bites["launched"] += 1)
	game.player.position = node.global_position + Vector2(0, 150)
	game.player.god_mode = true
	node.max_hp = 10000.0
	node.start(node.global_position)
	_hit(node, 0.5)
	_run(node, 30.0)
	assert_int(bites["windup"]).is_equal(0)
	assert_int(node.steps).is_equal(2)
	_hit(node, 0.24)
	_run(node, 4.0)
	assert_int(node.steps).is_equal(3)
	var shots: int = game.hazards.projectile_count()
	_run(node, 12.0)
	# Сначала замах (с предупреждением), потом три плевка; затем пауза до следующего.
	assert_int(bites["windup"]).is_greater(0)
	assert_int(bites["launched"]).is_greater(0)
	assert_int(bites["launched"]).is_less_equal(bites["windup"])
	assert_int(game.hazards.projectile_count() + game.hazards.pool_count()).is_greater(shots)
	assert_float(CampaignNode.BITE_WINDUP).is_greater(0.5)
	assert_float(float(CampaignNode.BITE_PERIOD[1])).is_greater(3.0)


func test_node_pressure_drives_spawner_and_clears_when_destroyed() -> void:
	var game := await _integration_game()
	var node: CampaignNode = game.boss
	var spawner: Spawner = game.spawner
	var objective: CampaignObjective = game.objective
	assert_float(spawner.node_pressure).is_equal(1.0)
	var base_rate := spawner.current_rate()
	node.max_hp = 10000.0
	node.start(node.global_position)
	_hit(node, 0.4)
	_run(node, 6.0)
	objective._physics_process(DT)
	assert_float(spawner.node_pressure).is_equal_approx(node.pressure, 0.0001)
	assert_float(spawner.current_rate()).is_greater(base_rate * 1.4)
	# Всплеск зова: порция орды в пределах лимита, не пустая.
	game.horde.count = 0
	game.horde._rebuild_grid()
	var calls_before := spawner.node_calls
	spawner.node_call_prepare(node.global_position, CampaignNode.CALL_WARNING)
	assert_float(spawner.node_call_left).is_greater(0.0)
	var before: int = game.horde.count
	var made := spawner.node_call(2)
	assert_int(made).is_greater(10)
	assert_int(game.horde.count).is_equal(before + made)
	assert_int(spawner.node_calls).is_equal(calls_before + 1)
	# Разрушение узла снимает давление и возвращает обычную строку кривой.
	node.take_damage(node.max_hp, Vector2.UP, node.global_position)
	assert_float(node.pressure).is_equal(0.0)
	assert_float(spawner.node_pressure).is_equal(0.0)
	assert_bool(spawner._objective_row.is_empty()).is_true()
	assert_float(node.call_left).is_equal(0.0)
	# Даём штатному переходу операции дойти до рапорта, пока сцена жива.
	await get_tree().create_timer(1.6).timeout
	print("NP1_TEST thresholds=once decay=slow bite=last_quarter cleared=true")


func _integration_game() -> Node2D:
	Meta.reset()
	var world := Meta.campaign
	Meta.campaign["pending_operation"] = CampaignRules.mission(world, world["offers"][0], 0)
	_game = load("res://scenes/main.tscn").instantiate()
	_game.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_game)
	_game.objective._physics_process(0.0)
	_game.horde.count = 0
	_game.horde._rebuild_grid()
	_game.weapons.effects = null
	_game.boss.effects = null
	seed(20261017)
	await get_tree().process_frame
	return _game
