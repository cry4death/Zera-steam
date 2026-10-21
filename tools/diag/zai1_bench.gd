extends Node
## ZAI1 (временный): цена отдельных шагов ИИ орды в основном потоке, без орды на экране.
## --headless --path . res://tools/diag/zai1_bench.tscn -- --fresh-save --nav-thread --map=<id>

var game


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	for f in 10:
		await get_tree().physics_frame
	var ob = game.obstacles
	var h = game.horde
	var d = game._horde_director
	var pp: Vector2 = game.player.position
	var out := {"map": game._map_id, "cells": ob.blocked.size(), "obstacles": ob.count}
	# Поле одного класса целиком в основном потоке (столько же стоит задача потока).
	for k in 3:
		var layer: Dictionary = ob._nav_layers[k]
		var best := INF
		for rep in 3:
			var o := {}
			var t0 := Time.get_ticks_usec()
			Obstacles._flow_layer(layer["edges"], layer["weights"], layer["points"], layer["capacity"], ob._offsets, ob.cell_at(pp), pp, o)
			best = minf(best, (Time.get_ticks_usec() - t0) / 1000.0)
		out["flow_ms_%d" % k] = snappedf(best, 0.1)
	# Луч коридора тела на 100..700 px в случайных направлениях.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for dist in [150.0, 400.0, 700.0]:
		var t0 := Time.get_ticks_usec()
		var n := 400
		var clear := 0
		for j in n:
			var from: Vector2 = pp + Vector2.from_angle(rng.randf() * TAU) * dist
			if ob.body_clear(from, pp, 5.0):
				clear += 1
		out["body_clear_us_%d" % int(dist)] = snappedf((Time.get_ticks_usec() - t0) / float(n), 0.1)
		out["body_clear_hit_%d" % int(dist)] = snappedf(float(clear) / n, 0.01)
	# steering() — выборка поля для одного тела.
	var t1 := Time.get_ticks_usec()
	for j in 2000:
		ob.steering(pp + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(100.0, 900.0), Vector2.RIGHT, 5.0)
	out["steering_us"] = snappedf((Time.get_ticks_usec() - t1) / 2000.0, 0.01)
	# Старт события режиссёра: prepare() с маршрутами route()/body_path() для всех плеч.
	if d:
		if d.player == null:
			d.setup(h, game.player, 81073, game._map_id)
		for p in [HordeDirector.Pattern.PINCER, HordeDirector.Pattern.RING, HordeDirector.Pattern.TIDE, HordeDirector.Pattern.FLANK, HordeDirector.Pattern.RUSH]:
			var t0 := Time.get_ticks_usec()
			d.force_pattern(p, rng.randf() * TAU, game.time)
			out["event_ms_" + HordeDirector.NAMES[p]] = snappedf((Time.get_ticks_usec() - t0) / 1000.0, 0.1)
			out["event_lanes_" + HordeDirector.NAMES[p]] = d._origins.size()
		h.release_groups()
	# Полная перестройка сетки (узел кампании add_body/remove_body, setup).
	var t2 := Time.get_ticks_usec()
	var body: int = ob.add_body(game.obstacles.free_point(pp + Vector2(120, 0), 30.0), 26.0)
	out["add_body_ms"] = snappedf((Time.get_ticks_usec() - t2) / 1000.0, 0.1)
	out["layers_ready_after_add"] = ob._nav_layers[1]["ready"]
	var t3 := Time.get_ticks_usec()
	ob.remove_body(body)
	out["remove_body_ms"] = snappedf((Time.get_ticks_usec() - t3) / 1000.0, 0.1)
	print("ZAI1B ", JSON.stringify(out))
	get_tree().quit()
