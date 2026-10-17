# Отчёт G5 — экран итогов забега

**Исполнитель:** ChatGPT (Codex) · **Ветка/файл:** inbox/G5/run_results.gd · **Коммит:** нет, zera только чтение.

## Сделано
- RunResults по CONTRACTS.md §8: open(stats: Dictionary), restart_requested, PROCESS_MODE_ALWAYS.
- Панель 260×316 игровых пикселей, затемнение, полноразмерный текст с обводкой в стиле level_up.gd / trader_ui.gd. Статистика с точками-лидерами, готовые подписи оружия, множитель и крупный золотой итог ДНК.
- ДНК появляется построчно каждые 0.25 с; значения досчитываются от нуля за 0.3 с. Первое действие допечатывает, второе запрашивает рестарт. Сигнал повторно не испускается до следующего open().
- R, включая физическую клавишу при русской раскладке, Enter, цифровой Enter, Space, клик по кнопке. Защита первых 0.25 с и игнорирование echo.
- Две колонки для длинных списков, перенос оружия, уменьшение подписей ДНК до 6 px и многоточие для чрезмерно длинных подписей. Внутренняя прокрутка колесом / ↑↓ / PageUp / PageDown; заголовок, итог и кнопка закреплены.
- Суммы ДНК берутся готовыми из stats, баланс не пересчитывается.

## Изменённые файлы
- run_results.gd — полный новый файл для переноса ревьюером в zera/scripts/.
- victory.png, death.png — обязательные снимки 1920×1080.
- printing.png — печать чека, 1920×1080.
- victory_1280.png, victory_2560.png — 1280×720 и 2560×1440.
- long_list.png, long_list_bottom.png — 20 стволов и 22 строки ДНК, начало и конец прокрутки, 2560×1440.
- notes.md — отчёт.

## Проверка
Копия zera без .git и .godot сделана robocopy в разрешённый scratch/G5. Во временном тестовом SceneTree создавался RunResults, дерево ставилось на паузу, вызывался open(), ввод передавался через Input.parse_input_event(). Assert проверял печать, допечатывание, рестарт, нулевую прокрутку стандартного набора и отсутствие дочерних нод. PNG получены из viewport после RenderingServer.frame_post_draw. Все итоговые снимки просмотрены самостоятельно.

GODOT = C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe
SCRATCH = C:\Users\Dev\AppData\Local\Temp\claude\C--Users-Dev-Desktop-GameZ\c0951c8e-5403-4ca4-8a08-a7e35d3e4417\scratchpad\codex_tmp\G5
APPDATA и LOCALAPPDATA для проверок направлены внутрь SCRATCH: настройки и логи не пишутся в профиль пользователя.

Финальный импорт: GODOT --headless --path SCRATCH --import --quit. Код возврата 0. Ниже полный stdout + stderr; удалены только ANSI-коды цвета.
```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started Инициализация проекта (5 steps)
[   0% ] first_scan_filesystem | Сканирование структуры файлов…
[  16% ] first_scan_filesystem | Загрузка глобальных имен классов…
[  33% ] first_scan_filesystem | Проверка GDExtensions…
[  50% ] first_scan_filesystem | Создание скриптов автозагрузки…
[  66% ] first_scan_filesystem | Инициализация плагинов…
[  83% ] first_scan_filesystem | Начало сканирование файлов…
[ DONE ] first_scan_filesystem

[   0% ] loading_editor_layout | Started Загрузка редактора (5 steps)
[   0% ] loading_editor_layout | Загрузка макета редактора…
[  16% ] loading_editor_layout | Загрузка док-панели…
[ DONE ] loading_editor_layout

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

```

Финальный тест: GODOT --path SCRATCH --rendering-method forward_plus --script res://test_results.gd. Код возврата 0. Дословный stdout + stderr:

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
D3D12 12_0 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 3060 Ti

SHOT printing 1920x1080
PASS paused animation; Enter completes receipt without restart
SHOT victory 1920x1080
PASS second Enter emits restart_requested
SHOT death 1920x1080
PASS R / Space / keypad Enter: complete then restart
PASS button click: complete then restart
SHOT victory_1280 1280x720
SHOT victory_2560 2560x1440
SHOT long_list 2560x1440
SHOT long_list_bottom 2560x1440
PASS long lists: two columns, wrapped weapons, bounded scroll; zero child nodes
G5 TESTS PASSED
ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)

