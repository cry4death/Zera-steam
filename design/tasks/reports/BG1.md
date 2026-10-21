# Отчёт BG1 — диагностика NaN/inf босса

**Исполнитель:** Codex · **Ветка:** `task/bg1` · **Коммит:** не создавался.

**Статус: BG1 не закрыта. Точная причина не найдена, исправления боевого кода нет.** Данные для следующего запуска — [BG1_questions.md](BG1_questions.md).

## Сделано
- Добавлены три теста GdUnit4: совпавшая цель и нулевой таран Объекта-7/Генерала/Мясной горы; настоящий `Weapons.explode()` точно в центре всех пяти боссов; спавн через `_boss_timeline()` настоящей сцены с препятствиями четырёх карт. Последний тест проверяет пять видов боссов и четыре направления спавна (включая нулевое), затем совпавшую цель и 120 тиков физики — всего 80 спавнов и 9600 тиков. Проверяются конечные координаты/направление и нанесение урона. Все тесты проходят уже на исходной логике, поэтому воспроизведением исходного дефекта их считать нельзя.
- Выполнены семь полных `--sim=600 --fresh-save`: пять seed, включая повтор в окне и повтор в полном наборе. Все exit=0, `SCRIPT ERROR` отсутствует, позиции спавна конечны. Дополнительно оконный бой Объекта-7 до 610 и Мясной горы до 660, включая третью фазу, — exit=0.
- Временная диагностика проверяла вход `Boss.start`, результат `_bounded`/`free_point`, нечисловые входы `_move_to` и обоих аргументов расстояния HUD. Плохих значений не получено. Диагностика удалена; `scripts/boss.gd` и `scripts/hud.gd` совпадают с HEAD, исходная защита HUD сохранена.
- `Explosions` меняет только изображение; урон босса идёт через `Weapons`, без переноса его позиции. Нормализация совпавших точек и нулевой `move_toward` в проверенных атаках остаются конечными. Установить точную строку исходного сбоя этими проверками не удалось.
- При продолжении задачи проверены также сохранённые журналы `app_userdata/Zera/logs`: первоначального исключения там нет. Повторён полный набор; его итог ниже.

## Изменённые файлы
| Файл | Что |
|---|---|
| `tests/boss/boss_finite_test.gd` | Три теста граничных случаев и спавна с настоящими препятствиями |
| `design/tasks/reports/BG1.md`, `BG1_questions.md` | Результат и недостающие данные |
| `design/tasks/reports/BG1_checks.log` | Сводный вывод проверок и диагностики |
| `design/tasks/reports/BG1_before_phase1.png` | Настоящий viewport Объекта-7 до изменений |

## Проверка
Команды: `tools/test_project.ps1 -Suite full -Out tmp/test_results/BG1_resume_full`; отдельный GdUnit4 по `res://tests/boss/boss_finite_test.gd` штатной командой из TOOLING.md; симуляции штатным Godot CLI. Подробные строки спавна/итогов — [BG1_checks.log](BG1_checks.log). Полные логи набора — `tmp/test_results/BG1_resume_full/`, финальных трёх тестов босса — `tmp/test_results/BG1_scene_final/`. В полном наборе GdUnit4 прошёл до добавления третьего теста; обновлённый файл отдельно проверен после последней правки.

| Полный SIM 600 | Режим | Exit | SCRIPT ERROR |
|---|---|---:|---:|
| seed 81073 | headless | 0 | 0 |
| seed 81074 | headless | 0 | 0 |
| seed 81073 | окно, `--fixed-fps 60` | 0 | 0 |
| seed 81075 | headless, `--fixed-fps 60` | 0 | 0 |
| seed 81076 | headless, `--fixed-fps 60` | 0 | 0 |
| seed 81077 | headless, `--fixed-fps 60` | 0 | 0 |
| seed 81073 | headless, полный набор при продолжении задачи | 0 | 0 |

Все — карта `quarantine_checkpoint`; дополнительные симуляции направляли trace в отдельные `res://tmp/BG1_*.json`. Первый обычный прогон использовал штатный путь trace; перезаписанные проверками чужие отчёты восстановлены из HEAD.

