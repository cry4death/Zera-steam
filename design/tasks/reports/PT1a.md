# Отчёт PT1a — узел заражения

**Исполнитель:** ChatGPT · **Ветка:** `task/pt1a` · **Коммит:** не создавался.

## Сделано
- Причина: до 10:00 рисовался `campaign_node_closed`, но `CampaignNode.start()` не вызывался: цель не жива, оружие её не видит. Отдельного тела препятствия тоже не было.
- Узел активен с начала операции. Общий протокол босса уже обслуживает все виды урона; менять оружие не потребовалось. Полоса подписана «Узел заражения».
- Круглое тело 28 px зарегистрировано в общей сетке препятствий: игрок останавливается, орда строит обход; собственное тело не перекрывает линию огня. После разрушения тело снимается, навигация обновляется.
- В окне проверены огонь АК-С, отклик попадания, убывание HP, две стадии повреждения, обрушение и экран «Операция выполнена». Для последовательности разрушения использованы четыре ствола уровня 5; HP узла вручную не менялось. Охрана отключена в стенде для изолированной проверки цели.
- GdUnit4 проверяет первую операцию на свежем профиле, настоящий выстрел всех 16 классов, взрыв, горение, коллизию/маршруты игрока и трёх размеров орды, освобождение прохода и единственную выдачу награды.
- Продолжение: исправлена очистка теста — после настоящего экрана победы восстанавливаются пауза дерева и масштаб времени. Ранее все 78 тестов заканчивались, но GdUnit4 зависал при выходе из-за оставленной паузы.
- При повторном запуске исполнителя проверены существующий diff, три референса автора, кадры до/после (огонь, стадии, победа, проход игрока, последовательность обхода орды) и исходные логи проверок. Новых дефектов PT1a не найдено; код и прогоны без изменений не дублировались. Повторный `git diff --check`: код 0, вывода нет.

## Изменённые файлы
| Файл | Что |
|---|---|
| `scripts/campaign/campaign_node.gd` | Регистрация/снятие тела, радиус, имя полосы |
| `scripts/campaign/campaign_objective.gd` | Комментарий к активации видимой цели |
| `scripts/campaign/campaign_catalog.gd` | `node_time`: 600 → 0 секунд |
| `scripts/obstacles.gd` | `add_body`/`remove_body`: packed-строки общей сетки, без дополнительного Node |
| `design/BALANCE.md` | Время доступности, прежние HP и радиус узла |
| `tests/campaign/campaign_node_test.gd` | Регрессия первой операции |
| `design/tasks/reports/PT1a*` | Отчёт, проверки и оконные кадры |

## Проверка
```text
PT1A_TEST classes=16 bullet=true explosion=true fire=true collision_player_horde=true navigation=true victory=true
Overall Summary: 1 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans |
PT1A PLAY label=before time=3.68 alive=false hp_before=24000 hp_after=24000 shots=[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
PT1A WALK label=before start=(512.0, 885.0) end=(512.0, 722.3358) node=(512.0, 800.0)
PT1A PLAY label=after time=3.70 alive=true hp_before=12000 hp_after=11874 shots=[19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
PT1A WALK label=after start=(512.0, 885.0) end=(512.0, 833.02) node=(512.0, 800.0)
PT1A VICTORY game_over=true done=true hp=0 results=true
PT1A HORDE frames=8 step=1s min_surface_distance=28.020 node_radius=28 last=(509.5384, 860.9051)
```
До запуска `start()` поле HP имело унаследованное значение 24 000, но не было боевым HP. После активации применяется прежний баланс кампании — 12 000 HP × множитель угрозы.

