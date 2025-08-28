extends RefCounted
class_name BoardManager

# BoardManager handles the game board, grid system, and battlefield
# This includes terrain, movement validation, and board state

var board_size: Vector2i = Vector2i(12, 12)  # 12x12 grid
var grid_cells: Array[Array] = []
var terrain: Array[Array] = []

func _init():
	print("BoardManager initialized")

func setup_battlefield():
	print("Setting up battlefield...")
	initialize_grid()
	place_terrain()
	print("Battlefield ready!")

func initialize_grid():
	# Initialize the grid with empty cells
	grid_cells.clear()
	terrain.clear()
	
	for x in range(board_size.x):
		var row: Array = []
		var terrain_row: Array = []
		for y in range(board_size.y):
			row.append(null)  # No unit initially
			terrain_row.append("clear")  # Clear terrain initially
		grid_cells.append(row)
		terrain.append(terrain_row)
	
	print("Grid initialized with size: ", board_size)

func place_terrain():
	# Place some basic terrain features
	# This can be expanded with more complex terrain placement
	
	# Place some obstacles in the center
	terrain[5][5] = "obstacle"
	terrain[5][6] = "obstacle"
	terrain[6][5] = "obstacle"
	terrain[6][6] = "obstacle"
	
	# Place some cover on the sides
	terrain[2][3] = "cover"
	terrain[2][4] = "cover"
	terrain[9][7] = "cover"
	terrain[9][8] = "cover"

func is_valid_position(position: Vector2i) -> bool:
	return position.x >= 0 and position.x < board_size.x and \
		   position.y >= 0 and position.y < board_size.y

func is_position_occupied(position: Vector2i) -> bool:
	if !is_valid_position(position):
		return true
	
	return grid_cells[position.x][position.y] != null

func place_unit(unit: Unit, position: Vector2i) -> bool:
	if !is_valid_position(position):
		print("Invalid position: ", position)
		return false
	
	if is_position_occupied(position):
		print("Position occupied: ", position)
		return false
	
	# Remove unit from old position if it exists
	if unit.position != Vector2i.ZERO:
		grid_cells[unit.position.x][unit.position.y] = null
	
	# Place unit at new position
	unit.position = position
	grid_cells[position.x][position.y] = unit
	return true

func remove_unit(unit: Unit):
	if unit.position != Vector2i.ZERO:
		grid_cells[unit.position.x][unit.position.y] = null
		unit.position = Vector2i.ZERO

func get_unit_at_position(position: Vector2i) -> Unit:
	if !is_valid_position(position):
		return null
	
	return grid_cells[position.x][position.y]

func get_terrain_at_position(position: Vector2i) -> String:
	if !is_valid_position(position):
		return "invalid"
	
	return terrain[position.x][position.y]

func calculate_distance(pos1: Vector2i, pos2: Vector2i) -> int:
	# Calculate Manhattan distance for movement
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)

func get_adjacent_positions(position: Vector2i) -> Array[Vector2i]:
	var adjacent: Array[Vector2i] = []
	var directions = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
	
	for direction in directions:
		var new_pos = position + direction
		if is_valid_position(new_pos):
			adjacent.append(new_pos)
	
	return adjacent

func get_positions_in_range(position: Vector2i, range: int) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	
	for x in range(max(0, position.x - range), min(board_size.x, position.x + range + 1)):
		for y in range(max(0, position.y - range), min(board_size.y, position.y + range + 1)):
			var pos = Vector2i(x, y)
			if calculate_distance(position, pos) <= range:
				positions.append(pos)
	
	return positions

func is_valid_movement(unit: Unit, from_pos: Vector2i, to_pos: Vector2i) -> bool:
	if !is_valid_position(to_pos):
		return false
	
	if is_position_occupied(to_pos):
		return false
	
	var distance = calculate_distance(from_pos, to_pos)
	if distance > unit.move:
		return false
	
	# Check terrain effects
	var terrain_type = get_terrain_at_position(to_pos)
	if terrain_type == "obstacle":
		return false
	
	return true

func get_movement_options(unit: Unit) -> Array[Vector2i]:
	var options: Array[Vector2i] = []
	var current_pos = unit.position
	
	for x in range(max(0, current_pos.x - unit.move), min(board_size.x, current_pos.x + unit.move + 1)):
		for y in range(max(0, current_pos.y - unit.move), min(board_size.y, current_pos.y + unit.move + 1)):
			var pos = Vector2i(x, y)
			if is_valid_movement(unit, current_pos, pos):
				options.append(pos)
	
	return options

func get_charge_targets(unit: Unit) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	var current_pos = unit.position
	var max_charge = 12  # 2D6 maximum
	
	for x in range(max(0, current_pos.x - max_charge), min(board_size.x, current_pos.x + max_charge + 1)):
		for y in range(max(0, current_pos.y - max_charge), min(board_size.y, current_pos.y + max_charge + 1)):
			var pos = Vector2i(x, y)
			var unit_at_pos = get_unit_at_position(pos)
			
			if unit_at_pos and unit_at_pos.player_owner != unit.player_owner:
				var distance = calculate_distance(current_pos, pos)
				if distance <= max_charge:
					targets.append(pos)
	
	return targets

func get_board_state() -> String:
	var state = "Board State:\n"
	for y in range(board_size.y):
		var row = ""
		for x in range(board_size.x):
			var pos = Vector2i(x, y)
			var unit = get_unit_at_position(pos)
			if unit:
				if unit.player_owner == 1:
					row += "1"
				else:
					row += "2"
			else:
				var terrain_type = get_terrain_at_position(pos)
				match terrain_type:
					"obstacle":
						row += "#"
					"cover":
						row += "C"
					_:
						row += "."
		state += row + "\n"
	return state
