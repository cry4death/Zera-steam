# CP1 — команды и дословный вывод

Рабочая папка: `C:/Users/Dev/Desktop/zera-cp1`. APPDATA для каждого дочернего процесса перенаправлялся в `design/tasks/reports/cp1_userdata`. Настоящий профиль не использовался. Ниже сохранён вывод оболочки целиком: stdout и stderr; PowerShell разворачивает stderr в NativeCommandError. Строки ошибок не отфильтрованы. До/после относятся к разным версиям правил.

Оконный префикс WINDOW:
```text
bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --windowed --resolution 1920x1080 --disable-vsync --path . --
```

## cp1_baseline.log

Команда: `C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --campaign-test`

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.
At C:\Users\Dev\Desktop\zera-cp1\design\tasks\reports\cp1_run.ps1:15 char:9
+         & $engine --headless --path $root -- @GameArgs *> "$PSScriptR ...
+         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
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
Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в res://tmp/c1_migration.json.campaign-bad-4280952
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
       [4] _ready (res://scripts/game.gd:674)
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

## cp1_capture_before.log

Команда: `WINDOW --cp1-capture (код до CP1)`

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 15:05:18
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

bash.exe : ERROR: Failed to read the root certificate store.
At C:\Users\Dev\Desktop\zera-cp1\design\tasks\reports\cp1_run.ps1:11 char:9
+         & 'C:/Program Files/Git/bin/bash.exe' C:/Users/Dev/Desktop/ze ...
+         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
CP1TRACE seed=20261017 strategy=safe_four_then_recovery outcomes=victory
CP1TURN 1 offers=north_america:clearance:2,east_asia:extract:3,east_europe:nest:4 choice=north_america:clearance average=37.88->37.88 lost=0 phase=active
CP1TURN 2 offers=north_america:clearance:2,east_europe:extract:4,east_europe:nest:4 choice=north_america:clearance average=37.88->39.38 lost=0 phase=active
CP1TURN 3 offers=north_america:clearance:2,west_europe:extract:3,east_europe:nest:4 choice=north_america:clearance average=39.38->40.88 lost=0 phase=active
CP1TURN 4 offers=north_america:clearance:2,south_asia:extract:3,east_europe:nest:4 choice=north_america:clearance average=40.88->42.88 lost=0 phase=active
CP1TURN 5 offers=north_america:clearance:2,middle_east:extract:3,east_europe:nest:4 choice=east_europe:nest average=42.88->35.63 lost=0 phase=active
CP1TURN 6 offers=north_america:clearance:2,east_europe:extract:3,east_asia:clearance:4 choice=east_asia:clearance average=35.63->32.00 lost=0 phase=victory
CP1TURN 7 offers=north_america:clearance:2,siberia:extract:3,middle_east:clearance:4 choice=middle_east:clearance average=32.00->27.88 lost=0 phase=free
CP1TURN 8 offers=north_america:clearance:2,east_asia:extract:3,west_europe:clearance:5 choice=west_europe:clearance average=27.88->24.88 lost=0 phase=free
CP1TURN 9 offers=north_america:clearance:2,east_europe:extract:3,middle_east:clearance:4 choice=middle_east:clearance average=24.88->21.75 lost=0 phase=free
CP1TURN 10 offers=middle_east:clearance:2,siberia:extract:3,south_asia:clearance:4 choice=south_asia:clearance average=21.75->18.38 lost=0 phase=free
CP1TURN 11 offers=north_america:clearance:2,south_asia:extract:3,east_europe:clearance:5 choice=east_europe:clearance average=18.38->14.88 lost=0 phase=free
CP1TURN 12 offers=middle_east:clearance:2,north_america:extract:3,west_europe:clearance:5 choice=middle_east:clearance average=14.88->14.13 lost=0 phase=free
CP1SHOT res://design/tasks/reports/cp1_globe_before.png
CP1SHOT res://design/tasks/reports/cp1_briefing_before.png
CP1CAPTURE complete=true
EXIT=0
```

## cp1_import_final.log

Команда: `C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --headless --path . --import`

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.
строка:2 знак:71
+ ... data).Path; & 'C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/God ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
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
[   0% ] [90m[1mloading_editor_layout[22m | Started Загрузка редактора (5 steps)[39m[0m
[   0% ] [90m[1mloading_editor_layout[22m | Загрузка макета редактора…[39m[0m
[  16% ] [90m[1mloading_editor_layout[22m | Загрузка док-панели…[39m[0m
[92m[ DONE ][39m [1mloading_editor_layout[22m
[0m
EXIT=0
```

## cp1_meta_final.log

Команда: `C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --meta-test --cp1-paths`

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.
At C:\Users\Dev\Desktop\zera-cp1\design\tasks\reports\cp1_run.ps1:15 char:9
+         & $engine --headless --path $root -- @GameArgs *> "$PSScriptR ...
+         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=176.06 seed=81073
S7SETTINGS migration_v1_v5=true progress_preserved=true roundtrip=true sanitize=true temporary_save=true
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792415280
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792415280
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792415280
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792415280
Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в user://test_save.json.campaign-bad-3806020
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
METATEST trait sticky (Улей): кассета из 3, прилипание → взрыв через 0.58 с (едет с носителем), носитель потерял 27 HP
METATEST trait hicap (Страж): магазин 17, 4.2 выстр/с, урон 8; перезарядка после 17 выстрелов
METATEST trait fan (Ковбой): 6 выстрелов за 0.43 с по 5 разным целям, барабан пуст → перезарядка
METATEST trait steady (Оса): магазин 50, за 4 с 44 выстрелов, разброс +0.0° (ППШ за 1 с +21.0°)
METATEST trait lever (Винчестер): интервал 0.63 с, после убийства следующий выстрел через 0.23 с; урон 28.8 (Мосинка 48), темп 1.6/с
METATEST checks=257 failed=0
METATEST ok=true
EXIT=0
```

## cp1_campaign_final.log

Команда: `C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --campaign-test --cp1-paths`

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.
At C:\Users\Dev\Desktop\zera-cp1\design\tasks\reports\cp1_run.ps1:15 char:9
+         & $engine --headless --path $root -- @GameArgs *> "$PSScriptR ...
+         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
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
CAMPAIGNTEST cp1_restore_current_profile_after_legacy_fixture=true
CAMPAIGNTEST report_full_changes_causes_priority=true
CAMPAIGNTEST integration3_results_reopen=true
CAMPAIGNTEST integration2_defeat_once=true
CAMPAIGNTEST integration3_legacy_result_gets_run_id_once=true
CAMPAIGNTEST idempotent_older_run_report=true
CAMPAIGNTEST integration5_v1_v2_profile_preserved=true
CAMPAIGNTEST integration5_file_migration_not_corrupt=true
Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в res://design/tasks/reports/cp1_userdata/fixtures/c1_migration.json.campaign-bad-4265068
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
WARNING: Meta: запись res://design/tasks/reports/cp1_userdata/fixtures/c1_missing_directory/save.json не удалась
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] save (res://scripts/meta.gd:446)
       [1] start_operation (res://scripts/campaign/campaign.gd:57)
       [2] _integration (res://scripts/campaign/campaign_test.gd:277)
       [3] run (res://scripts/campaign/campaign_test.gd:24)
       [4] _ready (res://scripts/game.gd:681)
CAMPAIGNTEST failed_start_no_scene_config=true
CAMPAIGNTEST new_campaign_keeps_profile=true
CAMPAIGNTEST cp1_no_first_turn_final=true
CAMPAIGNTEST cp1_forecast_clearance_victory=true
CAMPAIGNTEST cp1_forecast_clearance_defeat=true
CAMPAIGNTEST cp1_forecast_extract_victory=true
CAMPAIGNTEST cp1_forecast_extract_defeat=true
CAMPAIGNTEST cp1_forecast_clearance_victory=true
CAMPAIGNTEST cp1_forecast_clearance_defeat=true
CAMPAIGNTEST cp1_preview_no_mutation=true
CAMPAIGNTEST cp1_front_cancel_or_land=true
CAMPAIGNTEST cp1_front_advances_only_at_deadline=true
CAMPAIGNTEST cp1_outpost_unique_persistent=true
CAMPAIGNTEST cp1_samples_unique=true
CAMPAIGNTEST cp1_outpost_lost_at_80=true
CAMPAIGNTEST cp1_final_unlock_six_operations=true
CAMPAIGNTEST cp1_final_can_delay_to_defend_front=true
CAMPAIGNTEST cp1_final_stops_front=true
CAMPAIGNTEST cp1_v4_all_profile_fields_pending_offers_preserved=true
CAMPAIGNTEST cp1_corrupt_progress_rejected=true
CAMPAIGNTEST cp1_corrupt_front_rejected=true
CAMPAIGNTEST cp1_actual_c6_v4_fixture_preserved=true
CAMPAIGNTEST cp1_v4_disk_rewritten_v5_no_profile_loss=true
CAMPAIGNTEST cp1_recovery_zero_one_two_keys_lost=true
CP1SIM campaigns=1400 limit=60; model outcomes, not combat; capped=unfinished
strategy | win | defeat | capped | median_turn | p90_turn | mean_final_infection | boss_turn
perfect | 200 | 0 | 0 | 7 | 7 | 16.48 | 7.00 (200)
CAMPAIGNTEST cp1_perfect_player_can_win_all=true
tactical | 200 | 0 | 0 | 7 | 9 | 20.49 | 7.77 (200)
learning | 198 | 1 | 1 | 9 | 14 | 24.83 | 9.70 (199)
random | 187 | 11 | 2 | 13 | 27 | 28.90 | 13.85 (191)
reward | 192 | 6 | 2 | 12 | 28 | 26.36 | 12.54 (194)
safe | 0 | 200 | 0 | 15 | 18 | 57.16 | 0.00 (0)
frequent_defeat | 16 | 177 | 7 | 17 | 39 | 67.50 | 19.41 (37)
CAMPAIGNTEST cp1_failures_have_a_price=true
CAMPAIGNTEST cp1_1400_campaigns_valid_no_deadlocks=true
CAMPAIGNTEST checks=81 failures=0
CAMPAIGNTEST ok=true
EXIT=0
```

## cp1_q1_final.log

Команда: `C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --q1-test --fresh-save --cp1-paths`

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.
At C:\Users\Dev\Desktop\zera-cp1\design\tasks\reports\cp1_run.ps1:15 char:9
+         & $engine --headless --path $root -- @GameArgs *> "$PSScriptR ...
+         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=179.83 seed=81073
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

## cp1_gore_final.log

Команда: `C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --fresh-save --gore-checks --cp1-paths`

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.
At C:\Users\Dev\Desktop\zera-cp1\design\tasks\reports\cp1_run.ps1:15 char:9
+         & $engine --headless --path $root -- @GameArgs *> "$PSScriptR ...
+         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=214.45 seed=81073
R1CHECK pellets_one_reaction_full_damage=true
R1CHECK exit_spray=true
R1CHECK crawler_inertia=true
R1CHECK bounded_flood_2400_deaths=true
R1CHECK no_permanent_body_or_ash_stamps=true
R1CHECK all_remains_expire=true
R1CHECK ok=true remains_peak=200 stamps_queue=420 particles=0
EXIT=0
```

## cp1_obstacles_final.log

Команда: `C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --obstacles-test --fresh-save --cp1-paths`

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.
At C:\Users\Dev\Desktop\zera-cp1\design\tasks\reports\cp1_run.ps1:15 char:9
+         & $engine --headless --path $root -- @GameArgs *> "$PSScriptR ...
+         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=239.96 seed=81073
OBSTEST layout cars=27 barrels=20 objects=409 seed=81073
OBSTEST simulation seconds=10 alive=500 penetrations=0
OBSTEST simulation seconds=20 alive=500 penetrations=0
OBSTEST simulation seconds=30 alive=500 penetrations=0
OBSTEST simulation seconds=40 alive=500 penetrations=0
OBSTEST simulation seconds=50 alive=500 penetrations=0
OBSTEST simulation seconds=60 alive=500 penetrations=0
OBSTEST wall arrived=500/500 nav_worst_us=192
OBSTEST ok=true penetrations=0 arrived=500 detonations=3 blood_events=2
EXIT=0
```

## cp1_sim_final.log

Команда: `C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --sim=600 --fresh-save --cp1-paths`

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.
At C:\Users\Dev\Desktop\zera-cp1\design\tasks\reports\cp1_run.ps1:15 char:9
+         & $engine --headless --path $root -- @GameArgs *> "$PSScriptR ...
+         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=184.10 seed=81073
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
PICK lvl=2 { "type": "module", "id": 3, "rare": false } slot=0 of ["weapon", "module", "level"]
PICK lvl=3 { "type": "weapon", "id": 5, "rare": false } slot=-1 of ["passive", "weapon", "module"]
PICK lvl=4 { "type": "weapon", "id": 1, "rare": false } slot=-1 of ["weapon", "module", "weapon"]
SIM 01:00 level=4 kills=74 xp=60/74 credits=4/7 credits_left=4 zombies=13 kinds=13/0/0/0 elites=0 elites_spawned=0 crates=0 nades=1 dmg_taken=95 peak=45 fps=145 | АК-С L1 Стан1 [Дето1] | Бульдог L1 Стан1 [] | Мясник L1 Стан1 []
PICK lvl=5 { "type": "module", "id": 2, "rare": false } slot=1 of ["level", "weapon", "module"]
PICK lvl=6 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "weapon", "level"]
SIM 02:00 level=6 kills=207 xp=174/207 credits=11/14 credits_left=11 zombies=52 kinds=52/0/0/0 elites=0 elites_spawned=0 crates=0 nades=5 dmg_taken=155 peak=92 fps=145 | АК-С L1 Стан1 [Дето1] | Бульдог L2 Стан1 [Спли1] | Мясник L1 Стан1 []
PICK lvl=7 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["weapon", "module", "level"]
PICK lvl=8 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "passive", "weapon"]
PICK lvl=9 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "level", "passive"]
SIM 03:00 level=9 kills=474 xp=408/474 credits=22/28 credits_left=22 zombies=24 kinds=24/0/0/0 elites=0 elites_spawned=0 crates=0 nades=9 dmg_taken=178 peak=85 fps=145 | АК-С L3 Стан1 [Дето1] | Бульдог L2 Стан1 [Спли1] | Мясник L1 Стан1 []
PICK lvl=10 { "type": "module", "id": 4, "rare": true } slot=0 of ["ammo", "module", "level"]
PICK lvl=11 { "type": "module", "id": 5, "rare": true } slot=2 of ["weapon", "module", "module"]
SIM 04:00 level=11 kills=734 xp=704/758 credits=46/57 credits_left=46 zombies=38 kinds=24/9/5/0 elites=0 elites_spawned=0 crates=0 nades=11 dmg_taken=298 peak=100 fps=145 | АК-С L3 Стан1 [Дето1,Сдво1] | Бульдог L2 Стан1 [Спли1] | Мясник L1 Стан1 [Цепь1]
PICK lvl=12 { "type": "module", "id": 5, "rare": false } slot=2 of ["module", "module", "weapon"]
PICK lvl=13 { "type": "weapon", "id": 4, "rare": false } slot=-1 of ["level", "level", "weapon"]
TRADER 0 at 05:00 credits_left=10 bought=["ammo(40)", "level(50)"]
SIM 05:00 level=13 kills=1087 xp=1036/1210 credits=100/110 credits_left=10 zombies=52 kinds=42/0/10/0 elites=0 elites_spawned=0 crates=0 nades=14 dmg_taken=298 peak=127 fps=145 | АК-С L4 Зажи1 [Дето1,Сдво1] | Бульдог L2 Стан1 [Спли1] | Мясник L1 Стан1 [Цепь2] | Кольт L1 Стан1 []
PICK lvl=14 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "level", "module"]
PICK lvl=15 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "passive", "level"]
PICK lvl=16 { "type": "module", "id": 4, "rare": false } slot=0 of ["module", "level", "passive"]
SIM 06:00 level=16 kills=1509 xp=1521/1853 credits=161/197 credits_left=71 zombies=52 kinds=22/8/18/4 elites=0 elites_spawned=2 crates=1 nades=15 dmg_taken=393 peak=131 fps=145 | АК-С L4 Зажи1 [Дето1,Сдво2] | Бульдог L4 Стан1 [Спли1] | Мясник L1 Стан1 [Цепь2] | Кольт L1 Стан1 []
PICK lvl=17 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["module", "level", "level"]
PICK lvl=18 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["level", "passive", "passive"]
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=0 rare=true
PICK lvl=19 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["module", "level", "module"]
SIM 07:00 level=19 kills=1997 xp=2156/2593 credits=244/294 credits_left=154 zombies=43 kinds=32/0/6/5 elites=0 elites_spawned=4 crates=1 nades=18 dmg_taken=569 peak=80 fps=145 | АК-С L5 Зажи1 [Дето1,Сдво2,Рико1] | Бульдог L5 Стан1 [Спли1] | Мясник L1 Стан1 [Цепь2] | Кольт L1 Стан1 []
ALARM_EVENT warn time=07:00
ALARM_EVENT start time=07:03
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=1 rare=true
PICK lvl=20 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["level", "ammo", "passive"]
PICK lvl=21 { "type": "module", "id": 0, "rare": false } slot=0 of ["level", "module", "passive"]
PICK lvl=22 { "type": "module", "id": 4, "rare": false } slot=0 of ["module", "level", "module"]
PICK lvl=23 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "module", "passive"]
PICK lvl=24 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["level", "level", "ammo"]
ALARM_EVENT finish container=(2178.481, 621.6967) time=07:33
CONTAINER dropped pos=(2178.481, 621.6967) time=07:33
ALARM rewards mult=2 xp=1962 credits=322
LOOT СБРОС СНАБЖЕНИЯ: module slot=1 rare=true
CONTAINER picked time=07:34 crates=2
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
PICK lvl=25 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["level", "level", "ammo"]
PICK lvl=26 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["module", "level", "ammo"]
SIM 08:00 level=26 kills=2971 xp=4796/5082 credits=642/689 credits_left=552 zombies=62 kinds=46/0/9/7 elites=0 elites_spawned=10 crates=2 nades=21 dmg_taken=804 peak=122 fps=145 | АК-С L5 Эксп1 [Дето1,Сдво3,Рико2] | Бульдог L5 Стан1 [Спли1,Цепь1,Проб1] | Мясник L3 Стан1 [Цепь2] | Кольт L1 Стан1 []
PICK lvl=27 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "level", "passive"]
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
PICK lvl=28 { "type": "module", "id": 3, "rare": false } slot=0 of ["passive", "module", "level"]
CALM 09:00 removed=1 left=11
TRADER 1 at 09:00 credits_left=335 bought=["module(60)", "level(75)", "level(75)", "module(60)", "passive(60)"]
SIM 09:00 level=28 kills=3683 xp=5617/6134 credits=755/824 credits_left=335 zombies=12 kinds=6/0/5/1 elites=0 elites_spawned=12 crates=3 nades=24 dmg_taken=1071 peak=73 fps=145 | АК-С L5 Стан1 [Дето2,Сдво3,Рико2] | Бульдог L5 Стан1 [Спли2,Цепь1,Проб2] | Мясник L4 Стан1 [Цепь2] | Кольт L2 Стан1 []
PICK lvl=29 { "type": "module", "id": 4, "rare": false } slot=2 of ["ammo", "module", "level"]
BOSS spawn t=600.00 pos=(2414.854, 766.6056) hp=24000
SIM 10:00 level=29 kills=3894 xp=6164/6406 credits=824/857 credits_left=404 zombies=13 kinds=13/0/0/0 elites=0 elites_spawned=14 crates=3 nades=24 dmg_taken=1071 peak=29 fps=145 | АК-С L5 Стан1 [Дето2,Сдво3,Рико2] | Бульдог L5 Стан1 [Спли2,Цепь1,Проб2] | Мясник L4 Стан1 [Цепь2,Сдво1] | Кольт L2 Стан1 []
SIM summary kills=3894 peak=131 level=29 damage=1070.90 boss_alive=true
EXIT=0
```

## cp1_globe_final.log

Команда: `WINDOW --globe-test`

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 16:12:42
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

bash.exe : ERROR: Failed to read the root certificate store.
At C:\Users\Dev\Desktop\zera-cp1\design\tasks\reports\cp1_run.ps1:11 char:9
+         & 'C:/Program Files/Git/bin/bash.exe' C:/Users/Dev/Desktop/ze ...
+         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
GLOBETEST isolated_before_ready=true
GLOBETEST viewport_active=true
GLOBETEST eight_zones_three_offers=true
GLOBETEST briefing_art_catalog_complete=true
GLOBETEST land_mask_all_eight_centers_and_ocean=true
GLOBETEST spread_routes_present=true
GLOBETEST quiet_regions_have_no_permanent_labels=true
GLOBETEST focus_zooms_to_operation=true
GLOBETEST idle_rotation=true
GLOBETEST reduced_motion_stops_idle_rotation=true
GLOBETEST keyboard_filter_cycle=true
GLOBETEST keyboard_journal=true
GLOBETEST label_projection_cases=2592 leader_crossings=14
GLOBETEST labels_no_overlap_or_clipping=true
GLOBETEST selected_and_operation_labels_visible=true
GLOBETEST briefing_third_offer=true
GLOBETEST mouse_drag_no_launch=true
GLOBETEST mouse_zoom=true
GLOBETEST horizon_culls_back=true
GLOBETEST back_autoturn=true
GLOBETEST dpad_all_eight_regions=true
GLOBETEST pad_all_offers_same_region=true
GLOBETEST filter_0=true
GLOBETEST filter_1=true
GLOBETEST filter_2=true
GLOBETEST filter_selection_2=true
GLOBETEST filter_3=true
GLOBETEST pad_a_selects=true
GLOBETEST region_journal=true
GLOBETEST motion_setting_sanitized=true
GLOBETEST settings_ui_motion_toggle=true
GLOBETEST motion_setting_disk_roundtrip=true
GLOBETEST reduced_motion_instant_focus=true
GLOBETEST reduced_motion_no_flash=true
GLOBETEST hidden_viewport_disabled=true
GLOBETEST viewing_does_not_advance=true
GLOBETEST mouse_offer_select=true
GLOBETEST mouse_marker_select=true
GLOBETEST pending_before_scene=true
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=414.47 seed=1076249530
MISSION threat=5 modifiers=["runner_surge", "elite_hunt"] seed=1076249530 profile={ "extract": false, "rate_mul": 1.456, "runner_add": 37.0, "spitter_add": 4.0, "acid": false, "elite_period": 22.0, "directional": 0.4, "hunt": true, "extra_alarm": false, "acid_life_mul": 1.0, "boss_hp_mul": 1.0, "boss_shed": 0.5 } commit=true persist=false
C6OBJECTIVE type=clearance target=(1760.0, 736.0) exit=(320.0, 544.0) reachable=true
GLOBETEST battle_config_and_globe_unloaded=true
GLOBETEST dispatcher_variants_fit_one_line=true
GLOBETEST results_committed_once=true
GLOBETEST results_events_max_three=true
GLOBETEST save_warning_survives_reopen=true
GLOBETEST results_reopen_idempotent=true
GLOBETEST save_retry_clears_warning=true
GLOBETEST reward_factors_separate=true
GLOBETEST reward_factors_exact=true
GLOBETEST defeat_no_operation_bonus=true
GLOBETEST free_victory_factor=true
GLOBETEST map_return_highlights=true
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=276.98 seed=81073
GLOBETEST free_run_no_pending=true
GLOBETEST free_result_no_world_change=true
GLOBETEST checks=52 failed=0
GLOBETEST ok=true temporary_save=true
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
EXIT=0
```

