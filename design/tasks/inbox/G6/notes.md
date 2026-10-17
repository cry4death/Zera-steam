# Отчёт G6 — boss.gd: «Объект-7»

**Исполнитель:** ChatGPT (Codex) · **Ветка/файл:** inbox/G6/boss.gd · **Коммит:** нет, передача файла ревьюеру.

## Сделано

- Полный Boss по CONTRACTS.md §6: имена, типы, константы, свойства, семь сигналов и четыре публичных метода сохранены.
- WALK, TELEGRAPH, CHARGE, RECOVER, SLAM, ROAR и переход SHED; 24 000 HP, броня ×0.75, фаза 2 при HP ≤12 000. Смертельный удар сразу завершает бой; дальнейшие попадания не повторяют died.
- Таран 400 px/с до внутренней границы арены; полная фиксация цели при начале каждого телеграфа, swept-проверка отрезка против игрока и орды. Контрактный вызов Horde.damage, crushed только при подтверждённом убийстве.
- Серия фазы 2: три отдельных телеграфа по 0.7 с, паузы 0.4/0.4/0.6 с. В первой фазе телеграф 1 с и RECOVER 0.6 с. КД серии 6 с отсчитывается от окончания последнего прохода.
- Замах SLAM 0.5 с, волна 0→150 за 0.6 с, ширина 20, 25 урона один раз. Учитывается относительное пересечение игроком фронта между тиками; запрос урона не повторяется после уклонения с неуязвимостью. КД 9/6.3 с от начала волны.
- Рёв 0.8 с с кольцами и кровавой слюной; сигнал 15/25, КД 15 с от сигнала. Контакт при ходьбе 20/25 раз в 0.8 с. Во время атак/восстановления отдельного контактного урона нет: он не подменяет телеграфированный урон и окно RECOVER.
- Срыв брони: 1.2 с неуязвимости, восемь направлений armor_plate, кровь и тряска. В фазе 1 пластина каждые 1500 фактически снятых HP; в фазе 2 капли effects.emit(..., true) при ходьбе/таране. Пластины и смерть визуализирует интегратор по сигналам, как предписано контрактом.
- Отрисовка листа 5×2, ячейка 144×144, ART_SCALE, фаза по строке, шаги по пути, кадр 4 при CHARGE. Процедурная туша при отсутствии boss.png, тень, предупреждения и волны без draw_circle. Один дочерний Node2D только для тела и белой вспышки 0.08 с; нод на атаки нет.
- Обычная пауза дерева останавливает босса. Координаты start, hit_test, сигналов и интеграционных объектов — мировые. arena следует задать до start.

## Изменённые файлы

| Файл | Что |
|---|---|
| `boss.gd` | Файл для переноса в `zera/scripts/boss.gd` ревьюером. |
| `test_boss.gd` | Воспроизводимый проверочный скрипт; запускать в копии проекта из её корня. |
| `preview.png` | Осмотренное превью процедурных фаз и предупреждений, 1280×720. |
| `notes.md` | Этот отчёт. |

Исходный `C:/Users/Dev/Desktop/zera` использовался только для чтения. Git-команды, изменение веток и запись в исходный проект не выполнялись. Копия создана robocopy `/E /XD .git .godot`, только в разрешённом scratch/G6/project.

## Проверка

В командах ниже `$g6` — `C:/Users/Dev/AppData/Local/Temp/claude/C--Users-Dev-Desktop-GameZ/c0951c8e-5403-4ca4-8a08-a7e35d3e4417/scratchpad/codex_tmp/G6`, `$godot` — `$g6/engine/Godot_v4.7.2-stable_win64_console.exe`. Это неизменённая копия указанного пользователем Godot 4.7.2 вместе с основным EXE и стандартным маркером `_sc_`: настройки редактора остаются в scratch. Исходный запуск указанным EXE пытался сохранить настройки вне разрешённых папок (ошибка приведена ниже), поэтому последующие проверки выполнены в штатном self-contained режиме.

