class_name BossBase
extends Node2D
## Общий протокол босса: жизнь, фазы, попадания и наземные предупреждения.

signal phase_changed(phase: int)
signal died(pos: Vector2)
signal charge_telegraph(from: Vector2, to: Vector2, time: float)
signal slam_started(pos: Vector2)
signal roar(count: int)
signal crushed(pos: Vector2, dir: Vector2)
signal armor_plate(pos: Vector2, dir: Vector2)

var horde: Horde
var player: Player
var obstacles: Obstacles
var effects: Effects
var floor_decals: FloorDecals
var camera: GameCamera
var arena: Rect2
var minutes := 0.0
var hp := 24000.0
var max_hp := 24000.0
var armor_threshold := 0.5
var phase := 1
var _alive := false
var _flash := 0.0


func body_radius() -> float:
	return 18.0


## Радиус для стен и пути. У мягких тел (Мясная гора) меньше радиуса попаданий — протискивается по улицам.
func move_radius() -> float:
	return body_radius()


## ZAI6 (З5): ходьба в обход домов. Путь крупного тела (Obstacles.big_path) пересчитывается раз в 0,4 с или когда
## цель ушла на 32 px; без пути (замкнут, нет препятствий) — по прямой, как раньше. Возвращает точку шага.
var _path := PackedVector2Array()
var _path_goal := Vector2.INF
var _path_cd := 0.0
var _path_found := true


func _walk_point(target: Vector2, step: float, delta: float) -> Vector2:
	var from := global_position
	if obstacles == null:
		return from.move_toward(target, step)
	var r := move_radius()
	_path_cd -= delta
	if _path_cd <= 0.0 or _path_goal.distance_to(target) > 32.0:
		_path_goal = target
		_path = obstacles.big_path(from, target, r)
		_path_found = obstacles.big_found
		# Цель недостижима — путь к ближайшей достижимой клетке; повторный поиск реже (он дорогой).
		_path_cd = 0.4 if _path_found else 2.0
		if OS.get_cmdline_user_args().has("--boss-debug"):
			print("BOSSPATH from=%s to=%s r=%.0f points=%d expanded=%d found=%s" % [from.round(), target.round(), r, _path.size(), obstacles.big_expanded, _path_found])
	if _path.is_empty():
		return from.move_toward(target, step)
	# Промежуточные точки снимаем, когда дошли или видна следующая. Последняя — цель (идём к игроку сейчас)
	# или, если цель недостижима, ближайшая к ней клетка.
	while _path.size() > 1 and (from.distance_to(_path[0]) < 4.0 or obstacles.big_clear(from, _path[1], r)):
		_path.remove_at(0)
	return from.move_toward(target if _path.size() == 1 and _path_found else _path[0], step)


## Таран и бросок — по прямой: начинаются, только если на отрезке нет дома или забора (машины ломаются).
func _ram_open(to: Vector2) -> bool:
	return obstacles == null or obstacles.ram_clear(global_position, to, move_radius())


func display_name() -> String:
	return "Объект-7"


func is_alive() -> bool:
	return _alive


func hit_test(p: Vector2, r: float) -> bool:
	return _alive and p.distance_squared_to(global_position) <= pow(body_radius() + maxf(r, 0.0), 2.0)


func _lose_hp(amount: float) -> bool:
	hp = maxf(hp - amount, 0.0)
	_flash = 0.08
	if hp > 0.0:
		return false
	_alive = false
	visible = false
	died.emit(global_position)
	return true


func _set_phase(value: int) -> void:
	if value == phase:
		return
	phase = value
	phase_changed.emit(phase)


func _warn_ground(at: Vector2, radius: float, progress: float, rotten: bool = false) -> void:
	var p := to_local(at)
	var edge := Color("baa58c") if rotten else Color("d1a899")
	var contour := _ground_patch(p, radius, Color(0.035, 0.018, 0.018, 0.75))
	draw_polyline(contour, Color(edge, 0.9), 0.8)
	# Неровные ветвящиеся трещины сходятся к месту выхода, без текста.
	var cracks := PackedVector2Array()
	var branches := PackedVector2Array()
	for k in 5:
		var dir := Vector2.from_angle(float(k) * TAU / 5.0 + 0.3)
		var a := p + dir * radius
		var b := p + dir * radius * (0.88 - clampf(progress, 0.0, 1.0) * 0.65)
		var elbow := a.lerp(b, 0.55) + dir.orthogonal() * (3.0 if k % 2 == 0 else -3.0)
		cracks.append_array(PackedVector2Array([a, elbow, elbow, b]))
		branches.append_array(PackedVector2Array([elbow, elbow + dir.orthogonal() * 5.0 - dir * 3.0]))
	draw_multiline(cracks, edge.darkened(0.25), 1.2)
	draw_multiline(branches, edge.darkened(0.4), 0.8)


func _ground_patch(at: Vector2, radius: float, color: Color, squash: float = 1.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for k in 32:
		var angle := float(k) * TAU / 32.0
		var reach := radius * (1.0 + 0.04 * sin(float(k) * 2.3))
		points.append(at + Vector2(cos(angle), sin(angle) * squash) * reach)
	draw_colored_polygon(points, color)
	points.append(points[0])
	return points
