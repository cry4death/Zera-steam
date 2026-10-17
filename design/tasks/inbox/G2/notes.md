# Отчёт G2 — доработка по ревью от 2026-10-17

**Исполнитель:** ChatGPT · **Ветка/файл:** inbox/G2/alarm_overlay.gd · **Коммит:** не создавался

## Сделано
- Полностью прочитаны README.md, CONTRACTS.md, M4/G2_alarm_overlay.md, reviews/G2.md и шаблон отчёта. Исправлены только замечания 1–2 ревью.
- Радиальный овал заменён двумя плавными краевыми спадами, один раз запечёнными в ImageTexture 1024×576 в _ready. Шесть точек градиента дают ease-in: до радиуса 0.55 прозрачно, затем постепенное нарастание. В 16:9 ширина спада одинакова от четырёх краёв: 243 экранных px при 1920×1080. Залитых плоских углов и границы овала больше нет.
- Цвет середины края (0.35, 0, 0.02) плавно темнеет до (0.12, 0, 0.01) в углах. При среднем уровне пульса альфа края 0.40, угла 0.58; размах пульса в углу 0.58 ± 0.12. Прежние двойной удар и периоды 1.1/0.6 с сохранены. В _draw по-прежнему один вызов рисования виньетки, новых аллокаций/нод/шейдеров нет.
- Полосы warn уменьшены с 10 до 7 игровых px. Это оставляет зазор до HP (начало y=9) и цифр таймера; положение и анимация полос сохранены. Верхняя полоса опыта у самого края остаётся в общей зоне полосы, как допущено вариантом исправления из ревью.
- Сверены реальные scripts/alarm_overlay.gd, hud.gd, screen_blood.gd, scenes/main.tscn и tools/gen_art.py. Исходный alarm_overlay.gd в zera совпадал с исходником inbox перед правкой и остался неизменным после проверки. В zera ничего не записывалось, git не запускался, BOARD.md не менялся.

## Изменённые файлы
- alarm_overlay.gd — полный файл для замены, только новая виньетка/её амплитуда и высота полос.
- start.png, warn.png — новые настоящие снимки из Godot 4.7.2, 1920×1080; расчётные промежуточные превью заменены снимками движка. Оба открыты и просмотрены.
- notes.md — этот отчёт; import.log, parser.log, validation.log, render.log, render_errors.log — дословные stdout/stderr текущей проверки. Остальные существующие материалы inbox не менялись.

## Проверка
Временная копия: C:/Users/Dev/AppData/Local/Temp/claude/C--Users-Dev-Desktop-GameZ/c0951c8e-5403-4ca4-8a08-a7e35d3e4417/scratchpad/codex_tmp/G2. Копирование исключало .git и .godot. В scripts/ копии помещён обновлённый файл, SHA256 совпал с inbox. Все запуски выполнялись только на этой копии; она удалена, отсутствие проверено.

Исполняемый файл: C:/Users/Dev/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe.

Команды (полный вывод каждой команды дословно сохранён в соответствующем .log):

~~~text
--headless --path <копия> --import
--headless --path <копия> --check-only --script res://scripts/alarm_overlay.gd
--headless --path <копия> --quit-after 240 --script res://validate_alarm_overlay.gd
--path <копия> --rendering-method gl_compatibility --windowed --resolution 1920x1080 --quit-after 180 --script res://render_alarm_overlay.gd -- --out=<копия>/screens
~~~

Все четыре команды завершились с кодом 0. Ошибок/предупреждений парсера по alarm_overlay.gd нет. Проверочный скрипт из прежнего inbox скопирован во временную папку; только там обновлены ожидаемые альфы 0.70/0.628/0.58 и диапазон проверки текстуры 1024×576. Исходные вспомогательные скрипты inbox не менялись. Проверки: 39 PASS поведения, 11 PASS рендера, failures=0 в обоих прогонах.

Дословный вывод check-only:

~~~text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
~~~

Дословный stdout проверки поведения:

~~~text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

PASS: initially hidden and inactive
PASS: single Control, no child nodes
PASS: full-screen anchors
PASS: mouse and focus pass through
PASS: pause is respected under an ALWAYS parent
PASS: warn starts at 3
PASS: warning stripes enter during first 0.25 seconds
PASS: stripes fully entered and title blink is hard
PASS: warning title repeats at 2 Hz
PASS: warning countdown 2
PASS: warning countdown 1
PASS: start replaces warning and shows 0:30
PASS: initial flash respects central alpha limit
PASS: first heartbeat reaches corner alpha 0.70
PASS: second heartbeat is weaker
PASS: full-screen flash ends by 0.3 seconds
PASS: stripes leave by 0.4 seconds
PASS: bonus and remaining time are cached text
PASS: last five seconds use 0.6-second heartbeat period
PASS: finish is visible but not active
PASS: finish halves vignette opacity at 0.75 seconds
PASS: repeated finish does not restart fade
PASS: finish hides and stops processing after 1.5 seconds
PASS: zero warning duration stays hidden
PASS: negative alarm duration stays hidden
PASS: non-finite duration is rejected
PASS: alarm automatically finishes when duration expires
PASS: stop clears and hides immediately
PASS: warning expiry never starts the game alarm by itself
PASS: large delta handles alarm expiry and full result fade
PASS: reduced motion keeps warning stable
PASS: reduced motion removes flash and heartbeat
PASS: actual tree pause freezes warning under ALWAYS layer
PASS: warning resumes after unpause
PASS: actual tree pause freezes active alarm
PASS: actual tree pause freezes result fade
PASS: textures are reused across phases
PASS: vignette is transparent throughout central 60 percent rectangle
PASS: phase changes create no child nodes
RESULT: failures=0
~~~

