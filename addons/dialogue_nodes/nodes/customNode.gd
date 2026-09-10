class_name CustomNode
extends Resource

## The id of the node
@export var id: StringName = &''
@export var display_name: String = ''
@export var description: String = ''

## The scene that represents the node in the Graph
@export var scene: PackedScene


## This is the processor that runs when the node is executed.
func execute(context: DialogueData, parser: DialogueParser) -> DialogueResult:
	return DialogueResult.new(DialogueResult.Action.CONTINUE)
