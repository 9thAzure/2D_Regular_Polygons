@tool
extends Polygon2D

## A node that draws regular shapes, with some advanced properties. 
##
## A node that draws regular shapes, with some advanced properties.
## It mainly uses draw_* methods, but may use the [member polygon] property, specifically with [member width].
## With advanced properties, circles use a 36-sided shape, and lines are unaffected.

## The number of vertices in the perfect shape. A value of 1 creates a circle, a value of 2 creates a line.
## Values are clamped to a value greater than or equal to 1.[br]
## Note: With advanced properties, circles use a 36-sided shape, and lines are unaffected.
@export_range(1,8,1,"or_greater") var vertices_count : int = 1:
	set(value):
		assert(value >= 1)
		vertices_count = value
		if value < 1:
			vertices_count = 1
		if corner_size != 0:
			corner_size = corner_size
			return
		_pre_redraw()

## The length from each corner to the center.
## Values are clamped to a value greater than 0.
@export var size : float = 10:
	set(value):
		size = value
		if value <= 0:
			size = 0.000001	
		_pre_redraw()

## The offset rotation of the shape, in degrees.
@export_range(-360, 360, 0.1, "or_greater", "or_less") var offset_rotation_degrees : float = 0:
	set(value):
		offset_rotation = deg_to_rad(value)
	get:
		return rad_to_deg(offset_rotation)

## the offset rotation of the shape, in radians.
var offset_rotation : float = 0:
	set(value):
		offset_rotation = value
		_pre_redraw()

# ? not sure if this is a good name for it and many of the properties under it, they may need changing.
@export_group("advanced")

# The default value is -0.001 so that dragging it into positive values is quick.
## Determines the width of the shape. A value of 0 outlines the shape with lines, and a value smaller than 0 ignores this effect.
## A value greater than [member size] also ignores this effect while using [member polygon].[br]
## Note: A value between 0 and 0.01 is converted to 0, to make it easier to select it in the editor.
@export var width : float = -0.001:
	set(value):
		width = value
		if width > 0 and width < 0.01:
			width = 0
		_pre_redraw()

# Todo: implement effects
# this variable would cut out edges (eg: draw only have a hexagon, a trapezoid). To be implemented. Name is temporary.
# Exact implementation/way of working TBD.
## Cuts out vertices of the shape, as a percentage. Cuts are only made at the corners.
@export_range(0, 1, 0.0001) var shape_cut_percentage : float = 0.0:
	set(value):
		shape_cut_percentage = value
		self.queue_redraw()
		_pre_redraw()

## How much of the shape is drawn.
@export_range(-360, 360) 
var drawn_arc_degrees : float = 360:
	set(value):
		drawn_arc = deg_to_rad(value)
	get:
		return rad_to_deg(drawn_arc)

var drawn_arc : float = TAU:
	set(value):
		drawn_arc = value
		_pre_redraw()

## The length cut off from each end to form the corner.
## Values are clamped to 0 and half of the side length.
@export_range(0, 5, 0.01, "or_greater") var corner_size : float = 0.0:
	set(value):
		corner_size = get_side_length(vertices_count) * size / 2
		if value < corner_size:
			corner_size = value
			if value < 0:
				corner_size = 0
		_pre_redraw()

## How many lines make up the corner. A value of 0 will use a value of 36 divided by [member vertices_count].
## Values are clamped to a value greater than 0.
@export_range(0, 8, 1, "or_greater") var corner_smoothness : int = 0:
	set(value):
		corner_smoothness = value
		if value < 0:
			corner_smoothness = 0
		_pre_redraw()

# used to signal when _draw should be used.
var _use_draw := true

func _ready():
	# ? Is this necessary for all cases? eg: does this run when 'polygon' is used?
	_pre_redraw()

# Todo: implement changes from _draw.
# Called when shape properties are updated, before [method _draw]/[method queue_redraw]. Calls [method queue_redraw] automatically.
func _pre_redraw() -> void:
	if (width <= 0
		or vertices_count == 2
	):
		# ? Have it so that it uses polygon property when in editor and texture is available so that editing uv is easier.
		# ? The drawback is that the polygon data is still stored when it isn't needed.
		_use_draw = true
		polygon = PackedVector2Array()
		return

	# shape has hole here.
	_use_draw = false
	var points = get_shape_vertices(36 if vertices_count == 1 else vertices_count, size, offset_rotation)
	if width < size:
		add_hole_to_points(points, 1 - width / size)
	polygon = points

