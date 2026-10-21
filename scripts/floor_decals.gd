class_name FloorDecals
extends Node2D
signal blood_landed(pos: Vector2, size: float)
## Пол как «холст бойни». Два постоянных слоя, которые никогда не очищаются:
##
## 1. Слой крови хранит ТОЛЩИНУ (R), СВЕЖЕСТЬ (G) и снятый подошвой слой (B).
##    Штампы смешиваются по маске — лужи сливаются без общего насыщения. Шейдер blood.gdshader
##    раскрашивает толщину: тонкий край — тёмно-бордовый, густое — почти
##    чёрно-бордовое, на свежем — влажный блик и тёмный ободок. Раз в секунду
##    свежесть всего слоя умножается на коэффициент — кровь буреет и тускнеет.
## 2. Слой декалей: гильзы, магазины, следы кислоты. Останки и пепел живут в Gore.
##
## Кровь — арена × BLOOD_DENSITY, декали — × FLOOR_DENSITY. В кадре, когда есть
## новые штампы, рисуются только они и ложатся поверх старого.
## Сетка мокроты на CPU помнит, где недавно пролилась кровь, — по ней оставляют следы.

const DRY_INTERVAL := 1.0 # сек между проходами высыхания
const DRY_FACTOR := 0.90 # влажный блик уходит за десятки секунд
const FLOOR_DENSITY := 2.0 # кровь и мелкий мусор не требуют детализации персонажей
const BLOOD_DENSITY := 1.0 # разливы крупные; для накопления достаточно пикселя на единицу
const MAX_STAMPS := 512
const MAX_POOLS := 128
const POOL_STEPS := 7 # из скольких слоёв растекается лужа
const POOL_TIME := 4.8 # сек, за которые лужа растекается
const WET_CELL := 8.0
const WET_WINDOW := 30.0 # сколько секунд по пятну можно наследить

var stamps_last_frame := 0
var stamps_total := 0
var remains_baked := 0
var remains_occluded := 0
var time := 0.0
var gore_multiplier := 1.0

var _origin := Vector2.ZERO
var _vp: SubViewport
var _canvas: Node2D
var _remains_canvas: Node2D
var _remains_stamps: Array[Array] = []
var _remains_cover := PackedByteArray()
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
var _pool_masks: Array[Texture2D] = []

var _grid_w := 0
var _grid_h := 0
var _wet_time := PackedFloat32Array()
var _coverage := PackedFloat32Array()
var _coverage_time := PackedFloat32Array()

var _print_tex: Texture2D
var _scorch_layer: Node2D
var _scorches: Array = []
var _scorch_cursor := 0
var _landings: Dictionary = {}
var _player: Player
var _player_at := Vector2.INF
var _player_stride := 0.0
var _player_feet := 0
var _player_side := 1.0
var hive_material: ShaderMaterial


## Попадания в поверхности объединяются по ячейкам, не по каждому пикселю следа.
func land_drop(pos: Vector2, size: float) -> void:
	if size < 1.5 or gore_multiplier < 0.3:
		return
	var cell := Vector2i(pos / 8.0)
	if _landings.has(cell):
		var drop: Vector3 = _landings[cell]
		drop.z = minf(8.0, drop.z + size * 0.5)
		_landings[cell] = drop
	elif _landings.size() < 24:
		_landings[cell] = Vector3(pos.x, pos.y, maxf(size, 2.0))


