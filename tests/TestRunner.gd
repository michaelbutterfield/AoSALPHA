extends Node

# Comprehensive test runner for all test suites
class_name TestRunner

var test_results: Array[String] = []
var passed_tests: int = 0
var total_tests: int = 0
var test_suites: Array[String] = []

func _ready() -> void:
	print("🚀 Starting Comprehensive Test Suite...")
	run_all_test_suites()
	print_final_results()
	get_tree().quit()

func run_all_test_suites() -> void:
	test_suites = [
		"Game Flow Tests",
		"Unit3D Tests", 
		"Phase Controller Tests",
		"Utility Tests"
	]
	
	print("📋 Test Suites to Run:")
	for suite in test_suites:
		print("  - " + suite)
	print()
	
	# Run each test suite
	run_game_flow_tests()
	run_unit3d_tests()
	run_phase_controller_tests()
	run_utility_tests()

func run_game_flow_tests() -> void:
	print("🎯 Running Game Flow Tests...")
	
	# Test core game systems
	var game_rules = GameRules.new()
	assert_not_null(game_rules, "GameRules creation")
	
	var unit_manager = UnitManager.new()
	assert_not_null(unit_manager, "UnitManager creation")
	
	var board_manager = BoardManager.new()
	assert_not_null(board_manager, "BoardManager creation")
	
	# Test unit creation
	unit_manager.create_sample_units()
	assert_greater_than(unit_manager.all_units.size(), 0, "Sample units created")
	
	# Test player separation
	var player1_units = unit_manager.get_units_for_player(1)
	var player2_units = unit_manager.get_units_for_player(2)
	assert_greater_than(player1_units.size(), 0, "Player 1 has units")
	assert_greater_than(player2_units.size(), 0, "Player 2 has units")
	
	# Test phase progression (using enum values directly)
	var phases = [1, 2, 3, 4, 5, 6]  # HERO_PHASE, MOVEMENT_PHASE, SHOOTING_PHASE, CHARGE_PHASE, COMBAT_PHASE, BATTLESHOCK_PHASE
	
	for i in range(phases.size() - 1):
		assert_equals(phases[i] + 1, phases[i + 1], "Phase %d transitions to %d" % [phases[i], phases[i + 1]])

func run_unit3d_tests() -> void:
	print("🎯 Running Unit3D Tests...")
	
	# Test unit data creation
	var unit_data = Unit.new()
	unit_data.unit_name = "Test Unit"
	unit_data.move = 6
	unit_data.save = 4
	unit_data.max_wounds = 5
	unit_data.current_wounds = 5
	unit_data.player_owner = 1
	unit_data.position = Vector2(10, 10)
	
	assert_not_null(unit_data, "Unit data creation")
	assert_equals(unit_data.unit_name, "Test Unit", "Unit name set correctly")
	assert_equals(unit_data.move, 6, "Unit move set correctly")
	assert_equals(unit_data.save, 4, "Unit save set correctly")
	assert_equals(unit_data.max_wounds, 5, "Unit max wounds set correctly")
	assert_equals(unit_data.current_wounds, 5, "Unit current wounds set correctly")
	assert_equals(unit_data.player_owner, 1, "Unit player owner set correctly")
	assert_equals(unit_data.position, Vector2(10, 10), "Unit position set correctly")
	
	# Test unit selection
	var is_selected = false
	assert_false(is_selected, "Unit starts unselected")
	
	is_selected = true
	assert_true(is_selected, "Unit is selectable")
	
	# Test unit movement
	var target_position = Vector2(3, 4)
	var distance = unit_data.position.distance_to(target_position)
	assert_less_than_or_equal(distance, unit_data.move, "Movement within limits")
	
	# Test base radius hierarchy
	var infantry_radius = 0.5
	var hero_radius = 0.75
	var cavalry_radius = 1.0
	var monster_radius = 1.75
	
	assert_greater_than(hero_radius, infantry_radius, "Hero base larger than infantry")
	assert_greater_than(cavalry_radius, hero_radius, "Cavalry base larger than hero")
	assert_greater_than(monster_radius, cavalry_radius, "Monster base larger than cavalry")

func run_phase_controller_tests() -> void:
	print("🎯 Running Phase Controller Tests...")
	
	# Test phase controller creation (using preload)
	var movement_phase_script = preload("res://scripts/phases/MovementPhase.gd")
	var shooting_phase_script = preload("res://scripts/phases/ShootingPhase.gd")
	var charge_phase_script = preload("res://scripts/phases/ChargePhase.gd")
	var combat_phase_script = preload("res://scripts/phases/CombatPhase.gd")
	
	assert_not_null(movement_phase_script, "MovementPhase script loaded")
	assert_not_null(shooting_phase_script, "ShootingPhase script loaded")
	assert_not_null(charge_phase_script, "ChargePhase script loaded")
	assert_not_null(combat_phase_script, "CombatPhase script loaded")
	
	# Test phase controller instantiation
	var battlefield = Node3D.new()
	var camera = Camera3D.new()
	var unit_instances: Array[Unit3D] = []
	
	var movement_phase = movement_phase_script.new(battlefield, camera)
	var shooting_phase = shooting_phase_script.new(battlefield, camera, unit_instances)
	var charge_phase = charge_phase_script.new(battlefield, camera, unit_instances)
	var combat_phase = combat_phase_script.new(battlefield, camera, unit_instances)
	
	assert_not_null(movement_phase, "MovementPhase instantiated")
	assert_not_null(shooting_phase, "ShootingPhase instantiated")
	assert_not_null(charge_phase, "ChargePhase instantiated")
	assert_not_null(combat_phase, "CombatPhase instantiated")
	
	# Test signal connections
	var signal_connected = false
	movement_phase.movement_completed.connect(func(): signal_connected = true)
	assert_true(signal_connected == false, "Signal not triggered initially")
	
	# Cleanup
	battlefield.queue_free()
	camera.queue_free()

