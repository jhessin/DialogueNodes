@tool
class_name CustomNode
extends Resource

const CUSTOM_NODE_ID_OFFSET: int = 1000

## The id of the node
@export var id: StringName = &''
@export var display_name: String = ''
@export var description: String = ''

## The scene that represents the node in the Graph
@export var scene: PackedScene

## This holds the menu_index of the node
var menu_index: int = CUSTOM_NODE_ID_OFFSET


## This is the processor that runs when the node is executed.
func execute(parser: DialogueParser) -> DialogueResult:
	return DialogueResult.new(DialogueResult.Action.CONTINUE)
