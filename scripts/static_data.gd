extends Node

@export var color_pink: Color = Color.PINK
@export var color_blue: Color = Color.BLUE
@export var color_neutral: Color = Color.GRAY

enum UnitTypes { CENTRAL_NODE, TOWER_NODE, WORM, TROJAN, VIRUS }
enum HackingGroups { PINK, BLUE, NEUTRAL }

@export var unit_stats = { 
	UnitTypes.CENTRAL_NODE: { "hp_max": 200, "ap_max": 20 },
	UnitTypes.TOWER_NODE: { "hp_max": 50, "ap_max": 10, "attack": 10, "attack_extra": 5 },
	
	UnitTypes.WORM: { "hp_max": 5, "ap_max": 3 },
	UnitTypes.TROJAN: { "hp_max": 12, "ap_max": 10 },
	UnitTypes.VIRUS: { "hp_max": 30, "ap_max": 10, "attack": 3, "attack_extra": 2 },
	}
