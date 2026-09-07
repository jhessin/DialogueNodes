@tool
class_name DialogueNodes
extends Object

var _registered_nodes: Dictionary = { }


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
	return _registered_nodes.keys()
