extends Control
## Боевой HUD оперативника Z.E.R.A. — тактический дисплей, рисуется вручную в «игровых»
## пикселях (по высоте ~360) и масштабируется целым множителем: 1080p → ×3, 720p → ×2.
## Слева сверху — здоровье и ресурсы, по центру — время и ближайшее событие, справа — убийства
## и операция, снизу — способности и четыре ствола. Акцент организации — янтарный (ACCENT),
## красный — только здоровье и опасность.
##
## Цена кадра: панели перерисовываются с частотой REDRAW_PERIOD, а прицел, указатели у края
## и дуга урона — каждый кадр на дочернем слое (Overlay). Текст — кэшированные TextLine
## (без повторной вёрстки), на тёмных панелях без обводки; все надписи рисуются пачкой в конце слоя.

const TEXT := Color(0.92, 0.91, 0.86)
const DIM := Color(0.62, 0.62, 0.58)
const ACCENT := Color(1.0, 0.74, 0.2)
const ACCENT_DIM := Color(0.62, 0.46, 0.14)
const HP_COLOR := Color(0.86, 0.17, 0.14)
const HOT := Color(1.0, 0.45, 0.25)
const COOL := Color(0.55, 0.88, 1.0)
const CREDIT_COLOR := Color(1.0, 0.82, 0.35)
const DNA_COLOR := Color(0.55, 0.9, 0.95)
const PANEL_BG := Color(0.028, 0.032, 0.038, 0.68)
const SLOT_BG := Color(0.3, 0.31, 0.34, 0.85) # светлый фон под тёмные силуэты стволов
const ICON_BG := Color(0.13, 0.14, 0.16, 0.88)
const EMPTY := Color(0.13, 0.13, 0.14, 0.9)
const FONT_SIZE := 10

const REDRAW_PERIOD := 1.0 / 30.0 # панели обновляются 30 раз в секунду, прицел — каждый кадр
const OP_Y := 44.0 # строка операции — под убийствами и серией
const SLOT_W := 116.0
const SLOT_H := 36.0
const SLOT_GAP := 4.0
const MARGIN := 6.0
const GUN_BOX := Vector2(32.0, 18.0)
const PIP_MAX := 14 # магазин больше — вместо пипсов полоса
const HP_PER_SEGMENT := 10.0
const NUM_CACHE := 2000
const LINE_CACHE_MAX := 900

const AMMO_COLORS := [Color(0.85, 0.85, 0.8), Color(1.0, 0.85, 0.5), Color(1.0, 0.55, 0.2), Color(0.6, 0.9, 1.0)]
const PASSIVE_CODES := {
	WeaponDefs.Passive.DAMAGE: "УРОН", WeaponDefs.Passive.FIRE_RATE: "ТЕМП", WeaponDefs.Passive.RELOAD: "ПЕРЗ",
	WeaponDefs.Passive.SPEED: "СКОР", WeaponDefs.Passive.HP: "БРОНЯ", WeaponDefs.Passive.PICKUP: "СБОР",
}
const PASSIVE_COLOR := Color(0.55, 0.95, 0.6)
# цвет метки модификатора операции; красный — усложняет, зелёный — помогает. Текст — CampaignCatalog.MODIFIER_INFO.
const MODIFIER_TAGS := {
	"runner_surge": Color(1.0, 0.5, 0.35), "elite_hunt": Color(1.0, 0.5, 0.35),
	"acid_rain": Color(0.7, 0.9, 0.35), "blood_frenzy": Color(1.0, 0.35, 0.3),
	"hardened_boss": Color(1.0, 0.5, 0.35), "resource_cache": Color(0.55, 0.95, 0.6),
}
const ICON_NAMES := ["star", "dash", "vest", "dna", "arrow", "skull", "container", "crate", "part", "med", "coin", "bolt"]
const POINTER_ELITES := 4 # сколько ближайших элиток показываем у края
const UNITS_PER_METER := 9.0
const SCAN_PERIOD := 0.1 # как часто ищем элитки за краем


## Подготовленная строка: вёрстка делается один раз.
class Line:
	var tl: TextLine
	var w := 0.0 # ширина в экранных пикселях
	var asc := 0.0


## Слой поверх панелей: рисуется каждый кадр (прицел, указатели, дуга урона, анонсы).
class Overlay extends Control:
	var painter: Callable

	func _draw() -> void:
		painter.call(self)


var show_debug := false
var draw_ms := 0.0 # сглаженная цена записи HUD за кадр (F3 и бенчмарк)
var operation: Dictionary = {} # операция кампании (Campaign.pending()); пусто — обычный забег

var _ci: Control # слой, который рисуется сейчас
var _over: Overlay
var _ui := 2.0
var _w := 640.0
var _h := 360.0
var _font: Font
var _icons := {} # имя → Texture2D (hud_<имя>.png)
var _grenade_icon: Texture2D
var _gun_tex := {} # модель → иконка, заранее масштабированная под текущий _ui
var _cache_ui := 0.0
var _slots: Array[Dictionary] = [] # кэш подписей и ширин по стволам
var _nums := PackedStringArray()
var _meters := PackedStringArray()
var _lines := {} # размер → {строка → Line}
var _line_count := 0
var _chip_cache := {}
# пачка надписей слоя: строка, позиция в пикселях, цвет, обводка
var _job_line: Array[Line] = []
var _job_pos := PackedVector2Array()
var _job_color := PackedColorArray()
var _job_outline := PackedByteArray()
var _segs := PackedVector2Array()
var _clock := 0.0 # время миганий; в паузе стоит
var _since_draw := 1.0
var _spent_usec := 0
var _danger := 0.0
var _heartbeat_phase := 0.0
var _connected := false
var _hp_ghost := 100.0
var _ghost_hold := 0.0
var _hurt_flash := 0.0
var _hit_angle := 0.0
var _hit_t := 0.0
var _xp_flash := 0.0
var _level_seen := 1
var _credits_seen := -1
var _credit_pop := 0
var _credit_pop_t := 0.0
var _event: Dictionary = {}
var _event_poll := 0.0
var _clock_sec := -1
var _clock_text := ""
var _event_sec := -1
var _event_count := ""
var _event_at := ""
var _cam := Transform2D.IDENTITY
var _scan_t := 0.0
# ближайшие элитки (дистанция², точка мира), обновляются раз в SCAN_PERIOD
var _elite_d := PackedFloat32Array([0, 0, 0, 0])
var _elite_p := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _elite_n := 0
var _ptr_pos := PackedVector2Array()
var _ptr_n := 0
var _op_text := ""
var _op_threat := 0
var _op_chips: Array[Array] = []

