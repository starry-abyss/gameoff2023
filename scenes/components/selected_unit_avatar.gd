extends Panel


@onready var camera_container: Node3D = $SubViewportContainer/SubViewport/CameraContainer


var unit: Unit


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if unit != null:
		camera_container.position = unit.position


func show_avatar(new_unit):
	unit = new_unit
	
	
func hide_avatar():
	unit = null
