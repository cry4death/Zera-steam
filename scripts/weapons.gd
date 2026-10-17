class_name Weapons
extends Node2D
## Модульное оружие (GDD §5): до 4 стволов, каждый = основа + патроны + модули.
## Стволы стреляют сами: автомат и дробовик — пулями, рейлган — мгновенным лучом,
## гранатомёт — гранатами со взрывом. Пули, лучи, гранаты и взрывы — данные в массивах.

signal prototype_unlocked(slot: int, proto_name: String)

const BULLET_RADIUS := 1.5
const SHARD_SPEED := 300.0
const GRENADE_KNOCK := 120.0 # отброс от гранаты игрока

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

var player: Player
var camera: GameCamera
var horde: Horde
var effects: Effects
var floor_decals: FloorDecals
var passives := {} # WeaponDefs.Passive → уровень (заполняет прогрессия)

var slots: Array[Slot] = []
var bullet_count := 0

# пули: позиция, скорость, жизнь, урон, ствол, пробивание, отскоки, флаги, uid последней цели
const F_SHARD := 1 # осколок сплита: сам не делится
const F_CHAIN := 2 # снаряд цепи
var _bpos := PackedVector2Array()
var _bvel := PackedVector2Array()
var _blife := PackedFloat32Array()
var _bdmg := PackedFloat32Array()
var _bslot := PackedInt32Array()
var _bpierce := PackedInt32Array()
var _bbounce := PackedInt32Array()
var _bflags := PackedInt32Array()
var _blast := PackedInt32Array()
var _bdepth := PackedInt32Array() # глубина цепи

# гранаты
var _gpos := PackedVector2Array()
var _gvel := PackedVector2Array()
var _gleft := PackedFloat32Array() # оставшийся путь
var _gslot := PackedInt32Array()
var _gdmg := PackedFloat32Array()
var _grad := PackedFloat32Array()
var _gsmall := PackedByteArray() # кассетная мини-граната

# эффекты для отрисовки: лучи [от, до, ширина, время, цвет], взрывы [центр, радиус, время]
var _beams: Array = []
var _blasts: Array = []
var _flashes: Array = [] # [позиция, угол, время]
var _aim_hold := 0.0


func _ready() -> void:
	add_weapon(WeaponDefs.Base.RIFLE)


# --- управление стволами -----------------------------------------------------------

func add_weapon(base: int) -> void:
	var s := Slot.new()
	s.base = base
	slots.append(s)
	refresh(slots.size() - 1)
	s.mag = s.stats["mag"]


func has_base(base: int) -> bool:
	for s in slots:
		if s.base == base:
			return true
	return false


## Пересчёт статов ствола: основа + уровень + пассивки + модули, проверка прототипа.
func refresh(i: int) -> void:
	var s := slots[i]
	var st := WeaponDefs.base_stats(s.base, s.level)
	st["damage"] *= 1.0 + _passive(WeaponDefs.Passive.DAMAGE)
	st["rate"] *= 1.0 + _passive(WeaponDefs.Passive.FIRE_RATE)
	st["reload"] *= 1.0 - _passive(WeaponDefs.Passive.RELOAD)
	# сдвоенный ствол
	var twin := s.mod_rank(WeaponDefs.Module.TWIN)
	if twin > 0:
		var extra := twin + (1 if s.module(WeaponDefs.Module.TWIN)["rare"] else 0)
		if s.base == WeaponDefs.Base.SHOTGUN:
			extra *= 2
		st["proj"] += extra
		st["damage"] *= [0.9, 0.85, 0.85][twin - 1] if not s.module(WeaponDefs.Module.TWIN)["rare"] else 1.0
	# пробивание у рейлгана — бонус урона
	if s.base == WeaponDefs.Base.RAIL:
		st["damage"] *= 1.0 + 0.2 * s.mod_rank(WeaponDefs.Module.PIERCE)
	if s.base == WeaponDefs.Base.LAUNCHER:
		st["radius"] *= 1.0 + 0.15 * s.mod_rank(WeaponDefs.Module.PIERCE)
	# прототип
	var before := s.prototype
	s.prototype = -1
	for p in WeaponDefs.PROTOTYPES.size():
		var r: Dictionary = WeaponDefs.PROTOTYPES[p]
		if s.base == r["base"] and s.level >= WeaponDefs.MAX_LEVEL and s.ammo == r["ammo"] and s.mod_rank(r["module"]) > 0:
			s.prototype = p
	if s.prototype == 1:
		st["width"] *= 1.5
	s.stats = st
	if s.prototype >= 0 and s.prototype != before:
		prototype_unlocked.emit(i, WeaponDefs.PROTOTYPES[s.prototype]["name"])


