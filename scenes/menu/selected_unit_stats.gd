extends Control


@onready var type_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/Type
@onready var group_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/Group
@onready var hp_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/Hp
@onready var attack_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/Attack
@onready var ap_label: Label = $VBoxContainer/MarginContainer/VBoxContainer/Ap
@onready var title: Label = %Title

@onready var button_info_title: Label = $VBoxContainer/MarginContainer2/VBoxContainer/MarginContainer/Title
@onready var button_info_description: Label = $VBoxContainer/MarginContainer2/VBoxContainer/Description


func _display_unit_stats(unit: Unit, current_group: Gameplay.HackingGroups, is_selected: bool):
	type_label.text = ""
	%Title.text = StaticData.unit_stats[unit.type].name
	
	if unit.group != Gameplay.HackingGroups.NEUTRAL:
		if unit.group == current_group:
			if is_selected:
				group_label.text = "(selected)"
			else:
				group_label.text = " " # if just an empty string, then height of the widget jitters
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


func show_button_description(button_name: String):
	var button_info = StaticData.tooltips[button_name]
	button_info_title.text = button_name
	button_info_description.text = button_info.text
	button_info_title.visible = true
	button_info_description.visible = true
	

func hide_button_description():
	button_info_title.visible = false
	button_info_description.visible = false
