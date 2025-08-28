extends Node3D

func _ready():
	print("3D Test Scene loaded successfully!")
	print("Testing basic 3D functionality...")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("Space pressed - 3D input working!")
			get_tree().quit()

