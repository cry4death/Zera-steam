# Отчёт G4 — арт M5: «Объект-7»

**Исполнитель:** ChatGPT (Codex) · **Ветка/файл:** inbox/G4/gen_art_m5.py · **Коммит:** нет, zera только для чтения.

## Сделано
- Самостоятельный генератор поверх `gen_art as ga`, без зависимости от gen_art_m4. Использует Canvas, LIGHT, рампы, выборочную обводку, tear, stain, walk из проекта. Импорт и исходный zera не менялись; PYTHONDONTWRITEBYTECODE=1 запрещал создание __pycache__ в zera/tools.
- Босс смотрит по +X: 2 фазы × 5 кадров, плечи и руки-колоды, когти, небольшой костяной лоб, броня с заклёпками, царапинами и трафаретом О-7, ремни и оборванные трубки. Во второй фазе — мышцы, вены, раны, жир, рёбра, кровь и один оставшийся обломок брони.
- Четыре разные пластины, четыре типа гибов (плечо с бронёй, рёбра, кишки, лобная кость), три вытянутые декали с разной одеждой, военный ящик с жёлтыми полосами и красной пломбой.
- preview.png: все 10 кадров босса и все остальные спрайты ×3 без сглаживания, на асфальте (61,63,67) и крови (60,12,14). Отдельное сравнение обеих фаз с обычным зомби и толстяком из существующего атласа.
- Превью просмотрено после генерации и после доработок: открыты глаза у края лобной пластины, добавлены мышечные волокна и сравнение масштаба. Проверка нашла совпадение кадров 0/2; исправлено смещением корпуса, итоговые 5 кадров каждой фазы уникальны.

## Изменённые файлы
| Файл | Что |
|---|---|
| gen_art_m5.py | Полный генератор; `--out DIR`, `--preview PNG`, `--reference zombie_atlas.png` |
| art/boss.png | 720×288; ячейки 144×144, строки — фазы 1/2, столбцы — ходьба 0–3 и таран 4 |
| art/boss_plate_0.png … boss_plate_3.png | 4 пластины 30×30 |
| art/boss_gib_0.png … boss_gib_3.png | 4 гиба 36×36 |
| art/crushed_0.png … crushed_2.png | 3 декали 48×48 с полупрозрачными краями, без outline |
| art/military_crate.png | Военный ящик 27×27 |
| preview.png | Лист 2400×3300 для визуальной проверки |
| notes.md | Этот отчёт |

Перенос ревьюером: скрипт → zera/tools/gen_art_m5.py, содержимое art/ → zera/art/. По умолчанию выход — ga.OUT, как в G3. При запуске из inbox нужен PYTHONPATH=zera/tools и явный --out, иначе сработает исходный ga.OUT. Ниже приведён безопасный запуск.

## Проверка
Среда: Python 3.14.7, Pillow 12.3.0, Godot 4.7.2.stable.official.ed1daf0bf. Временные проверки и копия проекта находились только в разрешённом codex_tmp/G4.

### Генерация
```powershell
$env:PYTHONDONTWRITEBYTECODE='1'
$env:PYTHONPATH='C:\Users\Dev\Desktop\zera\tools'
python tasks/inbox/G4/gen_art_m5.py --out tasks/inbox/G4/art --preview tasks/inbox/G4/preview.png --reference C:/Users/Dev/Desktop/zera/art/zombie_atlas.png
```
Дословный вывод:
```
boss.png: 720x288 RGBA
boss_plate_0.png: 30x30 RGBA
boss_plate_1.png: 30x30 RGBA
boss_plate_2.png: 30x30 RGBA
boss_plate_3.png: 30x30 RGBA
boss_gib_0.png: 36x36 RGBA
boss_gib_1.png: 36x36 RGBA
boss_gib_2.png: 36x36 RGBA
boss_gib_3.png: 36x36 RGBA
crushed_0.png: 48x48 RGBA
crushed_1.png: 48x48 RGBA
crushed_2.png: 48x48 RGBA
military_crate.png: 27x27 RGBA
art -> C:\Users\Dev\Desktop\GameZ\tasks\inbox\G4\art
preview -> tasks/inbox/G4/preview.png
```

