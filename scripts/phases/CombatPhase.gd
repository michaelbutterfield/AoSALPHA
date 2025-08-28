class_name CombatPhase
extends RefCounted

signal pile_in_completed(unit: Unit3D, distance: float)
signal attack_resolved(attacker: Unit3D, target: Unit3D, damage: int)

var is_pile_in_dragging: bool = false
var drag_start_pos: Vector3
var pile_in_preview: CSGBox3D = null
var floating_text: Label3D = null
var pile_in_data: Dictionary = {}
var combat_units: Array[Unit3D] = []
var combat_targets: Dictionary = {}

var battlefield: Node3D
var camera: Camera3D
var unit_3d_instances: Array[Unit3D]

func _init(battlefield_node: Node3D, camera_node: Camera3D, units: Array[Unit3D]):
	battlefield = battlefield_node
	camera = camera_node
	unit_3d_instances = units

func find_combat_units(current_player: int) -> void:
	combat_units.clear()
	combat_targets.clear()
	
	# Find all units within 3" of enemy units (pile-in range)
	for unit in unit_3d_instances:
		if unit.unit_data.player_owner == current_player:
			var can_pile_in = false
			var nearby_enemies: Array[Unit3D] = []
			
			# Check if this unit is within 3" of any enemy
			for enemy in unit_3d_instances:
				if enemy.unit_data.player_owner != current_player:
					var distance = _get_base_to_base_distance(unit, enemy)
					if distance <= 3.0:  # 3" pile-in range
						can_pile_in = true
						nearby_enemies.append(enemy)
			
			if can_pile_in:
				combat_units.append(unit)
				combat_targets[unit.unit_data.unit_name] = nearby_enemies
				print("✅ %s can pile in (within 3\" of enemies)" % unit.unit_data.unit_name)
			else:
				print("❌ %s cannot pile in (not within 3\" of enemies)" % unit.unit_data.unit_name)

func show_pile_in_indicators() -> void:
	# Create visual indicators for units that can pile in
	for unit in combat_units:
		_create_pile_in_indicator(unit)

func start_pile_in_movement(unit: Unit3D) -> bool:
	print("🎯 Starting pile-in movement for %s" % unit.unit_data.unit_name)
	
	# Initialize pile-in data
	if not pile_in_data.has(unit.unit_data.unit_name):
		pile_in_data[unit.unit_data.unit_name] = {}
	
	pile_in_data[unit.unit_data.unit_name]["start_position"] = unit.global_position
	pile_in_data[unit.unit_data.unit_name]["has_piled_in"] = false
	
	print("📏 %s can pile in up to 3\" towards enemies" % unit.unit_data.unit_name)
	
	# Start pile-in movement drag
	return _start_pile_in_drag(unit)

func start_pile_in_drag(unit: Unit3D) -> bool:
	if not unit:
		return false
	
	is_pile_in_dragging = true
	drag_start_pos = unit.global_position
	
	_create_pile_in_preview()
	
	print("Started pile-in drag for: ", unit.unit_data.unit_name)
	return true

func update_pile_in_drag(selected_unit: Unit3D, mouse_pos: Vector2) -> void:
	if not selected_unit or not is_pile_in_dragging:
		return
	
	var target_pos = _get_mouse_intersection_point(mouse_pos)
	if not target_pos:
		return
	
	var total_distance_from_start = drag_start_pos.distance_to(target_pos)
	
	# Clamp movement to 3" pile-in limit
	if total_distance_from_start > 3.0:
		var direction = (target_pos - drag_start_pos).normalized()
		target_pos = drag_start_pos + direction * 3.0
		total_distance_from_start = 3.0
	
	# Check for collisions with other units
	var collision_adjusted_pos = _check_unit_collisions(selected_unit, target_pos)
	if collision_adjusted_pos != target_pos:
		target_pos = collision_adjusted_pos
	
	# Update preview position
	if pile_in_preview:
		pile_in_preview.global_position = target_pos
	
	# Update floating text
	_update_floating_text_pile_in(total_distance_from_start)

