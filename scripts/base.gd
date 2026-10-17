extends Control
## Экран базы между забегами (CONTRACTS §13): казарма (дерево класса), мастерская, арсенал, склад ящиков.
## Рисуется в «игровых пикселях» 640×360, как level_up.gd и run_results.gd; все траты идут через Meta.
##
## Управление: 1–5 / Tab / PgUp·PgDn / LB·RB — разделы; стрелки, WASD, D-pad — выбор;
## E / F / A — действие; R / X — вскрыть все ящики; Enter / Space / Start — «В БОЙ» (во время вскрытия ящика —
## дальше / пропустить); Esc / B — отмена. Мышь: клик по любому элементу.
## В операциях: стик / ЛКМ — вращать; A / Enter — выбрать / начать; Space / Start — свободный забег.
##
## Поток: главная сцена игры. Любой тест-флаг (Meta.is_test_run, --meta*, --save-file) сразу ведёт в main.tscn,
## чтобы все старые команды проверки работали без изменений.
## Проверка: godot --path . -- --base-test --shot=путь/s6.png (временное сохранение, настоящее не трогает).

enum Tab { BARRACKS, WORKSHOP, ARSENAL, CRATES, OPERATIONS }
enum Open { NONE, SHAKE, LID, FLASH, CARD, SUMMARY }

const MAIN_SCENE := "res://scenes/main.tscn"
const VIEW_W := 640.0
const VIEW_H := 360.0

const GOLD := Color(1.0, 0.82, 0.35)
const WHITE := Color(0.92, 0.90, 0.85)
const MUTED := Color(0.65, 0.65, 0.62)
const DIM := Color(0.42, 0.42, 0.40)
const RED := Color(0.92, 0.43, 0.40)
const GREEN := Color(0.60, 0.90, 0.60)
const RARE := Color(0.45, 0.72, 1.0)
const PROTO := Color(1.0, 0.55, 0.25)
const PANEL := Color(0.07, 0.065, 0.065, 0.86)
const PANEL_DARK := Color(0.04, 0.035, 0.035, 0.9)

const TAB_NAMES := ["КАЗАРМА", "МАСТЕРСКАЯ", "АРСЕНАЛ", "СКЛАД", "ОПЕРАЦИИ"]
const GLOBE_SCENE := preload("res://scenes/globe_view.tscn")
const MODIFIER_TEXT := {
	"runner_surge": "Прорыв бегунов: быстрые группы",
	"elite_hunt": "Охота элиток: усиленные формы",
	"acid_rain": "Кислотные выбросы: плевальщики",
	"blood_frenzy": "Кровавая вспышка: тревога на 4:00",
	"hardened_boss": "Броня объекта: +25% HP босса",
	"resource_cache": "Военный склад: бонус снабжения",
}
const CATEGORY_NAMES := ["АВТОМАТЫ", "ДРОБОВИКИ", "РЕЙЛГАНЫ", "ГРАНАТОМЁТЫ", "ПИСТОЛЕТЫ", "РЕВОЛЬВЕРЫ", "ПП", "ВИНТОВКИ"]
const BRANCH_COLORS := [Color(1.0, 0.52, 0.30), Color(1.0, 0.82, 0.35), Color(0.55, 0.92, 0.60)]
const STAT_LABELS := {"damage": "УРОН", "rate": "СКОРОСТРЕЛЬНОСТЬ", "mag": "МАГАЗИН", "reload": "ПЕРЕЗАРЯДКА"}
const RARITY_COLORS := [Color(0.72, 0.72, 0.68), WHITE, RARE]
const CRATE_INFO := [
	{"name": "ОБЫЧНЫЙ ЯЩИК", "odds": ["50% новая модель (15% редкая)", "50% пачка ДНК 30–80"], "tex": "base_crate"},
	{"name": "ВОЕННЫЙ ЯЩИК", "odds": ["80% новая модель (50% редкая)", "20% пачка ДНК 30–80"], "tex": "base_crate_mil"},
]

# анимация вскрытия, секунды (у «вскрыть все» со второго ящика — быстрее)
const SHAKE_T := 0.8
const LID_T := 0.35
const FLASH_T := 0.45
const AUTO_NEXT := 1.6
const FADE_T := 0.35

# состояние тест-режима живёт между сценами (бой и возврат на базу)
static var _test_stage := 0
static var _test_checks := 0
static var _test_fails := 0
static var _test_dna := 0
static var _test_crates := 0

var _ui := 3.0
var _origin := Vector2.ZERO
var _t := 0.0
var _tab: int = Tab.OPERATIONS
var _globe: GlobeView
var _op_region := "east_europe"
var _op_sel := -1
var _op_filter := 0
var _op_armed := false
var _op_journal := false
var _op_scroll := 0
static var _globe_test_started := false
var _hits: Array[Dictionary] = []
var _hover_key := ""
var _mouse := Vector2(-1000, -1000)
var _msg := ""
var _msg_t := 0.0
var _leaving := false
var _fade := 1.0
var _stick := Vector2i.ZERO

var _sel_node := 0 # казарма: ветка * 3 + узел
var _ws_sel := 0 # мастерская: индекс в списке открытых моделей
var _ws_stat := 0
var _ars_sel := 0 # арсенал: индекс в WeaponDefs.MODEL_ORDER
var _crate_sel := 0 # склад: 0 обычный, 1 военный
var _confirm_node := "" # подтверждение траты очка навыка

var _open: int = Open.NONE
var _open_t := 0.0
var _open_res: Dictionary = {}
var _open_mil := false
var _open_all := false
var _open_fast := 1.0
var _open_queue: Array[bool] = []
var _open_log: Array[Dictionary] = []
var _pending_dna := 0 # ДНК из вскрываемого ящика: в шапке появляется вместе с карточкой
var _history: Array[Dictionary] = []
var _shake := 0.0

var _sfx: Sfx
var _settings_menu: PauseMenu
var _bg: Texture2D
var _tex: Dictionary = {}
var _test := false
var _shot_path := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_test = args.has("--base-test")
	var globe_test := args.has("--globe-test")
	if _test:
		_tab = Tab.BARRACKS
	if not _test and not globe_test and not get_tree().has_meta("s6_return_to_base") and _goes_straight_to_battle(args):
		visible = false
		get_tree().change_scene_to_file.call_deferred(MAIN_SCENE)
		return
	if get_tree().has_meta("s6_return_to_base"):
		get_tree().remove_meta("s6_return_to_base")
	if not Meta.is_test_run() and not globe_test:
		_msg = Campaign.abandon_pending()
		if not _msg.is_empty():
			_msg_t = 8.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sfx = Sfx.new()
	add_child(_sfx)
	_settings_menu = PauseMenu.new()
	add_child(_settings_menu)
	_settings_menu.sfx = _sfx
	_bg = PixelArt.tex("base_bg")
	for id: String in WeaponDefs.MODEL_ORDER:
		_tex[id] = PixelArt.tex("gun_" + id)
	for c: Dictionary in CRATE_INFO:
		_tex[c["tex"] + "_body"] = PixelArt.tex(c["tex"] + "_body")
		_tex[c["tex"] + "_lid"] = PixelArt.tex(c["tex"] + "_lid")
	for a in args:
		if a.begins_with("--shot="):
			_shot_path = a.trim_prefix("--shot=")
	if _test:
		_run_test.call_deferred()
	if get_tree().has_meta("c3_map_return"):
		_tab = Tab.OPERATIONS
		_op_region = str(get_tree().get_meta("c3_map_return"))
		get_tree().remove_meta("c3_map_return")
	elif get_tree().has_meta("c3_base_return"):
		_tab = Tab.BARRACKS
		get_tree().remove_meta("c3_base_return")
	if _tab == Tab.OPERATIONS:
		_open_operations()
	if globe_test and not _globe_test_started:
		_globe_test_started = true
		GlobeView.run_test.call_deferred(self, _shot_path)


## Тест-флаги игры и флаги меты: база пропускается.
static func _goes_straight_to_battle(args: PackedStringArray) -> bool:
	if Meta.is_test_run(args):
		return true
	for a in args:
		if a.begins_with("--meta") or a.begins_with("--save-file"):
			return true
	return false


# --- ввод --------------------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if _leaving or _settings_menu != null and _settings_menu.visible:
		return
	if _tab == Tab.OPERATIONS and _globe != null:
		var at := get_global_mouse_position() - _globe.global_position
		var mouse_event := event as InputEventMouse
		if mouse_event != null:
			at = mouse_event.position - _globe.position
		if _globe.pointer(event, at):
			accept_event()
			return
		var wheel := event as InputEventMouseButton
		if wheel != null and wheel.pressed and _op_journal and _op_card_rect().has_point(wheel.position / _ui - _origin):
			if wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
				_op_scroll = maxi(0, _op_scroll + (1 if wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1))
				accept_event()
				return
	var motion := event as InputEventMouseMotion
	if motion != null:
		_mouse = motion.position / _ui - _origin
		_hover_key = _key_at(_mouse)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _hover_key != "" else Control.CURSOR_ARROW
	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		_mouse = button.position / _ui - _origin
		_click(_key_at(_mouse))
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if _leaving or _settings_menu != null and _settings_menu.visible:
		return
	var key := event as InputEventKey
	if key != null and key.pressed:
		var code := key.keycode
		# буквенные команды работают и при русской раскладке
		if key.physical_keycode in [KEY_A, KEY_D, KEY_W, KEY_S, KEY_E, KEY_F, KEY_R]:
			code = key.physical_keycode
		var handled := true
		match code:
			KEY_O: _settings_menu.open(true)
			KEY_1, KEY_KP_1: _set_tab(Tab.BARRACKS)
			KEY_2, KEY_KP_2: _set_tab(Tab.WORKSHOP)
			KEY_3, KEY_KP_3: _set_tab(Tab.ARSENAL)
			KEY_4, KEY_KP_4: _set_tab(Tab.CRATES)
			KEY_5, KEY_KP_5: _set_tab(Tab.OPERATIONS)
			KEY_TAB: _step_tab(-1 if key.shift_pressed else 1)
			KEY_PAGEUP: _step_tab(-1)
			KEY_PAGEDOWN: _step_tab(1)
			KEY_LEFT, KEY_A: _nav(-1, 0)
			KEY_RIGHT, KEY_D: _nav(1, 0)
			KEY_UP, KEY_W: _nav(0, -1)
			KEY_DOWN, KEY_S: _nav(0, 1)
			KEY_E, KEY_F: if not key.echo: _confirm()
			KEY_R: if not key.echo: _all_pressed()
			KEY_ENTER, KEY_KP_ENTER:
				if not key.echo:
					if _tab == Tab.OPERATIONS: _confirm()
					else: _fight_pressed()
			KEY_SPACE: if not key.echo: _fight_pressed()
			KEY_ESCAPE: if not key.echo: _cancel()
			_: handled = false
		if handled:
			get_viewport().set_input_as_handled()
		return
	var pad := event as InputEventJoypadButton
	if pad != null and pad.pressed:
		match pad.button_index:
			JOY_BUTTON_A: _confirm()
			JOY_BUTTON_B: _cancel()
			JOY_BUTTON_X: _all_pressed()
			JOY_BUTTON_START: _fight_pressed()
			JOY_BUTTON_LEFT_SHOULDER: _step_tab(-1)
			JOY_BUTTON_RIGHT_SHOULDER: _step_tab(1)
			JOY_BUTTON_DPAD_LEFT: _nav(-1, 0)
			JOY_BUTTON_DPAD_RIGHT: _nav(1, 0)
			JOY_BUTTON_DPAD_UP: _nav(0, -1)
			JOY_BUTTON_DPAD_DOWN: _nav(0, 1)
		return
	var axis := event as InputEventJoypadMotion
	if _tab == Tab.OPERATIONS:
		return
	if axis != null and (axis.axis == JOY_AXIS_LEFT_X or axis.axis == JOY_AXIS_LEFT_Y):
		var v := 0
		if absf(axis.axis_value) > 0.6:
			v = 1 if axis.axis_value > 0.0 else -1
		var horizontal := axis.axis == JOY_AXIS_LEFT_X
		var old := _stick.x if horizontal else _stick.y
		if v != old:
			if horizontal:
				_stick.x = v
			else:
				_stick.y = v
			if v != 0:
				_nav(v if horizontal else 0, 0 if horizontal else v)


