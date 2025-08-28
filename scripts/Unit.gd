extends RefCounted
class_name Unit

# Unit class representing a single unit in Age of Sigmar
# This includes all the stats and abilities from the warscroll

signal unit_damaged(unit: Unit, damage: int)
signal unit_destroyed(unit: Unit)
signal unit_activated(unit: Unit)

@export var unit_name: String = "Unknown Unit"
@export var unit_type: String = "Infantry"
@export var faction: String = "Unknown"
@export var player_owner: int = 1

# Core Stats
@export var move: int = 5
@export var save: int = 5
@export var bravery: int = 6
@export var max_wounds: int = 1
@export var current_wounds: int = 1

# Combat Stats
@export var attacks: int = 1
@export var to_hit: int = 4
@export var to_wound: int = 4
@export var rend: int = 0
@export var damage: int = 1

# Unit Size
@export var min_size: int = 1
@export var max_size: int = 10
@export var current_size: int = 1

# Special Abilities
var abilities: Array[String] = []
var keywords: Array[String] = []

# Position and State
var position: Vector2i = Vector2i.ZERO
var is_activated: bool = false
var has_moved: bool = false
var has_charged: bool = false
var has_fought: bool = false
var has_shot: bool = false

# Combat State
var models_lost: int = 0
var wounds_taken: int = 0

func _init():
	current_wounds = max_wounds
	current_size = min_size

func take_damage(amount: int) -> int:
	var actual_damage = min(amount, current_wounds)
	current_wounds -= actual_damage
	wounds_taken += actual_damage
	
	unit_damaged.emit(self, actual_damage)
	
	if current_wounds <= 0:
		destroy_unit()
	
	return actual_damage

func destroy_unit():
	current_wounds = 0
	unit_destroyed.emit(self)

func heal(amount: int) -> int:
	var actual_healing = min(amount, max_wounds - current_wounds)
	current_wounds += actual_healing
	return actual_healing

func activate():
	is_activated = true
	unit_activated.emit(self)

func reset_activation():
	is_activated = false
	has_moved = false
	has_charged = false
	has_fought = false
	has_shot = false

func can_move() -> bool:
	return !is_activated and current_wounds > 0

func can_charge() -> bool:
	return !has_charged and current_wounds > 0

func can_fight() -> bool:
	return !has_fought and current_wounds > 0

func can_shoot() -> bool:
	return !has_shot and current_wounds > 0

func get_effective_bravery() -> int:
	# Apply any modifiers to bravery
	return bravery

func get_effective_save() -> int:
	# Apply any modifiers to save
	return save

func get_effective_attacks() -> int:
	# Apply any modifiers to attacks
	return attacks * current_size

func get_effective_to_hit() -> int:
	# Apply any modifiers to hit
	return to_hit

func get_effective_to_wound() -> int:
	# Apply any modifiers to wound
	return to_wound

func get_effective_rend() -> int:
	# Apply any modifiers to rend
	return rend

func get_effective_damage() -> int:
	# Apply any modifiers to damage
	return damage

func has_keyword(keyword: String) -> bool:
	return keywords.has(keyword)

func has_ability(ability: String) -> bool:
	return abilities.has(ability)

func get_unit_info() -> String:
	return """
Unit: %s
Type: %s
Faction: %s
Move: %d" | Save: %d+ | Bravery: %d
Wounds: %d/%d | Size: %d/%d
Attacks: %d | Hit: %d+ | Wound: %d+ | Rend: -%d | Damage: %d
Keywords: %s
Abilities: %s
""" % [
	unit_name, unit_type, faction, move, save, bravery,
	current_wounds, max_wounds, current_size, max_size,
	get_effective_attacks(), get_effective_to_hit(), get_effective_to_wound(), 
	get_effective_rend(), get_effective_damage(),
	", ".join(keywords), ", ".join(abilities)
]
