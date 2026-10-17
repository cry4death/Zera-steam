extends Node2D
## Корень сцены: связывает системы, ведёт время забега, отладочные клавиши и бенчмарк.
##
## Бенчмарк: godot --path . -- --bench[=кол-во_зомби] [--shot=путь.png]
## Держит 500 зомби, игрок бессмертен и бегает сам; в конце печатает замеры и выходит.
##
## Мета: godot --headless --path . -- --meta-test
## Сохранение, уровни класса, мастерская, ящики, статы с деревом и черты моделей; итог METATEST ok=true.
## Все тест-режимы работают на сохранении в памяти (Meta); --meta-preset=maxed и --meta=<json> подставляют мету.
##
## Предметы и граната: godot --path . -- --s3-test --shot=путь.png
## Орда, лужи крови, предметы на полу, бросок гранаты; снимки s3_*.png и строки S3TEST.
##
## Тревога: godot --path . -- --alarm [--no-fire] [--shot=путь.png]
## Старт в 6:55, оружие как --loadout, бессмертие; раз в секунду печатает ALARM t=..,
## в конце — худший кадр. С --no-fire зомби не убиваются (пик 500 живых).

const ARENA := Rect2(0, 0, 2560, 1440)
const BaseScreen := preload("res://scripts/base.gd")
const BENCH_TARGET := 500
var _bench_target := BENCH_TARGET
const BENCH_WARMUP := 3.0
const BENCH_DURATION := 10.0

const COMBO_WINDOW := 1.5 # сек между убийствами, чтобы серия не прервалась
const COMBO_TITLES := {10: "РЕЗНЯ!", 25: "МЯСОРУБКА!", 50: "КРОВАВАЯ БАНЯ!", 100: "БОЙНЯ!", 200: "АПОКАЛИПСИС!", 400: "ЖНЕЦ!"}
const MULTIKILL_WINDOW := 0.15
const DIRT_RADIUS := 48.0
# дроп предметов (BALANCE.md §2.1, §2.3, §11.4)
const MEDKIT_CHANCE := 0.004 # аптечка с любого врага
const MEDKIT_CHANCE_ELITE := 0.05
const MEDKIT_HEAL := 25.0
const CRATE_CHANCE_ELITE := 0.10 # оружейный ящик с элитки
const PART_CHANCE_ELITE := 0.20 # редкая деталь с элитки
const DROP_SCATTER := 10.0 # предметы с одной элитки не лежат стопкой
const CALM_RADIUS := 200.0 # затишье 9:00: зомби дальше этого от игрока убираются
const TRADER_TIMES := [300.0, 540.0] # визиты торговца: 5:00 и 9:00 (BALANCE.md §9.2)

var time := 0.0
var kills := 0
var game_over := false
var trader_visit := 0 # следующий визит торговца
var nades := 0 # брошено гранат (для отчёта --sim)
var crates := 0 # оружейные ящики, найденные за забег (открываются на базе, M6)
var military_crates := 0
var elites_killed := 0
var boss_phase_flash := 0.0
var _boss_test := false
var _boss_hp := -1.0
var _boss_warned := false
var _boss_spawned := false
var _boss_next_print := 595.0
var _boss_started := 0.0
var _boss_phase1_shot := false
var _boss_phase2_shot := false
var _boss_last_frame := 0
var _boss_death_worst_ms := 0.0
var _boss_death_usec := 0
var _boss_dbg_burst_ms := 0.0
var _boss_frames_dbg := ""
var _boss_fight_ms := 0.0
var _boss_fight_frames := 0
var _boss_fight_worst_ms := 0.0
var _boss_death_physics_ms := 0.0
var _boss_skip_frames := 0
var _boss_reward_pos := Vector2.INF
var _boss_reward_age := 0.0
var _boss_reward: Node2D
var _boss_crate_tex: Texture2D
var _alarm_xp := 0
var _alarm_credits := 0

# комбо и надписи (рисует HUD)
var combo := 0
var best_combo := 0
var announce_text := ""
var announce_t := 0.0
var announce_color := Color(0.9, 0.15, 0.1)
var _combo_timer := 0.0
var _burst_count := 0
var _burst_t := -1.0
var _loot_open := false # на экране награда (контейнер, деталь), а не Level Up
var _loot_queue: Array[Dictionary] = [] # параметры наград; карты создаём перед показом

# 400 обычных (8:00, BALANCE §7.1) + 6 элиток, пополняются отдельно.
const KINDS_COUNTS := [220, 100, 40, 40]
const KINDS_ELITES := 6
var _kinds := false
var _bench := false
var _shot_path := ""
var _bench_t := 0.0
var _zoom := 1.0
var _gore_stress := false
var _no_fire := false
var _ui_test := false
var _s3_test := false
var _weapons_test := false
var _meta_test := false
var _wtest_shot := false
var _wtest_started := 0.0
var _sim := false
var _sim_next_report := 60.0
var _sim_until := 600.0
var _sim_peak := 0 # пик живых зомби за минуту (отчёт --sim)
var _alarm := false
var _alarm_next_print := 0.0
var _alarm_worst_ms := 0.0
var _alarm_min_fps := 9999
var _alarm_peak := 0
var _alarm_shot_done := false
var _alarm_drop_shot_done := false
var _alarm_chain_done := false
var _alarm_chain_frames: Array[float] = []
var _alarm_end_t := -1.0
var _alarm_skip_frames := 0 # кадры вокруг снимка экрана в замер не идут
var _bench_frames := 0
var _bench_frame_ms := 0.0
var _bench_worst_ms := 0.0
var _bench_horde_ms := 0.0
var _bench_physics_ms := 0.0
var _bench_enemies := 0

@onready var sfx: Sfx = $Sfx
@onready var player: Player = $World/Player
@onready var horde: Horde = $World/Horde
@onready var weapons: Weapons = $World/Weapons
@onready var gems: Gems = $World/Gems
@onready var credit_drops: Gems = $World/Credits
@onready var pickups: Pickups = $World/Pickups
@onready var progression: Progression = $Progression
@onready var level_up: Control = $Overlay/LevelUp
@onready var trader: Trader = $Trader
@onready var trader_ui: Control = $Overlay/Trader
@onready var effects: Effects = $World/Effects
@onready var floor_decals: FloorDecals = $World/FloorDecals
@onready var gore: Gore = $World/Gore
@onready var ground: Node2D = $World/Ground
@onready var spawner: Spawner = $Spawner
@onready var hazards: Hazards = $World/Hazards
@onready var blood_alarm: BloodAlarm = $BloodAlarm
@onready var alarm_overlay: AlarmOverlay = $AlarmLayer/AlarmOverlay
@onready var alarm_tint: CanvasModulate = $AlarmTint
@onready var camera: GameCamera = $Camera
@onready var screen_blood: Control = $ScreenFX/ScreenBlood
@onready var boss: Boss = $World/Boss
@onready var results: RunResults = $Overlay/RunResults


