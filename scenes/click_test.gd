extends Node3D


@onready var unit = preload("res://scenes/unit.tscn")
@onready var unit_container = $UnitContainer
@onready var selected_unit_stats = $CanvasLayer/SelectedUnitStats
@onready var selected_unit_indicator = $SelectedUnitIndicator


var selected_unit: Unit = null


# Called when the node enters the scene tree for the first time.
func _ready():
	_generate_units(3)
	

func _generate_units(count: int):
	for i in range(count):
		var new_unit = unit.instantiate() as Unit
		new_unit.hp_max = randi_range(10, 20)
		new_unit.attack = randi_range(5, 10)
		unit_container.add_child(new_unit)
		new_unit.position = Vector3(i, 0, 0)
		new_unit.on_click.connect(_on_unit_click)
	
	
func _on_unit_click(unit: Unit):
	if selected_unit == unit:
		selected_unit = null
		selected_unit_indicator.visible = false
		selected_unit_stats.visible = false
	else:
		selected_unit = unit
		selected_unit_stats.visible = true
		selected_unit_indicator.position = selected_unit.position + Vector3(0, 1.5, 0) 
		selected_unit_indicator.visible = true
		selected_unit_stats._display_unit_stats(selected_unit)
	
