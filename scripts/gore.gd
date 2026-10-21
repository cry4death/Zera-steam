class_name Gore
extends Node2D
## Смерти, раны и куски мяса. Трупы и гибы — «обломки» с простой физикой:
## разлетаются, крутятся, оставляют кровавый след, затем стареют в ограниченном пуле.
## Тип смерти задают патроны (GDD §5.3, §6.4).

## Близкая кровавая смерть: игра решает, забрызгать ли экран.
signal splatter(pos: Vector2, strength: float)

enum Death { NORMAL, HEADSHOT, GIBS, BURN, ICE, DECAP, BISECT, PIN }
const DEATH_NAMES := ["обычная", "голова лопается", "гибы", "сожжение", "лёд", "обезглавливание", "распил", "пригвождение"]

## GIB — летящий кусок; CORPSE — труп (скользит, дёргается, оседает);
## BURNING/STATUE — горящий и замёрзший; WALKER — тело без головы ещё идёт;
## CRAWLER — верхняя половина после распила движется по инерции.
enum Kind { GIB, CORPSE, BURNING, STATUE, WALKER, CRAWLER }

const MAX_DEBRIS := 900
const BLOOD := Color(0.195, 0.0037, 0.006)
const BLOOD_DARK := Color(0.023, 0.0009, 0.0018)
const ASH := Color(0.09, 0.08, 0.075)
const CORPSE_TINT := Color(0.65, 0.59, 0.57)
const MAX_REMAINS := 200
const CELL_SIZE := 128.0
const CELL_LIMIT := 8

var remains_count := 0
var remains_peak := 0
var _r_tex := PackedInt32Array()
var _r_pos := PackedVector2Array()
var _r_rot := PackedFloat32Array()
var _r_scale := PackedVector2Array()
var _r_age := PackedFloat32Array()
var _r_life := PackedFloat32Array()
var _r_tint := PackedColorArray()
var _r_order := PackedInt32Array()
var _r_sort := PackedInt32Array()
var _r_layer: Node2D
var _pending_hits: Dictionary = {}
var _hit_tokens := 64.0
var _hit_rng := RandomNumberGenerator.new()
var _radial_death := false
enum Region { TORSO, HEAD, LIMB }
var _geometry: Dictionary = {}
var _pulses: Array[Array] = []
var _last_recipe: Dictionary = {}

var floor_decals: FloorDecals
var effects: Effects
var player: Player
var arena := Rect2()

var _textures: Array[Texture2D] = []
# по видам зомби
var _t_corpse: Array[int] = []
var _t_headless: Array[int] = []
var _t_whole: Array[int] = []
var _t_walker: Array[int] = []
var _t_top: Array[int] = []
var _t_legs: Array[int] = []
var _t_head: Array[int] = []
var _t_arm: Array[int] = []
var _t_torso: Array[int] = []
# общие
var _t_burnt: Array[int] = []
var _t_brain := 0
var _t_ash := 0
var _t_jaw := 0
var _t_eye := 0
var _t_bone := 0
var _t_skull := 0
var _t_rib := 0
var _t_spine := 0
var _t_guts: Array[int] = []
var _t_organs: Array[int] = []
var _t_bloody_bones: Array[int] = []
var _t_meat: Array[int] = []
var _t_shards: Array[int] = []
var _splats: Array[Texture2D] = []
var _sprays: Array[Texture2D] = []
var _t_boss_gibs: Array[int] = []
var _t_boss_plates: Array[int] = []

var count := 0
var gore_multiplier := 1.0
var _kind := PackedInt32Array()
var _tex := PackedInt32Array()
var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _impact_dir := PackedVector2Array()
var _rot := PackedFloat32Array()
var _spin := PackedFloat32Array()
var _drag := PackedFloat32Array()
var _age := PackedFloat32Array()
var _timer := PackedFloat32Array()
var _col := PackedColorArray()
var _trail := PackedByteArray()
var _trail_pos := PackedVector2Array()
var _var := PackedByteArray()
var _scale := PackedVector2Array()
var _event_scale := Vector2.ONE
var _variant_textures: Dictionary = {}
var _t_armor: Array[int] = []
var _sort_cnt := PackedInt32Array()
var _order := PackedInt32Array()


var _stain_at := PackedVector2Array()
var _stain_amount := PackedFloat32Array()
var _stain_wet := PackedFloat32Array()
var _r_stain_at := PackedVector2Array()
var _r_stain_amount := PackedFloat32Array()
var _r_stain_wet := PackedFloat32Array()
var _stain_time := 0.0
var _horde: Horde
var _obstacles: Obstacles
var stains_on_remains := 0