func _key_at(p: Vector2) -> String:
	for i in range(_hits.size() - 1, -1, -1):
		if _hits[i]["r"].has_point(p):
			return _hits[i]["k"]
	return ""


func _hit(r: Rect2, key: String) -> void:
	_hits.append({"r": r, "k": key})


func _hot(key: String) -> bool:
	return _hover_key == key


func _click(key: String) -> void:
	if _confirm_node != "":
		if key == "unlock_yes":
			_accept_unlock()
		elif key == "unlock_no":
			_confirm_node = ""
		return
	if _open != Open.NONE:
		_advance()
		return
	if key == "":
		return
	var parts := key.split(":")
	var arg := int(parts[1]) if parts.size() > 1 else 0
	match parts[0]:
		"op": _select_operation(arg)
		"op_start": _start_campaign()
		"op_filter":
			_op_filter = arg
			_globe.filter = arg
			_op_journal = false
			_op_sel = -1
			for id: String in CampaignCatalog.REGIONS:
				if _globe.matches_filter(Campaign.region_info(id)):
					_select_region(id, false)
					break
			_op_armed = false
			_click_sound()
		"op_journal":
			_op_journal = not _op_journal
			_op_scroll = 0
			_click_sound()
		"op_scroll": _op_scroll = maxi(0, _op_scroll + (1 if arg == 1 else -1))
		"op_back": _cancel()
		"settings": _settings_menu.open(true)
		"tab": _set_tab(arg)
		"node":
			_sel_node = arg
			_click_sound()
		"node_buy":
			_sel_node = arg
			_unlock_selected()
		"wsm":
			_ws_sel = arg
			_click_sound()
		"wss":
			_ws_stat = arg
			_click_sound()
		"wsb":
			_ws_stat = arg
			_buy_selected()
		"ars":
			_ars_sel = arg
			_click_sound()
		"fav":
			_ars_sel = arg
			_favorite_selected()
		"csel":
			_crate_sel = arg
			_click_sound()
		"copen":
			_crate_sel = arg
			_open_selected()
		"call": _open_everything()
		"fight": _go_fight()


func _set_tab(t: int) -> void:
	if _open != Open.NONE or _confirm_node != "":
		return
	if t == _tab:
		return
	_tab = t
	_sync_globe()
	_msg_t = 0.0
	_play("ui/click", -9.0)


func _step_tab(d: int) -> void:
	if _open != Open.NONE or _confirm_node != "":
		return
	_set_tab(posmod(_tab + d, 5))


func _nav(dx: int, dy: int) -> void:
	if _open != Open.NONE or _confirm_node != "":
		return
	match _tab:
		Tab.OPERATIONS:
			if _op_journal:
				_op_scroll = maxi(0, _op_scroll + dy)
			else:
				_nav_operations(dx if dx != 0 else dy)
		Tab.BARRACKS:
			var b := clampi(_sel_node / 3 + dx, 0, 2)
			var i := clampi(_sel_node % 3 + dy, 0, 2)
			_sel_node = b * 3 + i
		Tab.WORKSHOP:
			var n := _ws_models().size()
			_ws_sel = clampi(_ws_sel + dy, 0, maxi(n - 1, 0))
			_ws_stat = posmod(_ws_stat + dx, 4)
		Tab.ARSENAL:
			var gx := clampi(_grid_x(_ars_sel) + dx, 0, 3)
			var gy := clampi(_grid_y(_ars_sel) + dy, 0, 3)
			_ars_sel = _grid_model(gx, gy)
		Tab.CRATES:
			_crate_sel = clampi(_crate_sel + dx, 0, 1)
	_click_sound()


func _confirm() -> void:
	if _confirm_node != "":
		_accept_unlock()
		return
	if _open != Open.NONE:
		_advance()
		return
	match _tab:
		Tab.OPERATIONS:
			if _op_armed: _start_campaign()
			else: _op_armed = _op_sel >= 0
		Tab.BARRACKS: _unlock_selected()
		Tab.WORKSHOP: _buy_selected()
		Tab.ARSENAL: _favorite_selected()
		Tab.CRATES: _open_selected()


func _fight_pressed() -> void:
	if _confirm_node != "":
		_accept_unlock()
	elif _open != Open.NONE:
		_advance()
	else:
		_go_fight()


func _all_pressed() -> void:
	if _confirm_node == "" and _open == Open.NONE and _tab == Tab.CRATES:
		_open_everything()


func _cancel() -> void:
	if _tab == Tab.OPERATIONS:
		if _globe._turning or _globe._flash > 0.0:
			_globe.skip_motion()
		elif _op_journal:
			_op_journal = false
		elif _op_armed:
			_op_armed = false
		else:
			_set_tab(Tab.BARRACKS)
		return
	if _confirm_node != "":
		_confirm_node = ""
		return
	if _open == Open.NONE:
		return
	_open_queue.clear()
	if _open != Open.CARD and _open != Open.SUMMARY:
		_skip()
	else:
		_advance()


func _click_sound() -> void:
	_play("ui/click")


func _play(id: String, db := 0.0) -> void:
	if _sfx != null:
		_sfx.play(id, Vector2.INF, db, 0.04)


func _toast(text: String) -> void:
	_msg = text
	_msg_t = 2.2
	_play("ui/deny")


# --- действия ----------------------------------------------------------------------------------

func _node_id(sel: int) -> String:
	return Meta.TREE[sel / 3]["nodes"][sel % 3]["id"]


func _unlock_selected() -> void:
	var id := _node_id(_sel_node)
	if Meta.tree.has(id):
		_toast("Узел уже открыт")
	elif Meta.can_unlock(id):
		_confirm_node = id
		_click_sound()
	elif Meta.skill_points() <= 0:
		_toast("Нет очков подготовки: сдавайте образцы с операций")
	else:
		_toast("Узлы открываются по порядку внутри ветки")


func _accept_unlock() -> void:
	if Meta.unlock(_confirm_node):
		_play("ui/confirm")
	_confirm_node = ""


func _ws_models() -> Array[String]:
	var out: Array[String] = []
	for id: String in WeaponDefs.MODEL_ORDER:
		if Meta.is_owned(id):
			out.append(id)
	return out


func _buy_selected() -> void:
	var models := _ws_models()
	if models.is_empty():
		return
	var model := models[clampi(_ws_sel, 0, models.size() - 1)]
	var stat: String = Meta.WORKSHOP_STATS[_ws_stat]
	var cost := Meta.upgrade_cost(model, stat)
	if cost < 0:
		_toast("Уже максимум")
	elif Meta.dna < cost:
		_toast("Не хватает ДНК: нужно %d, есть %d" % [cost, Meta.dna])
	elif Meta.buy_upgrade(model, stat):
		_play("ui/confirm")


func _favorite_selected() -> void:
	var id: String = WeaponDefs.MODEL_ORDER[_ars_sel]
	if not Meta.is_owned(id):
		_toast("Модель закрыта: она выпадает из оружейных ящиков")
	elif Meta.model_for(WeaponDefs.MODELS[id]["base"]) == id:
		_toast("Уже избранная")
	elif Meta.set_favorite(WeaponDefs.MODELS[id]["base"], id):
		_play("ui/confirm")


func _open_selected() -> void:
	var count := Meta.military_crates if _crate_sel == 1 else Meta.crates
	if count <= 0:
		_toast("Таких ящиков нет: трофеи с элиток, сбросы снабжения, награда за объект")
		return
	_begin_sequence(false)
	_start_open(_crate_sel == 1)


func _open_everything() -> void:
	var queue: Array[bool] = []
	for i in Meta.crates:
		queue.append(false)
	for i in Meta.military_crates:
		queue.append(true)
	if queue.is_empty():
		_toast("Ящиков нет")
		return
	_begin_sequence(true)
	_open_queue = queue
	_start_open(_open_queue.pop_front())


func _begin_sequence(all: bool) -> void:
	_open_all = all
	_open_fast = 1.0
	_open_log.clear()
	_open_queue.clear()


func _start_open(military: bool) -> void:
	var res := Meta.open_crate(military)
	if res.is_empty():
		_open = Open.NONE
		return
	_present(res, military)


## Показывает уже полученный из Meta результат: тряска → крышка → вспышка → карточка.
func _present(res: Dictionary, military: bool) -> void:
	_open_res = res
	_open_mil = military
	_pending_dna = int(res["dna"])
	_open = Open.SHAKE
	_open_t = 0.0
	_open_log.append({"res": res, "mil": military})
	_play("ui/click", -4.0)


func _stage_dur(state: int) -> float:
	match state:
		Open.SHAKE: return SHAKE_T * _open_fast
		Open.LID: return LID_T * _open_fast
		Open.FLASH: return FLASH_T * _open_fast
	return 1.0e9


func _enter_state(state: int) -> void:
	_open = state
	_open_t = 0.0
	match state:
		Open.LID:
			_shake = 1.0
			_play("ui/confirm", -9.0 if _open_res.get("rare", false) else -16.0)
		Open.CARD:
			_pending_dna = 0
			_record_history()
			if _open_res["kind"] == "model" and not _open_res["duplicate"]:
				_play("ui/confirm", -3.0)
				_play("ui/click", -6.0)


func _skip() -> void:
	if _open in [Open.SHAKE, Open.LID, Open.FLASH]:
		_enter_state(Open.CARD)


## «Дальше» во время вскрытия: пропустить анимацию, закрыть карточку, следующий ящик или итог.
func _advance() -> void:
	match _open:
		Open.SHAKE, Open.LID, Open.FLASH:
			_skip()
		Open.CARD:
			if _open_all and not _open_queue.is_empty():
				_open_fast = 0.6
				_start_open(_open_queue.pop_front())
			elif _open_all and _open_log.size() > 1:
				_open = Open.SUMMARY
				_open_t = 0.0
			else:
				_open = Open.NONE
		Open.SUMMARY:
			_open = Open.NONE


func _record_history() -> void:
	var res := _open_res
	var text := ""
	var color := GOLD
	if res["kind"] == "model":
		var m: Dictionary = WeaponDefs.MODELS[res["model"]]
		color = RARE if res["rare"] else WHITE
		text = ("дубликат %s → +%d ДНК" % [m["short"], res["dna"]]) if res["duplicate"] else ("НОВАЯ: " + str(m["name"]))
	else:
		text = "пачка ДНК +%d" % res["dna"]
	_history.push_front({"text": text, "color": color, "mil": _open_mil})
	if _history.size() > 12:
		_history.pop_back()


func _go_fight() -> void:
	if _leaving:
		return
	_leaving = true
	if _globe != null:
		_globe.set_active(false)
	_play("ui/confirm")
	_fade = 0.0


func _change_to_battle() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)


func _process(delta: float) -> void:
	if _globe != null:
		_globe.input_enabled = not _settings_menu.visible and not _leaving
		_globe.position = (Vector2(144, 64) + _origin) * _ui
		_globe.size = Vector2(264, 238) * _ui
	_t += delta
	_msg_t = maxf(_msg_t - delta, 0.0)
	_shake = maxf(_shake - delta * 3.5, 0.0)
	if _leaving:
		_fade += delta / FADE_T
		if _fade >= 1.0:
			_leaving = false
			_change_to_battle()
	if _open in [Open.SHAKE, Open.LID, Open.FLASH]:
		_open_t += delta
		if _open_t >= _stage_dur(_open):
			_enter_state(_open + 1)
	elif _open == Open.CARD:
		_open_t += delta
		if _open_all and not _open_queue.is_empty() and _open_t > AUTO_NEXT:
			_advance()
	elif _open == Open.SUMMARY:
		_open_t += delta
	queue_redraw()


# --- данные для показа -------------------------------------------------------------------------

func _grid_x(idx: int) -> int:
	var m: Dictionary = WeaponDefs.MODELS[WeaponDefs.MODEL_ORDER[idx]]
	return (int(m["base"]) / 4) * 2 + _slot_of(idx)


