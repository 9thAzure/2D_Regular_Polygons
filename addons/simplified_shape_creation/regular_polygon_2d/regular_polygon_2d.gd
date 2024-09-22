@tool
@icon("res://addons/simplified_shape_creation/regular_polygon_2d/regular_polygon_2d.svg")
class_name RegularPolygon2D
extends Polygon2D

## Node that draws regular shapes, with some complex properties. 
##
## A node that draws regular shapes, with some complex properties.
## It uses methods like [method CanvasItem.draw_colored_polygon] or [method CanvasItem.draw_circle], or use [member Polygon2D.polygon].
## Certain properties with circles will use a 32-sided polygon instead.
## [br][br][b]Note[/b]: If the node is set to use [member Polygon2D.polygon] when it is outside the [SceneTree],
## regeneration will be delayed to when it enters it. Use [method regenerate] to force regeneration.

## The number of vertices in the regular shape. A value of [code]1[/code] creates a circle, and a value of [code]2[/code] creates a line.
## [br][br]Certain properties with circles will use a 32-sided polygon instead.
@export_range(1, 2000, 1) 
var vertices_count : int = 1:
	set(value):
		assert(value > 0, "property 'vertices_count' must be greater than 0")
		vertices_count = value
		if vertices_count == 2 and width > 0:
			polygon = PackedVector2Array()
			return
		queue_regenerate()

## The length from each corner to the center.
@export_range(0.000001, 10, 0.001, "or_greater", "hide_slider")
var size : float = 10:
	set(value):
		assert(value > 0, "property 'size' must be greater than 0");
		size = value
		queue_regenerate()

## The offset rotation of the shape, in degrees.
var offset_rotation_degrees : float = 0:
	set(value):
		offset_rotation = deg_to_rad(value)
	get:
		return rad_to_deg(offset_rotation)

## the offset rotation of the shape, in radians.
@export_range(-360, 360, 0.1, "or_greater", "or_less", "radians") 
var offset_rotation : float = 0:
	set(value):
		offset_rotation = value
		queue_regenerate()

## Transforms [member Polygon2D.polygon], rotating it by [param rotation] radians and scaling it by a factor of [param scaler].
## This method modifies the existing [member Polygon2D.polygon], so is generally faster than changing [member size] and [member offset_rotation].
## This only happens if the transformed shape is congruent to the original. If it is not or [member Polygon2D.polygon] isn't used, the shape is regenerated.
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
	if scale_width:
		width *= scale

	if scale_corner_size:
		corner_size *= scale

	_queue_status = _NOT_QUEUED
	
	if not uses_polygon_member():
		queue_redraw()
		return

	if not scale_width and \
		(width >= size and width < size / scale
		or width < size and width >= size / scale):
		regenerate()
		return
	
	var points_per_corner := 0
	if corner_size > 0:
		points_per_corner = corner_smoothness if corner_smoothness != 0 else corner_smoothness / vertices_count
	points_per_corner += 1
	
	var shape := polygon
	RegularGeometry2D.apply_transformation(shape, rotation, scale, 0 < width and width < size, points_per_corner, scale_width, scale_corner_size)
	polygon = shape


# ? not sure if this is a good name for it and many of the properties under it, they may need changing.
@export_group("complex")

# The default value is -0.001 so that dragging it into positive values is quick.
## Determines the width of the shape. A value of [code]0[/code] outlines the shape with lines, and a value smaller than [code]0[/code] ignores this effect.
## Values greater than [code]0[/code] will have [member Polygon2D.polygon] used,
## and value greater than [member size] also ignores this effect while still using [member Polygon2D.polygon].
## [br][br]If a line is drawn, [method CanvasItem.draw_line] will always be used, with this property corresponding to the [param width] parameter.
@export_range(-0.001, 10, 0.001, "or_greater", "hide_slider")
var width : float = -0.001:
	set(value):
		if Engine.is_editor_hint() and value > 0 and value < 0.01:
			value = 0
		
		if width > 0 and value <= 0:
			width = value
			polygon = PackedVector2Array()
			return

		width = value
		queue_regenerate()

