class_name CampaignCatalog
extends RefCounted
## Статические данные оперативной карты Z.E.R.A.

## Место операции определяется регионом, в том числе для старых сохранённых предложений.
const REGION_MAPS := {
	"east_europe": "quarantine_checkpoint", "west_europe": "old_town",
	"north_africa": "open_perimeter", "middle_east": "military_airfield",
	"siberia": "military_airfield", "east_asia": "residential_district",
	"north_america": "residential_district", "south_asia": "cargo_port"}

const BALANCE := {
	"seed": 20261017, "max_seed": 2147483647, "max_turn": 1000000,
	"infection_min": 0, "infection_max": 100, "stages": [20, 40, 60, 80],
	"initial_infection": {"east_europe": 64, "west_europe": 28, "siberia": 52, "middle_east": 43, "north_africa": 22, "east_asia": 47, "north_america": 12, "south_asia": 35},
	"lost_neighbor_bonus": 1, "reclaim_crate_bonus": 0.15, "node_hp": 12000.0,
	"self_growth": 1, "neighbor_pressure": 2, "neighbor_cap": 4,
	"nest_pressure": 2, "growth_cap": 6, "suppression": 3,
	"victory": {"infection": -28, "neighbors": -3, "suppression": 2},
	"partial": {"infection": -12, "neighbors": 0, "suppression": 1},
	"defeat": {"infection": 7, "neighbors": 0, "suppression": 0},
	"nest": {"infection": -40, "neighbors": -8, "suppression": 3},
	"offers": 3, "safe_max": 2, "threat_min": 1, "threat_max": 5,
	"standard_threat": 3, "nest_threat": 4, "risky_min": 4,
	"threat_weights": [1, 2, 3, 4, 5], "priority_critical": 4, "priority_nest": 3, "priority_asset": 2,
	"dna_mul": [1.0, 1.05, 1.15, 1.25, 1.35], "crate_chance": [0.0, 0.05, 0.10, 0.15, 0.20],
	"nest_dna_bonus": 0.15, "cache_dna_bonus": 0.10, "cache_crate_bonus": 0.15,
	"max_dna_mul": 1.6, "max_crate_chance": 0.5, "max_modifiers": 2,
	"defeat_lost": 3, "victory_average": 35,
	"extract": {"infection": -10, "neighbors": 0, "suppression": 1},
	"reclaim": {"infection": -38, "neighbors": -3, "suppression": 2},
	"extract_crate_bonus": 0.25, "reclaim_dna_bonus": 0.2,
	"node_time": 0.0, "pickup_hold": 3.0, "evac_hold": 25.0, "evac_time": 300.0,
	"final_required": 1, "reward_limit": 10000000,
	"front_period": 3, "front_infection": 8, "outpost_suppression": 2,
	"assault_turn": 6, "assault_outposts": 3, "assault_samples": 2,
}

const KEY_REGIONS := ["east_europe", "west_europe", "siberia", "middle_east"]
const STAGE_COMBAT := [
	{"threat": 1, "modifiers": []},
	{"threat": 2, "modifiers": []},
	{"threat": 3, "modifiers": ["runner_surge"]},
	{"threat": 4, "modifiers": ["acid_rain"]},
	{"threat": 4, "modifiers": ["elite_hunt"]},
]

