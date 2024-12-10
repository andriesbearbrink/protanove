shader_type canvas_item;

// Existing uniforms...
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float chromatic_strength : hint_range(0.0, 5.0) = 1.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 4.0;
uniform float glow_strength : hint_range(0.0, 2.0) = 0;
uniform float glow_threshold : hint_range(0.0, 1.0) = 0;
uniform float glow_blur : hint_range(0.0, 4.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float grain_strength : hint_range(0.0, 1.0) = 0.0;
uniform float grain_speed : hint_range(0.0, 10.0) = 0.0;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float contrast : hint_range(0.0, 2.0) = 1.0;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float edge_strength : hint_range(0.0, 5.0) = 0.0;
uniform float pixelate_amount : hint_range(1.0, 512.0) = 1;
uniform float pulse_speed : hint_range(0.0, 10.0) = 0.0;

// New lens uniforms
uniform vec2 lens_center = vec2(0.5, 0.5);
uniform float lens_radius : hint_range(0.0, 1.0) = 0.65;  // Set to 0 by default (disabled)
uniform float magnification : hint_range(0.1, 3.0) = 25;
uniform float edge_compression : hint_range(0.1, 2.0) = 0.2;
uniform float border_width : hint_range(0.0, 0.1) = 0.00;
uniform vec4 border_color : source_color = vec4(0.8, 0.8, 0.8, 0.0);

// Random function for grain effect
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Gaussian blur function
vec4 blur(sampler2D tex, vec2 uv, vec2 scale) {
    vec4 color = vec4(0.0);
    
    // 9-tap gaussian blur
    vec2 blur_coords[9] = vec2[9](
        vec2(-1.0, -1.0), vec2(0.0, -1.0), vec2(1.0, -1.0),
        vec2(-1.0, 0.0), vec2(0.0, 0.0), vec2(1.0, 0.0),
        vec2(-1.0, 1.0), vec2(0.0, 1.0), vec2(1.0, 1.0)
    );
    
    float weights[9] = float[9](
        0.0625, 0.125, 0.0625,
        0.125, 0.25, 0.125,
        0.0625, 0.125, 0.0625
    );
    
    for(int i = 0; i < 9; i++) {
        color += texture(tex, uv + blur_coords[i] * scale) * weights[i];
    }
    
    return color;
}

// Main function to apply all post-processing effects
vec4 apply_effects(vec4 color, vec2 uv) {
    vec4 final_color = color;
    
    // Pixelation
    if (pixelate_amount > 1.0) {
        vec2 pixel_uv = floor(uv * pixelate_amount) / pixelate_amount;
        final_color = texture(SCREEN_TEXTURE, pixel_uv);
    }
    
    // Glow effect
    vec4 bright_areas = vec4(0.0);
    if(brightness > glow_threshold) {
        bright_areas = final_color * glow_strength;
    }
    
    vec2 blur_scale = vec2(glow_blur) / vec2(textureSize(SCREEN_TEXTURE, 0));
    vec4 blurred = blur(SCREEN_TEXTURE, uv, blur_scale);
    vec4 glow = blurred * glow_strength * glow_color;
    final_color = max(final_color, glow);
    
    // Chromatic aberration
    if (chromatic_strength > 0.0) {
        vec2 dist_from_center = uv - vec2(0.5);
        vec2 chromatic_offset = dist_from_center * chromatic_strength * 0.005;
        
        float red = texture(SCREEN_TEXTURE, uv + chromatic_offset).r;
        float green = texture(SCREEN_TEXTURE, uv).g;
        float blue = texture(SCREEN_TEXTURE, uv - chromatic_offset).b;
        
        final_color = vec4(red, green, blue, final_color.a);
    }
    
    // Edge detection
    if (edge_strength > 0.0) {
        float dx = 1.0 / float(textureSize(SCREEN_TEXTURE, 0).x);
        float dy = 1.0 / float(textureSize(SCREEN_TEXTURE, 0).y);
        
        vec4 h = texture(SCREEN_TEXTURE, uv + vec2(dx, 0.0)) - 
                 texture(SCREEN_TEXTURE, uv - vec2(dx, 0.0));
        vec4 v = texture(SCREEN_TEXTURE, uv + vec2(0.0, dy)) - 
                 texture(SCREEN_TEXTURE, uv - vec2(0.0, dy));
        
        float edge = sqrt(dot(h.rgb, h.rgb) + dot(v.rgb, v.rgb)) * edge_strength;
        final_color.rgb = mix(final_color.rgb, vec3(1.0) - edge, edge);
    }
    
    // Film grain
    if (grain_strength > 0.0) {
        float grain = random(uv + vec2(TIME * grain_speed));
        final_color.rgb = mix(final_color.rgb, vec3(grain), grain_strength * 0.1);
    }
    
    // Brightness and contrast
    final_color.rgb = (final_color.rgb - 0.5) * contrast + 0.5;
    final_color.rgb *= brightness;
    
    // Color tint
    final_color.rgb *= tint_color.rgb;
    
    // Pulsing effect
    if (pulse_speed > 0.0) {
        float pulse = (sin(TIME * pulse_speed) * 0.1) + 0.9;
        final_color.rgb *= pulse;
    }
    
    return final_color;
}

// Brightness calculation
float get_brightness(vec3 color) {
    return max(max(color.r, color.g), color.b);
}

// New lens distortion function
vec2 apply_lens_distortion(vec2 uv) {
    if (lens_radius <= 0.0) return uv;
    
    vec2 delta = uv - lens_center;
    float dist = length(delta);
    float normalized_dist = dist / lens_radius;
    
    if (dist < lens_radius) {
        // Inside lens: magnify
        float distortion = pow(normalized_dist, 1.0 / magnification);
        return lens_center + delta * distortion;
    } else {
        // Outside lens: compress edges
        float distortion = 1.0 + (normalized_dist - 1.0) * edge_compression;
        return lens_center + delta * distortion;
    }
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 final_color;
    
    // Apply lens distortion if enabled
    if (lens_radius > 0.0) {
        vec2 distorted_uv = apply_lens_distortion(uv);
        float dist = length(uv - lens_center);
        
        // Get the color at the distorted position
        vec4 distorted_color = texture(SCREEN_TEXTURE, distorted_uv);
        
        // Apply all effects to the distorted color
        distorted_color = apply_effects(distorted_color, distorted_uv);
        
        if (dist < lens_radius) {
            // Inside lens: apply border blend
            float border = smoothstep(lens_radius - border_width, lens_radius, dist);
            final_color = mix(distorted_color, border_color, border);
        } else {
            // Outside lens: use regular color
            vec4 regular_color = texture(SCREEN_TEXTURE, uv);
            final_color = apply_effects(regular_color, uv);
        }
    } else {
        // No lens effect - process normally
        vec4 screen_color = texture(SCREEN_TEXTURE, uv);
        final_color = apply_effects(screen_color, uv);
    }
    
    // Apply vignette last (affects everything)
    if (vignette_strength > 0.0) {
        vec2 center = vec2(0.5);
        float dist = length(uv - center);
        float vignette = 1.0 - smoothstep(0.5, 1.5, dist) * vignette_strength;
        final_color.rgb *= vignette;
    }
    
    COLOR = final_color;
}