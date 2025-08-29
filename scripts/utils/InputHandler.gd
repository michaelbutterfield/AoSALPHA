class_name InputHandler
extends RefCounted

signal key_pressed(keycode: int)
signal mouse_button_pressed(button_index: int, position: Vector2)
signal mouse_button_released(button_index: int, position: Vector2)
signal mouse_motion(delta: Vector2, position: Vector2)

var camera_controller: RefCounted

func _init():
	pass

func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_handle_key_press(event.keycode)
	
	elif event is InputEventMouseButton:
		var mouse_pos = event.position
		if event.pressed:
			_handle_mouse_button_press(event.button_index, mouse_pos)
		else:
			_handle_mouse_button_release(event.button_index, mouse_pos)
	
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event.relative, event.position)

func _handle_key_press(keycode: int) -> void:
	key_pressed.emit(keycode)
	
	if not camera_controller:
		return
	
	match keycode:
		KEY_W:
			camera_controller.move_forward()
		KEY_S:
			camera_controller.move_backward()
		KEY_A:
			camera_controller.move_left()
		KEY_D:
			camera_controller.move_right()
		KEY_SPACE:
			camera_controller.move_up()
		KEY_X:
			camera_controller.move_down()

func _handle_mouse_button_press(button_index: int, position: Vector2) -> void:
	mouse_button_pressed.emit(button_index, position)

func _handle_mouse_button_release(button_index: int, position: Vector2) -> void:
	mouse_button_released.emit(button_index, position)

func _handle_mouse_motion(delta: Vector2, position: Vector2) -> void:
	mouse_motion.emit(delta, position)
	
	# Handle camera rotation with right mouse button
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and camera_controller:
		camera_controller.rotate_camera(delta)

func get_mouse_position() -> Vector2:
	return Vector2.ZERO  # This will be updated by the main controller

func is_mouse_button_pressed(button_index: int) -> bool:
	return Input.is_mouse_button_pressed(button_index)



