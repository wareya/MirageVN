extends CanvasLayer
class_name SaveDataManager

var mode = "save"
var save_disabled = false

var latest_saves = []
func update_latest_saves():
    var sysdata = Manager.load_sysdata()
    if "latest_saves" in sysdata:
        latest_saves = sysdata["latest_saves"]
    

func _ready():
    update_latest_saves()
    var _unused
    for button in $CategoryButtons.get_children():
        if button is BaseButton:
            _unused = (button as BaseButton).connect("pressed", self, "pressed_category_button", [button])
    for button in $PageButtons.get_children():
        if button is BaseButton:
            _unused = (button as BaseButton).connect("pressed", self, "pressed_page_button", [button])
    for panel in $Page.get_children():
        panel.connect("pressed", self, "pressed_panel", [panel])
    
    if save_disabled:
        mode = "load"
        $CategoryButtons/SaveButton.disabled = true
    
    if mode == "save":
        $Title.text = "Save"
        $CategoryButtons/SaveButton.grab_focus()
        $Background.texture = preload("res://art/ui/menubg2.png")
    else:
        $Title.text = "Load"
        $CategoryButtons/LoadButton.grab_focus()
        $Background.texture = preload("res://art/ui/menubg3.png")
    
    pagenum = 1
    set_page()

func pressed_category_button(button : BaseButton):
    for other in $CategoryButtons.get_children():
        if other is BaseButton and button != other:
            other.pressed = false
    button.pressed = true
    
    if button == $CategoryButtons/SaveButton:
        mode = "save"
    
    if button == $CategoryButtons/LoadButton:
        mode = "load"
    
    if button == $CategoryButtons/ReturnButton:
        dying = true

var save_type = "save"

func load_data(savenum : int):
    var save = File.new()
    var fname = "user://saves/%04d_%s.json" % [savenum, save_type]
    var err = save.open(fname, File.READ)
    var data = null
    if err == OK:
        var json = save.get_as_text()
        var result = JSON.parse(json)
        if result.error == OK:
            data = result.result
        else:
            pass
    else:
        pass
    save.close()
    
    return data

func save_data(savenum : int, data : Dictionary, panel):
    var dir : Directory = Directory.new()
    var _unused = dir.open("user://")
    if !dir.dir_exists("saves"):
        _unused = dir.make_dir("saves")
    
    var save = File.new()
    var fname = "user://saves/%04d_%s.json" % [savenum, save_type]
    save.open(fname, File.WRITE)
    var json = JSON.print(data, " ")
    save.store_string(json)
    save.flush()
    save.close()
    Manager.admit_latest_save(fname)
    update_latest_saves()
    
    panel.set_new(true)

const saves_per_page = 12
func set_page():
    var panels = $Page.get_children()
    if pagenum > 0:
        save_type = "save"
        var first_save = 1 + (pagenum-1)*saves_per_page
        var last_save = first_save + saves_per_page - 1
        
        for i in range(first_save, last_save + 1):
            var panel = panels[i - first_save]
            var data = load_data(i)
            if data:
                panel.set_savedata(data)
            else:
                panel.set_blank()
            panel.set_number(i)
            
            var fname = "user://saves/%04d_%s.json" % [i, save_type]
            panel.set_new(fname in latest_saves)
    else:
        save_type = "quicksave"
        for i in range(0, saves_per_page):
            var panel = panels[i]
            var data = load_data(i)
            if data:
                panel.set_savedata(data)
            else:
                panel.set_blank()
            panel.set_number(i)
            
            var fname = "user://saves/%04d_%s.json" % [i, save_type]
            panel.set_new(fname in latest_saves)
        

var pagenum = 1
func pressed_page_button(button : BaseButton):
    for other in $PageButtons.get_children():
        if other is BaseButton and button != other:
            other.pressed = false
    button.pressed = true
    
    if button.text != "Q":
        pagenum = int(button.text)
        set_page()
    else:
        pagenum = -1
        set_page()

func pressed_panel(panel):
    if mode == "load":
        if panel.data and panel.data.size() > 0:
            Manager.load_from_dict(panel.data)
            dying = true
    elif mode == "save":
        var data = Manager.save_to_dict()
        data["date"] = OS.get_date()
        data["time"] = OS.get_time()
        save_data(panel.number, data, panel)
        panel.set_savedata(data)
        panel.set_new(true)

var dying = false
var show_amount = 0.0

func _process(delta):
    if mode == "save":
        $Title.text = "Save"
        $CategoryButtons/SaveButton.pressed = true
        $CategoryButtons/LoadButton.pressed = false
        $Background.texture = preload("res://art/ui/menubg2.png")
    else:
        $Title.text = "Load"
        $CategoryButtons/SaveButton.pressed = false
        $CategoryButtons/LoadButton.pressed = true
        $Background.texture = preload("res://art/ui/menubg3.png")
    
    if Input.is_action_just_pressed("m2"):
        dying = true
    
    if dying:
        show_amount -= delta*4.0
        if show_amount <= 0.0:
            show_amount = 0.0
            queue_free()
    else:
        show_amount += delta*4.0
        show_amount = clamp(show_amount, 0.0, 1.0)
    
    offset.y = -get_viewport().get_visible_rect().size.y * (1.0-show_amount*show_amount)
    $Background.rect_position.y = -offset.y
    $FillRect.rect_position.y = -offset.y
    $Background.modulate.a = show_amount
    $FillRect.modulate.a = show_amount
    
    $Background.region_rect.position.x -= delta * 16.0
    

