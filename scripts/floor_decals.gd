class_name FloorDecals
extends Node2D
## Пол как «холст бойни». Два постоянных слоя, которые никогда не очищаются:
##
## 1. Слой крови хранит не цвет, а ТОЛЩИНУ (R) и СВЕЖЕСТЬ (G). Штампы складываются
##    аддитивно — лужи сливаются, в центре кровь гуще. Шейдер blood.gdshader
##    раскрашивает толщину: тонкий край — полупрозрачный алый, густое — почти
##    чёрно-бордовое, на свежем — влажный блик и тёмный ободок. Раз в секунду
##    свежесть всего слоя умножается на коэффициент — кровь буреет и тускнеет.
## 2. Слой декалей: трупы, гибы, пепел, лёд — обычные цветные спрайты.
##
## Оба слоя — SubViewport размером с арену × плотность арта. В кадре, когда есть
## новые штампы, рисуются только они и ложатся поверх старого.
## Сетка мокроты на CPU помнит, где недавно пролилась кровь, — по ней оставляют следы.

const DRY_INTERVAL := 1.0 # сек между проходами высыхания
const DRY_FACTOR := 0.965 # свежесть ×0.965 в секунду → бурая примерно за минуту
const POOL_STEPS := 7 # из скольких слоёв растекается лужа
const POOL_TIME := 2.4 # сек, за которые лужа растекается
const WET_CELL := 8.0
const WET_WINDOW := 30.0 # сколько секунд по пятну можно наследить

var stamps_last_frame := 0
var stamps_total := 0
var time := 0.0
var gore_multiplier := 1.0

var _origin := Vector2.ZERO
var _vp: SubViewport
var _canvas: Node2D
var _blood_vp: SubViewport
var _blood_canvas: Node2D
var _dry_node: Node2D
var _dry_t := 0.0
var _dry_now := false

# цветные штампы: [текстура, позиция, поворот, масштаб, цвет]
var _stamps: Array = []
# кровь: [0, текстура, позиция, поворот, масштаб, толщина] | [1, позиция, радиус, толщина]
#        | [2, от, до, ширина, толщина]
var _blood: Array = []

# растекающиеся лужи
var _pool_tex: Array[Texture2D] = []
var _pool_pos := PackedVector2Array()
var _pool_rot := PackedFloat32Array()
var _pool_scale := PackedFloat32Array()
var _pool_age := PackedFloat32Array()
var _pool_step := PackedInt32Array()

var _grid_w := 0
var _grid_h := 0
var _wet_time := PackedFloat32Array()

var _print_tex: Texture2D


func setup(rect: Rect2) -> void:
	process_priority = 100 # после всех, кто штампует в этом кадре
	_origin = rect.position

	# слой крови (под декалями)
	_blood_vp = _make_viewport(rect)
	_blood_canvas = Node2D.new()
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_blood_canvas.material = add_mat
	_blood_canvas.draw.connect(_on_blood_draw)
	_blood_vp.add_child(_blood_canvas)
	_dry_node = Node2D.new()
	var mul_mat := CanvasItemMaterial.new()
	mul_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	_dry_node.material = mul_mat
	_dry_node.draw.connect(_on_dry_draw)
	_blood_vp.add_child(_dry_node)
	var blood_view := _make_view(_blood_vp, rect)
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = preload("res://shaders/blood.gdshader")
	blood_view.material = shader_mat

	# слой декалей
	_vp = _make_viewport(rect)
	_canvas = Node2D.new()
	_canvas.draw.connect(_on_canvas_draw)
	_vp.add_child(_canvas)
	_make_view(_vp, rect)

	_grid_w = ceili(rect.size.x / WET_CELL)
	_grid_h = ceili(rect.size.y / WET_CELL)
	_wet_time.resize(_grid_w * _grid_h)
	_wet_time.fill(-1000.0)
	_print_tex = PixelArt.tex("footprint")


func _make_viewport(rect: Rect2) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(rect.size * PixelArt.ART_DENSITY) # плотность как у спрайтов
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	vp.canvas_transform = Transform2D.IDENTITY.scaled(Vector2.ONE * PixelArt.ART_DENSITY) # только после входа в дерево
	return vp


func _make_view(vp: SubViewport, rect: Rect2) -> Sprite2D:
	var view := Sprite2D.new()
	view.texture = vp.get_texture()
	view.centered = false
	view.position = rect.position
	view.scale = Vector2.ONE * PixelArt.ART_SCALE
	add_child(view)
	return view


# --- цветные декали ---------------------------------------------------------------

## Сразу в слой декалей (трупы, гибы, пепел, лёд).
func stamp(tex: Texture2D, pos: Vector2, rot: float, color: Color, scale_factor := 1.0) -> void:
	_stamps.append([tex, pos - _origin, rot, scale_factor * PixelArt.ART_SCALE, color])


# --- кровь -------------------------------------------------------------------------------

## Пятно крови по маске толщины (белое — густо).
func blood(tex: Texture2D, pos: Vector2, rot: float, scale_factor := 1.0, thickness := 0.6) -> void:
	if gore_multiplier < 1.0 and randf() > gore_multiplier:
		return
	_blood.append([0, tex, pos - _origin, rot, scale_factor * PixelArt.ART_SCALE, thickness])
	mark_wet(pos, tex.get_size().x * 0.35 * scale_factor * PixelArt.ART_SCALE)


## Капля.
func stamp_dot(pos: Vector2, size: float, _color := Color.WHITE) -> void:
	if gore_multiplier < 1.0 and randf() > gore_multiplier:
		return
	_blood.append([1, pos - _origin, size * 0.45, 0.55])


