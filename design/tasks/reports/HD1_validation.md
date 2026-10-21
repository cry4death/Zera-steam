# HD1 — дословный вывод проверок

Команды из строк COMMAND и полный объединённый stdout/stderr. EXIT_CODE добавлен runner после завершения процесса. Настоящий APPDATA перенаправлялся только в дочернем процессе.

## hd1_import_delivery.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_import_delivery_engine.log --headless --path C:\Users\Dev\Desktop\zera-hd1 --import
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
[   0% ] [90m[1mupdate_scripts_classes[22m | [39m[0m
[  25% ] [90m[1mupdate_scripts_classes[22m | Horde[39m[0m
[  50% ] [90m[1mupdate_scripts_classes[22m | HordeDirector[39m[0m
[92m[ DONE ][39m [1mupdate_scripts_classes[22m
[0m
[   0% ] [90m[1mloading_editor_layout[22m | Started Загрузка редактора (5 steps)[39m[0m
[   0% ] [90m[1mloading_editor_layout[22m | Загрузка макета редактора…[39m[0m
[  16% ] [90m[1mloading_editor_layout[22m | Загрузка док-панели…[39m[0m
[92m[ DONE ][39m [1mloading_editor_layout[22m
[0m

EXIT_CODE=0
```

## hd1_director_result.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_director_result_engine.log --headless --path C:\Users\Dev\Desktop\zera-hd1 -- --director-test --fresh-save --layout-seed=81073
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=179.20 seed=81073
DIRECTORTEST form map=quarantine_checkpoint place=0 pattern=pincer lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=0 pattern=ring lanes=6 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=0 pattern=column lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=0 pattern=rush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=0 pattern=ambush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=0 pattern=tide lanes=5 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=0 pattern=flank lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=0 pattern=rest lanes=0 moved=0/0 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=1 pattern=pincer lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=1 pattern=ring lanes=7 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=1 pattern=column lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=1 pattern=rush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=1 pattern=ambush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=1 pattern=tide lanes=5 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=1 pattern=flank lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=1 pattern=rest lanes=0 moved=0/0 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=2 pattern=pincer lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=2 pattern=ring lanes=6 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=2 pattern=column lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=2 pattern=rush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=2 pattern=ambush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=2 pattern=tide lanes=5 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=2 pattern=flank lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=quarantine_checkpoint place=2 pattern=rest lanes=0 moved=0/0 penetrations=0
DIRECTORTEST form map=old_town place=0 pattern=pincer lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=0 pattern=ring lanes=6 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=0 pattern=column lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=0 pattern=rush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=0 pattern=ambush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=0 pattern=tide lanes=5 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=0 pattern=flank lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=0 pattern=rest lanes=0 moved=0/0 penetrations=0
DIRECTORTEST form map=old_town place=1 pattern=pincer lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=1 pattern=ring lanes=6 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=1 pattern=column lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=1 pattern=rush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=1 pattern=ambush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=1 pattern=tide lanes=5 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=1 pattern=flank lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=1 pattern=rest lanes=0 moved=0/0 penetrations=0
DIRECTORTEST form map=old_town place=2 pattern=pincer lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=2 pattern=ring lanes=7 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=2 pattern=column lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=2 pattern=rush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=2 pattern=ambush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=2 pattern=tide lanes=5 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=2 pattern=flank lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=old_town place=2 pattern=rest lanes=0 moved=0/0 penetrations=0
DIRECTORTEST form map=open_perimeter place=0 pattern=pincer lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=0 pattern=ring lanes=7 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=0 pattern=column lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=0 pattern=rush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=0 pattern=ambush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=0 pattern=tide lanes=5 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=0 pattern=flank lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=0 pattern=rest lanes=0 moved=0/0 penetrations=0
DIRECTORTEST form map=open_perimeter place=1 pattern=pincer lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=1 pattern=ring lanes=7 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=1 pattern=column lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=1 pattern=rush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=1 pattern=ambush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=1 pattern=tide lanes=5 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=1 pattern=flank lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=1 pattern=rest lanes=0 moved=0/0 penetrations=0
DIRECTORTEST form map=open_perimeter place=2 pattern=pincer lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=2 pattern=ring lanes=7 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=2 pattern=column lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=2 pattern=rush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=2 pattern=ambush lanes=1 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=2 pattern=tide lanes=5 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=2 pattern=flank lanes=2 moved=60/60 penetrations=0
DIRECTORTEST form map=open_perimeter place=2 pattern=rest lanes=0 moved=0/0 penetrations=0
DIRECTORTEST cases=72 failures=0 penetrations=0 budget=3897.00 planned=3841.91 issued=3838 ratio=0.98586 seed=true cap=true one_fast_side=true ok=true

EXIT_CODE=0
```

## hd1_meta_acceptance.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_meta_acceptance_engine.log --headless --path C:\Users\Dev\Desktop\zera-hd1 -- --meta-test --hd1-paths
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=186.19 seed=81073
S7SETTINGS migration_v1_v5=true progress_preserved=true roundtrip=true sanitize=true temporary_save=true
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792422069
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792422069
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792422069
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792422069
Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в user://test_save.json.campaign-bad-4559411
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

EXIT_CODE=0
```

## hd1_campaign_acceptance.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_campaign_acceptance_engine.log --headless --path C:\Users\Dev\Desktop\zera-hd1 -- --campaign-test --hd1-paths
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
CAMPAIGNTEST cp1_restore_current_profile_after_legacy_fixture=true
CAMPAIGNTEST report_full_changes_causes_priority=true
CAMPAIGNTEST integration3_results_reopen=true
CAMPAIGNTEST integration2_defeat_once=true
CAMPAIGNTEST integration3_legacy_result_gets_run_id_once=true
CAMPAIGNTEST idempotent_older_run_report=true
CAMPAIGNTEST integration5_v1_v2_profile_preserved=true
CAMPAIGNTEST integration5_file_migration_not_corrupt=true
Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в res://design/tasks/reports/hd1_fixtures/c1_migration.json.campaign-bad-5250931
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
WARNING: Meta: запись res://design/tasks/reports/hd1_fixtures/c1_missing_directory/save.json не удалась
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] save (res://scripts/meta.gd:446)
       [1] start_operation (res://scripts/campaign/campaign.gd:57)
       [2] _integration (res://scripts/campaign/campaign_test.gd:277)
       [3] run (res://scripts/campaign/campaign_test.gd:24)
       [4] _ready (res://scripts/game.gd:695)
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

EXIT_CODE=0
```

## hd1_q1_acceptance.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_q1_acceptance_engine.log --headless --path C:\Users\Dev\Desktop\zera-hd1 -- --q1-test --fresh-save --hd1-paths
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=182.13 seed=81073
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

EXIT_CODE=0
```

## hd1_gore_acceptance.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_gore_acceptance_engine.log --headless --path C:\Users\Dev\Desktop\zera-hd1 -- --fresh-save --gore-checks --hd1-paths
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=186.69 seed=81073
R1CHECK pellets_one_reaction_full_damage=true
R1CHECK exit_spray=true
R1CHECK crawler_inertia=true
R1CHECK bounded_flood_2400_deaths=true
R1CHECK no_permanent_body_or_ash_stamps=true
R1CHECK all_remains_expire=true
R1CHECK ok=true remains_peak=200 stamps_queue=400 particles=0

EXIT_CODE=0
```

## hd1_obstacles_acceptance.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_obstacles_acceptance_engine.log --headless --path C:\Users\Dev\Desktop\zera-hd1 -- --obstacles-test --fresh-save --hd1-paths
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=243.87 seed=81073
OBSTEST layout cars=27 barrels=20 objects=409 seed=81073
OBSTEST simulation seconds=10 alive=500 penetrations=0
OBSTEST simulation seconds=20 alive=500 penetrations=0
OBSTEST simulation seconds=30 alive=500 penetrations=0
OBSTEST simulation seconds=40 alive=500 penetrations=0
OBSTEST simulation seconds=50 alive=500 penetrations=0
OBSTEST simulation seconds=60 alive=500 penetrations=0
OBSTEST wall arrived=500/500 nav_worst_us=277
OBSTEST ok=true penetrations=0 arrived=500 detonations=3 blood_events=2

EXIT_CODE=0
```

## hd1_activities_acceptance.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_activities_acceptance_engine.log --headless --path C:\Users\Dev\Desktop\zera-hd1 -- --activities-test --fresh-save --hd1-paths
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=177.52 seed=81073
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

EXIT_CODE=0
```

## hd1_bench_1_before.log

```text
COMMAND "C:/Program Files/Git/usr/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_bench_1_before_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-hd1 -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/hd1_bench_1_before.png
HD1GUARD before_godot=[]
GODOT_EXCLUSIVE other_godot_processes=0 at 16:44:37
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=758.46 seed=81073
BENCH frames=434 avg_fps=43.1 avg_frame_ms=23.20 worst_frame_ms=139.81 horde_ms=4.37 enemies=499 kills=1119
BENCH process_ms=9.46 physics_ms=17.10 draw_calls=589 objects=4159 gore=587 particles=803 wet=105
BENCH physics_avg_ms=21.38 hud_ms=0.591
BENCH screenshot: res://design/tasks/reports/hd1_bench_1_before.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

HD1GUARD foreign_during=[]
EXIT_CODE=0
```

## hd1_bench_2_before.log

```text
COMMAND "C:/Program Files/Git/usr/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_bench_2_before_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-hd1 -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/hd1_bench_2_before.png
HD1GUARD before_godot=[]
GODOT_EXCLUSIVE other_godot_processes=0 at 16:45:10
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=745.15 seed=81073
BENCH frames=347 avg_fps=34.6 avg_frame_ms=28.93 worst_frame_ms=139.54 horde_ms=4.74 enemies=498 kills=1061
BENCH process_ms=9.65 physics_ms=15.30 draw_calls=533 objects=4033 gore=141 particles=555 wet=28
BENCH physics_avg_ms=22.19 hud_ms=0.737
BENCH screenshot: res://design/tasks/reports/hd1_bench_2_before.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

HD1GUARD foreign_during=[]
EXIT_CODE=0
```

## hd1_bench_3_before.log

```text
COMMAND "C:/Program Files/Git/usr/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_bench_3_before_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-hd1 -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/hd1_bench_3_before.png
HD1GUARD before_godot=[]
GODOT_EXCLUSIVE other_godot_processes=0 at 16:45:38
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=473.25 seed=81073
BENCH frames=438 avg_fps=43.5 avg_frame_ms=22.97 worst_frame_ms=144.02 horde_ms=4.49 enemies=499 kills=888
BENCH process_ms=9.43 physics_ms=23.89 draw_calls=827 objects=4064 gore=900 particles=1561 wet=90
BENCH physics_avg_ms=19.40 hud_ms=0.632
BENCH screenshot: res://design/tasks/reports/hd1_bench_3_before.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

HD1GUARD foreign_during=[]
EXIT_CODE=0
```

## hd1_bench_1_after.log

```text
COMMAND "C:/Program Files/Git/usr/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_bench_1_after_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-hd1 -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/hd1_bench_1_after.png
GODOT_EXCLUSIVE other_godot_processes=0 at 17:55:13
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=479.44 seed=81073
BENCH frames=705 avg_fps=70.1 avg_frame_ms=14.26 worst_frame_ms=116.59 horde_ms=3.69 enemies=498 kills=1100
BENCH process_ms=6.30 physics_ms=15.53 draw_calls=578 objects=4070 gore=339 particles=1004 wet=42
BENCH physics_avg_ms=19.91 hud_ms=0.463
BENCH screenshot: res://design/tasks/reports/hd1_bench_1_after.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0
```

## hd1_bench_2_after.log

```text
COMMAND "C:/Program Files/Git/usr/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_bench_2_after_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-hd1 -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/hd1_bench_2_after.png
GODOT_EXCLUSIVE other_godot_processes=0 at 17:55:40
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=256.24 seed=81073
BENCH frames=1585 avg_fps=158.4 avg_frame_ms=6.31 worst_frame_ms=32.76 horde_ms=2.38 enemies=498 kills=1038
BENCH process_ms=7.62 physics_ms=13.04 draw_calls=645 objects=4203 gore=744 particles=1272 wet=128
BENCH physics_avg_ms=13.21 hud_ms=0.216
BENCH screenshot: res://design/tasks/reports/hd1_bench_2_after.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0
```

## hd1_bench_3_after.log

```text
COMMAND "C:/Program Files/Git/usr/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_bench_3_after_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-hd1 -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/hd1_bench_3_after.png
GODOT_EXCLUSIVE other_godot_processes=0 at 17:56:01
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=247.17 seed=81073
BENCH frames=1387 avg_fps=138.6 avg_frame_ms=7.22 worst_frame_ms=39.95 horde_ms=2.36 enemies=499 kills=967
BENCH process_ms=6.70 physics_ms=10.18 draw_calls=573 objects=4224 gore=288 particles=594 wet=76
BENCH physics_avg_ms=11.94 hud_ms=0.233
BENCH screenshot: res://design/tasks/reports/hd1_bench_3_after.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0
```

## hd1_fixed_starter_control.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_fixed_starter_control_engine.log --headless --fixed-fps 60 --path C:\Users\Dev\Desktop\zera-hd1 -- --sim=600 --fresh-save --layout-seed=81073 --director-trace=fixed_starter --director-off
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=181.43 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
PICK lvl=2 { "type": "weapon", "id": 1, "rare": false } slot=-1 of ["weapon", "module", "passive"]
PICK lvl=3 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "level", "module"]
ACTIVITY event=start kind=carrier time=57.47 age=0.00 pos=(1602.343, 414.4794) offered=1 success=0 failed=0 rewards=0
SIM 01:00 level=3 kills=49 xp=45/49 credits=5/5 credits_left=5 zombies=36 kinds=35/1/0/0 elites=0 elites_spawned=0 crates=0 nades=2 dmg_taken=0 peak=43 fps=100 | АК-С L1 Стан1 [] | Мясник L1 Стан1 []
ACTIVITY event=success kind=carrier time=63.13 age=5.67 pos=(1672.756, 275.5013) offered=1 success=1 failed=0 rewards=1
PICK lvl=4 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["weapon", "level", "level"]
PICK lvl=5 { "type": "module", "id": 0, "rare": false } slot=0 of ["module", "level", "module"]
PICK lvl=6 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["weapon", "module", "passive"]
PICK lvl=7 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["weapon", "level", "module"]
SIM 02:00 level=7 kills=244 xp=240/279 credits=20/23 credits_left=20 zombies=25 kinds=25/0/0/0 elites=0 elites_spawned=0 crates=0 nades=8 dmg_taken=67 peak=90 fps=588 | АК-С L3 Стан1 [Рико1] | Мясник L1 Стан1 []
PICK lvl=8 { "type": "weapon", "id": 3, "rare": false } slot=-1 of ["level", "weapon", "weapon"]
PICK lvl=9 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["ammo", "ammo", "level"]
ACTIVITY event=start kind=supply time=152.87 age=0.00 pos=(2200.0, 440.0) offered=2 success=1 failed=0 rewards=1
ACTIVITY event=success kind=supply time=174.20 age=21.33 pos=(2200.0, 440.0) offered=2 success=2 failed=0 rewards=2
LOOT СНАБЖЕНИЕ: module slot=0 rare=false
SIM 03:00 level=9 kills=507 xp=419/542 credits=30/43 credits_left=30 zombies=19 kinds=19/0/0/0 elites=0 elites_spawned=0 crates=0 nades=11 dmg_taken=67 peak=49 fps=547 | АК-С L3 Стан1 [Рико1,Дето1] | Мясник L2 Стан1 [] | Гром L1 Стан1 []
PICK lvl=10 { "type": "module", "id": 1, "rare": false } slot=1 of ["weapon", "passive", "module"]
PICK lvl=11 { "type": "module", "id": 4, "rare": false } slot=2 of ["level", "ammo", "module"]
SIM 04:00 level=11 kills=648 xp=669/683 credits=51/54 credits_left=51 zombies=149 kinds=122/12/15/0 elites=0 elites_spawned=0 crates=0 nades=12 dmg_taken=67 peak=149 fps=583 | АК-С L3 Стан1 [Рико1,Дето1] | Мясник L2 Стан1 [Проб1] | Гром L1 Стан1 [Сдво1]
PICK lvl=12 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["ammo", "ammo", "module"]
PICK lvl=13 { "type": "module", "id": 3, "rare": false } slot=0 of ["module", "weapon", "weapon"]
PICK lvl=14 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["passive", "level", "level"]
TRADER 0 at 05:00 credits_left=8 bought=["level(50)", "level(50)"]
SIM 05:00 level=14 kills=1122 xp=1213/1295 credits=108/115 credits_left=8 zombies=26 kinds=11/10/5/0 elites=0 elites_spawned=0 crates=0 nades=17 dmg_taken=424 peak=161 fps=399 | АК-С L4 Эксп1 [Рико1,Дето2] | Мясник L3 Стан1 [Проб1] | Гром L1 Стан1 [Сдво1]
PICK lvl=15 { "type": "weapon", "id": 7, "rare": false } slot=-1 of ["weapon", "module", "passive"]
PICK lvl=16 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "ammo", "module"]
ACTIVITY event=start kind=fuel time=328.07 age=0.00 pos=(1768.0, 440.0) offered=3 success=2 failed=0 rewards=2
ACTIVITY event=success kind=fuel time=341.00 age=12.93 pos=(1768.0, 440.0) offered=3 success=3 failed=0 rewards=3
PICK lvl=17 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "module", "ammo"]
SIM 06:00 level=17 kills=1540 xp=1660/1929 credits=157/212 credits_left=57 zombies=50 kinds=31/0/13/6 elites=0 elites_spawned=2 crates=0 nades=20 dmg_taken=507 peak=58 fps=389 | АК-С L5 Эксп1 [Рико1,Дето2] | Мясник L3 Стан1 [Проб1] | Гром L1 Стан1 [Сдво1] | Мосинка L2 Стан1 []
PICK lvl=18 { "type": "module", "id": 4, "rare": false } slot=0 of ["ammo", "module", "module"]
PICK lvl=19 { "type": "module", "id": 2, "rare": false } slot=1 of ["module", "level", "ammo"]
PICK lvl=20 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["passive", "module", "passive"]
SIM 07:00 level=20 kills=2065 xp=2467/2685 credits=267/309 credits_left=167 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=4 crates=0 nades=23 dmg_taken=620 peak=57 fps=332 | АК-С L5 Эксп1 [Рико1,Дето2,Сдво1] | Мясник L3 Стан1 [Проб1,Спли1] | Гром L1 Стан1 [Сдво1] | Мосинка L2 Стан1 []
ALARM_EVENT warn time=07:00
ALARM_EVENT start time=07:03
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=3 rare=true
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=1 rare=true
PICK lvl=21 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["module", "module", "level"]
PICK lvl=22 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["level", "level", "module"]
PICK lvl=23 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["passive", "level", "module"]
ALARM_EVENT finish container=(2144.632, 531.5671) time=07:33
CONTAINER dropped pos=(2144.632, 531.5671) time=07:33
ALARM rewards mult=2 xp=2022 credits=276
PICK lvl=24 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "level", "level"]
LOOT СБРОС СНАБЖЕНИЯ: module slot=2 rare=false
CONTAINER picked time=07:34 crates=1
PICK lvl=25 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "level", "passive"]
PICK lvl=26 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["level", "ammo", "module"]
SIM 08:00 level=26 kills=3037 xp=4567/5120 credits=558/641 credits_left=458 zombies=21 kinds=14/0/2/5 elites=0 elites_spawned=10 crates=1 nades=26 dmg_taken=745 peak=143 fps=237 | АК-С L5 Крио1 [Рико1,Дето2,Сдво1] | Мясник L3 Стан1 [Проб2,Спли1] | Гром L3 Стан1 [Сдво1,Цепь1] | Мосинка L4 Стан1 [Цепь1]
PICK lvl=27 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["passive", "level", "ammo"]
PICK lvl=28 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "module", "level"]
PICK lvl=29 { "type": "module", "id": 2, "rare": true } slot=1 of ["module", "module", "passive"]
CALM 09:00 removed=34 left=0
TRADER 1 at 09:00 credits_left=159 bought=["passive(60)", "ammo(150)", "passive(60)", "ammo(150)", "module(60)"]
SIM 09:00 level=29 kills=3693 xp=5965/6120 credits=739/777 credits_left=159 zombies=34 kinds=24/0/3/7 elites=0 elites_spawned=12 crates=1 nades=29 dmg_taken=792 peak=67 fps=311 | АК-С L5 Зажи1 [Рико2,Дето2,Сдво1] | Мясник L3 Стан1 [Проб2,Спли2] | Гром L3 Стан1 [Сдво1,Цепь1] | Мосинка L4 Стан1 [Цепь1]
PICK lvl=30 { "type": "module", "id": 2, "rare": false } slot=1 of ["passive", "module", "module"]
BOSS spawn t=600.00 pos=(2408.178, 743.761) hp=24000
SIM 10:00 level=30 kills=3891 xp=6279/6366 credits=777/805 credits_left=197 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=14 crates=1 nades=31 dmg_taken=792 peak=29 fps=539 | АК-С L5 Зажи1 [Рико2,Дето2,Сдво1] | Мясник L3 Стан1 [Проб2,Спли3] | Гром L3 Стан1 [Сдво1,Цепь1] | Мосинка L4 Стан1 [Цепь1]
SIM summary kills=3891 peak=161 level=30 damage=792.06 boss_alive=true

EXIT_CODE=0
```

## hd1_fixed_starter_after.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_fixed_starter_after_engine.log --headless --fixed-fps 60 --path C:\Users\Dev\Desktop\zera-hd1 -- --sim=600 --fresh-save --layout-seed=81073 --director-trace=fixed_starter
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=178.45 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
DIRECTOR {"alive":0,"curve":0.0,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":0,"nearby":0,"pattern":"column","phase":"scout","planned":0.0,"time":0.0666666666666667}
DIRECTOR {"alive":4,"curve":7.49999999999999,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":4,"nearby":0,"pattern":"tide","phase":"scout","planned":7.49999999999999,"time":5.06666666666667}
DIRECTOR {"alive":13,"curve":15.1,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":13,"nearby":0,"pattern":"tide","phase":"build","planned":15.1,"time":10.1333333333333}
DIRECTOR {"alive":19,"curve":22.7000000000001,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":19,"nearby":0,"pattern":"tide","phase":"build","planned":22.7000000000001,"time":15.2}
DIRECTOR {"alive":29,"curve":30.3000000000002,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":29,"nearby":0,"pattern":"tide","phase":"build","planned":30.3000000000002,"time":20.2666666666666}
DIRECTOR {"alive":26,"curve":37.9000000000003,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":32,"nearby":0,"pattern":"tide","phase":"build","planned":37.9000000000003,"time":25.3333333333333}
PICK lvl=2 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["weapon", "module", "level"]
DIRECTOR {"alive":27,"curve":45.5000000000004,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":44,"nearby":0,"pattern":"tide","phase":"build","planned":45.5000000000004,"time":30.3999999999999}
DIRECTOR {"alive":33,"curve":53.0000000000005,"damage":0.0,"exclusive":false,"intensity":0.1,"issued":51,"nearby":0,"pattern":"tide","phase":"peak","planned":53.0000000000005,"time":35.4000000000001}
PICK lvl=3 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["module", "weapon", "level"]
DIRECTOR {"alive":32,"curve":60.5000000000006,"damage":0.0,"exclusive":false,"intensity":0.046875,"issued":56,"nearby":3,"pattern":"tide","phase":"peak","planned":60.5000000000006,"time":40.4000000000003}
DIRECTOR {"alive":34,"curve":68.0000000000004,"damage":0.0,"exclusive":false,"intensity":0.104166666666667,"issued":62,"nearby":0,"pattern":"tide","phase":"peak","planned":68.0000000000004,"time":45.4000000000006}
DIRECTOR {"alive":41,"curve":75.5,"damage":12.4056184040507,"exclusive":false,"intensity":0.386458333333333,"issued":72,"nearby":5,"pattern":"tide","phase":"peak","planned":75.5,"time":50.4000000000008}
DIRECTOR {"alive":37,"curve":82.9999999999996,"damage":18.9430566466053,"exclusive":false,"intensity":0.325,"issued":81,"nearby":0,"pattern":"tide","phase":"decay","planned":82.9999999999996,"time":55.4000000000011}
PICK lvl=4 { "type": "weapon", "id": 3, "rare": false } slot=-1 of ["weapon", "weapon", "level"]
ACTIVITY event=start kind=carrier time=57.47 age=0.00 pos=(1626.613, 463.3311) offered=1 success=0 failed=0 rewards=0
SIM 01:00 level=4 kills=51 xp=47/51 credits=1/1 credits_left=1 zombies=35 kinds=34/1/0/0 elites=0 elites_spawned=0 crates=0 nades=2 dmg_taken=19 peak=44 fps=862 | АК-С L3 Стан1 [] | Гром L1 Стан1 []
DIRECTOR {"alive":39,"curve":91.0999999999992,"damage":18.9430566466053,"exclusive":true,"intensity":0.0,"issued":89,"nearby":0,"pattern":"tide","phase":"decay","planned":91.0999999999992,"time":60.4000000000013}
ACTIVITY event=success kind=carrier time=61.73 age=4.27 pos=(1690.49, 411.0835) offered=1 success=1 failed=0 rewards=1
PICK lvl=5 { "type": "weapon", "id": 2, "rare": false } slot=-1 of ["level", "module", "weapon"]
DIRECTOR {"alive":44,"curve":106.099999999999,"damage":18.9430566466053,"exclusive":false,"intensity":0.0,"issued":95,"nearby":0,"pattern":"ambush","phase":"relax","planned":101.702722713864,"time":65.4000000000014}
DIRECTOR {"alive":34,"curve":121.3,"damage":18.9430566466053,"exclusive":false,"intensity":0.0,"issued":95,"nearby":0,"pattern":"ambush","phase":"relax","planned":105.573354825115,"time":70.4666666666678}
DIRECTOR {"alive":39,"curve":136.499999999999,"damage":18.9430566466053,"exclusive":false,"intensity":0.0,"issued":102,"nearby":0,"pattern":"ambush","phase":"relax","planned":109.422070375052,"time":75.5333333333342}
DIRECTOR {"alive":39,"curve":151.699999999998,"damage":18.9430566466053,"exclusive":false,"intensity":0.0,"issued":108,"nearby":0,"pattern":"column","phase":"scout","planned":114.37125115887,"time":80.6000000000005}
DIRECTOR {"alive":38,"curve":166.899999999998,"damage":18.9430566466053,"exclusive":false,"intensity":0.00833333333333333,"issued":115,"nearby":0,"pattern":"column","phase":"scout","planned":127.441856721449,"time":85.6666666666669}
DIRECTOR {"alive":32,"curve":182.099999999997,"damage":18.9430566466053,"exclusive":false,"intensity":0.0,"issued":129,"nearby":0,"pattern":"column","phase":"build","planned":141.403745048461,"time":90.7333333333333}
DIRECTOR {"alive":28,"curve":197.299999999996,"damage":18.9430566466053,"exclusive":false,"intensity":0.00833333333333333,"issued":147,"nearby":0,"pattern":"column","phase":"build","planned":160.599581963757,"time":95.7999999999997}
DIRECTOR {"alive":14,"curve":212.499999999995,"damage":18.9430566466053,"exclusive":false,"intensity":0.0208333333333333,"issued":166,"nearby":0,"pattern":"column","phase":"build","planned":179.791543615675,"time":100.866666666666}
DIRECTOR {"alive":25,"curve":227.699999999994,"damage":18.9430566466053,"exclusive":false,"intensity":0.0,"issued":190,"nearby":0,"pattern":"column","phase":"build","planned":198.990286978506,"time":105.933333333332}
DIRECTOR {"alive":27,"curve":242.899999999993,"damage":18.9430566466053,"exclusive":false,"intensity":0.0,"issued":211,"nearby":0,"pattern":"column","phase":"build","planned":218.191936788873,"time":110.999999999999}
DIRECTOR {"alive":21,"curve":258.099999999992,"damage":18.9430566466053,"exclusive":false,"intensity":0.0,"issued":231,"nearby":0,"pattern":"column","phase":"peak","planned":238.888407922459,"time":116.066666666665}
SIM 02:00 level=5 kills=216 xp=83/251 credits=1/19 credits_left=1 zombies=25 kinds=25/0/0/0 elites=0 elites_spawned=0 crates=0 nades=2 dmg_taken=19 peak=44 fps=665 | АК-С L3 Стан1 [] | Гром L1 Стан1 [] | Игла L1 Стан1 []
DIRECTOR {"alive":20,"curve":274.366666666658,"damage":18.9430566466053,"exclusive":false,"intensity":0.0,"issued":251,"nearby":0,"pattern":"column","phase":"peak","planned":263.526217024861,"time":121.133333333332}
DIRECTOR {"alive":23,"curve":294.633333333324,"damage":18.9430566466053,"exclusive":false,"intensity":0.00416666666666667,"issued":280,"nearby":0,"pattern":"column","phase":"peak","planned":294.220286697567,"time":126.199999999998}
DIRECTOR {"alive":46,"curve":314.899999999989,"damage":18.9430566466053,"exclusive":false,"intensity":0.0,"issued":314,"nearby":0,"pattern":"column","phase":"peak","planned":324.937107318441,"time":131.266666666664}
DIRECTOR {"alive":35,"curve":335.166666666655,"damage":18.9430566466053,"exclusive":false,"intensity":0.025,"issued":329,"nearby":0,"pattern":"column","phase":"decay","planned":343.621868099451,"time":136.333333333331}
PICK lvl=6 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["weapon", "ammo", "level"]
DIRECTOR {"alive":33,"curve":355.43333333332,"damage":18.9430566466053,"exclusive":false,"intensity":0.0197916666666667,"issued":350,"nearby":1,"pattern":"column","phase":"decay","planned":360.05000828768,"time":141.399999999997}
PICK lvl=7 { "type": "module", "id": 3, "rare": true } slot=0 of ["level", "weapon", "module"]
DIRECTOR {"alive":18,"curve":375.699999999986,"damage":18.9430566466053,"exclusive":false,"intensity":0.0208333333333333,"issued":359,"nearby":0,"pattern":"column","phase":"relax","planned":371.356264784379,"time":146.466666666663}
PICK lvl=8 { "type": "module", "id": 5, "rare": true } slot=0 of ["module", "weapon", "weapon"]
DIRECTOR {"alive":17,"curve":395.966666666651,"damage":18.9430566466053,"exclusive":false,"intensity":0.00416666666666667,"issued":359,"nearby":0,"pattern":"column","phase":"relax","planned":376.493364657955,"time":151.53333333333}
ACTIVITY event=start kind=supply time=152.87 age=0.00 pos=(1880.0, 264.0) offered=2 success=1 failed=0 rewards=1
DIRECTOR {"alive":30,"curve":416.233333333317,"damage":18.9430566466053,"exclusive":true,"intensity":0.0208333333333333,"issued":381,"nearby":0,"pattern":"column","phase":"relax","planned":392.57961328838,"time":156.599999999996}
PICK lvl=9 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["ammo", "level", "passive"]
DIRECTOR {"alive":40,"curve":436.499999999982,"damage":18.9430566466053,"exclusive":true,"intensity":0.0,"issued":400,"nearby":0,"pattern":"column","phase":"scout","planned":412.846279955045,"time":161.666666666663}
DIRECTOR {"alive":58,"curve":456.766666666648,"damage":18.9430566466053,"exclusive":true,"intensity":0.0166666666666667,"issued":422,"nearby":0,"pattern":"column","phase":"scout","planned":433.112946621711,"time":166.733333333329}
DIRECTOR {"alive":62,"curve":477.033333333313,"damage":18.9430566466053,"exclusive":true,"intensity":0.0416666666666667,"issued":444,"nearby":0,"pattern":"column","phase":"build","planned":453.379613288376,"time":171.799999999995}
ACTIVITY event=success kind=supply time=176.67 age=23.80 pos=(1880.0, 264.0) offered=2 success=2 failed=0 rewards=2
LOOT СНАБЖЕНИЕ: module slot=1 rare=true
DIRECTOR {"alive":44,"curve":497.299999999979,"damage":18.9430566466053,"exclusive":false,"intensity":0.00416666666666667,"issued":455,"nearby":0,"pattern":"rush","phase":"build","planned":473.786875684779,"time":176.866666666662}
SIM 03:00 level=9 kills=452 xp=367/487 credits=25/29 credits_left=25 zombies=22 kinds=21/1/0/0 elites=0 elites_spawned=0 crates=0 nades=3 dmg_taken=19 peak=73 fps=555 | АК-С L3 Эксп1 [Дето1,Цепь1] | Гром L1 Стан1 [Рико1] | Игла L2 Стан1 []
DIRECTOR {"alive":12,"curve":517.566666666644,"damage":18.9430566466053,"exclusive":false,"intensity":0.0125,"issued":455,"nearby":0,"pattern":"rush","phase":"build","planned":499.369053237807,"time":181.933333333328}
DIRECTOR {"alive":40,"curve":537.83333333331,"damage":18.9430566466053,"exclusive":false,"intensity":0.0,"issued":486,"nearby":0,"pattern":"rush","phase":"build","planned":524.982878775099,"time":186.999999999995}
DIRECTOR {"alive":31,"curve":558.099999999975,"damage":18.9430566466053,"exclusive":false,"intensity":0.0333333333333333,"issued":514,"nearby":0,"pattern":"rush","phase":"build","planned":550.557305801365,"time":192.066666666661}
DIRECTOR {"alive":12,"curve":578.366666666641,"damage":18.9430566466053,"exclusive":false,"intensity":0.00416666666666667,"issued":540,"nearby":0,"pattern":"rush","phase":"peak","planned":578.860345835077,"time":197.133333333327}
DIRECTOR {"alive":9,"curve":598.633333333306,"damage":18.9430566466053,"exclusive":false,"intensity":0.0364583333333333,"issued":565,"nearby":1,"pattern":"rush","phase":"peak","planned":609.541776092135,"time":202.199999999994}
PICK lvl=10 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["module", "module", "level"]
DIRECTOR {"alive":7,"curve":618.899999999972,"damage":18.9430566466053,"exclusive":false,"intensity":0.0291666666666667,"issued":602,"nearby":0,"pattern":"rush","phase":"peak","planned":640.172016715818,"time":207.26666666666}
DIRECTOR {"alive":20,"curve":641.433333333306,"damage":18.9430566466053,"exclusive":false,"intensity":0.00416666666666667,"issued":633,"nearby":0,"pattern":"rush","phase":"decay","planned":673.351339233026,"time":212.333333333326}
DIRECTOR {"alive":40,"curve":666.766666666642,"damage":18.9430566466053,"exclusive":false,"intensity":0.0,"issued":656,"nearby":0,"pattern":"rush","phase":"decay","planned":693.852099873568,"time":217.399999999993}
DIRECTOR {"alive":39,"curve":692.099999999978,"damage":18.9430566466053,"exclusive":false,"intensity":0.00416666666666667,"issued":671,"nearby":0,"pattern":"rush","phase":"decay","planned":714.366859671295,"time":222.466666666659}
DIRECTOR {"alive":35,"curve":717.433333333315,"damage":18.9430566466053,"exclusive":false,"intensity":0.0,"issued":686,"nearby":0,"pattern":"rush","phase":"relax","planned":725.296639134706,"time":227.533333333326}
PICK lvl=11 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["passive", "ammo", "ammo"]
DIRECTOR {"alive":26,"curve":742.766666666651,"damage":18.9430566466053,"exclusive":false,"intensity":0.0291666666666667,"issued":697,"nearby":0,"pattern":"rush","phase":"relax","planned":731.765956454558,"time":232.599999999992}
DIRECTOR {"alive":7,"curve":768.099999999987,"damage":18.9430566466053,"exclusive":false,"intensity":0.0239583333333333,"issued":697,"nearby":1,"pattern":"rush","phase":"relax","planned":738.271230632816,"time":237.666666666658}
SIM 04:00 level=11 kills=716 xp=636/775 credits=40/50 credits_left=40 zombies=9 kinds=7/0/2/0 elites=0 elites_spawned=0 crates=0 nades=4 dmg_taken=38 peak=55 fps=433 | АК-С L3 Крио1 [Дето1,Цепь1] | Гром L1 Стан1 [Рико1] | Игла L3 Стан1 []
DIRECTOR {"alive":24,"curve":796.099999999987,"damage":38.2724102648562,"exclusive":false,"intensity":0.3,"issued":723,"nearby":0,"pattern":"ambush","phase":"scout","planned":756.652310858268,"time":242.733333333325}
DIRECTOR {"alive":28,"curve":826.499999999986,"damage":38.2724102648562,"exclusive":false,"intensity":0.0,"issued":747,"nearby":0,"pattern":"ambush","phase":"scout","planned":783.02918064335,"time":247.799999999991}
DIRECTOR {"alive":30,"curve":856.899999999984,"damage":38.2724102648562,"exclusive":false,"intensity":0.05,"issued":779,"nearby":0,"pattern":"ambush","phase":"build","planned":815.940800533785,"time":252.866666666657}
DIRECTOR {"alive":54,"curve":887.299999999982,"damage":38.2724102648562,"exclusive":false,"intensity":0.0,"issued":814,"nearby":0,"pattern":"ambush","phase":"build","planned":854.321332982164,"time":257.933333333324}
PICK lvl=12 { "type": "module", "id": 0, "rare": false } slot=1 of ["level", "module", "level"]
DIRECTOR {"alive":94,"curve":917.69999999998,"damage":38.2724102648562,"exclusive":false,"intensity":0.0,"issued":856,"nearby":0,"pattern":"ambush","phase":"build","planned":892.749821814868,"time":262.99999999999}
DIRECTOR {"alive":116,"curve":948.099999999979,"damage":38.2724102648562,"exclusive":false,"intensity":0.0375,"issued":891,"nearby":0,"pattern":"ambush","phase":"build","planned":931.171528936658,"time":268.066666666657}
DIRECTOR {"alive":108,"curve":978.499999999977,"damage":38.2724102648562,"exclusive":false,"intensity":0.015625,"issued":932,"nearby":1,"pattern":"ambush","phase":"build","planned":969.519606054233,"time":273.133333333323}
DIRECTOR {"alive":60,"curve":1008.89999999998,"damage":38.2724102648562,"exclusive":false,"intensity":0.05,"issued":977,"nearby":0,"pattern":"ambush","phase":"peak","planned":1013.96091494593,"time":278.199999999989}
PICK lvl=13 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "level", "ammo"]
DIRECTOR {"alive":40,"curve":1039.29999999998,"damage":38.2724102648562,"exclusive":false,"intensity":0.00416666666666667,"issued":1026,"nearby":0,"pattern":"ambush","phase":"peak","planned":1059.88257697712,"time":283.266666666656}
DIRECTOR {"alive":12,"curve":1069.69999999998,"damage":38.2724102648562,"exclusive":true,"intensity":0.0197916666666667,"issued":1045,"nearby":1,"pattern":"ambush","phase":"peak","planned":1095.77779273776,"time":288.333333333322}
PICK lvl=14 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["level", "ammo", "passive"]
DIRECTOR {"alive":44,"curve":1100.09999999999,"damage":38.2724102648562,"exclusive":true,"intensity":0.00833333333333333,"issued":1081,"nearby":0,"pattern":"ambush","phase":"decay","planned":1126.17779273777,"time":293.399999999988}
DIRECTOR {"alive":27,"curve":1130.5,"damage":38.2724102648562,"exclusive":true,"intensity":0.05,"issued":1108,"nearby":0,"pattern":"ambush","phase":"decay","planned":1156.57779273777,"time":298.466666666655}
TRADER 0 at 05:00 credits_left=23 bought=["weapon(60)"]
SIM 05:00 level=14 kills=1105 xp=1111/1230 credits=83/93 credits_left=23 zombies=30 kinds=25/0/5/0 elites=0 elites_spawned=0 crates=0 nades=7 dmg_taken=38 peak=128 fps=251 | АК-С L3 Крио2 [Дето1,Цепь1] | Гром L2 Стан1 [Рико2] | Игла L3 Стан1 [] | ППШ L1 Стан1 []
DIRECTOR {"alive":17,"curve":1164.36666666667,"damage":38.2724102648562,"exclusive":true,"intensity":0.0125,"issued":1147,"nearby":0,"pattern":"ambush","phase":"decay","planned":1190.44445940444,"time":303.533333333321}
DIRECTOR {"alive":23,"curve":1199.83333333334,"damage":38.2724102648562,"exclusive":true,"intensity":0.0,"issued":1176,"nearby":0,"pattern":"ambush","phase":"relax","planned":1225.91112607111,"time":308.599999999988}
DIRECTOR {"alive":13,"curve":1235.30000000001,"damage":38.2724102648562,"exclusive":true,"intensity":0.0208333333333333,"issued":1219,"nearby":0,"pattern":"ambush","phase":"relax","planned":1261.37779273778,"time":313.666666666654}
PICK lvl=15 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["module", "passive", "ammo"]
DIRECTOR {"alive":0,"curve":1270.76666666668,"damage":38.2724102648562,"exclusive":false,"intensity":0.0,"issued":1219,"nearby":0,"pattern":"column","phase":"relax","planned":1277.70262607112,"time":318.73333333332}
DIRECTOR {"alive":20,"curve":1306.23333333334,"damage":38.2724102648562,"exclusive":false,"intensity":0.00416666666666667,"issued":1242,"nearby":0,"pattern":"ring","phase":"scout","planned":1302.53098595312,"time":323.799999999987}
PICK lvl=16 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "level", "level"]
ACTIVITY event=start kind=fuel time=328.07 age=0.00 pos=(1724.285, 479.3917) offered=3 success=2 failed=0 rewards=2
DIRECTOR {"alive":36,"curve":1341.70000000001,"damage":38.2724102648562,"exclusive":true,"intensity":0.0,"issued":1267,"nearby":0,"pattern":"ring","phase":"scout","planned":1333.74851913896,"time":328.866666666653}
DIRECTOR {"alive":60,"curve":1377.16666666668,"damage":38.2724102648562,"exclusive":true,"intensity":0.00416666666666667,"issued":1302,"nearby":0,"pattern":"ring","phase":"build","planned":1369.21518580563,"time":333.93333333332}
DIRECTOR {"alive":47,"curve":1412.63333333335,"damage":74.0498751314944,"exclusive":true,"intensity":0.325,"issued":1340,"nearby":0,"pattern":"ring","phase":"build","planned":1404.6818524723,"time":338.999999999986}
ACTIVITY event=success kind=fuel time=341.00 age=12.93 pos=(1724.285, 479.3917) offered=3 success=3 failed=0 rewards=3
DIRECTOR {"alive":11,"curve":1448.10000000002,"damage":86.2913101824587,"exclusive":false,"intensity":0.328125,"issued":1355,"nearby":1,"pattern":"ambush","phase":"build","planned":1444.70141048607,"time":344.066666666652}
DIRECTOR {"alive":39,"curve":1483.56666666669,"damage":86.2913101824587,"exclusive":false,"intensity":0.0,"issued":1394,"nearby":0,"pattern":"ambush","phase":"build","planned":1488.00254593346,"time":349.133333333319}
DIRECTOR {"alive":88,"curve":1519.03333333336,"damage":86.2913101824587,"exclusive":false,"intensity":0.0,"issued":1443,"nearby":0,"pattern":"ambush","phase":"peak","planned":1533.07629224614,"time":354.199999999985}
DIRECTOR {"alive":134,"curve":1554.50000000003,"damage":86.2913101824587,"exclusive":false,"intensity":0.0,"issued":1493,"nearby":0,"pattern":"ambush","phase":"peak","planned":1586.86390679875,"time":359.266666666651}
SIM 06:00 level=16 kills=1412 xp=1639/1714 credits=161/187 credits_left=101 zombies=123 kinds=99/0/10/14 elites=0 elites_spawned=2 crates=0 nades=9 dmg_taken=86 peak=134 fps=439 | АК-С L4 Стан1 [Дето1,Цепь1] | Гром L2 Стан1 [Рико2] | Игла L3 Стан1 [] | ППШ L1 Стан1 []
PICK lvl=17 { "type": "module", "id": 1, "rare": false } slot=2 of ["module", "level", "level"]
DIRECTOR {"alive":137,"curve":1594.23333333336,"damage":88.7913101824587,"exclusive":false,"intensity":0.3,"issued":1548,"nearby":0,"pattern":"ambush","phase":"peak","planned":1644.74623451331,"time":364.333333333318}
DIRECTOR {"alive":171,"curve":1634.76666666669,"damage":160.578225961573,"exclusive":false,"intensity":0.329166666666667,"issued":1613,"nearby":0,"pattern":"ambush","phase":"peak","planned":1702.66611820484,"time":369.399999999984}
DIRECTOR {"alive":126,"curve":1675.30000000002,"damage":232.1378620776,"exclusive":false,"intensity":0.365625,"issued":1654,"nearby":1,"pattern":"ambush","phase":"decay","planned":1749.28817692095,"time":374.466666666651}
DIRECTOR {"alive":66,"curve":1715.83333333335,"damage":239.6378620776,"exclusive":false,"intensity":0.39375,"issued":1688,"nearby":6,"pattern":"ambush","phase":"decay","planned":1783.51310823153,"time":379.533333333317}
DIRECTOR {"alive":45,"curve":1756.36666666668,"damage":322.135668092615,"exclusive":false,"intensity":0.341666666666667,"issued":1715,"nearby":0,"pattern":"tide","phase":"relax","planned":1815.97301158875,"time":384.599999999983}
DIRECTOR {"alive":38,"curve":1796.90000000001,"damage":371.670093828088,"exclusive":false,"intensity":0.33125,"issued":1740,"nearby":2,"pattern":"tide","phase":"relax","planned":1831.92907985676,"time":389.66666666665}
PICK lvl=18 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["ammo", "level", "ammo"]
DIRECTOR {"alive":15,"curve":1837.43333333335,"damage":504.971432367211,"exclusive":false,"intensity":0.335416666666667,"issued":1750,"nearby":2,"pattern":"tide","phase":"relax","planned":1847.86140518336,"time":394.733333333316}
DIRECTOR {"alive":7,"curve":1877.96666666668,"damage":507.471432367211,"exclusive":false,"intensity":0.3,"issued":1769,"nearby":0,"pattern":"tide","phase":"relax","planned":1863.39375326596,"time":399.799999999982}
DIRECTOR {"alive":31,"curve":1918.50000000001,"damage":507.471432367211,"exclusive":false,"intensity":0.0,"issued":1807,"nearby":0,"pattern":"flank","phase":"scout","planned":1898.01707227143,"time":404.866666666649}
DIRECTOR {"alive":22,"curve":1959.03333333334,"damage":507.471432367211,"exclusive":false,"intensity":0.0,"issued":1833,"nearby":0,"pattern":"flank","phase":"scout","planned":1932.91043931736,"time":409.933333333315}
PICK lvl=19 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["module", "level", "ammo"]
DIRECTOR {"alive":31,"curve":1999.56666666667,"damage":507.471432367211,"exclusive":false,"intensity":0.0291666666666667,"issued":1888,"nearby":0,"pattern":"flank","phase":"build","planned":1983.62131331652,"time":414.999999999982}
DIRECTOR {"alive":55,"curve":2040.1,"damage":507.471432367211,"exclusive":false,"intensity":0.0,"issued":1938,"nearby":0,"pattern":"flank","phase":"build","planned":2034.77920965027,"time":420.066666666648}
SIM 07:00 level=19 kills=1916 xp=2172/2448 credits=236/296 credits_left=176 zombies=55 kinds=38/0/12/5 elites=0 elites_spawned=4 crates=0 nades=13 dmg_taken=507 peak=171 fps=260 | АК-С L4 Стан3 [Дето1,Цепь1] | Гром L2 Стан1 [Рико2] | Игла L3 Стан1 [Проб1] | ППШ L1 Стан1 []
ALARM_EVENT warn time=07:00
ALARM_EVENT start time=07:03
DIRECTOR {"alive":95,"curve":2112.63333333333,"damage":571.555204897739,"exclusive":true,"intensity":0.390625,"issued":2013,"nearby":5,"pattern":"flank","phase":"build","planned":2107.45346165195,"time":425.133333333314}
PICK lvl=20 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["module", "passive", "level"]
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
DIRECTOR {"alive":108,"curve":2234.23333333332,"damage":809.39313405861,"exclusive":true,"intensity":0.521875,"issued":2136,"nearby":11,"pattern":"flank","phase":"build","planned":2229.05346165195,"time":430.199999999981}
PICK lvl=21 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "level", "level"]
DIRECTOR {"alive":109,"curve":2355.83333333332,"damage":1347.28864934331,"exclusive":true,"intensity":0.308333333333333,"issued":2258,"nearby":0,"pattern":"flank","phase":"peak","planned":2350.65346165194,"time":435.266666666647}
DIRECTOR {"alive":159,"curve":2477.43333333331,"damage":1412.14304044133,"exclusive":true,"intensity":0.316666666666667,"issued":2373,"nearby":0,"pattern":"flank","phase":"peak","planned":2472.25346165193,"time":440.333333333313}
PICK lvl=22 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["level", "level", "ammo"]
DIRECTOR {"alive":62,"curve":2599.0333333333,"damage":1412.14304044133,"exclusive":true,"intensity":0.03125,"issued":2500,"nearby":2,"pattern":"flank","phase":"peak","planned":2593.85346165193,"time":445.39999999998}
DIRECTOR {"alive":87,"curve":2720.6333333333,"damage":1499.41804044133,"exclusive":true,"intensity":0.35,"issued":2616,"nearby":0,"pattern":"flank","phase":"peak","planned":2715.45346165192,"time":450.466666666646}
ALARM_EVENT finish container=(2414.448, 567.1375) time=07:33
CONTAINER dropped pos=(2414.448, 567.1375) time=07:33
ALARM rewards mult=2 xp=2016 credits=340
LOOT СБРОС СНАБЖЕНИЯ: module slot=1 rare=false
CONTAINER picked time=07:34 crates=2
DIRECTOR {"alive":31,"curve":2806.23333333329,"damage":1540.57653539067,"exclusive":false,"intensity":0.333333333333333,"issued":2696,"nearby":0,"pattern":"tide","phase":"decay","planned":2797.68891534976,"time":455.533333333313}
PICK lvl=23 { "type": "module", "id": 2, "rare": false } slot=1 of ["passive", "module", "level"]
PICK lvl=24 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["passive", "level", "ammo"]
DIRECTOR {"alive":14,"curve":2851.83333333328,"damage":1553.61133687382,"exclusive":false,"intensity":0.308333333333333,"issued":2736,"nearby":0,"pattern":"tide","phase":"decay","planned":2836.0092740729,"time":460.599999999979}
DIRECTOR {"alive":0,"curve":2897.43333333327,"damage":1553.61133687382,"exclusive":false,"intensity":0.0,"issued":2765,"nearby":0,"pattern":"tide","phase":"relax","planned":2866.69362679098,"time":465.666666666645}
DIRECTOR {"alive":2,"curve":2943.03333333327,"damage":1553.61133687382,"exclusive":false,"intensity":0.0,"issued":2778,"nearby":0,"pattern":"tide","phase":"relax","planned":2878.31374183522,"time":470.733333333312}
PICK lvl=25 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "level", "module"]
DIRECTOR {"alive":11,"curve":2988.63333333326,"damage":1553.61133687382,"exclusive":false,"intensity":0.0125,"issued":2792,"nearby":0,"pattern":"tide","phase":"relax","planned":2889.85988848503,"time":475.799999999978}
SIM 08:00 level=25 kills=2829 xp=4165/4853 credits=560/687 credits_left=500 zombies=2 kinds=2/0/0/0 elites=0 elites_spawned=10 crates=2 nades=17 dmg_taken=1554 peak=183 fps=212 | АК-С L4 Зажи3 [Дето1,Цепь1] | Гром L3 Стан1 [Рико3,Спли1] | Игла L3 Стан1 [Проб1] | ППШ L2 Стан1 []
DIRECTOR {"alive":18,"curve":3035.83333333325,"damage":1553.61133687382,"exclusive":false,"intensity":0.0,"issued":2807,"nearby":0,"pattern":"column","phase":"scout","planned":2907.22651722502,"time":480.866666666645}
DIRECTOR {"alive":21,"curve":3091.56666666657,"damage":1553.61133687382,"exclusive":false,"intensity":0.0458333333333333,"issued":2848,"nearby":0,"pattern":"column","phase":"scout","planned":2955.18980378213,"time":485.933333333311}
DIRECTOR {"alive":26,"curve":3147.29999999989,"damage":1553.61133687382,"exclusive":false,"intensity":0.141666666666667,"issued":2907,"nearby":8,"pattern":"column","phase":"build","planned":3007.2480307803,"time":490.999999999977}
DIRECTOR {"alive":72,"curve":3203.0333333332,"damage":1765.14633687382,"exclusive":false,"intensity":0.3,"issued":2975,"nearby":0,"pattern":"column","phase":"build","planned":3075.21096872805,"time":496.066666666644}
DIRECTOR {"alive":55,"curve":3258.76666666652,"damage":1780.9199088419,"exclusive":false,"intensity":0.35,"issued":3040,"nearby":0,"pattern":"column","phase":"build","planned":3143.07710582595,"time":501.13333333331}
PICK lvl=26 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["module", "passive", "ammo"]
DIRECTOR {"alive":22,"curve":3314.49999999984,"damage":1795.15791829472,"exclusive":false,"intensity":0.3,"issued":3109,"nearby":0,"pattern":"column","phase":"build","planned":3212.37482980404,"time":506.199999999976}
DIRECTOR {"alive":10,"curve":3370.23333333316,"damage":1810.14485200291,"exclusive":false,"intensity":0.35,"issued":3179,"nearby":0,"pattern":"column","phase":"build","planned":3280.22320527813,"time":511.266666666643}
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=2 rare=true
PICK lvl=27 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["module", "passive", "ammo"]
DIRECTOR {"alive":7,"curve":3425.23333333314,"damage":1810.14485200291,"exclusive":false,"intensity":0.396875,"issued":3246,"nearby":3,"pattern":"column","phase":"peak","planned":3351.77388843676,"time":516.266666666646}
DIRECTOR {"alive":64,"curve":3480.23333333312,"damage":1860.56151866958,"exclusive":false,"intensity":0.3,"issued":3330,"nearby":0,"pattern":"column","phase":"peak","planned":3429.73877846257,"time":521.26666666665}
DIRECTOR {"alive":55,"curve":3535.23333333311,"damage":1868.06151866958,"exclusive":false,"intensity":0.35,"issued":3405,"nearby":0,"pattern":"column","phase":"peak","planned":3508.18268259236,"time":526.266666666654}
DIRECTOR {"alive":40,"curve":3590.23333333309,"damage":1899.5008039479,"exclusive":false,"intensity":0.3375,"issued":3487,"nearby":0,"pattern":"column","phase":"peak","planned":3586.54316657889,"time":531.266666666658}
DIRECTOR {"alive":25,"curve":3645.23333333308,"damage":1918.0409469609,"exclusive":true,"intensity":0.304166666666667,"issued":3530,"nearby":0,"pattern":"column","phase":"decay","planned":3639.53801696166,"time":536.266666666662}
CALM 09:00 removed=30 left=0
TRADER 1 at 09:00 credits_left=337 bought=["ammo(60)", "level(75)", "module(60)", "level(75)", "module(60)"]
SIM 09:00 level=27 kills=3581 xp=5285/5951 credits=727/822 credits_left=337 zombies=30 kinds=15/8/4/3 elites=0 elites_spawned=12 crates=2 nades=19 dmg_taken=1921 peak=102 fps=267 | АК-С L4 Крио1 [Дето1,Цепь1] | Гром L3 Стан1 [Рико3,Спли1] | Игла L4 Стан1 [Проб3,Сдво1] | ППШ L3 Стан1 []
DIRECTOR {"alive":1,"curve":3690.63333333306,"damage":1920.5409469609,"exclusive":true,"intensity":0.3,"issued":3570,"nearby":0,"pattern":"column","phase":"decay","planned":3684.93801696164,"time":541.266666666666}
PICK lvl=28 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "level", "module"]
DIRECTOR {"alive":12,"curve":3705.63333333305,"damage":1920.5409469609,"exclusive":true,"intensity":0.0,"issued":3584,"nearby":0,"pattern":"column","phase":"relax","planned":3699.93801696163,"time":546.26666666667}
DIRECTOR {"alive":14,"curve":3720.63333333303,"damage":1920.5409469609,"exclusive":true,"intensity":0.0125,"issued":3601,"nearby":0,"pattern":"column","phase":"relax","planned":3714.93801696162,"time":551.266666666674}
DIRECTOR {"alive":10,"curve":3735.63333333302,"damage":1920.5409469609,"exclusive":true,"intensity":0.0,"issued":3611,"nearby":0,"pattern":"column","phase":"relax","planned":3729.9380169616,"time":556.266666666678}
DIRECTOR {"alive":11,"curve":3750.63333333301,"damage":1920.5409469609,"exclusive":true,"intensity":0.00833333333333333,"issued":3623,"nearby":0,"pattern":"column","phase":"scout","planned":3744.93801696159,"time":561.266666666682}
DIRECTOR {"alive":18,"curve":3765.63333333299,"damage":1920.5409469609,"exclusive":true,"intensity":0.0125,"issued":3649,"nearby":0,"pattern":"column","phase":"scout","planned":3759.93801696158,"time":566.266666666686}
DIRECTOR {"alive":0,"curve":3781.89999999965,"damage":1920.5409469609,"exclusive":true,"intensity":0.00416666666666667,"issued":3658,"nearby":0,"pattern":"column","phase":"build","planned":3776.20468362824,"time":571.26666666669}
DIRECTOR {"alive":10,"curve":3801.89999999967,"damage":1920.5409469609,"exclusive":true,"intensity":0.00416666666666667,"issued":3684,"nearby":0,"pattern":"column","phase":"build","planned":3796.20468362825,"time":576.266666666694}
PICK lvl=29 { "type": "module", "id": 3, "rare": false } slot=0 of ["level", "module", "ammo"]
DIRECTOR {"alive":9,"curve":3821.89999999969,"damage":1920.5409469609,"exclusive":true,"intensity":0.0166666666666667,"issued":3697,"nearby":0,"pattern":"column","phase":"build","planned":3816.20468362827,"time":581.266666666698}
DIRECTOR {"alive":19,"curve":3841.8999999997,"damage":1920.5409469609,"exclusive":true,"intensity":0.0333333333333333,"issued":3724,"nearby":0,"pattern":"column","phase":"build","planned":3836.20468362828,"time":586.266666666702}
DIRECTOR {"alive":9,"curve":3861.89999999972,"damage":1920.5409469609,"exclusive":true,"intensity":0.0125,"issued":3737,"nearby":0,"pattern":"column","phase":"build","planned":3856.2046836283,"time":591.266666666706}
DIRECTOR {"alive":0,"curve":3881.89999999973,"damage":1920.5409469609,"exclusive":true,"intensity":0.0458333333333333,"issued":3762,"nearby":0,"pattern":"column","phase":"peak","planned":3876.20468362832,"time":596.26666666671}
BOSS spawn t=600.00 pos=(2160.452, 687.0635) hp=24000
SIM 10:00 level=29 kills=3785 xp=6060/6203 credits=820/858 credits_left=430 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=14 crates=2 nades=19 dmg_taken=1921 peak=33 fps=446 | АК-С L4 Крио1 [Дето2,Цепь1] | Гром L4 Стан1 [Рико3,Спли1] | Игла L4 Стан1 [Проб3,Сдво1] | ППШ L3 Стан1 []
SIM summary kills=3785 peak=183 level=29 damage=1920.54 boss_alive=true
DIRECTOR summary curve=3896.83 planned=3891.14 issued=3772 dropped=41

EXIT_CODE=0
```

## hd1_fixed_w1_control.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_fixed_w1_control_engine.log --headless --fixed-fps 60 --path C:\Users\Dev\Desktop\zera-hd1 -- --sim=600 --fresh-save --layout-seed=81073 --director-trace=fixed_w1 --loadout-w1 --director-off
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=197.15 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
PICK lvl=2 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
PICK lvl=3 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "passive", "passive"]
ACTIVITY event=start kind=carrier time=57.47 age=0.00 pos=(1304.0, 552.0) offered=1 success=0 failed=0 rewards=0
SIM 01:00 level=3 kills=58 xp=40/58 credits=3/4 credits_left=3 zombies=29 kinds=28/1/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=120 peak=41 fps=691 | Кольт L5 Зажи3 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
ACTIVITY event=success kind=carrier time=62.13 age=4.67 pos=(1309.161, 466.7736) offered=1 success=1 failed=0 rewards=1
PICK lvl=4 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["ammo", "passive", "ammo"]
PICK lvl=5 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
PICK lvl=6 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["passive", "passive", "ammo"]
PICK lvl=7 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "passive", "passive"]
SIM 02:00 level=7 kills=260 xp=208/295 credits=10/13 credits_left=10 zombies=9 kinds=9/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=120 peak=46 fps=594 | Кольт L5 Эксп1 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
PICK lvl=8 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
PICK lvl=9 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["passive", "passive", "passive"]
ACTIVITY event=start kind=supply time=152.87 age=0.00 pos=(1928.0, 264.0) offered=2 success=1 failed=0 rewards=1
ACTIVITY event=success kind=supply time=176.33 age=23.47 pos=(1928.0, 264.0) offered=2 success=2 failed=0 rewards=2
SIM 03:00 level=9 kills=508 xp=373/543 credits=19/28 credits_left=19 zombies=11 kinds=11/0/0/0 elites=0 elites_spawned=0 crates=0 nades=1 dmg_taken=120 peak=55 fps=599 | Кольт L5 Эксп1 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
PICK lvl=10 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
PICK lvl=11 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["passive", "passive", "passive"]
SIM 04:00 level=11 kills=782 xp=716/841 credits=38/54 credits_left=38 zombies=14 kinds=10/0/4/0 elites=0 elites_spawned=0 crates=0 nades=2 dmg_taken=120 peak=26 fps=557 | Кольт L5 Эксп1 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
PICK lvl=12 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "passive", "passive"]
PICK lvl=13 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["passive", "ammo", "ammo"]
PICK lvl=14 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["passive", "ammo", "ammo"]
TRADER 0 at 05:00 credits_left=10 bought=["passive(40)", "ammo(40)"]
SIM 05:00 level=14 kills=1141 xp=1197/1329 credits=90/101 credits_left=10 zombies=14 kinds=12/0/2/0 elites=0 elites_spawned=0 crates=0 nades=2 dmg_taken=120 peak=35 fps=451 | Кольт L5 Зажи2 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
PICK lvl=15 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["passive", "ammo", "ammo"]
PICK lvl=16 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["ammo", "passive", "ammo"]
ACTIVITY event=start kind=fuel time=328.07 age=0.00 pos=(1634.924, 499.9578) offered=3 success=2 failed=0 rewards=2
ACTIVITY event=success kind=fuel time=341.00 age=12.93 pos=(1634.924, 499.9578) offered=3 success=3 failed=0 rewards=3
PICK lvl=17 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["ammo", "passive", "ammo"]
SIM 06:00 level=17 kills=1575 xp=1730/1973 credits=165/214 credits_left=85 zombies=11 kinds=10/0/0/1 elites=0 elites_spawned=2 crates=0 nades=4 dmg_taken=120 peak=41 fps=405 | Кольт L5 Стан1 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
PICK lvl=18 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
PICK lvl=19 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["ammo", "ammo", "passive"]
PICK lvl=20 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
SIM 07:00 level=20 kills=2060 xp=2476/2696 credits=285/327 credits_left=205 zombies=11 kinds=8/0/2/1 elites=0 elites_spawned=4 crates=1 nades=7 dmg_taken=120 peak=60 fps=421 | Кольт L5 Стан3 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
ALARM_EVENT warn time=07:00
ALARM_EVENT start time=07:03
PICK lvl=21 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["passive", "passive", "ammo"]
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
PICK lvl=22 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["ammo", "passive", "ammo"]
PICK lvl=23 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["passive", "ammo", "passive"]
PICK lvl=24 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["passive", "passive", "ammo"]
ALARM_EVENT finish container=(2228.82, 497.1561) time=07:33
CONTAINER dropped pos=(2228.82, 497.1561) time=07:33
ALARM rewards mult=2 xp=2266 credits=338
PICK lvl=25 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
CONTAINER picked time=07:34 crates=3
PICK lvl=26 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["passive", "ammo", "ammo"]
PICK lvl=27 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
SIM 08:00 level=27 kills=3051 xp=5278/5385 credits=691/718 credits_left=611 zombies=13 kinds=9/0/2/2 elites=0 elites_spawned=10 crates=3 nades=10 dmg_taken=120 peak=75 fps=332 | Кольт L5 Стан1 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
PICK lvl=28 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
PICK lvl=29 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["ammo", "passive", "ammo"]
CALM 09:00 removed=2 left=0
TRADER 1 at 09:00 credits_left=327 bought=["ammo(60)", "passive(60)", "ammo(150)", "passive(60)", "passive(60)"]
SIM 09:00 level=29 kills=3712 xp=6122/6355 credits=797/845 credits_left=327 zombies=2 kinds=2/0/0/0 elites=0 elites_spawned=12 crates=3 nades=12 dmg_taken=120 peak=37 fps=392 | Кольт L5 Стан1 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
PICK lvl=30 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
BOSS spawn t=600.00 pos=(2522.88, 772.753) hp=24000
SIM 10:00 level=30 kills=3927 xp=6569/6618 credits=855/878 credits_left=385 zombies=3 kinds=0/3/0/0 elites=0 elites_spawned=14 crates=3 nades=13 dmg_taken=120 peak=28 fps=611 | Кольт L5 Стан1 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
SIM summary kills=3927 peak=75 level=30 damage=120.00 boss_alive=true

EXIT_CODE=0
```

## hd1_fixed_w1_after.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_fixed_w1_after_engine.log --headless --fixed-fps 60 --path C:\Users\Dev\Desktop\zera-hd1 -- --sim=600 --fresh-save --layout-seed=81073 --director-trace=fixed_w1 --loadout-w1
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=180.39 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
DIRECTOR {"alive":0,"curve":0.0,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":0,"nearby":0,"pattern":"column","phase":"scout","planned":0.0,"time":0.0666666666666667}
DIRECTOR {"alive":4,"curve":7.49999999999999,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":4,"nearby":0,"pattern":"tide","phase":"scout","planned":7.49999999999999,"time":5.06666666666667}
DIRECTOR {"alive":13,"curve":15.1,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":13,"nearby":0,"pattern":"tide","phase":"build","planned":15.1,"time":10.1333333333333}
DIRECTOR {"alive":19,"curve":22.7000000000001,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":19,"nearby":0,"pattern":"tide","phase":"build","planned":22.7000000000001,"time":15.2}
DIRECTOR {"alive":29,"curve":30.3000000000002,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":29,"nearby":0,"pattern":"tide","phase":"build","planned":30.3000000000002,"time":20.2666666666666}
DIRECTOR {"alive":20,"curve":37.9000000000003,"damage":0.0,"exclusive":false,"intensity":0.00416666666666667,"issued":32,"nearby":0,"pattern":"tide","phase":"build","planned":37.9000000000003,"time":25.3333333333333}
PICK lvl=2 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
DIRECTOR {"alive":14,"curve":45.5000000000004,"damage":120.0,"exclusive":false,"intensity":0.3,"issued":43,"nearby":0,"pattern":"tide","phase":"build","planned":45.5000000000004,"time":30.3999999999999}
DIRECTOR {"alive":18,"curve":53.0000000000005,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":50,"nearby":0,"pattern":"tide","phase":"peak","planned":53.0000000000005,"time":35.4000000000001}
PICK lvl=3 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "passive", "passive"]
DIRECTOR {"alive":14,"curve":60.5000000000006,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":58,"nearby":0,"pattern":"tide","phase":"peak","planned":60.5000000000006,"time":40.4000000000003}
DIRECTOR {"alive":23,"curve":68.0000000000004,"damage":120.0,"exclusive":false,"intensity":0.1,"issued":67,"nearby":0,"pattern":"tide","phase":"peak","planned":68.0000000000004,"time":45.4000000000006}
DIRECTOR {"alive":27,"curve":75.5,"damage":120.0,"exclusive":false,"intensity":0.1,"issued":75,"nearby":0,"pattern":"tide","phase":"peak","planned":75.5,"time":50.4000000000008}
PICK lvl=4 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "passive", "passive"]
DIRECTOR {"alive":27,"curve":82.9999999999996,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":80,"nearby":0,"pattern":"tide","phase":"decay","planned":82.9999999999996,"time":55.4000000000011}
ACTIVITY event=start kind=carrier time=57.47 age=0.00 pos=(1476.056, 1012.383) offered=1 success=0 failed=0 rewards=0
ACTIVITY event=success kind=carrier time=59.60 age=2.13 pos=(1487.076, 1014.382) offered=1 success=1 failed=0 rewards=1
SIM 01:00 level=4 kills=54 xp=49/89 credits=4/4 credits_left=4 zombies=33 kinds=33/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=120 peak=34 fps=691 | Кольт L5 Зажи3 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":33,"curve":91.0999999999992,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":86,"nearby":0,"pattern":"column","phase":"decay","planned":90.8713603560885,"time":60.4000000000013}
PICK lvl=5 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
DIRECTOR {"alive":33,"curve":106.099999999999,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":90,"nearby":0,"pattern":"column","phase":"relax","planned":100.674413032026,"time":65.4000000000014}
DIRECTOR {"alive":30,"curve":121.3,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":99,"nearby":0,"pattern":"column","phase":"relax","planned":104.616273967551,"time":70.4666666666678}
DIRECTOR {"alive":22,"curve":136.499999999999,"damage":120.0,"exclusive":false,"intensity":0.1,"issued":104,"nearby":0,"pattern":"column","phase":"relax","planned":108.801271755162,"time":75.5333333333342}
DIRECTOR {"alive":16,"curve":151.699999999998,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":110,"nearby":0,"pattern":"ambush","phase":"scout","planned":113.798652286135,"time":80.6000000000005}
DIRECTOR {"alive":20,"curve":166.899999999998,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":120,"nearby":0,"pattern":"ambush","phase":"scout","planned":126.868743310156,"time":85.6666666666669}
DIRECTOR {"alive":22,"curve":182.099999999997,"damage":120.0,"exclusive":false,"intensity":0.125,"issued":128,"nearby":0,"pattern":"ambush","phase":"build","planned":140.825759745047,"time":90.7333333333333}
DIRECTOR {"alive":27,"curve":197.299999999996,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":143,"nearby":0,"pattern":"ambush","phase":"build","planned":159.933434418456,"time":95.7999999999997}
DIRECTOR {"alive":27,"curve":212.499999999995,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":167,"nearby":0,"pattern":"ambush","phase":"build","planned":179.133146597133,"time":100.866666666666}
PICK lvl=6 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["ammo", "ammo", "passive"]
DIRECTOR {"alive":52,"curve":227.699999999994,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":192,"nearby":0,"pattern":"ambush","phase":"build","planned":198.349328645173,"time":105.933333333332}
DIRECTOR {"alive":47,"curve":242.899999999993,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":212,"nearby":0,"pattern":"ambush","phase":"build","planned":217.426001211544,"time":110.999999999999}
DIRECTOR {"alive":35,"curve":258.099999999992,"damage":120.0,"exclusive":false,"intensity":0.1125,"issued":227,"nearby":0,"pattern":"ambush","phase":"peak","planned":238.099719079222,"time":116.066666666665}
SIM 02:00 level=6 kills=220 xp=185/255 credits=17/22 credits_left=17 zombies=33 kinds=33/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=120 peak=58 fps=595 | Кольт L5 Эксп1 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":21,"curve":274.366666666658,"damage":120.0,"exclusive":false,"intensity":0.0416666666666667,"issued":256,"nearby":0,"pattern":"ambush","phase":"peak","planned":262.404795564684,"time":121.133333333332}
PICK lvl=7 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
DIRECTOR {"alive":46,"curve":294.633333333324,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":283,"nearby":0,"pattern":"ambush","phase":"peak","planned":293.120352243993,"time":126.199999999998}
DIRECTOR {"alive":77,"curve":314.899999999989,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":314,"nearby":0,"pattern":"ambush","phase":"peak","planned":323.866243520857,"time":131.266666666664}
DIRECTOR {"alive":59,"curve":335.166666666655,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":334,"nearby":0,"pattern":"ambush","phase":"decay","planned":342.558237199746,"time":136.333333333331}
DIRECTOR {"alive":69,"curve":355.43333333332,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":355,"nearby":0,"pattern":"ambush","phase":"decay","planned":358.966311929345,"time":141.399999999997}
PICK lvl=8 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
DIRECTOR {"alive":70,"curve":375.699999999986,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":366,"nearby":0,"pattern":"ambush","phase":"relax","planned":370.033377528446,"time":146.466666666663}
DIRECTOR {"alive":64,"curve":395.966666666651,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":371,"nearby":0,"pattern":"ambush","phase":"relax","planned":375.197873103665,"time":151.53333333333}
ACTIVITY event=start kind=supply time=152.87 age=0.00 pos=(1864.0, 264.0) offered=2 success=1 failed=0 rewards=1
DIRECTOR {"alive":72,"curve":416.233333333317,"damage":120.0,"exclusive":true,"intensity":0.0,"issued":384,"nearby":0,"pattern":"ambush","phase":"relax","planned":391.280468973871,"time":156.599999999996}
DIRECTOR {"alive":99,"curve":436.499999999982,"damage":120.0,"exclusive":true,"intensity":0.0,"issued":405,"nearby":0,"pattern":"ambush","phase":"scout","planned":411.547135640536,"time":161.666666666663}
DIRECTOR {"alive":76,"curve":456.766666666648,"damage":120.0,"exclusive":true,"intensity":0.0,"issued":415,"nearby":0,"pattern":"ambush","phase":"scout","planned":431.813802307202,"time":166.733333333329}
DIRECTOR {"alive":92,"curve":477.033333333313,"damage":120.0,"exclusive":true,"intensity":0.0,"issued":440,"nearby":0,"pattern":"ambush","phase":"build","planned":452.080468973867,"time":171.799999999995}
DIRECTOR {"alive":33,"curve":497.299999999979,"damage":120.0,"exclusive":true,"intensity":0.0,"issued":462,"nearby":0,"pattern":"ambush","phase":"build","planned":472.347135640533,"time":176.866666666662}
ACTIVITY event=success kind=supply time=177.13 age=24.27 pos=(1864.0, 264.0) offered=2 success=2 failed=0 rewards=2
SIM 03:00 level=8 kills=479 xp=302/514 credits=23/32 credits_left=23 zombies=8 kinds=7/1/0/0 elites=0 elites_spawned=0 crates=0 nades=2 dmg_taken=120 peak=99 fps=501 | Кольт L5 Эксп1 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":18,"curve":517.566666666644,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":479,"nearby":0,"pattern":"rush","phase":"build","planned":497.577016522679,"time":181.933333333328}
DIRECTOR {"alive":40,"curve":537.83333333331,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":502,"nearby":0,"pattern":"rush","phase":"build","planned":523.197300832272,"time":186.999999999995}
PICK lvl=9 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "ammo", "ammo"]
DIRECTOR {"alive":60,"curve":558.099999999975,"damage":120.0,"exclusive":false,"intensity":0.00416666666666667,"issued":529,"nearby":0,"pattern":"rush","phase":"build","planned":548.780124262526,"time":192.066666666661}
DIRECTOR {"alive":51,"curve":578.366666666641,"damage":120.0,"exclusive":false,"intensity":0.05,"issued":554,"nearby":0,"pattern":"rush","phase":"peak","planned":577.471466304946,"time":197.133333333327}
PICK lvl=10 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
DIRECTOR {"alive":60,"curve":598.633333333306,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":578,"nearby":0,"pattern":"rush","phase":"peak","planned":608.136465321662,"time":202.199999999994}
DIRECTOR {"alive":60,"curve":618.899999999972,"damage":120.0,"exclusive":false,"intensity":0.0291666666666667,"issued":622,"nearby":0,"pattern":"rush","phase":"peak","planned":638.815367695591,"time":207.26666666666}
DIRECTOR {"alive":52,"curve":641.433333333306,"damage":120.0,"exclusive":false,"intensity":0.05,"issued":652,"nearby":0,"pattern":"rush","phase":"decay","planned":671.968779410721,"time":212.333333333326}
DIRECTOR {"alive":50,"curve":666.766666666642,"damage":120.0,"exclusive":false,"intensity":0.025,"issued":671,"nearby":0,"pattern":"rush","phase":"decay","planned":692.498704962065,"time":217.399999999993}
PICK lvl=11 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["passive", "passive", "passive"]
DIRECTOR {"alive":49,"curve":692.099999999978,"damage":120.0,"exclusive":false,"intensity":0.0458333333333333,"issued":693,"nearby":0,"pattern":"rush","phase":"decay","planned":713.013464759792,"time":222.466666666659}
DIRECTOR {"alive":48,"curve":717.433333333315,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":693,"nearby":0,"pattern":"rush","phase":"relax","planned":723.882921144119,"time":227.533333333326}
DIRECTOR {"alive":29,"curve":742.766666666651,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":708,"nearby":0,"pattern":"rush","phase":"relax","planned":730.343106563422,"time":232.599999999992}
DIRECTOR {"alive":30,"curve":768.099999999987,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":717,"nearby":0,"pattern":"rush","phase":"relax","planned":736.785028181631,"time":237.666666666658}
SIM 04:00 level=11 kills=735 xp=644/788 credits=39/50 credits_left=39 zombies=3 kinds=2/0/1/0 elites=0 elites_spawned=0 crates=0 nades=2 dmg_taken=120 peak=86 fps=416 | Кольт L5 Эксп1 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":0,"curve":796.099999999987,"damage":120.0,"exclusive":false,"intensity":0.0,"issued":731,"nearby":0,"pattern":"column","phase":"scout","planned":753.695385113786,"time":242.733333333325}
DIRECTOR {"alive":0,"curve":826.499999999986,"damage":120.0,"exclusive":false,"intensity":0.05,"issued":758,"nearby":0,"pattern":"column","phase":"scout","planned":779.851003318591,"time":247.799999999991}
DIRECTOR {"alive":0,"curve":856.899999999984,"damage":120.0,"exclusive":false,"intensity":0.00416666666666667,"issued":786,"nearby":0,"pattern":"column","phase":"build","planned":812.753129740844,"time":252.866666666657}
PICK lvl=12 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["passive", "ammo", "passive"]
DIRECTOR {"alive":0,"curve":887.299999999982,"damage":156.401666666666,"exclusive":false,"intensity":0.3,"issued":816,"nearby":0,"pattern":"column","phase":"build","planned":850.693335387706,"time":257.933333333324}
DIRECTOR {"alive":0,"curve":917.69999999998,"damage":156.401666666666,"exclusive":false,"intensity":0.025,"issued":851,"nearby":0,"pattern":"column","phase":"build","planned":888.025124683958,"time":262.99999999999}
DIRECTOR {"alive":0,"curve":948.099999999979,"damage":156.401666666666,"exclusive":false,"intensity":0.00833333333333333,"issued":884,"nearby":0,"pattern":"column","phase":"build","planned":926.383858775827,"time":268.066666666657}
PICK lvl=13 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["passive", "ammo", "ammo"]
DIRECTOR {"alive":0,"curve":978.499999999977,"damage":156.401666666666,"exclusive":false,"intensity":0.0,"issued":928,"nearby":0,"pattern":"column","phase":"build","planned":964.754218657836,"time":273.133333333323}
DIRECTOR {"alive":19,"curve":1008.89999999998,"damage":156.401666666666,"exclusive":false,"intensity":0.0458333333333333,"issued":968,"nearby":0,"pattern":"column","phase":"peak","planned":1009.39835308683,"time":278.199999999989}
DIRECTOR {"alive":9,"curve":1039.29999999998,"damage":156.401666666666,"exclusive":false,"intensity":0.0,"issued":1011,"nearby":0,"pattern":"column","phase":"peak","planned":1055.0725985567,"time":283.266666666656}
PICK lvl=14 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["passive", "passive", "ammo"]
DIRECTOR {"alive":6,"curve":1069.69999999998,"damage":156.401666666666,"exclusive":true,"intensity":0.05,"issued":1049,"nearby":0,"pattern":"column","phase":"peak","planned":1091.02279577541,"time":288.333333333322}
DIRECTOR {"alive":5,"curve":1100.09999999999,"damage":156.401666666666,"exclusive":true,"intensity":0.0166666666666667,"issued":1080,"nearby":0,"pattern":"column","phase":"decay","planned":1121.42279577542,"time":293.399999999988}
DIRECTOR {"alive":0,"curve":1130.5,"damage":156.401666666666,"exclusive":true,"intensity":0.0416666666666667,"issued":1110,"nearby":0,"pattern":"column","phase":"decay","planned":1151.82279577543,"time":298.466666666655}
TRADER 0 at 05:00 credits_left=2 bought=["ammo(40)", "passive(40)"]
SIM 05:00 level=14 kills=1129 xp=1123/1287 credits=82/95 credits_left=2 zombies=13 kinds=13/0/0/0 elites=0 elites_spawned=0 crates=0 nades=4 dmg_taken=156 peak=38 fps=388 | Кольт L5 Стан1 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":12,"curve":1164.36666666667,"damage":156.401666666666,"exclusive":true,"intensity":0.0,"issued":1146,"nearby":0,"pattern":"column","phase":"decay","planned":1185.6894624421,"time":303.533333333321}
DIRECTOR {"alive":15,"curve":1199.83333333334,"damage":156.401666666666,"exclusive":true,"intensity":0.05,"issued":1179,"nearby":0,"pattern":"column","phase":"relax","planned":1221.15612910877,"time":308.599999999988}
PICK lvl=15 { "type": "ammo", "id": 2, "rare": true } slot=0 of ["passive", "ammo", "passive"]
DIRECTOR {"alive":15,"curve":1235.30000000001,"damage":156.401666666666,"exclusive":true,"intensity":0.0,"issued":1215,"nearby":0,"pattern":"column","phase":"relax","planned":1256.62279577544,"time":313.666666666654}
DIRECTOR {"alive":0,"curve":1270.76666666668,"damage":156.401666666666,"exclusive":false,"intensity":0.0,"issued":1228,"nearby":0,"pattern":"ambush","phase":"relax","planned":1272.99557158664,"time":318.73333333332}
DIRECTOR {"alive":8,"curve":1306.23333333334,"damage":156.401666666666,"exclusive":false,"intensity":0.0,"issued":1259,"nearby":0,"pattern":"rush","phase":"scout","planned":1297.84554208812,"time":323.799999999987}
ACTIVITY event=start kind=fuel time=328.07 age=0.00 pos=(1749.219, 259.8284) offered=3 success=2 failed=0 rewards=2
DIRECTOR {"alive":8,"curve":1341.70000000001,"damage":156.401666666666,"exclusive":true,"intensity":0.0458333333333333,"issued":1278,"nearby":0,"pattern":"rush","phase":"scout","planned":1329.06517630641,"time":328.866666666653}
DIRECTOR {"alive":37,"curve":1377.16666666668,"damage":156.401666666666,"exclusive":true,"intensity":0.0458333333333333,"issued":1317,"nearby":0,"pattern":"rush","phase":"build","planned":1364.53184297308,"time":333.93333333332}
DIRECTOR {"alive":63,"curve":1412.63333333335,"damage":156.401666666666,"exclusive":true,"intensity":0.0,"issued":1349,"nearby":0,"pattern":"rush","phase":"build","planned":1399.99850963975,"time":338.999999999986}
ACTIVITY event=success kind=fuel time=340.73 age=12.67 pos=(1749.219, 259.8284) offered=3 success=3 failed=0 rewards=3
DIRECTOR {"alive":48,"curve":1448.10000000002,"damage":169.73872282664,"exclusive":false,"intensity":0.308333333333333,"issued":1361,"nearby":0,"pattern":"ring","phase":"build","planned":1441.1368958246,"time":344.066666666652}
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
PICK lvl=16 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["ammo", "ammo", "passive"]
DIRECTOR {"alive":49,"curve":1483.56666666669,"damage":169.73872282664,"exclusive":false,"intensity":0.015625,"issued":1412,"nearby":1,"pattern":"ring","phase":"build","planned":1484.53382293867,"time":349.133333333319}
DIRECTOR {"alive":33,"curve":1519.03333333336,"damage":183.423632647196,"exclusive":false,"intensity":0.3,"issued":1459,"nearby":0,"pattern":"ring","phase":"peak","planned":1529.2265347135,"time":354.199999999985}
DIRECTOR {"alive":40,"curve":1554.50000000003,"damage":183.423632647196,"exclusive":false,"intensity":0.0,"issued":1505,"nearby":0,"pattern":"ring","phase":"peak","planned":1579.99269695539,"time":359.266666666651}
SIM 06:00 level=16 kills=1501 xp=1585/1816 credits=136/180 credits_left=56 zombies=47 kinds=41/0/5/1 elites=0 elites_spawned=2 crates=0 nades=5 dmg_taken=183 peak=67 fps=308 | Кольт L5 Стан1 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":80,"curve":1594.23333333336,"damage":183.423632647196,"exclusive":false,"intensity":0.0,"issued":1568,"nearby":0,"pattern":"ring","phase":"peak","planned":1640.15264736977,"time":364.333333333318}
DIRECTOR {"alive":99,"curve":1634.76666666669,"damage":183.423632647196,"exclusive":false,"intensity":0.0239583333333333,"issued":1632,"nearby":1,"pattern":"ring","phase":"peak","planned":1701.45926248425,"time":369.399999999984}
PICK lvl=17 { "type": "ammo", "id": 2, "rare": true } slot=0 of ["passive", "passive", "ammo"]
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
DIRECTOR {"alive":101,"curve":1675.30000000002,"damage":222.678632647196,"exclusive":false,"intensity":0.304166666666667,"issued":1674,"nearby":0,"pattern":"ring","phase":"decay","planned":1748.84815825613,"time":374.466666666651}
DIRECTOR {"alive":83,"curve":1715.83333333335,"damage":236.688702494303,"exclusive":false,"intensity":0.304166666666667,"issued":1711,"nearby":0,"pattern":"ring","phase":"decay","planned":1782.72917693853,"time":379.533333333317}
DIRECTOR {"alive":102,"curve":1756.36666666668,"damage":236.688702494303,"exclusive":false,"intensity":0.00416666666666667,"issued":1738,"nearby":0,"pattern":"ring","phase":"relax","planned":1813.91391468259,"time":384.599999999983}
DIRECTOR {"alive":69,"curve":1796.90000000001,"damage":236.688702494303,"exclusive":false,"intensity":0.05,"issued":1748,"nearby":0,"pattern":"ring","phase":"relax","planned":1824.40362728268,"time":389.66666666665}
DIRECTOR {"alive":34,"curve":1837.43333333335,"damage":236.688702494303,"exclusive":false,"intensity":0.0291666666666667,"issued":1760,"nearby":0,"pattern":"ring","phase":"relax","planned":1835.00292268934,"time":394.733333333316}
DIRECTOR {"alive":22,"curve":1877.96666666668,"damage":236.688702494303,"exclusive":false,"intensity":0.0,"issued":1773,"nearby":0,"pattern":"ring","phase":"relax","planned":1845.42688560549,"time":399.799999999982}
PICK lvl=18 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["ammo", "passive", "passive"]
DIRECTOR {"alive":2,"curve":1918.50000000001,"damage":236.688702494303,"exclusive":false,"intensity":0.05,"issued":1808,"nearby":0,"pattern":"flank","phase":"scout","planned":1879.02980511665,"time":404.866666666649}
DIRECTOR {"alive":0,"curve":1959.03333333334,"damage":236.688702494303,"exclusive":false,"intensity":0.0,"issued":1841,"nearby":0,"pattern":"flank","phase":"scout","planned":1913.90533482588,"time":409.933333333315}
DIRECTOR {"alive":10,"curve":1999.56666666667,"damage":236.688702494303,"exclusive":false,"intensity":0.05,"issued":1893,"nearby":0,"pattern":"flank","phase":"build","planned":1964.61879233395,"time":414.999999999982}
DIRECTOR {"alive":30,"curve":2040.1,"damage":236.688702494303,"exclusive":false,"intensity":0.05,"issued":1940,"nearby":0,"pattern":"flank","phase":"build","planned":2015.7896062123,"time":420.066666666648}
SIM 07:00 level=18 kills=1943 xp=2089/2445 credits=214/278 credits_left=134 zombies=30 kinds=26/0/1/3 elites=0 elites_spawned=4 crates=0 nades=6 dmg_taken=237 peak=112 fps=354 | Кольт L5 Крио2 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
ALARM_EVENT warn time=07:00
ALARM_EVENT start time=07:03
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
PICK lvl=19 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["passive", "ammo", "passive"]
DIRECTOR {"alive":49,"curve":2112.63333333333,"damage":236.688702494303,"exclusive":true,"intensity":0.05,"issued":2003,"nearby":0,"pattern":"flank","phase":"build","planned":2088.4599829506,"time":425.133333333314}
PICK lvl=20 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
DIRECTOR {"alive":38,"curve":2234.23333333332,"damage":236.688702494303,"exclusive":true,"intensity":0.0,"issued":2124,"nearby":0,"pattern":"flank","phase":"build","planned":2210.0599829506,"time":430.199999999981}
DIRECTOR {"alive":48,"curve":2355.83333333332,"damage":236.688702494303,"exclusive":true,"intensity":0.00833333333333333,"issued":2248,"nearby":0,"pattern":"flank","phase":"peak","planned":2331.65998295059,"time":435.266666666647}
DIRECTOR {"alive":10,"curve":2477.43333333331,"damage":236.688702494303,"exclusive":true,"intensity":0.05,"issued":2367,"nearby":0,"pattern":"flank","phase":"peak","planned":2453.25998295058,"time":440.333333333313}
DIRECTOR {"alive":34,"curve":2599.0333333333,"damage":236.688702494303,"exclusive":true,"intensity":0.0,"issued":2497,"nearby":0,"pattern":"flank","phase":"peak","planned":2574.85998295058,"time":445.39999999998}
DIRECTOR {"alive":9,"curve":2720.6333333333,"damage":236.688702494303,"exclusive":true,"intensity":0.0,"issued":2618,"nearby":0,"pattern":"flank","phase":"peak","planned":2696.45998295057,"time":450.466666666646}
ALARM_EVENT finish container=(2101.564, 199.0524) time=07:33
CONTAINER dropped pos=(2101.564, 199.0524) time=07:33
ALARM rewards mult=2 xp=2262 credits=298
CONTAINER picked time=07:33 crates=2
DIRECTOR {"alive":11,"curve":2806.23333333329,"damage":236.688702494303,"exclusive":false,"intensity":0.0333333333333333,"issued":2692,"nearby":0,"pattern":"tide","phase":"decay","planned":2777.96599306435,"time":455.533333333313}
DIRECTOR {"alive":7,"curve":2851.83333333328,"damage":236.688702494303,"exclusive":false,"intensity":0.05,"issued":2728,"nearby":0,"pattern":"tide","phase":"decay","planned":2814.93350823503,"time":460.599999999979}
PICK lvl=21 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "passive", "ammo"]
DIRECTOR {"alive":0,"curve":2897.43333333327,"damage":236.688702494303,"exclusive":false,"intensity":0.0,"issued":2756,"nearby":0,"pattern":"tide","phase":"relax","planned":2843.95908598471,"time":465.666666666645}
PICK lvl=22 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
PICK lvl=23 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
PICK lvl=24 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["passive", "ammo", "passive"]
DIRECTOR {"alive":12,"curve":2943.03333333327,"damage":236.688702494303,"exclusive":false,"intensity":0.0,"issued":2768,"nearby":0,"pattern":"tide","phase":"relax","planned":2855.48879521353,"time":470.733333333312}
DIRECTOR {"alive":8,"curve":2988.63333333326,"damage":236.688702494303,"exclusive":false,"intensity":0.0,"issued":2783,"nearby":0,"pattern":"tide","phase":"relax","planned":2867.11712896827,"time":475.799999999978}
PICK lvl=25 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["passive", "passive", "passive"]
SIM 08:00 level=25 kills=2828 xp=4121/4919 credits=501/608 credits_left=421 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=10 crates=2 nades=8 dmg_taken=237 peak=99 fps=239 | Кольт L5 Эксп3 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":1,"curve":3035.83333333325,"damage":236.688702494303,"exclusive":false,"intensity":0.0,"issued":2789,"nearby":0,"pattern":"column","phase":"scout","planned":2884.50652719836,"time":480.866666666645}
DIRECTOR {"alive":11,"curve":3091.56666666657,"damage":236.688702494303,"exclusive":false,"intensity":0.0,"issued":2843,"nearby":0,"pattern":"column","phase":"scout","planned":2932.48113360377,"time":485.933333333311}
DIRECTOR {"alive":5,"curve":3147.29999999989,"damage":236.688702494303,"exclusive":false,"intensity":0.05,"issued":2899,"nearby":0,"pattern":"column","phase":"build","planned":2984.60102488064,"time":490.999999999977}
PICK lvl=26 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
DIRECTOR {"alive":12,"curve":3203.0333333332,"damage":236.688702494303,"exclusive":false,"intensity":0.0,"issued":2969,"nearby":0,"pattern":"column","phase":"build","planned":3054.82945794708,"time":496.066666666644}
PICK lvl=27 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["passive", "passive", "ammo"]
DIRECTOR {"alive":5,"curve":3258.76666666652,"damage":279.200369160969,"exclusive":false,"intensity":0.329166666666667,"issued":3034,"nearby":0,"pattern":"column","phase":"build","planned":3124.62361931104,"time":501.13333333331}
DIRECTOR {"alive":7,"curve":3314.49999999984,"damage":364.390369160968,"exclusive":false,"intensity":0.3,"issued":3066,"nearby":0,"pattern":"column","phase":"build","planned":3192.34766341836,"time":506.199999999976}
DIRECTOR {"alive":82,"curve":3370.23333333316,"damage":364.390369160968,"exclusive":false,"intensity":0.0,"issued":3140,"nearby":0,"pattern":"column","phase":"build","planned":3261.27239329616,"time":511.266666666643}
DIRECTOR {"alive":51,"curve":3425.23333333314,"damage":364.390369160968,"exclusive":false,"intensity":0.025,"issued":3212,"nearby":0,"pattern":"column","phase":"peak","planned":3336.6010349242,"time":516.266666666646}
PICK lvl=28 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["ammo", "passive", "passive"]
DIRECTOR {"alive":17,"curve":3480.23333333312,"damage":378.163636906939,"exclusive":false,"intensity":0.3,"issued":3291,"nearby":0,"pattern":"column","phase":"peak","planned":3416.02860157683,"time":521.26666666665}
DIRECTOR {"alive":0,"curve":3535.23333333311,"damage":378.163636906939,"exclusive":false,"intensity":0.00833333333333333,"issued":3369,"nearby":0,"pattern":"column","phase":"peak","planned":3497.29662514054,"time":526.266666666654}
DIRECTOR {"alive":0,"curve":3590.23333333309,"damage":378.163636906939,"exclusive":false,"intensity":0.05,"issued":3449,"nearby":0,"pattern":"column","phase":"peak","planned":3580.38946433846,"time":531.266666666658}
DIRECTOR {"alive":1,"curve":3645.23333333308,"damage":378.163636906939,"exclusive":true,"intensity":0.0,"issued":3486,"nearby":0,"pattern":"column","phase":"decay","planned":3633.62847543552,"time":536.266666666662}
CALM 09:00 removed=24 left=0
TRADER 1 at 09:00 credits_left=315 bought=["ammo(60)", "passive(60)", "ammo(60)", "ammo(60)", "passive(60)"]
SIM 09:00 level=28 kills=3550 xp=5670/5919 credits=695/733 credits_left=315 zombies=24 kinds=12/8/3/1 elites=0 elites_spawned=12 crates=2 nades=10 dmg_taken=378 peak=93 fps=313 | Кольт L5 Зажи1 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":12,"curve":3690.63333333306,"damage":378.163636906939,"exclusive":true,"intensity":0.0,"issued":3544,"nearby":0,"pattern":"column","phase":"decay","planned":3679.0284754355,"time":541.266666666666}
DIRECTOR {"alive":10,"curve":3705.63333333305,"damage":378.163636906939,"exclusive":true,"intensity":0.0,"issued":3553,"nearby":0,"pattern":"column","phase":"relax","planned":3694.02847543549,"time":546.26666666667}
DIRECTOR {"alive":9,"curve":3720.63333333303,"damage":378.163636906939,"exclusive":true,"intensity":0.0,"issued":3572,"nearby":0,"pattern":"column","phase":"relax","planned":3709.02847543547,"time":551.266666666674}
DIRECTOR {"alive":0,"curve":3735.63333333302,"damage":378.163636906939,"exclusive":true,"intensity":0.0,"issued":3582,"nearby":0,"pattern":"column","phase":"relax","planned":3724.02847543546,"time":556.266666666678}
PICK lvl=29 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["ammo", "passive", "ammo"]
DIRECTOR {"alive":0,"curve":3750.63333333301,"damage":378.163636906939,"exclusive":true,"intensity":0.0,"issued":3597,"nearby":0,"pattern":"column","phase":"scout","planned":3739.02847543545,"time":561.266666666682}
DIRECTOR {"alive":2,"curve":3765.63333333299,"damage":378.163636906939,"exclusive":true,"intensity":0.0333333333333333,"issued":3616,"nearby":0,"pattern":"column","phase":"scout","planned":3754.02847543543,"time":566.266666666686}
DIRECTOR {"alive":0,"curve":3781.89999999965,"damage":378.163636906939,"exclusive":true,"intensity":0.0,"issued":3627,"nearby":0,"pattern":"column","phase":"build","planned":3770.29514210209,"time":571.26666666669}
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
DIRECTOR {"alive":0,"curve":3801.89999999967,"damage":378.163636906939,"exclusive":true,"intensity":0.0166666666666667,"issued":3650,"nearby":0,"pattern":"column","phase":"build","planned":3790.29514210211,"time":576.266666666694}
DIRECTOR {"alive":0,"curve":3821.89999999969,"damage":378.163636906939,"exclusive":true,"intensity":0.0,"issued":3664,"nearby":0,"pattern":"column","phase":"build","planned":3810.29514210213,"time":581.266666666698}
DIRECTOR {"alive":0,"curve":3841.8999999997,"damage":378.163636906939,"exclusive":true,"intensity":0.0458333333333333,"issued":3687,"nearby":0,"pattern":"column","phase":"build","planned":3830.29514210214,"time":586.266666666702}
DIRECTOR {"alive":1,"curve":3861.89999999972,"damage":378.163636906939,"exclusive":true,"intensity":0.0458333333333333,"issued":3709,"nearby":0,"pattern":"column","phase":"build","planned":3850.29514210216,"time":591.266666666706}
DIRECTOR {"alive":11,"curve":3881.89999999973,"damage":378.163636906939,"exclusive":true,"intensity":0.0,"issued":3733,"nearby":0,"pattern":"column","phase":"peak","planned":3870.29514210217,"time":596.26666666671}
BOSS spawn t=600.00 pos=(2401.604, 698.9465) hp=24000
SIM 10:00 level=29 kills=3759 xp=6092/6176 credits=741/763 credits_left=361 zombies=10 kinds=0/10/0/0 elites=0 elites_spawned=14 crates=2 nades=10 dmg_taken=378 peak=23 fps=447 | Кольт L5 Эксп1 [Сдво3,Рико3,Цепь3] | Бульдог L5 Эксп3 [Дето3,Спли3,Проб3] | ППШ L5 Крио3 [Проб3,Рико3,Спли3] | Мосинка L5 Стан3 [Спли3,Дето3,Сдво3]
SIM summary kills=3759 peak=112 level=29 damage=378.16 boss_alive=true
DIRECTOR summary curve=3896.83 planned=3885.23 issued=3750 dropped=81

EXIT_CODE=0
```

## hd1_fixed_full_control.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_fixed_full_control_engine.log --headless --fixed-fps 60 --path C:\Users\Dev\Desktop\zera-hd1 -- --sim=600 --fresh-save --layout-seed=81073 --director-trace=fixed_full --loadout --director-off
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=180.27 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
ACTIVITY event=start kind=carrier time=57.47 age=0.00 pos=(1384.0, 808.0) offered=1 success=0 failed=0 rewards=0
ACTIVITY event=success kind=carrier time=58.93 age=1.47 pos=(1384.0, 808.0) offered=1 success=1 failed=0 rewards=1
SIM 01:00 level=1 kills=85 xp=3/120 credits=0/3 credits_left=0 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=26 fps=709 | АК-С L5 Зажи3 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
PICK lvl=2 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
PICK lvl=3 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
PICK lvl=4 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
SIM 02:00 level=4 kills=255 xp=78/290 credits=3/9 credits_left=3 zombies=13 kinds=13/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=47 fps=669 | АК-С L5 Зажи3 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
ACTIVITY event=start kind=supply time=152.87 age=0.00 pos=(1138.974, 789.7661) offered=2 success=1 failed=0 rewards=1
ACTIVITY event=success kind=supply time=173.93 age=21.07 pos=(1138.974, 789.7661) offered=2 success=2 failed=0 rewards=2
PICK lvl=5 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["ammo", "ammo", "passive"]
SIM 03:00 level=5 kills=525 xp=90/560 credits=3/22 credits_left=3 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=71 fps=749 | АК-С L5 Стан1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
PICK lvl=6 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
PICK lvl=7 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["passive", "passive", "ammo"]
PICK lvl=8 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["passive", "ammo", "ammo"]
SIM 04:00 level=8 kills=797 xp=297/877 credits=8/50 credits_left=8 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=23 fps=678 | АК-С L5 Стан1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
TRADER 0 at 05:00 credits_left=8 bought=[]
SIM 05:00 level=8 kills=1155 xp=297/1304 credits=8/87 credits_left=8 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=20 fps=661 | АК-С L5 Стан1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
ACTIVITY event=start kind=fuel time=328.07 age=0.00 pos=(916.6993, 1086.703) offered=3 success=2 failed=0 rewards=2
ACTIVITY event=success kind=fuel time=340.27 age=12.20 pos=(916.6993, 1086.703) offered=3 success=3 failed=0 rewards=3
PICK lvl=9 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "passive", "ammo"]
PICK lvl=10 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
PICK lvl=11 { "type": "ammo", "id": 3, "rare": true } slot=0 of ["ammo", "ammo", "passive"]
PICK lvl=12 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "passive", "passive"]
PICK lvl=13 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["ammo", "passive", "ammo"]
PICK lvl=14 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["passive", "passive", "ammo"]
PICK lvl=15 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
PICK lvl=16 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
PICK lvl=17 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
SIM 06:00 level=17 kills=1486 xp=1652/1802 credits=154/178 credits_left=154 zombies=99 kinds=45/42/6/6 elites=0 elites_spawned=2 crates=0 nades=0 dmg_taken=60 peak=99 fps=505 | АК-С L5 Крио2 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
SIM 07:00 level=17 kills=1673 xp=1652/2021 credits=154/191 credits_left=154 zombies=350 kinds=188/83/44/35 elites=2 elites_spawned=4 crates=0 nades=0 dmg_taken=60 peak=350 fps=295 | АК-С L5 Крио2 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
ALARM_EVENT warn time=07:00
ALARM_EVENT start time=07:03
ALARM_EVENT finish container=(1416.98, 1363.435) time=07:33
CONTAINER dropped pos=(1416.98, 1363.435) time=07:33
ALARM rewards mult=2 xp=1984 credits=322
SIM 08:00 level=17 kills=2472 xp=1652/4207 credits=154/524 credits_left=154 zombies=289 kinds=195/29/46/19 elites=1 elites_spawned=9 crates=0 nades=0 dmg_taken=60 peak=500 fps=238 | АК-С L5 Крио2 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
CALM 09:00 removed=416 left=0
TRADER 1 at 09:00 credits_left=34 bought=["passive(60)", "ammo(60)"]
SIM 09:00 level=17 kills=2926 xp=1652/4875 credits=154/607 credits_left=34 zombies=416 kinds=239/94/46/37 elites=1 elites_spawned=11 crates=0 nades=0 dmg_taken=60 peak=500 fps=207 | АК-С L5 Эксп1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
BOSS spawn t=600.00 pos=(1290.98, 1363.432) hp=24000
SIM 10:00 level=17 kills=2926 xp=1652/4875 credits=154/607 credits_left=34 zombies=150 kinds=138/12/0/0 elites=2 elites_spawned=13 crates=0 nades=0 dmg_taken=60 peak=150 fps=540 | АК-С L5 Эксп1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
SIM summary kills=2926 peak=500 level=17 damage=60.00 boss_alive=true

EXIT_CODE=0
```

## hd1_fixed_full_after.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_fixed_full_after_engine.log --headless --fixed-fps 60 --path C:\Users\Dev\Desktop\zera-hd1 -- --sim=600 --fresh-save --layout-seed=81073 --director-trace=fixed_full --loadout
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=178.66 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
DIRECTOR {"alive":0,"curve":0.0,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":0,"nearby":0,"pattern":"column","phase":"scout","planned":0.0,"time":0.0666666666666667}
DIRECTOR {"alive":4,"curve":7.49999999999999,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":4,"nearby":0,"pattern":"tide","phase":"scout","planned":7.49999999999999,"time":5.06666666666667}
DIRECTOR {"alive":13,"curve":15.1,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":13,"nearby":0,"pattern":"tide","phase":"build","planned":15.1,"time":10.1333333333333}
DIRECTOR {"alive":15,"curve":22.7000000000001,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":19,"nearby":0,"pattern":"tide","phase":"build","planned":22.7000000000001,"time":15.2}
DIRECTOR {"alive":20,"curve":30.3000000000002,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":30,"nearby":0,"pattern":"tide","phase":"build","planned":30.3000000000002,"time":20.2666666666666}
DIRECTOR {"alive":13,"curve":37.9000000000003,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":36,"nearby":0,"pattern":"tide","phase":"build","planned":37.9000000000003,"time":25.3333333333333}
DIRECTOR {"alive":13,"curve":45.5000000000004,"damage":60.0,"exclusive":false,"intensity":0.320833333333333,"issued":44,"nearby":0,"pattern":"tide","phase":"build","planned":45.5000000000004,"time":30.3999999999999}
DIRECTOR {"alive":13,"curve":53.0000000000005,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":51,"nearby":0,"pattern":"tide","phase":"peak","planned":53.0000000000005,"time":35.4000000000001}
DIRECTOR {"alive":8,"curve":60.5000000000006,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":55,"nearby":0,"pattern":"tide","phase":"peak","planned":60.5000000000006,"time":40.4000000000003}
DIRECTOR {"alive":8,"curve":68.0000000000004,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":66,"nearby":0,"pattern":"tide","phase":"peak","planned":68.0000000000004,"time":45.4000000000006}
DIRECTOR {"alive":5,"curve":75.5,"damage":60.0,"exclusive":false,"intensity":0.0166666666666667,"issued":74,"nearby":0,"pattern":"tide","phase":"peak","planned":75.5,"time":50.4000000000008}
DIRECTOR {"alive":0,"curve":82.9999999999996,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":77,"nearby":0,"pattern":"tide","phase":"decay","planned":82.9999999999996,"time":55.4000000000011}
ACTIVITY event=start kind=carrier time=57.47 age=0.00 pos=(1384.0, 808.0) offered=1 success=0 failed=0 rewards=0
ACTIVITY event=success kind=carrier time=58.93 age=1.47 pos=(1384.0, 808.0) offered=1 success=1 failed=0 rewards=1
SIM 01:00 level=1 kills=84 xp=3/119 credits=0/4 credits_left=0 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=26 fps=656 | АК-С L5 Зажи3 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":0,"curve":91.0999999999992,"damage":60.0,"exclusive":false,"intensity":0.1,"issued":83,"nearby":0,"pattern":"column","phase":"decay","planned":90.8730227560043,"time":60.4000000000013}
PICK lvl=2 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["ammo", "ammo", "passive"]
DIRECTOR {"alive":0,"curve":106.099999999999,"damage":60.0,"exclusive":false,"intensity":0.1,"issued":88,"nearby":0,"pattern":"column","phase":"relax","planned":100.74114833544,"time":65.4000000000014}
PICK lvl=3 { "type": "ammo", "id": 0, "rare": true } slot=0 of ["ammo", "ammo", "ammo"]
PICK lvl=4 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "passive", "ammo"]
DIRECTOR {"alive":10,"curve":121.3,"damage":60.0,"exclusive":false,"intensity":0.1,"issued":98,"nearby":0,"pattern":"column","phase":"relax","planned":104.946008006742,"time":70.4666666666678}
DIRECTOR {"alive":10,"curve":136.499999999999,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":98,"nearby":0,"pattern":"column","phase":"relax","planned":109.183742520017,"time":75.5333333333342}
DIRECTOR {"alive":10,"curve":151.699999999998,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":98,"nearby":0,"pattern":"ambush","phase":"scout","planned":114.119267172356,"time":80.6000000000005}
DIRECTOR {"alive":30,"curve":166.899999999998,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":118,"nearby":0,"pattern":"ambush","phase":"scout","planned":127.186270965023,"time":85.6666666666669}
DIRECTOR {"alive":23,"curve":182.099999999997,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":131,"nearby":0,"pattern":"ambush","phase":"build","planned":141.14946186262,"time":90.7333333333333}
DIRECTOR {"alive":9,"curve":197.299999999996,"damage":60.0,"exclusive":false,"intensity":0.05,"issued":153,"nearby":0,"pattern":"ambush","phase":"build","planned":160.338517067003,"time":95.7999999999997}
DIRECTOR {"alive":6,"curve":212.499999999995,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":174,"nearby":0,"pattern":"ambush","phase":"build","planned":179.52854108723,"time":100.866666666666}
DIRECTOR {"alive":11,"curve":227.699999999994,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":193,"nearby":0,"pattern":"ambush","phase":"build","planned":198.731159713441,"time":105.933333333332}
DIRECTOR {"alive":0,"curve":242.899999999993,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":206,"nearby":0,"pattern":"ambush","phase":"build","planned":217.925058997049,"time":110.999999999999}
DIRECTOR {"alive":0,"curve":258.099999999992,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":221,"nearby":0,"pattern":"ambush","phase":"peak","planned":238.643900969235,"time":116.066666666665}
SIM 02:00 level=4 kills=251 xp=71/286 credits=5/13 credits_left=5 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=30 fps=695 | АК-С L5 Стан1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":0,"curve":274.366666666658,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":250,"nearby":0,"pattern":"ambush","phase":"peak","planned":263.268438685207,"time":121.133333333332}
DIRECTOR {"alive":8,"curve":294.633333333324,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":281,"nearby":0,"pattern":"ambush","phase":"peak","planned":293.956188650089,"time":126.199999999998}
DIRECTOR {"alive":13,"curve":314.899999999989,"damage":60.0,"exclusive":false,"intensity":0.05,"issued":317,"nearby":0,"pattern":"ambush","phase":"peak","planned":324.626243433064,"time":131.266666666664}
DIRECTOR {"alive":0,"curve":335.166666666655,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":323,"nearby":0,"pattern":"ambush","phase":"decay","planned":343.264803905042,"time":136.333333333331}
DIRECTOR {"alive":0,"curve":355.43333333332,"damage":60.0,"exclusive":false,"intensity":0.05,"issued":345,"nearby":0,"pattern":"ambush","phase":"decay","planned":359.662612586039,"time":141.399999999997}
DIRECTOR {"alive":20,"curve":375.699999999986,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":365,"nearby":0,"pattern":"ambush","phase":"relax","planned":370.731544739431,"time":146.466666666663}
DIRECTOR {"alive":0,"curve":395.966666666651,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":365,"nearby":0,"pattern":"ambush","phase":"relax","planned":375.914304115747,"time":151.53333333333}
ACTIVITY event=start kind=supply time=152.87 age=0.00 pos=(1138.974, 783.2675) offered=2 success=1 failed=0 rewards=1
DIRECTOR {"alive":16,"curve":416.233333333317,"damage":60.0,"exclusive":true,"intensity":0.0,"issued":375,"nearby":0,"pattern":"ambush","phase":"relax","planned":391.996899985952,"time":156.599999999996}
DIRECTOR {"alive":30,"curve":436.499999999982,"damage":60.0,"exclusive":true,"intensity":0.0,"issued":389,"nearby":0,"pattern":"ambush","phase":"scout","planned":412.263566652618,"time":161.666666666663}
DIRECTOR {"alive":66,"curve":456.766666666648,"damage":60.0,"exclusive":true,"intensity":0.0,"issued":419,"nearby":0,"pattern":"ambush","phase":"scout","planned":432.530233319283,"time":166.733333333329}
DIRECTOR {"alive":31,"curve":477.033333333313,"damage":60.0,"exclusive":true,"intensity":0.0,"issued":438,"nearby":0,"pattern":"ambush","phase":"build","planned":452.796899985949,"time":171.799999999995}
ACTIVITY event=success kind=supply time=174.07 age=21.20 pos=(1138.974, 783.2675) offered=2 success=2 failed=0 rewards=2
DIRECTOR {"alive":1,"curve":497.299999999979,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":438,"nearby":0,"pattern":"rush","phase":"build","planned":475.948524090457,"time":176.866666666662}
PICK lvl=5 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
SIM 03:00 level=5 kills=465 xp=87/500 credits=8/27 credits_left=8 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=66 fps=491 | АК-С L5 Стан1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":0,"curve":517.566666666644,"damage":60.0,"exclusive":false,"intensity":0.0291666666666667,"issued":463,"nearby":0,"pattern":"rush","phase":"build","planned":501.545556819774,"time":181.933333333328}
PICK lvl=6 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["ammo", "passive", "ammo"]
PICK lvl=7 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["passive", "ammo", "ammo"]
DIRECTOR {"alive":0,"curve":537.83333333331,"damage":60.0,"exclusive":false,"intensity":0.1,"issued":470,"nearby":0,"pattern":"rush","phase":"build","planned":526.913626071074,"time":186.999999999995}
PICK lvl=8 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
DIRECTOR {"alive":0,"curve":558.099999999975,"damage":60.0,"exclusive":false,"intensity":0.1,"issued":483,"nearby":0,"pattern":"rush","phase":"build","planned":552.380191599939,"time":192.066666666661}
PICK lvl=9 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
DIRECTOR {"alive":0,"curve":578.366666666641,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":505,"nearby":0,"pattern":"rush","phase":"peak","planned":580.973403567912,"time":197.133333333327}
DIRECTOR {"alive":0,"curve":598.633333333306,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":505,"nearby":0,"pattern":"rush","phase":"peak","planned":611.597956454553,"time":202.199999999994}
DIRECTOR {"alive":0,"curve":618.899999999972,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":505,"nearby":0,"pattern":"rush","phase":"peak","planned":642.283178536305,"time":207.26666666666}
PICK lvl=10 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["passive", "passive", "ammo"]
DIRECTOR {"alive":8,"curve":641.433333333306,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":513,"nearby":0,"pattern":"rush","phase":"decay","planned":675.523802219408,"time":212.333333333326}
DIRECTOR {"alive":17,"curve":666.766666666642,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":530,"nearby":0,"pattern":"rush","phase":"decay","planned":696.030395842111,"time":217.399999999993}
DIRECTOR {"alive":12,"curve":692.099999999978,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":551,"nearby":0,"pattern":"rush","phase":"decay","planned":716.547488832702,"time":222.466666666659}
DIRECTOR {"alive":0,"curve":717.433333333315,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":563,"nearby":0,"pattern":"rush","phase":"relax","planned":727.457737463131,"time":227.533333333326}
DIRECTOR {"alive":8,"curve":742.766666666651,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":571,"nearby":0,"pattern":"rush","phase":"relax","planned":733.863131479148,"time":232.599999999992}
DIRECTOR {"alive":0,"curve":768.099999999987,"damage":60.0,"exclusive":false,"intensity":0.05,"issued":576,"nearby":0,"pattern":"rush","phase":"relax","planned":740.295921196808,"time":237.666666666658}
SIM 04:00 level=10 kills=595 xp=493/648 credits=32/43 credits_left=32 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=26 fps=450 | АК-С L5 Зажи1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":16,"curve":796.099999999987,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":592,"nearby":0,"pattern":"column","phase":"scout","planned":757.112191740427,"time":242.733333333325}
DIRECTOR {"alive":12,"curve":826.499999999986,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":611,"nearby":0,"pattern":"column","phase":"scout","planned":783.259577328292,"time":247.799999999991}
DIRECTOR {"alive":28,"curve":856.899999999984,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":652,"nearby":0,"pattern":"column","phase":"build","planned":816.202394016032,"time":252.866666666657}
DIRECTOR {"alive":21,"curve":887.299999999982,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":688,"nearby":0,"pattern":"column","phase":"build","planned":854.609568900148,"time":257.933333333324}
DIRECTOR {"alive":0,"curve":917.69999999998,"damage":60.0,"exclusive":false,"intensity":0.05,"issued":725,"nearby":0,"pattern":"column","phase":"build","planned":893.022556679334,"time":262.99999999999}
DIRECTOR {"alive":42,"curve":948.099999999979,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":767,"nearby":0,"pattern":"column","phase":"build","planned":931.43166919514,"time":268.066666666657}
DIRECTOR {"alive":31,"curve":978.499999999977,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":804,"nearby":0,"pattern":"column","phase":"build","planned":969.840781710947,"time":273.133333333323}
DIRECTOR {"alive":26,"curve":1008.89999999998,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":852,"nearby":0,"pattern":"column","phase":"peak","planned":1014.49818752637,"time":278.199999999989}
DIRECTOR {"alive":14,"curve":1039.29999999998,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":893,"nearby":0,"pattern":"column","phase":"peak","planned":1060.56773072064,"time":283.266666666656}
DIRECTOR {"alive":11,"curve":1069.69999999998,"damage":60.0,"exclusive":true,"intensity":0.0,"issued":922,"nearby":0,"pattern":"column","phase":"peak","planned":1096.55205436161,"time":288.333333333322}
DIRECTOR {"alive":17,"curve":1100.09999999999,"damage":60.0,"exclusive":true,"intensity":0.0,"issued":954,"nearby":0,"pattern":"column","phase":"decay","planned":1126.95205436162,"time":293.399999999988}
DIRECTOR {"alive":10,"curve":1130.5,"damage":60.0,"exclusive":true,"intensity":0.0,"issued":984,"nearby":0,"pattern":"column","phase":"decay","planned":1157.35205436163,"time":298.466666666655}
TRADER 0 at 05:00 credits_left=32 bought=[]
SIM 05:00 level=10 kills=993 xp=493/1169 credits=32/97 credits_left=32 zombies=18 kinds=17/0/1/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=53 fps=493 | АК-С L5 Зажи1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":3,"curve":1164.36666666667,"damage":60.0,"exclusive":true,"intensity":0.0,"issued":1013,"nearby":0,"pattern":"column","phase":"decay","planned":1191.2187210283,"time":303.533333333321}
DIRECTOR {"alive":41,"curve":1199.83333333334,"damage":60.0,"exclusive":true,"intensity":0.0,"issued":1051,"nearby":0,"pattern":"column","phase":"relax","planned":1226.68538769497,"time":308.599999999988}
DIRECTOR {"alive":26,"curve":1235.30000000001,"damage":60.0,"exclusive":true,"intensity":0.0,"issued":1089,"nearby":0,"pattern":"column","phase":"relax","planned":1262.15205436164,"time":313.666666666654}
DIRECTOR {"alive":0,"curve":1270.76666666668,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":1101,"nearby":0,"pattern":"ambush","phase":"relax","planned":1278.51843784246,"time":318.73333333332}
DIRECTOR {"alive":9,"curve":1306.23333333334,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":1128,"nearby":0,"pattern":"ring","phase":"scout","planned":1303.35880362417,"time":323.799999999987}
ACTIVITY event=start kind=fuel time=328.07 age=0.00 pos=(916.6993, 952.1053) offered=3 success=2 failed=0 rewards=2
DIRECTOR {"alive":1,"curve":1341.70000000001,"damage":60.0,"exclusive":true,"intensity":0.0,"issued":1150,"nearby":0,"pattern":"ring","phase":"scout","planned":1334.57063400765,"time":328.866666666653}
DIRECTOR {"alive":5,"curve":1377.16666666668,"damage":60.0,"exclusive":true,"intensity":0.05,"issued":1185,"nearby":0,"pattern":"ring","phase":"build","planned":1370.03730067432,"time":333.93333333332}
DIRECTOR {"alive":37,"curve":1412.63333333335,"damage":60.0,"exclusive":true,"intensity":0.0,"issued":1221,"nearby":0,"pattern":"ring","phase":"build","planned":1405.50396734099,"time":338.999999999986}
ACTIVITY event=success kind=fuel time=341.00 age=12.93 pos=(916.6993, 952.1053) offered=3 success=3 failed=0 rewards=3
DIRECTOR {"alive":0,"curve":1448.10000000002,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":1232,"nearby":0,"pattern":"column","phase":"build","planned":1446.46505288671,"time":344.066666666652}
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
DIRECTOR {"alive":0,"curve":1483.56666666669,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":1279,"nearby":0,"pattern":"column","phase":"build","planned":1491.23951503027,"time":349.133333333319}
PICK lvl=11 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["passive", "passive", "passive"]
PICK lvl=12 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "passive", "passive"]
PICK lvl=13 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["ammo", "ammo", "passive"]
DIRECTOR {"alive":0,"curve":1519.03333333336,"damage":60.0,"exclusive":false,"intensity":0.1,"issued":1314,"nearby":0,"pattern":"column","phase":"peak","planned":1535.94252781297,"time":354.199999999985}
DIRECTOR {"alive":42,"curve":1554.50000000003,"damage":60.0,"exclusive":false,"intensity":0.1,"issued":1379,"nearby":0,"pattern":"column","phase":"peak","planned":1589.42932427314,"time":359.266666666651}
SIM 06:00 level=13 kills=1368 xp=908/1724 credits=98/198 credits_left=98 zombies=42 kinds=40/0/1/1 elites=0 elites_spawned=2 crates=0 nades=0 dmg_taken=60 peak=53 fps=483 | АК-С L5 Крио1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":103,"curve":1594.23333333336,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":1439,"nearby":0,"pattern":"column","phase":"peak","planned":1649.65436767811,"time":364.333333333318}
DIRECTOR {"alive":165,"curve":1634.76666666669,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":1501,"nearby":0,"pattern":"column","phase":"peak","planned":1711.14615023184,"time":369.399999999984}
DIRECTOR {"alive":17,"curve":1675.30000000002,"damage":60.0,"exclusive":false,"intensity":0.05,"issued":1549,"nearby":0,"pattern":"column","phase":"decay","planned":1758.99086999585,"time":374.466666666651}
DIRECTOR {"alive":10,"curve":1715.83333333335,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":1578,"nearby":0,"pattern":"column","phase":"decay","planned":1791.87608196383,"time":379.533333333317}
DIRECTOR {"alive":0,"curve":1756.36666666668,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":1607,"nearby":0,"pattern":"column","phase":"relax","planned":1822.3747003091,"time":384.599999999983}
DIRECTOR {"alive":0,"curve":1796.90000000001,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":1617,"nearby":0,"pattern":"column","phase":"relax","planned":1832.69638593911,"time":389.66666666665}
DIRECTOR {"alive":0,"curve":1837.43333333335,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":1627,"nearby":0,"pattern":"column","phase":"relax","planned":1843.02537708956,"time":394.733333333316}
DIRECTOR {"alive":0,"curve":1877.96666666668,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":1639,"nearby":0,"pattern":"column","phase":"relax","planned":1853.36167376045,"time":399.799999999982}
DIRECTOR {"alive":0,"curve":1918.50000000001,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":1668,"nearby":0,"pattern":"flank","phase":"scout","planned":1886.94950014055,"time":404.866666666649}
DIRECTOR {"alive":13,"curve":1959.03333333334,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":1711,"nearby":0,"pattern":"flank","phase":"scout","planned":1921.83189036389,"time":409.933333333315}
DIRECTOR {"alive":8,"curve":1999.56666666667,"damage":60.0,"exclusive":false,"intensity":0.0,"issued":1755,"nearby":0,"pattern":"flank","phase":"build","planned":1972.52467980061,"time":414.999999999982}
DIRECTOR {"alive":1,"curve":2040.1,"damage":74.3141040802002,"exclusive":false,"intensity":0.3125,"issued":1805,"nearby":0,"pattern":"flank","phase":"build","planned":2023.38418085413,"time":420.066666666648}
SIM 07:00 level=13 kills=1837 xp=1023/2392 credits=101/293 credits_left=101 zombies=1 kinds=0/0/1/0 elites=0 elites_spawned=4 crates=0 nades=0 dmg_taken=74 peak=165 fps=274 | АК-С L5 Крио1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
ALARM_EVENT warn time=07:00
ALARM_EVENT start time=07:03
DIRECTOR {"alive":0,"curve":2112.63333333333,"damage":74.3141040802002,"exclusive":true,"intensity":0.15,"issued":1867,"nearby":0,"pattern":"flank","phase":"build","planned":2096.03421245968,"time":425.133333333314}
PICK lvl=14 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["ammo", "ammo", "passive"]
PICK lvl=15 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["passive", "ammo", "ammo"]
PICK lvl=16 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["ammo", "passive", "passive"]
PICK lvl=17 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["ammo", "passive", "ammo"]
PICK lvl=18 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
PICK lvl=19 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["ammo", "passive", "ammo"]
DIRECTOR {"alive":84,"curve":2234.23333333332,"damage":74.3141040802002,"exclusive":true,"intensity":0.1,"issued":1996,"nearby":0,"pattern":"flank","phase":"build","planned":2217.63421245968,"time":430.199999999981}
PICK lvl=20 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["passive", "ammo", "ammo"]
DIRECTOR {"alive":206,"curve":2355.83333333332,"damage":74.3141040802002,"exclusive":true,"intensity":0.1,"issued":2118,"nearby":0,"pattern":"flank","phase":"peak","planned":2339.23421245967,"time":435.266666666647}
DIRECTOR {"alive":292,"curve":2477.43333333331,"damage":74.3141040802002,"exclusive":true,"intensity":0.1,"issued":2241,"nearby":0,"pattern":"flank","phase":"peak","planned":2460.83421245966,"time":440.333333333313}
DIRECTOR {"alive":165,"curve":2599.0333333333,"damage":74.3141040802002,"exclusive":true,"intensity":0.025,"issued":2353,"nearby":0,"pattern":"flank","phase":"peak","planned":2582.43421245966,"time":445.39999999998}
PICK lvl=21 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
DIRECTOR {"alive":200,"curve":2720.6333333333,"damage":74.3141040802002,"exclusive":true,"intensity":0.0,"issued":2478,"nearby":0,"pattern":"flank","phase":"peak","planned":2704.03421245965,"time":450.466666666646}
ALARM_EVENT finish container=(1500.849, 1298.733) time=07:33
CONTAINER dropped pos=(1500.849, 1298.733) time=07:33
ALARM rewards mult=2 xp=1470 credits=208
CONTAINER picked time=07:34 crates=2
DIRECTOR {"alive":49,"curve":2806.23333333329,"damage":74.3141040802002,"exclusive":false,"intensity":0.0,"issued":2560,"nearby":0,"pattern":"tide","phase":"decay","planned":2785.6179178958,"time":455.533333333313}
PICK lvl=22 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "passive", "passive"]
DIRECTOR {"alive":85,"curve":2851.83333333328,"damage":74.3141040802002,"exclusive":false,"intensity":0.1,"issued":2597,"nearby":0,"pattern":"tide","phase":"decay","planned":2822.59068275042,"time":460.599999999979}
DIRECTOR {"alive":94,"curve":2897.43333333327,"damage":74.3141040802002,"exclusive":false,"intensity":0.0,"issued":2623,"nearby":0,"pattern":"tide","phase":"relax","planned":2852.08689640403,"time":465.666666666645}
DIRECTOR {"alive":72,"curve":2943.03333333327,"damage":74.3141040802002,"exclusive":false,"intensity":0.0,"issued":2636,"nearby":0,"pattern":"tide","phase":"relax","planned":2863.87138565814,"time":470.733333333312}
DIRECTOR {"alive":27,"curve":2988.63333333326,"damage":74.3141040802002,"exclusive":false,"intensity":0.0,"issued":2651,"nearby":0,"pattern":"tide","phase":"relax","planned":2875.63121878076,"time":475.799999999978}
SIM 08:00 level=22 kills=2685 xp=3314/4387 credits=459/561 credits_left=459 zombies=15 kinds=12/0/1/2 elites=0 elites_spawned=10 crates=2 nades=3 dmg_taken=74 peak=315 fps=207 | АК-С L5 Зажи1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":23,"curve":3035.83333333325,"damage":74.3141040802002,"exclusive":false,"intensity":0.0,"issued":2668,"nearby":0,"pattern":"column","phase":"scout","planned":2893.08003462568,"time":480.866666666645}
DIRECTOR {"alive":28,"curve":3091.56666666657,"damage":74.3141040802002,"exclusive":false,"intensity":0.1,"issued":2714,"nearby":0,"pattern":"column","phase":"scout","planned":2941.12444676223,"time":485.933333333311}
DIRECTOR {"alive":81,"curve":3147.29999999989,"damage":74.3141040802002,"exclusive":false,"intensity":0.1,"issued":2767,"nearby":0,"pattern":"column","phase":"build","planned":2993.39190398938,"time":490.999999999977}
DIRECTOR {"alive":77,"curve":3203.0333333332,"damage":74.3141040802002,"exclusive":false,"intensity":0.1,"issued":2833,"nearby":0,"pattern":"column","phase":"build","planned":3062.91342442764,"time":496.066666666644}
DIRECTOR {"alive":151,"curve":3258.76666666652,"damage":74.3141040802002,"exclusive":false,"intensity":0.1,"issued":2907,"nearby":0,"pattern":"column","phase":"build","planned":3132.56282855744,"time":501.13333333331}
DIRECTOR {"alive":56,"curve":3314.49999999984,"damage":74.3141040802002,"exclusive":false,"intensity":0.1,"issued":2978,"nearby":0,"pattern":"column","phase":"build","planned":3202.10921526905,"time":506.199999999976}
DIRECTOR {"alive":10,"curve":3370.23333333316,"damage":74.3141040802002,"exclusive":false,"intensity":0.1125,"issued":3039,"nearby":0,"pattern":"column","phase":"build","planned":3271.70711068976,"time":511.266666666643}
DIRECTOR {"alive":93,"curve":3425.23333333314,"damage":74.3141040802002,"exclusive":false,"intensity":0.1,"issued":3122,"nearby":0,"pattern":"column","phase":"peak","planned":3346.20994303981,"time":516.266666666646}
DIRECTOR {"alive":172,"curve":3480.23333333312,"damage":74.3141040802002,"exclusive":false,"intensity":0.1,"issued":3201,"nearby":0,"pattern":"column","phase":"peak","planned":3428.08450056192,"time":521.26666666665}
PICK lvl=23 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["passive", "passive", "passive"]
DIRECTOR {"alive":25,"curve":3535.23333333311,"damage":74.3141040802002,"exclusive":false,"intensity":0.0,"issued":3276,"nearby":0,"pattern":"column","phase":"peak","planned":3509.69489429699,"time":526.266666666654}
PICK lvl=24 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
DIRECTOR {"alive":26,"curve":3590.23333333309,"damage":74.3141040802002,"exclusive":false,"intensity":0.0,"issued":3370,"nearby":0,"pattern":"column","phase":"peak","planned":3592.84160900411,"time":531.266666666658}
PICK lvl=25 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
DIRECTOR {"alive":0,"curve":3645.23333333308,"damage":74.3141040802002,"exclusive":true,"intensity":0.0,"issued":3418,"nearby":0,"pattern":"column","phase":"decay","planned":3646.12072610271,"time":536.266666666662}
PICK lvl=26 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["ammo", "passive", "passive"]
CALM 09:00 removed=8 left=0
TRADER 1 at 09:00 credits_left=187 bought=["passive(60)", "passive(60)", "ammo(150)", "passive(60)", "passive(60)"]
SIM 09:00 level=26 kills=3494 xp=4517/5510 credits=577/728 credits_left=187 zombies=8 kinds=0/8/0/0 elites=0 elites_spawned=12 crates=2 nades=3 dmg_taken=74 peak=186 fps=263 | АК-С L5 Стан1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":1,"curve":3690.63333333306,"damage":74.3141040802002,"exclusive":true,"intensity":0.0,"issued":3461,"nearby":0,"pattern":"column","phase":"decay","planned":3691.52072610269,"time":541.266666666666}
PICK lvl=27 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
DIRECTOR {"alive":0,"curve":3705.63333333305,"damage":74.3141040802002,"exclusive":true,"intensity":0.0,"issued":3470,"nearby":0,"pattern":"column","phase":"relax","planned":3706.52072610268,"time":546.26666666667}
DIRECTOR {"alive":0,"curve":3720.63333333303,"damage":74.3141040802002,"exclusive":true,"intensity":0.0,"issued":3485,"nearby":0,"pattern":"column","phase":"relax","planned":3721.52072610267,"time":551.266666666674}
DIRECTOR {"alive":14,"curve":3735.63333333302,"damage":74.3141040802002,"exclusive":true,"intensity":0.0,"issued":3511,"nearby":0,"pattern":"column","phase":"relax","planned":3736.52072610265,"time":556.266666666678}
DIRECTOR {"alive":8,"curve":3750.63333333301,"damage":74.3141040802002,"exclusive":true,"intensity":0.0,"issued":3519,"nearby":0,"pattern":"column","phase":"scout","planned":3751.52072610264,"time":561.266666666682}
DIRECTOR {"alive":15,"curve":3765.63333333299,"damage":74.3141040802002,"exclusive":true,"intensity":0.0,"issued":3534,"nearby":0,"pattern":"column","phase":"scout","planned":3766.52072610263,"time":566.266666666686}
DIRECTOR {"alive":33,"curve":3781.89999999965,"damage":74.3141040802002,"exclusive":true,"intensity":0.0,"issued":3551,"nearby":0,"pattern":"column","phase":"build","planned":3782.78739276929,"time":571.26666666669}
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
DIRECTOR {"alive":40,"curve":3801.89999999967,"damage":74.3141040802002,"exclusive":true,"intensity":0.0,"issued":3576,"nearby":0,"pattern":"column","phase":"build","planned":3802.7873927693,"time":576.266666666694}
DIRECTOR {"alive":51,"curve":3821.89999999969,"damage":74.3141040802002,"exclusive":true,"intensity":0.0,"issued":3587,"nearby":0,"pattern":"column","phase":"build","planned":3822.78739276932,"time":581.266666666698}
PICK lvl=28 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["ammo", "passive", "ammo"]
DIRECTOR {"alive":29,"curve":3841.8999999997,"damage":74.3141040802002,"exclusive":true,"intensity":0.0,"issued":3613,"nearby":0,"pattern":"column","phase":"build","planned":3842.78739276933,"time":586.266666666702}
DIRECTOR {"alive":11,"curve":3861.89999999972,"damage":74.3141040802002,"exclusive":true,"intensity":0.05,"issued":3632,"nearby":0,"pattern":"column","phase":"build","planned":3862.78739276935,"time":591.266666666706}
DIRECTOR {"alive":4,"curve":3881.89999999973,"damage":74.3141040802002,"exclusive":true,"intensity":0.0,"issued":3654,"nearby":0,"pattern":"column","phase":"peak","planned":3882.78739276937,"time":596.26666666671}
BOSS spawn t=600.00 pos=(2008.0, 1016.0) hp=24000
SIM 10:00 level=28 kills=3686 xp=5602/5750 credits=727/760 credits_left=337 zombies=18 kinds=18/0/0/0 elites=0 elites_spawned=14 crates=2 nades=4 dmg_taken=74 peak=66 fps=561 | АК-С L5 Стан3 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
SIM summary kills=3686 peak=315 level=28 damage=74.31 boss_alive=true
DIRECTOR summary curve=3896.83 planned=3897.72 issued=3669 dropped=160

EXIT_CODE=0
```

## hd1_mortal_fixed_starter_control.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_mortal_fixed_starter_control_engine.log --headless --fixed-fps 60 --path C:\Users\Dev\Desktop\zera-hd1 -- --sim=600 --mortal --fresh-save --layout-seed=81073 --director-trace=mortal_fixed_starter --director-off
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=177.33 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
PICK lvl=2 { "type": "module", "id": 4, "rare": false } slot=0 of ["weapon", "module", "module"]
PICK lvl=3 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "module", "weapon"]
ACTIVITY event=start kind=carrier time=57.47 age=0.00 pos=(1448.0, 936.0) offered=1 success=0 failed=0 rewards=0
SIM 01:00 level=3 kills=60 xp=35/60 credits=1/4 credits_left=1 zombies=29 kinds=28/1/0/0 elites=0 elites_spawned=0 crates=0 nades=1 dmg_taken=0 peak=34 fps=235 | АК-С L2 Стан1 [Сдво1]
PICK lvl=4 { "type": "weapon", "id": 4, "rare": false } slot=-1 of ["weapon", "level", "weapon"]
ACTIVITY event=success kind=carrier time=62.47 age=5.00 pos=(1448.111, 788.2974) offered=1 success=1 failed=0 rewards=1
PICK lvl=5 { "type": "weapon", "id": 1, "rare": false } slot=-1 of ["weapon", "passive", "ammo"]
PICK lvl=6 { "type": "weapon", "id": 6, "rare": false } slot=-1 of ["level", "level", "weapon"]
SIM 02:00 level=6 kills=246 xp=181/281 credits=7/19 credits_left=7 zombies=15 kinds=15/0/0/0 elites=0 elites_spawned=0 crates=0 nades=3 dmg_taken=40 peak=57 fps=553 | АК-С L2 Стан1 [Сдво1] | Кольт L1 Стан1 [] | Мясник L1 Стан1 [] | ППШ L1 Стан1 []
ACTIVITY event=start kind=supply time=152.87 age=0.00 pos=(2244.024, 563.1326) offered=2 success=1 failed=0 rewards=1
PICK lvl=7 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "level", "level"]
PICK lvl=8 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "level", "passive"]
PICK lvl=9 { "type": "module", "id": 4, "rare": false } slot=0 of ["level", "module", "module"]
ACTIVITY event=success kind=supply time=177.40 age=24.53 pos=(2244.024, 563.1326) offered=2 success=2 failed=0 rewards=2
LOOT СНАБЖЕНИЕ: module slot=1 rare=true
SIM 03:00 level=9 kills=507 xp=395/542 credits=20/33 credits_left=20 zombies=14 kinds=14/0/0/0 elites=0 elites_spawned=0 crates=0 nades=5 dmg_taken=40 peak=36 fps=640 | АК-С L2 Стан1 [Сдво2] | Кольт L2 Стан1 [Дето1] | Мясник L1 Стан1 [] | ППШ L2 Стан1 []
PICK lvl=10 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["ammo", "level", "module"]
SIM 04:00 level=10 kills=768 xp=519/833 credits=27/52 credits_left=27 zombies=28 kinds=23/0/5/0 elites=0 elites_spawned=0 crates=0 nades=6 dmg_taken=40 peak=47 fps=615 | АК-С L2 Стан1 [Сдво2] | Кольт L3 Стан1 [Дето1] | Мясник L1 Стан1 [] | ППШ L2 Стан1 []
TRADER 0 at 05:00 credits_left=27 bought=[]
SIM 05:00 level=10 kills=1119 xp=519/1301 credits=27/100 credits_left=27 zombies=33 kinds=27/0/6/0 elites=0 elites_spawned=0 crates=0 nades=6 dmg_taken=40 peak=58 fps=323 | АК-С L2 Стан1 [Сдво2] | Кольт L3 Стан1 [Дето1] | Мясник L1 Стан1 [] | ППШ L2 Стан1 []
MISSION_RESULT outcome=defeat time=337.07 kills=1387 peak=58 level=10 damage=144.48

EXIT_CODE=0
```

## hd1_mortal_fixed_starter_after.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_mortal_fixed_starter_after_engine.log --headless --fixed-fps 60 --path C:\Users\Dev\Desktop\zera-hd1 -- --sim=600 --mortal --fresh-save --layout-seed=81073 --director-trace=mortal_fixed_starter
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=179.74 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
DIRECTOR {"alive":0,"curve":0.0,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":0,"nearby":0,"pattern":"column","phase":"scout","planned":0.0,"time":0.0666666666666667}
DIRECTOR {"alive":4,"curve":7.49999999999999,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":4,"nearby":0,"pattern":"tide","phase":"scout","planned":7.49999999999999,"time":5.06666666666667}
DIRECTOR {"alive":13,"curve":15.1,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":13,"nearby":0,"pattern":"tide","phase":"build","planned":15.1,"time":10.1333333333333}
DIRECTOR {"alive":19,"curve":22.7000000000001,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":19,"nearby":0,"pattern":"tide","phase":"build","planned":22.7000000000001,"time":15.2}
DIRECTOR {"alive":29,"curve":30.3000000000002,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":29,"nearby":0,"pattern":"tide","phase":"build","planned":30.3000000000002,"time":20.2666666666666}
DIRECTOR {"alive":27,"curve":37.9000000000003,"damage":0.0,"exclusive":false,"intensity":0.00416666666666667,"issued":32,"nearby":0,"pattern":"tide","phase":"build","planned":37.9000000000003,"time":25.3333333333333}
DIRECTOR {"alive":31,"curve":45.5000000000004,"damage":0.0,"exclusive":false,"intensity":0.00416666666666667,"issued":44,"nearby":0,"pattern":"tide","phase":"build","planned":45.5000000000004,"time":30.3999999999999}
PICK lvl=2 { "type": "weapon", "id": 1, "rare": false } slot=-1 of ["weapon", "passive", "module"]
DIRECTOR {"alive":25,"curve":53.0000000000005,"damage":0.0,"exclusive":false,"intensity":0.00416666666666667,"issued":49,"nearby":0,"pattern":"tide","phase":"peak","planned":53.0000000000005,"time":35.4000000000001}
DIRECTOR {"alive":22,"curve":60.5000000000006,"damage":0.0,"exclusive":false,"intensity":0.00833333333333333,"issued":57,"nearby":0,"pattern":"tide","phase":"peak","planned":60.5000000000006,"time":40.4000000000003}
PICK lvl=3 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["level", "weapon", "passive"]
DIRECTOR {"alive":23,"curve":68.0000000000004,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":67,"nearby":0,"pattern":"tide","phase":"peak","planned":68.0000000000004,"time":45.4000000000006}
DIRECTOR {"alive":19,"curve":75.5,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":72,"nearby":0,"pattern":"tide","phase":"peak","planned":75.5,"time":50.4000000000008}
DIRECTOR {"alive":25,"curve":82.9999999999996,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":81,"nearby":0,"pattern":"tide","phase":"decay","planned":82.9999999999996,"time":55.4000000000011}
ACTIVITY event=start kind=carrier time=57.47 age=0.00 pos=(1448.0, 936.0) offered=1 success=0 failed=0 rewards=0
SIM 01:00 level=3 kills=60 xp=38/60 credits=2/2 credits_left=2 zombies=22 kinds=21/1/0/0 elites=0 elites_spawned=0 crates=0 nades=1 dmg_taken=0 peak=34 fps=117 | АК-С L1 Стан1 [] | Мясник L1 Стан1 []
DIRECTOR {"alive":22,"curve":91.0999999999992,"damage":0.0,"exclusive":true,"intensity":0.00416666666666667,"issued":81,"nearby":0,"pattern":"tide","phase":"decay","planned":91.0999999999992,"time":60.4000000000013}
PICK lvl=4 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["weapon", "level", "level"]
ACTIVITY event=success kind=carrier time=64.93 age=7.47 pos=(1448.211, 709.1473) offered=1 success=1 failed=0 rewards=1
DIRECTOR {"alive":36,"curve":106.099999999999,"damage":0.0,"exclusive":false,"intensity":0.00416666666666667,"issued":97,"nearby":0,"pattern":"ambush","phase":"relax","planned":105.20478318584,"time":65.4000000000014}
PICK lvl=5 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "level", "weapon"]
DIRECTOR {"alive":28,"curve":121.3,"damage":0.0,"exclusive":false,"intensity":0.00833333333333333,"issued":97,"nearby":0,"pattern":"ambush","phase":"relax","planned":109.071305941845,"time":70.4666666666678}
DIRECTOR {"alive":24,"curve":136.499999999999,"damage":0.0,"exclusive":false,"intensity":0.00833333333333333,"issued":104,"nearby":0,"pattern":"ambush","phase":"relax","planned":112.941938053097,"time":75.5333333333342}
DIRECTOR {"alive":18,"curve":151.699999999998,"damage":0.0,"exclusive":false,"intensity":0.00416666666666667,"issued":104,"nearby":0,"pattern":"column","phase":"scout","planned":117.896361567636,"time":80.6000000000005}
DIRECTOR {"alive":20,"curve":166.899999999998,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":116,"nearby":0,"pattern":"column","phase":"scout","planned":130.968510745891,"time":85.6666666666669}
DIRECTOR {"alive":34,"curve":182.099999999997,"damage":0.0,"exclusive":false,"intensity":0.00833333333333333,"issued":137,"nearby":0,"pattern":"column","phase":"build","planned":144.927131057732,"time":90.7333333333333}
PICK lvl=6 { "type": "module", "id": 4, "rare": false } slot=0 of ["module", "weapon", "module"]
DIRECTOR {"alive":23,"curve":197.299999999996,"damage":0.0,"exclusive":false,"intensity":0.00416666666666667,"issued":145,"nearby":0,"pattern":"column","phase":"build","planned":164.126358828486,"time":95.7999999999997}
DIRECTOR {"alive":27,"curve":212.499999999995,"damage":0.0,"exclusive":false,"intensity":0.00833333333333333,"issued":168,"nearby":0,"pattern":"column","phase":"build","planned":183.311780973449,"time":100.866666666666}
DIRECTOR {"alive":23,"curve":227.699999999994,"damage":0.0,"exclusive":false,"intensity":0.00416666666666667,"issued":189,"nearby":0,"pattern":"column","phase":"build","planned":202.503258217444,"time":105.933333333332}
DIRECTOR {"alive":21,"curve":242.899999999993,"damage":0.0,"exclusive":false,"intensity":0.0166666666666667,"issued":209,"nearby":0,"pattern":"column","phase":"build","planned":221.701517172353,"time":110.999999999999}
DIRECTOR {"alive":16,"curve":258.099999999992,"damage":0.0,"exclusive":false,"intensity":0.00416666666666667,"issued":225,"nearby":0,"pattern":"column","phase":"peak","planned":242.400949220393,"time":116.066666666665}
SIM 02:00 level=6 kills=238 xp=156/273 credits=7/19 credits_left=7 zombies=15 kinds=15/0/0/0 elites=0 elites_spawned=0 crates=0 nades=5 dmg_taken=0 peak=38 fps=675 | АК-С L2 Стан1 [Сдво1] | Мясник L2 Стан1 []
DIRECTOR {"alive":15,"curve":274.366666666658,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":253,"nearby":0,"pattern":"column","phase":"peak","planned":267.014427447673,"time":121.133333333332}
DIRECTOR {"alive":0,"curve":294.633333333324,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":277,"nearby":0,"pattern":"column","phase":"peak","planned":297.689537996907,"time":126.199999999998}
DIRECTOR {"alive":18,"curve":314.899999999989,"damage":0.0,"exclusive":false,"intensity":0.0416666666666667,"issued":318,"nearby":0,"pattern":"column","phase":"peak","planned":328.402566793086,"time":131.266666666664}
DIRECTOR {"alive":16,"curve":335.166666666655,"damage":0.0,"exclusive":false,"intensity":0.00416666666666667,"issued":339,"nearby":0,"pattern":"column","phase":"decay","planned":347.061582104225,"time":136.333333333331}
DIRECTOR {"alive":10,"curve":355.43333333332,"damage":0.0,"exclusive":false,"intensity":0.0166666666666667,"issued":349,"nearby":0,"pattern":"column","phase":"decay","planned":363.475489815983,"time":141.399999999997}
DIRECTOR {"alive":8,"curve":375.699999999986,"damage":0.0,"exclusive":false,"intensity":0.0197916666666667,"issued":359,"nearby":1,"pattern":"column","phase":"relax","planned":374.620532729315,"time":146.466666666663}
DIRECTOR {"alive":7,"curve":395.966666666651,"damage":0.0,"exclusive":false,"intensity":0.0125,"issued":370,"nearby":0,"pattern":"column","phase":"relax","planned":379.790050849837,"time":151.53333333333}
ACTIVITY event=start kind=supply time=152.87 age=0.00 pos=(1277.973, 1090.646) offered=2 success=1 failed=0 rewards=1
PICK lvl=7 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["module", "level", "weapon"]
DIRECTOR {"alive":6,"curve":416.233333333317,"damage":0.0,"exclusive":true,"intensity":0.0,"issued":376,"nearby":0,"pattern":"column","phase":"relax","planned":395.900499016713,"time":156.599999999996}
DIRECTOR {"alive":29,"curve":436.499999999982,"damage":0.0,"exclusive":true,"intensity":0.0,"issued":399,"nearby":0,"pattern":"column","phase":"scout","planned":416.167165683379,"time":161.666666666663}
DIRECTOR {"alive":53,"curve":456.766666666648,"damage":0.0,"exclusive":true,"intensity":0.0,"issued":423,"nearby":0,"pattern":"column","phase":"scout","planned":436.433832350045,"time":166.733333333329}
DIRECTOR {"alive":68,"curve":477.033333333313,"damage":0.0,"exclusive":true,"intensity":0.0,"issued":438,"nearby":0,"pattern":"column","phase":"build","planned":456.70049901671,"time":171.799999999995}
DIRECTOR {"alive":92,"curve":497.299999999979,"damage":0.0,"exclusive":true,"intensity":0.0,"issued":462,"nearby":0,"pattern":"column","phase":"build","planned":476.967165683376,"time":176.866666666662}
SIM 03:00 level=7 kills=371 xp=200/406 credits=9/25 credits_left=9 zombies=103 kinds=81/22/0/0 elites=0 elites_spawned=0 crates=0 nades=6 dmg_taken=0 peak=103 fps=626 | АК-С L3 Стан1 [Сдво1] | Мясник L2 Стан1 []
DIRECTOR {"alive":113,"curve":517.566666666644,"damage":0.0,"exclusive":true,"intensity":0.0,"issued":483,"nearby":0,"pattern":"column","phase":"build","planned":497.233832350041,"time":181.933333333328}
DIRECTOR {"alive":116,"curve":537.83333333331,"damage":0.0,"exclusive":true,"intensity":0.0,"issued":497,"nearby":0,"pattern":"column","phase":"build","planned":517.500499016707,"time":186.999999999995}
DIRECTOR {"alive":128,"curve":558.099999999975,"damage":0.0,"exclusive":true,"intensity":0.0208333333333333,"issued":526,"nearby":0,"pattern":"column","phase":"build","planned":537.767165683372,"time":192.066666666661}
DIRECTOR {"alive":122,"curve":578.366666666641,"damage":0.0,"exclusive":true,"intensity":0.00833333333333333,"issued":538,"nearby":0,"pattern":"column","phase":"peak","planned":558.033832350038,"time":197.133333333327}
DIRECTOR {"alive":125,"curve":598.633333333306,"damage":0.0,"exclusive":true,"intensity":0.00833333333333333,"issued":564,"nearby":0,"pattern":"column","phase":"peak","planned":578.300499016703,"time":202.199999999994}
DIRECTOR {"alive":124,"curve":618.899999999972,"damage":0.0,"exclusive":true,"intensity":0.00416666666666667,"issued":582,"nearby":0,"pattern":"column","phase":"peak","planned":598.567165683369,"time":207.26666666666}
DIRECTOR {"alive":138,"curve":641.433333333306,"damage":0.0,"exclusive":true,"intensity":0.00416666666666667,"issued":606,"nearby":0,"pattern":"column","phase":"decay","planned":621.100499016703,"time":212.333333333326}
DIRECTOR {"alive":150,"curve":666.766666666642,"damage":0.0,"exclusive":true,"intensity":0.00833333333333333,"issued":632,"nearby":0,"pattern":"column","phase":"decay","planned":646.433832350039,"time":217.399999999993}
DIRECTOR {"alive":136,"curve":692.099999999978,"damage":0.0,"exclusive":true,"intensity":0.0458333333333333,"issued":655,"nearby":0,"pattern":"column","phase":"decay","planned":671.767165683375,"time":222.466666666659}
ACTIVITY event=failed kind=supply time=222.87 age=70.00 pos=(1277.973, 1090.646) offered=2 success=1 failed=1 rewards=1
DIRECTOR {"alive":128,"curve":717.433333333315,"damage":0.0,"exclusive":false,"intensity":0.025,"issued":669,"nearby":0,"pattern":"ring","phase":"relax","planned":683.142810349062,"time":227.533333333326}
DIRECTOR {"alive":96,"curve":742.766666666651,"damage":0.0,"exclusive":false,"intensity":0.0125,"issued":674,"nearby":0,"pattern":"ring","phase":"relax","planned":689.768511465793,"time":232.599999999992}
DIRECTOR {"alive":72,"curve":768.099999999987,"damage":0.0,"exclusive":false,"intensity":0.1375,"issued":674,"nearby":8,"pattern":"ring","phase":"relax","planned":696.538040016153,"time":237.666666666658}
SIM 04:00 level=7 kills=622 xp=214/657 credits=11/37 credits_left=11 zombies=54 kinds=49/3/2/0 elites=0 elites_spawned=0 crates=0 nades=8 dmg_taken=0 peak=153 fps=417 | АК-С L3 Стан1 [Сдво1] | Мясник L2 Стан1 []
DIRECTOR {"alive":61,"curve":796.099999999987,"damage":0.0,"exclusive":false,"intensity":0.00833333333333333,"issued":693,"nearby":0,"pattern":"ambush","phase":"scout","planned":713.89510565037,"time":242.733333333325}
DIRECTOR {"alive":82,"curve":826.499999999986,"damage":0.0,"exclusive":false,"intensity":0.00416666666666667,"issued":724,"nearby":0,"pattern":"ambush","phase":"scout","planned":740.040947622556,"time":247.799999999991}
DIRECTOR {"alive":96,"curve":856.899999999984,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":744,"nearby":0,"pattern":"ambush","phase":"build","planned":772.972170968532,"time":252.866666666657}
DIRECTOR {"alive":114,"curve":887.299999999982,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":777,"nearby":0,"pattern":"ambush","phase":"build","planned":811.394846906167,"time":257.933333333324}
DIRECTOR {"alive":140,"curve":917.69999999998,"damage":0.0,"exclusive":false,"intensity":0.00416666666666667,"issued":818,"nearby":0,"pattern":"ambush","phase":"build","planned":849.773441722855,"time":262.99999999999}
PICK lvl=8 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["module", "level", "module"]
DIRECTOR {"alive":130,"curve":948.099999999979,"damage":0.0,"exclusive":false,"intensity":0.053125,"issued":854,"nearby":1,"pattern":"ambush","phase":"build","planned":888.129027163226,"time":268.066666666657}
PICK lvl=9 { "type": "module", "id": 4, "rare": false } slot=0 of ["level", "module", "module"]
DIRECTOR {"alive":157,"curve":978.499999999977,"damage":0.0,"exclusive":false,"intensity":0.0166666666666667,"issued":897,"nearby":0,"pattern":"ambush","phase":"build","planned":926.489456682822,"time":273.133333333323}
DIRECTOR {"alive":150,"curve":1008.89999999998,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":939,"nearby":0,"pattern":"ambush","phase":"peak","planned":971.046784748562,"time":278.199999999989}
DIRECTOR {"alive":175,"curve":1039.29999999998,"damage":0.0,"exclusive":false,"intensity":0.0552083333333333,"issued":987,"nearby":3,"pattern":"ambush","phase":"peak","planned":1016.88976641734,"time":283.266666666656}
DIRECTOR {"alive":184,"curve":1069.69999999998,"damage":0.0,"exclusive":true,"intensity":0.1,"issued":1015,"nearby":0,"pattern":"ambush","phase":"peak","planned":1052.77171079155,"time":288.333333333322}
PICK lvl=10 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["passive", "module", "level"]
DIRECTOR {"alive":179,"curve":1100.09999999999,"damage":0.0,"exclusive":true,"intensity":0.00416666666666667,"issued":1036,"nearby":0,"pattern":"ambush","phase":"decay","planned":1083.17171079156,"time":293.399999999988}
DIRECTOR {"alive":181,"curve":1130.5,"damage":0.0,"exclusive":true,"intensity":0.0395833333333333,"issued":1077,"nearby":2,"pattern":"ambush","phase":"decay","planned":1113.57171079156,"time":298.466666666655}
TRADER 0 at 05:00 credits_left=37 bought=[]
SIM 05:00 level=10 kills=929 xp=528/1024 credits=37/80 credits_left=37 zombies=159 kinds=132/0/27/0 elites=0 elites_spawned=0 crates=0 nades=13 dmg_taken=0 peak=192 fps=293 | АК-С L4 Стан1 [Сдво2] | Мясник L3 Стан1 []
DIRECTOR {"alive":110,"curve":1164.36666666667,"damage":0.0,"exclusive":true,"intensity":0.0125,"issued":1110,"nearby":0,"pattern":"ambush","phase":"decay","planned":1147.43837745823,"time":303.533333333321}
PICK lvl=11 { "type": "weapon", "id": 5, "rare": false } slot=-1 of ["passive", "weapon", "weapon"]
PICK lvl=12 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["module", "level", "passive"]
DIRECTOR {"alive":6,"curve":1199.83333333334,"damage":13.3951301574707,"exclusive":true,"intensity":0.348518723805745,"issued":1139,"nearby":0,"pattern":"ambush","phase":"relax","planned":1182.9050441249,"time":308.599999999988}
DIRECTOR {"alive":34,"curve":1235.30000000001,"damage":13.3951301574707,"exclusive":true,"intensity":0.00416666666666667,"issued":1185,"nearby":0,"pattern":"ambush","phase":"relax","planned":1218.37171079157,"time":313.666666666654}
PICK lvl=13 { "type": "module", "id": 2, "rare": false } slot=0 of ["level", "module", "ammo"]
DIRECTOR {"alive":20,"curve":1270.76666666668,"damage":13.3951301574707,"exclusive":false,"intensity":0.0,"issued":1193,"nearby":0,"pattern":"rush","phase":"relax","planned":1234.77245304821,"time":318.73333333332}
DIRECTOR {"alive":41,"curve":1306.23333333334,"damage":13.3951301574707,"exclusive":false,"intensity":0.0,"issued":1223,"nearby":0,"pattern":"column","phase":"scout","planned":1259.62011160278,"time":323.799999999987}
ACTIVITY event=start kind=fuel time=328.07 age=0.00 pos=(1016.0, 1288.0) offered=3 success=1 failed=1 rewards=1
DIRECTOR {"alive":57,"curve":1341.70000000001,"damage":13.3951301574707,"exclusive":true,"intensity":0.0,"issued":1240,"nearby":0,"pattern":"column","phase":"scout","planned":1290.83134169128,"time":328.866666666653}
DIRECTOR {"alive":88,"curve":1377.16666666668,"damage":13.3951301574707,"exclusive":true,"intensity":0.0,"issued":1279,"nearby":0,"pattern":"column","phase":"build","planned":1326.29800835794,"time":333.93333333332}
DIRECTOR {"alive":120,"curve":1412.63333333335,"damage":13.3951301574707,"exclusive":true,"intensity":0.0,"issued":1311,"nearby":0,"pattern":"column","phase":"build","planned":1361.76467502461,"time":338.999999999986}
DIRECTOR {"alive":152,"curve":1448.10000000002,"damage":25.9933280944824,"exclusive":true,"intensity":0.341961260477702,"issued":1349,"nearby":0,"pattern":"column","phase":"build","planned":1397.23134169128,"time":344.066666666652}
DIRECTOR {"alive":176,"curve":1483.56666666669,"damage":25.9933280944824,"exclusive":true,"intensity":0.0377945938110352,"issued":1386,"nearby":0,"pattern":"column","phase":"build","planned":1432.69800835795,"time":349.133333333319}
DIRECTOR {"alive":187,"curve":1519.03333333336,"damage":38.6886739730835,"exclusive":true,"intensity":0.384213964780172,"issued":1414,"nearby":0,"pattern":"column","phase":"peak","planned":1468.16467502462,"time":354.199999999985}
DIRECTOR {"alive":206,"curve":1554.50000000003,"damage":76.9102001190186,"exclusive":true,"intensity":0.498878543217977,"issued":1455,"nearby":0,"pattern":"column","phase":"peak","planned":1503.63134169129,"time":359.266666666651}
SIM 06:00 level=13 kills=1254 xp=917/1511 credits=79/143 credits_left=79 zombies=213 kinds=130/38/26/19 elites=1 elites_spawned=2 crates=0 nades=14 dmg_taken=77 peak=213 fps=529 | АК-С L4 Стан1 [Сдво2,Спли1] | Мясник L4 Стан1 [] | Бульдог L1 Стан1 []
DIRECTOR {"alive":218,"curve":1594.23333333336,"damage":76.9102001190186,"exclusive":true,"intensity":0.240545209884644,"issued":1494,"nearby":0,"pattern":"column","phase":"peak","planned":1543.36467502462,"time":364.333333333318}
DIRECTOR {"alive":214,"curve":1634.76666666669,"damage":103.902005195618,"exclusive":true,"intensity":0.575687291781108,"issued":1536,"nearby":0,"pattern":"column","phase":"peak","planned":1583.89800835795,"time":369.399999999984}
MISSION_RESULT outcome=defeat time=370.33 kills=1331 peak=225 level=13 damage=116.75

EXIT_CODE=0
```

## hd1_mortal_fixed_w1_control.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_mortal_fixed_w1_control_engine.log --headless --fixed-fps 60 --path C:\Users\Dev\Desktop\zera-hd1 -- --sim=600 --mortal --fresh-save --layout-seed=81073 --director-trace=mortal_fixed_w1 --loadout-w1 --director-off
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=178.46 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
MISSION_RESULT outcome=defeat time=28.80 kills=29 peak=32 level=2 damage=120.00

EXIT_CODE=0
```

## hd1_mortal_fixed_w1_after.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_mortal_fixed_w1_after_engine.log --headless --fixed-fps 60 --path C:\Users\Dev\Desktop\zera-hd1 -- --sim=600 --mortal --fresh-save --layout-seed=81073 --director-trace=mortal_fixed_w1 --loadout-w1
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=193.11 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
DIRECTOR {"alive":0,"curve":0.0,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":0,"nearby":0,"pattern":"column","phase":"scout","planned":0.0,"time":0.0666666666666667}
DIRECTOR {"alive":4,"curve":7.49999999999999,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":4,"nearby":0,"pattern":"tide","phase":"scout","planned":7.49999999999999,"time":5.06666666666667}
DIRECTOR {"alive":13,"curve":15.1,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":13,"nearby":0,"pattern":"tide","phase":"build","planned":15.1,"time":10.1333333333333}
DIRECTOR {"alive":19,"curve":22.7000000000001,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":19,"nearby":0,"pattern":"tide","phase":"build","planned":22.7000000000001,"time":15.2}
DIRECTOR {"alive":29,"curve":30.3000000000002,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":29,"nearby":0,"pattern":"tide","phase":"build","planned":30.3000000000002,"time":20.2666666666666}
DIRECTOR {"alive":22,"curve":37.9000000000003,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":32,"nearby":0,"pattern":"tide","phase":"build","planned":37.9000000000003,"time":25.3333333333333}
MISSION_RESULT outcome=defeat time=28.80 kills=28 peak=32 level=2 damage=120.00

EXIT_CODE=0
```

## hd1_mortal_fixed_full_control.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_mortal_fixed_full_control_engine.log --headless --fixed-fps 60 --path C:\Users\Dev\Desktop\zera-hd1 -- --sim=600 --mortal --fresh-save --layout-seed=81073 --director-trace=mortal_fixed_full --loadout --director-off
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=179.57 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
ACTIVITY event=start kind=carrier time=57.47 age=0.00 pos=(1384.0, 808.0) offered=1 success=0 failed=0 rewards=0
ACTIVITY event=success kind=carrier time=59.53 age=2.07 pos=(1384.0, 808.0) offered=1 success=1 failed=0 rewards=1
SIM 01:00 level=1 kills=85 xp=3/120 credits=0/7 credits_left=0 zombies=3 kinds=3/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=26 fps=764 | АК-С L5 Зажи3 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
PICK lvl=2 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
PICK lvl=3 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["passive", "passive", "ammo"]
PICK lvl=4 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["passive", "passive", "ammo"]
SIM 02:00 level=4 kills=157 xp=75/192 credits=4/12 credits_left=4 zombies=100 kinds=100/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=100 fps=734 | АК-С L5 Эксп1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
ACTIVITY event=start kind=supply time=152.87 age=0.00 pos=(1131.28, 1131.07) offered=2 success=1 failed=0 rewards=1
ACTIVITY event=success kind=supply time=174.07 age=21.20 pos=(1131.28, 1131.07) offered=2 success=2 failed=0 rewards=2
SIM 03:00 level=4 kills=409 xp=77/444 credits=4/22 credits_left=4 zombies=2 kinds=0/2/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=150 fps=699 | АК-С L5 Эксп1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
PICK lvl=5 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "ammo", "ammo"]
PICK lvl=6 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["passive", "passive", "ammo"]
PICK lvl=7 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "passive", "passive"]
PICK lvl=8 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["passive", "ammo", "ammo"]
SIM 04:00 level=8 kills=680 xp=317/760 credits=21/53 credits_left=21 zombies=3 kinds=2/0/1/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=45 fps=613 | АК-С L5 Эксп1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
TRADER 0 at 05:00 credits_left=21 bought=[]
SIM 05:00 level=8 kills=1034 xp=317/1216 credits=21/89 credits_left=21 zombies=13 kinds=10/0/3/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=28 fps=619 | АК-С L5 Эксп1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
ACTIVITY event=start kind=fuel time=328.07 age=0.00 pos=(2022.436, 730.1956) offered=3 success=2 failed=0 rewards=2
ACTIVITY event=success kind=fuel time=340.73 age=12.67 pos=(2022.436, 730.1956) offered=3 success=3 failed=0 rewards=3
SIM 06:00 level=8 kills=1457 xp=321/1822 credits=21/203 credits_left=21 zombies=15 kinds=13/0/1/1 elites=0 elites_spawned=2 crates=0 nades=0 dmg_taken=60 peak=27 fps=502 | АК-С L5 Эксп1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
PICK lvl=9 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "ammo", "ammo"]
PICK lvl=10 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["passive", "passive", "ammo"]
PICK lvl=11 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["ammo", "ammo", "ammo"]
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
PICK lvl=12 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["ammo", "passive", "ammo"]
PICK lvl=13 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["passive", "ammo", "ammo"]
PICK lvl=14 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
PICK lvl=15 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["ammo", "passive", "ammo"]
PICK lvl=16 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["ammo", "ammo", "passive"]
PICK lvl=17 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
SIM 07:00 level=17 kills=1953 xp=1801/2579 credits=222/312 credits_left=222 zombies=7 kinds=5/0/1/1 elites=0 elites_spawned=4 crates=1 nades=1 dmg_taken=60 peak=38 fps=398 | АК-С L5 Зажи1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
ALARM_EVENT warn time=07:00
ALARM_EVENT start time=07:03
PICK lvl=18 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["ammo", "ammo", "passive"]
PICK lvl=19 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["ammo", "passive", "passive"]
PICK lvl=20 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["ammo", "passive", "ammo"]
ALARM_EVENT finish container=(2484.319, 709.6036) time=07:33
CONTAINER dropped pos=(2484.319, 709.6036) time=07:33
ALARM rewards mult=2 xp=2166 credits=312
PICK lvl=21 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["passive", "passive", "passive"]
CONTAINER picked time=07:35 crates=5
SIM 08:00 level=21 kills=2953 xp=2901/5201 credits=386/703 credits_left=386 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=10 crates=5 nades=3 dmg_taken=60 peak=75 fps=322 | АК-С L5 Стан1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
PICK lvl=22 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
PICK lvl=23 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["passive", "passive", "ammo"]
PICK lvl=24 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["passive", "ammo", "ammo"]
PICK lvl=25 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "passive", "passive"]
PICK lvl=26 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["ammo", "passive", "passive"]
CALM 09:00 removed=7 left=0
TRADER 1 at 09:00 credits_left=157 bought=["ammo(150)", "passive(60)", "ammo(60)", "ammo(150)", "passive(60)"]
SIM 09:00 level=26 kills=3606 xp=4718/6161 credits=637/857 credits_left=157 zombies=7 kinds=6/0/1/0 elites=0 elites_spawned=12 crates=6 nades=4 dmg_taken=60 peak=61 fps=291 | АК-С L5 Эксп1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
BOSS spawn t=600.00 pos=(2392.155, 760.2027) hp=24000
SIM 10:00 level=26 kills=3810 xp=4718/6413 credits=637/895 credits_left=157 zombies=1 kinds=1/0/0/0 elites=0 elites_spawned=14 crates=6 nades=4 dmg_taken=60 peak=17 fps=821 | АК-С L5 Эксп1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
SIM summary kills=3810 peak=150 level=26 damage=60.00 boss_alive=true

EXIT_CODE=0
```

## hd1_mortal_fixed_full_after.log

```text
COMMAND C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_mortal_fixed_full_after_engine.log --headless --fixed-fps 60 --path C:\Users\Dev\Desktop\zera-hd1 -- --sim=600 --mortal --fresh-save --layout-seed=81073 --director-trace=mortal_fixed_full --loadout
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=188.11 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
DIRECTOR {"alive":0,"curve":0.0,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":0,"nearby":0,"pattern":"column","phase":"scout","planned":0.0,"time":0.0666666666666667}
DIRECTOR {"alive":4,"curve":7.49999999999999,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":4,"nearby":0,"pattern":"tide","phase":"scout","planned":7.49999999999999,"time":5.06666666666667}
DIRECTOR {"alive":13,"curve":15.1,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":13,"nearby":0,"pattern":"tide","phase":"build","planned":15.1,"time":10.1333333333333}
DIRECTOR {"alive":15,"curve":22.7000000000001,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":19,"nearby":0,"pattern":"tide","phase":"build","planned":22.7000000000001,"time":15.2}
DIRECTOR {"alive":20,"curve":30.3000000000002,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":30,"nearby":0,"pattern":"tide","phase":"build","planned":30.3000000000002,"time":20.2666666666666}
DIRECTOR {"alive":13,"curve":37.9000000000003,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":36,"nearby":0,"pattern":"tide","phase":"build","planned":37.9000000000003,"time":25.3333333333333}
DIRECTOR {"alive":13,"curve":45.5000000000004,"damage":60.0,"exclusive":false,"intensity":0.500833333333333,"issued":44,"nearby":0,"pattern":"tide","phase":"build","planned":45.5000000000004,"time":30.3999999999999}
DIRECTOR {"alive":13,"curve":53.0000000000005,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":50,"nearby":0,"pattern":"tide","phase":"peak","planned":53.0000000000005,"time":35.4000000000001}
DIRECTOR {"alive":8,"curve":60.5000000000006,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":60,"nearby":0,"pattern":"tide","phase":"peak","planned":60.5000000000006,"time":40.4000000000003}
DIRECTOR {"alive":8,"curve":68.0000000000004,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":65,"nearby":0,"pattern":"tide","phase":"peak","planned":68.0000000000004,"time":45.4000000000006}
DIRECTOR {"alive":4,"curve":75.5,"damage":60.0,"exclusive":false,"intensity":0.200833333333333,"issued":75,"nearby":0,"pattern":"tide","phase":"peak","planned":75.5,"time":50.4000000000008}
DIRECTOR {"alive":0,"curve":82.9999999999996,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":81,"nearby":0,"pattern":"tide","phase":"decay","planned":82.9999999999996,"time":55.4000000000011}
ACTIVITY event=start kind=carrier time=57.47 age=0.00 pos=(1384.0, 808.0) offered=1 success=0 failed=0 rewards=0
ACTIVITY event=success kind=carrier time=58.87 age=1.40 pos=(1384.0, 808.0) offered=1 success=1 failed=0 rewards=1
SIM 01:00 level=1 kills=87 xp=3/122 credits=0/3 credits_left=0 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=26 fps=705 | АК-С L5 Зажи3 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":0,"curve":91.0999999999992,"damage":60.0,"exclusive":false,"intensity":0.28,"issued":86,"nearby":0,"pattern":"column","phase":"decay","planned":90.8957013906439,"time":60.4000000000013}
PICK lvl=2 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["ammo", "ammo", "passive"]
DIRECTOR {"alive":0,"curve":106.099999999999,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":91,"nearby":0,"pattern":"column","phase":"relax","planned":101.262526085123,"time":65.4000000000014}
DIRECTOR {"alive":12,"curve":121.3,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":103,"nearby":0,"pattern":"column","phase":"relax","planned":106.23008209018,"time":70.4666666666678}
DIRECTOR {"alive":12,"curve":136.499999999999,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":103,"nearby":0,"pattern":"column","phase":"relax","planned":111.197638095237,"time":75.5333333333342}
DIRECTOR {"alive":18,"curve":151.699999999998,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":109,"nearby":0,"pattern":"ambush","phase":"scout","planned":117.149345806995,"time":80.6000000000005}
DIRECTOR {"alive":30,"curve":166.899999999998,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":121,"nearby":0,"pattern":"ambush","phase":"scout","planned":130.427516224188,"time":85.6666666666669}
DIRECTOR {"alive":44,"curve":182.099999999997,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":135,"nearby":0,"pattern":"ambush","phase":"build","planned":144.507588032026,"time":90.7333333333333}
DIRECTOR {"alive":56,"curve":197.299999999996,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":161,"nearby":0,"pattern":"ambush","phase":"build","planned":163.312604635481,"time":95.7999999999997}
DIRECTOR {"alive":44,"curve":212.499999999995,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":175,"nearby":0,"pattern":"ambush","phase":"build","planned":182.107933080487,"time":100.866666666666}
DIRECTOR {"alive":44,"curve":227.699999999994,"damage":60.0,"exclusive":false,"intensity":0.200833333333333,"issued":195,"nearby":0,"pattern":"ambush","phase":"build","planned":200.909558828484,"time":105.933333333332}
DIRECTOR {"alive":44,"curve":242.899999999993,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":210,"nearby":0,"pattern":"ambush","phase":"build","planned":219.714091024017,"time":110.999999999999}
DIRECTOR {"alive":44,"curve":258.099999999992,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":231,"nearby":0,"pattern":"ambush","phase":"peak","planned":239.869932321951,"time":116.066666666665}
SIM 02:00 level=2 kills=208 xp=10/243 credits=1/8 credits_left=1 zombies=44 kinds=44/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=59 fps=800 | АК-С L5 Крио1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":44,"curve":274.366666666658,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":251,"nearby":0,"pattern":"ambush","phase":"peak","planned":263.680744458487,"time":121.133333333332}
DIRECTOR {"alive":53,"curve":294.633333333324,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":287,"nearby":0,"pattern":"ambush","phase":"peak","planned":293.32852330383,"time":126.199999999998}
DIRECTOR {"alive":44,"curve":314.899999999989,"damage":60.0,"exclusive":false,"intensity":0.2175,"issued":316,"nearby":0,"pattern":"ambush","phase":"peak","planned":322.963662733526,"time":131.266666666664}
DIRECTOR {"alive":54,"curve":335.166666666655,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":337,"nearby":0,"pattern":"ambush","phase":"decay","planned":341.773206995359,"time":136.333333333331}
DIRECTOR {"alive":68,"curve":355.43333333332,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":351,"nearby":0,"pattern":"ambush","phase":"decay","planned":358.554032616934,"time":141.399999999997}
DIRECTOR {"alive":39,"curve":375.699999999986,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":366,"nearby":0,"pattern":"ambush","phase":"relax","planned":370.585546818366,"time":146.466666666663}
DIRECTOR {"alive":39,"curve":395.966666666651,"damage":60.0,"exclusive":false,"intensity":0.18,"issued":366,"nearby":0,"pattern":"ambush","phase":"relax","planned":377.20895482511,"time":151.53333333333}
ACTIVITY event=start kind=supply time=152.87 age=0.00 pos=(1124.281, 1131.137) offered=2 success=1 failed=0 rewards=1
DIRECTOR {"alive":59,"curve":416.233333333317,"damage":60.0,"exclusive":true,"intensity":0.18,"issued":380,"nearby":0,"pattern":"ambush","phase":"relax","planned":393.705773704166,"time":156.599999999996}
DIRECTOR {"alive":39,"curve":436.499999999982,"damage":60.0,"exclusive":true,"intensity":0.23,"issued":394,"nearby":0,"pattern":"ambush","phase":"scout","planned":413.972440370832,"time":161.666666666663}
DIRECTOR {"alive":39,"curve":456.766666666648,"damage":60.0,"exclusive":true,"intensity":0.18,"issued":415,"nearby":0,"pattern":"ambush","phase":"scout","planned":434.239107037497,"time":166.733333333329}
DIRECTOR {"alive":54,"curve":477.033333333313,"damage":60.0,"exclusive":true,"intensity":0.18,"issued":440,"nearby":0,"pattern":"ambush","phase":"build","planned":454.505773704163,"time":171.799999999995}
ACTIVITY event=success kind=supply time=174.07 age=21.20 pos=(1124.281, 1131.137) offered=2 success=2 failed=0 rewards=2
PICK lvl=3 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
PICK lvl=4 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "passive", "passive"]
PICK lvl=5 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["ammo", "passive", "ammo"]
PICK lvl=6 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["ammo", "ammo", "passive"]
DIRECTOR {"alive":0,"curve":497.299999999979,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":448,"nearby":0,"pattern":"rush","phase":"build","planned":477.369594915007,"time":176.866666666662}
SIM 03:00 level=6 kills=477 xp=174/512 credits=9/28 credits_left=9 zombies=8 kinds=8/0/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=68 fps=610 | АК-С L5 Зажи1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":17,"curve":517.566666666644,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":475,"nearby":0,"pattern":"rush","phase":"build","planned":502.520972355659,"time":181.933333333328}
DIRECTOR {"alive":19,"curve":537.83333333331,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":502,"nearby":0,"pattern":"rush","phase":"build","planned":527.685267340908,"time":186.999999999995}
DIRECTOR {"alive":22,"curve":558.099999999975,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":524,"nearby":0,"pattern":"rush","phase":"build","planned":552.846978817236,"time":192.066666666661}
DIRECTOR {"alive":0,"curve":578.366666666641,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":549,"nearby":0,"pattern":"rush","phase":"peak","planned":580.819036128654,"time":197.133333333327}
DIRECTOR {"alive":13,"curve":598.633333333306,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":582,"nearby":0,"pattern":"rush","phase":"peak","planned":610.670056777619,"time":202.199999999994}
DIRECTOR {"alive":17,"curve":618.899999999972,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":611,"nearby":0,"pattern":"rush","phase":"peak","planned":640.521077426583,"time":207.26666666666}
DIRECTOR {"alive":27,"curve":641.433333333306,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":649,"nearby":0,"pattern":"rush","phase":"decay","planned":672.837903525756,"time":212.333333333326}
DIRECTOR {"alive":1,"curve":666.766666666642,"damage":60.0,"exclusive":false,"intensity":0.2,"issued":663,"nearby":0,"pattern":"rush","phase":"decay","planned":693.755139092552,"time":217.399999999993}
DIRECTOR {"alive":28,"curve":692.099999999978,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":690,"nearby":0,"pattern":"rush","phase":"decay","planned":714.658375502164,"time":222.466666666659}
DIRECTOR {"alive":14,"curve":717.433333333315,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":702,"nearby":0,"pattern":"rush","phase":"relax","planned":726.722256665248,"time":227.533333333326}
DIRECTOR {"alive":6,"curve":742.766666666651,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":709,"nearby":0,"pattern":"rush","phase":"relax","planned":734.743997078226,"time":232.599999999992}
DIRECTOR {"alive":0,"curve":768.099999999987,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":709,"nearby":0,"pattern":"rush","phase":"relax","planned":742.73834178956,"time":237.666666666658}
SIM 04:00 level=6 kills=728 xp=175/787 credits=9/48 credits_left=9 zombies=12 kinds=0/12/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=28 fps=724 | АК-С L5 Зажи1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":24,"curve":796.099999999987,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":733,"nearby":0,"pattern":"column","phase":"scout","planned":760.452134457068,"time":242.733333333325}
DIRECTOR {"alive":12,"curve":826.499999999986,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":760,"nearby":0,"pattern":"column","phase":"scout","planned":786.960726113199,"time":247.799999999991}
DIRECTOR {"alive":2,"curve":856.899999999984,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":789,"nearby":0,"pattern":"column","phase":"build","planned":819.67049855315,"time":252.866666666657}
DIRECTOR {"alive":42,"curve":887.299999999982,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":829,"nearby":0,"pattern":"column","phase":"build","planned":857.440192611307,"time":257.933333333324}
DIRECTOR {"alive":32,"curve":917.69999999998,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":872,"nearby":0,"pattern":"column","phase":"build","planned":895.184697457496,"time":262.99999999999}
DIRECTOR {"alive":24,"curve":948.099999999979,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":909,"nearby":0,"pattern":"column","phase":"build","planned":932.911763618475,"time":268.066666666657}
DIRECTOR {"alive":6,"curve":978.499999999977,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":941,"nearby":0,"pattern":"column","phase":"build","planned":970.648517937904,"time":273.133333333323}
DIRECTOR {"alive":17,"curve":1008.89999999998,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":977,"nearby":0,"pattern":"column","phase":"peak","planned":1014.17143576345,"time":278.199999999989}
DIRECTOR {"alive":43,"curve":1039.29999999998,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":1031,"nearby":0,"pattern":"column","phase":"peak","planned":1058.94796673689,"time":283.266666666656}
DIRECTOR {"alive":12,"curve":1069.69999999998,"damage":60.0,"exclusive":true,"intensity":0.15,"issued":1063,"nearby":0,"pattern":"column","phase":"peak","planned":1094.42608178114,"time":288.333333333322}
DIRECTOR {"alive":1,"curve":1100.09999999999,"damage":60.0,"exclusive":true,"intensity":0.15,"issued":1094,"nearby":0,"pattern":"column","phase":"decay","planned":1124.82608178115,"time":293.399999999988}
DIRECTOR {"alive":10,"curve":1130.5,"damage":60.0,"exclusive":true,"intensity":0.15,"issued":1127,"nearby":0,"pattern":"column","phase":"decay","planned":1155.22608178116,"time":298.466666666655}
TRADER 0 at 05:00 credits_left=9 bought=[]
SIM 05:00 level=6 kills=1136 xp=175/1303 credits=9/100 credits_left=9 zombies=18 kinds=14/0/4/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=60 peak=54 fps=614 | АК-С L5 Зажи1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":7,"curve":1164.36666666667,"damage":60.0,"exclusive":true,"intensity":0.175,"issued":1164,"nearby":0,"pattern":"column","phase":"decay","planned":1189.09274844783,"time":303.533333333321}
DIRECTOR {"alive":22,"curve":1199.83333333334,"damage":60.0,"exclusive":true,"intensity":0.15,"issued":1196,"nearby":0,"pattern":"column","phase":"relax","planned":1224.5594151145,"time":308.599999999988}
DIRECTOR {"alive":21,"curve":1235.30000000001,"damage":60.0,"exclusive":true,"intensity":0.15,"issued":1235,"nearby":0,"pattern":"column","phase":"relax","planned":1260.02608178117,"time":313.666666666654}
DIRECTOR {"alive":0,"curve":1270.76666666668,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":1235,"nearby":0,"pattern":"ambush","phase":"relax","planned":1277.8978590673,"time":318.73333333332}
DIRECTOR {"alive":28,"curve":1306.23333333334,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":1263,"nearby":0,"pattern":"ring","phase":"scout","planned":1303.67838414105,"time":323.799999999987}
ACTIVITY event=start kind=fuel time=328.07 age=0.00 pos=(916.6993, 945.808) offered=3 success=2 failed=0 rewards=2
DIRECTOR {"alive":15,"curve":1341.70000000001,"damage":60.0,"exclusive":true,"intensity":0.15,"issued":1288,"nearby":0,"pattern":"ring","phase":"scout","planned":1335.25879564548,"time":328.866666666653}
DIRECTOR {"alive":48,"curve":1377.16666666668,"damage":60.0,"exclusive":true,"intensity":0.15,"issued":1320,"nearby":0,"pattern":"ring","phase":"build","planned":1370.72546231215,"time":333.93333333332}
DIRECTOR {"alive":26,"curve":1412.63333333335,"damage":60.0,"exclusive":true,"intensity":0.15,"issued":1362,"nearby":0,"pattern":"ring","phase":"build","planned":1406.19212897882,"time":338.999999999986}
ACTIVITY event=success kind=fuel time=341.00 age=12.93 pos=(916.6993, 945.808) offered=3 success=3 failed=0 rewards=3
DIRECTOR {"alive":4,"curve":1448.10000000002,"damage":60.0,"exclusive":false,"intensity":0.15,"issued":1367,"nearby":0,"pattern":"column","phase":"build","planned":1446.74970272513,"time":344.066666666652}
PICK lvl=7 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "passive", "ammo"]
DIRECTOR {"alive":0,"curve":1483.56666666669,"damage":60.0,"exclusive":false,"intensity":0.178571428571429,"issued":1419,"nearby":0,"pattern":"column","phase":"build","planned":1490.77849960672,"time":349.133333333319}
PICK lvl=8 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["passive", "ammo", "passive"]
PICK lvl=9 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "ammo", "passive"]
DIRECTOR {"alive":0,"curve":1519.03333333336,"damage":60.0,"exclusive":false,"intensity":0.158333333333333,"issued":1465,"nearby":0,"pattern":"column","phase":"peak","planned":1535.05225743787,"time":354.199999999985}
PICK lvl=10 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["passive", "passive", "ammo"]
DIRECTOR {"alive":28,"curve":1554.50000000003,"damage":60.0,"exclusive":false,"intensity":0.1125,"issued":1507,"nearby":0,"pattern":"column","phase":"peak","planned":1587.6211163366,"time":359.266666666651}
SIM 06:00 level=10 kills=1510 xp=465/1880 credits=38/202 credits_left=38 zombies=46 kinds=34/0/4/8 elites=0 elites_spawned=2 crates=0 nades=0 dmg_taken=60 peak=80 fps=523 | АК-С L5 Эксп1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":51,"curve":1594.23333333336,"damage":60.0,"exclusive":false,"intensity":0.1125,"issued":1574,"nearby":0,"pattern":"column","phase":"peak","planned":1646.50669766824,"time":364.333333333318}
DIRECTOR {"alive":38,"curve":1634.76666666669,"damage":60.0,"exclusive":false,"intensity":0.1125,"issued":1635,"nearby":0,"pattern":"column","phase":"peak","planned":1706.58033778624,"time":369.399999999984}
DIRECTOR {"alive":18,"curve":1675.30000000002,"damage":60.0,"exclusive":false,"intensity":0.1125,"issued":1679,"nearby":0,"pattern":"column","phase":"decay","planned":1753.92848612168,"time":374.466666666651}
DIRECTOR {"alive":25,"curve":1715.83333333335,"damage":60.0,"exclusive":false,"intensity":0.1125,"issued":1713,"nearby":0,"pattern":"column","phase":"decay","planned":1787.2252733109,"time":379.533333333317}
DIRECTOR {"alive":1,"curve":1756.36666666668,"damage":60.0,"exclusive":false,"intensity":0.1125,"issued":1737,"nearby":0,"pattern":"column","phase":"relax","planned":1818.29554554014,"time":384.599999999983}
DIRECTOR {"alive":8,"curve":1796.90000000001,"damage":60.0,"exclusive":false,"intensity":0.1125,"issued":1760,"nearby":0,"pattern":"column","phase":"relax","planned":1830.50570820344,"time":389.66666666665}
DIRECTOR {"alive":1,"curve":1837.43333333335,"damage":60.0,"exclusive":false,"intensity":0.1125,"issued":1771,"nearby":0,"pattern":"column","phase":"relax","planned":1842.71587086674,"time":394.733333333316}
DIRECTOR {"alive":10,"curve":1877.96666666668,"damage":60.0,"exclusive":false,"intensity":0.1375,"issued":1786,"nearby":0,"pattern":"column","phase":"relax","planned":1854.86028384609,"time":399.799999999982}
DIRECTOR {"alive":8,"curve":1918.50000000001,"damage":60.0,"exclusive":false,"intensity":0.1125,"issued":1817,"nearby":0,"pattern":"flank","phase":"scout","planned":1888.89109547694,"time":404.866666666649}
DIRECTOR {"alive":12,"curve":1959.03333333334,"damage":60.0,"exclusive":false,"intensity":0.158333333333333,"issued":1848,"nearby":0,"pattern":"flank","phase":"scout","planned":1924.11239509767,"time":409.933333333315}
DIRECTOR {"alive":32,"curve":1999.56666666667,"damage":60.0,"exclusive":false,"intensity":0.1125,"issued":1888,"nearby":0,"pattern":"flank","phase":"build","planned":1974.24338877655,"time":414.999999999982}
DIRECTOR {"alive":15,"curve":2040.1,"damage":60.0,"exclusive":false,"intensity":0.1125,"issued":1942,"nearby":0,"pattern":"flank","phase":"build","planned":2024.75153261697,"time":420.066666666648}
SIM 07:00 level=10 kills=1961 xp=465/2525 credits=38/274 credits_left=38 zombies=15 kinds=9/0/5/1 elites=0 elites_spawned=4 crates=0 nades=0 dmg_taken=60 peak=78 fps=623 | АК-С L5 Эксп1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
ALARM_EVENT warn time=07:00
ALARM_EVENT start time=07:03
DIRECTOR {"alive":73,"curve":2112.63333333333,"damage":60.0,"exclusive":true,"intensity":0.1125,"issued":2003,"nearby":0,"pattern":"flank","phase":"build","planned":2097.41706527605,"time":425.133333333314}
DIRECTOR {"alive":56,"curve":2234.23333333332,"damage":60.0,"exclusive":true,"intensity":0.1125,"issued":2134,"nearby":0,"pattern":"flank","phase":"build","planned":2219.01706527604,"time":430.199999999981}
DIRECTOR {"alive":39,"curve":2355.83333333332,"damage":60.0,"exclusive":true,"intensity":0.1125,"issued":2255,"nearby":0,"pattern":"flank","phase":"peak","planned":2340.61706527604,"time":435.266666666647}
DIRECTOR {"alive":11,"curve":2477.43333333331,"damage":60.0,"exclusive":true,"intensity":0.1625,"issued":2377,"nearby":0,"pattern":"flank","phase":"peak","planned":2462.21706527603,"time":440.333333333313}
DIRECTOR {"alive":8,"curve":2599.0333333333,"damage":60.0,"exclusive":true,"intensity":0.1625,"issued":2498,"nearby":0,"pattern":"flank","phase":"peak","planned":2583.81706527602,"time":445.39999999998}
DIRECTOR {"alive":48,"curve":2720.6333333333,"damage":60.0,"exclusive":true,"intensity":0.1125,"issued":2614,"nearby":0,"pattern":"flank","phase":"peak","planned":2705.41706527602,"time":450.466666666646}
ALARM_EVENT finish container=(1414.98, 985.8466) time=07:33
CONTAINER dropped pos=(1414.98, 985.8466) time=07:33
ALARM rewards mult=2 xp=2150 credits=324
DIRECTOR {"alive":0,"curve":2806.23333333329,"damage":60.0,"exclusive":false,"intensity":0.116666666666667,"issued":2694,"nearby":0,"pattern":"tide","phase":"decay","planned":2787.1866095238,"time":455.533333333313}
DIRECTOR {"alive":44,"curve":2851.83333333328,"damage":60.0,"exclusive":false,"intensity":0.1125,"issued":2738,"nearby":0,"pattern":"tide","phase":"decay","planned":2824.62239650232,"time":460.599999999979}
DIRECTOR {"alive":23,"curve":2897.43333333327,"damage":60.0,"exclusive":false,"intensity":0.1125,"issued":2761,"nearby":0,"pattern":"tide","phase":"relax","planned":2854.57939334176,"time":465.666666666645}
DIRECTOR {"alive":13,"curve":2943.03333333327,"damage":60.0,"exclusive":false,"intensity":0.1125,"issued":2782,"nearby":0,"pattern":"tide","phase":"relax","planned":2868.38979473241,"time":470.733333333312}
DIRECTOR {"alive":3,"curve":2988.63333333326,"damage":60.0,"exclusive":false,"intensity":0.1125,"issued":2792,"nearby":0,"pattern":"tide","phase":"relax","planned":2882.1426651496,"time":475.799999999978}
SIM 08:00 level=10 kills=2844 xp=465/4884 credits=38/614 credits_left=38 zombies=1 kinds=0/1/0/0 elites=0 elites_spawned=10 crates=0 nades=0 dmg_taken=75 peak=127 fps=264 | АК-С L5 Эксп1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":13,"curve":3035.83333333325,"damage":75.2097501754761,"exclusive":false,"intensity":0.441018281579018,"issued":2817,"nearby":0,"pattern":"column","phase":"scout","planned":2906.05041256699,"time":480.866666666645}
DIRECTOR {"alive":25,"curve":3091.56666666657,"damage":75.2097501754761,"exclusive":false,"intensity":0.141018281579018,"issued":2864,"nearby":0,"pattern":"column","phase":"scout","planned":2954.81650593838,"time":485.933333333311}
DIRECTOR {"alive":23,"curve":3147.29999999989,"damage":75.2097501754761,"exclusive":false,"intensity":0.141018281579018,"issued":2918,"nearby":0,"pattern":"column","phase":"build","planned":3007.20698662507,"time":490.999999999977}
DIRECTOR {"alive":26,"curve":3203.0333333332,"damage":75.2097501754761,"exclusive":false,"intensity":0.141018281579018,"issued":2978,"nearby":0,"pattern":"column","phase":"build","planned":3076.43891557349,"time":496.066666666644}
DIRECTOR {"alive":64,"curve":3258.76666666652,"damage":75.2097501754761,"exclusive":false,"intensity":0.141018281579018,"issued":3053,"nearby":0,"pattern":"column","phase":"build","planned":3145.67084452192,"time":501.13333333331}
DIRECTOR {"alive":45,"curve":3314.49999999984,"damage":75.2097501754761,"exclusive":false,"intensity":0.141018281579018,"issued":3127,"nearby":0,"pattern":"column","phase":"build","planned":3214.94184904276,"time":506.199999999976}
DIRECTOR {"alive":32,"curve":3370.23333333316,"damage":75.2097501754761,"exclusive":false,"intensity":0.141018281579018,"issued":3198,"nearby":0,"pattern":"column","phase":"build","planned":3284.17377799119,"time":511.266666666643}
DIRECTOR {"alive":7,"curve":3425.23333333314,"damage":75.2097501754761,"exclusive":false,"intensity":0.170184948245684,"issued":3263,"nearby":0,"pattern":"column","phase":"peak","planned":3358.02763814128,"time":516.266666666646}
DIRECTOR {"alive":14,"curve":3480.23333333312,"damage":75.2097501754761,"exclusive":false,"intensity":0.141018281579018,"issued":3354,"nearby":0,"pattern":"column","phase":"peak","planned":3439.25453464593,"time":521.26666666665}
DIRECTOR {"alive":38,"curve":3535.23333333311,"damage":75.2097501754761,"exclusive":false,"intensity":0.141018281579018,"issued":3435,"nearby":0,"pattern":"column","phase":"peak","planned":3520.18164001068,"time":526.266666666654}
DIRECTOR {"alive":57,"curve":3590.23333333309,"damage":75.2097501754761,"exclusive":false,"intensity":0.141018281579018,"issued":3511,"nearby":0,"pattern":"column","phase":"peak","planned":3601.26863398337,"time":531.266666666658}
DIRECTOR {"alive":0,"curve":3645.23333333308,"damage":75.2097501754761,"exclusive":true,"intensity":0.141018281579018,"issued":3544,"nearby":0,"pattern":"column","phase":"decay","planned":3654.71648514721,"time":536.266666666662}
CALM 09:00 removed=50 left=0
TRADER 1 at 09:00 credits_left=38 bought=[]
SIM 09:00 level=10 kills=3585 xp=465/5875 credits=38/739 credits_left=38 zombies=50 kinds=28/10/6/6 elites=0 elites_spawned=12 crates=0 nades=0 dmg_taken=75 peak=94 fps=384 | АК-С L5 Эксп1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
DIRECTOR {"alive":9,"curve":3690.63333333306,"damage":75.2097501754761,"exclusive":true,"intensity":0.141018281579018,"issued":3602,"nearby":0,"pattern":"column","phase":"decay","planned":3700.1164851472,"time":541.266666666666}
DIRECTOR {"alive":13,"curve":3705.63333333305,"damage":75.2097501754761,"exclusive":true,"intensity":0.182684948245684,"issued":3616,"nearby":0,"pattern":"column","phase":"relax","planned":3715.11648514719,"time":546.26666666667}
DIRECTOR {"alive":0,"curve":3720.63333333303,"damage":75.2097501754761,"exclusive":true,"intensity":0.141018281579018,"issued":3625,"nearby":0,"pattern":"column","phase":"relax","planned":3730.11648514717,"time":551.266666666674}
DIRECTOR {"alive":9,"curve":3735.63333333302,"damage":75.2097501754761,"exclusive":true,"intensity":0.141018281579018,"issued":3645,"nearby":0,"pattern":"column","phase":"relax","planned":3745.11648514716,"time":556.266666666678}
DIRECTOR {"alive":11,"curve":3750.63333333301,"damage":75.2097501754761,"exclusive":true,"intensity":0.149351614912351,"issued":3656,"nearby":0,"pattern":"column","phase":"scout","planned":3760.11648514714,"time":561.266666666682}
DIRECTOR {"alive":12,"curve":3765.63333333299,"damage":75.2097501754761,"exclusive":true,"intensity":0.141018281579018,"issued":3677,"nearby":0,"pattern":"column","phase":"scout","planned":3775.11648514713,"time":566.266666666686}
DIRECTOR {"alive":12,"curve":3781.89999999965,"damage":75.2097501754761,"exclusive":true,"intensity":0.141018281579018,"issued":3688,"nearby":0,"pattern":"column","phase":"build","planned":3791.38315181379,"time":571.26666666669}
DIRECTOR {"alive":10,"curve":3801.89999999967,"damage":75.2097501754761,"exclusive":true,"intensity":0.141018281579018,"issued":3708,"nearby":0,"pattern":"column","phase":"build","planned":3811.38315181381,"time":576.266666666694}
DIRECTOR {"alive":12,"curve":3821.89999999969,"damage":75.2097501754761,"exclusive":true,"intensity":0.191018281579018,"issued":3732,"nearby":0,"pattern":"column","phase":"build","planned":3831.38315181382,"time":581.266666666698}
DIRECTOR {"alive":17,"curve":3841.8999999997,"damage":75.2097501754761,"exclusive":true,"intensity":0.141018281579018,"issued":3750,"nearby":0,"pattern":"column","phase":"build","planned":3851.38315181384,"time":586.266666666702}
DIRECTOR {"alive":8,"curve":3861.89999999972,"damage":75.2097501754761,"exclusive":true,"intensity":0.141018281579018,"issued":3770,"nearby":0,"pattern":"column","phase":"build","planned":3871.38315181386,"time":591.266666666706}
DIRECTOR {"alive":0,"curve":3881.89999999973,"damage":75.2097501754761,"exclusive":true,"intensity":0.141018281579018,"issued":3788,"nearby":0,"pattern":"column","phase":"peak","planned":3891.38315181387,"time":596.26666666671}
BOSS spawn t=600.00 pos=(1288.98, 985.8485) hp=24000
SIM 10:00 level=10 kills=3786 xp=465/6124 credits=38/770 credits_left=38 zombies=11 kinds=0/11/0/0 elites=0 elites_spawned=14 crates=0 nades=0 dmg_taken=75 peak=29 fps=654 | АК-С L5 Эксп1 [Сдво3,Рико3,Цепь3] | Мясник L5 Эксп3 [Дето3,Спли3,Проб3] | Игла L5 Крио3 [Проб3,Рико3,Спли3] | Гром L5 Стан3 [Спли3,Дето3,Сдво3]
SIM summary kills=3786 peak=127 level=10 damage=75.21 boss_alive=true
DIRECTOR summary curve=3896.83 planned=3906.32 issued=3804 dropped=31

EXIT_CODE=0
```

## hd1_shots_delivery.log

```text
COMMAND "C:/Program Files/Git/usr/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_shots_delivery_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-hd1 -- --director-shots --fresh-save --layout-seed=81073
GODOT_EXCLUSIVE other_godot_processes=0 at 18:21:05
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=302.30 seed=81073
DIRECTORSHOT pattern=pincer stage=0 alive=120 path=res://design/tasks/reports/hd1_pincer_start.png
DIRECTORSHOT pattern=pincer stage=1 alive=120 path=res://design/tasks/reports/hd1_pincer.png
DIRECTORSHOT pattern=ring stage=0 alive=120 path=res://design/tasks/reports/hd1_ring_start.png
DIRECTORSHOT pattern=ring stage=1 alive=120 path=res://design/tasks/reports/hd1_ring.png
DIRECTORSHOT pattern=column stage=0 alive=120 path=res://design/tasks/reports/hd1_column_start.png
DIRECTORSHOT pattern=column stage=1 alive=120 path=res://design/tasks/reports/hd1_column.png
DIRECTORSHOT pattern=rush stage=0 alive=70 path=res://design/tasks/reports/hd1_rush_start.png
DIRECTORSHOT pattern=rush stage=1 alive=70 path=res://design/tasks/reports/hd1_rush.png
DIRECTORSHOT pattern=ambush stage=0 alive=120 path=res://design/tasks/reports/hd1_ambush_start.png
DIRECTORSHOT pattern=ambush stage=1 alive=120 path=res://design/tasks/reports/hd1_ambush.png
DIRECTORSHOT pattern=tide stage=0 alive=120 path=res://design/tasks/reports/hd1_tide_start.png
DIRECTORSHOT pattern=tide stage=1 alive=120 path=res://design/tasks/reports/hd1_tide.png
DIRECTORSHOT pattern=flank stage=0 alive=120 path=res://design/tasks/reports/hd1_flank_start.png
DIRECTORSHOT pattern=flank stage=1 alive=120 path=res://design/tasks/reports/hd1_flank.png
DIRECTORSHOT pattern=rest stage=0 alive=0 path=res://design/tasks/reports/hd1_rest_start.png
DIRECTORSHOT pattern=rest stage=1 alive=0 path=res://design/tasks/reports/hd1_rest.png
DIRECTORSHOTS ok=true viewport=true camera=standard
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0
```

## hd1_live_final.log

```text
COMMAND "C:/Program Files/Git/usr/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-hd1\design\tasks\reports\hd1_live_final_engine.log --disable-vsync --fixed-fps 60 --path C:\Users\Dev\Desktop\zera-hd1 -- --sim=600 --fresh-save --layout-seed=81073 --director-trace=live --director-capture-live
GODOT_EXCLUSIVE other_godot_processes=0 at 18:16:05
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=251.49 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
DIRECTOR {"alive":0,"curve":0.0,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":0,"nearby":0,"pattern":"column","phase":"scout","planned":0.0,"time":0.0666666666666667}
DIRECTOR {"alive":4,"curve":7.49999999999999,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":4,"nearby":0,"pattern":"tide","phase":"scout","planned":7.49999999999999,"time":5.06666666666667}
DIRECTOR {"alive":13,"curve":15.1,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":13,"nearby":0,"pattern":"tide","phase":"build","planned":15.1,"time":10.1333333333333}
DIRECTOR {"alive":20,"curve":22.7000000000001,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":20,"nearby":0,"pattern":"tide","phase":"build","planned":22.7000000000001,"time":15.2}
DIRECTOR {"alive":28,"curve":30.3000000000002,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":28,"nearby":0,"pattern":"tide","phase":"build","planned":30.3000000000002,"time":20.2666666666666}
DIRECTOR {"alive":34,"curve":37.9000000000003,"damage":0.0,"exclusive":false,"intensity":0.03125,"issued":37,"nearby":2,"pattern":"tide","phase":"build","planned":37.9000000000003,"time":25.3333333333333}
PICK lvl=2 { "type": "weapon", "id": 1, "rare": false } slot=-1 of ["weapon", "passive", "level"]
DIRECTOR {"alive":33,"curve":45.5000000000004,"damage":0.0,"exclusive":false,"intensity":0.119791666666667,"issued":42,"nearby":1,"pattern":"tide","phase":"build","planned":45.5000000000004,"time":30.3999999999999}
DIRECTOR {"alive":42,"curve":53.0000000000005,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":53,"nearby":0,"pattern":"tide","phase":"peak","planned":53.0000000000005,"time":35.4000000000001}
DIRECTOR {"alive":43,"curve":60.5000000000006,"damage":0.0,"exclusive":false,"intensity":0.00833333333333333,"issued":58,"nearby":0,"pattern":"tide","phase":"peak","planned":60.5000000000006,"time":40.4000000000003}
DIRECTOR {"alive":50,"curve":68.0000000000004,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":68,"nearby":0,"pattern":"tide","phase":"peak","planned":68.0000000000004,"time":45.4000000000006}
PICK lvl=3 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "passive", "module"]
DIRECTOR {"alive":44,"curve":75.5,"damage":0.0,"exclusive":false,"intensity":0.00416666666666667,"issued":74,"nearby":0,"pattern":"tide","phase":"peak","planned":75.5,"time":50.4000000000008}
DIRECTOR {"alive":39,"curve":82.9999999999996,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":79,"nearby":0,"pattern":"tide","phase":"decay","planned":82.9999999999996,"time":55.4000000000011}
ACTIVITY event=start kind=carrier time=57.47 age=0.00 pos=(1573.858, 447.2546) offered=1 success=0 failed=0 rewards=0
SIM 01:00 level=3 kills=45 xp=38/45 credits=5/5 credits_left=5 zombies=40 kinds=39/1/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=0 peak=50 fps=231 | АК-С L1 Стан1 [] | Мясник L2 Стан1 []
DIRECTOR {"alive":39,"curve":91.0999999999992,"damage":0.0,"exclusive":true,"intensity":0.00416666666666667,"issued":84,"nearby":0,"pattern":"tide","phase":"decay","planned":91.0999999999992,"time":60.4000000000013}
ACTIVITY event=success kind=carrier time=63.07 age=5.60 pos=(1641.294, 305.6184) offered=1 success=1 failed=0 rewards=1
PICK lvl=4 { "type": "weapon", "id": 2, "rare": false } slot=-1 of ["weapon", "weapon", "passive"]
DIRECTOR {"alive":42,"curve":106.099999999999,"damage":0.0,"exclusive":false,"intensity":0.0,"issued":90,"nearby":0,"pattern":"ambush","phase":"relax","planned":102.469307627475,"time":65.4000000000014}
DIRECTOR {"alive":30,"curve":121.3,"damage":0.0,"exclusive":false,"intensity":0.0354166666666667,"issued":90,"nearby":2,"pattern":"ambush","phase":"relax","planned":106.355692267172,"time":70.4666666666678}
PICK lvl=5 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["level", "module", "passive"]
DIRECTOR {"alive":23,"curve":136.499999999999,"damage":0.0,"exclusive":false,"intensity":0.00416666666666667,"issued":99,"nearby":0,"pattern":"ambush","phase":"relax","planned":110.26193879056,"time":75.5333333333342}
DIRECTOR {"alive":14,"curve":151.699999999998,"damage":32.8002652225495,"exclusive":false,"intensity":0.308333333333333,"issued":99,"nearby":0,"pattern":"column","phase":"scout","planned":116.202023493468,"time":80.6000000000005}
DIRECTOR {"alive":19,"curve":166.899999999998,"damage":32.8002652225495,"exclusive":false,"intensity":0.00416666666666667,"issued":108,"nearby":0,"pattern":"column","phase":"scout","planned":129.56823145807,"time":85.6666666666669}
DIRECTOR {"alive":37,"curve":182.099999999997,"damage":32.8002652225495,"exclusive":false,"intensity":0.0,"issued":129,"nearby":0,"pattern":"column","phase":"build","planned":143.526492520016,"time":90.7333333333333}
PICK lvl=6 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["ammo", "ammo", "level"]
DIRECTOR {"alive":53,"curve":197.299999999996,"damage":32.8002652225495,"exclusive":false,"intensity":0.0,"issued":152,"nearby":0,"pattern":"column","phase":"build","planned":162.735892857142,"time":95.7999999999997}
DIRECTOR {"alive":66,"curve":212.499999999995,"damage":32.8002652225495,"exclusive":false,"intensity":0.0,"issued":171,"nearby":0,"pattern":"column","phase":"build","planned":181.946262010112,"time":100.866666666666}
DIRECTOR {"alive":69,"curve":227.699999999994,"damage":32.8002652225495,"exclusive":false,"intensity":0.0,"issued":189,"nearby":0,"pattern":"column","phase":"build","planned":201.147911820479,"time":105.933333333332}
DIRECTOR {"alive":87,"curve":242.899999999993,"damage":32.8002652225495,"exclusive":false,"intensity":0.00416666666666667,"issued":208,"nearby":0,"pattern":"column","phase":"build","planned":220.364093868519,"time":110.999999999999}
DIRECTOR {"alive":99,"curve":258.099999999992,"damage":32.8002652225495,"exclusive":false,"intensity":0.0,"issued":229,"nearby":0,"pattern":"column","phase":"peak","planned":241.083060998734,"time":116.066666666665}
SIM 02:00 level=6 kills=158 xp=168/193 credits=13/15 credits_left=13 zombies=92 kinds=92/0/0/0 elites=0 elites_spawned=0 crates=0 nades=2 dmg_taken=33 peak=100 fps=233 | АК-С L2 Стан1 [] | Мясник L2 Стан1 [] | Игла L1 Стан1 []
DIRECTOR {"alive":89,"curve":274.366666666658,"damage":32.8002652225495,"exclusive":false,"intensity":0.00833333333333333,"issued":249,"nearby":0,"pattern":"column","phase":"peak","planned":265.681687912626,"time":121.133333333332}
DIRECTOR {"alive":104,"curve":294.633333333324,"damage":32.8002652225495,"exclusive":false,"intensity":0.0197916666666667,"issued":281,"nearby":1,"pattern":"column","phase":"peak","planned":296.366594008988,"time":126.199999999998}
PICK lvl=7 { "type": "weapon", "id": 4, "rare": false } slot=-1 of ["weapon", "ammo", "weapon"]
DIRECTOR {"alive":102,"curve":314.899999999989,"damage":32.8002652225495,"exclusive":false,"intensity":0.175,"issued":314,"nearby":4,"pattern":"column","phase":"peak","planned":326.788600259865,"time":131.266666666664}
DIRECTOR {"alive":90,"curve":335.166666666655,"damage":32.8002652225495,"exclusive":false,"intensity":0.115625,"issued":326,"nearby":1,"pattern":"column","phase":"decay","planned":345.365508041858,"time":136.333333333331}
DIRECTOR {"alive":81,"curve":355.43333333332,"damage":32.8002652225495,"exclusive":false,"intensity":0.0197916666666667,"issued":351,"nearby":1,"pattern":"column","phase":"decay","planned":361.854661223485,"time":141.399999999997}
DIRECTOR {"alive":58,"curve":375.699999999986,"damage":32.8002652225495,"exclusive":false,"intensity":0.00833333333333333,"issued":362,"nearby":0,"pattern":"column","phase":"relax","planned":372.957248525072,"time":146.466666666663}
PICK lvl=8 { "type": "module", "id": 3, "rare": false } slot=0 of ["module", "level", "module"]
DIRECTOR {"alive":25,"curve":395.966666666651,"damage":32.8002652225495,"exclusive":false,"intensity":0.00416666666666667,"issued":367,"nearby":0,"pattern":"column","phase":"relax","planned":378.265114938894,"time":151.53333333333}
ACTIVITY event=start kind=supply time=152.87 age=0.00 pos=(1832.0, 504.0) offered=2 success=1 failed=0 rewards=1
DIRECTOR {"alive":25,"curve":416.233333333317,"damage":32.8002652225495,"exclusive":true,"intensity":0.0,"issued":374,"nearby":0,"pattern":"column","phase":"relax","planned":394.358212494729,"time":156.599999999996}
DIRECTOR {"alive":38,"curve":436.499999999982,"damage":32.8002652225495,"exclusive":true,"intensity":0.0,"issued":395,"nearby":0,"pattern":"column","phase":"scout","planned":414.624879161395,"time":161.666666666663}
DIRECTOR {"alive":51,"curve":456.766666666648,"damage":32.8002652225495,"exclusive":true,"intensity":0.0,"issued":417,"nearby":0,"pattern":"column","phase":"scout","planned":434.89154582806,"time":166.733333333329}
DIRECTOR {"alive":67,"curve":477.033333333313,"damage":32.8002652225495,"exclusive":true,"intensity":0.0,"issued":432,"nearby":0,"pattern":"column","phase":"build","planned":455.158212494726,"time":171.799999999995}
ACTIVITY event=success kind=supply time=174.40 age=21.53 pos=(1832.0, 504.0) offered=2 success=2 failed=0 rewards=2
LOOT СНАБЖЕНИЕ: module slot=1 rare=false
DIRECTOR {"alive":61,"curve":497.299999999979,"damage":32.8002652225495,"exclusive":false,"intensity":0.00833333333333333,"issued":445,"nearby":0,"pattern":"rush","phase":"build","planned":477.949789401595,"time":176.866666666662}
SIM 03:00 level=8 kills=415 xp=339/450 credits=21/28 credits_left=21 zombies=65 kinds=65/0/0/0 elites=0 elites_spawned=0 crates=0 nades=5 dmg_taken=33 peak=110 fps=208 | АК-С L2 Стан1 [Дето1] | Мясник L2 Стан1 [Цепь1] | Игла L1 Стан1 [] | Кольт L1 Стан1 []
DIRECTOR {"alive":61,"curve":517.566666666644,"damage":32.8002652225495,"exclusive":false,"intensity":0.0,"issued":461,"nearby":0,"pattern":"rush","phase":"build","planned":503.54811388537,"time":181.933333333328}
PICK lvl=9 { "type": "module", "id": 0, "rare": false } slot=2 of ["module", "passive", "passive"]
DIRECTOR {"alive":72,"curve":537.83333333331,"damage":32.8002652225495,"exclusive":false,"intensity":0.0,"issued":492,"nearby":0,"pattern":"rush","phase":"build","planned":529.143854860226,"time":186.999999999995}
DIRECTOR {"alive":92,"curve":558.099999999975,"damage":32.8002652225495,"exclusive":false,"intensity":0.0,"issued":517,"nearby":0,"pattern":"rush","phase":"build","planned":554.758972151977,"time":192.066666666661}
DIRECTOR {"alive":61,"curve":578.366666666641,"damage":32.8002652225495,"exclusive":false,"intensity":0.05,"issued":541,"nearby":0,"pattern":"rush","phase":"peak","planned":583.398353525766,"time":197.133333333327}
DIRECTOR {"alive":46,"curve":598.633333333306,"damage":32.8002652225495,"exclusive":false,"intensity":0.0666666666666667,"issued":567,"nearby":4,"pattern":"rush","phase":"peak","planned":613.760638537705,"time":202.199999999994}
PICK lvl=10 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["level", "passive", "module"]
DIRECTOR {"alive":63,"curve":618.899999999972,"damage":32.8002652225495,"exclusive":false,"intensity":0.00416666666666667,"issued":611,"nearby":0,"pattern":"rush","phase":"peak","planned":644.39909478156,"time":207.26666666666}
DIRECTOR {"alive":61,"curve":641.433333333306,"damage":32.8002652225495,"exclusive":false,"intensity":0.0,"issued":643,"nearby":0,"pattern":"rush","phase":"decay","planned":677.417659730991,"time":212.333333333326}
DIRECTOR {"alive":56,"curve":666.766666666642,"damage":32.8002652225495,"exclusive":false,"intensity":0.0,"issued":664,"nearby":0,"pattern":"rush","phase":"decay","planned":697.941752300175,"time":217.399999999993}
PICK lvl=11 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["passive", "level", "passive"]
DIRECTOR {"alive":35,"curve":692.099999999978,"damage":32.8002652225495,"exclusive":false,"intensity":0.0125,"issued":682,"nearby":0,"pattern":"rush","phase":"decay","planned":718.491801639972,"time":222.466666666659}
DIRECTOR {"alive":20,"curve":717.433333333315,"damage":32.8002652225495,"exclusive":false,"intensity":0.0375,"issued":693,"nearby":0,"pattern":"rush","phase":"relax","planned":729.404734987355,"time":227.533333333326}
DIRECTOR {"alive":0,"curve":742.766666666651,"damage":32.8002652225495,"exclusive":false,"intensity":0.0,"issued":693,"nearby":0,"pattern":"rush","phase":"relax","planned":735.921994785083,"time":232.599999999992}
DIRECTOR {"alive":13,"curve":768.099999999987,"damage":32.8002652225495,"exclusive":false,"intensity":0.0,"issued":706,"nearby":0,"pattern":"rush","phase":"relax","planned":742.3273888011,"time":237.666666666658}
SIM 04:00 level=11 kills=712 xp=674/765 credits=43/43 credits_left=43 zombies=13 kinds=10/0/3/0 elites=0 elites_spawned=0 crates=0 nades=8 dmg_taken=33 peak=92 fps=170 | АК-С L2 Стан1 [Дето1] | Мясник L2 Стан1 [Цепь1] | Игла L2 Стан1 [Рико1] | Кольт L1 Стан1 []
DIRECTOR {"alive":25,"curve":796.099999999987,"damage":32.8002652225495,"exclusive":false,"intensity":0.0,"issued":718,"nearby":0,"pattern":"ambush","phase":"scout","planned":759.116263643075,"time":242.733333333325}
DIRECTOR {"alive":50,"curve":826.499999999986,"damage":32.8002652225495,"exclusive":false,"intensity":0.0,"issued":743,"nearby":0,"pattern":"ambush","phase":"scout","planned":785.250271228412,"time":247.799999999991}
PICK lvl=12 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["ammo", "passive", "module"]
DIRECTOR {"alive":81,"curve":856.899999999984,"damage":32.8002652225495,"exclusive":false,"intensity":0.0,"issued":781,"nearby":0,"pattern":"ambush","phase":"build","planned":818.167175568912,"time":252.866666666657}
DIRECTOR {"alive":94,"curve":887.299999999982,"damage":32.8002652225495,"exclusive":false,"intensity":0.00833333333333333,"issued":823,"nearby":0,"pattern":"ambush","phase":"build","planned":856.570475189648,"time":257.933333333324}
DIRECTOR {"alive":96,"curve":917.69999999998,"damage":69.3002652225492,"exclusive":false,"intensity":0.3125,"issued":838,"nearby":0,"pattern":"ambush","phase":"build","planned":894.195331278987,"time":262.99999999999}
DIRECTOR {"alive":111,"curve":948.099999999979,"damage":105.958598555882,"exclusive":false,"intensity":0.3,"issued":867,"nearby":0,"pattern":"ambush","phase":"build","planned":931.541168404989,"time":268.066666666657}
DIRECTOR {"alive":135,"curve":978.499999999977,"damage":105.958598555882,"exclusive":false,"intensity":0.0375,"issued":902,"nearby":0,"pattern":"ambush","phase":"build","planned":968.923336125176,"time":273.133333333323}
DIRECTOR {"alive":100,"curve":1008.89999999998,"damage":105.958598555882,"exclusive":false,"intensity":0.08125,"issued":943,"nearby":2,"pattern":"ambush","phase":"peak","planned":1013.23531041932,"time":278.199999999989}
PICK lvl=13 { "type": "module", "id": 5, "rare": false } slot=1 of ["ammo", "module", "level"]
DIRECTOR {"alive":92,"curve":1039.29999999998,"damage":105.958598555882,"exclusive":false,"intensity":0.05,"issued":989,"nearby":0,"pattern":"ambush","phase":"peak","planned":1059.20342230301,"time":283.266666666656}
DIRECTOR {"alive":36,"curve":1069.69999999998,"damage":105.958598555882,"exclusive":true,"intensity":0.05,"issued":1025,"nearby":0,"pattern":"ambush","phase":"peak","planned":1095.11759718713,"time":288.333333333322}
DIRECTOR {"alive":46,"curve":1100.09999999999,"damage":105.958598555882,"exclusive":true,"intensity":0.0,"issued":1054,"nearby":0,"pattern":"ambush","phase":"decay","planned":1125.51759718714,"time":293.399999999988}
PICK lvl=14 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["level", "level", "passive"]
DIRECTOR {"alive":45,"curve":1130.5,"damage":105.958598555882,"exclusive":true,"intensity":0.025,"issued":1083,"nearby":0,"pattern":"ambush","phase":"decay","planned":1155.91759718714,"time":298.466666666655}
TRADER 0 at 05:00 credits_left=30 bought=["passive(40)"]
SIM 05:00 level=14 kills=1064 xp=1139/1243 credits=70/81 credits_left=30 zombies=52 kinds=43/0/9/0 elites=0 elites_spawned=0 crates=0 nades=10 dmg_taken=106 peak=144 fps=160 | АК-С L2 Стан1 [Дето1] | Мясник L2 Стан1 [Цепь2] | Игла L2 Стан1 [Рико1] | Кольт L1 Стан1 []
DIRECTORSHOT live=true time=300.066666666655 path=hd1_fight_5min.png
DIRECTOR {"alive":52,"curve":1164.36666666667,"damage":105.958598555882,"exclusive":true,"intensity":0.00416666666666667,"issued":1120,"nearby":0,"pattern":"ambush","phase":"decay","planned":1189.78426385381,"time":303.533333333321}
DIRECTOR {"alive":36,"curve":1199.83333333334,"damage":105.958598555882,"exclusive":true,"intensity":0.05,"issued":1156,"nearby":0,"pattern":"ambush","phase":"relax","planned":1225.25093052048,"time":308.599999999988}
DIRECTOR {"alive":12,"curve":1235.30000000001,"damage":121.20460552152,"exclusive":true,"intensity":0.3,"issued":1194,"nearby":0,"pattern":"ambush","phase":"relax","planned":1260.71759718715,"time":313.666666666654}
PICK lvl=15 { "type": "module", "id": 5, "rare": false } slot=1 of ["module", "module", "passive"]
DIRECTOR {"alive":9,"curve":1270.76666666668,"damage":121.20460552152,"exclusive":false,"intensity":0.0,"issued":1203,"nearby":0,"pattern":"column","phase":"relax","planned":1279.09117240839,"time":318.73333333332}
DIRECTOR {"alive":26,"curve":1306.23333333334,"damage":121.20460552152,"exclusive":false,"intensity":0.0166666666666667,"issued":1232,"nearby":0,"pattern":"rush","phase":"scout","planned":1303.92673583022,"time":323.799999999987}
ACTIVITY event=start kind=fuel time=328.07 age=0.00 pos=(1633.895, 565.4966) offered=3 success=2 failed=0 rewards=2
DIRECTOR {"alive":30,"curve":1341.70000000001,"damage":121.20460552152,"exclusive":true,"intensity":0.0,"issued":1256,"nearby":0,"pattern":"rush","phase":"scout","planned":1335.16557948804,"time":328.866666666653}
DIRECTOR {"alive":71,"curve":1377.16666666668,"damage":121.20460552152,"exclusive":true,"intensity":0.0,"issued":1296,"nearby":0,"pattern":"rush","phase":"build","planned":1370.63224615471,"time":333.93333333332}
DIRECTOR {"alive":84,"curve":1412.63333333335,"damage":121.20460552152,"exclusive":true,"intensity":0.0125,"issued":1323,"nearby":0,"pattern":"rush","phase":"build","planned":1406.09891282138,"time":338.999999999986}
ACTIVITY event=success kind=fuel time=341.13 age=13.07 pos=(1633.895, 565.4966) offered=3 success=3 failed=0 rewards=3
DIRECTOR {"alive":77,"curve":1448.10000000002,"damage":146.974242926703,"exclusive":false,"intensity":0.3375,"issued":1343,"nearby":0,"pattern":"ring","phase":"build","planned":1445.89376244035,"time":344.066666666652}
DIRECTOR {"alive":74,"curve":1483.56666666669,"damage":201.419275046454,"exclusive":false,"intensity":0.304166666666667,"issued":1381,"nearby":0,"pattern":"tide","phase":"build","planned":1489.01518254851,"time":349.133333333319}
PICK lvl=16 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["module", "ammo", "level"]
DIRECTOR {"alive":76,"curve":1519.03333333336,"damage":216.14897418128,"exclusive":false,"intensity":0.352083333333333,"issued":1414,"nearby":2,"pattern":"tide","phase":"peak","planned":1532.27796057211,"time":354.199999999985}
DIRECTOR {"alive":113,"curve":1554.50000000003,"damage":216.14897418128,"exclusive":false,"intensity":0.0125,"issued":1462,"nearby":0,"pattern":"tide","phase":"peak","planned":1583.40908594085,"time":359.266666666651}
SIM 06:00 level=16 kills=1381 xp=1535/1704 credits=122/164 credits_left=82 zombies=112 kinds=89/0/12/11 elites=0 elites_spawned=2 crates=0 nades=12 dmg_taken=251 peak=114 fps=138 | АК-С L3 Стан1 [Дето1] | Мясник L2 Стан1 [Цепь3] | Игла L2 Стан1 [Рико1] | Кольт L1 Стан1 []
DIRECTOR {"alive":132,"curve":1594.23333333336,"damage":276.839726210699,"exclusive":false,"intensity":0.325,"issued":1508,"nearby":0,"pattern":"tide","phase":"peak","planned":1640.2963756585,"time":364.333333333318}
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
DIRECTOR {"alive":134,"curve":1634.76666666669,"damage":290.697853804694,"exclusive":false,"intensity":0.308333333333333,"issued":1551,"nearby":0,"pattern":"tide","phase":"peak","planned":1698.06964212851,"time":369.399999999984}
PICK lvl=17 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "passive", "module"]
DIRECTOR {"alive":144,"curve":1675.30000000002,"damage":321.877812148199,"exclusive":false,"intensity":0.3,"issued":1589,"nearby":0,"pattern":"tide","phase":"decay","planned":1744.46346204704,"time":374.466666666651}
DIRECTOR {"alive":132,"curve":1715.83333333335,"damage":321.877812148199,"exclusive":false,"intensity":0.04375,"issued":1624,"nearby":2,"pattern":"tide","phase":"decay","planned":1778.55400144864,"time":379.533333333317}
DIRECTOR {"alive":122,"curve":1756.36666666668,"damage":321.877812148199,"exclusive":false,"intensity":0.0458333333333333,"issued":1664,"nearby":0,"pattern":"tide","phase":"relax","planned":1809.12195734132,"time":384.599999999983}
DIRECTOR {"alive":99,"curve":1796.90000000001,"damage":349.160832167731,"exclusive":false,"intensity":0.332291666666667,"issued":1672,"nearby":1,"pattern":"tide","phase":"relax","planned":1820.95497251199,"time":389.66666666665}
DIRECTOR {"alive":103,"curve":1837.43333333335,"damage":351.660832167731,"exclusive":false,"intensity":0.3,"issued":1688,"nearby":0,"pattern":"tide","phase":"relax","planned":1836.36038717697,"time":394.733333333316}
DIRECTOR {"alive":113,"curve":1877.96666666668,"damage":351.660832167731,"exclusive":false,"intensity":0.0,"issued":1706,"nearby":0,"pattern":"tide","phase":"relax","planned":1850.87544153853,"time":399.799999999982}
PICK lvl=18 { "type": "module", "id": 1, "rare": true } slot=0 of ["level", "module", "level"]
DIRECTOR {"alive":137,"curve":1918.50000000001,"damage":351.660832167731,"exclusive":false,"intensity":0.0,"issued":1738,"nearby":0,"pattern":"flank","phase":"scout","planned":1884.43719796499,"time":404.866666666649}
DIRECTOR {"alive":163,"curve":1959.03333333334,"damage":351.660832167731,"exclusive":false,"intensity":0.0,"issued":1770,"nearby":0,"pattern":"flank","phase":"scout","planned":1919.28802982339,"time":409.933333333315}
DIRECTOR {"alive":196,"curve":1999.56666666667,"damage":351.660832167731,"exclusive":false,"intensity":0.0375,"issued":1817,"nearby":0,"pattern":"flank","phase":"build","planned":1970.08157610798,"time":414.999999999982}
DIRECTOR {"alive":177,"curve":2040.1,"damage":351.660832167731,"exclusive":false,"intensity":0.00416666666666667,"issued":1851,"nearby":0,"pattern":"flank","phase":"build","planned":2021.14065322555,"time":420.066666666648}
SIM 07:00 level=18 kills=1707 xp=2022/2197 credits=193/238 credits_left=153 zombies=177 kinds=138/0/22/17 elites=0 elites_spawned=4 crates=0 nades=16 dmg_taken=352 peak=205 fps=188 | АК-С L3 Крио1 [Дето1,Проб1] | Мясник L2 Стан1 [Цепь3] | Игла L2 Стан1 [Рико1] | Кольт L2 Стан1 []
ALARM_EVENT warn time=07:00
ALARM_EVENT start time=07:03
DIRECTOR {"alive":213,"curve":2112.63333333333,"damage":399.306090816523,"exclusive":true,"intensity":0.460416666666667,"issued":1920,"nearby":10,"pattern":"flank","phase":"build","planned":2093.81458228862,"time":425.133333333314}
DIRECTOR {"alive":201,"curve":2234.23333333332,"damage":468.530413470347,"exclusive":true,"intensity":0.3375,"issued":2044,"nearby":0,"pattern":"flank","phase":"build","planned":2215.41458228861,"time":430.199999999981}
PICK lvl=19 { "type": "module", "id": 4, "rare": false } slot=3 of ["passive", "module", "level"]
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=3 rare=true
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
DIRECTOR {"alive":208,"curve":2355.83333333332,"damage":635.761058510222,"exclusive":true,"intensity":0.365625,"issued":2165,"nearby":1,"pattern":"flank","phase":"peak","planned":2337.0145822886,"time":435.266666666647}
PICK lvl=20 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["level", "passive", "ammo"]
DIRECTOR {"alive":156,"curve":2477.43333333331,"damage":746.751771629729,"exclusive":true,"intensity":0.325,"issued":2286,"nearby":0,"pattern":"flank","phase":"peak","planned":2458.6145822886,"time":440.333333333313}
PICK lvl=21 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["passive", "module", "passive"]
DIRECTOR {"alive":222,"curve":2599.0333333333,"damage":749.251771629729,"exclusive":true,"intensity":0.3125,"issued":2403,"nearby":0,"pattern":"flank","phase":"peak","planned":2580.21458228859,"time":445.39999999998}
PICK lvl=22 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["passive", "module", "ammo"]
DIRECTOR {"alive":302,"curve":2720.6333333333,"damage":749.251771629729,"exclusive":true,"intensity":0.0166666666666667,"issued":2526,"nearby":0,"pattern":"flank","phase":"peak","planned":2701.81458228858,"time":450.466666666646}
ALARM_EVENT finish container=(2124.128, 857.1032) time=07:33
CONTAINER dropped pos=(2124.128, 857.1032) time=07:33
ALARM rewards mult=2 xp=1778 credits=290
LOOT СБРОС СНАБЖЕНИЯ: module slot=3 rare=false
CONTAINER picked time=07:34 crates=1
DIRECTOR {"alive":270,"curve":2806.23333333329,"damage":749.251771629729,"exclusive":false,"intensity":0.0916666666666667,"issued":2595,"nearby":4,"pattern":"tide","phase":"decay","planned":2783.44186010147,"time":455.533333333313}
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
DIRECTOR {"alive":244,"curve":2851.83333333328,"damage":751.751771629729,"exclusive":false,"intensity":0.35,"issued":2625,"nearby":0,"pattern":"tide","phase":"decay","planned":2820.71753171967,"time":460.599999999979}
PICK lvl=23 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "level", "ammo"]
DIRECTOR {"alive":195,"curve":2897.43333333327,"damage":759.251771629729,"exclusive":false,"intensity":0.3,"issued":2663,"nearby":0,"pattern":"tide","phase":"relax","planned":2852.68932249085,"time":465.666666666645}
DIRECTOR {"alive":164,"curve":2943.03333333327,"damage":766.751771629729,"exclusive":false,"intensity":0.320833333333333,"issued":2682,"nearby":0,"pattern":"tide","phase":"relax","planned":2870.23718247821,"time":470.733333333312}
PICK lvl=24 { "type": "module", "id": 5, "rare": false } slot=3 of ["ammo", "passive", "module"]
DIRECTOR {"alive":115,"curve":2988.63333333326,"damage":766.751771629729,"exclusive":false,"intensity":0.0,"issued":2690,"nearby":0,"pattern":"tide","phase":"relax","planned":2887.78709714319,"time":475.799999999978}
SIM 08:00 level=24 kills=2636 xp=3821/4445 credits=504/599 credits_left=464 zombies=112 kinds=88/0/19/5 elites=0 elites_spawned=10 crates=1 nades=20 dmg_taken=767 peak=323 fps=132 | АК-С L3 Стан1 [Дето1,Проб1] | Мясник L2 Стан1 [Цепь3] | Игла L2 Стан1 [Рико1] | Кольт L3 Стан1 [Сдво3,Цепь1]
DIRECTOR {"alive":118,"curve":3035.83333333325,"damage":766.751771629729,"exclusive":false,"intensity":0.0,"issued":2714,"nearby":0,"pattern":"column","phase":"scout","planned":2905.20425264255,"time":480.866666666645}
DIRECTOR {"alive":128,"curve":3091.56666666657,"damage":766.751771629729,"exclusive":false,"intensity":0.0125,"issued":2760,"nearby":0,"pattern":"column","phase":"scout","planned":2953.17885904795,"time":485.933333333311}
DIRECTOR {"alive":164,"curve":3147.29999999989,"damage":780.839845360198,"exclusive":false,"intensity":0.315625,"issued":2814,"nearby":1,"pattern":"column","phase":"build","planned":3004.89254666208,"time":490.999999999977}
DIRECTOR {"alive":213,"curve":3203.0333333332,"damage":852.612757385649,"exclusive":false,"intensity":0.319791666666667,"issued":2878,"nearby":1,"pattern":"column","phase":"build","planned":3072.74580658271,"time":496.066666666644}
DIRECTOR {"alive":241,"curve":3258.76666666652,"damage":1076.40631255634,"exclusive":false,"intensity":0.38125,"issued":2954,"nearby":2,"pattern":"column","phase":"build","planned":3140.04534788064,"time":501.13333333331}
DIRECTOR {"alive":240,"curve":3314.49999999984,"damage":1192.30360995777,"exclusive":false,"intensity":0.319791666666667,"issued":3019,"nearby":1,"pattern":"column","phase":"build","planned":3207.48787025036,"time":506.199999999976}
DIRECTOR {"alive":218,"curve":3370.23333333316,"damage":1229.14811717518,"exclusive":false,"intensity":0.353125,"issued":3087,"nearby":1,"pattern":"column","phase":"build","planned":3275.22212729138,"time":511.266666666643}
PICK lvl=25 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["module", "module", "passive"]
DIRECTOR {"alive":135,"curve":3425.23333333314,"damage":1236.64811717518,"exclusive":false,"intensity":0.3,"issued":3155,"nearby":0,"pattern":"column","phase":"peak","planned":3347.05757379019,"time":516.266666666646}
DIRECTOR {"alive":185,"curve":3480.23333333312,"damage":1239.14811717518,"exclusive":false,"intensity":0.3,"issued":3240,"nearby":0,"pattern":"column","phase":"peak","planned":3425.47714704486,"time":521.26666666665}
DIRECTOR {"alive":202,"curve":3535.23333333311,"damage":1239.14811717518,"exclusive":false,"intensity":0.0,"issued":3313,"nearby":0,"pattern":"column","phase":"peak","planned":3507.35170456699,"time":526.266666666654}
DIRECTOR {"alive":224,"curve":3590.23333333309,"damage":1239.14811717518,"exclusive":false,"intensity":0.1,"issued":3400,"nearby":0,"pattern":"column","phase":"peak","planned":3589.19150369607,"time":531.266666666658}
DIRECTOR {"alive":146,"curve":3645.23333333308,"damage":1239.14811717518,"exclusive":true,"intensity":0.125,"issued":3451,"nearby":0,"pattern":"column","phase":"decay","planned":3642.60373736652,"time":536.266666666662}
CALM 09:00 removed=129 left=0
TRADER 1 at 09:00 credits_left=87 bought=["passive(60)", "level(75)", "level(75)", "level(75)", "module(150)"]
SIM 09:00 level=25 kills=3404 xp=4316/5537 credits=562/723 credits_left=87 zombies=129 kinds=101/3/16/9 elites=0 elites_spawned=12 crates=1 nades=22 dmg_taken=1239 peak=274 fps=143 | АК-С L3 Стан1 [Дето1,Проб2] | Мясник L3 Стан1 [Цепь3] | Игла L3 Стан1 [Рико1] | Кольт L4 Стан1 [Сдво3,Цепь1]
DIRECTOR {"alive":1,"curve":3690.63333333306,"damage":1239.14811717518,"exclusive":true,"intensity":0.1,"issued":3492,"nearby":0,"pattern":"column","phase":"decay","planned":3688.0037373665,"time":541.266666666666}
DIRECTOR {"alive":20,"curve":3705.63333333305,"damage":1239.14811717518,"exclusive":true,"intensity":0.1,"issued":3512,"nearby":0,"pattern":"column","phase":"relax","planned":3703.00373736649,"time":546.26666666667}
DIRECTOR {"alive":23,"curve":3720.63333333303,"damage":1239.14811717518,"exclusive":true,"intensity":0.1125,"issued":3524,"nearby":0,"pattern":"column","phase":"relax","planned":3718.00373736648,"time":551.266666666674}
DIRECTOR {"alive":27,"curve":3735.63333333302,"damage":1239.14811717518,"exclusive":true,"intensity":0.1,"issued":3539,"nearby":0,"pattern":"column","phase":"relax","planned":3733.00373736646,"time":556.266666666678}
DIRECTOR {"alive":20,"curve":3750.63333333301,"damage":1239.14811717518,"exclusive":true,"intensity":0.1,"issued":3560,"nearby":0,"pattern":"column","phase":"scout","planned":3748.00373736645,"time":561.266666666682}
DIRECTOR {"alive":14,"curve":3765.63333333299,"damage":1239.14811717518,"exclusive":true,"intensity":0.104166666666667,"issued":3574,"nearby":0,"pattern":"column","phase":"scout","planned":3763.00373736644,"time":566.266666666686}
DIRECTOR {"alive":5,"curve":3781.89999999965,"damage":1239.14811717518,"exclusive":true,"intensity":0.0125,"issued":3583,"nearby":0,"pattern":"column","phase":"build","planned":3779.2704040331,"time":571.26666666669}
PICK lvl=26 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["ammo", "passive", "level"]
DIRECTOR {"alive":27,"curve":3801.89999999967,"damage":1239.14811717518,"exclusive":true,"intensity":0.0,"issued":3610,"nearby":0,"pattern":"column","phase":"build","planned":3799.27040403311,"time":576.266666666694}
PICK lvl=27 { "type": "module", "id": 2, "rare": false } slot=1 of ["module", "level", "passive"]
DIRECTOR {"alive":29,"curve":3821.89999999969,"damage":1239.14811717518,"exclusive":true,"intensity":0.0375,"issued":3625,"nearby":0,"pattern":"column","phase":"build","planned":3819.27040403313,"time":581.266666666698}
DIRECTOR {"alive":25,"curve":3841.8999999997,"damage":1239.14811717518,"exclusive":true,"intensity":0.0125,"issued":3647,"nearby":0,"pattern":"column","phase":"build","planned":3839.27040403314,"time":586.266666666702}
DIRECTOR {"alive":42,"curve":3861.89999999972,"damage":1239.14811717518,"exclusive":true,"intensity":0.0,"issued":3667,"nearby":0,"pattern":"column","phase":"build","planned":3859.27040403316,"time":591.266666666706}
DIRECTOR {"alive":58,"curve":3881.89999999973,"damage":1239.14811717518,"exclusive":true,"intensity":0.0,"issued":3689,"nearby":0,"pattern":"column","phase":"peak","planned":3879.27040403318,"time":596.26666666671}
BOSS spawn t=600.00 pos=(2421.982, 879.1459) hp=24000
SIM 10:00 level=27 kills=3560 xp=5289/5741 credits=695/755 credits_left=220 zombies=52 kinds=43/9/0/0 elites=0 elites_spawned=14 crates=1 nades=22 dmg_taken=1239 peak=58 fps=190 | АК-С L3 Стан1 [Дето1,Проб2] | Мясник L3 Стан1 [Цепь3,Спли1] | Игла L3 Стан1 [Рико1] | Кольт L4 Стан1 [Сдво3,Цепь1]
SIM summary kills=3560 peak=323 level=27 damage=1239.15 boss_alive=true
DIRECTOR summary curve=3896.83 planned=3894.20 issued=3698 dropped=133
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0
```
