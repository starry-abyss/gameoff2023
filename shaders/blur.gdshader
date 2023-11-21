shader_type canvas_item;

uniform float lod: hint_range(0.0, 3.0) = 1.0;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void fragment() {
	COLOR = vec4(texture(SCREEN_TEXTURE, SCREEN_UV, lod).rgb, 1.0);
}