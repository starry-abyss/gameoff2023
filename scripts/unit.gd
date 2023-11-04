extends Node3D

enum Types { CENTRAL_NODE, TOWER_NODE, WORM, TROJAN, VIRUS }
enum HackingGroups { PINK, BLUE, NEUTRAL }

@export var type: Types = Types.TOWER_NODE
@export var group: HackingGroups = HackingGroups.NEUTRAL

@export var hp: int = 8
@export var hp_max: int = 8
@export var attack: int = 0
@export var attack_extra: int = 0
@export var ap: int = 3
@export var ap_max: int = 3

func is_static() -> bool:
	return type == Types.CENTRAL_NODE || type == Types.TOWER_NODE

func can_attack() -> bool:
	return attack > 0 || attack_extra > 0

func can_move() -> bool:
	return !is_static() && ap > 0
