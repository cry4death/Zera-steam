# EV1 — дословные журналы

Команды runner записаны первой строкой каждого журнала. В первых исходных замерах — нативный engine.log и журнал оболочки; перенаправление stderr PowerShell добавляет собственное оформление системной ошибки сертификатов.

Финальные проверки не скрывают системную диагностику сертификатов и существующее предупреждение ObjectDB.

## ev1_import_final.log

```text
COMMAND ['C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe', '--headless', '--path', '.', '--import']
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
[   0% ] [90m[1mfirst_scan_filesystem[22m | Started Инициализация проекта (5 steps)[39m[0m
[   0% ] [90m[1mfirst_scan_filesystem[22m | Сканирование структуры файлов…[39m[0m
[  16% ] [90m[1mfirst_scan_filesystem[22m | Загрузка глобальных имен классов…[39m[0m
[  33% ] [90m[1mfirst_scan_filesystem[22m | Проверка GDExtensions…[39m[0m
[  50% ] [90m[1mfirst_scan_filesystem[22m | Создание скриптов автозагрузки…[39m[0m
[  66% ] [90m[1mfirst_scan_filesystem[22m | Инициализация плагинов…[39m[0m
[  83% ] [90m[1mfirst_scan_filesystem[22m | Начало сканирование файлов…[39m[0m
[92m[ DONE ][39m [1mfirst_scan_filesystem[22m
[0m
[   0% ] [90m[1mupdate_scripts_classes[22m | Started Регистрация глобальных классов… (3 steps)[39m[0m
[   0% ] [90m[1mupdate_scripts_classes[22m | Activities[39m[0m
[  25% ] [90m[1mupdate_scripts_classes[22m | ActivitiesTest[39m[0m
[  50% ] [90m[1mupdate_scripts_classes[22m | [39m[0m
[92m[ DONE ][39m [1mupdate_scripts_classes[22m
[0m
[   0% ] [90m[1mloading_editor_layout[22m | Started Загрузка редактора (5 steps)[39m[0m
[   0% ] [90m[1mloading_editor_layout[22m | Загрузка макета редактора…[39m[0m
[  16% ] [90m[1mloading_editor_layout[22m | Загрузка док-панели…[39m[0m
[92m[ DONE ][39m [1mloading_editor_layout[22m
[0m

EXIT=0
```

## ev1_meta_final.log

```text
COMMAND ['C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe', '--headless', '--path', '.', '--', '--meta-test']
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=199.95 seed=81073
S7SETTINGS migration_v1_v4=true progress_preserved=true roundtrip=true sanitize=true temporary_save=true
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792411239
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792411239
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792411239
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792411239
Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в user://test_save.json.campaign-bad-3496107
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
METATEST trait sticky (Улей): кассета из 3, прилипание → взрыв через 0.58 с (едет с носителем), носитель потерял 23 HP
METATEST trait hicap (Страж): магазин 17, 4.2 выстр/с, урон 8; перезарядка после 17 выстрелов
METATEST trait fan (Ковбой): 6 выстрелов за 0.43 с по 5 разным целям, барабан пуст → перезарядка
METATEST trait steady (Оса): магазин 50, за 4 с 44 выстрелов, разброс +0.0° (ППШ за 1 с +21.0°)
METATEST trait lever (Винчестер): интервал 0.63 с, после убийства следующий выстрел через 0.23 с; урон 28.8 (Мосинка 48), темп 1.6/с
METATEST checks=257 failed=0
METATEST ok=true

EXIT=0
```

## ev1_campaign_final.log

```text
COMMAND ['C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe', '--headless', '--path', '.', '--', '--campaign-test']
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
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
Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в res://tmp/c1_migration.json.campaign-bad-3915875
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
WARNING: Meta: запись res://tmp/c1_missing_directory/save.json не удалась
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] save (res://scripts/meta.gd:446)
       [1] start_operation (res://scripts/campaign/campaign.gd:57)
       [2] _integration (res://scripts/campaign/campaign_test.gd:265)
       [3] run (res://scripts/campaign/campaign_test.gd:24)
       [4] _ready (res://scripts/game.gd:673)
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

EXIT=0
```

## ev1_q1_final.log

```text
COMMAND ['C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe', '--headless', '--path', '.', '--', '--q1-test', '--fresh-save']
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=185.73 seed=81073
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

EXIT=0
```

## ev1_gore_final.log

```text
COMMAND ['C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe', '--headless', '--path', '.', '--', '--fresh-save', '--gore-checks']
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=174.83 seed=81073
R1CHECK pellets_one_reaction_full_damage=true
R1CHECK exit_spray=true
R1CHECK crawler_inertia=true
R1CHECK bounded_flood_2400_deaths=true
R1CHECK no_permanent_body_or_ash_stamps=true
R1CHECK all_remains_expire=true
R1CHECK ok=true remains_peak=200 stamps_queue=401 particles=0

EXIT=0
```

## ev1_obstacles_final.log

```text
COMMAND ['C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe', '--headless', '--path', '.', '--', '--obstacles-test', '--fresh-save']
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=247.93 seed=81073
OBSTEST layout cars=27 barrels=20 objects=409 seed=81073
OBSTEST simulation seconds=10 alive=500 penetrations=0
OBSTEST simulation seconds=20 alive=500 penetrations=0
OBSTEST simulation seconds=30 alive=500 penetrations=0
OBSTEST simulation seconds=40 alive=500 penetrations=0
OBSTEST simulation seconds=50 alive=500 penetrations=0
OBSTEST simulation seconds=60 alive=500 penetrations=0
OBSTEST wall arrived=500/500 nav_worst_us=274
OBSTEST ok=true penetrations=0 arrived=500 detonations=3 blood_events=2

EXIT=0
```

## ev1_activities_final.log

