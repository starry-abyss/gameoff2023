extends Control


signal on_back_pressed
signal on_group_color_change(group: Gameplay.HackingGroups, color: Color)

@export var hide_background_effect := true

@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/Control4/VolumeMusic
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/Control2/VolumeSFX
@onready var master_slider: HSlider = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/Control/VolumeMaster
@onready var background = $Background
@onready var effect = $Effect
@onready var team_1_color_button = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/Control3/HBoxContainer/TeamColor1
@onready var team_2_color_button = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/Control3/HBoxContainer/TeamColor2


func _ready():
	team_1_color_button.color = StaticData.color_pink
	team_2_color_button.color = StaticData.color_blue
	music_slider.value = FMODStudioModule.get_studio_system().get_bus("bus:/Music Bus").get_volume().volume * 100
	sfx_slider.value = FMODStudioModule.get_studio_system().get_bus("bus:/Sfx Bus").get_volume().volume * 100
	#master_slider.value = FMODStudioModule.get_studio_system().get_bus("bus:/Master").get_volume().volume * 100
	
	music_slider.value_changed.connect(_on_volume_music_value_changed)
	sfx_slider.value_changed.connect(_on_volume_sfx_value_changed)
	master_slider.value_changed.connect(_on_volume_master_value_changed)
	
	
	if hide_background_effect:
		background.visible = false
		effect.visible = false
	
	if true:
			var button = $MarginContainer/VBoxContainer/Back
	#for button in find_children("", "Button"):
		#if button.get_script() == null:
			button.set_script(preload("res://scripts/button.gd"))
			button._ready()
			button.set_process(true)
			
			button.is_back_button = true

func _on_back_pressed():
	on_back_pressed.emit()


func _on_volume_music_value_changed(value):
	var bus = FMODStudioModule.get_studio_system().get_bus("bus:/Music Bus")
	#if bus:
	bus.set_volume(value / 100.0)
	
	UIHelpers.audio_event("Ui/Ui_Slider")

func _on_volume_sfx_value_changed(value):
	var bus = FMODStudioModule.get_studio_system().get_bus("bus:/Sfx Bus")
	#if bus:
	bus.set_volume(value / 100.0)
	
	UIHelpers.audio_event("Ui/Ui_Slider")

func _on_volume_master_value_changed(value):
	#var bus = FMODStudioModule.get_studio_system().get_bus("bus:/Master Bus")
	#if bus:
	#bus.set_volume(value / 100.0)
	
	UIHelpers.audio_event("Ui/Ui_Slider")

func _on_color_picker_button_color_changed(color):
	StaticData.color_pink = color
	on_group_color_change.emit(Gameplay.HackingGroups.PINK, color)


func _on_color_picker_button_2_color_changed(color):
	StaticData.color_blue = color
	on_group_color_change.emit(Gameplay.HackingGroups.BLUE, color)
