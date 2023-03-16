# MirageVN

<p align="center"><img src='https://user-images.githubusercontent.com/585488/170622103-1df90280-e630-40ef-9441-25461343b3fa.png' width=640></p>

MirageVN is an experimental VN engine built on top of Godot 3.

As it is experimental software, it is missing a lot of creature comforts that VN engines typically have, and leaves many things up to the user to finish implementing. It is also very immature, so there are some common things that it does not yet support, and there are a lot of rough edges.

Because of MirageVN's immaturity, anything can change at any time. If you start a serious project, keep a local backup copy of the base project to reference later, in case the published version of MirageVN changes from how your project's copy works.

But all of the truly "difficult" VN-specific functionality is there.

## Features

- Built on mature, widely used technology (Godot). **Not bespoke**!
- Proper transitions for almost everything, including for tachie (standing sprites)
- Built-in animations for tachie
- Environment coloring for tachie
- Choices, saving, skip-until-unread, auto, a working backlog, background transitions/panning/zoom, etc.
- *Most* of the cutscene-scripting-related things you'd expect any VN engine to have
- Everything Godot supports, including WYSIWYG editing for GUIs
- Hot reloading mid-cutscene for rapid experimentation (note: you need to quicksave and quickload)
- Built-in settings manager and save data manager, with things like save locking and save memos
- Quicksave backups
- Autosaves

Because MirageVN is a base project, not a black box, it's very easy to disable or remove features that you don't want.

Beware, though, that MirageVN is still experimental and immature, so a lot of creature comforts are missing. However, the difficult and fragile parts are all there.

Useful features MirageVN does **NOT** currently have, and that you will need to build yourself if you need them:

- Gallery
- Automatic voice playback (and related things like voice replay)
- Rewinding via backlog
- Facial animation
- Expression overlays (expression variations need to be full independent images right now)
- Ruby text

Known issues:

- Some things may not be possible to do purely with keyboard or controller inputs; if you find a specific example, please report it, I will fix it ASAP
- Godot doesn't support mixed-DPI setups 100%; I have a 1x DPI scale main monitor, and if I drag godot projects onto my 1.25x DPI scale monitor, they end up blurry
- While window resizing results in sharp text and sprites, the project is not truly base-resolution-independent; changing the default window resolution away from 720p will slightly break how things are positioned
- Speaker face display on the textbox and in the backlog are a huge hack and you will probably have to replace or heavily edit the relevant code if you make a complex game
- Tachie may not render properly in GLES2 mode

## How to use

### Getting Started

