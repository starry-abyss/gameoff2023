class_name Gameplay
extends Node3D

@onready var battle_area = %battle_area
@onready var battle_ui = %battle_ui

enum UnitTypes { CENTRAL_NODE, TOWER_NODE, WORM, TROJAN, VIRUS }
enum TargetTypes { UNIT, TILE, SELF }
enum HackingGroups { PINK, BLUE, NEUTRAL }
enum ControllerType { PLAYER, AI }

var current_turn_group: HackingGroups = HackingGroups.PINK

var who_controls_blue: ControllerType = ControllerType.PLAYER
var who_controls_pink: ControllerType = ControllerType.PLAYER

var units = []
var firewalls = {}
var selected_unit: Unit = null

var map_size: Vector2i = Vector2i(20, 11)
var tiles = []

var distances = []

var cached_path = []
var destination_for_cached_path = Vector2i(-1, -1)

const NotCalculated = -1
const Unreachable = -2 # for blocking attacks through firewalls

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
				
				var tile_neighbors = UIHelpers.get_tile_neighbor_list(pos_to_explore)
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

func tower_pos_to_firewall_index(tile_pos1: Vector2i, tile_pos2: Vector2i) -> int:
	var index1 = tile_pos_to_tile_index(tile_pos1)
	var index2 = tile_pos_to_tile_index(tile_pos2)
	
	const multiplier = 256 * 256
	if index1 > index2:
		return index2 * multiplier + index1
	else:
		return index1 * multiplier + index2

func init_firewall(index: int):
	var firewall = preload("res://art/firewall.tscn").instantiate()
	firewalls[index] = firewall
	
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var mesh_instances = find_children("", "MeshInstance3D")
	for mi in mesh_instances:
		mi.material_override = material
	
	battle_area.add_child(firewall)
	
	# TODO: position, rotate and scale properly

func firewall_set_tint(index: int):
	# TODO: set tint
	pass

func update_firewalls(init = false):
	var towers_already_updated = []
	for unit in units:
		if unit.type == UnitTypes.TOWER_NODE:
			var neighbor_towers = get_neighbor_towers(unit)
			for nt in neighbor_towers:
				if !towers_already_updated.has(nt):
					var firewall_index = tower_pos_to_firewall_index(unit.tile_pos, nt.tile_pos)
					if init:
						init_firewall(firewall_index)
					else:
						if unit.group == nt.group:
							firewalls[firewall_index].visible = true
							
							firewall_set_tint(firewall_index)
						else:
							firewalls[firewall_index].visible = false
			
			towers_already_updated.append(unit)

func get_neighbor_towers(starting_unit: Unit):
	var towers = []
	
	var tile_neighbors = UIHelpers.get_tile_neighbor_list(starting_unit.tile_pos)
	for direction in tile_neighbors:
		var tile_pos = starting_unit.tile_pos
		while true:
			tile_pos += direction
			if is_tile_pos_out_of_bounds(tile_pos):
				break
			
			var unit_found = find_unit_by_tile_pos(tile_pos)
			if unit_found != null && unit_found.is_static():
				if unit_found.type == UnitTypes.TOWER_NODE:
					towers.append(unit_found)
				
				break
	
	return towers

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
			tile.global_transform.origin = Vector3(pos.x, 0.0, pos.y)
			
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

func remove_unit(unit: Unit):
	if unit == selected_unit:
		select_unit(null)
	
	units.erase(unit)
	unit.on_click.disconnect(battle_ui._on_unit_click)
	unit.to_be_removed = true
	
	battle_ui._on_unit_destroy(unit)

