class_name Gore
extends Node2D
## Смерти, раны и куски мяса. Трупы и гибы — «обломки» с простой физикой:
## разлетаются, крутятся, оставляют кровавый след, а остановившись, запекаются в пол.
## Тип смерти задают патроны (GDD §5.3, §6.4).

## Близкая кровавая смерть: игра решает, забрызгать ли экран.
signal splatter(pos: Vector2, strength: float)

enum Death { NORMAL, HEADSHOT, GIBS, BURN, ICE, DECAP, BISECT }
const DEATH_NAMES := ["обычная", "голова лопается", "гибы", "сожжение", "лёд", "обезглавливание", "распил"]

## GIB — летящий кусок; CORPSE — труп (скользит, дёргается, запекается);
## BURNING/STATUE — горящий и замёрзший; WALKER — тело без головы ещё идёт;
## CRAWLER — верхняя половина после распила ползёт к игроку.
enum Kind { GIB, CORPSE, BURNING, STATUE, WALKER, CRAWLER }

const MAX_DEBRIS := 900
const BLOOD := Color(0.42, 0.03, 0.03)
const BLOOD_DARK := Color(0.22, 0.015, 0.015)
const ASH := Color(0.09, 0.08, 0.075)
const CORPSE_TINT := Color(0.8, 0.8, 0.8)

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
var _shirt: Array[Color] = []
# общие
var _t_burnt: Array[int] = []
var _t_brain := 0
var _t_jaw := 0
var _t_eye := 0
var _t_bone := 0
var _t_skull := 0
var _t_rib := 0
var _t_spine := 0
var _t_guts: Array[int] = []
var _t_meat: Array[int] = []
var _t_shards: Array[int] = []
var _splats: Array[Texture2D] = []
var _sprays: Array[Texture2D] = []

var count := 0
var _kind := PackedInt32Array()
var _tex := PackedInt32Array()
var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _rot := PackedFloat32Array()
var _spin := PackedFloat32Array()
var _drag := PackedFloat32Array()
var _age := PackedFloat32Array()
var _timer := PackedFloat32Array()
var _col := PackedColorArray()
var _trail := PackedByteArray()
var _trail_pos := PackedVector2Array()
var _var := PackedByteArray()


func _ready() -> void:
	_kind.resize(MAX_DEBRIS)
	_tex.resize(MAX_DEBRIS)
	_pos.resize(MAX_DEBRIS)
	_vel.resize(MAX_DEBRIS)
	_rot.resize(MAX_DEBRIS)
	_spin.resize(MAX_DEBRIS)
	_drag.resize(MAX_DEBRIS)
	_age.resize(MAX_DEBRIS)
	_timer.resize(MAX_DEBRIS)
	_col.resize(MAX_DEBRIS)
	_trail.resize(MAX_DEBRIS)
	_trail_pos.resize(MAX_DEBRIS)
	_var.resize(MAX_DEBRIS)

	for v in PixelArt.VARIANT_COUNT:
		for pose in PixelArt.CORPSE_POSES: # индекс: вид × позы + поза
			_t_corpse.append(_load("corpse_%d_%d" % [v, pose]))
			_t_headless.append(_load("corpse_headless_%d_%d" % [v, pose]))
		_t_whole.append(_load("zombie_whole_%d" % v))
		_t_walker.append(_load("zombie_headless_%d" % v))
		_t_top.append(_load("zombie_top_%d" % v))
		_t_legs.append(_load("legs_%d" % v))
		_t_head.append(_load("gib_head_%d" % v))
		_t_arm.append(_load("gib_arm_%d" % v))
		_t_torso.append(_load("gib_torso_%d" % v))
	_shirt.assign([Color("4d6074"), Color("c9cbc1"), Color("515a3a"), Color("d26c24"), Color("323235"), Color("b2a88a"), Color("56683b")])
	for pose in PixelArt.CORPSE_POSES:
		_t_burnt.append(_load("corpse_burnt_%d" % pose))
	_t_bone = _load("gib_bone")
	_t_skull = _load("gib_skull_0")
	_t_brain = _load("gib_brain")
	_t_jaw = _load("gib_jaw")
	_t_eye = _load("gib_eye")
	_t_rib = _load("gib_rib")
	_t_spine = _load("gib_spine")
	for k in 3:
		_t_guts.append(_load("gib_guts_%d" % k))
		_t_shards.append(_load("gib_shard_%d" % k))
	for k in 4:
		_t_meat.append(_load("gib_meat_%d" % k))
	_t_meat.append(_load("gib_skull_1"))
	for k in 8:
		_splats.append(PixelArt.tex("blood_%d" % k))
	for k in 4:
		_sprays.append(PixelArt.tex("spray_%d" % k))


