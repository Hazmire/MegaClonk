shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled, cull_disabled;
#define BILLBOARD_DISABLED
#define ALPHA_DISABLED
#define VERTEX_FOG_ENABLED
#include "res://shaders/vendor_psx/psx.gdshaderinc"
uniform bool foliage=false;
uniform int season=0;
uniform float saturation=0.62;
uniform vec4 flash_color:source_color=vec4(1.0);
uniform float hit_flash=0.0;
varying float damage_flash;
void vertex(){
#include "res://shaders/vendor_psx/psx_vertex.gdshaderinc"
 damage_flash=max(INSTANCE_CUSTOM.r,hit_flash);
}
void fragment(){
#include "res://shaders/vendor_psx/psx_fragment.gdshaderinc"
 float l=dot(ALBEDO,vec3(.299,.587,.114));ALBEDO=mix(vec3(l),ALBEDO,saturation);
 if(foliage){
  float green=smoothstep(.01,.1,ALBEDO.g-max(ALBEDO.r,ALBEDO.b));
  if(season==1)ALBEDO=mix(ALBEDO,vec3(l)*vec3(1.25,1.04,.51),green*.92);
  if(season==2)ALBEDO=vec3(l)*vec3(.78,.73,.66);
 }
 ALBEDO=mix(ALBEDO,flash_color.rgb,damage_flash);
 EMISSION+=flash_color.rgb*damage_flash*.42;
 ROUGHNESS=1.0;SPECULAR=0.0;
}
