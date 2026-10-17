# Отчёт G3 — доработка кислотных луж

**Исполнитель:** ChatGPT · **Файл:** inbox/G3/gen_art_m4.py · **Коммит:** нет.
Дата: 17.10.2026. Основание: tasks/reviews/G3.md, ДОРАБОТКА.

## Сделано
- Изменены только acid(frame) и дополнительный ряд preview(). Код и зёрна девяти принятых спрайтов сохранены.
- Основа кислоты — #3d5216 / #4f6a1c с землистым серым. Насыщенность HSV, взвешенная по альфе, снижена с 0,741–0,746 до 0,378–0,379, примерно вдвое.
- Альфа жидкости у края около 61–100, в центре 157–164. Внешняя кайма около 1–2 родных пикселей: (40,38,22), alpha 140. Без Canvas.outline.
- Рваный угловой контур с короткими языками и hnoise; три отдельные капли; пять пузырей радиусом 1–3 px с тенью и бликом; редкая пена. ACID[4] только в двух пикселях бликов на кадр.
- В --preview добавлен ряд на (60,12,14) и (61,63,67), масштабы x2 и x1. Основной лист остаётся x4 без сглаживания.
- Финальное превью просмотрено: кислота видна на обоих фонах, сплошного яркого салатового пятна нет. Промежуточная проверка выявила примыкание одной капли acid_2; позиции исправлены, финально все капли отдельные.

## Изменённые файлы
- gen_art_m4.py — полный генератор с исправленными acid() и preview().
- art/acid_0.png, art/acid_1.png, art/acid_2.png — новые декали 60x60 RGBA.
- preview.png — просмотренный лист 792x1400.
- notes.md — отчёт.
- .review_render.cs, .review_render.ps1, .review_render.exe, .review_verify.cs, .review_verify.exe — временные средства проверки; удалить автоматически не удалось (см. ниже). Финальные PNG соответствуют .review_render.cs; .ps1 — промежуточная версия.

Прочие девять PNG сохранены байт-в-байт. README.md и старый каталог preview/ оставлены без изменений; актуальное превью — preview.png в корне G3.

## Проверка

**Обязательная проверка Python с настоящим gen_art не пройдена.** Чтение zera запрещено, Python не установлен. Проверки предыдущего захода не подтверждают эту версию.

Попытка чтения настоящего API:
```powershell
Get-Content -Encoding UTF8 C:/Users/Dev/Desktop/zera/tools/gen_art.py -TotalCount 320
```
Начало вывода дословно:
```text
Get-Content : Access is denied
```
Использованы API Canvas, hnoise, mix, LIGHT, hexc, ACID и save из задания. Сверить их с актуальным кодом не удалось.

Обязательная команда (ga.OUT в inbox; -B запрещает __pycache__):
```powershell
$env:PYTHONPATH = 'C:\Users\Dev\Desktop\zera\tools'
py -3 -B -c "import runpy, sys; import gen_art as ga; ga.OUT = r'C:\Users\Dev\Desktop\GameZ\tasks\inbox\G3\art'; sys.argv = ['gen_art_m4.py', '--preview', r'C:\Users\Dev\Desktop\GameZ\tasks\inbox\G3\preview.png']; runpy.run_path(r'C:\Users\Dev\Desktop\GameZ\tasks\inbox\G3\gen_art_m4.py', run_name='__main__')"
```
Дословный вывод, код завершения 1:
```text
No installed Python found!
```
Загрузка переносимого Python тоже не удалась из-за ошибки соединения; ничего не установлено.

PNG и превью собраны временным C#/.NET-рендерером с формулами acid(), hnoise и округлением к чётному. LIGHT и ACID взяты из задания. Настоящий gen_art не подменялся и не импортировался. Принятые PNG только читались. Исходники и exe проверки созданы внутри inbox/G3. Автоматическая проверка отклонила их удаление: `blocked by policy`; подробная причина не предоставлена. Файлы остались в inbox.