func _ready() -> void:
	_stain_at.resize(MAX_DEBRIS)
	_stain_amount.resize(MAX_DEBRIS)
	_stain_wet.resize(MAX_DEBRIS)
	_r_stain_at.resize(MAX_REMAINS)
	_r_stain_amount.resize(MAX_REMAINS)
	_r_stain_wet.resize(MAX_REMAINS)
	var debris_mat := ShaderMaterial.new()
	debris_mat.shader = preload("res://shaders/flash.gdshader")
	debris_mat.set_shader_parameter("debris_mode", true)
	material = debris_mat
	_r_tex.resize(MAX_REMAINS)
	_r_pos.resize(MAX_REMAINS)
	_r_rot.resize(MAX_REMAINS)
	_r_scale.resize(MAX_REMAINS)
	_r_age.resize(MAX_REMAINS)
	_r_life.resize(MAX_REMAINS)
	_r_tint.resize(MAX_REMAINS)
	_r_order.resize(MAX_REMAINS)
	_r_layer = Node2D.new()
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/flash.gdshader")
	mat.set_shader_parameter("debris_mode", true)
	_r_layer.material = mat
	_r_layer.show_behind_parent = true
	_r_layer.draw.connect(_draw_remains)
	add_child(_r_layer)
	for k in 4:
		_t_boss_gibs.append(_load("boss_gib_%d" % k))
		_t_boss_plates.append(_load("boss_plate_%d" % k))
	_kind.resize(MAX_DEBRIS)
	_tex.resize(MAX_DEBRIS)
	_pos.resize(MAX_DEBRIS)
	_vel.resize(MAX_DEBRIS)
	_impact_dir.resize(MAX_DEBRIS)
	_rot.resize(MAX_DEBRIS)
	_spin.resize(MAX_DEBRIS)
	_drag.resize(MAX_DEBRIS)
	_age.resize(MAX_DEBRIS)
	_timer.resize(MAX_DEBRIS)
	_col.resize(MAX_DEBRIS)
	_trail.resize(MAX_DEBRIS)
	_trail_pos.resize(MAX_DEBRIS)
	_var.resize(MAX_DEBRIS)
	_scale.resize(MAX_DEBRIS)

	for appearance in PixelArt.APPEARANCE_COUNT:
		var v := appearance % PixelArt.VARIANT_COUNT
		var tone := appearance / PixelArt.VARIANT_COUNT
		var first := _textures.size()
		for pose in PixelArt.CORPSE_POSES:
			_t_corpse.append(_load("zombie_corpse_%d_%d_t%d" % [pose, v, tone]))
			_t_headless.append(_load("zombie_corpse_headless_%d_%d_t%d" % [pose, v, tone]))
		_t_whole.append(_load("zombie_whole_%d" % v if tone == 0 else "zombie_whole_%d_t%d" % [v, tone]))
		_t_walker.append(_load("zombie_headless_%d" % v if tone == 0 else "zombie_headless_%d_t%d" % [v, tone]))
		_t_top.append(_load("zombie_top_%d" % v if tone == 0 else "zombie_top_%d_t%d" % [v, tone]))
		_t_legs.append(_load("zombie_legs_%d_t%d" % [v, tone]))
		_t_head.append(_load("zombie_head_%d_t%d" % [v, tone]))
		_t_arm.append(_load("zombie_arm_%d_t%d" % [v, tone]))
		_t_torso.append(_load("zombie_torso_%d_t%d" % [v, tone]))
		for texture_id in range(first, _textures.size()):
			_variant_textures[texture_id] = true
	for t in 3:
		var military_first := _textures.size()
		for pose in PixelArt.CORPSE_POSES:
			_t_corpse.append(_load("zombie_military_corpse_%d_%d" % [pose, t]))
			_t_headless.append(_load("zombie_military_corpse_headless_%d_%d" % [pose, t]))
		for pair: Array in [[_t_whole, "whole"], [_t_walker, "headless"], [_t_top, "top"], [_t_legs, "legs"], [_t_head, "head"], [_t_arm, "arm"], [_t_torso, "torso"]]:
			var list: Array[int] = pair[0]
			var tex_id := _load("zombie_military_%s_%d" % [pair[1], t])
			list.append(tex_id)
			_variant_textures[tex_id] = true
		for part in 4:
			_t_armor.append(_load("armor_%d_%d" % [t, part]))
		for texture_id in range(military_first, _textures.size()):
			_variant_textures[texture_id] = true
	for pose in PixelArt.CORPSE_POSES:
		_t_burnt.append(_load("corpse_burnt_%d" % pose))
	_t_bone = _load("gib_bone")
	_t_skull = _load("gib_skull_0")
	_t_brain = _load("gib_brain")
	_t_jaw = _load("gib_jaw")
	_t_eye = _load("gib_eye")
	_t_rib = _load("gib_rib")
	_t_spine = _load("gib_spine")
	for k in 6:
		_t_guts.append(_load("gib_gut_%d" % k))
	for organ: String in ["heart", "liver", "lung", "stomach"]:
		for k in 2:
			_t_organs.append(_load("gib_organ_%s_%d" % [organ, k]))
	for bone: String in ["arm", "long", "rib", "skull", "spine"]:
		for k in 4:
			_t_bloody_bones.append(_load("bbone_%s_%d" % [bone, k]))
	_t_bone = _t_bloody_bones[4]
	_t_rib = _t_bloody_bones[8]
	_t_skull = _t_bloody_bones[12]
	_t_spine = _t_bloody_bones[16]
	for k in 3:
		_t_shards.append(_load("gib_shard_%d" % k))
	for k in 4:
		_t_meat.append(_load("gib_meat_%d" % k))
	for k in 4:
		_t_meat.append(_load("gib_scrap_%d" % k))
	for k in 8:
		_splats.append(PixelArt.tex("blood_%d" % k))
	_t_ash = _load("blood_0")
	for k in 4:
		_sprays.append(PixelArt.tex("spray_%d" % k))


func setup(floor_layer: FloorDecals, fx: Effects, arena_rect: Rect2, target: Player) -> void:
	_hit_rng.seed = 81073
	floor_decals = floor_layer
	effects = fx
	arena = arena_rect
	player = target
	_horde = get_parent().get_node_or_null("Horde") as Horde
	if _horde:
		_horde.impact_geometry.connect(_on_impact_geometry)
	_obstacles = target.obstacles
	floor_decals.blood_landed.connect(_on_blood_landed)


func _load(art_name: String) -> int:
	_textures.append(PixelArt.tex(art_name))
	return _textures.size() - 1


func _corpse_tex(list: Array[int], v: int) -> int:
	return list[v * PixelArt.CORPSE_POSES + randi() % PixelArt.CORPSE_POSES]


# --- реакция на события орды -------------------------------------------------

func on_enemy_killed(p: Vector2, dir: Vector2, death: int, facing: float, v: int) -> void:
	_event_scale = PixelArt.corpse_scale(v)
	v = PixelArt.appearance(v)
	_radial_death = PixelArt.variant_kind(v) == Horde.Kind.FAT
	for hit: Array in _pending_hits.values():
		var hit_at: Vector2 = hit[0]
		if hit_at.distance_squared_to(p) < 1.0 and bool(hit[6]):
			_radial_death = true
	if death != Death.BURN and death != Death.ICE:
		# Смерть продолжает выстрел, даже если цель погибла с первой пули.
		effects.blood_burst(p, dir, 18 if death == Death.NORMAL else 26, 190.0 if death == Death.NORMAL else 250.0, 0.34, _hit_rng)
	if PixelArt.variant_kind(v) == Horde.Kind.SPITTER:
		# Капли кислоты вперемешку с обычной кровью при любом типе смерти.
		_acid_drops(p, 12)
	match death:
		Death.PIN:
			_add_corpse(_corpse_tex(_t_corpse, v), p, Vector2.ZERO, dir.angle())
			floor_decals.pool(_splats[0], p, dir.angle(), 0.7)
			if _pinned.size() >= 64: _pinned.pop_front()
			_pinned.append([p, dir, 30.0])
		Death.HEADSHOT:
			_death_headshot(p, dir, v)
		Death.GIBS:
			_death_gibs(p, dir, v)
		Death.BURN:
			_death_burn(p, dir)
		Death.ICE:
			_death_ice(p, dir, facing, v)
		Death.DECAP:
			_death_decap(p, dir, facing, v)
		Death.BISECT:
			_death_bisect(p, dir, facing, v)
		_:
			_death_normal(p, dir, v)
	# Рана определяет дополнительные части, не меняя игрового типа смерти.
	for hit: Array in _pending_hits.values():
		if (hit[0] as Vector2).distance_squared_to(p) < 1.0:
			_hit_parts(hit[7], v, true, death)
			break
	_event_scale = Vector2.ONE
	_radial_death = false


## Дробинки одного тика объединяем по постоянному номеру тела, урон считает орда.
func _on_impact_geometry(id: int, entry: Vector2, facing: float, weapon: int, through: bool, killed: bool) -> void:
	if _geometry.size() < 96:
		_geometry[id] = [entry, facing, weapon, through, killed]