@onready var game = owner # скрипт game.gd корневой сцены


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # при паузе убираем анонс из-под экрана награды
	_font = ThemeDB.fallback_font
	for n: String in ICON_NAMES:
		_icons[n] = PixelArt.tex("hud_" + n)
	_grenade_icon = PixelArt.tex("icon_grenade")
	for i in NUM_CACHE:
		_nums.append(str(i))
	for i in 400:
		_meters.append("%d м" % i)
	_ptr_pos.resize(12)
	_segs.resize(2)
	_over = Overlay.new()
	_over.painter = _draw_overlay
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_over)
	set_operation(Campaign.pending())


## Операция кампании: имя, угроза и значки модификаторов; пустой словарь — обычный забег.
func set_operation(config: Dictionary) -> void:
	operation = config
	_op_chips.clear()
	if config.is_empty():
		_op_text = ""
		return
	_op_text = "ОП: " + str(config.get("name", config.get("region_name", "")))
	_op_threat = int(config.get("threat", 1))
	for m: String in config.get("modifiers", []):
		if MODIFIER_TAGS.has(m):
			var tag: String = CampaignCatalog.MODIFIER_INFO[m]["short"]
			_op_chips.append([tag, MODIFIER_TAGS[m], _font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x + 5.0])


func _process(delta: float) -> void:
	var cursor_mode := Input.MOUSE_MODE_HIDDEN if combat_cursor_visible() else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != cursor_mode:
		Input.mouse_mode = cursor_mode
	var player: Player = game.player
	if not get_tree().paused:
		var target := 0.0 if player.is_dead else clampf(1.0 - player.hp / player.max_hp / 0.3, 0.0, 1.0)
		_danger = lerpf(_danger, target, 1.0 - exp(-delta * 4.0))
		_heartbeat_phase = fposmod(_heartbeat_phase + delta, 1.0)
		_clock += delta
		_hurt_flash = maxf(_hurt_flash - delta * 3.0, 0.0)
		_hit_t = maxf(_hit_t - delta, 0.0)
		_xp_flash = maxf(_xp_flash - delta, 0.0)
		_credit_pop_t = maxf(_credit_pop_t - delta, 0.0)
		_ghost_hold = maxf(_ghost_hold - delta, 0.0)
		if _ghost_hold <= 0.0:
			_hp_ghost = maxf(_hp_ghost - delta * 45.0, player.hp)
		if player.hp > _hp_ghost:
			_hp_ghost = player.hp
		_event_poll -= delta
		if _event_poll <= 0.0:
			_event_poll = 0.25
			_event = game.next_event()
		_scan_t -= delta
		if _scan_t <= 0.0:
			_scan_t = SCAN_PERIOD
			_scan_elites(player)
	if not _connected:
		_connected = true
		player.hurt.connect(_on_hurt)
		_hp_ghost = player.hp
	_cam = player.get_canvas_transform()
	# цена кадра: сколько записи HUD пришлось на этот кадр (кадры без перерисовки панелей — почти ноль)
	draw_ms = lerpf(draw_ms, _spent_usec / 1000.0, 0.05)
	_spent_usec = 0
	_since_draw += delta
	if _since_draw >= REDRAW_PERIOD:
		_since_draw = 0.0
		queue_redraw()
	_over.queue_redraw()


## Дуга урона: источник — ближайший зомби в радиусе касания или босс; без источника только вспышка.
func _on_hurt(_amount: float) -> void:
	_hurt_flash = 1.0
	_ghost_hold = 0.45
	var player: Player = game.player
	var from := Vector2.INF
	var best := INF
	var boss: Boss = game.boss
	if boss.is_alive():
		var d := boss.global_position.distance_squared_to(player.global_position)
		if d < pow(Boss.RADIUS + 40.0, 2.0):
			from = boss.global_position
			best = d
	for i in game.horde.query_radius(player.global_position, 26.0):
		var d: float = game.horde.pos[i].distance_squared_to(player.global_position)
		if d < best:
			best = d
			from = game.horde.pos[i]
	if from != Vector2.INF and best > 0.01:
		_hit_angle = (from - player.global_position).angle()
		_hit_t = 1.0


## Ближайшие живые элитки, которых не видно на экране.
func _scan_elites(player: Player) -> void:
	var horde: Horde = game.horde
	var pp := player.global_position
	_elite_n = 0
	for i in horde.count:
		if horde.elite[i] == 0 or horde.dead[i] != 0:
			continue
		var wp := horde.pos[i]
		var sp := _cam * wp / _ui
		if sp.x > 4.0 and sp.x < _w - 4.0 and sp.y > 4.0 and sp.y < _h - 4.0:
			continue
		var d := wp.distance_squared_to(pp)
		var at := _elite_n
		if _elite_n < POINTER_ELITES:
			_elite_n += 1
		elif d >= _elite_d[POINTER_ELITES - 1]:
			continue
		else:
			at = POINTER_ELITES - 1
		while at > 0 and _elite_d[at - 1] > d:
			_elite_d[at] = _elite_d[at - 1]
			_elite_p[at] = _elite_p[at - 1]
			at -= 1
		_elite_d[at] = d
		_elite_p[at] = wp


func combat_cursor_visible() -> bool:
	return not get_tree().paused and not game.game_over and not game.player.is_dead


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	if get_tree().paused:
		game.player._input(event) # после меню прицел сразу следует за последним устройством


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_F3:
		show_debug = not show_debug
		_since_draw = 1.0 # сразу показать/убрать панель


# --- кадр -------------------------------------------------------------------------------

func _begin(ci: Control) -> void:
	_ci = ci
	_ui = maxf(1.0, roundf(size.y / 360.0))
	_w = size.x / _ui
	_h = size.y / _ui
	if not is_equal_approx(_cache_ui, _ui):
		_cache_ui = _ui # смена масштаба: все подготовленные подписи и иконки устарели
		_lines.clear()
		_line_count = 0
		_gun_tex.clear()
		_slots.clear()
		_chip_cache.clear()
	_job_line.clear()
	_job_pos.clear()
	_job_color.clear()
	_job_outline.clear()
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))


