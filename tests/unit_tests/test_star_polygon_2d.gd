extends GutCollectionTest

var class_script := preload("res://addons/simplified_shape_creation/star_polygon_2d/star_polygon_2d.gd")
var sample_polygon := PackedVector2Array([Vector2.ONE, Vector2.RIGHT, Vector2.LEFT])

func before_each():
	ignore_method_when_doubling(class_script, "_init")
	ignore_method_when_doubling(class_script, "get_star_vertices")
	ignore_method_when_doubling(class_script, "_get_vertices")

func test_init__params_filled__assigned_to_vars():
	var star : StarPolygon2D

	star = autoqfree(StarPolygon2D.new(3, 5.0, 1.0, 1.0, Color.RED, Vector2.ONE, 1.0, 1.0, 1.0, 1))

	assert_eq(star.vertices_count, 3, "Property 'vertices_count'.")
	assert_eq(star.size, 5.0, "Property 'size'.")
	assert_eq(star.inner_size, 1.0, "Property 'inner_size'.")
	assert_eq(star.offset_rotation, 1.0, "Property 'offset_rotation'.")
	assert_eq(star.color, Color.RED, "Property 'color'.")
	assert_eq(star.offset, Vector2.ONE, "Property 'offset'.")
	assert_eq(star.width, 1.0, "Property 'width'.")
	assert_eq(star.drawn_arc, 1.0, "Property 'drawn_arc'.")
	assert_eq(star.corner_size, 1.0, "Property 'corner_size'.")
	assert_eq(star.corner_smoothness, 1, "Property 'corner_smoothness'.")

func test_init__polygon_not_empty__queue_blocked():
	var star := Polygon2D.new()
	autoqfree(star)
	star.polygon = sample_polygon

	star.set_script(class_script)

	assert_eq(star._queue_status, StarPolygon2D._BLOCK_QUEUE, "Property '_queue_status' should be '_BLOCK_QUEUE' (2)")

func test_init__polygon_empty__queue_not_blocked():
	var star := Polygon2D.new()
	autoqfree(star)
	star.polygon = PackedVector2Array()

	star.set_script(class_script)

	assert_ne(star._queue_status, StarPolygon2D._BLOCK_QUEUE, "Property '_queue_status' should not be '_BLOCK_QUEUE' (2)")

func test_enter_tree__blocked_queue__regenerate_not_called_not_queued():
	var shape : StarPolygon2D = partial_double(class_script).new()
	stub(shape, "regenerate").to_do_nothing()
	shape.polygon = sample_polygon
	shape._queue_status = StarPolygon2D._BLOCK_QUEUE

	shape._enter_tree()

	assert_not_called(shape, "regenerate") # does not accept a custom message.

func test_enter_tree__not_not_queued__now_not_queued(p= use_parameters([StarPolygon2D._IS_QUEUED, StarPolygon2D._BLOCK_QUEUE])):
	var shape : StarPolygon2D = partial_double(class_script).new()
	shape._queue_status = p

	shape._enter_tree()

	assert_eq(shape._queue_status, StarPolygon2D._NOT_QUEUED, "Property '_queue_status' should be '_NOT_QUEUED' (0).")

func test_pre_redraw__not_queued__is_queued():
	var star : StarPolygon2D = partial_double(class_script).new()
	stub(star, "uses_polygon_member").to_return(true)
	star.polygon = sample_polygon
	star._queue_status = StarPolygon2D._NOT_QUEUED

	star.queue_regenerate()

	assert_eq(star._queue_status, StarPolygon2D._IS_QUEUED, "Property '_queue_status' should be '_IS_QUEUED' (1).")

func test_queue_regenerate__in_tree__delayed_shape_filled():
	var star : StarPolygon2D = partial_double(class_script).new()
	star.width = 10
	star._queue_status = StarPolygon2D._NOT_QUEUED
	stub(star, "_enter_tree").to_do_nothing()
	add_child(star)

	star.queue_regenerate()

	assert_true(star.polygon.is_empty(), "Variable 'polygon' should still be an empty array.")
	await wait_for_signal(get_tree().process_frame, 10)
	await wait_frames(2)
	assert_false(star.polygon.is_empty(), "Property 'polygon' should be a filled array at this point.")
	assert_eq(star._queue_status, StarPolygon2D._NOT_QUEUED, "Property '_queue_status' should be '_NOT_QUEUED' (0).")

