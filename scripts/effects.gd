class_name Effects
extends Node2D
## Частицы: брызги крови, искры, дым, гильзы, следы рывка.
## Кровавые капли (bake) по окончании полёта запекаются в пол.

const MAX_PARTICLES := 3000
const BLOOD_DARK := Color(0.22, 0.015, 0.015)
const BLOOD := Color(0.45, 0.03, 0.03)

var floor_decals: FloorDecals

var _n := 0
var _bake := PackedByteArray()
var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _life := PackedFloat32Array()
var _drag := PackedFloat32Array()
var _size := PackedFloat32Array()
var _col := PackedColorArray()

# следы рывка: позиция, поворот, оставшаяся жизнь
var _ghost_pos := PackedVector2Array()
var _ghost_rot := PackedFloat32Array()
var _ghost_life := PackedFloat32Array()
var _ghost_tex: Texture2D


func _ready() -> void:
	_pos.resize(MAX_PARTICLES)
	_vel.resize(MAX_PARTICLES)
	_life.resize(MAX_PARTICLES)
	_drag.resize(MAX_PARTICLES)
	_size.resize(MAX_PARTICLES)
	_col.resize(MAX_PARTICLES)
	_bake.resize(MAX_PARTICLES)


func emit(p: Vector2, v: Vector2, life: float, color: Color, size: float, drag: float, bake := false) -> void:
	var i := _n
	if _n >= MAX_PARTICLES:
		i = randi() % MAX_PARTICLES # переполнение: затираем случайную
	else:
		_n += 1
	_pos[i] = p
	_vel[i] = v
	_life[i] = life
	_drag[i] = drag
	_size[i] = size
	_col[i] = color
	_bake[i] = 1 if bake else 0


func particle_count() -> int:
	return _n


## Веер кровавых капель по направлению dir; все они остаются на полу.
func blood_burst(p: Vector2, dir: Vector2, n: int, speed: float, spread: float) -> void:
	for k in n:
		var v := dir.rotated(randf_range(-spread, spread)) * randf_range(speed * 0.25, speed)
		var size := 2.0 if randf() < 0.25 else 1.0
		emit(p, v, randf_range(0.15, 0.45), BLOOD_DARK.lerp(BLOOD, randf()), size, 6.0, true)


## Попадание без смерти: короткий выплеск крови из выходного отверстия.
func blood_hit(p: Vector2, dir: Vector2, big: bool) -> void:
	blood_burst(p, dir, 12 if big else 3, 140.0 if big else 90.0, 0.6)


func casing(origin: Vector2, dir: Vector2) -> void:
	var side := -dir.orthogonal()
	var v := side.rotated(randf_range(-0.4, 0.4)) * randf_range(40.0, 70.0) - dir * 10.0
	emit(origin, v, 2.5, Color(0.85, 0.68, 0.3), 1.0, 6.0)


func ghost(p: Vector2, rot: float, tex: Texture2D) -> void:
	_ghost_tex = tex
	_ghost_pos.append(p)
	_ghost_rot.append(rot)
	_ghost_life.append(0.2)


func _physics_process(delta: float) -> void:
	var i := _n - 1
	while i >= 0:
		_life[i] -= delta
		if _life[i] <= 0.0:
			if _bake[i] == 1 and floor_decals:
				floor_decals.stamp_dot(_pos[i], _size[i], _col[i])
			_n -= 1
			_bake[i] = _bake[_n]
			_pos[i] = _pos[_n]
			_vel[i] = _vel[_n]
			_life[i] = _life[_n]
			_drag[i] = _drag[_n]
			_size[i] = _size[_n]
			_col[i] = _col[_n]
		else:
			_pos[i] += _vel[i] * delta
			_vel[i] *= exp(-_drag[i] * delta)
		i -= 1

	var g := _ghost_life.size() - 1
	while g >= 0:
		_ghost_life[g] -= delta
		if _ghost_life[g] <= 0.0:
			_ghost_pos.remove_at(g)
			_ghost_rot.remove_at(g)
			_ghost_life.remove_at(g)
		g -= 1
	queue_redraw()


func _draw() -> void:
	for i in _n:
		var c := _col[i]
		if _bake[i] == 0:
			c.a *= clampf(_life[i] / 0.5, 0.0, 1.0) # затухание в последние полсекунды
		var s := _size[i]
		if _bake[i] == 1:
			# летящая капля вытягивается вдоль скорости; упавшая — круглая
			var v := _vel[i] * 0.025
			if v.length_squared() > 0.25:
				draw_line(_pos[i] - v, _pos[i], c, s * 0.55)
			else:
				PixelArt.draw_dot(self, _pos[i], s * 0.35, c)
		else:
			draw_rect(Rect2(_pos[i] - Vector2(s, s) * 0.3, Vector2(s, s) * 0.6), c)
	if _ghost_tex:
		var half := _ghost_tex.get_size() * 0.5
		for g in _ghost_life.size():
			draw_set_transform(_ghost_pos[g], _ghost_rot[g], Vector2(PixelArt.ART_SCALE, PixelArt.ART_SCALE))
			draw_texture(_ghost_tex, -half, Color(0.5, 0.8, 1.0, _ghost_life[g] / 0.2 * 0.5))
		draw_set_transform(Vector2.ZERO)
