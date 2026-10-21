extends GdUnitTestSuite
## Совпавшие точки атаки не должны портить координаты босса.

const ARENA := Rect2(0, 0, 2560, 1440)
const CENTER := Vector2(1280, 720)
const GameScript = preload("res://scripts/game.gd")


func _boss(kind: int) -> Boss:
	var b: Boss
	match kind:
		1, 2:
			var hive := BossHive.new()
			hive.hive = BossHive.Hive.MOTHER if kind == 1 else BossHive.Hive.MEAT
			b = hive
		3:
			b = BossGeneral.new()
		4:
			b = BossHeart.new()
		_:
			b = Boss.new()
	var target := Player.new()
	auto_free(target)
	auto_free(b)
	target.god_mode = true
	target.position = CENTER
	b.player = target
	b.arena = ARENA
	b.start(CENTER)
	return b


func test_coincident_target_and_zero_length_charge() -> void:
	for kind in [0, 2, 3]:
		var b := _boss(kind)
		if b is BossHive:
			b._begin_roll()
			assert_vector(b._roll_to).is_equal(CENTER)
		elif b is BossGeneral:
			b._begin_shield_charge()
			assert_vector(b._charge_target).is_equal(CENTER)
		else:
			# На краю арены пролёт в прежнем направлении имеет нулевую длину.
			b.position.x = ARENA.end.x - Boss.RADIUS
			b.player.position = b.position
			b._begin_charge_series()
			assert_vector(b._charge_target).is_equal(b.position)
		for frame in 120:
			b._physics_process(1.0 / 60.0)
			assert_bool(b.global_position.is_finite()).is_true()
			assert_bool(b._facing.is_finite()).is_true()


func test_explosion_at_center_of_every_boss() -> void:
	var weapons := Weapons.new()
	var horde := Horde.new()
	auto_free(weapons)
	auto_free(horde)
	weapons.horde = horde
	for kind in 5:
		var b := _boss(kind)
		weapons.boss = b
		weapons._boss_active = true
		var hp_before := b.hp
		weapons.explode(b.global_position, 100.0, 100.0)
		assert_float(b.hp).is_less(hp_before)
		assert_vector(b.global_position).is_equal(CENTER)
		assert_bool(b._facing.is_finite()).is_true()


func test_spawn_and_coincident_charge_with_map_obstacles() -> void:
	# Настоящая сцена проверяет и глобальный трансформ, и спавн от камеры.
	var game: GameScript = load("res://scenes/main.tscn").instantiate()
	auto_free(game)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(game)
	game.player.god_mode = true
	var original_boss := game.boss
	for map_id in ["quarantine_checkpoint", "military_airfield", "cargo_port", "residential_district"]:
		var data := MapLoader.load_map(map_id)
		var arena := Rect2(Vector2.ZERO, data["size"])
		game.obstacles.setup(arena, MapLoader.layout(data, 81073))
		game.player.arena = arena
		for kind in 5:
			var b := _boss(kind)
			game.get_node("World").add_child(b)
			b.player = game.player
			b.arena = arena
			b.obstacles = game.obstacles
			b.camera = game.camera
			game.boss = b
			for direction in [Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN, Vector2.ONE.normalized()]:
				game.player.position = game.obstacles.free_point(data["start"], Player.RADIUS)
				game.player.facing = direction
				game.camera.setup(arena, game.player)
				game.time = 600.0
				game._boss_spawned = false
				game._boss_warned = true
				game._boss_timeline()
				assert_bool(b.is_alive()).is_true()
				assert_bool(b.global_position.is_finite()).is_true()
				assert_bool(b.global_position.distance_to(game.player.global_position) < 10000.0).is_true()
				# Совпавшая цель после разрешения коллизий, включая тело у стены.
				game.player.position = b.global_position
				if b is BossHive and b.hive == BossHive.Hive.MEAT:
					b._begin_roll()
				elif b is BossGeneral:
					b._begin_shield_charge()
				elif kind == 0:
					b._begin_charge_series()
				for frame in 120:
					b._physics_process(1.0 / 60.0)
					assert_bool(b.global_position.is_finite()).is_true()
					assert_bool(b._facing.is_finite()).is_true()
			b._alive = false
			b.visible = false
	# Остальные системы сцены по-прежнему ссылаются на её исходного босса.
	game.boss = original_boss
