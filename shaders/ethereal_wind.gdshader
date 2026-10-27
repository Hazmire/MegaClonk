shader_type spatial;
render_mode unshaded, cull_disabled;

group_uniforms Color;
uniform vec3 primary_color : source_color = vec3(1.0,0.8,0.2);
uniform vec3 secondary_color : source_color = vec3(1.0,0.4,0.1);
uniform float emission = 2.0;
uniform float color_curve = 1.0;
uniform float hue_variation = 0.1;

group_uniforms Shape;
uniform sampler2D noise_texture;
uniform vec2 noise_scale = vec2(3.0, 1.0);
uniform vec2 noise_scroll = vec2(0.1, 0.4);
uniform float shape_curve = 2.0;

group_uniforms Transparency;
uniform float edge_hardness : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float edge_position : hint_range(0.0, 1.0, 0.01) = 0.2;
// No depth-buffer sampling: particles use ordinary geometry depth tests.

varying flat int id;

vec3 shift_hue(vec3 color, float shift) {
	vec3 gray = vec3(0.57735);
	vec3 projection = gray * dot(gray, color.rgb);
	vec3 U = color.rgb - projection;
	vec3 V = cross(gray, U);
	vec3 shifted = U * cos(shift * 2.0 * PI) + V * sin(shift * 2.0 * PI) + projection;
	return shifted;
}

void vertex() {
	id = INSTANCE_ID;
}

void fragment() {
	float noise = texture(noise_texture, (UV + COLOR.r) * 0.3 * noise_scale + (TIME * noise_scroll)).r;
	
	float shape = (1.0 - length(UV * 2.0 - 1.0)) * noise;
	shape = smoothstep(0.2, 0.8, shape);
	
	ALPHA = shape * COLOR.a;
	
	vec3 color = mix(secondary_color, primary_color, noise);
	color = shift_hue(color, (COLOR.r - 0.5) * hue_variation);
	
	ALBEDO = color * emission;
	
	

	ALPHA = clamp((ALPHA - edge_position) / (1.0 - edge_hardness), 0.0, 1.0);
}