extends CanvasLayer

signal done

func _ready():
    Manager.set_bg(preload("res://art/ui/title.png"), true)
    
    var _unused
    _unused = $"Buttons/New Game".connect("pressed", self, "new_game")
    
    var quicksave = File.new()
    var err = quicksave.open("user://saves/0000_quicksave.json", File.READ)
    if err == OK:
        $"Buttons/Continue".disabled = false
        _unused = $"Buttons/Continue".connect("pressed", self, "load_game")
    
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
    and get_tree().get_nodes_in_group("MenuScreen").size() == 0
    and Input.is_action_just_pressed("ui_focus_next")):
        $"Buttons/New Game".grab_focus()

var block = false

func load_game():
    if block:
        return
    block = true
    print("!!!!!!!!loading game")
    emit_signal("done")
    
    Manager.quickload()
    yield(get_tree(), "idle_frame")

func new_game():
    if block:
        return
    block = true
    EmitterFactory.emit(null, "startgame", Vector2(), "OtherSFX")
    print("!!!!!!!!new game")
    emit_signal("done")
    
    Manager.play_bgm(null, 3.0)
    yield(get_tree(), "idle_frame")
    
    Manager.change_to("res://cutscenes/Story/0-Prologue.gd")

