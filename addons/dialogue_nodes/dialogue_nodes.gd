@tool
class_name DialogueNodes
extends Object

var _registered_nodes: Dictionary[StringName, PackedScene] = { }
var _registered_processors: Dictionary[StringName, Callable] = { }


func register_node(id: StringName, scene: PackedScene) -> bool:
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
	return true


func unregister_node(id: StringName) -> bool:
	if not _registered_nodes.has(id):
		return false

	_registered_nodes.erase(id)
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

	if not processor.is_valid():
		push_error('DialogueNodes: Cannot register "%s% with an invalid processor.' % id)
		return false

	if _registered_processors.has(id):
		push_error('DialogueNodes: processor "%s" is already registered.' % id)
		return false

	_registered_processors[id] = processor
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
