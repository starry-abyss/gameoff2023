extends CanvasLayer


const CAMERA_ROTATE_SPEED = 1
const MAP_SIZE = Vector2(5, 5)

@onready var viewport_container = $Node3D/SubViewportContainer
@onready var viewport = $Node3D/SubViewportContainer/SubViewport
@onready var main_menu = $MainMenu
@onready var options_menu = $OptionsMenu
@onready var tile_container = $Node3D/TileContainer
@onready var camera_container = $Node3D/SubViewportContainer/SubViewport/CameraContainer
@onready var timer = $Timer
@onready var glowing_outline_shader: VisualShader = preload("res://shaders/glowing_outline_shader.tres")
@onready var unit_container = $Node3D/UnitContainer

enum UnitTypes { CENTRAL_NODE, TOWER_NODE, WORM, TROJAN, VIRUS }
enum HackingGroups { PINK, BLUE, NEUTRAL }

var tiles = []
var units = []


func _ready():
	tiles.resize(MAP_SIZE.x * MAP_SIZE.y)
	
	main_menu.go_to_options_menu.connect(_go_to_options_menu)
	options_menu.connect("on_back_pressed", _go_to_main_menu)
	
	get_tree().set_auto_accept_quit(false)
	
	for button in find_children("", "Button"):
		button.mouse_entered.connect(_on_button_highlight)
	
	for x in range(MAP_SIZE.x):
		for y in range(MAP_SIZE.y):
			add_tile(Vector2i(x, y))
			
	_retint_tiles()
	_generate_random_unit()
	
	#for tile in tiles:
		#var material = ShaderMaterial.new()
		#material.shader = glowing_outline_shader
		#var mesh_instances = tile.find_children("", "MeshInstance3D")
		#for mi in mesh_instances:
			#mi.material_override = material
	

func _process(delta):
	viewport.size = viewport_container.size
	
	camera_container.rotate_y(CAMERA_ROTATE_SPEED * delta)

	
func _generate_random_unit():
	for unit in unit_container.get_children():
		unit.queue_free()
	units = []
	
	for x in range(MAP_SIZE.x):
		for y in range(MAP_SIZE.y):
			var tile_pos = Vector2i(x, y)
			var random = randf_range(0, 1)
			if random > 0.9:
				spawn_unit(tile_pos, randi_range(0, 4), HackingGroups.BLUE)
			elif random < 0.1:
				spawn_unit(tile_pos, randi_range(0, 4), HackingGroups.PINK)
		
	

func spawn_unit(tile_pos: Vector2i, type: UnitTypes, group: HackingGroups):
	var unit = preload("res://scenes/unit.tscn").instantiate()
	unit.type = type
	unit.group = group
	unit.tile_pos = tile_pos
	units.append(unit)
	unit.update_model_pos()
	unit_container.add_child(unit)
	
	var tile = tiles[tile_pos_to_tile_index(tile_pos)]
	if tile != null:
		tiles[tile_pos_to_tile_index(tile_pos)].group = group
	

func _on_button_highlight():
	UIHelpers.audio_event("Ui/Ui_Highlight")


func add_tile(tile_pos: Vector2i):
	var tile = preload("res://art/tile.tscn").instantiate()
	tiles.append(tile)
	tile_container.add_child(tile)
	var pos = UIHelpers.tile_pos_to_world_pos(tile_pos)
	tile.transform.origin = Vector3(pos.x, 0.0, pos.y)
	tile.set_script(preload("res://scripts/tile.gd"))
	tile._on_ready()


func _go_to_main_menu():
	options_menu.visible = false
	main_menu.visible = true
	
	UIHelpers.audio_event("Ui/Ui_Back")
	

func _go_to_options_menu():
	main_menu.visible = false
	options_menu.visible = true
	
	UIHelpers.audio_event("Ui/Ui_Accept")


func _on_timer_timeout():
	_retint_tiles()
	_generate_random_unit()
	

func _retint_tiles():
	for tile in tiles:
		if tile != null:
			tile.group = randi_range(0, 1)


func tile_pos_to_tile_index(tile_pos: Vector2i) -> int:
	return tile_pos.y * MAP_SIZE.x + tile_pos.x
