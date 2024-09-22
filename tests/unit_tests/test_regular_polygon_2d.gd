extends GutCollectionTest

var class_script := preload("res://addons/simplified_shape_creation/regular_polygon_2d/regular_polygon_2d.gd")
var sample_polygon := PackedVector2Array([Vector2.ONE, Vector2.RIGHT, Vector2.LEFT])

func before_each():
	ignore_method_when_doubling(class_script, "_init")
	ignore_method_when_doubling(class_script, "get_shape_vertices")
	ignore_method_when_doubling(class_script, "_get_vertices")
	ignore_method_when_doubling(class_script, "_find_intersection")
	ignore_method_when_doubling(class_script, "add_rounded_corners")
	ignore_method_when_doubling(class_script, "quadratic_bezier_interpolate")
	ignore_method_when_doubling(class_script, "add_hole_to_points")
	ignore_method_when_doubling(class_script, "_add_rounded_corners_result")
	ignore_method_when_doubling(class_script, "_add_hole_to_points_result")

func test_init__filled__variables_assigned():
	var shape : RegularPolygon2D

	shape = autoqfree(RegularPolygon2D.new(5, 5.0, 1.0, Color.RED, Vector2.ONE, 0.0, 2.0, 1.0, 1))

	assert_eq(shape.vertices_count, 5, "Property 'vertices_count'.")
	assert_eq(shape.size, 5.0, "Property 'size'.")
	assert_eq(shape.offset_rotation, 1.0, "Property 'offset_rotation'.")
	assert_eq(shape.color, Color.RED, "Property 'color'.")
	assert_eq(shape.offset, Vector2.ONE, "Property 'offset'.")
	assert_eq(shape.width, 0.0, "Property 'width'.")
	assert_eq(shape.drawn_arc, 2.0, "Property 'drawn_arc'.")
	assert_eq(shape.corner_size, 1.0, "Property 'corner_size'.")
	assert_eq(shape.corner_smoothness, 1, "Property 'corner_smoothness'.")

func test_init__polygon_not_empty__queue_blocked():
	var shape := Polygon2D.new()
	autoqfree(shape)
	shape.polygon = sample_polygon

	shape.set_script(class_script)

	assert_eq(shape._queue_status, RegularPolygon2D._BLOCK_QUEUE, "Property '_queue_status' should be '_BLOCK_QUEUE' (2)")

func test_init__polygon_empty__queue_not_blocked():
	var shape := Polygon2D.new()
	autoqfree(shape)
	shape.polygon = PackedVector2Array()

	shape.set_script(class_script)

	assert_ne(shape._queue_status, RegularPolygon2D._BLOCK_QUEUE, "Property '_queue_status' should not be '_BLOCK_QUEUE' (2)")

func test_pre_redraw__in_tree_using_polygon__delayed_polygon_fill():
	var shape : RegularPolygon2D = partial_double(class_script).new()
	shape.width = 10
	shape._queue_status = RegularPolygon2D._NOT_QUEUED
	stub(shape, "_enter_tree").to_do_nothing()
	add_child(shape)

	shape.queue_regenerate()

	assert_true(shape.polygon.is_empty(), "Variable 'polygon' should still be an empty array.")
	await wait_for_signal(get_tree().process_frame, 10)
	await wait_frames(2)
	assert_false(shape.polygon.is_empty(), "Variable 'polygon' should be a filled array at this point.")
	assert_eq(shape._queue_status, RegularPolygon2D._NOT_QUEUED, "Property '_queue_status' should be '_NOT_QUEUED' (0).")

func test_enter_tree__blocked_queue__polygon_not_regenerated():
	var shape : RegularPolygon2D = partial_double(class_script).new()
	stub(shape, "uses_polygon_member").to_return(true)
	stub(shape, "regenerate").to_do_nothing()
	shape._queue_status = RegularPolygon2D._BLOCK_QUEUE

	shape._enter_tree()

	assert_not_called(shape, "regenerate")

