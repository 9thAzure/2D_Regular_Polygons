@tool
@icon("res://addons/complex_shape_creation/regular_collision_polygon_2d/regular_collision_polygon_2d.svg")
class_name RegularCollisionPolygon2D
extends CollisionShape2D

## Node that generates 2d regular collision shapes.
##
## A node with variables for generating 2d regular shapes for collision.
## It creates various shape inheriting [Shape2D] based on the values of its variables and sets it to [member CollisionShape2D.shape].
## [br][br][b]Note[/b]: If properties are set when the node is outside the [SceneTree],
## regeneration will be delayed to when it enters one. Use [method regenerate] to force regeneration.

## The number of vertices in the regular shape. A value of [code]1[/code] creates a circle, and a value of [code]2[/code] creates a line.
## [br][br]Certain properties with circles will use a 32-sided polygon instead.
## [br][br][b]Note[/b]: [member inner_size] affects the values required for circles and lines.
@export_range(1, 2000)
var vertices_count : int = 1:
	set(value):
		assert(value > 0, "property 'vertices_count' must be greater than 0")
		vertices_count = value
		queue_regenerate()

## The length of each corner to the center of the shape.
@export_range(0.000001, 10, 0.001 , "or_greater", "hide_slider")
var size : float = 10:
	set(value):
		assert(value > 0, "value 'size' must be greater than 0")
		size = value
		queue_regenerate()

## The offset rotation of the shape, in degrees.
var offset_rotation_degrees : float = 0:
	set(value):
		offset_rotation = deg_to_rad(value)
	get:
		return rad_to_deg(offset_rotation)

## The offset rotation of the shape, in radians.
@export_range(-360, 360, 0.1, "or_greater", "or_less", "radians")
var offset_rotation : float = 0:
	set(value):
		offset_rotation = value
		queue_regenerate()

