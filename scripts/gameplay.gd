class_name Gameplay
extends Node3D

@onready var battle_area = %battle_area
@onready var battle_ui = %battle_ui

enum UnitTypes { CENTRAL_NODE, TOWER_NODE, WORM, TROJAN, VIRUS }
enum HackingGroups { PINK, BLUE, NEUTRAL }
enum ControllerType { PLAYER, AI }

var current_turn_group: HackingGroups = HackingGroups.BLUE

var who_controls_blue: ControllerType = ControllerType.PLAYER
var who_controls_pink: ControllerType = ControllerType.PLAYER

var units = []
var selected_unit = null

var map_size: Vector2i = Vector2i(10, 10)
var tiles = []

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

func click_unit(unit_to_select):
	if unit_to_select.group == current_turn_group && !is_ai_turn():
		if selected_unit == unit_to_select:
			select_unit(null)
		else:
			select_unit(unit_to_select)

func select_unit(unit_to_select):
	for unit in units:
		#unit.selected = (unit == unit_to_select)
		pass
	
	selected_unit = unit_to_select
	
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
	
func order_move(new_tile_pos: Vector2i, imaginary = false) -> bool:
	if selected_unit == null:
		return false
	
	var path = get_path_to_tile_pos()
	if path.size() > 0:
		if selected_unit.ap >= path.size():
			if !imaginary:
				selected_unit.ap -= path.size()
				selected_unit.tile_pos = new_tile_pos
			
			return true
		
	return false
	
func get_path_to_tile_pos():
	return []
	
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
	
	for x in range(map_size.x):
		for y in range(map_size.y):
			var tile = preload("res://art/tile.tscn").instantiate()
			tiles.append(tile)
			battle_area.add_child(tile)
			
			var pos = UIHelpers.tile_pos_to_world_pos(Vector2i(x, y))
			tile.transform.origin = Vector3(pos.x, 0.0, pos.y)
	
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
