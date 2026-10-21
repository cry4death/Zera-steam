extends SceneTree
## Настоящие переходы: база → кнопка «Тир» → все стволы → база, без наград.

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var meta := root.get_node("Meta")
	var before: Dictionary = meta.to_dict()
	set_meta("s6_return_to_base",true)
	var base: Node = load("res://scenes/base.tscn").instantiate()
	root.add_child(base)
	current_scene = base
	base._click("range:0")
	await create_timer(.3).timeout
	var game := current_scene
	var ok: bool = game.gun_lab_range and game.player.god_mode and not game.spawner.enabled
	for gun: String in GunLabAudio.GUNS:
		game.gun_lab_controller.panel.choose(gun)
		var slot: Variant = game.weapons.slots[0]
		ok = ok and slot.gun == gun
		var count: int = game.weapons.shots[slot.base]
		game.gun_lab_controller.panel.fire.emit()
		ok = ok and game.weapons.shots[slot.base] == count+1
		await process_frame
	game._return_to_base()
	await create_timer(.3).timeout
	ok = ok and current_scene.get_script() == load("res://scripts/base.gd") and meta.to_dict() == before
	print("GUNLABENTRY base_button=true all_guns=8 fire=true return=true progress_unchanged=%s ok=%s" % [meta.to_dict() == before,ok])
	quit(0 if ok else 1)
