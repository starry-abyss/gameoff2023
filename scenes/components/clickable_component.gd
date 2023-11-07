extends Area3D


signal on_click


func _on_input_event(camera, event, pos, normal, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true:
			on_click.emit()