func _draw() -> void:
	var started := Time.get_ticks_usec()
	var player: Player = game.player
	var weapons: Weapons = game.weapons
	var prog: Progression = game.progression
	_begin(self)
	# Тот же мягкий край, что у тревоги; рисуем до HUD, центр остаётся прозрачным.
	if _danger > 0.001:
		var beat := pow(maxf(1.0 - absf(_heartbeat_phase - 0.1) / 0.1, 0.0), 2.0)
		beat += 0.65 * pow(maxf(1.0 - absf(_heartbeat_phase - 0.3) / 0.08, 0.0), 2.0)
		_ci.draw_texture_rect(game.alarm_overlay._vignette, Rect2(0, 0, _w, _h), false, Color(1, 1, 1, _danger * (0.8 + beat * 0.2)))
	var slots_top := _h - MARGIN - SLOT_H
	_draw_xp(prog)
	_draw_vitals(player, prog)
	_draw_passives(prog)
	_draw_clock()
	_draw_kills()
	_draw_operation()
	_draw_mission_banner()
	# раскладка низа: способности слева, стволы по центру; на узком экране (4:3) стволы
	# сужаются, а способности поднимаются над ними
	var n := weapons.slots.size()
	var sw := minf(SLOT_W, (_w - 2.0 * MARGIN - (n - 1) * SLOT_GAP) / n)
	var total := n * sw + (n - 1) * SLOT_GAP
	var left := MARGIN + (84.0 if player.adrenaline else 62.0) + 6.0
	var x0 := roundf((_w - total) * 0.5)
	var ability_y := _h - MARGIN
	if x0 < left:
		if left + total <= _w - MARGIN:
			x0 = left
		else:
			ability_y = slots_top - 3.0
	_draw_abilities(player, Vector2(MARGIN, ability_y))
	_draw_boss_bar(slots_top - 30.0)
	for i in n:
		_draw_slot(weapons, i, Vector2(x0 + i * (sw + SLOT_GAP), slots_top), sw)
	_draw_hints(player, slots_top)
	if show_debug:
		_draw_debug(player, weapons)
	_flush_text()
	_spent_usec += Time.get_ticks_usec() - started


func _draw_overlay(layer: Control) -> void:
	var started := Time.get_ticks_usec()
	var player: Player = game.player
	_begin(layer)
	_draw_pointers(player)
	_draw_hit_arc(player)
	# крупное объявление (пороги серий, редкие события): без дрожания и скачка размера
	var covered: bool = game.level_up.visible or game.results.visible
	if game.announce_t > 0.0 and not covered:
		var k: float = game.announce_t / 1.4
		var col: Color = game.announce_color
		col.a = clampf(k * 2.0, 0.0, 1.0)
		# пока на экране тревога (заголовок, полоса, «ТРЕВОГА ОТБИТА»), анонсы идут ниже неё
		var ay := 112.0 if game.alarm_overlay.visible else 78.0
		_text_c(_w * 0.5, ay, game.announce_text, col, 20, true)
	# радио Диспетчера: стабильная строка под часами, короткое появление и затухание
	if game.radio_t > 0.0 and not covered and not game.trader_ui.visible:
		var fade := clampf((game.RADIO_TIME - game.radio_t) / 0.25, 0.0, 1.0) * clampf(game.radio_t / 0.6, 0.0, 1.0)
		var rc: Color = game.radio_color
		rc.a = fade
		_text_c(_w * 0.5, 66.0 if game.alarm_overlay.visible else 46.0, game.radio_text, rc, 9, true)
	if combat_cursor_visible():
		_draw_crosshair(player)
	_flush_text()
	_spent_usec += Time.get_ticks_usec() - started


# --- текст ------------------------------------------------------------------------------

## Подготовленная строка нужного размера: TextLine создаётся один раз и переиспользуется.
func _line(s: String, fs: int) -> Line:
	var bucket: Dictionary = _lines.get(fs, {})
	var line: Line = bucket.get(s)
	if line == null:
		if _line_count >= LINE_CACHE_MAX: # динамические числа не должны копиться бесконечно
			_lines.clear()
			_line_count = 0
			bucket = {}
		line = Line.new()
		line.tl = TextLine.new()
		line.tl.add_string(s, _font, fs * int(_ui))
		line.w = line.tl.get_size().x
		line.asc = line.tl.get_line_ascent()
		bucket[s] = line
		_lines[fs] = bucket
		_line_count += 1
	return line


func _queue_text(line: Line, px: Vector2, c: Color, outline: bool) -> void:
	_job_line.append(line)
	_job_pos.append(px.round())
	_job_color.append(c)
	_job_outline.append(1 if outline else 0)


## Надпись с базовой линией в p (единицы HUD). Обводка нужна только на открытом фоне — не на панелях.
func _text(p: Vector2, s: String, c: Color, fs := FONT_SIZE, outline := false) -> void:
	var line := _line(s, fs)
	_queue_text(line, Vector2(p.x * _ui, p.y * _ui - line.asc), c, outline)


func _text_c(x: float, y: float, s: String, c: Color, fs := FONT_SIZE, outline := false) -> void:
	var line := _line(s, fs)
	_queue_text(line, Vector2(x * _ui - line.w * 0.5, y * _ui - line.asc), c, outline)


func _text_r(x: float, y: float, s: String, c: Color, fs := FONT_SIZE, outline := false) -> void:
	var line := _line(s, fs)
	_queue_text(line, Vector2(x * _ui - line.w, y * _ui - line.asc), c, outline)


## Ширина строки в единицах HUD.
func _text_w(s: String, fs: int) -> float:
	return _line(s, fs).w / _ui


## Все надписи слоя поверх фигур: один сброс трансформации, без вёрстки.
func _flush_text() -> void:
	var rid := _ci.get_canvas_item()
	_ci.draw_set_transform(Vector2.ZERO)
	var outline := 2 * int(_ui)
	for i in _job_line.size():
		var line := _job_line[i]
		var c := _job_color[i]
		if _job_outline[i] != 0:
			line.tl.draw_outline(rid, _job_pos[i], outline, Color(0, 0, 0, 0.8 * c.a))
		line.tl.draw(rid, _job_pos[i], c)


# --- панели и примитивы -------------------------------------------------------------------

## Тёмная панель с тонкой рамкой в 1 экранный пиксель.
func _panel(r: Rect2, edge: Color, bg := PANEL_BG) -> void:
	var px := 1.0 / _ui
	_ci.draw_rect(r, bg)
	_ci.draw_rect(Rect2(r.position + Vector2(px, px) * 0.5, r.size - Vector2(px, px)), Color(edge, edge.a * 0.45), false, px)


