extends Control


var button_ok = null
var button_cancel = null
var button_close = null

signal pressed_ok
signal pressed_cancel

func set_title(new : String):
    $Panel/Title.text = new

func set_text(new : String):
    $Panel/LabelScroller/LabelHolder/Label.bbcode_text = "[center]%s[/center]" % [new]

func set_ok_text(new : String):
    button_ok.text = new

func set_cancel_text(new : String):
    button_cancel.text = new

func emit_ok():
    emit_signal("pressed_ok", $Panel/TextEdit.text)
    hide()
    pass

func emit_cancel():
    emit_signal("pressed_cancel")
    hide()
    pass

func set_closable(close_is_ok : bool = false):
    button_close = find_node("Close")
    button_close.visible = true
    if close_is_ok:
        button_close.connect("pressed", self, "emit_ok")
    else:
        button_close.connect("pressed", self, "emit_cancel")

func _input(_event : InputEvent):
    if not _event is InputEventKey:
        return
    if !$Panel/TextEdit.has_focus():
        return
    var event : InputEventKey = _event
    if !event.pressed:
        return
    if event.control and event.scancode == KEY_ENTER:
        button_ok.emit_signal("pressed")
        get_tree().set_input_as_handled()
    if event.scancode == KEY_TAB:
        if !event.shift:
            $Panel/Buttons/OK.grab_focus()
            get_tree().set_input_as_handled()
        else:
            $Panel/Close.grab_focus()
            get_tree().set_input_as_handled()

func _unhandled_input(event : InputEvent):
    if event.is_action_pressed("ui_cancel"):
        emit_cancel()
    pass

func open(panel):
    just_opened = true
    show()
    $Panel/TextEdit.grab_focus()
    if "memo" in panel.data:
        $Panel/TextEdit.text = panel.data["memo"]

func _ready():
    set_closable()
    
    button_ok     = find_node("OK")
    button_cancel = find_node("Cancel")
    if !OS.is_ok_left_and_cancel_right():
        var button_parent = button_ok.get_parent()
        var ok_index     = button_parent.get_children().find(button_ok)
        var cancel_index = button_parent.get_children().find(button_ok)
        button_parent.move_child(button_ok, cancel_index+1)
        button_parent.move_child(button_cancel, ok_index)
    
    button_ok    .connect("pressed", self, "emit_ok")
    button_cancel.connect("pressed", self, "emit_cancel")

var just_opened = false
func _process(_delta):
    if !just_opened and button_close.visible and Input.is_action_just_pressed("m2"):
        button_close.emit_signal("pressed")
    just_opened = false
