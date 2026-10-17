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

## Один ствол игрока.
class Slot:
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
	var shot_mult := 1.0 # множитель урона текущего выстрела (заряд, последний патрон)
	var shot_gibs := false # текущий выстрел рвёт на гибы (последний патрон)
	var shot_charged := false
	var last_damage := 0.0 # урон снаряда последнего выстрела до крита (для тестов)

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
var horde: Horde
var boss: Boss
var firing_enabled := true
const BOSS_TARGET := -2 # отдельный uid, индексы орды остаются прежними
const MANUAL_TARGET := -3 # точка игрока, поиск врага не нужен
var _boss_active := false
var boss_damage := PackedFloat64Array([0, 0, 0, 0, 0, 0, 0, 0])
var boss_sources: Dictionary = {}
var _burn_left := PackedFloat32Array([0, 0, 0, 0])
var _burn_dps := PackedFloat32Array([0, 0, 0, 0])
var _burn_tick := 0.0
var effects: Effects
var floor_decals: FloorDecals
var sfx: Sfx
const GUN_IDS := ["rifle", "shotgun", "rail", "launcher", "pistol", "revolver", "smg", "sniper"]
const RECOIL := [0.8, 1.8, 1.4, 1.5, 0.55, 1.25, 0.25, 2.5]
var shots := PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0])
var damage_dealt := 0.0
var passives := {} # WeaponDefs.Passive → уровень (заполняет прогрессия)
var bonuses := {} # дерево класса на этот забег (Meta.run_bonuses())

var slots: Array[Slot] = []
var bullet_count := 0

# пули: позиция, скорость, жизнь, урон, ствол, пробивание, отскоки, флаги, uid последней цели
const F_SHARD := 1 # осколок сплита: сам не делится
const F_CHAIN := 2 # снаряд цепи
const F_LAST := 4 # пуля последнего патрона: убийство всегда рвёт на гибы
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

# прилипшие гранаты: позиция, uid носителя (0 — земля, BOSS_TARGET — босс), смещение, время до взрыва
var _xpos := PackedVector2Array()
var _xuid := PackedInt32Array()
var _xoff := PackedVector2Array()
var _xt := PackedFloat32Array()
var _xslot := PackedInt32Array()
var _xdmg := PackedFloat32Array()
var _xrad := PackedFloat32Array()
var _xflag := PackedByteArray()

# эффекты для отрисовки: лучи [от, до, ширина, время, цвет], взрывы [центр, радиус, время]
var _beams: Array = []
var _blasts: Array = []
# Вспышек мало (до четырёх стволов); один общий аддитивный слой.
const FLASH_KINDS := ["rifle", "shotgun", "rifle", "launcher", "small", "small", "small", "sniper"]
var _flashes: Array = [] # [позиция, угол, время, основа, тинт, масштаб, поворот, вариант, жизнь]
var _flash_tex: Array[Texture2D] = []
var _flash_layer: Node2D
var _flash_drawn := false
var tails := PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0])
var _aim_hold := 0.0


func _ready() -> void:
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
	add_weapon(WeaponDefs.Base.RIFLE)


# --- управление стволами -----------------------------------------------------------

## model "" — избранная модель категории (Meta.model_for).
func add_weapon(base: int, model := "") -> void:
	var s := Slot.new()
	s.set_model(model if model != "" else Meta.model_for(base))
	slots.append(s)
	refresh(slots.size() - 1)
	s.mag = s.stats["mag"]


func has_base(base: int) -> bool:
	for s in slots:
		if s.base == base:
			return true
	return false


