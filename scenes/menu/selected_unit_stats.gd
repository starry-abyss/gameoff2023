extends Control


@onready var type_label: Label = $MarginContainer/VBoxContainer/Type
@onready var group_label: Label = $MarginContainer/VBoxContainer/Group
@onready var hp_label: Label = $MarginContainer/VBoxContainer/Hp
@onready var attack_label: Label = $MarginContainer/VBoxContainer/Attack
@onready var ap_label: Label = $MarginContainer/VBoxContainer/Ap


func _display_unit_stats(unit: Unit):
	type_label.text = "TYPE %s" % [unit.type]
	group_label.text = "GROUP %s" % [unit.group]
	hp_label.text = "HP %s / %s" % [unit.hp, unit.hp_max]
	attack_label.text = "ATTACK %s - %s" % [unit.attack, unit.attack + unit.attack_extra]
	ap_label.text = "AP %s / %s" % [unit.ap, unit.ap_max]
