# W4 — набор для прослушивания

Все файлы — итоговый выход Master через настоящую цепочку шин (Weapons/Shots/World/UI → компрессор → лимитер), 48 кГц, 16 бит.
`*_before` — main до W4 (коммит `43e1c7c`: старые сэмплы, старый `sfx.gd`, старый `default_bus_layout.tres`).
`*_after` — ветка `task/w4` (новые сэмплы + микс). Сценарий одинаковый, генератор случайных чисел с одним зерном.
Слушать парами: сначала `before`, потом `after`, на одной громкости системы. `after` громче — это задумано
(выстрел должен вести микс); сравнивать нужно вес, атаку и хвост.

## 1. Бой (главное)
1. `battle_before.wav` → `battle_after.wav` — 5 с: орда, гильзы, попадания и четыре ствола (ППШ, винтовка, дробовик, Мосин).

## 2. Одиночные выстрелы: от лёгкого к тяжёлому
2. `pistol_before` / `pistol_after`
3. `revolver_before` / `revolver_after`
4. `smg_before` / `smg_after`
5. `rifle_before` / `rifle_after`
6. `shotgun_before` / `shotgun_after`
7. `sniper_before` / `sniper_after` (Мосин)

## 3. Очереди по 2 с (автоматы: выстрелы + отдельный хвост после очереди)
8. `smg_burst_before` / `smg_burst_after`
9. `rifle_burst_before` / `rifle_burst_after`
10. `m4_burst_before` / `m4_burst_after`
11. `osa_burst_before` / `osa_burst_after`
12. `shkval_burst_before` / `shkval_burst_after` (5 выстрелов, не автомат)

## 4. Модели из ящиков и спецоружие
13. `m4`, `shkval`, `guard`, `cowboy`, `osa`, `winchester` — `<имя>_before` / `<имя>_after`
14. `rail`, `launcher`, `spear`, `hive` — `<имя>_before` / `<имя>_after`

`capture_before.json` / `capture_after.json` — сколько выстрелов запрошено и принято в каждой записи
(поле `shot_rejected` — потерянные выстрелы; в `*_stress` — 10 с на 60 выстрелов/с).
