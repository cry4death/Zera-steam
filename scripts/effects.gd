class_name Effects
extends Node2D
## Частицы: брызги крови, искры, дым, гильзы, следы рывка.
## Кровавые капли (bake) по окончании полёта запекаются в пол.

const MAX_PARTICLES := 3000
const BLOOD_DARK := Color(0.023, 0.0009, 0.0018)
const BLOOD := Color(0.195, 0.0037, 0.006)
const BLOOD_INK := [Color(0.023, 0.0009, 0.0018), Color(0.063, 0.0018, 0.0033), Color(0.156, 0.003, 0.0044), Color(0.195, 0.0037, 0.006)]

var floor_decals: FloorDecals
var gore_multiplier := 1.0
var sfx: Sfx
var casings_on_floor := 0
var _armor_rng := RandomNumberGenerator.new()
var _armor_audio_at := -100.0
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
var _bake := PackedByteArray() # 0 — прочее, 1 — капля, 2 — дымка, 3 — крупная капля со следом
var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _life := PackedFloat32Array()
var _drag := PackedFloat32Array()
var _size := PackedFloat32Array()
var _col := PackedColorArray()
var _drop_at := PackedVector2Array()
var _blood_lines: Array[PackedVector2Array] = []
var _blood_tokens := 160.0
var _blood_frame := -1
var _blood_in_frame := 0
var _hazards: Hazards
var _acid_rims: Array[Texture2D] = []

# следы рывка: позиция, поворот, оставшаяся жизнь
var _ghost_pos := PackedVector2Array()
var _ghost_rot := PackedFloat32Array()
var _ghost_life := PackedFloat32Array()
var _ghost_tex: Texture2D


func _ready() -> void:
	_armor_rng.seed = 81073
	_fx_rng.seed = 771107
	_ground_layer = Node2D.new()
	_ground_layer.z_index = 1
	_ground_mat = ShaderMaterial.new()
	_ground_mat.shader = preload("res://shaders/fuel_fire.gdshader")
	_ground_mat.set_shader_parameter("noise_tex", preload("res://shaders/fire_noise.tres"))
	_ground_layer.material = _ground_mat
	_ground_layer.draw.connect(_draw_ground_fire)
	add_child(_ground_layer)
	_jet_layer = Node2D.new()
	_jet_layer.z_index = 2
	_jet_mat = ShaderMaterial.new()
	_jet_mat.shader = preload("res://shaders/fuel_fire.gdshader")
	_jet_mat.set_shader_parameter("noise_tex", preload("res://shaders/fire_noise.tres"))
	_jet_mat.set_shader_parameter("jet", true)
	_jet_layer.material = _jet_mat
	_jet_layer.draw.connect(_draw_flame_jets)
	add_child(_jet_layer)
	_weapon_layer = Node2D.new()
	_weapon_layer.z_index = 2
	_weapon_layer.draw.connect(_draw_weapon_fx)
	add_child(_weapon_layer)
	_hazards = get_parent().get_node_or_null("Hazards") as Hazards
	if _hazards:
		for tex: Texture2D in _hazards._acid_tex:
			if not tex:
				_acid_rims.append(null)
				continue
			var source := tex.get_image()
			var rim := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
			for y in range(1, source.get_height() - 1):
				for x in range(1, source.get_width() - 1):
					var alpha := source.get_pixel(x, y).a
					var neighbor := minf(source.get_pixel(x - 1, y).a, source.get_pixel(x + 1, y).a)
					neighbor = minf(neighbor, minf(source.get_pixel(x, y - 1).a, source.get_pixel(x, y + 1).a))
					if alpha >= 0.32 and neighbor < 0.32:
						rim.set_pixel(x, y, Color(0.58, 0.62, 0.34, 0.85))
			_acid_rims.append(ImageTexture.create_from_image(rim))
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
	_drop_at.resize(MAX_PARTICLES)
	for k in 8:
		_blood_lines.append(PackedVector2Array())


func emit(p: Vector2, v: Vector2, life: float, color: Color, size: float, drag: float, bake := false) -> int:
	if bake and gore_multiplier < 1.0 and randf() > gore_multiplier:
		return -1
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
	_drop_at[i] = p
	return i


func particle_count() -> int:
	return _n


