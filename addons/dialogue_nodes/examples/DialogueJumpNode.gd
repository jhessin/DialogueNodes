@tool
extends GraphNode

signal modified

@export var dialogue_data: DialogueData:
	set(value):
		dialogue_data = value
		if is_node_ready():
			_updating_picker = true
			resource_picker.edited_resource = value
			_updating_picker = false

@export var start_id := 'START':
	set(value):
		start_id = value
		if is_node_ready() and start_id_edit.text != value:
			start_id_edit.text = value

@onready var resource_picker: EditorResourcePicker = %ResourcePicker
@onready var start_id_edit: LineEdit = %StartId

var undo_redo: EditorUndoRedoManager
var last_start_id := 'START'
var _updating_picker := false


func _ready() -> void:
	resource_picker.base_type = 'DialogueData'
	resource_picker.edited_resource = dialogue_data
	resource_picker.resource_changed.connect(_on_resource_changed)
	start_id_edit.text = start_id
	last_start_id = start_id
	start_id_edit.text_changed.connect(_on_start_id_changed)


func _to_dict(graph: GraphEdit) -> Dictionary:
	var connections := graph.get_connections(name)
	var file_path := ''
	if dialogue_data:
		file_path = dialogue_data.resource_path

	return {
		'file_path': file_path,
		'start_id': start_id,
		'link': connections[0]['to_node'] if connections.size() > 0 else 'END',
		'size': size,
	}


func _from_dict(dict: Dictionary) -> Array[String]:
	var file_path: String = dict.get('file_path', '')
	if file_path != '':
		var resource := ResourceLoader.load(file_path, '', ResourceLoader.CACHE_MODE_IGNORE)
		if resource is DialogueData:
			dialogue_data = resource

	start_id = str(dict.get('start_id', 'START'))
	last_start_id = start_id

	if dict.has('size'):
		var new_size: Vector2
		if dict['size'] is Vector2:
			new_size = dict['size']
		else:
			new_size = Vector2(float(dict['size']['x']), float(dict['size']['y']))
		size = new_size

	return [str(dict.get('link', 'END'))]


func set_start_id(value: String) -> void:
	start_id = value
	if start_id_edit.text != value:
		start_id_edit.text = value


func _on_resource_changed(resource: Resource) -> void:
	if _updating_picker:
		return

	var new_resource := resource as DialogueData
	if new_resource == dialogue_data:
		return

	if not undo_redo:
		dialogue_data = new_resource
		modified.emit()
		return

	undo_redo.create_action('Set dialogue resource')
	undo_redo.add_do_property(self, 'dialogue_data', new_resource)
	undo_redo.add_do_method(self, 'emit_signal', 'modified')
	undo_redo.add_undo_property(self, 'dialogue_data', dialogue_data)
	undo_redo.add_undo_method(self, 'emit_signal', 'modified')
	undo_redo.commit_action()


func _on_start_id_changed(value: String) -> void:
	if value == start_id:
		return

	if not undo_redo:
		start_id = value
		last_start_id = value
		modified.emit()
		return

	undo_redo.create_action('Set dialogue start ID')
	undo_redo.add_do_method(self, 'set_start_id', value)
	undo_redo.add_do_method(self, 'emit_signal', 'modified')
	undo_redo.add_undo_method(self, 'set_start_id', last_start_id)
	undo_redo.add_undo_method(self, 'emit_signal', 'modified')
	undo_redo.commit_action()
	last_start_id = value
