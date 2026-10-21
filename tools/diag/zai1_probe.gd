extends Node
## ZAI1 (облако, временный): точечные замеры к разделу «Что доделать» отчёта reviews/ZOMBIE_AI_REVIEW.md.
## Настоящая геометрия экрана без GPU (Linux): xvfb-run -a -s "-screen 0 1920x1080x24" godot --audio-driver Dummy
##   --rendering-driver dummy --fixed-fps 60 --path . res://tools/diag/zai1_probe.tscn -- --fresh-save --nav-thread
##   --probe=<режим> [--map=<id>] [--at=<с>] [--dur=<с>] [--warm=<с>] [--noguns] [--move | --kite] [--tag=<имя>]
## Режимы:
##   jerk   — давка: смещение особи за тик в полосе 12–80 px от игрока, разложенное на шаг, выталкивание игроком,
##            разделение и стены (подкласс орды zai1_horde_probe.gd); плюс смещение за 0,1 с, как у штрихов zai1_arrows.
##   wall   — колонны у стен (З4): доля идущих зомби у стены (<16 px) при открытом месте рядом против доли такой площади.
##   boss   — босс за домом (З5): с --boss [--boss-kind=…]; пары «босс — игрок» с перекрытой и открытой линией.
##   shield — обход щита (С8): боец кружит вокруг щитовика на R px со скоростью игрока; доля времени вне щита.
##   watch  — окна по --win с: живые, r90, в кадре, урон по игроку, убийства за кадром; с --sim, --alarm, узлом
##            (--node-rate=<доля HP в минуту> — стенд сам бьёт узел «Зачистки», игрок стоит в --near-node px от него).
##   jerk также пишет кольцо касания (< 12 px): выталкивание игроком против разделения.
## Кадры (вместо --rendering-driver dummy — --rendering-method gl_compatibility): --overview=t1,t2 — камера ×1 на кадр
##   (res://tmp/zai1_<tag>_ovNNN.png), --arrows — штрихи скорости zai1_arrows.gd.
## Режиссёр в стенде выключен (--fresh-save — тестовый флаг); включить — --director-bench.

const SHIELD_COS := 0.35 # horde._absorb_armor: удар спереди, если dot(пуля, взгляд) < -0.35 → щит закрывает ±69,5°
var game
var args := PackedStringArray()
var probe := "jerk"
var tag := "run"
var _t := 0.0
var _tick := 0
var _dur := 90.0
var _warm := 20.0
var _mode := "stand"
var _start := Vector2.ZERO
var _ready_run := false
var _sim := false
var rng := RandomNumberGenerator.new()


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
	probe = _arg("--probe", "jerk")
	_sim = args.has("--sim") or Array(args).any(func(a: String) -> bool: return a.begins_with("--sim="))
	game = load("res://scenes/main.tscn").instantiate()
	if probe == "jerk":
		game.get_node("World/Horde").set_script(load("res://tools/diag/zai1_horde_probe.gd"))
	get_tree().root.add_child(game)
	await get_tree().process_frame
	for f in 1200:
		if game.obstacles and game.obstacles.nav_completed > 0 and game.player.position.x > 16.0:
			break
		await get_tree().process_frame
	tag = _arg("--tag", probe)
	_dur = float(_arg("--dur", "90"))
	_warm = float(_arg("--warm", "20"))
	rng.seed = hash(tag) & 0x7fffffff
	if not _sim:
		game.player.god_mode = true
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
	for v in _arg("--overview", "").split(",", false):
		_overviews.append(float(v))
	if "--arrows" in args:
		var ar = load("res://tools/diag/zai1_arrows.gd").new()
		ar.horde = game.horde
		ar.z_index = 101
		game.horde.add_child(ar)
	match probe:
		"jerk":
			_jerk_init()
		"wall":
			pass
		"boss":
			game.player.autopilot = false
		"shield":
			_shield_init()
		"watch":
			_watch_init()
	print("ZAI1VIEW viewport=%s zoom=%s spawn_ring=%.0f" % [get_viewport().get_visible_rect().size, game.camera.zoom, game.horde.spawn_ring])
	print("ZAI1P start probe=%s tag=%s map=%s start=%s mode=%s at=%.0f guns=%s sim=%s node=%s" % [probe, tag, game._map_id, _start, _mode, at,
		not ("--noguns" in args), _sim, game.objective != null])
	_ready_run = true


