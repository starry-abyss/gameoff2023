class_name Gameplay
extends Node3D

@onready var battle_area = %battle_area
@onready var battle_ui = %battle_ui

enum UnitTypes { CENTRAL_NODE, TOWER_NODE, WORM, TROJAN, VIRUS }
enum HackingGroups { PINK, BLUE, NEUTRAL }
enum ControllerType { PLAYER, AI }

var current_turn_group: HackingGroups = HackingGroups.PINK

var who_controls_blue: ControllerType = ControllerType.PLAYER
var who_controls_pink: ControllerType = ControllerType.PLAYER

var units = []
var selected_unit: Unit = null

var map_size: Vector2i = Vector2i(10, 10)
var tiles = []

var distances = []
var cached_path = []
var destination_for_cached_path = Vector2i(-1, -1)

const NotCalculated = -1
const Tile_neighbors_even_row = [ Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1), \
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1) ]

const Tile_neighbors_odd_row = [ Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), \
	Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1) ]

func get_neighbor_list(tile_pos: Vector2i):
	return Tile_neighbors_even_row if tile_pos.y % 2 == 0 else Tile_neighbors_odd_row

func calculate_distances():
	# invalidate the path cache
	destination_for_cached_path = Vector2i(-1, -1)
	
	if selected_unit == null:
		for tile in tiles:
			if tile != null:
				tile._on_hide_debug_distance()
	else:
		for i in range(distances.size()):
			distances[i] = NotCalculated
		
		var tile_pos = selected_unit.tile_pos
		
		distances[tile_pos_to_tile_index(tile_pos)] = 0
		#if selected_unit.can_move():
		if !selected_unit.is_static():
			var pos_to_explore_stack = [ tile_pos ]
			while pos_to_explore_stack.size() > 0:
				var pos_to_explore = pos_to_explore_stack.pop_front()
				
				var current_distance = distances[tile_pos_to_tile_index(pos_to_explore)]
				
				var tile_neighbors = get_neighbor_list(pos_to_explore)
				for adj_tile_pos in tile_neighbors:
					var pos_to_explore_next = pos_to_explore + adj_tile_pos
					
					if is_tile_walkable(pos_to_explore_next):
						var neighbor_distance_old = distances[tile_pos_to_tile_index(pos_to_explore_next)]
						if neighbor_distance_old == NotCalculated: # || neighbor_distance_old > current_distance + 1:
							#pos_to_explore_array.append(pos_to_explore)
							distances[tile_pos_to_tile_index(pos_to_explore_next)] = current_distance + 1
							pos_to_explore_stack.append(pos_to_explore_next)
				
		for i in range(tiles.size()):
			if tiles[i] != null:
				tiles[i]._on_show_debug_distance(distances[i])
	pass

func is_tile_walkable(tile_pos: Vector2i):
	# there is no tile even
	if is_tile_pos_out_of_bounds(tile_pos):
		return false
	
	# there is a tile, but no unit is standing on it
	if tiles[tile_pos_to_tile_index(tile_pos)] != null:
		if find_unit_by_tile_pos(tile_pos) == null:
			return true
	
	return false

func is_ai_turn() -> bool:
	if current_turn_group == HackingGroups.BLUE && who_controls_blue == ControllerType.AI:
		return true
	if current_turn_group == HackingGroups.PINK && who_controls_pink == ControllerType.AI:
		return true
	return false

func tile_index_to_tile_pos(index: int) -> Vector2i:
	return Vector2i(index % map_size.x, index / map_size.y)

func tile_pos_to_tile_index(tile_pos: Vector2i) -> int:
	return tile_pos.y * map_size.x + tile_pos.x

func is_tile_pos_out_of_bounds(tile_pos: Vector2i):
	if tile_pos.x < 0 || tile_pos.y < 0:
		return true
	
	if tile_pos.x >= map_size.x || tile_pos.y >= map_size.y:
		return true
	
	# for hexagons all even rows are shorter by 1
	#if tile_pos.y % 2 == 0 && tile_pos.x >= map_size.x - 1:
	#	return true

