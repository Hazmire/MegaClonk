shader_type spatial;
// Pooled PSX effect solids (angular bolt segments, shards): unshaded, hard-edged, vertex-snapped through the project's vendor PSX
// includes (same snap, fog and 640x360 composite as the rest of the world). Instance colour tints.
render_mode unshaded, cull_disabled, depth_draw_opaque;
#define BILLBOARD_DISABLED
#define ALPHA_DISABLED
#define VERTEX_FOG_ENABLED
#include "res://shaders/vendor_psx/psx.gdshaderinc"
void vertex(){
#include "res://shaders/vendor_psx/psx_vertex.gdshaderinc"
}
void fragment(){
#include "res://shaders/vendor_psx/psx_fragment.gdshaderinc"
}
