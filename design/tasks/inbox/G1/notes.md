# Отчёт G1 — плевки, кислотные лужи и взрывы толстяков

**Исполнитель:** ChatGPT · **Ветка/файл:** `inbox/G1/hazards.gd` · **Коммит:** не создавался

## Сделано
- Прочитаны полностью `tasks/README.md`, `tasks/CONTRACTS.md`, `tasks/M4/G1_hazards.md` и шаблон отчёта; проверены числа в `BALANCE.md`. Файла `tasks/reviews/G1.md` на момент начала работы не было.
- Сверены реальные Player, Horde, WeaponDefs, FloorDecals, Effects, GameCamera, PixelArt и соглашения арта из `tools/gen_art.py`. В zera ничего не записывалось; команды git не запускались. BOARD.md не изменялся.
- Реализован самостоятельный Hazards с точными публичными именами и сигнатурами контракта. Снаряды, лужи, очередь взрывов и вспышки хранятся в заранее выделенных Packed-массивах; удаление активных сущностей — swap-remove.
- Плевок летит со скоростью 140; при попадании исчезает без лужи, по прибытии создаёт лужу. Есть тень, хвост, пульсация, брызги и необязательные кадры арта с частотой 12 кадров/с.
- Лужи имеют фиксированный силуэт из семи пятен, подсветку, пузыри, затухание за 0.8 с и один постоянный след на полу. Общий таймер игрока даёт тики с интервалом 0.5 с; пересечения не суммируют урон. При лимите 64 удаляется именно старейшая лужа, включая случаи после swap-remove.
- Взрывы обрабатываются FIFO, не больше восьми за кадр. Снимок очереди берётся до любых вызовов урона в этом кадре: новые цепные взрывы ждут следующего кадра. Реализованы радиус, элитные множители, рост урона игроку по минутам, затухание урона зомби, отброс, explosive=true, частицы, кровавые декали, мокрота, кольцо, дым и тряска камеры.
- Все зависимости допускают null. clear() очищает снаряды, лужи, очередь, вспышки и таймеры; учтён синхронный clear() из обработчика урона.

## Изменённые файлы

| Файл | Что |
|---|---|
| `inbox/G1/hazards.gd` | Единственный игровой файл для переноса в `zera/scripts/` |
| `inbox/G1/validate_hazards.gd` | Дополнительный воспроизводимый прогон; перенос в игру не нужен |
| `inbox/G1/import.log` | Полный вывод заключительного импорта |
| `inbox/G1/parser.log` | Полный вывод явной проверки компиляции Hazards |
| `inbox/G1/validation.log` | Полный вывод поведенческих и интеграционных проверок |
| `inbox/G1/notes.md` | Этот отчёт |

Существующий `inbox/G1/README.md` не изменялся.

## Проверка

Создана временная копия `C:\Users\Dev\AppData\Local\Temp\Zera_G1_1792215089946` через robocopy /E /XD .git .godot /XF .git. В неё скопированы hazards.gd в scripts/ и validate_hazards.gd в корень. В исходном проекте Godot не запускался. Ниже — дословный вывод заключительных успешных запусков; полные логи также лежат рядом.

1. Обязательный импорт. Exit code: 0.

```
& "C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path "C:\Users\Dev\AppData\Local\Temp\Zera_G1_1792215089946" --import
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started Инициализация проекта (5 steps)
[   0% ] first_scan_filesystem | Сканирование структуры файлов…
[  16% ] first_scan_filesystem | Загрузка глобальных имен классов…
[  33% ] first_scan_filesystem | Проверка GDExtensions…
[  50% ] first_scan_filesystem | Создание скриптов автозагрузки…
[  66% ] first_scan_filesystem | Инициализация плагинов…
[  83% ] first_scan_filesystem | Начало сканирование файлов…
[ DONE ] first_scan_filesystem

[   0% ] update_scripts_classes | Started Регистрация глобальных классов… (2 steps)
[   0% ] update_scripts_classes | Hazards
[  33% ] update_scripts_classes | 
[ DONE ] update_scripts_classes

[   0% ] loading_editor_layout | Started Загрузка редактора (5 steps)
[   0% ] loading_editor_layout | Загрузка макета редактора…
[  16% ] loading_editor_layout | Загрузка док-панели…
[ DONE ] loading_editor_layout
```