## Пересчёт статов ствола (CONTRACTS §11): основа → переопределения модели → уровни L2–L5 →
## мастерская модели → дерево класса → пассивки → модули, затем проверка прототипа.
func refresh(i: int) -> void:
	var s := slots[i]
	var st := WeaponDefs.model_stats(s.model, s.level)
	var step: Dictionary = Meta.WORKSHOP_STEP
	st["damage"] *= (1.0 + step["damage"] * Meta.workshop_level(s.model, "damage")) * float(bonuses.get("damage_mul", 1.0))
	st["rate"] *= 1.0 + step["rate"] * Meta.workshop_level(s.model, "rate")
	st["mag"] = ceili(float(st["mag"]) * (1.0 + step["mag"] * Meta.workshop_level(s.model, "mag")) * float(bonuses.get("mag_mul", 1.0)) - 0.0001)
	st["reload"] *= (1.0 + step["reload"] * Meta.workshop_level(s.model, "reload")) * float(bonuses.get("reload_mul", 1.0))
	st["crit"] += float(bonuses.get("crit_add", 0.0))
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
	bullet_count = 0
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

func _physics_process(delta: float) -> void:
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
		return
	_aim_hold -= delta
	if _aim_hold <= 0.0 and not player.manual_aim:
		player.aim_dir = Vector2.ZERO
	if Input.is_action_just_pressed("reload"):
		reload_all()
	for i in slots.size():
		_update_slot(i, delta)


func _update_slot(i: int, delta: float) -> void:
	var s := slots[i]
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
				effects.casing(player.global_position, s.rack_dir, "shell" if s.base == WeaponDefs.Base.SHOTGUN else "brass_rifle")
	if s.reloading:
		var before := s.reload_t / float(s.stats["reload"])
		s.reload_t += delta
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
	var target := MANUAL_TARGET if player.manual_aim else _nearest_target(player.global_position, s.stats["range"])
	if target == -1:
		return
	if s.trait_id == "fan":
		_start_fan(s)
		_update_fan(i, s, 0.0)
		return
	_fire_shot(i, s, target)
	# ППШ и очереди сохраняют дробную часть интервала: 14/с не округляется до 12/с на физике 60 Гц.
	var carry := -delta if s.base == WeaponDefs.Base.SMG or s.trait_id == "burst3" else 0.0
	s.cooldown = maxf(s.cooldown, carry) + _shot_interval(s)


