@tool
@icon("res://addons/complex_shape_creation/star_polygon_2d/star_polygon_2d.svg")
extends Polygon2D
class_name StarPolygon2D

## Node that draws a star, with complex properties.
##
## A node that draws star, with complex properties.
## It uses [method CanvasItem.draw_colored_polygon], [method CanvasItem.draw_polyline], or [member Polygon2D.polygon]
## [br][br][b]Note[/b]: If the node is set to use [member Polygon2D.polygon] when it is outside the [SceneTree],
## regeneration will be delayed to when it enters it. Use [method regenerate] to force regeneration.

## The number of points the star has.
## [br][br]If set to [code]1[/code], a line is drawn.
var vertices_count : int = 5:
	set(value):
		assert(value > 0, "property 'vertices_count' must be greater than 0")
		vertices_count = value
		if vertices_count == 1 and width > 0:
			polygon = PackedVector2Array()
			return
		queue_regenerate()

## see [member vertices_count]
## @deprecated
@export_range(1, 2000)
var point_count : int = 5:
	set(value):
		vertices_count = value
	get:
		return vertices_count
		
## The length of each point to the center of the star.
## [br][br]For lines, it determines the length of the top part.
@export_range(0.000001, 10, 0.001, "or_greater", "hide_slider")
var size : float = 10.0:
	set(value):
		assert(value > 0, "property 'size' must be greater than 0");
		size = value
		queue_regenerate()

## The length of the inner vertices to the center of the star.
## [br][br]For lines, it determines the length of the bottom part.
@export_range(0.000001, 10, 0.001, "or_greater", "hide_slider")
var inner_size : float = 5.0:
	set(value):
		assert(value > 0, "property 'inner_size' must be greater than 0");
		inner_size = value
		queue_regenerate()

## The offset rotation of the star, in degrees.
var offset_rotation_degrees : float = 0:
	set(value):
		offset_rotation = deg_to_rad(value)
	get:
		return rad_to_deg(offset_rotation)

## the offset rotation of the star, in radians.
@export_range(-360, 360, 0.1, "or_greater", "or_less", "radians") 
var offset_rotation : float = 0:
	set(value):
		offset_rotation = value
		queue_regenerate()

## Transforms [member Polygon2D.polygon], rotating it by [param rotation] radians and scaling it by a factor of [param scaler].
## This method modifies the existing [member Polygon2D.polygon], so is generally faster than changing [member size]/[member inner_size] and [member offset_rotation].
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
	inner_size *= scale
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

@export_group("complex")

# The default value is -0.001 so that dragging it into positive values is quick.
## Determines the width of the star. A value of [code]0[/code] outlines the star with lines, and a value smaller than [code]0[/code] ignores this effect.
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

## The arc of the drawn star, in degrees, cutting off beyond that arc. 
## Values greater than [code]360[/code] or [code]-360[/code] draws a full star. It starts at the top point.
## The direction of the arc is clockwise with positive values and counterclockwise with negative values.
## [br][br]For lines, this property rotates the top half of the line.
## [b]Note[/b]: if [member width] is used, this leaves a gap between the 2 lines on the outer angle. Using [member corner_size] fills it in.
## [br][br]A value of [code]0[/code] makes the node not draw anything.
var drawn_arc_degrees : float = 360:
	set(value):
		drawn_arc = deg_to_rad(value)
	get:
		return rad_to_deg(drawn_arc)

## The arc of the drawn star, in radians, cutting off beyond that arc. 
## Values greater than [constant @GDScript.TAU] or -[constant @GDScript.TAU] draws a full star. It starts at the top point
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

## Sets [member inner_size] such that the angle formed by each point is equivalent to [param angle], in radians.
func set_point_angle(angle : float) -> void:
	assert(0 < angle and angle < TAU, "param 'angle' must be between 0 and TAU")
	angle /= 2
	inner_size = size * sin(angle / (sin(PI - angle - TAU / vertices_count / 2)))

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

func _draw():
	if uses_polygon_member() or drawn_arc == 0:
		return
	
	if vertices_count == 1:
		var point := -_get_vertices(offset_rotation + drawn_arc, size)
		var width_value = width if width != 0 else -1
		if drawn_arc <= -TAU or drawn_arc >= TAU:
			draw_line(point + offset, -point * inner_size / size + offset, color, width_value, antialiased)
			return
		
		var point2 := _get_vertices(offset_rotation, inner_size)
		if is_zero_approx(corner_size):
			draw_line(point + offset, offset, color, width_value, antialiased)
			draw_line(point2 + offset, offset, color, width_value, antialiased)
			return
		
		var smoothness := corner_smoothness if corner_smoothness != 0 else 16
		var multiplier1 := corner_size / size if corner_size <= size else 1.0
		var multiplier2 := corner_size / inner_size if corner_size <= inner_size else 1.0
		var line := PackedVector2Array()
		line.resize(3 + smoothness)
		line[0] = point + offset
		line[1] = point * multiplier1 + offset
		line[-2] = point2 * multiplier2 + offset
		line[-1] = point2 + offset
		var i := 1
		while i < smoothness:
			line[i + 1] = RegularPolygon2D.quadratic_bezier_interpolate(line[1], offset, line[-2], i / (smoothness as float))
			i += 1
		draw_polyline(line, color, width_value, antialiased)
		return
	
	var points := get_star_vertices(vertices_count, size, inner_size, offset_rotation, offset, drawn_arc)

	if not is_zero_approx(corner_size):
		RegularPolygon2D.add_rounded_corners(points, corner_size, corner_smoothness if corner_smoothness != 0 else 32 / vertices_count)

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
	draw_colored_polygon(points, color);
	
