extends Control


@onready var type_label: Label = $MarginContainer/VBoxContainer/Type
@onready var group_label: Label = $MarginContainer/VBoxContainer/Group
@onready var hp_label: Label = $MarginContainer/VBoxContainer/Hp
@onready var attack_label: Label = $MarginContainer/VBoxContainer/Attack
@onready var ap_label: Label = $MarginContainer/VBoxContainer/Ap


func _display_unit_stats(unit: Unit, current_group: Gameplay.HackingGroups, is_selected: bool):
	type_label.text = ""
	%Title.text = StaticData.unit_stats[unit.type].name
	
	if unit.group != Gameplay.HackingGroups.NEUTRAL:
		if unit.group == current_group:
			if is_selected:
				group_label.text = "(selected)"
			else:
				group_label.text = ""
		else:
			group_label.text = "(enemy)"
		hp_label.text = "Hit Points:     %s / %s" % [unit.hp, unit.hp_max]
	else:
		group_label.text = "(offline)"
		hp_label.text = ""
	
	attack_label.text = "" # "ATTACK %s - %s, RANGE %s" % [unit.attack, unit.attack + unit.attack_extra, unit.attack_range]
	
	if unit.group != Gameplay.HackingGroups.NEUTRAL:
		ap_label.text = "Action Points:  %s / %s" % [unit.ap, unit.ap_max]
	else:
		ap_label.text = ""