func _grid_y(idx: int) -> int:
	return int(WeaponDefs.MODELS[WeaponDefs.MODEL_ORDER[idx]]["base"]) % 4


func _slot_of(idx: int) -> int:
	var id: String = WeaponDefs.MODEL_ORDER[idx]
	return 0 if WeaponDefs.MODELS[id]["rarity"] == WeaponDefs.Rarity.SERIAL else 1


func _grid_model(gx: int, gy: int) -> int:
	var base := (gx / 2) * 4 + gy
	var id := WeaponDefs.models_of(base)[gx % 2]
	return WeaponDefs.MODEL_ORDER.find(id)


func _rarity_color(model: String) -> Color:
	return RARITY_COLORS[int(WeaponDefs.MODELS[model]["rarity"])]


## Статы ствола на ур.1 с мастерской и деревом — те же формулы, что в Weapons.refresh().
func _stats_with(model: String, lv: Dictionary) -> Dictionary:
	var st := WeaponDefs.model_stats(model, 1)
	var b := Meta.run_bonuses()
	var step: Dictionary = Meta.WORKSHOP_STEP
	st["damage"] = float(st["damage"]) * (1.0 + float(step["damage"]) * lv["damage"]) * float(b["damage_mul"])
	st["rate"] = float(st["rate"]) * (1.0 + float(step["rate"]) * lv["rate"])
	st["mag"] = ceili(float(st["mag"]) * (1.0 + float(step["mag"]) * lv["mag"]) * float(b["mag_mul"]) - 0.0001)
	st["reload"] = float(st["reload"]) * (1.0 + float(step["reload"]) * lv["reload"]) * float(b["reload_mul"])
	st["crit"] = float(st.get("crit", 0.0)) + float(b["crit_add"])
	return st


func _dps(model: String, st: Dictionary) -> float:
	var rate := float(st["rate"])
	var mag := float(st["mag"])
	var shots := mag / rate
	if WeaponDefs.MODELS[model]["trait"] == "fan":
		shots = WeaponDefs.FAN_TIME * WeaponDefs.FAN_BASE_RATE / rate
	return float(st["damage"]) * int(st["proj"]) * mag / (shots + float(st["reload"])) * (1.0 + float(st["crit"]) + 0.15)


func _levels_of(model: String) -> Dictionary:
	var lv := {}
	for stat: String in Meta.WORKSHOP_STATS:
		lv[stat] = Meta.workshop_level(model, stat)
	return lv


func _fmt(stat: String, v: float) -> String:
	match stat:
		"damage": return "%.1f" % v
		"rate": return "%.2f/с" % v
		"mag": return str(int(v))
	return "%.2f с" % v


func _num(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += " "
		out += s[i]
	return ("-" if n < 0 else "") + out


func _total_steps(model: String) -> int:
	var n := 0
	for stat: String in Meta.WORKSHOP_STATS:
		n += Meta.workshop_level(model, stat)
	return n


func _spent(model: String) -> int:
	var rare: bool = WeaponDefs.MODELS[model]["rarity"] == WeaponDefs.Rarity.RARE
	var sum := 0.0
	for stat: String in Meta.WORKSHOP_STATS:
		for i in Meta.workshop_level(model, stat):
			sum += float(Meta.WORKSHOP_COSTS[i]) * (WeaponDefs.RARE_MULT if rare else 1.0)
	return roundi(sum)


# --- рисование: общее --------------------------------------------------------------------------

func _ts() -> void:
	draw_set_transform(_origin * _ui, 0.0, Vector2(_ui, _ui))


func _width(font: Font, s: String, fs: int) -> float:
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * int(_ui)).x / _ui


func _text(font: Font, p: Vector2, s: String, c: Color, fs: int) -> void:
	var k := int(_ui)
	var at := (p + _origin) * _ui
	draw_set_transform(Vector2.ZERO)
	draw_string_outline(font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * k, 2 * k, Color(0, 0, 0, 0.8 * c.a))
	draw_string(font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs * k, c)
	_ts()


func _text_c(font: Font, p: Vector2, s: String, c: Color, fs: int) -> void:
	_text(font, p - Vector2(_width(font, s, fs) * 0.5, 0), s, c, fs)


func _text_r(font: Font, p: Vector2, s: String, c: Color, fs: int) -> void:
	_text(font, p - Vector2(_width(font, s, fs), 0), s, c, fs)


func _wrap(font: Font, s: String, max_w: float, fs: int) -> Array[String]:
	var out: Array[String] = []
	var line := ""
	for word in s.split(" "):
		var test := word if line == "" else line + " " + word
		if _width(font, test, fs) > max_w and line != "":
			out.append(line)
			line = word
		else:
			line = test
	if line != "":
		out.append(line)
	return out


func _box(r: Rect2, accent: Color, border := 0.5, fill := PANEL, strip := true) -> void:
	draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r, fill)
	draw_rect(r, Color(accent, border), false, 1.0)
	if strip:
		draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(accent, 0.8))


func _button(font: Font, r: Rect2, label: String, color: Color, key: String, enabled := true, fs := 9) -> void:
	var hot := enabled and _hot(key)
	var c := color if enabled else DIM
	draw_rect(r, Color(c.r * 0.22, c.g * 0.2, c.b * 0.16, 0.95) if not hot else Color(c.r * 0.38, c.g * 0.32, c.b * 0.22, 0.98))
	draw_rect(r, Color(c, 1.0 if hot else (0.7 if enabled else 0.4)), false, 1.0)
	_text_c(font, Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.5 + fs * 0.36), label, c, fs)
	if enabled:
		_hit(r, key)
	else:
		_hit(r, key)


func _gun(model: String, center: Vector2, k: int, tint := Color.WHITE) -> void:
	var tex: Texture2D = _tex[model]
	var size := tex.get_size() * float(k) / 3.0
	var pos := ((center - size * 0.5) * _ui).round() / _ui
	draw_texture_rect(tex, Rect2(pos, size), false, tint)


func _star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI * 0.5 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	draw_colored_polygon(pts, col)


func _check_mark(c: Vector2, col: Color) -> void:
	draw_polyline(PackedVector2Array([c + Vector2(-3, 0), c + Vector2(-1, 2.2), c + Vector2(3.4, -2.6)]), col, 1.2)


func _dna_icon(c: Vector2, h: float, col: Color) -> void:
	var pa := PackedVector2Array()
	var pb := PackedVector2Array()
	for i in 13:
		var y := c.y - h * 0.5 + h * i / 12.0
		var off := sin(i * 0.55 + _t * 2.0) * h * 0.22
		pa.append(Vector2(c.x + off, y))
		pb.append(Vector2(c.x - off, y))
	for i in range(1, 12, 2):
		draw_line(pa[i], pb[i], Color(col, 0.45), 1.0)
	draw_polyline(pa, col, 1.0)
	draw_polyline(pb, Color(col.r * 0.75, col.g * 0.75, col.b * 0.9), 1.0)


## Ящик: корпус и крышка отдельно (крышка может лететь). tex — "base_crate" или "base_crate_mil".
func _crate(tex: String, center: Vector2, k: int, lid_off := Vector2.ZERO, lid_rot := 0.0, lid_alpha := 1.0, tint := Color.WHITE) -> void:
	var body: Texture2D = _tex[tex + "_body"]
	var lid: Texture2D = _tex[tex + "_lid"]
	var bs := body.get_size() * float(k) / 3.0
	var ls := lid.get_size() * float(k) / 3.0
	var body_pos := center - bs * 0.5
	draw_texture_rect(body, Rect2(((body_pos * _ui).round()) / _ui, bs), false, tint)
	var lid_center := Vector2(center.x, body_pos.y - ls.y * 0.5 + 2.0) + lid_off
	if lid_rot == 0.0:
		draw_texture_rect(lid, Rect2(((lid_center - ls * 0.5) * _ui).round() / _ui, ls), false, Color(tint, lid_alpha))
	else:
		draw_set_transform((lid_center + _origin) * _ui, lid_rot, Vector2(_ui, _ui))
		draw_texture_rect(lid, Rect2(-ls * 0.5, ls), false, Color(tint, lid_alpha))
		_ts()


# --- рисование: экран --------------------------------------------------------------------------

func _draw() -> void:
	if _bg == null:
		return
	_ui = maxf(1.0, roundf(size.y / VIEW_H))
	var view := size / _ui
	_origin = Vector2((view.x - VIEW_W) * 0.5, maxf(0.0, (view.y - VIEW_H) * 0.5))
	_hits.clear()
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.12))
	_ts()
	var font := ThemeDB.fallback_font
	_draw_top(font)
	_draw_tabs(font)
	match _tab:
		Tab.BARRACKS: _draw_barracks(font)
		Tab.WORKSHOP: _draw_workshop(font)
		Tab.ARSENAL: _draw_arsenal(font)
		Tab.CRATES: _draw_crates(font)
		Tab.OPERATIONS: _draw_operations(font)
	_draw_hint(font)
	_draw_bottom(font)
	if _confirm_node != "":
		_hits.clear()
		_draw_unlock_confirmation(font)
	if _open != Open.NONE:
		_hits.clear()
		_draw_stage(font)
		_hit(Rect2(-100, -100, 900, 600), "adv:0")
	if _fade < 1.0 or _leaving:
		var a := 1.0 - _fade if not _leaving else _fade
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, clampf(a, 0.0, 1.0)))
		_ts()
	elif _t < 0.4:
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 1.0 - _t / 0.4))
		_ts()


func _draw_unlock_confirmation(font: Font) -> void:
	draw_rect(Rect2(-_origin, size / _ui), Color(0, 0, 0, 0.8))
	var node: Dictionary = Meta.TREE[_sel_node / 3]["nodes"][_sel_node % 3]
	_box(Rect2(174, 108, 292, 136), GOLD, 0.8, PANEL_DARK)
	_text_c(font, Vector2(320, 130), "ОТКРЫТЬ НАВЫК?", GOLD, 13)
	_text_c(font, Vector2(320, 148), str(node["name"]), WHITE, 12)
	var y := 162.0
	for line in _wrap(font, str(node["text"]), 266.0, 9):
		_text_c(font, Vector2(320, y), line, MUTED, 9)
		y += 11.0
	_text_c(font, Vector2(320, 202), "Стоимость: 1 очко · осталось %d" % Meta.skill_points(), GOLD, 9)
	_button(font, Rect2(186, 215, 130, 20), "ОТКРЫТЬ [E / A]", GOLD, "unlock_yes", true, 9)
	_button(font, Rect2(324, 215, 130, 20), "ОТМЕНА [Esc / B]", MUTED, "unlock_no", true, 9)


func _draw_top(font: Font) -> void:
	draw_rect(Rect2(-_origin.x, -_origin.y, size.x / _ui, 36.0 + _origin.y), Color(0.03, 0.025, 0.025, 0.9))
	draw_rect(Rect2(-_origin.x, 35.0, size.x / _ui, 1.0), Color(GOLD, 0.35))
	# класс и прогресс до следующего уровня
	var level := Meta.class_level()
	var lo := Meta.dna_for_level(level)
	var hi := Meta.dna_for_level(level + 1)
	var frac := clampf(float(Meta.dna_earned - lo) / maxf(float(hi - lo), 1.0), 0.0, 1.0)
	_text(font, Vector2(8, 27), "УР. %d" % level, GOLD, 15)
	_text(font, Vector2(56, 13), "ФОРПОСТ Z.E.R.A.", MUTED, 8)
	draw_rect(Rect2(56, 17, 132, 6), Color(0.14, 0.12, 0.1))
	draw_rect(Rect2(56, 17, 132.0 * frac, 6), Color(GOLD, 0.85))
	draw_rect(Rect2(56, 17, 132, 6), Color(GOLD, 0.4), false, 1.0)
	_text(font, Vector2(56, 32), "до след. уровня: %s ДНК" % _num(maxi(hi - Meta.dna_earned, 0)), MUTED, 7)
	# очки навыков
	var points := Meta.skill_points()
	var pc := GREEN if points > 0 else DIM
	_text(font, Vector2(206, 13), "ОЧКИ НАВЫКОВ", MUTED, 7)
	_text(font, Vector2(206, 31), str(points), pc, 16)
	if points > 0:
		_text(font, Vector2(226, 31), "доступно", Color(pc, 0.8), 7)
	# ДНК
	var shown := Meta.dna - _pending_dna
	_dna_icon(Vector2(300, 20), 16.0, GOLD)
	_text(font, Vector2(312, 13), "ОБРАЗЦЫ (ДНК)", MUTED, 7)
	_text(font, Vector2(312, 31), _num(shown), GOLD, 16)
	# ящики
	_draw_crate_chip(font, 0, Vector2(440, 6), Meta.crates, "ЯЩИКИ")
	_draw_crate_chip(font, 1, Vector2(540, 6), Meta.military_crates, "ВОЕННЫЕ")