## The arc of the drawn shape, in degrees, cutting off beyond that arc. 
## Values greater than [code]360[/code] or [code]-360[/code] draws a full shape. It starts in the middle of the bottom edge of the shapes. 
## The direction of the arc is clockwise with positive values and counterclockwise with negative values.
## [br][br]For lines, this property rotates the top half of the line.
## [b]Note[/b]: if [member width] is used, this leaves a gap between the 2 lines on the outer angle. Using [member corner_size] fills it in.
## [br][br]A value of [code]0[/code] makes the node not draw anything.
var drawn_arc_degrees : float = 360:
	set(value):
		drawn_arc = deg_to_rad(value)
	get:
		return rad_to_deg(drawn_arc)

## The arc of the drawn shape, in radians, cutting off beyond that arc. 
## Values greater than [constant @GDScript.TAU] or -[constant @GDScript.TAU] draws a full shape. It starts in the middle of the bottom edge of the shapes. 
## The direction of the arc is clockwise with positive values and counterclockwise with negative values.
## [br][br]For lines, this property rotates the top half of the line.
## [b]Note[/b]: if [member width] is used, this leaves a gap between the 2 lines on the outer angle. Using [member corner_size] fills it in.
## [br][br]A value of [code]0[/code] makes the node not draw anything.
@export_range(-360, 360, 0.01, "radians") 
var drawn_arc : float = TAU:
	set(value):
		drawn_arc = value
		queue_regenerate()
		update_configuration_warnings()

## The distance from each vertex along the edge to the point where the rounded corner starts.
## If this value is over half of the edge length, the mid-point of the edge is used instead.
## [br][br]This only has an effect on lines if [member drawn_arc] is also used.
## The maximum possible distance is the ends of the line from the middle.
@export_range(0.0, 5, 0.001, "or_greater", "hide_slider") 
var corner_size : float = 0.0:
	set(value):
		assert(value >= 0, "property 'corner_size' must be greater than or equal to 0")
		corner_size = value
		queue_regenerate()

## How many lines make up each corner. A value of [code]0[/code] will use a value of [code]32[/code] divided by [member vertices_count].
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

## @deprecated
func _pre_redraw() -> void:
	queue_regenerate()

## Queues [method regenerate] for the next process frame. If this method is called multiple times, the shape is only regenerated once.
## [br][br]If this method is called when the node is outside the [SceneTree], regeneration will be delayed to when the node enters the tree.
## Call [method regenerate] directly to force initialization.
func queue_regenerate() -> void:
	if not uses_polygon_member():
		# the setting the 'polygon' property already calls queue_redraw
		queue_redraw()
		return
	
	if _queue_status != _NOT_QUEUED:
		return
	
	_queue_status = _IS_QUEUED
	if not is_inside_tree():
		polygon = PackedVector2Array()
		return

	await get_tree().process_frame
	_queue_status = _NOT_QUEUED
	if not uses_polygon_member():
		return
	regenerate()

func _enter_tree() -> void:
	if _queue_status == _IS_QUEUED and uses_polygon_member():
		regenerate()
	_queue_status = _NOT_QUEUED