## Transforms [member CollisionShape2D.shape], rotating it by [param rotation] radians and scaling it by a factor of [param scaler].
## This method modifies the existing [member CollisionShape2D.shape], so is generally faster than changing [member size]/[member inner_size] and [member offset_rotation].
## This only happens if the transformed shape is congruent to the original, otherwise it is simply regenerated. Certain cases will also cause it to regenerate.
## [br][br][param scale_width] toggles scaling [member width].
## [param scale_corner_size] toggles scaling [member corner_size].
## If these values are [code]false[/code], their respective properties are not altered and the shape is corrected.
## [br][br][b][color=red]Warning[/color][/b]: Currently method does not check if the [member corner_size] value is clamped due to small side lengths.
## If this occurs in the original or transformed shape and [param scale_corner_size] is [code]false[/code], the shape will not be accurate to this node's properties.
func apply_transformation(rotation : float, scale : float, scale_width := true, scale_corner_size := true) -> void:
	assert(scale > 0, "param 'scale' should be positive.")
	_queue_status = _BLOCK_QUEUE
	offset_rotation += rotation
	size *= scale
	inner_size *= scale
	if scale_width:
		width *= scale

	if scale_corner_size:
		corner_size *= scale

	_queue_status = _NOT_QUEUED
	
	if not scale_width and \
		(width >= size and width < size / scale
		or width < size and width >= size / scale):
		regenerate()
		return
	
	var is_star_shape := not is_zero_approx(inner_size)
	var is_line := is_star_shape and vertices_count == 1 or not is_star_shape and vertices_count == 2
	var has_rounded_corners := not is_zero_approx(corner_size)
	var points_per_corner := 0
	if has_rounded_corners:
		points_per_corner = corner_smoothness if corner_smoothness != 0 else corner_smoothness / vertices_count 
	points_per_corner += 1

	
	# cares about scale_width
	# unaffected by corner_size
	if shape is CircleShape2D:
		shape.radius *= scale
		return

	# cares about scale_width, corner_size, everything that isn't scale
	if shape is RectangleShape2D:
		if not is_zero_approx(rotation):
			regenerate()
			return

		if not scale_width and is_line:
			if is_zero_approx(sin(offset_rotation)):
				shape.size.y *= scale
				return
			shape.size.x *= scale
			return
		shape.size *= scale
		return
	
	# scale_width can't even effect this
	if shape is SegmentShape2D:
		var transform := Transform2D(-rotation, Vector2.ONE * scale, 0, Vector2.ZERO)
		shape.a *= transform
		shape.b *= transform
		return
	
	if shape is ConvexPolygonShape2D:
		var points : PackedVector2Array = shape.points
		if not scale_width and is_line:
			assert(points.size() == 4)
			var slope1 := (points[0] - (points[0] - points[1]) / 2) * (scale - 1)
			var slope2 := (points[3] - (points[0] - points[1]) / 2) * (scale - 1)
			var transform := Transform2D(-rotation, Vector2.ONE, 0, Vector2.ZERO)
			points[0] = (points[0] + slope1) * transform
			points[1] = (points[1] + slope1) * transform
			points[2] = (points[2] + slope2) * transform
			points[3] = (points[3] + slope2) * transform
			shape.points = points
			return

		RegularGeometry2D.apply_transformation(points, rotation, scale, 0 < width and width < size, points_per_corner, scale_width, scale_corner_size)
		shape.points = points
		return

	if not shape is ConcavePolygonShape2D:
		printerr("unexpected shape found: (%s)" % shape)
		return

	# requires special care for scale if it forms a line.
	var segments : PackedVector2Array = shape.segments
	if is_line:
		if is_zero_approx(width):
			if scale_corner_size and has_rounded_corners:
				RegularGeometry2D.apply_transformation(segments, rotation, scale)
				shape.segments = segments
				return 
			
			segments[0] *= scale
			segments[-1] *= scale
			RegularGeometry2D.apply_transformation(segments, rotation, 1)
			shape.segments = segments
			return

		
		if scale_width and (scale_corner_size or not has_rounded_corners):
			RegularGeometry2D.apply_transformation(segments, rotation, scale)
			shape.segments = segments
			return 
			
		# TODO: Should be possible, but requires modification of apply_transformation that I don't want to do.
		if scale_width != scale_corner_size and has_rounded_corners:
			regenerate()
			return

		RegularGeometry2D.apply_transformation(segments, rotation, 1)

		# extend segments
		if not has_rounded_corners:
			# point 1
			var slope := (segments[0] - segments[1]) * (scale - 1)
			var point := segments[0] + slope
			segments[0] = point
			segments[7] = point

			point = segments[5] + slope
			segments[5] = point
			segments[6] = point

			# point 2
			slope = (segments[9] - segments[8]) * (scale - 1)
			point = segments[9] + slope
			segments[9] = point
			segments[10] = point

			point = segments[11] + slope
			segments[11] = point
			segments[12] = point
		else:
			# point 1
			var slope := (segments[0] - (segments[-1] - segments[-2]) / 2) * (scale - 1)
			var point := segments[0] + slope
			segments[0] = point
			segments[-1] = point

			point = segments[-2] + slope
			segments[-2] = point
			segments[-3] = point

			# point 2
			var index := segments.size() / 2
			slope = (segments[index] - (segments[index - 1] - segments[index - 2]) / 2) * (scale - 1)
			point = segments[index] + slope
			segments[index] = point
			segments[index - 1] = point

			point = segments[index - 2] + slope
			segments[index - 2] = point
			segments[index - 3] = point

		shape.segments = segments
		return
	
	var is_ringed_shape := 0 < width and width < size
	var offset_points := _uses_drawn_arc() and is_ringed_shape
	# TODO: Again, I don't want to change apply_transformation to make this work.
	if is_ringed_shape and not _uses_drawn_arc():
		regenerate()
		return

	var segment_size := segments.size()
	for i in segment_size / 2 - 1:
		segments[i + 1] = segments[i * 2 + 1]
	segments.resize(segment_size / 2)

	if offset_points:
		var temp := segments[-1]
		for i in segments.size() - 1:
			segments[i - 1] = segments[i]
		segments[-2] = temp

	RegularGeometry2D.apply_transformation(segments, rotation, scale, is_ringed_shape, points_per_corner, scale_width, scale_corner_size)

	if offset_points:
		var temp := segments[0]
		for i in segments.size() - 1:
			segments[-i] = segments[-i - 1] 
		segments[1] = temp

	segments.resize(segment_size)
	segments[-1] = segments[0]
	for i in segment_size / 2 - 1:
		var point := segments[segment_size / 2 - i - 1]
		segments[-i * 2 - 2] = point
		segments[-i * 2 - 3] = point

	shape.segments = segments