func setup(floor_layer: FloorDecals, fx: Effects, arena_rect: Rect2, target: Player) -> void:
	floor_decals = floor_layer
	effects = fx
	arena = arena_rect
	player = target


func _load(art_name: String) -> int:
	_textures.append(PixelArt.tex(art_name))
	return _textures.size() - 1


func _corpse_tex(list: Array[int], v: int) -> int:
	return list[v * PixelArt.CORPSE_POSES + randi() % PixelArt.CORPSE_POSES]


# --- реакция на события орды -------------------------------------------------

func on_enemy_killed(p: Vector2, dir: Vector2, death: int, facing: float, v: int) -> void:
	if v == 6:
		# Капли кислоты вперемешку с обычной кровью при любом типе смерти.
		_acid_drops(p, 12)
	match death:
		Death.HEADSHOT:
			_death_headshot(p, dir, v)
		Death.GIBS:
			_death_gibs(p, dir, v)
		Death.BURN:
			_death_burn(p, dir)
		Death.ICE:
			_death_ice(p, facing, v)
		Death.DECAP:
			_death_decap(p, dir, facing, v)
		Death.BISECT:
			_death_bisect(p, dir, facing, v)
		_:
			_death_normal(p, dir, v)


## Попадание без смерти: клочья одежды.
func on_enemy_hit(p: Vector2, dir: Vector2, v: int) -> void:
	if v == 6:
		_acid_drops(p, 3)
	if randf() < 0.3:
		var c := _shirt[v].darkened(randf_range(0.0, 0.3))
		effects.emit(p, dir.rotated(randf_range(-0.8, 0.8)) * randf_range(40.0, 90.0), randf_range(0.6, 1.2), c, 1.0, 6.0)


## Новая стадия раны: что-то отлетает с той стороны, куда попали.
func on_enemy_wounded(p: Vector2, dir: Vector2, facing: float, v: int, stage: int, wound: int) -> void:
	if v == 6:
		_acid_drops(p, 4 + stage * 2)
	effects.blood_burst(p, dir, 4 + stage * 3, 90.0, 0.7)
	if wound & PixelArt.WOUND_ARM_L or wound & PixelArt.WOUND_ARM_R:
		var side := -1.0 if wound & PixelArt.WOUND_ARM_L else 1.0
		var shoulder := p + Vector2(3.0, 5.5 * side).rotated(facing)
		var out := Vector2.from_angle(facing + PI * 0.5 * side).lerp(dir, 0.4).normalized()
		_add(Kind.GIB, _t_arm[v], shoulder, out * randf_range(60.0, 120.0), randf() * TAU, randf_range(-14.0, 14.0), Color.WHITE, 5.0, true)
		effects.blood_burst(shoulder, out, 8, 100.0, 0.5)
	if wound & PixelArt.WOUND_CHEST:
		_add(Kind.GIB, _t_rib, p, dir.rotated(randf_range(-1.0, 1.0)) * randf_range(50.0, 100.0), randf() * TAU, randf_range(-12.0, 12.0), Color.WHITE, 6.0, false)
		_add(Kind.GIB, _t_meat.pick_random(), p, dir.rotated(randf_range(-1.0, 1.0)) * randf_range(40.0, 90.0), randf() * TAU, 8.0, Color.WHITE, 6.0, true)
	if wound & PixelArt.WOUND_HEAD:
		for i in 3:
			var tid: int = _t_skull if i == 0 else _t_meat.pick_random()
			_add(Kind.GIB, tid, p, dir.rotated(randf_range(-0.7, 0.7)) * randf_range(60.0, 140.0), randf() * TAU, randf_range(-16.0, 16.0), Color.WHITE, 6.0, i > 0)
		_add(Kind.GIB, _t_guts.pick_random(), p, -dir * 20.0, randf() * TAU, 3.0, Color.WHITE, 8.0, true)


## Только визуальные капли; опасные лужи создаёт Hazards в S2.
func _acid_drops(p: Vector2, n: int) -> void:
	for j in n:
		var velocity := Vector2.from_angle(randf() * TAU) * randf_range(35.0, 120.0)
		effects.emit(p, velocity, randf_range(0.3, 0.7), Color(0.29, 0.40, 0.12), randf_range(0.7, 1.3), 5.0, true)


# --- типы смерти -------------------------------------------------------------

