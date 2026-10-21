extends GdUnitTestSuite
## PT1c: новые стороны не переносят следы и не переключают спрайт.

var objects: Obstacles


func before_test() -> void:
	objects = Obstacles.new()
	add_child(objects)
	objects.set_process(false)
	objects.set_physics_process(false)
	var layout: Array[Dictionary] = [{"kind": Obstacles.Kind.SEDAN, "pos": Vector2(128, 128), "angle": 0.6}]
	objects.setup(Rect2(0, 0, 256, 256), layout)


func after_test() -> void:
	objects.free()


func hit(local: Vector2, direction: Vector2) -> void:
	objects.splatter(objects.pos[0] + local.rotated(0.6), direction.rotated(0.6))


func test_opposite_sides_keep_original_positions_and_sprite() -> void:
	objects._sync_art()
	var tile := objects._art_buffer.slice(8, 10)
	hit(Vector2(-34, 0), Vector2.RIGHT)
	var first := objects._blood_at[0]
	objects._process(30.0)
	hit(Vector2(34, 0), Vector2.LEFT)
	hit(Vector2(0, 16), Vector2.UP)
	objects._process(0.0)
	objects._sync_art()
	assert_int(objects.blood[0]).is_equal(3)
	assert_vector(objects._blood_at[0]).is_equal(first)
	assert_float(objects._blood_time[0]).is_equal(0.0)
	assert_float(objects._blood_time[1]).is_equal(30.0)
	assert_array(objects._art_buffer.slice(8, 10)).is_equal(tile)
	assert_int(objects._blood_meshes.size()).is_equal(1)
	var mesh := objects._blood_meshes[0]
	var vertices: PackedVector2Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for vertex in vertices:
		var p := (vertex - objects.pos[0]).rotated(-0.6)
		assert_bool(absf(p.x) <= 48.01 and absf(p.y) <= 24.01).is_true()


func test_blood_moving_away_does_not_hit_far_side() -> void:
	hit(Vector2(-40, 0), Vector2.LEFT)
	assert_int(objects.blood[0]).is_equal(0)
	hit(Vector2(-40, 0), Vector2.RIGHT)
	assert_int(objects.blood[0]).is_equal(1)
	assert_float(objects._blood_at[0].x).is_less(0.0)


func test_repeated_contact_does_not_move_or_refresh_old_stain() -> void:
	objects.stain_blood(objects.pos[0], 5.0)
	objects._process(120.0)
	objects.stain_blood(objects.pos[0], 5.0)
	assert_int(objects.blood[0]).is_equal(1)
	assert_float(objects._blood_time[0]).is_equal(0.0)
	assert_float(objects._blood_clock).is_equal(120.0)
	objects.state[0] = Obstacles.State.GONE
	objects._mark_art(0)
	objects._process(0.0)
	assert_int(objects._blood_meshes[0].get_surface_count()).is_equal(0)


func test_limits_keep_existing_stains() -> void:
	for j in 100:
		objects._add_blood(0, Vector2(j % 10, j / 10) * 3.0, Vector2.RIGHT, 0.5)
	assert_int(objects._blood_at.size()).is_equal(Obstacles.BLOOD_PER_OBJECT)
	assert_vector(objects._blood_at[0]).is_equal(Vector2.ZERO)
	assert_int(objects._blood_node.get_child_count()).is_equal(0)