func _draw_crate_chip(font: Font, kind: int, p: Vector2, count: int, label: String) -> void:
	var tex: String = CRATE_INFO[kind]["tex"]
	var body: Texture2D = _tex[tex + "_body"]
	var s := body.get_size() / 3.0
	var tint := Color.WHITE if count > 0 else Color(0.45, 0.45, 0.45, 0.8)
	draw_texture_rect(body, Rect2(((p + Vector2(0, 5)) * _ui).round() / _ui, s * 0.5), false, tint)
	var lid: Texture2D = _tex[tex + "_lid"]
	draw_texture_rect(lid, Rect2(((p + Vector2(0, 2)) * _ui).round() / _ui, lid.get_size() / 3.0 * 0.5), false, tint)
	_text(font, p + Vector2(36, 8), label, MUTED, 7)
	_text(font, p + Vector2(36, 25), "×%d" % count, GOLD if count > 0 else DIM, 15)


func _draw_tabs(font: Font) -> void:
	_button(font, Rect2(480, 40, 152, 19), "НАСТРОЙКИ [O]", MUTED, "settings", true, 9)
	for i in 5:
		var r := Rect2(8 + i * 93, 40, 89, 19)
		var active := _tab == i
		var hot := _hot("tab:%d" % i)
		draw_rect(r, Color(0.16, 0.13, 0.07, 0.95) if active else (Color(0.12, 0.11, 0.1, 0.92) if hot else Color(0.05, 0.045, 0.045, 0.85)))
		draw_rect(r, Color(GOLD, 0.9 if active else (0.55 if hot else 0.22)), false, 1.0)
		if active:
			draw_rect(Rect2(r.position + Vector2(0, r.size.y - 2), Vector2(r.size.x, 2)), GOLD)
		_text(font, r.position + Vector2(7, 13), str(i + 1), Color(GOLD, 0.7 if active else 0.4), 9)
		_text_c(font, r.position + Vector2(r.size.x * 0.5 + 4, 13), TAB_NAMES[i], GOLD if active else (WHITE if hot else MUTED), 9)
		_hit(r, "tab:%d" % i)
		var badge := 0
		if i == Tab.BARRACKS:
			badge = Meta.skill_points()
		elif i == Tab.CRATES:
			badge = Meta.crates + Meta.military_crates
		if badge > 0 and not active:
			var bc := GREEN if i == Tab.BARRACKS else GOLD
			PixelArt.draw_dot(self, r.position + Vector2(r.size.x - 7, 5), 5.5, bc)
			_text_c(font, r.position + Vector2(r.size.x - 7, 8.4), str(mini(badge, 99)), Color(0.05, 0.05, 0.04), 7)


func _draw_hint(font: Font) -> void:
	if _msg_t > 0.0:
		_text_c(font, Vector2(320, 309), _msg, Color(RED, minf(_msg_t * 2.0, 1.0)), 8)
		return
	var tail := ""
	match _tab:
		Tab.BARRACKS: tail = "стрелки — выбор узла · E / клик — открыть (1 очко)"
		Tab.WORKSHOP: tail = "↑↓ — модель · ←→ — параметр · E / клик по цене — улучшить"
		Tab.ARSENAL: tail = "стрелки — выбор · E / клик по ★ — избранная (её предлагает Level Up)"
		Tab.CRATES: tail = "←→ — тип · E — вскрыть · R — вскрыть все · Enter — пропуск"
		Tab.OPERATIONS: tail = "ЛКМ / стик — вращать · колесо / курки — масштаб · D-pad — регион · A / Enter — выбрать / начать"
	_text_c(font, Vector2(320, 309), "1–5 / Tab — разделы · " + tail, DIM, 7)


func _draw_bottom(font: Font) -> void:
	draw_rect(Rect2(-_origin.x, 312, size.x / _ui, 48.0 + _origin.y), Color(0.03, 0.025, 0.025, 0.92))
	draw_rect(Rect2(-_origin.x, 312, size.x / _ui, 1.0), Color(GOLD, 0.3))
	# с чем идём в бой: избранная или серийная модель каждой категории
	for b in 8:
		var model := Meta.model_for(b)
		var col := b % 4
		var row := b / 4
		var r := Rect2(8 + col * 106, 316 + row * 21, 102, 19)
		var fav: bool = WeaponDefs.MODELS[model]["rarity"] != WeaponDefs.Rarity.SERIAL
		var rc := _rarity_color(model)
		draw_rect(r, Color(0.07, 0.065, 0.065, 0.9))
		draw_rect(r, Color(rc, 0.4 if fav else 0.18), false, 1.0)
		_gun(model, r.position + Vector2(19, 10), 1)
		_text(font, r.position + Vector2(38, 9), str(WeaponDefs.MODELS[model]["short"]), rc if fav else WHITE, 8)
		var steps := _total_steps(model)
		_text(font, r.position + Vector2(38, 17), ("★ " if fav else "") + ("%d/20" % steps if steps > 0 else CATEGORY_NAMES[b].to_lower()), Color(GOLD, 0.8) if fav else DIM, 6)
		if b == WeaponDefs.Base.RIFLE:
			_text_r(font, r.position + Vector2(100, 8), "старт", Color(GREEN, 0.9), 6)
	# кнопка «В БОЙ»
	var br := Rect2(444, 316, 188, 40)
	var hot := _hot("fight:0")
	var pulse := 0.85 if Meta.settings["reduce_motion"] else 0.65 + 0.35 * sin(_t * 3.0)
	draw_rect(Rect2(br.position + Vector2(2, 3), br.size), Color(0, 0, 0, 0.4))
	draw_rect(br, Color(0.30, 0.20, 0.06) if hot else Color(0.20, 0.14, 0.05))
	draw_rect(Rect2(br.position, Vector2(br.size.x, 14)), Color(GOLD, 0.08))
	draw_rect(br, Color(GOLD, 1.0 if hot else pulse), false, 1.0)
	draw_rect(Rect2(br.position, Vector2(br.size.x, 2)), GOLD)
	_text_c(font, br.position + Vector2(br.size.x * 0.5, 18), "В БОЙ", GOLD, 16)
	_text_c(font, br.position + Vector2(br.size.x * 0.5, 28), "свободный забег — мир не меняется", Color(GOLD, 0.8), 7)
	_text_c(font, br.position + Vector2(br.size.x * 0.5, 36), "Space / Start", Color(GOLD, 0.6), 6)
	_hit(br, "fight:0")


# --- казарма -----------------------------------------------------------------------------------

func _draw_barracks(font: Font) -> void:
	var col_w := 200.0
	for b in 3:
		var branch: Dictionary = Meta.TREE[b]
		var x := 8.0 + b * (col_w + 12.0)
		var accent: Color = BRANCH_COLORS[b]
		var opened := 0
		for n: Dictionary in branch["nodes"]:
			if Meta.tree.has(n["id"]):
				opened += 1
		draw_rect(Rect2(x, 64, col_w, 15), Color(accent, 0.15))
		draw_rect(Rect2(x, 78, col_w, 1), Color(accent, 0.6))
		_text(font, Vector2(x + 6, 75), str(branch["name"]).to_upper(), accent, 10)
		_text_r(font, Vector2(x + col_w - 6, 75), "%d/3" % opened, Color(accent, 0.8), 9)
		for i in 3:
			var node: Dictionary = branch["nodes"][i]
			var id: String = node["id"]
			var r := Rect2(x, 84 + i * 72, col_w, 66)
			var idx := b * 3 + i
			var is_open := Meta.tree.has(id)
			var prev_open := i == 0 or Meta.tree.has(branch["nodes"][i - 1]["id"])
			var can := Meta.can_unlock(id)
			var selected := _sel_node == idx
			var hot := _hot("node:%d" % idx)
			var border := accent
			var name_c := WHITE
			if is_open:
				border = GREEN
				name_c = GREEN
			elif not prev_open:
				border = DIM
				name_c = DIM
			elif not can:
				border = Color(accent, 0.55)
			var bd := 0.95 if selected else (0.7 if hot else 0.4)
			# связка с предыдущим узлом
			if i > 0:
				draw_rect(Rect2(x + col_w * 0.5 - 1, r.position.y - 6, 2, 6), Color(border, 0.7) if prev_open else Color(DIM, 0.5))
			draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.35))
			draw_rect(r, Color(0.10, 0.09, 0.07, 0.94) if selected else PANEL)
			draw_rect(r, Color(border, bd), false, 1.0)
			draw_rect(Rect2(r.position, Vector2(3, r.size.y)), Color(border, 0.85 if (is_open or prev_open) else 0.3))
			_text(font, r.position + Vector2(10, 14), "%d. %s" % [i + 1, node["name"]], name_c, 11)
			var y := 26.0
			for line in _wrap(font, str(node["text"]), col_w - 18.0, 8):
				_text(font, r.position + Vector2(10, y), line, Color(WHITE.r, WHITE.g, WHITE.b, 0.88 if prev_open else 0.4), 8)
				y += 9.5
			if is_open:
				_check_mark(r.position + Vector2(14, 58), GREEN)
				_text(font, r.position + Vector2(22, 61), "ОТКРЫТ", GREEN, 8)
			elif not prev_open:
				_text(font, r.position + Vector2(10, 61), "сначала: " + str(branch["nodes"][i - 1]["name"]), DIM, 7)
			elif can:
				_text(font, r.position + Vector2(10, 61), "СТОИМОСТЬ: 1 ОЧКО", GOLD, 8)
			else:
				_text(font, r.position + Vector2(10, 61), "нужно очко навыка", Color(GOLD, 0.5), 8)
			_hit(r, "node:%d" % idx)
			if can and selected:
				_button(font, Rect2(r.position.x + col_w - 84, r.position.y + 48, 78, 14), "ОТКРЫТЬ [E]", GOLD, "node_buy:%d" % idx, true, 8)


# --- мастерская --------------------------------------------------------------------------------

