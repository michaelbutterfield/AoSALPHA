extends Node

# Test script for phase controllers
# Run this script to test the refactored phase controllers

var test_runner: TestRunner

func _ready() -> void:
	print("🧪 Starting Phase Controller Tests...")
	
	# Create test runner
	test_runner = TestRunner.new()
	
	# Run tests
	test_runner.run_all_tests()
	
	# Exit after tests complete
	get_tree().quit()

func _process(delta: float) -> void:
	# Exit after one frame
	get_tree().quit()