const REGIONS := {
	"east_europe": {"id": "east_europe", "name": "Восточная Европа", "lat": 52.0, "lon": 30.0, "neighbors": ["west_europe", "siberia", "middle_east"], "traits": ["Полевые укрепления"], "infection": BALANCE["initial_infection"]["east_europe"], "asset": "Карантинная зона"},
	"west_europe": {"id": "west_europe", "name": "Западная Европа", "lat": 48.0, "lon": 6.0, "neighbors": ["east_europe", "north_africa", "north_america"], "traits": ["Городской периметр"], "infection": BALANCE["initial_infection"]["west_europe"], "asset": "Узел связи"},
	"siberia": {"id": "siberia", "name": "Сибирь", "lat": 61.0, "lon": 95.0, "neighbors": ["east_europe", "east_asia"], "traits": ["Мороз", "Лаборатории"], "infection": BALANCE["initial_infection"]["siberia"], "asset": "Лабораторный комплекс"},
	"middle_east": {"id": "middle_east", "name": "Ближний Восток", "lat": 30.0, "lon": 45.0, "neighbors": ["east_europe", "north_africa", "south_asia"], "traits": ["Промышленная зона"], "infection": BALANCE["initial_infection"]["middle_east"], "asset": "Военная база"},
	"north_africa": {"id": "north_africa", "name": "Северная Африка", "lat": 27.0, "lon": 15.0, "neighbors": ["west_europe", "middle_east"], "traits": ["Открытый периметр"], "infection": BALANCE["initial_infection"]["north_africa"], "asset": ""},
	"east_asia": {"id": "east_asia", "name": "Восточная Азия", "lat": 36.0, "lon": 116.0, "neighbors": ["siberia", "south_asia"], "traits": ["Мегаполис"], "infection": BALANCE["initial_infection"]["east_asia"], "asset": "Коллектор"},
	"north_america": {"id": "north_america", "name": "Северная Америка", "lat": 42.0, "lon": -100.0, "neighbors": ["west_europe"], "traits": ["Автомагистрали"], "infection": BALANCE["initial_infection"]["north_america"], "asset": "Гарнизон"},
	"south_asia": {"id": "south_asia", "name": "Южная Азия", "lat": 21.0, "lon": 78.0, "neighbors": ["middle_east", "east_asia"], "traits": ["Транспортный узел"], "infection": BALANCE["initial_infection"]["south_asia"], "asset": "Центральный улей"},
}
const DECORATIONS := [
	{"id": "arctic", "name": "Арктические объекты", "lat": 80.0, "lon": 0.0, "status": "Нет связи"},
	{"id": "oceania", "name": "Океания", "lat": -25.0, "lon": 135.0, "status": "Нет связи"},
	{"id": "pacific_facility", "name": "Тихоокеанская платформа", "lat": 0.0, "lon": -150.0, "status": "Нет связи"},
]
const NESTS := {
	"object_7": {"region_id": "east_europe", "name": "Объект-7", "playable": true},
	"mother": {"region_id": "siberia", "name": "Матка", "playable": true, "pressure": 0},
	"meat_mountain": {"region_id": "east_asia", "name": "Мясная гора", "playable": true, "pressure": 0},
	"general": {"region_id": "middle_east", "name": "Генерал", "playable": true, "pressure": 0},
	"hive_heart": {"region_id": "south_asia", "name": "Сердце Улья", "playable": true, "pressure": 0},
}
const MODIFIERS := ["runner_surge", "elite_hunt", "acid_rain", "blood_frenzy", "hardened_boss", "resource_cache"]
## Единый словарь названий условий операции: брифинг («text»), баннер («name»), HUD («short»).
const MODIFIER_INFO := {
	"runner_surge": {"name": "Прорыв бегунов", "short": "Бегуны", "text": "Прорыв бегунов: быстрые группы"},
	"elite_hunt": {"name": "Элитные группы", "short": "Элитные", "text": "Элитные группы: больше усиленных особей"},
	"acid_rain": {"name": "Кислотные выбросы", "short": "Кислота", "text": "Кислотные выбросы: плевальщики"},
	"blood_frenzy": {"name": "Дополнительная тревога", "short": "Доп. тревога 4:00", "text": "Дополнительная тревога на 4:00"},
	"hardened_boss": {"name": "Усиленный объект", "short": "HP объекта +25%", "text": "Усиленный объект: +25% здоровья"},
	"resource_cache": {"name": "Запас снабжения", "short": "Снабжение", "text": "Запас снабжения: больше ДНК и шанс ящика"},
}
## Эти пары вместе перегружают арену; генератор их исключает.
const INCOMPATIBLE := [["acid_rain", "blood_frenzy"], ["runner_surge", "blood_frenzy"]]
## Названия операций по заданию. Старые сохранённые предложения хранят прежние имена — они остаются валидными.
const OP_NAMES := {"clearance": "Зачистка периметра", "nest": "Ликвидация Объекта-7", "extract": "Извлечение образца", "reclaim": "Возврат региона"}
## Раньше имя собиралось из двух списков по 5 слов; два броска генератора сохранены, чтобы seed и состав операций не менялись.
const LEGACY_NAME_DRAWS := 5
const STAGES := ["Удерживается", "Нестабильно", "Заражено", "Критически", "Потеряно"]


static func compatible(modifiers: Array) -> bool:
	for pair: Array in INCOMPATIBLE:
		if modifiers.has(pair[0]) and modifiers.has(pair[1]):
			return false
	return true


static func effect_key(type: String) -> String:
	return type if type in ["nest", "extract", "reclaim"] else "victory"


static func objective(type: String) -> String:
	return {"nest": "kill_boss", "extract": "extract_sample"}.get(type, "destroy_node")


static func type_label(type: String) -> String:
	return {"nest": "Удар по улью", "extract": "Извлечение", "reclaim": "Возврат"}.get(type, "Зачистка")


static func nest_in(region: String) -> String:
	for id: String in NESTS:
		if NESTS[id]["region_id"] == region:
			return id
	return ""


static func region_modifiers(state: Dictionary, region: String, modifiers: Array) -> Array:
	var result := modifiers.duplicate()
	if not state["nests"]["mother"]["alive"] and (region == "siberia" or REGIONS["siberia"]["neighbors"].has(region)):
		result.erase("elite_hunt")
	if not state["nests"]["meat_mountain"]["alive"] and region == "east_asia":
		result.erase("acid_rain")
	return result
