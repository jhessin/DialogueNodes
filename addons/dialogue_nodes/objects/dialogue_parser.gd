@tool
## A parser for reading and processing DialogueData resources.
@icon("res://addons/dialogue_nodes/icons/DialogueParser.svg")
class_name DialogueParser
extends Node

signal dialogue_started(id: String)
signal dialogue_processed(speaker: Variant, dialogue: String, options: Array[String])
signal option_selected(idx: int)
signal dialogue_signal(value: String)
signal variable_changed(variable_name: String, value: Variant)
signal dialogue_ended

@export var data: DialogueData
@export var skip_options_condition_checks := false

var variables: Dictionary = {}
var characters: Array[Character] = []

var _running := false
var _option_links: Array[String] = []
var _data_stack: Array[DialogueData] = []
var _character_stack: Array[Array[Character]] = []
var _resume_stack: Array[String] = []


func load_data(path: String) -> void:
	if not path.ends_with(".tres"):
		return
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded is DialogueData:
		set_data(loaded)


func set_data(new_data: DialogueData) -> void:
	stop(false)
	data = new_data
	_data_stack.clear()
	_character_stack.clear()
	_resume_stack.clear()
	_option_links.clear()
	variables.clear()
	characters.clear()

	if data == null:
		return

	for variable_name: String in data.variables:
		var entry: Dictionary = data.variables[variable_name]
		variables[variable_name] = entry.get("value")

	if data.characters != null:
		characters.assign(data.characters.characters)


func start(start_id: String) -> void:
	if data == null:
		push_error("No dialogue data loaded.")
		return
	if not data.starts.has(start_id):
		push_error("Start ID '%s' not found in dialogue data." % start_id)
		return

	_running = true
	if _resume_stack.is_empty():
		dialogue_started.emit(start_id)
	_proceed(String(data.starts[start_id]))


func stop(emit_signal := true) -> void:
	var was_running := _running
	_running = false
	_option_links.clear()
	_data_stack.clear()
	_character_stack.clear()
	_resume_stack.clear()
	if emit_signal and was_running:
		dialogue_ended.emit()


func select_option(idx: int) -> void:
	if not _running:
		return
	if idx < 0 or idx >= _option_links.size():
		push_error("Option index %d is not selectable." % idx)
		return

	option_selected.emit(idx)
	_proceed(_option_links[idx])


func is_running() -> bool:
	return _running


func _proceed(node_name: String) -> void:
	if not _running:
		return

	if node_name == "END":
		if not _resume_stack.is_empty():
			data = _data_stack.pop_back()
			characters = _character_stack.pop_back()
			_proceed(_resume_stack.pop_back())
		else:
			stop()
		return

	if data == null or not data.nodes.has(node_name):
		push_error("Dialogue node '%s' does not exist." % node_name)
		stop()
		return

	var node_data: Dictionary = data.nodes[node_name]
	if node_data.has("custom_node_id"):
		_process_custom(node_data)
		return

	var node_type := _node_type_id(node_name)
	match node_type:
		0:
			_proceed(String(node_data.get("link", "END")))
		1:
			_process_dialogue(node_data)
		2:
			pass
		3:
			dialogue_signal.emit(String(node_data.get("signal_value", node_data.get("signalValue", ""))))
			_proceed(String(node_data.get("link", "END")))
		4:
			_process_set(node_data)
		5:
			_process_condition(node_data)
		6:
			_process_nest(node_data)
		7:
			_process_fork(node_data)
		_:
			push_error("Unknown dialogue node type for '%s'." % node_name)
			stop()


func _node_type_id(node_name: String) -> int:
	var separator := node_name.find("_")
	if separator <= 0:
		return -1
	return node_name.substr(0, separator).to_int()


func _process_dialogue(node_data: Dictionary) -> void:
	var speaker: Variant = ""
	var speaker_value: Variant = node_data.get("speaker", "")
	if speaker_value is String:
		speaker = speaker_value
	elif speaker_value is int and speaker_value >= 0 and speaker_value < characters.size():
		speaker = characters[speaker_value]

	var dialogue_text := tr(_parse_variables(String(node_data.get("dialogue", ""))))
	_option_links.clear()
	var option_texts: Array[String] = []

	for option_value: Variant in node_data.get("options", {}).values():
		var option: Dictionary = option_value
		var conditions: Array = option.get("condition", [])
		if conditions.is_empty() or _check_condition(conditions) or skip_options_condition_checks:
			option_texts.append(_parse_variables(String(option.get("text", ""))))
			_option_links.append(String(option.get("link", "END")))

	if option_texts.is_empty():
		option_texts.append("")
		_option_links.append("END")

	dialogue_processed.emit(speaker, dialogue_text, option_texts)


func _process_custom(node_data: Dictionary) -> void:
	var custom_node_id: StringName = StringName(node_data.get("custom_node_id", ""))
	var custom_node := data.get_custom_node(custom_node_id)
	if custom_node == null:
		push_error("Custom node '%s' is not defined by DialogueData." % custom_node_id)
		_proceed("END")
		return

	var result := custom_node.execute(data, self)
	if result == null:
		result = DialogueResult.continue_dialogue()

	match result.action:
		DialogueResult.Action.CONTINUE:
			_proceed(String(node_data.get("link", "END")))
		DialogueResult.Action.WAIT:
			return
		DialogueResult.Action.END:
			_proceed("END")
		DialogueResult.Action.JUMP:
			_proceed(String(result.target))


