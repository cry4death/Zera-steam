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
## HUD: godot --path . -- --hud-test --shot=путь/h1.png (оконный)
## Снимки боя, перезарядки, низкого HP, тревоги, босса, операции кампании, отладки и 720p: h1_*.png.
##
## Тревога: godot --path . -- --alarm [--no-fire] [--shot=путь.png]
## Старт в 6:55, оружие как --loadout, бессмертие; раз в секунду печатает ALARM t=..,
## в конце — худший кадр. С --no-fire зомби не убиваются (пик 500 живых).

## Карты: --fresh-save --map=<id>; --map-test проверяет все планы.
## --fresh-save --loadout --map=<id> --map-shots сохраняет обзор и бой, затем выходит.
## R1: --fresh-save --gore-shots [--map=<id>] --shot=путь.png; --gore-checks проверяет пулы без окна.
## Ульи: --boss --boss-kind=mother|meat_mountain; --boss-test проверяет атаки и фазы.
## Баланс: --headless --fixed-fps 60 --path . -- --boss-sim --boss-loadout=starter|w1|full.
## --boss-shots --fresh-save --shot=префикс сохраняет фазы, смерти и глобус.
var ARENA := Rect2(0, 0, 2560, 1440)
var first_run := false
const BaseScreen := preload("res://scripts/base.gd")
const BENCH_TARGET := 500
var _bench_target := BENCH_TARGET
const BENCH_WARMUP := 3.0
const BENCH_DURATION := 10.0

const COMBO_WINDOW := 6.0 # убийства за последние 6 с, включая паузы тяжёлого оружия
const COMBO_THRESHOLDS := [5, 10, 20, 40, 80]
const COMBO_TITLES := {20: "РЕЗНЯ", 40: "БОЙНЯ", 80: "ЖНЕЦ"}
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

# Реплики не используют боевой RNG и не влияют на сценарий операции.
const DISPATCH := {
	"start": ["Высадка. Работайте.", "Связь есть. Зачищайте."],
	"trader": ["Снабжение выдано.", "Снабжение окончено."],
	"alarm": ["Всплеск биомассы.", "Активность растёт. Огонь."],
	"approach": ["Объект-7 на подходе.", "Объект-7. Приготовиться."],
	"heart_approach": ["Центральный улей впереди.", "Сердце Улья. Группа, приготовиться."],
	"general_approach": ["Генерал. Группа, приготовиться."],
	"boss": ["Объект-7 уничтожен.", "Сигнал Объекта-7 пропал."],
	"general_defeated": ["Генерал уничтожен. Командный пункт зачищен."],
	"evac": ["Единица ранена. Эвакуация.", "Прекратить огонь. Эвакуация."],
	"supply": ["Сброс снабжения.", "Снабжение. Груз на земле."],
}
var _dispatch_counts: Dictionary = {}
var _dispatch_started := false
var _dispatch_alarm_phase := BloodAlarm.Phase.IDLE


var time := 0.0
var kills := 0
var game_over := false
var trader_visit := 0 # следующий визит торговца
var nades := 0 # брошено гранат (для отчёта --sim)
var crates := 0 # оружейные ящики, найденные за забег (открываются на базе, M6)
var military_crates := 0
var elites_killed := 0
var _c6_test := OS.get_cmdline_user_args().has("--c6-test")
var objective: CampaignObjective
var activities: Activities
var boss_phase_flash := 0.0
var _boss_test := false
var _boss_hp := -1.0
var _boss_warned := false
var _boss_spawned := false
var _boss_next_print := 595.0
var _boss_started := 0.0
var _boss_damage_start := 0.0
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
# Радио Диспетчера — отдельная стабильная строка под часами, не крупное объявление.
const RADIO_TIME := 3.2
var radio_text := ""
var radio_t := 0.0
var radio_color := Color(0.75, 0.85, 0.8)
# Мультикилл — небольшая метка у счётчика убийств.
var multikill_text := ""
var multikill_t := 0.0
var _combo_timer := 0.0
var _combo_clock := 0.0
var _combo_times := PackedFloat64Array()
var _combo_awarded := 0
var combo_reward_t := 0.0
var combo_title := ""
var _combo_pending_threshold := 0
var _burst_count := 0
var _burst_t := -1.0
var _loot_open := false # на экране награда (контейнер, деталь), а не Level Up
var _loot_queue: Array[Dictionary] = [] # параметры наград; карты создаём перед показом

# 400 обычных (8:00, BALANCE §7.1) + 6 элиток, пополняются отдельно.
const KINDS_COUNTS := [220, 100, 40, 40, 0, 0, 0]
const KINDS_ELITES := 6
var _kinds := false
var _bench := false
var gun_lab_range := false
var gun_lab_controller: GunLabRange
var _shot_path := ""
var _bench_t := 0.0
var _zoom := 1.0
var _gore_stress := false
var _no_fire := false
var _ui_test := false
var _hud_test := false
var _s3_test := false
var _weapons_test := false
var _meta_test := false
var mission_config: Dictionary = {} # Неизменяемый профиль для C2.
var endless := false
var endless_best_time := 0
var _endless_class := "assault"
var _endless_notice := 0
var _endless_milestone := 0
var _endless_stats: Dictionary = {}
var _sim_report_frames := 0
var _sim_report_started := 0
var mission_banner_t := 0.0
var mission_title := ""
var mission_region := ""
var mission_mod_names := ""
var mission_modifiers: Array = []
var _run_peak := 0
var _wtest_shot := false
var _wtest_started := 0.0
var _sim := false
var _mortal := false # Только отдельная проверка выживаемости с уклонением.
var _mortal_path := PackedVector2Array()
var _mortal_path_goal := Vector2.INF
var _mortal_path_at := 0.0
var _sim_next_report := 60.0
var _sim_until := 600.0
var _sim_peak := 0 # пик живых зомби за минуту (отчёт --sim)
var _sim_drop_rng := RandomNumberGenerator.new()
var _sim_deaths := PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
var _sim_situations: Dictionary = {}
var _sim_damage_seen := 0.0
var _sim_tick := 0
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
var _bench_hud_ms := 0.0
var _bench_enemies := 0
var _audio_test := false
var _aim_test := false
var _aim_failures := 0
var _aim_records: Array[Dictionary] = []
var _audio_lowhp := false
var horde_audio: HordeAudio
var pause_menu: PauseMenu
var obstacles: Obstacles
var _layout_seed := 81073
var _obstacles_test := false
var _map_id := ""
var _map_data: Dictionary = {}
var _map_test := false
var _map_shots := false
var _map_load_ms := 0.0
var _director_warning := -1
var _horde_director := HordeDirector.new()
var _director_pending := false
var _director_cue := 0
var _director_audio_at := 0.0
var _director_log_at := 0.0
var _director_trace: Array[Dictionary] = []
var _director_fight_shot := false

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
@onready var explosions: Explosions = $World/Explosions
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


func _apply_settings() -> void:
	var amount := Meta.gore_multiplier()
	gore.gore_multiplier = amount
	effects.gore_multiplier = amount
	floor_decals.gore_multiplier = amount
	screen_blood.gore_multiplier = amount
	camera.shake_multiplier = float(Meta.settings["shake"])


func _enter_tree() -> void:
	_setup_input()


## E1: прямые вызовы визуальной системы, без подключения боевых взрывов до E1b.
func _run_fx_test() -> void:
	seed(81073)
	spawner.enabled = false
	weapons.firing_enabled = false
	weapons.set_physics_process(false)
	player.god_mode = true
	player.set_physics_process(false)
	gems.collected.disconnect(progression.add_xp)
	$HUD.visible = false
	camera.target = null
	camera.shake_multiplier = 0.0
	camera.position_smoothing_enabled = false
	camera.position = ARENA.get_center()
	camera.zoom = Vector2(2.5, 2.5)
	player.position = ARENA.get_center() + Vector2(-130, 90)
	var dir := "res://design/tasks/reports"
	if not _shot_path.is_empty():
		dir = _shot_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	await get_tree().create_timer(0.6).timeout
	if OS.get_cmdline_user_args().has("--fx-perf-only"):
		await _fx_perf()
		Meta.finish_test()
		return
	await _fx_sequence(dir, "seq", Explosions.Kind.GRENADE, 90.0)
	for j in 45:
		horde.spawn(ARENA.get_center() + Vector2(randf_range(-120, 120), randf_range(-85, 85)))
	await get_tree().physics_frame
	_fx_kill_crowd(ARENA.get_center(), 85.0)
	await _fx_sequence(dir, "crowd", Explosions.Kind.LAUNCHER, 65.0)
	gore.on_enemy_killed(ARENA.get_center(), Vector2.RIGHT, Gore.Death.GIBS, 0.0, 5)
	await _fx_sequence(dir, "fat", Explosions.Kind.FAT, 72.0)
	# Цепь: четыре момента, затем отдельный прогон без чтения GPU для замера.
	explosions.clear()
	var images: Array[Image] = []
	for j in 20:
		var at := ARENA.get_center() + Vector2(float(j % 5) * 62.0 - 124.0, floorf(j / 5.0) * 42.0 - 63.0)
		explosions.spawn(at, 32.0, Explosions.Kind.DETONATOR)
		explosions.set_process(false)
		explosions.advance(0.04)
		explosions.set_process(false)
		await get_tree().create_timer(0.04).timeout
		if j % 5 == 4:
			images.append(await _fx_image())
	_fx_contact(images, dir.path_join("r1d_fx_chain.png" if OS.get_cmdline_user_args().has("--r1d") else "z1_fx_chain.png" if OS.get_cmdline_user_args().has("--z1") else "r1c_fx_chain.png" if OS.get_cmdline_user_args().has("--r1c") else "r1b_fx_chain.png" if OS.get_cmdline_user_args().has("--r1b") else ("r1_fx_chain.png" if OS.get_cmdline_user_args().has("--gore-report") else "e1_chain.png")))
	gore.boss_burst(ARENA.get_center())
	_fx_kill_crowd(ARENA.get_center(), 200.0)
	await _fx_sequence(dir, "boss", Explosions.Kind.BOSS, 180.0)
	await get_tree().create_timer(3.0).timeout
	await _fx_perf()
	# Переполнение, очистка и завершение отложенных ступеней проверяются отдельно.
	explosions.clear()
	for j in 100:
		explosions.spawn(ARENA.get_center(), 60.0, Explosions.Kind.LAUNCHER)
	assert(explosions.active_count() <= Explosions.CAPACITY)
	assert(explosions.layer_count(Explosions.Layer.FIRE) <= 24)
	assert(explosions.layer_count(Explosions.Layer.SMOKE) <= 96)
	explosions.advance(4.0)
	assert(explosions.active_count() == 0)
	explosions.clear()
	print("FXTEST ok=true pool_cap=%d overflow_replaced=%d idle_process=%s" % [Explosions.CAPACITY, explosions.replaced, explosions.is_processing()])
	Meta.finish_test()


## O1: проверка на настоящих packed-строках орды; headless не делает замеров FPS.
func _run_obstacles_test() -> void:
	set_physics_process(false)
	set_process(false)
	horde.set_physics_process(false)
	hazards.set_physics_process(false)
	obstacles.set_physics_process(false)
	player.god_mode = true
	var ok := true
	var layout := ArenaLayout.generate(_layout_seed, ArenaLayout.QUARANTINE)
	ok = _obstacle_check(layout == ArenaLayout.generate(_layout_seed, ArenaLayout.QUARANTINE), "same_seed") and ok
	ok = _obstacle_check(layout != ArenaLayout.generate(_layout_seed + 1, ArenaLayout.QUARANTINE), "different_seed") and ok
	var cars := 0
	var barrels := 0
	for row in layout:
		var k := int(row["kind"])
		if k <= Obstacles.Kind.TRUCK:
			cars += 1
		if k == Obstacles.Kind.RED or k == Obstacles.Kind.ACID:
			barrels += 1
		if k < Obstacles.Kind.TIRES:
			ok = _obstacle_check(Vector2(row["pos"]).distance_to(ARENA.get_center()) > 200.0, "start_clear") and ok
	ok = _obstacle_check(cars >= 25 and cars <= 40 and barrels == 20, "density") and ok
	ok = _obstacle_check(obstacles.connected(), "connected_quarantine") and ok
	for i in obstacles.count:
		if obstacles.kind[i] >= Obstacles.Kind.TIRES:
			continue
		ok = _obstacle_check(not obstacles.contains(obstacles.free_point(obstacles.pos[i], 12.0), 11.99), "free_spawn_drop") and ok
	print("OBSTEST layout cars=%d barrels=%d objects=%d seed=%d" % [cars, barrels, obstacles.count, _layout_seed])
	# Разные профили/сиды проверяются отдельно от активного поля боя.
	for test_seed in 8:
		obstacles.setup(ARENA, ArenaLayout.generate(test_seed, ArenaLayout.QUARANTINE))
		ok = _obstacle_check(obstacles.connected(), "connected_seed_%d" % test_seed) and ok
	var wall: Array[Dictionary] = []
	for j in 9:
		wall.append({"kind": Obstacles.Kind.JERSEY, "pos": Vector2(1088 + j * 44, 720), "angle": 0.0})
	obstacles.setup(ARENA, wall)
	player.position = Vector2(1280, 890)
	horde.count = 0
	horde.far_distance = 5000.0
	for i in 500:
		var at := Vector2(1035 + (i % 50) * 10, 450 + (i / 50) * 10)
		var e := horde.spawn(at, Horde.Kind.SHAMBLER, i % 17 == 0)
		horde.hp[e] = 100000.0
		horde.max_hp[e] = 100000.0
	var penetrations := 0
	for frame in 3600:
		obstacles.navigation_step(1.0 / 60.0, player.position)
		horde._physics_process(1.0 / 60.0)
		if frame % 4 == 0:
			for i in horde.count:
				if obstacles.contains(horde.pos[i], horde.radius[i] - 0.04):
					penetrations += 1
		if frame % 600 == 599:
			print("OBSTEST simulation seconds=%d alive=%d penetrations=%d" % [(frame + 1) / 60, horde.count, penetrations])
			await get_tree().process_frame
	var arrived := 0
	for i in horde.count:
		# Центр за дальней гранью стены (y 725): обошёл. С очередью ZAI4 толпа у игрока — плотный диск радиусом
		# ~150 px; он упирается в стену, и внешний слой ждёт в очереди прямо под ней (раньше считали y > 750).
		if horde.pos[i].y > 725.0:
			arrived += 1
		else:
			print("OBSTEST stuck i=%d pos=%s elite=%d steer=%s queued=%d d=%.0f" % [i, horde.pos[i], horde.elite[i], horde.steer[i], horde.queued[i], horde.pos[i].distance_to(player.position)])
	ok = _obstacle_check(penetrations == 0, "500_no_penetrations_60s") and ok
	ok = _obstacle_check(arrived == 500, "500_long_wall_arrived") and ok
	print("OBSTEST wall arrived=%d/500 nav_worst_us=%d" % [arrived, obstacles.nav_worst_usec])
	# Игрок и быстрый рывок: тонкий забор не туннелируется.
	var from := Vector2(1280, 675)
	var to := obstacles.move_actor(from, Vector2(1280, 760), Player.RADIUS)
	if to.y >= 720 or obstacles.contains(to, Player.RADIUS - 0.01):
		print("OBSTEST dash from=%s to=%s radius=%.2f" % [from, to, Player.RADIUS])
	ok = _obstacle_check(to.y < 720 and not obstacles.contains(to, Player.RADIUS - 0.01), "dash_stopped") and ok
	var demo: Array[Dictionary] = [
		{"kind": Obstacles.Kind.SEDAN, "pos": Vector2(1280, 720)},
		{"kind": Obstacles.Kind.RED, "pos": Vector2(1280, 770)},
		{"kind": Obstacles.Kind.ACID, "pos": Vector2(1400, 770)},
		{"kind": Obstacles.Kind.BAGS, "pos": Vector2(1500, 720)},
		{"kind": Obstacles.Kind.WOOD, "pos": Vector2(1560, 720)},
		{"kind": Obstacles.Kind.JERSEY, "pos": Vector2(1650, 720)}]
	horde.count = 0
	obstacles.setup(ARENA, demo)
	ok = _obstacle_check(obstacles.ray_hit(Vector2(1200, 720), Vector2(1350, 720)) == 0, "high_stops_bullet") and ok
	ok = _obstacle_check(obstacles.line_clear(Vector2(1450, 720), Vector2(1590, 720)), "low_passes_bullet") and ok
	ok = _obstacle_check(not obstacles.line_clear(Vector2(1200, 720), Vector2(1350, 720)), "spit_blocked") and ok
	obstacles.damage(1, 100.0)
	obstacles._physics_process(1.0 / 60.0)
	ok = _obstacle_check(obstacles.state[1] == Obstacles.State.GONE and obstacles.state[0] == Obstacles.State.BURNING, "barrel_car_chain_burning") and ok
	for frame in 420:
		obstacles._physics_process(1.0 / 60.0)
	ok = _obstacle_check(obstacles.state[0] == Obstacles.State.WRECK and obstacles.contains(Vector2(1280, 720)), "car_wreck_collision") and ok
	obstacles.damage(2, 100.0)
	obstacles._physics_process(1.0 / 60.0)
	ok = _obstacle_check(hazards.pool_count() > 0 and obstacles.state[2] == Obstacles.State.GONE, "acid_barrel_pool") and ok
	ok = _obstacle_check(not obstacles.charge(Vector2(1500, 720), Boss.RADIUS) and obstacles.state[3] == Obstacles.State.GONE, "charge_crush_bags") and ok
	ok = _obstacle_check(not obstacles.charge(Vector2(1560, 720), Boss.RADIUS) and obstacles.state[4] == Obstacles.State.GONE, "charge_crush_wood") and ok
	ok = _obstacle_check(obstacles.charge(Vector2(1650, 720), Boss.RADIUS), "charge_stops_jersey") and ok
	obstacles.splatter(Vector2(1280, 740))
	ok = _obstacle_check(obstacles.blood[0] > 0, "blood_on_object") and ok
	print("OBSTEST ok=%s penetrations=%d arrived=%d detonations=%d blood_events=%d" % [ok, penetrations, arrived, obstacles.detonations, obstacles.blood_events])
	if OS.get_cmdline_user_args().has("--obstacles-shots") and DisplayServer.get_name() != "headless":
		await _obstacle_shots()
	Meta.finish_test(0 if ok else 1)


## O2: проверяем авторские планы, не исправляя их случайным переносом объектов.
func _run_map_test() -> void:
	set_physics_process(false)
	set_process(false)
	horde.set_physics_process(false)
	hazards.set_physics_process(false)
	obstacles.set_physics_process(false)
	var ok := true
	var test_maps: Array = [_map_id] if Array(OS.get_cmdline_user_args()).any(func(arg: String) -> bool: return arg.begins_with("--map=")) else MapLoader.IDS
	for id: String in test_maps:
		var data := MapLoader.load_map(id)
		ok = _obstacle_check(not data.is_empty(), "map_load_" + id) and ok
		if data.is_empty():
			continue
		var layout := MapLoader.layout(data, 81073)
		ok = _obstacle_check(layout == MapLoader.layout(data, 81073), "map_same_seed_" + id) and ok
		var other := MapLoader.layout(data, 81074)
		ok = _obstacle_check(layout != other, "map_different_details_" + id) and ok
		ok = _obstacle_check(_map_geometry(layout) == _map_geometry(other), "map_fixed_plan_" + id) and ok
		var rect := Rect2(Vector2.ZERO, data["size"])
		obstacles.setup(rect, layout)
		if not obstacles.connected():
			print("MAPTEST unreachable id=%s at=%s" % [id, obstacles.cell_center(obstacles.unreachable_cell())])
		ok = _obstacle_check(obstacles.connected(), "map_connected_" + id) and ok
		ok = _obstacle_check(not obstacles.contains(data["start"], Player.RADIUS), "map_start_" + id) and ok
		var entries: PackedVector2Array = data["spawn_points"]
		for entry in entries:
			ok = _obstacle_check(not obstacles.contains(entry, 19.0), "map_entry_" + id) and ok
		for type: String in data.get("objective_sockets", {}):
			for socket: Array in data["objective_sockets"][type]:
				var at := MapLoader.point(socket)
				var radius := 60.0 if type == "evac" else 36.0
				if not data.has("ground_art"):
					at = obstacles.free_point(at, radius)
				ok = _obstacle_check(not obstacles.contains(at, radius) and not obstacles.body_path(data["start"], at, 7.95).is_empty(), "map_socket_%s_%s" % [id, type]) and ok
		for socket: Array in data.get("activity_sockets", []):
			var at := MapLoader.point(socket)
			ok = _obstacle_check(not obstacles.contains(at, 54.0) and not obstacles.body_path(data["start"], at, 7.95).is_empty(), "map_activity_socket_" + id) and ok
		if data.has("activity_sockets"):
			_map_data = data
			player.position = data["start"]
			for activity_kind in Activities.Kind.size():
				activities.kind = activity_kind as Activities.Kind
				activities._rng.seed = 81073
				var at := activities.find_site()
				var authored := false
				for socket: Array in data["activity_sockets"]:
					authored = authored or at.is_equal_approx(MapLoader.point(socket))
				ok = _obstacle_check(authored and activities.valid_site(at), "map_activity_authored_%s_%d" % [id, activity_kind]) and ok
		if data.has("boss_arena"):
			var at := MapLoader.point(data["boss_arena"]["at"])
			ok = _obstacle_check(not obstacles.contains(at, float(data["boss_arena"]["radius"])), "map_boss_arena_" + id) and ok
		for loop: Array in data["loops"]:
			for j in loop.size():
				var from := MapLoader.point(loop[j])
				var to := MapLoader.point(loop[(j + 1) % loop.size()])
				ok = _obstacle_check(obstacles.move_actor(from, to, 8.0).distance_to(to) < 0.1, "map_loop_" + id) and ok
		for i in obstacles.count:
			if obstacles.kind[i] == Obstacles.Kind.STRUCTURE:
				var from := obstacles.pos[i] - obstacles.axis[i] * (obstacles.half[i].x + 20)
				ok = _obstacle_check(not obstacles.line_clear(from, obstacles.pos[i]), "map_high_structure_" + id) and ok
		for row in layout:
			var at: Vector2 = row["pos"]
			ok = _obstacle_check(not obstacles.contains(obstacles.free_point(at, 12.0), 11.95), "map_drop_" + id) and ok
		player.position = data["start"]
		horde.arena = rect
		horde.map_entries = entries
		horde.count = 0
		spawner.profile = {"directional": 1.0}
		for group in 20:
			spawner._spawn_group(5, [100, 0, 0, 0])
		for i in horde.count:
			var nearest := INF
			for entry in entries:
				nearest = minf(nearest, horde.pos[i].distance_to(entry))
			ok = _obstacle_check(nearest < 90.0, "map_directional_entry_" + id) and ok
		if OS.get_cmdline_user_args().has("--map-validate-only"):
			continue
		horde.count = 0
		horde.arena = rect
		horde.map_entries = entries
		horde.far_distance = 5000.0
		for i in 500:
			var at := entries[i % entries.size()] + Vector2(float(i % 9) * 4, float(i % 7) * 4)
			var e := horde.spawn(at, Horde.Kind.SHAMBLER, i % 17 == 0)
			horde.hp[e] = 100000.0
			horde.max_hp[e] = 100000.0
		var penetrations := 0
		for frame in 3600:
			obstacles.navigation_step(1.0 / 60.0, player.position)
			horde._physics_process(1.0 / 60.0)
			if frame % 4 == 0:
				for i in horde.count:
					if obstacles.contains(horde.pos[i], horde.radius[i] - 0.04):
						if penetrations < 3:
							print("MAPTEST penetration map=%s frame=%d at=%s radius=%.3f" % [id, frame, horde.pos[i], horde.radius[i]])
						penetrations += 1
			if frame % 600 == 599:
				await get_tree().process_frame
		ok = _obstacle_check(penetrations == 0, "map_500_no_penetrations_" + id) and ok
		print("MAPTEST id=%s connected=%s fixed_plan=%s seconds=60 alive=%d penetrations=%d objects=%d" % [id, obstacles.connected(), _map_geometry(layout) == _map_geometry(other), horde.count, penetrations, layout.size()])
	var wall: Array[Dictionary] = []
	for j in 9:
		wall.append({"kind": Obstacles.Kind.JERSEY, "pos": Vector2(1088 + j * 44, 720)})
	obstacles.setup(ARENA, wall)
	var dash := obstacles.move_actor(Vector2(1280, 675), Vector2(1280, 760), Player.RADIUS)
	ok = _obstacle_check(dash.y < 720 and not obstacles.contains(dash, Player.RADIUS - 0.01), "map_swept_wall") and ok
	if dash.y >= 720:
		print("MAPTEST dash=%s extent=%s pos=%s half=%s" % [dash, obstacles._extent[4], obstacles.pos[4], obstacles.half[4]])
	print("MAPTEST ok=%s maps=%d" % [ok, test_maps.size()])
	Meta.finish_test(0 if ok else 1)


func _map_geometry(layout: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in layout:
		var k := int(row["kind"])
		if k >= Obstacles.Kind.TIRES and k != Obstacles.Kind.STRUCTURE:
			continue
		result.append({"pos": row["pos"], "angle": row.get("angle", 0.0), "half": row.get("half", Vector2.ZERO)})
	return result


func _run_map_shots() -> void:
	set_physics_process(false)
	$HUD.visible = false
	camera.target = null
	camera.shake_multiplier = 0.0
	camera.position_smoothing_enabled = false
	camera.position = ARENA.get_center()
	camera.zoom = Vector2.ONE * minf(1920.0 / ARENA.size.x, 1080.0 / ARENA.size.y)
	var dir := "res://design/tasks/reports"
	var prefix := _shot_path.get_basename() if not _shot_path.is_empty() else dir.path_join("o2_%s" % _map_id)
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(prefix + "_overview.png")
	if OS.get_cmdline_user_args().has("--map-overview-only"):
		print("MAPSHOTS id=%s overview=true staged=false" % _map_id)
		Meta.finish_test()
		return
	player.position = Vector2(1840, 790) if _map_id == "quarantine_checkpoint" else Vector2(1408, 800)
	player.position = obstacles.free_point(player.position, Player.RADIUS)
	camera.position = player.position
	camera.zoom = Vector2.ONE * 2.1
	player.force_auto_aim = true
	for i in 140:
		var at := player.position + Vector2.from_angle(float(i) * 2.4) * (150.0 + float(i % 10) * 13.0)
		horde.spawn(at, i % 4)
	weapons.firing_enabled = true
	weapons.set_physics_process(true)
	await get_tree().create_timer(1.15).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(prefix + "_fight.png")
	print("MAPSHOTS id=%s overview=true fight=true" % _map_id)
	Meta.finish_test()


func _obstacle_check(ok: bool, label: String) -> bool:
	if not ok:
		push_error("OBSTEST FAILED " + label)
	return ok


func _obstacle_shots() -> void:
	$HUD.visible = false
	camera.target = null
	camera.shake_multiplier = 0.0
	camera.position_smoothing_enabled = false
	player.position = ARENA.get_center()
	camera.position = player.position
	camera.zoom = Vector2.ONE
	obstacles.setup(ARENA, ArenaLayout.generate(_layout_seed, ArenaLayout.QUARANTINE))
	horde.count = 0
	for i in 500:
		horde.spawn(Vector2(740 + i % 40 * 25, 360 + i / 40 * 34), i % 4)
	horde._rebuild_grid()
	horde._render()
	await get_tree().create_timer(0.4).timeout
	await _obstacle_shot("arena")
	var demo: Array[Dictionary] = [
		{"kind": Obstacles.Kind.POLICE, "pos": Vector2(1240, 690), "angle": 0.15},
		{"kind": Obstacles.Kind.JEEP, "pos": Vector2(1360, 750), "angle": -0.12},
		{"kind": Obstacles.Kind.JERSEY, "pos": Vector2(1260, 790)},
		{"kind": Obstacles.Kind.JERSEY, "pos": Vector2(1310, 790)},
		{"kind": Obstacles.Kind.RED, "pos": Vector2(1320, 650)},
		{"kind": Obstacles.Kind.ACID, "pos": Vector2(1340, 650)}]
	obstacles.setup(ARENA, demo)
	camera.zoom = Vector2(3, 3)
	horde.count = 0
	for i in 90:
		var e := horde.spawn(Vector2(1140 + i % 15 * 18, 630 + i / 15 * 29), i % 4)
		horde.angle[e] = float(i) * 0.7
	horde._rebuild_grid()
	horde._render()
	player.position = Vector2(1170, 820)
	for i in 26:
		floor_decals.blood(PixelArt.tex("blood_%d" % (i % 8)), Vector2(1190 + i % 7 * 28, 650 + i / 7 * 35), float(i), 1.5, 0.7)
	for i in 3:
		obstacles.splatter(Vector2(1250, 735))
	await get_tree().create_timer(0.3).timeout
	await _obstacle_shot("blood")
	obstacles.damage(0, 200.0)
	await get_tree().create_timer(0.3).timeout
	await _obstacle_shot("burning")
	obstacles._detonate(0)
	obstacles._burning.clear()
	explosions.set_process(false)
	explosions.advance(0.12)
	explosions.set_process(false)
	await _obstacle_shot("blast")


func _obstacle_shot(suffix: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://design/tasks/reports/o1_%s.png" % suffix
	var err := get_viewport().get_texture().get_image().save_png(path)
	print("OBSTEST screenshot=%s error=%d" % [path, err])


func _fx_perf() -> void:
	# Орда 500: те же визуальные вызовы, без урона/старых кругов и без снимков.
	seed(81073)
	for j in 500 - horde.count:
		horde.spawn(ARENA.get_center() + Vector2.from_angle(float(j) * 2.4) * randf_range(170.0, 360.0))
	await get_tree().create_timer(0.5).timeout
	# Холодные пики сохраняем в логе отдельно; контроль получает такой же прогрев.
	await _fx_measure("warm_chain20", false, false)
	await get_tree().create_timer(3.0).timeout
	await _fx_measure("warm_boss", false, true)
	await get_tree().create_timer(3.0).timeout
	var baseline := OS.get_cmdline_user_args().has("--fx-baseline")
	await _fx_measure("chain20", baseline, false)
	await get_tree().create_timer(3.0).timeout
	await _fx_measure("boss", baseline, true)


func _fx_kill_crowd(at: Vector2, radius: float) -> void:
	var previous := horde.death_override
	horde.death_override = Gore.Death.GIBS
	for i in horde.count:
		if horde.dead[i] == 0 and horde.pos[i].distance_squared_to(at) <= radius * radius:
			horde.damage(i, 99999.0, (horde.pos[i] - at).normalized(), 230.0, WeaponDefs.Ammo.STANDARD, false, horde.pos[i], true)
	horde.death_override = previous


func _fx_sequence(dir: String, suffix: String, kind: int, radius: float) -> void:
	explosions.clear()
	explosions.spawn(ARENA.get_center(), radius, kind)
	explosions.set_process(false)
	sfx.play("explosions/grenade", ARENA.get_center())
	var images: Array[Image] = []
	var previous := 0.0
	for age: float in [0.05, 0.15, 0.4, 1.5]:
		await get_tree().create_timer(age - previous).timeout
		explosions.advance(age - previous)
		explosions.set_process(false)
		images.append(await _fx_image())
		previous = age
	_fx_contact(images, dir.path_join(("r1d_fx_%s.png" if OS.get_cmdline_user_args().has("--r1d") else "z1_fx_%s.png" if OS.get_cmdline_user_args().has("--z1") else "r1c_fx_%s.png" if OS.get_cmdline_user_args().has("--r1c") else "r1b_fx_%s.png" if OS.get_cmdline_user_args().has("--r1b") else ("r1_fx_%s.png" if OS.get_cmdline_user_args().has("--gore-report") else "e1_%s.png")) % suffix))
	print("FXTEST sheet=%s ages=0.05,0.15,0.4,1.5" % suffix)


func _fx_image() -> Image:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var crop_size := Vector2i(mini(960, img.get_width()), mini(800, img.get_height()))
	return img.get_region(Rect2i((img.get_size() - crop_size) / 2, crop_size))


func _fx_contact(images: Array[Image], path: String) -> void:
	var sheet := Image.create(1920, 420, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.07, 0.075, 0.08))
	for j in images.size():
		images[j].resize(480, 400, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(images[j], Rect2i(0, 0, 480, 400), Vector2i(j * 480, 20))
	assert(sheet.save_png(path) == OK)


func _fx_measure(label: String, baseline: bool, boss_burst: bool) -> void:
	explosions.clear()
	explosions.update_worst_usec = 0
	explosions.draw_worst_usec = 0
	explosions.peak = 0
	var clock_state := [Time.get_ticks_usec(), 0.0, 0.0, 0.0, 0.0, 0.0]
	var tick := func() -> void:
		var now := Time.get_ticks_usec()
		var ms := float(now - int(clock_state[0])) / 1000.0
		clock_state[0] = now
		clock_state[1] = maxf(float(clock_state[1]), ms)
		clock_state[2] += ms
		clock_state[3] += 1.0
		clock_state[4] = maxf(float(clock_state[4]), Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		clock_state[5] = maxf(float(clock_state[5]), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	RenderingServer.frame_post_draw.connect(tick)
	var spawn_worst := 0
	for j in (1 if boss_burst else 20):
		var start := Time.get_ticks_usec()
		if boss_burst:
			gore.boss_burst(ARENA.get_center())
		if not baseline:
			explosions.spawn(ARENA.get_center() + Vector2(float(j % 5) * 45.0 - 90.0, floorf(j / 5.0) * 36.0 - 54.0), 180.0 if boss_burst else 32.0, Explosions.Kind.BOSS if boss_burst else Explosions.Kind.DETONATOR)
		spawn_worst = maxi(spawn_worst, Time.get_ticks_usec() - start)
		await get_tree().create_timer(0.04).timeout
	await get_tree().create_timer(3.0).timeout
	RenderingServer.frame_post_draw.disconnect(tick)
	print("FXBENCH %s baseline=%s enemies=%d frames=%d avg_ms=%.3f worst_ms=%.3f physics_worst_ms=%.3f draw_calls_peak=%d spawn_worst_ms=%.3f update_worst_ms=%.3f draw_submit_worst_ms=%.3f peak=%d" % [label, baseline, horde.count, clock_state[3], float(clock_state[2]) / maxf(1.0, float(clock_state[3])), clock_state[1], clock_state[4], clock_state[5], spawn_worst / 1000.0, explosions.update_worst_usec / 1000.0, explosions.draw_worst_usec / 1000.0, explosions.peak])


func _ready() -> void:
	first_run = get_tree().has_meta("first_run_active") and Meta.needs_first_run()
	get_tree().remove_meta("first_run_active")
	gun_lab_range = bool(get_tree().get_meta("gun_lab_range",false)) or OS.get_cmdline_user_args().has("--gun-range")
	get_tree().remove_meta("gun_lab_range")
	if OS.get_cmdline_user_args().has("--cp1-paths"):
		# Пути фикстур в памяти; условия штатных тестов не меняются.
		DirAccess.make_dir_recursive_absolute("res://design/tasks/reports/cp1_userdata/fixtures")
		if OS.get_cmdline_user_args().has("--meta-test") or OS.get_cmdline_user_args().has("--q1-test"):
			var script := load("res://scripts/meta_test.gd") as GDScript
			script.source_code = script.source_code.replace("res://tmp", "res://design/tasks/reports/cp1_userdata/fixtures")
			assert(script.reload() == OK)
	if OS.get_cmdline_user_args().has("--r1d"):
		_r1d_test_paths()
	if OS.get_cmdline_user_args().has("--z1"):
		_z1_test_paths()
	if OS.get_cmdline_user_args().has("--r1c"):
		_r1c_test_paths()
	if OS.get_cmdline_user_args().has("--r1b"):
		_r1b_test_paths()
	if Meta.test_errors > 0:
		Meta.finish_test(1)
		return
	if OS.get_cmdline_user_args().has("--campaign-test"):
		var ok: bool = await CampaignTest.run(self)
		Meta.finish_test(0 if ok else 1)
		return
	endless = get_tree().has_meta("endless_config") or OS.get_cmdline_user_args().has("--endless") or OS.get_cmdline_user_args().has("--endless-test") or OS.get_cmdline_user_args().has("--endless-shots")
	if endless:
		var config: Dictionary = get_tree().get_meta("endless_config", {})
		_map_id = str(config.get("map_id", ""))
		_endless_class = Meta.class_id
		if not Meta.is_test_run():
			_layout_seed = (int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec()) & 0x7fffffff
		seed(_layout_seed)
	if not _read_mission():
		Meta.finish_test(1)
		return
	if not mission_config.is_empty() and mission_config["type"] in ["clearance", "reclaim"]:
		var old_boss := boss
		boss = CampaignNode.new()
		$World.add_child(boss)
		old_boss.queue_free()
	var hive_id := str(mission_config.get("boss", "object_7"))
	if hive_id.is_empty():
		hive_id = "object_7"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--boss-kind="):
			hive_id = arg.trim_prefix("--boss-kind=")
	if hive_id in ["mother", "meat_mountain"]:
		var old_boss := boss
		var hive_boss := BossHive.new()
		hive_boss.hive = BossHive.Hive.MOTHER if hive_id == "mother" else BossHive.Hive.MEAT
		boss = hive_boss
		$World.add_child(boss)
		old_boss.queue_free()
	elif hive_id == "hive_heart":
		var old_boss := boss
		boss = BossHeart.new()
		$World.add_child(boss)
		old_boss.queue_free()
	elif hive_id == "general":
		var old_boss := boss
		boss = BossGeneral.new()
		$World.add_child(boss)
		old_boss.queue_free()
	elif hive_id != "object_7":
		push_error("Unknown boss: " + hive_id)
		Meta.finish_test(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg == "--map-test":
			_map_test = true
		elif arg == "--map-shots":
			_map_shots = true
		elif arg.begins_with("--map="):
			_map_id = arg.trim_prefix("--map=")
		elif arg == "--obstacles-test":
			_obstacles_test = true
		elif arg.begins_with("--layout-seed="):
			_layout_seed = arg.trim_prefix("--layout-seed=").to_int()
		elif arg == "--aim-test":
			_aim_test = true
		elif arg == "--audio-test":
			_audio_test = true
		elif arg == "--bench":
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
		elif arg == "--meta-test" or arg == "--class-tree-test":
			_meta_test = true
		elif arg == "--loadout-w1":
			_w1_loadout.call_deferred()
		elif arg == "--loadout":
			_full_loadout.call_deferred() # бенчмарк с полным арсеналом
		elif arg == "--alarm":
			_alarm = true # тревога: старт в 6:55, оружие как --loadout
			_full_loadout.call_deferred()
		elif arg == "--boss" or arg == "--boss-sim":
			_boss_test = true
			if not Array(OS.get_cmdline_user_args()).any(func(a: String) -> bool: return a.begins_with("--boss-loadout=")):
				_full_loadout.call_deferred()
		elif arg.begins_with("--boss-loadout="):
			if arg.ends_with("=starter"):
				_boss_starter_loadout.call_deferred()
			elif arg.ends_with("=w1"):
				_w1_loadout.call_deferred()
			elif arg.ends_with("=full"):
				_full_loadout.call_deferred()
		elif arg.begins_with("--boss-hp="):
			_boss_hp = arg.trim_prefix("--boss-hp=").to_float() # стартовое HP босса (быстрый тест смерти)
		elif arg == "--s3-test":
			_s3_test = true # предметы на кровавом полу и бросок гранаты
		elif arg == "--ui-test":
			_ui_test = true # снимки экрана Level Up и выбора ствола
		elif arg == "--hud-test":
			_hud_test = true # снимки боевого HUD (H1)
		elif arg == "--sim" or arg.begins_with("--sim="):
			_sim = true # прогон забега на ускорении с отчётом раз в минуту
			_sim_until = arg.trim_prefix("--sim=").to_float() if arg.begins_with("--sim=") else 600.0
		elif arg == "--gore-stress":
			_gore_stress = true # 120 убийств/с со случайным типом смерти
		elif arg.begins_with("--zoom="):
			_zoom = arg.trim_prefix("--zoom=").to_float()
	# Случайность боя не зависит от локального RNG генератора карты.
	if first_run or _bench or _boss_test or _sim or _obstacles_test or Array(OS.get_cmdline_user_args()).any(func(a: String) -> bool: return a.begins_with("--layout-seed=")):
		seed(_layout_seed)

	var map_started := Time.get_ticks_usec()
	if not mission_config.is_empty() and not Array(OS.get_cmdline_user_args()).any(func(a: String) -> bool: return a.begins_with("--layout-seed=")):
		_layout_seed = int(mission_config["seed"])
	if _map_id.is_empty():
		if first_run:
			_map_id = "quarantine_checkpoint"
	if _map_id.is_empty():
		_map_id = MapLoader.for_region(str(mission_config.get("region_id", "east_europe")))
		if hive_id == "general":
			_map_id = "military_airfield" # Генерал — на военной базе (O3)
	_map_data = MapLoader.load_map(_map_id)
	if _map_data.is_empty():
		Meta.finish_test(1)
		return
	ARENA = Rect2(Vector2.ZERO, _map_data["size"])
	ground.setup(ARENA, _map_data)
	_map_load_ms = (Time.get_ticks_usec() - map_started) / 1000.0
	floor_decals.setup(ARENA)
	if boss is BossHeart:
		$World/Ground.z_index = -2
		floor_decals.infect_hive(ARENA)
	effects.floor_decals = floor_decals
	explosions.floor_decals = floor_decals
	explosions.effects = effects
	explosions.camera = camera
	explosions.player = player
	weapons.explosions = explosions
	hazards.explosions = explosions
	effects.sfx = sfx
	player.sfx = sfx
	weapons.sfx = sfx
	gore.setup(floor_decals, effects, ARENA, player)
	player.arena = ARENA
	player.position = _map_data["start"]
	player.effects = effects
	horde.setup(ARENA, player, floor_decals)
	horde.map_entries = _map_data["spawn_points"]
	horde.benchmark_spawn = _bench
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
	var collision_started := Time.get_ticks_usec()
	if not OS.get_cmdline_user_args().has("--no-obstacles"):
		obstacles = Obstacles.new()
		obstacles.name = "Obstacles"
		$World.add_child(obstacles)
		$World.move_child(obstacles, $World/Horde.get_index())
		obstacles.player = player
		obstacles.horde = horde
		obstacles.hazards = hazards
		obstacles.explosions = explosions
		obstacles.sfx = sfx
		if not mission_config.is_empty() and not Array(OS.get_cmdline_user_args()).any(func(a: String) -> bool: return a.begins_with("--layout-seed=")):
			_layout_seed = int(mission_config["seed"])
		obstacles.setup(ARENA, ArenaLayout.generate(_layout_seed, ArenaLayout.QUARANTINE) if _obstacles_test else MapLoader.layout(_map_data, _layout_seed))
		if boss is BossHeart:
			obstacles.hive_skin = PixelArt.tex("hive_wall")
			obstacles.queue_redraw()
		player.obstacles = obstacles
		horde.obstacles = obstacles
		weapons.obstacles = obstacles
		hazards.obstacles = obstacles
		pickups.obstacles = obstacles
		boss.obstacles = obstacles
		horde.enemy_killed.connect(obstacles.splatter)
		obstacles.threaded_nav = _live_play()
		while obstacles.nav_completed == 0:
			obstacles.navigation_step(0.0, player.position)
	_map_load_ms += (Time.get_ticks_usec() - collision_started) / 1000.0
	print("MAP loaded id=%s size=%s load_ms=%.2f seed=%d" % [_map_id, ARENA.size, _map_load_ms, _layout_seed])
	boss.horde = horde
	boss.player = player
	boss.effects = effects
	boss.floor_decals = floor_decals
	boss.camera = camera
	boss.arena = ARENA
	if boss is BossHive or boss is BossHeart or boss is BossGeneral:
		boss.sfx = sfx
	if boss is BossGeneral:
		boss.explosions = explosions
	boss.roar.connect(_on_boss_roar)
	boss.crushed.connect(_on_boss_crushed)
	boss.armor_plate.connect(_on_boss_plate)
	boss.phase_changed.connect(_on_boss_phase)
	boss.charge_telegraph.connect(func(_from: Vector2, _to: Vector2, _duration: float) -> void: camera.shake(1.8))
	boss.slam_started.connect(func(at: Vector2) -> void:
		camera.shake(6.0)
		sfx.play("explosions/grenade", at, 1.0, 0.02))
	if boss is CampaignNode:
		boss.died.connect(func(_at: Vector2) -> void: _objective_victory())
	else:
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
	_apply_mission()
	spawner.endless = endless
	_horde_director.endless = endless
	if endless:
		mission_title = "БЕСКОНЕЧНАЯ БОЙНЯ"
		mission_region = Meta.ENDLESS_MAP_NAMES[Meta.ENDLESS_MAPS.find(_map_id)]
		endless_best_time = int(Meta.endless_best(_map_id, _endless_class)["time"])
		# Штормы заменяют одиночную тревогу свободной вылазки, без наложения пиков.
		blood_alarm.phase = BloodAlarm.Phase.DONE
		blood_alarm.set_physics_process(false)
	if not mission_config.is_empty() and mission_config["type"] != "nest":
		objective = CampaignObjective.new()
		$World.add_child(objective)
		objective.setup(self, _map_data)
	activities = Activities.new()
	$World.add_child(activities)
	var activity_seed := int(mission_config.get("seed", _layout_seed)) if endless or Meta.is_test_run() else int(Time.get_unix_time_from_system()) ^ int(Time.get_ticks_usec())
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--activities-seed="):
			activity_seed = arg.trim_prefix("--activities-seed=").to_int()
	activities.setup(self, activity_seed)
	# Один ранний эпизод в зачистке/возврате; у основных целей приоритет.
	var optional_episode := mission_config.is_empty() or str(mission_config.get("type", "")) in ["clearance", "reclaim"]
	activities.enabled = optional_episode and (_sim or _bench or not Meta.is_test_run() or OS.get_cmdline_user_args().has("--activities-test"))
	if not activities.enabled:
		activities.set_physics_process(false)
	camera.setup(ARENA, player)
	get_viewport().size_changed.connect(_update_view)
	_update_view()
	var director_args := OS.get_cmdline_user_args()
	if not director_args.has("--director-off") and (not Meta.is_test_run() or _sim or director_args.has("--director-test") or director_args.has("--director-shots") or director_args.has("--director-bench")):
		if director_args.has("--director-test") or director_args.has("--director-shots"):
			spawner.director = _horde_director
			spawner.director.setup(horde, player, int(mission_config.get("seed", _layout_seed)), _map_id)
		else:
			_director_pending = true

	horde.enemy_killed.connect(_on_enemy_killed)
	horde.enemy_died.connect(_on_enemy_died)
	horde.enemy_killed.connect(gore.on_enemy_killed)
	horde.enemy_wounded.connect(gore.on_enemy_wounded)
	horde.enemy_impact.connect(gore.on_enemy_hit)
	horde.armor_hit.connect(effects.armor_impact)
	horde.armor_detached.connect(gore.on_armor_detached)
	horde.spit_fired.connect(hazards.spit)
	horde.fat_burst.connect(hazards.fat_explosion)
	blood_alarm.container_dropped.connect(_on_container_dropped)
	gore.splatter.connect(_on_splatter)
	horde.player_touched.connect(_class_contact)
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
	sfx.listener = player
	var listener := AudioListener2D.new()
	player.add_child(listener)
	listener.make_current()
	horde_audio = HordeAudio.new()
	add_child(horde_audio)
	horde_audio.setup(horde, player, sfx)
	pause_menu = PauseMenu.new()
	$Overlay.add_child(pause_menu)
	pause_menu.game = self
	pause_menu.sfx = sfx
	pause_menu.surrendered.connect(func() -> void:
		player.is_dead = true
		_open_results(false))
	level_up.sfx = sfx
	trader_ui.sfx = sfx
	results.sfx = sfx
	Meta.settings_changed.connect(_apply_settings)
	_apply_settings()
	player.force_auto_aim = Meta.is_test_run() and not _aim_test
	if first_run or (not Meta.is_test_run() and not Meta.first_run.get("skipped", false)):
		var hints := preload("res://scripts/ui/hints.gd").new()
		$HUD/Hud.add_child(hints)
		hints.setup(self)
	if OS.get_cmdline_user_args().has("--guns-test"):
		_run_guns_test.call_deferred()
	if OS.get_cmdline_user_args().has("--boss-test"):
		_run_boss_checks.call_deferred()
	if OS.get_cmdline_user_args().has("--boss-shots"):
		_run_boss_shots.call_deferred()
	if OS.get_cmdline_user_args().has("--class-shots"):
		_run_class_shots.call_deferred()
	if _aim_test:
		spawner.enabled = false
		player.god_mode = true
		gems.collected.disconnect(progression.add_xp)
		_run_aim_test.call_deferred()
	if _audio_test:
		spawner.enabled = false
		player.god_mode = true
		player.autopilot = true
		gems.collected.disconnect(progression.add_xp)
		_run_audio_test.call_deferred()

	if OS.get_cmdline_user_args().has("--q1-test") or OS.get_cmdline_user_args().has("--pack-test"):
		_run_q1_test.call_deferred()
	if _meta_test:
		if OS.get_cmdline_user_args().has("--class-tree-test"):
			_run_class_tree_test.call_deferred()
			return
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
	if OS.get_cmdline_user_args().has("--fx-test"):
		_run_fx_test.call_deferred()
	if _map_test or _map_shots:
		spawner.enabled = false
		weapons.firing_enabled = false
		weapons.set_physics_process(false)
		player.god_mode = true
		player.set_physics_process(false)
		gems.collected.disconnect(progression.add_xp)
		if _map_test:
			_run_map_test.call_deferred()
		else:
			_run_map_shots.call_deferred()
	if _obstacles_test:
		spawner.enabled = false
		weapons.firing_enabled = false
		weapons.set_physics_process(false)
		player.god_mode = true
		player.set_physics_process(false)
		gems.collected.disconnect(progression.add_xp)
		_run_obstacles_test.call_deferred()
	if _sim:
		_sim_report_started = Time.get_ticks_usec()
		print("SIM meta: class_level=%d tree=%d workshop_models=%d owned=%d bonuses=%s models=%s" % [Meta.class_level(), Meta.tree.size(), Meta.workshop.size(), Meta.owned.size(), Meta.run_bonuses(), weapons.slots[0].model])
		horde.reset_variety_seed(_layout_seed ^ 0x53494d)
		gore._hit_rng.seed = _layout_seed ^ 0x474f5245
		explosions._rng.seed = _layout_seed ^ 0x4658
		sfx._rng.seed = _layout_seed ^ 0x534658
		horde_audio._rng.seed = _layout_seed ^ 0x415544
		get_tree().physics_frame.connect(_sim_seed)
		player.god_mode = true
		player.autopilot = true
		Engine.time_scale = 4.0
		Engine.max_physics_steps_per_frame = 16
	Music.begin_combat(int(mission_config.get("seed", _layout_seed)), _sim)
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
	if _hud_test:
		_run_hud_test.call_deferred()
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
	if OS.get_cmdline_user_args().has("--mortal") and (_sim or _boss_test):
		_mortal = true
		player.god_mode = false # Отдельный прогон выживаемости, без изменения старых тестов.
	if not mission_config.is_empty() and _shot_path != "":
		_mission_screenshot.call_deferred()
	if Array(OS.get_cmdline_user_args()).any(func(a: String) -> bool: return a.begins_with("--c6-test")):
		CampaignCombatTest.run.call_deferred(self)
	if OS.get_cmdline_user_args().has("--c2-checks"):
		_mission_checks.call_deferred()
	if OS.get_cmdline_user_args().has("--gore-shots"):
		_run_gore_shots.call_deferred()
	if OS.get_cmdline_user_args().has("--r1d-shots"):
		_run_r1d_shots.call_deferred()
	if OS.get_cmdline_user_args().has("--gore-impact-shots"):
		_run_gore_impact_shots.call_deferred()
	if OS.get_cmdline_user_args().has("--z1-shots"):
		_run_z1_shots.call_deferred()
	if OS.get_cmdline_user_args().has("--armor-test"):
		_run_armor_test.call_deferred()
	if OS.get_cmdline_user_args().has("--armor-shots"):
		_run_armor_shots.call_deferred()
	if OS.get_cmdline_user_args().has("--z1-checks"):
		_run_z1_checks.call_deferred()
	if OS.get_cmdline_user_args().has("--gore-checks"):
		_run_gore_checks.call_deferred()
	if OS.get_cmdline_user_args().has("--activities-test"):
		ActivitiesTest.run.call_deferred(self)
	if OS.get_cmdline_user_args().has("--activities-shots"):
		ActivitiesTest.shots.call_deferred(self, _shot_path)
	if _bench and OS.get_cmdline_user_args().has("--activities-bench"):
		var activity_at := player.position + Vector2(90, -20)
		if obstacles:
			activity_at = obstacles.free_point(activity_at, 54.0)
		if activities.begin(Activities.Kind.TURRET, activity_at if activities.valid_site(activity_at) else activities.find_site()):
			activities._work = Activities.GENERATOR_TIME
			activities._support = Activities.TURRET_TIME
			activities.phase = Activities.Phase.ACTIVE
	if _bench and OS.get_cmdline_user_args().has("--gore-profile"):
		for vp: Viewport in [get_viewport(), floor_decals._vp, floor_decals._blood_vp]:
			RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
	if director_args.has("--director-test"):
		_run_director_test.call_deferred()
	if director_args.has("--endless-test"):
		_run_endless_test.call_deferred()
	if director_args.has("--endless-shots"):
		if get_tree().has_meta("endless_launch_test"):
			_run_endless_launch_test.call_deferred()
		else:
			_run_endless_shots.call_deferred()
	if director_args.has("--director-shots"):
		_run_director_shots.call_deferred()
	gun_lab_controller = GunLabRange.new()
	gun_lab_controller.game = self
	gun_lab_controller.active = gun_lab_range
	add_child(gun_lab_controller)
	if OS.get_cmdline_user_args().has("--gunlab-test"):
		GunLabTest.run.call_deferred(self)
	if OS.get_cmdline_user_args().has("--gunlab-render") or OS.get_cmdline_user_args().has("--gunlab-shots"):
		GunLabTest.capture.call_deferred(self)
	if OS.get_cmdline_user_args().has("--arsenal-test"):
		_run_arsenal_test.call_deferred()
	if OS.get_cmdline_user_args().has("--arsenal-shots"):
		_run_arsenal_shots.call_deferred()
	if OS.get_cmdline_user_args().has("--weapon-fx-shots"):
		_run_arsenal_shots.call_deferred()
	if OS.get_cmdline_user_args().has("--weapon-fx-test"):
		_run_weapon_fx_test.call_deferred()
	if OS.get_cmdline_user_args().has("--fire-shots") or OS.get_cmdline_user_args().has("--fire-bench"):
		_run_fire_stand.call_deferred()
	if OS.get_cmdline_user_args().has("--arsenal-balance"):
		_run_arsenal_balance.call_deferred()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--arsenal-loadout="):
			_arsenal_loadout.call_deferred(arg.trim_prefix("--arsenal-loadout="))
	if director_args.has("--pathing-shots"):
		_run_pathing_shots.call_deferred()
	if director_args.has("--pathing-test"):
		_run_pathing_test.call_deferred()
	if director_args.has("--crowd-test"):
		_run_crowd_test.call_deferred()


var _arsenal_checks := 0
var _arsenal_failed := 0


func _arsenal_check(label: String, ok: bool) -> void:
	_arsenal_checks += 1
	if not ok:
		_arsenal_failed += 1
		print("ARSENAL FAIL ", label)


func _arsenal_loadout(ids: String) -> void:
	weapons.clear_projectiles()
	weapons.slots.clear()
	for id: String in ids.split(","):
		if not WeaponDefs.MODELS.has(id):
			push_error("Unknown arsenal model: " + id)
			return
		weapons.add_weapon(WeaponDefs.MODELS[id]["base"], id)
		weapons.slots.back().level = 5
		weapons.refresh(weapons.slots.size() - 1)
	weapons.refill_all()


func _arsenal_stand() -> void:
	set_physics_process(false)
	spawner.enabled = false
	for node: Node in [weapons, player, horde, effects, gore]: node.set_physics_process(false)
	player.god_mode = true
	player.position = ARENA.get_center()
	player.force_auto_aim = true
	player.manual_aim = false
	player.fire_requested = true
	player.aim_dir = Vector2.RIGHT
	player.tree_still = 1.0
	weapons.obstacles = null
	weapons.camera = null
	weapons.bonuses = {}
	weapons.passives = {}
	horde.count = 0
	weapons.clear_projectiles()


func _arsenal_tick(frames: int) -> void:
	for frame in frames:
		horde._time += 1.0 / 60.0
		weapons._physics_process(1.0 / 60.0)
		effects._physics_process(1.0 / 60.0)
		gore._physics_process(1.0 / 60.0)


func _run_arsenal_test() -> void:
	seed(7107)
	_arsenal_stand()
	var snapshot := Meta.to_dict()
	_arsenal_check("48 models 16 types", WeaponDefs.MODELS.size() == 48 and WeaponDefs.BASES.size() == 16)
	for base: int in WeaponDefs.BASES:
		var voices := {}
		for id: String in WeaponDefs.models_of(base):
			voices[float(WeaponDefs.MODEL_PITCH.get(id, 1.0))] = true
		_arsenal_check("three model timbres " + str(base), voices.size() == 3)
	for id: String in WeaponDefs.MODEL_ORDER:
		horde.count = 0
		weapons.clear_projectiles()
		weapons.slots.clear()
		var base: int = WeaponDefs.MODELS[id]["base"]
		weapons.add_weapon(base, id)
		var s := weapons.slots[0]
		_arsenal_check(id + " art", s.texture != null and ResourceLoader.exists("res://art/gun_" + id + "_large.png"))
		_arsenal_check(id + " sound", sfx.has(weapons.sound_id(s, "shot")) and (base < 8 or sfx.has(weapons.sound_id(s, "mag_in"))))
		for level in range(1, 6):
			s.level = level
			weapons.refresh(0)
			_arsenal_check(id + " level " + str(level), float(s.stats["damage"]) > 0.0 and float(s.stats["reload"]) > 0.0)
		s.level = 1
		weapons.refresh(0)
		s.mag = int(s.stats["mag"])
		var distance := minf(60.0, float(s.stats["range"]) * 0.65)
		for j in 5:
			var e := horde.spawn(player.position + Vector2(distance + j * 3.0, float(j - 2) * 4.0))
			horde.hp[e] = 100000.0
			horde.max_hp[e] = 100000.0
		horde._rebuild_grid()
		var before := weapons.damage_dealt
		var fired := weapons.shots[base]
		_arsenal_tick(150)
		_arsenal_check(id + " shoots and hits", weapons.shots[base] > fired and weapons.damage_dealt > before)
		s.mag = 0
		weapons._start_reload(s)
		_arsenal_tick(ceili(float(s.stats["reload"]) * 60.0) + 1)
		_arsenal_check(id + " reload", not s.reloading and s.mag > 0)
		for module: int in WeaponDefs.MODULES:
			s.modules.clear()
			var status := progression.module_status(0, module)
			_arsenal_check(id + " module compatibility", (status != "") == WeaponDefs.supports_module(base, module))
			if status != "":
				progression.apply({"type":"module", "id":module, "rare":false}, 0, false)
				weapons.refresh(0)
				_arsenal_check(id + " module hit " + str(module), _arsenal_probe(s))
		for ammo in WeaponDefs.AMMO.size():
			if WeaponDefs.supports_ammo(base, ammo):
				s.ammo = ammo
				_arsenal_check(id + " ammo hit " + str(ammo), _arsenal_probe(s))
			else:
				_arsenal_check(id + " rejects ammo", progression.ammo_status(0, ammo) == "")
		if not Meta.owned.has(id): Meta.owned.append(id)
		Meta.workshop[id] = {"damage":5,"rate":5,"mag":5,"reload":5}
		print("ARSENAL model=%s hit=true reload=true L5=true dps_L1=%.2f" % [id, WeaponDefs.effective_dps(id, 1)])
	_arsenal_check("save roundtrip", Meta.from_dict(JSON.parse_string(JSON.stringify(Meta.to_dict()))) and Meta.owned.size() == 48 and Meta.workshop.size() == 48)
	Meta.rng.seed = 7107
	Meta.military_crates = 2048
	var found := {}
	for n in 2048:
		var drop := Meta.open_crate(true)
		if drop.has("model"): found[drop["model"]] = true
	for id: String in WeaponDefs.MODEL_ORDER:
		if WeaponDefs.MODELS[id]["rarity"] != WeaponDefs.Rarity.SERIAL:
			_arsenal_check(id + " crate", found.has(id))
	weapons.slots.clear()
	for base: int in WeaponDefs.BASES: weapons.add_weapon(base)
	_arsenal_check("four slots", weapons.slots.size() == 4)
	_arsenal_feature_checks()
	Meta.from_dict(snapshot)
	print("ARSENALTEST checks=%d failed=%d models=48 types=16" % [_arsenal_checks, _arsenal_failed])
	Meta.finish_test(0 if _arsenal_failed == 0 else 1)


func _arsenal_probe(s: Weapons.Slot) -> bool:
	weapons.clear_projectiles()
	s.aimed = false
	s.reloading = false
	s.mag = int(s.stats["mag"])
	s.heat = 0.0
	weapons._aim_gun(0, horde.pos[0], 1.0)
	var before := weapons.damage_dealt
	for attempt in 3:
		weapons._fire_shot(0, s, 0)
		for step in 90:
			weapons._update_bullets(1.0 / 60.0)
			weapons._update_grenades(1.0 / 60.0)
			weapons._update_stuck(1.0 / 60.0)
		if weapons.damage_dealt > before: return true
	return false


func _arsenal_fixture(id: String, offsets: Array[Vector2], hp := 100000.0) -> Weapons.Slot:
	weapons.clear_projectiles()
	weapons.slots.clear()
	horde.count = 0
	weapons.add_weapon(WeaponDefs.MODELS[id]["base"], id)
	for at: Vector2 in offsets:
		var e := horde.spawn(player.position + at)
		horde.hp[e] = hp
		horde.max_hp[e] = hp
	horde._rebuild_grid()
	return weapons.slots[0]


func _arsenal_feature_checks() -> void:
	var s := _arsenal_fixture("m134", [Vector2(60, 0)])
	var fired := weapons.shots[s.base]
	_arsenal_tick(35)
	_arsenal_check("minigun spin delay", weapons.shots[s.base] == fired and s.spin > 0.0)
	_arsenal_tick(30)
	_arsenal_check("minigun spin fire and movement", weapons.shots[s.base] > fired and player.weapon_speed_mul == 0.65)
	player.fire_requested = false
	_arsenal_tick(60)
	_arsenal_check("minigun releases movement", player.weapon_speed_mul == 1.0)
	player.fire_requested = true
	s = _arsenal_fixture("lpo", [Vector2(40, 0), Vector2(40, 18)])
	weapons._hit_enemy(0, 0, 1.0, Vector2.RIGHT, horde.pos[0], 0.0)
	weapons._contact_fire_t = 0.0
	weapons._update_contact_fire(0.0)
	_arsenal_check("living fire contact", horde.burn_t[1] > 0.0 and horde.dead[0] == 0)
	s = _arsenal_fixture("arc", [Vector2(65, 0), Vector2(100, 25), Vector2(110, -20)])
	s.angle = 0.0
	weapons._fire_shot(0, s, 0)
	_arsenal_check("arc chains without kills", horde.hp[0] < 100000.0 and horde.hp[1] < 100000.0 and horde.hp[2] < 100000.0 and horde.dead[0] == 0)
	var deaths: Array[int] = []
	var capture := func(_p: Vector2, _d: Vector2, death: int, _f: float, _v: int) -> void: deaths.append(death)
	horde.enemy_killed.connect(capture)
	s = _arsenal_fixture("druzhba", [Vector2(28, 0)], 1.0)
	weapons._hit_enemy(0, 0, 10.0, Vector2.RIGHT, horde.pos[0], 0.0)
	_arsenal_check("saw bisects", deaths.back() == Gore.Death.BISECT)
	s = _arsenal_fixture("skif", [Vector2(70, 0)], 1.0)
	var pinned := gore._pinned.size()
	weapons._hit_enemy(0, 0, 10.0, Vector2.RIGHT, horde.pos[0], 0.0)
	_arsenal_check("bolt pins corpse", deaths.back() == Gore.Death.PIN and gore._pinned.size() == pinned + 1)
	horde.enemy_killed.disconnect(capture)
	s = _arsenal_fixture("makarov", [Vector2(60, 0)])
	s.mag = 1
	s.angle = 0.0
	weapons._fire_shot(0, s, 0)
	_arsenal_check("last round triple", is_equal_approx(s.last_damage, float(s.stats["damage"]) * player.tree_damage_multiplier(-1.0) * 3.0))
	s = _arsenal_fixture("aa12", [Vector2(60, 0)])
	_arsenal_check("slug replaces pellets", s.stats["proj"] == 1 and int(s.stats["pierce"]) == 2)
	s = _arsenal_fixture("svd", [Vector2(60, 0)])
	player.tree_still = 1.0
	weapons._hit_enemy(0, 0, 10.0, Vector2.RIGHT, horde.pos[0], 0.0)
	_arsenal_check("focus standing bonus", horde.hp[0] <= 100000.0 - 13.5)
	s = _arsenal_fixture("saiga", [Vector2(60, 0)])
	progression.apply({"type":"module","id":WeaponDefs.Module.SPLIT,"rare":false},0,false)
	weapons.add_weapon(WeaponDefs.Base.SAW, "druzhba")
	trader.free_moves = 1
	_arsenal_check("trader rejects incompatible transfer", not trader.can_move(0, 0, 1))


## Один и тот же сид и состав для сравнения огня до/после.
func _run_fire_stand() -> void:
	seed(7107)
	_arsenal_stand()
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	# Фиксированный размер кадра: событие смены fullscreen приходит асинхронно.
	get_window().content_scale_size = Vector2i(1280, 720)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	$HUD.visible = false
	camera.target = null
	camera.position_smoothing_enabled = false
	camera.position = player.position
	camera.zoom = Vector2.ONE * 2.0
	weapons.slots.clear()
	weapons.add_weapon(WeaponDefs.Base.FLAMER, "lpo")
	weapons.slots[0].cooldown = 1000.0
	await get_tree().process_frame
	for j in 500:
		var at := player.position + Vector2.from_angle(float(j) * 2.39996) * (40.0 + sqrt(float(j)) * 8.0)
		var e := horde.spawn(at, j % 4)
		horde.hp[e] = 100000.0
		horde.max_hp[e] = 100000.0
		# В замере число горящих не должно зависеть от FPS и числа тиков распространения.
		if j % 3 == 0 or OS.get_cmdline_user_args().has("--fire-bench"):
			horde.ignite(e, 0.01, 60.0)
			horde._burn_started[e] = -float(j % 9) * 0.4
	horde._rebuild_grid()
	for j in 12:
		effects.burning_patch(player.position + Vector2(45 + j * 7, 26 + sin(j * 2.7) * 13), 5.0, 0.8)
	_arsenal_tick(90)
	for j in horde.count:
		if horde.burn_t[j] > 0.0:
			horde._burn_started[j] = horde._time - float(j % 9) * 0.26
			if not OS.get_cmdline_user_args().has("--fire-bench") and not OS.get_cmdline_user_args().has("--capture-before"):
				# Разные моменты поджога/затухания, те же позиции и seed толпы W7c.
				if j % 5 == 0: horde._burn_started[j] = horde._time - 0.08
				if j % 5 == 1: horde.burn_t[j] = 0.12 + horde.seed_value[j] * 0.25
	horde._render()
	var prefix := "w7d_before_" if OS.get_cmdline_user_args().has("--capture-before") else "w7d_"
	if OS.get_cmdline_user_args().has("--fire-bench"):
		var elapsed := 0.0
		var frames := 0
		var worst := 0.0
		while elapsed < 13.0:
			var start := Time.get_ticks_usec()
			_arsenal_tick(1)
			effects.weapon_sector(player.position + Vector2(8, 0), Vector2.RIGHT, 100.0, 30.0, false)
			horde._render()
			await RenderingServer.frame_post_draw
			var dt := float(Time.get_ticks_usec() - start) / 1000000.0
			elapsed += dt
			if elapsed > 3.0:
				frames += 1
				worst = maxf(worst, dt * 1000.0)
		print("FIREBENCH enemies=500 burning=%d avg_fps=%.1f worst_ms=%.2f" % [horde._fire_mm.visible_instance_count, float(frames) / (elapsed - 3.0), worst])
		Meta.finish_test()
		return
	for frame in 8:
		_arsenal_tick(6)
		effects.weapon_sector(player.position + Vector2(8, 0), Vector2.RIGHT, 100.0, 30.0, false)
		horde._render()
		await RenderingServer.frame_post_draw
		var shot := get_viewport().get_texture().get_image()
		shot.save_png("res://design/tasks/reports/" + prefix + "seq_%02d.png" % frame)
		if frame == 3:
			shot.save_png("res://design/tasks/reports/" + prefix + "burning_crowd.png")
			var close := shot.get_region(Rect2i(650, 230, 260, 190))
			close.resize(1040, 760, Image.INTERPOLATE_NEAREST)
			close.save_png("res://design/tasks/reports/" + prefix + "body_fire_close.png")
			shot.get_region(Rect2i(600, 280, 340, 210)).save_png("res://design/tasks/reports/" + prefix + "flamer.png")
			shot.get_region(Rect2i(685, 365, 240, 110)).save_png("res://design/tasks/reports/" + prefix + "ground_fire.png")
			shot.get_region(Rect2i(660, 150, 350, 240)).save_png("res://design/tasks/reports/" + prefix + "smoke.png")
			for y in shot.get_height():
				for x in shot.get_width():
					var c := shot.get_pixel(x, y)
					var gray := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
					shot.set_pixel(x, y, Color(gray, gray, gray, c.a))
			shot.save_png("res://design/tasks/reports/" + prefix + "gray.png")
	# Отдельная деталь топлива: тела не закрывают низкие языки и копоть.
	horde.visible = false
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().get_region(Rect2i(685, 365, 240, 110)).save_png("res://design/tasks/reports/" + prefix + "ground_fire.png")
	horde.visible = true
	print("FIRESHOTS enemies=500 burning=%d frames=8 step=0.1" % horde._fire_mm.visible_instance_count)
	await _capture_fire_details(prefix)
	Meta.finish_test()


## Отдельные стадии и реальное перемещение бегуна, без изменения боевой симуляции.
func _capture_fire_details(prefix: String) -> void:
	weapons.slots.clear()
	effects.visible = false
	player.visible = false
	horde.count = 0
	camera.zoom = Vector2.ONE * 6.0
	var ages := [0.08, 1.3, 4.0, 6.0, -1.0]
	for j in ages.size():
		var e := horde.spawn(player.position + Vector2((j - 2) * 27.0, 0.0), Horde.Kind.SHAMBLER)
		horde.angle[e] = -0.4
		horde.seed_value[e] = 0.37
		if j < 3:
			horde.ignite(e, 0.01, 3.0 if j < 2 else 0.16)
		if ages[j] >= 0.0:
			horde._burn_started[e] = horde._time - ages[j]
	horde._render()
	await RenderingServer.frame_post_draw
	var stages := get_viewport().get_texture().get_image().get_region(Rect2i(200, 225, 880, 270))
	stages.save_png("res://design/tasks/reports/" + prefix + "stages.png")
	# Два направления хода: хвост должен оставаться позади, а не над головой.
	horde.count = 0
	for j in 2:
		var e := horde.spawn(player.position + Vector2(-23.0, (j - 0.5) * 28.0), Horde.Kind.RUNNER)
		horde.ignite(e, 0.01, 3.0)
		horde._burn_started[e] = horde._time - 0.7
		horde.angle[e] = 0.0 if j == 0 else PI
	horde._render()
	for frame in 12:
		horde._time += 1.0 / 60.0
		horde.pos[0] += Vector2.RIGHT * (88.0 / 60.0)
		horde.pos[1] += Vector2.LEFT * (88.0 / 60.0)
		horde._render()
		await RenderingServer.frame_post_draw
		if frame in [5, 8, 11]:
			var runner := get_viewport().get_texture().get_image().get_region(Rect2i(200, 185, 880, 350))
			runner.save_png("res://design/tasks/reports/" + prefix + "runner_%02d.png" % frame)
			if frame == 11:
				runner.save_png("res://design/tasks/reports/" + prefix + "runner_fire.png")


func _run_arsenal_shots() -> void:
	seed(7107)
	var polish := OS.get_cmdline_user_args().has("--weapon-fx-shots")
	var prefix := "w7b_" if polish else "w7_"
	_arsenal_stand()
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	$HUD.visible = false
	camera.target = null
	camera.position_smoothing_enabled = false
	camera.position = player.position
	camera.zoom = Vector2.ONE * 2.0
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	layer.add_child(label)
	label.position = Vector2(36, 28)
	label.add_theme_font_size_override("font_size", 26)
	var ids := ["pkm", "m134", "lpo", "druzhba", "skif", "saiga", "svd", "arc"]
	if polish: ids = ["lpo", "arc", "druzhba", "skif", "m134"]
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--arsenal-shot-model="):
			ids = [arg.trim_prefix("--arsenal-shot-model=")]
	for id: String in ids:
		await _arsenal_clean_shot()
		weapons.clear_projectiles()
		weapons.slots.clear()
		horde.count = 0
		var base: int = WeaponDefs.MODELS[id]["base"]
		weapons.add_weapon(base, id)
		var reach: float = weapons.slots[0].stats["range"]
		for j in 18:
			var at := player.position + Vector2.from_angle(float(j % 5 - 2) * 0.2) * (minf(reach * 0.75, 100.0) + float(j / 5) * 17.0)
			var e := horde.spawn(at, Horde.Kind.SHAMBLER)
			horde.hp[e] = 6.0 if base == WeaponDefs.Base.SAW and j in [1, 2, 3] else 300.0
			horde.max_hp[e] = 300.0
		horde._rebuild_grid()
		label.text = WeaponDefs.MODELS[id]["name"] + " · " + WeaponDefs.TRAITS[WeaponDefs.MODELS[id]["trait"]]["name"]
		weapons.slots[0].cooldown = 10.0
		_arsenal_tick(65)
		if base in [WeaponDefs.Base.LMG, WeaponDefs.Base.MINIGUN]:
			# На кадре видна очередь, а не одиночная пуля после раскрутки.
			weapons.slots[0].cooldown = 0.0
		weapons._fire_shot(0, weapons.slots[0], weapons.slots[0].target)
		_arsenal_tick(4 if base in [WeaponDefs.Base.FLAMER, WeaponDefs.Base.TESLA, WeaponDefs.Base.SAW] else 10)
		if polish and base in [WeaponDefs.Base.FLAMER, WeaponDefs.Base.MINIGUN]:
			weapons.slots[0].cooldown = 0.0
			_arsenal_tick(36 if base == WeaponDefs.Base.FLAMER else 18)
		if polish and base == WeaponDefs.Base.SAW:
			# Половины успевают разойтись, а новый контакт оставляет свежий фонтан.
			_arsenal_tick(8)
			weapons._fire_shot(0, weapons.slots[0], weapons.slots[0].target)
			_arsenal_tick(2)
		if base == WeaponDefs.Base.CROSSBOW:
			# Болт виден в полёте до первой цели.
			weapons._fire_shot(0, weapons.slots[0], weapons.slots[0].target)
		weapons.queue_redraw()
		horde._render()
		horde.queue_redraw()
		if polish:
			print("WEAPONFXSHOT model=%s burning=%d arcs=%d cuts=%d" % [id, horde._fire_mm.visible_instance_count, effects._weapon_arcs.size(), effects._cut_pos.size()])
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/" + prefix + Weapons.GUN_IDS[base] + ".png")
		if polish and base == WeaponDefs.Base.FLAMER:
			for frame in 8:
				_arsenal_tick(6)
				horde._render()
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/w7b_flame_seq_%02d.png" % frame)
	await _arsenal_clean_shot()
	_arsenal_loadout("lpo,arc,m134" if polish else "m134,lpo")
	horde.count = 0
	for j in 500:
		var e := horde.spawn(player.position + Vector2.from_angle(float(j) * 2.39996) * (35.0 + sqrt(float(j)) * 9.0), j % 4)
		horde.hp[e] = 500.0
	horde._rebuild_grid()
	label.text = "ЛПО / Дуга / М134 · 500 целей" if polish else "М134 / ЛПО · 500 целей"
	_arsenal_tick(96)
	horde._render()
	horde.queue_redraw()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/" + prefix + "crowd_fire.png")
	if polish:
		_arsenal_tick(60)
		horde._render()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/w7b_burning_crowd.png")
	print("ARSENALSHOTS types=%d crowd=500" % ids.size())
	Meta.finish_test()


## Следующий кадр стенда начинается с пустых пулов и чистого пола.
func _arsenal_clean_shot() -> void:
	effects._n = 0
	effects._cn = 0
	effects.clear_weapon_fx()
	gore.count = 0
	gore.remains_count = 0
	gore._pending_hits.clear()
	gore._pulses.clear()
	gore._pinned.clear()
	floor_decals._blood.clear()
	floor_decals._stamps.clear()
	floor_decals._remains_stamps.clear()
	floor_decals._pool_tex.clear()
	floor_decals._pool_pos.clear()
	floor_decals._pool_rot.clear()
	floor_decals._pool_scale.clear()
	floor_decals._pool_age.clear()
	floor_decals._pool_step.clear()
	floor_decals._landings.clear()
	floor_decals._remains_cover.fill(0)
	floor_decals._coverage.fill(0.0)
	floor_decals._wet_time.fill(-100.0)
	for canvas: Node2D in [floor_decals._canvas, floor_decals._blood_canvas, floor_decals._remains_canvas]:
		canvas.queue_redraw()
	for vp: SubViewport in [floor_decals._vp, floor_decals._blood_vp]:
		vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw


func _run_weapon_fx_test() -> void:
	seed(771107)
	_arsenal_stand()
	effects.clear_weapon_fx()
	for j in 160:
		effects.burning_patch(player.position + Vector2(float(j) * 10.0, 0))
		effects.ground_bolt(player.position, Vector2.RIGHT)
		effects.weapon_arc(player.position, player.position + Vector2(50, 0))
	_arsenal_check("fire pool cap", effects._fire_pos.size() == 64)
	_arsenal_check("bolt pool cap", effects._bolt_pos.size() == 64)
	_arsenal_check("arc pool cap", effects._weapon_arcs.size() == 64)
	for j in 20: effects.saw_contact(player.position, Vector2.RIGHT)
	_arsenal_check("cut pool cap", effects._cut_pos.size() == 16)
	effects._physics_process(3.1)
	_arsenal_check("fire and cuts expire", effects._fire_pos.is_empty() and effects._cut_pos.is_empty() and effects._weapon_arcs.is_empty())
	effects._physics_process(9.0)
	_arsenal_check("bolts expire", effects._bolt_pos.is_empty())
	var e := horde.spawn(player.position + Vector2(40, 0))
	horde.ignite(e, 4.0, 2.0, 0.3, 20.0)
	horde.shock_until[e] = horde._time + 3.0
	horde._time += 1.0
	horde._render()
	_arsenal_check("one batched body flame", horde._fire_mm.visible_instance_count == 1)
	_arsenal_check("body flame transform", absf(horde._fire_buf[3] - horde._buf[3]) < 0.01 and horde._fire_buf[7] < horde._buf[7] - 9.0)
	_arsenal_check("body flame opacity", horde._fire_buf[9] == 1.0)
	_arsenal_check("char and shock channel", horde._buf[8] >= 80.0)
	_arsenal_check("procedural fuel and jet", effects._ground_mat.shader != null and effects._jet_mat.get_shader_parameter("jet") == true)
	_arsenal_check("shared smoke noise", horde._smoke_mat.get_shader_parameter("noise_tex") == horde._fire_mat.get_shader_parameter("noise_tex"))
	var moved := horde.spawn(player.position + Vector2(60, 0))
	horde.shock_until[moved] = 7.0
	horde.bolt_dir[moved] = Vector2.LEFT
	horde._burn_started[moved] = 2.0
	horde.dead[e] = 1
	horde._compact()
	_arsenal_check("compact preserves visual channels", horde.count == 1 and horde.shock_until[0] == 7.0 and horde.bolt_dir[0] == Vector2.LEFT and horde._burn_started[0] == 2.0)
	print("WEAPONFXTEST checks=%d failed=%d fire_cap=64 bolt_cap=64 cut_cap=16" % [_arsenal_checks, _arsenal_failed])
	Meta.finish_test(0 if _arsenal_failed == 0 else 1)


## Реальные попадания на трёх дистанциях, одиночная и плотная группа; одинаковые L1 и seed.
func _run_arsenal_balance() -> void:
	seed(7107)
	_arsenal_stand()
	player.class_id = "assault"
	for id: String in ["ak_s", "mosin", "pkm", "m134", "lpo", "druzhba", "skif", "saiga", "svd", "arc"]:
		for distance: float in [30.0, 100.0, 240.0]:
			for group: int in [1, 6]:
				weapons.clear_projectiles()
				weapons.slots.clear()
				horde.count = 0
				weapons.add_weapon(WeaponDefs.MODELS[id]["base"], id)
				var s := weapons.slots[0]
				s.ammo = WeaponDefs.Ammo.STANDARD
				for j in group:
					var e := horde.spawn(player.position + Vector2(distance + j * 8.0, float(j % 2) * 8.0))
					horde.hp[e] = 1000000.0
					horde.max_hp[e] = 1000000.0
				horde._rebuild_grid()
				var before := weapons.damage_dealt
				_arsenal_tick(1200)
				print("ARSENALDPS model=%s level=1 distance=%.0f targets=%d seconds=20 direct=%.2f" % [id, distance, group, (weapons.damage_dealt - before) / 20.0])
	print("ARSENALBALANCE rows=60 seed=7107 burn_dps_per_target=4")
	Meta.finish_test()


func _run_gore_checks() -> void:
	$World.process_mode = Node.PROCESS_MODE_DISABLED
	set_physics_process(false)
	set_process(false)
	spawner.enabled = false
	var ok := true
	var p := player.position
	ok = _gore_impact_checks(p) and ok
	horde.count = 0
	var e := horde.spawn(p + Vector2(50, 0))
	horde.hp[e] = 1000.0
	horde.max_hp[e] = 1000.0
	for pellet in 8:
		horde.damage(e, 4.0, Vector2.RIGHT, 12.0)
	ok = _gore_check(horde.hp[e] == 968.0 and gore._pending_hits.size() == 1, "pellets_one_reaction_full_damage") and ok
	gore._flush_hits(0.1)
	ok = _gore_check(gore._pending_hits.is_empty() and effects.particle_count() > 0, "exit_spray") and ok
	if OS.get_cmdline_user_args().has("--r1d"):
		ok = _r1d_checks(p) and ok
	if OS.get_cmdline_user_args().has("--r1c"):
		ok = _r1c_checks(p) and ok
	if OS.get_cmdline_user_args().has("--r1b"):
		ok = _r1b_impact_checks(p) and ok
	gore.count = 0
	gore.remains_count = 0
	gore.on_enemy_killed(p, Vector2.RIGHT, Gore.Death.BISECT, 0.0, 0)
	var crawler := gore.count - 1
	var before := gore._rot[crawler]
	player.position = p + Vector2(0, 100)
	gore._update_special(crawler, 0.1)
	ok = _gore_check(gore._rot[crawler] == before, "crawler_inertia") and ok
	player.position = p
	for tick in 600:
		for j in 4:
			gore.on_enemy_killed(p + Vector2(float(j) * 12.0, 15.0), Vector2.RIGHT, tick % 7, 0.0, j)
		gore._physics_process(0.1)
		effects._physics_process(0.1)
		floor_decals._process(0.1)
		ok = gore.remains_count <= Gore.MAX_REMAINS and floor_decals.pool_count() <= FloorDecals.MAX_POOLS and ok
		if tick % 100 == 99:
			await get_tree().process_frame
	ok = _gore_check(ok and floor_decals._blood.size() <= FloorDecals.MAX_STAMPS, "bounded_flood_2400_deaths") and ok
	ok = _gore_check(floor_decals._remains_stamps.size() <= FloorDecals.MAX_STAMPS and floor_decals.remains_baked > 0, "bounded_permanent_remains_queue") and ok
	for tick in 320:
		gore._physics_process(0.1)
		effects._physics_process(0.1)
		floor_decals._process(0.1)
	ok = _gore_check(gore.remains_count > 0 or floor_decals.remains_baked > 0, "remains_retained_or_baked") and ok
	print("R1CHECK ok=%s remains_peak=%d stamps_queue=%d particles=%d" % [ok, gore.remains_peak, floor_decals._blood.size(), effects.particle_count()])
	get_tree().quit(0 if ok else 1)


func _gore_check(ok: bool, label: String) -> bool:
	print("R1CHECK %s=%s" % [label, ok])
	return ok


func _gore_impact_checks(p: Vector2) -> bool:
	var ok := true
	gore._hit_rng.seed = 91573
	var total := 0.0
	var squared := 0.0
	var forms: Dictionary = {}
	var bands := PackedInt32Array([0, 0, 0])
	var samples := 0
	var entrance_ok := true
	for j in 100:
		floor_decals._blood.clear()
		floor_decals._coverage.fill(0.0)
		gore._pending_hits.clear()
		effects._n = 0
		effects._blood_tokens = 300.0
		effects._blood_frame = -1
		var entry := p + Vector2(-2, 1)
		gore._on_impact_geometry(j, entry, 0.0, WeaponDefs.Base.REVOLVER, true, false)
		gore.on_enemy_hit(p, Vector2.RIGHT, 0, 30.0, 90.0, j)
		var hit: Array = gore._pending_hits[j]
		var recipe: Dictionary = hit[7]
		var nearest := INF
		for stamp: Array in floor_decals._blood:
			if int(stamp[0]) == 1:
				nearest = minf(nearest, (stamp[1] as Vector2).distance_to(entry - floor_decals._origin))
		entrance_ok = entrance_ok and nearest <= 12.0
		var amount: float = recipe["volume"]
		total += amount
		squared += amount * amount
		forms[recipe["mask"]] = true
		gore._flush_hits(0.02)
		for k in effects._n:
			if effects._bake[k] == 2 or effects._pos[k].distance_to(recipe["exit"]) > 0.01:
				continue
			var reach := effects._vel[k].length() * (1.0 - exp(-effects._drag[k] * effects._life[k])) / effects._drag[k]
			bands[mini(2, int(reach / 80.0))] += 1
			samples += 1
	var cv := sqrt(squared / 100.0 - pow(total / 100.0, 2.0)) / (total / 100.0)
	var near_fraction := float(bands[0]) / samples
	var mid_fraction := float(bands[1]) / samples
	var far_fraction := float(bands[2]) / samples
	print("GOREIMPACT samples=%d bands=%s fractions=%.3f,%.3f,%.3f volume_cv=%.3f masks=%d" % [samples, bands, near_fraction, mid_fraction, far_fraction, cv, forms.size()])
	ok = _gore_check(entrance_ok, "entry_within_12_every_hit") and ok
	ok = _gore_check(near_fraction >= 0.63 and near_fraction <= 0.78 and mid_fraction >= 0.15 and mid_fraction <= 0.28 and far_fraction >= 0.04 and far_fraction <= 0.12, "range_0_1m_1_2m_2_3m") and ok
	ok = _gore_check(cv >= 0.35 and forms.size() >= 12, "volume_variation_and_masks") and ok
	var regions: Array[int] = []
	var outcomes: Array[int] = []
	for local: Vector2 in [Vector2(4, 0), Vector2(0, 0), Vector2(0, 3.5)]:
		var recipe := gore._hit_recipe(p, Vector2.RIGHT, 0, 30.0, 90.0, false, [p + local.rotated(1.2), 1.2, WeaponDefs.Base.REVOLVER, true, true])
		regions.append(recipe["region"])
		gore.count = 0
		gore._hit_parts(recipe, 0, true, Gore.Death.NORMAL)
		outcomes.append(gore._tex[0])
	ok = _gore_check(regions == [Gore.Region.HEAD, Gore.Region.TORSO, Gore.Region.LIMB] and outcomes[0] != outcomes[1] and outcomes[1] != outcomes[2], "body_rotation_and_region_parts") and ok
	gore.count = 0
	gore.remains_count = 0
	floor_decals._stamps.clear()
	var i := gore._add(Gore.Kind.GIB, gore._t_organs[0], p, Vector2.ZERO, 0.0, 0.0, Color.WHITE, 5.0, true)
	gore._bake(i)
	gore.count = 0
	gore._age_remains(179.0)
	var retained := gore.remains_count == 1
	var baked_before := floor_decals.remains_baked
	gore._age_remains(2.0)
	ok = _gore_check(retained and gore.remains_count == 0 and floor_decals.remains_baked == baked_before + 1 and floor_decals._remains_stamps.size() == 1, "remains_180s_then_permanent_stamp") and ok
	var archived: int = floor_decals.remains_baked
	for j in 100:
		floor_decals.bake_remains(gore._textures[gore._t_organs[0]], p, j * 0.1, Vector2.ONE, Color.WHITE)
	ok = _gore_check(floor_decals.remains_baked == archived + 100 and floor_decals._remains_stamps.size() == 1, "dense_pile_keeps_visible_silhouette") and ok
	floor_decals.bake_remains(gore._textures[gore._t_corpse[0]], p, 0.3, Vector2.ONE, Gore.CORPSE_TINT)
	floor_decals.bake_remains(gore._textures[gore._t_organs[0]], p + Vector2(7, 0), 0.0, Vector2.ONE, Color.WHITE)
	ok = _gore_check(floor_decals._remains_stamps.size() == 2, "body_covers_small_pieces") and ok
	floor_decals.bake_remains(gore._textures[gore._t_organs[0]], p + Vector2(48, 0), 0.0, Vector2.ONE, Color.WHITE)
	ok = _gore_check(floor_decals._remains_stamps.size() == 3, "separate_remains_stay_separate") and ok
	gore._pending_hits.clear()
	gore._pulses.clear()
	gore.count = 0
	floor_decals._stamps.clear()
	floor_decals._remains_stamps.clear()
	floor_decals._remains_cover.fill(0)
	return ok


func _r1b_impact_checks(p: Vector2) -> bool:
	var ok := true
	for low in [false, true]:
		effects._n = 0
		effects._blood_tokens = 300.0
		effects._blood_frame = -1
		gore.count = 0
		gore.gore_multiplier = 0.25 if low else 1.0
		effects.gore_multiplier = gore.gore_multiplier
		gore.on_enemy_hit(p + Vector2(38, 0), Vector2.RIGHT, 0, 48.0, 110.0, 7001)
		gore._flush_hits(0.1)
		var reverse := false
		var big := false
		var mist := false
		for j in effects._n:
			reverse = reverse or effects._vel[j].x < 0.0
			big = big or effects._bake[j] == 3
			mist = mist or effects._bake[j] == 2 and is_equal_approx(effects._life[j], 0.12)
		ok = _gore_check(reverse and big and mist, "r1b_entry_exit_mist_low" if low else "r1b_entry_exit_mist_full") and ok
		ok = _gore_check(gore.count <= 3, "r1b_heavy_gib_cap") and ok
		print("R1B CHECK low=%s particles=%d chunks=%d" % [low, effects._n, gore.count])
		for tick in 30:
			effects._physics_process(0.1)
			gore._physics_process(0.1)
		ok = _gore_check(effects._n == 0 and gore.count == 0, "r1b_transients_expire") and ok
	gore.gore_multiplier = 1.0
	effects.gore_multiplier = 1.0
	effects._n = 0
	effects._blood_tokens = 0.0
	effects._blood_frame = Engine.get_process_frames()
	effects._blood_in_frame = 240
	effects.blood_impact(p, Vector2.RIGHT, 1.0, true, true, gore._hit_rng)
	var reserved := effects._n
	effects.blood_impact(p, Vector2.RIGHT, 1.0, true, false, gore._hit_rng)
	ok = _gore_check(reserved == 10 and effects._n == reserved, "r1b_near_reserve_far_simplified") and ok
	return ok


## Стенд R1: одинаковый поток смертей, независимо от RNG эффектов и частоты кадров.
func _run_gore_shots() -> void:
	set_process(false)
	set_physics_process(false)
	spawner.enabled = false
	_full_loadout()
	announce_t = 0.0
	for node: Node in [$World, $BloodAlarm, $Spawner]:
		node.process_mode = Node.PROCESS_MODE_DISABLED
	gems.collected.disconnect(progression.add_xp)
	player.god_mode = true
	player.force_auto_aim = true
	camera.target = null
	camera.position_smoothing_enabled = false
	camera.shake_multiplier = 0.0
	var center := obstacles.free_point(_map_data["start"], 16.0)
	player.position = center
	camera.position = center
	camera.zoom = Vector2(3.0, 3.0)
	player.aim_dir = Vector2.RIGHT
	player.add_dirt(140.0)
	player._physics_process(0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 81073
	var path := _shot_path if not _shot_path.is_empty() else "res://design/tasks/reports/r1_after.png"
	if OS.get_cmdline_user_args().has("--r1d"):
		await _r1d_details(center)
	if OS.get_cmdline_user_args().has("--r1c"):
		await _r1c_detail_shots(center)
		if not OS.get_cmdline_user_args().has("--r1c-before"):
			await _r1c_stain_shots(center)
			await _r1c_palette_shot(center)
		if OS.get_cmdline_user_args().has("--r1c-details"):
			get_tree().quit()
			return
	if OS.get_cmdline_user_args().has("--gore-hit-only"):
		await _gore_hit_shots(center)
		get_tree().quit()
		return
	var peak := 0
	for second in 600:
		for tick in 10:
			# 12 смертей/с; основная масса в одном коридоре перед бойцом.
			for event in (2 if tick < 2 else 1):
				var at := center + Vector2(rng.randfn(25.0, 85.0), rng.randfn(0.0, 55.0))
				at = obstacles.free_point(at, 6.0)
				var impulse := (at - center).normalized()
				var death := rng.randi_range(0, 6)
				var variant := rng.randi_range(0, 6)
				seed(second * 1000 + tick * 10 + event + 81073)
				gore.on_enemy_killed(at, impulse, death, impulse.angle(), variant)
			gore._physics_process(0.1)
			effects._physics_process(0.1)
			floor_decals._process(0.1)
			peak = maxi(peak, gore.count)
		await RenderingServer.frame_post_draw
		if second + 1 in [60, 300, 480, 600]:
			print("GORESTAND seconds=%d debris=%d peak=%d remains=%d remains_peak=%d stamps=%d queue=%d pools=%d memory=%d video=%d baked=%d occluded=%d" % [second + 1, gore.count, peak, gore.remains_count, gore.remains_peak, floor_decals.stamps_total, floor_decals._blood.size(), floor_decals.pool_count(), OS.get_static_memory_usage(), Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), floor_decals.remains_baked, floor_decals.remains_occluded])
		if second + 1 in [300, 600]:
			time = float(second + 1)
			await _gore_threat_shot(path.replace(".png", "_%dmin.png" % ((second + 1) / 60)), center)
	print("GORESTAND complete seed=81073 deaths=7200 zoom=3 map=", _map_id)
	if OS.get_cmdline_user_args().has("--r1d"):
		assert(floor_decals._blood_vp.get_texture().get_image().save_png("res://design/tasks/reports/r1d_accumulation.png") == OK)
	if OS.get_cmdline_user_args().has("--gore-closeup"):
		await _gore_hit_shots(center)
	get_tree().quit()


func _gore_threat_shot(path: String, center: Vector2) -> void:
	horde.count = 0
	seed(81073)
	for j in 65:
		var at := center + Vector2(randf_range(-220.0, 240.0), randf_range(-115.0, 120.0))
		if at.distance_squared_to(center) < 1600.0:
			at.x += 55.0
		horde.spawn(obstacles.free_point(at, 7.0), j % 4)
	horde.spawn(center + Vector2(38, -18), Horde.Kind.RUNNER)
	horde.spawn(center + Vector2(72, 34), Horde.Kind.SPITTER)
	if OS.get_cmdline_user_args().has("--r1d") and not OS.get_cmdline_user_args().has("--r1d-before"):
		# Короткая пройденная дорожка бойца и два подхода живых по настоящей мокроте.
		for step in 15:
			player.position = center + Vector2(-35.0 + sin(step * 0.25) * 5.0, -98.0 + step * 7.0)
			floor_decals._player_steps()
		player.position = center
		floor_decals._player_steps()
		for i in [horde.count - 2, horde.count - 1]:
			for step in 8:
				horde.step_acc[i] = Horde.STEP_LENGTH
				horde._feet_and_drips(i, horde.pos[i] + Vector2(7.0 * (7 - step), 0), PI)
		floor_decals._process(0.0)
	horde._rebuild_grid()
	horde._render()
	horde.queue_redraw()
	hazards.clear()
	hazards.acid_pool(center + Vector2(40, 42), 18.0, 5.0, 30.0)
	hazards.queue_redraw()
	effects.queue_redraw()
	pickups.spawn(center + Vector2(-38, 30), Pickups.Kind.MEDKIT)
	pickups.spawn(center + Vector2(-65, -30), Pickups.Kind.CRATE)
	pickups.queue_redraw()
	$HUD/Hud.queue_redraw()
	_update_view()
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	assert(shot.save_png(path) == OK)
	shot.convert(Image.FORMAT_L8)
	assert(shot.save_png(path.replace(".png", "_gray.png")) == OK)
	print("GORESTAND screenshot: ", path)
	if (OS.get_cmdline_user_args().has("--r1b") or OS.get_cmdline_user_args().has("--r1c") or OS.get_cmdline_user_args().has("--r1d")) and (path.contains("5min") or OS.get_cmdline_user_args().has("--r1d")):
		# Поверх накопления — одновременные ранения, без движущейся камеры.
		var hit_count := 0
		for i in horde.count:
			if horde.pos[i].distance_squared_to(center) < 22500.0:
				horde.hp[i] = 100.0
				horde.max_hp[i] = 100.0
				horde.damage(i, 7.0 if i % 3 else 30.0, (horde.pos[i] - center).normalized(), 50.0)
				hit_count += 1
		gore._physics_process(1.0 / 60.0)
		effects._physics_process(0.05)
		floor_decals._process(0.05)
		horde._render()
		await RenderingServer.frame_post_draw
		var fight_path := path if OS.get_cmdline_user_args().has("--r1c") or OS.get_cmdline_user_args().has("--r1d") else "res://design/tasks/reports/r1b_fight_5min.png"
		assert(get_viewport().get_texture().get_image().save_png(fight_path) == OK)
		print("GORESTAND fight simultaneous_hits=%d camera=3 screenshot=%s" % [hit_count, fight_path])
		if OS.get_cmdline_user_args().has("--r1d") and not OS.get_cmdline_user_args().has("--r1d-before"):
			var activity_at := obstacles.free_point(center + Vector2(-125, -45), 54.0)
			activities.clear()
			var started := activities.begin(Activities.Kind.SUPPLY, activity_at)
			activities._age = 12.0
			activities._work = 8.0
			activities.queue_redraw()
			activities._floor.queue_redraw()
			await RenderingServer.frame_post_draw
			assert(get_viewport().get_texture().get_image().save_png(path.replace(".png", "_ev1.png")) == OK)
			print("R1DSTAND activity_visible=%s position=%s" % [started, activity_at])
			activities.clear()
	horde.count = 0
	horde._render()
	hazards.clear()


## Реальный урон трёх стволов, реакция в одном тике; камера остаётся штатной.
func _gore_hit_shots(center: Vector2) -> void:
	if OS.get_cmdline_user_args().has("--r1b"):
		await _r1b_hit_shots(center)
		return
	var images: Array[Image] = []
	for base: int in [WeaponDefs.Base.RIFLE, WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.SNIPER]:
		gore.count = 0
		effects._n = 0
		horde.count = 0
		var at := center + Vector2(38, 0)
		var e := horde.spawn(at, Horde.Kind.SHAMBLER)
		horde.hp[e] = 1000.0
		horde.max_hp[e] = 1000.0
		var stats: Dictionary = WeaponDefs.BASES[base]
		for pellet in int(stats["proj"]):
			horde.damage(e, float(stats["damage"]), Vector2.RIGHT, float(stats["knock"]))
		gore._physics_process(1.0 / 60.0)
		effects._physics_process(0.06)
		horde._render()
		floor_decals._process(0.06)
		await RenderingServer.frame_post_draw
		var frame := get_viewport().get_texture().get_image()
		frame.save_png("res://design/tasks/reports/r1_hit_%d.png" % base)
		var screen_at := get_viewport().get_canvas_transform() * center
		images.append(frame.get_region(Rect2i(Vector2i(screen_at) - Vector2i(70, 100), Vector2i(300, 200))))
	var sheet := Image.create(900, 200, false, Image.FORMAT_RGB8)
	for j in images.size():
		sheet.blit_rect(images[j], Rect2i(0, 0, 300, 200), Vector2i(j * 300, 0))
	sheet.save_png("res://design/tasks/reports/r1_hit_closeup.png")
	print("GORESTAND hit_sheet rifle=7 shotgun=6x5 sniper=48 source=WeaponDefs.BASES crop_native_pixels=true")


## Тот же стенд R1: штатная камера, одинаковые урон, зерно и возраст реакции.
func _r1b_hit_shots(center: Vector2) -> void:
	if OS.get_cmdline_user_args().has("--r1b-audio"):
		await _r1b_record_audio(center)
		return
	var stage_name := "before" if OS.get_cmdline_user_args().has("--r1b-before") else "after"
	var images: Array[Image] = []
	for base: int in [0, 6, 4, 5, 1, 7, 2, 3]:
		gore.count = 0
		effects._n = 0
		horde.count = 0
		gore._hit_rng.seed = 918 + base
		seed(81073)
		var e := horde.spawn(center + Vector2(38, 0), Horde.Kind.SHAMBLER)
		horde.hp[e] = 100.0
		horde.max_hp[e] = 100.0
		var stats: Dictionary = WeaponDefs.BASES[base]
		for pellet in int(stats["proj"]):
			horde.damage(e, float(stats["damage"]), Vector2.RIGHT, float(stats["knock"]), WeaponDefs.Ammo.STANDARD, false, Vector2.INF, base == WeaponDefs.Base.LAUNCHER)
		gore._physics_process(1.0 / 60.0)
		effects._physics_process(0.06)
		horde._render()
		floor_decals._process(0.06)
		await RenderingServer.frame_post_draw
		var frame := get_viewport().get_texture().get_image()
		frame.save_png("res://design/tasks/reports/r1b_hit_%d_%s.png" % [base, stage_name])
		var screen_at := get_viewport().get_canvas_transform() * center
		var crop := Rect2i(Vector2i(screen_at) - Vector2i(60, 110), Vector2i(390, 220))
		images.append(frame.get_region(crop))
		if base == WeaponDefs.Base.SNIPER:
			horde.flash[e] = 0.0
			horde._render()
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/r1b_wounded_%s.png" % stage_name)
		if base == WeaponDefs.Base.SHOTGUN:
			# Новый одиночный удар; шаги ровно 0/50/100/200/400 мс.
			gore.count = 0
			effects._n = 0
			for pellet in 6:
				gore.on_enemy_hit(center + Vector2(38, 0), Vector2.RIGHT, 0, 5.0, 40.0, 9001)
			gore._flush_hits(0.1)
			var previous := 0.0
			for age: float in [0.0, 0.05, 0.1, 0.2, 0.4]:
				gore._physics_process(age - previous)
				effects._physics_process(age - previous)
				floor_decals._process(age - previous)
				horde.flash[e] = maxf(0.0, 1.0 - age * 10.0)
				horde._render()
				previous = age
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/r1b_shotgun_%d_%s.png" % [roundi(age * 1000), stage_name])
	var sheet := Image.create(1560, 440, false, Image.FORMAT_RGB8)
	for j in images.size():
		sheet.blit_rect(images[j], Rect2i(0, 0, 390, 220), Vector2i(j % 4 * 390, j / 4 * 220))
	assert(sheet.save_png("res://design/tasks/reports/r1b_hits_%s.png" % stage_name) == OK)
	print("R1BSTAND hits order=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=60ms zoom=3 native_pixels=true stage=", stage_name)


## Только пути фикстур в памяти: штатные проверки и пользовательское сохранение сохранены.
func _r1b_test_paths() -> void:
	DirAccess.make_dir_recursive_absolute("res://design/tasks/reports/R1b_test")
	for entry: Array in [["--q1-test", "res://scripts/meta_test.gd"], ["--campaign-test", "res://scripts/campaign/campaign_test.gd"]]:
		if OS.get_cmdline_user_args().has(entry[0]):
			var script := load(entry[1]) as GDScript
			script.source_code = script.source_code.replace("res://tmp", "res://design/tasks/reports/R1b_test").replace("reports/q1_", "reports/r1b_q1_")
			assert(script.reload() == OK)


## Выход Master: каждый ствол отдельно и очередью, затем частые попадания по 500 целям.
func _r1b_record_audio(center: Vector2) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), true)
	for loop in sfx._loops:
		loop.stop()
	sfx._heart.stop()
	sfx._rng.seed = 81073
	var record := AudioEffectRecord.new()
	record.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, record)
	var guns: Array[String] = ["rifle", "smg", "pistol", "revolver", "shotgun", "sniper", "rail", "launcher"]
	var bases: Array[int] = [0, 6, 4, 5, 1, 7, 2, 3]
	var started := Time.get_ticks_msec()
	var timeline := "# R1b — запись Master\n\nПорядок: одиночный выстрел, затем три выстрела; попадание через 40 мс.\n\n"
	record.set_recording_active(true)
	for j in guns.size():
		var stats: Dictionary = WeaponDefs.BASES[bases[j]]
		timeline += "%s: %.3f s\n\n" % [guns[j], (Time.get_ticks_msec() - started) * 0.001]
		await get_tree().create_timer(0.2).timeout
		for shot in 4:
			sfx.play("weapons/" + guns[j] + "/shot", Vector2.INF, 0.0, 0.015)
			await get_tree().create_timer(0.04).timeout
			for pellet in int(stats["proj"]):
				sfx.queue_impact(center + Vector2(38, 0), Vector2.RIGHT, 0, stats["damage"], stats["knock"], 9000 + j)
			await get_tree().create_timer(0.85 if shot == 0 else 0.18).timeout
		await get_tree().create_timer(0.7).timeout
	var before := int(sfx.played_by_id.get("gore/hit", 0))
	var shots_before := int(sfx.played_by_id.get("weapons/smg/shot", 0))
	timeline += "500 целей, 600 выстрелов ППШ за 10 с: %.3f s\n" % ((Time.get_ticks_msec() - started) * 0.001)
	var stress_started := Time.get_ticks_usec()
	var next_shot := 0
	var peak_hits := 0
	while (Time.get_ticks_usec() - stress_started) * 0.000001 < 10.0:
		var elapsed := (Time.get_ticks_usec() - stress_started) * 0.000001
		while next_shot < 600 and next_shot / 60.0 <= elapsed:
			sfx.play("weapons/smg/shot", Vector2.INF, 0.0, 0.015)
			next_shot += 1
		for id in 500:
			sfx.queue_impact(center + Vector2(20 + id % 100, id / 100), Vector2.RIGHT, 0, 4.0, 18.0, id)
		peak_hits = maxi(peak_hits, sfx.hits_s)
		await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	record.set_recording_active(false)
	var recording := record.get_recording()
	assert(recording.save_to_wav("res://design/tasks/reports/r1b_hit_sounds.wav") == OK)
	var file := FileAccess.open("res://design/tasks/reports/R1b_sound_timeline.md", FileAccess.WRITE)
	file.store_string(timeline)
	var hits := int(sfx.played_by_id.get("gore/hit", 0)) - before
	var shots := int(sfx.played_by_id.get("weapons/smg/shot", 0)) - shots_before
	print("R1BAUDIO master=true seconds=%.3f stress_targets=500 hit_voices=%d shot_requested=%d shot_accepted=%d max_hits_s=%d" % [recording.get_length(), hits, next_shot, shots, peak_hits])
	assert(shots == 600 and hits <= 121 and peak_hits <= 12)
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)


## C1 отключает commit для старых тестов. Явный --campaign-op даёт им только снимок боя.
func _read_mission() -> bool:
	if endless:
		mission_config = {}
		return true
	if gun_lab_range:
		mission_config = {}
		return true
	mission_config = Campaign.pending()
	var forced := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--campaign-op="):
			forced = arg.trim_prefix("--campaign-op=")
	if forced.is_empty():
		return true
	if mission_config.is_empty():
		var offers := Campaign.offers()
		if forced == "first":
			forced = offers[0]["id"]
		elif forced in ["clearance", "extract", "nest"]:
			for op: Dictionary in offers:
				if op["type"] == forced:
					forced = op["id"]
					break
		if Campaign.enabled():
			mission_config = Campaign.start_operation(forced)
		else:
			for op: Dictionary in offers:
				if op["id"] == forced:
					mission_config = CampaignRules.mission(Campaign.world(), op, 0)
	if mission_config.is_empty():
		push_error("Campaign: операция недоступна: " + forced)
		return false
	# Отладочные переопределения меняют только локальную копию, не сохранённый pending.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--threat="):
			var value := arg.trim_prefix("--threat=")
			if not value.is_valid_int() or int(value) < 1 or int(value) > 5:
				push_error("Campaign: --threat ожидает 1..5")
				return false
			mission_config["threat"] = int(value)
		elif arg.begins_with("--mods="):
			var mods: Array[String] = []
			for value: String in arg.trim_prefix("--mods=").split(",", false):
				if not CampaignCatalog.MODIFIERS.has(value) or mods.has(value):
					push_error("Campaign: неизвестный или повторный модификатор: " + value)
					return false
				mods.append(value)
			if mods.size() > 2 or not CampaignCatalog.compatible(mods):
				push_error("Campaign: несовместимые модификаторы (максимум два)")
				return false
			mission_config["modifiers"] = mods
	seed(int(mission_config["seed"])) # Воспроизводимые сравнения явной CLI-операции.
	return true


func _apply_mission() -> void:
	var profile := Spawner.combat_profile(mission_config)
	spawner.set_profile(profile)
	if profile.is_empty():
		return
	hazards.acid_life_mul = float(profile["acid_life_mul"])
	boss.set_mission_profile(float(profile["boss_hp_mul"]), float(profile["boss_shed"]))
	blood_alarm.set_extra_alarm(profile["extra_alarm"])
	mission_modifiers = mission_config["modifiers"].duplicate()
	var names: Array[String] = []
	for id: String in mission_modifiers:
		names.append(CampaignCatalog.MODIFIER_INFO[id]["name"])
	mission_mod_names = " · ".join(names) if not names.is_empty() else "Штатный периметр"
	mission_title = "%s · %s" % [mission_config["name"], ["I", "II", "III", "IV", "V"][int(mission_config["threat"]) - 1]]
	mission_region = "%s / УГРОЗА %s" % [mission_config["region_name"], ["I", "II", "III", "IV", "V"][int(mission_config["threat"]) - 1]]
	mission_banner_t = 3.6 # крупная плашка операции (HUD сворачивает её в компактную строку)
	print("MISSION threat=%d modifiers=%s seed=%d profile=%s commit=%s persist=%s" % [mission_config["threat"], mission_modifiers, mission_config["seed"], profile, Campaign.enabled(), Meta.persist])


func _mission_screenshot() -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().create_timer(0.5).timeout
	var debug_before: bool = $HUD/Hud.show_debug
	$HUD/Hud.show_debug = false
	$HUD/Hud.queue_redraw()
	await get_tree().process_frame
	await _boss_screenshot("operation")
	await get_tree().create_timer(2.2).timeout
	await _boss_screenshot("hud")
	$HUD/Hud.show_debug = debug_before


## Проверяем боевую границу и настоящие переходы тревоги, не только коэффициенты.
func _mission_checks() -> void:
	assert(not Meta.persist)
	var probe := Spawner.new()
	probe.set_profile({})
	for row: Array in Spawner.CURVE:
		probe.time = float(row[0])
		assert(probe.current_row() == row)
	var normal := mission_config.duplicate(true)
	normal["threat"] = 1
	normal["modifiers"] = []
	probe.set_profile(Spawner.combat_profile(normal))
	for row: Array in Spawner.CURVE:
		probe.time = float(row[0])
		assert(probe.current_row() == row)
	print("C2TEST free_and_threat1_curve=true")
	var hard := normal.duplicate(true)
	hard["threat"] = 5
	hard["modifiers"] = ["runner_surge", "elite_hunt"]
	var profile := Spawner.combat_profile(hard)
	probe.set_profile(profile)
	for row: Array in Spawner.CURVE:
		probe.time = float(row[0])
		assert(int(probe.current_row()[2]) == int(row[2]))
		assert(float(probe.current_row()[1]) > float(row[1]))
		assert(float(probe.current_row()[3][1]) > float(row[3][1]))
	probe.horde = horde
	probe.player = player
	probe.time = 180.0
	probe._physics_process(0.0)
	assert(probe.elites_spawned == 3 and probe._next_hunt == 270.0)
	probe._physics_process(0.0)
	assert(probe.elites_spawned == 3)
	probe.time = 0.0
	while horde.count < int(probe.current_row()[2]):
		horde.spawn(player.position + Vector2(180, 0))
	var at_cap := horde.count
	probe.spawn_elites(4)
	probe._physics_process(1.0)
	assert(horde.count == at_cap)
	print("C2TEST threat5_composition_caps_hunt_once=true")
	hard["modifiers"] = ["acid_rain"]
	probe.set_profile(Spawner.combat_profile(hard))
	probe.time = 120.0
	assert(float(probe.current_row()[3][3]) > 0.0)
	var acid := Hazards.new()
	acid.acid_life_mul = float(probe.profile["acid_life_mul"])
	acid.acid_pool(Vector2.ZERO)
	assert(is_equal_approx(acid._pool_life[0], 5.25) and acid._pool_dps[0] == 5.0)
	acid.free()
	print("C2TEST acid_early_spitters_life_only=true")
	var target := Boss.new()
	target.arena = ARENA
	target.set_mission_profile(1.25, 0.35)
	target.start(ARENA.get_center())
	assert(target.hp == 30000.0)
	target.take_damage(20000.0, Vector2.RIGHT, target.position)
	assert(target.phase == 1 and target.hp == 15000.0)
	target.take_damage(7000.0, Vector2.RIGHT, target.position)
	assert(target.phase == 2)
	target.free()
	print("C2TEST hardened_hp_and_later_shedding=true")
	var alarm := BloodAlarm.new()
	alarm.spawner = probe
	alarm.player = player
	alarm.overlay = alarm_overlay
	alarm.tint = alarm_tint
	alarm.set_extra_alarm(true)
	var drops: Array[int] = [0]
	alarm.container_dropped.connect(func(_pos: Vector2) -> void: drops[0] += 1)
	for start: float in [240.0, 420.0]:
		alarm.time = start
		alarm._physics_process(0.016)
		assert(alarm.phase == BloodAlarm.Phase.WARN)
		alarm.time = start + BloodAlarm.WARN_TIME
		alarm._physics_process(0.016)
		assert(alarm.is_active() and probe.alarm and alarm.reward_mult() == 2.0)
		alarm.time = start + BloodAlarm.WARN_TIME + BloodAlarm.DURATION
		alarm._physics_process(0.016)
		assert(not probe.alarm and alarm.reward_mult() == 1.0)
	assert(drops[0] == 2)
	alarm.set_extra_alarm(true)
	alarm.time = 415.0
	alarm._physics_process(0.016)
	assert(alarm.phase == BloodAlarm.Phase.IDLE and alarm._event == 1)
	alarm.free()
	probe.free()
	print("C2TEST two_alarms_two_containers_skip_to_future=true")
	var stats := _result_stats(true)
	assert(stats["outcome"] == "victory" and stats["run_id"] == mission_config["run_id"] and stats["reward"] == mission_config["reward"])
	assert(_result_stats(false)["outcome"] == "defeat")
	var before := Meta.save_calls
	var report := Campaign.complete_operation(stats)
	assert(not report.is_empty() and Meta.save_calls == before + 1)
	assert(Campaign.complete_operation(stats) == report and Meta.save_calls == before + 1)
	print("C2TEST stats_transaction_once=true")
	var cache_checked := false
	for seed_value in 30:
		Campaign.new_campaign(seed_value)
		for op: Dictionary in Campaign.offers():
			if not op["modifiers"].has("resource_cache"):
				continue
			mission_config = Campaign.start_operation(op["id"])
			stats = _result_stats(true)
			stats["dna_total"] = 100
			var without_cache := mission_config.duplicate(true)
			without_cache["modifiers"].erase("resource_cache")
			assert(Spawner.combat_profile(without_cache) == Spawner.combat_profile(mission_config))
			report = Campaign.complete_operation(stats)
			assert(int(report["stats"]["dna_total"]) == floori(100.0 * float(mission_config["reward"]["dna_mul"])))
			cache_checked = true
			break
		if cache_checked:
			break
	assert(cache_checked)
	print("C2TEST resource_cache_rewards_only=true")
	print("C2TEST ok=true")
	Meta.finish_test()


## Предупреждение приходит до пика; после него остаётся обычный отдых директора.
func _endless_step() -> void:
	var storm := floori((time + 5.0) / Spawner.STORM_PERIOD)
	if storm > _endless_notice:
		_endless_notice = storm
		_announce("ШТОРМ ЧЕРЕЗ 5 С", preload("res://scripts/ui/zera_style.gd").DANGER)
	for i in Meta.ENDLESS_MILESTONES.size():
		if time >= Meta.ENDLESS_MILESTONES[i] and _endless_milestone <= i:
			_endless_milestone = i + 1
			var label := "ТРОФЕЙ ВЫЖИВАНИЯ" if endless_best_time < Meta.ENDLESS_MILESTONES[i] else "ВЫЖИВАНИЕ"
			_announce("%d МИН · %s" % [Meta.ENDLESS_MILESTONES[i] / 60, label], preload("res://scripts/ui/zera_style.gd").BETTER)


var _endless_checks := 0
var _endless_failed := 0


func _endless_check(label: String, ok: bool) -> void:
	_endless_checks += 1
	if not ok:
		_endless_failed += 1
		print("ENDLESSTEST FAIL ", label)


func _run_endless_test() -> void:
	set_physics_process(false)
	spawner.enabled = false
	player.god_mode = true
	player.set_physics_process(false)
	weapons.set_physics_process(false)
	var original := Meta.to_dict()
	var original_path := Meta.save_path
	Meta.endless_records.clear()
	for map: String in Meta.ENDLESS_MAPS:
		for kind: String in ClassTree.CLASSES:
			var first := Meta.record_endless(map, kind, 900.5, 100)
			_endless_check("first records " + map + kind, first["time"] and first["kills"] and first["trophies"] == [15])
			var worse := Meta.record_endless(map, kind, 899.0, 99)
			_endless_check("worse kept", not worse["time"] and not worse["kills"] and worse["trophies"].is_empty())
			var kill_only := Meta.record_endless(map, kind, 850.0, 101)
			var time_only := Meta.record_endless(map, kind, 1800.0, 90)
			_endless_check("independent records", kill_only["kills"] and not kill_only["time"] and time_only["time"] and not time_only["kills"])
			_endless_check("milestones once", time_only["trophies"] == [20, 30] and Meta.record_endless(map, kind, 1800.0, 101)["trophies"].is_empty())
	_endless_check("nine isolated keys", Meta.endless_records.size() == 9)
	var saved := Meta.to_dict()
	_endless_check("JSON roundtrip", Meta.from_dict(JSON.parse_string(JSON.stringify(saved))) and Meta.to_dict() == saved)
	var corrupt := {"quarantine_checkpoint:assault": {"time": -1, "kills": 3}, "old_town:engineer": {"time": "900", "kills": 1}, "unknown:assault": {"time": 900, "kills": 500}, "open_perimeter:gunner": {"time": 123, "kills": 456}}
	_endless_check("bad records isolated", Meta.clean_endless(corrupt) == {"open_perimeter:gunner": {"time": 123, "kills": 456}})
	_endless_check("invalid record rejected", Meta.record_endless("unknown", "assault", 900.0, 100).is_empty() and Meta.record_endless("old_town", "engineer", NAN, 100).is_empty())
	for version in range(1, Meta.SAVE_VERSION):
		var legacy := original.duplicate(true)
		legacy["version"] = version
		legacy.erase("endless_records")
		_endless_check("migration v%d" % version, Meta.from_dict(legacy) and Meta.endless_records.is_empty() and Meta.dna == int(legacy["dna"]) and Meta.owned == PackedStringArray(legacy["owned"]) and Meta.campaign == legacy["campaign"])
	var v7 := original.duplicate(true)
	v7["version"] = 7
	v7["class_id"] = "engineer"
	v7["dna_earned"] = Meta.dna_for_level(3)
	var gunner_node: String = ClassTree.catalog("gunner").keys()[0]
	v7["class_trees"]["gunner"] = {gunner_node: true}
	_endless_check("v7 class and inactive tree preserved", Meta.from_dict(v7) and Meta.class_id == "engineer" and Meta.class_trees.size() == 3 and Meta.class_trees["gunner"].get(gunner_node) == true)
	Meta.from_dict(saved)
	Meta.persist = true
	Meta.save_path = "user://endless_records_test.json"
	Meta.save()
	var wrote := Meta.last_save_ok
	Meta.endless_records.clear()
	_endless_check("disk restart records", wrote and Meta.load_save() and Meta.endless_records == saved["endless_records"])
	DirAccess.remove_absolute(Meta.save_path)
	Meta.persist = false
	Meta.save_path = original_path
	for minute in [0, 1, 10, 15, 20, 30, 60]:
		var reward := Meta.endless_rewards(minute * 60.0)
		_endless_check("reward bounded %d" % minute, int(reward["dna_total"]) == minute * 4 and int(reward["military_crates"]) == 0 and int(reward["crates"]) <= 3 and float(reward["dna_mult"]) == 1.0)
	var stats := {"endless": true, "map_id": "old_town", "class_id": "engineer", "time": 1200.0, "kills": 200, "dna_total": 999999, "crates": 999, "military_crates": 99}
	var bank := Meta.dna
	var runs_before := Meta.runs
	var campaign_before := Meta.campaign.duplicate(true)
	Meta.add_run(stats)
	Meta.add_run(stats)
	_endless_check("single credit ignores loot", Meta.dna == bank + 80 and Meta.runs == runs_before + 1 and stats["crates"] == 2 and stats["military_crates"] == 0)
	_endless_check("campaign untouched", Meta.campaign == campaign_before)
	for at in [480.0, 540.0, 600.0, 720.0, 900.0, 1200.0, 1500.0, 1800.0, 3600.0]:
		spawner.time = at
		var row := spawner.current_row()
		_endless_check("cap and continuous budget %.0f" % at, int(row[2]) == 500 and float(row[1]) >= Spawner.ENDLESS_RATE)
	_endless_check("uncapped growth", Spawner.endless_rate(3621.0) > Spawner.endless_rate(1821.0) and Spawner.endless_rate(1821.0) > Spawner.endless_rate(621.0))
	_endless_check("storm exact bounds", not Spawner.storm_active(299.9) and Spawner.storm_active(300.0) and Spawner.storm_active(319.9) and not Spawner.storm_active(320.0))
	time = 1221.0
	_boss_timeline()
	_endless_check("no scheduled boss", not _boss_spawned and not boss.is_alive() and next_event()["name"] == "ШТОРМ")
	_endless_check("activities beyond finale", not activities.priority_event())
	activities.schedule.clear()
	activities._next = 0
	activities.enabled = true
	activities._physics_process(0.016)
	_endless_check("bounded future activity", activities.schedule.size() == 1 and float(activities.schedule[0]["time"]) > time)
	var d := HordeDirector.new()
	d.setup(horde, player, 81073, _map_id)
	d.endless = true
	var early := 0
	var late := 0
	for id in 1000:
		horde._next_uid = id
		if d._armored_kind(Horde.Kind.SHAMBLER, 719.0) >= Horde.Kind.INFANTRY: early += 1
		if d._armored_kind(Horde.Kind.SHAMBLER, 1500.0) >= Horde.Kind.INFANTRY: late += 1
	_endless_check("military rises at 12 minutes", late > early * 3)
	spawner.director = d
	time = 1245.0
	_endless_check("director after finale", d.advance(time, 0.016, spawner.current_row()[3], false) > 0.0 and not d.suspended)
	spawner.enabled = true
	spawner.time = 720.0
	spawner._next_elite = 720.0
	var elites_before := spawner.elites_spawned
	spawner._physics_process(0.016)
	_endless_check("elite pack from 12 minutes", spawner.elites_spawned == elites_before + 3 and is_equal_approx(spawner._next_elite, 744.0))
	spawner.time = 1800.0
	spawner._next_elite = 1800.0
	elites_before = spawner.elites_spawned
	spawner._physics_process(0.016)
	_endless_check("late elite pack bounded", spawner.elites_spawned == elites_before + 6 and is_equal_approx(spawner._next_elite, 1808.0) and horde.count <= 500)
	spawner.time = 120.0
	_endless_check("gentle intro same type opening", is_equal_approx(spawner.current_rate(), 4.0 * Spawner.ENDLESS_INTRO) and spawner.current_row()[3] == Spawner.CURVE[2][3])
	Meta.from_dict(original)
	print("ENDLESSTEST checks=%d failed=%d military_early=%d military_late=%d" % [_endless_checks, _endless_failed, early, late])
	Meta.finish_test(0 if _endless_failed == 0 else 1)


func _run_endless_shots() -> void:
	if DisplayServer.get_name() == "headless":
		Meta.finish_test(1)
		return
	Meta.settings["fullscreen"] = false
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	get_window().size = Vector2i(1280, 720)
	player.god_mode = true
	player.autopilot = true
	gems.collected.disconnect(progression.add_xp)
	_boss_starter_loadout()
	spawner.director = _horde_director
	spawner.director.setup(horde, player, _layout_seed, _map_id)
	_director_pending = false
	trader_visit = TRADER_TIMES.size()
	Meta.record_endless(_map_id, _endless_class, 1200.0, 4000)
	endless_best_time = 1200
	for minute in [15, 25]:
		time = minute * 60.0
		horde.minutes = minute
		spawner.time = time
		# Штатный спавн и движение после перемотки; это стенд HUD, не замер баланса.
		await get_tree().create_timer(18.0).timeout
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/g8_%dmin.png" % minute)
		print("ENDLESSSHOT minute=%d alive=%d" % [minute, horde.count])
	Meta.record_endless(_map_id, _endless_class, 1200.0, 4000)
	time = 1532.0
	kills = 6784
	_open_results(false)
	await get_tree().create_timer(1.8, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/g8_record.png")
	get_tree().set_meta("endless_capture", true)
	_return_to_base()


func _run_endless_launch_test() -> void:
	player.god_mode = true
	spawner.enabled = false
	var expected: Dictionary = get_tree().get_meta("endless_expected")
	BaseScreen._check("endless launch map/class/mode", endless and spawner.endless and _map_id == expected["map_id"] and _endless_class == expected["class_id"] and mission_config.is_empty())
	if int(get_tree().get_meta("endless_launch_test")) == 1:
		get_tree().set_meta("endless_launch_test", 2)
		_restart_run()
	else:
		get_tree().set_meta("endless_launch_test", 3)
		_return_to_base()


func _sim_seed() -> void:
	# До орды с priority=-10, а не только до корня с priority=0.
	seed(_layout_seed + _sim_tick * 104729)
	_sim_tick += 1


func _physics_process(delta: float) -> void:
	if gun_lab_range:
		return
	if game_over:
		return
	time += delta
	if _director_pending and not first_run and time >= 60.0:
		# Вводная минута проходит тем же путём, что и контроль.
		_director_pending = false
		spawner.director = _horde_director
		spawner.director.setup(horde, player, int(mission_config.get("seed", _layout_seed)), _map_id)
	_run_peak = maxi(_run_peak, horde.count)
	if _audio_lowhp:
		player.hp = player.max_hp * 0.2
	if _audio_test and time < 36.0 and horde.count < 300:
		for k in mini(15, 300 - horde.count):
			horde.spawn(player.position + Vector2.from_angle(randf() * TAU) * randf_range(100.0, 330.0), randi() % 4, randf() < 0.025)
	if not first_run and not _bench and not _ui_test and not _s3_test and not _weapons_test:
		_boss_timeline()
	if _boss_test and boss.is_alive():
		# Чередуем сближение и отход; автопилот не стоит в упор весь бой.
		var away := (player.global_position - boss.global_position).normalized()
		var distance := 160.0 + 100.0 * sin((time - _boss_started) * 0.22)
		if boss is BossHeart:
			distance = maxf(distance, boss.body_radius() + 60.0)
		player.auto_target = boss.global_position + away * distance + away.orthogonal() * 70.0
		if boss is BossHeart:
			# Бот учитывает видимую кромку арены, как обычную границу карты.
			var safe: Rect2 = boss.cage().grow(-35.0)
			player.auto_target = player.auto_target.clamp(safe.position, safe.end)
	if _sim:
		_sim_measure(delta)
		player.auto_target = pickups.nearest(player.global_position, 400.0)
		if activities != null and activities.is_active():
			player.auto_target = activities.bot_target(delta)
		if player.auto_target == Vector2.INF:
			player.auto_target = gems.nearest(player.global_position, 260.0)
		_sim_grenade()
		_sim_peak = maxi(_sim_peak, horde.count)
		if player.adrenaline and weapons.any_reloading():
			player.try_dash() # «Адреналин» используется как в живой игре: рывок, когда стволы на перезарядке
	if _mortal:
		_mortal_step()
	horde.minutes = time / 60.0
	spawner.time = time
	if spawner.director:
		spawner.director.sample(time, kills)
		# Узел кампании — не босс для режиссёра: его давление ложится поверх цикла (ZAI3, R8).
		spawner.director_exclusive = (activities != null and activities.phase == Activities.Phase.ACTIVE) or blood_alarm.phase in [BloodAlarm.Phase.WARN, BloodAlarm.Phase.ACTIVE] or (boss.is_alive() and not boss is CampaignNode) or (Spawner.storm_pending(time) if endless else ((time >= 285.0 and time < 315.0) or time >= 535.0))
		if _sim and time >= _director_log_at:
			_director_log_at = time + 5.0
			var d := spawner.director
			var record := {"time": time, "phase": HordeDirector.PHASES[d.phase], "pattern": HordeDirector.NAMES[d.pattern], "intensity": d.intensity, "nearby": d.nearby, "alive": horde.count, "damage": player.damage_taken, "planned": d.planned, "curve": spawner.curve_budget, "issued": spawner.total_spawned, "exclusive": d.suspended}
			_director_trace.append(record)
			if endless and _director_trace.size() > 360:
				_director_trace.pop_front()
			print("DIRECTOR ", JSON.stringify(record))
		if _sim and time >= 300.0 and not _director_fight_shot and (OS.get_cmdline_user_args().has("--director-capture-live") or OS.get_cmdline_user_args().has("--map-capture-live")):
			_director_fight_shot = true
			_director_live_shot.call_deferred()
	blood_alarm.time = time
	Music.combat_step(delta, time, spawner.director.phase if spawner.director else HordeDirector.Phase.SCOUT,
		blood_alarm.phase in [BloodAlarm.Phase.WARN, BloodAlarm.Phase.ACTIVE],
		activities != null and activities.phase == Activities.Phase.ACTIVE,
		objective != null and objective.type == "extract" and objective.picked and not objective.done,
		_boss_warned or boss.is_alive(), _horde_director.nearby, player.hp / maxf(player.max_hp, 1.0))
	hazards.minutes = time / 60.0
	boss.minutes = time / 60.0
	if endless:
		_endless_step()
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
			if mission_config.is_empty():
				horde.spawn_group(player.global_position, mini(15, _bench_target - horde.count))
			else:
				spawner.fill_benchmark(mini(15, _bench_target - horde.count))
	if _gore_stress and horde.count > 0:
		for k in 2:
			var i := randi() % horde.count
			var dir := (horde.pos[i] - player.global_position).normalized()
			horde.death_override = randi() % Gore.Death.size()
			horde.damage(i, 3.0 if randf() < 0.5 else 9999.0, dir, 0.0, WeaponDefs.Ammo.STANDARD, false, horde.pos[i] + dir.orthogonal() * 3.0)
		horde.death_override = -1


func _process(delta: float) -> void:
	if _sim:
		_sim_report_frames += 1
	_director_sound()
	if blood_alarm.phase != _dispatch_alarm_phase:
		if blood_alarm.phase == BloodAlarm.Phase.WARN or (blood_alarm.phase == BloodAlarm.Phase.ACTIVE and _dispatch_alarm_phase != BloodAlarm.Phase.WARN):
			_radio("alarm", Color(1.0, 0.45, 0.35), true)
		_dispatch_alarm_phase = blood_alarm.phase
	mission_banner_t = maxf(0.0, mission_banner_t - delta)
	if not _dispatch_started and mission_banner_t <= 0.0:
		_dispatch_started = true
		_radio("start", Color(0.75, 0.85, 0.8))
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
	_combo_step(delta)
	announce_t = maxf(announce_t - delta, 0.0)
	radio_t = maxf(radio_t - delta, 0.0)
	multikill_t = maxf(multikill_t - delta, 0.0)
	screen_blood.low_hp = 0.0 # мягкая виньетка теперь рисуется под HUD


## Бот проверки не получает здоровья/урона: только выбирает путь и обычный рывок.
func _mortal_step() -> void:
	var at := player.global_position
	var escape := Vector2.ZERO
	if horde.count > 0: # До первого тика орды пространственная сетка ещё не построена.
		for i in horde.query_radius(at, 95.0):
			var offset := at - horde.pos[i]
			if horde.dead[i] == 0:
				escape += offset.normalized() * maxf(0.0, 95.0 - offset.length())
	if escape.length_squared() > 1.0:
		player.auto_target = at + escape.normalized() * 100.0
		if escape.length() > 100.0:
			player.try_dash()
	for i in hazards._pool_count:
		if at.distance_to(hazards._pool_pos[i]) < hazards._pool_radius[i] + 20.0:
			player.auto_target = at + (at - hazards._pool_pos[i]).normalized() * 90.0
	if boss.is_alive():
		var away := (at - boss.global_position).normalized()
		if escape.length_squared() <= 1.0:
			player.auto_target = boss.global_position + away * 220.0 + away.orthogonal() * 100.0
		if boss._state == Boss.State.TELEGRAPH or boss._state == Boss.State.CHARGE:
			var line := (boss._charge_target - boss._charge_from).normalized()
			var side := line.orthogonal()
			if (at - boss._charge_from).dot(side) < 0.0:
				side = -side
			player.auto_target = at + side * 140.0
			if boss._state == Boss.State.CHARGE:
				player.try_dash()
	if player.auto_target != Vector2.INF:
		player.auto_target = player.auto_target.clamp(ARENA.position + Vector2.ONE * 100.0, ARENA.end - Vector2.ONE * 100.0)
		# Тестовый бот обходит технику тем же путём, что и тела орды.
		var goal := player.auto_target
		if obstacles != null and not obstacles.body_clear(at, goal, Player.RADIUS):
			if time >= _mortal_path_at or goal.distance_squared_to(_mortal_path_goal) > 4096.0:
				_mortal_path = obstacles.body_path(at, goal, Player.RADIUS)
				_mortal_path_goal = goal
				_mortal_path_at = time + 1.0
			while not _mortal_path.is_empty() and at.distance_squared_to(_mortal_path[0]) < 64.0:
				_mortal_path.remove_at(0)
			if not _mortal_path.is_empty():
				player.auto_target = _mortal_path[0]


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_F9:
		gun_lab_controller.panel.toggle()
		get_viewport().set_input_as_handled()
		return
	if key.keycode != KEY_F11 and not $HUD/Hud.show_debug:
		return # отладочные клавиши F1–F10 только при включённой отладке (F3)
	match key.keycode:
		KEY_F1:
			for i in 10:
				horde.spawn_group(player.global_position, 10)
		KEY_F2:
			player.god_mode = not player.god_mode
		KEY_F4:
			time += 60.0
		KEY_F11:
			Meta.set_setting("fullscreen", not Meta.settings["fullscreen"])
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
	var threshold := _combo_add()
	if threshold > 0:
		if _combo_pending_threshold == 0:
			_play_combo_reward.call_deferred()
		_combo_pending_threshold = threshold
	if time - _burst_t < MULTIKILL_WINDOW:
		_burst_count += 1
		if _burst_count in [4, 6, 10, 15]:
			multikill_text = "МУЛЬТИКИЛЛ ×%d" % _burst_count
			multikill_t = 1.6
	else:
		_burst_count = 1
	_burst_t = time
	if pos.distance_to(player.global_position) < DIRT_RADIUS:
		player.add_dirt(1.0)


func _play_combo_reward() -> void:
	# Одновременный мультикилл звучит один раз, на самом высоком достигнутом пороге.
	var threshold := _combo_pending_threshold
	_combo_pending_threshold = 0
	if threshold > 0:
		sfx.play("ui/combo", Vector2.INF, -3.0, 0.0, 0.85 + 0.05 * COMBO_THRESHOLDS.find(threshold))


## Скользящее окно: каждый убитый учитывается ровно шесть секунд.
func _combo_step(delta: float) -> void:
	_combo_clock += delta
	combo_reward_t = maxf(0.0, combo_reward_t - delta)
	while not _combo_times.is_empty() and _combo_times[0] <= _combo_clock - COMBO_WINDOW:
		_combo_times.remove_at(0)
	combo = _combo_times.size()
	_combo_timer = maxf(0.0, _combo_times[0] + COMBO_WINDOW - _combo_clock) if combo > 0 else 0.0
	if combo == 0:
		_combo_awarded = 0
		combo_title = ""


## Порог награждается один раз до полного затихания серии; дрожание счётчика звук не повторяет.
func _combo_add() -> int:
	_combo_step(0.0)
	_combo_times.append(_combo_clock)
	combo = _combo_times.size()
	best_combo = maxi(best_combo, combo)
	_combo_timer = _combo_times[0] + COMBO_WINDOW - _combo_clock
	if combo in COMBO_THRESHOLDS and combo > _combo_awarded:
		_combo_awarded = combo
		combo_reward_t = 0.6
		combo_title = COMBO_TITLES.get(combo, "")
		return combo
	return 0


## Дроп по типу врага (таблица Horde.KINDS), тревога удваивает опыт и кредиты.
func _on_enemy_died(pos: Vector2, kind: int, is_elite: bool) -> void:
	if _sim:
		# Порядок дропа по типу и номеру смерти; эффекты и директор его не сдвигают.
		var stream := kind + (4 if is_elite else 0) if kind < 4 else kind + 4 + (3 if is_elite else 0)
		_sim_deaths[stream] += 1
		_sim_drop_rng.seed = _layout_seed + stream * 104729 + _sim_deaths[stream] * 7919
	if obstacles:
		pos = obstacles.free_point(pos, 4.0)
	if is_elite:
		elites_killed += 1
	var mult := roundi(blood_alarm.reward_mult())
	var xp_before := gems.spawned_total
	var credits_before := credit_drops.spawned_total
	var def: Dictionary = Horde.KINDS[kind]
	if is_elite:
		gems.spawn(pos, Horde.ELITE_XP * mult)
		credit_drops.spawn(pos, Horde.ELITE_CREDITS * mult) # у элитки кредиты гарантированы
		if _drop_roll() < CRATE_CHANCE_ELITE:
			pickups.spawn(_scatter(pos), Pickups.Kind.CRATE)
		if _drop_roll() < PART_CHANCE_ELITE:
			pickups.spawn(_scatter(pos), Pickups.Kind.PART)
	else:
		gems.spawn(pos, int(def["xp"]) * mult)
		if _drop_roll() < float(def["credit_chance"]):
			credit_drops.spawn(pos, int(def["credits"]) * mult)
		if kind >= Horde.Kind.INFANTRY and _drop_roll() < 0.08:
			pickups.spawn(_scatter(pos), Pickups.Kind.AMMO)
	if _drop_roll() < (MEDKIT_CHANCE_ELITE if is_elite else MEDKIT_CHANCE):
		pickups.spawn(_scatter(pos), Pickups.Kind.MEDKIT)
	if mult > 1:
		_alarm_xp += gems.spawned_total - xp_before
		_alarm_credits += credit_drops.spawned_total - credits_before


func _scatter(p: Vector2) -> Vector2:
	return p + Vector2.from_angle(_drop_roll() * TAU) * _drop_roll() * DROP_SCATTER


func _drop_roll() -> float:
	return _sim_drop_rng.randf() if _sim else randf()


## Граната игрока приземлилась: взрыв без привязки к стволу, рвёт на гибы.
func _on_grenade_landed(at: Vector2) -> void:
	nades += 1
	weapons.explode(at, Player.GRENADE_DAMAGE, Player.GRENADE_RADIUS)


func _class_contact(amount: float) -> void:
	if player.class_id != "gunner" or player.class_active_t <= 0.0:
		player.take_damage(amount)
		return
	var source := Vector2.INF
	var nearest := INF
	for e in horde.query_radius(player.position, 25.0):
		var dist := player.position.distance_squared_to(horde.pos[e])
		if dist < nearest:
			nearest = dist
			source = horde.pos[e]
	player.take_damage(amount, source)


func _run_class_shots(finish := true) -> void:
	var profile := Meta.to_dict()
	var spawning := spawner.enabled
	spawner.enabled = false
	player.god_mode = true
	player.autopilot = false
	var shot_rng := RandomNumberGenerator.new()
	for kind: String in ClassTree.CLASSES:
		for e in horde.count: horde.dead[e] = 1
		horde._compact()
		shot_rng.seed = 81073
		for e in 70:
			var at := player.position + Vector2.from_angle(shot_rng.randf() * TAU) * shot_rng.randf_range(65, 180)
			horde.spawn(obstacles.free_point(at, 7.0), e % 4)
		Meta.select_class(kind)
		player.apply_bonuses(Meta.run_bonuses())
		weapons.bonuses = Meta.run_bonuses()
		player.grenade_cd = 0.0
		player._gren_t = -1.0
		player.throw_grenade()
		await get_tree().create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/t2_q_%s.png" % kind)
	Meta.from_dict(profile)
	player.apply_bonuses(Meta.run_bonuses())
	player._gren_t = -1.0
	weapons.bonuses = Meta.run_bonuses()
	spawner.enabled = spawning
	if finish: Meta.finish_test()


## Контейнер тревоги упал: он лежит до подбора (см. Pickups).
func _on_container_dropped(pos: Vector2) -> void:
	_radio("supply", Color(1.0, 0.82, 0.35))
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
		Pickups.Kind.AMMO:
			weapons.refill_all()
		Pickups.Kind.MEDKIT:
			player.hp = minf(player.hp + MEDKIT_HEAL, player.max_hp)
			for k in 8:
				effects.emit(pos, Vector2.from_angle(randf() * TAU) * randf_range(10.0, 50.0), randf_range(0.3, 0.6), Color(0.4, 1.0, 0.5), 1.5, 4.0)
		Pickups.Kind.CRATE:
			crates += 1
			_announce("ОРУЖЕЙНЫЙ ЯЩИК", Color(1.0, 0.75, 0.3))
		Pickups.Kind.PART:
			_open_loot("РЕДКАЯ ДЕТАЛЬ", "выбери одну из двух", 2, true, true)
		Pickups.Kind.ACTIVITY_MODULE:
			_open_loot("СНАБЖЕНИЕ", "", 2, false, false)
		Pickups.Kind.CONTAINER:
			crates += 1
			_open_loot("СБРОС СНАБЖЕНИЯ", "выбери модуль · +1 оружейный ящик", 3, false, false)
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
	if _sim:
		var card := _sim_card(true)
		card["rare"] = true
		progression.apply(card, _auto_slot(card), false)
		print("LOOT fixed=", card)
		return
	if _bench or _sim or _alarm or _weapons_test or _boss_test or _c6_test or _audio_test:
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
			progression.auto_link(card, i)
			return i
	return -2


## Симуляция: бросаем гранату, если в точке падения набралась кучка зомби.
func _sim_grenade() -> void:
	if horde.count == 0 or player.grenade_cd > 0.0 or player.is_dead:
		return
	if (player.class_id != "assault" and horde.query_radius(player.position, 150.0).size() >= 6) or horde.query_radius(player.grenade_target(), Player.GRENADE_RADIUS * 0.8).size() >= 6:
		player.throw_grenade()


func _on_credits_collected(value: int) -> void:
	progression.credits += value


# --- Level Up ---------------------------------------------------------------------------

func _on_level_ready() -> void:
	if game_over:
		return
	if level_up.visible or trader_ui.visible:
		return
	if _sim:
		while progression.pending > 0:
			var card := _sim_card()
			print("PICK fixed=", card)
			progression.apply(card, _auto_slot(card))
		return
	if _bench or _sim or _alarm or _weapons_test or _boss_test or _c6_test:
		# в бенчмарке и симуляции выбираем сами (случайно), без паузы
		while progression.pending > 0:
			var cards := progression.make_cards(time / 60.0)
			var card: Dictionary = cards.pick_random()
			var slot := _auto_slot(card)
			if slot == -2:
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
	if not _sim:
		trader.start_visit(index, time / 60.0)
	if index == 1:
		# затишье 9:00: дальних зомби тихо убираем, чтобы после лавки не выйти в стену мяса
		var removed := horde.despawn_far(player.global_position, CALM_RADIUS)
		if _sim:
			print("CALM %02d:%02d removed=%d left=%d" % [int(time) / 60, int(time) % 60, removed, horde.count - removed])
	if _bench or _sim or _alarm or _weapons_test or _boss_test or _c6_test:
		_auto_shop()
		return
	get_tree().paused = true
	trader_ui.open(trader, progression, weapons, time / 60.0)


func _on_trader_closed() -> void:
	_radio("trader", Color(1.0, 0.82, 0.35))
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
	if _sim:
		trader.visit = trader_visit - 1
		for i in int(Trader.VISITS[trader.visit]["slots"]):
			var card := _sim_card()
			var price := trader._card_price(card)
			if progression.credits < price:
				break
			progression.credits -= price
			progression.apply(card, _auto_slot(card), false)
			print("TRADER fixed=", card)
		return
	var bought: Array[String] = []
	var order := range(trader.offers.size())
	order.shuffle()
	for i: int in order:
		var card: Dictionary = trader.offers[i]["card"]
		var slot := _auto_slot(card)
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
	var vs := PixelArt.screen_size(get_viewport())
	var z := maxf(1.0, roundf(vs.y / 360.0)) * _zoom
	camera.zoom = Vector2(z, z)
	horde.spawn_ring = (vs / (2.0 * z)).length() + 30.0
	horde.far_distance = horde.spawn_ring * 1.6


func _dispatch_line(event: String) -> String:
	var count := int(_dispatch_counts.get(event, 0))
	_dispatch_counts[event] = count + 1
	var variants: Array = DISPATCH[event]
	return "Диспетчер: " + str(variants[posmod(Meta.runs + count, variants.size())])


## Крупное объявление: пороги серий, редкие события. Без тряски камеры — она у срочных предупреждений.
func _announce(text: String, color := Color(0.9, 0.15, 0.1)) -> void:
	announce_text = text
	announce_color = color
	announce_t = 1.4


## Реплика Диспетчера: стабильная строка под часами. Срочные (тревога, босс на подходе) ещё и трясут камеру.
func _radio(event: String, color := Color(0.75, 0.85, 0.8), urgent := false) -> void:
	radio_text = _dispatch_line(event)
	radio_color = color
	radio_t = RADIO_TIME
	if urgent:
		camera.shake(2.0)


func _on_splatter(pos: Vector2, strength: float) -> void:
	var d := pos.distance_to(player.global_position)
	if d < 70.0:
		var from := (pos - player.global_position).normalized()
		screen_blood.splash(strength * (1.0 - d / 70.0), from)
		player.add_dirt(3.0 * strength)


func _on_player_hurt(_amount: float) -> void:
	sfx.play("player/hurt", Vector2.INF, -1.0)
	camera.shake(3.0)
	effects.blood_hit(player.global_position, Vector2.from_angle(randf() * TAU), false)
	player.add_dirt(2.0)
	screen_blood.splash(0.2)


func _on_player_died() -> void:
	if game_over:
		return
	game_over = true
	spawner.enabled = false
	_radio("evac", Color(1.0, 0.45, 0.35))
	camera.shake(6.0)
	for i in 4:
		effects.blood_hit(player.global_position, Vector2.from_angle(randf() * TAU), true)
	await get_tree().create_timer(0.6, false).timeout
	_open_results(false)
	if _sim or _boss_test:
		print("MISSION_RESULT outcome=defeat time=%.2f kills=%d peak=%d level=%d damage=%.2f" % [time, kills, _run_peak, progression.level, player.damage_taken])
		if _sim:
			_sim_measure(0.0)
			print("SIM situations ", JSON.stringify(_sim_situations))
		Meta.finish_test()


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


## Единый порядок наград для парного SIM: стволы, уровни, модули, пассивки.
## Момент получения опыта и подбора остаётся результатом боя.
func _sim_card(modules_only := false) -> Dictionary:
	if not modules_only:
		for base: int in WeaponDefs.BASES:
			if weapons.slots.size() < WeaponDefs.MAX_SLOTS and not weapons.has_base(base):
				return {"type": "weapon", "id": base, "rare": false}
		var lowest := -1
		for i in weapons.slots.size():
			if weapons.slots[i].level < WeaponDefs.MAX_LEVEL and (lowest < 0 or weapons.slots[i].level < weapons.slots[lowest].level):
				lowest = i
		if lowest >= 0:
			return {"type": "level", "slot": lowest, "rare": false}
	for module: int in WeaponDefs.MODULES:
		for i in weapons.slots.size():
			if progression.module_status(i, module) != "":
				return {"type": "module", "id": module, "rare": false}
	if not modules_only:
		for passive: int in WeaponDefs.PASSIVES:
			if progression.passives.get(passive, 0) < WeaponDefs.MAX_PASSIVE:
				return {"type": "passive", "id": passive, "rare": false}
	return {"type": "credits", "amount": 20, "rare": false}


## Урон всего боя в интервале формы, а не только от её группы.
func _sim_measure(delta: float) -> void:
	var situation := "control"
	if spawner.director:
		var d := spawner.director
		situation = "event" if d.suspended else HordeDirector.NAMES[d.pattern]
	var row: Dictionary = _sim_situations.get(situation, {"seconds": 0.0, "damage": 0.0})
	row["seconds"] += delta
	row["damage"] += player.damage_taken - _sim_damage_seen
	_sim_damage_seen = player.damage_taken
	_sim_situations[situation] = row


func _sim_report() -> void:
	_sim_measure(0.0)
	var parts: Array[String] = []
	for s in weapons.slots:
		var mods: Array[String] = []
		for m in s.modules:
			mods.append("%s%d" % [WeaponDefs.MODULES[m["id"]]["name"].left(4), m["rank"]])
		parts.append("%s L%d %s%d [%s]" % [s.short_name(), s.level, WeaponDefs.AMMO[s.ammo]["name"].left(4), s.ammo_rank, ",".join(mods)])
	var alive := [0, 0, 0, 0, 0, 0, 0]
	var elites := 0
	for i in horde.count:
		alive[horde.kind[i]] += 1
		elites += horde.elite[i]
	print("SIM %02d:00 level=%d kills=%d xp=%d/%d credits=%d/%d credits_left=%d zombies=%d kinds=%d/%d/%d/%d armored=%d/%d/%d elites=%d elites_spawned=%d crates=%d nades=%d dmg_taken=%d peak=%d fps=%d | %s" % [int(time / 60.0), progression.level, kills,
		gems.collected_total, gems.spawned_total, credit_drops.collected_total, credit_drops.spawned_total, progression.credits, horde.count,
		alive[0], alive[1], alive[2], alive[3], alive[4], alive[5], alive[6], elites, spawner.elites_spawned, crates, nades, roundi(player.damage_taken), _sim_peak, Engine.get_frames_per_second(), " | ".join(parts)])
	_sim_peak = 0
	if endless:
		var elapsed := maxf(0.001, (Time.get_ticks_usec() - _sim_report_started) / 1000000.0)
		print("ENDLESS minute=%d render_fps=%.1f static_mb=%.2f objects=%d nodes=%d enemies=%d gore=%d particles=%d wet=%d activities=%d rate=%.2f director_active=%s" % [int(time / 60.0), _sim_report_frames / elapsed, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, int(Performance.get_monitor(Performance.OBJECT_COUNT)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), horde.count, gore.count, effects.particle_count(), floor_decals.pool_count(), activities.offered, spawner.current_rate(), spawner.director != null and not spawner.director.suspended])
		_sim_report_started = Time.get_ticks_usec()
		_sim_report_frames = 0
	if time >= _sim_until:
		print("SIM summary kills=%d peak=%d level=%d damage=%.2f boss_alive=%s" % [kills, _run_peak, progression.level, player.damage_taken, boss.is_alive()])
		print("ARMOR summary spawned=", horde.military_spawned)
		print("SIM situations ", JSON.stringify(_sim_situations))
		if spawner.director and not endless:
			var tag := "after"
			var trace_path := ""
			for arg: String in OS.get_cmdline_user_args():
				if arg.begins_with("--director-trace="):
					var requested := arg.trim_prefix("--director-trace=")
					if requested.ends_with(".json"):
						trace_path = requested
					else:
						tag = requested.validate_filename()
			if trace_path.is_empty():
				trace_path = "res://design/tasks/reports/hd1_trace_%s.json" % tag
			var file := FileAccess.open(trace_path, FileAccess.WRITE)
			file.store_string(JSON.stringify(_director_trace, "\t"))
			print("DIRECTOR summary curve=%.2f planned=%.2f issued=%d dropped=%.0f" % [spawner.curve_budget, spawner.director.planned, spawner.total_spawned, spawner.director.dropped])
			print("DIRECTOR forms ", JSON.stringify(Array(spawner.director.form_counts)))
		Meta.finish_test()


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
			_announce("МЯСОРУБКА!") # проверка: анонс не перекрывает заголовок тревоги
			_radio("alarm", Color(1.0, 0.45, 0.35), true)
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
		Meta.finish_test()


## Проверка миграции и настроек использует только файл внутри рабочей копии.
func _settings_checks() -> void:
	var saved := Meta.to_dict()
	var old_path := Meta.save_path
	var old_persist := Meta.persist
	var legacy := saved.duplicate(true)
	legacy.erase("settings")
	legacy.erase("campaign") # В настоящей схеме v1 кампании ещё не было.
	legacy.erase("first_run") # В v1 не было флагов вводной; миграция открывает всё старому профилю.
	legacy["version"] = 1
	legacy["dna"] = 123
	Meta.save_path = "res://design/tasks/reports/R1d_test/s7_migration.json" if OS.get_cmdline_user_args().has("--r1d") else "res://design/tasks/reports/R1c_test/s7_migration.json" if OS.get_cmdline_user_args().has("--r1c") else "res://design/tasks/reports/R1b_test/s7_migration.json" if OS.get_cmdline_user_args().has("--r1b") else "res://tmp/s7_migration.json"
	Meta.persist = true
	assert(Meta._write_atomic(Meta.save_path, JSON.stringify(legacy)))
	assert(Meta.load_save() and Meta.dna == 123 and Meta.settings == Meta.DEFAULT_SETTINGS)
	var migrated: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Meta.save_path))
	assert(migrated["version"] == Meta.SAVE_VERSION and migrated.has("settings"))
	for key: String in legacy:
		if key != "version":
			assert(migrated[key] == legacy[key])
	Meta.set_setting("master", 0.42)
	Meta.set_setting("gore", 0)
	Meta.set_setting("shake", 0.0)
	Meta.set_setting("fullscreen", false)
	assert(Meta.load_save() and is_equal_approx(Meta.settings["master"], 0.42) and Meta.settings["gore"] == 0 and not Meta.settings["fullscreen"])
	var clean := Meta.clean_settings({"master": -4.0, "world": 8.0, "ui": "bad", "shake": NAN, "gore": 99, "fullscreen": "bad", "unknown": 1})
	assert(clean["master"] == 0.0 and clean["world"] == 1.0 and clean["ui"] == 1.0 and clean["shake"] == 1.0 and clean["gore"] == 2 and clean["fullscreen"] and not clean.has("unknown"))
	DirAccess.remove_absolute(Meta.save_path)
	Meta.save_path = old_path
	Meta.persist = old_persist
	Meta.from_dict(saved)
	Meta.apply_settings()
	print("S7SETTINGS migration_v1_v%d=true progress_preserved=true roundtrip=true sanitize=true temporary_save=true" % Meta.SAVE_VERSION)


func _audio_shot(suffix: String) -> void:
	if _shot_path == "" or DisplayServer.get_name() == "headless":
		return
	var debug_before: bool = $HUD/Hud.show_debug
	$HUD/Hud.show_debug = false
	$HUD/Hud.queue_redraw()
	await RenderingServer.frame_post_draw
	var path := _shot_path.replace(".png", "_" + suffix + ".png")
	assert(get_viewport().get_texture().get_image().save_png(path) == OK)
	$HUD/Hud.show_debug = debug_before
	print("AUDIO screenshot: " + path)


func _audio_key(code: Key, pad_button := -1) -> void:
	if pad_button >= 0:
		var event := InputEventJoypadButton.new()
		event.button_index = pad_button as JoyButton
		event.pressed = true
		Input.parse_input_event(event)
		await get_tree().process_frame
		event.pressed = false
		Input.parse_input_event(event)
	else:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = true
		Input.parse_input_event(event)
		await get_tree().process_frame
		event.pressed = false
		Input.parse_input_event(event)
	await get_tree().process_frame


func _run_audio_test() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1280, 720))
		Meta.settings["fullscreen"] = false
	_settings_checks()
	weapons.slots.clear()
	for base: int in [WeaponDefs.Base.RIFLE, WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.SNIPER]:
		weapons.add_weapon(base)
		var index := weapons.slots.size() - 1
		weapons.slots[index].level = 3
		weapons.refresh(index)
		weapons.slots[index].mag = weapons.slots[index].stats["mag"]
	for second in 30:
		await get_tree().create_timer(1.0).timeout
		print("AUDIO t=%02d voices=%d horde_voices=%d hits_s=%d dropped=%d horde_mix=%.2f lowpass=%.0f" % [second + 1, sfx.active_voices(), sfx.active_voices(true), sfx.hits_s, sfx.dropped, horde_audio.mix, sfx.lowpass])
		assert(sfx.active_voices() <= Sfx.VOICES and sfx.active_voices(true) <= 6 and sfx.hits_s <= 12)
	_audio_lowhp = true
	player.autopilot = false
	player.position = (player.position + Vector2(-350, 180)).clamp(ARENA.position + Vector2.ONE * 200, ARENA.end - Vector2.ONE * 200)
	player.hp = player.max_hp * 0.2
	for second in 5:
		await get_tree().create_timer(1.0).timeout
		print("AUDIO t=%02d voices=%d horde_voices=%d hits_s=%d dropped=%d horde_mix=%.2f lowpass=%.0f" % [31 + second, sfx.active_voices(), sfx.active_voices(true), sfx.hits_s, sfx.dropped, horde_audio.mix, sfx.lowpass])
	assert(not get_tree().paused and not level_up.visible)
	if not sfx._silent:
		assert(sfx.lowpass < 11000.0)
	await _audio_shot("lowhp")
	await _audio_key(KEY_ESCAPE)
	assert(pause_menu.visible and get_tree().paused)
	var paused_time := time
	await get_tree().create_timer(0.2, true).timeout
	assert(is_equal_approx(time, paused_time))
	await _audio_shot("pause")
	await _audio_key(KEY_DOWN)
	await _audio_key(KEY_ENTER)
	assert(pause_menu.settings_open)
	await _audio_shot("settings")
	await _audio_key(KEY_LEFT)
	assert(is_equal_approx(Meta.settings["master"], 0.95))
	await _audio_key(KEY_RIGHT)
	pause_menu._selected = PauseMenu.KEYS.find("reduce_motion")
	pause_menu.queue_redraw()
	await _audio_shot("settings_help")
	pause_menu._selected = 0
	await _audio_key(KEY_ESCAPE)
	pause_menu._activate(2)
	await _audio_shot("confirm")
	pause_menu._back()
	assert(not pause_menu.confirming and get_tree().paused)
	await _audio_key(KEY_NONE, JOY_BUTTON_START)
	assert(not pause_menu.visible and not get_tree().paused)
	_audio_lowhp = false
	player.hp = player.max_hp
	await get_tree().create_timer(2.0).timeout
	if not sfx._silent:
		assert(sfx.lowpass > 20000.0)
	print("AUDIO pause_freezes=true cancel_return=true lowpass_recovers=true")
	_audio_test = false
	weapons.set_physics_process(false)
	player.autopilot = false
	player.set_physics_process(false)
	hazards.clear()
	hazards.set_physics_process(false)
	var placements := PackedVector2Array()
	var placement_rng := RandomNumberGenerator.new()
	placement_rng.seed = 73177
	for i in 65:
		placements.append(player.position + Vector2.from_angle(placement_rng.randf() * TAU) * placement_rng.randf_range(20.0, 130.0))
	for mode in [0, 2]:
		# Одинаковая постановка на чистом полу, без остатков предыдущего режима.
		Meta.set_setting("gore", mode)
		for i in horde.count:
			horde.dead[i] = 1
		await get_tree().physics_frame
		await get_tree().physics_frame
		gore.count = 0
		effects._n = 0
		while gems.count > 0:
			gems._remove(gems.count - 1)
		while credit_drops.count > 0:
			credit_drops._remove(credit_drops.count - 1)
		floor_decals._pool_tex.clear()
		floor_decals._pool_pos.clear()
		floor_decals._pool_rot.clear()
		floor_decals._pool_scale.clear()
		floor_decals._pool_age.clear()
		floor_decals._pool_step.clear()
		floor_decals._stamps.clear()
		floor_decals._blood.clear()
		for vp: SubViewport in [floor_decals._vp, floor_decals._blood_vp]:
			vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await get_tree().create_timer(0.15).timeout
		seed(73177)
		for i in 65:
			var at := placements[i]
			gore.on_enemy_killed(at, (at - player.position).normalized(), Gore.Death.GIBS if i % 3 == 0 else Gore.Death.NORMAL, 0.0, i % 7)
		screen_blood.splash(1.0)
		await get_tree().create_timer(1.0).timeout
		await _audio_shot("gore_low" if mode == 0 else "gore_max")
		print("AUDIO gore=%d debris=%d particles=%d screen_drops=%d" % [mode, gore.count, effects.particle_count(), screen_blood._pos.size()])
		if mode == 0:
			assert(screen_blood._pos.is_empty())
	pause_menu.open()
	pause_menu._activate(2)
	var runs_before := Meta.runs
	pause_menu._activate(0)
	assert(game_over and results.visible and Meta.runs == runs_before + 1 and not results._stats["victory"])
	print("AUDIO surrender_results=true counted_once=true complete=true")
	Meta.finish_test()


func _run_q1_test() -> void:
	if Meta.test_errors > 0:
		Meta.finish_test(1)
		return
	get_tree().paused = true
	spawner.enabled = false
	player.god_mode = true
	weapons.set_physics_process(false)
	horde.set_physics_process(false)
	boss.set_physics_process(false)
	var ok: bool = await MetaTest.run_q1(self)
	Meta.finish_test(0 if ok else 1)


func _run_meta_test() -> void:
	# Разброс выстрелов и размеры манекенов воспроизводимы вместе с метой.
	seed(20261017)
	horde.reset_variety_seed(20261017)
	_settings_checks()
	# Манекены и оружие шагаются самим MetaTest; фон не должен двигать их и тратить RNG.
	# Meta.rng уже имеет этот seed, но разброс пуль использует глобальный генератор.
	get_tree().paused = true
	seed(20261017)
	var ok: bool = await MetaTest.run(self)
	Meta.finish_test(0 if ok else 1)


func _run_ui_test() -> void:
	if DisplayServer.get_name() != "headless":
		Meta.settings["fullscreen"] = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		get_window().size = Vector2i(1280, 720)
	await get_tree().create_timer(2.0).timeout
	progression.add_xp(Progression.xp_to_next(progression.level) - progression.xp)
	level_up.open([{"type": "module", "id": WeaponDefs.Module.RICOCHET, "rare": true},
		{"type": "weapon", "id": WeaponDefs.Base.SHOTGUN, "rare": false},
		{"type": "ammo", "id": WeaponDefs.Ammo.CRYO, "rare": false}])
	await get_tree().create_timer(1.0, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_cards.png"))
	level_up._hover = 1 # подробности по наведению
	await get_tree().create_timer(0.2, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_cards_hover.png"))
	level_up._hover = -1
	level_up._pick(0)
	await get_tree().create_timer(0.5, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_slots.png"))
	level_up.close()
	# экран контейнера при двух отложенных Level Up: выбор их не списывает
	progression.pending = 2
	_open_loot("СБРОС СНАБЖЕНИЯ", "выбери модуль · +1 оружейный ящик", 3, false, false)
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
	# Сравнение модели и пассивных навыков на том же экране, включая полное HP.
	level_up.open([{"type": "level", "slot": 0, "rare": false},
		{"type": "passive", "id": WeaponDefs.Passive.DAMAGE, "rare": false},
		{"type": "passive", "id": WeaponDefs.Passive.HP, "rare": false}])
	await get_tree().create_timer(0.3, true).timeout
	await _hud_shot("comparisons")
	for rect: Rect2 in level_up._rects:
		assert(Rect2(Vector2.ZERO, level_up.size / level_up._ui).encloses(rect))
	level_up.close()
	get_tree().paused = false
	progression.credits = 230
	time = TRADER_TIMES[0]
	_open_trader()
	await get_tree().create_timer(1.0, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_trader.png"))
	trader_ui._hover = 1
	await get_tree().create_timer(0.2, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shot_path.replace(".png", "_trader_hover.png"))
	trader_ui._hover = -1
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	Input.parse_input_event(key)
	await get_tree().create_timer(0.3, true).timeout
	print("UI test trader closed=%s paused=%s dashing=%s" % [not trader_ui.visible, get_tree().paused, player.is_dashing() or player.dash_cd > 0.0])
	_open_results(false)
	await get_tree().create_timer(4.0, true).timeout # чек считается около трёх секунд
	await _boss_screenshot("defeat")
	results.visible = false
	military_crates = 1
	_full_loadout() # живой чек: четыре ствола и настоящие числа
	kills = 1234
	elites_killed = 14
	best_combo = 87
	time = 600.0
	_open_results(true)
	await get_tree().create_timer(1.2, true).timeout
	await _boss_screenshot("results_counting")
	await get_tree().create_timer(3.0, true).timeout
	await _boss_screenshot("results")
	print("UI test results victory=true military=1 dna=%d paused=%s" % [results._stats["dna_total"], get_tree().paused])
	print("UI test screenshots saved")
	Meta.finish_test()


## --hud-test: готовый билд с разными моделями, орда вокруг, затем снимки HUD (H1).
func _run_hud_test() -> void:
	var hud: Control = $HUD/Hud
	seed(500)
	if DisplayServer.get_name() != "headless":
		Meta.settings["fullscreen"] = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		get_window().size = Vector2i(1920, 1080)
	await get_tree().create_timer(0.5).timeout
	spawner.enabled = false
	player.god_mode = true
	player.autopilot = true
	gems.collected.disconnect(progression.add_xp) # уровень задаём сами, без меню Level Up
	# начало забега: один ствол, чистый HUD с подсказкой управления
	horde.spawn_group(player.position + Vector2(160.0, 0.0), 12)
	await get_tree().create_timer(1.5).timeout
	await _hud_shot("start")
	_full_loadout()
	for pair: Array in [[0, "m4"], [1, "shkval"], [2, "spear"], [3, "hive"]]:
		weapons.slots[pair[0]].set_model(pair[1])
		weapons.refresh(pair[0])
	player.max_hp = 120.0
	player.dash_max = 2
	player.adrenaline = true
	trader_visit = 1
	time = 300.0
	_hud_state()
	seed(500)
	for k in maxi(0, 500 - horde.count):
		horde.spawn(player.position + Vector2.from_angle(randf() * TAU) * randf_range(60.0, 300.0), randi() % 4)
	for k in 3:
		horde.spawn(player.position + Vector2.from_angle(randf_range(-0.5, 0.5)) * randf_range(380.0, 460.0), Horde.Kind.SHAMBLER, true)
	pickups.spawn(player.position + Vector2(-400.0, 80.0), Pickups.Kind.CRATE)
	await get_tree().create_timer(3.0).timeout
	_hud_state()
	for k in maxi(0, 500 - horde.count):
		horde.spawn(player.position + Vector2.from_angle(randf() * TAU) * randf_range(60.0, 300.0), k % 4)
	print("HUDTEST density time=%.2f enemies=%d" % [time, horde.count])
	await _hud_shot("battle")
	# перезарядка: два ствола на разных стадиях
	for pair: Array in [[1, 0.35], [2, 0.7]]:
		var s: Weapons.Slot = weapons.slots[pair[0]]
		weapons._start_reload(s)
		s.reload_t = float(s.stats["reload"]) * pair[1]
	weapons.slots[0].mag = 6
	weapons.slots[3].charged = true
	await get_tree().create_timer(0.3).timeout
	await _hud_shot("reload")
	# низкое HP: удар по бойцу от зомби слева-снизу
	player.hp = 70.0
	horde.spawn(player.position + Vector2(-13.0, 9.0), Horde.Kind.SHAMBLER)
	await get_tree().create_timer(0.1).timeout # зомби должен попасть в сетку орды
	player.god_mode = false
	player.hp = 46.0
	player.take_damage(24.0)
	await get_tree().create_timer(0.12).timeout
	await _hud_shot("lowhp")
	player.god_mode = true
	player.hp = 87.0
	# тревога: контейнер и элитки за краем
	time = BloodAlarm.START - 0.5
	pickups.spawn(player.position + Vector2(380.0, -150.0), Pickups.Kind.CONTAINER)
	await get_tree().create_timer(6.0).timeout
	_hud_state()
	await _hud_shot("alarm")
	# дальше тревога не нужна: без контейнера и меню награды
	blood_alarm.phase = BloodAlarm.Phase.DONE
	spawner.alarm = false
	alarm_overlay.stop()
	while pickups.count > 0:
		pickups._remove(0)
	# босс: сначала за краем, затем полоса здоровья
	trader_visit = TRADER_TIMES.size()
	time = 598.0
	await get_tree().create_timer(2.6).timeout
	await _hud_shot("boss_far")
	await get_tree().create_timer(3.0).timeout
	boss.hp = Boss.MAX_HP * 0.64
	_hud_state()
	await _hud_shot("boss")
	# операция кампании и отладка
	var offers := Campaign.offers()
	var op := {"name": "Красный коридор", "threat": 4, "modifiers": ["runner_surge", "resource_cache"]}
	for offer: Dictionary in offers:
		if offer["modifiers"].size() > 0:
			op = CampaignRules.mission(Meta.campaign, offer, 1)
			break
	hud.set_operation(op)
	print("HUDTEST operation=%s threat=%d modifiers=%s" % [op["name"], op["threat"], op["modifiers"]])
	mission_config = op # крупная плашка операции в начале боя, затем компактная строка
	mission_banner_t = 3.0
	await _hud_shot("op_banner")
	mission_banner_t = 0.0
	await _hud_shot("op")
	mission_config = {}
	hud.show_debug = true
	await _hud_shot("debug")
	hud.show_debug = false
	hud.ammo_sheet = true # лист всех патронов (U3)
	await get_tree().create_timer(0.3).timeout
	await _hud_shot("ammo_sheet")
	hud.ammo_sheet = false
	# 720p
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		get_window().size = Vector2i(1280, 720)
		await get_tree().create_timer(0.5).timeout
	print("HUDTEST window=%s viewport=%s" % [DisplayServer.window_get_size(), get_viewport().get_visible_rect().size])
	_hud_state()
	await _hud_shot("720p")
	await _hud_shot("gray")
	pause_menu.open()
	await get_tree().create_timer(0.3, true).timeout
	await _hud_shot("pause")
	pause_menu.open(true)
	await get_tree().create_timer(0.3, true).timeout
	await _hud_shot("settings")
	pause_menu.close()
	# нестандартные пропорции: 4:3 и 21:9
	if DisplayServer.get_name() != "headless":
		for shape: Array in [["43", Vector2i(1440, 1080)], ["wide", Vector2i(1920, 822)]]:
			get_window().size = shape[1]
			await get_tree().create_timer(0.5).timeout
			_hud_state()
			await _hud_shot(shape[0])
	print("HUDTEST screenshots saved")
	Meta.finish_test()


## Состояние для снимков: цифры, которые бой сам не успевает набрать.
func _hud_state() -> void:
	progression.level = 7
	progression.xp = Progression.xp_to_next(7) / 2
	progression.credits = 340
	progression.passives = {WeaponDefs.Passive.DAMAGE: 2, WeaponDefs.Passive.FIRE_RATE: 1, WeaponDefs.Passive.HP: 1}
	kills = 1234
	combo = 14
	_combo_timer = 1.1
	if not player.is_dead and player.god_mode:
		player.hp = 87.0
	player.dash_left = 1
	player.dash_cd = 1.2
	player.adrenaline_cd = 4.0
	player.grenade_cd = 3.0


func _hud_shot(suffix: String) -> void:
	await RenderingServer.frame_post_draw
	if _shot_path == "" or DisplayServer.get_name() == "headless":
		return
	var path := _shot_path.replace(".png", "_" + suffix + ".png")
	var frame := get_viewport().get_texture().get_image()
	if suffix == "gray":
		for y in frame.get_height():
			for x in frame.get_width():
				var pixel := frame.get_pixel(x, y)
				var light := pixel.r * 0.2126 + pixel.g * 0.7152 + pixel.b * 0.0722
				frame.set_pixel(x, y, Color(light, light, light, pixel.a))
	assert(frame.save_png(path) == OK)
	print("HUDTEST screenshot: ", path)


## Последние полминуты сохраняют слабую орду; предупреждение не мешает управлению.
func _boss_timeline() -> void:
	if endless:
		return
	if not mission_config.is_empty() and mission_config["type"] != "nest":
		return
	if time >= 570.0 and not _boss_warned:
		_boss_warned = true
		_radio("heart_approach" if boss is BossHeart else ("general_approach" if boss is BossGeneral else "approach"), Color(1.0, 0.34, 0.16), true)
		camera.shake(6.0)
	if time < 600.0 or _boss_spawned:
		return
	_boss_spawned = true
	_boss_started = time
	_boss_damage_start = player.damage_taken
	var dir := -player.facing.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.LEFT
	var half := PixelArt.screen_size(get_viewport()) / camera.zoom * 0.5
	var edge := minf(half.x / maxf(absf(dir.x), 0.0001), half.y / maxf(absf(dir.y), 0.0001))
	var at := camera.get_screen_center_position() + dir * (edge + Boss.RADIUS + 16.0)
	if boss is BossHive or boss is BossGeneral:
		at = camera.get_screen_center_position() + dir * maxf(70.0, minf(edge - 65.0, 190.0))
	boss.start(at)
	if boss is BossHeart:
		spawner.enabled = false
		player.position = obstacles.free_point(boss.position + Vector2(160, 80), Player.RADIUS)
		at = boss.position
	var roar_id := "zombies/boss_roar"
	if boss is BossHeart:
		roar_id = "zombies/heart_roar"
	elif boss is BossHive:
		roar_id = "zombies/mother_roar" if boss.hive == BossHive.Hive.MOTHER else "zombies/meat_roar"
	sfx.play(roar_id, at, 1.0, 0.02)
	if _boss_test and _boss_hp > 0.0:
		boss.hp = _boss_hp # --boss-hp=N: быстрый прогон смерти босса
	_announce(boss.display_name().to_upper(), Color(1.0, 0.34, 0.16))
	camera.shake(8.0)
	if _boss_test or _sim:
		print("BOSS spawn t=%.2f pos=%s hp=%.0f" % [time, boss.global_position, boss.hp])


func _on_boss_roar(count: int) -> void:
	sfx.play("zombies/boss_roar", boss.position, 1.0, 0.02)
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
	sfx.play("zombies/heart_roar" if boss is BossHeart else "zombies/boss_roar", boss.position, 1.0, 0.02)
	boss_phase_flash = 0.7
	if not boss is BossHive and not boss is BossHeart and not boss is BossGeneral:
		_announce("БРОНЯ СОРВАНА", Color(1.0, 0.36, 0.18))
	camera.shake(2.0)


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
	_boss_death_usec = Time.get_ticks_usec()
	gore.boss_burst(at)
	explosions.spawn(at, 180.0, Explosions.Kind.BOSS)
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
	if not boss is BossHive and not boss is BossHeart:
		_radio("general_defeated" if boss is BossGeneral else "boss", Color(1.0, 0.82, 0.35))
	if _boss_test or _sim:
		print("BOSS killed fight_s=%.2f military_crates=%d fight_damage=%.2f" % [time - _boss_started, military_crates, player.damage_taken - _boss_damage_start])
		print("MISSION_RESULT outcome=victory time=%.2f kills=%d peak=%d level=%d damage=%.2f" % [time, kills, _run_peak, progression.level, player.damage_taken])
	get_tree().paused = true
	await get_tree().create_timer(0.15, true, false, true).timeout
	Engine.time_scale = 0.25
	get_tree().paused = false
	await get_tree().create_timer(0.6, true, false, true).timeout
	Engine.time_scale = 1.0
	if boss is BossHeart:
		await get_tree().create_timer(0.65, true, false, true).timeout
		# После обвала остаётся тишина. Новый контекст базы снова включит музыку.
		Music.set_process(false)
		for stream: AudioStreamPlayer in Music._players:
			stream.stop()
		horde_audio.set_process(false)
		sfx.set_process(false)
		for voice: Node in sfx.get_children():
			if voice is AudioStreamPlayer or voice is AudioStreamPlayer2D:
				voice.stop()
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
		print("BOSS summary victory=true fight_s=%.2f death_worst_frame_ms=%.2f death_physics_ms=%.2f fight_avg_frame_ms=%.2f fight_worst_frame_ms=%.2f dna=%d damage=%.2f" % [time - _boss_started, _boss_death_worst_ms, _boss_death_physics_ms,
			_boss_fight_ms / maxi(_boss_fight_frames, 1), _boss_fight_worst_ms, results._stats["dna_total"], player.damage_taken])
		for i in Weapons.GUN_IDS.size():
			print("BOSS damage %s=%.2f" % [Weapons.GUN_IDS[i], weapons.boss_damage[i]])
		print("BOSS sources ", weapons.boss_sources)
		print("BOSS death frames ms (first 1.5 s): ", _boss_frames_dbg)
		Meta.finish_test()
	elif _sim:
		_sim_report()
		Meta.finish_test()


## Строки подсчёта ДНК за забег (рапорт и прогноз HUD).
func _dna_lines() -> Array[Array]:
	if endless:
		return [["Время в зоне (4 ДНК/мин)", maxi(0, floori(time / 60.0)) * Meta.ENDLESS_DNA_PER_MINUTE]]
	return [["Время в зоне (10 ДНК/мин)", floori(time / 6.0)], ["Убийства (1 ДНК за 50)", kills / 50], ["Элитки (по 5 ДНК)", elites_killed * 5]]


## Прогноз ДНК за забег без бонуса победы (для HUD).
func dna_forecast() -> int:
	var subtotal := 0
	for line in _dna_lines():
		subtotal += int(line[1])
	return subtotal


## Ближайшее запланированное событие для HUD: {"name", "at"} (время забега, с) или пусто.
func next_event() -> Dictionary:
	if first_run:
		return {"name": "ВЫХОД", "at": 120.0} if time < 120.0 else {}
	if endless:
		return {"name": "ШТОРМ", "at": (floorf(time / Spawner.STORM_PERIOD) + 1.0) * Spawner.STORM_PERIOD}
	var best := {}
	if trader_visit < TRADER_TIMES.size():
		best = {"name": "ТОРГОВЕЦ", "at": TRADER_TIMES[trader_visit]}
	if blood_alarm.phase == BloodAlarm.Phase.IDLE and time < BloodAlarm.START + BloodAlarm.WARN_TIME:
		if best.is_empty() or BloodAlarm.START < float(best["at"]):
			best = {"name": "ТРЕВОГА", "at": BloodAlarm.START}
	if not _boss_spawned and not boss.is_alive() and (mission_config.is_empty() or mission_config["type"] != "extract"):
		if best.is_empty() or 600.0 < float(best["at"]):
			best = {"name": "УЗЕЛ" if boss is CampaignNode else boss.display_name().to_upper(), "at": 600.0}
	return best


func _result_stats(victory: bool) -> Dictionary:
	if endless and not _endless_stats.is_empty():
		return _endless_stats
	var names: Array[String] = []
	var guns: Array[Array] = [] # для значков на экране итогов: модель, уровень, патроны, ранг патронов
	for s in weapons.slots:
		names.append("%s ур.%d · %s %s" % [WeaponDefs.MODELS[s.model]["name"], s.level, WeaponDefs.AMMO[s.ammo]["name"], WeaponDefs.ROMAN[s.ammo_rank]])
		guns.append([s.model, s.level, s.ammo, s.ammo_rank])
	var lines := _dna_lines()
	var subtotal := dna_forecast()
	var mult := (1.5 if victory else 1.0) * float(Meta.run_bonuses()["dna_mul"])
	var stats := {"victory": victory, "outcome": "victory" if victory else "defeat", "time": time, "kills": kills, "elites": elites_killed, "best_combo": best_combo,
		"blood_liters": floor_decals.stamps_total * 0.015, "weapons": names, "guns": guns, "crates": crates, "military_crates": military_crates,
		"dna_lines": lines, "dna_mult": mult, "dna_total": floori(subtotal * mult)}
	if endless:
		stats.merge(Meta.endless_rewards(time), true)
		stats.merge({"endless": true, "map_id": _map_id, "class_id": _endless_class}, true)
		_endless_stats = stats
	if not mission_config.is_empty():
		for key: String in ["run_id", "operation_id", "region_id", "type", "reward"]:
			stats[key] = mission_config[key].duplicate(true) if mission_config[key] is Dictionary else mission_config[key]
	return stats


func _open_results(victory: bool) -> void:
	if gun_lab_range:
		_return_to_base()
		return
	if activities:
		activities.clear()
	pause_menu.visible = false
	game_over = true
	Engine.time_scale = 1.0
	level_up.close()
	trader_ui.visible = false
	alarm_overlay.stop()
	Music.play(&"results")
	if first_run:
		Meta.finish_first_run()
	elif victory and objective != null and objective.type == "extract" and objective.done:
		Meta.complete_hint("evac")
	var stats := _result_stats(victory)
	stats["first_run"] = first_run
	results.open(stats)
	if victory and boss is BossHeart and Meta.campaign.get("phase") == "victory":
		results.visible = false
		var ending := WarEnding.new()
		ending.world = Campaign.world()
		ending.base_requested.connect(_return_to_base)
		$Overlay.add_child(ending)
	get_tree().paused = true


func _restart_run() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred("res://scenes/main.tscn")


func _return_to_base() -> void:
	if boss is BossHeart:
		Music.set_process(true)
	if get_tree().has_meta("endless_config"):
		get_tree().remove_meta("endless_config")
	Engine.time_scale = 1.0
	get_tree().paused = false
	# Возврат из тестового боя тоже показывает базу, не повторяя маршрутизацию CLI.
	get_tree().set_meta("s6_return_to_base", true)
	get_tree().change_scene_to_file.call_deferred("res://scenes/base.tscn")


## Проверяет обе кнопки итогов на настоящих переходах сцен и состояние Meta между ними.
func _run_base_test() -> void:
	await get_tree().create_timer(0.4).timeout
	BaseScreen._check("battle favorite+workshop applied", weapons.slots[0].model == "m4" and is_equal_approx(float(weapons.slots[0].stats["damage"]), 8.0 * 1.10 * 1.08))
	if BaseScreen._test_stage == 1 and not _shot_path.is_empty():
		await _run_class_shots(false)
	if BaseScreen._test_stage == 1:
		time = 60.0
		kills = 100
		await _on_player_died()
		await get_tree().create_timer(0.8, true).timeout
		await _boss_screenshot("base_defeat")
		BaseScreen._check("defeat rewards once+paused", Meta.runs == 1 and get_tree().paused)
		BaseScreen._test_stage = 2
		# X пропускает отсчёт, повторный X перезапускает бой.
		for n in 2:
			var again := _button(JOY_BUTTON_X)
			again.pressed = true
			Input.parse_input_event(again)
			again = again.duplicate()
			again.pressed = false
			Input.parse_input_event(again)
			await get_tree().create_timer(0.1, true).timeout
	else:
		BaseScreen._check("restart main scene+meta kept", Meta.runs == 1 and not game_over and not get_tree().paused)
		time = 120.0
		kills = 200
		crates = 2
		military_crates = 1
		_open_results(true)
		await get_tree().create_timer(0.8, true).timeout
		await _boss_screenshot("base_results")
		BaseScreen._check("victory rewards once+paused", Meta.runs == 2 and get_tree().paused)
		# B возвращает на базу через обычный маршрут ввода итогов.
		for n in 2:
			var home := _button(JOY_BUTTON_B)
			home.pressed = true
			Input.parse_input_event(home)
			home = home.duplicate()
			home.pressed = false
			Input.parse_input_event(home)
			await get_tree().create_timer(0.1, true).timeout


func _draw_boss_reward() -> void:
	if _boss_reward_pos == Vector2.INF:
		return
	var t := clampf(_boss_reward_age / 0.8, 0.0, 1.0)
	var height := 48.0 * pow(1.0 - t, 2.0) + absf(sin(t * PI * 3.0)) * 5.0 * (1.0 - t)
	PixelArt.draw_dot(_boss_reward, _boss_reward_pos, 12.0, Color(0.02, 0.02, 0.01, 0.5))
	_boss_reward.draw_set_transform(_boss_reward_pos - Vector2(0, height), 0.0, Vector2.ONE * PixelArt.ART_SCALE)
	_boss_reward.draw_texture(_boss_crate_tex, -_boss_crate_tex.get_size() * 0.5)
	_boss_reward.draw_set_transform(Vector2.ZERO)
	_boss_reward.draw_string(preload("res://scripts/ui/zera_style.gd").BODY_FONT, _boss_reward_pos + Vector2(-44, -20 - height), "+1 ВОЕННЫЙ ЯЩИК", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, preload("res://scripts/ui/zera_style.gd").ACTION)


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
	if time > (2400.0 if OS.get_cmdline_user_args().has("--boss-sim") else 840.0):
		print("BOSS timeout hp=%.0f" % boss.hp)
		Meta.finish_test(1)


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
	var alive := [0, 0, 0, 0, 0, 0, 0]
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
	_bench_hud_ms += $HUD/Hud.draw_ms
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
	print("%s physics_avg_ms=%.2f hud_ms=%.3f" % [label, _bench_physics_ms / n, _bench_hud_ms / n])
	if OS.get_cmdline_user_args().has("--gore-profile"):
		var gpu := 0.0
		for vp: Viewport in [get_viewport(), floor_decals._vp, floor_decals._blood_vp]:
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp.get_viewport_rid())
		print("R1PROFILE static=%d video=%d gpu_last_ms=%.3f remains=%d remains_peak=%d stamps=%d queue=%d" % [OS.get_static_memory_usage(), Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), gpu, gore.remains_count, gore.remains_peak, floor_decals.stamps_total, floor_decals._blood.size()])
	if obstacles and obstacles.profile_enabled:
		_pathing_profile()
		print("OBSPROFILE move_calls=%d move_ms=%.3f resolve_calls=%d resolve_ms=%.3f ray_calls=%d ray_ms=%.3f nav_worst_us=%d" % [obstacles.move_calls, obstacles.move_usec / 1000.0, obstacles.resolve_calls, obstacles.resolve_usec / 1000.0, obstacles.ray_calls, obstacles.ray_usec / 1000.0, obstacles.nav_worst_usec])
	if _shot_path != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_shot_path)
		print(label, " screenshot: ", _shot_path)
	Meta.finish_test()


## Управление задаём кодом по физическим клавишам — работает при любой раскладке.
static func _setup_input() -> void:
	_add_action("move_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_add_action("move_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_add_action("move_up", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_add_action("move_down", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_add_action("dash", [_key(KEY_SPACE), _key(KEY_SHIFT), _button(JOY_BUTTON_A)])
	_add_action("reload", [_key(KEY_R), _button(JOY_BUTTON_X)])
	_add_action("grenade", [_key(KEY_Q), _key(KEY_G), _mouse(MOUSE_BUTTON_MIDDLE), _button(JOY_BUTTON_RIGHT_SHOULDER)])
	_add_action("aim_override", [_mouse(MOUSE_BUTTON_RIGHT)])
	_add_action("fire", [_mouse(MOUSE_BUTTON_LEFT), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_add_action("aim_left", [_axis(JOY_AXIS_RIGHT_X, -1.0)])
	_add_action("aim_right", [_axis(JOY_AXIS_RIGHT_X, 1.0)])
	_add_action("aim_up", [_axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_add_action("aim_down", [_axis(JOY_AXIS_RIGHT_Y, 1.0)])


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


## --aim-test: настоящий маршрут ввода и выстрела, сохранение только в tmp/.
func _aim_check(ok: bool, label: String) -> void:
	if not ok:
		_aim_failures += 1
	print("AIMTEST %s=%s" % [label, ok])


func _aim_mouse(button: MouseButton, pressed: bool) -> void:
	var event := _mouse(button)
	event.pressed = pressed
	event.position = player.aim_mouse_position
	event.global_position = event.position
	Input.parse_input_event(event)
	await get_tree().create_timer(0.04).timeout


func _aim_axis(axis: JoyAxis, value: float) -> void:
	var event := _axis(axis, value)
	Input.parse_input_event(event)
	await get_tree().create_timer(0.04).timeout


func _aim_stick(value: Vector2) -> void:
	Input.parse_input_event(_axis(JOY_AXIS_RIGHT_X, value.x))
	Input.parse_input_event(_axis(JOY_AXIS_RIGHT_Y, value.y))
	await get_tree().create_timer(0.04).timeout


func _aim_move(offset: Vector2) -> void:
	var screen := player.get_canvas_transform() * (player.global_position + offset)
	var event := InputEventMouseMotion.new()
	event.position = screen
	event.global_position = screen
	event.relative = Vector2(2, 0)
	get_viewport().push_input(event, true)
	await get_tree().create_timer(0.06).timeout


func _aim_refill() -> void:
	weapons.clear_projectiles()
	weapons.refill_all()
	for slot: Weapons.Slot in weapons.slots:
		slot.cooldown = 0.0
		slot.heat = 0.0
		slot.fan_left = 0
	_aim_records.clear()


## Снимаем направление уже созданных снарядов, а не только вычисленный aim_dir.
func _aim_on_shot(base: int) -> void:
	var slot: Weapons.Slot
	for s: Weapons.Slot in weapons.slots:
		if s.base == base:
			slot = s
			break
	var angle := player.aim_dir.angle()
	var cursor_angle := (player.aim_point - player.global_position).angle()
	var worst := 0.0
	var spread_limit := (float(slot.stats.get("spread", 0.0)) + slot.heat) * 0.5
	if base not in [WeaponDefs.Base.RAIL, WeaponDefs.Base.LAUNCHER]:
		if base != WeaponDefs.Base.SHOTGUN:
			spread_limit += (int(slot.stats["proj"]) - 1) * 2.5
		for b in range(weapons.bullet_count - int(slot.stats["proj"]), weapons.bullet_count):
			var actual := weapons._bvel[b].angle()
			worst = maxf(worst, absf(angle_difference(angle, actual)))
	elif base == WeaponDefs.Base.RAIL:
		spread_limit = (int(slot.stats["proj"]) - 1) * 7.5
		var beam: Array = weapons._beams.back()
		worst = absf(angle_difference(angle, (beam[1] - beam[0]).angle()))
	_aim_records.append({"model": slot.model, "base": base, "angle": rad_to_deg(angle),
		"cursor": rad_to_deg(cursor_angle), "error": rad_to_deg(worst),
		"limit": spread_limit,
		"manual": player.manual_aim})


func _aim_verify_shots(label: String, count: int) -> void:
	var models := {}
	var ok := true
	for shot: Dictionary in _aim_records:
		models[shot["model"]] = true
		ok = ok and shot["manual"] and absf(angle_difference(deg_to_rad(shot["angle"]), deg_to_rad(shot["cursor"]))) < 0.001
		ok = ok and float(shot["error"]) <= float(shot["limit"]) + 0.01
		if not models.get(shot["model"] + "_printed", false):
			print("AIMTEST %s model=%s shot_deg=%.3f cursor_deg=%.3f projectile_error_deg=%.3f spread_limit_deg=%.3f" % [label, shot["model"], shot["angle"], shot["cursor"], shot["error"], shot["limit"]])
			models[shot["model"] + "_printed"] = true
	_aim_check(ok and models.size() == count * 2, label + "_all_guns_to_cursor")


## W3: реальная геометрия слотов и выстрелы, фиксированный шаг без случайного кадра вспышки.
func _guns_step(frames: int) -> void:
	for frame in frames:
		weapons._age_fx(1.0 / 60.0)
		player.sprite.rotation = player.aim_dir.angle()
		for i in weapons.slots.size():
			weapons._update_slot(i, 1.0 / 60.0)
		effects._physics_process(1.0 / 60.0)
		weapons._update_gun_layers()


func _guns_image(label: String) -> Image:
	_guns_label.text = label
	weapons.queue_redraw()
	weapons._flash_layer.queue_redraw()
	weapons._update_gun_layers()
	effects.queue_redraw()
	await RenderingServer.frame_post_draw
	var frame := get_viewport().get_texture().get_image()
	var center := Vector2i(player.get_global_transform_with_canvas().origin)
	var crop := frame.get_region(Rect2i(center - Vector2i(96, 72), Vector2i(192, 144)))
	crop.resize(576, 432, Image.INTERPOLATE_NEAREST)
	return crop


var _guns_label: Label


func _run_guns_test() -> void:
	seed(33117)
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	set_physics_process(false)
	spawner.enabled = false
	weapons.set_physics_process(false)
	player.set_physics_process(false)
	horde.set_physics_process(false)
	effects.set_physics_process(false)
	player.god_mode = true
	player.position = ARENA.get_center()
	player.aim_dir = Vector2.RIGHT
	player.force_auto_aim = true
	player.fire_requested = true
	$HUD.visible = false
	camera.target = null
	camera.position_smoothing_enabled = false
	camera.shake_multiplier = 0.0
	camera.position = player.position
	camera.zoom = Vector2.ONE * 3.0
	weapons.camera = null
	var overlay := CanvasLayer.new()
	add_child(overlay)
	_guns_label = Label.new()
	overlay.add_child(_guns_label)
	_guns_label.add_theme_font_size_override("font_size", 12)
	_guns_label.position = get_viewport_rect().size * 0.5 + Vector2(-90, 52)
	var path := _shot_path if not _shot_path.is_empty() else "res://design/tasks/reports/w3_guns.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	await get_tree().create_timer(0.2).timeout
	var targets := PackedVector2Array([Vector2(90, 0), Vector2(32, 88), Vector2(32, -88), Vector2(-41, -88)])
	for at: Vector2 in targets:
		var e := horde.spawn(player.position + at)
		horde.speed[e] = 0.0
		horde.hp[e] = 1000000.0
	horde._rebuild_grid() # физика орды в этом тесте выключена, а цели ищутся по сетке
	weapons.slots.clear()
	weapons.add_weapon(WeaponDefs.Base.RIFLE, "ak_s")
	_guns_step(30)
	weapons.clear_projectiles()
	weapons._flashes.clear()
	effects._update_lights(1.0)
	(await _guns_image("01 / AK-S")).save_png(path.get_basename() + "_single.png")
	for id: String in ["butcher", "needle", "colt"]:
		weapons.add_weapon(WeaponDefs.MODELS[id]["base"], id)
	weapons.refill_all()
	_guns_step(50)
	var unique := {}
	for s: Weapons.Slot in weapons.slots:
		unique[s.target] = true
	assert(unique.size() == 4)
	# Останавливаем все стволы в одном моменте выстрела; проверяем реальные источники.
	weapons.clear_projectiles()
	weapons._flashes.clear()
	for i in 4:
		var s := weapons.slots[i]
		s.reloading = false
		s.mag = 10
		var before := weapons.bullet_count
		weapons._fire_shot(i, s, s.target)
		var muzzle := weapons.gun_point(i, s.muzzle)
		assert(Vector2(weapons._flashes.back()[0]).distance_to(muzzle) < 0.001)
		if s.base == WeaponDefs.Base.RAIL:
			assert(Vector2(weapons._beams.back()[0]).distance_to(muzzle) < 0.001)
		else:
			assert(weapons._bpos[before].distance_to(muzzle) < 0.001)
		assert(s.recoil >= 1.0 and s.recoil <= 2.0)
		print("GUNSTEST slot=%d model=%s target=%d angle=%.2f muzzle=%s" % [i, s.model, s.target, rad_to_deg(s.angle), muzzle])
	(await _guns_image("04 / AUTO + FLASH")).save_png(path.get_basename() + "_auto.png")
	weapons._flashes.clear()
	weapons.clear_projectiles()
	player.manual_aim = true
	player.aim_dir = Vector2(1, -0.35).normalized()
	player.aim_point = player.position + player.aim_dir * 140.0
	weapons.refill_all()
	_guns_step(30)
	for s: Weapons.Slot in weapons.slots:
		assert(absf(angle_difference(s.angle, player.aim_dir.angle())) < 0.001)
	weapons.clear_projectiles()
	weapons._flashes.clear()
	effects._update_lights(1.0)
	(await _guns_image("04 / MANUAL")).save_png(path.get_basename() + "_manual.png")
	weapons._flashes.clear()
	weapons.clear_projectiles()
	for s: Weapons.Slot in weapons.slots:
		s.reloading = true
		s.reload_t = float(s.stats["reload"]) * 0.5
		s.recoil = 0.0
	(await _guns_image("04 / RELOAD")).save_png(path.get_basename() + "_reload.png")
	# Урон синхронно скрывает оба слоя; спинной слой стоит перед Sprite.
	player.sprite.visible = false
	weapons._update_gun_layers()
	assert(not weapons._gun_layers[0].visible and not weapons._gun_layers[1].visible)
	player.sprite.visible = true
	assert(weapons._gun_layers[0].get_index() < player.sprite.get_index())
	assert(weapons._gun_layers[1].get_index() > player.sprite.get_index())
	# Цель за сектором не должна расходовать патроны; затем корпус доворачивается.
	player.manual_aim = false
	var servo := weapons.slots[1]
	servo.reloading = false
	servo.recoil = 0.0
	servo.angle = 0.0
	player.aim_dir = Vector2.RIGHT
	weapons._aim_gun(1, player.position + Vector2(-100, 0), 1.0)
	assert(not weapons._gun_aligned(1, player.position + Vector2(-100, 0)))
	player.aim_dir = Vector2.LEFT
	player.sprite.rotation = PI
	weapons._aim_gun(1, player.position + Vector2(-100, 0), 1.0)
	assert(weapons._gun_aligned(1, player.position + Vector2(-100, 0)))
	player.manual_aim = true
	player.aim_dir = Vector2.RIGHT
	player.sprite.rotation = 0.0
	effects._cn = 0
	effects._n = 0
	effects._update_lights(1.0)
	var sheet := Image.create(2304, ceili(WeaponDefs.MODELS.size() / 4.0) * 432, false, Image.FORMAT_RGB8)
	var n := 0
	for id: String in WeaponDefs.MODELS:
		weapons.slots.clear()
		weapons.add_weapon(WeaponDefs.MODELS[id]["base"], id)
		var s := weapons.slots[0]
		s.cooldown = 1000.0
		_guns_step(1)
		var model_image := await _guns_image("%02d / %s" % [n + 1, id.to_upper()])
		sheet.blit_rect(model_image, Rect2i(0, 0, 576, 432), Vector2i((n % 4) * 576, (n >> 2) * 432))
		n += 1
	sheet.save_png(path.get_basename() + "_models.png")
	print("GUNSTEST ok=true models=%d independent_targets=4 muzzle_sources=4 recoil=true sector=true blink=true layers=true" % n)
	Meta.finish_test()


func _run_aim_test() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	Meta.settings["fullscreen"] = false
	$HUD/Hud.show_debug = false
	weapons.firing_enabled = false
	await get_tree().create_timer(0.15).timeout
	_aim_check(not Meta.persist and Meta.save_path == Meta.SAVE_PATH, "temporary_save")
	# Старый v2 с настройками S7, без нового ключа; прогресс остаётся прежним.
	var saved := Meta.to_dict()
	var legacy := saved.duplicate(true)
	legacy["dna"] = 123
	legacy["settings"].erase("auto_fire")
	Meta.save_path = "res://design/tasks/reports/R1d_test/s8_settings.json" if OS.get_cmdline_user_args().has("--r1d") else "res://design/tasks/reports/R1c_test/s8_settings.json" if OS.get_cmdline_user_args().has("--r1c") else "res://tmp/s8_settings.json"
	Meta.persist = true
	var migration_ok := Meta._write_atomic(Meta.save_path, JSON.stringify(legacy)) and Meta.load_save()
	migration_ok = migration_ok and Meta.settings["auto_fire"] and Meta.dna == 123
	Meta.set_setting("auto_fire", false)
	var roundtrip_ok: bool = Meta.load_save() and not Meta.settings["auto_fire"] and Meta.dna == 123
	_aim_check(migration_ok and roundtrip_ok and Meta.clean_settings({"auto_fire": "bad"})["auto_fire"], "settings_migration_roundtrip")
	DirAccess.remove_absolute(Meta.save_path)
	Meta.persist = false
	Meta.save_path = Meta.SAVE_PATH
	Meta.from_dict(saved)
	Meta.set_setting("auto_fire", true)
	Meta.set_setting("shake", 0.0)
	weapons.slots.clear()
	for base: int in [WeaponDefs.Base.RIFLE, WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.RAIL, WeaponDefs.Base.LAUNCHER]:
		weapons.add_weapon(base)
	# Пули видны веером, без изменения баланса реального забега.
	weapons.slots[0].modules = [{"id": WeaponDefs.Module.TWIN, "rank": 3, "rare": false}]
	weapons.refresh(0)
	var nearest := horde.spawn(player.position + Vector2(-80, 0))
	horde.hp[nearest] = 1000000.0
	horde.speed[nearest] = 0.0
	var farther := horde.spawn(player.position + Vector2(-160, 45))
	horde.hp[farther] = 1000000.0
	horde.speed[farther] = 0.0
	for k in 22:
		floor_decals.stamp(PixelArt.tex("blood_%d" % (k % 8)), player.position + Vector2(randf_range(30, 170), randf_range(-90, 80)), randf() * TAU, Color(0.36, 0.012, 0.008, 0.85))
	weapons.shot_fired.connect(_aim_on_shot)
	await _aim_move(Vector2(130, -35))
	_aim_refill()
	weapons.firing_enabled = true
	await get_tree().create_timer(0.22).timeout
	_aim_check(not player.manual_aim and player.aim_dir.x < -0.9 and weapons._nearest_target(player.position, 300) == nearest, "auto_nearest")
	await _audio_shot("auto")
	var nades_before := nades
	await _aim_mouse(MOUSE_BUTTON_RIGHT, true)
	_aim_refill()
	await get_tree().create_timer(0.18).timeout
	_aim_verify_shots("override", 4)
	_aim_check(nades == nades_before and player.sprite.rotation == player.aim_dir.angle(), "rmb_aim_no_grenade_rotation")
	await _audio_shot("override")
	await _aim_mouse(MOUSE_BUTTON_RIGHT, false)
	_aim_refill()
	await get_tree().create_timer(0.12).timeout
	_aim_check(not player.manual_aim and player.aim_dir.x < -0.9 and not _aim_records.is_empty(), "release_returns_auto")
	Meta.set_setting("auto_fire", false)
	_aim_refill()
	var before := weapons.shots.duplicate()
	await get_tree().create_timer(2.0).timeout
	_aim_check(weapons.shots == before, "manual_idle_2s_zero_shots")
	floor_decals.stamp(PixelArt.tex("blood_3"), player.aim_point, 0.3, Color(0.45, 0.012, 0.008), 1.5)
	await _aim_mouse(MOUSE_BUTTON_LEFT, true)
	await get_tree().create_timer(0.18).timeout
	_aim_verify_shots("manual", 4)
	await _audio_shot("manual")
	await _aim_mouse(MOUSE_BUTTON_LEFT, false)
	before = weapons.shots.duplicate()
	await get_tree().create_timer(0.3).timeout
	_aim_check(weapons.shots == before, "release_lmb_stops_all")
	# Отдельно измеряем реальную точку взрыва и ограничение дальности гранатомёта.
	weapons.slots.clear()
	weapons.add_weapon(WeaponDefs.Base.LAUNCHER)
	await _aim_move(Vector2(110, -35))
	_aim_refill()
	await _aim_mouse(MOUSE_BUTTON_LEFT, true)
	await _aim_mouse(MOUSE_BUTTON_LEFT, false)
	var expected := player.aim_point
	while not weapons._gpos.is_empty():
		await get_tree().physics_frame
	await get_tree().process_frame
	var explosion_error := explosions.last_at.distance_to(expected)
	var explosion_ok := explosion_error < 5.0
	print("AIMTEST launcher explosion_error_px=%.3f" % explosion_error)
	_aim_check(explosion_ok, "launcher_explosion_at_cursor")
	await _aim_move(Vector2(260, -35))
	_aim_refill()
	await _aim_mouse(MOUSE_BUTTON_LEFT, true)
	await _aim_mouse(MOUSE_BUTTON_LEFT, false)
	var endpoint := weapons._gpos[0] + weapons._gvel[0].normalized() * weapons._gleft[0]
	_aim_check(absf(endpoint.distance_to(player.position) - float(weapons.slots[0].stats["range"])) < 0.01, "launcher_range_clamp")
	# Остальные категории и все модели из ящиков, включая прерываемый ручной веер Ковбоя.
	for batch in 3:
		weapons.slots.clear()
		var ids: Array = ["colt", "bulldog", "ppsh", "mosin"] if batch == 0 else (["m4", "shkval", "spear", "hive"] if batch == 1 else ["guard", "cowboy", "osa", "winchester"])
		for id: String in ids:
			weapons.add_weapon(WeaponDefs.MODELS[id]["base"], id)
		_aim_refill()
		await _aim_mouse(MOUSE_BUTTON_LEFT, true)
		await get_tree().create_timer(0.15).timeout
		_aim_verify_shots("models_%d" % batch, 4)
		await _aim_mouse(MOUSE_BUTTON_LEFT, false)
		before = weapons.shots.duplicate()
		await get_tree().create_timer(0.6).timeout
		_aim_check(weapons.shots == before, "models_%d_release_stops" % batch)
	Meta.set_setting("auto_fire", true)
	_aim_refill()
	await _aim_axis(JOY_AXIS_RIGHT_X, 0.3)
	_aim_check(not player.manual_aim, "stick_deadzone")
	await _aim_stick(Vector2(0.8, 0.6))
	_aim_refill()
	await get_tree().create_timer(0.15).timeout
	_aim_verify_shots("gamepad_override", 4)
	_aim_check(player.aim_gamepad and player.aim_dir.is_equal_approx(Vector2(0.8, 0.6)), "gamepad_axis_override")
	await _aim_stick(Vector2.ZERO)
	_aim_check(not player.manual_aim, "stick_release_auto")
	Meta.set_setting("auto_fire", false)
	_aim_refill()
	before = weapons.shots.duplicate()
	await get_tree().create_timer(0.2).timeout
	_aim_check(weapons.shots == before and player.aim_dir.is_equal_approx(Vector2(0.8, 0.6)), "gamepad_manual_idle_last_direction")
	await _aim_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await get_tree().create_timer(0.15).timeout
	_aim_verify_shots("gamepad_trigger", 4)
	await _aim_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	before = weapons.shots.duplicate()
	await get_tree().create_timer(0.2).timeout
	_aim_check(weapons.shots == before, "trigger_release_stops")
	# Смену устройства, близкий курсор и неподвижный прицел при движении камеры тоже проверяем.
	await _aim_move(Vector2.ZERO)
	_aim_check(player.aim_dir.is_finite() and player.aim_dir.length() > 0.99 and not player.aim_gamepad, "mouse_returns_close_cursor_valid")
	await _aim_move(Vector2(120, -55))
	var cursor_world := player.get_canvas_transform().affine_inverse() * player.aim_mouse_position
	_aim_check(player.aim_point.distance_to(cursor_world) < 0.01, "camera_world_coordinates")
	# Граната на G / СКМ / RB; ПКМ уже проверена отдельно.
	var grenade_ok := true
	for control in 3:
		player.grenade_cd = 0.0
		player._gren_t = -1.0
		var old_nades := nades
		if control == 0:
			Input.parse_input_event(_aim_pressed_key(KEY_G, true))
			await get_tree().create_timer(0.04).timeout
			Input.parse_input_event(_aim_pressed_key(KEY_G, false))
		elif control == 1:
			await _aim_mouse(MOUSE_BUTTON_MIDDLE, true)
			await _aim_mouse(MOUSE_BUTTON_MIDDLE, false)
		else:
			var event := _button(JOY_BUTTON_RIGHT_SHOULDER)
			event.pressed = true
			Input.parse_input_event(event)
			await get_tree().create_timer(0.04).timeout
			event.pressed = false
			Input.parse_input_event(event)
		await get_tree().create_timer(0.5).timeout
		grenade_ok = grenade_ok and nades == old_nades + 1
	_aim_check(grenade_ok, "grenade_g_mmb_rb")
	# Попадания ручной пули, рельсы и гранаты по живому боссу через обычную физику.
	boss.start(player.position + Vector2(100, -20))
	boss.set_physics_process(false)
	var boss_ok := true
	for base: int in [WeaponDefs.Base.RIFLE, WeaponDefs.Base.RAIL, WeaponDefs.Base.LAUNCHER]:
		weapons.slots.clear()
		weapons.add_weapon(base)
		_aim_refill()
		await _aim_move(boss.position - player.position)
		var hp_before := boss.hp
		await _aim_mouse(MOUSE_BUTTON_LEFT, true)
		await _aim_mouse(MOUSE_BUTTON_LEFT, false)
		await get_tree().create_timer(0.7).timeout
		boss_ok = boss_ok and boss.hp < hp_before
	_aim_check(boss_ok, "manual_boss_bullet_rail_explosion")
	weapons.firing_enabled = false
	Meta.set_setting("auto_fire", true)
	pause_menu.open(true)
	await get_tree().create_timer(0.04).timeout
	_aim_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not $HUD/Hud.combat_cursor_visible(), "pause_system_cursor")
	await _audio_shot("settings")
	await _aim_move(Vector2(90, 65))
	pause_menu._selected = PauseMenu.KEYS.find("auto_fire")
	pause_menu._change(1)
	_aim_check(not Meta.settings["auto_fire"], "settings_menu_toggle")
	pause_menu.close()
	await get_tree().create_timer(0.04).timeout
	_aim_check(Input.mouse_mode == Input.MOUSE_MODE_HIDDEN and $HUD/Hud.combat_cursor_visible(), "combat_crosshair")
	_aim_check(player.aim_mouse_position.distance_to(player.get_canvas_transform() * (player.position + Vector2(90, 65))) < 0.01, "menu_mouse_position_kept")
	# На базе используется тот же PauseMenu без владельца паузы.
	var base_settings := PauseMenu.new()
	$Overlay.add_child(base_settings)
	base_settings.open(true)
	base_settings._selected = PauseMenu.KEYS.find("auto_fire")
	base_settings._change(1)
	_aim_check(Meta.settings["auto_fire"] and not get_tree().paused, "base_settings_shared_toggle")
	base_settings.close()
	base_settings.queue_free()
	Meta.set_setting("auto_fire", false)
	player.force_auto_aim = true
	player._update_aim()
	_aim_check(not player.manual_aim and player.fire_requested, "autopilot_forced_auto")
	_aim_check(MetaTest.run_aim_wall(self), "line_of_sight_regressions")
	print("AIMTEST ok=%s failures=%d" % [_aim_failures == 0, _aim_failures])
	Meta.finish_test(0 if _aim_failures == 0 else 1)


func _aim_pressed_key(code: Key, pressed: bool) -> InputEventKey:
	var event := _key(code)
	event.pressed = pressed
	return event


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
	Meta.finish_test()


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
	var offered := PackedByteArray()
	offered.resize(WeaponDefs.BASES.size())
	for attempt in 400:
		for card: Dictionary in progression.make_cards(0.0):
			if card["type"] == "weapon":
				offered[int(card["id"])] = 1
	for base in range(4, WeaponDefs.BASES.size()):
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
	Meta.finish_test()


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
		horde._rebuild_grid()
		await get_tree().physics_frame
		var before := weapons.tails[base]
		var id: String = "weapons/" + Weapons.GUN_IDS[base] + "/tail"
		assert(sfx.has(id))
		var played := int(sfx.played_by_id.get(id, 0))
		# Даже короткая очередь получает отражение; повторная пауза молчит.
		for k in 2:
			s.cooldown = 0.0
			weapons._update_slot(0, 1.0 / 60.0)
		s.cooldown = 1000.0
		weapons._update_slot(0, 2.0 / float(s.stats["rate"]))
		assert(weapons.tails[base] == before + 1)
		await _wtest_audio_gap()
		for k in 3:
			s.cooldown = 0.0
			weapons._update_slot(0, 1.0 / 60.0)
		s.cooldown = 1000.0
		weapons._update_slot(0, 2.0 / float(s.stats["rate"]))
		weapons._update_slot(0, 2.0 / float(s.stats["rate"]))
		assert(weapons.tails[base] == before + 2)
		await _wtest_audio_gap()
		# Тактическая перезарядка завершает очередь сразу.
		for k in 3:
			s.cooldown = 0.0
			weapons._update_slot(0, 1.0 / 60.0)
		weapons.reload_all()
		assert(weapons.tails[base] == before + 3)
		s.reloading = false
		s.mag = s.stats["mag"]
		await _wtest_audio_gap()
		# Новая цель внутри стрельбы не наслаивает хвост, он звучит после паузы.
		for k in 3:
			s.cooldown = 0.0
			weapons._update_slot(0, 1.0 / 60.0)
		var other := horde.spawn(player.position + Vector2(70, 0))
		horde.speed[other] = 0.0
		horde.hp[other] = 100000.0
		horde._rebuild_grid()
		await get_tree().physics_frame
		s.cooldown = 0.0
		s.target_t = 0.0 # пауза между сканами цели прошла
		weapons._update_slot(0, 1.0 / 60.0)
		assert(weapons.tails[base] == before + 3)
		s.cooldown = 1000.0
		weapons._update_slot(0, 2.0 / float(s.stats["rate"]))
		assert(weapons.tails[base] == before + 4)
		if DisplayServer.get_name() != "headless":
			assert(int(sfx.played_by_id.get(id, 0)) == played + 4)
		print("W5TEST tails %s short=1 pause=1 reload=1 target_change=0 final=1 repeated_pause=0 played=%d" % [Weapons.GUN_IDS[base], int(sfx.played_by_id.get(id, 0)) - played])
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


## Цели завершаются через общий commit результатов.
func _objective_victory() -> void:
	if game_over:
		return
	game_over = true
	if objective:
		objective.done = true
	spawner.enabled = false
	weapons.firing_enabled = false
	player.god_mode = true
	player.set_physics_process(false)
	if boss is CampaignNode:
		explosions.spawn(boss.position, 110.0, Explosions.Kind.DETONATOR)
		_radio_line_objective("Узел уничтожен. Группа на выход.")
	else:
		_radio_line_objective("Образец на борту. Операция завершена.")
	await get_tree().create_timer(1.4).timeout
	_open_results(true)


func _radio_line_objective(line: String) -> void:
	radio_text = line
	radio_t = 4.0

## R1c: реальные реакции, штатная камера; до/после меняется только имя PNG.
func _r1c_detail_shots(center: Vector2) -> void:
	var suffix := "_before" if OS.get_cmdline_user_args().has("--r1c-before") else ""
	var images: Array[Image] = []
	for base: int in [0, 6, 4, 5, 1, 7, 2, 3]:
		gore.count = 0
		gore.remains_count = 0
		effects._n = 0
		horde.count = 0
		gore._hit_rng.seed = 918 + base
		seed(81073)
		var e := horde.spawn(center + Vector2(20, 0), Horde.Kind.SHAMBLER)
		horde.hp[e] = 1000.0
		horde.max_hp[e] = 1000.0
		var stats: Dictionary = WeaponDefs.BASES[base]
		for pellet in int(stats["proj"]):
			horde.damage(e, float(stats["damage"]), Vector2.RIGHT, float(stats["knock"]), WeaponDefs.Ammo.STANDARD, false, Vector2.INF, base == WeaponDefs.Base.LAUNCHER)
		gore._physics_process(1.0 / 60.0)
		for tick in 18:
			effects._physics_process(1.0 / 60.0)
			gore._physics_process(1.0 / 60.0)
		floor_decals._process(0.3)
		horde.flash[e] = 0.0
		horde._render()
		await RenderingServer.frame_post_draw
		var frame := get_viewport().get_texture().get_image()
		var screen_at := get_viewport().get_canvas_transform() * center
		images.append(frame.get_region(Rect2i(Vector2i(screen_at) - Vector2i(45, 140), Vector2i(510, 280))))
	var sheet := Image.create(2040, 560, false, Image.FORMAT_RGB8)
	for j in images.size():
		sheet.blit_rect(images[j], Rect2i(0, 0, 510, 280), Vector2i(j % 4 * 510, j / 4 * 280))
	sheet.save_png("res://design/tasks/reports/r1c_hits%s.png" % suffix)
	gore.count = 0
	gore.remains_count = 0
	effects._n = 0
	horde.count = 0
	seed(9241)
	gore._hit_rng.seed = 9241
	for j in 12:
		var at := center + Vector2(-180 + (j % 4) * 110, -65 + (j / 4) * 65)
		gore.on_enemy_killed(at, Vector2.RIGHT, Gore.Death.NORMAL if j < 8 else Gore.Death.GIBS, 0.0, j % 7)
	for tick in 24:
		gore._physics_process(1.0 / 60.0)
		effects._physics_process(1.0 / 60.0)
	floor_decals._process(0.4)
	horde._render()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/r1c_death_parts%s.png" % suffix)
	print("R1CSTAND details camera=3 hits_age=300ms deaths_age=400ms suffix=", suffix)
	gore.count = 0
	gore.remains_count = 0
	effects._n = 0

## Подменяются только файловые пути фикстур; условия штатных тестов прежние.
func _r1c_test_paths() -> void:
	DirAccess.make_dir_recursive_absolute("res://design/tasks/reports/R1c_test")
	for entry: Array in [["--meta-test", "res://scripts/meta_test.gd"], ["--q1-test", "res://scripts/meta_test.gd"], ["--campaign-test", "res://scripts/campaign/campaign_test.gd"]]:
		if OS.get_cmdline_user_args().has(entry[0]):
			var script := load(entry[1]) as GDScript
			script.source_code = script.source_code.replace("res://tmp", "res://design/tasks/reports/R1c_test").replace("reports/q1_", "reports/r1c_q1_")
			assert(script.reload() == OK)


func _r1c_checks(p: Vector2) -> bool:
	var ok := true
	effects._n = 0
	gore.count = 0
	gore.remains_count = 0
	gore._hit_rng.seed = 1819
	effects.blood_impact(p, Vector2.RIGHT, 0.6, false, true, gore._hit_rng)
	var destinations := PackedFloat32Array()
	for j in effects._n:
		if effects._bake[j] != 3:
			continue
		# Аналитическое затухание скорости, до исчезновения капли.
		var drag := effects._drag[j]
		var reach := effects._pos[j].distance_to(p) + effects._vel[j].length() / drag * (1.0 - exp(-drag * effects._life[j]))
		destinations.append(reach)
	destinations.sort()
	print("R1C reach heavy_min=%.2f heavy_max=%.2f drops=%d" % [destinations[0], destinations[-1], destinations.size()])
	ok = _gore_check(destinations[0] >= 30.0 and destinations[-1] > 70.0, "r1c_reach_30_90") and ok
	var whole := 0
	var parts := 0
	for j in 100:
		gore.count = 0
		gore.on_enemy_killed(p, Vector2.RIGHT, Gore.Death.NORMAL, 0.0, 0)
		if gore.count == 1:
			whole += 1
		else:
			parts += 1
	print("R1C deaths normal_whole=%d normal_with_parts=%d bone_variants=%d guts=%d organs=%d" % [whole, parts, gore._t_bloody_bones.size(), gore._t_guts.size(), gore._t_organs.size()])
	ok = _gore_check(whole > parts and parts > 0 and gore._t_bloody_bones.size() == 20 and gore._t_organs.size() == 8, "r1c_random_death_parts") and ok
	gore.count = 0
	gore._add(Gore.Kind.CORPSE, gore._t_corpse[0], p, Vector2.ZERO, 0.0, 0.0, Color.WHITE, 5.0, true)
	gore._bake(0)
	gore.count = 0
	gore._r_age[0] = 6.0
	horde.count = 0
	var e := horde.spawn(p + Vector2(20, 0))
	horde._rebuild_grid()
	floor_decals.land_drop(p, 4.0)
	floor_decals.land_drop(p + Vector2(20, 0), 4.0)
	floor_decals._process(0.0)
	ok = _gore_check(gore._r_stain_amount[0] > 0.0 and horde._blood_amount[e] > 0.0 and player._blood_amount > 0.0, "r1c_stain_corpse_live_player") and ok
	var fresh := gore._stain_color(Color.WHITE, Vector2(0.5, 0.5), 1.0, gore._stain_time)
	gore._stain_time += 60.0
	var dry := gore._stain_color(Color.WHITE, Vector2(0.5, 0.5), 1.0, gore._stain_time - 60.0)
	ok = _gore_check(fresh.g > 0.99 and dry.g < 0.04, "r1c_stain_drains_wetness") and ok
	horde._blood_amount[e] = 0.75
	horde.dead[e] = 1
	horde._compact()
	var clean := horde.spawn(p + Vector2(20, 0))
	ok = _gore_check(horde._blood_amount[clean] == 0.0, "r1c_reused_slot_clean") and ok
	gore.count = 0
	gore.remains_count = 0
	effects._n = 0
	return ok


func _r1c_stain_shots(center: Vector2) -> void:
	gore.count = 0
	gore.remains_count = 0
	effects._n = 0
	horde.count = 0
	var original_layout := MapLoader.layout(_map_data, _layout_seed)
	obstacles.setup(ARENA, [
		{"kind": Obstacles.Kind.SEDAN, "pos": center + Vector2(-135, -55), "angle": 0.0},
		{"kind": Obstacles.Kind.JERSEY, "pos": center + Vector2(-30, -55), "angle": 0.0}])
	gore._obstacles = obstacles
	var targets := PackedVector2Array([center + Vector2(-135, -55), center + Vector2(-30, -55), center + Vector2(65, -55), center + Vector2(-110, 45), center + Vector2(-20, 45), center + Vector2(65, 45)])
	player.position = targets[5]
	player._blood_amount = 0.0
	player._blood_material.set_shader_parameter("surface_stain", Vector4(0.5, 0.5, 0, 0))
	var e := horde.spawn(targets[2])
	horde._blood_amount[e] = 0.0
	horde._rebuild_grid()
	gore._add(Gore.Kind.CORPSE, gore._t_corpse[0], targets[3], Vector2.ZERO, 0.0, 0.0, Color.WHITE, 5.0, true)
	gore._bake(0)
	gore.count = 0
	gore._r_age[0] = 6.0
	gore._add(Gore.Kind.GIB, gore._t_bone, targets[4], Vector2.ZERO, 0.0, 0.0, Color.WHITE, 5.0, true)
	gore._bake(0)
	gore.count = 0
	gore._r_age[1] = 2.0
	gore._r_layer.queue_redraw()
	horde._render()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/r1c_stain_before.png")
	for at: Vector2 in targets:
		for k in 6:
			var i := effects.emit(at - Vector2(60, 0) + Vector2(0, float(k - 3) * 0.5), Vector2(200, 0), 0.31, Effects.BLOOD, 3.5, 0.0, true)
			effects._bake[i] = 3
	for tick in 24:
		effects._physics_process(1.0 / 60.0)
		floor_decals._process(1.0 / 60.0)
	player._physics_process(0.0)
	horde._render()
	gore._r_layer.queue_redraw()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/r1c_stain.png")
	print("R1CSTAND stain remains=%s,%s live=%s hero=%s car=%d wall=%d" % [gore._r_stain_amount[0], gore._r_stain_amount[1], horde._blood_amount[e], player._blood_amount, obstacles.blood[0], obstacles.blood[1]])
	obstacles.setup(ARENA, original_layout)
	player.position = center
	player._physics_process(0.0)
	gore.count = 0
	gore.remains_count = 0
	effects._n = 0
	horde.count = 0
	horde._render()


func _r1c_palette_shot(center: Vector2) -> void:
	var samples := Node2D.new()
	$World.add_child(samples)
	var mask := gore._splats[3].get_image()
	var materials: Array[ShaderMaterial] = []
	for surface in 3:
		for age in 3:
			var data := Image.create(mask.get_width(), mask.get_height(), false, Image.FORMAT_RGBA8)
			for y in data.get_height():
				for x in data.get_width():
					var c := mask.get_pixel(x, y)
					var thick := c.r * c.a
					data.set_pixel(x, y, Color(thick, [1.0, 0.25, 0.01][age] * c.a, 0.0, 1.0))
			var sample := Sprite2D.new()
			sample.texture = ImageTexture.create_from_image(data)
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://shaders/blood.gdshader")
			sample.material = mat
			materials.append(mat)
			sample.position = center + Vector2([-245, 0, 220][surface], -55 + age * 65)
			sample.scale = Vector2.ONE * PixelArt.ART_SCALE * 1.1
			samples.add_child(sample)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/r1c_palette.png")
	print("R1CSTAND palette columns=sand,asphalt,tile rows=fresh,half_dry,dry camera=3")
	# Исходный шейдер из HEAD — только для парного сравнения палитры.
	for mat: ShaderMaterial in materials:
		mat.shader = load("res://design/tasks/reports/R1c_blood_before.gdshader") as Shader
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/r1c_palette_before.png")
	samples.queue_free()


## Только пути тестовых фикстур; условия штатных проверок не меняются.
func _r1d_checks(p: Vector2) -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = 110719
	for fan in [false, true]:
		var inside := 0
		var total := 0
		var palette := true
		for repeat_index in 24:
			var dir := Vector2.from_angle(float(repeat_index) * 0.71)
			effects._n = 0
			effects._blood_tokens = 300.0
			effects._blood_frame = -1
			effects.blood_impact(p, dir, float(repeat_index % 6) / 5.0, fan, true, rng)
			for j in effects._n:
				inside += int(absf(effects._vel[j].angle_to(dir)) <= deg_to_rad(40.0))
				total += 1
				var c := effects._col[j]
				palette = palette and c.r <= 0.1951 and c.g <= 0.006 and c.b <= 0.008
		var ratio := float(inside) / total
		print("R1DCHECK hit fan=%s cone40=%.5f samples=%d palette=%s" % [fan, ratio, total, palette])
		ok = _gore_check(ratio >= 0.85 and palette, "r1d_shotgun_cone_palette" if fan else "r1d_bullet_cone_palette") and ok
	for death: int in [Gore.Death.NORMAL, Gore.Death.HEADSHOT, Gore.Death.GIBS, Gore.Death.DECAP, Gore.Death.BISECT]:
		var inside := 0
		var total := 0
		var parts_ok := true
		for repeat_index in 16:
			gore.count = 0
			gore._pending_hits.clear()
			effects._n = 0
			effects._blood_tokens = 300.0
			effects._blood_frame = -1
			horde.count = 0
			var dir := Vector2.from_angle(float(repeat_index) * 1.3)
			var e := horde.spawn(p, Horde.Kind.SHAMBLER)
			horde.death_override = death
			horde.damage(e, 1000.0, dir, 80.0)
			gore._flush_hits(0.1)
			for j in effects._n:
				inside += int(absf(effects._vel[j].angle_to(dir)) <= deg_to_rad(40.0))
				total += 1
			for j in gore.count:
				if gore._kind[j] == Gore.Kind.GIB and gore._vel[j].length_squared() > 1.0:
					parts_ok = parts_ok and absf(gore._vel[j].angle_to(dir)) <= deg_to_rad(40.0)
		var ratio := float(inside) / maxi(total, 1)
		print("R1DCHECK death=%d cone40=%.5f samples=%d parts=%s" % [death, ratio, total, parts_ok])
		ok = _gore_check(ratio >= 0.75 and parts_ok, "r1d_death_%d" % death) and ok
	horde.death_override = -1
	# У ранения плечо и поворот тела не должны разворачивать выходной выброс.
	gore.count = 0
	effects._n = 0
	effects._blood_tokens = 300.0
	effects._blood_frame = -1
	gore.on_enemy_wounded(p, Vector2.RIGHT, PI, 0, 3, PixelArt.WOUND_ARM_L | PixelArt.WOUND_CHEST | PixelArt.WOUND_HEAD)
	var forward := true
	for j in effects._n:
		forward = forward and absf(effects._vel[j].angle()) <= deg_to_rad(40.0)
	ok = _gore_check(forward, "r1d_wound_ignores_facing") and ok
	gore.count = 0
	horde.count = 0
	horde.death_override = Gore.Death.ICE
	for j in 2:
		var e := horde.spawn(p + Vector2(j * 15, 0))
		horde.angle[e] = PI
		horde.damage(e, 1000.0, Vector2.RIGHT if j == 0 else Vector2.UP, 80.0)
	gore._remove(0)
	var carried := gore._impact_dir[0].is_equal_approx(Vector2.UP)
	gore._update_special(0, 1.0)
	for j in gore.count:
		if gore._kind[j] == Gore.Kind.GIB and gore._t_meat.has(gore._tex[j]):
			carried = carried and absf(gore._vel[j].angle_to(Vector2.UP)) < deg_to_rad(40.0)
	ok = _gore_check(carried, "r1d_delayed_ice_direction_compaction") and ok
	var original_at := player.position
	var queued := floor_decals._blood.size()
	floor_decals._player_at = p
	player.position = p + Vector2(8.0, 0.0)
	floor_decals.mark_wet(player.position, 8.0)
	floor_decals._player_steps()
	var stepped: bool = floor_decals._blood.size() == queued + 1 and floor_decals._blood.back()[0] == 3
	floor_decals._player_steps()
	stepped = stepped and floor_decals._blood.size() == queued + 1
	player.position = original_at
	floor_decals._player_at = Vector2.INF
	ok = _gore_check(stepped, "r1d_player_wet_stride_no_idle_stamps") and ok
	horde.death_override = -1
	gore.count = 0
	gore._pending_hits.clear()
	effects._n = 0
	horde.count = 0
	return ok


func _r1d_test_paths() -> void:
	DirAccess.make_dir_recursive_absolute("res://design/tasks/reports/R1d_test")
	for entry: Array in [["--meta-test", "res://scripts/meta_test.gd"], ["--q1-test", "res://scripts/meta_test.gd"], ["--campaign-test", "res://scripts/campaign/campaign_test.gd"]]:
		if OS.get_cmdline_user_args().has(entry[0]):
			var script := load(entry[1]) as GDScript
			script.source_code = script.source_code.replace("res://tmp", "res://design/tasks/reports/R1d_test").replace("reports/q1_", "reports/r1d_q1_")
			assert(script.reload() == OK)


## Сравнимый стенд: двенадцать одинаковых выстрелов, восемь стволов и осевшее тело.
func _run_gore_impact_shots() -> void:
	set_process(false)
	set_physics_process(false)
	spawner.enabled = false
	for node: Node in [$World, $BloodAlarm, $Spawner]:
		node.process_mode = Node.PROCESS_MODE_DISABLED
	camera.target = null
	camera.position_smoothing_enabled = false
	camera.shake_multiplier = 0.0
	camera.zoom = Vector2(3, 3)
	var center := obstacles.free_point(_map_data["start"], 16.0)
	camera.position = center
	player.position = center - Vector2(45, 0)
	if OS.get_cmdline_user_args().has("--gore-retention-checks"):
		await _gore_retention_checks(center)
		return
	var prefix := _shot_path.trim_suffix(".png") if not _shot_path.is_empty() else "res://design/tasks/reports/r1e"
	for group in 3:
		var images: Array[Image] = []
		for j in (12 if group == 0 else 8 if group == 1 else 1):
			await _r1d_clear()
			# Очищаем также постоянный слой останков и гильз.
			floor_decals._stamps.clear()
			floor_decals._remains_stamps.clear()
			floor_decals._vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
			floor_decals._vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			floor_decals._canvas.queue_redraw()
			floor_decals._remains_canvas.queue_redraw()
			seed(81073 + j)
			gore._hit_rng.seed = 81073 + j
			var base: int = [0, 6, 4, 5, 1, 7, 2, 3][j] if group == 1 else WeaponDefs.Base.REVOLVER
			var stats: Dictionary = WeaponDefs.BASES[base]
			var e := horde.spawn(center, Horde.Kind.SHAMBLER)
			horde.visual_code[e] = 0
			horde.angle[e] = 0.4 if group == 2 else j * 0.45
			horde.hp[e] = 25.0 if group == 2 else 1000.0
			horde.max_hp[e] = horde.hp[e]
			for pellet in int(stats["proj"]):
				var contact := center + Vector2(-1, 0) if group == 2 else center + Vector2(-4, (j % 3 - 1) * 3.0)
				horde.damage(e, float(stats["damage"]), Vector2.RIGHT, float(stats["knock"]), WeaponDefs.Ammo.STANDARD, false, contact, base == WeaponDefs.Base.LAUNCHER, base, base in [WeaponDefs.Base.REVOLVER, WeaponDefs.Base.SNIPER, WeaponDefs.Base.RAIL])
			for tick in (300 if group == 2 else 54):
				gore._physics_process(1.0 / 60.0)
				effects._physics_process(1.0 / 60.0)
				floor_decals._process(1.0 / 60.0)
				if tick % 3 == 0:
					await RenderingServer.frame_post_draw
			horde.flash[e] = 0.0
			horde._render()
			await RenderingServer.frame_post_draw
			var frame := get_viewport().get_texture().get_image()
			var at := Vector2i(get_viewport().get_canvas_transform() * center)
			images.append(frame.get_region(Rect2i(at - Vector2i(80, 90), Vector2i(450, 180))))
		var sheet := Image.create(1800 if group < 2 else 450, 540 if group == 0 else 360 if group == 1 else 180, false, Image.FORMAT_RGB8)
		for j in images.size():
			sheet.blit_rect(images[j], Rect2i(0, 0, 450, 180), Vector2i(j % 4 * 450, j / 4 * 180))
		var path: String = prefix + ["_hits_grid.png", "_weapons.png", "_body.png"][group]
		assert(sheet.save_png(path) == OK)
		print("GOREIMPACTSTAND screenshot=", path)
	get_tree().quit()


## Настоящий накопительный RT: переживает вытеснение, старение и последующие записи.
func _gore_retention_checks(center: Vector2) -> void:
	await _r1d_clear()
	floor_decals._stamps.clear()
	floor_decals._vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	floor_decals._vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	floor_decals._canvas.queue_redraw()
	await RenderingServer.frame_post_draw
	var first := floor_decals.remains_baked
	for j in 420:
		var at := center + Vector2((j % 30 - 15) * 7.0, (j / 30 - 7) * 7.0)
		var i := gore._add(Gore.Kind.GIB, gore._t_organs[j % 8], at, Vector2.ZERO, j * 0.3, 0.0, Color.WHITE, 5.0, true)
		assert(gore._bake(i))
		gore.count = 0
		if j % 100 == 99:
			floor_decals._process(0.0)
			await RenderingServer.frame_post_draw
	gore._age_remains(181.0)
	floor_decals._process(0.0)
	await RenderingServer.frame_post_draw
	var before := floor_decals._vp.get_texture().get_image()
	var visible := 0
	for y in range(before.get_height()):
		for x in range(before.get_width()):
			if before.get_pixel(x, y).a > 0.1:
				visible += 1
	for j in 6:
		floor_decals._process(100.0)
		await RenderingServer.frame_post_draw
	# Ещё одна запись в стороне не должна повторять/стирать прошлый набор команд.
	floor_decals.bake_remains(gore._textures[gore._t_brain], center + Vector2(200, 0), 0.0, Vector2.ONE, Color.WHITE)
	floor_decals._process(0.0)
	await RenderingServer.frame_post_draw
	var late := floor_decals._vp.get_texture().get_image()
	var retained := 0
	for y in range(before.get_height()):
		for x in range(before.get_width()):
			if before.get_pixel(x, y).a > 0.1 and before.get_pixel(x, y).is_equal_approx(late.get_pixel(x, y)):
				retained += 1
	var ok := visible > 1000 and retained == visible and floor_decals.remains_baked - first == 421 and gore.remains_count == 0
	print("GORERETENTION actual_RT=true baked=%d visible_pixels=%d retained_after_600s=%d active=%d ok=%s" % [floor_decals.remains_baked - first, visible, retained, gore.remains_count, ok])
	assert(late.save_png("res://design/tasks/reports/r1e_remains_rt.png") == OK)
	get_tree().quit(0 if ok else 1)


func _run_r1d_shots() -> void:
	set_process(false)
	set_physics_process(false)
	spawner.enabled = false
	for node: Node in [$World, $BloodAlarm, $Spawner]:
		node.process_mode = Node.PROCESS_MODE_DISABLED
	camera.target = null
	camera.position_smoothing_enabled = false
	camera.shake_multiplier = 0.0
	camera.zoom = Vector2(3, 3)
	var center := obstacles.free_point(_map_data["start"], 16.0)
	camera.position = center
	player.position = center
	if OS.get_cmdline_user_args().has("--r1d-retention"):
		await _r1d_retention(center)
		return
	await _r1d_details(center)
	get_tree().quit()


func _r1d_retention(center: Vector2) -> void:
	await _r1d_clear()
	floor_decals.blood(floor_decals._pool_masks[0], center, 0.0, 1.0, 1.0)
	floor_decals._process(0.0)
	await RenderingServer.frame_post_draw
	var density := float(floor_decals._blood_vp.size.x) / ARENA.size.x
	var pixel := Vector2i((center - floor_decals._origin) * density)
	var image := floor_decals._blood_vp.get_texture().get_image()
	var fresh := image.get_pixelv(pixel)
	var sample_center := pixel
	# Самая густая точка реального пятна, независимо от сухого островка под центром.
	for y in range(sample_center.y - 30, sample_center.y + 30):
		for x in range(sample_center.x - 40, sample_center.x + 40):
			var sample := image.get_pixel(x, y)
			if sample.r > fresh.r:
				fresh = sample
				pixel = Vector2i(x, y)
	for second in 600:
		floor_decals._process(1.0)
		await RenderingServer.frame_post_draw
	var dried := floor_decals._blood_vp.get_texture().get_image().get_pixelv(pixel)
	var ok := fresh.r > 0.2 and is_equal_approx(fresh.r, dried.r) and dried.g < fresh.g * 0.1
	var rt_bytes := (floor_decals._blood_vp.size.x * floor_decals._blood_vp.size.y + floor_decals._vp.size.x * floor_decals._vp.size.y) * 4
	print("R1DCHECK actual_RT_600s=%s fresh=%s dried=%s size=%s bytes_two_RGBA8=%d" % [ok, fresh, dried, floor_decals._blood_vp.size, rt_bytes])
	# Повторная бойня остаётся локальной, с разной толщиной и мягкой альфой.
	for layer in 80:
		for spot in 6:
			var at := center + Vector2((spot % 3 - 1) * 48, (spot / 3 * 2 - 1) * 32)
			floor_decals.blood(floor_decals._pool_masks[spot], at, spot * 0.7, 1.2, 0.55)
		floor_decals._process(0.5)
		await RenderingServer.frame_post_draw
	image = floor_decals._blood_vp.get_texture().get_image()
	var middle := Vector2i((center - floor_decals._origin) * density)
	var lo := 1.0
	var hi := 0.0
	var gaps := 0
	var soft := 0
	for y in range(middle.y - 90, middle.y + 90):
		for x in range(middle.x - 130, middle.x + 130):
			var sample := image.get_pixel(x, y)
			if sample.a < 0.03:
				gaps += 1
			elif sample.a > 0.9:
				lo = minf(lo, sample.r)
				hi = maxf(hi, sample.r)
			else:
				soft += 1
	var localized := image.get_pixelv(middle + Vector2i(250, 0)).a < 0.01
	var varied := hi - lo > 0.3 and gaps > 1000 and soft > 100 and localized
	print("R1DCHECK repeated_spill_varied=%s thickness=%.3f..%.3f gaps=%d soft=%d localized=%s" % [varied, lo, hi, gaps, soft, localized])
	ok = ok and varied
	get_tree().quit(0 if ok else 1)


func _r1d_clear() -> void:
	gore.count = 0
	gore.remains_count = 0
	gore._pending_hits.clear()
	gore._pulses.clear()
	floor_decals._remains_stamps.clear()
	floor_decals._remains_cover.fill(0)
	effects._n = 0
	effects._blood_tokens = 300.0
	effects._blood_frame = -1
	horde.count = 0
	floor_decals._blood.clear()
	floor_decals._pool_tex.clear()
	floor_decals._pool_pos.clear()
	floor_decals._pool_rot.clear()
	floor_decals._pool_scale.clear()
	floor_decals._pool_age.clear()
	floor_decals._pool_step.clear()
	floor_decals._coverage.fill(0.0)
	floor_decals._player_at = Vector2.INF
	floor_decals._player_feet = 0
	floor_decals._player_stride = 0.0
	floor_decals._blood_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	floor_decals._process(0.0)
	floor_decals._blood_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	floor_decals._blood_canvas.queue_redraw()
	horde._render()
	gore.queue_redraw()
	gore._r_layer.queue_redraw()
	effects.queue_redraw()
	await RenderingServer.frame_post_draw


## Один и тот же стенд до/после: без изменения камеры и масштаба пикселей.
func _r1d_details(center: Vector2) -> void:
	var suffix := "_before" if OS.get_cmdline_user_args().has("--r1d-before") else ""
	var images: Array[Image] = []
	for base: int in [0, 6, 4, 5, 1, 7, 2, 3]:
		await _r1d_clear()
		gore._hit_rng.seed = 918 + base
		seed(81073)
		var e := horde.spawn(center + Vector2(20, 0), Horde.Kind.SHAMBLER)
		horde.hp[e] = 1000.0
		horde.max_hp[e] = 1000.0
		var stats: Dictionary = WeaponDefs.BASES[base]
		for pellet in int(stats["proj"]):
			horde.damage(e, float(stats["damage"]), Vector2.RIGHT, float(stats["knock"]), WeaponDefs.Ammo.STANDARD, false, Vector2.INF, base == WeaponDefs.Base.LAUNCHER)
		for tick in 18:
			gore._physics_process(1.0 / 60.0)
			effects._physics_process(1.0 / 60.0)
			floor_decals._process(1.0 / 60.0)
			await RenderingServer.frame_post_draw
		horde.flash[e] = 0.0
		horde._render()
		await RenderingServer.frame_post_draw
		var frame := get_viewport().get_texture().get_image()
		var screen_at := get_viewport().get_canvas_transform() * center
		images.append(frame.get_region(Rect2i(Vector2i(screen_at) - Vector2i(45, 140), Vector2i(510, 280))))
	var sheet := Image.create(2040, 560, false, Image.FORMAT_RGB8)
	for j in images.size():
		sheet.blit_rect(images[j], Rect2i(0, 0, 510, 280), Vector2i(j % 4 * 510, j / 4 * 280))
	assert(sheet.save_png("res://design/tasks/reports/r1d_hits%s.png" % suffix) == OK)
	await _r1d_clear()
	seed(9241)
	gore._hit_rng.seed = 9241
	for j in 8:
		var at := center + Vector2(-210 + (j % 4) * 135, -65 + (j / 4) * 115)
		var dir := Vector2.from_angle([0.0, PI * 0.5, PI, -PI * 0.5][j % 4])
		var e := horde.spawn(at, Horde.Kind.SHAMBLER)
		horde.death_override = Gore.Death.NORMAL if j < 4 else Gore.Death.GIBS
		horde.damage(e, 1000.0, dir, 70.0)
	horde.count = 0
	horde.death_override = -1
	for tick in 30:
		gore._physics_process(1.0 / 60.0)
		effects._physics_process(1.0 / 60.0)
		floor_decals._process(1.0 / 60.0)
		await RenderingServer.frame_post_draw
	horde._render()
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/r1d_kill_dir%s.png" % suffix) == OK)
	print("R1DSTAND hits=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=300ms camera=3 suffix=", suffix)
	await _r1d_clear()
	await _r1d_palette(center, suffix)


func _r1d_palette(center: Vector2, suffix: String) -> void:
	var samples := Node2D.new()
	$World.add_child(samples)
	var ground_image := PixelArt.tex("map_ground").get_image()
	for surface in 3:
		var bg := Sprite2D.new()
		bg.texture = PixelArt.tex("asphalt") if surface == 0 else ImageTexture.create_from_image(ground_image.get_region(Rect2i(0, (5 if surface == 1 else 7) * 64, 64, 64)))
		bg.position = center + Vector2((surface - 1) * 185, 0)
		bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		bg.region_enabled = true
		bg.region_rect = Rect2(0, 0, 510, 720)
		bg.scale = Vector2.ONE / 3.0
		samples.add_child(bg)
		for age in 3:
			# Контрольные полосы толщины дают точные пиксели без градиента маски.
			var data := Image.create(120, 60, false, Image.FORMAT_RGBA8)
			for y in 60:
				for x in 120:
					data.set_pixel(x, y, Color(0.07 if x < 60 else 1.0, [1.0, 0.25, 0.0][age], 0.0, 1.0))
			var sample := Sprite2D.new()
			sample.texture = ImageTexture.create_from_image(data)
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://shaders/blood.gdshader")
			sample.material = mat
			sample.position = bg.position + Vector2(0, -75 + age * 75)
			samples.add_child(sample)
	await RenderingServer.frame_post_draw
	var frame := get_viewport().get_texture().get_image()
	assert(frame.save_png("res://design/tasks/reports/r1d_palette%s.png" % suffix) == OK)
	var palette_ok := true
	for surface in 3:
		for age in 3:
			var screen := get_viewport().get_canvas_transform() * (center + Vector2((surface - 1) * 185, -75 + age * 75))
			var thin := frame.get_pixelv(Vector2i(screen) - Vector2i(60, 0))
			var thick := frame.get_pixelv(Vector2i(screen) + Vector2i(60, 0))
			print("R1DPALETTE surface=%d age=%d thin=%s thick=%s" % [surface, age, thin.to_html(false), thick.to_html(false)])
			if age == 0:
				palette_ok = palette_ok and thin.r >= 0.4 and thin.r <= 0.5 and thin.g < 0.075 and thin.b < 0.10
				palette_ok = palette_ok and thick.r >= 0.12 and thick.r <= 0.25 and thick.g < 0.04 and thick.b < 0.05
			elif age == 2:
				palette_ok = palette_ok and thin.r < 0.23 and thick.r < 0.13 and thick.g < 0.05
	if suffix.is_empty():
		print("R1DCHECK palette_pixels=", palette_ok)
		assert(palette_ok)
	samples.queue_free()
	await RenderingServer.frame_post_draw


func _z1_test_paths() -> void:
	DirAccess.make_dir_recursive_absolute("res://design/tasks/reports/Z1_test")
	for entry: Array in [["--meta-test", "res://scripts/meta_test.gd"], ["--q1-test", "res://scripts/meta_test.gd"], ["--campaign-test", "res://scripts/campaign/campaign_test.gd"]]:
		if OS.get_cmdline_user_args().has(entry[0]):
			var script := load(entry[1]) as GDScript
			script.source_code = script.source_code.replace("res://tmp", "res://design/tasks/reports/Z1_test").replace("reports/q1_", "reports/z1_q1_")
			assert(script.reload() == OK)


## Повторяемая бойня: 300 живых, пол после 1200 смертей, камера 3.
func _run_z1_shots() -> void:
	set_process(false)
	set_physics_process(false)
	spawner.enabled = false
	for node: Node in [$World, $BloodAlarm, $Spawner]:
		node.process_mode = Node.PROCESS_MODE_DISABLED
	announce_t = 0.0
	player.god_mode = true
	camera.target = null
	camera.position_smoothing_enabled = false
	camera.shake_multiplier = 0.0
	camera.zoom = Vector2(3, 3)
	var center := obstacles.free_point(_map_data["start"], 16.0)
	camera.position = center
	player.position = center
	player.aim_dir = Vector2.RIGHT
	player._physics_process(0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 92071
	seed(92071)
	for second in 100:
		for j in 12:
			var at := center + Vector2(rng.randf_range(-235, 240), rng.randf_range(-105, 100))
			var v := rng.randi_range(0, PixelArt.VARIANT_COUNT - 1)
			gore.on_enemy_killed(at, (at - center).normalized(), j % 7, rng.randf() * TAU, v)
		for tick in 5:
			gore._physics_process(0.2)
			effects._physics_process(0.2)
			floor_decals._process(0.2)
		await RenderingServer.frame_post_draw
	horde.count = 0
	for j in 300:
		var at := center + Vector2(-280 + (j % 25) * 23 + rng.randf_range(-5, 5), -122 + (j / 25) * 22 + rng.randf_range(-4, 4))
		if at.distance_to(center) < 37:
			at += Vector2(38, 0)
		var k := Horde.Kind.SHAMBLER if j % 10 < 6 else Horde.Kind.RUNNER if j % 10 < 8 else Horde.Kind.FAT if j % 10 == 8 else Horde.Kind.SPITTER
		var e := horde.spawn(obstacles.free_point(at, 7.0), k, j % 47 == 0)
		horde.angle[e] = (center - at).angle()
	horde._rebuild_grid()
	for e in horde.count:
		if e % 7 == 0:
			horde.damage(e, horde.hp[e] * 0.16, (horde.pos[e] - center).normalized(), 45.0)
	gore._physics_process(0.016)
	effects._physics_process(0.065)
	floor_decals._process(0.065)
	horde._render()
	horde.queue_redraw()
	effects.queue_redraw()
	hazards.acid_pool(center + Vector2(40, 42), 18.0, 5.0, 30.0)
	hazards.queue_redraw()
	pickups.spawn(center + Vector2(-38, 30), Pickups.Kind.MEDKIT)
	pickups.queue_redraw()
	_update_view()
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(_shot_path) == OK)
	print("Z1STAND crowd=", horde.count, " deaths=1200 seed=92071 camera=3 path=", _shot_path)
	if OS.get_cmdline_user_args().has("--z1-gallery"):
		await _z1_gallery(center)
	get_tree().quit()


## Контактный лист: живой, тело, обезглавленный, верх и крупные части.
func _z1_gallery(center: Vector2) -> void:
	obstacles.visible = false
	horde.count = 0
	gore.count = 0
	gore.remains_count = 0
	effects._n = 0
	hazards.clear()
	var labels := Node2D.new()
	$World.add_child(labels)
	labels.z_index = 100
	var captions: Array = []
	for v in PixelArt.VARIANT_COUNT:
		var at := center + Vector2(-250 + (v % 7) * 82, -85 + (v / 7) * 84)
		var i := horde.spawn(at, PixelArt.variant_kind(v))
		var tone := v % PixelArt.CLOTH_TONES
		var appearance := v + tone * PixelArt.VARIANT_COUNT
		horde.variant[i] = v
		horde.visual_code[i] = appearance + 64 * 9
		horde.body_scale[i] = 1.0
		horde.seed_value[i] = (float(tone) + 0.5) / 3.0
		horde.angle[i] = 0.0
		horde.wounds[i] = PixelArt.WOUND_ARM_L if v == 15 else 0
		captions.append([at + Vector2(-15, -14), "%02d %s" % [v, PixelArt.VARIANT_NAMES[v]]])
		for part in 3:
			gore._add(Gore.Kind.CORPSE, [gore._t_corpse[appearance * 3], gore._t_walker[appearance], gore._t_top[appearance]][part], at + Vector2(-20 + part * 20, 23), Vector2.ZERO, 0.0, 0.0, Color.WHITE, 0.0, false, 20.0)
		for part in 3:
			gore._add(Gore.Kind.GIB, [gore._t_head[appearance], gore._t_arm[appearance], gore._t_torso[appearance]][part], at + Vector2(-17 + part * 17, 43), Vector2.ZERO, 0.0, 0.0, Color.WHITE, 0.0, false, 20.0)
	labels.draw.connect(func() -> void:
		for caption: Array in captions:
			labels.draw_string(ThemeDB.fallback_font, caption[0], caption[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(0.9, 0.88, 0.8)))
	horde._render()
	horde.queue_redraw()
	gore.queue_redraw()
	effects.queue_redraw()
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/z1_parts.png") == OK)
	print("Z1STAND gallery variants=21 tones=3 live/corpse/headless/top/head/arm/torso camera=3")
	labels.queue_free()
	horde.count = 0
	gore.count = 0
	var samples := [7, 8, 9, 10, 11, 13, 14, 15, 16, 17, 18, 19]
	for j in samples.size():
		var at := center + Vector2(-230 + (j % 6) * 90, -65 + (j / 6) * 130)
		var v: int = samples[j]
		var i := horde.spawn(at, PixelArt.variant_kind(v), j % 6 == 5)
		var tone := j % 3
		horde.variant[i] = v
		horde.body_scale[i] = 1.04
		horde.visual_code[i] = v + tone * PixelArt.VARIANT_COUNT + 64 * (13 + (32 if j % 2 else 0) + (64 if j % 6 == 5 else 0))
		horde.seed_value[i] = (float(tone) + 0.5) / 3.0
		horde.angle[i] = 0.0
		horde.wounds[i] = PixelArt.WOUND_ARM_L if v == 15 else 0
	horde._render()
	gore.queue_redraw()
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/z1_corpses_alive.png") == OK)
	for j in horde.count:
		horde.death_override = [Gore.Death.NORMAL, Gore.Death.DECAP, Gore.Death.BISECT, Gore.Death.GIBS][j % 4]
		horde.damage(j, horde.hp[j] + 1.0, Vector2.RIGHT, 60.0)
	horde._compact()
	for tick in 4:
		gore._physics_process(0.025)
		effects._physics_process(0.025)
		floor_decals._process(0.025)
	horde._render()
	gore.queue_redraw()
	effects.queue_redraw()
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/z1_corpses.png") == OK)
	print("Z1STAND actual_deaths=12 age=100ms normal/decap/bisect/gibs matching_tone_size_mirror=true")


func _director_sound() -> void:
	var d := spawner.director
	if d == null or d.warning_left <= 0.0:
		return
	if d.warning_serial != _director_warning:
		_director_warning = d.warning_serial
		_director_cue = 0
		_director_audio_at = time
	if _director_cue >= d.warning_points.size() or time < _director_audio_at:
		return
	var direction := (d.warning_points[_director_cue] - player.position).normalized()
	sfx.play(Sfx.DIRECTOR_CUES["fast" if d.warning_fast[_director_cue] else "front"], player.position + direction * 180.0, 1.0, 0.02)
	_director_cue += 1
	_director_audio_at = time + 0.16


func _director_live_shot() -> void:
	await RenderingServer.frame_post_draw
	if OS.get_cmdline_user_args().has("--map-capture-live"):
		var prefix := _shot_path.get_basename() if not _shot_path.is_empty() else "res://design/tasks/reports/map_" + _map_id
		var frame := get_viewport().get_texture().get_image()
		frame.save_png(prefix + "_fight.png")
		frame.convert(Image.FORMAT_L8)
		frame.save_png(prefix + "_gray.png")
		print("MAPSHOT live=true time=%.2f map=%s enemies=%d kills=%d gray=true" % [time, _map_id, horde.count, kills])
		return
	get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/hd1_fight_5min.png")
	print("DIRECTORSHOT live=true time=", time, " path=hd1_fight_5min.png")


func _director_freeze() -> void:
	set_physics_process(false)
	set_process(false)
	spawner.enabled = false
	spawner.set_physics_process(false)
	blood_alarm.set_physics_process(false)
	player.god_mode = true
	player.set_physics_process(false)
	weapons.set_physics_process(false)
	horde.set_physics_process(false)
	hazards.set_physics_process(false)
	obstacles.set_physics_process(false)
	activities.set_physics_process(false)
	pickups.set_physics_process(false)
	gems.set_physics_process(false)
	credit_drops.set_physics_process(false)
	camera.target = null
	camera.position_smoothing_enabled = false
	camera.shake_multiplier = 0.0


func _director_check(ok: bool, label: String) -> int:
	if not ok:
		print("DIRECTORTEST FAILED ", label)
	return 0 if ok else 1


func _run_director_test() -> void:
	_director_freeze()
	seed(81073)
	horde.reset_variety_seed(81073)
	var failures := 0
	var cases := 0
	var penetrations := 0
	for id: String in MapLoader.IDS:
		var data := MapLoader.load_map(id)
		var rect := Rect2(Vector2.ZERO, data["size"])
		obstacles.setup(rect, MapLoader.layout(data, 81073))
		horde.setup(rect, player, null)
		horde.map_entries = data["spawn_points"]
		horde.far_distance = 5000.0
		for place in 3:
			player.position = obstacles.free_point(data["start"] + Vector2(place * 80, place * 55), 32.0)
			camera.position = player.position
			camera.force_update_scroll()
			while obstacles._target_cell != obstacles.cell_at(obstacles.free_point(player.position, 19.0)):
				obstacles.navigation_step(0.2, player.position)
			for pattern in HordeDirector.NAMES.size():
				horde.count = 0
				horde.release_groups()
				var d := HordeDirector.new()
				d.setup(horde, player, 81073, id)
				d.force_pattern(pattern, 0.0, 300.0)
				var sources := d._origins
				var valid := true
				for at in sources:
					valid = valid and not PixelArt.view_rect(horde, 20.0).has_point(at) and not obstacles.contains(at, 19.0)
				var shape := true
				if pattern == HordeDirector.Pattern.PINCER:
					shape = sources.size() == 2
					if shape:
						shape = (sources[0] - player.position).normalized().dot((sources[1] - player.position).normalized()) < -0.65
				elif pattern == HordeDirector.Pattern.RING:
					shape = sources.size() >= 4
					for at in sources:
						shape = shape and absf(angle_difference(d.gap_angle, (at - player.position).angle())) >= 0.70
				elif pattern == HordeDirector.Pattern.TIDE:
					shape = sources.size() >= 3
				elif pattern == HordeDirector.Pattern.FLANK:
					shape = sources.size() == 2
				elif pattern == HordeDirector.Pattern.REST:
					shape = sources.is_empty()
				else:
					shape = sources.size() == 1
				failures += _director_check(valid and shape, "shape_%s_%d_%s lanes=%d" % [id, place, HordeDirector.NAMES[pattern], sources.size()])
				var made := d.spawn_group(60, [100, 0, 0, 0], false, 300.0)
				var initial := PackedVector2Array()
				for i in horde.count:
					initial.append(horde.pos[i])
				var moved := 0
				var closure := 0.0
				for frame in 720:
					obstacles.navigation_step(1.0 / 60.0, player.position)
					horde._physics_process(1.0 / 60.0)
					if frame % 30 == 0:
						for i in horde.count:
							if obstacles.contains(horde.pos[i], horde.radius[i] - 0.05):
								penetrations += 1
				for i in horde.count:
					closure += initial[i].distance_to(player.position) - horde.pos[i].distance_to(player.position)
					if horde.pos[i].distance_to(initial[i]) > 30.0:
						moved += 1
					elif pattern != HordeDirector.Pattern.REST:
						print("DIRECTORTEST stopped map=%s place=%d pattern=%s i=%d from=%s at=%s radius=%.3f group=%d" % [id, place, HordeDirector.NAMES[pattern], i, initial[i], horde.pos[i], horde.radius[i], horde.group_id[i]])
						print("DIRECTORTEST stopped goal=%s normal=%s stuck=%.3f" % [player.position, obstacles.wall_normal[obstacles.cell_at(horde.pos[i])], horde._stuck_time[i]])
				if pattern in [HordeDirector.Pattern.PINCER, HordeDirector.Pattern.RING]:
					failures += _director_check(closure / maxf(made, 1.0) > 20.0, "compression_%s_%d_%s" % [id, place, HordeDirector.NAMES[pattern]])
				failures += _director_check(moved == made and (made == 60 or pattern == HordeDirector.Pattern.REST), "movement_%s_%d_%s moved=%d/%d" % [id, place, HordeDirector.NAMES[pattern], moved, made])
				# Конечный срок обязан снять маршрут даже у агента в тупике.
				horde._time += 40.0
				horde._move(1.0 / 60.0)
				var released := true
				for i in horde.count:
					released = released and horde.group_id[i] == 0
				failures += _director_check(released, "expire_%s_%s" % [id, HordeDirector.NAMES[pattern]])
				cases += 1
				print("DIRECTORTEST form map=%s place=%d pattern=%s lanes=%d moved=%d/%d penetrations=%d" % [id, place, HordeDirector.NAMES[pattern], sources.size(), moved, made, penetrations])
				if pattern in [HordeDirector.Pattern.RUSH, HordeDirector.Pattern.FLANK]:
					horde.count = 0
					d.force_pattern(pattern, 0.0, 300.0)
					d.spawn_group(20, [60, 40, 0, 0], true, 300.0)
					var fast_lane := 1 if pattern == HordeDirector.Pattern.FLANK else 0
					var fast_ok := horde.count == 20
					for i in horde.count:
						fast_ok = fast_ok and horde.kind[i] == Horde.Kind.RUNNER and horde.group_id[i] == d._groups[fast_lane]
					failures += _director_check(fast_ok, "actual_fast_side_%s_%d_%s" % [id, place, HordeDirector.NAMES[pattern]])
				await get_tree().process_frame
	# Реальный spawner с освобождением слотов имитирует неограниченное убийство.
	horde.count = 0
	spawner.enabled = true
	spawner.set_profile({})
	spawner._objective_row.clear()
	spawner._budget = 0.0
	spawner._next_group = 4
	spawner._next_elite = Spawner.ELITE_START
	spawner.total_spawned = 0
	spawner.curve_budget = 0.0
	spawner.director_exclusive = false
	spawner.director = HordeDirector.new()
	spawner.director.setup(horde, player, 81073, "open_perimeter")
	var replay := HordeDirector.new()
	replay.setup(horde, player, 81073, "open_perimeter")
	var deterministic := true
	var caps := true
	var two_fast := false
	for frame in 36000:
		var now := float(frame) / 60.0
		spawner.time = now
		spawner.alarm = now >= 423.0 and now < 453.0
		horde.count = 0
		spawner._physics_process(1.0 / 60.0)
		replay.advance(now, 1.0 / 60.0, spawner.current_row()[3], spawner.alarm)
		deterministic = deterministic and replay.pattern == spawner.director.pattern and replay.phase == spawner.director.phase
		caps = caps and horde.count <= int(spawner.current_row()[2])
		var fast_sides := 0
		for flag in spawner.director.warning_fast:
			fast_sides += flag
		two_fast = two_fast or fast_sides > 1
		if frame % 600 == 599:
			await get_tree().process_frame
	var curve_600 := spawner.curve_budget
	var planned_600 := spawner.director.planned
	var issued_600 := spawner.total_spawned
	var ratio := planned_600 / curve_600
	failures += _director_check(absf(ratio - 1.0) <= 0.10 and absf(float(spawner.total_spawned) / spawner.curve_budget - 1.0) <= 0.10, "600s_budget")
	failures += _director_check(deterministic and caps and not two_fast, "seed_cap_one_fast_side")
	# Полный cap вместе с элитой; невыданное не разрастается в очередь.
	horde.count = int(spawner.current_row()[2])
	var before := horde.count
	spawner.spawn_elites(4)
	for frame in 600:
		spawner._physics_process(1.0 / 60.0)
	failures += _director_check(horde.count == before and spawner._budget <= spawner._next_group, "cap_elites_no_debt")
	# Перенос packed-метаданных и сброс нового спавна.
	horde.count = 0
	var first := horde.spawn(player.position + Vector2(200, 0))
	var second := horde.spawn(player.position + Vector2(220, 0))
	var token := horde.make_group(20.0)
	horde.attach_group(second, token)
	horde.dead[first] = 1
	horde._compact()
	failures += _director_check(horde.group_id[0] == token, "compact")
	var fresh := horde.spawn(player.position + Vector2(230, 0))
	failures += _director_check(horde.group_id[fresh] == 0, "spawn_reset")
	# Старый id не наследует маршрут при обороте фиксированного пула.
	for j in Horde.GROUP_CAPACITY:
		horde.make_group(20.0)
	horde._group_direction(0, Vector2.RIGHT)
	failures += _director_check(horde.group_id[0] == 0, "group_generation")
	spawner.director._roles.fill(0)
	var roles_ok := spawner.director.accept_kind(Horde.Kind.RUNNER) == Horde.Kind.RUNNER
	roles_ok = roles_ok and HordeDirector._role_of(spawner.director.accept_kind(Horde.Kind.FAT)) == 2
	roles_ok = roles_ok and spawner.director.accept_kind(Horde.Kind.SPITTER) == Horde.Kind.SHAMBLER
	failures += _director_check(roles_ok, "two_special_roles")
	# Безопасность обычного режима: разнесённые клещи, единый быстрый край, низкое HP.
	horde.count = 0
	spawner.director.force_pattern(HordeDirector.Pattern.PINCER, 0.0, 320.0)
	spawner.director._forced = false
	spawner.director.spawn_group(8, [100, 0, 0, 0], false, 323.5)
	var staggered := horde.count == 8
	for i in horde.count:
		staggered = staggered and horde.group_id[i] == spawner.director._groups[0]
	failures += _director_check(staggered, "pincer_stagger")
	var first_side := spawner.director._origins[0]
	spawner.director.fast_origin = first_side
	spawner.director._fast_until = 330.0
	var held := spawner.director.fast_source(spawner.director._origins[1])
	failures += _director_check(held != Vector2.INF and (held - player.position).normalized().dot((first_side - player.position).normalized()) > 0.8, "fast_edge_survives_replan")
	var saved_hp := player.hp
	player.hp = player.max_hp * 0.2
	spawner.director.sample(324.0, 0)
	var recovery := spawner.director.shape_count(12, 324.0) == 0 and spawner.director._groups.is_empty()
	recovery = recovery and spawner.director.advance(324.0, 0.1, [60, 20, 10, 10], false) == 1.0
	failures += _director_check(recovery, "low_hp_no_compression")
	player.hp = saved_hp
	# Событие снимает групповые цели и предупреждения, не меняя его темп.
	spawner.director.force_pattern(HordeDirector.Pattern.PINCER, 0.0, 320.0)
	var event_rate := spawner.director.advance(320.0, 0.1, [60, 20, 10, 10], true)
	failures += _director_check(event_rate == 1.0 and spawner.director.suspended and spawner.director.warning_left == 0.0 and spawner.director._origins.is_empty(), "event_priority")
	failures += _director_check(penetrations == 0, "no_penetrations")
	print("DIRECTORTEST cases=%d failures=%d penetrations=%d budget=%.2f planned=%.2f issued=%d ratio=%.5f seed=%s cap=%s one_fast_side=%s ok=%s" % [cases, failures, penetrations, curve_600, planned_600, issued_600, ratio, deterministic, caps, not two_fast, failures == 0])
	Meta.finish_test(0 if failures == 0 else 1)


func _run_director_shots() -> void:
	_director_freeze()
	seed(81073)
	time = 300.0
	trader_visit = 1
	player.position = obstacles.free_point(Vector2(1280, 1050), 32.0)
	player.aim_dir = Vector2.RIGHT
	player.force_auto_aim = true
	player._physics_process(0.0)
	weapons._update_gun_layers()
	camera.position = player.position
	camera.force_update_scroll()
	while obstacles._target_cell != obstacles.cell_at(obstacles.free_point(player.position, 19.0)):
		obstacles.navigation_step(0.2, player.position)
	for pattern in HordeDirector.NAMES.size():
		horde.count = 0
		horde.release_groups()
		var d := spawner.director
		d.force_pattern(pattern, 0.0, 300.0)
		var amount := 120
		if pattern == HordeDirector.Pattern.REST:
			amount = 0
		var runners := pattern in [HordeDirector.Pattern.RUSH, HordeDirector.Pattern.FLANK]
		d.spawn_group(amount / 2 if pattern == HordeDirector.Pattern.FLANK else amount, [100, 0, 0, 0], false, 300.0)
		if runners:
			horde.count = 0 if pattern == HordeDirector.Pattern.RUSH else horde.count
			d.spawn_group(70 if pattern == HordeDirector.Pattern.RUSH else amount / 2, [60, 40, 0, 0], true, 300.0)
		for stage in 2:
			var frames := (110 if stage == 0 else 70) if pattern == HordeDirector.Pattern.RUSH else (210 if stage == 0 else 120)
			if pattern == HordeDirector.Pattern.COLUMN:
				frames = 120 if stage == 0 else 90
			elif pattern == HordeDirector.Pattern.AMBUSH:
				frames = 1200 if stage == 0 else 90
			for frame in frames:
				obstacles.navigation_step(1.0 / 60.0, player.position)
				horde._physics_process(1.0 / 60.0)
				if pattern == HordeDirector.Pattern.AMBUSH and stage == 0 and frame % 6 == 0:
					var visible_count := 0
					var view := PixelArt.view_rect(horde, -25.0)
					for i in horde.count:
						visible_count += 1 if view.has_point(horde.pos[i]) else 0
					if visible_count >= 10:
						break
				if frame % 30 == 29:
					await get_tree().process_frame
			d.warning_left = 3.0
			await RenderingServer.frame_post_draw
			var path := "res://design/tasks/reports/hd1_%s%s.png" % [HordeDirector.NAMES[pattern], "_start" if stage == 0 else ""]
			get_viewport().get_texture().get_image().save_png(path)
			print("DIRECTORSHOT pattern=%s stage=%d alive=%d path=%s" % [HordeDirector.NAMES[pattern], stage, horde.count, path])
	print("DIRECTORSHOTS ok=true viewport=true camera=standard")
	Meta.finish_test()


var _armor_checks := 0
var _armor_failed := 0


func _armor_check(label: String, passed: bool) -> void:
	_armor_checks += 1
	if not passed:
		_armor_failed += 1
		print("ARMORFAIL ", label)


func _armor_dummy(k: int) -> int:
	horde.count = 0
	horde.minutes = 0.0
	var i := horde.spawn(ARENA.get_center(), k)
	horde.hp[i] = Horde.KINDS[k]["hp"]
	horde.max_hp[i] = horde.hp[i]
	horde.angle[i] = 0.0
	return i


func _run_armor_test() -> void:
	$World.process_mode = Node.PROCESS_MODE_DISABLED
	spawner.enabled = false
	set_physics_process(false)
	set_process(false)
	seed(81073)
	var pieces: Array[int] = []
	var collect := func(_at: Vector2, _dir: Vector2, _facing: float, _code: int, part: int) -> void: pieces.append(part)
	horde.armor_detached.connect(collect)
	var e := _armor_dummy(Horde.Kind.INFANTRY)
	var initial_hp := horde.hp[e]
	var blood_events: Array[int] = []
	var blood := func(_p: Vector2, _d: Vector2, _v: int, _a: float, _k: float, id: int, _ex: bool) -> void: blood_events.append(id)
	horde.enemy_impact.connect(blood)
	horde.damage(e, 7.0, Vector2.LEFT, 0.0, 0, false, horde.pos[e], false, 0, false, 0.0)
	_armor_check("rifle absorbs without blood", horde.hp[e] == initial_hp and blood_events.is_empty() and horde.armor_chest[e] == 15.0)
	for j in 3: horde.damage(e, 7.0, Vector2.LEFT, 0.0, 0, false, horde.pos[e], false, 0, false, 0.0)
	_armor_check("plate once and flesh transition", pieces.count(1) == 1 and horde.hp[e] < initial_hp and blood_events.size() > 0)
	pieces.clear()
	e = _armor_dummy(Horde.Kind.INFANTRY)
	horde.damage(e, 10.0, Vector2.LEFT, 0.0, 0, false, horde.pos[e] + Vector2(3, 0), false, 0, false, 0.0)
	_armor_check("helmet on head hit", pieces == [0] and horde.armor_mask[e] == 2)
	initial_hp = horde.hp[e]
	horde.damage(e, 7.0, Vector2.LEFT, 0.0, 0, false, horde.pos[e] + Vector2(3, 0), false, 0, false, 0.0)
	_armor_check("bare head bypasses vest", horde.hp[e] == initial_hp - 7.0 and horde.armor_chest[e] == 22.0)
	pieces.clear()
	e = _armor_dummy(Horde.Kind.RIOT)
	initial_hp = horde.hp[e]
	horde.damage(e, 14.0, Vector2.LEFT, 0.0, 0, false, horde.pos[e], false, 0, false, 0.0)
	_armor_check("shield front", horde.hp[e] == initial_hp and horde.armor_shield[e] == 41.0)
	horde.damage(e, 14.0, Vector2.RIGHT, 0.0, 0, false, horde.pos[e], false, 0, false, 0.0)
	_armor_check("shield rear open", horde.hp[e] == initial_hp - 14.0)
	e = _armor_dummy(Horde.Kind.RIOT)
	horde.damage(e, horde.hp[e] + 8.0, Vector2.LEFT, 0.0, 0, false, horde.pos[e], true)
	_armor_check("explosion bypass", horde.dead[e] == 1)
	pieces.clear()
	e = _armor_dummy(Horde.Kind.JUGGERNAUT)
	for j in 7: horde.damage(e, 8.0, Vector2.LEFT, 0.0, 0, false, horde.pos[e], false, 0, false, 0.0)
	_armor_check("heavy chest separate", pieces.count(1) == 1 and horde.armor_mask[e] == 5)
	horde.damage(e, 1000.0, Vector2.LEFT, 0.0, 0, false, horde.pos[e], true)
	horde.damage(e, 1000.0, Vector2.LEFT, 0.0)
	_armor_check("all parts exactly once", pieces.size() == 3 and pieces.count(0) == 1 and pieces.count(2) == 1)
	e = _armor_dummy(Horde.Kind.JUGGERNAUT)
	horde.damage(e, 1.0, Vector2.RIGHT, 100.0, 0, false, horde.pos[e], false, 0, false, 1.0)
	_armor_check("heavy mass resists push", is_equal_approx(horde.knock[e].x, 30.0))
	# Перенос состояния и повторное использование слота не возвращают снятые детали.
	e = _armor_dummy(Horde.Kind.INFANTRY)
	var second := horde.spawn(ARENA.get_center() + Vector2(30, 0), Horde.Kind.JUGGERNAUT)
	horde._detach_armor(second, 0, Vector2.LEFT)
	var code := horde.visual_code[second]
	horde.dead[e] = 1
	horde._compact()
	_armor_check("compact armor", horde.armor_mask[0] == 6 and horde.armor_chest[0] == 40.0 and horde.visual_code[0] == code)
	e = horde.spawn(ARENA.get_center(), Horde.Kind.SHAMBLER)
	_armor_check("spawn reset armor", horde.armor_mask[e] == 0 and horde.armor_head[e] == 0.0 and horde.armor_chest[e] == 0.0)
	for k in range(Horde.Kind.INFANTRY, Horde.Kind.JUGGERNAUT + 1):
		horde.reset_variety_seed(81073)
		e = _armor_dummy(k)
		var state := [horde.hp[e], horde.speed[e], horde.visual_code[e], horde.armor_mask[e], horde.radius[e]]
		horde.reset_variety_seed(81073)
		e = _armor_dummy(k)
		_armor_check("seed " + str(k), state == [horde.hp[e], horde.speed[e], horde.visual_code[e], horde.armor_mask[e], horde.radius[e]])
		_armor_check("PF1 radius " + str(k), horde.radius[e] <= 7.95 and horde.radius[e] * 2.0 < Horde.CELL)
		_armor_check("corpse bank " + str(k), PixelArt.appearance(horde.visual_code[e]) == 63 + k - Horde.Kind.INFANTRY)
	# Реальная damage(), магазин и темп; без крита, разброса, статусов и пассивок.
	var rows := PackedStringArray(["model,base,infantry,infantry_p3,riot,riot_p3,heavy,heavy_p3"])
	for id: String in WeaponDefs.MODEL_ORDER:
		var base: int = WeaponDefs.MODELS[id]["base"]
		var values := PackedStringArray([id, str(base)])
		weapons.slots.clear()
		weapons.add_weapon(base, id)
		for k in range(Horde.Kind.INFANTRY, Horde.Kind.JUGGERNAUT + 1):
			for rank in [0, 3]:
				var slot := weapons.slots[0]
				slot.modules.clear()
				if rank > 0 and WeaponDefs.supports_module(base, WeaponDefs.Module.PIERCE):
					slot.modules.append({"id": WeaponDefs.Module.PIERCE, "rank": rank, "rare": false})
				weapons.refresh(0)
				var st := slot.stats
				e = _armor_dummy(k)
				var shots := 0
				var elapsed := 0.0
				var mag: int = st["mag"]
				var pen := WeaponDefs.armor_penetration(base, id, rank if WeaponDefs.supports_module(base, WeaponDefs.Module.PIERCE) else 0, 35.0)
				while horde.dead[e] == 0 and shots < 1000:
					for pellet in int(st["proj"]):
						horde.damage(e, float(st["damage"]), Vector2.LEFT, 0.0, 0, false, horde.pos[e], base == WeaponDefs.Base.LAUNCHER, base, false, pen)
					shots += 1
					if horde.dead[e] == 0:
						var pause := 1.0 / float(st["rate"])
						if shots % mag == 0: pause = maxf(pause, float(st["reload"]))
						elapsed += pause
				values.append("%.3f" % elapsed)
				_armor_check("finite TTK " + id, horde.dead[e] == 1 and elapsed < 30.0)
		rows.append(",".join(values))
		_armor_check("weapon AP " + id, WeaponDefs.armor_penetration(base, id) >= 0.0 and WeaponDefs.armor_penetration(base, id) <= 1.0)
	_armor_check("shotgun near vs far", WeaponDefs.armor_penetration(1, "butcher", 0, 30) > WeaponDefs.armor_penetration(1, "butcher", 0, 140))
	_armor_check("mosin AP", WeaponDefs.armor_penetration(7, "mosin") >= 0.9)
	var director := HordeDirector.new()
	director.setup(horde, player, 81073, "quarantine_checkpoint")
	director.pattern = HordeDirector.Pattern.COLUMN
	var selected := PackedInt32Array([0, 0, 0])
	var original_uid := horde._next_uid
	for serial in 1000:
		horde._next_uid = serial
		var k := director._armored_kind(Horde.Kind.SHAMBLER, 480.0)
		if k >= Horde.Kind.INFANTRY: selected[k - Horde.Kind.INFANTRY] += 1
		_armor_check("director seed replay", k == director._armored_kind(Horde.Kind.SHAMBLER, 480.0))
	_armor_check("military column distribution", selected == PackedInt32Array([13, 6, 1]))
	_armor_check("midrun gate", director._armored_kind(Horde.Kind.SHAMBLER, 299.0) == Horde.Kind.SHAMBLER)
	_armor_check("preserve explosive heavy", director._armored_kind(Horde.Kind.FAT, 480.0) == Horde.Kind.FAT)
	_armor_check("shared heavy role", HordeDirector._role_of(Horde.Kind.RIOT) == 2)
	var legacy := true
	for appearance in PixelArt.APPEARANCE_COUNT:
		legacy = legacy and PixelArt.base_variant(64 + appearance) == appearance % PixelArt.VARIANT_COUNT
	_armor_check("legacy visual codes", legacy)
	horde._next_uid = original_uid
	horde.armor_detached.disconnect(collect)
	horde.enemy_impact.disconnect(blood)
	var file := FileAccess.open("res://design/tasks/reports/z2_ttk.csv", FileAccess.WRITE)
	if file: file.store_string("\n".join(rows) + "\n")
	print("ARMORTEST checks=%d failed=%d models=48 types=3 seed=81073" % [_armor_checks, _armor_failed])
	get_tree().quit(0 if _armor_failed == 0 else 1)


func _run_armor_shots() -> void:
	set_process(false)
	set_physics_process(false)
	spawner.enabled = false
	for node: Node in [$World, $BloodAlarm, $Spawner]: node.process_mode = Node.PROCESS_MODE_DISABLED
	announce_t = 0.0
	player.god_mode = true
	camera.target = null
	camera.position_smoothing_enabled = false
	camera.shake_multiplier = 0.0
	var center := obstacles.free_point(_map_data["start"], 100.0)
	camera.position = center
	camera.zoom = Vector2(12, 12)
	player.position = center + Vector2(0, 35)
	seed(81073)
	horde.reset_variety_seed(81073)
	horde.count = 0
	for j in 4:
		var e := horde.spawn(center + Vector2(-60 + j * 40, 0), Horde.Kind.SHAMBLER if j == 0 else Horde.Kind.INFANTRY + j - 1)
		horde.angle[e] = 0.0
		horde.variant[e] = 2
		horde.body_scale[e] = 1.2 if j == 3 else 1.0
	horde._render()
	await _armor_save("lineup")
	var gray := get_viewport().get_texture().get_image()
	for y in gray.get_height():
		for x in gray.get_width():
			var c := gray.get_pixel(x, y)
			var l := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			gray.set_pixel(x, y, Color(l, l, l, c.a))
	gray.save_png("res://design/tasks/reports/z2_lineup_gray.png")
	for j in range(1, 4):
		var at := horde.pos[j]
		horde.damage(j, horde.armor_head[j], Vector2.LEFT, 0.0, 0, false, at + Vector2(3, 0), false, 0, false, 0.0)
		horde.damage(j, horde.armor_shield[j] if j == 2 else horde.armor_chest[j], Vector2.LEFT, 0.0, 0, false, at, false, 0, false, 0.0)
		if j == 3: horde.damage(j, horde.armor_limbs[j], Vector2.LEFT, 0.0, 0, false, at + Vector2(0, 3), false, 0, false, 0.0)
		horde.damage(j, 7.0, Vector2.LEFT, 0.0, 0, false, at, false, 0, false, 0.0)
	gore._physics_process(0.08)
	effects._physics_process(0.03)
	horde._render()
	await _armor_save("armor_hits")
	await _r1d_clear()
	for j in 2:
		var e := horde.spawn(center + Vector2(-30 + j * 60, 0), Horde.Kind.RIOT)
		horde.angle[e] = 0.0 if j == 0 else PI
		horde.damage(e, 7.0, Vector2.LEFT, 0.0, 0, false, horde.pos[e], false, 0, false, 0.0)
	gore._physics_process(0.016)
	horde._render()
	await _armor_save("shield_flank")
	await _r1d_clear()
	horde.death_override = Gore.Death.NORMAL
	for j in 3:
		var e := horde.spawn(center + Vector2(-45 + j * 45, 16), Horde.Kind.INFANTRY + j)
		horde.damage(e, horde.hp[e] + 100.0, Vector2.RIGHT, 35.0, 0, false, horde.pos[e])
	horde.death_override = -1
	for tick in 12:
		gore._physics_process(0.08)
		effects._physics_process(0.08)
		floor_decals._process(0.08)
	horde._compact()
	horde._render()
	await _armor_save("corpses")
	await _r1d_clear()
	camera.zoom = Vector2(3, 3)
	for j in 90:
		var at := center + Vector2(-230 + (j % 15) * 32, -90 + (j / 15) * 32)
		if at.distance_to(player.position) < 30.0: continue
		var e := horde.spawn(at, Horde.Kind.INFANTRY + j % 3 if j % 4 == 0 else Horde.Kind.SHAMBLER)
		horde.angle[e] = (player.position - at).angle()
		if j % 6 == 0: horde.damage(e, 7.0, (at - player.position).normalized(), 0.0, 0, false, at)
	_arsenal_loadout("ak_s,colt,ppsh,butcher")
	for tick in 90:
		horde._physics_process(1.0 / 60.0)
		weapons._physics_process(1.0 / 60.0)
		gore._physics_process(1.0 / 60.0)
		effects._physics_process(1.0 / 60.0)
		floor_decals._process(1.0 / 60.0)
	horde._render()
	await _armor_save("fight")
	print("ARMORSHOTS viewport=true types=3 camera=12,3 seed=81073")
	get_tree().quit()


func _armor_save(name: String) -> void:
	announce_t = 0.0
	multikill_t = 0.0
	$HUD/Hud.queue_redraw()
	horde.queue_redraw()
	gore.queue_redraw()
	effects.queue_redraw()
	_zoom = 1.0 if name == "fight" else 4.0
	_update_view()
	# После предыдущего снимка даём CanvasItem отправить новый кадр, без остатков стенда.
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/z2_%s.png" % name)


func _run_z1_checks() -> void:
	$World.process_mode = Node.PROCESS_MODE_DISABLED
	spawner.enabled = false
	set_physics_process(false)
	set_process(false)
	var ok := true
	var center := ARENA.get_center()
	for is_elite: bool in [false, true]:
		for k in 4:
			horde.count = 0
			horde.minutes = 0.0
			horde.reset_variety_seed(92071 + k)
			var sums := PackedFloat64Array([0, 0, 0, 0])
			var lows := PackedFloat64Array([INF, INF, INF, INF])
			var highs := PackedFloat64Array([-INF, -INF, -INF, -INF])
			var snapshot := PackedFloat32Array()
			var identities := PackedInt32Array()
			var visual_seeds := PackedFloat32Array()
			var quirks := PackedByteArray()
			var covariance := Vector2.ZERO
			var traits := PackedInt32Array([0, 0, 0, 0, 0])
			for j in 2000:
				var i := horde.spawn(center, k, is_elite)
				var values := PackedFloat64Array([horde.max_hp[i] / (float(Horde.KINDS[k]["hp"]) * (Horde.ELITE_HP if is_elite else 1.0)), horde.speed[i] / (float(Horde.KINDS[k]["speed"]) * (Horde.ELITE_SPEED if is_elite else 1.0)), horde.damage_mult[i], horde.body_scale[i]])
				for axis in 4:
					sums[axis] += values[axis]
					lows[axis] = minf(lows[axis], values[axis])
					highs[axis] = maxf(highs[axis], values[axis])
				traits[horde.quirk[i]] += 1
				covariance += Vector2((values[0] - 1.0) * (values[3] - 1.0), (values[1] - 1.0) * (values[3] - 1.0))
				var speed_delta: float = Horde.TRAIT_SPEED[horde.quirk[i]] - (0.0056 if k != Horde.Kind.SHAMBLER else 0.0)
				var spread := 0.22 if k == Horde.Kind.RUNNER else 0.11
				ok = ok and values[0] >= 0.7999 and values[0] <= 1.2001 and values[2] >= 0.8999 and values[2] <= 1.1001 and values[3] >= 0.9199 and values[3] <= 1.0801
				ok = ok and absf(values[1] / Horde.BASE_SPEED_MEAN - 1.0 - speed_delta) <= spread + 0.0001
				ok = ok and is_equal_approx((1.0 + (horde.body_scale[i] - 1.0) * (0.75 if is_elite else 1.0)) * Horde.RADIUS * (Horde.ELITE_SCALE if is_elite else 1.0), horde.radius[i]) and horde.radius[i] <= Horde.MAX_COLLISION_RADIUS + 0.0001 and PixelArt.base_variant(horde.visual_code[i]) == horde.variant[i]
				for axis in 4:
					snapshot.append(values[axis])
				identities.append(horde.visual_code[i])
				visual_seeds.append(horde.seed_value[i])
				quirks.append(horde.quirk[i])
			for axis in 4:
				ok = ok and absf(sums[axis] / 2000.0 - 1.0) <= 0.03
			ok = ok and covariance.x > 0.0 and covariance.y < 0.0
			print("Z1CHECK kind=%d elite=%s n=2000 mean=%s min=%s max=%s traits=%s" % [k, is_elite, PackedFloat64Array([sums[0] / 2000.0, sums[1] / 2000.0, sums[2] / 2000.0, sums[3] / 2000.0]), lows, highs, traits])
			horde.count = 0
			horde.reset_variety_seed(92071 + k)
			for j in 2000:
				var i := horde.spawn(center, k, is_elite)
				ok = ok and identities[j] == horde.visual_code[i]
				ok = ok and visual_seeds[j] == horde.seed_value[i] and quirks[j] == horde.quirk[i]
				ok = ok and is_equal_approx(snapshot[j * 4], horde.max_hp[i] / (float(Horde.KINDS[k]["hp"]) * (Horde.ELITE_HP if is_elite else 1.0)))
				ok = ok and is_equal_approx(snapshot[j * 4 + 1], horde.speed[i] / (float(Horde.KINDS[k]["speed"]) * (Horde.ELITE_SPEED if is_elite else 1.0))) and is_equal_approx(snapshot[j * 4 + 2], horde.damage_mult[i]) and is_equal_approx(snapshot[j * 4 + 3], horde.body_scale[i])
	# Последняя строка переезжает вместе со всеми новыми каналами.
	var last := horde.count - 1
	var last_code := horde.visual_code[last]
	var last_trait := horde.quirk[last]
	var last_damage := horde.damage_mult[last]
	horde.dead[0] = 1
	horde._compact()
	ok = ok and horde.visual_code[0] == last_code and horde.quirk[0] == last_trait and horde.damage_mult[0] == last_damage
	var atlas := PixelArt.tex("zombie_atlas")
	ok = ok and atlas.get_width() == 768 and atlas.get_height() == PixelArt.VARIANT_COUNT * 192 and atlas.get_height() <= 4096
	ok = ok and gore._t_whole.size() == PixelArt.APPEARANCE_COUNT and gore._t_corpse.size() == PixelArt.APPEARANCE_COUNT * PixelArt.CORPSE_POSES
	for list: Array[int] in [gore._t_whole, gore._t_walker, gore._t_top, gore._t_head, gore._t_arm, gore._t_torso, gore._t_legs, gore._t_corpse, gore._t_headless]:
		for texture_id in list:
			ok = ok and gore._textures[texture_id] != null and gore._textures[texture_id].get_width() > 0
	# Все варианты и оттенки проходят настоящие смерти и переход в останки.
	for appearance in PixelArt.APPEARANCE_COUNT:
		var code := appearance + 64 * (9 + 32 + 64)
		gore.count = 0
		gore.on_enemy_killed(center, Vector2.RIGHT, Gore.Death.NORMAL, 0.0, code)
		ok = ok and gore._tex[0] in gore._t_corpse and gore._scale[0] == PixelArt.corpse_scale(code)
		gore._keep_remains(0, 20.0)
		ok = ok and gore._r_scale[gore.remains_count - 1] == PixelArt.corpse_scale(code)
		gore.count = 0
		gore.on_enemy_killed(center, Vector2.RIGHT, Gore.Death.DECAP, 0.0, code)
		ok = ok and gore._textures[gore._t_walker[appearance]] != null
	ok = ok and Horde.MAX_COLLISION_RADIUS * 2.0 < Horde.CELL
	print("Z1CHECK checks=replay,compact,corpse_parts,collision_grid atlas=%dx%d appearances=%d ok=%s" % [atlas.get_width(), atlas.get_height(), PixelArt.APPEARANCE_COUNT, ok])
	Meta.finish_test(0 if ok else 1)


# --- дерево класса: численные эффекты, допуски и миграция -----------------------------------------
var _tree_checks := 0
var _tree_failed := 0


func _tree_check(name: String, ok: bool) -> void:
	_tree_checks += 1
	if not ok:
		_tree_failed += 1
		print("CLASSTREE FAIL " + name)


func _tree_fixture(selected: Dictionary, kind := "assault") -> Weapons.Slot:
	Meta.reset()
	Meta.persist = false
	Meta.select_class(kind)
	Meta.tree = selected.duplicate()
	boss.hp = 0.0
	weapons.clear_projectiles()
	weapons.slots.clear()
	weapons.passives.clear()
	weapons.bonuses = Meta.run_bonuses()
	weapons.add_weapon(WeaponDefs.Base.RIFLE)
	var s := weapons.slots[0]
	s.stats["crit"] = -5.0
	for e in horde.count:
		horde.dead[e] = 1
	horde._compact()
	horde.reset_variety_seed(19501)
	seed(19501)
	player.is_dead = false
	player.god_mode = false
	player.apply_bonuses(Meta.run_bonuses())
	player._iframes = 0.0
	player._dash_t = 0.0
	player._gren_t = -1.0
	player.position = ARENA.get_center()
	player.facing = Vector2.RIGHT
	player.aim_dir = Vector2.RIGHT
	player.aim_point = player.position + Vector2(100, 0)
	player.autopilot = false
	player.manual_aim = true
	player.force_auto_aim = true
	return s


func _tree_dummy() -> int:
	var e := horde.spawn(player.position + Vector2(10, 0))
	horde.hp[e] = 10000.0
	horde.max_hp[e] = 10000.0
	horde.speed[e] = 0.0
	horde._rebuild_grid()
	return e


func _tree_probe(key: String, selected: Dictionary, kind := "assault") -> float:
	var s := _tree_fixture(selected, kind)
	match key:
		"assault_return":
			player.dash_cd = 2.0
			player._close_return_cd = 0.0
			player.class_hit(player.position + Vector2(10, 0))
			return player.dash_cd
		"brace_damage", "brace_range":
			player.stability = 1.0
			return player.tree_damage_multiplier(160.0)
		"brace_knock":
			player.stability = 1.0
			var e := _tree_dummy()
			weapons._hit_enemy(0, e, 1.0, Vector2.RIGHT, horde.pos[e], 40.0)
			return horde.knock[e].length()
		"brace_gain", "brace_persist":
			player._moving = key == "brace_persist"
			player.stability = 1.0 if player._moving else 0.0
			player.class_tick(0.2)
			return player.stability
		"bastion_time", "turret_time":
			player.grenade_cd = 0.0
			player.throw_grenade()
			return player.class_active_t
		"bastion_cd_mul", "turret_cd_mul": return player.ability_cooldown()
		"bastion_move", "bastion_rate", "bastion_reload", "turret_refill", "turret_heal", "turret_guard":
			player.grenade_cd = 0.0
			player.hp = 50.0
			s.mag = 1
			player.throw_grenade()
			if key in ["bastion_reload", "turret_refill"]: return float(s.mag)
			if key == "turret_heal": return player.hp
			if key == "turret_guard": return player._iframes
			return player.tree_speed_multiplier() if key == "bastion_move" else player.tree_damage_multiplier(100.0)
		"brace_reload":
			player.stability = 1.0
			s.mag = 1
			weapons._start_reload(s)
			weapons._update_slot(0, 0.1)
			return s.reload_t
		"turret_damage", "turret_range", "turret_rate", "turret_double", "crossfire_window":
			player.grenade_cd = 0.0
			player.throw_grenade()
			var e := _tree_dummy()
			if key == "turret_range":
				horde.pos[e] = player.class_anchor + Vector2(162, 0)
				horde._rebuild_grid()
			weapons._turret_cd = 0.0
			weapons._class_turret(0.01)
			if key == "turret_rate": return weapons._turret_cd
			if key == "crossfire_window": return player.turret_mark_t
			return 10000.0 - horde.hp[e]
		"crossfire", "crossfire_knock":
			var e := _tree_dummy()
			player.turret_mark = horde.pos[e]
			player.turret_mark_t = 1.0
			player.class_anchor = horde.pos[e] + Vector2(30, 0)
			weapons._hit_enemy(0, e, 10.0, Vector2.RIGHT, horde.pos[e], 40.0)
			return horde.knock[e].length() if key == "crossfire_knock" else 10000.0 - horde.hp[e]
		"damage_mul": return float(s.stats["damage"])
		"crit_add":
			weapons.refresh(0)
			return float(s.stats["crit"])
		"reload_mul": return float(s.stats["reload"])
		"mag_mul": return float(s.stats["mag"])
		"range_mul": return float(s.stats["range"])
		"spread_mul": return float(s.stats["spread"])
		"knock_mul": return float(s.stats["knock"])
		"hp_add": return player.max_hp
		"dash_charges": return float(player.dash_max)
		"speed_mul": return player.move_speed
		"dash_distance": return player.dash_distance
		"sustained_rate":
			s.streak = 3.1
			return weapons._streak_mult(s)
		"standing_damage":
			player.tree_still = 1.1
			return player.tree_damage_multiplier(100.0)
		"close_damage": return player.tree_damage_multiplier(50.0)
		"far_damage": return player.tree_damage_multiplier(160.0)
		"low_damage":
			player.hp = 20.0
			return player.tree_damage_multiplier(100.0)
		"first_round", "last_round":
			s.mag = int(s.stats["mag"]) if key == "first_round" else 1
			weapons._fire_shot(0, s, Weapons.MANUAL_TARGET)
			return s.last_damage
		"tactical_mul":
			s.mag = 1
			weapons._start_reload(s)
			weapons._update_slot(0, 0.1)
			return s.reload_t
		"reload_move":
			s.mag = 1
			weapons._start_reload(s)
			weapons._physics_process(0.01)
			return player.tree_speed_multiplier()
		"reload_cover":
			s.mag = 1
			weapons._start_reload(s)
			return player._iframes
		"adrenaline":
			s.mag = 1
			player.try_dash()
			return float(s.mag)
		"dash_heal":
			player.hp = 50.0
			player.try_dash()
			return player.hp
		"dash_cd_mul":
			player.try_dash()
			return player.dash_cd
		"dash_guard":
			player.try_dash()
			return player._iframes
		"dash_speed":
			player.try_dash()
			return player.tree_speed_multiplier()
		"dash_grenade":
			player.grenade_cd = 5.0
			player.try_dash()
			return player.grenade_cd
		"hurt_mul":
			player.take_damage(20.0)
			return player.max_hp - player.hp
		"rest_heal":
			player.hp = 50.0
			player._tree_unhurt = 7.0
			player._physics_process(1.0)
			return player.hp
		"rescue_hp":
			player.take_damage(200.0)
			return player.hp
		"grenade_speed":
			player.grenade_cd = 0.0
			player.throw_grenade()
			return player.tree_speed_multiplier()
		"grenade_cd_mul":
			player.grenade_cd = 0.0
			player.throw_grenade()
			return player.grenade_cd
		"grenade_distance": return player.position.distance_to(player.grenade_target())
		"grenade_heal":
			player.hp = 50.0
			player.grenade_cd = 0.0
			player.throw_grenade()
			player._update_grenade(0.5)
			return player.hp
		"grenade_refill":
			s.mag = 1
			weapons.explode(player.position, Player.GRENADE_DAMAGE, Player.GRENADE_RADIUS)
			return float(s.mag)
		"grenade_damage_mul", "grenade_radius_mul", "grenade_knock_mul":
			var e := _tree_dummy()
			weapons.explode(player.position, Player.GRENADE_DAMAGE, Player.GRENADE_RADIUS)
			return horde.knock[e].length() if key == "grenade_knock_mul" else 10000.0 - horde.hp[e]
		"crit_knock", "close_knock", "first_knock", "elite_damage", "finish_damage":
			var e := _tree_dummy()
			if key == "crit_knock": s.stats["crit"] = 5.0
			if key == "elite_damage": horde.elite[e] = 1
			if key == "finish_damage": horde.max_hp[e] = 100000.0
			weapons._hit_enemy(0, e, 10.0, Vector2.RIGHT, horde.pos[e], 40.0, false, false, key == "first_knock")
			return 10000.0 - horde.hp[e] if key in ["elite_damage", "finish_damage"] else horde.knock[e].length()
		"boss_damage":
			boss.start(player.position + Vector2(100, 0))
			var hp_before := boss.hp
			weapons._damage_boss(0, 100.0, Vector2.RIGHT, boss.position, "test")
			return hp_before - boss.hp
		"dna_mul":
			time = 606.0
			kills = 0
			elites_killed = 0
			var stats := _result_stats(false)
			Meta.apply_run(stats)
			_tree_check("dna report matches credited reward", int(stats["dna_total"]) == int(Meta.last_run["dna"]))
			return float(Meta.last_run["dna"])
	push_error("CLASSTREE untested effect " + key)
	return NAN


func _run_class_tree_test() -> void:
	get_tree().paused = true
	Meta.persist = false
	player.died.disconnect(_on_player_died)
	player.hurt.disconnect(_on_player_hurt)
	weapons.effects = null
	weapons.camera = null
	weapons.sfx = null
	weapons.explosions = null
	player.effects = null
	var empty: Array[Dictionary] = []
	obstacles.setup(ARENA, empty)
	for kind: String in ClassTree.CLASSES:
		Meta.reset()
		Meta.select_class(kind)
		var catalog := ClassTree.catalog()
		_tree_check(kind + " 72 unique nodes", catalog.size() == 72)
		var visited: Dictionary = {}
		for pass_index in 72:
			for id: String in catalog:
				if ClassTree.parents_met(catalog[id], visited): visited[id] = true
		_tree_check(kind + " connected to center", visited.size() == 72)
		for id: String in catalog:
			var n: Dictionary = catalog[id]
			for neighbor: String in n["parents"]:
				_tree_check(id + " undirected", catalog[neighbor]["parents"].has(id))
			if not n["start"]:
				_tree_check(id + " locked without neighbor", not ClassTree.parents_met(n, {}))
				_tree_check(id + " any neighbor", ClassTree.parents_met(n, {n["parents"][-1]: true}))
			for key: String in n["effects"]:
				var before := _tree_probe(key, {}, kind)
				var after := _tree_probe(key, {id: true}, kind)
				_tree_check(id + "." + key + " applied", is_finite(before) and is_finite(after) and not is_equal_approx(before, after))
			Meta.reset()
			Meta.select_class(kind)
			Meta.dna_earned = Meta.dna_for_level(99)
			Meta.tree_gates = {"runs5": true, "runs10": true, "nest": true}
			if not str(n["exclude"]).is_empty():
				Meta.tree[n["exclude"]] = true
				_tree_check(id + " exclusive", not Meta.can_unlock(id))
		Meta.reset()
		Meta.select_class(kind)
		Meta.apply_preset("tree-full")
		var full_cost := Meta.tree_spent()
		var snapshot := Meta.to_dict()
		_tree_check(kind + " roundtrip", Meta.from_dict(snapshot) and Meta.to_dict() == snapshot)
		Meta.select_class(ClassTree.CLASSES[(ClassTree.CLASSES.find(kind) + 1) % 3])
		Meta.select_class(kind)
		_tree_check(kind + " build retained across switch", Meta.tree == snapshot["tree"] and Meta.tree_spent() == full_cost)
		var points := Meta.skill_points()
		_tree_check(kind + " reset refund", Meta.reset_tree() == full_cost and Meta.skill_points() == points + full_cost)
		Meta.select_class(ClassTree.CLASSES[(ClassTree.CLASSES.find(kind) + 1) % 3])
		Meta.select_class(kind)
		_tree_check(kind + " reset persists across switch", Meta.tree.is_empty())
		_tree_fixture({}, kind)
		player.grenade_cd = 0.0
		_tree_check(kind + " Q starts", player.throw_grenade() and player.grenade_cd > 0)
		_tree_check(kind + " Q cooldown blocks repeat", not player.throw_grenade())
		var cooldown := player.grenade_cd
		player._physics_process(cooldown - 0.01)
		_tree_check(kind + " Q still cooling", not player.throw_grenade())
		player._physics_process(0.02)
		_tree_check(kind + " Q recharged by timer", player.throw_grenade())
		if kind == "gunner":
			player.hp = 100
			player.take_damage(20, player.position + player.class_facing * 20)
			_tree_check("bastion front damage /4", player.hp == 95)
			player._iframes = 0
			player.take_damage(20, player.position - player.class_facing * 20)
			_tree_check("bastion rear unprotected", player.hp == 75)
		if kind == "engineer":
			var e := _tree_dummy()
			weapons._turret_cd = 0
			weapons._class_turret(0.01)
			_tree_check("turret fires and marks", horde.hp[e] < 10000 and player.turret_mark_t > 0)
			player.position = player.turret_mark + (player.turret_mark - player.class_anchor).normalized() * 30
			_tree_check("crossfire opposite side", player.class_hit(player.turret_mark) > 1.0)
			for enemy in horde.count: horde.dead[enemy] = 1
			horde._compact()
			boss.start(player.class_anchor + Vector2(100, 0))
			var health := boss.hp
			weapons._turret_cd = 0
			weapons._class_turret(0.01)
			_tree_check("turret attacks boss", boss.hp < health)
		print("CLASSTREE class=%s nodes=%d full_cost=%d" % [kind, catalog.size(), full_cost])
	# Поведение на границах и защита от повторного срабатывания.
	_tree_fixture({"surv_bandage": true})
	player.hp = 50.0
	player.try_dash()
	player.dash_left = 1
	player.try_dash()
	_tree_check("dash heal shared 10s cooldown", player.hp == 56.0 and player._tree_heal_cd == 10.0)
	_tree_fixture({"surv_rescue": true})
	player.take_damage(200.0)
	_tree_check("rescue first lethal", player.hp == 25.0 and player._iframes >= 1.0)
	player._iframes = 0.0
	player.take_damage(200.0)
	_tree_check("rescue once per run", player.is_dead and player.hp == 0.0)
	_tree_fixture({"fire_hold": true})
	player.tree_still = 0.99
	_tree_check("standing threshold", player.tree_damage_multiplier(100.0) == 1.0)
	player.tree_still = 1.0
	_tree_check("standing active", is_equal_approx(player.tree_damage_multiplier(100.0), 1.25))
	_tree_fixture({"fire_close": true})
	_tree_check("close range boundary", player.tree_damage_multiplier(70.0) > 1.0 and player.tree_damage_multiplier(70.01) == 1.0)
	_tree_fixture({"fire_far": true})
	_tree_check("far range boundary", player.tree_damage_multiplier(140.0) > 1.0 and player.tree_damage_multiplier(139.99) == 1.0)
	_tree_fixture({"dash_run": true, "dash_smoke": true})
	player.try_dash()
	player.grenade_cd = 0.0
	player.throw_grenade()
	_tree_check("temporary speed stacks", is_equal_approx(player.tree_speed_multiplier(), 1.35))
	player._physics_process(2.1)
	_tree_check("temporary speed expires", player.tree_speed_multiplier() == 1.0)
	var cover_slot := _tree_fixture({"mag_cover": true})
	cover_slot.mag = 1
	weapons._start_reload(cover_slot)
	player._iframes = 0.0
	weapons._start_reload(cover_slot)
	_tree_check("reload cover shared cooldown", player._iframes == 0.0 and player._tree_cover_cd == 3.0)
	_tree_fixture({"tact_finish": true})
	boss.start(player.position + Vector2(100, 0))
	boss.hp = boss.max_hp * 0.19
	var boss_before := boss.hp
	weapons._damage_boss(0, 100.0, Vector2.RIGHT, boss.position, "test")
	_tree_check("execution also affects boss", is_equal_approx(boss_before - boss.hp, 93.75))
	for version in range(1, 7):
		Meta.reset()
		Meta.dna = 777
		Meta.dna_earned = Meta.dna_for_level(20)
		Meta.workshop = {"ak_s": {"damage": 3}}
		Meta.runs = 12
		Meta.crates = 4
		Meta.military_crates = 2
		Meta.owned.append("m4")
		Meta.favorite[0] = "m4"
		Meta.tree = {"fire_1": true, "fire_2": true, "fire_3": true, "mag_1": true}
		var legacy := Meta.to_dict()
		legacy["version"] = version
		Meta.reset()
		_tree_check("v%d migration" % version, Meta.from_dict(legacy) and Meta.tree == legacy["tree"] and Meta.dna == 777 and Meta.dna_earned == legacy["dna_earned"] and Meta.workshop == legacy["workshop"] and Meta.campaign == legacy["campaign"] and Meta.class_id == "assault" and Meta.tree_spent() + Meta.skill_points() == 19)
		var preserved := Meta.to_dict()
		for field: String in ["owned", "favorite", "crates", "military_crates", "runs", "settings"]:
			_tree_check("v%d preserves %s" % [version, field], preserved[field] == legacy[field])
		var migrated := Meta.to_dict()
		_tree_check("v%d stable" % version, Meta.from_dict(migrated) and Meta.to_dict() == migrated)
	Meta.reset()
	Meta.apply_preset("tree-full")
	var old_full := Meta.to_dict()
	old_full["version"] = 6
	for id: String in old_full["tree"].keys():
		if id.begins_with("assault_"): old_full["tree"].erase(id)
	_tree_check("T1 full build preserved", Meta.from_dict(old_full) and Meta.tree == old_full["tree"])
	var upgraded := Meta.to_dict()
	_tree_check("T1 full build reload stable", Meta.from_dict(upgraded) and Meta.to_dict() == upgraded)
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://design/tasks/reports/cp1_v4_fixture.json"))
	_tree_check("actual v4 campaign profile loads", Meta.from_dict(fixture) and not Meta.campaign_recovered)
	var current := Meta.to_dict()
	for field: String in fixture:
		if field == "version": continue
		if field == "owned":
			# Серийные модели новых типов (W7) выдаются при загрузке — старые открытия должны сохраниться.
			var kept := true
			for id: Variant in fixture[field]:
				kept = kept and Array(current[field]).has(id)
			_tree_check("actual v4 preserved owned", kept)
			continue
		var expected: Variant = CampaignRules.normalized(CampaignRules.migrate(fixture[field])) if field == "campaign" else CampaignRules.normalized(fixture[field], field)
		_tree_check("actual v4 preserved " + field, CampaignRules.normalized(current[field], field) == expected)
	print("CLASSTREE checks=%d failed=%d" % [_tree_checks, _tree_failed])
	Meta.finish_test(0 if _tree_failed == 0 else 1)

func _run_boss_checks() -> void:
	var ok: bool = await BossTest.run(self)
	Meta.finish_test(0 if ok else 1)


## Снимок снаряжения свежего --sim на 10:00, до случайного усиления в самом бою.
func _boss_starter_loadout() -> void:
	var bases := [WeaponDefs.Base.RIFLE, WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.SMG, WeaponDefs.Base.REVOLVER]
	var levels := [5, 3, 3, 2]
	var modules := [
		[[WeaponDefs.Module.SPLIT, 3], [WeaponDefs.Module.TWIN, 2], [WeaponDefs.Module.CHAIN, 1]],
		[[WeaponDefs.Module.DETONATOR, 3], [WeaponDefs.Module.PIERCE, 1]],
		[[WeaponDefs.Module.TWIN, 3]],
		[[WeaponDefs.Module.RICOCHET, 2]],
	]
	for i in 4:
		if i >= weapons.slots.size():
			weapons.add_weapon(bases[i])
		var slot: Weapons.Slot = weapons.slots[i]
		slot.set_model(Meta.model_for(bases[i]))
		slot.level = levels[i]
		slot.ammo = WeaponDefs.Ammo.STANDARD
		slot.ammo_rank = 1
		slot.modules.clear()
		for module: Array in modules[i]:
			slot.modules.append({"id": module[0], "rank": module[1], "rare": false})
		weapons.refresh(i)
		slot.mag = slot.stats["mag"]
	for id: int in [1, 1, 1, 5, 3, 3]:
		progression.apply({"type": "passive", "id": id}, -1, false)


func _run_boss_shots() -> void:
	await BossShots.run(self)
	Meta.finish_test()

## Повторяемый стенд движения, с тем же шагом и камерой для кадров до/после.
func _run_pathing_shots() -> void:
	_director_freeze()
	$HUD.visible = false
	var before := OS.get_cmdline_user_args().has("--pathing-before")
	var suffix := "_before" if before else ""
	var center := Vector2(1280, 720)
	camera.position = center
	camera.zoom = Vector2(3, 3)
	for scene in 4:
		if before and scene == 2:
			break
		var layout: Array[Dictionary] = []
		if scene == 0:
			for side in [-1, 1]:
				layout.append({"kind": Obstacles.Kind.SEDAN, "pos": center + Vector2(side * 39, 0)})
		elif scene == 1 or scene == 3:
			camera.zoom = Vector2(3, 3)
			var spacing := 74 if scene == 1 else 78
			for j in 3:
				layout.append({"kind": Obstacles.Kind.SEDAN, "pos": center + Vector2((j - 1) * spacing, -14), "angle": 0.12})
			layout.append({"kind": Obstacles.Kind.JERSEY, "pos": center + Vector2(94, 35), "angle": 0.4})
		else:
			layout = MapLoader.layout(_map_data, 81073)
			camera.zoom = Vector2(1.5, 1.5)
		obstacles.setup(ARENA, layout)
		horde.count = 0
		horde.reset_variety_seed(81073)
		horde.far_distance = 5000.0
		player.position = center + Vector2(0, 105 if scene == 0 else 90)
		weapons.position = player.position
		_pathing_warm(5.0, player.position)
		for i in (300 if scene == 2 else 65):
			var at := center + Vector2(-60 + i % 13 * 10, -110 - i / 13 * 12)
			if scene == 2:
				at = center + Vector2.from_angle(i * 2.399963) * (140 + i % 9 * 14)
			var e := horde.spawn(at, Horde.Kind.SHAMBLER)
			horde.quirk[e] = Horde.Trait.ORDINARY
		var crossed := PackedByteArray()
		crossed.resize(horde.count)
		var routes := PackedByteArray()
		routes.resize(horde.count)
		var inner := 0
		var outer := 0
		for tick in 360:
			obstacles.navigation_step(1.0 / 60.0, player.position)
			horde._physics_process(1.0 / 60.0)
			if scene == 1 or scene == 3:
				for i in horde.count:
					if routes[i] == 0 and horde.pos[i].y >= center.y - 14:
						routes[i] = 1 if absf(horde.pos[i].x - center.x) < 74 else 2
					if crossed[i] == 0 and horde.pos[i].y > center.y + 18:
						crossed[i] = 1
						if routes[i] == 1:
							inner += 1
						else:
							outer += 1
			if scene == 0 and not before and tick >= 150 and tick < 300 and tick % 15 == 0:
				await _pathing_shot("seq_%02d" % ((tick - 150) / 15))
			if tick == 239:
				await _pathing_shot((["gap", "hug", "crowd", "hug_wide"][scene]) + suffix)
			if tick == 359 and scene == 3:
				await _pathing_shot("hug_wide_6s")
		if scene == 1 or scene == 3:
			print("PATHINGFLOW scene=%d seconds=6 inner=%d outer=%d" % [scene, inner, outer])
		if scene == 1 and obstacles.profile_enabled:
			for x in [-30, 0, 30]:
				print("PATHSAMPLE x=%d path=%s" % [x, obstacles.body_path(center + Vector2(x, -110), player.position, 4.6)])
	if obstacles.profile_enabled:
		_pathing_profile()
	get_tree().quit()


func _pathing_profile() -> void:
	var ticks := maxf(1, horde.profile_ticks)
	print("PATHPROFILE ticks=%d separation_ms=%.3f collision_ms=%.3f clear_ms=%.3f paths=%d rays=%d layers=%d" % [ticks, horde.separation_usec / ticks / 1000.0, horde.collision_usec / ticks / 1000.0, obstacles.body_usec / ticks / 1000.0, obstacles.path_calls, obstacles.body_calls, obstacles._nav_layers.size()])


func _pathing_shot(label: String) -> void:
	horde._render()
	horde.queue_redraw()
	obstacles.queue_redraw()
	await RenderingServer.frame_post_draw
	var path := "res://design/tasks/reports/pf1_%s.png" % label
	var err := get_viewport().get_texture().get_image().save_png(path)
	print("PATHINGSHOT path=%s error=%d" % [path, err])


## --crowd-test (ZAI2): метрики поведения толпы на картах; пороги — в CrowdTest.LIMITS.
func _run_crowd_test() -> void:
	_director_freeze()
	seed(81073)
	var crowd := CrowdTest.new()
	var failed: int = await crowd.run(self)
	Meta.finish_test(0 if failed == 0 else 1)


func _pathing_warm(_r: float, target: Vector2) -> void:
	for tick in 10000:
		obstacles.navigation_step(1.0 / 60.0, target)
		if not obstacles._building and obstacles.nav_completed > 0:
			break


func _pathing_walk(from: Vector2, target: Vector2, r: float, gap_x := 1280.0, gap_width := 20.0) -> Dictionary:
	_pathing_warm(r, target)
	var p := from
	var length := 0.0
	var penetrations := 0
	var still := 0
	var max_still := 0
	var crossed := false
	var closest := INF
	for tick in 1800:
		if p.distance_to(target) < 1.0:
			break
		var dir := obstacles.steering(p, (target - p).normalized(), r, target)
		if dir == Vector2.ZERO:
			dir = (target - p).normalized()
		var next := obstacles.move_actor(p, p + dir * minf(0.5, p.distance_to(target)), r)
		length += next.distance_to(p)
		still = still + 1 if next.distance_to(p) < 0.01 else 0
		max_still = maxi(max_still, still)
		if obstacles.contains(next, r - 0.03):
			penetrations += 1
		if p.y < 720 and next.y >= 720 and absf(next.x - gap_x) <= gap_width * 0.5 - r + 0.03:
			crossed = true
		if absf(next.x - 1280) < 28:
			closest = minf(closest, absf(next.y - 720) - 14.0 - r)
		p = next
	return {"arrived": p.distance_to(target) < 1.0, "length": length + p.distance_to(target), "penetrations": penetrations, "stuck_ticks": max_still, "gap": crossed, "clearance": closest}


func _run_pathing_test() -> void:
	_director_freeze()
	seed(81073)
	var checks := 0
	var failed := 0
	var penetrations := 0
	var stuck := 0
	var center := Vector2(1280, 720)
	for gap: float in [10.2, 14.0, 20.0, 30.0]:
		for r: float in [5.0, 6.9, 7.5]:
			for shift: float in [0.0, 3.25]:
				var layout: Array[Dictionary] = []
				for side in [-1, 1]:
					layout.append({"kind": Obstacles.Kind.SEDAN, "pos": center + Vector2(side * (32 + gap * 0.5) + shift, 0)})
				obstacles.setup(Rect2(center - Vector2(256, 256), Vector2(512, 512)), layout)
				var result := _pathing_walk(center + Vector2(-22 + shift, -100), center + Vector2(22 + shift, 100), r, center.x + shift, gap)
				checks += 1
				var ok: bool = result["arrived"] and result["gap"] == (gap > r * 2.0) and result["penetrations"] == 0 and result["stuck_ticks"] < 180
				if not ok:
					failed += 1
				print("PATHINGTEST gap=%.1f radius=%.2f shift=%.2f through=%s arrived=%s length=%.3f penetrations=%d stuck_ticks=%d ok=%s" % [gap, r, shift, result["gap"], result["arrived"], result["length"], result["penetrations"], result["stuck_ticks"], ok])
	# Прямая машина: точная длина касательных к скруглённому контуру.
	var car: Array[Dictionary] = [{"kind": Obstacles.Kind.SEDAN, "pos": center}]
	obstacles.setup(Rect2(center - Vector2(256, 256), Vector2(512, 512)), car)
	var hug := _pathing_walk(center + Vector2(-100, 0), center + Vector2(100, 0), 5.0)
	var d := Vector2(68, 14).length()
	var arc := atan2(14.0, 68.0) + asin(5.0 / d)
	var shortest := 64 + 2 * (sqrt(d * d - 25) + 5 * arc)
	checks += 1
	var hug_ok: bool = hug["arrived"] and hug["length"] <= shortest * 1.15 and hug["clearance"] >= -0.04 and hug["clearance"] <= 2.0 and hug["penetrations"] == 0 and hug["stuck_ticks"] < 180
	if not hug_ok:
		failed += 1
	print("PATHINGTEST hug length=%.3f shortest=%.3f ratio=%.4f clearance=%.3f penetrations=%d stuck_ticks=%d ok=%s" % [hug["length"], shortest, hug["length"] / shortest, hug["clearance"], hug["penetrations"], hug["stuck_ticks"], hug_ok])
	# Прижатое толпой к кузову тело продолжает идти вдоль него, без отскока в запас поля.
	for r: float in [5.0, 7.5]:
		var at := obstacles.resolve(center + Vector2(0, -14), r)
		_pathing_warm(r, center + Vector2(100, 0))
		var direction := obstacles.steering(at, Vector2.RIGHT, r, center + Vector2(100, 0))
		checks += 1
		if direction.dot(Vector2.RIGHT) < 0.95:
			failed += 1
			print("PATHINGTEST FAILED wall_contact radius=", r, " direction=", direction)
	for angle: float in [-0.61, 0.43]:
		car[0]["angle"] = angle
		obstacles.setup(Rect2(center - Vector2(256, 256), Vector2(512, 512)), car)
		var walk := _pathing_walk(center + Vector2(-100, 0), center + Vector2(100, 0), 7.5)
		checks += 1
		if not walk["arrived"] or walk["penetrations"] != 0 or walk["stuck_ticks"] >= 180:
			failed += 1
			print("PATHINGTEST FAILED rotated ", angle, " ", walk)
	var circles: Array[Dictionary] = [{"kind": Obstacles.Kind.BAGS, "pos": center}]
	obstacles.setup(Rect2(center - Vector2(256, 256), Vector2(512, 512)), circles)
	var round_walk := _pathing_walk(center + Vector2(-70, 0), center + Vector2(70, 0), 5.0)
	checks += 1
	if not round_walk["arrived"] or round_walk["penetrations"] != 0:
		failed += 1
	var old_path := obstacles.body_path(center + Vector2(-70, 0), center + Vector2(70, 0), 5.0)
	var old_revision := obstacles.nav_revision
	obstacles.charge(center, Boss.RADIUS)
	var opened := obstacles.body_path(center + Vector2(-70, 0), center + Vector2(70, 0), 5.0)
	checks += 1
	if old_path.size() < 2 or opened.size() != 1 or obstacles.nav_revision == old_revision:
		failed += 1
		print("PATHINGTEST FAILED destruction")
	obstacles.setup(Rect2(center - Vector2(256, 256), Vector2(512, 512)), circles)
	_pathing_warm(5.0, center + Vector2(70, 0))
	checks += 1
	if old_path != obstacles.body_path(center + Vector2(-70, 0), center + Vector2(70, 0), 5.0):
		failed += 1
		print("PATHINGTEST FAILED reproducible")
	for spacing in [74.0, 78.0]:
		var row := _pathing_row_flow(spacing)
		checks += 1
		# ZAI5: видимость цели считает поле — агенты лучей не пускают.
		var flow_ok: bool = row["queries"] == 0 and row["penetrations"] == 0 and row["oversized"] == 0 and row["left"] >= (1 if spacing < 75 else 10) and row["right"] >= (1 if spacing < 75 else 10) and row["inner"] >= (row["eligible"] * 0.6 if spacing < 75 else 30)
		if not flow_ok:
			failed += 1
		print("PATHINGTEST row spacing=%.1f gap=%.3f eligible=%d left=%d right=%d inner=%d outer=%d oversized=%d penetrations=%d ok=%s" % [spacing, spacing * cos(0.12) - 64.0, row["eligible"], row["left"], row["right"], row["inner"], row["outer"], row["oversized"], row["penetrations"], flow_ok])
		print("PATHINGTEST shared layers=%d agent_queries=%d" % [obstacles._nav_layers.size(), row["queries"]])
	for map_id: String in MapLoader.IDS:
		var data := MapLoader.load_map(map_id)
		var rect := Rect2(Vector2.ZERO, data["size"])
		obstacles.setup(rect, MapLoader.layout(data, 81073))
		horde.setup(rect, player, null)
		horde.count = 0
		horde.reset_variety_seed(81073)
		horde.far_distance = 5000.0
		player.position = data["start"]
		_pathing_warm(5.0, player.position)
		var previous := PackedVector2Array()
		var stops := PackedInt32Array()
		stops.resize(48)
		stops.fill(0)
		for i in 48:
			var entries: Array = data["spawn_points"]
			var at: Vector2 = Vector2(entries[i % entries.size()]) + Vector2((i / entries.size()) * 12, 0)
			var e := horde.spawn(at, Horde.Kind.RUNNER, i % 7 == 0)
			horde.quirk[e] = Horde.Trait.ORDINARY
			previous.append(horde.pos[e])
		for tick in 1800:
			obstacles.navigation_step(1.0 / 60.0, player.position)
			horde._physics_process(1.0 / 60.0)
			for i in horde.count:
				if obstacles.contains(horde.pos[i], horde.radius[i] - 0.04):
					penetrations += 1
				if not rect.grow(-horde.radius[i] + 0.04).has_point(horde.pos[i]):
					penetrations += 1
				if tick % 30 == 29:
					stops[i] = stops[i] + 30 if horde.pos[i].distance_to(previous[i]) < 1.0 and horde.pos[i].distance_to(player.position) > 80 else 0
					previous[i] = horde.pos[i]
					if stops[i] == 180:
						stuck += 1
						print("PATHINGTEST stuck map=%s i=%d pos=%s radius=%.3f" % [map_id, i, horde.pos[i], horde.radius[i]])
			if tick % 300 == 299:
				await get_tree().process_frame
		checks += 1
		print("PATHINGTEST map=%s actors=%d seconds=30 penetrations=%d stuck=%d" % [map_id, horde.count, penetrations, stuck])
	checks += 2
	if penetrations > 0:
		failed += 1
	if stuck > 0:
		failed += 1
	print("PATHINGTEST checks=%d failed=%d penetrations=%d stuck=%d seed=81073 ok=%s" % [checks, failed, penetrations, stuck, failed == 0])
	Meta.finish_test(0 if failed == 0 else 1)


func _pathing_row_flow(spacing: float) -> Dictionary:
	var center := Vector2(1280, 720)
	var layout: Array[Dictionary] = []
	for j in 3:
		layout.append({"kind": Obstacles.Kind.SEDAN, "pos": center + Vector2((j - 1) * spacing, -14), "angle": 0.12})
	layout.append({"kind": Obstacles.Kind.JERSEY, "pos": center + Vector2(94, 35), "angle": 0.4})
	obstacles.setup(Rect2(center - Vector2(256, 256), Vector2(512, 512)), layout)
	horde.setup(ARENA, player, null)
	horde.count = 0
	horde.reset_variety_seed(81073)
	horde.far_distance = 5000.0
	player.position = center + Vector2(0, 90)
	obstacles.profile_enabled = true
	obstacles.path_calls = 0
	obstacles.body_calls = 0
	obstacles.ray_calls = 0
	var result := {"eligible": 0, "left": 0, "right": 0, "inner": 0, "outer": 0, "oversized": 0, "penetrations": 0}
	var crossed := PackedByteArray()
	crossed.resize(65)
	var routes := PackedByteArray()
	routes.resize(65)
	for i in 65:
		var e := horde.spawn(center + Vector2(-60 + i % 13 * 10, -110 - i / 13 * 12), Horde.Kind.SHAMBLER)
		horde.quirk[e] = Horde.Trait.ORDINARY
		if horde.radius[e] * 2.0 + 0.05 < spacing * cos(0.12) - 64.0:
			result["eligible"] += 1
	for tick in 600:
		obstacles.navigation_step(1.0 / 60.0, player.position)
		horde._physics_process(1.0 / 60.0)
		for i in horde.count:
			if obstacles.contains(horde.pos[i], horde.radius[i] - 0.04):
				result["penetrations"] += 1
			if routes[i] == 0 and horde.pos[i].y >= center.y - 14:
				var x := horde.pos[i].x - center.x
				routes[i] = (1 if x < 0 else 2) if absf(x) < spacing else 3
			if crossed[i] == 0 and horde.pos[i].y > center.y + 18:
				crossed[i] = 1
				if routes[i] <= 2:
					result["inner"] += 1
					result["left" if routes[i] == 1 else "right"] += 1
					if horde.radius[i] * 2.0 > spacing * cos(0.12) - 64.0:
						result["oversized"] += 1
				else:
					result["outer"] += 1
	result["queries"] = obstacles.path_calls + obstacles.body_calls + obstacles.ray_calls
	obstacles.profile_enabled = false
	return result


## Живая игра без тестовых флагов (или --nav-thread): поле путей считается в фоновых потоках. Тесты и
## симуляции оставляют пошаговый расчёт — их результаты не должны зависеть от реального времени.
func _live_play() -> bool:
	var args := OS.get_cmdline_user_args()
	if "--nav-thread" in args:
		return true
	for arg in args:
		if arg.begins_with("--") and arg != "--fresh-save" and not arg.begins_with("--map=") and not arg.begins_with("--layout-seed="):
			return false
	return true
