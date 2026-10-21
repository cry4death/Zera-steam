class_name SetPieces
extends RefCounted
## Фиксированные места коллизий. RNG меняет только кузова, состояние и мелкий мусор.


static func structure(at: Vector2, size: Vector2, skin: int, angle := 0.0) -> Dictionary:
	return {"kind": Obstacles.Kind.STRUCTURE, "pos": at, "half": size * 0.5, "skin": skin, "angle": angle}


static func build(piece: Dictionary, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var id: String = piece["type"]
	match id:
		"traffic":
			for i in 5:
				rows.append({"kind": rng.randi_range(0, 1), "pos": Vector2(i * 90 - 180, 0), "angle": 0.0, "state": rng.randi_range(0, 1)})
		"convoy":
			for i in 5:
				rows.append({"kind": Obstacles.Kind.TRUCK if i < 4 else Obstacles.Kind.JEEP, "pos": Vector2(i * 110 - 220, 0)})
		"crash":
			rows.append({"kind": rng.randi_range(0, 1), "pos": Vector2(-70, -32), "angle": 0.28, "state": Obstacles.State.WRECK})
			rows.append({"kind": Obstacles.Kind.JEEP, "pos": Vector2(65, 38), "angle": -0.65, "state": Obstacles.State.DAMAGED})
		"checkpoint":
			rows.append(structure(Vector2(-104, -104), Vector2(56, 48), 3))
			for i in 3:
				rows.append({"kind": Obstacles.Kind.JERSEY, "pos": Vector2(-100 + i * 47, -42)})
				rows.append({"kind": Obstacles.Kind.JERSEY, "pos": Vector2(24 + i * 47, 72)})
			rows.append({"kind": Obstacles.Kind.POLICE, "pos": Vector2(124, -100), "angle": PI * 0.5})
			rows.append(structure(Vector2(-48, -105), Vector2(48, 5), 2))
		"gas_station":
			rows.append(structure(Vector2(-12, -42), Vector2(146, 78), 4))
			rows.append(structure(Vector2(130, -35), Vector2(76, 36), 6))
			for i in 2:
				rows.append(structure(Vector2(-55 + i * 80, 30), Vector2(16, 12), 11))
				rows.append({"kind": Obstacles.Kind.RED, "pos": Vector2(100 + i * 23, 38)})
		"parking":
			for i in [0, 1, 3, 4, 6]:
				rows.append({"kind": rng.randi_range(0, 1), "pos": Vector2(float(i) * 52 - 156, 0), "angle": PI * 0.5, "state": rng.randi_range(0, 1)})
		"construction":
			rows.append(structure(Vector2(0, -62), Vector2(180, 6), 2))
			rows.append({"kind": Obstacles.Kind.WOOD, "pos": Vector2(-55, 0)})
			rows.append({"kind": Obstacles.Kind.WOOD, "pos": Vector2(36, 18)})
		"field_post", "airfield_post":
			rows.append({"kind": Obstacles.Kind.TRUCK, "pos": Vector2(0, -60)})
			# На аэродроме отсечки пропускают и самые широкие тела PF1.
			var spread := 88.0 if id == "airfield_post" else 75.0
			for i in 5:
				var a := float(i) * 0.48 + 0.5
				rows.append({"kind": Obstacles.Kind.BAGS, "pos": Vector2.from_angle(a) * spread, "angle": a + PI * 0.5})
			rows.append(structure(Vector2(-83, -50), Vector2(24, 28), 9))
		"bus_stop":
			rows.append(structure(Vector2(0, -24), Vector2(90, 28), 3))
			rows.append(structure(Vector2(80, -20), Vector2(34, 40), 0))
		"containers":
			for i in 3:
				rows.append(structure(Vector2(0, float(i) * 96 - 96), Vector2(152, 48), 5))
		"camp":
			rows.append(structure(Vector2(-120, -100), Vector2(120, 66), 10))
			rows.append(structure(Vector2(110, -80), Vector2(96, 60), 10))
			rows.append(structure(Vector2(80, 96), Vector2(60, 48), 9))
			rows.append({"kind": Obstacles.Kind.TRUCK, "pos": Vector2(-110, 100), "state": Obstacles.State.WRECK})
		"fountain":
			rows.append(structure(Vector2.ZERO, Vector2(80, 64), 7))
		"blast_wall":
			rows.append(structure(Vector2.ZERO, Vector2(128, 16), 14))
		"radar":
			rows.append(structure(Vector2.ZERO, Vector2(64, 48), 15))
			rows.append({"kind": Obstacles.Kind.TRUCK, "pos": Vector2(0, 62)})
		"helicopter":
			rows.append(structure(Vector2.ZERO, Vector2(88, 28), 16))
			rows.append(structure(Vector2(-65, 0), Vector2(52, 10), 16))
			rows.append({"kind": Obstacles.Kind.BOARDS, "pos": Vector2(20, 30), "angle": 0.4})
		"fuel_bowser":
			rows.append(structure(Vector2.ZERO, Vector2(76, 36), 6))
			rows.append({"kind": Obstacles.Kind.TRUCK, "pos": Vector2(-110, 0)})
			for i in 3:
				rows.append({"kind": Obstacles.Kind.RED, "pos": Vector2(20 + i * 24, 52)})
		"dock_crane":
			rows.append(structure(Vector2.ZERO, Vector2(96, 80), 19))
		"cargo_spill":
			rows.append(structure(Vector2(-48, 0), Vector2(60, 48), 9))
			rows.append(structure(Vector2(40, 18), Vector2(24, 28), 9))
			rows.append({"kind": Obstacles.Kind.RED, "pos": Vector2(2, -35)})
		"bus_wreck":
			rows.append(structure(Vector2.ZERO, Vector2(112, 32), 20))
		"dumpsters":
			rows.append(structure(Vector2.ZERO, Vector2(32, 20), 21))
			rows.append({"kind": Obstacles.Kind.RUBBISH, "pos": Vector2(30, 10)})
	# Мусор группируется у сценки, вне её коллизий; проезжая часть между сценками чистая.
	var litter := 24 if id == "crash" else (5 if id == "fountain" else 12)
	for i in litter:
		var at := Vector2(rng.randf_range(-110, 110), rng.randf_range(50, 72))
		var k := 11 + i % 6
		if id == "crash":
			at = (Vector2(-70, -32) if i % 2 == 0 else Vector2(65, 38)) + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(18, 60)
			k = Obstacles.Kind.GLASS if i % 4 != 0 else Obstacles.Kind.TIRES
		elif id == "traffic" or id == "convoy":
			at = Vector2(float(i % 5 - 2) * (110.0 if id == "convoy" else 90.0) + rng.randf_range(-35, 35), rng.randf_range(22, 38) * (-1 if i % 2 == 0 else 1))
		elif id == "containers":
			at = Vector2(rng.randf_range(83, 110), float(i % 3 - 1) * 96 + rng.randf_range(-30, 30))
		elif id == "bus_stop" or id == "fountain":
			k = Obstacles.Kind.PAPER if i % 3 != 0 else Obstacles.Kind.RUBBISH
		elif id == "construction":
			k = Obstacles.Kind.BOARDS if i % 3 != 0 else Obstacles.Kind.CONE
		rows.append({"kind": k, "pos": at, "angle": rng.randf() * TAU})
	var origin := MapLoader.point(piece["at"])
	var turn := deg_to_rad(float(piece.get("angle", 0)))
	for row in rows:
		row["pos"] = origin + Vector2(row["pos"]).rotated(turn)
		row["angle"] = float(row.get("angle", 0.0)) + turn
	return rows