func _enter_tree() -> void:
	_setup_input()


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--bench":
			_bench = true
		elif arg.begins_with("--bench="):
			_bench = true
			_bench_target = arg.trim_prefix("--bench=").to_int()
		elif arg == "--kinds":
			_kinds = true
			_bench = true
			_bench_target = 406
		elif arg.begins_with("--shot="):
			_shot_path = arg.trim_prefix("--shot=")
		elif arg == "--no-fire":
			_no_fire = true # для скриншотов живой орды: не стреляем и стоим на месте
		elif arg == "--weapons-test":
			_weapons_test = true
		elif arg == "--meta-test":
			_meta_test = true
		elif arg == "--loadout-w1":
			_w1_loadout.call_deferred()
		elif arg == "--loadout":
			_full_loadout.call_deferred() # бенчмарк с полным арсеналом
		elif arg == "--alarm":
			_alarm = true # тревога: старт в 6:55, оружие как --loadout
			_full_loadout.call_deferred()
		elif arg == "--boss":
			_boss_test = true
			_full_loadout.call_deferred()
		elif arg.begins_with("--boss-hp="):
			_boss_hp = arg.trim_prefix("--boss-hp=").to_float() # стартовое HP босса (быстрый тест смерти)
		elif arg == "--s3-test":
			_s3_test = true # предметы на кровавом полу и бросок гранаты
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
	effects.sfx = sfx
	player.sfx = sfx
	weapons.sfx = sfx
	gore.setup(floor_decals, effects, ARENA, player)
	player.arena = ARENA
	player.position = ARENA.get_center()
	player.effects = effects
	horde.setup(ARENA, player, floor_decals)
	weapons.player = player
	weapons.horde = horde
	weapons.boss = boss
	weapons.effects = effects
	weapons.floor_decals = floor_decals
	weapons.camera = camera
	gems.player = player
	credit_drops.player = player
	pickups.player = player
	pickups.effects = effects
	pickups.floor_decals = floor_decals
	pickups.camera = camera
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
	hazards.horde = horde
	hazards.player = player
	hazards.floor_decals = floor_decals
	hazards.effects = effects
	hazards.camera = camera
	boss.horde = horde
	boss.player = player
	boss.effects = effects
	boss.floor_decals = floor_decals
	boss.camera = camera
	boss.arena = ARENA
	boss.roar.connect(_on_boss_roar)
	boss.crushed.connect(_on_boss_crushed)
	boss.armor_plate.connect(_on_boss_plate)
	boss.phase_changed.connect(_on_boss_phase)
	boss.charge_telegraph.connect(func(_from: Vector2, _to: Vector2, _duration: float) -> void: camera.shake(1.8))
	boss.slam_started.connect(func(at: Vector2) -> void:
		camera.shake(6.0)
		sfx.play("explosions/grenade", at, 1.0, 0.02))
	boss.died.connect(_on_boss_died)
	results.restart_requested.connect(_restart_run)
	results.base_requested.connect(_return_to_base)
	_boss_crate_tex = PixelArt.tex("military_crate")
	_boss_reward = Node2D.new()
	_boss_reward.z_index = 10
	$World.add_child(_boss_reward)
	_boss_reward.draw.connect(_draw_boss_reward)
	blood_alarm.spawner = spawner
	blood_alarm.player = player
	blood_alarm.overlay = alarm_overlay
	blood_alarm.tint = alarm_tint
	blood_alarm.verbose = _sim or _alarm
	camera.setup(ARENA, player)
	get_viewport().size_changed.connect(_update_view)
	_update_view()

	horde.enemy_killed.connect(_on_enemy_killed)
	horde.enemy_died.connect(_on_enemy_died)
	horde.enemy_killed.connect(gore.on_enemy_killed)
	horde.enemy_wounded.connect(gore.on_enemy_wounded)
	horde.enemy_hit.connect(gore.on_enemy_hit)
	horde.spit_fired.connect(hazards.spit)
	horde.fat_burst.connect(hazards.fat_explosion)
	blood_alarm.container_dropped.connect(_on_container_dropped)
	gore.splatter.connect(_on_splatter)
	horde.player_touched.connect(player.take_damage)
	player.hurt.connect(_on_player_hurt)
	player.grenade_landed.connect(_on_grenade_landed)
	pickups.collected.connect(_on_pickup)
	player.died.connect(_on_player_died)
	player.adrenaline_fired.connect(_on_adrenaline)
	gems.collected.connect(progression.add_xp)
	credit_drops.collected.connect(_on_credits_collected)
	progression.level_ready.connect(_on_level_ready)
	level_up.chosen.connect(_on_card_chosen)
	level_up.reroll_requested.connect(_on_reroll)
	trader_ui.closed.connect(_on_trader_closed)
	weapons.prototype_unlocked.connect(_on_prototype)

	if _meta_test:
		weapons.process_mode = Node.PROCESS_MODE_DISABLED
		spawner.enabled = false
		gems.collected.disconnect(progression.add_xp)
		_run_meta_test.call_deferred()
	if OS.get_cmdline_user_args().has("--base-test"):
		spawner.enabled = false
		player.god_mode = true
		_run_base_test.call_deferred()
	if _weapons_test:
		weapons.process_mode = Node.PROCESS_MODE_DISABLED
		_run_weapons_test.call_deferred()
	if _sim:
		print("SIM meta: class_level=%d tree=%d workshop_models=%d owned=%d bonuses=%s models=%s" % [Meta.class_level(), Meta.tree.size(), Meta.workshop.size(), Meta.owned.size(), Meta.run_bonuses(), weapons.slots[0].model])
		player.god_mode = true
		player.autopilot = true
		Engine.time_scale = 4.0
		Engine.max_physics_steps_per_frame = 16
	if _boss_test:
		time = 595.0
		trader_visit = TRADER_TIMES.size()
		player.god_mode = true
		player.autopilot = true
		# Готовый билд проверяется без случайного роста от опыта во время боя.
		gems.collected.disconnect(progression.add_xp)
		# Кадры считаем по отрисовке, а не по _process: на хит-стопе игра на паузе, а картинка идёт.
		_boss_last_frame = Time.get_ticks_usec()
		RenderingServer.frame_post_draw.connect(_boss_frame_tick)
	if _alarm:
		time = BloodAlarm.START - 5.0
		trader_visit = 1 # лавку 5:00 пропускаем
		player.god_mode = true
		player.autopilot = not _no_fire
		_alarm_prefill()
		if _no_fire:
			weapons.process_mode = Node.PROCESS_MODE_DISABLED
	if _ui_test:
		_run_ui_test()
	if _s3_test:
		spawner.enabled = false
		_run_s3_test()
	if _bench:
		player.god_mode = true
		player.autopilot = true
		spawner.enabled = false
		if _kinds:
			_fill_kinds(true)
		if _no_fire:
			player.autopilot = false
			weapons.process_mode = Node.PROCESS_MODE_DISABLED


func _physics_process(delta: float) -> void:
	if game_over:
		return
	time += delta
	if not _bench and not _ui_test and not _s3_test and not _weapons_test:
		_boss_timeline()
	if _boss_test and boss.is_alive():
		# Чередуем сближение и отход; автопилот не стоит в упор весь бой.
		var away := (player.global_position - boss.global_position).normalized()
		var distance := 160.0 + 100.0 * sin((time - _boss_started) * 0.22)
		player.auto_target = boss.global_position + away * distance + away.orthogonal() * 70.0
	if _sim:
		player.auto_target = pickups.nearest(player.global_position, 400.0)
		if player.auto_target == Vector2.INF:
			player.auto_target = gems.nearest(player.global_position, 260.0)
		_sim_grenade()
		_sim_peak = maxi(_sim_peak, horde.count)
		if player.adrenaline and weapons.any_reloading():
			player.try_dash() # «Адреналин» используется как в живой игре: рывок, когда стволы на перезарядке
	horde.minutes = time / 60.0
	spawner.time = time
	blood_alarm.time = time
	hazards.minutes = time / 60.0
	boss.minutes = time / 60.0
	credit_drops.radius = gems.radius # пассивка подбора действует и на кредиты
	if trader_visit < TRADER_TIMES.size() and time >= TRADER_TIMES[trader_visit]:
		_open_trader()
	if _sim and (time >= _sim_next_report or time >= _sim_until):
		_sim_next_report += 60.0
		_sim_report()
	if _weapons_test and horde.count < 40:
		var p := player.global_position + Vector2.from_angle(randf_range(-0.7, 0.7)) * randf_range(85.0, 130.0)
		var e := horde.spawn(p)
		if e >= 0:
			horde.speed[e] = 7.0
	if _bench and horde.count < _bench_target:
		if _kinds:
			_fill_kinds()
		else:
			horde.spawn_group(player.global_position, mini(15, _bench_target - horde.count))
	if _gore_stress and horde.count > 0:
		for k in 2:
			var i := randi() % horde.count
			var dir := (horde.pos[i] - player.global_position).normalized()
			horde.death_override = randi() % Gore.Death.size()
			horde.damage(i, 3.0 if randf() < 0.5 else 9999.0, dir, 0.0, WeaponDefs.Ammo.STANDARD, false, horde.pos[i] + dir.orthogonal() * 3.0)
		horde.death_override = -1


func _process(delta: float) -> void:
	boss_phase_flash = maxf(0.0, boss_phase_flash - delta)
	if _boss_reward_pos != Vector2.INF:
		_boss_reward_age += delta
		_boss_reward.queue_redraw()
	if _boss_test:
		_boss_test_step()
	if _bench:
		_bench_step(delta)
	if _alarm:
		_alarm_step(delta)
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
			for j in 10:
				horde.spawn(player.global_position + Vector2(130.0, 0.0) + Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0)), Horde.Kind.RUNNER)
		KEY_F8:
			horde.spawn(player.global_position + Vector2(100.0, 0.0), Horde.Kind.FAT)
		KEY_F9:
			horde.spawn(player.global_position + Vector2(150.0, 0.0), Horde.Kind.SPITTER)
		KEY_F10:
			horde.spawn(player.global_position + Vector2(110.0, 0.0), randi() % Horde.Kind.size(), true)
		KEY_F6:
			# перебор типа смерти: авто → все типы по очереди
			horde.death_override += 1
			if horde.death_override >= Gore.Death.size():
				horde.death_override = -1


