@tool
@icon("res://addons/dialogue_nodes/icons/Dialogue.svg")
class_name DialogueData
extends Resource

## The complete serialized state of one dialogue asset.
##
## DialogueData is the single source of truth shared by the editor and runtime.
@export_group("Graph")
@export var starts: Dictionary = {}
@export var nodes: Dictionary = {}
@export var strays: Array[String] = []

@export_group("Variables")
@export var variables: Dictionary = {}

@export_group("Characters")
@export var characters: CharacterList

@export_group("Custom Nodes")
## Custom node definitions available to this dialogue.
@export var custom_nodes: Array[CustomNode] = []


func get_custom_node(id: StringName) -> CustomNode:
	for custom_node: CustomNode in custom_nodes:
		if custom_node != null and custom_node.id == id:
			return custom_node
	return null


func get_custom_node_map() -> Dictionary[StringName, CustomNode]:
	var result: Dictionary[StringName, CustomNode] = {}
	for custom_node: CustomNode in custom_nodes:
		if custom_node != null and not custom_node.id.is_empty():
			result[custom_node.id] = custom_node
	return result


func clear_graph() -> void:
	starts.clear()
	nodes.clear()
	strays.clear()


func ensure_characters() -> void:
	if characters == null:
		characters = CharacterList.new()
