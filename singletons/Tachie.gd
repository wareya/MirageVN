tool
extends TextureRect
class_name Tachie

var _transparent = preload("res://art/ui/transparent.png")

func _ready():
    if Engine.editor_hint:
        return
    material = material.duplicate()
    material.set_shader_param("texture2", texture2)
    material.set_shader_param("texture2size", Vector2(1.0, 1.0))
    material.set_shader_param("texturesize", Vector2(1.0, 1.0))
    material.set_shader_param("fadeamount", anim_state.texfade)
    #var size = rect_size * rect_scale
    material.set_shader_param("rectsize", rect_size * rect_scale)
    material.set_shader_param("position", offset + position * Vector2(1, scale_factor))
    material.set_shader_param("scale", Vector2(scale, scale) * scale_factor)
    
    material.set_shader_param("flipx_1", flip_first)
    material.set_shader_param("flipx_2", flip_second)
    
    material.set_shader_param("mip_hint", get_viewport_ratio())
    
    if !Engine.editor_hint:
        material.set_shader_param("env_saturation", Manager.env_saturation)
        material.set_shader_param("env_color", Manager.env_color)
        material.set_shader_param("env_light", Manager.env_light)
    else:
        material.set_shader_param("env_saturation", 1.0)
        material.set_shader_param("env_color", Color(0.5, 0.5, 0.5))
        material.set_shader_param("env_light", Color(1.0, 1.0, 1.0))

export(Texture) var texture2 : Texture = _transparent
export(Vector2) var position = Vector2(0,0)
export(float, 0.0, 5.0) var scale = 2.0

var scale_factor = 1.0
var scale_factor_target = 1.0

var flip_first  = false
var flip_second = false

var offset = Vector2()
var offset_target = Vector2()

func get_viewport_ratio():
    #var outer_size = get_viewport().size
    var outer_size = OS.get_real_window_size()
    var ratio_x = outer_size.x / get_viewport().get_visible_rect().size.x
    var ratio_y = outer_size.y / get_viewport().get_visible_rect().size.y
    var ratio = min(ratio_x, ratio_y)
    return ratio

func set_next_flipped(flipped : bool):
    flip_second = flipped

func update_uniforms():
    if !visible:
        return
    if !Engine.editor_hint:
        #print("----")
        #print(get_viewport_rect())
        #print(get_viewport().size)
        #var ratio = get_viewport_ratio()
        #print(ratio)
        pass
    
    if texture2:
        material.set_shader_param("texture2", texture2)
        material.set_shader_param("texture2size", texture2.get_size())
    else:
        material.set_shader_param("texture2", _transparent)
        material.set_shader_param("texture2size", Vector2(1.0, 1.0))
    
    if texture:
        material.set_shader_param("texturesize", texture.get_size())
    else:
        material.set_shader_param("texturesize", Vector2(1.0, 1.0))
    
    if anim_state:
        material.set_shader_param("fadeamount", anim_state.texfade)
        modulate.a = anim_state.alpha
        material.set_shader_param("rectsize", rect_size * rect_scale)
        material.set_shader_param("position", offset + anim_state.pos * Vector2(1, scale_factor))
        material.set_shader_param("scale", Vector2(anim_state.scale, anim_state.scale) * scale_factor)
    
    material.set_shader_param("flipx_1", flip_first)
    material.set_shader_param("flipx_2", flip_second)
    
    material.set_shader_param("mip_hint", get_viewport_ratio())
    
    if !Engine.editor_hint:
        material.set_shader_param("env_saturation", Manager.env_saturation)
        material.set_shader_param("env_color", Manager.env_color)
        material.set_shader_param("env_light", Manager.env_light)
    else:
        material.set_shader_param("env_saturation", 1.0)
        material.set_shader_param("env_color", Color(0.5, 0.5, 0.5))
        material.set_shader_param("env_light", Color(1.0, 1.0, 1.0))

var anim_default = {
  "pos" : EngineSettings.tachie_anim_default_pos,
  "scale" : EngineSettings.tachie_anim_default_scale,
  "alpha" : 1.0,
  "texfade" : 0.0,
}
var anim_from = anim_default.duplicate()
var anim_to = anim_default.duplicate()
var anim_state = anim_default.duplicate()
var anim_progress = 0

func _anim_bounce():
    var x : float = anim_progress
    #var bounce = (x*(x-1)*(x-2))*2.5
    var bounce = sin((x + x*x*x)*PI) * (1-x) * 1.5
    anim_state.pos.y += bounce*35