## «Адреналин»: рывок зарядил все стволы.
func _on_adrenaline() -> void:
	weapons.refill_all()
	for k in 10:
		effects.emit(player.global_position, Vector2.from_angle(randf() * TAU) * randf_range(20.0, 70.0), randf_range(0.2, 0.4), Color(1.0, 0.45, 0.7), 1.5, 4.0)


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


## Дроп по типу врага (таблица Horde.KINDS), тревога удваивает опыт и кредиты.
func _on_enemy_died(pos: Vector2, kind: int, is_elite: bool) -> void:
	if is_elite:
		elites_killed += 1
	var mult := roundi(blood_alarm.reward_mult())
	var xp_before := gems.spawned_total
	var credits_before := credit_drops.spawned_total
	var def: Dictionary = Horde.KINDS[kind]
	if is_elite:
		gems.spawn(pos, Horde.ELITE_XP * mult)
		credit_drops.spawn(pos, Horde.ELITE_CREDITS * mult) # у элитки кредиты гарантированы
		if randf() < CRATE_CHANCE_ELITE:
			pickups.spawn(_scatter(pos), Pickups.Kind.CRATE)
		if randf() < PART_CHANCE_ELITE:
			pickups.spawn(_scatter(pos), Pickups.Kind.PART)
	else:
		gems.spawn(pos, int(def["xp"]) * mult)
		if randf() < float(def["credit_chance"]):
			credit_drops.spawn(pos, int(def["credits"]) * mult)
	if randf() < (MEDKIT_CHANCE_ELITE if is_elite else MEDKIT_CHANCE):
		pickups.spawn(_scatter(pos), Pickups.Kind.MEDKIT)
	if mult > 1:
		_alarm_xp += gems.spawned_total - xp_before
		_alarm_credits += credit_drops.spawned_total - credits_before


func _scatter(p: Vector2) -> Vector2:
	return p + Vector2.from_angle(randf() * TAU) * randf_range(0.0, DROP_SCATTER)


## Граната игрока приземлилась: взрыв без привязки к стволу, рвёт на гибы.
func _on_grenade_landed(at: Vector2) -> void:
	nades += 1
	weapons.explode(at, Player.GRENADE_DAMAGE, Player.GRENADE_RADIUS)


## Контейнер тревоги упал: он лежит до подбора (см. Pickups).
func _on_container_dropped(pos: Vector2) -> void:
	_alarm_end_t = time
	pickups.spawn(pos, Pickups.Kind.CONTAINER)
	if _alarm and _shot_path != "":
		player.autopilot = false # даём снять приземлившийся контейнер до автоподбора
	if _sim or _alarm:
		print("CONTAINER dropped pos=%s time=%02d:%02d" % [pos, int(time) / 60, int(time) % 60])
		print("ALARM rewards mult=2 xp=%d credits=%d" % [_alarm_xp, _alarm_credits])


# --- Предметы -----------------------------------------------------------------------------

func _on_pickup(kind: int, pos: Vector2) -> void:
	match kind:
		Pickups.Kind.MEDKIT:
			player.hp = minf(player.hp + MEDKIT_HEAL, player.max_hp)
			for k in 8:
				effects.emit(pos, Vector2.from_angle(randf() * TAU) * randf_range(10.0, 50.0), randf_range(0.3, 0.6), Color(0.4, 1.0, 0.5), 1.5, 4.0)
		Pickups.Kind.CRATE:
			crates += 1
			_announce("ОРУЖЕЙНЫЙ ЯЩИК", Color(1.0, 0.75, 0.3))
		Pickups.Kind.PART:
			_open_loot("РЕДКАЯ ДЕТАЛЬ", "выбери одну из двух", 2, true, true)
		Pickups.Kind.CONTAINER:
			crates += 1
			_open_loot("КРОВАВЫЙ КОНТЕЙНЕР", "выбери модуль · +1 оружейный ящик", 3, false, false)
			if _sim or _alarm:
				print("CONTAINER picked time=%02d:%02d crates=%d" % [int(time) / 60, int(time) % 60, crates])


## Карты награды: модули (контейнер) или модули и патроны (деталь). Выбор не списывает
## отложенный Level Up. all_rare — все карты редкие, иначе по шансу, но хотя бы одна редкая.
func _loot_cards(count: int, with_ammo: bool, all_rare: bool) -> Array:
	var options: Array = []
	for m in WeaponDefs.MODULES:
		for i in weapons.slots.size():
			if progression.module_status(i, m) != "":
				options.append({"type": "module", "id": m})
				break
	if with_ammo:
		for a in WeaponDefs.AMMO.size():
			for i in weapons.slots.size():
				if progression.ammo_status(i, a) != "":
					options.append({"type": "ammo", "id": a})
					break
	options.shuffle()
	var cards: Array = options.slice(0, count)
	var rare_chance := 0.05 + 0.015 * time / 60.0 # как у обычных карт Level Up
	var any_rare := false
	for c: Dictionary in cards:
		c["rare"] = all_rare or randf() < rare_chance
		any_rare = any_rare or c["rare"]
	if not any_rare and not cards.is_empty():
		cards.pick_random()["rare"] = true
	return cards


func _open_loot(title: String, sub: String, count: int, with_ammo: bool, all_rare: bool) -> void:
	if game_over:
		return
	if _bench or _sim or _alarm or _weapons_test or _boss_test:
		var cards := _loot_cards(count, with_ammo, all_rare)
		if cards.is_empty():
			return
		var card: Dictionary = cards.pick_random()
		var slot := _auto_slot(card)
		if slot != -2:
			if _sim:
				print("LOOT %s: %s slot=%d rare=%s" % [title, card["type"], slot, card["rare"]])
			progression.apply(card, slot, false)
		return
	_loot_queue.append({"title": title, "sub": sub, "count": count, "ammo": with_ammo, "rare": all_rare})
	if not level_up.visible and not trader_ui.visible:
		_show_next_loot()


func _show_next_loot() -> void:
	while not _loot_queue.is_empty():
		var loot: Dictionary = _loot_queue.pop_front()
		# Предыдущая награда могла довести модуль до III — не предлагаем устаревшие карты.
		var cards := _loot_cards(loot["count"], loot["ammo"], loot["rare"])
		if cards.is_empty():
			_announce("НЕЧЕГО УЛУЧШАТЬ", Color(0.7, 0.7, 0.66))
			continue
		_loot_open = true
		get_tree().paused = true
		level_up.open(cards, loot["title"], loot["sub"])
		return
	_after_overlay()


## Куда автоматически поставить карту: -1 — слот не нужен, -2 — некуда.
func _auto_slot(card: Dictionary) -> int:
	if not Progression.needs_slot(card):
		return -1
	for i in weapons.slots.size():
		if progression.slot_status(card, i) != "":
			return i
	return -2


## Симуляция: бросаем гранату, если в точке падения набралась кучка зомби.
func _sim_grenade() -> void:
	if horde.count == 0 or player.grenade_cd > 0.0 or player.is_dead:
		return
	if horde.query_radius(player.grenade_target(), Player.GRENADE_RADIUS * 0.8).size() >= 6:
		player.throw_grenade()


func _on_credits_collected(value: int) -> void:
	progression.credits += value


# --- Level Up ---------------------------------------------------------------------------

func _on_level_ready() -> void:
	if game_over:
		return
	if level_up.visible or trader_ui.visible:
		return
	if _bench or _sim or _alarm or _weapons_test or _boss_test:
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
	if _loot_open:
		# награда (контейнер, деталь): Level Up не списывается
		progression.apply(card, slot, false)
		_loot_open = false
	else:
		progression.apply(card, slot)
	_after_overlay()


## Экран закрыт: сначала следующая награда, потом отложенные Level Up, иначе игра идёт.
func _after_overlay() -> void:
	if not _loot_queue.is_empty():
		_show_next_loot()
	elif progression.pending > 0:
		get_tree().paused = true
		level_up.open(progression.make_cards(time / 60.0))
	else:
		level_up.close()
		get_tree().paused = false


func _on_reroll() -> void:
	if _loot_open or progression.rerolls <= 0:
		return
	progression.rerolls -= 1
	level_up.open(progression.make_cards(time / 60.0))


# --- Торговец ---------------------------------------------------------------------------

func _open_trader() -> void:
	if game_over:
		return
	if level_up.visible:
		return # награда могла открыться в этом же физическом кадре
	# F4 может перескочить сразу через оба визита — открываем последний наступивший
	while trader_visit + 1 < TRADER_TIMES.size() and time >= TRADER_TIMES[trader_visit + 1]:
		trader_visit += 1
	var index := trader_visit
	trader_visit += 1
	trader.start_visit(index, time / 60.0)
	if index == 1:
		# затишье 9:00: дальних зомби тихо убираем, чтобы после лавки не выйти в стену мяса
		var removed := horde.despawn_far(player.global_position, CALM_RADIUS)
		if _sim:
			print("CALM %02d:%02d removed=%d left=%d" % [int(time) / 60, int(time) % 60, removed, horde.count - removed])
	if _bench or _sim or _alarm or _weapons_test or _boss_test:
		_auto_shop()
		return
	get_tree().paused = true
	trader_ui.open(trader, progression, weapons, time / 60.0)


