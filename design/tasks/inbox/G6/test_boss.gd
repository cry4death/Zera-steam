extends SceneTree
## Проверка в копии zera: --headless --disable-vsync --path . --script res://test_boss.gd

const STEP := 1.0 / 60.0
var world: Node2D
var boss: Boss
var player: Player
var horde: Horde
var effects: Effects
var clock := 0.0
var failures := 0
var telegraphs := 0
var slams := 0
var roars := 0
var crushes := 0
var plates := 0
var deaths := 0
var charge_begin := 0.0
var charge_wait := 0.0
var previous_state := -1
var physics_usec := 0
var physics_max := 0
var samples := 0
var damage_values: Array[float] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", label)


func _run() -> void:
	seed(706)
	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(world)
	player = Player.new()
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	player.add_child(sprite)
	player.max_hp = 1000000.0
	world.add_child(player)
	player.hurt.connect(func(amount: float) -> void: damage_values.append(amount))
	effects = Effects.new()
	world.add_child(effects)
	horde = Horde.new()
	world.add_child(horde)
	horde.setup(Rect2(0.0, 0.0, 640.0, 360.0), player, null)
	for i in 200:
		horde.spawn(Vector2(randf_range(90.0, 550.0), randf_range(140.0, 220.0)))
	boss = Boss.new()
	boss.player = player
	boss.horde = horde
	boss.effects = effects
	boss.arena = horde.arena
	world.add_child(boss)
	boss.charge_telegraph.connect(_telegraph)
	boss.slam_started.connect(func(_p: Vector2) -> void:
		slams += 1
		print("EVENT t=%.3f slam phase=%d" % [clock, boss.phase]))
	boss.roar.connect(func(count: int) -> void:
		roars += 1
		print("EVENT t=%.3f roar count=%d" % [clock, count])
		for i in count:
			horde.spawn(boss.global_position + Vector2.from_angle(float(i) * TAU / count) * 65.0, Horde.Kind.RUNNER))
	boss.crushed.connect(func(_p: Vector2, _dir: Vector2) -> void: crushes += 1)
	boss.armor_plate.connect(func(_p: Vector2, _dir: Vector2) -> void: plates += 1)
	boss.phase_changed.connect(func(phase: int) -> void: print("EVENT t=%.3f phase=%d hp=%.2f plates=%d" % [clock, phase, boss.hp, plates]))
	boss.died.connect(func(_p: Vector2) -> void: deaths += 1)
	boss.start(Vector2(80.0, 180.0))
	print("SIM begin seconds=60 hz=60 shamblers=200 seed=706")
	for frame in 3600:
		clock = float(frame + 1) * STEP
		if frame == 1800:
			boss.take_damage(15999.0, Vector2.RIGHT, boss.global_position)
			_check(boss.phase == 1 and is_equal_approx(boss.hp, 12000.75), "phase stays 1 above 50%")
			boss.take_damage(1.0, Vector2.RIGHT, boss.global_position)
			_check(boss.phase == 2 and is_equal_approx(boss.hp, 12000.0), "phase 2 at exactly 50%")
			var hp_before := boss.hp
			boss.take_damage(999.0, Vector2.RIGHT, boss.global_position)
			_check(boss.hp == hp_before, "armor shedding invulnerability")
		var segment := int(clock / 8.0) % 2
		if segment == 0:
			player.global_position = Vector2(320.0, 180.0) + Vector2.from_angle(clock * 0.4) * 150.0
		else:
			player.global_position = boss.global_position.move_toward(Vector2(320.0, 180.0), 75.0)
		player._iframes = maxf(player._iframes - STEP, 0.0)
		horde._physics_process(STEP)
		_tick(STEP)
		effects._physics_process(STEP)
		_check(boss.global_position == boss._bounded(boss.global_position), "arena containment")
	_check(telegraphs >= 5 and slams > 1 and roars > 0 and crushes > 0, "all attacks and crushing in 60 s")
	_check(boss.phase == 2 and effects.particle_count() > 0, "phase 2 blood")
	print("SIM end telegraphs=%d slams=%d roars=%d crushed=%d plates=%d" % [telegraphs, slams, roars, crushes, plates])
	print("PERF boss_physics_avg_ms=%.6f max_ms=%.6f samples=%d" % [float(physics_usec) / samples / 1000.0, float(physics_max) / 1000.0, samples])
	_check(float(physics_usec) / samples < 300.0, "boss average < 0.3 ms")
	_unit_checks()
	# Настоящая пауза дерева: прямые вызовы выше используются только для ускорения.
	world.process_mode = Node.PROCESS_MODE_INHERIT
	player.set_physics_process(false)
	horde.set_physics_process(false)
	effects.set_physics_process(false)
	boss.start(Vector2(200.0, 180.0))
	paused = true
	var old_age := boss._age
	for i in 3:
		await physics_frame
	_check(boss._age == old_age, "scene pause")
	paused = false
	print("CHECK pause PASS" if boss._age == old_age else "CHECK pause FAIL")
	print("RESULT failures=%d" % failures)
	quit(0 if failures == 0 else 1)


