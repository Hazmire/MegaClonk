// Megaclonk — endless-mode ghost.
// One unshaded material per tier. No transparency sorting: the "see-through" look is an ordered 4x4
// dither (screen-door) discard, so hundreds of ghosts draw in the opaque pass with no overdraw sorting
// problems. All animation (bob, tail ripple, arm grasp) is in the vertex shader, driven by vertex colours
// baked into the mesh:  R = tail weight (0 head -> 1 tail tip)   G = arm weight   B = face (0.5 socket, 1 eye)
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec4 body_color : source_color = vec4(0.62, 0.78, 0.75, 1.0);
uniform vec4 rim_color  : source_color = vec4(0.92, 1.0, 0.97, 1.0);
uniform vec4 eye_color  : source_color = vec4(0.72, 1.0, 0.94, 1.0);
uniform vec4 socket_color : source_color = vec4(0.02, 0.03, 0.03, 1.0);
uniform float opacity = 0.5;      // overall solidity; harder tiers are more solid
uniform float core = 0.3;         // how solid the middle of the body is (rim is always solid)
uniform float rim_power = 1.6;
uniform float wobble = 1.0;       // tail ripple amount
uniform float speed = 1.0;        // animation speed
uniform float flicker = 0.18;     // how much the body flickers
uniform float psx_snap = 180.0;   // vertex snapping (0 = off)
uniform float fade = 1.0;         // 0..1, drive from code to fade in on spawn / out on death

varying float tailw;
varying float armw;
varying float face;
varying float phase;
varying float inst_fade;

void vertex() {
	inst_fade = INSTANCE_CUSTOM.x; // per-ghost fade (multimesh custom data): 0 = not there, 1 = fully there
	tailw = COLOR.r; armw = COLOR.g; face = COLOR.b;
	// per-ghost phase from its world position so a swarm never moves in lockstep
	phase = fract(sin(dot(MODEL_MATRIX[3].xz, vec2(12.9898, 78.233))) * 43758.5453) * 6.2831;
	// stepped time: the motion stutters like a badly tracked tape instead of floating smoothly
	float tt = floor(TIME * 12.0) / 12.0;
	float t = tt * speed * 3.0 + phase;
	// now and then the whole thing twitches sideways for a frame
	float glitch = step(0.94, fract(sin(floor(TIME * 7.0) + phase * 17.0) * 43758.5453));
	// tail: a travelling ripple that grows toward the tip, plus a slow stretch
	VERTEX.x += sin(t + VERTEX.z * 3.2 + VERTEX.y * 1.5) * 0.16 * tailw * tailw * wobble;
	VERTEX.y += sin(t * 0.8 + VERTEX.z * 2.4) * 0.09 * tailw * wobble;
	VERTEX.z += tailw * tailw * 0.18 * (sin(t * 1.3) * 0.5 + 0.5) * wobble;
	// arms: fingers grasping, a slow reach
	VERTEX.y += sin(t * 1.7 + VERTEX.z * 5.0) * 0.035 * armw;
	VERTEX.z -= (sin(t * 0.9) * 0.5 + 0.5) * 0.12 * armw;
	// whole body bob, and the twitch (strongest at the head)
	VERTEX.y += sin(t * 0.9) * 0.06;
	VERTEX.x += glitch * 0.09 * (1.0 - tailw) * sign(sin(phase * 31.0));
	if (psx_snap > 0.0) {
		vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
		clip.xy = floor(clip.xy / clip.w * psx_snap) / psx_snap * clip.w;
		POSITION = clip;
	}
}

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0)); int y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	float m[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[i] + 0.5) / 16.0;
}

void fragment() {
	float ndv = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float rim = pow(1.0 - clamp(ndv, 0.0, 1.0), rim_power);
	vec3 c = mix(body_color.rgb, rim_color.rgb, rim);
	// solid at the rim, see-through in the middle, thinning out toward the tail tip
	float a = opacity * (core + (1.0 - core) * 1.2 * rim) * (1.0 - tailw * 0.65);
	a *= 1.0 - flicker + flicker * sin(TIME * 9.0 + phase * 3.0 + FRAGCOORD.y * 0.07);
	a *= 1.0 + (1.0 - smoothstep(0.0, 0.12, tailw)) * 0.7;   // the skull reads more solid than the shroud
	if (face > 0.25 && face < 0.75) { c = socket_color.rgb; a = 1.0; }          // eye sockets and mouth
	if (face >= 0.75) { c = eye_color.rgb * 1.6; a = 1.0; }                     // the eyes
	a *= fade * inst_fade;
	if (a < bayer4(FRAGCOORD.xy)) discard;
	ALBEDO = c;
}
