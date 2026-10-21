class_name CrowdTest
extends RefCounted
## --crowd-test (ZAI2): поведение толпы на настоящих картах. Орда и поле шагаются вручную, без окна и потоков —
## детерминированно и быстро, как --pathing-test. Метрики считаются только по позициям, поэтому не зависят от
## устройства движения. Сценарии:
##   jam   — давка у стоящего игрока без оружия: рывки, пинг-понг у героя, дрожание курса, перекрытия;
##   move  — игрок бежит кругами: стоящие, взгляд против курса, окружение, скольжение по кольцу, бегуны;
##   start — пустая карта, зомби из обычной точки появления: время до контакта, дистанция, «из воздуха», колонны у стен;
##   far   — игрок бежит по большому кругу: доля отставших дальше 800 px.
## Пороги включаются по задачам (LIMITS); остальные строки печатаются для отчёта.

const DT := 1.0 / 60.0
const MAPS := ["open_perimeter", "old_town"]
# Порог: [метрика, сравнение, значение, задача]. Задача — с какой ZAI порог обязателен.
# Исходные значения main 2026-10-21 — в комментариях (open_perimeter / old_town).
const LIMITS := [
	["spawn_view", "<=", 0.0, "ZAI2"], # 0 / 0
	["penetrations", "<=", 0.0, "ZAI2"], # 0
	["move_stall_pct", "<=", 12.0, "ZAI2"], # 9,3 / 5,8 — защита от регресса до ZAI4
	["start_ttc_p50", "<=", 10.0, "ZAI3"], # 20,1 / 27,5
	["far_pct", "<=", 5.0, "ZAI3"], # 4,7 / 7,7
	# ZAI4 — давка у стоящего игрока без оружия (до ZAI4 → после, open_perimeter / old_town)
	["jam_dv_p90", "<=", 1.5, "ZAI4"], # 4,4 / 4,1 → 0,06 / 0,06 px
	["jam_path_net_p50", "<=", 1.3, "ZAI4"], # 2,46 / 2,53 → 1,12 / 1,13
	["jam_inner_flip_pct", "<=", 10.0, "ZAI4"], # 49,9 / 51,0 → 0 / 0 (пинг-понг у героя)
	["jam_inner_step_p90", "<=", 2.0, "ZAI4"], # 7,3 / 6,9 → 0,04 шага
	["jam_rev_pct", "<=", 2.0, "ZAI4"], # 38,4 / 39,1 → 0,6 / 0,0
	["jam_turn_deg", "<=", 15.0, "ZAI4"], # 94 / 95 → 9,9 / 10,0
	["jam_deep_pct", "<=", 3.0, "ZAI4"], # 13,3 / 12,4 → 0 / 0
	["jam_ovl", "<=", 0.12, "ZAI4"], # 0,189 / 0,181 → 0,093 / 0,074
	["move_face_bad_pct", "<=", 8.0, "ZAI4"], # 16,6 / 14,5 → 6,3 / 4,5
	# ZAI5 — видимость в поле, штраф у длинных стен (до ZAI5 → после)
	["move_mode_back_pct", "<=", 0.3, "ZAI5"], # 0,19 / 0,55 → 0,06 / 0,17 (смена режима, отменённая за 0,5 с)
	["far_mode_back_pct", "<=", 0.3, "ZAI5"], # 0,17 / 0,29 → 0,14 / 0,07
	["start_long_x", "<=", 1.5, "ZAI5"], # 0 / 0 → 0 / 0 (у домов и заборов к равномерной толпе; машины — PF1, вплотную)
	# ZAI6 — группы со старта и сигнализация (только old_town: на open_perimeter нет легковушек)
	["senses_calm_moved", "<=", 80.0, "ZAI6"], # спокойная группа за 3 с не уходит дальше 80 px от места
	["senses_wake_s", ">=", 0.0, "ZAI6"], # -1 — не проснулась за 2 с
	["senses_wake_s", "<=", 1.0, "ZAI6"],
	["senses_noise_woken", ">=", 1.0, "ZAI6"], # выстрел будит всю группу в радиусе
	["senses_lured_pct", ">=", 60.0, "ZAI6"], # вой увёл большинство преследующих (кроме бегунов и тех, кто у игрока)
	["senses_lure_closer_pct", ">=", 60.0, "ZAI6"], # и за 6 с воя подошли к машине на четверть пути (или встали у неё)
	["senses_released_pct", ">=", 95.0, "ZAI6"], # после воя снова преследуют
	["boss_reached_pct", ">=", 90.0, "ZAI6"], # босс (18 px) из-за дома: до ZAI6 37–50 % (стенд zai1_probe --probe=boss)
	["boss_stuck_pct", "<=", 10.0, "ZAI6"], # было 31–45 % времени
	["shield_open_s_120", "<=", 4.0, "ZAI6"], # фланг щита на R 120 px при 80 px/с: было 7,7 с
	["shield_open_s_150", "<=", 4.0, "ZAI6"], # на R 150 px: было «никогда»
]
const ACTIVE := ["ZAI2", "ZAI3", "ZAI4", "ZAI5", "ZAI6"]