@export_group("complex")

## The length of the inner vertices between each normal vertices to the center of the shape. If set to [code]0[/code], it is ignored.
## [br][br]If used, [member vertices_count] must be set to [code]1[/code] to generate lines, and circles cannot be generated.
## It determines the length of the bottom segment of the line.
@export_range(0, 10, 0.001, "or_greater", "hide_slider")
var inner_size : float = 0.0:
	set(value):
		assert(value >= 0, "property 'inner_size' must be greater than 0");
		inner_size = value
		queue_regenerate()

## Determines the width of the shape. It only has an effect with values greater than [code]0[/code].
## [br][br][b]Note[/b]: using this property with lines may not produce the same shape as [RegularPolygon2D].
@export_range(0, 10, 0.001, "or_greater", "hide_slider") 
var width : float = 0:
	set(value):
		width = value
		queue_regenerate()

## The arc of the drawn shape, in degrees, cutting off beyond that arc. 
## Values greater than [code]360[/code] or smaller than [code]-360[/code] draws a full shape. It starts in the middle of the base of the shapes. 
## The direction of the arc is clockwise with positive values and counterclockwise with negative values.
## [br][br]For lines, this property rotates the top half of the line.
## [b]Note[/b]: if [member width] is used, this leaves a gap between the 2 lines on the outer angle. Using [member corner_size] fills it in.
## [br][br]A value of [code]0[/code] makes the node not change [member CollisionShape2D.shape].
var drawn_arc_degrees : float = 360:
	set(value):
		drawn_arc = deg_to_rad(value)
	get:
		return rad_to_deg(drawn_arc)

## The arc of the drawn shape, in radians, cutting off beyond that arc. 
## Values greater than [constant @GDScript.TAU] or smaller than -[constant @GDScript.TAU] draws a full shape. It starts in the middle of the base of the shapes. 
## The direction of the arc is clockwise with positive values and counterclockwise with negative values.
## [br][br]For lines, this property rotates the top half of the line.
## [b]Note[/b]: if [member width] is used, this leaves a gap between the 2 lines on the outer angle. Using [member corner_size] fills it in.
## [br][br]A value of [code]0[/code] makes the node not change [member CollisionShape2D.shape].
@export_range(-360, 360, 0.1, "radians") 
var drawn_arc : float = TAU:
	set(value):
		drawn_arc = value
		queue_regenerate()
		update_configuration_warnings()

## The distance from each vertex along the edge to the point where the rounded corner starts.
## If this value is over half of the edge length, the mid-point of the edge is used instead.
## [br][br]This only has an effect on lines if [member drawn_arc] is also used.
## The maximum possible distance is the ends of the line from the middle.
@export_range(0, 5, 0.001, "or_greater", "hide_slider")
var corner_size : float = 0.0:
	set(value):
		assert(value >= 0, "property 'corner_size' must be greater than or equal to 0")
		corner_size = value
		queue_regenerate()

## How many lines make up the corner. A value of [code]0[/code] will use a value of [code]32[/code] divided by [member vertices_count].
## This only has an effect if [member corner_size] is used.
@export_range(0, 8, 1, "or_greater") 
var corner_smoothness : int = 0:
	set(value):
		assert(value >= 0, "property 'corner_smoothness' must be greater than or equal to 0")
		corner_smoothness = value
		queue_regenerate()

# "_BLOCK_QUEUE" is used by _init to prevent regeneration of the shape when it is already set by PackedScene.instantiate().
const _NOT_QUEUED = 0
const _IS_QUEUED = 1
const _BLOCK_QUEUE = 2

