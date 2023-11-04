@tool
extends Node3D

@export var type: StaticData.UnitTypes = StaticData.UnitTypes.TOWER_NODE:
	set(new_value):
		if type != new_value:
			load_model(type_to_model_scene_name(new_value))
			set_tint(group_to_color(group))
		type = new_value

@export var group: StaticData.HackingGroups = StaticData.HackingGroups.NEUTRAL:
	set(new_value):
		if group != new_value:
			set_tint(group_to_color(new_value))
		group = new_value

@export var hp: int = 8
@export var hp_max: int = 8
@export var attack: int = 0
@export var attack_extra: int = 0
@export var ap: int = 3
@export var ap_max: int = 3

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
	
	pass
	
func set_tint(color: Color):
	#print(material)
	
	if material != null:
		material.albedo_color = color
	pass

func _ready():
	#print(type_to_model_scene_name(type))
	load_model(type_to_model_scene_name(type))
	set_tint(group_to_color(group))
	#type = Types.TROJAN
