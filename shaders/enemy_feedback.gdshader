shader_type spatial;
render_mode cull_back;
uniform sampler2D albedo_map : source_color, hint_default_white;
uniform vec4 base_tint : source_color = vec4(1.0);
varying float damage_flash;
varying float spectral;
varying float flash_tint;
void vertex(){damage_flash=INSTANCE_CUSTOM.r;spectral=INSTANCE_CUSTOM.g;flash_tint=INSTANCE_CUSTOM.b;}
void fragment(){vec3 flash_rgb=mix(vec3(1.0),vec3(0.45,1.0,0.35),flash_tint);ALBEDO=mix(COLOR.rgb*texture(albedo_map,UV).rgb*base_tint.rgb,flash_rgb,damage_flash);ROUGHNESS=0.9;EMISSION=flash_rgb*0.35*damage_flash+vec3(0.1,0.35,0.4)*spectral;}
