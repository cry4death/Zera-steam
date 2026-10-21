extends Node
## ZAI1 (временный стенд аудита ИИ орды): настоящая сцена, игрок бессмертен; метрики поведения толпы.
## --headless --fixed-fps 60 --path . res://tools/diag/zai1_metrics.tscn -- --fresh-save --nav-thread [--map=<id>]
##   [--at=<с>] [--dur=<с>] [--warm=<с>] [--move | --kite] [--noguns] [--pos=x,y] [--profile] [--tag=<имя>]
##   [--snap=t1,t2] [--seq=t] [--arrows] [--campaign-op=clearance]
## Строки ZAI1W — окна по 5 с, ZAI1S — итог (JSON) после разгона --warm.

const KINDS := 7
var game
var args := PackedStringArray()
var tag := "run"
var _start := Vector2.ZERO
var _t := 0.0
var _tick := 0
var _dur := 90.0
var _warm := 20.0
var _mode := "stand"
var _ready_run := false
var _next_report := 5.0
var _p05 := {}
var _p01 := {}
var _h01 := {}
var _m01 := {}
var _spawn := {}
var _contacted := {}
var _known := {}
var _nav_seen := 0
var _nav_times := PackedFloat32Array()
var _upd := PackedFloat32Array()
var _snaps := PackedFloat32Array()
var _seq_at := -1.0
var _seq_n := 0
var W := {}
var S := {}
var _ttc := PackedFloat32Array()
var _eff_path := PackedFloat32Array()
var _spawn_dist := PackedFloat32Array()
var _kill_d := PackedFloat32Array()
var _kill_off := 0
var _sep0 := 0
var _col0 := 0
var _body0 := 0
var _bodyc0 := 0
var _prof0 := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	args = OS.get_cmdline_user_args()
	_run.call_deferred()


func _arg(name: String, fallback: String) -> String:
	for a in args:
		if a.begins_with(name + "="):
			return a.trim_prefix(name + "=")
	return fallback


func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	# В окне карта грузится несколько кадров: ждём готового поля, иначе игрок ещё в (8, 8).
	for f in 1200:
		if game.obstacles and game.obstacles.nav_completed > 0 and game.player.position.x > 16.0:
			break
		await get_tree().process_frame
	game.player.god_mode = true
	tag = _arg("--tag", "run")
	_dur = float(_arg("--dur", "90"))
	_warm = float(_arg("--warm", "20"))
	if "--noguns" in args:
		game.weapons.process_mode = Node.PROCESS_MODE_DISABLED
	if "--move" in args:
		_mode = "move"
	elif "--kite" in args:
		_mode = "kite"
	var at := float(_arg("--at", "0"))
	if at > 0.0:
		game.time = at
	_start = game.player.position
	var pos_arg := _arg("--pos", "")
	if pos_arg != "":
		var xy := pos_arg.split(",")
		_start = game.obstacles.free_point(Vector2(float(xy[0]), float(xy[1])), 8.0)
		game.player.position = _start
	if "--profile" in args:
		game.obstacles.profile_enabled = true
	for s in _arg("--snap", "").split(",", false):
		_snaps.append(float(s))
	_seq_at = float(_arg("--seq", "-1"))
	if "--overlay" in args:
		var ov = load("res://tools/diag/collision_overlay.gd").new()
		ov.ob = game.obstacles
		ov.z_index = 100
		game.obstacles.add_child(ov)
	if "--arrows" in args:
		var ar = load("res://tools/diag/zai1_arrows.gd").new()
		ar.horde = game.horde
		ar.z_index = 101
		game.horde.add_child(ar)
	_reset(W)
	_reset(S)
	game.horde.enemy_died.connect(_on_died)
	_ready_run = true
	print("ZAI1VIEW view_rect=%s screen=%s viewport=%s zoom=%s spawn_ring=%.0f" % [PixelArt.view_rect(game.horde, 0.0), _screen(), get_viewport().get_visible_rect().size, game.camera.zoom, game.horde.spawn_ring])
	print("ZAI1 tag=%s map=%s start=%s mode=%s at=%.0f guns=%s threaded=%s node=%s" % [tag, game._map_id, _start, _mode, at,
		not ("--noguns" in args), game.obstacles.threaded_nav, game.objective != null])


## Экран живой игры 1080p: камера ×3 показывает 640×360 мировых px (game._update_view). Без окна view_rect врёт.
func _screen() -> Rect2:
	return Rect2(game.camera.get_screen_center_position() - Vector2(320.0, 180.0), Vector2(640.0, 360.0))


