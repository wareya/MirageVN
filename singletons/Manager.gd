extends CanvasLayer


func get_sec():
    return OS.get_ticks_usec()/1_000_000.0

var fade_contrast = 0.0
var fade_color : Color = Color.white
signal fade_completed
var fading = false
var fade_nonce = 0
func do_fade_anim(invert = false, fadein = false, fade_time = 0.75):
    # Use a coroutine to handle the fade overlay. Use a nonce to exit out early if necessary.
    fading = true
    var start_time = get_sec()
    var progress = 0.0
    fade_nonce += 1
    var start_nonce = fade_nonce
    while progress < 1.0:
        yield(get_tree(), "idle_frame")
        if start_nonce != fade_nonce: # another fade started
            return
        progress = (get_sec() - start_time)/fade_time
        if do_timer_skip(): progress = 1.0
        
        $FadeLayer/ScreenFader.invert = invert
        $FadeLayer/ScreenFader.contrast = fade_contrast
        $FadeLayer/ScreenFader.modulate = fade_color
        $FadeLayer/ScreenFader.self_modulate = Color.white
        if fadein:
            $FadeLayer/ScreenFader.fadeamount = clamp(1.0-progress, 0.0, 1.0)
        else:
            $FadeLayer/ScreenFader.fadeamount = clamp(progress, 0.0, 1.0)
        
    fading = false
    emit_signal("fade_completed")

func wipe_fade_out(flat = false):
    fade_contrast = 1.0 if flat else 0.0
    return do_fade_anim()

func wipe_fade_in(flat = false):
    fade_contrast = 1.0 if flat else 0.0
    return do_fade_anim(true, true)


###!!!! DO NOT TOUCH!!!!
var CUSTOM_SAVE_DATA_AT_SCENE_ENTRY = {}
# do-not-touch warning is now over

var last_entered_room_name = ""
var changing_room = false
var changing_room_out = false
signal room_changed
signal room_change_complete
func change_to(target_level : String, flat_fade : bool = false):
    if changing_room_out:
        return
    
    screen_shake_power = 0.0
    screen_shake_power_target = 0.0
    last_entered_room_name = target_level
    changing_room = true
    changing_room_out = true
    
    CUSTOM_SAVE_DATA_AT_SCENE_ENTRY = custom_save_data.duplicate(true)
    
    if true:#target_level != null and target_level != "":
        push_input_mode("transition")
        yield(wipe_fade_out(flat_fade), "completed")
        
        var scene
        if target_level.ends_with(".gd"):
            scene = Cutscene.new()
            scene.cutscene = load(target_level)
        else:
            scene = load(target_level).instance()
        
        #call_deferred("_change_to", scene, target_node) # wrong (at least in 3.3.x)
        yield(get_tree(), "idle_frame")
        _change_to(scene)
        changing_room_out = false
        yield(get_tree(), "idle_frame")
        
        
        emit_signal("room_changed")
        
        yield(wipe_fade_in(flat_fade), "completed")
        pop_input_mode("transition")
        
        changing_room = false
        emit_signal("room_change_complete")
    #else:
    #    place_player(target_node)

func _change_to(scene):
    if get_tree().current_scene and is_instance_valid(get_tree().current_scene):
        get_tree().current_scene.free()
    get_tree().get_root().add_child(scene)
    get_tree().current_scene = scene
    #place_player(target_node)

func add_entity(node : Node):
    var holder = get_from_group("Entities")
    if !holder:
        holder = get_tree().current_scene
    holder.add_child(node)

func place_player(target_node):
    var player = get_player()
    if player == null:
        #player = preload("res://scenes/entity/world/MyChar.tscn").instance()
        #get_tree().current_scene.add_child(player)
        #player.make_player()
        pass
    if target_node:
        var spawn = get_tree().current_scene.find_node(target_node, true, false)
        if spawn and player:
            player.global_position = spawn.global_position
    if player:
        player.inform_mapchange()


func parse_cutscene(script : GDScript):
    if script == null:
        return null
    return CutsceneParser.parsify(script).new()

# save/saving/savedata related stuff

# YOUR FLAGS ETC GO HERE
# This is a dictionary. See https://docs.godotengine.org/en/stable/classes/class_dictionary.html
# Don't store objects that inherit from Reference in here.
# Also don't store any data that cannot be JSON-serialized in here.
# Such objects will not be saved/loaded properly.
var custom_save_data = {}

# !!!!!!!!DO NOT TOUCH!!!!!!!!
# !!!!!!!!DO NOT TOUCH!!!!!!!!
# !!!!!!!!DO NOT TOUCH!!!!!!!!
# !!!!!!!!(THIS ALSO MEANS DON'T ASSIGN TO THESE ALL WILLY-NILLY)!!!!!!!!
# !!!!!!!!(IF YOU'RE TOUCHING THESE, AND YOU'RE NOT WRITING LOW-LEVEL SAVE SYSTEM CODE,
#          THEN YOU'RE DOING WHATEVER YOU'RE DOING THE ＷＲＯＮＧ　ＷＡＹ)!!!!!!!!
# !!!!!!!!(SERIOUSLY YOU'RE GOING TO BREAK SOMETHING)!!!!!!!!
var custom_save_data_shuttle = {}
# ^--- to make custom data more resilient against being saved in the wrong place
var SAVED_CUSTOM_SAVE_DATA = {}
var taken_choices = []
var _LOAD_CHOICE = 0
var SAVED_CHOICES = []
var LOAD_SKIP = false
var LOAD_LINE = 0
var SAVED_LINE = 0
var SAVED_CUTSCENE = ""
var last_displayed_line = ""
# do-not-touch warning is now over

# feel free to write to these
var chapter_name = "???"
var chapter_number = 0
var scene_name = "???"
var scene_number = 0

func get_savable_scene_name():
    if last_entered_room_name != "":
        return last_entered_room_name
    elif get_tree().current_scene.filename != "":
        return get_tree().current_scene.filename
    else:
        return "res://cutscenes/Dummy.gd"

func save_to_dict() -> Dictionary:
    var ret = {}
    # for loading:
    ret["SAVED_CUTSCENE"] = get_savable_scene_name()
    ret["SAVED_LINE"] = LOAD_LINE
    ret["SAVED_CHOICES"] = taken_choices.duplicate(true)
    ret["SAVED_CUSTOM_SAVE_DATA"] = custom_save_data_shuttle.duplicate(true)
    ret["SAVED_CUSTOM_SAVE_DATA_AT_SCENE_ENTRY"] = CUSTOM_SAVE_DATA_AT_SCENE_ENTRY.duplicate(true)
    # for GUI:
    ret["last_displayed_line"] = last_displayed_line
    ret["time"] = OS.get_time()
    ret["chapter_name"] = chapter_name
    ret["chapter_number"] = chapter_number
    ret["scene_name"] = scene_name
    ret["scene_number"] = scene_number
    return ret

func load_from_dict(data : Dictionary):
    SAVED_CUTSCENE = data["SAVED_CUTSCENE"]
    SAVED_LINE = data["SAVED_LINE"]
    SAVED_CUSTOM_SAVE_DATA = data["SAVED_CUSTOM_SAVE_DATA"]
    CUSTOM_SAVE_DATA_AT_SCENE_ENTRY = data["SAVED_CUSTOM_SAVE_DATA_AT_SCENE_ENTRY"]
    custom_save_data_shuttle = CUSTOM_SAVE_DATA_AT_SCENE_ENTRY.duplicate(true)
    custom_save_data = CUSTOM_SAVE_DATA_AT_SCENE_ENTRY.duplicate(true)
    SAVED_CHOICES = data["SAVED_CHOICES"]
    if SAVED_CUTSCENE == "":
        return
    print("loading to: ", [LOAD_LINE, SAVED_CUTSCENE])
    play_bgm(null)
    cutscene_paused = false
    
    change_to(SAVED_CUTSCENE)
    yield(self, "fade_completed")
    LOAD_SKIP = true
    _LOAD_CHOICE = 0
    
    $Choices.hide()
    textbox_show()