Для воспроизведения: скопировать проект без `.git`/`.godot`, положить `boss.gd` в `scripts`, `test_boss.gd` в корень копии. При запуске не требуются Python или установленные дополнения; Python использован только для сборки этого отчёта из сохранённых логов.

Проверка парсера финального файла:

```powershell
& $godot --headless --path "$g6/project" --check-only --script res://scripts/boss.gd --log-file "$g6/check.log"
```

```text
CHECK_ONLY_EXIT=0
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
```

Финальный импорт (завершён, ошибок/предупреждений GDScript нет; остаётся системная ошибка сертификатов):

```powershell
& $godot --headless --path "$g6/project" --import --log-file "$g6/import-final.log"
```

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
[   0% ] first_scan_filesystem | Started Инициализация проекта (5 steps)
[   0% ] first_scan_filesystem | Сканирование структуры файлов…
[  16% ] first_scan_filesystem | Загрузка глобальных имен классов…
[  33% ] first_scan_filesystem | Проверка GDExtensions…
[  50% ] first_scan_filesystem | Создание скриптов автозагрузки…
[  66% ] first_scan_filesystem | Инициализация плагинов…
[  83% ] first_scan_filesystem | Начало сканирование файлов…
[ DONE ] first_scan_filesystem

[   0% ] update_scripts_classes | Started Регистрация глобальных классов… (2 steps)
[   0% ] update_scripts_classes | Boss
[  33% ] update_scripts_classes | 
[ DONE ] update_scripts_classes

[   0% ] loading_editor_layout | Started Загрузка редактора (5 steps)
[   0% ] loading_editor_layout | Загрузка макета редактора…
[  16% ] loading_editor_layout | Загрузка док-панели…
[ DONE ] loading_editor_layout
```

60 игровых секунд, 3600 шагов по 1/60 с, без ожидания реального времени. Реальные Player, Horde и Effects из копии проекта; в начале 200 шаркающих, по roar добавляются бегуны. Игрок чередует круговую траекторию и близкую позицию; отдельные проверки оставляют его неподвижным. Вручную шагают физика орды и босса, эффекты и таймер неуязвимости Player; фактический урон проходит через оригинальный Player.take_damage и сигнал hurt. Повреждение босса до порога вносится скриптом на 30-й секунде. После SIM идут изолированные проверки с фиксированной меткой t=60.000. Пауза отдельно проверена настоящими кадрами SceneTree.

```powershell
& $godot --headless --disable-vsync --path "$g6/project" --script res://test_boss.gd --log-file "$g6/test-final.log"
```

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
SIM begin seconds=60 hz=60 shamblers=200 seed=706
EVENT t=0.017 telegraph phase=1 duration=1.0
EVENT t=3.800 roar count=15
EVENT t=8.500 slam phase=1
EVENT t=9.117 telegraph phase=1 duration=1.0
EVENT t=19.600 roar count=15
EVENT t=19.617 telegraph phase=1 duration=1.0
EVENT t=24.500 slam phase=1
EVENT t=27.017 telegraph phase=1 duration=1.0
EVENT t=30.017 phase=2 hp=12000.00 plates=16
EVENT t=34.167 slam phase=2
EVENT t=35.583 roar count=25
EVENT t=35.600 telegraph phase=2 duration=0.7
EVENT t=37.217 telegraph phase=2 duration=0.7
EVENT t=39.167 telegraph phase=2 duration=0.7
EVENT t=42.533 slam phase=2
EVENT t=47.433 telegraph phase=2 duration=0.7
EVENT t=49.483 telegraph phase=2 duration=0.7
EVENT t=51.917 telegraph phase=2 duration=0.7
EVENT t=55.200 roar count=25
EVENT t=56.500 slam phase=2
EVENT t=59.800 telegraph phase=2 duration=0.7
SIM end telegraphs=11 slams=5 roars=4 crushed=255 plates=16
PERF boss_physics_avg_ms=0.007391 max_ms=0.131000 samples=3600
EVENT t=60.000 phase=2 hp=12000.00 plates=32
CHECK walk_speed=40/60 phase2_damage=100% flash=0.08 blood_bake PASS
EVENT t=60.000 phase=2 hp=12000.00 plates=48
CHECK contact phase1=20 phase2=25 cooldown=0.8 PASS
EVENT t=60.000 telegraph phase=1 duration=1.0
CHECK charge telegraph=1.0 swept_damage=35 once PASS
EVENT t=60.000 slam phase=1
EVENT t=60.000 slam phase=1
EVENT t=60.000 phase=2 hp=12000.00 plates=64
EVENT t=60.000 slam phase=2
CHECK slam windup=0.5 radius=150 time=0.6 width=20 damage=25 once dash_safe PASS
EVENT t=60.000 phase=2 hp=12000.00 plates=80
EVENT t=60.000 telegraph phase=2 duration=0.7
EVENT t=60.000 telegraph phase=2 duration=0.7
EVENT t=60.000 telegraph phase=2 duration=0.7
CHECK phase2 telegraphs=[0.7, 0.7, 0.7] recovery_frames=[24, 24, 36]
EVENT t=60.000 telegraph phase=1 duration=1.0
CHECK wall_recover displacement hit_test death PASS
CHECK pause PASS
RESULT failures=0
```

