extends Control
## Первая вылазка и одноразовые подсказки. Оружие, карты и награды остаются штатными.

const Style := preload("res://scripts/ui/zera_style.gd")
const XP_AT := 8.0
const PICKUP_AT := 18.0
const ABILITY_AT := 25.0
const TRADER_AT := 65.0
const EXIT_AT := 120.0
const END_AT := 150.0
const TRADER_CREDITS := 60

var game: Node2D
var current := ""
var anchor := Vector2.ZERO
var _start := Vector2.ZERO
var _xp_spawned := false
var _pickup_spawned := false
var _xp_at := Vector2.INF
var _shop_at := Vector2.INF
var _exit_at := Vector2.INF
var _shop: Sprite2D
var _shop_used := false
var _exit: Sprite2D
var _device := ChoiceInput.new()
var _pad := false
var _ui := 1.0


func setup(value: Node2D) -> void:
	name = "FirstRunHints"
	process_mode = Node.PROCESS_MODE_ALWAYS
	game = value
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_start = game.player.position
	_pad = ChoiceInput.pad_mode
	game.pickups.collected.connect(_collected)
	game.gems.collected.connect(_experience)
	game.level_up.chosen.connect(_card_chosen)
	game.trader_ui.closed.connect(func() -> void: Meta.complete_hint("trader"))
	if not game.first_run:
		return
	game._director_pending = false
	game.activities.enabled = false
	game.activities.set_physics_process(false)
	game.blood_alarm.phase = BloodAlarm.Phase.DONE
	game.blood_alarm.set_physics_process(false)
	game.trader_visit = game.TRADER_TIMES.size()
	# Видимые первые цели: штатные шаркающие, без изменения их здоровья и оружия.
	for i in 5:
		var at := _free(_start + Vector2(85 + i * 10, (i - 2) * 18), 10.0)
		game.horde.spawn(at, Horde.Kind.SHAMBLER)
	game.player.force_auto_aim = false


func _free(at: Vector2, radius: float) -> Vector2:
	return game.obstacles.free_point(at, radius) if game.obstacles else at


func _collected(_kind: int, _at: Vector2) -> void:
	Meta.complete_hint("pickup")


func _experience(_amount: int) -> void:
	Meta.complete_hint("xp")


func _card_chosen(_card: Dictionary, _slot: int) -> void:
	Meta.complete_hint("card")