func _process_set(node_data: Dictionary) -> void:
	var variable_name := String(node_data.get("variable", ""))
	if not variables.has(variable_name):
		push_error("Variable '%s' not found in DialogueData." % variable_name)
		_proceed(String(node_data.get("link", "END")))
		return

	var current: Variant = variables[variable_name]
	var value: Variant = node_data.get("value")
	var operator := int(node_data.get("type", 0))

	match typeof(current):
		TYPE_STRING:
			value = str(value)
			if operator > 2:
				push_error("Invalid operator for String.")
				_proceed(String(node_data.get("link", "END")))
				return
		TYPE_INT:
			value = int(value)
		TYPE_FLOAT:
			value = float(value)
		TYPE_BOOL:
			value = value == "true" if value is String else bool(value)
			if operator > 0:
				push_error("Invalid operator for Bool.")
				_proceed(String(node_data.get("link", "END")))
				return

	match operator:
		0:
			current = value
		1:
			current += value
		2:
			current -= value
		3:
			current *= value
		4:
			current /= value
		_:
			push_error("Invalid variable operator: %d" % operator)
			_proceed(String(node_data.get("link", "END")))
			return

	variables[variable_name] = current
	if data.variables.has(variable_name):
		var entry: Dictionary = data.variables[variable_name]
		entry["value"] = current
		data.variables[variable_name] = entry
		data.emit_changed()

	variable_changed.emit(variable_name, current)
	_proceed(String(node_data.get("link", "END")))


func _process_condition(node_data: Dictionary) -> void:
	var result := _check_condition(node_data.get("condition", []))
	_proceed(String(node_data.get("true" if result else "false", "END")))


func _process_fork(node_data: Dictionary) -> void:
	var next_node := String(node_data.get("default", "END"))
	for fork_value: Variant in node_data.get("forks", {}).values():
		var fork: Dictionary = fork_value
		if _check_condition(fork.get("condition", [])):
			next_node = String(fork.get("link", "END"))
			break
	_proceed(next_node)


func _process_nest(node_data: Dictionary) -> void:
	var file_path := String(node_data.get("file_path", ""))
	if not file_path.ends_with(".tres"):
		push_error("Invalid nested dialogue file: %s" % file_path)
		_proceed(String(node_data.get("link", "END")))
		return

	var loaded := ResourceLoader.load(file_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not loaded is DialogueData:
		push_error("Nested dialogue must be a DialogueData resource: %s" % file_path)
		_proceed(String(node_data.get("link", "END")))
		return

	_data_stack.push_back(data)
	_character_stack.push_back(characters.duplicate())
	_resume_stack.push_back(String(node_data.get("link", "END")))

	data = loaded
	for variable_name: String in data.variables:
		if not variables.has(variable_name):
			variables[variable_name] = data.variables[variable_name].get("value")

	characters.clear()
	if data.characters != null:
		characters.assign(data.characters.characters)

	start(String(node_data.get("start_id", "")))


func _check_condition(conditions: Array) -> bool:
	var result := true
	var combiner := 1

	for condition: Dictionary in conditions:
		if condition.is_empty():
			continue

		var value1: Variant = condition.get("value1", "")
		var value2: Variant = condition.get("value2", "")
		if value1 is String and value1.contains("{{"):
			value1 = _parse_variables(value1)
		if value2 is String and value2.contains("{{"):
			value2 = _parse_variables(value2)

		var current_result := false
		match int(condition.get("operator", -1)):
			0:
				current_result = value1 == value2
			1:
				current_result = value1 != value2
			2:
				current_result = value1 > value2
			3:
				current_result = value1 < value2
			4:
				current_result = value1 >= value2
			5:
				current_result = value1 <= value2

		result = result or current_result if combiner == 0 else result and current_result
		combiner = int(condition.get("combiner", combiner))

	return result


func _parse_variables(value: String) -> String:
	if value.count("{{") != value.count("}}"):
		push_error("Failed to parse variables: unmatched braces.")
		return value

	var formatted: Dictionary = {}
	for key: String in variables:
		var current: Variant = variables[key]
		formatted[key] = "%0.2f" % current if current is float else current

	var regex := RegEx.new()
	regex.compile("{{([^{}]+)}}")
	for match_result in regex.search_all(value):
		var key := match_result.get_string(1)
		if not variables.has(key):
			push_error("Unknown variable '%s'." % key)
			formatted[key] = ""

	return value.format(formatted, "{{_}}")


func _update_wait_tags(node: RichTextLabel, value: String) -> String:
	if value.is_empty():
		value = " "
	if not value.begins_with("[wait"):
		value = "[wait]" + value + "[/wait]"

	node.text = value.replace("\n", " ").replace("[br]", "\n")
	var text_length := node.get_parsed_text().length() - value.count("\n")
	var index := 0
	var character_index := -1
	var character_count := 0
	var waits: Array[Dictionary] = []

	while index < value.length():
		if value[index] == "[":
			var open_end := value.findn("]", index)
			var wait_start := value.findn("[wait", index)
			var wait_end := value.findn("[/wait]", index)
			if wait_start == index:
				waits.push_back({"at": open_end, "start": character_index + 1})
				index = open_end + 1
				continue
			if wait_end == index and not waits.is_empty():
				var start_data: Dictionary = waits.pop_back()
				var insert_text := " start=%d last=%d length=%d" % [
					start_data.get("start", 0),
					start_data.get("last", character_count - 1),
					text_length,
				]
				value = value.insert(start_data["at"], insert_text)
				index = wait_end + insert_text.length() + 7
				continue
			index = open_end + 1
			continue

		index += 1
		character_index += 1
		character_count += 1
		if not waits.is_empty():
			waits[-1]["last"] = character_count - 1

	while not waits.is_empty():
		var start_data: Dictionary = waits.pop_back()
		var insert_text := " start=%d last=%d length=%d" % [
			start_data.get("start", 0),
			character_count - 1,
			text_length,
		]
		value = value.insert(start_data["at"], insert_text)

	return value
