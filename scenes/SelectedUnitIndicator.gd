extends Node3D

func _process(delta):
	var time = Time.get_ticks_msec()
	
	$cursor.rotation = Vector3(0.0, -time / 400.0, 0.0)
	$cursor.position = Vector3(0.0, (sin(time / 200.0) + 1.1) * 0.3, 0.0)
