class_name MovementPhase
extends RefCounted

signal movement_completed(unit: Unit3D, final_position: Vector3)
signal movement_undo(unit: Unit3D)

var battlefield: Node3D
var camera: Camera3D
var unit_instances: Array[Unit3D]
var unit_utils_script = preload("res://scripts/utils/UnitUtils.gd")

var is_dragging: bool = false
var drag_start_pos: Vector3
var selected_unit: Unit3D = null
var movement_preview: CSGBox3D = null
var floating_text: Label3D = null

func _init() -> void:
	pass

func start_movement_drag(unit: Unit3D, mouse_pos: Vector2) -> void:
	"""Start movement drag for a unit"""
	if not unit or unit.unit_data.player_owner != 1:  # Only Player 1 can move
		return
	
	selected_unit = unit
	is_dragging = true
	
	# Get the starting position
	var intersection_point = unit_utils_script.get_mouse_intersection_point(camera, mouse_pos)
	if intersection_point:
		drag_start_pos = intersection_point
		unit.original_position = unit.global_position
		
		# Create movement preview
		create_movement_preview(unit)
		
		print("Started movement drag for %s" % unit.unit_data.unit_name)

func update_movement_drag(mouse_pos: Vector2) -> void:
	"""Update movement drag with current mouse position"""
	if not is_dragging or not selected_unit:
		return
	
	var intersection_point = unit_utils_script.get_mouse_intersection_point(camera, mouse_pos)
	if not intersection_point:
		return
	
	# Calculate movement distance
	var movement_vector = intersection_point - drag_start_pos
	var distance = movement_vector.length()
	
	# Check if movement is within unit's move characteristic
	if distance <= selected_unit.unit_data.move_characteristic:
		# Check if path is valid (no collisions with enemies unless flying)
		if is_valid_movement_path(selected_unit, intersection_point):
			# Update unit position
			selected_unit.global_position = Vector3(intersection_point.x, 0, intersection_point.z)
			
			# Update movement preview
			update_movement_preview(selected_unit, distance)
		else:
			print("❌ Invalid movement path - would collide with enemies")
	else:
		print("❌ Movement distance %.1f\" exceeds unit's move characteristic %.1f\"" % [distance, selected_unit.unit_data.move_characteristic])

func end_movement_drag() -> void:
	"""End movement drag and finalize movement"""
	if not is_dragging or not selected_unit:
		return
	
	is_dragging = false
	
	# Update unit's 2D position data
	selected_unit.unit_data.position = Vector2(selected_unit.global_position.x, selected_unit.global_position.z)
	
	# Clean up preview
	cleanup_movement_preview()
	
	# Emit completion signal
	movement_completed.emit(selected_unit, selected_unit.global_position)
	
	print("Completed movement for %s to position %s" % [selected_unit.unit_data.unit_name, selected_unit.global_position])
	
	selected_unit = null

func undo_movement(unit: Unit3D) -> void:
	"""Undo the last movement for a unit"""
	if not unit or not unit.original_position:
		return
	
	# Restore original position
	unit.global_position = unit.original_position
	unit.unit_data.position = Vector2(unit.original_position.x, unit.original_position.z)
	
	# Clear original position
	unit.original_position = null
	
	# Emit undo signal
	movement_undo.emit(unit)
	
	print("Undid movement for %s" % unit.unit_data.unit_name)

func finalize_movement(unit: Unit3D) -> void:
	"""Finalize movement and mark unit as moved"""
	if not unit:
		return
	
	unit.unit_data.has_moved = true
	print("Finalized movement for %s" % unit.unit_data.unit_name)

func is_valid_movement_path(unit: Unit3D, target_position: Vector3) -> bool:
	"""Check if the movement path is valid (no enemy collisions unless flying)"""
	if unit.unit_data.keywords.has("Fly"):
		return true  # Flying units can move through enemies
	
	# Sample points along the path to check for collisions
	var start_pos = unit.global_position
	var path_vector = target_position - start_pos
	var path_length = path_vector.length()
	var sample_count = max(1, int(path_length / 0.5))  # Sample every 0.5 units
	
	for i in range(sample_count + 1):
		var t = float(i) / sample_count
		var sample_pos = start_pos + path_vector * t
		
		# Check for enemy collisions at this point
		for enemy_unit in unit_instances:
			if enemy_unit.unit_data.player_owner != unit.unit_data.player_owner:
				var distance = sample_pos.distance_to(enemy_unit.global_position)
				var min_distance = unit_utils_script.get_unit_base_radius(unit.unit_data) + unit_utils_script.get_unit_base_radius(enemy_unit.unit_data) + 0.5
				
				if distance < min_distance:
					return false
	
	return true

func create_movement_preview(unit: Unit3D) -> void:
	"""Create visual preview for movement"""
	if movement_preview:
		movement_preview.queue_free()
	
	movement_preview = CSGBox3D.new()
	movement_preview.size = Vector3(0.1, 0.1, 0.1)
	movement_preview.material = StandardMaterial3D.new()
	movement_preview.material.albedo_color = Color.YELLOW
	movement_preview.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	movement_preview.material.albedo_color.a = 0.5
	
	battlefield.add_child(movement_preview)

func update_movement_preview(unit: Unit3D, distance: float) -> void:
	"""Update movement preview with current distance"""
	if not movement_preview:
		return
	
	movement_preview.global_position = unit.global_position
	
	# Update floating text
	if not floating_text:
		floating_text = Label3D.new()
		floating_text.text = "%.1f\"" % distance
		floating_text.font_size = 24
		floating_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		floating_text.pixel_size = 0.01
		floating_text.modulate = Color.WHITE
		battlefield.add_child(floating_text)
	
	floating_text.text = "%.1f\"" % distance
	floating_text.global_position = unit.global_position + Vector3(0, 2, 0)

func cleanup_movement_preview() -> void:
	"""Clean up movement preview objects"""
	if movement_preview:
		movement_preview.queue_free()
		movement_preview = null
	
	if floating_text:
		floating_text.queue_free()
		floating_text = null
