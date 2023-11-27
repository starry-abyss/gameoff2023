extends Panel


@onready var title: Label = %Title
@onready var description: Label = $MarginContainer/VBoxContainer/Description


func show_button_description(button_name: String):
	var button_info = StaticData.tooltips[button_name]
	title.text = button_name
	description.text = button_info.text
	visible = true
	print(button_info)
	

func hide_button_description():
	visible = false
