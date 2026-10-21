# Отчёт ST1 — настройки

**Исполнитель:** ChatGPT · **Ветка:** `task/st1` · **Коммит:** не создавался.

## Сделано
- Четыре вкладки настроек с базы и из паузы, мышь/клавиатура/геймпад. Состояние фокуса и материалы — ZeraStyle.
- Все боевые назначения клавиатуры/мыши, взаимодействие и пропуск вводной сохраняются через InputMap. Конфликт явно предлагает обмен; альтернативные клавиши сохраняются; есть сброс. Геймпад показывает штатную раскладку, переназначение геймпада не добавлялось.
- Подсказки FR1 и HUD читают фактические назначения. Пауза работает и после назначения кнопки мыши; раскладка восстанавливается после загрузки профиля и перехода в бой.
- Масштаб 80–150%: HUD, база, пауза, карты, торговец и итоги. Карты переносятся в строки; длинные экраны прокручиваются, выбранные карты автоматически показываются при навигации. Горизонтальная прокрутка базы — полоса или Shift+колесо.
- Независимые тряска/отдача, вспышки, экранная кровь, мигание тревоги. Минимальная жестокость больше не принуждает выключать экранную кровь: её количество уменьшается, доступность задаёт отдельный переключатель.
- Общая громкость, музыка, эффекты и UI; сохранены отдельные уровни оружия/мира. «Эффекты» умножает уровни Weapons/World/Shots, не затрагивает Music/UI. Порядок существующих шин сохранён, новые не понадобились.
- Профиль v10, безопасные значения и ограничения, приём старых v1–v9 без потери прогресса и состояния FR1.

## Изменённые файлы
| Файл | Что |
|---|---|
| `scripts/ui/settings_bindings.gd` | Назначения, подписи, проверка данных, обмен, InputMap |
| `scripts/ui/settings_screen.gd` | Вкладки, захват клавиш, ползунки, навигация |
| `scripts/ui/settings_layout.gd` | Общий масштаб, колонки и прокрутка |
| `scripts/meta.gd` | Настройки, профиль v10, загрузка старых данных и громкость |
| `scripts/pause_menu.gd`, `scripts/base.gd` | Вход в настройки, масштаб и прокрутка |
| `scripts/hud.gd`, `scripts/level_up.gd`, `scripts/trader_ui.gd`, `scripts/run_results.gd` | Масштаб, расположение, координаты клика и текста |
| `scripts/ui/hints.gd` | Назначения в подсказках и действиях FR1 |
| `scripts/game_camera.gd`, `scripts/alarm_overlay.gd`, `scripts/screen_blood.gd` | Независимые выключатели эффектов |
| `tests/settings/` | 10 случаев GdUnit4 и оконный интеграционный стенд |
| `scripts/campaign/cp1_test.gd` | Ожидание новых полей настроек в старом профиле |

## Проверка
Команды из корня worktree:
```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test_project.ps1 -Suite full -Out tmp/test_results/st1_final
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test_project.ps1 -Suite bench -SkipImport -Out tmp/test_results/st1_bench_final
```
Для процессов `APPDATA` направлен в `tmp/st1_runtime`: обычная папка userdata недоступна песочнице. Код игры и пути сохранений для этого не менялись. Оконные запуски — через `godot_exclusive.sh`; bench — штатным скриптом через ту же общую блокировку.

Полный набор завершился с кодом 0. После последней правки отдельно повторены 10 тестов настроек: `Exit code: 0`.
```
[OK  ] godot  4.7.2.stable.official.ed1daf0bf
[OK  ] import  exit=0 script_errors=0
[OK  ] gdunit  exit=0 tests=63 failed=0 skipped=0 report=D:\zera-wt\zera-st1\tmp\test_results\st1_final\gdunit\report_1
[OK  ] --meta-test  exit=0 METATEST ok=true
[OK  ] --campaign-test  exit=0 CAMPAIGNTEST ok=true
[OK  ] --q1-test --fresh-save  exit=0 Q1TEST checks=25 failed=0 ok=true
[OK  ] --fresh-save --gore-checks  exit=0 R1CHECK ok=true remains_peak=200 stamps_queue=396 particles=0
[OK  ] --obstacles-test --fresh-save  exit=0 OBSTEST ok=true penetrations=0 arrived=500 detonations=3 blood_events=2
[OK  ] --activities-test --fresh-save  exit=0 ACTIVITIESTEST checks=149 failures=0 rewards=6 ok=true
[OK  ] --sim=600 --fresh-save  exit=0 SIM 10:00 level=29 kills=3755 xp=5938/6111 credits=785/817 credits_left=435 zombies=30 kinds=30/0/0/0 armored=0/0/0 elites=0 elites_spawned=13 crates=3 nades=13 dmg_taken=234 peak=33 fps=135 | АК-С L5 Стан1 [Рико3,Проб3] | Мясник L5 Стан1 [Рико3,Проб3] | Игла L5 Стан1 [Рико3,Проб2] | Гром L5 Стан1 [Рико3]
ZERA_TEST suite=full checks=10 failed=0 out=tmp/test_results/st1_final
ZERA_TEST suite=bench checks=4 failed=0 out=tmp/test_results/st1_bench_final
```
Строки трёх замеров и оконного стенда — [ST1_checks.log](ST1_checks.log). Полные логи стандартных проверок — `tmp/test_results/st1_final/`. Порождённые тестами изменения `b3_arc.json`/`hd1_trace_after.json` убраны; runtime и дубли логов удалены.

