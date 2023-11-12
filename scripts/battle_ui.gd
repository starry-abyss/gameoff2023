extends Node3D

@onready var selected_unit_stats = $CanvasLayer/SelectedUnitStats
@onready var selected_unit_indicator = $SelectedUnitIndicator
@onready var select_idle_unit = $CanvasLayer/select_idle_unit
@onready var end_turn = $CanvasLayer/end_turn
@onready var draw_3d = $Draw3d

@onready var movement_path: Path3D = $Path3D
@onready var movement_path_follow: PathFollow3D = $Path3D/PathFollow3D
@onready var movement_path_timer: Timer = $Path3D/Timer
@onready var movement_path_follow_node: Node3D = $Path3D/PathFollow3D/Node3D

signal tile_clicked
signal tile_hovered
signal unit_clicked
signal order_given

signal animation_finished

var is_selected_unit_moving = false:
	set(new_value):
		is_selected_unit_moving = new_value
		
		change_actions_disabled(is_selected_unit_moving)
		update_abilities_buttons_general_visibility()
	
var in_select_target_mode = false:
	set(new_value):
		in_select_target_mode = new_value
		
		update_abilities_buttons_general_visibility()
		
var order_parameters = {}
var selected_unit: Unit
var selected_unit_start_pos: Vector3


func _ready():
	$CanvasLayer/cancel_select_target.pressed.connect(_on_cancel_select_target_button_clicked)
	
	for ability_id in StaticData.ability_stats.keys():
		add_ability_button(ability_id)
	
	in_select_target_mode = false
	
	movement_path_timer.timeout.connect(_on_timer_timeout)
	movement_path_timer.wait_time = StaticData.turn_animation_duration

func change_actions_disabled(disable: bool):
	select_idle_unit.disabled = disable
	end_turn.disabled = disable
	

func update_abilities_buttons_general_visibility():
	$CanvasLayer/cancel_select_target.visible = !is_selected_unit_moving && in_select_target_mode && selected_unit_indicator.visible
	%ability_buttons.visible = !is_selected_unit_moving && !in_select_target_mode && selected_unit_indicator.visible

func update_abilities_buttons(selected_unit: Unit):
	update_abilities_buttons_general_visibility()
	
	if selected_unit != null:
		var stats = StaticData.unit_stats[selected_unit.type]
		for button in %ability_buttons.get_children():
			var ability_id = button.name
			var ability_stats = StaticData.ability_stats[ability_id]
			if stats.has("abilities"):
				button.visible = stats.abilities.has(ability_id)
				button.disabled = selected_unit.ap < ability_stats.ap \
					|| selected_unit.get_cooldown(ability_id) > 0
			else:
				button.visible = false

func add_ability_button(ability_id: String):
	var stats = StaticData.ability_stats[ability_id]
	
	var button = Button.new()
	
	var button_text = stats.name
	var target_type = stats.target
	
	var cooldown_text = (", CD: " + str(stats.cooldown)) if stats.cooldown > 0 else ""
	
	button.name = ability_id
	button.text = button_text \
		+ "\ntarget: " + Gameplay.TargetTypes.keys()[target_type] \
		+ "\nAP: " + str(stats.ap) + cooldown_text
	#button.position.x = %ability_buttons.get_children().size() * 100
	button.custom_minimum_size = Vector2(100, 100)
	
	%ability_buttons.add_child(button)
	button.pressed.connect(_on_ability_button_clicked.bind(ability_id, target_type))

func _on_show_path(unit: Unit, path: Array):
	draw_3d.clear_all()
	for index in range(len(path) - 1):
		var pos_1 = UIHelpers.tile_pos_to_world_pos(path[index])
		var pos_2 = UIHelpers.tile_pos_to_world_pos(path[index + 1])
		var world_pos_1 = Vector3(pos_1.x, 0.05, pos_1.y)
		var world_pos_2 = Vector3(pos_2.x, 0.05, pos_2.y)
		if index == 0:
			draw_3d.draw_point(world_pos_1)
		draw_3d.draw_point(world_pos_2)
		draw_3d.draw_line(world_pos_1, world_pos_2, Color.GREEN)

# doesn't work and not needed at the moment
func _on_show_path_not_enough_ap(unit: Unit, path: Array):
	pass

func _on_hide_path():
	draw_3d.clear_all()
	
func _on_unit_move(unit: Unit, path: Array):
	#print("move ", path)
	
	selected_unit_start_pos = unit.position
	var new_curve = Curve3D.new()
	for point in path:
		var pos = UIHelpers.tile_pos_to_world_pos(point)
		var pos_offset = Vector3(pos.x, 0.0, pos.y) - unit.position
		new_curve.add_point(pos_offset)
	movement_path.curve = new_curve
	movement_path_timer.start()
	
	is_selected_unit_moving = true
	
	# TODO: not needed when the function is implemented
	# immediately moves the unit model to the final tile
	# (to unit.tile_pos, gameplay-wise the actual unit is already there)
	#unit.update_model_pos()
	pass