func end_pile_in_drag(selected_unit: Unit3D) -> void:
	if not selected_unit or not is_pile_in_dragging:
		return
	
	is_pile_in_dragging = false
	
	# Get final position from preview
	var final_pos = selected_unit.global_position
	if pile_in_preview:
		final_pos = pile_in_preview.global_position
	
	# Move unit to final position
	selected_unit.global_position = final_pos
	
	# Mark unit as having piled in
	var unit_id = selected_unit.unit_data.unit_name
	if pile_in_data.has(unit_id):
		pile_in_data[unit_id]["has_piled_in"] = true
		pile_in_data[unit_id]["final_position"] = final_pos
	
	# Clean up preview
	if pile_in_preview:
		pile_in_preview.queue_free()
		pile_in_preview = null
	
	# Clean up floating text
	if floating_text:
		floating_text.queue_free()
		floating_text = null
	
	print("✅ %s piled in to position %s" % [selected_unit.unit_data.unit_name, str(final_pos)])
	
	# Check if unit is now within 1" of enemies for attacking
	_check_attack_range_after_pile_in(selected_unit)

func check_attack_range_after_pile_in(unit: Unit3D) -> bool:
	if not unit:
		return false
	
	var can_attack = false
	for enemy in unit_3d_instances:
		if enemy.unit_data.player_owner != unit.unit_data.player_owner:
			var distance = _get_base_to_base_distance(unit, enemy)
			if distance <= 1.0:  # 1" attack range
				can_attack = true
				print("✅ %s can now attack %s (%.1f\" away)" % [unit.unit_data.unit_name, enemy.unit_data.unit_name, distance])
	
	if not can_attack:
		print("❌ %s piled in but is not within 1\" of any enemies" % unit.unit_data.unit_name)
	
	return can_attack

func can_attack_target(attacker: Unit3D, target: Unit3D) -> bool:
	var distance = _get_base_to_base_distance(attacker, target)
	return distance <= 1.0  # 1" attack range

func resolve_attack(attacker: Unit3D, target: Unit3D) -> int:
	# Calculate attack results with dice rolls
	var hit_rolls: Array[int] = []
	var wound_rolls: Array[int] = []
	var hits = 0
	var wounds = 0
	var damage_dealt = 0
	
	# Roll to hit
	print("🎲 Rolling to hit (%d+ needed):" % attacker.unit_data.to_hit)
	for i in range(attacker.unit_data.attacks):
		var roll = randi() % 6 + 1
		hit_rolls.append(roll)
		if roll >= attacker.unit_data.to_hit:
			hits += 1
			print("  Roll %d: %d ✅ HIT!" % [i + 1, roll])
		else:
			print("  Roll %d: %d ❌ MISS" % [i + 1, roll])
	
	# Roll to wound
	if hits > 0:
		print("🎲 Rolling to wound (%d+ needed):" % attacker.unit_data.to_wound)
		for i in range(hits):
			var roll = randi() % 6 + 1
			wound_rolls.append(roll)
			if roll >= attacker.unit_data.to_wound:
				wounds += 1
				print("  Roll %d: %d ✅ WOUND!" % [i + 1, roll])
			else:
				print("  Roll %d: %d ❌ FAILED" % [i + 1, roll])
	
	# Apply damage
	for i in range(wounds):
		damage_dealt += attacker.unit_data.damage
	
	# Show dice results
	_show_dice_results("Combat Attack", hit_rolls, wound_rolls, hits, wounds, damage_dealt)
	
	# Apply damage to target
	if damage_dealt > 0:
		target.unit_data.take_damage(damage_dealt)
		print("💥 Final Result: %d hits, %d wounds, %d damage dealt!" % [hits, wounds, damage_dealt])
		
		# Check if unit died and remove it
		if target.unit_data.current_wounds <= 0:
			print("💀 Unit destroyed: ", target.unit_data.unit_name)
			unit_3d_instances.erase(target)
			target.queue_free()
	else:
		print("💥 Final Result: %d hits, %d wounds, 0 damage dealt" % [hits, wounds])
	
	attack_resolved.emit(attacker, target, damage_dealt)
	return damage_dealt

func cleanup() -> void:
	_cleanup_pile_in_visuals()
	_clear_pile_in_indicators()
	pile_in_data.clear()
	combat_units.clear()
	combat_targets.clear()