## Короткий веер металла с обратным следом рикошета, без кровавого декаля.
func armor_impact(at: Vector2, dir: Vector2) -> void:
	for j in 7:
		var out := (-dir).rotated(_armor_rng.randf_range(-1.25, 1.25))
		var i := emit(at, out * _armor_rng.randf_range(45.0, 135.0), _armor_rng.randf_range(0.09, 0.20), Color(0.92, 0.73, 0.38) if j < 3 else Color(0.60, 0.65, 0.61), 0.45 if j < 5 else 0.7, 2.0)
		if i >= 0 and j < 3: _bake[i] = 4
	# Звук не вытесняет выстрелы при четырёх автоматах.
	var now := Time.get_ticks_msec() * 0.001
	if sfx and now - _armor_audio_at > 0.055:
		sfx.play("gore/armor", at, -2.0, 0.04, 1.5)
		_armor_audio_at = now


## Веер кровавых капель по направлению dir; все они остаются на полу.
func blood_burst(p: Vector2, dir: Vector2, n: int, speed: float, spread: float, rng: RandomNumberGenerator = null) -> void:
	var frame := Engine.get_process_frames()
	if frame != _blood_frame:
		_blood_frame = frame
		_blood_in_frame = 0
	var budget := mini(n, mini(int(_blood_tokens), maxi(0, 160 - _blood_in_frame)))
	_blood_tokens -= budget
	_blood_in_frame += budget
	for k in budget:
		var angle := rng.randf_range(-spread, spread) if rng else randf_range(-spread, spread)
		var grain := rng.randf() if rng else randf()
		var life := rng.randf_range(0.30, 0.56) if rng else randf_range(0.30, 0.56)
		var reach := (rng.randf() if rng else randf())
		reach = lerpf(0.8, clampf(speed * 0.45, 8.0, 120.0), pow(reach, 2.0))
		var velocity := reach * 1.8 / (1.0 - exp(-1.8 * life))
		var shade := rng.randf() if rng else randf()
		var size := 3.2 if grain < 0.25 else 1.25
		var i := emit(p, dir.rotated(angle) * velocity, life, BLOOD_DARK.lerp(BLOOD, shade), size, 1.8, true)
		if i >= 0 and grain < 0.25:
			_bake[i] = 3


## Попадание без смерти: короткий выплеск крови из выходного отверстия.
func blood_hit(p: Vector2, dir: Vector2, big: bool) -> void:
	blood_burst(p, dir, 16 if big else 5, 160.0 if big else 110.0, 0.32)


## Слоистый выплеск: тяжёлые капли, мелкая взвесь и входной брызг. Общий пул.
func blood_impact(p: Vector2, dir: Vector2, force: float, fan: bool, near: bool, rng: RandomNumberGenerator, recipe: Dictionary = {}) -> void:
	var frame := Engine.get_process_frames()
	if frame != _blood_frame:
		_blood_frame = frame
		_blood_in_frame = 0
	var volume := lerpf(0.28, 1.0, clampf(gore_multiplier, 0.0, 1.0))
	var amount: float = recipe.get("volume", 1.0)
	var wanted := clampi(roundi(lerpf(12.0, 25.0, force) * amount * volume), 4, 96) if near else clampi(roundi(7.0 * amount * volume), 3, 20)
	var budget := mini(wanted, mini(maxi(0, int(_blood_tokens)), maxi(0, 240 - _blood_in_frame)))
	if near:
		# Ближний удар сохраняет вход, выход и тяжёлую каплю даже после дальнего потока.
		budget = maxi(budget, mini(wanted, 8 if force > 0.7 else 4))
	_blood_tokens = maxf(0.0, _blood_tokens - budget)
	_blood_in_frame += budget
	var cone: float = recipe.get("cone", 0.65 if fan else 0.3)
	var through: bool = recipe.get("through", force > 0.7)
	for k in budget:
		var reverse := k == budget - 1 and budget >= 6
		var out := (-dir if reverse else dir).rotated(rng.randf_range(-cone, cone))
		# Визуальная дальность задачи: 80 ед./м. В ближней полосе сгущаемся у раны.
		var u := rng.randf()
		var distance := lerpf(0.5, 80.0, pow(rng.randf(), 2.2)) if u < 0.70 else rng.randf_range(80.0, 160.0) if u < 0.92 else rng.randf_range(160.0, 240.0)
		if reverse:
			distance = rng.randf_range(0.5, 3.0)
		elif not through:
			distance *= 0.6
		var heavy := distance > 80.0
		var size := (rng.randf_range(3.5, 6.0) if heavy else rng.randf_range(2.5, 4.5)) * clampf(sqrt(amount), 0.8, 1.8)
		var life := rng.randf_range(0.16, 0.3) + distance * 0.0015
		var drag := 2.0
		# Интеграл экспоненциального торможения задаёт нужную дальность.
		var speed := distance * drag / (1.0 - exp(-drag * life))
		var i := _n if _n < MAX_PARTICLES else rng.randi_range(0, MAX_PARTICLES - 1)
		if _n < MAX_PARTICLES:
			_n += 1
		_pos[i] = recipe.get("entry", p) if reverse else p
		_vel[i] = out * speed
		_life[i] = life
		_drag[i] = drag
		_size[i] = size * lerpf(0.7, 1.0, volume)
		_col[i] = BLOOD_DARK.lerp(BLOOD, rng.randf_range(0.35, 1.0))
		_bake[i] = 3 if heavy else 1
		_drop_at[i] = _pos[i]
	if near and budget >= 3:
		# Облачко 120 мс, без аддитивного смешивания и без свечения.
		for k in 2:
			var i := emit(p + dir * float(k * 3), dir.rotated(rng.randf_range(-0.32, 0.32)) * 20.0, 0.12, Color(BLOOD, 0.18 * volume), 6.0 + force * 3.0, 4.0)
			if i >= 0:
				_bake[i] = 2


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
	for i in _fire_pos.size():
		var r := (16.0 + _fire_scale[i] * 12.0)
		var pulse := (0.85 + sin(_fx_time * 17.0 + i * 7.3) * 0.15) * minf(1.0, _fire_life[i] * 3.0)
		_glow_layer.draw_texture_rect(_glow_tex, Rect2(_fire_pos[i] - Vector2(r, r * 0.65), Vector2(r * 2.0, r * 1.3)), false, Color(0.18, 0.045, 0.006, 1) * pulse)
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
	var any := not _fire_pos.is_empty()
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


