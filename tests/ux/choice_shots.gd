extends Node
## Оконный стенд выбора: отдельный профиль через --save-file, кадры до/после.

var game: Node
var prefix := "ux1_after"
var root: Window


func _ready() -> void:
	root = get_tree().root
	get_tree().create_timer(45.0, true).timeout.connect(func() -> void: get_tree().quit(1))
	_run.call_deferred()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-prefix="):
			prefix = arg.trim_prefix("--capture-prefix=")
	var meta := root.get_node("Meta")
	meta.persist = false
	meta.reset()
	meta.settings["fullscreen"] = false
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await get_tree().create_timer(2.0).timeout
	game.spawner.enabled = false
	game.player.god_mode = true
	get_tree().paused = true
	game.progression.level = 2
	game.progression.pending = 1
	game.level_up.open([{"type": "weapon", "id": WeaponDefs.Base.SHOTGUN, "rare": false},
		{"type": "module", "id": WeaponDefs.Module.TWIN, "rare": true},
		{"type": "ammo", "id": WeaponDefs.Ammo.CRYO, "rare": false}])
	await shot("cards")
	game.level_up.open([{"type": "level", "slot": 0, "rare": false},
		{"type": "passive", "id": WeaponDefs.Passive.DAMAGE, "rare": false},
		{"type": "passive", "id": WeaponDefs.Passive.HP, "rare": false}])
	await shot("upgrade")
	game.level_up.close()
	game.progression.credits = 230
	game.trader.offers.assign([{"card": {"type": "level", "slot": 0, "rare": false}, "price": 50, "sold": false},
		{"card": {"type": "module", "id": WeaponDefs.Module.TWIN, "rare": true}, "price": 100, "sold": false},
		{"card": {"type": "ammo", "id": WeaponDefs.Ammo.CRYO, "rare": false}, "price": 40, "sold": false},
		{"card": {"type": "weapon", "id": WeaponDefs.Base.RAIL, "rare": false}, "price": 60, "sold": false}])
	game.trader_ui.open(game.trader, game.progression, game.weapons, 5.0)
	await shot("trader")
	game.trader_ui._pick(1)
	await shot("install")
	game.trader_ui._set_step(0)
	game.trader_ui._pick(2)
	await shot("replacement")
	game.trader_ui.visible = false
	game.time = 300.0
	game.radio_t = 0.0
	game.weapons.add_weapon(WeaponDefs.Base.PISTOL)
	game.weapons.add_weapon(WeaponDefs.Base.SHOTGUN)
	game.weapons.slots[0].target = -1
	game.weapons.slots[1].target = -1
	game.weapons.slots[2].reloading = true
	game.weapons.slots[2].reload_t = 0.9
	# Реальная закрытая линия: одна цель и стена на её пути, остальные слоты вне радиуса.
	game.horde.count = 0
	game.horde.spawn(game.player.position + Vector2(120, 0), Horde.Kind.SHAMBLER)
	game.horde._rebuild_grid()
	game.weapons.slots[1].stats["range"] = 30.0
	var layout: Array[Dictionary] = [{"kind": Obstacles.Kind.JERSEY, "pos": game.player.position + Vector2(60, 0), "angle": PI / 2}]
	game.obstacles.setup(game.obstacles.arena, layout)
	game.horde._render()
	await shot("silent_gun")
	for k in 80:
		game.horde.spawn(game.player.position + Vector2.from_angle(k * 2.399) * (130 + k % 100), k % 4)
	# Настоящие смерти проходят сигналы игры и звук порогов; пауза удерживает кадр реакции.
	for k in 20:
		game.horde.damage(k + 1, 10000.0, Vector2.RIGHT, 80.0, WeaponDefs.Ammo.STANDARD, true)
	game.horde._compact()
	game.horde._rebuild_grid()
	game.horde._render()
	game.horde.queue_redraw()
	await shot("combo")
	print("CHOICE_SHOTS prefix=%s" % prefix)
	get_tree().quit()


func shot(suffix: String) -> void:
	await get_tree().create_timer(0.6, true).timeout
	await RenderingServer.frame_post_draw
	var name := "%s_%s" % [prefix, suffix]
	for stage in ["before", "after"]:
		if prefix.ends_with("_" + stage):
			name = prefix.trim_suffix("_" + stage) + "_" + suffix
			if stage == "before" or suffix not in ["combo", "silent_gun"]:
				name += "_" + stage
			break
	root.get_texture().get_image().save_png("res://design/tasks/reports/%s.png" % name)