## Тело — эллипс в локальных координатах спрайта; X смотрит вперёд.
func _hit_recipe(p: Vector2, dir: Vector2, v: int, damage: float, impulse: float, explosive: bool, geometry: Array) -> Dictionary:
	var facing: float = geometry[1]
	var shape := PixelArt.corpse_scale(v)
	var local: Vector2 = (geometry[0] - p).rotated(-facing) / shape if (geometry[0] as Vector2).is_finite() else -dir.rotated(-facing) * Vector2(5, 3.5)
	local = local.limit_length(6.5)
	var entry := p + (local * shape).rotated(facing)
	var normal := (local / Vector2(25.0, 12.25) / shape).normalized().rotated(facing)
	var incidence := clampf(absf(normal.dot(dir)), 0.15, 1.0)
	var region := Region.HEAD if local.x > 2.0 and absf(local.y) < 2.5 else Region.LIMB if absf(local.y) > 2.4 or local.x < -3.5 else Region.TORSO
	var weapon: int = geometry[2]
	var caliber := 1.0
	match weapon:
		WeaponDefs.Base.SMG: caliber = 0.55
		WeaponDefs.Base.PISTOL: caliber = 0.8
		WeaponDefs.Base.REVOLVER: caliber = 1.5
		WeaponDefs.Base.SHOTGUN: caliber = 1.75
		WeaponDefs.Base.SNIPER: caliber = 1.9
		WeaponDefs.Base.RAIL: caliber = 2.7
		WeaponDefs.Base.LAUNCHER: caliber = 2.4
	if explosive:
		caliber = maxf(caliber, 2.4)
	var force := clampf(damage / 42.0 + impulse / 500.0, 0.0, 1.0)
	var volume := clampf(exp(_hit_rng.randfn(-0.20, 0.75)), 0.65, 4.0) * caliber * 2.0
	volume *= (1.35 if bool(geometry[4]) else 1.0) * (1.4 if region == Region.HEAD else 0.75 if region == Region.LIMB else 1.0)
	var through: bool = geometry[3] or explosive or (weapon < 0 and force > 0.8)
	var cone := _hit_rng.randf_range(0.12, 0.4) + (1.0 - incidence) * 0.3
	if weapon == WeaponDefs.Base.SHOTGUN:
		cone += 0.45
	if explosive:
		cone = 1.25
	return {"entry": entry, "exit": entry + dir * (7.0 * incidence if through else 0.0), "dir": dir, "region": region, "volume": volume, "cone": cone, "force": force, "through": through, "killed": bool(geometry[4]), "weapon": weapon, "mask": _hit_rng.randi_range(0, 15)}


func on_enemy_hit(p: Vector2, dir: Vector2, v: int, damage := 8.0, impulse := 10.0, id := -1, explosive := false) -> void:
	var key := id if id >= 0 else hash(p)
	var geometry: Array = _geometry.get(id, [Vector2.INF, dir.angle(), -1, false, false])
	_geometry.erase(id)
	# Огонь и разряд обугливают; пулевой фонтан скрывал пламя на теле.
	if not explosive and int(geometry[2]) in [WeaponDefs.Base.FLAMER, WeaponDefs.Base.TESLA]:
		return
	var recipe := _hit_recipe(p, dir, v, damage, impulse, explosive, geometry)
	# Вход не зависит от бюджета далёких частиц и ставится до объединения дробинок.
	floor_decals.stamp_dot(recipe["entry"], _hit_rng.randf_range(3.5, 5.5))
	if _pending_hits.has(key):
		var hit: Array = _pending_hits[key]
		hit[3] = float(hit[3]) + damage
		hit[4] = maxf(float(hit[4]), impulse)
		hit[5] = int(hit[5]) + 1
		var combined: Dictionary = hit[7]
		combined["volume"] = minf(7.0, float(combined["volume"]) + float(recipe["volume"]) * 0.4)
		combined["killed"] = bool(combined["killed"]) or bool(recipe["killed"])
		combined["force"] = maxf(float(combined["force"]), float(recipe["force"]))
	elif _pending_hits.size() < 96:
		_pending_hits[key] = [p, dir, v, damage, impulse, 1, explosive, recipe]
	else:
		# Даже при перегрузе остаётся дешёвая выходная капля.
		floor_decals.stamp_dot(p + dir * 7.0, 1.0)


func _flush_hits(delta: float) -> void:
	_hit_tokens = minf(64.0, _hit_tokens + delta * 420.0)
	_update_pulses(delta)
	# Ближние реакции получают бюджет раньше дальних.
	for nearby in [true, false]:
		for hit: Array in _pending_hits.values():
			var p: Vector2 = hit[0]
			var near := player == null or p.distance_squared_to(player.global_position) < 22500.0
			if near != nearby:
				continue
			var dir: Vector2 = hit[1]
			var recipe: Dictionary = hit[7]
			_last_recipe = recipe
			if _hit_tokens < 1.0 and not near:
				floor_decals.stamp_dot(recipe["entry"], 1.3)
				continue
			_hit_tokens = maxf(0.0, _hit_tokens - 1.0)
			var force: float = recipe["force"]
			var fan := int(hit[5]) >= 3
			effects.blood_impact(recipe["exit"], dir, force, fan, near, _hit_rng, recipe)
			var amount: float = recipe["volume"]
			floor_decals.blood(floor_decals._pool_masks[int(recipe["mask"])], recipe["entry"], _hit_rng.randf() * TAU, clampf(sqrt(amount) * 0.85, 0.55, 2.0), 0.85)
			# Мокрая связка от раны до ближних капель, а не одинаковая дальняя лужа.
			var end: Vector2 = recipe["exit"] + dir.rotated(_hit_rng.randf_range(-0.2, 0.2)) * _hit_rng.randf_range(5.0, 14.0) * sqrt(amount)
			floor_decals.smear(recipe["entry"], end, _hit_rng.randf_range(2.5, 4.0) * sqrt(amount), 0.65)
			if near:
				var cursor: Vector2 = recipe["entry"]
				var reach := clampf(_hit_rng.randf_range(40.0, 65.0) * sqrt(amount), 28.0, 100.0) * (1.0 if bool(recipe["through"]) else 0.6)
				for k in 6:
					var t := float(k + 1) / 6.0
					var next: Vector2 = recipe["entry"] + dir * reach * t + dir.orthogonal() * _hit_rng.randf_range(-3.0, 3.0) * t
					floor_decals.smear(cursor, next, _hit_rng.randf_range(3.0, 5.0) * sqrt(amount) * (1.0 - t * 0.72), 0.6)
					floor_decals.stamp_dot(next + dir.orthogonal() * _hit_rng.randf_range(-6.0, 6.0) * t, _hit_rng.randf_range(2.5, 5.0) * sqrt(amount) * (1.0 - t * 0.45))
					cursor = next
			if near and bool(recipe["killed"]):
				floor_decals.pool(_splats[int(recipe["mask"]) % 8], p, dir.angle() + _hit_rng.randf_range(-0.4, 0.4), clampf(sqrt(amount) * 0.7, 0.4, 1.6))
			if near and not bool(recipe["killed"]) and force > 0.35:
				_hit_parts(recipe, PixelArt.appearance(int(hit[2])), false, Death.NORMAL)
			if near and int(recipe["region"]) == Region.HEAD and _pulses.size() < 24 and _hit_rng.randf() < 0.45:
				_pulses.append([recipe.duplicate(), 0.16, 3])
			if PixelArt.variant_kind(int(hit[2])) == Horde.Kind.SPITTER:
				_acid_drops(p, 2)
	_pending_hits.clear()


