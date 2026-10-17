extends SceneTree

var checks := 0
var failures := 0
var events: Array[String] = []
var deaths: Array[int] = []
var touches: Array[float] = []
var shots: Array[Vector2] = []
var shot_damage: Array[float] = []

func _initialize() -> void:
	_run.call_deferred()

func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	seed(12345)
	var game := load("res://scenes/main.tscn").instantiate() as Node2D
	root.add_child(game)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var h: Horde = game.get_node("World/Horde")
	var p: Player = game.get_node("World/Player")
	h.floor_decals = null
	h.far_distance = 600.0
	h.spawn_ring = 380.0
	h.minutes = 2.0
	for k in Horde.Kind.size():
		for e in 2:
			var i := h.spawn(p.position + Vector2(200.0 + k * 20.0, e * 30.0), k, e == 1)
			verify(i == k * 2 + e, "spawn index")
			verify(h.kind[i] == k and h.elite[i] == e, "type/elite arrays")
			verify(is_equal_approx(h.hp[i], Horde.KINDS[k]["hp"] * 1.24 * (5.0 if e == 1 else 1.0)), "scaled hp")
			verify(is_equal_approx(h.radius[i], 7.5 if e == 1 else 5.0), "scaled radius")
			verify(h.variant[i] < 4 if k == 0 else h.variant[i] == k + 3, "atlas variant")
			var base: float = Horde.KINDS[k]["speed"] * (1.1 if e == 1 else 1.0)
			verify(h.speed[i] >= base * (0.95 if k == Horde.Kind.RUNNER else 0.85) - 0.001 and h.speed[i] <= base * 1.2, "speed range")
			if k == Horde.Kind.RUNNER:
				verify(h.speed[i] > p.move_speed, "runner outruns player")
	var saved_count := h.count
	h.count = Horde.MAX_ENEMIES
	verify(h.spawn(Vector2.ZERO) == -1 and h.count == Horde.MAX_ENEMIES, "spawn cap")
	h.count = saved_count
	h.damage(4, 1.0, Vector2.RIGHT, 100.0)
	verify(is_equal_approx(h.knock[4].x, 30.0), "fat knockback x0.3")
	h.touch_cd[7] = 0.42
	h.spit_cd[7] = 1.23
	h.spit_windup[7] = 0.25
	var last_uid := h.uid[7]
	h.dead[0] = 1
	h._compact()
	verify(h.count == 7 and h.uid[0] == last_uid and h.kind[0] == Horde.Kind.SPITTER and h.elite[0] == 1, "compact identity")
	verify(is_equal_approx(h.touch_cd[0], 0.42) and is_equal_approx(h.spit_cd[0], 1.23) and is_equal_approx(h.spit_windup[0], 0.25), "compact timers")
	h.count = 0
	var elite_i := h.spawn(Vector2(400.0, 400.0), Horde.Kind.SHAMBLER, true)
	h._rebuild_grid()
	verify(h.find_hit(Vector2(407.0, 400.0), 0.0) == elite_i, "elite hit edge")
	verify(h.find_hit(Vector2(408.0, 400.0), 0.0) == -1, "elite hit outside")
	verify(h.query_radius(Vector2(417.0, 400.0), 10.0).has(elite_i), "elite radius query edge")
	verify(not h.query_radius(Vector2(418.0, 400.0), 10.0).has(elite_i), "elite radius query outside")
	h.spawn(Vector2(411.0, 400.0))
	h._rebuild_grid()
	h._separate()
	verify(h.pos[0].distance_to(h.pos[1]) >= 12.49, "elite separation sum of radii")
	h._render()
	verify(is_equal_approx(h._buf[12], 1.5) and h._buf[20] >= 8.0, "elite scale and +8 flag rendered last")
	h.enemy_killed.connect(func(_pos: Vector2, _dir: Vector2, death: int, _face: float, _v: int) -> void:
		events.append("killed")
		deaths.append(death))
	h.enemy_died.connect(func(_pos: Vector2, _k: int, _e: bool) -> void: events.append("died"))
	h.fat_burst.connect(func(_pos: Vector2, _e: bool) -> void: events.append("fat"))
	for ammo in WeaponDefs.Ammo.size():
		h.count = 0
		events.clear()
		var i := h.spawn(p.position + Vector2(80.0, 0.0), Horde.Kind.FAT, true)
		h.freeze_t[i] = 1.0
		h.death_override = Gore.Death.ICE
		h.damage(i, 9999.0, Vector2.ZERO, 0.0, ammo)
		verify(events == ["killed", "died", "fat"] and deaths.back() == Gore.Death.GIBS, "fat signal order/death for ammo %d" % ammo)
		h.damage(i, 9999.0, Vector2.ZERO, 0.0, ammo)
		verify(events.size() == 3, "fat only dies once")
	h.death_override = -1
	h.count = 0
	h.minutes = 0.0
	h.player_touched.connect(func(damage: float) -> void: touches.append(damage))
	for k in Horde.Kind.size():
		var i := h.spawn(p.position + Vector2(10.0, 0.0), k, k == Horde.Kind.FAT)
		h.speed[i] = 0.0
	h._move(0.0)
	verify(touches.size() == 1 and is_equal_approx(touches[0], 13.0), "one max contact signal")
	h._move(0.4)
	verify(touches.size() == 1, "contact cooldown at 0.4")
	h._move(0.41)
	verify(touches.size() == 2, "contact cooldown at 0.81")
	for i in h.count:
		h.freeze_t[i] = 1.0
		h.touch_cd[i] = 0.0
	h._move(0.1)
	verify(touches.size() == 2, "frozen cannot hit")
	h.count = 0
	h.minutes = 2.0
	h.spit_fired.connect(func(_from: Vector2, to: Vector2, damage: float) -> void:
		shots.append(to)
		shot_damage.append(damage))
	var sp := h.spawn(p.position + Vector2(150.0, 0.0), Horde.Kind.SPITTER, true)
	h.spit_cd[sp] = 0.0
	var before := h.pos[sp]
	h._move(0.01)
	verify(shots.is_empty() and h.spit_windup[sp] > 0.0, "spitter windup")
	h._move(0.29)
	verify(shots.is_empty() and h.pos[sp] == before, "windup stop")
	h._move(0.02)
	verify(shots.size() == 1 and shots[0] == p.position and is_equal_approx(shot_damage[0], 14.3), "spit target/growth/elite damage")
	for i in 150:
		h._move(1.0 / 60.0)
	verify(shots.size() == 1, "spit not before 3 seconds")
	for i in 40:
		h._move(1.0 / 60.0)
	verify(shots.size() == 2, "spit repeats after 3 seconds")
	h.spit_cd[sp] = 99.0
	h.spit_windup[sp] = 0.0
	h.pos[sp] = p.position + Vector2(100.0, 0.0)
	h._move(0.1)
	verify(h.pos[sp].distance_to(p.position) > 100.0, "spitter retreats")
	h.pos[sp] = p.position + Vector2(200.0, 0.0)
	h._move(0.1)
	verify(h.pos[sp].distance_to(p.position) < 200.0, "spitter approaches")
	h.pos[sp] = p.position + Vector2(150.0, 0.0)
	h._move(0.1)
	verify(is_equal_approx(h.pos[sp].distance_to(p.position), 150.0), "spitter holds distance")
	h.pos[sp] = p.position + Vector2(300.0, 0.0)
	h.spit_cd[sp] = 0.0
	h._move(0.01)
	verify(h.spit_windup[sp] == 0.0, "spitter no shot beyond 260")
	h.pos[sp] = p.position + Vector2(80.0, 0.0)
	h._move(0.01)
	verify(h.spit_windup[sp] == 0.0, "spitter no shot below 90")
	print("S1 CONTRACT checks=%d failures=%d" % [checks, failures])
	game.free()
	quit(0 if failures == 0 else 1)
