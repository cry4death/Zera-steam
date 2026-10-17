# Промт для ChatGPT: экран лавки торговца (Godot 4.7, GDScript)

Скопируй всё ниже линии в ChatGPT. Ответ — один файл `scripts/trader_ui.gd`, его пришлёшь мне.

---

Ты — опытный разработчик игр на Godot 4.7 (GDScript 2.0, статическая типизация). Помоги написать один файл для моей игры.

## Об игре

Zera — top-down roguelite в пиксель-арте, «мясной Vampire Survivors»: орды зомби, автострельба, модульное оружие. У игрока до 4 стволов; каждый ствол = основа (автомат/дробовик/рейлган/гранатомёт) + патроны (стандартные/экспансивные/зажигательные/крио, ранги I–III) + модули (до 3 слотов, ранги I–III, бывают редкие). На 5:00 и 9:00 забега прилетает торговец: игрок тратит кредиты, выпавшие из зомби. Игра на паузе, пока открыта лавка.

## Задача

Напиши файл **`scripts/trader_ui.gd`** — экран лавки торговца. Логика лавки уже готова в `trader.gd` (ниже) — экран только показывает состояние и вызывает её методы. Другие файлы менять нельзя.

### Контракт (обязательно, на него завязана игра)

```gdscript
extends Control
signal closed  # игрок закрыл лавку — игра снимет паузу и уберёт экран

func open(trader: Trader, progression: Progression, weapons: Weapons, minutes: float) -> void
func close() -> void   # скрыть экран и испустить closed
```

- Узел лежит в `CanvasLayer`, растянут на весь экран (anchors full rect). В `_ready()` поставь `process_mode = Node.PROCESS_MODE_ALWAYS`, `visible = false`, `mouse_filter = Control.MOUSE_FILTER_STOP`.
- Пока лавка открыта, `get_tree().paused == true` (ставит игра). Сам паузу не трогай.
- `minutes` — минута забега, нужна для `trader.reroll(minutes)`.
- Подпишись на `trader.changed` (перерисовка). При повторном `open()` не подписывайся дважды.

### Что должно быть на экране

1. Заголовок «ТОРГОВЕЦ» и баланс кредитов (`trader.credits()`), заметно.
2. Позиции `trader.offers` (4 или 5) — карточками в ряд, как карты Level Up (стиль ниже): тип, название, описание из `progression.describe(card)`, ранги I/II/III (если есть ключ "ranks"), цена. Проданное — помечено «ПРОДАНО» и приглушено; недоступное (`not trader.can_buy(i)`) — цена красным/серым. Номер позиции 1–5.
3. Кнопки-действия внизу: **Лечение** (`trader.heal_price()`, `can_heal()`, `buy_heal()`, +50 HP), **Реролл** (`trader.reroll_price`, `reroll(minutes)`), **Переставить модуль** (цена `trader.move_price()`, первая бесплатная — покажи «бесплатно»), **В бой** (закрыть).
4. Покупка модуля или патронов — второй шаг «КУДА ПОСТАВИТЬ»: список стволов с тем, что произойдёт (`progression.slot_status(card, i)`; пустая строка — нельзя, показать «нет места»), сводка ствола (патроны, модули с рангами, «слоты x/y»), подсказка прототипа `progression.prototype_hint(card, i)` если не пустая. Покупка: `trader.buy(i, slot)`. Esc — назад.
5. Режим перестановки модуля (три шага): выбрать ствол-источник → выбрать его модуль → выбрать ствол-цель. Доступность цели — `trader.can_move(from, module_index, to)`. Выполнить — `trader.move_module(from, module_index, to)`. Esc — шаг назад.
6. Подсказка по управлению внизу.

### Управление
- Клавиши: `1`–`5` — купить позицию / выбрать ствол или модуль в подшагах; `H` — лечение; `Q` — реролл; `M` — режим перестановки; `Esc` — назад (на верхнем уровне — закрыть); `Space`/`Enter` — в бой (закрыть).
- Мышь: наведение подсвечивает, левый клик — то же, что клавиша. Используй `_gui_input` для мыши и `_unhandled_input` для клавиш (как в `level_up.gd`), помечай ввод обработанным `get_viewport().set_input_as_handled()`.
- Игнорируй ввод первые ~0.25 с после открытия (защита от случайного клика).
- Учитывай раскладку: проверяй `keycode` (как в образце), русская раскладка не должна ломать цифры и Esc/Space/Enter.

