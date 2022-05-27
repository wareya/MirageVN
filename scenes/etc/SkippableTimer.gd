extends Node
class_name SkippableTimer

signal timeout

func _process(delta):
    if !manually_time:
        set_time -= delta
    if Input.is_action_pressed("skip") or \
       Input.is_action_just_pressed("m1") or \
       Input.is_action_just_pressed("ui_accept") or \
       Input.is_action_just_pressed("ui_cancel"):
        set_time = min(set_time, 0.075)
    if !manually_time:
        check_time()

func think(delta):
    if !manually_time:
        return
    set_time -= delta
    check_time()

var dead = false
func check_time():
    if dead:
        return
    if set_time <= 0.0:
        dead = true
        yield(Manager.get_tree(), "idle_frame")
        emit_signal("timeout")
        queue_free()

var set_time = 0.0
var manually_time = false
func _init(time : float, _manually_time = false).():
    set_time = time
    manually_time = _manually_time
    pause_mode = PAUSE_MODE_PROCESS
    Manager.get_tree().get_root().add_child(self)