## Экран живой игры 1080p: камера ×3 показывает 640×360 мировых px.
func _screen() -> Rect2:
	return Rect2(game.camera.get_screen_center_position() - Vector2(320.0, 180.0), Vector2(640.0, 360.0))


func _physics_process(delta: float) -> void:
	if game == null or game.horde == null or not _ready_run:
		return
	if not _sim:
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
	for v in _overviews:
		if absf(_t - v) < delta * 0.5:
			_overview.call_deferred("%s_ov%03d" % [tag, int(v)])
	if not _sim and probe != "boss" and probe != "shield":
		_move_player()
	match probe:
		"wall":
			if _tick % 30 == 0:
				_wall_sample()
		"boss":
			_boss_step(delta)
		"shield":
			_shield_step(delta)
		"watch":
			_watch_step(delta)
	if probe != "watch" and probe != "boss" and probe != "shield" and _t >= _dur:
		_finish()


var _overviews := PackedFloat32Array()


## Обзор: камера ×1 (1920×1080 мировых px вокруг игрока) на один кадр, затем прежний зум.
func _overview(label: String) -> void:
	var z: Vector2 = game.camera.zoom
	game.camera.zoom = Vector2.ONE
	game.camera.position = game.player.position
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tmp/zai1_%s.png" % label)
	game.camera.zoom = z


func _move_player() -> void:
	var ob = game.obstacles
	var near_node := float(_arg("--near-node", "0"))
	if near_node > 0.0 and game.objective != null and game.boss.is_alive():
		if _t < 0.05:
			_start = ob.free_point(game.boss.global_position + Vector2(near_node, 0.0), 8.0)
	if _mode == "move":
		game.player.position = ob.move_actor(game.player.position, _start + Vector2(cos(_t * 0.35), sin(_t * 0.35)) * 170.0, 6.0)
	elif _mode == "kite":
		game.player.position = ob.move_actor(game.player.position, _start + Vector2(cos(_t * 0.3), sin(_t * 0.3)) * 260.0, 6.0)
	else:
		game.player.position = _start


func _finish() -> void:
	match probe:
		"jerk":
			_jerk_summary()
		"wall":
			_wall_summary()
	get_tree().quit()


func _quant(a: PackedFloat32Array, q: float) -> float:
	if a.is_empty():
		return -1.0
	var s := a.duplicate()
	s.sort()
	return s[clampi(int(q * (s.size() - 1)), 0, s.size() - 1)]


func _dist(a: PackedFloat32Array) -> Dictionary:
	var sum := 0.0
	for v in a:
		sum += v
	return {"n": a.size(), "mean": snappedf(sum / maxf(a.size(), 1), 0.001), "p50": snappedf(_quant(a, 0.5), 0.001),
		"p90": snappedf(_quant(a, 0.9), 0.001), "p99": snappedf(_quant(a, 0.99), 0.001), "max": snappedf(_quant(a, 1.0), 0.001)}


# ---------------------------------------------------------------- jerk: рывки в давке

var J := {}
var _w_start := PackedVector2Array()
var _w_path := PackedFloat32Array()
var _w_uid := PackedInt32Array()
var _w_n := PackedInt32Array()
var _prev_tot := PackedVector2Array()
var _prev_ok := PackedByteArray()
var _kind_n := PackedFloat32Array()
var _kind_eff := PackedFloat32Array()


func _jerk_init() -> void:
	for key in ["total", "nom", "move", "sep", "col", "push", "net01", "path01", "ratio01", "nom01", "rad", "dv", "dv_nom",
			"in_total", "in_sep", "in_nom", "in_dv", "in_push", "in_rad"]:
		J[key] = PackedFloat32Array()
	for key in ["in_n", "in_elig", "in_pushed", "in_rep_err", "in_both", "in_opp"]:
		J[key] = 0.0
	_kind_n.resize(7)
	_kind_eff.resize(7)
	for key in ["elig", "pushed", "rep_err", "opp", "both", "big2", "big1", "samples", "inband", "e_sep", "e_push", "e_col", "e_nom", "e_total"]:
		J[key] = 0.0
	game.horde.probe_on = true
	game.horde.tick_cb = _jerk_tick


