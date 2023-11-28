extends Panel

@export var full_hp_ap = false

@onready var unit_label: Label = $HBoxContainer/VBoxContainer/UnitLabel
@onready var info_label: Label = $HBoxContainer/VBoxContainer/InfoLabel
@onready var hp_label: Label = $HBoxContainer/HBoxContainer/VBoxContainer2/HPLabel
@onready var ap_label: Label = $HBoxContainer/HBoxContainer/VBoxContainer2/APLabel

func _ready():
	if full_hp_ap:
		%HP.text = "Hit Points"
		%AP.text = "Action Points"

func _display_unit_stats(unit: Unit, current_group: Gameplay.HackingGroups, is_selected: bool):
	unit_label.text = StaticData.unit_stats[unit.type].name
	if is_selected:
		unit_label.add_theme_color_override("font_color", Color("#00ff00"))
	else:
		unit_label.add_theme_color_override("font_color", Color.WHITE)
	
	info_label.add_theme_color_override("font_color", \
		UIHelpers.group_to_color(unit.group).lightened(0.15))
	
	if unit.group != Gameplay.HackingGroups.NEUTRAL:
		if !full_hp_ap:
			if unit.group == Gameplay.HackingGroups.PINK:
				info_label.text = "> Rebels group"
			else:
				info_label.text = "> Cyber police group"
			
			if StaticData.show_tutorial_hints:
				if is_selected:
					info_label.text += " " # "\n> Selected"
				elif current_group == unit.group:
					info_label.text += "\n> Click to select"
		else:
			#if StaticData.show_tutorial_hints:
			#	info_label.text = "> Selected"
			#else:
			info_label.text = ""
		
		hp_label.text = "%s / %s" % [unit.hp, unit.hp_max]
	else:
		info_label.text = "> Offline"
		hp_label.text = ""
	
	if unit.group != Gameplay.HackingGroups.NEUTRAL:
		ap_label.text = "%s / %s" % [unit.ap, unit.ap_max]
	else:
		ap_label.text = ""
