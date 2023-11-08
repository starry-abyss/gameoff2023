extends Control


signal go_to_main_menu


func _on_back_pressed():
	go_to_main_menu.emit()


func _on_volume_value_changed(value):
	var bus = FMODStudioModule.get_studio_system().get_bus("bus:/Music Bus")
	#if bus:
	bus.set_volume(value / 100.0)