func _on_unit_selection_changed(unit: Unit):
	selected_unit = unit
	if unit == null:
		selected_unit_indicator.visible = false
		selected_unit_stats.visible = false
		
		in_select_target_mode = false
	else:
		selected_unit_stats.visible = true 
		selected_unit_indicator.visible = true
		selected_unit_stats._display_unit_stats(unit)
	
	update_abilities_buttons(unit)

func _on_unit_destroy(unit: Unit):
	pass
	
func _on_unit_hp_change(unit: Unit, delta_hp: int):
	var label = preload("res://scenes/hp_change.tscn").instantiate()
	add_child(label)
	
	if delta_hp > 0:
		label.get_node("Label").text = "+" + str(delta_hp)
	else:
		label.get_node("Label").text = str(delta_hp)
	
	label.global_position = unit.global_position + Vector3(0.0, 2.0, 0.0)
	
func _on_playing_group_changed(current_group: Gameplay.HackingGroups, is_ai_turn: bool):
	#var group_color = UIHelpers.group_to_color(current_group)
	
	if current_group == Gameplay.HackingGroups.PINK:
		$CanvasLayer/end_turn.theme = preload("res://themes/pink.tres")
		$CanvasLayer/select_idle_unit.theme = preload("res://themes/pink.tres")
	else:
		$CanvasLayer/end_turn.theme = preload("res://themes/blue.tres")
		$CanvasLayer/select_idle_unit.theme = preload("res://themes/blue.tres")
	pass

func _on_battle_end(who_won: Gameplay.HackingGroups):
	pass
	
func _on_unit_click(unit: Unit):
	# for now we'll use tile click for this purpose
	return
	
	if !is_selected_unit_moving:
		if !in_select_target_mode:
			unit_clicked.emit(unit)
		elif order_parameters.target_type == Gameplay.TargetTypes.UNIT:
			order_given.emit(order_parameters.ability_id, unit)

func _on_ability_button_clicked(ability_id: String, target_type: Gameplay.TargetTypes):
	if target_type == Gameplay.TargetTypes.SELF:
		order_given.emit(ability_id, null)
	else:
		in_select_target_mode = true
		
		order_parameters.ability_id = ability_id
		order_parameters.target_type = target_type

func _on_cancel_select_target_button_clicked():
	in_select_target_mode = false

func _on_order_processed(success: bool, selected_unit: Unit):
	if success:
		in_select_target_mode = false
	
	_on_unit_selection_changed(selected_unit)
	#update_abilities_buttons(selected_unit)

func _unhandled_input(event):
	if event is InputEventMouseButton && event.pressed:
		#print("Mouse Click/Unclick at: ", event.position)

		var world_pos = UIHelpers.screen_pos_to_world_pos(event.position)
		#print("world pos: ", world_pos)
		
		var tile_pos = UIHelpers.world_pos_to_tile_pos(world_pos)
		print("tile_pos: ", tile_pos)
		
		#var test_distance = UIHelpers.tile_pos_distance(Vector2i(5, 5), tile_pos)		
		#print("distance: ", test_distance)
		
		if !is_selected_unit_moving:
			if !in_select_target_mode:
				tile_clicked.emit(tile_pos)
			else:
				if order_parameters.target_type == Gameplay.TargetTypes.TILE:
					order_given.emit(order_parameters.ability_id, tile_pos)
				elif order_parameters.target_type == Gameplay.TargetTypes.UNIT:
					order_given.emit(order_parameters.ability_id, tile_pos)
		
	elif event is InputEventMouseMotion:
		#print("Mouse Motion at: ", event.position)
		
		var world_pos = UIHelpers.screen_pos_to_world_pos(event.position)
		#print("world pos: ", world_pos)
		
		var tile_pos = UIHelpers.world_pos_to_tile_pos(world_pos)
		
		if !in_select_target_mode and !is_selected_unit_moving:
			tile_hovered.emit(tile_pos)
		
		
func _process(delta):
	if selected_unit != null:
		selected_unit_indicator.position = selected_unit.position + Vector3(0, 1.5, 0)
	
	if !movement_path_timer.is_stopped():
		movement_path_follow.progress_ratio = (movement_path_timer.wait_time - movement_path_timer.time_left) / movement_path_timer.wait_time
		selected_unit.position = selected_unit_start_pos + movement_path_follow_node.global_position
	pass
	
func _on_timer_timeout():
	is_selected_unit_moving = false
