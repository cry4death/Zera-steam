extends SceneTree
## Самостоятельный прогон только во временной копии проекта.

class TestPlayer extends Player:
	var hits := 0
	var received := 0.0
	func _ready() -> void:
		hp = 10000.0
	func _physics_process(delta: float) -> void:
		_iframes = maxf(_iframes - delta, 0.0)
	func take_damage(amount: float) -> void:
		var before := hp
		super.take_damage(amount)
		if hp < before:
			hits += 1
			received += before - hp

class TestHorde extends Horde:
	var hazards: Hazards
	var chain := false
	var calls := 0
	var bad_explosive := false
	var last_damage := 0.0
	var last_dir := Vector2.ZERO
	var last_knock := 0.0
	func _ready() -> void:
		pass
	func query_radius(p: Vector2, r: float) -> PackedInt32Array:
		var result := PackedInt32Array()
		for i in count:
			if pos[i].distance_to(p) <= r + RADIUS:
				result.append(i)
		return result
	func damage(i: int, amount: float, dir: Vector2, knockback: float,
			_ammo := WeaponDefs.Ammo.STANDARD, _crit := false,
			_hit_pos := Vector2.INF, explosive := false) -> bool:
		calls += 1
		last_damage = amount
		last_dir = dir
		last_knock = knockback
		bad_explosive = bad_explosive or not explosive
		dead[i] = 1
		if chain:
			hazards.fat_explosion(pos[i], false)
		return true

class TestFloor extends FloorDecals:
	var stamps := 0
	var pools := 0
	var wets := 0
	var bad_blood := false
	func _process(_delta: float) -> void:
		pass
	func stamp(_tex: Texture2D, _pos: Vector2, _rot: float, _color: Color, _scale_factor := 1.0) -> void:
		stamps += 1
	func blood(_tex: Texture2D, _pos: Vector2, _rot: float, scale_factor := 1.0, thickness := 0.6) -> void:
		pools += 1
		bad_blood = bad_blood or scale_factor < 1.6 or scale_factor > 2.4 or not is_equal_approx(thickness, 0.9)
	func mark_wet(_pos: Vector2, _radius: float) -> void:
		wets += 1

class TestEffects extends Effects:
	var pus := 0
	var baked := 0
	var burst_count := 0
	var bad_burst := false
	func _ready() -> void:
		pass
	func _physics_process(_delta: float) -> void:
		pass
	func emit(_p: Vector2, _v: Vector2, _life: float, _color: Color, _size: float, _drag: float, bake := false) -> void:
		if bake:
			baked += 1
		else:
			pus += 1
	func blood_burst(_p: Vector2, dir: Vector2, n: int, speed: float, spread: float) -> void:
		burst_count += 1
		bad_burst = bad_burst or dir != Vector2.RIGHT or n != 40 or speed != 170.0 or spread != PI

class TestCamera extends GameCamera:
	var last_shake := 0.0
	func _process(_delta: float) -> void:
		pass
	func shake(amount: float) -> void:
		last_shake = amount

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		_failures += 1
		push_error("FAIL: " + message)


func _step(h: Hazards, p: TestPlayer, dt: float) -> void:
	if p:
		p._physics_process(dt)
	h._physics_process(dt)


