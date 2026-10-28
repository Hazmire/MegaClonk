
global uniform float psx_affine_strength;
global uniform float psx_precision_uv;
global uniform float psx_precision_xy;
global uniform float psx_precision_z;

uniform float i_precision_uv = 1.0;
uniform float i_precision_xy = 1.0;
uniform float i_precision_z = 1.0;

uniform bool u_vertex_color_use_as_albedo = true;

uniform sampler2D u_albedo_texture: hint_default_white, filter_nearest;
uniform vec4 u_albedo_color: source_color = vec4(1.0);

varying vec3 v_vertex_color;
varying vec4 v_clip;
varying vec2 v_uv;
varying vec2 v_uv2;

#if (!defined ALPHA_DISABLED) && (defined ALPHA_SCISSOR)
uniform float u_alpha_scissor_threshold: hint_range(0.0, 1.0, 0.01) = 0.5;
#endif

#if defined EMISSION_ADD
uniform vec3 u_emission: source_color = vec3(0.0, 0.0, 0.0);
uniform float u_emission_energy_multiplier = 1.0;
uniform bool u_emission_on_uv2 = false;
uniform sampler2D u_emission_texture: hint_default_black, filter_nearest;
#elif defined EMISSION_MULTIPLY
uniform vec3 u_emission: source_color = vec3(0.0, 0.0, 0.0);
uniform float u_emission_energy_multiplier = 1.0;
uniform bool u_emission_on_uv2 = false;
uniform sampler2D u_emission_texture: hint_default_black, filter_nearest;
#endif

#if (defined VERTEX_FOG_ENABLED) || (defined VERTEX_FOG_ALWAYS)
global uniform vec4 psx_fog_color;
global uniform float psx_fog_far;
global uniform float psx_fog_near;

varying float v_fog_strength;
varying vec3 v_fog_color;
#endif