## Пауза до следующего выстрела с учётом «Шквала огня»; у burst3 — внутри очереди короткая, после неё длинная.
func _shot_interval(s: Slot) -> float:
	var rate: float = s.stats["rate"] * _streak_mult(s)
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
	_burst_shot(s, target if target < -1 else horde.uid[target])
	var target_pos := player.aim_point if target == MANUAL_TARGET else _target_position(target)
	var dir := player.aim_dir if target == MANUAL_TARGET else (target_pos - origin).normalized()
	if target == MANUAL_TARGET:
		target_pos = origin + (target_pos - origin).limit_length(float(s.stats["range"]))
	player.aim_dir = dir
	_aim_hold = 0.4
	# множитель урона: усиленный выстрел «Копья» и последний патрон магазина (дерево класса)
	s.shot_mult = 1.0
	s.shot_charged = false
	s.shot_gibs = false
	if s.trait_id == "kill_charge" and s.charged:
		s.charged = false
		s.shot_charged = true
		s.shot_mult *= WeaponDefs.KILL_CHARGE_MULT
	if s.mag == 1 and bool(bonuses.get("last_round", false)):
		s.shot_mult *= LAST_ROUND_MULT
		s.shot_gibs = true
	s.last_damage = float(s.stats["damage"]) * s.shot_mult
	player.kick(RECOIL[s.base])
	if camera:
		camera.kick(dir, RECOIL[s.base])
		if s.base in [WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.SNIPER]:
			camera.shake(0.6 if s.base == WeaponDefs.Base.SHOTGUN else 0.9)
	var muzzle := origin + dir * 9.0 - dir.orthogonal() * 1.5
	match s.base:
		WeaponDefs.Base.RIFLE, WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.PISTOL, WeaponDefs.Base.REVOLVER, WeaponDefs.Base.SMG, WeaponDefs.Base.SNIPER:
			_fire_bullets(i, muzzle, dir)
		WeaponDefs.Base.RAIL:
			_fire_rail(i, muzzle, dir)
		WeaponDefs.Base.LAUNCHER:
			_fire_grenades(i, muzzle, target_pos)
	var tint := Color.WHITE
	if s.base == WeaponDefs.Base.RAIL:
		tint = Color(0.45, 0.85, 1.0)
	if s.ammo == WeaponDefs.Ammo.CRYO:
		tint = Color(0.45, 0.8, 1.0)
	elif s.ammo == WeaponDefs.Ammo.INCENDIARY:
		tint = Color(1.0, 0.36, 0.1)
	var life := randf_range(0.04, 0.06)
	_flashes.append([muzzle, dir.angle(), life, s.base, tint, randf_range(0.85, 1.15), randf_range(-PI / 18.0, PI / 18.0), randi() % 4, life])
	_flash_layer.queue_redraw()
	_sound(s, "shot")
	shots[s.base] += 1
	if effects:
		var light_tint := Color(1.0, 0.78, 0.45) if tint == Color.WHITE else tint
		effects.flash_light(muzzle, light_tint, 100.0 + RECOIL[s.base] * 32.0, 0.9 + RECOIL[s.base] * 0.3, life)
		var smoke := Color(0.48, 0.49, 0.50, 0.1)
		effects.emit(muzzle + dir * 3.0, dir * 9.0 + Vector2(0, -6), 0.45, smoke, 3.4, 2.0)
		if s.heat > 8.0:
			effects.emit(muzzle, Vector2(0, -14), 0.7, Color(0.5, 0.5, 0.48, 0.2), 3.5, 1.0)
	# у «Ровного боя» и очередей по 3 разброс не растёт
	if s.base in [WeaponDefs.Base.RIFLE, WeaponDefs.Base.SMG] and s.trait_id != "steady" and s.trait_id != "burst3":
		s.heat = minf(s.heat + (1.0 if s.base == WeaponDefs.Base.RIFLE else 1.4), 16.0 if s.base == WeaponDefs.Base.RIFLE else 26.0)
	s.since_shot = 0.0
	if s.base in [WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.SNIPER]:
		if s.trait_id == "slamfire":
			if effects:
				effects.casing(origin, dir, "shell") # автомат без помпы: гильза сразу
		else:
			s.rack_t = 0.25 if s.base == WeaponDefs.Base.SHOTGUN else 0.3
			s.rack_dir = dir
	elif s.base in [WeaponDefs.Base.RIFLE, WeaponDefs.Base.PISTOL, WeaponDefs.Base.SMG] and effects:
		effects.casing(origin, dir, "brass_rifle" if s.base == WeaponDefs.Base.RIFLE else "brass_small")
	s.mag -= 1
	if s.mag <= 0:
		_sound(s, "dry")
		_start_reload(s)
	shot_fired.emit(s.base)


## Веер ковбоя: барабан целиком по разным целям за FAN_TIME (темп сокращает его).
func _start_fan(s: Slot) -> void:
	s.fan_left = s.mag
	s.fan_hit.clear()
	s.fan_interval = WeaponDefs.FAN_TIME * WeaponDefs.FAN_BASE_RATE / (float(s.stats["rate"]) * _streak_mult(s)) / float(maxi(s.mag, 1))
	s.fan_t = 0.0


func _update_fan(i: int, s: Slot, delta: float) -> void:
	s.fan_t -= delta
	if s.fan_t > 0.0:
		return
	var target := MANUAL_TARGET if player.manual_aim else _fan_target(s)
	if target == -1:
		s.fan_left = 0 # цели кончились: оставшиеся патроны берегутся
		return
	s.fan_left -= 1
	s.fan_t += s.fan_interval
	_fire_shot(i, s, target)
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
	if s.base in [WeaponDefs.Base.PISTOL, WeaponDefs.Base.RIFLE, WeaponDefs.Base.SMG]:
		_sound(s, "mag_out")
		if effects:
			effects.casing(player.global_position, player.aim_dir, "mag_" + GUN_IDS[s.base])
	elif s.base == WeaponDefs.Base.REVOLVER:
		_sound(s, "cyl_open")


