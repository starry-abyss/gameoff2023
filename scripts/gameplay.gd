class_name Gameplay
extends Node3D

@onready var battle_area = %battle_area
@onready var battle_ui = %battle_ui
@onready var options_menu: Control = $CanvasLayer/OptionsMenu
@onready var options: Button = $CanvasLayer/Options

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

var map_size: Vector2i = Vector2i(28, 19)
var tiles = []

var distances = []

# aren't used actually
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
		
		# let's assume static units' abilities aren't blocked by firewalls in any way
		if !selected_unit.is_static():
			var inside_an_enemy_firewall = false
			for fw_index in firewalls.keys():
				if firewalls[fw_index].visible:
					var start_end_tile_pos = firewall_index_to_tile_pos(fw_index)
					var start_tile_pos = Vector2i(start_end_tile_pos.x, start_end_tile_pos.y)
					var end_tile_pos = Vector2i(start_end_tile_pos.z, start_end_tile_pos.w)
					
					var tower = find_unit_by_tile_pos(start_tile_pos)
					assert(tower != null)
					# neutral can't have firewalls, so it's an enemy's one
					if tower.group != selected_unit.group:
						if is_unit_inside_the_firewall(selected_unit, start_tile_pos, end_tile_pos):
							inside_an_enemy_firewall = true
							# mark two lines parallel to the firewall as Unreachable to trap the unit
							# 1) find the direction to the second tower
							var i = find_direction_for_tower_tile_pos(start_tile_pos, end_tile_pos)
							# 2) find neighbor tiles, between which lies this direction (left and right ones)
							var neighbors = [(i - 1 + 6) % 6, (i + 1) % 6]
							# 3) get the length of the firewall
							var distance = UIHelpers.tile_pos_distance(start_tile_pos, end_tile_pos)
							for n in neighbors:
								var tile_pos = start_tile_pos + UIHelpers.get_tile_neighbor_list(start_tile_pos)[n]
								# mark all line Unreachable
								for j in range(distance):
									# start marking from the first tile
									distances[tile_pos_to_tile_index(tile_pos)] = Unreachable
									
									var direction = UIHelpers.get_tile_neighbor_list(tile_pos)[i]
									tile_pos += direction
							
							break
				
			if !inside_an_enemy_firewall:
				# mark all enemy firewalls as obstacles
				for fw_index in firewalls.keys():
					if firewalls[fw_index].visible:
						var start_end_tile_pos = firewall_index_to_tile_pos(fw_index)
						var start_tile_pos = Vector2i(start_end_tile_pos.x, start_end_tile_pos.y)
						var end_tile_pos = Vector2i(start_end_tile_pos.z, start_end_tile_pos.w)
						
						var tower = find_unit_by_tile_pos(start_tile_pos)
						assert(tower != null)
						# neutral can't have firewalls, so it's an enemy's one
						if tower.group != selected_unit.group:
							var distance = UIHelpers.tile_pos_distance(start_tile_pos, end_tile_pos)
							var i = find_direction_for_tower_tile_pos(start_tile_pos, end_tile_pos)
							var tile_pos = start_tile_pos
							# mark all line Unreachable except tower positions (start and end)
							for j in range(distance-1):
								var direction = UIHelpers.get_tile_neighbor_list(tile_pos)[i]
								tile_pos += direction
								
								# start marking from the second tile
								distances[tile_pos_to_tile_index(tile_pos)] = Unreachable
						
		# end of firewalls-related pre-processing
		
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

# return an index to be used with the array returned from UIHelpers.get_tile_neighbor_list()
func find_direction_for_tower_tile_pos(tile_pos1: Vector2i, tile_pos2: Vector2i) -> int:
	var distance = UIHelpers.tile_pos_distance(tile_pos1, tile_pos2)
	for i in range(6):
		var tile_pos = tile_pos1
		for j in range(distance):
			var direction = UIHelpers.get_tile_neighbor_list(tile_pos)[i]
			tile_pos += direction
		
		if tile_pos == tile_pos2:
			return i
	
	assert(false)
	return 0

