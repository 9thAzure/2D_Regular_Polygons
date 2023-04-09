@tool
@icon("res://addons/regular_polygon_2d/regular_collision_polygon_2d.svg")
class_name RegularCollisionPolygon2D
extends CollisionShape2D

## Node that generates 2d regular collision shapes.
##
## A node with variables for generating 2d regular shapes for collision.
## It creates various shape inheriting [Shape2D] based on the values of its variables and sets it to [member CollisionShape2D.shape].
## [br][br]Note: If these properties are set when the node is outside a [SceneTree], its effects are delayed to when it enters one.
## If [member CollisionShape2D.shape] is already set before then, it won't be regenerated.
## [method regenerate] can be used to force regeneration.

## The number of vertices in the regular shape
## a value of 1 creates a circle, a value of 2 creates a line.
## Values are clamped to a value greater than or equal to 1.
@export_range(1,8,1,"or_greater")
var vertices_count : int = 1:
	set(value):
		assert(value < 2000, "Large vertices counts should not be necessary.")
		vertices_count = value
		if value < 1:
			vertices_count = 1

		queue_regenerate()

## The length of each corner to the center.
## Values are clamped to a value greater than 0.
@export
var size : float = 10:
	set(value):
		size = value
		if value <= 0:
			size = 0.00000001
		
		queue_regenerate()

## The offset rotation of the shape, in degrees.
@export_range(-360, 360, 0.1, "or_greater", "or_less")
var offset_rotation_degrees : float = 0:
	set(value):
		offset_rotation = deg_to_rad(value)
	get:
		return rad_to_deg(offset_rotation)

## The offset rotation of the shape, in radians.
var offset_rotation : float = 0:
	set(value):
		offset_rotation = value
		queue_regenerate()

@export_group("complex")

## Determines the width of the shape. It only has an effect with values greater than [code]0[/code].
## Values greater than or equal to [member size] force the usage of [ConvexPolygonShape2D].
@export 
var width : float = 0:
	set(value):
		width = value
		queue_regenerate()

## The arc of the drawn shape, in degrees, cutting off beyond that arc. 
## Values greater than [code]360[/code] or smaller than [code]-360[/code] draws a full shape. It starts in the middle of the base of the shapes. 
## The direction of the arc is clockwise with positive values and counterclockwise with negative values.
## [br][br]A value of [code]0[/code] makes the node not change [member CollisionShape2D.shape].
@export_range(-360, 360) 
var drawn_arc_degrees : float = 360:
	set(value):
		drawn_arc = deg_to_rad(value)
	get:
		return rad_to_deg(drawn_arc)

## The arc of the drawn shape, in radians, cutting off beyond that arc. 
## Values greater than [constant @GDScript.TAU] or smaller than -[constant @GDScript.TAU] draws a full shape. It starts in the middle of the base of the shapes. 
## The direction of the arc is clockwise with positive values and counterclockwise with negative values.
## [br][br]A value of [code]0[/code] makes the node not change [member CollisionShape2D.shape].
var drawn_arc : float = TAU:
	set(value):
		drawn_arc = value
		queue_regenerate()

## The distance from each vertex along the edge to the point where the rounded corner starts.
## If this value is over half of the edge length, the mid-point of the edge is used instead.
## Values are clamped to a value of [code]0[/code] or greater.
@export 
var corner_size : float = 0.0:
	set(value):
		corner_size = value
		if value < 0:
			corner_size = 0
		
		queue_regenerate()

## How many lines make up the corner. A value of [code]0[/code] will use a value of [code]32[/code] divided by [member vertices_count].
## Values are clamped to a value of [code]0[/code] or greater.
@export_range(0, 8, 1, "or_greater") 
var corner_smoothness : int = 0:
	set(value):
		corner_smoothness = value
		if value < 0:
			corner_smoothness = 0
		
		queue_regenerate()

var _is_queued := true

## Queues [method regenerate] for the next process frame. If this method is called multiple times, the shape is only regenerated once.
##[br][br]This method does nothing if the node is outside the [SceneTree]. Use [method regenerate] instead.
func queue_regenerate() -> void:
	if _is_queued:
		return
	
	_is_queued = true
	await get_tree().process_frame
	_is_queued = false
	regenerate()

func _enter_tree() -> void:
	if shape == null and not Engine.is_editor_hint():
		regenerate()
	_is_queued = false

func _exit_tree() -> void:
	_is_queued = true

## Regenerates the [member CollisionShape2D.shape] using the properties of this node.
func regenerate() -> void:
	if vertices_count == 2:
		var line := SegmentShape2D.new()
		line.a = size * (Vector2.UP if is_zero_approx(offset_rotation) else Vector2(sin(offset_rotation), -cos(offset_rotation)))
		line.b = -line.a
		shape = line
		return
	
	if drawn_arc == 0:
		return
	
	var uses_rounded_corners := not is_zero_approx(corner_size)
	var uses_width := width > 0
	var uses_drawn_arc := -TAU < drawn_arc and drawn_arc < TAU
	if uses_width:
		var polygon := ConcavePolygonShape2D.new()
		var points := RegularPolygon2D.get_shape_vertices(vertices_count, size, offset_rotation, Vector2.ZERO, drawn_arc, not uses_width)
		if uses_width and width >= size:
			uses_width = false
		
		if uses_width and uses_drawn_arc:
			RegularPolygon2D.add_hole_to_points(points, 1 - width / size, false)

		if uses_rounded_corners:
			RegularPolygon2D.add_rounded_corners(points, corner_size, corner_smoothness if corner_smoothness != 0 else 32 / vertices_count)

		if uses_width and not uses_drawn_arc:
			RegularPolygon2D.add_hole_to_points(points, 1 - width / size, true)
		
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
		
		shape = polygon
		return
	
	if vertices_count == 1:
		var circle := CircleShape2D.new()
		circle.radius = size
		shape = circle
		return
	
	if vertices_count == 4 and is_zero_approx(offset_rotation) and not uses_rounded_corners:
		const sqrt_two_over_two := 0.707106781
		var square := RectangleShape2D.new()
		square.size = size / sqrt_two_over_two * Vector2.ONE
		shape = square
		return
	
	var polygon := ConvexPolygonShape2D.new()
	var points := RegularPolygon2D.get_shape_vertices(vertices_count, size, offset_rotation, Vector2.ZERO, drawn_arc)
	if uses_rounded_corners:
		RegularPolygon2D.add_rounded_corners(points, corner_size, corner_smoothness if corner_smoothness != 0 else 32 / vertices_count)
	
	polygon.points = points 
	shape = polygon

func _uses_drawn_arc() -> bool:
	return -TAU < drawn_arc and drawn_arc < TAU