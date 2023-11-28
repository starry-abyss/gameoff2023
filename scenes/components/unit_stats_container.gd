extends Panel


@onready var unit_label: Label = $HBoxContainer/VBoxContainer/UnitLabel
@onready var info_label: Label = $HBoxContainer/VBoxContainer/InfoLabel
@onready var hp_label: Label = $HBoxContainer/HBoxContainer/VBoxContainer2/HPLabel
@onready var ap_label: Label = $HBoxContainer/HBoxContainer/VBoxContainer2/APLabel


func _display_unit_stats(unit: Unit, current_group: Gameplay.HackingGroups, is_selected: bool):
	unit_label.text = StaticData.unit_stats[unit.type].name
	
	if unit.group != Gameplay.HackingGroups.NEUTRAL:
		if unit.group == current_group:
			if is_selected:
				info_label.text = "(selected)"
			else:
				info_label.text = ""
		else:
			info_label.text = "(enemy)"
		hp_label.text = "%s / %s" % [unit.hp, unit.hp_max]
	else:
		info_label.text = "(offline)"
		hp_label.text = ""
	
	if unit.group != Gameplay.HackingGroups.NEUTRAL:
		ap_label.text = "%s / %s" % [unit.ap, unit.ap_max]
	else:
		ap_label.text = ""