var _weapon_arcs: Array[Array] = []
var _weapon_flames: Array[Array] = []
var _weapon_layer: Node2D
var _fx_time := 0.0
var _fx_rng := RandomNumberGenerator.new()
var _ground_layer: Node2D
var _jet_layer: Node2D
var _ground_mat: ShaderMaterial
var _jet_mat: ShaderMaterial
var _fuel_drop_at := 0.0
var _soot_tex: Texture2D
var _fire_pos := PackedVector2Array()
var _fire_life := PackedFloat32Array()
var _fire_scale := PackedFloat32Array()
var _cut_pos := PackedVector2Array()
var _cut_dir := PackedVector2Array()
var _cut_life := PackedFloat32Array()
var _bolt_pos := PackedVector2Array()
var _bolt_dir := PackedVector2Array()
var _bolt_life := PackedFloat32Array()


func clear_weapon_fx() -> void:
	_weapon_arcs.clear()
	_weapon_flames.clear()
	_fire_pos.clear()
	_fire_life.clear()
	_fire_scale.clear()
	_cut_pos.clear()
	_cut_dir.clear()
	_cut_life.clear()
	_bolt_pos.clear()
	_bolt_dir.clear()
	_bolt_life.clear()
	_weapon_layer.queue_redraw()
	_ground_layer.queue_redraw()
	_jet_layer.queue_redraw()


## Смесь догорает без урона: баланс остаётся у Weapons/Horde.
func burning_patch(at: Vector2, duration := 3.0, size := 0.5) -> void:
	for i in _fire_pos.size():
		if _fire_pos[i].distance_squared_to(at) < 64.0:
			_fire_life[i] = maxf(_fire_life[i], duration)
			return
	if _fire_pos.size() >= 64:
		return
	_fire_pos.append(at)
	_fire_life.append(duration)
	_fire_scale.append(size)


func ground_bolt(at: Vector2, dir: Vector2) -> void:
	if _bolt_pos.size() >= 64:
		_bolt_pos.remove_at(0)
		_bolt_dir.remove_at(0)
		_bolt_life.remove_at(0)
	_bolt_pos.append(at)
	_bolt_dir.append(dir)
	_bolt_life.append(12.0)