# ? I've got a basic testing uv working, not sure if it is fool proof.
func _draw():
	if not _use_draw:
		return
	
	# at this point, width <= 0
	# if there is no advanced features, check for other draw calls.
	if vertices_count == 1:
		draw_circle(offset, size, color)
		return
	
	if vertices_count == 2:
		var point = Vector2(sin(-offset_rotation), cos (-offset_rotation)) * size
		draw_line(point + offset, -point + offset, color)
		return
		
	if (vertices_count == 4 
		and is_zero_approx(offset_rotation)
		and not is_zero_approx(width)
		and is_zero_approx(corner_size)
		and (drawn_arc >= TAU or drawn_arc <= -TAU)
	):
		const sqrt_two_over_two := 0.707106781
		draw_rect(Rect2(-Vector2.ONE * sqrt_two_over_two * size + offset, Vector2.ONE * sqrt_two_over_two * size * 2), color)
		return
		# no matches, using default drawing.

	var points = get_shape_vertices(vertices_count, size, offset_rotation, offset, drawn_arc)

	if not is_zero_approx(corner_size):
		points = get_rounded_corners(points, corner_size, corner_smoothness)

	if is_zero_approx(width):
		points.append(points[0])
		draw_polyline(points, color)
		return
	
	## Add null checks and branching so that uv isn't used in draw_colored_polygon.
	var uv_points := uv
	if texture != null:
		# The check if uv is smaller imitates the behaviour of Polygon2D; If uv size doesn't match polygon size, it is treated as empty.
		# Greater values aren't checked for the cases of transitioning between width values from >0 to <0.
		# ? Perhaps change this default way this works, inconsistent behaviour.
		if uv_points.is_empty() or uv_points.size() < vertices_count:
			uv_points = points.duplicate()
		else:
			uv_points.resize(points.size())
		
		var uv_scale_x := 1.0 / texture.get_width()
		var uv_scale_y := 1.0 / texture.get_height()
		# The scale doesn't need to be reversed, for some reason.
		var transform := Transform2D(-texture_rotation, texture_scale, 0, -texture_offset)
		uv_points *= transform
		for i in uv_points.size():
			var uv_point := uv_points[i]
			uv_point.x *= uv_scale_x
			uv_point.y *= uv_scale_y
			uv_points[i] = uv_point
	
	draw_colored_polygon(points, color, uv_points, texture)

# <section> helper functions for _draw()

## Gets the side length of a shape with the specified vertices amount, each being 1 away from the center.
## If [param vertices_count] is 1, PI is returned. If it is 2, 1 is returned.
static func get_side_length(vertices_count : int):
	assert(vertices_count >= 1)
	if vertices_count == 1: return PI
	if vertices_count == 2: return 1
	return 2 * sin(TAU / vertices_count / 2)

# ! Note: this func should be static, it was removed for debug purposes and should be re-added when done.
## Returns a [PackedVector2Array] with the points for drawing the specified shape with [method CanvasItem.draw_colored_polygon].
func get_shape_vertices(vertices_count : int, size : float = 1, offset_rotation : float = 0.0, offset_position : Vector2 = Vector2.ZERO, drawn_arc : float = TAU) -> PackedVector2Array:
	assert(vertices_count > 0)
	assert(size > 0)

	var points := PackedVector2Array()
	var sign := signf(drawn_arc)
	var rotation_spacing := TAU / vertices_count * sign
	
	# If drawing a full shape
	if drawn_arc >= TAU or drawn_arc <= -TAU:
		# rotation is initialized pointing down and offset to the left so that the bottom is flat
		var current_rotation := rotation_spacing / 2 + offset_rotation
		for i in vertices_count:
			points.append(_get_vertices(current_rotation, size, offset_position))
			current_rotation += rotation_spacing
		return points
			
	# Drawing a partial shape.
	var current_rotation := -rotation_spacing / 2 
	# draw_circle(_get_vertices(current_rotation, size, offset_position), 0.5, Color.GRAY)
	var limit := sign * drawn_arc
	var fail_safe := 0
	while sign * current_rotation < limit:
		fail_safe += 1
		assert(fail_safe < 100, "fail_safe: infinite loop!")
		var point := _get_vertices(current_rotation, size, offset_position)
		points.append(point)
		current_rotation += rotation_spacing
	
	# Setting center point.
	var first_point := points[0]
	var vector_to_second := (points[1] if points.size() != 1 else _get_vertices(current_rotation, size, offset_position)) - first_point
	# draw_line(first_point, first_point + vector_to_second, Color.BLACK)
	# draw_circle(first_point, 0.1, Color.GRAY)
	points[0] = first_point + vector_to_second / 2

	if is_equal_approx(current_rotation, drawn_arc):
		points.append(_get_vertices(current_rotation, size, offset_position)) 
	else:
		# variable names in formula: P, _, Q, R
		var last_point := points[-1]
		var next_point := _get_vertices(current_rotation, size, offset_position)
		var edge_slope := next_point - last_point 
		var ending_slope := Vector2(sin(-drawn_arc), cos(-drawn_arc))
		# formula variables: P, Q, S, R
		var scaler := _find_intersection(last_point, edge_slope, offset_position, ending_slope)
		var edge_point := last_point + scaler * edge_slope
		# draw_line(last_point, last_point + edge_slope, Color.ORANGE)
		# draw_line(offset_position, offset_position + ending_slope * size, Color.GREEN)
		points.append(edge_point)
	
	if not is_equal_approx(drawn_arc, PI):
		points.append(offset_position)
			
	return points