func _reset(a: Dictionary) -> void:
	for key in ["stall_n", "stall_s", "turn_sum", "turn_n", "turn_big", "turn_rev", "turn_near_n", "turn_near_big",
			"face_n", "face_bad", "face_back", "direct", "field", "contact", "wait", "cover", "samples", "tan", "rad",
			"ring_n", "onscreen", "far", "mode_n", "mode_flip", "ovl_sum", "ovl_n", "ovl_deep", "spawn_n", "spawn_view", "spawn_near", "alive", "r150", "stuck"]:
		a[key] = 0.0
	var per := []
	for k in KINDS:
		per.append([0.0, 0.0, 0.0, 0.0]) # стоящих, всего, сумма эффективности скорости, n
	a["kind"] = per


func _add(key: String, v: float) -> void:
	W[key] += v
	if _t >= _warm:
		S[key] += v


func _add_kind(k: int, slot: int, v: float) -> void:
	W["kind"][k][slot] += v
	if _t >= _warm:
		S["kind"][k][slot] += v


func _physics_process(delta: float) -> void:
	if game == null or game.horde == null or not _ready_run:
		return
	if game.trader_ui and game.trader_ui.visible:
		game.trader_ui.close()
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
	var h = game.horde
	var ob = game.obstacles
	var pp: Vector2 = game.player.global_position
	_upd.append(h.update_ms)
	if ob.nav_completed != _nav_seen:
		_nav_seen = ob.nav_completed
		_nav_times.append(_t)
	_track_spawns(h, pp)
	if _tick % 6 == 0:
		_sample_fast(h, ob, pp)
	if _tick % 30 == 0:
		_sample_slow(h, ob, pp)
	# движение игрока
	if _mode == "move":
		var want := _start + Vector2(cos(_t * 0.35), sin(_t * 0.35)) * 170.0
		game.player.position = ob.move_actor(game.player.position, want, 6.0)
	elif _mode == "kite":
		var want := _start + Vector2(cos(_t * 0.3), sin(_t * 0.3)) * 260.0
		game.player.position = ob.move_actor(game.player.position, want, 6.0)
	else:
		game.player.position = _start
	for s in _snaps:
		if absf(_t - s) < delta * 0.5:
			_snap.call_deferred("%s_t%03d" % [tag, int(s)])
	if _seq_at >= 0.0 and _t >= _seq_at and _seq_n < 24 and _tick % 6 == 0:
		_snap.call_deferred("%s_seq%02d" % [tag, _seq_n])
		_seq_n += 1
	if _t >= _next_report:
		_next_report += 5.0
		_report(h, ob, pp)
	if _t >= _dur:
		_summary(h, ob)
		get_tree().quit()


func _on_died(at: Vector2, _kind: int, _elite: bool) -> void:
	if _t < _warm:
		return
	_kill_d.append(at.distance_to(game.player.global_position))
	if not _screen().has_point(at):
		_kill_off += 1


func _track_spawns(h, pp: Vector2) -> void:
	var view: Rect2 = _screen()
	for i in h.count:
		if h.dead[i] == 1:
			continue
		var u: int = h.uid[i]
		var q: Vector2 = h.pos[i]
		if not _known.has(u):
			_known[u] = true
			if _t > 1.0:
				_add("spawn_n", 1.0)
				if view.has_point(q):
					_add("spawn_view", 1.0)
				if q.distance_to(pp) < 300.0:
					_add("spawn_near", 1.0)
				_spawn[u] = [_t, q.distance_to(pp), h.speed[i]]
				if _t >= _warm:
					_spawn_dist.append(q.distance_to(pp))
		elif not _contacted.has(u) and _spawn.has(u) and q.distance_to(pp) < 40.0:
			_contacted[u] = true
			var rec: Array = _spawn[u]
			var ttc: float = _t - float(rec[0])
			if float(rec[0]) >= 2.0 and _t >= _warm:
				_ttc.append(ttc)
				_eff_path.append(maxf(0.0, float(rec[1]) - 40.0) / maxf(ttc * float(rec[2]), 0.001))


