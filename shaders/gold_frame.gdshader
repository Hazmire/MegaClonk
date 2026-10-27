shader_type canvas_item;
void fragment() {
 vec2 uv=UV;
 float edge=min(min(uv.x,1.0-uv.x),min(uv.y,1.0-uv.y));
 float shine=pow(max(0.0,sin((uv.x+uv.y)*7.0-TIME*2.0)),12.0);
 COLOR=vec4(vec3(0.65,0.43,0.12)+vec3(0.35,0.35,0.25)*shine,step(edge,0.045));
}
