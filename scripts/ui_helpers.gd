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

const Size = Vector2(1.2, 1.2)
const Origin = Vector2(1.0, 1.0)

func world_pos_to_tile_pos(world_pos: Vector2) -> Vector2i:
	var tile_pos = Vector2i(0, 0)
	
	tile_pos.y = floori((world_pos.y - Origin.y + Size.y * 0.5) / Size.y)
	tile_pos.x = floori((world_pos.x - Origin.x + Size.x * 0.5 - (Size.x * 0.5 if tile_pos.y % 2 == 0 else 0.0)) / Size.x)
	
	return tile_pos

func tile_pos_to_world_pos(tile_pos: Vector2i) -> Vector2:
	var x = (tile_pos.x * Size.x) + (Size.x * 0.5 if tile_pos.y % 2 == 0 else 0.0)
	var y = tile_pos.y * Size.y
	
	return Vector2(Origin.x + x, Origin.y + y)

func snap_world_pos_to_tile_center(world_pos: Vector2) -> Vector2:
	return tile_pos_to_world_pos(world_pos_to_tile_pos(world_pos))
