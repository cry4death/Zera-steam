extends Node2D
## Корень сцены: связывает системы, ведёт время забега, отладочные клавиши и бенчмарк.
##
## Бенчмарк: godot --path . -- --bench[=кол-во_зомби] [--shot=путь.png]
## Держит 500 зомби, игрок бессмертен и бегает сам; в конце печатает замеры и выходит.

const ARENA := Rect2(0, 0, 2560, 1440)
const BENCH_TARGET := 500
var _bench_target := BENCH_TARGET
const BENCH_WARMUP := 3.0
const BENCH_DURATION := 10.0

const COMBO_WINDOW := 1.5 # сек между убийствами, чтобы серия не прервалась
const COMBO_TITLES := {10: "РЕЗНЯ!", 25: "МЯСОРУБКА!", 50: "КРОВАВАЯ БАНЯ!", 100: "БОЙНЯ!", 200: "АПОКАЛИПСИС!", 400: "ЖНЕЦ!"}
const MULTIKILL_WINDOW := 0.15
const DIRT_RADIUS := 48.0
const CREDIT_CHANCE := 0.06 # шаркающий: 6% × 1 кредит (BALANCE.md §2.1)
const TRADER_TIMES := [300.0, 540.0] # визиты торговца: 5:00 и 9:00 (BALANCE.md §9.2)

var time := 0.0
var kills := 0
var game_over := false
var trader_visit := 0 # следующий визит торговца

# комбо и надписи (рисует HUD)
var combo := 0
var best_combo := 0
var announce_text := ""
var announce_t := 0.0
var announce_color := Color(0.9, 0.15, 0.1)
var _combo_timer := 0.0
var _burst_count := 0
var _burst_t := -1.0

var _bench := false
var _shot_path := ""
var _bench_t := 0.0
var _zoom := 1.0
var _gore_stress := false
var _no_fire := false
var _ui_test := false
var _sim := false
var _sim_next_report := 60.0
var _sim_until := 600.0
var _bench_frames := 0
var _bench_frame_ms := 0.0
var _bench_worst_ms := 0.0
var _bench_horde_ms := 0.0
var _bench_enemies := 0

@onready var player: Player = $World/Player
@onready var horde: Horde = $World/Horde
@onready var weapons: Weapons = $World/Weapons
@onready var gems: Gems = $World/Gems
@onready var credit_drops: Gems = $World/Credits
@onready var progression: Progression = $Progression
@onready var level_up: Control = $Overlay/LevelUp
@onready var trader: Trader = $Trader
@onready var trader_ui: Control = $Overlay/Trader
@onready var effects: Effects = $World/Effects
@onready var floor_decals: FloorDecals = $World/FloorDecals
@onready var gore: Gore = $World/Gore
@onready var ground: Node2D = $World/Ground
@onready var spawner: Spawner = $Spawner
@onready var camera: GameCamera = $Camera
@onready var screen_blood: Control = $ScreenFX/ScreenBlood


