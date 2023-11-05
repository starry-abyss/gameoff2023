extends Control


signal go_to_main_menu


func _on_back_pressed():
	go_to_main_menu.emit()
