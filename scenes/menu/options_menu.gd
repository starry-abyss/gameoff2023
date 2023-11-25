extends Control


signal on_back_pressed
signal on_group_color_change(group: Gameplay.HackingGroups, color: Color)

@export var hide_background_effect := false
@export var show_options_button := false

@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/Control/Volume
@onready var sound_slider: HSlider = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/Control2/Volume2
@onready var background = $Background
@onready var team_1_color_button = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/Control3/HBoxContainer/TeamColor1
@onready var team_2_color_button = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/Control3/HBoxContainer/TeamColor2
@onready var options: Button = $Options


func _ready():
	team_1_color_button.color = StaticData.color_pink
	team_2_color_button.color = StaticData.color_blue
	music_slider.value = FMODStudioModule.get_studio_system().get_bus("bus:/Music Bus").get_volume().volume * 100
	if hide_background_effect:
		background.visible = false
	#if show_options_button:
		#options.visible = true


func _on_volume_value_changed(value):
	var bus = FMODStudioModule.get_studio_system().get_bus("bus:/Music Bus")
	#if bus:
	bus.set_volume(value / 100.0)
	
	UIHelpers.audio_event("Ui/Ui_Slider")


func _on_color_picker_button_color_changed(color):
	StaticData.color_pink = color
	on_group_color_change.emit(Gameplay.HackingGroups.PINK, color)
	

func _on_color_picker_button_2_color_changed(color):
	StaticData.color_blue = color
	on_group_color_change.emit(Gameplay.HackingGroups.BLUE, color)


func change_theme_color(color):
	var ui_nodes = [$Panel, $Back, music_slider, sound_slider, background, team_1_color_button, team_2_color_button, options]
	UIHelpers.override_ui_node_theme_with_color(ui_nodes, color)


#func _on_options_pressed() -> void:
	#options.disabled = true
	#set_content_visible(true)


func _on_back_pressed():
	on_back_pressed.emit()
	#set_content_visible(false)
	#options.disabled = false


#func set_content_visible(visible: bool):
	#$Panel.visible = visible
	#$MarginContainer.visible = visible
	#$Back.visible = visible
