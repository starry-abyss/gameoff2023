extends Node

@export var color_pink: Color = Color("#641347")
@export var color_blue: Color = Color("#002a80")
@export var color_neutral: Color = Color("#252525")
@export var tile_good_target: Color = Color("#757575")
@export var tile_bad_target: Color = Color("#202020")

@export var main_menu_color: Color = Color("#00ff00")

var turn_animation_duration: float = 1.0

var hurt_animation_duration: float:
	get:
		return 0.5 * turn_animation_duration
var heal_animation_duration: float:
	get:
		return 0.5 * turn_animation_duration
var spawn_animation_duration: float:
	get:
		return 1 * turn_animation_duration
var attack_animation_duration: float:
	get:
		return 0.4 * turn_animation_duration
var mutation_animation_duration: float:
	get:
		return 0.4 * turn_animation_duration
var move_animation_duration_per_tile: float:
	get:
		return 0.2 * turn_animation_duration

@export var who_controls_blue: Gameplay.ControllerType = Gameplay.ControllerType.PLAYER
@export var who_controls_pink: Gameplay.ControllerType = Gameplay.ControllerType.PLAYER

@export var fullscreen = false
@export var show_tutorial_hints = true

@export var unit_stats = { 
	Gameplay.UnitTypes.CENTRAL_NODE: { "name": "Kernel node", "hp_max": 60, "ap_max": 6, "abilities": ["repair","reset","spawn_worms","self_repair"] },
	Gameplay.UnitTypes.TOWER_NODE: { "name": "Anti-malware node", "hp_max": 25, "ap_max": 9, "abilities": ["tower_attack"] },
	
	Gameplay.UnitTypes.WORM: { "name": "Worm malware", "hp_max": 1, "ap_max": 3, "abilities": ["move","scale","self_modify_to_virus","self_modify_to_trojan"] },
	Gameplay.UnitTypes.TROJAN: { "name": "Trojan malware", "hp_max": 6, "ap_max": 8, "abilities": ["move","capture_tower","backdoor"] },
	Gameplay.UnitTypes.VIRUS: { "name": "Virus malware", "hp_max": 15, "ap_max": 5, "abilities": ["move","virus_attack","integrate","spread"] },
	}

# sometimes abilities make AP drop right to zero, this table only shows the minimum AP cost
@export var ability_stats = {
	"move": { "icon": "move", "key": "M", "name": "move", "target": Gameplay.TargetTypes.TILE, "ap": 1, "cooldown": 0 },
	
	"virus_attack": { "icon": "virus attack", "key": "A", "name": "attack_short", "target": Gameplay.TargetTypes.UNIT, "ap": 3, "cooldown": 0, "attack": 4, "attack_extra": 2, "attack_range": 1 },
	"tower_attack": { "icon": "tower attack", "key": "A", "name": "attack_long", "target": Gameplay.TargetTypes.UNIT, "ap": 3, "cooldown": 0, "attack": 6, "attack_extra": 2, "attack_range": 2 },
	
	"scale": { "icon": "duplicate 2", "key": "D", "name": "duplicate", "target": Gameplay.TargetTypes.TILE, "ap": 1, "cooldown": 1 },
	"self_modify_to_virus": { "icon": "virus grid", "key": "V", "name": "mutate_to_virus", "target": Gameplay.TargetTypes.SELF, "ap": 2, "cooldown": 0 },
	"self_modify_to_trojan": { "icon": "trojan", "key": "T", "name": "mutate_to_trojan", "target": Gameplay.TargetTypes.SELF, "ap": 3, "cooldown": 0 },
	
	"integrate": { "icon": "integrate", "key": "B", "name": "boost", "target": Gameplay.TargetTypes.UNIT, "ap": -3, "cooldown": 1 },
	"spread": { "icon": "spread", "key": "S", "name": "attack_n_spread", "target": Gameplay.TargetTypes.UNIT, "ap": 6, "cooldown": 0, "attack": 3, "attack_extra": 2 },
	
	"repair": { "icon": "repair", "key": "P", "name": "patch", "target": Gameplay.TargetTypes.UNIT, "ap": 3, "cooldown": 0, "restored_hp": 4 },
	"reset": { "icon": "reset", "key": "R", "name": "reset_area", "target": Gameplay.TargetTypes.TILE, "ap": 6, "cooldown": 5 },
	"spawn_worms": { "icon": "spawn worm", "name": "generate_worms", "target": Gameplay.TargetTypes.SELF, "ap": 0, "cooldown": 5 },
	"self_repair": { "icon": "self heal", "name": "self_maintain", "target": Gameplay.TargetTypes.SELF, "ap": 0, "cooldown": 0, "restored_hp": 6 },
	
	"capture_tower": { "icon": "capture", "key": "C", "name": "capture_node", "target": Gameplay.TargetTypes.UNIT, "ap": 4, "cooldown": 0 },
	"backdoor": { "icon": "backdoor", "key": "B", "name": "open_backdoor", "target": Gameplay.TargetTypes.TILE, "ap": 2, "cooldown": 3 },
	}
	
