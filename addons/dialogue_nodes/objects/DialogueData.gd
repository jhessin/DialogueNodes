## Data for processing dialogue through a [param DialogueParser].
@tool
@icon('res://addons/dialogue_nodes/icons/Dialogue.svg')
class_name DialogueData
extends Resource

## Contains the start IDs as keys and their respective node name as values.
## Example: { "START": "0_1" }
@export var starts: Dictionary = { }
## Contains all the data for each node in a dialogue graph with their node names as keys.[br]
## Example: [code]{ "0_1": { "link": "1_1", "offset": Vector2(0, 0), "start_id": "START" } }[/code]
@export var nodes: Dictionary = { }
## Contains the variable data including the variable name, data type and initial value.[br]
## Example: [code]{ "COINS": { "type": TYPE_INT, "value": 10 } }[/code]
@export var variables: Dictionary = { }
## Contains the node names of all the nodes not connected to a dialogue tree
@export var strays: Array[String] = []
## Contains the characters available to dialogue nodes.
@export var characters: CharacterList
## Contains the custom nodes to be used in this dialogue if any.
@export var custom_node_scenes: Array[PackedScene] = []

var custom_nodes: Dictionary[StringName, CustomNode]:
	get:
		var result: Dictionary[StringName, CustomNode] = { }

		for scene: PackedScene in custom_node_scenes:
			if scene == null:
				continue

			var instance: Node = scene.instantiate()

			if instance is not CustomGraphNode:
				instance.queue_free()
				continue

			var custom_graph_node: CustomGraphNode = instance

			if custom_graph_node.custom_node == null:
				instance.queue_free()
				continue

			result[custom_graph_node.custom_node.id] = custom_graph_node.custom_node
			instance.queue_free()

		return result

var scene_dict: Dictionary[StringName, PackedScene]:
	get:
		var result: Dictionary[StringName, PackedScene] = { }

		for scene: PackedScene in custom_node_scenes:
			if scene == null:
				continue

			var instance: Node = scene.instantiate()

			if instance is not CustomGraphNode:
				instance.queue_free()
				continue

			var custom_node: CustomNode = instance.custom_node

			if custom_node == null:
				instance.queue_free()
				continue

			result[custom_node.id] = scene
			instance.queue_free()

		return result