func _sample_fast(h, ob, pp: Vector2) -> void:
	var cur := {}
	var head := {}
	var modes := {}
	for i in h.count:
		if h.dead[i] == 1:
			continue
		var u: int = h.uid[i]
		var q: Vector2 = h.pos[i]
		cur[u] = q
		if q.distance_to(pp) > 90.0:
			var m := 1 if h.steer[i] == Vector2.ZERO else 2
			modes[u] = m
			if _m01.has(u):
				_add("mode_n", 1.0)
				if int(_m01[u]) != m:
					_add("mode_flip", 1.0)
		if not _p01.has(u):
			continue
		var d := q.distance_to(pp)
		if d < 14.0 or d > 500.0 or h.freeze_t[i] > 0.0:
			continue
		var v: Vector2 = q - _p01[u]
		var nominal: float = h.speed[i] * 0.1
		if v.length() < nominal * 0.3:
			continue
		var hd := v.angle()
		head[u] = hd
		var fd: float = absf(angle_difference(h.angle[i], hd))
		_add("face_n", 1.0)
		if fd > PI * 0.25:
			_add("face_bad", 1.0)
		if fd > PI * 0.667:
			_add("face_back", 1.0)
		if _h01.has(u):
			var turn: float = absf(angle_difference(float(_h01[u]), hd))
			_add("turn_sum", rad_to_deg(turn))
			_add("turn_n", 1.0)
			if turn > PI * 0.25:
				_add("turn_big", 1.0)
			if turn > PI * 0.667:
				_add("turn_rev", 1.0)
			if ob.obstacle_distance[ob.cell_at(q)] < 16.0:
				_add("turn_near_n", 1.0)
				if turn > PI * 0.25:
					_add("turn_near_big", 1.0)
	_p01 = cur
	_h01 = head
	_m01 = modes


func _sample_slow(h, ob, pp: Vector2) -> void:
	var cur := {}
	var sectors := PackedByteArray()
	sectors.resize(16)
	var contact := 0
	var wait := 0
	var alive := 0
	var r150 := 0
	var view: Rect2 = _screen()
	for i in h.count:
		if h.dead[i] == 1:
			continue
		alive += 1
		var u: int = h.uid[i]
		var q: Vector2 = h.pos[i]
		cur[u] = q
		var d := q.distance_to(pp)
		var k: int = h.kind[i]
		if d < 150.0:
			r150 += 1
		if view.has_point(q):
			_add("onscreen", 1.0)
		elif d > 800.0:
			_add("far", 1.0)
		var touch: float = Player.RADIUS + h.radius[i] + 1.5
		if d <= touch:
			contact += 1
		elif d < 80.0:
			wait += 1
		if d < 40.0:
			sectors[int(fposmod((q - pp).angle(), TAU) / TAU * 16.0) % 16] = 1
		if d > 90.0:
			if h.steer[i] == Vector2.ZERO:
				_add("direct", 1.0)
			else:
				_add("field", 1.0)
		if h._stuck_time[i] > 0.0:
			_add("stuck", 1.0)
		if _p05.has(u):
			var v: Vector2 = (q - _p05[u]) / 0.5
			var to := (pp - q).normalized()
			var nominal: float = maxf(h.speed[i] * (1.0 - h.chill[i]), 1.0)
			if d > 45.0 and d < 500.0 and h.freeze_t[i] <= 0.0:
				_add("stall_n", 1.0)
				_add_kind(k, 1, 1.0)
				if v.dot(to) < 5.0:
					_add("stall_s", 1.0)
					_add_kind(k, 0, 1.0)
				_add_kind(k, 2, v.dot(to) / nominal)
				_add_kind(k, 3, 1.0)
			if d >= 12.0 and d < 80.0:
				_add("ring_n", 1.0)
				_add("rad", v.dot(to))
				_add("tan", absf(v.dot(to.orthogonal())))
		if d < 200.0:
			for j in h.query_radius(q, h.radius[i]):
				if j == i:
					continue
				var min_d: float = h.radius[i] + h.radius[j]
				var pen: float = (min_d - q.distance_to(h.pos[j])) / min_d
				if pen > 0.0:
					_add("ovl_sum", pen)
					_add("ovl_n", 1.0)
					if pen > 0.4:
						_add("ovl_deep", 1.0)
	_p05 = cur
	var covered := 0
	for s in sectors:
		covered += s
	_add("contact", contact)
	_add("wait", wait)
	_add("cover", covered / 16.0)
	_add("samples", 1.0)
	_add("alive", alive)
	_add("r150", r150)


func _pct(a: Dictionary, num: String, den: String) -> float:
	return 100.0 * a[num] / maxf(a[den], 1.0)


func _line(a: Dictionary) -> String:
	var n := maxf(a["samples"], 1.0)
	return "alive=%.0f r150=%.0f stall=%.1f%% turn=%.1fdeg big=%.1f%% rev=%.1f%% near_big=%.1f%% face_bad=%.1f%% back=%.1f%% direct=%.0f%% contact=%.2f wait=%.1f cover=%.2f rad=%.1f tan=%.1f ovl=%.3f deep=%.1f%% stuck=%.1f%% spawn_view=%.0f/%.0f near=%.0f" % [
		a["alive"] / n, a["r150"] / n, _pct(a, "stall_s", "stall_n"), a["turn_sum"] / maxf(a["turn_n"], 1.0),
		_pct(a, "turn_big", "turn_n"), _pct(a, "turn_rev", "turn_n"), _pct(a, "turn_near_big", "turn_near_n"),
		_pct(a, "face_bad", "face_n"), _pct(a, "face_back", "face_n"), 100.0 * a["direct"] / maxf(a["direct"] + a["field"], 1.0),
		a["contact"] / n, a["wait"] / n, a["cover"] / n, a["rad"] / maxf(a["ring_n"], 1.0), a["tan"] / maxf(a["ring_n"], 1.0),
		a["ovl_sum"] / maxf(a["ovl_n"], 1.0), _pct(a, "ovl_deep", "ovl_n"), 100.0 * a["stuck"] / maxf(a["alive"], 1.0),
		a["spawn_view"], a["spawn_n"], a["spawn_near"]]