## Вертикальные разделители внутри r на n равных частей, одной командой.
func _dividers(r: Rect2, n: int, color: Color, width: float) -> void:
	if n < 2:
		return
	if _segs.size() != (n - 1) * 2:
		_segs.resize((n - 1) * 2)
	for j in n - 1:
		var sx := r.position.x + r.size.x * (j + 1) / n
		_segs[j * 2] = Vector2(sx, r.position.y)
		_segs[j * 2 + 1] = Vector2(sx, r.end.y)
	_ci.draw_multiline(_segs, color, width)


## Полоса из n сегментов: фон, заливка до fill с бликом и тёмные разделители.
func _seg_bar(r: Rect2, fill: float, color: Color, n: int, sep_w: float, bg := EMPTY) -> void:
	_ci.draw_rect(r, bg)
	var k := clampf(fill, 0.0, 1.0)
	if k > 0.0:
		_ci.draw_rect(Rect2(r.position, Vector2(r.size.x * k, r.size.y)), color)
		_ci.draw_rect(Rect2(r.position, Vector2(r.size.x * k, minf(2.0, r.size.y * 0.3))), Color(1, 1, 1, 0.2))
	_dividers(r, n, Color(0, 0, 0, 0.6), sep_w)


func _bar(r: Rect2, fill: float, color: Color) -> void:
	_ci.draw_rect(r, Color(0.0, 0.0, 0.0, 0.55))
	_ci.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(fill, 0.0, 1.0), r.size.y)), color)


## Целое без аллокации строки (кэш до NUM_CACHE).
func _n(v: int) -> String:
	return _nums[v] if v >= 0 and v < NUM_CACHE else str(v)


func _icon_c(name: String, center: Vector2, c := Color.WHITE, scale := 1.0) -> void:
	var t: Texture2D = _icons[name]
	var sz := t.get_size() * scale
	_ci.draw_texture_rect(t, Rect2((center - sz * 0.5).round(), sz), false, c)


## Сектор «осталось» кулдауна поверх круга: толстая дуга как залитый сектор.
func _pie(center: Vector2, r: float, fraction: float, c: Color) -> void:
	if fraction <= 0.0:
		return
	_ci.draw_arc(center, r * 0.5, -PI * 0.5, -PI * 0.5 + TAU * minf(fraction, 1.0), 24, c, r)


func _ring(center: Vector2, r: float, c: Color) -> void:
	_ci.draw_arc(center, r, 0.0, TAU, 28, c, 2.0 / _ui)


# --- вверху слева: опыт, здоровье, ресурсы ------------------------------------------------

func _draw_xp(prog: Progression) -> void:
	if prog.level != _level_seen:
		if prog.level > _level_seen:
			_xp_flash = 1.0
		_level_seen = prog.level
	var need := Progression.xp_to_next(prog.level)
	var fill := clampf(float(prog.xp) / need, 0.0, 1.0)
	var px := 1.0 / _ui
	_ci.draw_rect(Rect2(0, 0, _w, 2), Color(0.0, 0.0, 0.0, 0.7))
	_ci.draw_rect(Rect2(0, 0, _w * fill, 2), ACCENT)
	_ci.draw_rect(Rect2(0, 2, _w, px), Color(0.0, 0.0, 0.0, 0.35))
	_dividers(Rect2(0, 0, _w, 2), 10, Color(0.0, 0.0, 0.0, 0.5), px) # десять делений
	if _xp_flash > 0.0:
		var a := _xp_flash
		_ci.draw_rect(Rect2(0, 0, _w, 2.0 + 4.0 * a), Color(1.0, 0.95, 0.75, 0.75 * a))


func _draw_vitals(player: Player, prog: Progression) -> void:
	var r := Rect2(MARGIN, MARGIN + 1.0, 126, 40)
	var low := player.hp / player.max_hp <= 0.3
	var beat := 0.5 + 0.5 * sin(_clock * 9.0)
	var edge := ACCENT_DIM
	if low and not player.is_dead:
		edge = HP_COLOR.lerp(Color(1, 0.55, 0.45), beat * 0.5)
	if _hurt_flash > 0.0:
		edge = edge.lerp(Color.WHITE, _hurt_flash)
	_panel(r, edge)
	if _hurt_flash > 0.0:
		_ci.draw_rect(r, Color(HP_COLOR, 0.28 * _hurt_flash))
	var x := r.position.x
	var y := r.position.y
	_icon_c("med", Vector2(x + 10, y + 11), HP_COLOR)
	var hp_col := TEXT
	if low:
		hp_col = HP_COLOR.lerp(Color.WHITE, beat * 0.35)
	_text(Vector2(x + 19, y + 15), _n(ceili(player.hp)), hp_col, 14)
	_text(Vector2(x + 47, y + 15), "/ " + _n(ceili(player.max_hp)), DIM, 8)
	if player.max_hp > 100.5:
		_icon_c("vest", Vector2(x + 75, y + 10), Color(0.62, 0.8, 1.0))
	_text_r(x + r.size.x - 6, y + 15, "УР. " + _n(prog.level), ACCENT, 11)
	# здоровье: сегмент на каждые HP_PER_SEGMENT; светлый «призрак» — недавно потерянное
	var bar := Rect2(x + 5.0, y + 19.0, r.size.x - 10.0, 7.0)
	_ci.draw_rect(bar, Color(0.16, 0.03, 0.03, 0.9))
	var ghost := clampf(_hp_ghost / player.max_hp, 0.0, 1.0)
	_ci.draw_rect(Rect2(bar.position, Vector2(bar.size.x * ghost, bar.size.y)), Color(1.0, 0.82, 0.78, 0.85))
	var fill := clampf(player.hp / player.max_hp, 0.0, 1.0)
	_ci.draw_rect(Rect2(bar.position, Vector2(bar.size.x * fill, bar.size.y)), HP_COLOR.lerp(Color.WHITE, _hurt_flash * 0.8))
	_ci.draw_rect(Rect2(bar.position, Vector2(bar.size.x * fill, 2)), Color(1, 1, 1, 0.18))
	_dividers(bar, maxi(1, ceili(player.max_hp / HP_PER_SEGMENT)), Color(0.0, 0.0, 0.0, 0.7), 1.0)
	# кредиты и образцы
	_icon_c("coin", Vector2(x + 10, y + 33), CREDIT_COLOR)
	_text(Vector2(x + 19, y + 36), _n(prog.credits), CREDIT_COLOR, 9)
	if prog.credits != _credits_seen:
		if _credits_seen >= 0 and prog.credits > _credits_seen:
			_credit_pop = _credit_pop + (prog.credits - _credits_seen) if _credit_pop_t > 0.0 else prog.credits - _credits_seen
			_credit_pop_t = 1.2
		_credits_seen = prog.credits
	if _credit_pop_t > 0.0:
		var rise := (1.2 - _credit_pop_t) * 6.0
		_text(Vector2(x + 43, y + 36 - rise), "+" + _n(_credit_pop), Color(CREDIT_COLOR, minf(_credit_pop_t * 2.0, 1.0)), 8)
	_icon_c("dna", Vector2(x + 82, y + 33), DNA_COLOR)
	_text(Vector2(x + 90, y + 36), "~" + _n(game.dna_forecast()), DNA_COLOR, 8)