func _death_normal(p: Vector2, dir: Vector2, v: int) -> void:
	effects.blood_burst(p, dir, 10, 120.0, 0.7)
	floor_decals.pool(_splats.pick_random(), p + dir * 6.0, randf() * TAU, 0.8)
	_add_corpse(_corpse_tex(_t_corpse, v), p, dir * randf_range(50.0, 90.0), dir.angle() + randf_range(-0.4, 0.4))


func _death_headshot(p: Vector2, dir: Vector2, v: int) -> void:
	# голова лопается: направленный фонтан, осколки черепа, безголовый труп
	effects.blood_burst(p, dir, 26, 200.0, 0.4)
	floor_decals.blood(_sprays.pick_random(), p + dir * 14.0, dir.angle() + randf_range(-0.15, 0.15), 1.2, 0.7)
	for i in 5:
		var vel := dir.rotated(randf_range(-0.6, 0.6)) * randf_range(80.0, 210.0)
		var tid: int = [_t_skull, _t_jaw, _t_brain, _t_eye, _t_meat.pick_random()][i]
		_add(Kind.GIB, tid, p, vel, randf() * TAU, randf_range(-20.0, 20.0), Color.WHITE, 6.0, i >= 2)
	_add_corpse(_corpse_tex(_t_headless, v), p, dir * randf_range(60.0, 100.0), dir.angle() + randf_range(-0.3, 0.3))
	splatter.emit(p, 0.6)


func _death_gibs(p: Vector2, dir: Vector2, v: int) -> void:
	var bursts := 2 if v == 5 else 1
	for j in bursts:
		var burst_dir := Vector2.from_angle(randf() * TAU) if v == 5 else dir
		effects.blood_burst(p, burst_dir, 30, 210.0, 1.3)
	if v == 5:
		floor_decals.pool(_splats.pick_random(), p + Vector2.from_angle(randf() * TAU) * 8.0, randf() * TAU, 1.4)
		floor_decals.blood(_sprays.pick_random(), p - dir * 10.0, dir.angle() + PI, 1.1, 0.6)
	floor_decals.pool(_splats.pick_random(), p, randf() * TAU, 1.4)
	floor_decals.blood(_sprays.pick_random(), p + dir * 10.0, dir.angle(), 1.1, 0.6)
	var parts: Array[int] = [_t_head[v], _t_arm[v], _t_arm[v], _t_torso[v], _t_rib, _t_spine, _t_bone, _t_brain, _t_jaw, _t_eye]
	for i in 4 if v == 5 else 2:
		parts.append(_t_guts.pick_random())
	for i in 4:
		parts.append(_t_meat.pick_random())
	for t in parts:
		var out := Vector2.from_angle(randf() * TAU) if v == 5 else dir.rotated(randf_range(-1.3, 1.3))
		var vel := out * randf_range(60.0, 230.0)
		var bloody := t != _t_bone and t != _t_rib and t != _t_spine
		_add(Kind.GIB, t, p + Vector2(randf_range(-3, 3), randf_range(-3, 3)), vel, randf() * TAU, randf_range(-18.0, 18.0), Color.WHITE, 4.5, bloody)
	splatter.emit(p, 1.0)


func _death_burn(p: Vector2, dir: Vector2) -> void:
	for i in 8:
		effects.emit(p, Vector2.from_angle(randf() * TAU) * randf_range(20.0, 70.0), randf_range(0.3, 0.7), Color(1.0, randf_range(0.4, 0.75), 0.1), 1.0, 4.0)
	_add(Kind.BURNING, _t_burnt.pick_random(), p, dir * 30.0, dir.angle() + randf_range(-0.4, 0.4), 0.0, Color.WHITE, 9.0, false, randf_range(1.2, 1.8))


func _death_ice(p: Vector2, facing: float, v: int) -> void:
	_add(Kind.STATUE, _t_whole[v], p, Vector2.ZERO, facing, 0.0, Color(0.75, 0.95, 1.15), 0.0, false, randf_range(0.3, 0.45))


## Голова отлетает и катится, тело делает ещё пару шагов с фонтаном из шеи.
func _death_decap(p: Vector2, dir: Vector2, facing: float, v: int) -> void:
	var head_pos := p + Vector2.from_angle(facing) * 2.0
	var hv := dir.rotated(randf_range(-0.5, 0.5)) * randf_range(120.0, 200.0)
	_add(Kind.GIB, _t_head[v], head_pos, hv, randf() * TAU, hv.length() * 0.12 * (1.0 if randf() < 0.5 else -1.0), Color.WHITE, 2.5, true)
	effects.blood_burst(head_pos, dir, 14, 150.0, 0.5)
	var i := _add(Kind.WALKER, _t_walker[v], p, Vector2.from_angle(facing) * 22.0, facing, 0.0, Color.WHITE, 0.0, true, randf_range(0.6, 1.0))
	_var[i] = v
	splatter.emit(p, 0.5)