# Private helper methods
func _get_mouse_intersection_point(mouse_pos: Vector2) -> Vector3:
	var plane = Plane(Vector3(0, 1, 0), 0)
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var intersection = plane.intersects_ray(from, to)
	if intersection:
		intersection.y = 0
		return intersection
	return Vector3.ZERO

func _check_unit_collisions(moving_unit: Unit3D, target_pos: Vector3) -> Vector3:
	# Simplified collision check - can be expanded later
	return target_pos

func _get_base_to_base_distance(unit1: Unit3D, unit2: Unit3D) -> float:
	var pos1 = unit1.global_position
	var pos2 = unit2.global_position
	
	var base_radius1 = _get_unit_base_radius(unit1.unit_data)
	var base_radius2 = _get_unit_base_radius(unit2.unit_data)
	
	var center_distance = pos1.distance_to(pos2)
	var base_distance = center_distance - base_radius1 - base_radius2
	
	if base_distance < 0:
		print("    WARNING: Bases are overlapping! Distance: %.2f" % base_distance)
		return 999.0
	
	return base_distance

func _get_unit_base_radius(unit_data: Unit) -> float:
	match unit_data.unit_type:
		"Infantry":
			return 0.5
		"Hero":
			return 0.75
		"Cavalry":
			return 1.0
		"Monster":
			return 1.75
		"War Machine":
			return 1.2
		_:
			return 0.5

func _create_pile_in_indicator(unit: Unit3D) -> void:
	# Create a visual indicator showing this unit can pile in
	var indicator = CSGCylinder3D.new()
	indicator.radius = 3.0  # 3" pile-in range
	indicator.height = 0.1
	indicator.global_position = unit.global_position
	indicator.global_position.y = 0.05  # Just above the ground
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GREEN
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.3
	indicator.material = material
	
	# Add to the scene as child of unit so it moves with the unit
	unit.add_child(indicator)
	
	# Store reference for cleanup
	if not pile_in_data.has(unit.unit_data.unit_name):
		pile_in_data[unit.unit_data.unit_name] = {}
	pile_in_data[unit.unit_data.unit_name]["indicator"] = indicator
	
	print("📏 Pile-in indicator created for %s (3\" range)" % unit.unit_data.unit_name)

func _clear_pile_in_indicators() -> void:
	for unit_name in pile_in_data:
		if pile_in_data[unit_name].has("indicator"):
			var indicator = pile_in_data[unit_name]["indicator"]
			if indicator and is_instance_valid(indicator):
				indicator.queue_free()
	pile_in_data.clear()

func _start_pile_in_drag(unit: Unit3D) -> bool:
	return start_pile_in_drag(unit)

func _create_pile_in_preview() -> void:
	if pile_in_preview:
		pile_in_preview.queue_free()
	
	pile_in_preview = CSGBox3D.new()
	pile_in_preview.size = Vector3(0.5, 0.5, 0.5)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.7
	pile_in_preview.material = material
	
	battlefield.add_child(pile_in_preview)

func _update_floating_text_pile_in(distance: float) -> void:
	if floating_text:
		floating_text.text = "Pile-in: %.1f\"" % distance
		# Note: Mouse position would need to be passed from the main controller
		# For now, just update the text

func _check_attack_range_after_pile_in(unit: Unit3D) -> void:
	check_attack_range_after_pile_in(unit)

func _show_dice_results(attack_type: String, hit_rolls: Array[int], wound_rolls: Array[int], hits: int, wounds: int, damage: int) -> void:
	print("=== %s RESULTS ===" % attack_type.to_upper())
	print("Hit Rolls: %s" % str(hit_rolls) if not hit_rolls.is_empty() else "No hits")
	print("Wound Rolls: %s" % str(wound_rolls) if not wound_rolls.is_empty() else "No wounds")
	print("Final: %d hits, %d wounds, %d damage" % [hits, wounds, damage])
	print("==================")

func _cleanup_pile_in_visuals() -> void:
	if pile_in_preview:
		pile_in_preview.queue_free()
		pile_in_preview = null
	
	if floating_text:
		floating_text.visible = false
