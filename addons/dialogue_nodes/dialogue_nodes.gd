@tool
extends Node

var _registered_nodes: Dictionary[StringName, PackedScene] = { }
var _registered_processors: Dictionary[StringName, Callable] = { }


func register_node(
	id: StringName,
	scene: PackedScene,
	processor: Callable = Callable(self, '_process_default'),
) -> bool:
	if id.is_empty():
		push_error("DialogueNodes: Cannot register a node with an empty ID.")
		return false

	if scene == null:
		push_error("DialogueNodes: Cannot register '%s' with a null scene." % id)
		return false

	if _registered_nodes.has(id):
		push_error("DialogueNodes: Node '%s' is already registered." % id)
		return false

	_registered_nodes[id] = scene

	if processor.is_valid():
		register_processor(id, processor)

	return true


func unregister_node(id: StringName) -> bool:
	if not _registered_nodes.has(id):
		return false

	_registered_nodes.erase(id)

	if _registered_processors.has(id):
		_registered_processors.erase(id)

	return true


func is_node_registered(id: StringName) -> bool:
	return _registered_nodes.has(id)


func get_node_scene(id: StringName) -> PackedScene:
	return _registered_nodes.get(id, null)


func get_registered_node_ids() -> Array[StringName]:
	var ids: Array[StringName] = []

	for id in _registered_nodes.keys():
		ids.append(id)

	return ids


func register_processor(id: StringName, processor: Callable) -> bool:
	if id.is_empty():
		push_error('DialogueNodes: Cannot register a processor with an empty ID.')
		return false

	if _registered_processors.has(id):
		push_error('DialogueNodes: processor "%s" is already registered.' % id)
		return false

	if processor.is_valid():
		_registered_processors[id] = processor
	else:
		_registered_processors[id] = Callable(self, '_process_default')

	return true


func unregister_processor(id: StringName) -> bool:
	if not _registered_processors.has(id):
		return false

	_registered_processors.erase(id)
	return true


func is_processor_registered(id: StringName) -> bool:
	return _registered_processors.has(id)


func get_processor(id: StringName) -> Callable:
	return _registered_processors.get(id, Callable())


func get_registered_processor_ids() -> Array[StringName]:
	var ids: Array[StringName] = []

	for id in _registered_processors.keys():
		ids.append(id)

	return ids


func _process_default(node_data: Dictionary, parser: DialogueParser) -> void:
	parser.proceed(str(node_data.get('link', 'END')))
