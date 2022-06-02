extends Node


var sounds = {
# add EmitterFactory sounds here. for example:
"startgame": preload("res://sfx/startbleep.wav"),
}


class Emitter2D extends AudioStreamPlayer2D:
    var ready = false
    var frame_counter = 0

    func _process(_delta):
        if ready and !playing:
            frame_counter += 1
        if frame_counter > 2:
            queue_free()

    func emit(parent : Node, sound, arg_position, channel):
        parent.add_child(self)
        position = arg_position
        var abs_position = global_position
        parent.remove_child(self)
        parent.get_tree().get_root().add_child(self)
        global_position = abs_position
        stream = sound
        bus = channel
        play()
        ready = true
        return self


class Emitter extends AudioStreamPlayer:
    var ready = false
    var frame_counter = 0

    func _process(_delta):
        if ready and !playing:
            frame_counter += 1
        if frame_counter > 2:
            queue_free()

    func emit(parent : Node, sound, channel):
        parent.add_child(self)
        stream = sound
        bus = channel
        volume_db = -3
        play()
        ready = true
        return self

func emit(parent, sound, arg_position = Vector2(), channel = "SFX"):
    var stream = null
    if sound in sounds:
        stream = sounds[sound]
    elif sound is AudioStream:
        stream = sound
    if parent:
        return Emitter2D.new().emit(parent, stream, arg_position, channel)
    else:
        return Emitter.new().emit(Manager, stream, channel)