```text
COMMAND ['C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe', '--headless', '--path', '.', '--', '--activities-test', '--fresh-save']
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=178.61 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
ACTIVITIESTEST reachable_quarantine_checkpoint_81073_12_sites=true
ACTIVITIESTEST seed_quarantine_checkpoint_81073=true
ACTIVITIESTEST variety_quarantine_checkpoint_81073=true
ACTIVITIESTEST pool_quarantine_checkpoint_81073=true
ACTIVITIESTEST reachable_quarantine_checkpoint_27_12_sites=true
ACTIVITIESTEST seed_quarantine_checkpoint_27=true
ACTIVITIESTEST variety_quarantine_checkpoint_27=true
ACTIVITIESTEST pool_quarantine_checkpoint_27=true
ACTIVITIESTEST reachable_quarantine_checkpoint_96241_12_sites=true
ACTIVITIESTEST seed_quarantine_checkpoint_96241=true
ACTIVITIESTEST variety_quarantine_checkpoint_96241=true
ACTIVITIESTEST pool_quarantine_checkpoint_96241=true
ACTIVITIESTEST reachable_old_town_81073_12_sites=true
ACTIVITIESTEST seed_old_town_81073=true
ACTIVITIESTEST variety_old_town_81073=true
ACTIVITIESTEST pool_old_town_81073=true
ACTIVITIESTEST reachable_old_town_27_12_sites=true
ACTIVITIESTEST seed_old_town_27=true
ACTIVITIESTEST variety_old_town_27=true
ACTIVITIESTEST pool_old_town_27=true
ACTIVITIESTEST reachable_old_town_96241_12_sites=true
ACTIVITIESTEST seed_old_town_96241=true
ACTIVITIESTEST variety_old_town_96241=true
ACTIVITIESTEST pool_old_town_96241=true
ACTIVITIESTEST reachable_open_perimeter_81073_12_sites=true
ACTIVITIESTEST seed_open_perimeter_81073=true
ACTIVITIESTEST variety_open_perimeter_81073=true
ACTIVITIESTEST pool_open_perimeter_81073=true
ACTIVITIESTEST reachable_open_perimeter_27_12_sites=true
ACTIVITIESTEST seed_open_perimeter_27=true
ACTIVITIESTEST variety_open_perimeter_27=true
ACTIVITIESTEST pool_open_perimeter_27=true
ACTIVITIESTEST reachable_open_perimeter_96241_12_sites=true
ACTIVITIESTEST seed_open_perimeter_96241=true
ACTIVITIESTEST variety_open_perimeter_96241=true
ACTIVITIESTEST pool_open_perimeter_96241=true
ACTIVITY event=start kind=supply time=100.00 age=0.00 pos=(1721.711, 1066.606) offered=1 success=0 failed=0 rewards=0
ACTIVITIESTEST supply_start=true
ACTIVITIESTEST supply_no_overlap=true
ACTIVITIESTEST supply_pause_keeps_work=true
ACTIVITY event=success kind=supply time=100.00 age=20.00 pos=(1721.711, 1066.606) offered=1 success=1 failed=0 rewards=1
ACTIVITIESTEST supply_success_reward=true
ACTIVITIESTEST supply_one_physical_reward=true
ACTIVITIESTEST supply_reward_once=true
ACTIVITY event=start kind=supply time=100.00 age=0.00 pos=(1721.711, 1066.606) offered=2 success=1 failed=0 rewards=1
ACTIVITIESTEST supply_restart=true
ACTIVITY event=failed kind=supply time=100.00 age=71.00 pos=(1721.711, 1066.606) offered=2 success=1 failed=1 rewards=1
ACTIVITIESTEST supply_failure_no_reward=true
ACTIVITIESTEST supply_released_state=true
ACTIVITY event=start kind=carrier time=100.00 age=0.00 pos=(1721.711, 1066.606) offered=3 success=1 failed=1 rewards=1
ACTIVITIESTEST carrier_start=true
ACTIVITIESTEST carrier_no_overlap=true
ACTIVITIESTEST carrier_moves_on_route=true
ACTIVITIESTEST carrier_freeze_works=true
ACTIVITY event=success kind=carrier time=100.00 age=0.30 pos=(1725.843, 1065.852) offered=3 success=2 failed=1 rewards=2
ACTIVITIESTEST carrier_success_reward=true
ACTIVITIESTEST carrier_real_medkit_xp=true
ACTIVITIESTEST carrier_reward_once=true
ACTIVITY event=start kind=carrier time=100.00 age=0.00 pos=(1721.711, 1066.606) offered=4 success=2 failed=1 rewards=2
ACTIVITIESTEST carrier_restart=true
ACTIVITY event=failed kind=carrier time=100.00 age=71.00 pos=(1721.711, 1066.606) offered=4 success=2 failed=2 rewards=2
ACTIVITIESTEST carrier_failure_no_reward=true
ACTIVITIESTEST carrier_released_state=true
ACTIVITY event=start kind=fuel time=100.00 age=0.00 pos=(1721.711, 1066.606) offered=5 success=2 failed=2 rewards=2
ACTIVITIESTEST fuel_start=true
ACTIVITIESTEST fuel_no_overlap=true
ACTIVITIESTEST fuel_armed_by_contact=true
ACTIVITY event=success kind=fuel time=100.00 age=8.00 pos=(1721.711, 1066.606) offered=5 success=3 failed=2 rewards=3
ACTIVITIESTEST fuel_actual_horde_damage=true
ACTIVITIESTEST fuel_success_reward=true
ACTIVITIESTEST fuel_real_credit_drop=true
ACTIVITIESTEST fuel_reward_once=true
ACTIVITY event=start kind=fuel time=100.00 age=0.00 pos=(1721.711, 1066.606) offered=6 success=3 failed=2 rewards=3
ACTIVITIESTEST fuel_restart=true
ACTIVITY event=failed kind=fuel time=100.00 age=8.00 pos=(1721.711, 1066.606) offered=6 success=3 failed=3 rewards=3
ACTIVITIESTEST fuel_staying_is_dangerous=true
ACTIVITIESTEST fuel_failure_no_reward=true
ACTIVITIESTEST fuel_released_state=true
ACTIVITY event=start kind=carrier time=100.00 age=0.00 pos=(1721.711, 1066.606) offered=7 success=3 failed=3 rewards=3
ACTIVITIESTEST end_clears_activity_without_reward=true
ACTIVITIESTEST end_releases_carrier=true
ACTIVITIESTEST director_defers_when_hurt=true
ACTIVITY event=start kind=supply time=116.00 age=0.00 pos=(1612.625, 857.0885) offered=1 success=3 failed=3 rewards=3
ACTIVITIESTEST director_keeps_first_two_optional_offers=true
ACTIVITY event=failed kind=supply time=116.00 age=0.00 pos=(1612.625, 857.0885) offered=1 success=3 failed=4 rewards=3
ACTIVITY event=skip_pressure kind=supply time=116.00 age=0.00 pos=(inf, inf) offered=2 success=3 failed=4 rewards=3
ACTIVITIESTEST director_skips_later_danger=true
ACTIVITIESTEST director_no_overdue_debt=true
ACTIVITY event=start kind=supply time=100.00 age=0.00 pos=(1721.711, 1066.606) offered=3 success=3 failed=4 rewards=3
ACTIVITY event=failed kind=supply time=285.00 age=20.00 pos=(1721.711, 1066.606) offered=3 success=3 failed=5 rewards=3
ACTIVITIESTEST trader_priority_no_reward=true
ACTIVITIESTEST wave_respects_existing_cap=true
ACTIVITIESTEST alarm_blocks_activity_wave=true
ACTIVITIESTEST checks=75 failures=0 rewards=3 ok=true

EXIT=0
```

## ev1_sim_headless_final.log

