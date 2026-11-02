// Out-of-bounds backdrop ring: a cut-out silhouette strip with its own haze.
// Scene fog is ignored (it would wash the silhouettes out completely at 90-240 m);
// instead each ring blends toward the stage's haze colour by a fixed amount, far rings more.
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform sampler2D strip : source_color, filter_nearest, repeat_enable;
uniform vec2 repeats = vec2(1.0, 1.0);
uniform vec4 haze_color : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform float haze = 0.3;        // 0 = crisp silhouette, 1 = fully hazed
uniform float lights_keep = 0.8; // lit windows punch through the haze
void fragment() {
	// one lap of the ring = the strip, then the same strip mirrored. Seamless at both joins, and you
	// never see the same landmark twice in the same orientation.
	float u = fract(UV.x * repeats.x);
	float su = u < 0.5 ? u * 2.0 : 2.0 - u * 2.0;
	vec4 t = texture(strip, vec2(su, UV.y));
	if (t.a < 0.5) discard;
	float bright = max(max(t.r, t.g), t.b);
	float is_light = step(0.55, bright);
	float h = haze * (1.0 - is_light * lights_keep);
	// silhouettes never go to true black: the darkest they get is a fraction of the haze colour
	ALBEDO = max(mix(t.rgb, haze_color.rgb, h), haze_color.rgb * 0.5 + vec3(0.03, 0.015, 0.015));
}
