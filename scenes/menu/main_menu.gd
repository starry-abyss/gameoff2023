extends Control


signal go_to_options_menu

@onready var credits: Control = $Credits
@onready var glitch_effect: Sprite2D = $Effect
@onready var show_glitch_effect_timer = $Timer

static var settings_load = true

func _ready():
	var list = []
	UIHelpers.get_ui_theme_node_recurrsively(self, list)
	UIHelpers.override_ui_node_theme_with_color(list, StaticData.main_menu_color)
	
	DisplayServer.window_set_title("Repro " + ProjectSettings.get_setting("application/config/version"))
	
	if settings_load:
		var config = ConfigFile.new()
		var err = config.load("user://groups.cfg")

		# If the file didn't load, ignore it.
		if err == OK:
			%pink_controller.selected = config.get_value("groups", "rebels")
			%blue_controller.selected = config.get_value("groups", "cyberpolice")

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
	
	if true:
		var config = ConfigFile.new()
		
		config.set_value("groups", "rebels", %pink_controller.selected)
		config.set_value("groups", "cyberpolice", %blue_controller.selected)
		
		config.save("user://groups.cfg")

func _on_options_pressed():
	go_to_options_menu.emit()


func _on_quit_pressed():
	UIHelpers.quit_the_game()


func _on_timer_timeout():
	glitch_effect.visible = false
	get_tree().change_scene_to_file("res://maps/test1.tscn")
	

func _on_credits_pressed() -> void:
	credits.visible = true
