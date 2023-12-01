extends Node3D


#FIXME: queue free timer after timeout
func call_after_time(callable: Callable, time: float):
	
	if callable.get_object() == null:
		return
		
		
	
	var _timer = Timer.new()
	_timer.wait_time = time
	_timer.one_shot = true
	_timer.timeout.connect(func callback(): callable.call())
	add_child(_timer)
	_timer.start()
