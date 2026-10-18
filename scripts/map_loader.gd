class_name MapLoader
extends RefCounted
## JSON хранит два читаемых ASCII-слоя и список сценок; координаты сценок — в клетках.

const IDS := ["quarantine_checkpoint", "old_town", "open_perimeter"]
const REGION_MAP := {
	"east_europe": "quarantine_checkpoint", "west_europe": "old_town",
	"north_africa": "open_perimeter", "middle_east": "open_perimeter",
	"siberia": "quarantine_checkpoint", "east_asia": "old_town",
	"north_america": "quarantine_checkpoint", "south_asia": "old_town",
	"south_america": "old_town", "central_africa": "open_perimeter",
	"southeast_asia": "old_town", "oceania": "quarantine_checkpoint",
	"arctic": "quarantine_checkpoint", "pacific_facility": "quarantine_checkpoint"}
const CELL := 32.0
const SKINS := {"B": 0, "R": 1, "W": 2, "T": 8}


static func load_map(id: String) -> Dictionary:
	if not IDS.has(id):
		push_error("MAP unknown id: " + id)
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string("res://maps/%s.json" % id)) != OK:
		push_error("MAP invalid JSON: " + id)
		return {}
	var data: Dictionary = parser.data
	var ground: Array = data.get("ground", [])
	var structures: Array = data.get("structures", [])
	if ground.is_empty() or structures.size() != ground.size():
		return {}
	var width := String(ground[0]).length()
	for y in ground.size():
		if String(ground[y]).length() != width or String(structures[y]).length() != width:
			push_error("MAP invalid row: %s:%d" % [id, y])
			return {}
	data["id"] = id
	data["size"] = Vector2(width, ground.size()) * CELL
	data["start"] = point(data["player_start"])
	var entries := PackedVector2Array()
	for p: Array in data["entries"]:
		entries.append(point(p))
	data["spawn_points"] = entries
	return data


static func point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1])) * CELL


static func layout(data: Dictionary, detail_seed: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var rows: Array = data["structures"]
	var width := String(rows[0]).length()
	var used := PackedByteArray()
	used.resize(width * rows.size())
	# Соседние клетки одного материала объединяются в прямоугольники коллизии.
	for y in rows.size():
		for x in width:
			var symbol := String(rows[y]).substr(x, 1)
			if not SKINS.has(symbol) or used[x + y * width] != 0:
				continue
			var w := 1
			while x + w < width and used[x + w + y * width] == 0 and String(rows[y]).substr(x + w, 1) == symbol:
				w += 1
			var h := 1
			var extend := true
			while y + h < rows.size() and extend:
				for xx in range(x, x + w):
					if used[xx + (y + h) * width] != 0 or String(rows[y + h]).substr(xx, 1) != symbol:
						extend = false
						break
				if extend:
					h += 1
			for yy in range(y, y + h):
				for xx in range(x, x + w):
					used[xx + yy * width] = 1
			result.append(SetPieces.structure(Vector2(x + w * 0.5, y + h * 0.5) * CELL, Vector2(w, h) * CELL, int(SKINS[symbol])))
	result.append_array(ArenaLayout.generate(detail_seed, data))
	return result
