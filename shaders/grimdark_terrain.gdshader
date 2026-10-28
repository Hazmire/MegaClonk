shader_type spatial;
render_mode vertex_lighting,diffuse_lambert,specular_disabled,cull_disabled;
#define BILLBOARD_DISABLED
#define ALPHA_DISABLED
#define VERTEX_FOG_ENABLED
#include "res://shaders/vendor_psx/psx.gdshaderinc"
uniform sampler2D earth_texture:source_color,repeat_enable,filter_nearest;
uniform sampler2D grass_texture:source_color,repeat_enable,filter_nearest;
uniform sampler2D rock_texture:source_color,repeat_enable,filter_nearest;
uniform sampler2D variation:repeat_enable,filter_nearest;
uniform vec3 moss_low:source_color=vec3(.08,.14,.055);
uniform vec3 moss_high:source_color=vec3(.20,.27,.12);
uniform vec3 soil:source_color=vec3(.19,.15,.10);
uniform vec3 stone_low:source_color=vec3(.14,.15,.14);
uniform vec3 stone_high:source_color=vec3(.29,.28,.25);
varying vec3 world_pos;
varying vec3 world_normal;
void vertex(){
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
 #include "res://shaders/vendor_psx/psx_vertex.gdshaderinc"
}
void fragment(){
 #include "res://shaders/vendor_psx/psx_fragment.gdshaderinc"
 vec2 ground_uv=world_pos.xz*.22;
 float broad=texture(variation,world_pos.xz*.012).r;
 vec3 grass_tex=texture(grass_texture,ground_uv).rgb;
 vec3 earth_tex=texture(earth_texture,ground_uv).rgb;
 float grass_l=dot(grass_tex,vec3(.299,.587,.114));
 float earth_l=dot(earth_tex,vec3(.299,.587,.114));
 vec3 ground=mix(moss_low,moss_high,broad)*(.55+grass_l*1.5);
 ground=mix(ground,soil*(.6+earth_l),smoothstep(.56,.76,broad));
 vec2 rock_uv=vec2(world_pos.x+world_pos.z,world_pos.y)*.25;
 float rock_l=dot(texture(rock_texture,rock_uv).rgb,vec3(.299,.587,.114));
 vec3 rock=mix(stone_low,stone_high,rock_l);
 vec3 base=mix(rock,ground,smoothstep(.55,.8,abs(world_normal.y)));
 #ifdef VERTEX_FOG_ENABLED
 base=mix(base,v_fog_color,v_fog_strength);
 #endif
 ALBEDO=base;ROUGHNESS=1.0;SPECULAR=0.0;
}
