extends Node

@export var color_pink: Color = Color.DEEP_PINK
@export var color_blue: Color = Color.DARK_BLUE
@export var color_neutral: Color = Color.DARK_GRAY

@export var turn_animation_duration: float = 2.0

@export var unit_stats = { 
	Gameplay.UnitTypes.CENTRAL_NODE: { "name": "Kernel", "hp_max": 200, "ap_max": 20, "abilities": ["repair","reset"] },
	Gameplay.UnitTypes.TOWER_NODE: { "name": "Anti-virus", "hp_max": 50, "ap_max": 10, "attack": 10, "attack_extra": 5, "attack_range": 2 },
	
	Gameplay.UnitTypes.WORM: { "name": "Worm", "hp_max": 5, "ap_max": 3, "abilities": ["scale","self_modify_to_virus","self_modify_to_trojan"] },
	Gameplay.UnitTypes.TROJAN: { "name": "Trojan", "hp_max": 12, "ap_max": 10, "abilities": ["capture_tower","backdoor"] },
	Gameplay.UnitTypes.VIRUS: { "name": "Virus", "hp_max": 30, "ap_max": 10, "attack": 3, "attack_extra": 2 },
	}

# sometimes abilities make AP drop right to zero, this table only shows the minimum AP cost
@export var ability_stats = {
	"scale": { "name": "Double", "target": Gameplay.TargetTypes.TILE, "ap": 1, "cooldown": 0 },
	"self_modify_to_virus": { "name": "Self-modify to Virus", "target": Gameplay.TargetTypes.SELF, "ap": 1, "cooldown": 0 },
	"self_modify_to_trojan": { "name": "Self-modify to Trojan", "target": Gameplay.TargetTypes.SELF, "ap": 1, "cooldown": 0 },
	
	"repair": { "name": "Repair", "target": Gameplay.TargetTypes.UNIT, "ap": 1, "cooldown": 3 },
	"reset": { "name": "Reset", "target": Gameplay.TargetTypes.TILE, "ap": 1, "cooldown": 3 },
	
	"capture_tower": { "name": "Capture a node", "target": Gameplay.TargetTypes.UNIT, "ap": 1, "cooldown": 0 },
	"backdoor": { "name": "Open a backdoor", "target": Gameplay.TargetTypes.TILE, "ap": 1, "cooldown": 0 },
	}
	
@export var tile_size = Vector2(1.2, 1.2)
@export var map_origin = Vector2(1.0, 1.0)