[Download the repository](https://github.com/wareya/MirageVN/archive/refs/heads/main.zip) into a new folder/directory somewhere on your system.

[Download the newest version of Godot 3](https://godotengine.org/download/3.x/windows/) on a computer and place it somewhere useful.

If Godot 4 is released at the time you're reading this, *don't use it, MirageVN is not compatible with Godot 4 yet*. Use Godot 3. Godot 3.4.4 is an example of a version of Godot 3.

(You can find Godot's user documentation [here](https://docs.godotengine.org/en/stable/). Godot's documentation is very useful, unlike *some* open-source software.)

Run Godot. This will open up Godot's project manager. Click "Import" and navigate to the folder you downloaded this repository to. Import and edit.

You will now be inside of MirageVN.

### Running the demo project

Press the "play" button in the top right corner of the editor to launch the demo project. Feel free to read through it, but beware that the second cutscene expects you to find your way around the editor and tinker with its cutscene code.

### Cutscene scripting documentation

Barebones cutscene scripting docs: https://github.com/wareya/MirageVN/wiki/Cutscene-Scripting-Documentation

### Tour of Godot's UI and of the demo project

In the editor, find and click through the File System panel to get an idea of what the project's file structure looks like.

Open `res://scenes/ui/Menu.tscn` and make sure that the "2D" context button at the top of Godot's editor is active. This is the scene that contains the engine's main menu. In the Scene panel, you should see a scroll-shaped icon next to the `Menu` node. This tells you that the node has a script attached. Click on the scroll-shaped icon. This should activate the "Script" context button at the top of Godot's editor and open up the `Menu.gd` script in Godot's script editor. This is what gdscript code looks like. gdscript is godot's custom python-inspired programming language, designed specifically for writing game code. (Like python, indentation is meaningful.)

Navigate to `res://cutscenes/Splash.gd` and open it. This will open the `Splash.gd` script in the script editor. The currently-open script, and the list of scripts in the script editor, have nothing to do with the scene currently open in the tab list of open scenes. This is one of Godot's clunky editor UI quirks. It'll take some time to get used to all of Godot's editor quirks, so I recommend spending some time with small "real game"-style projects before trying to make a full-fledged VN with MirageVN.

`Splash.gd` is the cutscene script responsible for the splash screen, i.e. "logo" that fades in and out when you run the demo project. That's right, it's a cutscene script, in the exact same format as full-blown VN scenes. Uncomment the commented-out timer line and re-run the demo project. Observe that it takes longer for the splash screen to fade in.

Navigate to `res://cutscenes/Story/0-Prologue.gd` and open it.

It starts with a giant wall of comments giving warnings about the cutscene preprocessor. MirageVN's cutscene scripts are NOT pure gdscript code; they run through an algorithm that replaces bare strings with the complicated code necessary to display text on screen, and yield statements with ones that are save-friendly. If you get too creative with your syntax, this algorithm might break.

Scroll down and skim the cutscene. This is essentially what a typical MirageVN cutscene script looks like, animations and transitions and all. In this particular cutscene script, there are comments explaining most of what's going on, and some common pitfalls. The next cutscene script, `1-1-Test.gd`, comments on fewer things, but the comments that it *does* have are much more detailed and stern.

## Getting narration/dialogue into the right format.

MirageVN's cutscene syntax was designed with one goal in mind: make it *straightforward* to get lots of text from a nametagged document into a cutscene script, working, as fast as possible. *Then* you can go in and do the tedious-but-hard-to-automate process of adding in the commands for things like tachie (standing sprite) placement, background transitions, music, sound effects, etc.

The format I use to write my narration/dialogue scripts looks like this:

```
Guide: Hey, what's up?
Reed: Oh, nothing, just, y'know...

He wasn't really feeling it.
Can't really blame him.

Guide: It's okay, I understand.
Reed: Yeah.
Reed: Hey, your tail piece is folded.
Guide: Oh, thanks.
```

The equivalent MirageVN cutscene script code would look like:

```
"Guide" > "Hey, what's up?"
"Reed" > "Oh, nothing, just, y'know..."

"He wasn't really feeling it."
"Can't really blame him."

"Guide" > "It's okay, I understand."
"Reed" > "Yeah."
"Reed" > "Hey, your tail piece is folded."
"Guide" > "Oh, thanks."
```

Dialogue lines take the form `"Name" > "Line"`, and narration lines take the form `"Line"`. There is no semicolon.

You can convert from the first format to the second format with [this tool](https://jsfiddle.net/2sp486tm/).

Note: if you have any colons in narration, this tool will interpret the first one per line as marking a dialogue nametag. These should be few enough in number that you can fix them manually. If they're not, you can edit the `if (where < 0)` in the JavaScript section to be something like `if (where < 0 || where > NUMBER)` where you replace NUMBER with the maximum nametag length in your script (plus a few if you use spaces at the end of your nametags); this will reduce the number of colons it detects as nametag markers.

Note 2: In Godot's script editor, you can indent or unindent entire sections of code by multi-line selecting them and pressing tab or shift-tab. You can do this to make Godot stop complaining about the indentation being wrong.

**WARNING**: MirageVN's code uses spaces for indentation, because it's what I use. Godot defaults to using "hard tabs" for indentation, with spaces being a non-default editor option. This discrepancy may cause problems for you. You can convert an entire script file to be a consistent indentation type with the `Edit -> Convert Indent to (Spaces/Tabs)` menu item in Godot's script editor. This will fix your problems.

## Credits / License

Aside from the background images, which were made available by their creators under the Creative Commons Zero license on Flickr (at time of obtainment); [some effect images](https://opengameart.org/content/explosion-effects-and-more), which were made available by their creator under the Creative Commons Zero license (at time of obtainment); built-in Godot project related files like `export_presets.cfg`; some autogenerated shaders; and the included fonts, which have their licenses next to them (OFL); everything in this project was made by me.

Everything made by me in this project, and everything that I obtained under the Creative Commons Zero license, is hereby released under the Creative Commons Zero license. You can use it all for any purpose without crediting me or doing anything special whatsoever. LICENSE.txt, a copy of the Creative Commons Zero 1.0 legal code, hereby applies to all relevant files.

In short: you can use this project however you want and do whatever you want with it (except for keeping other people from using it), almost as if you'd made it yourself.

However, keep in mind that Godot itself is licensed under the MIT license, so when you release a game/VN based on this project, you need to include its license texts alongside your game/VN in some form. The MIT license is permissive and not 'viral'; it does not restrict what you're allowed to do with your own code, or with MirageVN code. All you need to do is include the license text. MirageVN does this by default, on the settings screen. If you remove the license button from the settings screen or change its contents, you might need to add Godot license data back in somewhere else. For full instructions on complying with the licenses of Godot and its dependencies, see [this page](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html) and [this page](https://godotengine.org/license).

The music under the bgm directory uses virtual instruments that were not created by me. I have the right to use these virtual instruments and treat works produced using them as my own, but I do not own the copyright to them themselves. The recordings/files themselves are still available under the CC0, but sampling their raw data in certain ways might violate the copyright of the creators of said virtual instruments, depending on how your local legal jurisdiction handles certain edge cases in music copyright law. Nothing else in this project has such caveats. (FLAC versions of the music are available on request if I still have them when you ask.)
