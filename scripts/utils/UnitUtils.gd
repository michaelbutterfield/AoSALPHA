class_name UnitUtils
extends RefCounted

static func get_unit_base_radius(unit_data: Unit) -> float:
	"""Get the base radius in inches based on unit type"""
	match unit_data.unit_type:
		"Infantry":
			return 0.5  # 25mm base = 0.5 inch radius
		"Hero":
			return 0.75  # 40mm base = 0.75 inch radius
		"Cavalry":
			return 1.0  # 50mm base = 1 inch radius
		"Monster":
			return 1.75  # 90mm base = 1.75 inch radius
		"War Machine":
			return 1.2  # 60mm base = 1.2 inch radius
		_:
			return 0.5  # Default to infantry size

static func get_base_to_base_distance(unit1: Unit3D, unit2: Unit3D) -> float:
	"""Calculate the base-to-base distance between two units"""
	var pos1 = unit1.global_position
	var pos2 = unit2.global_position
	
	var base_radius1 = get_unit_base_radius(unit1.unit_data)
	var base_radius2 = get_unit_base_radius(unit2.unit_data)
	
	var center_distance = pos1.distance_to(pos2)
	var base_distance = center_distance - base_radius1 - base_radius2
	
	if base_distance < 0:
		print("    WARNING: Bases are overlapping! Distance: %.2f" % base_distance)
		return 999.0
	
	print("    Center distance: %.2f, Base1 radius: %.2f, Base2 radius: %.2f, Base-to-base: %.2f" % [
		center_distance, base_radius1, base_radius2, base_distance
	])
	
	return base_distance

static func get_mouse_intersection_point(camera: Camera3D, mouse_pos: Vector2) -> Vector3:
	"""Get the 3D intersection point of mouse ray with ground plane"""
	var plane = Plane(Vector3(0, 1, 0), 0)
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var intersection = plane.intersects_ray(from, to)
	if intersection:
		intersection.y = 0
		return intersection
	return Vector3.ZERO

static func get_clicked_unit(camera: Camera3D, mouse_pos: Vector2, unit_instances: Array[Unit3D]) -> Unit3D:
	"""Use raycasting to find which unit was clicked"""
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result and result.collider:
		# Find the unit that owns this collision body
		for unit_3d in unit_instances:
			if is_instance_valid(unit_3d) and unit_3d.has_node("CollisionBody"):
				if result.collider == unit_3d.get_node("CollisionBody"):
					return unit_3d
	
	return null

static func roll_dice(num_dice: int, target_value: int = 0) -> Array[int]:
	"""Roll dice and return array of results"""
	var rolls: Array[int] = []
	for i in range(num_dice):
		rolls.append(randi() % 6 + 1)
	return rolls

static func get_base_to_base_distance_from_positions(pos1: Vector3, pos2: Vector3, radius1: float, radius2: float) -> float:
	"""Calculate base-to-base distance from positions and radii"""
	var center_distance = pos1.distance_to(pos2)
	var base_distance = center_distance - radius1 - radius2
	
	if base_distance < 0:
		return 0.0  # Bases are overlapping
	
	return base_distance

static func check_unit_collisions(moving_unit: Unit3D, target_pos: Vector3, all_units: Array[Unit3D]) -> Vector3:
	"""Check if moving a unit to target_pos would cause collisions with other units"""
	var adjusted_pos = target_pos
	var moving_unit_radius = get_unit_base_radius(moving_unit.unit_data)
	
	# Check if unit has Fly keyword (can ignore movement restrictions)
	var has_fly = moving_unit.unit_data.keywords.has("Fly")
	if has_fly:
		return target_pos
	
	# Check final position collision
	for other_unit in all_units:
		# Skip the moving unit itself
		if other_unit == moving_unit:
			continue
		
		# Skip invalid units
		if not is_instance_valid(other_unit) or not other_unit.unit_data:
			continue
		
		var other_unit_radius = get_unit_base_radius(other_unit.unit_data)
		var other_unit_pos = other_unit.global_position
		
		# Calculate distance between unit centers
		var distance = target_pos.distance_to(other_unit_pos)
		
		# Calculate minimum safe distance (base-to-base contact)
		var min_safe_distance = moving_unit_radius + other_unit_radius
		
		# If units would be too close, adjust the position
		if distance < min_safe_distance:
			# Calculate direction from other unit to target
			var direction = (target_pos - other_unit_pos).normalized()
			
			# If units are at the same position, use a default direction
			if direction.length() < 0.001:
				direction = Vector3(1, 0, 0)  # Default to right
			
			# Calculate new position that maintains required distance
			var safe_pos = other_unit_pos + direction * min_safe_distance
			
			# Keep the y coordinate from the original target
			safe_pos.y = target_pos.y
			
			# Update adjusted position (use the closest safe position)
			if adjusted_pos == target_pos:
				adjusted_pos = safe_pos
			else:
				# If we already adjusted for another unit, use the position that's closest to original target
				var current_distance = adjusted_pos.distance_to(target_pos)
				var new_distance = safe_pos.distance_to(target_pos)
				if new_distance < current_distance:
					adjusted_pos = safe_pos
	
	return adjusted_pos