## Хвост принадлежит завершившейся очереди, счётчик сбрасывается до проигрывания.
func _end_burst(s: Slot) -> void:
	var count := s.burst_shots
	s.burst_shots = 0
	s.burst_target = -1
	if count >= 3:
		tails[s.base] += 1
		_sound(s, "tail")


func _burst_shot(s: Slot, target_uid: int) -> void:
	if (s.base != WeaponDefs.Base.RIFLE and s.base != WeaponDefs.Base.SMG) or s.trait_id == "burst3":
		return # очереди по 3 хвоста не дают
	if s.burst_target != target_uid:
		_end_burst(s)
	s.burst_target = target_uid
	s.burst_shots += 1


## Голос по MODELS[model]["gun"]; нет такого файла (звуки моделей делает A3) — голос серийной модели.
func sound_id(s: Slot, action: String) -> String:
	var id := "weapons/" + s.gun + "/" + action
	if sfx and not sfx.has(id):
		id = "weapons/" + GUN_IDS[s.base] + "/" + action
	return id


func _sound(s: Slot, action: String) -> void:
	if sfx:
		# A2 уже сводит механику на ~12 дБ тише выстрела.
		sfx.play(sound_id(s, action))


## Пороговые события без таймеров-нод. Тактическая помпа вставляет только недостающие патроны.
func _reload_actions(s: Slot, before: float, after: float) -> void:
	if s.base in [WeaponDefs.Base.PISTOL, WeaponDefs.Base.RIFLE, WeaponDefs.Base.SMG]:
		if before < 0.7 and after >= 0.7:
			_sound(s, "mag_in")
		if before < 1.0 and after >= 1.0:
			_sound(s, "rack")
	elif s.base == WeaponDefs.Base.REVOLVER:
		if before < 0.15 and after >= 0.15:
			_sound(s, "eject")
			if effects:
				for k in s.reload_missing:
					effects.casing(player.global_position, Vector2.from_angle(TAU * k / maxf(1.0, s.reload_missing)), "brass_small")
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


# --- пули ------------------------------------------------------------------------------------

func _fire_bullets(i: int, muzzle: Vector2, dir: Vector2) -> void:
	var s := slots[i]
	var st := s.stats
	var n: int = st["proj"]
	var spread := deg_to_rad(float(st["spread"]) + s.heat)
	var pierce := int(s.mod_value(WeaponDefs.Module.PIERCE, [2, 4, 6])) + int(st.get("pierce", 0))
	var bounce := int(s.mod_value(WeaponDefs.Module.RICOCHET, [1, 2, 3]))
	for k in n:
		var a := dir.angle()
		if s.base == WeaponDefs.Base.SHOTGUN:
			a += randf_range(-spread, spread) * 0.5
		else:
			# автомат: несколько пуль идут небольшим веером
			a += (k - (n - 1) * 0.5) * deg_to_rad(5.0) + randf_range(-spread, spread) * 0.5
		var spd: float = st["speed"] * (randf_range(0.85, 1.1) if s.base == WeaponDefs.Base.SHOTGUN else 1.0)
		_spawn_bullet(muzzle, Vector2.from_angle(a) * spd, st["range"] / spd, st["damage"] * s.shot_mult, i, pierce, bounce, F_LAST if s.shot_gibs else 0)


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
		if hit != -1:
			if not _bullet_hit(i, hit, probe):
				_remove_bullet(i)
				i -= 1
				continue
		elif _blife[i] <= 0.0:
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


func _nearest_target(at: Vector2, radius: float, exclude := PackedInt32Array()) -> int:
	var target := horde.find_nearest(at, radius) if exclude.is_empty() else horde.find_nearest_except(at, radius, exclude)
	if _boss_active and not exclude.has(BOSS_TARGET):
		var distance := at.distance_squared_to(boss.global_position)
		if distance <= radius * radius and (target == -1 or distance < at.distance_squared_to(horde.pos[target]) * 2.25):
			return BOSS_TARGET
	return target


