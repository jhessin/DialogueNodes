@tool
class_name CustomNode
extends Resource

## Stable identifier used by serialized dialogue nodes.
@export var id: StringName = &""

## Name shown in the editor's Add Node menu.
@export var display_name: String = ""

## Description shown to users in the editor.
@export_multiline var description: String = ""

## Scene used to represent this custom node in the graph editor.
@export var scene: PackedScene


## Executes this node against the current DialogueData.
##
## Override this method in a derived CustomNode to implement behavior.
func execute(context: Resource, parser: Node) -> DialogueResult:
	return DialogueResult.continue_dialogue()
