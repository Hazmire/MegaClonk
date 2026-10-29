// Full-screen post overlay for every Fog County screen: scanlines + vignette,
// plus the two HUD states from the mockup (low-HP pulse, Stopwatch tint).
// Put it on a ColorRect (anchors full rect, mouse_filter = IGNORE) as the top-most UI child.
shader_type canvas_item;

uniform float scanline_strength : hint_range(0.0, 0.5) = 0.14; // mockup: rgba(0,0,0,0.14..0.16)
uniform float scanline_period_px = 3.0;                         // 1px dark every 3px
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.58;
uniform float vignette_start : hint_range(0.0, 1.0) = 0.46;
uniform float low_hp : hint_range(0.0, 1.0) = 0.0;             // 0 off, 1 full; pulses at 1.1 s
uniform vec4 low_hp_color : source_color = vec4(0.494, 0.094, 0.125, 0.85);
uniform float stopwatch : hint_range(0.0, 1.0) = 0.0;          // cool blue edge glow while time is slowed
uniform vec4 stopwatch_color : source_color = vec4(0.498, 0.769, 1.0, 0.35);

void fragment() {
	vec2 px = FRAGCOORD.xy;
	float line = step(scanline_period_px - 1.0, mod(px.y, scanline_period_px));
	vec2 uv = SCREEN_UV - 0.5;
	uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x * 0.5625; // keep the ellipse at 16:9
	float d = length(uv) * 1.6;
	float vig = smoothstep(vignette_start, 1.0, d) * vignette_strength;

	float a = line * scanline_strength;
	vec3 col = vec3(0.0);
	float alpha = max(a, vig);

	float edge = smoothstep(0.62, 1.15, d); // only the screen edges
	if (low_hp > 0.0) {
		float pulse = 0.55 + 0.45 * (0.5 + 0.5 * sin(TIME * 6.2831 / 1.1));
		float k = edge * low_hp * pulse * low_hp_color.a;
		col = mix(col, low_hp_color.rgb, k / max(alpha + k, 0.0001));
		alpha = max(alpha, k);
	}
	if (stopwatch > 0.0) {
		float k = edge * stopwatch * stopwatch_color.a;
		col = mix(col, stopwatch_color.rgb, k / max(alpha + k, 0.0001));
		alpha = max(alpha, k);
	}
	COLOR = vec4(col, alpha);
}
