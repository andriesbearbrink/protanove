shader_type canvas_item;

uniform bool shape_0_active = true;
uniform bool shape_1_active = true;
uniform bool shape_2_active = true;
uniform bool shape_3_active = true;
uniform bool shape_4_active = true;

uniform vec4 shape_0_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform vec4 shape_1_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform vec4 shape_2_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform vec4 shape_3_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform vec4 shape_4_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);

uniform float outline_thickness : hint_range(0.001, 0.1) = 0.01;
uniform float throb_speed : hint_range(0.1, 10.0) = 2.0;
uniform float throb_intensity : hint_range(0.0, 0.3) = 0.1;
uniform float phase_shift : hint_range(0.0, 10.0) = 0.0;  // New uniform for fade effect


// Each shape phase offset multiplier
const float SHAPE_PHASES[5] = float[5](0.0, 0.4, 0.8, 1.2, 1.6);

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float sdTriangle(vec2 p, float r) {
    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r/k;
    if(p.x + k*p.y > 0.0) p = vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp(p.x, -2.0*r, 0.0);
    return -length(p)*sign(p.y);
}

float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdRhombus(vec2 p, vec2 b) {
    vec2 q = abs(p);
    float h = clamp((-2.0*b.y + b.x + b.y - q.x - q.y) / (2.0*b.y), 0.0, 1.0);
    return length(q - vec2(b.x, b.y)*vec2(1.0-h, h)) * sign(q.x*b.y + q.y*b.x - b.x*b.y);
}

float getShape(int shape_id, vec2 uv, float scale) {
    if (shape_id == 0) return sdCircle(uv, 0.4 * scale);
    if (shape_id == 1) return sdTriangle(uv, 0.4 * scale);
    if (shape_id == 2) return sdBox(uv, vec2(0.3) * scale);
    if (shape_id == 3) return sdRhombus(uv, vec2(0.3, 0.5) * scale);
    if (shape_id == 4) return sdCircle(uv, 0.2 * scale);
    return 1e10;
}

float get_shape_throb(int shape_index) {
    float phase = SHAPE_PHASES[shape_index] + phase_shift;
    return 1.0 + throb_intensity * sin(TIME * throb_speed + phase);
}

void fragment() {
    vec2 uv = (UV - 0.5) * 1.0;
    vec4 final_color = vec4(0.0);
    
    for(int i = 0; i < 5; i++) {
        bool is_active = false;
        vec4 shape_color;
        
        switch(i) {
            case 0: 
                is_active = shape_0_active;
                shape_color = shape_0_color;
                break;
            case 1: 
                is_active = shape_1_active;
                shape_color = shape_1_color;
                break;
            case 2: 
                is_active = shape_2_active;
                shape_color = shape_2_color;
                break;
            case 3: 
                is_active = shape_3_active;
                shape_color = shape_3_color;
                break;
            case 4: 
                is_active = shape_4_active;
                shape_color = shape_4_color;
                break;
        }
        
        if (is_active) {
            float throb = get_shape_throb(i);
            float d = abs(getShape(i, uv, throb)) - outline_thickness;
            if (d < 0.0) {
                final_color = mix(final_color, shape_color, shape_color.a);
            }
        }
    }
    
    COLOR = final_color;
}