func _draw() -> void:
	if uses_polygon_member() or drawn_arc == 0:
		return
	
	if vertices_count == 2:
		var point := _get_vertices(offset_rotation, size)
		var width_value = width if width != 0 else -1
		if not _uses_drawn_arc():
			draw_line(point + offset, -point + offset, color, width_value, antialiased)
			return

		var point2 := _get_vertices(offset_rotation + drawn_arc + PI, size)
		if is_zero_approx(corner_size):
			draw_line(point + offset, offset, color, width_value, antialiased)
			draw_line(point2 + offset, offset, color, width_value, antialiased)
			return
		
		var smoothness := corner_smoothness if corner_smoothness != 0 else 16
		var multiplier := corner_size / size if corner_size <= size else 1.0
		var line := PackedVector2Array()
		line.resize(3 + smoothness)
		line[0] = point + offset
		line[1] = point * multiplier + offset
		line[-2] = point2 * multiplier + offset
		line[-1] = point2 + offset
		var i := 1
		while i < smoothness:
			line[i + 1] = quadratic_bezier_interpolate(line[1], offset, line[-2], i / (smoothness as float))
			i += 1
		draw_polyline(line, color, width_value, antialiased)
		return
		
	if (vertices_count == 4 
		and is_zero_approx(offset_rotation)
		and is_zero_approx(corner_size)
		and (drawn_arc >= TAU or drawn_arc <= -TAU)
		and texture == null
	):
		const sqrt_two_over_two := 0.707106781
		var rect = Rect2(-Vector2.ONE * sqrt_two_over_two * size + offset, Vector2.ONE * sqrt_two_over_two * size * 2)
		if is_zero_approx(width):
			draw_rect(rect, color, false)
			return
		# Using the width param would require having all the checks here also be in the pre_redraw function as well.
		draw_rect(rect, color)
		return
	
	var points : PackedVector2Array
	if vertices_count == 1:
		if (drawn_arc >= TAU or drawn_arc <= -TAU) and texture == null and width < 0:
			draw_circle(offset, size, color)
			return
		points = get_shape_vertices(32, size, offset_rotation, offset, drawn_arc)
	else:
		points = get_shape_vertices(vertices_count, size, offset_rotation, offset, drawn_arc)
	
	if not is_zero_approx(corner_size):
		add_rounded_corners(points, corner_size, corner_smoothness if corner_smoothness != 0 else 32 / vertices_count)

	if is_zero_approx(width):
		points.append(points[0])
		draw_polyline(points, color)
		return
	
	if texture != null:
		var uv_points := uv
		if uv_points.size() != points.size():
			uv_points = points.duplicate()
		
		var uv_scale_x := 1.0 / texture.get_width()
		var uv_scale_y := 1.0 / texture.get_height()
		# The scale doesn't need to be reversed.
		var transform := Transform2D(-texture_rotation, texture_scale, 0, -texture_offset)
		uv_points *= transform
		for i in uv_points.size():
			var uv_point := uv_points[i]
			uv_point.x *= uv_scale_x
			uv_point.y *= uv_scale_y
			uv_points[i] = uv_point
		
		draw_colored_polygon(points, color, uv_points, texture)
		return
	
	draw_colored_polygon(points, color)

## see [method regenerate]
## @deprecated
func regenerate_polygon() -> void:
	regenerate()

## Sets [member Polygon2D.polygon] using the properties of this node. 
## This method can be used when the node is outside the [SceneTree] to force the regeneration of [member Polygon2D.polygon].
func regenerate() -> void:
	_queue_status = _NOT_QUEUED
	if drawn_arc == 0:
		polygon = PackedVector2Array()
		return
	
	var uses_width := width < size
	var uses_drawn_arc := _uses_drawn_arc()
	var points = get_shape_vertices(vertices_count, size, offset_rotation, Vector2.ZERO, drawn_arc, not uses_width)
	if uses_width:
		add_hole_to_points(points, 1 - width / size, not uses_drawn_arc)

	if not is_zero_approx(corner_size):
		add_rounded_corners(points, corner_size, corner_smoothness if corner_smoothness != 0 else 32 / vertices_count, uses_width and not uses_drawn_arc)
	
	polygon = points

func _init(vertices_count : int = 1, size := 10.0, offset_rotation := 0.0, color := Color.WHITE, offset_position := Vector2.ZERO,
	width := -0.001, drawn_arc := TAU, corner_size := 0.0, corner_smoothness := 0):
	if not polygon.is_empty():
		_queue_status = _BLOCK_QUEUE

	if vertices_count != 1:
		self.vertices_count = vertices_count
	if size != 10.0:
		self.size = size
	if offset_rotation != 0.0:
		self.offset_rotation = offset_rotation
	if color != Color.WHITE:
		self.color = color
	if offset_position != Vector2.ZERO:
		self.offset = offset_position
	if width != -0.001:
		self.width = width
	if drawn_arc != TAU:
		self.drawn_arc = drawn_arc
	if corner_size != 0.0:
		self.corner_size = corner_size
	if corner_smoothness != 0:
		self.corner_smoothness = corner_smoothness
	
