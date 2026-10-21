class_name ClassTree
extends RefCounted
## Три классовые сети: кластеры, кольца, мосты и взаимоисключающие доктрины.
## Числа — BALANCE §11.2; _mul перемножаются, остальные числа складываются.

const BRANCHES := [
	{"id": "fire", "name": "ОГОНЬ", "nodes": [
		{"id": "fire_1", "name": "Пристрелка", "text": "+8% урона всех стволов.", "short": "+8%", "icon": "bullet", "effects": {"damage_mul": 1.08}},
		{"id": "fire_2", "name": "Бронебой", "text": "+10 процентных пунктов шанса критического попадания.", "short": "+10%", "icon": "sight", "effects": {"crit_add": 0.10}},
		{"id": "fire_3", "name": "Шквал огня", "text": "После 3 с непрерывной стрельбы +20% темпа. Перезарядка обрывает серию.", "short": "3с", "icon": "burst", "effects": {"sustained_rate": 0.20}},
		{"id": "fire_hold", "name": "Упор", "text": "После 1 с на месте +25% урона. Движение сразу снимает бонус.", "short": "1с", "icon": "brace", "effects": {"standing_damage": 0.25}},
		{"id": "fire_range", "name": "Дальнобой", "text": "+12% дальности всех стволов.", "short": "+12%", "icon": "sight", "effects": {"range_mul": 1.12}},
		{"id": "fire_spread", "name": "Кучность", "text": "Разброс стволов меньше на 20%.", "short": "−20%", "icon": "sight", "effects": {"spread_mul": 0.80}},
		{"id": "fire_close", "name": "Пролом", "text": "+25% урона стволов целям в пределах 70 px. Нужно 5 завершённых вылазок.", "short": "<70", "icon": "burst", "gate": "runs5", "effects": {"close_damage": 0.25}},
		{"id": "fire_far", "name": "Рубеж", "text": "+20% урона стволов целям от 140 px. Нужно 5 завершённых вылазок.", "short": ">140", "icon": "sight", "gate": "runs5", "effects": {"far_damage": 0.20}}]},
	{"id": "mag", "name": "МАГАЗИН", "nodes": [
		{"id": "mag_1", "name": "Быстрые руки", "text": "Перезарядка всех стволов быстрее на 15%.", "short": "−15%", "icon": "reload", "effects": {"reload_mul": 0.85}},
		{"id": "mag_2", "name": "Расширенные магазины", "text": "+20% ёмкости магазинов; округление вверх.", "short": "+20%", "icon": "mag", "effects": {"mag_mul": 1.20}},
		{"id": "mag_3", "name": "Последний патрон", "text": "Последний патрон магазина наносит тройной урон и разрывает убитую цель.", "short": "×3", "icon": "bullet", "effects": {"last_round": true}},
		{"id": "mag_first", "name": "Первый залп", "text": "Первый патрон полного магазина наносит урон ×1,6. Работает после любой полной перезарядки.", "short": "×1,6", "icon": "burst", "effects": {"first_round": 0.60}},
		{"id": "mag_tactical", "name": "Тактическая смена", "text": "Перезарядка непустого магазина ещё на 20% быстрее. Пустого — без бонуса.", "short": "−20%", "icon": "reload", "effects": {"tactical_mul": 0.80}},
		{"id": "mag_move", "name": "Смена на ходу", "text": "+10% скорости движения, пока перезаряжается хотя бы один ствол.", "short": "+10%", "icon": "boot", "effects": {"reload_move": 0.10}},
		{"id": "mag_grenade", "name": "Смена под взрыв", "text": "Приземление гранаты мгновенно заряжает все стволы. Нужно 10 завершённых вылазок.", "short": "Q→R", "icon": "reload", "gate": "runs10", "effects": {"grenade_refill": true}},
		{"id": "mag_cover", "name": "Прикрытие", "text": "Начало перезарядки даёт 0,2 с неуязвимости. Общий КД 3 с. Нужно 10 вылазок.", "short": "0,2с", "icon": "shield", "gate": "runs10", "effects": {"reload_cover": 0.20}}]},
	{"id": "surv", "name": "ЗАЩИТА", "nodes": [
		{"id": "surv_1", "name": "Бронежилет", "text": "+20 максимального здоровья.", "short": "+20", "icon": "vest", "effects": {"hp_add": 20.0}},
		{"id": "surv_2", "name": "Рефлексы", "text": "+1 запасной заряд рывка. Заряды восстанавливаются по одному.", "short": "+1", "icon": "boot", "effects": {"dash_charges": 1}},
		{"id": "surv_3", "name": "Адреналин", "text": "Рывок мгновенно заряжает все стволы. Общий КД 10 с.", "short": "↗R", "icon": "reload", "effects": {"adrenaline": true}},
		{"id": "surv_bandage", "name": "Перевязка", "text": "Рывок восстанавливает 6 HP. КД 10 с, даже если здоровье полное.", "short": "+6", "icon": "med", "effects": {"dash_heal": 6.0}},
		{"id": "surv_armor", "name": "Подбой", "text": "Весь входящий урон меньше на 8%.", "short": "−8%", "icon": "vest", "effects": {"hurt_mul": 0.92}},
		{"id": "surv_rest", "name": "Передышка", "text": "После 6 с без полученного урона восстанавливается 0,5 HP/с. Удар прерывает лечение.", "short": "0,5/с", "icon": "med", "effects": {"rest_heal": 0.50}},
		{"id": "surv_rescue", "name": "Последний шанс", "text": "Один раз за вылазку смертельный удар оставляет 25 HP и 1 с защиты. Требуется уничтоженный улей.", "short": "25HP", "icon": "med", "gate": "nest", "effects": {"rescue_hp": 25.0}},
		{"id": "surv_rage", "name": "На пределе", "text": "+20% урона стволов при здоровье ниже 35%. Требуется уничтоженный улей.", "short": "<35%", "icon": "burst", "gate": "nest", "effects": {"low_damage": 0.20}}]},
	{"id": "dash", "name": "МАНЁВР", "nodes": [
		{"id": "dash_speed", "name": "Лёгкий шаг", "text": "+5% скорости движения.", "short": "+5%", "icon": "boot", "effects": {"speed_mul": 1.05}},
		{"id": "dash_reach", "name": "Разбег", "text": "+10 px к дальности рывка.", "short": "+10", "icon": "boot", "effects": {"dash_distance": 10.0}},
		{"id": "dash_sprint", "name": "Спринт", "text": "Заряд рывка восстанавливается на 20% быстрее.", "short": "−20%", "icon": "clock", "effects": {"dash_cd_mul": 0.80}},
		{"id": "dash_lunge", "name": "Выпад", "text": "Ещё +20 px рывка. Время рывка не увеличивается.", "short": "+20", "icon": "boot", "effects": {"dash_distance": 20.0}},
		{"id": "dash_guard", "name": "Скольжение", "text": "+0,05 с неуязвимости при рывке.", "short": "+0,05", "icon": "shield", "effects": {"dash_guard": 0.05}},
		{"id": "dash_smoke", "name": "Под прикрытием", "text": "Бросок гранаты даёт +15% скорости на 2 с.", "short": "Q+15%", "icon": "grenade", "effects": {"grenade_speed": 0.15}},
		{"id": "dash_run", "name": "Обход", "text": "После рывка +20% скорости на 1 с. Нужно 5 завершённых вылазок.", "short": "↗20%", "icon": "boot", "gate": "runs5", "effects": {"dash_speed": 0.20}},
		{"id": "dash_fuse", "name": "Короткий фитиль", "text": "Каждый потраченный заряд рывка сокращает текущий КД гранаты на 1 с. Нужно 5 вылазок.", "short": "Q−1с", "icon": "clock", "gate": "runs5", "effects": {"dash_grenade": 1.0}}]},
	{"id": "gren", "name": "ГРАНАТЫ", "nodes": [
		{"id": "gren_ready", "name": "Подсумок", "text": "КД гранаты меньше на 10%: 8 → 7,2 с.", "short": "−10%", "icon": "clock", "effects": {"grenade_cd_mul": 0.90}},
		{"id": "gren_radius", "name": "Осколочная рубашка", "text": "+10% радиуса ручной гранаты.", "short": "+10%", "icon": "grenade", "effects": {"grenade_radius_mul": 1.10}},
		{"id": "gren_charge", "name": "Заряд", "text": "Ручная граната: +50% урона, −20% радиуса. Не влияет на гранатомёт.", "short": "+50%", "icon": "grenade", "effects": {"grenade_damage_mul": 1.50, "grenade_radius_mul": 0.80}},
		{"id": "gren_wide", "name": "Охват", "text": "Ручная граната: −20% урона, +30% радиуса. Освобождает больше места.", "short": "+30%", "icon": "blast", "effects": {"grenade_damage_mul": 0.80, "grenade_radius_mul": 1.30}},
		{"id": "gren_throw", "name": "Дальний бросок", "text": "+20 px дальности броска ручной гранаты.", "short": "+20", "icon": "grenade", "effects": {"grenade_distance": 20.0}},
		{"id": "gren_knock", "name": "Ударная волна", "text": "+30% отброса ручной гранаты.", "short": "+30%", "icon": "blast", "effects": {"grenade_knock_mul": 1.30}},
		{"id": "gren_heal", "name": "Перегруппировка", "text": "Приземление ручной гранаты восстанавливает 6 HP, даже если она ни в кого не попала. Нужно 10 вылазок.", "short": "+6HP", "icon": "med", "gate": "runs10", "effects": {"grenade_heal": 6.0}},
		{"id": "gren_push", "name": "Расчистка", "text": "Отброс ручной гранаты дополнительно удвоен. Нужно 10 вылазок.", "short": "×2", "icon": "blast", "gate": "runs10", "effects": {"grenade_knock_mul": 2.0}}]},
	{"id": "tact", "name": "ТАКТИКА", "nodes": [
		{"id": "tact_knock", "name": "Стоппер", "text": "+15% отброса всех стволов.", "short": "+15%", "icon": "blast", "effects": {"knock_mul": 1.15}},
		{"id": "tact_crit", "name": "Тяжёлое попадание", "text": "Критическое попадание отбрасывает ещё на 50% сильнее.", "short": "+50%", "icon": "bullet", "effects": {"crit_knock": 0.50}},
		{"id": "tact_close", "name": "Натиск", "text": "Попадания стволов в пределах 70 px отбрасывают вдвое сильнее.", "short": "<70", "icon": "brace", "effects": {"close_knock": 1.0}},
		{"id": "tact_first", "name": "Заслон", "text": "Первый патрон полного магазина отбрасывает втрое сильнее.", "short": "1→×3", "icon": "shield", "effects": {"first_knock": 2.0}},
		{"id": "tact_elite", "name": "Приоритет", "text": "+10% урона стволов элитным зомби.", "short": "+10%", "icon": "sight", "effects": {"elite_damage": 0.10}},
		{"id": "tact_boss", "name": "Уязвимое место", "text": "+10% урона стволов боссу. Ручная граната без бонуса.", "short": "+10%", "icon": "sight", "effects": {"boss_damage": 0.10}},
		{"id": "tact_dna", "name": "Трофеи", "text": "+10% ДНК за завершённую вылазку, округление вниз. Ящики без бонуса. Требуется уничтоженный улей.", "short": "+10%Д", "icon": "dna", "gate": "nest", "effects": {"dna_mul": 1.10}},
		{"id": "tact_finish", "name": "Добивание", "text": "+25% урона стволов зомби и боссам ниже 20% HP. Требуется уничтоженный улей.", "short": "<20%", "icon": "bullet", "gate": "nest", "effects": {"finish_damage": 0.25}}]},
]