func quicksave():
    var dir : Directory = Directory.new()
    var _unused = dir.open("user://")
    if !dir.dir_exists("saves"):
        _unused = dir.make_dir("saves")
    
    $Skip.pressed = false
    var quicksave = File.new()
    quicksave.open("user://saves/0000_quicksave.json", File.WRITE)
    var json = JSON.print(save_to_dict(), " ")
    quicksave.store_string(json)
    quicksave.flush()
    quicksave.close()

func quickload():
    $Skip.pressed = false
    var quicksave = File.new()
    var err = quicksave.open("user://saves/0000_quicksave.json", File.READ)
    if err == OK:
        var json = quicksave.get_as_text()
        var result = JSON.parse(json)
        if result.error == OK:
            var data = result.result
            load_from_dict(data)
        else:
            # TODO handle error
            pass
    else:
        # TODO handle error in a user-visible way
        print("no quicksave exists")

func notify_load_finished():
    LOAD_SKIP = false
    custom_save_data = SAVED_CUSTOM_SAVE_DATA.duplicate(true)



####!!!!DO NOT TOUCH!!!!
# for skip-until-unread, already-read colorizer, etc
var READ_LINES = {}
# do-not-touch warning is now over

func is_line_read():
    var current_scene = get_savable_scene_name()
    if current_scene in READ_LINES:
        if LOAD_LINE in READ_LINES[current_scene]:
            return true
    return false

func ensure_valid_sys_file():
    var dir : Directory = Directory.new()
    var _unused = dir.open("user://")
    if !dir.dir_exists("saves"):
        _unused = dir.make_dir("saves")
    
    var sys = File.new()
    # initialize system file to empty dict if it doesn't exist yet
    if !sys.file_exists("user://saves/0000_system.json"):
        sys.open("user://saves/0000_system.json", File.WRITE)
        sys.store_string("{}")
        sys.flush()
        sys.close()

var text_has_been_added_since_loadline_update = false
func set_load_line(new):
    text_has_been_added_since_loadline_update = false
    custom_save_data_shuttle = custom_save_data.duplicate(true)
    LOAD_LINE = new

func admit_read_line(load_only = false):
    if !text_has_been_added_since_loadline_update and !load_only:
        return
    text_has_been_added_since_loadline_update = false
    ensure_valid_sys_file()
    var sysfile = File.new()
    var err = sysfile.open("user://saves/0000_system.json", File.READ)
    var sysdata = {}
    print(sysdata)
    if err == OK:
        var json = sysfile.get_as_text()
        var result = JSON.parse(json)
        if result.error == OK:
            sysdata = result.result
        else:
            # TODO handle error
            return
    else:
        # TODO handle error
        return
    
    # FIXME make this read and write an array not a dict
    # merge in-memory and on-disk read_lines sets
    var read_lines = {}
    if "read_lines" in sysdata:
        read_lines = sysdata["read_lines"]
    for scene in read_lines:
        if not scene in READ_LINES:
            READ_LINES[scene] = {}
        for line in read_lines[scene]:
            line = int(line)
            READ_LINES[scene][line] = null # godot doesn't have a "set" type so we use dicts instead
    
    # set current line as read
    var current_scene = get_savable_scene_name()
    if not current_scene in READ_LINES:
        READ_LINES[current_scene] = {}
    READ_LINES[current_scene][LOAD_LINE] = null
    
    # write back to sysdata in memory
    sysdata["read_lines"] = READ_LINES.duplicate(true)
    for scene in sysdata["read_lines"]:
        sysdata["read_lines"][scene] = sysdata["read_lines"][scene].keys()
    
    sysfile.close()
    
    if load_only:
        return
    
    # write back to file
    err = sysfile.open("user://saves/0000_system.json", File.WRITE)
    if err == OK:
        var json = JSON.print(sysdata, " ")
        sysfile.store_string(json)
    sysfile.flush()
    sysfile.close()



# mmm, auto

var auto_delay_amount = 1.5
var auto_delay_timer = -1.0
var auto_delay_per_character = 0.015
func auto():
    $Skip.pressed = false

# false positives
# warning-ignore:unused_signal
# warning-ignore:unused_signal
# warning-ignore:unused_signal
signal bg_transform_1_finished
signal bg_transform_2_finished
signal bg_transform_finished

func _ready():
    admit_read_line(true)
    print()
    var dir = Directory.new()
    var _unused = dir.open("user://")
    if !dir.dir_exists("saves"):
        _unused = dir.make_dir("saves")
    
    randomize()
    process_priority = -100
    $Textbox/Face.hide()
    $Textbox/Name.hide()
    $Textbox.hide()
    textbox_visibility_intent = false
    $Scene/Background.hide()
    backlog_hide()
    $Scene/Tachie1.hide()
    $Scene/Tachie2.hide()
    $Scene/Tachie3.hide()
    $Choices.hide()
    
    configure_bg_distortion(0)
    
    background.show()
    background.texture = preload("res://art/ui/white.png")
    background.connect("transform_1_finished", self, "emit_signal", ["bg_transform_1_finished"])
    background.connect("transform_2_finished", self, "emit_signal", ["bg_transform_2_finished"])
    background.connect("transform_finished", self, "emit_signal", ["bg_transform_finished"])
    
    _unused = $Buttons/Quicksave.connect("pressed", self, "quicksave")
    _unused = $Buttons/Quickload.connect("pressed", self, "quickload")
    _unused = $Buttons/Auto.connect("pressed", self, "auto")
    _unused = $Skip.connect("pressed", self, "skip_pressed")

func volts_to_db(x):
    return log(x)/log(10)*10*2.0 # 2.0 to get voltage db instead of power db

signal new_bgm_playing
var next_bgm = null
var bgm_fading = false
var _bgm_fade_force_remaining_time_at_most = -1.0
func bgm_fade(fade_time = 0.7):
    if bgm_fading:
        _bgm_fade_force_remaining_time_at_most = fade_time
        return
    bgm_fading = true
    var progress = 0
    while progress < 1.0:
        yield(get_tree(), "idle_frame")
        var delta = get_process_delta_time()/fade_time
        var remaining = fade_time/(1.0-progress)
        if _bgm_fade_force_remaining_time_at_most >= 0.0 and remaining > _bgm_fade_force_remaining_time_at_most:
            var rate = fade_time/_bgm_fade_force_remaining_time_at_most
            progress += delta*rate
        else:
            progress += delta
        if do_timer_skip(): progress = 1.0
        var n = (1.0-progress)
        n = n*n
        var new_db = volts_to_db(n)
        $BGM.volume_db = new_db
    $BGM.stop()
    $BGM.stream = next_bgm
    $BGM.volume_db = 0
    $BGM.play()
    next_bgm = null
    bgm_fading = false
    emit_signal("new_bgm_playing")

