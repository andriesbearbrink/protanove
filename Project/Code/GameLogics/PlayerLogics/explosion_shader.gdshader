shader_type canvas_item;

uniform float radius : hint_range(0.0, 0.5) = 0.5;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center);

    if (dist < radius) {
        COLOR = vec4(1.0, 0.5, 0.0, 1.0);  // Orange color
    } else {
        COLOR = vec4(0.0);
    }

    // Add a glow effect
    float glow = 1.0 - smoothstep(radius - 0.05, radius, dist);
    COLOR.rgb += vec3(1.0, 0.5, 0.0) * glow * 0.5;
}