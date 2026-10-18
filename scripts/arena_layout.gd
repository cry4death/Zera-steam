class_name ArenaLayout
extends RefCounted
## Профиль — данные для O2; локальный RNG не меняет случайность боя.

const QUARANTINE := {"name": "quarantine", "size": Vector2(2560, 1440),
	"cars": 32, "barrels": 20, "checkpoints": 10, "litter": 320,
	"vehicles": [0, 1, 2, 3, 4], "roads": [0.5, 0.5], "safe_radius": 200.0}


static func generate(layout_seed: int, profile: Dictionary) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = layout_seed
	var size: Vector2 = profile.get("size", Vector2(2560, 1440))
	var center := size * 0.5
	var safe: float = profile.get("safe_radius", 200.0)
	var roads: Array = profile.get("roads", [0.5, 0.5])
	var vehicles: Array = profile.get("vehicles", [0, 1, 2, 3, 4])
	var result: Array[Dictionary] = []
	var occupied := PackedVector2Array()
	# Машины в двух полосах двух дорог; отдельные развёрнуты после аварии.
	for i in int(profile.get("cars", 32)):
		for attempt in 200:
			var horizontal := i % 2 == 0
			var lane := -65.0 if i % 4 < 2 else 65.0
			var p := Vector2(rng.randf_range(120, size.x - 120), size.y * float(roads[1]) + lane)
			if not horizontal:
				p = Vector2(size.x * float(roads[0]) + lane, rng.randf_range(110, size.y - 110))
			if not _available(p, occupied, center, safe, 104.0):
				continue
			var angle := (0.0 if horizontal else PI * 0.5) + rng.randf_range(-0.17, 0.17)
			if i % 9 == 0:
				angle += 0.5
			result.append({"kind": int(vehicles[i % vehicles.size()]), "pos": p, "angle": angle})
			occupied.append(p)
			break
	# Открытые блокпосты: линии не соединяются в замкнутый периметр.
	for i in int(profile.get("checkpoints", 10)):
		for attempt in 200:
			var p := Vector2(rng.randf_range(100, size.x - 100), rng.randf_range(100, size.y - 100))
			if not _available(p, occupied, center, safe + 45.0, 120.0):
				continue
			var angle := float(i % 2) * PI * 0.5
			for j in 3:
				var at := p + Vector2(float(j - 1) * 49.0, 0).rotated(angle)
				result.append({"kind": 7 if j < 2 else (8 if i % 2 == 0 else 10), "pos": at, "angle": angle})
			occupied.append(p)
			break
	for i in int(profile.get("barrels", 20)):
		var at: Vector2 = result[i % mini(32, result.size())]["pos"]
		var p := at + Vector2(0, 51.0 if i % 2 == 0 else -51.0)
		result.append({"kind": 5 if i % 3 != 0 else 6, "pos": p, "angle": rng.randf() * TAU})
	for i in 12:
		var p := Vector2(170.0 + float(i % 6) * 430.0, 60.0 if i < 6 else size.y - 60.0)
		result.append({"kind": 9, "pos": p, "angle": 0.0})
	for i in int(profile.get("litter", 320)):
		var p := Vector2(rng.randf_range(30, size.x - 30), rng.randf_range(30, size.y - 30))
		result.append({"kind": 11 + i % 6, "pos": p, "angle": rng.randf() * TAU})
	# Проверяем именно сетку с запасом элитки, которую затем использует орда.
	var probe := Obstacles.new()
	for attempt in 40:
		probe.setup(Rect2(Vector2.ZERO, size), result)
		var unreachable := probe.unreachable_cell()
		if unreachable == -1:
			break
		var at := probe.cell_center(unreachable)
		var nearest := -1
		var distance := INF
		for i in result.size():
			if int(result[i]["kind"]) >= 11:
				continue
			var d := Vector2(result[i]["pos"]).distance_squared_to(at)
			if d < distance:
				nearest = i
				distance = d
		if nearest < 0:
			break
		var p := Vector2(result[nearest]["pos"]) + Vector2(90, 75).rotated(float(attempt) * 2.4)
		p = p.clamp(Vector2(95, 95), size - Vector2(95, 95))
		if p.distance_to(center) < safe + 55.0:
			p = center + (p - center).normalized() * (safe + 90.0)
		result[nearest]["pos"] = p
	probe.free()
	return result


static func _available(p: Vector2, occupied: PackedVector2Array, center: Vector2, safe: float, gap: float) -> bool:
	if p.distance_squared_to(center) < (safe + 55.0) * (safe + 55.0):
		return false
	for q in occupied:
		if p.distance_squared_to(q) < gap * gap:
			return false
	return true
