extends CanvasLayer

# TODO: reset to default, auto speed, whether to save screenshots for saves, when to autosave,

onready var bgs = [
    preload("res://art/cutscene/bg/desert bg.jpg"),
    preload("res://art/cutscene/bg/dusk bg.jpg"),
    preload("res://art/cutscene/bg/hill bg.jpg"),
    preload("res://art/cutscene/bg/night bg.jpg"),
    preload("res://art/cutscene/bg/grass bg.jpg"),
]

const saved_project_settings = [
  "display/window/size/fullscreen",
  "display/window/size/borderless",
  "display/window/vsync/use_vsync",
  "display/window/vsync/vsync_via_compositor",
  "display/window/dpi/allow_hidpi",
  "debug/settings/fps/force_fps",
]

func save_project_settings(list : Array = saved_project_settings):
    # ProjectSettings.save_custom() saves too much crap and causes a lot of trouble
    var file = File.new()
    #print(ProjectSettings.get_setting("application/config/project_settings_override"))
    file.open(ProjectSettings.get_setting("application/config/project_settings_override"), File.WRITE)
    file.store_string("config_version=4")
    file.store_string("\n\n")
    
    var categories = {}
    
    for name in list:
        categories[(name as String).split("/")[0]] = null
    
    for category in categories:
        file.store_string("\n[%s]\n\n" % [category])
        for name in list:
            if !name.begins_with(category):
                continue
            var setting = name.split("/", true, 1)[1]
            file.store_string("%s.release=" % [setting])
            var value = ProjectSettings.get_setting(name)
            if value is String:
                file.store_string("\"%s\"" % [(value as String).c_escape()])
            elif value is bool:
                file.store_string("%s" % ["true" if value else "false"])
            else:
                file.store_string("%s" % [value])
            file.store_string("\n")
    
    file.store_string("\n")
    file.flush()
    file.close()


var existing_bgm = null

func _ready():
    existing_bgm = Manager.get_node("BGM").stream
    if OS.has_feature("editor"):
        $Infodump2.visible = true
    else:
        $Infodump2.visible = false
    $ScreenSettings/Framerate.add_item("No Limit/Follow Vsync")
    for val in [24, 30, 48, 50, 60, 75, 80, 120, 144, 240, 300]:
        $ScreenSettings/Framerate.add_item("%sfps" % [val])
    
    $ScreenSettings/Fullscreen.pressed = ProjectSettings.get_setting("display/window/size/fullscreen")
    $ScreenSettings/Borderless.pressed = ProjectSettings.get_setting("display/window/size/borderless")
    $ScreenSettings/Vsync.pressed = ProjectSettings.get_setting("display/window/vsync/use_vsync")
    $ScreenSettings/CompositorVsync.pressed = ProjectSettings.get_setting("display/window/vsync/vsync_via_compositor")
    $ScreenSettings/HiDPI.pressed = ProjectSettings.get_setting("display/window/dpi/allow_hidpi")
    
    $DisplaySettings/WindowOpacity.value = UserSettings.textbox_opacity * $DisplaySettings/WindowOpacity.max_value
    $DisplaySettings/TextSpeed.value = (log(UserSettings.text_speed)/log(10)/2.0+0.5) * $DisplaySettings/WindowOpacity.max_value
    $DisplaySettings/TextOutline.pressed = UserSettings.text_outline
    $DisplaySettings/TextShadow.pressed = UserSettings.text_shadow
    
    $AudioSettings/BgMute.pressed = UserSettings.audio_muted_unfocused
    $AudioSettings/SFXVolume.value = $AudioSettings/SFXVolume.max_value * sqrt(Manager.db_to_volts(UserSettings.audio_sfx_volume)) * 4.0 / 5.0
    $AudioSettings/BGMVolume.value = $AudioSettings/BGMVolume.max_value * sqrt(Manager.db_to_volts(UserSettings.audio_bgm_volume)) * 4.0 / 5.0
    $AudioSettings/MasterVolume.value = $AudioSettings/MasterVolume.max_value * sqrt(Manager.db_to_volts(UserSettings.audio_master_volume))
    
    $DialogSettings/Quicksave.pressed = UserSettings.dialog_quicksave_dialog
    $DialogSettings/Quickload.pressed = UserSettings.dialog_quickload_dialog
    $DialogSettings/Save.pressed = UserSettings.dialog_save_dialog
    $DialogSettings/SaveOverwrite.pressed = UserSettings.dialog_save_overwrite_dialog
    $DialogSettings/Load.pressed = UserSettings.dialog_load_dialog
    $DialogSettings/Delete.pressed = UserSettings.dialog_delete_dialog
    $DialogSettings/Quit.pressed = UserSettings.dialog_quit_dialog
    
    var _unused
    
    for input in $ScreenSettings.get_children() + $DisplaySettings.get_children() + $AudioSettings.get_children() + $DialogSettings.get_children():
        if input is CheckButton:
            input.connect("toggled", self, "button_toggled", [input])
        elif input is OptionButton:
            input.connect("item_selected", self, "button_option_picked", [input])
        elif input is Range:
            input.connect("value_changed", self, "slider_changed", [input])
            input.connect("gui_input", self, "slider_gui_input", [input])
    
    var fps = ProjectSettings.get_setting("debug/settings/fps/force_fps")
    for i in $ScreenSettings/Framerate.get_item_count():
        var item_name : String = $ScreenSettings/Framerate.get_item_text(i)
        if item_name.begins_with(str(fps)):
            $ScreenSettings/Framerate.selected = i
            break
    
    for button in $CategoryButtons.get_children():
        _unused = (button as BaseButton).connect("pressed", self, "pressed_category_button", [button])
    
    $CategoryButtons/ScreenButton.grab_focus()


