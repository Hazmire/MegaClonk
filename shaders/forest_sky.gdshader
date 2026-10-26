shader_type sky;
// Static directional sky: no TIME dependency or per-frame radiance rebuild.
uniform vec3 zenith : source_color = vec3(0.035, 0.075, 0.18);
uniform vec3 horizon : source_color = vec3(0.28, 0.38, 0.53);
uniform vec3 cloud_tint : source_color = vec3(0.48, 0.57, 0.70);
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.48;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float soft_noise(vec2 p) {
 vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void sky() {
 vec3 direction=normalize(EYEDIR);
 float elevation=max(direction.y,0.0);
 vec3 base=mix(horizon,zenith,pow(elevation,0.48));
 float glow=pow(max(dot(direction,normalize(vec3(-0.5,0.12,0.7))),0.0),8.0);
 base+=vec3(0.07,0.035,0.015)*glow*(1.0-elevation);
 if(direction.y>0.035 && cloud_coverage>0.0) {
  vec2 p=direction.xz/(direction.y+0.22)*2.6+vec2(7.3,3.8);
  float field=soft_noise(p)*0.62+soft_noise(p*2.1)*0.27+soft_noise(p*4.3)*0.11;
  float cloud=smoothstep(1.0-cloud_coverage,0.79,field)*smoothstep(0.035,0.19,elevation);
  base=mix(base,cloud_tint,cloud*0.62);
 }
 COLOR=base;
}
