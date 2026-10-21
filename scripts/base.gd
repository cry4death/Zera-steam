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
const Style := preload("res://scripts/ui/zera_style.gd")
const GOLD := Style.SELECTED
const WHITE := Style.TEXT
const MUTED := Style.MUTED
const DIM := Style.DISABLED
const RED := Style.DANGER
const GREEN := Style.BETTER
const RARE := Style.RARE
const PROTO := Color("b7957c")
const PANEL := Style.METAL
const PANEL_DARK := Style.RECESS

const TAB_NAMES := ["КАЗАРМА", "МАСТЕРСКАЯ", "АРСЕНАЛ", "СКЛАД", "ОПЕРАЦИИ"]
const GLOBE_SCENE := preload("res://scenes/globe_view.tscn")
const CATEGORY_NAMES := ["АВТОМАТЫ", "ДРОБОВИКИ", "РЕЙЛГАНЫ", "ГРАНАТОМЁТЫ", "ПИСТОЛЕТЫ", "РЕВОЛЬВЕРЫ", "ПП", "ВИНТОВКИ",
	"ПУЛЕМЁТЫ", "МИНИГАНЫ", "ОГНЕМЁТЫ", "ПИЛЫ", "АРБАЛЕТЫ", "АВТОДРОБОВИКИ", "МАРКСМАНСКИЕ", "РАЗРЯДНИКИ"] # по WeaponDefs.Base
const BRANCH_COLORS := [Color(1.0, 0.52, 0.30), Color(1.0, 0.82, 0.35), Color(0.55, 0.92, 0.60)]
const STAT_LABELS := {"damage": "УРОН", "rate": "СКОРОСТРЕЛЬНОСТЬ", "mag": "МАГАЗИН", "reload": "ПЕРЕЗАРЯДКА"}
const RARITY_COLORS := [Color(0.72, 0.72, 0.68), WHITE, RARE]
const CRATE_INFO := [
	{"name": "ОБЫЧНЫЙ ЯЩИК", "odds": ["модель 50% (редкая 15%)", "образцы 50% · 30–80"], "tex": "base_crate"},
	{"name": "ВОЕННЫЙ ЯЩИК", "odds": ["модель 80% (редкая 50%)", "образцы 20% · 30–80"], "tex": "base_crate_mil"},
]

# анимация вскрытия, секунды (у «вскрыть все» со второго ящика — быстрее)
const SHAKE_T := 0.45
const LID_T := 0.3
const FLASH_T := 0.15
const AUTO_NEXT := 1.6
const FADE_T := 0.35

# состояние тест-режима живёт между сценами (бой и возврат на базу)
static var _test_stage := 0
static var _test_checks := 0
static var _test_fails := 0
static var _test_dna := 0
static var _test_crates := 0

var _ui := 3.0
var _layout: SettingsLayout.Scroll
var _reveal_selection := true
var _origin := Vector2.ZERO
var _t := 0.0
var _dna_prev := -1 # счётчик ДНК в прошлом кадре: рост запускает короткое выделение
var _dna_flash := 0.0
var _tab: int = Tab.OPERATIONS
var _globe: GlobeView
var _op_region := "east_europe"
var _op_sel := -1
var _op_filter := 0
var _op_armed := false
var _op_journal := false
var _op_scroll := 0
var _op_pad := false
var _op_tips: Dictionary = {}
static var _globe_test_started := false
var _hits: Array[Dictionary] = []
var _hover_key := ""
var _pad_mode := false # последним использовалось устройство: геймпад (подсказки внизу)
var _mouse := Vector2(-1000, -1000)
var _msg := ""
var _msg_t := 0.0
var _leaving := false
var _endless_open := false
var _endless_map := 0
var _endless_kind := 0
var _fade := 1.0
var _stick := Vector2i.ZERO

var _sel_node := 0 # казарма: ветка * 8 + узел
var _tree_icons: Texture2D
const TREE_ICONS := ["bullet", "sight", "burst", "brace", "reload", "mag", "boot", "shield", "vest", "med", "clock", "grenade", "blast", "turret", "dna", "area", "charge", "throw", "wave", "repel", "grenade_cooldown", "grenade_reload", "grenade_speed", "fuse", "fragments"]
var _ws_sel := 0 # мастерская: индекс в списке открытых моделей
var _ws_stat := 0
var _reward_t := 0.0
var _reward_text := ""
var _crate_odds := false
var _crate_journal := false
var _ars_scroll := 0
var _ars_order: Array = WeaponDefs.MODEL_ORDER.duplicate()
var _ws_scroll := 0
var _tree_focus := 0
var _ars_sel := 0 # арсенал: индекс в WeaponDefs.MODEL_ORDER
var _ars_seen := -1
var _ars_time := 1.0
var _ars_feedback := 0.0
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
var _steel: Texture2D
var _canvas: Texture2D
var _tex: Dictionary = {}
var _test := false
var _shot_path := ""
var _op_preview: Dictionary = {}
var _op_failure: Dictionary = {}
var _op_preview_id := ""
var _front_seen := ""
var _report_seen := ""


var _choice_input := ChoiceInput.new()

func _ready() -> void:
	if Meta.test_errors > 0:
		Meta.finish_test(1)
		return
	var args := OS.get_cmdline_user_args()
	_test = args.has("--base-test")
	var globe_test := args.has("--globe-test") or args.has("--c6-capture") or args.has("--cp1-capture")
	if Meta.needs_first_run() and not get_tree().has_meta("s6_return_to_base") and (args.is_empty() or args == PackedStringArray(["--fresh-save"])):
		Meta.begin_first_run()
		get_tree().set_meta("first_run_active", true)
		visible = false
		get_tree().change_scene_to_file.call_deferred(MAIN_SCENE)
		return
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
	_layout = SettingsLayout.Scroll.new(self)
	_settings_menu = PauseMenu.new()
	add_child(_settings_menu)
	_settings_menu.sfx = _sfx
	_steel = PixelArt.tex("ui_steel")
	_canvas = PixelArt.tex("ui_canvas")
	_tree_icons = PixelArt.tex("tree_t2_icons")
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
	if Meta.campaign["phase"] in ["victory", "defeat"]:
		_tab = Tab.OPERATIONS
	if not _test and not globe_test and not Meta.tab_open(_tab):
		_tab = Tab.ARSENAL
	Meta.visit_tab(_tab)
	if _tab == Tab.OPERATIONS:
		_open_operations()
	Music.play(&"globe" if _tab == Tab.OPERATIONS else &"base")
	if get_tree().has_meta("endless_capture"):
		get_tree().remove_meta("endless_capture")
		_capture_endless_base.call_deferred()
	elif get_tree().has_meta("endless_launch_test") and int(get_tree().get_meta("endless_launch_test")) == 3:
		_check("endless return clears mode", not get_tree().has_meta("endless_config") and not get_tree().paused)
		get_tree().remove_meta("endless_launch_test")
		get_tree().remove_meta("endless_expected")
		print("ENDLESSSHOTS screenshots=5 checks=%d failed=%d" % [_test_checks, _test_fails])
		Meta.finish_test(0 if _test_fails == 0 else 1)
	if args.has("--cp1-capture"):
		load("res://scripts/campaign/cp1_capture.gd").run.call_deferred(self)
	elif args.has("--c6-capture"):
		CampaignCapture.run.call_deferred(self)
	elif globe_test and not _globe_test_started:
		_globe_test_started = true
		GlobeView.run_test.call_deferred(self, _shot_path)


## Тест-флаги игры и флаги меты: база пропускается.
static func _goes_straight_to_battle(args: PackedStringArray) -> bool:
	if args.has("--endless"):
		return true
	if args.has("--gun-range") or args.has("--gunlab-test") or args.has("--gunlab-render") or args.has("--gunlab-shots"):
		return true
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
	if event is InputEventMouseButton and event.shift_pressed and _layout.pointer(event):
		accept_event()
		return
	if _tab == Tab.OPERATIONS and _globe != null and not _endless_open:
		if event is InputEventMouse:
			_op_pad = false
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
	var list_wheel := event as InputEventMouseButton
	if list_wheel != null and list_wheel.pressed and list_wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var at := list_wheel.position / _ui - _origin
		var step := 1 if list_wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1
		if _tab == Tab.ARSENAL and at.x < 264:
			_ars_scroll = clampi(_ars_scroll + step, 0, maxi(0, _ars_rows().size() - 8))
			accept_event()
			return
		if _tab == Tab.WORKSHOP and at.x < 128:
			_ws_scroll = clampi(_ws_scroll + step, 0, maxi(0, _ws_models().size() - 7))
			_ws_sel = clampi(_ws_sel, _ws_scroll, _ws_scroll + 6)
			accept_event()
			return
	var motion := event as InputEventMouseMotion
	if _layout.pointer(event):
		accept_event()
		return
	if _tab == Tab.BARRACKS and _confirm_node.is_empty():
		var wheel := event as InputEventMouseButton
		if wheel != null and wheel.pressed:
			if wheel.button_index == MOUSE_BUTTON_MIDDLE and wheel.double_click:
				_tree_zoom = 1.0
				_tree_pan = Vector2.ZERO
				return
			if wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
				_tree_zoom = clampf(_tree_zoom + (0.2 if wheel.button_index == MOUSE_BUTTON_WHEEL_UP else -0.2), 1.0, 2.4)
				accept_event()
				return
		if motion != null and motion.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			_tree_pan += motion.relative / _ui
			accept_event()
			return
	if motion != null:
		_pad_mode = false
		_mouse = motion.position / _ui - _origin
		_hover_key = _key_at(_mouse)
		if _tab == Tab.BARRACKS and _confirm_node.is_empty() and _hover_key.begins_with("node:"):
			_sel_node = _hover_key.get_slice(":", 1).to_int()
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _hover_key != "" else Control.CURSOR_ARROW
	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		_mouse = button.position / _ui - _origin
		_click(_key_at(_mouse))
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	var pad_command := _choice_input.read(event)
	if _leaving or _settings_menu != null and _settings_menu.visible:
		return
	if _endless_open:
		_endless_input(event, pad_command)
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and (key.keycode == KEY_H or key.physical_keycode == KEY_H):
		_pad_mode = false
		_open_endless()
		return
	if _tab == Tab.BARRACKS and _confirm_node.is_empty():
		if key != null and key.pressed and key.keycode == KEY_HOME:
			_tree_zoom = 1.0
			_tree_pan = Vector2.ZERO
			return
		if key != null and key.pressed and key.keycode == KEY_C:
			_tree_class(ClassTree.CLASSES.find(Meta.class_id) + 1)
			return
		var pad := event as InputEventJoypadButton
		if pad != null and pad.pressed and pad.button_index == JOY_BUTTON_RIGHT_STICK:
			_tree_zoom = 1.0
			_tree_pan = Vector2.ZERO
			return
		if pad != null and pad.pressed and pad.button_index == JOY_BUTTON_Y:
			_tree_class(ClassTree.CLASSES.find(Meta.class_id) + 1)
			return
		var axis := event as InputEventJoypadMotion
		if axis != null and axis.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT] and axis.axis_value > 0.5:
			_tree_zoom = clampf(_tree_zoom + (0.2 if axis.axis == JOY_AXIS_TRIGGER_RIGHT else -0.2), 1.0, 2.4)
			return
	if key != null and key.pressed:
		_pad_mode = false
		if _tab == Tab.CRATES and not key.echo:
			if key.keycode == KEY_Q:
				_click("crate_odds")
				return
			if key.keycode == KEY_J:
				_click("crate_journal")
				return
		if _tab == Tab.BARRACKS and key.keycode == KEY_V and not key.echo:
			_focus_cluster(_tree_focus + 1)
			return
		if _tab == Tab.OPERATIONS:
			_op_pad = false
			if key.physical_keycode == KEY_Q or key.keycode == KEY_Q:
				if not key.echo:
					_click("op_filter:%d" % posmod(_op_filter + 1, 4))
				get_viewport().set_input_as_handled()
				return
			if key.physical_keycode == KEY_J or key.keycode == KEY_J:
				if not key.echo:
					_click("op_journal")
				get_viewport().set_input_as_handled()
				return
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
		if pad_command == "":
			return
		_pad_mode = true
		if _tab == Tab.CRATES:
			if pad.button_index == JOY_BUTTON_Y:
				_click("crate_odds")
				return
			if pad.button_index == JOY_BUTTON_BACK:
				_click("crate_journal")
				return
		if _tab == Tab.OPERATIONS:
			_op_pad = true
			if pad.button_index == JOY_BUTTON_Y:
				_click("op_filter:%d" % posmod(_op_filter + 1, 4))
				return
			if pad.button_index == JOY_BUTTON_BACK:
				_click("op_journal")
				return
		match pad.button_index:
			JOY_BUTTON_A: _confirm()
			JOY_BUTTON_B: _cancel()
			JOY_BUTTON_X: _all_pressed()
			JOY_BUTTON_START: _fight_pressed()
			JOY_BUTTON_BACK: _settings_menu.open(true)
			JOY_BUTTON_LEFT_SHOULDER: _step_tab(-1)
			JOY_BUTTON_RIGHT_SHOULDER: _step_tab(1)
			JOY_BUTTON_DPAD_LEFT: _nav(-1, 0)
			JOY_BUTTON_DPAD_RIGHT: _nav(1, 0)
			JOY_BUTTON_DPAD_UP: _nav(0, -1)
			JOY_BUTTON_DPAD_DOWN: _nav(0, 1)
		return
	var axis := event as InputEventJoypadMotion
	if _tab == Tab.OPERATIONS:
		if axis != null and absf(axis.axis_value) > 0.22:
			_op_pad = true
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
	if _reveal_selection:
		var target: String = {Tab.ARSENAL: "ars:%d" % _ars_sel, Tab.WORKSHOP: "wss:%d" % _ws_stat, Tab.BARRACKS: "node:%d" % _sel_node, Tab.CRATES: "csel:%d" % _crate_sel, Tab.OPERATIONS: "op:%d" % _op_sel}.get(_tab, "")
		if key == target:
			_layout.reveal(Rect2(r.position + _origin - _layout.offset / _ui, r.size).grow(4))
			_reveal_selection = false


