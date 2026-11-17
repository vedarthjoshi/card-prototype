
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float time = 0.0;
uniform float electricity_strength = 1.0;

uniform vec4 lightning_color : source_color = vec4(0.3, 0.8, 1.0, 1.0);

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

void fragment() {
    vec4 tex = texture(screen_texture, SCREEN_UV);

    if (tex.a > 0.0001) {
        tex.rgb /= tex.a;
    }

    float distortion = noise(
        vec2(
            UV.x * 8.0,
            UV.y * 35.0 + time * 5.0
        )
    );

    float line = abs(
        sin(
            UV.y * 65.0 +
            distortion * 12.0 +
            time * 10.0
        )
    );

    float electricity = 1.0 - smoothstep(
        0.0,
        0.12,
        line
    );

    electricity *= step(
        0.75,
        noise(UV * 10.0 + vec2(time))
    );

    vec3 rgb = tex.rgb;

    rgb += lightning_color.rgb *
           electricity *
           progress *
           electricity_strength;

    float remaining = 1.0 - smoothstep(
        0.75,
        1.0,
        progress
    );

    COLOR = vec4(rgb, tex.a * remaining);
}
