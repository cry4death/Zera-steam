class_name WeaponDefs
## Данные модульного оружия (GDD §5, BALANCE.md §3–6): основы, патроны, модули, пассивки.
## Только описания и цифры — логика стрельбы в weapons.gd, выбор карт в progression.gd.

enum Base { RIFLE, SHOTGUN, RAIL, LAUNCHER, PISTOL, REVOLVER, SMG, SNIPER, LMG, MINIGUN, FLAMER, SAW, CROSSBOW, AUTO_SHOTGUN, DMR, TESLA }
## Патроны задают тип смерти (GDD §5.3).
enum Ammo { STANDARD, EXPANSIVE, INCENDIARY, CRYO }
enum Module { RICOCHET, PIERCE, SPLIT, DETONATOR, TWIN, CHAIN, LINK }
enum Passive { DAMAGE, FIRE_RATE, RELOAD, SPEED, HP, PICKUP }
## Редкость модели: серийная доступна с начала, обычная и редкая выпадают из ящиков (CONTRACTS §11).
enum Rarity { SERIAL, COMMON, RARE }

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
	},	Base.LMG: {
		"name": "Пулемёт ПКМ", "short": "ПКМ", "desc": "Лента, упор и длительная очередь",
		"damage": 5.0, "rate": 9.0, "mag": 90, "reload": 3.2, "range": 250, "spread": 10.0,
		"proj": 1, "knock": 45, "speed": 450, "crit": 0.0, "pierce": 0,
		"levels": [{}, {"damage": 1.25, "text": "урон +25% от L1"},
			{"mag": 32, "text": "увеличенный запас"},
			{"rate_mul": 1.15, "proj": 1, "text": "темп +15%, +1 пуля"},
			{"damage": 2.0, "reload_mul": 0.75, "text": "урон +40% от L1, перезарядка −25%"}],
	},
	Base.MINIGUN: {
		"name": "Миниган М134", "short": "М134", "desc": "Вращающийся блок стволов",
		"damage": 3, "rate": 24, "mag": 180, "reload": 4.2, "range": 175, "spread": 17,
		"proj": 1, "knock": 15, "speed": 470, "crit": 0.0, "pierce": 0,
		"levels": [{}, {"damage": 0.75, "text": "урон +25% от L1"},
			{"mag": 63, "text": "увеличенный запас"},
			{"rate_mul": 1.35, "damage": 1.0, "text": "темп +35%, урон +1"},
			{"damage": 1.2, "reload_mul": 0.75, "text": "урон +40% от L1, перезарядка −25%"}],
	},
	Base.FLAMER: {
		"name": "Огнемёт ЛПО", "short": "ЛПО", "desc": "Топливная струя ближнего действия",
		"damage": 2.4, "rate": 8, "mag": 60, "reload": 3, "range": 85, "spread": 44,
		"proj": 1, "knock": 8, "speed": 250, "crit": 0.0, "pierce": 0,
		"levels": [{}, {"damage": 0.6, "text": "урон +25% от L1"},
			{"mag": 21, "text": "увеличенный запас"},
			{"rate_mul": 1.15, "text": "темп +15%"},
			{"damage": 0.96, "reload_mul": 0.75, "text": "урон +40% от L1, перезарядка −25%"}],
	},
	Base.SAW: {
		"name": "Бензопила «Дружба»", "short": "Дружба", "desc": "Моторная цепная пила",
		"damage": 8, "rate": 5, "mag": 40, "reload": 2.4, "range": 42, "spread": 85,
		"proj": 1, "knock": 65, "speed": 250, "crit": 0.0, "pierce": 0,
		"levels": [{}, {"damage": 2, "text": "урон +25% от L1"},
			{"mag": 14, "text": "увеличенный запас"},
			{"rate_mul": 1.15, "text": "темп +15%"},
			{"damage": 3.2, "reload_mul": 0.75, "text": "урон +40% от L1, перезарядка −25%"}],
	},
	Base.CROSSBOW: {
		"name": "Арбалет «Скиф»", "short": "Скиф", "desc": "Тяжёлый стальной болт",
		"damage": 38, "rate": 1.1, "mag": 3, "reload": 1.9, "range": 290, "spread": 1,
		"proj": 1, "knock": 160, "speed": 330, "crit": 0.0, "pierce": 3,
		"levels": [{}, {"damage": 9.5, "text": "урон +25% от L1"},
			{"mag": 2, "text": "увеличенный запас"},
			{"rate_mul": 1.15, "pierce": 2, "text": "темп +15%, ещё 2 цели насквозь"},
			{"damage": 15.2, "reload_mul": 0.75, "text": "урон +40% от L1, перезарядка −25%"}],
	},
	Base.AUTO_SHOTGUN: {
		"name": "Дробовик «Сайга»", "short": "Сайга", "desc": "Самозарядный дробовик",
		"damage": 3, "rate": 3.5, "mag": 12, "reload": 3, "range": 115, "spread": 38,
		"proj": 5, "knock": 25, "speed": 380, "crit": 0.0, "pierce": 0,
		"levels": [{}, {"damage": 0.75, "text": "урон +25% от L1"},
			{"mag": 5, "text": "увеличенный запас"},
			{"rate_mul": 1.15, "text": "темп +15%"},
			{"damage": 1.2, "reload_mul": 0.75, "text": "урон +40% от L1, перезарядка −25%"}],
	},
	Base.DMR: {
		"name": "Винтовка СВД", "short": "СВД", "desc": "Магазинная винтовка с оптикой",
		"damage": 19, "rate": 2.4, "mag": 10, "reload": 2, "range": 310, "spread": 1.5,
		"proj": 1, "knock": 65, "speed": 500, "crit": 0.0, "pierce": 1,
		"levels": [{}, {"damage": 4.75, "text": "урон +25% от L1"},
			{"mag": 4, "text": "увеличенный запас"},
			{"rate_mul": 1.15, "text": "темп +15%"},
			{"damage": 7.6, "reload_mul": 0.75, "text": "урон +40% от L1, перезарядка −25%"}],
	},
	Base.TESLA: {
		"name": "Разрядник «Дуга»", "short": "Дуга", "desc": "Полевой дуговой разрядник",
		"damage": 12, "rate": 2, "mag": 12, "reload": 2.7, "range": 145, "spread": 0,
		"proj": 1, "knock": 10, "speed": 450, "crit": 0.0, "pierce": 0,
		"levels": [{}, {"damage": 3, "text": "урон +25% от L1"},
			{"mag": 5, "text": "увеличенный запас"},
			{"rate_mul": 1.15, "text": "темп +15%"},
			{"damage": 4.8, "reload_mul": 0.75, "text": "урон +40% от L1, перезарядка −25%"}],
	},

}