func _enter_tree() -> void:
	_setup_input()


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--bench":
			_bench = true
		elif arg.begins_with("--bench="):
			_bench = true
			_bench_target = arg.trim_prefix("--bench=").to_int()
		elif arg.begins_with("--shot="):
			_shot_path = arg.trim_prefix("--shot=")
		elif arg == "--no-fire":
			_no_fire = true # для скриншотов живой орды: не стреляем и стоим на месте
		elif arg == "--loadout":
			_full_loadout.call_deferred() # бенчмарк с полным арсеналом
		elif arg == "--ui-test":
			_ui_test = true # снимки экрана Level Up и выбора ствола
		elif arg == "--sim" or arg.begins_with("--sim="):
			_sim = true # прогон забега на ускорении с отчётом раз в минуту
			_sim_until = arg.trim_prefix("--sim=").to_float() if arg.begins_with("--sim=") else 600.0
		elif arg == "--gore-stress":
			_gore_stress = true # 120 убийств/с со случайным типом смерти
		elif arg.begins_with("--zoom="):
			_zoom = arg.trim_prefix("--zoom=").to_float()

	ground.setup(ARENA)
	floor_decals.setup(ARENA)
	effects.floor_decals = floor_decals
	gore.setup(floor_decals, effects, ARENA, player)
	player.arena = ARENA
	player.position = ARENA.get_center()
	player.effects = effects
	horde.setup(ARENA, player, floor_decals)
	weapons.player = player
	weapons.horde = horde
	weapons.effects = effects
	weapons.floor_decals = floor_decals
	weapons.camera = camera
	gems.player = player
	credit_drops.player = player
	progression.weapons = weapons
	progression.player = player
	progression.gems = gems
	level_up.progression = progression
	level_up.weapons = weapons
	trader.progression = progression
	trader.weapons = weapons
	trader.player = player
	spawner.horde = horde
	spawner.player = player
	camera.setup(ARENA, player)
	get_viewport().size_changed.connect(_update_view)
	_update_view()

	horde.enemy_killed.connect(_on_enemy_killed)
	horde.enemy_killed.connect(gore.on_enemy_killed)
	horde.enemy_wounded.connect(gore.on_enemy_wounded)
	horde.enemy_hit.connect(gore.on_enemy_hit)
	gore.splatter.connect(_on_splatter)
	horde.player_touched.connect(player.take_damage)
	player.hurt.connect(_on_player_hurt)
	player.died.connect(_on_player_died)
	gems.collected.connect(progression.add_xp)
	credit_drops.collected.connect(_on_credits_collected)
	progression.level_ready.connect(_on_level_ready)
	level_up.chosen.connect(_on_card_chosen)
	level_up.reroll_requested.connect(_on_reroll)
	trader_ui.closed.connect(_on_trader_closed)
	weapons.prototype_unlocked.connect(_on_prototype)

	if _sim:
		player.god_mode = true
		player.autopilot = true
		Engine.time_scale = 4.0
		Engine.max_physics_steps_per_frame = 16
	if _ui_test:
		_run_ui_test()
	if _bench:
		player.god_mode = true
		player.autopilot = true
		spawner.enabled = false
		if _no_fire:
			player.autopilot = false
			weapons.process_mode = Node.PROCESS_MODE_DISABLED


func _physics_process(delta: float) -> void:
	if game_over:
		return
	time += delta
	if _sim:
		player.auto_target = gems.nearest(player.global_position, 260.0)
	if _sim and time >= _sim_next_report:
		_sim_next_report += 60.0
		_sim_report()
	horde.minutes = time / 60.0
	spawner.time = time
	credit_drops.radius = gems.radius # пассивка подбора действует и на кредиты
	if trader_visit < TRADER_TIMES.size() and time >= TRADER_TIMES[trader_visit]:
		_open_trader()
	if _bench and horde.count < _bench_target:
		horde.spawn_group(player.global_position, mini(15, _bench_target - horde.count))
	if _gore_stress and horde.count > 0:
		for k in 2:
			var i := randi() % horde.count
			var dir := (horde.pos[i] - player.global_position).normalized()
			horde.death_override = randi() % Gore.Death.size()
			horde.damage(i, 3.0 if randf() < 0.5 else 9999.0, dir, 0.0, WeaponDefs.Ammo.STANDARD, false, horde.pos[i] + dir.orthogonal() * 3.0)
		horde.death_override = -1