## Пассивки — компактными плашками под панелью.
func _draw_passives(prog: Progression) -> void:
	var x := MARGIN
	var y := MARGIN + 44.0
	for p in prog.passives:
		var text: String = PASSIVE_CODES[p] + " " + _n(prog.passives[p])
		var w := _chip_w(text)
		_ci.draw_rect(Rect2(x, y, w, 9), Color(0.03, 0.08, 0.04, 0.72))
		_ci.draw_rect(Rect2(x, y, 1, 9), PASSIVE_COLOR)
		_text(Vector2(x + 3, y + 7), text, PASSIVE_COLOR, 6)
		x += w + 2.0


func _chip_w(text: String) -> float:
	if not _chip_cache.has(text):
		_chip_cache[text] = _text_w(text, 6) + 6.0
	return _chip_cache[text]


# --- вверху по центру: время и событие; справа: убийства -----------------------------------

func _draw_clock() -> void:
	var cx := roundf(_w * 0.5)
	# панель не выше 27: под ней тревога рисует заголовок
	var r := Rect2(cx - 50.0, MARGIN, 100.0, 27.0)
	var ev := _event
	var urgent := false
	var remain := 0.0
	if not ev.is_empty():
		remain = float(ev["at"]) - float(game.time)
		urgent = remain <= 10.0 and remain > 0.0
	_panel(r, ACCENT if urgent and int(_clock * 4.0) % 2 == 0 else ACCENT_DIM)
	var t := int(game.time)
	if t != _clock_sec:
		_clock_sec = t
		_clock_text = "%02d:%02d" % [t / 60, t % 60]
	_text_c(cx, r.position.y + 14.0, _clock_text, TEXT, 14)
	if not ev.is_empty():
		var sec := maxi(ceili(remain), 0)
		if sec != _event_sec:
			_event_sec = sec
			_event_count = "%d:%02d" % [sec / 60, sec % 60]
			var at := int(ev["at"])
			_event_at = "%s %d:%02d" % [ev["name"], at / 60, at % 60]
		_text(Vector2(r.position.x + 5, r.position.y + 23.5), _event_at, DIM, 7)
		_text_r(r.end.x - 5, r.position.y + 23.5, _event_count, ACCENT if not urgent else HOT, 8)
	elif game.boss.is_alive():
		_text(Vector2(r.position.x + 5, r.position.y + 23.5), "ЦЕЛЬ: ОБЪЕКТ-7", Color(1.0, 0.4, 0.25), 7)
		_text_r(r.end.x - 5, r.position.y + 23.5, _n(ceili(game.boss.hp / Boss.MAX_HP * 100.0)) + "%", Color(1.0, 0.4, 0.25), 8)


func _draw_kills() -> void:
	var r := Rect2(_w - MARGIN - 84.0, MARGIN, 84.0, 17.0)
	_panel(r, ACCENT_DIM)
	_text(Vector2(r.position.x + 5, r.position.y + 12), "УБИТО", DIM, 6)
	_text_r(r.end.x - 5, r.position.y + 12, _n(game.kills), TEXT, 9)
	# мультикилл: небольшая метка слева от счётчика убийств, затухает за 1.6 с
	if game.multikill_t > 0.0:
		_text_r(r.position.x - 8.0, r.position.y + 12.0, game.multikill_text, Color(HOT, clampf(game.multikill_t * 2.0, 0.0, 1.0)), 9, true)
	if game.combo >= 5:
		var cr := Rect2(r.position.x, r.end.y + 2.0, r.size.x, 14.0)
		_panel(cr, HOT, Color(0.1, 0.03, 0.02, 0.7))
		_text(Vector2(cr.position.x + 5, cr.position.y + 11), "СЕРИЯ", Color(HOT, 0.8), 6)
		_text_r(cr.end.x - 5, cr.position.y + 11, "×" + _n(game.combo), HOT.lerp(Color.WHITE, 0.2), 10)
		# окно серии: сколько ещё можно не прерываться
		var k := clampf(game._combo_timer / game.COMBO_WINDOW, 0.0, 1.0)
		_ci.draw_rect(Rect2(cr.position.x + 1, cr.end.y + 1, (cr.size.x - 2) * k, 1), Color(HOT, 0.85))


# --- вверху справа: операция кампании -----------------------------------------------------


## Баннер операции Диспетчера в начале боя из кампании (C2): 2.5 с, поверх поля, под часами.
func _draw_mission_banner() -> void:
	if game.mission_config.is_empty() or game.mission_banner_t <= 0.0 or game.level_up.visible or game.trader_ui.visible:
		return
	var width := minf(240.0, _w - 24.0)
	var r := Rect2(roundf((_w - width) * 0.5), 96.0, width, 50.0) # ниже анонсов, не перекрывает их
	_panel(r, ACCENT)
	_text(r.position + Vector2(8, 9), "Диспетчер: операция", ACCENT_DIM, 6)
	_text(r.position + Vector2(8, 22), str(game.mission_config.get("name", "")).to_upper(), TEXT, 10, true)
	_text(r.position + Vector2(8, 33), game.mission_region, ACCENT, 7)
	_text(r.position + Vector2(8, 44), game.mission_mod_names, DIM, 7)

