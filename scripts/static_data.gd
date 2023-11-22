extends Node

@export var color_pink: Color = Color("#a61162")
@export var color_blue: Color = Color("#0045ff")
@export var color_neutral: Color = Color("#606060")

@export var hurt_animation_duration: float = 0.2
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
	"move": { "name": "Move", "target": Gameplay.TargetTypes.TILE, "ap": 1, "cooldown": 0 },
	
	"virus_attack": { "name": "Damage", "target": Gameplay.TargetTypes.UNIT, "ap": 3, "cooldown": 0, "attack": 3, "attack_extra": 2, "attack_range": 1 },
	"tower_attack": { "name": "Damage (at range)", "target": Gameplay.TargetTypes.UNIT, "ap": 3, "cooldown": 0, "attack": 10, "attack_extra": 3, "attack_range": 2 },
	
	"scale": { "name": "Double", "target": Gameplay.TargetTypes.TILE, "ap": 1, "cooldown": 2 },
	"self_modify_to_virus": { "name": "Mutate to Virus", "target": Gameplay.TargetTypes.SELF, "ap": 2, "cooldown": 0 },
	"self_modify_to_trojan": { "name": "Mutate to Trojan", "target": Gameplay.TargetTypes.SELF, "ap": 3, "cooldown": 0 },
	
	"integrate": { "name": "Integrate", "target": Gameplay.TargetTypes.UNIT, "ap": -3, "cooldown": 1 },
	"spread": { "name": "Spread", "target": Gameplay.TargetTypes.UNIT, "ap": 6, "cooldown": 0, "attack": 1, "attack_extra": 2 },
	
	"repair": { "name": "Patch", "target": Gameplay.TargetTypes.UNIT, "ap": 3, "cooldown": 0, "restored_hp": 6 },
	"reset": { "name": "Reset", "target": Gameplay.TargetTypes.TILE, "ap": 6, "cooldown": 5 },
	"spawn_worms": { "name": "Generate Worms", "target": Gameplay.TargetTypes.SELF, "ap": 0, "cooldown": 5 },
	"self_repair": { "name": "Maintenance", "target": Gameplay.TargetTypes.SELF, "ap": 0, "cooldown": 0, "restored_hp": 6 },
	
	"capture_tower": { "name": "Capture a node", "target": Gameplay.TargetTypes.UNIT, "ap": 4, "cooldown": 0 },
	"backdoor": { "name": "Use the backdoor", "target": Gameplay.TargetTypes.TILE, "ap": 2, "cooldown": 3 },
	}
	
@export var tile_size = Vector2(1.15, 1.15 * sin(PI / 3.0))
@export var map_origin = Vector2(1.0, 1.0)

