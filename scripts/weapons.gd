class_name Weapons
extends Node2D
## Модульное оружие (GDD §5): до 4 стволов, каждый = основа + патроны + модули.
## Стволы стреляют сами: автомат и дробовик — пулями, рейлган — мгновенным лучом,
## гранатомёт — гранатами со взрывом. Пули, лучи, гранаты и взрывы — данные в массивах.

signal shot_fired(base: int)

signal prototype_unlocked(slot: int, proto_name: String)

const BULLET_RADIUS := 1.5
const SHARD_SPEED := 300.0
const GRENADE_KNOCK := 120.0 # отброс от гранаты игрока
const SUSTAINED_TIME := 3.0 # «Шквал огня»: столько секунд непрерывной стрельбы до бонуса темпа
const LAST_ROUND_MULT := 3.0 # «Последний патрон»
const OVERFLOW_SHARE := 0.75
const OVERFLOW_CAP := 1.0
const OVERFLOW_MAX := 80.0
const LINK_TIME := 6.0
const AIM_MARGIN := -4.0 # ZAI3/R14: автоогонь берёт только цели на экране; −4 — цель видна хотя бы наполовину

## Один расход патрона; потомки делят корень, но не получают его права.
class ShotRoot:
	var id := 0
	var closed := false
	var selected := false

class HitContext:
	var root: ShotRoot
	var generation := 0
	var event_kind := "direct"
	var proc_mask := 1 # право новых связей; потомки его только теряют
	var source: Slot
	var source_slot := -1
	var bindings: Dictionary = {}

	func child(kind: String) -> HitContext:
		var c := HitContext.new()
		c.root = root
		c.generation = generation + 1
		c.event_kind = kind
		c.proc_mask = proc_mask & ~1
		c.source = source
		c.source_slot = source_slot
		c.bindings = bindings
		return c

## Один ствол игрока.
class Slot:
	var uid := 0
	var base := 0
	var model := "ak_s" # id в WeaponDefs.MODELS
	var gun := "rifle" # голос: sfx/weapons/<gun>/
	var trait_id := "" # черта модели (WeaponDefs.TRAITS)
	var level := 1
	var ammo := 0
	var ammo_rank := 1
	var ammo_rare := false
	var modules: Array[Dictionary] = [] # {"id", "rank", "rare"}
	var prototype := -1 # индекс в WeaponDefs.PROTOTYPES
	var mag := 0
	var reloading := false
	var reload_t := 0.0
	var cooldown := 0.0
	var stats := {}
	var heat := 0.0
	var spin := 0.0
	var since_shot := 100.0
	var rack_t := -1.0
	var rack_dir := Vector2.RIGHT
	var reload_missing := 0
	var burst_shots := 0
	var burst_target := -1
	var streak := 0.0 # сколько секунд подряд стреляет (Шквал огня)
	var charged := false # kill_charge: следующий выстрел усилен
	var burst_left := 0 # burst3: сколько пуль осталось в очереди
	var fan_left := 0 # fan: сколько пуль осталось в барабане веера
	var fan_t := 0.0
	var fan_interval := 0.1
	var fan_hit := PackedInt32Array() # fan: цели (uid), по которым уже стреляли в этом веере
	var fan_target := -1
	var fan_uid := 0
	var shot_mult := 1.0 # множитель урона текущего выстрела (заряд, последний патрон)
	var shot_gibs := false # текущий выстрел рвёт на гибы (последний патрон)
	var shot_charged := false
	var last_damage := 0.0 # урон снаряда последнего выстрела до крита (для тестов)
	var angle := 0.0
	var aimed := false
	var recoil := 0.0
	var target := -1
	var target_uid := 0
	var target_t := 0.0
	var retarget := false
	var texture: Texture2D
	var visual_model := ""
	var grip := Vector2.ZERO
	var support := Vector2.ZERO
	var muzzle := Vector2.ZERO
	var eject := Vector2.ZERO

	func set_model(id: String) -> void:
		model = id
		var m: Dictionary = WeaponDefs.MODELS[id]
		base = m["base"]
		gun = m["gun"]
		trait_id = m["trait"]

	func short_name() -> String:
		return WeaponDefs.MODELS[model]["short"]

	func module(id: int) -> Dictionary:
		for m in modules:
			if m["id"] == id:
				return m
		return {}

	## Значение модуля по рангу с учётом редкости (редкий — ×1.5 к ключевому числу).
	func mod_value(id: int, values: Array, rare_mult := WeaponDefs.RARE_MULT) -> float:
		var m := module(id)
		if m.is_empty():
			return 0.0
		var v: float = values[int(m["rank"]) - 1]
		return v * rare_mult if m["rare"] else v

	func mod_rank(id: int) -> int:
		var m := module(id)
		return 0 if m.is_empty() else int(m["rank"])

var player: Player
var camera: GameCamera
## Видимая часть мира для автоогня; пустой прямоугольник — без ограничения (тесты без тика оружия).
var aim_view := Rect2()
var explosions: Explosions
var obstacles: Obstacles
var horde: Horde
var boss: Boss
var firing_enabled := true
const BOSS_TARGET := -2 # отдельный uid, индексы орды остаются прежними
const MANUAL_TARGET := -3 # точка игрока, поиск врага не нужен
var _boss_active := false
var boss_damage := PackedFloat64Array()
var boss_sources: Dictionary = {}
var _burn_left := PackedFloat32Array([0, 0, 0, 0])
var _burn_dps := PackedFloat32Array([0, 0, 0, 0])
var _burn_tick := 0.0
var _contact_fire_t := 0.0
var _contact_fire_cursor := 0
var effects: Effects
var floor_decals: FloorDecals
var sfx: Sfx
const GUN_IDS := ["rifle", "shotgun", "rail", "launcher", "pistol", "revolver", "smg", "sniper", "lmg", "minigun", "flamer", "saw", "crossbow", "auto_shotgun", "dmr", "tesla"]
const RECOIL := [0.8, 1.8, 1.4, 1.5, 0.55, 1.25, 0.25, 2.5, 0.65, 0.2, 0.1, 0.4, 1.1, 1.1, 1.3, 0.3]
var shots := PackedInt32Array()
var damage_dealt := 0.0
var passives := {} # WeaponDefs.Passive → уровень (заполняет прогрессия)
var bonuses := {} # дерево класса на этот забег (Meta.run_bonuses())

var slots: Array[Slot] = []
var _weapon_uid := 0
var _instance_uid := 0
var _shot_uid := 0
var _event: HitContext
var _boverflow := PackedFloat32Array()
var _bcontext: Array[HitContext] = []
var _gcontext: Array[HitContext] = []
var _xcontext: Array[HitContext] = []
var link_metrics := {"received": 0.0, "spent": 0.0, "busy": 0.0, "cap": 0.0, "expired": 0.0, "missed": 0.0, "bonus_hp": 0.0, "procs": 0}
var cryo_metrics := {"hits": 0, "epochs": 0, "alive": 0, "threshold_deaths": 0}
var _link_fx: Array = [] # не более четырёх коротких направленных жестов
var bullet_count := 0

# пули: позиция, скорость, жизнь, урон, ствол, пробивание, отскоки, флаги, uid последней цели
const F_SHARD := 1 # осколок сплита: сам не делится
const F_CHAIN := 2 # снаряд цепи
const F_LAST := 4 # пуля последнего патрона: убийство всегда рвёт на гибы
const F_FIRST := 8 # первый патрон: признак хранится вместе со снарядом
var _bpos := PackedVector2Array()
var _bvel := PackedVector2Array()
var _blife := PackedFloat32Array()
var _bdmg := PackedFloat32Array()
var _bslot := PackedInt32Array()
var _bpierce := PackedInt32Array()
var _bbounce := PackedInt32Array()
var _bflags := PackedInt32Array()
var _blast := PackedInt32Array()
var _bdepth := PackedInt32Array() # глубина цепи
var _bobstacle := PackedInt32Array()

# гранаты
var _gpos := PackedVector2Array()
var _gvel := PackedVector2Array()
var _gleft := PackedFloat32Array() # оставшийся путь
var _gslot := PackedInt32Array()
var _gdmg := PackedFloat32Array()
var _grad := PackedFloat32Array()
var _gsmall := PackedByteArray() # кассетная мини-граната
var _gflag := PackedByteArray() # G_LAST | G_STICKY
const G_LAST := 1 # граната последнего патрона: убитые рвутся на гибы
const G_STICKY := 2 # «Улей»: прилипает к цели и рвётся через STICKY_FUSE
const G_FIRST := 4

# прилипшие гранаты: позиция, uid носителя (0 — земля, BOSS_TARGET — босс), смещение, время до взрыва
var _xpos := PackedVector2Array()
var _xuid := PackedInt32Array()
var _xoff := PackedVector2Array()
var _xt := PackedFloat32Array()
var _xslot := PackedInt32Array()
var _xdmg := PackedFloat32Array()
var _xrad := PackedFloat32Array()
var _xflag := PackedByteArray()

# эффекты для отрисовки: лучи [от, до, ширина, время, цвет]
var _beams: Array = []
# Вспышек мало (до четырёх стволов); один общий аддитивный слой.
const FLASH_KINDS := ["rifle", "shotgun", "rifle", "launcher", "small", "small", "small", "sniper", "rifle", "small", "small", "small", "small", "shotgun", "sniper", "small"]
var _flashes: Array = [] # [позиция, угол, время, основа, тинт, масштаб, поворот, вариант, жизнь]
var _flash_tex: Array[Texture2D] = []
var _flash_layer: Node2D
var _flash_drawn := false
var tails := PackedInt32Array()
var _aim_hold := 0.0
const MOUNTS := [Vector2(1.0, 4.0), Vector2(-1.0, 8.0), Vector2(-2.0, -8.0), Vector2(-8.0, -1.0)]
const SERVO_SECTOR := 2.0943951 # ±120° относительно корпуса
const GUN_TURN := 48.0
var _gun_meta: Dictionary = {}
var _gun_layers: Array[Node2D] = []


func _ready() -> void:
	shots.resize(WeaponDefs.BASES.size())
	tails.resize(WeaponDefs.BASES.size())
	boss_damage.resize(WeaponDefs.BASES.size())
	_gun_meta = JSON.parse_string(FileAccess.get_file_as_string("res://art/guns_meta.json"))["models"]
	if FileAccess.file_exists("res://art/gun_meta_w7.json"):
		_gun_meta.merge(JSON.parse_string(FileAccess.get_file_as_string("res://art/gun_meta_w7.json"))["models"])
	_flash_layer = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_flash_layer.material = mat
	_flash_layer.draw.connect(_draw_flashes)
	add_child(_flash_layer)
	for kind: String in FLASH_KINDS:
		for variant in 4:
			_flash_tex.append(PixelArt.tex("flash_%s_%d" % [kind, variant]))
	bonuses = Meta.run_bonuses()
	add_weapon(ClassTree.STARTERS[ClassTree.CLASSES.find(Meta.class_id)])


# --- управление стволами -----------------------------------------------------------

## Координаты арта и эффекты используют одну и ту же трансформацию.
func gun_scale(i: int) -> float:
	return PixelArt.ART_SCALE * (1.0 if i == 0 else 0.8)


func gun_angle(i: int) -> float:
	var s := slots[i]
	var tilt := sin(clampf(s.reload_t / float(s.stats["reload"]), 0.0, 1.0) * PI) * 0.28 if s.reloading else 0.0
	return s.angle + tilt


func gun_grip(i: int) -> Vector2:
	return player.global_position + player.sprite.position + MOUNTS[i].rotated(player.sprite.rotation) - Vector2.from_angle(slots[i].angle) * slots[i].recoil


func gun_point(i: int, point: Vector2) -> Vector2:
	return gun_grip(i) + ((point - slots[i].grip) * gun_scale(i)).rotated(gun_angle(i))


