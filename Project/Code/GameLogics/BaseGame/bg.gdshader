shader_type canvas_item;

uniform vec4 color1 : source_color;
uniform vec4 color2 : source_color;
uniform vec4 color3 : source_color;
uniform vec4 color4 : source_color;
uniform float speed : hint_range(0.0, 2.0);
uniform float line_opacity : hint_range(0.0, 1.0) = 0.0; // Reduced default opacity
uniform vec2 player1_pos;
uniform vec2 player2_pos;
uniform float player_influence = 100.0;

const int MAX_BULLETS = 100;
uniform vec4 bullet_data[MAX_BULLETS];  // x, y: current position, z: trail length, w: bullet color (packed)

const vec2 fixed_resolution = vec2(1920.0, 1080.0);

float hash(vec3 p) {
    return fract(sin(1e3*dot(p,vec3(1.0,57.0,-13.7)))*4375.5453);
}

float noise3(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(mix(hash(p + vec3(0,0,0)), hash(p + vec3(1,0,0)), f.x),
            mix(hash(p + vec3(0,1,0)), hash(p + vec3(1,1,0)), f.x), f.y),
        mix(mix(hash(p + vec3(0,0,1)), hash(p + vec3(1,0,1)), f.x),
            mix(hash(p + vec3(0,1,1)), hash(p + vec3(1,1,1)), f.x), f.y),
        f.z
    );
}

float noise(vec3 x) {
    return (noise3(x) + noise3(x + 11.5)) / 2.0;
}

vec2 rotate(vec2 uv, float angle) {
    mat2 rotation = mat2(vec2(cos(angle), -sin(angle)),
                        vec2(sin(angle), cos(angle)));
    return uv * rotation;
}

vec2 calculate_offset(vec2 uv, vec2 player_pos) {
    vec2 diff = (player_pos - uv) * fixed_resolution;
    float dist = length(diff);
    float influence = 1.0 - smoothstep(0.0, player_influence, dist);
    return normalize(diff) * influence * 10.0;
}

vec3 unpack_color(float packed_color) {
    vec3 color;
    color.r = floor(packed_color / 65536.0) / 255.0;
    color.g = floor(mod(packed_color, 65536.0) / 256.0) / 255.0;
    color.b = floor(mod(packed_color, 256.0)) / 255.0;
    return color;
}

void fragment() {
    vec2 fixed_uv = UV * fixed_resolution;
    float time = TIME * speed;
    vec2 rotated_uv = rotate(UV - 0.5, time * 0.1) + 0.5;

    // Base gradient
    vec4 gradient = mix(
        mix(color1, color2, rotated_uv.x),
        mix(color3, color4, rotated_uv.x),
        rotated_uv.y
    );

    // Calculate player influence with increased strength
    vec2 to_player1 = player1_pos - UV;
    vec2 to_player2 = player2_pos - UV;
    float dist1 = length(to_player1 * fixed_resolution);
    float dist2 = length(to_player2 * fixed_resolution);

    // Stronger influence field
    float player_influence1 = 1.0 - smoothstep(0.0, player_influence * 1.5, dist1);
    float player_influence2 = 1.0 - smoothstep(0.0, player_influence * 1.5, dist2);

    // Create much stronger distortion
    vec2 distortion = vec2(0.0);
    if (dist1 < player_influence * 2.0) {
        distortion += normalize(to_player1) * player_influence1 * 0.01; // Increased from 0.1 to 0.4
    }
    if (dist2 < player_influence * 2.0) {
        distortion += normalize(to_player2) * player_influence2 * 0.01;
    }

    // Apply distortion to UV coordinates used for the noise
    vec2 distorted_uv = UV + distortion;

    // Generate noise pattern with stronger distortion
    float n = noise(vec3(distorted_uv * 2.5, 0.00000005 * TIME));

    // Add extra turbulence near players
    float total_influence = max(player_influence1, player_influence2);
    n += total_influence * 0.02; // Added noise distortion

    // Create line pattern
    float v = sin(30.0 * (sin(TIME / 400.0) + 4.0) * n);
    v = smoothstep(1.0, 0.2, abs(v)/fwidth(v)) * 0.15;

    // Mix gradient with noise pattern
    vec4 base_color = gradient;
    base_color = mix(base_color, vec4(0.0, 0.0, 0.0, max(0.01, line_opacity)), v * 0.6);


    // Draw bullet trails
    for (int i = 0; i < MAX_BULLETS; i++) {
        vec2 bullet_pos = bullet_data[i].xy;
        float trail_length = bullet_data[i].z;
        vec3 bullet_color = unpack_color(bullet_data[i].w);

        if (trail_length > 0.0) {
            vec2 to_pixel = (UV - bullet_pos) * fixed_resolution;
            float dist_along_trail = -to_pixel.x;
            if (dist_along_trail > 0.0 && dist_along_trail < trail_length) {
                float perp_distance = abs(to_pixel.y);
                float trail_width = 2.0;
                if (perp_distance < trail_width) {
                    float intensity = 1.0 - dist_along_trail / trail_length;
                    intensity *= smoothstep(trail_width, 0.0, perp_distance);
                    base_color.rgb = mix(base_color.rgb, bullet_color, intensity * 0.7);
                }
            }
        }
    }

    COLOR = base_color;
}