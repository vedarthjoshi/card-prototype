shader_type canvas_item;

// 1. Add the screen_texture uniform for CanvasGroup
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float noise_scale = 18.0;
uniform float edge_width = 0.06;
uniform vec4 edge_color : source_color = vec4(0.55, 0.2, 1.0, 1.0);

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

void fragment() {
    // 2. Sample screen_texture at SCREEN_UV instead of TEXTURE at UV
    vec4 tex = texture(screen_texture, SCREEN_UV);

    // 3. Un-premultiply alpha (CanvasGroup uses premultiplied alpha)
    if (tex.a > 0.0001) {
        tex.rgb /= tex.a;
    }

    float n = noise(UV * noise_scale);

    float dissolve = smoothstep(
        progress - 0.04,
        progress + 0.04,
        n
    );

    float edge = 1.0 - smoothstep(
        0.0,
        edge_width,
        abs(n - progress)
    );

    vec3 final_color = tex.rgb;
    // Only apply edge glow where the card actually exists
    final_color = mix(final_color, edge_color.rgb, edge * step(0.01, tex.a));

    COLOR = vec4(final_color, tex.a * dissolve);
}
