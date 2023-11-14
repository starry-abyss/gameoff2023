extends Control


signal go_to_options_menu


func _on_play_pressed():
	get_tree().change_scene_to_file("res://maps/test1.tscn")
	
	UIHelpers.audio_event("Ui/Ui_Start")


func _on_options_pressed():
	go_to_options_menu.emit()


func _on_quit_pressed():
	UIHelpers.audio_event("Ui/Ui_Quit")
	
	# TODO: wait for the sound to end before exiting
	get_tree().quit()
