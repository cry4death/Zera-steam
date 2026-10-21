extends "res://scripts/horde.gd"
## ZAI1 (временный): снимки позиций внутри тика орды — до шага, после шага (с выталкиванием игроком),
## после разделения и после стен. Стенд zai1_probe.gd ставит этот скрипт на узел Horde до входа в дерево.

var probe_on := false
var s0 := PackedVector2Array() # до _move
var k0 := PackedVector2Array() # отброс до _move
var ch0 := PackedFloat32Array() # замедление до _move
var fr0 := PackedFloat32Array() # заморозка до _move
var a1 := PackedVector2Array() # после _move
var c1 := PackedVector2Array() # после _separate
var tick_cb := Callable() # (delta) — зовётся из _render, когда pos уже после стен


func _move(delta: float) -> void:
	if probe_on:
		s0 = pos.duplicate()
		k0 = knock.duplicate()
		ch0 = chill.duplicate()
		fr0 = freeze_t.duplicate()
	super._move(delta)
	if probe_on:
		a1 = pos.duplicate()
		_last_delta = delta


func _separate() -> void:
	super._separate()
	if probe_on:
		c1 = pos.duplicate()


var _last_delta := 0.0


func _render() -> void:
	if probe_on and tick_cb.is_valid() and s0.size() == pos.size() and c1.size() == pos.size():
		tick_cb.call(_last_delta)
	super._render()