func test_enter_tree__not_not_queued__now_not_queued(p= use_parameters([RegularPolygon2D._IS_QUEUED, RegularPolygon2D._BLOCK_QUEUE])):
	var shape : RegularPolygon2D = partial_double(class_script).new()
	shape._queue_status = p

	shape._enter_tree()

	assert_eq(shape._queue_status, RegularPolygon2D._NOT_QUEUED, "Property '_queue_status' should be '_NOT_QUEUED' (0).")

func test_regenerate__holed_shape_without_drawn_arc__ends_equal():
	var shape : RegularPolygon2D = autoqfree(RegularPolygon2D.new())
	shape.vertices_count = 4
	shape.width = 5

	shape.regenerate()

	var polygon := shape.polygon
	assert_almost_eq(polygon[0], polygon[4], Vector2.ONE * 0.01, "The first and last points of the outer shape of the generated polygon.")
	assert_almost_eq(polygon[5], polygon[9], Vector2.ONE * 0.01, "The first and last points of the inner ring of the generated polygon.")

func test_regenerate__holed_shape_with_drawn_arc__ends_not_equal():
	var shape : RegularPolygon2D = autoqfree(RegularPolygon2D.new())
	shape.vertices_count = 4
	shape.width = 5
	shape.drawn_arc = 6

	shape.regenerate()

	var polygon := shape.polygon
	assert_almost_ne(polygon[0], polygon[4], Vector2.ONE * 0.01, "The first and last points of the outer shape of the generated polygon.")
	assert_almost_ne(polygon[5], polygon[9], Vector2.ONE * 0.01, "The first and last points of the inner ring of the generated polygon.")

func test_get_shape_vertices__drawn_arc_PI__no_central_point():
	var expected := PackedVector2Array([Vector2(0, 7.07107), Vector2(-7.07107, 7.07107), Vector2(-7.07107, -7.07107), Vector2(0, -7.07107)])
	var shape : PackedVector2Array

	shape = RegularPolygon2D.get_shape_vertices(4, 10, 0, Vector2.ZERO, PI)

	assert_almost_ne(shape[-1], Vector2.ZERO, Vector2.ONE * 0.01, "The last element of the returned array.")
	# assert_eq(shape.size(), 4, "Size of returned array.")
	assert_almost_eq_deep(shape, expected, Vector2.ONE * 0.001)

func test_get_shape_vertices__false_central_point_when_drawn_arc_is_TAU_or_PI__no_central_point(p = use_parameters([[TAU], [PI], [-PI]])):
	var shape : PackedVector2Array

	shape = RegularPolygon2D.get_shape_vertices(4, 1, 0, Vector2.ZERO, p[0], false)

	assert_almost_ne(shape[-1], Vector2.ZERO, Vector2.ONE * 0.01, "The last element of the returned array.")

func test_get_shape_vertices__false_central_point__last_point_not_ZERO():
	var shape : PackedVector2Array

	shape = RegularPolygon2D.get_shape_vertices(4, 1, 0, Vector2.ZERO, 1, false)

	assert_false(shape[-1].is_equal_approx(Vector2.ZERO), "%s should not equal Vector2.ZERO (0, 0)" % shape[-1])

func test_add_rounded_corners__various_corner_smoothness__array_size_increases_by_that_percentage(p = use_parameters([[1], [2], [3], [10]])):
	var shape := SimplePolygon2D.get_shape_vertices(3)
	var previous_size := shape.size()
	
	RegularPolygon2D.add_rounded_corners(shape, 1, p[0])

	assert_eq(shape.size(), previous_size + previous_size * p[0], "Size of modified array, %s * the original size" % (p[0] + 1))

func test_add_rounded_corners__very_small_corner_size__approximately_equal_vectors():
	var shape := SimplePolygon2D.get_shape_vertices(3)
	
	RegularPolygon2D.add_rounded_corners(shape, 0.01, 2)

	for i in 3:
		var index := i * 3
		assert_almost_eq(shape[index + 1], shape[index], Vector2.ONE * 0.1, "First part of corner of modified array.")
		assert_almost_eq(shape[index + 2], shape[index], Vector2.ONE * 0.1, "Last part of corner of modified array.")