func _update_pulses(delta: float) -> void:
	for j in range(_pulses.size() - 1, -1, -1):
		var pulse: Array = _pulses[j]
		pulse[1] = float(pulse[1]) - delta
		if float(pulse[1]) <= 0.0:
			var recipe: Dictionary = pulse[0]
			recipe["volume"] = float(recipe["volume"]) * 0.5
			effects.blood_impact(recipe["exit"], recipe["dir"], recipe["force"], false, false, _hit_rng, recipe)
			pulse[1] = 0.18
			pulse[2] = int(pulse[2]) - 1
			if int(pulse[2]) <= 0:
				_pulses.remove_at(j)


func _hit_parts(recipe: Dictionary, v: int, killed: bool, death: int) -> void:
	if death in [Death.BURN, Death.ICE] or (not killed and _hit_rng.randf() > float(recipe["force"]) * 0.45):
		return
	var p: Vector2 = recipe["exit"]
	var dir: Vector2 = recipe["dir"]
	var region: int = recipe["region"]
	var n := _hit_rng.randi_range(2, 5) if killed else _hit_rng.randi_range(1, 2)
	for k in n:
		var t := _t_meat[_hit_rng.randi_range(0, _t_meat.size() - 1)]
		if region == Region.HEAD:
			t = [_t_brain, _t_jaw, _t_eye, _t_skull][k % 4]
		elif region == Region.LIMB:
			t = _t_arm[v] if k == 0 else _t_bloody_bones[_hit_rng.randi_range(0, 7)]
		else:
			t = _t_guts[_hit_rng.randi_range(0, 5)] if k == 0 else _t_organs[_hit_rng.randi_range(0, 7)]
		var out := dir.rotated(_hit_rng.randf_range(-0.65, 0.65))
		var speed := _hit_rng.randf_range(18.0, 115.0)
		_add(Kind.GIB, t, p, out * speed, out.angle() + _hit_rng.randf_range(-1.0, 1.0), _hit_rng.randf_range(-8, 8), Color.WHITE, 5.0, true)


## Новая стадия раны: что-то отлетает с той стороны, куда попали.
func on_enemy_wounded(p: Vector2, dir: Vector2, facing: float, v: int, stage: int, wound: int) -> void:
	_event_scale = PixelArt.corpse_scale(v)
	v = PixelArt.appearance(v)
	if PixelArt.variant_kind(v) == Horde.Kind.SPITTER:
		_acid_drops(p, 4 + stage * 2)
	effects.blood_burst(p, dir, 6 + stage * 3, 120.0, 0.34)
	if wound & PixelArt.WOUND_ARM_L or wound & PixelArt.WOUND_ARM_R:
		var side := (-1.0 if wound & PixelArt.WOUND_ARM_L else 1.0) * signf(_event_scale.y)
		var shoulder := p + Vector2(3.0, 5.5 * side).rotated(facing)
		var out := dir.rotated(randf_range(-0.32, 0.32))
		_add(Kind.GIB, _t_arm[v], shoulder, out * randf_range(60.0, 120.0), randf() * TAU, randf_range(-14.0, 14.0), Color.WHITE, 5.0, true)
		effects.blood_burst(shoulder, dir, 10, 120.0, 0.34)
	if wound & PixelArt.WOUND_CHEST:
		_add(Kind.GIB, _t_rib, p, dir.rotated(randf_range(-0.34, 0.34)) * randf_range(50.0, 100.0), randf() * TAU, randf_range(-12.0, 12.0), Color.WHITE, 6.0, false)
		_add(Kind.GIB, _t_meat.pick_random(), p, dir.rotated(randf_range(-0.34, 0.34)) * randf_range(40.0, 90.0), randf() * TAU, 8.0, Color.WHITE, 6.0, true)
	if wound & PixelArt.WOUND_HEAD:
		for i in 3:
			var tid: int = _t_skull if i == 0 else _t_meat.pick_random()
			_add(Kind.GIB, tid, p, dir.rotated(randf_range(-0.7, 0.7)) * randf_range(60.0, 140.0), randf() * TAU, randf_range(-16.0, 16.0), Color.WHITE, 6.0, i > 0)
		_add(Kind.GIB, _t_guts.pick_random(), p, dir * 24.0, randf() * TAU, 3.0, Color.WHITE, 8.0, true)
	_event_scale = Vector2.ONE


## Только визуальные капли; опасные лужи создаёт Hazards в S2.
func _acid_drops(p: Vector2, n: int) -> void:
	for j in n:
		var velocity := Vector2.from_angle(randf() * TAU) * randf_range(35.0, 120.0)
		effects.emit(p, velocity, randf_range(0.3, 0.7), Color(0.29, 0.40, 0.12), randf_range(0.7, 1.3), 5.0, true)


# --- типы смерти -------------------------------------------------------------

func _death_normal(p: Vector2, dir: Vector2, v: int) -> void:
	effects.blood_burst(p, dir, 16, 150.0, 0.34)
	floor_decals.pool(_splats.pick_random(), p + dir * 10.0, dir.angle(), 1.25)
	_add_corpse(_corpse_tex(_t_corpse, v), p, dir * randf_range(50.0, 90.0), dir.angle() + randf_range(-0.4, 0.4))
	# Обычный удар чаще оставляет целое тело; сильный импульс даёт больше деталей.
	var force := 0.25
	for hit: Array in _pending_hits.values():
		var hit_at: Vector2 = hit[0]
		if hit_at.distance_squared_to(p) < 1.0:
			force = maxf(force, clampf(float(hit[3]) / 42.0 + float(hit[4]) / 500.0, 0.0, 1.0))
	if _hit_rng.randf() < (lerpf(0.16, 0.65, force) if PixelArt.variant_kind(v) != Horde.Kind.FAT else 0.75):
		_spill_parts(p, dir.normalized(), _hit_rng.randi_range(2, 5))


func _death_headshot(p: Vector2, dir: Vector2, v: int) -> void:
	# голова лопается: направленный фонтан, осколки черепа, безголовый труп
	effects.blood_burst(p, dir, 26, 200.0, 0.4)
	floor_decals.pool(_splats.pick_random(), p + dir * 8.0, dir.angle(), 1.1)
	floor_decals.blood(_sprays.pick_random(), p + dir * 14.0, dir.angle() + randf_range(-0.15, 0.15), 1.2, 0.7)
	for i in 5:
		var vel := dir.rotated(randf_range(-0.6, 0.6)) * randf_range(80.0, 210.0)
		var tid: int = [_t_skull, _t_jaw, _t_brain, _t_eye, _t_meat.pick_random()][i]
		_add(Kind.GIB, tid, p, vel, randf() * TAU, randf_range(-20.0, 20.0), Color.WHITE, 6.0, i >= 2, 0.0, true)
	_add_corpse(_corpse_tex(_t_headless, v), p, dir * randf_range(60.0, 100.0), dir.angle() + randf_range(-0.3, 0.3))
	splatter.emit(p, 0.6)