## Суммарный бонус пассивки: «за уровень» × уровень.
func _passive(p: int) -> float:
	var per: float = WeaponDefs.PASSIVES[p]["per_level"]
	var lv: int = passives.get(p, 0)
	return per * lv


func refresh_all() -> void:
	for i in slots.size():
		refresh(i)


## Тактическая перезарядка (R): все неполные магазины.
func reload_all() -> void:
	for s in slots:
		if not s.reloading and s.mag < s.stats["mag"]:
			_start_reload(s)


# --- кадр -----------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_update_bullets(delta)
	_update_grenades(delta)
	_age_fx(delta)
	queue_redraw()
	if player == null or player.is_dead:
		return
	_aim_hold -= delta
	if _aim_hold <= 0.0:
		player.aim_dir = Vector2.ZERO
	if Input.is_action_just_pressed("reload"):
		reload_all()
	for i in slots.size():
		_update_slot(i, delta)


func _update_slot(i: int, delta: float) -> void:
	var s := slots[i]
	s.cooldown -= delta
	if s.reloading:
		s.reload_t += delta
		if s.reload_t >= s.stats["reload"]:
			s.reloading = false
			s.mag = s.stats["mag"]
		return
	if s.cooldown > 0.0:
		return
	var origin := player.global_position
	var target := horde.find_nearest(origin, s.stats["range"])
	if target == -1:
		return
	var dir := (horde.pos[target] - origin).normalized()
	player.aim_dir = dir
	_aim_hold = 0.4
	player.kick()
	var muzzle := origin + dir * 9.0 - dir.orthogonal() * 1.5
	match s.base:
		WeaponDefs.Base.RIFLE, WeaponDefs.Base.SHOTGUN:
			_fire_bullets(i, muzzle, dir)
		WeaponDefs.Base.RAIL:
			_fire_rail(i, muzzle, dir)
		WeaponDefs.Base.LAUNCHER:
			_fire_grenades(i, muzzle, horde.pos[target])
	_flashes.append([muzzle, dir.angle(), 0.05])
	s.mag -= 1
	s.cooldown = maxf(s.cooldown, 0.0) + 1.0 / s.stats["rate"]
	if s.mag <= 0:
		_start_reload(s)


func _start_reload(s: Slot) -> void:
	s.reloading = true
	s.reload_t = 0.0


func reload_progress(i: int) -> float:
	var s := slots[i]
	return clampf(s.reload_t / s.stats["reload"], 0.0, 1.0) if s.reloading else 1.0


# --- пули ------------------------------------------------------------------------------------

func _fire_bullets(i: int, muzzle: Vector2, dir: Vector2) -> void:
	var s := slots[i]
	var st := s.stats
	var n: int = st["proj"]
	var spread := deg_to_rad(st["spread"])
	var pierce := int(s.mod_value(WeaponDefs.Module.PIERCE, [2, 4, 6]))
	var bounce := int(s.mod_value(WeaponDefs.Module.RICOCHET, [1, 2, 3]))
	for k in n:
		var a := dir.angle()
		if s.base == WeaponDefs.Base.SHOTGUN:
			a += randf_range(-spread, spread) * 0.5
		else:
			# автомат: несколько пуль идут небольшим веером
			a += (k - (n - 1) * 0.5) * deg_to_rad(5.0) + randf_range(-spread, spread) * 0.5
		var spd: float = st["speed"] * (randf_range(0.85, 1.1) if s.base == WeaponDefs.Base.SHOTGUN else 1.0)
		_spawn_bullet(muzzle, Vector2.from_angle(a) * spd, st["range"] / spd, st["damage"], i, pierce, bounce, 0)
	if effects:
		effects.casing(player.global_position, dir)


func _spawn_bullet(p: Vector2, v: Vector2, life: float, dmg: float, slot: int, pierce: int, bounce: int, flags: int, depth := 0) -> void:
	var b := bullet_count
	if b >= _bpos.size():
		_bpos.resize(b + 128)
		_bvel.resize(b + 128)
		_blife.resize(b + 128)
		_bdmg.resize(b + 128)
		_bslot.resize(b + 128)
		_bpierce.resize(b + 128)
		_bbounce.resize(b + 128)
		_bflags.resize(b + 128)
		_blast.resize(b + 128)
		_bdepth.resize(b + 128)
	_bpos[b] = p
	_bvel[b] = v
	_blife[b] = life
	_bdmg[b] = dmg
	_bslot[b] = slot
	_bpierce[b] = pierce
	_bbounce[b] = bounce
	_bflags[b] = flags
	_blast[b] = -1
	_bdepth[b] = depth
	bullet_count += 1


