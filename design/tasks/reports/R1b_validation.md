# R1b — дословные журналы

Команды, stdout/stderr и код возврата. ANSI-разметка импорта сохранена.

## r1b_audio.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_audio_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-shots --gore-hit-only --r1b --r1b-audio
GODOT_EXCLUSIVE other_godot_processes=0 at 22:03:02
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=727.69 seed=81073
R1BAUDIO master=true seconds=30.421 stress_targets=500 hit_voices=119 shot_requested=600 shot_accepted=600 max_hits_s=6
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_audio_final.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_audio_final_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-shots --gore-hit-only --r1b --r1b-audio
GODOT_EXCLUSIVE other_godot_processes=0 at 22:07:42
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=502.18 seed=81073
R1BAUDIO master=true seconds=30.453 stress_targets=500 hit_voices=119 shot_requested=600 shot_accepted=600 max_hits_s=12
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_bench_1_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_bench_1_after_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1b_bench_after.png
GODOT_EXCLUSIVE other_godot_processes=0 at 22:04:43
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=507.76 seed=81073
BENCH frames=291 avg_fps=29.0 avg_frame_ms=34.47 worst_frame_ms=140.11 horde_ms=5.05 enemies=498 kills=1108
BENCH process_ms=9.00 physics_ms=17.38 draw_calls=790 objects=3323 gore=573 particles=1099 wet=69
BENCH physics_avg_ms=27.79 hud_ms=0.940
BENCH screenshot: res://design/tasks/reports/r1b_bench_after.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_bench_1_before.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_bench_1_before_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1b_bench_before.png
GODOT_EXCLUSIVE other_godot_processes=0 at 21:51:59
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=763.33 seed=81073
BENCH frames=388 avg_fps=38.8 avg_frame_ms=25.80 worst_frame_ms=138.91 horde_ms=4.75 enemies=498 kills=1135
BENCH process_ms=9.95 physics_ms=18.21 draw_calls=691 objects=3272 gore=900 particles=688 wet=126
BENCH physics_avg_ms=25.32 hud_ms=0.769
BENCH screenshot: res://design/tasks/reports/r1b_bench_before.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_bench_2_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_bench_2_after_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --loadout --bench=500 --fresh-save
GODOT_EXCLUSIVE other_godot_processes=0 at 22:05:11
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=577.62 seed=81073
BENCH frames=462 avg_fps=46.1 avg_frame_ms=21.69 worst_frame_ms=141.05 horde_ms=4.94 enemies=499 kills=1068
BENCH process_ms=13.18 physics_ms=25.79 draw_calls=561 objects=3162 gore=900 particles=740 wet=40
BENCH physics_avg_ms=21.24 hud_ms=0.659
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_bench_2_before.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_bench_2_before_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --loadout --bench=500 --fresh-save
GODOT_EXCLUSIVE other_godot_processes=0 at 21:52:32
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=861.14 seed=81073
BENCH frames=357 avg_fps=35.6 avg_frame_ms=28.09 worst_frame_ms=139.75 horde_ms=4.80 enemies=499 kills=945
BENCH process_ms=11.59 physics_ms=18.83 draw_calls=623 objects=3351 gore=271 particles=529 wet=97
BENCH physics_avg_ms=22.00 hud_ms=0.846
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_bench_3_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_bench_3_after_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --loadout --bench=500 --fresh-save
GODOT_EXCLUSIVE other_godot_processes=0 at 22:05:59
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=489.68 seed=81073
BENCH frames=369 avg_fps=36.9 avg_frame_ms=27.13 worst_frame_ms=135.40 horde_ms=4.71 enemies=499 kills=939
BENCH process_ms=9.89 physics_ms=22.31 draw_calls=444 objects=3327 gore=424 particles=628 wet=18
BENCH physics_avg_ms=26.33 hud_ms=0.811
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_bench_3_before.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_bench_3_before_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --loadout --bench=500 --fresh-save
GODOT_EXCLUSIVE other_godot_processes=0 at 21:53:29
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=489.63 seed=81073
BENCH frames=341 avg_fps=34.0 avg_frame_ms=29.38 worst_frame_ms=149.99 horde_ms=4.78 enemies=499 kills=960
BENCH process_ms=8.18 physics_ms=18.79 draw_calls=598 objects=3394 gore=288 particles=610 wet=75
BENCH physics_avg_ms=23.57 hud_ms=0.870
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_bench_batch_1_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_bench_batch_1_after_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --loadout --bench=500 --fresh-save --shot=res://design/tasks/reports/r1b_bench_after.png
GODOT_EXCLUSIVE other_godot_processes=0 at 22:20:04
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=438.08 seed=81073
BENCH frames=394 avg_fps=39.3 avg_frame_ms=25.44 worst_frame_ms=145.66 horde_ms=4.75 enemies=498 kills=1271
BENCH process_ms=14.26 physics_ms=24.35 draw_calls=459 objects=3336 gore=330 particles=129 wet=66
BENCH physics_avg_ms=25.41 hud_ms=0.740
BENCH screenshot: res://design/tasks/reports/r1b_bench_after.png
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_bench_batch_2_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_bench_batch_2_after_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --loadout --bench=500 --fresh-save
GODOT_EXCLUSIVE other_godot_processes=0 at 22:21:00
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=459.08 seed=81073
BENCH frames=441 avg_fps=43.5 avg_frame_ms=22.98 worst_frame_ms=141.57 horde_ms=4.68 enemies=498 kills=1067
BENCH process_ms=10.63 physics_ms=24.03 draw_calls=544 objects=3305 gore=728 particles=510 wet=84
BENCH physics_avg_ms=26.03 hud_ms=0.657
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_bench_batch_3_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_bench_batch_3_after_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --loadout --bench=500 --fresh-save
GODOT_EXCLUSIVE other_godot_processes=0 at 22:21:23
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=478.55 seed=81073
BENCH frames=374 avg_fps=37.3 avg_frame_ms=26.79 worst_frame_ms=141.52 horde_ms=4.98 enemies=498 kills=951
BENCH process_ms=9.67 physics_ms=23.70 draw_calls=455 objects=3285 gore=518 particles=429 wet=81
BENCH physics_avg_ms=25.95 hud_ms=0.797
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_bench_final_1_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_bench_final_1_after_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --loadout --bench=500 --fresh-save
GODOT_EXCLUSIVE other_godot_processes=0 at 22:15:03
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=509.85 seed=81073
BENCH frames=294 avg_fps=29.4 avg_frame_ms=34.06 worst_frame_ms=138.69 horde_ms=4.70 enemies=498 kills=1092
BENCH process_ms=9.92 physics_ms=23.90 draw_calls=444 objects=3378 gore=357 particles=323 wet=76
BENCH physics_avg_ms=27.74 hud_ms=0.974
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_bench_final_2_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_bench_final_2_after_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --loadout --bench=500 --fresh-save
GODOT_EXCLUSIVE other_godot_processes=0 at 22:15:48
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=539.41 seed=81073
BENCH frames=441 avg_fps=43.9 avg_frame_ms=22.80 worst_frame_ms=125.29 horde_ms=4.79 enemies=499 kills=1066
BENCH process_ms=8.86 physics_ms=21.52 draw_calls=723 objects=3422 gore=837 particles=953 wet=87
BENCH physics_avg_ms=25.70 hud_ms=0.710
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_bench_final_2_repeat_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_bench_final_2_repeat_after_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --loadout --bench=500 --fresh-save
GODOT_EXCLUSIVE other_godot_processes=0 at 22:18:47
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=464.93 seed=81073
BENCH frames=319 avg_fps=31.8 avg_frame_ms=31.43 worst_frame_ms=135.90 horde_ms=4.80 enemies=498 kills=1303
BENCH process_ms=9.01 physics_ms=21.28 draw_calls=558 objects=3289 gore=900 particles=892 wet=92
BENCH physics_avg_ms=34.50 hud_ms=0.831
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_bench_final_3_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_bench_final_3_after_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --loadout --bench=500 --fresh-save
stat: cannot stat 'C:/Users/Dev/Desktop/zera-assets/locks/godot.lock': No such file or directory
C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh: line 9: 1792351107 -  : syntax error: operand expected (error token is "-  ")
GODOT_EXCLUSIVE other_godot_processes=0 at 22:18:28
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=506.12 seed=81073
BENCH frames=326 avg_fps=32.5 avg_frame_ms=30.79 worst_frame_ms=150.00 horde_ms=5.25 enemies=499 kills=972
BENCH process_ms=12.23 physics_ms=21.68 draw_calls=455 objects=3178 gore=601 particles=633 wet=109
BENCH physics_avg_ms=27.40 hud_ms=0.882
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_campaign.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_campaign_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --campaign-test --r1b
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
Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в res://design/tasks/reports/R1b_test/c1_migration.json.campaign-bad-7462958
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
WARNING: Meta: запись res://design/tasks/reports/R1b_test/c1_missing_directory/save.json не удалась
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] save (res://scripts/meta.gd:446)
       [1] start_operation (res://scripts/campaign/campaign.gd:57)
       [2] _integration (res://scripts/campaign/campaign_test.gd:256)
       [3] run (res://scripts/campaign/campaign_test.gd:22)
       [4] _ready (res://scripts/game.gd:668)
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

EXIT_CODE=0

```

## r1b_fight_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_fight_after_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-shots --r1b --shot=res://design/tasks/reports/r1b_fight_after.png
GODOT_EXCLUSIVE other_godot_processes=0 at 22:08:25
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=489.86 seed=81073
GORESTAND seconds=60 debris=50 peak=112 remains=90 remains_peak=200 stamps=29134 queue=0 pools=17 memory=135413175 video=301928448
GORESTAND seconds=300 debris=51 peak=132 remains=177 remains_peak=200 stamps=146648 queue=0 pools=18 memory=135416727 video=302125056
GORESTAND screenshot: res://design/tasks/reports/r1b_fight_after_5min.png
R1BSTAND fight simultaneous_hits=40 camera=3 screenshot=r1b_fight_5min.png
GORESTAND seconds=480 debris=71 peak=132 remains=124 remains_peak=200 stamps=234979 queue=0 pools=17 memory=135548291 video=302583808
GORESTAND seconds=600 debris=27 peak=132 remains=113 remains_peak=200 stamps=293431 queue=0 pools=14 memory=135545363 video=302649344
GORESTAND screenshot: res://design/tasks/reports/r1b_fight_after_10min.png
GORESTAND complete seed=81073 deaths=7200 zoom=3 map=quarantine_checkpoint
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_fight_before.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_fight_before_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-shots --r1b --shot=res://design/tasks/reports/r1b_fight_before.png
GODOT_EXCLUSIVE other_godot_processes=0 at 21:53:57
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=662.53 seed=81073
GORESTAND seconds=60 debris=45 peak=106 remains=79 remains_peak=200 stamps=28773 queue=0 pools=17 memory=135462302 video=301928448
GORESTAND seconds=300 debris=44 peak=125 remains=174 remains_peak=200 stamps=145317 queue=0 pools=18 memory=135469298 video=302125056
GORESTAND screenshot: res://design/tasks/reports/r1b_fight_before_5min.png
GORESTAND seconds=480 debris=68 peak=125 remains=131 remains_peak=200 stamps=232724 queue=0 pools=17 memory=135508278 video=301993984
GORESTAND seconds=600 debris=23 peak=125 remains=115 remains_peak=200 stamps=290477 queue=0 pools=14 memory=135505322 video=302059520
GORESTAND screenshot: res://design/tasks/reports/r1b_fight_before_10min.png
GORESTAND complete seed=81073 deaths=7200 zoom=3 map=quarantine_checkpoint
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_fight_deliver.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_fight_deliver_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-shots --r1b --shot=res://design/tasks/reports/r1b_fight_after.png
GODOT_EXCLUSIVE other_godot_processes=0 at 22:16:29
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=473.62 seed=81073
GORESTAND seconds=60 debris=50 peak=112 remains=90 remains_peak=200 stamps=29150 queue=0 pools=17 memory=135191691 video=301928448
GORESTAND seconds=300 debris=51 peak=132 remains=177 remains_peak=200 stamps=146652 queue=0 pools=18 memory=135194423 video=302125056
GORESTAND screenshot: res://design/tasks/reports/r1b_fight_after_5min.png
R1BSTAND fight simultaneous_hits=40 camera=3 screenshot=r1b_fight_5min.png
GORESTAND seconds=480 debris=67 peak=132 remains=130 remains_peak=200 stamps=235000 queue=0 pools=17 memory=135502501 video=302583808
GORESTAND seconds=600 debris=27 peak=132 remains=115 remains_peak=200 stamps=293417 queue=0 pools=14 memory=135500145 video=302059520
GORESTAND screenshot: res://design/tasks/reports/r1b_fight_after_10min.png
GORESTAND complete seed=81073 deaths=7200 zoom=3 map=quarantine_checkpoint
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_fight_verified.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_fight_verified_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-shots --r1b --shot=res://design/tasks/reports/r1b_fight_after.png
GODOT_EXCLUSIVE other_godot_processes=0 at 22:11:37
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=552.32 seed=81073
GORESTAND seconds=60 debris=50 peak=112 remains=90 remains_peak=200 stamps=29159 queue=0 pools=17 memory=135762751 video=301928448
GORESTAND seconds=300 debris=51 peak=132 remains=177 remains_peak=200 stamps=146690 queue=0 pools=18 memory=135765483 video=302125056
GORESTAND screenshot: res://design/tasks/reports/r1b_fight_after_5min.png
R1BSTAND fight simultaneous_hits=40 camera=3 screenshot=r1b_fight_5min.png
GORESTAND seconds=480 debris=71 peak=132 remains=129 remains_peak=200 stamps=235069 queue=0 pools=17 memory=135896507 video=301993984
GORESTAND seconds=600 debris=27 peak=132 remains=112 remains_peak=200 stamps=293422 queue=0 pools=14 memory=135892871 video=302649344
GORESTAND screenshot: res://design/tasks/reports/r1b_fight_after_10min.png
GORESTAND complete seed=81073 deaths=7200 zoom=3 map=quarantine_checkpoint
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_fx.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_fx_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fx-test --fresh-save --r1b --shot=res://design/tasks/reports/r1b_fx.png
GODOT_EXCLUSIVE other_godot_processes=0 at 22:10:26
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=488.20 seed=81073
FXTEST sheet=seq ages=0.05,0.15,0.4,1.5
FXTEST sheet=crowd ages=0.05,0.15,0.4,1.5
FXTEST sheet=fat ages=0.05,0.15,0.4,1.5
FXTEST sheet=boss ages=0.05,0.15,0.4,1.5
FXBENCH warm_chain20 baseline=false enemies=500 frames=584 avg_ms=6.643 worst_ms=18.498 physics_worst_ms=11.724 draw_calls_peak=122 spawn_worst_ms=0.368 update_worst_ms=0.652 draw_submit_worst_ms=3.803 peak=398
FXBENCH warm_boss baseline=false enemies=500 frames=396 avg_ms=7.667 worst_ms=13.589 physics_worst_ms=10.109 draw_calls_peak=146 spawn_worst_ms=1.423 update_worst_ms=0.212 draw_submit_worst_ms=1.158 peak=180
FXBENCH chain20 baseline=false enemies=500 frames=484 avg_ms=8.014 worst_ms=16.930 physics_worst_ms=14.074 draw_calls_peak=121 spawn_worst_ms=0.214 update_worst_ms=0.296 draw_submit_worst_ms=2.214 peak=399
FXBENCH boss baseline=false enemies=500 frames=367 avg_ms=8.242 worst_ms=21.493 physics_worst_ms=17.696 draw_calls_peak=154 spawn_worst_ms=1.252 update_worst_ms=0.472 draw_submit_worst_ms=1.485 peak=180
FXTEST ok=true pool_cap=592 overflow_replaced=2708 idle_process=false
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_gore.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_gore_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-checks --r1b
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=376.51 seed=81073
R1CHECK pellets_one_reaction_full_damage=true
R1CHECK exit_spray=true
R1CHECK crawler_inertia=true
R1CHECK bounded_flood_2400_deaths=true
R1CHECK no_permanent_body_or_ash_stamps=true
R1CHECK all_remains_expire=true
R1CHECK ok=true remains_peak=200 stamps_queue=365 particles=0

EXIT_CODE=0

```

## r1b_gore_deliver.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_gore_deliver_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-checks --r1b
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=392.89 seed=81073
R1CHECK pellets_one_reaction_full_damage=true
R1CHECK exit_spray=true
R1CHECK r1b_entry_exit_mist_full=true
R1CHECK r1b_heavy_gib_cap=true
R1B CHECK low=false particles=29 chunks=2
R1CHECK r1b_transients_expire=true
R1CHECK r1b_entry_exit_mist_low=true
R1CHECK r1b_heavy_gib_cap=true
R1B CHECK low=true particles=14 chunks=0
R1CHECK r1b_transients_expire=true
R1CHECK r1b_near_reserve_far_simplified=true
R1CHECK crawler_inertia=true
R1CHECK bounded_flood_2400_deaths=true
R1CHECK no_permanent_body_or_ash_stamps=true
R1CHECK all_remains_expire=true
R1CHECK ok=true remains_peak=200 stamps_queue=426 particles=0

EXIT_CODE=0

```

## r1b_gore_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_gore_final_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-checks --r1b
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=397.07 seed=81073
R1CHECK pellets_one_reaction_full_damage=true
R1CHECK exit_spray=true
R1CHECK r1b_entry_exit_mist_full=true
R1CHECK r1b_heavy_gib_cap=true
R1B CHECK low=false particles=29 chunks=2
R1CHECK r1b_transients_expire=true
R1CHECK r1b_entry_exit_mist_low=true
R1CHECK r1b_heavy_gib_cap=true
R1B CHECK low=true particles=14 chunks=0
R1CHECK r1b_transients_expire=true
R1CHECK crawler_inertia=true
R1CHECK bounded_flood_2400_deaths=true
R1CHECK no_permanent_body_or_ash_stamps=true
R1CHECK all_remains_expire=true
R1CHECK ok=true remains_peak=200 stamps_queue=393 particles=0

EXIT_CODE=0

```

## r1b_hits_after.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_hits_after_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-shots --gore-hit-only --r1b --shot=res://design/tasks/reports/r1b_hits_after.png
GODOT_EXCLUSIVE other_godot_processes=0 at 21:56:37
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=640.00 seed=81073
R1BSTAND hits order=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=60ms zoom=3 native_pixels=true stage=after
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_hits_before.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_hits_before_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-shots --gore-hit-only --r1b --r1b-before --shot=res://design/tasks/reports/r1b_hits_before.png
GODOT_EXCLUSIVE other_godot_processes=0 at 21:53:06
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=577.51 seed=81073
R1BSTAND hits order=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=60ms zoom=3 native_pixels=true stage=before
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_hits_clean.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_hits_clean_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-shots --gore-hit-only --r1b --shot=res://design/tasks/reports/r1b_hits_after.png
GODOT_EXCLUSIVE other_godot_processes=0 at 22:23:34
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=533.98 seed=81073
R1BSTAND hits order=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=60ms zoom=3 native_pixels=true stage=after
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_hits_deliver.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_hits_deliver_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-shots --gore-hit-only --r1b --shot=res://design/tasks/reports/r1b_hits_after.png
GODOT_EXCLUSIVE other_godot_processes=0 at 22:15:27
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=493.37 seed=81073
R1BSTAND hits order=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=60ms zoom=3 native_pixels=true stage=after
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_hits_final.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_hits_final_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-shots --gore-hit-only --r1b --shot=res://design/tasks/reports/r1b_hits_after.png
GODOT_EXCLUSIVE other_godot_processes=0 at 22:04:18
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=520.51 seed=81073
R1BSTAND hits order=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=60ms zoom=3 native_pixels=true stage=after
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_hits_verified.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_hits_verified_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-shots --gore-hit-only --r1b --shot=res://design/tasks/reports/r1b_hits_after.png
GODOT_EXCLUSIVE other_godot_processes=0 at 22:11:13
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=665.54 seed=81073
R1BSTAND hits order=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=60ms zoom=3 native_pixels=true stage=after
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

## r1b_import_after.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_import_after_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b --import
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
[   0% ] [90m[1mupdate_scripts_classes[22m | Started Регистрация глобальных классов… (5 steps)[39m[0m
[   0% ] [90m[1mupdate_scripts_classes[22m | Effects[39m[0m
[  16% ] [90m[1mupdate_scripts_classes[22m | [39m[0m
[  33% ] [90m[1mupdate_scripts_classes[22m | Gore[39m[0m
[  50% ] [90m[1mupdate_scripts_classes[22m | Horde[39m[0m
[  66% ] [90m[1mupdate_scripts_classes[22m | Sfx[39m[0m
[92m[ DONE ][39m [1mupdate_scripts_classes[22m
[0m
[   0% ] [90m[1m_update_scan_actions[22m | Started Сканирование действий… (10 steps)[39m[0m
[   0% ] [90m[1m_update_scan_actions[22m | hit_0.wav[39m[0m
[   9% ] [90m[1m_update_scan_actions[22m | hit_1.wav[39m[0m
[  18% ] [90m[1m_update_scan_actions[22m | hit_2.wav[39m[0m
[  27% ] [90m[1m_update_scan_actions[22m | hit_3.wav[39m[0m
[  36% ] [90m[1m_update_scan_actions[22m | hit_4.wav[39m[0m
[  45% ] [90m[1m_update_scan_actions[22m | hit_5.wav[39m[0m
[  54% ] [90m[1m_update_scan_actions[22m | hit_6.wav[39m[0m
[  63% ] [90m[1m_update_scan_actions[22m | hit_7.wav[39m[0m
[  72% ] [90m[1m_update_scan_actions[22m | hit_8.wav[39m[0m
[  81% ] [90m[1m_update_scan_actions[22m | hit_9.wav[39m[0m
[92m[ DONE ][39m [1m_update_scan_actions[22m
[0m
[   0% ] [90m[1mreimport[22m | Started Импорт или повторный импорт ассетов (10 steps)[39m[0m
[   0% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[   9% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  18% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  27% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  36% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  45% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  54% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  63% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  72% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[  81% ] [90m[1mreimport[22m | Подготовка файлов к повторному импорту…[39m[0m
[   0% ] [90m[1mreimport[22m | Выполнение предимпортных операций…[39m[0m
[   0% ] [90m[1mreimport[22m | hit_0.wav[39m[0m
[   9% ] [90m[1mreimport[22m | hit_1.wav[39m[0m
[  18% ] [90m[1mreimport[22m | hit_2.wav[39m[0m
[  27% ] [90m[1mreimport[22m | hit_3.wav[39m[0m
[  36% ] [90m[1mreimport[22m | hit_4.wav[39m[0m
[  45% ] [90m[1mreimport[22m | hit_5.wav[39m[0m
[  54% ] [90m[1mreimport[22m | hit_6.wav[39m[0m
[  63% ] [90m[1mreimport[22m | hit_7.wav[39m[0m
[  72% ] [90m[1mreimport[22m | hit_8.wav[39m[0m
[  81% ] [90m[1mreimport[22m | hit_9.wav[39m[0m
[  90% ] [90m[1mreimport[22m | Завершение импорта активов…[39m[0m
[92m[ DONE ][39m [1mreimport[22m
[0m
[   0% ] [90m[1mreimport[22m | Started Импорт или повторный импорт ассетов (10 steps)[39m[0m
[   0% ] [90m[1mreimport[22m | Выполнение операций после реимпорта…[39m[0m
[92m[ DONE ][39m [1mreimport[22m
[0m
[   0% ] [90m[1mloading_editor_layout[22m | Started Загрузка редактора (5 steps)[39m[0m
[   0% ] [90m[1mloading_editor_layout[22m | Загрузка макета редактора…[39m[0m
[  16% ] [90m[1mloading_editor_layout[22m | Загрузка док-панели…[39m[0m
[92m[ DONE ][39m [1mloading_editor_layout[22m
[0m

EXIT_CODE=0

```

## r1b_import_deliver.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_import_deliver_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b --import
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
[   0% ] [90m[1m_update_scan_actions[22m | Started Сканирование действий… (10 steps)[39m[0m
[   0% ] [90m[1m_update_scan_actions[22m | hit_0.wav[39m[0m
[   9% ] [90m[1m_update_scan_actions[22m | hit_1.wav[39m[0m
[  18% ] [90m[1m_update_scan_actions[22m | hit_2.wav[39m[0m
[  27% ] [90m[1m_update_scan_actions[22m | hit_3.wav[39m[0m
[  36% ] [90m[1m_update_scan_actions[22m | hit_4.wav[39m[0m
[  45% ] [90m[1m_update_scan_actions[22m | hit_5.wav[39m[0m
[  54% ] [90m[1m_update_scan_actions[22m | hit_6.wav[39m[0m
[  63% ] [90m[1m_update_scan_actions[22m | hit_7.wav[39m[0m
[  72% ] [90m[1m_update_scan_actions[22m | hit_8.wav[39m[0m
[  81% ] [90m[1m_update_scan_actions[22m | hit_9.wav[39m[0m
[92m[ DONE ][39m [1m_update_scan_actions[22m
[0m
[   0% ] [90m[1mloading_editor_layout[22m | Started Загрузка редактора (5 steps)[39m[0m
[   0% ] [90m[1mloading_editor_layout[22m | Загрузка макета редактора…[39m[0m
[  16% ] [90m[1mloading_editor_layout[22m | Загрузка док-панели…[39m[0m
[92m[ DONE ][39m [1mloading_editor_layout[22m
[0m

EXIT_CODE=0

```

## r1b_import_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_import_final_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b --import
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
[  20% ] [90m[1mupdate_scripts_classes[22m | [39m[0m
[  40% ] [90m[1mupdate_scripts_classes[22m | Gore[39m[0m
[  60% ] [90m[1mupdate_scripts_classes[22m | Sfx[39m[0m
[92m[ DONE ][39m [1mupdate_scripts_classes[22m
[0m
[   0% ] [90m[1mloading_editor_layout[22m | Started Загрузка редактора (5 steps)[39m[0m
[   0% ] [90m[1mloading_editor_layout[22m | Загрузка макета редактора…[39m[0m
[  16% ] [90m[1mloading_editor_layout[22m | Загрузка док-панели…[39m[0m
[92m[ DONE ][39m [1mloading_editor_layout[22m
[0m

EXIT_CODE=0

```

## r1b_meta.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_meta_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --meta-test --r1b
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=362.52 seed=81073
S7SETTINGS migration_v1_v3=true progress_preserved=true roundtrip=true sanitize=true temporary_save=true
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792349998
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792349998
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792349998
Meta: сохранение повреждено или другой версии, копия в user://test_save.json.bad-1792349998
Meta: блок campaign повреждён; профиль сохранён; новая кампания; копия в user://test_save.json.campaign-bad-6905354
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

EXIT_CODE=0

```

## r1b_obstacles.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_obstacles_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --obstacles-test --fresh-save --r1b
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=510.84 seed=81073
OBSTEST layout cars=27 barrels=20 objects=409 seed=81073
OBSTEST simulation seconds=10 alive=500 penetrations=0
OBSTEST simulation seconds=20 alive=500 penetrations=0
OBSTEST simulation seconds=30 alive=500 penetrations=0
OBSTEST simulation seconds=40 alive=500 penetrations=0
OBSTEST simulation seconds=50 alive=500 penetrations=0
OBSTEST simulation seconds=60 alive=500 penetrations=0
OBSTEST wall arrived=500/500 nav_worst_us=559
OBSTEST ok=true penetrations=0 arrived=500 detonations=3 blood_events=2

EXIT_CODE=0

```

## r1b_q1.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_q1_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --q1-test --fresh-save --r1b
GODOT_EXCLUSIVE other_godot_processes=0 at 22:01:08
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=552.38 seed=81073
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

EXIT_CODE=0

```

## r1b_sim.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_sim_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --sim=600 --fresh-save --r1b
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=363.99 seed=81073
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
PICK lvl=2 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["weapon", "weapon", "level"]
PICK lvl=3 { "type": "weapon", "id": 7, "rare": false } slot=-1 of ["level", "passive", "weapon"]
SIM 01:00 level=3 kills=44 xp=42/44 credits=3/3 credits_left=3 zombies=45 kinds=45/0/0/0 elites=0 elites_spawned=0 crates=0 nades=1 dmg_taken=25 peak=46 fps=145 | АК-С L2 Стан1 [] | Мосинка L1 Стан1 []
PICK lvl=4 { "type": "weapon", "id": 5, "rare": false } slot=-1 of ["weapon", "weapon", "module"]
PICK lvl=5 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["level", "weapon", "weapon"]
PICK lvl=6 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["level", "level", "passive"]
SIM 02:00 level=6 kills=199 xp=191/199 credits=11/11 credits_left=11 zombies=70 kinds=70/0/0/0 elites=0 elites_spawned=0 crates=0 nades=6 dmg_taken=267 peak=82 fps=145 | АК-С L2 Стан1 [] | Мосинка L1 Стан1 [] | Бульдог L2 Стан1 []
PICK lvl=7 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["level", "module", "ammo"]
PICK lvl=8 { "type": "module", "id": 1, "rare": false } slot=0 of ["module", "weapon", "weapon"]
SIM 03:00 level=8 kills=473 xp=311/473 credits=23/35 credits_left=23 zombies=34 kinds=34/0/0/0 elites=0 elites_spawned=0 crates=0 nades=9 dmg_taken=730 peak=79 fps=145 | АК-С L2 Крио1 [Проб1] | Мосинка L1 Стан1 [] | Бульдог L2 Стан1 []
PICK lvl=9 { "type": "module", "id": 0, "rare": false } slot=1 of ["level", "module", "passive"]
PICK lvl=10 { "type": "module", "id": 5, "rare": false } slot=2 of ["module", "passive", "module"]
PICK lvl=11 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["level", "module", "level"]
PICK lvl=12 { "type": "module", "id": 5, "rare": true } slot=2 of ["level", "module", "level"]
SIM 04:00 level=12 kills=740 xp=754/767 credits=59/62 credits_left=59 zombies=29 kinds=23/0/6/0 elites=0 elites_spawned=0 crates=0 nades=11 dmg_taken=1783 peak=62 fps=144 | АК-С L2 Крио1 [Проб1] | Мосинка L1 Стан1 [Рико1] | Бульдог L3 Стан1 [Цепь2]
PICK lvl=13 { "type": "module", "id": 3, "rare": false } slot=2 of ["level", "module", "level"]
PICK lvl=14 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["weapon", "level", "weapon"]
TRADER 0 at 05:00 credits_left=37 bought=["weapon(60)"]
SIM 05:00 level=14 kills=1095 xp=1086/1227 credits=97/113 credits_left=37 zombies=39 kinds=28/0/11/0 elites=0 elites_spawned=0 crates=0 nades=17 dmg_taken=2706 peak=186 fps=144 | АК-С L2 Крио1 [Проб1] | Мосинка L1 Стан1 [Рико1] | Бульдог L4 Стан1 [Цепь2,Дето1] | ППШ L1 Стан1 []
PICK lvl=15 { "type": "passive", "id": 0, "rare": false } slot=-1 of ["level", "passive", "module"]
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=1 rare=true
PICK lvl=16 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["module", "level", "module"]
SIM 06:00 level=16 kills=1485 xp=1605/1845 credits=172/195 credits_left=112 zombies=64 kinds=43/0/13/8 elites=0 elites_spawned=2 crates=0 nades=20 dmg_taken=2826 peak=114 fps=144 | АК-С L2 Крио1 [Проб1] | Мосинка L1 Стан1 [Рико2] | Бульдог L5 Стан1 [Цепь2,Дето1] | ППШ L1 Стан1 []
PICK lvl=17 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["module", "passive", "level"]
PICK lvl=18 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "level", "ammo"]
PICK lvl=19 { "type": "module", "id": 4, "rare": false } slot=0 of ["module", "passive", "module"]
SIM 07:00 level=19 kills=1973 xp=2383/2553 credits=273/290 credits_left=213 zombies=72 kinds=49/11/7/5 elites=1 elites_spawned=4 crates=0 nades=24 dmg_taken=2969 peak=127 fps=143 | АК-С L3 Крио1 [Проб1,Сдво1] | Мосинка L1 Стан1 [Рико2] | Бульдог L5 Стан1 [Цепь2,Дето1] | ППШ L1 Стан1 []
ALARM_EVENT warn time=07:00
PICK lvl=20 { "type": "module", "id": 3, "rare": false } slot=2 of ["passive", "level", "module"]
ALARM_EVENT start time=07:03
PICK lvl=21 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "module", "level"]
PICK lvl=22 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["level", "ammo", "ammo"]
PICK lvl=23 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["level", "level", "ammo"]
PICK lvl=24 { "type": "module", "id": 4, "rare": false } slot=0 of ["passive", "level", "module"]
ALARM_EVENT finish container=(2479.342, 766.6469) time=07:33
CONTAINER dropped pos=(2479.342, 766.6469) time=07:33
ALARM rewards mult=2 xp=2278 credits=282
LOOT СБРОС СНАБЖЕНИЯ: module slot=2 rare=true
CONTAINER picked time=07:33 crates=1
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
PICK lvl=25 { "type": "module", "id": 2, "rare": false } slot=2 of ["module", "ammo", "level"]
PICK lvl=26 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "level", "module"]
SIM 08:00 level=26 kills=3029 xp=4647/5237 credits=539/610 credits_left=479 zombies=0 kinds=0/0/0/0 elites=0 elites_spawned=10 crates=1 nades=28 dmg_taken=3373 peak=180 fps=145 | АК-С L4 Крио2 [Проб1,Сдво2] | Мосинка L1 Стан1 [Рико2] | Бульдог L5 Стан1 [Цепь3,Дето2,Спли1] | ППШ L2 Стан1 []
PICK lvl=27 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["module", "ammo", "level"]
PICK lvl=28 { "type": "module", "id": 0, "rare": false } slot=1 of ["passive", "module", "level"]
CALM 09:00 removed=30 left=0
TRADER 1 at 09:00 credits_left=206 bought=["module(60)", "passive(60)", "ammo(150)", "level(75)", "level(75)"]
SIM 09:00 level=28 kills=3666 xp=5738/6122 credits=686/744 credits_left=206 zombies=30 kinds=6/19/5/0 elites=0 elites_spawned=12 crates=1 nades=31 dmg_taken=3464 peak=67 fps=145 | АК-С L4 Стан1 [Проб1,Сдво3] | Мосинка L3 Стан1 [Рико3] | Бульдог L5 Стан1 [Цепь3,Дето2,Спли1] | ППШ L3 Стан1 []
PICK lvl=29 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "level", "passive"]
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
BOSS spawn t=600.00 pos=(2161.028, 473.6202) hp=24000
SIM 10:00 level=29 kills=3867 xp=6149/6371 credits=735/778 credits_left=255 zombies=11 kinds=10/1/0/0 elites=0 elites_spawned=14 crates=1 nades=33 dmg_taken=3464 peak=23 fps=145 | АК-С L5 Эксп1 [Проб1,Сдво3] | Мосинка L3 Стан1 [Рико3] | Бульдог L5 Стан1 [Цепь3,Дето2,Спли1] | ППШ L3 Стан1 []
SIM summary kills=3867 peak=186 level=29 damage=3463.83 boss_alive=true

EXIT_CODE=0

```

## r1b_sim_final.log

```text
C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_sim_final_engine.log --headless --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --sim=600 --fresh-save --r1b
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=431.31 seed=81073
SIM meta: class_level=1 tree=0 workshop_models=0 owned=8 bonuses={ "damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0, "mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false } models=ak_s
PICK lvl=2 { "type": "weapon", "id": 4, "rare": false } slot=-1 of ["weapon", "module", "weapon"]
PICK lvl=3 { "type": "weapon", "id": 1, "rare": false } slot=-1 of ["weapon", "module", "level"]
PICK lvl=4 { "type": "weapon", "id": 7, "rare": false } slot=-1 of ["weapon", "ammo", "level"]
SIM 01:00 level=4 kills=67 xp=56/67 credits=9/9 credits_left=9 zombies=22 kinds=22/0/0/0 elites=0 elites_spawned=0 crates=0 nades=1 dmg_taken=0 peak=31 fps=144 | АК-С L1 Стан1 [] | Кольт L1 Стан1 [] | Мясник L1 Стан1 [] | Мосинка L1 Стан1 []
PICK lvl=5 { "type": "module", "id": 1, "rare": true } slot=0 of ["level", "module", "passive"]
PICK lvl=6 { "type": "level", "slot": 2, "rare": false } slot=-1 of ["passive", "level", "level"]
PICK lvl=7 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "level", "module"]
SIM 02:00 level=7 kills=207 xp=206/207 credits=18/18 credits_left=18 zombies=63 kinds=63/0/0/0 elites=0 elites_spawned=0 crates=0 nades=4 dmg_taken=120 peak=63 fps=145 | АК-С L1 Стан1 [Проб1] | Кольт L1 Стан1 [] | Мясник L2 Стан1 [] | Мосинка L2 Стан1 []
PICK lvl=8 { "type": "level", "slot": 3, "rare": false } slot=-1 of ["level", "ammo", "level"]
PICK lvl=9 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["passive", "ammo", "module"]
SIM 03:00 level=9 kills=478 xp=406/478 credits=25/33 credits_left=25 zombies=29 kinds=17/12/0/0 elites=0 elites_spawned=0 crates=0 nades=9 dmg_taken=120 peak=87 fps=145 | АК-С L1 Стан1 [Проб1] | Кольт L1 Стан1 [] | Мясник L2 Стан1 [] | Мосинка L3 Стан1 []
PICK lvl=10 { "type": "passive", "id": 2, "rare": false } slot=-1 of ["level", "module", "passive"]
PICK lvl=11 { "type": "module", "id": 2, "rare": false } slot=1 of ["module", "passive", "ammo"]
PICK lvl=12 { "type": "module", "id": 2, "rare": false } slot=1 of ["passive", "module", "level"]
SIM 04:00 level=12 kills=741 xp=771/780 credits=53/54 credits_left=53 zombies=34 kinds=29/0/5/0 elites=0 elites_spawned=0 crates=0 nades=13 dmg_taken=176 peak=62 fps=145 | АК-С L1 Стан1 [Проб1] | Кольт L1 Стан1 [Спли2] | Мясник L2 Стан1 [] | Мосинка L3 Стан1 []
PICK lvl=13 { "type": "ammo", "id": 2, "rare": true } slot=0 of ["ammo", "ammo", "ammo"]
TRADER 0 at 05:00 credits_left=22 bought=["level(50)"]
SIM 05:00 level=13 kills=1018 xp=1034/1123 credits=72/83 credits_left=22 zombies=117 kinds=89/11/17/0 elites=0 elites_spawned=0 crates=0 nades=17 dmg_taken=372 peak=123 fps=145 | АК-С L1 Зажи1 [Проб1] | Кольт L1 Стан1 [Спли2] | Мясник L2 Стан1 [] | Мосинка L4 Стан1 []
PICK lvl=14 { "type": "level", "slot": 1, "rare": false } slot=-1 of ["level", "level", "module"]
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
PICK lvl=15 { "type": "module", "id": 1, "rare": false } slot=0 of ["level", "module", "ammo"]
PICK lvl=16 { "type": "ammo", "id": 2, "rare": true } slot=0 of ["module", "ammo", "passive"]
SIM 06:00 level=16 kills=1458 xp=1512/1769 credits=126/165 credits_left=76 zombies=96 kinds=77/0/12/7 elites=0 elites_spawned=2 crates=0 nades=23 dmg_taken=1066 peak=161 fps=145 | АК-С L1 Зажи1 [Проб2] | Кольт L2 Стан1 [Спли2] | Мясник L2 Стан1 [] | Мосинка L4 Стан1 []
PICK lvl=17 { "type": "module", "id": 1, "rare": false } slot=0 of ["level", "passive", "module"]
PICK lvl=18 { "type": "module", "id": 4, "rare": false } slot=2 of ["module", "module", "module"]
PICK lvl=19 { "type": "ammo", "id": 3, "rare": false } slot=0 of ["ammo", "level", "module"]
SIM 07:00 level=19 kills=1828 xp=2236/2330 credits=217/232 credits_left=167 zombies=215 kinds=141/25/28/21 elites=0 elites_spawned=4 crates=0 nades=27 dmg_taken=1250 peak=220 fps=145 | АК-С L1 Крио1 [Проб3] | Кольт L2 Стан1 [Спли2] | Мясник L2 Стан1 [Сдво1] | Мосинка L4 Стан1 []
ALARM_EVENT warn time=07:00
ALARM_EVENT start time=07:03
PICK lvl=20 { "type": "module", "id": 1, "rare": false } slot=3 of ["level", "module", "level"]
LOOT РЕДКАЯ ДЕТАЛЬ: ammo slot=0 rare=true
PICK lvl=21 { "type": "module", "id": 3, "rare": false } slot=3 of ["module", "module", "module"]
PICK lvl=22 { "type": "ammo", "id": 0, "rare": false } slot=0 of ["ammo", "module", "ammo"]
PICK lvl=23 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["level", "passive", "module"]
ALARM_EVENT finish container=(1705.708, 1087.14) time=07:33
CONTAINER dropped pos=(1705.708, 1087.14) time=07:33
ALARM rewards mult=2 xp=2274 credits=298
LOOT СБРОС СНАБЖЕНИЯ: module slot=2 rare=false
CONTAINER picked time=07:34 crates=1
PICK lvl=24 { "type": "passive", "id": 4, "rare": false } slot=-1 of ["level", "ammo", "passive"]
SIM 08:00 level=24 kills=2976 xp=4045/5169 credits=481/625 credits_left=431 zombies=60 kinds=39/0/10/11 elites=0 elites_spawned=10 crates=1 nades=33 dmg_taken=4886 peak=342 fps=145 | АК-С L1 Стан1 [Проб3] | Кольт L2 Стан1 [Спли2] | Мясник L2 Стан1 [Сдво2] | Мосинка L4 Стан1 [Проб1,Дето1]
PICK lvl=25 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "ammo", "level"]
PICK lvl=26 { "type": "module", "id": 4, "rare": false } slot=2 of ["passive", "module", "module"]
PICK lvl=27 { "type": "module", "id": 2, "rare": true } slot=1 of ["module", "module", "passive"]
PICK lvl=28 { "type": "level", "slot": 0, "rare": false } slot=-1 of ["level", "module", "level"]
CALM 09:00 removed=53 left=2
TRADER 1 at 09:00 credits_left=334 bought=["module(60)", "ammo(60)", "level(75)", "passive(60)", "module(60)"]
SIM 09:00 level=28 kills=3636 xp=5742/6139 credits=699/761 credits_left=334 zombies=55 kinds=31/0/17/7 elites=0 elites_spawned=12 crates=1 nades=34 dmg_taken=5011 peak=181 fps=145 | АК-С L3 Зажи1 [Проб3,Спли1] | Кольт L2 Стан1 [Спли3] | Мясник L3 Стан1 [Сдво3,Рико1] | Мосинка L4 Стан1 [Проб1,Дето1]
PICK lvl=29 { "type": "ammo", "id": 2, "rare": false } slot=0 of ["ammo", "level", "level"]
LOOT РЕДКАЯ ДЕТАЛЬ: module slot=2 rare=true
BOSS spawn t=600.00 pos=(2365.964, 969.6426) hp=24000
SIM 10:00 level=29 kills=3833 xp=6111/6390 credits=745/795 credits_left=380 zombies=22 kinds=9/13/0/0 elites=0 elites_spawned=14 crates=1 nades=37 dmg_taken=5011 peak=22 fps=145 | АК-С L3 Зажи2 [Проб3,Спли1] | Кольт L2 Стан1 [Спли3] | Мясник L3 Стан1 [Сдво3,Рико2] | Мосинка L4 Стан1 [Проб1,Дето1]
SIM summary kills=3833 peak=342 level=29 damage=5011.49 boss_alive=true

EXIT_CODE=0

```

## r1b_visual_final.log

```text
"C:/Program Files/Git/bin/bash.exe" C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --log-file C:\Users\Dev\Desktop\zera-r1b\design\tasks\reports\r1b_visual_final_engine.log --disable-vsync --path C:\Users\Dev\Desktop\zera-r1b -- --fresh-save --gore-shots --gore-closeup --r1b --shot=res://design/tasks/reports/r1b_fight_after.png
GODOT_EXCLUSIVE other_godot_processes=0 at 22:22:18
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: AMD - AMD Radeon(TM) Graphics

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=618.94 seed=81073
GORESTAND seconds=60 debris=50 peak=112 remains=90 remains_peak=200 stamps=29154 queue=0 pools=17 memory=135919501 video=302518272
GORESTAND seconds=300 debris=51 peak=132 remains=177 remains_peak=200 stamps=146684 queue=0 pools=18 memory=135941293 video=302125056
GORESTAND screenshot: res://design/tasks/reports/r1b_fight_after_5min.png
R1BSTAND fight simultaneous_hits=40 camera=3 screenshot=r1b_fight_5min.png
GORESTAND seconds=480 debris=71 peak=132 remains=131 remains_peak=200 stamps=235058 queue=0 pools=17 memory=136094509 video=302583808
GORESTAND seconds=600 debris=27 peak=132 remains=113 remains_peak=200 stamps=293470 queue=0 pools=14 memory=136091325 video=302649344
GORESTAND screenshot: res://design/tasks/reports/r1b_fight_after_10min.png
GORESTAND complete seed=81073 deaths=7200 zoom=3 map=quarantine_checkpoint
R1BSTAND hits order=rifle,smg,pistol,revolver,shotgun,sniper,rail,launcher age=60ms zoom=3 native_pixels=true stage=after
WARNING: 1 ObjectDB instance was leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

EXIT_CODE=0

```