## Патроны: индексы совпадают с Weapon.Ammo (STANDARD, EXPANSIVE, INCENDIARY, CRYO).
const AMMO := [
	{"name": "Стандартные", "big": ["+10%", "крит"], "desc": "+10% шанс крита; крит взрывает голову",
		"ranks": ["+10% крит", "+15% крит", "крит ×2.5"]},
	{"name": "Экспансивные", "big": ["30%", "всплеск"], "desc": "Всплеск урона вокруг цели; убитых рвёт на куски",
		"ranks": ["всплеск 30%", "всплеск 45%", "всплеск и при убийстве"]},
	{"name": "Зажигательные", "big": ["4/с", "огонь"], "desc": "Поджигают; горящие трупы поджигают соседей",
		"ranks": ["огонь 4/с", "огонь 6/с", "огонь перекидывается вдвое дальше"]},
	{"name": "Крио", "big": ["4", "попадания до заморозки"], "desc": "Замедляют и замораживают; замёрзших раскалывает",
		"ranks": ["заморозка с 4 попаданий", "заморозка с 3 попаданий", "осколки ранят и морозят соседей"]},
]

const MODULES := {
	Module.RICOCHET: {"name": "Рикошет", "big": ["1", "отскок"], "desc": "Снаряд отскакивает к следующей цели",
		"ranks": ["1 отскок", "2 отскока", "3 отскока"]},
	Module.PIERCE: {"name": "Пробивание", "big": ["2", "цели насквозь"], "desc": "Снаряд проходит сквозь врагов",
		"ranks": ["сквозь 2", "сквозь 4", "сквозь 6, +20% урона за каждого"]},
	Module.SPLIT: {"name": "Сплит", "big": ["3", "осколка"], "desc": "При попадании разлетается осколками",
		"ranks": ["3 осколка", "4 осколка", "5 осколков"]},
	Module.DETONATOR: {"name": "Детонатор", "big": ["25%", "шанс взрыва"], "desc": "Убитые этим стволом взрываются",
		"ranks": ["шанс 25%", "шанс 40%", "шанс 60%, взрывы цепляют друг друга"]},
	Module.TWIN: {"name": "Сдвоенный ствол", "big": ["+1", "снаряд"], "desc": "Больше снарядов за выстрел",
		"ranks": ["+1 снаряд", "+2 снаряда", "+3 снаряда веером"]},
	Module.CHAIN: {"name": "Цепь", "big": ["50%", "урона соседу"], "desc": "Убийство выпускает снаряд в соседа",
		"ranks": ["50% урона", "65% урона", "80%, цепь до 3 звеньев"]},
	Module.LINK: {"name": "Перелив", "big": ["1", "заряд"], "desc": "Избыток тяжёлого убийства питает следующий дробовой залп",
		"ranks": ["Один заряд на 6 с; без рангов и редкости"]},
}

