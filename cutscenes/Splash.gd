extends Node
#warning-ignore-all:standalone_expression

func cutscene():
    Manager.block_saving = true
    Manager.is_splash = true
    
    if UserSettings.system_autocontinue_on_boot:
        if Manager.attempt_continue():
            return
        Manager.inform_failed_load()
    
    yield(Manager.get_tree().create_timer(1.5), "timeout")
    Manager.set_bg(preload("res://art/ui/splashA.png"), true)
    yield(Manager, "bg_transition_done")
    #yield(Manager.cutscene_timer(1.0), "timeout")
    
    Manager.set_bg(preload("res://art/ui/splashC.png"))
    yield(Manager, "bg_transition_done")
    
    yield(Manager.cutscene_timer(1.0), "timeout")
    
    Manager.fade_color = Color.white
    
    Manager.change_to("res://scenes/ui/Menu.tscn")
    
    