# func _ready() -> void:
# 	if Engine.is_editor_hint():
# 		var control := preload("res://addons/simplified_shape_creation/gui_handlers/size_rotation_handler.gd").new(self, 2)
# 		add_child(control)

func _get_configuration_warnings() -> PackedStringArray:
	if drawn_arc == 0:
		return ["nothing will be drawn when 'drawn_arc' is 0."]
	return []

## Checks whether the current properties of this node will have it use [member Polygon2d.polygon].
func uses_polygon_member() -> bool:
	return (
		width > 0
		and vertices_count != 2
	)

func _uses_drawn_arc() -> bool:
	return -TAU < drawn_arc and drawn_arc < TAU


## Returns a [PackedVector2Array] with the points for the shape with the specified [param vertices_count].
## [br][br]If [param vertices_count] is [code]1[/code], a value of [code]32[/code] is used instead.
## [param add_central_point] adds [param offset_rotation] at the end of the array. It only has an effect if [param drawn_arc] is used and isn't ±[constant @GDSCript.PI].
## It should be set to false when using [method add_hole_to_points].
## For [param drawn_arc] documentation, see [member drawn_arc].
static func get_shape_vertices(vertices_count : int, size : float = 1, offset_rotation : float = 0.0, offset_position : Vector2 = Vector2.ZERO, 
	drawn_arc : float = TAU, add_central_point := true) -> PackedVector2Array:
	assert(vertices_count >= 1, "param 'vertices_count' must be 1 or greater.")
	assert(size > 0, "param 'size' must be positive.")
	assert(drawn_arc != 0, "param 'drawn_arc' cannot be 0")

	if drawn_arc <= -TAU or TAU <= drawn_arc:
		return SimplePolygon2D.get_shape_vertices(vertices_count, size, offset_rotation, offset_position)
	
	if vertices_count == 1:
		vertices_count = 32
	
	var points := PackedVector2Array()
	var sign := signf(drawn_arc)
	var rotation_spacing := TAU / vertices_count * sign
	var half_rotation_spacing := rotation_spacing / 2
	var original_vertices_count := floori((drawn_arc + half_rotation_spacing) / rotation_spacing)
	var ends_on_vertex := is_equal_approx(drawn_arc + half_rotation_spacing, rotation_spacing * original_vertices_count)
	original_vertices_count += 1
	
	if add_central_point and is_zero_approx(sign * drawn_arc - PI):
		add_central_point = false

	if add_central_point and not ends_on_vertex:
		points.resize(original_vertices_count + 2)
	# if add central point and end on vertex (true true), or don't add point and don't end on vertex (false, false):
	elif add_central_point == ends_on_vertex: 
		points.resize(original_vertices_count + 1)
	else:
		points.resize(original_vertices_count)

	var starting_rotation := -half_rotation_spacing + offset_rotation
	for i in original_vertices_count:
		var rotation := starting_rotation + rotation_spacing * i
		var point := _get_vertices(rotation, size, offset_position)
		points[i] = point
	
	# Setting center point.
	var first_point := points[0]
	var second_point := points[1] if original_vertices_count >= 2 else _get_vertices(starting_rotation + rotation_spacing, size, offset_position)
	var vector_to_second := second_point - first_point
	points[0] = first_point + vector_to_second / 2
	
	if not ends_on_vertex:
		# variable names in formula: P, _, Q, R
		var last_point := points[original_vertices_count - 1]
		var next_point := _get_vertices(starting_rotation + rotation_spacing * original_vertices_count, size, offset_position)
		var edge_slope := next_point - last_point 
		var ending_slope := _get_vertices(drawn_arc + offset_rotation)
		# formula variables: P, Q, S, R
		var scaler := _find_intersection(last_point, edge_slope, offset_position, ending_slope)
		var edge_point := last_point + scaler * edge_slope
		points[original_vertices_count] = edge_point
	
	if add_central_point:
		points[-1] = offset_position
		pass
			
	return points

