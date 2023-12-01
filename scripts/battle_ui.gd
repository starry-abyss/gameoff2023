extends Node3D

@onready var tooltip_panel = $CanvasLayer/TooltipPanel
@onready var selected_unit_indicator = $SelectedUnitIndicator
@onready var select_idle_unit = %select_idle_unit
@onready var end_turn = %end_turn
@onready var draw_3d = $Draw3d
@onready var selected_unit_avatar: Panel = $CanvasLayer/SelectedUnitAvatar
@onready var selected_unit_stats_panel: Panel = %SelectedUnitStatsPanel
@onready var hovered_unit_stats_panel: Panel = $CanvasLayer/HoveredUnitStatsPanel

@onready var movement_path: Path3D = $Path3D
@onready var movement_path_follow: PathFollow3D = $Path3D/PathFollow3D
@onready var movement_path_timer: Timer = $Path3D/Timer
@onready var movement_path_follow_node: Node3D = $Path3D/PathFollow3D/Node3D

signal tile_clicked
signal tile_hovered
signal tiles_need_tint
signal tiles_need_tint_all
signal tiles_need_reset_tint
signal unit_clicked
signal order_given

signal animation_finished

var in_unit_animation_mode = false:
	set(new_value):
		in_unit_animation_mode = new_value
		
		change_actions_disabled(in_unit_animation_mode)
		update_abilities_buttons_general_visibility()
	
var in_select_target_mode = false:
	set(new_value):
		in_select_target_mode = new_value
		
		update_abilities_buttons_general_visibility()
		
var order_parameters = {}
var animated_unit: Unit
var animated_unit_start_pos: Vector3

var current_group: Gameplay.HackingGroups
var is_ai_turn = false

var last_tile_pos = Vector2i(0, 0)
var timeout_callback_helper

func _ready():
	timeout_callback_helper = get_tree().get_nodes_in_group("TimeoutCallbackHelper")[0]
	%end_game_message.get_parent().visible = false
	
	for button in find_children("", "Button"):
		button.set_script(preload("res://scripts/button.gd"))
		button._ready()
		button.set_process(true)
		
		button.connect("on_highlight", _on_ability_button_highlight)
		button.connect("on_unhighlight", _on_ability_button_unhighlight)
	
	for button in get_node("../CanvasLayer").find_children("", "Button"):
		button.set_script(preload("res://scripts/button.gd"))
		button._ready()
		button.set_process(true)
		
		button.connect("on_highlight", _on_ability_button_highlight)
		button.connect("on_unhighlight", _on_ability_button_unhighlight)
	
	%cancel_select_target.pressed.connect(_on_cancel_select_target_button_clicked)	
	%cancel_select_target.is_back_button = true
	
	%select_idle_unit.no_press_sound = true

	for ability_id in StaticData.ability_stats.keys():
		add_ability_button(ability_id)
	
	in_select_target_mode = false
	
	movement_path_timer.timeout.connect(_on_timer_timeout)
	#movement_path_timer.wait_time = StaticData.turn_animation_duration
	
	#RenderingServer.set_debug_generate_wireframes(true)
	#get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	
	_on_unit_show_stats(null, false)

func change_actions_disabled(disable: bool):
	%select_idle_unit.disabled = disable
	end_turn.disabled = disable
	
func update_selection_indicator(unit: Unit):
	selected_unit_indicator.visible = (unit != null)
	
	if unit != null:
		var unit_aabb = Utils.get_aabb(unit.model)
		selected_unit_indicator.position = unit.position + Vector3(0, unit_aabb.size.y + Utils.get_y_offset(unit.type), 0)

func update_abilities_buttons_general_visibility():
	%cancel_select_target.visible = !in_unit_animation_mode && in_select_target_mode && selected_unit_indicator.visible && !is_ai_turn
	%ability_buttons.visible = !in_select_target_mode && selected_unit_indicator.visible && !is_ai_turn
	#selected_unit_label.visible = %ability_buttons.visible
	#$CanvasLayer/Panel/Panel/function_list_label.visible = %ability_buttons.visible
	
	%ai_turn_message.visible = is_ai_turn
	%end_turn.visible = !is_ai_turn
	%select_idle_unit.visible = !is_ai_turn
	#%SelectedUnitStatsPanel.visible = !is_ai_turn

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
					|| selected_unit.get_cooldown(ability_id) > 0 \
					|| ability_stats.ap == 0
				
				update_ability_button_text(ability_id, selected_unit)
			else:
				button.visible = false
	
	if in_unit_animation_mode:
		for button in %ability_buttons.get_children():
			button.disabled = true
			
	update_abilities_buttons_icon_tint()

