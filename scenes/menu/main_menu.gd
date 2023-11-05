extends Control


signal go_to_options_menu


func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/audio.tscn")


func _on_options_pressed():
	go_to_options_menu.emit()


func _on_quit_pressed():
	get_tree().quit()
