class_name Tile
extends Node3D

var group: Gameplay.HackingGroups = Gameplay.HackingGroups.NEUTRAL:
	set(new_value):
		group = new_value
		set_tint(UIHelpers.group_to_color(new_value))

var debug_distance: Label3D = Label3D.new()
var material = null

func _on_ready():
	debug_distance.font = preload("res://assets/fonts/ShareTechMono-Regular.ttf")
	debug_distance.font_size = 128
	#debug_distance.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	
	debug_distance.rotate_x(-PI / 2.0)
	
	####### 
	add_child(debug_distance)
	
	debug_distance.position.y += 0.1
	
	var mesh_instances = find_children("", "MeshInstance3D")
	var mesh_instance: MeshInstance3D = mesh_instances[-1]
	
	material = StandardMaterial3D.new()
	mesh_instance.material_override = material
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	group = Gameplay.HackingGroups.NEUTRAL
	
	#debug_distance.text = "123"
	pass

func set_tint(color: Color):
	if material != null:
		color.v *= 0.35
		material.albedo_color = color
	pass

func _on_hide_debug_distance():
	debug_distance.text = ""
	pass

func _on_show_debug_distance(distance: int):
	#print("tile pos: ", global_position)
	#print("text pos: ", debug_distance.global_position)
	#print("----")
	
	debug_distance.text = str(distance)
	pass
