# W6 — прослушивание пресетов и W4/main

Реальный выход Master, без последующей нормализации; у W6 сильнее атака.
Исходный main: `86e3c53af634662b0c04b2a4cac33de900a517bd`, вариант `shot_0`, его шины и Shots −7 дБ.
W6: стартовые настройки `sfx/gun_tuning.json`, сохранённый микс W5, четыре живых слоя, отдельный звуковой RNG.
Это одиночные выстрелы звукового стенда, не запись боя. У автоматов здесь слышен и слой отражения;
в игре он вызывается событием конца очереди. Dummy-драйвер выдаёт WAV около 2,4–2,6 с.

| Ствол | W4/main | Пресет W6 |
|---|---|---|
| Пистолет | [main](pistol_main.wav) | [W6](pistol_preset.wav) |
| Револьвер | [main](revolver_main.wav) | [W6](revolver_preset.wav) |
| ППШ | [main](smg_main.wav) | [W6](smg_preset.wav) |
| АК | [main](rifle_main.wav) | [W6](rifle_preset.wav) |
| Дробовик | [main](shotgun_main.wav) | [W6](shotgun_preset.wav) |
| Мосин | [main](sniper_main.wav) | [W6](sniper_preset.wav) |
| Рельса | [main](rail_main.wav) | [W6](rail_preset.wav) |
| Гранатомёт | [main](launcher_main.wav) | [W6](launcher_preset.wav) |

Пересоздание исходников/стартовых настроек: `node tools/prep_gunlab.mjs` (перезаписывает настройки проекта).
Эталоны: `node tools/prep_gunlab.mjs --reference`. После импорта:
`godot --headless --path . -- --gunlab-render --fresh-save`; один ствол — дополнительно `--gunlab-gun=rifle`.
Метрики: `node design/tasks/reports/w6_analyze.mjs`.
