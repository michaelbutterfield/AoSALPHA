extends Node3D
class_name Unit3D

# 3D representation of a unit on the battlefield
# Handles visual representation, selection, and movement

signal unit_clicked(unit: Unit3D)
signal unit_selected(unit: Unit3D)
signal unit_deselected(unit: Unit3D)

@onready var selection_ring: CSGCylinder3D = $SelectionRing
@onready var health_bar_fill: CSGBox3D = $HealthBar/HealthBarFill
@onready var unit_label: Label3D = $UnitLabel
@onready var model: CSGBox3D = $Model

var unit_data: Unit
var is_selected: bool = false
var is_hovered: bool = false
var movement_path: Array[Vector3] = []
var target_position: Vector3

# Movement animation
var is_moving: bool = false
var move_speed: float = 5.0  # units per second
var move_progress: float = 0.0
var start_position: Vector3

func _ready():
	# Connect mouse input
	set_process_input(true)
	set_process(true)
	
	# Connect collision body input
	var collision_body = $CollisionBody
	if collision_body:
		collision_body.input_event.connect(_on_collision_body_input_event)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if we clicked on this unit
		var camera = get_viewport().get_camera_3d()
		if !camera:
			return
			
		var mouse_pos = get_viewport().get_mouse_position()
		
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * 1000
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		
		if result and result.collider == $CollisionBody:
			print("Unit clicked: ", unit_data.unit_name if unit_data else "Unknown")
			unit_clicked.emit(self)

func _process(delta):
	# Update health bar
	if unit_data:
		update_health_bar()
	
	# Handle hover effects
	if selection_ring:
		if is_hovered and !is_selected:
			selection_ring.visible = true
			if selection_ring.material:
				selection_ring.material.albedo_color = Color(1, 1, 0, 0.5)  # Yellow hover
		else:
			selection_ring.visible = is_selected
	
	# Add floating effect for flying units
	if unit_data and unit_data.keywords.has("Fly"):
		var time = Time.get_time_dict_from_system()
		var float_offset = sin(time.second * 2.0) * 0.1  # Gentle floating motion
		model.transform.origin.y = 0.55 + float_offset  # Base position + float

func setup_unit(unit: Unit):
	unit_data = unit
	update_visuals()
	
	# Connect unit signals
	unit.unit_damaged.connect(_on_unit_damaged)
	unit.unit_destroyed.connect(_on_unit_destroyed)

func update_visuals():
	if !unit_data:
		return
	
	# Update label
	if unit_label:
		var label_text = unit_data.unit_name
		# Add Fly indicator if unit has Fly keyword
		if unit_data.keywords.has("Fly"):
			label_text += " (FLY)"
		unit_label.text = label_text
	
	# Update model color based on player
	if model:
		# Create material if it doesn't exist
		if !model.material:
			model.material = StandardMaterial3D.new()
		
		match unit_data.player_owner:
			1:  # Player 1 - Red
				model.material.albedo_color = Color(0.8, 0.2, 0.2, 1)
			2:  # Player 2 - Blue
				model.material.albedo_color = Color(0.2, 0.6, 1, 1)

func set_highlight_color(color: Color):
	# Update the selection ring color to show player ownership
	if selection_ring:
		if !selection_ring.material:
			selection_ring.material = StandardMaterial3D.new()
		selection_ring.material.albedo_color = color
		selection_ring.visible = true
	
	# Update model size and position based on unit type - SMALLER MODELS
	if model:
		match unit_data.unit_type:
			"Hero":
				model.size = Vector3(0.4, 0.5, 0.4)  # Smaller hero model
				model.transform.origin.y = 0.65  # On top of base (0.4 + 0.25)
			"Infantry":
				model.size = Vector3(0.25, 0.3, 0.25)  # Smaller infantry model
				model.transform.origin.y = 0.55  # On top of base (0.4 + 0.15)
			"Cavalry":
				model.size = Vector3(0.3, 0.35, 0.45)  # Smaller cavalry model
				model.transform.origin.y = 0.6  # On top of base (0.4 + 0.2)
			"Monster":
				model.size = Vector3(0.5, 0.6, 0.5)  # Smaller monster model
				model.transform.origin.y = 0.8  # On top of base (0.4 + 0.4)
			"War Machine":
				model.size = Vector3(0.4, 0.3, 0.5)  # Smaller war machine model
				model.transform.origin.y = 0.6  # On top of base (0.4 + 0.2)
			_:
				model.size = Vector3(0.25, 0.3, 0.25)  # Default small size
				model.transform.origin.y = 0.55  # On top of base (0.4 + 0.15)
	
	# Update base size based on unit type - PROPER AGE OF SIGMAR BASE SIZES (NEW SCALE)
	var base_radius = 0.5  # Start with infantry base
	match unit_data.unit_type:
		"Hero":
			base_radius = 0.75  # 40mm base (heroes) - 0.75 inch radius
		"Infantry":
			base_radius = 0.5  # 25mm base (infantry) - 0.5 inch radius
		"Cavalry":
			base_radius = 1.0  # 50mm base (cavalry) - 1 inch radius
		"Monster":
			base_radius = 1.75  # 90mm base (monsters) - 1.75 inch radius
		"War Machine":
			base_radius = 1.2  # 60mm base (war machines) - 1.2 inch radius
	
	# Update base visual
	if $Base:
		$Base.radius = base_radius
		$Base.height = 1.0  # Make base taller and more visible
		$Base.transform.origin.y = 0.5  # Position so base is clearly visible above table
		
		# Color the base to match player ownership
		if !$Base.material:
			$Base.material = StandardMaterial3D.new()
		
		match unit_data.player_owner:
			1:  # Player 1 - Red
				$Base.material.albedo_color = Color(0.8, 0.2, 0.2, 1)
			2:  # Player 2 - Blue
				$Base.material.albedo_color = Color(0.2, 0.6, 1, 1)
	
	# Update collision shape to match base radius (circular hit box)
	if $CollisionBody/CollisionShape:
		var collision_shape = $CollisionBody/CollisionShape
		if collision_shape.shape is CylinderShape3D:
			collision_shape.shape.radius = base_radius
			collision_shape.shape.height = 0.8  # Match base height
		else:
			# Create new cylinder shape if it doesn't exist
			var cylinder_shape = CylinderShape3D.new()
			cylinder_shape.radius = base_radius
			cylinder_shape.height = 0.8
			collision_shape.shape = cylinder_shape
	
	if selection_ring:
		selection_ring.radius = base_radius + 0.05
		selection_ring.transform.origin.y = -0.06  # Position below base

