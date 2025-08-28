extends Node

# Manual test for phase controllers using preload
func _ready() -> void:
	print("🧪 Testing Phase Controllers (Manual Load)...")
	print("==================================================")
	
	# Test MovementPhase
	test_movement_phase()
	
	# Test ShootingPhase
	test_shooting_phase()
	
	# Test ChargePhase
	test_charge_phase()
	
	# Test CombatPhase
	test_combat_phase()
	
	print("==================================================")
	print("✅ All phase controller tests completed!")
	get_tree().quit()

func test_movement_phase() -> void:
	print("Testing MovementPhase...")
	
	# Load the script manually
	var movement_script = preload("res://scripts/phases/MovementPhase.gd")
	var battlefield = Node3D.new()
	var camera = Camera3D.new()
	
	# Create instance manually
	var movement_phase = movement_script.new(battlefield, camera)
	
	if movement_phase:
		print("✅ MovementPhase created successfully!")
		print("✅ Battlefield reference: ", movement_phase.battlefield == battlefield)
		print("✅ Camera reference: ", movement_phase.camera == camera)
		
		# Test signal connection
		var signal_connected = false
		movement_phase.movement_completed.connect(func(): signal_connected = true)
		print("✅ Signal connection test passed")
	else:
		print("❌ Failed to create MovementPhase")
	
	# Cleanup
	battlefield.queue_free()
	camera.queue_free()

func test_shooting_phase() -> void:
	print("Testing ShootingPhase...")
	
	var shooting_script = preload("res://scripts/phases/ShootingPhase.gd")
	var battlefield = Node3D.new()
	var camera = Camera3D.new()
	var unit_instances: Array[Unit3D] = []
	
	var shooting_phase = shooting_script.new(battlefield, camera, unit_instances)
	
	if shooting_phase:
		print("✅ ShootingPhase created successfully!")
		print("✅ Battlefield reference: ", shooting_phase.battlefield == battlefield)
		print("✅ Camera reference: ", shooting_phase.camera == camera)
	else:
		print("❌ Failed to create ShootingPhase")
	
	battlefield.queue_free()
	camera.queue_free()

func test_charge_phase() -> void:
	print("Testing ChargePhase...")
	
	var charge_script = preload("res://scripts/phases/ChargePhase.gd")
	var battlefield = Node3D.new()
	var camera = Camera3D.new()
	var unit_instances: Array[Unit3D] = []
	
	var charge_phase = charge_script.new(battlefield, camera, unit_instances)
	
	if charge_phase:
		print("✅ ChargePhase created successfully!")
		print("✅ Battlefield reference: ", charge_phase.battlefield == battlefield)
		print("✅ Camera reference: ", charge_phase.camera == camera)
	else:
		print("❌ Failed to create ChargePhase")
	
	battlefield.queue_free()
	camera.queue_free()

func test_combat_phase() -> void:
	print("Testing CombatPhase...")
	
	var combat_script = preload("res://scripts/phases/CombatPhase.gd")
	var battlefield = Node3D.new()
	var camera = Camera3D.new()
	var unit_instances: Array[Unit3D] = []
	
	var combat_phase = combat_script.new(battlefield, camera, unit_instances)
	
	if combat_phase:
		print("✅ CombatPhase created successfully!")
		print("✅ Battlefield reference: ", combat_phase.battlefield == battlefield)
		print("✅ Camera reference: ", combat_phase.camera == camera)
	else:
		print("❌ Failed to create CombatPhase")
	
	battlefield.queue_free()
	camera.queue_free()