var _queue_status : int = _NOT_QUEUED 

## Queues [method regenerate] for the next process frame. If this method is called multiple times, the shape is only regenerated once.
## [br][br]If this method is called when the node is outside the [SceneTree], regeneration will be delayed to when the node enters the tree.
## Call [method regenerate] directly to force initialization.
func queue_regenerate() -> void:
	if _queue_status != _NOT_QUEUED:
		return
	
	_queue_status = _IS_QUEUED
	if not is_inside_tree():
		return
	
	await get_tree().process_frame
	# __is_queued = false # regenerate already sets this variable to false.
	regenerate()

func _enter_tree() -> void:
	if _queue_status == _IS_QUEUED:
		regenerate()
	_queue_status = _NOT_QUEUED

## Regenerates the [member CollisionShape2D.shape] using the properties of this node.
## [br][br]The value of [member Shape2D.custom_solver_bias] of the new [Shape2D] will be the same a the previous, if [member shape] isn't [value]null[/value].
func regenerate() -> void:
	_queue_status = _NOT_QUEUED
	
	if drawn_arc == 0:
		return
	
	var uses_inner_size := inner_size > 0

	if vertices_count == 2 and not uses_inner_size or vertices_count == 1 and uses_inner_size:
		var point1 := SimplePolygon2D._get_vertices(offset_rotation) * size
		var point2 := -point1
		if uses_inner_size:
			point1 *= inner_size / size

		if drawn_arc <= -TAU or drawn_arc >= TAU:
			if width <= 0:
				var line := SegmentShape2D.new()
				line.a = point1
				line.b = point2
				_set_shape(line)
				return
			
			if not uses_inner_size:
				if is_zero_approx(point1.x):
					var rect_line := RectangleShape2D.new()
					rect_line.size.y = size * 2
					rect_line.size.x = width
					_set_shape(rect_line)
					return

				if is_zero_approx(point1.y):
					var rect_line := RectangleShape2D.new()
					rect_line.size.y = width
					rect_line.size.x = size * 2
					_set_shape(rect_line)
					return
			
			var line := ConvexPolygonShape2D.new()
			var array := PackedVector2Array()
			array.resize(4)
			var tangent := Vector2(point1.y, -point1.x).normalized() * width / 2
			array[0] = point1 - tangent
			array[1] = point1 + tangent
			array[2] = point2 + tangent
			array[3] = point2 - tangent
			line.points = array
			_set_shape(line)
			return
		
		point2 = SimplePolygon2D._get_vertices(offset_rotation + drawn_arc + PI) * size
		var lines := ConcavePolygonShape2D.new()
		if is_zero_approx(corner_size):
			var array := PackedVector2Array()
			array.resize(4)
			array[0] = point1
			array[1] = Vector2.ZERO
			array[2] = Vector2.ZERO
			array[3] = point2
			if width > 0:
				widen_multiline(array, width)
			lines.segments = array
			_set_shape(lines)
			return
		
		if is_equal_approx(PI, abs(drawn_arc)):
			var array := PackedVector2Array()
			array.resize(2)
			array[0] = point2
			array[1] = Vector2.ZERO
			if width > 0:
				widen_polyline(array, width, false)
			lines.segments = array
			_set_shape(lines)
			return
		
		var smoothness := corner_smoothness if corner_smoothness != 0 else 16
		var multiplier1 := corner_size / size if corner_size < size else 0.999999
		var multiplier2 := multiplier1
		if uses_inner_size:
			multiplier1 = corner_size / inner_size if corner_size < inner_size else 0.999999

		var array := PackedVector2Array()
		array.resize((smoothness + 2) * 2)
		array[0] = point1
		array[1] = point1 * multiplier1
		array[-2] = point2 * multiplier2
		array[-1] = point2
		var i := 1
		while i <= smoothness:
			array[i * 2] = array[i * 2 - 1]
			array[i * 2 + 1] = RegularPolygon2D.quadratic_bezier_interpolate(array[1], Vector2.ZERO, array[-2], i / (smoothness as float))
			i += 1
		if width > 0:
			widen_polyline(array, width, true)
		lines.segments = array
		_set_shape(lines)
		return
	
	var uses_rounded_corners := not is_zero_approx(corner_size)
	var uses_width := width > 0 and width < size
	var uses_drawn_arc := -TAU < drawn_arc and drawn_arc < TAU
	if uses_width:
		var polygon := ConcavePolygonShape2D.new()
		var points : PackedVector2Array
		if uses_inner_size:
			points = StarPolygon2D.get_star_vertices(vertices_count, size, inner_size, offset_rotation, Vector2.ZERO, drawn_arc, not uses_width)
		else:	
			points = RegularPolygon2D.get_shape_vertices(vertices_count, size, offset_rotation, Vector2.ZERO, drawn_arc, not uses_width)
		
		RegularPolygon2D.add_hole_to_points(points, 1 - width / size, not uses_drawn_arc)

		if not is_zero_approx(corner_size):
			RegularPolygon2D.add_rounded_corners(points, corner_size, corner_smoothness if corner_smoothness != 0 else 32 / vertices_count, uses_width and not uses_drawn_arc)
	
		var segments := PackedVector2Array()
		var original_size := points.size()
		var modified_size := original_size
		var offset := 0
		var ignored_i := -1
		if not uses_drawn_arc:
			ignored_i = original_size / 2 - 1
			modified_size -= 2

		segments.resize(modified_size * 2)
		for i in modified_size:
			if i == ignored_i:
				if i + 1 >= original_size:
					break
				offset += 1
			
			segments[(modified_size - i) * 2 - 1] = points[original_size - i - 1 - offset]
			segments[(modified_size - i) * 2 - 2] = points[original_size - i - 2 - offset]
		
		polygon.segments = segments 
		_set_shape(polygon)
		return
	
	var vertices := vertices_count
	if vertices_count == 1:
		if drawn_arc >= TAU or drawn_arc <= -TAU:
			var circle := CircleShape2D.new()
			circle.radius = size
			_set_shape(circle)
			return
		vertices = 32
	
	if vertices_count == 4 and not uses_inner_size and is_zero_approx(offset_rotation) and not uses_rounded_corners and not uses_drawn_arc:
		const sqrt_two_over_two := 0.707106781
		var square := RectangleShape2D.new()
		square.size = size / sqrt_two_over_two * Vector2.ONE
		_set_shape(square)
		return
	
	var points : PackedVector2Array
	if uses_inner_size:
		points = StarPolygon2D.get_star_vertices(vertices, size, inner_size, offset_rotation, Vector2.ZERO, drawn_arc)
	else:
		points = RegularPolygon2D.get_shape_vertices(vertices, size, offset_rotation, Vector2.ZERO, drawn_arc)

	if uses_rounded_corners:
		RegularPolygon2D.add_rounded_corners(points, corner_size, corner_smoothness if corner_smoothness != 0 else 32 / vertices)
	
	if uses_drawn_arc and (drawn_arc > PI or drawn_arc < -PI) or uses_inner_size and vertices_count > 2:
		var lines := ConcavePolygonShape2D.new()
		lines.segments = convert_to_line_segments(points)
		_set_shape(lines)
		return

	var polygon := ConvexPolygonShape2D.new()
	polygon.points = points
	_set_shape(polygon)

