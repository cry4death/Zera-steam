class_name GunLabRange
extends Node
## Один контроллер тира; мишени и снаряды пользуются существующими packed-пулами.

var game: Node
var panel: GunLabPanel
var active := false
var _burst_left := 0.0
var _next := 0.0
var _spawn_at := 0.0
var _music_muted := false
const MODELS := {"pistol":"colt", "revolver":"magnum", "smg":"ppsh", "rifle":"ak_s", "shotgun":"butcher", "sniper":"mosin", "rail":"needle", "launcher":"grom"}

func _ready() -> void:
	panel = GunLabPanel.new()
	panel.audio = game.sfx.gun_lab
	game.add_child(panel)
	panel.selected.connect(_select)
	panel.fire.connect(_fire)
	panel.burst.connect(func() -> void: _burst_left = 2.0; _next = 0.0)
	if active:
		game.weapons.set_physics_process(false)
		process_physics_priority = 1
		game.player.god_mode = true
		game.spawner.enabled = false
		game.activities.enabled = false
		game.blood_alarm.set_process(false)
		game.blood_alarm.set_physics_process(false)
		game.player.autopilot = false
		game.gems.collected.disconnect(game.progression.add_xp)
		_music_muted = AudioServer.is_bus_mute(AudioServer.get_bus_index("Music"))
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),true)
		for voice in game.sfx._loops:
			voice.stop()
		var back := Button.new()
		back.text = "На базу"
		back.position = Vector2(20,20)
		panel.add_child(back)
		back.pressed.connect(game._return_to_base)
		_select("shotgun")
		panel.toggle()

func _select(gun: String) -> void:
	if not active:
		return
	var slot: Weapons.Slot = game.weapons.slots[0]
	var model: String = MODELS.get(gun, "")
	# Идентификаторы серийных моделей берём из каталога, а не из мета-разблокировок.
	for id: String in WeaponDefs.MODEL_ORDER:
		if WeaponDefs.MODELS[id].gun == gun and WeaponDefs.MODELS[id].rarity == WeaponDefs.Rarity.SERIAL:
			model = id
			break
	slot.set_model(model)
	game.weapons.refresh(0)

func _fire() -> void:
	if not active:
		game.sfx.gun_lab.play_shot(panel.gun)
		return
	var slot: Weapons.Slot = game.weapons.slots[0]
	slot.mag = int(slot.stats.mag)
	slot.reloading = false
	if panel.root.visible and panel.root.get_global_rect().has_point(panel.root.get_global_mouse_position()):
		game.player.aim_point = game.player.global_position + Vector2(-60,-150)
	game.player.aim_dir = (game.player.aim_point-game.player.global_position).normalized()
	game.weapons._fire_shot(0,slot,Weapons.MANUAL_TARGET)

func _process(delta: float) -> void:
	if not is_instance_valid(panel):
		return
	game.camera.view_shift = Vector2(game.get_viewport_rect().size.x * .31 / game.camera.zoom.x,0.0) if panel.root.visible else Vector2.ZERO
	if _burst_left > 0.0:
		_burst_left -= delta
		_next -= delta
		var interval: float = .09 if panel.gun in ["smg","rifle"] else .4
		if _next <= 0.0:
			_fire()
			_next += interval
	if not active:
		return
	var slot: Weapons.Slot = game.weapons.slots[0]
	slot.mag = int(slot.stats.mag)
	slot.reloading = false
	_spawn_at -= delta
	if _spawn_at <= 0.0 and game.horde.count < 8:
		_spawn_at = .5
		var index: int = game.horde.spawn(game.player.global_position + Vector2(-110.0 + game.horde.count%4*50.0, -120.0-game.horde.count/4*50.0))
		if index >= 0:
			game.horde.speed[index] = 0.0

func _physics_process(delta: float) -> void:
	if active:
		game.player.manual_aim = true
		game.player.aim_dir = (game.player.aim_point-game.player.global_position).normalized()
		game.player.fire_requested = Input.is_action_pressed("fire")
		if panel.root.visible and panel.root.get_global_rect().has_point(panel.root.get_global_mouse_position()):
			game.player.fire_requested = false
		game.weapons._physics_process(delta)

func _exit_tree() -> void:
	if active:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),_music_muted)
