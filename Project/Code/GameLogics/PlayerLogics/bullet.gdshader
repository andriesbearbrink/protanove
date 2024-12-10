shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float trail_length : hint_range(0.0, 5.0) = 2.0;
uniform float trail_width_start : hint_range(0.0, 1.0) = 1.0;
uniform float trail_width_end : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec2 centered_uv = (UV - 0.5) * 2.0;
    float dist = length(centered_uv);

    // Bullet shape
    float bullet_shape = smoothstep(1.0, 0.9, dist);

    // Trail shape
    float trail_shape = 0.0;
    if (centered_uv.x < 0.0) {
        float trail_width = mix(trail_width_end, trail_width_start, (-centered_uv.x / trail_length));
        trail_shape = smoothstep(trail_width, trail_width * 0.9, abs(centered_uv.y));
        trail_shape *= smoothstep(trail_length, 0.0, -centered_uv.x);
    }

    // Combine bullet and trail
    float final_shape = max(bullet_shape, trail_shape);

    // Apply color and alpha
    vec4 instance_color = COLOR;
    COLOR = base_color * instance_color;
    COLOR.a *= final_shape;

    // Add a small highlight
    if (dist < 0.1) {
        COLOR = mix(COLOR, vec4(1.0, 1.0, 1.0, COLOR.a), 0.5);
    }
}