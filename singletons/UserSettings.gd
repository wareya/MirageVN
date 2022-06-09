extends Node

var textbox_opacity = EngineSettings.textbox_default_opacity
var text_speed_max = 10.0
var text_speed = 1.0
var text_shadow = true
var text_outline = true
var text_copy_to_clipboard = false

var audio_sfx_volume = EngineSettings.audio_sfx_default_volume
var audio_bgm_volume = EngineSettings.audio_bgm_default_volume
var audio_master_volume = EngineSettings.audio_master_default_volume
var audio_muted_unfocused = false

var dialog_quickload_dialog = true
var dialog_quicksave_dialog = true
var dialog_load_dialog = true
var dialog_save_dialog = true
var dialog_save_overwrite_dialog = true
var dialog_delete_dialog = true
var dialog_quit_dialog = true
var dialog_to_title_dialog = true

var system_save_screenshots = true
var system_autocontinue_on_boot = false
var system_skip_wake_on_unread = true
var system_autosave_when = 0 # 0: on exit only. 1: also at choices. 2: also when changing scenes.
var system_read_lines_write_on_save_only = false
var system_auto_chars_per_second = round(10.0/EngineSettings.auto_delay_per_character)/10.0
var system_auto_additional_pause_seconds = EngineSettings.auto_delay_amount

var defaults = {}

func reset_to_defaults():
    from_dict(defaults)

func _init():
    defaults = to_dict()
    do_load()

func to_dict():
    var dict = {
        textbox_opacity = textbox_opacity,
        text_speed = text_speed,
        text_shadow = text_shadow,
        text_outline = text_outline,
        text_copy_to_clipboard = text_copy_to_clipboard,
        
        audio_sfx_volume = audio_sfx_volume,
        audio_bgm_volume = audio_bgm_volume,
        audio_master_volume = audio_master_volume,
        audio_muted_unfocused = audio_muted_unfocused,
        
        dialog_quickload_dialog = dialog_quickload_dialog,
        dialog_quicksave_dialog = dialog_quicksave_dialog,
        dialog_load_dialog = dialog_load_dialog,
        dialog_save_dialog = dialog_save_dialog,
        dialog_save_overwrite_dialog = dialog_save_overwrite_dialog,
        dialog_delete_dialog = dialog_delete_dialog,
        dialog_quit_dialog = dialog_quit_dialog,

        system_save_screenshots = system_save_screenshots,
        system_autocontinue_on_boot = system_autocontinue_on_boot,
        system_skip_wake_on_unread = system_skip_wake_on_unread,
        system_autosave_when = system_autosave_when,
        system_read_lines_write_on_save_only = system_read_lines_write_on_save_only,
        system_auto_chars_per_second = system_auto_chars_per_second,
        system_auto_additional_pause_seconds = system_auto_additional_pause_seconds,
    }
    return dict

func from_dict(dict : Dictionary):
    for key in dict:
        set(key, dict[key])

var want_to_save = -1

func do_save(instant = true):
    if want_to_save < 0:
        want_to_save = 0.0
    if instant:
        check_save(1.0)
    
func check_save(delta):
    if want_to_save >= 0:
        want_to_save += delta
    if want_to_save >= 1.0:
        want_to_save = -1
        var save = File.new()
        var dict = to_dict()
        save.open("user://user_settings.json", File.WRITE)
        save.store_string(JSON.print(dict, " "))
        save.flush()
        save.close()

func do_load():
    var save = File.new()
    var err = save.open("user://user_settings.json", File.READ)
    if err == OK:
        var json = save.get_as_text()
        var result = JSON.parse(json)
        if result.error == OK:
            var data = result.result
            from_dict(data)
    save.close()

func _process(delta):
    
    check_save(delta)
    
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), audio_sfx_volume)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), audio_bgm_volume)
    AudioServer.set_bus_volume_db(0, audio_master_volume)

func _notification(what : int) -> void:
    match what:
        NOTIFICATION_WM_FOCUS_OUT:
            AudioServer.set_bus_mute(0, audio_muted_unfocused)
        NOTIFICATION_WM_FOCUS_IN:
            AudioServer.set_bus_mute(0, false)
        NOTIFICATION_WM_QUIT_REQUEST:
            check_save(1.0)
