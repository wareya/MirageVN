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

var default_project_settings = {
  "display/window/size/fullscreen" : false,
  "display/window/size/borderless" : false,
  "display/window/vsync/use_vsync" : true,
  "display/window/vsync/vsync_via_compositor" : false,
  "display/window/dpi/allow_hidpi" : true,
  "debug/settings/fps/force_fps" : 144,
}

func reset_project_settings():
    for setting in default_project_settings:
        var value = default_project_settings[setting]
        ProjectSettings.set_setting(setting, value)
    
    OS.window_fullscreen = ProjectSettings.get_setting("display/window/size/fullscreen")
    OS.window_borderless = ProjectSettings.get_setting("display/window/size/borderless")
    OS.vsync_enabled = ProjectSettings.get_setting("display/window/vsync/use_vsync")
    OS.vsync_via_compositor = ProjectSettings.get_setting("display/window/vsync/vsync_via_compositor")
    Engine.target_fps = ProjectSettings.get_setting("debug/settings/fps/force_fps")

func save_project_settings(list : Array = saved_project_settings):
    # ProjectSettings.save_custom() saves too much crap and causes a lot of trouble
    # so we encode the file manually instead
    var file = File.new()
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

onready var category_pairs = [
    [$ScreenSettings , $CategoryButtons/ScreenButton ],
    [$DisplaySettings, $CategoryButtons/DisplayButton],
    [$AudioSettings  , $CategoryButtons/AudioButton  ],
    [$DialogSettings , $CategoryButtons/DialogButton ],
    [$SystemSettings , $CategoryButtons/SystemButton ]
]

onready var cat_buttons = [
    $CategoryButtons/ScreenButton,
    $CategoryButtons/DisplayButton,
    $CategoryButtons/AudioButton,
    $CategoryButtons/DialogButton,
    $CategoryButtons/SystemButton
]

var existing_bgm = null

func set_controls_from_settings():
    $ScreenSettings/Fullscreen.pressed = ProjectSettings.get_setting("display/window/size/fullscreen")
    $ScreenSettings/Borderless.pressed = ProjectSettings.get_setting("display/window/size/borderless")
    $ScreenSettings/Vsync.pressed = ProjectSettings.get_setting("display/window/vsync/use_vsync")
    $ScreenSettings/CompositorVsync.pressed = ProjectSettings.get_setting("display/window/vsync/vsync_via_compositor")
    $ScreenSettings/HiDPI.pressed = ProjectSettings.get_setting("display/window/dpi/allow_hidpi")
    
    $DisplaySettings/WindowOpacity.value = UserSettings.textbox_opacity * $DisplaySettings/WindowOpacity.max_value
    $DisplaySettings/TextSpeed.value = (log(UserSettings.text_speed)/log(10)/2.0+0.5) * $DisplaySettings/WindowOpacity.max_value
    $DisplaySettings/TextOutline.pressed = UserSettings.text_outline
    $DisplaySettings/TextShadow.pressed = UserSettings.text_shadow
    $DisplaySettings/ClipboardCopy.pressed = UserSettings.text_copy_to_clipboard
    
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
    $DialogSettings/ToTitle.pressed = UserSettings.dialog_to_title_dialog
    
    $SystemSettings/SaveScreenshots.pressed = UserSettings.system_save_screenshots
    $SystemSettings/AutoContinue.pressed = UserSettings.system_autocontinue_on_boot
    $SystemSettings/SkipWake.pressed = UserSettings.system_skip_wake_on_unread
    $SystemSettings/AutosaveFreq.selected = UserSettings.system_autosave_when
    $SystemSettings/ReadTextSaveFreq.selected = !!UserSettings.system_read_lines_write_on_save_only
    $SystemSettings/AutoCPS.value = UserSettings.system_auto_chars_per_second
    $SystemSettings/AutoPause.value = UserSettings.system_auto_additional_pause_seconds*10.0

    $SystemSettings/AutoCPSLabel.text = str(UserSettings.system_auto_chars_per_second)
    $SystemSettings/AutoPauseLabel.text = "%1.1f" % [UserSettings.system_auto_additional_pause_seconds]
        
    var _unused
    
    for input in $ScreenSettings.get_children() + $DisplaySettings.get_children() + $AudioSettings.get_children() + $DialogSettings.get_children() + $SystemSettings.get_children():
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
    

