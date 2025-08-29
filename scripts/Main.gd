extends Node3D

# Main game controller for Age of Sigmar 3D
class_name Main

signal turn_changed(turn_number: int, player: int)
signal unit_selected(unit: Unit)
signal game_state_changed(state: GameState)

enum GameState {
	SETUP,
	HERO_PHASE,
	MOVEMENT_PHASE,
	SHOOTING_PHASE,
	CHARGE_PHASE,
	COMBAT_PHASE,
	BATTLESHOCK_PHASE,
	GAME_END
}

# UI References
@onready var game_board: Node3D = $GameBoard
@onready var battlefield: Node3D = $GameBoard/Battlefield
@onready var turn_info: Label = $UI/TurnInfo
@onready var unit_info_label: Label = $UI/UnitInfo/UnitInfoLabel
@onready var distance_label: Label = $UI/DistanceLabel

# Game State
var current_state: GameState = GameState.SETUP
var current_turn: int = 1
var current_player: int = 1
var total_players: int = 2

# Core Systems
var game_rules: GameRules
var unit_manager: UnitManager
var board_manager: BoardManager

# 3D Unit Management
var unit_3d_instances: Array[Unit3D] = []
var selected_unit_3d: Unit3D = null
var hovered_unit_3d: Unit3D = null

# Phase Controllers
var movement_phase_script = preload("res://scripts/phases/MovementPhase.gd")
var movement_phase: RefCounted
var shooting_phase_script = preload("res://scripts/phases/ShootingPhase.gd")
var shooting_phase: RefCounted
var charge_phase_script = preload("res://scripts/phases/ChargePhase.gd")
var charge_phase: RefCounted
var combat_phase_script = preload("res://scripts/phases/CombatPhase.gd")
var combat_phase: RefCounted

# Utility Controllers
var camera_controller_script = preload("res://scripts/utils/CameraController.gd")
var camera_controller: RefCounted
var input_handler_script = preload("res://scripts/utils/InputHandler.gd")
var input_handler: RefCounted
var unit_utils_script = preload("res://scripts/utils/UnitUtils.gd")

# Temporary variables for basic functionality
var is_dragging: bool = false
var is_charge_dragging: bool = false
var is_targeting: bool = false
var drag_start_pos: Vector3
var movement_preview: CSGBox3D = null
var floating_text: Label3D = null
var unit_movement_data: Dictionary = {}
var charge_movement_data: Dictionary = {}
var charge_roll_results: Dictionary = {}
var charging_units: Array[Unit3D] = []
var camera_speed: float = 10.0
var camera_rotation_speed: float = 2.0
var camera: Camera3D = null
var camera_position: Vector3 = Vector3(0, 15, 15)
var camera_rotation: Vector2 = Vector2(0, -30)

# Player Colors
var player_colors: Array[Color] = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]
var current_player_color: Color = Color.RED
var enemy_player_color: Color = Color.BLUE

func _ready() -> void:
	print("Age of Sigmar 4th Edition 3D - Game Starting...")
	setup_game_systems()
	start_new_game()
	setup_3d_environment()

func setup_game_systems() -> void:
	"""Initialize all core game systems"""
	game_rules = GameRules.new()
	unit_manager = UnitManager.new()
	board_manager = BoardManager.new()
	
	# Connect signals
	turn_changed.connect(_on_turn_changed)
	unit_selected.connect(_on_unit_selected)

func setup_3d_environment() -> void:
	"""Setup the 3D battlefield and controllers"""
	create_battlefield_grid()
	setup_camera_controls()
	setup_player_colors()

func create_battlefield_grid() -> void:
	"""Create a visual grid on the battlefield (60\"x44\")"""
	var grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = Color(0.3, 0.3, 0.3, 0.5)
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Create grid lines for 60"x44" board
	# Vertical lines (60" width, every 2")
	for i in range(-30, 31, 2):
		var line = CSGBox3D.new()
		line.size = Vector3(0.05, 0.05, 44)
		line.transform.origin = Vector3(i, 0.05, 0)
		line.material = grid_material
		battlefield.add_child(line)
		
		# Horizontal lines (44" depth, every 2")
		var line2 = CSGBox3D.new()
		line2.size = Vector3(60, 0.05, 0.05)
		line2.transform.origin = Vector3(0, 0.05, i)
		line2.material = grid_material
		battlefield.add_child(line2)