func _hot(key: String) -> bool:
	return _hover_key == key


func _click(key: String) -> void:
	if key == "endless":
		_open_endless()
		return
	if _endless_open:
		match key.get_slice(":", 0):
			"endless_map": _endless_map = key.get_slice(":", 1).to_int()
			"endless_kind": _endless_kind = key.get_slice(":", 1).to_int()
			"endless_start": _start_endless()
			"endless_back": _endless_open = false
		return
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
			_tree_focus = int(ClassTree.node(_node_id(arg))["cluster"])
			_click_sound()
		"node_buy":
			_sel_node = arg
			_unlock_selected()
		"tree_reset": _all_pressed()
		"class": _tree_class(arg)
		"cluster":
			_focus_cluster(arg)
		"crate_odds":
			_crate_odds = not _crate_odds
			if _crate_odds: _crate_journal = false
		"crate_journal":
			_crate_journal = not _crate_journal
			if _crate_journal: _crate_odds = false
		"ars_scroll": _ars_scroll = maxi(0, _ars_scroll + (1 if arg == 1 else -1))
		"ws_scroll":
			_ws_scroll = clampi(_ws_scroll + (1 if arg == 1 else -1), 0, maxi(0, _ws_models().size() - 7))
			_ws_sel = clampi(_ws_sel, _ws_scroll, _ws_scroll + 6)
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
		"range":
			get_tree().set_meta("gun_lab_range",true)
			get_tree().change_scene_to_file.call_deferred(MAIN_SCENE)


func _set_tab(t: int) -> void:
	if _open != Open.NONE or _confirm_node != "":
		return
	if not _test and not Meta.tab_open(t):
		_toast(Meta.tab_requirement(t))
		return
	Meta.visit_tab(t)
	if t == _tab:
		return
	_tab = t
	_reveal_selection = true
	_reward_t = 0.0
	if t == Tab.ARSENAL: _ars_seen = -1
	_sync_globe()
	_msg_t = 0.0
	_play("ui/click", -9.0)


func _step_tab(d: int) -> void:
	if _open != Open.NONE or _confirm_node != "":
		return
	for offset in range(1, 6):
		var next := posmod(_tab + offset * d, 5)
		if _test or Meta.tab_open(next):
			_set_tab(next)
			return


func _nav(dx: int, dy: int) -> void:
	_reveal_selection = true
	if _open != Open.NONE or _confirm_node != "":
		return
	match _tab:
		Tab.OPERATIONS:
			if _op_journal:
				_op_scroll = maxi(0, _op_scroll + dy)
			else:
				_nav_operations(dx if dx != 0 else dy)
		Tab.BARRACKS:
			_tree_nav(dx, dy)
		Tab.WORKSHOP:
			var n := _ws_models().size()
			_ws_sel = clampi(_ws_sel + dy, 0, maxi(n - 1, 0))
			_ws_stat = posmod(_ws_stat + dx, 4)
		Tab.ARSENAL:
			var gx := clampi(_grid_x(_ars_sel) + dx, 0, 1)
			var gy := clampi(_grid_y(_ars_sel) + dy, 0, _ars_rows().size() - 1)
			_ars_sel = _grid_model(gx, gy)
			_ars_scroll = clampi(_ars_scroll, maxi(0, gy - 7), gy)
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
			if _campaign_end_action(): return
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
	if _tab == Tab.OPERATIONS:
		_open_endless()
		return
	if _tab == Tab.BARRACKS and _confirm_node.is_empty() and Meta.tree_spent() > 0:
		_confirm_node = "__reset"
		return
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
	return ClassTree.ids()[clampi(sel, 0, ClassTree.ids().size() - 1)]


func _unlock_selected() -> void:
	var id := _node_id(_sel_node)
	if Meta.tree.has(id):
		_toast("Узел уже открыт")
	elif Meta.can_unlock(id):
		_confirm_node = id
		_click_sound()
	else:
		_toast(Meta.unlock_reason(id))


func _accept_unlock() -> void:
	if _confirm_node == "__reset":
		_toast("Возвращено очков: %d" % Meta.reset_tree())
		_play("ui/confirm")
	elif Meta.unlock(_confirm_node):
		_reward_text = str(ClassTree.node(_confirm_node)["name"]) + " · НАВЫК ОТКРЫТ"
		_reward_t = 1.1
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
		_reward_text = STAT_LABELS[stat] + " · УЛУЧШЕНО"
		_reward_t = 0.85
		_play("ui/confirm")


func _favorite_selected() -> void:
	var id: String = _ars_order[_ars_sel]
	if not Meta.is_owned(id):
		_toast("Модель закрыта: она выпадает из оружейных ящиков")
	elif Meta.model_for(WeaponDefs.MODELS[id]["base"]) == id:
		_toast("Уже избранная")
	elif Meta.set_favorite(WeaponDefs.MODELS[id]["base"], id):
		_ars_feedback = 0.35
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


## Показывает уже полученный из Meta результат: тряска → крышка → пауза → карточка.
func _present(res: Dictionary, military: bool) -> void:
	_open_res = res
	_open_mil = military
	_pending_dna = int(res["dna"])
	_open = Open.SHAKE
	_open_t = 0.0
	_open_log.append({"res": res, "mil": military})
	_play("ui/click", -4.0)
	if Meta.settings["reduce_motion"]: _skip()


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
			_shake = 0.35
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
		text = "Образцы: +%d ДНК" % res["dna"]
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


func _open_endless() -> void:
	if _open != Open.NONE or not _confirm_node.is_empty():
		return
	_endless_open = true
	_endless_kind = maxi(0, ClassTree.CLASSES.find(Meta.class_id))
	_click_sound()


func _capture_endless_base() -> void:
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/g8_base_entry.png")
	_open_endless()
	await get_tree().create_timer(0.2).timeout
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/tasks/reports/g8_records_table.png")
	var selected := _endless_kind
	await _test_key(KEY_DOWN)
	_check("endless keyboard class", _endless_kind == posmod(selected + 1, 3))
	var map := _endless_map
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_DPAD_RIGHT
	pad.pressed = true
	Input.parse_input_event(pad)
	await get_tree().process_frame
	pad.pressed = false
	Input.parse_input_event(pad)
	await get_tree().process_frame
	_check("endless pad map", _endless_map == posmod(map + 1, 3))
	await _test_key(KEY_ESCAPE)
	_check("endless cancel", not _endless_open)
	await _test_click(Vector2(300, 352))
	_check("endless mouse entry", _endless_open)
	get_tree().set_meta("endless_launch_test", 1)
	get_tree().set_meta("endless_expected", {"map_id": Meta.ENDLESS_MAPS[_endless_map], "class_id": ClassTree.CLASSES[_endless_kind]})
	_start_endless()


func _start_endless() -> void:
	if _leaving:
		return
	Meta.select_class(ClassTree.CLASSES[_endless_kind])
	get_tree().set_meta("endless_config", {"map_id": Meta.ENDLESS_MAPS[_endless_map]})
	_go_fight()


func _endless_input(event: InputEvent, command: String) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		_pad_mode = false
		match key.physical_keycode if key.physical_keycode != 0 else key.keycode:
			KEY_LEFT, KEY_A: _endless_map = posmod(_endless_map - 1, 3)
			KEY_RIGHT, KEY_D: _endless_map = posmod(_endless_map + 1, 3)
			KEY_UP, KEY_W: _endless_kind = posmod(_endless_kind - 1, 3)
			KEY_DOWN, KEY_S: _endless_kind = posmod(_endless_kind + 1, 3)
			KEY_E, KEY_F, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: _start_endless()
			KEY_ESCAPE, KEY_H: _endless_open = false
		get_viewport().set_input_as_handled()
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_pad_mode = true
		match command:
			"left": _endless_map = posmod(_endless_map - 1, 3)
			"right": _endless_map = posmod(_endless_map + 1, 3)
			"up": _endless_kind = posmod(_endless_kind - 1, 3)
			"down": _endless_kind = posmod(_endless_kind + 1, 3)
			"accept", "pause": _start_endless()
			"cancel": _endless_open = false
		get_viewport().set_input_as_handled()


func _draw_endless(font: Font) -> void:
	Style.cloth(self, Rect2(12, 36, 616, 308))
	_text(Style.TITLE_FONT, Vector2(28, 72), "БЕСКОНЕЧНАЯ БОЙНЯ", WHITE, 24)
	_text(font, Vector2(28, 94), "Рекорды классов на карте «%s». Шторм каждые пять минут." % Meta.ENDLESS_MAP_NAMES[_endless_map], MUTED, 10)
	_text(font, Vector2(28, 117), "КАРТА  [← →]", MUTED, 8)
	_text(font, Vector2(250, 117), "КЛАСС  [↑ ↓]", MUTED, 8)
	_text(font, Vector2(374, 117), "ВРЕМЯ", MUTED, 8)
	_text(font, Vector2(448, 117), "УБИЙСТВА", MUTED, 8)
	_text(font, Vector2(532, 117), "ТРОФЕИ · МИН", MUTED, 8)
	for i in 3:
		var y := 128.0 + i * 48.0
		_button(font, Rect2(28, y, 198, 40), Meta.ENDLESS_MAP_NAMES[i], WHITE, "endless_map:%d" % i, true, 13)
		if i == _endless_map:
			draw_rect(Rect2(28, y, 3, 40), Style.SELECTED)
		var row := Rect2(242, y, 370, 40)
		Style.surface(self, row, Style.State.SELECTED if i == _endless_kind else Style.State.NORMAL)
		_hit(row, "endless_kind:%d" % i)
		var best := Meta.endless_best(Meta.ENDLESS_MAPS[_endless_map], ClassTree.CLASSES[i])
		_text(font, Vector2(250, y + 24), ["Штурмовик", "Пулемётчик", "Инженер"][i], WHITE, 10)
		var seconds := int(best["time"])
		_text(font, Vector2(374, y + 27), "%d:%02d" % [seconds / 60, seconds % 60] if seconds > 0 else "—", Style.ACTION if seconds > 0 else DIM, 18)
		_text(font, Vector2(448, y + 27), str(best["kills"]) if int(best["kills"]) > 0 else "—", WHITE if int(best["kills"]) > 0 else DIM, 18)
		for t in 3:
			var x := 532.0 + t * 27.0
			var col := Style.ACTION if seconds >= Meta.ENDLESS_MILESTONES[t] else DIM
			_op_image("hud_star", Rect2(x, y + 8, 8, 8), col)
			_text(font, Vector2(x, y + 29), str(Meta.ENDLESS_MILESTONES[t] / 60), col, 8)
	_text(font, Vector2(28, 294), "4 ДНК/мин · ящик за 10 мин, до 3 за забег · трофеи за 15 / 20 / 30 мин", MUTED, 10)
	_button(font, Rect2(28, 310, 130, 22), "НАЗАД [B]" if _pad_mode else "НАЗАД [Esc]", MUTED, "endless_back", true, 9)
	_button(font, Rect2(374, 308, 238, 26), "В БОЙ [A]" if _pad_mode else "В БОЙ [Enter]", GOLD, "endless_start", true, 10)


