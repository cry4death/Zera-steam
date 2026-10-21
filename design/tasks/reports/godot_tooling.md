# Отчёт godot-tooling — Godot Editor MCP и GdUnit4

**Исполнитель:** Claude Opus 5.5 · **Ветка:** `chore/godot-tooling` (worktree `Desktop\zera-godot-tooling`) · **Основа:** `main` 83800d1

## Сделано
- GdUnit4 6.2.2 (стабильный тег) в `addons/gdUnit4/`, включён в `project.godot`. Официально заявлен до Godot 4.7.1;
  на 4.7.2 проверен: импорт без ошибок, плагин грузится в редакторе (вкладка GdUnit, `gdUnitConsole`), 40 тестов,
  коды выхода 0 / 100 / 105.
- Первые тесты: `tests/campaign/campaign_rules_test.gd` (26 случаев: этапы заражения по CAMPAIGN.md §6.1,
  воспроизводимость и неизменяемость входа `advance`, победа/провал/удар по улью, подавление, 40 ходов войны,
  фазы, отказ битых сохранений, `normalized`, миграция v2→v3, `run_id`) и `tests/weapons/weapon_defs_test.gd`
  (14 случаев: АК-С по BALANCE §3.2–3.3, ограничение уровня, статы и DPS всех 48 моделей, пробитие брони, слоты
  модулей, ограничения огнемёта/пилы/теслы).
- Godot Editor MCP: сервер `godot-editor-mcp==2026.10.15` через `uvx` (stdio), addon 2026.10.15 в `addons/godot_mcp/`
  (включён), skills `godot-getting-started`, `godot-playtest-and-debug`, `godot-expert` (+ `references/`) в
  `.claude/skills/`. Регистрация в Claude Code — scope `local` для `Desktop\zera`, мост закрыт токеном.
- `tools/test_project.ps1` — единая проверка (`fast`/`full`/`gdunit`/`bench`), `tools/godot_mcp_setup.ps1` —
  регистрация MCP, `tools/godot_editor.ps1` — редактор под общей блокировкой с токеном моста.
- Правила: `design/tasks/TOOLING.md` (единый источник), ссылки из `AGENTS.md`, новый короткий `CLAUDE.md`,
  `design/tasks/README.md` — действующая схема сверху, inbox/Sonnet — в разделе «История», `HANDOFF.md`.
- `.claude/settings.json`: чтение через MCP — без вопросов, разрушающие инструменты и запуск игры — `ask`.

## Изменённые файлы
| Файл | Что |
|---|---|
| `addons/gdUnit4/`, `addons/godot_mcp/` | официальные addon’ы без изменений (MIT) |
| `project.godot` | `[editor_plugins]` — два плагина |
| `tests/campaign/campaign_rules_test.gd`, `tests/weapons/weapon_defs_test.gd` | тесты GdUnit4 |
| `tools/test_project.ps1`, `tools/godot_mcp_setup.ps1`, `tools/godot_editor.ps1` | скрипты (UTF-8 с BOM для PowerShell 5.1) |
| `.claude/skills/godot-*`, `.claude/settings.json` | skills MCP, разрешения |
| `design/tasks/TOOLING.md`, `CLAUDE.md` | новые правила |
| `AGENTS.md`, `HANDOFF.md`, `design/tasks/README.md`, `.gitignore` | ссылки, проверка одной командой, история схемы, `/tmp/` и `/reports/` |

Вне репозитория: `uv 0.13.3` (`pip install uv` в Python 3.12), запись `godot` в `~/.claude.json` (scope local,
`Desktop\zera`), токен `%LOCALAPPDATA%\zera\godot_mcp_bridge.token`. Настройки Codex и глобальные настройки Claude
не менялись.