## Распил: ноги остаются, верхняя половина ещё ползёт к игроку.
func _death_bisect(p: Vector2, dir: Vector2, facing: float, v: int) -> void:
	effects.blood_burst(p, dir, 20, 140.0, 1.0)
	floor_decals.blood(_sprays.pick_random(), p, dir.angle(), 1.0, 0.6)
	floor_decals.pool(_splats.pick_random(), p, randf() * TAU, 0.9)
	var back := Vector2.from_angle(facing + PI)
	_add_corpse(_t_legs[v], p + back * 3.0, back * randf_range(20.0, 40.0), facing)
	for k in 2:
		_add(Kind.GIB, _t_guts.pick_random(), p, dir.rotated(randf_range(-1.0, 1.0)) * randf_range(30.0, 80.0), randf() * TAU, 4.0, Color.WHITE, 6.0, true)
	var i := _add(Kind.CRAWLER, _t_top[v], p + Vector2.from_angle(facing) * 2.0, Vector2.ZERO, facing, 0.0, Color.WHITE, 0.0, true, randf_range(1.2, 2.0))
	_var[i] = v
	splatter.emit(p, 0.7)


func _shatter(p: Vector2) -> void:
	for i in 9:
		var vel := Vector2.from_angle(randf() * TAU) * randf_range(50.0, 170.0)
		_add(Kind.GIB, _t_shards.pick_random(), p, vel, randf() * TAU, randf_range(-20.0, 20.0), Color.WHITE, 6.0, false)
	for i in 3:
		var vel := Vector2.from_angle(randf() * TAU) * randf_range(40.0, 120.0)
		_add(Kind.GIB, _t_meat.pick_random(), p, vel, randf() * TAU, randf_range(-15.0, 15.0), Color.WHITE, 6.0, true)
	for i in 14:
		effects.emit(p, Vector2.from_angle(randf() * TAU) * randf_range(30.0, 110.0), randf_range(0.2, 0.5), Color(0.8, 0.95, 1.0), 1.0, 5.0)
	floor_decals.pool(_splats.pick_random(), p, randf() * TAU, 0.5)


func _crumble(p: Vector2, rot: float) -> void:
	floor_decals.stamp(_splats.pick_random(), p, rot, Color(ASH, 0.85), 1.2)
	for i in 10:
		effects.emit(p + Vector2(randf_range(-5, 5), randf_range(-4, 4)), Vector2(randf_range(-20, 20), randf_range(-35, -5)),
			randf_range(0.4, 0.9), Color(0.2, 0.19, 0.18, 0.8), 2.0, 3.0)


# --- обломки -------------------------------------------------------------------

## Труп скользит от удара, затем дёргается timer секунд и запекается.
func _add_corpse(tex_id: int, p: Vector2, vel: Vector2, rot: float) -> void:
	_add(Kind.CORPSE, tex_id, p, vel, rot, randf_range(-2.0, 2.0), CORPSE_TINT, 7.0, true, randf_range(0.5, 1.6))


func _add(kind: int, tex_id: int, p: Vector2, v: Vector2, rot: float, spin: float, col: Color, drag: float, trail: bool, timer := 0.0) -> int:
	if count >= MAX_DEBRIS:
		_bake(0)
		_remove(0)
	var i := count
	count += 1
	_kind[i] = kind
	_tex[i] = tex_id
	_pos[i] = p
	_vel[i] = v
	_rot[i] = rot
	_spin[i] = spin
	_drag[i] = drag
	_age[i] = 0.0
	_timer[i] = timer
	_col[i] = col
	_trail[i] = 1 if trail else 0
	_trail_pos[i] = p
	_var[i] = 0
	return i


func _physics_process(delta: float) -> void:
	var lo := arena.position + Vector2.ONE * 6.0
	var hi := arena.end - Vector2.ONE * 6.0
	var i := count - 1
	while i >= 0:
		_age[i] += delta
		if not _update_special(i, delta):
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
			_spin[i] *= exp(-3.0 * delta)
			if _trail[i] == 1:
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
				_bake(i)
				_remove(i)
			elif _kind[i] == Kind.CORPSE:
				_timer[i] -= delta # дёргается, пока не выйдет время
				if _timer[i] <= 0.0:
					_bake(i)
					_remove(i)
		i -= 1
	queue_redraw()


