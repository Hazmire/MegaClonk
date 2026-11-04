shader_type spatial;
render_mode vertex_lighting,diffuse_lambert,specular_disabled,cull_disabled;
#define BILLBOARD_DISABLED
#define ALPHA_DISABLED
#include "res://shaders/vendor_psx/psx.gdshaderinc"
// Stage ground: world-space triplanar, nearest-filtered 128 px textures. Flat cells use `top`, cells at the lowest terrain level use
// `low`, vertical terrace faces use `side` (optionally with an emission mask). Geometry is untouched; this only picks texels.
uniform sampler2D top_tex:source_color,repeat_enable,filter_nearest;
uniform sampler2D side_tex:source_color,repeat_enable,filter_nearest;
uniform sampler2D low_tex:source_color,repeat_enable,filter_nearest;
uniform sampler2D emission_tex:source_color,repeat_enable,filter_nearest;
uniform float tex_scale=.25;
uniform float low_scale=.18;
uniform float low_y=0.0;
uniform float emission_strength=0.0;
varying vec3 world_pos;
varying vec3 world_normal;
void vertex(){
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
 #include "res://shaders/vendor_psx/psx_vertex.gdshaderinc"
}
vec3 tri(sampler2D t,vec3 p,vec3 w,float s){
 return texture(t,p.zy*s).rgb*w.x+texture(t,p.xz*s).rgb*w.y+texture(t,p.xy*s).rgb*w.z;
}
void fragment(){
 #include "res://shaders/vendor_psx/psx_fragment.gdshaderinc"
 vec3 w=pow(abs(world_normal),vec3(4.0));w/=(w.x+w.y+w.z);
 float up=smoothstep(.45,.65,world_normal.y);
 float is_low=step(world_pos.y,low_y+.15);
 vec3 ground=mix(tri(top_tex,world_pos,w,tex_scale),tri(low_tex,world_pos,w,low_scale),is_low);
 vec3 wall=tri(side_tex,world_pos,w,tex_scale);
 ALBEDO=mix(wall,ground,up);
 EMISSION=tri(emission_tex,world_pos,w,tex_scale)*emission_strength*(1.0-up);
 ROUGHNESS=1.0;SPECULAR=0.0;
}
