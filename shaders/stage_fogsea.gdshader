// Fog sea: a flat, render-only layer of rolling fog that fills the space outside the arena.
// Unshaded and opaque: coverage is a dithered cut-out (no alpha blending), so two layers sort cleanly against everything else.
// It is only present outside the arena square (arena_half) and fades in over edge_soft metres from that edge. The mesh also has a
// square hole at the arena edge, so it can never draw inside the arena even if a uniform is wrong.
// It drifts slowly, is quantised to 6 steps (PSX look), and reads solid at the grazing angles the player sees it from.
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, shadows_disabled, depth_draw_opaque;
uniform vec4 fog_color : source_color = vec4(0.6, 0.62, 0.58, 1.0);
uniform vec4 deep_color : source_color = vec4(0.4, 0.42, 0.4, 1.0);
uniform vec2 arena_half = vec2(96.0, 96.0);
uniform float density = 1.0;     // 0..1 how much of the layer is present
uniform float edge_soft = 12.0;  // metres from the arena edge over which it builds up
uniform float drift = 0.6;       // metres per second
uniform float steps = 6.0;
varying vec3 wpos;
float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p){
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float bayer4(vec2 p){ int x = int(mod(p.x, 4.0)); int y = int(mod(p.y, 4.0));
	float m[16] = float[](0.0,8.0,2.0,10.0,12.0,4.0,14.0,6.0,3.0,11.0,1.0,9.0,15.0,7.0,13.0,5.0); return (m[x + y*4] + 0.5) / 16.0; }
void vertex(){ wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 d = abs(wpos.xz) - arena_half;
	float outside = max(d.x, d.y);                 // metres past the arena edge (<= 0 inside)
	if (outside <= 0.0) discard;
	float edge = clamp(outside / edge_soft, 0.0, 1.0);
	float t = TIME * drift;
	float n = vnoise(wpos.xz * 0.045 + vec2(t, t * 0.6) * 0.05) * 0.6 + vnoise(wpos.xz * 0.11 - vec2(t * 0.8, t) * 0.05) * 0.4;
	// grazing angle: 1 when the plane is seen edge-on. Solid there, so the layer reads as a sea and not as patches.
	float graze = 1.0 - abs(dot(normalize(VIEW), NORMAL));
	float solid = smoothstep(0.55, 0.9, graze);
	float cover = clamp(density * edge * mix(0.35 + 0.9 * n, 1.0, solid), 0.0, 1.0);
	cover = floor(cover * steps + bayer4(FRAGCOORD.xy)) / steps;
	if (cover < 0.5) discard;
	float shade = floor(n * steps) / steps;
	ALBEDO = mix(deep_color.rgb, fog_color.rgb, shade);
}