### Проверка пикселей и структуры
`python "$G4_TMP\verify.py"`, временный проверочный скрипт. Дважды вызывает sprites(), сравнивает байты всех изображений и сохранённых PNG, проверяет полное множество имён, размеры и режим RGBA, уникальность кадров и прозрачные поля, вытянутость и частичную прозрачность декалей. Импорт проверен с ga.OUT, указывающим на несуществующий временный каталог: он не создаётся. Размер сравнивается по непрозрачному bounding box, не по размеру ячейки.

Дословный итоговый вывод (exit 0):
```
PASS: importing gen_art and gen_art_m5 generates no files
PASS: 13 PNG names, sizes, RGBA, deterministic pixels and delivered PNG match
PASS: each phase has 5 unique frames, transparent padding, no clipped sprites
PASS: crushed decals elongated along +X with translucent blood edges
Visible boss/civilian size ratio: 2.65x width, 3.35x height
PASS: preview contains both backgrounds, all 10 boss frames and 12 other sprites at x3
```
Промежуточный assert len(hashes) == 5 выявил повтор кадра 0/2; после исправления итоговая проверка выше проходит. В первом варианте проверочного скрипта Pillow предупреждал об устаревшем getdata(); проверка переведена на get_flattened_data(), предупреждений в итоговом запуске нет. Рабочий генератор getdata() не использует.

### Godot: копия проекта
```powershell
& 'C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path "$G4_TMP\project" --import --quit
```
Копия zera без .git/.godot, поверх добавлены только новые PNG и генератор. Exit 0, но импорт НЕ считается чистым: в снимке проекта есть ошибки player.gd. Ниже дословные диагностические строки из godot-import.log (фильтр `SCRIPT ERROR|ERROR:|WARNING:|at:`); строки прогресса импорта не приведены.
```
Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
SCRIPT ERROR: Parse Error: Identifier "grenade_cd" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:142)
SCRIPT ERROR: Parse Error: Identifier "_gren_t" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:142)
SCRIPT ERROR: Parse Error: Identifier "GRENADE_COOLDOWN" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:144)
SCRIPT ERROR: Parse Error: Identifier "grenade_cd" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:144)
SCRIPT ERROR: Parse Error: Identifier "_gren_t" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:145)
SCRIPT ERROR: Parse Error: Identifier "_gren_from" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:146)
SCRIPT ERROR: Parse Error: Identifier "GRENADE_DISTANCE" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:147)
SCRIPT ERROR: Parse Error: Identifier "_gren_to" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:147)
SCRIPT ERROR: Parse Error: Identifier "_moving" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:153)
SCRIPT ERROR: Parse Error: Identifier "GRENADE_DISTANCE" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:160)
SCRIPT ERROR: Parse Error: Identifier "_gren_t" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:164)
SCRIPT ERROR: Parse Error: Identifier "_gren_t" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:166)
SCRIPT ERROR: Parse Error: Identifier "_gren_t" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:167)
SCRIPT ERROR: Parse Error: Identifier "GRENADE_TIME" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:167)
SCRIPT ERROR: Parse Error: Identifier "_gren_t" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:168)
SCRIPT ERROR: Parse Error: Identifier "_gren_to" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:169)
SCRIPT ERROR: Parse Error: Identifier "grenade_landed" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:169)
SCRIPT ERROR: Parse Error: Identifier "_gren_t" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:175)
SCRIPT ERROR: Parse Error: Identifier "_gren_t" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:177)
SCRIPT ERROR: Parse Error: Identifier "GRENADE_TIME" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:177)
SCRIPT ERROR: Parse Error: Cannot infer the type of "k" variable because the value doesn't have a set type.
   at: GDScript::reload (res://scripts/player.gd:177)
SCRIPT ERROR: Parse Error: Identifier "_gren_to" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:178)
SCRIPT ERROR: Parse Error: Identifier "_gren_from" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:178)
SCRIPT ERROR: Parse Error: Identifier "GRENADE_ARC" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:179)
SCRIPT ERROR: Parse Error: Cannot infer the type of "lift" variable because the value doesn't have a set type.
   at: GDScript::reload (res://scripts/player.gd:179)
SCRIPT ERROR: Parse Error: Identifier "_gren_to" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:180)
SCRIPT ERROR: Parse Error: Identifier "GRENADE_RADIUS" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:180)
SCRIPT ERROR: Parse Error: Identifier "_gren_tex" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:184)
SCRIPT ERROR: Parse Error: Identifier "_gren_tex" not declared in the current scope.
   at: GDScript::reload (res://scripts/player.gd:184)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/game.gd:0)
ERROR: Failed to load script "res://scripts/game.gd" with error "Parse error".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
ERROR: Cannot save file 'C:/Users/Dev/AppData/Roaming/Godot/editor_settings-4.7.tres'.
   at: save (scene/resources/resource_format_text.cpp:1768)
ERROR: Error saving editor settings to C:/Users/Dev/AppData/Roaming/Godot/editor_settings-4.7.tres
   at: save (editor/settings/editor_settings.cpp:1525)
```