### Стиль (важно — как в остальном интерфейсе)
- Весь экран рисуется вручную в `_draw()`. Разметка — в «игровых» пикселях высотой ~360: масштаб `_ui = maxf(1.0, roundf(size.y / 360.0))`, `draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))`, ширина `w = size.x / _ui`.
- Текст — шрифт `ThemeDB.fallback_font`, рисуется в полном разрешении через helper `_text()` (как в образце: сброс трансформа, позиция × `_ui`, размер шрифта × `_ui`, обводка), чтобы был чётким.
- Тёмная полупрозрачная подложка на весь экран, карточки — тёмные прямоугольники с цветной рамкой и полосой сверху; цвета брать из `describe(card)["color"]`. Кредиты — жёлто-золотые (например `Color(1.0, 0.82, 0.35)`).
- Лёгкая анимация появления карточек (как `pop` в образце).
- **Не используй `draw_circle`** — в Godot 4.7 он очень дорогой. Только `draw_rect`, `draw_line`, `draw_string*`.
- Комментарии и строки интерфейса — на русском. Код — типизированный (`var x := ...`, `-> void`, типы параметров).

### Код, на который опираться

`scripts/trader.gd` (логика лавки — используй только её публичные методы и поля):

```gdscript
class_name Trader
extends Node
## Торговец забега (BALANCE.md §9.2): ассортимент, цены, покупки, реролл, лечение,
## перестановка модулей между стволами. Только логика — экран лавки в trader_ui.gd.
##
## Визит 0 — на 5:00 (4 позиции), визит 1 — на 9:00 (5 позиций, цены ×1.5).
## Кредиты хранит Progression (progression.credits).

signal changed # что-то куплено/обновлено — экран перерисовывается

const PRICE_COMMON := 40 # обычная деталь (модуль, патроны, пассивка)
const PRICE_RARE := 100 # редкая деталь
const PRICE_WEAPON := 60 # новый ствол
const PRICE_LEVEL := 50 # +уровень ствола
const PRICE_HEAL := 30
const HEAL_AMOUNT := 50.0
const PRICE_REROLL := 10 # растёт на столько же после каждого реролла
const PRICE_MOVE := 30 # перестановка модуля (первая за визит — бесплатно)
const RARE_CHANCE := 0.3 # в лавке редкое попадается чаще, чем в Level Up
const VISITS := [{"slots": 4, "mult": 1.0}, {"slots": 5, "mult": 1.5}]

var progression: Progression
var weapons: Weapons
var player: Player

var visit := 0
## Позиции: {"card": карта в формате Level Up, "price": int, "sold": bool}
var offers: Array[Dictionary] = []
var reroll_price := PRICE_REROLL
var free_moves := 1


## Новый визит: свежий ассортимент, сброс реролла и бесплатной перестановки.
func start_visit(index: int, minutes: float) -> void:
	visit = clampi(index, 0, VISITS.size() - 1)
	reroll_price = _price(PRICE_REROLL)
	free_moves = 1
	_fill(minutes)


func _mult() -> float:
	return VISITS[visit]["mult"]


func _price(base: int) -> int:
	return roundi(base * _mult())


func _fill(minutes: float) -> void:
	offers.clear()
	var want: int = VISITS[visit]["slots"]
	var guard := 0
	while offers.size() < want and guard < 20:
		guard += 1
		for card: Dictionary in progression.make_cards(minutes):
			if offers.size() >= want:
				break
			if _duplicate(card):
				continue
			if card["type"] == "module" or card["type"] == "ammo":
				card["rare"] = randf() < RARE_CHANCE
			offers.append({"card": card, "price": _card_price(card), "sold": false})
	changed.emit()


func _duplicate(card: Dictionary) -> bool:
	for o in offers:
		var c: Dictionary = o["card"]
		if c["type"] == card["type"] and c.get("id", -1) == card.get("id", -1) and c.get("slot", -1) == card.get("slot", -1):
			return true
	return false


func _card_price(card: Dictionary) -> int:
	match card["type"]:
		"weapon":
			return _price(PRICE_WEAPON)
		"level":
			return _price(PRICE_LEVEL)
		"module", "ammo":
			return _price(PRICE_RARE if card.get("rare", false) else PRICE_COMMON)
	return _price(PRICE_COMMON)


func credits() -> int:
	return progression.credits


func can_afford(price: int) -> bool:
	return progression.credits >= price


## Можно ли купить позицию i прямо сейчас (не продана, хватает денег, есть куда поставить).
func can_buy(i: int) -> bool:
	if i < 0 or i >= offers.size() or offers[i]["sold"] or not can_afford(offers[i]["price"]):
		return false
	var card: Dictionary = offers[i]["card"]
	if Progression.needs_slot(card):
		for s in weapons.slots.size():
			if progression.slot_status(card, s) != "":
				return true
		return false
	if card["type"] == "weapon":
		return weapons.slots.size() < WeaponDefs.MAX_SLOTS and not weapons.has_base(card["id"])
	if card["type"] == "level":
		return weapons.slots[card["slot"]].level < WeaponDefs.MAX_LEVEL
	return true


## Купить позицию i. Для модуля и патронов нужен slot — ствол, куда ставить.
func buy(i: int, slot := -1) -> bool:
	if not can_buy(i):
		return false
	var card: Dictionary = offers[i]["card"]
	if Progression.needs_slot(card) and (slot < 0 or slot >= weapons.slots.size() or progression.slot_status(card, slot) == ""):
		return false
	progression.credits -= offers[i]["price"]
	offers[i]["sold"] = true
	progression.apply(card, slot, false)
	changed.emit()
	return true


func heal_price() -> int:
	return _price(PRICE_HEAL)


func can_heal() -> bool:
	return can_afford(heal_price()) and player.hp < player.max_hp


func buy_heal() -> bool:
	if not can_heal():
		return false
	progression.credits -= heal_price()
	player.hp = minf(player.hp + HEAL_AMOUNT, player.max_hp)
	changed.emit()
	return true


func reroll(minutes: float) -> bool:
	if not can_afford(reroll_price):
		return false
	progression.credits -= reroll_price
	reroll_price += _price(PRICE_REROLL)
	_fill(minutes)
	return true


func move_price() -> int:
	return 0 if free_moves > 0 else _price(PRICE_MOVE)


## Можно ли переставить модуль module_index со ствола from_slot на to_slot.
## Если на целевом стволе такой модуль уже есть — ранги складываются (максимум III).
func can_move(from_slot: int, module_index: int, to_slot: int) -> bool:
	if from_slot == to_slot or not can_afford(move_price()):
		return false
	if from_slot < 0 or from_slot >= weapons.slots.size() or to_slot < 0 or to_slot >= weapons.slots.size():
		return false
	var src: Weapons.Slot = weapons.slots[from_slot]
	if module_index < 0 or module_index >= src.modules.size():
		return false
	var m: Dictionary = src.modules[module_index]
	var dst: Weapons.Slot = weapons.slots[to_slot]
	var have := dst.module(m["id"])
	if not have.is_empty():
		return int(have["rank"]) < WeaponDefs.MAX_RANK
	return dst.modules.size() < WeaponDefs.module_slots(dst.level)


func move_module(from_slot: int, module_index: int, to_slot: int) -> bool:
	if not can_move(from_slot, module_index, to_slot):
		return false
	progression.credits -= move_price()
	if free_moves > 0:
		free_moves -= 1
	var src: Weapons.Slot = weapons.slots[from_slot]
	var dst: Weapons.Slot = weapons.slots[to_slot]
	var m: Dictionary = src.modules[module_index]
	src.modules.remove_at(module_index)
	var have := dst.module(m["id"])
	if have.is_empty():
		dst.modules.append(m)
	else:
		have["rank"] = mini(int(have["rank"]) + int(m["rank"]), WeaponDefs.MAX_RANK)
		have["rare"] = have["rare"] or m["rare"]
	weapons.refresh(from_slot)
	weapons.refresh(to_slot)
	changed.emit()
	return true
```