```text
[OK  ] godot  4.7.2.stable.official.ed1daf0bf
[OK  ] import  exit=0 script_errors=0
[OK  ] gdunit  exit=0 tests=42 failed=0 skipped=0 report=C:\Users\Dev\Desktop\zera-bg1\tmp\test_results\BG1_resume_full\gdunit\report_1
[FAIL] --meta-test  exit=1 TESTRESULT ok=false errors=5
[OK  ] --campaign-test  exit=0 CAMPAIGNTEST ok=true
[OK  ] --q1-test --fresh-save  exit=0 Q1TEST checks=25 failed=0 ok=true
[OK  ] --fresh-save --gore-checks  exit=0 R1CHECK ok=true remains_peak=200 stamps_queue=443 particles=0
[OK  ] --obstacles-test --fresh-save  exit=0 OBSTEST ok=true penetrations=0 arrived=500 detonations=3 blood_events=2
[OK  ] --activities-test --fresh-save  exit=0 ACTIVITIESTEST checks=149 failures=0 rewards=6 ok=true
[OK  ] --sim=600 --fresh-save  exit=0 SIM 10:00 level=21 kills=3846 xp=2740/6482 credits=300/890 credits_left=10 zombies=15 kinds=15/0/0/0 armored=0/0/0 elites=0 elites_spawned=14 crates=0 nades=12 dmg_taken=394 peak=30 fps=145 | АК-С L5 Стан1 [Рико3] | Мясник L5 Стан1 [Рико3] | Игла L5 Стан1 [Рико3] | Гром L5 Стан1 []
ZERA_TEST suite=full checks=10 failed=1 out=tmp/test_results/BG1_resume_full
```

Финальный отдельный GdUnit4: `Overall Summary: 3 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans |`, `Exit code: 0`.

Скриншот «до»: [BG1_before_phase1.png](BG1_before_phase1.png), просмотрен. «После» и сравнительный FPS не снимались: исправления игровой логики/отрисовки нет. Окна запускались через общую блокировку, `mode=parallel`; FPS шумный, производительность не оценивалась. Баланс и сохранения не менялись.

## Критерии приёмки
- [ ] Найдена точная строка появления NaN/inf: не воспроизведено, нужны исходные команда и полный стек.
- [ ] Исправлена причина во всех боссах с той же схемой: без установленной причины предположительных изменений не внесено.
- [x] Есть тесты совпавшей цели, нулевого рывка и взрыва в центре босса.
- [x] Не менее пяти полных `--sim=600 --fresh-save` без `SCRIPT ERROR`: семь отдельных прогонов.
- [x] Защита HUD оставлена.
- [ ] `ZERA_TEST suite=full … failed=0`: `--meta-test` падает из-за недоступной записи `user://test_save.json`.

## Отступления от задачи и контракта
- Задача оставлена открытой; утверждение о NaN именно у босса не подтверждено. `INT_MIN` от расстояния не определяет, какой из двух аргументов был нечисловым. Исходное исключение не найдено в доступных логах main.
- Для оконной диагностики временно создавался `override.cfg`, отключавший shader cache и pipeline cache: без этого тестовый логгер прекращал запуск на ошибках записи кэша в `user://`. Временный файл и диагностические вставки HUD/босса удалены; новых флагов и подмен путей в игровых скриптах нет.
- CONTRACTS.md менять не требуется. Временных копий проекта и коммитов нет.
- Генерируемые проверками `b3_arc.json` и `hd1_trace_after.json` восстановлены из HEAD; изменений вне разрешённых файлов не осталось.
- Автоматическая проверка отклонила очистку `tmp/test_results/BG1_scene` и `BG1_scene.log`: `blocked by policy`. Дубли промежуточной проверки оставлены в игнорируемом `tmp/`; запрет не обходился.

## Найденные проблемы вне задачи
- `--meta-test`: запись `user://test_save.json` запрещена песочницей; `_write_text` затем вызывает `store_string` у null. В логе пять `SCRIPT ERROR`, источник — `scripts/meta_test.gd:92`, а не босс. Исходники/пути теста не менялись; нужен повтор у ревьюера с доступом к штатному каталогу.