func test_add_hole_to_points__do_not_close_shape__expected_shape():
	const sample_hole_scaler = 0.5
	var shape := PackedVector2Array([Vector2(8.66025, 5), Vector2(-8.66025, 5), Vector2(-1.22465e-15, -10)])
	var expected_shape := PackedVector2Array([Vector2(8.66025, 5), Vector2(-8.66025, 5), Vector2(-1.22465e-15, -10), Vector2(-6.12323e-16, -5), Vector2(-4.33013, 2.5), Vector2(4.33013, 2.5)])

	RegularPolygon2D.add_hole_to_points(shape, sample_hole_scaler, false)

	assert_almost_eq_deep(shape, expected_shape, Vector2.ONE * 0.0001)
	
func test_add_hole_to_points__do_close_shape__expected_shape():
	const sample_hole_scaler = 0.5
	var shape := PackedVector2Array([Vector2(8.66025, 5), Vector2(-8.66025, 5), Vector2(-1.22465e-15, -10)])
	var expected_shape := PackedVector2Array([Vector2(8.66025, 5), Vector2(-8.66025, 5), Vector2(-1.22465e-15, -10), Vector2(8.66025, 5), Vector2(4.33012, 2.5), Vector2(-6.12323e-16, -5), Vector2(-4.33013, 2.5), Vector2(4.33013, 2.5)])

	RegularPolygon2D.add_hole_to_points(shape, sample_hole_scaler, true)

	assert_almost_eq_deep(shape, expected_shape, Vector2.ONE * 0.0001)

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
	var shape : RegularPolygon2D = partial_double(class_script).new()
	shape._queue_status = RegularPolygon2D._BLOCK_QUEUE
	shape.vertices_count = p[0]
	shape.size = p[1]
	shape.width = p[2]
	shape.drawn_arc = p[3]
	shape.corner_size = p[4]
	shape.corner_smoothness = p[5]
	shape._queue_status = RegularPolygon2D._NOT_QUEUED
	var expected := RegularPolygon2D.new()
	autoqfree(expected)
	expected.vertices_count = p[0]
	expected.size = p[1]
	expected.width = p[2]
	expected.drawn_arc = p[3]
	expected.corner_size = p[4]
	expected.corner_smoothness = p[5]
	expected.regenerate()
	shape.polygon = expected.polygon
	expected.offset_rotation += sample_rotation_amount
	expected.size *= sample_scale_amount
	expected.regenerate()

	shape.apply_transformation(sample_rotation_amount, sample_scale_amount, false, false)

	assert_almost_eq_deep(shape.polygon, expected.polygon, Vector2.ONE * 0.001)
	assert_not_called(shape, "regenerate")

func test_apply_transformation__size_change_creates_ring__shape_regenerated() -> void:
	const sample_scale_amount := 2
	var expected_shape := PackedVector2Array([Vector2(14.1421, 14.1421), Vector2(-14.1421, 14.1421), Vector2(-14.1421, -14.1421), Vector2(14.1421, -14.1421), Vector2(14.1421, 14.1421), Vector2(3.53553, 3.53553), Vector2(3.53553, -3.53553), Vector2(-3.53553, -3.53553), Vector2(-3.53553, 3.53553), Vector2(3.53553, 3.53553)])
	var shape := RegularPolygon2D.new()
	shape.vertices_count = 4
	shape.width = 15
	shape.regenerate()
	autoqfree(shape)

	shape.apply_transformation(0, sample_scale_amount, false, false)

	assert_almost_eq_deep(shape.polygon, expected_shape, Vector2.ONE * 0.001)

func test_apply_transformation__size_change_removes_ring__shape_regenerated() -> void:
	const sample_scale_amount := 0.5
	var expected_shape := PackedVector2Array([Vector2(7.07107, 7.07107), Vector2(-7.07107, 7.07107), Vector2(-7.07107, -7.07107), Vector2(7.07107, -7.07107)])
	var shape := RegularPolygon2D.new()
	shape.vertices_count = 4
	shape.size = 20
	shape.width = 15
	shape.regenerate()
	autoqfree(shape)

	shape.apply_transformation(0, sample_scale_amount, false, false)

	assert_almost_eq_deep(shape.polygon, expected_shape, Vector2.ONE * 0.001)

