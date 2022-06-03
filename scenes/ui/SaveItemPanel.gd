extends Panel

var fname
signal lock_changed

func lock_toggled(_locked : bool):
    locked = _locked
    emit_signal("lock_changed", _locked)

func _ready():
    focus_mode = Control.FOCUS_ALL
    $LockIcon.connect("toggled", self, "lock_toggled")
    pass

var highlighted = false

func _notification(what : int) -> void:
    match what:
        NOTIFICATION_MOUSE_ENTER:
            highlighted = true
            update()
        NOTIFICATION_MOUSE_EXIT:
            highlighted = false
            update()
        NOTIFICATION_FOCUS_ENTER:
            update()
        NOTIFICATION_FOCUS_EXIT:
            update()

var pressed_down = false

signal pressed
func _gui_input(_event : InputEvent):
    if _event is InputEventMouseButton:
        var event : InputEventMouseButton = _event
        if event.button_index == 1:
            if event.pressed:
                pressed_down = true
            else:
                pressed_down = false
                if highlighted:
                    emit_signal("pressed")
    elif _event.is_action_pressed("ui_accept"):
        emit_signal("pressed")

var locked = false
var data = {}
func set_blank():
    locked = false
    data = {}
    
    $Text.visible = false
    $DateTime.visible = false
    $Chapter.visible = false
    $Screenshot.visible = false
    $New.visible = false
    $LockIcon.visible = false
    $LockIcon.pressed = false

func set_savedata(_data : Dictionary):
    # for GUI:
    #ret["last_displayed_line"] = last_displayed_line
    #ret["time"] = OS.get_time()
    #ret["chapter_name"] = chapter_name
    #ret["chapter_number"] = chapter_number
    #ret["scene_name"] = scene_name
    #ret["scene_number"] = scene_number
    #ret["screenshot"] = Marshalls.raw_to_base64(latest_screenshot.save_png_to_buffer())
    
    locked = false
    data = _data
    
    if "screenshot" in data:
        var tex = ImageTexture.new()
        var img = Image.new()
        img.load_png_from_buffer(Marshalls.base64_to_raw(data["screenshot"]))
        tex.create_from_image(img)
        $Screenshot.texture = tex
        $Screenshot.visible = true
    else:
        $Screenshot.texture = null
        $Screenshot.visible = false
    
    var date = data["date"]
    var time = data["time"]
    
    $New.visible = false
    
    $DateTime.visible = true
    $DateTime.text = "%04d-%02d-%02d %02d:%02d:%02d" % [date.year, date.month, date.day, time.hour, time.minute, time.second]
    
    $Chapter.visible = true
    $Chapter.text = "%s-%s" % [data["chapter_number"], data["scene_number"]]
    
    $Text.bbcode_enabled = true
    $Text.bbcode_text = data["last_displayed_line"]
    $Text.visible = true
    
    $LockIcon.visible = false
    $LockIcon.pressed = false

func set_locked(whether : bool):
    $LockIcon.visible = true
    $LockIcon.pressed = whether

var number = 1
func set_number(i : int):
    number = i
    $Number.text = "%04d" % [i]

func set_new(new : bool):
    $New.visible = new

func _draw():
    if highlighted:
        draw_rect(Rect2(Vector2(), rect_size), Color.orange, false, 3.0, true)
    elif has_focus():
        draw_rect(Rect2(Vector2(), rect_size), Color(0.25, 0.5, 1.0), false, 3.0, true)