## Сплошной мазок от a до b — след волочащегося тела или куска.
func smear(a: Vector2, b: Vector2, width: float, thickness := 0.35) -> void:
	if gore_multiplier < 1.0 and randf() > gore_multiplier:
		return
	_blood.append([2, a - _origin, b - _origin, width, thickness])


## След ноги: отпечаток подошвы, повёрнутый по направлению шага.
func stamp_print(pos: Vector2, angle: float, strength: float) -> void:
	if gore_multiplier < 1.0 and randf() > gore_multiplier:
		return
	_blood.append([0, _print_tex, pos - _origin, angle, PixelArt.ART_SCALE, 0.4 * strength])


## Лужа, которая растекается: несколько растущих слоёв, центр получается гуще краёв.
func pool(tex: Texture2D, pos: Vector2, rot: float, scale_factor := 1.0) -> void:
	if gore_multiplier < 1.0 and randf() > gore_multiplier:
		return
	_pool_tex.append(tex)
	_pool_pos.append(pos)
	_pool_rot.append(rot)
	_pool_scale.append(scale_factor)
	_pool_age.append(0.0)
	_pool_step.append(0)


func mark_wet(pos: Vector2, radius: float) -> void:
	var p := pos - _origin
	var r := ceili(radius / WET_CELL)
	var cx := int(p.x / WET_CELL)
	var cy := int(p.y / WET_CELL)
	for y in range(maxi(cy - r, 0), mini(cy + r + 1, _grid_h)):
		for x in range(maxi(cx - r, 0), mini(cx + r + 1, _grid_w)):
			_wet_time[x + y * _grid_w] = time


func is_wet(pos: Vector2) -> bool:
	var p := pos - _origin
	var x := int(p.x / WET_CELL)
	var y := int(p.y / WET_CELL)
	if x < 0 or y < 0 or x >= _grid_w or y >= _grid_h:
		return false
	return time - _wet_time[x + y * _grid_w] < WET_WINDOW


func pool_count() -> int:
	return _pool_tex.size()


func _process(delta: float) -> void:
	time += delta
	_grow_pools(delta)
	_dry_t += delta
	if _dry_t >= DRY_INTERVAL:
		_dry_t = 0.0
		_dry_now = true

	stamps_last_frame = _stamps.size() + _blood.size()
	if not _stamps.is_empty():
		_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		_canvas.queue_redraw()
	if not _blood.is_empty() or _dry_now:
		# оба узла перерисовываем всегда: иначе их прошлые команды повторятся в этом кадре
		_blood_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		_blood_canvas.queue_redraw()
		_dry_node.queue_redraw()


func _grow_pools(delta: float) -> void:
	var i := _pool_tex.size() - 1
	while i >= 0:
		_pool_age[i] += delta
		# слои ложатся всё шире, быстрее в начале
		while _pool_step[i] < POOL_STEPS and _pool_age[i] >= POOL_TIME * pow(float(_pool_step[i]) / POOL_STEPS, 1.6):
			var t := float(_pool_step[i] + 1) / POOL_STEPS
			blood(_pool_tex[i], _pool_pos[i], _pool_rot[i], _pool_scale[i] * lerpf(0.35, 1.0, t), 0.2)
			_pool_step[i] += 1
		if _pool_step[i] >= POOL_STEPS:
			_pool_tex.remove_at(i)
			_pool_pos.remove_at(i)
			_pool_rot.remove_at(i)
			_pool_scale.remove_at(i)
			_pool_age.remove_at(i)
			_pool_step.remove_at(i)
		i -= 1


func _on_blood_draw() -> void:
	var dot := PixelArt.dot()
	for s: Array in _blood:
		var thick: float = s[s.size() - 1]
		var c := Color(thick, 1.0, 0.0, 1.0) # R — толщина, G — свежесть
		match s[0]:
			0:
				var tex: Texture2D = s[1]
				var k: float = s[4]
				_blood_canvas.draw_set_transform(s[2], s[3], Vector2(k, k))
				_blood_canvas.draw_texture(tex, -tex.get_size() * 0.5, c)
			1:
				var r: float = s[2]
				_blood_canvas.draw_set_transform(Vector2.ZERO)
				_blood_canvas.draw_texture_rect(dot, Rect2(s[1] - Vector2(r, r), Vector2(r, r) * 2.0), false, c)
			2:
				var a: Vector2 = s[1]
				var b: Vector2 = s[2]
				var w: float = s[3]
				var len := a.distance_to(b)
				_blood_canvas.draw_set_transform(a, (b - a).angle())
				_blood_canvas.draw_texture_rect(dot, Rect2(-w * 0.5, -w * 0.5, len + w, w), false, c)
	_blood_canvas.draw_set_transform(Vector2.ZERO)
	stamps_total += _blood.size()
	_blood.clear()


func _on_dry_draw() -> void:
	if not _dry_now:
		return
	_dry_now = false
	# умножаем только свежесть (G); толщина и альфа не меняются
	_dry_node.draw_rect(Rect2(Vector2.ZERO, Vector2(_blood_vp.size) / PixelArt.ART_DENSITY), Color(1.0, DRY_FACTOR, 1.0, 1.0))


func _on_canvas_draw() -> void:
	for s: Array in _stamps:
		var tex: Texture2D = s[0]
		var k: float = s[3]
		_canvas.draw_set_transform(s[1], s[2], Vector2(k, k))
		_canvas.draw_texture(tex, -tex.get_size() * 0.5, s[4])
	_canvas.draw_set_transform(Vector2.ZERO)
	stamps_total += _stamps.size()
	_stamps.clear()