const PASSIVES := {
	Passive.DAMAGE: {"name": "Боевые стимуляторы", "big": ["+10%", "урон"], "per_level": 0.10, "text": "+10% урона"},
	Passive.FIRE_RATE: {"name": "Облегчённый затвор", "big": ["+8%", "скорострельность"], "per_level": 0.08, "text": "+8% скорострельности"},
	Passive.RELOAD: {"name": "Быстрые руки", "big": ["−8%", "перезарядка"], "per_level": 0.08, "text": "−8% времени перезарядки"},
	Passive.SPEED: {"name": "Экзоскелет", "big": ["+6%", "скорость"], "per_level": 0.06, "text": "+6% скорости"},
	Passive.HP: {"name": "Бронежилет", "big": ["+20", "здоровье"], "per_level": 20.0, "text": "+20 макс. HP"},
	Passive.PICKUP: {"name": "Сборщик образцов", "big": ["+25%", "радиус подбора"], "per_level": 0.25, "text": "+25% радиуса подбора"},
}

## Прототипы: основа на ур.5 + патроны + модуль.
const PROTOTYPES := [
	{"name": "МЯСОРУБКА", "base": Base.SHOTGUN, "ammo": 1, "module": Module.DETONATOR,
		"desc": "каждое убийство взрывается, взрывы цепляют друг друга"},
	{"name": "АБСОЛЮТНЫЙ НОЛЬ", "base": Base.RAIL, "ammo": 3, "module": Module.PIERCE,
		"desc": "луч мгновенно замораживает всю линию"},
]


