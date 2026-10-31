class_name GemIcon
extends Control

# Large faceted diamond in an element's colour, used where a gem needs an icon (shop offers).
var element=""
static func add(parent: Node,element_id: String,edge: Color,size: int=66) -> Control:
 var slot=PanelContainer.new();slot.custom_minimum_size=Vector2(size,size+16);slot.add_theme_stylebox_override("panel",RewardScreens.style(edge,Color("152321")));parent.add_child(slot)
 var gem=GemIcon.new();gem.element=element_id;gem.custom_minimum_size=Vector2(size-12,size-12);gem.mouse_filter=Control.MOUSE_FILTER_IGNORE;slot.add_child(gem)
 return slot
func _draw() -> void:
 var c=size*0.5;var r=minf(size.x,size.y)*0.42;var color=Elements.color(element)
 var shape=PackedVector2Array([c+Vector2(0,-r),c+Vector2(r*0.75,0),c+Vector2(0,r),c+Vector2(-r*0.75,0)])
 draw_colored_polygon(shape,color)
 draw_colored_polygon(PackedVector2Array([c+Vector2(0,-r),c+Vector2(r*0.75,0),c]),color.lightened(0.3))
 draw_colored_polygon(PackedVector2Array([c+Vector2(0,r),c+Vector2(-r*0.75,0),c]),color.darkened(0.3))
 draw_polyline(shape+PackedVector2Array([shape[0]]),color.lightened(0.6),2.0)