Оконный стенд `tests/settings/capture.gd` завершился с кодом 0:
```
SETTINGSINPUT conflict_exchange=true reset=true
SETTINGSINPUT gamepad_tabs=true gamepad_slider=true gamepad_back=true
SETTINGSINPUT rebound_pause_after_scene_change=true
SETTINGSLAYOUT resolutions=4 scales=2 selected_cards_visible=true
SETTINGSSHOTS done
```
Проверены 1280×720, 1920×1080, 2560×1440, 2560×1080 при 80% и 150%. Обязательные кадры просмотрены крупно; дополнительно просмотрены пауза, торговец, база и управление при 150%.

| Замер | До | После |
|---|---|---|
| `--bench=500`, медиана 3 | нет результата: все три прежних запуска упали при записи shader cache/userdata | 11,8 FPS; 9,2 / 11,8 / 12,5 FPS |
| Худший кадр | нет результата | 150,00 мс во всех трёх |
| Условия | `mode=parallel` | `mode=parallel`, других процессов 7 / 11 / 9 |
| Баланс | не менялся | не менялся |

Достоверного сравнения FPS до/после нет; условие просадки ≤5% не подтверждено. Шумную серию не повторял. Исходные кадры `st1_*_before.png` унаследованы от предыдущего незавершённого прохода, часть реализации ST1 в них уже присутствует.

Скриншоты в корне worktree: `st1_controls.png`, `st1_screen.png`, `st1_audio.png`, `st1_hint_rebound.png`; `st1_scale_{80,150}_{1280x720,1920x1080}.png` — карты, соответствующие `*_hud.png` — HUD. Дополнительно `st1_controls_150.png`, `st1_base_150.png`, `st1_pause_150.png`, `st1_trader_150.png`.

## Критерии приёмки
- [x] Назначения клавиатуры/мыши, подсветка конфликта, обмен, сброс, актуальные подсказки.
- [x] Масштаб 80–150%; содержимое больших экранов доступно с прокруткой, фокус карты остаётся видимым.
- [x] Отдельные выключатели эффектов и уровни громкости.
- [x] Вкладки настроек с базы и паузы; мышь, клавиатура, геймпад.
- [x] Сохранение/загрузка назначений, безопасные значения, миграция старых профилей.
- [x] Полный набор: `ZERA_TEST suite=full checks=10 failed=0`.
- [ ] Подтверждение отсутствия просадки FPS более 5%: исходный bench не получил результата.

## Отступления от задачи и контракта
- `base.gd` изменён также для общего масштаба/прокрутки: это требуется пунктом 2 задачи, хотя список разрешает в нём только вход в настройки. Содержимое разделов не переписывалось.
- Вне перечня — две строки в `scripts/campaign/cp1_test.gd`: прежняя проверка требовала точного равенства старого словаря настроек, включая отсутствие новых полей. Ожидание теперь проходит через штатную миграцию настроек; прогресс проверяется как прежде.
- Крупные экраны не уменьшаются обратно вопреки выбранному масштабу: вместо этого доступны полосы прокрутки. При 150% вся база/торговец/сборка паузы одновременно не помещаются.
- CONTRACTS.md не менялся; баланс и содержимое карт не менялись.

## Найденные проблемы вне задачи
- В среде Godot пишет `ERROR: Failed to read the root certificate store.`; при завершении оконного стенда остаётся предупреждение об одном ObjectDB instance. Проверки и стенд завершились штатно; это не ошибки назначений/раскладки.