var game
var horde: Horde
var obstacles: Obstacles
var player: Player
var checks := 0
var failed := 0
var penetrations := 0
var _map := ""
var _scenario := ""
var _tick := 0
var _counting := false
var _rng := RandomNumberGenerator.new()
# снимки тика (horde.tick_probe)
var _s0 := PackedVector2Array()
var _a1 := PackedVector2Array()
var _c1 := PackedVector2Array()
var _ch0 := PackedFloat32Array()
var _fr0 := PackedFloat32Array()
# по индексу особи: uid, прошлое смещение за тик, окно 0,1 с
var _uid := PackedInt32Array()
var _prev := PackedVector2Array()
var _prev_ok := PackedByteArray()
var _w_start := PackedVector2Array()
var _w_path := PackedFloat32Array()
var _w_n := PackedInt32Array()
var _w_head := PackedFloat32Array()
var _w_head_ok := PackedByteArray()
var _prev_rad := PackedFloat32Array()
var M := {}


func run(owner_game) -> int:
	game = owner_game
	horde = game.horde
	obstacles = game.obstacles
	player = game.player
	horde.tick_probe = _probe
	# --crowd-only=<сценарий> — для итераций; проверка в full гоняет все.
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--crowd-only="):
			only = arg.trim_prefix("--crowd-only=")
	for map_id: String in MAPS:
		for scenario in ["jam", "move", "start", "far"]:
			if only == "" or only == scenario:
				await _scenario_run(map_id, scenario)
		if (only == "" or only == "senses") and map_id == "old_town":
			await _senses_run(map_id)
		if (only == "" or only == "boss") and map_id == "old_town":
			await _boss_run(map_id)
		if (only == "" or only == "shield") and map_id == "open_perimeter":
			await _shield_run(map_id)
	horde.tick_probe = Callable()
	_check("penetrations", penetrations)
	print("CROWDTEST checks=%d failed=%d penetrations=%d active=%s ok=%s" % [checks, failed, penetrations, ",".join(ACTIVE), failed == 0])
	return failed


func _scenario_run(map_id: String, scenario: String) -> void:
	_map = map_id
	_scenario = scenario
	var data := MapLoader.load_map(map_id)
	var rect := Rect2(Vector2.ZERO, data["size"])
	obstacles.setup(rect, MapLoader.layout(data, 81073))
	horde.setup(rect, player, null)
	horde.map_entries = data["spawn_points"]
	horde.count = 0
	horde.minutes = 6.0
	horde.reset_variety_seed(81073)
	seed(81073)
	_rng.seed = hash(map_id + scenario)
	var start := obstacles.free_point(data["start"], 8.0)
	player.position = start
	_follow()
	game._pathing_warm(5.0, player.position)
	M = {}
	_modes = {}
	_mode_flip_t = {}
	_counting = false
	_tick = 0
	var duration := 50.0
	var warm := 30.0
	match scenario:
		"jam":
			_ring(300, 150.0, 420.0)
		"move":
			_ring(200, 200.0, 450.0)
			duration = 45.0
			warm = 20.0
		"start":
			duration = 60.0
			warm = 0.0
		"far":
			duration = 60.0
			warm = 30.0
	var ticks := int(duration / DT)
	var spawned := 0
	for tick in ticks:
		_tick = tick
		var t := tick * DT
		_counting = t >= warm
		match scenario:
			"move":
				var want := start + Vector2(cos(t * 0.35), sin(t * 0.35)) * 170.0
				player.position = obstacles.move_actor(player.position, want, 6.0)
			"far":
				var want := start + Vector2(cos(t * 0.3), sin(t * 0.3)) * 260.0
				player.position = obstacles.move_actor(player.position, want, 6.0)
		if scenario == "start" and t < 20.0 and tick % 40 == 0:
			_spawn_tracked(Horde.Kind.SHAMBLER, t)
			spawned += 1
		if scenario == "far" and tick % 15 == 0 and horde.count < 250:
			_spawn_tracked(Horde.Kind.SHAMBLER if spawned % 5 else Horde.Kind.RUNNER, t)
			spawned += 1
		if tick % 6 == 0:
			_follow()
		obstacles.navigation_step(DT, player.position)
		horde._physics_process(DT)
		if tick % 6 == 5:
			_mode_sample()
		if tick % 30 == 29:
			_slow_sample(t)
			for i in horde.count:
				if horde.dead[i] == 0 and obstacles.contains(horde.pos[i], horde.radius[i] - 0.04):
					penetrations += 1
		if tick % 300 == 299:
			await game.get_tree().process_frame
	_report()