func _draw_operation() -> void:
	if _op_text.is_empty() and not game.mission_config.is_empty():
		set_operation(game.mission_config) # профиль боя C2 (в т.ч. --campaign-op без pending)
	if _op_text.is_empty():
		return
	var r := Rect2(_w - MARGIN - 150.0, OP_Y, 150.0, 25.0)
	_panel(r, ACCENT_DIM)
	_text(Vector2(r.position.x + 5, r.position.y + 10), _op_text, ACCENT, 8)
	_text(Vector2(r.position.x + 5, r.position.y + 21), "УГРОЗА " + WeaponDefs.ROMAN[clampi(_op_threat, 1, 5)], HP_COLOR if _op_threat >= 4 else DIM, 7)
	var x := r.end.x - 4.0
	for k in range(_op_chips.size() - 1, -1, -1):
		var chip: Array = _op_chips[k]
		var w: float = chip[2]
		x -= w
		_ci.draw_rect(Rect2(x, r.position.y + 14, w, 8), Color(0.0, 0.0, 0.0, 0.5))
		_ci.draw_rect(Rect2(x, r.position.y + 14, 1, 8), chip[1])
		_text(Vector2(x + 3, r.position.y + 21), chip[0], chip[1], 6)
		x -= 2.0


# --- внизу слева: способности -------------------------------------------------------------

func _draw_abilities(player: Player, origin: Vector2) -> void:
	var gamepad := player.aim_gamepad
	var r := 12.0
	# граната: иконка, сектор кулдауна и секунды
	var gc := Vector2(origin.x + r + 1.0, origin.y - 24.0)
	var cd := player.grenade_cd / Player.GRENADE_COOLDOWN
	PixelArt.draw_dot(_ci, gc, r, ICON_BG)
	_ring(gc, r - 0.5, ACCENT if cd <= 0.0 else ACCENT_DIM)
	_ci.draw_texture(_grenade_icon, (gc - _grenade_icon.get_size() * 0.5).round(), Color.WHITE if cd <= 0.0 else Color(1, 1, 1, 0.45))
	_pie(gc, r - 1.0, cd, Color(0, 0, 0, 0.62))
	if cd > 0.0:
		_text_c(gc.x, gc.y + 3.5, _n(ceili(player.grenade_cd)), TEXT, 9)
	_text_c(gc.x, origin.y - 1.0, "RB" if gamepad else "G", ACCENT if cd <= 0.0 else DIM, 7)
	# рывок: иконка, сектор текущего заряда, под кругом — заряды
	var dc := Vector2(gc.x + r * 2.0 + 4.0, gc.y)
	var ready := player.dash_left > 0
	PixelArt.draw_dot(_ci, dc, r, ICON_BG)
	_ring(dc, r - 0.5, COOL if ready else ACCENT_DIM)
	_icon_c("dash", dc, COOL if ready else Color(0.5, 0.58, 0.64))
	if player.dash_left < player.dash_max:
		_pie(dc, r - 1.0, player.dash_cd / player.dash_cooldown, Color(0, 0, 0, 0.55))
	var pips := player.dash_max
	var pip_x := dc.x - (pips * 5.0 - 1.0) * 0.5
	for k in pips:
		_ci.draw_rect(Rect2(pip_x + k * 5.0, origin.y - 9.0, 4, 3), COOL if k < player.dash_left else Color(0.2, 0.26, 0.3, 0.9))
	_text_c(dc.x, origin.y - 1.0, "A" if gamepad else "ПРОБЕЛ", COOL if ready else DIM, 7)
	# «Адреналин»: рывок перезаряжает стволы
	if player.adrenaline:
		var ac := Vector2(dc.x + r + 16.0, gc.y + 6.0)
		var ak := player.adrenaline_cd / Meta.ADRENALINE_COOLDOWN
		var pink := Color(1.0, 0.45, 0.7)
		PixelArt.draw_dot(_ci, ac, 8.0, ICON_BG)
		_ring(ac, 7.5, pink if ak <= 0.0 else Color(0.5, 0.25, 0.35))
		_icon_c("bolt", ac, pink if ak <= 0.0 else Color(0.6, 0.4, 0.5))
		_pie(ac, 7.0, ak, Color(0, 0, 0, 0.6))
		_text_c(ac.x, origin.y - 1.0, "АДР", pink if ak <= 0.0 else DIM, 6)


# --- внизу: стволы ------------------------------------------------------------------------

## Подписи и ширины ствола пересчитываются только при смене состава, не каждый кадр.
func _slot_info(i: int, s: Weapons.Slot) -> Dictionary:
	var sig := s.level | s.ammo << 4 | s.ammo_rank << 8 | int(s.ammo_rare) << 12 | (s.prototype + 1) << 13 | int(s.stats["mag"]) << 16
	for m in s.modules:
		sig = sig * 31 + int(m["id"]) * 8 + int(m["rank"]) * 2 + int(m["rare"])
	while _slots.size() <= i:
		_slots.append({})
	var c := _slots[i]
	if not c.is_empty() and c["sig"] == sig and c["model"] == s.model:
		return c
	c = {"sig": sig, "model": s.model}
	var proto := s.prototype >= 0
	c["name"] = s.short_name()
	c["name_col"] = Color(1.0, 0.7, 0.4) if proto else TEXT
	c["name_fs"] = 8 if _text_w(c["name"], 8) <= 34.0 else 7
	c["proto"] = WeaponDefs.PROTOTYPES[s.prototype]["name"] if proto else ""
	var mag_max := int(s.stats["mag"])
	c["mag_max"] = mag_max
	c["max_text"] = "/" + str(mag_max)
	c["max_w"] = _text_w(c["max_text"], 6) + 1.0
	var trait_id := s.trait_id
	c["trait"] = WeaponDefs.TRAITS[trait_id]["name"] if trait_id != "" else ""
	var ammo_col: Color = AMMO_COLORS[s.ammo]
	if s.ammo_rare:
		ammo_col = ammo_col.lerp(Color(0.45, 0.72, 1.0), 0.4)
	c["ammo_col"] = ammo_col
	c["level_text"] = "ур. " + str(s.level)
	_slots[i] = c
	return c


## Иконка ствола, заранее приведённая к целому масштабу экрана: на 1080p без изменений, на 720p — сжата.
func _gun_icon(model: String) -> Texture2D:
	if _gun_tex.has(model):
		return _gun_tex[model]
	var img := PixelArt.tex("gun_" + model).get_image()
	if img.is_compressed():
		img.decompress()
	var sc := minf(GUN_BOX.x * _ui / img.get_width(), GUN_BOX.y * _ui / img.get_height())
	if sc >= 1.0:
		sc = floorf(sc)
	if not is_equal_approx(sc, 1.0):
		img.resize(maxi(1, roundi(img.get_width() * sc)), maxi(1, roundi(img.get_height() * sc)),
			Image.INTERPOLATE_NEAREST if sc > 1.0 else Image.INTERPOLATE_LANCZOS)
	var t := ImageTexture.create_from_image(img)
	_gun_tex[model] = t
	return t


