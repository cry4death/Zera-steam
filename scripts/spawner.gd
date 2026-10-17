class_name Spawner
extends Node
## Кривая спавна из BALANCE.md §7.1. В M1 — только шаркающие и без тревоги.

# [начало_сек, спавн/сек, лимит живых]
const CURVE := [
	[0.0, 1.5, 60],
	[60.0, 3.0, 100],
	[120.0, 4.0, 150],
	[210.0, 5.0, 200],
	[240.0, 6.0, 250],
	[300.0, 7.0, 300],
	[360.0, 8.0, 350],
	[450.0, 9.0, 400],
	[480.0, 11.0, 500],
]

var horde: Horde
var player: Player
var time := 0.0
var enabled := true

var _budget := 0.0
var _next_group := 4


func _physics_process(delta: float) -> void:
	if not enabled or horde == null or player.is_dead:
		return
	var phase: Array = CURVE[0]
	for p: Array in CURVE:
		if time >= p[0]:
			phase = p
	var rate: float = phase[1]
	var cap: int = phase[2]

	_budget += rate * delta
	# копим «бюджет» и выпускаем зомби группами — так орда читается как волна
	if _budget >= _next_group:
		var room := cap - horde.count
		if room <= 0:
			_budget = minf(_budget, float(_next_group))
			return
		var n := mini(_next_group, room)
		horde.spawn_group(player.global_position, n)
		_budget -= n
		_next_group = randi_range(3, 6) if time < 60.0 else randi_range(5, 15)


func current_rate() -> float:
	var rate := 0.0
	for p: Array in CURVE:
		if time >= p[0]:
			rate = p[1]
	return rate
