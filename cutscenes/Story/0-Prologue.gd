extends Node
#warning-ignore-all:standalone_expression

# MirageVN's cutscene script preprocessor has some syntax restrictions.
# ----
# Basic rule:
# Keep your syntax simple and consistent. Comments should generally go on their own line. Etc.
# ----
# yield statements MUST be a single line, and should not be overly complex.
# this is because the preprocessor rewrites yield statements.
# it rewrites them so that they can be skipped during save-loading.
# in order to keep the yield statement parser simple and easy to debug,
# the following characters are forbidden in strings on yield statement lines: (){}[]#
# if you need to use a string with one of those characters in it in a yield statement,
# assign that string to a variable first.
# ----
# Dialogue must be on a single line, and be of the form:
# "name" > "dialogue text"
# Narration must be on a single line, and be of the form:
# "narration text"
# there are some cases where you can use more complex expressions, like:
# "name" > "dialogue with %s" % ["string formatting"]
# "narration with %s" % ["string formatting"]
# but such cases are fragile, and you should keep them as simple as possible
# ----
# for troubleshooting purposes, there is a human-readable description
# of the narration/dialogue preprocessing logic in singletons/CutsceneParser.gd


# assign tachie texture resources to variables to make easier to change and take up less space
# you can do this with almost any sort of non-statement expression you use in your cutscene code
# e.g. `preload("res://art/cutscene/bg/dusk bg.jpg")` etc. could also be assigned to variables
# note: in global scope, you can only assign 'const' expressions to variables
# if you need to use a non-constr exprssion, you must use `onready var` instead of `var`
# this makes it happen when the cutscene enters the scene tree instead of when it's initialized
var tachie_normal    = preload("res://art/cutscene/tachie/vn engine test tachie base.png")
var tachie_happy     = preload("res://art/cutscene/tachie/vn engine test tachie thinking smile.png")
var tachie_blink     = preload("res://art/cutscene/tachie/vn engine test tachie thinking.png")
var tachie_avoid     = preload("res://art/cutscene/tachie/vn engine test tachie avoid.png")

var tachie_remember  = preload("res://art/cutscene/tachie/vn engine test tachie remembering.png")
var tachie_smug      = preload("res://art/cutscene/tachie/vn engine test tachie smug.png")
var tachie_really    = preload("res://art/cutscene/tachie/vn engine test tachie really.png")
var tachie_confident = preload("res://art/cutscene/tachie/vn engine test tachie confident.png")

