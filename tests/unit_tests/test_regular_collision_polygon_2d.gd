extends GutCollectionTest

func assert_eq_shape(a : Shape2D, b : Shape2D, error_interval : float) -> void:
	if a.get_class() != b.get_class():
		fail_test("shapes aren't the same: %s vs %s" % [a, b])
		return

	if a is CircleShape2D:
		assert_almost_eq(a.radius, b.radius, error_interval)
		return
	
	if a is RectangleShape2D:
		assert_almost_eq(a.size, b.size, Vector2.ONE * error_interval)
		return
	
	if a is SegmentShape2D:
		assert_almost_eq(a.a, b.a, Vector2.ONE * error_interval)
		assert_almost_eq(a.b, b.b, Vector2.ONE * error_interval)
		return
	
	var points1 : PackedVector2Array = []
	var points2 : PackedVector2Array = []
	if a is ConcavePolygonShape2D:
		points1 = a.segments
		points2 = b.segments
	elif a is ConvexPolygonShape2D:
		points1 = a.points
		points2 = b.points
	else:
		fail_test("unexpected shapes encountered: %s vs %s" % [a, b])
		return
	
	assert_almost_eq_deep(points1, points2, Vector2.ONE * error_interval)

var class_script := preload("res://addons/simplified_shape_creation/regular_collision_polygon_2d/regular_collision_polygon_2d.gd")

func before_each():
	ignore_method_when_doubling(class_script, "_init")
	ignore_method_when_doubling(class_script, "widen_polyline")
	ignore_method_when_doubling(class_script, "widen_multiline")
	ignore_method_when_doubling(class_script, "_widen_polyline_result")
	ignore_method_when_doubling(class_script, "_widen_multiline_result")
	ignore_method_when_doubling(class_script, "convert_to_line_segments")

func test_init__filled_params__assigned_to_vars():
	var shape : RegularCollisionPolygon2D

	shape = autoqfree(RegularCollisionPolygon2D.new(5, 5.0, 1.0, 1.0, 1.0, 1.0, 1))

	assert_eq(shape.vertices_count, 5, "Property 'vertices_count'.")
	assert_eq(shape.size, 5.0, "Property 'size'.")
	assert_eq(shape.offset_rotation, 1.0, "Property 'offset_rotation'.")
	assert_eq(shape.width, 1.0, "Property 'width'.")
	assert_eq(shape.drawn_arc, 1.0, "Property 'drawn_arc'.")
	assert_eq(shape.corner_size, 1.0, "Property 'corner_size'.")
	assert_eq(shape.corner_smoothness, 1, "Property 'corner_smoothness'.")

func test_init__shape_not_null__queue_blocked():
	var shape := CollisionShape2D.new()
	autoqfree(shape)
	shape.shape = CircleShape2D.new()

	shape.set_script(class_script)

	assert_eq(shape._queue_status, RegularCollisionPolygon2D._BLOCK_QUEUE, "Property '_queue_status' should be '_BLOCK_QUEUE' (2)")

func test_init__shape_null__queue_not_blocked():
	var shape := CollisionShape2D.new()
	autoqfree(shape)
	shape.shape = null

	shape.set_script(class_script)

	assert_ne(shape._queue_status, RegularCollisionPolygon2D._BLOCK_QUEUE, "Property '_queue_status' should not be '_BLOCK_QUEUE' (2)")

func test_enter_tree__blocked_queue__regenerate_not_called_not_queued():
	var shape : RegularCollisionPolygon2D = partial_double(class_script).new() 
	stub(shape, "regenerate").to_do_nothing()
	shape.shape = RectangleShape2D.new()
	shape._queue_status = RegularCollisionPolygon2D._BLOCK_QUEUE

	shape._enter_tree()

	assert_not_called(shape, "regenerate")

func test_enter_tree__not_not_queued__now_not_queued(p= use_parameters([RegularCollisionPolygon2D._IS_QUEUED, RegularCollisionPolygon2D._BLOCK_QUEUE])):
	var shape : RegularCollisionPolygon2D = partial_double(class_script).new()
	shape._queue_status = p

	shape._enter_tree()

	assert_eq(shape._queue_status, RegularCollisionPolygon2D._NOT_QUEUED, "Property '_queue_status' should be '_NOT_QUEUED' (0).")

func test_queue_regenerate__not_queued__is_queued():
	var shape : RegularCollisionPolygon2D = autoqfree(RegularCollisionPolygon2D.new())
	shape.shape = RectangleShape2D.new()

	shape.queue_regenerate()

	assert_eq(shape._queue_status, RegularCollisionPolygon2D._IS_QUEUED, "Property '_queue_status' should be '_IS_QUEUED' (1).")

