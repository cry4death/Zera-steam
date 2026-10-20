class_name Explosions
extends Node2D
## Только изображение взрыва. Урон и смерти остаются у вызывающей системы.
## Один узел, фиксированные Packed-пулы, один проход каждого слоя, без нод на частицы.

enum Kind { GRENADE, LAUNCHER, FAT, DETONATOR, BOSS, CAR }
enum Layer { FIRE, SMOKE, DUST, DEBRIS, FLASH }
const START := [0, 24, 120, 248, 568]
const LIMIT := [24, 96, 128, 320, 24]
const CAPACITY := 592
const FIRE_CELLS := [96.0, 144.0, 192.0]

var floor_decals: FloorDecals
var effects: Effects
var camera: GameCamera
var player: Player
var horde: Horde
# Громкость взрыва для орды по виду (граната, гранатомёт, толстяк, детонатор, босс, машина), px.
const NOISE := [900.0, 800.0, 400.0, 500.0, 0.0, 1100.0]
var spawned := 0
var last_at := Vector2.INF
var replaced := 0
var peak := 0
var update_worst_usec := 0
var draw_worst_usec := 0

var _active := PackedByteArray()
var _scorch_pending := PackedByteArray()
var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _age := PackedFloat32Array()
var _life := PackedFloat32Array()
var _size := PackedFloat32Array()
var _rot := PackedFloat32Array()
var _spin := PackedFloat32Array()
var _height := PackedFloat32Array()
var _art := PackedInt32Array()
var _variant := PackedInt32Array()
var _color := PackedColorArray()
var _cursor := PackedInt32Array([0, 0, 0, 0, 0])
var _fire: Array[Texture2D] = []
var _debris_atlas: Texture2D
var _scorch: Array[Texture2D] = []
var _smoke: Texture2D
var _rng := RandomNumberGenerator.new()
var _flash := RID()
var _add_material: CanvasItemMaterial


func _ready() -> void:
	_active.resize(CAPACITY)
	_scorch_pending.resize(CAPACITY)
	_pos.resize(CAPACITY)
	_vel.resize(CAPACITY)
	_age.resize(CAPACITY)
	_life.resize(CAPACITY)
	_size.resize(CAPACITY)
	_rot.resize(CAPACITY)
	_spin.resize(CAPACITY)
	_height.resize(CAPACITY)
	_art.resize(CAPACITY)
	_variant.resize(CAPACITY)
	_color.resize(CAPACITY)
	for name: String in ["small", "medium", "large"]:
		_fire.append(PixelArt.tex("fx_explosion_" + name))
	_smoke = PixelArt.tex("fx_smoke")
	_debris_atlas = PixelArt.tex("fx_debris_atlas")
	for i in 3:
		_scorch.append(PixelArt.tex("fx_scorch_%d" % i))
	# Аддитивная вспышка — постоянный RID, а не дополнительный узел на взрыв.
	_flash = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(_flash, get_canvas_item())
	_add_material = CanvasItemMaterial.new()
	_add_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	RenderingServer.canvas_item_set_material(_flash, _add_material.get_rid())
	_rng.seed = 81073
	set_process(false)


func _exit_tree() -> void:
	if _flash.is_valid():
		RenderingServer.free_rid(_flash)
		_flash = RID()


## radius — радиус урона в мировых единицах, kind — Kind. Звук остаётся у владельца.
func spawn(at: Vector2, radius: float, kind: int) -> void:
	if radius <= 0.0 or not at.is_finite():
		return
	radius = clampf(radius, 8.0, 320.0)
	kind = clampi(kind, Kind.GRENADE, Kind.CAR)
	last_at = at
	spawned += 1
	if horde and NOISE[kind] > 0.0:
		horde.noise(at, NOISE[kind], 3.0 if kind != Kind.FAT else 1.5)
	var r := radius * (0.80 if kind == Kind.DETONATOR else 1.0)
	var primary := _burst(at, r, kind, 0.0)
	_scorch_pending[primary] = 1
	if kind == Kind.BOSS:
		# Вторичные выбросы раскрываются последовательно, а не одним белым диском.
		for j in 4:
			var offset := Vector2.from_angle(float(j) * 2.4 + 0.3) * r * _rng.randf_range(0.22, 0.40)
			_burst(at + offset, r * 0.48, Kind.LAUNCHER, 0.13 + float(j) * 0.11)
	if effects:
		effects.flash_light(at, Color(1.0, 0.53, 0.21), r * 2.5, 1.6, 0.12)
		if kind == Kind.FAT:
			effects.blood_burst(at, Vector2.RIGHT, 32, 170.0, PI)
	if camera and player:
		var distance := at.distance_to(player.global_position)
		camera.shake(minf(14.0, r * 0.065) * clampf(1.0 - distance / maxf(300.0, r * 4.0), 0.0, 1.0))
	set_process(true)
	queue_redraw()


