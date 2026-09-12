@tool
class_name ExampleCustomNode
extends CustomNode


func _init() -> void:
	id = &"test_custom_node"
	display_name = "Test Custom Node"
	description = "A simple custom node used to verify the CustomNode system."


func execute(parser: DialogueParser) -> DialogueResult:
	print("ExampleCustomNode executed!")

	return DialogueResult.new(DialogueResult.Action.CONTINUE)