func play_bgm(bgm : AudioStream, fade_time = 0.7):
    if LOAD_SKIP:
        $BGM.stream = bgm
        yield(get_tree(), "idle_frame")
        $BGM.play()
        emit_signal("new_bgm_playing")
        return
    if $BGM.stream == null or !$BGM.playing:
        $BGM.stream = bgm
        $BGM.play()
        yield(get_tree(), "idle_frame")
        emit_signal("new_bgm_playing")
    elif $BGM.stream != bgm:
        if bgm == null and fade_time == 0.7:
            fade_time = 1.5
        next_bgm = bgm
        bgm_fade(fade_time)

func delayed_emit_signal(sig : String, delay : float = 1.0):
    yield(get_tree().create_timer(delay), "timeout")
    if sig == "cutscene_continue":
        admit_read_line()
    emit_signal(sig)

#onready var time = OS.get_system_time_msecs()
#var timer_stopped = false

#func reset_timer():
#    time = OS.get_system_time_msecs()

#func show_timer():
#    $Timer.show()
#func hide_timer():
#    $Timer.hide()
#func timer_visible():
#    return $Timer.visible

var cutscene_inertia_thing = true
var highest_combo = 0
var input_mode = "gameplay"
var input_mode_stack = []

func push_input_mode(mode):
    #print("???? PUSHING input mode (%s)" % mode)
    input_mode_stack.push_back(input_mode)
    input_mode = mode
func pop_input_mode(mode):
    #print("???? popping input mode (%s)" % mode)
    if input_mode == mode:
        input_mode = input_mode_stack.pop_back()
    else:
        var same = input_mode_stack.find_last(mode)
        if same < 0:
            input_mode = input_mode_stack.pop_back()
        else:
            input_mode_stack.remove(same)

var textbox_visibility_intent = false

var typein_mode = true
var typein_chars = -1
func textbox_set_typin(onoff : bool):
    typein_mode = onoff

func textbox_set_continue_icon(mode : String):
    if mode == "done":
        $Textbox/NextAnimHolder/NextAnim.animation = "done"
    elif mode == "next":
        $Textbox/NextAnimHolder/NextAnim.animation = "next"

var timers = {}
func cutscene_timer(time : float) -> SkippableTimer:
    var timer = SkippableTimer.new(time, true)
    timers[timer] = null
    return timer

func process_cutscene_timers(delta):
    if cutscene_paused:
        return
    for timer in timers:
        if !is_instance_valid(timer) or timer.dead:
            timers.erase(timer)
        else:
            timer.think(delta)

var text_mode_NVL = false

func set_NVL_mode():
    $Textbox/Label.bbcode_text = ""
    $Textbox/Label.visible_characters = 0
    typein_chars = 0
    
    text_mode_NVL = true
    $Textbox.anchor_left = 0
    $Textbox.anchor_right = 1
    $Textbox.anchor_top = 0
    $Textbox.anchor_bottom = 1
    
    $Textbox.margin_left = 0
    $Textbox.margin_right = 0
    $Textbox.margin_top = 0
    $Textbox.margin_bottom = 0
    
    $Textbox/ADV.hide()
    $Textbox/NVL.show()

func set_ADV_mode():
    $Textbox/Label.bbcode_text = ""
    $Textbox/Label.visible_characters = 0
    typein_chars = 0
    
    text_mode_NVL = false
    $Textbox.anchor_left = 0
    $Textbox.anchor_right = 1
    $Textbox.anchor_top = 1
    $Textbox.anchor_bottom = 1
    
    $Textbox.margin_left = 0
    $Textbox.margin_right = 0
    $Textbox.margin_top = -224
    $Textbox.margin_bottom = 0
    
    $Textbox/ADV.show()
    $Textbox/NVL.hide()

func get_dummy_emitter_parent():
    return $SoundCenter

signal cutscene_continue

var m1_pressed

var f4_previously_pressed = false
func check_window_size_stuff():
    var w = ProjectSettings.get_setting("display/window/size/width")
    var h = ProjectSettings.get_setting("display/window/size/height")
    # looks glitchy and nasty AF and leaves a one-pixel letterbox most of the time
    if false:
        if !OS.window_maximized and !OS.window_minimized and !OS.window_fullscreen and OS.is_window_focused():
            var target_ratio = float(w)/float(h)
            
            var winsize = OS.window_size
            var actual_ratio = winsize.x / winsize.y
            if actual_ratio < target_ratio: # wider than tall = sidebars = shrink w
                var new_w = round(winsize.y * target_ratio)
                OS.set_window_size(Vector2(new_w, winsize.y))
            else: # opposite
                var new_h = round(winsize.x / target_ratio)
                OS.set_window_size(Vector2(winsize.x, new_h))
    
    var f4_pressed = Input.is_key_pressed(KEY_F4)
    if f4_pressed and !f4_previously_pressed:
        OS.set_window_size(Vector2(w, h))
    f4_previously_pressed = f4_pressed

var delta_elapsed = 0.0
func _process(delta):
    #print(LOAD_LINE)
    #for i in range(OS.get_screen_count()):
    #    print(OS.get_screen_dpi(i))
    check_window_size_stuff()
    delta_elapsed += delta
    $DebugText.text = ""
    
    if !$Skip.pressed:
        skip_pressed_during_read_text = false
    
    process_cutscene(delta)
    $Buttons.visible = $Textbox.visible
    $Buttons.modulate = $Textbox.modulate
    $Skip.visible = $Textbox.visible
    $Skip.modulate = $Textbox.modulate
    if $Skip.pressed:
        $Buttons/Auto.pressed = false
        $Skip.visible = true
        $Skip.modulate = Color.white
    if changing_room:
        $Buttons.visible = false
        $Skip.visible = false
    m1_pressed = false
    pass

func configure_bg_distortion(mode : int):
    background.configure_bg_distortion(mode)

func set_bg_normal_map(normal_map : Texture):
    background.normal_map = normal_map

func get_bg():
    return background

func stuff_to_xform(position : Vector2, zoom : Vector2, angle : float = 0.0):
    var xform : Transform2D = Transform2D.IDENTITY
    zoom = Vector2(1.0, 1.0)/zoom
    position = position * zoom
    xform = xform.translated(-Vector2(0.5,0.5))
    xform = xform.translated( Vector2(0.5,0.5)/zoom)
    xform = xform.translated(position)
    xform = xform.scaled(zoom)
    xform = xform.rotated(angle)
    return xform

func set_bg_transform_1(position : Vector2, zoom : Vector2, angle : float = 0.0):
    var xform = stuff_to_xform(position, zoom, angle)
    background.set_transform_1(xform)
func set_bg_transform_1_target(position : Vector2, zoom : Vector2, angle : float = 0.0, time = 4.0):
    var xform = stuff_to_xform(position, zoom, angle)
    background.set_transform_1_target(xform, time)
func set_bg_transform_2(position : Vector2, zoom : Vector2, angle : float = 0.0):
    var xform = stuff_to_xform(position, zoom, angle)
    background.set_transform_2(xform)
func set_bg_transform_2_target(position : Vector2, zoom : Vector2, angle : float = 0.0, time = 4.0):
    var xform = stuff_to_xform(position, zoom, angle)
    background.set_transform_2_target(xform, time)

func debug_text(s):
    $DebugText.text += "%s\n" % s

func get_player() -> Node:
    var player : Node = null
    for obj in get_tree().get_nodes_in_group("Player"):
        player = obj
        break
    return player

func is_player(node : Node):
    return node.is_in_group("Player") and node == get_player()

