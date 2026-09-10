class_name TestCustomNode
extends CustomNode


func _init() -> void:
	id = &"test_custom_node"
	display_name = "Test Custom Node"
	description = "A simple custom node used to verify the CustomNode system."


func execute(parser: DialogueParser) -> DialogueResult:
	print("TestCustomNode executed!")

	return DialogueResult.new(DialogueResult.Action.CONTINUE)
