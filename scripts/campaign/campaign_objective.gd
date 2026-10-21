class_name CampaignObjective
extends Node2D
## Одна цель операции: узел либо контейнер и посадочная площадка.

var game: Node
var type := ""
var target := Vector2.INF
var exit_point := Vector2.INF
var picked := false
var spawned := false
var done := false
var hold := 0.0
var evac_at := 300.0
var guard_stamp := -100.0
var _sample: Texture2D
var _beacon: Texture2D
var _beacon_lit: Texture2D
var _zone: Texture2D
var _closed_node: Texture2D
var _guard_at := 0.0
var _log_at := 0.0


func setup(owner_game: Node, data: Dictionary) -> void:
	game = owner_game
	type = game.mission_config["type"]
	_sample = PixelArt.tex("campaign_sample")
	_beacon = PixelArt.tex("campaign_beacon")
	_beacon_lit = PixelArt.tex("campaign_beacon_lit")
	_zone = PixelArt.tex("campaign_beacon_zone")
	_closed_node = PixelArt.tex("campaign_node_closed")
	target = socket(data["objective_sockets"]["sample" if type == "extract" else "node"], 36.0)
	exit_point = socket(data["objective_sockets"]["evac"], 60.0)
	evac_at = float(CampaignCatalog.BALANCE["evac_time"])
	z_index = 4
	print("C6OBJECTIVE type=%s target=%s exit=%s reachable=true" % [type, target, exit_point])


func socket(points: Array, radius: float) -> Vector2:
	var start := int(game.mission_config["seed"]) % points.size()
	for offset in points.size():
		var at := MapLoader.point(points[(start + offset) % points.size()])
		if game.obstacles:
			at = game.obstacles.free_point(at, radius)
			var c: int = game.obstacles.cell_at(at)
			if game.obstacles.contains(at, radius) or game.obstacles.distance[c] == Obstacles.NO_PATH:
				continue
		return at
	push_error("C6: нет достижимого сокета цели")
	return Vector2.INF


func icon() -> String:
	return "crate" if type == "extract" and not picked else ("arrow" if type == "extract" else "skull")


func progress() -> float:
	return hold / float(CampaignCatalog.BALANCE["evac_hold"] if picked else CampaignCatalog.BALANCE["pickup_hold"])


func _physics_process(delta: float) -> void:
	if not game or game.game_over or done:
		return
	if type != "extract":
		# Видимая цель доступна для огня сразу, без скрытого ожидания 10:00.
		if not spawned and game.time >= float(CampaignCatalog.BALANCE["node_time"]):
			spawned = true
			queue_redraw()
			game.boss.start(target)
			_connect_node()
			game.spawner.set_node_pressure(1.0)
			game.radio_text = "Узел открыт. Уничтожьте его."
			game.radio_t = 4.0
			guards()
		if spawned:
			_pressure_step()
			if game.time >= _guard_at:
				guards()
		return
	var close: bool = game.player.position.distance_to(target) <= (58.0 if picked else 34.0)
	if close and (not picked or game.time >= evac_at):
		hold += delta
	elif not picked:
		hold = 0.0
	# Эвакуация сохраняет удержанные секунды; выход из зоны останавливает погрузку.
	if not picked and hold >= float(CampaignCatalog.BALANCE["pickup_hold"]):
		picked = true
		hold = 0.0
		target = exit_point
		evac_at = maxf(evac_at, game.time + 60.0)
		game.spawner.objective_pressure(true)
		game.radio_text = "Образец принят. Отходите к маяку."
		game.radio_t = 4.0
		guards()
	if picked and hold >= float(CampaignCatalog.BALANCE["evac_hold"]):
		done = true
		game._objective_victory()
	elif picked and game.time >= _guard_at:
		guards()
	queue_redraw()


## NP1: узел сам ведёт давление; цель связывает его с бюджетом орды, звуком и подсказкой на экране.
func _connect_node() -> void:
	var node := game.boss as CampaignNode
	if node == null:
		return
	node.hazards = game.hazards
	node.call_started.connect(_on_call_started)
	node.call_released.connect(_on_call_released)
	node.bite_started.connect(func() -> void: game.sfx.play("zombies/node_spit", node.global_position, 2.0, 0.03))
	node.died.connect(_on_node_died)
	node.bite_launched.connect(func() -> void:
		game.sfx.play("zombies/node_spit", node.global_position, 4.0, 0.03)
		game.camera.shake(2.5))


func _pressure_step() -> void:
	var node := game.boss as CampaignNode
	if node == null:
		return
	# После разрушения давление снимается вместе с узлом.
	game.spawner.set_node_pressure(node.pressure if node.is_alive() else 0.0)
	if game._sim and game.time >= _log_at:
		_log_at = game.time + 5.0
		print("NP1 t=%.1f hp=%.3f pressure=%.3f rate=%.2f cap=%d alive=%d calls=%d steps=%d dmg=%d level=%d kills=%d" % [game.time, node.hp_fraction(), node.pressure,
			game.spawner.current_rate(), int(game.spawner.current_row()[2]), game.horde.count, game.spawner.node_calls, node.steps, roundi(game.player.damage_taken), game.progression.level, game.kills])


func _on_node_died(_at: Vector2) -> void:
	game.spawner.set_node_pressure(0.0) # узел разрушен: давление снимается сразу
	if game._sim:
		var node := game.boss as CampaignNode
		print("NP1RESULT victory time=%.1f steps=%d calls=%d called=%d dmg=%d level=%d kills=%d pressure_cleared=%s" % [game.time, node.steps, game.spawner.node_calls, game.spawner.node_called, roundi(game.player.damage_taken), game.progression.level, game.kills, game.spawner.node_pressure == 0.0])
		Meta.finish_test.call_deferred()


func _on_call_started(_step: int) -> void:
	var node := game.boss as CampaignNode
	game.spawner.node_call_prepare(node.global_position, CampaignNode.CALL_WARNING)
	game.sfx.play("zombies/node_call", node.global_position, 5.0, 0.02)
	game.camera.shake(4.0)


func _on_call_released(step: int) -> void:
	var node := game.boss as CampaignNode
	game.spawner.node_call(step)
	game.sfx.play("zombies/node_call", node.global_position, 2.0, 0.02)


func guards() -> void:
	guard_stamp = game.time
	_guard_at = game.time + (12.0 if picked else 30.0)
	for i in 3:
		var at := target + Vector2.from_angle(TAU * float(i) / 3.0) * 95.0
		if game.obstacles:
			at = game.obstacles.free_point(at, Horde.RADIUS)
		if game.horde.count < int(game.spawner.current_row()[2]):
			game.horde.spawn(at, Horde.Kind.RUNNER, true)


func _draw() -> void:
	if not game:
		return
	if type != "extract":
		if not spawned:
			draw_texture_rect(_closed_node, Rect2(target + Vector2(-40, -52), Vector2(80, 72)), false)
		return
	if done:
		return
	var tex := _beacon if picked else _sample
	if picked:
		# Матовая краска и конусы лежат в мире, проблеск — только в лампе.
		draw_texture_rect(_zone, Rect2(target - Vector2(60, 60), Vector2(120, 120)), false)
		if game.time >= evac_at and fmod(game.time, 1.6) < 0.22:
			tex = _beacon_lit
	var at := target + Vector2(0, -35) if picked else target
	var size := Vector2(40, 48) if picked else Vector2(40, 36)
	draw_texture_rect(tex, Rect2(at - size * 0.5, size), false)
