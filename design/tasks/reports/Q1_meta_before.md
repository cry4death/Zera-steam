Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to open 'user://logs/godot2026-10-18T19.45.55.log'.
строка:2 знак:59
+ ... ing]::UTF8; & 'C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/God ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...T19.45.55.log'.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   at: copy (core/io/dir_access.cpp:429)
ERROR: Failed to open log file for writing: user://logs/godot.log
   at: rotate_file (core/io/logger.cpp:169)
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=247.07 seed=81073
SCRIPT ERROR: Assertion failed.
   at: _settings_checks (res://scripts/game.gd:1822)
   GDScript backtrace (most recent call first):
       [0] _settings_checks (res://scripts/game.gd:1822)
       [1] _run_meta_test (res://scripts/game.gd:1991)
WARNING: Meta: запись user://test_save.json не удалась
   at: push_warning (core/variant/variant_utility.cpp:1033)
   GDScript backtrace (most recent call first):
       [0] save (res://scripts/meta.gd:361)
       [1] _test_save_load (res://scripts/meta_test.gd:120)
       [2] _run (res://scripts/meta_test.gd:37)
       [3] run (res://scripts/meta_test.gd:22)
       [4] _run_meta_test (res://scripts/game.gd:1992)
METATEST FAIL save.file_written tmp-файл остался или файла нет
METATEST FAIL save.load_ok 
METATEST FAIL save.fields 
METATEST FAIL save.tree_workshop 
METATEST FAIL save.owned_favorite 
SCRIPT ERROR: Cannot call method 'store_string' on a null value.
   at: MetaTest._write_text (res://scripts/meta_test.gd:89)
   GDScript backtrace (most recent call first):
       [0] _write_text (res://scripts/meta_test.gd:89)
       [1] _test_save_load (res://scripts/meta_test.gd:128)
       [2] _run (res://scripts/meta_test.gd:37)
       [3] run (res://scripts/meta_test.gd:22)
       [4] _run_meta_test (res://scripts/game.gd:1992)
METATEST FAIL save.corrupt_detected 
METATEST FAIL save.corrupt_backup копий: 0
METATEST FAIL save.corrupt_rewritten 
SCRIPT ERROR: Cannot call method 'store_string' on a null value.
   at: MetaTest._write_text (res://scripts/meta_test.gd:89)
   GDScript backtrace (most recent call first):
       [0] _write_text (res://scripts/meta_test.gd:89)
       [1] _test_save_load (res://scripts/meta_test.gd:133)
       [2] _run (res://scripts/meta_test.gd:37)
       [3] run (res://scripts/meta_test.gd:22)
       [4] _run_meta_test (res://scripts/game.gd:1992)
SCRIPT ERROR: Cannot call method 'store_string' on a null value.
   at: MetaTest._write_text (res://scripts/meta_test.gd:89)
   GDScript backtrace (most recent call first):
       [0] _write_text (res://scripts/meta_test.gd:89)
       [1] _test_save_load (res://scripts/meta_test.gd:135)
       [2] _run (res://scripts/meta_test.gd:37)
       [3] run (res://scripts/meta_test.gd:22)
       [4] _run_meta_test (res://scripts/game.gd:1992)
SCRIPT ERROR: Cannot call method 'store_string' on a null value.
   at: MetaTest._write_text (res://scripts/meta_test.gd:89)
   GDScript backtrace (most recent call first):
       [0] _write_text (res://scripts/meta_test.gd:89)
       [1] _test_save_load (res://scripts/meta_test.gd:138)
       [2] _run (res://scripts/meta_test.gd:37)
       [3] run (res://scripts/meta_test.gd:22)
       [4] _run_meta_test (res://scripts/game.gd:1992)
SCRIPT ERROR: Cannot call method 'store_string' on a null value.
   at: MetaTest._write_text (res://scripts/meta_test.gd:89)
   GDScript backtrace (most recent call first):
       [0] _write_text (res://scripts/meta_test.gd:89)
       [1] _test_save_load (res://scripts/meta_test.gd:141)
       [2] _run (res://scripts/meta_test.gd:37)
       [3] run (res://scripts/meta_test.gd:22)
       [4] _run_meta_test (res://scripts/game.gd:1992)
METATEST FAIL save.sanitize 
METATEST save: есть ошибки
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
METATEST trait sticky (Улей): кассета из 3, прилипание → взрыв через 0.58 с (едет с носителем), носитель потерял 29 HP
METATEST trait hicap (Страж): магазин 17, 4.2 выстр/с, урон 8; перезарядка после 17 выстрелов
METATEST trait fan (Ковбой): 6 выстрелов за 0.43 с по 5 разным целям, барабан пуст → перезарядка
METATEST trait steady (Оса): магазин 50, за 4 с 44 выстрелов, разброс +0.0° (ППШ за 1 с +21.0°)
METATEST trait lever (Винчестер): интервал 0.63 с, после убийства следующий выстрел через 0.23 с; урон 28.8 (Мосинка 48), темп 1.6/с
METATEST checks=257 failed=9
METATEST ok=false
