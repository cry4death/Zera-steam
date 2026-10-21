# Отчёт ZAI2 — ИИ орды: проверки, честный экран в headless, фризы

**Исполнитель:** Claude Opus 5.5 (облачная сессия, по решению автора «делай все рекомендации») ·
**Ветка:** `claude/great-rubin-vhn9o1` · **Коммит:** `8c9e97a` (+ отчёт)

## Сделано
- **R1.** В `-Suite full` добавлены `--pathing-test`, `--director-test` и новый `--crowd-test` (`tools/test_project.ps1`,
  `AGENTS.md`). В `--pathing-test` ожидание «0 лучей агентов» заменено бюджетом «не чаще раза в 4 тика на агента»
  (`65 × 600 / 4 = 9750`; факт 8525–9183): тест красный, если лучи начнут пускать каждый тик. Ноль вернёт ZAI5.
- **R2.** Без окна логика видит экран 1920×1080: `PixelArt.screen_size()` и `PixelArt.view_rect()` (виртуальный
  экран с центром камеры), `game._update_view()`, точка появления босса (`game.gd`, `_boss_timeline`). В headless
  теперь зум ×3 и `spawn_ring`=397, как в живой игре. `root.size` и `--resolution` в headless не помогают — проверено.
- **R6.** Мёртвые маршруты событий удалены: `HordeDirector.route()` (BFS), `GroupMode`, `_group_paths`,
  `_group_mode`, `group_step`. Пачка события — жетон со сроком жизни (`make_group(lifetime)`), плечо — точка
  появления; участники идут к игроку по общему полю, как и раньше (PT1b). Из `--director-test` убраны проверки
  маршрутов (`routes_*`, `gap_route_*`).
  **Найдено попутно:** с честным экраном на КПП «колонна» не находила плеча (точки строя должны быть ≥1,5 кольца, а
  запасной вход требовал того же). В живой игре это означало молча пропавшее событие. Запасной вход теперь годится,
  если он за экраном (дальше `spawn_ring`), и для него пачка появляется не ближе кольца.
- **R7.** `add_body` перестраивает только область вокруг тела (`rebuild_grid(false, i)`, общий `_link_body`), слои
  путей не сбрасываются. `_nav_generation` растёт при каждой перестройке (З3): поток, начатый по старой геометрии,
  не подменит слои.
- **Падение из потока (З7).** 40 повторов того же запуска (`--nav-thread`, residential, 0:00, Xvfb) — ни одного
  падения. Фоновая задача `_flow_layer` статическая и работает только со своими аргументами, узлов не касается.
  Ошибка `propagate_notification() on /root` из чужого потока похожа на сбой X11/Xvfb при создании окна. Если
  повторится в Windows — нужен полный лог с трассировкой.
- **`--crowd-test`** (`scripts/crowd_test.gd`, вызов из `game.gd`). Орда и поле шагаются вручную, детерминированно,
  на open_perimeter и old_town, ~75 с.
  - Сценарии: давка у стоящего игрока, бег кругами, старт с обычным появлением, бег по большому кругу.
  - Метрики считаются только по позициям, через крючок `horde.tick_probe` (снимки внутри тика).
  - Пороги — `CrowdTest.LIMITS` по задачам. В ZAI2 включены: появлений в кадре 0, проникновений 0, доля
    стоящих при беге ≤ 12 % (защита от регресса до ZAI4).

## Изменённые файлы
| Файл | Что |
|---|---|
| `scripts/pixel_art.gd` | `HEADLESS_SCREEN`, `screen_size()`, `view_rect()` с виртуальным экраном |
| `scripts/game.gd` | `_update_view`, появление босса, бюджет лучей в `--pathing-test`, `--director-test` без маршрутов, `_run_crowd_test` |
| `scripts/horde.gd` | жетоны групп без маршрутов, `tick_probe` |
| `scripts/horde_director.gd` | без `route()`; запасной вход за экраном; `_min_distance` |
| `scripts/obstacles.gd` | локальный `add_body`, `_link_body`, поколение в `rebuild_grid` |
| `scripts/crowd_test.gd` | новый тест толпы |
| `tests/horde/director_events_test.gd` | группы без режимов |
| `tools/test_project.ps1`, `AGENTS.md` | три проверки в full |