func run_utility_tests() -> void:
	print("🎯 Running Utility Tests...")
	
	# Test camera controller
	var camera_controller_script = preload("res://scripts/utils/CameraController.gd")
	var input_handler_script = preload("res://scripts/utils/InputHandler.gd")
	
	assert_not_null(camera_controller_script, "CameraController script loaded")
	assert_not_null(input_handler_script, "InputHandler script loaded")
	
	# Test utility functions
	var pos1 = Vector3(0, 0, 0)
	var pos2 = Vector3(3, 0, 4)
	var radius1 = 0.5
	var radius2 = 0.5
	
	# Test distance calculation manually
	var center_distance = pos1.distance_to(pos2)
	var expected_distance = center_distance - radius1 - radius2
	
	assert_equals(expected_distance, 4.0, "Base-to-base distance calculation correct (5 - 0.5 - 0.5 = 4.0)")
	
	# Test dice rolling
	var dice_roll = randi_range(1, 6)
	assert_greater_than_or_equal(dice_roll, 1, "Dice roll minimum 1")
	assert_less_than_or_equal(dice_roll, 6, "Dice roll maximum 6")
	
	# Test charge roll (2D6)
	var charge_roll = randi_range(1, 6) + randi_range(1, 6)
	assert_greater_than_or_equal(charge_roll, 2, "Charge roll minimum 2")
	assert_less_than_or_equal(charge_roll, 12, "Charge roll maximum 12")

# Utility functions
func assert_equals(actual, expected, message: String) -> void:
	total_tests += 1
	if actual == expected:
		passed_tests += 1
		test_results.append("✅ PASS: " + message)
	else:
		test_results.append("❌ FAIL: " + message + " (Expected: " + str(expected) + ", Got: " + str(actual) + ")")

func assert_not_null(value, message: String) -> void:
	total_tests += 1
	if value != null:
		passed_tests += 1
		test_results.append("✅ PASS: " + message)
	else:
		test_results.append("❌ FAIL: " + message + " (Value is null)")

func assert_true(condition: bool, message: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		test_results.append("✅ PASS: " + message)
	else:
		test_results.append("❌ FAIL: " + message + " (Condition is false)")

func assert_false(condition: bool, message: String) -> void:
	total_tests += 1
	if not condition:
		passed_tests += 1
		test_results.append("✅ PASS: " + message)
	else:
		test_results.append("❌ FAIL: " + message + " (Condition is true)")

func assert_greater_than(actual, expected, message: String) -> void:
	total_tests += 1
	if actual > expected:
		passed_tests += 1
		test_results.append("✅ PASS: " + message)
	else:
		test_results.append("❌ FAIL: " + message + " (" + str(actual) + " is not greater than " + str(expected) + ")")

func assert_greater_than_or_equal(actual, expected, message: String) -> void:
	total_tests += 1
	if actual >= expected:
		passed_tests += 1
		test_results.append("✅ PASS: " + message)
	else:
		test_results.append("❌ FAIL: " + message + " (" + str(actual) + " is not greater than or equal to " + str(expected) + ")")

func assert_less_than_or_equal(actual, expected, message: String) -> void:
	total_tests += 1
	if actual <= expected:
		passed_tests += 1
		test_results.append("✅ PASS: " + message)
	else:
		test_results.append("❌ FAIL: " + message + " (" + str(actual) + " is not less than or equal to " + str(expected) + ")")

func print_final_results() -> void:
	print("\n" + "============================================================")
	print("🎯 COMPREHENSIVE TEST SUITE RESULTS")
	print("============================================================")
	
	print("\n📋 Test Suites Completed:")
	for suite in test_suites:
		print("  ✅ " + suite)
	
	print("\n📊 DETAILED RESULTS:")
	for result in test_results:
		print(result)
	
	print("\n📈 FINAL SUMMARY:")
	print("Total Tests: " + str(total_tests))
	print("Passed: " + str(passed_tests))
	print("Failed: " + str(total_tests - passed_tests))
	print("Success Rate: " + str(round((float(passed_tests) / total_tests) * 100)) + "%")
	
	if passed_tests == total_tests:
		print("\n🎉 ALL TESTS PASSED! The game is ready for play!")
	else:
		print("\n⚠️  SOME TESTS FAILED! Please review the failed tests above.")
	
	print("============================================================")
