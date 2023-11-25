extends Control


@onready var type_label: Label = $MarginContainer/VBoxContainer/Type
@onready var group_label: Label = $MarginContainer/VBoxContainer/Group
@onready var hp_label: Label = $MarginContainer/VBoxContainer/Hp
@onready var attack_label: Label = $MarginContainer/VBoxContainer/Attack
@onready var ap_label: Label = $MarginContainer/VBoxContainer/Ap
@onready var title: Label = %Title

func _display_unit_stats(unit: Unit, current_group: Gameplay.HackingGroups):
	type_label.text = ""
	title.text = StaticData.unit_stats[unit.type].name
	if unit.group != current_group:
		title.text = "%s %s" % [title.text, "(Opponent)"]
	group_label.text = "" #"GROUP " + Gameplay.HackingGroups.keys()[unit.group]
	hp_label.text = "HP %s / %s" % [unit.hp, unit.hp_max]
	attack_label.text = "" # "ATTACK %s - %s, RANGE %s" % [unit.attack, unit.attack + unit.attack_extra, unit.attack_range]
	ap_label.text = "AP %s / %s" % [unit.ap, unit.ap_max]