## Попадание пули. Возвращает true, если пуля летит дальше (пробила/отскочила).
func _bullet_hit(b: int, e: int, at: Vector2) -> bool:
	var slot := _bslot[b]
	var s := slots[slot] if slot < slots.size() else slots[0]
	var dir := _bvel[b].normalized()
	var is_boss := e == BOSS_TARGET
	var source := "chain" if _bflags[b] & F_CHAIN else ("shard" if _bflags[b] & F_SHARD else "bullet")
	var killed := _hit_boss(slot, _bdmg[b], dir, at, source) if is_boss else _hit_enemy(slot, e, _bdmg[b], dir, at, s.stats["knock"], false, _bflags[b] & F_LAST != 0)
	var uid := BOSS_TARGET if is_boss else horde.uid[e]
	_blast[b] = uid
	# сплит: осколки веером (сами не делятся)
	if _bflags[b] & F_SHARD == 0 and s.mod_rank(WeaponDefs.Module.SPLIT) > 0:
		_spawn_shards(slot, at, dir, _bdmg[b], uid)
	if killed and not is_boss:
		_on_kill(slot, e, dir, _bdepth[b])
	if _bpierce[b] > 0:
		_bpierce[b] -= 1
		_bdmg[b] *= 1.2 if s.mod_rank(WeaponDefs.Module.PIERCE) >= 3 else 0.8
		return true
	if _bbounce[b] > 0:
		var exclude := PackedInt32Array([uid])
		var next := _nearest_target(at, 120.0, exclude)
		if next != -1:
			_bbounce[b] -= 1
			_bdmg[b] *= 0.7
			_bvel[b] = (_target_position(next) - at).normalized() * _bvel[b].length()
			_blife[b] = maxf(_blife[b], 0.4)
			return true
	return false


func _spawn_shards(slot: int, at: Vector2, dir: Vector2, dmg: float, skip_uid: int) -> void:
	var s := slots[slot]
	var n := int(s.mod_value(WeaponDefs.Module.SPLIT, [3, 4, 5], 1.0)) + (1 if s.module(WeaponDefs.Module.SPLIT)["rare"] else 0)
	var k: float = [0.35, 0.4, 0.45][s.mod_rank(WeaponDefs.Module.SPLIT) - 1]
	for j in n:
		var a := dir.angle() + (j - (n - 1) * 0.5) * 0.45
		_spawn_bullet(at, Vector2.from_angle(a) * SHARD_SPEED, 0.25, dmg * k, slot, 0, 0, F_SHARD)
		_blast[bullet_count - 1] = skip_uid


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


# --- попадание: патроны ------------------------------------------------------------------

## Крит и боеприпасы босса; крио даёт обычный урон, не замораживает босса.
func _hit_boss(slot: int, dmg: float, dir: Vector2, at: Vector2, source: String) -> bool:
	var s := slots[slot]
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
	var killed := _damage_boss(slot, dmg, dir, at, source)
	if s.ammo == WeaponDefs.Ammo.EXPANSIVE and source != "explosion" and (not killed or rank >= 3):
		var radius := 16.0 if rank < 2 else 20.0
		var splash: float = [0.3, 0.45, 0.45][rank - 1] * rare
		for j in horde.query_radius(at, radius):
			horde.damage(j, dmg * splash, (horde.pos[j] - at).normalized(), 30.0, s.ammo, false, horde.pos[j], true)
	return killed


