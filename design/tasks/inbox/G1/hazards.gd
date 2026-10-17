class_name Hazards
extends Node2D
## Плевки, кислотные лужи и отложенные взрывы толстяков без нод на сущность.

const SPIT_SPEED := 140.0
const SPIT_RADIUS := 3.0
const ACID_TICK := 0.5
const POOL_LIMIT := 64
const POOL_LOBES := 7
const FADE_TIME := 0.8
const BLASTS_PER_FRAME := 8
const FLASH_TIME := 0.25
const FLASH_LIMIT := 128 # 8 взрывов × 15 кадров при 60 Гц, с запасом

var horde: Horde
var player: Player
var floor_decals: FloorDecals
var effects: Effects
var camera: GameCamera
var minutes := 0.0

var _shot_count := 0
var _shot_pos := PackedVector2Array()
var _shot_target := PackedVector2Array()
var _shot_dir := PackedVector2Array()
var _shot_damage := PackedFloat32Array()
var _shot_phase := PackedFloat32Array()

var _pool_count := 0
var _pool_pos := PackedVector2Array()
var _pool_radius := PackedFloat32Array()
var _pool_dps := PackedFloat32Array()
var _pool_life := PackedFloat32Array()
var _pool_seed := PackedFloat32Array()
var _pool_rot := PackedFloat32Array()
var _pool_art := PackedByteArray()
var _pool_order := PackedInt64Array()
var _lobe_pos := PackedVector2Array()
var _lobe_radius := PackedFloat32Array()
var _next_pool_order := 0
var _acid_tick := 0.0

# Кольцевая FIFO: снимок количества не включает новые цепные взрывы.
var _queue_pos := PackedVector2Array()
var _queue_elite := PackedByteArray()
var _queue_head := 0
var _queue_count := 0

var _flash_count := 0
var _flash_pos := PackedVector2Array()
var _flash_radius := PackedFloat32Array()
var _flash_age := PackedFloat32Array()

var _spit_tex: Array[Texture2D] = []
var _acid_tex: Array[Texture2D] = []
var _blood_tex: Array[Texture2D] = []
var _time := 0.0
var _generation := 0


func _init() -> void:
	_resize_shots(64)
	_pool_pos.resize(POOL_LIMIT)
	_pool_radius.resize(POOL_LIMIT)
	_pool_dps.resize(POOL_LIMIT)
	_pool_life.resize(POOL_LIMIT)
	_pool_seed.resize(POOL_LIMIT)
	_pool_rot.resize(POOL_LIMIT)
	_pool_art.resize(POOL_LIMIT)
	_pool_order.resize(POOL_LIMIT)
	_lobe_pos.resize(POOL_LIMIT * POOL_LOBES)
	_lobe_radius.resize(POOL_LIMIT * POOL_LOBES)
	_queue_pos.resize(2048)
	_queue_elite.resize(2048)
	_flash_pos.resize(FLASH_LIMIT)
	_flash_radius.resize(FLASH_LIMIT)
	_flash_age.resize(FLASH_LIMIT)
	_spit_tex.resize(3)
	_acid_tex.resize(3)
	_blood_tex.resize(8)


func _ready() -> void:
	for i in 3:
		if ResourceLoader.exists("res://art/spit_%d.png" % i):
			_spit_tex[i] = PixelArt.tex("spit_%d" % i)
		if ResourceLoader.exists("res://art/acid_%d.png" % i):
			_acid_tex[i] = PixelArt.tex("acid_%d" % i)
	for i in 8:
		_blood_tex[i] = PixelArt.tex("blood_%d" % i)


func spit(from: Vector2, to: Vector2, damage: float) -> void:
	if _shot_count == _shot_pos.size():
		_resize_shots(_shot_pos.size() * 2)
	var i := _shot_count
	_shot_count += 1
	_shot_pos[i] = from
	_shot_target[i] = to
	_shot_dir[i] = (to - from).normalized()
	_shot_damage[i] = damage
	_shot_phase[i] = randf() * TAU
	queue_redraw()


