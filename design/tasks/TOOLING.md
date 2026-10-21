# Инструменты проверки: test_project.ps1, GdUnit4, Godot Editor MCP

Единственный источник правил по этим инструментам. AGENTS.md и CLAUDE.md только ссылаются сюда.

## Версии (закреплены 2026-10-20)

| Компонент | Версия | Где | Лицензия |
|---|---|---|---|
| Godot | 4.7.2.stable (`ed1daf0bf`) | `Desktop\Godot_v4.7.2-stable_win64.exe\` | MIT. **Не обновлять без разрешения автора** |
| GdUnit4 | 6.2.2 (тег `v6.2.2`, стабильный) | `addons/gdUnit4/` | MIT (`addons/gdUnit4/LICENSE`) |
| Godot Editor MCP, сервер | `godot-editor-mcp==2026.10.15` (PyPI), contract 1 | запускается `uvx` | MIT |
| Godot Editor MCP, addon | 2026.10.15 (`godot_mcp_addon.zip` из релиза) | `addons/godot_mcp/` | MIT |
| Skills MCP | тег `2026.10.15`, папка `skills/` | `.claude/skills/godot-*` | MIT |
| uv / uvx | 0.13.3 (`python -m pip install uv`) | Python 3.12 `Scripts\` | MIT/Apache-2.0 |

Совместимость GdUnit4 6.2.x официально заявлена до Godot 4.7.1; на 4.7.2 проверена прогоном этого проекта
(загрузка плагина при импорте, 40 тестов, коды выхода). Обновлять addon’ы — отдельной задачей: заменить папку целиком
из официального релиза, обновить эту таблицу и прогнать `-Suite full`.

## Проверка перед сдачей — одна команда для Opus и Codex

Из корня своего worktree:

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test_project.ps1 -Suite full
```

| Набор | Что | Когда |
|---|---|---|
| `fast` (по умолчанию) | импорт, GdUnit4, `--meta-test`, `--gore-checks` | во время итераций (~2 мин) |
| `full` | импорт, GdUnit4, все проверки из AGENTS.md «Проверки перед сдачей» | перед сдачей (~12 мин) |
| `gdunit` | импорт и только GdUnit4 | пишете или правите тесты |
| `bench` | `--loadout --bench=500 --fresh-save` ×3 через общую блокировку, медиана `avg_fps` | задача меняет производительность |

Все наборы, кроме `bench`, headless: окно не открывается, блокировка не нужна. Ключи: `-SkipImport`, `-Godot <exe>`
(или `ZERA_GODOT`), `-Out <папка>`, `-TimeoutSec`. Код выхода 0 — всё прошло; 1 — хоть одна проверка упала;
2 — нет Godot или не та версия.

Скрипт считает провалом: ненулевой код любой проверки, ошибки разбора при импорте, отсутствие `results.xml`
(тесты не запустились), 0 найденных тестов, любой failed/error/skipped тест. Если проверки изменили файлы под
git, печатается `WARN …` (известно: `--sim=600` перезаписывает `design/tasks/reports/hd1_trace_after.json`; такой
файл не коммитить).

**Доказательство в отчёте:** итоговая строка `ZERA_TEST suite=full checks=… failed=…` и строки `[OK]/[FAIL]`
дословно; логи и отчёт GdUnit4 лежат в `tmp/test_results/<время>/` (не в git) — в отчёт задачи их не копировать.

## GdUnit4 — юнит-тесты логики

- Тесты — `tests/<система>/<имя>_test.gd`, `extends GdUnitTestSuite`. Штатные `--*-test` флаги игры остаются для
  сцен, интеграции и баланса; GdUnit4 их дополняет, а не заменяет.
- Нужны, когда задача меняет чистую логику, которую можно вызвать без сцены: правила кампании
  (`CampaignRules`, `CampaignDirector`, `CampaignWar`), данные и формулы оружия (`WeaponDefs`), миграции и проверку
  сохранений. Новое правило или исправленный баг в такой логике — новый тест.
- Тест проверяет требование из `design/*.md` или контракта, а не пересказывает код. Сиды фиксированы, без `randomize()`,
  ожиданий по времени, окон и ввода (прогон headless, InputEvent не доходит).
- Профиль игрока: скрипт запускает GdUnit4 с `-- --save-file=res://tmp/test_results/gdunit_profile.json`. Без этого
  автозагрузка `Meta` читает и может переписать настоящий `user://zera_save.json`, а с `--fresh-save` её тестовый
  логгер завершает процесс на первой ошибке посреди прогона.
- Один файл без скрипта (для итераций):
  `<godot_console> --headless --path . -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -c -a res://tests/<путь>_test.gd -rd tmp/test_results/one -- --save-file=res://tmp/test_results/gdunit_profile.json`
- Коды GdUnit4: 0 — успех (и «тестов не найдено»!), 100 — провалы, 101 — предупреждения, 103 — headless без флага,
  105 — ошибки скриптов при поиске тестов. Строки `ERROR: The remote port number…` и `Remote Debugger: Unable to connect`
  — штатный приём GdUnit4 против интерактивного отладчика, не ошибка.
- Известное исключение в тестах: `KNOWN_DPS_DROPS` в `tests/weapons/weapon_defs_test.gd` (Гарпун L3). Убрать вместе с
  правкой баланса.

## Godot Editor MCP — живой редактор (только Opus)

**Владелец.** Сервер `godot` зарегистрирован в Claude Code со scope `local` только для `Desktop\zera` (запись в
`~/.claude.json`, не в git). Его видят сессии Claude в рабочей копии Opus; исполнители Codex его не получают и работают
файлами и CLI. Другому агенту MCP выдаёт только Opus, явно в задаче, и на это время Opus сам редактор не трогает.