## ZAI6 (4В): группы на карте и сигнализация. Спокойная группа вне WAKE_R не просыпается и не уходит от места;
## игрок на виду ближе WAKE_R будит её за ≤ 1 с; выстрел будит группу в радиусе шума; вой машины уводит к ней
## преследующих дальше LURE_KEEP, после воя они снова идут к игроку.
func _senses_run(map_id: String) -> void:
	_map = map_id
	_scenario = "senses"
	var data := MapLoader.load_map(map_id)
	var rect := Rect2(Vector2.ZERO, data["size"])
	obstacles.setup(rect, MapLoader.layout(data, 81073))
	horde.setup(rect, player, null)
	horde.map_entries = data["spawn_points"]
	horde.count = 0
	horde.minutes = 6.0
	horde.senses = true
	horde.reset_variety_seed(81073)
	seed(81073)
	M = {}
	var start := obstacles.free_point(data["start"], 8.0)
	player.position = start
	_follow()
	game._pathing_warm(5.0, player.position)
	# Открытое место для группы: ближайшая к старту видимая клетка в 400 px.
	var place := Vector2.INF
	for k in 64:
		var q := obstacles.free_point(start + Vector2.from_angle(k * TAU / 64.0) * 400.0, 12.0)
		if q.distance_to(start) > 360.0 and obstacles.sees_target(q, 5.0):
			place = q
			break
	var r := {"senses_calm_moved": -1.0, "senses_wake_s": -1.0, "senses_noise_woken": -1.0, "senses_lured_pct": -1.0,
		"senses_lure_closer_pct": -1.0, "senses_released_pct": -1.0}
	if place != Vector2.INF:
		horde.poi = PackedVector2Array([place])
		var n := horde.spawn_idle_groups(start + (start - place).normalized() * 200.0)
		_senses_steps(180)
		var calm := 0
		var moved := 0.0
		for i in horde.count:
			calm += 1 if horde.mind[i] == Horde.Mind.WANDER else 0
			moved = maxf(moved, horde.pos[i].distance_to(place))
		r["senses_calm_moved"] = snappedf(moved, 0.1) if calm == n else 999.0
		# Игрок подходит на 200 px по открытому — группа просыпается.
		player.position = obstacles.free_point(place + (start - place).normalized() * 200.0, 8.0)
		_follow()
		game._pathing_warm(5.0, player.position)
		for t in 120:
			_senses_steps(1)
			var left := 0
			for i in horde.count:
				left += 1 if horde.mind[i] != Horde.Mind.CHASE else 0
			if left == 0:
				r["senses_wake_s"] = snappedf((t + 1) / 60.0, 0.01)
				break
		# Выстрел будит вторую группу в радиусе шума.
		horde.count = 0
		player.position = start
		_follow()
		game._pathing_warm(5.0, player.position)
		horde.poi = PackedVector2Array([place])
		n = horde.spawn_idle_groups(start + (start - place).normalized() * 200.0)
		horde.noise(start, start.distance_to(place) + 40.0)
		var woke := 0
		for i in horde.count:
			woke += 1 if horde.mind[i] == Horde.Mind.CHASE else 0
		r["senses_noise_woken"] = float(woke) / maxf(n, 1.0)
	# Сигнализация: целая легковушка, ближайшая к старту; игрок в 350 px от неё, 40 преследующих вокруг игрока
	# в 200–500 px.
	horde.count = 0
	var car := -1
	var car_d := INF
	for i in obstacles.count:
		if obstacles.kind[i] < Obstacles.Kind.TRUCK and obstacles.state[i] == Obstacles.State.INTACT and obstacles.pos[i].distance_to(start) < car_d:
			car = i
			car_d = obstacles.pos[i].distance_to(start)
	if car >= 0:
		var away := (start - obstacles.pos[car]).normalized() if car_d > 1.0 else Vector2.RIGHT
		player.position = obstacles.free_point(obstacles.pos[car] + away * 350.0, 8.0)
		_follow()
		game._pathing_warm(5.0, player.position)
		_ring(40, 200.0, 500.0)
		var at := obstacles.pos[car]
		var d0 := PackedFloat32Array()
		for i in horde.count:
			d0.append(horde.pos[i].distance_to(at))
		obstacles.damage(car, 1.0)
		_senses_steps(360)
		var eligible := 0
		var lured := 0
		var closer := 0
		for i in horde.count:
			if horde.kind[i] == Horde.Kind.RUNNER or d0[i] > Obstacles.ALARM_LURE:
				continue
			eligible += 1
			if horde.mind[i] == Horde.Mind.LURE:
				lured += 1
				closer += 1 if horde.pos[i].distance_to(at) < d0[i] * 0.75 or horde.pos[i].distance_to(at) < Horde.LURE_STOP + 12.0 else 0
		r["senses_lured_pct"] = snappedf(100.0 * lured / maxf(eligible, 1.0), 0.1)
		r["senses_lure_closer_pct"] = snappedf(100.0 * closer / maxf(lured, 1.0), 0.1)
		_senses_steps(int((Obstacles.ALARM_TIME + Horde.LURE_HOLD - 6.0 + 1.0) * 60.0))
		var chase := 0
		for i in horde.count:
			chase += 1 if horde.mind[i] == Horde.Mind.CHASE else 0
		r["senses_released_pct"] = snappedf(100.0 * chase / maxf(horde.count, 1.0), 0.1)
	print("CROWDTEST map=%s scenario=senses %s" % [map_id, JSON.stringify(r)])
	for key in r:
		_check(key, r[key])
	horde.count = 0
	await game.get_tree().process_frame