## Модели стволов (CONTRACTS §11, BALANCE §3.4, GDD §5.10). У каждой категории серийная модель
## (без переопределений) и модель из ящика. "stats" — абсолютные переопределения статов основы
## на ур.1 (до уровней L2–L5), "mul" — множители поверх итога (после уровней).
## "gun" — папка голоса sfx/weapons/<gun>/ (нет файлов — голос серийной модели).
const MODELS := {
	"an94": {"base": Base.RIFLE, "name": "Автомат АН-94", "short": "АН-94", "rarity": 2, "gun": "rifle", "trait": "doubletap", "desc": "Автомат, 5,45 мм"},
	"coach": {"base": Base.SHOTGUN, "name": "Дробовик «Кучер»", "short": "Кучер", "rarity": 1, "gun": "shotgun", "trait": "slug", "desc": "Укороченный дробовик", "stats": {"mag":2,"rate":1.8,"reload":1.4}},
	"harpoon": {"base": Base.RAIL, "name": "Рейлган «Гарпун»", "short": "Гарпун", "rarity": 1, "gun": "rail", "trait": "last_round", "desc": "Рейлган с длинными направляющими", "stats": {"mag":2,"damage":25}},
	"thumper": {"base": Base.LAUNCHER, "name": "Гранатомёт «Факел»", "short": "Факел", "rarity": 1, "gun": "launcher", "trait": "tracer", "desc": "Сигнальный гранатомёт", "stats": {"damage":18,"radius":34}},
	"makarov": {"base": Base.PISTOL, "name": "Пистолет ПМ", "short": "ПМ", "rarity": 1, "gun": "pistol", "trait": "last_round", "desc": "Компактный пистолет", "stats": {"mag":8,"damage":10}},
	"nagant": {"base": Base.REVOLVER, "name": "Револьвер «Наган»", "short": "Наган", "rarity": 1, "gun": "revolver", "trait": "execute", "desc": "Семизарядный револьвер", "stats": {"mag":7,"damage":24}},
	"mp5": {"base": Base.SMG, "name": "ПП MP5", "short": "MP5", "rarity": 2, "gun": "smg", "trait": "doubletap", "desc": "Компактный пистолет-пулемёт", "stats": {"mag":30,"rate":10,"spread":3}},
	"tikka": {"base": Base.SNIPER, "name": "Винтовка «Тикка»", "short": "Тикка", "rarity": 1, "gun": "sniper", "trait": "focus", "desc": "Болтовая винтовка с оптикой", "stats": {"damage":40,"pierce":2}},
	"pkm": {"base": Base.LMG, "name": "Пулемёт ПКМ", "short": "ПКМ", "rarity": 0, "gun": "lmg", "trait": "brace", "desc": "Пулемёт. Пулемётчик: раскрутка быстрее на 25%"},
	"rpk": {"base": Base.LMG, "name": "Пулемёт РПК", "short": "РПК", "rarity": 1, "gun": "lmg", "trait": "tracer", "desc": "Пулемёт. Пулемётчик: раскрутка быстрее на 25%", "stats": {"mag":60,"reload":2.5,"damage":5.5}},
	"pecheneg": {"base": Base.LMG, "name": "Пулемёт «Печенег»", "short": "Печенег", "rarity": 2, "gun": "lmg", "trait": "quick_spin", "desc": "Пулемёт. Пулемётчик: раскрутка быстрее на 25%", "stats": {"rate":9,"mag":80}},
	"m134": {"base": Base.MINIGUN, "name": "Миниган М134", "short": "М134", "rarity": 0, "gun": "minigun", "trait": "spin", "desc": "Многоствольный пулемёт. Пулемётчик: раскрутка быстрее на 25%"},
	"gatling": {"base": Base.MINIGUN, "name": "Миниган «Картечница»", "short": "Картечница", "rarity": 1, "gun": "minigun", "trait": "quick_spin", "desc": "Многоствольный пулемёт. Пулемётчик: раскрутка быстрее на 25%", "stats": {"damage":2.6,"mag":120,"reload":3.2}},
	"vulcan": {"base": Base.MINIGUN, "name": "Миниган «Вулкан»", "short": "Вулкан", "rarity": 2, "gun": "minigun", "trait": "last_round", "desc": "Многоствольный пулемёт. Пулемётчик: раскрутка быстрее на 25%", "stats": {"mag":90,"damage":3.2}},
	"lpo": {"base": Base.FLAMER, "name": "Огнемёт ЛПО", "short": "ЛПО", "rarity": 0, "gun": "flamer", "trait": "flame", "desc": "Переносной огнемёт"},
	"torch": {"base": Base.FLAMER, "name": "Огнемёт «Смола»", "short": "Смола", "rarity": 1, "gun": "flamer", "trait": "napalm", "desc": "Переносной огнемёт", "stats": {"damage":1.8,"mag":45}},
	"furnace": {"base": Base.FLAMER, "name": "Огнемёт «Горн»", "short": "Горн", "rarity": 2, "gun": "flamer", "trait": "wide", "desc": "Переносной огнемёт", "stats": {"range":65,"damage":2.2}},
	"druzhba": {"base": Base.SAW, "name": "Бензопила «Дружба»", "short": "Дружба", "rarity": 0, "gun": "saw", "trait": "cleave", "desc": "Моторная цепная пила"},
	"rescuer": {"base": Base.SAW, "name": "Пила «Спасатель»", "short": "Спасатель", "rarity": 1, "gun": "saw", "trait": "sweep", "desc": "Моторная цепная пила", "stats": {"range":49,"damage":6.5}},
	"butcher_saw": {"base": Base.SAW, "name": "Пила «Забойщик»", "short": "Забойщик", "rarity": 2, "gun": "saw", "trait": "execute", "desc": "Моторная цепная пила", "stats": {"rate":4,"damage":9}},
	"skif": {"base": Base.CROSSBOW, "name": "Арбалет «Скиф»", "short": "Скиф", "rarity": 0, "gun": "crossbow", "trait": "pin", "desc": "Арбалет со стальным болтом"},
	"ballista": {"base": Base.CROSSBOW, "name": "Арбалет «Баллиста»", "short": "Баллиста", "rarity": 2, "gun": "crossbow", "trait": "explosive_bolt", "desc": "Арбалет со стальным болтом", "stats": {"damage":27,"pierce":1,"mag":2}},
	"repeater": {"base": Base.CROSSBOW, "name": "Арбалет «Егерь»", "short": "Егерь", "rarity": 1, "gun": "crossbow", "trait": "return_bolt", "desc": "Арбалет со стальным болтом", "stats": {"damage":29,"mag":5}},
	"saiga": {"base": Base.AUTO_SHOTGUN, "name": "Дробовик «Сайга»", "short": "Сайга", "rarity": 0, "gun": "auto_shotgun", "trait": "drum", "desc": "Самозарядный дробовик"},
	"aa12": {"base": Base.AUTO_SHOTGUN, "name": "Дробовик AA-12", "short": "AA-12", "rarity": 1, "gun": "auto_shotgun", "trait": "slug", "desc": "Самозарядный дробовик", "stats": {"spread":3,"mag":8}},
	"striker": {"base": Base.AUTO_SHOTGUN, "name": "Дробовик «Страйкер»", "short": "Страйкер", "rarity": 2, "gun": "auto_shotgun", "trait": "last_round", "desc": "Самозарядный дробовик", "stats": {"mag":8,"rate":3}},
	"svd": {"base": Base.DMR, "name": "Винтовка СВД", "short": "СВД", "rarity": 0, "gun": "dmr", "trait": "focus", "desc": "Полуавтоматическая винтовка"},
	"sks": {"base": Base.DMR, "name": "Карабин СКС", "short": "СКС", "rarity": 1, "gun": "dmr", "trait": "return_bolt", "desc": "Полуавтоматическая винтовка", "stats": {"damage":17,"mag":10,"pierce":0}},
	"m14": {"base": Base.DMR, "name": "Винтовка M14", "short": "M14", "rarity": 2, "gun": "dmr", "trait": "doubletap", "desc": "Полуавтоматическая винтовка", "stats": {"damage":16,"rate":3,"mag":20}},
	"arc": {"base": Base.TESLA, "name": "Разрядник «Дуга»", "short": "Дуга", "rarity": 0, "gun": "tesla", "trait": "arc", "desc": "Полевой разрядник. Инженер: ещё одна цель"},
	"fork": {"base": Base.TESLA, "name": "Разрядник «Вилка»", "short": "Вилка", "rarity": 1, "gun": "tesla", "trait": "fork", "desc": "Полевой разрядник. Инженер: ещё одна цель", "stats": {"damage":8,"mag":10}},
	"storm": {"base": Base.TESLA, "name": "Разрядник «Гроза»", "short": "Гроза", "rarity": 2, "gun": "tesla", "trait": "ground", "desc": "Полевой разрядник. Инженер: ещё одна цель", "stats": {"damage":10,"range":120}},
	"ak_s": {"base": Base.RIFLE, "name": "Автомат АК-С", "short": "АК-С", "rarity": Rarity.SERIAL, "gun": "rifle", "trait": ""},
	"m4": {"base": Base.RIFLE, "name": "Карабин «М4»", "short": "М4", "rarity": Rarity.COMMON, "gun": "m4", "trait": "burst3",
		"desc": "Карабин",
		"stats": {"damage": 8.0, "rate": 5.0, "range": 250.0, "spread": 1.5}},
	"butcher": {"base": Base.SHOTGUN, "name": "Дробовик «Мясник»", "short": "Мясник", "rarity": Rarity.SERIAL, "gun": "shotgun", "trait": ""},
	"shkval": {"base": Base.SHOTGUN, "name": "Дробовик «Шквал»", "short": "Шквал", "rarity": Rarity.COMMON, "gun": "shkval", "trait": "slamfire",
		"desc": "Автоматическая помпа: сплошной поток дроби",
		"stats": {"damage": 3.5, "rate": 2.2, "proj": 5, "mag": 10, "reload": 2.6, "range": 115.0, "spread": 38.0, "knock": 26.0},
		"levels": [{}, {"proj": 2, "text": "+2 дробины"}, {"damage": 1.0, "text": "урон +1"},
			{"mag": 2, "reload_mul": 0.8, "text": "магазин +2, перезарядка −20%"},
			{"proj": 3, "knock_mul": 2.0, "text": "+3 дробины, отброс ×2"}]},
	"needle": {"base": Base.RAIL, "name": "Рейлган «Игла»", "short": "Игла", "rarity": Rarity.SERIAL, "gun": "rail", "trait": ""},
	"spear": {"base": Base.RAIL, "name": "Рейлган «Копьё»", "short": "Копьё", "rarity": Rarity.RARE, "gun": "spear", "trait": "kill_charge",
		"desc": "Рейлган с толстым лучом",
		"stats": {"damage": 60.0, "rate": 0.4, "mag": 3, "width": 10.0, "crit": 0.1}},
	"grom": {"base": Base.LAUNCHER, "name": "Гранатомёт «Гром»", "short": "Гром", "rarity": Rarity.SERIAL, "gun": "launcher", "trait": ""},
	"hive": {"base": Base.LAUNCHER, "name": "Гранатомёт «Улей»", "short": "Улей", "rarity": Rarity.RARE, "gun": "hive", "trait": "sticky",
		"desc": "Кассета из трёх гранат",
		"stats": {"damage": 10.0, "rate": 0.9, "proj": 3, "mag": 6, "reload": 3.0, "radius": 34.0, "knock": 60.0},
		"levels": [{}, {"radius": 8.0, "text": "радиус +8"}, {"damage": 4.0, "text": "урон +4"},
			{"proj": 1, "text": "+1 граната в кассете"},
			{"damage": 4.0, "radius": 8.0, "reload_mul": 0.7, "text": "урон +4, радиус +8, перезарядка −30%"}]},
	"colt": {"base": Base.PISTOL, "name": "Пистолет «Кольт»", "short": "Кольт", "rarity": Rarity.SERIAL, "gun": "pistol", "trait": ""},
	"guard": {"base": Base.PISTOL, "name": "Пистолет «Страж»", "short": "Страж", "rarity": Rarity.COMMON, "gun": "guard", "trait": "hicap",
		"desc": "Пистолет, 9 мм",
		"stats": {"damage": 8.0, "rate": 4.2, "mag": 17, "reload": 1.4, "range": 170.0, "spread": 3.0, "knock": 25.0, "crit": 0.05}},
	"bulldog": {"base": Base.REVOLVER, "name": "Револьвер «Бульдог»", "short": "Бульдог", "rarity": Rarity.SERIAL, "gun": "revolver", "trait": ""},
	"cowboy": {"base": Base.REVOLVER, "name": "Револьвер «Ковбой»", "short": "Ковбой", "rarity": Rarity.RARE, "gun": "cowboy", "trait": "fan",
		"desc": "Револьвер, курок под ладонью",
		"stats": {"damage": 15.0, "reload": 3.0, "range": 190.0, "spread": 6.0, "knock": 55.0, "pierce": 0},
		"levels": [{}, {"damage": 4.0, "text": "урон +4"}, {"rate_mul": 1.2, "text": "веер на 20% быстрее"},
			{"knock_mul": 1.5, "crit": 0.1, "text": "отброс ×1.5, +10% крит"},
			{"damage": 7.0, "reload_mul": 0.75, "text": "урон +7, перезарядка −25%"}]},
	"ppsh": {"base": Base.SMG, "name": "ПП «ППШ»", "short": "ППШ", "rarity": Rarity.SERIAL, "gun": "smg", "trait": ""},
	"osa": {"base": Base.SMG, "name": "ПП «Оса»", "short": "Оса", "rarity": Rarity.COMMON, "gun": "osa", "trait": "steady",
		"desc": "Пистолет-пулемёт",
		"stats": {"damage": 4.0, "rate": 11.0, "mag": 50, "reload": 1.8, "range": 150.0, "spread": 5.0, "knock": 14.0}},
	"mosin": {"base": Base.SNIPER, "name": "Винтовка «Мосинка»", "short": "Мосинка", "rarity": Rarity.SERIAL, "gun": "sniper", "trait": ""},
	"winchester": {"base": Base.SNIPER, "name": "Винтовка «Винчестер»", "short": "Винчестер", "rarity": Rarity.RARE, "gun": "winchester", "trait": "lever",
		"desc": "Рычажная винтовка",
		"stats": {"mag": 7, "range": 310.0, "pierce": 1, "crit": 0.1}, "mul": {"damage": 0.6, "rate": 2.0}},
}