func select():
	is_selected = true
	if selection_ring:
		selection_ring.visible = true
		if selection_ring.material:
			selection_ring.material.albedo_color = Color(0, 1, 0, 0.7)  # Green selection
	unit_selected.emit(self)

func deselect():
	is_selected = false
	if selection_ring:
		selection_ring.visible = false
	unit_deselected.emit(self)

func move_to_position(target_pos: Vector3):
	if is_moving:
		return
	
	start_position = global_position
	target_position = target_pos
	is_moving = true
	move_progress = 0.0
	
	# Calculate movement distance
	var distance = start_position.distance_to(target_position)
	var move_time = distance / move_speed
	
	# Create movement animation
	var tween = create_tween()
	tween.tween_method(update_movement_position, 0.0, 1.0, move_time)
	tween.tween_callback(_on_movement_complete)

func update_movement_position(progress: float):
	global_position = start_position.lerp(target_position, progress)
	
	# Add a slight bounce effect
	var bounce_height = sin(progress * PI) * 0.5
	global_position.y += bounce_height

func _on_movement_complete():
	is_moving = false
	global_position = target_position
	
	# Update unit data position
	if unit_data:
		unit_data.position = Vector2i(round(global_position.x), round(global_position.z))

func update_health_bar():
	if !unit_data or !health_bar_fill:
		return
	
	var health_percentage = float(unit_data.current_wounds) / float(unit_data.max_wounds)
	health_bar_fill.size.x = health_percentage
	
	# Update health bar color
	if health_bar_fill.material:
		if health_percentage > 0.6:
			health_bar_fill.material.albedo_color = Color(0, 1, 0, 1)  # Green
		elif health_percentage > 0.3:
			health_bar_fill.material.albedo_color = Color(1, 1, 0, 1)  # Yellow
		else:
			health_bar_fill.material.albedo_color = Color(1, 0, 0, 1)  # Red

func _on_unit_damaged(unit: Unit, damage: int):
	update_health_bar()
	
	# Visual feedback for damage
	if model and model.material:
		var tween = create_tween()
		tween.tween_property(model, "material:albedo_color", Color(1, 0, 0, 1), 0.1)
		tween.tween_property(model, "material:albedo_color", model.material.albedo_color, 0.1)

func _on_unit_destroyed(unit: Unit):
	# Visual feedback for unit destruction
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	tween.tween_callback(queue_free)

func get_distance_to(other_unit: Unit3D) -> float:
	return global_position.distance_to(other_unit.global_position)

func get_distance_inches_to(other_unit: Unit3D) -> float:
	# Convert game units to inches (assuming 1 game unit = 1 inch)
	return get_distance_to(other_unit)

func show_movement_range():
	# Show movement range visually
	# This could be implemented with a transparent cylinder or sphere
	pass

func hide_movement_range():
	# Hide movement range
	pass

func _on_mouse_entered():
	is_hovered = true

func _on_mouse_exited():
	is_hovered = false

func _on_collision_body_input_event(camera: Camera3D, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Unit clicked via collision body: ", unit_data.unit_name if unit_data else "Unknown")
		unit_clicked.emit(self)
