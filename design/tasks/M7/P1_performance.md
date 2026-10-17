# P1 — производительность на встроенной видеокарте

**Исполнитель:** Sonnet · **Уровень:** high (производительность) · **Ветка:** `task/p1`
**Почему сейчас:** автор начинает плейтест на этой машине (AMD Radeon встроенная, D3D12 Forward+, 1920×1080).
`--loadout --bench=500` даёт ~20–40 FPS (шумно), `physics_ms` 15–35, `draw_calls` 1100–3500, тяжёлые кадры
40–150 мс (`reviews/S3.md`, `W1.md`, `S4.md`, `CONCEPT_FULL.md` §10 «известные проблемы»).

## Цель

`--loadout --bench=500` — **стабильно ≥ 60 FPS** на этой машине (средний), худший кадр ≤ 50 мс, без видимой
потери gore и читаемости. Если 60 недостижимо без потери вида — максимум возможного + честный анализ, что именно упирается.

## Сделать

1. **Профилирование, а не догадки.** Godot профайлер/монитор (`Performance.get_monitor`: TIME_PROCESS, TIME_PHYSICS_PROCESS,
   RENDER_TOTAL_DRAW_CALLS_IN_FRAME, RENDER_TOTAL_OBJECTS_IN_FRAME, RENDER_VIDEO_MEM_USED) + собственные таймеры по
   системам (орда, пули, gore, эффекты/частицы, декали пола, гильзы, свет, звук `horde_audio`, HUD). Таблица «система →
   мс CPU, draw calls» до и после. Отдельно: CPU-bound или GPU-bound (сравни с `--headless` и с уменьшенным окном).
2. **Кандидаты** (проверь цифрами, делай только то, что помогает):
   - `_draw()` с тысячами `draw_rect`/`draw_line`/`PixelArt.draw_dot` каждый кадр (gore, effects, gems, weapons, horde._draw)
     → MultiMesh / батч в один ArrayMesh / рисовать только изменившееся / уменьшить частоту перерисовки статичного;
   - запекание в пол (`floor_decals`): размер и число SubViewport, частота обновления, UPDATE_ONCE вместо ALWAYS;
   - 6 `PointLight2D` вспышек: стоимость света на встроенной GPU (light mask, `shadow_enabled=false`, меньше радиус,
     один свет на кадр), сравнить с выключенным светом;
   - физика: `physics_ms` — что именно (расталкивание орды, пули, гильзы), шаг spatial hash, лишние запросы;
   - аудио: стоимость `horde_audio` и пула голосов.
3. Поведение и вид не менять (кроме незаметных упрощений, перечисленных в отчёте). Все Packed-массивы/без нод на сущность.
4. **Опция качества** (если выигрыш большой, а вид страдает): пункт «Качество эффектов: Высокое/Среднее» в экране
   настроек S7 (свет вспышек, плотность частиц) — по умолчанию выбирать автоматически по первым секундам FPS не надо,
   просто «Высокое» по умолчанию.

## Можно трогать

`scripts/horde.gd` (только рендер и расталкивание; логика врагов — без изменений), `scripts/gore.gd`, `scripts/effects.gd`,
`scripts/floor_decals.gd`, `scripts/gems.gd`, `scripts/pickups.gd`, `scripts/weapons.gd` (только `_draw`/слои вспышек и свет),
`scripts/hud.gd` (только отрисовка), `scripts/horde_audio.gd`, `scripts/sfx.gd`, экран настроек (`pause_menu.gd`) и `meta.gd`
(только пункт качества), отчёт `design/tasks/reports/P1.md`, `p1_*`.
**Не трогать** (идут задачи кампании C1–C3): `scripts/campaign/**`, `base.gd`, `run_results.gd`, `spawner.gd`, `game.gd`
(кроме добавления счётчиков в вывод `--bench`, если без этого никак — тогда минимально и описать).

## Проверка

```
godot --headless --path . --import
godot --disable-vsync --path . -- --loadout --bench=500      (×3 до, ×3 после; то же на main во временной копии)
godot --disable-vsync --path . -- --loadout-w1 --bench=500   (×2)
godot --disable-vsync --path . -- --alarm                    (worst_frame_ms до/после)
godot --disable-vsync --path . -- --boss                     (death_worst_frame_ms до/после)
godot --headless --path . -- --sim=600 ; --weapons-test ; --meta-test   (ничего не сломано)
```
Скриншоты до/после в одинаковый момент `--bench` (`p1_before.png`, `p1_after.png`) — вид не должен заметно отличаться.

## Критерии приёмки
- [ ] Таблица профиля по системам до/после, вывод: что было узким местом.
- [ ] `--loadout --bench=500` ≥ 60 FPS средний (или максимум + честное объяснение), худший кадр ≤ 50 мс.
- [ ] Gore и читаемость не потеряны (скриншоты рядом), тесты зелёные.
- [ ] Отчёт `design/tasks/reports/P1.md`.