signal choice_finished
func choice_select(choice_button):
    for child in $Choices.get_children():
        $Choices.remove_child(child)
        child.queue_free()
    $Choices.hide()
    block_scrollback = false
    cutscene_paused = false
    taken_choices.push_back(choice_button.text)
    emit_signal("choice_finished", choice_button.text)

func choice(choices):
    if LOAD_SKIP:
        _LOAD_CHOICE += 1
        var which = SAVED_CHOICES[_LOAD_CHOICE-1]
        taken_choices.push_back(which)
        return which
    
    backlog_hide()
    $Textbox/NextAnimHolder/NextAnim.hide()
    block_scrollback = true
    cutscene_paused = true
    
    for child in $Choices.get_children():
        $Choices.remove_child(child)
        child.queue_free()
    $Choices.show()
    var first = true
    for choice in choices:
        var button : Button = Button.new()
        button.rect_min_size = Vector2(256, 48)
        button.theme = preload("res://resources/BigButtonBG.theme")
        button.text = choice
        var _unused = button.connect("pressed", self, "choice_select", [button])
        $Choices.add_child(button)
        if first:
            button.grab_focus()
            first = false
    
    return null

var cutscene_processing_blocked = false

var skip_textbox_timer_this_frame = false
var autocontinue = false
var chars_per_sec = 120
var already_processing = false
var manually_hidden = false
var cutscene_life = 0.0
func process_cutscene(delta):
    skip_textbox_timer_this_frame = false
    var just_continued = false
    if input_mode != "cutscene":
        return
    if already_processing:
        return
    if changing_room:
        return
    
    already_processing = true
    
    if Input.is_action_just_released("skip"):
        $Skip.pressed = false
        $Buttons/Auto.pressed = false
    
    if !block_simulation():
        screen_shake_power = move_toward(screen_shake_power, screen_shake_power_target, delta)
        if do_timer_skip():
            screen_shake_power = screen_shake_power_target
        cutscene_life += delta
        if screen_shake_power > 0.0:
            var fps30_frame = floor(cutscene_life*30.0)
            var rng = RandomNumberGenerator.new()
            rng.seed = hash(fps30_frame)
            $Scene.offset.x = rng.randf_range(-1.0, 1.0) * screen_shake_power * screen_shake_amount
            $Scene.offset.y = rng.randf_range(-1.0, 1.0) * screen_shake_power * screen_shake_amount
        else:
            $Scene.offset = Vector2()
        
    if Input.is_action_just_pressed("ui_page_down"):
        prints(textbox_visibility_intent, manually_hidden, $Textbox.visible, $Textbox.modulate.a, cutscene_paused)
    
    var suppress_textbox_toggle = false
    if $ScrollbackBG.visible:
        $Skip.pressed = false
        $Buttons/Auto.pressed = false
        if Input.is_action_just_pressed("ui_up") or Input.is_action_just_released("mscroll_up"):
            $Scrollback.scroll_vertical -= backlog_entry_size
        if Input.is_action_just_pressed("ui_down") or Input.is_action_just_released("mscroll_down"):
            var old = $Scrollback.scroll_vertical
            $Scrollback.scroll_vertical += backlog_entry_size
            if $Scrollback.scroll_vertical == old:
                backlog_hide()
                if manually_hidden:
                    textbox_show()
                    manually_hidden = false
                suppress_textbox_toggle = true
                skip_textbox_timer_this_frame = true
        if Input.is_action_just_pressed("ui_end"):
            scroll_backlog_to_end()
        if Input.is_action_just_pressed("ui_home"):
            $Scrollback.scroll_vertical = 0
        if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("m2"):
            backlog_hide()
            if manually_hidden:
                textbox_show()
                manually_hidden = false
            suppress_textbox_toggle = true
            skip_textbox_timer_this_frame = true
    
    if Input.is_action_just_pressed("ui_home") or Input.is_action_just_pressed("ui_up") or Input.is_action_just_released("mscroll_up"):
        $Skip.pressed = false
        $Buttons/Auto.pressed = false
        backlog_show()
    
    if $ScrollbackBG.visible or suppress_textbox_toggle:
        already_processing = false
        $Skip.pressed = false
        $Buttons/Auto.pressed = false
        return
    
    if (Input.is_action_just_pressed("m2") or Input.is_action_just_pressed("x")) and !suppress_textbox_toggle:
        if $Skip.pressed:
            $Skip.pressed = false
        elif $Buttons/Auto.pressed:
            $Buttons/Auto.pressed = false
        elif textbox_visibility_intent:
            textbox_hide(true)
            manually_hidden = true
        elif manually_hidden:
            textbox_show()
            manually_hidden = false
    if Input.is_action_just_pressed("m1") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_down"):
        if !textbox_visibility_intent and manually_hidden:
            $Buttons/Auto.pressed = false
            textbox_show()
            manually_hidden = false
            just_continued = true
    
    process_cutscene_timers(delta)
    
    if realtime_skip() and typein_chars >= 0:
        typein_chars = -1
        $Textbox/Label.visible_characters = -1
        print("waking up cutscene")
        delayed_emit_signal("cutscene_continue", 1/20.0)
    elif !just_continued and (Input.is_action_just_pressed("ui_accept") or m1_pressed or Input.is_action_just_pressed("skip") or Input.is_action_just_pressed("ui_down")):
        $Buttons/Auto.pressed = false
        $Skip.pressed = false
        if !textbox_visibility_intent:
            skip_textbox_timer_this_frame = true
        if $Textbox/Label.visible_characters < 0 or $Textbox/Label.visible_characters >= $Textbox/Label.get_total_character_count():
            print("waking up cutscene")
            admit_read_line()
            emit_signal("cutscene_continue")
            yield(get_tree(), "idle_frame")
            just_continued = true
            #print("setting to true")
        else:
            typein_chars = -1
            $Textbox/Label.visible_characters = -1
    elif textbox_visibility_intent and (typein_chars < 0 or $Textbox/Label.visible_characters == $Textbox/Label.get_total_character_count()) and $Buttons/Auto.pressed:
        var actual_delay_amount = auto_delay_amount + auto_delay_per_character * last_displayed_line.length()
        if auto_delay_timer < actual_delay_amount:
            auto_delay_timer = clamp(auto_delay_timer, 0, actual_delay_amount)
            auto_delay_timer += delta
        else:
            auto_delay_timer = 0.0
            typein_chars = -1
            $Textbox/Label.visible_characters = -1
            print("waking up cutscene")
            delayed_emit_signal("cutscene_continue", 1/20.0)
    
    if typein_chars >= 0 and typein_chars < $Textbox/Label.get_total_character_count():
        auto_delay_timer = 0.0
        if $Textbox/Name.visible or $Textbox/Face.texture != null:
            if $BleepPlayer.stream:
                if !$BleepPlayer.playing:
                    $BleepPlayer.playing = true
                var stream : AudioStreamSample = $BleepPlayer.stream
                stream.loop_mode = AudioStreamSample.LOOP_FORWARD
        else:
            if $BleepPlayer.stream:
                var stream : AudioStreamSample = $BleepPlayer.stream
                stream.loop_mode = AudioStreamSample.LOOP_DISABLED
        
        if $Textbox.modulate.a == 1.0 and !just_continued:
            typein_chars += delta*chars_per_sec
        $Textbox/Label.visible_characters = floor(typein_chars)
        $Textbox/NextAnimHolder/NextAnim.hide()
    else:
        #if just_continued:
            #print("in else")
        if $BleepPlayer.stream:
            var stream : AudioStreamSample = $BleepPlayer.stream
            stream.loop_mode = AudioStreamSample.LOOP_DISABLED
        
        if $Textbox/Label.get_total_character_count() > 0:
            if !$Textbox/NextAnimHolder/NextAnim.visible:
                $Textbox/NextAnimHolder/NextAnim.frame = 0
            if !$Choices.visible:
                $Textbox/NextAnimHolder/NextAnim.show()
        else:
            $Textbox/NextAnimHolder/NextAnim.hide()
        
        if autocontinue:
            print("waking up cutscene")
            admit_read_line()
            emit_signal("cutscene_continue")
            $Textbox/NextAnimHolder/NextAnim.hide()
            autocontinue = false
        
    already_processing = false

