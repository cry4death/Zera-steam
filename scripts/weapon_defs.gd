class_name WeaponDefs
## Данные модульного оружия (GDD §5, BALANCE.md §3–6): основы, патроны, модули, пассивки.
## Только описания и цифры — логика стрельбы в weapons.gd, выбор карт в progression.gd.

enum Base { RIFLE, SHOTGUN, RAIL, LAUNCHER, PISTOL, REVOLVER, SMG, SNIPER }
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

## Статы основы на ур.1 и прибавки за уровни 2..5. Ключи *_mul — множители, остальные — прибавки.
## Расстояния — в игровых единицах.
const BASES := {
	Base.RIFLE: {
		"name": "Автомат АК-С", "short": "АК-С", "desc": "Очереди в ближайшего врага",
		"damage": 7.0, "rate": 6.0, "mag": 30, "reload": 1.5, "range": 220.0, "spread": 4.0,
		"speed": 450.0, "proj": 1, "knock": 50.0, "crit": 0.0,
		"levels": [
			{}, {"damage": 2.0, "text": "урон +2"},
			{"mag": 15, "rate_mul": 1.15, "text": "магазин +15, скорострельность +15%"},
			{"proj": 1, "text": "+1 пуля за выстрел"},
			{"damage": 4.0, "reload_mul": 0.7, "text": "урон +4, перезарядка −30%"},
		],
	},
	Base.SHOTGUN: {
		"name": "Дробовик «Мясник»", "short": "Мясник", "desc": "Веер дроби в упор — рвёт толпу",
		"damage": 5.0, "rate": 1.1, "mag": 6, "reload": 2.2, "range": 130.0, "spread": 30.0,
		"speed": 380.0, "proj": 6, "knock": 40.0, "crit": 0.0,
		"levels": [
			{}, {"proj": 2, "text": "+2 дробины"},
			{"damage": 2.0, "text": "урон +2"},
			{"mag": 2, "reload_mul": 0.8, "text": "магазин +2, перезарядка −20%"},
			{"proj": 3, "knock_mul": 2.0, "text": "+3 дробины, отброс ×2"},
		],
	},
	Base.RAIL: {
		"name": "Рейлган «Игла»", "short": "Игла", "desc": "Луч пробивает всю линию",
		"damage": 30.0, "rate": 0.7, "mag": 4, "reload": 2.5, "range": 320.0, "width": 6.0,
		"proj": 1, "knock": 70.0, "crit": 0.1,
		"levels": [
			{}, {"damage": 15.0, "text": "урон +15"},
			{"mag": 2, "text": "магазин +2"},
			{"width_mul": 2.0, "rate_mul": 1.2, "text": "ширина луча ×2, скорострельность +20%"},
			{"damage": 25.0, "crit": 0.15, "text": "урон +25, крит +15%"},
		],
	},
	Base.LAUNCHER: {
		"name": "Гранатомёт «Гром»", "short": "Гром", "desc": "Граната с взрывом по площади",
		"damage": 22.0, "rate": 0.8, "mag": 4, "reload": 2.8, "range": 200.0, "radius": 40.0,
		"speed": 260.0, "proj": 1, "knock": 120.0, "crit": 0.0,
		"levels": [
			{}, {"radius": 10.0, "text": "радиус +10"},
			{"damage": 10.0, "text": "урон +10"},
			{"proj": 1, "text": "+1 граната за выстрел"},
			{"damage": 10.0, "radius": 10.0, "reload_mul": 0.7, "text": "урон +10, радиус +10, перезарядка −30%"},
		],
	},
	Base.PISTOL: {
		"name": "Пистолет «Кольт»", "short": "Кольт", "desc": "Точная .45, быстрый магазин, +10% крит",
		"damage": 14.0, "rate": 3.0, "mag": 7, "reload": 1.1, "range": 180.0, "spread": 2.0,
		"speed": 450.0, "proj": 1, "knock": 35.0, "crit": 0.1,
		"levels": [{}, {"damage": 4.0, "text": "урон +4"},
			{"mag": 3, "rate_mul": 1.15, "text": "магазин +3, скорострельность +15%"},
			{"crit": 0.1, "range": 20.0, "text": "+10% крит, дальность +20"},
			{"damage": 8.0, "reload_mul": 0.7, "text": "урон +8, перезарядка −30%"}],
	},
	Base.REVOLVER: {
		"name": "Револьвер «Бульдог»", "short": "Бульдог", "desc": "Пробивает одного насквозь, мощный отброс",
		"damage": 30.0, "rate": 1.5, "mag": 6, "reload": 2.4, "range": 210.0, "spread": 3.0,
		"speed": 460.0, "proj": 1, "knock": 90.0, "crit": 0.0, "pierce": 1,
		"levels": [{}, {"damage": 10.0, "text": "урон +10"},
			{"rate_mul": 1.2, "text": "скорострельность +20%"},
			{"knock_mul": 1.5, "crit": 0.1, "text": "отброс ×1.5, +10% крит"},
			{"damage": 16.0, "reload_mul": 0.75, "text": "урон +16, перезарядка −25%"}],
	},
	Base.SMG: {
		"name": "ПП «ППШ»", "short": "ППШ", "desc": "Диск на 71 патрон, растущий разброс очереди",
		"damage": 4.0, "rate": 14.0, "mag": 71, "reload": 2.6, "range": 165.0, "spread": 8.0,
		"speed": 430.0, "proj": 1, "knock": 18.0, "crit": 0.0,
		"levels": [{}, {"damage": 1.0, "text": "урон +1"},
			{"mag": 20, "rate_mul": 1.1, "text": "магазин +20, скорострельность +10%"},
			{"proj": 1, "text": "+1 пуля за выстрел"},
			{"damage": 2.0, "reload_mul": 0.75, "text": "урон +2, перезарядка −25%"}],
	},
	Base.SNIPER: {
		"name": "Винтовка «Мосинка»", "short": "Мосинка", "desc": "Затвор, пробивает троих, +15% крит",
		"damage": 48.0, "rate": 0.8, "mag": 5, "reload": 3.0, "range": 360.0, "spread": 1.0,
		"speed": 500.0, "proj": 1, "knock": 110.0, "crit": 0.15, "pierce": 3,
		"levels": [{}, {"damage": 16.0, "text": "урон +16"},
			{"mag": 2, "text": "магазин +2"},
			{"rate_mul": 1.15, "crit": 0.1, "text": "скорострельность +15%, +10% крит"},
			{"damage": 26.0, "reload_mul": 0.75, "text": "урон +26, перезарядка −25%"}],
	},
}

