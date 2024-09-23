extends Object
class_name RegularGeometry2D

## Holds methods for creating and modifying shapes.

func _init():
	printerr("This class is meant to be a singleton, and cannot be instantiated")
	self.free()

## Modifies [param points] so that the shape it represents have rounded corners. The method uses quadratic Bézier curves for the corners.
## [br][br][param corner_size] determines how long each corner is, from the original point to at most half the side length.
## [param corner_smoothness] determines how many [b]lines[/b] are in each corner.
## [br][br][param start_index] & [param length] can be used to specify only part of the shape should be rounded.
## [param limit_ending_slopes] determines whether the ending corners should still be limited to half the side length. Does not work if the entire shape is being rounded.
## [param original_array_size], when used, indicates that the array has already been resized, so the method should add points into the empty space.
## This parameter specifies the part of the array that is currently used.
static func add_rounded_corners(points : PackedVector2Array, corner_size : float, corner_smoothness : int,
	start_index := 0, length := -1, limit_ending_slopes := true, original_array_size := 0) -> void:
	# argument prep 
	var corner_size_squared := corner_size ** 2
	var points_per_corner := corner_smoothness + 1
	var resize_array := false
	if original_array_size <= 0:
		resize_array = true
		original_array_size = points.size()
	if length < 0:
		length = original_array_size - start_index
	if corner_smoothness == 0:
		corner_smoothness = 32 / points.size()
	
	assert(points.size() >= 3, "param 'points' must have at least 3 points.")
	assert(corner_size >= 0, "param 'corner_size' must be 0 or greater.")
	assert(corner_smoothness >= 0, "param 'corner_smoothness' must be 0 or greater.")
	assert(start_index >= 0, "param 'start_index' must be 0 or greater.")
	assert(start_index + length <= original_array_size, "sum of param 'start_index' & param 'length' must not be greater than the original size of the array (param 'original_array_size', or if 0, size of param 'points').")
	assert(limit_ending_slopes || length != original_array_size, "param 'limit_ending_slopes' was set to false, but the entire shape is being rounded so there are no \"ending\" slopes.")

	# resizing and spacing
	var size_increase := SizeIncrease.add_rounded_corners(length, corner_smoothness)
	if resize_array:
		points.resize(original_array_size + size_increase)
		for i in (original_array_size - start_index - length):
			points[-i - 1] = points[-i - 1 - size_increase]
	else:
		assert(original_array_size + size_increase <= points.size(), "The function is set to use the empty space in param 'points' but it is too small.")
		for i in (original_array_size - start_index - length):
			points[original_array_size - i - 1 + size_increase]= points[original_array_size - i - 1]

	for i in length:
		var index := length - i - 1
		points[start_index + index * points_per_corner] = points[index + start_index]

	# pre-loop prep and looping
	var current_point := points[start_index]
	var next_point : Vector2
	var point_after_final : Vector2
	var previous_point : Vector2
	if start_index == 0:
		if length == original_array_size:
			previous_point = points[original_array_size + size_increase - points_per_corner]
		else:
			previous_point = points[original_array_size + size_increase - 1]
	else:
		previous_point = points[start_index - 1]

	if start_index + length == original_array_size:
		point_after_final = points[0]
	else:
		point_after_final = points[start_index + length * points_per_corner - points.size()]
	
	for i in length:
		if i + 1 == length:
			next_point = point_after_final
		else:
			next_point = points[start_index + (i + 1) * points_per_corner]
		
		# creating corner
		var starting_slope := (current_point - previous_point)
		var ending_slope := (current_point - next_point)
		var starting_point : Vector2
		var ending_point : Vector2

		var slope_limit_value := 1 if not limit_ending_slopes and i == 0 else 2
		if starting_slope.length_squared() / (slope_limit_value * slope_limit_value) < corner_size_squared:
			starting_point = current_point - starting_slope / (slope_limit_value + 0.001)
		else:
			starting_point = current_point - starting_slope.normalized() * corner_size
		
		slope_limit_value = 1 if not limit_ending_slopes and i + 1 == length else 2
		if ending_slope.length_squared() / (slope_limit_value * slope_limit_value) < corner_size_squared:
			ending_point = current_point - ending_slope / (slope_limit_value + 0.001)
		else:
			ending_point = current_point - ending_slope.normalized() * corner_size

		points[start_index + i * points_per_corner] = starting_point
		points[start_index + i * points_per_corner + points_per_corner - 1] = ending_point
		# sub_i is initialized with a value of 1 as a corner_smoothness of 1 has no in-between points.
		var sub_i := 1
		while sub_i < corner_smoothness:
			var t_value := sub_i / (corner_smoothness as float)
			points[start_index + i * points_per_corner + sub_i] = _quadratic_bezier_interpolate(starting_point, current_point, ending_point, t_value)
			sub_i += 1
		
		# end, prep for next loop.
		previous_point = current_point
		current_point = next_point

static func _quadratic_bezier_interpolate(start : Vector2, control : Vector2, end : Vector2, t : float) -> Vector2:
	return control + (t - 1) ** 2 * (start - control) + t ** 2 * (end - control)