func _on_trader_closed() -> void:
	# Space закрывает лавку и он же рывок: ждём физический кадр, чтобы нажатие не стало рывком
	await get_tree().physics_frame
	await get_tree().physics_frame
	get_tree().paused = false
	if not _loot_queue.is_empty():
		_show_next_loot()
	elif progression.pending > 0:
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
	if game_over:
		return
	game_over = true
	spawner.enabled = false
	camera.shake(6.0)
	for i in 4:
		effects.blood_hit(player.global_position, Vector2.from_angle(randf() * TAU), true)
	await get_tree().create_timer(0.6, false).timeout
	_open_results(false)


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
		s.set_model(Meta.model_for(setup[i][0]))
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
		parts.append("%s L%d %s%d [%s]" % [s.short_name(), s.level, WeaponDefs.AMMO[s.ammo]["name"].left(4), s.ammo_rank, ",".join(mods)])
	var alive := [0, 0, 0, 0]
	var elites := 0
	for i in horde.count:
		alive[horde.kind[i]] += 1
		elites += horde.elite[i]
	print("SIM %02d:00 level=%d kills=%d xp=%d/%d credits=%d/%d credits_left=%d zombies=%d kinds=%d/%d/%d/%d elites=%d elites_spawned=%d crates=%d nades=%d dmg_taken=%d peak=%d fps=%d | %s" % [int(time / 60.0), progression.level, kills,
		gems.collected_total, gems.spawned_total, credit_drops.collected_total, credit_drops.spawned_total, progression.credits, horde.count,
		alive[0], alive[1], alive[2], alive[3], elites, spawner.elites_spawned, crates, nades, roundi(player.damage_taken), _sim_peak, Engine.get_frames_per_second(), " | ".join(parts)])
	_sim_peak = 0
	if time >= _sim_until:
		get_tree().quit()


## --alarm: к 6:55 на поле уже ~300 зомби (350 — лимит 6:00), доли как в строке 6:00.
func _alarm_prefill() -> void:
	for j in 300:
		var r := randf()
		var k := Horde.Kind.SHAMBLER if r < 0.6 else (Horde.Kind.RUNNER if r < 0.8 else (Horde.Kind.FAT if r < 0.9 else Horde.Kind.SPITTER))
		horde.spawn(player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(90.0, 330.0), k)


func _alarm_step(delta: float) -> void:
	var ms := delta * 1000.0
	_alarm_skip_frames -= 1
	var t_rel := time - BloodAlarm.START # 0 = начало предупреждения
	if ms > 40.0:
		print("HITCH %.1f ms t=%.2f zombies=%d level=%d" % [ms, t_rel, horde.count, progression.level])
	if t_rel >= -3.0 and _alarm_skip_frames <= 0:
		_alarm_worst_ms = maxf(_alarm_worst_ms, ms)
		_alarm_min_fps = mini(_alarm_min_fps, Engine.get_frames_per_second())
		_alarm_peak = maxi(_alarm_peak, horde.count)
	if time >= _alarm_next_print:
		_alarm_next_print = floorf(time) + 1.0
		print("ALARM t=%.0f phase=%s zombies=%d fps=%d worst_ms=%.1f pools=%d spits=%d" % [t_rel, BloodAlarm.Phase.keys()[blood_alarm.phase],
			horde.count, Engine.get_frames_per_second(), _alarm_worst_ms, hazards.pool_count(), hazards.projectile_count()])
	# цепной взрыв толстяков: 12 штук кучей, лопаем одного, два шага замеряем худший кадр
	if not _alarm_chain_done and t_rel >= BloodAlarm.WARN_TIME + 10.0:
		_alarm_chain_done = true
		var at := player.global_position + Vector2(70.0, 0.0)
		var first := -1
		for j in 12:
			var idx := horde.spawn(at + Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0)), Horde.Kind.FAT)
			if first == -1:
				first = idx
		_alarm_chain_frames.clear()
		horde.damage(first, 9999.0, Vector2.RIGHT, 0.0)
		print("CHAIN fats spawned, first burst queued, alive=%d" % horde.count)
	if _alarm_chain_done and t_rel < BloodAlarm.WARN_TIME + 12.5 and t_rel >= BloodAlarm.WARN_TIME + 10.0:
		_alarm_chain_frames.append(ms)
	elif _alarm_chain_done and not _alarm_chain_frames.is_empty() and _alarm_chain_frames[0] >= 0.0:
		var worst := 0.0
		for f in _alarm_chain_frames:
			worst = maxf(worst, f)
		print("CHAIN worst_frame_ms=%.1f frames=%d" % [worst, _alarm_chain_frames.size()])
		_alarm_chain_frames[0] = -1.0
	if not _alarm_shot_done and t_rel >= BloodAlarm.WARN_TIME + 15.0:
		_alarm_shot_done = true
		if _shot_path != "":
			_announce("МУЛЬТИКИЛЛ ×15") # проверка: анонс не перекрывает заголовок тревоги
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(_shot_path)
			print("ALARM screenshot: ", _shot_path)
			_alarm_skip_frames = 3
	if _alarm_end_t >= 0.0 and not _alarm_drop_shot_done and _shot_path != "" and time >= _alarm_end_t + 0.9:
		_alarm_drop_shot_done = true # контейнер уже приземлился
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_container.png"))
		print("ALARM screenshot: ", _shot_path.replace(".png", "_container.png"))
		player.autopilot = not _no_fire
		_alarm_skip_frames = 3
	if _alarm_end_t >= 0.0 and time >= _alarm_end_t + 2.0:
		_alarm = false
		print("ALARM summary peak_zombies=%d min_fps=%d worst_frame_ms=%.1f physics_ms=%.2f process_ms=%.2f draw_calls=%d horde_ms=%.2f" % [
			_alarm_peak, _alarm_min_fps, _alarm_worst_ms, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), horde.update_ms])
		get_tree().quit()