var screen_shake_amount = 4.0
var screen_shake_power = 0.0
var screen_shake_power_target = 0.0
func screen_shake_start():
    screen_shake_power_target = 1.0
    
func screen_shake_stop():
    screen_shake_power_target = 0.0

onready var background = $Scene/Background
signal bg_transition_done
const __transparent = preload("res://art/ui/transparent.png")
var bg_nonce = 0
var last_set_bg : Texture = null
func set_bg(bg : Texture = null, instant : bool = false, no_textbox_hide = false):
    if bg == null and last_set_bg != null:
        bg = last_set_bg
    if bg != null:
        last_set_bg = bg
    if !bg:
        bg = __transparent
    if LOAD_SKIP:
        background.texture = bg
        background.texture2 = __transparent
        background.fadeamount = 0.0
        background.cycle_transform()
        return
    bg_nonce += 1
    var start_nonce = bg_nonce
    if !no_textbox_hide:
        if textbox_visibility_intent:
            yield(Manager, textbox_hide())
        elif $Textbox.visible:
            yield(Manager, "textbox_hidden")
    if instant:
        background.show()
        background.texture = bg
        background.texture2 = __transparent
        background.fadeamount = 0.0
        background.cycle_transform()
        yield(get_tree(), "idle_frame")
        while cutscene_paused:
            yield(get_tree(), "idle_frame")
        emit_signal("bg_transition_done")
    else:
        if background.visible and background.texture:
            if background.fadeamount > 0.0:
                background.texture = background.texture2
                background.texture2 = __transparent
                background.fadeamount = 0.0
                background.cycle_transform()
            
            background.texture2 = bg
            background.fadeamount = 0.0
        else:
            background.show()
            background.texture = __transparent
            background.fadeamount = 0.0
            background.texture2 = bg
        
        var fade_time = 1.25
        var i = 0.0
        while i < 1.0:
            yield(get_tree(), "idle_frame")
            if start_nonce != bg_nonce:
                return
            if cutscene_paused:
                continue
            var delta = get_process_delta_time()
            i += delta / fade_time
            i = clamp(i, 0.0, 1.0)
            if do_timer_skip(): i = 1.0
            var effective_contrast = background.fade_contrast
            var texture : Texture = background.fade_texture
            if texture.resource_name == "res://art/transition/flat.png":
                effective_contrast = 0.0
            background.fadeamount = lerp(smoothstep(0.0, 1.0, i), i, clamp(effective_contrast, 0, 1))
        
        background.texture = background.texture2
        background.texture2 = __transparent
        background.fadeamount = 0.0
        background.cycle_transform()
        while cutscene_paused:
            yield(get_tree(), "idle_frame")
        emit_signal("bg_transition_done")

var _default_bg_mask = preload("res://art/transition/flat.png")
func set_bg_fade_mask(texture : Texture = _default_bg_mask, invert : bool = false, contrast : float = 1.0):
    if texture == _default_bg_mask:
        contrast = 0.0
    background.fade_texture = texture
    background.fade_contrast = contrast
    background.fade_invert = invert
    pass

onready var tachie_slots = [
    null,
    $Scene/Tachie1,
    $Scene/Tachie2,
    $Scene/Tachie3,
    $Scene/Tachie4,
    $Scene/Tachie5,
]

var tachie_owners = [
    null,
    null,
    null,
    null,
    null,
    null,
]

signal tachie_zoom_finished
func set_tachie_zoom(slot : int, zoom : float):
    var tachie_slot : Tachie = tachie_slots[slot]
    tachie_slot.set_zoom(zoom)
    yield(tachie_slot, "zoom_finished")
    emit_signal("tachie_zoom_finished")

signal tachie_offset_finished
func set_tachie_offset(slot : int, offset : Vector2):
    var tachie_slot : Tachie = tachie_slots[slot]
    tachie_slot.set_offset(offset)
    yield(tachie_slot, "offset_finished")
    emit_signal("tachie_offset_finished")

# Call right after set_tachie, e.g.
#    Manager.set_tachie(1, tachie_normal, "center")
#    Manager.set_next_tachie_flipped(1)
# Causes the tachie to be flipped starting with the target of the next/current tachie transition.
# This is retained past future transitions. To unflip the tachie, you must call this again with
# false in the second argument slot.
func set_tachie_next_flipped(slot : int, flipped : bool = true):
    var tachie_slot : Tachie = tachie_slots[slot]
    tachie_slot.set_next_flipped(flipped)

signal tachie_finished
func set_tachie(slot : int, tachie : Texture, animation : String = "", no_textbox_hide = false, time : float = -1):
    if !no_textbox_hide and !LOAD_SKIP:
        if textbox_visibility_intent:
            yield(Manager, textbox_hide())
        elif $Textbox.visible:
            yield(Manager, "textbox_hidden")
    
    var tachie_slot : Tachie = tachie_slots[slot]
    if animation == "":
        animation = tachie_slot.anim_memory
    if animation == "":
        animation = "center"
    
    tachie_slot.play_animation(animation, tachie)
    tachie_slot.show()
    tachie_slot.modulate.a = 1.0
    if time >= 0.0:
        tachie_slot.anim_time = time
    else:
        tachie_slot.anim_time = 0.4
    if LOAD_SKIP or tachie_slot.anim_time == 0.0:
        tachie_slot.force_finish_anim()
    else:
        yield(tachie_slot, "animation_finished")
        emit_signal("tachie_finished")

func do_tachie_animation(slot : int, animation : String, time : float = -1):
    var tachie_slot : Tachie = tachie_slots[slot]
    if animation == "":
        animation = tachie_slot.anim_memory
    if animation == "":
        animation = "center"
    
    tachie_slot.play_animation(animation, tachie_slot.get_next_texture())
    tachie_slot.show()
    tachie_slot.modulate.a = 1.0
    if time >= 0.0:
        tachie_slot.anim_time = time
    else:
        tachie_slot.anim_time = 0.4
    if LOAD_SKIP:
        tachie_slot.force_finish_anim()
    else:
        yield(tachie_slot, "animation_finished")
        emit_signal("tachie_finished")

func set_tachie_owner(slot : int, identity : String):
    tachie_owners[slot] = identity

func animate_tachie(slot : int, animation : String = ""):
    tachie_slots[slot].play_animation(animation)

func stop_tachie(slot : int):
    tachie_slots[slot].force_finish_anim()

func hide_tachie(slot : int):
    var tachie_slot : TextureRect = tachie_slots[slot]
    if tachie_slot.modulate.a > 1 or tachie_slot.visible:
        tachie_slot.fadeout()

func hide_all_tachie():
    for tachie_slot in tachie_slots:
        if tachie_slot != null:
            if tachie_slot.modulate.a > 1 or tachie_slot.visible:
                tachie_slot.fadeout()

var skip_pressed_during_read_text = false
func skip_pressed():
    if is_line_read():
        skip_pressed_during_read_text = true
        print("wheee")