func _aim_gun(i: int, at: Vector2, delta: float) -> void:
	var s := slots[i]
	var body := player.aim_dir.angle() if player.aim_dir != Vector2.ZERO else player.facing.angle()
	# Основной ствол задаёт корпус, боковые остаются в секторе своих сервоприводов.
	if i == 0 and not player.manual_aim and s.target != -1:
		player.aim_dir = (at - player.global_position).normalized()
		_aim_hold = 0.4
		body = player.aim_dir.angle()
	var desired := (at - gun_grip(i)).angle()
	# Учитываем поперечное смещение дула: ось спрайта точно проходит через цель.
	var offset := (s.muzzle - s.grip) * gun_scale(i)
	var distance := gun_grip(i).distance_to(at)
	if distance > absf(offset.y) + 0.01:
		desired -= asin(clampf(offset.y / distance, -1.0, 1.0))
	var relative := angle_difference(body, desired)
	if i > 0 and not player.manual_aim:
		desired = body + clampf(relative, -SERVO_SECTOR, SERVO_SECTOR)
	if player.manual_aim:
		desired = player.aim_dir.angle()
	# Ручной прицел следует курсору сразу: доводка не должна задерживать выстрелы.
	if player.manual_aim or not s.aimed:
		s.angle = desired
		s.aimed = true
	else:
		s.angle = lerp_angle(s.angle, desired, 1.0 - exp(-GUN_TURN * delta))


func _gun_aligned(i: int, at: Vector2) -> bool:
	if player.manual_aim:
		return absf(angle_difference(slots[i].angle, player.aim_dir.angle())) < 0.005
	var dir := at - gun_point(i, slots[i].muzzle)
	return absf(angle_difference(slots[i].angle, dir.angle())) < 0.08


## Два постоянных слоя: спинное крепление под бойцом, остальные над ним.
func _update_gun_layers() -> void:
	if player == null:
		return
	if _gun_layers.is_empty():
		for rear: bool in [true, false]:
			var layer := Node2D.new()
			player.add_child(layer)
			if rear:
				player.move_child(layer, 0)
			layer.draw.connect(_draw_guns.bind(layer, rear))
			_gun_layers.append(layer)
	for layer: Node2D in _gun_layers:
		layer.visible = player.sprite.visible and not player.is_dead
		layer.modulate = player.sprite.modulate
		layer.queue_redraw()


func _draw_guns(layer: Node2D, rear: bool) -> void:
	for i in mini(slots.size(), MOUNTS.size()):
		if (i == 3) != rear:
			continue
		var s := slots[i]
		var grip := gun_grip(i) - player.global_position
		if i > 0:
			var root := player.sprite.position + Vector2(-3.0, 0).rotated(player.sprite.rotation)
			var elbow := root.lerp(grip, 0.6) - Vector2.from_angle(player.sprite.rotation) * 2.0
			layer.draw_line(root, elbow, Color("171e23"), 1.4)
			layer.draw_line(elbow, grip, Color("526068"), 0.7)
			layer.draw_rect(Rect2(elbow - Vector2.ONE, Vector2.ONE * 2.0), Color("242e33"))
			layer.draw_rect(Rect2(elbow - Vector2.ONE * 0.35, Vector2.ONE * 0.7), Color("91a6a5"))
		var scale := Vector2.ONE * gun_scale(i)
		layer.draw_set_transform(grip + Vector2(0, PixelArt.ART_SCALE), gun_angle(i), scale)
		layer.draw_texture(s.texture, -s.grip, Color(0, 0, 0, 0.65))
		layer.draw_set_transform(grip, gun_angle(i), scale)
		layer.draw_texture(s.texture, -s.grip)
		if s.base == WeaponDefs.Base.SAW and s.since_shot < 0.3:
			var shift := fmod(effects._fx_time * 70.0, 3.0) if effects else 0.0
			for k in 7:
				var tooth := s.muzzle - s.grip - Vector2(3.0 + k * 3.0 + shift, 2.0)
				layer.draw_rect(Rect2(tooth, Vector2(1.5, 1.0)), Color("c3c7ba"))
		if s.base == WeaponDefs.Base.MINIGUN and s.spin > 0.0:
			var phase := effects._fx_time * (10.0 + s.spin * 60.0) if effects else 0.0
			for k in 3:
				var offset := sin(phase + float(k) * TAU / 3.0) * 4.0
				var end := s.muzzle - s.grip + Vector2(-1.0, offset)
				layer.draw_line(end - Vector2(26.0, 0), end, Color("9da4a0") if offset < 0 else Color("353d3e"), 1.2)
		if s.base == WeaponDefs.Base.LMG:
			for k in 4:
				var link := s.eject - s.grip + Vector2(-3.0, float(k) * 2.2)
				layer.draw_line(link, link + Vector2(3.5, 0), Color("a48a50"), 1.0)
		layer.draw_set_transform(Vector2.ZERO)
		if i == 0:
			# Перчатки действительно лежат на точках хвата обеих рук каждой модели.
			for hand: Vector2 in [s.grip, s.support]:
				var p := gun_point(i, hand) - player.global_position
				layer.draw_rect(Rect2(p - Vector2(0.8, 0.6), Vector2(1.6, 1.2)), Color("303830"))
				layer.draw_line(p - Vector2(0.5, 0.4), p + Vector2(0.4, -0.4), Color("66715a"), PixelArt.ART_SCALE)

## model "" — избранная модель категории (Meta.model_for).
func add_weapon(base: int, model := "") -> void:
	if slots.size() >= WeaponDefs.MAX_SLOTS:
		return
	var s := Slot.new()
	_weapon_uid += 1
	s.uid = _weapon_uid
	s.set_model(model if model != "" else Meta.model_for(base))
	slots.append(s)
	refresh(slots.size() - 1)
	s.mag = s.stats["mag"]


func _refresh_gun(s: Slot) -> void:
	if s.visual_model == s.model:
		return
	s.visual_model = s.model
	var world: Dictionary = _gun_meta[s.model]["world"]
	s.texture = PixelArt.tex("gun_%s_world" % s.model)
	s.grip = Vector2(world["grip"][0], world["grip"][1])
	s.support = Vector2(world["support"][0], world["support"][1])
	s.muzzle = Vector2(world["muzzle"][0], world["muzzle"][1])
	# В метаданных нет окна выброса: на ствольной коробке между хватом и цевьём.
	s.eject = s.grip.lerp(s.support, 0.3) + Vector2(0, -3)


func has_base(base: int) -> bool:
	for s in slots:
		if s.base == base:
			return true
	return false


static func overflow_donor(s: Slot) -> bool:
	return s.base in [WeaponDefs.Base.RAIL, WeaponDefs.Base.SNIPER, WeaponDefs.Base.CROSSBOW, WeaponDefs.Base.REVOLVER]


static func overflow_receiver(s: Slot) -> bool:
	return s.base in [WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.AUTO_SHOTGUN] and s.trait_id != "slug"


func slot_by_uid(uid: int) -> int:
	for i in slots.size():
		if slots[i].uid == uid:
			return i
	return -1


func link_count() -> int:
	var n := 0
	for s in slots:
		if not s.module(WeaponDefs.Module.LINK).is_empty(): n += 1
	return n


func link_available(receiver: int, partner := -1, moving: Dictionary = {}) -> bool:
	if receiver < 0 or receiver >= slots.size() or not overflow_receiver(slots[receiver]): return false
	var dst := slots[receiver]
	if moving.is_empty():
		if link_count() >= 2: return false
		for s in slots:
			if not s.module(WeaponDefs.Module.LINK).is_empty(): return false # один экземпляр рецепта
	if not dst.module(WeaponDefs.Module.LINK).is_empty() and dst.module(WeaponDefs.Module.LINK) != moving: return false
	if partner >= 0:
		return partner < slots.size() and partner != receiver and overflow_donor(slots[partner])
	for s in slots:
		if overflow_donor(s): return true
	return false


func overflow_limit(s: Slot) -> float:
	return minf(OVERFLOW_MAX, float(s.stats["damage"]) * int(s.stats["proj"]) * OVERFLOW_CAP)


func install_link(receiver: int, partner: int, replacement: Dictionary = {}) -> bool:
	if partner < 0: return false
	if not link_available(receiver, partner): return false
	if not _link_room(receiver, {}, replacement): return false
	_instance_uid += 1
	var s := slots[receiver]
	s.modules.append({"id": WeaponDefs.Module.LINK, "rank": 1, "rare": false, "instance_id": _instance_uid,
		"recipe_id": "overflow", "receiver_weapon_uid": s.uid, "partner_weapon_uid": slots[partner].uid,
		"binding_revision": 1, "charge": 0.0, "left": 0.0, "active": true})
	refresh(receiver)
	return true


## Перепривязка сохраняет экземпляр; старые снаряды не входят в новую ревизию.
func rebind_link(m: Dictionary, receiver: int, partner: int, replacement: Dictionary = {}) -> bool:
	if partner < 0: return false
	if not link_available(receiver, partner, m): return false
	var old := slot_by_uid(int(m["receiver_weapon_uid"]))
	if old < 0 or not slots[old].modules.has(m): return false
	if not _link_room(receiver, m, replacement): return false
	if old != receiver:
		slots[old].modules.erase(m)
		slots[receiver].modules.append(m)
	m["receiver_weapon_uid"] = slots[receiver].uid
	m["partner_weapon_uid"] = slots[partner].uid
	m["binding_revision"] += 1
	m["charge"] = 0.0
	m["left"] = 0.0
	m["active"] = true
	refresh(receiver)
	return true


## Замена оплачивается только после выбора конкретной детали и повторной проверки её снимка.
func _link_room(receiver: int, moving: Dictionary, replacement: Dictionary) -> bool:
	var s := slots[receiver]
	if s.modules.has(moving) or s.modules.size() < WeaponDefs.module_slots(s.level):
		return replacement.is_empty()
	if replacement.is_empty() or int(replacement.get("id", -1)) == WeaponDefs.Module.LINK or not s.modules.has(replacement): return false
	s.modules.erase(replacement)
	return true


func _sync_links() -> void:
	for s in slots:
		var m := s.module(WeaponDefs.Module.LINK)
		if m.is_empty(): continue
		var partner := slot_by_uid(int(m["partner_weapon_uid"]))
		var active := overflow_receiver(s) and partner >= 0 and overflow_donor(slots[partner])
		if bool(m["active"]) != active:
			m["binding_revision"] += 1
			m["charge"] = 0.0
			m["left"] = 0.0
		m["active"] = active
		m["charge"] = minf(float(m["charge"]), overflow_limit(s))


func _update_links(delta: float) -> void:
	for s in slots:
		var m := s.module(WeaponDefs.Module.LINK)
		if m.is_empty() or float(m["left"]) <= 0.0: continue
		m["left"] = maxf(0.0, float(m["left"]) - delta)
		if float(m["left"]) == 0.0:
			link_metrics["expired"] += float(m["charge"])
			m["charge"] = 0.0
	for j in range(_link_fx.size() - 1, -1, -1):
		_link_fx[j][2] -= delta
		if _link_fx[j][2] <= 0.0: _link_fx.remove_at(j)


func _snapshot(s: Slot) -> Slot:
	var copy := Slot.new()
	copy.set_model(s.model)
	copy.uid = s.uid
	copy.level = s.level
	copy.ammo = s.ammo
	copy.ammo_rank = s.ammo_rank
	copy.ammo_rare = s.ammo_rare
	copy.stats = s.stats.duplicate(true)
	copy.modules = s.modules.duplicate(true)
	copy.prototype = s.prototype
	copy.shot_gibs = s.shot_gibs
	copy.shot_charged = s.shot_charged
	copy.mag = s.mag
	return copy


func _begin_shot(i: int) -> HitContext:
	var c := HitContext.new()
	_shot_uid += 1
	c.root = ShotRoot.new()
	c.root.id = _shot_uid
	c.source_slot = i
	c.source = _snapshot(slots[i])
	for s in slots:
		var m := s.module(WeaponDefs.Module.LINK)
		if not m.is_empty() and m["active"] and int(m["partner_weapon_uid"]) == c.source.uid:
			c.bindings[m["instance_id"]] = m["binding_revision"]
	return c


func _donate(c: HitContext, result: Horde.DamageResult, at: Vector2) -> void:
	if c == null or result == null or c.generation != 0 or c.proc_mask & 1 == 0 or c.root.closed or c.root.selected or not result.killed or result.overkill <= 0.0: return
	for s in slots:
		var m := s.module(WeaponDefs.Module.LINK)
		if m.is_empty() or not m["active"] or int(m["partner_weapon_uid"]) != c.source.uid: continue
		if c.bindings.get(m["instance_id"], -1) != m["binding_revision"]: continue
		c.root.selected = true
		var raw := result.overkill * OVERFLOW_SHARE
		if float(m["charge"]) > 0.0:
			link_metrics["busy"] += raw
			return
		var charge := minf(raw, overflow_limit(s))
		m["charge"] = charge
		m["left"] = LINK_TIME
		link_metrics["received"] += charge
		link_metrics["cap"] += raw - charge
		link_metrics["procs"] += 1
		_link_gesture(at, player.global_position, false)
		return