## Патроны: индексы совпадают с Weapon.Ammo (STANDARD, EXPANSIVE, INCENDIARY, CRYO).
const AMMO := [
	{"name": "Стандартные", "desc": "+10% шанс крита; крит взрывает голову",
		"ranks": ["+10% крит", "+15% крит", "крит ×2.5"]},
	{"name": "Экспансивные", "desc": "Всплеск урона вокруг цели; убитых рвёт на куски",
		"ranks": ["всплеск 30%", "всплеск 45%", "всплеск и при убийстве"]},
	{"name": "Зажигательные", "desc": "Поджигают; горящие трупы поджигают соседей",
		"ranks": ["огонь 4/с", "огонь 6/с", "огонь перекидывается вдвое дальше"]},
	{"name": "Крио", "desc": "Замедляют и замораживают; замёрзших раскалывает",
		"ranks": ["заморозка с 4 попаданий", "заморозка с 3 попаданий", "осколки ранят и морозят соседей"]},
]

const MODULES := {
	Module.RICOCHET: {"name": "Рикошет", "desc": "Снаряд отскакивает к следующей цели",
		"ranks": ["1 отскок", "2 отскока", "3 отскока"]},
	Module.PIERCE: {"name": "Пробивание", "desc": "Снаряд проходит сквозь врагов",
		"ranks": ["сквозь 2", "сквозь 4", "сквозь 6, +20% урона за каждого"]},
	Module.SPLIT: {"name": "Сплит", "desc": "При попадании разлетается осколками",
		"ranks": ["3 осколка", "4 осколка", "5 осколков"]},
	Module.DETONATOR: {"name": "Детонатор", "desc": "Убитые этим стволом взрываются",
		"ranks": ["шанс 25%", "шанс 40%", "шанс 60%, взрывы цепляют друг друга"]},
	Module.TWIN: {"name": "Сдвоенный ствол", "desc": "Больше снарядов за выстрел",
		"ranks": ["+1 снаряд", "+2 снаряда", "+3 снаряда веером"]},
	Module.CHAIN: {"name": "Цепь", "desc": "Убийство выпускает снаряд в соседа",
		"ranks": ["50% урона", "65% урона", "80%, цепь до 3 звеньев"]},
}

const PASSIVES := {
	Passive.DAMAGE: {"name": "Боевые стимуляторы", "per_level": 0.10, "text": "+10% урона"},
	Passive.FIRE_RATE: {"name": "Облегчённый затвор", "per_level": 0.08, "text": "+8% скорострельности"},
	Passive.RELOAD: {"name": "Быстрые руки", "per_level": 0.08, "text": "−8% времени перезарядки"},
	Passive.SPEED: {"name": "Экзоскелет", "per_level": 0.06, "text": "+6% скорости"},
	Passive.HP: {"name": "Бронежилет", "per_level": 20.0, "text": "+20 макс. HP"},
	Passive.PICKUP: {"name": "Сборщик образцов", "per_level": 0.25, "text": "+25% радиуса подбора"},
}

## Прототипы: основа на ур.5 + патроны + модуль.
const PROTOTYPES := [
	{"name": "МЯСОРУБКА", "base": Base.SHOTGUN, "ammo": 1, "module": Module.DETONATOR,
		"desc": "каждое убийство взрывается, взрывы цепляют друг друга"},
	{"name": "АБСОЛЮТНЫЙ НОЛЬ", "base": Base.RAIL, "ammo": 3, "module": Module.PIERCE,
		"desc": "луч мгновенно замораживает всю линию"},
]


## Статы основы с учётом уровня (без пассивок и модулей).
static func base_stats(base: int, level: int) -> Dictionary:
	var d: Dictionary = BASES[base]
	var s := {}
	for k in ["damage", "rate", "mag", "reload", "range", "spread", "speed", "proj", "knock", "crit", "width", "radius", "pierce"]:
		if d.has(k):
			s[k] = d[k]
	var levels: Array = d["levels"]
	for l in range(1, mini(level, levels.size())):
		var up: Dictionary = levels[l]
		for k: String in up:
			if k == "text":
				continue
			if k.ends_with("_mul"):
				var key := k.trim_suffix("_mul")
				s[key] = s[key] * up[k]
			else:
				s[k] = s.get(k, 0) + up[k]
	return s


static func module_slots(level: int) -> int:
	return 1 if level < 3 else (2 if level < 5 else 3)