func setup_camera_controls() -> void:
	"""Initialize camera and input controllers"""
	camera = get_viewport().get_camera_3d()
	if camera:
		# Initialize utility controllers
		var camera_controller_instance = camera_controller_script.new()
		camera_controller_instance.camera = camera
		camera_controller = camera_controller_instance
		
		var input_handler_instance = input_handler_script.new()
		input_handler_instance.camera_controller = camera_controller_instance
		input_handler = input_handler_instance
		
		# Connect input signals
		input_handler.key_pressed.connect(_on_key_pressed)
		input_handler.mouse_button_pressed.connect(_on_mouse_button_pressed)
		input_handler.mouse_button_released.connect(_on_mouse_button_released)
		input_handler.mouse_motion.connect(_on_mouse_motion)
		
		print("Camera controls initialized")
		print("📷 Camera Controls:")
		print("  WASD - Move camera")
		print("  SPACE - Move camera up")
		print("  X - Move camera down")
		print("  Right Mouse + Drag - Rotate camera")
		print("  ENTER - Next phase")
	else:
		print("WARNING: No camera found!")
		# Create dummy controllers for testing
		camera_controller = camera_controller_script.new()
		input_handler = input_handler_script.new()

func setup_player_colors() -> void:
	"""Set player colors (Player 1 = Red, Player 2 = Blue)"""
	current_player_color = player_colors[0]  # Red for Player 1
	enemy_player_color = player_colors[1]    # Blue for Player 2
	print("Player 1 color: ", current_player_color)
	print("Player 2 color: ", enemy_player_color)

func start_new_game() -> void:
	"""Initialize a new game"""
	print("Starting new Age of Sigmar 3D game...")
	current_state = GameState.SETUP
	current_turn = 1
	current_player = 1
	
	# Setup the battlefield
	board_manager.setup_battlefield()
	
	# Setup units for both players
	setup_player_armies()
	
	# Create 3D unit instances
	create_3d_units()
	
	# Initialize phase controllers
	initialize_phase_controllers()
	
	# Start the first turn
	start_hero_phase()

func setup_player_armies() -> void:
	"""Setup player armies and place units on the board"""
	print("Setting up player armies...")
	unit_manager.create_sample_units()
	
	# Place units on the board
	for unit in unit_manager.all_units:
		board_manager.place_unit(unit, unit.position)

func create_3d_units() -> void:
	"""Create 3D unit instances for all units"""
	print("Creating 3D unit instances...")
	
	# Clear existing units
	for unit_3d in unit_3d_instances:
		unit_3d.queue_free()
	unit_3d_instances.clear()
	
	# Create 3D instances for each unit
	for unit in unit_manager.all_units:
		var unit_3d_scene = preload("res://scenes/Unit3D.tscn")
		var unit_3d = unit_3d_scene.instantiate() as Unit3D
		
		if unit_3d:
			# Setup the 3D unit
			unit_3d.setup_unit(unit)
			
			# Position the unit in 3D space
			var world_pos = Vector3(unit.position.x, 0, unit.position.y)
			unit_3d.global_position = world_pos
			
			# Add to battlefield
			battlefield.add_child(unit_3d)
			unit_3d_instances.append(unit_3d)
			
			# Connect signals
			unit_3d.unit_clicked.connect(_on_unit_3d_clicked)
			unit_3d.unit_selected.connect(_on_unit_3d_selected)
			unit_3d.unit_deselected.connect(_on_unit_3d_deselected)
			
			print("Created 3D unit: ", unit.unit_name, " at position: ", world_pos)
	
	print("Total 3D units created: ", unit_3d_instances.size())
	
	# Apply player color highlighting
	highlight_units_by_player()
	
	# Print unit ownership information
	print_unit_setup_info()