func is_unit_inside_the_firewall(unit: Unit, start_tile_pos: Vector2i, end_tile_pos: Vector2i) -> bool:
	var tile_pos = start_tile_pos
	var distance = UIHelpers.tile_pos_distance(start_tile_pos, end_tile_pos)
	var direction = find_direction_for_tower_tile_pos(start_tile_pos, end_tile_pos)
	for i in range(distance-1):
		tile_pos += UIHelpers.get_tile_neighbor_list(tile_pos)[direction]
		if tile_pos == unit.tile_pos:
			return true
	
	return false

const firewall_index_multiplier: int = 256 * 256
func tower_pos_to_firewall_index(tile_pos1: Vector2i, tile_pos2: Vector2i) -> int:
	#print("to index: ", tile_pos1, tile_pos2)
	
	var index1 = tile_pos_to_tile_index(tile_pos1)
	var index2 = tile_pos_to_tile_index(tile_pos2)
	
	#print("sub-index: ", index1, ", ", index2)
	
	# if we swap start and end tower positions for a firewall, the index should be the same
	if index1 > index2:
		return index2 * firewall_index_multiplier + index1
	else:
		return index1 * firewall_index_multiplier + index2

func firewall_index_to_tile_pos(index: int) -> Vector4i:
	#print("fw index to sub-index: ", index, " ", index % firewall_index_multiplier, " ", index / firewall_index_multiplier)
	
	var tile_pos1 = tile_index_to_tile_pos(index % firewall_index_multiplier)
	var tile_pos2 = tile_index_to_tile_pos(index / firewall_index_multiplier)
	
	#print("fw tile pos: ", tile_pos1, tile_pos2)
	
	return Vector4i(tile_pos1.x, tile_pos1.y, tile_pos2.x, tile_pos2.y)

func init_firewall(index: int):
	var firewall = preload("res://art/firewall.tscn").instantiate()
	firewalls[index] = firewall
	
	#var material = StandardMaterial3D.new()
	#material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	#material.cull_mode = BaseMaterial3D.CULL_DISABLED
	#material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var mesh_instances = firewall.find_children("", "MeshInstance3D")
	for mi in mesh_instances:
	#	mi.material_override = material
		mi.material_override = preload("res://art/firewall_material.tres").duplicate()
	
	battle_area.add_child(firewall)
	
	var tile_pos_start_end = firewall_index_to_tile_pos(index)
	
	var start_pos = UIHelpers.tile_pos_to_world_pos(Vector2i(tile_pos_start_end.x, tile_pos_start_end.y))
	var end_pos = UIHelpers.tile_pos_to_world_pos(Vector2i(tile_pos_start_end.z, tile_pos_start_end.w))
	
	var vector: Vector2 = end_pos - start_pos
	
	#start_pos += vector.normalized() * StaticData.tile_size.x * 0.5
	
	firewall.position = (Vector3(start_pos.x, 0.0, start_pos.y) + Vector3(end_pos.x, 0.0, end_pos.y)) * 0.5
	
	firewall.scale.x = start_pos.distance_to(end_pos) - StaticData.tile_size.x * 1.1
	
	#firewall.rotate_y(-vector.angle())
	firewall.rotation = Vector3(0, -vector.angle(), 0)
	
	print("fw index: ", index)
	print("firewall init: ", tile_pos_start_end)
	
	# TODO: position, rotate and scale properly

func firewall_set_tint(index: int, color: Color):
	color.a = 0.3
	
	var mesh_instances = firewalls[index].find_children("", "MeshInstance3D")
	for mi in mesh_instances:
		mi.material_override.albedo_color = color
	pass

