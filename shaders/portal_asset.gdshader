shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_map : source_color,filter_nearest_mipmap;
uniform sampler2D emission_map : source_color,filter_nearest_mipmap;
uniform sampler2D metallic_map : filter_nearest_mipmap;
uniform vec3 portal_color : source_color=vec3(1.0,0.10,0.20);
uniform float pulse=0.65;
void fragment(){
 vec3 base=texture(albedo_map,UV).rgb;
 vec3 light=texture(emission_map,UV).rgb;
 float magic=smoothstep(0.03,0.15,base.b-base.r);
 float rune=clamp((light.g-0.12)*1.8,0.0,1.0);
 ALBEDO=mix(base*0.75,portal_color*(0.08+rune*0.12),magic);
 EMISSION=portal_color*rune*pulse*magic;
 ROUGHNESS=0.88;METALLIC=texture(metallic_map,UV).r*0.2;
}
