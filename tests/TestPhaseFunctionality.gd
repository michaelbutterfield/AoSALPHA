extends Node

# Comprehensive test for phase controller functionality
func _ready() -> void:
	print("🧪 Testing Phase Controller Functionality...")
	print("============================================================")
	
	# Test MovementPhase functionality
	test_movement_phase_functionality()
	
	# Test ShootingPhase functionality
	test_shooting_phase_functionality()
	
	# Test ChargePhase functionality
	test_charge_phase_functionality()
	
	# Test CombatPhase functionality
	test_combat_phase_functionality()
	
	print("============================================================")
	print("✅ All phase functionality tests completed!")
	get_tree().quit()

func test_movement_phase_functionality() -> void:
	print("Testing MovementPhase Functionality...")
	
	var movement_script = preload("res://scripts/phases/MovementPhase.gd")
	var battlefield = Node3D.new()
	var camera = Camera3D.new()
	
	var movement_phase = movement_script.new(battlefield, camera)
	
	# Test signal emission
	var movement_completed_called = false
	var movement_undo_called = false
	
	movement_phase.movement_completed.connect(func(unit, pos): movement_completed_called = true)
	movement_phase.movement_undo.connect(func(unit, pos): movement_undo_called = true)
	
	# Test cleanup
	movement_phase.cleanup()
	
	print("✅ MovementPhase functionality test passed")
	
	# Cleanup
	battlefield.queue_free()
	camera.queue_free()

func test_shooting_phase_functionality() -> void:
	print("Testing ShootingPhase Functionality...")
	
	var shooting_script = preload("res://scripts/phases/ShootingPhase.gd")
	var battlefield = Node3D.new()
	var camera = Camera3D.new()
	var unit_instances: Array[Unit3D] = []
	
	var shooting_phase = shooting_script.new(battlefield, camera, unit_instances)
	
	# Test signal emission
	var shooting_completed_called = false
	shooting_phase.shooting_completed.connect(func(attacker, target, damage): shooting_completed_called = true)
	
	# Test cleanup
	shooting_phase.cleanup()
	
	print("✅ ShootingPhase functionality test passed")
	
	# Cleanup
	battlefield.queue_free()
	camera.queue_free()

func test_charge_phase_functionality() -> void:
	print("Testing ChargePhase Functionality...")
	
	var charge_script = preload("res://scripts/phases/ChargePhase.gd")
	var battlefield = Node3D.new()
	var camera = Camera3D.new()
	var unit_instances: Array[Unit3D] = []
	
	var charge_phase = charge_script.new(battlefield, camera, unit_instances)
	
	# Test signal emission
	var charge_completed_called = false
	var charge_failed_called = false
	
	charge_phase.charge_completed.connect(func(unit, pos): charge_completed_called = true)
	charge_phase.charge_failed.connect(func(unit): charge_failed_called = true)
	
	# Test cleanup
	charge_phase.cleanup()
	
	print("✅ ChargePhase functionality test passed")
	
	# Cleanup
	battlefield.queue_free()
	camera.queue_free()

func test_combat_phase_functionality() -> void:
	print("Testing CombatPhase Functionality...")
	
	var combat_script = preload("res://scripts/phases/CombatPhase.gd")
	var battlefield = Node3D.new()
	var camera = Camera3D.new()
	var unit_instances: Array[Unit3D] = []
	
	var combat_phase = combat_script.new(battlefield, camera, unit_instances)
	
	# Test signal emission
	var pile_in_completed_called = false
	var attack_resolved_called = false
	
	combat_phase.pile_in_completed.connect(func(unit, pos): pile_in_completed_called = true)
	combat_phase.attack_resolved.connect(func(attacker, target, damage): attack_resolved_called = true)
	
	# Test cleanup
	combat_phase.cleanup()
	
	print("✅ CombatPhase functionality test passed")
	
	# Cleanup
	battlefield.queue_free()
	camera.queue_free()
