extends GdUnitTestSuite
## Строй — редкое событие; даже его участники преследуют текущую цель.

var _horde: Horde
var _player: Player
var _director: HordeDirector
const SHARES := [60, 20, 10, 10]


func before_test() -> void:
	_player = auto_free(Player.new())
	_player.position = Vector2(2000, 2000)
	_horde = auto_free(Horde.new())
	add_child(_horde)
	_horde.set_physics_process(false)
	_horde.arena = Rect2(0, 0, 4000, 4000)
	_horde.player = _player
	_director = HordeDirector.new()
	_director.setup(_horde, _player, 81073, "open_perimeter")


func test_three_warned_events_in_ten_minutes_and_no_ordinary_formations() -> void:
	var warnings: Array[int] = []
	var serial := 0
	for second in 600:
		_director.advance(float(second), 1.0, SHARES, false)
		if _director.warning_serial != serial:
			serial = _director.warning_serial
			warnings.append(second)
			assert_float(_director.warning_left).is_greater_equal(HordeDirector.WARNING)
			assert_int(_director.shape_count(8, float(second))).is_zero()
		if second < 90 or second >= 117 and second < 250 or second >= 277 and second < 410 or second >= 437:
			assert_int(_director.shape_count(8, float(second))).is_zero()
	assert_array(warnings).is_equal([87, 247, 407])


func test_priority_event_discards_formation_without_catchup() -> void:
	_director.advance(87.0, 0.1, SHARES, true)
	_director.advance(90.0, 0.1, SHARES, false)
	assert_int(_director.warning_serial).is_zero()
	assert_int(_director.shape_count(20, 90.0)).is_zero()
	_director.advance(247.0, 0.1, SHARES, false)
	assert_int(_director.warning_serial).is_equal(1)


func test_ordinary_runners_do_not_cancel_warned_slow_front() -> void:
	_director.advance(87.0, 0.1, SHARES, false)
	_director.fast_origin = Vector2(2800, 2000)
	_director.advance(90.0, 0.1, SHARES, false)
	assert_int(_director.shape_count(8, 90.0)).is_equal(8)
	assert_int(_director.spawn_group(8, SHARES, false, 90.0)).is_equal(8)
	_director.advance(117.0, 0.1, SHARES, false)
	for i in _horde.count:
		_horde._group_direction(i, Vector2.LEFT)
		assert_int(_horde.group_id[i]).is_zero()
	assert_int(_director.shape_count(8, 117.0)).is_zero()


func test_all_group_modes_follow_player_and_dissolve_after_event() -> void:
	var i := _horde.spawn(Vector2(2400, 2000))
	for mode in Horde.GroupMode.values():
		var token := _horde.make_group(PackedVector2Array([_horde.pos[i], Vector2(2600, 2200)]), mode, 30.0)
		_horde.attach_group(i, token)
		assert_vector(_horde._group_direction(i, Vector2.LEFT)).is_equal(Vector2.LEFT)
		_player.position = Vector2(2500, 2000)
		assert_vector(_horde._group_direction(i, Vector2.RIGHT)).is_equal(Vector2.RIGHT)
		_horde._time += 30.0
		_horde._group_direction(i, Vector2.RIGHT)
		assert_int(_horde.group_id[i]).is_zero()


func test_event_sources_are_distant_and_stay_fixed_when_player_moves() -> void:
	_director.force_pattern(HordeDirector.Pattern.PINCER, 0.0, 300.0)
	var sources := _director._origins.duplicate()
	for at in sources:
		assert_float(at.distance_to(_player.position)).is_greater_equal(_horde.spawn_ring * 1.5)
	_director._forced = false
	_player.position += Vector2(0, 190)
	_director.spawn_group(8, SHARES, false, 310.0)
	assert_array(Array(_director._origins)).is_equal(Array(sources))
	_director.advance(330.0, 0.1, SHARES, false)
	for i in _horde.count:
		_horde._group_direction(i, Vector2.LEFT)
		assert_int(_horde.group_id[i]).is_zero()
