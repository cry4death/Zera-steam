class_name Pickups
extends Node2D
## Предметы на полу: аптечка, оружейный ящик, редкая деталь и кровавый контейнер.
## Лежат, покачиваются, подбираются касанием (не магнитом). Обычные исчезают через 40 с
## с миганием в последние 5 с, контейнер лежит, пока его не возьмут. Без нод на предмет.

signal collected(kind: int, pos: Vector2)

enum Kind { MEDKIT, CRATE, PART, CONTAINER }

const TEXTURES := ["medkit", "weapon_crate", "rare_part", "blood_container"]
const GLOWS := [Color(0.4, 1.0, 0.5), Color(1.0, 0.72, 0.3), Color(0.4, 0.7, 1.0), Color(1.0, 0.2, 0.15)]
const GLOW_RADIUS := [7.0, 8.0, 7.0, 13.0]
const TOUCH_RADIUS := [7.0, 8.0, 7.0, 12.0] # радиус предмета; к нему добавляется Player.RADIUS
const LIFETIME := 40.0
const BLINK_TIME := 5.0
const FALL_TIME := 0.55 # контейнер падает сверху
const FALL_HEIGHT := 90.0
const MAX_ITEMS := 64

var player: Player
var effects: Effects
var floor_decals: FloorDecals
var camera: GameCamera

var count := 0
var _pos := PackedVector2Array()
var _kind := PackedByteArray()
var _life := PackedFloat32Array() # сколько ещё лежит; контейнер не исчезает
var _fall := PackedFloat32Array() # сколько ещё падает (0 — лежит)
var _phase := PackedFloat32Array()
var _tex: Array[Texture2D] = []
var _time := 0.0


func _ready() -> void:
	for n: String in TEXTURES:
		_tex.append(PixelArt.tex(n))


## Кладёт предмет в точку p. Контейнер сначала падает с «неба» и приземляется с тряской.
func spawn(p: Vector2, kind: int) -> void:
	if count >= MAX_ITEMS:
		# место кончилось: убираем самый старый обычный предмет
		for i in count:
			if _kind[i] != Kind.CONTAINER:
				_remove(i)
				break
		if count >= MAX_ITEMS:
			return
	_pos.append(p)
	_kind.append(kind)
	_life.append(INF if kind == Kind.CONTAINER else LIFETIME)
	_fall.append(FALL_TIME if kind == Kind.CONTAINER else 0.0)
	_phase.append(randf() * TAU)
	count += 1


## Ближайший предмет (кроме аптечек) для автопилота симуляции или Vector2.INF.
func nearest(p: Vector2, max_dist: float) -> Vector2:
	var best := Vector2.INF
	var best_d := max_dist * max_dist
	for i in count:
		var d := _pos[i].distance_squared_to(p)
		if _kind[i] != Kind.MEDKIT and _fall[i] <= 0.0 and d < best_d:
			best_d = d
			best = _pos[i]
	return best


func count_of(kind: int) -> int:
	var n := 0
	for i in count:
		if _kind[i] == kind:
			n += 1
	return n


func _physics_process(delta: float) -> void:
	_time += delta
	var i := count - 1
	while i >= 0:
		if _fall[i] > 0.0:
			_fall[i] -= delta
			if _fall[i] <= 0.0:
				_fall[i] = 0.0
				_land(_pos[i])
			i -= 1
			continue
		_life[i] -= delta
		if _life[i] <= 0.0:
			_remove(i)
			i -= 1
			continue
		if player != null and not player.is_dead and _touched(i):
			var k := _kind[i]
			var at := _pos[i]
			_remove(i)
			collected.emit(k, at)
		i -= 1
	queue_redraw()


func _touched(i: int) -> bool:
	var k := _kind[i]
	if k == Kind.MEDKIT and player.hp >= player.max_hp:
		return false # здоровому аптечка не нужна — пусть лежит
	var r: float = Player.RADIUS + TOUCH_RADIUS[k]
	return _pos[i].distance_squared_to(player.global_position) <= r * r


## Приземление контейнера: тряска, пыль, брызги и лужа вокруг.
func _land(p: Vector2) -> void:
	if camera:
		camera.shake(6.0)
	if effects:
		for k in 8:
			effects.blood_burst(p, Vector2.from_angle(TAU * k / 8.0 + randf() * 0.4), 8, 170.0, 0.5)
		for k in 10:
			effects.emit(p, Vector2.from_angle(randf() * TAU) * randf_range(20.0, 70.0), randf_range(0.4, 0.8),
				Color(0.45, 0.42, 0.4, 0.5), 3.0, 4.0)
	if floor_decals:
		floor_decals.pool(PixelArt.tex("blood_%d" % (randi() % 8)), p, randf() * TAU, 2.0)


func _remove(i: int) -> void:
	count -= 1
	_pos[i] = _pos[count]
	_kind[i] = _kind[count]
	_life[i] = _life[count]
	_fall[i] = _fall[count]
	_phase[i] = _phase[count]
	_pos.resize(count)
	_kind.resize(count)
	_life.resize(count)
	_fall.resize(count)
	_phase.resize(count)


func _draw() -> void:
	var k := PixelArt.ART_SCALE
	for i in count:
		draw_set_transform(Vector2.ZERO) # после прошлого предмета остался масштаб
		var kind := _kind[i]
		var tex := _tex[kind]
		var p := _pos[i]
		var pulse := 0.5 + 0.5 * sin(_time * 4.0 + _phase[i])
		if _fall[i] > 0.0:
			# падение: тень растёт, предмет снижается
			var f := _fall[i] / FALL_TIME
			PixelArt.draw_dot(self, p, GLOW_RADIUS[kind] * (1.0 - f * 0.6), Color(0, 0, 0, 0.45 * (1.0 - f)))
			draw_set_transform(p + Vector2(0.0, -FALL_HEIGHT * f * f), 0.0, Vector2(k, k))
			draw_texture(tex, -tex.get_size() * 0.5)
			continue
		if _life[i] < BLINK_TIME and int(_life[i] * 8.0) % 2 == 0:
			continue # мигание перед исчезновением
		# тень и свечение: на кровавом полу предмет должен читаться издалека
		PixelArt.draw_dot(self, p + Vector2(0.0, 2.0), TOUCH_RADIUS[kind] * 0.8, Color(0, 0, 0, 0.35))
		PixelArt.draw_dot(self, p, GLOW_RADIUS[kind] * (1.0 + 0.15 * pulse), Color(GLOWS[kind], 0.25 + 0.15 * pulse))
		var bob := Vector2(0.0, -0.8 * pulse - 1.0)
		var tilt := 0.0 if kind == Kind.CONTAINER else sin(_time * 2.0 + _phase[i]) * 0.1
		draw_set_transform(p + bob, tilt, Vector2(k, k))
		draw_texture(tex, -tex.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO)
