extends Node3D

@onready var selected_unit_stats = $CanvasLayer/SelectedUnitStats
@onready var selected_unit_indicator = $SelectedUnitIndicator

signal tile_clicked
signal tile_hovered

signal animation_finished

func _on_show_path(unit: Unit, path: Array):
	#print("show ", path)
	pass

# doesn't work and not needed at the moment
func _on_show_path_not_enough_ap(unit: Unit, path: Array):
	pass

func _on_hide_path():
	pass
	
func _on_unit_move(unit: Unit, path: Array):
	#print("move ", path)
	
	# TODO: not needed when the function is implemented
	# immediately moves the unit model to the final tile
	# (to unit.tile_pos, gameplay-wise the actual unit is already there)
	unit.update_model_pos()
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

func _on_unit_destroy(unit: Unit):
	pass
	
func _on_playing_group_changed(current_group: Gameplay.HackingGroups, is_ai_turn: bool):
	#var group_color = UIHelpers.group_to_color(current_group)
	
	if current_group == Gameplay.HackingGroups.PINK:
		$CanvasLayer/end_turn.theme = preload("res://themes/pink.tres")
		$CanvasLayer/select_idle_unit.theme = preload("res://themes/pink.tres")
	else:
		$CanvasLayer/end_turn.theme = preload("res://themes/blue.tres")
		$CanvasLayer/select_idle_unit.theme = preload("res://themes/blue.tres")
	pass

func _on_battle_end(who_won: Gameplay.HackingGroups):
	pass

func _input(event):
	if event is InputEventMouseButton && event.pressed:
		#print("Mouse Click/Unclick at: ", event.position)

		var world_pos = UIHelpers.screen_pos_to_world_pos(event.position)
		#print("world pos: ", world_pos)
		
		var tile_pos = UIHelpers.world_pos_to_tile_pos(world_pos)
		print("tile_pos: ", tile_pos)
		
		tile_clicked.emit(tile_pos)
		
	elif event is InputEventMouseMotion:
		#print("Mouse Motion at: ", event.position)
		
		var world_pos = UIHelpers.screen_pos_to_world_pos(event.position)
		#print("world pos: ", world_pos)
		
		var tile_pos = UIHelpers.world_pos_to_tile_pos(world_pos)
		tile_hovered.emit(tile_pos)
		