## Поведение особых обломков. Возвращает false, если обломок надо убрать.
func _update_special(i: int, delta: float) -> bool:
	match _kind[i]:
		Kind.BURNING:
			_timer[i] -= delta
			if randf() < 0.35:
				effects.emit(_pos[i] + Vector2(randf_range(-5, 5), randf_range(-4, 4)), Vector2(randf_range(-8, 8), randf_range(-40, -15)),
					randf_range(0.3, 0.7), Color(1.0, randf_range(0.35, 0.7), 0.05), 1.0, 1.5)
			if randf() < 0.15:
				effects.emit(_pos[i], Vector2(randf_range(-6, 6), randf_range(-25, -10)), randf_range(0.6, 1.0), Color(0.15, 0.14, 0.13, 0.5), 3.0, 1.0)
			if _timer[i] <= 0.0:
				_crumble(_pos[i], _rot[i])
				return false
		Kind.STATUE:
			_timer[i] -= delta
			if _timer[i] <= 0.0:
				_shatter(_pos[i])
				return false
		Kind.WALKER:
			_timer[i] -= delta
			# фонтан из шеи
			var fwd := Vector2.from_angle(_rot[i])
			for k in 2:
				effects.emit(_pos[i] + fwd * 2.0, fwd.rotated(randf_range(-0.9, 0.9)) * randf_range(30.0, 90.0), randf_range(0.2, 0.4),
					BLOOD_DARK.lerp(BLOOD, randf()), 1.0, 5.0, true)
			_rot[i] += sin(_age[i] * 9.0) * delta * 1.5 # спотыкается
			_vel[i] = Vector2.from_angle(_rot[i]) * 22.0 * clampf(_timer[i] * 2.0, 0.0, 1.0)
			if _timer[i] <= 0.0:
				floor_decals.pool(_splats.pick_random(), _pos[i] + fwd * 6.0, randf() * TAU, 0.9)
				_add_corpse(_corpse_tex(_t_headless, _var[i]), _pos[i], fwd * 35.0, _rot[i] + randf_range(-0.3, 0.3))
				return false
		Kind.CRAWLER:
			_timer[i] -= delta
			if player:
				var want := (player.global_position - _pos[i]).angle()
				_rot[i] = lerp_angle(_rot[i], want, delta * 2.0)
			# ползёт рывками: подтягивается руками
			var pull := maxf(sin(_age[i] * 8.0), 0.0)
			_vel[i] = Vector2.from_angle(_rot[i]) * 26.0 * pull * clampf(_timer[i], 0.0, 1.0)
			if _timer[i] <= 0.0:
				floor_decals.pool(_splats.pick_random(), _pos[i], randf() * TAU, 0.8)
				floor_decals.stamp(_textures[_tex[i]], _pos[i], _rot[i], CORPSE_TINT)
				return false
	return true


func _bake(i: int) -> void:
	var tex := _textures[_tex[i]]
	match _kind[i]:
		Kind.CORPSE:
			floor_decals.pool(_splats.pick_random(), _pos[i], randf() * TAU, 0.9)
			floor_decals.stamp(tex, _pos[i], _rot[i], _col[i])
		Kind.GIB:
			if _trail[i] == 1:
				floor_decals.stamp_dot(_pos[i], 3.0)
			floor_decals.stamp(tex, _pos[i], _rot[i], CORPSE_TINT)
		Kind.BURNING:
			_crumble(_pos[i], _rot[i])
		Kind.STATUE, Kind.WALKER, Kind.CRAWLER:
			floor_decals.stamp(tex, _pos[i], _rot[i], CORPSE_TINT)


func _remove(i: int) -> void:
	count -= 1
	if i == count:
		return
	_kind[i] = _kind[count]
	_tex[i] = _tex[count]
	_pos[i] = _pos[count]
	_vel[i] = _vel[count]
	_rot[i] = _rot[count]
	_spin[i] = _spin[count]
	_drag[i] = _drag[count]
	_age[i] = _age[count]
	_timer[i] = _timer[count]
	_col[i] = _col[count]
	_trail[i] = _trail[count]
	_trail_pos[i] = _trail_pos[count]
	_var[i] = _var[count]


func _draw() -> void:
	for i in count:
		var tex := _textures[_tex[i]]
		var col := _col[i]
		var rot := _rot[i]
		match _kind[i]:
			Kind.BURNING:
				col = Color(1.0, 0.6, 0.4).lerp(Color.WHITE, 1.0 - clampf(_timer[i], 0.0, 1.0)) * randf_range(0.85, 1.15)
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
		draw_set_transform(_pos[i], rot, Vector2(PixelArt.ART_SCALE, PixelArt.ART_SCALE))
		draw_texture(tex, -tex.get_size() * 0.5, col)
	draw_set_transform(Vector2.ZERO)