func add_ability_button(ability_id: String):
	var stats = StaticData.ability_stats[ability_id]
	
	var button = Button.new()
	button.theme = load("res://themes/ui.tres")
	
	button.name = ability_id
	button.custom_minimum_size = Vector2(140, 140)

		#icon.material.set_shader_parameter("tint", Color.GREEN)
	
	button.text = ""
	#button.position.x = %ability_buttons.get_children().size() * 100
	
	UIHelpers.override_ui_node_theme_font_size(button, 12)
	
	%ability_buttons.add_child(button)
	button.pressed.connect(_on_ability_button_clicked.bind(ability_id, stats.target))
	
	var tint_all_tiles = func():
		_on_hide_path()
		
		if !button.disabled:
			tiles_need_tint_all.emit(ability_id)
		else:
			tiles_need_reset_tint.emit()
	button.mouse_entered.connect(tint_all_tiles)
	
	button.set_script(preload("res://scripts/button.gd"))
	button.connect("on_highlight", _on_ability_button_highlight)
	button.connect("on_unhighlight", _on_ability_button_unhighlight)
	button._ready()
	button.set_process(true)
	
	button.no_press_sound = (stats.target == Gameplay.TargetTypes.SELF)
	#button.mouse_entered.connect(_on_button_highlight.bind(button))
	
	if stats.has("icon"):
		var icon = TextureRect.new()
		icon.material = ShaderMaterial.new()
		icon.material.shader = preload("res://shaders/icon_shader.gdshader")
		icon.texture = load("res://art/icons/" + stats.icon + ".png")
		icon.name = "icon"
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.size = button.size * 0.4
		#icon.pivot_offset = icon.size * 0.5
		icon.position = (button.size - icon.size) * 0.5
		

func make_ap_string(ability_id, ap) -> String:
	if ability_id == "move":
		return "AP: " + str(ap) + " per tile"
	elif ap > 0:
		return "AP: " + str(ap)
	elif ap < 0:
		return "AP: +" + str(-ap)
	
	return "auto"

func make_cd_string(cooldown) -> String:
	if cooldown > 0:
		if cooldown % 10 == 1:
			return str(cooldown) + " turn left"
		else:
			return str(cooldown) + " turns left"
	
	return ""

func update_ability_button_text(ability_id: String, selected_unit: Unit):
	assert(selected_unit != null)
	
	var stats = StaticData.ability_stats[ability_id]
	
	var cooldown_text = ""
	if stats.cooldown > 0:
		var current_cooldown = selected_unit.get_cooldown(ability_id)
		cooldown_text += ", ready: %s/%s" % [stats.cooldown - current_cooldown, stats.cooldown]
		#+ str(stats.cooldown) + "\n" + make_cd_string(current_cooldown)
	
	if stats.has("attack"):
		cooldown_text += ", damage: %s-%s" % [stats.attack, stats.attack + stats.attack_extra]
	
	if stats.has("restored_hp"):
		cooldown_text += ", HP: +%s" % [stats.restored_hp]
	
	var button = %ability_buttons.get_node(ability_id)
	button.text = make_ap_string(ability_id, stats.ap) + cooldown_text \
		#+ "\nargument: " + Gameplay.TargetTypes.keys()[stats.target] \
		+ "\n\n\n\n\n\n\n" + stats.name

func _on_show_path(unit: Unit, path: Array):
	if in_select_target_mode && (order_parameters.ability_id != "move"):
		return
	
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
	
	animated_unit_start_pos = unit.position
	var new_curve = Curve3D.new()
	for point in path:
		var pos = UIHelpers.tile_pos_to_world_pos(point)
		var pos_offset = Vector3(pos.x, 0.0, pos.y) - unit.position
		new_curve.add_point(pos_offset)
	movement_path.curve = new_curve
	movement_path_timer.wait_time = StaticData.move_animation_duration_per_tile * (len(path) - 1)
	
	if movement_path_timer.wait_time > StaticData.turn_animation_duration:
		movement_path_timer.wait_time = StaticData.turn_animation_duration
	
	movement_path_timer.start()
	
	in_unit_animation_mode = true
	animated_unit = unit
	
	#if animated_unit.type == Gameplay.UnitTypes.WORM:
		#UIHelpers.audio_event3d_loop_start("SFX/Worms/SFX_WormMove", animated_unit)
		#UIHelpers.audio_event3d("SFX/Worms/SFX_WormMove", animated_unit.tile_pos)
	#elif animated_unit.type == Gameplay.UnitTypes.TROJAN:
		#UIHelpers.audio_event3d_loop_start("SFX/Trojan/SFX_TrojanMove", animated_unit)
		#UIHelpers.audio_event3d("SFX/Trojan/SFX_TrojanMove", animated_unit.tile_pos)
	#elif animated_unit.type == Gameplay.UnitTypes.VIRUS:
		#UIHelpers.audio_event3d_loop_start("SFX/Virus/SFX_VirusMove", animated_unit)
	UIHelpers.audio_event3d("SFX/Virus/SFX_VirusMove", animated_unit.tile_pos)
	#UIHelpers.audio_event("SFX/Virus/SFX_VirusMove")

