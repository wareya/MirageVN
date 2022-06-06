extends Node

var textbox_opacity = EngineSettings.textbox_default_opacity
var text_speed_max = 10.0
var text_speed = 1.0
var text_shadow = true
var text_outline = true
# TODO: auto delay configuration
# TODO: configure whether to wake from skip when reaching unread text

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

var system_save_screenshots = true
# TODO: settings for when to autosave (on quit, at choices, at scene changes, at every text update, etc)
var system_autocontinue_on_boot = false

func _init():
    do_load()

func to_dict():
    var dict = {
        textbox_opacity = textbox_opacity,
        text_speed = text_speed,
        text_shadow = text_shadow,
        text_outline = text_outline,
        audio_sfx_volume = audio_sfx_volume,
        audio_bgm_volume = audio_bgm_volume,
        audio_master_volume = audio_master_volume,
        audio_muted_unfocused = audio_muted_unfocused,
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