Фрагменты `scripts/progression.gd` (класс `Progression`; также есть поля `credits: int`, `level: int`):

```gdscript
## Нужно ли выбирать ствол для карты (модуль, патроны).
static func needs_slot(card: Dictionary) -> bool:
	return card["type"] == "module" or card["type"] == "ammo"

## Что будет со стволом i, если поставить модуль m; пустая строка — нельзя.
func module_status(i: int, m: int) -> String:
	var s: Weapons.Slot = weapons.slots[i]
	var have := s.module(m)
	if not have.is_empty():
		var r: int = have["rank"]
		return "" if r >= WeaponDefs.MAX_RANK else "%s → %s" % [WeaponDefs.ROMAN[r], WeaponDefs.ROMAN[r + 1]]
	var free := WeaponDefs.module_slots(s.level) - s.modules.size()
	return "новый слот" if free > 0 else ""

func slot_status(card: Dictionary, i: int) -> String:
	return module_status(i, card["id"]) if card["type"] == "module" else ammo_status(i, card["id"])

## Подсказка: поставить эту деталь на ствол i — шаг к прототипу?
func prototype_hint(card: Dictionary, i: int) -> String:
	var s: Weapons.Slot = weapons.slots[i]
	for r: Dictionary in WeaponDefs.PROTOTYPES:
		if s.base != r["base"]:
			continue
		var fits: bool = (card["type"] == "module" and card["id"] == r["module"]) or (card["type"] == "ammo" and card["id"] == r["ammo"])
		if fits:
			return "◆ рецепт «%s»" % r["name"]
	return ""

## {kind, title, lines, color} для отрисовки карты.
func describe(card: Dictionary) -> Dictionary:
	var rare: bool = card.get("rare", false)
	match card["type"]:
	# ... (возвращает {"kind", "title", "lines": Array[String], "color": Color} и у модулей/патронов ещё "ranks": [3 строки])
```

