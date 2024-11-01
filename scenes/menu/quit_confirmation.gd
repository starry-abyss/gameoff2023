class_name YesNoDialog extends Control

enum YesAction { Quit, Restart, Menu }

var yes_action := YesAction.Quit

func show_dialog(yes_action: YesAction):
	self.yes_action = yes_action
	visible = true
	
	if yes_action == YesAction.Quit:
		%Label.text = "Really quit?"
	elif yes_action == YesAction.Restart:
		%Label.text = "Really restart the battle?"
	else:
		%Label.text = "Really end the battle?"

func _on_yes_pressed() -> void:
	get_tree().set_pause(false)
	
	if yes_action == YesAction.Quit:
		UIHelpers.quit_the_game()
	elif yes_action == YesAction.Restart:
		get_tree().change_scene_to_file("res://maps/test1.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menu/main_menu_3d.tscn")

func _on_no_pressed() -> void:
	visible = false


func change_theme_color(color):
	var ui_nodes = [$Panel, $Panel/VBoxContainer/HBoxContainer/Yes, $Panel/VBoxContainer/HBoxContainer/No]
	UIHelpers.override_ui_node_theme_with_color(ui_nodes, color)

func _process(delta: float) -> void:
	$CanvasLayer.visible = visible
	$CanvasLayer2.visible = visible