func button_toggled(button_pressed : bool, button : BaseButton):
    if button == $ScreenSettings/Fullscreen:
        ProjectSettings.set_setting("display/window/size/fullscreen", button_pressed)
        OS.window_fullscreen = button_pressed
        Manager.reconcile_borderless_fullscreen()
    elif button == $ScreenSettings/Borderless:
        ProjectSettings.set_setting("display/window/size/borderless", button_pressed)
        OS.window_borderless = button_pressed
        Manager.reconcile_borderless_fullscreen()
    elif button == $ScreenSettings/Vsync:
        ProjectSettings.set_setting("display/window/vsync/use_vsync", button_pressed)
        OS.vsync_enabled = button_pressed
    elif button == $ScreenSettings/CompositorVsync:
        ProjectSettings.set_setting("display/window/vsync/vsync_via_compositor", button_pressed)
        OS.vsync_via_compositor = button_pressed
    elif button == $ScreenSettings/HiDPI:
    
        ProjectSettings.set_setting("display/window/dpi/allow_hidpi", button_pressed)
    elif button == $DisplaySettings/TextOutline:
        UserSettings.text_outline = button_pressed
    elif button == $DisplaySettings/TextShadow:
        UserSettings.text_shadow = button_pressed
    
    elif button == $AudioSettings/BgMute:
        UserSettings.audio_muted_unfocused = button_pressed
    
    elif button == $DialogSettings/Quicksave:
        UserSettings.dialog_quicksave_dialog = button_pressed
    elif button == $DialogSettings/Quickload:
        UserSettings.dialog_quickload_dialog = button_pressed
    elif button == $DialogSettings/Save:
        UserSettings.dialog_save_dialog = button_pressed
        if button_pressed:
            UserSettings.dialog_save_overwrite_dialog = true
            $DialogSettings/SaveOverwrite.pressed = true
    elif button == $DialogSettings/SaveOverwrite:
        UserSettings.dialog_save_overwrite_dialog = button_pressed
        if !button_pressed:
            UserSettings.dialog_save_dialog = false
            $DialogSettings/Save.pressed = false
    elif button == $DialogSettings/Load:
        UserSettings.dialog_load_dialog = button_pressed
    elif button == $DialogSettings/Delete:
        UserSettings.dialog_delete_dialog = button_pressed
    elif button == $DialogSettings/Quit:
        UserSettings.dialog_quit_dialog = button_pressed
    
    if $ScreenSettings.is_a_parent_of(button):
        save_project_settings()
    elif $DisplaySettings.is_a_parent_of(button):
        UserSettings.do_save()
    elif $AudioSettings.is_a_parent_of(button):
        UserSettings.do_save()
    elif $DialogSettings.is_a_parent_of(button):
        UserSettings.do_save()

func button_option_picked(option : int, button : OptionButton):
    ProjectSettings.set_setting("debug/settings/fps/force_fps", 0)
    Engine.target_fps = 0
    if button == $ScreenSettings/Framerate:
        var array = button.get_item_text(option).split("fps")
        if array.size() > 0:
            var text : String = array[0]
            if text.is_valid_float():
                var fps = text.to_float()
                ProjectSettings.set_setting("debug/settings/fps/force_fps", fps)
                Engine.target_fps = fps
    
    if $ScreenSettings.is_a_parent_of(button):
        save_project_settings()
    elif $DisplaySettings.is_a_parent_of(button):
        UserSettings.do_save()
    elif $AudioSettings.is_a_parent_of(button):
        UserSettings.do_save()
    elif $DialogSettings.is_a_parent_of(button):
        UserSettings.do_save()

