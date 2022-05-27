shader_type canvas_item;

uniform sampler2D texture2;
uniform sampler2D texture3;
uniform vec2 texturesize;
uniform vec2 texture2size;
uniform float fadeamount;
uniform float contrast;
uniform bool invert;
uniform vec2 rectsize;

uniform sampler2D normalmap;
uniform vec2 normal_strength;
uniform vec2 normal_scale;
uniform vec2 normal_offset;

uniform mat4 transform_1;
uniform mat4 transform_2;

varying vec2 uv;
varying vec2 uv2;



float sample_mask_at(vec2 _uv) {
    float sharpness = 10.0 * max(0.0001, contrast);
    float out_a = dot(texture(texture3, _uv).rgb, vec3(1.0/3.0, 1.0/3.0, 1.0/3.0))-0.5;
    out_a *= invert?-1.0:1.0;
    out_a += fadeamount*(1.0+1.0/sharpness)-(1.0/sharpness/2.0);
    out_a = (out_a-0.5)*sharpness+0.5;
    return clamp(out_a, 0.0, 1.0);
}

float get_mask_a(vec2 _uv) {
    vec2 halfpx_x = vec2(0.25/rectsize.x, 0.0);
    vec2 halfpx_y = vec2(0.0, 0.25/rectsize.y);
    float out_a = 0.0;
    out_a += sample_mask_at(_uv - halfpx_x - halfpx_y);
    out_a += sample_mask_at(_uv + halfpx_x - halfpx_y);
    out_a += sample_mask_at(_uv - halfpx_x + halfpx_y);
    out_a += sample_mask_at(_uv + halfpx_x + halfpx_y);
    out_a /= 4.0;
    return out_a;
}


void vertex() {
    float target_ratio = rectsize.x / rectsize.y;
    float actual_ratio   = texturesize.x / texturesize.y;
    float actual_ratio_2 = texture2size.x / texture2size.y;
    
    if(actual_ratio >= target_ratio) // wider, grow x
    {
        uv = UV.xy * vec2(target_ratio/actual_ratio, 1.0);
        uv.x += (1.0-(target_ratio/actual_ratio))/2.0;
    }
    else // taller, grow y
    {
        uv = UV.xy * vec2(1.0, actual_ratio/target_ratio);
        uv.y += (1.0-(actual_ratio/target_ratio))/2.0;
    }
    if(actual_ratio_2 >= target_ratio) // wider, grow x
    {
        uv2 = UV.xy * vec2(target_ratio/actual_ratio_2, 1.0);
        uv2.x += (1.0-(target_ratio/actual_ratio_2))/2.0;
    }
    else // taller, grow y
    {
        uv2 = UV.xy * vec2(1.0, actual_ratio_2/target_ratio);
        uv2.y += (1.0-(actual_ratio_2/target_ratio))/2.0;
    }
}

void fragment() {
// Texture:2
    vec2 _uv = uv;
    vec2 _uv2 = uv2;
    _uv  = _uv.xy  + (texture(normalmap, (_uv -vec2(0.5, 0.5))/normal_scale + normal_offset).xy-vec2(0.5, 0.5))*normal_strength;
    _uv = (transform_1 * vec4(_uv, 1.0, 1.0)).xy;
    //_uv = (mat3(vec3(2,0,0),vec3(0,2,0),vec3(0,0,1)) * vec3(_uv, 1.0)).xy;
    _uv2 = _uv2.xy + (texture(normalmap, (_uv2-vec2(0.5, 0.5))/normal_scale + normal_offset).xy-vec2(0.5, 0.5))*normal_strength;
    _uv2 = (transform_2 * vec4(_uv2, 1.0, 1.0)).xy;
    //_uv2 = (mat3(vec3(2,0,0),vec3(0,2,0),vec3(0,0,1)) * vec3(_uv2, 1.0)).xy;
    vec4 colorA = texture(TEXTURE , _uv);
    vec4 colorB = texture(texture2, _uv2);
    colorA.rgb *= colorA.a;
    colorB.rgb *= colorB.a;
    float i = get_mask_a(UV.xy);
    vec4 colorC = mix(colorA, colorB, i);
    if(colorC.a > 0.0)
        colorC.rgb /= colorC.a;
    
// Output:0
    COLOR = colorC;
}

void light() {
// Output:0

}