## Порядок моделей (как в CONTRACTS §11) — для списков базы и для ящиков.
const MODEL_ORDER := ["ak_s", "m4", "butcher", "shkval", "needle", "spear", "grom", "hive", "colt", "guard", "bulldog", "cowboy", "ppsh", "osa", "mosin", "winchester", "an94", "coach", "harpoon", "thumper", "makarov", "nagant", "mp5", "tikka", "pkm", "rpk", "pecheneg", "m134", "gatling", "vulcan", "lpo", "torch", "furnace", "druzhba", "rescuer", "butcher_saw", "skif", "ballista", "repeater", "saiga", "aa12", "striker", "svd", "sks", "m14", "arc", "fork", "storm"]
const RARITY_NAMES := ["серийная", "обычная", "редкая"]

## Тембр модели поверх четырёхслойного пресета категории W6; механика остаётся в исходной высоте.
const MODEL_PITCH := {
	"m4": 1.06, "shkval": 0.9, "spear": 0.8, "hive": 1.15,
	"guard": 1.18, "cowboy": 0.92, "osa": 1.12, "winchester": 0.9,
	"an94": 1.18, "coach": 0.82, "harpoon": 0.72, "thumper": 0.9,
	"makarov": 1.25, "nagant": 1.1, "mp5": 1.22, "tikka": 1.1,
	"rpk": 1.13, "pecheneg": 0.94, "gatling": 0.88, "vulcan": 1.08,
	"torch": 0.78, "furnace": 1.15, "rescuer": 1.16, "butcher_saw": 0.82,
	"ballista": 0.74, "repeater": 1.2, "aa12": 0.85, "striker": 1.1,
	"sks": 0.9, "m14": 1.1, "fork": 1.18, "storm": 0.76,
}

