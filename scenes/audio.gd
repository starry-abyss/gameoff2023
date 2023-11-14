extends Node

@export var event: EventAsset

# Called when the node enters the scene tree for the first time.
func _ready():
	#FMODRuntime.play_one_shot(event)
	
	#FMODRuntime.play_one_shot_path("event:/Music/MusicPlaylist")
	
	#print(FMODRuntime.get_event_description_path("event:/Music/MusicPlaylist"))
	UIHelpers.audio_event("Music/MusicPlaylist")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