func _anim_bounceup():
    # same but up
    var x : float = anim_progress
    var bounce = sin((x + x*x*x)*PI) * (1-x) * 1.5
    anim_state.pos.y -= bounce*35

func _anim_bounceskip():
    var x : float = anim_progress
    var bounce = sin((x + x*x)*PI) * (1-x*0.8) * 1.5
    anim_state.pos.y -= abs(bounce*25)

func _anim_hop():
    var x : float = anim_progress
    var bounce = x*(1-x)*4
    anim_state.pos.y -= bounce*35

func _anim_hop2():
    var x : float = anim_progress
    var bounce = x*(1-x)*(1-x)*7
    anim_state.pos.y -= bounce*35

func _anim_dip():
    var x : float = anim_progress
    var bounce = x*(1-x)*4
    anim_state.pos.y += bounce*35

func _anim_wiggle():
    var x : float = anim_progress
    var bounce = sin(x*PI*2) * x * (1-x) * 5
    anim_state.pos.x += bounce*35

func _anim_squirm():
    var x : float = anim_progress
    var bounce_x = sin(x*PI*4)
    var bounce_y = x*(1-x)*4
    anim_state.pos.x += bounce_x*15*bounce_y
    anim_state.pos.y += bounce_y*35

func _anim_minisquirm():
    var x : float = anim_progress
    var bounce_x = sin(x*PI*2)
    var bounce_y = x*(1-x)*4
    anim_state.pos.x += bounce_x*10*bounce_y
    anim_state.pos.y += bounce_y*15

func _anim_shakehead():
    var x : float = anim_progress
    var bounce = sin(x*PI*3) * x * (1-x) * 5
    anim_state.pos.x += bounce*15

func _anim_shake():
    var x : float = anim_progress
    var bounce = sin(x*PI*4) * x * (1-x) * 5
    anim_state.pos.x -= bounce*15

# Dictionary of anim names to function name strings.
# Special animations are relative to the tachie's animated base position.
var special_anims = {
    "bounce" : "_anim_bounce",
    "bounceup" : "_anim_bounceup",
    "bounceskip" : "_anim_bounceskip",
    "hop" : "_anim_hop",
    "hop2" : "_anim_hop2",
    "dip" : "_anim_dip",
    "wiggle" : "_anim_wiggle",
    "squirm" : "_anim_squirm",
    "minisquirm" : "_anim_minisquirm",
    "shakehead" : "_anim_shakehead",
    "shake" : "_anim_shake",
}

signal animation_finished
var anim_time = EngineSettings.tachie_anim_time
func process_animation(delta):
    if Engine.editor_hint:
        return
    if Manager.cutscene_paused:
        return
    if anim_progress >= 0.0:
        if anim_time < 0.0001:
            anim_time = 0.0001
        
        # slow down animations that go a long distance
        var soft_limit = EngineSettings.tachie_anim_longer_distance
        if abs(anim_to.pos.x - anim_from.pos.x) > soft_limit:
            var amount = abs(anim_to.pos.x - anim_from.pos.x) - soft_limit
            var factor = 1.0 + amount/soft_limit
            anim_progress += delta/(anim_time*factor)
        else:
            anim_progress += delta/anim_time
        anim_progress = clamp(anim_progress, 0.0, 1.0)
        
        if Manager.do_timer_skip(): anim_progress = 1.0
        
        anim_state.pos = anim_from.pos.linear_interpolate(anim_to.pos, smoothstep(0.0, 1.0, anim_progress))
        anim_state.scale = smoothstep(anim_from.scale, anim_to.scale, anim_progress)
        anim_state.alpha = smoothstep(anim_from.alpha, anim_to.alpha, anim_progress)
        anim_state.texfade = anim_progress
        
        if anim_current_name in special_anims:
            call(special_anims[anim_current_name])
        
        if anim_progress == 1.0:
            anim_from = anim_to
            anim_from.texfade = 0.0
            anim_state = anim_from.duplicate()
            anim_progress = -1
            anim_current_name = ""
            if texture2:
                texture = texture2
            else:
                texture = _transparent
            flip_first = flip_second
            emit_signal("animation_finished")