func test_queue_regenerate__in_tree__delayed_shape_filled():
	var shape : RegularCollisionPolygon2D = partial_double(class_script).new()
	stub(shape, "_enter_tree").to_do_nothing()
	shape._queue_status = RegularCollisionPolygon2D._NOT_QUEUED
	add_child(shape)

	shape.queue_regenerate()

	assert_null(shape.shape, "Property 'shape'.")
	await wait_for_signal(get_tree().process_frame, 10)
	await wait_frames(2)
	assert_not_null(shape.shape, "Property 'shape'.")
	assert_eq(shape._queue_status, RegularCollisionPolygon2D._NOT_QUEUED, "Property '_queue_status' should be '_NOT_QUEUED' (0).")

func test_regenerate__vertices_count_2__shape_segment_shape():
	var shape : RegularCollisionPolygon2D = autoqfree(RegularCollisionPolygon2D.new())
	shape.vertices_count = 2

	shape.regenerate()

	assert_true(shape.shape is SegmentShape2D, "Property 'shape' should be type SegmentShape2D.")

func test_regenerate__line_with_width_offset_rotation_multiples_of_PI__expected_shape(p = use_parameters([0, PI, -PI, TAU])):
	var expected_shape := RectangleShape2D.new()
	expected_shape.size = Vector2(5, 20)
	var shape : RegularCollisionPolygon2D = autoqfree(RegularCollisionPolygon2D.new())
	shape.vertices_count = 2
	shape.size = 10
	shape.width = 5
	shape.offset_rotation = p

	shape.regenerate()

	assert_true(shape.shape is RectangleShape2D, "Property 'shape' should be type RectangleShape2D.")
	if is_failing(): 
		return
	assert_eq_shape(shape.shape, expected_shape, 0.001)

func test_regenerate__line_with_width_offset_rotation_multiples_of_PI_plus_PI_over_2__shape_rectangle_wider_than_tall(p = use_parameters([PI / 2, -PI * 3 / 2, PI * 5 / 2])):
	var expected_shape := RectangleShape2D.new()
	expected_shape.size = Vector2(20, 5)
	var shape : RegularCollisionPolygon2D = autoqfree(RegularCollisionPolygon2D.new())
	shape.vertices_count = 2
	shape.size = 10
	shape.width = 5
	shape.offset_rotation = p

	shape.regenerate()

	assert_true(shape.shape is RectangleShape2D, "Property 'shape' should be type RectangleShape2D.")
	if is_failing(): 
		return
	assert_eq_shape(shape.shape, expected_shape, 0.001)

func test_regenerate__line_with_width_offset_rotation_not_multiple_of_PI_over_2__shape_4_point_convex_shape(p = use_parameters([1, -3, 5])):
	var shape : RegularCollisionPolygon2D = autoqfree(RegularCollisionPolygon2D.new())
	shape.vertices_count = 2
	shape.width = 5
	shape.offset_rotation = p

	shape.regenerate()

	assert_true(shape.shape is ConvexPolygonShape2D, "Property 'shape' should be type ConvexPolygonShape2D")
	if is_failing(): 
		return
	assert_eq(shape.shape.points.size(), 4, "Property 'shape.points' should have 4 points")

func test_regenerate__line_with_width_uses_drawn_arc__shape_16_point_concave_shape(p = use_parameters([2, PI, -1])):
	var shape : RegularCollisionPolygon2D = autoqfree(RegularCollisionPolygon2D.new())
	shape.vertices_count = 2
	shape.width = 5
	shape.drawn_arc = p

	shape.regenerate()

	assert_true(shape.shape is ConcavePolygonShape2D, "Property 'shape' should be type ConcavePolygonShape2D")
	if is_failing(): 
		return
	assert_eq(shape.shape.segments.size(), 16, "Property 'shape.segments' should have 16 points")

func test_regenerate__line_with_width_uses_drawn_arc_and_corner_size__expected_shape():
	var expected_shape := to_vector2s([-2.5, 10, -2.5, 5.40569, -2.5, 5.40569, -3.22642, 3.22642, -3.22642, 3.22642, -5.40569, 2.5, -5.40569, 2.5, -10, 2.5, -10, 2.5, -10, -2.5, -10, -2.5, -4.59431, -2.5, -4.59431, -2.5, 0.726424, -0.726424, 0.726424, -0.726424, 2.5, 4.59431, 2.5, 4.59431, 2.5, 10, 2.5, 10, -2.5, 10])
	var shape : RegularCollisionPolygon2D = autoqfree(RegularCollisionPolygon2D.new())
	shape.vertices_count = 2
	shape.width = 5
	shape.drawn_arc = PI * 3 / 2
	shape.corner_size = 5
	shape.corner_smoothness = 2

	shape.regenerate()

	assert_true(shape.shape is ConcavePolygonShape2D, "Property 'shape' should be type ConcavePolygonShape2D")
	if is_failing(): 
		return
	assert_almost_eq_deep(shape.shape.segments, expected_shape, Vector2.ONE * 0.001)