func test_get_star_vertices__drawn_arc_PI__no_central_point(p = use_parameters([[PI], [-PI]])):
	var star : PackedVector2Array

	star = StarPolygon2D.get_star_vertices(5, 10, 5, 0, Vector2.ZERO, p[0])

	assert_almost_ne(star[-1], Vector2.ZERO, Vector2.ONE * 0.01, "The last point of the returned array.")
	assert_eq(star.size(), 6, "Size of the returned array.")

func test_get_star_vertices__add_central_point_false__expected_size_and_not_ZERO():
	var expected_shape := PackedVector2Array([Vector2(-1.22465e-15, -10), Vector2(2.93893, -4.04508), Vector2(9.51057, -3.09017), Vector2(4.75528, 1.54508), Vector2(5.87785, 8.09017), Vector2(1.22465e-15, 5), Vector2(-5.87785, 8.09017), Vector2(-4.75528, 1.54508), Vector2(-6.34038, 0)])
	var star : PackedVector2Array

	star = StarPolygon2D.get_star_vertices(5, 10, 5, 0, Vector2.ZERO, PI * 3 / 2, false)

	assert_almost_eq_deep(star, expected_shape, Vector2.ONE * 0.001)

var params_transform_shape := [
	[4, 10, 100, TAU, 0, 0],
	[20, 10, 100, TAU, 0, 0],
	[4, 100, 10, TAU, 0, 0],
	[4, 10, 5, -PI, 0.5, 3],
	[8, 30, 15, 2.269, 1, 2],
]
func test_apply_transformation__various_shape_types__almost_expected_result(p=use_parameters(params_transform_shape)):
	const sample_rotation_amount = 2;
	const sample_scale_amount := PI
	assert(p[2] >= 0 and p[0] != 2, "param does not have the node use 'polygon'.")
	var shape : StarPolygon2D = partial_double(class_script).new()
	shape._queue_status = StarPolygon2D._BLOCK_QUEUE
	shape.vertices_count = p[0]
	shape.size = p[1]
	shape.inner_size = p[1] / 2.0
	shape.width = p[2]
	shape.drawn_arc = p[3]
	shape.corner_size = p[4]
	shape.corner_smoothness = p[5]
	shape._queue_status = StarPolygon2D._NOT_QUEUED
	var expected := StarPolygon2D.new()
	autoqfree(expected)
	expected.vertices_count = p[0]
	expected.size = p[1]
	expected.inner_size = p[1] / 2.0
	expected.width = p[2]
	expected.drawn_arc = p[3]
	expected.corner_size = p[4]
	expected.corner_smoothness = p[5]
	expected.regenerate()
	shape.polygon = expected.polygon
	expected.offset_rotation += sample_rotation_amount
	expected.size *= sample_scale_amount
	expected.inner_size *= sample_scale_amount
	expected.regenerate()

	shape.apply_transformation(sample_rotation_amount, sample_scale_amount, false, false)

	assert_almost_eq_deep(shape.polygon, expected.polygon, Vector2.ONE * 0.001)
	assert_not_called(shape, "regenerate")

func test_apply_transformation__size_change_creates_ring__shape_regenerated() -> void:
	const sample_scale_amount := 3
	var expected := StarPolygon2D.new()
	expected.vertices_count = 4
	expected.width = 15
	expected.regenerate()
	autoqfree(expected)
	var shape : StarPolygon2D = partial_double(class_script).new()
	shape._queue_status = StarPolygon2D._BLOCK_QUEUE
	shape.vertices_count = 4
	shape.width = 15
	shape._queue_status = StarPolygon2D._NOT_QUEUED
	shape.polygon = expected.polygon
	expected.size *= sample_scale_amount
	expected.inner_size *= sample_scale_amount
	expected.regenerate()

	shape.apply_transformation(0, sample_scale_amount, false, false)

	assert_called(shape, "regenerate")
	assert_almost_eq_deep(shape.polygon, expected.polygon, Vector2.ONE * 0.001)

func test_apply_transformation__size_change_removes_ring__shape_regenerated() -> void:
	const sample_scale_amount := 0.2
	var expected := StarPolygon2D.new()
	expected.vertices_count = 4
	expected.width = 5
	expected.regenerate()
	autoqfree(expected)
	var shape : StarPolygon2D = partial_double(class_script).new()
	shape._queue_status = StarPolygon2D._BLOCK_QUEUE
	shape.vertices_count = 4
	shape.width = 5
	shape._queue_status = StarPolygon2D._NOT_QUEUED
	shape.polygon = expected.polygon
	expected.size *= sample_scale_amount
	expected.inner_size *= sample_scale_amount
	expected.regenerate()

	shape.apply_transformation(0, sample_scale_amount, false, false)

	assert_called(shape, "regenerate")
	assert_almost_eq_deep(shape.polygon, expected.polygon, Vector2.ONE * 0.001)