func update_firewalls(init = false):
	# not sure if this is needed
	for fw in firewalls:
		firewalls[fw].visible = false
	
	var towers_already_updated = []
	for unit in units:
		if unit.type == UnitTypes.TOWER_NODE:
			var neighbor_towers = get_neighbor_towers(unit)
			for nt in neighbor_towers:
				if !towers_already_updated.has(nt):
					var firewall_index = tower_pos_to_firewall_index(unit.tile_pos, nt.tile_pos)
					if init:
						init_firewall(firewall_index)
					
					if unit.group == nt.group && unit.group != HackingGroups.NEUTRAL:
						firewalls[firewall_index].visible = true
						
						firewall_set_tint(firewall_index, UIHelpers.group_to_color(unit.group))
					else:
						firewalls[firewall_index].visible = false
						pass
			
			towers_already_updated.append(unit)
	
	if !init:
		calculate_distances()

func get_neighbor_towers(starting_unit: Unit):
	var towers = []
	
	for i in range(6):
		var tile_pos = starting_unit.tile_pos
		while true:
			var tile_neighbors = UIHelpers.get_tile_neighbor_list(tile_pos)
			tile_pos += tile_neighbors[i]
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
	return Vector2i(index % map_size.x, index / map_size.x)

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
			tile.set_process(true)

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

func highlight_idle_units():
	for t in tiles:
		if t != null:
			t.set_tint(Color.BLACK)
	
	for unit in units:
		if unit.group == current_turn_group && unit.ap > 0:
			get_tile(unit.tile_pos).set_tint(StaticData.tile_good_target)

func tint_all_tiles(ability_id: String):
	for t in tiles:
		if t != null:
			t.set_tint(Color.BLACK)
	
	var target_type_is_self = StaticData.ability_stats[ability_id].target == Gameplay.TargetTypes.SELF
	for i in range(tiles.size()):
		var t = tiles[i]
		if t != null:
			if target_type_is_self:
				if tile_pos_to_tile_index(selected_unit.tile_pos) == i:
					t.set_tint(StaticData.tile_good_target)
				else:
					t.set_tint(Color.BLACK)
			else:
				tint_tiles(ability_id, tile_index_to_tile_pos(i), \
				ability_id != "backdoor", ability_id == "backdoor" || ability_id == "reset", true)

func tint_tiles(ability_id: String, center_tile_pos: Vector2i, show_center: bool = true, show_neighbors: bool = false, no_reset: bool = false):
	var bad_target_color = StaticData.tile_bad_target
	
	if !no_reset:
		for t in tiles:
			if t != null:
				t.set_tint(Color.BLACK)
	else:
		bad_target_color = Color.BLACK
	
	# ignore what UI requested :D
	if selected_unit == null:
		return
	
	var new_color = StaticData.tile_good_target
	# TODO: bad and duplicated code, but not much time until release
	if ability_id != "":
		if !give_order(ability_id, center_tile_pos, true):
			new_color = bad_target_color
	else:
		var unit_at_pos = find_unit_by_tile_pos(center_tile_pos)
		if unit_at_pos == null:
			if !give_order("move", center_tile_pos, true):
				new_color = bad_target_color
		else:
			if selected_unit.type == UnitTypes.VIRUS:
				if !give_order("virus_attack", unit_at_pos, true):
					new_color = bad_target_color
			elif selected_unit.type == UnitTypes.TOWER_NODE:
				if !give_order("tower_attack", unit_at_pos, true):
					new_color = bad_target_color
			else:
				new_color = bad_target_color
	
	if show_center:
		var tile = get_tile(center_tile_pos)
		if tile != null:
			if !no_reset || (tile.get_tint() != StaticData.tile_good_target):
				tile.set_tint(new_color)
	
	if show_neighbors:
		var tile_neighbors = UIHelpers.get_tile_neighbor_list(center_tile_pos)
		for adj_tile_pos in tile_neighbors:
			var pos_to_explore_next = center_tile_pos + adj_tile_pos
			var tile = get_tile(pos_to_explore_next)
			if tile != null:
				if !no_reset || (tile.get_tint() != StaticData.tile_good_target):
					tile.set_tint(new_color)
		
	pass