func _update_bullets(delta: float) -> void:
	var i := bullet_count - 1
	while i >= 0:
		var p0 := _bpos[i]
		var v := _bvel[i]
		var p1 := p0 + v * delta
		_blife[i] -= delta
		var probe := p0.lerp(p1, 0.5)
		var hit := _find_hit_except(probe, _blast[i])
		if hit == -1:
			probe = p1
			hit = _find_hit_except(probe, _blast[i])
		if hit != -1:
			if not _bullet_hit(i, hit, probe):
				_remove_bullet(i)
				i -= 1
				continue
		elif _blife[i] <= 0.0:
			_remove_bullet(i)
			i -= 1
			continue
		_bpos[i] = probe if hit != -1 else p1
		i -= 1


func _find_hit_except(p: Vector2, last_uid: int) -> int:
	var hit := horde.find_hit(p, BULLET_RADIUS)
	if hit != -1 and horde.uid[hit] == last_uid:
		return -1
	return hit


## Попадание пули. Возвращает true, если пуля летит дальше (пробила/отскочила).
func _bullet_hit(b: int, e: int, at: Vector2) -> bool:
	var slot := _bslot[b]
	var s := slots[slot] if slot < slots.size() else slots[0]
	var dir := _bvel[b].normalized()
	var killed := _hit_enemy(slot, e, _bdmg[b], dir, at, s.stats["knock"])
	_blast[b] = horde.uid[e]
	# сплит: осколки веером (сами не делятся)
	if _bflags[b] & F_SHARD == 0 and s.mod_rank(WeaponDefs.Module.SPLIT) > 0:
		_spawn_shards(slot, at, dir, _bdmg[b], horde.uid[e])
	if killed:
		_on_kill(slot, e, dir, _bdepth[b])
	if _bpierce[b] > 0:
		_bpierce[b] -= 1
		_bdmg[b] *= 1.2 if s.mod_rank(WeaponDefs.Module.PIERCE) >= 3 else 0.8
		return true
	if _bbounce[b] > 0:
		var exclude := PackedInt32Array([horde.uid[e]])
		var next := horde.find_nearest_except(at, 120.0, exclude)
		if next != -1:
			_bbounce[b] -= 1
			_bdmg[b] *= 0.7
			_bvel[b] = (horde.pos[next] - at).normalized() * _bvel[b].length()
			_blife[b] = maxf(_blife[b], 0.4)
			return true
	return false


func _spawn_shards(slot: int, at: Vector2, dir: Vector2, dmg: float, skip_uid: int) -> void:
	var s := slots[slot]
	var n := int(s.mod_value(WeaponDefs.Module.SPLIT, [3, 4, 5], 1.0)) + (1 if s.module(WeaponDefs.Module.SPLIT)["rare"] else 0)
	var k: float = [0.35, 0.4, 0.45][s.mod_rank(WeaponDefs.Module.SPLIT) - 1]
	for j in n:
		var a := dir.angle() + (j - (n - 1) * 0.5) * 0.45
		_spawn_bullet(at, Vector2.from_angle(a) * SHARD_SPEED, 0.25, dmg * k, slot, 0, 0, F_SHARD)
		_blast[bullet_count - 1] = skip_uid


func _remove_bullet(i: int) -> void:
	bullet_count -= 1
	var j := bullet_count
	_bpos[i] = _bpos[j]
	_bvel[i] = _bvel[j]
	_blife[i] = _blife[j]
	_bdmg[i] = _bdmg[j]
	_bslot[i] = _bslot[j]
	_bpierce[i] = _bpierce[j]
	_bbounce[i] = _bbounce[j]
	_bflags[i] = _bflags[j]
	_blast[i] = _blast[j]
	_bdepth[i] = _bdepth[j]


# --- попадание: патроны ------------------------------------------------------------------

