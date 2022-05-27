tool
extends TextureRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    material = material.duplicate()
    if Engine.editor_hint:
        return
    fadeamount = 0.0
    invert = false
    material.set_shader_param("fadeamount", 0.0)
    material.set_shader_param("invert", false)
    material.set_shader_param("contrast", contrast)
    pass # Replace with function body.

export(float, 0.0, 1.0) var fadeamount : float = 0.0
export var invert : bool = false
export(float, 0.0001, 8.0) var contrast : float = 1.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    #if Engine.editor_hint:
    material.set_shader_param("fadeamount", fadeamount)
    material.set_shader_param("invert", invert)
    material.set_shader_param("contrast", contrast)
