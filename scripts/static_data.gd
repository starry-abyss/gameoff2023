extends Node

@export var color_pink: Color = Color("#641347")
@export var color_blue: Color = Color("#002a80")
@export var color_neutral: Color = Color("#252525")
@export var tile_good_target: Color = Color("#757575")
@export var tile_bad_target: Color = Color("#202020")

@export var hurt_animation_duration: float = 0.5
@export var spawn_animation_duration: float = 2
@export var turn_animation_duration: float = 1.0
@export var move_animation_duration_per_tile: float = 0.2

@export var who_controls_blue: Gameplay.ControllerType = Gameplay.ControllerType.PLAYER
@export var who_controls_pink: Gameplay.ControllerType = Gameplay.ControllerType.PLAYER

@export var unit_stats = { 
	Gameplay.UnitTypes.CENTRAL_NODE: { "name": "Kernel node", "hp_max": 60, "ap_max": 6, "abilities": ["repair","reset","spawn_worms","self_repair"] },
	Gameplay.UnitTypes.TOWER_NODE: { "name": "Anti-malware node", "hp_max": 25, "ap_max": 9, "abilities": ["tower_attack"] },
	
	Gameplay.UnitTypes.WORM: { "name": "Worm", "hp_max": 1, "ap_max": 3, "abilities": ["move","scale","self_modify_to_virus","self_modify_to_trojan"] },
	Gameplay.UnitTypes.TROJAN: { "name": "Trojan", "hp_max": 6, "ap_max": 8, "abilities": ["move","capture_tower","backdoor"] },
	Gameplay.UnitTypes.VIRUS: { "name": "Virus", "hp_max": 15, "ap_max": 5, "abilities": ["move","virus_attack","integrate","spread"] },
	}

# sometimes abilities make AP drop right to zero, this table only shows the minimum AP cost
@export var ability_stats = {
	"move": { "name": "move", "target": Gameplay.TargetTypes.TILE, "ap": 1, "cooldown": 0 },
	
	"virus_attack": { "name": "attack_short", "target": Gameplay.TargetTypes.UNIT, "ap": 3, "cooldown": 0, "attack": 4, "attack_extra": 2, "attack_range": 1 },
	"tower_attack": { "name": "attack_long", "target": Gameplay.TargetTypes.UNIT, "ap": 3, "cooldown": 0, "attack": 6, "attack_extra": 2, "attack_range": 2 },
	
	"scale": { "name": "double", "target": Gameplay.TargetTypes.TILE, "ap": 1, "cooldown": 1 },
	"self_modify_to_virus": { "name": "mutate_to_virus", "target": Gameplay.TargetTypes.SELF, "ap": 2, "cooldown": 0 },
	"self_modify_to_trojan": { "name": "mutate_to_trojan", "target": Gameplay.TargetTypes.SELF, "ap": 3, "cooldown": 0 },
	
	"integrate": { "name": "integrate", "target": Gameplay.TargetTypes.UNIT, "ap": -3, "cooldown": 1 },
	"spread": { "name": "attack_n_spread", "target": Gameplay.TargetTypes.UNIT, "ap": 6, "cooldown": 0, "attack": 3, "attack_extra": 2 },
	
	"repair": { "name": "patch", "target": Gameplay.TargetTypes.UNIT, "ap": 3, "cooldown": 0, "restored_hp": 4 },
	"reset": { "name": "reset_area", "target": Gameplay.TargetTypes.TILE, "ap": 6, "cooldown": 5 },
	"spawn_worms": { "name": "generate_worms", "target": Gameplay.TargetTypes.SELF, "ap": 0, "cooldown": 5 },
	"self_repair": { "name": "self_maintain", "target": Gameplay.TargetTypes.SELF, "ap": 0, "cooldown": 0, "restored_hp": 6 },
	
	"capture_tower": { "name": "capture_node", "target": Gameplay.TargetTypes.UNIT, "ap": 4, "cooldown": 0 },
	"backdoor": { "name": "open_port", "target": Gameplay.TargetTypes.TILE, "ap": 2, "cooldown": 3 },
	}
	
@export var tile_size = Vector2(1.30, 1.30 * sin(PI / 3.0))
@export var map_origin = Vector2(1.0, 1.0)