func _ready():
    existing_bgm = Manager.get_node("BGM").stream
    if OS.has_feature("editor"):
        $Infodump2.visible = true
    else:
        $Infodump2.visible = false
    $ScreenSettings/Framerate.add_item("No Limit/Follow Vsync")
    for val in [24, 30, 48, 50, 60, 75, 80, 120, 144, 240, 300]:
        $ScreenSettings/Framerate.add_item("%sfps" % [val])
    
    $SystemSettings/AutosaveFreq.add_item("On Quit")
    $SystemSettings/AutosaveFreq.add_item("Also At Choices")
    $SystemSettings/AutosaveFreq.add_item("Also At Scene Changes")
    
    $SystemSettings/ReadTextSaveFreq.add_item("While Reading")
    $SystemSettings/ReadTextSaveFreq.add_item("Occasionally")
    
    set_controls_from_settings()
    
    for button in $CategoryButtons.get_children():
        var _unused = (button as BaseButton).connect("pressed", self, "pressed_category_button", [button])
    
    $CategoryButtons/ScreenButton.grab_focus()
    
    for pair in category_pairs:
        var first_focusable = true
        for _control in pair[0].get_children():
            if not _control is Control:
                continue
            var control : Control = _control
            if control.focus_mode != Control.FOCUS_NONE:
                control.focus_neighbour_left = pair[1].get_path()
                if first_focusable:
                    control.focus_previous = pair[1].get_path()
                    first_focusable = false


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
    elif button == $DisplaySettings/ClipboardCopy:
        UserSettings.text_copy_to_clipboard = button_pressed
    
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
    elif button == $DialogSettings/ToTitle:
        UserSettings.dialog_to_title_dialog = button_pressed
    
    elif button == $SystemSettings/SaveScreenshots:
        UserSettings.system_save_screenshots = button_pressed
    elif button == $SystemSettings/AutoContinue:
        UserSettings.system_autocontinue_on_boot = button_pressed
    elif button == $SystemSettings/SkipWake:
        UserSettings.system_skip_wake_on_unread = button_pressed
    
    if $ScreenSettings.is_a_parent_of(button):
        save_project_settings()
    elif $DisplaySettings.is_a_parent_of(button):
        UserSettings.do_save()
    elif $AudioSettings.is_a_parent_of(button):
        UserSettings.do_save()
    elif $DialogSettings.is_a_parent_of(button):
        UserSettings.do_save()
    elif $SystemSettings.is_a_parent_of(button):
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
    
    elif button == $SystemSettings/AutosaveFreq:
        UserSettings.system_autosave_when = option
    elif button == $SystemSettings/ReadTextSaveFreq:
        UserSettings.system_read_lines_write_on_save_only = option
    
    if $ScreenSettings.is_a_parent_of(button):
        save_project_settings()
    elif $DisplaySettings.is_a_parent_of(button):
        UserSettings.do_save()
    elif $AudioSettings.is_a_parent_of(button):
        UserSettings.do_save()
    elif $DialogSettings.is_a_parent_of(button):
        UserSettings.do_save()
    elif $SystemSettings.is_a_parent_of(button):
        UserSettings.do_save()