func _jerk_tick(delta: float) -> void:
	if _t < _warm or get_tree().paused:
		return
	var h = game.horde
	var ob = game.obstacles
	var pp: Vector2 = game.player.global_position
	var near: PackedInt32Array = ob.near_head
	var cap: int = h.pos.size()
	if _w_start.size() != cap:
		_w_start.resize(cap)
		_w_path.resize(cap)
		_w_uid.resize(cap)
		_w_uid.fill(-1)
		_w_n.resize(cap)
		_prev_tot.resize(cap)
		_prev_ok.resize(cap)
		_prev_ok.fill(0)
	var window_end := _tick % 6 == 0
	J["samples"] += 1.0
	for i in h.count:
		if h.dead[i] == 1:
			continue
		var s: Vector2 = h.s0[i]
		var f: Vector2 = h.pos[i]
		# окно 0,1 с — путь и итоговое смещение по uid
		if _w_uid[i] != h.uid[i]:
			_w_uid[i] = h.uid[i]
			_w_start[i] = s
			_w_path[i] = 0.0
			_w_n[i] = 0
			_prev_ok[i] = 0
		_w_path[i] += s.distance_to(f)
		_w_n[i] += 1
		var d0 := s.distance_to(pp)
		var tot_now := f - s
		var had_prev := _prev_ok[i] == 1
		var prev_now := _prev_tot[i]
		_prev_tot[i] = tot_now
		_prev_ok[i] = 1
		if window_end:
			if _w_n[i] == 6 and d0 >= 12.0 and d0 <= 80.0 and h.fr0[i] <= 0.0:
				var net := _w_start[i].distance_to(f)
				J["net01"].append(net)
				J["path01"].append(_w_path[i])
				J["nom01"].append(h.speed[i] * (1.0 - h.ch0[i]) * 0.1)
				if net > 0.05:
					J["ratio01"].append(_w_path[i] / net)
			_w_start[i] = f
			_w_path[i] = 0.0
			_w_n[i] = 0
		if d0 < 0.01 or d0 > 80.0 or h.fr0[i] > 0.0:
			continue
		var inner := d0 < 12.0
		if not inner:
			J["inband"] += 1.0
			_kind_n[h.kind[i]] += 1.0
		var a: Vector2 = h.a1[i]
		var c: Vector2 = h.c1[i]
		var spd: float = h.speed[i] * (1.0 - h.ch0[i])
		if h.quirk[i] == Horde.Trait.LIMP:
			spd *= 1.0 + sin(h._time * 7.0 + h.seed_value[i] * TAU) * 0.55
		elif h.quirk[i] == Horde.Trait.CRAWLER:
			spd *= 1.0 + sin(h._time * 5.0 + h.seed_value[i] * TAU) * 0.20
		var nom := spd * delta
		var total := f - s
		var sep := c - a
		var col := f - c
		var dir := (pp - s) / d0
		if inner:
			_jerk_inner(i, s, a, c, f, dir, nom, delta, had_prev, prev_now, pp, near)
			continue
		J["total"].append(total.length())
		_kind_eff[h.kind[i]] += total.dot(dir) / maxf(nom, 0.0001)
		# рывок: смена смещения за тик относительно прошлого тика той же особи
		if had_prev:
			var dv := (total - prev_now).length()
			J["dv"].append(dv)
			J["dv_nom"].append(dv / maxf(nom, 0.0001))
		J["nom"].append(nom)
		J["move"].append((a - s).length())
		J["sep"].append(sep.length())
		J["col"].append(col.length())
		J["rad"].append(total.dot(dir) / maxf(nom, 0.0001))
		J["e_sep"] += sep.length()
		J["e_col"] += col.length()
		J["e_nom"] += nom
		J["e_total"] += total.length()
		if total.length() > 2.0 * nom:
			J["big2"] += 1.0
		if total.length() > 1.0:
			J["big1"] += 1.0
		# выталкивание игроком: точка шага без него восстанавливается точно (horde._move, полоса < 90 px без стен рядом)
		if h.kind[i] != Horde.Kind.SPITTER and h.group_id[i] == 0 and near[ob.cell_at(s)] == -1 and (h.k0[i] * delta).length() < 0.5:
			var pre: Vector2 = s + dir * nom + h.k0[i] * delta
			var push := a - pre
			J["elig"] += 1.0
			J["push"].append(push.length())
			J["e_push"] += push.length()
			var touch_r: float = Player.RADIUS + h.radius[i]
			if push.length() > 0.01:
				J["pushed"] += 1.0
				if absf(a.distance_to(pp) - touch_r) > 0.05:
					J["rep_err"] += 1.0
			if push.length() > 0.05 and sep.length() > 0.05:
				J["both"] += 1.0
				if push.normalized().dot(sep.normalized()) < -0.5:
					J["opp"] += 1.0