## see [method regenerate].
## @deprecated
func regenerate_polygon() -> void:
	regenerate()

## Sets [member Polygon2D.polygon] using the properties of this node. 
## This method can be used when the node is outside the [SceneTree] to force this, and ignores the result of [method uses_polygon_member].
func regenerate() -> void:
	_queue_status = _NOT_QUEUED
	if drawn_arc == 0:
		polygon = PackedVector2Array()
		return
	
	var uses_width := width < size
	var uses_drawn_arc := -TAU < drawn_arc and drawn_arc < TAU
	var points = StarPolygon2D.get_star_vertices(vertices_count, size, inner_size, offset_rotation, Vector2.ZERO, drawn_arc, not uses_width)
	if uses_width:
		RegularPolygon2D.add_hole_to_points(points, 1 - width / size, not uses_drawn_arc)

	if not is_zero_approx(corner_size):
		RegularPolygon2D.add_rounded_corners(points, corner_size, corner_smoothness if corner_smoothness != 0 else 32 / vertices_count, uses_width and not uses_drawn_arc)
	
	polygon = points
	
func _init(vertices_count : int = 1, size := 10.0, inner_size := 5.0, offset_rotation := 0.0, color := Color.WHITE, offset_position := Vector2.ZERO,
	width := -0.001, drawn_arc := TAU, corner_size := 0.0, corner_smoothness := 0):
	if not polygon.is_empty():
		_queue_status = _BLOCK_QUEUE

	if vertices_count != 1:
		self.vertices_count = vertices_count
	if size != 10.0:
		self.size = size
	if inner_size != 5.0:
		self.inner_size = inner_size
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

func _get_configuration_warnings() -> PackedStringArray:
	if drawn_arc == 0:
		return ["Nothing will be drawn when 'drawn_arc' is 0."]
	return []

## Checks whether the current properties of this node will have it use [member Polygon2d.polygon].
func uses_polygon_member() -> bool:
	return (
		width > 0
		and vertices_count != 1
	)

## Returns a [PackedVector2Array] with points for forming the specified star.
## [br][br][param add_central_point] adds [param offset_rotation] at the end of the array. 
## It only has an effect if [param drawn_arc] is used and isn't ±[constant @GDSCript.PI].
## It should be set to false when using [method RegularPolygon2D.add_hole_to_points].
static func get_star_vertices(vertices_count : int, size : float, inner_size : float, offset_rotation := 0.0, offset_position := Vector2.ZERO,
	drawn_arc := TAU, add_central_point := true) -> PackedVector2Array:
	assert(vertices_count > 1, "param 'vertices_count' must be greater than 1")
	assert(size > 0, "param 'size' must be greater than 0")
	assert(inner_size > 0, "param 'inner_size' must be greater than 0")
	assert(drawn_arc != 0, "param 'drawn_arc' cannot be 0")
	
	var points := PackedVector2Array()
	offset_rotation += PI
	if drawn_arc >= TAU or drawn_arc <= -TAU:
		points.resize(vertices_count * 2)
		var current_rotation := offset_rotation
		var rotation_spacing := TAU / vertices_count / 2
		for i in vertices_count:	
			points[i * 2] = Vector2(-sin(current_rotation), cos(current_rotation)) * size + offset_position
			current_rotation += rotation_spacing
			points[i * 2 + 1] = Vector2(-sin(current_rotation), cos(current_rotation)) * inner_size + offset_position
			current_rotation += rotation_spacing
		return points
	
	var sign := signf(drawn_arc)
	var rotation_spacing := TAU / vertices_count * sign
	var half_rotation_spacing := rotation_spacing / 2
	var original_vertices_count := floori(drawn_arc / half_rotation_spacing)
	var ends_on_vertex := is_equal_approx(drawn_arc, original_vertices_count * half_rotation_spacing)
	original_vertices_count += 1

	if add_central_point and is_zero_approx(sign * drawn_arc - PI):
		add_central_point = false

	# print(original_vertices_count)
	if add_central_point and not ends_on_vertex:
		# print("+2")
		points.resize(original_vertices_count + 2)
	elif add_central_point == ends_on_vertex:
		# print("+1")
		points.resize(original_vertices_count + 1)
	else:
		points.resize(original_vertices_count)

	var max_i := original_vertices_count / 2
	for i in max_i:
		var rotation := rotation_spacing * i + offset_rotation
		points[2 * i] = _get_vertices(rotation, size, offset_position)
		points[2 * i + 1] = _get_vertices(rotation + half_rotation_spacing, inner_size, offset_position)
	
	if original_vertices_count & 1 == 1:
		points[original_vertices_count - 1] = _get_vertices((original_vertices_count - 1) * half_rotation_spacing + offset_rotation, size, offset_position)
	
	if not ends_on_vertex:
		var last_point := points[original_vertices_count - 1]
		var next_point : Vector2
		if original_vertices_count & 1 == 0:
			next_point = _get_vertices(half_rotation_spacing * original_vertices_count + offset_rotation, size, offset_position)
		else:
			next_point = _get_vertices(half_rotation_spacing * original_vertices_count + offset_rotation, inner_size, offset_position)
		
		var edge_slope := next_point - last_point
		var ending_slope := _get_vertices(drawn_arc + offset_rotation)

		var scaler := RegularPolygon2D._find_intersection(last_point, edge_slope, offset_position, ending_slope)
		points[original_vertices_count] = last_point + edge_slope * scaler
	
	if add_central_point:
		points[-1] = offset_position
	return points
	
static func _get_vertices(rotation : float, size : float = 1, offset : Vector2 = Vector2.ZERO) -> Vector2:
	return Vector2(-sin(rotation), cos(rotation)) * size + offset