## ZAI6 (З5): ходьба босса (BossBase._walk_point, тело 18 px, 40 px/с) из-за дома: пары 220–380 px, прямая
## перекрыта. Доходит — ближе 33 px за 1,5 × время по кратчайшему пути для тела + 5 с; «стоит» — сдвиг < 4 px за
## 0,5 с дальше 53 px.
func _boss_run(map_id: String) -> void:
	_map = map_id
	_scenario = "boss"
	var data := MapLoader.load_map(map_id)
	var rect := Rect2(Vector2.ZERO, data["size"])
	obstacles.setup(rect, MapLoader.layout(data, 81073))
	horde.count = 0
	var walker := BossBase.new()
	walker.obstacles = obstacles
	game.add_child(walker)
	var rng := RandomNumberGenerator.new()
	rng.seed = 81073
	var r := walker.move_radius()
	var trials := 0
	var reached := 0
	var stuck := 0.0
	var total := 0.0
	var area := obstacles.arena.grow(-160.0)
	for trial in 12:
		var p := Vector2.INF
		var b := Vector2.INF
		for attempt in 400:
			var pp: Vector2 = obstacles.free_point(area.position + Vector2(rng.randf(), rng.randf()) * area.size, 8.0)
			var bb: Vector2 = obstacles.free_point(pp + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(220.0, 380.0), r + 2.0)
			var dist := pp.distance_to(bb)
			if dist >= 200.0 and dist <= 400.0 and obstacles.arena.grow(-r - 4.0).has_point(bb) and not obstacles.line_clear(bb, pp):
				p = pp
				b = bb
				break
		if p == Vector2.INF:
			continue
		trials += 1
		walker.global_position = b
		walker._path = PackedVector2Array()
		walker._path_cd = 0.0
		# Предел — по длине кратчайшего пути для тела, а не по прямой: обход квартала бывает втрое длиннее.
		var plen := 0.0
		var prev := b
		for q in obstacles.big_path(b, p, r):
			plen += prev.distance_to(q)
			prev = q
		var limit := 1.5 * maxf(plen - 33.0, 0.0) / 40.0 + 5.0
		var last := b
		var t := 0.0
		while t < limit:
			var before := walker.global_position
			walker.global_position = obstacles.move_actor(before, walker._walk_point(p, 40.0 * DT, DT), r)
			t += DT
			if fmod(t, 0.5) < DT:
				total += 0.5
				if walker.global_position.distance_to(last) < 4.0 and walker.global_position.distance_to(p) > 53.0:
					stuck += 0.5
				last = walker.global_position
			if walker.global_position.distance_to(p) <= 33.0:
				reached += 1
				break
		if OS.get_cmdline_user_args().has("--crowd-debug"):
			print("CROWDDEBUG boss d0=%.0f path=%.0f t=%.1f limit=%.1f end=%.0f" % [b.distance_to(p), plen, t, limit, walker.global_position.distance_to(p)])
	walker.queue_free()
	var res := {"boss_trials": float(trials), "boss_reached_pct": snappedf(100.0 * reached / maxf(trials, 1.0), 0.1),
		"boss_stuck_pct": snappedf(100.0 * stuck / maxf(total, 0.5), 0.1), "boss_searches": float(obstacles.big_calls)}
	print("CROWDTEST map=%s scenario=boss %s" % [map_id, JSON.stringify(res)])
	for key in res:
		_check(key, res[key])
	await game.get_tree().process_frame


