# R1d — команды и дословные журналы

Файлы не фильтруются; ранние неуспешные и промежуточные прогоны сохранены отдельно от финальных.

## r1d_activities_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --activities-test --fresh-save
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=345.06 seed=81073
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

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_activities_rivers_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --activities-test --fresh-save
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=178.37 seed=81073
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

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_bench_1_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1d_bench.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:29:32
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=510.49 seed=81073
BENCH frames=432 avg_fps=43.1 avg_frame_ms=23.19 worst_frame_ms=138.17 horde_ms=4.51 enemies=499 kills=926
BENCH process_ms=11.01 physics_ms=25.63 draw_calls=496 objects=4108 gore=201 particles=85 wet=108
BENCH physics_avg_ms=19.77 hud_ms=0.626
BENCH screenshot: res://design/tasks/reports/r1d_bench.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_bench_1_before.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1d_bench_before.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:20:09
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=303.38 seed=81073
BENCH frames=1322 avg_fps=132.1 avg_frame_ms=7.57 worst_frame_ms=45.05 horde_ms=2.52 enemies=499 kills=880
BENCH process_ms=6.09 physics_ms=12.96 draw_calls=583 objects=4180 gore=825 particles=840 wet=35
BENCH physics_avg_ms=13.42 hud_ms=0.254
BENCH screenshot: res://design/tasks/reports/r1d_bench_before.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_bench_2_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1d_bench.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:29:59
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=485.86 seed=81073
BENCH frames=481 avg_fps=48.0 avg_frame_ms=20.83 worst_frame_ms=139.05 horde_ms=4.43 enemies=499 kills=792
BENCH process_ms=10.36 physics_ms=17.12 draw_calls=611 objects=4044 gore=312 particles=432 wet=95
BENCH physics_avg_ms=28.53 hud_ms=0.548
BENCH screenshot: res://design/tasks/reports/r1d_bench.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_bench_2_before.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1d_bench_before.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:20:34
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=305.64 seed=81073
BENCH frames=1191 avg_fps=119.0 avg_frame_ms=8.40 worst_frame_ms=64.42 horde_ms=2.72 enemies=499 kills=1164
BENCH process_ms=12.09 physics_ms=19.73 draw_calls=615 objects=4131 gore=639 particles=1319 wet=82
BENCH physics_avg_ms=15.09 hud_ms=0.291
BENCH screenshot: res://design/tasks/reports/r1d_bench_before.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_bench_3_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1d_bench.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:30:25
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=437.44 seed=81073
BENCH frames=422 avg_fps=42.0 avg_frame_ms=23.79 worst_frame_ms=137.52 horde_ms=4.60 enemies=499 kills=906
BENCH process_ms=13.25 physics_ms=16.91 draw_calls=506 objects=4162 gore=282 particles=579 wet=50
BENCH physics_avg_ms=23.60 hud_ms=0.650
BENCH screenshot: res://design/tasks/reports/r1d_bench.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_bench_3_before.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1d_bench_before.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:20:55
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
SCRIPT ERROR: Parse Error: Function "_r1d_test_paths()" not found in base self.
   at: GDScript::reload (res://scripts/game.gd:666)
SCRIPT ERROR: Parse Error: Identifier "_run_r1d_shots" not declared in the current scope.
   at: GDScript::reload (res://scripts/game.gd:1025)
SCRIPT ERROR: Parse Error: Function "_r1d_details()" not found in base self.
   at: GDScript::reload (res://scripts/game.gd:1164)
ERROR: Failed to load script "res://scripts/game.gd" with error "Parse error".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
TESTRESULT ok=false errors=4
SCRIPT ERROR: Invalid access to property or key 'player' on a base object of type 'Node2D'.
   at: _draw (res://scripts/hud.gd:349)
   GDScript backtrace (most recent call first):
       [0] _draw (res://scripts/hud.gd:349)
SCRIPT ERROR: Invalid access to property or key 'player' on a base object of type 'Node2D'.
   at: _draw_overlay (res://scripts/hud.gd:397)
   GDScript backtrace (most recent call first):
       [0] _draw_overlay (res://scripts/hud.gd:397)
       [1] _draw (res://scripts/hud.gd:75)

R1DGUARD foreign_during=[11480, 13596]
EXIT_CODE=1
```

## r1d_bench_3_repeat_before.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1d_bench_before.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:25:05
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=407.29 seed=81073
BENCH frames=1295 avg_fps=129.5 avg_frame_ms=7.72 worst_frame_ms=30.31 horde_ms=2.52 enemies=498 kills=933
BENCH process_ms=8.75 physics_ms=15.12 draw_calls=599 objects=4142 gore=359 particles=1016 wet=86
BENCH physics_avg_ms=12.88 hud_ms=0.258
BENCH screenshot: res://design/tasks/reports/r1d_bench_before.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_bench_deliver_1_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1d_bench.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:48:44
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=310.75 seed=81073
BENCH frames=1464 avg_fps=146.4 avg_frame_ms=6.83 worst_frame_ms=20.70 horde_ms=2.45 enemies=498 kills=1194
BENCH process_ms=5.59 physics_ms=12.09 draw_calls=514 objects=4153 gore=623 particles=951 wet=128
BENCH physics_avg_ms=12.80 hud_ms=0.229
BENCH screenshot: res://design/tasks/reports/r1d_bench.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_bench_deliver_2_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1d_bench.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:49:05
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=266.33 seed=81073
BENCH frames=1215 avg_fps=121.4 avg_frame_ms=8.24 worst_frame_ms=66.83 horde_ms=2.88 enemies=498 kills=1067
BENCH process_ms=8.71 physics_ms=14.88 draw_calls=792 objects=4273 gore=875 particles=1412 wet=128
BENCH physics_avg_ms=15.07 hud_ms=0.286
BENCH screenshot: res://design/tasks/reports/r1d_bench.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[10340, 12512]
EXIT_CODE=0
```

## r1d_bench_deliver_2_repeat_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1d_bench.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:50:06
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=255.47 seed=81073
BENCH frames=1444 avg_fps=144.2 avg_frame_ms=6.94 worst_frame_ms=19.35 horde_ms=2.50 enemies=497 kills=1019
BENCH process_ms=6.82 physics_ms=9.42 draw_calls=618 objects=4317 gore=491 particles=1465 wet=125
BENCH physics_avg_ms=13.17 hud_ms=0.245
BENCH screenshot: res://design/tasks/reports/r1d_bench.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_bench_deliver_3_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1d_bench.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:49:29
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=276.30 seed=81073
BENCH frames=1491 avg_fps=148.7 avg_frame_ms=6.72 worst_frame_ms=77.48 horde_ms=2.67 enemies=498 kills=1120
BENCH process_ms=6.54 physics_ms=15.94 draw_calls=632 objects=4151 gore=900 particles=1328 wet=107
BENCH physics_avg_ms=12.37 hud_ms=0.235
BENCH screenshot: res://design/tasks/reports/r1d_bench.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_bench_rivers_1_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1d_bench.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 18:00:24
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=370.57 seed=81073
BENCH frames=1215 avg_fps=121.3 avg_frame_ms=8.24 worst_frame_ms=59.06 horde_ms=2.78 enemies=499 kills=879
BENCH process_ms=6.86 physics_ms=14.88 draw_calls=600 objects=4197 gore=381 particles=1120 wet=42
BENCH physics_avg_ms=14.32 hud_ms=0.283
BENCH screenshot: res://design/tasks/reports/r1d_bench.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[9572, 15200, 17824, 19844]
EXIT_CODE=0
```

## r1d_bench_rivers_2_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1d_bench.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 18:04:43
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=258.80 seed=81073
BENCH frames=1453 avg_fps=145.2 avg_frame_ms=6.89 worst_frame_ms=81.29 horde_ms=2.41 enemies=498 kills=868
BENCH process_ms=6.00 physics_ms=12.69 draw_calls=516 objects=4179 gore=327 particles=618 wet=110
BENCH physics_avg_ms=20.57 hud_ms=0.219
BENCH screenshot: res://design/tasks/reports/r1d_bench.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_bench_rivers_3_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1d_bench.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 18:05:04
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=271.08 seed=81073
BENCH frames=1537 avg_fps=153.6 avg_frame_ms=6.51 worst_frame_ms=59.78 horde_ms=2.40 enemies=498 kills=989
BENCH process_ms=5.14 physics_ms=9.23 draw_calls=475 objects=4188 gore=264 particles=782 wet=96
BENCH physics_avg_ms=12.73 hud_ms=0.219
BENCH screenshot: res://design/tasks/reports/r1d_bench.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_bench_rivers_4_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1d_bench.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 18:06:30
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=238.84 seed=81073
BENCH frames=1690 avg_fps=168.9 avg_frame_ms=5.92 worst_frame_ms=18.77 horde_ms=2.46 enemies=497 kills=945
BENCH process_ms=5.06 physics_ms=9.26 draw_calls=522 objects=4097 gore=280 particles=774 wet=95
BENCH physics_avg_ms=11.37 hud_ms=0.215
BENCH screenshot: res://design/tasks/reports/r1d_bench.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_campaign_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --campaign-test --r1d
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
Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в res://design/tasks/reports/R1d_test/c1_migration.json.campaign-bad-8820291
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
WARNING: Meta: запись res://design/tasks/reports/R1d_test/c1_missing_directory/save.json не удалась
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] save (res://scripts/meta.gd:446)
       [1] start_operation (res://scripts/campaign/campaign.gd:57)
       [2] _integration (res://scripts/campaign/campaign_test.gd:265)
       [3] run (res://scripts/campaign/campaign_test.gd:24)
       [4] _ready (res://scripts/game.gd:677)
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

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_campaign_rivers_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --campaign-test --r1d
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
Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в res://design/tasks/reports/R1d_test/c1_migration.json.campaign-bad-4634043
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
WARNING: Meta: запись res://design/tasks/reports/R1d_test/c1_missing_directory/save.json не удалась
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] save (res://scripts/meta.gd:446)
       [1] start_operation (res://scripts/campaign/campaign.gd:57)
       [2] _integration (res://scripts/campaign/campaign_test.gd:265)
       [3] run (res://scripts/campaign/campaign_test.gd:24)
       [4] _ready (res://scripts/game.gd:677)
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

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_control_1_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:31:35
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=419.31 seed=81073
BENCH frames=281 avg_fps=28.0 avg_frame_ms=35.71 worst_frame_ms=140.58 horde_ms=4.63 enemies=499 kills=1016
BENCH process_ms=16.32 physics_ms=25.84 draw_calls=594 objects=4110 gore=466 particles=663 wet=115
BENCH physics_avg_ms=24.97 hud_ms=0.772
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_control_1_before.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:31:09
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=502.60 seed=81073
BENCH frames=450 avg_fps=44.9 avg_frame_ms=22.26 worst_frame_ms=137.43 horde_ms=4.60 enemies=499 kills=880
BENCH process_ms=11.17 physics_ms=18.33 draw_calls=533 objects=4090 gore=306 particles=311 wet=55
BENCH physics_avg_ms=21.92 hud_ms=0.592
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_control_2_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:32:27
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=647.79 seed=81073
BENCH frames=307 avg_fps=30.7 avg_frame_ms=32.62 worst_frame_ms=141.05 horde_ms=4.67 enemies=499 kills=958
BENCH process_ms=15.07 physics_ms=29.29 draw_calls=547 objects=4024 gore=886 particles=669 wet=125
BENCH physics_avg_ms=25.25 hud_ms=0.727
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_control_2_before.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:32:01
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=447.16 seed=81073
BENCH frames=518 avg_fps=51.8 avg_frame_ms=19.32 worst_frame_ms=142.59 horde_ms=4.58 enemies=498 kills=1063
BENCH process_ms=16.38 physics_ms=33.15 draw_calls=555 objects=4006 gore=300 particles=327 wet=124
BENCH physics_avg_ms=18.91 hud_ms=0.523
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_control_3_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:33:24
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=495.32 seed=81073
BENCH frames=385 avg_fps=38.3 avg_frame_ms=26.14 worst_frame_ms=137.52 horde_ms=4.69 enemies=499 kills=903
BENCH process_ms=10.23 physics_ms=20.46 draw_calls=565 objects=4067 gore=503 particles=526 wet=116
BENCH physics_avg_ms=30.46 hud_ms=0.714
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[13656, 21932]
EXIT_CODE=0
```

## r1d_control_3_before.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:32:56
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=582.33 seed=81073
BENCH frames=433 avg_fps=43.2 avg_frame_ms=23.14 worst_frame_ms=135.49 horde_ms=4.65 enemies=499 kills=922
BENCH process_ms=10.80 physics_ms=21.25 draw_calls=541 objects=3981 gore=133 particles=343 wet=97
BENCH physics_avg_ms=25.14 hud_ms=0.642
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_fx_final.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fx-test --fresh-save --r1d --shot=res://design/tasks/reports/r1d_fx.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:47:19
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=301.21 seed=81073
FXTEST sheet=seq ages=0.05,0.15,0.4,1.5
FXTEST sheet=crowd ages=0.05,0.15,0.4,1.5
FXTEST sheet=fat ages=0.05,0.15,0.4,1.5
FXTEST sheet=boss ages=0.05,0.15,0.4,1.5
FXBENCH warm_chain20 baseline=false enemies=500 frames=935 avg_ms=4.107 worst_ms=10.416 physics_worst_ms=6.652 draw_calls_peak=137 spawn_worst_ms=0.185 update_worst_ms=0.242 draw_submit_worst_ms=1.341 peak=409
FXBENCH warm_boss baseline=false enemies=500 frames=746 avg_ms=4.074 worst_ms=8.963 physics_worst_ms=6.275 draw_calls_peak=138 spawn_worst_ms=0.943 update_worst_ms=0.401 draw_submit_worst_ms=0.972 peak=180
FXBENCH chain20 baseline=false enemies=500 frames=993 avg_ms=3.858 worst_ms=8.767 physics_worst_ms=5.648 draw_calls_peak=130 spawn_worst_ms=0.110 update_worst_ms=0.284 draw_submit_worst_ms=1.314 peak=408
FXBENCH boss baseline=false enemies=500 frames=719 avg_ms=4.229 worst_ms=9.107 physics_worst_ms=6.908 draw_calls_peak=139 spawn_worst_ms=0.644 update_worst_ms=0.206 draw_submit_worst_ms=0.890 peak=180
FXTEST ok=true pool_cap=592 overflow_replaced=2708 idle_process=false
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_fx_rivers_final.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fx-test --fresh-save --r1d --shot=res://design/tasks/reports/r1d_fx.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 17:59:14
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=256.07 seed=81073
FXTEST sheet=seq ages=0.05,0.15,0.4,1.5
FXTEST sheet=crowd ages=0.05,0.15,0.4,1.5
FXTEST sheet=fat ages=0.05,0.15,0.4,1.5
FXTEST sheet=boss ages=0.05,0.15,0.4,1.5
FXBENCH warm_chain20 baseline=false enemies=500 frames=1165 avg_ms=3.264 worst_ms=7.974 physics_worst_ms=4.828 draw_calls_peak=119 spawn_worst_ms=0.119 update_worst_ms=0.500 draw_submit_worst_ms=1.461 peak=419
FXBENCH warm_boss baseline=false enemies=500 frames=779 avg_ms=3.901 worst_ms=8.556 physics_worst_ms=5.863 draw_calls_peak=124 spawn_worst_ms=0.866 update_worst_ms=0.243 draw_submit_worst_ms=0.908 peak=180
FXBENCH chain20 baseline=false enemies=500 frames=1053 avg_ms=3.637 worst_ms=7.699 physics_worst_ms=6.549 draw_calls_peak=116 spawn_worst_ms=0.152 update_worst_ms=0.487 draw_submit_worst_ms=1.810 peak=410
FXBENCH boss baseline=false enemies=500 frames=771 avg_ms=3.941 worst_ms=7.400 physics_worst_ms=5.913 draw_calls_peak=122 spawn_worst_ms=1.022 update_worst_ms=0.403 draw_submit_worst_ms=0.941 peak=180
FXTEST ok=true pool_cap=592 overflow_replaced=2708 idle_process=false
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_gore_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --gore-checks --r1d
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=337.50 seed=81073
R1CHECK pellets_one_reaction_full_damage=true
R1CHECK exit_spray=true
R1DCHECK hit fan=false cone40=0.97059 samples=816 palette=true
R1CHECK r1d_bullet_cone_palette=true
R1DCHECK hit fan=true cone40=0.97059 samples=816 palette=true
R1CHECK r1d_shotgun_cone_palette=true
R1DCHECK death=0 cone40=0.98718 samples=1248 parts=true
R1CHECK r1d_death_0=true
R1DCHECK death=1 cone40=0.98958 samples=1536 parts=true
R1CHECK r1d_death_1=true
R1DCHECK death=2 cone40=0.99038 samples=1664 parts=true
R1CHECK r1d_death_2=true
R1DCHECK death=5 cone40=0.98810 samples=1344 parts=true
R1CHECK r1d_death_5=true
R1DCHECK death=6 cone40=0.98958 samples=1536 parts=true
R1CHECK r1d_death_6=true
R1CHECK r1d_wound_ignores_facing=true
R1CHECK r1d_delayed_ice_direction_compaction=true
R1CHECK crawler_inertia=true
R1CHECK bounded_flood_2400_deaths=true
R1CHECK no_permanent_body_or_ash_stamps=true
R1CHECK all_remains_expire=true
R1CHECK ok=true remains_peak=200 stamps_queue=381 particles=0

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_gore_rivers.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --gore-checks --r1d
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
SCRIPT ERROR: Parse Error: Cannot infer the type of "stepped" variable because the value doesn't have a set type.
   at: GDScript::reload (res://scripts/game.gd:4270)
ERROR: Failed to load script "res://scripts/game.gd" with error "Parse error".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
TESTRESULT ok=false errors=2
SCRIPT ERROR: Invalid access to property or key 'player' on a base object of type 'Node2D'.
   at: _draw (res://scripts/hud.gd:349)
   GDScript backtrace (most recent call first):
       [0] _draw (res://scripts/hud.gd:349)
SCRIPT ERROR: Invalid access to property or key 'player' on a base object of type 'Node2D'.
   at: _draw_overlay (res://scripts/hud.gd:397)
   GDScript backtrace (most recent call first):
       [0] _draw_overlay (res://scripts/hud.gd:397)
       [1] _draw (res://scripts/hud.gd:75)

R1DGUARD foreign_during=[]
EXIT_CODE=1
```

## r1d_gore_rivers2.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --gore-checks --r1d
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=183.84 seed=81073
R1CHECK pellets_one_reaction_full_damage=true
R1CHECK exit_spray=true
R1DCHECK hit fan=false cone40=0.97059 samples=816 palette=true
R1CHECK r1d_bullet_cone_palette=true
R1DCHECK hit fan=true cone40=0.97059 samples=816 palette=true
R1CHECK r1d_shotgun_cone_palette=true
R1DCHECK death=0 cone40=0.98718 samples=1248 parts=true
R1CHECK r1d_death_0=true
R1DCHECK death=1 cone40=0.98958 samples=1536 parts=true
R1CHECK r1d_death_1=true
R1DCHECK death=2 cone40=0.99038 samples=1664 parts=true
R1CHECK r1d_death_2=true
R1DCHECK death=5 cone40=0.98810 samples=1344 parts=true
R1CHECK r1d_death_5=true
R1DCHECK death=6 cone40=0.98958 samples=1536 parts=true
R1CHECK r1d_death_6=true
R1CHECK r1d_wound_ignores_facing=true
R1CHECK r1d_delayed_ice_direction_compaction=true
R1CHECK r1d_player_wet_stride_no_idle_stamps=true
R1CHECK crawler_inertia=true
R1CHECK bounded_flood_2400_deaths=true
R1CHECK no_permanent_body_or_ash_stamps=true
R1CHECK all_remains_expire=true
R1CHECK ok=true remains_peak=200 stamps_queue=381 particles=0

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_gore_rivers_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --gore-checks --r1d
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=176.76 seed=81073
R1CHECK pellets_one_reaction_full_damage=true
R1CHECK exit_spray=true
R1DCHECK hit fan=false cone40=0.97059 samples=816 palette=true
R1CHECK r1d_bullet_cone_palette=true
R1DCHECK hit fan=true cone40=0.97059 samples=816 palette=true
R1CHECK r1d_shotgun_cone_palette=true
R1DCHECK death=0 cone40=0.98718 samples=1248 parts=true
R1CHECK r1d_death_0=true
R1DCHECK death=1 cone40=0.98958 samples=1536 parts=true
R1CHECK r1d_death_1=true
R1DCHECK death=2 cone40=0.99038 samples=1664 parts=true
R1CHECK r1d_death_2=true
R1DCHECK death=5 cone40=0.98810 samples=1344 parts=true
R1CHECK r1d_death_5=true
R1DCHECK death=6 cone40=0.98958 samples=1536 parts=true
R1CHECK r1d_death_6=true
R1CHECK r1d_wound_ignores_facing=true
R1CHECK r1d_delayed_ice_direction_compaction=true
R1CHECK r1d_player_wet_stride_no_idle_stamps=true
R1CHECK crawler_inertia=true
R1CHECK bounded_flood_2400_deaths=true
R1CHECK no_permanent_body_or_ash_stamps=true
R1CHECK all_remains_expire=true
R1CHECK ok=true remains_peak=200 stamps_queue=417 particles=0

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_gore_trial.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --gore-checks --r1d
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=350.17 seed=81073
R1CHECK pellets_one_reaction_full_damage=true
R1CHECK exit_spray=true
R1DCHECK hit fan=false cone40=0.97059 samples=816 palette=true
R1CHECK r1d_bullet_cone_palette=true
R1DCHECK hit fan=true cone40=0.97059 samples=816 palette=true
R1CHECK r1d_shotgun_cone_palette=true
R1DCHECK death=0 cone40=0.98718 samples=1248 parts=true
R1CHECK r1d_death_0=true
R1DCHECK death=1 cone40=0.98958 samples=1536 parts=true
R1CHECK r1d_death_1=true
R1DCHECK death=2 cone40=0.99038 samples=1664 parts=true
R1CHECK r1d_death_2=true
R1DCHECK death=5 cone40=0.98810 samples=1344 parts=true
R1CHECK r1d_death_5=true
R1DCHECK death=6 cone40=0.98958 samples=1536 parts=true
R1CHECK r1d_death_6=true
R1CHECK r1d_wound_ignores_facing=true
R1CHECK crawler_inertia=true
R1CHECK bounded_flood_2400_deaths=true
R1CHECK no_permanent_body_or_ash_stamps=true
R1CHECK all_remains_expire=true
R1CHECK ok=true remains_peak=200 stamps_queue=509 particles=0

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_import_after.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d --import
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
[   0% ] [90m[1mupdate_scripts_classes[22m | Started Регистрация глобальных классов… (4 steps)[39m[0m
[   0% ] [90m[1mupdate_scripts_classes[22m | Effects[39m[0m
[  20% ] [90m[1mupdate_scripts_classes[22m | FloorDecals[39m[0m
[  40% ] [90m[1mupdate_scripts_classes[22m | [39m[0m
[  60% ] [90m[1mupdate_scripts_classes[22m | Gore[39m[0m
[92m[ DONE ][39m [1mupdate_scripts_classes[22m
[0m
[   0% ] [90m[1m_update_scan_actions[22m | Started Сканирование действий… (8 steps)[39m[0m
[   0% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_0.png[39m[0m
[  11% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_1.png[39m[0m
[  22% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_2.png[39m[0m
[  33% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_3.png[39m[0m
[  44% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_4.png[39m[0m
[  55% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_5.png[39m[0m
[  66% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_6.png[39m[0m
[  77% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_7.png[39m[0m
[92m[ DONE ][39m [1m_update_scan_actions[22m
[0m
[   0% ] [90m[1mreimport[22m | Started Импорт или повторный импорт ассетов (8 steps)[39m[0m
[   0% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  11% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  22% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  33% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  44% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  55% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  66% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  77% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[   0% ] [90m[1mreimport[22m | Выполнение предимпортных операций…[39m[0m
[   0% ] [90m[1mreimport[22m | blood_pool_r1d_0.png[39m[0m
[  11% ] [90m[1mreimport[22m | blood_pool_r1d_1.png[39m[0m
[  22% ] [90m[1mreimport[22m | blood_pool_r1d_2.png[39m[0m
[  33% ] [90m[1mreimport[22m | blood_pool_r1d_3.png[39m[0m
[  44% ] [90m[1mreimport[22m | blood_pool_r1d_4.png[39m[0m
[  55% ] [90m[1mreimport[22m | blood_pool_r1d_5.png[39m[0m
[  66% ] [90m[1mreimport[22m | blood_pool_r1d_6.png[39m[0m
[  77% ] [90m[1mreimport[22m | blood_pool_r1d_7.png[39m[0m
[  88% ] [90m[1mreimport[22m | Завершение импорта активов…[39m[0m
[92m[ DONE ][39m [1mreimport[22m
[0m
[   0% ] [90m[1mreimport[22m | Started Импорт или повторный импорт ассетов (8 steps)[39m[0m
[   0% ] [90m[1mreimport[22m | Выполнение операций после реимпорта…[39m[0m
[92m[ DONE ][39m [1mreimport[22m
[0m
[   0% ] [90m[1mloading_editor_layout[22m | Started Загрузка редактора (5 steps)[39m[0m
[   0% ] [90m[1mloading_editor_layout[22m | Загрузка макета редактора…[39m[0m
[  16% ] [90m[1mloading_editor_layout[22m | Загрузка док-панели…[39m[0m
[92m[ DONE ][39m [1mloading_editor_layout[22m
[0m

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_import_deliver.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d --import
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
[   0% ] [90m[1mupdate_scripts_classes[22m | Started Регистрация глобальных классов… (2 steps)[39m[0m
[   0% ] [90m[1mupdate_scripts_classes[22m | FloorDecals[39m[0m
[  33% ] [90m[1mupdate_scripts_classes[22m | [39m[0m
[92m[ DONE ][39m [1mupdate_scripts_classes[22m
[0m
[   0% ] [90m[1m_update_scan_actions[22m | Started Сканирование действий… (8 steps)[39m[0m
[   0% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_0.png[39m[0m
[  11% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_1.png[39m[0m
[  22% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_2.png[39m[0m
[  33% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_3.png[39m[0m
[  44% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_4.png[39m[0m
[  55% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_5.png[39m[0m
[  66% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_6.png[39m[0m
[  77% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_7.png[39m[0m
[92m[ DONE ][39m [1m_update_scan_actions[22m
[0m
[   0% ] [90m[1mloading_editor_layout[22m | Started Загрузка редактора (5 steps)[39m[0m
[   0% ] [90m[1mloading_editor_layout[22m | Загрузка макета редактора…[39m[0m
[  16% ] [90m[1mloading_editor_layout[22m | Загрузка док-панели…[39m[0m
[92m[ DONE ][39m [1mloading_editor_layout[22m
[0m

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_import_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d --import
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
[   0% ] [90m[1mupdate_scripts_classes[22m | Started Регистрация глобальных классов… (4 steps)[39m[0m
[   0% ] [90m[1mupdate_scripts_classes[22m | Effects[39m[0m
[  20% ] [90m[1mupdate_scripts_classes[22m | FloorDecals[39m[0m
[  40% ] [90m[1mupdate_scripts_classes[22m | [39m[0m
[  60% ] [90m[1mupdate_scripts_classes[22m | Gore[39m[0m
[92m[ DONE ][39m [1mupdate_scripts_classes[22m
[0m
[   0% ] [90m[1mloading_editor_layout[22m | Started Загрузка редактора (5 steps)[39m[0m
[   0% ] [90m[1mloading_editor_layout[22m | Загрузка макета редактора…[39m[0m
[  16% ] [90m[1mloading_editor_layout[22m | Загрузка док-панели…[39m[0m
[92m[ DONE ][39m [1mloading_editor_layout[22m
[0m

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_import_resume.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d --import
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
[   0% ] [90m[1mloading_editor_layout[22m | Started Загрузка редактора (5 steps)[39m[0m
[   0% ] [90m[1mloading_editor_layout[22m | Загрузка макета редактора…[39m[0m
[  16% ] [90m[1mloading_editor_layout[22m | Загрузка док-панели…[39m[0m
[92m[ DONE ][39m [1mloading_editor_layout[22m
[0m

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_import_rivers.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d --import
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
[   0% ] [90m[1mupdate_scripts_classes[22m | Started Регистрация глобальных классов… (2 steps)[39m[0m
[   0% ] [90m[1mupdate_scripts_classes[22m | FloorDecals[39m[0m
[  33% ] [90m[1mupdate_scripts_classes[22m | [39m[0m
[92m[ DONE ][39m [1mupdate_scripts_classes[22m
[0m
[   0% ] [90m[1m_update_scan_actions[22m | Started Сканирование действий… (9 steps)[39m[0m
[   0% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_0.png[39m[0m
[  10% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_1.png[39m[0m
[  20% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_2.png[39m[0m
[  30% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_3.png[39m[0m
[  40% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_4.png[39m[0m
[  50% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_5.png[39m[0m
[  60% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_6.png[39m[0m
[  70% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_7.png[39m[0m
[  80% ] [90m[1m_update_scan_actions[22m | blood_relief_r1d.png[39m[0m
[92m[ DONE ][39m [1m_update_scan_actions[22m
[0m
[   0% ] [90m[1mreimport[22m | Started Импорт или повторный импорт ассетов (1 steps)[39m[0m
[   0% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[   0% ] [90m[1mreimport[22m | Выполнение предимпортных операций…[39m[0m
[   0% ] [90m[1mreimport[22m | blood_relief_r1d.png[39m[0m
[  50% ] [90m[1mreimport[22m | Завершение импорта активов…[39m[0m
[92m[ DONE ][39m [1mreimport[22m
[0m
[   0% ] [90m[1mreimport[22m | Started Импорт или повторный импорт ассетов (1 steps)[39m[0m
[   0% ] [90m[1mreimport[22m | Выполнение операций после реимпорта…[39m[0m
[92m[ DONE ][39m [1mreimport[22m
[0m
[   0% ] [90m[1mloading_editor_layout[22m | Started Загрузка редактора (5 steps)[39m[0m
[   0% ] [90m[1mloading_editor_layout[22m | Загрузка макета редактора…[39m[0m
[  16% ] [90m[1mloading_editor_layout[22m | Загрузка док-панели…[39m[0m
[92m[ DONE ][39m [1mloading_editor_layout[22m
[0m

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_import_rivers_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d --import
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
[   0% ] [90m[1mupdate_scripts_classes[22m | Started Регистрация глобальных классов… (2 steps)[39m[0m
[   0% ] [90m[1mupdate_scripts_classes[22m | FloorDecals[39m[0m
[  33% ] [90m[1mupdate_scripts_classes[22m | [39m[0m
[92m[ DONE ][39m [1mupdate_scripts_classes[22m
[0m
[   0% ] [90m[1mloading_editor_layout[22m | Started Загрузка редактора (5 steps)[39m[0m
[   0% ] [90m[1mloading_editor_layout[22m | Загрузка макета редактора…[39m[0m
[  16% ] [90m[1mloading_editor_layout[22m | Загрузка док-панели…[39m[0m
[92m[ DONE ][39m [1mloading_editor_layout[22m
[0m

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_import_texture.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d --import
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
[   0% ] [90m[1m_update_scan_actions[22m | Started Сканирование действий… (9 steps)[39m[0m
[   0% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_0.png[39m[0m
[  10% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_1.png[39m[0m
[  20% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_2.png[39m[0m
[  30% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_3.png[39m[0m
[  40% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_4.png[39m[0m
[  50% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_5.png[39m[0m
[  60% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_6.png[39m[0m
[  70% ] [90m[1m_update_scan_actions[22m | blood_pool_r1d_7.png[39m[0m
[  80% ] [90m[1m_update_scan_actions[22m | blood_relief_r1d.png[39m[0m
[92m[ DONE ][39m [1m_update_scan_actions[22m
[0m
[   0% ] [90m[1mreimport[22m | Started Импорт или повторный импорт ассетов (9 steps)[39m[0m
[   0% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  10% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  20% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  30% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  40% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  50% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  60% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  70% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  80% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[   0% ] [90m[1mreimport[22m | Выполнение предимпортных операций…[39m[0m
[   0% ] [90m[1mreimport[22m | blood_pool_r1d_0.png[39m[0m
[  10% ] [90m[1mreimport[22m | blood_pool_r1d_1.png[39m[0m
[  20% ] [90m[1mreimport[22m | blood_pool_r1d_2.png[39m[0m
[  30% ] [90m[1mreimport[22m | blood_pool_r1d_3.png[39m[0m
[  40% ] [90m[1mreimport[22m | blood_pool_r1d_4.png[39m[0m
[  50% ] [90m[1mreimport[22m | blood_pool_r1d_5.png[39m[0m
[  60% ] [90m[1mreimport[22m | blood_pool_r1d_6.png[39m[0m
[  70% ] [90m[1mreimport[22m | blood_pool_r1d_7.png[39m[0m
[  80% ] [90m[1mreimport[22m | blood_relief_r1d.png[39m[0m
[  90% ] [90m[1mreimport[22m | Завершение импорта активов…[39m[0m
[92m[ DONE ][39m [1mreimport[22m
[0m
[   0% ] [90m[1mreimport[22m | Started Импорт или повторный импорт ассетов (9 steps)[39m[0m
[   0% ] [90m[1mreimport[22m | Выполнение операций после реимпорта…[39m[0m
[92m[ DONE ][39m [1mreimport[22m
[0m
[   0% ] [90m[1mloading_editor_layout[22m | Started Загрузка редактора (5 steps)[39m[0m
[   0% ] [90m[1mloading_editor_layout[22m | Загрузка макета редактора…[39m[0m
[  16% ] [90m[1mloading_editor_layout[22m | Загрузка док-панели…[39m[0m
[92m[ DONE ][39m [1mloading_editor_layout[22m
[0m

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_meta_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --meta-test --r1d
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=337.40 seed=81073
S7SETTINGS migration_v1_v4=true progress_preserved=true roundtrip=true sanitize=true temporary_save=true
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792416972
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792416972
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792416972
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792416972
Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в user://test_save.json.campaign-bad-8100140
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

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_meta_rivers_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --meta-test --r1d
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=180.61 seed=81073
S7SETTINGS migration_v1_v4=true progress_preserved=true roundtrip=true sanitize=true temporary_save=true
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792420650
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792420650
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792420650
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792420650
Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в user://test_save.json.campaign-bad-4247529
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

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_obstacles_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --obstacles-test --fresh-save
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=496.61 seed=81073
OBSTEST layout cars=27 barrels=20 objects=409 seed=81073
OBSTEST simulation seconds=10 alive=500 penetrations=0
OBSTEST simulation seconds=20 alive=500 penetrations=0
OBSTEST simulation seconds=30 alive=500 penetrations=0
OBSTEST simulation seconds=40 alive=500 penetrations=0
OBSTEST simulation seconds=50 alive=500 penetrations=0
OBSTEST simulation seconds=60 alive=500 penetrations=0
OBSTEST wall arrived=500/500 nav_worst_us=394
OBSTEST ok=true penetrations=0 arrived=500 detonations=3 blood_events=2

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_obstacles_rivers_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --obstacles-test --fresh-save
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=262.32 seed=81073
OBSTEST layout cars=27 barrels=20 objects=409 seed=81073
OBSTEST simulation seconds=10 alive=500 penetrations=0
OBSTEST simulation seconds=20 alive=500 penetrations=0
OBSTEST simulation seconds=30 alive=500 penetrations=0
OBSTEST simulation seconds=40 alive=500 penetrations=0
OBSTEST simulation seconds=50 alive=500 penetrations=0
OBSTEST simulation seconds=60 alive=500 penetrations=0
OBSTEST wall arrived=500/500 nav_worst_us=203
OBSTEST ok=true penetrations=0 arrived=500 detonations=3 blood_events=2

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_profile_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --gore-profile
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:35:06
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=428.69 seed=81073
R1DCOST scripts/floor_decals.gd avg_us=194.226666666667
R1DCOST scripts/gore.gd avg_us=1048.155
R1DCOST scripts/effects.gd avg_us=794.896666666667
BENCH frames=457 avg_fps=45.7 avg_frame_ms=21.90 worst_frame_ms=139.47 horde_ms=4.52 enemies=499 kills=864
BENCH process_ms=11.11 physics_ms=20.91 draw_calls=583 objects=4050 gore=359 particles=673 wet=128
BENCH physics_avg_ms=22.38 hud_ms=0.610
R1PROFILE static=151131737 video=343842816 gpu_last_ms=3.642 remains=200 remains_peak=200 stamps=49896 queue=112
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_profile_before.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --loadout --bench=500 --fresh-save --gore-profile
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:34:40
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=416.63 seed=81073
R1DCOST scripts/floor_decals.gd avg_us=200.445
R1DCOST scripts/gore.gd avg_us=1255.45833333333
R1DCOST scripts/effects.gd avg_us=611.321666666667
BENCH frames=486 avg_fps=48.6 avg_frame_ms=20.58 worst_frame_ms=146.54 horde_ms=4.63 enemies=499 kills=927
BENCH process_ms=9.58 physics_ms=21.55 draw_calls=516 objects=4012 gore=182 particles=581 wet=107
BENCH physics_avg_ms=19.19 hud_ms=0.578
R1PROFILE static=146918078 video=342597632 gpu_last_ms=3.322 remains=200 remains_peak=200 stamps=46614 queue=51
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_q1_final.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --q1-test --fresh-save --r1d
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:47:01
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=570.44 seed=81073
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
Q1TEST screenshot_levelup=true
Q1TEST pad_held_does_not_install=true
Q1TEST pad_install_open=true
Q1TEST pad_install_back=true
Q1TEST pad_module_applied=true
Q1TEST screenshot_trader=true
Q1TEST pad_purchase=true
Q1TEST pad_shop_install_open=true
Q1TEST pad_shop_install_bought=true
Q1TEST pad_shop_close=true
Q1TEST slider_applies_immediately=true
Q1SLIDER movements=100 save_calls=1
Q1TEST slider_one_save=true
Q1TEST slider_disk_roundtrip=true
Q1TEST slider_debounce_then_close_one_save=true
Q1TEST checks=27 failed=0 ok=true
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[2668, 3168, 5440, 6200, 9408, 9448, 13204, 16284]
EXIT_CODE=0
```

## r1d_q1_rivers_final.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --q1-test --fresh-save --r1d
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 17:59:02
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=285.81 seed=81073
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
Q1TEST screenshot_levelup=true
Q1TEST pad_held_does_not_install=true
Q1TEST pad_install_open=true
Q1TEST pad_install_back=true
Q1TEST pad_module_applied=true
Q1TEST screenshot_trader=true
Q1TEST pad_purchase=true
Q1TEST pad_shop_install_open=true
Q1TEST pad_shop_install_bought=true
Q1TEST pad_shop_close=true
Q1TEST slider_applies_immediately=true
Q1SLIDER movements=100 save_calls=1
Q1TEST slider_one_save=true
Q1TEST slider_disk_roundtrip=true
Q1TEST slider_debounce_then_close_one_save=true
Q1TEST checks=27 failed=0 ok=true
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_retention_final.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --r1d-shots --r1d --r1d-retention
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:48:18
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=341.28 seed=81073
R1DCHECK actual_RT_600s=true fresh=(0.9882, 0.9882, 0.0, 1.0) dried=(0.9882, 0.0157, 0.0, 1.0) size=(2560, 1440) bytes_two_RGBA8=73728000
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_retention_rivers.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --r1d-shots --r1d --r1d-retention
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 17:44:25
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=245.01 seed=81073
R1DCHECK actual_RT_600s=true fresh=(0.851, 0.8706, 0.0, 0.8706) dried=(0.851, 0.0157, 0.0, 0.8706) size=(2560, 1440) bytes_two_RGBA8=73728000
R1DCHECK repeated_spill_varied=true thickness=0.341..0.980 gaps=36437 soft=2662 localized=true
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_retention_rivers_final.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --r1d-shots --r1d --r1d-retention
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 18:00:14
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=260.63 seed=81073
R1DCHECK actual_RT_600s=true fresh=(0.851, 0.8706, 0.0, 0.8706) dried=(0.851, 0.0157, 0.0, 0.8706) size=(2560, 1440) bytes_two_RGBA8=73728000
R1DCHECK repeated_spill_varied=true thickness=0.341..0.980 gaps=36437 soft=2662 localized=true
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_shots_before.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --gore-shots --r1d --r1d-before --shot=res://design/tasks/reports/r1d_fight_before.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:25:31
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=287.69 seed=81073
R1DSTAND hits=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=300ms camera=3 suffix=_before
R1DPALETTE surface=0 age=0 thin=463539 thick=311114
R1DPALETTE surface=0 age=1 thin=3e3c40 thick=2f282b
R1DPALETTE surface=0 age=2 thin=39383c thick=333134
R1DPALETTE surface=1 age=0 thin=7f6048 thick=441f1a
R1DPALETTE surface=1 age=1 thin=7b694c thick=5f4d39
R1DPALETTE surface=1 age=2 thin=7f6f51 thick=6d5d45
R1DPALETTE surface=2 age=0 thin=5a4743 thick=381718
R1DPALETTE surface=2 age=1 thin=54514b thick=423b37
R1DPALETTE surface=2 age=2 thin=51514b thick=484540
GORESTAND seconds=60 debris=50 peak=93 remains=95 remains_peak=174 stamps=32133 queue=0 pools=17 memory=140863635 video=325623808
GORESTAND seconds=300 debris=44 peak=110 remains=131 remains_peak=186 stamps=154901 queue=0 pools=16 memory=140871039 video=325754880
GORESTAND screenshot: res://design/tasks/reports/r1d_fight_before_5min.png
GORESTAND fight simultaneous_hits=49 camera=3 screenshot=res://design/tasks/reports/r1d_fight_before_5min.png
GORESTAND seconds=480 debris=63 peak=110 remains=106 remains_peak=186 stamps=247210 queue=0 pools=16 memory=141010887 video=325623808
GORESTAND seconds=600 debris=27 peak=110 remains=131 remains_peak=186 stamps=308650 queue=0 pools=14 memory=141007063 video=325623808
GORESTAND screenshot: res://design/tasks/reports/r1d_fight_before_10min.png
GORESTAND fight simultaneous_hits=49 camera=3 screenshot=res://design/tasks/reports/r1d_fight_before_10min.png
GORESTAND complete seed=81073 deaths=7200 zoom=3 map=quarantine_checkpoint
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[3964, 11960]
EXIT_CODE=0
```

## r1d_shots_final.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --gore-shots --r1d --shot=res://design/tasks/reports/r1d_fight.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:48:02
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=265.41 seed=81073
R1DSTAND hits=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=300ms camera=3 suffix=
R1DPALETTE surface=0 age=0 thin=720c12 thick=2e0306
R1DPALETTE surface=0 age=1 thin=411210 thick=1d0606
R1DPALETTE surface=0 age=2 thin=31140f thick=170606
R1DPALETTE surface=1 age=0 thin=740e12 thick=2e0306
R1DPALETTE surface=1 age=1 thin=431411 thick=1d0606
R1DPALETTE surface=1 age=2 thin=331610 thick=170606
R1DPALETTE surface=2 age=0 thin=730d12 thick=2e0306
R1DPALETTE surface=2 age=1 thin=421310 thick=1d0606
R1DPALETTE surface=2 age=2 thin=311510 thick=170606
R1DCHECK palette_pixels=true
GORESTAND seconds=60 debris=50 peak=92 remains=95 remains_peak=179 stamps=32183 queue=0 pools=48 memory=142075601 video=282763264
GORESTAND seconds=300 debris=48 peak=113 remains=127 remains_peak=193 stamps=154993 queue=0 pools=48 memory=142081753 video=282828800
GORESTAND screenshot: res://design/tasks/reports/r1d_fight_5min.png
GORESTAND fight simultaneous_hits=49 camera=3 screenshot=res://design/tasks/reports/r1d_fight_5min.png
R1DSTAND activity_visible=true position=(1155.0, 755.0)
GORESTAND seconds=480 debris=64 peak=113 remains=107 remains_peak=193 stamps=247328 queue=0 pools=40 memory=142240721 video=282107904
GORESTAND seconds=600 debris=26 peak=113 remains=117 remains_peak=193 stamps=308768 queue=0 pools=40 memory=142236401 video=282107904
GORESTAND screenshot: res://design/tasks/reports/r1d_fight_10min.png
GORESTAND fight simultaneous_hits=49 camera=3 screenshot=res://design/tasks/reports/r1d_fight_10min.png
R1DSTAND activity_visible=true position=(1155.0, 755.0)
GORESTAND complete seed=81073 deaths=7200 zoom=3 map=quarantine_checkpoint
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_shots_rivers.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --gore-shots --r1d --shot=res://design/tasks/reports/r1d_fight.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 17:24:18
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=294.51 seed=81073
R1DSTAND hits=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=300ms camera=3 suffix=
R1DPALETTE surface=0 age=0 thin=720c12 thick=2e0306
R1DPALETTE surface=0 age=1 thin=3e1310 thick=1c0606
R1DPALETTE surface=0 age=2 thin=31140f thick=170606
R1DPALETTE surface=1 age=0 thin=740e12 thick=2e0306
R1DPALETTE surface=1 age=1 thin=401410 thick=1c0606
R1DPALETTE surface=1 age=2 thin=331610 thick=170606
R1DPALETTE surface=2 age=0 thin=730d12 thick=2e0306
R1DPALETTE surface=2 age=1 thin=3f1310 thick=1c0606
R1DPALETTE surface=2 age=2 thin=311510 thick=170606
R1DCHECK palette_pixels=true
GORESTAND seconds=60 debris=50 peak=92 remains=95 remains_peak=179 stamps=32183 queue=0 pools=48 memory=141080699 video=283287552
GORESTAND seconds=300 debris=48 peak=113 remains=127 remains_peak=193 stamps=154993 queue=0 pools=48 memory=141086739 video=283353088
GORESTAND screenshot: res://design/tasks/reports/r1d_fight_5min.png
GORESTAND fight simultaneous_hits=49 camera=3 screenshot=res://design/tasks/reports/r1d_fight_5min.png
R1DSTAND activity_visible=true position=(1155.0, 755.0)
GORESTAND seconds=480 debris=64 peak=113 remains=107 remains_peak=193 stamps=247342 queue=0 pools=40 memory=141244463 video=283287552
GORESTAND seconds=600 debris=26 peak=113 remains=117 remains_peak=193 stamps=308782 queue=0 pools=40 memory=141241575 video=283287552
GORESTAND screenshot: res://design/tasks/reports/r1d_fight_10min.png
GORESTAND fight simultaneous_hits=49 camera=3 screenshot=res://design/tasks/reports/r1d_fight_10min.png
R1DSTAND activity_visible=true position=(1155.0, 755.0)
GORESTAND complete seed=81073 deaths=7200 zoom=3 map=quarantine_checkpoint
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_shots_rivers_final.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --gore-shots --r1d --shot=res://design/tasks/reports/r1d_fight.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 17:59:55
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=292.72 seed=81073
R1DSTAND hits=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=300ms camera=3 suffix=
R1DPALETTE surface=0 age=0 thin=720c12 thick=2e0306
R1DPALETTE surface=0 age=1 thin=3e1310 thick=1c0606
R1DPALETTE surface=0 age=2 thin=31140f thick=170606
R1DPALETTE surface=1 age=0 thin=740e12 thick=2e0306
R1DPALETTE surface=1 age=1 thin=401410 thick=1c0606
R1DPALETTE surface=1 age=2 thin=331610 thick=170606
R1DPALETTE surface=2 age=0 thin=730d12 thick=2e0306
R1DPALETTE surface=2 age=1 thin=3f1310 thick=1c0606
R1DPALETTE surface=2 age=2 thin=311510 thick=170606
R1DCHECK palette_pixels=true
GORESTAND seconds=60 debris=50 peak=92 remains=95 remains_peak=179 stamps=32183 queue=0 pools=48 memory=141363745 video=283287552
GORESTAND seconds=300 debris=48 peak=113 remains=127 remains_peak=193 stamps=154993 queue=0 pools=48 memory=141369785 video=283353088
GORESTAND screenshot: res://design/tasks/reports/r1d_fight_5min.png
GORESTAND fight simultaneous_hits=49 camera=3 screenshot=res://design/tasks/reports/r1d_fight_5min.png
R1DSTAND activity_visible=true position=(1155.0, 755.0)
GORESTAND seconds=480 debris=64 peak=113 remains=107 remains_peak=193 stamps=247342 queue=0 pools=40 memory=141527509 video=283287552
GORESTAND seconds=600 debris=26 peak=113 remains=117 remains_peak=193 stamps=308782 queue=0 pools=40 memory=141525269 video=283287552
GORESTAND screenshot: res://design/tasks/reports/r1d_fight_10min.png
GORESTAND fight simultaneous_hits=49 camera=3 screenshot=res://design/tasks/reports/r1d_fight_10min.png
R1DSTAND activity_visible=true position=(1155.0, 755.0)
GORESTAND complete seed=81073 deaths=7200 zoom=3 map=quarantine_checkpoint
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_shots_seamless.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --gore-shots --r1d --shot=res://design/tasks/reports/r1d_fight.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 17:28:45
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
SCRIPT ERROR: Parse Error: Cannot infer the type of "stepped" variable because the value doesn't have a set type.
   at: GDScript::reload (res://scripts/game.gd:4270)
ERROR: Failed to load script "res://scripts/game.gd" with error "Parse error".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
TESTRESULT ok=false errors=2
SCRIPT ERROR: Invalid access to property or key 'player' on a base object of type 'Node2D'.
   at: _draw (res://scripts/hud.gd:349)
   GDScript backtrace (most recent call first):
       [0] _draw (res://scripts/hud.gd:349)
SCRIPT ERROR: Invalid access to property or key 'player' on a base object of type 'Node2D'.
   at: _draw_overlay (res://scripts/hud.gd:397)
   GDScript backtrace (most recent call first):
       [0] _draw_overlay (res://scripts/hud.gd:397)
       [1] _draw (res://scripts/hud.gd:75)

R1DGUARD foreign_during=[]
EXIT_CODE=1
```

## r1d_shots_seamless2.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --gore-shots --r1d --shot=res://design/tasks/reports/r1d_fight.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 17:32:05
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=235.63 seed=81073
R1DSTAND hits=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=300ms camera=3 suffix=
R1DPALETTE surface=0 age=0 thin=720c12 thick=2e0306
R1DPALETTE surface=0 age=1 thin=3e1310 thick=1c0606
R1DPALETTE surface=0 age=2 thin=31140f thick=170606
R1DPALETTE surface=1 age=0 thin=740e12 thick=2e0306
R1DPALETTE surface=1 age=1 thin=401410 thick=1c0606
R1DPALETTE surface=1 age=2 thin=331610 thick=170606
R1DPALETTE surface=2 age=0 thin=730d12 thick=2e0306
R1DPALETTE surface=2 age=1 thin=3f1310 thick=1c0606
R1DPALETTE surface=2 age=2 thin=311510 thick=170606
R1DCHECK palette_pixels=true
GORESTAND seconds=60 debris=50 peak=92 remains=95 remains_peak=179 stamps=32183 queue=0 pools=48 memory=140895345 video=283287552
GORESTAND seconds=300 debris=48 peak=113 remains=127 remains_peak=193 stamps=154993 queue=0 pools=48 memory=140901385 video=283353088
GORESTAND screenshot: res://design/tasks/reports/r1d_fight_5min.png
GORESTAND fight simultaneous_hits=49 camera=3 screenshot=res://design/tasks/reports/r1d_fight_5min.png
R1DSTAND activity_visible=true position=(1155.0, 755.0)
GORESTAND seconds=480 debris=64 peak=113 remains=107 remains_peak=193 stamps=247342 queue=0 pools=40 memory=141059385 video=283287552
GORESTAND seconds=600 debris=26 peak=113 remains=117 remains_peak=193 stamps=308782 queue=0 pools=40 memory=141057145 video=283287552
GORESTAND screenshot: res://design/tasks/reports/r1d_fight_10min.png
GORESTAND fight simultaneous_hits=49 camera=3 screenshot=res://design/tasks/reports/r1d_fight_10min.png
R1DSTAND activity_visible=true position=(1155.0, 755.0)
GORESTAND complete seed=81073 deaths=7200 zoom=3 map=quarantine_checkpoint
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_shots_texture.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --gore-shots --r1d --shot=res://design/tasks/reports/r1d_fight.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 17:17:53
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=470.64 seed=81073
R1DSTAND hits=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=300ms camera=3 suffix=
R1DPALETTE surface=0 age=0 thin=4b3135 thick=2e0306
R1DPALETTE surface=0 age=1 thin=3e3436 thick=1c0606
R1DPALETTE surface=0 age=2 thin=373031 thick=170606
R1DPALETTE surface=1 age=0 thin=7e5842 thick=2e0306
R1DPALETTE surface=1 age=1 thin=6f5840 thick=1c0606
R1DPALETTE surface=1 age=2 thin=6d5b42 thick=170606
R1DPALETTE surface=2 age=0 thin=5c423f thick=2e0306
R1DPALETTE surface=2 age=1 thin=504540 thick=1c0606
R1DPALETTE surface=2 age=2 thin=4a433d thick=170606
R1DCHECK palette_pixels=false
SCRIPT ERROR: Assertion failed.
   at: _r1d_palette (res://scripts/game.gd:4428)
   GDScript backtrace (most recent call first):
       [0] _r1d_palette (res://scripts/game.gd:4428)
TESTRESULT ok=false errors=1
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=1
```

## r1d_shots_texture2.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --gore-shots --r1d --shot=res://design/tasks/reports/r1d_fight.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 17:20:55
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=343.15 seed=81073
R1DSTAND hits=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=300ms camera=3 suffix=
R1DPALETTE surface=0 age=0 thin=720c12 thick=2e0306
R1DPALETTE surface=0 age=1 thin=3e1310 thick=1c0606
R1DPALETTE surface=0 age=2 thin=31140f thick=170606
R1DPALETTE surface=1 age=0 thin=740e12 thick=2e0306
R1DPALETTE surface=1 age=1 thin=401410 thick=1c0606
R1DPALETTE surface=1 age=2 thin=331610 thick=170606
R1DPALETTE surface=2 age=0 thin=730d12 thick=2e0306
R1DPALETTE surface=2 age=1 thin=3f1310 thick=1c0606
R1DPALETTE surface=2 age=2 thin=311510 thick=170606
R1DCHECK palette_pixels=true
GORESTAND seconds=60 debris=50 peak=92 remains=95 remains_peak=179 stamps=32183 queue=0 pools=48 memory=141482056 video=283287552
GORESTAND seconds=300 debris=48 peak=113 remains=127 remains_peak=193 stamps=154993 queue=0 pools=48 memory=141488880 video=283353088
GORESTAND screenshot: res://design/tasks/reports/r1d_fight_5min.png
GORESTAND fight simultaneous_hits=49 camera=3 screenshot=res://design/tasks/reports/r1d_fight_5min.png
R1DSTAND activity_visible=true position=(1155.0, 755.0)
GORESTAND seconds=480 debris=64 peak=113 remains=107 remains_peak=193 stamps=247328 queue=0 pools=40 memory=141646704 video=283942912
GORESTAND seconds=600 debris=26 peak=113 remains=117 remains_peak=193 stamps=308768 queue=0 pools=40 memory=141643704 video=283287552
GORESTAND screenshot: res://design/tasks/reports/r1d_fight_10min.png
GORESTAND fight simultaneous_hits=49 camera=3 screenshot=res://design/tasks/reports/r1d_fight_10min.png
R1DSTAND activity_visible=true position=(1155.0, 755.0)
GORESTAND complete seed=81073 deaths=7200 zoom=3 map=quarantine_checkpoint
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_shots_trial.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --fresh-save --gore-shots --r1d --shot=res://design/tasks/reports/r1d_fight.png
R1DGUARD before_godot=0
GODOT_EXCLUSIVE other_godot_processes=0 at 16:27:54
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=656.39 seed=81073
R1DSTAND hits=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=300ms camera=3 suffix=
R1DPALETTE surface=0 age=0 thin=720c12 thick=2e0306
R1DPALETTE surface=0 age=1 thin=411210 thick=1d0606
R1DPALETTE surface=0 age=2 thin=31140f thick=170606
R1DPALETTE surface=1 age=0 thin=740e12 thick=2e0306
R1DPALETTE surface=1 age=1 thin=431411 thick=1d0606
R1DPALETTE surface=1 age=2 thin=331610 thick=170606
R1DPALETTE surface=2 age=0 thin=730d12 thick=2e0306
R1DPALETTE surface=2 age=1 thin=421310 thick=1d0606
R1DPALETTE surface=2 age=2 thin=311510 thick=170606
GORESTAND seconds=60 debris=50 peak=92 remains=97 remains_peak=183 stamps=32172 queue=0 pools=43 memory=140792725 video=327327744
GORESTAND seconds=300 debris=47 peak=115 remains=126 remains_peak=192 stamps=154973 queue=0 pools=42 memory=140799693 video=326737920
GORESTAND screenshot: res://design/tasks/reports/r1d_fight_5min.png
GORESTAND fight simultaneous_hits=49 camera=3 screenshot=res://design/tasks/reports/r1d_fight_5min.png
GORESTAND seconds=480 debris=67 peak=115 remains=106 remains_peak=193 stamps=247307 queue=0 pools=34 memory=140946001 video=327327744
GORESTAND seconds=600 debris=26 peak=115 remains=116 remains_peak=193 stamps=308747 queue=0 pools=31 memory=140943081 video=327327744
GORESTAND screenshot: res://design/tasks/reports/r1d_fight_10min.png
GORESTAND fight simultaneous_hits=49 camera=3 screenshot=res://design/tasks/reports/r1d_fight_10min.png
GORESTAND complete seed=81073 deaths=7200 zoom=3 map=quarantine_checkpoint
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_sim_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --sim=600 --fresh-save --layout-seed=81073
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=359.94 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
PICK lvl=2 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["weapon", "passive", "weapon"]
PICK lvl=3 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["ammo", "weapon", "level"]
ACTIVITY event=start kind=carrier time=57.47 age=0.00 pos=(1448.0, 920.0) offered=1 success=0 failed=0 rewards=0
SIM 01:00 level=3 kills=39 xp=35/39 credits=2/2 credits_left=2 zombies=47 kinds=46/1/0/0 elites=0 elites_spawned=0 crates=0 nades=1 dmg_taken=37 peak=50 fps=143 | АК-С L2 Стан1 []
ACTIVITY event=success kind=carrier time=63.80 age=6.33 pos=(1448.16, 727.7033) offered=1 success=1 failed=0 rewards=1
PICK lvl=4 { "type": "module", "id": 3, "rare": false } slot=0 of ["weapon", "level", "module"]
PICK lvl=5 { "type": "weapon", "id": 1, "rare": false } slot=-1 of ["weapon", "ammo", "module"]
PICK lvl=6 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "level", "weapon"]
PICK lvl=7 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "level", "ammo"]
PICK lvl=8 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["weapon", "level", "passive"]
SIM 02:00 level=8 kills=262 xp=282/297 credits=17/17 credits_left=17 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=0 crates=0 nades=7 dmg_taken=70 peak=75 fps=145 | АК-С L3 Стан1 [Дето1] | Мясник L3 Стан1 []
ACTIVITY event=start kind=supply time=152.87 age=0.00 pos=(1077.779, 947.8593) offered=2 success=1 failed=0 rewards=1
ACTIVITY event=success kind=supply time=174.07 age=21.20 pos=(1077.779, 947.8593) offered=2 success=2 failed=0 rewards=2
LOOT СНАБЖЕНИЕ: module slot=0 rare=false
PICK lvl=9 { "type": "weapon", "id": 4, "rare": false } slot=-1 of ["ammo", "weapon", "weapon"]
SIM 03:00 level=9 kills=410 xp=393/445 credits=21/24 credits_left=21 zombies=113 kinds=113/0/0/0 elites=0 elites_spawned=0 crates=0 nades=11 dmg_taken=124 peak=138 fps=145 | АК-С L3 Стан1 [Дето1,Цепь1] | Мясник L3 Стан1 [] | Кольт L1 Стан1 []
PICK lvl=10 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["level", "ammo", "module"]
PICK lvl=11 { "type": "ammo", "id": 0, "rare": true } slot=0 of ["level", "ammo", "weapon"]
PICK lvl=12 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "level", "level"]
SIM 04:00 level=12 kills=750 xp=821/824 credits=58/58 credits_left=58 zombies=49 kinds=39/0/10/0 elites=0 elites_spawned=0 crates=0 nades=17 dmg_taken=1098 peak=113 fps=145 | АК-С L3 Стан3 [Дето1,Цепь1] | Мясник L4 Стан1 [] | Кольт L1 Стан1 []
PICK lvl=13 { "type": "weapon", "id": 6, "rare": false } slot=-1 of ["weapon", "level", "weapon"]
PICK lvl=14 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "level", "passive"]
TRADER 0 at 05:00 credits_left=39 bought=["ammo(40)"]
SIM 05:00 level=14 kills=1065 xp=1131/1229 credits=79/90 credits_left=39 zombies=90 kinds=67/8/15/0 elites=0 elites_spawned=0 crates=0 nades=22 dmg_taken=1389 peak=138 fps=145 | АК-С L3 Крио1 [Дето1,Цепь1] | Мясник L4 Стан1 [] | Кольт L1 Стан1 [] | ППШ L2 Стан1 []
PICK lvl=15 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["passive", "passive", "passive"]
PICK lvl=16 { "type": "ammo", "id": 1, "rare": true } slot=0 of ["passive", "level", "ammo"]
ACTIVITY event=start kind=fuel time=328.07 age=0.00 pos=(1029.617, 1300.659) offered=3 success=2 failed=0 rewards=2
ACTIVITY event=success kind=fuel time=341.73 age=13.67 pos=(1029.617, 1300.659) offered=3 success=3 failed=0 rewards=3
PICK lvl=17 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "ammo", "passive"]
SIM 06:00 level=17 kills=1447 xp=1715/1787 credits=157/184 credits_left=117 zombies=137 kinds=87/22/15/13 elites=1 elites_spawned=2 crates=0 nades=26 dmg_taken=1682 peak=140 fps=145 | АК-С L3 Эксп1 [Дето1,Цепь1] | Мясник L4 Стан1 [] | Кольт L1 Стан1 [] | ППШ L3 Стан1 []
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=1 rare=true
PICK lvl=18 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["module", "passive", "module"]
PICK lvl=19 { "type": "module", "id": 5, "rare": true } slot=0 of ["level", "module", "level"]
SIM 07:00 level=19 kills=1951 xp=2408/2548 credits=256/299 credits_left=216 zombies=113 kinds=80/8/12/13 elites=0 elites_spawned=4 crates=0 nades=30 dmg_taken=2174 peak=167 fps=145 | АК-С L3 Эксп1 [Дето1,Цепь2] | Мясник L4 Стан1 [Спли1] | Кольт L1 Стан1 [] | ППШ L3 Стан1 []
ALARM_EVENT warn time=07:00
PICK lvl=20 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["level", "level", "module"]
ALARM_EVENT start time=07:03
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=1 rare=true
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=1 rare=true
PICK lvl=21 { "type": "module", "id": 3, "rare": false } slot=0 of ["level", "module", "module"]
PICK lvl=22 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["module", "level", "ammo"]
PICK lvl=23 { "type": "module", "id": 1, "rare": false } slot=2 of ["level", "module", "ammo"]
PICK lvl=24 { "type": "ammo", "id": 1, "rare": false } slot=0 of ["level", "ammo", "ammo"]
ALARM_EVENT finish container=(1643.51, 1362.282) time=07:33
CONTAINER dropped pos=(1643.51, 1362.282) time=07:33
ALARM rewards mult=2 xp=1542 credits=274
LOOT СБРОС СНАБЖЕНИЯ: module slot=2 rare=false
CONTAINER picked time=07:34 crates=2
PICK lvl=25 { "type": "module", "id": 5, "rare": false } slot=0 of ["module", "level", "module"]
SIM 08:00 level=25 kills=2972 xp=4303/4835 credits=573/663 credits_left=533 zombies=91 kinds=52/0/31/8 elites=0 elites_spawned=10 crates=2 nades=37 dmg_taken=4438 peak=381 fps=145 | АК-С L3 Эксп1 [Дето2,Цепь3] | Мясник L4 Стан1 [Спли2,Сдво1] | Кольт L2 Стан1 [Проб2] | ППШ L3 Стан1 []
PICK lvl=26 { "type": "module", "id": 5, "rare": false } slot=3 of ["module", "ammo", "passive"]
PICK lvl=27 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "level", "ammo"]
PICK lvl=28 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "passive", "module"]
CALM 09:00 removed=19 left=37
TRADER 1 at 09:00 credits_left=197 bought=["passive(60)", "module(150)", "module(60)", "ammo(150)", "level(75)"]
SIM 09:00 level=28 kills=3670 xp=5401/5931 credits=732/816 credits_left=197 zombies=56 kinds=30/11/6/9 elites=0 elites_spawned=12 crates=3 nades=41 dmg_taken=5021 peak=162 fps=140 | АК-С L3 Зажи1 [Дето2,Цепь3] | Мясник L4 Стан1 [Спли3,Сдво2] | Кольт L2 Стан1 [Проб2] | ППШ L5 Стан1 [Цепь1]
PICK lvl=29 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "passive", "level"]
BOSS spawn t=600.00 pos=(1680.911, 1181.779) hp=24000
SIM 10:00 level=29 kills=3888 xp=6123/6210 credits=817/851 credits_left=282 zombies=31 kinds=31/0/0/0 elites=0 elites_spawned=14 crates=3 nades=44 dmg_taken=5034 peak=71 fps=132 | АК-С L3 Зажи1 [Дето2,Цепь3] | Мясник L5 Стан1 [Спли3,Сдво2] | Кольт L2 Стан1 [Проб2] | ППШ L5 Стан1 [Цепь1]
SIM summary kills=3888 peak=381 level=29 damage=5033.88 boss_alive=true

R1DGUARD foreign_during=[]
EXIT_CODE=0
```

## r1d_sim_rivers_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1d\design\tasks\reports\R1d_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1d -- --sim=600 --fresh-save --layout-seed=81073
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=175.64 seed=81073
ACTIVITIES seed=81073 map=quarantine_checkpoint schedule=[{ "time": 57.4466171264648, "kind": 1 }, { "time": 152.862487792969, "kind": 0 }, { "time": 328.002532958984, "kind": 2 }]
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
PICK lvl=2 { "type": "weapon", "id": 1, "rare": false } slot=-1 of ["weapon", "passive", "passive"]
PICK lvl=3 { "type": "module", "id": 4, "rare": false } slot=0 of ["module", "passive", "level"]
ACTIVITY event=start kind=carrier time=57.47 age=0.00 pos=(1376.224, 767.011) offered=1 success=0 failed=0 rewards=0
SIM 01:00 level=3 kills=56 xp=34/56 credits=3/4 credits_left=3 zombies=31 kinds=30/1/0/0 elites=0 elites_spawned=0 crates=0 nades=0 dmg_taken=6 peak=37 fps=144 | АК-С L1 Стан1 [Сдво1] | Мясник L1 Стан1 []
ACTIVITY event=success kind=carrier time=63.93 age=6.47 pos=(1449.777, 595.3463) offered=1 success=1 failed=0 rewards=1
PICK lvl=4 { "type": "weapon", "id": 6, "rare": false } slot=-1 of ["weapon", "passive", "weapon"]
PICK lvl=5 { "type": "passive", "id": 3, "rare": false } slot=-1 of ["level", "passive", "module"]
PICK lvl=6 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "module", "level"]
SIM 02:00 level=6 kills=198 xp=133/233 credits=11/15 credits_left=11 zombies=66 kinds=66/0/0/0 elites=0 elites_spawned=0 crates=0 nades=3 dmg_taken=72 peak=100 fps=145 | АК-С L2 Стан1 [Сдво1] | Мясник L1 Стан1 [] | ППШ L1 Стан1 []
PICK lvl=7 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["passive", "level", "weapon"]
PICK lvl=8 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "ammo", "ammo"]
PICK lvl=9 { "type": "module", "id": 1, "rare": false } slot=1 of ["level", "module", "passive"]
ACTIVITY event=start kind=supply time=152.87 age=0.00 pos=(792.0, 88.0) offered=2 success=1 failed=0 rewards=1
ACTIVITY event=success kind=supply time=176.60 age=23.73 pos=(792.0, 88.0) offered=2 success=2 failed=0 rewards=2
LOOT СНАБЖЕНИЕ: module slot=1 rare=false
SIM 03:00 level=9 kills=417 xp=402/452 credits=28/30 credits_left=28 zombies=98 kinds=74/24/0/0 elites=0 elites_spawned=0 crates=0 nades=7 dmg_taken=130 peak=109 fps=144 | АК-С L2 Стан1 [Сдво1] | Мясник L3 Стан1 [Проб2] | ППШ L1 Стан1 []
PICK lvl=10 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["ammo", "level", "weapon"]
PICK lvl=11 { "type": "module", "id": 4, "rare": false } slot=0 of ["module", "ammo", "module"]
SIM 04:00 level=11 kills=722 xp=640/775 credits=41/49 credits_left=41 zombies=69 kinds=50/8/11/0 elites=0 elites_spawned=0 crates=0 nades=14 dmg_taken=249 peak=108 fps=145 | АК-С L2 Стан1 [Сдво2] | Мясник L4 Стан1 [Проб2] | ППШ L1 Стан1 []
PICK lvl=12 { "type": "module", "id": 4, "rare": false } slot=0 of ["level", "module", "level"]
PICK lvl=13 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["passive", "ammo", "ammo"]
PICK lvl=14 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "level", "module"]
TRADER 0 at 05:00 credits_left=10 bought=["ammo(40)", "module(40)"]
SIM 05:00 level=14 kills=1112 xp=1207/1276 credits=90/95 credits_left=10 zombies=44 kinds=40/0/4/0 elites=0 elites_spawned=0 crates=0 nades=20 dmg_taken=620 peak=75 fps=145 | АК-С L2 Стан1 [Сдво3] | Мясник L5 Стан1 [Проб2,Цепь1] | ППШ L1 Стан1 []
PICK lvl=15 { "type": "weapon", "id": 3, "rare": false } slot=-1 of ["level", "weapon", "weapon"]
ACTIVITY event=start kind=fuel time=328.07 age=0.00 pos=(1112.739, 709.8325) offered=3 success=2 failed=0 rewards=2
ACTIVITY event=success kind=fuel time=340.73 age=12.67 pos=(1112.739, 709.8325) offered=3 success=3 failed=0 rewards=3
PICK lvl=16 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["module", "level", "level"]
SIM 06:00 level=16 kills=1405 xp=1426/1674 credits=114/153 credits_left=34 zombies=183 kinds=114/12/28/29 elites=1 elites_spawned=2 crates=0 nades=22 dmg_taken=730 peak=183 fps=145 | АК-С L3 Стан1 [Сдво3] | Мясник L5 Стан1 [Проб2,Цепь1] | ППШ L1 Стан1 [] | Гром L1 Стан1 []
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=0 rare=true
PICK lvl=17 { "type": "module", "id": 4, "rare": false } slot=1 of ["level", "module", "passive"]
PICK lvl=18 { "type": "module", "id": 1, "rare": false } slot=1 of ["module", "level", "level"]
PICK lvl=19 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["level", "ammo", "ammo"]
SIM 07:00 level=19 kills=1936 xp=2204/2519 credits=234/285 credits_left=154 zombies=130 kinds=90/9/20/11 elites=0 elites_spawned=4 crates=0 nades=27 dmg_taken=1145 peak=197 fps=145 | АК-С L3 Стан2 [Сдво3,Спли1] | Мясник L5 Стан1 [Проб3,Цепь1,Сдво1] | ППШ L1 Стан1 [] | Гром L1 Стан1 []
ALARM_EVENT warn time=07:00
ALARM_EVENT start time=07:03
PICK lvl=20 { "type": "module", "id": 0, "rare": false } slot=2 of ["level", "level", "module"]
PICK lvl=21 { "type": "module", "id": 0, "rare": false } slot=2 of ["passive", "level", "module"]
ALARM_EVENT finish container=(1315.582, 537.9921) time=07:33
CONTAINER dropped pos=(1315.582, 537.9921) time=07:33
ALARM rewards mult=2 xp=1182 credits=128
LOOT СБРОС СНАБЖЕНИЯ: module slot=3 rare=false
CONTAINER picked time=07:34 crates=1
PICK lvl=22 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["module", "ammo", "level"]
PICK lvl=23 { "type": "module", "id": 4, "rare": false } slot=1 of ["module", "level", "level"]
PICK lvl=24 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["module", "level", "passive"]
SIM 08:00 level=24 kills=3038 xp=3865/4664 credits=425/557 credits_left=345 zombies=14 kinds=0/0/14/0 elites=2 elites_spawned=10 crates=1 nades=32 dmg_taken=2177 peak=464 fps=144 | АК-С L3 Зажи1 [Сдво3,Спли1] | Мясник L5 Стан1 [Проб3,Цепь1,Сдво2] | ППШ L1 Стан1 [Рико2] | Гром L1 Стан1 [Проб1]
PICK lvl=25 { "type": "passive", "id": 1, "rare": false } slot=-1 of ["level", "passive", "passive"]
CALM 09:00 removed=166 left=9
TRADER 1 at 09:00 credits_left=108 bought=["passive(60)", "level(75)", "level(75)", "passive(60)", "module(60)"]
SIM 09:00 level=25 kills=3547 xp=4448/5453 credits=518/669 credits_left=108 zombies=175 kinds=85/40/29/21 elites=0 elites_spawned=12 crates=2 nades=34 dmg_taken=3015 peak=198 fps=145 | АК-С L4 Зажи1 [Сдво3,Спли1] | Мясник L5 Стан1 [Проб3,Цепь1,Сдво3] | ППШ L1 Стан1 [Рико2] | Гром L2 Стан1 [Проб1]
PICK lvl=26 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["module", "level", "level"]
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=0 rare=true
BOSS spawn t=600.00 pos=(1272.0, 424.0) hp=24000
SIM 10:00 level=26 kills=3732 xp=4822/5690 credits=577/702 credits_left=167 zombies=35 kinds=24/11/0/0 elites=0 elites_spawned=14 crates=2 nades=34 dmg_taken=3044 peak=40 fps=144 | АК-С L4 Зажи1 [Сдво3,Спли2] | Мясник L5 Стан1 [Проб3,Цепь1,Сдво3] | ППШ L2 Стан1 [Рико2] | Гром L2 Стан1 [Проб1]
SIM summary kills=3732 peak=464 level=26 damage=3043.58 boss_alive=true

R1DGUARD foreign_during=[]
EXIT_CODE=0
```
