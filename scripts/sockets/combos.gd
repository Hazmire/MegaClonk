class_name Combos
extends RefCounted

# The six dual-element combinations. A weapon holding two different gems gets a combination on
# top of both individual effects. Combos are state-based: they fire from a hit when the target is
# in the right combination of statuses, then go on a per-target cooldown.
#
# Safety rules shared by every combo:
#  - all damage goes through StatusManager.deal(), never Game.hit(), so combos cannot trigger
#    each other, crit, or re-enter on_hit();
#  - every combo has a per-target cooldown and a damage cap;
#  - a global per-second budget bounds the work in a crowd;
#  - nothing here allocates unless a combo actually fires.
static var window_start=-1.0
static var window_count=0
static var power=1.0 # Heretic's Prism / Gem Cutter's Loupe, set per evaluate()
static var reach=1.0 # Alchemist's Retort radius

static func burning(e: Dictionary) -> bool:
 return float(e.get("burn",0.0))>0.0
static func budget_ok(game: Object) -> bool:
 var now=float(game.elapsed)
 if now<window_start or now-window_start>=1.0:window_start=now;window_count=0
 return window_count<int(Elements.TUNING.combos.budget_per_second)
static func spend() -> void:
 window_count+=1
static func capped(e: Dictionary, percent: float, cap: float) -> float:
 return minf(cap,float(e.max_hp)*percent)*power
static func announce(game: Object, e: Dictionary, _combo_name: String, color: Color) -> void:
 game.play_sound("status.combo")
 if is_instance_valid(game.combat_fx):game.combat_fx.burst("sparks_shower",e.pos,0.7,0.25)
 if game.settings.numbers and DisplayServer.get_name()!="headless" and is_instance_valid(game.numbers) and not game.settings.reduced:
  game.flash(e.pos,color,1.6)
# Called by StatusManager.on_hit after the single-element effects were applied.
static func evaluate(game: Object, e: Dictionary, weapon: int, combo: Dictionary) -> void:
 if combo.is_empty() or e.hp<=0 or not budget_ok(game):return
 var id=str(combo.id);var t: Dictionary=Elements.TUNING.combos.get(id,{})
 power=game.irt.combo_damage();reach=game.irt.combo_radius()
 var key="combo_"+id
 if not StatusManager.cooldown_ready(e,key):return
 match id:
  "thermal_shock":
   if burning(e) and StatusManager.chill_stacks(e)>=int(t.chill_stacks_consumed):
    StatusManager.consume_chill(e,int(t.chill_stacks_consumed))
    fire_combo(game,e,key,float(t.cooldown),combo)
    StatusManager.deal(game,e,capped(e,float(t.damage_percent_max_hp),float(t.damage_cap)),weapon,Color("ffb36b"))
  "overcharge":
   if burning(e) and StatusManager.stunned(e):
    fire_combo(game,e,key,float(t.cooldown),combo)
    StatusManager.deal(game,e,capped(e,float(t.damage_percent_max_hp),float(t.damage_cap)),weapon,Color("fff08a"))
  "caustic_combustion":
   if burning(e) and StatusManager.poisoned(e):
    fire_combo(game,e,key,float(t.cooldown),combo)
    for victim in game.nearby(e.pos,float(t.radius)*reach):
     StatusManager.deal(game,victim,capped(victim,float(t.damage_percent_max_hp),float(t.damage_cap)),weapon,Color("c8ff6a"))
    if is_instance_valid(game.combat_fx):game.combat_fx.supplied_burst("fire",e.pos,1.4)
  "toxic_conduction":
   if StatusManager.poisoned(e) and StatusManager.stunned(e):
    fire_combo(game,e,key,float(t.cooldown),combo)
    var list=game.nearby(e.pos,float(t.radius)*reach);var reached=0
    list.sort_custom(func(a,b): return a.pos.distance_squared_to(e.pos)<b.pos.distance_squared_to(e.pos))
    for victim in list:
     if victim==e:continue
     StatusManager.deal(game,victim,capped(victim,float(t.damage_percent_max_hp),float(t.damage_cap)),weapon,Color("a8ffb0"))
     StatusManager.apply_corrosive(game,victim,weapon)
     reached+=1
     if reached>=int(t.targets):break
  "cryoshock":
   if StatusManager.chill_stacks(e)>0 and StatusManager.stunned(e):
    fire_combo(game,e,key,float(t.cooldown),combo)
    for victim in game.nearby(e.pos,float(t.radius)*reach):
     if victim==e:continue
     StatusManager.deal(game,victim,capped(victim,float(t.damage_percent_max_hp),float(t.damage_cap)),weapon,Color("a8e8ff"))
     StatusManager.apply_chill(game,victim,int(t.chill_stacks))
static func fire_combo(game: Object, e: Dictionary, key: String, cooldown: float, combo: Dictionary) -> void:
 StatusManager.start_cooldown(e,key,cooldown*game.irt.combo_cooldown());spend();game.irt.on_combo()
 announce(game,e,str(combo.name),Color("ffffff"))