Среднее **0.007391 мс**, максимум **0.131 мс**, 3600 вызовов. Это время непосредственно вызова Boss._physics_process, включая его обращения к орде/сигналам/эффектам, без чужой физики и GPU-отрисовки. FPS не измерялся: прогон исполняет фиксированные игровые шаги ускоренно. Все проверки вернули `RESULT failures=0`.

Превью получено настоящим рендером Godot Compatibility/OpenGL; шесть панелей: броня, мясо, телеграф, замах, волна и рёв. Я открыл и осмотрел финальный PNG. В двух первых панелях тело увеличено ×3 для осмотра; остальные показывают реальные игровые размеры. Для этого запуска только во временном project.godot отключён штатный `rendering/shader_compiler/shader_cache/enabled`: иначе sandbox запрещает запись кэша. Код boss.gd не содержит этой настройки.

```powershell
& $godot --rendering-method gl_compatibility --rendering-driver opengl3 --audio-driver Dummy --windowed --resolution 1280x720 --disable-vsync --path "$g6/project" --script res://preview.gd --log-file "$g6/preview-final.log" -- C:/Users/Dev/Desktop/GameZ/tasks/inbox/G6/preview.png
```

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 610.88 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 3060 Ti

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
PREVIEW save_png=0 size=(1280, 720)
```

Скриншоты: `inbox/G6/preview.png`.

## Критерии приёмки

- [x] Контракт §6 буква в букву: публичные имена, типы и семантика сохранены.
- [x] Все атаки и числа BALANCE §10, телеграфы честные (урон не раньше конца телеграфа): проверены симуляцией и изолированными тестами. Значения диапазонов выбора атак дополнены запасным выбором, см. ниже.
- [x] Фаза 2: срыв брони, серии таранов, кровь. Проверка точно на 50%; 8 пластин от накопленного урона + 8 срыва = 16 в логе перехода.
- [x] Не выходит за арену, не застревает в углу (если таран упирается в стену — RECOVER): проверены все кадры SIM, нулевой путь у стены и внешний перенос за границы.
- [x] Лог проверки и ограничения в `notes.md`.
- [x] Средняя цена физики босса <0.3 мс.
- [ ] Буквально безошибочный вывод `--headless --import`: не достигнут из-за системного хранилища сертификатов. Импорт завершается, GDScript ошибок и предупреждений не выдаёт; `--check-only` чистый. Это ограничение среды, не скрыто и не подавлено.

## Отступления от задачи и контракта

- После приоритетов «дальше 180 — таран / ближе 120 — SLAM / мало бегунов — ROAR» разрешён запасной таран на меньшей дистанции, если он готов, предыдущая атака другая и игрок вне контактного радиуса. Первый прогон выявил длительное отсутствие атак после SLAM при живых бегунах и постоянно близком игроке. Запасной выбор позволяет чередовать атаки; телеграф сохраняется полностью. Публичный контракт не меняется; это уточнение поведения для ревьюера.
- «Мало бегунов» конкретизировано как менее 8 живых в радиусе 260; этих чисел в BALANCE §10 нет. Это локальные параметры выбора, не изменение боевых статов.
- Между проходами серии используется RECOVER 0.4 с, после последнего — 0.6 с. Это согласует одновременно заданные в задаче «между ними 0.4» и «после тарана RECOVER 0.6».
- Лист `art/boss.png` в прочитанном исходном проекте отсутствовал. Визуально проверена запасная отрисовка; реальный G4-арт и бой с оружием/наградами S4 пока не проверены. Поддержка раскладки реализована, но оценка длительности полноценного боя 60–80 с остаётся за интеграционным плейтестом.
- FloorDecals в симуляции не создаёт GPU-пол; проверяется флаг bake у оригинального Effects. Запекание этого API уже реализовано существующим Effects; новых методов пола босс не требует. camera используется через существующий shake, без изменения камеры.
- Требуемые изменения CONTRACTS.md: нет.

## Найденные проблемы вне задачи

1. Godot в sandbox сообщает ошибку корневого хранилища сертификатов даже на пустом проекте с единственным SceneTree-скриптом `quit()`. Контрольный запуск:

```powershell
& $godot --headless --path "$g6/control" --script res://quit.gd --log-file "$g6/control-script.log"
```

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
```