func _object(texture: String, at: Vector2, size: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = PixelArt.tex(texture)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = at
	sprite.scale = size / sprite.texture.get_size()
	game.get_node("World").add_child(sprite)
	game.get_node("World").move_child(sprite, game.horde.get_index())
	return sprite


func _intro_step() -> void:
	var t: float = game.time
	var p: Vector2 = game.player.position
	if t >= XP_AT and not _xp_spawned:
		_xp_spawned = true
		_xp_at = _free(p + Vector2(30, 24), 8.0)
		game.gems.spawn(_xp_at, Progression.xp_to_next(game.progression.level))
	if t >= PICKUP_AT and not _pickup_spawned:
		_pickup_spawned = true
		game.pickups.spawn(_free(p + Vector2(-30, 20), 10.0), Pickups.Kind.CRATE)
		game.pickups._life[game.pickups.count - 1] = INF
	if t >= TRADER_AT and _shop == null:
		_shop_at = _free(p + Vector2(38, 26), 18.0)
		_shop = _object("activity_supply", _shop_at, Vector2(28, 24))
		game.progression.credits += TRADER_CREDITS
	if t >= EXIT_AT and _exit == null:
		_exit_at = _free(p + Vector2(0, -54), 36.0)
		_exit = _object("activity_apc", _exit_at, Vector2(78, 64))
		game.spawner.enabled = false
	if t >= END_AT:
		game._open_results(true)


func _process(_delta: float) -> void:
	if game == null:
		return
	current = ""
	if game.game_over:
		visible = false
		set_process(false)
		return
	if get_tree().paused or game.game_over:
		queue_redraw()
		return
	if game.first_run:
		_intro_step()
		if game.game_over:
			return
	var p: Vector2 = game.player.position
	if p.distance_to(_start) >= 16.0:
		Meta.complete_hint("move")
	if game.player.manual_aim:
		Meta.complete_hint("aim")
	if game.player.grenade_cd > 0.0:
		Meta.complete_hint("ability")
	anchor = p
	if _exit != null and not Meta.hint_done("evac"):
		current = "evac"
		anchor = _exit_at
	elif not game.first_run and game.objective != null and game.objective.type == "extract" and game.objective.picked and game.time >= game.objective.evac_at and not Meta.hint_done("evac"):
		current = "evac"
		anchor = game.objective.target
	elif _shop != null and not Meta.hint_done("trader"):
		current = "trader"
		anchor = _shop_at
	elif not Meta.hint_done("pickup") and game.pickups.count > 0:
		current = "pickup"
		anchor = game.pickups._pos[0]
	elif not Meta.hint_done("move"):
		current = "move"
	elif not Meta.hint_done("xp") and game.gems.count > 0 and game.time >= XP_AT:
		current = "xp"
		anchor = game.gems.nearest(p, INF)
	elif not Meta.hint_done("ability") and game.time >= ABILITY_AT and game.player.grenade_cd <= 0.0:
		current = "ability"
	elif not Meta.hint_done("aim"):
		current = "aim"
	queue_redraw()


func _input(event: InputEvent) -> void:
	_device.read(event)
	_pad = ChoiceInput.pad_mode
	if game == null or game.game_over or get_tree().paused:
		return
	var key := event as InputEventKey
	var button := event as InputEventJoypadButton
	if event.is_action_pressed("intro_skip") or (button != null and button.pressed and button.button_index == JOY_BUTTON_BACK):
		if game.first_run:
			Meta.finish_first_run(true)
			game._return_to_base()
			get_viewport().set_input_as_handled()
		return
	var interact := event.is_action_pressed("interact") or (button != null and button.pressed and button.button_index == JOY_BUTTON_A)
	if not interact:
		return
	if _exit != null and game.player.position.distance_to(_exit_at) <= 60.0:
		Meta.complete_hint("evac")
		game._open_results(true)
		get_viewport().set_input_as_handled()
	elif _shop != null and not _shop_used and game.player.position.distance_to(_shop_at) <= 54.0:
		game.trader_visit = 0
		game._open_trader()
		if game.trader_ui.visible:
			_shop_used = true
			Meta.complete_hint("trader")
		get_viewport().set_input_as_handled()


func _key(at: Vector2, label: String) -> void:
	var font := Style.BODY_FONT
	var width := maxf(17.0, font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 8.0)
	Style.cut_rect(self, Rect2(at, Vector2(width, 17)), Style.HOVER, 2.0)
	draw_line(at + Vector2(2, 16), at + Vector2(width - 2, 16), Style.MUTED)
	_label(at + Vector2(4, 12), label, 9, Style.TEXT)


func _label(at: Vector2, value: String, size: int, color: Color) -> void:
	# Как на базе: шрифт растрируется в физических пикселях, а не растягивается после.
	draw_set_transform(Vector2.ZERO)
	draw_string(Style.BODY_FONT, (at * _ui).round(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(size * _ui), color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))


func _draw() -> void:
	if game == null or game.game_over or get_tree().paused or current.is_empty():
		return
	var ui := maxf(1.0, roundf(get_viewport_rect().size.y / 360.0))
	_ui = ui
	var view := get_viewport_rect().size / ui
	var at: Vector2 = (game.player.get_canvas_transform() * anchor) / ui
	var names := {"move": "Движение", "aim": "Прицел", "xp": "Опыт", "pickup": "Подойти", "ability": "Граната", "trader": "Снабжение", "evac": "На базу"}
	if game.player.class_id != "assault":
		names["ability"] = "Щит" if game.player.class_id == "gunner" else "Турель"
	var movement := "LS" if _pad else SettingsBindings.movement_hint()
	var keys := {"move": movement, "aim": "RS" if _pad else SettingsBindings.hint("aim_override"), "xp": movement, "pickup": movement, "ability": "RB" if _pad else SettingsBindings.hint("grenade"), "trader": "A" if _pad else SettingsBindings.hint("interact"), "evac": "A" if _pad else SettingsBindings.hint("interact")}
	var near := true
	if current == "evac" and not game.first_run:
		names[current] = "Стоять" if game.player.position.distance_to(anchor) <= 58.0 else "К маяку"
		keys[current] = movement
	if current in ["trader", "evac"]:
		near = game.player.position.distance_to(anchor) <= (60.0 if current == "evac" else 54.0)
		if not near:
			keys[current] = movement
	var skip: bool = game.first_run and current == "move"
	var width := 144.0 if skip else 116.0
	var key_width := maxf(17, Style.BODY_FONT.get_string_size(keys[current], HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 8)
	width = maxf(width, key_width + Style.BODY_FONT.get_string_size(names[current], HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 28)
	var height := 45.0 if skip else 28.0
	var point := (at + Vector2(-width * 0.5, 20)).round().clamp(Vector2(12, 76), view - Vector2(width + 12, 78))
	# Подсказка у выхода над героем не должна закрывать самого героя.
	var player_at: Vector2 = (game.player.get_canvas_transform() * game.player.position) / ui
	if Rect2(point, Vector2(width, height)).intersects(Rect2(player_at - Vector2(12, 16), Vector2(24, 32))):
		point.y = clampf(at.y - height - 20.0, 76.0, view.y - height - 78.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(ui, ui))
	Style.cut_rect(self, Rect2(point, Vector2(width, height)), Style.RECESS)
	draw_rect(Rect2(point, Vector2(2, height)), Style.ACTION)
	_key(point + Vector2(7, 5), keys[current])
	var text_x := key_width + 15.0
	_label(point + Vector2(text_x, 18), names[current], 10, Style.TEXT)
	if skip:
		var skip_key := "Back" if _pad else SettingsBindings.hint("intro_skip")
		_key(point + Vector2(7, 25), skip_key)
		_label(point + Vector2(maxf(44, Style.BODY_FONT.get_string_size(skip_key, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 22), 37), "Пропустить", 8, Style.MUTED)
	# Короткая привязка к предмету остаётся видна и при краевом положении цели.
	var from := point + Vector2(width * 0.5, height if point.y < at.y else 0.0)
	var target := at.clamp(Vector2(12, 76), view - Vector2(12, 64))
	draw_line(from, target, Style.ACTION, 1.0)