## Кольцо касания (< 12 px): здесь работает выталкивание игроком (horde._move, touch_r = 5 + радиус зомби).
func _jerk_inner(i: int, s: Vector2, a: Vector2, c: Vector2, f: Vector2, dir: Vector2, nom: float, delta: float,
		had_prev: bool, prev_now: Vector2, pp: Vector2, near: PackedInt32Array) -> void:
	var h = game.horde
	var total := f - s
	var sep := c - a
	J["in_n"] += 1.0
	J["in_total"].append(total.length())
	J["in_sep"].append(sep.length())
	J["in_nom"].append(nom)
	if had_prev:
		J["in_dv"].append((total - prev_now).length())
	if h.kind[i] == Horde.Kind.SPITTER or h.group_id[i] != 0 or near[game.obstacles.cell_at(s)] != -1 or (h.k0[i] * delta).length() >= 0.5:
		return
	var push: Vector2 = a - (s + dir * nom + h.k0[i] * delta)
	J["in_elig"] += 1.0
	J["in_push"].append(push.length())
	if push.length() > 0.01:
		J["in_pushed"] += 1.0
		if absf(a.distance_to(pp) - (Player.RADIUS + h.radius[i])) > 0.05:
			J["in_rep_err"] += 1.0
	if push.length() > 0.05 and sep.length() > 0.05:
		J["in_both"] += 1.0
		if push.normalized().dot(sep.normalized()) < -0.5:
			J["in_opp"] += 1.0
	# итог тика вдоль радиуса: + к игроку
	J["in_rad"].append(total.dot(dir))


func _jerk_summary() -> void:
	var out := {"tag": tag, "map": game._map_id, "mode": _mode, "alive": game.horde.count, "guns": not ("--noguns" in args),
		"band_per_tick": snappedf(J["inband"] / maxf(J["samples"], 1.0), 0.1)}
	for key in ["total", "nom", "move", "sep", "col", "push", "net01", "path01", "ratio01", "nom01", "rad", "dv", "dv_nom"]:
		out[key] = _dist(J[key])
	var inner := {"per_tick": snappedf(J["in_n"] / maxf(J["samples"], 1.0), 0.1),
		"pushed_pct": snappedf(100.0 * J["in_pushed"] / maxf(J["in_elig"], 1.0), 0.1),
		"replica_err_pct": snappedf(100.0 * J["in_rep_err"] / maxf(J["in_pushed"], 1.0), 0.1),
		"push_vs_sep_opposite_pct": snappedf(100.0 * J["in_opp"] / maxf(J["in_both"], 1.0), 0.1)}
	for key in ["in_total", "in_sep", "in_nom", "in_dv", "in_push", "in_rad"]:
		inner[key] = _dist(J[key])
	out["inner"] = inner
	var kinds := {}
	for k in 7:
		if _kind_n[k] > 0.0:
			kinds[str(k)] = {"share_pct": snappedf(100.0 * _kind_n[k] / maxf(J["inband"], 1.0), 0.1), "radial_eff": snappedf(_kind_eff[k] / _kind_n[k], 0.01)}
	out["kinds"] = kinds
	out["pushed_pct"] = snappedf(100.0 * J["pushed"] / maxf(J["elig"], 1.0), 0.1)
	out["push_replica_err_pct"] = snappedf(100.0 * J["rep_err"] / maxf(J["pushed"], 1.0), 0.1)
	out["push_vs_sep_opposite_pct"] = snappedf(100.0 * J["opp"] / maxf(J["both"], 1.0), 0.1)
	out["over_2x_nom_pct"] = snappedf(100.0 * J["big2"] / maxf(J["inband"], 1.0), 0.1)
	out["over_1px_pct"] = snappedf(100.0 * J["big1"] / maxf(J["inband"], 1.0), 0.1)
	# «Куда уходит движение»: суммы модулей за тик относительно номинального шага
	var e: float = maxf(J["e_nom"], 0.0001)
	out["sum_ratio"] = {"sep": snappedf(J["e_sep"] / e, 0.01), "push": snappedf(J["e_push"] / e * J["inband"] / maxf(J["elig"], 1.0), 0.01),
		"col": snappedf(J["e_col"] / e, 0.01), "total": snappedf(J["e_total"] / e, 0.01)}
	print("ZAI1P jerk ", JSON.stringify(out))