## ZAI6 (С8): щитовик (бессмертный) стоит, игрок кружит на R со скоростью 80 px/с и стреляет в него 6 раз в
## секунду (удар в щит — упор SHIELD_BRACE). Время до первого захода во фланг (вне дуги щита).
func _shield_run(map_id: String) -> void:
	_map = map_id
	_scenario = "shield"
	var data := MapLoader.load_map(map_id)
	var rect := Rect2(Vector2.ZERO, data["size"])
	obstacles.setup(rect, MapLoader.layout(data, 81073))
	horde.setup(rect, player, null)
	horde.senses = false
	var center := obstacles.free_point(data["start"], 8.0)
	var best := INF
	for c in obstacles.obstacle_distance.size():
		if obstacles.obstacle_distance[c] >= 40.0 and obstacles.cell_center(c).distance_to(data["start"]) < best:
			var q := obstacles.cell_center(c)
			var open := true
			for k in 8:
				if obstacles.contains(q + Vector2.from_angle(k * TAU / 8.0) * 150.0, 8.0):
					open = false
					break
			if open:
				best = q.distance_to(data["start"])
				center = q
	var res := {}
	for radius_px: float in [120.0, 150.0]:
		horde.count = 0
		var i := horde.spawn(center, Horde.Kind.RIOT)
		horde.hp[i] = 1.0e6
		horde.max_hp[i] = 1.0e6
		horde.armor_shield[i] = 1.0e6
		horde.speed[i] = 0.0 # стоит: меряем только поворот щита
		horde.angle[i] = 0.0
		var theta := 0.0
		var first := -1.0
		var t := 0.0
		var shot := 0.0
		while t < 8.0:
			theta += 80.0 / radius_px * DT
			player.position = horde.pos[i] + Vector2.from_angle(theta) * radius_px
			horde._physics_process(DT)
			t += DT
			shot += DT
			if shot >= 1.0 / 6.0:
				shot = 0.0
				var dir := (horde.pos[i] - player.position).normalized()
				horde.damage(i, 1.0, dir, 0.0, WeaponDefs.Ammo.STANDARD, false, horde.pos[i] - dir * horde.radius[i])
			var off := absf(angle_difference(horde.angle[i], (player.position - horde.pos[i]).angle()))
			if t > 0.5 and cos(off) < 0.35 and first < 0.0:
				first = t
				break
		res["shield_open_s_%d" % int(radius_px)] = snappedf(first if first >= 0.0 else 99.0, 0.01)
	horde.count = 0
	horde.senses = true
	print("CROWDTEST map=%s scenario=shield %s" % [map_id, JSON.stringify(res)])
	for key in res:
		_check(key, res[key])
	await game.get_tree().process_frame


func _senses_steps(ticks: int) -> void:
	for t in ticks:
		obstacles.navigation_step(DT, player.position)
		obstacles._update_alarms(DT)
		horde._physics_process(DT)


func _follow() -> void:
	game.camera.position = player.position
	game.camera.force_update_scroll()


## Кольцо особей вокруг игрока (смесь как в 6:00: шаркуны, бегуны, толстяки).
func _ring(n: int, r0: float, r1: float) -> void:
	for j in n:
		var k := Horde.Kind.SHAMBLER
		if j % 7 == 3:
			k = Horde.Kind.RUNNER
		elif j % 20 == 11:
			k = Horde.Kind.FAT
		var at := player.position + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(r0, r1)
		horde.spawn(obstacles.free_point(at.clamp(horde.arena.position + Vector2.ONE * 24.0, horde.arena.end - Vector2.ONE * 24.0), 6.0), k)


func _spawn_tracked(k: int, t: float) -> void:
	var at := horde.spawn_point(player.position)
	var view := PixelArt.view_rect(horde, 0.0)
	var i := horde.spawn(at, k)
	if i < 0:
		return
	_add("spawn_n", 1.0)
	if view.has_point(horde.pos[i]):
		_add("spawn_view", 1.0)
	_list("spawn_d").append(horde.pos[i].distance_to(player.position))
	M["born_%d" % horde.uid[i]] = t


func _add(key: String, v: float) -> void:
	M[key] = float(M.get(key, 0.0)) + v


func _list(key: String) -> PackedFloat32Array:
	if not M.has(key):
		M[key] = PackedFloat32Array()
	return M[key]


func _append(key: String, v: float) -> void:
	var a: PackedFloat32Array = _list(key)
	a.append(v)
	M[key] = a


## Снимки внутри тика орды: 0 — до шага, 1 — после шага (с выталкиванием игроком), 2 — после разделения, 3 — итог.
func _probe(stage: int) -> void:
	match stage:
		0:
			_s0 = horde.pos.duplicate()
			_ch0 = horde.chill.duplicate()
			_fr0 = horde.freeze_t.duplicate()
		1:
			_a1 = horde.pos.duplicate()
		2:
			_c1 = horde.pos.duplicate()
		3:
			_fast_sample()


