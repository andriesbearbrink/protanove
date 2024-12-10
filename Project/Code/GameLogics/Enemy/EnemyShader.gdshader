shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE;

    float outline = texture(TEXTURE, UV + vec2(-size.x, 0) * outline_width).a;
    outline += texture(TEXTURE, UV + vec2(0, size.y) * outline_width).a;
    outline += texture(TEXTURE, UV + vec2(size.x, 0) * outline_width).a;
    outline += texture(TEXTURE, UV + vec2(0, -size.y) * outline_width).a;
    outline = min(outline, 1.0);

    vec4 color = texture(TEXTURE, UV);
    COLOR = mix(base_color, outline_color, outline - color.a);
    COLOR.a = max(color.a, outline);
}