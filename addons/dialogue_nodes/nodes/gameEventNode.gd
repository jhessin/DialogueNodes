@tool
extends GraphNode

signal modified

var undo_redo: EditorUndoRedoManager
var last_value := ''

@onready var value := $EventValue
@onready var timer := $Timer


func set_value(new_value: String) -> void:
	if value.text != new_value:
		value.text = new_value
	last_value = new_value


func _to_dict(graph: GraphEdit) -> Dictionary:
	var dict := { }
	var connections: Array = graph.get_connections(name)

	dict['eventValue'] = value.text
	dict['link'] = connections[0]['to_node'] if connections.size() > 0 else 'END'

	return dict


func _from_dict(dict: Dictionary) -> Array[String]:
	value.text = dict['eventValue']
	last_value = value.text

	return [dict['link']]


func _on_event_value_changed(_new_text) -> void:
	timer.stop()
	timer.start()


func _on_timer_timeout() -> void:
	if not undo_redo:
		return

	undo_redo.create_action('Set event value')
	undo_redo.add_do_method(self, 'set_value', value.text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_value', last_value)
	undo_redo.commit_action()


func _on_modified() -> void:
	modified.emit()
