class_name ChargePhase
extends RefCounted

signal charge_completed(unit: Unit3D, distance: float)
signal charge_failed(unit: Unit3D)

var is_charge_dragging: bool = false
var drag_start_pos: Vector3
var movement_preview: CSGBox3D = null
var floating_text: Label3D = null
var charge_movement_data: Dictionary = {}
var charge_roll_results: Dictionary = {}
var charging_units: Array[Unit3D] = []
var charge_range_indicators: Array[CSGCylinder3D] = []

var battlefield: Node3D
var camera: Camera3D
var unit_3d_instances: Array[Unit3D]

func _init():
	pass

func start_charge_roll(unit: Unit3D) -> bool:
	if unit.unit_data.has_charged:
		print("Unit has already charged this turn: ", unit.unit_data.unit_name)
		return false
	
	var charge_roll = _roll_dice(2, 0)
	var charge_result = charge_roll[0] + charge_roll[1]
	
	print("🎲 %s charge roll: %d + %d = %d" % [unit.unit_data.unit_name, charge_roll[0], charge_roll[1], charge_result])
	
	charge_roll_results[unit.unit_data.unit_name] = charge_result
	
	if not charging_units.has(unit):
		charging_units.append(unit)
	
	charge_movement_data[unit.unit_data.unit_name] = {
		"charge_roll": charge_result,
		"movement_used": 0.0,
		"start_position": unit.global_position,
		"current_position": unit.global_position,
		"is_within_0_5_of_enemy": false
	}
	
	print("✅ %s can move up to %d inches to charge!" % [unit.unit_data.unit_name, charge_result])
	return true

func start_charge_movement_drag(selected_unit: Unit3D) -> bool:
	if not selected_unit or not charge_movement_data.has(selected_unit.unit_data.unit_name):
		print("Cannot start charge movement drag - missing unit or charge data")
		return false
	
	is_charge_dragging = true
	drag_start_pos = selected_unit.global_position
	
	_create_movement_preview()
	_create_floating_text()
	
	print("Started charge movement drag for: ", selected_unit.unit_data.unit_name)
	return true

func update_charge_movement_drag(selected_unit: Unit3D, mouse_pos: Vector2) -> void:
	if not selected_unit or not is_charge_dragging or not charge_movement_data.has(selected_unit.unit_data.unit_name):
		return
	
	var target_pos = _get_mouse_intersection_point(mouse_pos)
	if not target_pos:
		return
	
	var total_distance_from_start = drag_start_pos.distance_to(target_pos)
	var unit_id = selected_unit.unit_data.unit_name
	var charge_data = charge_movement_data[unit_id]
	var max_charge_distance = charge_data.charge_roll
	
	# Clamp movement to charge roll distance
	if total_distance_from_start > max_charge_distance:
		var direction = (target_pos - drag_start_pos).normalized()
		target_pos = drag_start_pos + direction * max_charge_distance
		total_distance_from_start = max_charge_distance
	
	# Check for collisions with other units
	var collision_adjusted_pos = _check_unit_collisions(selected_unit, target_pos)
	if collision_adjusted_pos != target_pos:
		target_pos = collision_adjusted_pos
		total_distance_from_start = drag_start_pos.distance_to(target_pos)
	
	_update_movement_preview(target_pos, collision_adjusted_pos != target_pos)
	_update_floating_text(total_distance_from_start, max_charge_distance)

func end_charge_movement_drag(selected_unit: Unit3D) -> void:
	if not selected_unit or not is_charge_dragging or not charge_movement_data.has(selected_unit.unit_data.unit_name):
		return
	
	is_charge_dragging = false
	
	if movement_preview and movement_preview.visible:
		var final_pos = movement_preview.global_position
		var current_pos = selected_unit.global_position
		var distance_moved = current_pos.distance_to(final_pos)
		
		if distance_moved > 0.1:
			var unit_id = selected_unit.unit_data.unit_name
			var charge_data = charge_movement_data[unit_id]
			
			selected_unit.move_to_position(final_pos)
			charge_data.movement_used = distance_moved
			charge_data.current_position = final_pos
			
			print("Moved %s: %.1f inches (Charge roll: %d)" % [
				selected_unit.unit_data.unit_name,
				distance_moved,
				charge_data.charge_roll
			])
			
			_check_charge_success(selected_unit)
	
	_cleanup_movement_visuals()