func setup(rect: Rect2) -> void:
	process_priority = 100 # после всех, кто штампует в этом кадре
	_origin = rect.position
	_player = get_parent().get_node_or_null("Player") as Player
	# Подпалины отдельным ограниченным пакетом под кровью, без третьего viewport.
	_scorch_layer = Node2D.new()
	_scorch_layer.draw.connect(_draw_scorches)
	add_child(_scorch_layer)

	# слой крови (под декалями)
	_blood_vp = _make_viewport(rect, BLOOD_DENSITY)
	_blood_canvas = Node2D.new()
	# Новая порция обновляет местную толщину, а не забивает весь RT до единицы.
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://shaders/blood.gdshader")
	paint.set_shader_parameter("depositing", true)
	paint.set_shader_parameter("relief", PixelArt.tex("blood_relief_r1d"))
	paint.set_shader_parameter("relief_scale", Vector2.ONE / (768.0 * BLOOD_DENSITY))
	_blood_canvas.material = paint
	_blood_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_blood_canvas.draw.connect(_on_blood_draw)
	_blood_vp.add_child(_blood_canvas)
	_dry_node = Node2D.new()
	var mul_mat := CanvasItemMaterial.new()
	mul_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	_dry_node.material = mul_mat
	_dry_node.draw.connect(_on_dry_draw)
	_blood_vp.add_child(_dry_node)
	var blood_view := _make_view(_blood_vp, rect, BLOOD_DENSITY)
	blood_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = preload("res://shaders/blood.gdshader")
	blood_view.material = shader_mat

	# слой декалей
	_vp = _make_viewport(rect)
	_remains_canvas = Node2D.new()
	var remains_mat := ShaderMaterial.new()
	remains_mat.shader = preload("res://shaders/flash.gdshader")
	remains_mat.set_shader_parameter("debris_mode", true)
	_remains_canvas.material = remains_mat
	_remains_canvas.draw.connect(_on_remains_draw)
	_vp.add_child(_remains_canvas)
	_canvas = Node2D.new()
	_canvas.draw.connect(_on_canvas_draw)
	_vp.add_child(_canvas)
	_make_view(_vp, rect)

	_grid_w = ceili(rect.size.x / WET_CELL)
	_grid_h = ceili(rect.size.y / WET_CELL)
	_wet_time.resize(_grid_w * _grid_h)
	_wet_time.fill(-1000.0)
	_coverage.resize(_grid_w * _grid_h)
	_coverage_time.resize(_grid_w * _grid_h)
	_remains_cover.resize(_grid_w * _grid_h)
	_print_tex = PixelArt.tex("footprint")
	for k in 16:
		_pool_masks.append(PixelArt.tex("blood_pool_r1e_%d" % k))


## Один повторяемый слой под кровью; не создаёт дополнительного viewport.
func infect_hive(rect: Rect2) -> void:
	var tissue := Sprite2D.new()
	tissue.texture = PixelArt.tex("hive_floor")
	tissue.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	tissue.region_enabled = true
	tissue.region_rect = Rect2(Vector2.ZERO, rect.size * PixelArt.ART_DENSITY)
	tissue.position = rect.get_center()
	tissue.scale = Vector2.ONE * PixelArt.ART_SCALE
	tissue.z_index = -1
	var pulse := ShaderMaterial.new()
	pulse.shader = preload("res://shaders/hive_floor.gdshader")
	tissue.material = pulse
	hive_material = pulse
	add_child(tissue)


func _make_viewport(rect: Rect2, density := FLOOR_DENSITY) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(rect.size * density)
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	vp.canvas_transform = Transform2D.IDENTITY.scaled(Vector2.ONE * density)
	return vp


func _make_view(vp: SubViewport, rect: Rect2, density := FLOOR_DENSITY) -> Sprite2D:
	var view := Sprite2D.new()
	view.texture = vp.get_texture()
	view.centered = false
	view.position = rect.position
	view.scale = Vector2.ONE / density
	add_child(view)
	return view


# --- цветные декали ---------------------------------------------------------------

## Сразу в слой мелких декалей, без тел и частей зомби.
func stamp(tex: Texture2D, pos: Vector2, rot: float, color: Color, scale_factor := 1.0) -> void:
	if _stamps.size() >= MAX_STAMPS:
		return
	_stamps.append([tex, pos - _origin, rot, scale_factor * PixelArt.ART_SCALE, color])


## Старые тела и органы остаются в существующем RT, без спрайта на каждый кусок.
func bake_remains(tex: Texture2D, pos: Vector2, rot: float, shape: Vector2, tint: Color) -> bool:
	if _remains_stamps.size() >= MAX_STAMPS:
		return false
	# В плотной куче нижние останки скрыты целым верхним силуэтом, а не крошат его.
	# Сетка конечна по площади арены; ни RT, ни список предметов не растут.
	var cell := Vector2i((pos - _origin) / WET_CELL)
	var body := tex.get_width() >= 40 and tex.get_height() >= 28
	var radius := 2 if body else 1
	for y in range(maxi(0, cell.y - radius), mini(_grid_h, cell.y + radius + 1)):
		for x in range(maxi(0, cell.x - radius), mini(_grid_w, cell.x + radius + 1)):
			var cover := _remains_cover[x + y * _grid_w]
			if cover == 2 or (not body and cover == 1):
				remains_baked += 1
				remains_occluded += 1
				return true
	if cell.x >= 0 and cell.y >= 0 and cell.x < _grid_w and cell.y < _grid_h:
		_remains_cover[cell.x + cell.y * _grid_w] = 2 if body else 1
	_remains_stamps.append([tex, pos - _origin, rot, shape * PixelArt.ART_SCALE, tint])
	remains_baked += 1
	return true