func _link_gesture(from: Vector2, to: Vector2, spending: bool) -> void:
	if _link_fx.size() >= 4: _link_fx.pop_front()
	_link_fx.append([from, to, 0.32, spending])


## Пересчёт статов ствола (CONTRACTS §11): основа → переопределения модели → уровни L2–L5 →
## мастерская модели → дерево класса → пассивки → модули, затем проверка прототипа.
func refresh(i: int) -> void:
	var s := slots[i]
	_refresh_gun(s)
	var st := WeaponDefs.model_stats(s.model, s.level)
	var step: Dictionary = Meta.WORKSHOP_STEP
	st["damage"] *= (1.0 + step["damage"] * Meta.workshop_level(s.model, "damage")) * float(bonuses.get("damage_mul", 1.0))
	st["rate"] *= 1.0 + step["rate"] * Meta.workshop_level(s.model, "rate")
	st["mag"] = ceili(float(st["mag"]) * (1.0 + step["mag"] * Meta.workshop_level(s.model, "mag")) * float(bonuses.get("mag_mul", 1.0)) - 0.0001)
	st["reload"] *= (1.0 + step["reload"] * Meta.workshop_level(s.model, "reload")) * float(bonuses.get("reload_mul", 1.0))
	st["crit"] += float(bonuses.get("crit_add", 0.0))
	st["range"] *= float(bonuses.get("range_mul", 1.0))
	st["spread"] = float(st.get("spread", 0.0)) * float(bonuses.get("spread_mul", 1.0))
	st["knock"] *= float(bonuses.get("knock_mul", 1.0))
	st["damage"] *= 1.0 + _passive(WeaponDefs.Passive.DAMAGE)
	st["rate"] *= 1.0 + _passive(WeaponDefs.Passive.FIRE_RATE)
	st["reload"] *= 1.0 - _passive(WeaponDefs.Passive.RELOAD)
	# сдвоенный ствол
	var twin := s.mod_rank(WeaponDefs.Module.TWIN)
	if twin > 0:
		var extra := twin + (1 if s.module(WeaponDefs.Module.TWIN)["rare"] else 0)
		if s.base == WeaponDefs.Base.SHOTGUN:
			extra *= 2
		st["proj"] += extra
		st["damage"] *= [0.9, 0.85, 0.85][twin - 1] if not s.module(WeaponDefs.Module.TWIN)["rare"] else 1.0
	# пробивание у рейлгана — бонус урона
	if s.base == WeaponDefs.Base.RAIL:
		st["damage"] *= 1.0 + 0.2 * s.mod_rank(WeaponDefs.Module.PIERCE)
	if s.base == WeaponDefs.Base.LAUNCHER:
		st["radius"] *= 1.0 + 0.15 * s.mod_rank(WeaponDefs.Module.PIERCE)
	if s.trait_id == "slug":
		st["damage"] *= int(st["proj"])
		st["proj"] = 1
		st["spread"] = 2.0
		st["pierce"] = int(st.get("pierce", 0)) + 2
	# прототип
	var before := s.prototype
	s.prototype = -1
	for p in WeaponDefs.PROTOTYPES.size():
		var r: Dictionary = WeaponDefs.PROTOTYPES[p]
		if s.base == r["base"] and s.level >= WeaponDefs.MAX_LEVEL and s.ammo == r["ammo"] and s.mod_rank(r["module"]) > 0:
			s.prototype = p
	if s.prototype == 1:
		st["width"] *= 1.5
	s.stats = st
	_sync_links()
	if s.prototype >= 0 and s.prototype != before:
		prototype_unlocked.emit(i, WeaponDefs.PROTOTYPES[s.prototype]["name"])


## Суммарный бонус пассивки: «за уровень» × уровень.
func _passive(p: int) -> float:
	var per: float = WeaponDefs.PASSIVES[p]["per_level"]
	var lv: int = passives.get(p, 0)
	return per * lv


func refresh_all() -> void:
	for i in slots.size():
		refresh(i)


## Тактическая перезарядка (R): все неполные магазины.
func reload_all() -> void:
	for s in slots:
		if not s.reloading and s.mag < s.stats["mag"]:
			_start_reload(s)


## Убрать все снаряды в полёте (тесты).
func clear_projectiles() -> void:
	for i in bullet_count: _bcontext[i] = null
	bullet_count = 0
	_gcontext.clear()
	_xcontext.clear()
	_gpos.clear()
	_gvel.clear()
	_gleft.clear()
	_gslot.clear()
	_gdmg.clear()
	_grad.clear()
	_gsmall.clear()
	_gflag.clear()
	_xpos.clear()
	_xuid.clear()
	_xoff.clear()
	_xt.clear()
	_xslot.clear()
	_xdmg.clear()
	_xrad.clear()
	_xflag.clear()
	_beams.clear()


## «Адреналин»: рывок мгновенно заряжает все стволы.
func refill_all() -> void:
	for s in slots:
		s.reloading = false
		s.reload_t = 0.0
		s.mag = s.stats["mag"]


func any_reloading() -> bool:
	for s in slots:
		if s.reloading:
			return true
	return false


# --- кадр -----------------------------------------------------------------------------------

var _turret_cd := 0.0


func _class_turret(delta: float) -> void:
	_turret_cd = maxf(0.0, _turret_cd - delta)
	if player == null or player.is_dead or player.class_id != "engineer" or player.class_active_t <= 0.0 or _turret_cd > 0.0: return
	_turret_cd = 0.25 / (1.0 + float(bonuses.get("turret_rate", 0.0)))
	var target := -1
	var reach := 160.0 + float(bonuses.get("turret_range", 0.0))
	var best := reach * reach
	for e in horde.query_radius(player.class_anchor, reach):
		var dist := player.class_anchor.distance_squared_to(horde.pos[e])
		if dist < best and (obstacles == null or obstacles.line_clear(player.class_anchor, horde.pos[e])):
			best = dist
			target = e
	var hit_boss := boss != null and boss.is_alive() and player.class_anchor.distance_squared_to(boss.position) < best and (obstacles == null or obstacles.line_clear(player.class_anchor, boss.position))
	if target < 0 and not hit_boss: return
	var at: Vector2 = boss.position if hit_boss else horde.pos[target]
	player.class_facing = (at - player.class_anchor).normalized()
	player.turret_mark = at
	player.turret_mark_t = 0.8 + float(bonuses.get("crossfire_window", 0.0))
	var dmg := 4.0 + float(bonuses.get("turret_damage", 0.0))
	var pellets := 2 if bool(bonuses.get("turret_double", false)) else 1
	if pellets == 2: dmg *= 0.6
	for pellet in pellets:
		if hit_boss:
			_damage_boss(-1, dmg, player.class_facing, at, "turret")
			continue
		if horde.dead[target] != 0: break
		damage_dealt += minf(dmg, horde.hp[target])
		horde.damage(target, dmg, player.class_facing, 12.0, WeaponDefs.Ammo.STANDARD, false, at, false)
	if effects: effects.emit(player.class_anchor + player.class_facing * 10.0, player.class_facing * 30.0, 0.08, Color("bbb18c"), 1.5, 0.0)


func _physics_process(delta: float) -> void:
	aim_view = PixelArt.view_rect(self, AIM_MARGIN)
	_update_links(delta)
	_update_contact_fire(delta)
	_class_turret(delta)
	_boss_active = boss != null and boss.is_alive()
	_update_boss_fire(delta)
	_update_bullets(delta)
	_update_grenades(delta)
	_update_stuck(delta)
	_age_fx(delta)
	queue_redraw()
	# Слой вспышек перерисовывается, только пока есть вспышки (и один раз, чтобы стереть).
	if not _flashes.is_empty() or _flash_drawn:
		_flash_layer.queue_redraw()
	_flash_drawn = not _flashes.is_empty()
	if player == null or player.is_dead or not firing_enabled:
		_update_gun_layers()
		return
	_aim_hold -= delta
	if _aim_hold <= 0.0 and not player.manual_aim:
		player.aim_dir = Vector2.ZERO
	if Input.is_action_just_pressed("reload"):
		reload_all()
	player.tree_reloading = any_reloading()
	player.weapon_speed_mul = 1.0
	for i in slots.size():
		_update_slot(i, delta)
		if slots[i].base == WeaponDefs.Base.MINIGUN and slots[i].spin > 0.1:
			player.weapon_speed_mul = 0.65
	_update_gun_layers()


func _update_slot(i: int, delta: float) -> void:
	var s := slots[i]
	s.recoil = move_toward(s.recoil, 0.0, delta * lerpf(20.0, 16.0, RECOIL[s.base] / 2.5))
	s.target_t -= delta
	# Цель сохраняется между выстрелами; uid защищает от перестановки плотной орды.
	var valid := s.target == BOSS_TARGET and _boss_active
	if s.target >= 0 and s.target < horde.count:
		valid = horde.dead[s.target] == 0 and horde.uid[s.target] == s.target_uid
	var needs_line := s.base not in [WeaponDefs.Base.RAIL, WeaponDefs.Base.LAUNCHER]
	var origin: Vector2 = player.global_position + MOUNTS[i].rotated(player.sprite.rotation)
	if not valid and s.target != -1:
		s.target_t = 0.0 # смерть позволяет немедленно искать новую цель
	if valid and s.target_t <= 0.0:
		valid = origin.distance_squared_to(_target_position(s.target)) <= float(s.stats["range"]) * float(s.stats["range"]) and _on_screen(s.target)
		if valid and needs_line and obstacles != null:
			valid = obstacles.line_clear(origin, _target_position(s.target))
	if player.manual_aim:
		s.target = MANUAL_TARGET
	else:
		if s.target == MANUAL_TARGET:
			s.aimed = false # Возврат с ПКМ к автоцели без паузы на доводку.
		if not valid:
			s.target = -1
		# Живую цель держим до выстрела: вне сектора ждём корпус без новых сканирований.
		if s.fan_left <= 0 and (not valid or (s.retarget and s.cooldown <= delta)) and s.target_t <= 0.0:
			var candidate := _nearest_target(origin, s.stats["range"], PackedInt32Array(), needs_line)
			# Равные цели не перетягивают ствол: выигрыш дистанции должен быть 15%.
			if not valid or candidate == -1 or origin.distance_squared_to(_target_position(candidate)) < origin.distance_squared_to(_target_position(s.target)) * 0.7225:
				s.target = candidate
			s.target_uid = horde.uid[s.target] if s.target >= 0 else 0
			s.target_t = 0.08
			s.retarget = false
	var at := player.aim_point if s.target == MANUAL_TARGET else (_target_position(s.target) if s.target != -1 else player.global_position + Vector2.from_angle(player.sprite.rotation) * 100.0)
	if s.base in [WeaponDefs.Base.LMG, WeaponDefs.Base.MINIGUN]:
		var spinning := player.fire_requested and s.target != -1 and not s.reloading
		var spin_time := 0.35 if s.base == WeaponDefs.Base.LMG else 0.9
		if player.class_id == "gunner": spin_time *= 0.75
		if s.trait_id == "quick_spin": spin_time *= 0.5
		s.spin = move_toward(s.spin, 1.0 if spinning else 0.0, delta / (spin_time if spinning else (1.3 if s.trait_id == "quick_spin" else 0.5)))
	if s.fan_left <= 0:
		_aim_gun(i, at, delta)
	s.cooldown -= delta
	s.since_shot += delta
	if s.since_shot > 1.5 / float(s.stats["rate"]):
		_end_burst(s)
		s.heat = move_toward(s.heat, 0.0, delta * 35.0)
	# «Шквал огня»: серия не прерывается короткими паузами между очередями, но перезарядка её сбрасывает
	if s.since_shot > maxf(0.6, 1.5 / float(s.stats["rate"])):
		s.streak = 0.0
		s.burst_left = 0
	elif not s.reloading:
		s.streak += delta
	if s.rack_t >= 0.0:
		s.rack_t -= delta
		if s.rack_t < 0.0:
			_sound(s, "rack")
			if effects:
				effects.casing(gun_point(i, s.eject), Vector2.from_angle(s.angle), "shell" if s.base == WeaponDefs.Base.SHOTGUN else "brass_rifle")
	if s.reloading:
		var before := s.reload_t / float(s.stats["reload"])
		if player.class_id == "gunner": delta /= maxf(0.4, 1.0 - player.stability * float(bonuses.get("brace_reload", 0.0)))
		s.reload_t += delta / (float(bonuses.get("tactical_mul", 1.0)) if s.reload_missing < int(s.stats["mag"]) else 1.0)
		_reload_actions(s, before, s.reload_t / float(s.stats["reload"]))
		if s.reload_t >= s.stats["reload"]:
			s.reloading = false
			s.mag = s.stats["mag"]
		return
	if not player.fire_requested:
		s.fan_left = 0
		s.burst_left = 0
		return
	if s.fan_left > 0:
		_update_fan(i, s, delta)
		return
	if s.cooldown > 0.0:
		return
	if s.base in [WeaponDefs.Base.LMG, WeaponDefs.Base.MINIGUN] and s.spin < 0.99:
		return
	var target := s.target
	if target == -1:
		return
	if not _gun_aligned(i, at):
		return
	if target != MANUAL_TARGET and needs_line and obstacles != null and not obstacles.line_clear(gun_point(i, s.muzzle), at):
		s.target = -1
		return
	if s.trait_id == "fan":
		_start_fan(s)
		_update_fan(i, s, 0.0)
		return
	_fire_shot(i, s, target)
	# ППШ и очереди сохраняют дробную часть интервала: 14/с не округляется до 12/с на физике 60 Гц.
	var carry := -delta if s.base in [WeaponDefs.Base.SMG, WeaponDefs.Base.MINIGUN, WeaponDefs.Base.LMG, WeaponDefs.Base.FLAMER, WeaponDefs.Base.SAW] or s.trait_id in ["burst3", "doubletap"] else 0.0
	s.cooldown = maxf(s.cooldown, carry) + _shot_interval(s)


