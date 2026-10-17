# Контракты M4 — общие API между задачами

Это единственный источник правды по стыкам. Задача, которая **создаёт** API, обязана его
выполнить буква в букву; задача, которая **использует**, — не полагаться ни на что сверх.
Нужно изменить контракт — сначала согласовать с ревьюером (Opus), он правит этот файл.

Числа — `GameZ/BALANCE.md` §1, §2, §7, §9.

---

## 1. Horde — типы врагов и элитки (создаёт **S1**)

```gdscript
enum Kind { SHAMBLER, RUNNER, FAT, SPITTER }

## Статы на 0:00 (BALANCE §2.1). HP растёт ×(1 + 0.12·мин), урон ×(1 + 0.05·мин).
const KINDS := [
	{"hp": 10.0, "speed": 28.0, "damage": 6.0,  "xp": 1, "credit_chance": 0.06, "credits": 1},  # шаркающий
	{"hp": 6.0,  "speed": 88.0, "damage": 4.0,  "xp": 1, "credit_chance": 0.06, "credits": 1},  # бегун
	{"hp": 60.0, "speed": 20.0, "damage": 10.0, "xp": 4, "credit_chance": 0.40, "credits": 2},  # толстяк
	{"hp": 15.0, "speed": 34.0, "damage": 5.0,  "xp": 2, "credit_chance": 0.20, "credits": 2},  # плевальщик
]
const ELITE_HP := 5.0
const ELITE_DAMAGE := 1.3
const ELITE_SCALE := 1.5   # размер спрайта и радиус попадания/коллизии
const ELITE_SPEED := 1.1
const ELITE_XP := 25
const ELITE_CREDITS := 10

var kind := PackedByteArray()   # Kind
var elite := PackedByteArray()  # 0/1

## Возвращает индекс нового врага или -1 (лимит). Индекс действителен только до конца кадра.
func spawn(p: Vector2, k := Kind.SHAMBLER, is_elite := false) -> int
func spawn_group(center: Vector2, n: int, k := Kind.SHAMBLER) -> void

## Испускается при каждой смерти СРАЗУ ПОСЛЕ enemy_killed (старый сигнал не меняется).
signal enemy_died(pos: Vector2, kind: int, is_elite: bool)
## Плевальщик выстрелил: снаряд летит из from в точку to (где был игрок).
signal spit_fired(from: Vector2, to: Vector2, damage: float)
## Толстяк умер (любым способом) — сам взрыв считает Hazards.
signal fat_burst(pos: Vector2, is_elite: bool)
```

- `variant` (индекс спрайта) по-прежнему хранится и уходит в gore: шаркающий — 0..3
  (случайно, веса как сейчас), бегун — 4, толстяк — 5, плевальщик — 6.
- `player_touched(damage)` — сигнатура прежняя. Каждый зомби бьёт не чаще раза в 0.8 с;
  за кадр испускается **один** сигнал с наибольшим уроном среди ударивших.
- Плевальщик держит дистанцию 130–170 px (ближе — отходит, дальше — подходит),
  плюёт раз в 3 с (±случайная фаза), если игрок в 90–260 px. Урон плевка 10 ×(1 + 0.05·мин), у элитки ×1.3.
- Толстяк при смерти всегда умирает как `Gore.Death.GIBS` (лопается).

## 2. Hazards — плевки, кислота, взрыв толстяка (создаёт **G1**, подключает **S2**)

```gdscript
class_name Hazards
extends Node2D

var horde: Horde
var player: Player
var floor_decals: FloorDecals
var effects: Effects
var camera: GameCamera
var minutes := 0.0            # игра обновляет каждый кадр

func spit(from: Vector2, to: Vector2, damage: float) -> void
func acid_pool(p: Vector2, radius := 20.0, dps := 5.0, duration := 3.0) -> void
func fat_explosion(p: Vector2, is_elite: bool) -> void
func clear() -> void
func projectile_count() -> int
func pool_count() -> int
```

- Плевок: 140 px/с к точке `to`; попал в игрока (дистанция ≤ Player.RADIUS + 3) — `damage`,
  долетел до `to` — кислотная лужа там же.
- Лужа: игрок внутри получает урон **тиками раз в 0.5 с** по `dps × 0.5`
  (тики реже 0.4 с неуязвимости игрока, иначе урон «съедается»). Зомби кислота не ранит.
- Взрыв толстяка: радиус 48 (элитка ×1.5), игроку 30 ×(1 + 0.05·мин) (элитка ×1.3),
  зомби 40 с затуханием к краю, `explosive = true`. Взрывы **ставятся в очередь** и
  выполняются в следующем `_physics_process` (цепные взрывы толстяков — с задержкой кадра,
  максимум 8 за кадр).

## 3. AlarmOverlay — экран кровавой тревоги (создаёт **G2**, подключает **S2**)