func check_charge_success(unit: Unit3D) -> bool:
	var unit_id = unit.unit_data.unit_name
	var charge_data = charge_movement_data[unit_id]
	
	print("🔍 Checking charge success for %s at position %s" % [unit.unit_data.unit_name, unit.global_position])
	
	for enemy_unit in unit_3d_instances:
		if not is_instance_valid(enemy_unit) or not enemy_unit.unit_data:
			continue
		
		if enemy_unit.unit_data.player_owner != unit.unit_data.player_owner:
			var base_distance = _get_base_to_base_distance(unit, enemy_unit)
			print("  📏 Base-to-base distance to %s: %.2f inches" % [enemy_unit.unit_data.unit_name, base_distance])
			
			if base_distance >= 0.0 and base_distance <= 0.5:
				charge_data.is_within_0_5_of_enemy = true
				print("✅ %s successfully charged and is within 0.5\" of %s!" % [
					unit.unit_data.unit_name,
					enemy_unit.unit_data.unit_name
				])
				charge_completed.emit(unit, charge_data.movement_used)
				return true
			elif base_distance < 0.0:
				print("❌ %s is overlapping with %s - move units apart!" % [
					unit.unit_data.unit_name,
					enemy_unit.unit_data.unit_name
				])
			else:
				print("❌ %s is %.2f\" from %s (need ≤0.5\")" % [
					unit.unit_data.unit_name,
					base_distance,
					enemy_unit.unit_data.unit_name
				])
	
	charge_data.is_within_0_5_of_enemy = false
	print("❌ %s is not within 0.5\" of any enemy unit" % unit.unit_data.unit_name)
	charge_failed.emit(unit)
	return false

func show_charge_range_indicators(current_player: int) -> void:
	_clear_charge_range_indicators()
	
	print("🔍 Creating charge range indicators for non-active player units...")
	
	var indicators_created = 0
	for unit in unit_3d_instances:
		if not is_instance_valid(unit) or not unit.unit_data:
			continue
		
		if unit.unit_data.player_owner == current_player:
			continue
		
		_create_charge_range_indicator(unit)
		indicators_created += 1
	
	print("✅ Created %d charge range indicators" % indicators_created)

func clear_failed_charges() -> void:
	print("🧹 Clearing failed charges...")
	
	var successful_charges: Array[Unit3D] = []
	
	for unit in charging_units:
		if not is_instance_valid(unit):
			print("  ⚠️ Removing invalid unit")
			continue
		
		if not charge_movement_data.has(unit.unit_data.unit_name):
			print("  ⚠️ Removing %s - no charge data" % unit.unit_data.unit_name)
			continue
		
		var charge_data = charge_movement_data[unit.unit_data.unit_name]
		if charge_data.is_within_0_5_of_enemy:
			print("  ✅ Keeping %s - successful charge" % unit.unit_data.unit_name)
			successful_charges.append(unit)
		else:
			print("  ❌ Removing %s - failed charge" % unit.unit_data.unit_name)
			charge_movement_data.erase(unit.unit_data.unit_name)
			charge_roll_results.erase(unit.unit_data.unit_name)
	
	charging_units = successful_charges
	print("🧹 Cleared failed charges. %d successful charges remain." % charging_units.size())

func can_advance_from_charge_phase() -> bool:
	if charging_units.is_empty():
		print("✅ No units charged - advancing to Combat Phase")
		return true
	
	print("🔍 Checking %d charging units for advancement..." % charging_units.size())
	
	var valid_charging_units: Array[Unit3D] = []
	for unit in charging_units:
		if not is_instance_valid(unit):
			print("⚠️ Removing invalid unit from charging array")
			continue
		
		if not charge_movement_data.has(unit.unit_data.unit_name):
			print("⚠️ Removing unit without charge data: %s" % unit.unit_data.unit_name)
			continue
		
		valid_charging_units.append(unit)
	
	charging_units = valid_charging_units
	
	if charging_units.is_empty():
		print("✅ No valid charging units - advancing to Combat Phase")
		return true
	
	print("🔍 Checking %d valid charging units for advancement..." % charging_units.size())
	
	for unit in charging_units:
		var charge_data = charge_movement_data[unit.unit_data.unit_name]
		print("  📋 %s: is_within_0_5_of_enemy = %s" % [unit.unit_data.unit_name, charge_data.is_within_0_5_of_enemy])
		
		if not charge_data.is_within_0_5_of_enemy:
			print("❌ Cannot advance: %s is not within 0.5\" of any enemy" % unit.unit_data.unit_name)
			return false
	
	print("✅ All charging units are within 0.5\" of enemies - can advance to Combat Phase")
	return true