func spawn_unit(tile_pos: Vector2i, type: UnitTypes, group: HackingGroups, imaginary = false) -> bool:
	if is_tile_pos_out_of_bounds(tile_pos):
		return false
	
	var tile = tiles[tile_pos_to_tile_index(tile_pos)]
	if tile == null:
		return false
	
	var old_unit = find_unit_by_tile_pos(tile_pos)
	if old_unit != null:
		return false
	
	if !imaginary:
		var unit = preload("res://scenes/unit.tscn").instantiate()
		unit.type = type
		unit.group = group
		unit.tile_pos = tile_pos
		
		if unit.is_static():
			tile.group = group
		
		battle_area.add_child(unit)
		units.append(unit)
		
		unit.update_model_pos()
		
		unit.on_click.connect(battle_ui._on_unit_click)
		
		battle_ui._on_unit_spawn(unit)
		
		#unit.hp = 1
	
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
		var unit_at_pos: Unit = find_unit_by_tile_pos(tile_pos)
		if unit_at_pos == null:
			var result = order_move(tile_pos)
			battle_ui._on_order_processed(result, selected_unit)
		else:
			if unit_at_pos.group == current_turn_group:
				click_unit(unit_at_pos)
				pass
			else: # unit_at_pos.can_attack():
				var result = order_attack(unit_at_pos)
				battle_ui._on_order_processed(result, selected_unit)

func click_unit(unit_to_select: Unit):
	if unit_to_select.group == current_turn_group && !is_ai_turn():
		if selected_unit == unit_to_select:
			select_unit(null)
		else:
			select_unit(unit_to_select)

func give_order(ability_id: String, target):
	var order_callable = Callable(self, "order_ability_" + ability_id)
	var result = false
	
	if StaticData.ability_stats[ability_id].target == Gameplay.TargetTypes.UNIT && target is Vector2i:
		target = find_unit_by_tile_pos(target)
		if target == null:
			battle_ui._on_order_processed(result, selected_unit)
			return
	
	var stats = StaticData.ability_stats[ability_id]
	if selected_unit.ap >= stats.ap && selected_unit.get_cooldown(ability_id) == 0:
		
		result = order_callable.call(target, false)
		
		if result:
			# if the selected unit wasn't removed during the order execution
			if selected_unit != null:
				# need to prevent AP from going below zero,
				# if during the order execution AP already became zero
				selected_unit.ap = max(0, selected_unit.ap - stats.ap)
				selected_unit.cooldowns[ability_id] = stats.cooldown
	
	battle_ui._on_order_processed(result, selected_unit)

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
	var units_in_the_same_group_before_selected_unit = []
	var units_in_the_same_group_after_selected_unit = []
	var amount_of_other_units_with_spare_ap = 0
	
	var found_selected_unit = false
	for unit in units:
		if unit.group == current_turn_group: # && 
			if unit == selected_unit:
				found_selected_unit = true
			else:
				if found_selected_unit:
					units_in_the_same_group_after_selected_unit.append(unit)
				else:
					units_in_the_same_group_before_selected_unit.append(unit)
			
				if unit.ap > 0:
					amount_of_other_units_with_spare_ap += 1
	
	if amount_of_other_units_with_spare_ap > 0:
		# cycle - first after, then before
		for unit in units_in_the_same_group_after_selected_unit:
			if unit.ap > 0:
				select_unit(unit)
				return
		
		for unit in units_in_the_same_group_before_selected_unit:
			if unit.ap > 0:
				select_unit(unit)
				return
	elif selected_unit.ap == 0:
		select_unit(null)

func teleport_unit(unit: Unit, new_tile_pos: Vector2i):
	unit.tile_pos = new_tile_pos
	#unit.update_model_pos()
	
	things_have_updated()

func order_ability_self_modify(new_type: UnitTypes, imaginary = false) -> bool:
	if selected_unit == null:
		return false
	
	if !imaginary:
		selected_unit.type = new_type
		selected_unit.ap = 0
		
		select_unit(null)
	
	return true

func order_ability_self_modify_to_trojan(target_not_used, imaginary = false) -> bool:
	return order_ability_self_modify(UnitTypes.TROJAN, imaginary)

func order_ability_self_modify_to_virus(target_not_used, imaginary = false) -> bool:
	return order_ability_self_modify(UnitTypes.VIRUS, imaginary)