func _run_meta_test() -> void:
	var ok: bool = await MetaTest.run(self)
	get_tree().quit(0 if ok else 1)


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
	# экран контейнера при двух отложенных Level Up: выбор их не списывает
	progression.pending = 2
	_open_loot("КРОВАВЫЙ КОНТЕЙНЕР", "выбери модуль · +1 оружейный ящик", 3, false, false)
	await get_tree().create_timer(1.0, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_container.png"))
	var rerolls_before := progression.rerolls
	_on_reroll()
	assert(progression.rerolls == rerolls_before and _loot_open)
	print("UI test container reroll_blocked=true cards=%d" % level_up.cards.size())
	level_up._pick(0)
	await get_tree().create_timer(0.3, true).timeout
	if level_up._card.is_empty() == false:
		level_up._pick(0) # модуль на первый ствол
		await get_tree().create_timer(0.3, true).timeout
	print("UI test container pending_kept=%s level_up_open_again=%s loot_open=%s" % [progression.pending == 2, level_up.visible, _loot_open])
	assert(progression.pending == 2 and level_up.visible and not _loot_open)
	level_up.close()
	progression.pending = 0
	get_tree().paused = false
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
	_open_results(false)
	await get_tree().create_timer(1.5, true).timeout
	await _boss_screenshot("defeat")
	results.visible = false
	military_crates = 1
	_open_results(true)
	await get_tree().create_timer(1.5, true).timeout
	await _boss_screenshot("results")
	print("UI test results victory=true military=1 dna=%d paused=%s" % [results._stats["dna_total"], get_tree().paused])
	print("UI test screenshots saved")
	get_tree().quit()


## Последние полминуты сохраняют слабую орду; предупреждение не мешает управлению.
func _boss_timeline() -> void:
	if time >= 570.0 and not _boss_warned:
		_boss_warned = true
		_announce("ОБЪЕКТ-7 ПРИБЛИЖАЕТСЯ", Color(1.0, 0.34, 0.16))
		camera.shake(6.0)
	if time < 600.0 or _boss_spawned:
		return
	_boss_spawned = true
	_boss_started = time
	var dir := -player.facing.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.LEFT
	var half := get_viewport().get_visible_rect().size / camera.zoom * 0.5
	var edge := minf(half.x / maxf(absf(dir.x), 0.0001), half.y / maxf(absf(dir.y), 0.0001))
	var at := camera.get_screen_center_position() + dir * (edge + Boss.RADIUS + 16.0)
	boss.start(at)
	if _boss_test and _boss_hp > 0.0:
		boss.hp = _boss_hp # --boss-hp=N: быстрый прогон смерти босса
	_announce("ОБЪЕКТ-7", Color(1.0, 0.34, 0.16))
	camera.shake(8.0)
	if _boss_test or _sim:
		print("BOSS spawn t=%.2f pos=%s hp=%.0f" % [time, boss.global_position, boss.hp])


func _on_boss_roar(count: int) -> void:
	for i in count:
		var at := boss.global_position + Vector2.from_angle(TAU * i / count) * randf_range(42.0, 70.0)
		horde.spawn(at.clamp(ARENA.position + Vector2.ONE * 12.0, ARENA.end - Vector2.ONE * 12.0), Horde.Kind.RUNNER)


func _on_boss_crushed(at: Vector2, dir: Vector2) -> void:
	floor_decals.stamp(PixelArt.tex("crushed_%d" % (randi() % 3)), at, dir.angle(), Color.WHITE)
	effects.blood_burst(at, dir, 12, 140.0, 0.65)


func _on_boss_plate(at: Vector2, dir: Vector2) -> void:
	gore.boss_plate(at, dir)
	sfx.play("casings/mag_drop", at, -6.0)


func _on_boss_phase(_phase: int) -> void:
	boss_phase_flash = 0.7
	_announce("БРОНЯ СОРВАНА", Color(1.0, 0.36, 0.18))


## Реальные секунды: хит-стоп и замедление не растягивают задержку до итогов.
func _on_boss_died(at: Vector2) -> void:
	if game_over:
		return
	game_over = true
	spawner.enabled = false
	weapons.firing_enabled = false
	player.set_physics_process(false)
	player.god_mode = true
	hazards.clear()
	hazards.set_physics_process(false)
	military_crates += 1
	_boss_reward_pos = at
	_boss_reward_age = 0.0
	camera.shake(14.0)
	_boss_death_usec = Time.get_ticks_usec()
	gore.boss_burst(at)
	_boss_dbg_burst_ms = (Time.get_ticks_usec() - _boss_death_usec) / 1000.0
	sfx.play("explosions/grenade", at, 3.0, 0.02)
	screen_blood.splash(1.0, (at - player.global_position).normalized())
	player.add_dirt(15.0)
	# Индексы орды стабильны до конца физического тика.
	var previous := horde.death_override
	horde.death_override = Gore.Death.GIBS
	for i in horde.query_radius(at, 200.0):
		if horde.dead[i] == 0:
			horde.damage(i, 99999.0, (horde.pos[i] - at).normalized(), 250.0, WeaponDefs.Ammo.STANDARD, false, horde.pos[i], true)
	horde.death_override = previous
	if _boss_test:
		print("BOSS death cpu: burst=%.2f ms, total handler=%.2f ms" % [_boss_dbg_burst_ms, (Time.get_ticks_usec() - _boss_death_usec) / 1000.0])
	_announce("ОБЪЕКТ-7 УНИЧТОЖЕН", Color(1.0, 0.82, 0.35))
	if _boss_test or _sim:
		print("BOSS killed fight_s=%.2f military_crates=%d" % [time - _boss_started, military_crates])
	get_tree().paused = true
	await get_tree().create_timer(0.15, true, false, true).timeout
	Engine.time_scale = 0.25
	get_tree().paused = false
	await get_tree().create_timer(0.6, true, false, true).timeout
	Engine.time_scale = 1.0
	if _boss_test:
		# Снимок смерти — когда куски долетели и запеклись в пол, перед самым экраном итогов.
		await get_tree().create_timer(1.15, true, false, true).timeout
		await _boss_screenshot("death")
		await get_tree().create_timer(0.6, true, false, true).timeout
	else:
		await get_tree().create_timer(1.75, true, false, true).timeout
	_open_results(true)
	if _boss_test:
		await get_tree().create_timer(1.5, true, false, true).timeout
		await _boss_screenshot("results")
		print("BOSS summary victory=true fight_s=%.2f death_worst_frame_ms=%.2f death_physics_ms=%.2f fight_avg_frame_ms=%.2f fight_worst_frame_ms=%.2f dna=%d" % [time - _boss_started, _boss_death_worst_ms, _boss_death_physics_ms,
			_boss_fight_ms / maxi(_boss_fight_frames, 1), _boss_fight_worst_ms, results._stats["dna_total"]])
		for i in Weapons.GUN_IDS.size():
			print("BOSS damage %s=%.2f" % [Weapons.GUN_IDS[i], weapons.boss_damage[i]])
		print("BOSS sources ", weapons.boss_sources)
		print("BOSS death frames ms (first 1.5 s): ", _boss_frames_dbg)
		get_tree().quit()
	elif _sim:
		_sim_report()
		get_tree().quit()


func _result_stats(victory: bool) -> Dictionary:
	var names: Array[String] = []
	for s in weapons.slots:
		names.append("%s ур.%d · %s %s" % [WeaponDefs.MODELS[s.model]["name"], s.level, WeaponDefs.AMMO[s.ammo]["name"], WeaponDefs.ROMAN[s.ammo_rank]])
	var lines: Array[Array] = [["Время × 10", floori(time / 6.0)], ["Убийства / 50", kills / 50], ["Элитки × 5", elites_killed * 5]]
	var subtotal := 0
	for line in lines:
		subtotal += int(line[1])
	var mult := 1.5 if victory else 1.0
	return {"victory": victory, "time": time, "kills": kills, "elites": elites_killed, "best_combo": best_combo,
		"blood_liters": floor_decals.stamps_total * 0.015, "weapons": names, "crates": crates, "military_crates": military_crates,
		"dna_lines": lines, "dna_mult": mult, "dna_total": floori(subtotal * mult)}


func _open_results(victory: bool) -> void:
	game_over = true
	Engine.time_scale = 1.0
	level_up.close()
	trader_ui.visible = false
	alarm_overlay.stop()
	results.open(_result_stats(victory))
	get_tree().paused = true


func _restart_run() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred("res://scenes/main.tscn")


func _return_to_base() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	# Возврат из тестового боя тоже показывает базу, не повторяя маршрутизацию CLI.
	get_tree().set_meta("s6_return_to_base", true)
	get_tree().change_scene_to_file.call_deferred("res://scenes/base.tscn")


## Проверяет обе кнопки итогов на настоящих переходах сцен и состояние Meta между ними.
func _run_base_test() -> void:
	await get_tree().create_timer(0.4).timeout
	BaseScreen._check("battle favorite+workshop applied", weapons.slots[0].model == "m4" and is_equal_approx(float(weapons.slots[0].stats["damage"]), 8.0 * 1.10 * 1.08))
	if BaseScreen._test_stage == 1:
		time = 60.0
		kills = 100
		await _on_player_died()
		await get_tree().create_timer(1.8, true).timeout
		await _boss_screenshot("base_defeat")
		BaseScreen._check("defeat rewards once+paused", Meta.runs == 1 and get_tree().paused)
		BaseScreen._test_stage = 2
		var again := InputEventKey.new()
		again.keycode = KEY_R
		again.physical_keycode = KEY_R
		again.pressed = true
		Input.parse_input_event(again)
		again = again.duplicate()
		again.pressed = false
		Input.parse_input_event(again)
	else:
		BaseScreen._check("restart main scene+meta kept", Meta.runs == 1 and not game_over and not get_tree().paused)
		time = 120.0
		kills = 200
		crates = 2
		military_crates = 1
		_open_results(true)
		await get_tree().create_timer(1.8, true).timeout
		await _boss_screenshot("base_results")
		BaseScreen._check("victory rewards once+paused", Meta.runs == 2 and get_tree().paused)
		var home := InputEventMouseButton.new()
		home.position = results._base_button.get_center() * results._ui
		home.button_index = MOUSE_BUTTON_LEFT
		home.pressed = true
		Input.parse_input_event(home)
		home = home.duplicate()
		home.pressed = false
		Input.parse_input_event(home)


func _draw_boss_reward() -> void:
	if _boss_reward_pos == Vector2.INF:
		return
	var t := clampf(_boss_reward_age / 0.8, 0.0, 1.0)
	var height := 48.0 * pow(1.0 - t, 2.0) + absf(sin(t * PI * 3.0)) * 5.0 * (1.0 - t)
	PixelArt.draw_dot(_boss_reward, _boss_reward_pos, 12.0, Color(0.02, 0.02, 0.01, 0.5))
	_boss_reward.draw_set_transform(_boss_reward_pos - Vector2(0, height), 0.0, Vector2.ONE * PixelArt.ART_SCALE)
	_boss_reward.draw_texture(_boss_crate_tex, -_boss_crate_tex.get_size() * 0.5)
	_boss_reward.draw_set_transform(Vector2.ZERO)
	_boss_reward.draw_string(ThemeDB.fallback_font, _boss_reward_pos + Vector2(-44, -20 - height), "+1 ВОЕННЫЙ ЯЩИК", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.82, 0.35))