func _burst(at: Vector2, r: float, kind: int, delay: float) -> int:
	var variant := _rng.randi_range(0, 2)
	var art := 0 if r < 40.0 else (1 if r < 100.0 else 2)
	var i := _add(Layer.FIRE, at, Vector2.ZERO, 0.68, r * 2.4, delay)
	var primary := i
	_art[i] = art
	_variant[i] = variant
	_rot[i] = _rng.randf_range(-0.22, 0.22)
	if kind == Kind.FAT:
		_color[i] = Color(0.80, 0.83, 0.46)
	i = _add(Layer.FLASH, at, Vector2.ZERO, 0.045, r * 1.6, delay)
	_art[i] = art
	_variant[i] = variant
	for j in (3 if kind == Kind.DETONATOR else 6):
		var dir := Vector2.from_angle(_rng.randf_range(0.0, TAU))
		i = _add(Layer.SMOKE, at + dir * r * 0.18, dir * _rng.randf_range(5.0, 15.0) + Vector2(-3, -12), _rng.randf_range(1.8, 2.8), r * _rng.randf_range(0.85, 1.25), delay + _rng.randf_range(0.10, 0.24))
		_color[i] = Color(0.73, 0.83, 0.43, 0.82) if kind == Kind.FAT else Color(0.80, 0.79, 0.77, 0.83)
	for j in 8:
		# Разрозненные низкие клубы: фронт давления без геометрического кольца.
		var dir := Vector2.from_angle(float(j) * TAU / 8.0 + _rng.randf_range(-0.30, 0.30))
		i = _add(Layer.DUST, at + dir * r * 0.12, dir * r * _rng.randf_range(1.6, 2.7), _rng.randf_range(0.35, 0.65), r * _rng.randf_range(0.5, 0.85), delay + 0.025)
		_color[i] = Color(2.0, 1.80, 1.40, 0.38)
	for j in (28 if kind == Kind.CAR else clampi(roundi(r / 7.0) + 8, 8, 20)):
		var dir := Vector2.from_angle(_rng.randf_range(0.0, TAU))
		i = _add(Layer.DEBRIS, at + dir * r * 0.09, dir * _rng.randf_range(45.0, 130.0) * sqrt(r / 60.0), _rng.randf_range(0.6, 1.25), _rng.randf_range(2.2, 4.2), delay)
		_art[i] = _rng.randi_range(3, 5) if kind == Kind.CAR else (6 if j % 3 == 0 else _rng.randi_range(0, 5))
		_height[i] = _rng.randf_range(65.0, 130.0)
		_rot[i] = dir.angle()
		_spin[i] = _rng.randf_range(-12.0, 12.0)
	return primary


func _add(layer: int, at: Vector2, velocity: Vector2, life: float, size_px: float, delay: float) -> int:
	var first: int = START[layer]
	var capacity: int = LIMIT[layer]
	var slot := -1
	var worst := -INF
	var listener := to_local(player.global_position) if player else Vector2.ZERO
	for offset in capacity:
		var j := first + (_cursor[layer] + offset) % capacity
		if _active[j] == 0:
			slot = j
			break
		var score := _age[j] / _life[j]
		if player:
			score += _pos[j].distance_squared_to(listener) / 2000000.0
		if score > worst:
			worst = score
			slot = j
	if _active[slot] != 0:
		replaced += 1
	_cursor[layer] = (slot - first + 1) % capacity
	_active[slot] = 1
	_scorch_pending[slot] = 0
	_pos[slot] = to_local(at)
	_vel[slot] = velocity
	_age[slot] = -delay
	_life[slot] = life
	_size[slot] = size_px
	_rot[slot] = 0.0
	_spin[slot] = 0.0
	_height[slot] = 0.0
	_art[slot] = 0
	_variant[slot] = 0
	_color[slot] = Color.WHITE
	return slot


func active_count() -> int:
	return _active.count(1)


func layer_count(layer: int) -> int:
	var result := 0
	for i in range(START[layer], START[layer] + LIMIT[layer]):
		result += _active[i]
	return result


func clear() -> void:
	_active.fill(0)
	_cursor.fill(0)
	set_process(false)
	queue_redraw()
	RenderingServer.canvas_item_clear(_flash)


func _process(delta: float) -> void:
	advance(delta)


