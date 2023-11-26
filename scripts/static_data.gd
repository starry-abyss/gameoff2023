extends Node

@export var color_pink: Color = Color("#641347")
@export var color_blue: Color = Color("#002a80")
@export var color_neutral: Color = Color("#606060")
@export var tile_good_target: Color = Color("#757575")
@export var tile_bad_target: Color = Color("#252525")

@export var hurt_animation_duration: float = 0.5
@export var spawn_animation_duration: float = 2
@export var turn_animation_duration: float = 1.0
@export var move_animation_duration_per_tile: float = 0.2


@export var unit_stats = { 
	Gameplay.UnitTypes.CENTRAL_NODE: { "name": "Kernel node", "hp_max": 100, "ap_max": 6, "abilities": ["repair","reset","spawn_worms","self_repair"] },
	Gameplay.UnitTypes.TOWER_NODE: { "name": "Anti-virus node", "hp_max": 30, "ap_max": 9, "abilities": ["tower_attack"] },
	
	Gameplay.UnitTypes.WORM: { "name": "Worm", "hp_max": 1, "ap_max": 3, "abilities": ["move","scale","self_modify_to_virus","self_modify_to_trojan"] },
	Gameplay.UnitTypes.TROJAN: { "name": "Trojan", "hp_max": 6, "ap_max": 8, "abilities": ["move","capture_tower","backdoor"] },
	Gameplay.UnitTypes.VIRUS: { "name": "Virus", "hp_max": 15, "ap_max": 5, "abilities": ["move","virus_attack","integrate","spread"] },
	}

# sometimes abilities make AP drop right to zero, this table only shows the minimum AP cost
@export var ability_stats = {
	"move": { "name": "move", "target": Gameplay.TargetTypes.TILE, "ap": 1, "cooldown": 0 },
	
	"virus_attack": { "name": "damage_short", "target": Gameplay.TargetTypes.UNIT, "ap": 3, "cooldown": 0, "attack": 3, "attack_extra": 2, "attack_range": 1 },
	"tower_attack": { "name": "damage_long", "target": Gameplay.TargetTypes.UNIT, "ap": 3, "cooldown": 0, "attack": 10, "attack_extra": 3, "attack_range": 2 },
	
	"scale": { "name": "double", "target": Gameplay.TargetTypes.TILE, "ap": 1, "cooldown": 2 },
	"self_modify_to_virus": { "name": "mutate_to_virus", "target": Gameplay.TargetTypes.SELF, "ap": 2, "cooldown": 0 },
	"self_modify_to_trojan": { "name": "mutate_to_trojan", "target": Gameplay.TargetTypes.SELF, "ap": 3, "cooldown": 0 },
	
	"integrate": { "name": "integrate", "target": Gameplay.TargetTypes.UNIT, "ap": -3, "cooldown": 1 },
	"spread": { "name": "spread", "target": Gameplay.TargetTypes.UNIT, "ap": 6, "cooldown": 0, "attack": 1, "attack_extra": 2 },
	
	"repair": { "name": "patch", "target": Gameplay.TargetTypes.UNIT, "ap": 3, "cooldown": 0, "restored_hp": 6 },
	"reset": { "name": "reset", "target": Gameplay.TargetTypes.TILE, "ap": 6, "cooldown": 5 },
	"spawn_worms": { "name": "generate_worms", "target": Gameplay.TargetTypes.SELF, "ap": 0, "cooldown": 5 },
	"self_repair": { "name": "maintain", "target": Gameplay.TargetTypes.SELF, "ap": 0, "cooldown": 0, "restored_hp": 6 },
	
	"capture_tower": { "name": "capture_node", "target": Gameplay.TargetTypes.UNIT, "ap": 4, "cooldown": 0 },
	"backdoor": { "name": "open_port", "target": Gameplay.TargetTypes.TILE, "ap": 2, "cooldown": 3 },
	}
	
@export var tile_size = Vector2(1.30, 1.30 * sin(PI / 3.0))
@export var map_origin = Vector2(1.0, 1.0)

