extends CanvasLayer

var sysdata
func _ready():
    Manager.set_bg(preload("res://art/ui/title.png"), true)
    
    sysdata = Manager.load_sysdata()
    
    var _unused
    _unused = $"Buttons/New Game".connect("pressed", self, "new_game")
    
    var dir = Directory.new()
    if "last_accessed_save" in sysdata:
        if dir.file_exists(sysdata["last_accessed_save"]):
            $"Buttons/Continue".disabled = false
            _unused = $"Buttons/Continue".connect("pressed", self, "continue_game")
    
    if $"Buttons/Continue".disabled:
        if "latest_saves" in sysdata:
            for f in sysdata["latest_saves"]:
                if dir.file_exists(f):
                    $"Buttons/Continue".disabled = false
                    _unused = $"Buttons/Continue".connect("pressed", self, "continue_game")
                    break
    
    yield(get_tree(), "idle_frame")
    if Manager.fading:
        yield(Manager, "fade_completed")
    Manager.play_bgm(preload("res://bgm/excited music.ogg"))
    
    _unused = $"Buttons/Settings".connect("pressed", Manager, "settings")
    _unused = $"Buttons/Load Data".connect("pressed", self, "load_screen")

func load_screen():
    if get_tree().get_nodes_in_group("MenuScreen").size() > 0:
        return
    var screen = preload("res://scenes/ui/SaveDataManager.tscn").instance()
    screen.mode = "load"
    screen.save_disabled = true
    get_tree().get_root().add_child(screen)

func _process(_delta):
    if ($Buttons.get_focus_owner() == null
    and get_tree().get_nodes_in_group("MenuScreen").size() == 0):
        $"Buttons/New Game".grab_focus()

var block = false

func continue_game():
    if block:
        return
    block = true
    
    var dir = Directory.new()
    
    if "last_accessed_save" in sysdata:
        if dir.file_exists(sysdata["last_accessed_save"]):
            var data = Manager.load_data(sysdata["last_accessed_save"])
            if data:
                Manager.load_from_dict(data)
                return
    
    if "latest_saves" in sysdata:
        for f in sysdata["latest_saves"]:
            if dir.file_exists(f):
                var data = Manager.load_data(f)
                if data:
                    Manager.load_from_dict(data)
                    return
    
    Manager.inform_failed_load()

func new_game():
    if block:
        return
    block = true
    EmitterFactory.emit(null, "startgame", Vector2(), "OtherSFX")
    #print("!!!!!!!!new game")
    
    Manager.play_bgm(null, 3.0)
    yield(get_tree(), "idle_frame")
    
    Manager.change_to("res://cutscenes/Story/0-Prologue.gd")