func _death_gibs(p: Vector2, dir: Vector2, v: int) -> void:
	var bursts := 2 if PixelArt.variant_kind(v) == Horde.Kind.FAT else 1
	for j in bursts:
		var burst_dir := dir
		effects.blood_burst(p, burst_dir, 34, 240.0, 0.55 if _radial_death else 0.34)
	if _radial_death:
		effects.blood_burst(p, dir, 10, 130.0, PI)
	if PixelArt.variant_kind(v) == Horde.Kind.FAT:
		floor_decals.pool(_splats.pick_random(), p + dir * 8.0, dir.angle(), 1.6)
	floor_decals.pool(_splats.pick_random(), p, dir.angle(), 1.5)
	floor_decals.blood(_sprays.pick_random(), p + dir * 10.0, dir.angle(), 1.1, 0.6)
	var parts: Array[int] = [_t_head[v], _t_arm[v], _t_torso[v]]
	for t in parts:
		var out := dir.rotated(_hit_rng.randf_range(-0.55, 0.55))
		_add(Kind.GIB, t, p, out * _hit_rng.randf_range(90.0, 210.0), _hit_rng.randf() * TAU, _hit_rng.randf_range(-16.0, 16.0), Color.WHITE, 4.5, true)
	_spill_parts(p, dir, _hit_rng.randi_range(7, 12) if PixelArt.variant_kind(v) == Horde.Kind.FAT else _hit_rng.randi_range(4, 8))
	splatter.emit(p, 1.0)


func _death_burn(p: Vector2, dir: Vector2) -> void:
	effects.burning_patch(p, 2.2, 0.85)
	_add(Kind.BURNING, _t_burnt.pick_random(), p, dir * 30.0, dir.angle() + randf_range(-0.4, 0.4), 0.0, Color.WHITE, 9.0, false, randf_range(1.2, 1.8))


func _death_ice(p: Vector2, dir: Vector2, facing: float, v: int) -> void:
	var i := _add(Kind.STATUE, _t_whole[v], p, Vector2.ZERO, facing, 0.0, Color(0.75, 0.95, 1.15), 0.0, false, randf_range(0.3, 0.45))
	_impact_dir[i] = dir


## Голова отлетает и катится, тело делает ещё пару шагов с фонтаном из шеи.
func _death_decap(p: Vector2, dir: Vector2, facing: float, v: int) -> void:
	var head_pos := p + Vector2.from_angle(facing) * 2.0
	var hv := dir.rotated(randf_range(-0.5, 0.5)) * randf_range(120.0, 200.0)
	_add(Kind.GIB, _t_head[v], head_pos, hv, randf() * TAU, hv.length() * 0.12 * (1.0 if randf() < 0.5 else -1.0), Color.WHITE, 2.5, true)
	effects.blood_burst(head_pos, dir, 14, 150.0, 0.5)
	var i := _add(Kind.WALKER, _t_walker[v], p, dir * 22.0, dir.angle(), 0.0, Color.WHITE, 0.0, true, randf_range(0.6, 1.0))
	_var[i] = v
	splatter.emit(p, 0.5)


## Распил: ноги остаются, верхняя половина скользит по удару.
func _death_bisect(p: Vector2, dir: Vector2, facing: float, v: int) -> void:
	effects.saw_contact(p, dir)
	effects.blood_burst(p, dir, 26, 180.0, 0.34)
	floor_decals.blood(_sprays.pick_random(), p, dir.angle(), 1.0, 0.6)
	floor_decals.pool(_splats.pick_random(), p, dir.angle(), 1.2)
	var back := dir
	_add_corpse(_t_legs[v], p - back * 4.0, -back * randf_range(20.0, 40.0), facing)
	_add(Kind.GIB, _t_arm[v], p, dir.orthogonal() * 75.0 + dir * 35.0, facing, 8.0, Color.WHITE, 4.0, true)
	for k in 2:
		_add(Kind.GIB, _t_guts.pick_random(), p, dir.rotated(randf_range(-0.34, 0.34)) * randf_range(30.0, 80.0), randf() * TAU, 4.0, Color.WHITE, 6.0, true, 0.0, true)
	var i := _add(Kind.CRAWLER, _t_top[v], p + Vector2.from_angle(facing) * 2.0, dir * 40.0, dir.angle(), 0.0, CORPSE_TINT, 1.5, true, randf_range(0.6, 1.0))
	_var[i] = v
	splatter.emit(p, 0.7)


func _shatter(p: Vector2, dir: Vector2) -> void:
	for i in 9:
		var vel := Vector2.from_angle(randf() * TAU) * randf_range(50.0, 170.0)
		_add(Kind.GIB, _t_shards.pick_random(), p, vel, randf() * TAU, randf_range(-20.0, 20.0), Color.WHITE, 6.0, false)
	for i in 3:
		var vel := dir.rotated(randf_range(-0.55, 0.55)) * randf_range(40.0, 120.0)
		_add(Kind.GIB, _t_meat.pick_random(), p, vel, randf() * TAU, randf_range(-15.0, 15.0), Color.WHITE, 6.0, true)
	for i in 14:
		effects.emit(p, Vector2.from_angle(randf() * TAU) * randf_range(30.0, 110.0), randf_range(0.2, 0.5), Color(0.8, 0.95, 1.0), 1.0, 5.0)
	floor_decals.pool(_splats.pick_random(), p, dir.angle(), 0.7)


func _crumble(p: Vector2, rot: float) -> void:
	_add(Kind.GIB, _t_ash, p, Vector2.ZERO, rot, 0.0, Color(ASH, 0.35), 5.0, false)
	for i in 10:
		effects.emit(p + Vector2(randf_range(-5, 5), randf_range(-4, 4)), Vector2(randf_range(-20, 20), randf_range(-35, -5)),
			randf_range(0.4, 0.9), Color(0.2, 0.19, 0.18, 0.8), 2.0, 3.0)


# --- обломки -------------------------------------------------------------------

## Отлетевшая пластина брони босса.
func boss_plate(p: Vector2, dir: Vector2) -> void:
	_add(Kind.GIB, _t_boss_plates.pick_random(), p, dir * randf_range(100.0, 220.0), dir.angle(), randf_range(-12, 12), Color.WHITE, 3.0, false)