func _draw_workshop(font: Font) -> void:
	var models := _ws_models()
	_ws_sel = clampi(_ws_sel, 0, maxi(models.size() - 1, 0))
	# список открытых моделей
	var list := Rect2(8, 64, 172, 238)
	draw_rect(list, PANEL)
	draw_rect(list, Color(GOLD, 0.25), false, 1.0)
	_text(font, Vector2(14, 75), "МОДЕЛИ (%d)" % models.size(), GOLD, 9)
	for i in models.size():
		var id := models[i]
		var r := Rect2(10, 80 + i * 13.6, 168, 13)
		var sel := i == _ws_sel
		var hot := _hot("wsm:%d" % i)
		if sel:
			draw_rect(r, Color(GOLD, 0.16))
			draw_rect(r, Color(GOLD, 0.7), false, 1.0)
		elif hot:
			draw_rect(r, Color(1, 1, 1, 0.07))
		var rc := _rarity_color(id)
		var base: int = WeaponDefs.MODELS[id]["base"]
		if Meta.model_for(base) == id and WeaponDefs.MODELS[id]["rarity"] != WeaponDefs.Rarity.SERIAL:
			_star(r.position + Vector2(7, 6.5), 3.6, GOLD)
		else:
			draw_rect(Rect2(r.position + Vector2(5, 4.5), Vector2(4, 4)), rc)
		_text(font, r.position + Vector2(15, 10), str(WeaponDefs.MODELS[id]["short"]), rc if not sel else WHITE, 9)
		var steps := _total_steps(id)
		_text_r(font, r.position + Vector2(165, 10), "%d/20" % steps, GOLD if steps > 0 else DIM, 8)
		_hit(r, "wsm:%d" % i)
	if models.is_empty():
		return
	var model := models[_ws_sel]
	var m: Dictionary = WeaponDefs.MODELS[model]
	var rc := _rarity_color(model)
	var lv := _levels_of(model)
	var panel := Rect2(188, 64, 444, 238)
	draw_rect(panel, PANEL)
	draw_rect(panel, Color(rc, 0.4), false, 1.0)
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, 2)), Color(rc, 0.8))
	# шапка модели
	draw_rect(Rect2(196, 72, 92, 44), PANEL_DARK)
	draw_rect(Rect2(196, 72, 92, 44), Color(rc, 0.25), false, 1.0)
	_gun(model, Vector2(242, 94), 2)
	_text(font, Vector2(298, 87), str(m["name"]), rc, 14)
	_text(font, Vector2(298, 99), "%s · %s" % [CATEGORY_NAMES[int(m["base"])].to_lower(), WeaponDefs.RARITY_NAMES[int(m["rarity"])]], MUTED, 8)
	var trait_id: String = m["trait"]
	if trait_id != "":
		var tr: Dictionary = WeaponDefs.TRAITS[trait_id]
		_text(font, Vector2(298, 110), "черта: " + str(tr["name"]), GOLD if m["rarity"] != WeaponDefs.Rarity.RARE else RARE, 8)
		var tw := _width(font, "черта: " + str(tr["name"]), 8)
		_text(font, Vector2(304 + tw, 110), "· " + str(tr["text"]), MUTED, 7)
	else:
		_text(font, Vector2(298, 110), "серийная модель, без особой черты", DIM, 8)
	# четыре стата 2×2
	for s in 4:
		var stat: String = Meta.WORKSHOP_STATS[s]
		var r := Rect2(196 + (s % 2) * 218, 124 + (s / 2) * 62, 210, 56)
		var level: int = lv[stat]
		var cost := Meta.upgrade_cost(model, stat)
		var sel := _ws_stat == s
		var hot := _hot("wss:%d" % s)
		draw_rect(r, PANEL_DARK if not sel else Color(0.10, 0.085, 0.05, 0.94))
		draw_rect(r, Color(GOLD, 0.85 if sel else (0.55 if hot else 0.22)), false, 1.0)
		_text(font, r.position + Vector2(8, 13), STAT_LABELS[stat], WHITE if sel else MUTED, 8)
		_text_r(font, r.position + Vector2(r.size.x - 8, 13), "%d/%d" % [level, Meta.WORKSHOP_MAX], GOLD if level > 0 else DIM, 9)
		for p in Meta.WORKSHOP_MAX:
			var pr := Rect2(r.position + Vector2(8 + p * 39, 19), Vector2(36, 7))
			draw_rect(pr, Color(0.14, 0.12, 0.1))
			if p < level:
				draw_rect(pr, GOLD)
				draw_rect(Rect2(pr.position, Vector2(pr.size.x, 2)), Color(1, 1, 1, 0.25))
			draw_rect(pr, Color(GOLD, 0.35), false, 1.0)
		var cur := _stats_with(model, lv)
		var cur_v := float(cur[stat])
		if cost >= 0:
			var nxt_lv := lv.duplicate()
			nxt_lv[stat] = level + 1
			var nxt_v := float(_stats_with(model, nxt_lv)[stat])
			_text(font, r.position + Vector2(8, 46), _fmt(stat, cur_v), WHITE, 10)
			var cw := _width(font, _fmt(stat, cur_v), 10)
			_text(font, r.position + Vector2(14 + cw, 46), "→", MUTED, 9)
			_text(font, r.position + Vector2(26 + cw, 46), _fmt(stat, nxt_v), GREEN, 10)
			var afford := Meta.dna >= cost
			_button(font, Rect2(r.position.x + r.size.x - 72, r.position.y + 32, 66, 18), "%d ДНК" % cost, GOLD if afford else RED, "wsb:%d" % s, afford, 9)
		else:
			_text(font, r.position + Vector2(8, 46), _fmt(stat, cur_v), WHITE, 10)
			_text_r(font, r.position + Vector2(r.size.x - 8, 46), "МАКСИМУМ", GREEN, 9)
		_hit(r, "wss:%d" % s)
		# кнопка добавлена позже, поверх карточки
		if cost >= 0:
			_hit(Rect2(r.position.x + r.size.x - 72, r.position.y + 32, 66, 18), "wsb:%d" % s)
	# сводка: эфф. DPS и вложения
	var cur_st := _stats_with(model, lv)
	var dps_now := _dps(model, cur_st)
	var stat_sel: String = Meta.WORKSHOP_STATS[_ws_stat]
	var line := "Эфф. DPS ур.1: %.1f" % dps_now
	_text(font, Vector2(198, 263), line, WHITE, 10)
	if Meta.upgrade_cost(model, stat_sel) >= 0:
		var nl := lv.duplicate()
		nl[stat_sel] = int(lv[stat_sel]) + 1
		var dps_next := _dps(model, _stats_with(model, nl))
		var w := _width(font, line, 10)
		_text(font, Vector2(206 + w, 263), "→ %.1f (%+.0f%%)" % [dps_next, (dps_next / maxf(dps_now, 0.01) - 1.0) * 100.0], GREEN, 10)
	var proj := int(cur_st["proj"])
	var extra := "магазин %d · перезарядка %.2f с · %.2f выстр/с" % [int(cur_st["mag"]), float(cur_st["reload"]), float(cur_st["rate"])]
	if proj > 1:
		extra = ("снарядов %d · " % proj) + extra
	_text(font, Vector2(198, 276), extra, MUTED, 8)
	_text(font, Vector2(198, 290), "вложено: %s ДНК · максимум модели: %d ДНК · редкие ×1.5" % [_num(_spent(model)), 2400 if m["rarity"] == WeaponDefs.Rarity.RARE else 1600], DIM, 7)
	_text_r(font, Vector2(624, 263), "у вас %s ДНК" % _num(Meta.dna), GOLD, 9)


# --- арсенал -----------------------------------------------------------------------------------

func _draw_arsenal(font: Font) -> void:
	for b in 8:
		var cell := Rect2(8 + (b / 4) * 216, 64 + (b % 4) * 59, 212, 55)
		draw_rect(cell, PANEL)
		draw_rect(cell, Color(GOLD, 0.18), false, 1.0)
		_text(font, cell.position + Vector2(6, 9), CATEGORY_NAMES[b], GOLD, 8)
		var models := WeaponDefs.models_of(b)
		_text_r(font, cell.position + Vector2(206, 9), "в бою: " + str(WeaponDefs.MODELS[Meta.model_for(b)]["short"]), MUTED, 7)
		for s in models.size():
			var id := models[s]
			var idx := WeaponDefs.MODEL_ORDER.find(id)
			var r := Rect2(cell.position + Vector2(2 + s * 104, 12), Vector2(102, 41))
			var owned := Meta.is_owned(id)
			var rc := _rarity_color(id)
			var sel := _ars_sel == idx
			var hot := _hot("ars:%d" % idx)
			var fav := owned and Meta.model_for(b) == id
			draw_rect(r, Color(0.045, 0.04, 0.04, 0.95) if not sel else Color(0.09, 0.08, 0.06, 0.96))
			draw_rect(r, Color(rc if owned else DIM, 0.95 if sel else (0.7 if hot else (0.45 if owned else 0.2))), false, 1.0)
			if sel:
				draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(rc if owned else MUTED, 0.9))
			if owned:
				_gun(id, r.position + Vector2(51, 14), 2)
				_text_c(font, r.position + Vector2(51, 32), str(WeaponDefs.MODELS[id]["short"]), rc, 8)
				_text_c(font, r.position + Vector2(51, 39), WeaponDefs.RARITY_NAMES[int(WeaponDefs.MODELS[id]["rarity"])], Color(rc, 0.65), 6)
			else:
				_gun(id, r.position + Vector2(51, 14), 2, Color(0.0, 0.0, 0.0, 0.9))
				_text_c(font, r.position + Vector2(51, 17), "???", Color(MUTED, 0.9), 11)
				_text_c(font, r.position + Vector2(51, 32), "???", DIM, 8)
				_text_c(font, r.position + Vector2(51, 39), "из ящика", DIM, 6)
			_hit(r, "ars:%d" % idx)
			if owned:
				var sc := r.position + Vector2(r.size.x - 9, 9)
				_star(sc, 5.2, GOLD if fav else Color(0.5, 0.45, 0.3, 0.5))
				_hit(Rect2(sc - Vector2(7, 7), Vector2(14, 14)), "fav:%d" % idx)
	# подробности выбранной модели
	var id: String = WeaponDefs.MODEL_ORDER[_ars_sel]
	var m: Dictionary = WeaponDefs.MODELS[id]
	var owned := Meta.is_owned(id)
	var rc := _rarity_color(id)
	var panel := Rect2(444, 64, 188, 238)
	draw_rect(panel, PANEL)
	draw_rect(panel, Color(rc if owned else DIM, 0.45), false, 1.0)
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, 2)), Color(rc if owned else DIM, 0.85))
	draw_rect(Rect2(452, 72, 172, 58), PANEL_DARK)
	draw_rect(Rect2(452, 72, 172, 58), Color(rc if owned else DIM, 0.22), false, 1.0)
	if owned:
		_gun(id, Vector2(538, 101), 3)
	else:
		_gun(id, Vector2(538, 101), 3, Color(0.0, 0.0, 0.0, 0.9))
		_text_c(font, Vector2(538, 106), "???", Color(MUTED, 0.9), 16)
	var y := 144.0
	if owned:
		_text(font, Vector2(452, y), str(m["name"]), rc, 11)
		y += 11
		_text(font, Vector2(452, y), "%s · %s" % [CATEGORY_NAMES[int(m["base"])].to_lower(), WeaponDefs.RARITY_NAMES[int(m["rarity"])]], MUTED, 8)
		y += 6
		for line in _wrap(font, str(m.get("desc", WeaponDefs.BASES[int(m["base"])]["desc"])), 172.0, 8):
			y += 9.5
			_text(font, Vector2(452, y), line, WHITE, 8)
		var trait_id: String = m["trait"]
		y += 13
		if trait_id != "":
			var tr: Dictionary = WeaponDefs.TRAITS[trait_id]
			_text(font, Vector2(452, y), "ЧЕРТА: " + str(tr["name"]).to_upper(), RARE if m["rarity"] == WeaponDefs.Rarity.RARE else GOLD, 8)
			for line in _wrap(font, str(tr["text"]), 172.0, 8):
				y += 9.5
				_text(font, Vector2(452, y), line, MUTED, 8)
		else:
			_text(font, Vector2(452, y), "Серийная: без особой черты", DIM, 8)
	else:
		_text(font, Vector2(452, y), "ЗАКРЫТАЯ МОДЕЛЬ", MUTED, 11)
		y += 12
		for line in _wrap(font, "Выдаётся из ящиков: обычные — с операций и сбросов, военные — за объект. Дубликат сдаётся за образцы.", 172.0, 8):
			y += 9.5
			_text(font, Vector2(452, y), line, DIM, 8)
		y += 13
		_text(font, Vector2(452, y), "РЕДКОСТЬ: " + WeaponDefs.RARITY_NAMES[int(m["rarity"])].to_upper(), RARE if m["rarity"] == WeaponDefs.Rarity.RARE else WHITE, 8)
	# эфф. DPS на ур.1 для сравнения с серийной
	var dps := WeaponDefs.effective_dps(id, 1)
	var serial_dps := WeaponDefs.effective_dps(WeaponDefs.serial_model(int(m["base"])), 1)
	var by := 258.0
	_text(font, Vector2(452, by), "Эфф. DPS ур.1:", MUTED, 8)
	_text_r(font, Vector2(624, by), "%.1f" % dps, WHITE if owned else Color(MUTED, 0.8), 10)
	if m["rarity"] != WeaponDefs.Rarity.SERIAL:
		var delta := (dps / serial_dps - 1.0) * 100.0
		_text_r(font, Vector2(624, by + 10), "к серийной %+.0f%%" % delta, GREEN if delta >= 0.0 else RED, 7)
	if owned:
		var is_fav: bool = Meta.model_for(int(m["base"])) == id
		if is_fav:
			_text_c(font, Vector2(538, 295), "★ ИЗБРАННАЯ В КАТЕГОРИИ", GOLD, 8)
		else:
			_button(font, Rect2(452, 281, 172, 17), "СДЕЛАТЬ ИЗБРАННОЙ [E]", GOLD, "fav:%d" % _ars_sel, true, 8)