## Transforms [param points], rotating it by [param rotation] radians and scaling it by a factor of [param scaler].
## [br][br][param is_ringed_shape] indicates the shape forms a ringed shape.
## [param points_per_corner] indicates the shape has rounded corners and how many points form each rounded corner.
## [param scale_width] toggles scaling the width formed by the ring.
## [param scale_corner_size] toggles scaling the size of the rounded corners.
## [br][br][b]Note[/b]: The method does not check if the transformation would result in a different shape then its properties would suggest,
## such as shrinking a ring shape to the point it is no longer ringed or having a corner size larger than the a side length.
static func apply_transformation(points : PackedVector2Array, rotation : float, scaler : float, is_ringed_shape := false, points_per_corner := 1, scale_width := true, scale_corner_size := true) -> void:
	assert(points.size() >= 3, "param 'points' does not represent a proper shape.")
	assert(scaler > 0, "param 'scaler' should be positive.")
	assert(points_per_corner > 0, "param 'points_per_corner' should be positive.")
	var size := points.size()
	var has_rounded_corners := points_per_corner != 1
	
	var transform := Transform2D(-rotation, Vector2.ONE * scaler, 0, Vector2.ZERO)
	for i in size:
		points[i] *= transform

	scale_corner_size = scale_corner_size or not has_rounded_corners
	scale_width = scale_width or not is_ringed_shape
	if scale_corner_size and scale_width or is_equal_approx(scaler, 1):
		return

	var delta := 1 - (1 / scaler)
	var previous_outer_point := points[-1]
	var previous_inner_point := points[0]
	var complete_shape_arc := false
	if is_ringed_shape and points[-1].is_equal_approx(points[size / 2]):
		assert(points[0].is_equal_approx(points[size / 2 - 1]), "expected two pairs of points to be on top of each other, forming an identical line used to draw a ringed shape")
		complete_shape_arc = true
		previous_outer_point = points[size / 2 - 2]
		previous_inner_point = points[size / 2 + 1]

	var iterations_count := size / points_per_corner / (2 if is_ringed_shape else 1)
	for i in iterations_count:
		var index := i * points_per_corner
		var outer_point := Vector2.ZERO
		var inner_point := Vector2.ZERO
		
		if not has_rounded_corners:
			if scale_width:
				continue

			outer_point = points[index]
			inner_point = points[-index - 1]
			points[-index - 1] = inner_point.lerp(outer_point, delta)
			continue

		var first_point1 := points[index]
		var last_point1 := points[index + points_per_corner - 1]
		var first_slope1 := first_point1 - previous_outer_point
		var last_slope1 := last_point1 - points[index + points_per_corner - size]
		var a := _find_intersection(first_point1, first_slope1, last_point1, last_slope1)
		outer_point = first_point1 + first_slope1 * a
		previous_outer_point = last_point1
		if not scale_corner_size:
			for i2 in points_per_corner:
				points[index + i2] = points[index + i2].lerp(outer_point, delta)

		if not is_ringed_shape:
			continue

		if scale_corner_size:
			if scale_width:
				continue
			
			if not complete_shape_arc and (i == 0 or i + 1 == iterations_count):
				var offset = i / (iterations_count - 1) * (points_per_corner - 1)
				outer_point = points[index + points_per_corner - 1 - offset]
				inner_point = points[-index - points_per_corner + offset]
				var slope := (outer_point - inner_point) * delta
				for i2 in points_per_corner:
					points[-index - i2 - 1] = points[-index - i2 - 1] + slope
				continue
			
			for i2 in points_per_corner:
				points[-index - i2 - 1] = points[-index - i2 - 1].lerp(points[index + i2], delta)	
			continue

		if not scale_width:
			for i2 in points_per_corner:
				points[-index - i2 - 1] = points[-index - i2 - 1].lerp(outer_point, delta)
				pass
			continue
		
		var first_point2 := points[-index - 1]
		var last_point2 := points[-index - points_per_corner]
		var first_slope2 := first_point2 - previous_inner_point
		var last_slope2 := last_point2 - points[-index - points_per_corner - 1 + size]
		var b := _find_intersection(first_point2, first_slope2, last_point2, last_slope2)
		inner_point = first_point2 + first_slope2 * b
		previous_inner_point = last_point2
		for i2 in points_per_corner:
			points[-index - i2 - 1] = points[-index - i2 - 1].lerp(inner_point, delta)

	if complete_shape_arc:
		var offsetting_slope := (points[size / 2 - 2] - points[0]) / 4194304 # 2^22
		points[size / 2 - 1] = points[0] + offsetting_slope
		points[size / 2] = points[-1] + offsetting_slope

# finds the intersection between 2 points and their slopes. The value returned is not the point itself, but a scaler.
# The point would be obtained by (where a = returned value of function): point1 + a * slope1
static func _find_intersection(point1 : Vector2, slope1 : Vector2, point2: Vector2, slope2: Vector2) -> float:
	var numerator := slope2.y * (point2.x - point1.x) - slope2.x * (point2.y - point1.y)
	var devisor := (slope1.x * slope2.y) - (slope1.y * slope2.x)
	assert(devisor != 0, "one or both slopes are 0, or are parallel")
	return numerator / devisor 
	
## sub class that designates how much each method expands the array.
class SizeIncrease:
	extends Object

	func _init():
		printerr("This class is meant to be a singleton, and cannot be instantiated")
		self.free()

	## Designates how much [method RegularGeometry2D.add_rounded_corners] expands the array.
	## [br][br][param length] specifies many points are to be converted into rounded corners.
	## [param corner_smoothness] specifies how many lines are in each corner.
	static func add_rounded_corners(length : int, corner_smoothness : int) -> int:
		assert(length >= 0, "param 'length' must be positive.")
		assert(corner_smoothness > 0, "param 'corner_smoothness' must be positive.")
		return length * (corner_smoothness + 1) - length
