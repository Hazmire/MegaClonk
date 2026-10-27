shader_type spatial;
render_mode diffuse_burley;
varying vec3 world_position;
void vertex() {
 world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void fragment() {
 vec2 cell=floor(world_position.xz*5.0);
 float grain=hash(cell);
 float patches=sin(world_position.x*0.17)*sin(world_position.z*0.13);
 float flecks=smoothstep(0.93,1.0,grain)*0.12;
 ALBEDO=COLOR.rgb*(0.9+grain*0.11+patches*0.07+flecks);
 ROUGHNESS=0.94;
}