## cp1_capture_final.log

Команда: `WINDOW --cp1-capture`

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 16:09:49
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

bash.exe : ERROR: Failed to read the root certificate store.
At C:\Users\Dev\Desktop\zera-cp1\design\tasks\reports\cp1_run.ps1:11 char:9
+         & 'C:/Program Files/Git/bin/bash.exe' C:/Users/Dev/Desktop/ze ...
+         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
CP1TURN 1 choice=siberia:clearance average=37.88->35.13 outposts=1 samples=0 unlocked=false lost=0 phase=active
CP1TURN 2 choice=east_asia:clearance average=35.13->32.25 outposts=2 samples=0 unlocked=false lost=0 phase=active
CP1SHOT res://design/tasks/reports/cp1_globe_after.png
CP1TURN 3 choice=east_europe:clearance average=32.25->28.13 outposts=3 samples=0 unlocked=false lost=0 phase=active
CP1TURN 4 choice=south_asia:extract average=28.13->27.25 outposts=3 samples=1 unlocked=false lost=0 phase=active
CP1SHOT res://design/tasks/reports/cp1_briefing.png
CP1SHOT res://design/tasks/reports/cp1_forecast.png
CP1SHOT res://design/tasks/reports/cp1_outposts.png
CP1SHOT res://design/tasks/reports/cp1_samples.png
CP1SHOT res://design/tasks/reports/cp1_history.png
CP1SHOT res://design/tasks/reports/cp1_720p.png
CP1TURN 5 choice=east_europe:extract average=27.25->26.50 outposts=3 samples=2 unlocked=false lost=0 phase=active
CP1TURN 6 choice=middle_east:clearance average=26.50->22.38 outposts=4 samples=2 unlocked=true lost=0 phase=active
CP1SHOT res://design/tasks/reports/cp1_assault.png
CP1TURN 7 choice=east_europe:nest average=22.38->16.38 outposts=4 samples=2 unlocked=true lost=0 phase=victory
CP1SHOT res://design/tasks/reports/cp1_victory.png
CP1SHOT res://design/tasks/reports/cp1_front.png
CP1SHOT res://design/tasks/reports/cp1_risk.png
CP1SHOT res://design/tasks/reports/cp1_defeat.png
CP1CAPTURE complete=true viewport=true profile_untouched=true
EXIT=0
```

## Scope, PNG и очистка

Проверены разрешённые пути, отсутствие diff EV1, git diff --check, восстановление default_bus_layout.tres, декодирование PNG и отсутствие процессов Godot.

```text
CP1SCOPE unauthorized=[] forbidden_diff=[] diff_check=0 default_bus_clean=True
CP1PNG cp1_720p.png 1280x720 decoded=true
CP1PNG cp1_arc.png 1440x960 decoded=true
CP1PNG cp1_assault.png 1920x1080 decoded=true
CP1PNG cp1_briefing.png 1920x1080 decoded=true
CP1PNG cp1_briefing_before.png 1920x1080 decoded=true
CP1PNG cp1_defeat.png 1920x1080 decoded=true
CP1PNG cp1_forecast.png 1920x1080 decoded=true
CP1PNG cp1_front.png 1920x1080 decoded=true
CP1PNG cp1_globe_after.png 1920x1080 decoded=true
CP1PNG cp1_globe_before.png 1920x1080 decoded=true
CP1PNG cp1_history.png 1920x1080 decoded=true
CP1PNG cp1_outposts.png 1920x1080 decoded=true
CP1PNG cp1_risk.png 1920x1080 decoded=true
CP1PNG cp1_samples.png 1920x1080 decoded=true
CP1PNG cp1_victory.png 1920x1080 decoded=true
CP1CLEAN cp1_run.py_exists=False cp1_run.ps1_exists=False userdata_remains=True
CP1PROCESSES godot_count=0
CP1ART existing_assets=true new_raster_game_art=false
EXIT=0
```