```

Визуальная проверка: победа с 4 стволами / 6 начислениями, смерть на 3:12 с 1 стволом, промежуточная печать и стандартная победа на двух дополнительных разрешениях выглядят корректно, текст не пересекается. Стандартная победа помещается без прокрутки (assert _scroll_max == 0).

Стресс-проверка 20 стволов / 22 начислений: строки не выходят за область, но на снимке после прокрутки иногда исчезают фон, заголовок, итог и кнопка. Автоматический PASS проверяет только геометрию/состояние и не исключает этот визуальный дефект. Он воспроизводился в Compatibility и Forward Plus; первоначальная гипотеза о проблеме только OpenGL не подтвердилась. Отдельный запуск Mobile дал правильный кадр. Ожидание кадра, force_draw и прекращение перерисовки готового чека не устранили дефект полностью. long_list_bottom.png оставлен как свидетельство. Требуется дальнейшая проверка этого крайнего случая при интеграции; не считаю его полностью исправленным.

Промежуточная проверка нашла лишнюю прокрутку стандартного набора:
```
SCRIPT ERROR: Assertion failed.
   at: run (res://test_results.gd:81)
   GDScript backtrace (most recent call first):
       [0] run (res://test_results.gd:81)
```
Интервалы уплотнены, повторные прогоны прошли. Первый процесс, остановившийся на assert, завершён Python по timeout=90. В финальных прогонах ошибок и предупреждений парсера нет.

Первый импорт до перенаправления APPDATA дополнительно вывел:
```
ERROR: Cannot save file 'C:/Users/Dev/AppData/Roaming/Godot/editor_settings-4.7.tres'.
   at: save (scene/resources/resource_format_text.cpp:1768)
ERROR: Error saving editor settings to C:/Users/Dev/AppData/Roaming/Godot/editor_settings-4.7.tres
   at: save (editor/settings/editor_settings.cpp:1525)
```
Перенаправление настроек внутрь SCRATCH устранило эти две ошибки. Ошибка хранилища сертификатов осталась; полностью чистый от ERROR вывод получить не удалось. Необходимые инструменты Python и Godot доступны.

## Критерии приёмки
- [x] Контракт §8, работает на паузе, мышь и клавиши.
- [x] Чек печатается построчно, пропуск допечатывает.
- [x] Ничего не вылезает за панель на 1280×720 и 2560×1440 в обязательных наборах задачи.
- [x] Без draw_circle, без дочерних нод на строки (get_child_count() == 0).
- [ ] Дополнительный крайний стресс-набор полностью корректен визуально после прокрутки: остаётся описанный выше дефект. Полную приёмку произвольных длинных списков подтвердить не могу.

## Отступления от задачи и контракта
- Панель 260×316 вместо приблизительных 260×300, чтобы показать обычный чек целиком.
- Для произвольно больших списков добавлена внутренняя прокрутка сверх уменьшения подписей и двух колонок. Подписи начислений, не помещающиеся даже при 6 px, сокращаются многоточием; строки оружия переносятся полностью.
- Изменять CONTRACTS.md не требуется. BALANCE.md задача не ссылается на конкретный раздел; расчёта начислений в экране нет. Прочитан MVP.md §10.
- Стандартные скриншоты сняты на пустом фоне тестового viewport, поверх него отрисовано полупрозрачное затемнение.

## Найденные проблемы вне задачи
- Godot в данном окружении выводит Failed to read the root certificate store, при коде возврата 0.
- Существующие исходники zera и его git-ветка не менялись. Удаление временной копии G5 не выполнено: автоматическая проверка отклонила Remove-Item -LiteralPath <проверенный абсолютный путь G5> -Recurse -Force с причиной blocked by policy. Путь: C:\Users\Dev\AppData\Local\Temp\claude\C--Users-Dev-Desktop-GameZ\c0951c8e-5403-4ca4-8a08-a7e35d3e4417\scratchpad\codex_tmp\G5. Другие способы удаления после отказа не применялись.

