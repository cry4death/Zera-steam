# G1 — hazards.gd: плевки кислотой, кислотные лужи, взрыв толстяка

**Исполнитель:** ChatGPT · **Результат:** один файл `hazards.gd` → сохранить в `GameZ/tasks/inbox/G1/hazards.gd`

---

Ты пишешь один самостоятельный скрипт для игры на **Godot 4.7** (GDScript 2.0).
Игра — top-down пиксельный зомби-шутер в духе Vampire Survivors: сотни зомби, автострельба,
много крови. Код проекта ты не видишь — ниже всё, что тебе можно использовать. **Не выдумывай
методы, которых здесь нет.** Если чего-то не хватает — напиши об этом в пояснении после кода.

## Правила кода

- GDScript со статической типизацией (`var x := 0.0`, `func f(a: int) -> void`), отступы — **табы**.
- Комментарии по-русски, коротко, только где неочевидно. Документирующий комментарий класса `##`.
- Массовые сущности (снаряды, лужи) — в **Packed-массивах** (`PackedVector2Array`, `PackedFloat32Array`),
  не нодами. Удаление — swap-remove (последний на место удаляемого).
- **Нельзя `draw_circle`** — в этой версии он очень медленный. Круглые пятна рисуй через
  `PixelArt.draw_dot(self, center, radius, color)`. `draw_arc`, `draw_texture_rect`, `draw_rect`,
  `draw_line` — можно.
- Если тип не выводится (`:=` от Variant/Array-элемента) — пиши тип явно: `var p: Vector2 = arr[i]`.
- Отдай **файл целиком** одним блоком кода, без «…» и «остальное без изменений».

## Мир

- Единица мира: зомби — круг радиуса 5, игрок — радиус 5. Камера увеличивает ×3.
- Скорость игрока 80 ед/с, бегуна 88, шаркающего 28.
- Нода `Hazards` лежит в `World` между слоем трупов и ордой: всё, что рисуешь в `_draw()`,
  — в координатах мира и оказывается **под** зомби и игроком. Это нормально и для луж, и для плевков.
- Пауза игры (Level Up, торговец) останавливает `_physics_process` — ничего специально делать не нужно.

## API, которые можно использовать

```gdscript
# --- Player (class_name Player, extends Node2D) ---
const RADIUS := 5.0
var global_position: Vector2
var is_dead: bool
func take_damage(amount: float) -> void   # после удара 0.4 с неуязвимости: удары чаще — теряются

# --- Horde (class_name Horde) — все зомби в массивах ---
const RADIUS := 5.0
var count: int
var pos: PackedVector2Array        # позиции, индекс 0..count-1
var dead: PackedByteArray          # 1 — уже мёртв в этом кадре
func query_radius(p: Vector2, r: float) -> PackedInt32Array   # индексы живых в радиусе
## Наносит урон зомби i. Возвращает true, если убил. ВНИМАНИЕ: при смерти синхронно
## испускаются сигналы, и если умер толстяк — тебе же придёт вызов fat_explosion() (см. ниже).
func damage(i: int, amount: float, dir: Vector2, knockback: float, ammo := WeaponDefs.Ammo.STANDARD,
		crit := false, hit_pos := Vector2.INF, explosive := false) -> bool

# --- WeaponDefs ---
enum Ammo { STANDARD, ... }        # используй WeaponDefs.Ammo.STANDARD

# --- FloorDecals (class_name FloorDecals) — пол, на который «запекается» кровь ---
func stamp(tex: Texture2D, pos: Vector2, rot: float, color: Color, scale_factor := 1.0) -> void   # цветная декаль
func blood(tex: Texture2D, pos: Vector2, rot: float, scale_factor := 1.0, thickness := 0.6) -> void # лужа крови
func mark_wet(pos: Vector2, radius: float) -> void   # зомби, прошедшие тут, оставят кровавые следы

# --- Effects (class_name Effects) — частицы ---
func emit(p: Vector2, v: Vector2, life: float, color: Color, size: float, drag: float, bake := false) -> void
	# bake = true — капля по окончании полёта запекается в пол (для крови)
func blood_burst(p: Vector2, dir: Vector2, n: int, speed: float, spread: float) -> void
	# n кровавых капель веером ±spread (рад) вокруг dir (dir — ЕДИНИЧНЫЙ вектор).
	# Во все стороны: dir = Vector2.RIGHT, spread = PI. Vector2.ZERO даст нулевую скорость!

# --- GameCamera ---
func shake(amount: float) -> void   # 1..5 — от лёгкой до сильной

# --- PixelArt (статические) ---
static func draw_dot(ci: CanvasItem, p: Vector2, r: float, color: Color) -> void
static func tex(name: String) -> Texture2D   # load("res://art/%s.png" % name)
const ART_SCALE := 1.0 / 3.0                 # спрайты нарисованы в 3 раза плотнее мира
# текстуры крови: PixelArt.tex("blood_0") .. "blood_7" (белые маски, ~60 px)
```