func _fast_sample() -> void:
	var cap := horde.pos.size()
	if _uid.size() != cap:
		for a in [_uid, _prev_ok, _w_head_ok]:
			a.resize(cap)
		_uid.fill(-1)
		for a in [_prev, _w_start]:
			a.resize(cap)
		for a in [_w_path, _w_head, _prev_rad]:
			a.resize(cap)
		_w_n.resize(cap)
	if _s0.size() != cap or _a1.size() != cap or _c1.size() != cap:
		return
	var pp := player.global_position
	var window := _tick % 6 == 5
	if _counting:
		_add("tick_n", 1.0)
	for i in horde.count:
		if horde.dead[i] == 1:
			continue
		var s: Vector2 = _s0[i]
		var f: Vector2 = horde.pos[i]
		var total := f - s
		if _uid[i] != horde.uid[i]:
			_uid[i] = horde.uid[i]
			_prev_ok[i] = 0
			_w_head_ok[i] = 0
			_w_start[i] = s
			_w_path[i] = 0.0
			_w_n[i] = 0
			_prev_rad[i] = 0.0
		var d0 := s.distance_to(pp)
		var nominal: float = horde.speed[i] * (1.0 - _ch0[i]) * DT
		var frozen := _fr0[i] > 0.0
		_w_path[i] += total.length()
		_w_n[i] += 1
		if _counting and not frozen and d0 > 0.01:
			var out := (s - pp) / d0
			var touch: float = Player.RADIUS + horde.radius[i]
			if d0 < touch + 3.0:
				# кольцо касания: смена знака радиального смещения — пинг-понг «наружу/внутрь»
				var rad := total.dot(out)
				_add("inner_n", 1.0)
				_append("inner_step", total.length() / maxf(nominal, 0.0001))
				if _prev_ok[i] == 1 and absf(rad) > 0.3 and absf(_prev_rad[i]) > 0.3 and signf(rad) != signf(_prev_rad[i]):
					_add("inner_flip", 1.0)
				_prev_rad[i] = rad
			elif d0 >= 12.0 and d0 <= 80.0:
				_add("band_n", 1.0)
				if _prev_ok[i] == 1:
					_append("dv", (total - _prev[i]).length())
				_add("sep_sum", (_c1[i] - _a1[i]).length())
				_add("nom_sum", nominal)
		_prev[i] = total
		_prev_ok[i] = 1
		if window:
			if _w_n[i] == 6 and not frozen:
				var net := _w_start[i].distance_to(f)
				var moving := net >= 0.3 * nominal * 6.0 and nominal > 0.0
				if _counting and d0 >= 12.0 and d0 <= 80.0 and net > 0.05:
					_append("path_net", _w_path[i] / net)
				if moving and d0 >= 14.0 and d0 <= 500.0:
					var head := (f - _w_start[i]).angle()
					if _counting:
						var fd := absf(angle_difference(horde.angle[i], head))
						_add("face_n", 1.0)
						if fd > PI * 0.25:
							_add("face_bad", 1.0)
						if _w_head_ok[i] == 1:
							var turn := absf(angle_difference(_w_head[i], head))
							_add("turn_n", 1.0)
							_add("turn_sum", rad_to_deg(turn))
							if turn > PI * 0.667:
								_add("turn_rev", 1.0)
					_w_head[i] = head
					_w_head_ok[i] = 1
				else:
					_w_head_ok[i] = 0
			_w_start[i] = f
			_w_path[i] = 0.0
			_w_n[i] = 0


var _modes := {} # uid → режим прошлого замера (1 — прямо, 2 — по полю)
var _mode_flip_t := {} # uid → время последней смены режима
var _p05 := {}


## ZAI5: режим «прямо / по полю» раз в 0,1 с у особей дальше 90 px — доля смен между соседними замерами.
func _mode_sample() -> void:
	var pp := player.global_position
	var cur := {}
	for i in horde.count:
		if horde.dead[i] == 1 or horde.pos[i].distance_to(pp) <= 90.0:
			continue
		var u: int = horde.uid[i]
		var m := 1 if horde.steer[i] == Vector2.ZERO else 2
		cur[u] = m
		if _counting and _modes.has(u):
			_add("mode_n", 1.0)
			if int(_modes[u]) != m:
				_add("mode_flip", 1.0)
				# Мельтешение: смена режима, отменённая быстрее 0,5 с.
				if _mode_flip_t.has(u) and _tick * DT - float(_mode_flip_t[u]) < 0.5:
					_add("mode_back", 1.0)
				_mode_flip_t[u] = _tick * DT
				if OS.get_cmdline_user_args().has("--crowd-debug"):
					var q: Vector2 = horde.pos[i]
					var c := obstacles.cell_at(q)
					_add("dbg_flip_d%d" % mini(int(q.distance_to(pp) / 100.0), 7), 1.0)
					_add("dbg_flip_od%d" % mini(int(obstacles.obstacle_distance[c] / 4.0), 5), 1.0)
					_add("dbg_flip_to%d" % m, 1.0)
					var k := obstacles.radius_class(horde.radius[i])
					var los: PackedByteArray = obstacles._nav_layers[k]["los"]
					_add("dbg_flip_los%d" % (los[c] if c < los.size() else 9), 1.0)
					var dist: PackedInt32Array = obstacles._nav_layers[k]["distance"]
					_add("dbg_flip_nopath", 1.0 if c >= dist.size() or dist[c] == Obstacles.NO_PATH else 0.0)
	_modes = cur


