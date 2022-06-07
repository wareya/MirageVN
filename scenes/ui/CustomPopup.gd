extends Control


var button_ok = null
var button_cancel = null
var button_close = null

# warning-ignore:unused_signal
signal pressed_ok
signal pressed_cancel
# warning-ignore:unused_signal
signal pressed_close

func set_title(new : String):
    $Panel/Title.text = new

func set_text(new : String):
    $Panel/LabelScroller/LabelHolder/Label.bbcode_text = "[center]%s[/center]" % [new]

func set_ok_text(new : String):
    button_ok.text = new

func set_cancel_text(new : String):
    button_cancel.text = new

func emit_cancel():
    emit_signal("pressed_cancel")

func set_closable(close_is_ok : bool = false):
    button_close = find_node("Close")
    button_close.visible = true
    button_close.connect("pressed", self, "emit_cancel")
    if close_is_ok:
        button_close.connect("pressed", self, "emit_signal", ["pressed_ok"])
    else:
        button_close.connect("pressed", self, "emit_signal", ["pressed_cancel"])

func _unhandled_input(event : InputEvent):
    if event.is_action_pressed("ui_cancel"):
        emit_cancel()

func _ready():
    button_ok     = find_node("OK")
    button_cancel = find_node("Cancel")
    if !OS.is_ok_left_and_cancel_right():
        var button_parent = button_ok.get_parent()
        var ok_index     = button_parent.get_children().find(button_ok)
        var cancel_index = button_parent.get_children().find(button_ok)
        button_parent.move_child(button_ok, cancel_index+1)
        button_parent.move_child(button_cancel, ok_index)
    
    button_ok    .connect("pressed", self, "emit_signal", ["pressed_ok"])
    button_cancel.connect("pressed", self, "emit_signal", ["pressed_cancel"])
    
    button_cancel.grab_focus()

func _process(_delta):
    if button_close.visible and Input.is_action_just_pressed("m2"):
        button_close.emit_signal("pressed")
