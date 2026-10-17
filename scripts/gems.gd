class_name Gems
extends Node2D
## Образцы (опыт): падают с трупов, лежат и мерцают; в радиусе подбора летят к бойцу.
## Если на карте слишком много, новые вливаются в ближайшие — те «растут» (1 → 5 → 25).
## Тот же узел с art = "credit" — жетоны кредитов (подбираются так же).

signal collected(value: int)

const MERGE_ABOVE := 250
const MERGE_RADIUS := 28.0
const PULL_SPEED := 240.0
const COLLECT_DIST := 6.0

@export var art := "xp" # спрайты art/<art>_0..2.png
@export var glow := Color(0.35, 1.0, 0.55)

var player: Player
var radius := 32.0 # радиус подбора (растёт от пассивки)

var count := 0
var spawned_total := 0 # статистика для симуляции
var collected_total := 0
var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _val := PackedInt32Array()
var _pulled := PackedByteArray()
var _phase := PackedFloat32Array()
var _tex: Array[Texture2D] = []
var _time := 0.0


func _ready() -> void:
	for t in 3:
		_tex.append(PixelArt.tex("%s_%d" % [art, t]))


func spawn(p: Vector2, value: int) -> void:
	spawned_total += value
	if count > MERGE_ABOVE:
		# слияние с ближайшим образцом
		var best := -1
		var best_d := MERGE_RADIUS * MERGE_RADIUS
		for i in count:
			var d := _pos[i].distance_squared_to(p)
			if d < best_d:
				best_d = d
				best = i
		if best != -1:
			_val[best] += value
			return
	_pos.append(p)
	_vel.append(Vector2.from_angle(randf() * TAU) * randf_range(10.0, 40.0)) # «выпадает» из трупа
	_val.append(value)
	_pulled.append(0)
	_phase.append(randf() * TAU)
	count += 1


## Ближайший образец (для автопилота симуляции) или Vector2.INF.
func nearest(p: Vector2, max_dist: float) -> Vector2:
	var best := Vector2.INF
	var best_d := max_dist * max_dist
	for i in count:
		var d := _pos[i].distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = _pos[i]
	return best


func _physics_process(delta: float) -> void:
	_time += delta
	if player == null:
		return
	var pp := player.global_position
	var r2 := radius * radius
	var i := count - 1
	while i >= 0:
		var p := _pos[i]
		var to := pp - p
		var d2 := to.length_squared()
		if _pulled[i] == 0 and d2 < r2 and not player.is_dead:
			_pulled[i] = 1
		if _pulled[i] == 1:
			var dist := sqrt(d2)
			if dist < COLLECT_DIST:
				collected_total += _val[i]
				collected.emit(_val[i])
				_remove(i)
				i -= 1
				continue
			_vel[i] = _vel[i].move_toward(to / maxf(dist, 0.01) * PULL_SPEED, 900.0 * delta)
		else:
			_vel[i] = _vel[i] * exp(-6.0 * delta)
		_pos[i] = p + _vel[i] * delta
		i -= 1
	queue_redraw()


func _remove(i: int) -> void:
	count -= 1
	_pos[i] = _pos[count]
	_vel[i] = _vel[count]
	_val[i] = _val[count]
	_pulled[i] = _pulled[count]
	_phase[i] = _phase[count]
	_pos.resize(count)
	_vel.resize(count)
	_val.resize(count)
	_pulled.resize(count)
	_phase.resize(count)


func _draw() -> void:
	var k := PixelArt.ART_SCALE
	var view := PixelArt.view_rect(self)
	for i in count:
		if not view.has_point(_pos[i]):
			continue # вне экрана не рисуем
		var v := _val[i]
		var tier := 0 if v < 5 else (1 if v < 25 else 2)
		var tex := _tex[tier]
		var pulse := 0.5 + 0.5 * sin(_time * 4.0 + _phase[i])
		# свечение под кристаллом
		PixelArt.draw_dot(self, _pos[i], 3.0 + tier * 1.5, Color(glow, 0.12 + 0.1 * pulse))
		var bob := Vector2(0, -0.6 * pulse)
		draw_set_transform(_pos[i] + bob, 0.0, Vector2(k, k))
		draw_texture(tex, -tex.get_size() * 0.5, Color(1, 1, 1).lerp(Color(1.3, 1.3, 1.3), pulse * 0.4))
	draw_set_transform(Vector2.ZERO)
