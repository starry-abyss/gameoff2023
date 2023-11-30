#@tool
class_name Unit
extends Node3D

@export var type: Gameplay.UnitTypes = Gameplay.UnitTypes.TOWER_NODE:
	set(new_value):
		var type_changed = (type != new_value)
		type = new_value
		if type_changed || model == null:
			type_changed_set_up(new_value)
		

@export var group: Gameplay.HackingGroups = Gameplay.HackingGroups.NEUTRAL:
	set(new_value):
		if group != new_value:
			set_tint(UIHelpers.group_to_color(new_value))
		group = new_value
		
		restore_tower_balls()

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

var tower_ball_current = null
var attack_timer = 0.0
var is_attacking = false
var attack_target_pos = Vector3(0.0, 0.0, 0.0)
var attack_start_pos = Vector3(0.0, 0.0, 0.0)

var is_mutating = false
var mutation_timer = 0.0
var start_mutation_scale_x = 0.3
var start_mutation_scale_z = 0.5

var emission_color: Color

var idle_animation_offset = 0.0

var tower_balls = []

var timeout_callback_helper

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
	
	if type == Gameplay.UnitTypes.TOWER_NODE:
		#var ball_material = ShaderMaterial.new()
		#ball_material.shader = preload("res://shaders/electric/electric.gdshader")
		#ball_material.set_shader_parameter("show_glitch", true)
		
		var ball_material = preload("res://shaders/electric/electric_tower_material.tres")
		
		for ball in model.get_node("balls").get_children():
			ball.material_override = ball_material.duplicate()
			
			ball.rotate_y(randf() * PI * 2.0)
			ball.material_override.set_shader_parameter("electro_scale", 6.0 + randf() * 2.0)
			ball.material_override.set_shader_parameter("speed", 3.5 + randf() * 1.5)
			ball.material_override.set_shader_parameter("random_scale", 4.6)
			#ball.material_override.set_shader_parameter("seed", Vector2(randf(), randf()))
		
		restore_tower_balls()
	
	#var lights = model.find_children("", "Light3D")
	#for light in lights:
	#	light.queue_free()
	
	#var cameras = model.find_children("", "Camera3D")
	#for camera in cameras:
	#	camera.queue_free()
	
	set_tint(UIHelpers.group_to_color(group))
	
	aabb = Utils.get_aabb(model)
	
	set_initial_facing()
	pass
	
func restore_tower_balls():
	if type == Gameplay.UnitTypes.TOWER_NODE && model != null:
		tower_balls = []
		for ball in model.get_node("balls").get_children():
			ball.visible = group != Gameplay.HackingGroups.NEUTRAL
			tower_balls.append(ball)

func use_tower_ball() -> MeshInstance3D:
	return tower_balls.pop_back()

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
		if type == Gameplay.UnitTypes.TOWER_NODE:
			var ball_color = color
			
			
			for ball in model.get_node("balls").get_children():
				ball_color.a = 0.5
				ball_color.v *= 1.3
				ball.material_override.set_shader_parameter("light_color", ball_color)
				
				#ball_color.v *= 2.0
				#ball.material_override.set_shader_parameter("arc_color", ball_color)
			
			#color.a = 0.85
			#color.s = 1.0
			#color.v = 0.20
			
			#material.set_shader_parameter("emission_amount", 3.0)
			#material.set_shader_parameter("emission_color", color)
			#return
		
		color.a = 0.85
		
		#if type == Gameplay.UnitTypes.TOWER_NODE:
			#color.v *= 0.85
			#color.s *= 0.8
		
		material.set_shader_parameter("emission_color", color)
	pass

func set_look_at(point: Vector2):
	return
	
	# doesn't fully work
	if model != null:
		var dx = point.x - model.global_position.z
		var threshold = StaticData.tile_size.x * 0.5
		var m = model.get_child(0)
		
		if dx > threshold:
			m.rotation_degrees.x = -24.4
			m.rotation_degrees.y = 0
		elif dx < -threshold:
			m.rotation_degrees.x = 24.4
			m.rotation_degrees.y = 180

func set_initial_facing():
	if !is_static() && model != null:
		var m = model.get_child(0)
		if group == Gameplay.HackingGroups.BLUE:
			m.rotation_degrees.x = 24.4
			m.rotation_degrees.y = 180
		else:
			m.rotation_degrees.x = -24.4
			m.rotation_degrees.y = 0

