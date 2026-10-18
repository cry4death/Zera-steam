# Музыка

Треки сгенерированы автором игры в Suno (2026-10-17). Исходники (WAV/MP3) лежат вне репозитория:
`Desktop\zera-assets\music_src\tracks`. Сборка: `tools/prep_music.py` — OGG Vorbis ≈ 110 кбит/с,
громкость к RMS −16 dBFS (пик ≤ −1 dBFS), затухание 1.5 с в конце.

| Файл | Исходник | Где звучит |
|---|---|---|
| protocol_zero | Protocol Zero («главное меню») | база |
| orbit_of_extinction | Orbit of Extinction («карта планеты») | вкладка «Операции» |
| descent_into_madness_a | Descent Into Madness («классная») | Объект-7 (с предупреждения в 9:30) |
| descent_into_madness_b | Descent Into Madness («оч хорошая») | бой |
| delirious_charge, delirium_charge, infected_among_us, mechanical_suffocation, mechanical_survival, obsessive_groove, pressurized_chamber, quarantine_zone, rattling_machine, sirenes_des_cendres, suffocating_tension, por | одноимённые треки | бой (мешок без повторов) |

Распределение — константы в `scripts/music.gd`.
