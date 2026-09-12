class_name DialogueResult
extends RefCounted

enum Action {
	CONTINUE,
	WAIT,
	END,
	JUMP,
}

var action: Action
var target: StringName


static func continue_dialogue() -> DialogueResult:
	return DialogueResult.new(Action.CONTINUE)


static func wait() -> DialogueResult:
	return DialogueResult.new(Action.WAIT)


static func end() -> DialogueResult:
	return DialogueResult.new(Action.END)


static func jump_to(name: StringName) -> DialogueResult:
	return DialogueResult.new(Action.JUMP, name)


func _init(_action: Action, _target: StringName = &"") -> void:
	action = _action
	target = _target
