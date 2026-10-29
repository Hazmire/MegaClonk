## Fog County UI tokens. Every value here comes straight from the canvas mockups.
## Use these instead of typing hex codes into scenes.
class_name FogPalette
extends RefCounted

# --- Base colours ----------------------------------------------------------
const NIGHT := Color("0E0F0E")        # panel backgrounds, outlines on pixel art
const NIGHT_PANEL := Color(0.055, 0.059, 0.055, 0.92)  # rgba(14,15,14,0.92) side panels
const NIGHT_TILE := Color(0.055, 0.059, 0.055, 0.85)   # slots, tiles, stat strips
const INK := Color("050505")          # hard text shadows (3px 3px 0)
const FOG := Color("8C978F")
const FOG_DARK := Color("1F2620")     # ground band in menu backgrounds
const ASH := Color("B9BAB1")          # default menu text, body copy
const ASH_DIM := Color("8D9188")      # small-caps labels
const ASH_FAINT := Color("6E726A")    # key hints, disabled
const BONE := Color("E8E2D0")         # main text
const BONE_BRIGHT := Color("F4EFE2")  # selected text, big numbers
const MEMO := Color("D3CBB2")         # paper memo cards
const MEMO_INK := Color("1C1A15")     # text on memo paper
const MEMO_INK_SOFT := Color("4A453A")
const RUST := Color("7E1820")         # selected menu row, HP fill, accent rules
const RUST_BRIGHT := Color("B3363F")  # selected borders, low-HP fill
const RUST_TEXT := Color("E07B83")    # warnings, "need more gold"
const RUST_DEEP := Color("2A1416")    # HP bar track
const BORDER := Color("3A3D38")       # default 1px panel border
const BORDER_LIGHT := Color("5A5D56")
const DIVIDER := Color("2E302C")

const GOLD := Color("F2C14E")
const GOLD_PALE := Color("FFF1C2")
const XP := Color("5C9FD6")
const XP_GLOW := Color("7FC4FF")

# --- Rarity ------------------------------------------------------------------
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
const RARITY := {
	Rarity.COMMON:    {"name": "Common",    "color": Color("8F876F"), "on": Color("F4EFE2"), "bg": Color("1A1C19"), "weight": 0.50},
	Rarity.UNCOMMON:  {"name": "Uncommon",  "color": Color("33772F"), "on": Color("F1F7EE"), "bg": Color("18201A"), "weight": 0.28},
	Rarity.RARE:      {"name": "Rare",      "color": Color("2B6CB5"), "on": Color("F2F6FB"), "bg": Color("141E29"), "weight": 0.15},
	Rarity.EPIC:      {"name": "Epic",      "color": Color("7B3FB3"), "on": Color("F7F1FC"), "bg": Color("1E1528"), "weight": 0.05},
	Rarity.LEGENDARY: {"name": "Legendary", "color": Color("C9861A"), "on": Color("1C1A15"), "bg": Color("2A2010"), "weight": 0.02},
}

# --- Elements (socket gems) -------------------------------------------------
const ELEMENT := {
	"corrosive":   Color("79B35F"),
	"ice":         Color("7FB8CF"),
	"fire":        Color("D9763E"),
	"electricity": Color("A487DA"),
}

# --- Type scale (px at 1920x1080) -------------------------------------------
# Serif = IM Fell English (titles, menus, names)   Sans = Overpass (labels, numbers)
# Memo  = Special Elite (paper cards only)
const SIZE_TITLE_XL := 104   # "Paused", "Megaclonk" is 150 (IM Fell English SC)
const SIZE_TITLE := 72       # screen titles
const SIZE_MENU_SELECTED := 46
const SIZE_MENU := 34
const SIZE_HUD_TIMER := 68
const SIZE_HUD_NUMBER := 34
const SIZE_LABEL := 13       # small caps labels, letter spacing ~0.28em
const SIZE_BODY := 17
