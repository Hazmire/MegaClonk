shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
uniform sampler2D runes:source_color,filter_nearest;
uniform vec3 portal_color:source_color=vec3(1.0,.1,.2);
uniform float pulse=.55;
void fragment(){
 vec2 p=UV-.5;float edge=1.0-smoothstep(.34,.5,length(p));
 vec3 glyph=texture(runes,UV).rgb;float marks=max(glyph.r,max(glyph.g,glyph.b));
 float ripple=.5+.5*sin(length(p)*55.0-TIME*2.0);
 ALBEDO=portal_color*(.08+marks*.7);EMISSION=portal_color*(marks+ripple*.12)*pulse;
 ALPHA=edge*(.16+marks*.65+ripple*.08);
}