func _set_shape(new_shape : Shape2D) -> void:
	if shape != null:
		new_shape.custom_solver_bias = shape.custom_solver_bias
	shape = new_shape

func _uses_drawn_arc() -> bool:
	return -TAU < drawn_arc and drawn_arc < TAU

func _init(vertices_count := 1, size := 10.0, offset_rotation := 0.0, width := 0.0, drawn_arc := TAU, corner_size := 0.0, corner_smoothness : int = 0):
	if shape != null:
		_queue_status = _BLOCK_QUEUE

	if vertices_count != 1:
		self.vertices_count = vertices_count
	if size != 10.0:
		self.size = size
	if offset_rotation != 0.0:
		self.offset_rotation = offset_rotation
	if width != 0.0:
		self.width = width
	if drawn_arc != 360.0:
		self.drawn_arc = drawn_arc
	if corner_size != 0.0:
		self.corner_size = corner_size
	if corner_smoothness != 0:
		self.corner_smoothness = corner_smoothness

func _get_configuration_warnings() -> PackedStringArray:
	if drawn_arc == 0:
		return ["Collision shapes will not be regenerated when 'drawn_arc' is 0."]
	return []

## Modifies and returns [param points] with the identical shape represented with line segments.
static func convert_to_line_segments(points : PackedVector2Array) -> PackedVector2Array:
	var original_size := points.size()
	points.resize(original_size * 2)
	
	for i in original_size:
		var index := original_size - i - 1
		var point := points[index]

		points[index * 2] = point
		points[index * 2 - 1] = point

	return points

