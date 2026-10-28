class_name PickupTally
extends RefCounted

# Running totals of gold and XP gained, shown beside the player's head. A total keeps growing
# while gains keep arriving and clears WINDOW seconds after the last one ("+44" after a gem
# burst). Gains are detected by watching the game's gold / XP / level between frames, so no
# pickup code needs to know about the display. Spending gold is ignored.
const WINDOW=4.0
const GOLD_COLOR=Color("ffd24a")
const XP_COLOR=Color("5ab4ff")
var gold_total=0.0
var gold_left=0.0
var xp_total=0.0
var xp_left=0.0
var last_gold=-1
var last_xp=0.0
var last_level=-1

func reset(game: Object) -> void:
 gold_total=0.0;gold_left=0.0;xp_total=0.0;xp_left=0.0
 last_gold=int(game.gold);last_xp=float(game.xp);last_level=int(game.level)
func update(game: Object,delta: float) -> void:
 if last_level<0 or int(game.level)<last_level:reset(game);return
 var gold_gain=int(game.gold)-last_gold
 if gold_gain>0:gold_total+=gold_gain;gold_left=WINDOW
 last_gold=int(game.gold)
 var xp_gain=float(game.xp)-last_xp
 for l in range(last_level,int(game.level)):xp_gain+=Catalog.threshold(l) # levels completed since last frame
 if xp_gain>0.0:xp_total+=xp_gain;xp_left=WINDOW
 last_xp=float(game.xp);last_level=int(game.level)
 gold_left=maxf(0.0,gold_left-delta);xp_left=maxf(0.0,xp_left-delta)
 if gold_left<=0.0:gold_total=0.0
 if xp_left<=0.0:xp_total=0.0
func gold_text() -> String:
 return "+%d"%roundi(gold_total) if gold_total>0.0 else ""
func xp_text() -> String:
 return "+%d"%roundi(xp_total) if xp_total>0.0 else ""
# 1.0 while fresh, fading to 0 over the last second.
func alpha(left: float) -> float:
 return clampf(left,0.0,1.0)