func _telegraph(_from: Vector2, _to: Vector2, duration: float) -> void:
	telegraphs += 1
	charge_begin = clock
	charge_wait = duration
	print("EVENT t=%.3f telegraph phase=%d duration=%.1f" % [clock, boss.phase, duration])


func _tick(delta: float) -> void:
	var before := Time.get_ticks_usec()
	boss._physics_process(delta)
	var elapsed := Time.get_ticks_usec() - before
	physics_usec += elapsed
	physics_max = maxi(physics_max, elapsed)
	samples += 1
	if boss._state == Boss.State.CHARGE and previous_state == Boss.State.TELEGRAPH:
		_check(clock - charge_begin + 0.00001 >= charge_wait, "full charge telegraph")
	previous_state = boss._state


func _reset(p := Vector2(200.0, 180.0)) -> void:
	boss.start(p)
	boss.horde = null
	damage_values.clear()
	player._iframes = 0.0
	player.is_dead = false
	player.global_position = boss.global_position


func _unit_checks() -> void:
	_reset()
	player.position += Vector2(100.0, 0.0)
	boss._charge_cd = 99.0
	boss._slam_cd = 99.0
	boss._roar_cd = 99.0
	var old_pos := boss.position
	boss._physics_process(0.1)
	_check(is_equal_approx(boss.position.distance_to(old_pos), 4.0), "phase 1 speed 40")
	boss.take_damage(16000.0, Vector2.RIGHT, boss.position)
	boss._physics_process(1.2)
	old_pos = boss.position
	boss._physics_process(0.1)
	_check(is_equal_approx(boss.position.distance_to(old_pos), 6.0), "phase 2 speed 60")
	var old_hp := boss.hp
	boss.take_damage(100.0, Vector2.RIGHT, boss.position)
	_check(is_equal_approx(old_hp - boss.hp, 100.0) and boss._flash == 0.08, "phase 2 full damage and flash")
	_check(effects._bake.count(1) > 0, "blood bake particles")
	print("CHECK walk_speed=40/60 phase2_damage=100% flash=0.08 blood_bake PASS")
	_reset()
	boss._charge_cd = 99.0
	boss._slam_cd = 99.0
	boss._roar_cd = 99.0
	for i in 49:
		player._iframes = 0.0
		boss._physics_process(STEP)
	_check(damage_values == [20.0, 20.0], "contact 20, cooldown 0.8")
	_reset()
	boss.take_damage(16000.0, Vector2.RIGHT, boss.position)
	boss._physics_process(1.2)
	boss._charge_cd = 99.0
	boss._slam_cd = 99.0
	boss._roar_cd = 99.0
	boss._physics_process(STEP)
	_check(damage_values == [25.0], "phase 2 contact 25")
	print("CHECK contact phase1=20 phase2=25 cooldown=0.8 PASS")
	_reset(Vector2(100.0, 180.0))
	player.position = Vector2(130.0, 180.0)
	boss._charges_left = 1
	boss._begin_telegraph()
	for i in 60:
		boss._physics_process(STEP)
	_check(damage_values.is_empty(), "charge has no windup damage")
	boss._physics_process(0.25)
	boss._physics_process(0.25)
	_check(damage_values == [35.0], "swept charge 35 once")
	for i in 200:
		if boss._state != Boss.State.CHARGE:
			break
		boss._physics_process(0.01)
	_check(boss._state == Boss.State.RECOVER and boss._charge_cd == 6.0, "charge cooldown 6 after final pass")
	var hp_at_recover := boss.hp
	boss.take_damage(100.0, Vector2.RIGHT, boss.position)
	_check(is_equal_approx(hp_at_recover - boss.hp, 75.0), "recover vulnerable and armor 25%")
	print("CHECK charge telegraph=1.0 swept_damage=35 once PASS")
	_reset()
	player.position += Vector2(80.0, 0.0)
	boss._choose_attack()
	for i in 29:
		boss._physics_process(STEP)
	_check(damage_values.is_empty() and not boss._slam_wave, "slam windup no damage")
	for i in 38:
		boss._physics_process(STEP)
	_check(damage_values == [25.0], "slam ring 25 once")
	_check(boss._slam_cd > 8.3 and boss._slam_cd < 8.5, "slam cooldown 9")
	_reset()
	player.position += Vector2(80.0, 0.0)
	boss._choose_attack()
	player._iframes = 10.0
	for i in 67:
		boss._physics_process(STEP)
	_check(damage_values.is_empty(), "slam dash invulnerability")
	_reset()
	boss.take_damage(16000.0, Vector2.RIGHT, boss.position)
	boss._physics_process(1.2)
	player.position += Vector2(80.0, 0.0)
	boss._choose_attack()
	boss._physics_process(0.5)
	_check(is_equal_approx(boss._slam_cd, 6.3), "phase 2 slam cooldown 6.3")
	print("CHECK slam windup=0.5 radius=150 time=0.6 width=20 damage=25 once dash_safe PASS")
	_reset()
	boss.take_damage(16000.0, Vector2.RIGHT, boss.position)
	boss._physics_process(1.2)
	player.position = Vector2(500.0, 180.0)
	var t: Array[float] = []
	var record := func(_a: Vector2, _b: Vector2, duration: float) -> void: t.append(duration)
	boss.charge_telegraph.connect(record)
	boss._choose_attack()
	var recover_frames := 0
	var recovery_lengths: Array[int] = []
	var last_state := boss._state
	for i in 2000:
		if boss._state == Boss.State.RECOVER:
			recover_frames += 1
		boss._physics_process(STEP)
		if last_state == Boss.State.RECOVER and boss._state != Boss.State.RECOVER:
			recovery_lengths.append(recover_frames)
			recover_frames = 0
		last_state = boss._state
		player.position = Vector2(640.0, 360.0) - player.position
		if recovery_lengths.size() == 3:
			break
	boss.charge_telegraph.disconnect(record)
	_check(t == [0.7, 0.7, 0.7], "three fresh phase 2 telegraphs")
	_check(recovery_lengths == [24, 24, 36], "recover 0.4/0.4/0.6")
	print("CHECK phase2 telegraphs=%s recovery_frames=%s" % [t, recovery_lengths])
	_reset(Vector2(622.0, 342.0))
	player.position = Vector2(639.0, 359.0)
	boss._charges_left = 1
	boss._begin_telegraph()
	boss._physics_process(1.0)
	boss._physics_process(STEP)
	_check(boss._state == Boss.State.RECOVER, "wall ends charge")
	boss.global_position = Vector2(-999.0, 999.0)
	boss._physics_process(STEP)
	_check(boss.position == Vector2(18.0, 342.0), "external displacement clamped")
	_check(boss.hit_test(boss.position + Vector2(20.0, 0.0), 2.0), "hit test tangent")
	_reset()
	var before := deaths
	_check(boss.take_damage(100000.0, Vector2.RIGHT, boss.position), "lethal returns true")
	_check(not boss.is_alive() and not boss.visible and deaths == before + 1, "death hides and emits once")
	_check(not boss.take_damage(10.0, Vector2.RIGHT, boss.position) and deaths == before + 1, "no repeated death")
	_check(not boss.hit_test(boss.position, 10.0), "dead hit test false")
	print("CHECK wall_recover displacement hit_test death PASS")