## Броня использует общий физический пул, без крови и отдельных Node.
func on_armor_detached(p: Vector2, dir: Vector2, facing: float, code: int, part: int) -> void:
	var t := (code >> 15) & 3
	var offsets := [Vector2(3, 0), Vector2(-2, 0), Vector2(-1, 3), Vector2(5, 0)]
	var out := dir.rotated(_hit_rng.randf_range(-0.8, 0.8))
	if out == Vector2.ZERO: out = Vector2.from_angle(facing + 1.0)
	_event_scale = PixelArt.corpse_scale(code)
	var i := _add(Kind.GIB, _t_armor[t * 4 + part], p + (offsets[part] * _event_scale).rotated(facing), out * _hit_rng.randf_range(55.0, 100.0), facing, _hit_rng.randf_range(-9.0, 9.0), Color.WHITE, 3.2, false)
	if i >= 0: _scale[i] = _event_scale
	_event_scale = Vector2.ONE


## Смерть босса: куски летят по всему экрану (дальность = скорость / drag, до ~500 px).
func boss_burst(p: Vector2) -> void:
	for i in 80:
		# направления сгущаются в три «языка» и по скорости неравномерны: без ровного веера
		var a := TAU * i / 80.0 + randf_range(-0.12, 0.12)
		a += sin(a * 3.0 + 1.3) * 0.35
		var dir := Vector2.from_angle(a)
		var tex_id: int = _t_boss_gibs[i % 4] if i < 24 else _t_meat.pick_random()
		_add(Kind.GIB, tex_id, p + dir * 12.0, dir * randf_range(220.0, 800.0) * (1.0 + 0.3 * sin(a * 2.0)), dir.angle(), randf_range(-18, 18), Color.WHITE, 1.5, true, 0.0, i >= 24)
	for i in 12:
		boss_plate(p, Vector2.from_angle(TAU * i / 12.0))
	for i in 8:
		var dir := Vector2.from_angle(TAU * i / 8.0 + 0.2 + sin(float(i) * 2.1) * 0.3)
		floor_decals.pool(_splats[i % _splats.size()], p + dir * randf_range(30.0, 130.0), dir.angle(), 3.2)
		floor_decals.blood(_sprays[i % _sprays.size()], p + dir * 55.0, dir.angle(), 3.4, 0.8)
	effects.blood_burst(p, Vector2.RIGHT, 200, 380.0, PI)


## Труп скользит от удара, затем оседает в пул останков.
func _add_corpse(tex_id: int, p: Vector2, vel: Vector2, rot: float) -> void:
	_add(Kind.CORPSE, tex_id, p, vel * 1.35, rot, randf_range(-2.0, 2.0), CORPSE_TINT, 6.0, true, randf_range(1.8, 2.0))


## trail: за обломком остаётся кровавый след. drops_only — мелкий кусок: только редкие капли, без сплошного мазка
## (иначе десятки одинаково длинных линий из центра смерти складываются в «звезду»).
func _add(kind: int, tex_id: int, p: Vector2, v: Vector2, rot: float, spin: float, col: Color, drag: float, trail: bool, timer := 0.0, drops_only := false) -> int:
	if kind == Kind.GIB and gore_multiplier < 1.0 and randf() > gore_multiplier:
		return -1
	if count >= MAX_DEBRIS:
		# Вытеснение не запускает вторичную смерть и не добавляет новые куски рекурсивно.
		if not _keep_remains(0, 180.0):
			return -1
		_remove(0)
	var i := count
	count += 1
	_kind[i] = kind
	_tex[i] = tex_id
	_pos[i] = p
	_vel[i] = v
	_impact_dir[i] = v.normalized()
	_rot[i] = rot
	_spin[i] = spin
	_drag[i] = drag
	_age[i] = 0.0
	_timer[i] = timer
	_col[i] = col
	_trail[i] = (2 if drops_only else 1) if trail else 0
	_trail_pos[i] = p
	_var[i] = 0
	_scale[i] = _event_scale if _variant_textures.has(tex_id) else Vector2.ONE
	_stain_amount[i] = 0.0
	_stain_wet[i] = -1000.0
	_stain_at[i] = Vector2(0.5, 0.5)
	return i


var _pinned: Array[Array] = []


func _physics_process(delta: float) -> void:
	for j in range(_pinned.size() - 1, -1, -1):
		_pinned[j][2] -= delta
		if _pinned[j][2] <= 0.0: _pinned.remove_at(j)
	_stain_time += delta
	_flush_hits(delta)
	_age_remains(delta)
	var lo := arena.position + Vector2.ONE * 6.0
	var hi := arena.end - Vector2.ONE * 6.0
	var spin_decay := exp(-3.0 * delta)
	var i := count - 1
	while i >= 0:
		_age[i] += delta
		if _kind[i] == Kind.CORPSE and _age[i] < 1.8 and int(_age[i] * 8.0) != int((_age[i] - delta) * 8.0):
			var bleed := clampf(_age[i] / 1.8, 0.0, 1.0)
			floor_decals.stamp_dot(_pos[i] + Vector2(_hit_rng.randf_range(-4, 4), _hit_rng.randf_range(-3, 3)), lerpf(2.0, 4.0, bleed))
		# GIB и CORPSE (почти все обломки) особого поведения не имеют: функцию не вызываем
		if _kind[i] >= Kind.BURNING and not _update_special(i, delta):
			_remove(i)
			i -= 1
			continue
		var v := _vel[i]
		if v != Vector2.ZERO:
			var p := _pos[i] + v * delta
			# отскок от стен арены
			if p.x < lo.x or p.x > hi.x:
				v.x = -v.x * 0.5
				p.x = clampf(p.x, lo.x, hi.x)
			if p.y < lo.y or p.y > hi.y:
				v.y = -v.y * 0.5
				p.y = clampf(p.y, lo.y, hi.y)
			_pos[i] = p
			_vel[i] = v * exp(-_drag[i] * delta)
			_rot[i] += _spin[i] * delta
			_spin[i] *= spin_decay
			if _trail[i] == 2:
				# мелкие куски: редкие капли на пути, и в воздухе, и по земле
				if p.distance_squared_to(_trail_pos[i]) > 100.0:
					floor_decals.stamp_dot(p + Vector2(randf_range(-1, 1), randf_range(-1, 1)), randf_range(1.0, 2.0))
					_trail_pos[i] = p
			elif _trail[i] == 1:
				var wide := _kind[i] == Kind.CORPSE or _kind[i] == Kind.CRAWLER
				if v.length_squared() > 8100.0 and not wide:
					# летит по воздуху — роняет редкие капли
					if p.distance_squared_to(_trail_pos[i]) > 64.0:
						floor_decals.stamp_dot(p + Vector2(randf_range(-1, 1), randf_range(-1, 1)), randf_range(1.0, 2.0))
						_trail_pos[i] = p
				elif p.distance_squared_to(_trail_pos[i]) > 4.0:
					# скользит по земле — сплошной мазок: тела волокут широкую полосу, куски — тонкую
					floor_decals.smear(_trail_pos[i], p, 2.6 if wide else 1.1, 0.4 if wide else 0.3)
					_trail_pos[i] = p
		var settled := _vel[i].length_squared() < 16.0
		if settled and _age[i] > 0.2:
			if _kind[i] == Kind.GIB:
				if _bake(i):
					_remove(i)
			elif _kind[i] == Kind.CORPSE:
				_timer[i] -= delta # дёргается, пока не выйдет время
				if _timer[i] <= 0.0:
					if _bake(i):
						_remove(i)
		elif _age[i] > 4.0 and _kind[i] <= Kind.CORPSE:
			if _bake(i):
				_remove(i)
		i -= 1
	queue_redraw()


