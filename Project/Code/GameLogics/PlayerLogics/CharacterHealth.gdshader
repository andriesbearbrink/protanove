shader_type canvas_item;

uniform vec4 fill_color : source_color;
uniform float fill_percentage : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float dist = length(uv);
    
    if (dist > 1.0) {
        // Outside the circle, fully transparent
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    } else if (dist > fill_percentage) {
        // Between fill_percentage and edge of circle, transparent
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    } else {
        // Inside the health indicator
        COLOR = fill_color;
    }
}