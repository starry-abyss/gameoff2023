extends Node

# The Y coordinate from 3D is zero, 
# so we use (X, Z) instead of (X, 0.0, Z) for the world pos
func screen_pos_to_world_pos(screen_pos: Vector2) -> Vector2:
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return Vector2(-99999.0, -99999.0)
	
	var from = camera.project_ray_origin(screen_pos)
	var to = from + camera.project_ray_normal(screen_pos) * 100
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
	tile_pos.x = floori((world_pos.x - StaticData.map_origin.x - (StaticData.tile_size.x * 0.5 if tile_pos.y % 2 == 0 else 0.0)) / StaticData.tile_size.x)
	
	return tile_pos

func tile_pos_to_world_pos(tile_pos: Vector2i) -> Vector2:
	var x = (tile_pos.x * StaticData.tile_size.x) + (StaticData.tile_size.x * 0.5 if tile_pos.y % 2 == 0 else 0.0)
	var y = tile_pos.y * StaticData.tile_size.y
	
	return Vector2(StaticData.map_origin.x + x, StaticData.map_origin.y + y)

func snap_world_pos_to_tile_center(world_pos: Vector2) -> Vector2:
	return tile_pos_to_world_pos(world_pos_to_tile_pos(world_pos))
	
const Tile_neighbors_even_row = [ Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1), \
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1) ]
const Tile_neighbors_odd_row = [ Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), \
	Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1) ]

func get_tile_neighbor_list(tile_pos: Vector2i):
	return Tile_neighbors_even_row if tile_pos.y % 2 == 0 else Tile_neighbors_odd_row

func audio_event(event_name: String):
	FMODRuntime.play_one_shot_path("event:/" + event_name)