func _slow_sample(t: float) -> void:
	var pp := player.global_position
	var cur := {}
	var sectors := PackedByteArray()
	sectors.resize(16)
	var view := PixelArt.view_rect(horde, 0.0)
	var alive := 0
	var far := 0
	for i in horde.count:
		if horde.dead[i] == 1:
			continue
		alive += 1
		var u: int = horde.uid[i]
		var q: Vector2 = horde.pos[i]
		cur[u] = q
		var d := q.distance_to(pp)
		if d > 800.0 and not view.has_point(q):
			far += 1
		if d < 40.0:
			sectors[int(fposmod((q - pp).angle(), TAU) / TAU * 16.0) % 16] = 1
		if M.has("born_%d" % u) and not M.has("met_%d" % u) and d < 40.0:
			M["met_%d" % u] = true
			_append("ttc", t - float(M["born_%d" % u]))
		if not _counting or not _p05.has(u) or horde.freeze_t[i] > 0.0:
			continue
		var v: Vector2 = (q - _p05[u]) / 0.5
		var to := (pp - q) / maxf(d, 0.01)
		var nominal: float = maxf(horde.speed[i] * (1.0 - horde.chill[i]), 1.0)
		if d > 45.0 and d < 500.0:
			_add("stall_n", 1.0)
			if v.dot(to) < 5.0:
				_add("stall", 1.0)
				if OS.get_cmdline_user_args().has("--crowd-debug"):
					_add("dbg_blocked" if horde._block[i] < horde.speed[i] * 0.5 else "dbg_free", 1.0)
					_add("dbg_d%d" % mini(int(d / 50.0), 9), 1.0)
					_add("dbg_vlen%d" % mini(int(v.length() / 5.0), 9), 1.0)
					_add("dbg_kind%d" % horde.kind[i], 1.0)
					_add("dbg_sum_block", minf(horde._block[i], 100.0))
					_add("dbg_sum_want", horde.want_v[i].length())
					_add("dbg_sum_wantdot", horde.want_v[i].dot(to))
					_add("dbg_sum_vel", horde.vel[i].length())
					_add("dbg_sum_veldot", horde.vel[i].dot(to))
					_add("dbg_sum_sep", horde._sep_v[i].length())
					_add("dbg_sum_sepdot", horde._sep_v[i].dot(to))
					_add("dbg_sum_spd", horde.speed[i])
					_add("dbg_steer", 1.0 if horde.steer[i] != Vector2.ZERO else 0.0)
			if horde.kind[i] == Horde.Kind.RUNNER:
				_add("runner_n", 1.0)
				_add("runner_eff", v.dot(to) / nominal)
				if OS.get_cmdline_user_args().has("--crowd-debug"):
					var b := "dbg_r_d%d" % mini(int(d / 100.0), 4)
					_add(b + "_n", 1.0)
					_add(b + "_eff", v.dot(to) / nominal)
					_add(b + "_spd", v.length() / nominal)
					_add(b + "_steer", 1.0 if horde.steer[i] != Vector2.ZERO else 0.0)
					_add(b + "_sepdot", horde._sep_v[i].dot(to) / nominal)
					_add(b + "_wantdot", horde.want_v[i].dot(to) / nominal)
		if d >= 12.0 and d < 80.0:
			_add("ring_n", 1.0)
			_add("ring_rad", absf(v.dot(to)))
			_add("ring_tan", absf(v.dot(to.orthogonal())))
		if d >= 90.0 and d <= 600.0 and v.length() >= 0.3 * nominal:
			_add("wall_n", 1.0)
			var c := obstacles.cell_at(q)
			if obstacles.obstacle_distance[c] < 16.0 and obstacles.obstacle_distance[obstacles.cell_at(q + obstacles.wall_normal[c] * 24.0)] >= 28.0:
				_add("wall_hug", 1.0)
				_add("wall_hug_long", float(obstacles.long_wall[c]))
		if d < 200.0:
			for j in horde.query_radius(q, horde.radius[i]):
				if j == i:
					continue
				var min_d: float = horde.radius[i] + horde.radius[j]
				var pen: float = (min_d - q.distance_to(horde.pos[j])) / min_d
				if pen > 0.0:
					_add("ovl_sum", pen)
					_add("ovl_n", 1.0)
					if pen > 0.4:
						_add("ovl_deep", 1.0)
	_p05 = cur
	if _counting:
		var covered := 0
		for s in sectors:
			covered += s
		_add("cover_sum", covered / 16.0)
		_add("samples", 1.0)
		_add("alive_sum", alive)
		_add("far_sum", far)
		# та же классификация «у стены» для случайных проходимых точек кольца 90–600 px
		for k in 200:
			var q := pp + Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf_range(8100.0, 360000.0))
			if not obstacles.arena.has_point(q):
				continue
			var c := obstacles.cell_at(q)
			if obstacles.obstacle_distance[c] < 6.0:
				continue
			_add("area_n", 1.0)
			if obstacles.obstacle_distance[c] < 16.0 and obstacles.obstacle_distance[obstacles.cell_at(q + obstacles.wall_normal[c] * 24.0)] >= 28.0:
				_add("area_hug", 1.0)
				_add("area_hug_long", float(obstacles.long_wall[c]))


