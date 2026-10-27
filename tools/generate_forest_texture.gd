extends SceneTree
func _initialize():
 var noise=FastNoiseLite.new();noise.seed=911;noise.frequency=0.018;noise.fractal_octaves=2
 var image=noise.get_seamless_image(256,256);var result=image.save_png("res://assets/config/forest_variation.png")
 print("Forest variation texture: ",result);quit(result)