## Урон по зомби с эффектами патронов ствола. Возвращает true, если убит.
func _hit_enemy(slot: int, e: int, dmg: float, dir: Vector2, at: Vector2, knockback: float, explosive := false) -> bool:
	var s := slots[slot]
	var rank := s.ammo_rank
	var rare := WeaponDefs.RARE_MULT if s.ammo_rare else 1.0
	var crit_chance: float = s.stats["crit"] + 0.05
	var crit_mult := 2.0
	if s.ammo == WeaponDefs.Ammo.STANDARD:
		crit_chance += [0.10, 0.15, 0.15][rank - 1] * rare
		if rank >= 3:
			crit_mult = 2.5
	var crit := randf() < crit_chance
	if crit:
		dmg *= crit_mult
	match s.ammo:
		WeaponDefs.Ammo.INCENDIARY:
			horde.ignite(e, [4.0, 6.0, 6.0][rank - 1] * rare, 3.0, [0.3, 0.3, 0.6][rank - 1], 16.0 if rank < 3 else 32.0)
		WeaponDefs.Ammo.CRYO:
			horde.chill_hit(e, 0.2, 4 if rank < 2 else 3, rank >= 3, s.prototype == 1)
	var e_pos := horde.pos[e]
	var killed := horde.damage(e, dmg, dir, knockback, s.ammo, crit, at, explosive)
	if effects:
		effects.blood_hit(e_pos, dir, false)
		_ammo_sparks(s.ammo, e_pos, dir)
	if s.ammo == WeaponDefs.Ammo.EXPANSIVE and not explosive:
		var k: float = [0.3, 0.45, 0.45][rank - 1] * rare
		var r := 16.0 if rank < 2 else 20.0
		if not killed or rank >= 3:
			for j in horde.query_radius(e_pos, r):
				if j != e:
					horde.damage(j, dmg * k, (horde.pos[j] - e_pos).normalized(), 30.0, s.ammo, false, horde.pos[j], true)
	return killed


## Убийство: детонатор и цепь.
func _on_kill(slot: int, e: int, dir: Vector2, depth: int) -> void:
	var s := slots[slot]
	var at := horde.pos[e]
	if s.mod_rank(WeaponDefs.Module.DETONATOR) > 0:
		var chance := 1.0 if s.prototype == 0 else minf(s.mod_value(WeaponDefs.Module.DETONATOR, [0.25, 0.4, 0.6]), 1.0)
		if randf() < chance and depth < 3:
			var chained := s.mod_rank(WeaponDefs.Module.DETONATOR) >= 3 or s.prototype == 0
			explode(at, s.stats["damage"], 30.0 * (1.3 if s.prototype == 0 else 1.0), slot, depth + (1 if chained else 3))
	if s.mod_rank(WeaponDefs.Module.CHAIN) > 0 and depth < (3 if s.mod_rank(WeaponDefs.Module.CHAIN) >= 3 else 1):
		var next := horde.find_nearest_except(at, 80.0, PackedInt32Array([horde.uid[e]]))
		if next != -1:
			var k := minf(s.mod_value(WeaponDefs.Module.CHAIN, [0.5, 0.65, 0.8]), 1.0)
			var v := (horde.pos[next] - at).normalized() * 380.0
			_spawn_bullet(at, v, 0.35, s.stats["damage"] * k, slot, 0, 0, F_CHAIN | F_SHARD, depth + 1)
			_blast[bullet_count - 1] = horde.uid[e]


## Взрыв: урон по площади, отброс, гибы. depth ограничивает цепные детонации.
## slot >= 0 — взрыв ствола (патроны, детонатор), slot = -1 — «ничей» (граната игрока):
## урон без эффектов патронов, любая смерть — гибы.
func explode(at: Vector2, dmg: float, radius: float, slot := -1, depth := 0) -> void:
	_blasts.append([at, radius, 0.0])
	if effects:
		for k in 14:
			effects.emit(at, Vector2.from_angle(randf() * TAU) * randf_range(30.0, 160.0), randf_range(0.15, 0.4),
				Color(1.0, randf_range(0.5, 0.9), 0.2), 1.5, 5.0)
		for k in 6:
			effects.emit(at, Vector2.from_angle(randf() * TAU) * randf_range(10.0, 40.0), randf_range(0.5, 1.0),
				Color(0.2, 0.19, 0.18, 0.6), 4.0, 2.0)
	if floor_decals:
		# подпалина: лёгкая копоть, чтобы не забивать кровь
		floor_decals.stamp(PixelArt.tex("blood_%d" % (randi() % 8)), at, randf() * TAU, Color(0.07, 0.06, 0.055, 0.3), radius / 45.0)
	var s: Slot = slots[slot] if slot >= 0 else null
	var prev_override := horde.death_override
	if s == null:
		horde.death_override = Gore.Death.GIBS # граната рвёт на куски, даже замёрзших
	for j in horde.query_radius(at, radius):
		var d := horde.pos[j] - at
		var falloff := 1.0 - clampf(d.length() / (radius + Horde.RADIUS), 0.0, 1.0) * 0.5
		var dir := d.normalized() if d.length_squared() > 0.01 else Vector2.from_angle(randf() * TAU)
		if s == null:
			if horde.damage(j, dmg * falloff, dir, GRENADE_KNOCK, WeaponDefs.Ammo.STANDARD, false, horde.pos[j], true) and effects:
				effects.blood_hit(horde.pos[j], dir, false)
		elif _hit_enemy(slot, j, dmg * falloff, dir, horde.pos[j], s.stats["knock"] * 1.5, true):
			if depth < 2 and s.mod_rank(WeaponDefs.Module.DETONATOR) > 0:
				_on_kill(slot, j, dir, depth)
	horde.death_override = prev_override
	var to_player := player.global_position.distance_to(at)
	if camera and to_player < 120.0:
		camera.shake(3.0 * (1.0 - to_player / 120.0))


