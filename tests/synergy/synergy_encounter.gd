extends "res://tests/synergy/synergy_scenarios.gd"
## Одинаковые группы: дальнее слабое тело, пауза, сближение с фронтом.

func _run() -> void:
	Meta.persist = false
	Meta.reset()
	get_tree().paused = true
	for variant in ["empty", "link", "twin", "pierce", "split", "chain", "detonator", "passive", "level"]:
		var total := 0.0
		var charged := 0
		for run_seed in range(92000, 92030):
			seed(run_seed)
			world(["mosin", "butcher"])
			match variant:
				"link": guns.install_link(1, 0)
				"twin", "pierce", "split", "chain", "detonator":
					var module: int = {"twin": WeaponDefs.Module.TWIN, "pierce": WeaponDefs.Module.PIERCE, "split": WeaponDefs.Module.SPLIT, "chain": WeaponDefs.Module.CHAIN, "detonator": WeaponDefs.Module.DETONATOR}[variant]
					guns.slots[1].modules.append({"id": module, "rank": 1, "rare": false})
				"passive": guns.passives[WeaponDefs.Passive.DAMAGE] = 1
				"level": guns.slots[1].level = 2
			guns.refresh_all()
			for s in guns.slots:
				s.angle = 0.0
				s.stats["crit"] = 0.0
			var e := crowd.spawn(player.position + Vector2(210, -5))
			crowd.hp[e] = 10.0
			crowd.max_hp[e] = 10.0
			crowd._rebuild_grid()
			for aim in 3:
				guns.slots[0].angle = (crowd.pos[e] - guns.gun_point(0, guns.slots[0].muzzle)).angle()
			guns._fire_shot(0, guns.slots[0], e)
			for frame in 90: guns._update_bullets(1.0 / 120.0)
			guns._update_links(0.75)
			if guns.link_metrics["received"] > 0.0: charged += 1
			var layout := RandomNumberGenerator.new()
			layout.seed = run_seed
			# Поперечный фронт: нет второго ряда для пробивания; толстые цели переживают дробину.
			if OS.get_cmdline_user_args().has("--column"):
				for x in [65, 85, 105]:
					for y in range(-24, 25, 12):
						e = crowd.spawn(player.position + Vector2(x, y) + Vector2(layout.randf_range(-2, 2), layout.randf_range(-2, 2)))
						crowd.hp[e] = 24.0
						crowd.max_hp[e] = 24.0
			else:
				for k in 7:
					var a := (k - 3) * 0.14
					e = crowd.spawn(player.position + Vector2.from_angle(a) * layout.randf_range(64, 72))
					crowd.hp[e] = 60.0
					crowd.max_hp[e] = 60.0
			crowd._rebuild_grid()
			useful_hp = 0.0
			guns._fire_shot(1, guns.slots[1], e)
			for frame in 90: guns._update_bullets(1.0 / 120.0)
			total += useful_hp
			guns.free()
			hazards.free()
			crowd.free()
			player.free()
		print("BATTERY variant=%s seeds=30 receiver_hp=%.3f charged=%d" % [variant, total / 30.0, charged])
	get_tree().quit()
