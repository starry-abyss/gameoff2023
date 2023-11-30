extends Node


func get_aabb(model) -> AABB:
	var aabb
	var mesh_instances = model.find_children("", "MeshInstance3D") as Array[MeshInstance3D]
	for mesh in mesh_instances:
		if aabb == null:
			aabb = mesh.get_aabb()
		else:
			aabb = mesh.get_aabb().merge(aabb) 
	return aabb
	
func get_y_offset(type) -> float:
	if type == Gameplay.UnitTypes.CENTRAL_NODE:
		return -1.0
	elif type == Gameplay.UnitTypes.WORM:
		return 1.0
	
	return 0.0