## Пауза до следующего выстрела с учётом «Шквала огня»; у burst3 — внутри очереди короткая, после неё длинная.
func _shot_interval(s: Slot) -> float:
	var rate: float = s.stats["rate"] * _streak_mult(s)
	if s.trait_id == "doubletap":
		s.burst_left = 1 if s.burst_left <= 0 else 0
		return 0.05 if s.burst_left > 0 else maxf(0.05, 2.0 / rate - 0.05)
	if s.trait_id == "burst3":
		s.burst_left = WeaponDefs.BURST_SHOTS - 1 if s.burst_left <= 0 else s.burst_left - 1
		if s.burst_left > 0:
			return WeaponDefs.BURST_GAP
		return maxf(WeaponDefs.BURST_SHOTS / rate - WeaponDefs.BURST_GAP * (WeaponDefs.BURST_SHOTS - 1), WeaponDefs.BURST_GAP)
	return 1.0 / rate


func _streak_mult(s: Slot) -> float:
	return 1.0 + float(bonuses.get("sustained_rate", 0.0)) if s.streak >= SUSTAINED_TIME else 1.0


## Один выстрел в цель target: снаряды, отдача, вспышка, звук, гильза, магазин. Паузу ставит вызывающий.
func _fire_shot(i: int, s: Slot, target: int) -> void:
	var origin := player.global_position
	s.retarget = true
	_burst_shot(s, target if target < -1 else horde.uid[target])
	var target_pos := player.aim_point if target == MANUAL_TARGET else _target_position(target)
	if target == MANUAL_TARGET:
		s.angle = player.aim_dir.angle() # после доводки сохраняем точную ось ручного прицела S8
	var dir := Vector2.from_angle(s.angle)
	if target == MANUAL_TARGET:
		target_pos = origin + (target_pos - origin).limit_length(float(s.stats["range"]))
	if i == 0 and target != MANUAL_TARGET:
		player.aim_dir = (target_pos - origin).normalized()
		_aim_hold = 0.4
	# множитель урона: усиленный выстрел «Копья» и последний патрон магазина (дерево класса)
	s.shot_mult = 1.0
	# Стойка и HP фиксируются при выстреле; дистанция — до фактически задетой цели при попадании.
	s.shot_mult *= player.tree_damage_multiplier(-1.0)
	if s.mag == int(s.stats["mag"]):
		s.shot_mult *= 1.0 + float(bonuses.get("first_round", 0.0))
	s.shot_charged = false
	s.shot_gibs = false
	if s.trait_id == "kill_charge" and s.charged:
		s.charged = false
		s.shot_charged = true
		s.shot_mult *= WeaponDefs.KILL_CHARGE_MULT
	if s.mag == 1 and (bool(bonuses.get("last_round", false)) or s.trait_id == "last_round"):
		s.shot_mult *= LAST_ROUND_MULT
		s.shot_gibs = true
	s.last_damage = float(s.stats["damage"]) * s.shot_mult
	var feel: Dictionary = sfx.gun_lab.values(s.gun) if sfx else {"shake":1.0,"recoil":1.0,"flash":1.0}
	player.kick(RECOIL[s.base] * float(feel.recoil))
	# Плечи получают удар в кадре выстрела, до следующего шага физики героя.
	player.sprite.position = -Vector2.from_angle(player.sprite.rotation) * minf(player._kick * 0.8, 2.0)
	if camera:
		var impulse: float = [1.15, 3.0, 2.6, 2.8, 0.9, 1.7, 0.45, 3.5][s.base] if s.base < 8 else RECOIL[s.base] * 1.4
		camera.kick(dir, impulse * float(feel.shake))
		if s.base in [WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.SNIPER]:
			camera.shake((0.35 if s.base == WeaponDefs.Base.SHOTGUN else 0.5) * float(feel.shake))
	s.recoil = minf(2.0, ([1.3, 2.0, 1.8, 1.8, 1.2, 1.65, 1.0, 2.0][s.base] if s.base < 8 else maxf(1.0, RECOIL[s.base] * 1.6)) * float(feel.recoil))
	var muzzle := gun_point(i, s.muzzle)
	var parent := _event
	_event = _begin_shot(i)
	match s.base:
		WeaponDefs.Base.RIFLE, WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.PISTOL, WeaponDefs.Base.REVOLVER, WeaponDefs.Base.SMG, WeaponDefs.Base.SNIPER, WeaponDefs.Base.LMG, WeaponDefs.Base.MINIGUN, WeaponDefs.Base.CROSSBOW, WeaponDefs.Base.AUTO_SHOTGUN, WeaponDefs.Base.DMR:
			_fire_bullets(i, muzzle, dir)
		WeaponDefs.Base.FLAMER, WeaponDefs.Base.SAW:
			_fire_sector(i, muzzle, dir)
		WeaponDefs.Base.TESLA:
			_fire_arc(i, muzzle, target)
		WeaponDefs.Base.RAIL:
			_fire_rail(i, muzzle, dir)
		WeaponDefs.Base.LAUNCHER:
			_fire_grenades(i, muzzle, target_pos)
	_event = parent
	var tint := Color.WHITE
	if s.base == WeaponDefs.Base.RAIL:
		tint = Color(0.8, 0.9, 1.0)
	if s.ammo == WeaponDefs.Ammo.CRYO:
		tint = Color(0.45, 0.8, 1.0)
	elif s.ammo == WeaponDefs.Ammo.INCENDIARY:
		tint = Color(1.0, 0.36, 0.1)
	var heavy := s.base in [WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.SNIPER, WeaponDefs.Base.RAIL, WeaponDefs.Base.LAUNCHER]
	var life := randf_range(0.045, 0.06) if heavy else randf_range(0.025, 0.035)
	var flash_strength := clampf(float(Meta.settings.get("flashes", 1.0)), 0.0, 1.0)
	tint.a *= minf(1.0, flash_strength * float(feel.flash))
	if s.base not in [WeaponDefs.Base.FLAMER, WeaponDefs.Base.SAW, WeaponDefs.Base.TESLA, WeaponDefs.Base.CROSSBOW]:
		_flashes.append([muzzle, dir.angle(), life, s.base, tint, randf_range(0.85, 1.15), randf_range(-PI / 18.0, PI / 18.0), randi() % 4, life, i])
	_flash_layer.queue_redraw()
	_sound(s, "shot")
	shots[s.base] += 1
	if effects:
		var light_tint := Color(1.0, 0.78, 0.45) if tint == Color.WHITE else tint
		effects.flash_light(muzzle, light_tint, 100.0 + RECOIL[s.base] * 32.0, (0.9 + RECOIL[s.base] * 0.3) * flash_strength, life)
		if heavy or s.heat > 4.0:
			var smoke := Color(0.48, 0.49, 0.50, 0.10 if heavy else 0.06)
			effects.emit(muzzle + dir * 3.0, dir * 9.0 + Vector2(0, -8), 0.35, smoke, 3.4, 1.4)
	# у «Ровного боя» и очередей по 3 разброс не растёт
	if s.base in [WeaponDefs.Base.RIFLE, WeaponDefs.Base.SMG] and s.trait_id != "steady" and s.trait_id != "burst3":
		s.heat = minf(s.heat + (1.0 if s.base == WeaponDefs.Base.RIFLE else 1.4), 16.0 if s.base == WeaponDefs.Base.RIFLE else 26.0)
	s.since_shot = 0.0
	if s.base in [WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.SNIPER]:
		if s.trait_id == "slamfire":
			if effects:
				effects.casing(gun_point(i, s.eject), dir, "shell") # автомат без помпы: гильза сразу
		else:
			s.rack_t = 0.25 if s.base == WeaponDefs.Base.SHOTGUN else 0.3
			s.rack_dir = dir
	elif s.base in [WeaponDefs.Base.RIFLE, WeaponDefs.Base.PISTOL, WeaponDefs.Base.SMG, WeaponDefs.Base.LMG, WeaponDefs.Base.MINIGUN, WeaponDefs.Base.DMR, WeaponDefs.Base.AUTO_SHOTGUN] and effects:
		effects.casing(gun_point(i, s.eject), dir, "shell" if s.base == WeaponDefs.Base.AUTO_SHOTGUN else ("brass_small" if s.base in [WeaponDefs.Base.PISTOL, WeaponDefs.Base.SMG] else "brass_rifle"))
	s.mag -= 1
	if s.mag <= 0:
		_sound(s, "dry")
		_start_reload(s)
	shot_fired.emit(s.base)


## Контактный огонь живых носителей: работа ограничена двенадцатью источниками за тик.
func _update_contact_fire(delta: float) -> void:
	_contact_fire_t -= delta
	if _contact_fire_t > 0.0 or horde == null or horde.count == 0: return
	_contact_fire_t = 0.35
	var active := false
	for s: Slot in slots:
		if s.base == WeaponDefs.Base.FLAMER: active = true
	if not active: return
	var sources := 0
	for step in horde.count:
		_contact_fire_cursor = (_contact_fire_cursor + 1) % horde.count
		var e := _contact_fire_cursor
		if horde.dead[e] != 0 or horde.burn_t[e] <= 0.5: continue
		for j: int in horde.query_radius(horde.pos[e], 20.0):
			if j != e and horde.burn_t[j] <= 0.0:
				horde.ignite(j, 4.0, 2.0, 0.3, 20.0)
				if effects: effects.burning_patch(horde.pos[e].lerp(horde.pos[j], 0.5), 0.55, 0.35)
				break
		sources += 1
		if sources >= 12: break


## Струя и цепь проверяют только соседние ячейки; максимум восемь целей за тик.
func _fire_sector(i: int, muzzle: Vector2, dir: Vector2) -> void:
	var s := slots[i]
	var reach: float = s.stats["range"]
	var angle: float = 76.0 if s.trait_id == "wide" else (140.0 if s.trait_id == "sweep" else float(s.stats["spread"]))
	var threshold := cos(deg_to_rad(angle * 0.5))
	var origin := player.global_position
	var hit_count := 0
	for e: int in horde.query_radius(origin, reach):
		if horde.dead[e] != 0: continue
		var to := horde.pos[e] - origin
		if dir.dot(to.normalized()) < threshold: continue
		if obstacles and not obstacles.line_clear(origin, horde.pos[e]): continue
		if effects and s.base == WeaponDefs.Base.SAW:
			effects.saw_contact(horde.pos[e], dir)
		var killed := _hit_enemy(i, e, s.last_damage, dir, horde.pos[e], s.stats["knock"])
		if killed: _on_kill(i, e, dir, 0)
		hit_count += 1
		if hit_count >= 8: break
	if s.base == WeaponDefs.Base.SAW and hit_count > 0:
		player.stain_blood(origin + dir * 3.0, 0.7)
		if sfx: sfx.play(sound_id(s, "shot"), Vector2.INF, -9.0, 0.01, 0.72)
	if _boss_active and origin.distance_to(boss.global_position) <= reach + Boss.RADIUS and dir.dot((boss.global_position - origin).normalized()) >= threshold:
		_hit_boss(i, s.last_damage, dir, boss.global_position, "sector")
	if effects:
		effects.weapon_sector(muzzle, dir, maxf(12.0, reach - muzzle.distance_to(origin)), angle, s.base == WeaponDefs.Base.SAW)


