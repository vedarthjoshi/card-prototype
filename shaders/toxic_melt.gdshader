
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float distortion = 0.025;
uniform float noise_scale = 12.0;

uniform vec4 poison_color : source_color = vec4(0.2, 0.85, 0.15, 1.0);

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
    vec2 uv = UV;

    float n = noise(UV * noise_scale);

    // Distort screen sampling coordinates.
    vec2 distorted_screen_uv = SCREEN_UV;

    distorted_screen_uv.x +=
        sin(UV.y * 30.0 + progress * 10.0)
        * distortion * progress;

    distorted_screen_uv.y +=
        sin(UV.x * 25.0 + progress * 12.0)
        * distortion * progress;

    vec4 tex = texture(
        screen_texture,
        distorted_screen_uv
    );

    if (tex.a > 0.0001) {
        tex.rgb /= tex.a;
    }

    vec3 rgb = mix(
        tex.rgb,
        poison_color.rgb,
        progress * 0.55
    );

    float remaining = smoothstep(
        progress - 0.08,
        progress + 0.08,
        n
    );

    COLOR = vec4(rgb, tex.a * remaining);
}
