# Отчёт FR1 — первый запуск и первая вылазка

**Исполнитель:** Codex · **Ветка:** `task/fr1` · **Коммит:** не создавался.

## Сделано
- Продолжена уже начатая работа в worktree. План и разбор восьми референсов — [FIRST_RUN.md](../../FIRST_RUN.md).
- Новый профиль сразу входит на Блокпост со штатным АК-С без меты. Видимые цели сразу, XP в 8 с, ящик в 18 с, снабжение в 65 с, выход в 120 с, страховочное завершение в 150 с. Tab / Back пропускает вводную без награды.
- Одна подсказка рядом с героем/предметом, клавиатура или геймпад по последнему вводу; флаги сохраняются после реального действия. Пауза и карты скрывают подсказки. Подпись выхода и предметы не закрывают героя.
- После первого возвращения — арсенал и склад; затем мастерская/операции, казарма по очку навыка или третьему возвращению. «Новое» снимается при посещении, закрытый раздел показывает условие.
- Схема профиля v9: v1–v8 обходят вводную и сохраняют все допуски и прогресс; повторная загрузка мигрированного профиля также проверена. Изученное снабжение остаётся доступным при повторе прерванной вводной.

## Изменённые файлы
| Файл | Что |
|---|---|
| `design/FIRST_RUN.md`, `design/BALANCE.md` | План, расписание и награды вводной |
| `scripts/meta.gd` | Флаги, миграция, постоянный допуск к вкладкам |
| `scripts/base.gd` | Вход в бой, закрытые вкладки и отметки посещения |
| `scripts/ui/hints.gd`, `.uid` | Подсказки и короткая вылазка |
| `scripts/game.gd` | Подключение вводной, отключение поздних событий, завершение |
| `scripts/hud.gd`, `scripts/run_results.gd` | Значок выхода, одна подсказка, возврат на базу |
| `tests/first_run/` | 6 тестов профиля и оконный сценарий |
| `design/tasks/reports/fr1_*.png`, `FR1.md` | Кадры и отчёт |

## Проверка
`powershell -NoProfile -ExecutionPolicy Bypass -File tools/test_project.ps1 -Suite full -Out tmp/test_results/fr1_final`

```text
[OK  ] godot  4.7.2.stable.official.ed1daf0bf
[OK  ] import  exit=0 script_errors=0
[OK  ] gdunit  exit=0 tests=46 failed=0 skipped=0 report=C:\Users\Dev\Desktop\zera-fr1\tmp\test_results\fr1_final\gdunit\report_1
[FAIL] --meta-test  exit=1 TESTRESULT ok=false errors=5
[OK  ] --campaign-test  exit=0 CAMPAIGNTEST ok=true
[OK  ] --q1-test --fresh-save  exit=0 Q1TEST checks=25 failed=0 ok=true
[OK  ] --fresh-save --gore-checks  exit=0 R1CHECK ok=true remains_peak=200 stamps_queue=387 particles=0
[OK  ] --obstacles-test --fresh-save  exit=0 OBSTEST ok=true penetrations=0 arrived=500 detonations=3 blood_events=2
[OK  ] --activities-test --fresh-save  exit=0 ACTIVITIESTEST checks=149 failures=0 rewards=6 ok=true
[OK  ] --sim=600 --fresh-save  exit=0 SIM 10:00 level=20 kills=3591 xp=2468/6014 credits=324/819 credits_left=24 zombies=25 kinds=16/9/0/0 armored=0/0/0 elites=0 elites_spawned=14 crates=2 nades=9 dmg_taken=610 peak=35 fps=134 | АК-С L5 Стан1 [Рико3] | Мясник L5 Стан1 [Рико3] | Игла L5 Стан1 [Рико1] | Гром L5 Стан1 []
ZERA_TEST suite=full checks=10 failed=1 out=tmp/test_results/fr1_final
```

Полный прогон завершился кодом 1 только из-за meta-test: недоступна запись тестовой фикстуры в `user://` (`store_string` на null). Повтор только упавшей проверки с `$env:APPDATA='C:/Users/Dev/Desktop/zera-fr1/tmp/fr1_runtime'` завершился кодом 0. Остальные проверки повторно не запускались:

```text
METATEST checks=520 failed=0
METATEST ok=true
FIRST_RUN_INTEGRATION checks=15 failed=0
FIRST_EXIT_VISIBILITY checks=1 failed=0
```

