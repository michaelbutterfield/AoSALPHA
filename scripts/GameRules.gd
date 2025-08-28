extends RefCounted
class_name GameRules

# GameRules class handles all Age of Sigmar 4th edition rule logic
# This includes combat resolution, spell casting, command abilities, etc.

func _init():
	print("GameRules initialized")

# Combat Resolution
func resolve_combat(attacker: Unit, defender: Unit) -> CombatResult:
	var result = CombatResult.new()
	
	# Roll to hit
	var hits = roll_dice(attacker.get_effective_attacks(), attacker.get_effective_to_hit())
	result.hits = hits
	
	# Roll to wound
	var wounds = roll_dice(hits, attacker.get_effective_to_wound())
	result.wounds = wounds
	
	# Defender rolls saves
	var save_roll = defender.get_effective_save() - attacker.get_effective_rend()
	var saves = roll_dice(wounds, save_roll)
	result.saves = saves
	
	# Calculate damage
	var damage_dealt = wounds - saves
	result.damage_dealt = damage_dealt
	
	# Apply damage
	if damage_dealt > 0:
		defender.take_damage(damage_dealt)
	
	return result

# Dice rolling
func roll_dice(number_of_dice: int, target: int) -> int:
	var successes = 0
	for i in range(number_of_dice):
		var roll = randi_range(1, 6)
		if roll >= target:
			successes += 1
	return successes

func roll_d6() -> int:
	return randi_range(1, 6)

func roll_2d6() -> int:
	return randi_range(1, 6) + randi_range(1, 6)

# Movement rules
func calculate_charge_distance(unit: Unit) -> int:
	# Base charge is 2D6
	var charge_roll = roll_2d6()
	# Add any modifiers from abilities, spells, etc.
	return charge_roll

func can_charge(unit: Unit, target_position: Vector2i) -> bool:
	var distance = unit.position.distance_to(target_position)
	var charge_distance = calculate_charge_distance(unit)
	return distance <= charge_distance

# Battleshock rules
func resolve_battleshock(unit: Unit) -> int:
	var bravery = unit.get_effective_bravery()
	var models_lost = unit.max_wounds - unit.current_wounds
	
	if models_lost == 0:
		return 0
	
	var battleshock_roll = roll_d6()
	var casualties = battleshock_roll + models_lost - bravery
	
	if casualties > 0:
		unit.take_damage(casualties)
		return casualties
	
	return 0

# Command abilities
func use_command_ability(commander: Unit, target: Unit, ability: String) -> bool:
	# Check if commander can use command ability
	if !commander.has_keyword("HERO"):
		return false
	
	# Apply command ability effects
	match ability:
		"All-out Attack":
			target.to_hit -= 1
			return true
		"All-out Defence":
			target.save -= 1
			return true
		"Rally":
			var heal_roll = roll_d6()
			if heal_roll >= 6:
				target.heal(1)
			return true
	
	return false

# Spell casting
func cast_spell(caster: Unit, spell: Spell, target: Unit = null) -> bool:
	if !caster.has_keyword("WIZARD"):
		return false
	
	var casting_roll = roll_2d6()
	if casting_roll >= spell.casting_value:
		# Spell successfully cast
		apply_spell_effects(spell, target)
		return true
	
	return false

func apply_spell_effects(spell: Spell, target: Unit):
	# Apply spell effects based on spell type
	pass

# Victory conditions
func check_victory_conditions(player1_units: Array, player2_units: Array) -> int:
	# Return 1 for player 1 victory, 2 for player 2 victory, 0 for no victory
	
	var p1_alive = 0
	var p2_alive = 0
	
	for unit in player1_units:
		if unit.current_wounds > 0:
			p1_alive += 1
	
	for unit in player2_units:
		if unit.current_wounds > 0:
			p2_alive += 1
	
	if p1_alive == 0:
		return 2
	elif p2_alive == 0:
		return 1
	
	return 0

# Combat Result class
class CombatResult:
	var hits: int = 0
	var wounds: int = 0
	var saves: int = 0
	var damage_dealt: int = 0