Класс ствола из `scripts/weapons.gd` (`weapons.slots: Array[Weapons.Slot]`):

```gdscript
## Один ствол игрока.
class Slot:
	var base := 0
	var level := 1
	var ammo := 0
	var ammo_rank := 1
	var ammo_rare := false
	var modules: Array[Dictionary] = [] # {"id", "rank", "rare"}
	var prototype := -1 # индекс в WeaponDefs.PROTOTYPES
	var mag := 0
	var reloading := false
	var reload_t := 0.0
	var cooldown := 0.0
	var stats := {}

	func module(id: int) -> Dictionary:
		for m in modules:
			if m["id"] == id:
				return m
		return {}

	## Значение модуля по рангу с учётом редкости (редкий — ×1.5 к ключевому числу).
	func mod_value(id: int, values: Array, rare_mult := WeaponDefs.RARE_MULT) -> float:
		var m := module(id)
		if m.is_empty():
			return 0.0
		var v: float = values[int(m["rank"]) - 1]
		return v * rare_mult if m["rare"] else v

	func mod_rank(id: int) -> int:
		var m := module(id)
		return 0 if m.is_empty() else int(m["rank"])
```

`scripts/weapon_defs.gd` (данные):

```gdscript
enum Base { RIFLE, SHOTGUN, RAIL, LAUNCHER }
## Патроны задают тип смерти (GDD §5.3).
enum Ammo { STANDARD, EXPANSIVE, INCENDIARY, CRYO }
enum Module { RICOCHET, PIERCE, SPLIT, DETONATOR, TWIN, CHAIN }
enum Passive { DAMAGE, FIRE_RATE, RELOAD, SPEED, HP, PICKUP }

const MAX_SLOTS := 4
const MAX_LEVEL := 5
const MAX_RANK := 3
const MAX_PASSIVE := 5
const RARE_MULT := 1.5
const ROMAN := ["", "I", "II", "III", "IV", "V"]

# BASES[base]   — словарь: "name", "short" (короткое имя ствола), "desc", статы, "levels"
# AMMO[id]      — словарь: "name", "desc", "ranks" (3 строки)
# MODULES[id]   — словарь: "name", "desc", "ranks" (3 строки)
# PROTOTYPES    — массив рецептов: "name", "base", "ammo", "module", "desc"

## Сколько слотов модулей у ствола данного уровня: ур.1–2 → 1, ур.3–4 → 2, ур.5 → 3.
static func module_slots(level: int) -> int:
	return 1 if level < 3 else (2 if level < 5 else 3)
```

Образец стиля и устройства экрана — `scripts/level_up.gd` (экран Level Up; повтори подход к отрисовке, вводу, масштабу и тексту):