func cleanup() -> void:
	_cleanup_movement_visuals()
	_clear_charge_range_indicators()
	charge_movement_data.clear()
	charge_roll_results.clear()
	charging_units.clear()

# Private helper methods
func _roll_dice(num_dice: int, target_value: int) -> Array[int]:
	var rolls: Array[int] = []
	for i in range(num_dice):
		rolls.append(randi() % 6 + 1)
	return rolls

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
	
	print("    Center distance: %.2f, Base1 radius: %.2f, Base2 radius: %.2f, Base-to-base: %.2f" % [
		center_distance, base_radius1, base_radius2, base_distance
	])
	
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

func _create_movement_preview() -> void:
	if movement_preview:
		movement_preview.queue_free()
	
	movement_preview = CSGBox3D.new()
	movement_preview.size = Vector3(0.5, 0.1, 0.5)
	
	var preview_material = StandardMaterial3D.new()
	preview_material.albedo_color = Color(1, 1, 0, 0.7)
	preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	movement_preview.material = preview_material
	
	movement_preview.visible = false
	battlefield.add_child(movement_preview)

func _create_floating_text() -> void:
	if floating_text:
		floating_text.queue_free()
	
	floating_text = Label3D.new()
	floating_text.text = "0.0\""
	floating_text.font_size = 32
	floating_text.outline_size = 3
	floating_text.outline_modulate = Color(0, 0, 0, 1)
	floating_text.modulate = Color(0, 1, 1, 1)  # Cyan for charge
	floating_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	floating_text.visible = false
	
	battlefield.add_child(floating_text)

func _update_movement_preview(target_pos: Vector3, has_collision: bool) -> void:
	if movement_preview:
		movement_preview.global_position = target_pos
		movement_preview.visible = true
		
		if has_collision:
			movement_preview.material.albedo_color = Color(1, 0, 0, 0.8)
		else:
			movement_preview.material.albedo_color = Color(1, 1, 0, 0.7)

func _update_floating_text(distance: float, max_distance: float) -> void:
	if floating_text:
		floating_text.text = "%.1f\" / %d\" CHARGE" % [distance, max_distance]
		
		if distance >= max_distance:
			floating_text.modulate = Color(1, 0, 0, 1)
		elif distance >= max_distance * 0.8:
			floating_text.modulate = Color(1, 0.5, 0, 1)
		else:
			floating_text.modulate = Color(0, 1, 1, 1)
		
		floating_text.visible = true

func _create_charge_range_indicator(unit: Unit3D) -> void:
	var unit_radius = _get_unit_base_radius(unit.unit_data)
	var charge_range = 0.5
	
	var indicator = CSGCylinder3D.new()
	indicator.radius = unit_radius + charge_range
	indicator.height = 0.5
	
	var indicator_material = StandardMaterial3D.new()
	indicator_material.albedo_color = Color(1, 0, 1, 0.9)
	indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	indicator.material = indicator_material
	
	# Attach to the unit as a child so it moves with the unit
	indicator.global_position = unit.global_position
	indicator.global_position.y = 0.0
	unit.add_child(indicator)
	
	charge_range_indicators.append(indicator)
	
	print("Created charge range indicator for %s (0.5\" range from base edge, total radius: %.2f\")" % [unit.unit_data.unit_name, unit_radius + charge_range])

func _clear_charge_range_indicators() -> void:
	for indicator in charge_range_indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	charge_range_indicators.clear()

func _cleanup_movement_visuals() -> void:
	if movement_preview:
		movement_preview.queue_free()
		movement_preview = null
	
	if floating_text:
		floating_text.visible = false

func _check_charge_success(unit: Unit3D) -> void:
	check_charge_success(unit)



