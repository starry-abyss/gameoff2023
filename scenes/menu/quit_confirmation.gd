extends Control


func _on_yes_pressed() -> void:
	UIHelpers.quit_the_game()


func _on_no_pressed() -> void:
	visible = false


func change_theme_color(color):
	var ui_nodes = [$Panel, $Panel/VBoxContainer/HBoxContainer/Yes, $Panel/VBoxContainer/HBoxContainer/No]
	UIHelpers.override_ui_node_theme_with_color(ui_nodes, color)