```gdscript
class_name AlarmOverlay
extends Control

func warn(seconds: float) -> void   # предупреждение: мигающая надпись, полосы сирены
func start(seconds: float) -> void  # тревога: красный свет, пульс, полоса оставшегося времени
func finish() -> void               # «ТРЕВОГА ОТБИТА» + плавное угасание ~1.5 с
func stop() -> void                 # убрать мгновенно
func is_active() -> bool            # идёт warn или start
```

Пауза игры замораживает экран (обычный process_mode). Мышь не перехватывает.

## 4. Арт M4 (создаёт **G3**, использует **S3**)

`zera/tools/gen_art_m4.py` пишет в `zera/art/`:

| Файл | Размер, px | Что |
|---|---|---|
| `medkit.png` | 15×15 | аптечка на полу |
| `weapon_crate.png` | 21×21 | оружейный ящик (подбор с элитки) |
| `rare_part.png` | 15×15 | редкая деталь (подбор с элитки), синее свечение |
| `blood_container.png` | 42×30 | кровавый контейнер (финал тревоги) |
| `grenade.png` | 9×9 | граната в полёте (вид сверху) |
| `spit_0..2.png` | 9×9 | кадры плевка кислотой |
| `acid_0..2.png` | 60×60 | лужа кислоты (декаль, полупрозрачная) |
| `icon_grenade.png` | 12×12 | иконка активки для HUD |

## 5. Run-статистика (создаёт **S3**)

`game.gd`: `var crates := 0` — оружейные ящики, найденные за забег (открываются на базе в M6).

---

# M5 — босс и финал

## 6. Boss — «Объект-7» (создаёт **G6**, подключает **S4**)

Цифры — `BALANCE.md` §10, поведение — `MVP.md` §6.

```gdscript
class_name Boss
extends Node2D

const RADIUS := 18.0          # радиус попадания и контакта (мир)
const MAX_HP := 24000.0

signal phase_changed(phase: int)              # 2 — при 50% HP: броня сорвана
signal died(pos: Vector2)
signal charge_telegraph(from: Vector2, to: Vector2, time: float)  # начало телеграфа тарана
signal slam_started(pos: Vector2)             # удар по земле: пошла волна
signal roar(count: int)                       # игра спавнит count бегунов вокруг босса
signal crushed(pos: Vector2, dir: Vector2)    # таран раздавил зомби — игра кладёт «лепёшку»
signal armor_plate(pos: Vector2, dir: Vector2) # отлетела пластина (фаза 2 и попадания в фазе 1)

var horde: Horde
var player: Player
var effects: Effects
var floor_decals: FloorDecals
var camera: GameCamera
var arena: Rect2
var minutes := 0.0

var hp := MAX_HP
var phase := 1

func start(p: Vector2) -> void                 # появиться в точке и начать бой
func take_damage(amount: float, dir: Vector2, at: Vector2) -> bool  # true — умер; −25% в фазе 1
func hit_test(p: Vector2, r: float) -> bool    # пересекает ли круг (p, r) босса
func is_alive() -> bool
```

- Сам наносит урон игроку (`player.take_damage`): контакт, таран, кольцо удара по земле.
- Таран давит зомби на пути: `horde.damage(j, 9999.0, dir, 300.0, WeaponDefs.Ammo.STANDARD, false, horde.pos[j], true)` + сигнал `crushed`.
- Рисует себя сам (`_draw`) из `art/boss.png` (раскладка §7), с процедурным запасным вариантом.
- Пауза игры его останавливает (обычный process_mode).

## 7. Арт M5 (создаёт **G4**)

`zera/tools/gen_art_m5.py` (импортирует `gen_art` как `ga`, как G3) пишет в `zera/art/`:

| Файл | Размер, px | Что |
|---|---|---|
| `boss.png` | 720×288 | лист 5×2 ячеек по 144×144. Строка 0 — фаза 1 (броня), строка 1 — фаза 2 (мясо). Столбцы 0–3 — шаги, 4 — поза тарана. Смотрит вправо (+X). |
| `boss_plate_0..3.png` | 30×30 | отлетевшие пластины брони |
| `boss_gib_0..3.png` | 36×36 | крупные куски мяса босса для взрыва смерти |
| `crushed_0..2.png` | 48×48 | раздавленный зомби — «лепёшка», декаль на пол |
| `military_crate.png` | 27×27 | военный ящик (награда за босса) |

## 8. RunResults — экран итогов (создаёт **G5**, подключает **S4**)

```gdscript
class_name RunResults
extends Control

signal restart_requested

## stats:
## {"victory": bool, "time": float (сек), "kills": int, "elites": int, "best_combo": int,
##  "blood_liters": float, "weapons": Array[String] (готовые подписи «АК-С ур.5 · Крио III»),
##  "crates": int, "military_crates": int,
##  "dna_lines": Array[Array] ([подпись: String, значение: int]), "dna_mult": float, "dna_total": int}
func open(stats: Dictionary) -> void
```

