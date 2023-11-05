extends CanvasLayer


@onready var viewport_container = $Node3D/SubViewportContainer
@onready var viewport = $Node3D/SubViewportContainer/SubViewport
@onready var main_menu = $MainMenu
@onready var options_menu = $OptionsMenu


func _ready():
	main_menu.go_to_options_menu.connect(_go_to_options_menu)
	options_menu.go_to_main_menu.connect(_go_to_main_menu)


func _process(delta):
	viewport.size = viewport_container.size


func _go_to_main_menu():
	options_menu.visible = false
	main_menu.visible = true
	

func _go_to_options_menu():
	main_menu.visible = false
	options_menu.visible = true