func hover_tile(tile_pos: Vector2i):
	#tint_tiles(tile_pos)
	
	if !is_tile_pos_out_of_bounds(tile_pos):
		#if selected_unit != null:
		#	selected_unit.set_look_at(UIHelpers.tile_pos_to_world_pos(tile_pos))
		
		#for i in range(tiles.size()):
		#	var tile = tiles[i]
		#	if tile != null:
		#		tile.get_node("tile_wireframe").visible = i == tile_pos_to_tile_index(tile_pos)
			
		# TODO: make order_move support reporting not enough AP reason
		if order_ability_move(tile_pos, true):
			var path = get_path_to_tile_pos(tile_pos)
			battle_ui._on_show_path(selected_unit, path)
		else:
			battle_ui._on_hide_path()
	else:
		battle_ui._on_hide_path()
	
	var hovered_unit = find_unit_by_tile_pos(tile_pos)
	if hovered_unit != null:
		battle_ui._on_unit_show_stats(hovered_unit, hovered_unit == selected_unit)
	else:
		battle_ui._on_unit_show_stats(selected_unit, true)

func click_tile(tile_pos: Vector2i):
	# TODO: also select units by clicking tiles
	
	if !is_tile_pos_out_of_bounds(tile_pos):
		var unit_at_pos: Unit = find_unit_by_tile_pos(tile_pos)
		if unit_at_pos == null:
			var result = order_ability_move(tile_pos)
			battle_ui._on_order_processed(result, selected_unit)
		else:
			if unit_at_pos.group == current_turn_group:
				click_unit(unit_at_pos)
				pass
			else: # unit_at_pos.can_attack():
				#var result = false
				if selected_unit != null && selected_unit.can_attack():
					if selected_unit.type == UnitTypes.VIRUS:
						give_order("virus_attack", unit_at_pos) #result = order_ability_virus_attack(unit_at_pos)
					elif selected_unit.type == UnitTypes.TOWER_NODE:
						give_order("tower_attack", unit_at_pos) #result = order_ability_tower_attack(unit_at_pos)
					
					#battle_ui._on_order_processed(result, selected_unit)

func click_unit(unit_to_select: Unit):
	if unit_to_select.group == current_turn_group && !is_ai_turn():
		if selected_unit == unit_to_select:
			select_unit(null)
		else:
			select_unit(unit_to_select)

func give_order(ability_id: String, target, imaginary = false) -> bool:
	var order_callable = Callable(self, "order_ability_" + ability_id)
	var result = false
	
	if StaticData.ability_stats[ability_id].target == Gameplay.TargetTypes.UNIT && target is Vector2i:
		target = find_unit_by_tile_pos(target)
		if target == null:
			if !imaginary:
				battle_ui._on_order_processed(result, selected_unit)
			return result
	
	var stats = StaticData.ability_stats[ability_id]
	if selected_unit.ap >= stats.ap && selected_unit.get_cooldown(ability_id) == 0:
		
		result = order_callable.call(target, imaginary)
		
		if imaginary:
			return result
		
		if result:
			# if the selected unit wasn't removed during the order execution
			if selected_unit != null:
				# move cost is per tile, so it'll be processed during the order execution
				if ability_id != "move":
					# need to prevent AP from going below zero,
					# if during the order execution AP already became zero
					selected_unit.ap = max(0, selected_unit.ap - stats.ap)
				
				selected_unit.cooldowns[ability_id] = stats.cooldown
	
	if !imaginary:
		if result:
			calculate_distances()
		battle_ui._on_order_processed(result, selected_unit)
	
	return result