func test_apply_transformation__width_scaled__expected_shape(p=use_parameters(params_transform_shape)):
	const sample_scale_amount := 2.3
	const sample_rotation_amount := 1
	var shape : RegularPolygon2D = partial_double(class_script).new()
	shape._queue_status = RegularPolygon2D._BLOCK_QUEUE
	shape.vertices_count = p[0]
	shape.size = p[1]
	shape.width = p[2]
	shape.drawn_arc = p[3]
	shape.corner_size = p[4]
	shape.corner_smoothness = p[5]
	shape._queue_status = RegularPolygon2D._NOT_QUEUED
	var expected := RegularPolygon2D.new()
	autoqfree(expected)
	expected.vertices_count = p[0]
	expected.size = p[1]
	expected.width = p[2]
	expected.drawn_arc = p[3]
	expected.corner_size = p[4]
	expected.corner_smoothness = p[5]
	expected.regenerate()
	shape.polygon = expected.polygon
	expected.offset_rotation += sample_rotation_amount
	expected.size *= sample_scale_amount
	expected.width *= sample_scale_amount
	expected.regenerate()

	shape.apply_transformation(sample_rotation_amount, sample_scale_amount, true, false)

	assert_almost_eq_deep(shape.polygon, expected.polygon, Vector2.ONE * 0.001)
	assert_not_called(shape, "regenerate")

func test_apply_transformation__corner_size_scaled__expected_shape(p=use_parameters(params_transform_shape)):
	const sample_scale_amount := 2.3
	const sample_rotation_amount := 1
	var shape : RegularPolygon2D = partial_double(class_script).new()
	shape._queue_status = RegularPolygon2D._BLOCK_QUEUE
	shape.vertices_count = p[0]
	shape.size = p[1]
	shape.width = p[2]
	shape.drawn_arc = p[3]
	shape.corner_size = p[4]
	shape.corner_smoothness = p[5]
	shape._queue_status = RegularPolygon2D._NOT_QUEUED
	var expected := RegularPolygon2D.new()
	autoqfree(expected)
	expected.vertices_count = p[0]
	expected.size = p[1]
	expected.width = p[2]
	expected.drawn_arc = p[3]
	expected.corner_size = p[4]
	expected.corner_smoothness = p[5]
	expected.regenerate()
	shape.polygon = expected.polygon
	expected.offset_rotation += sample_rotation_amount
	expected.size *= sample_scale_amount
	expected.corner_size *= sample_scale_amount
	expected.regenerate()

	shape.apply_transformation(sample_rotation_amount, sample_scale_amount, false, true)

	assert_almost_eq_deep(shape.polygon, expected.polygon, Vector2.ONE * 0.001)
	assert_not_called(shape, "regenerate")

func test_apply_transformation__width_and_corner_size_scaled__expected_shape(p=use_parameters(params_transform_shape)):
	const sample_scale_amount := 2.3
	const sample_rotation_amount := 1
	var shape : RegularPolygon2D = partial_double(class_script).new()
	shape._queue_status = RegularPolygon2D._BLOCK_QUEUE
	shape.vertices_count = p[0]
	shape.size = p[1]
	shape.width = p[2]
	shape.drawn_arc = p[3]
	shape.corner_size = p[4]
	shape.corner_smoothness = p[5]
	shape._queue_status = RegularPolygon2D._NOT_QUEUED
	var expected := RegularPolygon2D.new()
	autoqfree(expected)
	expected.vertices_count = p[0]
	expected.size = p[1]
	expected.width = p[2]
	expected.drawn_arc = p[3]
	expected.corner_size = p[4]
	expected.corner_smoothness = p[5]
	expected.regenerate()
	shape.polygon = expected.polygon
	expected.offset_rotation += sample_rotation_amount
	expected.size *= sample_scale_amount
	expected.width *= sample_scale_amount
	expected.corner_size *= sample_scale_amount
	expected.regenerate()

	shape.apply_transformation(sample_rotation_amount, sample_scale_amount, true, true)

	assert_almost_eq_deep(shape.polygon, expected.polygon, Vector2.ONE * 0.001)
	assert_not_called(shape, "regenerate")
