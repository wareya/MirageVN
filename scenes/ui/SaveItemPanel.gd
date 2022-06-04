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
var trash_created = false

signal pressed
func _gui_input(_event : InputEvent):
    if _event is InputEventMouseButton:
        var event : InputEventMouseButton = _event
        if event.button_index == 1:
            if event.pressed:
                pressed_down = true
            else:
                if highlighted and pressed_down:
                    emit_signal("pressed")
                pressed_down = false
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

class Trash extends Sprite:
    var panel : Control = null
    func _init(_panel : Control):
        texture = preload("res://art/ui/graphic design is my passion 2.png")
        centered = true
        panel = _panel
    
    var last_global_position = Vector2()
    func _ready():
        last_global_position = global_position
    
    func _process(delta):
        last_global_position = global_position
        global_position = get_global_mouse_position()
        if last_global_position == Vector2():
            last_global_position = global_position
        
        var motion = (global_position - last_global_position) / max(0.0001, delta)
        
        #rotation_degrees = move_toward(rotation_degrees, motion.x*0.04, delta*100)
        rotation_degrees = lerp(rotation_degrees, motion.x*0.1, 1.0-pow(0.01, delta))
        
        Input.get_last_mouse_speed()
        
        if !Input.is_mouse_button_pressed(1):
            for trash in get_tree().get_nodes_in_group("SaveDeletePanel"):
                if trash.is_visible_in_tree() and trash.get_global_rect().has_point(global_position):
                    panel.do_delete()
            panel.trash_created = false
            queue_free()

signal delete
func do_delete():
    emit_signal("delete")

func _process(_delta):
    if !get_global_rect().has_point(get_global_mouse_position()):
        if highlighted:
            highlighted = false
            update()
        if !locked and pressed_down and !trash_created and data.size() > 0:
            get_parent().get_parent().add_child(Trash.new(self))
            trash_created = true
            pressed_down = false
    else:
        if !highlighted:
            highlighted = true
            update()

func _draw():
    if highlighted:
        draw_rect(Rect2(Vector2(), rect_size), Color.orange, false, 3.0, true)
    elif has_focus():
        draw_rect(Rect2(Vector2(), rect_size), Color(0.25, 0.5, 1.0), false, 3.0, true)