func realtime_skip():
    return Input.is_action_pressed("skip") or $Skip.pressed

func do_general_skip():
    if LOAD_SKIP or realtime_skip():
        return true
    return false
        
func do_timer_skip():
    if do_general_skip():
        return true
    if (!block_simulation() and
        (   Input.is_action_just_pressed("ui_accept")
         or Input.is_action_just_pressed("ui_down")
         or Input.is_action_just_pressed("m1")
        )):
        return true
    return false


signal textbox_shown
func _textbox_show():
    print("showing")
    $Textbox.show()
    textbox_visibility_intent = true
    manually_hidden = false
    $Textbox.modulate.a = 0.0
    var fade_time = 0.25
    var i = 0.0
    while i < 1.0:
        yield(get_tree(), "idle_frame")
        if cutscene_paused:
            continue
        if !textbox_visibility_intent:
            emit_signal("textbox_shown")
            return
        var delta = get_process_delta_time()
        i += delta / fade_time
        i = clamp(i, 0.0, 1.0)
        if do_timer_skip(): i = 1.0
        $Textbox.modulate.a = smoothstep(0.0, 1.0, i)
    emit_signal("textbox_shown")
func textbox_show():
    _textbox_show()
    return "textbox_shown"

signal textbox_hidden
func _textbox_hide(no_clear = false):
    print("hiding")
    $Textbox.show()
    textbox_visibility_intent = false
    
    if !no_clear:
        $Textbox/Label.bbcode_text = ""
        $Textbox/Face.texture = null
        $Textbox/Name.text = ""
        $Textbox/Name.bbcode_text = ""
    
    $Textbox.modulate.a = 1.0
    var fade_time = 0.25
    var i = 0.0
    while i < 1.0:
        yield(get_tree(), "idle_frame")
        if cutscene_paused:
            continue
        if textbox_visibility_intent:
            emit_signal("textbox_hidden")
            return
        var delta = get_process_delta_time()
        i += delta / fade_time
        i = clamp(i, 0.0, 1.0)
        if do_timer_skip(): i = 1.0
        $Textbox.modulate.a = smoothstep(1.0, 0.0, i)
    $Textbox.hide()
    
    emit_signal("textbox_hidden")
func textbox_hide(no_clear = false):
    _textbox_hide(no_clear)
    return "textbox_hidden"

# Sound effect that interrupts the BGM.
#func play_jingle(jingle : AudioStream):
#    if LOAD_SKIP:
#        return
#    $BGM.stream_paused = true
#    
#    $Jingle.stream = jingle
#    $Jingle.play()
#    
#    yield($Jingle, "finished")
#    $BGM.stream_paused = false

# Sound effect.
func sfx(sfx, pos = Vector2(), channel : String = "SFX", delay : float = 0.0):
    if LOAD_SKIP:
        return
    if delay > 0.0:
        print("!!!!!9314391438 yielding")
        yield(cutscene_timer(delay), "timeout")
        print("!!!!!9314391438 woke up from yield")
    return EmitterFactory.emit(null, sfx, pos, channel)

func ambiance(sound : AudioStream):
    $Ambiance.stop()
    $Ambiance.stream = sound
    $Ambiance.play()

# Set the speaker tag in the textbox. Try not to use directly.
func textbox_set_tag(bbcode : String):
    if bbcode == "":
        $Textbox/Label/Tag.hide()
        $Textbox/Label/Tag.bbcode_text = ""
    else:
        $Textbox/Label/Tag.show()
        $Textbox/Label/Tag.bbcode_text = bbcode

var override_mode_after_cutscene = null

signal kill_all_cutscenes
# Move to a new cutscene.
# Note: incorrect use of this function can cause memory leaks, crashes, save corruption, etc.
# Try to instead change scenes the same way the template does, with Manager.next_scene
func call_cutscene(entity : Node, method : String):
    if !entity.has_method(method):
        return input_mode
    
    Engine.time_scale = 1.0
    
    for i in len(tachie_slots):
        if i > 0:
            set_tachie(i, null, "", true, 0.0)
            set_tachie_next_flipped(i, false)
    $Textbox/Name.text = ""
    $Textbox/Name.bbcode_text = ""
    $Textbox/Label.text = ""
    $Textbox/Label.bbcode_text = ""
    push_input_mode("cutscene")
    configure_bg_distortion(0)
    set_bg_transform_1(Vector2(), Vector2.ONE)
    set_bg_transform_2(Vector2(), Vector2.ONE)
    
    taken_choices = []
    
    env_color = Color(0.5, 0.5, 0.5)
    env_light = Color(1.0, 1.0, 1.0)
    env_saturation = 1.0
    
    emit_signal("kill_all_cutscenes")
    var _unused = connect("kill_all_cutscenes", entity, "kill")
    add_child(entity)
    var other_ret = entity.call(method)
    yield(other_ret, "completed")
    #if is_instance_valid(entity):
    #    print("!!!!!! still valid")
    end_cutscene()
    
    if next_scene:
        fade_color = Color.black
        change_to(next_scene)
    else:
        print("!!!! NOWHERE TO GO TO")

var next_scene = null

func end_cutscene():
    pop_input_mode("cutscene")
    if $Textbox.visible:
        textbox_hide()

var name_first_person_whitelist = ["Me"]

#var _textbox_dialogue  : StreamTexture = preload("res://assets/cutscene/textbox.png")
#var _textbox_narration : StreamTexture = preload("res://assets/cutscene/textbox narration 2.png")

func set_font_outline_color(color : Color):
    for _font in ["bold_italics_font", "bold_font", "italics_font", "normal_font", "mono_font"]:
        var font : Font = $Textbox/Label.get_font(_font)
        if font and font is DynamicFont:
            font.outline_color = color
func set_font_outline_size(size : int):
    for _font in ["bold_italics_font", "bold_font", "italics_font", "normal_font", "mono_font"]:
        var font : Font = $Textbox/Label.get_font(_font)
        if font and font is DynamicFont:
            font.outline_size = size

# Edit color constance to your preference.
func set_light_on_dark():
    $Textbox/NextAnimHolder/NextAnim.modulate = Color("#ffffff")
    $Textbox/Label.add_color_override("default_color", Color("#ffffff"))
    $Textbox/Label.add_color_override("font_color_shadow", Color("#393a49"))
    $Textbox/Label.add_constant_override("shadow_offset_x", 3)
    $Textbox/Label.add_constant_override("shadow_offset_y", 1)
    set_font_outline_size(2)
    set_font_outline_color("#393a49")
    pass
func set_dark_on_light():
    $Textbox/NextAnimHolder/NextAnim.modulate = Color("#261810")
    $Textbox/Label.add_color_override("default_color", Color("#261810"))
    $Textbox/Label.add_color_override("font_color_shadow", Color("#261810"))
    $Textbox/Label.add_constant_override("shadow_offset_x", 0)
    $Textbox/Label.add_constant_override("shadow_offset_y", 0)
    set_font_outline_size(2)
    set_font_outline_color(Color("#C0FFFFFF"))
    pass

func group_exists(s : String) -> bool:
    return get_tree().get_nodes_in_group(s).size() > 0
func get_from_group(s : String) -> bool:
    var nodes = get_tree().get_nodes_in_group(s)
    return nodes[0] if nodes.size() > 0 else null

