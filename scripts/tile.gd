extends Node3D

var group: Gameplay.HackingGroups = Gameplay.HackingGroups.NEUTRAL

var debug_distance: Label3D = Label3D.new()

func _on_ready():
	debug_distance.font = preload("res://assets/fonts/ShareTechMono-Regular.ttf")
	debug_distance.font_size = 128
	#debug_distance.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	
	debug_distance.rotate_x(-PI / 2.0)
	
	add_child(debug_distance)
	
	debug_distance.position.y += 0.1
	
	#debug_distance.text = "123"
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