func type_changed_set_up(new_type: Gameplay.UnitTypes):
	load_stats(new_type)
	load_model(type_to_model_scene_name(new_type))
	
	if new_type == Gameplay.UnitTypes.TOWER_NODE && model != null:
		var sides: MeshInstance3D = model.find_child("Sides")
		sides.rotate_y(randf() * PI * 2.0)
	
	if new_type == Gameplay.UnitTypes.CENTRAL_NODE && model != null:
		var antenna: MeshInstance3D = model.find_child("Antenna")
		antenna.rotate_y(randf() * PI * 2.0)

func _ready():
	timeout_callback_helper = get_tree().get_nodes_in_group("TimeoutCallbackHelper")[0]
	#if Engine.is_editor_hint():
	type_changed_set_up(type)

	clickable_component.on_click.connect(_on_click)
	
	idle_animation_offset = randf_range(0.0, 2 * PI)
	
func _on_click():
	on_click.emit(self)

func on_mutating():
	is_mutating = true
	
	scale = Vector3(start_mutation_scale_x, 1.0, start_mutation_scale_z)

func on_attacking(target, start_pos):
	is_attacking = true
	
	attack_start_pos = start_pos
	global_position = attack_start_pos
	
	if target is Unit:
		var unit_aabb = Utils.get_aabb(target.model)
		attack_target_pos = target.global_position + Vector3(0.0, unit_aabb.size.y * 0.5, 0.0)
	elif target is Vector2i:
		var wp = UIHelpers.tile_pos_to_world_pos(target)
		attack_target_pos = Vector3(wp.x, 0.0, wp.y)
	else:
		# this branch shouldn't happen
		assert(false)
	
	if type == Gameplay.UnitTypes.TOWER_NODE:
		#if tower_ball_current == null:
		tower_ball_current = use_tower_ball()
	else:
		attack_target_pos.y = 0.0


func on_hurt_end():
	material.set_shader_parameter("show_glitch", false)
	

func wait_for_hurt(time):
	timeout_callback_helper.call_after_time(on_hurt, time)
	
	
func on_hurt():
	if is_static() && hp <= 0:
		UIHelpers.audio_event3d("SFX/Kernel Node/SFX_KernelDamage", tile_pos)
	else:
		UIHelpers.audio_event3d("SFX/GeneralEvents/UnitDamage", tile_pos)
	
	#is_hurt = true
	timeout_callback_helper.call_after_time(on_hurt_end, StaticData.hurt_animation_duration)
	
	material.set_shader_parameter("show_glitch", true)
	
	const y_range = 0.3
	const y_margin = 0.2
	
	var y_min = (aabb as AABB).size.y * randf_range(y_margin, 1.0 - y_margin - y_range)
	var y_max = (aabb as AABB).size.y * y_range + y_min
	var y_pos = aabb.position.y
	var glitch_y_range = Vector2(y_min + y_pos, y_max + y_pos)
	material.set_shader_parameter("glitch_y_range", glitch_y_range)


func start_spawn():
	on_spawn = true
	timeout_callback_helper.call_after_time(on_spawn_end, StaticData.spawn_animation_duration)


func on_spawn_end():
	on_spawn = false
	spawn_timer = 0
	material.set_shader_parameter("spawn_y_range", Vector2(-10, 10))