static func _get_vertices(rotation : float, size : float, offset : Vector2) -> Vector2:
	return Vector2(-sin(rotation), cos(rotation)) * size + offset

# finds the intersection between 2 points and their slopes. The value returned is not the point itself, but a scaler.
# The point would be obtained by (where a = returned value of function): point1 + a * slope1
static func _find_intersection(point1 : Vector2, slope1 : Vector2, point2: Vector2, slope2: Vector2) -> float:
	var numerator := slope2.y * (point2.x - point1.x) - slope2.x * (point2.y - point1.y)
	var devisor := (slope1.x * slope2.y) - (slope1.y * slope2.x)
	return numerator / devisor 
	

# Todo: Check what happens when corner_size is greater then halve the side lengths (corners are bigger than the shape).
## Returns a new [PackedVector2Array] with the points for drawing the rounded shape with [method CanvasItem.draw_colored_polygon].
## [param corner_size] dictates the amount of lines used to draw the corner, and a value of 0 will instead use a value of 36 divided by the size of [param points].
static func get_rounded_corners(points : PackedVector2Array, corner_size : float, corner_smoothness : int) -> PackedVector2Array:
	assert(not points.is_empty(), "points must not be empty")
	assert(corner_smoothness >= 0, "corners must draw some lines")
	
	if corner_smoothness == 0:
		corner_smoothness = 36 / points.size()
	var new_points := PackedVector2Array()
	var index_factor := corner_smoothness + 1
	new_points.resize(points.size() * index_factor)

	var last_point := points[-1]
	var current_point := points[0]
	var next_point : Vector2
	for i in points.size():
		next_point = points[(i + 1) % points.size()]
		
		# get starting & ending points of corner.
		var starting_slope := (current_point - last_point).normalized()
		var ending_slope := (current_point - next_point).normalized()
		var starting_point = current_point - starting_slope * corner_size
		var ending_point = current_point - ending_slope * corner_size

		new_points[i * index_factor] = starting_point
		new_points[i * index_factor + index_factor - 1] = ending_point

		# Quadratic Bezier curves are use because we have all three required points already. It isn't a perfect circle, but good enough.
		# sub_i is initialized with a value of 1 as a corner_smoothness of 1 has no between points.
		var sub_i := 1
		while sub_i < corner_smoothness:
			var t_value := sub_i / (corner_smoothness as float)
			new_points[i * index_factor + sub_i] = quadratic_bezier_interpolate(starting_point, points[i], ending_point, t_value)
			sub_i += 1
		
		# end, prep for next loop.
		last_point = current_point
		current_point = next_point

	return new_points

## Returns the point at the given [param t] on the Bézier curve with the given [param start], [param end], and singular [param control] point.
static func quadratic_bezier_interpolate(start : Vector2, control : Vector2, end : Vector2, t : float) -> Vector2:
	return control + (t - 1) ** 2 * (start - control) + t ** 2 * (end - control)

# Todo: change method to instead create a new array instead.
## [b]Appends[/b] points, which are [param hole_scaler] of the original points, on [param points] to give it a hole for [member Polygon2D.polygon].
static func add_hole_to_points(points : PackedVector2Array, hole_scaler : float) -> void:
	points.append(points[0])
	var original_size := points.size()
	for i in original_size:
		points.append(points[original_size - i - 1] * hole_scaler)
