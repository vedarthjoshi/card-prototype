
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float time = 0.0;

uniform float noise_scale = 12.0;
uniform float edge_width = 0.055;

uniform vec4 fire_color : source_color = vec4(1.0, 0.18, 0.015, 1.0);
uniform vec4 hot_color : source_color = vec4(1.0, 0.78, 0.22, 1.0);
uniform vec4 char_color : source_color = vec4(0.055, 0.018, 0.008, 1.0);

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;

    for (int i = 0; i < 4; i++) {
        value += noise(p) * amplitude;
        p *= 2.0;
        amplitude *= 0.5;
    }

    return value;
}

void fragment() {
    vec4 tex = textureLod(screen_texture, SCREEN_UV, 0.0);

    if (tex.a > 0.0001) {
        tex.rgb /= tex.a;
    }

    // Animated turbulent combustion field.
    float n1 = fbm(
        UV * vec2(noise_scale, noise_scale * 0.65)
        + vec2(0.0, time * 0.35)
    );

    float n2 = fbm(
        UV * vec2(30.0, 20.0)
        + vec2(0.0, time * 0.8)
    );

    float turbulence = (n1 - 0.5) * 0.24;
    turbulence += (n2 - 0.5) * 0.065;

    // Fire travels from bottom to top.
    float field = 1.0 - UV.y + turbulence;

    float front = mix(-0.25, 1.35, progress);

    float dist = field - front;

    // Boundary gradually becomes thicker.
    float dynamic_width = mix(
        0.012,
        edge_width * 2.2,
        progress
    );

    // Remaining card.
    float remaining = smoothstep(
        -dynamic_width,
        dynamic_width,
        dist
    );

    // Burnt material behind the flame.
    float char_mask = (
        1.0 - smoothstep(0.015, 0.16, dist)
    ) * remaining;

    vec3 rgb = tex.rgb;

    rgb = mix(
        rgb,
        char_color.rgb,
        char_mask * 0.85
    );

    // Uneven flame tongues.
    float tongue_wave = 0.5 + 0.5 * sin(
        UV.x * 34.0 +
        n1 * 13.0 -
        time * 4.0
    );

    float tongue_height = mix(
        0.018,
        0.12,
        pow(tongue_wave, 5.0)
    );

    float flame_body = step(0.0, dist) *
        (
            1.0 - smoothstep(
                tongue_height,
                tongue_height + 0.025,
                dist
            )
        );

    float flicker = 0.75 + 0.25 * sin(
        time * 18.0 + UV.x * 75.0 + n2 * 8.0
    );

    float flame_gradient = clamp(
        dist / max(tongue_height, 0.001),
        0.0,
        1.0
    );

    vec3 flame_rgb = mix(
        hot_color.rgb,
        fire_color.rgb,
        flame_gradient
    );

    rgb = mix(
        rgb,
        flame_rgb,
        flame_body * flicker
    );

    // Bright, expanding combustion edge.
    float edge_glow = exp(
        -abs(dist) / max(dynamic_width * 0.75, 0.001)
    );

    rgb += fire_color.rgb * edge_glow * 0.9;
    rgb += hot_color.rgb * edge_glow * edge_glow * 0.6;

    COLOR = vec4(rgb, tex.a * remaining);
}