## Дуга перескакивает при попадании, в отличие от модуля CHAIN, требующего убийства.
func _fire_arc(i: int, muzzle: Vector2, target: int) -> void:
	var s := slots[i]
	var excluded := PackedInt32Array()
	var branches := 2 if s.trait_id == "fork" else 1
	branches += int(s.stats["proj"]) - 1
	for branch in branches:
		var from := muzzle
		var e := target if branch == 0 and target != MANUAL_TARGET else _nearest_target(player.global_position, s.stats["range"], excluded)
		var dmg := s.last_damage
		var jumps := (6 if s.trait_id == "ground" else 4) + s.mod_rank(WeaponDefs.Module.CHAIN)
		if player.class_id == "engineer": jumps += 1
		for jump in jumps:
			if e == -1: break
			var uid: int = BOSS_TARGET if e == BOSS_TARGET else horde.uid[e]
			if excluded.has(uid): break
			excluded.append(uid)
			var at := _target_position(e)
			if e >= 0: horde.shock_until[e] = horde._time + 0.28
			if effects: effects.weapon_arc(from, at)
			var killed := _hit_boss(i, dmg, (at - from).normalized(), at, "arc") if e == BOSS_TARGET else _hit_enemy(i, e, dmg, (at - from).normalized(), at, s.stats["knock"])
			if killed and e >= 0: _on_kill(i, e, (at - from).normalized(), 0)
			from = at
			dmg *= 0.6 if s.trait_id == "ground" else 0.72
			e = _nearest_target(from, 95.0 if s.trait_id == "ground" else 65.0, excluded)


## Веер ковбоя: барабан целиком по разным целям за FAN_TIME (темп сокращает его).
func _start_fan(s: Slot) -> void:
	s.fan_left = s.mag
	s.fan_target = -1
	s.fan_hit.clear()
	s.fan_interval = WeaponDefs.FAN_TIME * WeaponDefs.FAN_BASE_RATE / (float(s.stats["rate"]) * _streak_mult(s)) / float(maxi(s.mag, 1))
	s.fan_t = 0.0


func _update_fan(i: int, s: Slot, delta: float) -> void:
	s.fan_t -= delta
	var pending := s.fan_target == BOSS_TARGET and _boss_active
	if s.fan_target >= 0 and s.fan_target < horde.count:
		pending = horde.dead[s.fan_target] == 0 and horde.uid[s.fan_target] == s.fan_uid
	if pending and not player.manual_aim and obstacles != null:
		pending = obstacles.line_clear(player.global_position, _target_position(s.fan_target))
	var target := MANUAL_TARGET if player.manual_aim else (s.fan_target if pending else _fan_target(s))
	s.fan_target = target
	s.fan_uid = horde.uid[target] if target >= 0 else 0
	if target == -1:
		s.fan_left = 0 # цели кончились: оставшиеся патроны берегутся
		return
	var at := player.aim_point if target == MANUAL_TARGET else _target_position(target)
	_aim_gun(i, at, delta)
	if s.fan_t > 0.0:
		return
	if not _gun_aligned(i, at):
		return
	s.fan_left -= 1
	s.fan_t += s.fan_interval
	_fire_shot(i, s, target)
	s.fan_target = -1
	s.cooldown = 0.0


## Ближайшая цель, по которой в этом веере ещё не стреляли; кончились новые — по кругу.
func _fan_target(s: Slot) -> int:
	var origin := player.global_position
	var target := _nearest_target(origin, s.stats["range"], s.fan_hit)
	if target == -1 and not s.fan_hit.is_empty():
		s.fan_hit.clear()
		target = _nearest_target(origin, s.stats["range"])
	if target != -1:
		s.fan_hit.append(BOSS_TARGET if target == BOSS_TARGET else horde.uid[target])
	return target


func _start_reload(s: Slot) -> void:
	_end_burst(s)
	s.burst_left = 0
	s.fan_left = 0
	s.reloading = true
	s.reload_t = 0.0
	s.reload_missing = int(s.stats["mag"]) - s.mag
	player.tree_reload_cover()
	if s.base in [WeaponDefs.Base.PISTOL, WeaponDefs.Base.RIFLE, WeaponDefs.Base.SMG] or s.base >= 8:
		_sound(s, "mag_out")
		if effects:
			var i := slots.find(s)
			effects.casing(gun_point(i, s.grip), Vector2.from_angle(s.angle), "mag_" + (GUN_IDS[s.base] if s.base < 8 else "rifle"))
	elif s.base == WeaponDefs.Base.REVOLVER:
		_sound(s, "cyl_open")


## Хвост принадлежит завершившейся очереди, счётчик сбрасывается до проигрывания.
func _end_burst(s: Slot) -> void:
	var count := s.burst_shots
	s.burst_shots = 0
	s.burst_target = -1
	if count > 0:
		tails[s.base] += 1
		_sound(s, "tail")


func _burst_shot(s: Slot, target_uid: int) -> void:
	if s.base != WeaponDefs.Base.RIFLE and s.base != WeaponDefs.Base.SMG:
		return
	# Смена цели внутри непрерывной очереди не добавляет отражения поверх неё.
	s.burst_target = target_uid
	s.burst_shots += 1


## Голос по MODELS[model]["gun"]; нет такого файла (звуки моделей делает A3) — голос серийной модели.
func sound_id(s: Slot, action: String) -> String:
	var id := "weapons/" + s.gun + "/" + action
	if sfx and not sfx.has(id):
		id = "weapons/" + (GUN_IDS[s.base] if s.base < 8 or action == "shot" else "rifle") + "/" + action
	return id


func _sound(s: Slot, action: String) -> void:
	if sfx:
		# A2 уже сводит механику на ~12 дБ тише выстрела.
		sfx.play(sound_id(s, action), Vector2.INF, 0.0, 0.05, float(WeaponDefs.MODEL_PITCH.get(s.model, 1.0)) if action == "shot" else 1.0)


## Пороговые события без таймеров-нод. Тактическая помпа вставляет только недостающие патроны.
func _reload_actions(s: Slot, before: float, after: float) -> void:
	if s.base in [WeaponDefs.Base.PISTOL, WeaponDefs.Base.RIFLE, WeaponDefs.Base.SMG] or s.base >= 8:
		if before < 0.7 and after >= 0.7:
			_sound(s, "mag_in")
		if before < 1.0 and after >= 1.0:
			_sound(s, "rack")
	elif s.base == WeaponDefs.Base.REVOLVER:
		if before < 0.15 and after >= 0.15:
			_sound(s, "eject")
			if effects:
				for k in s.reload_missing:
					effects.casing(gun_point(slots.find(s), s.eject), Vector2.from_angle(s.angle + TAU * k / maxf(1.0, s.reload_missing)), "brass_small")
		if before < 0.5 and after >= 0.5:
			_sound(s, "load")
		if before < 0.95 and after >= 0.95:
			_sound(s, "cyl_close")
	elif s.base == WeaponDefs.Base.SHOTGUN:
		for k in s.reload_missing:
			var threshold := float(k + 1) / float(s.reload_missing + 1)
			if before < threshold and after >= threshold:
				_sound(s, "shell_in")


func reload_progress(i: int) -> float:
	var s := slots[i]
	return clampf(s.reload_t / s.stats["reload"], 0.0, 1.0) if s.reloading else 1.0


## Только чтение для HUD: пустой радиус или цель за преградой. Стрельба не меняется.
func silence_reason(i: int) -> String:
	if player == null or horde == null:
		return ""
	var s := slots[i]
	if s.reloading or s.since_shot < 0.2 or s.cooldown > 0.0 or player.manual_aim:
		return ""
	if s.target != -1:
		return ""
	var origin: Vector2 = player.global_position + MOUNTS[i].rotated(player.sprite.rotation)
	var target := _nearest_target(origin, float(s.stats["range"]), PackedInt32Array(), false)
	if target == -1:
		return "no_target"
	if s.base in [WeaponDefs.Base.RAIL, WeaponDefs.Base.LAUNCHER] or obstacles == null:
		return ""
	var at := _target_position(target)
	return "blocked" if not obstacles.line_clear(origin, at) or not obstacles.line_clear(gun_point(i, s.muzzle), at) else ""


# --- пули ------------------------------------------------------------------------------------

func _fire_bullets(i: int, muzzle: Vector2, dir: Vector2) -> void:
	var s := slots[i]
	var st := s.stats
	var n: int = st["proj"]
	var spread := deg_to_rad(float(st["spread"]) + s.heat * float(bonuses.get("spread_mul", 1.0)))
	if s.base == WeaponDefs.Base.LMG and player.tree_still > 0.4:
		spread *= 0.25
	elif s.base == WeaponDefs.Base.LMG:
		spread *= 2.5
	var pierce := int(s.mod_value(WeaponDefs.Module.PIERCE, [2, 4, 6])) + int(st.get("pierce", 0))
	var bounce := int(s.mod_value(WeaponDefs.Module.RICOCHET, [1, 2, 3]))
	var extra := 0.0
	var link := s.module(WeaponDefs.Module.LINK)
	if not link.is_empty() and link["active"] and float(link["charge"]) > 0.0:
		extra = float(link["charge"]) / n
		link_metrics["spent"] += float(link["charge"])
		link_metrics["missed"] += float(link["charge"])
		link["charge"] = 0.0
		link["left"] = 0.0
		_event.root.closed = true
		_link_gesture(muzzle, muzzle + dir * 54.0, true)
	for k in n:
		var a := dir.angle()
		if s.base in [WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.AUTO_SHOTGUN]:
			a += randf_range(-spread, spread) * 0.5
		else:
			# автомат: несколько пуль идут небольшим веером
			a += (k - (n - 1) * 0.5) * deg_to_rad(5.0) + randf_range(-spread, spread) * 0.5
		var spd: float = st["speed"] * (randf_range(0.85, 1.1) if s.base in [WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.AUTO_SHOTGUN] else 1.0)
		var flags := (F_LAST if s.shot_gibs else 0) | (F_FIRST if s.mag == int(st["mag"]) else 0)
		_spawn_bullet(muzzle, Vector2.from_angle(a) * spd, st["range"] / spd, st["damage"] * s.shot_mult, i, pierce, bounce, flags)
		_boverflow[bullet_count - 1] = extra


func _spawn_bullet(p: Vector2, v: Vector2, life: float, dmg: float, slot: int, pierce: int, bounce: int, flags: int, depth := 0) -> void:
	var b := bullet_count
	if b >= _bpos.size():
		_bpos.resize(b + 128)
		_bvel.resize(b + 128)
		_blife.resize(b + 128)
		_bdmg.resize(b + 128)
		_bslot.resize(b + 128)
		_bpierce.resize(b + 128)
		_bbounce.resize(b + 128)
		_bflags.resize(b + 128)
		_blast.resize(b + 128)
		_bdepth.resize(b + 128)
		_bobstacle.resize(b + 128)
		_boverflow.resize(b + 128)
		_bcontext.resize(b + 128)
	_bpos[b] = p
	_bvel[b] = v
	_blife[b] = life
	_bdmg[b] = dmg
	_bslot[b] = slot
	_bpierce[b] = pierce
	_bbounce[b] = bounce
	_bflags[b] = flags
	_blast[b] = -1
	_bdepth[b] = depth
	_bobstacle[b] = -1
	_boverflow[b] = 0.0
	_bcontext[b] = _event
	bullet_count += 1