func _process(delta: float) -> void:
	if _tab == Tab.ARSENAL and _ars_seen != _ars_sel:
		_ars_seen = _ars_sel
		_ars_time = 0.0
		var model: Dictionary = WeaponDefs.MODELS[_ars_order[_ars_sel]]
		var sound := "weapons/" + str(model["gun"]) + "/rack"
		if not _sfx.has(sound): sound = "weapons/" + str(model["gun"]) + "/mag_in"
		if _sfx.has(sound): _play(sound, -17.0)
	_reward_t = maxf(0.0, _reward_t - delta)
	_ars_time = minf(_ars_time + delta, 0.28)
	_ars_feedback = maxf(_ars_feedback - delta, 0.0)
	if _tab == Tab.BARRACKS and _pad_mode:
		var pan := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
		if pan.length() > 0.25: _tree_pan -= pan * delta * 100.0
	if _globe != null:
		_globe.input_enabled = not _settings_menu.visible and not _leaving and not _endless_open
		_globe.visible = _tab == Tab.OPERATIONS and not _endless_open
		_globe.position = (Vector2(12, 64) + _origin) * _ui
		_globe.size = Vector2(412, 230) * _ui
	_t += delta
	var dna_now := Meta.dna - _pending_dna
	if _dna_prev >= 0 and dna_now > _dna_prev:
		_dna_flash = 0.5
	_dna_prev = dna_now
	_dna_flash = maxf(_dna_flash - delta, 0.0)
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
	var rows := _ars_rows()
	for row: Dictionary in rows:
		if row["models"].has(idx): return row["models"].find(idx)
	return 0

func _grid_y(idx: int) -> int:
	var rows := _ars_rows()
	for i in rows.size():
		if rows[i]["models"].has(idx): return i
	return 0

func _grid_model(gx: int, gy: int) -> int:
	var row: Array = _ars_rows()[clampi(gy, 0, _ars_rows().size() - 1)]["models"]
	return row[clampi(gx, 0, row.size() - 1)]

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
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(fs * _ui)).x / _ui


func _text(font: Font, p: Vector2, s: String, c: Color, fs: int) -> void:
	var k := int(_ui)
	var at := (p + _origin) * _ui
	draw_set_transform(Vector2.ZERO)
	draw_string(font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(fs * _ui), c)
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


## Плашка: рамка рисуется только при border > 0 (у фокуса и модального окна), тени и полос нет.
func _box(r: Rect2, accent: Color, border := 0.0, fill := PANEL) -> void:
	draw_rect(r, fill)
	if border > 0.0:
		draw_rect(r, Color(accent, border), false, 1.0)


func _button(font: Font, r: Rect2, label: String, color: Color, key: String, enabled := true, fs := 9) -> void:
	var hot := enabled and _hot(key)
	var primary := color == GOLD and key.get_slice(":", 0) in ["op_start", "node_buy", "wsb", "fav", "copen", "call", "unlock_yes", "fight"]
	var selected := color == GOLD and key.begins_with("class:")
	var c := (Style.ACTION if primary else WHITE) if enabled else DIM
	Style.surface(self, r, Style.State.SELECTED if selected else (Style.State.HOVERED if hot else (Style.State.NORMAL if enabled else Style.State.DISABLED)))
	if primary and enabled:
		Style.cut_rect(self, r, Style.ACTION.lightened(0.1) if hot else Style.ACTION)
		c = Style.RECESS
	_text_c(font, Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.5 + fs * 0.36), label, c, fs)
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
		var off := sin(i * 0.55 + 0.8) * h * 0.22 # статичный знак образцов, без анимации
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
	if _steel == null:
		return
	_ui = SettingsLayout.scale_for(size)
	var view := _layout.view(size, Vector2(VIEW_W, VIEW_H), _ui)
	_origin = Vector2((view.x - VIEW_W) * 0.5, maxf(0.0, (view.y - VIEW_H) * 0.5)) + _layout.offset / _ui
	_hits.clear()
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect(_steel, Rect2(Vector2.ZERO, size), true)
	_ts()
	var font := Style.BODY_FONT
	_draw_top(font)
	_draw_tabs(font)
	match _tab:
		Tab.BARRACKS: _draw_barracks(font)
		Tab.WORKSHOP: _draw_workshop(font)
		Tab.ARSENAL: _draw_arsenal(font)
		Tab.CRATES: _draw_crates(font)
		Tab.OPERATIONS: _draw_operations(font)
	if _reward_t > 0.0 and _tab in [Tab.BARRACKS, Tab.WORKSHOP, Tab.OPERATIONS]:
		Style.reward(self, Rect2(160, 38, 308, 22), _reward_t)
		_text_c(font, Vector2(314, 53), _reward_text, GREEN, 10)
	if not _endless_open and _tab != Tab.BARRACKS and _tab != Tab.ARSENAL: _draw_hint(font)
	if _tab == Tab.BARRACKS and not _endless_open:
		_text(font, Vector2(12, 355), "V — кластер · C / Y — класс · колесо / курки — масштаб · E / A — открыть", MUTED, 8)
	if _tab != Tab.ARSENAL:
		_text(Style.TITLE_FONT, Vector2(12, 51), TAB_NAMES[_tab], Style.SELECTED, Style.SUBTITLE)
	if _tab == Tab.OPERATIONS and not _endless_open:
		_button(font, Rect2(228, 345, 184, 15), "БЕСКОНЕЧНАЯ БОЙНЯ [X]" if _pad_mode else "БЕСКОНЕЧНАЯ БОЙНЯ [H]", MUTED, "endless", true, 8)
	if _endless_open:
		_hits.clear()
		_draw_endless(font)
	# Контекстная подсказка оболочки не перекрывает рабочую область.
	if _hot("fight:0"):
		_text_r(font, Vector2(628, 354), "Свободная вылазка · без изменений на карте · Space / Start", MUTED, 8)
	elif _hot("settings"):
		_text_r(font, Vector2(628, 354), "Настройки · O / Back", MUTED, 8)
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
	if _confirm_node == "__reset":
		_box(Rect2(174, 108, 292, 136), GOLD, 0.8, PANEL_DARK)
		_text_c(font, Vector2(320, 132), "СБРОСИТЬ ПОДГОТОВКУ?", GOLD, 13)
		_text_c(font, Vector2(320, 159), "Вернётся %d очк. · бесплатно" % Meta.tree_spent(), WHITE, 11)
		_text_c(font, Vector2(320, 184), "Можно сразу выбрать другие доктрины", MUTED, 9)
		_button(font, Rect2(186, 215, 130, 20), "СБРОСИТЬ [E / A]", GOLD, "unlock_yes", true, 9)
		_button(font, Rect2(324, 215, 130, 20), "ОТМЕНА [Esc / B]", MUTED, "unlock_no", true, 9)
		return
	var node := ClassTree.node(_node_id(_sel_node))
	_box(Rect2(174, 108, 292, 136), GOLD, 0.8, PANEL_DARK)
	_text_c(font, Vector2(320, 130), "ОТКРЫТЬ НАВЫК?", GOLD, 13)
	_text_c(font, Vector2(320, 148), str(node["name"]), WHITE, 12)
	var y := 162.0
	for line in _wrap(font, str(node["text"]), 266.0, 9):
		_text_c(font, Vector2(320, y), line, MUTED, 9)
		y += 11.0
	_text_c(font, Vector2(320, 202), "%d очк. · останется %d" % [node["cost"], Meta.skill_points() - int(node["cost"])], GOLD, 9)
	_button(font, Rect2(186, 215, 130, 20), "ОТКРЫТЬ [E / A]", GOLD, "unlock_yes", true, 9)
	_button(font, Rect2(324, 215, 130, 20), "ОТМЕНА [Esc / B]", MUTED, "unlock_no", true, 9)


func _draw_top(font: Font) -> void:
	draw_rect(Rect2(-_origin.x, -_origin.y, size.x / _ui, Style.HEADER + _origin.y), Style.RECESS)
	draw_line(Vector2(-_origin.x, 31), Vector2(640 + _origin.x, 31), Color("414a3e"), 1.0)
	_text(Style.TITLE_FONT, Vector2(12, 22), "Z.E.R.A.", WHITE, 13)
	_text(font, Vector2(350, 19), "УР. %d" % Meta.class_level(), WHITE, 8)
	var lo := Meta.dna_for_level(Meta.class_level())
	var hi := Meta.dna_for_level(Meta.class_level() + 1)
	var frac := clampf(float(Meta.dna_earned - lo) / maxf(float(hi - lo), 1.0), 0.0, 1.0)
	draw_rect(Rect2(350, 24, 28, 1), DIM)
	draw_rect(Rect2(350, 24, 28 * frac, 1), Style.SELECTED)
	_dna_icon(Vector2(391, 16), 9.0, MUTED)
	_text(font, Vector2(400, 19), _num(Meta.dna - _pending_dna), WHITE.lerp(GREEN, _dna_flash * 2.0), 10)
	_hit(Rect2(383, 5, 57, 22), "tab:1")
	for kind in 2:
		var x := 448.0 + kind * 39.0
		var tex: String = CRATE_INFO[kind]["tex"]
		var body: Texture2D = _tex[tex + "_body"]
		var lid: Texture2D = _tex[tex + "_lid"]
		draw_texture_rect(body, Rect2(x, 12, 13, 8), false)
		draw_texture_rect(lid, Rect2(x, 10, 13, 3), false)
		_text(font, Vector2(x + 16, 19), str(Meta.crates if kind == 0 else Meta.military_crates), MUTED, 10)
		_hit(Rect2(x - 2, 5, 37, 22), "tab:3")
	_button(font, Rect2(526, 7, 25, 19), "ТИР", MUTED, "range:0", true, 8)
	_button(font, Rect2(558, 7, 49, 19), "В БОЙ", GOLD, "fight:0", true, 9)
	var gear := Vector2(623, 16)
	var gear_color := WHITE if _hot("settings") else MUTED
	for i in 4:
		var v := Vector2.from_angle(i * PI / 4.0) * 6
		draw_line(gear - v, gear + v, gear_color, 2.0)
	PixelArt.draw_dot(self, gear, 6, gear_color)
	PixelArt.draw_dot(self, gear, 2.5, Style.RECESS)
	_hit(Rect2(613, 5, 20, 23), "settings")

func _draw_crate_chip(font: Font, kind: int, p: Vector2, count: int) -> void:
	var tex: String = CRATE_INFO[kind]["tex"]
	var body: Texture2D = _tex[tex + "_body"]
	var s := body.get_size() / 3.0
	var tint := Color.WHITE if count > 0 else Color(0.45, 0.45, 0.45, 0.8)
	draw_texture_rect(body, Rect2(((p + Vector2(0, 5)) * _ui).round() / _ui, s * 0.5), false, tint)
	var lid: Texture2D = _tex[tex + "_lid"]
	draw_texture_rect(lid, Rect2(((p + Vector2(0, 2)) * _ui).round() / _ui, lid.get_size() / 3.0 * 0.5), false, tint)
	_text(font, p + Vector2(36, 21), "×%d" % count, GOLD if count > 0 else DIM, 16)