## Худший кадр от смерти босса до экрана итогов (кадры сразу после скриншота не считаются).
func _boss_frame_tick() -> void:
	var now := Time.get_ticks_usec()
	var frame_ms := (now - _boss_last_frame) / 1000.0
	_boss_last_frame = now
	if _boss_skip_frames > 0:
		_boss_skip_frames -= 1
		return
	if boss.is_alive():
		_boss_fight_ms += frame_ms
		_boss_fight_frames += 1
		_boss_fight_worst_ms = maxf(_boss_fight_worst_ms, frame_ms)
	if game_over and _boss_death_usec > 0 and not results.visible:
		_boss_death_worst_ms = maxf(_boss_death_worst_ms, frame_ms)
		if now - _boss_death_usec < 1500000:
			_boss_frames_dbg += "%.0f " % frame_ms
		if frame_ms > 25.0:
			print("BOSS death frame %.1f ms at +%.2f s (real) process=%.1f physics=%.1f draw_calls=%d gore=%d particles=%d" % [frame_ms, (now - _boss_death_usec) / 1000000.0,
				Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), gore.count, effects.particle_count()])
		_boss_death_physics_ms = maxf(_boss_death_physics_ms, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)


func _boss_test_step() -> void:
	if time >= _boss_next_print:
		_boss_next_print += 1.0
		print("BOSS t=%.2f hp=%.0f phase=%d fps=%d" % [time, boss.hp, boss.phase, Engine.get_frames_per_second()])
	var offset := (boss.global_position - camera.get_screen_center_position()) * camera.zoom
	var half := get_viewport().get_visible_rect().size * 0.5
	# Босс ближе к центру кадра: на снимке видны тело, броня и орда рядом.
	var framed := absf(offset.x) < 500.0 and offset.y > -half.y + 290.0 and offset.y < half.y - 420.0
	if boss.is_alive() and boss.phase == 1 and boss._flash <= 0.0 and time >= _boss_started + 2.0 and framed and not _boss_phase1_shot:
		_boss_phase1_shot = true
		_boss_screenshot("phase1")
	if boss.phase == 2 and boss._flash <= 0.0 and boss_phase_flash <= 0.0 and framed and not _boss_phase2_shot:
		_boss_phase2_shot = true
		_boss_screenshot("phase2")
	if time > 840.0:
		print("BOSS timeout hp=%.0f" % boss.hp)
		get_tree().quit(1)


func _boss_screenshot(suffix: String) -> void:
	if _shot_path.is_empty() or DisplayServer.get_name() == "headless":
		return
	_boss_skip_frames = 3
	await RenderingServer.frame_post_draw
	if suffix in ["phase1", "phase2"] and boss._flash > 0.0:
		if suffix == "phase1":
			_boss_phase1_shot = false
		else:
			_boss_phase2_shot = false
		return
	var path := _shot_path.get_basename() + "_" + suffix + ".png"
	get_viewport().get_texture().get_image().save_png(path)
	_boss_skip_frames = 3
	print("BOSS screenshot: ", path)


## В --kinds состав не зависит от того, кого первым убило оружие.
func _fill_kinds(initial := false) -> void:
	var alive := [0, 0, 0, 0]
	var elites := 0
	for i in horde.count:
		if horde.elite[i] == 1:
			elites += 1
		else:
			alive[horde.kind[i]] += 1
	for k in Horde.Kind.size():
		for j in maxi(0, KINDS_COUNTS[k] - alive[k]):
			var p := horde.spawn_point(player.global_position)
			if initial:
				p = player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(90.0, 270.0)
			horde.spawn(p, k)
	for j in maxi(0, KINDS_ELITES - elites):
		var p := player.global_position + Vector2.from_angle(TAU * (elites + j) / KINDS_ELITES) * 140.0
		horde.spawn(p, (elites + j) % Horde.Kind.size(), true)
	if initial:
		print("KINDS population=400 mix=220/100/40/40 elites=6 total=%d" % horde.count)


func _bench_step(delta: float) -> void:
	_bench_t += delta
	# перебираем типы смерти, чтобы на скриншоте были все
	if not _gore_stress and not _kinds:
		horde.death_override = int(_bench_t / 1.5) % Gore.Death.size()
	if _bench_t < BENCH_WARMUP:
		return
	_bench_frames += 1
	_bench_frame_ms += delta * 1000.0
	_bench_worst_ms = maxf(_bench_worst_ms, delta * 1000.0)
	_bench_horde_ms += horde.update_ms
	_bench_physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	_bench_enemies += horde.count
	if _bench_t < BENCH_WARMUP + BENCH_DURATION:
		return
	_bench = false
	var n := float(_bench_frames)
	var label := "KINDS" if _kinds else "BENCH"
	print("%s frames=%d avg_fps=%.1f avg_frame_ms=%.2f worst_frame_ms=%.2f horde_ms=%.2f enemies=%.0f kills=%d" % [
		label, _bench_frames, 1000.0 / (_bench_frame_ms / n), _bench_frame_ms / n, _bench_worst_ms,
		_bench_horde_ms / n, _bench_enemies / n, kills])
	print("%s process_ms=%.2f physics_ms=%.2f draw_calls=%d objects=%d gore=%d particles=%d wet=%d" % [
		label, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.OBJECT_COUNT),
		gore.count, effects.particle_count(), floor_decals.pool_count()])
	print("%s physics_avg_ms=%.2f" % [label, _bench_physics_ms / n])
	if _shot_path != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_shot_path)
		print(label, " screenshot: ", _shot_path)
	get_tree().quit()