const DEFAULTS := {"damage_mul": 1.0, "crit_add": 0.0, "sustained_rate": 0.0, "reload_mul": 1.0,
	"mag_mul": 1.0, "last_round": false, "hp_add": 0.0, "dash_charges": 1, "adrenaline": false,
	"standing_damage": 0.0, "range_mul": 1.0, "spread_mul": 1.0, "close_damage": 0.0, "far_damage": 0.0,
	"first_round": 0.0, "tactical_mul": 1.0, "reload_move": 0.0, "grenade_refill": false, "reload_cover": 0.0,
	"dash_heal": 0.0, "hurt_mul": 1.0, "rest_heal": 0.0, "rescue_hp": 0.0, "low_damage": 0.0,
	"speed_mul": 1.0, "dash_distance": 0.0, "dash_cd_mul": 1.0, "dash_guard": 0.0, "grenade_speed": 0.0,
	"dash_speed": 0.0, "dash_grenade": 0.0, "grenade_cd_mul": 1.0, "grenade_radius_mul": 1.0,
	"grenade_damage_mul": 1.0, "grenade_distance": 0.0, "grenade_knock_mul": 1.0, "grenade_heal": 0.0,
	"knock_mul": 1.0, "crit_knock": 0.0, "close_knock": 0.0, "first_knock": 0.0, "elite_damage": 0.0,
	"boss_damage": 0.0, "dna_mul": 1.0, "finish_damage": 0.0}

