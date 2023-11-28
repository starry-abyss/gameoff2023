extends Control



@onready var title_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/MarginContainer/Title
@onready var tooltip_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/Tooltip
@onready var additional_info_label: Label = $"VBoxContainer/MarginContainer/VBoxContainer/Additional Info"


func _ready() -> void:
	hide_tooltip()


func show_tooltip(title: String, tooltip: String):
	title_label.text = title
	tooltip_label.text = tooltip
	visible = true
	

func hide_tooltip():
	visible = false
