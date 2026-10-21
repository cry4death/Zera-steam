extends Control
## Кровь на «объективе»: капли от близких взрывов, медленно стекают и тают.
## Плюс красная виньетка при низком HP (GDD §8).

const MAX_DROPS := 60

var low_hp := 0.0 # 0..1, насколько близко к смерти
var gore_multiplier := 1.0

var _pos := PackedVector2Array()
var _start_y := PackedFloat32Array()
var _r := PackedFloat32Array()
var _speed := PackedFloat32Array()
var _life := PackedFloat32Array()
var _max_life := PackedFloat32Array()
var _seed := PackedFloat32Array()
var _time := 0.0


## strength 0..1; from — направление события на экране (капли кучнее с той стороны).
func splash(strength: float, from := Vector2.ZERO) -> void:
	if not Meta.settings["screen_blood"]:
		return
	var n := roundi((4 + strength * 10) * gore_multiplier)
	var view := size / _ui() # рисуем в «игровых» пикселях, как HUD
	var center := view * 0.5 + from * view * 0.3
	for k in n:
		if _pos.size() >= MAX_DROPS:
			_remove(0)
		var p := center + Vector2(randf_range(-0.5, 0.5) * view.x, randf_range(-0.5, 0.5) * view.y) * randf_range(0.2, 1.0)
		_pos.append(p)
		_start_y.append(p.y)
		_r.append(randf_range(1.0, 2.2 + strength * 2.0))
		_seed.append(randf() * 100.0)
		_speed.append(randf_range(2.0, 10.0))
		var life := randf_range(1.8, 3.5)
		_life.append(life)
		_max_life.append(life)


func _process(delta: float) -> void:
	if not Meta.settings["screen_blood"]:
		while not _pos.is_empty():
			_remove(_pos.size() - 1)
	_time += delta
	var i := _pos.size() - 1
	while i >= 0:
		_life[i] -= delta
		if _life[i] <= 0.0:
			_remove(i)
		else:
			var p := _pos[i]
			p.y += _speed[i] * delta
			_pos[i] = p
			_speed[i] *= exp(-0.4 * delta)
		i -= 1
	queue_redraw()


func _ui() -> float:
	return maxf(1.0, roundf(size.y / 360.0))


func _remove(i: int) -> void:
	_pos.remove_at(i)
	_start_y.remove_at(i)
	_r.remove_at(i)
	_speed.remove_at(i)
	_life.remove_at(i)
	_max_life.remove_at(i)
	_seed.remove_at(i)


func _draw() -> void:
	var ui := _ui()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(ui, ui))
	for i in _pos.size():
		var a := clampf(_life[i] / (_max_life[i] * 0.5), 0.0, 1.0) * 0.7
		var c := Color(0.24, 0.01, 0.01, a)
		var p := _pos[i]
		var r := _r[i]
		var sd := _seed[i]
		# потёк: сужается от места попадания к капле
		var top := _start_y[i]
		if p.y - top > 1.0:
			draw_line(Vector2(p.x, top), p, Color(c, a * 0.55), r * 0.45)
		# клякса из нескольких кругов разного размера + брызги вокруг
		for k in 4:
			var ang := sd * 3.7 + k * 1.9
			var off := Vector2(cos(ang), sin(ang)) * r * (0.35 + 0.25 * fmod(sd * (k + 1.3), 1.0))
			PixelArt.draw_dot(self, p + off, r * (0.55 + 0.3 * fmod(sd * (k + 2.1), 1.0)), c)
		for k in 3:
			var ang := sd * 5.1 + k * 2.3
			PixelArt.draw_dot(self, p + Vector2(cos(ang), sin(ang)) * r * 1.8, r * 0.18, c)
	if low_hp > 0.0:
		# виньетка пульсирует, как сердцебиение
		var pulse := 1.0 if not Meta.settings["screen_flashes"] else 0.75 + 0.25 * pow(maxf(sin(_time * 7.0), 0.0), 4.0)
		var a := low_hp * 0.5 * pulse
		var w := size.x / ui
		var h := size.y / ui
		for k in 6:
			var t := k / 6.0
			var inset := t * 40.0
			var col := Color(0.4, 0.0, 0.0, a * (1.0 - t) * 0.4)
			draw_rect(Rect2(0, inset, w, 7), col)
			draw_rect(Rect2(0, h - inset - 7, w, 7), col)
			draw_rect(Rect2(inset, 0, 7, h), col)
			draw_rect(Rect2(w - inset - 7, 0, 7, h), col)