func _draw_tabs(font: Font) -> void:
	var x := 72.0
	var widths := [51, 64, 51, 42, 58]
	for i in 5:
		var r := Rect2(x, 4, widths[i] - 2, 25)
		var available := _test or Meta.tab_open(i)
		var active := _tab == i
		var hot := _hot("tab:%d" % i)
		if active or hot:
			Style.surface(self, r, Style.State.SELECTED if active else Style.State.HOVERED)
		_text_c(font, r.position + Vector2(r.size.x * 0.5, 15), TAB_NAMES[i], (WHITE if active or hot else MUTED) if available else DIM, Style.NAV)
		_hit(r, "tab:%d" % i)
		if not available:
			Style.lock_icon(self, r.position + Vector2(r.size.x - 5, 21), DIM)
		elif Meta.tab_new(i):
			_text_r(font, r.position + Vector2(r.size.x - 3, 24), "НОВОЕ", GREEN, 8)
		var badge := Meta.skill_points() if i == Tab.BARRACKS else 0
		if badge > 0:
			_text_r(font, r.position + Vector2(r.size.x - 3, 24), "+%d" % badge, GREEN, 8)
		x += widths[i]

func _draw_hint(font: Font) -> void:
	if _hover_key.begins_with("tab:"):
		var hovered := _hover_key.trim_prefix("tab:").to_int()
		if not _test and not Meta.tab_open(hovered):
			_text(font, Vector2(12, 355), Meta.tab_requirement(hovered), MUTED, 8)
			return
	if _msg_t > 0.0:
		_text_c(font, Vector2(320, 355), _msg, Color(RED, minf(_msg_t * 2.0, 1.0)), 8)
		return
	if _tab == Tab.OPERATIONS:
		var help := "Стик · курки · A начать" if _op_pad else "ЛКМ · колесо · Enter начать"
		_text(font, Vector2(12, 355), help, MUTED, 8)
		return
	# подсказка для последнего использованного устройства; номера вкладок и так подписаны на кнопках вкладок
	var tail := ""
	match _tab:
		Tab.BARRACKS: tail = "A — открыть" if _pad_mode else "стрелки · E — открыть"
		Tab.WORKSHOP: tail = "крестовина · A — улучшить" if _pad_mode else "↑↓ модель · ←→ параметр · E — улучшить"
		Tab.ARSENAL: tail = "A — избранная" if _pad_mode else "E — избранная"
		Tab.CRATES: tail = "крестовина · A — вскрыть · X — все" if _pad_mode else "←→ · E — вскрыть · R — все"
		Tab.OPERATIONS: tail = "ЛКМ / стик — вращать · колесо / курки — масштаб · D-pad — регион · A / Enter — выбрать / начать"
	if _tab == Tab.OPERATIONS:
		tail = "1–5 / Tab — разделы · " + tail
	elif _pad_mode:
		tail = "LB / RB · " + tail
	_text_c(font, Vector2(320, 355), tail, MUTED, 8)


var _tree_zoom := 1.0
var _tree_pan := Vector2.ZERO


func _tree_pos(index: int) -> Vector2:
	var n := ClassTree.node(_node_id(index))
	var cluster := int(n["cluster"])
	var center: Vector2 = [Vector2(124, 190), Vector2(320, 185), Vector2(516, 190)][cluster]
	var offset: Vector2 = n["pos"] - center
	if cluster != _tree_focus:
		return Vector2(64, 140 + cluster * 76) + offset * 0.25
	return Vector2(295, 214) + offset * 1.65 * _tree_zoom + _tree_pan


func _focus_cluster(index: int) -> void:
	_tree_focus = posmod(index, 3)
	_tree_pan = Vector2.ZERO
	_tree_zoom = 1.0
	for i in ClassTree.ids().size():
		if int(ClassTree.node(_node_id(i))["cluster"]) == _tree_focus:
			_sel_node = i
			break

func _tree_class(index: int) -> void:
	Meta.select_class(ClassTree.CLASSES[posmod(index, 3)])
	_sel_node = 0
	_tree_focus = 0
	_tree_zoom = 1.0
	_tree_pan = Vector2.ZERO
	_hover_key = ""

func _tree_nav(dx: int, dy: int) -> void:
	var current := _tree_pos(_sel_node)
	var best := _sel_node
	var score := INF
	for i in ClassTree.ids().size():
		if int(ClassTree.node(_node_id(i))["cluster"]) != _tree_focus: continue
		var offset := _tree_pos(i) - current
		if (dx != 0 and offset.x * dx <= 0.0) or (dy != 0 and offset.y * dy <= 0.0): continue
		var candidate := absf(offset.x) + absf(offset.y) * 4.0 if dx != 0 else absf(offset.y) + absf(offset.x) * 4.0
		if candidate < score:
			score = candidate
			best = i
	if best == _sel_node and dx != 0:
		_focus_cluster(_tree_focus + dx)
		return
	_sel_node = best
	_hover_key = ""
	var focus := _tree_pos(best)
	if not Rect2(155, 108, 280, 214).has_point(focus):
		_tree_pan += Vector2(295, 214) - focus

func _skill_icon(node: Dictionary) -> String:
	# Силуэт отражает эффект, одинаковые ступени сохраняют один знак.
	var id: String = node["id"]
	var icons := {"gren_ready": "grenade_cooldown", "gren_radius": "fragments", "gren_charge": "charge", "gren_wide": "area", "gren_throw": "throw", "gren_knock": "wave", "gren_push": "repel", "mag_grenade": "grenade_reload", "dash_smoke": "grenade_speed", "dash_fuse": "fuse"}
	if icons.has(id): return icons[id]
	if node["effects"].has("grenade_cd_mul"): return "grenade_cooldown"
	return node["icon"]


func _draw_barracks(font: Font) -> void:
	var class_index := ClassTree.CLASSES.find(Meta.class_id)
	for c in 3:
		_button(font, Rect2(12 + c * 137, 64, 131, 22), ClassTree.NAMES[c], GOLD if c == class_index else MUTED, "class:%d" % c, true, 10)
	_text_r(font, Vector2(628, 78), "%d ОЧК. ПОДГОТОВКИ" % Meta.skill_points(), WHITE, 11)
	_text(font, Vector2(12, 99), ClassTree.RULES[class_index], MUTED, 8)
	var ids := ClassTree.ids()
	var catalog := ClassTree.catalog()
	var n := ClassTree.node(_node_id(_sel_node))
	var colors := [Style.ACTION, Style.BETTER, Style.RARE]
	for c in 3:
		var rect := Rect2(12, 109 + c * 76, 108, 70)
		if c == _tree_focus or _hot("cluster:%d" % c): Style.surface(self, rect, Style.State.SELECTED if c == _tree_focus else Style.State.HOVERED)
		_text(font, rect.position + Vector2(6, 12), ClassTree.CLUSTERS[class_index][c], colors[c], 8)
		var taken := 0
		for id: String in ids:
			if int(catalog[id]["cluster"]) != c: continue
			var center: Vector2 = [Vector2(124, 190), Vector2(320, 185), Vector2(516, 190)][c]
			var at: Vector2 = Vector2(64, 140 + c * 76) + (catalog[id]["pos"] - center) * 0.25
			for parent: String in catalog[id]["parents"]:
				if int(catalog[parent]["cluster"]) != c: continue
				var to: Vector2 = Vector2(64, 140 + c * 76) + (catalog[parent]["pos"] - center) * 0.25
				draw_line(at, to, Style.DISABLED, 0.5)
			PixelArt.draw_dot(self, at, 1.5, colors[c] if Meta.tree.has(id) else Style.MUTED)
			if Meta.tree.has(id): taken += 1
		_text_r(font, rect.end - Vector2(6, 4), "%d / 24" % taken, MUTED, 8)
		_hit(rect, "cluster:%d" % c)
	var field := Rect2(128, 95, 330, 249)
	for idx in ids.size():
		var node: Dictionary = catalog[ids[idx]]
		if int(node["cluster"]) != _tree_focus: continue
		var at := _tree_pos(idx)
		if not field.grow(-12).has_point(at): continue
		for parent: String in node["parents"]:
			var j := ids.find(parent)
			if j < idx or int(catalog[parent]["cluster"]) != _tree_focus: continue
			var to := _tree_pos(j)
			if field.grow(-12).has_point(to):
				draw_line(at, to, colors[_tree_focus] if Meta.tree.has(ids[idx]) and Meta.tree.has(parent) else Style.DISABLED, 1)
	for idx in ids.size():
		var node: Dictionary = catalog[ids[idx]]
		if int(node["cluster"]) != _tree_focus: continue
		var at := _tree_pos(idx)
		if not field.grow(-12).has_point(at): continue
		var taken := Meta.tree.has(ids[idx])
		var available := Meta.can_unlock(ids[idx])
		var selected := idx == _sel_node
		var radius := 12.0 if node["key"] else 10.0
		PixelArt.draw_dot(self, at, radius, Style.HOVER if taken else Style.RECESS)
		var color: Color = colors[_tree_focus] if taken else (Style.SELECTED if available else Style.DISABLED)
		draw_arc(at, radius, 0, TAU, 20, color, 1)
		if selected:
			draw_arc(at, radius + 3, 0, TAU, 24, WHITE, 1)
			if _reward_t > 0: draw_arc(at, radius + 6, 0, TAU, 24, Color(GREEN, minf(1, _reward_t)), 2)
		draw_texture_rect_region(_tree_icons, Rect2(at - Vector2.ONE * 9, Vector2.ONE * 18), Rect2(TREE_ICONS.find(_skill_icon(node)) * 24, 0, 24, 24), Color.WHITE if taken else Style.MUTED)
		if taken: _check_mark(at + Vector2(9, -9), GREEN)
		elif Meta.tree.has(node["exclude"]):
			draw_line(at - Vector2(6, 6), at + Vector2(6, 6), RED, 1)
		_hit(Rect2(at - Vector2.ONE * 13, Vector2.ONE * 26), "node:%d" % idx)
	draw_line(Vector2(466, 112), Vector2(466, 328), Style.DISABLED, 1)
	_text(font, Vector2(480, 120), ClassTree.CLUSTERS[class_index][_tree_focus], colors[_tree_focus], 8)
	var y := 143.0
	for line: String in _wrap(Style.TITLE_FONT, str(n["name"]), 145, 13):
		_text(Style.TITLE_FONT, Vector2(480, y), line, WHITE, 13)
		y += 16
	y += 9
	for line: String in _wrap(font, str(n["text"]), 144, 10):
		_text(font, Vector2(480, y), line, WHITE, 10)
		y += 13
	var reason := Meta.unlock_reason(n["id"])
	var cost_y := maxf(180, y + 14)
	_text(font, Vector2(480, cost_y), "%d очк." % n["cost"], Style.ACTION, 14)
	var status := "ОТКРЫТ" if Meta.tree.has(n["id"]) else "ОТКРЫТЬ  [A]" if _pad_mode else "ОТКРЫТЬ  [E]"
	_button(font, Rect2(480, cost_y + 12, 148, 24), status, GOLD, "node_buy:%d" % _sel_node, reason.is_empty(), 10)
	if not reason.is_empty() and not Meta.tree.has(n["id"]):
		var yy := cost_y + 50
		for line: String in _wrap(font, reason, 144, 8):
			_text(font, Vector2(480, yy), line, MUTED, 8)
			yy += 10
	_button(font, Rect2(480, 324, 148, 16), "СБРОС  [R / X]", MUTED, "tree_reset", Meta.tree_spent() > 0, 8)

