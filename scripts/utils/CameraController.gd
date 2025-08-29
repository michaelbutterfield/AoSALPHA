class_name CameraController
extends RefCounted

signal camera_moved(position: Vector3)
signal camera_rotated(rotation: Vector2)

var camera: Camera3D
var camera_speed: float = 10.0
var camera_rotation_speed: float = 2.0
var camera_position: Vector3 = Vector3(0, 15, 15)
var camera_rotation: Vector2 = Vector2(0, -30)

func _init():
	pass

func move_forward() -> void:
	camera_position += Vector3(0, 0, -1) * camera_speed * 0.1
	update_camera_position()
	camera_moved.emit(camera_position)

func move_backward() -> void:
	camera_position += Vector3(0, 0, 1) * camera_speed * 0.1
	update_camera_position()
	camera_moved.emit(camera_position)

func move_left() -> void:
	camera_position += Vector3(-1, 0, 0) * camera_speed * 0.1
	update_camera_position()
	camera_moved.emit(camera_position)

func move_right() -> void:
	camera_position += Vector3(1, 0, 0) * camera_speed * 0.1
	update_camera_position()
	camera_moved.emit(camera_position)

func move_up() -> void:
	camera_position += Vector3(0, 1, 0) * camera_speed * 0.1
	update_camera_position()
	camera_moved.emit(camera_position)

func move_down() -> void:
	camera_position += Vector3(0, -1, 0) * camera_speed * 0.1
	update_camera_position()
	camera_moved.emit(camera_position)

func rotate_camera(mouse_delta: Vector2) -> void:
	camera_rotation.x += mouse_delta.x * camera_rotation_speed * 0.01
	camera_rotation.y += mouse_delta.y * camera_rotation_speed * 0.01
	camera_rotation.y = clamp(camera_rotation.y, -60, 60)
	update_camera_position()
	camera_rotated.emit(camera_rotation)

func reset_camera() -> void:
	camera_position = Vector3(0, 15, 15)
	camera_rotation = Vector2(0, -30)
	update_camera_position()
	camera_moved.emit(camera_position)
	camera_rotated.emit(camera_rotation)

func focus_on_unit(unit_position: Vector3) -> void:
	camera_position = unit_position + Vector3(0, 8, 8)
	update_camera_position()
	camera_moved.emit(camera_position)

func update_camera_position() -> void:
	if not camera:
		return
	
	# Set camera position directly
	camera.global_position = camera_position
	
	# Calculate camera rotation based on current rotation values
	var rotation_radians = Vector2(
		deg_to_rad(camera_rotation.x),
		deg_to_rad(camera_rotation.y)
	)
	
	# Create rotation basis
	var basis = Basis()
	basis = basis.rotated(Vector3.UP, rotation_radians.x)
	basis = basis.rotated(basis.x, rotation_radians.y)
	
	# Apply rotation to camera
	camera.transform.basis = basis