## Отдельный шаг позволяет снимать точные 0.05/0.15/0.4/1.5 с при любом FPS.
func advance(delta: float) -> void:
	var start := Time.get_ticks_usec()
	var alive := 0
	for i in CAPACITY:
		if _active[i] == 0:
			continue
		_age[i] += delta
		if _scorch_pending[i] == 1 and _age[i] >= 0.16:
			_scorch_pending[i] = 0
			if floor_decals:
				# Подпалина появляется под раскрытым огнём, а не раньше маленькой вспышки.
				floor_decals.scorch(_scorch[_variant[i]], to_global(_pos[i]), _rot[i], _size[i] / 2.4 * 1.75 / (144.0 * PixelArt.ART_SCALE))
		# Дальние старые клубы быстрее растворяются при насыщенном пуле.
		if i >= START[Layer.SMOKE] and i < START[Layer.DUST] and _age[i] > 0.7 and player and _pos[i].distance_squared_to(to_local(player.global_position)) > 810000.0:
			_age[i] += delta
		if _age[i] >= _life[i]:
			_active[i] = 0
		else:
			alive += 1
	peak = maxi(peak, alive)
	queue_redraw()
	if alive == 0:
		set_process(false)
	update_worst_usec = maxi(update_worst_usec, Time.get_ticks_usec() - start)


func _draw() -> void:
	var start := Time.get_ticks_usec()
	RenderingServer.canvas_item_clear(_flash)
	# Все тени подряд: одна текстура, без переключения «тень / камень» на каждом осколке.
	for i in range(START[Layer.DEBRIS], START[Layer.DEBRIS] + LIMIT[Layer.DEBRIS]):
		if _active[i] == 0 or _age[i] < 0.0 or _art[i] == 6:
			continue
		var age := _age[i]
		var at := _pos[i] + _vel[i] * (1.0 - exp(-age * 1.7)) / 1.7
		var size_px := _size[i]
		draw_texture_rect(PixelArt.dot(), Rect2(at + Vector2(1, 2) - Vector2(size_px, size_px * 0.4) * 0.5, Vector2(size_px, size_px * 0.4)), false, Color(0.01, 0.01, 0.01, 0.35 * (1.0 - age / _life[i])))
	# Пыль у пола, затем дым, огонь и обломки. Текстуры группируются по слою.
	for layer: int in [Layer.DUST, Layer.SMOKE, Layer.FIRE, Layer.DEBRIS, Layer.FLASH]:
		for i in range(START[layer], START[layer] + LIMIT[layer]):
			if _active[i] == 0 or _age[i] < 0.0:
				continue
			var age := _age[i]
			var t := clampf(age / _life[i], 0.0, 1.0)
			var at := _pos[i]
			var size_px := _size[i]
			var color := _color[i]
			var tex: Texture2D
			var source: Rect2
			var rotation := _rot[i]
			if layer == Layer.FIRE or layer == Layer.FLASH:
				tex = _fire[_art[i]]
				var cell: float = FIRE_CELLS[_art[i]]
				var frame := mini(11, int(t * 12.0)) if layer == Layer.FIRE else 0
				source = Rect2(Vector2(frame, _variant[i]) * cell, Vector2.ONE * cell)
				size_px *= lerpf(0.87, 1.10, t)
				at.y -= _size[i] * t * 0.05
				if layer == Layer.FLASH:
					color.a = (1.0 - t) * 0.65
			elif layer == Layer.SMOKE or layer == Layer.DUST:
				tex = _smoke
				source = Rect2(Vector2(mini(7, int(t * 8.0)) * 96, 0), Vector2(96, 96))
				at += _vel[i] * (age if layer == Layer.SMOKE else (1.0 - exp(-age * 4.0)) * 0.25)
				size_px *= lerpf(0.55, 1.50, t)
				color.a *= smoothstep(0.0, 0.14, t) * (1.0 - smoothstep(0.40, 1.0, t))
			else:
				tex = _debris_atlas
				source = Rect2(Vector2(_art[i] * 12, 0), Vector2(12, 12))
				at += _vel[i] * (1.0 - exp(-age * 1.7)) / 1.7
				var height := maxf(0.0, _height[i] * age - 140.0 * age * age)
				at.y -= height
				rotation += age * _spin[i]
				color.a *= 1.0 - smoothstep(0.65, 1.0, t)
			var target := Rect2(-Vector2.ONE * size_px * 0.5, Vector2.ONE * size_px)
			if layer == Layer.DUST:
				target.position.y *= 0.40
				target.size.y *= 0.40
			if layer == Layer.FLASH:
				RenderingServer.canvas_item_add_set_transform(_flash, Transform2D(rotation, at))
				RenderingServer.canvas_item_add_texture_rect_region(_flash, target, tex.get_rid(), source, color)
			else:
				draw_set_transform(at, rotation)
				draw_texture_rect_region(tex, target, source, color)
	draw_set_transform(Vector2.ZERO)
	draw_worst_usec = maxi(draw_worst_usec, Time.get_ticks_usec() - start)
