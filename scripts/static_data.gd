extends Node

@export var color_pink: Color = Color("#ff1493")
@export var color_blue: Color = Color("#0051ff")
@export var color_neutral: Color = Color("#606060")

@export var turn_animation_duration: float = 1.0

@export var unit_stats = { 
	Gameplay.UnitTypes.CENTRAL_NODE: { "name": "Kernel", "hp_max": 200, "ap_max": 6, "abilities": ["repair","reset"] },
	Gameplay.UnitTypes.TOWER_NODE: { "name": "Anti-virus", "hp_max": 30, "ap_max": 9, "attack": 10, "attack_extra": 3, "attack_range": 2, "ap_cost_of_attack": 3 },
	
	Gameplay.UnitTypes.WORM: { "name": "Worm", "hp_max": 1, "ap_max": 3, "abilities": ["scale","self_modify_to_virus","self_modify_to_trojan"] },
	Gameplay.UnitTypes.TROJAN: { "name": "Trojan", "hp_max": 6, "ap_max": 8, "abilities": ["capture_tower","backdoor"] },
	Gameplay.UnitTypes.VIRUS: { "name": "Virus", "hp_max": 12, "ap_max": 5, "attack": 3, "attack_extra": 2, "ap_cost_of_attack": 3 },
	}

# sometimes abilities make AP drop right to zero, this table only shows the minimum AP cost
@export var ability_stats = {
	"scale": { "name": "Double", "target": Gameplay.TargetTypes.TILE, "ap": 1, "cooldown": 2 },
	"self_modify_to_virus": { "name": "Self-modify to Virus", "target": Gameplay.TargetTypes.SELF, "ap": 2, "cooldown": 0 },
	"self_modify_to_trojan": { "name": "Self-modify to Trojan", "target": Gameplay.TargetTypes.SELF, "ap": 3, "cooldown": 0 },
	
	"repair": { "name": "Repair", "target": Gameplay.TargetTypes.UNIT, "ap": 3, "cooldown": 0, "restored_hp": 6 },
	"reset": { "name": "Reset", "target": Gameplay.TargetTypes.TILE, "ap": 6, "cooldown": 5 },
	"spawn_worms": { "name": "Spawn Worms", "target": Gameplay.TargetTypes.SELF, "ap": 0, "cooldown": 5 },
	"self_repair": { "name": "Maintenance", "target": Gameplay.TargetTypes.SELF, "ap": 0, "cooldown": 0, "restored_hp": 6 },
	
	"capture_tower": { "name": "Capture a node", "target": Gameplay.TargetTypes.UNIT, "ap": 4, "cooldown": 0 },
	"backdoor": { "name": "Open a backdoor", "target": Gameplay.TargetTypes.TILE, "ap": 2, "cooldown": 3 },
	}
	
@export var tile_size = Vector2(1.2, 1.2)
@export var map_origin = Vector2(1.0, 1.0)