func initialize_phase_controllers() -> void:
	"""Initialize all phase controllers"""
	var camera = get_viewport().get_camera_3d()
	
	# Initialize MovementPhase
	var movement_phase_instance = movement_phase_script.new()
	movement_phase_instance.battlefield = battlefield
	movement_phase_instance.camera = camera
	movement_phase_instance.unit_instances = unit_3d_instances
	movement_phase = movement_phase_instance
	
	# Initialize ShootingPhase
	var shooting_phase_instance = shooting_phase_script.new()
	shooting_phase_instance.battlefield = battlefield
	shooting_phase_instance.camera = camera
	shooting_phase_instance.unit_3d_instances = unit_3d_instances
	shooting_phase = shooting_phase_instance
	
	# Initialize ChargePhase
	var charge_phase_instance = charge_phase_script.new()
	charge_phase_instance.battlefield = battlefield
	charge_phase_instance.camera = camera
	charge_phase_instance.unit_3d_instances = unit_3d_instances
	charge_phase = charge_phase_instance
	
	# Initialize CombatPhase
	var combat_phase_instance = combat_phase_script.new()
	combat_phase_instance.battlefield = battlefield
	combat_phase_instance.camera = camera
	combat_phase_instance.unit_3d_instances = unit_3d_instances
	combat_phase = combat_phase_instance
	
	# Connect phase signals
	movement_phase.movement_completed.connect(_on_movement_completed)
	movement_phase.movement_undo.connect(_on_movement_undo)
	shooting_phase.shooting_completed.connect(_on_shooting_completed)
	charge_phase.charge_completed.connect(_on_charge_completed)
	charge_phase.charge_failed.connect(_on_charge_failed)
	combat_phase.pile_in_completed.connect(_on_pile_in_completed)
	combat_phase.attack_resolved.connect(_on_attack_resolved)

func highlight_units_by_player() -> void:
	"""Highlight all units based on their player ownership"""
	for unit_3d in unit_3d_instances:
		if is_instance_valid(unit_3d) and unit_3d.unit_data:
			var highlight_color = current_player_color if unit_3d.unit_data.player_owner == 1 else enemy_player_color
			unit_3d.set_highlight_color(highlight_color)

func print_unit_setup_info() -> void:
	"""Print unit setup information"""
	print("📋 Unit Setup:")
	print("  Player 1 (Red): ", unit_manager.get_units_for_player(1).size(), " units")
	for unit in unit_manager.get_units_for_player(1):
		print("    - ", unit.unit_name, " at position ", unit.position)
	print("  Player 2 (Blue): ", unit_manager.get_units_for_player(2).size(), " units")
	for unit in unit_manager.get_units_for_player(2):
		print("    - ", unit.unit_name, " at position ", unit.position)

# Phase Management Functions
func start_hero_phase() -> void:
	current_state = GameState.HERO_PHASE
	print("=== HERO PHASE ===")
	print("Player ", current_player, " - Cast spells and use command abilities")
	update_ui()

func start_movement_phase() -> void:
	current_state = GameState.MOVEMENT_PHASE
	print("=== MOVEMENT PHASE ===")
	print("Player ", current_player, " - Move your units")
	update_ui()

func start_shooting_phase() -> void:
	current_state = GameState.SHOOTING_PHASE
	print("=== SHOOTING PHASE ===")
	print("Player ", current_player, " - Shoot with ranged weapons")
	update_ui()

func start_charge_phase() -> void:
	current_state = GameState.CHARGE_PHASE
	print("=== CHARGE PHASE ===")
	print("Player ", current_player, " - Charge into combat")
	print("💡 TIP: Click your units to roll charge dice (2D6), or press 'C' to clear failed charges")
	print("💡 TIP: Units must end within 0.5\" of enemies to successfully charge")
	print("💡 TIP: Charge distance is determined by dice roll - move up to that distance")
	
	# Show charge range indicators (temporarily disabled)
	# charge_phase.show_charge_range_indicators(current_player)
	
	update_ui()