```text
COMMAND ['C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe', '--headless', '--path', '.', '--', '--sim=600', '--fresh-save', '--layout-seed=81073']
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=195.48 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
PICK lvl=2 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["weapon", "module", "level"]
PICK lvl=3 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["ammo", "level", "passive"]
ACTIVITY event=start kind=carrier time=57.47 age=0.00 pos=(1240.0, 568.0) offered=1 success=0 failed=0 rewards=0
SIM 01:00 level=3 kills=38 xp=36/38 credits=4/4 credits_left=4 zombies=51 kinds=50/1/0/0 elites=0 elites_spawned=0 crates=0 nades=1 dmg_taken=31 peak=51 fps=145 | АК-С L2 Крио1 []
ACTIVITY event=success kind=carrier time=63.40 age=5.93 pos=(1325.233, 493.8046) offered=1 success=1 failed=0 rewards=1
PICK lvl=4 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["weapon", "module", "level"]
PICK lvl=5 { "type": "weapon", "id": 1, "rare": false } slot=-1 of ["module", "level", "weapon"]
PICK lvl=6 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["level", "level", "passive"]
PICK lvl=7 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["level", "passive", "weapon"]
SIM 02:00 level=7 kills=193 xp=213/228 credits=11/13 credits_left=11 zombies=74 kinds=74/0/0/0 elites=0 elites_spawned=0 crates=0 nades=6 dmg_taken=238 peak=91 fps=145 | АК-С L3 Крио1 [] | Мясник L1 Стан1 []
PICK lvl=8 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "level", "module"]
ACTIVITY event=start kind=supply time=152.87 age=0.00 pos=(1226.468, 880.5485) offered=2 success=1 failed=0 rewards=1
ACTIVITY event=success kind=supply time=174.33 age=21.47 pos=(1226.468, 880.5485) offered=2 success=2 failed=0 rewards=2
LOOT СНАБЖЕНИЕ: module slot=0 rare=true
PICK lvl=9 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["ammo", "level", "passive"]
SIM 03:00 level=9 kills=433 xp=380/468 credits=21/27 credits_left=21 zombies=93 kinds=92/1/0/0 elites=0 elites_spawned=0 crates=0 nades=9 dmg_taken=810 peak=96 fps=145 | АК-С L3 Крио1 [Спли1] | Мясник L2 Стан1 []
PICK lvl=10 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["ammo", "level", "module"]
PICK lvl=11 { "type": "module", "id": 5, "rare": false } slot=0 of ["module", "module", "level"]
SIM 04:00 level=11 kills=709 xp=715/774 credits=47/53 credits_left=47 zombies=84 kinds=59/16/9/0 elites=0 elites_spawned=0 crates=0 nades=15 dmg_taken=2548 peak=93 fps=145 | АК-С L3 Крио1 [Спли1,Цепь1] | Мясник L3 Стан1 []
PICK lvl=12 { "type": "weapon", "id": 3, "rare": false } slot=-1 of ["ammo", "weapon", "passive"]
PICK lvl=13 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "level", "weapon"]
PICK lvl=14 { "type": "weapon", "id": 5, "rare": false } slot=-1 of ["passive", "level", "weapon"]
TRADER 0 at 05:00 credits_left=2 bought=["module(40)", "module(40)"]
SIM 05:00 level=14 kills=1074 xp=1125/1229 credits=82/96 credits_left=2 zombies=83 kinds=63/11/9/0 elites=0 elites_spawned=0 crates=0 nades=18 dmg_taken=2858 peak=124 fps=145 | АК-С L4 Крио1 [Спли1,Цепь1] | Мясник L3 Стан1 [Проб1,Рико1] | Гром L1 Стан1 [] | Бульдог L1 Стан1 []
PICK lvl=15 { "type": "module", "id": 1, "rare": false } slot=1 of ["module", "level", "module"]
ACTIVITY event=start kind=fuel time=328.07 age=0.00 pos=(1402.004, 671.5276) offered=3 success=2 failed=0 rewards=2
ACTIVITY event=success kind=fuel time=340.73 age=12.67 pos=(1402.004, 671.5276) offered=3 success=3 failed=0 rewards=3
PICK lvl=16 { "type": "module", "id": 0, "rare": false } slot=1 of ["level", "module", "module"]
SIM 06:00 level=16 kills=1450 xp=1458/1778 credits=128/182 credits_left=48 zombies=138 kinds=83/19/20/16 elites=0 elites_spawned=2 crates=0 nades=20 dmg_taken=3170 peak=200 fps=145 | АК-С L4 Крио1 [Спли1,Цепь1] | Мясник L3 Стан1 [Проб2,Рико2] | Гром L1 Стан1 [] | Бульдог L1 Стан1 []
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=0 rare=true
PICK lvl=17 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "passive", "passive"]
PICK lvl=18 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["module", "passive", "ammo"]
PICK lvl=19 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "module", "level"]
SIM 07:00 level=19 kills=2054 xp=2232/2677 credits=232/320 credits_left=152 zombies=18 kinds=8/0/4/6 elites=0 elites_spawned=4 crates=1 nades=25 dmg_taken=4003 peak=154 fps=145 | АК-С L4 Крио1 [Спли1,Цепь2] | Мясник L4 Стан1 [Проб2,Рико2] | Гром L1 Стан1 [] | Бульдог L2 Стан1 []
ALARM_EVENT warn time=07:00
ALARM_EVENT start time=07:03
PICK lvl=20 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "level", "module"]
PICK lvl=21 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["level", "module", "passive"]
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=0 rare=true
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
PICK lvl=22 { "type": "module", "id": 2, "rare": false } slot=0 of ["module", "ammo", "module"]
PICK lvl=23 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "level", "module"]
PICK lvl=24 { "type": "module", "id": 5, "rare": false } slot=2 of ["level", "ammo", "module"]
ALARM_EVENT finish container=(2243.768, 525.1582) time=07:33
CONTAINER dropped pos=(2243.768, 525.1582) time=07:33
ALARM rewards mult=2 xp=2156 credits=300
LOOT СБРОС СНАБЖЕНИЯ: module slot=0 rare=false
CONTAINER picked time=07:34 crates=4
PICK lvl=25 { "type": "module", "id": 2, "rare": false } slot=3 of ["level", "module", "passive"]
PICK lvl=26 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["ammo", "passive", "passive"]
SIM 08:00 level=26 kills=2999 xp=4768/5129 credits=583/651 credits_left=503 zombies=63 kinds=40/0/13/10 elites=0 elites_spawned=10 crates=4 nades=28 dmg_taken=5042 peak=161 fps=145 | АК-С L5 Крио1 [Спли3,Цепь3] | Мясник L4 Стан1 [Проб2,Рико2] | Гром L1 Стан1 [Цепь1] | Бульдог L3 Стан1 [Спли1]
PICK lvl=27 { "type": "module", "id": 4, "rare": false } slot=0 of ["ammo", "module", "module"]
PICK lvl=28 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "module", "passive"]
CALM 09:00 removed=130 left=0
TRADER 1 at 09:00 credits_left=204 bought=["ammo(60)", "module(60)", "level(75)", "level(75)", "ammo(150)"]
SIM 09:00 level=28 kills=3594 xp=5531/5992 credits=704/778 credits_left=204 zombies=130 kinds=84/9/27/10 elites=0 elites_spawned=12 crates=4 nades=30 dmg_taken=5221 peak=131 fps=145 | АК-С L5 Эксп1 [Спли3,Цепь3,Сдво1] | Мясник L5 Стан1 [Проб2,Рико2,Спли1] | Гром L2 Стан1 [Цепь1] | Бульдог L4 Стан1 [Спли1]
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
PICK lvl=29 { "type": "module", "id": 0, "rare": false } slot=1 of ["level", "level", "module"]
BOSS spawn t=600.00 pos=(2422.186, 867.7889) hp=24000
SIM 10:00 level=29 kills=3789 xp=5970/6235 credits=755/809 credits_left=255 zombies=21 kinds=18/3/0/0 elites=0 elites_spawned=14 crates=4 nades=31 dmg_taken=5221 peak=34 fps=145 | АК-С L5 Эксп2 [Спли3,Цепь3,Сдво1] | Мясник L5 Стан1 [Проб2,Рико3,Спли1] | Гром L2 Стан1 [Цепь1] | Бульдог L4 Стан1 [Спли1]
SIM summary kills=3789 peak=200 level=29 damage=5220.81 boss_alive=true

EXIT=0
```