func add_tile(tile_pos: Vector2i):
	if !is_tile_pos_out_of_bounds(tile_pos):
		var current_tile = tiles[tile_pos_to_tile_index(tile_pos)]
		if current_tile == null:
			var tile = preload("res://art/tile.tscn").instantiate()
			
			#tiles.append(tile)
			tiles[tile_pos_to_tile_index(tile_pos)] = tile
			battle_area.add_child(tile)
			
			var pos = UIHelpers.tile_pos_to_world_pos(tile_pos)
			tile.transform.origin = Vector3(pos.x, 0.0, pos.y)
			
			tile.set_script(preload("res://scripts/tile.gd"))
			tile._on_ready()

# TODO: don't remove right away, first play an animation
func remove_tile(tile_pos: Vector2i):
	if !is_tile_pos_out_of_bounds(tile_pos):
		var current_tile = tiles[tile_pos_to_tile_index(tile_pos)]
		if current_tile != null:
			current_tile.queue_free()
			
			tiles[tile_pos_to_tile_index(tile_pos)] = null
		
		var unit = find_unit_by_tile_pos(tile_pos)
		if unit != null:
			remove_unit(unit)

# TODO: don't remove right away, first play an animation
func remove_unit(unit: Unit):
	units.erase(unit)
	unit.on_click.disconnect(click_unit)
	unit.queue_free()

func spawn_unit(tile_pos: Vector2i, type: UnitTypes, group: HackingGroups, imaginary = false) -> bool:
	var old_unit = find_unit_by_tile_pos(tile_pos)
	if old_unit != null:
		return false
	
	if !imaginary:
		var unit = preload("res://scenes/unit.tscn").instantiate()
		unit.type = type
		unit.group = group
		unit.tile_pos = tile_pos
		
		battle_area.add_child(unit)
		units.append(unit)
		
		unit.update_model_pos()
		
		unit.on_click.connect(click_unit)
	
	return true

func find_unit_by_tile_pos(tile_pos: Vector2i):
	for unit in units:
		if unit.tile_pos.x == tile_pos.x && unit.tile_pos.y == tile_pos.y:
			return unit
	
	return null

func hover_tile(tile_pos: Vector2i):
	if !is_tile_pos_out_of_bounds(tile_pos):
		# TODO: make order_move support reporting not enough AP reason
		if order_move(tile_pos, true):
			var path = get_path_to_tile_pos(tile_pos)
			battle_ui._on_show_path(selected_unit, path)
		else:
			battle_ui._on_hide_path()
	else:
		battle_ui._on_hide_path()

func click_tile(tile_pos: Vector2i):
	# TODO: also select units by clicking tiles
	
	if !is_tile_pos_out_of_bounds(tile_pos):
		order_move(tile_pos)

func click_unit(unit_to_select: Unit):
	if unit_to_select.group == current_turn_group && !is_ai_turn():
		if selected_unit == unit_to_select:
			select_unit(null)
		else:
			select_unit(unit_to_select)

func select_unit(unit_to_select: Unit, no_ui = false):
	for unit in units:
		#unit.selected = (unit == unit_to_select)
		pass
	
	selected_unit = unit_to_select
	calculate_distances()
	
	if no_ui:
		battle_ui._on_unit_selection_changed(null)
	else:
		battle_ui._on_unit_selection_changed(selected_unit)

func select_next_unit():
	var units_with_spare_ap = []
	
	# TODO: select next unit after currently selected one (cycle)
	
	#var selected_unit_id = 0
	for unit in units:
		if unit.group == current_turn_group && unit.ap > 0:
			units_with_spare_ap.append(unit)
		#if unit.selected:
		#	selected_unit_id
	
	if units_with_spare_ap.size() > 0:
		if selected_unit == null:
			select_unit(units_with_spare_ap[0])
		else:
			select_unit(units_with_spare_ap[0])
			
			#for i in units_with_spare_ap.size():
			#	if unit.selected:
			pass
	else:
		select_unit(null)

func teleport_unit(unit: Unit, new_tile_pos: Vector2i):
	selected_unit.tile_pos = new_tile_pos
	#unit.update_model_pos()
	
	things_have_updated()

