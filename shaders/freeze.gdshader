
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float progress : hint_range(0.0, 1.0) = 0.0;

uniform vec2 shard_grid = vec2(8.0, 10.0);
uniform float scatter_distance = 0.18;
uniform float rotation_strength = 1.2;

uniform vec4 ice_color : source_color = vec4(0.25, 0.75, 1.0, 1.0);
uniform vec4 shard_edge_color : source_color = vec4(0.85, 0.97, 1.0, 1.0);

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 rotate_vec(vec2 p, float angle) {
    float s = sin(angle);
    float c = cos(angle);

    return vec2(
        p.x * c - p.y * s,
        p.x * s + p.y * c
    );
}

void fragment() {
    // Convert local UV displacement into screen UV displacement.
    vec2 uv_dx = dFdx(UV);
    vec2 uv_dy = dFdy(UV);

    vec2 screen_dx = dFdx(SCREEN_UV);
    vec2 screen_dy = dFdy(SCREEN_UV);

    float dx = abs(uv_dx.x) < 0.000001 ? 0.000001 : uv_dx.x;
    float dy = abs(uv_dy.y) < 0.000001 ? 0.000001 : uv_dy.y;

    vec2 screen_axis_x = screen_dx / dx;
    vec2 screen_axis_y = screen_dy / dy;

    vec2 grid_position = UV * shard_grid;
    vec2 base_cell = floor(grid_position);

    bool found = false;

    vec2 chosen_source = UV;
    vec2 chosen_local = vec2(0.0);
    vec2 chosen_cell = vec2(0.0);

    float chosen_side = 0.0;
    float chosen_id = 0.0;

    // Search for the original triangular shard that occupies this pixel.
    // The search range allows the shards to move beyond their original cells.
    for (int y = -3; y <= 3; y++) {
        for (int x = -3; x <= 3; x++) {

            vec2 cell = base_cell + vec2(float(x), float(y));

            vec2 center = (cell + vec2(0.5)) / shard_grid;

            for (int tri = 0; tri < 2; tri++) {

                if (!found) {

                    float id = hash(
                        cell + vec2(float(tri) * 19.19, 7.31)
                    );

                    // Each shard gets its own direction.
                    float angle_random = hash(
                        cell + vec2(41.7, float(tri) * 13.0)
                    ) * 6.2831853;

                    vec2 random_direction = vec2(
                        cos(angle_random),
                        sin(angle_random)
                    );

                    vec2 outward = center - vec2(0.5);

                    if (length(outward) > 0.001) {
                        outward = normalize(outward);
                    } else {
                        outward = vec2(0.0, -1.0);
                    }

                    vec2 direction = normalize(
                        outward * 0.7 + random_direction * 0.65
                    );

                    float distance_amount =
                        scatter_distance *
                        pow(progress, 1.15) *
                        mix(0.35, 1.25, id);

                    vec2 offset = direction * distance_amount;

                    // Independent rotation for every triangle.
                    float rotation = (
                        hash(cell + vec2(61.3, float(tri) * 23.0)) - 0.5
                    ) * rotation_strength * progress;

                    // Inverse transformation: destination -> original source.
                    vec2 source_uv = center + rotate_vec(
                        UV - center - offset,
                        -rotation
                    );

                    vec2 source_grid = source_uv * shard_grid;
                    vec2 source_cell = floor(source_grid);
                    vec2 local = fract(source_grid);

                    // Ignore samples outside the original cell.
                    bool same_cell =
                        source_cell.x == cell.x &&
                        source_cell.y == cell.y;

                    bool inside_texture =
                        source_uv.x >= 0.0 &&
                        source_uv.y >= 0.0 &&
                        source_uv.x < 1.0 &&
                        source_uv.y < 1.0;

                    // Alternating diagonal cuts create triangular pieces.
                    float diagonal = mod(cell.x + cell.y, 2.0);

                    float side = diagonal < 1.0
                        ? local.x - local.y
                        : local.x + local.y - 1.0;

                    bool inside_triangle =
                        (tri == 0 && side >= 0.0) ||
                        (tri == 1 && side < 0.0);

                    if (
                        same_cell &&
                        inside_texture &&
                        inside_triangle
                    ) {
                        chosen_source = source_uv;
                        chosen_local = local;
                        chosen_cell = cell;
                        chosen_side = side;
                        chosen_id = id;

                        found = true;
                    }
                }
            }
        }
    }

    vec4 tex = vec4(0.0);

    if (found) {

        // Sample the original card at the fragment's source position.
        vec2 source_screen_uv = SCREEN_UV;

        source_screen_uv +=
            screen_axis_x * (chosen_source.x - UV.x);

        source_screen_uv +=
            screen_axis_y * (chosen_source.y - UV.y);

        tex = textureLod(
            screen_texture,
            source_screen_uv,
            0.0
        );

        if (tex.a > 0.0001) {
            tex.rgb /= tex.a;
        }
    }

    vec3 rgb = tex.rgb;

    // Slight variation in individual shard surfaces.
    float facet = mix(0.82, 1.12, chosen_id);
    rgb *= facet;

    // Ice tint develops as the shards separate.
    rgb = mix(
        rgb,
        ice_color.rgb,
        progress * 0.14
    );

    // Highlight the triangular fracture edges.
    float edge_distance = min(
        min(chosen_local.x, 1.0 - chosen_local.x),
        min(chosen_local.y, 1.0 - chosen_local.y)
    );

    edge_distance = min(
        edge_distance,
        abs(chosen_side) * 0.707
    );

    float crack = 1.0 - smoothstep(
        0.002,
        0.035,
        edge_distance
    );

    float crack_activation = smoothstep(
        0.04,
        0.25,
        progress
    );

    rgb += shard_edge_color.rgb *
           crack *
           crack_activation *
           0.8;

    // Let the pieces scatter before the final disappearance.
    float final_fade = 1.0 - smoothstep(
        0.92,
        1.0,
        progress
    );

    COLOR = vec4(rgb, tex.a * final_fade);
}
