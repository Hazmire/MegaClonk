// Fused weapon overlay: put on every MeshInstance3D of a Fusion weapon as material_overlay.
// Two-tone bands of the Fusion's colours running up the weapon, a bright rim, and a slow shimmer.
// Additive and unshaded, so it works on any model without touching its own materials.
shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;
uniform vec4 core : source_color = vec4(1.0);
uniform vec4 mid : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform vec4 acc : source_color = vec4(0.6, 0.9, 1.0, 1.0);
uniform float strength = 1.0;      // 0..1; the forge ramps it up as the weapon re-forms
uniform float band_scale = 9.0;    // bands per metre along the weapon
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float b = 0.5 + 0.5 * sin((lp.y + lp.z) * band_scale * 6.2832 - TIME * 2.0);
	vec3 band = mix(mid.rgb, acc.rgb, smoothstep(0.35, 0.65, b));
	ALBEDO = (band * 0.3 + core.rgb * rim * 0.6) * strength;
}
