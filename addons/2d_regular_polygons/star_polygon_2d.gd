@tool
extends Polygon2D
class_name StarPolygon2D

@export
var point_count := 5
@export
var size := 10.0
@export
var inner_size := 5.0
@export
var offset_rotation := 0.0

# @export_range(0, 90, 0.001, "radians")
# var point_angle := 0.0:
# 	set(value):
# 		# var a := (PI - TAU / point_count) / 2
# 		var a := TAU / point_count / 2
# 		var step := sin(PI - value - a)
# 		inner_size = size * sin(value) / step
# 		point_angle = value
# 		print(rad_to_deg(a))
# 		print(rad_to_deg(asin(step)))
# 		queue_redraw()
# 		regenerate_polygon(

var _is_queued = true

func _pre_redraw() -> void:
	if not uses_polygon_member():
		# the setting the 'polygon' property already calls queue_redraw
		queue_redraw()
		return
	
	if _is_queued:
		return
	
	_is_queued = true
	if not is_inside_tree():
		polygon = PackedVector2Array()
		return

	await get_tree().process_frame
	_is_queued = false
	if not uses_polygon_member():
		return
	regenerate_polygon()

func _enter_tree() -> void:
	if _is_queued and uses_polygon_member() and polygon.is_empty():
		regenerate_polygon()
	_is_queued = false

func uses_polygon_member() -> bool:
	return (
		width > 0
		and vertices_count != 2
	)

# func _draw():
# 	var scaler1 := Vector2(sin(PI - point_angle), -cos(PI - point_angle))
# 	var scaler2 := Vector2(sin(TAU / point_count / 2), -cos(TAU / point_count / 2))
# 	# print(point_angle)
# 	# print(scaler1)
# 	# print(scaler2)
# 	draw_line(Vector2.UP * size, Vector2.UP * size + scaler1 * size, Color.GREEN)
# 	draw_line(Vector2.ZERO, scaler2 * size, Color.BLUE)


func regenerate_polygon():
	polygon = StarPolygon2D.create_star_shape(point_count, size, inner_size)


static func create_star_shape(point_count : int, size : float, inner_size : float ) -> PackedVector2Array:
	var points = PackedVector2Array()
	var current_rotation := PI
	var rotation_spacing := TAU / point_count / 2
	for i in point_count:	
		points.append(Vector2(-sin(current_rotation), cos(current_rotation)) * size)
		current_rotation += rotation_spacing
		points.append(Vector2(-sin(current_rotation), cos(current_rotation)) * inner_size)
		current_rotation += rotation_spacing
	return points
