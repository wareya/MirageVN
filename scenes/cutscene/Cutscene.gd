class_name Cutscene
extends Node2D


func _cutscene():
    if Engine.editor_hint:
        return
    return Manager.parse_cutscene(cutscene)
export var cutscene : GDScript = preload("res://cutscenes/Dummy.gd")
onready var cutscene_node : Node = _cutscene()

func _ready():
    Manager.call_cutscene(cutscene_node, "cutscene")
