extends Node
## Диагностика «зомби копятся и не подходят»: настоящая сцена, игрок бессмертен и стоит, раз в 5 с —
## сколько живых в радиусах и средняя радиальная скорость (к игроку > 0) ближних.
## --headless --fixed-fps 60 --path . res://tools/diag/crowd_stall.tscn -- --fresh-save [--map=<id>] [--at=<с>] [--move] [--noguns] [--loadout] [--pos=x,y] [--snap] [--overlay]
## Строки STALL: доля зомби в 45–500 px, не идущих к игроку (норма после 2026-10-20 — 0–5 %). Кадры --snap — в tmp/.

var game
var _start := Vector2.ZERO
var _last := {}
var _t := 0.0
var _next := 5.0
var _prev := {}
var _tick := 0
var _stalled := 0
var _sampled := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.player.god_mode = true
	if "--noguns" in OS.get_cmdline_user_args():
		game.weapons.process_mode = Node.PROCESS_MODE_DISABLED
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--at="):
			game.time = float(arg.trim_prefix("--at="))
	_start = game.player.position
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pos="):
			var xy := arg.trim_prefix("--pos=").split(",")
			_start = game.obstacles.free_point(Vector2(float(xy[0]), float(xy[1])), 8.0)
			game.player.position = _start
	if "--overlay" in OS.get_cmdline_user_args():
		var ov = load("res://tools/diag/collision_overlay.gd").new()
		ov.ob = game.obstacles
		ov.z_index = 100
		game.obstacles.add_child(ov)
	print("DIAG map=%s start=%s" % [game._map_id, _start])


func _physics_process(delta: float) -> void:
	if game == null or game.horde == null:
		return
	if get_tree().paused:
		if game.level_up.cards.size() > 0:
			game.level_up._pick(0)
			if not game.level_up._card.is_empty():
				game.level_up._pick(game._auto_slot(game.level_up._card))
		if get_tree().paused:
			get_tree().paused = false
		return
	_t += delta
	_tick += 1
	if _tick % 30 == 0:
		var hh = game.horde
		var pp: Vector2 = game.player.global_position
		var cur := {}
		for i in hh.count:
			if hh.dead[i] == 1:
				continue
			var q: Vector2 = hh.pos[i]
			cur[hh.uid[i]] = q
			var dd := q.distance_to(pp)
			if dd > 45.0 and dd < 500.0 and _prev.has(hh.uid[i]):
				var v: Vector2 = (q - _prev[hh.uid[i]]) / 0.5
				_sampled += 1
				if v.dot((pp - q).normalized()) < 5.0:
					_stalled += 1
		_prev = cur
	if "--move" in OS.get_cmdline_user_args():
		var want := _start + Vector2(cos(_t * 0.35), sin(_t * 0.35)) * 170.0
		game.player.position = game.obstacles.move_actor(game.player.position, want, 6.0)
	else:
		game.player.position = _start
	if _t < _next:
		return
	_next += 5.0
	var h = game.horde
	var p: Vector2 = game.player.global_position
	var bands := [40.0, 80.0, 150.0, 300.0]
	var counts := [0, 0, 0, 0]
	var vel_sum := 0.0
	var vel_n := 0
	var knock_sum := 0.0
	var now := {}
	for i in h.count:
		if h.dead[i] == 1:
			continue
		var d: float = h.pos[i].distance_to(p)
		for b in 4:
			if d <= bands[b]:
				counts[b] += 1
		now[h.uid[i]] = d
		if d > 50.0 and d < 250.0 and _last.has(h.uid[i]) and not "--move" in OS.get_cmdline_user_args():
			vel_sum += (float(_last[h.uid[i]]) - d) / 5.0
			vel_n += 1
			knock_sum += h.knock[i].length()
	_last = now
	if "--snap" in OS.get_cmdline_user_args():
		_snap.call_deferred(int(_t))
	print("NAV t=%3.0f avg_us=%d worst_us=%d target_lag=%.0f completed=%d building=%s ready=%s" % [_t, game.obstacles.nav_total_usec / maxi(game.obstacles.nav_calls, 1), game.obstacles.nav_worst_usec, game.obstacles._flow_target.distance_to(p), game.obstacles.nav_completed, game.obstacles._building, game.obstacles._flow_ready])
	game.obstacles.nav_worst_usec = 0 # худший вызов — за последние 5 с
	print("STALL t=%3.0f stalled=%.0f%% of %d" % [_t, 100.0 * _stalled / maxf(_sampled, 1), _sampled])
	_stalled = 0
	_sampled = 0
	print("DIAG t=%3.0f alive=%d r40=%d r80=%d r150=%d r300=%d approach_v=%.1f (n=%d) knock=%.1f" % [
		_t, h.count, counts[0], counts[1], counts[2], counts[3],
		vel_sum / maxf(vel_n, 1), vel_n, knock_sum / maxf(vel_n, 1)])
	if _t >= 90.0:
		get_tree().quit()


func _snap(t: int) -> void:
	game.camera.position = game.player.position
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(960, 540, Image.INTERPOLATE_BILINEAR)
	img.save_png("res://tmp/diag_snap_%03d.png" % t)
