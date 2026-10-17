# Базовая линия (main @ 6d35ef4, до M4) — с ней сравниваются задачи

Машина: RTX 3060 Ti, D3D12, 1920×1080.

```
--bench=500
BENCH frames=1439 avg_fps=143.9 avg_frame_ms=6.95 worst_frame_ms=7.14 horde_ms=1.89 enemies=500 kills=20
BENCH process_ms=8.33 physics_ms=2.71 draw_calls=207 objects=1814 gore=13 particles=65 wet=9

--sim=180
SIM 01:00 level=4 kills=72  credits=5/5
SIM 02:00 level=7 kills=226 credits=14/17
SIM 03:00 level=9 kills=467 credits=28/31
```

## Обновлено после S1 (main @ db81d7e), `--disable-vsync`

С vsync FPS упирается в 144 и задачи не различает. Сравнивать по `horde_ms`/`physics_ms`, прогоны с `--disable-vsync`.

```
BENCH avg_fps=1032 horde_ms=2.33 physics_ms=3.38 draw_calls=187   (--bench=500)
KINDS avg_fps=663  horde_ms=1.89 worst_frame_ms=14.45             (--kinds)
```