func select_unit(unit_to_select: Unit, no_ui = false):
	for unit in units:
		#unit.selected = (unit == unit_to_select)
		pass
		
	#if selected_unit != unit_to_select:
	#	UIHelpers.audio_event("Ui/Ui_UnitChanged")
	
	selected_unit = unit_to_select
	calculate_distances()
	
	if no_ui:
		battle_ui._on_unit_selection_changed(null)
	else:
		battle_ui._on_unit_selection_changed(selected_unit)
		battle_ui._on_unit_show_stats(selected_unit, true)

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
	elif selected_unit != null && selected_unit.ap == 0:
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
		
		# disallow restoring AP right after Virus' creation
		if new_type == UnitTypes.VIRUS:
			selected_unit.cooldowns["integrate"] = 1
			
			UIHelpers.audio_event3d("SFX/Worms/SFX_MutateVirus", selected_unit.tile_pos)
		else:
			UIHelpers.audio_event3d("SFX/Worms/SFX_MutateTrojan", selected_unit.tile_pos)
		
		#select_unit(null)
	
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
	
	var tile = get_tile(target.tile_pos)
	if tile == null || tile.group != selected_unit.group:
		return false
	
	if !imaginary:
		heal_unit(target, StaticData.ability_stats["repair"].restored_hp)
		
		UIHelpers.audio_event3d("SFX/Kernel Node/SFX_Patch", selected_unit.tile_pos)
	
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
		
		selected_unit.ap = 0
		
		# copy some stats from the parent Worm
		new_worm.ap = 0
		new_worm.hp = selected_unit.hp
		new_worm.cooldowns["scale"] = StaticData.ability_stats["scale"].cooldown
		
		UIHelpers.audio_event3d("SFX/Worms/SFX_Double", selected_unit.tile_pos)
	
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
		
		UIHelpers.audio_event3d("SFX/Kernel Node/SFX_Reset", selected_unit.tile_pos)
	
	return true

func order_ability_capture_tower(target: Unit, imaginary = false) -> bool:
	if selected_unit == null:
		return false
	
	if (target.type != UnitTypes.TOWER_NODE && target.type != UnitTypes.CENTRAL_NODE) \
		|| target.group != HackingGroups.NEUTRAL:
		return false
	
	var target_is_neighbor = \
		UIHelpers.tile_pos_distance(selected_unit.tile_pos, target.tile_pos) == 1
	
	if !target_is_neighbor:
		return false
	
	if !imaginary:
		target.group = selected_unit.group
		
		target.hp = target.hp_max
		
		UIHelpers.audio_event3d("SFX/Trojan/SFX_CaptureNode", selected_unit.tile_pos)
		
		remove_unit(selected_unit)
		
		update_firewalls()
	
	return true

func order_ability_integrate(target: Unit, imaginary = false) -> bool:
	if selected_unit == null:
		return false
	
	if target.type != UnitTypes.WORM:
		return false
	
	if target.group != selected_unit.group:
		return false
	
	var target_is_neighbor = \
		UIHelpers.tile_pos_distance(selected_unit.tile_pos, target.tile_pos) == 1
	
	if !target_is_neighbor:
		return false
	
	if !imaginary:
		remove_unit(target)
		
		UIHelpers.audio_event3d("SFX/Virus/SFX_Integrate", selected_unit.tile_pos)
	
	return true

func check_ability_spread(target: Unit) -> bool:
	if selected_unit == null || target == null || target == selected_unit:
		return false
	
	if target.hp == 0:
		return false
	
	if target.is_static():
		return false
	
	# allow to only attack enemies
	if target.group != flip_group(selected_unit.group):
		return false
	
	return true

func execute_ability_spread(target: Unit) -> void:
	var ability_stats = StaticData.ability_stats["spread"]
	var attack_power = ability_stats.attack + randi_range(0, ability_stats.attack_extra)
	hurt_unit(target, attack_power)

func order_ability_spread(target: Unit, imaginary = false) -> bool:
	if !check_ability_spread(target):
		return false
	
	var target_is_neighbor = \
		UIHelpers.tile_pos_distance(selected_unit.tile_pos, target.tile_pos) == 1
	
	if !target_is_neighbor:
		return false
	
	if !imaginary:
		execute_ability_spread(target)
		var affected_units = [ target ]
		
		var pos_to_explore_stack = [ target.tile_pos ]
		while pos_to_explore_stack.size() > 0:
			var pos_to_explore = pos_to_explore_stack.pop_front()
			
			var tile_neighbors = UIHelpers.get_tile_neighbor_list(pos_to_explore)
			for adj_tile_pos in tile_neighbors:
				var pos_to_explore_next = pos_to_explore + adj_tile_pos
				
				var current_distance = distances[tile_pos_to_tile_index(pos_to_explore_next)]
				
				var unit_to_damage = find_unit_by_tile_pos(pos_to_explore_next)
				if check_ability_spread(unit_to_damage) && current_distance != Unreachable && !affected_units.has(unit_to_damage):
					execute_ability_spread(unit_to_damage)
					affected_units.append(unit_to_damage)
					
					pos_to_explore_stack.append(pos_to_explore_next)
	
		UIHelpers.audio_event3d("SFX/Virus/SFX_Spread", selected_unit.tile_pos)
	
	return true