func cutscene():
    Manager.chapter_number = 0
    Manager.chapter_name = "Prologue"
    Manager.scene_number = 1
    Manager.scene_name = "???"
    
    # set the background, in "instant" mode (second argument true), so that
    # it displays under the built-in room change fader
    Manager.set_bg(preload("res://art/ui/splashA.png"), true)
    # now wait for the room change fader to finish before continuing the cutscene
    if Manager.changing_room:
        yield(Manager, "room_change_complete")
    
    # change background to plain black, then wait for it to finish
    Manager.set_bg(preload("res://art/ui/black.png"))
    yield(Manager, "bg_transition_done")
    
    # start background music
    Manager.play_bgm(preload("res://bgm/calm piano loopable.ogg"))
    
    # wait 1.0 seconds
    yield(Manager.cutscene_timer(1.0), "timeout")
    
    # set the background transition fading mask to noise
    Manager.set_bg_fade_mask(preload("res://art/transition/noisesolid.png"))
    # change to a non-black background so there's something pretty to look at
    Manager.set_bg(preload("res://art/cutscene/bg/dusk bg.jpg"))
    yield(Manager, "bg_transition_done")
    
    # display a tachie in slot 1, centered, then wait for it to finish fading in
    Manager.set_tachie(1, tachie_normal, "center")
    # make it so the identity "Guide" is associated with tachie slot 1
    # (this makes the textbox preview this tachie when "Guide" speaks)
    Manager.set_tachie_owner(1, "Guide")
    yield(Manager, "tachie_finished")
    
    # change the tachie to a confident face, then wait for it to finish fading in
    Manager.set_tachie(1, tachie_confident, "center")
    yield(Manager, "tachie_finished")
    # change the tachie to a happy face, then wait for it to finish fading in
    Manager.set_tachie(1, tachie_happy, "center")
    yield(Manager, "tachie_finished")
    
    # make "Guide" speak, then wait for user input
    "Guide" > "Welcome to MirageVN!"
    
    # change tachie back to normal
    Manager.set_tachie(1, tachie_normal, "center")
    yield(Manager, "tachie_finished")
    
    # series of dialogue statements with no changes to anything
    "Guide" > "First, a word of warning: MirageVN is very immature, so unless you're already experienced in game development, like, REAL game development, you will run into things you can't do."
    "Guide" > "MirageVN is less of a 'toolkit' to build inside of, and more of a 'base project' to flesh out."
    "Guide" > "For example: all the code related to saving/loading is there, but it's currently only used for the 'Continue' button on the main menu, and quicksave/quickloading."
    "Guide" > "If you want a real GUI for managing save data, you're gonna have to build it yourself, because I haven't gotten around to adding one yet."
    Manager.set_tachie(1, tachie_really, "center")
    yield(Manager, "tachie_finished")
    "Guide" > "Here be dragons. Bring a programmer with you. Etc."
    Manager.set_tachie(1, tachie_normal, "center")
    yield(Manager, "tachie_finished")
    "Guide" > "Second, as you may have realized if you're looking at this within Godot's editor, Godot has a specialized editor."
    "Guide" > "Godot has a learning curve. It's not in-and-running. There are weird clunky quirks to its UI. The tools take time to learn."
    "Guide" > "So if you're new to Godot, it might be good to mess around with 'real game' projects for a couple weeks before making a full length VN in MirageVN."
    
    Manager.set_tachie(1, tachie_blink, "center")
    yield(Manager, "tachie_finished")
    
    "Guide" > "Oh, one random thing. Make sure to change the project's internal name in the project settings, from MirageVN to literally anything else."
    
    Manager.set_tachie(1, tachie_really, "center")
    yield(Manager, "tachie_finished")
    
    "Guide" > "If you keep it as MirageVN then your save data will conflict with other people who keep it as MirageVN, because the internal project name determines where it's stored."
    
    Manager.set_tachie(1, tachie_normal, "center")

    
    "Guide" > "Okay, warning over. Here's a quick demo of some random engine features."
    
    # narration
    "Smooth tachie handling"
    
    # fade tachie out, wait; fade it in on the left; 
    Manager.set_tachie(1, null)
    yield(Manager, "tachie_finished")
    # fade it in on the left, wait, then tell it to move to the right, then wait again
    Manager.set_tachie(1, tachie_normal, "left")
    yield(Manager, "tachie_finished")
    Manager.set_tachie(1, tachie_normal, "rightish")
    yield(Manager, "tachie_finished")
    
    # narration
    "Tachie animation"
    
    # hide textbox, wait for it to disappear before continuing
    # (in this case, `Manager.textbox_hide()` returns the name of the signal to wait for)
    # (not all functions do this. this is not a general pattern.)
    yield(Manager, Manager.textbox_hide())
    
    # place one tachie on each side of the screen, wait for them to go there and/or fade in
    Manager.set_tachie(1, tachie_avoid, "farrightish")
    Manager.set_tachie(2, tachie_blink, "farleftish")
    Manager.set_tachie_owner(2, "Guide B")
    # when waiting for multiple tachie at once, you should yield for all of their signals.
    # all of them in a group, one after the other, after calling all tachie transitions/animations.
    # otherwise, you might have signal buildup, triggering other yields later when unwanted.
    # if you only yield on one of them, weird stuff might happen when loading saves or skipping
    yield(Manager, "tachie_finished")
    yield(Manager, "tachie_finished")
    
    
    # make each tachie play an animation. wait for each animation to finish one at a time.
    Manager.do_tachie_animation(1, "bounceup")
    yield(Manager, "tachie_finished")
    Manager.set_tachie_zoom(2, 1.4)
    Manager.set_tachie_offset(2, Vector2(0, 100))
    yield(Manager, "tachie_zoom_finished")
    Manager.do_tachie_animation(2, "dip")
    yield(Manager, "tachie_finished")
    Manager.set_tachie_zoom(2, 1.0)
    Manager.set_tachie_offset(2, Vector2())
    yield(Manager, "tachie_zoom_finished")
    
    # play some sound effects
    Manager.sfx(preload("res://sfx/wet.wav"))
    "Sound effects"
    
    Manager.sfx(preload("res://sfx/slide sound.wav"))
    "Yep, sound effects"
    
    # turn on background distortion
    # (this is instant)
    # background distortion is defined in the `_normal_configs` variable in singletons/Manager.gd
    # you can test values out in the 2D editor of the Manager scene
    # with the `HUD/Scene/Background` node selected in the scene tree editor
    # by editing the relevant values in the Inspector panel.
    Manager.configure_bg_distortion(1)
    
    Manager.set_tachie(1, null)
    Manager.set_tachie(2, null)
    yield(Manager, "tachie_finished")
    yield(Manager, "tachie_finished")
    
    "Background distortion"
    
    # change distortion normal map
    # (this is instant)
    Manager.set_bg_normal_map(preload("res://art/normal/noisy.png"))
    Manager.configure_bg_distortion(2)
    
    "No, seriously, background distortion"
    "(unless you're TRYING to make stuff look weird, you don't want to transition from one mode to another without transitioning to mode zero first; this is just for demonstration)"
    
    # disable background distortion (by using configuration 0) (this is instant)
    Manager.configure_bg_distortion(0)
    
    "Background fading masks"
    
    # vertical shutter
    Manager.set_bg_fade_mask(preload("res://art/transition/shuttervert.png"), true)
    Manager.set_bg(preload("res://art/ui/black.png"))
    yield(Manager, "bg_transition_done")
    
    # twin horizontal shutters
    Manager.set_bg_fade_mask(preload("res://art/transition/horiz_twin.png"), true)
    Manager.set_bg(preload("res://art/cutscene/bg/hill bg.jpg"))
    yield(Manager, "bg_transition_done")
    
    # flat
    Manager.set_bg_fade_mask(preload("res://art/transition/flat.png"), true, 0.0) # 0.0 is zero contrast
    Manager.set_bg(preload("res://art/cutscene/bg/dusk bg.jpg"))
    yield(Manager, "bg_transition_done")
    
    # radial
    Manager.set_bg_fade_mask(preload("res://art/transition/radial.png"), true)
    Manager.set_bg(preload("res://art/cutscene/bg/night bg.jpg"))
    yield(Manager, "bg_transition_done")
    
    # bring back tachie
    Manager.set_tachie(1, tachie_happy, "farrightish")
    Manager.set_tachie(2, tachie_blink, "farleftish")
    yield(Manager, "tachie_finished")
    yield(Manager, "tachie_finished")
    
    
    # set environmental coloration:
    # 70% saturation
    # blueish-gray "overlay" effect (https://en.wikipedia.org/wiki/Blend_modes#Overlay)
    # blueish multiply effect
    Manager.set_env(0.7, Color(0.4, 0.45, 0.5), Color(0.8, 0.9, 1.0))
    "Environmental coloration (saturation, overlay, multiply)"
    
    Manager.set_bg_fade_mask(preload("res://art/transition/flashblurfudge2.png"), true)
    Manager.set_bg(preload("res://art/cutscene/bg/dusk bg.jpg"))
    yield(Manager, "bg_transition_done")
    
    Manager.set_env()
    
    Manager.set_tachie(1, tachie_smug, "center")
    Manager.set_tachie(2, null)
    yield(Manager, "tachie_finished")
    yield(Manager, "tachie_finished")
    
    Manager.play_bgm(preload("res://bgm/dark piano.ogg"))
    
    "Guide" > "Pretty basic stuff, right? There's a tutorial cutscene with more stuff after this one."
    Manager.set_tachie(1, tachie_normal, "center")
    yield(Manager, "tachie_finished")
    "Guide" > "Oh. This next one's important. Let me explain it first."
    "Guide" > "A lot of VN engines have a problem where, when tachies fade from one version to the next..."
    "Guide" > "You either get a semi-transparent moment in the middle of the transition, or you get both versions fully opaque in the middle."
    "Guide" > "It's a blending math thing. MirageVN handles it correctly. Watch closely. I'll do it in slow motion."
    
    "Correct tachie fading"
    
    Manager.textbox_hide()
    yield(Manager, "textbox_hidden")
    
    # setting engine timescale to make tachie fading run in slow motion
    # `Engine.time_scale` affects anything that uses the _process() function's `delta` variable
    # which is almost everything
    Engine.time_scale = 0.2
    
    # fade to an inverted tachie, then fade back
    Manager.set_tachie(1, tachie_normal, "center")
    Manager.set_tachie_next_flipped(1)
    yield(Manager, "tachie_finished")
    Manager.set_tachie(1, tachie_smug, "center")
    Manager.set_tachie_next_flipped(1, false)
    yield(Manager, "tachie_finished")
    
    Engine.time_scale = 1.0
    
    "Guide" > "You have no idea how annoying that was to implement."
    
    Manager.set_tachie(1, tachie_normal, "center")
    yield(Manager, "tachie_finished")
    
    Manager.set_bg_fade_mask(preload("res://art/transition/flat.png"), true, 0.0) # 0.0 is zero contrast
    Manager.set_bg(preload("res://art/ui/black.png"))
    yield(Manager, "bg_transition_done")
    yield(Manager, Manager.textbox_show())
    
    "Guide" > "Anyways, this is how you move to a new cutscene script file. Set Manager.next_scene to its path and then let the function return out the bottom."
    
    Manager.set_tachie(1, tachie_remember, "center")
    yield(Manager, "tachie_finished")
    
    "Guide" > "It's probably OK to do this inside of a branch and return explicitly, but I did not test doing so. Your mileage may vary."
    
    Manager.play_bgm(null) # fade bgm out while changing scenes
    Manager.next_scene = "res://cutscenes/Story/1-1-Test.gd"
    