var is_narration = false
func textbox_set_identity(name : String = "<<NARRATOR>>", icon : Texture = null, bleep : AudioStream = null):
    # FIXME everything related to displaying the speaker's face anywhere other than their tachie
    # is an absolute disaster jesus christ
    if name_first_person_whitelist.find(name) >= 0:
        is_narration = false
        #set_light_on_dark() # For games with distinct narration/dialogue boxes
        #$Textbox/Sprite.texture = _textbox_dialogue
        $Textbox/Name.bbcode_text = name
        $Textbox/Face.texture = null
        $Textbox/Face.hide()
        $Textbox/Name.hide()
        #$Textbox/Label.margin_left = 50
    elif name != "<<NARRATOR>>":
        is_narration = false
        #set_light_on_dark() # For games with distinct narration/dialogue boxes
        #$Textbox/Sprite.texture = _textbox_dialogue
        $Textbox/Name.bbcode_text = name
        if icon != null:
            $Textbox/Face.texture = icon
            $Textbox/Face.show()
            #$Textbox/Label.margin_left = 200
        else:
            $Textbox/Face.texture = null
            $Textbox/Face.hide()
            for i in len(tachie_owners):
                if tachie_owners[i] == name:
                    $Textbox/Face.texture = tachie_slots[i].get_next_texture()
                    print("face texture: ", $Textbox/Face.texture)
                    $Textbox/Face.show()
                    break
            #$Textbox/Label.margin_left = 50
        $Textbox/Name.show()
    else:
        is_narration = true
        #set_dark_on_light() # For games with distinct narration/dialogue boxes
        #$Textbox/Sprite.texture = _textbox_narration
        $Textbox/Name.bbcode_text = ""
        $Textbox/Face.texture = null
        $Textbox/Face.hide()
        $Textbox/Name.hide()
        #$Textbox/Label.margin_left = 50
    if $BleepPlayer.playing and $BleepPlayer.stream:
        var stream : AudioStreamSample = $BleepPlayer.stream
        stream.loop_mode = AudioStreamSample.LOOP_DISABLED
        yield($BleepPlayer, "finished")
        stream.loop_mode = AudioStreamSample.LOOP_FORWARD
    $BleepPlayer.stream = bleep


class BacklogEntry:
    var name : String
    var icon : Texture
    var bbcode : String
    var is_narration : bool
    # warning-ignore:shadowed_variable
    # warning-ignore:shadowed_variable
    # warning-ignore:shadowed_variable
    # warning-ignore:shadowed_variable
    # warning-ignore:shadowed_variable
    static func build(name : String, icon : Texture, bbcode : String, is_narration : bool):
        var ret = BacklogEntry.new()
        ret.name = name
        ret.icon = icon
        ret.bbcode = bbcode
        ret.is_narration = is_narration
        return ret

var backlog_entry_size = 128+8*2
var block_scrollback = false
var hide_from_scrollback = false
var cutscene_paused = false

func scroll_backlog_to_end():
    $Scrollback.scroll_vertical = $Scrollback/List.rect_size.y#+$Scrollback.rect_size.y

func block_simulation():
    return cutscene_paused

var backlog_textbox_visibility_storage = false
func backlog_hide():
    cutscene_paused = false
    $ScrollbackBG.hide()
    # scrolling doesn't update properly if we hide the scroll container, so we have to emulate hiding it with modulation and input mode stuff instead
    $Scrollback.show()
    $Scrollback.modulate.a = 0.0
    $Scrollback.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $Scrollback.get_v_scrollbar().mouse_filter = Control.MOUSE_FILTER_IGNORE
    $Scrollback.get_h_scrollbar().mouse_filter = Control.MOUSE_FILTER_IGNORE
    $Scrollback/List.show()
    if backlog_shown:
        $Textbox.visible = backlog_textbox_visibility_storage
    backlog_shown = false
    print("intent: ", textbox_visibility_intent)

var backlog_shown = false
func backlog_show():
    if block_scrollback:
        return
    if $ScrollbackBG.visible:
        return
    if $Choices.visible:
        return
    backlog_shown = true
    if $BleepPlayer.stream:
        var stream : AudioStreamSample = $BleepPlayer.stream
        stream.loop_mode = AudioStreamSample.LOOP_DISABLED
    cutscene_paused = true
    backlog_textbox_visibility_storage = $Textbox.visible
    $Textbox.hide()
    $ScrollbackBG.show()
    $Scrollback.show()
    $Scrollback.modulate.a = 1.0
    $Scrollback.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $Scrollback.get_v_scrollbar().mouse_filter = Control.MOUSE_FILTER_STOP
    $Scrollback.get_h_scrollbar().mouse_filter = Control.MOUSE_FILTER_IGNORE
    $Scrollback/List.show()
    $Scrollback.force_update_transform()
    scroll_backlog_to_end()

var backlog_style = preload("res://resources/BacklogBox9patch.tres")
var backlog_style_narration = preload("res://resources/BacklogBox9patchNarration.tres")
class BacklogTextbox extends Panel:
    func _init():
        mouse_filter = Control.MOUSE_FILTER_IGNORE
    static func build(entry : BacklogEntry):
        var ret = BacklogTextbox.new()
        ret._build(entry)
        return ret
        
    var icon_holder : Control = null
    var icon : TextureRect = null
    var namelabel : RichTextLabel = null
    var label : RichTextLabel = null
    var icon_size = 120.0
    var icon_height = 120.0
    var icon_margin = Vector2(0, 1)
    func _build(entry : BacklogEntry):
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        if entry.icon:
            icon_holder = Control.new()
            icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
            icon = TextureRect.new()
            icon.texture = entry.icon
            icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
            icon.expand = true
            var tex_size = entry.icon.get_size()
            icon_height = icon_size * tex_size.y/tex_size.x
            icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
            icon_holder.add_child(icon)
            add_child(icon_holder)
            icon_holder.rect_size = Vector2(icon_size, icon_size)
            print(tex_size)
            print(icon_height)
            print(max(0.0, (icon_height - icon_size) / 2.0))
            icon.rect_size = Vector2(icon_size, icon_height)
            icon.rect_position.y = max(0.0, (icon_height - icon_size) / 2.0)
        if entry.name != "":
            namelabel = RichTextLabel.new()
            namelabel.bbcode_enabled = true
            namelabel.bbcode_text = entry.name
            namelabel.theme = preload("res://resources/BacklogTextTheme.tres")
            namelabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
            add_child(namelabel)
        
        #rect_min_size.x = 900
        rect_min_size.y = icon_size+icon_margin.y*2
        
        label = RichTextLabel.new()
        label.bbcode_enabled = true
        label.bbcode_text = entry.bbcode
        #if entry.is_narration:
        #    label.theme = preload("res://resources/BacklogTextThemeNarration.tres")
        #else:
        label.theme = preload("res://resources/BacklogTextTheme.tres")
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(label)
        
        fix_flow()
        material = CanvasItemMaterial.new()
        material.blend_mode = BLEND_MODE_MIX
        #if entry.is_narration:
        #    add_stylebox_override("panel", Manager.backlog_style_narration)
        #else:
        add_stylebox_override("panel", Manager.backlog_style)
    func fix_flow():
        #if namelabel != null or icon != null:
        #    label.margin_left = icon_size+icon_margin.x*2
        #else:
        #    label.margin_left = icon_margin.x
        label.margin_left = icon_size+icon_margin.x*2
        
        label.margin_right = -icon_margin.x
        label.margin_top = icon_margin.y
        label.margin_bottom = -icon_margin.y
        label.anchor_right = 1
        label.anchor_bottom = 1
        
        # FIXME this needs to be configurable lol
        if icon != null:
            icon_holder.rect_position.x = 2#icon_margin.x
            icon_holder.rect_position.y = icon_margin.y
            icon.rect_size = Vector2(icon_size, icon_height)
            icon.rect_position.y = max(0.0, (icon_height - icon_size) / 2.0)
            icon.rect_position.y -= icon_height*0.4
            icon.rect_scale = Vector2(4.0, 4.0)
            icon.rect_position.x = -(icon_size*4.0 - icon_size)/2.0
            icon_holder.rect_clip_content = true
        if namelabel != null:
            namelabel.rect_position.x = 4
            namelabel.rect_position.y = rect_min_size.y - 28.0
            namelabel.rect_size = Vector2(600.0, icon_size)