func _draw_workshop(font: Font) -> void:
	var models := _ws_models()
	_ws_sel = clampi(_ws_sel, 0, maxi(0, models.size() - 1))
	if models.is_empty(): return
	_text_r(font, Vector2(120, 61), "%02d / %d" % [_ws_sel + 1, models.size()], MUTED, 8)
	_ws_scroll = clampi(_ws_scroll, maxi(0, _ws_sel - 6), _ws_sel)
	for slot in mini(7, models.size()):
		var i := slot + _ws_scroll
		if i >= models.size(): break
		var rect := Rect2(12, 66 + slot * 37, 108, 33)
		if i == _ws_sel or _hot("wsm:%d" % i): Style.surface(self, rect, Style.State.SELECTED if i == _ws_sel else Style.State.HOVERED)
		_gun(models[i], rect.position + Vector2(23, 12), 1)
		_text(font, rect.position + Vector2(46, 15), WeaponDefs.MODELS[models[i]]["short"], WHITE, 9)
		_text_r(font, rect.position + Vector2(102, 28), "%d / 20" % _total_steps(models[i]), MUTED, 8)
		_hit(rect, "wsm:%d" % i)
	_button(font, Rect2(12, 328, 50, 16), "↑", MUTED, "ws_scroll:0", _ws_scroll > 0, 10)
	_button(font, Rect2(68, 328, 52, 16), "↓", MUTED, "ws_scroll:1", _ws_scroll + 7 < models.size(), 10)
	if models.size() > 7:
		draw_rect(Rect2(124, 66, 2, 255), Style.RECESS)
		draw_rect(Rect2(124, 66 + 255.0 * _ws_scroll / models.size(), 2, 255.0 * 7 / models.size()), Style.SELECTED)
	var model := models[_ws_sel]
	var data: Dictionary = WeaponDefs.MODELS[model]
	var lv := _levels_of(model)
	var cur := _stats_with(model, lv)
	var stat: String = Meta.WORKSHOP_STATS[_ws_stat]
	var cost := Meta.upgrade_cost(model, stat)
	var next_levels := lv.duplicate()
	if cost >= 0: next_levels[stat] = int(lv[stat]) + 1
	var next := _stats_with(model, next_levels)
	draw_texture_rect(_canvas, Rect2(136, 64, 492, 130), true)
	_text(Style.TITLE_FONT, Vector2(148, 87), str(data["short"]).to_upper(), WHITE, 20)
	_text_r(font, Vector2(616, 82), CATEGORY_NAMES[int(data["base"])], MUTED, 8)
	var shift := 0.0 if Meta.settings["reduce_motion"] else roundf(sin(_reward_t * 20) * _reward_t * 3)
	_gun(model, Vector2(382 + shift, 141), 6)
	_text(font, Vector2(148, 184), "Эфф. DPS ур.1   %.1f → %.1f" % [_dps(model, cur), _dps(model, next)], GREEN if _reward_t > 0 else MUTED, 10)
	var labels := ["УРОН", "ТЕМП /С", "МАГАЗИН", "ПЕРЕЗАРЯДКА"]
	for i in 4:
		var rect := Rect2(136 + i * 125, 203, 117, 38)
		if i == _ws_stat or _hot("wss:%d" % i): Style.surface(self, rect, Style.State.SELECTED if i == _ws_stat else Style.State.HOVERED)
		var key: String = Meta.WORKSHOP_STATS[i]
		_text(font, rect.position + Vector2(7, 13), labels[i], WHITE if i == _ws_stat else MUTED, 8)
		_text(font, rect.position + Vector2(7, 29), _fmt(key, cur[key]), WHITE, 11)
		_text_r(font, rect.position + Vector2(110, 29), "%d / %d" % [lv[key], Meta.WORKSHOP_MAX], MUTED, 8)
		_hit(rect, "wss:%d" % i)
	_text(Style.TITLE_FONT, Vector2(148, 267), labels[_ws_stat], WHITE, 13)
	_text(font, Vector2(148, 301), _fmt(stat, cur[stat]), WHITE, 24)
	_text(font, Vector2(240, 298), "→", MUTED, 20)
	_text(font, Vector2(272, 301), _fmt(stat, next[stat]), GREEN, 24)
	for p in Meta.WORKSHOP_MAX:
		draw_rect(Rect2(148 + p * 37, 315, 32, 4), GREEN if p < int(lv[stat]) else Style.HOVER)
	_text_r(font, Vector2(616, 267), "%d ДНК" % cost if cost >= 0 else "МАКСИМУМ", Style.ACTION, 16)
	_button(font, Rect2(400, 283, 216, 32), "УЛУЧШИТЬ  [A]" if _pad_mode else "УЛУЧШИТЬ  [E]", GOLD, "wsb:%d" % _ws_stat, cost >= 0 and Meta.dna >= cost, 11)
	if cost >= 0 and Meta.dna < cost:
		_text_r(font, Vector2(616, 333), "Нужно ещё %d ДНК · за вылазки и образцы" % (cost - Meta.dna), MUTED, 8)

func _draw_arsenal(font: Font) -> void:
	_text(Style.TITLE_FONT, Vector2(12, 59), "АРСЕНАЛ", WHITE, 17)
	_text_r(font, Vector2(253, 72), "%02d / %d" % [_ws_models().size(), _ars_order.size()], MUTED, 11)
	_text(font, Vector2(12, 72), "КОЛЛЕКЦИЯ ВООРУЖЕНИЯ", MUTED, Style.SMALL)
	var rows := _ars_rows()
	_ars_scroll = clampi(_ars_scroll, 0, maxi(0, rows.size() - 8))
	for row_index in mini(8, rows.size() - _ars_scroll):
		var row: Dictionary = rows[row_index + _ars_scroll]
		var category: int = row["category"]
		var y := 85.0 + row_index * 33
		_text(font, Vector2(12, y), "%02d" % (category + 1), MUTED, 8)
		_text(font, Vector2(27, y), CATEGORY_NAMES[category] + (" · продолжение" if not row["first"] else ""), MUTED, 8)
		for slot in row["models"].size():
			var idx: int = row["models"][slot]
			var model: String = _ars_order[idx]
			var owned := Meta.is_owned(model)
			var rect := Rect2(12 + slot * 124, y + 3, 120, 22)
			if idx == _ars_sel or _hot("ars:%d" % idx): Style.surface(self, rect, Style.State.SELECTED if idx == _ars_sel else Style.State.HOVERED)
			_gun(model, rect.position + Vector2(22, 11), 1, Color.WHITE if owned else Color("c3c9be"))
			_text(font, rect.position + Vector2(43, 14), str(WeaponDefs.MODELS[model]["short"]), WHITE if owned else MUTED, 9)
			if not owned: Style.lock_icon(self, rect.position + Vector2(113, 9), DIM)
			elif Meta.model_for(category) == model: _check_mark(rect.position + Vector2(112, 7), Style.SELECTED)
			_hit(rect, "ars:%d" % idx)
	if rows.size() > 8:
		draw_rect(Rect2(258, 88, 2, 252), Style.RECESS)
		draw_rect(Rect2(258, 88 + 252.0 * _ars_scroll / rows.size(), 2, 252.0 * 8 / rows.size()), Style.SELECTED)
		_button(font, Rect2(198, 39, 25, 20), "↑", MUTED, "ars_scroll:0", _ars_scroll > 0, 10)
		_button(font, Rect2(228, 39, 25, 20), "↓", MUTED, "ars_scroll:1", _ars_scroll + 8 < rows.size(), 10)
	var id: String = _ars_order[_ars_sel]
	var model: Dictionary = WeaponDefs.MODELS[id]
	var owned := Meta.is_owned(id)
	var category := int(model["base"])
	var current := Meta.model_for(category)
	var is_current := current == id
	var rarity := int(model["rarity"])
	draw_texture_rect(_canvas, Rect2(272, 40, 356, 188), true)
	_text(font, Vector2(284, 54), "%02d · %s" % [category + 1, CATEGORY_NAMES[category]], MUTED, Style.SMALL)
	_text_r(font, Vector2(616, 54), WeaponDefs.RARITY_NAMES[rarity].to_upper(), RARE if rarity == 2 else MUTED, Style.SMALL)
	_text(Style.TITLE_FONT, Vector2(284, 86), str(model["short"]).to_upper(), WHITE, Style.TITLE)
	var status := "ДОПУЩЕНО К ВЫДАЧЕ" if owned else "НЕТ НА СКЛАДЕ"
	if not owned: Style.lock_icon(self, Vector2(288, 99), MUTED)
	_text(font, Vector2(284 if owned else 298, 104), status, Style.SELECTED if owned else MUTED, Style.SMALL)
	var shift := 0.0 if Meta.settings["reduce_motion"] else roundf(8.0 * pow(1.0 - _ars_time / 0.28, 3))
	var center := Vector2(452 + shift, 152)
	_gun(id, center + Vector2(0, 4), 6, Color(0.0, 0.0, 0.0, 0.32))
	_gun(id, center, 6, Color.WHITE if owned else Color("d4dbcf"))
	var roles := ["Держит толпу на дистанции", "Сметает плотную группу в упор", "Пробивает всю линию", "Накрывает группу взрывом", "Точный огонь с высоким шансом крита", "Пробивает цель с сильным отбросом", "Долгая очередь с растущим разбросом", "Пробивает троих на большой дистанции"]
	var role: String = roles[category] if category < roles.size() else str(model["desc"])
	var model_trait: Dictionary = WeaponDefs.TRAITS.get(model["trait"], {})
	if not model_trait.is_empty(): role = str(model_trait["text"])
	if id == "m4": role = "Очередь из трёх пуль; разброс не растёт"
	elif id == "shkval": role = "Плотный поток дроби с короткой дистанции"
	elif id == "spear": role = "Убийство: +50% урона следующему выстрелу"
	elif id == "hive": role = "Гранаты прилипают; взрыв через %.1f с" % WeaponDefs.STICKY_FUSE
	elif id == "guard": role = "Дольше стреляет, слабее бьёт"
	elif id == "cowboy": role = "Весь барабан веером по разным целям"
	elif id == "osa": role = "Держит очередь без роста разброса"
	elif id == "winchester": role = "Убийство мгновенно взводит рычаг"
	var role_y := 209.0
	for line: String in _wrap(font, role, 332, 9):
		_text(font, Vector2(284, role_y), line, WHITE, 9)
		role_y += 11
	var stats := _stats_with(id, _levels_of(id))
	var other := _stats_with(current, _levels_of(current))
	_text(font, Vector2(284, 239), "УР. 1 · ПОДГОТОВКА + МАСТЕРСКАЯ", MUTED, 8)
	_text_r(font, Vector2(616, 249), "ТЕКУЩАЯ: " + str(WeaponDefs.MODELS[current]["short"]), MUTED, 8)
	var labels := ["УРОН", "ТЕМП /С", "МАГАЗИН", "ПЕРЕЗАРЯДКА"]
	for i in 4:
		var key: String = Meta.WORKSHOP_STATS[i]
		var x := 284.0 + i * 85.0
		var value := float(stats[key])
		var delta := value - float(other[key])
		_text(font, Vector2(x, 260), labels[i], MUTED, Style.SMALL)
		var shown := str(int(value)) if key == "mag" else ("%.1f" % value)
		if key == "reload": shown += " с"
		_text(font, Vector2(x, 282), shown, WHITE, Style.NUMBER)
		var difference := "—" if is_zero_approx(delta) else ("%+d" % roundi(delta) if key == "mag" else "%+.1f" % delta)
		if key == "reload" and not is_zero_approx(delta): difference += " с"
		var better := delta < 0.0 if key == "reload" else delta > 0.0
		_text(font, Vector2(x, 295), difference, MUTED if is_zero_approx(delta) else (GREEN if better else RED), Style.SMALL)
	var feature := "Эфф. DPS: %.1f · с учётом перезарядки" % _dps(id, stats)
	if category in [WeaponDefs.Base.SHOTGUN, WeaponDefs.Base.AUTO_SHOTGUN]:
		feature = "%d дробин за выстрел · урон указан на дробину" % int(stats["proj"])
	if not owned:
		_text(font, Vector2(284, 307), "Получение: обычный или военный оружейный ящик", WHITE, Style.SMALL)
		_text(font, Vector2(284, 317), "Военный ящик чаще содержит редкую модель" if rarity == 2 else "Ящики — за вылазки, контейнеры и операции", MUTED, Style.SMALL)
		_button(font, Rect2(284, 322, 332, 23), "НА СКЛАД  →", GOLD, "tab:3", true, 10)
	else:
		_text(font, Vector2(284, 310), feature, MUTED, Style.SMALL)
		if is_current:
			Style.cut_rect(self, Rect2(284, 322, 332, 23), Style.HOVER.lerp(Style.CANVAS, 1.0 - _ars_feedback / 0.35))
			_check_mark(Vector2(298, 333), GREEN)
			_text_c(font, Vector2(451, 337), "В КОМПЛЕКТЕ", Style.SELECTED, 10)
		else:
			_button(font, Rect2(284, 322, 332, 23), "ВЫБРАТЬ ДЛЯ БОЯ  [A]" if _pad_mode else "ВЫБРАТЬ ДЛЯ БОЯ  [E]", GOLD, "fav:%d" % _ars_sel, true, 10)
	var hint := "D-pad — модель · A — в комплект" if _pad_mode else "↑↓ категория · ←→ модель · E — в комплект"
	if _msg_t > 0.0: hint = _msg
	_text(font, Vector2(12, 355), hint, RED if _msg_t > 0.0 else MUTED, 8)
	var starter := Meta.model_for(ClassTree.STARTERS[ClassTree.CLASSES.find(Meta.class_id)])
	_text_r(font, Vector2(616, 355), "Старт: %s · остальные — с уровнем" % WeaponDefs.MODELS[starter]["short"], MUTED, 8)


