class_name ShootingPhase
extends RefCounted

signal shooting_completed(attacker: Unit3D, target: Unit3D, damage: int)

var is_targeting: bool = false
var shooting_unit: Unit3D = null
var target_preview: CSGBox3D = null
var shooting_text: Label3D = null

var battlefield: Node3D
var camera: Camera3D
var unit_3d_instances: Array[Unit3D]

func _init(battlefield_node: Node3D, camera_node: Camera3D, units: Array[Unit3D]):
	battlefield = battlefield_node
	camera = camera_node
	unit_3d_instances = units

func start_shooting_targeting(selected_unit: Unit3D) -> bool:
	if not selected_unit:
		return false
	
	if selected_unit.unit_data.has_shot:
		print("Unit has already shot this turn: ", selected_unit.unit_data.unit_name)
		return false
	
	if selected_unit.unit_data.attacks <= 0:
		print("Unit has no ranged attacks: ", selected_unit.unit_data.unit_name)
		return false
	
	is_targeting = true
	shooting_unit = selected_unit
	
	_create_target_preview()
	_create_shooting_text()
	
	print("Started shooting targeting for: ", selected_unit.unit_data.unit_name)
	return true

func update_shooting_targeting(mouse_pos: Vector2) -> void:
	if not shooting_unit or not is_targeting:
		return
	
	var target_pos = _get_mouse_intersection_point(mouse_pos)
	if not target_pos:
		return
	
	# Find closest enemy unit
	var closest_enemy = _find_closest_enemy_unit(target_pos)
	var distance = 0.0
	
	if closest_enemy:
		distance = shooting_unit.global_position.distance_to(closest_enemy.global_position)
		target_pos = closest_enemy.global_position
	
	# Update target preview
	if target_preview:
		target_preview.global_position = target_pos
		target_preview.visible = true
	
	# Update shooting text
	_update_shooting_text(distance, closest_enemy)

func end_shooting_targeting() -> void:
	if not shooting_unit or not is_targeting:
		return
	
	is_targeting = false
	
	# Get target from preview
	if target_preview and target_preview.visible:
		var target_pos = target_preview.global_position
		var target_unit = _find_closest_enemy_unit(target_pos)
		
		if target_unit:
			_execute_shooting_attack(shooting_unit, target_unit)
	
	# Clean up shooting visuals
	_cleanup_shooting_visuals()
	
	shooting_unit = null

func _find_closest_enemy_unit(target_pos: Vector3) -> Unit3D:
	var closest_enemy: Unit3D = null
	var closest_distance = 999.0
	
	for unit_3d in unit_3d_instances:
		# Check if unit still exists and is valid
		if not is_instance_valid(unit_3d) or not unit_3d.unit_data:
			continue
		
		# Check if this is an enemy unit
		if unit_3d.unit_data.player_owner != shooting_unit.unit_data.player_owner:
			var distance = target_pos.distance_to(unit_3d.global_position)
			if distance < closest_distance and distance < 2.0:  # Within 2" targeting range
				closest_distance = distance
				closest_enemy = unit_3d
	
	return closest_enemy

func _execute_shooting_attack(attacker: Unit3D, target: Unit3D) -> void:
	var distance = attacker.global_position.distance_to(target.global_position)
	var max_range = 12.0  # Default shooting range
	
	# Check if target is in range
	if distance > max_range:
		print("Target out of range: %.1f\" > %d\"" % [distance, max_range])
		return
	
	# Calculate shooting results with dice rolls
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
	
	# Show dice results on screen
	_show_dice_results("Shooting Attack", hit_rolls, wound_rolls, hits, wounds, damage_dealt)
	
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
	
	# Mark unit as having shot
	attacker.unit_data.has_shot = true
	
	shooting_completed.emit(attacker, target, damage_dealt)

func cleanup() -> void:
	_cleanup_shooting_visuals()

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

func _create_target_preview() -> void:
	if target_preview:
		target_preview.queue_free()
	
	target_preview = CSGBox3D.new()
	target_preview.size = Vector3(0.5, 0.1, 0.5)
	
	var preview_material = StandardMaterial3D.new()
	preview_material.albedo_color = Color(1, 0, 0, 0.7)  # Semi-transparent red
	preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	target_preview.material = preview_material
	
	target_preview.visible = false
	battlefield.add_child(target_preview)

func _create_shooting_text() -> void:
	if shooting_text:
		shooting_text.queue_free()
	
	shooting_text = Label3D.new()
	shooting_text.text = "Targeting..."
	shooting_text.font_size = 24
	shooting_text.outline_size = 2
	shooting_text.outline_modulate = Color(0, 0, 0, 1)
	shooting_text.modulate = Color(1, 0, 0, 1)  # Red text
	shooting_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shooting_text.visible = false
	
	battlefield.add_child(shooting_text)

func _update_shooting_text(distance: float, target_unit: Unit3D) -> void:
	if not shooting_text:
		return
	
	if target_unit:
		shooting_text.text = "Target: %s (%.1f\")" % [target_unit.unit_data.unit_name, distance]
		shooting_text.modulate = Color(1, 0, 0, 1)  # Red when targeting
		
		# Position above target
		var target_pos = target_unit.global_position
		target_pos.y += 2.0
		shooting_text.global_position = target_pos
		shooting_text.visible = true
	else:
		shooting_text.text = "No target in range"
		shooting_text.modulate = Color(0.5, 0.5, 0.5, 1)  # Gray when no target
		shooting_text.visible = false

func _cleanup_shooting_visuals() -> void:
	if target_preview:
		target_preview.queue_free()
		target_preview = null
	
	if shooting_text:
		shooting_text.visible = false

func _show_dice_results(attack_type: String, hit_rolls: Array[int], wound_rolls: Array[int], hits: int, wounds: int, damage: int) -> void:
	print("=== %s RESULTS ===" % attack_type.to_upper())
	print("Hit Rolls: %s" % str(hit_rolls) if not hit_rolls.is_empty() else "No hits")
	print("Wound Rolls: %s" % str(wound_rolls) if not wound_rolls.is_empty() else "No wounds")
	print("Final: %d hits, %d wounds, %d damage" % [hits, wounds, damage])
	print("==================")