2. Первый импорт исходным EXE дополнительно сообщил (дословно):

```text
ERROR: Cannot save file 'C:/Users/Dev/AppData/Roaming/Godot/editor_settings-4.7.tres'.
   at: save (scene/resources/resource_format_text.cpp:1768)
ERROR: Error saving editor settings to C:/Users/Dev/AppData/Roaming/Godot/editor_settings-4.7.tres
   at: save (editor/settings/editor_settings.cpp:1525)
```

После переноса неизменённого движка в scratch с `_sc_` этих сообщений в финальном импорте нет. Первое превью также выдавало `ERROR: Condition "f.is_null()" is true.` / `at: _save_to_cache (drivers/gles3/shader_gles3.cpp:648)`; штатное отключение кэша только во временном проекте устранило их. Ошибок компиляции шейдера не было.

3. `find-docs`/Context7 недоступен: `npx.cmd --yes ctx7@latest library Godot ...` вернул дословно `✖ fetch failed`. PowerShell-вариант npx.ps1 блокируется ExecutionPolicy; cmd-обёртка установлена штатно. Самодельных замен инструментов не использовано. API сверены по существующему коду, `--check-only` и официальной документации:
   - https://docs.godotengine.org/en/stable/classes/class_canvasitem.html
   - https://docs.godotengine.org/en/stable/classes/class_geometry2d.html
   - https://docs.godotengine.org/en/stable/classes/class_projectsettings.html

4. Очистка временной папки **не выполнена**: автоматическая проверка отклонила PowerShell Remove-Item с причиной `blocked by policy`. Сначала был проверен и разрешён абсолютный путь, затем предпринят более простой вызов с буквальным путём; он также отклонён. Другие способы обхода запрета не применялись. Дословный итог второго вызова:

```text
Remove-Item -LiteralPath 'C:/Users/Dev/AppData/Local/Temp/claude/C--Users-Dev-Desktop-GameZ/c0951c8e-5403-4ca4-8a08-a7e35d3e4417/scratchpad/codex_tmp/G6' -Recurse -Force -ErrorAction Stop
rejected: blocked by policy
```

Временные проект, превью-скрипт, копия движка, кэш npm и логи остались исключительно в разрешённом `C:/Users/Dev/AppData/Local/Temp/claude/C--Users-Dev-Desktop-GameZ/c0951c8e-5403-4ca4-8a08-a7e35d3e4417/scratchpad/codex_tmp/G6`. Для завершения очистки этот каталог нужно удалить вне текущего ограничения политики. В inbox оставлены только четыре перечисленных результата. Проверка списка процессов через Get-CimInstance также недоступна (`HRESULT 0x80041003`, отказано в доступе); контрольный запуск без main_scene прерван через его собственную exec-сессию, остальные запуски завершились сами.