# ---------------------------------------------------------------- wall: колонны у стен (З4)

var _p05 := {}
var WL := {}


func _wall_sample() -> void:
	var h = game.horde
	var ob = game.obstacles
	var pp: Vector2 = game.player.global_position
	if WL.is_empty():
		for key in ["n_direct", "n_field", "near_direct", "near_field", "hug_direct", "hug_field", "par_direct", "par_field",
				"area_n", "area_near", "area_hug", "nb_hug", "nb_hug_n", "nb_open", "nb_open_n", "samples"]:
			WL[key] = 0.0
	var cur := {}
	var counting := _t >= _warm
	for i in h.count:
		if h.dead[i] == 1:
			continue
		var u: int = h.uid[i]
		var q: Vector2 = h.pos[i]
		cur[u] = q
		if not counting or not _p05.has(u):
			continue
		var d := q.distance_to(pp)
		if d < 90.0 or d > 600.0 or h.freeze_t[i] > 0.0:
			continue
		var v: Vector2 = (q - _p05[u]) / 0.5
		if v.length() < 0.3 * h.speed[i] * (1.0 - h.chill[i]):
			continue
		var m := "direct" if h.steer[i] == Vector2.ZERO else "field"
		WL["n_" + m] += 1.0
		var c: int = ob.cell_at(q)
		var nb: int = h.query_radius(q, 10.0).size() - 1
		if ob.obstacle_distance[c] < 16.0:
			WL["near_" + m] += 1.0
			var normal: Vector2 = ob.wall_normal[c]
			if ob.obstacle_distance[ob.cell_at(q + normal * 24.0)] >= 28.0:
				WL["hug_" + m] += 1.0
				WL["nb_hug"] += nb
				WL["nb_hug_n"] += 1.0
				if absf(v.normalized().dot(normal)) < 0.4:
					WL["par_" + m] += 1.0
		else:
			WL["nb_open"] += nb
			WL["nb_open_n"] += 1.0
	_p05 = cur
	if not counting:
		return
	WL["samples"] += 1.0
	# Та же классификация для случайных проходимых точек того же кольца — ожидание при равномерной толпе.
	for k in 600:
		var q := pp + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf_range(90.0 * 90.0, 600.0 * 600.0))
		if not ob.arena.has_point(q):
			continue
		var c: int = ob.cell_at(q)
		if ob.obstacle_distance[c] < 6.0:
			continue
		WL["area_n"] += 1.0
		if ob.obstacle_distance[c] < 16.0:
			WL["area_near"] += 1.0
			if ob.obstacle_distance[ob.cell_at(q + ob.wall_normal[c] * 24.0)] >= 28.0:
				WL["area_hug"] += 1.0


func _wall_summary() -> void:
	var out := {"tag": tag, "map": game._map_id, "mode": _mode, "guns": not ("--noguns" in args), "samples": WL["samples"]}
	var area_near: float = WL["area_near"] / maxf(WL["area_n"], 1.0)
	var area_hug: float = WL["area_hug"] / maxf(WL["area_n"], 1.0)
	out["area_near_pct"] = snappedf(100.0 * area_near, 0.1)
	out["area_hug_pct"] = snappedf(100.0 * area_hug, 0.1)
	for m in ["direct", "field"]:
		var n: float = maxf(WL["n_" + m], 1.0)
		out[m] = {"n": int(WL["n_" + m]), "near_pct": snappedf(100.0 * WL["near_" + m] / n, 0.1), "hug_pct": snappedf(100.0 * WL["hug_" + m] / n, 0.1),
			"hug_x_area": snappedf(WL["hug_" + m] / n / maxf(area_hug, 0.0001), 0.01),
			"parallel_of_hug_pct": snappedf(100.0 * WL["par_" + m] / maxf(WL["hug_" + m], 1.0), 0.1)}
	var all_n: float = maxf(WL["n_direct"] + WL["n_field"], 1.0)
	out["all_hug_x_area"] = snappedf((WL["hug_direct"] + WL["hug_field"]) / all_n / maxf(area_hug, 0.0001), 0.01)
	out["field_share_pct"] = snappedf(100.0 * WL["n_field"] / all_n, 0.1)
	out["neighbors10_hug"] = snappedf(WL["nb_hug"] / maxf(WL["nb_hug_n"], 1.0), 0.01)
	out["neighbors10_open"] = snappedf(WL["nb_open"] / maxf(WL["nb_open_n"], 1.0), 0.01)
	print("ZAI1P wall ", JSON.stringify(out))