func _ammo_sparks(ammo: int, p: Vector2, dir: Vector2) -> void:
	var color: Color
	match ammo:
		WeaponDefs.Ammo.INCENDIARY:
			color = Color(1.0, 0.55, 0.1)
		WeaponDefs.Ammo.CRYO:
			color = Color(0.75, 0.95, 1.0)
		WeaponDefs.Ammo.EXPANSIVE:
			color = Color(1.0, 0.9, 0.6)
		_:
			return
	for k in 2:
		effects.emit(p, dir.rotated(randf_range(-1.0, 1.0)) * randf_range(30.0, 90.0), randf_range(0.1, 0.25), color, 1.0, 6.0)


# --- рейлган ----------------------------------------------------------------------------------

func _fire_rail(i: int, muzzle: Vector2, dir: Vector2) -> void:
	var s := slots[i]
	var n: int = s.stats["proj"]
	for k in n:
		var a := dir.angle() + (k - (n - 1) * 0.5) * deg_to_rad(15.0)
		_rail_beam(i, muzzle, Vector2.from_angle(a), s.stats["damage"], int(s.mod_value(WeaponDefs.Module.RICOCHET, [1, 2, 3])), PackedInt32Array())


func _rail_beam(i: int, from: Vector2, dir: Vector2, dmg: float, bounces: int, hit_uids: PackedInt32Array) -> void:
	var s := slots[i]
	var length: float = s.stats["range"]
	var half: float = s.stats["width"] * 0.5 + Horde.RADIUS
	var to := from + dir * length
	# кто на линии: сортируем по расстоянию вдоль луча
	var hits: Array = []
	for e in horde.count:
		if horde.dead[e] == 1 or hit_uids.has(horde.uid[e]):
			continue
		var rel := horde.pos[e] - from
		var t := rel.dot(dir)
		if t < 0.0 or t > length:
			continue
		if absf(rel.cross(dir)) <= half:
			hits.append([t, e])
	hits.sort_custom(func(x, y): return x[0] < y[0])
	var last := -1
	for h in hits:
		var e: int = h[1]
		if horde.dead[e] == 1:
			continue
		hit_uids.append(horde.uid[e])
		var at := horde.pos[e]
		if last == -1 and s.mod_rank(WeaponDefs.Module.SPLIT) > 0:
			_spawn_shards(i, at, dir, dmg, horde.uid[e])
		if _hit_enemy(i, e, dmg, dir, at, s.stats["knock"]):
			_on_kill(i, e, dir, 0)
		last = e
	var color := Color(0.6, 0.95, 1.0) if s.prototype == 1 else Color(0.55, 0.85, 1.0)
	_beams.append([from, to, s.stats["width"], 0.0, color])
	# рикошет: луч перескакивает с последней цели на ближайшую новую
	if bounces > 0 and last != -1:
		var at := horde.pos[last]
		var next := horde.find_nearest_except(at, 160.0, hit_uids)
		if next != -1:
			_rail_beam(i, at, (horde.pos[next] - at).normalized(), dmg * 0.7, bounces - 1, hit_uids)


# --- гранатомёт --------------------------------------------------------------------------------

func _fire_grenades(i: int, muzzle: Vector2, target: Vector2) -> void:
	var s := slots[i]
	var n: int = s.stats["proj"]
	for k in n:
		var t := target + (Vector2(randf_range(-14, 14), randf_range(-14, 14)) if k > 0 else Vector2.ZERO)
		_spawn_grenade(muzzle, t, i, s.stats["damage"], s.stats["radius"], false)