func start_combat_phase() -> void:
	current_state = GameState.COMBAT_PHASE
	print("=== COMBAT PHASE ===")
	print("Player ", current_player, " - Fight in melee combat")
	
	# Find all units that can participate in combat (temporarily disabled)
	# combat_phase.find_combat_units(current_player)
	
	# Show pile-in indicators for eligible units (temporarily disabled)
	# combat_phase.show_pile_in_indicators()
	
	update_ui()

func start_battleshock_phase() -> void:
	current_state = GameState.BATTLESHOCK_PHASE
	print("=== BATTLESHOCK PHASE ===")
	print("Player ", current_player, " - Take battleshock tests")
	update_ui()

func end_turn() -> void:
	"""End the current turn and start the next one"""
	print("Ending turn for player ", current_player)
	
	if current_player < total_players:
		current_player += 1
	else:
		current_player = 1
		current_turn += 1
		print("=== TURN ", current_turn, " BEGINS ===")
	
	# Reset all units for new turn
	unit_manager.reset_all_units()
	
	# Clean up phase controllers
	cleanup_phase_controllers()
	
	turn_changed.emit(current_turn, current_player)
	start_hero_phase()

func advance_phase() -> void:
	"""Advance to the next phase"""
	match current_state:
		GameState.HERO_PHASE:
			start_movement_phase()
		GameState.MOVEMENT_PHASE:
			start_shooting_phase()
		GameState.SHOOTING_PHASE:
			start_charge_phase()
		GameState.CHARGE_PHASE:
			# Check if we can advance from charge phase (temporarily disabled)
			# if charge_phase.can_advance_from_charge_phase():
			# 	charge_phase.cleanup()
			# 	start_combat_phase()
			# else:
			# 	print("❌ Cannot advance: Some charging units are not within 0.5\" of enemies")
			start_combat_phase()
		GameState.COMBAT_PHASE:
			# combat_phase.cleanup()
			start_battleshock_phase()
		GameState.BATTLESHOCK_PHASE:
			end_turn()

func cleanup_phase_controllers() -> void:
	"""Clean up all phase controllers"""
	if movement_phase:
		movement_phase.cleanup()
	if shooting_phase:
		shooting_phase.cleanup()
	if charge_phase:
		charge_phase.cleanup()
	if combat_phase:
		combat_phase.cleanup()

# Input Handling Functions
func _input(event: InputEvent) -> void:
	"""Handle all input events"""
	if input_handler:
		input_handler.handle_input(event)

func _on_key_pressed(keycode: int) -> void:
	"""Handle key press events"""
	print("Key pressed: ", keycode)
	
	match keycode:
		KEY_ENTER:
			print("ENTER pressed - advancing phase")
			advance_phase()
		KEY_M:
			print("M pressed - testing movement")
			if selected_unit_3d and current_state == GameState.MOVEMENT_PHASE:
				test_unit_movement()
		KEY_Z:
			print("Z pressed - undoing movement")
			if selected_unit_3d and current_state == GameState.MOVEMENT_PHASE:
				movement_phase.undo_movement(selected_unit_3d)
		KEY_F:
			print("F pressed - finalizing movement")
			if selected_unit_3d and current_state == GameState.MOVEMENT_PHASE:
				movement_phase.finalize_movement(selected_unit_3d)
		KEY_C:
			print("C pressed - clearing failed charges")
			if current_state == GameState.CHARGE_PHASE:
				charge_phase.clear_failed_charges()

func _on_mouse_button_pressed(button_index: int, position: Vector2) -> void:
	"""Handle mouse button press events"""
	if button_index == MOUSE_BUTTON_LEFT:
		handle_left_mouse_press(position)

func _on_mouse_button_released(button_index: int, position: Vector2) -> void:
	"""Handle mouse button release events"""
	if button_index == MOUSE_BUTTON_LEFT:
		handle_left_mouse_release(position)