Дословный stdout рендера:

~~~text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 610.88 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 3060 Ti

PASS: saved warn.png
PASS: saved start.png
PASS: saved finish.png
PASS: saved background.png
ALPHA: warn; central_max=0.0; edge=0.19
PASS: central 60 percent alpha <= 0.12: warn
ALPHA: start flash; central_max=0.1176470592618; edge=0.46
PASS: central 60 percent alpha <= 0.12: start flash
ALPHA: start first heartbeat; central_max=0.07843137532473; edge=0.7
PASS: central 60 percent alpha <= 0.12: start first heartbeat
ALPHA: start steady; central_max=0.00392156885937; edge=0.7
PASS: central 60 percent alpha <= 0.12: start steady
ALPHA: finish; central_max=0.00392156885937; edge=0.60666666666667
PASS: central 60 percent alpha <= 0.12: finish
ALPHA: 1280x720; central_max=0.0; edge=0.46
PASS: central 60 percent alpha <= 0.12: 1280x720
ALPHA: 2560x1440; central_max=0.0; edge=0.46
PASS: central 60 percent alpha <= 0.12: 2560x1440
RESULT: failures=0
~~~

Копия, проверенный файл и уборка:

~~~text
SHA256: a82d3635ae0c678c739289beda5e64cd64183689350cf10f3ffd63b08c2baf3f
PASS: only vignette texture, vignette pulse amplitude and stripe height changed
PASS: tab indentation; no draw_circle; public API and all other function bodies unchanged
CLEANUP: temporary G2 copy deleted; absence verified
~~~

## Критерии приёмки
- [x] Замечание 1: плавный ease-in из шести точек, тёмные края, ещё более тёмные углы, одинаковая ширина спада в 16:9, требуемая альфа и сердцебиение.
- [x] Замечание 2: полосы 7 игровых px, выбор объяснён выше, HP и таймер читаются.
- [x] Замечание 3: публичный контракт и остальной игровой код сохранены; неизменность остальных тел функций проверена сравнением с исходником.
- [x] Скрытие, пауза под ALWAYS-родителем, мышь, warn/start/finish/stop/is_active, обратный отсчёт, вспышка, ускорение сердцебиения и переиспользование ресурсов проверены.
- [x] Альфа центральных 60% не выше 0.12: максимум реального рендера во вспышке 0.1176470592618, в устойчивой тревоге 0.00392156885937. Проверены также 1280×720 и 2560×1440.
- [x] Импорт/парсер, новые снимки start/warn, визуальный просмотр и удаление временной копии выполнены.

## Отступления от задачи и контракта
- Вместо двух draw_texture_rect спады X/Y объединены в одну ImageTexture при инициализации: это позволяет отдельно затемнять цвет углов и сохранить прежний один draw виньетки. Внешний арт и новые API проекта не нужны. Размер и равная ширина спада рассчитаны на заданные 16:9.
- Ограничение вспышки 30/255 и остальные принятые ранее решения сохранены. Изменений контракта нет.

## Найденные проблемы вне задачи
Недостающих API нет. Оверлей не использует S1; связанных с S1 ошибок при импорте нет.

Среда сначала вернула EPERM при чтении zera и ENOENT при запуске Godot, затем доступ восстановился; итоговая проверка проведена полностью. Godot вывел следующие системные ошибки окружения (дословно); к GDScript они не относятся:

Импорт, stderr:

~~~text
ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
ERROR: Could not open 'user://' directory: 'user://'.
   at: _get_and_create_snapshot_storage_dir (modules/objectdb_profiler/editor/objectdb_profiler_panel.cpp:157)
ERROR: Cannot open directory './Godot/feature_profiles'.
   at: _update_profile_list (editor/settings/editor_feature_profile.cpp:392)
~~~

Проверка поведения, stderr:

~~~text
ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
~~~

Рендер, stderr:

~~~text
ERROR: Can't create shader cache folder, no shader caching will happen: user://
   at: RasterizerGLES3 (drivers/gles3/rasterizer_gles3.cpp:345)
ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
~~~

API встроенных Image/ImageTexture/Gradient/Color сверены с официальной документацией и фактически проверены компиляцией и рендерингом: [Image](https://docs.godotengine.org/en/4.7/classes/class_image.html), [ImageTexture](https://docs.godotengine.org/en/4.7/classes/class_imagetexture.html), [Gradient](https://docs.godotengine.org/en/4.7/classes/class_gradient.html), [Color](https://docs.godotengine.org/en/4.7/classes/class_color.html).
