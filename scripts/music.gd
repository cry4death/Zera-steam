extends Node
## Музыка (треки автора, Suno; исходники и сборка — tools/prep_music.py). Автозагрузка «Music».
##
## Сцены называют контекст, музыка сама решает трек: база — «Protocol Zero», вкладка «Операции» — «Orbit of
## Extinction», бой — плейлист без повторов, Объект-7 — свой трек с предупреждения. Смена — кроссфейд в
## реальном времени (хит-стоп и пауза не растягивают). Треки базы продолжаются с места, где их прервали.
## Без звука в headless; громкость — шина «Music» и настройка «music».

const DIR := "res://music/"
const BASE := "protocol_zero"
const GLOBE := "orbit_of_extinction"
const BOSS := "descent_into_madness_a"
const COMBAT := ["descent_into_madness_b", "delirious_charge", "delirium_charge", "infected_among_us",
	"mechanical_suffocation", "mechanical_survival", "obsessive_groove", "pressurized_chamber", "quarantine_zone",
	"rattling_machine", "sirenes_des_cendres", "suffocating_tension", "por"]
const FADE := 2.5 ## с: кроссфейд между треками
const OVERLAP := 3.0 ## с до конца трека: начать следующий (в конце трека зашито затухание 1.5 с)
const RESULTS_DB := -9.0 ## итоги забега: текущий трек тише
const DUCK_DB := -8.0 ## меню паузы и настройки

var _players: Array[AudioStreamPlayer] = []
var _gain := [0.0, 0.0]
var _active := 0
var _context := &""
var _bag: Array[String] = []
var _next := ""
var _drawn := ""
var _resume := {}
var _level_db := 0.0
var _duck := false
var _last_usec := 0
var _enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_enabled = DisplayServer.get_name() != "headless"
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = &"Music"
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	_last_usec = Time.get_ticks_usec()


## &"base", &"globe", &"combat", &"boss", &"results". Повтор того же контекста ничего не меняет.
func play(context: StringName) -> void:
	if context == _context or not _enabled:
		return
	_context = context
	_duck = false
	if context != &"results":
		_start(_pick())


## Приглушить на время меню паузы и настроек.
func duck(on: bool) -> void:
	_duck = on


func current() -> String:
	var p := _players[_active]
	return str(p.get_meta("id", "")) if p.playing else ""


func _pick() -> String:
	match _context:
		&"base": return BASE
		&"globe": return GLOBE
		&"boss": return BOSS
	if _next.is_empty():
		_next = _draw()
	var id := _next
	_next = _draw()
	ResourceLoader.load_threaded_request(DIR + _next + ".ogg")
	return id


## Мешок без повторов: все боевые треки по разу, на стыке мешков тот же трек не подряд.
func _draw() -> String:
	if _bag.is_empty():
		_bag.assign(COMBAT)
		_bag.shuffle()
		if _bag.size() > 1 and _bag[-1] == _drawn:
			_bag.reverse()
	_drawn = _bag.pop_back()
	return _drawn


func _start(id: String, restart := false) -> void:
	var cur := _players[_active]
	var cur_id := str(cur.get_meta("id", ""))
	if cur.playing and cur_id == id and not restart:
		return
	if cur.playing and cur_id in [BASE, GLOBE]:
		_resume[cur_id] = 0.0 if restart else cur.get_playback_position()
	_active = 1 - _active
	var p := _players[_active]
	var path := DIR + id + ".ogg"
	if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		p.stream = ResourceLoader.load_threaded_get(path)
	else:
		p.stream = load(path)
	p.set_meta("id", id)
	_gain[_active] = 0.0
	p.volume_db = -80.0
	p.play(float(_resume.get(id, 0.0)) if not restart else 0.0)


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var dt := minf((now - _last_usec) / 1.0e6, 0.25)
	_last_usec = now
	if not _enabled or _context.is_empty():
		return
	var level := (RESULTS_DB if _context == &"results" else 0.0) + (DUCK_DB if _duck else 0.0)
	_level_db = move_toward(_level_db, level, dt * 16.0)
	for i in 2:
		var p := _players[i]
		_gain[i] = move_toward(_gain[i], 1.0 if i == _active else 0.0, dt / FADE)
		if not p.playing:
			continue
		if _gain[i] <= 0.0 and i != _active:
			p.stop()
			continue
		p.volume_db = linear_to_db(maxf(_gain[i], 0.0001)) + _level_db
	var a := _players[_active]
	if a.stream == null:
		return
	if not a.playing or a.stream.get_length() - a.get_playback_position() < OVERLAP:
		_start(_pick(), true)