func _on_mouse_motion(delta: Vector2, position: Vector2) -> void:
	"""Handle mouse motion events"""
	handle_mouse_motion(position)

func handle_left_mouse_press(position: Vector2) -> void:
	"""Handle left mouse button press"""
	match current_state:
		GameState.MOVEMENT_PHASE:
			if selected_unit_3d:
				movement_phase.start_movement_drag(selected_unit_3d)
		GameState.SHOOTING_PHASE:
			if selected_unit_3d:
				shooting_phase.start_shooting_targeting(selected_unit_3d)
		GameState.CHARGE_PHASE:
			handle_charge_phase_click()
		GameState.COMBAT_PHASE:
			handle_combat_phase_click()

func handle_left_mouse_release(position: Vector2) -> void:
	"""Handle left mouse button release"""
	match current_state:
		GameState.MOVEMENT_PHASE:
			movement_phase.end_movement_drag(selected_unit_3d)
		GameState.SHOOTING_PHASE:
			shooting_phase.end_shooting_targeting()
		GameState.CHARGE_PHASE:
			charge_phase.end_charge_movement_drag(selected_unit_3d)
		GameState.COMBAT_PHASE:
			combat_phase.end_pile_in_drag(selected_unit_3d)

func handle_mouse_motion(position: Vector2) -> void:
	"""Handle mouse motion"""
	match current_state:
		GameState.MOVEMENT_PHASE:
			movement_phase.update_movement_drag(selected_unit_3d, position)
		GameState.SHOOTING_PHASE:
			shooting_phase.update_shooting_targeting(position)
		GameState.CHARGE_PHASE:
			charge_phase.update_charge_movement_drag(selected_unit_3d, position)
		GameState.COMBAT_PHASE:
			combat_phase.update_pile_in_drag(selected_unit_3d, position)

func handle_charge_phase_click() -> void:
	"""Handle clicks during charge phase"""
	# var clicked_unit = UnitUtils.get_clicked_unit(get_viewport().get_camera_3d(), input_handler.get_mouse_position(), unit_3d_instances)
	# if not clicked_unit:
	# 	return
	
	# print("Charge phase: Clicked on ", clicked_unit.unit_data.unit_name)
	
	# # Check if this is a friendly unit (potential charger)
	# if clicked_unit.unit_data.player_owner == current_player:
	# 	# Check if this unit has already charged this turn
	# 	if clicked_unit.unit_data.has_charged:
	# 		print("Unit has already charged this turn: ", clicked_unit.unit_data.unit_name)
	# 		return
		
	# 	# Start charge roll for this unit
	# 	if charge_phase.start_charge_roll(clicked_unit):
	# 		# Select this unit for movement
	# 		if selected_unit_3d and selected_unit_3d != clicked_unit:
	# 			selected_unit_3d.deselect()
	# 		selected_unit_3d = clicked_unit
	# 		clicked_unit.select()
			
	# 		# Automatically start charge movement drag after rolling
	# 		charge_phase.start_charge_movement_drag(clicked_unit)
	# 		print("Started charge movement drag for %s" % clicked_unit.unit_data.unit_name)
	var clicked_unit = unit_utils_script.get_clicked_unit(get_viewport().get_camera_3d(), input_handler.get_mouse_position(), unit_3d_instances)
	if not clicked_unit:
		return
	
	print("Charge phase: Clicked on ", clicked_unit.unit_data.unit_name)
	
	# Check if this is a friendly unit (potential charger)
	if clicked_unit.unit_data.player_owner == current_player:
		# Check if this unit has already charged this turn
		if clicked_unit.unit_data.has_charged:
			print("Unit has already charged this turn: ", clicked_unit.unit_data.unit_name)
			return
			
		# Start charge roll for this unit
		if charge_phase.start_charge_roll(clicked_unit):
			# Select this unit for movement
			if selected_unit_3d and selected_unit_3d != clicked_unit:
				selected_unit_3d.deselect()
			selected_unit_3d = clicked_unit
			clicked_unit.select()
				
			# Automatically start charge movement drag after rolling
			charge_phase.start_charge_movement_drag(clicked_unit)
			print("Started charge movement drag for %s" % clicked_unit.unit_data.unit_name)