## Поведение особых обломков. Возвращает false, если обломок надо убрать.
func _update_special(i: int, delta: float) -> bool:
	match _kind[i]:
		Kind.BURNING:
			_timer[i] -= delta
			if randf() < 0.15:
				effects.emit(_pos[i], Vector2(randf_range(-6, 6), randf_range(-25, -10)), randf_range(0.6, 1.0), Color(0.15, 0.14, 0.13, 0.5), 3.0, 1.0)
			if _timer[i] <= 0.0:
				_crumble(_pos[i], _rot[i])
				return false
		Kind.STATUE:
			_timer[i] -= delta
			if _timer[i] <= 0.0:
				_shatter(_pos[i], _impact_dir[i])
				return false
		Kind.WALKER:
			_timer[i] -= delta
			# фонтан из шеи
			var fwd := _impact_dir[i]
			for k in 2:
				effects.emit(_pos[i] + fwd * 2.0, fwd.rotated(randf_range(-0.34, 0.34)) * randf_range(30.0, 90.0), randf_range(0.2, 0.4),
					BLOOD_DARK.lerp(BLOOD, randf()), 1.0, 5.0, true)
			_rot[i] += sin(_age[i] * 9.0) * delta * 1.5 # спотыкается
			_vel[i] = Vector2.from_angle(_rot[i]) * 22.0 * clampf(_timer[i] * 2.0, 0.0, 1.0)
			if _timer[i] <= 0.0:
				floor_decals.pool(_splats.pick_random(), _pos[i] + fwd * 6.0, fwd.angle(), 1.1)
				_event_scale = _scale[i]
				_add_corpse(_corpse_tex(_t_headless, _var[i]), _pos[i], fwd * 35.0, _rot[i] + randf_range(-0.3, 0.3))
				_event_scale = Vector2.ONE
				return false
		Kind.CRAWLER:
			_timer[i] -= delta
			if _timer[i] <= 0.0:
				floor_decals.pool(_splats.pick_random(), _pos[i], _impact_dir[i].angle(), 1.0)
				return not _bake(i)
	return true


func _bake(i: int) -> bool:
	match _kind[i]:
		Kind.CORPSE:
			return _keep_remains(i, 180.0)
		Kind.GIB:
			if _trail[i] != 0:
				floor_decals.stamp_dot(_pos[i], 1.8)
			return _keep_remains(i, 180.0)
		Kind.BURNING:
			_crumble(_pos[i], _rot[i])
		Kind.STATUE, Kind.WALKER, Kind.CRAWLER:
			return _keep_remains(i, 180.0)
	return true


func _keep_remains(i: int, life: float) -> bool:
	var oldest := 0
	for j in remains_count:
		if _r_age[j] / _r_life[j] > _r_age[oldest] / _r_life[oldest]:
			oldest = j
	var slot := remains_count
	if remains_count == MAX_REMAINS:
		slot = oldest
		if not _archive_remains(slot):
			# Пол не успел отрисоваться: кусок остаётся в активном пуле до следующего кадра.
			return false
	else:
		remains_count += 1
	remains_peak = maxi(remains_peak, remains_count)
	_r_stain_at[slot] = _stain_at[i]
	_r_stain_amount[slot] = _stain_amount[i]
	_r_stain_wet[slot] = _stain_wet[i]
	_r_tex[slot] = _tex[i]
	_r_pos[slot] = _pos[i]
	_r_rot[slot] = _rot[i]
	_r_scale[slot] = _scale[i]
	_r_age[slot] = 0.0
	_r_life[slot] = maxf(180.0, life)
	_r_tint[slot] = _col[i] if _tex[i] == _t_ash else Color.WHITE
	return true


func _archive_remains(j: int) -> bool:
	var old := clampf(_r_age[j] / 120.0, 0.0, 1.0)
	var tint := CORPSE_TINT.lerp(Color(0.50, 0.43, 0.42), old) * _r_tint[j]
	tint = _stain_color(tint, _r_stain_at[j], _r_stain_amount[j], _r_stain_wet[j])
	return floor_decals.bake_remains(_textures[_r_tex[j]], _r_pos[j], _r_rot[j], _r_scale[j], tint)


func _age_remains(delta: float) -> void:
	var j := remains_count - 1
	while j >= 0:
		_r_age[j] += delta
		if _r_age[j] >= _r_life[j] and _archive_remains(j):
			remains_count -= 1
			_r_stain_at[j] = _r_stain_at[remains_count]
			_r_stain_amount[j] = _r_stain_amount[remains_count]
			_r_stain_wet[j] = _r_stain_wet[remains_count]
			_r_tex[j] = _r_tex[remains_count]
			_r_pos[j] = _r_pos[remains_count]
			_r_rot[j] = _r_rot[remains_count]
			_r_scale[j] = _r_scale[remains_count]
			_r_age[j] = _r_age[remains_count]
			_r_life[j] = _r_life[remains_count]
			_r_tint[j] = _r_tint[remains_count]
		j -= 1
	_r_layer.queue_redraw()


func _draw_remains() -> void:
	var view := PixelArt.view_rect(self, 30.0)
	# Сортировка подсчётом, как у летящих кусков.
	var nt := _textures.size()
	_r_sort.resize(nt + 1)
	_r_sort.fill(0)
	for j in remains_count:
		if view.has_point(_r_pos[j]):
			_r_sort[_r_tex[j] + 1] += 1
	for t in nt:
		_r_sort[t + 1] += _r_sort[t]
	var shown := _r_sort[nt]
	for j in remains_count:
		if view.has_point(_r_pos[j]):
			var t := _r_tex[j]
			_r_order[_r_sort[t]] = j
			_r_sort[t] += 1
	for n in shown:
		var j := _r_order[n]
		var age := _r_age[j]
		var old := clampf(age / 120.0, 0.0, 1.0)
		var col := CORPSE_TINT.lerp(Color(0.50, 0.43, 0.42), old)
		col *= _r_tint[j]
		col.a = _r_tint[j].a
		var tex := _textures[_r_tex[j]]
		_r_layer.draw_set_transform(_r_pos[j], _r_rot[j], _r_scale[j] * PixelArt.ART_SCALE)
		col = _stain_color(col, _r_stain_at[j], _r_stain_amount[j], _r_stain_wet[j])
		_r_layer.draw_texture(tex, -tex.get_size() * 0.5, col)
	_r_layer.draw_set_transform(Vector2.ZERO)


