# ZAI2 — ИИ орды: проверки, честный экран в headless, фризы

**Исполнитель:** Codex (gpt-6.1-sol, high) · **Ветка:** `task/zai2` · **Worktree:** `D:\zera-wt\zera-zai2`
**Основание:** аудит ZAI1 ([reviews/ZOMBIE_AI_REVIEW.md](../reviews/ZOMBIE_AI_REVIEW.md), находки С6, С9, С10, З1–З3;
рекомендации R1, R2, R6, R7). Правила — [AGENTS.md](../../../AGENTS.md). Первая задача серии ZAI: без неё
следующие нечем принимать. От ответов автора ([reports/ZAI1_questions.md](../reports/ZAI1_questions.md)) не зависит.

## Что сейчас (main)
- `--pathing-test` красный: `checks=42 failed=2`. Обе строки `PATHINGTEST row spacing=74/78` падают только на
  `queries == 0` (`game.gd`, `_run_pathing_test`, ~7378). Причина — починка 20.10 (`931f1d5`): прямой подход
  считается лучом `body_clear` у каждого агента (`horde.gd:867-877`). `--pathing-test` и `--director-test` не входят
  в `-Suite full` (`tools/test_project.ps1:125-127`), поэтому поломку никто не видел.
- Headless видит экран 64×64: `_update_view` (`game.gd:3288-3295`) и `PixelArt.view_rect` берут размер настоящего
  окна. В headless `spawn_ring`=75 (в игре 1080p — 397), `spawn_point` выбирает вход по кадру 64×64.
  `--resolution` и `root.size` в headless не помогают (проверено в облаке). Под Linux с Xvfb и
  `--rendering-driver dummy` геометрия честная. Это подтверждает, что дело только в размере окна.
- Маршруты событий режиссёра мёртвые: `horde_director.gd:375-389,453-505` строит BFS-маршруты, `horde.gd:453-462`
  их не использует. Старт «кольца» стоит 75–150 мс в основном потоке (bench `event_ms_ring`).
- Узел кампании при появлении вызывает полный `rebuild_grid()` (`campaign_node.gd:98` → `obstacles.add_body`,
  `obstacles.gd:343,362-498`). Это 1,9–7,9 с в основном потоке (bench `add_body_ms`); слои путей сбрасываются.
  `_nav_generation` растёт только в `setup()` (`obstacles.gd:939`), поэтому после взрыва машины один цикл поля
  идёт по старой геометрии.
- В облаке 1 прогон стенда из ~60 упал сразу после загрузки карты:
  `ERROR: /root: The caller thread can't call the function propagate_notification() on this node`, затем SIGSEGV
  (`--nav-thread`, residential_district, 0:00). Повтор прошёл. Похоже, фоновый поток трогает дерево сцены.

## Что сделать
1. **R1.** Добавить `--pathing-test --fresh-save` и `--director-test --fresh-save` в `-Suite full`. Ожидание
   `queries == 0` до ZAI5 заменить бюджетом: не больше одного луча на агента за 4 тика в пределах `DIRECT_RANGE`.
   Число печатать как сейчас. ZAI5 вернёт ноль. Тест должен падать, если лучи начнут пускаться каждый тик.
2. **R2.** В headless (`DisplayServer.get_name() == "headless"`) логика видит экран 1920×1080: `_update_view` и
   `PixelArt.view_rect` берут виртуальный размер. Рендер не трогать. Переснять эталоны, которые от этого
   сдвинутся (`--sim=600`, NP1/HD1-балансы в `design/BALANCE.md`), и записать в отчёт «было → стало».
   Ориентир из облака (Xvfb, бот `--sim=600`) — в [reports/zai1_data.md](../reports/zai1_data.md), раздел «облако».
3. **R6.** Удалить маршруты событий: `route`, `body_path` (если больше не нужен тестам PF1 — иначе оставить только
   там), `GroupMode`, `_group_paths`, `make_group`/`_group_direction` с путями. События строя PT1b должны работать
   как сейчас (предупреждение, окно, сбор). Тесты PT1b/HD1, которые ссылаются на режимы, поправить.
4. **R7.** `add_body`/`remove_body` перестраивают только область вокруг тела (тело + запас на радиус класса 2 +
   клетка). Слои путей не сбрасываются, поле досчитывается. `_nav_generation` растёт и в `rebuild_grid`.
5. **Падение из потока.** Найти, что из фоновой задачи поля (WorkerThreadPool, `obstacles.gd`) или другого потока
   трогает узлы. Исправить или доказать, что дело не в коде игры. Проверка — 30 запусков
   `zai1_metrics.tscn --nav-thread` подряд без падения.
6. **Постоянный стенд `--crowd-test`.** Из `tools/diag/zai1_metrics.gd` и `tools/diag/zai1_probe.gd` сделать общий
   тестовый режим. Код — в `scripts/crowd_test.gd`, вызов из `game.gd` по флагу, как `--pathing-test`.
   Сценарии: 6:00 стоит без оружия (давка); 6:00 бег кругами со стартовым оружием; старт 0:00 стоит.
   Карты: open_perimeter и old_town. Печатать строку `CROWDTEST` с метриками §7 отчёта и метриками рывков
   (`dv` в полосе 12–80 px, «выталкивание против разделения» в кольце касания). **Жёстко** в ZAI2 проверять только
   то, что верно уже сейчас: `spawn_view=0`, `stall ≤ 5 %` при движении, нет проникновений. Остальные пороги
   включат ZAI3/ZAI4.
   Добавить `--crowd-test` в `-Suite full`, укладываясь в ~3 мин на машине автора.
7. Временные стенды `tools/diag/zai1_*` после переноса удалить. `tools/diag/crowd_stall.*` не трогать.

## Можно трогать
`tools/test_project.ps1`, `scripts/game.gd` (только `_update_view`, `_run_pathing_test`, вызов `--crowd-test`),
`scripts/pixel_art.gd` (`view_rect`), `scripts/crowd_test.gd` (новый), `scripts/horde_director.gd` и
`scripts/horde.gd` (только удаление маршрутов R6), `scripts/obstacles.gd` (`add_body`/`remove_body`/`rebuild_grid`/
поколение, поток), `scripts/campaign/campaign_node.gd` (только вызов `add_body`), `tests/`, `tools/diag/zai1_*`,
`design/BALANCE.md` (эталоны sim), `design/tasks/reports/ZAI2*`, `zai2_*`. Движение и разделение не менять — это ZAI4.

## Проверки
`tools/test_project.ps1 -Suite full`: строка `ZERA_TEST … failed=0`, в ней `--pathing-test`, `--director-test`,
`--crowd-test`. Bench (`-Suite bench`) — до и после, просадка ≤5 %. Новые числа: `add_body_ms` < 30 и слои готовы
после добавления (стенд `zai1_bench.gd` или его перенос), `event_ms_ring` < 2. В headless строка
`ZAI1VIEW`/`CROWDTEST` показывает экран 640×360 мировых px и `spawn_ring≈397`.

## Скриншоты
Не нужны (логика). Если менялся `PixelArt.view_rect` — один оконный кадр 1080p, где видно, что спавн и
отсечение отрисовки не изменились: `zai2_view_window.png`.

## Отчёт
`design/tasks/reports/ZAI2.md`: что было и что стало по каждому пункту, эталоны sim до/после, вывод проверок дословно.