signal zoom_finished
var zoom_nonce = 0
var zoom_time = EngineSettings.tachie_anim_time
func set_zoom(zoom : float):
    zoom_nonce += 1
    var start_nonce = zoom_nonce
    
    if Manager.LOAD_SKIP:
        scale_factor_target = zoom
        scale_factor = zoom
        return
    
    if !visible or modulate.a == 0.0:
        scale_factor_target = zoom
        scale_factor = zoom
        yield(get_tree(), "idle_frame")
        emit_signal("zoom_finished")
        return
    
    scale_factor = scale_factor_target
    var old_scale_factor = scale_factor
    scale_factor_target = zoom
    
    var progress = 0.0
    while progress < 1.0:
        yield(get_tree(), "idle_frame")
        if Manager.cutscene_paused:
            continue
        if zoom_nonce != start_nonce:
            emit_signal("zoom_finished")
            return
        if Manager.do_timer_skip():
            scale_factor = scale_factor_target
            break
        
        progress += get_process_delta_time()/zoom_time
        progress = clamp(progress, 0.0, 1.0)
        scale_factor = lerp(old_scale_factor, scale_factor_target, smoothstep(0.0, 1.0, progress))
    
    emit_signal("zoom_finished")

signal offset_finished
var offset_nonce = 0
var offset_time = EngineSettings.tachie_anim_time
func set_offset(arg_offset : Vector2):
    print("entering set_offset")
    offset_nonce += 1
    var start_nonce = offset_nonce
    
    if Manager.LOAD_SKIP:
        offset_target = offset
        offset = offset
        return
    
    if !visible or modulate.a == 0.0:
        offset_target = offset
        offset = offset
        yield(get_tree(), "idle_frame")
        emit_signal("offset_finished")
        return
    
    offset = offset_target
    var old_offset = offset
    offset_target = arg_offset
    
    var progress = 0.0
    while progress < 1.0:
        yield(get_tree(), "idle_frame")
        if Manager.cutscene_paused:
            continue
        if offset_nonce != start_nonce:
            emit_signal("offset_finished")
            return
        if Manager.do_timer_skip():
            offset = offset_target
            break
        
        progress += get_process_delta_time()/offset_time
        progress = clamp(progress, 0.0, 1.0)
        offset = lerp(old_offset, offset_target, smoothstep(0.0, 1.0, progress))
        print(offset_target)
    
    emit_signal("offset_finished")

func _process(delta):
    process_animation(delta)
    update_uniforms()

func get_next_texture():
    if anim_progress < 0.0 and (texture2 == null or texture != null):
        return texture
    else:
        return texture2
    
func force_finish_anim():
    if anim_progress >= 0.0:
        anim_from = anim_to
        anim_from.texfade = 0.0
        anim_state = anim_from.duplicate()
        anim_progress = -1
        anim_current_name = ""
        if texture2:
            texture = texture2
        else:
            texture = _transparent
        flip_first = flip_second
        emit_signal("animation_finished")
    
var anim_memory = ""
var anim_current_name = ""
func play_animation(anim : String, next_texture : Texture = null):
    force_finish_anim()
    
    #print("!!playing anim... ", anim)
    
    if not anim in special_anims:
        #print("--- overriding animation memory")
        anim_memory = anim
    anim_current_name = anim
    
    anim_from = anim_to
    anim_from.texfade = 0.0
    anim_state = anim_to.duplicate()
    var start_texture = texture
    if texture2:
        texture = texture2
    else:
        texture = _transparent
    texture2 = next_texture
    
    if start_texture != null and texture == null and texture2 != null:
        texture = start_texture
    
    var anim_new = anim_default.duplicate()
    if anim == "farlefter":
        anim_new.pos.x = rect_size.x*-0.5
    elif anim == "farleft":
        anim_new.pos.x = rect_size.x*-0.4
    elif anim == "farleftish":
        anim_new.pos.x = rect_size.x*-0.3
    elif anim == "left":
        anim_new.pos.x = rect_size.x*-0.2
    elif anim == "leftish":
        anim_new.pos.x = rect_size.x*-0.1
    elif anim == "center" or anim == "middle":
        anim_new.pos.x = 0.0
    elif anim == "rightish":
        anim_new.pos.x = rect_size.x*0.1
    elif anim == "right":
        anim_new.pos.x = rect_size.x*0.2
    elif anim == "farrightish":
        anim_new.pos.x = rect_size.x*0.3
    elif anim == "farright":
        anim_new.pos.x = rect_size.x*0.4
    elif anim == "farrighter":
        anim_new.pos.x = rect_size.x*0.5
    elif anim in special_anims:
        anim_new = anim_from.duplicate()
    anim_new.texfade = 1.0
    
    anim_to = anim_new
    
    if texture == _transparent:
        var alpha = anim_from.alpha
        anim_from = anim_to.duplicate()
        anim_from.alpha = alpha
    
    anim_progress = 0.0
    yield(Manager.get_tree(), "idle_frame")

