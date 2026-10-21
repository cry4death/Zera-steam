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
		for card: Dictionary in progression.make_cards(minutes, false):
			if offers.size() >= want:
				break
			if _duplicate(card):
				continue
			if card["type"] == "module" or card["type"] == "ammo":
				card["rare"] = randf() < RARE_CHANCE
			offers.append({"card": card, "price": _card_price(card), "sold": false})
	if visit == 0 and progression.focus_overflow and progression.can_offer_link():
		var directed := {"type": "link", "id": WeaponDefs.Module.LINK, "rare": false}
		if not _duplicate(directed): offers[0] = {"card": directed, "price": _price(PRICE_COMMON), "sold": false}
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
	if card["type"] == "link":
		var partner := weapons.slot_by_uid(int(card.get("partner_uid", 0)))
		if not weapons.link_available(slot, partner) or partner < 0: return false
		if not weapons.install_link(slot, partner, card.get("replacement", {})): return false
	progression.credits -= offers[i]["price"]
	offers[i]["sold"] = true
	if card["type"] != "link": progression.apply(card, slot, false)
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
	if from_slot < 0 or from_slot >= weapons.slots.size() or to_slot < 0 or to_slot >= weapons.slots.size():
		return false
	var src: Weapons.Slot = weapons.slots[from_slot]
	if module_index < 0 or module_index >= src.modules.size():
		return false
	var m: Dictionary = src.modules[module_index]
	var dst: Weapons.Slot = weapons.slots[to_slot]
	if int(m["id"]) == WeaponDefs.Module.LINK:
		return (not m["active"] or can_afford(move_price())) and weapons.link_available(to_slot, -1, m)
	if from_slot == to_slot or not can_afford(move_price()): return false
	if not WeaponDefs.supports_module(dst.base, m["id"]): return false
	if dst.base == WeaponDefs.Base.LAUNCHER and (int(m["id"]) == WeaponDefs.Module.RICOCHET or (int(m["id"]) == WeaponDefs.Module.CHAIN and dst.mod_rank(WeaponDefs.Module.DETONATOR) == 0)): return false
	var have := dst.module(m["id"])
	if not have.is_empty():
		return int(have["rank"]) < WeaponDefs.MAX_RANK
	return dst.modules.size() < WeaponDefs.module_slots(dst.level)


func move_module(from_slot: int, module_index: int, to_slot: int, partner := -1, replacement: Dictionary = {}) -> bool:
	if not can_move(from_slot, module_index, to_slot):
		return false
	var link: Dictionary = weapons.slots[from_slot].modules[module_index]
	if int(link["id"]) == WeaponDefs.Module.LINK:
		var cost := move_price() if link["active"] else 0
		if partner < 0: partner = weapons.slot_by_uid(int(link["partner_weapon_uid"]))
		var was_active: bool = link["active"]
		if not weapons.rebind_link(link, to_slot, partner, replacement): return false
		progression.credits -= cost
		if was_active and free_moves > 0: free_moves -= 1
		changed.emit()
		return true
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