func _on_unit_selection_changed(unit: Unit):
	#if unit == null:
	in_select_target_mode = false
	
	tiles_tint_reset()
	
	update_selected_unit_avatar(unit)
	update_selected_unit_stats(unit)
	update_selection_indicator(unit)
	update_abilities_buttons(unit)
	#update_abilities_buttons_general_visibility()

func update_selected_unit_avatar(unit: Unit):
	if unit != null:
		selected_unit_avatar.show_avatar(unit)
	else:
		selected_unit_avatar.hide_avatar()

func update_selected_unit_stats(unit: Unit):
	if is_ai_turn:
		unit = null
	
	if unit == null:
		selected_unit_stats_panel.visible = false
	else:
		selected_unit_stats_panel.visible = true
		selected_unit_stats_panel._display_unit_stats(unit, current_group, true)

func _on_unit_show_stats(unit: Unit, is_selected: bool):
	if unit == null:
		hovered_unit_stats_panel.visible = false
		
		_on_ability_button_unhighlight()
	else:
		hovered_unit_stats_panel.visible = true
		hovered_unit_stats_panel._display_unit_stats(unit, current_group, is_selected)
		
		_on_ability_button_highlight(unit.type_to_model_scene_name(unit.type), \
			StaticData.unit_stats[unit.type].name)

func _on_unit_destroy(unit: Unit):
	pass

func _on_unit_spawn(unit: Unit):
	unit.start_spawn()
	pass

func _on_unit_hp_change(unit: Unit, delta_hp: int):
	# hack to not crash here
	if unit == null:
		return
	
	var label = preload("res://scenes/hp_change.tscn").instantiate()
	add_child(label)
	
	if delta_hp > 0:
		label.get_node("Label").modulate = Color("#00ff00")
		label.get_node("Label").text = "+" + str(delta_hp)
	else:
		label.get_node("Label").text = "" + str(delta_hp)
	
	var unit_aabb = Utils.get_aabb(unit.model)
	label.global_position = unit.global_position\
	 + Vector3(0.0, unit_aabb.size.y + Utils.get_y_offset(unit.type), 0.0)
	
func _on_playing_group_changed(current_group: Gameplay.HackingGroups, is_ai_turn: bool):
	change_theme_color()
	self.current_group = current_group
	self.is_ai_turn = is_ai_turn
	
	update_abilities_buttons_general_visibility()
	#update_abilities_buttons_icon_tint()
	
	hovered_unit_stats_panel.is_ai_turn = is_ai_turn
	
	# hack for unit stats to update
	tile_hovered.emit(last_tile_pos)

func update_abilities_buttons_icon_tint():
	for button in %ability_buttons.get_children():
		if button.has_node("icon"):
			var color = UIHelpers.group_to_color(current_group)
			if button.disabled:
				color.s -= 0.5
				color.v += 1.0
			else:
				color.v += 7.0
			#color.s *= 1.1
			button.get_node("icon").material.set_shader_parameter("tint", color)

func change_theme_color():
	update_abilities_buttons_icon_tint()
	
	var ui_nodes = [
	%end_turn, 
	%select_idle_unit, 
	%cancel_select_target, 
	$CanvasLayer/Panel,
	$CanvasLayer/Panel2,
	tooltip_panel,
	selected_unit_avatar,
	selected_unit_stats_panel,
	hovered_unit_stats_panel
	]
	ui_nodes.append_array(%ability_buttons.get_children())
	
	if current_group == Gameplay.HackingGroups.PINK:
		UIHelpers.override_ui_node_theme_with_color(ui_nodes, StaticData.color_pink)
	else:
		UIHelpers.override_ui_node_theme_with_color(ui_nodes, StaticData.color_blue)


func _on_battle_end(who_won: Gameplay.HackingGroups):
	%end_game_message.get_parent().visible = true
	
	if who_won == Gameplay.HackingGroups.PINK:
		%end_game_message.text = "Rebels win!"
	else:
		%end_game_message.text = "Cyber Police wins!"
	
func _on_unit_click(unit: Unit):
	# for now we'll use tile click for this purpose
	return
	
	if !in_unit_animation_mode:
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

func _on_ability_button_highlight(name: String, label: String, hide_stats = false):
	var title = ""
	if StaticData.ability_stats.has(name):
		title = StaticData.ability_stats[name].name
	else:
		title = label
	
	var show_tooltip = StaticData.show_tutorial_hints || name == "InstructionsAndMenuButton"
	
	if StaticData.tooltips.has(name) && show_tooltip:
		var author_name = _get_ability_author_name(name)
		tooltip_panel.show_tooltip(title, StaticData.tooltips[name].text, author_name)
	else:
		tooltip_panel.hide_tooltip()
	
	if hide_stats:
		hovered_unit_stats_panel.visible = false