func slider_changed(value : float, slider : Range):
    value = value/float(slider.max_value)
    if slider == $DisplaySettings/WindowOpacity:
        UserSettings.textbox_opacity = value
    elif slider == $DisplaySettings/TextSpeed:
        UserSettings.text_speed = pow(10.0, value * 2.0 - 1.0)
    elif slider == $AudioSettings/SFXVolume:
        value = value*5/4
        var db = Manager.volts_to_db(value*value)
        UserSettings.audio_sfx_volume = db
    elif slider == $AudioSettings/BGMVolume:
        value = value*5/4
        var db = Manager.volts_to_db(value*value)
        UserSettings.audio_bgm_volume = db
    elif slider == $AudioSettings/MasterVolume:
        var db = Manager.volts_to_db(value*value)
        UserSettings.audio_master_volume = db
    
    if $ScreenSettings.is_a_parent_of(slider):
        save_project_settings()
    elif $DisplaySettings.is_a_parent_of(slider):
        UserSettings.do_save()
    elif $AudioSettings.is_a_parent_of(slider):
        UserSettings.do_save()
    elif $DialogSettings.is_a_parent_of(slider):
        UserSettings.do_save()

func slider_gui_input(event : InputEvent, slider : Range):
    if event is InputEventMouseButton and event.pressed == false and event.button_index == 1:
        if slider == $AudioSettings/SFXVolume:
            Manager.sfx(preload("res://sfx/wet.wav"))

func pressed_category_button(button : BaseButton):
    for other in $CategoryButtons.get_children():
        if button != other:
            other.pressed = false
    button.pressed = true
    for panel in [$ScreenSettings, $DisplaySettings, $AudioSettings, $DialogSettings]:
        panel.hide()
    if button == $CategoryButtons/ScreenButton:
        $ScreenSettings.show()
    
    if button == $CategoryButtons/DisplayButton:
        $DisplaySettings.show()
        text_demo_reset()
    
    if button == $CategoryButtons/AudioButton:
        $AudioSettings.show()
        if !existing_bgm:
            Manager.play_bgm(preload("res://bgm/happy music loopable.ogg"))
    else:
        if !existing_bgm:
            Manager.play_bgm(null)
    
    if button == $CategoryButtons/DialogButton:
        $DialogSettings.show()
    
    if button == $CategoryButtons/ReturnButton:
        dying = true

func text_demo_reset():
    text_demo_visible_wait = 0
    text_demo_visible = 0
    $DisplaySettings/Textbox/BG.texture = bgs.pop_front()
    bgs.push_back($DisplaySettings/Textbox/BG.texture)

var text_demo_visible = 0
var text_demo_visible_wait_max = 1.5
var text_demo_visible_wait = 0

#EngineSettings.textbox_typein_chars_per_sec

var dying = false
var show_amount = 0.0

func _process(delta):
    if get_tree().get_nodes_in_group("CustomPopup").size() == 0 and Input.is_action_just_pressed("m2"):
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
    
    $Background.region_rect.position.x += delta * 16.0
    
    $FPSDisplay.text = "Current framerate: %s" % [round(1.0/max(0.0001, delta)*100.0)/100.0]
    
    Manager.input_disabled = true
    if $DisplaySettings.visible:
        var char_limit = $DisplaySettings/Textbox/Label.get_total_character_count()
        
        if UserSettings.text_shadow:
            $DisplaySettings/Textbox/Label.add_constant_override("shadow_offset_x", 2)
            $DisplaySettings/Textbox/Label.add_constant_override("shadow_offset_y", 2)
            $DisplaySettings/Textbox/Label.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 0.5))
        else:
            $DisplaySettings/Textbox/Label.add_constant_override("shadow_offset_x", 0)
            $DisplaySettings/Textbox/Label.add_constant_override("shadow_offset_y", 0)
            $DisplaySettings/Textbox/Label.add_color_override("font_color_shadow", Color(0.0, 0.0, 0.0, 0.0))
        
        for _font in ["bold_italics_font", "bold_font", "italics_font", "normal_font", "mono_font"]:
            var font : Font = $DisplaySettings/Textbox/Label.get_font(_font)
            if font and font is DynamicFont:
                font.outline_size = 1.0 if UserSettings.text_outline else 0.0
        
        $DisplaySettings/Textbox/ADV.modulate.a = UserSettings.textbox_opacity
        
        
        if UserSettings.text_speed < UserSettings.text_speed_max:
            text_demo_visible += delta*EngineSettings.textbox_typein_chars_per_sec*UserSettings.text_speed
        else:
            text_demo_visible = char_limit
        
        if text_demo_visible >= char_limit:
            text_demo_visible = char_limit
            text_demo_visible_wait += delta
        if text_demo_visible_wait > text_demo_visible_wait_max:
            text_demo_reset()
        $DisplaySettings/Textbox/Label.visible_characters = int(text_demo_visible)
    pass

