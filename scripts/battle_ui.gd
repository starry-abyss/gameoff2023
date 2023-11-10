extends Node3D

@onready var selected_unit_stats = $CanvasLayer/SelectedUnitStats
@onready var selected_unit_indicator = $SelectedUnitIndicator

signal tile_clicked
signal tile_hovered
signal unit_clicked
signal order_given

signal animation_finished

var in_select_target_mode = false:
	set(new_value):
		in_select_target_mode = new_value
		
		update_abilities_buttons()
		
var order_parameters = {}
var selected_unit_type
#var selected_unit_cooldowns

func _ready():
	$CanvasLayer/cancel_select_target.pressed.connect(_on_cancel_select_target_button_clicked)
	
	add_ability_button("Double", "scale", Gameplay.TargetTypes.TILE)
	add_ability_button("Self-modify to Virus", "self_modify_to_virus", Gameplay.TargetTypes.SELF)
	add_ability_button("Self-modify to Trojan", "self_modify_to_trojan", Gameplay.TargetTypes.SELF)
	
	add_ability_button("Repair", "repair", Gameplay.TargetTypes.UNIT)
	add_ability_button("Reset", "reset", Gameplay.TargetTypes.TILE)
	
	add_ability_button("Capture a tower", "capture_tower", Gameplay.TargetTypes.UNIT)
	add_ability_button("Open the backdoor", "backdoor", Gameplay.TargetTypes.TILE)
	
	in_select_target_mode = false

func update_abilities_buttons():
	$CanvasLayer/cancel_select_target.visible = in_select_target_mode && selected_unit_indicator.visible
	%ability_buttons.visible = !in_select_target_mode && selected_unit_indicator.visible
	
	if %ability_buttons.visible:
		var stats = StaticData.unit_stats[selected_unit_type]
		for button in %ability_buttons.get_children():
			if stats.has("abilities"):
				button.visible = stats.abilities.has(button.name)
			else:
				button.visible = false

func add_ability_button(button_text: String, ability_id: String, target_type: Gameplay.TargetTypes):
	var stats = StaticData.ability_stats[ability_id]
	
	var button = Button.new()
	
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
	#print("show ", path)
	pass

# doesn't work and not needed at the moment
func _on_show_path_not_enough_ap(unit: Unit, path: Array):
	pass

func _on_hide_path():
	pass
	
func _on_unit_move(unit: Unit, path: Array):
	#print("move ", path)
	
	# TODO: not needed when the function is implemented
	# immediately moves the unit model to the final tile
	# (to unit.tile_pos, gameplay-wise the actual unit is already there)
	unit.update_model_pos()
	pass

func _on_unit_selection_changed(unit: Unit):
	if unit == null:
		selected_unit_indicator.visible = false
		selected_unit_stats.visible = false
		
		in_select_target_mode = false
	else:
		selected_unit_stats.visible = true
		selected_unit_indicator.position = unit.position + Vector3(0, 1.5, 0) 
		selected_unit_indicator.visible = true
		selected_unit_stats._display_unit_stats(unit)
		
		selected_unit_type = unit.type
	
	update_abilities_buttons()

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

func _on_order_processed(success: bool):
	if success:
		in_select_target_mode = false
	
	update_abilities_buttons()

func _unhandled_input(event):
	if event is InputEventMouseButton && event.pressed:
		#print("Mouse Click/Unclick at: ", event.position)

		var world_pos = UIHelpers.screen_pos_to_world_pos(event.position)
		#print("world pos: ", world_pos)
		
		var tile_pos = UIHelpers.world_pos_to_tile_pos(world_pos)
		print("tile_pos: ", tile_pos)
		
		#var test_distance = UIHelpers.tile_pos_distance(Vector2i(5, 5), tile_pos)		
		#print("distance: ", test_distance)
		
		if !in_select_target_mode:
			tile_clicked.emit(tile_pos)
		elif order_parameters.target_type == Gameplay.TargetTypes.TILE:
			order_given.emit(order_parameters.ability_id, tile_pos)
		
	elif event is InputEventMouseMotion:
		#print("Mouse Motion at: ", event.position)
		
		var world_pos = UIHelpers.screen_pos_to_world_pos(event.position)
		#print("world pos: ", world_pos)
		
		var tile_pos = UIHelpers.world_pos_to_tile_pos(world_pos)
		
		if !in_select_target_mode:
			tile_hovered.emit(tile_pos)
		