# gets the vertices for a particular rotation and size, with a positional offset.
static func _get_vertices(rotation : float, size : float = 1, offset : Vector2 = Vector2.ZERO) -> Vector2:
	return Vector2(-sin(rotation), cos(rotation)) * size + offset

# finds the intersection between 2 points and their slopes. The value returned is not the point itself, but a scaler.
# The point would be obtained by (where a = returned value of function): point1 + a * slope1
static func _find_intersection(point1 : Vector2, slope1 : Vector2, point2: Vector2, slope2: Vector2) -> float:
	var numerator := slope2.y * (point2.x - point1.x) - slope2.x * (point2.y - point1.y)
	var devisor := (slope1.x * slope2.y) - (slope1.y * slope2.x)
	assert(devisor != 0, "one or both slopes are 0, or are parallel")
	return numerator / devisor 
	
# Quadratic Bezier curves are use because we have all three required points already. It isn't a perfect circle, but good enough.

## Modifies [param points] so that the shape it represents have rounded corners. 
## The method uses quadratic Bézier curves for the corners (see [method quadratic_bezier_interpolate]).
## [br][br]For [param corner_size] and [param corner_smoothness] documentation, see [member corner_size] and [member corner_smoothness].
## [param is_ringed_shape] is used to indicate that the shape to round is a ring (see [method add_hole_to_points]).
static func add_rounded_corners(points : PackedVector2Array, corner_size : float, corner_smoothness : int, is_ringed_shaped := false) -> void:
	if is_ringed_shaped:
		var functional_length := (points.size() - 2) / 2

		# temp points to have corners rounded to its correct neighbours.
		var temp_point := points[0]
		points[0] = points[-functional_length]
		RegularGeometry2D.add_rounded_corners(points, corner_size, corner_smoothness, functional_length + 2, functional_length)
		points[0] = temp_point

		temp_point = points[-1]
		points[-1] = points[functional_length - 1]
		RegularGeometry2D.add_rounded_corners(points, corner_size, corner_smoothness, 0, functional_length)
		points[-1] = temp_point

		points[functional_length * (corner_smoothness + 1)] = points[0]
		points[functional_length * (corner_smoothness + 1) + 1] = points[-1]
		return
	
	RegularGeometry2D.add_rounded_corners(points, corner_size, corner_smoothness)

# Returns the point at the given [param t] on the Bézier curve with the given [param start], [param end], and single [param control] point.
## [b][color=red]Warning[/color][/b]: This method is not meant to be used outside the class, and will be changed/made private in the future.
## @deprecated
static func quadratic_bezier_interpolate(start : Vector2, control : Vector2, end : Vector2, t : float) -> Vector2:
	return control + (t - 1) ** 2 * (start - control) + t ** 2 * (end - control)

## Appends points, which are [param hole_scaler] times the original [param points], in reverse order from the original.
## [param close_shape] adds the first point to the end, before the procedure.
## [br][br][b]Note[/b]: This method assumes the shape specified in [param points] is centered onto [constant Vector2.ZERO]
static func add_hole_to_points(points : PackedVector2Array, hole_scaler : float, close_shape : bool = true) -> void:
	var original_size := points.size()
	if close_shape:
		original_size += 1
	
	points.resize(original_size * 2)
	if close_shape:
		points[original_size - 1] = points[0]

	for i in original_size:
		points[-i - 1] = points[i] * hole_scaler
	
	if close_shape:
		var slope := (points[original_size - 2] - points[original_size - 1]) / 4194304 # 2^22
		points[original_size - 1] += slope
		points[original_size] += slope

# these functions are for c# interop, as changes to an argument are not transferred.
static func _add_rounded_corners_result(points : PackedVector2Array, corner_size : float, corner_smoothness : int) -> PackedVector2Array:
	add_rounded_corners(points, corner_size, corner_smoothness)
	return points

static func _add_hole_to_points_result(points : PackedVector2Array, hole_scaler : float, close_shape : bool = true) -> PackedVector2Array:
	add_hole_to_points(points, hole_scaler, close_shape)
	return points