func _draw_crates(font: Font) -> void:
	for i in 2:
		var count := Meta.military_crates if i == 1 else Meta.crates
		var rect := Rect2(12 + i * 157, 64, 149, 24)
		Style.surface(self, rect, Style.State.SELECTED if i == _crate_sel else (Style.State.HOVERED if _hot("csel:%d" % i) else Style.State.NORMAL))
		_text(font, rect.position + Vector2(9, 16), "%s   ×%d" % ["ВОЕННЫЙ" if i == 1 else "ОБЫЧНЫЙ", count], WHITE, 10)
		_hit(rect, "csel:%d" % i)
	var info: Dictionary = CRATE_INFO[_crate_sel]
	var count := Meta.military_crates if _crate_sel == 1 else Meta.crates
	draw_texture_rect(_canvas, Rect2(12, 98, 306, 193), true)
	_text(font, Vector2(24, 115), "ОРУЖЕЙНОЕ СНАБЖЕНИЕ", MUTED, 8)
	_crate(info["tex"], Vector2(165, 213), 6)
	_text_r(font, Vector2(305, 280), "×%d" % count, WHITE, 22)
	_button(font, Rect2(12, 302, 196, 30), "ВСКРЫТЬ  [A]" if _pad_mode else "ВСКРЫТЬ  [E]", GOLD, "copen:%d" % _crate_sel, count > 0, 11)
	_button(font, Rect2(216, 302, 102, 30), "ВСЕ  [X]" if _pad_mode else "ВСЕ  [R]", MUTED, "call:0", Meta.crates + Meta.military_crates > 0, 10)
	_text(Style.TITLE_FONT, Vector2(338, 80), "ВНУТРИ — ОРУЖИЕ", WHITE, 16)
	_text(font, Vector2(338, 97), "Редкие модели с особыми чертами", RARE, 10)
	var candidates: Array[String] = []
	for id: String in WeaponDefs.MODEL_ORDER:
		if int(WeaponDefs.MODELS[id]["rarity"]) > 0: candidates.append(id)
	for i in mini(3, candidates.size()):
		var id := candidates[posmod(i * 2 + _crate_sel, candidates.size())]
		var y := 129.0 + i * 36
		_gun(id, Vector2(365, y), 2)
		_text(font, Vector2(408, y - 1), WeaponDefs.MODELS[id]["short"], WHITE, 11)
		var trait_id: String = WeaponDefs.MODELS[id]["trait"]
		_text(font, Vector2(408, y + 11), str(WeaponDefs.TRAITS[trait_id]["name"]) if not trait_id.is_empty() else "Серийная модель", MUTED, 8)
	_dna_icon(Vector2(347, 227), 17, Style.SELECTED)
	_text(font, Vector2(365, 229), "или 30–80 ДНК для модернизации", WHITE, 10)
	_text(font, Vector2(338, 249), "Дубликат → ДНК. Находки — в арсенале.", MUTED, 8)
	_button(font, Rect2(338, 264, 138, 18), ("−" if _crate_odds else "+") + " ШАНСЫ [Q/Y]", MUTED, "crate_odds", true, 8)
	_button(font, Rect2(484, 264, 144, 18), ("−" if _crate_journal else "+") + " ЖУРНАЛ [J/Back] (%d)" % _history.size(), MUTED, "crate_journal", true, 8)
	if _crate_odds:
		for i in 2: _text(font, Vector2(338, 297 + i * 14), info["odds"][i], WHITE, 9)
		_text(font, Vector2(338, 327), "Редкость указана среди выпавших моделей", MUTED, 8)
	elif _crate_journal:
		if _history.is_empty(): _text(font, Vector2(338, 301), "Поставки появятся после вскрытия", MUTED, 9)
		for i in mini(3, _history.size()):
			_text(font, Vector2(338, 297 + i * 15), str(_history[i]["text"]), _history[i]["color"], 8)
	else:
		_text(font, Vector2(338, 300), "ГДЕ ПОЛУЧИТЬ", Style.SELECTED, 8)
		_text(font, Vector2(338, 315), "Ящики — за вылазки, контейнеры и операции.", WHITE, 9)
		_text(font, Vector2(338, 330), "Военные — за ульи и боевые награды.", MUTED, 9)

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
		_text_c(font, Vector2(320, 68), "%d / %d · Enter — дальше" % [_open_log.size(), _open_log.size() + left], MUTED, 8)
	if _open in [Open.SHAKE, Open.LID, Open.FLASH]:
		_draw_crate_stage(tex, center)
		if _open == Open.FLASH:
			draw_rect(Rect2(160, 94, 320, 168), Color(Style.SELECTED, 0.12 * (1.0 - _open_t / FLASH_T)))
	elif _open == Open.CARD:
		_draw_card(font, center, accent)
	elif _open == Open.SUMMARY:
		_draw_summary(font)


func _draw_crate_stage(tex: String, center: Vector2) -> void:
	var crate_center := center + Vector2(0, 22)
	var shake_off := Vector2.ZERO
	var rot := 0.0
	var lid_off := Vector2.ZERO
	var lid_rot := 0.0
	if _open == Open.SHAKE:
		# короткая тряска: ящик вскрывают, а не заряжают
		var u := _open_t / _stage_dur(Open.SHAKE)
		var amp := 0.4 + u * u * 1.6
		shake_off = Vector2(sin(_open_t * 73.0) * amp, cos(_open_t * 59.0) * amp * 0.35)
		rot = sin(_open_t * 47.0) * 0.008 * (1.0 + u * 2.0)
	else:
		# крышка сдвигается вбок и чуть проворачивается, дальше ящик стоит открытым
		var since := _open_t if _open == Open.LID else _stage_dur(Open.LID) + _open_t
		since = clampf(since / _open_fast / LID_T, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - since, 3.0)
		lid_off = Vector2(46.0 * e, -3.0 * e)
		lid_rot = 0.12 * e
	# тень под ящиком
	PixelArt.draw_dot(self, crate_center + Vector2(0, 34), 70.0, Color(0, 0, 0, 0.4))
	# корпус и крышка со смещением и наклоном
	if absf(rot) > 0.0:
		draw_set_transform((crate_center + shake_off + _origin) * _ui, rot, Vector2(_ui, _ui))
		_crate_local(tex, lid_off, lid_rot, 1.0)
		_ts()
	else:
		_crate(tex, crate_center + shake_off, 6, lid_off, lid_rot, 1.0)


## Ящик в локальных координатах (после draw_set_transform с поворотом): центр корпуса — (0, 0).
func _crate_local(tex: String, lid_off: Vector2, lid_rot: float, lid_alpha: float) -> void:
	var body: Texture2D = _tex[tex + "_body"]
	var lid: Texture2D = _tex[tex + "_lid"]
	var bs := body.get_size() * 6.0 / 3.0
	var ls := lid.get_size() * 6.0 / 3.0
	draw_texture_rect(body, Rect2(-bs * 0.5, bs), false)
	var lid_center := Vector2(0, -bs.y * 0.5 - ls.y * 0.5 + 2.0) + lid_off
	draw_texture_rect(lid, Rect2(lid_center - ls * 0.5, ls), false, Color(1, 1, 1, lid_alpha))


func _draw_card(font: Font, _center: Vector2, accent: Color) -> void:
	var res := _open_res
	var pop := 1.0 if Meta.settings["reduce_motion"] else clampf(_open_t / 0.2, 0.0, 1.0)
	var cx := 320.0
	var cy := 176.0
	# карточка просто появляется на тёмной подложке: без лучей, искр и вспышки
	var w := 356.0
	var h := 192.0
	var r := Rect2(cx - w * 0.5, cy - h * 0.5 + (1.0 - pop) * 6.0, w, h)
	draw_texture_rect(_canvas, r, true, Color(1, 1, 1, pop))
	Style.reward(self, Rect2(r.position, Vector2(r.size.x, 4)), 1.0)
	if pop < 0.6:
		return
	var fa := clampf((pop - 0.6) / 0.4, 0.0, 1.0)
	var top := r.position.y
	if res["kind"] == "model":
		var model: String = res["model"]
		var m: Dictionary = WeaponDefs.MODELS[model]
		var head := "НОВОЕ ОРУЖИЕ · " + str(m["short"])
		var head_c := WHITE
		if res["duplicate"]:
			head = "ДУБЛИКАТ · " + str(m["short"])
			head_c = MUTED
		_text_c(font, Vector2(cx, top + 18), head, Color(head_c, fa), 11)

		_gun(model, Vector2(cx, top + 59), 6, Color(1, 1, 1, fa) if not res["duplicate"] else Color(0.55, 0.55, 0.55, fa))
		# редкость — цвет небольшой бирки и подпись
		var tag := ("Редкая модель" if res["rare"] else "Обычная модель") if m["rarity"] != WeaponDefs.Rarity.SERIAL else "Серийная модель"
		var tw := _width(font, tag, 8)
		draw_rect(Rect2(cx - tw * 0.5 - 12, top + 104, 6, 6), Color(accent, fa))
		_text(font, Vector2(cx - tw * 0.5 - 2, top + 111), tag, Color(accent, fa), 8)
		_text_c(font, Vector2(cx, top + 124), CATEGORY_NAMES[int(m["base"])].to_lower(), Color(MUTED, fa), 8)
		if res["duplicate"]:
			_text_c(font, Vector2(cx, top + 147), "уже в Арсенале: +%d ДНК" % res["dna"], Color(GOLD, fa), 11)
		else:
			var tr: Dictionary = WeaponDefs.TRAITS.get(m["trait"], {"name": "Серийная модель", "text": ""})
			_text_c(font, Vector2(cx, top + 139), "черта: " + str(tr["name"]), Color(GOLD, fa), 9)
			var yy := top + 153.0
			for line in _wrap(font, str(tr["text"]), 214.0, 8):
				_text_c(font, Vector2(cx, yy), line, Color(WHITE, 0.85 * fa), 8)
				yy += 9.5
	else:
		_text_c(font, Vector2(cx, top + 18), "Получено: образцы", Color(WHITE, fa), 11)
		_dna_icon(Vector2(cx, top + 62), 44.0, Color(GOLD, fa))
		_text_c(font, Vector2(cx, top + 118), "+%d ДНК" % res["dna"], Color(GOLD, fa), 20)
		_text_c(font, Vector2(cx, top + 154), "Передано в лабораторию", Color(MUTED, fa), 8)
	var hint := "Enter / клик — дальше"
	if _open_all and not _open_queue.is_empty():
		hint = "дальше через %.1f с · Enter / клик — сразу" % maxf(AUTO_NEXT - _open_t, 0.0)
	_text_c(font, Vector2(cx, r.end.y - 6), hint, Color(DIM, fa), 8)


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
	_text(font, Vector2(r.position.x + 14, y), "Образцы", MUTED, 9)
	_text_r(font, Vector2(r.end.x - 14, y), "+%d" % packs, WHITE, 9)
	y += 12
	_text(font, Vector2(r.position.x + 14, y), "Дубликаты → ДНК", MUTED, 9)
	_text_r(font, Vector2(r.end.x - 14, y), "+%d" % dupes, WHITE, 9)
	y += 14
	_text(font, Vector2(r.position.x + 14, y), "ИТОГО ДНК", GOLD, 11)
	_text_r(font, Vector2(r.end.x - 14, y), "+%d" % (packs + dupes), GOLD, 11)
	_text_c(font, Vector2(320, r.end.y - 6), "Enter", DIM, 7)


