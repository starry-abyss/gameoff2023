class_name StyledCheckbox
extends Control


signal toggled(toggled_on: bool)

@export var checked := false

@onready var panel: Panel = $Panel
@onready var checkbox: CheckBox = $Checkbox


func _ready() -> void:
	checkbox.button_pressed = checked


func _on_checkbox_toggled(toggled_on: bool) -> void:
	toggled.emit(toggled_on)


func override_color(color: Color):
	panel.self_modulate = color
	checkbox.self_modulate = color
	