func slider_changed(value : float, slider : Range):
    var raw_value = value
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
    
    elif slider == $SystemSettings/AutoCPS:
        UserSettings.system_auto_chars_per_second = raw_value
        $SystemSettings/AutoCPSLabel.text = str(raw_value)
    elif slider == $SystemSettings/AutoPause:
        UserSettings.system_auto_additional_pause_seconds = raw_value/10.0
        $SystemSettings/AutoPauseLabel.text = "%1.1f" % [raw_value/10.0]
    
    if $ScreenSettings.is_a_parent_of(slider):
        save_project_settings()
    elif $DisplaySettings.is_a_parent_of(slider):
        UserSettings.do_save()
    elif $AudioSettings.is_a_parent_of(slider):
        UserSettings.do_save()
    elif $DialogSettings.is_a_parent_of(slider):
        UserSettings.do_save()
    elif $SystemSettings.is_a_parent_of(slider):
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
    if button in cat_buttons:
        for panel in [$ScreenSettings, $DisplaySettings, $AudioSettings, $DialogSettings, $SystemSettings]:
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
    
    if button == $CategoryButtons/SystemButton:
        $SystemSettings.show()
    
    if button == $CategoryButtons/ReturnButton:
        dying = true
    
    if button == $CategoryButtons/ResetDefaultsButton:
        var helper = Manager.PopupHelper.new(
            self,
            "reset_defaults",
            "Confirm Reset Defaults",
            "Reset all settings to default? There is no backup."
        )
        add_child(helper)
        helper.invoke()
    
    if button == $CategoryButtons/ViewCreditsButton:
        var helper = Manager.PopupHelperNoCancel.new(
            null,
            "",
            "Credits",
            ""
        )
        add_child(helper)
        var panel = helper.invoke()
        panel.set_big()
        var credits =  "\n" + EngineSettings.credits_text.strip_edges() + "\n"
        panel.set_text_raw(credits)
        panel.set_text_selectable()
        panel.set_text_nocenter()
    
    if button == $CategoryButtons/ViewLicenseButton:
        var helper = Manager.PopupHelperNoCancel.new(
            null,
            "",
            "License Info",
            ""
        )
        add_child(helper)
        var panel = helper.invoke()
        panel.set_big()
        var credits = ""
        for entry in Engine.get_copyright_info():
            credits += "Uses: [b]%s[/b]\n" % [entry.name]
            for part in entry.parts:
                for c in part.copyright:
                    credits += "Copyright: %s\n" % [c]
                credits += "License: %s\n\n" % [part.license]
        credits += "\nLicense texts:\n\n"
        for key in Engine.get_license_info():
            credits += "[b]The %s License[/b]\n\n" % [key]
            var info = Engine.get_license_info()[key]
            credits += "%s\n\n" % [info]
        panel.set_text_raw("\n" + credits.strip_edges() + "\n")
        panel.set_text_selectable()
        panel.set_text_nocenter()
    
    if button == $CategoryButtons/ToTitleButton:
        if !UserSettings.dialog_to_title_dialog:
            go_to_title()
        
        var helper = Manager.PopupHelper.new(
            self,
            "go_to_title",
            "Confirm Return to Title",
            ("Return to title?"
             if get_tree().get_nodes_in_group("MainMenu").size() > 0 or Manager.is_splash else
             ("Return to title?\nAn autosave will be created."
              if Manager.can_autosave() else
              "Return to title?\nUnsaved progress will be lost."
             )
            )
        )
        add_child(helper)
        helper.invoke()

func reset_defaults():
    reset_project_settings()
    UserSettings.reset_to_defaults()
    
    save_project_settings()
    UserSettings.do_save()
    
    set_controls_from_settings()

func go_to_title():
    Manager.admit_read_line(false, true)
    if Manager.can_autosave():
        Manager.autosave()
    Manager.change_to("res://scenes/ui/Menu.tscn")
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
    
    if $Background.get_focus_owner() == null and !Manager.block_input_focus():
        $CategoryButtons/ScreenButton.grab_focus()
    
    var focus_owner = $CategoryButtons.get_focus_owner()
    
    if Input.is_action_just_pressed("ui_right") and focus_owner and $CategoryButtons.is_a_parent_of(focus_owner):
        for pair in category_pairs:
            if !pair[1].has_focus():
                continue
            pair[1].emit_signal("pressed")
            for _control in pair[0].get_children():
                if not _control is Control:
                    continue
                var control : Control = _control
                if control.focus_mode != Control.FOCUS_NONE:
                    control.grab_focus()
                    break
    
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

