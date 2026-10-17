class_name Effects
extends Node2D
## Частицы: брызги крови, искры, дым, гильзы, следы рывка.
## Кровавые капли (bake) по окончании полёта запекаются в пол.

const MAX_PARTICLES := 3000
const BLOOD_DARK := Color(0.22, 0.015, 0.015)
const BLOOD := Color(0.45, 0.03, 0.03)

var floor_decals: FloorDecals
var gore_multiplier := 1.0
var sfx: Sfx
var casings_on_floor := 0
var mags_on_floor := 0
var lights_peak := 0
const MAX_CASINGS := 256
const CASING_IDS := ["brass_small", "brass_rifle", "shell", "mag_pistol", "mag_rifle", "mag_smg"]
const CASING_ART := ["casing_small", "casing_rifle", "casing_shell", "mag_pistol", "mag_rifle", "mag_smg"]
var _cn := 0
var _cp := PackedVector2Array()
var _cv := PackedVector2Array()
var _cz := PackedFloat32Array()
var _czv := PackedFloat32Array()
var _cr := PackedFloat32Array()
var _cspin := PackedFloat32Array()
var _cage := PackedFloat32Array()
var _ckind := PackedByteArray()
var _cbounce := PackedByteArray()
var _ctex: Array[Texture2D] = []
# Свет вспышек (P1): вместо шести PointLight2D — аддитивные радиальные пятна в одном слое.
# PointLight2D заставлял каждый пиксель двух экранных слоёв пола считать цикл по источникам (~1.7 мс GPU на встроенной).
class Glow:
	var layer: Node2D
	var enabled := false:
		set(value):
			if enabled != value and layer != null:
				layer.queue_redraw()
			enabled = value
	var position := Vector2.ZERO
	var color := Color.WHITE
	var texture_scale := 1.0 # радиус = 64 × масштаб, как у PointLight2D
	var energy := 0.0

const GLOW_GAIN := 0.24 # подобран по скриншотам: аддитивное пятно ≈ прежняя подсветка асфальта
var _lights: Array[Glow] = []
var _glow_layer: Node2D
var _glow_tex: Texture2D
var _glow_drawn := false
var _light_t := PackedFloat32Array()
var _light_duration := PackedFloat32Array()
var _light_energy := PackedFloat32Array()

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
	_cp.resize(MAX_CASINGS)
	_cv.resize(MAX_CASINGS)
	_cz.resize(MAX_CASINGS)
	_czv.resize(MAX_CASINGS)
	_cr.resize(MAX_CASINGS)
	_cspin.resize(MAX_CASINGS)
	_cage.resize(MAX_CASINGS)
	_ckind.resize(MAX_CASINGS)
	_cbounce.resize(MAX_CASINGS)
	for art: String in CASING_ART:
		_ctex.append(PixelArt.tex(art))
	_setup_lights()
	_pos.resize(MAX_PARTICLES)
	_vel.resize(MAX_PARTICLES)
	_life.resize(MAX_PARTICLES)
	_drag.resize(MAX_PARTICLES)
	_size.resize(MAX_PARTICLES)
	_col.resize(MAX_PARTICLES)
	_bake.resize(MAX_PARTICLES)


func emit(p: Vector2, v: Vector2, life: float, color: Color, size: float, drag: float, bake := false) -> void:
	if bake and gore_multiplier < 1.0 and randf() > gore_multiplier:
		return
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