func test_regenerate__line_with_width_drawn_arc_PI_uses_corner_size__shape_8_point_concave_shape():
	var expected_shape := to_vector2s([-2.5, 10, -2.5, 6.12323e-16, -2.5, 6.12323e-16, 2.5, -6.12323e-16, 2.5, -6.12323e-16, 2.5, 10, 2.5, 10, -2.5, 10])
	var shape : RegularCollisionPolygon2D = autoqfree(RegularCollisionPolygon2D.new())
	shape.vertices_count = 2
	shape.width = 5
	shape.drawn_arc = PI
	shape.corner_size = 5

	shape.regenerate()

	assert_true(shape.shape is ConcavePolygonShape2D, "Property 'shape' should be type ConcavePolygonShape2D")
	if is_failing(): 
		return
	assert_almost_eq_deep(shape.shape.segments, expected_shape, Vector2.ONE * 0.001)

func test_regenerate__uses_width__shape_concave_shape():
	var shape : RegularCollisionPolygon2D = autoqfree(RegularCollisionPolygon2D.new())
	shape.width = 5

	shape.regenerate()

	assert_true(shape.shape is ConcavePolygonShape2D, "Property 'shape' should be type ConcavePolygonShape2D.")

func test_regenerate__vertices_count_4__shape_rectangle_shape():
	var shape : RegularCollisionPolygon2D = autoqfree(RegularCollisionPolygon2D.new())
	shape.vertices_count = 4

	shape.regenerate()

	assert_true(shape.shape is RectangleShape2D, "Property 'shape' should be type RectangleShape2D.")

func random_shapes(amount, seed_value := 999) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var array := []
	for i in amount / 4:
		var dictionary := {
			vertices_count = r.randi_range(1, 5),
			size = r.randf_range(10.0, 30.0),
			inner_size = 0.0 if i % 2 == 0 else r.randf_range(2.0, 10.0),
			width = 0.0 if i % 4 < 2 else r.randf_range(3.0, 5.0),
			drawn_arc = TAU if i % 8 < 4 else r.randf_range(-TAU, TAU),
			corner_size = 0.0 if i % 16 < 8 else r.randf_range(0.1, 0.2),
			corner_smoothness = randi_range(1, 4),
			scale_width = false,
			scale_corner_size = false
		}
		if i % 8 >= 4:
			var point_count : int = dictionary.vertices_count
			if is_zero_approx(dictionary.inner_size) and point_count == 2 or not is_zero_approx(dictionary.inner_size) and point_count == 1:
				dictionary.drawn_arc = randf_range(-TAU, TAU)
			else:
				if point_count == 1:
					point_count = 32
				if dictionary.inner_size > 0.0:
					point_count *= 2
				var point_arc_range := TAU / point_count
				if dictionary.inner_size > 0.0:
					dictionary.drawn_arc = (point_arc_range * randi_range(1, point_count) - point_arc_range / 2) * (randi_range(0, 1) * 2 - 1)
				else:
					dictionary.drawn_arc = point_arc_range * randi_range(1, point_count - 1) * (randi_range(0, 1) * 2 - 1)
			assert(dictionary.drawn_arc != 0, str(dictionary))
		

		array.append(dictionary)
		dictionary = dictionary.duplicate()
		dictionary.scale_width = true
		array.append(dictionary)
		dictionary = dictionary.duplicate()
		dictionary.scale_corner_size = true
		array.append(dictionary)
		dictionary = dictionary.duplicate()
		dictionary.scale_width = false
		array.append(dictionary)
	return array

func test_apply_transformation__various_shape_types_and_options__almost_expected_result(p=use_parameters(random_shapes(100))):
	const sample_rotation_amount = 2;
	const sample_scale_amount := PI
	var shape : RegularCollisionPolygon2D = partial_double(class_script).new()
	shape._queue_status = RegularCollisionPolygon2D._BLOCK_QUEUE
	shape.vertices_count = p.vertices_count
	shape.size = p.size
	shape.inner_size = p.inner_size
	shape.width = p.width
	shape.drawn_arc = p.drawn_arc
	shape.corner_size = p.corner_size
	shape.corner_smoothness = p.corner_smoothness
	shape._queue_status = RegularCollisionPolygon2D._NOT_QUEUED
	var expected := RegularCollisionPolygon2D.new()
	autoqfree(expected)
	expected.vertices_count = p.vertices_count
	expected.size = p.size
	expected.inner_size = p.inner_size
	expected.width = p.width
	expected.drawn_arc = p.drawn_arc
	expected.corner_size = p.corner_size
	expected.corner_smoothness = p.corner_smoothness
	expected.regenerate()
	shape.shape = expected.shape
	expected.offset_rotation += sample_rotation_amount
	expected.size *= sample_scale_amount
	expected.inner_size *= sample_scale_amount
	if p.scale_width:
		expected.width *= sample_scale_amount
	if p.scale_corner_size:
		expected.corner_size *= sample_scale_amount
	expected.regenerate()

	shape.apply_transformation(sample_rotation_amount, sample_scale_amount, p.scale_width, p.scale_corner_size)

	assert_eq_shape(shape.shape, expected.shape, 0.01)