# --- склад ящиков ------------------------------------------------------------------------------

func _draw_crates(font: Font) -> void:
	for i in 2:
		var info: Dictionary = CRATE_INFO[i]
		var count := Meta.military_crates if i == 1 else Meta.crates
		var r := Rect2(8 + i * 152, 64, 148, 134)
		var sel := _crate_sel == i
		var hot := _hot("csel:%d" % i)
		var accent := GOLD if i == 1 else WHITE
		draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.35))
		draw_rect(r, PANEL if not sel else Color(0.10, 0.09, 0.06, 0.94))
		draw_rect(r, Color(accent, 0.9 if sel else (0.6 if hot else 0.3)), false, 1.0)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(accent, 0.8))
		_text_c(font, r.position + Vector2(74, 14), info["name"], accent, 9)
		var tint := Color.WHITE if count > 0 else Color(0.4, 0.4, 0.4, 0.8)
		# стопка: до трёх ящиков друг на друге
		var stack := mini(count, 3)
		for s in stack:
			_crate(info["tex"], r.position + Vector2(74, 62 - s * 6 + (3 - stack) * 4), 2, Vector2.ZERO, 0.0, 1.0, tint)
		if count == 0:
			_crate(info["tex"], r.position + Vector2(74, 62), 2, Vector2.ZERO, 0.0, 1.0, tint)
		_text_c(font, r.position + Vector2(74, 104), "×%d" % count, GOLD if count > 0 else DIM, 17)
		_text_c(font, r.position + Vector2(74, 116), info["odds"][0], MUTED, 6)
		_text_c(font, r.position + Vector2(74, 125), info["odds"][1], MUTED, 6)
		_hit(r, "csel:%d" % i)
	var sel_count := Meta.military_crates if _crate_sel == 1 else Meta.crates
	_button(font, Rect2(8, 206, 148, 24), "ВСКРЫТЬ [E]", GOLD, "copen:%d" % _crate_sel, sel_count > 0, 11)
	var total := Meta.crates + Meta.military_crates
	_button(font, Rect2(160, 206, 148, 24), "ВСКРЫТЬ ВСЕ (%d) [R]" % total, GOLD, "call:0", total > 0, 9)
	# справка
	var y := 244.0
	for line in ["Ящики: трофеи с элиток, сбросы снабжения, награда за объект.",
			"Новая модель навсегда попадает в Арсенал, дубликат",
			"сдаётся за образцы (ДНК): обычная 40, редкая 100."]:
		_text(font, Vector2(10, y), line, MUTED, 8)
		y += 11
	# журнал вскрытий этого визита
	var log_r := Rect2(316, 64, 316, 238)
	draw_rect(log_r, PANEL)
	draw_rect(log_r, Color(GOLD, 0.25), false, 1.0)
	_text(font, Vector2(324, 77), "ЖУРНАЛ ПОСТАВОК", GOLD, 9)
	if _history.is_empty():
		_text(font, Vector2(324, 100), "Пока ничего не вскрыто.", DIM, 9)
		_text(font, Vector2(324, 113), "Выбери ящик слева и нажми «ВСКРЫТЬ».", DIM, 8)
	for i in _history.size():
		var h: Dictionary = _history[i]
		var hy := 94.0 + i * 16.0
		var a := 1.0 - i * 0.05
		draw_rect(Rect2(324, hy - 9, 300, 14), Color(1, 1, 1, 0.04 if i % 2 == 0 else 0.0))
		draw_rect(Rect2(326, hy - 6, 6, 8), Color(GOLD if h["mil"] else MUTED, a))
		_text(font, Vector2(338, hy + 1), str(h["text"]), Color(h["color"], a), 9)


# --- анимация вскрытия -------------------------------------------------------------------------

func _result_color() -> Color:
	if _open_res["kind"] == "model":
		return RARE if _open_res["rare"] else WHITE
	return GOLD


func _draw_stage(font: Font) -> void:
	var accent := _result_color()
	var view_h := size.y / _ui
	draw_rect(Rect2(-_origin.x, 36, size.x / _ui, view_h), Color(0.02, 0.0, 0.0, 0.9))
	var so := Vector2(sin(_t * 91.0), cos(_t * 77.0)) * _shake * 3.0
	var center := Vector2(320, 160) + so
	var tex: String = CRATE_INFO[1 if _open_mil else 0]["tex"]
	_text_c(font, Vector2(320, 56), "ВОЕННЫЙ ЯЩИК" if _open_mil else "ОБЫЧНЫЙ ЯЩИК", GOLD if _open_mil else WHITE, 12)
	if _open_all:
		var left := _open_queue.size()
		_text_c(font, Vector2(320, 68), "вскрыто %d · осталось %d · Enter — пропуск · Esc — закончить" % [_open_log.size(), left], MUTED, 8)
	if _open in [Open.SHAKE, Open.LID, Open.FLASH]:
		_draw_crate_stage(tex, center, accent)
	elif _open == Open.CARD:
		_draw_card(font, center, accent)
	elif _open == Open.SUMMARY:
		_draw_summary(font)
	if _open == Open.FLASH:
		var f := clampf(1.0 - _open_t / _stage_dur(Open.FLASH), 0.0, 1.0)
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(Vector2.ZERO, size), Color(accent.lerp(Color.WHITE, 0.55), 0.92 * f * f))
		_ts()
	elif _open == Open.LID:
		var f := clampf(_open_t / _stage_dur(Open.LID), 0.0, 1.0)
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(Vector2.ZERO, size), Color(accent, 0.18 * f))
		_ts()


func _draw_crate_stage(tex: String, center: Vector2, accent: Color) -> void:
	var crate_center := center + Vector2(0, 22)
	var shake_off := Vector2.ZERO
	var rot := 0.0
	var lid_off := Vector2.ZERO
	var lid_rot := 0.0
	var lid_alpha := 1.0
	var glow := 0.0
	if _open == Open.SHAKE:
		var u := _open_t / _stage_dur(Open.SHAKE)
		var amp := 0.6 + u * u * 3.4
		shake_off = Vector2(sin(_open_t * 73.0) * amp, cos(_open_t * 59.0) * amp * 0.35)
		rot = sin(_open_t * 47.0) * 0.012 * (1.0 + u * 4.0)
		glow = clampf((u - 0.55) / 0.45, 0.0, 1.0) * 0.55 # свет из щели выдаёт цвет находки
	else:
		var since := _open_t if _open == Open.LID else _stage_dur(Open.LID) + _open_t
		since /= _open_fast
		lid_off = Vector2(150.0 * since, -250.0 * since + 520.0 * since * since)
		lid_rot = since * 6.5
		lid_alpha = clampf(1.6 - since * 1.8, 0.0, 1.0)
		glow = 1.0
	# тень под ящиком
	PixelArt.draw_dot(self, crate_center + Vector2(0, 34), 70.0, Color(0, 0, 0, 0.4))
	if _open != Open.SHAKE:
		# луч света из открытого ящика
		var top := crate_center + Vector2(0, -26)
		var beam := PackedVector2Array([top + Vector2(-56, 0), top + Vector2(56, 0), top + Vector2(120, -170), top + Vector2(-120, -170)])
		var a := 0.85 * clampf(_open_t / 0.12 if _open == Open.LID else 1.0, 0.0, 1.0)
		var cols := PackedColorArray([Color(accent, a), Color(accent, a), Color(accent, 0.0), Color(accent, 0.0)])
		draw_polygon(beam, cols)
		draw_rect(Rect2(top + Vector2(-54, -2), Vector2(108, 4)), Color(accent.lerp(Color.WHITE, 0.6), a))
	if glow > 0.0 and _open == Open.SHAKE:
		var seam := crate_center + Vector2(0, -26)
		draw_rect(Rect2(seam + Vector2(-48, -1.5), Vector2(96, 3)), Color(accent.lerp(Color.WHITE, 0.4), glow))
		draw_rect(Rect2(seam + Vector2(-60, -6), Vector2(120, 12)), Color(accent, glow * 0.18))
	# корпус и крышка со смещением и наклоном
	if absf(rot) > 0.0:
		draw_set_transform((crate_center + shake_off + _origin) * _ui, rot, Vector2(_ui, _ui))
		_crate_local(tex, lid_off, lid_rot, lid_alpha)
		_ts()
	else:
		_crate(tex, crate_center + shake_off, 4, lid_off, lid_rot, lid_alpha)


## Ящик в локальных координатах (после draw_set_transform с поворотом): центр корпуса — (0, 0).
func _crate_local(tex: String, lid_off: Vector2, lid_rot: float, lid_alpha: float) -> void:
	var body: Texture2D = _tex[tex + "_body"]
	var lid: Texture2D = _tex[tex + "_lid"]
	var bs := body.get_size() * 4.0 / 3.0
	var ls := lid.get_size() * 4.0 / 3.0
	draw_texture_rect(body, Rect2(-bs * 0.5, bs), false)
	var lid_center := Vector2(0, -bs.y * 0.5 - ls.y * 0.5 + 2.0) + lid_off
	draw_texture_rect(lid, Rect2(lid_center - ls * 0.5, ls), false, Color(1, 1, 1, lid_alpha))


