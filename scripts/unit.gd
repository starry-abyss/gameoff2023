@tool
class_name Unit
extends Node3D

@export var type: Gameplay.UnitTypes = Gameplay.UnitTypes.TOWER_NODE:
	set(new_value):
		if type != new_value || model == null:
			type_changed_set_up(new_value)
		type = new_value

@export var group: Gameplay.HackingGroups = Gameplay.HackingGroups.NEUTRAL:
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

var tile_pos: Vector2i = Vector2i(0, 0):
	set(new_value):
		tile_pos = new_value
		#update_model_pos()

@onready var clickable_component = $ClickableComponent
@onready var glowing_outline_shader: VisualShader = preload("res://shaders/glowing_outline_shader.tres")


signal on_click(node: Node3D)


var model = null
var material: ShaderMaterial = null

func update_model_pos():
	var pos = UIHelpers.tile_pos_to_world_pos(tile_pos)
	transform.origin = Vector3(pos.x, 0.0, pos.y)

func is_static() -> bool:
	return type == Gameplay.UnitTypes.CENTRAL_NODE || type == Gameplay.UnitTypes.TOWER_NODE

func can_attack() -> bool:
	return attack > 0 || attack_extra > 0

func can_move() -> bool:
	return !is_static() && ap > 0
	
func type_to_model_scene_name(which_type: Gameplay.UnitTypes) -> String:
	return Gameplay.UnitTypes.keys()[which_type].to_lower()

func group_to_color(which_group: Gameplay.HackingGroups) -> Color:
	if which_group == Gameplay.HackingGroups.PINK:
		return StaticData.color_pink
	if which_group == Gameplay.HackingGroups.BLUE:
		return StaticData.color_blue
	return StaticData.color_neutral

func load_model(model_scene_name: String):
	if model != null:
		model.queue_free()
	
	model = load("res://art/" + model_scene_name + ".tscn").instantiate()
	add_child(model)
	
	#model.set_meta("_edit_lock_", true)
	
	var mesh_instances = model.find_children("", "MeshInstance3D")
	var mesh_instance: MeshInstance3D = mesh_instances[-1]
	
	material = ShaderMaterial.new()
	material.shader = glowing_outline_shader
	mesh_instance.material_override = material
	
	#var lights = model.find_children("", "Light3D")
	#for light in lights:
	#	light.queue_free()
	
	#var cameras = model.find_children("", "Camera3D")
	#for camera in cameras:
	#	camera.queue_free()
	
	set_tint(group_to_color(group))
	
	pass
	
func load_stats(which_type: Gameplay.UnitTypes):
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
	if material != null:
		material.set_shader_parameter("emission_color", color)
	pass
	

func type_changed_set_up(new_type: Gameplay.UnitTypes):
	load_stats(new_type)
	load_model(type_to_model_scene_name(new_type))

func _ready():
	#if Engine.is_editor_hint():
	type_changed_set_up(type)

	clickable_component.on_click.connect(_on_click)
	
func _on_click():
	on_click.emit(self)
