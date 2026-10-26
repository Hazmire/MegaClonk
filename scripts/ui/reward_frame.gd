class_name RewardFrame
extends PanelContainer
# Small original metal corner caps; no pixels are taken from the reference.
func _draw() -> void:
 for corner in [Vector2.ZERO,Vector2(size.x-9,0),Vector2(0,size.y-9),size-Vector2.ONE*9]:
  draw_rect(Rect2(corner,Vector2.ONE*9),Color("151b19"))
  draw_rect(Rect2(corner+Vector2.ONE,Vector2.ONE*7),Color("b7aa90"),false,1)
  draw_line(corner+Vector2(2,4),corner+Vector2(6,4),Color("e6dac0"),1)
  draw_line(corner+Vector2(4,2),corner+Vector2(4,6),Color("e6dac0"),1)