# --- оперативная карта --------------------------------------------------------------------------

func _open_operations() -> void:
	_op_preview_id = ""
	if _globe == null:
		_globe = GLOBE_SCENE.instantiate() as GlobeView
		add_child(_globe)
		# Настройки всегда перекрывают дисплей и перехватывают ввод.
		move_child(_settings_menu, -1)
		_globe.region_selected.connect(_select_region)
	_globe.refresh()
	var front: Dictionary = Campaign.world()["war"]["front"]
	var front_key := str(front)
	if not front.is_empty() and front_key != _front_seen:
		_front_seen = front_key
		_play("ui/confirm" if front["stopped"] else "ui/deny", -14)
	_globe.set_active(true)
	_select_region(_op_region, false)
	if _op_sel < 0:
		for i in Campaign.offers().size():
			if _operation_matches(Campaign.offers()[i]):
				_select_operation(i)
				break
	if not Campaign.last_report().is_empty():
		var report: Dictionary = Campaign.last_report()
		if _report_seen != str(report):
			_report_seen = str(report)
			_globe.show_changes(report)
			var stats: Dictionary = report.get("stats", {})
			_reward_text = "ОПЕРАЦИЯ ЗАВЕРШЕНА" if stats.get("outcome", "victory") == "victory" else "РАПОРТ ПОЛУЧЕН"
			_reward_t = 1.1


func _sync_globe() -> void:
	Music.play(&"globe" if _tab == Tab.OPERATIONS else &"base")
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
	if _campaign_end_action():
		return
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
	return Rect2(432, 64, 196, 280)


func _operation_matches(op: Dictionary) -> bool:
	if _op_filter == 2:
		return int(op["threat"]) <= 2
	if _op_filter == 3:
		return op["type"] == "nest"
	return _globe.matches_filter(Campaign.region_info(op["region_id"]))


## Картинки кэшируются вместе с остальным артом базы.
func _op_image(id: String, rect: Rect2, tint := Color.WHITE) -> void:
	if not _tex.has(id):
		_tex[id] = PixelArt.tex(id)
	draw_texture_rect(_tex[id], rect, false, tint)


func _op_tip(rect: Rect2, key: String, text: String) -> void:
	_hit(rect, key)
	_op_tips[key] = text


func _draw_operations(font: Font) -> void:
	_op_tips.clear()
	var world := Campaign.world()
	_text_r(font, Vector2(421, 51), "ХОД %d · %.0f%% · ПОТЕРИ %d / 3" % [int(world["turn"]) + 1, CampaignRules.average(world), CampaignRules.lost_keys(world)], MUTED, 8)
	var offers := Campaign.offers()
	var shown := 0
	for i in offers.size():
		var op := offers[i]
		if not _operation_matches(op): continue
		var rect := Rect2(12 + shown * 139, 300, 133, 43)
		shown += 1
		Style.surface(self, rect, Style.State.SELECTED if _op_sel == i else (Style.State.HOVERED if _hot("op:%d" % i) else Style.State.NORMAL))
		_op_image("ops_" + str(op["type"]), Rect2(rect.position + Vector2(6, 7), Vector2(18, 18)))
		_text(font, rect.position + Vector2(29, 15), "[%d] %s" % [i + 1, _war_region(op["region_id"])], WHITE, 9)
		_text(font, rect.position + Vector2(29, 30), "%s · %s" % [CampaignCatalog.type_label(op["type"]), _roman(op["threat"])], MUTED, 8)
		_hit(rect, "op:%d" % i)
	if world["phase"] in ["victory", "defeat"]:
		_draw_campaign_end(font, world)
		return
	_button(font, Rect2(12, 277, 91, 17), ["Все [Q/Y]", "Крит. [Q/Y]", "I–II [Q/Y]", "Ульи [Q/Y]"][_op_filter], MUTED, "op_filter:%d" % posmod(_op_filter + 1, 4), true, 8)
	_op_image("ops_clearance", Rect2(118, 278, 12, 12))
	_text(font, Vector2(134, 288), "%d / 3" % world["war"]["outposts"].size(), WHITE, 8)
	_op_image("campaign_sample", Rect2(173, 278, 12, 12))
	_text(font, Vector2(189, 288), "%d / 2" % world["war"]["samples"].size(), WHITE, 8)
	_text_r(font, Vector2(420, 288), "Путь к Сердцу открыт" if not world["nests"]["object_7"]["alive"] else ("Штурм открыт" if world["war"]["assault_unlocked"] else "Подготовка %d / 6" % mini(6, int(world["turn"]))), MUTED, 8)
	if _op_sel < 0:
		_text(Style.TITLE_FONT, Vector2(440, 85), "РАЗВЕДКА", WHITE, 16)
		_text(font, Vector2(440, 108), Campaign.region_info(_op_region)["name"], MUTED, 10)
		_button(font, Rect2(440, 126, 184, 22), "ЖУРНАЛ РЕГИОНА [J]", MUTED, "op_journal", true, 9)
		if _op_journal: _draw_operation_journal(font, Campaign.region_info(_op_region))
		return
	var op := offers[_op_sel]
	var info := Campaign.region_info(_op_region)
	draw_texture_rect(_canvas, _op_card_rect(), true)
	_text(font, Vector2(444, 81), info["name"].to_upper(), MUTED, 9)
	_text(Style.TITLE_FONT, Vector2(444, 105), str(op["name"]).to_upper() if op["type"] == "nest" else CampaignCatalog.type_label(op["type"]).to_upper(), WHITE, 13 if op["type"] == "nest" else 17)
	_button(font, Rect2(558, 111, 58, 16), "Журнал [J]", MUTED, "op_journal", true, 8)
	if _op_journal:
		_draw_operation_journal(font, info)
		return
	_op_image("ops_region_" + _op_region, Rect2(444, 133, 172, 43))
	for i in 5:
		_op_image("ops_threat", Rect2(444 + i * 13, 113, 10, 12), RED if i < int(op["threat"]) else DIM)
	_op_tip(Rect2(444, 111, 69, 16), "op_help_threat", "Угроза %d из 5. Влияет на врагов и награду." % op["threat"])
	var y := 190.0
	var briefing: String = "Уничтожить %s." % {"mother": "Матку", "meat_mountain": "Мясную гору", "general": "Генерала", "hive_heart": "Сердце Улья"}.get(CampaignCatalog.nest_in(op["region_id"]), "Объект-7") if op["type"] == "nest" else ("Контейнер → маяк. Борт на 5:00." if op["type"] == "extract" else "На 10:00 — узел заражения.")
	for line: String in _wrap(font, briefing, 172, 9):
		_text(font, Vector2(444, y), line, WHITE, 9)
		y += 11
	y = maxf(y + 3, 212)
	for modifier: String in op["modifiers"]:
		_op_image("ops_" + modifier, Rect2(444, y - 9, 12, 12))
		_text(font, Vector2(461, y), CampaignCatalog.MODIFIER_INFO[modifier]["name"], MUTED, 8)
		y += 12
	if _op_preview_id != op["id"]:
		_op_preview_id = op["id"]
		_op_preview = CampaignRules.advance(world, op, "victory", true)["world"]
		_op_failure = CampaignRules.advance(world, op, "defeat", true)["world"]
	_text(font, Vector2(444, 245), "ПОСЛЕ ОПЕРАЦИИ", MUTED, 8)
	var effect: Dictionary = op["effects"]["win"]
	var rewards := [["ops_infection_down", _signed(int(effect["infection"]))], ["ops_neighbors", _signed(int(effect["neighbors"]))], ["hud_dna", "×%.2f" % float(op["reward"]["dna_mul"])], ["hud_crate", "%.0f%%" % (float(op["reward"]["extra_crate_chance"]) * 100)]]
	for i in 4:
		var x := 444.0 + i * 44
		_op_image(rewards[i][0], Rect2(x, 252, 12, 12))
		_text(font, Vector2(x + 14, 262), rewards[i][1], WHITE, 8)
	_text(font, Vector2(444, 277), _infection_outcome("Победа", int(info["infection"]), int(_op_preview["regions"][_op_region]["infection"])), GREEN, 8)
	_text(font, Vector2(444, 288), _infection_outcome("Провал", int(info["infection"]), int(_op_failure["regions"][_op_region]["infection"])), RED, 8)
	var gain := "Форпост действует" if world["war"]["outposts"].has(_op_region) else "+1 форпост · рост −2 за ход"
	if op["type"] == "extract": gain = "Образец исследован" if world["war"]["samples"].has(_op_region) else "+1 образец для штурма"
	elif op["type"] == "nest": gain = "Улей будет уничтожен"
	_text(font, Vector2(444, 299), gain, GREEN, 8)
	var strike: Dictionary = world["war"]["front"]
	var forecast := "Прогноз регионов — в журнале"
	if _op_preview["phase"] == "defeat": forecast = "Даже при победе: война проиграна"
	elif _op_failure["phase"] == "defeat": forecast = "Провал: война проиграна · 3 / 3"
	elif not strike.is_empty() and not strike["stopped"]:
		forecast = "Победа сорвёт удар" if strike["target"] == _op_region else "Удар: " + _war_region(strike["target"])
	_text(font, Vector2(444, 309), forecast, MUTED, 8)
	_button(font, Rect2(444, 318, 172, 23), "НАЧАТЬ ОПЕРАЦИЮ [A]" if _op_pad else "НАЧАТЬ ОПЕРАЦИЮ [Enter]", GOLD, "op_start", true, 9)
	_draw_op_help(font)

func _infection_outcome(outcome: String, before: int, after: int) -> String:
	if after == 0: return outcome + ": регион очищен"
	return "%s: заражение %d%% → %d%%" % [outcome, before, after]


func _draw_war_status(font: Font, world: Dictionary) -> void:
	var war: Dictionary = world["war"]
	_op_image("ops_clearance", Rect2(17, 216, 13, 13))
	_text(font, Vector2(33, 226), "%d / 3" % war["outposts"].size(), WHITE, 8)
	_op_image("campaign_sample", Rect2(77, 216, 13, 13))
	_text(font, Vector2(94, 226), "%d / 2" % war["samples"].size(), WHITE, 8)
	_op_tip(Rect2(16, 213, 132, 19), "op_help_progress", "Штурм: 3 форпоста, образцы из 2 разных регионов и 6 завершённых операций. Форпост снижает местный рост на 2; при 80% он теряется.")
	var milestone := "Штурм открыт · Объект-7"
	if not world["nests"]["object_7"]["alive"]:
		milestone = "Путь к Сердцу открыт"
	elif not war["assault_unlocked"]:
		milestone = "Подготовка · ходы %d / 6" % mini(6, int(world["turn"]))
	_text(font, Vector2(16, 239), milestone, MUTED, 8)
	var strike: Dictionary = war["front"]
	if not strike.is_empty():
		_op_tip(Rect2(158, 66, 271, 18), "op_help_front", "Победа в цели срывает удар. На карте отмечено направление; наступление произойдёт после операции хода %d." % int(strike["due_turn"]))
	_text(font, Vector2(16, 255), "ПОСЛЕДНИЕ ХОДЫ", MUTED, 6)
	var history: Array = war["history"]
	for i in mini(3, history.size()):
		var item: Dictionary = history[i]
		var y := 260.0 + i * 13.0
		_op_image("ops_" + str(item["type"]), Rect2(16, y, 10, 10), WHITE if item["outcome"] == "victory" else Color("c58e79"))
		_text(font, Vector2(29, y + 8), "%02d %s" % [item["turn"], _war_region(item["region_id"])], MUTED, 6)
		_text_r(font, Vector2(146, y + 8), _signed(item["delta"]), Color("a8b69b") if item["delta"] <= 0 else Color("c58e79"), 6)
		_op_tip(Rect2(16, y, 132, 12), "op_help_history%d" % i, "%s · %s · среднее заражение %s п.п." % [CampaignCatalog.type_label(item["type"]), "победа" if item["outcome"] == "victory" else "провал", _signed(item["delta"])])