@export var tooltips = {
	"default": { "text": """
		The goal in this battle is to put down the enemy Kernel node.
		Start with doubling Worms and mutating them.
		
		Use left mouse button to select units (nodes and malware) on your base.
		After a unit is selected, it can perform one or more types of actions.
		For more tips hover the mouse cursor over interactive objects and buttons.
		
		To find units with spare Action Points, click Next idle unit.
		To end your turn, click the End turn button.
		""", 
		"author_pink": "@space_rat", "author_blue": "Mike Denton" },
	
	"firewall": { "text": """
		Firewalls block all enemy units from moving and damaging through them.
		
		They are automatically created on a straight line between two Anti-malware nodes.
		For this Anti-malware nodes have to belong to the same group.
		
		The only way to put down a firewall is to damage one of the two Anti-malware nodes to 0 Hit Points.
		""" },
	"tower_node": { "text": """
		Anti-malware nodes can damage enemy units at the range of 2 tiles.
		If two Anti-malware nodes belong to the same group and stand on a straight line,
		a firewall with be created between them.
		
		If Hit Points reach 0, all neighbor firewalls are down too.
		
		The cost of every action in unit's Action Points is shown at the bottom of the button.
		This node has only one action type and button.
		""" },
	"central_node": { "text": """
		The Kernel node contains rootkits allowing us to control the computer of 
		a random internet guy.
		
		The group which loses the Kernel node - all damaged down to 0 Hit Points - loses the battle.
		
		The Kernel node has actions just like other units, some of them performed automatically when
		available.
		To perform non-automatic actions first click on the action button and then - on the target tile on the map.
		
		The cost of every action in unit's Action Points is shown at the bottom of the button.
		""" },
	
	"worm": { "text": """
		The Worm malware can reproduce by doubling, can move and can be mutated to other types of units.
		To perform those actions first click on the action button and then - on the target tile on the map.
		Mutation actions are performed on the Worm itself, so there is no step of choosing the target.
		
		The cost of every action in unit's Action Points is shown at the bottom of the button.
		
		From time to time Kernel node generates new Worms.
		""" },
	"virus": { "text": """
		The Virus malware can move and can attack enemy units in the range of 1.
		
		Also it can integrate friendly Worms to temporarily gain more Action Points, even beyond the limit!
		Integrating a Worm is the only way to then perform the 'spread' type of attack.
		""" },
	"trojan": { "text": """
		The Trojan malware can move fast but cannot attack.
		
		It can capture an enemy Anti-malware node.
		It can open a backdoor port to move friendly malware to the Trojan over long distances.
		""" },
	
	"end_turn": { "text": """
		Click this button to end your turn and start the enemy's turn.
		
		All friendly units will restore Action Points.
		The ready status of their actions will be increased by 1.
		""" },
	"next_idle_unit": { "text": """
		Click this button to select next friendly unit with spare Action Points.
		""" },
	"options": { "text": """
		Click this button to change settings, or to end or restart the battle.
	""" },
	
	"move": { "text": """
		Unlike nodes, malware can move.
		Maximum distance depends on the amount of Action Points left for the malware.
		It's impossible to walk through other units or through enemy firewalls.
		
		For this action it's not required to click the action button first.
		
		To move malware instantly at long distances use Trojan's 'open_port' action instead.
		""" },
	
	"virus_attack": { "text": """
		Deals the damage to an enemy unit on a neighbor tile.
		This action won't work through enemy firewalls, so attack Anti-malware nodes first.
		
		For this action it's not required to click the action button first.
		
		The other type of Virus attack is 'spread'.
		
		Possible damage amount is shown on the button.
		""" },
	"tower_attack": { "text": """
		Deals the damage to an enemy unit within the distance of 2 tiles.
		Note that there are enough Action Points for every Anti-malware to perform this action 3 times each turn.
		
		For this action it's not required to click the action button first.
		
		Possible damage amount is shown on the button.
		""" },
	
	"scale": { "text": """
		The 'double' action generates a new Worm on the chosen neighbor tile.
		
		After doubling both Worms are stuck until the next turn, so you might want to move the original one first.
		
		The period of unavailability after use, in turns, is shown on the button.
		""" },
	"self_modify_to_virus": { "text": """
		Changes malware type from Worm to Virus, no target selection needed.
		
		After the mutation the Worm is stuck until the next turn.
		""" },
	"self_modify_to_trojan": { "text": """
		Changes malware type from Worm to Trojan, no target selection needed.
		
		After the mutation the Worm is stuck until the next turn.
		""" },
	
	"integrate": { "text": """
		Consumes a chosen Worm from a neighbor tile. Action Points are increased by 3 then until the next turn.
		
		Only one Worm per turn can be integrated by each Virus.
		
		This is the only way to perform the 'spread' action (on the same turn).
		""" },
	"spread": { "text": """
		Deals the damage to an enemy on a neighbor tile.
		The damage is also spread instantly along the chain for enemy units on next neighbor tiles.
		
		The total maximum distance is unlimited.
		This action won't work through enemy firewalls, free tiles and friendly units.
		
		Possible damage amount is shown on the button.
		""" },
	
	"repair": { "text": """
		Restores a few Hit Points of the chosen friendly unit, except itself.
		The target unit must be located on the territory marked with the Kernel group's color.
		
		The Kernel's own Hit Points are partially restored at the beginning of every turn with 'maintain'.
		
		The amount of Hit Points restored is shown on the button.
		""" },
	"reset": { "text": """
		Performs a reset on 7 selected tiles eliminating all malware there regardless of their group.
		Nodes are unaffected. The central tile of the 7 must be located on the territory marked with the Kernel group's color.
		
		The period of unavailability after use, in turns, is shown on the button.
	""" },
	"spawn_worms": { "text": """
		Automatically generates up to 6 Worms on neighbor tiles.
		If any of neighbor tiles is occupied, no Worm is generated on that tile.
		
		The period of unavailability after use, in turns, is shown on the button.
	""" },
	"self_repair": { "text": """
		Automatically restores a few Kernel's own Hit Points at the beginning of every turn.
		
		The amount of Hit Points restored is shown on the button.
		""" },
	
	"capture_tower": { "text": """
		To capture an enemy Anti-malware node, firstly damage it down to 0 HP.
		Secondly, move the Trojan near the node (then of the neutral group) and use this action on it.
	""" },
	"backdoor": { "text": """
		Allows to teleport up to 6 friendly malware to the Trojan. The Trojan cannot teleport itself.
		
		Teleported units will preserve their relative position to the center of target tile, 
		but with the Trojan's tile instead of that tile.
		
		But if any of the Trojan neighbor tiles is occupied, no malware is teleported in that particular tile.
		Unlike other actions it's possible to teleport through any firewalls.
		
		All teleported units' Action Points are reduced to one (at maximum) until the next turn.
		
		The period of unavailability after use, in turns, is shown on the button.
		""" },
	
	}
