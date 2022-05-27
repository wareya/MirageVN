extends TextureRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

signal bg_transition_done

func change_bg(newbg : Texture, instant : bool = false):
    if !visible:
        texture = null
    show()
    if newbg == null:
        if instant:
            print("--------BG is instant and null?????")
            texture = null
            hide()
            modulate.a = 1.0
            $BgHolder2.texture = null
            $BgHolder2.hide()
            $BgHolder2.modulate.a = 1.0
            yield(get_tree(), "idle_frame")
            emit_signal("bg_transition_done")
        else:
            print("--------BG is null, treating as null")
            $Fader.play("FadeOut")
    elif !instant:
        print("--------BG is NOT null")
        $BgHolder2.texture = newbg
        $BgHolder2.show()
        $BgHolder2.modulate.a = 0.0
        $Fader.play("Fade")
    else:
        print("--------BG is instant?????")
        texture = newbg
        modulate.a = 1.0
        yield(get_tree(), "idle_frame")
        emit_signal("bg_transition_done")

func finish_fading():
    texture = $BgHolder2.texture
    modulate.a = 1.0
    $BgHolder2.modulate.a = 0.0
    emit_signal("bg_transition_done")

func finish_fading_out():
    texture = null
    hide()
    modulate.a = 1.0
    emit_signal("bg_transition_done")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
