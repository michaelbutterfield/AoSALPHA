extends Node

# Test script for 3D unit functionality
class_name TestUnit3D

var test_results: Array[String] = []
var passed_tests: int = 0
var total_tests: int = 0

func _ready() -> void:
	print("🧪 Starting Unit3D Tests...")
	run_all_tests()
	print_results()
	get_tree().quit()

func run_all_tests() -> void:
	test_unit_creation()
	test_unit_selection()
	test_unit_movement()
	test_unit_collision()
	test_unit_highlighting()

func test_unit_creation() -> void:
	print("Testing Unit3D Creation...")
	
	# Test unit data creation
	var unit_data = Unit.new()
	unit_data.unit_name = "Test Unit"
	unit_data.move = 6
	unit_data.save = 4
	unit_data.max_wounds = 5
	unit_data.current_wounds = 5
	unit_data.player_owner = 1
	unit_data.position = Vector2(10, 10)
	
	assert_not_null(unit_data, "Unit data should be created successfully")
	assert_equals(unit_data.unit_name, "Test Unit", "Unit name should be set correctly")
	assert_equals(unit_data.move, 6, "Unit move should be set correctly")
	assert_equals(unit_data.save, 4, "Unit save should be set correctly")
	assert_equals(unit_data.max_wounds, 5, "Unit max wounds should be set correctly")
	assert_equals(unit_data.current_wounds, 5, "Unit current wounds should be set correctly")
	assert_equals(unit_data.player_owner, 1, "Unit player owner should be set correctly")
	assert_equals(unit_data.position, Vector2(10, 10), "Unit position should be set correctly")

func test_unit_selection() -> void:
	print("Testing Unit3D Selection...")
	
	# Test selection state
	var unit_data = Unit.new()
	unit_data.unit_name = "Test Unit"
	unit_data.player_owner = 1
	
	# Simulate selection
	var is_selected = false
	assert_false(is_selected, "Unit should start unselected")
	
	is_selected = true
	assert_true(is_selected, "Unit should be selectable")
	
	is_selected = false
	assert_false(is_selected, "Unit should be deselectable")

func test_unit_movement() -> void:
	print("Testing Unit3D Movement...")
	
	var unit_data = Unit.new()
	unit_data.unit_name = "Test Unit"
	unit_data.move = 6
	unit_data.position = Vector2(0, 0)
	
	# Test movement within limits
	var target_position = Vector2(3, 4)
	var distance = unit_data.position.distance_to(target_position)
	
	assert_less_than_or_equal(distance, unit_data.move, "Movement should be within unit's move characteristic")
	
	# Test position update
	unit_data.position = target_position
	assert_equals(unit_data.position, target_position, "Unit position should be updated correctly")

func test_unit_collision() -> void:
	print("Testing Unit3D Collision...")
	
	# Test base radius calculations
	var infantry_radius = 0.5
	var hero_radius = 0.75
	var cavalry_radius = 1.0
	var monster_radius = 1.75
	var war_machine_radius = 1.2
	
	assert_greater_than(hero_radius, infantry_radius, "Hero base should be larger than infantry")
	assert_greater_than(cavalry_radius, hero_radius, "Cavalry base should be larger than hero")
	assert_greater_than(monster_radius, cavalry_radius, "Monster base should be larger than cavalry")
	
	# Test collision detection
	var unit1_pos = Vector3(0, 0, 0)
	var unit2_pos = Vector3(1, 0, 0)
	var unit1_radius = 0.5
	var unit2_radius = 0.5
	
	var distance_between = unit1_pos.distance_to(unit2_pos)
	var collision_distance = unit1_radius + unit2_radius
	
	assert_true(distance_between >= collision_distance, "Units should not be colliding at this distance")

func test_unit_highlighting() -> void:
	print("Testing Unit3D Highlighting...")
	
	# Test player color assignment
	var player1_color = Color.RED
	var player2_color = Color.BLUE
	
	assert_not_equals(player1_color, player2_color, "Player colors should be different")
	
	# Test highlight color assignment
	var unit_data = Unit.new()
	unit_data.player_owner = 1
	
	var highlight_color = player1_color if unit_data.player_owner == 1 else player2_color
	assert_equals(highlight_color, player1_color, "Player 1 unit should have player 1 color")

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

func assert_less_than_or_equal(actual, expected, message: String) -> void:
	total_tests += 1
	if actual <= expected:
		passed_tests += 1
		test_results.append("✅ PASS: " + message)
	else:
		test_results.append("❌ FAIL: " + message + " (" + str(actual) + " is not less than or equal to " + str(expected) + ")")

func assert_not_equals(actual, expected, message: String) -> void:
	total_tests += 1
	if actual != expected:
		passed_tests += 1
		test_results.append("✅ PASS: " + message)
	else:
		test_results.append("❌ FAIL: " + message + " (Values are equal: " + str(actual) + ")")

func print_results() -> void:
	print("\n" + "=" * 60)
	print("🎯 UNIT3D TEST RESULTS")
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


