@tool
extends Node3D

@export var type: StaticData.UnitTypes = StaticData.UnitTypes.TOWER_NODE:
	set(new_value):
		if type != new_value:
			type_changed_set_up(new_value)
		type = new_value

@export var group: StaticData.HackingGroups = StaticData.HackingGroups.NEUTRAL:
	set(new_value):
		if group != new_value:
			set_tint(group_to_color(new_value))
		group = new_value

var hp: int = 8
var hp_max: int = 8
var attack: int = 0
var attack_extra: int = 0
var ap: int = 3
var ap_max: int = 3

var model = null
var material = null

func is_static() -> bool:
	return type == StaticData.UnitTypes.CENTRAL_NODE || type == StaticData.Types.TOWER_NODE

func can_attack() -> bool:
	return attack > 0 || attack_extra > 0

func can_move() -> bool:
	return !is_static() && ap > 0
	
func type_to_model_scene_name(which_type: StaticData.UnitTypes) -> String:
	return StaticData.UnitTypes.keys()[which_type].to_lower()

func group_to_color(which_group: StaticData.HackingGroups) -> Color:
	if which_group == StaticData.HackingGroups.PINK:
		return StaticData.color_pink
	if which_group == StaticData.HackingGroups.BLUE:
		return StaticData.color_blue
	return StaticData.color_neutral

func load_model(model_scene_name: String):
	if model != null:
		model.queue_free()
	
	model = load("res://art/" + model_scene_name + ".tscn").instantiate()
	add_child(model)
	
	var mesh_instances = model.find_children("", "MeshInstance3D")
	var mesh_instance = mesh_instances[-1]
	material = StandardMaterial3D.new()
	mesh_instance.material_override = material
	
	#var lights = model.find_children("", "Light3D")
	#for light in lights:
	#	light.queue_free()
	
	#var cameras = model.find_children("", "Camera3D")
	#for camera in cameras:
	#	camera.queue_free()
	
	set_tint(group_to_color(group))
	
	pass
	
func load_stats(which_type: StaticData.UnitTypes):
	var stats: Dictionary = StaticData.unit_stats[which_type]
	
	if stats.has("hp_max"):
		hp_max = stats.hp_max
		hp = hp_max
	else:
		hp_max = 1
		hp = 1
	
	if stats.has("ap_max"):
		ap_max = stats.ap_max
		ap = ap_max
	else:
		ap_max = 0
		ap = 0
	
	if stats.has("attack"):
		attack = stats.attack
	else:
		attack = 0
	
	if stats.has("attack_extra"):
		attack_extra = stats.attack_extra
	else:
		attack_extra = 0
	
func set_tint(color: Color):
	#print(material)
	
	if material != null:
		material.albedo_color = color
	pass

func type_changed_set_up(new_type: StaticData.UnitTypes):
	load_stats(new_type)
	load_model(type_to_model_scene_name(new_type))

func _ready():
	#print(type_to_model_scene_name(type))
	type_changed_set_up(type)
	
	#type = Types.TROJAN