func test_apply_transformation__width_scaled__expected_shape(p=use_parameters(params_transform_shape)):
	const sample_scale_amount := 2.3
	const sample_rotation_amount := 1
	var shape : StarPolygon2D = partial_double(class_script).new()
	shape._queue_status = StarPolygon2D._BLOCK_QUEUE
	shape.vertices_count = p[0]
	shape.size = p[1]
	shape.inner_size = p[1] / 2.0
	shape.width = p[2]
	shape.drawn_arc = p[3]
	shape.corner_size = p[4]
	shape.corner_smoothness = p[5]
	shape._queue_status = StarPolygon2D._NOT_QUEUED
	var expected := StarPolygon2D.new()
	autoqfree(expected)
	expected.vertices_count = p[0]
	expected.size = p[1]
	expected.inner_size = p[1] / 2.0
	expected.width = p[2]
	expected.drawn_arc = p[3]
	expected.corner_size = p[4]
	expected.corner_smoothness = p[5]
	expected.regenerate()
	shape.polygon = expected.polygon
	expected.offset_rotation += sample_rotation_amount
	expected.size *= sample_scale_amount
	expected.inner_size *= sample_scale_amount
	expected.width *= sample_scale_amount
	expected.regenerate()

	shape.apply_transformation(sample_rotation_amount, sample_scale_amount, true, false)

	assert_almost_eq_deep(shape.polygon, expected.polygon, Vector2.ONE * 0.001)
	assert_not_called(shape, "regenerate")

func test_apply_transformation__corner_size_scaled__expected_shape(p=use_parameters(params_transform_shape)):
	const sample_scale_amount := 2.3
	const sample_rotation_amount := 1
	var shape : StarPolygon2D = partial_double(class_script).new()
	shape._queue_status = StarPolygon2D._BLOCK_QUEUE
	shape.vertices_count = p[0]
	shape.size = p[1]
	shape.inner_size = p[1] / 2.0
	shape.width = p[2]
	shape.drawn_arc = p[3]
	shape.corner_size = p[4]
	shape.corner_smoothness = p[5]
	shape._queue_status = StarPolygon2D._NOT_QUEUED
	var expected := StarPolygon2D.new()
	autoqfree(expected)
	expected.vertices_count = p[0]
	expected.size = p[1]
	expected.inner_size = p[1] / 2.0
	expected.width = p[2]
	expected.drawn_arc = p[3]
	expected.corner_size = p[4]
	expected.corner_smoothness = p[5]
	expected.regenerate()
	shape.polygon = expected.polygon
	expected.offset_rotation += sample_rotation_amount
	expected.size *= sample_scale_amount
	expected.inner_size *= sample_scale_amount
	expected.corner_size *= sample_scale_amount
	expected.regenerate()

	shape.apply_transformation(sample_rotation_amount, sample_scale_amount, false, true)

	assert_almost_eq_deep(shape.polygon, expected.polygon, Vector2.ONE * 0.001)
	assert_not_called(shape, "regenerate")

func test_apply_transformation__width_and_corner_size_scaled__expected_shape(p=use_parameters(params_transform_shape)):
	const sample_scale_amount := 2.3
	const sample_rotation_amount := 1
	var shape : StarPolygon2D = partial_double(class_script).new()
	shape._queue_status = StarPolygon2D._BLOCK_QUEUE
	shape.vertices_count = p[0]
	shape.size = p[1]
	shape.inner_size = p[1] / 2.0
	shape.width = p[2]
	shape.drawn_arc = p[3]
	shape.corner_size = p[4]
	shape.corner_smoothness = p[5]
	shape._queue_status = StarPolygon2D._NOT_QUEUED
	var expected := StarPolygon2D.new()
	autoqfree(expected)
	expected.vertices_count = p[0]
	expected.size = p[1]
	expected.inner_size = p[1] / 2.0
	expected.width = p[2]
	expected.drawn_arc = p[3]
	expected.corner_size = p[4]
	expected.corner_smoothness = p[5]
	expected.regenerate()
	shape.polygon = expected.polygon
	expected.offset_rotation += sample_rotation_amount
	expected.size *= sample_scale_amount
	expected.inner_size *= sample_scale_amount
	expected.width *= sample_scale_amount
	expected.corner_size *= sample_scale_amount
	expected.regenerate()

	shape.apply_transformation(sample_rotation_amount, sample_scale_amount, true, true)

	assert_almost_eq_deep(shape.polygon, expected.polygon, Vector2.ONE * 0.001)
	assert_not_called(shape, "regenerate")
