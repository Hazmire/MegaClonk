shader_type canvas_item;
// Adapted from supplied snotbane PSX Visuals post-process. Applied only to 3D texture.
const float PSX_DITHER_MATRIX[16]=float[](0.,8.,2.,10.,12.,4.,14.,6.,3.,11.,1.,9.,15.,7.,13.,5.);
uniform int bit_depth=5;
uniform bool dither_enabled=true;
void fragment(){
 vec3 color=texture(TEXTURE,UV).rgb;
 float levels=float((1<<bit_depth)-1);
 ivec2 p=ivec2(floor(UV/ TEXTURE_PIXEL_SIZE));
 float bias=dither_enabled ? PSX_DITHER_MATRIX[(p.x&3)+(p.y&3)*4]/16. : .5;
 COLOR=vec4(clamp(floor(color*levels+bias)/levels,vec3(0.),vec3(1.)),1.);
}