Повтор GdUnit4 после восстановления паузы тестом (код выхода 0):
```text
[OK  ] godot  4.7.2.stable.official.ed1daf0bf
[OK  ] gdunit  exit=0 tests=78 failed=0 skipped=0 report=D:\zera-wt\zera-pt1a\design\tasks\reports\PT1a_gdunit\gdunit\report_1
ZERA_TEST suite=gdunit checks=2 failed=0 out=design/tasks/reports/PT1a_gdunit
Overall Summary: 78 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans |
```
`powershell -NoProfile -ExecutionPolicy Bypass -File tools/test_project.ps1 -Suite full -Out design/tasks/reports/PT1a_full`, код выхода 1:
```text
[OK  ] godot  4.7.2.stable.official.ed1daf0bf
[OK  ] import  exit=0 script_errors=0
[FAIL] gdunit  exit=-1 tests=78 failed=0 skipped=0 report=D:\zera-wt\zera-pt1a\design\tasks\reports\PT1a_full\gdunit\report_1
[FAIL] --meta-test  exit=1 TESTRESULT ok=false errors=5
[OK  ] --campaign-test  exit=0 CAMPAIGNTEST ok=true
[OK  ] --q1-test --fresh-save  exit=0 Q1TEST checks=25 failed=0 ok=true
[OK  ] --fresh-save --gore-checks  exit=0 R1CHECK ok=true remains_peak=200 stamps_queue=391 particles=0
[OK  ] --obstacles-test --fresh-save  exit=0 OBSTEST ok=true penetrations=0 arrived=500 detonations=3 blood_events=2
[OK  ] --activities-test --fresh-save  exit=0 ACTIVITIESTEST checks=149 failures=0 rewards=6 ok=true
[OK  ] --sim=600 --fresh-save  exit=0 SIM 10:00 level=29 kills=3860 xp=6100/6289 credits=787/818 credits_left=437 zombies=8 kinds=8/0/0/0 armored=0/0/0 elites=0 elites_spawned=14 crates=3 nades=18 dmg_taken=1111 peak=41 fps=145 | АК-С L5 Стан1 [Рико3,Проб3] | Мясник L5 Стан1 [Рико3,Проб3] | Игла L5 Стан1 [Рико3,Проб2] | Гром L5 Стан1 [Рико3]
ZERA_TEST suite=full checks=10 failed=2 out=design/tasks/reports/PT1a_full
```
GdUnit4 остановлен после итоговой строки из-за оставленной тестом паузы, исправлен и успешно повторён отдельно (выше). Оставшийся сбой — запись меты в `user://test_save.json`: `Cannot call method 'store_string' on a null value.` в `MetaTest._write_text`; ревьюеру нужно повторить `--meta-test` вне песочницы. Логи — [PT1a_checks.log](PT1a_checks.log). `git diff --check`: код выхода 0, вывода нет. `fps=145` в headless SIM не является замером производительности.

Скриншоты (просмотрены):
- [До: огонь без цели](PT1a_node_fire_before.png), [после: попадание и HP](PT1a_node_fire_after.png).
- [Повреждение](PT1a_node_damaged_after.png), [критическое состояние](PT1a_node_critical_after.png), [останки](PT1a_node_ruined_after.png), [победа](PT1a_victory_after.png).
- Движение игрока через центр: `PT1a_walk_0..3_before.png` / `PT1a_walk_0..3_after.png` (шаг 0,5 с). После правки центр игрока останавливается в 33,02 px от узла вместо прохода насквозь.
- [Обход орды: 8 кадров с шагом 1 с](PT1a_horde_seq_after.png). Край тела не ближе 28,02 px к центру узла при радиусе узла 28 px.

## Критерии приёмки
- [x] Первая операция воспроизведена в окне, сохранены кадры до/после.
- [x] Урон всех классов оружия доходит до узла; пуля, взрыв и огонь покрыты тестом.
- [x] Видны попадания, полоса HP, стадии разрушения; уничтожение завершает операцию.
- [x] Игрок и орда не проходят сквозь узел; обход проверен маршрутами и оконной последовательностью.
- [ ] Общий `-Suite full`: `checks=10 failed=2`; GdUnit4 исправлен и повторён с `exit=0 tests=78 failed=0`, мета не проходит из-за недоступной записи в `user://`.
- [ ] Сравнение FPS до/после: обе серии по три прогона завершились `exit=1`, без строки BENCH; медиана и изменение FPS недоступны. Режим `parallel`, другие процессы Godot: до 8/8/10, после 12/12/12. Дословные строки в [PT1a_checks.log](PT1a_checks.log). Повторять шумную серию не стал.

## Отступления от задачи и контракта
- Минимально затронуты `campaign_catalog.gd` и `BALANCE.md` вне основного списка: скрытая задержка 600 секунд находилась в каталоге, её отмена нужна для доступности видимой цели. Остальные числа баланса не менялись. Изменение публичных контрактов не требуется.
- Одноразового оконного стенда в `tools/` больше нет; игровые флаги и пути сохранения не изменялись.
- Для штатного теста перезагрузки профиля создан отсутствовавший пустой каталог `tmp/test_results` (путь уже задан в существующих тестах). Исходники и путь теста не менялись; созданный тестом профиль удаляется самим тестом.
- Штатные прогоны перезаписали `b3_arc.json` и `hd1_trace_after.json`; оба восстановлены из HEAD, `git diff --quiet` для каждого вернул 0. Коммит не создавался.

## Найденные проблемы вне задачи
- Песочница запрещает запись shader cache в `user://`; оконные прогоны печатают `_save_to_cache: Condition "f.is_null()" is true.` и ошибку чтения системного хранилища сертификатов. Игровой результат отдельно подтверждён строками PT1A и кадрами.
- Очистка `PT1a_full_final/`, старого `PT1a_full_final.log` и двух кадров `PT1a_node_start_*` отклонена автоматической проверкой (`blocked by policy`, причина не уточнена); эти дубли оставлены, код и одноразовые стенды в них отсутствуют.