func handle_combat_phase_click() -> void:
	"""Handle clicks during combat phase (temporarily disabled)"""
	# var clicked_unit = UnitUtils.get_clicked_unit(get_viewport().get_camera_3d(), input_handler.get_mouse_position(), unit_3d_instances)
	# if not clicked_unit:
	# 	return
	
	# print("Combat phase: Clicked on ", clicked_unit.unit_data.unit_name)
	
	# # Check if this is a friendly unit that can pile in
	# if clicked_unit.unit_data.player_owner == current_player:
	# 	if combat_phase.combat_units.has(clicked_unit):
	# 		# Start pile-in movement for this unit
	# 		combat_phase.start_pile_in_movement(clicked_unit)
	# 	else:
	# 		print("❌ %s cannot pile in (not within 3\" of enemies)" % clicked_unit.unit_data.unit_name)
	
	# # Check if this is an enemy unit (for attack targeting)
	# elif clicked_unit.unit_data.player_owner != current_player:
	# 	if selected_unit_3d and selected_unit_3d.unit_data.player_owner == current_player:
	# 		if combat_phase.can_attack_target(selected_unit_3d, clicked_unit):
	# 			print("✅ %s can attack %s (within 1\")" % [selected_unit_3d.unit_data.unit_name, clicked_unit.unit_data.unit_name])
	# 		# 	combat_phase.resolve_attack(selected_unit_3d, clicked_unit)
	# 		else:
	# 			var distance = unit_utils_script.get_base_to_base_distance(selected_unit_3d, clicked_unit)
	# 			print("❌ %s cannot attack %s (%.1f\" away, need ≤1\")" % [selected_unit_3d.unit_data.unit_name, clicked_unit.unit_data.unit_name, distance])
	var clicked_unit = unit_utils_script.get_clicked_unit(get_viewport().get_camera_3d(), input_handler.get_mouse_position(), unit_3d_instances)
	if not clicked_unit:
		return
	
	print("Combat phase: Clicked on ", clicked_unit.unit_data.unit_name)
	
	# Check if this is a friendly unit that can pile in
	if clicked_unit.unit_data.player_owner == current_player:
		if combat_phase.combat_units.has(clicked_unit):
			# Start pile-in movement for this unit
			combat_phase.start_pile_in_movement(clicked_unit)
		else:
			print("❌ %s cannot pile in (not within 3\" of enemies)" % clicked_unit.unit_data.unit_name)
	
	# Check if this is an enemy unit (for attack targeting)
	elif clicked_unit.unit_data.player_owner != current_player:
		if selected_unit_3d and selected_unit_3d.unit_data.player_owner == current_player:
			if combat_phase.can_attack_target(selected_unit_3d, clicked_unit):
				print("✅ %s can attack %s (within 1\")" % [selected_unit_3d.unit_data.unit_name, clicked_unit.unit_data.unit_name])
			# 	combat_phase.resolve_attack(selected_unit_3d, clicked_unit)
			else:
				var distance = unit_utils_script.get_base_to_base_distance(selected_unit_3d, clicked_unit)
				print("❌ %s cannot attack %s (%.1f\" away, need ≤1\")" % [selected_unit_3d.unit_data.unit_name, clicked_unit.unit_data.unit_name, distance])