func acid_pool(p: Vector2, radius := 20.0, dps := 5.0, duration := 3.0) -> void:
	if radius <= 0.0 or duration <= 0.0:
		return
	if _pool_count == POOL_LIMIT:
		var oldest := 0
		for j in range(1, _pool_count):
			if _pool_order[j] < _pool_order[oldest]:
				oldest = j
		_remove_pool(oldest)
	var i := _pool_count
	_pool_count += 1
	_pool_pos[i] = p
	_pool_radius[i] = radius
	_pool_dps[i] = maxf(dps, 0.0)
	_pool_life[i] = duration
	_pool_seed[i] = randf() * TAU
	_pool_rot[i] = randf() * TAU
	_pool_art[i] = randi() % 3
	_pool_order[i] = _next_pool_order
	_next_pool_order += 1
	for k in POOL_LOBES:
		var slot := i * POOL_LOBES + k
		var a := _pool_seed[i] + float(k) * TAU / float(POOL_LOBES - 1)
		_lobe_pos[slot] = Vector2.ZERO if k == 0 else Vector2.from_angle(a) * radius * randf_range(0.45, 0.57)
		_lobe_radius[slot] = radius * (0.68 if k == 0 else randf_range(0.32, 0.43))
	if floor_decals:
		var tex: Texture2D = _blood_tex[randi() % 8]
		if tex:
			floor_decals.stamp(tex, p, _pool_rot[i], Color(0.16, 0.2, 0.05, 0.35), radius / 30.0)
	queue_redraw()


func fat_explosion(p: Vector2, is_elite: bool) -> void:
	if _queue_count == _queue_pos.size():
		_grow_queue()
	var slot := (_queue_head + _queue_count) % _queue_pos.size()
	_queue_pos[slot] = p
	_queue_elite[slot] = 1 if is_elite else 0
	_queue_count += 1


func clear() -> void:
	var had_visuals := _has_visuals()
	_shot_count = 0
	_pool_count = 0
	_flash_count = 0
	_queue_count = 0
	_queue_head = 0
	_next_pool_order = 0
	_acid_tick = 0.0
	_time = 0.0
	_generation += 1
	if had_visuals:
		queue_redraw() # один пустой кадр удаляет предыдущие команды рисования


func projectile_count() -> int:
	return _shot_count


func pool_count() -> int:
	return _pool_count


func _physics_process(delta: float) -> void:
	var had_visuals := _has_visuals()
	var generation := _generation
	var pending := mini(_queue_count, BLASTS_PER_FRAME)
	_time += delta
	_update_flashes(delta)
	_update_pools(delta)
	if generation != _generation:
		return
	_update_shots(delta)
	if generation != _generation:
		return
	for k in pending:
		var p := _queue_pos[_queue_head]
		var is_elite := _queue_elite[_queue_head] == 1
		_queue_head = (_queue_head + 1) % _queue_pos.size()
		_queue_count -= 1
		_explode(p, is_elite)
		if generation != _generation:
			return
	if had_visuals or _has_visuals():
		queue_redraw()


func _update_shots(delta: float) -> void:
	var generation := _generation
	var i := _shot_count - 1
	while i >= 0:
		var p := _shot_pos[i]
		var target := _shot_target[i]
		var next := p.move_toward(target, SPIT_SPEED * delta)
		if player and not player.is_dead:
			# Проверяем отрезок: крупный шаг физики не пролетает сквозь игрока.
			var step := next - p
			var t := 0.0
			if step.length_squared() > 0.000001:
				t = clampf((player.global_position - p).dot(step) / step.length_squared(), 0.0, 1.0)
			var hit := p + step * t
			if hit.distance_squared_to(player.global_position) <= pow(Player.RADIUS + SPIT_RADIUS, 2.0):
				var damage := _shot_damage[i]
				_remove_shot(i)
				_splash(hit)
				player.take_damage(damage)
				if generation != _generation:
					return
				i -= 1
				continue
		if next == target:
			_remove_shot(i)
			acid_pool(target)
			_splash(target)
		else:
			_shot_pos[i] = next
		i -= 1


func _update_pools(delta: float) -> void:
	_acid_tick = maxf(_acid_tick - delta, 0.0)
	var dps := 0.0
	var i := _pool_count - 1
	while i >= 0:
		_pool_life[i] -= delta
		if _pool_life[i] <= 0.0:
			_remove_pool(i)
		elif player and not player.is_dead:
			if player.global_position.distance_squared_to(_pool_pos[i]) <= _pool_radius[i] * _pool_radius[i]:
				dps = maxf(dps, _pool_dps[i])
		i -= 1
	if dps > 0.0 and _acid_tick <= 0.000001:
		_acid_tick = ACID_TICK
		player.take_damage(dps * ACID_TICK)


func _update_flashes(delta: float) -> void:
	var i := _flash_count - 1
	while i >= 0:
		_flash_age[i] += delta
		if _flash_age[i] >= FLASH_TIME:
			_flash_count -= 1
			_flash_pos[i] = _flash_pos[_flash_count]
			_flash_radius[i] = _flash_radius[_flash_count]
			_flash_age[i] = _flash_age[_flash_count]
		i -= 1