const CLASSES := ["assault", "gunner", "engineer"]
const NAMES := ["ШТУРМОВИК", "ПУЛЕМЁТЧИК", "ИНЖЕНЕР"]
const CLUSTERS := [["ШТУРМ", "МАНЁВР", "ПОДРЫВ"], ["РУБЕЖ", "БАСТИОН", "ПОДАВЛЕНИЕ"], ["ТУРЕЛЬ", "ПЕРЕКРЁСТНЫЙ ОГОНЬ", "ОБСЛУЖИВАНИЕ"]]
const RULES := ["Вблизи попадания возвращают рывок. Q — граната.", "Стоя: стабильность и отброс. Q — фронтальный щит на 3 с.", "Обходите цель с другой стороны турели. Q — турель на 8 с."]
const STARTERS := [0, 6, 1]
static var active := "assault"
static var _catalogs: Dictionary = {}


static func catalog(class_id: String = "") -> Dictionary:
	if class_id.is_empty(): class_id = active
	if not _catalogs.has(class_id):
		var result: Dictionary = {}
		_catalogs[class_id] = result
		if class_id != "assault":
			_build_specialist(result, class_id)
			_wire(result, class_id)
			return result
		for b in BRANCHES.size():
			var nodes: Array = BRANCHES[b]["nodes"]
			for i in nodes.size():
				var n: Dictionary = nodes[i].duplicate(true)
				n["branch"] = b
				n["index"] = i
				n["cost"] = [1, 1, 1, 1, 2, 2, 3, 3][i]
				n["parents"] = [] if i == 0 else ([nodes[2]["id"], nodes[3]["id"]] if i == 4 else [nodes[[0, 0, 1, 1, 2, 4, 5, 5][i]]["id"]])
				n["exclude"] = nodes[{2: 3, 3: 2, 6: 7, 7: 6}[i]]["id"] if i in [2, 3, 6, 7] else ""
				n["legacy_parents"] = n["parents"].duplicate()
				result[n["id"]] = n
		for c in 3:
			for i in 8:
				var specs := [["Натиск", "close_damage", 0.015, "burst", "+1,5% урона до 70 px"], ["Возврат", "assault_return", 0.025, "boot", "Попадание вблизи: −0,025 с КД рывка (не чаще 1/с)"], ["Запал", "grenade_cd_mul", 0.985, "grenade", "−1,5% КД гранаты"]]
				var s: Array = specs[c]
				var id := "assault_%d_%d" % [c, i]
				result[id] = _entry(id, str(s[0]) + " " + str(i + 1), str(s[4]), str(s[3]), {s[1]: s[2]}, c, i + 16)
		_wire(result, class_id)
	return _catalogs[class_id]


