class_name ForestRegions
extends RefCounted
# Binary spatial subdivision creates unequal landmasses and a changing T-junction
# graph. Heights are sampled independently of distance from the map centre.
static func choose_band(rng: RandomNumberGenerator,settings: ForestSettings) -> int:
 var weights=settings.elevation_band_weights
 if weights==null or weights.size()!=settings.elevation_bands-1:return rng.randi_range(1,settings.elevation_bands-1)
 var total=0.0
 for weight in weights:total+=maxf(0,weight)
 if total<=0:return rng.randi_range(1,settings.elevation_bands-1)
 var roll=rng.randf()*total
 for i in weights.size():
  roll-=maxf(0,weights[i])
  if roll<0:return i+1
 return weights.size()
static func partition(rng: RandomNumberGenerator,settings: ForestSettings) -> Array:
 var rectangles=[Rect2(-96,-96,192,192)]
 var target=rng.randi_range(settings.minimum_regions,settings.maximum_regions)
 while rectangles.size()<target:
  var candidates=[]
  for i in rectangles.size():
   if maxf(rectangles[i].size.x,rectangles[i].size.y)>=settings.minimum_plateau_size*2:candidates.append(i)
  if candidates.is_empty():break
  # Prefer broad areas without forcing a regular grid or a fixed split order.
  var pick=candidates[rng.randi_range(0,candidates.size()-1)]
  for i in settings.plateau_size_bias:
   var other=candidates[rng.randi_range(0,candidates.size()-1)]
   if rectangles[other].get_area()>rectangles[pick].get_area():pick=other
  var rect: Rect2=rectangles.pop_at(pick)
  var axis=0 if rng.randf()<0.5 else 1
  if rect.size[axis]<settings.minimum_plateau_size*2:axis=1-axis
  var cut=float(rng.randi_range(int(settings.minimum_plateau_size/2),int((rect.size[axis]-settings.minimum_plateau_size)/2))*2)
  var first=rect;first.size[axis]=cut
  var second=rect;second.position[axis]+=cut;second.size[axis]-=cut
  rectangles.append(first);rectangles.append(second)
 var regions=[]
 for rect in rectangles:
  var band=0 if rng.randf()>settings.elevated_coverage else choose_band(rng,settings)
  regions.append({"id":regions.size(),"rect":rect,"band":band,"height":float(band)*settings.maximum_elevation/(settings.elevation_bands-1)})
 var shuffled=range(regions.size())
 for i in range(shuffled.size()-1,0,-1):
  var j=rng.randi_range(0,i);var temp=shuffled[i];shuffled[i]=shuffled[j];shuffled[j]=temp
 for band in settings.elevation_bands:
  var region=regions[shuffled[band]];region.band=band;region.height=float(band)*settings.maximum_elevation/(settings.elevation_bands-1)
 return regions
static func draft(rng: RandomNumberGenerator,settings: ForestSettings) -> Dictionary:
 for attempt in 256:
  var regions=partition(rng,settings);var candidates=[]
  for a in regions.size():
   for b in range(a+1,regions.size()):
    var ra: Rect2=regions[a].rect;var rb: Rect2=regions[b].rect
    var axis=-1;var boundary=0.0;var lo=0.0;var hi=0.0
    if ra.end.x==rb.position.x or rb.end.x==ra.position.x:
     axis=0;boundary=maxf(ra.position.x,rb.position.x);lo=maxf(ra.position.y,rb.position.y);hi=minf(ra.end.y,rb.end.y)
    elif ra.end.y==rb.position.y or rb.end.y==ra.position.y:
     axis=1;boundary=maxf(ra.position.y,rb.position.y);lo=maxf(ra.position.x,rb.position.x);hi=minf(ra.end.x,rb.end.x)
    var width=settings.minimum_ramp_width
    if axis<0 or hi-lo<width+8:continue
    var first=a;var second=b
    if ra.position[axis]>rb.position[axis]:first=b;second=a
    var difference=absf(regions[first].height-regions[second].height)
    var length=maxf(settings.preferred_ramp_length,ceil(difference/tan(deg_to_rad(settings.maximum_ramp_slope))/4)*4)
    if length>settings.maximum_ramp_length or length/2+4>minf(ra.size[axis],rb.size[axis]):continue
    for center in range(int(lo+width/2+4),int(hi-width/2-3),2):
     var point=Vector2(boundary,center) if axis==0 else Vector2(center,boundary)
     var size=Vector2(length,width) if axis==0 else Vector2(width,length)
     candidates.append({"from":first,"to":second,"axis":axis,"rect":Rect2(point-size/2,size),"h0":regions[first].height,"h1":regions[second].height,"length":length,"width":width})
  for i in range(candidates.size()-1,0,-1):
   var j=rng.randi_range(0,i);var temp=candidates[i];candidates[i]=candidates[j];candidates[j]=temp
  var parents=range(regions.size());var ramps=[];var used={}
  for loops in [false,true]:
   for ramp in candidates:
    var a=ramp.from;var b=ramp.to
    while parents[a]!=a:a=parents[a]
    while parents[b]!=b:b=parents[b]
    if not loops and a==b:continue
    if loops and (used.has(str(ramp.from)+":"+str(ramp.to)) or rng.randf()>settings.extra_connection_frequency):continue
    var clear=true
    for selected in ramps:
     if selected.rect.grow(2).intersects(ramp.rect.grow(2)):clear=false;break
    if not clear:continue
    ramp.backbone=not loops;ramps.append(ramp);parents[a]=b;used[str(ramp.from)+":"+str(ramp.to)]=true
    if loops and ramps.size()>=regions.size()-1+settings.extra_connections:break
   if not loops and ramps.size()!=regions.size()-1:break
  if ramps.size()<regions.size()-1:continue
  # Large safe flat interiors are reserved before collision or scenery exists.
  var all_safe=true
  for region in regions:
   var anchors=[];var rect: Rect2=region.rect.grow(-8)
   for i in 160:
    var p=Vector2(floor(rng.randf_range(rect.position.x,rect.end.x)/2)*2+1,floor(rng.randf_range(rect.position.y,rect.end.y)/2)*2+1)
    var clear=true
    for ramp in ramps:
     if ramp.rect.grow(5).has_point(p):clear=false;break
    for other in anchors:
     if p.distance_to(other)<9:clear=false;break
    if clear:anchors.append(p)
    if anchors.size()>=6:break
   if anchors.size()<2:all_safe=false;break
   region.anchors=anchors;region.anchor=anchors[0]
  if all_safe:return {"regions":regions,"ramps":ramps,"attempts":attempt+1}
 assert(false,"Unable to construct safe vertical forest region graph")
 return {}
static func region_at(regions: Array,ramps: Array,p: Vector2,seed_value: int,amplitude: float) -> int:
 # Cell-aligned notches soften long orthogonal cliff outlines. Disable distortion
 # around ramp mouths; every ramp keeps its exact constant plane and landings.
 var warped=p
 var influence=1.0
 for ramp in ramps:
  var rect: Rect2=ramp.rect
  var distance=p.distance_to(p.clamp(rect.position,rect.end))
  influence=minf(influence,smoothstep(4,24,distance))
 if posmod(seed_value,2)==0:warped.x+=round(sin(p.y*0.09+seed_value%31)*amplitude*influence/2)*2
 else:warped.y+=round(sin(p.x*0.075+seed_value%43)*amplitude*influence/2)*2
 warped=warped.clamp(Vector2(-95.99,-95.99),Vector2(95.99,95.99))
 for region in regions:
  if region.rect.has_point(warped):return region.id
 return 0
