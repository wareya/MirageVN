shader_type canvas_item;
uniform float fadeamount;
uniform bool invert;
uniform float contrast;


void vertex() {
// Output:0

}

float sample_mask_at(sampler2D sampler, vec2 uv) {
    float sharpness = 10.0 * max(0.0001, contrast);
    float out_a = dot(texture(sampler, uv).rgb, vec3(1.0/3.0, 1.0/3.0, 1.0/3.0))-0.5;
    out_a *= invert?-1.0:1.0;
    out_a += fadeamount*(1.0+1.0/sharpness)-(1.0/sharpness/2.0);
    out_a = (out_a-0.5)*sharpness+0.5;
    return clamp(out_a, 0.0, 1.0);
}

float get_mask_a(sampler2D sampler, vec2 uv) {
    vec2 halfpx_x = vec2(0.25/1280.0, 0.0);
    vec2 halfpx_y = vec2(0.0, 0.25/720.0);
    float out_a = 0.0;
    out_a += sample_mask_at(sampler, uv - halfpx_x - halfpx_y);
    out_a += sample_mask_at(sampler, uv + halfpx_x - halfpx_y);
    out_a += sample_mask_at(sampler, uv - halfpx_x + halfpx_y);
    out_a += sample_mask_at(sampler, uv + halfpx_x + halfpx_y);
    out_a /= 4.0;
    return out_a;
}

void fragment() {
    COLOR.rgb = MODULATE.rgb;
    COLOR.a = get_mask_a(TEXTURE, UV.xy);

}

void light() {
// Output:0

}