func order_ability_backdoor(target_tile_pos: Vector2i, imaginary = false) -> bool:
	if selected_unit == null:
		return false
	
	# doesn't make sense for Trojan to target precisely itself
	if selected_unit.tile_pos == target_tile_pos:
		return false
	
	# if no friendly malware nearby then don't waste AP
	# need scopes for variables with the same name, so if true :'D
	if true:
		var found_someone = false
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
				found_someone = true
				break
		
		if !found_someone:
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
					
					# after teleporting each unit will have only 1 AP at max to re-group
					if unit_from.ap > 1:
						unit_from.ap = 1
					
					unit_from.update_model_pos()
					
		UIHelpers.audio_event3d("SFX/Trojan/SFX_Backdoor", selected_unit.tile_pos)
		
		#var apply_backdoor = func(tile_pos):
		#	var unit = find_unit_by_tile_pos(tile_pos)
		#	if unit != null && !unit.is_static():
		#		pass
		
		# won't teleport from the center or cursor, 
		# because can't teleport on the same tile as Trojan
		#apply_backdoor.call(target_tile_pos)
		#for_all_tile_pos_around(target_tile_pos, apply_backdoor)
	
	return true

func heal_unit(target: Unit, amount: int):
	if amount <= 0:
		return
	
	var hp_before = target.hp
	
	target.hp += amount
	
	if target.hp > target.hp_max:
		target.hp = target.hp_max
	
	var hp_change = target.hp - hp_before
	if hp_change > 0:
		battle_ui._on_unit_hp_change(target, hp_change)

func hurt_unit(target: Unit, amount: int):
	if amount <= 0:
		return
	
	var hp_before = target.hp
	target.hp = max(target.hp - amount, 0)
	
	var damage = hp_before - target.hp
	target.on_hurt()
	if damage > 0:
		battle_ui._on_unit_hp_change(target, -damage)
	
	if target.hp == 0:
		var this_is_the_end = (target.type == UnitTypes.CENTRAL_NODE)
		if this_is_the_end:
			# maybe there are more than one Kernel
			for u in units:
				if u.type == UnitTypes.CENTRAL_NODE && u.group == target.group:
					if target != u:
						this_is_the_end = false
						break
		
		var unit_group_originally = target.group
		
		if target.can_be_destroyed():
			remove_unit(target)
		else:
			target.group = HackingGroups.NEUTRAL
			update_firewalls()
			
			UIHelpers.audio_event3d("SFX/Kernel Node/SFX_KernelDamage", target.tile_pos)
		
		if this_is_the_end:
			end_battle(unit_group_originally)
	
	calculate_distances()

func end_battle(who_lost: HackingGroups):
	var units_array = units.duplicate()
	for unit in units_array:
		if unit.group == who_lost:
			unit.group = HackingGroups.NEUTRAL
			
			if !unit.is_static():
				hurt_unit(unit, 99999999)
		
			if unit.type == UnitTypes.TOWER_NODE:
				unit.hp = 0
	
	for tile in tiles:
		if tile != null && tile.group == who_lost:
			tile.group = HackingGroups.NEUTRAL
	
	update_firewalls()
	
	var who_won = flip_group(who_lost)
	battle_ui._on_battle_end(who_won)
	
	UIHelpers.audio_set_parameter("Winner", who_won)
	UIHelpers.audio_event("DX/Dx_End")

func order_ability_virus_attack(target: Unit, imaginary = false) -> bool:
	return order_attack(target, imaginary, StaticData.ability_stats["virus_attack"])

func order_ability_tower_attack(target: Unit, imaginary = false) -> bool:
	return order_attack(target, imaginary, StaticData.ability_stats["tower_attack"])

