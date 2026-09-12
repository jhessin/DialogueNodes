@tool
class_name CustomNode
extends Resource

## The id of the node.
@export var id: StringName = &''

## The name displayed in the Add Node menu.
@export var display_name: String = ''

## Description of what the node does.
@export_multiline var description: String = ''


## This is the processor that runs when the node is executed.
func execute(parser: DialogueParser) -> DialogueResult:
	return DialogueResult.new(DialogueResult.Action.CONTINUE)
