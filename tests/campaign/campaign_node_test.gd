extends GdUnitTestSuite
## PT1a: видимая цель первой операции принимает оружие и занимает место в общей сетке.

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


func after_test() -> void:
	_game.free()
	# Экран победы ставит всё дерево на паузу; не оставляем её следующему тесту.
	get_tree().paused = _paused
	Engine.time_scale = _time_scale
	Meta.from_dict(_snapshot)
	Meta.persist = _persist


func test_first_operation_damage_collision_and_victory() -> void:
	var node: CampaignNode = _game.boss
	var walls: Obstacles = _game.obstacles
	var guns: Weapons = _game.weapons
	var at := node.global_position
	assert_str(_game.objective.type).is_equal("clearance")
	assert_float(_game.time).is_equal(0.0)
	assert_bool(node.is_alive()).is_true()
	assert_bool(_game.objective.spawned).is_true()
	assert_str(node.display_name()).is_equal("Узел заражения")
	assert_bool(walls.contains(at, Player.RADIUS)).is_true()
	assert_bool(walls.line_clear(at + Vector2(0, 80), at)).is_true()
	var revision := walls.nav_revision
	for dir: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		for radius: float in [Player.RADIUS, 4.6, 5.4, 7.95]:
			var from := at + dir * 80.0
			var to := at - dir * 80.0
			var stopped := walls.move_actor(from, to, radius)
			assert_float((stopped - at).dot(dir)).is_greater_equal(node.body_radius() + radius)
			assert_bool(walls.body_clear(from, to, radius)).is_false()
			var path := walls.body_path(from, to, radius)
			assert_bool(path.is_empty()).is_false()
			var previous := from
			for point: Vector2 in path:
				assert_bool(walls.body_clear(previous, point, radius)).is_true()
				previous = point

	# Настоящий выстрел каждого класса, затем штатные шаги полёта и взрыва.
	_game.player.position = at + Vector2(0, 40)
	guns._boss_active = true
	assert_int(guns._nearest_target(_game.player.position, 150.0)).is_equal(Weapons.BOSS_TARGET)
	for base in WeaponDefs.BASES.size():
		guns.clear_projectiles()
		guns.slots.clear()
		guns.add_weapon(base)
		var slot: Weapons.Slot = guns.slots[0]
		slot.angle = -PI * 0.5
		node.hp = node.max_hp
		guns._fire_shot(0, slot, Weapons.BOSS_TARGET)
		for tick in 120:
			guns._update_bullets(1.0 / 60.0)
			guns._update_grenades(1.0 / 60.0)
			guns._update_stuck(1.0 / 60.0)
		assert_float(node.hp).override_failure_message("Урон класса %d не дошёл до узла" % base).is_less(node.max_hp)
		assert_float(node._flash).is_greater(0.0)
		if base == WeaponDefs.Base.FLAMER:
			var before_fire := node.hp
			guns._update_boss_fire(0.5)
			assert_float(node.hp).is_less(before_fire)
			assert_float(float(guns.boss_sources.get("fire", 0.0))).is_greater(0.0)

	var before_grenade := node.hp
	guns.explode(at, 100.0, 50.0)
	assert_float(node.hp).is_less(before_grenade)
	assert_float(float(guns.boss_sources.get("grenade", 0.0))).is_greater(0.0)
	assert_float(float(guns.boss_sources.get("explosion", 0.0))).is_greater(0.0)
	assert_bool(node.take_damage(node.max_hp, Vector2.UP, at)).is_true()
	assert_bool(node.is_alive()).is_false()
	assert_bool(node.hit_test(at, 1.0)).is_false()
	assert_bool(_game.game_over).is_true()
	assert_bool(_game.objective.done).is_true()
	assert_bool(walls.contains(at, Player.RADIUS)).is_false()
	assert_bool(walls.body_clear(at + Vector2(0, 80), at - Vector2(0, 80), Player.RADIUS)).is_true()
	assert_int(walls.nav_revision).is_greater(revision)
	assert_bool(node.take_damage(1.0, Vector2.UP, at)).is_false()
	# Даём настоящему переходу операции открыть рапорт; повторной награды нет.
	await get_tree().create_timer(1.6).timeout
	assert_bool(_game.results.visible).is_true()
	assert_bool(_game.results._stats["victory"]).is_true()
	assert_int(Meta.runs).is_equal(1)
	print("PT1A_TEST classes=16 bullet=true explosion=true fire=true collision_player_horde=true navigation=true victory=true")
