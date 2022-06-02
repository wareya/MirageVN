extends Control

func _gui_input(event):
    if event.is_action_pressed("m1"):
        Manager.m1_pressed = true
