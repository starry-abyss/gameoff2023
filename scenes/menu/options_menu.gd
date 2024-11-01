extends Control


signal on_back_pressed
signal on_group_color_change(group: Gameplay.HackingGroups, color: Color)
signal scroll_speed_change

@export var hide_background_effect := true
@export var show_options_button := false

@onready var music_slider: HSlider = %VolumeMusic
@onready var sfx_slider: HSlider = %VolumeSFX
@onready var master_slider: HSlider = %VolumeMaster

@onready var background = $Background
@onready var team_1_color_button = %TeamColor1
@onready var team_2_color_button = %TeamColor2
@onready var options: Button = $Options

@onready var hints_enabled = %HintsEnabled
@onready var fullscreen = %Fullscreen

func _ready():
	team_1_color_button.color = StaticData.color_pink
	team_2_color_button.color = StaticData.color_blue
	
	team_1_color_button.color_changed.connect(_on_color_picker_button_color_changed)
	team_2_color_button.color_changed.connect(_on_color_picker_button_2_color_changed)
	
	music_slider.value = FMODStudioModule.get_studio_system().get_bus("bus:/Music Bus").get_volume().volume * 100
	sfx_slider.value = FMODStudioModule.get_studio_system().get_bus("bus:/SFX Bus").get_volume().volume * 100
	master_slider.value = FMODStudioModule.get_studio_system().get_bus("bus:/").get_volume().volume * 100
	
	music_slider.value_changed.connect(_on_volume_music_value_changed)
	sfx_slider.value_changed.connect(_on_volume_sfx_value_changed)
	master_slider.value_changed.connect(_on_volume_master_value_changed)
	
	fullscreen.checked = StaticData.fullscreen
	fullscreen.toggled.connect(fullscreen_changed)
	
	hints_enabled.checked = StaticData.show_tutorial_hints
	hints_enabled.toggled.connect(show_tutorial_hints_changed)
	
	if hide_background_effect:
		background.visible = false
	
	if true:
		var button = $Back
#for button in find_children("", "Button"):
	#if button.get_script() == null:
		button.set_script(preload("res://scripts/button.gd"))
		button._ready()
		button.set_process(true)
		
		button.is_back_button = true

func force_update_options():
	scroll_speed_change.emit(%ScrollSpeedMouse.value, %ScrollSpeedKeyboard.value)

func show_tutorial_hints_changed(value):
	StaticData.show_tutorial_hints = value
	
func fullscreen_changed(value):
	if value:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	StaticData.fullscreen = value

func _on_volume_music_value_changed(value):
	var bus = FMODStudioModule.get_studio_system().get_bus("bus:/Music Bus")
	#if bus:
	bus.set_volume(value / 100.0)
	
	UIHelpers.audio_event("Ui/Ui_Slider")

func _on_volume_sfx_value_changed(value):
	var bus = FMODStudioModule.get_studio_system().get_bus("bus:/SFX Bus")
	#if bus:
	bus.set_volume(value / 100.0)
	
	UIHelpers.audio_event("Ui/Ui_Slider")

func _on_volume_master_value_changed(value):
	var bus = FMODStudioModule.get_studio_system().get_bus("bus:/")
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
	var ui_nodes = [%HintsEnabled, %Fullscreen, $Panel, $Back, \
	music_slider, sfx_slider, master_slider, background, \
	team_1_color_button, team_2_color_button, options, %ScrollSpeedKeyboard, %ScrollSpeedMouse]
	UIHelpers.override_ui_node_theme_with_color(ui_nodes, color)


#func _on_options_pressed() -> void:
	#options.disabled = true
	#set_content_visible(true)


func _on_back_pressed():
	scroll_speed_change.emit(%ScrollSpeedMouse.value, %ScrollSpeedKeyboard.value)
	
	on_back_pressed.emit()
	#set_content_visible(false)
	#options.disabled = false


#func set_content_visible(visible: bool):
	#$Panel.visible = visible
	#$MarginContainer.visible = visible
	#$Back.visible = visible
