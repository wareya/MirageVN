extends CanvasLayer
class_name SaveDataManager


const saves_per_page = 12


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
        panel.connect("delete", self, "attempt_panel_delete", [panel])
    
    if save_disabled:
        mode = "load"
        $CategoryButtons/SaveButton.disabled = true
    
    if mode == "save":
        $Title.text = "Save"
        $CategoryButtons/SaveButton.grab_focus()
        $Background.texture.atlas = preload("res://art/ui/menubg2.png")
    else:
        $Title.text = "Load"
        $CategoryButtons/LoadButton.grab_focus()
        $Background.texture.atlas = preload("res://art/ui/menubg3.png")
    
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
            panel.set_new(fname in latest_saves and data)
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
            panel.set_new(fname in latest_saves and data)
        

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

func do_panel_load(panel):
    if panel.data and panel.data.size() > 0:
        Manager.load_from_dict(panel.data)
        var sysdata = Manager.load_sysdata()
        sysdata["last_accessed_save"] = panel.fname
        Manager.save_sysdata(sysdata)
        dying = true

func do_panel_save(panel):
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

func pressed_panel(panel):
    if mode == "load":
        if panel.data and panel.data.size() > 0:
            if !UserSettings.dialog_load_dialog:
                do_panel_load(panel)
                return
            
            var helper = Manager.PopupHelper.new(
                self,
                "do_panel_load",
                "Confirm Load",
                ("Load game?\nUnsaved progress will be lost."
                if get_tree().get_nodes_in_group("MainMenu").size() == 0 else
                "Load game?"
                ),
                [panel]
            )
            add_child(helper)
            helper.invoke()
    elif mode == "save":
        if panel.fname in locked_saves:
            EmitterFactory.emit(null, EngineSettings.save_failure_sound)
            return
        
        var will_overwrite = panel.data.size() > 0
        
        if !will_overwrite and !UserSettings.dialog_save_dialog:
            do_panel_save(panel)
            return
        if will_overwrite and !UserSettings.dialog_save_overwrite_dialog:
            do_panel_save(panel)
            return
        
        var helper = Manager.PopupHelper.new(
            self,
            "do_panel_save",
            "Confirm Save",
            ("Save game?\nOverwritten data will not be backed up."
             if will_overwrite else
             "Save game?"
            ),
            [panel]
        )
        add_child(helper)
        helper.invoke()

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

func attempt_panel_delete(panel):
    if !panel.fname.begins_with("user://saves/"):
        return
    
    if !UserSettings.dialog_delete_dialog:
        panel_delete(panel)
        return

    var helper = Manager.PopupHelper.new(
        self,
        "panel_delete",
        "Confirm Delete",
        ("Delete save file?\nIf possible, save data will be sent to your OS's trash, but deleted with no backup if not."
         if "move_to_trash" in OS else
         "Delete save file?\nSave data will be permanently deleted with no backup."
        ),
        [panel]
    )
    add_child(helper)
    helper.invoke()

func panel_delete(panel):
    if !panel.fname.begins_with("user://saves/"):
        return
    
    EmitterFactory.emit(null, preload("res://sfx/savedelete.wav"))
    
    if "move_to_trash" in OS:
        OS.move_to_trash(panel.fname)
    else:
        var dir = Directory.new()
        dir.remove(panel.fname)
    
    var sysdata = Manager.load_sysdata()
    if "locked_saves" in sysdata:
        locked_saves = sysdata["locked_saves"]
    if "latest_saves" in sysdata:
        latest_saves = sysdata["latest_saves"]
    
    if latest_saves.find(panel.fname) >= 0:
        latest_saves.erase(panel.fname)
    if locked_saves.find(panel.fname) >= 0:
        locked_saves.erase(panel.fname)
    
    if "last_accessed_save" in sysdata:
        sysdata["last_accessed_save"] = ""
        if latest_saves.size() > 0:
            sysdata["last_accessed_save"] = latest_saves[0]
    
    sysdata["locked_saves"] = locked_saves
    sysdata["latest_saves"] = latest_saves
    Manager.save_sysdata(sysdata)
    
    panel.set_blank()
    panel.set_new(false)
    panel.set_locked(false)

var dying = false
var show_amount = 0.0

var prev_focus_owner = null

var memo_panel = null
func memo_apply(memo_text):
    memo_panel.data["memo"] = memo_text
    save_data(memo_panel.number, memo_panel.data, memo_panel)
    memo_panel.set_savedata(memo_panel.data)
    memo_panel = null
    pass
func do_memo_panel(panel):
    memo_panel = panel
    if !$MemoInputPanel.is_connected("pressed_ok", self, "memo_apply"):
        var _unused = $MemoInputPanel.connect("pressed_ok", self, "memo_apply")
    $MemoInputPanel.open(panel)
    pass

func _process(delta):
    if mode == "save":
        $Title.text = "Save"
        $CategoryButtons/SaveButton.pressed = true
        $CategoryButtons/LoadButton.pressed = false
        $Background.texture.atlas = preload("res://art/ui/menubg2.png")
    else:
        $Title.text = "Load"
        $CategoryButtons/SaveButton.pressed = false
        $CategoryButtons/LoadButton.pressed = true
        $Background.texture.atlas = preload("res://art/ui/menubg3.png")
    
    if get_tree().get_nodes_in_group("CustomPopup").size() == 0 and !$MemoInputPanel.visible and Input.is_action_just_pressed("m2"):
        var found_save_item = null
        var mouse_pos = $Page.get_global_mouse_position()
        for panel in $Page.get_children():
            if panel.get_global_rect().has_point(mouse_pos):
                found_save_item = panel
                break
        if found_save_item:
            do_memo_panel(found_save_item)
            pass
        else:
            dying = true
    
    var focus_holder = $Page.get_focus_owner()
    if Input.is_action_just_pressed("delete") and focus_holder and $Page.is_a_parent_of(focus_holder):
        attempt_panel_delete($Page.get_focus_owner())
    
    if focus_holder and ($CategoryButtons.is_a_parent_of(focus_holder) or $Page.is_a_parent_of(focus_holder) or $PageButtons.is_a_parent_of(focus_holder)):
        prev_focus_owner = focus_holder
    
    if !Manager.block_input_focus() and focus_holder == null:
        if prev_focus_owner and is_instance_valid(prev_focus_owner):
            prev_focus_owner.grab_focus()
    
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
    
    $Background.texture.region.position.x += delta * 16.0
    $Background.texture.region.position.x = fmod($Background.texture.region.position.x, $Background.texture.atlas.get_size().x)
    

