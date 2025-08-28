extends RefCounted
class_name UnitManager

# UnitManager handles unit creation, management, and sample data
# This will include all the different unit types from Age of Sigmar

var all_units: Array[Unit] = []
var player1_units: Array[Unit] = []
var player2_units: Array[Unit] = []

func _init():
	print("UnitManager initialized")

func create_sample_units():
	print("Creating sample units for both players...")
	
	# Player 1 - Stormcast Eternals
	create_stormcast_units()
	
	# Player 2 - Orruk Warclans
	create_orruk_units()

func create_stormcast_units():
	# Liberators
	var liberators = Unit.new()
	liberators.unit_name = "Liberators"
	liberators.unit_type = "Infantry"
	liberators.faction = "Stormcast Eternals"
	liberators.player_owner = 1
	liberators.move = 5
	liberators.save = 4
	liberators.bravery = 7
	liberators.max_wounds = 2
	liberators.attacks = 2
	liberators.to_hit = 3
	liberators.to_wound = 3
	liberators.rend = 1
	liberators.damage = 1
	liberators.min_size = 5
	liberators.max_size = 10
	liberators.current_size = 5
	liberators.keywords.append("ORDER")
	liberators.keywords.append("STORMCAST ETERNALS")
	liberators.keywords.append("LIBERATORS")
	liberators.abilities.append("Shield of Civilisation")
	liberators.position = Vector2i(20, 20)
	
	# Lord-Celestant
	var lord_celestant = Unit.new()
	lord_celestant.unit_name = "Lord-Celestant"
	lord_celestant.unit_type = "Hero"
	lord_celestant.faction = "Stormcast Eternals"
	lord_celestant.player_owner = 1
	lord_celestant.move = 5
	lord_celestant.save = 3
	lord_celestant.bravery = 8
	lord_celestant.max_wounds = 5
	lord_celestant.attacks = 4
	lord_celestant.to_hit = 3
	lord_celestant.to_wound = 3
	lord_celestant.rend = 2
	lord_celestant.damage = 2
	lord_celestant.min_size = 1
	lord_celestant.max_size = 1
	lord_celestant.current_size = 1
	lord_celestant.keywords.append("ORDER")
	lord_celestant.keywords.append("STORMCAST ETERNALS")
	lord_celestant.keywords.append("HERO")
	lord_celestant.keywords.append("LORD-CELESTANT")
	lord_celestant.abilities.append("Lightning Strike")
	lord_celestant.abilities.append("Command Ability")
	lord_celestant.position = Vector2i(25, 20)
	
	# Prosecutors (Flying unit)
	var prosecutors = Unit.new()
	prosecutors.unit_name = "Prosecutors"
	prosecutors.unit_type = "Infantry"
	prosecutors.faction = "Stormcast Eternals"
	prosecutors.player_owner = 1
	prosecutors.move = 12  # Flying units have longer movement
	prosecutors.save = 4
	prosecutors.bravery = 7
	prosecutors.max_wounds = 2
	prosecutors.attacks = 2
	prosecutors.to_hit = 3
	prosecutors.to_wound = 3
	prosecutors.rend = 1
	prosecutors.damage = 1
	prosecutors.min_size = 3
	prosecutors.max_size = 6
	prosecutors.current_size = 3
	prosecutors.keywords.append("ORDER")
	prosecutors.keywords.append("STORMCAST ETERNALS")
	prosecutors.keywords.append("PROSECUTORS")
	prosecutors.keywords.append("Fly")  # This unit can fly!
	prosecutors.abilities.append("Lightning Javelins")
	prosecutors.position = Vector2i(15, 20)
	
	player1_units.append(liberators)
	player1_units.append(lord_celestant)
	player1_units.append(prosecutors)
	all_units.append(liberators)
	all_units.append(lord_celestant)
	all_units.append(prosecutors)

func create_orruk_units():
	# Orruk Brutes
	var brutes = Unit.new()
	brutes.unit_name = "Orruk Brutes"
	brutes.unit_type = "Infantry"
	brutes.faction = "Orruk Warclans"
	brutes.player_owner = 2
	brutes.move = 5
	brutes.save = 5
	brutes.bravery = 6
	brutes.max_wounds = 3
	brutes.attacks = 3
	brutes.to_hit = 4
	brutes.to_wound = 3
	brutes.rend = 1
	brutes.damage = 2
	brutes.min_size = 5
	brutes.max_size = 10
	brutes.current_size = 5
	brutes.keywords.append("DESTRUCTION")
	brutes.keywords.append("ORRUK WARCLANS")
	brutes.keywords.append("ORRUK BRUTES")
	brutes.abilities.append("Brute Smash")
	brutes.position = Vector2i(40, 20)
	
	# Megaboss
	var megaboss = Unit.new()
	megaboss.unit_name = "Megaboss"
	megaboss.unit_type = "Hero"
	megaboss.faction = "Orruk Warclans"
	megaboss.player_owner = 2
	megaboss.move = 5
	megaboss.save = 4
	megaboss.bravery = 7
	megaboss.max_wounds = 6
	megaboss.attacks = 5
	megaboss.to_hit = 3
	megaboss.to_wound = 3
	megaboss.rend = 2
	megaboss.damage = 3
	megaboss.min_size = 1
	megaboss.max_size = 1
	megaboss.current_size = 1
	megaboss.keywords.append("DESTRUCTION")
	megaboss.keywords.append("ORRUK WARCLANS")
	megaboss.keywords.append("HERO")
	megaboss.keywords.append("MEGABOSS")
	megaboss.abilities.append("Waaagh!")
	megaboss.abilities.append("Command Ability")
	megaboss.position = Vector2i(35, 20)
	
	player2_units.append(brutes)
	player2_units.append(megaboss)
	all_units.append(brutes)
	all_units.append(megaboss)

func get_units_for_player(player: int) -> Array[Unit]:
	if player == 1:
		return player1_units
	elif player == 2:
		return player2_units
	return []

func get_unit_at_position(position: Vector2i) -> Unit:
	for unit in all_units:
		if unit.position == position and unit.current_wounds > 0:
			return unit
	return null

func get_all_alive_units() -> Array[Unit]:
	var alive_units: Array[Unit] = []
	for unit in all_units:
		if unit.current_wounds > 0:
			alive_units.append(unit)
	return alive_units

func reset_all_units():
	for unit in all_units:
		unit.reset_activation()

func get_units_by_keyword(keyword: String) -> Array[Unit]:
	var matching_units: Array[Unit] = []
	for unit in all_units:
		if unit.has_keyword(keyword) and unit.current_wounds > 0:
			matching_units.append(unit)
	return matching_units

func get_heroes_for_player(player: int) -> Array[Unit]:
	var heroes: Array[Unit] = []
	var player_units = get_units_for_player(player)
	for unit in player_units:
		if unit.has_keyword("HERO") and unit.current_wounds > 0:
			heroes.append(unit)
	return heroes