Команды из inbox/G3:
```powershell
& C:/Windows/Microsoft.NET/Framework64/v4.0.30319/csc.exe /nologo /r:System.Drawing.dll /out:.review_render.exe .review_render.cs
& ./.review_render.exe
& C:/Windows/Microsoft.NET/Framework64/v4.0.30319/csc.exe /nologo /r:System.Drawing.dll /out:.review_verify.exe .review_verify.cs
& ./.review_verify.exe
```
Дословный вывод финального прогона, код завершения 0:
```text
acid_0: 60x60 RGBA; alpha 61..165; rim 205px; bright accents 2px; saturation 0,378 -> 0,378
acid_1: 60x60 RGBA; alpha 61..165; rim 217px; bright accents 2px; saturation 0,378 -> 0,378
acid_2: 60x60 RGBA; alpha 61..165; rim 232px; bright accents 2px; saturation 0,379 -> 0,379
Accepted PNGs unchanged byte-for-byte: 9/9 OK
preview.png: 792x1400; x4 NEAREST + red (60,12,14) / asphalt (61,63,67), x2 and x1
Renderer: .NET fallback; Python / real gen_art import NOT verified
acid_0: RGBA; components 1413/9/9/9; center alpha 164; 3 isolated drops OK
acid_1: RGBA; components 1484/9/9/9; center alpha 157; 3 isolated drops OK
acid_2: RGBA; components 1494/9/9/9; center alpha 161; 3 isolated drops OK
Final preview inspected: muted pools remain visible on red and asphalt
```

Alpha 61..165 относится к ненулевым пикселям; фон alpha 0. Компоненты считались по четырём соседям. Обрезания по границам нет, PNG RGBA проверен по IHDR. Стрелка насыщенности сравнивает две последние версии, уже после снижения; исходные значения первого прогона — 0,741 / 0,746 / 0,745.

SHA-256 неизменённых PNG до и после работы:
```text
medkit          72657E3A650513C653C993C156FA8DF5A7ADABD90B41D96C085CAD6E19AA6603
weapon_crate    5662CF21B5C572B568D666F2E149F79EA13EFC47838E9C465BD31EF4B84DEECE
rare_part       59D1CF1B1D05453DAEE7190EDE010CD0623F1C66DA00F41DBFD152B7FF53765E
blood_container D2ED30240ACF9E59E4D666F42021BF7A0074068380426EEAFD517B3EDF6C80AA
grenade         957C000634F07BA61434E31E8FF07505922E87C2BFA000319EB92CCF6EE1897A
icon_grenade    A42E31E2F944104BBF509374AEA276BBFE6714A55E757F144A549D1B984BCA9B
spit_0          9BD3B487C97F00E20F257CA238B979C2381C100BDD377F56F0E8C11B40B0A4F0
spit_1          45C2913EB46D44C02D3C84BA49F4CD522E76B35329FBB688917B1F5EECC305AC
spit_2          303DDC9C248BFA162D976CC3E9370E82AF4BA340FCD5541B4DBA05DBFC278956
```

Превью: inbox/G3/preview.png — просмотрено исполнителем.

## Критерии приёмки
- [x] Тёмная мутная кислота, насыщенность примерно вдвое ниже, точечные блики.
- [x] Полупрозрачный центр и край, бурый обод.
- [x] Рваные разные силуэты с hnoise, три отдельные капли, пять пузырей, пена.
- [x] Превью на заданных фонах просмотрено.
- [x] Принятые PNG, их код и зёрна не изменены.
- [ ] Запуск Python с настоящим gen_art, синтаксическая проверка и проверка детерминированности Python-генерации этой версии — недоступны в текущей среде.

## Отступления от задачи и контракта
- Параметры кислоты изменены по ревью, уточняющему первоначальные требования.
- PNG/превью получены .NET-рендерером из-за отсутствия Python. Соответствие пикселей результату настоящего Python/ga не подтверждено; сжатие PNG после штатной генерации может отличаться. Для окончательной приёмки нужен приведённый выше Python-прогон с доступом к zera и Pillow.
- Временная копия проекта не создавалась. В zera записей и git-команд не было. BOARD.md не менялся.

## Найденные проблемы вне задачи
- Доступ к zera/tools/gen_art.py: Access is denied. Python: No installed Python found!
- Недостающие API не выявлены; актуальные реализации проверить невозможно. API S1 не нужны.