## Вправо от ствола в экранных координатах; высота считается отдельно от пола.
func casing(origin: Vector2, dir: Vector2, kind := "brass_small") -> void:
	if _cn >= MAX_CASINGS:
		return
	var k := CASING_IDS.find(kind)
	if k < 0:
		return
	var i := _cn
	_cn += 1
	var mag := k >= 3
	# origin — видимая точка окна выброса, высота полёта вычитается при рисовании.
	_cp[i] = origin + Vector2(0, 5.0)
	_cv[i] = (-dir.orthogonal()).rotated(randf_range(-0.35, 0.35)) * randf_range(28.0, 55.0) - dir * 12.0
	if mag:
		_cv[i] *= 0.25
	else:
		# Метр здесь — ширина бойца (~12 ед.); гильзы расходятся на 12–36 ед.
		_cv[i] = (-dir.orthogonal()).rotated(randf_range(-1.0, 1.0)) * randf_range(35.0, 85.0) - dir * randf_range(-8.0, 20.0)
	_cz[i] = 5.0
	_czv[i] = randf_range(30.0, 52.0) if not mag else 12.0
	if not mag:
		_czv[i] = randf_range(22.0, 46.0)
	_cr[i] = randf() * TAU
	_cspin[i] = randf_range(-16.0, 16.0)
	_cage[i] = 0.0
	_ckind[i] = k
	_cbounce[i] = 0


func _update_casings(delta: float) -> void:
	var i := _cn - 1
	while i >= 0:
		_cage[i] += delta
		_cp[i] += _cv[i] * delta
		_cr[i] += _cspin[i] * delta
		_czv[i] -= 170.0 * delta
		_cz[i] += _czv[i] * delta
		if _cz[i] <= 0.0:
			_cz[i] = 0.0
			if _cbounce[i] == 0 and sfx:
				var wet := floor_decals != null and floor_decals.is_wet(_cp[i])
				var id: String = CASING_IDS[_ckind[i]] if _ckind[i] < 3 else "mag_drop"
				sfx.play("casings/" + id, _cp[i], -9.0 if wet else -2.0)
			_cbounce[i] += 1
			_cv[i] *= 0.53
			_cspin[i] *= 0.45
			_czv[i] = absf(_czv[i]) * 0.42 if _cbounce[i] < 3 else 0.0
			if _czv[i] < 5.0:
				_cv[i] *= exp(-delta * 26.0)
		if _cage[i] >= 1.5 or _cbounce[i] >= 3 and _cv[i].length_squared() < 3.0:
			if floor_decals:
				var tint := Color.WHITE
				if _ckind[i] < 3:
					# Пыль гасит латунь; на мокрой крови металл ещё темнее.
					tint = Color(0.84, 0.85, 0.88, 0.88)
					if floor_decals.is_wet(_cp[i]):
						tint = Color(0.62, 0.6, 0.62, 0.8)
				floor_decals.stamp(_ctex[_ckind[i]], _cp[i], _cr[i], tint)
				if _ckind[i] < 3:
					casings_on_floor += 1
				else:
					mags_on_floor += 1
			_cn -= 1
			_cp[i] = _cp[_cn]
			_cv[i] = _cv[_cn]
			_cz[i] = _cz[_cn]
			_czv[i] = _czv[_cn]
			_cr[i] = _cr[_cn]
			_cspin[i] = _cspin[_cn]
			_cage[i] = _cage[_cn]
			_ckind[i] = _ckind[_cn]
			_cbounce[i] = _cbounce[_cn]
		i -= 1


