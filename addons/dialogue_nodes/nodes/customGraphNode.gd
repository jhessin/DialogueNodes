@tool
extends GraphNode

signal modified

@export var custom_node: CustomNode


func _to_dict(_graph) -> Dictionary:
	return { 'custom_node_id': custom_node.id if custom_node else &'' }


func _from_dict(_dict: Dictionary) -> Array[String]:
	return []


func _on_modified() -> void:
	modified.emit()
