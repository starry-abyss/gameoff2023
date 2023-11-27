extends Button

signal on_highlight(name: String)
signal on_unhighlight

var is_back_button = false
var no_press_sound = false

# Called when the node enters the scene tree for the first time.
func _ready():
	mouse_entered.connect(_on_highlight)
	mouse_exited.connect(_on_unhighlight)
	pressed.connect(_on_press)
	
	focus_mode = Control.FOCUS_NONE
	pass # Replace with function body.

func _on_highlight():
	if !disabled:
		on_highlight.emit(name)
		UIHelpers.audio_event("Ui/Ui_Highlight")
		
func _on_unhighlight():
	if !disabled:
		on_unhighlight.emit()

func _on_press():
	if !no_press_sound:
		if is_back_button:
			UIHelpers.audio_event("Ui/Ui_Back")
		else:
			UIHelpers.audio_event("Ui/Ui_Accept")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
