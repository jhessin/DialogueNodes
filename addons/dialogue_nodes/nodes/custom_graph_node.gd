@tool
class_name CustomGraphNode
extends GraphNode

signal modified

@export var custom_node: CustomNode

var undo_redo: EditorUndoRedoManager
var last_size := size
var last_text := ''


func _to_dict(graph: GraphEdit) -> Dictionary:
	var result := {
		"custom_node_id": custom_node.id if custom_node else &"",
		"link": "END",
		"size": size,
	}
	var connections: Array[Dictionary] = graph.get_connections(name)
	if not connections.is_empty():
		result["link"] = connections[0]["to_node"]
	return result


func _from_dict(_dict: Dictionary) -> Array[String]:
	return []


func _on_modified() -> void:
	modified.emit()
