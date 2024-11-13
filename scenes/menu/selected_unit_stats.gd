extends Control


@onready var title_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/MarginContainer/Title
@onready var tooltip_label = $VBoxContainer/MarginContainer/VBoxContainer/Tooltip
@onready var author_info_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/AuthorInfo


func _ready() -> void:
	hide_tooltip()


func show_tooltip(title: String, tooltip: String, author_info: String):
	title_label.text = title
	tooltip_label.text = tooltip
	author_info_label.text = "%s wrote: " % [author_info]
	author_info_label.visible = author_info != ""
	visible = true
	

func hide_tooltip():
	visible = false