func _draw_slot(weapons: Weapons, i: int, p: Vector2, sw: float) -> void:
	var s: Weapons.Slot = weapons.slots[i]
	var c := _slot_info(i, s)
	var mag_max: int = c["mag_max"]
	var frac := float(s.mag) / mag_max
	var low := not s.reloading and frac <= 0.25
	var blink := 0.5 + 0.5 * sin(_clock * 10.0)
	var edge := ACCENT_DIM
	if s.reloading:
		edge = ACCENT
	elif low:
		edge = HP_COLOR
	var r := Rect2(p, Vector2(sw, SLOT_H))
	_panel(r, edge)
	# иконка: при перезарядке тускнеет, светлая часть растёт слева направо
	var box := Rect2(p + Vector2(4, 4), GUN_BOX)
	_ci.draw_rect(box, SLOT_BG)
	var tex := _gun_icon(s.model)
	var tsize := tex.get_size()
	var pos := ((box.get_center() * _ui - tsize * 0.5).floor()) / _ui
	var prog := weapons.reload_progress(i)
	if s.reloading:
		_ci.draw_texture_rect(tex, Rect2(pos, tsize / _ui), false, Color(1, 1, 1, 0.3))
		var cut := floorf(tsize.x * prog)
		if cut > 0.0:
			_ci.draw_texture_rect_region(tex, Rect2(pos, Vector2(cut, tsize.y) / _ui), Rect2(0, 0, cut, tsize.y), Color(1.0, 0.86, 0.5))
	else:
		_ci.draw_texture_rect(tex, Rect2(pos, tsize / _ui), false, Color.WHITE)
	# уровень ствола — текстом
	_text(Vector2(p.x + 6.0, p.y + 31.0), c["level_text"], DIM, 6)
	# правый блок: имя, патроны, магазин
	var x0 := p.x + 42.0
	var rx := p.x + sw - 4.0
	var rw := rx - x0
	_text(Vector2(x0, p.y + 11), c["name"], c["name_col"], c["name_fs"])
	if s.reloading:
		_text_r(rx, p.y + 11, "—", DIM, 9)
	else:
		var count_col := TEXT
		if frac <= 0.1:
			count_col = HP_COLOR.lerp(Color.WHITE, blink * 0.4)
		elif frac <= 0.25:
			count_col = HOT
		_text_r(rx, p.y + 11, c["max_text"], DIM, 6)
		_text_r(rx - float(c["max_w"]), p.y + 11, _n(s.mag), count_col, 9)
	var bar := Rect2(x0, p.y + 14.0, rw, 8.0)
	var ammo_col: Color = c["ammo_col"]
	if s.reloading:
		_bar(bar, prog, ACCENT_DIM.lerp(ACCENT, 0.5))
		_text_c(x0 + rw * 0.5, bar.position.y + 6.5, "Перезарядка", Color(1, 1, 1, 0.85), 6)
	elif mag_max <= PIP_MAX:
		_seg_bar(bar, frac, ammo_col, mag_max, 1.0)
	else:
		# большой магазин: сплошная полоса с засечками через 10 (20) патронов
		var step := 10 if mag_max <= 60 else 20
		_seg_bar(bar, frac, ammo_col, ceili(float(mag_max) / step), 1.0 / _ui)
	# строка под полосой: прототип, заряд или черта модели; детали сборки — в меню паузы
	var proto_text: String = c["proto"]
	var trait_text: String = c["trait"]
	if proto_text != "":
		_text(Vector2(x0, p.y + 31), proto_text, Color(1.0, 0.6, 0.3), 6)
	elif s.charged:
		_text(Vector2(x0, p.y + 31), "След. выстрел ×1,5", ACCENT, 6)
	elif trait_text != "":
		_text(Vector2(x0, p.y + 31), trait_text, DIM, 6)


# --- босс ---------------------------------------------------------------------------------

func _draw_boss_bar(y: float) -> void:
	var boss: Boss = game.boss
	if not boss.is_alive():
		if game.time >= 570.0 and game.time < 600.0 and not game.game_over:
			_text_c(_w * 0.5, y + 14, "ОБЪЕКТ-7 ПРИБЛИЖАЕТСЯ", Color(1.0, 0.38, 0.19, 0.7 + 0.3 * sin(game.time * 5.0)), 12, true)
		return
	var width := minf(300.0, _w - 40.0)
	var x := roundf((_w - width) * 0.5)
	var color := Color(0.75, 0.15, 0.09) if boss.phase == 1 else Color(1.0, 0.28, 0.12)
	if game.boss_phase_flash > 0.0:
		color = color.lerp(Color.WHITE, game.boss_phase_flash / 0.7)
	var r := Rect2(x - 6.0, y - 3.0, width + 12.0, 27.0)
	_panel(r, color, Color(0.035, 0.022, 0.022, 0.86))
	_icon_c("skull", Vector2(x + 5, y + 6), color)
	_text(Vector2(x + 14, y + 9), "ОБЪЕКТ-7 · " + ("БРОНЯ" if boss.phase == 1 else "БРОНЯ СОРВАНА"), color, 9)
	_text_r(x + width, y + 9, _n(ceili(boss.hp)) + " / " + _n(int(Boss.MAX_HP)), DIM, 7)
	_seg_bar(Rect2(x, y + 13.0, width, 7.0), boss.hp / Boss.MAX_HP, color, 10, 1.0 / _ui, Color(0.0, 0.0, 0.0, 0.6))


# --- подсказки и отладка ------------------------------------------------------------------

func _draw_hints(player: Player, slots_top: float) -> void:
	# управление показываем в начале забега и убираем, чтобы не мозолило глаза
	var k := clampf((28.0 - float(game.time)) / 3.0, 0.0, 1.0)
	if k <= 0.0:
		return
	var aim_hint := "АВТО · ПКМ — свой прицел" if Meta.settings["auto_fire"] else "РУЧНОЙ · ЛКМ — огонь"
	if player.aim_gamepad:
		aim_hint = "АВТО · правый стик — свой прицел" if Meta.settings["auto_fire"] else "РУЧНОЙ · RT — огонь"
	_text_c(_w * 0.5, slots_top - 5.0, aim_hint + "   ·   " + ("RB" if player.aim_gamepad else "G / СКМ") + " — граната", Color(DIM, k), 7, true)


