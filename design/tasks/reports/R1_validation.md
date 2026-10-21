# R1 ? ????????? ??????? ????????

Godot_console.exe = `C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`.

godot_exclusive.sh = `C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh`. ??????? ?????: `C:/Users/Dev/Desktop/zera-r1`. ??????? ???????, ????? ???????, ????????????? ??????? `--log-file` ?????? `design/tasks/reports/R1*_engine.md`; ? ???????? ?????? ???? ???????? ???????????? stdout/stderr ????????.

## R1_import.md

```text
Godot_console.exe --headless --path . --import
```

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org



Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.

строка:2 знак:1

+ & 'C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-st ...

+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

[   0% ] [90m[1mupdate_scripts_classes[22m | Started Регистрация глобальных классов… (6 steps)[39m[0m

[   0% ] [90m[1mupdate_scripts_classes[22m | Effects[39m[0m

[  14% ] [90m[1mupdate_scripts_classes[22m | FloorDecals[39m[0m

[  28% ] [90m[1mupdate_scripts_classes[22m | [39m[0m

[  42% ] [90m[1mupdate_scripts_classes[22m | Gore[39m[0m

[  57% ] [90m[1mupdate_scripts_classes[22m | Horde[39m[0m

[  71% ] [90m[1mupdate_scripts_classes[22m | Player[39m[0m

[92m[ DONE ][39m [1mupdate_scripts_classes[22m

[0m

[   0% ] [90m[1mloading_editor_layout[22m | Started Загрузка редактора (5 steps)[39m[0m

[   0% ] [90m[1mloading_editor_layout[22m | Загрузка макета редактора…[39m[0m

[  16% ] [90m[1mloading_editor_layout[22m | Загрузка док-панели…[39m[0m

[92m[ DONE ][39m [1mloading_editor_layout[22m

[0m

ERROR: Cannot save file 'C:/Users/Dev/AppData/Roaming/Godot/editor_settings-4.7.tres'.

   at: save (scene/resources/resource_format_text.cpp:1768)

ERROR: Error saving editor settings to C:/Users/Dev/AppData/Roaming/Godot/editor_settings-4.7.tres

   at: save (editor/settings/editor_settings.cpp:1525)
```

## R1_before_bench.md

```text
bash godot_exclusive.sh Godot_console.exe --disable-vsync --path . -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1_before_bench.png
```

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 19:43:20

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics



bash : ERROR: Failed to read the root certificate store.

строка:2 знак:1

+ bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Use ...

+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException

    + FullyQualifiedErrorId : NativeCommandError

 

   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=987.41 seed=81073

BENCH frames=836 avg_fps=83.5 avg_frame_ms=11.97 worst_frame_ms=135.11 horde_ms=3.25 enemies=498 kills=1281

BENCH process_ms=21.21 physics_ms=31.80 draw_calls=698 objects=3346 gore=562 particles=975 wet=376

BENCH physics_avg_ms=16.84 hud_ms=0.438

BENCH screenshot: res://design/tasks/reports/r1_before_bench.png

WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).

   at: cleanup (core/object/object.cpp:2536)
```

## R1_before_bench2.md

```text
bash godot_exclusive.sh Godot_console.exe --disable-vsync --path . -- --loadout --bench=500 --fresh-save (HEAD + test-only GPU counters)
```

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 19:56:48

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics



bash : ERROR: Failed to read the root certificate store.

строка:2 знак:27

+ ... n in 2,3) { bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusi ...

+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException

    + FullyQualifiedErrorId : NativeCommandError

 

   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=383.24 seed=81073

BENCH frames=1232 avg_fps=123.1 avg_frame_ms=8.13 worst_frame_ms=115.56 horde_ms=3.13 enemies=498 kills=910

BENCH process_ms=12.54 physics_ms=8.46 draw_calls=1112 objects=3166 gore=900 particles=3000 wet=146

BENCH physics_avg_ms=14.39 hud_ms=0.325

R1PROFILE legacy static=140602330 video=470962176 gpu_last_ms=4.412 stamps=67296

WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).

   at: cleanup (core/object/object.cpp:2536)
```

## R1_before_bench3.md

```text
bash godot_exclusive.sh Godot_console.exe --disable-vsync --path . -- --loadout --bench=500 --fresh-save (HEAD + test-only GPU counters)
```

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 19:57:08

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics



bash : ERROR: Failed to read the root certificate store.

строка:2 знак:27

+ ... n in 2,3) { bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusi ...

+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException

    + FullyQualifiedErrorId : NativeCommandError

 

   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=320.45 seed=81073

BENCH frames=1210 avg_fps=121.0 avg_frame_ms=8.27 worst_frame_ms=39.09 horde_ms=2.88 enemies=498 kills=979

BENCH process_ms=11.88 physics_ms=12.08 draw_calls=539 objects=3249 gore=229 particles=695 wet=385

BENCH physics_avg_ms=13.36 hud_ms=0.292

R1PROFILE legacy static=140538077 video=470110208 gpu_last_ms=2.736 stamps=76652

WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).

   at: cleanup (core/object/object.cpp:2536)
```

## R1_before_shots.md

```text
bash godot_exclusive.sh Godot_console.exe --disable-vsync --path . -- --fresh-save --gore-shots --layout-seed=81073 --shot=res://design/tasks/reports/r1_before.png
```

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 19:45:32

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics



bash : ERROR: Failed to read the root certificate store.

строка:2 знак:1

+ bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Use ...

+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException

    + FullyQualifiedErrorId : NativeCommandError

 

   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=619.37 seed=81073

GORESTAND seconds=60 debris=44 peak=109 stamps=35017 pools=34 memory=132116841 video=449073152

GORESTAND seconds=300 debris=44 peak=125 stamps=179978 pools=32 memory=132154485 video=449204224

GORESTAND screenshot: res://design/tasks/reports/r1_before_5min.png

GORESTAND seconds=480 debris=64 peak=125 stamps=288211 pools=29 memory=132194177 video=449466368

GORESTAND seconds=600 debris=24 peak=125 stamps=358268 pools=22 memory=132194553 video=448811008

GORESTAND screenshot: res://design/tasks/reports/r1_before_10min.png

GORESTAND complete seed=81073 deaths=7200 zoom=3 map=quarantine_checkpoint

WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).

   at: cleanup (core/object/object.cpp:2536)
```

## R1_checks.md

```text
Godot_console.exe --headless --path . -- --fresh-save --gore-checks
```

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org



Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.

строка:2 знак:1

+ & 'C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-st ...

+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException

    + FullyQualifiedErrorId : NativeCommandError

 

   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=222.75 seed=81073

R1CHECK pellets_one_reaction_full_damage=true

R1CHECK exit_spray=true

R1CHECK crawler_inertia=true

R1CHECK bounded_flood_2400_deaths=true

R1CHECK no_permanent_body_or_ash_stamps=true

R1CHECK all_remains_expire=true

R1CHECK ok=true remains_peak=200 stamps_queue=392 particles=0
```

## R1_obstacles.md

```text
Godot_console.exe --headless --path . -- --obstacles-test --fresh-save
```

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org



Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.

строка:2 знак:1

+ & 'C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-st ...

+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException

    + FullyQualifiedErrorId : NativeCommandError

 

   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=302.90 seed=81073

OBSTEST layout cars=27 barrels=20 objects=409 seed=81073

OBSTEST simulation seconds=10 alive=500 penetrations=0

OBSTEST simulation seconds=20 alive=500 penetrations=0

OBSTEST simulation seconds=30 alive=500 penetrations=0

OBSTEST simulation seconds=40 alive=500 penetrations=0

OBSTEST simulation seconds=50 alive=500 penetrations=0

OBSTEST simulation seconds=60 alive=500 penetrations=0

OBSTEST wall arrived=500/500 nav_worst_us=290

OBSTEST ok=true penetrations=0 arrived=500 detonations=3 blood_events=2
```

## R1_campaign.md

```text
Godot_console.exe --headless --path . -- --campaign-test
```

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org



Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.

строка:2 знак:1

+ & 'C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-st ...

+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

CAMPAIGNTEST unit8_all_lost_recoverable=true

CAMPAIGNTEST unit9_explicit_symmetric_graph=true

CAMPAIGNTEST unit10_boss_unlock_content_gate=true

CAMPAIGNTEST validation_range=true

CAMPAIGNTEST validation_fraction=true

CAMPAIGNTEST validation_unknown_region=true

CAMPAIGNTEST validation_unknown_template=true

CAMPAIGNTEST validation_initial=true

CAMPAIGNTEST validation_json_roundtrip=true

CAMPAIGNTEST start_persisted_pending_before_scene=true

CAMPAIGNTEST integration1_victory_one_save_rewards_world=true

CAMPAIGNTEST integration1_idempotent_same_report=true

CAMPAIGNTEST report_full_changes_causes_priority=true

CAMPAIGNTEST integration3_results_reopen=true

CAMPAIGNTEST integration2_defeat_once=true

CAMPAIGNTEST integration3_legacy_result_gets_run_id_once=true

CAMPAIGNTEST idempotent_older_run_report=true

CAMPAIGNTEST integration5_v1_v2_profile_preserved=true

CAMPAIGNTEST integration5_file_migration_not_corrupt=true

Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в res://tmp/c1_migration.json.campaign-bad-3484965

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

       [0] save (res://scripts/meta.gd:361)

       [1] start_operation (res://scripts/campaign/campaign.gd:57)

       [2] _integration (res://scripts/campaign/campaign_test.gd:256)

       [3] run (res://scripts/campaign/campaign_test.gd:22)

       [4] _ready (res://scripts/game.gd:662)

CAMPAIGNTEST failed_start_no_scene_config=true

CAMPAIGNTEST new_campaign_keeps_profile=true

CAMPAIGNSIM campaigns=200 turns=40 per_strategy; first_lost=41 means censored; critical=infection>=60

strategy | first_lost_mean | critical_share | object7_turn | deadlocks | collapse | recovery_delta

always_win | 40.65 | 0.0041 | 2.65 (200/200) | 0 | 0 | 1.41

half_wins | 22.99 | 0.1401 | 6.34 (200/200) | 0 | 0 | 196.04

frequent_defeat | 5.05 | 0.6646 | 15.38 (168/200) | 0 | 0 | 313.91

reddest | 38.52 | 0.0023 | 3.74 (200/200) | 0 | 0 | 2.96

best_reward | 37.77 | 0.0123 | 1.29 (200/200) | 0 | 0 | 38.67

nest_hunter | 38.66 | 0.0025 | 1.41 (200/200) | 0 | 0 | 3.25

safe_clearance | 21.97 | 0.0970 | -- | 0 | 0 | 73.00

random | 30.81 | 0.0372 | 4.73 (200/200) | 0 | 0 | 43.96

CAMPAIGNTEST simulation_no_deadlocks=true

CAMPAIGNTEST simulation_no_irreversible_collapse=true

CAMPAIGNTEST checks=42 failures=0

CAMPAIGNTEST ok=true
```

## R1_sim.md

```text
Godot_console.exe --headless --path . -- --sim=600 --fresh-save
```

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org



Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.

строка:2 знак:1

+ & 'C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-st ...

+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException

    + FullyQualifiedErrorId : NativeCommandError

 

   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=204.29 seed=81073

SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s

PICK lvl=2 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["weapon", "module", "level"]

PICK lvl=3 { "type": "passive", "id": 5, "rare": false } slot=-1 of ["level", "passive", "passive"]

PICK lvl=4 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["weapon", "weapon", "level"]

SIM 01:00 level=4 kills=66 xp=62/66 credits=3/4 credits_left=3 zombies=23 kinds=23/0/0/0 elites=0 elites_spawned=0 crates=0 nades=3 dmg_taken=150 peak=41 fps=145 | АК-С L3 Стан1 []

PICK lvl=5 { "type": "module", "id": 3, "rare": false } slot=0 of ["module", "ammo", "module"]

PICK lvl=6 { "type": "module", "id": 1, "rare": false } slot=0 of ["passive", "level", "module"]

SIM 02:00 level=6 kills=189 xp=185/189 credits=13/13 credits_left=13 zombies=79 kinds=79/0/0/0 elites=0 elites_spawned=0 crates=0 nades=8 dmg_taken=567 peak=89 fps=145 | АК-С L3 Стан1 [Дето1,Проб1]

PICK lvl=7 { "type": "module", "id": 1, "rare": false } slot=0 of ["level", "ammo", "module"]

PICK lvl=8 { "type": "weapon", "id": 4, "rare": false } slot=-1 of ["level", "weapon", "module"]

PICK lvl=9 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["level", "passive", "module"]

SIM 03:00 level=9 kills=473 xp=427/473 credits=30/34 credits_left=30 zombies=31 kinds=31/0/0/0 elites=0 elites_spawned=0 crates=0 nades=13 dmg_taken=1527 peak=94 fps=145 | АК-С L3 Стан1 [Дето1,Проб2] | Кольт L1 Стан1 []

PICK lvl=10 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "ammo", "level"]

PICK lvl=11 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "weapon", "level"]

SIM 04:00 level=11 kills=722 xp=665/743 credits=46/56 credits_left=46 zombies=47 kinds=38/0/9/0 elites=0 elites_spawned=0 crates=0 nades=15 dmg_taken=1562 peak=86 fps=145 | АК-С L4 Стан1 [Дето1,Проб2] | Кольт L2 Стан1 []

PICK lvl=12 { "type": "weapon", "id": 3, "rare": false } slot=-1 of ["weapon", "weapon", "ammo"]

PICK lvl=13 { "type": "module", "id": 5, "rare": false } slot=1 of ["module", "level", "module"]

PICK lvl=14 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["weapon", "level", "ammo"]

TRADER 0 at 05:00 credits_left=28 bought=["weapon(60)"]

SIM 05:00 level=14 kills=1082 xp=1137/1202 credits=88/92 credits_left=28 zombies=58 kinds=42/10/6/0 elites=0 elites_spawned=0 crates=0 nades=17 dmg_taken=1604 peak=126 fps=145 | АК-С L4 Эксп1 [Дето1,Проб2] | Кольт L2 Стан1 [Цепь1] | Гром L1 Стан1 [] | Мосинка L1 Стан1 []

PICK lvl=15 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "level", "module"]

PICK lvl=16 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["module", "passive", "module"]

SIM 06:00 level=16 kills=1502 xp=1480/1768 credits=127/154 credits_left=67 zombies=55 kinds=39/9/4/3 elites=1 elites_spawned=2 crates=0 nades=20 dmg_taken=1700 peak=132 fps=145 | АК-С L5 Эксп1 [Дето1,Проб2] | Кольт L2 Стан1 [Цепь1] | Гром L1 Стан1 [] | Мосинка L1 Стан1 []

LOOT РЕДКАЯ ДЕТАЛЬ: module slot=0 rare=true

LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true

PICK lvl=17 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["module", "passive", "module"]

PICK lvl=18 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["ammo", "module", "module"]

PICK lvl=19 { "type": "module", "id": 0, "rare": false } slot=2 of ["level", "level", "module"]

SIM 07:00 level=19 kills=2023 xp=2240/2546 credits=219/259 credits_left=159 zombies=10 kinds=5/0/3/2 elites=0 elites_spawned=4 crates=1 nades=22 dmg_taken=1785 peak=65 fps=145 | АК-С L5 Крио1 [Дето1,Проб2,Сдво1] | Кольт L2 Стан1 [Цепь1] | Гром L1 Стан1 [Рико1] | Мосинка L1 Стан1 []

ALARM_EVENT warn time=07:00

ALARM_EVENT start time=07:03

LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true

PICK lvl=20 { "type": "module", "id": 0, "rare": false } slot=2 of ["module", "level", "module"]

LOOT РЕДКАЯ ДЕТАЛЬ: module slot=0 rare=true

PICK lvl=21 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["level", "passive", "module"]

PICK lvl=22 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["ammo", "level", "passive"]

ALARM_EVENT finish container=(2074.756, 499.5424) time=07:33

CONTAINER dropped pos=(2074.756, 499.5424) time=07:33

ALARM rewards mult=2 xp=1784 credits=210

LOOT СБРОС СНАБЖЕНИЯ: module slot=0 rare=true

CONTAINER picked time=07:34 crates=3

PICK lvl=23 { "type": "module", "id": 2, "rare": false } slot=3 of ["module", "passive", "level"]

PICK lvl=24 { "type": "module", "id": 0, "rare": true } slot=2 of ["module", "module", "passive"]

PICK lvl=25 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "module", "level"]

PICK lvl=26 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["level", "passive", "ammo"]

SIM 08:00 level=26 kills=3024 xp=4551/4871 credits=511/539 credits_left=451 zombies=11 kinds=7/0/4/0 elites=0 elites_spawned=10 crates=3 nades=25 dmg_taken=2155 peak=110 fps=145 | АК-С L5 Стан1 [Дето2,Проб3,Сдво1] | Кольт L3 Стан1 [Цепь1] | Гром L1 Стан1 [Рико3] | Мосинка L1 Стан1 [Спли1]

PICK lvl=27 { "type": "module", "id": 5, "rare": true } slot=1 of ["level", "module", "module"]

PICK lvl=28 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["level", "module", "level"]

CALM 09:00 removed=28 left=0

TRADER 1 at 09:00 credits_left=135 bought=["module(150)", "level(75)", "level(75)", "passive(60)", "ammo(60)"]

SIM 09:00 level=28 kills=3669 xp=5428/5804 credits=615/665 credits_left=135 zombies=28 kinds=23/0/2/3 elites=0 elites_spawned=12 crates=3 nades=28 dmg_taken=2198 peak=60 fps=145 | АК-С L5 Эксп1 [Дето2,Проб3,Сдво1] | Кольт L4 Стан1 [Цепь3] | Гром L3 Стан1 [Рико3] | Мосинка L1 Стан1 [Спли1]

LOOT РЕДКАЯ ДЕТАЛЬ: module slot=2 rare=true

PICK lvl=29 { "type": "module", "id": 5, "rare": false } slot=2 of ["level", "module", "level"]

BOSS spawn t=600.00 pos=(2530.986, 809.7615) hp=24000

SIM 10:00 level=29 kills=3863 xp=5868/6046 credits=677/698 credits_left=197 zombies=20 kinds=20/0/0/0 elites=0 elites_spawned=14 crates=4 nades=32 dmg_taken=2198 peak=21 fps=145 | АК-С L5 Эксп1 [Дето2,Проб3,Сдво1] | Кольт L4 Стан1 [Цепь3] | Гром L3 Стан1 [Рико3,Цепь2] | Мосинка L1 Стан1 [Спли1]

SIM summary kills=3863 peak=132 level=29 damage=2198.26 boss_alive=true
```

## R1_meta2.md

```text
Godot_console.exe --headless --path . -- --meta-test --gore-report
```

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org



Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.

строка:2 знак:1

+ & 'C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-st ...

+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException

    + FullyQualifiedErrorId : NativeCommandError

 

   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=234.12 seed=81073

S7SETTINGS migration_v1_v3=true progress_preserved=true roundtrip=true sanitize=true temporary_save=true

Meta: сохранение повреждено или другой версии, копия в res://design/tasks/reports/R1_meta_save.md.bad-1792342487

Meta: сохранение повреждено или другой версии, копия в res://design/tasks/reports/R1_meta_save.md.bad-1792342487

Meta: сохранение повреждено или другой версии, копия в res://design/tasks/reports/R1_meta_save.md.bad-1792342487

Meta: сохранение повреждено или другой версии, копия в res://design/tasks/reports/R1_meta_save.md.bad-1792342487

Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в res://design/tasks/reports/R1_meta_save.md.campaign-bad-4139869

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

METATEST FAIL fan.different_targets задето целей: 4

METATEST trait fan (Ковбой): 6 выстрелов за 0.43 с по 4 разным целям, барабан пуст → перезарядка

METATEST trait steady (Оса): магазин 50, за 4 с 44 выстрелов, разброс +0.0° (ППШ за 1 с +21.0°)

METATEST trait lever (Винчестер): интервал 0.63 с, после убийства следующий выстрел через 0.23 с; урон 28.8 (Мосинка 48), темп 1.6/с

METATEST checks=257 failed=1

METATEST ok=false
```

## R1_meta_baseline.md

```text
Godot_console.exe --headless --path . -- --meta-test --gore-report (HEAD + identical fixture-path redirection)
```

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org



Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.

строка:2 знак:1

+ & 'C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-st ...

+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException

    + FullyQualifiedErrorId : NativeCommandError

 

   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=193.13 seed=81073

S7SETTINGS migration_v1_v3=true progress_preserved=true roundtrip=true sanitize=true temporary_save=true

Meta: сохранение повреждено или другой версии, копия в res://design/tasks/reports/R1_meta_save.md.bad-1792342599

Meta: сохранение повреждено или другой версии, копия в res://design/tasks/reports/R1_meta_save.md.bad-1792342599

Meta: сохранение повреждено или другой версии, копия в res://design/tasks/reports/R1_meta_save.md.bad-1792342599

Meta: сохранение повреждено или другой версии, копия в res://design/tasks/reports/R1_meta_save.md.bad-1792342599

Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в res://design/tasks/reports/R1_meta_save.md.campaign-bad-3190845

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

METATEST trait sticky (Улей): кассета из 3, прилипание → взрыв через 0.58 с (едет с носителем), носитель потерял 22 HP

METATEST trait hicap (Страж): магазин 17, 4.2 выстр/с, урон 8; перезарядка после 17 выстрелов

METATEST FAIL fan.different_targets задето целей: 4

METATEST trait fan (Ковбой): 6 выстрелов за 0.43 с по 4 разным целям, барабан пуст → перезарядка

METATEST trait steady (Оса): магазин 50, за 4 с 44 выстрелов, разброс +0.0° (ППШ за 1 с +21.0°)

METATEST trait lever (Винчестер): интервал 0.63 с, после убийства следующий выстрел через 0.23 с; урон 28.8 (Мосинка 48), темп 1.6/с

METATEST checks=257 failed=1

METATEST ok=false
```

## R1_meta_isolated.md

```text
Godot_console.exe --headless --path . -- --meta-test --gore-report --no-obstacles
```

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org



Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.

строка:2 знак:288

+ ... _checks.md; & 'C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\God ...

+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException

    + FullyQualifiedErrorId : NativeCommandError

 

   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=97.65 seed=81073

S7SETTINGS migration_v1_v3=true progress_preserved=true roundtrip=true sanitize=true temporary_save=true

Meta: сохранение повреждено или другой версии, копия в res://design/tasks/reports/R1_meta_save.md.bad-1792342816

Meta: сохранение повреждено или другой версии, копия в res://design/tasks/reports/R1_meta_save.md.bad-1792342816

Meta: сохранение повреждено или другой версии, копия в res://design/tasks/reports/R1_meta_save.md.bad-1792342816

Meta: сохранение повреждено или другой версии, копия в res://design/tasks/reports/R1_meta_save.md.bad-1792342816

Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в res://design/tasks/reports/R1_meta_save.md.campaign-bad-3332521

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
```

## R1_fx.md

```text
bash godot_exclusive.sh Godot_console.exe --disable-vsync --path . -- --fx-test --fresh-save --gore-report --shot=res://design/tasks/reports/r1_fx.png
```

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 20:00:24

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics



bash : ERROR: Failed to read the root certificate store.

строка:2 знак:1

+ bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Use ...

+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException

    + FullyQualifiedErrorId : NativeCommandError

 

   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=270.37 seed=81073

ERROR: Condition "f.is_null()" is true.

   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)

ERROR: Condition "f.is_null()" is true.

   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)

FXTEST sheet=seq ages=0.05,0.15,0.4,1.5

FXTEST sheet=crowd ages=0.05,0.15,0.4,1.5

FXTEST sheet=fat ages=0.05,0.15,0.4,1.5

FXTEST sheet=boss ages=0.05,0.15,0.4,1.5

FXBENCH warm_chain20 baseline=false enemies=500 frames=739 avg_ms=5.240 worst_ms=10.295 physics_worst_ms=7.794 draw_calls_peak=128 spawn_worst_ms=0.169 update_worst_ms=0.578 draw_submit_worst_ms=1.426 peak=399

FXBENCH warm_boss baseline=false enemies=500 frames=444 avg_ms=6.852 worst_ms=13.321 physics_worst_ms=10.573 draw_calls_peak=155 spawn_worst_ms=1.602 update_worst_ms=0.245 draw_submit_worst_ms=0.929 peak=180

FXBENCH chain20 baseline=false enemies=500 frames=623 avg_ms=6.243 worst_ms=17.605 physics_worst_ms=13.049 draw_calls_peak=123 spawn_worst_ms=0.212 update_worst_ms=0.268 draw_submit_worst_ms=1.784 peak=393

FXBENCH boss baseline=false enemies=500 frames=401 avg_ms=7.605 worst_ms=15.298 physics_worst_ms=11.870 draw_calls_peak=149 spawn_worst_ms=1.053 update_worst_ms=0.191 draw_submit_worst_ms=1.627 peak=180

FXTEST ok=true pool_cap=592 overflow_replaced=2708 idle_process=false

WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).

   at: cleanup (core/object/object.cpp:2536)
```

## R1_final_bench1.md

```text
bash godot_exclusive.sh Godot_console.exe --disable-vsync --path . -- --loadout --bench=500 --fresh-save --gore-profile
```

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 19:57:42

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics



bash : ERROR: Failed to read the root certificate store.

строка:2 знак:29

+ ... in 1,2,3) { bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusi ...

+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException

    + FullyQualifiedErrorId : NativeCommandError

 

   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=283.72 seed=81073

ERROR: Condition "f.is_null()" is true.

   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)

ERROR: Condition "f.is_null()" is true.

   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)

BENCH frames=1686 avg_fps=168.5 avg_frame_ms=5.94 worst_frame_ms=33.35 horde_ms=2.59 enemies=499 kills=880

BENCH process_ms=9.49 physics_ms=11.08 draw_calls=471 objects=3120 gore=98 particles=31 wet=74

BENCH physics_avg_ms=12.97 hud_ms=0.219

R1PROFILE static=141229976 video=323031040 gpu_last_ms=2.364 remains=200 remains_peak=200 stamps=30988 queue=28

WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).

   at: cleanup (core/object/object.cpp:2536)
```

## R1_final_bench2.md

```text
bash godot_exclusive.sh Godot_console.exe --disable-vsync --path . -- --loadout --bench=500 --fresh-save --gore-profile
```

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 19:58:02

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics



bash : ERROR: Failed to read the root certificate store.

строка:2 знак:29

+ ... in 1,2,3) { bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusi ...

+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException

    + FullyQualifiedErrorId : NativeCommandError

 

   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=318.93 seed=81073

ERROR: Condition "f.is_null()" is true.

   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)

ERROR: Condition "f.is_null()" is true.

   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)

BENCH frames=1162 avg_fps=116.1 avg_frame_ms=8.61 worst_frame_ms=28.78 horde_ms=3.09 enemies=498 kills=775

BENCH process_ms=6.68 physics_ms=15.77 draw_calls=469 objects=3262 gore=139 particles=166 wet=66

BENCH physics_avg_ms=14.28 hud_ms=0.321

R1PROFILE static=141363435 video=323489792 gpu_last_ms=2.701 remains=200 remains_peak=200 stamps=28802 queue=22

WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).

   at: cleanup (core/object/object.cpp:2536)
```

## R1_final_bench3.md

```text
bash godot_exclusive.sh Godot_console.exe --disable-vsync --path . -- --loadout --bench=500 --fresh-save --gore-profile
```

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 19:58:22

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics



bash : ERROR: Failed to read the root certificate store.

строка:2 знак:29

+ ... in 1,2,3) { bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusi ...

+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException

    + FullyQualifiedErrorId : NativeCommandError

 

   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=337.03 seed=81073

ERROR: Condition "f.is_null()" is true.

   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)

ERROR: Condition "f.is_null()" is true.

   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)

BENCH frames=1347 avg_fps=134.3 avg_frame_ms=7.44 worst_frame_ms=39.58 horde_ms=2.72 enemies=498 kills=774

BENCH process_ms=7.22 physics_ms=14.00 draw_calls=422 objects=3328 gore=449 particles=311 wet=114

BENCH physics_avg_ms=15.40 hud_ms=0.282

R1PROFILE static=140550746 video=323948544 gpu_last_ms=3.639 remains=200 remains_peak=200 stamps=26768 queue=106

WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).

   at: cleanup (core/object/object.cpp:2536)
```

## R1_after_shots.md

```text
bash godot_exclusive.sh Godot_console.exe --disable-vsync --path . -- --fresh-save --gore-shots --map=quarantine_checkpoint --layout-seed=81073 --shot=res://design/tasks/reports/r1_after.png
```

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 20:08:58
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

bash : ERROR: Failed to read the root certificate store.
строка:2 знак:154
+ ... { $r1Map }; bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusi ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=349.44 seed=81073
ERROR: Condition "f.is_null()" is true.
   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)
ERROR: Condition "f.is_null()" is true.
   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)
GORESTAND seconds=60 debris=45 peak=106 remains=79 remains_peak=200 stamps=28755 queue=0 pools=17 memory=133127026 video=301928448
GORESTAND seconds=300 debris=44 peak=125 remains=174 remains_peak=200 stamps=145322 queue=0 pools=18 memory=133133910 video=302125056
GORESTAND screenshot: res://design/tasks/reports/r1_after_5min.png
GORESTAND seconds=480 debris=68 peak=125 remains=131 remains_peak=200 stamps=232697 queue=0 pools=17 memory=133172858 video=301993984
GORESTAND seconds=600 debris=23 peak=125 remains=115 remains_peak=200 stamps=290449 queue=0 pools=14 memory=133169250 video=302059520
GORESTAND screenshot: res://design/tasks/reports/r1_after_10min.png
GORESTAND complete seed=81073 deaths=7200 zoom=3 map=quarantine_checkpoint
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

## R1_old_town_shots.md

```text
bash godot_exclusive.sh Godot_console.exe --disable-vsync --path . -- --fresh-save --gore-shots --map=old_town --layout-seed=81073 --shot=res://design/tasks/reports/r1_old_town.png
```

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 20:09:12
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

bash : ERROR: Failed to read the root certificate store.
строка:2 знак:154
+ ... { $r1Map }; bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusi ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=old_town size=(2560.0, 1440.0) load_ms=372.85 seed=81073
ERROR: Condition "f.is_null()" is true.
   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)
ERROR: Condition "f.is_null()" is true.
   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)
GORESTAND seconds=60 debris=45 peak=106 remains=89 remains_peak=200 stamps=28776 queue=0 pools=17 memory=133137068 video=323072000
GORESTAND seconds=300 debris=44 peak=125 remains=177 remains_peak=200 stamps=145367 queue=0 pools=18 memory=133144748 video=322678784
GORESTAND screenshot: res://design/tasks/reports/r1_old_town_5min.png
GORESTAND seconds=480 debris=68 peak=125 remains=138 remains_peak=200 stamps=232771 queue=0 pools=17 memory=133182204 video=322547712
GORESTAND seconds=600 debris=23 peak=125 remains=113 remains_peak=200 stamps=290517 queue=0 pools=14 memory=133179404 video=323203072
GORESTAND screenshot: res://design/tasks/reports/r1_old_town_10min.png
GORESTAND complete seed=81073 deaths=7200 zoom=3 map=old_town
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```

## R1_open_perimeter_shots.md

```text
bash godot_exclusive.sh Godot_console.exe --disable-vsync --path . -- --fresh-save --gore-shots --map=open_perimeter --layout-seed=81073 --shot=res://design/tasks/reports/r1_open_perimeter.png
```

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 20:09:26
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

bash : ERROR: Failed to read the root certificate store.
строка:2 знак:154
+ ... { $r1Map }; bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusi ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=open_perimeter size=(2560.0, 1440.0) load_ms=327.10 seed=81073
ERROR: Condition "f.is_null()" is true.
   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)
ERROR: Condition "f.is_null()" is true.
   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)
GORESTAND seconds=60 debris=46 peak=108 remains=81 remains_peak=200 stamps=28769 queue=0 pools=17 memory=133054016 video=253280256
GORESTAND seconds=300 debris=44 peak=124 remains=177 remains_peak=200 stamps=145318 queue=0 pools=18 memory=133060876 video=253476864
GORESTAND screenshot: res://design/tasks/reports/r1_open_perimeter_5min.png
GORESTAND seconds=480 debris=68 peak=124 remains=133 remains_peak=200 stamps=232749 queue=0 pools=17 memory=133102564 video=253345792
GORESTAND seconds=600 debris=21 peak=124 remains=117 remains_peak=200 stamps=290371 queue=0 pools=14 memory=133099628 video=254001152
GORESTAND screenshot: res://design/tasks/reports/r1_open_perimeter_10min.png
GORESTAND complete seed=81073 deaths=7200 zoom=3 map=open_perimeter
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```


## R1_sim_final.md

```text
Godot_console.exe --headless --fixed-fps 60 --path . -- --sim=600 --fresh-save
```

?????????????? ?????????? ?????????????? ?????? ???????? ??????????; FPS ?? headless ?? ???????? ??????? ??????????????????.

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org



Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.

строка:2 знак:1

+ & 'C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-st ...

+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException

    + FullyQualifiedErrorId : NativeCommandError

 

   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=329.31 seed=81073

SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s

PICK lvl=2 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["weapon", "module", "level"]

PICK lvl=3 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["ammo", "weapon", "level"]

PICK lvl=4 { "type": "weapon", "id": 1, "rare": false } slot=-1 of ["weapon", "level", "weapon"]

SIM 01:00 level=4 kills=55 xp=51/55 credits=6/7 credits_left=6 zombies=29 kinds=29/0/0/0 elites=0 elites_spawned=0 crates=0 nades=1 dmg_taken=56 peak=39 fps=483 | АК-С L3 Стан1 [] | Мясник L1 Стан1 []

PICK lvl=5 { "type": "module", "id": 1, "rare": false } slot=0 of ["passive", "module", "level"]

PICK lvl=6 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "ammo", "module"]

PICK lvl=7 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["passive", "level", "level"]

SIM 02:00 level=7 kills=227 xp=221/227 credits=20/20 credits_left=20 zombies=39 kinds=39/0/0/0 elites=0 elites_spawned=0 crates=0 nades=7 dmg_taken=2022 peak=64 fps=330 | АК-С L4 Стан1 [Проб1] | Мясник L2 Стан1 []

PICK lvl=8 { "type": "module", "id": 0, "rare": false } slot=0 of ["level", "level", "module"]

PICK lvl=9 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["weapon", "ammo", "ammo"]

SIM 03:00 level=9 kills=434 xp=398/434 credits=28/28 credits_left=28 zombies=64 kinds=64/0/0/0 elites=0 elites_spawned=0 crates=0 nades=12 dmg_taken=3096 peak=94 fps=336 | АК-С L4 Эксп1 [Проб1,Рико1] | Мясник L2 Стан1 []

PICK lvl=10 { "type": "weapon", "id": 3, "rare": false } slot=-1 of ["level", "passive", "weapon"]

SIM 04:00 level=10 kills=683 xp=573/689 credits=34/42 credits_left=34 zombies=88 kinds=79/0/9/0 elites=0 elites_spawned=0 crates=0 nades=15 dmg_taken=3132 peak=98 fps=258 | АК-С L4 Эксп1 [Проб1,Рико1] | Мясник L2 Стан1 [] | Гром L1 Стан1 []

TRADER 0 at 05:00 credits_left=34 bought=[]

SIM 05:00 level=10 kills=1092 xp=573/1200 credits=34/86 credits_left=34 zombies=40 kinds=23/16/1/0 elites=0 elites_spawned=0 crates=0 nades=15 dmg_taken=3277 peak=114 fps=253 | АК-С L4 Эксп1 [Проб1,Рико1] | Мясник L2 Стан1 [] | Гром L1 Стан1 []

PICK lvl=11 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["level", "level", "ammo"]

SIM 06:00 level=11 kills=1509 xp=693/1819 credits=51/181 credits_left=51 zombies=50 kinds=33/0/8/9 elites=0 elites_spawned=2 crates=0 nades=16 dmg_taken=3316 peak=120 fps=226 | АК-С L4 Эксп1 [Проб1,Рико1] | Мясник L2 Стан1 [] | Гром L2 Стан1 []

PICK lvl=12 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["passive", "ammo", "passive"]

SIM 07:00 level=12 kills=1985 xp=787/2519 credits=61/268 credits_left=61 zombies=53 kinds=36/0/10/7 elites=0 elites_spawned=4 crates=0 nades=16 dmg_taken=3316 peak=74 fps=244 | АК-С L4 Эксп1 [Проб1,Рико1] | Мясник L2 Стан1 [] | Гром L2 Стан1 []

ALARM_EVENT warn time=07:00

ALARM_EVENT start time=07:03

ALARM_EVENT finish container=(1224.893, 386.52) time=07:33

CONTAINER dropped pos=(1224.893, 386.52) time=07:33

ALARM rewards mult=2 xp=1946 credits=292

SIM 08:00 level=12 kills=2988 xp=787/5002 credits=61/629 credits_left=61 zombies=44 kinds=30/3/7/4 elites=0 elites_spawned=10 crates=0 nades=17 dmg_taken=3316 peak=174 fps=266 | АК-С L4 Эксп1 [Проб1,Рико1] | Мясник L2 Стан1 [] | Гром L2 Стан1 []

CALM 09:00 removed=57 left=4

TRADER 1 at 09:00 credits_left=1 bought=["module(60)"]

SIM 09:00 level=12 kills=3634 xp=787/5950 credits=61/760 credits_left=1 zombies=61 kinds=25/26/7/3 elites=0 elites_spawned=12 crates=0 nades=17 dmg_taken=3316 peak=92 fps=226 | АК-С L4 Эксп1 [Проб1,Рико2] | Мясник L2 Стан1 [] | Гром L2 Стан1 []

BOSS spawn t=600.00 pos=(1208.0, 536.0) hp=24000

SIM 10:00 level=12 kills=3821 xp=787/6191 credits=61/792 credits_left=1 zombies=23 kinds=23/0/0/0 elites=0 elites_spawned=14 crates=0 nades=17 dmg_taken=3316 peak=40 fps=405 | АК-С L4 Эксп1 [Проб1,Рико2] | Мясник L2 Стан1 [] | Гром L2 Стан1 []

SIM summary kills=3821 peak=174 level=12 damage=3315.80 boss_alive=true
```

## R1_hit.md

```text
bash godot_exclusive.sh Godot_console.exe --disable-vsync --path . -- --fresh-save --gore-shots --gore-hit-only
```

```text
GODOT_EXCLUSIVE other_godot_processes=0 at 20:09:38
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

bash : ERROR: Failed to read the root certificate store.
строка:2 знак:616
+ ... hots.md" }; bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusi ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=345.81 seed=81073
ERROR: Condition "f.is_null()" is true.
   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)
ERROR: Condition "f.is_null()" is true.
   at: _save_to_cache (servers/rendering/renderer_rd/shader_rd.cpp:696)
GORESTAND hit_sheet rifle=7 shotgun=6x5 sniper=48 source=WeaponDefs.BASES crop_native_pixels=true
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```
