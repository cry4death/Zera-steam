# C6b — дословные финальные проверки

19.10.2026, worktree `C:/Users/Dev/Desktop/zera-c6b`, ветка `task/c6b`.

Во всех командах дочернему процессу задан `APPDATA=C:/Users/Dev/Desktop/zera-c6b/design/tasks/reports/C6b_userdata`. Команды сохранены в начале журналов; для боя у узла команда приведена отдельно. Оболочка возвращает настоящий ExitCode Godot. PowerShell runner сохраняет stdout и затем stderr, поэтому их взаимный порядок отличается от интерактивного терминала. Сообщения и цветовые escape-последовательности не удалены. В журнале боя у узла сохранена также служебная оболочка PowerShell вокруг stderr.

Ниже восемь полных финальных журналов, затем исходник временного стенда. Ранние журналы предыдущего прогона с повреждённым кэшем после заполнения диска не являются финальными проверками. Их удаление, как и очистка userdata/одноразовых скриптов, отклонено автоматической проверкой с причиной `blocked by policy`.

Команда боя у узла:

```text
bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --windowed --resolution 1920x1080 --disable-vsync --path . --script res://design/tasks/reports/C6b_runtime.gd -- --campaign-op=clearance --c6-test --c6b-fight
```

## c6b_resume_import.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe "--headless" "--path" "." "--import"
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] [90m[1mfirst_scan_filesystem[22m | Started Инициализация проекта (5 steps)[39m[0m
[   0% ] [90m[1mfirst_scan_filesystem[22m | Сканирование структуры файлов…[39m[0m
[  16% ] [90m[1mfirst_scan_filesystem[22m | Загрузка глобальных имен классов…[39m[0m
[  33% ] [90m[1mfirst_scan_filesystem[22m | Проверка GDExtensions…[39m[0m
[  50% ] [90m[1mfirst_scan_filesystem[22m | Создание скриптов автозагрузки…[39m[0m
[  66% ] [90m[1mfirst_scan_filesystem[22m | Инициализация плагинов…[39m[0m
[  83% ] [90m[1mfirst_scan_filesystem[22m | Начало сканирование файлов…[39m[0m
[92m[ DONE ][39m [1mfirst_scan_filesystem[22m
[0m
[   0% ] [90m[1mloading_editor_layout[22m | Started Загрузка редактора (5 steps)[39m[0m
[   0% ] [90m[1mloading_editor_layout[22m | Загрузка макета редактора…[39m[0m
[  16% ] [90m[1mloading_editor_layout[22m | Загрузка док-панели…[39m[0m
[92m[ DONE ][39m [1mloading_editor_layout[22m
[0m
ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

EXIT=0

```

## c6b_resume_campaign.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe "--headless" "--path" "." "--" "--campaign-test"
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

CAMPAIGNTEST unit1_clamp=true
CAMPAIGNTEST unit2_stage_boundaries=true
CAMPAIGNTEST unit3_snapshot_order_and_input_immutable=true
CAMPAIGNTEST unit3_pressure_after_mission_effect=true
CAMPAIGNTEST unit4_nest_permanent_no_pressure=true
CAMPAIGNTEST unit5_suppression_turns_1_2_3=true
CAMPAIGNTEST unit5_new_suppression_includes_current=true
CAMPAIGNTEST unit6_generator_deterministic=true
CAMPAIGNTEST unit7_offer_quotas_and_compatibility=true
CAMPAIGNTEST unit6_world_replay=true
CAMPAIGNTEST unit8_lost_still_accessible=true
CAMPAIGNTEST unit8_all_lost_campaign_defeat=true
CAMPAIGNTEST c6_reclaim_always_offered=true
CAMPAIGNTEST unit8_single_lost_recoverable=true
CAMPAIGNTEST unit9_explicit_symmetric_graph=true
CAMPAIGNTEST unit10_boss_unlock_content_gate=true
CAMPAIGNTEST validation_range=true
CAMPAIGNTEST validation_fraction=true
CAMPAIGNTEST validation_unknown_region=true
CAMPAIGNTEST validation_unknown_template=true
CAMPAIGNTEST validation_initial=true
CAMPAIGNTEST validation_json_roundtrip=true
CAMPAIGNTEST c6_three_distinct_objectives=true
CAMPAIGNTEST c6_stage_combat_edges_reclaim=true
CAMPAIGNTEST c6_victory_below_35=true
CAMPAIGNTEST c6_destroyed_object7_never_offered=true
CAMPAIGNTEST c6_boss_dead_alone_no_victory=true
CAMPAIGNTEST c6_warning_two_keys=true
CAMPAIGNTEST c6_defeat_three_keys_no_launch=true
CAMPAIGNTEST c6_migrate_v1_regenerate_cancel_pending=true
CAMPAIGNTEST c6_meta_v3_migration_keeps_dna=true
CAMPAIGNTEST c6_corrupt_legacy_rejected=true
CAMPAIGNTEST c6_extract_reward_weak_effect_death_fails=true
CAMPAIGNTEST c6_sockets_three_maps_three_seeds_reachable=true
CAMPAIGNTEST start_persisted_pending_before_scene=true
CAMPAIGNTEST integration1_victory_one_save_rewards_world=true
CAMPAIGNTEST integration1_idempotent_same_report=true
CAMPAIGNTEST c6_migrated_completed_reward_once=true
CAMPAIGNTEST report_full_changes_causes_priority=true
CAMPAIGNTEST integration3_results_reopen=true
CAMPAIGNTEST integration2_defeat_once=true
CAMPAIGNTEST integration3_legacy_result_gets_run_id_once=true
CAMPAIGNTEST idempotent_older_run_report=true
CAMPAIGNTEST integration5_v1_v2_profile_preserved=true
CAMPAIGNTEST integration5_file_migration_not_corrupt=true
Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в res://tmp/c1_migration.json.campaign-bad-4829658
CAMPAIGNTEST integration6_corrupt_campaign_backup_profile_intact=true
CAMPAIGNTEST integration4_pending_and_offers_reload=true
Campaign: Связь с группой потеряна — операция не засчитана
CAMPAIGNTEST integration8_abandoned_no_commit=true
CAMPAIGNTEST retry_new_run_id=true
CAMPAIGNTEST commit_invalid_rewards_rejected=true
CAMPAIGNTEST commit_wrong_run_rejected=true
CAMPAIGNTEST commit_partial_requires_explicit_objective=true
CAMPAIGNTEST integration7_all_legacy_test_flags_bypass=true
Campaign: Связь с группой потеряна — операция не засчитана
CAMPAIGNTEST failed_start_no_scene_config=true
CAMPAIGNTEST new_campaign_keeps_profile=true
CAMPAIGNSIM campaigns=200 turns=40 per_strategy; first_lost=41 means censored; critical=infection>=60
strategy | first_lost_mean | critical_share | object7_turn | deadlocks | collapse | recovery_delta
always_win | 39.02 | 0.0236 | 2.67 (200/200) | 0 | 0 | 55.66
half_wins | 13.75 | 0.2398 | 4.65 (165/200) | 0 | 0 | 193.84
frequent_defeat | 4.53 | 0.1625 | 3.74 (43/200) | 0 | 0 | 39.35
reddest | 36.67 | 0.0177 | 1.99 (200/200) | 0 | 0 | 46.77
best_reward | 33.81 | 0.0578 | 2.49 (198/200) | 0 | 0 | 115.91
nest_hunter | 37.90 | 0.0126 | 1.42 (200/200) | 0 | 0 | 39.63
safe_clearance | 5.00 | 0.1172 | -- | 0 | 0 | 0.00
random | 22.30 | 0.1513 | 4.12 (185/200) | 0 | 0 | 192.85
CAMPAIGNTEST simulation_no_deadlocks=true
CAMPAIGNTEST simulation_no_irreversible_collapse=true
CAMPAIGNTEST checks=57 failures=0
CAMPAIGNTEST ok=true
ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
WARNING: Meta: запись res://tmp/c1_missing_directory/save.json не удалась
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] save (res://scripts/meta.gd:446)
       [1] start_operation (res://scripts/campaign/campaign.gd:57)
       [2] _integration (res://scripts/campaign/campaign_test.gd:265)
       [3] run (res://scripts/campaign/campaign_test.gd:24)
       [4] _ready (res://scripts/game.gd:668)

EXIT=0

```

## c6b_resume_meta.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe "--headless" "--path" "." "--" "--meta-test"
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=267.43 seed=81073
S7SETTINGS migration_v1_v4=true progress_preserved=true roundtrip=true sanitize=true temporary_save=true
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792380782
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792380782
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792380782
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792380782
Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в user://test_save.json.campaign-bad-7040303
METATEST save: запись/чтение/битый/старый/типы ок
METATEST class_level ДНК для уровня: 2:80 3:226 4:416 5:640 6:894 8:1482 10:2160
METATEST tree: порядок узлов, очки, бонусы ок; maxed={ "damage_mul": 1.08, "crit_add": 0.1, "sustained_rate": 0.2, "reload_mul": 0.85, "mag_mul": 1.2, "last_round": true, "hp_add": 20.0, "dash_charges": 2, "adrenaline": true }
METATEST workshop: цены серийных [20, 40, 70, 110, 160], редких [30, 60, 105, 165, 240], ствол целиком 1600 ДНК
METATEST crate обычный x10000: модель 49.5% (цель 50), редкая среди моделей 14.9% (цель 15), пачка 30..80, ср. 55.0, дубликатов-ДНК ок
METATEST crate военный x10000: модель 79.2% (цель 80), редкая среди моделей 49.8% (цель 50), пачка 30..80, ср. 54.6, дубликатов-ДНК ок
METATEST stats АК-С L5 maxed: урон 17.550 (ожид. 17.550) темп 8.28 магазин 81 перезарядка 0.6247 крит 0.10
METATEST dps (BALANCE §3.1, стандартные патроны I): модель L1 / L5
METATEST   ak_s       серийная АК-С      L1= 37.15 L5=177.70  
METATEST   m4         обычная  М4        L1= 36.80 L5=163.25  burst3
METATEST   butcher    серийная Мясник    L1= 27.04 L5= 78.43  
METATEST   shkval     обычная  Шквал     L1= 28.16 L5= 82.42  slamfire
METATEST   needle     серийная Игла      L1= 18.26 L5= 60.98  
METATEST   spear      редкая   Копьё     L1= 22.50 L5= 54.19  kill_charge
METATEST   grom       серийная Гром      L1= 12.97 L5= 55.52  
METATEST   hive       редкая   Улей      L1= 21.41 L5= 56.67  sticky
METATEST   colt       серийная Кольт     L1= 35.68 L5= 95.68  
METATEST   guard      обычная  Страж     L1= 29.96 L5=101.55  hicap
METATEST   bulldog    серийная Бульдог   L1= 32.34 L5= 81.82  
METATEST   cowboy     редкая   Ковбой    L1= 29.57 L5= 73.13  fan
METATEST   ppsh       серийная ППШ       L1= 42.57 L5=186.42  
METATEST   osa        обычная  Оса       L1= 36.25 L5=157.95  steady
METATEST   mosin      серийная Мосинка   L1= 33.73 L5= 89.46  
METATEST   winchester редкая   Винчестер L1= 34.17 L5= 91.87  lever
METATEST sfx: «М4» играет weapons/m4/shot (файлов weapons/m4 есть)
METATEST player: HP 120, 2 заряда рывка, адреналин КД 10 с, без дерева 100 HP/1 заряд ок
METATEST last_round: урон последнего патрона ×3 ([7.0, 7.0, 21.0]), убитый рвётся на гибы ок
METATEST sustained: за 2 с до 3 с стрельбы 11 выстрелов, после — 14 (+20%)
METATEST trait burst3 (М4): очереди [3, 3, 3, 3, 3, 3], темп 5.25/с, разброс +0.0° (АК-С +6.0°)
METATEST trait slamfire (Шквал): 10 выстрелов за 4.20 с (2.14/с), магазин 10, перезарядка 2.6 с, без помпы
METATEST trait kill_charge (Копьё): выстрел 60 → убийство → следующий 90 (×1.5) → снова 60
METATEST trait sticky (Улей): кассета из 3, прилипание → взрыв через 0.58 с (едет с носителем), носитель потерял 25 HP
METATEST trait hicap (Страж): магазин 17, 4.2 выстр/с, урон 8; перезарядка после 17 выстрелов
METATEST trait fan (Ковбой): 6 выстрелов за 0.43 с по 5 разным целям, барабан пуст → перезарядка
METATEST trait steady (Оса): магазин 50, за 4 с 44 выстрелов, разброс +0.0° (ППШ за 1 с +21.0°)
METATEST trait lever (Винчестер): интервал 0.63 с, после убийства следующий выстрел через 0.23 с; урон 28.8 (Мосинка 48), темп 1.6/с
METATEST checks=257 failed=0
METATEST ok=true
ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

EXIT=0

```

## c6b_resume_q1.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe "--headless" "--path" "." "--" "--q1-test" "--fresh-save"
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=215.59 seed=81073
PACKTEST variants=295 sha256=ee6a3daae203b64c6994b6dedee91fa9c0c18670cbf32bbc295f954889602d1b
PACKTEST bank=91 missing=0 maps=3 ok=true
Q1TEST pack=true
Q1CARDS seed=81073 generations=3000 cards=9000 invalid=0
Q1TEST cards_applicable=true
Q1TEST wall_open_takes_damage=true
Q1TEST wall_no_ammo_spent=true
Q1TEST wall_boss_rejected=true
Q1TEST wall_boss_only_no_target=true
Q1TEST wall_bypass_base_2=true
Q1TEST wall_bypass_base_3=true
Q1TEST wall_expands_beyond_eight=true
Q1TEST target_hysteresis=true
Q1TEST target_death_immediate=true
Q1TEST pad_open_delay=true
Q1TEST stick_hold_once=true
Q1TEST pad_held_does_not_install=true
Q1TEST pad_install_open=true
Q1TEST pad_install_back=true
Q1TEST pad_module_applied=true
Q1TEST pad_purchase=true
Q1TEST pad_shop_install_open=true
Q1TEST pad_shop_install_bought=true
Q1TEST pad_shop_close=true
Q1TEST slider_applies_immediately=true
Q1SLIDER movements=100 save_calls=1
Q1TEST slider_one_save=true
Q1TEST slider_disk_roundtrip=true
Q1TEST slider_debounce_then_close_one_save=true
Q1TEST checks=25 failed=0 ok=true
ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

EXIT=0

```

## c6b_resume_node_fight.log

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 06:34:06
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

bash : ERROR: Failed to read the root certificate store.
строка:2 знак:78
+ ... _userdata'; bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusi ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=371.01 seed=1461607753
MISSION threat=2 modifiers=[] seed=1461607753 profile={ "extract": false, "rate_mul": 1.075, "runner_add": 3.0, "spitter_add": 1.0, "acid": false, "elite_period": 28.0, "directional": 0.25, "hunt": false, "extra_alarm": false, "acid_life_mul": 1.0, "boss_hp_mul": 1.0, "boss_shed": 0.5 } commit=true persist=false
C6OBJECTIVE type=clearance target=(768.0, 832.0) exit=(320.0, 736.0) reachable=true
C6BSHOT res://design/tasks/reports/c6b_node_fight.png
C6BFIGHT actual_weapons_and_objective=true captured=true
C6BOT time=616.52 pos=(775.9998, 903.9865) goal=(768.0, 897.0) waypoint=39/39 picked=false results=true dead=false
C6TEST type=clearance victory=true time=616.52 picked=false hold=0.00 node_hp=0 once=true pause_outside=false
C6TEST pad_movement=false pad_return=true
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
EXIT=0

```

## c6b_resume_extract.log

```text
COMMAND bash "C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh" "C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe" "--windowed" "--resolution" "1920x1080" "--disable-vsync" "--path" "." "--script" "res://design/tasks/reports/C6b_runtime.gd" "--" "--campaign-op=extract" "--c6-test" "--c6b-fight"
GODOT_EXCLUSIVE other_godot_processes=0 at 06:35:22
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

MAP loaded id=old_town size=(2560.0, 1440.0) load_ms=364.29 seed=1869756907
MISSION threat=3 modifiers=["runner_surge", "acid_rain"] seed=1869756907 profile={ "extract": true, "rate_mul": 1.288, "runner_add": 31.0, "spitter_add": 2.0, "acid": true, "elite_period": 26.0, "directional": 0.3, "hunt": false, "extra_alarm": false, "acid_life_mul": 1.75, "boss_hp_mul": 1.0, "boss_shed": 0.5 } commit=true persist=false
C6OBJECTIVE type=extract target=(2152.0, 1128.0) exit=(312.0, 968.0) reachable=true
C6BSHOT res://design/tasks/reports/c6b_extract.png
C6BFIGHT actual_weapons_and_objective=true captured=true
C6BOT time=327.72 pos=(301.1371, 971.7728) goal=(312.0, 983.0) waypoint=8/8 picked=true results=true dead=false
C6TEST type=extract victory=true time=327.72 picked=true hold=25.20 node_hp=24000 once=true pause_outside=true
C6TEST pad_movement=false pad_return=true
ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT=0

```

## c6b_resume_states.log

```text
COMMAND bash "C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh" "C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe" "--windowed" "--resolution" "1920x1080" "--disable-vsync" "--path" "." "--script" "res://design/tasks/reports/C6b_runtime.gd" "--" "--campaign-op=clearance" "--c6b-states"
GODOT_EXCLUSIVE other_godot_processes=0 at 06:36:44
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=499.47 seed=1461607753
MISSION threat=2 modifiers=[] seed=1461607753 profile={ "extract": false, "rate_mul": 1.075, "runner_add": 3.0, "spitter_add": 1.0, "acid": false, "elite_period": 28.0, "directional": 0.25, "hunt": false, "extra_alarm": false, "acid_life_mul": 1.0, "boss_hp_mul": 1.0, "boss_shed": 0.5 } commit=true persist=false
C6OBJECTIVE type=clearance target=(768.0, 832.0) exit=(320.0, 736.0) reachable=true
C6BSHOT res://design/tasks/reports/c6b_node_closed.png
C6BSHOT res://design/tasks/reports/c6b_node_open.png
C6BSHOT res://design/tasks/reports/c6b_node_damaged.png
C6BSHOT res://design/tasks/reports/c6b_node_critical.png
C6BSHOT res://design/tasks/reports/c6b_node_ruined.png
C6BSTATES closed_open_damaged_critical_ruined=true hitbox_radius=28 dead_not_targetable=true
ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT=0

```

## c6b_resume_png.log

```text
C6BGEN syntax=true
PNG OK campaign_beacon.png 120x144 crc=true zlib=true
PNG OK campaign_beacon_lit.png 120x144 crc=true zlib=true
PNG OK campaign_beacon_zone.png 360x360 crc=true zlib=true
PNG OK campaign_node.png 240x216 crc=true zlib=true
PNG OK campaign_node_closed.png 240x216 crc=true zlib=true
PNG OK campaign_node_critical.png 240x216 crc=true zlib=true
PNG OK campaign_node_damaged.png 240x216 crc=true zlib=true
PNG OK campaign_node_roots.png 240x216 crc=true zlib=true
PNG OK campaign_node_ruined.png 240x216 crc=true zlib=true
PNG OK campaign_sample.png 120x108 crc=true zlib=true
PNG OK c6b_extract.png 1920x1080 crc=true zlib=true
PNG OK c6b_extract_previous.png 1920x1080 crc=true zlib=true
PNG OK c6b_node_closed.png 1920x1080 crc=true zlib=true
PNG OK c6b_node_critical.png 1920x1080 crc=true zlib=true
PNG OK c6b_node_damaged.png 1920x1080 crc=true zlib=true
PNG OK c6b_node_fight.png 1920x1080 crc=true zlib=true
PNG OK c6b_node_open.png 1920x1080 crc=true zlib=true
PNG OK c6b_node_ruined.png 1920x1080 crc=true zlib=true
PNG OK c6b_node_states.png 3840x2240 crc=true zlib=true
PNG OK c6b_sheet.png 7500x3000 crc=true zlib=true
C6BPNG files=20 failed=0

```

## C6b_runtime.gd

```gdscript
extends SceneTree
## Только визуальный стенд: исходники и штатные проверки не меняются.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: Node2D = scene.instantiate()
	root.add_child(game)
	current_scene = game
	if OS.get_cmdline_user_args().has("--c6b-states"):
		await _states(game)
	elif OS.get_cmdline_user_args().has("--c6b-fight"):
		await _fight(game)


func _shot(suffix: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://design/tasks/reports/c6b_%s.png" % suffix
	assert(root.get_texture().get_image().save_png(path) == OK)
	print("C6BSHOT " + path)


func _states(game: Node2D) -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	game.set_physics_process(false)
	game.spawner.enabled = false
	game.weapons.firing_enabled = false
	game.player.god_mode = true
	game.player.set_physics_process(false)
	game.objective.set_physics_process(false)
	game.player.position = game.objective.target + Vector2(0, 65)
	game.camera.reset_smoothing()
	game.time = 599.0
	game.trader_visit = 2
	game.mission_banner_t = 0.0
	game._dispatch_started = true
	game.horde.set_physics_process(false)
	await create_timer(0.5).timeout
	await _shot("node_closed")
	assert(not game.boss.is_alive())
	game.time = 600.0
	game.objective._physics_process(0.0)
	await create_timer(0.2).timeout
	await _shot("node_open")
	assert(game.boss.hit_test(game.boss.position + Vector2(28, 0), 0.0))
	assert(not game.boss.hit_test(game.boss.position + Vector2(28.1, 0), 0.0))
	game.boss.take_damage(game.boss.max_hp * 0.5, Vector2.UP, game.boss.position)
	await create_timer(0.2).timeout
	await _shot("node_damaged")
	game.boss.take_damage(game.boss.max_hp * 0.25, Vector2.UP, game.boss.position)
	await create_timer(0.2).timeout
	await _shot("node_critical")
	# Стенд останков: финальный взрыв и рапорт проверяются отдельно ботом C6.
	for connection: Dictionary in game.boss.died.get_connections():
		game.boss.died.disconnect(connection["callable"])
	game.boss.take_damage(game.boss.max_hp, Vector2.UP, game.boss.position)
	await create_timer(0.8).timeout
	await _shot("node_ruined")
	assert(not game.boss.is_alive() and not game.boss.hit_test(game.boss.position, 1.0))
	print("C6BSTATES closed_open_damaged_critical_ruined=true hitbox_radius=28 dead_not_targetable=true")
	root.get_node("Meta").finish_test()


func _fight(game: Node2D) -> void:
	var captured := false
	while not game.game_over:
		await physics_frame
		if game.objective.type == "extract":
			if not captured and game.objective.picked and game.objective.hold > 8.0:
				captured = true
				await _shot("extract")
		else:
			if not captured and game.boss.is_alive() and game.boss.hp < game.boss.max_hp * 0.88:
				captured = true
				await _shot("node_fight")
	assert(captured)
	print("C6BFIGHT actual_weapons_and_objective=true captured=true")

```