## ev1_sim_final.log

```text
COMMAND ['bash', 'C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh', 'C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe', '--windowed', '--resolution', '1920x1080', '--disable-vsync', '--path', '.', '--', '--sim=600', '--fresh-save', '--layout-seed=81073', '--activities-seed=27', '--activities-capture']
GODOT_EXCLUSIVE other_godot_processes=0 at 14:50:47
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=247.68 seed=81073
ACTIVITIES seed=27 map=quarantine_checkpoint schedule=[{ "time": 63.0620880126953, "kind": 0 }, { "time": 159.607849121094, "kind": 2 }, { "time": 333.38916015625, "kind": 1 }, { "time": 472.279296875, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
PICK lvl=2 { "type": "weapon", "id": 1, "rare": false } slot=-1 of ["weapon", "level", "ammo"]
PICK lvl=3 { "type": "module", "id": 2, "rare": false } slot=0 of ["level", "module", "level"]
SIM 01:00 level=3 kills=39 xp=29/39 credits=0/0 credits_left=0 zombies=48 kinds=48/0/0/0 elites=0 elites_spawned=0 crates=0 nades=2 dmg_taken=19 peak=59 fps=358 | АК-С L1 Стан1 [Спли1] | Мясник L1 Стан1 []
ACTIVITY event=start kind=supply time=63.07 age=0.00 pos=(1720.0, 1048.0) offered=1 success=0 failed=0 rewards=0
ACTIVITYSHOT live=true res://design/tasks/reports/ev1_live_supply_1_start.png
ACTIVITYSHOT live=true res://design/tasks/reports/ev1_live_supply_1_peak.png
ACTIVITY event=success kind=supply time=85.20 age=22.13 pos=(1720.0, 1048.0) offered=1 success=1 failed=0 rewards=1
LOOT СНАБЖЕНИЕ: module slot=1 rare=false
PICK lvl=4 { "type": "weapon", "id": 7, "rare": false } slot=-1 of ["weapon", "weapon", "module"]
PICK lvl=5 { "type": "module", "id": 5, "rare": false } slot=2 of ["weapon", "level", "module"]
PICK lvl=6 { "type": "module", "id": 2, "rare": false } slot=0 of ["level", "module", "ammo"]
SIM 02:00 level=6 kills=225 xp=180/225 credits=8/10 credits_left=8 zombies=60 kinds=60/0/0/0 elites=0 elites_spawned=0 crates=0 nades=5 dmg_taken=32 peak=68 fps=330 | АК-С L1 Стан1 [Спли2] | Мясник L1 Стан1 [Дето1] | Мосинка L1 Стан1 [Цепь1]
PICK lvl=7 { "type": "weapon", "id": 2, "rare": false } slot=-1 of ["level", "weapon", "weapon"]
PICK lvl=8 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["passive", "module", "level"]
ACTIVITY event=start kind=fuel time=159.67 age=0.00 pos=(1972.072, 1269.621) offered=2 success=1 failed=0 rewards=1
ACTIVITYSHOT live=true res://design/tasks/reports/ev1_live_fuel_2_start.png
ACTIVITYSHOT live=true res://design/tasks/reports/ev1_live_fuel_2_peak.png
ACTIVITY event=success kind=fuel time=173.87 age=14.20 pos=(1972.072, 1269.621) offered=2 success=2 failed=0 rewards=2
PICK lvl=9 { "type": "module", "id": 1, "rare": false } slot=3 of ["level", "level", "module"]
SIM 03:00 level=9 kills=449 xp=362/449 credits=16/37 credits_left=16 zombies=80 kinds=80/0/0/0 elites=0 elites_spawned=0 crates=0 nades=7 dmg_taken=38 peak=91 fps=324 | АК-С L1 Стан1 [Спли2] | Мясник L2 Стан1 [Дето1] | Мосинка L1 Стан1 [Цепь1] | Игла L1 Стан1 [Проб1]
PICK lvl=10 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "level", "module"]
SIM 04:00 level=10 kills=759 xp=545/774 credits=22/60 credits_left=22 zombies=41 kinds=38/0/3/0 elites=0 elites_spawned=0 crates=0 nades=9 dmg_taken=48 peak=96 fps=284 | АК-С L1 Стан1 [Спли2] | Мясник L2 Стан1 [Дето1] | Мосинка L1 Стан1 [Цепь1] | Игла L2 Стан1 [Проб1]
PICK lvl=11 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["level", "passive", "module"]
PICK lvl=12 { "type": "module", "id": 3, "rare": false } slot=1 of ["module", "passive", "passive"]
TRADER 0 at 05:00 credits_left=3 bought=["passive(40)"]
SIM 05:00 level=12 kills=1001 xp=840/1070 credits=43/86 credits_left=3 zombies=158 kinds=128/15/15/0 elites=0 elites_spawned=0 crates=0 nades=10 dmg_taken=48 peak=163 fps=295 | АК-С L1 Стан1 [Спли2] | Мясник L2 Стан1 [Дето2] | Мосинка L1 Стан1 [Цепь1] | Игла L2 Стан1 [Проб1]
PICK lvl=13 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["module", "passive", "ammo"]
PICK lvl=14 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["module", "ammo", "level"]
ACTIVITY event=start kind=carrier time=333.40 age=0.00 pos=(1724.664, 798.2916) offered=3 success=2 failed=0 rewards=2
ACTIVITYSHOT live=true res://design/tasks/reports/ev1_live_carrier_3_start.png
ACTIVITYSHOT live=true res://design/tasks/reports/ev1_live_carrier_3_peak.png
ACTIVITY event=success kind=carrier time=341.73 age=8.33 pos=(1468.903, 792.1459) offered=3 success=3 failed=0 rewards=3
PICK lvl=15 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["module", "passive", "ammo"]
SIM 06:00 level=15 kills=1441 xp=1352/1679 credits=99/152 credits_left=59 zombies=133 kinds=79/11/21/22 elites=0 elites_spawned=2 crates=0 nades=14 dmg_taken=1117 peak=208 fps=234 | АК-С L1 Эксп2 [Спли2] | Мясник L2 Стан1 [Дето2] | Мосинка L2 Стан1 [Цепь1] | Игла L2 Стан1 [Проб1]
PICK lvl=16 { "type": "module", "id": 3, "rare": false } slot=1 of ["level", "module", "passive"]
PICK lvl=17 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["ammo", "module", "ammo"]
PICK lvl=18 { "type": "module", "id": 1, "rare": false } slot=3 of ["module", "passive", "level"]
SIM 07:00 level=18 kills=1913 xp=1978/2373 credits=183/247 credits_left=143 zombies=155 kinds=114/18/12/11 elites=0 elites_spawned=4 crates=0 nades=19 dmg_taken=2136 peak=161 fps=270 | АК-С L1 Зажи1 [Спли2] | Мясник L2 Стан1 [Дето3] | Мосинка L2 Стан1 [Цепь1] | Игла L2 Стан1 [Проб2]
ALARM_EVENT warn time=07:00
ALARM_EVENT start time=07:03
PICK lvl=19 { "type": "module", "id": 2, "rare": false } slot=0 of ["passive", "module", "level"]
PICK lvl=20 { "type": "module", "id": 1, "rare": false } slot=3 of ["level", "level", "module"]
PICK lvl=21 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["module", "level", "passive"]
PICK lvl=22 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "level", "ammo"]
ALARM_EVENT finish container=(1639.811, 1171.461) time=07:33
CONTAINER dropped pos=(1639.811, 1171.461) time=07:33
ALARM rewards mult=2 xp=1960 credits=268
LOOT СБРОС СНАБЖЕНИЯ: module slot=3 rare=true
CONTAINER picked time=07:34 crates=1
PICK lvl=23 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["level", "level", "passive"]
PICK lvl=24 { "type": "module", "id": 5, "rare": false } slot=2 of ["module", "level", "ammo"]
PICK lvl=25 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["level", "module", "passive"]
ACTIVITY event=start kind=fuel time=472.33 age=0.00 pos=(1018.889, 1154.605) offered=4 success=3 failed=0 rewards=3
ACTIVITYSHOT live=true res://design/tasks/reports/ev1_live_fuel_4_start.png
ACTIVITYSHOT live=true res://design/tasks/reports/ev1_live_fuel_4_peak.png
SIM 08:00 level=25 kills=2865 xp=4258/4769 credits=490/576 credits_left=450 zombies=200 kinds=140/24/18/18 elites=0 elites_spawned=10 crates=1 nades=23 dmg_taken=3778 peak=443 fps=206 | АК-С L1 Зажи1 [Спли3] | Мясник L2 Стан1 [Дето3] | Мосинка L4 Стан1 [Цепь2] | Игла L3 Стан1 [Проб3,Дето1]
ACTIVITY event=success kind=fuel time=485.33 age=13.00 pos=(1018.889, 1154.605) offered=4 success=4 failed=0 rewards=4
PICK lvl=26 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["module", "level", "passive"]
PICK lvl=27 { "type": "module", "id": 5, "rare": false } slot=2 of ["module", "module", "ammo"]
CALM 09:00 removed=164 left=18
TRADER 1 at 09:00 credits_left=216 bought=["ammo(60)", "passive(60)", "level(75)", "module(60)", "ammo(60)"]
SIM 09:00 level=27 kills=3546 xp=5022/5704 credits=571/680 credits_left=216 zombies=182 kinds=117/21/30/14 elites=1 elites_spawned=12 crates=1 nades=27 dmg_taken=5288 peak=386 fps=165 | АК-С L2 Эксп1 [Спли3] | Мясник L2 Стан1 [Дето3] | Мосинка L5 Стан1 [Цепь3,Проб1] | Игла L3 Стан1 [Проб3,Дето1]
PICK lvl=28 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "passive", "level"]
BOSS spawn t=600.00 pos=(1642.924, 836.1246) hp=24000
SIM 10:00 level=28 kills=3721 xp=5577/5946 credits=631/712 credits_left=276 zombies=55 kinds=55/0/0/0 elites=0 elites_spawned=14 crates=1 nades=27 dmg_taken=5288 peak=85 fps=240 | АК-С L2 Эксп1 [Спли3] | Мясник L2 Стан1 [Дето3] | Мосинка L5 Стан1 [Цепь3,Проб1] | Игла L4 Стан1 [Проб3,Дето1]
SIM summary kills=3721 peak=443 level=28 damage=5287.55 boss_alive=true
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT=0
```