func order_attack(target: Unit, imaginary: bool, ability_stats) -> bool:
	if selected_unit == null || target == selected_unit || !selected_unit.can_attack():
		return false
	
	if target.hp == 0:
		return false
	
	# allow to only attack enemies
	if target.group != flip_group(selected_unit.group):
		return false
	
	# to block attack through firewalls, but it only works with range 1 attacks
	# TODO: for range 2+ attacks need to cast rays as an extra step
	var distance = distances[tile_pos_to_tile_index(target.tile_pos)]
	if distance == Unreachable:
		return false
	
	if UIHelpers.tile_pos_distance(selected_unit.tile_pos, target.tile_pos) <= ability_stats.attack_range:
		#if selected_unit.ap >= ability_stats.ap:
			if !imaginary:
				#selected_unit.ap -= ability_stats.ap
				
				var attack_power = ability_stats.attack + randi_range(0, ability_stats.attack_extra)
				hurt_unit(target, attack_power)
				
				if selected_unit.type == UnitTypes.TOWER_NODE:
					# TODO: move to animation code
					var ball = selected_unit.use_tower_ball()
					ball.visible = false
					
					UIHelpers.audio_event3d("SFX/Anti Virus Node/SFX_DamageRange", selected_unit.tile_pos)
				elif selected_unit.type == UnitTypes.VIRUS:
					UIHelpers.audio_event3d("SFX/Virus/SFX_Damage", selected_unit.tile_pos)
				
				print("attack power: ", attack_power)
			
			return true
	
	return false

func order_ability_move(new_tile_pos: Vector2i, imaginary = false) -> bool:
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
					if next_distance < distance && next_distance != NotCalculated && next_distance != Unreachable:
						tile_pos = pos_to_explore_next
						distance = next_distance
						
						path.push_front(tile_pos)
						break
			
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
	
	# end of turn
	for unit in units:
		if unit.group == current_turn_group:
			for cd in unit.cooldowns.keys():
				unit.cooldowns[cd] = max(0, unit.cooldowns[cd] - 1)
			
			unit.ap = unit.ap_max
			
			unit.restore_tower_balls()
	
	# switch turn
	current_turn_group = flip_group(current_turn_group)
	
	# start of turn
	for unit in units:
		if unit.group == current_turn_group:
			if unit.type == UnitTypes.CENTRAL_NODE:
				if unit.hp < unit.hp_max:
					UIHelpers.audio_event3d("SFX/Kernel Node/SFX_Maintenance", unit.tile_pos)
				
				heal_unit(unit, StaticData.ability_stats["self_repair"].restored_hp)
				
				if (!unit.cooldowns.has("spawn_worms") || unit.cooldowns["spawn_worms"] <= 0):
					unit.cooldowns["spawn_worms"] = StaticData.ability_stats["spawn_worms"].cooldown
					UIHelpers.audio_event3d("SFX/Kernel Node/SFX_GenerateWorms", unit.tile_pos)
					
					for_all_tile_pos_around(unit.tile_pos, \
						func(tile_pos): spawn_unit(tile_pos, UnitTypes.WORM, unit.group))
	
	#update_firewalls()
	
	if !silent:
		battle_ui._on_playing_group_changed(current_turn_group, is_ai_turn())
		_init_group_color()

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


func _on_back_pressed() -> void:
	options_menu.visible = false
	
	
func _on_options_pressed() -> void:
	options_menu.visible = true


func _init_group_color():
	if current_turn_group == Gameplay.HackingGroups.PINK:
		on_group_color_change(current_turn_group, StaticData.color_pink)
	else:
		on_group_color_change(current_turn_group, StaticData.color_blue)


func on_group_color_change(group: Gameplay.HackingGroups, color: Color):
	for unit in units:
		if unit.group == group:
			unit.set_tint(color)
	for tile in tiles:
		if tile != null and tile.group == group:
			tile.set_wireframe_tint(color)
	update_firewalls()
	battle_ui.change_theme_color()
	if group == current_turn_group:
		options_menu.change_theme_color(color)
		UIHelpers.override_ui_node_theme_with_color([options], color)


