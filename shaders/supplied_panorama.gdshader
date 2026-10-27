shader_type sky;
uniform sampler2D panorama : filter_linear_mipmap, repeat_enable;
uniform vec3 tint : source_color=vec3(1.0);
uniform float energy=0.7;
void sky(){
 vec2 uv=vec2(atan(EYEDIR.x,EYEDIR.z)/TAU+0.5,acos(clamp(EYEDIR.y,-1.0,1.0))/PI);
 COLOR=texture(panorama,uv).rgb*tint*energy;
}