func _damage_boss(slot: int, dmg: float, dir: Vector2, at: Vector2, source: String) -> bool:
	var before := boss.hp
	var killed := boss.take_damage(dmg, dir, at)
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
func _hit_enemy(slot: int, e: int, dmg: float, dir: Vector2, at: Vector2, knockback: float, explosive := false, gibs := false) -> bool:
	var s := slots[slot]
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
	match s.ammo:
		WeaponDefs.Ammo.INCENDIARY:
			horde.ignite(e, [4.0, 6.0, 6.0][rank - 1] * rare, 3.0, [0.3, 0.3, 0.6][rank - 1], 16.0 if rank < 3 else 32.0)
		WeaponDefs.Ammo.CRYO:
			horde.chill_hit(e, 0.2, 4 if rank < 2 else 3, rank >= 3, s.prototype == 1)
	var e_pos := horde.pos[e]
	damage_dealt += minf(dmg, horde.hp[e])
	var prev_death := horde.death_override
	if gibs:
		horde.death_override = Gore.Death.GIBS # «Последний патрон» всегда рвёт на гибы
	var killed := horde.damage(e, dmg, dir, knockback, s.ammo, crit, at, explosive)
	horde.death_override = prev_death
	if effects:
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
	var s := slots[slot]
	var at := horde.pos[e]
	match s.trait_id:
		"kill_charge":
			s.charged = true # следующий выстрел «Копья» сильнее
		"lever":
			s.cooldown = 0.0 # убийство мгновенно взводит рычаг
	if s.mod_rank(WeaponDefs.Module.DETONATOR) > 0:
		var chance := 1.0 if s.prototype == 0 else minf(s.mod_value(WeaponDefs.Module.DETONATOR, [0.25, 0.4, 0.6]), 1.0)
		if randf() < chance and depth < 3:
			var chained := s.mod_rank(WeaponDefs.Module.DETONATOR) >= 3 or s.prototype == 0
			explode(at, s.stats["damage"], 30.0 * (1.3 if s.prototype == 0 else 1.0), slot, depth + (1 if chained else 3))
	if s.mod_rank(WeaponDefs.Module.CHAIN) > 0 and depth < (3 if s.mod_rank(WeaponDefs.Module.CHAIN) >= 3 else 1):
		var next := _nearest_target(at, 80.0, PackedInt32Array([horde.uid[e]]))
		if next != -1:
			var k := minf(s.mod_value(WeaponDefs.Module.CHAIN, [0.5, 0.65, 0.8]), 1.0)
			var v := (_target_position(next) - at).normalized() * 380.0
			_spawn_bullet(at, v, 0.35, s.stats["damage"] * k, slot, 0, 0, F_CHAIN | F_SHARD, depth + 1)
			_blast[bullet_count - 1] = horde.uid[e]


## Взрыв: урон по площади, отброс, гибы. depth ограничивает цепные детонации.
## slot >= 0 — взрыв ствола (патроны, детонатор), slot = -1 — «ничей» (граната игрока):
## урон без эффектов патронов, любая смерть — гибы.
func explode(at: Vector2, dmg: float, radius: float, slot := -1, depth := 0, gibs := false) -> void:
	_blasts.append([at, radius, 0.0])
	if sfx:
		sfx.play("explosions/grenade", at, -2.0)
	if effects:
		effects.flash_light(at, Color(1.0, 0.42, 0.12), radius * 2.5, 1.6, 0.15)
	if effects:
		for k in 14:
			effects.emit(at, Vector2.from_angle(randf() * TAU) * randf_range(30.0, 160.0), randf_range(0.15, 0.4),
				Color(1.0, randf_range(0.5, 0.9), 0.2), 1.5, 5.0)
		for k in 6:
			effects.emit(at, Vector2.from_angle(randf() * TAU) * randf_range(10.0, 40.0), randf_range(0.5, 1.0),
				Color(0.2, 0.19, 0.18, 0.6), 4.0, 2.0)
	if floor_decals:
		# подпалина: лёгкая копоть, чтобы не забивать кровь
		floor_decals.stamp(PixelArt.tex("blood_%d" % (randi() % 8)), at, randf() * TAU, Color(0.07, 0.06, 0.055, 0.3), radius / 45.0)
	var s: Slot = slots[slot] if slot >= 0 else null
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
			if horde.damage(j, dmg * falloff, dir, GRENADE_KNOCK, WeaponDefs.Ammo.STANDARD, false, horde.pos[j], true) and effects:
				effects.blood_hit(horde.pos[j], dir, false)
		elif _hit_enemy(slot, j, dmg * falloff, dir, horde.pos[j], s.stats["knock"] * 1.5, true, gibs):
			if depth < 2 and s.mod_rank(WeaponDefs.Module.DETONATOR) > 0:
				_on_kill(slot, j, dir, depth)
	horde.death_override = prev_override
	var to_player := player.global_position.distance_to(at)
	if camera and to_player < 120.0:
		camera.shake(3.0 * (1.0 - to_player / 120.0))


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
	hits.sort_custom(func(x, y): return x[0] < y[0])
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
		if _hit_enemy(i, e, dmg, dir, at, s.stats["knock"], false, s.shot_gibs):
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
	var flags := (G_LAST if s.shot_gibs else 0) | (G_STICKY if s.trait_id == "sticky" else 0)
	for k in n:
		var t := target + (Vector2(randf_range(-14, 14), randf_range(-14, 14)) if k > 0 else Vector2.ZERO)
		if player.manual_aim and k > 0:
			t = player.global_position + (t - player.global_position).limit_length(float(s.stats["range"]))
		_spawn_grenade(muzzle, t, i, s.stats["damage"] * s.shot_mult, s.stats["radius"], false, flags)