2. Явная проверка компиляции самостоятельного скрипта. Exit code: 0.

```
& "C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path "C:\Users\Dev\AppData\Local\Temp\Zera_G1_1792215089946" --check-only --script res://scripts/hazards.gd
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
```

3. Проверки поведения, совместимости и нагрузки. Exit code: 0.

```
& "C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path "C:\Users\Dev\AppData\Local\Temp\Zera_G1_1792215089946" --quit-after 120 --script res://validate_hazards.gd
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

PASS: initial counts
PASS: spit speed 140
PASS: arrival creates pool at target, null dependencies
PASS: zero-length spit
PASS: swept collision: hit removes spit without pool
PASS: player beyond target is not hit
PASS: overlap: two accepted ticks per second, total 5 damage
PASS: overlap selects maximum DPS
PASS: default pool: 3 seconds, six ticks, 15 damage, expires
PASS: exit and re-entry do not reset acid cooldown
PASS: dead player takes no acid damage
PASS: 64-pool limit removes oldest after swap-remove
PASS: pool silhouette remains fixed
PASS: invalid pool dimensions are ignored
PASS: explosions are queued
PASS: maximum eight explosions per frame
PASS: remaining explosions execute next frame
PASS: flash expires after 0.25 seconds
PASS: synchronous chain is deferred to next frame
PASS: blast center: damage, random unit direction, knockback, explosive flag
PASS: dead zombies are skipped
PASS: blast edge falloff includes Horde.RADIUS
PASS: normal blast radius 48
PASS: elite blast radius 72 and scaled player damage 58.5 at minute 10
PASS: acid stamps floor once
PASS: blast emits radial blood, 20-30 pus, 8-10 baked drops
PASS: blast stamps 2-3 blood pools and wet area
PASS: camera shake 4 within 150
PASS: camera shake attenuates to 2 at 225
PASS: no camera shake beyond 300
PASS: queue grows beyond reserve without dropping explosions
PASS: wrapped FIFO preserves order during growth
PASS: spit buffer grows without dropping projectiles
PASS: clear resets all transient state
BENCH: 120 physics steps, 40 spits, 64 pools, 8 blasts/step, 500 zombies (test double); average_us=1159.75833333333; worst_us=1703
PASS: peak workload keeps counts stable
PASS: integration with actual Horde, Player damage, Effects, FloorDecals, GameCamera
PASS: fallback draw callback completed
PASS: optional texture draw callback completed (synthetic texture, G3 art absent)
RESULT: failures=0
```

Все 38 проверок завершились успешно; в окончательных логах нет ERROR, SCRIPT ERROR, WARNING или FAIL. Нагрузочные цифры относятся только к синхронному шагу Hazards с тестовой ордой, без рендеринга, настоящей симуляции движения, декалей и частиц; это не измерение FPS игры. Отдельный интеграционный прогон использует настоящие компоненты проекта. Отрисовка fallback и ветка необязательной текстуры прошли без ошибок; для последней подставлялась синтетическая текстура, а не отсутствующий арт G3. Скриншоты для G1 не делались.

При первом запуске самостоятельного скрипта найдена ошибка вывода типа выражения с floor(); исправлена на floorf(). Первые варианты тестовой обвязки также исправлены: добавлен требуемый Player узел Sprite и скрыта тестовая Horde, у которой намеренно не инициализируются массивы рендера. Приведены результаты после этих исправлений.

Контроль результата и уборка:

```
SHA256: 46748AE2EDB996C80F93508A83BAA06378A4B88555DB974BE8E4111554420000
CHECK: tested file equals inbox; tabs only; no draw_circle; no errors or warnings in final logs
CLEANUP: removed C:\Users\Dev\AppData\Local\Temp\Zera_G1_1792215089946
```

Проверенный hazards.gd совпадал по SHA256 с файлом в inbox. Временная копия удалена полностью; отсутствие папки проверено через Test-Path. Скрытый .editorconfig в копии перед обычным удалением получил атрибут Normal.