## Черты моделей из ящиков. Механика — weapons.gd, здесь только названия и тексты.
const TRAITS := {
	"doubletap": {"name": "Двойка", "text": "Два выстрела с интервалом 0.05 с, затем пауза"},
	"slug": {"name": "Жакан", "text": "Один тяжёлый снаряд вместо дроби; пробивает две цели"},
	"last_round": {"name": "Контрольный", "text": "Последний патрон магазина наносит тройной урон"},
	"tracer": {"name": "Трассеры", "text": "Каждое попадание поджигает цель на 2 с"},
	"execute": {"name": "Добивание", "text": "Двойной урон врагам ниже 35% здоровья"},
	"focus": {"name": "Выдержка", "text": "После 0.6 с без движения урон +35%"},
	"brace": {"name": "Сошки", "text": "Раскрутка 0.35 с; стоя разброс вчетверо меньше"},
	"quick_spin": {"name": "Лёгкий ротор", "text": "Раскрутка вдвое быстрее, остановка сохраняет вращение дольше"},
	"spin": {"name": "Блок стволов", "text": "Раскрутка 0.9 с; во время огня скорость движения −35%"},
	"flame": {"name": "Струя", "text": "Конус 44°; огонь переходит на соседей"},
	"napalm": {"name": "Смола", "text": "Поджог длится 5 с вместо 2; прямой урон ниже"},
	"wide": {"name": "Раструб", "text": "Конус 76°; дальность короче"},
	"cleave": {"name": "Распил", "text": "Цепь бьёт всех в секторе 85° и рассекает тела"},
	"sweep": {"name": "Подрезка", "text": "Сектор 140° и длинная шина; ниже урон"},
	"pin": {"name": "Сквозной болт", "text": "Пробивает троих, пришпиливает убитых к земле"},
	"explosive_bolt": {"name": "Разрывной болт", "text": "Каждое попадание даёт взрыв радиусом 21"},
	"return_bolt": {"name": "Подхват", "text": "Убийство возвращает один патрон в магазин"},
	"drum": {"name": "Съёмный магазин", "text": "Дробь без помпы, быстрая смена целого магазина"},
	"arc": {"name": "Переброс", "text": "До четырёх целей; каждая следующая получает 72% урона"},
	"fork": {"name": "Развилка", "text": "Две независимые дуги по разным целям"},
	"ground": {"name": "Проводник", "text": "До шести целей; прыжок 95 вместо 65, затухание сильнее"},
	"burst3": {"name": "Очереди", "text": "Очередь из 3 пуль; разброс не растёт"},
	"slamfire": {"name": "Слэм-фаер", "text": "Высокий темп, магазин 10, долгая перезарядка"},
	"kill_charge": {"name": "Накопитель", "text": "Убийство даёт +50% урона следующему выстрелу"},
	"sticky": {"name": "Липкие гранаты", "text": "Гранаты прилипают и рвутся через 0.6 с"},
	"hicap": {"name": "Ёмкий магазин", "text": "17 патронов; темп выше, урон ниже, чем у «Кольта»"},
	"fan": {"name": "Веер", "text": "Барабан веером по разным целям за 0.5 с"},
	"steady": {"name": "Ровный бой", "text": "50 патронов; разброс не растёт"},
	"lever": {"name": "Рычаг", "text": "Темп ×2, урон ×0.6; убийство взводит рычаг"},
}