func _draw_card(font: Font, center: Vector2, accent: Color) -> void:
	var res := _open_res
	var pop := clampf(_open_t / 0.3, 0.0, 1.0)
	var ease := 1.0 + 2.2 * pow(pop - 1.0, 3.0) + 1.2 * pow(pop - 1.0, 2.0) # выезд с лёгким перелётом
	var is_new: bool = res["kind"] == "model" and not res["duplicate"]
	var cx := 320.0
	var cy := 176.0
	# лучи за карточкой у новой модели и редкой находки
	if is_new or res["rare"]:
		for i in 18:
			var a := _t * 0.35 + i * TAU / 18.0
			var d1 := Vector2(cos(a), sin(a))
			var d2 := Vector2(cos(a + 0.09), sin(a + 0.09))
			var c := Vector2(cx, cy)
			var al := (0.2 if res["rare"] else 0.11) * pop
			draw_polygon(PackedVector2Array([c, c + d1 * 260.0, c + d2 * 260.0]),
				PackedColorArray([Color(accent, al * 1.6), Color(accent, 0.0), Color(accent, 0.0)]))
		# искры
		var n := 28 if res["rare"] else 12
		for i in n:
			var ang := i * 2.399963
			var sp := 40.0 + (i * 37 % 90)
			var life := fmod(_open_t * 0.9 + i * 0.173, 1.4)
			var p := Vector2(cx, cy) + Vector2(cos(ang), sin(ang) * 0.8) * (30.0 + sp * life)
			draw_rect(Rect2(p, Vector2(2, 2)), Color(accent.lerp(Color.WHITE, 0.5), clampf(1.0 - life / 1.4, 0.0, 1.0)))
	var w := 236.0 * ease
	var h := 156.0 * ease
	var r := Rect2(cx - w * 0.5, cy - h * 0.5 + (1.0 - pop) * 14.0, w, h)
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.5))
	draw_rect(r, Color(0.06, 0.055, 0.055, 0.98))
	draw_rect(r, Color(accent, 0.9), false, 1.0)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), accent)
	if pop < 0.7:
		return
	var fa := clampf((pop - 0.7) / 0.3, 0.0, 1.0)
	var top := r.position.y
	if res["kind"] == "model":
		var model: String = res["model"]
		var m: Dictionary = WeaponDefs.MODELS[model]
		var head := "НОВАЯ МОДЕЛЬ!"
		var head_c := accent
		if res["duplicate"]:
			head = "ДУБЛИКАТ"
			head_c = MUTED
		_text_c(font, Vector2(cx, top + 18), head, Color(head_c, fa), 12)
		draw_rect(Rect2(cx - 100, top + 25, 200, 52), Color(0.03, 0.03, 0.03, 0.9 * fa))
		draw_rect(Rect2(cx - 100, top + 25, 200, 52), Color(accent, 0.3 * fa), false, 1.0)
		_gun(model, Vector2(cx, top + 51), 4, Color(1, 1, 1, fa) if not res["duplicate"] else Color(0.55, 0.55, 0.55, fa))
		_text_c(font, Vector2(cx, top + 92), str(m["name"]), Color(accent, fa), 13)
		var sub := "%s · %s" % [CATEGORY_NAMES[int(m["base"])].to_lower(), WeaponDefs.RARITY_NAMES[int(m["rarity"])]]
		_text_c(font, Vector2(cx, top + 103), sub, Color(MUTED, fa), 8)
		if res["duplicate"]:
			_text_c(font, Vector2(cx, top + 126), "уже в Арсенале → +%d ДНК" % res["dna"], Color(GOLD, fa), 12)
		else:
			var tr: Dictionary = WeaponDefs.TRAITS[m["trait"]]
			_text_c(font, Vector2(cx, top + 116), "черта: " + str(tr["name"]), Color(GOLD, fa), 9)
			var yy := top + 127.0
			for line in _wrap(font, str(tr["text"]), 214.0, 8):
				_text_c(font, Vector2(cx, yy), line, Color(WHITE, 0.85 * fa), 8)
				yy += 9.5
	else:
		_text_c(font, Vector2(cx, top + 18), "ПАЧКА ДНК", Color(accent, fa), 12)
		_dna_icon(Vector2(cx, top + 62), 44.0, Color(GOLD, fa))
		_text_c(font, Vector2(cx, top + 118), "+%d ДНК" % res["dna"], Color(GOLD, fa), 20)
		_text_c(font, Vector2(cx, top + 132), "добавлено на счёт", Color(MUTED, fa), 8)
	var hint := "Enter / клик — дальше"
	if _open_all and not _open_queue.is_empty():
		hint = "дальше через %.1f с · Enter / клик — сразу" % maxf(AUTO_NEXT - _open_t, 0.0)
	_text_c(font, Vector2(cx, r.end.y - 6), hint, Color(DIM, fa), 7)


func _draw_summary(font: Font) -> void:
	var new_models: Array[String] = []
	var dupes := 0
	var packs := 0
	for e in _open_log:
		var res: Dictionary = e["res"]
		if res["kind"] == "model" and not res["duplicate"]:
			new_models.append(res["model"])
		elif res["kind"] == "model":
			dupes += int(res["dna"])
		else:
			packs += int(res["dna"])
	var h := 120.0 + new_models.size() * 12.0
	var r := Rect2(190, 176.0 - h * 0.5, 260, h)
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.5))
	draw_rect(r, Color(0.06, 0.055, 0.055, 0.98))
	draw_rect(r, Color(GOLD, 0.8), false, 1.0)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), GOLD)
	_text_c(font, Vector2(320, r.position.y + 20), "ВСКРЫТО ЯЩИКОВ: %d" % _open_log.size(), GOLD, 13)
	var y := r.position.y + 38.0
	if new_models.is_empty():
		_text(font, Vector2(r.position.x + 14, y), "Новых моделей нет", MUTED, 9)
		y += 12
	for model in new_models:
		var m: Dictionary = WeaponDefs.MODELS[model]
		_text(font, Vector2(r.position.x + 14, y), "НОВАЯ: " + str(m["name"]), RARE if m["rarity"] == WeaponDefs.Rarity.RARE else WHITE, 9)
		y += 12
	y += 6
	_text(font, Vector2(r.position.x + 14, y), "Пачки ДНК", MUTED, 9)
	_text_r(font, Vector2(r.end.x - 14, y), "+%d" % packs, WHITE, 9)
	y += 12
	_text(font, Vector2(r.position.x + 14, y), "Дубликаты → ДНК", MUTED, 9)
	_text_r(font, Vector2(r.end.x - 14, y), "+%d" % dupes, WHITE, 9)
	y += 14
	_text(font, Vector2(r.position.x + 14, y), "ИТОГО ДНК", GOLD, 11)
	_text_r(font, Vector2(r.end.x - 14, y), "+%d" % (packs + dupes), GOLD, 11)
	_text_c(font, Vector2(320, r.end.y - 6), "Enter / клик — на склад", DIM, 7)


# --- оперативная карта --------------------------------------------------------------------------

func _open_operations() -> void:
	if _globe == null:
		_globe = GLOBE_SCENE.instantiate() as GlobeView
		add_child(_globe)
		# Настройки всегда перекрывают дисплей и перехватывают ввод.
		move_child(_settings_menu, -1)
		_globe.region_selected.connect(_select_region)
	_globe.refresh()
	_globe.set_active(true)
	_select_region(_op_region, false)
	if not Campaign.last_report().is_empty():
		_globe.show_changes(Campaign.last_report())


func _sync_globe() -> void:
	if _tab == Tab.OPERATIONS:
		_open_operations()
	elif _globe != null:
		_globe.set_active(false)


func _select_region(id: String, sound := true) -> void:
	_op_region = id
	_op_sel = -1
	_op_journal = false
	_op_scroll = 0
	var offers := Campaign.offers()
	for i in offers.size():
		if offers[i]["region_id"] == id and _operation_matches(offers[i]):
			_op_sel = i
			break
	_op_armed = _op_sel >= 0
	_globe.focus_region(id)
	if sound:
		_play("ui/deny" if int(Campaign.region_info(id)["stage"]) >= 3 else "ui/click", -8.0)


func _select_operation(index: int) -> void:
	var offers := Campaign.offers()
	if index < 0 or index >= offers.size():
		return
	_select_region(offers[index]["region_id"])
	_op_sel = index
	_op_armed = true


func _nav_operations(step: int) -> void:
	var entries: Array[Dictionary] = []
	var regions: Array[String] = []
	var offers := Campaign.offers()
	# Каждое задание отдельно: в одном регионе могут быть зачистка и улей.
	for i in offers.size():
		var op := offers[i]
		if _operation_matches(op):
			entries.append({"region": op["region_id"], "operation": i})
			regions.append(op["region_id"])
	for id: String in CampaignCatalog.REGIONS:
		if not regions.has(id) and _globe.matches_filter(Campaign.region_info(id)):
			entries.append({"region": id, "operation": -1})
	if entries.is_empty():
		return
	var current := -1
	for i in entries.size():
		if entries[i]["region"] == _op_region and entries[i]["operation"] == _op_sel:
			current = i
	var next := entries[posmod(current + step, entries.size())]
	_select_region(next["region"], false)
	_op_sel = int(next["operation"])
	_op_armed = false


func _start_campaign() -> void:
	if _leaving or _op_sel < 0:
		return
	var offers := Campaign.offers()
	if _op_sel >= offers.size():
		return
	var config := Campaign.start_operation(offers[_op_sel]["id"])
	if config.is_empty():
		_toast("Запуск отменён. Проверьте запись рапорта на диск.")
		return
	_go_fight()


func _op_card_rect() -> Rect2:
	return Rect2(416, 64, 216, 238)


func _operation_matches(op: Dictionary) -> bool:
	if _op_filter == 2:
		return int(op["threat"]) <= 2
	if _op_filter == 3:
		return op["type"] == "nest"
	return _globe.matches_filter(Campaign.region_info(op["region_id"]))


func _draw_operations(font: Font) -> void:
	draw_rect(Rect2(8, 64, 624, 238), Color("080d0e"))
	_box(Rect2(8, 64, 130, 238), MUTED, 0.3, Color("101616"), false)
	_box(_op_card_rect(), MUTED, 0.3, Color("101616"), false)
	var world := Campaign.world()
	var critical := 0
	var nests := 0
	for region: Dictionary in world["regions"].values():
		if int(region["infection"]) >= 60:
			critical += 1
	for id: String in world["nests"]:
		if world["nests"][id]["alive"] and CampaignCatalog.NESTS[id]["playable"]:
			nests += 1
	_text(font, Vector2(16, 79), "Z.E.R.A. / ЗЕМЛЯ", WHITE, 10)
	_text(font, Vector2(16, 96), "ХОД %03d" % int(world["turn"]), GOLD, 14)
	_text(font, Vector2(16, 110), "Очагов активно: %d" % nests, WHITE, 8)
	_text(font, Vector2(16, 121), "Регионов в критическом: %d" % critical, RED if critical > 0 else MUTED, 8)
	for i in 4:
		_button(font, Rect2(16 + (i % 2) * 59, 130 + (i / 2) * 18, 55, 15), ["Все", "Критические", "Доступные", "Ульи"][i], GOLD if _op_filter == i else MUTED, "op_filter:%d" % i, true, 7)
	_text(font, Vector2(16, 181), "ЗАДАНИЯ ДИСПЕТЧЕРА", MUTED, 7)
	var offers := Campaign.offers()
	var shown := 0
	for i in offers.size():
		var op := offers[i]
		if not _operation_matches(op):
			continue
		var y := 184.0 + shown * 32.0
		shown += 1
		var chosen := _op_sel == i
		var color := GOLD if chosen else WHITE
		var r := Rect2(14, y, 118, 30)
		draw_rect(r, Color("30291b") if chosen else Color("1b2220"))
		draw_rect(r, Color(color, 0.65 if chosen else 0.2), false)
		_text(font, Vector2(18, y + 10), "[%d] %s · %s" % [i + 1, "УЛЕЙ" if op["type"] == "nest" else "ЗАЧИСТКА", _roman(op["threat"])], color, 7)
		_text(font, Vector2(18, y + 19), str(op["name"]), color, 7)
		_text(font, Vector2(18, y + 27), str(CampaignCatalog.REGIONS[op["region_id"]]["name"]), MUTED, 6)
		_hit(r, "op:%d" % i)
	if shown == 0:
		_text(font, Vector2(16, 204), "Заданий в фильтре нет", DIM, 7)
	_text(font, Vector2(16, 289), "Один рапорт — один ход.", DIM, 7)
	var info := Campaign.region_info(_op_region)
	var accent: Color = GlobeView.COLORS[int(info["stage"])]
	_text(font, Vector2(424, 78), str(info["name"]).to_upper(), WHITE, 10)
	_text(font, Vector2(424, 91), "%s · %d / 100" % [info["stage_name"], info["infection"]], accent, 9)
	_button(font, Rect2(424, 97, 199, 14), "ЖУРНАЛ ПРИЧИН  /  РЕГИОН", GOLD if _op_journal else MUTED, "op_journal", true, 7)
	if _op_journal:
		_draw_operation_journal(font, info)
		return
	if _op_sel < 0:
		var y := 129.0
		for line in _wrap(font, "Операций в этом регионе сейчас нет. Выберите задание Диспетчера слева.", 196, 9):
			_text(font, Vector2(424, y), line, MUTED, 9)
			y += 12
		for nest: Dictionary in info["nests"]:
			for line in _wrap(font, "%s: %s" % [nest["name"], nest["status"] if nest["alive"] else "Уничтожен"], 196, 8):
				y += 11
				_text(font, Vector2(424, y), line, RED if nest["playable"] else DIM, 8)
		_button(font, Rect2(424, 277, 199, 18), "НАЗАД [B / Esc]", MUTED, "op_back", true, 8)
		return
	var op := offers[_op_sel]
	_text(font, Vector2(424, 124), str(op["name"]).to_upper(), GOLD, 11)
	_text(font, Vector2(424, 137), "%s · УГРОЗА %s / V" % ["УДАР ПО УЛЬЮ" if op["type"] == "nest" else "ЗАЧИСТКА", _roman(op["threat"])], accent, 8)
	var y := 149.0
	for line in _wrap(font, str(op["briefing"]), 196, 8):
		_text(font, Vector2(424, y), line, WHITE, 8)
		y += 10
	y += 3
	if op["modifiers"].is_empty():
		_text(font, Vector2(424, y), "Условия: штатный периметр", MUTED, 8)
		y += 10
	for modifier: String in op["modifiers"]:
		_text(font, Vector2(424, y), str(MODIFIER_TEXT[modifier]), MUTED, 8)
		y += 10
	y += 4
	_text(font, Vector2(424, y), "НАГРАДА ЗА ВЫПОЛНЕНИЕ", GOLD, 7)
	y += 11
	_text(font, Vector2(424, y), "ДНК ×%.2f · доп. ящик: %.0f%%" % [op["reward"]["dna_mul"], float(op["reward"]["extra_crate_chance"]) * 100.0], WHITE, 8)
	y += 11
	var effect: Dictionary = op["effects"]["win"]
	_text(font, Vector2(424, y), "Прямой эффект: %d; соседям %d" % [effect["infection"], effect["neighbors"]], GREEN, 8)
	y += 10
	_text(font, Vector2(424, y), "Затем — один перерасчёт фронта.", MUTED, 8)
	y += 10
	_text(font, Vector2(424, y), "Провал: +%d; рост давления на регион." % int(op["effects"]["loss"]["infection"]), RED, 8)
	# Постоянный эффект улья и подавление отличают стратегическую цель от обычной зачистки.
	y += 10
	_text(font, Vector2(424, y), "Улей исчезнет навсегда; защита 3 хода." if op["type"] == "nest" else "Подавление: %d пересчёта фронта." % int(effect["suppression"]), MUTED, 7)
	_button(font, Rect2(424, 267, 199, 19), "НАЧАТЬ ОПЕРАЦИЮ [A / E]", GOLD, "op_start", true, 9)
	_text(font, Vector2(424, 297), "B / Esc — назад · образцы сохранятся", DIM, 7)