func order_ability_repair(target: Unit, imaginary = false) -> bool:
	if selected_unit == null || target == selected_unit:
		return false
	
	if target.group != selected_unit.group:
		return false
	
	if target.hp == target.hp_max:
		return false
	
	if !imaginary:
		var hp_before = target.hp
		target.hp = target.hp_max
		
		var hp_delta = target.hp - hp_before
		if hp_delta > 0:
			battle_ui._on_unit_hp_change(target, hp_delta)
	
	return true

func order_ability_scale(target_tile_pos: Vector2i, imaginary = false) -> bool:
	if selected_unit == null:
		return false
	
	if !is_tile_walkable(target_tile_pos):
		return false
	
	var distance = distances[tile_pos_to_tile_index(target_tile_pos)]
	if distance <= 0:
		return false
	
	var target_is_neighbor = \
		UIHelpers.tile_pos_distance(selected_unit.tile_pos, target_tile_pos) == 1
	
	if !target_is_neighbor:
		return false
	
	if !imaginary:
		spawn_unit(target_tile_pos, UnitTypes.WORM, selected_unit.group)
		var new_worm = find_unit_by_tile_pos(target_tile_pos)
		
		new_worm.ap = 0
		selected_unit.ap = 0
	
	return true

func order_ability_reset(target_tile_pos: Vector2i, imaginary = false) -> bool:
	if selected_unit == null:
		return false
	
	var tile = get_tile(target_tile_pos)
	if tile == null || tile.group != selected_unit.group:
		return false
	
	if !imaginary:
		var apply_reset = func(tile_pos):
			var unit = find_unit_by_tile_pos(tile_pos)
			if unit != null && !unit.is_static():
				#remove_unit(unit)
				# same as remove, but should trigger the damage visualization
				hurt_unit(unit, 99999999)
		
		apply_reset.call(target_tile_pos)
		for_all_tile_pos_around(target_tile_pos, apply_reset)
	
	return true

func order_ability_capture_tower(target: Unit, imaginary = false) -> bool:
	if selected_unit == null:
		return false
	
	if target.type != UnitTypes.TOWER_NODE || target.group != HackingGroups.NEUTRAL:
		return false
	
	var target_is_neighbor = \
		UIHelpers.tile_pos_distance(selected_unit.tile_pos, target.tile_pos) == 1
	
	if !target_is_neighbor:
		return false
	
	if !imaginary:
		target.group = selected_unit.group
		
		remove_unit(selected_unit)
	
	return true

func order_ability_backdoor(target_tile_pos: Vector2i, imaginary = false) -> bool:
	if selected_unit == null:
		return false
	
	# doesn't make sense for Trojan to target precisely itself
	if selected_unit.tile_pos == target_tile_pos:
		return false
	
	if !imaginary:
		var tile_neighbors_from = UIHelpers.get_tile_neighbor_list(target_tile_pos)
		var tile_neighbors_to = UIHelpers.get_tile_neighbor_list(selected_unit.tile_pos)
		for i in range(tile_neighbors_from.size()):
			var tile_pos_from = target_tile_pos + tile_neighbors_from[i]
			var tile_pos_to = selected_unit.tile_pos + tile_neighbors_to[i]
			
			var unit_from = find_unit_by_tile_pos(tile_pos_from)
			
			if unit_from != null && !unit_from.is_static() \
				&& unit_from.group == selected_unit.group \
				&& unit_from != selected_unit \
				&& is_tile_walkable(tile_pos_to):
					teleport_unit(unit_from, tile_pos_to)
					unit_from.update_model_pos()
		
		#var apply_backdoor = func(tile_pos):
		#	var unit = find_unit_by_tile_pos(tile_pos)
		#	if unit != null && !unit.is_static():
		#		pass
		
		# won't teleport from the center or cursor, 
		# because can't teleport on the same tile as Trojan
		#apply_backdoor.call(target_tile_pos)
		#for_all_tile_pos_around(target_tile_pos, apply_backdoor)
	
	return true

