class_name Tile
extends Node3D

var group: Gameplay.HackingGroups = Gameplay.HackingGroups.NEUTRAL:
	set(new_value):
		group = new_value
		set_wireframe_tint(UIHelpers.group_to_color(new_value))

var debug_distance: Label3D = Label3D.new()
var material = null
var material_wireframe = null

func _process(delta):
	#if material != null:
	#	material.albedo_color.v = max(0, material.albedo_color.v - delta * 2.0)
	pass

func _on_ready():
	debug_distance.font = preload("res://assets/fonts/ShareTechMono-Regular.ttf")
	debug_distance.font_size = 128
	#debug_distance.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	
	debug_distance.rotate_x(-PI / 2.0)
	
	####### add_child(debug_distance)
	
	debug_distance.position.y += 0.1
	
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	material_wireframe = StandardMaterial3D.new()
	material_wireframe.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_wireframe.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	#var grey_color = Color.WHITE
	#grey_color.v = 0.15
	
	#material_wireframe.albedo_color = grey_color
	
	var mesh_instances = get_node("stone").find_children("", "MeshInstance3D")
	for mesh_instance in mesh_instances:
		mesh_instance.material_override = material
	
	var mesh_instances2 = get_node("tile_wireframe").find_children("", "MeshInstance3D")
	for mesh_instance in mesh_instances2:
		mesh_instance.material_override = material_wireframe
	
	group = Gameplay.HackingGroups.NEUTRAL
	
	set_tint(Color.BLACK)
	
	#debug_distance.text = "123"
	pass

func set_wireframe_tint(color: Color):
	if material != null:
		if group == Gameplay.HackingGroups.NEUTRAL:
			color.v = 0.12
		else:
			color.v = 0.45
		
		material_wireframe.albedo_color = color

func set_tint(color: Color):
	if material != null:
		material.albedo_color = color

func _on_hide_debug_distance():
	debug_distance.text = ""
	pass

func _on_show_debug_distance(distance: int):
	#print("tile pos: ", global_position)
	#print("text pos: ", debug_distance.global_position)
	#print("----")
	
	debug_distance.text = str(distance)
	pass
