shader_type canvas_item;

uniform vec3 tint;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	
	// remove black background
	if (color.r < 0.01 && color.g < 0.01 && color.b < 0.01)
	{
		discard;
	}
		
	// tint
	color = vec4(color.rgb * 0.2 * tint, color.a);
	
	COLOR = color;
}