## Modifies [param segments] to form an outline of the interconnected segments with the given [param width].
## [param join_perimeter] controls whether the function should extend (or shorten) line segments to form a properly closed shape.
## For disconnected segments, use [method widen_polyline].
## [br][br][param segments] should contain pairs of points for each segment (see [property ConcavePolygonShape2D.segments]).
static func widen_polyline(segments : PackedVector2Array, width : float, join_perimeter : bool) -> void:
	assert(segments.size() & 1 == 0, "parameter 'segments' should be an even size (was %s)." % segments.size())
	var original_size := segments.size()
	var size := original_size * 2 + 4
	segments.resize(size)

	var previous_slope : Vector2
	for i in original_size / 2:
		var point1 := segments[i * 2]
		var point2 := segments[i * 2 + 1]
		var slope := point2 - point1 
		var tangent := Vector2(slope.y, -slope.x).normalized() * width / 2

		segments[i * 2] = point1 + tangent
		segments[i * -2 - 3] = point1 - tangent

		segments[i * 2 + 1] = point2 + tangent
		segments[i * -2 - 4] = point2 - tangent

		if join_perimeter and i != 0:
			var previous_point := segments[i * 2 - 1]
			segments[i * 2] += slope * RegularPolygon2D._find_intersection(point1 + tangent, slope, previous_point, previous_slope)
			segments[i * 2 - 1] = segments[i * 2]

			previous_point = segments[i * -2 - 2]
			segments[i * -2 - 3] += slope * RegularPolygon2D._find_intersection(point1 - tangent, slope, previous_point, previous_slope)
			segments[i * -2 - 2] = segments[i * -2 - 3]
		
		previous_slope = slope
	
	segments[-1] = segments[0]
	segments[-2] = segments[-3]
	segments[original_size] = segments[original_size - 1]
	segments[original_size + 1] = segments[original_size + 2]

## modifies [param segments] to to form the outlines of every disconnected segment with the given [param width].
## For interconnected segments, use [method widen_polyline].
## [br][br][param segments] should contain pairs of points for each segment (see [property ConcavePolygonShape2D.segments]),
static func widen_multiline(segments : PackedVector2Array, width : float) -> void:
	var original_size := segments.size()
	segments.resize(original_size * 4)

	for i in original_size / 2:
		var index := original_size / 2 - i - 1

		var point1 := segments[index * 2]
		var point2 := segments[index * 2 + 1]
		var slope := point2 - point1
		var tangent := Vector2(slope.y, -slope.x).normalized() * width / 2

		segments[index * 8 + 7] = point1 + tangent
		segments[index * 8    ] = point1 + tangent

		segments[index * 8 + 1] = point2 + tangent
		segments[index * 8 + 2] = point2 + tangent

		segments[index * 8 + 3] = point2 - tangent
		segments[index * 8 + 4] = point2 - tangent

		segments[index * 8 + 5] = point1 - tangent
		segments[index * 8 + 6] = point1 - tangent

# functions for c# interop.
static func _widen_polyline_result(segments : PackedVector2Array, width : float, join_perimeter : bool) -> PackedVector2Array:
	widen_polyline(segments, width, join_perimeter)
	return segments

static func _widen_multiline_result(segments : PackedVector2Array, width : float) -> PackedVector2Array:
	widen_multiline(segments, width)
	return segments