func _spawn_grenade(from: Vector2, to: Vector2, slot: int, dmg: float, radius: float, small: bool, flags := 0) -> void:
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
		i -= 1


## Взрыв гранаты ствола; сплит у гранатомёта — кассета мини-гранат.
func _detonate(at: Vector2, slot: int, dmg: float, radius: float, small: bool, flags: int) -> void:
	explode(at, dmg, radius, slot, 0, flags & G_LAST != 0)
	if not small and slot < slots.size() and slots[slot].mod_rank(WeaponDefs.Module.SPLIT) > 0:
		var n := 2 + slots[slot].mod_rank(WeaponDefs.Module.SPLIT)
		for k in n:
			var to := at + Vector2.from_angle(TAU * k / n + randf() * 0.5) * randf_range(20.0, 34.0)
			_spawn_grenade(at, to, slot, dmg * 0.4, radius * 0.6, true)


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
			_xpos.resize(last)
			_xuid.resize(last)
			_xoff.resize(last)
			_xt.resize(last)
			_xslot.resize(last)
			_xdmg.resize(last)
			_xrad.resize(last)
			_xflag.resize(last)
			_detonate(at, slot, dmg, radius, false, flags)
		i -= 1


# --- отрисовка ------------------------------------------------------------------------------

func _age_fx(delta: float) -> void:
	var k := _beams.size() - 1
	while k >= 0:
		_beams[k][3] += delta
		if _beams[k][3] > 0.14:
			_beams.remove_at(k)
		k -= 1
	k = _blasts.size() - 1
	while k >= 0:
		_blasts[k][2] += delta
		if _blasts[k][2] > 0.22:
			_blasts.remove_at(k)
		k -= 1
	var f := _flashes.size() - 1
	while f >= 0:
		_flashes[f][2] -= delta
		if _flashes[f][2] <= 0.0:
			_flashes.remove_at(f)
		f -= 1


func _draw() -> void:
	for b in bullet_count:
		var p := _bpos[b]
		var tail := _bvel[b].normalized() * (3.0 if _bflags[b] & F_SHARD else 5.0)
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
	for bl: Array in _blasts:
		var k: float = bl[2] / 0.22
		var r: float = bl[1] * (0.4 + 0.6 * k)
		draw_arc(bl[0], r, 0.0, TAU, 24, Color(1.0, 0.8, 0.4, 0.8 * (1.0 - k)), 2.0)
		PixelArt.draw_dot(self, bl[0], r * 0.6 * (1.0 - k), Color(1.0, 0.85, 0.5, 0.6 * (1.0 - k)))
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
		tint.a *= minf(1.0, float(fl[2]) / 0.025)
		_flash_layer.draw_set_transform(fl[0], fl[1] + fl[6], Vector2.ONE * PixelArt.ART_SCALE * float(fl[5]))
		_flash_layer.draw_texture(tex, Vector2(-3.0, -tex.get_height() * 0.5), tint)
	_flash_layer.draw_set_transform(Vector2.ZERO)
