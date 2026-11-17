
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float time = 0.0;
uniform float glitch_strength = 0.08;

uniform vec4 glitch_color : source_color = vec4(0.3, 0.9, 1.0, 1.0);

float hash(float x) {
    return fract(sin(x * 127.1) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;

    float row = floor(UV.y * 45.0);

    float random_value = hash(
        row + floor(time * 15.0)
    );

    float intensity = progress * glitch_strength;

    uv.x += (random_value - 0.5) * intensity;

    float offset = progress * 0.012;

    vec4 tex = texture(screen_texture, uv);

    if (tex.a > 0.0001) {
        tex.rgb /= tex.a;
    }

    float red = texture(
        screen_texture,
        uv + vec2(offset, 0.0)
    ).r;

    float blue = texture(
        screen_texture,
        uv - vec2(offset, 0.0)
    ).b;

    vec3 rgb = vec3(red, tex.g, blue);

    rgb = mix(
        rgb,
        glitch_color.rgb,
        random_value * progress * 0.2
    );

    float flicker = step(
        progress * 0.55,
        hash(row + floor(time * 25.0) + 10.0)
    );

    float alpha = mix(
        tex.a,
        tex.a * flicker,
        progress * 0.7
    );

    alpha *= 1.0 - smoothstep(0.85, 1.0, progress);

    COLOR = vec4(rgb, alpha);
}
