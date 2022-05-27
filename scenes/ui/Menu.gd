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
    


func _process(_delta):
    pass

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

