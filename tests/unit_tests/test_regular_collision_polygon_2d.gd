extends GutTest

var class_script := preload("res://addons/2d_regular_polygons/regular_collision_polygon_2d/regular_collision_polygon_2d.gd")

func before_each():
	ignore_method_when_doubling(class_script, "_init")

func test_init__filled_params__assigned_to_vars():
	var shape : RegularCollisionPolygon2D

	shape = autoqfree(RegularCollisionPolygon2D.new(5, 5.0, 1.0, 1.0, 1.0, 1.0, 1))

	assert_eq(shape.vertices_count, 5)
	assert_eq(shape.size, 5.0)
	assert_eq(shape.offset_rotation, 1.0)
	assert_eq(shape.width, 1.0)
	assert_eq(shape.drawn_arc, 1.0)
	assert_eq(shape.corner_size, 1.0)
	assert_eq(shape.corner_smoothness, 1)

func test_enter_tree__shape_filled__regenerate_not_called():
	var shape : RegularCollisionPolygon2D = partial_double(class_script).new() 
	stub(shape, "regenerate").to_do_nothing()
	shape.shape = RectangleShape2D.new()
	shape._is_queued = true

	shape._enter_tree()

	assert_not_called(shape, "regenerate")
	assert_false(shape._is_queued)

func test_queue_regenerate__shape_filled_outside_tree__shape_null():
	var shape : RegularCollisionPolygon2D = autoqfree(RegularCollisionPolygon2D.new())
	shape.shape = RectangleShape2D.new()
	shape._is_queued = false

	shape.queue_regenerate()

	assert_null(shape.shape)

func test_queue_regenerate__in_tree__delayed_shape_filled():
	var shape : RegularCollisionPolygon2D = partial_double(class_script).new()
	shape._is_queued = false
	stub(shape, "_enter_tree").to_do_nothing()
	add_child(shape)

	shape.queue_regenerate()

	assert_null(shape.shape, "shape should not be instantly set.")
	await wait_for_signal(get_tree().process_frame, 10)
	await wait_frames(2)
	assert_not_null(shape.shape, "shape should be set at this point.")

func test_regenerate__vertices_count_2__shape_segment_shape():
	var shape : RegularCollisionPolygon2D = autoqfree(RegularCollisionPolygon2D.new())
	shape.vertices_count = 2

	shape.regenerate()

	assert_true(shape.shape is SegmentShape2D, "property shape should be SegmentShape2D")

func test_regenerate__uses_width__shape_concave_shape():
	var shape : RegularCollisionPolygon2D = autoqfree(RegularCollisionPolygon2D.new())
	shape.width = 5

	shape.regenerate()

	assert_true(shape.shape is ConcavePolygonShape2D, "property shape should be ConcavePolygonShape2D")

func test_regenerate__vertices_count_4__shape_rectangle_shape():
	var shape : RegularCollisionPolygon2D = autoqfree(RegularCollisionPolygon2D.new())
	shape.vertices_count = 4

	shape.regenerate()

	assert_true(shape.shape is RectangleShape2D, "property shape should be RectangleShape2D")