static func _entry(id: String, title: String, text: String, icon: String, effects: Dictionary, cluster: int, index: int) -> Dictionary:
	return {"id": id, "name": title, "text": text, "short": "", "icon": icon, "effects": effects, "cost": 1, "branch": cluster, "index": index, "exclude": "", "parents": []}


static func _build_specialist(out: Dictionary, class_id: String) -> void:
	# У каждого кластера восемь опор и шестнадцать узлов собственного правила класса.
	var support := [["Подбой", "hurt_mul", 0.99, "vest", "−1% входящего урона"], ["Подсумок", "mag_mul", 1.015, "mag", "+1,5% магазина"], ["Смена", "reload_mul", 0.99, "reload", "−1% времени перезарядки"], ["Шаг", "speed_mul", 1.005, "boot", "+0,5% скорости"]]
	var gunner := [["Пристрелка", "brace_damage", 0.012, "brace", "+1,2% урона при полной стабильности"], ["Экран", "bastion_time", 0.10, "shield", "+0,1 с фронтального щита Q"], ["Остановить", "brace_knock", 0.035, "burst", "+3,5% отброса при полной стабильности"]]
	var engineer := [["Ствол турели", "turret_damage", 0.35, "turret", "+0,35 урона пули турели"], ["Огонь с фланга", "crossfire", 0.012, "sight", "+1,2% урона игрока с противоположной стороны турели"], ["Аккумулятор", "turret_time", 0.10, "clock", "+0,1 с работы турели"]]
	for c in 3:
		for i in 24:
			var s: Array = support[(i + c) % 4] if i < 8 else (gunner[c] if class_id == "gunner" else engineer[c])
			if i >= 8:
				var variants: Array = [
					[["Пристрелка", "brace_damage", 0.018, "brace", "+1,8% урона при стабильности"], ["Стоппер", "brace_knock", 0.06, "burst", "+6% отброса при стабильности"], ["Вкладка", "brace_gain", 0.06, "clock", "+6% скорости набора стабильности"], ["Выдержка", "brace_persist", 0.10, "boot", "+0,1 с сохранения стабильности в движении"]],
					[["Экран", "bastion_time", 0.15, "shield", "+0,15 с щита Q"], ["Готовность", "bastion_cd_mul", 0.98, "clock", "−2% КД щита Q"], ["Передислокация", "bastion_move", 0.02, "boot", "+2% скорости под щитом Q"], ["Ответный огонь", "bastion_rate", 0.025, "burst", "+2,5% урона под щитом Q"]],
					[["Дистанция", "brace_range", 0.025, "sight", "+2,5% урона от 140 px при стабильности"], ["Подача ленты", "brace_reload", 0.02, "reload", "−2% времени перезарядки при стабильности"], ["Тяжёлая пуля", "brace_knock", 0.06, "bullet", "+6% отброса при стабильности"], ["Удержание", "brace_damage", 0.018, "brace", "+1,8% урона при стабильности"]]
				] if class_id == "gunner" else [
					[["Ствол турели", "turret_damage", 0.45, "turret", "+0,45 урона пули турели"], ["Оптика турели", "turret_range", 4.0, "sight", "+4 px дальности турели"], ["Привод", "turret_rate", 0.025, "mag", "+2,5% темпа турели"], ["Аккумулятор", "turret_time", 0.15, "clock", "+0,15 с работы турели"]],
					[["Фланг", "crossfire", 0.02, "sight", "+2% урона при перекрёстном огне"], ["Наблюдение", "crossfire_window", 0.10, "clock", "+0,1 с отметки турели"], ["Прижать", "crossfire_knock", 0.10, "burst", "+10% отброса при перекрёстном огне"], ["Сектор", "crossfire", 0.02, "sight", "+2% урона при перекрёстном огне"]],
					[["Запасная батарея", "turret_cd_mul", 0.98, "clock", "−2% КД турели Q"], ["Аптечка", "turret_heal", 0.5, "med", "Установка турели лечит 0,5 HP"], ["Укрытие", "turret_guard", 0.025, "shield", "+0,025 с защиты при установке Q"], ["Ресурс", "turret_time", 0.15, "turret", "+0,15 с работы турели"]]
				]
				s = variants[c][i % 4]
			var id := "%s_%d_%d" % [class_id, c, i]
			var n := _entry(id, str(s[0]) + " " + ["I", "II", "III", "IV"][((i - 8) if i >= 8 else i) / 4], str(s[4]), str(s[3]), {s[1]: s[2]}, c, i)
			if i in [10, 11, 22, 23]:
				n["exclude"] = "%s_%d_%d" % [class_id, c, i + (1 if i % 2 == 0 else -1)]
				n["key"] = true
				n["cost"] = 2
				var choice: Array
				var doctrines: Array = [
					[["Упор", "brace_damage", 0.16, "brace", "+16% урона при стабильности"], ["Стена огня", "brace_knock", 0.8, "burst", "+80% отброса при стабильности"], ["Занять рубеж", "brace_gain", 0.8, "clock", "+80% скорости набора стабильности"], ["Дальняя оборона", "brace_range", 0.15, "sight", "+15% урона от 140 px при стабильности"]],
					[["Крепость", "bastion_reload", true, "reload", "Q мгновенно заряжает оружие"], ["Подвижный заслон", "bastion_move", 0.15, "boot", "+15% скорости под щитом Q"], ["Глубокая оборона", "bastion_time", 1.0, "shield", "+1 с щита Q"], ["Резервный экран", "bastion_cd_mul", 0.85, "clock", "−15% КД щита Q"]],
					[["Длинная очередь", "brace_persist", 0.8, "brace", "В движении стабильность теряется медленнее на 0,8 с"], ["Ответный залп", "bastion_rate", 0.20, "burst", "+20% урона под щитом Q"], ["Непрерывная подача", "brace_reload", 0.15, "reload", "−15% перезарядки при стабильности"], ["Прицельное подавление", "brace_damage", 0.15, "sight", "+15% урона при стабильности"]]
				] if class_id == "gunner" else [
					[["Двойная подача", "turret_double", true, "turret", "Две пули турели по 60% урона"], ["Тяжёлый ствол", "turret_damage", 2.0, "bullet", "+2 урона пули турели"], ["Дальний сектор", "turret_range", 40.0, "sight", "+40 px дальности турели"], ["Форсированный привод", "turret_rate", 0.25, "mag", "+25% темпа турели"]],
					[["Клещи", "crossfire", 0.20, "sight", "+20% урона при перекрёстном огне"], ["Прижать к земле", "crossfire_knock", 1.0, "burst", "+100% отброса при перекрёстном огне"], ["Длинная отметка", "crossfire_window", 1.2, "clock", "+1,2 с отметки турели"], ["Добить с фланга", "crossfire", 0.15, "bullet", "+15% урона при перекрёстном огне"]],
					[["Смена позиции", "turret_refill", true, "reload", "Установка Q заряжает оружие"], ["Ремкомплект", "turret_heal", 4.0, "med", "Установка Q лечит 4 HP"], ["Прикрытие отхода", "turret_guard", 0.4, "shield", "Установка Q даёт 0,4 с защиты"], ["Долгая смена", "turret_time", 2.0, "clock", "+2 с работы турели"]]
				]
				choice = doctrines[c][[10, 11, 22, 23].find(i)]
				n["name"] = choice[0]
				n["effects"] = {choice[1]: choice[2]}
				n["icon"] = choice[3]
				n["text"] = choice[4]
			out[id] = n