func order_move(new_tile_pos: Vector2i, imaginary = false) -> bool:
	if selected_unit == null: #|| !selected_unit.can_move():
		return false
	
	#if !is_tile_walkable(new_tile_pos):
	if is_tile_pos_out_of_bounds(new_tile_pos):
		return false
	
	var distance = distances[tile_pos_to_tile_index(new_tile_pos)]
	#var distance = path.size()
	if distance > 0:
		if selected_unit.ap >= distance:
			if !imaginary:
				selected_unit.ap -= distance
				
				# the order is important here!
				var path = get_path_to_tile_pos(new_tile_pos)
				teleport_unit(selected_unit, new_tile_pos)
				battle_ui._on_unit_move(selected_unit, path)
			
			return true
		#else:
		#	if imaginary:
		#		battle_ui._on_show_path_not_enough_ap(selected_unit, path)
		
	return false
	
func get_path_to_tile_pos(tile_pos: Vector2i):
	#if destination_for_cached_path == tile_pos:
	#	return cached_path
	
	var distance = distances[tile_pos_to_tile_index(tile_pos)]
	var path = []
	
	if distance > 0:
		path.push_front(tile_pos)
		
		while distance > 0:
			var tile_neighbors = get_neighbor_list(tile_pos)
			for adj_tile_pos in tile_neighbors:
				var pos_to_explore_next = tile_pos + adj_tile_pos
				
				if !is_tile_pos_out_of_bounds(pos_to_explore_next):
					var next_distance = distances[tile_pos_to_tile_index(pos_to_explore_next)]
					if next_distance < distance && next_distance != NotCalculated:
						path.push_front(pos_to_explore_next)
						tile_pos = pos_to_explore_next
						distance = next_distance
			
			# const NotInitialized = 9999999
			#var min_distance_with_pos = [NotInitialized, Vector2i(0, 0)]
			#for adj_tile_pos in tile_neighbors:
			#	var pos_to_explore_next = tile_pos + adj_tile_pos
			#	var next_distance = distances[tile_pos_to_tile_index(pos_to_explore_next)]
			#	if min_distance_with_pos[0] > next_distance:
			#		min_distance_with_pos = [next_distance, pos_to_explore_next]
			#	
			#	path.push_front(pos_to_explore_next)
			#	tile_pos = pos_to_explore_next
			
	return path

func things_have_updated():
	calculate_distances()

func end_turn():
	select_unit(null)
	
	if current_turn_group == HackingGroups.BLUE:
		current_turn_group = HackingGroups.PINK
	else:
		current_turn_group = HackingGroups.BLUE
	
	for unit in units:
		if unit.group == current_turn_group:
			unit.ap = unit.ap_max

func _ready():
	battle_ui.get_node("CanvasLayer/end_turn").connect("pressed", end_turn)
	battle_ui.get_node("CanvasLayer/select_idle_unit").connect("pressed", select_next_unit)
	battle_ui.connect("tile_clicked", click_tile)
	battle_ui.connect("tile_hovered", hover_tile)
	
	tiles.resize(map_size.x * map_size.y)
	distances.resize(tiles.size())
	for x in range(map_size.x):
		for y in range(map_size.y):
			add_tile(Vector2i(x, y))
	
	remove_tile(Vector2i(5, 6))
	
	spawn_unit(Vector2i(0, 1), UnitTypes.WORM, HackingGroups.BLUE)
	spawn_unit(Vector2i(6, 3), UnitTypes.TROJAN, HackingGroups.PINK)
	
	spawn_unit(Vector2i(3, 5), UnitTypes.CENTRAL_NODE, HackingGroups.PINK)
	spawn_unit(Vector2i(3, 7), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	spawn_unit(Vector2i(3, 3), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	spawn_unit(Vector2i(1, 4), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	spawn_unit(Vector2i(1, 6), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	spawn_unit(Vector2i(4, 4), UnitTypes.TOWER_NODE, HackingGroups.BLUE)
	spawn_unit(Vector2i(4, 6), UnitTypes.TOWER_NODE, HackingGroups.BLUE)
	
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	pass

#func _input(event):
#	if event is InputEventMouseButton:
#		print("testete Mouse Click/Unclick at: ", event.position)
