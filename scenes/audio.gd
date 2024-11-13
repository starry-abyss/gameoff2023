extends Node

@export var event: EventAsset

signal quit_game

# Called when the node enters the scene tree for the first time.
func _ready():
	#FMODRuntime.play_one_shot(event)
	
	# TODO: for debug, to be removed:
	#UIHelpers.audio_set_parameter("Winner", Gameplay.HackingGroups.BLUE)
	
	UIHelpers.audio_event("Music/MusicPlaylist")
	
	get_node("/root/FMODRuntime").process_mode = Node.PROCESS_MODE_ALWAYS
	pass # Replace with function body.

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game.emit()
		#UIHelpers.quit_the_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