static func _link(out: Dictionary, a: String, b: String) -> void:
	if not out[a]["parents"].has(b): out[a]["parents"].append(b)
	if not out[b]["parents"].has(a): out[b]["parents"].append(a)


static func _wire(out: Dictionary, class_id: String) -> void:
	var groups: Array = [[], [], []]
	for id: String in out:
		var n: Dictionary = out[id]
		var cluster := int(n["branch"]) / 2 if class_id == "assault" and not id.begins_with("assault_") else int(n["branch"])
		n["cluster"] = cluster
		groups[cluster].append(id)
		n["parents"] = []
	# Небольшие кольца, развилки и поперечные связи вместо цепочек колонок.
	for c in 3:
		var group: Array = groups[c]
		for i in 24:
			var n: Dictionary = out[group[i]]
			n["start"] = i in [0, 8]
			n["key"] = not str(n["exclude"]).is_empty()
			var angle := float(i % 8) * TAU / 8.0 + (0.22 if i >= 8 and i < 16 else 0.0)
			angle += [0.0, 0.22, -0.17][CLASSES.find(class_id)] + c * 0.14
			var radius: float = [24.0, 48.0, 72.0][i / 8]
			if class_id == "gunner": radius *= 1.0 + (0.12 if i % 2 == 0 else -0.08)
			if class_id == "engineer": angle += (0.27 if i >= 16 else -0.12)
			var center: Vector2 = [Vector2(124, 190), Vector2(320, 185), Vector2(516, 190)][c]
			var shape := Vector2(1.03, 0.86) if class_id == "assault" else (Vector2(1.05, 0.79) if class_id == "gunner" else Vector2(0.94, 0.84))
			n["pos"] = center + Vector2(cos(angle), sin(angle)) * radius * shape
		for i in 24:
			if class_id != "gunner" or i % 8 != 7:
				_link(out, group[i], group[(i / 8) * 8 + (i + 1) % 8])
			if i >= 8:
				var offset := 2 if class_id == "engineer" else (1 if class_id == "gunner" and i % 2 == 1 else 0)
				_link(out, group[i], group[(i / 8 - 1) * 8 + (i + offset) % 8])
			if class_id == "engineer" and i < 8 and i % 2 == 0:
				_link(out, group[i], group[(i + 2) % 8])
	for c in 3:
		if c < 2: _link(out, groups[c][16], groups[c + 1][20])
	if class_id == "assault":
		for id: String in out:
			for parent: String in out[id].get("legacy_parents", []): _link(out, id, parent)


