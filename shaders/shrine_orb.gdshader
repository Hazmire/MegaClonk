shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
varying float charge;
varying float occupied;
varying float completed;
void vertex(){charge=INSTANCE_CUSTOM.r;occupied=INSTANCE_CUSTOM.g;completed=INSTANCE_CUSTOM.b;}
void fragment(){
 if(completed>0.5)discard;
 float edge=pow(1.0-clamp(abs(dot(normalize(NORMAL),normalize(VIEW))),0.0,1.0),3.0);
 float pulse=0.5+0.5*sin(TIME*2.0+charge*6.28);
 vec3 color=mix(vec3(0.18,0.65,0.95),vec3(0.30,1.0,0.68),occupied);
 ALBEDO=color;EMISSION=color*(0.1+charge*0.3);
 ALPHA=0.025+edge*(0.11+occupied*0.05)+charge*0.025+pulse*0.008;
}
