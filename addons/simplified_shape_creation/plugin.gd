@tool
extends EditorPlugin

func _handles(object : Object) -> bool:
	return _is_handled_node(object)

func _is_handled_node(object : Object) -> bool:
	return (
		object is SimplePolygon2D or
		object is RegularPolygon2D or
		object is RegularCollisionPolygon2D or
		object is StarPolygon2D
	)

func _edit(object : Object) -> void:
	var parent := _size_rotation_handler.get_parent()
	if object == null:
		if parent != null:
			parent.remove_child(_size_rotation_handler)
		return

	if not is_same(object, parent):
		if parent != null:
			parent.remove_child(_size_rotation_handler)
		_size_rotation_handler.request_ready()
		object.add_child(_size_rotation_handler, false, INTERNAL_MODE_BACK)

const BaseHandler := preload("res://addons/simplified_shape_creation/gui_handlers/base_handler.gd")
const SizeRotationHandler := preload("res://addons/simplified_shape_creation/gui_handlers/size_rotation_handler.gd")
var _size_rotation_handler : SizeRotationHandler
func _make_visible(visible) -> void:
	if visible:
		_size_rotation_handler = SizeRotationHandler.new(self, get_undo_redo())
	else:
		_remove(_size_rotation_handler)

func _remove(node : Node) -> void:
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.queue_free()

func _forward_canvas_gui_input(event) -> bool:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_MASK_LEFT:
			return false
		
		if event.pressed:
			if not _select_mode_button_selected():
				return false

			var viewport := EditorInterface.get_editor_viewport_2d()
			var transform := viewport.get_final_transform()
			var size := viewport.size
			var lower_bound := -transform.get_origin()
			lower_bound = Vector2(lower_bound.x / transform.get_scale().x, lower_bound.y / transform.get_scale().y)
			var upper_bound := lower_bound + Vector2(size.x / transform.get_scale().x, size.y / transform.get_scale().y)

			var mouse_position = viewport.get_mouse_position()
			if (lower_bound.x <= mouse_position.x and mouse_position.x <= upper_bound.x and
				lower_bound.y <= mouse_position.y and mouse_position.y <= upper_bound.y):
				return _size_rotation_handler.mouse_press(mouse_position)
		else:
			return _size_rotation_handler.mouse_release()
	
	return false

var _select_mode_button : Button = null
func _select_mode_button_selected() -> bool:
	if _is_select_mode_button_invalid(_select_mode_button):
		_get_select_mode_button()
		if _is_select_mode_button_invalid(_select_mode_button):
			return true

	return _select_mode_button.button_pressed

func _is_select_mode_button_invalid(button : Button) -> bool:
	return button == null or not is_instance_valid(button) or not button.toggle_mode or button.icon == null

func _get_select_mode_button() -> void:
	var main_screen := EditorInterface.get_editor_main_screen()

	var found_node : Node = main_screen.get_node_or_null("@CanvasItemEditor@9465/@MarginContainer@9280/@HFlowContainer@9281/@HBoxContainer@9282/@Button@9329")
	if found_node != null and found_node is Button:
		_select_mode_button = found_node
		return
	
	found_node = main_screen
	for i in 5:
		if found_node == null:
			break
		found_node = found_node.get_child(0)

	if found_node != null and found_node is Button:
		_select_mode_button = found_node
		return
	
	printerr("cannot find select button")