func _update_bullets(delta: float) -> void:
	var i := bullet_count - 1
	while i >= 0:
		var p0 := _bpos[i]
		var v := _bvel[i]
		var p1 := p0 + v * delta
		_blife[i] -= delta
		var probe := p0.lerp(p1, 0.5)
		var hit := _find_hit_except(probe, _blast[i])
		if hit == -1:
			probe = p1
			hit = _find_hit_except(probe, _blast[i])
		if _boss_active and _blast[i] != BOSS_TARGET:
			var nearest := Geometry2D.get_closest_point_to_segment(boss.global_position, p0, p1)
			if boss.hit_test(nearest, BULLET_RADIUS) and (hit == -1 or p0.distance_squared_to(nearest) < p0.distance_squared_to(probe)):
				hit = BOSS_TARGET
				probe = nearest
		# Стена проверяется до цели; низкое укрытие пропускает пулю, бочка принимает удар.
		var obstacle := obstacles.ray_hit(p0, probe if hit != -1 else p1, false, BULLET_RADIUS, _bobstacle[i]) if obstacles else -1
		if obstacle != -1:
			var s := _bcontext[i].source if _bcontext[i] != null else slots[_bslot[i]]
			obstacles.damage(obstacle, _bdmg[i], s.ammo == WeaponDefs.Ammo.INCENDIARY)
			_bobstacle[i] = obstacle
			if obstacles.high[obstacle] == 1:
				if s.base == WeaponDefs.Base.CROSSBOW and effects: effects.ground_bolt(probe, v.normalized())
				_remove_bullet(i)
				i -= 1
				continue
		if hit != -1:
			if not _bullet_hit(i, hit, probe):
				_remove_bullet(i)
				i -= 1
				continue
		elif _blife[i] <= 0.0:
			if slots[_bslot[i]].base == WeaponDefs.Base.CROSSBOW and effects: effects.ground_bolt(p1, v.normalized())
			_remove_bullet(i)
			i -= 1
			continue
		_bpos[i] = probe if hit != -1 else p1
		i -= 1


func _find_hit_except(p: Vector2, last_uid: int) -> int:
	var hit := horde.find_hit(p, BULLET_RADIUS)
	if hit != -1 and horde.uid[hit] == last_uid:
		return -1
	return hit


func _target_position(target: int) -> Vector2:
	return boss.global_position if target == BOSS_TARGET else horde.pos[target]


## Цель автоогня в кадре: зомби — точкой, босс/узел — с запасом на тело.
func _on_screen(target: int) -> bool:
	if not aim_view.has_area():
		return true
	if target == BOSS_TARGET:
		return boss != null and aim_view.grow(boss.body_radius()).has_point(boss.global_position)
	return target >= 0 and target < horde.count and aim_view.has_point(horde.pos[target])


func _nearest_target(at: Vector2, radius: float, exclude := PackedInt32Array(), needs_line := true) -> int:
	# Сетка даёт кандидатов; трассируем ближайшие восемь, затем расширяем пакет.
	var nearby := horde.query_radius(at, radius)
	# Автоогонь не стреляет за край экрана: толпа умирает в кадре (ZAI3, R14). Ручной прицел сюда не ходит.
	var screen := aim_view.has_area()
	var skipped := exclude.duplicate()
	var target := -1
	var best_distance := radius * radius
	var batch := 8
	while true:
		var indices := PackedInt32Array()
		var distances := PackedFloat64Array()
		for j in nearby:
			if skipped.has(horde.uid[j]) or screen and not aim_view.has_point(horde.pos[j]):
				continue
			var distance := at.distance_squared_to(horde.pos[j])
			if distance > radius * radius:
				continue
			var n := distances.bsearch(distance)
			if n < batch:
				indices.insert(n, j)
				distances.insert(n, distance)
				if indices.size() > batch:
					indices.resize(batch)
					distances.resize(batch)
		for n in indices.size():
			var j := indices[n]
			if not needs_line or obstacles == null or obstacles.line_clear(at, horde.pos[j]):
				target = j
				best_distance = distances[n]
				break
			skipped.append(horde.uid[j])
		if target != -1 or indices.size() < batch:
			break
		batch *= 2
	if _boss_active and not exclude.has(BOSS_TARGET) and _on_screen(BOSS_TARGET):
		var distance := at.distance_squared_to(boss.global_position)
		if distance <= radius * radius and (target == -1 or distance < best_distance * 2.25):
			if not needs_line or obstacles == null or obstacles.line_clear(at, boss.global_position):
				return BOSS_TARGET
	return target


## Попадание пули. Возвращает true, если пуля летит дальше (пробила/отскочила).
func _bullet_hit(b: int, e: int, at: Vector2) -> bool:
	var slot := _bslot[b]
	var parent := _event
	_event = _bcontext[b]
	var s := _event.source if _event != null else slots[slot]
	var dir := _bvel[b].normalized()
	var is_boss := e == BOSS_TARGET
	var source := "chain" if _bflags[b] & F_CHAIN else ("shard" if _bflags[b] & F_SHARD else "bullet")
	var extra := _boverflow[b]
	_boverflow[b] = 0.0 # только первая цель дробины, даже при пробивании и рикошете
	var killed := _hit_boss(slot, _bdmg[b], dir, at, source, extra) if is_boss else _hit_enemy(slot, e, _bdmg[b], dir, at, s.stats["knock"], false, _bflags[b] & F_LAST != 0, _bflags[b] & F_FIRST != 0, _bpierce[b] > 0, extra)
	var uid := BOSS_TARGET if is_boss else horde.uid[e]
	if s.trait_id == "explosive_bolt" and _bflags[b] & F_SHARD == 0:
		var direct := _event
		if _event: _event = _event.child("bolt_blast")
		explode(at, _bdmg[b] * 0.35, 21.0, slot)
		_event = direct
	_blast[b] = uid
	# сплит: осколки веером (сами не делятся)
	if _bflags[b] & F_SHARD == 0 and s.mod_rank(WeaponDefs.Module.SPLIT) > 0:
		_spawn_shards(slot, at, dir, _bdmg[b], uid)
	if killed and not is_boss:
		_on_kill(slot, e, dir, _bdepth[b])
	if _bpierce[b] > 0:
		_bpierce[b] -= 1
		_bdmg[b] *= 1.2 if s.mod_rank(WeaponDefs.Module.PIERCE) >= 3 else 0.8
		_event = parent
		return true
	if _bbounce[b] > 0:
		var exclude := PackedInt32Array([uid])
		var next := _nearest_target(at, 120.0, exclude)
		if next != -1:
			_bbounce[b] -= 1
			_bdmg[b] *= 0.7
			_bvel[b] = (_target_position(next) - at).normalized() * _bvel[b].length()
			_blife[b] = maxf(_blife[b], 0.4)
			_event = parent
			return true
	_event = parent
	return false


func _spawn_shards(slot: int, at: Vector2, dir: Vector2, dmg: float, skip_uid: int) -> void:
	var s := _event.source if _event != null else slots[slot]
	var parent := _event
	if _event: _event = _event.child("shard")
	var n := int(s.mod_value(WeaponDefs.Module.SPLIT, [3, 4, 5], 1.0)) + (1 if s.module(WeaponDefs.Module.SPLIT)["rare"] else 0)
	var k: float = [0.35, 0.4, 0.45][s.mod_rank(WeaponDefs.Module.SPLIT) - 1]
	for j in n:
		var a := dir.angle() + (j - (n - 1) * 0.5) * 0.45
		_spawn_bullet(at, Vector2.from_angle(a) * SHARD_SPEED, 0.25, dmg * k, slot, 0, 0, F_SHARD)
		_blast[bullet_count - 1] = skip_uid
	_event = parent


func _remove_bullet(i: int) -> void:
	bullet_count -= 1
	var j := bullet_count
	_bpos[i] = _bpos[j]
	_bvel[i] = _bvel[j]
	_blife[i] = _blife[j]
	_bdmg[i] = _bdmg[j]
	_bslot[i] = _bslot[j]
	_bpierce[i] = _bpierce[j]
	_bbounce[i] = _bbounce[j]
	_bflags[i] = _bflags[j]
	_blast[i] = _blast[j]
	_bdepth[i] = _bdepth[j]
	_bobstacle[i] = _bobstacle[j]
	_boverflow[i] = _boverflow[j]
	_bcontext[i] = _bcontext[j]
	_bcontext[j] = null


# --- попадание: патроны ------------------------------------------------------------------

## Крит и боеприпасы босса; крио даёт обычный урон, не замораживает босса.
func _hit_boss(slot: int, dmg: float, dir: Vector2, at: Vector2, source: String, flat_bonus := 0.0) -> bool:
	var s := _event.source if _event != null else slots[slot]
	if s.trait_id == "execute" and boss.hp < boss.max_hp * 0.35:
		dmg *= 2.0
	if s.trait_id == "focus" and player.tree_still >= 0.6:
		dmg *= 1.35
	if s.base == WeaponDefs.Base.FLAMER or s.trait_id == "tracer":
		_burn_left[slot] = 5.0 if s.trait_id == "napalm" else 2.0
		_burn_dps[slot] = 4.0
	var rank := s.ammo_rank
	var rare := WeaponDefs.RARE_MULT if s.ammo_rare else 1.0
	var chance: float = s.stats["crit"] + 0.05
	if s.ammo == WeaponDefs.Ammo.STANDARD:
		chance += [0.10, 0.15, 0.15][rank - 1] * rare
	if randf() < chance:
		dmg *= 2.5 if s.ammo == WeaponDefs.Ammo.STANDARD and rank >= 3 else 2.0
	if s.ammo == WeaponDefs.Ammo.INCENDIARY:
		_burn_left[slot] = 3.0
		_burn_dps[slot] = [4.0, 6.0, 6.0][rank - 1] * rare
	if effects:
		_ammo_sparks(s.ammo, at, dir)
	var killed := _damage_boss(slot, dmg, dir, at, source, flat_bonus)
	if s.ammo == WeaponDefs.Ammo.EXPANSIVE and source != "explosion" and (not killed or rank >= 3):
		var radius := 16.0 if rank < 2 else 20.0
		var splash: float = [0.3, 0.45, 0.45][rank - 1] * rare
		for j in horde.query_radius(at, radius):
			horde.damage(j, dmg * splash, (horde.pos[j] - at).normalized(), 30.0, s.ammo, false, horde.pos[j], true)
	return killed


func _damage_boss(slot: int, dmg: float, dir: Vector2, at: Vector2, source: String, flat_bonus := 0.0) -> bool:
	if slot >= 0:
		dmg *= player.class_hit(at)
		dmg *= player.tree_range_multiplier(player.global_position.distance_to(at))
		dmg *= 1.0 + float(bonuses.get("boss_damage", 0.0))
		if boss.hp < boss.max_hp * 0.20:
			dmg *= 1.0 + float(bonuses.get("finish_damage", 0.0))
	var before := boss.hp
	dmg += flat_bonus
	if flat_bonus > 0.0: link_metrics["missed"] -= flat_bonus
	var killed: bool
	if boss is BossGeneral:
		var pen := 0.0
		if slot >= 0:
			var s := _event.source if _event != null else slots[slot]
			pen = WeaponDefs.armor_penetration(s.base, s.model, s.mod_rank(WeaponDefs.Module.PIERCE), player.position.distance_to(at))
		killed = boss.take_armored_damage(dmg, dir, at, pen, source in ["explosion", "grenade", "expansive"])
	else:
		killed = boss.take_damage(dmg, dir, at)
	var dealt := before - boss.hp
	if slot >= 0:
		boss_damage[slots[slot].base] += dealt
	boss_sources[source] = float(boss_sources.get(source, 0.0)) + dealt
	if killed:
		_boss_active = false
	return killed


## Босс не получает статусы орды; горение стволов тикает отдельно раз в 0.5 с.
func _update_boss_fire(delta: float) -> void:
	if not _boss_active:
		_burn_left.fill(0.0)
		return
	_burn_tick += delta
	var tick := _burn_tick >= 0.5
	if tick:
		_burn_tick -= 0.5
	for i in mini(slots.size(), _burn_left.size()):
		if _burn_left[i] <= 0.0:
			continue
		if tick and _boss_active:
			_damage_boss(i, _burn_dps[i] * 0.5, Vector2.ZERO, boss.global_position, "fire")
			if effects:
				effects.emit(boss.global_position + Vector2(randf_range(-12, 12), randf_range(-12, 12)), Vector2(0, -25), 0.4, Color(1.0, 0.35, 0.05), 2.0, 1.0)
		_burn_left[i] = maxf(0.0, _burn_left[i] - delta)