func saw_contact(at: Vector2, dir: Vector2) -> void:
	if _cut_pos.size() < 16:
		_cut_pos.append(at)
		_cut_dir.append(dir)
		_cut_life.append(0.23)
	blood_burst(at, dir, 8, 135.0, 0.30, _fx_rng)
	for k in 3:
		var out := dir.rotated(_fx_rng.randf_range(-0.65, 0.65))
		emit(at, out * _fx_rng.randf_range(45.0, 130.0), 0.25, Color("a88372") if k == 0 else Color("651b19"), 0.7, 3.0, true)
	if _fx_rng.randf() < 0.3:
		emit(at, dir.rotated(-0.7) * 90.0, 0.18, Color("f1ce8b"), 0.5, 1.0)


func weapon_sector(at: Vector2, dir: Vector2, reach: float, angle: float, saw: bool) -> void:
	if not saw:
		flash_light(at + dir * reach * 0.5, Color(1.0, 0.36, 0.07), reach * 0.75, 0.7, 0.16)
		if _fx_time >= _fuel_drop_at:
			_fuel_drop_at = _fx_time + 0.08
			emit(at + dir * reach * 0.8 - Vector2(0, 5), Vector2(3, 28), 0.20, Color("f8aa32"), 0.65, 0.2)
		burning_patch(at + dir * reach * _fx_rng.randf_range(0.65, 1.0) + dir.orthogonal() * _fx_rng.randf_range(-6.0, 6.0))
		emit(at + dir * reach * 0.8, Vector2(-4.0, -18.0), 0.65, Color(0.18, 0.16, 0.13, 0.5), 3.0, 1.0)
		for flame: Array in _weapon_flames:
			if Vector2(flame[0]).distance_squared_to(at) < 16.0:
				flame[0] = at
				flame[1] = dir
				flame[4] = 0.19
				_jet_layer.queue_redraw()
				return
		if _weapon_flames.size() >= 4: _weapon_flames.pop_front()
		_weapon_flames.append([at, dir, reach, angle, 0.19])
		_jet_layer.queue_redraw()
		return


func weapon_arc(from: Vector2, to: Vector2) -> void:
	if _weapon_arcs.size() >= 64: _weapon_arcs.pop_front()
	_weapon_arcs.append([from, to, 0.22])
	flash_light(to, Color(0.67, 0.76, 0.86), 16.0, 0.5, 0.045)
	emit(to, Vector2(0, -12), 0.55, Color(0.20, 0.21, 0.20, 0.6), 2.3, 1.0)
	for k in 2:
		emit(to, Vector2.from_angle(_fx_rng.randf() * TAU) * 38.0, 0.2, Color("d6d9bf"), 0.5, 2.0)
	_weapon_layer.queue_redraw()


func _physics_process(delta: float) -> void:
	_fx_time += delta
	_ground_mat.set_shader_parameter("fx_time", _fx_time)
	_jet_mat.set_shader_parameter("fx_time", _fx_time)
	if not _fire_pos.is_empty(): _ground_layer.queue_redraw()
	if not _weapon_flames.is_empty(): _jet_layer.queue_redraw()
	if not _fire_pos.is_empty() or not _cut_pos.is_empty(): _weapon_layer.queue_redraw()
	for j in range(_fire_pos.size() - 1, -1, -1):
		_fire_life[j] -= delta
		if _fire_life[j] <= 0.0:
			if floor_decals:
				if _soot_tex == null: _soot_tex = PixelArt.tex("fx_scorch_0")
				floor_decals.scorch(_soot_tex, _fire_pos[j], 0.0, _fire_scale[j] * 0.16)
			_fire_pos.remove_at(j)
			_fire_life.remove_at(j)
			_fire_scale.remove_at(j)
			_ground_layer.queue_redraw()
	for j in range(_cut_pos.size() - 1, -1, -1):
		_cut_life[j] -= delta
		if _cut_life[j] <= 0.0:
			_cut_pos.remove_at(j)
			_cut_dir.remove_at(j)
			_cut_life.remove_at(j)
	for j in range(_bolt_pos.size() - 1, -1, -1):
		_bolt_life[j] -= delta
		if _bolt_life[j] <= 0.0:
			_bolt_pos.remove_at(j)
			_bolt_dir.remove_at(j)
			_bolt_life.remove_at(j)
	if not _fire_pos.is_empty() or not _cut_pos.is_empty(): _weapon_layer.queue_redraw()
	if not _weapon_flames.is_empty() or not _weapon_arcs.is_empty():
		_weapon_layer.queue_redraw()
	for j in range(_weapon_flames.size() - 1, -1, -1):
		_weapon_flames[j][4] -= delta
		if _weapon_flames[j][4] <= 0.0: _weapon_flames.remove_at(j)
	for j in range(_weapon_arcs.size() - 1, -1, -1):
		_weapon_arcs[j][2] -= delta
		if _weapon_arcs[j][2] <= 0.0: _weapon_arcs.remove_at(j)
	_blood_tokens = minf(300.0, _blood_tokens + delta * 3000.0)
	_update_casings(delta)
	_update_lights(delta)
	var i := _n - 1
	while i >= 0:
		var step := minf(delta, _life[i])
		var attenuation := exp(-_drag[i] * step)
		_pos[i] += _vel[i] * ((1.0 - attenuation) / _drag[i] if _drag[i] > 0.0 else step)
		_vel[i] *= attenuation
		_life[i] -= delta
		if _life[i] <= 0.0:
			if (_bake[i] == 1 or _bake[i] == 3) and floor_decals:
				floor_decals.stamp_dot(_pos[i], _size[i], _col[i])
				if _bake[i] == 3:
					floor_decals.smear(_pos[i] - _vel[i].normalized() * _size[i] * 2.0, _pos[i], _size[i] * 0.6, 0.55)
				if _col[i].g < _col[i].r * 0.5:
					floor_decals.land_drop(_pos[i], _size[i])
			_n -= 1
			_bake[i] = _bake[_n]
			_pos[i] = _pos[_n]
			_vel[i] = _vel[_n]
			_life[i] = _life[_n]
			_drag[i] = _drag[_n]
			_size[i] = _size[_n]
			_col[i] = _col[_n]
			_drop_at[i] = _drop_at[_n]
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