func _process(delta):
	# used for attacks and for other gradual movement as well
	if is_attacking:
		attack_timer += delta
		
		#var wp = UIHelpers.tile_pos_to_world_pos(tile_pos)
		#var original_pos = Vector3(wp.x, 0.0, wp.y)
		
		var progress = max(0.0, attack_timer * 1.0) / StaticData.attack_animation_duration
		
		if type == Gameplay.UnitTypes.TOWER_NODE:
			if tower_ball_current != null:
				progress = ease(progress, 0.1)
				tower_ball_current.global_position = global_position.lerp(attack_target_pos, progress)
		elif type == Gameplay.UnitTypes.VIRUS:
			if model != null:
				rotation.y = progress * PI * 2.0
				
				global_position = attack_start_pos.lerp((attack_target_pos + attack_start_pos) * 0.5, sin(progress * PI))
		elif type == Gameplay.UnitTypes.TROJAN:
			var fast_progress = progress * 3.0
			if fast_progress > 1.0:
				fast_progress = 1.0
			
			global_position = attack_start_pos.lerp(attack_target_pos, fast_progress)
		else:
			global_position = attack_start_pos.lerp(attack_target_pos, ease(progress, 3.6))
		
		if attack_timer >= StaticData.attack_animation_duration:
			if type == Gameplay.UnitTypes.TOWER_NODE:
				tower_ball_current.visible = false
				tower_ball_current = null
			elif type == Gameplay.UnitTypes.VIRUS:
				update_model_pos()
			else:
				if !to_be_removed:
					update_model_pos()
			
			is_attacking = false
			attack_timer = 0.0
	
	if is_mutating:
		mutation_timer += delta
		
		var progress_x = max(start_mutation_scale_x, mutation_timer * 1.0) / StaticData.mutation_animation_duration
		progress_x = ease(progress_x, 4.8)
		
		var progress_z = max(start_mutation_scale_z, mutation_timer * 1.0) / StaticData.mutation_animation_duration
		progress_z = ease(progress_z, 4.8)
		
		scale = Vector3(progress_x, 1.0, progress_z)
		
		if mutation_timer >= StaticData.mutation_animation_duration:
			scale = Vector3(1.0, 1.0, 1.0)
			
			is_mutating = false
			mutation_timer = 0.0
	
	#if is_hurt:
		#hurt_timer += delta
		#if hurt_timer >= StaticData.hurt_animation_duration:
			#material.set_shader_parameter("show_glitch", false)
			#is_hurt = false
			#hurt_timer = 0
			
	if on_spawn:
		spawn_timer += delta
		var y_max = (aabb as AABB).size.y * spawn_timer / StaticData.spawn_animation_duration
		var spawn_y_highlight_range = (aabb as AABB).size.y * 0.2
		var spawn_y_range = Vector2((aabb as AABB).position.y, (aabb as AABB).position.y + y_max)
		material.set_shader_parameter("spawn_y_highlight_range", spawn_y_highlight_range)
		material.set_shader_parameter("spawn_y_range", spawn_y_range)
		#if spawn_timer >= StaticData.spawn_animation_duration:
			#on_spawn = false
			#spawn_timer = 0
			#material.set_shader_parameter("spawn_y_range", Vector2(-10, 10))
	else:
		spawn_timer = 0
		material.set_shader_parameter("spawn_y_range", Vector2(-10, 10))
	
	if to_be_removed:
		destroy_timer += delta
		
		var new_scale = max(0.0, StaticData.turn_animation_duration - destroy_timer * 1.5) / StaticData.turn_animation_duration
		#scale = Vector3(new_scale, new_scale, new_scale)
		new_scale = ease(new_scale, 0.4)
		
		material.set_shader_parameter("opacity", new_scale)
		
		if destroy_timer >= StaticData.turn_animation_duration:
			queue_free()
	
	if type == Gameplay.UnitTypes.VIRUS && model != null:
		var time = Time.get_ticks_msec()
		model.position.y = 0.18 * ease(1.0 + sin(idle_animation_offset + time * 0.001), 0.2)
		
	if type == Gameplay.UnitTypes.WORM && model != null:
		var time = Time.get_ticks_msec()
		model.rotation.x = 0.12 * (0.0 + sin(idle_animation_offset + time * 0.001))
	
	if type == Gameplay.UnitTypes.TROJAN && model != null:
		var time = Time.get_ticks_msec()
		model.position.x = 0.07 * ease(1.0 + sin(idle_animation_offset + time * 0.001), -5.0)
	
	if type == Gameplay.UnitTypes.CENTRAL_NODE && model != null:
		var antenna: MeshInstance3D = model.find_child("Antenna")
		antenna.rotate_y(delta * 0.4)
	
	if type == Gameplay.UnitTypes.TOWER_NODE && model != null:
		var sides: MeshInstance3D = model.find_child("Sides")
		sides.rotate_y(delta * 0.4)
		
		for i in range(3):
			if tower_balls.size() > i:
				var ball = tower_balls[i]
				var a = sides.rotation.y + i * 2.0 * PI / 3.0
				var b = sides.rotation.y * (i + 1) * 3.0
				
				var distance = 0.25
				ball.global_position = global_position + Vector3(distance * cos(a), 1.2 + 0.2 * sin(b), distance * sin(a))
				ball.rotate_y(delta * 1.1)
				