## Урон по зомби с эффектами патронов ствола. Возвращает true, если убит.
func _hit_enemy(slot: int, e: int, dmg: float, dir: Vector2, at: Vector2, knockback: float, explosive := false, gibs := false, first_round := false, through := false, flat_bonus := 0.0) -> bool:
	if horde.dead[e] != 0: return false
	var s := _event.source if _event != null else slots[slot]
	var epoch_before := horde.freeze_epoch[e]
	if s.trait_id == "execute" and horde.hp[e] < horde.max_hp[e] * 0.35:
		dmg *= 2.0
	if s.trait_id == "focus" and player.tree_still >= 0.6:
		dmg *= 1.35
	if s.base == WeaponDefs.Base.FLAMER or s.trait_id == "tracer":
		horde.ignite(e, 4.0, 5.0 if s.trait_id == "napalm" else 2.0, 0.45, 24.0)
	var class_multiplier := player.class_hit(at)
	dmg *= class_multiplier
	if player.class_id == "engineer" and class_multiplier > 1.0: knockback *= 1.0 + float(bonuses.get("crossfire_knock", 0.0))
	if player.class_id == "gunner": knockback *= 1.0 + player.stability * (0.35 + float(bonuses.get("brace_knock", 0.0)))
	dmg *= player.tree_range_multiplier(player.global_position.distance_to(at))
	if horde.elite[e] != 0:
		dmg *= 1.0 + float(bonuses.get("elite_damage", 0.0))
	if horde.hp[e] < horde.max_hp[e] * 0.20:
		dmg *= 1.0 + float(bonuses.get("finish_damage", 0.0))
	if player.global_position.distance_squared_to(at) <= 70.0 * 70.0:
		knockback *= 1.0 + float(bonuses.get("close_knock", 0.0))
	if first_round:
		knockback *= 1.0 + float(bonuses.get("first_knock", 0.0))
	var rank := s.ammo_rank
	var rare := WeaponDefs.RARE_MULT if s.ammo_rare else 1.0
	var crit_chance: float = s.stats["crit"] + 0.05
	var crit_mult := 2.0
	if s.ammo == WeaponDefs.Ammo.STANDARD:
		crit_chance += [0.10, 0.15, 0.15][rank - 1] * rare
		if rank >= 3:
			crit_mult = 2.5
	var crit := randf() < crit_chance
	if crit:
		dmg *= crit_mult
		knockback *= 1.0 + float(bonuses.get("crit_knock", 0.0))
	match s.ammo:
		WeaponDefs.Ammo.INCENDIARY:
			horde.ignite(e, [4.0, 6.0, 6.0][rank - 1] * rare, 3.0, [0.3, 0.3, 0.6][rank - 1], 16.0 if rank < 3 else 32.0)
		WeaponDefs.Ammo.CRYO:
			var primary := _event != null and _event.generation == 0 and not _event.root.closed
			horde.chill_hit(e, 0.2, 4 if rank < 2 else 3, rank >= 3, s.prototype == 1, s.uid, primary)
			cryo_metrics["hits"] += 1
	var e_pos := horde.pos[e]
	damage_dealt += minf(dmg, horde.hp[e])
	var prev_death := horde.death_override
	if s.base == WeaponDefs.Base.SAW:
		horde.death_override = Gore.Death.BISECT
	elif s.base == WeaponDefs.Base.CROSSBOW:
		horde.death_override = Gore.Death.PIN
		horde.bolt_dir[e] = dir.rotated(-horde.angle[e])
	elif s.base == WeaponDefs.Base.FLAMER:
		horde.death_override = Gore.Death.BURN
	if gibs:
		horde.death_override = Gore.Death.GIBS # «Последний патрон» всегда рвёт на гибы
	var penetration := -1.0
	if horde.armor_mask[e] != 0:
		penetration = WeaponDefs.armor_penetration(s.base, s.model, s.mod_rank(WeaponDefs.Module.PIERCE), player.position.distance_to(at))
	var result: Horde.DamageResult
	if flat_bonus > 0.0 or (_event != null and not _event.bindings.is_empty()): result = Horde.DamageResult.new()
	var killed := horde.damage(e, dmg, dir, knockback, s.ammo, crit, at, explosive, s.base, through, penetration, result, flat_bonus)
	if horde.freeze_epoch[e] != epoch_before:
		cryo_metrics["epochs"] += 1
		cryo_metrics["threshold_deaths" if killed else "alive"] += 1
	if flat_bonus > 0.0:
		link_metrics["missed"] -= flat_bonus
		link_metrics["bonus_hp"] += result.bonus_hp_lost
	_donate(_event, result, at)
	horde.death_override = prev_death
	if effects:
		if not horde.last_armor_blocked and (s.base != WeaponDefs.Base.FLAMER or killed):
			effects.blood_hit(e_pos, dir, false)
		_ammo_sparks(s.ammo, e_pos, dir)
	if s.ammo == WeaponDefs.Ammo.EXPANSIVE and not explosive:
		var k: float = [0.3, 0.45, 0.45][rank - 1] * rare
		var r := 16.0 if rank < 2 else 20.0
		if not killed or rank >= 3:
			if _boss_active and boss.hit_test(e_pos, r):
				_damage_boss(slot, dmg * k, dir, e_pos, "expansive")
			for j in horde.query_radius(e_pos, r):
				if j != e:
					horde.damage(j, dmg * k, (horde.pos[j] - e_pos).normalized(), 30.0, s.ammo, false, horde.pos[j], true)
	return killed


## Убийство: детонатор и цепь.
func _on_kill(slot: int, e: int, dir: Vector2, depth: int) -> void:
	var s := _event.source if _event != null else slots[slot]
	var live := slot_by_uid(s.uid)
	var owner: Slot = slots[live] if live >= 0 else s
	var at := horde.pos[e]
	match s.trait_id:
		"return_bolt":
			owner.mag = mini(owner.mag + 1, int(owner.stats["mag"]))
		"kill_charge":
			owner.charged = true # следующий выстрел «Копья» сильнее
		"lever":
			owner.cooldown = 0.0 # убийство мгновенно взводит рычаг
	var parent := _event
	if _event: _event = _event.child("kill_proc")
	if s.mod_rank(WeaponDefs.Module.DETONATOR) > 0:
		var chance := 1.0 if s.prototype == 0 else minf(s.mod_value(WeaponDefs.Module.DETONATOR, [0.25, 0.4, 0.6]), 1.0)
		if randf() < chance and depth < 3:
			var chained := s.mod_rank(WeaponDefs.Module.DETONATOR) >= 3 or s.prototype == 0
			explode(at, s.stats["damage"], 30.0 * (1.3 if s.prototype == 0 else 1.0), slot, depth + (1 if chained else 3))
	if s.base != WeaponDefs.Base.TESLA and s.mod_rank(WeaponDefs.Module.CHAIN) > 0 and depth < (3 if s.mod_rank(WeaponDefs.Module.CHAIN) >= 3 else 1):
		var next := _nearest_target(at, 80.0, PackedInt32Array([horde.uid[e]]))
		if next != -1:
			var k := minf(s.mod_value(WeaponDefs.Module.CHAIN, [0.5, 0.65, 0.8]), 1.0)
			var v := (_target_position(next) - at).normalized() * 380.0
			_spawn_bullet(at, v, 0.35, s.stats["damage"] * k, slot, 0, 0, F_CHAIN | F_SHARD, depth + 1)
			_blast[bullet_count - 1] = horde.uid[e]
	_event = parent


## Взрыв: урон по площади, отброс, гибы. depth ограничивает цепные детонации.
## slot >= 0 — взрыв ствола (патроны, детонатор), slot = -1 — «ничей» (граната игрока):
## урон без эффектов патронов, любая смерть — гибы.
func explode(at: Vector2, dmg: float, radius: float, slot := -1, depth := 0, gibs := false, first_round := false) -> void:
	# Ничей взрыв здесь — ручная граната; стволы и вторичные детонации отдельны.
	if slot < 0:
		dmg *= float(bonuses.get("grenade_damage_mul", 1.0))
		radius *= float(bonuses.get("grenade_radius_mul", 1.0))
		if bool(bonuses.get("grenade_refill", false)):
			refill_all()
	if obstacles:
		obstacles.blast(at, radius, dmg)
	var kind := Explosions.Kind.GRENADE if slot < 0 else (Explosions.Kind.DETONATOR if depth > 0 else Explosions.Kind.LAUNCHER)
	if explosions:
		explosions.spawn(at, radius, kind)
	if sfx:
		sfx.play("explosions/grenade", at, -2.0)
	var s: Slot = (_event.source if _event != null else slots[slot]) if slot >= 0 else null
	if _boss_active and boss.hit_test(at, radius):
		var offset := boss.global_position - at
		var falloff := 1.0 - clampf(offset.length() / (radius + Boss.RADIUS), 0.0, 1.0) * 0.5
		if slot >= 0:
			_hit_boss(slot, dmg * falloff, offset.normalized(), boss.global_position, "explosion")
		else:
			_damage_boss(-1, dmg * falloff, offset.normalized(), boss.global_position, "grenade")
	var prev_override := horde.death_override
	if s == null:
		horde.death_override = Gore.Death.GIBS # граната рвёт на куски, даже замёрзших
	for j in horde.query_radius(at, radius):
		var d := horde.pos[j] - at
		var falloff := 1.0 - clampf(d.length() / (radius + Horde.RADIUS), 0.0, 1.0) * 0.5
		var dir := d.normalized() if d.length_squared() > 0.01 else Vector2.from_angle(randf() * TAU)
		if s == null:
			if horde.damage(j, dmg * falloff, dir, GRENADE_KNOCK * float(bonuses.get("grenade_knock_mul", 1.0)), WeaponDefs.Ammo.STANDARD, false, horde.pos[j], true) and effects:
				effects.blood_hit(horde.pos[j], dir, false)
		elif _hit_enemy(slot, j, dmg * falloff, dir, horde.pos[j], s.stats["knock"] * 1.5, true, gibs, first_round):
			if depth < 2 and s.mod_rank(WeaponDefs.Module.DETONATOR) > 0:
				_on_kill(slot, j, dir, depth)
	horde.death_override = prev_override


func _ammo_sparks(ammo: int, p: Vector2, dir: Vector2) -> void:
	var color: Color
	match ammo:
		WeaponDefs.Ammo.INCENDIARY:
			color = Color(1.0, 0.55, 0.1)
		WeaponDefs.Ammo.CRYO:
			color = Color(0.75, 0.95, 1.0)
		WeaponDefs.Ammo.EXPANSIVE:
			color = Color(1.0, 0.9, 0.6)
		_:
			return
	for k in 2:
		effects.emit(p, dir.rotated(randf_range(-1.0, 1.0)) * randf_range(30.0, 90.0), randf_range(0.1, 0.25), color, 1.0, 6.0)


# --- рейлган ----------------------------------------------------------------------------------

func _fire_rail(i: int, muzzle: Vector2, dir: Vector2) -> void:
	var s := slots[i]
	var n: int = s.stats["proj"]
	for k in n:
		var a := dir.angle() + (k - (n - 1) * 0.5) * deg_to_rad(15.0)
		_rail_beam(i, muzzle, Vector2.from_angle(a), s.stats["damage"] * s.shot_mult, int(s.mod_value(WeaponDefs.Module.RICOCHET, [1, 2, 3])), PackedInt32Array())


func _rail_beam(i: int, from: Vector2, dir: Vector2, dmg: float, bounces: int, hit_uids: PackedInt32Array) -> void:
	var s := slots[i]
	var length: float = s.stats["range"]
	var half: float = s.stats["width"] * 0.5 + Horde.RADIUS
	var to := from + dir * length
	if obstacles:
		# Рельса проходит насквозь и повреждает каждую машину на луче.
		for obstacle in obstacles.count:
			if obstacles.kind[obstacle] <= Obstacles.Kind.ACID and obstacles._segment(obstacle, from, to, 1.0) < INF:
				obstacles.damage(obstacle, dmg, s.ammo == WeaponDefs.Ammo.INCENDIARY)
	# кто на линии: сортируем по расстоянию вдоль луча
	var hits: Array = []
	if _boss_active and not hit_uids.has(BOSS_TARGET):
		var nearest := Geometry2D.get_closest_point_to_segment(boss.global_position, from, to)
		if boss.hit_test(nearest, float(s.stats["width"]) * 0.5):
			hits.append([from.distance_to(nearest), BOSS_TARGET])
	for e in horde.count:
		if horde.dead[e] == 1 or hit_uids.has(horde.uid[e]):
			continue
		var rel := horde.pos[e] - from
		var t := rel.dot(dir)
		if t < 0.0 or t > length:
			continue
		if absf(rel.cross(dir)) <= half:
			hits.append([t, e])
	hits.sort_custom(func(x, y): return x[0] < y[0] if x[0] != y[0] else (BOSS_TARGET if x[1] == BOSS_TARGET else horde.uid[x[1]]) < (BOSS_TARGET if y[1] == BOSS_TARGET else horde.uid[y[1]]))
	var last := -1
	for h in hits:
		var e: int = h[1]
		if e == BOSS_TARGET:
			hit_uids.append(BOSS_TARGET)
			if last == -1 and s.mod_rank(WeaponDefs.Module.SPLIT) > 0:
				_spawn_shards(i, boss.global_position, dir, dmg, BOSS_TARGET)
			_hit_boss(i, dmg, dir, boss.global_position, "rail")
			last = BOSS_TARGET
			continue
		if horde.dead[e] == 1:
			continue
		hit_uids.append(horde.uid[e])
		var at := horde.pos[e]
		if last == -1 and s.mod_rank(WeaponDefs.Module.SPLIT) > 0:
			_spawn_shards(i, at, dir, dmg, horde.uid[e])
		if _hit_enemy(i, e, dmg, dir, at, s.stats["knock"], false, s.shot_gibs, s.mag == int(s.stats["mag"]), true):
			_on_kill(i, e, dir, 0)
		last = e
	var color := Color(0.6, 0.95, 1.0) if s.prototype == 1 else Color(0.55, 0.85, 1.0)
	if s.shot_charged:
		color = Color(1.0, 0.72, 0.35) # усиленный луч «Копья» горячий
	_beams.append([from, to, s.stats["width"], 0.0, color])
	# рикошет: луч перескакивает с последней цели на ближайшую новую
	if bounces > 0 and last != -1:
		var at := _target_position(last)
		var next := _nearest_target(at, 160.0, hit_uids)
		if next != -1:
			_rail_beam(i, at, (_target_position(next) - at).normalized(), dmg * 0.7, bounces - 1, hit_uids)


