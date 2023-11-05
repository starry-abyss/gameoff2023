extends CanvasLayer


@onready var viewport_container = $Node3D/SubViewportContainer
@onready var viewport = $Node3D/SubViewportContainer/SubViewport


func _process(delta):
	viewport.size = viewport_container.size
