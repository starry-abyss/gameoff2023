extends Control


func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