Проверка наличия арта: `ResourceLoader.exists("res://art/acid_0.png")`.

## Контракт (строго эти имена и сигнатуры)

```gdscript
class_name Hazards
extends Node2D

var horde: Horde
var player: Player
var floor_decals: FloorDecals
var effects: Effects
var camera: GameCamera
var minutes := 0.0            # минуты с начала забега, игра обновляет каждый кадр

func spit(from: Vector2, to: Vector2, damage: float) -> void
func acid_pool(p: Vector2, radius := 20.0, dps := 5.0, duration := 3.0) -> void
func fat_explosion(p: Vector2, is_elite: bool) -> void
func clear() -> void           # убрать всё (рестарт)
func projectile_count() -> int
func pool_count() -> int
```

Любые ссылки (`horde`, `effects`, `camera`, `floor_decals`) могут быть `null` в тестах — проверяй.

## Поведение

**Плевок** (`spit`): снаряд летит прямо из `from` в `to` со скоростью 140 ед/с.
- Каждый кадр: если `player` жив и ближе `Player.RADIUS + 3` — `player.take_damage(damage)`,
  маленький всплеск зелёных частиц, снаряд исчезает (лужи **нет**).
- Долетел до `to` — исчезает и создаёт `acid_pool(to)` + всплеск брызг.
- Вид: ярко-кислотная капля (≈ `Color(0.62, 0.85, 0.2)`) радиуса 2 с тёмным краем, за ней хвост из
  2–3 затухающих точек; лёгкое «бульканье» размера. Если есть `res://art/spit_0..2.png` — рисуй
  кадрами (смена 12 кадров/с, поворот по направлению, масштаб `PixelArt.ART_SCALE`).
- Капля летит низко: рисуй под ней маленькую тёмную тень.

**Лужа** (`acid_pool`): живёт `duration` с; последние 0.8 с плавно исчезает.
- Игрок внутри радиуса: урон **тиком раз в 0.5 с** по `dps * 0.5`. Таймер тика — общий для
  игрока (стоит в двух лужах — урон не удваивается).
- Зомби кислота не ранит.
- Вид: неровное пятно из 5–8 `draw_dot` разного размера (форма фиксирована на всю жизнь лужи —
  храни зерно), цвет грязно-кислотный полупрозрачный (`Color(0.45, 0.62, 0.12, 0.55)`),
  светлее к центру, редкие пузыри (маленькие светлые точки появляются и лопаются).
  Если есть `res://art/acid_0..2.png` — используй текстуру (случайная из трёх, поворот, масштаб под
  радиус: текстура 60 px арта = радиус 20 мира при масштабе `ART_SCALE`), пузыри — поверх.
- Лужа слегка разъедает пол: при появлении один `floor_decals.stamp(PixelArt.tex("blood_N"), p, rot,
  Color(0.16, 0.2, 0.05, 0.35), radius / 30.0)` — тёмный выжженный след останется навсегда.
- Лимит 64 луж: при переполнении удаляется самая старая.

**Взрыв толстяка** (`fat_explosion`): толстяк лопается, как мешок гноя и крови.
- Вызов **не взрывает сразу**, а кладёт взрыв в очередь. В `_physics_process` выполняется не
  больше 8 взрывов за кадр (остальные — в следующих кадрах). Так цепочка толстяков рвётся
  красиво «каскадом» и не вешает кадр. Взрыв, добавленный во время обработки очереди, выполняется
  уже в следующем кадре.
- Радиус `r = 48` (элитка ×1.5).
- Игрок ближе `r` — `take_damage(30 * (1 + 0.05 * minutes))`, у элитки ×1.3.
- Зомби в `horde.query_radius(p, r)`: урон `40 * (1 - 0.5 * clamp(d / (r + Horde.RADIUS), 0, 1))`,
  направление — от центра (если совпадает — случайное), отброс 140, `explosive = true`.
  Перед уроном проверяй `horde.dead[j] == 0`.
- Мясо: `effects.blood_burst(p, Vector2.RIGHT, 40, 170, PI)`, 20–30 частиц гноя (желто-зелёные,
  `bake = false`), 8–10 крупных медленных кровавых капель `bake = true`; на пол —
  `floor_decals.blood(...)` 2–3 штуки масштабом 1.6–2.4 и толщиной 0.9, `mark_wet(p, r * 0.6)`.
- Вспышка: расширяющееся кольцо (`draw_arc`, 0.25 с, от 0.3r до r, цвет грязно-жёлтый → прозрачный)
  и короткий тёмный «дымный» диск под ним.
- `camera.shake(...)`: 4 если игрок ближе 150, иначе меньше по расстоянию, дальше 300 — нет.

## Производительность

В пике: 40 плевков, 64 лужи, 8 взрывов в кадре, 500 зомби. Без аллокаций в горячем цикле
(кроме `query_radius`), без нод на сущность, `queue_redraw()` только если есть что рисовать.

## Что отдать

1. `hazards.gd` целиком.
2. Короткий список: что сделано по-своему и почему; какие API не хватило.