## Управление задаём кодом по физическим клавишам — работает при любой раскладке.
static func _setup_input() -> void:
	_add_action("move_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_add_action("move_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_add_action("move_up", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_add_action("move_down", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_add_action("dash", [_key(KEY_SPACE), _key(KEY_SHIFT), _button(JOY_BUTTON_A)])
	_add_action("reload", [_key(KEY_R), _button(JOY_BUTTON_X)])
	_add_action("grenade", [_key(KEY_G), _mouse(MOUSE_BUTTON_RIGHT), _button(JOY_BUTTON_RIGHT_SHOULDER)])


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


static func _mouse(button: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
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


## --s3-test: кровавый пол, предметы, граната. Печатает S3TEST, снимки — s3_items/s3_fly/s3_boom.
func _run_s3_test() -> void:
	var dir := _shot_path.get_base_dir() if _shot_path != "" else "."
	var gibs := [0]
	var killed := [0]
	horde.enemy_killed.connect(func(_p, _d, death: int, _f, _v) -> void:
		killed[0] += 1
		if death == Gore.Death.GIBS:
			gibs[0] += 1)
	_full_loadout()
	for sl in weapons.slots:
		sl.cooldown = 1.0e9 # стволы молчат: в счёт попадают только гранаты
	for i in 2:
		weapons.slots[i].modules.clear() # место под модули из контейнера
		weapons.refresh(i)
	player.god_mode = true
	gems.collected.disconnect(progression.add_xp) # без Level Up по дороге: он ставит игру на паузу
	var c := player.global_position
	player.facing = Vector2.DOWN
	player.aim_dir = Vector2.LEFT
	assert(player.grenade_dir() == Vector2.LEFT) # стоим — по стволу
	player._moving = true
	assert(player.grenade_dir() == Vector2.DOWN) # идём — по движению
	player._dash_t = 0.1
	player._dash_dir = Vector2.UP
	assert(player.grenade_dir() == Vector2.UP) # рывок — по фактическому движению
	player._dash_t = 0.0
	player._moving = false
	player.facing = Vector2.RIGHT
	player.aim_dir = Vector2.RIGHT
	print("S3TEST direction standing=true moving=true dashing=true")
	await get_tree().create_timer(0.5).timeout
	# кровавый пол: полсотни зомби вокруг падают разом
	for j in 60:
		horde.spawn(c + Vector2.from_angle(randf() * TAU) * randf_range(20.0, 110.0), Horde.Kind.SHAMBLER)
	await get_tree().create_timer(0.3).timeout
	for j in horde.count:
		horde.damage(j, 9999.0, Vector2.from_angle(randf() * TAU), 0.0)
	await get_tree().create_timer(1.5).timeout
	killed[0] = 0
	gibs[0] = 0
	# предметы на полу
	var kinds := [Pickups.Kind.MEDKIT, Pickups.Kind.CRATE, Pickups.Kind.PART, Pickups.Kind.CONTAINER]
	for k in kinds.size():
		pickups.spawn(c + Vector2(-70.0 + 46.0 * k, -40.0), kinds[k])
	player.hp = 60.0
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("s3_items.png"))
	# толпа за пределами медленно подходит; кидаем гранату по ходу взгляда (вправо)
	var target := c + Vector2.RIGHT * Player.GRENADE_DISTANCE
	var frozen := horde.spawn(target, Horde.Kind.SHAMBLER)
	var frozen_uid := horde.uid[frozen]
	horde.freeze_t[frozen] = 3.0
	for j in 25:
		horde.spawn(target + Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 30.0)), Horde.Kind.SHAMBLER)
	for j in 3:
		horde.spawn(target + Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0)), Horde.Kind.FAT)
	await get_tree().create_timer(0.3).timeout
	var alive_before := horde.count
	print("S3TEST throw ok=%s cd=%.1f target=%s" % [player.throw_grenade(), player.grenade_cd, player.grenade_target()])
	print("S3TEST throw again (должно быть false): %s" % player.throw_grenade())
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("s3_fly.png"))
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("s3_boom.png"))
	await get_tree().create_timer(0.5).timeout
	print("S3TEST grenade alive_before=%d alive_after=%d killed=%d gibs=%d nades=%d" % [alive_before, horde.count, killed[0], gibs[0], nades])
	assert(killed[0] > 0 and killed[0] == gibs[0] and nades == 1)
	assert(not horde.uid.slice(0, horde.count).has(frozen_uid))
	print("S3TEST frozen_grenade_gibs=true")
	# подбор: аптечка (HP 60 → 85), ящик, деталь, контейнер
	player.position = c + Vector2(-70.0, -40.0)
	await get_tree().create_timer(0.3).timeout
	print("S3TEST medkit hp=%.0f items_left=%d" % [player.hp, pickups.count])
	player.position = c + Vector2(-24.0, -40.0)
	await get_tree().create_timer(0.3).timeout
	print("S3TEST crate crates=%d announce=%s items_left=%d" % [crates, announce_text, pickups.count])
	player.position = c + Vector2(22.0, -40.0)
	await get_tree().create_timer(0.3).timeout
	print("S3TEST part loot_open=%s paused=%s cards=%d" % [_loot_open, get_tree().paused, level_up.cards.size()])
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("s3_part.png"))
	level_up._pick(0)
	if not level_up._card.is_empty():
		level_up._pick(_auto_slot(level_up._card))
	await get_tree().create_timer(0.3, true).timeout
	print("S3TEST part chosen paused=%s" % get_tree().paused)
	assert(not get_tree().paused)
	player.position = c + Vector2(68.0, -40.0)
	await get_tree().create_timer(0.3).timeout
	print("S3TEST container crates=%d loot_open=%s cards=%d" % [crates, _loot_open, level_up.cards.size()])
	level_up._pick(0)
	if not level_up._card.is_empty():
		level_up._pick(_auto_slot(level_up._card))
	await get_tree().create_timer(0.3, true).timeout
	print("S3TEST done paused=%s items_left=%d" % [get_tree().paused, pickups.count])
	assert(not get_tree().paused and crates == 2)
	# Время жизни проверяем отдельно от боя: обычные исчезают, контейнер остаётся.
	var expiry := Pickups.new()
	add_child(expiry)
	expiry.process_mode = Node.PROCESS_MODE_DISABLED
	for kind in Pickups.Kind.size():
		expiry.spawn(c, kind)
	expiry._physics_process(0.6)
	expiry._physics_process(40.1)
	assert(expiry.count == 1 and expiry.count_of(Pickups.Kind.CONTAINER) == 1)
	print("S3TEST lifetime ordinary_expired=true container_kept=true")
	expiry.queue_free()
	player.god_mode = false
	player.take_damage(9999.0)
	await get_tree().create_timer(0.2, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join("s3_game_over.png"))
	get_tree().quit()


## Те же уровни/модули, что в старом --loadout, для сравнения нагрузки новых основ.
func _w1_loadout() -> void:
	_full_loadout()
	for i in 4:
		weapons.slots[i].set_model(Meta.model_for(WeaponDefs.Base.PISTOL + i))
		weapons.refresh(i)
		weapons.slots[i].mag = weapons.slots[i].stats["mag"]


## Восемь независимых 10-секундных отрезков. Урон — фактически снятые HP, без overkill.
func _run_weapons_test() -> void:
	spawner.enabled = false
	player.god_mode = true
	gems.collected.disconnect(progression.add_xp)
	weapons.shot_fired.connect(_wtest_on_shot)
	# Направление отдачи и ограничение накопления проверяются независимо от FPS.
	camera.kick(Vector2.RIGHT, 1.0)
	assert(camera._kick.x < 0.0)
	for i in 100:
		camera.kick(Vector2.RIGHT, 1.0)
	assert(camera._kick.length() <= 3.501)
	camera._kick = Vector2.ZERO
	assert(not sfx.has("weapons/missing/shot"))
	sfx.play("weapons/missing/shot")
	# Все новые основы действительно попадают в карты Level Up.
	var offered := PackedByteArray([0, 0, 0, 0, 0, 0, 0, 0])
	for attempt in 400:
		for card: Dictionary in progression.make_cards(0.0):
			if card["type"] == "weapon":
				offered[int(card["id"])] = 1
	for base in range(4, 8):
		assert(offered[base] == 1)
	print("WTEST checks recoil_direction=true recoil_cap=true new_cards=true missing_sfx_silent=true")
	# Проверка хвоста очереди меняет слоты, поэтому идёт после проверки карт Level Up.
	await _wtest_burst_checks()
	for base in WeaponDefs.BASES:
		for level: int in [1, 5]:
			var st := WeaponDefs.base_stats(base, level)
			var cycle: float = float(st["mag"]) / float(st["rate"])
			var crit: float = 1.0 + float(st["crit"]) + 0.15 # базовые 5% + стандарт I 10%
			var dps: float = float(st["damage"]) * int(st["proj"]) * float(st["rate"]) * cycle / (cycle + float(st["reload"])) * crit
			print("WTEST DPS %s L%d damage=%.1f rate=%.2f proj=%d mag=%d reload=%.2f crit=%.2f effective=%.2f" % [Weapons.GUN_IDS[base], level, st["damage"], st["rate"], st["proj"], st["mag"], st["reload"], crit - 1.0, dps])
		weapons.slots.clear()
		weapons.add_weapon(base)
		_wtest_shot = false
		var shots_before := weapons.shots[base]
		var kills_before := kills
		var damage_before := weapons.damage_dealt
		var casings_before := effects.casings_on_floor
		var mags_before := effects.mags_on_floor
		var sounds_before := sfx.played
		var dropped_before := sfx.dropped
		effects.lights_peak = 0
		var started := time
		_wtest_started = time
		weapons.process_mode = Node.PROCESS_MODE_INHERIT
		# Снимок по сигналу после полной сборки вспышки, в том же кадре рендера.
		await get_tree().create_timer(10.0).timeout
		var elapsed := time - started
		# Долетевшие пули/гранаты и последний затвор завершаются на прежнем слоте.
		weapons.slots[0].cooldown = 1.0e9
		await get_tree().create_timer(1.7).timeout # все гильзы и магазины успевают лечь
		print("WTEST %s shots=%d kills=%d dps=%.2f casings_on_floor=%d mags_on_floor=%d sfx_played=%d sfx_dropped=%d lights_peak=%d" % [
			Weapons.GUN_IDS[base], weapons.shots[base] - shots_before, kills - kills_before,
			(weapons.damage_dealt - damage_before) / elapsed, effects.casings_on_floor - casings_before,
			effects.mags_on_floor - mags_before, sfx.played - sounds_before, sfx.dropped - dropped_before, effects.lights_peak])
		assert(weapons.shots[base] > shots_before)
		if base in [WeaponDefs.Base.RIFLE, WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.PISTOL, WeaponDefs.Base.REVOLVER, WeaponDefs.Base.SMG, WeaponDefs.Base.SNIPER]:
			assert(effects.casings_on_floor > casings_before)
		if base in [WeaponDefs.Base.RIFLE, WeaponDefs.Base.PISTOL, WeaponDefs.Base.SMG]:
			assert(effects.mags_on_floor > mags_before)
		weapons.bullet_count = 0
		for e in horde.count:
			horde.dead[e] = 1
		await get_tree().physics_frame
		weapons.process_mode = Node.PROCESS_MODE_INHERIT
	weapons.process_mode = Node.PROCESS_MODE_DISABLED
	if _shot_path != "" and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_floor.png"))
	print("WTEST complete casings=%d mags=%d" % [effects.casings_on_floor, effects.mags_on_floor])
	if _shot_path != "" and DisplayServer.get_name() != "headless":
		await _wtest_spread_palette()
		await _wtest_floor_comparison()
	get_tree().quit()