func _draw_war_forecast(font: Font, world: Dictionary, op: Dictionary) -> void:
	var gain := "Форпост уже действует"
	if op["type"] == "nest":
		var nest_id := CampaignCatalog.nest_in(op["region_id"])
		gain = {"mother": "Элитные группы −100% · регион и соседи", "meat_mountain": "Кислотные выбросы −100% · регион"}.get(nest_id, "Источник уничтожен · удары прекращены")
	elif op["type"] == "extract":
		gain = "Образец уже исследован" if world["war"]["samples"].has(op["region_id"]) else "Новый образец · +1 к подготовке"
	elif not world["war"]["outposts"].has(op["region_id"]):
		gain = "Новый форпост · рост −2 за ход"
	_text(font, Vector2(440, 247), gain, Color("a8b69b"), 7)
	var others: Array[String] = []
	for id: String in CampaignCatalog.REGIONS:
		if id != op["region_id"]:
			others.append(id)
	others.sort_custom(func(a: String, b: String) -> bool:
		return int(_op_preview["regions"][a]["infection"]) - int(world["regions"][a]["infection"]) > int(_op_preview["regions"][b]["infection"]) - int(world["regions"][b]["infection"]))
	for i in 2:
		var id := others[i]
		var from := int(world["regions"][id]["infection"])
		var to := int(_op_preview["regions"][id]["infection"])
		_text(font, Vector2(440, 260 + i * 11), "%s  %d → %d%%" % [_war_region(id), from, to], Color("c58e79") if to > from else MUTED, 7)
	var detail: Array[String] = ["Оставленные регионы: победа / провал"]
	for id: String in others:
		detail.append("%s: %d → %d / %d" % [CampaignCatalog.REGIONS[id]["name"], world["regions"][id]["infection"], _op_preview["regions"][id]["infection"], _op_failure["regions"][id]["infection"]])
	_op_tip(Rect2(440, 251, 184, 25), "op_help_others", "\n".join(detail))
	var strike: Dictionary = world["war"]["front"]
	if _op_preview["phase"] == "victory":
		_text(font, Vector2(440, 282), "Победа: фронт стабилизирован", Color("a8b69b"), 6)
	elif _op_preview["phase"] == "defeat":
		_text(font, Vector2(440, 282), "Даже при победе: война проиграна", Color("c58e79"), 6)
	elif _op_failure["phase"] == "defeat":
		_text(font, Vector2(440, 282), "Провал: война проиграна · 3/3", Color("c58e79"), 6)
	elif not strike.is_empty() and not strike["stopped"]:
		_text(font, Vector2(440, 282), "Победа сорвёт удар" if strike["target"] == op["region_id"] else "Удар остаётся: " + _war_region(strike["target"]), MUTED, 6)


func _war_region(id: String) -> String:
	return str(CampaignCatalog.REGIONS[id]["name"]).replace("Восточная", "Вост.").replace("Западная", "Зап.").replace("Северная", "Сев.").replace("Ближний", "Бл.").replace("Южная", "Юж.")


## Справка под списком не закрывает брифинг и карту.
func _draw_op_help(font: Font) -> void:
	if not _op_tips.has(_hover_key): return
	draw_rect(Rect2(18, 236, 394, 34), Style.RECESS)
	var y := 249.0
	for line: String in _wrap(font, _op_tips[_hover_key], 380, 8):
		_text(font, Vector2(24, y), line, WHITE, 8)
		y += 11
		if y > 266: break

func _draw_operation_journal(font: Font, info: Dictionary) -> void:
	var rows: Array[String] = []
	if _op_sel >= 0 and not _op_preview.is_empty():
		rows.append("ПРОГНОЗ: ПОБЕДА / ПРОВАЛ")
		for id: String in CampaignCatalog.REGIONS:
			rows.append("%s: %d → %d / %d" % [_war_region(id), Campaign.world()["regions"][id]["infection"], _op_preview["regions"][id]["infection"], _op_failure["regions"][id]["infection"]])
	rows.append("РОСТ ЗАРАЖЕНИЯ")
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
		wrapped.append_array(_wrap(font, row, 180, 8))
	_op_scroll = clampi(_op_scroll, 0, maxi(0, wrapped.size() - 13))
	for i in mini(13, wrapped.size() - _op_scroll):
		_text(font, Vector2(440, 110 + i * 11), wrapped[_op_scroll + i], WHITE, 8)
	_button(font, Rect2(440, 265, 88, 16), "↑ ВЫШЕ", MUTED, "op_scroll:0", true, 8)
	_button(font, Rect2(536, 265, 88, 16), "↓ НИЖЕ", MUTED, "op_scroll:1", true, 8)
	_button(font, Rect2(440, 283, 184, 19), "К БРИФИНГУ [B / Esc]", WHITE, "op_journal", true, 8)


## Число со знаком и настоящим минусом: −40, +7.
func _signed(v: int) -> String:
	return ("+%d" % v) if v > 0 else ("−%d" % -v if v < 0 else "0")


func _turns(n: int) -> String:
	var tail := n % 10
	if n % 100 >= 11 and n % 100 <= 14 or tail == 0 or tail >= 5:
		return "%d ходов" % n
	return "%d ход" % n if tail == 1 else "%d хода" % n


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
	await _test_click(Vector2(623, 16))
	_check("settings mouse open", _settings_menu.visible and _settings_menu.settings_open and not get_tree().paused)
	await _shot("settings")
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
	await _test_click(Vector2(211, 16))
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
	_sel_node = 8
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
	# Мышь, D-pad, вся схема и обе стороны развилки на одном экране.
	var tree_profile := Meta.to_dict()
	Meta.apply_preset("tree-mid")
	Meta.dna_earned = Meta.dna_for_level(47)
	_sel_node = 2
	_pad_mode = false
	await _wait(0.1)
	await _shot("tree_after")
	_focus_cluster(2)
	await _wait(0.1)
	var motion := InputEventMouseMotion.new()
	motion.position = (_tree_pos(34) + _origin) * _ui
	Input.parse_input_event(motion)
	await _wait(0.1)
	_check("tree hover selects grenade doctrine", _sel_node == 34 and _hover_key == "node:34")
	await _shot("tree_node")
	var tree_pad := InputEventJoypadButton.new()
	tree_pad.button_index = JOY_BUTTON_DPAD_RIGHT
	tree_pad.pressed = true
	Input.parse_input_event(tree_pad)
	await get_tree().process_frame
	_check("tree pad crosses fork", _sel_node != 34 and _pad_mode)
	await _shot("tree_pad")
	tree_pad.pressed = false
	Input.parse_input_event(tree_pad)
	_all_pressed()
	_check("tree reset confirmation", _confirm_node == "__reset")
	_cancel()
	_check("tree reset cancel retains build", Meta.tree_spent() == 42)
	_all_pressed()
	_accept_unlock()
	_check("tree reset refunds weighted cost", Meta.tree.is_empty() and Meta.skill_points() == 46)
	for c in 3:
		_tree_class(c)
		Meta.apply_preset("tree-mid")
		Meta.dna_earned = Meta.dna_for_level(50)
		_sel_node = 10 if c > 0 else 2
		await _wait(0.4)
		await _shot("tree_" + ClassTree.CLASSES[c])
		_check("class selected " + Meta.class_id, Meta.class_id == ClassTree.CLASSES[c])
	await _shot("class_select")
	var zoom_event := InputEventMouseButton.new()
	zoom_event.button_index = MOUSE_BUTTON_WHEEL_UP
	zoom_event.pressed = true
	for step in 4: _gui_input(zoom_event)
	_check("mouse wheel zoom", _tree_zoom > 1.6)
	_tree_pan = Vector2(320, 185) - _tree_pos(_sel_node)
	await _wait(0.2)
	await _shot("tree_zoom")
	_focus_cluster(int(ClassTree.node(_node_id(11))["cluster"]))
	_tree_pan += Vector2(295, 214) - _tree_pos(11)
	await _wait(0.1)
	var tooltip_motion := InputEventMouseMotion.new()
	tooltip_motion.position = (_tree_pos(11) + _origin) * _ui
	_gui_input(tooltip_motion)
	_check("hover key shows other doctrine", _sel_node == 11)
	await _wait(0.1)
	await _shot("tree_tooltip")
	var drag := InputEventMouseMotion.new()
	drag.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	drag.relative = Vector2(12, -6) * _ui
	var old_pan := _tree_pan
	_gui_input(drag)
	_check("middle mouse pans", _tree_pan == old_pan + Vector2(12, -6))
	var class_pad := InputEventJoypadButton.new()
	class_pad.button_index = JOY_BUTTON_Y
	class_pad.pressed = true
	_unhandled_input(class_pad)
	_check("pad Y cycles class", Meta.class_id == "assault" and _tree_zoom == 1.0)
	var zoom_pad := InputEventJoypadMotion.new()
	zoom_pad.axis = JOY_AXIS_TRIGGER_RIGHT
	zoom_pad.axis_value = 1.0
	_unhandled_input(zoom_pad)
	_check("pad trigger zooms", _tree_zoom > 1.0)
	_tree_class(0)
	Meta.from_dict(tree_profile)
	_sel_node = 1
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
	Meta.finish_test(0 if _test_fails == 0 else 1)


func _campaign_end_action() -> bool:
	if Meta.campaign["phase"] not in ["victory", "defeat"]:
		return false
	if Meta.campaign["phase"] == "victory":
		Campaign.continue_campaign()
	else:
		Campaign.new_campaign((int(Meta.campaign["seed"]) + 1) % int(CampaignCatalog.BALANCE["max_seed"]))
	_op_preview_id = ""
	_open_operations()
	queue_redraw()
	return true


func _draw_campaign_end(font: Font, world: Dictionary) -> void:
	var win: bool = world["phase"] == "victory"
	_op_image("ops_clearance" if win else "ops_infection_up", Rect2(506, 100, 48, 48))
	_text(font, Vector2(440, 174), "ФРОНТ СТАБИЛИЗИРОВАН" if win else "СЕТЬ ФОРПОСТОВ ПОТЕРЯНА", WHITE, 10)
	_text(font, Vector2(440, 193), "Среднее заражение" if win else "Потеряно ключевых регионов", MUTED, 8)
	_text(font, Vector2(440, 224), "%.0f%%" % CampaignRules.average(world) if win else "%d / %d" % [CampaignRules.lost_keys(world), int(CampaignCatalog.BALANCE["defeat_lost"])], WHITE, 24)
	_text(font, Vector2(440, 248), "Объект-7 уничтожен." if win else "Группа отходит. Образцы сохранены.", MUTED, 8)
	_text(font, Vector2(440, 264), "%d ходов · %d форп. · %d обр." % [world["turn"], world["war"]["outposts"].size(), world["war"]["samples"].size()], MUTED, 8)
	_button(font, Rect2(440, 282, 184, 20), "ПРОДОЛЖИТЬ  [A / Enter]" if win else "НОВАЯ КАМПАНИЯ  [A / Enter]", WHITE, "op_start", true, 8)


func _ars_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for category in WeaponDefs.BASES.size():
		var models: Array[int] = []
		for i in _ars_order.size():
			if int(WeaponDefs.MODELS[_ars_order[i]]["base"]) == category: models.append(i)
		for i in range(0, models.size(), 2):
			rows.append({"category": category, "first": i == 0, "models": models.slice(i, mini(i + 2, models.size()))})
	return rows