func _report(h, ob, pp: Vector2) -> void:
	var lag: float = ob._flow_target.distance_to(pp)
	print("ZAI1W t=%3.0f %s lag=%.0f upd_ms=%.2f" % [_t, _line(W), lag, h.update_ms])
	_reset(W)


func _quant(a: PackedFloat32Array, q: float) -> float:
	if a.is_empty():
		return -1.0
	var s := a.duplicate()
	s.sort()
	return s[clampi(int(q * (s.size() - 1)), 0, s.size() - 1)]


func _summary(h, ob) -> void:
	var kinds := {}
	for k in KINDS:
		var row: Array = S["kind"][k]
		if row[1] > 0.0:
			kinds[str(k)] = {"stall": snappedf(100.0 * row[0] / row[1], 0.1), "radial_eff": snappedf(row[2] / maxf(row[3], 1.0), 0.01), "n": int(row[1])}
	var intervals := PackedFloat32Array()
	for j in range(1, _nav_times.size()):
		if _nav_times[j] >= _warm:
			intervals.append(_nav_times[j] - _nav_times[j - 1])
	var upd := _upd.slice(int(_warm * 60.0))
	var out := {"tag": tag, "map": game._map_id, "mode": _mode, "line": _line(S), "kinds": kinds,
		"ttc_p50": snappedf(_quant(_ttc, 0.5), 0.1), "ttc_p90": snappedf(_quant(_ttc, 0.9), 0.1), "ttc_n": _ttc.size(),
		"path_eff_p50": snappedf(_quant(_eff_path, 0.5), 0.01), "spawn_d_p10": int(_quant(_spawn_dist, 0.1)), "spawn_d_p50": int(_quant(_spawn_dist, 0.5)),
		"upd_p50": snappedf(_quant(upd, 0.5), 0.01), "upd_p95": snappedf(_quant(upd, 0.95), 0.01),
		"nav_interval_p50": snappedf(_quant(intervals, 0.5), 0.001), "nav_updates": intervals.size(),
		"kills": game.kills, "onscreen": snappedf(S["onscreen"] / maxf(S["samples"], 1.0), 0.1), "far": snappedf(S["far"] / maxf(S["samples"], 1.0), 0.1), "kill_d_p50": int(_quant(_kill_d, 0.5)), "kill_d_p90": int(_quant(_kill_d, 0.9)), "kill_offscreen_pct": snappedf(100.0 * _kill_off / maxf(_kill_d.size(), 1.0), 0.1), "mode_flip_pct": snappedf(100.0 * S["mode_flip"] / maxf(S["mode_n"], 1.0), 0.01)}
	if ob.profile_enabled:
		var ticks := maxf(h.profile_ticks, 1.0)
		out["sep_us"] = int(h.separation_usec / ticks)
		out["col_us"] = int(h.collision_usec / ticks)
		if "move_usec" in h:
			out["move_us"] = int(h.move_usec / ticks)
		out["body_us_tick"] = int(ob.body_usec / maxf(_tick, 1.0))
		out["body_calls_tick"] = snappedf(ob.body_calls / maxf(_tick, 1.0), 0.1)
		out["resolve_calls_tick"] = snappedf(ob.resolve_calls / maxf(_tick, 1.0), 0.1)
		out["resolve_us_tick"] = int(ob.resolve_usec / maxf(_tick, 1.0))
	if "--flowcost" in args:
		for k in 3:
			var layer: Dictionary = ob._nav_layers[k]
			var o := {}
			var t0 := Time.get_ticks_usec()
			Obstacles._flow_layer(layer["edges"], layer["weights"], layer["points"], layer["capacity"], ob._offsets, ob.cell_at(game.player.position), game.player.position, o)
			out["flow_ms_%d" % k] = snappedf((Time.get_ticks_usec() - t0) / 1000.0, 0.1)
		out["cells"] = ob.blocked.size()
	print("ZAI1S ", JSON.stringify(out))


func _snap(label: String) -> void:
	game.camera.position = game.player.position
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://tmp/zai1_%s.png" % label)