@export var tile_size = Vector2(1.30, 1.30 * sin(PI / 3.0))
@export var map_origin = Vector2(1.0, 1.0)

@export var tooltips = {
	"InstructionsAndMenuButton": { "text": """
		The goal is to put down the enemy Kernel node. Start with duplicating Worms and mutating them.
		
		Use [color=green]left mouse button[/color] to select units (nodes and malware) on your base (has the same color as panel borders).
		
		After a unit is selected, it can perform actions.
		
		For more hints hover the mouse cursor over interactive objects and buttons (if hints are enabled in options).
		
		To end your turn, click the End turn button.
		
		Click this button to change options, or to end or restart the battle.
		""" }, 
		#"author_pink": "@space_rat", "author_blue": "Mike Denton" },
	
	"firewall": { "text": """
		Firewalls block all enemy units from moving and damaging through them.
		
		They are automatically created on a straight line between two Anti-malware nodes.
		For this Anti-malware nodes have to belong to the same group.
		
		The only way to put down a firewall is to damage one of the two Anti-malware nodes to 0 Hit Points.
		""" },
	"tower_node": { "text": """
		Anti-malware nodes can damage enemy units at the range of 2 tiles. At the start of the battle they can't reach any enemies.
		
		Firewalls block all enemy units from moving and damaging through them.
		
		They are automatically created on a straight line between two Anti-malware nodes. For this Anti-malware nodes have to belong to the same group.
		
		If Hit Points reach 0, all neighbor firewalls are down too.
		""" },
	"central_node": { "text": """
		The Kernel node contains rootkits allowing us to control the computer of a random internet guy.
		
		The group which loses the Kernel node - all damaged down to 0 Hit Points - loses the battle.
		
		The Kernel node has actions just like other units, some of them performed automatically when
		available.
		
		To perform non-automatic actions for the selected node, click on the action button at the bottom and then - on the target tile. When the tile under mouse is highlighted brightly, it means that the target is valid (taking into account spare Action Points).
		
		The cost of every action in unit's Action Points (AP) is shown at the top of the button.
		""" },
	
	"worm": { "text": """
		The Worm malware can duplicate itself, can move and can be mutated to other types of units.
		
		To perform these actions for the selected malware, click on the action button at the bottom and then - on the target tile. When the tile under mouse is highlighted brightly, it means that the target is valid (taking into account spare Action Points).
		
		Mutation actions are performed on the Worm in place, so there is no step of choosing the target.
		
		The cost of every action in unit's Action Points (AP) is shown at the top of the button.
		
		From time to time Kernel node generates new Worms.
		""" },
	"virus": { "text": """
		The Virus malware can move and can attack enemy units in the range of 1.
		
		Also it can consume friendly Worms to temporarily gain more Action Points, even beyond the limit!
		
		Using 'boost' is the only way to then perform 'attack_n_spread'.
		""" },
	"trojan": { "text": """
		The Trojan malware can move fast but cannot attack.
		
		Can capture an enemy Anti-malware node.
		
		Can open a backdoor to move friendly malware to the Trojan over long distances.
		""" },
	
	"end_turn": { "text": """Shortcut: [color=green]Enter[/color]
	
	
		Click to end your turn and start the enemy's turn.
		
		All friendly units will restore Action Points.
		
		The ready status of their actions will be increased by 1.
		
		Tiles under units with spare Action Points are highlighted when hovering mouse over this button.
		""" },
	"select_idle_unit": { "text": """Shortcut: [color=green]Tab[/color]
		
		
		Click to select next friendly unit with spare Action Points.
		
		If some unit is dimmed, it has no more spare Action Points.
		
		Tiles under units with spare Action Points are highlighted when hovering mouse over this button.
		""" },
	"cancel_select_target": { "text": """Shortcut: [color=green]Esc[/color]
		
		
		Click to exit target selection mode. Can also be done by [color=green]right-clicking[/color] the battle field.
		
		After that it will be possible to select other abilities or units.
		""" },
	"ResetCamera": { "text": """Shortcut: [color=green]Backspace[/color]
		
		
		Click to reset the camera.
		
		To move camera you can use [color=green]arrow keys[/color] or [color=green]move mouse while holding its right or middle button[/color].
		
		And to zoom in and out you can use [color=green]+[/color] and [color=green]-[/color] keys or [color=green]mouse wheel[/color].
		
		The camera movement speed can be changed in the Options menu separately for mouse and keyboard.
		""" },
	#"Options": { "text": """
	#	Click this button to change settings, or to end or restart the battle.
	#""" },
	
	"move": { "text": """
		Unlike nodes, malware can move.
		
		Maximum movement distance depends on the amount of Action Points left for the malware.
		
		It's impossible to walk through other units or through enemy firewalls.
		
		[color=green]For this action it's not required to click the action button first - you can click the target tile right away, given there are enough Action Points to reach there.[/color]
		
		To move malware instantly at long distances use Trojan's 'open_backdoor' action instead.
		""" },
	
	"virus_attack": { "text": """
		Deals the damage to an enemy unit on a neighbor tile.
		
		This action won't work through enemy firewalls, so attack Anti-malware nodes first.
		
		[color=green]For this action it's not required to click the action button first - you can click the target on a neighbor tile right away.[/color]
		
		Possible damage amount is shown on the button.
		""" },
	"tower_attack": { "text": """
		Deals the damage to an enemy unit within the distance of 2 tiles.
		
		Note that there are enough Action Points (AP) for every Anti-malware to perform this action 3 times each turn.
		
		[color=green]For this action it's not required to click the action button first - you can click the target within the distance of 2 tiles right away.[/color]
		
		Possible damage amount is shown on the button.
		""" },
	
	"scale": { "text": """
		The 'duplicate' action generates a new Worm on the chosen neighbor tile.
		
		After duplicating both Worms are stuck until the next turn, so you might want to move the original one first.
		
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
		Consumes a chosen Worm from a neighbor tile. Action Points are increased by 3 then, even above the limit, until the next turn.
		
		Only one Worm per turn can be consumed by each Virus.
		
		This is the only way to perform 'attack_n_spread' action (on the same turn).
		""" },
	"spread": { "text": """
		The only way to perform 'attack_n_spread' is to first use 'boost' on the same turn.
		
		Deals the damage to an enemy malware on a neighbor tile.
		The damage is also spread instantly along the chain for enemy malware on next neighbor tiles.
		
		The total maximum distance is unlimited.
		This action won't work through enemy firewalls, free tiles and friendly units.
		
		Also it doesn't work with nodes, such as Kernel and Anti-malware.
		
		Possible damage amount per every affected enemy malware is shown on the button.
		""" },
	
	"repair": { "text": """
		Restores a few Hit Points of the chosen friendly unit (malware or node), except itself.
		
		The target unit must be located within the radius of 3 tiles (such tiles are marked with the Kernel group's color).
		
		The amount of Hit Points restored is shown on the button.
		
		The Kernel's own Hit Points are partially restored at the beginning of every turn with the 'maintain' auto-action instead.
	""" },
	"reset": { "text": """
		Performs a reset on 7 selected tiles eliminating all malware there regardless of their group.
		
		Nodes are unaffected. The central tile of the 7 must be located on the territory marked with the Kernel group's color.
		
		Be careful that it will also eliminate friendly malware as well!
		
		The period of unavailability after use, in turns, is shown on the button.
	""" },
	"spawn_worms": { "text": """
		Automatically generates up to 6 Worms on neighbor tiles. If any of neighbor tiles is occupied, no Worm is generated on that tile.
		
		The period of unavailability after use, in turns, is shown on the button.
	""" },
	"self_repair": { "text": """
		Automatically restores a few Kernel's own Hit Points at the beginning of every turn.
		
		The amount of Hit Points restored is shown on the button.
		""" },
	
	"capture_tower": { "text": """
		To capture an enemy Anti-malware node, firstly damage it down to 0 HP, so it changes its group to neutral.
		
		Secondly, move the Trojan close to the node and use this action on it.
		
		[color=green]For this action it's not required to click the action button first - you can click the neutral Anti-malware node on a neighbor tile right away.[/color]
	""" },
	"backdoor": { "text": """
		Allows to teleport up to 6 friendly malware to the Trojan. The Trojan cannot teleport itself.
		
		Teleported units will preserve their relative position to the center of target tile, but with the Trojan's tile as the center instead.
		
		But if any of the Trojan neighbor tiles is occupied, no malware is teleported in that particular tile.
		
		Unlike other actions it's possible to teleport through any firewalls.
		
		All teleported units' Action Points are reduced to 1 (or kept at zero) until the next turn.
		""" },
	
	}
