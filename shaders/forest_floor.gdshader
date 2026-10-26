shader_type spatial;
render_mode cull_back;
uniform sampler2D variation : repeat_enable,filter_linear_mipmap;
varying vec3 world_pos;
varying vec3 world_normal;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 float broad=texture(variation,world_pos.xz*0.012).r;
 float detail=texture(variation,world_pos.xz*0.24).r;
 vec3 moss=mix(vec3(0.08,0.18,0.045),vec3(0.22,0.34,0.09),broad);
 vec3 soil=vec3(0.20,0.135,0.065)*(0.85+detail*0.3);
 vec3 grass=mix(moss,soil,smoothstep(0.60,0.78,broad));
 grass*=0.91+detail*0.18;
 float stone_noise=texture(variation,vec2(world_pos.x+world_pos.z,world_pos.y)*0.065).r;
 vec3 stone=mix(vec3(0.13,0.15,0.18),vec3(0.30,0.28,0.24),stone_noise);
 stone*=0.9+0.1*sin(world_pos.y*0.8+stone_noise*3.0);
 ALBEDO=mix(stone,grass,smoothstep(0.55,0.8,abs(world_normal.y)));
 ROUGHNESS=0.95;
}
