extends Control


signal go_to_options_menu


@onready var show_glitch_effect_timer = $Timer
@onready var effect = $Effect


func _on_play_pressed():
	effect.visible = true
	show_glitch_effect_timer.start()
	UIHelpers.audio_event("Ui/Ui_Start")


func _on_options_pressed():
	go_to_options_menu.emit()


func _on_quit_pressed():
	UIHelpers.quit_the_game()


func _on_timer_timeout():
	effect.visible = false
	get_tree().change_scene_to_file("res://maps/test1.tscn")
