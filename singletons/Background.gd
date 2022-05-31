tool
extends TextureRect

export(Texture) var fade_texture = preload("res://art/transition/noiseburned.png")
export(Texture) var normal_map = preload("res://art/normal/cells.png")
export(float, 0.0, 4.0) var fade_contrast = 0.0
export var fade_invert = false

export var normal_strength = Vector2(0, 0)
export var normal_scale = Vector2(1.0, 1.0)
export var normal_timescale = Vector2(0.0, 0.0)
export var normal_offset = Vector2(0, 0)

var _normal_configs = [
    {"normal_strength" : Vector2(0, 0),
     "normal_scale" : Vector2(1.0, 1.0),
     "normal_timescale" : Vector2(0.0, 0.0),
    },
    {"normal_strength" : Vector2(0.15, -0.023),
     "normal_scale" : Vector2(1.0, 0.74),
     "normal_timescale" : Vector2(0.067, -0.0007),
    },
    {"normal_strength" : Vector2(0.25, 3.0),
     "normal_scale" : Vector2(0.25, 0.5),
     "normal_timescale" : Vector2(0.0, 0.2),
    },
]

var normal_config = _normal_configs[0].duplicate()
var normal_config_start  = normal_config.duplicate(true)
var normal_config_target = normal_config.duplicate(true)
var normal_config_interp = 1.0

func do_normal_config_interp(delta : float):
    normal_config_interp += delta / max(0.0001, EngineSettings.bg_fade_time)
    normal_config_interp = clamp(normal_config_interp, 0.0, 1.0)
    for prop in normal_config.keys():
        normal_config[prop] = normal_config_start[prop].linear_interpolate(normal_config_target[prop], normal_config_interp)
    if normal_config_interp < 1.0:
        if normal_config_start.normal_strength.length() == 0.0:
            normal_config.normal_scale = normal_config_target.normal_scale
        elif normal_config_target.normal_strength.length() == 0.0:
            normal_config.normal_scale = normal_config_start.normal_scale

func configure_bg_distortion(mode : int):
    mode = int(clamp(mode, 0, _normal_configs.size()-1))
    normal_config_start = normal_config.duplicate(true)
    normal_config_target = _normal_configs[mode].duplicate(true)
    normal_config_interp = 0.0
    yield(get_tree(), "idle_frame")
    if Manager.do_timer_skip():
        normal_config_interp = 1.0

var transform_1        : Transform2D = Transform2D.IDENTITY
var transform_1_target : Transform2D = Transform2D.IDENTITY
var transform_1_progress = 0.0
var transform_1_speed = 1.0
func set_transform_1(transform : Transform2D):
    transform_1        = transform
    transform_1_target = transform
    transform_1_progress = 1.0
func set_transform_1_target(transform : Transform2D, time = EngineSettings.bg_fade_time):
    transform_1 = transform_1_target
    transform_1_target = transform
    transform_1_progress = 0.0
    time = max(time, 0.0001)
    transform_1_speed = 1.0/time

var transform_2        : Transform2D = Transform2D.IDENTITY
var transform_2_target : Transform2D = Transform2D.IDENTITY
var transform_2_progress = 0.0
var transform_2_speed = 1.0
func set_transform_2(transform : Transform2D):
    transform_2 = transform
    transform_2_target = transform
    transform_2_progress = 1.0
func set_transform_2_target(transform : Transform2D, time = EngineSettings.bg_fade_time):
    transform_2 = transform_2_target
    transform_2_target = transform
    transform_2_progress = 0.0
    time = max(time, 0.0001)
    transform_2_speed = 1.0/time

func cycle_transform():
    transform_1 = transform_2
    transform_1_target = transform_2_target
    transform_1_progress = transform_2_progress

func _ready():
    if Engine.editor_hint:
        return
    material = material.duplicate()
    fadeamount = 0.0
    fade_contrast = 0.0
    
    material.set_shader_param("rectsize", rect_size * rect_scale)
    
    material.set_shader_param("texture2", null)
    material.set_shader_param("texture3", fade_texture)
    material.set_shader_param("contrast", fade_contrast)
    material.set_shader_param("texture2size", Vector2(1.0, 1.0))
    material.set_shader_param("texturesize", Vector2(1.0, 1.0))
    material.set_shader_param("fadeamount", fadeamount)
    material.set_shader_param("position", Vector2(0.0, 0.0))
    material.set_shader_param("scale", Vector2(1.0, 1.0))
    material.set_shader_param("invert", fade_invert)
    
    material.set_shader_param("normalmap", normal_map)
    material.set_shader_param("normal_strength", normal_config.normal_strength/10.0)
    var _normal_scale = normal_config.normal_scale
    if _normal_scale.x == 0:
        _normal_scale.x = 0.00001
    if _normal_scale.y == 0:
        _normal_scale.y = 0.00001
    material.set_shader_param("normal_scale", _normal_scale)
    material.set_shader_param("normal_offset", normal_offset)
    
    if !Engine.editor_hint:
        material.set_shader_param("transform_1", transform_1)
        material.set_shader_param("transform_2", transform_2)