func _draw_operation_journal(font: Font, info: Dictionary) -> void:
	var rows: Array[String] = []
	rows.append("СЕЙЧАС / ДАВЛЕНИЕ")
	for cause: String in info["danger_reasons"]:
		rows.append(cause)
	if info["danger_reasons"].is_empty():
		rows.append("Источников давления нет")
	for nest: Dictionary in info["nests"]:
		rows.append("%s: %s" % [nest["name"], nest["status"] if nest["alive"] else "Уничтожен"])
	for change: Dictionary in Campaign.last_report().get("changes", []):
		if change["region_id"] == _op_region:
			rows.append("ПОСЛЕДНИЙ РАПОРТ: %d → %d" % [change["from"], change["to"]])
			for cause: String in change["causes"]:
				rows.append(cause)
	var wrapped: Array[String] = []
	for row: String in rows:
		wrapped.append_array(_wrap(font, row, 195, 8))
	_op_scroll = clampi(_op_scroll, 0, maxi(0, wrapped.size() - 13))
	for i in mini(13, wrapped.size() - _op_scroll):
		_text(font, Vector2(424, 126 + i * 10), wrapped[_op_scroll + i], WHITE, 8)
	_button(font, Rect2(424, 265, 96, 16), "↑ ВЫШЕ", MUTED, "op_scroll:0", true, 7)
	_button(font, Rect2(527, 265, 96, 16), "↓ НИЖЕ", MUTED, "op_scroll:1", true, 7)
	_button(font, Rect2(424, 283, 199, 15), "К БРИФИНГУ [B / Esc]", GOLD, "op_journal", true, 7)


func _roman(tier: int) -> String:
	return ["I", "II", "III", "IV", "V"][clampi(tier - 1, 0, 4)]


# --- тест --------------------------------------------------------------------------------------

static func _check(name: String, ok: bool) -> void:
	_test_checks += 1
	if not ok:
		_test_fails += 1
	print("BASETEST %s %s" % [name, "ok" if ok else "FAIL"])


func _shot(suffix: String) -> void:
	if _shot_path == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var path := _shot_path.get_basename() + "_" + suffix + ".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("BASETEST screenshot: ", path)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _test_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await get_tree().process_frame


func _test_click(at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = (at + _origin) * _ui
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await get_tree().process_frame


func _run_test() -> void:
	if _test_stage > 0:
		await _run_test_back()
		return
	_check("isolated before base ready", not Meta.persist and Meta.runs == 0)
	for flag: String in ["--sim=600", "--bench=500", "--boss", "--alarm", "--ui-test", "--weapons-test", "--loadout", "--loadout-w1", "--s3-test", "--meta-test", "--meta-preset=maxed", "--meta={}", "--save-file=user://test.json", "--fresh-save", "--kinds", "--gore-stress"]:
		_check("route " + flag, _goes_straight_to_battle(PackedStringArray([flag])))
	_check("normal launch stays on base", not _goes_straight_to_battle(PackedStringArray()))
	_check("route --audio-test", _goes_straight_to_battle(PackedStringArray(["--audio-test"])))
	await _wait(0.1)
	await _test_click(Vector2(545, 49))
	_check("settings mouse open", _settings_menu.visible and _settings_menu.settings_open and not get_tree().paused)
	await _test_key(KEY_ESCAPE)
	_check("settings back", not _settings_menu.visible and not get_tree().paused)
	await _test_key(KEY_O)
	_check("settings keyboard open", _settings_menu.visible)
	await _test_key(KEY_ESCAPE)
	# временное сохранение: настоящее user://zera_save.json не читается и не пишется
	Meta.persist = false
	Meta.reset()
	Meta.rng.seed = 60606
	Meta.dna_earned = Meta.dna_for_level(5) + 60
	Meta.dna = 540
	Meta.crates = 3
	Meta.military_crates = 2
	Meta.owned.append("m4")
	Meta.owned.append("guard")
	await _wait(0.7)
	await _test_key(KEY_2)
	_check("keyboard tab 2", _tab == Tab.WORKSHOP)
	await _test_click(Vector2(280, 49))
	_check("mouse tab 3", _tab == Tab.ARSENAL)
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_RIGHT_SHOULDER
	pad.pressed = true
	Input.parse_input_event(pad)
	await get_tree().process_frame
	_check("gamepad RB tab 4", _tab == Tab.CRATES)
	await _test_key(KEY_1)
	_check("start level=5 points=4", Meta.class_level() == 5 and Meta.skill_points() == 4)
	# казарма: открыть узлы, закрытый узел не открывается
	_set_tab(Tab.BARRACKS)
	_sel_node = 0
	await _test_key(KEY_E)
	_check("barracks confirmation before spend", not Meta.tree.has("fire_1") and _confirm_node == "fire_1")
	await _wait(0.2)
	await _shot("confirm")
	_cancel()
	_check("barracks cancel keeps point", Meta.skill_points() == 4)
	_unlock_selected()
	_confirm()
	_sel_node = 3
	_unlock_selected()
	_confirm()
	_check("barracks fire_1+mag_1 points=2", Meta.tree.has("fire_1") and Meta.tree.has("mag_1") and Meta.skill_points() == 2)
	_sel_node = 2
	_unlock_selected()
	_check("barracks locked fire_3 refused", not Meta.tree.has("fire_3") and Meta.skill_points() == 2)
	_sel_node = 1
	_msg_t = 0.0
	await _wait(0.4)
	await _shot("barracks")
	# мастерская: купить улучшения «М4»
	_set_tab(Tab.WORKSHOP)
	var models := _ws_models()
	_ws_sel = models.find("m4")
	_ws_stat = 0
	var dna0 := Meta.dna
	_buy_selected()
	_buy_selected()
	_ws_stat = 2
	_buy_selected()
	_check("workshop m4 damage=2 mag=1 dna=%d" % (dna0 - 20 - 40 - 20), Meta.workshop_level("m4", "damage") == 2 and Meta.workshop_level("m4", "mag") == 1 and Meta.dna == dna0 - 80)
	var balance := Meta.dna
	Meta.dna = 0
	_buy_selected()
	_check("workshop insufficient dna refused", Meta.workshop_level("m4", "mag") == 1 and Meta.dna == 0)
	Meta.dna = balance
	_msg_t = 0.0
	_ws_stat = 0
	await _wait(0.4)
	await _shot("workshop")
	# арсенал: избранная модель
	_set_tab(Tab.ARSENAL)
	_ars_sel = WeaponDefs.MODEL_ORDER.find("m4")
	_favorite_selected()
	_check("arsenal favorite rifle=m4", Meta.model_for(WeaponDefs.Base.RIFLE) == "m4")
	_ars_sel = WeaponDefs.MODEL_ORDER.find("guard")
	await _wait(0.4)
	await _shot("arsenal")
	# склад: вскрыть один ящик (снимок в середине анимации), затем редкую находку
	_set_tab(Tab.CRATES)
	_crate_sel = 0
	await _wait(0.3)
	await _shot("crates")
	var crates0 := Meta.crates
	_open_selected()
	_check("crate opening started crates=%d" % (crates0 - 1), _open == Open.SHAKE and Meta.crates == crates0 - 1)
	while _open != Open.LID:
		await _wait(0.02)
	await _wait(0.1)
	await _shot("crate_open")
	while _open != Open.CARD:
		await _wait(0.02)
	await _wait(0.6)
	await _shot("crate_card")
	_check("crate result recorded", _history.size() == 1)
	_advance()
	_check("crate card closed", _open == Open.NONE)
	var rare_res := {}
	for i in 300:
		Meta.military_crates += 1
		var res := Meta.open_crate(true)
		if res["kind"] == "model" and res["rare"] and not res["duplicate"]:
			rare_res = res
			break
	_check("rare model found", not rare_res.is_empty())
	if not rare_res.is_empty():
		_present(rare_res, true)
		_skip()
		await _wait(0.9)
		await _shot("crate_rare")
		_check("rare owned %s" % rare_res["model"], Meta.is_owned(rare_res["model"]))
		_advance()
	# «вскрыть все» с пропуском анимации
	var total := Meta.crates + Meta.military_crates
	var dna_before := Meta.dna
	_open_everything()
	var guard := 0
	var shot_summary := false
	while _open != Open.NONE and guard < 400:
		guard += 1
		await _wait(0.05)
		if _open == Open.SUMMARY and not shot_summary:
			shot_summary = true
			await _wait(0.3)
			await _shot("crate_all")
		if guard % 3 == 0 or _open == Open.SUMMARY:
			_advance()
	_check("open all total=%d crates=0" % total, Meta.crates == 0 and Meta.military_crates == 0 and _open_log.size() == total)
	_check("open all dna_not_lost", Meta.dna >= dna_before)
	Meta.military_crates = 1
	_open_everything()
	_check("open all single military", Meta.military_crates == 0 and _open_mil and _open_queue.is_empty())
	_advance()
	_advance()
	_check("single military closes", _open == Open.NONE)
	# в бой и обратно: игра сама откроет итоги и вернёт на базу
	_test_dna = Meta.dna
	_test_crates = Meta.crates
	_test_stage = 1
	print("BASETEST to battle: dna=%d favorite_rifle=%s" % [_test_dna, Meta.model_for(WeaponDefs.Base.RIFLE)])
	await _test_key(KEY_ENTER)


func _run_test_back() -> void:
	await _wait(0.7)
	print("BASETEST back on base: dna=%d crates=%d military=%d runs=%d" % [Meta.dna, Meta.crates, Meta.military_crates, Meta.runs])
	_check("back: run rewards dna>%d" % _test_dna, Meta.dna > _test_dna)
	_check("back: crates 2/1 from run", Meta.crates == _test_crates + 2 and Meta.military_crates == 1)
	_check("back: favorite kept", Meta.model_for(WeaponDefs.Base.RIFLE) == "m4" and Meta.workshop_level("m4", "damage") == 2)
	_set_tab(Tab.CRATES)
	await _wait(0.4)
	await _shot("back")
	print("BASETEST checks=%d failed=%d" % [_test_checks, _test_fails])
	print("BASETEST ok=%s" % str(_test_fails == 0))
	get_tree().quit(0 if _test_fails == 0 else 1)
