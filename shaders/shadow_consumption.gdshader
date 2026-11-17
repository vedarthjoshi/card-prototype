
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float noise_scale = 14.0;
uniform float edge_width = 0.07;

uniform vec4 shadow_color : source_color = vec4(0.12, 0.01, 0.22, 1.0);

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

    vec2 centered = UV - vec2(0.5);

    float radial = length(centered * vec2(1.0, 1.2));

    float n = noise(UV * noise_scale);

    float field = radial + (n - 0.5) * 0.14;

    float threshold = mix(0.85, -0.05, progress);

    float remaining = 1.0 - smoothstep(
        threshold - edge_width,
        threshold + edge_width,
        field
    );

    float edge = 1.0 - smoothstep(
        0.0,
        edge_width,
        abs(field - threshold)
    );

    vec3 rgb = tex.rgb;

    rgb = mix(
        rgb,
        shadow_color.rgb,
        edge * 0.9
    );

    COLOR = vec4(rgb, tex.a * remaining);
}
