## Builds the shared Fog County Theme in code so every screen starts from the same look.
## Usage:  get_tree().root.theme = FogTheme.build()   (or assign to a top-level Control)
## Fonts are optional at build time: drop the .ttf/.woff2 files into res://ui/fonts/.
class_name FogTheme
extends RefCounted

const FONT_DIR := "res://ui/fonts/"
const SERIF_FILES := ["IMFellEnglish-Regular.ttf", "IMFellEnglish-Regular.woff2"]
const SERIF_SC_FILES := ["IMFellEnglishSC-Regular.ttf", "IMFellEnglishSC-Regular.woff2"]
const SANS_FILES := ["Overpass-VariableFont_wght.ttf", "Overpass[wght].ttf", "Overpass-ExtraBold.ttf", "Overpass-ExtraBold.woff2"]
const MEMO_FILES := ["SpecialElite-Regular.ttf", "SpecialElite-Regular.woff2"]

static func _load_font(names: Array) -> Font:
	for n in names:
		var p: String = FONT_DIR + n
		if ResourceLoader.exists(p):
			return load(p)
	return null

static func serif() -> Font: return _load_font(SERIF_FILES)
static func serif_sc() -> Font: return _load_font(SERIF_SC_FILES)
static func memo() -> Font: return _load_font(MEMO_FILES)

## Overpass at a given weight (400 / 600 / 800). Works with the variable font.
static func sans(weight: int = 800) -> Font:
	var base: Font = _load_font(SANS_FILES)
	if base == null:
		return null
	var v := FontVariation.new()
	v.base_font = base
	v.variation_opentype = {"wght": weight}
	return v

static func flat(bg: Color, border: Color = Color(0, 0, 0, 0), width: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(0)          # Fog County has no rounded corners
	s.anti_aliasing = false
	return s

static func build() -> Theme:
	var t := Theme.new()
	var f_serif := serif()
	var f_sans := sans(600)
	if f_sans:
		t.default_font = f_sans
	t.default_font_size = FogPalette.SIZE_BODY

	# Labels: bone text, hard ink shadow like the mockups' text-shadow: 3px 3px 0 #050505
	t.set_color("font_color", "Label", FogPalette.BONE)
	t.set_color("font_shadow_color", "Label", FogPalette.INK)
	t.set_constant("shadow_offset_x", "Label", 2)
	t.set_constant("shadow_offset_y", "Label", 2)

	# Panels and slots
	t.set_stylebox("panel", "Panel", flat(FogPalette.NIGHT_PANEL, FogPalette.BORDER, 1))
	t.set_stylebox("panel", "PanelContainer", flat(FogPalette.NIGHT_PANEL, FogPalette.BORDER, 1))

	# Menu buttons: transparent ash text, selected/hover = rust fill. Indent comes from content margin.
	var normal := flat(Color(0, 0, 0, 0))
	normal.content_margin_left = 56
	normal.content_margin_right = 24
	var hover := flat(FogPalette.RUST)
	hover.content_margin_left = 24
	hover.content_margin_right = 24
	var pressed := flat(FogPalette.BONE)          # one-frame invert flash
	pressed.content_margin_left = 24
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("focus", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", normal)
	t.set_color("font_color", "Button", FogPalette.ASH)
	t.set_color("font_hover_color", "Button", FogPalette.BONE_BRIGHT)
	t.set_color("font_focus_color", "Button", FogPalette.BONE_BRIGHT)
	t.set_color("font_pressed_color", "Button", FogPalette.RUST)
	t.set_color("font_disabled_color", "Button", FogPalette.ASH_FAINT)
	if f_serif:
		t.set_font("font", "Button", f_serif)
	t.set_font_size("font_size", "Button", FogPalette.SIZE_MENU)

	# Bars: HP is rust on a deep-rust track with a 2px ink border; XP is a separate variation.
	t.set_stylebox("background", "ProgressBar", flat(FogPalette.RUST_DEEP, FogPalette.INK, 2))
	t.set_stylebox("fill", "ProgressBar", flat(FogPalette.RUST))
	t.set_color("font_color", "ProgressBar", FogPalette.BONE_BRIGHT)

	t.add_type("XPBar")
	t.set_type_variation("XPBar", "ProgressBar")
	t.set_stylebox("background", "XPBar", flat(FogPalette.NIGHT_TILE, FogPalette.INK, 1))
	t.set_stylebox("fill", "XPBar", flat(FogPalette.XP))

	# Small-caps label variation ("WEAPONS · 1/4", "GOLD", ...)
	t.add_type("CapsLabel")
	t.set_type_variation("CapsLabel", "Label")
	t.set_color("font_color", "CapsLabel", FogPalette.ASH_DIM)
	t.set_font_size("font_size", "CapsLabel", FogPalette.SIZE_LABEL)
	var caps := sans(800)
	if caps:
		var spaced := FontVariation.new()
		spaced.base_font = caps
		spaced.spacing_glyph = 3            # ~0.28em at 13px
		t.set_font("font", "CapsLabel", spaced)

	# Big HUD numbers
	t.add_type("HudNumber")
	t.set_type_variation("HudNumber", "Label")
	t.set_color("font_color", "HudNumber", FogPalette.BONE_BRIGHT)
	t.set_font_size("font_size", "HudNumber", FogPalette.SIZE_HUD_NUMBER)
	t.set_constant("shadow_offset_x", "HudNumber", 3)
	t.set_constant("shadow_offset_y", "HudNumber", 3)
	var big := sans(800)
	if big:
		t.set_font("font", "HudNumber", big)

	# Serif titles
	t.add_type("TitleLabel")
	t.set_type_variation("TitleLabel", "Label")
	t.set_font_size("font_size", "TitleLabel", FogPalette.SIZE_TITLE)
	t.set_constant("shadow_offset_x", "TitleLabel", 3)
	t.set_constant("shadow_offset_y", "TitleLabel", 3)
	if f_serif:
		t.set_font("font", "TitleLabel", f_serif)

	# Memo text (paper cards)
	t.add_type("MemoLabel")
	t.set_type_variation("MemoLabel", "Label")
	t.set_color("font_color", "MemoLabel", FogPalette.MEMO_INK)
	t.set_color("font_shadow_color", "MemoLabel", Color(0, 0, 0, 0))
	var f_memo := memo()
	if f_memo:
		t.set_font("font", "MemoLabel", f_memo)
	return t

## Paper memo card background: memo paper, hard offset shadow (5px 7px 0 rgba(0,0,0,0.5)).
static func memo_style() -> StyleBoxFlat:
	var s := flat(FogPalette.MEMO)
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 1
	s.shadow_offset = Vector2(5, 7)
	s.set_content_margin_all(32)
	return s

## Slot / tile border in a rarity colour (items, chest reel, shop rows).
static func rarity_slot(r: int, selected: bool = false) -> StyleBoxFlat:
	var c: Color = FogPalette.RARITY[r]["color"]
	var s := flat(FogPalette.NIGHT, FogPalette.RUST_BRIGHT if selected else c, 2)
	s.border_width_bottom = 4
	return s