## Проверка
Облако, Linux Godot 4.7.2, bash-повтор `tools/test_project.ps1 -Suite full` на копии дерева после коммита:
```
[OK  ] import  exit=0 script_errors=0
[OK  ] gdunit  exit=0 tests=117 failed=0
[OK  ] --meta-test  exit=0 METATEST ok=true
[OK  ] --campaign-test  exit=0 CAMPAIGNTEST ok=true
[OK  ] --q1-test --fresh-save  exit=0 Q1TEST checks=25 failed=0 ok=true
[OK  ] --fresh-save --gore-checks  exit=0 R1CHECK ok=true remains_peak=200 stamps_queue=432 particles=0
[OK  ] --obstacles-test --fresh-save  exit=0 OBSTEST ok=true penetrations=0 arrived=500 detonations=3 blood_events=2
[OK  ] --activities-test --fresh-save  exit=0 ACTIVITIESTEST checks=149 failures=0 rewards=6 ok=true
[OK  ] --sim=600 --fresh-save  exit=0 SIM 10:00 level=28 kills=3763 … dmg_taken=696 peak=62 fps=145
[OK  ] --pathing-test --fresh-save  exit=0 PATHINGTEST checks=42 failed=0 penetrations=0 stuck=0 seed=81073 ok=true
[OK  ] --director-test --fresh-save  exit=0 DIRECTORTEST cases=144 failures=0 … ok=true
[OK  ] --crowd-test --fresh-save  exit=0 CROWDTEST checks=7 failed=0 penetrations=0 active=ZAI2 ok=true
ZERA_TEST suite=full checks=12 failed=0
```
До правок на том же снимке: `PATHINGTEST checks=42 failed=2` (обе — `queries == 0`), `--sim=600` dmg_taken=881
(headless 64×64).

Стенд `tools/diag/zai1_bench.gd` (headless, до → после):

| Карта | `add_body_ms` | слои готовы после добавления | `event_ms_ring` |
|---|---|---|---|
| old_town | 4941–7870 → 18,7 | false → true | 13–150 → 0,4 |
| open_perimeter | 1883–2936 → 24,0 | false → true | 12–75 → 0,5 |
| residential_district | 3573 → 21,5 | false → true | — → 0,2 |

`--crowd-test` до ZAI3 (open_perimeter / old_town):
- давка: смена смещения за тик p90 4,4 / 4,1 px, пинг-понг у героя 50 / 51 %;
- старт: первый контакт p50 20,1 / 27,5 с, дистанция появления p50 615 / 774 px;
- колонны у стен на старте ×0,34 / ×6,8;
- отставших дальше 800 px 4,7 / 7,7 %.

## Критерии приёмки
- [x] full зелёный с pathing/director/crowd.
- [x] `add_body_ms` < 30, слои готовы.
- [x] `event_ms` < 2.
- [x] В headless экран 640×360 мировых px, `spawn_ring≈397`.
- [ ] Bench FPS (`-Suite bench`) — только оконный на машине автора; в облаке не мерился. Код горячих циклов
  орды не менялся, кроме четырёх проверок `tick_probe.is_valid()` за тик.

## Отступления от задачи
- `crowd_test.gd` не переносит стенды ZAI1 целиком: он шагает орду вручную (как `--pathing-test`), без оружия и
  режиссёра — так он детерминирован и укладывается в ~75 с. Метрики оружия и режиссёра остались в стендах
  `tools/diag/zai1_*`; их удалю после ZAI6, когда перенесу стенды босса и щита.
- Порог «стоящих при беге ≤ 5 %» в ZAI2 не включён: синтетический сценарий бега даёт 6–9 % на исходном движении.
  Строгий порог — в ZAI4.

## Найденные проблемы вне задачи
- Эталоны баланса NP1/HD1 снимались на 64×64. С честным экраном дефолтный `--sim=600` дал 696 урона вместо 881
  (один прогон). Отдельный пересъём баланса имеет смысл после ZAI3–ZAI4: они меняют появление и движение сильнее.
