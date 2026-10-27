shader_type spatial;
render_mode cull_disabled;
uniform sampler2D base_texture : source_color,filter_nearest;
uniform bool has_texture=false;
uniform vec4 base_color : source_color=vec4(1.0);
uniform vec3 foliage : source_color=vec3(0.5,0.8,0.3);
uniform float strength=0.0;
uniform vec3 rock_tint : source_color=vec3(1.0);
uniform bool rock=false;
void fragment(){
 vec4 c=base_color;
 if(has_texture)c*=texture(base_texture,UV);
 if(c.a<0.4)discard;
 float green=smoothstep(0.005,0.12,c.g-max(c.r,c.b));
 vec3 leaf=foliage*clamp(max(c.r,max(c.g,c.b))*1.5,0.35,1.25);
 float grain=dot(c.rgb,vec3(0.299,0.587,0.114));
 ALBEDO=rock?vec3(0.24,0.28,0.31)*(0.85+grain*0.30)*rock_tint:mix(c.rgb,leaf,green*strength);
 ROUGHNESS=0.9;
}
