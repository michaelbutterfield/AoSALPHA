extends Node

# Simple test for MovementPhase
func _ready() -> void:
	print("🧪 Testing MovementPhase...")
	
	# Create test nodes
	var battlefield = Node3D.new()
	var camera = Camera3D.new()
	
	# Try to create MovementPhase
	var movement_phase = MovementPhase.new(battlefield, camera)
	
	if movement_phase:
		print("✅ MovementPhase created successfully!")
		print("✅ Battlefield reference: ", movement_phase.battlefield == battlefield)
		print("✅ Camera reference: ", movement_phase.camera == camera)
	else:
		print("❌ Failed to create MovementPhase")
	
	# Cleanup
	battlefield.queue_free()
	camera.queue_free()
	
	# Exit
	get_tree().quit()