func _spawn_grenade(from: Vector2, to: Vector2, slot: int, dmg: float, radius: float, small: bool) -> void:
	var d := to - from
	var spd: float = slots[slot].stats["speed"] if not small else 180.0
	_gpos.append(from)
	_gvel.append(d.normalized() * spd)
	_gleft.append(d.length())
	_gslot.append(slot)
	_gdmg.append(dmg)
	_grad.append(radius)
	_gsmall.append(1 if small else 0)


func _update_grenades(delta: float) -> void:
	var i := _gpos.size() - 1
	while i >= 0:
		var step := _gvel[i].length() * delta
		_gleft[i] -= step
		_gpos[i] += _gvel[i] * delta
		var touched := horde.find_hit(_gpos[i], 2.0) != -1
		if _gleft[i] <= 0.0 or touched:
			var at := _gpos[i]
			var slot := _gslot[i]
			explode(at, _gdmg[i], _grad[i], slot)
			# сплит у гранатомёта — кассета мини-гранат
			if _gsmall[i] == 0 and slot < slots.size() and slots[slot].mod_rank(WeaponDefs.Module.SPLIT) > 0:
				var n := 2 + slots[slot].mod_rank(WeaponDefs.Module.SPLIT)
				for k in n:
					var to := at + Vector2.from_angle(TAU * k / n + randf() * 0.5) * randf_range(20.0, 34.0)
					_spawn_grenade(at, to, slot, _gdmg[i] * 0.4, _grad[i] * 0.6, true)
			_gpos.remove_at(i)
			_gvel.remove_at(i)
			_gleft.remove_at(i)
			_gslot.remove_at(i)
			_gdmg.remove_at(i)
			_grad.remove_at(i)
			_gsmall.remove_at(i)
		i -= 1


# --- отрисовка ------------------------------------------------------------------------------

func _age_fx(delta: float) -> void:
	var k := _beams.size() - 1
	while k >= 0:
		_beams[k][3] += delta
		if _beams[k][3] > 0.14:
			_beams.remove_at(k)
		k -= 1
	k = _blasts.size() - 1
	while k >= 0:
		_blasts[k][2] += delta
		if _blasts[k][2] > 0.22:
			_blasts.remove_at(k)
		k -= 1
	var f := _flashes.size() - 1
	while f >= 0:
		_flashes[f][2] -= delta
		if _flashes[f][2] <= 0.0:
			_flashes.remove_at(f)
		f -= 1


func _draw() -> void:
	for b in bullet_count:
		var p := _bpos[b]
		var tail := _bvel[b].normalized() * (3.0 if _bflags[b] & F_SHARD else 5.0)
		var c := Color(1.0, 0.85, 0.45, 0.9) if _bflags[b] & F_CHAIN == 0 else Color(1.0, 0.4, 0.3, 0.9)
		draw_line(p - tail, p, c, 1.0)
	for g in _gpos.size():
		draw_rect(Rect2(_gpos[g] - Vector2(1.5, 1.5), Vector2(3, 3)), Color(0.25, 0.28, 0.2))
		draw_rect(Rect2(_gpos[g] - Vector2(0.5, 0.5), Vector2(1, 1)), Color(1.0, 0.4, 0.2))
	for beam: Array in _beams:
		var k: float = 1.0 - beam[3] / 0.14
		var c: Color = beam[4]
		draw_line(beam[0], beam[1], Color(c, 0.35 * k), beam[2] * 1.8 * k + 1.0)
		draw_line(beam[0], beam[1], Color(1, 1, 1, 0.9 * k), maxf(beam[2] * 0.35 * k, 0.6))
	for bl: Array in _blasts:
		var k: float = bl[2] / 0.22
		var r: float = bl[1] * (0.4 + 0.6 * k)
		draw_arc(bl[0], r, 0.0, TAU, 24, Color(1.0, 0.8, 0.4, 0.8 * (1.0 - k)), 2.0)
		PixelArt.draw_dot(self, bl[0], r * 0.6 * (1.0 - k), Color(1.0, 0.85, 0.5, 0.6 * (1.0 - k)))
	for fl: Array in _flashes:
		var f := Vector2.from_angle(fl[1])
		PixelArt.draw_dot(self, fl[0] + f * 1.5, 2.5, Color(1.0, 0.95, 0.6))
		draw_line(fl[0], fl[0] + f * 6.0, Color(1.0, 0.8, 0.3), 2.0)
