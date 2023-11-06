extends Node3D

@onready var selected_unit_stats = $CanvasLayer/SelectedUnitStats
@onready var selected_unit_indicator = $SelectedUnitIndicator

func _on_unit_selection_changed(unit: Unit):
	if unit == null:
		selected_unit_indicator.visible = false
		selected_unit_stats.visible = false
	else:
		selected_unit_stats.visible = true
		selected_unit_indicator.position = unit.position + Vector3(0, 1.5, 0) 
		selected_unit_indicator.visible = true
		selected_unit_stats._display_unit_stats(unit)