func _remove(i: int) -> void:
	count -= 1
	if i == count:
		return
	_stain_at[i] = _stain_at[count]
	_stain_amount[i] = _stain_amount[count]
	_stain_wet[i] = _stain_wet[count]
	_kind[i] = _kind[count]
	_tex[i] = _tex[count]
	_pos[i] = _pos[count]
	_vel[i] = _vel[count]
	_impact_dir[i] = _impact_dir[count]
	_rot[i] = _rot[count]
	_spin[i] = _spin[count]
	_drag[i] = _drag[count]
	_age[i] = _age[count]
	_timer[i] = _timer[count]
	_col[i] = _col[count]
	_trail[i] = _trail[count]
	_trail_pos[i] = _trail_pos[count]
	_var[i] = _var[count]
	_scale[i] = _scale[count]


func _draw() -> void:
	for bolt: Array in _pinned:
		var p: Vector2 = bolt[0]
		var dir: Vector2 = bolt[1]
		draw_line(p - dir * 7.0, p + dir * 4.0, Color(0.42, 0.43, 0.39), 1.0)
		draw_line(p - dir * 7.0, p - dir * 3.0, Color(0.64, 0.58, 0.41), 1.6)
	var view := PixelArt.view_rect(self, 40.0)
	# Порядок по текстуре (подсчётом): подряд идущие одинаковые текстуры Godot склеивает в один draw call.
	var nt := _textures.size()
	if _sort_cnt.size() != nt + 1:
		_sort_cnt.resize(nt + 1)
		_order.resize(MAX_DEBRIS)
	_sort_cnt.fill(0)
	for i in count:
		if view.has_point(_pos[i]):
			_sort_cnt[_tex[i] + 1] += 1
	for t in nt:
		_sort_cnt[t + 1] += _sort_cnt[t]
	var shown := _sort_cnt[nt]
	for i in count:
		if view.has_point(_pos[i]):
			var t := _tex[i]
			_order[_sort_cnt[t]] = i
			_sort_cnt[t] += 1
	for n in shown:
		var i := _order[n]
		var tex := _textures[_tex[i]]
		var col := _col[i]
		if _tex[i] != _t_ash and _kind[i] in [Kind.CORPSE, Kind.WALKER, Kind.CRAWLER, Kind.GIB]:
			col = Color.WHITE.lerp(CORPSE_TINT, clampf(_age[i] / 0.3, 0.0, 1.0))
		var rot := _rot[i]
		match _kind[i]:
			Kind.BURNING:
				col = Color(0.65, 0.61, 0.55)
				col.a = 1.0
			Kind.STATUE:
				col = _col[i].lerp(Color(2.0, 2.0, 2.0), 0.3 + 0.3 * sin(_age[i] * 40.0))
			Kind.CORPSE:
				if _vel[i].length_squared() < 16.0 and randf() < 0.3:
					rot += randf_range(-0.07, 0.07) # судороги
			Kind.CRAWLER:
				# кишки тянутся из среза
				var back := Vector2.from_angle(rot + PI)
				var side := back.orthogonal()
				var start := _pos[i] + back * 2.0
				var pts := PackedVector2Array([start])
				for k in range(1, 5):
					pts.append(start + back * (k * 2.5) + side * sin(_age[i] * 5.0 + k) * 1.5)
				draw_set_transform(Vector2.ZERO)
				draw_polyline(pts, Color(0.62, 0.32, 0.34), 1.0)
		draw_set_transform(_pos[i], rot, _scale[i] * PixelArt.ART_SCALE)
		col = _stain_color(col, _stain_at[i], _stain_amount[i], _stain_wet[i])
		draw_texture(tex, -tex.get_size() * 0.5, col)
	draw_set_transform(Vector2.ZERO)


## Органы, петли и кости выпадают разными наборами, без одинаковой радиальной схемы.
func _spill_parts(p: Vector2, dir: Vector2, n: int) -> void:
	for k in n:
		var roll := _hit_rng.randf()
		var list: Array[int] = _t_guts if roll < 0.38 else (_t_organs if roll < 0.66 else (_t_bloody_bones if roll < 0.88 else _t_meat))
		var t := list[_hit_rng.randi_range(0, list.size() - 1)]
		var out := dir.rotated(_hit_rng.randf_range(-0.60, 0.60))
		if _radial_death and k % 5 == 0:
			out = Vector2.from_angle(_hit_rng.randf() * TAU)
		var vel := out * _hit_rng.randf_range(35.0, 180.0)
		_add(Kind.GIB, t, p, vel, _hit_rng.randf() * TAU, _hit_rng.randf_range(-12.0, 12.0), Color.WHITE, 4.0, true, 0.0, not _t_guts.has(t))


func _stain_color(col: Color, at: Vector2, amount: float, wet_at: float) -> Color:
	if amount <= 0.0:
		return col
	var code := clampi(roundi(at.x * 15.0), 0, 15) + clampi(roundi(at.y * 15.0), 0, 15) * 16 + clampi(ceili(amount * 7.0), 1, 7) * 256
	return Color(2.0 + float(code) / 2048.0, exp(-maxf(0.0, _stain_time - wet_at) / 18.0), col.r, col.a)


## Только крупные капли при падении: общий ограниченный пакет от FloorDecals.
func _on_blood_landed(at: Vector2, size: float) -> void:
	if _obstacles == null and player:
		_obstacles = player.obstacles
	var r := 4.0 + size
	for j in remains_count:
		if _r_pos[j].distance_squared_to(at) > (r + 24.0) * (r + 24.0):
			continue
		var tex := _textures[_r_tex[j]]
		var local := (at - _r_pos[j]).rotated(-_r_rot[j]) / (PixelArt.ART_SCALE * _r_scale[j]) + tex.get_size() * 0.5
		if Rect2(Vector2.ZERO, tex.get_size()).grow(r).has_point(local):
			if _r_stain_amount[j] == 0.0:
				_r_stain_at[j] = (local / tex.get_size()).clamp(Vector2(0.15, 0.15), Vector2(0.85, 0.85))
			_r_stain_amount[j] = minf(1.0, _r_stain_amount[j] + size * 0.12)
			_r_stain_wet[j] = _stain_time
			stains_on_remains += 1
	for j in count:
		if _pos[j].distance_squared_to(at) < (r + 7.0) * (r + 7.0):
			var tex := _textures[_tex[j]]
			if _stain_amount[j] == 0.0:
				_stain_at[j] = ((at - _pos[j]).rotated(-_rot[j]) / (PixelArt.ART_SCALE * _scale[j]) / tex.get_size() + Vector2(0.5, 0.5)).clamp(Vector2(0.15, 0.15), Vector2(0.85, 0.85))
			_stain_amount[j] = minf(1.0, _stain_amount[j] + size * 0.12)
			_stain_wet[j] = _stain_time
	if _horde:
		_horde.stain_blood(at, r)
	if player and player.global_position.distance_squared_to(at) < (r + 6.0) * (r + 6.0):
		player.stain_blood(at, size)
	if _obstacles:
		_obstacles.stain_blood(at, r)