func _explode(p: Vector2, is_elite: bool) -> void:
	var generation := _generation
	var radius := 48.0 * (1.5 if is_elite else 1.0)
	_add_flash(p, radius)
	if effects:
		effects.blood_burst(p, Vector2.RIGHT, 40, 170.0, PI)
		for k in randi_range(20, 30):
			var v := Vector2.from_angle(randf() * TAU) * randf_range(30.0, 135.0)
			effects.emit(p, v, randf_range(0.2, 0.55), Color(randf_range(0.5, 0.7), 0.65, 0.12), randf_range(1.5, 3.0), 5.0, false)
		for k in randi_range(8, 10):
			var v := Vector2.from_angle(randf() * TAU) * randf_range(20.0, 65.0)
			effects.emit(p, v, randf_range(0.35, 0.7), Color(0.35, 0.025, 0.02), randf_range(3.0, 5.0), 4.0, true)
	if floor_decals:
		for k in randi_range(2, 3):
			var tex: Texture2D = _blood_tex[randi() % 8]
			if tex:
				var offset := Vector2.from_angle(randf() * TAU) * randf_range(0.0, radius * 0.25)
				floor_decals.blood(tex, p + offset, randf() * TAU, randf_range(1.6, 2.4), 0.9)
		floor_decals.mark_wet(p, radius * 0.6)
	if player:
		var distance := player.global_position.distance_to(p)
		if camera and distance < 300.0:
			camera.shake(4.0 if distance <= 150.0 else 4.0 * (300.0 - distance) / 150.0)
		if not player.is_dead and distance < radius:
			player.take_damage(30.0 * (1.0 + 0.05 * minutes) * (1.3 if is_elite else 1.0))
			if generation != _generation:
				return
	if horde:
		for j in horde.query_radius(p, radius):
			if j < 0 or j >= horde.count or horde.dead[j] != 0:
				continue
			var offset := horde.pos[j] - p
			var falloff := 1.0 - 0.5 * clampf(offset.length() / (radius + Horde.RADIUS), 0.0, 1.0)
			var dir := offset.normalized() if offset.length_squared() > 0.000001 else Vector2.from_angle(randf() * TAU)
			horde.damage(j, 40.0 * falloff, dir, 140.0, WeaponDefs.Ammo.STANDARD, false, horde.pos[j], true)
			if generation != _generation:
				return


func _splash(p: Vector2) -> void:
	if effects == null:
		return
	for k in 7:
		var v := Vector2.from_angle(randf() * TAU) * randf_range(15.0, 50.0)
		effects.emit(p, v, randf_range(0.12, 0.28), Color(0.62, 0.85, 0.2), randf_range(1.0, 2.0), 6.0, false)


func _add_flash(p: Vector2, radius: float) -> void:
	var i := _flash_count
	if _flash_count < FLASH_LIMIT:
		_flash_count += 1
	else:
		i = 0
		for j in range(1, _flash_count):
			if _flash_age[j] > _flash_age[i]:
				i = j
	_flash_pos[i] = p
	_flash_radius[i] = radius
	_flash_age[i] = 0.0


func _resize_shots(capacity: int) -> void:
	_shot_pos.resize(capacity)
	_shot_target.resize(capacity)
	_shot_dir.resize(capacity)
	_shot_damage.resize(capacity)
	_shot_phase.resize(capacity)


func _grow_queue() -> void:
	var capacity := _queue_pos.size()
	_queue_pos.resize(capacity * 2)
	_queue_elite.resize(capacity * 2)
	# Переносим обёрнутый хвост в новую половину без временного массива.
	for i in _queue_head:
		_queue_pos[capacity + i] = _queue_pos[i]
		_queue_elite[capacity + i] = _queue_elite[i]


func _remove_shot(i: int) -> void:
	_shot_count -= 1
	_shot_pos[i] = _shot_pos[_shot_count]
	_shot_target[i] = _shot_target[_shot_count]
	_shot_dir[i] = _shot_dir[_shot_count]
	_shot_damage[i] = _shot_damage[_shot_count]
	_shot_phase[i] = _shot_phase[_shot_count]


