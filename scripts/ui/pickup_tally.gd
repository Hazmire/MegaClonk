class_name PickupTally
extends RefCounted

# Running totals of gold ($) and XP (+) gained, shown beside the player's head.
# A total keeps growing while gains keep arriving and stays up for WINDOW seconds after the
# last one, then fades and starts again from zero. The shown number counts up towards the real
# total (so a 20-gold burst visibly ticks to $20) and every increase kicks a bounce.
# Gains are detected by watching gold / XP / level between frames, so no pickup code needs to
# know about the display. Spending gold is ignored. Time is advanced by the caller using real
# time, never by physics ticks.
const WINDOW=4.0
const FADE=0.8
const COUNT_RATE=2.5       # share of the remaining gap closed per second at minimum speed
const MIN_STEPS_PER_SECOND=40.0
const BOUNCE_DECAY=7.0
const GOLD_COLOR=Color("ffd24a")
const XP_COLOR=Color("5ab4ff")
class Counter:
 var target=0.0       # real total gained
 var shown=0.0        # animated number on screen
 var left=0.0         # seconds until the total clears
 var bounce=0.0       # 0..1+, decays; drives the scale kick
 var shown_int=0
 func add(amount: float,window: float) -> void:
  target+=amount;left=window
 func step(delta: float) -> void:
  if shown<target:
   var rate=maxf((target-shown)*PickupTally.COUNT_RATE*4.0,PickupTally.MIN_STEPS_PER_SECOND)
   shown=minf(target,shown+rate*delta)
  var now=int(floor(shown+0.0001))
  if now>shown_int:
   # Bigger totals bounce harder, up to a cap, so a long streak feels like it is building.
   bounce=minf(1.6,0.55+log(1.0+float(now))*0.14);shown_int=now
  bounce=maxf(0.0,bounce-delta*PickupTally.BOUNCE_DECAY*maxf(0.35,bounce))
  left=maxf(0.0,left-delta)
  if left<=0.0:
   target=0.0;shown=0.0;shown_int=0;bounce=0.0
 func alpha() -> float:
  return clampf(left/PickupTally.FADE,0.0,1.0)
var gold=Counter.new()
var xp=Counter.new()
var last_gold=-1
var last_xp=0.0
var last_level=-1
var gold_gain_now=0   # gains seen by the latest update() (PickupPopups reads these)
var xp_gain_now=0.0

func reset(game: Object) -> void:
 gold=Counter.new();xp=Counter.new()
 last_gold=int(game.gold);last_xp=float(game.xp);last_level=int(game.level)
func update(game: Object,delta: float) -> void:
 gold_gain_now=0;xp_gain_now=0.0
 if last_level<0 or int(game.level)<last_level:reset(game);return
 var gold_gain=int(game.gold)-last_gold
 if gold_gain>0:gold.add(gold_gain,WINDOW);gold_gain_now=gold_gain
 last_gold=int(game.gold)
 var xp_gain=float(game.xp)-last_xp
 for l in range(last_level,int(game.level)):xp_gain+=Catalog.threshold(l) # levels completed since last frame
 if xp_gain>0.0:xp.add(xp_gain,WINDOW);xp_gain_now=xp_gain
 last_xp=float(game.xp);last_level=int(game.level)
 gold.step(delta);xp.step(delta)
func gold_text() -> String:
 return "$%d"%int(floor(gold.shown+0.0001)) if gold.target>0.0 else ""
func xp_text() -> String:
 return "+%d"%int(floor(xp.shown+0.0001)) if xp.target>0.0 else ""
# True totals (what the number is counting towards).
func gold_total() -> int:
 return roundi(gold.target)
func xp_total() -> int:
 return roundi(xp.target)