func _on_ability_button_unhighlight():
	tooltip_panel.hide_tooltip()

func _get_ability_author_name(ability_name):
	var name = ""
	var dictionary = (StaticData.tooltips[ability_name] as Dictionary)
	if current_group == Gameplay.HackingGroups.PINK and dictionary.get("author_pink") != null:
			name = dictionary.get("author_pink")
	elif current_group == Gameplay.HackingGroups.BLUE and dictionary.get("author_blue") != null:
			name = dictionary.get("author_blue")
	return name

func _on_cancel_select_target_button_clicked():
	in_select_target_mode = false

func _on_order_processed(success: bool, selected_unit: Unit):
	if success:
		in_select_target_mode = false
		in_unit_animation_mode = true
		timeout_callback_helper.call_after_time(func callback(): 
			in_unit_animation_mode = false
			update_abilities_buttons(selected_unit), 
			StaticData.turn_animation_duration)
		tiles_tint_reset()
	
	update_selected_unit_stats(selected_unit)
	update_abilities_buttons(selected_unit)
	update_selection_indicator(selected_unit)
	
	# hack for unit stats to update
	tile_hovered.emit(last_tile_pos)

func tiles_tint_reset():
	tiles_need_tint.emit("", Vector2i(0, 0), false, false)

func _unhandled_input(event):
	if event is InputEventMouseButton && event.pressed \
		&& event.button_index == MOUSE_BUTTON_LEFT:
		#print("Mouse Click/Unclick at: ", event.position)

		var world_pos = UIHelpers.screen_pos_to_world_pos(event.position)
		#print("world pos: ", world_pos)
		
		var tile_pos = UIHelpers.world_pos_to_tile_pos(world_pos)
		print("tile_pos: ", tile_pos)
		
		last_tile_pos = tile_pos
		
		#if in_select_target_mode:
		#	_on_ability_button_highlight(order_parameters.ability_id, "test")
		#else:
		#var test_distance = UIHelpers.tile_pos_distance(Vector2i(5, 5), tile_pos)		
		#print("distance: ", test_distance)
		
		if !in_unit_animation_mode:
			if !in_select_target_mode:
				tile_clicked.emit(tile_pos)
				
				# hack for unit stats to update
				tile_hovered.emit(tile_pos)
			else:
				if order_parameters.target_type == Gameplay.TargetTypes.TILE:
					order_given.emit(order_parameters.ability_id, tile_pos)
				elif order_parameters.target_type == Gameplay.TargetTypes.UNIT:
					order_given.emit(order_parameters.ability_id, tile_pos)
		
	if event is InputEventMouseButton && event.pressed \
		&& event.button_index == MOUSE_BUTTON_RIGHT:
		in_select_target_mode = false
	elif event is InputEventMouseMotion:
		if Input.is_action_pressed("Scroll Mouse"):
			var camera = get_viewport().get_camera_3d()
			camera.global_position += Vector3(event.relative.x, 0.0, event.relative.y)
			return
		
		#print("Mouse Motion at: ", event.position)
		
		var world_pos = UIHelpers.screen_pos_to_world_pos(event.position)
		#print("world pos: ", world_pos)
		
		var tile_pos = UIHelpers.world_pos_to_tile_pos(world_pos)
		
		if !in_select_target_mode and !in_unit_animation_mode:
			tile_hovered.emit(tile_pos)
			tiles_need_tint.emit("", tile_pos)
		elif in_select_target_mode:
			tile_hovered.emit(tile_pos)
			if order_parameters.ability_id == "move":
				
				pass
			
			if order_parameters.ability_id == "reset":
				tiles_need_tint.emit(order_parameters.ability_id, tile_pos, true, true)
			elif order_parameters.ability_id == "backdoor":
				tiles_need_tint.emit(order_parameters.ability_id, tile_pos, false, true)
			else:
				tiles_need_tint.emit(order_parameters.ability_id, tile_pos)
		
func _process(delta):
	if animated_unit != null:
		update_selection_indicator(animated_unit)
	
	if !movement_path_timer.is_stopped():
		movement_path_follow.progress_ratio = (movement_path_timer.wait_time - movement_path_timer.time_left) / movement_path_timer.wait_time
		animated_unit.position = animated_unit_start_pos + movement_path_follow_node.global_position
	pass
	
func _on_timer_timeout():
	animated_unit.update_model_pos()
	in_unit_animation_mode = false
	
	#if animated_unit != null:
	#	UIHelpers.audio_event3d_loop_end(animated_unit)
	animated_unit = null
	
	animation_finished.emit()

	