- Работает на паузе (`PROCESS_MODE_ALWAYS`), рисуется в «игровых пикселях», как `level_up.gd`.
- `R`/`Enter`/`Space`/клик по кнопке «ЕЩЁ РАЗ» → `restart_requested`. Перезапуск сцены делает игра.

---

# W — огнестрел, звук, отдача, свет (после M4, до S4)

## 9. Звуки (создают **A1**, **A2**; играет **W1** через `Sfx`)

Источник — CC0 «The Free Firearm Sound Library» (Still North Media): реальные записи
стволов. Исходники вне репозитория: `C:\Users\Dev\Desktop\zera-assets\firearm_cc0\`
(`extracted\Prepared SFX Library\` — сведённые выстрелы; `raw_master_tracks.zip` — сырые
дорожки с механикой, опись `master_sheet.xlsx`). В репозиторий попадают только нарезанные файлы.

Генератор `zera/tools/prep_sfx.py` (Python 3 + numpy, детерминирован) пишет в `zera/sfx/`
**WAV 48 кГц 16 бит**. Выстрелы стерео, всё остальное моно. Файлы именуются `<id>_<n>.wav`,
`n` = 0..k (варианты). `id` — путь без индекса:

| id | Что | Источник |
|---|---|---|
| `weapons/<gun>/shot` | одиночный выстрел, вид «у стрелка», хвост ≤ 1.2 с (sniper/shotgun/revolver ≤ 2.5 с), 3–6 вариантов | Prepared, near |
| `weapons/rifle/tail`, `weapons/smg/tail` | хвост очереди ≥3 выстрелов, один раз при паузе >1.5 интервала, перезарядке или смене цели; 3 варианта, моно, 1.05–1.21 с | Prepared, near, отражения без атаки (W2) |
| `weapons/<gun>/mag_out`, `mag_in` | отстегнуть / вставить магазин | Raw (A2) |
| `weapons/<gun>/rack` | досылание: затвор, затворная рама, цевьё помпы | Raw (A2) |
| `weapons/<gun>/dry` | сухой щелчок | Raw (A2) |
| `weapons/revolver/cyl_open`, `cyl_close`, `eject`, `load` | барабан, выброс гильз, заряжание | Raw (A2) |
| `weapons/shotgun/shell_in` | патрон в трубчатый магазин (по одному) | Raw (A2) |
| `casings/brass_small`, `brass_rifle`, `shell` | падение гильзы на асфальт (2–3 отскока), моно, ≥ 6 вариантов | синтез (A1) |
| `casings/mag_drop` | пустой магазин упал на пол | синтез (A1) или Raw (A2) |
| `explosions/grenade` | взрыв гранаты/гранатомёта, ≥ 4 варианта | синтез (A1) |
| `weapons/launcher/shot` | хлопок подствольного гранатомёта | синтез из выстрела дробовика (A1) |
| `weapons/rail/shot` | рельса (единственная «не реальная» пушка) | синтез (A1) |

`<gun>` и запись-источник:

| gun | Ствол в игре | Запись |
|---|---|---|
| `pistol` | Пистолет «Кольт» | 1911 (.45) — `A_*` |
| `revolver` | Револьвер «Бульдог» | S&W 642 (.38) — `V_*` |
| `smg` | ПП «ППШ» | PPSh (7.62×25) — `P_*` |
| `rifle` | Автомат «АК-С» (есть) | AK-47 (7.62×39) — `C_*` |
| `sniper` | Винтовка «Мосинка» | Mosin Nagant (7.62×54R) — `M_*` |
| `shotgun` | Дробовик «Мясник» (есть) | Benelli Nova, помпа (12 к) — `O_*` |

Громкость: пик ≤ −1 dBFS, выстрелы выровнены по ощущению калибра
(sniper ≥ shotgun ≥ rifle ≥ revolver ≥ pistol ≥ smg), механика тише выстрелов на ~12 дБ.
`zera/sfx/CREDITS.md` — источник, лицензия CC0, авторы (Ben Jaszczak, Brian Nelson, Kevin Heras,
Matthew Nanney / Still North Media), таблица «файл ← исходник».

## 10. Sfx — проигрыватель (создаёт **W1**)

```gdscript
class_name Sfx
extends Node

## Грузит все res://sfx/**/<id>_<n>.wav при старте. Нет файлов — тихо ничего не делает.
## pos = Vector2.INF — без позиционирования (оружие игрока), иначе AudioStreamPlayer2D в точке.
func play(id: String, pos := Vector2.INF, volume_db := 0.0, pitch_jitter := 0.05) -> void
func has(id: String) -> bool
```

- Пул голосов (не нода на звук), лимит полифонии и минимальный интервал на `id`
  (ППШ 15 выстр./с не забивает микс), вытеснение самого старого.
- Шины: `Master` (лимитер), `Weapons`, `World` — в `default_bus_layout.tres`.
- `--headless` и тесты работают без звука и без ошибок.
