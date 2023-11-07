extends Node3D

@onready var selected_unit_stats = $CanvasLayer/SelectedUnitStats
@onready var selected_unit_indicator = $SelectedUnitIndicator

signal tile_clicked

func _on_show_path(path: Array):
	pass

func _on_unit_selection_changed(unit: Unit):
	if unit == null:
		selected_unit_indicator.visible = false
		selected_unit_stats.visible = false
	else:
		selected_unit_stats.visible = true
		selected_unit_indicator.position = unit.position + Vector3(0, 1.5, 0) 
		selected_unit_indicator.visible = true
		selected_unit_stats._display_unit_stats(unit)

func _input(event):
	if event is InputEventMouseButton && event.pressed:
		#print("Mouse Click/Unclick at: ", event.position)
		#pass
	#elif event is InputEventMouseMotion:
		#print("Mouse Motion at: ", event.position)
		
		var world_pos = UIHelpers.screen_pos_to_world_pos(event.position)
		#print("world pos: ", world_pos)
		
		var tile_pos = UIHelpers.world_pos_to_tile_pos(world_pos)
		tile_clicked.emit(tile_pos)
		#print("tile pos: ", tile_pos)