## ev1_fx_final.log

```text
COMMAND ['bash', 'C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh', 'C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe', '--windowed', '--resolution', '1920x1080', '--disable-vsync', '--path', '.', '--', '--fx-test', '--fresh-save', '--shot=res://design/tasks/reports/ev1_fx/ev1_fx.png']
GODOT_EXCLUSIVE other_godot_processes=0 at 14:56:45
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=243.59 seed=81073
FXTEST sheet=seq ages=0.05,0.15,0.4,1.5
FXTEST sheet=crowd ages=0.05,0.15,0.4,1.5
FXTEST sheet=fat ages=0.05,0.15,0.4,1.5
FXTEST sheet=boss ages=0.05,0.15,0.4,1.5
FXBENCH warm_chain20 baseline=false enemies=500 frames=1196 avg_ms=3.183 worst_ms=8.398 physics_worst_ms=4.911 draw_calls_peak=133 spawn_worst_ms=0.234 update_worst_ms=0.286 draw_submit_worst_ms=1.390 peak=420
FXBENCH warm_boss baseline=false enemies=500 frames=803 avg_ms=3.787 worst_ms=7.817 physics_worst_ms=6.537 draw_calls_peak=146 spawn_worst_ms=1.159 update_worst_ms=0.389 draw_submit_worst_ms=0.869 peak=180
FXBENCH chain20 baseline=false enemies=500 frames=997 avg_ms=3.860 worst_ms=9.273 physics_worst_ms=6.076 draw_calls_peak=125 spawn_worst_ms=0.168 update_worst_ms=0.223 draw_submit_worst_ms=1.485 peak=406
FXBENCH boss baseline=false enemies=500 frames=735 avg_ms=4.145 worst_ms=8.851 physics_worst_ms=6.666 draw_calls_peak=138 spawn_worst_ms=1.268 update_worst_ms=0.521 draw_submit_worst_ms=0.900 peak=180
FXTEST ok=true pool_cap=592 overflow_replaced=2708 idle_process=false
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT=0
```