func hurt_unit(target: Unit, amount: int):
	if amount <= 0:
		return
	
	var hp_before = target.hp
	target.hp = max(target.hp - amount, 0)
	
	var damage = hp_before - target.hp
	if damage > 0:
		battle_ui._on_unit_hp_change(target, -damage)
	
	if target.hp == 0:
		var this_is_the_end = (target.type == UnitTypes.CENTRAL_NODE)
		var unit_group_originally = target.group
		
		if target.can_be_destroyed():
			remove_unit(target)
		else:
			target.group = HackingGroups.NEUTRAL
		
		if this_is_the_end:
			end_battle(unit_group_originally)

func end_battle(who_lost: HackingGroups):
	for unit in units:
		if unit.group == who_lost:
			unit.group = HackingGroups.NEUTRAL
	
	var who_won = flip_group(who_lost)
	battle_ui._on_battle_end(who_won)

func order_attack(target: Unit, imaginary = false) -> bool:
	if selected_unit == null || target == selected_unit || !selected_unit.can_attack():
		return false
	
	if target.hp == 0:
		return false
	
	# to block attack through firewalls, but it only works with range 1 attacks
	# TODO: for range 2+ attacks need to cast rays as an extra step
	var distance = distances[tile_pos_to_tile_index(target.tile_pos)]
	if distance == Unreachable:
		return false
	
	if UIHelpers.tile_pos_distance(selected_unit.tile_pos, target.tile_pos) <= selected_unit.attack_range:
		if selected_unit.ap >= selected_unit.ap_cost_of_attack:
			if !imaginary:
				selected_unit.ap -= selected_unit.ap_cost_of_attack
				
				var attack_power = selected_unit.attack + randi_range(0, selected_unit.attack_extra)
				hurt_unit(target, attack_power)
			
			return true
	
	return false

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
				battle_ui._on_hide_path()
			
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
			var tile_neighbors = UIHelpers.get_tile_neighbor_list(tile_pos)
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

func flip_group(group: HackingGroups) -> HackingGroups:
	if group == HackingGroups.BLUE:
		return HackingGroups.PINK
	else:
		return HackingGroups.BLUE

func end_turn(silent = false):
	if !silent:
		select_unit(null)
	
	current_turn_group = flip_group(current_turn_group)
	
	for unit in units:
		if unit.group == current_turn_group:
			for cd in unit.cooldowns.keys():
				unit.cooldowns[cd] = max(0, unit.cooldowns[cd] - 1)
			
			unit.ap = unit.ap_max
		
			if unit.type == UnitTypes.CENTRAL_NODE:
				for_all_tile_pos_around(unit.tile_pos, \
					func(tile_pos): spawn_unit(tile_pos, UnitTypes.WORM, unit.group))
	
	update_firewalls()
	
	if !silent:
		battle_ui._on_playing_group_changed(current_turn_group, is_ai_turn())

func get_tile(tile_pos: Vector2i) -> Tile:
	if is_tile_pos_out_of_bounds(tile_pos):
		return null
	
	return tiles[tile_pos_to_tile_index(tile_pos)]

func for_all_tiles_around(tile_pos: Vector2i, f: Callable):
	var tile_neighbors = UIHelpers.get_tile_neighbor_list(tile_pos)
	for adj_tile_pos in tile_neighbors:
		var adj_tile_pos_absolute = tile_pos + adj_tile_pos
		var tile = get_tile(adj_tile_pos_absolute)
		if tile != null:
			f.call(tile)

func for_all_tile_pos_around(tile_pos: Vector2i, f: Callable):
	var tile_neighbors = UIHelpers.get_tile_neighbor_list(tile_pos)
	for adj_tile_pos in tile_neighbors:
		var adj_tile_pos_absolute = tile_pos + adj_tile_pos
		var tile = get_tile(adj_tile_pos_absolute)
		if tile != null:
			f.call(adj_tile_pos_absolute)

