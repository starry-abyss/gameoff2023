#@tool
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
			set_tint(UIHelpers.group_to_color(new_value))
		group = new_value

var destroy_timer = 0.0
var to_be_removed = false
var hurt_timer = 0.0
var is_hurt = false
var spawn_timer = 0.0
var on_spawn = false
var aabb = null

var hp: int = 8
var hp_max: int = 8
var attack: int = 0
var attack_extra: int = 0
var attack_range: int = 0
var ap_cost_of_attack: int = 1
var ap: int = 3
var ap_max: int = 3
var cooldowns = {}

var emission_color: Color

# TODO: add this for Central nodes to restore tile coloring after capture
@export var tile_ownership_radius = 0

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
	#return attack > 0 || attack_extra > 0
	
	return type == Gameplay.UnitTypes.VIRUS || type == Gameplay.UnitTypes.TOWER_NODE

func get_cooldown(ability_id: String) -> int:
	if cooldowns.has(ability_id):
		return cooldowns[ability_id]
	return 0

func can_move() -> bool:
	return !is_static() && ap > 0

func can_be_destroyed() -> bool:
	# if Central node is destroyed then game might crash due to firewalls trying to make a connection :'D
	return type != Gameplay.UnitTypes.TOWER_NODE && type != Gameplay.UnitTypes.CENTRAL_NODE

func type_to_model_scene_name(which_type: Gameplay.UnitTypes) -> String:
	return Gameplay.UnitTypes.keys()[which_type].to_lower()

func load_model(model_scene_name: String):
	if model != null:
		model.queue_free()
	
	model = load("res://art/" + model_scene_name + ".tscn").instantiate()
	add_child(model)
	
	#model.set_meta("_edit_lock_", true)
	
	material = ShaderMaterial.new()
	material.resource_local_to_scene = true
	material.shader = glowing_outline_shader
	#material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	
	var mesh_instances = model.find_children("", "MeshInstance3D")
	#var mesh_instance: MeshInstance3D = mesh_instances[-1]
	for mi in mesh_instances:
		mi.material_override = material
	#var lights = model.find_children("", "Light3D")
	#for light in lights:
	#	light.queue_free()
	
	#var cameras = model.find_children("", "Camera3D")
	#for camera in cameras:
	#	camera.queue_free()
	
	set_tint(UIHelpers.group_to_color(group))
	
	aabb = Utils.get_aabb(model)
	
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
	
	return
	
	# TODO: remove after refactoring attack into ability is finished
	if stats.has("attack"):
		attack = stats.attack
	else:
		attack = 0
	
	if stats.has("attack_extra"):
		attack_extra = stats.attack_extra
	else:
		attack_extra = 0
	
	if stats.has("ap_cost_of_attack"):
		ap_cost_of_attack = stats.ap_cost_of_attack
	else:
		ap_cost_of_attack = 1
	
	if stats.has("attack_range"):
		attack_range = stats.attack_range
	else:
		if attack > 0 || attack_range > 0:
			attack_range = 1
		else:
			attack_range = 0
	
func set_tint(color: Color):
	if material != null:
		color.a = 0.45
		material.set_shader_parameter("emission_color", color)
	pass
	

func type_changed_set_up(new_type: Gameplay.UnitTypes):
	load_stats(new_type)
	load_model(type_to_model_scene_name(new_type))
	
	if new_type == Gameplay.UnitTypes.TOWER_NODE && model != null:
		var sides: MeshInstance3D = model.find_child("Sides")
		sides.rotate_y(randf() * PI * 2.0)

func _ready():
	#if Engine.is_editor_hint():
	type_changed_set_up(type)

	clickable_component.on_click.connect(_on_click)
	
func _on_click():
	on_click.emit(self)
	

func on_hurt():
	is_hurt = true
	material.set_shader_parameter("show_glitch", true)
	
	var y_range = 0.3
	var y_min = (aabb as AABB).size.y * randf_range(0, 1 - y_range)
	var y_max = (aabb as AABB).size.y * y_range + y_min 
	var glitch_y_range = Vector2(y_min, y_max)
	print(glitch_y_range)
	material.set_shader_parameter("glitch_y_range", glitch_y_range)
	
func _process(delta):
	if is_hurt:
		hurt_timer += delta
		if hurt_timer >= StaticData.hurt_animation_duration:
			material.set_shader_parameter("show_glitch", false)
			is_hurt = false
			hurt_timer = 0
			
	if on_spawn:
		spawn_timer += delta
		var y_min = (aabb as AABB).size.y * spawn_timer / StaticData.spawn_animation_duration
		var y_max = y_min + (aabb as AABB).size.y * 0.3
		var spawn_y_range = Vector2(y_min, y_max)
		material.set_shader_parameter("spawn_y_range", spawn_y_range)
		if spawn_timer >= StaticData.spawn_animation_duration:
			on_spawn = false
			spawn_timer = 0
			material.set_shader_parameter("spawn_y_range", Vector2(-10, 10))
			
	if to_be_removed:
		destroy_timer += delta
		
		#var new_scale = max(0.0, StaticData.turn_animation_duration - destroy_timer * 2.0) / StaticData.turn_animation_duration
		#scale = Vector3(new_scale, new_scale, new_scale)
		#material.set_shader_parameter("emission_color", Color(material.get_shader_parameter("emission_color"), new_scale))
		
		if destroy_timer >= StaticData.turn_animation_duration:
			queue_free()
	
	if type == Gameplay.UnitTypes.TOWER_NODE && model != null:
		var sides: MeshInstance3D = model.find_child("Sides")
		sides.rotate_y(delta * 0.4)