# --- гранатомёт --------------------------------------------------------------------------------

func _fire_grenades(i: int, muzzle: Vector2, target: Vector2) -> void:
	var s := slots[i]
	var n: int = s.stats["proj"]
	var flags := (G_LAST if s.shot_gibs else 0) | (G_STICKY if s.trait_id == "sticky" else 0) | (G_FIRST if s.mag == int(s.stats["mag"]) else 0)
	for k in n:
		var t := target + (Vector2(randf_range(-14, 14), randf_range(-14, 14)) if k > 0 else Vector2.ZERO)
		if player.manual_aim and k > 0:
			t = player.global_position + (t - player.global_position).limit_length(float(s.stats["range"]))
		_spawn_grenade(muzzle, t, i, s.stats["damage"] * s.shot_mult, s.stats["radius"], false, flags)


func _spawn_grenade(from: Vector2, to: Vector2, slot: int, dmg: float, radius: float, small: bool, flags := 0) -> void:
	if obstacles:
		to = obstacles.free_point(to, 3.0)
	var d := to - from
	var spd: float = slots[slot].stats["speed"] if not small else 180.0
	_gpos.append(from)
	_gvel.append(d.normalized() * spd)
	_gleft.append(d.length())
	_gslot.append(slot)
	_gdmg.append(dmg)
	_grad.append(radius)
	_gsmall.append(1 if small else 0)
	_gflag.append(flags)
	_gcontext.append(_event)


func _update_grenades(delta: float) -> void:
	var i := _gpos.size() - 1
	while i >= 0:
		var step := _gvel[i].length() * delta
		_gleft[i] -= step
		_gpos[i] += _gvel[i] * delta
		var touched := horde.find_hit(_gpos[i], 2.0) != -1
		if _boss_active and boss.hit_test(_gpos[i], 2.0):
			touched = true
		if _gleft[i] <= 0.0 or touched:
			var parent := _event
			_event = _gcontext[i]
			var at := _gpos[i]
			var slot := _gslot[i]
			if _gflag[i] & G_STICKY != 0 and _gsmall[i] == 0:
				_stick(at, slot, _gdmg[i], _grad[i], _gflag[i])
			else:
				_detonate(at, slot, _gdmg[i], _grad[i], _gsmall[i] == 1, _gflag[i])
			_gpos.remove_at(i)
			_gvel.remove_at(i)
			_gleft.remove_at(i)
			_gslot.remove_at(i)
			_gdmg.remove_at(i)
			_grad.remove_at(i)
			_gsmall.remove_at(i)
			_gflag.remove_at(i)
			_gcontext.remove_at(i)
			_event = parent
		i -= 1


## Взрыв гранаты ствола; сплит у гранатомёта — кассета мини-гранат.
func _detonate(at: Vector2, slot: int, dmg: float, radius: float, small: bool, flags: int) -> void:
	if obstacles:
		at = obstacles.free_point(at, 3.0)
	explode(at, dmg, radius, slot, 0, flags & G_LAST != 0, flags & G_FIRST != 0)
	var s := _event.source if _event != null else slots[slot]
	if not small and s.mod_rank(WeaponDefs.Module.SPLIT) > 0:
		var n := 2 + s.mod_rank(WeaponDefs.Module.SPLIT)
		var parent := _event
		if _event: _event = _event.child("cluster")
		for k in n:
			var to := at + Vector2.from_angle(TAU * k / n + randf() * 0.5) * randf_range(20.0, 34.0)
			_spawn_grenade(at, to, slot, dmg * 0.4, radius * 0.6, true)
		_event = parent


## «Улей»: граната прилипает к врагу (или боссу, иначе к земле) и рвётся через STICKY_FUSE.
func _stick(at: Vector2, slot: int, dmg: float, radius: float, flags: int) -> void:
	var carrier := 0
	var off := Vector2.ZERO
	var e := horde.find_hit(at, 2.0)
	if e != -1:
		carrier = horde.uid[e]
		off = at - horde.pos[e]
	elif _boss_active and boss.hit_test(at, 2.0):
		carrier = BOSS_TARGET
		off = at - boss.global_position
	_xpos.append(at)
	_xuid.append(carrier)
	_xoff.append(off)
	_xt.append(WeaponDefs.STICKY_FUSE)
	_xslot.append(slot)
	_xdmg.append(dmg)
	_xrad.append(radius)
	_xflag.append(flags)
	_xcontext.append(_event)


func _update_stuck(delta: float) -> void:
	var i := _xpos.size() - 1
	while i >= 0:
		var carrier := _xuid[i]
		if carrier == BOSS_TARGET:
			if _boss_active:
				_xpos[i] = boss.global_position + _xoff[i]
		elif carrier > 0:
			var e := horde.uid.find(carrier)
			if e >= 0 and e < horde.count and horde.dead[e] == 0:
				_xpos[i] = horde.pos[e] + _xoff[i]
			else:
				_xuid[i] = 0 # носитель погиб: граната лежит на месте
		_xt[i] -= delta
		if _xt[i] <= 0.0:
			var parent := _event
			_event = _xcontext[i]
			var at := _xpos[i]
			var slot := _xslot[i]
			var dmg := _xdmg[i]
			var radius := _xrad[i]
			var flags := _xflag[i]
			var last := _xpos.size() - 1
			_xpos[i] = _xpos[last]
			_xuid[i] = _xuid[last]
			_xoff[i] = _xoff[last]
			_xt[i] = _xt[last]
			_xslot[i] = _xslot[last]
			_xdmg[i] = _xdmg[last]
			_xrad[i] = _xrad[last]
			_xflag[i] = _xflag[last]
			_xcontext[i] = _xcontext[last]
			_xpos.resize(last)
			_xuid.resize(last)
			_xoff.resize(last)
			_xt.resize(last)
			_xslot.resize(last)
			_xdmg.resize(last)
			_xrad.resize(last)
			_xflag.resize(last)
			_xcontext.resize(last)
			_detonate(at, slot, dmg, radius, false, flags)
			_event = parent
		i -= 1


# --- отрисовка ------------------------------------------------------------------------------

func _age_fx(delta: float) -> void:
	var k := _beams.size() - 1
	while k >= 0:
		_beams[k][3] += delta
		if _beams[k][3] > 0.14:
			_beams.remove_at(k)
		k -= 1
	var f := _flashes.size() - 1
	while f >= 0:
		_flashes[f][2] -= delta
		if _flashes[f][2] <= 0.0:
			_flashes.remove_at(f)
		elif player != null and _flashes[f].size() > 9 and int(_flashes[f][9]) < slots.size():
			var slot: int = _flashes[f][9]
			_flashes[f][0] = gun_point(slot, slots[slot].muzzle)
			_flashes[f][1] = gun_angle(slot)
		f -= 1


func _draw() -> void:
	for fx: Array in _link_fx:
		var from: Vector2 = fx[0]
		var to: Vector2 = fx[1]
		var t := 1.0 - float(fx[2]) / 0.32
		var dir := (to - from).normalized()
		var p := from.lerp(to, t)
		# Короткая передача к оружию; расход раскрывается веером, без постоянного луча.
		for j in 3:
			var a := dir.rotated((j - 1) * 0.22) if fx[3] else dir
			var tip := (from + a * (20.0 + t * 42.0)) if fx[3] else p - dir * j * 4.0
			draw_line(tip - a * 5.0, tip, Color("1c211e"), 3.0)
			draw_line(tip - a * 4.0, tip, Color("e1cf9f"), 1.4)
	for b in bullet_count:
		var p := _bpos[b]
		var tail := _bvel[b].normalized() * (3.0 if _bflags[b] & F_SHARD else 5.0)
		if _bslot[b] < slots.size() and slots[_bslot[b]].base == WeaponDefs.Base.CROSSBOW:
			tail = _bvel[b].normalized() * 11.0
			draw_line(p - tail, p, Color("b8b49a"), 0.8)
			draw_line(p - tail, p - tail * 0.72 + tail.orthogonal().normalized() * 1.6, Color("d0cdb8"), 0.8)
			draw_line(p, p - tail * 0.16, Color("e3e0d2"), 1.2)
			continue
		var c := Color(1.0, 0.85, 0.45, 0.9) if _bflags[b] & F_CHAIN == 0 else Color(1.0, 0.4, 0.3, 0.9)
		draw_line(p - tail, p, c, 1.0)
	for g in _gpos.size():
		draw_rect(Rect2(_gpos[g] - Vector2(1.5, 1.5), Vector2(3, 3)), Color(0.25, 0.28, 0.2))
		draw_rect(Rect2(_gpos[g] - Vector2(0.5, 0.5), Vector2(1, 1)), Color(1.0, 0.4, 0.2))
	for x in _xpos.size():
		# прилипшая граната мигает всё чаще
		var left := _xt[x] / WeaponDefs.STICKY_FUSE
		draw_rect(Rect2(_xpos[x] - Vector2(1.5, 1.5), Vector2(3, 3)), Color(0.25, 0.28, 0.2))
		if int(left * 14.0) % 2 == 0 or left < 0.25:
			draw_rect(Rect2(_xpos[x] - Vector2(0.5, 0.5), Vector2(1, 1)), Color(1.0, 0.25, 0.15))
	for beam: Array in _beams:
		var k: float = 1.0 - beam[3] / 0.14
		var c: Color = beam[4]
		draw_line(beam[0], beam[1], Color(c, 0.35 * k), beam[2] * 1.8 * k + 1.0)
		draw_line(beam[0], beam[1], Color(1, 1, 1, 0.9 * k), maxf(beam[2] * 0.35 * k, 0.6))
	# Дым остаётся в обычном смешивании, огонь — в общем аддитивном слое.
	for fl: Array in _flashes:
		if fl[3] != WeaponDefs.Base.SNIPER and fl[3] != WeaponDefs.Base.LAUNCHER:
			continue
		var age: float = 1.0 - fl[2] / fl[8]
		draw_set_transform(fl[0], fl[1])
		var smoke := Color(0.58, 0.59, 0.60, 0.12 * (1.0 - age))
		if fl[3] == WeaponDefs.Base.SNIPER:
			draw_arc(Vector2(4.0 + age * 3.0, 0), 3.0 + age * 5.0, 0.2, TAU - 0.5, 20, smoke, 0.7 + age)
		else:
			for j in 4:
				PixelArt.draw_dot(self, Vector2(3.0 + j * 1.6 + age * 3.0, sin(j * 2.0) * 2.0), 2.0 + age * 3.0, smoke)
		draw_set_transform(Vector2.ZERO)


func _draw_flashes() -> void:
	for fl: Array in _flashes:
		var tex := _flash_tex[int(fl[3]) * 4 + int(fl[7])]
		var tint: Color = fl[4]
		# Альфа у края уже в текстуре; затухает только последний короткий кадр.
		tint.a *= minf(1.0, float(fl[2]) / 0.008)
		_flash_layer.draw_set_transform(fl[0], fl[1] + fl[6], Vector2.ONE * PixelArt.ART_SCALE * float(fl[5]))
		_flash_layer.draw_texture(tex, Vector2(-3.0, -tex.get_height() * 0.5), tint)
	_flash_layer.draw_set_transform(Vector2.ZERO)
