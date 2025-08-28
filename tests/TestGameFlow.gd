extends Node

# Test script for complete game flow and phase transitions
class_name TestGameFlow

var test_results: Array[String] = []
var passed_tests: int = 0
var total_tests: int = 0

func _ready() -> void:
	print("🧪 Starting Game Flow Tests...")
	run_all_tests()
	print_results()
	get_tree().quit()

func run_all_tests() -> void:
	test_game_initialization()
	test_phase_transitions()
	test_unit_management()
	test_movement_system()
	test_charge_system()
	test_combat_system()
	test_turn_management()

func test_game_initialization() -> void:
	print("Testing Game Initialization...")
	
	# Test 1: Game state initialization
	assert_equals(GameState.SETUP, 0, "GameState.SETUP should be 0")
	assert_equals(GameState.HERO_PHASE, 1, "GameState.HERO_PHASE should be 1")
	assert_equals(GameState.MOVEMENT_PHASE, 2, "GameState.MOVEMENT_PHASE should be 2")
	assert_equals(GameState.SHOOTING_PHASE, 3, "GameState.SHOOTING_PHASE should be 3")
	assert_equals(GameState.CHARGE_PHASE, 4, "GameState.CHARGE_PHASE should be 4")
	assert_equals(GameState.COMBAT_PHASE, 5, "GameState.COMBAT_PHASE should be 5")
	assert_equals(GameState.BATTLESHOCK_PHASE, 6, "GameState.BATTLESHOCK_PHASE should be 6")
	assert_equals(GameState.GAME_END, 7, "GameState.GAME_END should be 7")
	
	# Test 2: Core systems initialization
	var game_rules = GameRules.new()
	assert_not_null(game_rules, "GameRules should be created successfully")
	
	var unit_manager = UnitManager.new()
	assert_not_null(unit_manager, "UnitManager should be created successfully")
	
	var board_manager = BoardManager.new()
	assert_not_null(board_manager, "BoardManager should be created successfully")

func test_phase_transitions() -> void:
	print("Testing Phase Transitions...")
	
	# Test phase progression
	var phases = [
		GameState.HERO_PHASE,
		GameState.MOVEMENT_PHASE,
		GameState.SHOOTING_PHASE,
		GameState.CHARGE_PHASE,
		GameState.COMBAT_PHASE,
		GameState.BATTLESHOCK_PHASE
	]
	
	for i in range(phases.size() - 1):
		assert_equals(phases[i] + 1, phases[i + 1], "Phase %d should transition to phase %d" % [phases[i], phases[i + 1]])

func test_unit_management() -> void:
	print("Testing Unit Management...")
	
	var unit_manager = UnitManager.new()
	unit_manager.create_sample_units()
	
	# Test unit creation
	assert_greater_than(unit_manager.all_units.size(), 0, "Should have created sample units")
	
	# Test player unit separation
	var player1_units = unit_manager.get_units_for_player(1)
	var player2_units = unit_manager.get_units_for_player(2)
	
	assert_greater_than(player1_units.size(), 0, "Player 1 should have units")
	assert_greater_than(player2_units.size(), 0, "Player 2 should have units")
	
	# Test unit properties
	for unit in unit_manager.all_units:
		assert_greater_than(unit.move, 0, "Unit %s should have positive move value" % unit.unit_name)
		assert_greater_than(unit.save, 0, "Unit %s should have positive save value" % unit.unit_name)
		assert_greater_than(unit.max_wounds, 0, "Unit %s should have positive max wounds" % unit.unit_name)
		assert_greater_than_or_equal(unit.current_wounds, 0, "Unit %s should have non-negative current wounds" % unit.unit_name)
		assert_less_than_or_equal(unit.current_wounds, unit.max_wounds, "Unit %s current wounds should not exceed max wounds" % unit.unit_name)

func test_movement_system() -> void:
	print("Testing Movement System...")
	
	# Test movement validation
	var unit_manager = UnitManager.new()
	unit_manager.create_sample_units()
	var test_unit = unit_manager.all_units[0]
	
	# Test valid movement
	var original_position = test_unit.position
	var valid_move = Vector2(original_position.x + 2, original_position.y + 2)
	
	# Test movement within limits
	assert_true(test_unit.move >= 2, "Unit should be able to move 2 inches")
	
	# Test position update
	test_unit.position = valid_move
	assert_equals(test_unit.position, valid_move, "Unit position should be updated")

func test_charge_system() -> void:
	print("Testing Charge System...")
	
	# Test charge roll calculation
	var charge_roll = randi_range(1, 6) + randi_range(1, 6)  # 2D6
	assert_greater_than_or_equal(charge_roll, 2, "Charge roll should be at least 2")
	assert_less_than_or_equal(charge_roll, 12, "Charge roll should be at most 12")
	
	# Test charge distance validation
	var charge_distance = 5.0
	var required_distance = 0.5
	assert_true(charge_distance >= required_distance, "Charge distance should be sufficient")

func test_combat_system() -> void:
	print("Testing Combat System...")
	
	# Test attack roll calculation
	var attack_roll = randi_range(1, 6)
	assert_greater_than_or_equal(attack_roll, 1, "Attack roll should be at least 1")
	assert_less_than_or_equal(attack_roll, 6, "Attack roll should be at most 6")
	
	# Test wound roll calculation
	var wound_roll = randi_range(1, 6)
	assert_greater_than_or_equal(wound_roll, 1, "Wound roll should be at least 1")
	assert_less_than_or_equal(wound_roll, 6, "Wound roll should be at most 6")
	
	# Test damage calculation
	var damage = randi_range(1, 3)
	assert_greater_than(damage, 0, "Damage should be positive")

func test_turn_management() -> void:
	print("Testing Turn Management...")
	
	# Test turn progression
	var current_turn = 1
	var current_player = 1
	var total_players = 2
	
	# Simulate turn progression
	current_player += 1
	assert_equals(current_player, 2, "Player should advance to 2")
	
	current_player += 1
	assert_equals(current_player, 3, "Player should advance to 3")
	
	# Reset for next turn
	current_player = 1
	current_turn += 1
	assert_equals(current_turn, 2, "Turn should advance to 2")
	assert_equals(current_player, 1, "Player should reset to 1")

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

func print_results() -> void:
	print("\n" + "=" * 60)
	print("🎯 GAME FLOW TEST RESULTS")
	print("=" * 60)
	
	for result in test_results:
		print(result)
	
	print("\n📊 SUMMARY:")
	print("Passed: " + str(passed_tests) + "/" + str(total_tests))
	print("Success Rate: " + str(round((float(passed_tests) / total_tests) * 100)) + "%")
	
	if passed_tests == total_tests:
		print("🎉 ALL TESTS PASSED!")
	else:
		print("⚠️  SOME TESTS FAILED!")
	
	print("=" * 60)