const BURST_SHOTS := 3 # burst3: пуль в очереди
const BURST_GAP := 0.07 # burst3: интервал внутри очереди
const KILL_CHARGE_MULT := 1.5 # kill_charge: бонус следующему выстрелу
const STICKY_FUSE := 0.6 # sticky: взрыв после прилипания
const FAN_TIME := 0.5 # fan: сколько длится веер при исходном темпе
const FAN_BASE_RATE := 1.5 # темп основы-револьвера, к которому привязана длительность веера


static func serial_model(base: int) -> String:
	for id: String in MODEL_ORDER:
		var m: Dictionary = MODELS[id]
		if m["base"] == base and m["rarity"] == Rarity.SERIAL:
			return id
	return ""


## Модели категории: серийная первой.
static func models_of(base: int) -> Array[String]:
	var out: Array[String] = []
	for id: String in MODEL_ORDER:
		if MODELS[id]["base"] == base:
			out.append(id)
	return out


## Модели, выпадающие из ящиков, заданной редкости.
static func crate_models(rarity: int) -> Array[String]:
	var out: Array[String] = []
	for id: String in MODEL_ORDER:
		if MODELS[id]["rarity"] == rarity:
			out.append(id)
	return out


## Статы модели: основа → переопределения → уровни L2–L5 → множители модели.
static func model_stats(model: String, level: int) -> Dictionary:
	var m: Dictionary = MODELS[model]
	var s := base_stats(m["base"], level, m.get("stats", {}), m.get("levels", []))
	var mul: Dictionary = m.get("mul", {})
	for k: String in mul:
		s[k] = s[k] * mul[k]
	return s


## Доля урона сквозь броню; остальное уходит в отдельный запас пластины.
static func armor_penetration(base: int, model := "", module_rank := 0, distance := 200.0) -> float:
	var values := [0.0, 0.0, 1.0, 1.0, 0.0, 0.35, 0.0, 0.90, 0.20, 0.05, 0.90, 0.80, 0.70, 0.0, 0.65, 1.0]
	var value: float = values[base] if base >= 0 and base < values.size() else 0.0
	if base in [Base.SHOTGUN, Base.AUTO_SHOTGUN]:
		value = 0.80 if distance <= 45.0 else 0.0
	if model in ["coach", "aa12"]: value = maxf(value, 0.75)
	if model in ["ballista", "tikka", "pecheneg", "m14"]: value = minf(1.0, value + 0.15)
	if model in ["makarov", "mp5", "repeater", "sks"]: value = maxf(0.0, value - 0.15)
	return minf(1.0, value + float(module_rank) * 0.25)


