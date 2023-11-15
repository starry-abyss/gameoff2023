extends CanvasLayer


@onready var viewport_container = $Node3D/SubViewportContainer
@onready var viewport = $Node3D/SubViewportContainer/SubViewport
@onready var main_menu = $MainMenu
@onready var options_menu = $OptionsMenu


func _ready():
	main_menu.go_to_options_menu.connect(_go_to_options_menu)
	options_menu.go_to_main_menu.connect(_go_to_main_menu)
	
	get_tree().set_auto_accept_quit(false)
	
	for button in find_children("", "Button"):
		button.mouse_entered.connect(_on_button_highlight)

func _on_button_highlight():
	UIHelpers.audio_event("Ui/Ui_Highlight")

func _process(delta):
	viewport.size = viewport_container.size


func _go_to_main_menu():
	options_menu.visible = false
	main_menu.visible = true
	
	UIHelpers.audio_event("Ui/Ui_Back")
	

func _go_to_options_menu():
	main_menu.visible = false
	options_menu.visible = true
	
	UIHelpers.audio_event("Ui/Ui_Accept")
