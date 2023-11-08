extends Node

@export var color_pink: Color = Color.DEEP_PINK
@export var color_blue: Color = Color.BLUE
@export var color_neutral: Color = Color.GRAY

@export var turn_animation_duration: float = 2.0

@export var unit_stats = { 
	Gameplay.UnitTypes.CENTRAL_NODE: { "hp_max": 200, "ap_max": 20 },
	Gameplay.UnitTypes.TOWER_NODE: { "hp_max": 50, "ap_max": 10, "attack": 10, "attack_extra": 5 },
	
	Gameplay.UnitTypes.WORM: { "hp_max": 5, "ap_max": 3 },
	Gameplay.UnitTypes.TROJAN: { "hp_max": 12, "ap_max": 10 },
	Gameplay.UnitTypes.VIRUS: { "hp_max": 30, "ap_max": 10, "attack": 3, "attack_extra": 2 },
	}
	
@export var tile_size = Vector2(1.2, 1.2)
@export var map_origin = Vector2(1.0, 1.0)

