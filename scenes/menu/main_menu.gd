extends Control


signal go_to_options_menu

@onready var credits: Control = $Credits
@onready var glitch_effect: Sprite2D = $Effect
@onready var show_glitch_effect_timer = $Timer


func _ready():
	var list = []
	UIHelpers.get_ui_theme_node_recurrsively(self, list)
	UIHelpers.override_ui_node_theme_with_color(list, StaticData.main_menu_color)


func _process(delta: float) -> void:
	%Quit.visible = !credits.visible
	%Options.visible = !credits.visible
	%Credits.visible = !credits.visible
	%Logos.visible = !credits.visible

func _on_play_pressed():
	StaticData.who_controls_pink = %pink_controller.selected
	StaticData.who_controls_blue = %blue_controller.selected
	
	show_glitch_effect_timer.start()
	glitch_effect.visible = true
	UIHelpers.audio_event("Ui/Ui_Start")


func _on_options_pressed():
	go_to_options_menu.emit()


func _on_quit_pressed():
	UIHelpers.quit_the_game()


func _on_timer_timeout():
	glitch_effect.visible = false
	get_tree().change_scene_to_file("res://maps/test1.tscn")
	

func _on_credits_pressed() -> void:
	credits.visible = true