**Один редактор — один мост.** Сервер слушает `ws://127.0.0.1:9080` (только loopback) и держит одно подключение
редактора. Мост закрыт токеном `GODOT_MCP_BRIDGE_TOKEN` (`%LOCALAPPDATA%\zera\godot_mcp_bridge.token`): addon включён в
`project.godot`, поэтому каждый `--import` в любом worktree стучится в мост, и без токена такой процесс вытеснил бы
редактор Opus. Транспорт — stdio, HTTP не включать.

**Когда MCP, а когда файлы и CLI.**
- MCP: посмотреть дерево открытой сцены и свойства узлов как их видит редактор, ошибки редактора, короткий
  плейтест сцены с чтением свойств и скриншотом, проверить правку сцены, которую трудно оценить по `.tscn`.
- Файлы и CLI (по умолчанию): чтение кода, правки скриптов, тесты, замеры — всё, что можно сделать без редактора.
  Проверки сдачи — только `tools/test_project.ps1`, не через MCP.

**Порядок работы.**
1. Один раз на машине: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/godot_mcp_setup.ps1`, затем
   перезапустить сессию Claude Code.
2. Открыть редактор: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/godot_editor.ps1 [-Project <worktree>]`
   в фоне. Скрипт ждёт общую блокировку, держит её, пока редактор открыт, и снимает при закрытии. Открывать
   редактор на том worktree, чьи файлы смотрите; чужой worktree исполнителя во время его работы не открывать.
3. В сессии: `godot_health_check` → `bridge_connected: true`, `godot_get_server_info` → версия 2026.10.15.
4. Закрыть редактор, как только он не нужен: пока он открыт, оконные тесты и замеры исполнителей стоят в очереди.

**Toolsets.** По умолчанию включены `core` (всегда) и `inspection` — только чтение. Приложение Claude Code не
обновляет список инструментов после `godot_enable_toolset`, поэтому набор задаётся при регистрации и действует с
новой сессии: `tools/godot_mcp_setup.ps1 -Toolsets <список>` и перезапуск сессии; после работы вернуть набор по
умолчанию (`tools/godot_mcp_setup.ps1`). Набор `all` не включать.

| Нужно | `-Toolsets` |
|---|---|
| смотреть сцены и узлы (по умолчанию) | `inspection` |
| + ошибки разбора и чтение скриптов в редакторе | `inspection,scripts` |
| + короткий запуск сцены (пишет профиль автора, см. ниже) | `inspection,runtime` |
| правка сцены в редакторе | `inspection,scene_edit,scripts` |
| + скриншот редактора | добавить `editor` |

**Безопасность.**
- Правки через MCP подчиняются тем же правилам, что правки Codex: только файлы из «Можно трогать», контракты
  из CONTRACTS.md, проверка `test_project.ps1`, коммит ревьюером. Сохранённая сцена — обычный diff в git.
- Изменяющие инструменты — сначала `dry_run=true`, потом вызов. Разрушающие (`delete_*`, `close/reload_scene`,
  `set_setting`, автозагрузки, шины, ввод) требуют `confirm=true` и в `.claude/settings.json` стоят в `ask` —
  Claude Code спросит автора. Только чтение (`inspection`, `health_check`, `get_server_info`, чтение runtime) разрешено
  без вопросов.
- `godot_runtime_run_and_capture`, `godot_runtime_play_scene` и `godot_debug_workflow` запускают игру без аргументов,
  то есть с настоящим профилем автора: проверено 2026-10-20 — 8 с headless-запуска `base.tscn` пересохранили
  `user://zera_save.json` (как обычный запуск игры). Поэтому они в `ask`, и включать их — только когда без живого
  запуска не обойтись, коротко (`timeout_seconds` ≤ 10). Всё остальное — CLI с `--fresh-save`.
- Пробные изменения — во временной сцене `res://tmp/…`, удалять после проверки. Игровые сцены ради проверки MCP не
  трогать.

**Проверено 2026-10-20** (редактор на worktree `chore/godot-tooling`): `bridge_connected: true`, addon и сервер
2026.10.15; проект Zera, главная сцена `res://scenes/base.tscn`, корень `Base` (Control, `base.gd`); ошибки разбора
`game.gd`/`base.gd` — нет; правки во временной сцене с `dry_run`, отказ `close_scene` без `confirm`; headless
`--import` без токена во время сессии отклонён мостом, редактор остался подключён; в логе редактора ошибок нет.

**Неисправности.**
- Редактор не стартует, скрипт молчит после `lock=taken` — Windows SmartScreen ждёт решения по exe Godot (так было
  со `Start-Process`; скрипт запускает Godot напрямую через CreateProcess). Закрыть окно SmartScreen, повторить.
- `bridge_connected: false` — редактор не открыт, открыт без `tools/godot_editor.ps1` (нет токена) или открыт другой
  редактор. Нижняя панель «MCP» в редакторе показывает причину. Закрыть лишние редакторы, открыть через скрипт.
- `bridge_bind_error` — порт 9080 занят другим сервером: открыта вторая сессия Claude с MCP. Закрыть её.
- Сервер `godot` не подключён в `/mcp` — `claude mcp get godot`; первый запуск `uvx` скачивает пакет (до минуты),
  повторить. Сломалось совсем — `tools/godot_mcp_setup.ps1 -Remove`: игра и проверки от MCP не зависят.
- Нет инструмента — набор не включён при регистрации (см. Toolsets).