func _process(delta: float) -> void:
	if _bench:
		_bench_step(delta)
	_combo_timer -= delta
	if _combo_timer <= 0.0:
		combo = 0
	announce_t = maxf(announce_t - delta, 0.0)
	var hp_ratio := player.hp / player.max_hp
	screen_blood.low_hp = 0.0 if player.is_dead else clampf(1.0 - hp_ratio / 0.35, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_F1:
			for i in 10:
				horde.spawn_group(player.global_position, 10)
		KEY_F2:
			player.god_mode = not player.god_mode
		KEY_F4:
			time += 60.0
		KEY_F11:
			var full := DisplayServer.window_get_mode() >= DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		KEY_F5:
			# отладка: перебор патронов первого ствола
			var s: Weapons.Slot = weapons.slots[0]
			s.ammo = (s.ammo + 1) % WeaponDefs.AMMO.size()
			weapons.refresh(0)
		KEY_F7:
			progression.add_xp(Progression.xp_to_next(progression.level) - progression.xp)
		KEY_F8:
			progression.credits += 100
		KEY_F6:
			# перебор типа смерти: авто → все типы по очереди
			horde.death_override += 1
			if horde.death_override >= Gore.Death.size():
				horde.death_override = -1
		KEY_ENTER, KEY_KP_ENTER:
			if game_over:
				get_tree().reload_current_scene()


func _on_enemy_killed(pos: Vector2, _dir: Vector2, _death: int, _facing: float, _variant: int) -> void:
	kills += 1
	combo += 1
	best_combo = maxi(best_combo, combo)
	_combo_timer = COMBO_WINDOW
	if COMBO_TITLES.has(combo):
		_announce(COMBO_TITLES[combo])
	if time - _burst_t < MULTIKILL_WINDOW:
		_burst_count += 1
		if _burst_count in [4, 6, 10, 15]:
			_announce("МУЛЬТИКИЛЛ ×%d" % _burst_count)
	else:
		_burst_count = 1
	_burst_t = time
	if pos.distance_to(player.global_position) < DIRT_RADIUS:
		player.add_dirt(1.0)
	gems.spawn(pos, 1)
	if randf() < CREDIT_CHANCE:
		credit_drops.spawn(pos, 1)


func _on_credits_collected(value: int) -> void:
	progression.credits += value


# --- Level Up ---------------------------------------------------------------------------

func _on_level_ready() -> void:
	if level_up.visible or trader_ui.visible:
		return
	if _bench or _sim:
		# в бенчмарке и симуляции выбираем сами (случайно), без паузы
		while progression.pending > 0:
			var cards := progression.make_cards(time / 60.0)
			var card: Dictionary = cards.pick_random()
			var slot := -1
			if Progression.needs_slot(card):
				for i in weapons.slots.size():
					if progression.slot_status(card, i) != "":
						slot = i
						break
				if slot == -1:
					progression.pending -= 1
					continue
			if _sim:
				print("PICK lvl=%d %s slot=%d of %s" % [progression.level - progression.pending + 1, card, slot, cards.map(func(c): return c["type"])])
			progression.apply(card, slot)
		return
	get_tree().paused = true
	level_up.open(progression.make_cards(time / 60.0))


func _on_card_chosen(card: Dictionary, slot: int) -> void:
	progression.apply(card, slot)
	if progression.pending > 0:
		level_up.open(progression.make_cards(time / 60.0))
	else:
		level_up.close()
		get_tree().paused = false


func _on_reroll() -> void:
	progression.rerolls -= 1
	level_up.open(progression.make_cards(time / 60.0))


# --- Торговец ---------------------------------------------------------------------------

func _open_trader() -> void:
	# F4 может перескочить сразу через оба визита — открываем последний наступивший
	while trader_visit + 1 < TRADER_TIMES.size() and time >= TRADER_TIMES[trader_visit + 1]:
		trader_visit += 1
	var index := trader_visit
	trader_visit += 1
	trader.start_visit(index, time / 60.0)
	if _bench or _sim:
		_auto_shop()
		return
	get_tree().paused = true
	trader_ui.open(trader, progression, weapons, time / 60.0)


func _on_trader_closed() -> void:
	# Space закрывает лавку и он же рывок: ждём физический кадр, чтобы нажатие не стало рывком
	await get_tree().physics_frame
	await get_tree().physics_frame
	get_tree().paused = false
	if progression.pending > 0:
		_on_level_ready()


## Симуляция: покупаем случайные доступные позиции, пока хватает кредитов.
func _auto_shop() -> void:
	var bought: Array[String] = []
	var order := range(trader.offers.size())
	order.shuffle()
	for i: int in order:
		var card: Dictionary = trader.offers[i]["card"]
		var slot := -1
		if Progression.needs_slot(card):
			for s in weapons.slots.size():
				if progression.slot_status(card, s) != "":
					slot = s
					break
		var price: int = trader.offers[i]["price"]
		if trader.buy(i, slot):
			bought.append("%s(%d)" % [card["type"], price])
	if _sim:
		print("TRADER %d at %02d:%02d credits_left=%d bought=%s" % [trader.visit, int(time) / 60, int(time) % 60, progression.credits, bought])


func _on_prototype(_slot: int, proto_name: String) -> void:
	_announce("ПРОТОТИП: " + proto_name, Color(1.0, 0.55, 0.2))


## Рендер в родном разрешении экрана: камера берёт целый зум, чтобы пиксели арта
## оставались квадратными: зум кратен плотности арта (1080p → ×3, 1440p → ×4, 4K → ×6),
## пиксель арта при этом не меньше пикселя экрана; орда спавнится за краем.
func _update_view() -> void:
	var vs := get_viewport().get_visible_rect().size
	var z := maxf(1.0, roundf(vs.y / 360.0)) * _zoom
	camera.zoom = Vector2(z, z)
	horde.spawn_ring = (vs / (2.0 * z)).length() + 30.0
	horde.far_distance = horde.spawn_ring * 1.6


func _announce(text: String, color := Color(0.9, 0.15, 0.1)) -> void:
	announce_text = text
	announce_color = color
	announce_t = 1.4
	camera.shake(2.0)


func _on_splatter(pos: Vector2, strength: float) -> void:
	var d := pos.distance_to(player.global_position)
	if d < 70.0:
		var from := (pos - player.global_position).normalized()
		screen_blood.splash(strength * (1.0 - d / 70.0), from)
		player.add_dirt(3.0 * strength)


func _on_player_hurt(_amount: float) -> void:
	camera.shake(3.0)
	effects.blood_hit(player.global_position, Vector2.from_angle(randf() * TAU), false)
	player.add_dirt(2.0)
	screen_blood.splash(0.2)


func _on_player_died() -> void:
	game_over = true
	camera.shake(6.0)
	for i in 4:
		effects.blood_hit(player.global_position, Vector2.from_angle(randf() * TAU), true)


## Отладка: 4 ствола ур.5 с модулями — худший случай для производительности.
func _full_loadout() -> void:
	var setup := [
		[WeaponDefs.Base.RIFLE, WeaponDefs.Ammo.INCENDIARY, [WeaponDefs.Module.TWIN, WeaponDefs.Module.RICOCHET, WeaponDefs.Module.CHAIN]],
		[WeaponDefs.Base.SHOTGUN, WeaponDefs.Ammo.EXPANSIVE, [WeaponDefs.Module.DETONATOR, WeaponDefs.Module.SPLIT, WeaponDefs.Module.PIERCE]],
		[WeaponDefs.Base.RAIL, WeaponDefs.Ammo.CRYO, [WeaponDefs.Module.PIERCE, WeaponDefs.Module.RICOCHET, WeaponDefs.Module.SPLIT]],
		[WeaponDefs.Base.LAUNCHER, WeaponDefs.Ammo.STANDARD, [WeaponDefs.Module.SPLIT, WeaponDefs.Module.DETONATOR, WeaponDefs.Module.TWIN]],
	]
	for i in setup.size():
		if i >= weapons.slots.size():
			weapons.add_weapon(setup[i][0])
		var s: Weapons.Slot = weapons.slots[i]
		s.base = setup[i][0]
		s.level = WeaponDefs.MAX_LEVEL
		s.ammo = setup[i][1]
		s.ammo_rank = 3
		s.modules.clear()
		for m in setup[i][2]:
			s.modules.append({"id": m, "rank": 3, "rare": false})
		weapons.refresh(i)


func _sim_report() -> void:
	var parts: Array[String] = []
	for s in weapons.slots:
		var mods: Array[String] = []
		for m in s.modules:
			mods.append("%s%d" % [WeaponDefs.MODULES[m["id"]]["name"].left(4), m["rank"]])
		parts.append("%s L%d %s%d [%s]" % [WeaponDefs.BASES[s.base]["short"], s.level, WeaponDefs.AMMO[s.ammo]["name"].left(4), s.ammo_rank, ",".join(mods)])
	print("SIM %02d:00 level=%d kills=%d xp=%d/%d credits=%d/%d zombies=%d fps=%d | %s" % [int(time / 60.0), progression.level, kills,
		gems.collected_total, gems.spawned_total, credit_drops.collected_total, credit_drops.spawned_total, horde.count, Engine.get_frames_per_second(), " | ".join(parts)])
	if time >= _sim_until:
		get_tree().quit()


func _run_ui_test() -> void:
	await get_tree().create_timer(2.0).timeout
	progression.add_xp(Progression.xp_to_next(progression.level) - progression.xp)
	level_up.open([{"type": "module", "id": WeaponDefs.Module.RICOCHET, "rare": true},
		{"type": "weapon", "id": WeaponDefs.Base.SHOTGUN, "rare": false},
		{"type": "ammo", "id": WeaponDefs.Ammo.CRYO, "rare": false}])
	await get_tree().create_timer(1.0, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_cards.png"))
	level_up._pick(0)
	await get_tree().create_timer(0.5, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_slots.png"))
	level_up.close()
	progression.pending = 0
	progression.credits = 230
	time = TRADER_TIMES[0]
	_open_trader()
	await get_tree().create_timer(1.0, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_trader.png"))
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	Input.parse_input_event(key)
	await get_tree().create_timer(0.3, true).timeout
	print("UI test trader closed=%s paused=%s dashing=%s" % [not trader_ui.visible, get_tree().paused, player.is_dashing() or player.dash_cd > 0.0])
	print("UI test screenshots saved")
	get_tree().quit()


func _bench_step(delta: float) -> void:
	_bench_t += delta
	# перебираем типы смерти, чтобы на скриншоте были все
	if not _gore_stress:
		horde.death_override = int(_bench_t / 1.5) % Gore.Death.size()
	if _bench_t < BENCH_WARMUP:
		return
	_bench_frames += 1
	_bench_frame_ms += delta * 1000.0
	_bench_worst_ms = maxf(_bench_worst_ms, delta * 1000.0)
	_bench_horde_ms += horde.update_ms
	_bench_enemies += horde.count
	if _bench_t < BENCH_WARMUP + BENCH_DURATION:
		return
	_bench = false
	var n := float(_bench_frames)
	print("BENCH frames=%d avg_fps=%.1f avg_frame_ms=%.2f worst_frame_ms=%.2f horde_ms=%.2f enemies=%.0f kills=%d" % [
		_bench_frames, 1000.0 / (_bench_frame_ms / n), _bench_frame_ms / n, _bench_worst_ms,
		_bench_horde_ms / n, _bench_enemies / n, kills])
	print("BENCH process_ms=%.2f physics_ms=%.2f draw_calls=%d objects=%d gore=%d particles=%d wet=%d" % [
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.OBJECT_COUNT),
		gore.count, effects.particle_count(), floor_decals.pool_count()])
	if _shot_path != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_shot_path)
		print("BENCH screenshot: ", _shot_path)
	get_tree().quit()


## Управление задаём кодом по физическим клавишам — работает при любой раскладке.
static func _setup_input() -> void:
	_add_action("move_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_add_action("move_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_add_action("move_up", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_add_action("move_down", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_add_action("dash", [_key(KEY_SPACE), _key(KEY_SHIFT), _button(JOY_BUTTON_A)])
	_add_action("reload", [_key(KEY_R), _button(JOY_BUTTON_X)])


static func _add_action(action: StringName, events: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.25)
	for e in events:
		InputMap.action_add_event(action, e)


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


static func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e


static func _button(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e