# Signal Handlers
func _on_unit_3d_clicked(unit_3d: Unit3D) -> void:
	"""Handle unit click events"""
	print("Unit clicked: ", unit_3d.unit_data.unit_name)
	
	# Don't change selection if we're in active phases and this is the selected unit
	if (current_state == GameState.MOVEMENT_PHASE or current_state == GameState.SHOOTING_PHASE) and selected_unit_3d == unit_3d:
		return
	
	# Prevent selecting enemy units during active phases (except for targeting)
	if (current_state == GameState.MOVEMENT_PHASE or current_state == GameState.SHOOTING_PHASE or current_state == GameState.CHARGE_PHASE) and unit_3d.unit_data.player_owner != current_player:
		print("❌ Cannot select enemy unit during active phase: ", unit_3d.unit_data.unit_name)
		print("💡 You are Player ", current_player, " - click on your own units (Player ", current_player, " units)")
		return
	
	# Deselect previous unit
	if selected_unit_3d and selected_unit_3d != unit_3d:
		selected_unit_3d.deselect()
	
	# Select new unit
	selected_unit_3d = unit_3d
	unit_3d.select()
	
	# Update UI
	unit_selected.emit(unit_3d.unit_data)

func _on_unit_3d_selected(unit_3d: Unit3D) -> void:
	print("Unit selected: ", unit_3d.unit_data.unit_name)

func _on_unit_3d_deselected(unit_3d: Unit3D) -> void:
	print("Unit deselected: ", unit_3d.unit_data.unit_name)

func _on_turn_changed(turn_number: int, player: int) -> void:
	print("Turn changed to: ", turn_number, " Player: ", player)

func _on_unit_selected(unit: Unit) -> void:
	if unit:
		unit_info_label.text = "Unit: %s\nMove: %d\"\nSave: %d+\nWounds: %d/%d\nPosition: %s" % [
			unit.unit_name,
			unit.move,
			unit.save,
			unit.current_wounds,
			unit.max_wounds,
			str(unit.position)
		]
	else:
		unit_info_label.text = "Select a unit to see info"

# Phase Event Handlers
func _on_movement_completed(unit: Unit3D, final_position: Vector3) -> void:
	"""Handle movement completion"""
	unit_movement_data[unit] = final_position
	update_ui()

func _on_movement_undo(unit: Unit3D, position: Vector3) -> void:
	"""Handle movement undo"""
	unit_movement_data[unit] = position
	update_ui()

func _on_charge_completed(unit: Unit3D, distance: float) -> void:
	print("Charge completed: ", unit.unit_data.unit_name, " charged ", distance, " inches")

func _on_charge_failed(unit: Unit3D) -> void:
	print("Charge failed: ", unit.unit_data.unit_name)

func _on_shooting_completed(attacker: Unit3D, target: Unit3D, damage: int) -> void:
	print("Shooting completed: ", attacker.unit_data.unit_name, " dealt ", damage, " damage to ", target.unit_data.unit_name)

func _on_pile_in_completed(unit: Unit3D, distance: float) -> void:
	print("Pile-in completed: ", unit.unit_data.unit_name, " piled in ", distance, " inches")

func _on_attack_resolved(attacker: Unit3D, target: Unit3D, damage: int) -> void:
	print("Attack resolved: ", attacker.unit_data.unit_name, " dealt ", damage, " damage to ", target.unit_data.unit_name)

# Utility Functions
func test_unit_movement() -> void:
	"""Test function for unit movement"""
	if selected_unit_3d:
		var target_pos = selected_unit_3d.global_position + Vector3(3, 0, 2)
		selected_unit_3d.move_to_position(target_pos)
		print("Moving unit to: ", target_pos)

func update_ui() -> void:
	"""Update the user interface"""
	turn_info.text = "Turn: %d | Player: %d | Phase: %s" % [
		current_turn, 
		current_player, 
		GameState.keys()[current_state]
	]

func update_camera_position() -> void:
	"""Update camera position and rotation"""
	if camera:
		camera.global_position = camera_position
		camera.rotation_degrees = Vector3(camera_rotation.y, camera_rotation.x, 0)

func _process(delta: float) -> void:
	"""Process function called every frame"""
	# Update distance display
	if selected_unit_3d and hovered_unit_3d:
		var distance = selected_unit_3d.get_distance_inches_to(hovered_unit_3d)
		distance_label.text = "Distance: %.1f inches" % distance
	elif selected_unit_3d:
		distance_label.text = "Selected: " + selected_unit_3d.unit_data.unit_name
	else:
		distance_label.text = "No unit selected"