static func node(id: String) -> Dictionary:
	return catalog().get(id, {})


static func ids() -> Array[String]:
	var out: Array[String] = []
	out.assign(catalog().keys())
	return out


static func parents_met(n: Dictionary, selected: Dictionary) -> bool:
	if n.get("start", false) or n["parents"].is_empty():
		return true
	for id: String in n["parents"]:
		if selected.has(id):
			return true
	return false


static func bonuses(selected: Dictionary) -> Dictionary:
	var out := DEFAULTS.duplicate()
	out.merge({"brace_gain": 0.0, "bastion_cd_mul": 1.0, "brace_range": 0.0, "brace_reload": 0.0, "turret_range": 0.0, "turret_rate": 0.0, "crossfire_window": 0.0, "crossfire_knock": 0.0, "turret_cd_mul": 1.0})
	out.merge({"assault_return": 0.0, "brace_damage": 0.0, "brace_knock": 0.0, "bastion_time": 0.0, "bastion_reload": false, "bastion_move": 0.0, "brace_persist": 0.0, "bastion_rate": 0.0, "turret_damage": 0.0, "crossfire": 0.0, "turret_time": 0.0, "turret_heal": 0.0, "turret_refill": false, "turret_double": false, "turret_guard": 0.0})
	for id: String in selected:
		var n := node(id)
		for key: String in n.get("effects", {}):
			var value: Variant = n["effects"][key]
			if value is bool:
				out[key] = value
			elif key.ends_with("_mul"):
				out[key] *= value
			else:
				out[key] += value
	return out
