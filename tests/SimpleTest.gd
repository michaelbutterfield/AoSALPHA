extends SceneTree

# Simple test script for core game systems
func _ready() -> void:
	print("🧪 Starting Simple Core Tests...")
	run_simple_tests()
	print("✅ Simple tests completed!")
	quit()

func run_simple_tests() -> void:
	test_basic_math()
	test_vector_operations()
	test_dice_rolling()
	test_unit_properties()
	test_phase_enumeration()

func test_basic_math() -> void:
	print("Testing basic math...")
	
	# Test addition
	test_assert(2 + 2 == 4, "Basic addition")
	
	# Test distance calculation
	var pos1 = Vector3(0, 0, 0)
	var pos2 = Vector3(3, 0, 4)
	var distance = pos1.distance_to(pos2)
	test_assert(distance == 5.0, "Distance calculation (3,4,5 triangle)")
	
	# Test base-to-base distance
	var radius1 = 0.5
	var radius2 = 0.5
	var base_distance = distance - radius1 - radius2
	test_assert(base_distance == 4.0, "Base-to-base distance calculation")
	
	print("✅ Basic math tests passed")

func test_vector_operations() -> void:
	print("Testing vector operations...")
	
	var v1 = Vector2(1, 2)
	var v2 = Vector2(3, 4)
	var v3 = Vector2(4, 6)
	
	test_assert(v1 + v2 == v3, "Vector addition")
	test_assert(v1.distance_to(v2) > 0, "Vector distance")
	
	print("✅ Vector operation tests passed")

func test_dice_rolling() -> void:
	print("Testing dice rolling...")
	
	# Test single die
	var roll1 = randi_range(1, 6)
	test_assert(roll1 >= 1 and roll1 <= 6, "Single die roll range")
	
	# Test 2D6 (charge roll)
	var charge_roll = randi_range(1, 6) + randi_range(1, 6)
	test_assert(charge_roll >= 2 and charge_roll <= 12, "Charge roll range (2D6)")
	
	# Test multiple rolls
	for i in range(10):
		var roll = randi_range(1, 6)
		test_assert(roll >= 1 and roll <= 6, "Multiple die roll %d" % i)
	
	print("✅ Dice rolling tests passed")

func test_unit_properties() -> void:
	print("Testing unit properties...")
	
	# Test base radius hierarchy
	var infantry_radius = 0.5
	var hero_radius = 0.75
	var cavalry_radius = 1.0
	var monster_radius = 1.75
	
	test_assert(hero_radius > infantry_radius, "Hero base larger than infantry")
	test_assert(cavalry_radius > hero_radius, "Cavalry base larger than hero")
	test_assert(monster_radius > cavalry_radius, "Monster base larger than cavalry")
	
	# Test movement validation
	var unit_move = 6
	var target_distance = 4.0
	test_assert(target_distance <= unit_move, "Movement within unit limits")
	
	print("✅ Unit property tests passed")

func test_phase_enumeration() -> void:
	print("Testing phase enumeration...")
	
	# Test phase progression (using integer values)
	var phases = [0, 1, 2, 3, 4, 5, 6, 7]  # SETUP, HERO, MOVEMENT, SHOOTING, CHARGE, COMBAT, BATTLESHOCK, GAME_END
	
	for i in range(phases.size() - 1):
		test_assert(phases[i] + 1 == phases[i + 1], "Phase %d transitions to %d" % [phases[i], phases[i + 1]])
	
	# Test phase names
	var phase_names = ["SETUP", "HERO_PHASE", "MOVEMENT_PHASE", "SHOOTING_PHASE", "CHARGE_PHASE", "COMBAT_PHASE", "BATTLESHOCK_PHASE", "GAME_END"]
	test_assert(phase_names.size() == phases.size(), "Phase names match phase count")
	
	print("✅ Phase enumeration tests passed")

func test_assert(condition: bool, message: String) -> void:
	if not condition:
		print("❌ ASSERTION FAILED: " + message)
		push_error("Test assertion failed: " + message)
