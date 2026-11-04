class_name Armor
extends RefCounted
# Armour is stored as points (game.stats.armor) and shown as the damage reduction they give: points / (75 + points). Diminishing
# returns, never 100%: 4 points ~5%, 25 ~25%, 75 = 50%, 300 = 80%.
const K=75.0
static func reduction(points: float) -> float:
 var a=maxf(0.0,points);return a/(K+a)
static func multiplier(points: float) -> float:return 1.0-reduction(points)