func _ready():
	battle_ui.get_node("CanvasLayer/end_turn").connect("pressed", end_turn)
	battle_ui.get_node("CanvasLayer/select_idle_unit").connect("pressed", select_next_unit)
	battle_ui.connect("tile_clicked", click_tile)
	battle_ui.connect("tile_hovered", hover_tile)
	battle_ui.connect("unit_clicked", click_unit)
	battle_ui.connect("order_given", give_order)
	
	tiles.resize(map_size.x * map_size.y)
	distances.resize(tiles.size())
	for x in range(map_size.x):
		for y in range(map_size.y):
			add_tile(Vector2i(x, y))
	
	remove_tile(Vector2i(19, 0))
	remove_tile(Vector2i(19, 2))
	remove_tile(Vector2i(19, 4))
	remove_tile(Vector2i(19, 6))
	remove_tile(Vector2i(19, 8))
	remove_tile(Vector2i(19, 10))
	
	#spawn_unit(Vector2i(0, 1), UnitTypes.WORM, HackingGroups.BLUE)
	#spawn_unit(Vector2i(0, 2), UnitTypes.TROJAN, HackingGroups.BLUE)
	#spawn_unit(Vector2i(0, 3), UnitTypes.VIRUS, HackingGroups.PINK)
	
	#spawn_unit(Vector2i(6, 3), UnitTypes.TROJAN, HackingGroups.PINK)
	
	spawn_unit(Vector2i(5, 5), UnitTypes.CENTRAL_NODE, HackingGroups.PINK)
	spawn_unit(Vector2i(6, 8), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	spawn_unit(Vector2i(3, 2), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	spawn_unit(Vector2i(2, 5), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	spawn_unit(Vector2i(3, 8), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	spawn_unit(Vector2i(6, 2), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	spawn_unit(Vector2i(8, 5), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	
	for_all_tile_pos_around(Vector2i(5, 5), func(tile1): \
		for_all_tile_pos_around(tile1, func(tile2): \
			for_all_tile_pos_around(tile2, func(tile3): \
				get_tile(tile3).group = HackingGroups.PINK)))
	
	var blue_offset = Vector2i(9, 0)
	
	spawn_unit(blue_offset + Vector2i(5, 5), UnitTypes.CENTRAL_NODE, HackingGroups.BLUE)
	spawn_unit(blue_offset + Vector2i(6, 8), UnitTypes.TOWER_NODE, HackingGroups.BLUE)
	spawn_unit(blue_offset + Vector2i(3, 2), UnitTypes.TOWER_NODE, HackingGroups.BLUE)
	spawn_unit(blue_offset + Vector2i(2, 5), UnitTypes.TOWER_NODE, HackingGroups.BLUE)
	spawn_unit(blue_offset + Vector2i(3, 8), UnitTypes.TOWER_NODE, HackingGroups.BLUE)
	spawn_unit(blue_offset + Vector2i(6, 2), UnitTypes.TOWER_NODE, HackingGroups.BLUE)
	spawn_unit(blue_offset + Vector2i(8, 5), UnitTypes.TOWER_NODE, HackingGroups.BLUE)
	
	for_all_tile_pos_around(blue_offset + Vector2i(5, 5), func(tile1): \
		for_all_tile_pos_around(tile1, func(tile2): \
			for_all_tile_pos_around(tile2, func(tile3): \
				get_tile(tile3).group = HackingGroups.BLUE)))
	
	#remove_unit(find_unit_by_tile_pos(Vector2i(6, 2)))
	
	#tiles[tile_pos_to_tile_index(Vector2i(4, 5))].group = HackingGroups.PINK
	#UIHelpers.for_all_tiles_in_radius(Vector2i(5, 5), 3, func(tile): tile.group = HackingGroups.PINK)
	
	#UIHelpers.for_all_tile_pos_in_radius
	
	update_firewalls(true)
	
	# contains some init code that otherwise will be called only starting the next turn
	# for first group to init
	end_turn(true)
	# for second group to init
	end_turn()
	pass
