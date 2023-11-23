extends Node

# The Y coordinate from 3D is zero, 
# so we use (X, Z) instead of (X, 0.0, Z) for the world pos
func screen_pos_to_world_pos(screen_pos: Vector2) -> Vector2:
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return Vector2(-99999.0, -99999.0)
	
	var from = camera.project_ray_origin(screen_pos)
	var to = from + camera.project_ray_normal(screen_pos) * 10000
	var world_pos = Plane(Vector3.UP, 0.0).intersects_ray(from, to)
	
	if world_pos == null:
		return Vector2(-99999.0, -99999.0)
	
	return Vector2(world_pos.x, world_pos.z)

# TODO
func world_pos_to_screen_pos(mouse_pos: Vector2) -> Vector2:
	return Vector2(0, 0)

func world_pos_to_tile_pos(world_pos: Vector2) -> Vector2i:
	var tile_pos = Vector2i(0, 0)
	
	# + Size.y * 0.5
	# + Size.x * 0.5
	
	tile_pos.y = floori((world_pos.y - StaticData.map_origin.y) / StaticData.tile_size.y)
	tile_pos.x = floori((world_pos.x - StaticData.map_origin.x - (StaticData.tile_size.x * 0.5 if tile_pos.y & 1 == 0 else 0.0)) / StaticData.tile_size.x)
	
	var tile_pos_first_try: Vector2i = tile_pos
	
	var min_distance = world_pos.distance_to(tile_pos_to_world_pos(tile_pos_first_try))
	var tile_neighbors = UIHelpers.get_tile_neighbor_list(tile_pos_first_try)
	
	#print("=======")
	#print("click world_pos: ", world_pos)
	#print("distance 1st: ", min_distance, " tile_pos: ", tile_pos_first_try, " world_pos: ", tile_pos_to_world_pos(tile_pos_first_try))
	for adj_tile_pos in tile_neighbors:
		var adj_tile_pos_absolute = tile_pos_first_try + adj_tile_pos
		var distance = world_pos.distance_to(tile_pos_to_world_pos(adj_tile_pos_absolute))
		#print("distance: ", distance, " tile_pos: ", adj_tile_pos_absolute, " world_pos: ", tile_pos_to_world_pos(adj_tile_pos_absolute))
		if distance < min_distance:
			min_distance = distance
			tile_pos = adj_tile_pos_absolute
	
	#print("result: ", tile_pos)
	
	return tile_pos

func tile_pos_to_world_pos(tile_pos: Vector2i) -> Vector2:
	var x = (tile_pos.x * StaticData.tile_size.x) + (StaticData.tile_size.x * 0.5 if tile_pos.y & 1 == 0 else 0.0)
	var y = tile_pos.y * StaticData.tile_size.y
	
	return Vector2(StaticData.map_origin.x + x, StaticData.map_origin.y + y)

func snap_world_pos_to_tile_center(world_pos: Vector2) -> Vector2:
	return tile_pos_to_world_pos(world_pos_to_tile_pos(world_pos))
	
const Tile_neighbors_even_row = [ Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1), \
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1) ]
const Tile_neighbors_odd_row = [ Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), \
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1) ]

# coordinates relative to tile_pos
func get_tile_neighbor_list(tile_pos: Vector2i):
	return Tile_neighbors_even_row if tile_pos.y & 1 == 0 else Tile_neighbors_odd_row

# https://www.redblobgames.com/grids/hexagons
func tile_pos_distance(tile_pos1: Vector2i, tile_pos2: Vector2i) -> int:
	var cube_distance = func (a, b) -> int:
		return (abs(a.q - b.q) + abs(a.r - b.r) + abs(a.s - b.s)) / 2

	var evenr_to_cube = func (hex):
		var cube = {}
		cube["q"] = hex.x - (hex.y + (hex.y & 1)) / 2
		cube["r"] = hex.y
		cube["s"] = -cube.q - cube.r
		return cube
	
	var cube1 = evenr_to_cube.call(tile_pos1)
	var cube2 = evenr_to_cube.call(tile_pos2)
	return cube_distance.call(cube1, cube2)

func group_to_color(which_group: Gameplay.HackingGroups) -> Color:
	if which_group == Gameplay.HackingGroups.PINK:
		return StaticData.color_pink
	if which_group == Gameplay.HackingGroups.BLUE:
		return StaticData.color_blue
	return StaticData.color_neutral

func audio_set_parameter(parameter_name: String, value: float):
	FMODStudioModule.get_studio_system().set_parameter_by_name(parameter_name, value, false)

func audio_event(event_name: String):
	FMODRuntime.play_one_shot_path("event:/" + event_name)

func audio_event3d(event_name: String, tile_pos: Vector2i):
	var pos = tile_pos_to_world_pos(tile_pos)
	FMODRuntime.play_one_shot_path("event:/" + event_name, Vector3(pos.x, 0.0, pos.y))

func audio_event3d_loop_start(event_name: String, unit: Unit):
	#unit.get_node("sound_loop").event.set_event_ref_from_description( \
	#	FMODRuntime.get_event_description_path("event:/" + event_name))
	
	unit.get_node("sound_loop").play()
	
func audio_event3d_loop_end(unit: Unit):
	unit.get_node("sound_loop").stop()

func quit_the_game():
	# TODO: for debug, to be removed:
	#UIHelpers.audio_set_parameter("Winner", Gameplay.HackingGroups.PINK)
	
	UIHelpers.audio_event("Ui/Ui_Quit")
	
	await get_tree().create_timer(0.5).timeout
	
	FMODStudioModule.shutdown()
	
	get_tree().quit()