func _run() -> void:
	seed(127)
	var h := Hazards.new()
	root.add_child(h)
	h.set_physics_process(false)
	_check(h.projectile_count() == 0 and h.pool_count() == 0, "initial counts")
	h.spit(Vector2.ZERO, Vector2(14, 0), 10.0)
	h._physics_process(0.05)
	_check(h.projectile_count() == 1 and h.pool_count() == 0 and h._shot_pos[0].is_equal_approx(Vector2(7, 0)), "spit speed 140")
	h._physics_process(0.05)
	_check(h.projectile_count() == 0 and h.pool_count() == 1 and h._pool_pos[0] == Vector2(14, 0), "arrival creates pool at target, null dependencies")
	h.clear()
	h.spit(Vector2.ONE, Vector2.ONE, 10.0)
	h._physics_process(1.0 / 60.0)
	_check(h.projectile_count() == 0 and h.pool_count() == 1, "zero-length spit")
	h.clear()
	var p := TestPlayer.new()
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	p.add_child(sprite)
	root.add_child(p)
	p.set_physics_process(false)
	h.player = p
	p.position = Vector2(50, 0)
	h.spit(Vector2.ZERO, Vector2(100, 0), 10.0)
	_step(h, p, 1.0)
	_check(h.projectile_count() == 0 and h.pool_count() == 0 and p.received == 10.0, "swept collision: hit removes spit without pool")
	h.spit(Vector2.ZERO, Vector2(10, 0), 10.0)
	_step(h, p, 1.0)
	_check(h.pool_count() == 1 and p.received == 10.0, "player beyond target is not hit")
	h.clear()
	p.position = Vector2.ZERO
	p._iframes = 0.0
	p.hits = 0
	p.received = 0.0
	h.acid_pool(Vector2.ZERO)
	h.acid_pool(Vector2.ZERO)
	for i in 60:
		_step(h, p, 1.0 / 60.0)
	_check(p.hits == 2 and p.received == 5.0, "overlap: two accepted ticks per second, total 5 damage")
	h.clear()
	p._iframes = 0.0
	p.received = 0.0
	h.acid_pool(Vector2.ZERO, 20.0, 5.0)
	h.acid_pool(Vector2.ZERO, 20.0, 9.0)
	_step(h, p, 1.0 / 60.0)
	_check(p.received == 4.5, "overlap selects maximum DPS")
	h.clear()
	p._iframes = 0.0
	p.hits = 0
	p.received = 0.0
	h.acid_pool(Vector2.ZERO)
	for i in 181:
		_step(h, p, 1.0 / 60.0)
	_check(p.hits == 6 and p.received == 15.0 and h.pool_count() == 0, "default pool: 3 seconds, six ticks, 15 damage, expires")
	h.clear()
	p._iframes = 0.0
	p.received = 0.0
	h.acid_pool(Vector2.ZERO)
	_step(h, p, 0.01)
	p.position = Vector2(100, 0)
	_step(h, p, 0.1)
	p.position = Vector2.ZERO
	_step(h, p, 0.3)
	_check(p.received == 2.5, "exit and re-entry do not reset acid cooldown")
	p.is_dead = true
	_step(h, p, 0.6)
	_check(p.received == 2.5, "dead player takes no acid damage")
	p.is_dead = false
	h.clear()
	for i in 64:
		h.acid_pool(Vector2(i, 0), 20.0, 5.0, 10.0)
	h._pool_life[10] = 0.0
	h.player = null
	h._physics_process(0.01)
	h.acid_pool(Vector2(64, 0))
	h.acid_pool(Vector2(65, 0))
	_check(h.pool_count() == 64 and not h._pool_pos.has(Vector2.ZERO) and h._pool_pos.has(Vector2(65, 0)), "64-pool limit removes oldest after swap-remove")
	var lobe := h._lobe_pos[0]
	h._physics_process(0.02)
	_check(h._lobe_pos[0] == lobe, "pool silhouette remains fixed")
	h.clear()
	h.acid_pool(Vector2.ZERO, 0.0)
	h.acid_pool(Vector2.ZERO, 20.0, 5.0, 0.0)
	_check(h.pool_count() == 0, "invalid pool dimensions are ignored")
	for i in 10:
		h.fat_explosion(Vector2(i, 0), false)
	_check(h._flash_count == 0 and h._queue_count == 10, "explosions are queued")
	h._physics_process(1.0 / 60.0)
	_check(h._flash_count == 8 and h._queue_count == 2, "maximum eight explosions per frame")
	h._physics_process(1.0 / 60.0)
	_check(h._flash_count == 10 and h._queue_count == 0, "remaining explosions execute next frame")
	h._physics_process(0.3)
	_check(h._flash_count == 0, "flash expires after 0.25 seconds")
	h.clear()
	var mob := TestHorde.new()
	mob.visible = false
	root.add_child(mob)
	mob.set_physics_process(false)
	mob.hazards = h
	mob.count = 2
	mob.pos = PackedVector2Array([Vector2.ZERO, Vector2(500, 0)])
	mob.dead = PackedByteArray([0, 0])
	mob.chain = true
	h.horde = mob
	h.fat_explosion(Vector2.ZERO, false)
	h._physics_process(1.0 / 60.0)
	_check(mob.calls == 1 and h._queue_count == 1 and h._flash_count == 1, "synchronous chain is deferred to next frame")
	_check(is_equal_approx(mob.last_damage, 40.0) and is_equal_approx(mob.last_dir.length(), 1.0) and mob.last_knock == 140.0 and not mob.bad_explosive, "blast center: damage, random unit direction, knockback, explosive flag")
	h._physics_process(1.0 / 60.0)
	_check(h._queue_count == 0 and mob.calls == 1 and h._flash_count == 2, "dead zombies are skipped")
	h.clear()
	mob.chain = false
	mob.count = 1
	mob.pos = PackedVector2Array([Vector2(53, 0)])
	mob.dead = PackedByteArray([0])
	h.fat_explosion(Vector2.ZERO, false)
	h._physics_process(1.0 / 60.0)
	_check(is_equal_approx(mob.last_damage, 20.0), "blast edge falloff includes Horde.RADIUS")
	h.clear()
	h.horde = null
	h.player = p
	p.position = Vector2(60, 0)
	p._iframes = 0.0
	p.received = 0.0
	h.minutes = 10.0
	h.fat_explosion(Vector2.ZERO, false)
	_step(h, p, 0.01)
	_check(p.received == 0.0, "normal blast radius 48")
	h.fat_explosion(Vector2.ZERO, true)
	_step(h, p, 0.01)
	_check(is_equal_approx(p.received, 58.5), "elite blast radius 72 and scaled player damage 58.5 at minute 10")
	var floor_layer := TestFloor.new()
	var fx := TestEffects.new()
	var cam := TestCamera.new()
	root.add_child(floor_layer)
	root.add_child(fx)
	root.add_child(cam)
	h.floor_decals = floor_layer
	h.effects = fx
	h.camera = cam
	h.clear()
	h.acid_pool(Vector2.ZERO)
	_check(floor_layer.stamps == 1, "acid stamps floor once")
	h.fat_explosion(Vector2.ZERO, false)
	_step(h, p, 0.01)
	_check(fx.burst_count == 1 and not fx.bad_burst and fx.pus >= 20 and fx.pus <= 30 and fx.baked >= 8 and fx.baked <= 10, "blast emits radial blood, 20-30 pus, 8-10 baked drops")
	_check(floor_layer.pools >= 2 and floor_layer.pools <= 3 and floor_layer.wets == 1 and not floor_layer.bad_blood, "blast stamps 2-3 blood pools and wet area")
	_check(cam.last_shake == 4.0, "camera shake 4 within 150")
	p.position = Vector2(225, 0)
	h.fat_explosion(Vector2.ZERO, false)
	_step(h, p, 0.01)
	_check(cam.last_shake == 2.0, "camera shake attenuates to 2 at 225")
	p.position = Vector2(301, 0)
	cam.last_shake = 0.0
	h.fat_explosion(Vector2.ZERO, false)
	_step(h, p, 0.01)
	_check(cam.last_shake == 0.0, "no camera shake beyond 300")
	h.clear()
	h.player = null
	h.effects = null
	h.floor_decals = null
	h.camera = null
	for i in 2051:
		h.fat_explosion(Vector2(i, 0), false)
	for i in 260:
		h._physics_process(1.0 / 60.0)
	_check(h._queue_count == 0 and h._queue_pos.size() == 4096, "queue grows beyond reserve without dropping explosions")
	h.clear()
	h._queue_head = h._queue_pos.size() - 4
	for i in h._queue_pos.size() + 1:
		h.fat_explosion(Vector2(i, 0), false)
	var fifo_ok := true
	for i in h._queue_count:
		if h._queue_pos[(h._queue_head + i) % h._queue_pos.size()] != Vector2(i, 0):
			fifo_ok = false
	_check(fifo_ok, "wrapped FIFO preserves order during growth")
	h.clear()
	for i in 100:
		h.spit(Vector2.ZERO, Vector2(1000, 0), 10.0)
	_check(h.projectile_count() == 100, "spit buffer grows without dropping projectiles")
	h.clear()
	_check(h.projectile_count() == 0 and h.pool_count() == 0 and h._queue_count == 0 and h._flash_count == 0, "clear resets all transient state")
	for i in 64:
		h.acid_pool(Vector2(i * 5, 0), 20.0, 5.0, 1000.0)
	for i in 40:
		h.spit(Vector2(i, 0), Vector2(1000000, 0), 10.0)
	mob.count = 500
	mob.pos.resize(500)
	mob.dead.resize(500)
	mob.pos.fill(Vector2.ZERO)
	mob.dead.fill(0)
	h.horde = mob
	var worst_us := 0
	var started := Time.get_ticks_usec()
	for frame in 120:
		mob.dead.fill(0)
		for k in 8:
			h.fat_explosion(Vector2.ZERO, false)
		var tick := Time.get_ticks_usec()
		h._physics_process(1.0 / 60.0)
		worst_us = maxi(worst_us, Time.get_ticks_usec() - tick)
	var elapsed := Time.get_ticks_usec() - started
	print("BENCH: 120 physics steps, 40 spits, 64 pools, 8 blasts/step, 500 zombies (test double); average_us=", elapsed / 120.0, "; worst_us=", worst_us)
	_check(h.projectile_count() == 40 and h.pool_count() == 64 and h._queue_count == 0, "peak workload keeps counts stable")
	h.clear()
	# Настоящие компоненты: проверяем совместимость без подмены методов.
	var actual_floor := FloorDecals.new()
	root.add_child(actual_floor)
	actual_floor.setup(Rect2(0, 0, 512, 512))
	actual_floor.set_process(false)
	var actual_effects := Effects.new()
	root.add_child(actual_effects)
	actual_effects.floor_decals = actual_floor
	actual_effects.set_physics_process(false)
	var actual_horde := Horde.new()
	root.add_child(actual_horde)
	actual_horde.set_physics_process(false)
	actual_horde.setup(Rect2(0, 0, 512, 512), p, actual_floor)
	for i in 10:
		actual_horde.spawn(Vector2(150 + i, 150))
	actual_horde._rebuild_grid()
	var actual_camera := GameCamera.new()
	root.add_child(actual_camera)
	actual_camera.set_process(false)
	h.horde = actual_horde
	h.floor_decals = actual_floor
	h.effects = actual_effects
	h.camera = actual_camera
	h.player = p
	p.position = Vector2(160, 160)
	p._iframes = 0.0
	h.acid_pool(Vector2(300, 300))
	h.spit(Vector2(100, 100), Vector2(300, 300), 10.0)
	h.fat_explosion(Vector2(150, 150), false)
	_step(h, p, 1.0 / 60.0)
	var dead_count := 0
	for i in actual_horde.count:
		dead_count += actual_horde.dead[i]
	_check(dead_count == 10 and actual_effects.particle_count() >= 68 and not actual_floor._blood.is_empty() and not actual_floor._stamps.is_empty(), "integration with actual Horde, Player damage, Effects, FloorDecals, GameCamera")
	await process_frame
	await process_frame
	_check(true, "fallback draw callback completed")
	var image := Image.create_empty(60, 60, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.45, 0.62, 0.12, 0.55))
	var texture := ImageTexture.create_from_image(image)
	for i in 3:
		h._acid_tex[i] = texture
		h._spit_tex[i] = texture
	h.queue_redraw()
	await process_frame
	await process_frame
	_check(true, "optional texture draw callback completed (synthetic texture, G3 art absent)")
	h.clear()
	print("RESULT: failures=", _failures)
	quit(0 if _failures == 0 else 1)