## ev1_bench_before_engine.log

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=393.34 seed=81073
BENCH frames=1556 avg_fps=155.5 avg_frame_ms=6.43 worst_frame_ms=34.24 horde_ms=2.36 enemies=497 kills=859
BENCH process_ms=7.54 physics_ms=11.40 draw_calls=452 objects=3366 gore=681 particles=802 wet=28
BENCH physics_avg_ms=12.11 hud_ms=0.226
BENCH screenshot: design/tasks/reports/ev1_battle_before.png
```

## ev1_bench_after.log

```text
COMMAND ['bash', 'C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh', 'C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe', '--windowed', '--resolution', '1920x1080', '--disable-vsync', '--path', '.', '--', '--loadout', '--bench=500', '--fresh-save', '--shot=design/tasks/reports/ev1_battle_after.png']
GODOT_EXCLUSIVE other_godot_processes=0 at 14:53:59
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=239.77 seed=81073
BENCH frames=1507 avg_fps=150.6 avg_frame_ms=6.64 worst_frame_ms=30.89 horde_ms=2.23 enemies=498 kills=1029
BENCH process_ms=9.02 physics_ms=10.17 draw_calls=538 objects=3616 gore=765 particles=1454 wet=91
BENCH physics_avg_ms=11.71 hud_ms=0.210
BENCH screenshot: design/tasks/reports/ev1_battle_after.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT=0
```

## ev1_bench_active_after.log

```text
COMMAND ['bash', 'C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh', 'C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe', '--windowed', '--resolution', '1920x1080', '--disable-vsync', '--path', '.', '--', '--loadout', '--bench=500', '--fresh-save', '--activities-bench', '--shot=design/tasks/reports/ev1_battle_active_after.png']
GODOT_EXCLUSIVE other_godot_processes=0 at 14:55:08
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=236.45 seed=81073
BENCH frames=1696 avg_fps=169.5 avg_frame_ms=5.90 worst_frame_ms=21.57 horde_ms=2.31 enemies=498 kills=1051
BENCH process_ms=6.03 physics_ms=8.08 draw_calls=465 objects=3466 gore=200 particles=656 wet=28
BENCH physics_avg_ms=11.56 hud_ms=0.202
BENCH screenshot: design/tasks/reports/ev1_battle_active_after.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT=0
```

## ev1_alarm_before.log

```text
COMMAND ['bash', 'C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh', 'C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe', '--windowed', '--resolution', '1920x1080', '--disable-vsync', '--path', '.', '--', '--alarm', '--fresh-save', '--layout-seed=81073', '--shot=design/tasks/reports/ev1_alarm_before.png']
GODOT_EXCLUSIVE other_godot_processes=0 at 14:37:53
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=342.23 seed=81073
HITCH 133.3 ms t=-4.87 zombies=301 level=1
ALARM t=-5 phase=IDLE zombies=301 fps=1 worst_ms=0.0 pools=0 spits=0
HITCH 91.3 ms t=-4.77 zombies=295 level=1
ALARM t=-4 phase=IDLE zombies=176 fps=88 worst_ms=0.0 pools=0 spits=3
ALARM t=-3 phase=IDLE zombies=124 fps=99 worst_ms=5.6 pools=1 spits=4
ALARM t=-2 phase=IDLE zombies=81 fps=162 worst_ms=13.7 pools=5 spits=2
ALARM t=-1 phase=IDLE zombies=80 fps=188 worst_ms=13.7 pools=7 spits=0
ALARM_EVENT warn time=07:00
ALARM t=0 phase=WARN zombies=62 fps=189 worst_ms=13.7 pools=6 spits=0
ALARM t=1 phase=WARN zombies=60 fps=177 worst_ms=16.1 pools=2 spits=0
ALARM t=2 phase=WARN zombies=62 fps=236 worst_ms=16.1 pools=0 spits=0
ALARM_EVENT start time=07:03
ALARM t=3 phase=ACTIVE zombies=71 fps=259 worst_ms=16.1 pools=0 spits=0
ALARM t=4 phase=ACTIVE zombies=61 fps=241 worst_ms=16.1 pools=0 spits=0
ALARM t=5 phase=ACTIVE zombies=67 fps=243 worst_ms=16.1 pools=0 spits=0
ALARM t=6 phase=ACTIVE zombies=95 fps=237 worst_ms=16.1 pools=0 spits=0
ALARM t=7 phase=ACTIVE zombies=111 fps=236 worst_ms=16.1 pools=0 spits=0
ALARM t=8 phase=ACTIVE zombies=137 fps=249 worst_ms=16.1 pools=0 spits=0
ALARM t=9 phase=ACTIVE zombies=142 fps=238 worst_ms=16.1 pools=0 spits=0
ALARM t=10 phase=ACTIVE zombies=143 fps=193 worst_ms=16.1 pools=0 spits=0
ALARM t=11 phase=ACTIVE zombies=166 fps=207 worst_ms=16.1 pools=0 spits=0
ALARM t=12 phase=ACTIVE zombies=183 fps=226 worst_ms=16.1 pools=0 spits=0
ALARM t=13 phase=ACTIVE zombies=210 fps=239 worst_ms=16.1 pools=0 spits=0
CHAIN fats spawned, first burst queued, alive=222
ALARM t=14 phase=ACTIVE zombies=240 fps=200 worst_ms=16.1 pools=0 spits=0
ALARM t=15 phase=ACTIVE zombies=184 fps=188 worst_ms=16.1 pools=0 spits=0
CHAIN worst_frame_ms=12.9 frames=445
ALARM t=16 phase=ACTIVE zombies=170 fps=165 worst_ms=16.1 pools=0 spits=0
ALARM t=17 phase=ACTIVE zombies=119 fps=195 worst_ms=16.1 pools=0 spits=0
ALARM t=18 phase=ACTIVE zombies=110 fps=231 worst_ms=16.1 pools=0 spits=0
ALARM screenshot: design/tasks/reports/ev1_alarm_before.png
HITCH 145.8 ms t=18.15 zombies=110 level=5
ALARM t=19 phase=ACTIVE zombies=110 fps=128 worst_ms=16.1 pools=0 spits=0
ALARM t=20 phase=ACTIVE zombies=137 fps=240 worst_ms=16.1 pools=0 spits=0
ALARM t=21 phase=ACTIVE zombies=96 fps=234 worst_ms=16.1 pools=0 spits=0
ALARM t=22 phase=ACTIVE zombies=96 fps=227 worst_ms=16.1 pools=0 spits=0
ALARM t=23 phase=ACTIVE zombies=99 fps=218 worst_ms=16.1 pools=0 spits=0
ALARM t=24 phase=ACTIVE zombies=127 fps=195 worst_ms=16.1 pools=0 spits=0
ALARM t=25 phase=ACTIVE zombies=140 fps=209 worst_ms=16.1 pools=0 spits=0
HITCH 62.2 ms t=25.37 zombies=121 level=5
ALARM t=26 phase=ACTIVE zombies=131 fps=215 worst_ms=62.2 pools=0 spits=1
ALARM t=27 phase=ACTIVE zombies=153 fps=209 worst_ms=62.2 pools=1 spits=0
ALARM t=28 phase=ACTIVE zombies=182 fps=207 worst_ms=62.2 pools=1 spits=0
ALARM t=29 phase=ACTIVE zombies=207 fps=242 worst_ms=62.2 pools=1 spits=0
ALARM t=30 phase=ACTIVE zombies=215 fps=247 worst_ms=62.2 pools=0 spits=0
ALARM t=31 phase=ACTIVE zombies=223 fps=208 worst_ms=62.2 pools=0 spits=0
ALARM t=32 phase=ACTIVE zombies=228 fps=190 worst_ms=62.2 pools=0 spits=0
ALARM_EVENT finish container=(1291.365, 723.9124) time=07:33
CONTAINER dropped pos=(1291.365, 723.9124) time=07:33
ALARM rewards mult=2 xp=1746 credits=258
ALARM t=33 phase=DONE zombies=246 fps=167 worst_ms=62.2 pools=0 spits=0
ALARM screenshot: design/tasks/reports/ev1_alarm_before_container.png
HITCH 147.3 ms t=34.07 zombies=257 level=5
ALARM t=34 phase=DONE zombies=257 fps=190 worst_ms=62.2 pools=0 spits=0
CONTAINER picked time=07:34 crates=1
ALARM t=35 phase=DONE zombies=267 fps=129 worst_ms=62.2 pools=0 spits=0
ALARM summary peak_zombies=267 min_fps=99 worst_frame_ms=62.2 physics_ms=5.65 process_ms=389.25 draw_calls=617 horde_ms=1.42
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT=0
```

## ev1_sim_before_engine.log

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=183.37 seed=81073
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
PICK lvl=2 { "type": "module", "id": 1, "rare": false } slot=0 of ["weapon", "level", "module"]
PICK lvl=3 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "ammo", "passive"]
PICK lvl=4 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["weapon", "level", "module"]
SIM 01:00 level=4 kills=62 xp=53/62 credits=3/4 credits_left=3 zombies=25 kinds=25/0/0/0 elites=0 elites_spawned=0 crates=0 nades=2 dmg_taken=0 peak=39 fps=145 | АК-С L3 Стан1 [Проб1]
PICK lvl=5 { "type": "weapon", "id": 6, "rare": false } slot=-1 of ["level", "weapon", "passive"]
PICK lvl=6 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["level", "weapon", "ammo"]
PICK lvl=7 { "type": "module", "id": 2, "rare": true } slot=0 of ["module", "level", "weapon"]
SIM 02:00 level=7 kills=216 xp=200/216 credits=9/9 credits_left=9 zombies=50 kinds=50/0/0/0 elites=0 elites_spawned=0 crates=0 nades=5 dmg_taken=120 peak=64 fps=145 | АК-С L3 Эксп1 [Проб1,Спли1] | ППШ L1 Стан1 []
PICK lvl=8 { "type": "weapon", "id": 7, "rare": false } slot=-1 of ["level", "weapon", "weapon"]
PICK lvl=9 { "type": "module", "id": 1, "rare": false } slot=0 of ["module", "passive", "level"]
SIM 03:00 level=9 kills=488 xp=403/488 credits=17/22 credits_left=17 zombies=23 kinds=23/0/0/0 elites=0 elites_spawned=0 crates=0 nades=10 dmg_taken=1520 peak=104 fps=145 | АК-С L3 Эксп1 [Проб2,Спли1] | ППШ L1 Стан1 [] | Мосинка L1 Стан1 []
PICK lvl=10 { "type": "weapon", "id": 3, "rare": false } slot=-1 of ["level", "ammo", "weapon"]
PICK lvl=11 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["module", "level", "ammo"]
PICK lvl=12 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["module", "level", "module"]
SIM 04:00 level=12 kills=753 xp=729/774 credits=39/42 credits_left=39 zombies=21 kinds=14/0/7/0 elites=0 elites_spawned=0 crates=0 nades=12 dmg_taken=1534 peak=34 fps=145 | АК-С L3 Стан1 [Проб2,Спли1] | ППШ L2 Стан1 [] | Мосинка L1 Стан1 [] | Гром L1 Стан1 []
PICK lvl=13 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["passive", "level", "module"]
PICK lvl=14 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["passive", "level", "passive"]
TRADER 0 at 05:00 credits_left=24 bought=["level(50)"]
SIM 05:00 level=14 kills=1127 xp=1142/1262 credits=74/90 credits_left=24 zombies=13 kinds=12/0/1/0 elites=0 elites_spawned=0 crates=0 nades=16 dmg_taken=1658 peak=35 fps=145 | АК-С L4 Стан1 [Проб2,Спли1] | ППШ L2 Стан1 [] | Мосинка L1 Стан1 [] | Гром L1 Стан1 []
PICK lvl=15 { "type": "module", "id": 3, "rare": false } slot=1 of ["module", "module", "ammo"]
PICK lvl=16 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "level", "ammo"]
PICK lvl=17 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["ammo", "level", "passive"]
SIM 06:00 level=17 kills=1529 xp=1836/1911 credits=189/196 credits_left=139 zombies=30 kinds=16/0/9/5 elites=0 elites_spawned=2 crates=0 nades=19 dmg_taken=1765 peak=46 fps=145 | АК-С L4 Стан1 [Проб2,Спли1] | ППШ L2 Стан1 [Дето1] | Мосинка L2 Стан1 [] | Гром L1 Стан1 []
PICK lvl=18 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["ammo", "module", "level"]
PICK lvl=19 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["level", "ammo", "passive"]
PICK lvl=20 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["passive", "level", "ammo"]
SIM 07:00 level=20 kills=2034 xp=2468/2698 credits=278/304 credits_left=228 zombies=8 kinds=4/0/2/2 elites=0 elites_spawned=4 crates=0 nades=22 dmg_taken=1973 peak=75 fps=145 | АК-С L4 Эксп1 [Проб2,Спли1] | ППШ L2 Стан1 [Дето1] | Мосинка L2 Стан1 [] | Гром L1 Стан1 []
ALARM_EVENT warn time=07:00
ALARM_EVENT start time=07:03
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=0 rare=true
PICK lvl=21 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["module", "level", "level"]
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
PICK lvl=22 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["passive", "level", "module"]
PICK lvl=23 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["module", "passive", "level"]
ALARM_EVENT finish container=(2369.434, 729.4971) time=07:33
CONTAINER dropped pos=(2369.434, 729.4971) time=07:33
ALARM rewards mult=2 xp=2182 credits=294
LOOT СБРОС СНАБЖЕНИЯ: module slot=2 rare=false
CONTAINER picked time=07:34 crates=1
PICK lvl=24 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["module", "level", "level"]
PICK lvl=25 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "module", "level"]
SIM 08:00 level=25 kills=3021 xp=4481/5270 credits=550/630 credits_left=500 zombies=7 kinds=4/0/3/0 elites=0 elites_spawned=10 crates=1 nades=26 dmg_taken=2032 peak=191 fps=145 | АК-С L4 Крио1 [Проб2,Спли2] | ППШ L3 Стан1 [Дето1] | Мосинка L4 Стан1 [Цепь1] | Гром L3 Стан1 []
PICK lvl=26 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "level", "module"]
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
PICK lvl=27 { "type": "module", "id": 1, "rare": true } slot=0 of ["level", "module", "module"]
PICK lvl=28 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["module", "level", "ammo"]
PICK lvl=29 { "type": "module", "id": 4, "rare": false } slot=0 of ["module", "module", "module"]
CALM 09:00 removed=61 left=7
TRADER 1 at 09:00 credits_left=163 bought=["module(150)", "passive(60)", "ammo(150)", "module(60)", "level(75)"]
SIM 09:00 level=29 kills=3629 xp=5946/6126 credits=708/736 credits_left=163 zombies=68 kinds=40/6/13/9 elites=0 elites_spawned=12 crates=1 nades=28 dmg_taken=2073 peak=68 fps=145 | АК-С L5 Стан1 [Проб3,Спли2,Сдво1] | ППШ L3 Стан1 [Дето1,Рико1] | Мосинка L4 Стан1 [Цепь1,Проб1] | Гром L4 Стан1 []
PICK lvl=30 { "type": "module", "id": 1, "rare": false } slot=2 of ["module", "module", "passive"]
BOSS spawn t=600.00 pos=(2057.959, 942.8546) hp=24000
SIM 10:00 level=30 kills=3793 xp=6288/6346 credits=761/767 credits_left=216 zombies=53 kinds=41/12/0/0 elites=0 elites_spawned=14 crates=1 nades=30 dmg_taken=2073 peak=54 fps=145 | АК-С L5 Стан1 [Проб3,Спли2,Сдво1] | ППШ L3 Стан1 [Дето1,Рико1] | Мосинка L4 Стан1 [Цепь1,Проб2] | Гром L4 Стан1 []
SIM summary kills=3793 peak=191 level=30 damage=2072.93 boss_alive=true
```

