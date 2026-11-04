// Fog wall: an endless curtain of rolling fog at the map boundary.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform vec4 fog_color : source_color = vec4(0.65, 0.69, 0.65, 1.0);
uniform vec4 glow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float density = 0.75;
uniform float glow = 0.0;
uniform float wall_len = 100.0;
varying vec3 wpos;
float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p){ vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i), hash(i+vec2(1,0)), f.x), mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), f.x), f.y); }
float fbm(vec2 p){ float a = 0.5, s = 0.0; for (int i = 0; i < 5; i++){ s += a*vnoise(p); p *= 2.03; a *= 0.5; } return s; }
void vertex(){ wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment(){
	vec2 p = vec2((wpos.x + wpos.z) * 0.06, wpos.y * 0.035);
	float n = fbm(p + vec2(TIME * 0.03, -TIME * 0.05));
	float n2 = fbm(p * 2.7 - vec2(TIME * 0.07, 0.0));
	float a = density * (0.35 + 0.95 * n * n) * (0.8 + 0.4 * n2);
	a *= mix(0.5, 1.0, smoothstep(-8.0, 40.0, wpos.y));
	a *= smoothstep(-70.0, -25.0, wpos.y);           // fades into the abyss below
	// pixelate like PSX: quantise alpha
	a = floor(a * 8.0) / 8.0;
	vec3 c = fog_color.rgb * (0.85 + 0.25 * n2) + glow_color.rgb * glow * smoothstep(30.0, -10.0, wpos.y) * (0.6 + 0.6 * n);
	ALBEDO = c;
	ALPHA = clamp(a, 0.0, 0.97);
}