func make_dummy():
    var dummy = Control.new()
    dummy.mouse_filter = Control.MOUSE_FILTER_IGNORE
    dummy.rect_min_size.y = 16
    return dummy

onready var dummyA = make_dummy()

var backlog = []
func backlog_add(bbcode : String, is_narration : bool):
    if hide_from_scrollback:
        return
    if LOAD_SKIP:
        return
    
    if len($Scrollback/List.get_children()) == 0:
        $Scrollback/List.add_child(make_dummy())
    backlog.push_back(BacklogEntry.build($Textbox/Name.bbcode_text, $Textbox/Face.texture, bbcode, is_narration))
    while backlog.size() > 200:
        backlog.pop_front()
        var dead = $Scrollback/List.get_children()[1]
        dead.queue_free()
        $Scrollback/List.remove_child(dead)
    
    var new_entry = BacklogTextbox.build(backlog.back())
    $Scrollback/List.add_child(new_entry)
    scroll_backlog_to_end()
    if dummyA.get_parent() == $Scrollback/List:
        $Scrollback/List.remove_child(dummyA)
    $Scrollback/List.add_child(dummyA)

func pageflip_NVL():
    
    $Textbox/Label.bbcode_text = ""
    $Textbox/Label.visible_characters = 0
    typein_chars = 0
    

func textbox_set_bbcode(bbcode : String):
    text_has_been_added_since_loadline_update = true
    last_displayed_line = bbcode
    if skip_pressed_during_read_text and !is_line_read():
        $Skip.pressed = false
    
    backlog_add(bbcode, is_narration)
    
    #if do_logging:
    #    var logline = ""
    #    if $Textbox/Name.visible:
    #        logline += $Textbox/Name.bbcode_text + ": "
    #    logline += bbcode
    #    logfile.store_line(logline)
    
    if !$Textbox.visible or !textbox_visibility_intent:
        textbox_show()
    if text_mode_NVL:
        var old_len = $Textbox/Label.get_total_character_count()
        $Textbox/Label.append_bbcode(bbcode)
        if typein_mode:
            $Textbox/Label.visible_characters = old_len
            typein_chars = float(old_len)
            $Textbox/NextAnimHolder/NextAnim.stop()
            $Textbox/NextAnimHolder/NextAnim.frame = 0
            $Textbox/NextAnimHolder/NextAnim.play()
            $Textbox/NextAnimHolder/NextAnim.hide()
        else:
            $Textbox/Label.visible_characters = -1
            typein_chars = -1
            $Textbox/NextAnimHolder/NextAnim.stop()
            $Textbox/NextAnimHolder/NextAnim.frame = 0
            $Textbox/NextAnimHolder/NextAnim.play()
            $Textbox/NextAnimHolder/NextAnim.show()
    else:
        $Textbox/Label.bbcode_text = bbcode
        if typein_mode:
            $Textbox/Label.visible_characters = 0
            typein_chars = 0
            $Textbox/NextAnimHolder/NextAnim.stop()
            $Textbox/NextAnimHolder/NextAnim.frame = 0
            $Textbox/NextAnimHolder/NextAnim.play()
            $Textbox/NextAnimHolder/NextAnim.hide()
        else:
            $Textbox/Label.visible_characters = -1
            typein_chars = -1
            $Textbox/NextAnimHolder/NextAnim.stop()
            $Textbox/NextAnimHolder/NextAnim.frame = 0
            $Textbox/NextAnimHolder/NextAnim.play()
            $Textbox/NextAnimHolder/NextAnim.show()
    
    if is_line_read():
        $Textbox/Label.modulate = Color.yellow
    else:
        $Textbox/Label.modulate = Color.white


func textbox_clear():
    $Textbox/Label.bbcode_text = ""
    $Textbox/Icon.bbcode_text = ""
    textbox_set_identity("<<NARRATOR>>")

var env_saturation = 1.0
var env_color = Color(0.5, 0.5, 0.5)
var env_light = Color(1.0, 1.0, 1.0)

var env_transition_speed = 1.0

var env_nonce = 0
func set_env(saturation : float = 1.0, color : Color = Color(0.5, 0.5, 0.5), light : Color = Color(1.0, 1.0, 1.0)):
    env_nonce += 1
    var start_nonce = env_nonce
    var old_color = env_color
    var old_light = env_light
    var old_saturation = env_saturation
    var progress = 0.0
    while progress < 1.0:
        progress += get_process_delta_time() * env_transition_speed
        progress = clamp(progress, 0.0, 1.0)
        
        env_saturation = lerp(old_saturation, saturation, progress)
        env_color = old_color.linear_interpolate(color, progress)
        env_light = old_light.linear_interpolate(light, progress)
        
        yield(get_tree(), "idle_frame")
        if env_nonce != start_nonce:
            return
    
    env_saturation = saturation
    env_color = color
    env_light = light

var default_effect_framerate = 30

class Effect extends TextureRect:
    var size : Vector2
    var count : Vector2
    
    var framerate = 30
    
    signal finished
    func _init(_atlas : Texture, _count : Vector2):
        framerate = Manager.default_effect_framerate
        
        expand = true
        stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        
        texture = AtlasTexture.new()
        texture.atlas = _atlas
        count = _count
        texture.region = Rect2(Vector2(), texture.atlas.get_size()/count)
        
        _process(0)
    
    var progress = 0.0
    func _process(delta):
        progress += delta
        
        var total_count = count.x * count.y
        
        var frame = int(floor(progress * framerate))
        
        texture.region.position = Vector2(frame%int(count.x), floor(frame/count.x)) * texture.region.size
        
        if delta == 0.0:
            return
        
        if frame >= total_count or Manager.do_timer_skip():
            modulate.a = 0
            queue_free()
            print("normal effect finishing")
            if Manager.do_timer_skip():
                print("note: forced skip")
            emit_signal("finished")

class DummyEffect extends Node:
    signal finished
    func _process(_delta):
        queue_free()
        print("dummy effect finishing")
        emit_signal("finished")

func spawn_effect_raw(_atlas : Texture, _count : Vector2) -> Effect:
    var effect = Effect.new(_atlas, _count)
    $Scene.add_child(effect)
    effect.anchor_right = 1.0
    effect.anchor_bottom = 1.0
    return effect

func spawn_effect(name : String):
    if do_timer_skip():
        var ret = DummyEffect.new()
        $Scene.add_child(ret)
        return ret
    
    if name == "Bubble":
        return spawn_effect_raw(load("res://art/cutscene/effect/bubble.png"), Vector2(4, 4))
    elif name == "Splash":
        return spawn_effect_raw(load("res://art/cutscene/effect/splash.png"), Vector2(4, 4))
    else:
        var ret = DummyEffect.new()
        $Scene.add_child(ret)
        return ret