func _draw_ground_fire() -> void:
	for i in _fire_pos.size():
		var size := Vector2(26, 18) * _fire_scale[i]
		var at := _fire_pos[i] - Vector2(size.x * 0.5, size.y * 0.83)
		var phase := fposmod(_fire_pos[i].x * 0.137 + _fire_pos[i].y * 0.317, 1.0)
		_ground_layer.draw_rect(Rect2(at, size), Color(phase, 1, 1, minf(1.0, _fire_life[i] * 3.0)))


func _draw_flame_jets() -> void:
	for flame: Array in _weapon_flames:
		var origin: Vector2 = flame[0]
		var dir: Vector2 = flame[1]
		var reach: float = flame[2]
		var width := maxf(10.0, tan(deg_to_rad(float(flame[3]) * 0.5)) * reach * 0.95)
		var fade := minf(1.0, float(flame[4]) / 0.06)
		_jet_layer.draw_set_transform(origin, dir.angle())
		_jet_layer.draw_rect(Rect2(0, -width, reach, width * 2.0), Color(1, 1, 1, fade))
	_jet_layer.draw_set_transform(Vector2.ZERO)


func _draw_weapon_fx() -> void:
	for arc: Array in _weapon_arcs:
		var a: Vector2 = arc[0]
		var b: Vector2 = arc[1]
		var side := (b - a).normalized().orthogonal()
		var fade := minf(1.0, float(arc[2]) / 0.07)
		var phase := floorf(_fx_time * 60.0) + a.x * 0.31
		var points := PackedVector2Array([a])
		var segments := clampi(ceili(a.distance_to(b) / 6.0), 5, 32)
		for j in range(1, segments):
			var offset := sin(float(j) * 19.73 + phase * 2.41) * 4.5 + cos(float(j) * 7.1 + phase) * 2.0
			points.append(a.lerp(b, float(j) / segments) + side * offset)
		points.append(b)
		_weapon_layer.draw_polyline(points, Color(0.48, 0.60, 0.73, 0.28 * fade), 3.2)
		_weapon_layer.draw_polyline(points, Color(0.91, 0.95, 0.93, fade), 1.1)
		for j in range(2, segments, 4):
			var tip := points[j] + (b - a).normalized() * 8.0 + side * sin(phase + j * 3.1) * 15.0
			_weapon_layer.draw_polyline(PackedVector2Array([points[j], points[j].lerp(tip, 0.5) - side * 2.0, tip]), Color(0.73, 0.83, 0.87, 0.7 * fade), 0.8)
		PixelArt.draw_dot(_weapon_layer, b, 2.0 * fade, Color(0.94, 0.94, 0.80, fade))
	for i in _cut_pos.size():
		var age := 0.23 - _cut_life[i]
		var dir := _cut_dir[i]
		for k in 4:
			var out := dir.rotated(sin(float(k) * 7.3 + float(i)) * 0.35)
			var p := _cut_pos[i] + out * age * (100.0 + k * 17.0) + Vector2(0, age * age * 90.0)
			_weapon_layer.draw_line(p - out * (2.0 + k), p, Color(0.37 + k * 0.025, 0.025, 0.022, minf(1.0, _cut_life[i] * 15.0)), 0.8 + k * 0.15)


