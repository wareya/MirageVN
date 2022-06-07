extends Node

const bgm_fade_time = 0.7

const bg_fade_time = 1.25

const effect_default_framerate = 30.0

const tachie_anim_time = 0.4
const tachie_anim_longer_distance = 384
const tachie_anim_default_pos = Vector2(0.5, 250)
const tachie_anim_default_scale = 1.75

const env_transition_speed = 1.0

const scene_fade_time = 0.75

const screen_shake_default_power = 4.0

# maybe affected by user configuration in the future???

const backlog_max_size = 200
const cutscene_skip_rate = 20.0

# affected by user configuration

const textbox_default_opacity = 0.75
const textbox_typein_chars_per_sec = 120.0
const textbox_fade_time = 0.25

const auto_delay_amount = 1.5
const auto_delay_per_character = 1.0/25.0

const audio_sfx_default_volume = -1.0
const audio_bgm_default_volume = -12.0
const audio_master_default_volume = 0.0

# sounds

const load_failure_sound = preload("res://sfx/errorthing.wav")
const load_success_sound = preload("res://sfx/reconfirm.wav")
const save_failure_sound = preload("res://sfx/errorthing.wav")
const save_success_sound = preload("res://sfx/progress.wav")

