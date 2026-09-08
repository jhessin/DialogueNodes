@tool
extends Node

const NODE_ID: StringName = &"dialogue_jump"
const NODE_SCENE_PATH := 'res://addons/dialogue_nodes/examples/DialogueJumpNode.tscn'

var _registered := false


func _ready() -> void:
	if Engine.is_editor_hint():
		get_tree().node_added.connect(_on_node_added)
	_try_register()


func _exit_tree() -> void:
	if is_instance_valid(DialogueNodes):
		DialogueNodes.unregister_node(NODE_ID)


func _on_node_added(node: Node) -> void:
	if node.name == 'DialogueNodes':
		_try_register.call_deferred()


func _try_register() -> void:
	if _registered or not is_instance_valid(DialogueNodes):
		return

	if Engine.is_editor_hint():
		var node_scene := load(NODE_SCENE_PATH) as PackedScene
		if node_scene == null:
			push_error('ExampleNodeRegistry: Failed to load %s' % NODE_SCENE_PATH)
			return
		if DialogueNodes.register_node(NODE_ID, node_scene, _process_dialogue_jump):
			_registered = true
			_refresh_graph_menu()
		return

	_registered = DialogueNodes.register_processor(NODE_ID, _process_dialogue_jump)


func _refresh_graph_menu() -> void:
	if not Engine.is_editor_hint():
		return

	var main_screen := EditorInterface.get_editor_main_screen()
	for graph in main_screen.find_children('*', 'GraphEdit', true, false):
		if graph.has_method('refresh_node_menu'):
			graph.refresh_node_menu()


func _process_dialogue_jump(node_data: Dictionary, parser: DialogueParser) -> void:
	var file_path := str(node_data.get('file_path', ''))
	var start_id := str(node_data.get('start_id', 'START'))
	var fallback_link := str(node_data.get('link', 'END'))

	if file_path.is_empty():
		printerr('Dialogue Jump: No DialogueData resource selected.')
		parser.proceed(fallback_link)
		return

	var loaded_data := ResourceLoader.load(file_path, '', ResourceLoader.CACHE_MODE_IGNORE)
	if not loaded_data is DialogueData:
		printerr('Dialogue Jump: Invalid DialogueData resource: ', file_path)
		parser.proceed(fallback_link)
		return

	if not loaded_data.starts.has(start_id):
		printerr('Dialogue Jump: Start ID "%s" was not found in %s.' % [start_id, file_path])
		parser.proceed(fallback_link)
		return

	parser.set_data(loaded_data)
	parser.start(start_id)
