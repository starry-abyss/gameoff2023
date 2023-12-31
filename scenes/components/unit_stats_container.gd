extends Panel

@export var full_hp_ap = false
var is_ai_turn = false

@onready var unit_label: Label = $HBoxContainer/VBoxContainer/UnitLabel
@onready var info_label: Label = $HBoxContainer/VBoxContainer/InfoLabel
@onready var hp_label: Label = $HBoxContainer/HBoxContainer/VBoxContainer2/HPLabel
@onready var ap_label: Label = $HBoxContainer/HBoxContainer/VBoxContainer2/APLabel

func _ready():
	if full_hp_ap:
		%HP.text = "Hit Points"
		%AP.text = "Action Points"

func _process(delta):
	if full_hp_ap:
		# center vertically
		unit_label.position.y = (size.y - unit_label.size.y) * 0.5

func _display_unit_stats(unit: Unit, current_group: Gameplay.HackingGroups, is_selected: bool):
	unit_label.text = StaticData.unit_stats[unit.type].name
	
	if is_selected:
		unit_label.add_theme_color_override("font_color", Color("#00ff00"))
	else:
		unit_label.add_theme_color_override("font_color", Color.WHITE)
	
	var text_color = UIHelpers.group_to_color(unit.group)
	text_color.s += 0.1
	text_color.v += 2.0 #0.15
	info_label.add_theme_color_override("font_color", text_color)
	
	if unit.group != Gameplay.HackingGroups.NEUTRAL:
		if !full_hp_ap:
			if unit.group == Gameplay.HackingGroups.PINK:
				info_label.text = "> Rebels group"
			else:
				info_label.text = "> Cyber Police group"
			
			if StaticData.show_tutorial_hints && !is_ai_turn:
				if is_selected:
					info_label.text += " " # "\n> Selected"
				elif current_group == unit.group:
					info_label.text += "\n> Click to select"
		else:
			#if StaticData.show_tutorial_hints:
			#	info_label.text = "> Selected"
			#else:
			info_label.text = ""
			
			UIHelpers.override_ui_node_theme_font_size(unit_label, 20)
			
			# for it to be shorter
			unit_label.text = unit_label.text.replace(" node", "")
			unit_label.text = unit_label.text.replace(" malware", "")
		
		hp_label.text = "%s / %s" % [unit.hp, unit.hp_max]
		
		%HP.visible = true
		%AP.visible = true
	else:
		info_label.text = "> Offline"
		hp_label.text = ""
		
		%HP.visible = false
		%AP.visible = false
	
	# hack for fixed position and fixed to fit the info
	hp_label.text = hp_label.text.rpad(7)
	
	if unit.group != Gameplay.HackingGroups.NEUTRAL:
		ap_label.text = "%s / %s" % [unit.ap, unit.ap_max]
	else:
		ap_label.text = ""
