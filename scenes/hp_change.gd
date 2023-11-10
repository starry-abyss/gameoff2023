extends Node3D

func _process(delta):
	$Label.global_position.y += 0.3 * delta
