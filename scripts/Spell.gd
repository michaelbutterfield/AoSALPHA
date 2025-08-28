extends Resource
class_name Spell

# Basic Spell class for Age of Sigmar magic system

@export var spell_name: String = "Unknown Spell"
@export var casting_value: int = 7
@export var range: int = 18
@export var description: String = "A mysterious spell"

func _init():
	pass