export(Texture) var texture2 : Texture
export(float, 0.0, 1.0) var fadeamount : float
export(Vector2) var position = Vector2(0,0)
export(Vector2) var scale = Vector2(1,1)

signal transform_finished
signal transform_1_finished
signal transform_2_finished

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    if !Engine.editor_hint and Manager.block_simulation():
        return
    
    do_normal_config_interp(delta)
    
    if Engine.editor_hint:
        normal_config.normal_scale = normal_scale
        normal_config.normal_strength = normal_strength
        normal_config.normal_timescale = normal_timescale
    
    if normal_config.normal_scale.x != 0:
        normal_offset.x += -normal_config.normal_timescale.x*delta/normal_config.normal_scale.x
    else:
        normal_offset.x += -normal_config.normal_timescale.x*delta
    if normal_config.normal_scale.y != 0:
        normal_offset.y += -normal_config.normal_timescale.y*delta/normal_config.normal_scale.y
    else:
        normal_offset.y += -normal_config.normal_timescale.y*delta
    normal_offset = normal_offset.posmod(1.0)
    
    var prev_progress_1 = transform_1_progress
    var prev_progress_2 = transform_2_progress
    transform_1_progress += delta*transform_1_speed
    if !Engine.editor_hint and Manager.do_timer_skip():
        transform_1_progress = 1.0
    transform_1_progress = clamp(transform_1_progress, 0.0, 1.0)
    transform_2_progress += delta*transform_2_speed
    if !Engine.editor_hint and Manager.do_timer_skip():
        transform_2_progress = 1.0
    transform_2_progress = clamp(transform_2_progress, 0.0, 1.0)
    if prev_progress_1 < 1.0 and transform_1_progress == 1.0:
        emit_signal("transform_finished")
        emit_signal("transform_1_finished")
    if prev_progress_2 < 1.0 and transform_2_progress == 1.0:
        emit_signal("transform_finished")
        emit_signal("transform_2_finished")
    
    update_uniforms()

func update_uniforms():
    material.set_shader_param("rectsize", rect_size * rect_scale)
    
    material.set_shader_param("texture2", texture2)
    material.set_shader_param("texture3", fade_texture)
    material.set_shader_param("contrast", fade_contrast)
    if texture2:
        material.set_shader_param("texture2size", texture2.get_size())
    else:
        material.set_shader_param("texture2size", Vector2(1.0, 1.0))
    if texture:
        material.set_shader_param("texturesize", texture.get_size())
    else:
        material.set_shader_param("texturesize", Vector2(1.0, 1.0))
    material.set_shader_param("fadeamount", fadeamount)
    material.set_shader_param("position", Vector2(0.0, 0.0))
    material.set_shader_param("scale", Vector2(1.0, 1.0))
    material.set_shader_param("invert", fade_invert)
    
    material.set_shader_param("normalmap", normal_map)
    material.set_shader_param("normal_strength", normal_config.normal_strength/10.0)
    var _normal_scale = normal_config.normal_scale
    if _normal_scale.x == 0:
        _normal_scale.x = 0.00001
    if _normal_scale.y == 0:
        _normal_scale.y = 0.00001
    material.set_shader_param("normal_scale", _normal_scale)
    material.set_shader_param("normal_offset", normal_offset)
    
    var prog_1 = smoothstep(0.0, 1.0, transform_1_progress)
    var xform_1 = transform_1.interpolate_with(transform_1_target, prog_1)
    material.set_shader_param("transform_1", xform_1)
    var prog_2 = smoothstep(0.0, 1.0, transform_2_progress)
    var xform_2 = transform_2.interpolate_with(transform_2_target, prog_2)
    material.set_shader_param("transform_2", xform_2)
    #prints(xform_1, xform_2)
    #material.set_shader_param("transform_1", Transform2D.IDENTITY.scaled(Vector2(2.0, 2.0)))
    #material.set_shader_param("transform_2", Transform2D.IDENTITY.scaled(Vector2(2.0, 2.0)))
