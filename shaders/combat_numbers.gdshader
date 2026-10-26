shader_type spatial;
render_mode unshaded,cull_disabled,depth_test_disabled,depth_draw_never;
uniform sampler2D glyphs : source_color,filter_nearest,repeat_disable;
varying flat float glyph;
void vertex(){
 glyph=INSTANCE_CUSTOM.x;
 mat4 model_view=VIEW_MATRIX*MODEL_MATRIX;
 model_view[0].xyz=vec3(length(MODEL_MATRIX[0].xyz),0.0,0.0);
 model_view[1].xyz=vec3(0.0,length(MODEL_MATRIX[1].xyz),0.0);
 model_view[2].xyz=vec3(0.0,0.0,1.0);
 MODELVIEW_MATRIX=model_view;
}
void fragment(){
 vec4 value=texture(glyphs,vec2((UV.x+glyph)/16.0,UV.y));
 if(value.a<0.5)discard;
 ALBEDO=value.rgb*COLOR.rgb;
 ALPHA=1.0;
}