func _quant(key: String, q: float) -> float:
	if not M.has(key):
		return -1.0
	var s: PackedFloat32Array = (M[key] as PackedFloat32Array).duplicate()
	if s.is_empty():
		return -1.0
	s.sort()
	return s[clampi(int(q * (s.size() - 1)), 0, s.size() - 1)]


func _ratio(num: String, den: String, scale := 1.0) -> float:
	return scale * float(M.get(num, 0.0)) / maxf(float(M.get(den, 0.0)), 1.0)


func _report() -> void:
	var line := ""
	match _scenario:
		"jam":
			var r := {"band": snappedf(_ratio("band_n", "tick_n"), 0.1), "inner": snappedf(_ratio("inner_n", "tick_n"), 0.1),
				"jam_dv_p90": snappedf(_quant("dv", 0.9), 0.01), "jam_dv_p99": snappedf(_quant("dv", 0.99), 0.01),
				"jam_sep_ratio": snappedf(_ratio("sep_sum", "nom_sum"), 0.01), "jam_path_net_p50": snappedf(_quant("path_net", 0.5), 0.01),
				"jam_inner_flip_pct": snappedf(_ratio("inner_flip", "inner_n", 100.0), 0.1), "jam_inner_step_p90": snappedf(_quant("inner_step", 0.9), 0.01),
				"jam_turn_deg": snappedf(_ratio("turn_sum", "turn_n"), 0.1), "jam_rev_pct": snappedf(_ratio("turn_rev", "turn_n", 100.0), 0.1),
				"jam_ovl": snappedf(_ratio("ovl_sum", "ovl_n"), 0.001), "jam_deep_pct": snappedf(_ratio("ovl_deep", "ovl_n", 100.0), 0.1)}
			line = JSON.stringify(r)
			for key in r:
				_check(key, r[key])
		"move":
			var r := {"move_stall_pct": snappedf(_ratio("stall", "stall_n", 100.0), 0.1), "move_face_bad_pct": snappedf(_ratio("face_bad", "face_n", 100.0), 0.1),
				"move_cover": snappedf(_ratio("cover_sum", "samples"), 0.01), "move_tan_rad": snappedf(_ratio("ring_tan", "ring_rad"), 0.01),
				"move_runner_eff": snappedf(_ratio("runner_eff", "runner_n"), 0.01), "move_turn_deg": snappedf(_ratio("turn_sum", "turn_n"), 0.1),
				"move_mode_flip_pct": snappedf(_ratio("mode_flip", "mode_n", 100.0), 0.01),
				"move_mode_back_pct": snappedf(_ratio("mode_back", "mode_n", 100.0), 0.01)}
			line = JSON.stringify(r)
			for key in r:
				_check(key, r[key])
		"start":
			var r := {"spawn_view": float(M.get("spawn_view", 0.0)), "spawn_n": float(M.get("spawn_n", 0.0)),
				"start_spawn_d_p50": snappedf(_quant("spawn_d", 0.5), 1.0), "start_ttc_p50": snappedf(_quant("ttc", 0.5), 0.1),
				"start_ttc_n": float(_list("ttc").size()), "start_wall_x": snappedf(_ratio("wall_hug", "wall_n") / maxf(_ratio("area_hug", "area_n"), 0.0001), 0.01),
				"start_long_x": snappedf(_ratio("wall_hug_long", "wall_n") / maxf(_ratio("area_hug_long", "area_n"), 0.0001), 0.01)}
			line = JSON.stringify(r)
			for key in r:
				_check(key, r[key])
		"far":
			var r := {"far_pct": snappedf(_ratio("far_sum", "alive_sum", 100.0), 0.1), "spawn_view": float(M.get("spawn_view", 0.0)),
				"far_mode_flip_pct": snappedf(_ratio("mode_flip", "mode_n", 100.0), 0.01),
				"far_mode_back_pct": snappedf(_ratio("mode_back", "mode_n", 100.0), 0.01)}
			line = JSON.stringify(r)
			for key in r:
				_check(key, r[key])
	print("CROWDTEST map=%s scenario=%s %s" % [_map, _scenario, line])
	if OS.get_cmdline_user_args().has("--crowd-debug"):
		var dbg := {}
		for key in M:
			if str(key).begins_with("dbg_"):
				dbg[key] = M[key]
		print("CROWDDEBUG ", JSON.stringify(dbg))


func _check(key: String, value: float) -> void:
	for limit: Array in LIMITS:
		if limit[0] != key or not ACTIVE.has(limit[3]):
			continue
		checks += 1
		var ok: bool = value <= float(limit[2]) if limit[1] == "<=" else value >= float(limit[2])
		if not ok:
			failed += 1
			print("CROWDTEST FAILED map=%s scenario=%s %s=%s (%s %s, %s)" % [_map, _scenario, key, value, limit[1], limit[2], limit[3]])
