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
# (see: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html)
# but such cases are fragile, and you should keep them as simple as possible
# ----
# for troubleshooting purposes, there is a human-readable description
# of the narration/dialogue preprocessing logic in singletons/CutsceneParser.gd

func cutscene():
    Manager.chapter_number = 1
    Manager.chapter_name = "Test Chapter"
    Manager.scene_number = 1
    Manager.scene_name = "Test Scene"
    
    # now wait for the room change fader to finish before continuing the cutscene
    if Manager.changing_room:
        Manager.set_bg(preload("res://art/cutscene/bg/grass bg.jpg"), true) # true in second argument = instant
        yield(Manager, "room_change_complete")
    else:
        Manager.set_bg(preload("res://art/cutscene/bg/grass bg.jpg"))
        yield(Manager, "bg_transition_done")
    
    Manager.play_bgm(preload("res://bgm/happy music loopable.ogg"))
    
    
    # WARNING ABOUT CUSTOM SAVE DATA:
    # save loading works by fast-forwarding the cutscene to where the player saved them
    # when loading saves begins, Manager.custom_save_data is reset to what it was when the scene started
    # when loading saves finishes, it's forcibly set to what it was when the player saved
    # do not put randomly-generated data into Manager.custom_save_data mid-cutscene and then branch on it later in the same cutscene
    # if you do, some saves will fail to load (because of going down a different branch than the player did)
    # if you *must*, then you need to generate it deterministically from something that already exists in Manager.custom_save_data
    # alternatively, generate the random data as the very last thing in the cutscene
    # and then immediately switch to a new cutscene script to do the branching
    
    # ANOTHER WARNING ABOUT CUSTOM SAVE DATA:
    # anything you put into Manager.custom_save_data must be serializable as JSON
    # (https://docs.godotengine.org/en/stable/classes/class_json.html)
    # non-JSON-serializable types will fail to save to disk
    # for example: JSON doesn't support ints or floats as dictionary keys. only strings.
    # so any ints or floats in dictionary keys will be converted to strings on save.
    # so, on saving,
    # {0: null, 1: 914398, "1": 13}
    # will turn into (on disk)
    # {"0": null, "1": 914398, "1": 13}
    # this is obviously bad, so remember to only put JSON-serializable data into custom_save_data!
    # (godot doesn't do duplicate keys; the in-memory representation after loading will only have
    #  a single "1" element)
    
    
    if not "test_flag" in Manager.custom_save_data:
        Manager.custom_save_data["test_flag"] = 0
    
    Manager.custom_save_data["test_flag"] += 3
    
    if Manager.custom_save_data["test_flag"] == 3:
        "This is your first time through this scene, huh? test_flag is set to %s" % [Manager.custom_save_data["test_flag"]]
    else:
        "Second time around? %s" % [Manager.custom_save_data["test_flag"]]
    
    yield(Manager, Manager.textbox_hide())
    
    Manager.set_NVL_mode()
    
    "NVL mode test. "
    "Second sentence on same line test.\n\n"
    "Spaced-out new line test.\n\n"
    "Really long line to see what happens with linewrapping test what can I write about here how about the weather man it's really humid here it's kind of a drag. That's not long enough I need to make it longer. "
    "Additional sentence on same line.\n\n"
    "Check what's going on with the backlog BTW. It's still ADV style. Probably not going to make an NVL-style one. Switching between the two would be too hard. "
    "Try not to put too much text in a single 'click' of NVL text or it might break the backlog.\n\n"
    "BTW quicksave and quickload here and watch the entire page re-type itself. Tell me if this is a bug or a feature."
    
    Manager.pageflip_NVL()
    
    "New page."
    
    yield(Manager, Manager.textbox_hide())
    
    Manager.set_ADV_mode()
    
    "Back to ADV mode."
    
    "Background zoom test"
    
    # unlike background transitions,
    # you often want to keep reading while a background pan happen
    # so background pans don't hide the textbox
    # in this case, we're Showing Off background panning, so we hide the textbox explicitly
    yield(Manager, Manager.textbox_hide())
    
    # set bg transform to centered, full scale
    Manager.set_bg_transform_1(Vector2(0.0, 0.0), Vector2(1.0, 1.0))
    # transition bg transform to looking slightly up, zoomed in 2x
    # Vector2(0.0, 0.25) is coordinates where 0.25 means 25% of the background size upwards (y axis)
    # Vector2(2.0, 2.0) means 200% zoom (2x in each dimension)
    Manager.set_bg_transform_1_target(Vector2(0.0, 0.25), Vector2(2.0, 2.0))
    yield(Manager, "bg_transform_1_finished")
    
    Manager.set_bg()
    # transition the pre-transition bg to looking slightly down
    Manager.set_bg_transform_1_target(Vector2(0.0, -0.25), Vector2(2.0, 2.0))
    # make the post-transition bg look from left to right
    Manager.set_bg_transform_2(Vector2(-0.5, 0.0), Vector2(2.0, 2.0))
    Manager.set_bg_transform_2_target(Vector2(0.5, 0.0), Vector2(2.0, 2.0))
    yield(Manager, "bg_transform_2_finished")
    
    Manager.set_bg_transform_2(Vector2(0.0, 0.0), Vector2(1.0, 1.0))
    
    Manager.set_bg()
    yield(Manager, "bg_transition_done")
        
    Manager.screen_shake_start()
    "Screen shake"
    Manager.screen_shake_stop()
    
    # if "test_data" variable doesn't exist in custom save data, create it and set it to something distinctive
    if not "test_data" in Manager.custom_save_data:
        Manager.custom_save_data["test_data"] = "Hi I'm a string from before the overlay effects"
    # print some narration with that variable in it
    # see: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html
    "Quicksave and quickload now and see this string (should not change): %s" % [Manager.custom_save_data["test_data"]]
    "(If you went through this cutscene once before, that should have been the post-choice-branch version of the string)"
    
    "Overlay effects and choices"
    
    # show choice picker
    var chosen = Manager.choice(["Bubble", "Splash"])
    # when loading saves, Manager.choice() returns the choice right away, without showing the picker
    # in that case, it returns non-null.
    # otherwise, we have to wait for the "choice_finished" signal to get the picked choice
    # (yes, signals can transmit values)
    if chosen == null:
        chosen = yield(Manager, "choice_finished")
    
    
    # WARNING ABOUT CHOICES AND SAVES
    # the list of choices that a user has chosen up to the given point is stored in the save data as
    # literal text, not as numbers. so, if you had a typo in a choice in a previous version of your
    # game/VN, and you later updated it to not have a typo in it, then when loading saves, the value
    # returned by Manager.choice() may be the version with the typo in it.
    # FOR EXAMPLE:
    # pretend that there was an early version of this tutorial where "Bubble" was typo'd as
    # "Buble". In order to support saves from that earlier version, this script would have to check
    # for the old version and map it to the new version.
    # if chosen == "Buble":
    #     chosen = "Bubble"
    
    
    # different branches for different choices
    if chosen == "Bubble":
        yield(Manager, Manager.textbox_hide())
        yield(Manager.spawn_effect("Bubble"), "finished")
        Manager.custom_save_data["test_data"] = "String from bubble branch"
        "Yep that was a bubble (quicksave and quickload here to see that saving after choices works)"
    else:
        yield(Manager, Manager.textbox_hide())
        yield(Manager.spawn_effect("Splash"), "finished")
        Manager.custom_save_data["test_data"] = "String from splash branch"
        "Yep that was a splash (quicksave and quickload here to see that saving after choices works)"
    "(from https://opengameart.org/content/explosion-effects-and-more)"
    "TODO: add a setting for additive blending for effects"
    
    "Quicksave and quickload now and see this string (should not change): %s" % [Manager.custom_save_data["test_data"]]
    
    
    
    "You can resize the window and the text should remain sharp at almost any resolution."
    "The text bounces around while resizing because of a godot bug. See https://github.com/godotengine/godot/issues/56399"
    "You can press f4 to return the window to its exact original resolution."
    "If you don't want the window to be resizable, you can disable window resizing in the project options."
    
    
    
    "Unrelated: open this cutscene up in Godot's script editor. It's cutscenes/Story/1-1-Test.gd in the FileSystem panel."
    "Then read the below sections in the editor before advancing any further ingame."
    "If you do not need to retain save file compatibility between updates, you don't need to worry about the following section."
    
    # Saves are based on narration/dialogue line number.
    # The cutscene parser tracks this number automatically and adds the relevant logic.
    # But when you add or delete lines, the number will desynchronize, causing old saves to load in the wrong place.
    # There's fixes for that, though!
    
    # EXPLANATION:
    # the LINE_DELETED_HERE directive can be above or below a commented-out or deleted line of dialogue or narration.
    # if you delete a line without adding a LINE_DELETED_HERE directive, old saves won't load properly.
    # the directive must have the same level of indentation as the context it is found in.
    # LINE_DELETED_HERE directives are only necessary for compatibility with old save data.
    # if you are breaking compatibility with old save data, you do not need to use these directives.
    "This line starts out uncommented. Quicksave on this line, then comment it out and follow the instructions in the below comment. Then quickload."
    # change the below ___ to LINE_DELETED_HERE
    # such that the entire line is `    #### LINE_DELETED_HERE`
    #### ___
    "End up here instead of breaking terribly? Good!"
    
    
    
    # EXPLANATION:
    # the LINE_ADDED_FORCE_NEXT_LINE_NUM directive must be immediately before any newly-added line of dialogue or narration.
    # you need one for each such new line, and each LINE_ADDED_FORCE_NEXT_LINE_NUM should be immediately before its corresponding new line.
    # the directive must have the same level of indentation as the context it is found in.
    # LINE_ADDED_FORCE_NEXT_LINE_NUM directives are only necessary for compatibility with old save data.
    # if you are breaking compatibility with old save data, you do not need to use these directives.
    # this directive has a number in it. the number should be a unique large number. a random six-digit number will work fine, as long as you don't have 100000 or more lines per cutscene file.
    "Now let's test out adding new lines not breaking existing saves."
    "Read this section of this cutscene in Godot's script editor for instructions."
    # change the below ___ to LINE_ADDED_FORCE_NEXT_LINE_NUM
    # such that the entire line is `    #### LINE_ADDED_FORCE_NEXT_LINE_NUM 914381`
    #### ___ 914381
    #"This line starts out commented-out. Advance to the below line, then quicksave. Then uncomment this line and follow the above instructions. Then quickload."
    "AFTER reading the instructions in the above commented-out line, quicksave here. Then follow the instructions in the above commented-out line. Then load your quicksave. You should end up on this line."
    "By using the LINE_ADDED_FORCE_NEXT_LINE_NUM directive, adding new lines to a scene doesn't create issues for old saves."
    
    
    "...What happens if you add a line, publish an update, then delete it again in another update?"
    "Instead of LINE_DELETED_HERE, use the LINE_DELETED_FORCE_LINE_NUM directive. It will cause saves with the given line number to load there."
    "The LINE_DELETED_FORCE_LINE_NUM directive has the same syntax as the LINE_ADDED_FORCE_NEXT_LINE_NUM directive."
    
    
    "Using the above three directives should be considered a last resort."
    "For the sake of your players and readers, and your own sanity, you should avoid adding or deleting lines in updates unless it's absolutely necessary."
    "It's better to replace troublesome lines with innocuous ones than to delete them."
    "And it's better to add new scenes or lengthen existing lines than to add new lines to existing scenes."
    
    
    "If you have edited this script while playing it, quicksave and quickload here to avoid hitting a Godot bug when the scene finishes. Then don't edit it until it finishes."
    "End of tutorial. This scene will loop back into itself."
    
    
    # come back to this scene
    Manager.next_scene = "res://cutscenes/Story/1-1-Test.gd"
    