# ---------------------------------------------------------------- boss: босс за домом (З5)

var B := {}
var _trial := -1
var _trial_t := 0.0
var _trial_blocked := false
var _trial_d0 := 0.0
var _trial_limit := 30.0
var _trial_stuck := 0.0
var _trial_hist := PackedVector2Array()
var _trial_p := Vector2.ZERO
var _results: Array = []


func _boss_reach() -> float:
	var boss = game.boss
	if boss is BossGeneral:
		return 140.0 # Генерал сам держится в 125 px
	return (boss.body_radius() if boss.has_method("body_radius") else Boss.RADIUS) + Player.RADIUS + 10.0


func _boss_speed() -> float:
	var boss = game.boss
	if boss is BossHive:
		return [18.0, 30.0, 96.0][boss.phase - 1]
	if boss is BossGeneral:
		return 24.0
	return 40.0 if boss.phase == 1 else 60.0


func _boss_step(delta: float) -> void:
	var boss = game.boss
	if not boss.is_alive() or game.time < 600.5:
		return
	if _trial < 0 or _trial_done():
		if _trial >= 0:
			_trial_report()
		_trial += 1
		if _trial >= int(_arg("--trials", "16")):
			_boss_summary()
			get_tree().quit()
			return
		_trial_setup()
	game.player.position = _trial_p
	_trial_t += delta
	_trial_hist.append(boss.global_position)
	var n := _trial_hist.size()
	if n > 120 and n % 30 == 0:
		var moved: float = boss.global_position.distance_to(_trial_hist[n - 121])
		if boss.global_position.distance_to(_trial_p) > _boss_reach() + 20.0 and moved < 4.0:
			_trial_stuck += 0.5


func _trial_done() -> bool:
	var d: float = game.boss.global_position.distance_to(_trial_p)
	return d <= _boss_reach() or _trial_t >= _trial_limit


func _trial_setup() -> void:
	var ob = game.obstacles
	var boss = game.boss
	var r: float = boss.body_radius() if boss.has_method("body_radius") else Boss.RADIUS
	_trial_blocked = _trial % 2 == 0
	var arena: Rect2 = ob.arena.grow(-160.0)
	for attempt in 400:
		var p: Vector2 = ob.free_point(arena.position + Vector2(rng.randf(), rng.randf()) * arena.size, 8.0)
		var b: Vector2 = ob.free_point(p + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(220.0, 380.0), r + 2.0)
		if not ob.arena.grow(-r - 4.0).has_point(b):
			continue
		var dist := p.distance_to(b)
		if dist < 200.0 or dist > 400.0:
			continue
		if ob.line_clear(b, p) == _trial_blocked:
			continue
		_trial_p = p
		boss.global_position = b
		break
	game.time = 605.0 # --boss завершает прогон на 14:00 игрового времени
	_trial_t = 0.0
	_trial_stuck = 0.0
	_trial_hist = PackedVector2Array()
	_trial_d0 = boss.global_position.distance_to(_trial_p)
	_trial_limit = maxf(30.0, 2.0 * (_trial_d0 - _boss_reach()) / _boss_speed() + 5.0)
	game.player.position = _trial_p


