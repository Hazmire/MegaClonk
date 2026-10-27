shader_type spatial;
render_mode cull_back;
uniform sampler2D albedo_map : source_color, hint_default_white;
uniform vec4 base_tint : source_color = vec4(1.0);
varying float damage_flash;
varying float spectral;
void vertex(){damage_flash=INSTANCE_CUSTOM.r;spectral=INSTANCE_CUSTOM.g;}
void fragment(){ALBEDO=mix(COLOR.rgb*texture(albedo_map,UV).rgb*base_tint.rgb,vec3(1.0,0.025,0.015),damage_flash);ROUGHNESS=0.9;EMISSION=vec3(0.3,0.0,0.0)*damage_flash+vec3(0.1,0.35,0.4)*spectral;}
