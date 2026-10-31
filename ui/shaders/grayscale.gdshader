// Locked collection entries: the mockups use filter: grayscale(1) brightness(0.55).
shader_type canvas_item;
uniform float brightness : hint_range(0.0, 1.0) = 0.55;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114)) * brightness;
	COLOR = vec4(vec3(g), c.a);
}