## ev1_shots_final.log

```text
COMMAND ['bash', 'C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh', 'C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe', '--windowed', '--resolution', '1920x1080', '--disable-vsync', '--path', '.', '--', '--activities-shots', '--fresh-save', '--layout-seed=81073', '--shot=res://design/tasks/reports/ev1.png']
GODOT_EXCLUSIVE other_godot_processes=0 at 14:56:23
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=252.88 seed=81073
ACTIVITIESTEST shot_supply_started=true
ACTIVITYSHOT res://design/tasks/reports/ev1_supply_start.png
ACTIVITYSHOT res://design/tasks/reports/ev1_supply.png
ACTIVITIESTEST shot_carrier_started=true
ACTIVITYSHOT res://design/tasks/reports/ev1_carrier_start.png
ACTIVITYSHOT res://design/tasks/reports/ev1_carrier.png
ACTIVITIESTEST shot_fuel_started=true
ACTIVITYSHOT res://design/tasks/reports/ev1_fuel_start.png
ACTIVITYSHOT res://design/tasks/reports/ev1_fuel.png
ACTIVITYSHOT res://design/tasks/reports/ev1_pointer.png
ACTIVITYSHOTS ok=true standard_camera=true staged=true
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT=0
```

## ev1_scope.log

```text
EV1ART deterministic=true sprites=8 python=3.13.9
EV1PNG activity_carrier.png size=(66, 72) sha256=0e10da8da5bc4dd3858eb4a4c7441ce9ce725be2b4e6503c5e2b1cda29829eeb
EV1PNG activity_fuel.png size=(234, 192) sha256=1a43f32488494c32ba9ec320eeaab5f90d31ee56c5d0b9c2b16432b63374e88c
EV1PNG activity_fuel_spent.png size=(234, 192) sha256=9a381c2399fa2ac91a5de1a02517cf4574bbe143fc15f78c398870b7bc9aa87e
EV1PNG activity_fuel_zone.png size=(456, 456) sha256=489ad6ee4308f055343050eaae5ed83e10507e8621746fc3b532e44484f7103f
EV1PNG activity_parachute.png size=(228, 228) sha256=f5e88f7adbc1a6dd3a0409da380dd7405d394c366a25571837ee26b48c4c863b
EV1PNG activity_smoke.png size=(126, 192) sha256=e973b9f3a8fa8344066f8ad33735e8f094b367a0e8127c5d2c303b32371d2a7d
EV1PNG activity_supply.png size=(156, 126) sha256=3a56175ffea5da2b5714300a3349e418c0846dbc5f766f0cc6c2264c7e2319e7
EV1PNG activity_zone.png size=(312, 312) sha256=ed23163efd1f57e42a9a89770a354e57d7ba4d7384a4be086360f90c6baf3bf3
EV1PNG ev1_alarm_before.png size=(1920, 1080)
EV1PNG ev1_alarm_before_container.png size=(1920, 1080)
EV1PNG ev1_battle_active_after.png size=(1920, 1080)
EV1PNG ev1_battle_after.png size=(1920, 1080)
EV1PNG ev1_battle_before.png size=(1920, 1080)
EV1PNG ev1_carrier.png size=(1920, 1080)
EV1PNG ev1_carrier_start.png size=(1920, 1080)
EV1PNG ev1_fuel.png size=(1920, 1080)
EV1PNG ev1_fuel_start.png size=(1920, 1080)
EV1PNG ev1_live_carrier_3_peak.png size=(1920, 1080)
EV1PNG ev1_live_carrier_3_start.png size=(1920, 1080)
EV1PNG ev1_live_fuel_2_peak.png size=(1920, 1080)
EV1PNG ev1_live_fuel_2_start.png size=(1920, 1080)
EV1PNG ev1_live_fuel_4_peak.png size=(1920, 1080)
EV1PNG ev1_live_fuel_4_start.png size=(1920, 1080)
EV1PNG ev1_live_supply_1_peak.png size=(1920, 1080)
EV1PNG ev1_live_supply_1_start.png size=(1920, 1080)
EV1PNG ev1_pointer.png size=(1920, 1080)
EV1PNG ev1_supply.png size=(1920, 1080)
EV1PNG ev1_supply_start.png size=(1920, 1080)
EV1PNG ev1_timeline.png size=(1920, 900)
EV1DIFF check=0 output=''
EV1SCOPE files=86 unauthorized=[] forbidden_diff=[] default_bus_restored=true
```
