extends CanvasLayer
class_name SaveDataManager

var mode = "save"
var save_disabled = false

var latest_page = 1

var latest_saves = []
var locked_saves = []
func update_latest_saves():
    var sysdata = Manager.load_sysdata()
    if "latest_saves" in sysdata:
        latest_saves = sysdata["latest_saves"]
    if "locked_saves" in sysdata:
        locked_saves = sysdata["locked_saves"]
    if "latest_page" in sysdata:
        latest_page  = sysdata["latest_page"]

var pageflip_sound = preload("res://sfx/paper bag.wav")

func _ready():
    update_latest_saves()
    var _unused
    for button in $CategoryButtons.get_children():
        if button is BaseButton:
            _unused = (button as BaseButton).connect("pressed", self, "pressed_category_button", [button])
    
    pagenum = latest_page
    
    for button in $PageButtons.get_children():
        if button is BaseButton:
            _unused = (button as BaseButton).connect("pressed", self, "pressed_page_button", [button])
            if button is Button:
                button.pressed = button.text == "%d" % [latest_page]
    for panel in $Page.get_children():
        panel.connect("pressed", self, "pressed_panel", [panel])
        panel.connect("lock_changed", self, "panel_lock_changed", [panel])
    
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
    
    set_page(true)

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
func set_page(silent : bool = false):
    if !silent:
        EmitterFactory.emit(null, pageflip_sound)
    var panels = $Page.get_children()
    if pagenum > 0:
        latest_page = pagenum
        var sysdata = Manager.load_sysdata()
        sysdata["latest_page"] = latest_page
        Manager.save_sysdata(sysdata)
        
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
            panel.fname = fname
            panel.set_new(fname in latest_saves)
            panel.set_locked(fname in locked_saves)
    else:
        if pagenum == -1:
            save_type = "quicksave"
        elif pagenum == -2:
            save_type = "autosave"
        else:
            return
        for i in range(0, saves_per_page):
            var panel = panels[i]
            var data = load_data(i)
            if data:
                panel.set_savedata(data)
            else:
                panel.set_blank()
            panel.set_number(i)
            
            var fname = "user://saves/%04d_%s.json" % [i, save_type]
            panel.fname = fname
            panel.set_new(fname in latest_saves)
        

var pagenum = 1
func pressed_page_button(button : BaseButton):
    for other in $PageButtons.get_children():
        if other is BaseButton and button != other:
            other.pressed = false
    button.pressed = true
    
    if button.text != "Q" and button.text != "A":
        pagenum = int(button.text)
        set_page()
    elif button.text == "Q":
        pagenum = -1
        set_page()
    elif button.text == "A":
        pagenum = -2
        set_page()

func pressed_panel(panel):
    if mode == "load":
        if panel.data and panel.data.size() > 0:
            Manager.load_from_dict(panel.data)
            var sysdata = Manager.load_sysdata()
            sysdata["last_accessed_save"] = panel.fname
            Manager.save_sysdata(sysdata)
            dying = true
    elif mode == "save":
        if panel.fname in locked_saves:
            EmitterFactory.emit(null, EngineSettings.save_failure_sound)
            return
        var data = Manager.save_to_dict()
        data["date"] = OS.get_date()
        data["time"] = OS.get_time()
        save_data(panel.number, data, panel)
        panel.set_savedata(data)
        panel.set_new(true)
        panel.set_locked(panel.fname in locked_saves)

func panel_lock_changed(locked : bool, panel):
    if not pagenum > 0:
        return
    
    var sysdata = Manager.load_sysdata()
    if "locked_saves" in sysdata:
        locked_saves = sysdata["locked_saves"]
    if locked and locked_saves.find(panel.fname) < 0:
        locked_saves.push_back(panel.fname)
    elif !locked and locked_saves.find(panel.fname) >= 0:
        locked_saves.erase(panel.fname)
    
    sysdata["locked_saves"] = locked_saves
    Manager.save_sysdata(sysdata)

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
    