## Критерии приёмки
- [x] «Контракт (строго эти имена и сигнатуры)»: все пять зависимостей, minutes и шесть публичных методов присутствуют.
- [x] «GDScript со статической типизацией», табы, краткие русские комментарии и документирующий комментарий класса; явная компиляция успешна.
- [x] «Массовые сущности ... в Packed-массивах», «Удаление — swap-remove», без нод на сущность.
- [x] «Нельзя draw_circle»: круглые пятна через PixelArt.draw_dot; кольцо через draw_arc.
- [x] «Плевок ... со скоростью 140»: скорость, попадание без лужи, прибытие с лужей, частицы и необязательный арт.
- [x] «Лужа ... последние 0.8 с плавно исчезает»: срок жизни, фиксированная форма, пузыри и след на полу.
- [x] «Таймер тика — общий для игрока»: не более одного тика за 0.5 с даже при наложении и повторном входе; зомби кислота не ранит.
- [x] «Лимит 64 луж: ... удаляется самая старая»: проверено после перестановки последней на место удалённой.
- [x] «Вызов не взрывает сразу», «не больше 8 взрывов за кадр», новый цепной взрыв ждёт следующего кадра.
- [x] Радиусы 48/72, урон игроку и элитные множители, формула затухания для зомби, проверка dead и explosive=true.
- [x] Мясо, гной, крупные запекаемые капли, 2–3 кровавых пятна, mark_wet, вспышка и дистанционная тряска.
- [x] «Любые ссылки ... могут быть null»: прогон с пустыми зависимостями успешен.
- [x] Пауза наследуется от обычного process_mode Node2D, отдельного обхода паузы нет.
- [x] 40 плевков, 64 лужи, 8 взрывов за шаг и 500 зомби проверены. При этой нагрузке внутренние Packed-буферы Hazards не растут; query_radius и внутренние аллокации вызванных API — вне управления Hazards.
- [x] Обязательный импорт выполнен во временной копии без .git/.godot; копия после проверки удалена.

## Отступления от задачи и контракта
- Проверка попадания плевка охватывает отрезок движения за кадр, а не только конечную точку. Это предотвращает пролёт сквозь игрока при длинном шаге; отрезок ограничен целью, поэтому игрок за точкой to не поражается.
- Первый тик кислоты при доступном общем таймере происходит сразу при нахождении в луже, затем каждые 0.5 с. Это сохраняет 15 суммарного урона за стандартную трёхсекундную лужу. После выхода таймер не сбрасывается; при пересечении разных dps берётся максимальный.
- В ТЗ указаны одновременно 60 px арта, ART_SCALE=1/3 и радиус 20. При таком масштабе 60 px дают диаметр 20, то есть радиус 10. Текстура подгоняется под фактический диаметр 2*radius (для radius=20 итоговый масштаб 2/3), чтобы видимая лужа соответствовала опасной области. Исходный ART_SCALE используется в формуле. Правка CONTRACTS.md не требуется: численный радиус сохранён.
- Вспышки имеют резерв 128 одновременных визуальных эффектов (достаточно для 8/кадр, 0.25 с при штатных 60 Гц); сверх него заменяется старейшая вспышка, логический взрыв и урон не теряются.
- Резерв — 64 плевка и 2048 ожидающих взрывов. Сверх резерва Packed-буферы удваиваются при добавлении, чтобы не терять события; обычные циклы обновления не создают временных массивов, кроме разрешённого query_radius. Неограниченное переполнение может потребовать аллокации при расширении — это явно оговорённое поведение вне заданного пика.
- queue_redraw() вызывается только при наличии визуальных сущностей либо один раз для удаления последних команд рисования после исчезновения/clear(). Без последнего пустого перерисовывания старый кадр остался бы на экране.

## Найденные проблемы вне задачи
- На момент снятия копии в Horde ещё нет контракта S1: Kind/KINDS, массивов kind/elite, новых сигнатур spawn/spawn_group и сигналов enemy_died/spit_fired/fat_burst. Hazards не обращается к отсутствующим членам; ошибок компиляции по S1 нет. Подключение spit_fired к spit и fat_burst к fat_explosion выполняет S2 после S1.
- Арт spit_0..2 и acid_0..2 пока отсутствует в исходном проекте. Работает процедурный fallback; окончательный вид с PNG G3 не проверен.
- Дополнительных API для выполнения G1 не потребовалось. Новых требований к контракту нет.