func _draw() -> void:
	var view := PixelArt.view_rect(self, 24.0)
	for i in _bolt_pos.size():
		var p := _bolt_pos[i]
		var dir := _bolt_dir[i]
		draw_line(p - dir * 9.0, p, Color("75674b"), 0.65)
		draw_line(p - dir * 9.0, p - dir * 7.0 + dir.orthogonal() * 1.4, Color("b9b8a2"), 0.65)
	for k in _blood_lines.size():
		_blood_lines[k].clear()
	# Неровный край самой маски лужи, поверх крови, ниже живых. Без ореола.
	if _hazards:
		for art in _acid_rims.size():
			var tex := _acid_rims[art]
			if not tex:
				continue
			for j in _hazards._pool_count:
				var p := _hazards._pool_pos[j]
				if _hazards._pool_art[j] != art or not view.has_point(p):
					continue
				var scale_factor := _hazards._pool_radius[j] * 2.0 / tex.get_width()
				var fade := clampf(_hazards._pool_life[j] / Hazards.FADE_TIME, 0.0, 1.0)
				draw_set_transform(p, _hazards._pool_rot[j], Vector2.ONE * scale_factor)
				draw_texture(tex, -tex.get_size() * 0.5, Color(1, 1, 1, fade))
		draw_set_transform(Vector2.ZERO)
	var dot := PixelArt.dot()
	for i in _n:
		if not view.has_point(_pos[i]):
			continue # вне экрана не рисуем
		var c := _col[i]
		if _bake[i] == 0:
			c.a *= clampf(_life[i] / 0.5, 0.0, 1.0) # затухание в последние полсекунды
		var s := _size[i]
		if _bake[i] == 2:
			var fade := clampf(_life[i] / 0.12, 0.0, 1.0)
			c.a *= fade * fade
			var r := s * lerpf(1.4, 0.7, fade)
			draw_texture_rect(dot, Rect2(_pos[i] - Vector2.ONE * r, Vector2.ONE * r * 2.0), false, c)
		elif _bake[i] == 4:
			c.a *= clampf(_life[i] / 0.08, 0.0, 1.0)
			draw_line(_pos[i], _pos[i] - _vel[i] * 0.035, c, maxf(0.35, s))
		elif _bake[i] == 3:
			var length := clampf(_vel[i].length() * 0.018, s * 0.7, s * 2.3)
			draw_set_transform(_pos[i], _vel[i].angle())
			draw_texture_rect(dot, Rect2(-length, -s * 0.4, length * 1.5, s * 0.8), false, c)
			PixelArt.draw_dot(self, Vector2(-length * 0.25, -s * 0.18), s * 0.22, Color(0.10, 0.002, 0.003, 0.6))
			draw_set_transform(Vector2.ZERO)
		elif _bake[i] == 1:
			# летящая капля вытягивается вдоль скорости; упавшая — круглая
			var v := _vel[i] * 0.025
			if c.g < c.r * 0.5:
				# Восемь пакетов вместо сотен отдельных draw_line; кислота остаётся зелёной.
				var bucket := clampi(int(c.r * 20.0), 0, 3) + (4 if s > 1.5 else 0)
				if v.length_squared() < 0.25:
					v = Vector2(0.2, 0.0)
				_blood_lines[bucket].append(_pos[i] - v)
				_blood_lines[bucket].append(_pos[i])
			elif v.length_squared() > 0.25:
				draw_line(_pos[i] - v, _pos[i], c, s * 0.55)
			else:
				var r := s * 0.35
				draw_texture_rect(dot, Rect2(_pos[i].x - r, _pos[i].y - r, r * 2.0, r * 2.0), false, c)
		else:
			draw_rect(Rect2(_pos[i].x - s * 0.3, _pos[i].y - s * 0.3, s * 0.6, s * 0.6), c)
	for k in _blood_lines.size():
		if not _blood_lines[k].is_empty():
			draw_multiline(_blood_lines[k], BLOOD_INK[k % 4], 1.1 if k >= 4 else 0.55)
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