func _trial_report() -> void:
	var boss = game.boss
	var d: float = boss.global_position.distance_to(_trial_p)
	var reached := d <= _boss_reach()
	var ideal: float = maxf(_trial_d0 - _boss_reach(), 0.0) / _boss_speed()
	var rec := {"blocked": _trial_blocked, "reached": reached, "t": snappedf(_trial_t, 0.1), "ideal_t": snappedf(ideal, 0.1),
		"d0": int(_trial_d0), "d_end": int(d), "stuck_s": _trial_stuck, "phase": boss.phase}
	_results.append(rec)
	print("ZAI1P boss_trial ", JSON.stringify(rec))


func _boss_summary() -> void:
	var out := {"tag": tag, "map": game._map_id, "boss": str(game.boss.get_script().resource_path.get_file()),
		"speed": _boss_speed(), "reach": _boss_reach()}
	for blocked in [true, false]:
		var n := 0
		var ok := 0
		var stuck := 0.0
		var total_t := 0.0
		var slow := PackedFloat32Array()
		for rec in _results:
			if rec["blocked"] != blocked:
				continue
			n += 1
			total_t += rec["t"]
			stuck += rec["stuck_s"]
			if rec["reached"]:
				ok += 1
				slow.append(rec["t"] / maxf(rec["ideal_t"], 0.1))
		out["blocked" if blocked else "clear"] = {"n": n, "reached_pct": snappedf(100.0 * ok / maxf(n, 1), 0.1),
			"stuck_share_pct": snappedf(100.0 * stuck / maxf(total_t, 0.1), 0.1), "slowdown_p50": snappedf(_quant(slow, 0.5), 0.01)}
	print("ZAI1P boss ", JSON.stringify(out))


# ---------------------------------------------------------------- shield: обход щита (С8)

var _radii := PackedFloat32Array()
var _speeds := PackedFloat32Array()
var _sh_case := -1
var _sh_uid := -1
var _sh_theta := 0.0
var _sh_t := 0.0
var _sh_first := -1.0
var _sh_open := 0.0
var _sh_off_sum := 0.0
var _sh_off_n := 0.0
var _sh_center := Vector2.ZERO


func _shield_init() -> void:
	for s in _arg("--radii", "40,60,80,100,150").split(","):
		_radii.append(float(s))
	for s in _arg("--speeds", "80").split(","):
		_speeds.append(float(s))
	game.spawner.enabled = false
	# Открытое место: ближайшая к старту клетка, от которой до препятствий больше 220 px.
	var ob = game.obstacles
	var best := INF
	for c in ob.obstacle_distance.size():
		if ob.obstacle_distance[c] >= 220.0:
			var p: Vector2 = ob.cell_center(c)
			var dd := p.distance_squared_to(_start)
			if dd < best:
				best = dd
				_sh_center = p
	if best == INF:
		_sh_center = _start


func _shield_index() -> int:
	var h = game.horde
	for i in h.count:
		if h.uid[i] == _sh_uid and h.dead[i] == 0:
			return i
	return -1


func _shield_step(delta: float) -> void:
	var h = game.horde
	var i := _shield_index()
	if _sh_case < 0 or i < 0 or _sh_t >= 21.0:
		if _sh_case >= 0:
			_shield_report()
		_sh_case += 1
		if _sh_case >= _radii.size() * _speeds.size():
			get_tree().quit()
			return
		h.despawn_far(Vector2.ZERO, 0.0)
		var z: Vector2 = game.obstacles.free_point(_sh_center, 6.0)
		var idx: int = h.spawn(z, Horde.Kind.RIOT, false)
		_sh_uid = h.uid[idx]
		h.angle[idx] = 0.0 # смотрит на игрока, стоящего справа
		_sh_theta = 0.0
		_sh_t = 0.0
		_sh_first = -1.0
		_sh_open = 0.0
		_sh_off_sum = 0.0
		_sh_off_n = 0.0
		i = idx
	var r: float = _radii[_sh_case % _radii.size()]
	var v: float = _speeds[_sh_case / _radii.size()]
	var zp: Vector2 = h.pos[i]
	_sh_theta += v / r * delta
	game.player.position = zp + Vector2.from_angle(_sh_theta) * r
	_sh_t += delta
	if _sh_t < 1.0:
		return
	var to: Vector2 = game.player.position - zp
	var off := absf(angle_difference(h.angle[i], to.angle()))
	_sh_off_sum += off
	_sh_off_n += 1.0
	if cos(off) < SHIELD_COS:
		_sh_open += delta
		if _sh_first < 0.0:
			_sh_first = _sh_t