func _ready():
	battle_ui.get_node("CanvasLayer/end_turn").connect("pressed", end_turn)
	battle_ui.get_node("CanvasLayer/end_turn").connect("mouse_entered", highlight_idle_units)
	battle_ui.get_node("CanvasLayer/select_idle_unit").connect("pressed", select_next_unit)
	battle_ui.get_node("CanvasLayer/select_idle_unit").connect("mouse_entered", highlight_idle_units)
	
	battle_ui.connect("tile_clicked", click_tile)
	battle_ui.connect("tile_hovered", hover_tile)
	battle_ui.connect("tiles_need_tint", tint_tiles)
	battle_ui.connect("tiles_need_tint_all", tint_all_tiles)
	battle_ui.connect("unit_clicked", click_unit)
	battle_ui.connect("order_given", give_order)
	battle_ui.connect("animation_finished", func(): select_unit(selected_unit))
	options_menu.connect("on_group_color_change", on_group_color_change)
	options_menu.connect("on_back_pressed", _on_back_pressed)
	
	tiles.resize(map_size.x * map_size.y)
	distances.resize(tiles.size())
	for x in range(map_size.x):
		for y in range(map_size.y):
			add_tile(Vector2i(x, y))
	
	#for i in range(map_size.y / 2 + 1):
	#	remove_tile(Vector2i(map_size.x - 1, i * 2))
	
	for i in range(map_size.y / 2 + 1):
		for j in range(4 - i / 2):
			remove_tile(Vector2i(j, i))
			remove_tile(Vector2i(j, map_size.y - i - 1))
			
			remove_tile(Vector2i(map_size.x - j - 1, i))
			remove_tile(Vector2i(map_size.x - j - 1, map_size.y - i - 1))
	
	remove_tile(Vector2i(23, 0))
	remove_tile(Vector2i(24, 2))
	remove_tile(Vector2i(25, 4))
	remove_tile(Vector2i(26, 6))
	remove_tile(Vector2i(27, 8))
	remove_tile(Vector2i(27, 10))
	remove_tile(Vector2i(26, 12))
	remove_tile(Vector2i(25, 14))
	remove_tile(Vector2i(24, 16))
	remove_tile(Vector2i(23, 18))
	
	#spawn_unit(Vector2i(0, 1), UnitTypes.WORM, HackingGroups.BLUE)
	#spawn_unit(Vector2i(13, 3), UnitTypes.TROJAN, HackingGroups.BLUE)
	#spawn_unit(Vector2i(0, 3), UnitTypes.VIRUS, HackingGroups.PINK)
	
	#spawn_unit(Vector2i(13, 2), UnitTypes.TROJAN, HackingGroups.PINK)
	#spawn_unit(Vector2i(14, 3), UnitTypes.TROJAN, HackingGroups.PINK)
	
	var pink_offset = Vector2i(4, 4)
	
	spawn_unit(pink_offset + Vector2i(5, 5), UnitTypes.CENTRAL_NODE, HackingGroups.PINK)
	spawn_unit(pink_offset + Vector2i(6, 8), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	spawn_unit(pink_offset + Vector2i(3, 2), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	spawn_unit(pink_offset + Vector2i(2, 5), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	spawn_unit(pink_offset + Vector2i(3, 8), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	spawn_unit(pink_offset + Vector2i(6, 2), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	spawn_unit(pink_offset + Vector2i(8, 5), UnitTypes.TOWER_NODE, HackingGroups.PINK)
	
	for_all_tile_pos_around(pink_offset + Vector2i(5, 5), func(tile1): \
		for_all_tile_pos_around(tile1, func(tile2): \
			for_all_tile_pos_around(tile2, func(tile3): \
				get_tile(tile3).group = HackingGroups.PINK)))
	
	var blue_offset = Vector2i(13, 4)
	
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
	
	UIHelpers.audio_event("DX/Dx_Start")
	pass


# FIXME for test usage!
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("End Turn"):
		end_turn()
