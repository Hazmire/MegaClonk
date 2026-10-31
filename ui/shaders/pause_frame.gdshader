// Pause backdrop (RunPause): the frozen gameplay frame blurred ~6px, desaturated and darkened to 72%.
shader_type canvas_item;
uniform float blur_px = 6.0;
uniform float saturation = 0.45;
uniform float brightness = 0.72;
void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * blur_px;
	vec4 sum = texture(TEXTURE, UV) * 0.2;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398;
		vec2 d = vec2(cos(a), sin(a));
		sum += texture(TEXTURE, UV + d * px) * 0.06 + texture(TEXTURE, UV + d * px * 0.5) * 0.04;
	}
	float g = dot(sum.rgb, vec3(0.299, 0.587, 0.114));
	vec3 c = mix(vec3(g), sum.rgb, saturation) * brightness;
	COLOR = vec4(c, 1.0);
}