Оконные команды: `bash C:/Users/Dev/Desktop/zera-assets/locks/godot_exclusive.sh "<godot>" --disable-vsync --path . --script res://tests/first_run/capture.gd -- --fresh-save`; для последней проверки перекрытий — также `--capture-evac`. Временный APPDATA внутри worktree нужен для доступного кэша шейдеров. Код игры и тестовые пути ради песочницы не подменялись.

Кадры 1920×1080 просмотрены крупно: [до](fr1_before_start.png), [первые секунды](fr1_first_seconds.png), `fr1_hint_{move,move_pad,aim,xp,pickup,ability,trader,evac}.png`, [первый уровень](fr1_first_levelup.png), [база после вылазки](fr1_base_after_first.png), [старый профиль](fr1_old_profile_base.png), [итоги](fr1_results.png). Исправлены перекрытие героя подписью и порядок отрисовки снабжения; арсенал после входа больше не помечен новым.

## Замеры до/после
AMD Radeon Graphics, D3D12 Forward+. Исходные три замера: **15,0 / 13,0 / 7,7 FPS**, медиана **13,0**; посторонних процессов **4 / 8 / 6**. Итоговые: **7,5 / 7,8 / 7,7 FPS**, медиана **7,7**; посторонних процессов **12 / 10 / 6**. Формальная разница **−40,8 %**, сравнение невалидно из-за разной внешней нагрузки. Общая блокировка работает в `mode=parallel`; её `[OK]` не доказывает чистоту замера.

```text
BENCH median avg_fps=7.7
ZERA_TEST suite=bench checks=4 failed=0 out=tmp/test_results/fr1_after
```

Начальная попытка `-Suite bench` до изменений упала на разборе внешнего `godot_exclusive.ps1`; исходные три числа получены через штатный bash-lock. После исправления общего инструмента извне итоговый `-Suite bench -SkipImport` отработал. Нужен чистый парный замер ревьюером: условие ≤5 % пока не подтверждено.

Первый оконный стенд зафиксировал `launch_ms=17508 game_seconds=1.73 kills=4`; итоговый — `launch_ms=44556 game_seconds=1.73 kills=4`, дополнительный кадр — `launch_ms=30055`. До FR1 требовался выбор на глобусе; теперь ввод до первого выстрела не нужен. При нынешней параллельной нагрузке цель **10–20 с от запуска процесса не подтверждена**. В игровом времени четыре убийства уже к 1,73 с.

## Критерии приёмки
- [x] Документ, прямой вход нового профиля, короткая вылазка, XP/карты, подбор и выход.
- [x] Контекстные одноразовые подсказки, клавиатура/геймпад, пропуск, сохранение после перезапуска.
- [x] Постепенное открытие базы; старый профиль без обучения и ограничений.
- [x] Кадры просмотрены, читаемость исправлена итерациями.
- [ ] Чистый FPS без регрессии >5 % и запуск за 10–20 с — мешают параллельные процессы; нужен повтор в свободной системе.
- [ ] Агрегат `full failed=0` — исходный meta-test ограничен песочницей; его отдельный повтор успешен.

## Отступления от задачи и контракта
- Новый растровый арт не понадобился: значки предметов существующие, клавиши рисуются средствами общего ZeraStyle. Генератор и дубли ассетов не добавлялись.
- Оружие, карты, орда и кампания не изменялись; новые методы Meta используются внутри пакета FR1.
- Уже присутствовавшие изменения `tools/test_project.ps1` и `design/tasks/reports/b3_arc.json` не входят в FR1 и не откатывались. Нет коммитов.
- Созданный `--sim` файл `hd1_trace_after.json` восстановлен. Итоговые логи набора — `tmp/test_results/fr1_final/`, краткие дополнительные результаты — [fr1_checks.log](fr1_checks.log). Удаление временного `tmp/fr1_runtime/` (~2,5 МБ), старых `tmp/test_results/fr1_{before,full,unit}/` и дублей логов не выполнено: автоматическая проверка дважды отклонила очистку с причиной `blocked by policy`, включая вариант с заранее проверенными абсолютными `-LiteralPath`. Временные процессы FR1 завершены.

## Найденные проблемы вне задачи
- Нужен штатный доступный каталог userdata для CLI-проверок; внешние процессы и параллельный режим блокировки мешают приёмке производительности.