func _remove_pool(i: int) -> void:
	_pool_count -= 1
	_pool_pos[i] = _pool_pos[_pool_count]
	_pool_radius[i] = _pool_radius[_pool_count]
	_pool_dps[i] = _pool_dps[_pool_count]
	_pool_life[i] = _pool_life[_pool_count]
	_pool_seed[i] = _pool_seed[_pool_count]
	_pool_rot[i] = _pool_rot[_pool_count]
	_pool_art[i] = _pool_art[_pool_count]
	_pool_order[i] = _pool_order[_pool_count]
	for k in POOL_LOBES:
		_lobe_pos[i * POOL_LOBES + k] = _lobe_pos[_pool_count * POOL_LOBES + k]
		_lobe_radius[i * POOL_LOBES + k] = _lobe_radius[_pool_count * POOL_LOBES + k]


func _has_visuals() -> bool:
	return _shot_count > 0 or _pool_count > 0 or _flash_count > 0


func _draw() -> void:
	for i in _pool_count:
		_draw_pool(i)
	for i in _flash_count:
		var p := to_local(_flash_pos[i])
		var t := clampf(_flash_age[i] / FLASH_TIME, 0.0, 1.0)
		var radius := _flash_radius[i]
		if t < 0.6:
			PixelArt.draw_dot(self, p, radius * lerpf(0.25, 0.7, t), Color(0.1, 0.09, 0.04, 0.35 * (1.0 - t / 0.6)))
		draw_arc(p, radius * lerpf(0.3, 1.0, t), 0.0, TAU, 32, Color(0.7, 0.66, 0.18, 0.85 * (1.0 - t)), 1.5)
	for i in _shot_count:
		_draw_shot(i)


func _draw_pool(i: int) -> void:
	var p := to_local(_pool_pos[i])
	var radius := _pool_radius[i]
	var fade := clampf(_pool_life[i] / FADE_TIME, 0.0, 1.0)
	var tex: Texture2D = _acid_tex[_pool_art[i]]
	if tex:
		# 60 px × ART_SCALE дают диаметр 20: доводим его до 2 × radius.
		var base_radius := tex.get_size().x * PixelArt.ART_SCALE * 0.5
		var scale_factor := PixelArt.ART_SCALE * radius / base_radius
		draw_set_transform(p, _pool_rot[i], Vector2.ONE * scale_factor)
		draw_texture_rect(tex, Rect2(-tex.get_size() * 0.5, tex.get_size()), false, Color(1.0, 1.0, 1.0, fade))
		draw_set_transform(Vector2.ZERO)
	else:
		for k in POOL_LOBES:
			var slot := i * POOL_LOBES + k
			PixelArt.draw_dot(self, p + _lobe_pos[slot], _lobe_radius[slot], Color(0.45, 0.62, 0.12, 0.55 * fade))
		PixelArt.draw_dot(self, p - Vector2(radius * 0.12, radius * 0.14), radius * 0.4, Color(0.62, 0.73, 0.19, 0.24 * fade))
	var cycle := _time * 0.75 + _pool_seed[i]
	var phase := fposmod(cycle, 1.0)
	if phase < 0.22:
		var a := _pool_seed[i] + floorf(cycle) * 2.4
		var bubble := p + Vector2.from_angle(a) * radius * 0.45
		PixelArt.draw_dot(self, bubble, lerpf(0.5, 1.6, phase / 0.22), Color(0.8, 0.9, 0.38, fade * (1.0 - phase / 0.22)))


func _draw_shot(i: int) -> void:
	var p := to_local(_shot_pos[i])
	var dir := _shot_dir[i]
	var pulse := 1.0 + 0.12 * sin(_time * 15.0 + _shot_phase[i])
	PixelArt.draw_dot(self, p + Vector2(1.0, 2.0), 2.5, Color(0.03, 0.04, 0.01, 0.45))
	for k in range(3, 0, -1):
		var strength := 1.0 - float(k) * 0.23
		PixelArt.draw_dot(self, p - dir * float(k) * 2.3, 1.5 * strength, Color(0.52, 0.72, 0.14, 0.6 * strength))
	var frame := int(_time * 12.0 + _shot_phase[i]) % 3
	var tex: Texture2D = _spit_tex[frame]
	if tex:
		draw_set_transform(p, dir.angle(), Vector2.ONE * PixelArt.ART_SCALE * pulse)
		draw_texture_rect(tex, Rect2(-tex.get_size() * 0.5, tex.get_size()), false)
		draw_set_transform(Vector2.ZERO)
	else:
		PixelArt.draw_dot(self, p, 2.7 * pulse, Color(0.17, 0.23, 0.04))
		PixelArt.draw_dot(self, p, 2.0 * pulse, Color(0.62, 0.85, 0.2))
		PixelArt.draw_dot(self, p - Vector2(0.6, 0.7), 0.65, Color(0.88, 0.96, 0.52))