func _shield_report() -> void:
	var r: float = _radii[_sh_case % _radii.size()]
	var v: float = _speeds[_sh_case / _radii.size()]
	var rec := {"R": r, "player_speed": v, "omega": snappedf(v / r, 0.01), "turn_rate": 0.85, "first_open_s": snappedf(_sh_first, 0.1),
		"open_share_pct": snappedf(100.0 * _sh_open / 20.0, 0.1), "mean_offset_deg": snappedf(rad_to_deg(_sh_off_sum / maxf(_sh_off_n, 1.0)), 0.1)}
	print("ZAI1P shield ", JSON.stringify(rec))


# ---------------------------------------------------------------- watch: серии по окнам

var WT := {}
var _win := 10.0
var _win_end := 0.0
var _node_rate := 0.0
var _dmg0 := 0.0
var _kills0 := 0


func _watch_init() -> void:
	_win = float(_arg("--win", "60" if _sim else "10"))
	_win_end = floorf(game.time / _win) * _win + _win
	_node_rate = float(_arg("--node-rate", "0"))
	_dmg0 = game.player.damage_taken
	_kills0 = game.kills
	_watch_reset()
	game.horde.enemy_died.connect(_on_watch_died)


func _watch_reset() -> void:
	for key in ["n", "alive", "r90", "r90_any", "r150", "onscreen", "kills_off", "kills_all", "exclusive", "nearest"]:
		WT[key] = 0.0


func _on_watch_died(at: Vector2, _kind: int, _elite: bool) -> void:
	WT["kills_all"] += 1.0
	if not _screen().has_point(at):
		WT["kills_off"] += 1.0


func _watch_step(delta: float) -> void:
	var node_alive: bool = game.objective != null and game.boss.is_alive()
	if _node_rate > 0.0 and node_alive and _t > 1.0:
		game.boss.take_damage(game.boss.max_hp * _node_rate / 60.0 * delta, Vector2.ZERO, game.boss.global_position)
	if _tick % 30 == 0:
		var h = game.horde
		var pp: Vector2 = game.player.global_position
		var view := _screen()
		var r90 := 0
		var nearest := INF
		for i in h.count:
			if h.dead[i] == 1:
				continue
			var d: float = h.pos[i].distance_to(pp)
			nearest = minf(nearest, d)
			WT["alive"] += 1.0
			if d < 90.0:
				r90 += 1
			if d < 150.0:
				WT["r150"] += 1.0
			if view.has_point(h.pos[i]):
				WT["onscreen"] += 1.0
		WT["r90"] += r90
		WT["r90_any"] += 1.0 if r90 > 0 else 0.0
		WT["nearest"] += minf(nearest, 2000.0)
		WT["exclusive"] += 1.0 if game.spawner.director_exclusive else 0.0
		WT["n"] += 1.0
	if game.time >= _win_end:
		var n: float = maxf(WT["n"], 1.0)
		var d: HordeDirector = game.spawner.director
		var rec := {"t": int(_win_end), "alive": snappedf(WT["alive"] / n, 0.1), "r90": snappedf(WT["r90"] / n, 0.1),
			"r90_any_pct": snappedf(100.0 * WT["r90_any"] / n, 1), "r150": snappedf(WT["r150"] / n, 0.1),
			"onscreen": snappedf(WT["onscreen"] / n, 0.1), "nearest": int(WT["nearest"] / n),
			"kills": int(WT["kills_all"]), "kill_off_pct": snappedf(100.0 * WT["kills_off"] / maxf(WT["kills_all"], 1.0), 0.1),
			"dmg": snappedf(game.player.damage_taken - _dmg0, 0.1), "exclusive_pct": snappedf(100.0 * WT["exclusive"] / n, 1),
			"phase": HordeDirector.PHASES[d.phase] if d else "-", "level": game.progression.level}
		if game.objective != null:
			rec["node_hp"] = snappedf(game.boss.hp_fraction(), 0.01) if game.boss.is_alive() else 0.0
			rec["pressure"] = snappedf(game.spawner.node_pressure, 0.01)
		print("ZAI1P watch ", JSON.stringify(rec))
		_dmg0 = game.player.damage_taken
		_win_end += _win
		_watch_reset()
	if not _sim and _t >= _dur:
		get_tree().quit()