## Проверка
Базовый прогон чистого `main` (до правок, тот же коммит):
```
import exit=0 · --meta-test 0 · --campaign-test 0 · --q1-test --fresh-save 1 (PACKTEST bank=92 … ok=false)
--fresh-save --gore-checks 0 · --obstacles-test 0 · --activities-test 0 · --sim=600 0
```
Ветка, `tools/test_project.ps1 -Suite full`:
```
[OK  ] godot  4.7.2.stable.official.ed1daf0bf
[OK  ] import  exit=0 script_errors=0
[OK  ] gdunit  exit=0 tests=40 failed=0 skipped=0
[OK  ] --meta-test  exit=0 METATEST ok=true
[OK  ] --campaign-test  exit=0 CAMPAIGNTEST ok=true
[FAIL] --q1-test --fresh-save  exit=1 Q1TEST checks=25 failed=1 ok=false
[OK  ] --fresh-save --gore-checks  exit=0 R1CHECK ok=true remains_peak=200 stamps_queue=397 particles=0
[OK  ] --obstacles-test --fresh-save  exit=0 OBSTEST ok=true penetrations=0 arrived=500 detonations=3 blood_events=2
[OK  ] --activities-test --fresh-save  exit=0 ACTIVITIESTEST checks=113 failures=0 rewards=6 ok=true
[OK  ] --sim=600 --fresh-save  exit=0 SIM 10:00 level=18 kills=3826 … peak=31 fps=145
WARN проверки изменили файлы под git: design/tasks/reports/hd1_trace_after.json
ZERA_TEST suite=full checks=10 failed=1
```
Единственный провал — тот же, что на `main` (не связан с интеграцией). Проверены и пути отказа: ошибка разбора
теста → GdUnit4 код 105, скрипт «results.xml не создан»; пустой каталог → GdUnit4 код 0, скрипт считает провалом.

Godot Editor MCP (редактор открыт `tools/godot_editor.ps1` на этом worktree, клиент MCP по stdio):
```
health_check: bridge_connected=true addon_version=2026.10.15 bridge_url=ws://localhost:9080 (bind 127.0.0.1)
get_server_info: version=2026.10.15 contract_version=1 transport=stdio
get_project_info: name=Zera godot 4.7.2-stable main_scene=res://scenes/base.tscn autoloads Meta, Music
get_active_scene: res://scenes/base.tscn dirty=false · get_node_properties(.): Control, res://scripts/base.gd
scripts_get_parse_errors game.gd / base.gd: ok=true errors=[]
create_scene/create_node (dry_run, затем по-настоящему) в res://tmp/mcp_probe.tscn → persisted=true; удалена
close_scene без confirm → PRECONDITION_FAILED … Pass confirm=true
run_and_capture base.tscn 8 s: ran=true timed_out=true errors=[] warnings=[]
--import без токена во время сессии: "bridge auth: no auth message from peer; refusing", редактор connected все 12 опросов
claude mcp get godot: ✔ Connected · Scope: Local config · GODOT_MCP_DEFAULT_TOOLSETS=inspection
```
Скриншот редактора через MCP: `reports/godot_tooling_editor_mcp.png`. В логе редактора ошибок и предупреждений нет.
Оконный бенч не запускался: игровой код и сцены не менялись.

## Отступления
- MCP зарегистрирован со scope `local`, а не в `.mcp.json`: мост — одно подключение на порту 9080, а проектный
  `.mcp.json` разошёлся бы по всем worktree; токен не должен попасть в git.
- Набор по умолчанию — только `inspection`: запуск игры через MCP пишет настоящий профиль (см. ниже).
- `--import` в любом worktree теперь грузит оба плагина (addon MCP пытается подключиться к мосту и без токена
  отклоняется). На импорт это не повлияло (exit 0, 0 ошибок разбора).

## Не проверено
- Вызов инструментов MCP из **новой** сессии Claude Code: CLI десктопа отсюда не авторизован (`claude -p` →
  «Not logged in»), а текущая сессия не подхватывает новые серверы. Сервер виден Claude Code как `✔ Connected`,
  инструменты проверены тем же протоколом stdio. Нужно перезапустить сессию в `Desktop\zera` и спросить
  «Godot подключён?» с открытым редактором.
- Слияние в `main` не делалось; в `main` addon’ов ещё нет, поэтому редактор для MCP пока открывать на этом worktree.

## Найденные проблемы вне задачи
- `--q1-test --fresh-save` падает на чистом `main`: `PACKTEST bank=92`, тест ждёт 91 банк звуков (`meta_test.gd:847`).
- `--sim=600` перезаписывает отслеживаемый `design/tasks/reports/hd1_trace_after.json` (`game.gd:2982`).
- Баланс: у «Гарпуна» (`last_round`) L3 «магазин +2» снижает эффективный DPS 37.33 → 36.52; в тестах — известное
  исключение `KNOWN_DPS_DROPS`.
- Headless-запуск `base.tscn` без флагов (так запускает MCP) за 8 с пересохранил `user://zera_save.json` автора
  (версия 7, 15078 → 15275 байт; JSON цел, загрузчик не создал `.bad-*`). Копии до записи нет.
- Автозагрузка `Meta` без флагов читает настоящий профиль и при старой версии переписывает его; любой новый
  инструмент, запускающий проект без `--fresh-save`/`--save-file`, это унаследует.