func _draw_debug(player: Player, weapons: Weapons) -> void:
	var horde: Horde = game.horde
	var lines := [
		"FPS %d" % Engine.get_frames_per_second(),
		"зомби %d" % horde.count,
		"орда %.2f мс" % horde.update_ms,
		"пули %d" % weapons.bullet_count,
		"обломки %d" % game.gore.count,
		"образцы %d" % game.gems.count,
		"кредиты на земле %d" % game.credit_drops.count,
		"смерть: %s" % ("авто" if horde.death_override < 0 else Gore.DEATH_NAMES[horde.death_override]),
		"спавн %.1f/с" % game.spawner.current_rate(),
		"HUD %.2f мс" % draw_ms,
		"бессмертие" if player.god_mode else "",
	]
	var y := (OP_Y + 38.0) if not _op_text.is_empty() else (MARGIN + 44.0)
	for i in lines.size():
		_text_r(_w - MARGIN, y + i * 10, lines[i], DIM, 8, true)
	y += lines.size() * 10 + 4.0
	for hint: String in ["F1 +100 · F2 бессм. · F3 отладка · F4 +1 мин", "F5 патроны · F6 смерть · F7 бегуны", "F8 толстяк · F9 плевальщик · F10 элитка"]:
		_text_r(_w - MARGIN, y, hint, Color(0.5, 0.5, 0.48), 6, true)
		y += 8.0


# --- указатели и дуга урона ---------------------------------------------------------------

func _draw_pointers(player: Player) -> void:
	var bottom := _h - MARGIN - SLOT_H - 14.0 - (32.0 if game.boss.is_alive() else 0.0) # над полосой босса
	var top := 74.0 if not _op_text.is_empty() else 56.0 # ниже панелей справа
	if game.alarm_overlay.visible:
		top = maxf(top, 80.0) # и ниже надписей тревоги
	var area := Rect2(16.0, top, _w - 32.0, bottom - top)
	var pulse := 0.65 + 0.35 * sin(_clock * 6.0)
	_ptr_n = 0
	# босс
	var boss: Boss = game.boss
	if boss.is_alive():
		_pointer(player, area, boss.global_position, "skull", Color(1.0, 0.3, 0.15), 2.0, 1.0)
	# предметы: контейнер всегда, ящик и деталь, аптечка — когда плохо с HP
	var pickups: Pickups = game.pickups
	var need_med := player.hp / player.max_hp < 0.6
	for i in pickups.count:
		if pickups._fall[i] > 0.0:
			continue
		var at := pickups._pos[i] # чтение массивов предметов напрямую, без копий
		match pickups._kind[i]:
			Pickups.Kind.CONTAINER:
				_pointer(player, area, at, "container", Color(1.0, 0.25, 0.18), 1.0, pulse)
			Pickups.Kind.CRATE:
				_pointer(player, area, at, "crate", ACCENT, 1.0, 1.0)
			Pickups.Kind.PART:
				_pointer(player, area, at, "part", Color(0.45, 0.72, 1.0), 1.0, 1.0)
			Pickups.Kind.MEDKIT:
				if need_med:
					_pointer(player, area, at, "med", Color(0.4, 1.0, 0.5), 1.0, 1.0)
	for k in _elite_n:
		_pointer(player, area, _elite_p[k], "skull", Color(1.0, 0.55, 0.2), 1.0, 1.0)


## Стрелка по краю к точке мира, если она вне экрана; значок и дистанция — со стороны центра.
func _pointer(player: Player, area: Rect2, world: Vector2, icon: String, color: Color, icon_scale: float, alpha: float) -> void:
	var sp := _cam * world / _ui
	if sp.x > 4.0 and sp.x < _w - 4.0 and sp.y > 4.0 and sp.y < _h - 4.0:
		return
	var origin := area.get_center()
	var d := sp - origin
	var half := area.size * 0.5
	var k := minf(half.x / maxf(absf(d.x), 0.001), half.y / maxf(absf(d.y), 0.001))
	var p := (origin + d * k).round()
	# цели рядом друг с другом показываем одной стрелкой; порядок вызовов задаёт приоритет
	for j in _ptr_n:
		if p.distance_squared_to(_ptr_pos[j]) < 256.0:
			return
	if _ptr_n < _ptr_pos.size():
		_ptr_pos[_ptr_n] = p
		_ptr_n += 1
	var dir := d.normalized()
	var col := Color(color, alpha)
	# стрелка
	_ci.draw_set_transform(p * _ui, dir.angle(), Vector2(_ui, _ui))
	var arrow: Texture2D = _icons["arrow"]
	_ci.draw_texture(arrow, -arrow.get_size() * 0.5, col)
	_ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(_ui, _ui))
	var ic := (p - dir * 11.0).round()
	PixelArt.draw_dot(_ci, ic, 7.0 * icon_scale, ICON_BG)
	_icon_c(icon, ic, col, icon_scale)
	var meters := int(world.distance_to(player.global_position) / UNITS_PER_METER)
	_text_c(ic.x, ic.y + 10.0 * icon_scale + 6.0, _meters[meters] if meters < 400 else "99+", Color(TEXT, alpha), 6, true)


## Красная дуга со стороны удара вокруг бойца; гаснет за секунду.
func _draw_hit_arc(player: Player) -> void:
	if _hit_t <= 0.0:
		return
	var c := (player.get_global_transform_with_canvas().origin / _ui).round()
	var a := _hit_t
	_ci.draw_arc(c, 34.0, _hit_angle - 0.7, _hit_angle + 0.7, 14, Color(HP_COLOR, 0.30 * a), 7.0)
	_ci.draw_arc(c, 36.0, _hit_angle - 0.55, _hit_angle + 0.55, 12, Color(1.0, 0.25, 0.2, 0.85 * a), 3.0)


## Короткие штрихи с просветом и тёмной обводкой видны и на крови, и на асфальте.
func _draw_crosshair(player: Player) -> void:
	var p := player.aim_mouse_position / _ui
	if player.aim_gamepad:
		p = (player.get_canvas_transform() * player.aim_point) / _ui
	p = p.round()
	var color := Color(1.0, 0.94, 0.70) if player.manual_aim else Color(0.65, 0.67, 0.65)
	for dir: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		_ci.draw_line(p + dir * 2.0, p + dir * 4.0, Color(0.015, 0.012, 0.01, 0.95), 3.0)
		_ci.draw_line(p + dir * 2.0, p + dir * 4.0, color, 1.0)