## Шесть источников переиспользуются, текстура общая. В headless GPU не нужен.
func _setup_lights() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var img := Image.create_empty(128, 128, false, Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128:
			var d := Vector2(x - 63.5, y - 63.5).length() / 64.0
			img.set_pixel(x, y, Color(1, 1, 1, pow(maxf(0.0, 1.0 - d), 2.0)))
	_glow_tex = ImageTexture.create_from_image(img)
	_glow_layer = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow_layer.material = mat
	_glow_layer.draw.connect(_draw_glow)
	add_child(_glow_layer)
	for i in 6:
		var glow := Glow.new()
		glow.layer = _glow_layer
		_lights.append(glow)
		_light_t.append(0.0)
		_light_duration.append(0.0)
		_light_energy.append(0.0)


func _draw_glow() -> void:
	for g in _lights:
		if not g.enabled:
			continue
		var r := g.texture_scale * 64.0
		var c := Color(g.color.r, g.color.g, g.color.b, 1.0) * (g.energy * GLOW_GAIN)
		c.a = 1.0
		_glow_layer.draw_texture_rect(_glow_tex, Rect2(g.position.x - r, g.position.y - r, r * 2.0, r * 2.0), false, c)


func flash_light(p: Vector2, color: Color, radius: float, energy: float, duration := 0.06) -> void:
	if _lights.is_empty():
		return
	var i := 0
	for k in _lights.size():
		if _light_t[k] < _light_t[i]:
			i = k
		# Одновременные стволы у одного бойца делят свет: не освещаем один пол шесть раз.
		if duration <= 0.07 and _light_duration[k] <= 0.07 and _light_t[k] > 0.0 and _lights[k].position.distance_squared_to(p) < 576.0:
			i = k
			radius = maxf(radius, _lights[k].texture_scale * 64.0)
			energy = maxf(energy, _light_energy[k] * _light_t[k] / _light_duration[k])
			break
	var light := _lights[i]
	light.position = p
	light.color = color
	light.texture_scale = radius / 64.0
	light.energy = energy
	light.enabled = true
	_glow_layer.queue_redraw()
	_light_t[i] = duration
	_light_duration[i] = duration
	_light_energy[i] = energy
	var active := 0
	for t in _light_t:
		if t > 0.0:
			active += 1
	lights_peak = maxi(lights_peak, active)


func _update_lights(delta: float) -> void:
	if _lights.is_empty():
		return
	var any := false
	for i in _lights.size():
		_light_t[i] = maxf(0.0, _light_t[i] - delta)
		_lights[i].enabled = _light_t[i] > 0.0
		if _light_t[i] > 0.0:
			any = true
			var k := _light_t[i] / _light_duration[i]
			_lights[i].energy = _light_energy[i] * k * (0.9 + 0.1 * sin(_light_t[i] * 370.0))
	# слой перерисовываем, пока есть вспышки (и один раз, чтобы стереть последнюю)
	if any or _glow_drawn:
		_glow_layer.queue_redraw()
	_glow_drawn = any


func ghost(p: Vector2, rot: float, tex: Texture2D) -> void:
	_ghost_tex = tex
	_ghost_pos.append(p)
	_ghost_rot.append(rot)
	_ghost_life.append(0.2)


func _physics_process(delta: float) -> void:
	_update_casings(delta)
	_update_lights(delta)
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
	var view := PixelArt.view_rect(self, 24.0)
	var dot := PixelArt.dot()
	for i in _n:
		if not view.has_point(_pos[i]):
			continue # вне экрана не рисуем
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
				var r := s * 0.35
				draw_texture_rect(dot, Rect2(_pos[i].x - r, _pos[i].y - r, r * 2.0, r * 2.0), false, c)
		else:
			draw_rect(Rect2(_pos[i].x - s * 0.3, _pos[i].y - s * 0.3, s * 0.6, s * 0.6), c)
	for i in _cn:
		if not view.has_point(_cp[i]):
			continue
		PixelArt.draw_dot(self, _cp[i], 1.2 if _ckind[i] < 3 else 2.5, Color(0, 0, 0, 0.3))
		var tex := _ctex[_ckind[i]]
		draw_set_transform(_cp[i] - Vector2(0, _cz[i]), _cr[i], Vector2.ONE * PixelArt.ART_SCALE)
		# В полёте латунь может блеснуть; на полу она уже тусклая.
		var glint := Color(1.3, 1.25, 1.1) if _ckind[i] < 3 and _cz[i] > 0.5 else Color.WHITE
		draw_texture(tex, -tex.get_size() * 0.5, glint)
	draw_set_transform(Vector2.ZERO)
	if _ghost_tex:
		var half := _ghost_tex.get_size() * 0.5
		for g in _ghost_life.size():
			draw_set_transform(_ghost_pos[g], _ghost_rot[g], Vector2(PixelArt.ART_SCALE, PixelArt.ART_SCALE))
			draw_texture(_ghost_tex, -half, Color(0.5, 0.8, 1.0, _ghost_life[g] / 0.2 * 0.5))
		draw_set_transform(Vector2.ZERO)
