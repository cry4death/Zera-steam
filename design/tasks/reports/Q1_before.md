Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=237.13 seed=81073
PACKTEST bank=89 missing=0 maps=3 ok=true
Q1TEST pack=true
Q1CARDS seed=81073 generations=3000 cards=9000 invalid=1432
METATEST FAIL cards_applicable 
Q1TEST cards_applicable=false
METATEST FAIL wall_open_takes_damage 
Q1TEST wall_open_takes_damage=false
METATEST FAIL wall_no_ammo_spent 
Q1TEST wall_no_ammo_spent=false
METATEST FAIL wall_boss_rejected 
Q1TEST wall_boss_rejected=false
METATEST FAIL stick_hold_once 
Q1TEST stick_hold_once=false
METATEST FAIL pad_install_open 
Q1TEST pad_install_open=false
Q1TEST pad_install_back=true
METATEST FAIL pad_module_applied 
Q1TEST pad_module_applied=false
METATEST FAIL pad_purchase 
Q1TEST pad_purchase=false
METATEST FAIL pad_shop_close 
Q1TEST pad_shop_close=false
Q1TEST slider_applies_immediately=true
Q1SLIDER movements=100 save_calls=101
METATEST FAIL slider_one_save 
Q1TEST slider_one_save=false
Q1TEST checks=13 failed=10 ok=false
ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
ERROR: Resource file not found: res://art/map_roof_0_12_65_0.png (expected type: unknown)
   at: _load (core/io/resource_loader.cpp:325)
   GDScript backtrace (most recent call first):
       [0] tex (res://scripts/pixel_art.gd:53)
       [1] setup (res://scripts/obstacles.gd:181)
       [2] _q1_wall (res://scripts/meta_test.gd:950)
       [3] _q1_run (res://scripts/meta_test.gd:1004)
       [4] run_q1 (res://scripts/meta_test.gd:805)
       [5] _run_q1_test (res://scripts/game.gd:1994)

EXIT=1