func scorch(tex: Texture2D, pos: Vector2, rot: float, scale_factor: float) -> void:
	var stamp_data := [tex, pos, rot, scale_factor * PixelArt.ART_SCALE]
	if _scorches.size() < 256:
		_scorches.append(stamp_data)
	else:
		_scorches[_scorch_cursor] = stamp_data
		_scorch_cursor = (_scorch_cursor + 1) % 256
	_scorch_layer.queue_redraw()


func _draw_scorches() -> void:
	# Три текстуры рисуются группами: старые подпалины не дробят пакет.
	for variant_index in 3:
		for s: Array in _scorches:
			var tex: Texture2D = s[0]
			if not tex.resource_path.ends_with("_%d.png" % variant_index):
				continue
			_scorch_layer.draw_set_transform(s[1], s[2], Vector2.ONE * float(s[3]))
			_scorch_layer.draw_texture(tex, -tex.get_size() * 0.5)
	_scorch_layer.draw_set_transform(Vector2.ZERO)


# --- кровь -------------------------------------------------------------------------------

## Пятно крови по маске толщины (белое — густо).
func blood(tex: Texture2D, pos: Vector2, rot: float, scale_factor := 1.0, thickness := 0.6) -> void:
	if not _allow_blood(pos):
		return
	if gore_multiplier < 1.0 and randf() > gore_multiplier:
		return
	_blood.append([0, tex, pos - _origin, rot, scale_factor * PixelArt.ART_SCALE, thickness])
	mark_wet(pos, tex.get_size().x * 0.35 * scale_factor * PixelArt.ART_SCALE)


## Капля.
func stamp_dot(pos: Vector2, size: float, _color := Color.WHITE) -> void:
	if not _allow_blood(pos):
		return
	if gore_multiplier < 1.0 and randf() > gore_multiplier:
		return
	_blood.append([1, pos - _origin, size * 0.65, 0.65])
	if size >= 2.0:
		mark_wet(pos, size)


## Сплошной мазок от a до b — след волочащегося тела или куска.
func smear(a: Vector2, b: Vector2, width: float, thickness := 0.35) -> void:
	if not _allow_blood(b):
		return
	if gore_multiplier < 1.0 and randf() > gore_multiplier:
		return
	_blood.append([2, a - _origin, b - _origin, width, thickness])


## След ноги: отпечаток подошвы, повёрнутый по направлению шага.
func stamp_print(pos: Vector2, angle: float, strength: float) -> void:
	if not _allow_blood(pos):
		return
	if gore_multiplier < 1.0 and randf() > gore_multiplier:
		return
	_blood.append([3, _print_tex, pos - _origin, angle, PixelArt.ART_SCALE * 1.15, 0.7 * strength])


## Лужа, которая растекается: несколько растущих слоёв, центр получается гуще краёв.
func pool(tex: Texture2D, pos: Vector2, rot: float, scale_factor := 1.0) -> void:
	if _pool_tex.size() >= MAX_POOLS:
		return
	if gore_multiplier < 1.0 and randf() > gore_multiplier:
		return
	# Маска разлива крупнее брызг; выбор не расходует боевой RNG.
	_pool_tex.append(_pool_masks[absi(roundi(pos.x * 3.0 + pos.y)) % _pool_masks.size()] if not _pool_masks.is_empty() else tex)
	_pool_pos.append(pos)
	_pool_rot.append(rot)
	_pool_scale.append(scale_factor)
	_pool_age.append(0.0)
	_pool_step.append(0)