### Godot: изолированная проверка арта
Создан минимальный временный проект с 13 PNG и проверочным SceneTree-скриптом. Выполнены `--headless --path "$G4_TMP\art_check" --import --quit` и затем `--headless --path "$G4_TMP\art_check" --script res://verify.gd`. Скрипт загружает каждый файл через load() как Texture2D и проверяет контрактные размеры. APPDATA/LOCALAPPDATA перенаправлены внутрь временной G4 для настроек редактора.

Дословный вывод второго запуска (exit 0):
```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

Godot_v4.7.2-stable_win64_console.exe : ERROR: Failed to read the root certificate store.
строка:26 знак:313
+ ... .log" 2>&1; & 'C:\Users\Dev\Desktop\Godot_v4.7.2-stable_win64.exe\God ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (ERROR: Failed t...tificate store.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
PASS: Godot loaded all 13 imported textures with contract dimensions
```
Изолированный импорт и загрузка не дали ошибок/предупреждений GDScript и ошибок текстур. Остаётся системная ошибка чтения хранилища корневых сертификатов в обоих запусках Godot; она не препятствовала импорту и загрузке арта. Первый импорт полной копии также не смог сохранить настройки редактора вне разрешённых каталогов; при изолированной проверке пути настроек перенаправлены во временную папку.

Скриншоты/превью: `preview.png`, просмотрено исполнителем после последней генерации. Босс примерно втрое больше обычного зомби; фактические отношения ширины/высоты силуэта — 2.65/3.35. Фазы и когти читаются на обоих фонах. Отдельный игровой скриншот/бой не требовался задачей и не запускался из-за ошибок исходного снимка.

## Критерии приёмки
- [x] Размеры и раскладка — контракт §7.
- [x] Босс в 3 раза крупнее зомби, фазы различимы с первого взгляда, читается на кровавом полу (примерно ×3 по видимому силуэту; измерения выше).
- [x] Детерминированно (`random.Random(seed)`), импорт `gen_art` ничего не генерирует.
- [x] `notes.md`: что и почему.

## Отступления от задачи и контракта
- Имена, размеры, направление, раскладка атласа — без отступлений. Баланс и игровой код не менялись.
- Чистый импорт полной игры не достигнут из-за существующих ошибок player.gd и ограничений среды. Новый арт дополнительно импортирован и загружен в изолированном Godot-проекте; ошибка сертификатов среды остаётся. CONTRACTS.md менять не требуется.
- Удаление временного проекта, проверочных скриптов, логов и перенаправленных настроек из codex_tmp/G4 запрошено после переноса результатов в отчёт, но НЕ выполнено: автоматическая проверка отклонила Remove-Item -LiteralPath <проверенный абсолютный путь G4> -Recurse -Force с причиной `rejected: blocked by policy`. Подробное основание не предоставлено; обход блокировки не предпринимался. Осталась папка `C:\Users\Dev\AppData\Local\Temp\claude\C--Users-Dev-Desktop-GameZ\c0951c8e-5403-4ca4-8a08-a7e35d3e4417\scratchpad\codex_tmp\G4`, её нужно удалить вручную.

## Найденные проблемы вне задачи
- В прочитанном снимке player.gd используются необъявленные переменные/константы/сигнал гранаты (полный перечень выше); game.gd вследствие этого не компилируется. zera параллельно редактируется другим исполнителем, поэтому это состояние только сделанной копии, не оценка его окончательной работы.
- Godot в среде не читает хранилище корневых сертификатов. Исходный проект и системные настройки не исправлялись.