## Эффективный DPS в первую цель (BALANCE §3.1; метод W1: стандартные патроны I, без модулей и пассивок).
## Крит: 5% игрока + 10% патронов + крит ствола, множитель ×2. Веер ковбоя тратит на выстрелы FAN_TIME.
static func effective_dps(model: String, level: int) -> float:
	var st := model_stats(model, level)
	var rate: float = st["rate"]
	var shots_time: float = float(st["mag"]) / rate
	if int(MODELS[model]["base"]) in [Base.LMG, Base.MINIGUN]:
		shots_time += (0.35 if MODELS[model]["base"] == Base.LMG else 0.9) * (0.5 if MODELS[model]["trait"] == "quick_spin" else 1.0)
	if MODELS[model]["trait"] == "fan":
		shots_time = FAN_TIME * FAN_BASE_RATE / rate
	var crit: float = 1.0 + float(st["crit"]) + 0.15
	if MODELS[model]["trait"] == "last_round":
		crit *= 1.0 + 2.0 / float(st["mag"])
	return float(st["damage"]) * int(st["proj"]) * float(st["mag"]) / (shots_time + float(st["reload"])) * crit


## Статы основы с учётом уровня (без пассивок и модулей). overrides — переопределения модели на ур.1.
static func base_stats(base: int, level: int, overrides := {}, levels_override := []) -> Dictionary:
	var d: Dictionary = BASES[base]
	var s := {}
	for k in ["damage", "rate", "mag", "reload", "range", "spread", "speed", "proj", "knock", "crit", "width", "radius", "pierce"]:
		if d.has(k):
			s[k] = d[k]
	for k: String in overrides:
		s[k] = overrides[k]
	var levels: Array = levels_override if not levels_override.is_empty() else d["levels"]
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


## Что даёт переход на уровень level (2..5) для модели: словарь прибавок с полем "text".
static func level_info(model: String, level: int) -> Dictionary:
	var m: Dictionary = MODELS[model]
	var levels: Array = m.get("levels", BASES[m["base"]]["levels"])
	return levels[level - 1]


## Главный эффект уровня ствола одной крупной цифрой: [число, подпись]. Остальное — по наведению (текст уровня).
static func level_big(step: Dictionary) -> Array[String]:
	if step.has("damage"):
		return ["+" + _fmt(step["damage"]), "урон"]
	if step.has("proj"):
		return ["+" + _fmt(step["proj"]), "снарядов за выстрел"]
	if step.has("mag"):
		return ["+" + _fmt(step["mag"]), "в магазине"]
	if step.has("rate_mul"):
		return ["+%d%%" % roundi((float(step["rate_mul"]) - 1.0) * 100.0), "скорострельность"]
	if step.has("reload_mul"):
		return ["−%d%%" % roundi((1.0 - float(step["reload_mul"])) * 100.0), "время перезарядки"]
	if step.has("radius"):
		return ["+" + _fmt(step["radius"]), "радиус взрыва"]
	if step.has("width_mul"):
		return ["×" + _fmt(step["width_mul"]), "ширина луча"]
	if step.has("crit"):
		return ["+%d%%" % roundi(float(step["crit"]) * 100.0), "крит"]
	if step.has("knock_mul"):
		return ["×" + _fmt(step["knock_mul"]), "отброс"]
	if step.has("range"):
		return ["+" + _fmt(step["range"]), "дальность"]
	return ["", ""]


static func _fmt(v: float) -> String:
	return "%d" % roundi(v) if is_equal_approx(v, roundf(v)) else "%.1f" % v


static func module_slots(level: int) -> int:
	return 1 if level < 3 else (2 if level < 5 else 3)


static func supports_module(base: int, module: int) -> bool:
	if module == Module.LINK:
		return base in [Base.SHOTGUN, Base.AUTO_SHOTGUN]
	if base in [Base.FLAMER, Base.SAW]:
		return module in [Module.DETONATOR, Module.CHAIN]
	if base == Base.TESLA:
		return module in [Module.DETONATOR, Module.CHAIN, Module.TWIN]
	return true


static func supports_ammo(base: int, ammo: int) -> bool:
	if base == Base.FLAMER: return ammo in [Ammo.STANDARD, Ammo.INCENDIARY]
	if base == Base.SAW: return ammo in [Ammo.STANDARD, Ammo.EXPANSIVE]
	return true
