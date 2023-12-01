extends Sprite2D


## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW, Vector2(texture.get_width(), texture.get_height()) / 2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position = get_global_mouse_position()
