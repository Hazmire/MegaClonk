// Out-of-bounds backdrop ring: a cut-out silhouette strip with its own haze.
// Scene fog is ignored (it would wash the silhouettes out completely at 90-240 m);
// instead each ring blends toward the stage's haze colour by a fixed amount, far rings more.
// Its foot dissolves into the fog bank by world height: below fog_floor it is pure fog colour, and it
// only comes out of the fog over fog_band metres. Each strip has a deep solid hillside under its ground
// line, so the bottom edge of the ring sits below the outer ground and is never on screen.
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform sampler2D strip : source_color, filter_nearest, repeat_enable;
uniform vec2 repeats = vec2(1.0, 1.0);
uniform vec4 haze_color : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform float haze = 0.3;        // 0 = crisp silhouette, 1 = fully hazed
uniform float lights_keep = 0.8; // lit windows punch through the haze (but not through the fog bank)
uniform float fog_floor = 0.0;   // world y: fully fog below this
uniform float fog_band = 12.0;   // metres over which it emerges from the fog
varying float wy;
float bayer4(vec2 p){ int x = int(mod(p.x, 4.0)); int y = int(mod(p.y, 4.0));
	float m[16] = float[](0.0,8.0,2.0,10.0,12.0,4.0,14.0,6.0,3.0,11.0,1.0,9.0,15.0,7.0,13.0,5.0); return (m[x + y*4] + 0.5) / 16.0; }
void vertex(){ wy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y; }
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
	// fog bank: PSX-stepped and dithered so it matches the fog sea in front of it
	float f = 1.0 - clamp((wy - fog_floor) / fog_band, 0.0, 1.0);
	f = clamp(floor(f * f * 8.0 + bayer4(FRAGCOORD.xy)) / 8.0, 0.0, 1.0);
	ALBEDO = mix(mix(t.rgb, haze_color.rgb, h), haze_color.rgb, f);
}