func _wtest_on_shot(base: int) -> void:
	if _wtest_shot or _shot_path == "" or time - _wtest_started < 2.0:
		return
	_wtest_shot = true
	if DisplayServer.get_name() == "headless":
		return
	get_tree().paused = true
	await RenderingServer.frame_post_draw
	var frame := get_viewport().get_texture().get_image()
	frame.save_png(_shot_path.replace(".png", "_" + Weapons.GUN_IDS[base] + ".png"))
	var center := Vector2i(player.get_global_transform_with_canvas().origin)
	var crop := frame.get_region(Rect2i(center - Vector2i(70, 65), Vector2i(160, 130)))
	crop.resize(crop.get_width() * 3, crop.get_height() * 3, Image.INTERPOLATE_NEAREST)
	crop.save_png(_shot_path.get_base_dir().path_join("w2_flash_" + Weapons.GUN_IDS[base] + ".png"))
	# Контрольный кадр того же состояния мира без источников света.
	for light in effects._lights:
		light.enabled = false
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_" + Weapons.GUN_IDS[base] + "_unlit.png"))
	get_tree().paused = false


## Чистый участок для веера длинной очереди и двух цветов патронов, без груды трупов.
func _wtest_spread_palette() -> void:
	player.position += Vector2(-240, -160)
	camera.global_position = player.global_position
	camera.reset_smoothing()
	for e in horde.count:
		horde.dead[e] = 1
	await get_tree().physics_frame
	weapons.slots.clear()
	weapons.add_weapon(WeaponDefs.Base.SMG)
	var s := weapons.slots[0]
	s.level = 5
	weapons.refresh(0)
	s.mag = s.stats["mag"]
	# Близкую автоматическую толпу заменяем дальней неподвижной мишенью.
	_weapons_test = false
	for k in 24:
		var e := horde.spawn(player.position + Vector2(150.0, (k - 12) * 8.0))
		horde.speed[e] = 0.0
		horde.hp[e] = 10000.0
		horde.max_hp[e] = 10000.0
	weapons.process_mode = Node.PROCESS_MODE_INHERIT
	for ammo: int in [WeaponDefs.Ammo.INCENDIARY, WeaponDefs.Ammo.CRYO]:
		s.ammo = ammo
		await get_tree().create_timer(1.5).timeout
		await weapons.shot_fired
		get_tree().paused = true
		await RenderingServer.frame_post_draw
		var tag := "incendiary" if ammo == WeaponDefs.Ammo.INCENDIARY else "cryo"
		get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_spread_" + tag + ".png"))
		print("WTEST palette=%s heat=%.1f tracers=%d camera_kick=%.2f" % [tag, s.heat, weapons.bullet_count, camera._kick.length()])
		get_tree().paused = false


## Проверяем завершение реальной стрельбы по живучей цели, без случайной орды.
func _wtest_burst_checks() -> void:
	_weapons_test = false
	_wtest_shot = true
	for base: int in [WeaponDefs.Base.RIFLE, WeaponDefs.Base.SMG]:
		weapons.slots.clear()
		weapons.add_weapon(base)
		var s := weapons.slots[0]
		var e := horde.spawn(player.position + Vector2(100, 0))
		horde.speed[e] = 0.0
		horde.hp[e] = 100000.0
		horde.max_hp[e] = 100000.0
		await get_tree().physics_frame
		var before := weapons.tails[base]
		var id: String = "weapons/" + Weapons.GUN_IDS[base] + "/tail"
		assert(sfx.has(id))
		var played := int(sfx.played_by_id.get(id, 0))
		# Два выстрела не дают хвоста, три — дают, повторная пауза молчит.
		for k in 2:
			s.cooldown = 0.0
			weapons._update_slot(0, 1.0 / 60.0)
		s.cooldown = 1000.0
		weapons._update_slot(0, 2.0 / float(s.stats["rate"]))
		assert(weapons.tails[base] == before)
		for k in 3:
			s.cooldown = 0.0
			weapons._update_slot(0, 1.0 / 60.0)
		s.cooldown = 1000.0
		weapons._update_slot(0, 2.0 / float(s.stats["rate"]))
		weapons._update_slot(0, 2.0 / float(s.stats["rate"]))
		assert(weapons.tails[base] == before + 1)
		await _wtest_audio_gap()
		# Тактическая перезарядка завершает очередь сразу.
		for k in 3:
			s.cooldown = 0.0
			weapons._update_slot(0, 1.0 / 60.0)
		weapons.reload_all()
		assert(weapons.tails[base] == before + 2)
		s.reloading = false
		s.mag = s.stats["mag"]
		await _wtest_audio_gap()
		# Новая ближайшая цель: предыдущая очередь получает один хвост.
		for k in 3:
			s.cooldown = 0.0
			weapons._update_slot(0, 1.0 / 60.0)
		var other := horde.spawn(player.position + Vector2(70, 0))
		horde.speed[other] = 0.0
		horde.hp[other] = 100000.0
		await get_tree().physics_frame
		s.cooldown = 0.0
		weapons._update_slot(0, 1.0 / 60.0)
		assert(weapons.tails[base] == before + 3)
		if DisplayServer.get_name() != "headless":
			assert(int(sfx.played_by_id.get(id, 0)) == played + 3)
		print("W2TEST tails %s short=0 pause=1 reload=1 target_change=1 repeated_pause=0 played=%d" % [Weapons.GUN_IDS[base], int(sfx.played_by_id.get(id, 0)) - played])
		weapons.bullet_count = 0
		for j in horde.count:
			horde.dead[j] = 1
		await get_tree().physics_frame
	_weapons_test = true
	_wtest_shot = false


## Ограничитель Sfx использует реальное время, а не delta после долгого GPU-кадра.
func _wtest_audio_gap() -> void:
	var until := Time.get_ticks_msec() + 100
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame


## Рядом лежат все три гильзы, кредиты, опыт и магазины; используются игровые штампы.
func _wtest_floor_comparison() -> void:
	weapons.process_mode = Node.PROCESS_MODE_DISABLED
	player.position += Vector2(-260, -180)
	player.set_physics_process(false)
	player.sprite.texture = player._frames[0]
	player.sprite.modulate = Color.WHITE
	player.sprite.visible = true
	camera.global_position = player.position
	camera.reset_smoothing()
	for j in horde.count:
		horde.dead[j] = 1
	await get_tree().physics_frame
	# Массивы Gems параллельны count: убираем штатным _remove, а не обнулением счётчика.
	while gems.count > 0:
		gems._remove(gems.count - 1)
	while credit_drops.count > 0:
		credit_drops._remove(credit_drops.count - 1)
	gems.player = null
	credit_drops.player = null
	var c := player.position
	for row in 2:
		var y := -34.0 + row * 52.0
		if row == 1:
			for x in range(-52, 89, 23):
				floor_decals.blood(PixelArt.tex("blood_2"), c + Vector2(x, y), 0.0, 1.6, 0.85)
		for kind in 3:
			for j in 6:
				var p := c + Vector2(-49.0 + kind * 21.0 + (j % 3) * 4.0, y - 3.0 + (j / 3) * 6.0)
				effects.casing(p, Vector2.RIGHT, Effects.CASING_IDS[kind])
				var i := effects._cn - 1
				effects._cv[i] = Vector2.ZERO
				effects._cz[i] = 0.0
				effects._czv[i] = 0.0
				effects._cage[i] = 1.5
		credit_drops.spawn(c + Vector2(28, y), 1)
		gems.spawn(c + Vector2(48, y), 1)
		for kind in 3:
			floor_decals.stamp(PixelArt.tex(Effects.CASING_ART[kind + 3]), c + Vector2(68 + kind * 10, y), -0.3, Color.WHITE)
	gems.queue_redraw()
	credit_drops.queue_redraw()
	await get_tree().create_timer(0.2).timeout
	get_tree().paused = true
	await RenderingServer.frame_post_draw
	var frame := get_viewport().get_texture().get_image()
	frame.save_png(_shot_path.get_base_dir().path_join("w2_casings_full.png"))
	var center := Vector2i(player.get_global_transform_with_canvas().origin)
	var crop := frame.get_region(Rect2i(center + Vector2i(-180, -135), Vector2i(480, 270)))
	crop.resize(crop.get_width() * 3, crop.get_height() * 3, Image.INTERPOLATE_NEAREST)
	crop.save_png(_shot_path.get_base_dir().path_join("w2_casings_vs_credits.png"))
	print("W2TEST floor casing_native_px=3,5,4 wet_tint=true magazines_unchanged=true")
	get_tree().paused = false