## Повторные слои в одной ячейке насыщаются; запас возвращается со временем.
func _allow_blood(pos: Vector2) -> bool:
	if _blood.size() >= MAX_STAMPS:
		return false
	var p := Vector2i((pos - _origin) / WET_CELL)
	if p.x < 0 or p.y < 0 or p.x >= _grid_w or p.y >= _grid_h:
		return false
	var i := p.x + p.y * _grid_w
	_coverage[i] = maxf(0.0, _coverage[i] - (time - _coverage_time[i]) * 3.0)
	_coverage_time[i] = time
	if _coverage[i] >= 8.0:
		return false
	_coverage[i] += 1.0
	return true


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
	_player_steps()
	for drop: Vector3 in _landings.values():
		blood_landed.emit(Vector2(drop.x, drop.y), drop.z)
	_landings.clear()
	_grow_pools(delta)
	_dry_t += delta
	if _dry_t >= DRY_INTERVAL:
		_dry_t = 0.0
		_dry_now = true

	stamps_last_frame = _stamps.size() + _blood.size()
	if not _stamps.is_empty() or not _remains_stamps.is_empty():
		_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		_canvas.queue_redraw()
		_remains_canvas.queue_redraw()
	if not _blood.is_empty() or _dry_now:
		# оба узла перерисовываем всегда: иначе их прошлые команды повторятся в этом кадре
		_blood_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		_blood_canvas.queue_redraw()
		_dry_node.queue_redraw()


## Следы бойца: только пройденное расстояние, остановка не рисует новые отпечатки.
func _player_steps() -> void:
	if not is_instance_valid(_player) or _player.is_dead:
		return
	var at := _player.position
	if not _player_at.is_finite() or at.distance_squared_to(_player_at) > 1024.0:
		_player_at = at
		_player_stride = 0.0
		return
	var movement := at - _player_at
	_player_at = at
	if movement.length_squared() < 0.01:
		return
	if is_wet(at):
		_player_feet = 10
	_player_stride += movement.length()
	if _player_stride >= 7.0:
		_player_stride = fmod(_player_stride, 7.0)
		if _player_feet > 0:
			stamp_print(at + movement.normalized().orthogonal() * _player_side * 1.8, movement.angle(), _player_feet / 10.0)
			_player_side = -_player_side
			_player_feet -= 1


func _grow_pools(delta: float) -> void:
	var i := _pool_tex.size() - 1
	while i >= 0:
		_pool_age[i] += delta
		# слои ложатся всё шире, быстрее в начале
		while _pool_step[i] < POOL_STEPS and _pool_age[i] >= POOL_TIME * pow(float(_pool_step[i]) / POOL_STEPS, 1.6):
			var t := float(_pool_step[i] + 1) / POOL_STEPS
			var flow := Vector2.from_angle(_pool_rot[i]) * (t * t * 12.0)
			blood(_pool_tex[i], _pool_pos[i] + flow, _pool_rot[i], _pool_scale[i] * lerpf(0.45, 1.15, t), 0.24)
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
		var c := Color(thick, 1.0, 1.0 if s[0] == 3 else 0.45 if s[0] == 2 else 0.0, 1.0)
		match s[0]:
			0, 3:
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
	# Высыхает только влажность; пигмент остаётся в том же ограниченном RT.
	_dry_node.draw_rect(Rect2(Vector2.ZERO, Vector2(_blood_vp.size) / BLOOD_DENSITY), Color(1.0, DRY_FACTOR, 1.0, 1.0))


func _on_canvas_draw() -> void:
	for s: Array in _stamps:
		var tex: Texture2D = s[0]
		var k: float = s[3]
		_canvas.draw_set_transform(s[1], s[2], Vector2(k, k))
		_canvas.draw_texture(tex, -tex.get_size() * 0.5, s[4])
	_canvas.draw_set_transform(Vector2.ZERO)
	stamps_total += _stamps.size()
	_stamps.clear()


func _on_remains_draw() -> void:
	for s: Array in _remains_stamps:
		var tex: Texture2D = s[0]
		_remains_canvas.draw_set_transform(s[1], s[2], s[3])
		_remains_canvas.draw_texture(tex, -tex.get_size() * 0.5, s[4])
	_remains_canvas.draw_set_transform(Vector2.ZERO)
	stamps_total += _remains_stamps.size()
	_remains_stamps.clear()