```gdscript
extends Control
## Экран Level Up: 3 карты на выбор (клавиши 1–3 или мышь), Q — реролл.
## Модуль и патроны требуют второго шага — выбрать ствол (1–4), Esc — назад.
## Работает на паузе (process_mode = ALWAYS), рисуется в «игровых» пикселях, как HUD.

signal chosen(card: Dictionary, slot: int)
signal reroll_requested

const CARD_W := 150.0
const CARD_H := 138.0
const GAP := 12.0
const FONT := 10

var progression: Progression
var weapons: Weapons
var cards: Array = []
var _card: Dictionary = {} # выбранная карта на шаге выбора ствола
var _ui := 3.0
var _rects: Array[Rect2] = []
var _hover := -1
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func open(new_cards: Array) -> void:
	cards = new_cards
	_card = {}
	_t = 0.0
	visible = true
	queue_redraw()


func close() -> void:
	visible = false


func _process(delta: float) -> void:
	if visible:
		_t += delta
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	var mm := event as InputEventMouseMotion
	if mm:
		_hover = _rect_at(mm.position / _ui)
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _t > 0.25:
		var i := _rect_at(mb.position / _ui)
		if i != -1:
			_pick(i)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or _t < 0.25:
		return
	match key.keycode:
		KEY_1, KEY_KP_1:
			_pick(0)
		KEY_2, KEY_KP_2:
			_pick(1)
		KEY_3, KEY_KP_3:
			_pick(2)
		KEY_4, KEY_KP_4:
			_pick(3)
		KEY_Q:
			if _card.is_empty() and progression.rerolls > 0:
				reroll_requested.emit()
		KEY_ESCAPE:
			_card = {}
	get_viewport().set_input_as_handled()


func _rect_at(p: Vector2) -> int:
	for i in _rects.size():
		if _rects[i].has_point(p):
			return i
	return -1


func _pick(i: int) -> void:
	if _card.is_empty():
		if i >= cards.size():
			return
		var card: Dictionary = cards[i]
		if Progression.needs_slot(card):
			_card = card
			_hover = -1
		else:
			chosen.emit(card, -1)
	else:
		if i >= weapons.slots.size() or progression.slot_status(_card, i) == "":
			return
		chosen.emit(_card, i)


func _draw() -> void:
	if not visible:
		return
	_ui = maxf(1.0, roundf(size.y / 360.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))
	var w := size.x / _ui
	var h := size.y / _ui
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, w, h), Color(0.03, 0.0, 0.0, 0.72))
	_rects.clear()
	if _card.is_empty():
		_draw_cards(font, w, h)
	else:
		_draw_slots(font, w, h)


func _draw_cards(font: Font, w: float, h: float) -> void:
	_text_c(font, Vector2(w * 0.5, 60), "УРОВЕНЬ %d" % (progression.level - progression.pending + 1), Color(0.95, 0.85, 0.5), 18)
	_text_c(font, Vector2(w * 0.5, 76), "выбери улучшение", Color(0.7, 0.7, 0.66))
	var total := cards.size() * CARD_W + (cards.size() - 1) * GAP
	var x0 := (w - total) * 0.5
	var y0 := h * 0.5 - CARD_H * 0.5 + 10.0
	for i in cards.size():
		var d := progression.describe(cards[i])
		var pop := clampf(_t * 6.0 - i * 0.6, 0.0, 1.0) # карты выезжают по очереди
		var r := Rect2(x0 + i * (CARD_W + GAP), y0 + (1.0 - pop) * 30.0, CARD_W, CARD_H)
		_rects.append(r)
		var col: Color = d["color"]
		var hover := _hover == i
		draw_rect(r, Color(0.08, 0.07, 0.07, 0.95 * pop))
		draw_rect(r, Color(col, (0.9 if hover else 0.5) * pop), false, 1.0)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), Color(col, 0.8 * pop))
		_text(font, r.position + Vector2(8, 16), d["kind"], Color(col, 0.75 * pop), 8)
		_text(font, r.position + Vector2(8, 32), d["title"], Color(col, pop), 12)
		var y := 50.0
		for line: String in d["lines"]:
			for part in _wrap(font, line, CARD_W - 16.0, 9):
				_text(font, r.position + Vector2(8, y), part, Color(0.8, 0.8, 0.76, pop), 9)
				y += 11.0
		if d.has("ranks"):
			y += 3.0
			for k in 3:
				var rank_line := "%s: %s" % [WeaponDefs.ROMAN[k + 1], d["ranks"][k]]
				for part in _wrap(font, rank_line, CARD_W - 16.0, 8):
					_text(font, r.position + Vector2(8, y), part, Color(0.65, 0.68, 0.72, pop), 8)
					y += 9.5
		_text(font, r.position + Vector2(CARD_W - 14, 16), str(i + 1), Color(1, 1, 1, 0.5 * pop), 10)
	var hint := "1–3 / клик — выбрать"
	if progression.rerolls > 0:
		hint += " · Q — реролл (%d)" % progression.rerolls
	_text_c(font, Vector2(w * 0.5, y0 + CARD_H + 26.0), hint, Color(0.6, 0.6, 0.56), 9)


func _draw_slots(font: Font, w: float, h: float) -> void:
	var d := progression.describe(_card)
	_text_c(font, Vector2(w * 0.5, 70), "КУДА ПОСТАВИТЬ: %s" % d["title"], d["color"], 14)
	var row_w := 300.0
	var row_h := 30.0
	var x0 := (w - row_w) * 0.5
	var y0 := 96.0
	for i in weapons.slots.size():
		var s: Weapons.Slot = weapons.slots[i]
		var status := progression.slot_status(_card, i)
		var ok := status != ""
		var r := Rect2(x0, y0 + i * (row_h + 6.0), row_w, row_h)
		_rects.append(r)
		var col := Color(0.92, 0.9, 0.85) if ok else Color(0.45, 0.45, 0.43)
		draw_rect(r, Color(0.08, 0.07, 0.07, 0.95))
		draw_rect(r, Color(col, 0.9 if (_hover == i and ok) else 0.4), false, 1.0)
		_text(font, r.position + Vector2(8, 13), "%d. %s ур.%d" % [i + 1, WeaponDefs.BASES[s.base]["short"], s.level], col, 11)
		_text(font, r.position + Vector2(8, 25), slot_summary(s), Color(col, 0.7), 8)
		var right := status if ok else "нет места"
		var tw := font.get_string_size(right, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		_text(font, r.position + Vector2(row_w - 8 - tw, 13), right, Color(0.6, 0.9, 0.6) if ok else Color(0.7, 0.4, 0.4), 10)
		var proto := progression.prototype_hint(_card, i)
		if proto != "" and ok:
			var pw := font.get_string_size(proto, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			_text(font, r.position + Vector2(row_w - 8 - pw, 25), proto, Color(1.0, 0.55, 0.3), 8)
	_text_c(font, Vector2(w * 0.5, y0 + weapons.slots.size() * (row_h + 6.0) + 16.0), "1–4 / клик — выбрать ствол · Esc — назад", Color(0.6, 0.6, 0.56), 9)


## Короткая сводка ствола: патроны и модули.
static func slot_summary(s: Weapons.Slot) -> String:
	var parts: Array[String] = ["%s %s" % [WeaponDefs.AMMO[s.ammo]["name"], WeaponDefs.ROMAN[s.ammo_rank]]]
	for m in s.modules:
		parts.append("%s %s" % [WeaponDefs.MODULES[m["id"]]["name"], WeaponDefs.ROMAN[m["rank"]]])
	parts.append("слоты %d/%d" % [s.modules.size(), WeaponDefs.module_slots(s.level)])
	return " · ".join(parts)


func _wrap(font: Font, s: String, max_w: float, fs: int) -> Array[String]:
	var out: Array[String] = []
	var line := ""
	for word in s.split(" "):
		var test := word if line == "" else line + " " + word
		if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w and line != "":
			out.append(line)
			line = word
		else:
			line = test
	if line != "":
		out.append(line)
	return out


func _text(font: Font, p: Vector2, s: String, c: Color, fs := FONT) -> void:
	var k := int(_ui)
	draw_set_transform(Vector2.ZERO)
	draw_string_outline(font, p * _ui, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * k, 2 * k, Color(0, 0, 0, 0.8 * c.a))
	draw_string(font, p * _ui, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * k, c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))


func _text_c(font: Font, p: Vector2, s: String, c: Color, fs := FONT) -> void:
	var tw := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_text(font, Vector2(p.x - tw * 0.5, p.y), s, c, fs)
```

### Формат ответа
Только полный текст файла `scripts/trader_ui.gd` одним блоком кода, без пояснений до и после. Файл должен компилироваться в Godot 4.7 без предупреждений о типах.
