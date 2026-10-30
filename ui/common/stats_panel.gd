class_name StatsPanel
extends PanelContainer
# Shared Stats panel (RunStats, 420x870 at 1920x1080). Rows come from RunData.stat_sections(), i.e. from the real
# game.stats. Neutral values are dim, changed values bold. preview(stat, from, to) fills a row rust and shows
# "old → new" (used on hover/focus by Level up, Shop and Shrine); clear_preview() restores it.
const SIZE_PX=Vector2(420,870)
var game: Node
var rows: Dictionary={} # stat key -> {bg, label, value, base_text, changed}
var previewing=""
var column: VBoxContainer
func setup(game_node: Node) -> StatsPanel:
 game=game_node;custom_minimum_size=SIZE_PX;size=SIZE_PX;mouse_filter=Control.MOUSE_FILTER_STOP
 var box=FogTheme.flat(FogPalette.NIGHT_PANEL,FogPalette.BORDER,1);box.content_margin_left=30;box.content_margin_right=30;box.content_margin_top=28;box.content_margin_bottom=28
 add_theme_stylebox_override("panel",box)
 refresh();return self
func refresh() -> void:
 previewing=""
 for c in get_children():remove_child(c);c.queue_free()
 rows.clear()
 column=VBoxContainer.new();column.add_theme_constant_override("separation",18);column.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(column)
 column.add_child(_heading("Stats"))
 var sections=VBoxContainer.new();sections.add_theme_constant_override("separation",8);sections.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(sections)
 for section in RunData.stat_sections(game):
  if section.rows.is_empty():continue
  var block=VBoxContainer.new();block.add_theme_constant_override("separation",3);block.mouse_filter=Control.MOUSE_FILTER_IGNORE;sections.add_child(block)
  var caption=MenuStyle.label(str(section.title).to_upper(),MenuStyle.sans(800,0.28,12),12,FogPalette.ASH_DIM,0,block)
  var rule=ColorRect.new();rule.color=FogPalette.DIVIDER;rule.custom_minimum_size=Vector2(0,1);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;block.add_child(rule)
  for r in section.rows:block.add_child(_row(r))
static func _heading(text: String) -> Control:
 var wrap=VBoxContainer.new();wrap.add_theme_constant_override("separation",10);wrap.mouse_filter=Control.MOUSE_FILTER_IGNORE
 MenuStyle.label(text,MenuStyle.serif(),38,FogPalette.BONE,0,wrap)
 var bar=ColorRect.new();bar.color=FogPalette.RUST;bar.custom_minimum_size=Vector2(40,4);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;wrap.add_child(bar)
 return wrap
func _row(r: Dictionary) -> Control:
 var bg=ColorRect.new();bg.custom_minimum_size=Vector2(0,20);bg.color=Color(0,0,0,0);bg.mouse_filter=Control.MOUSE_FILTER_STOP;bg.tooltip_text=BuildStats.help(str(r.key))
 var h=HBoxContainer.new();h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);h.offset_left=6;h.offset_right=-6;h.mouse_filter=Control.MOUSE_FILTER_IGNORE;bg.add_child(h)
 var label=MenuStyle.label(str(r.label),MenuStyle.sans(400,0,15),15,FogPalette.ASH if r.changed else FogPalette.ASH_DIM,0,h);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var value=MenuStyle.label(str(r.text),_number_font(r.changed),15,FogPalette.BONE_BRIGHT if r.changed else FogPalette.ASH_DIM,0,h);value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 rows[str(r.key)]={"bg":bg,"label":label,"value":value,"text":str(r.text),"changed":bool(r.changed)}
 return bg
static func _number_font(is_changed: bool) -> Font:
 var base=FogTheme.sans(800 if is_changed else 400)
 if base==null:return null
 var f=FontVariation.new();f.base_font=base;f.opentype_features={"tnum":1};return f
# Shows what a choice would do: the row goes rust and reads "old → new". `from`/`to` are raw stat values.
func preview(stat: String,from: float,to: float) -> void:
 clear_preview()
 if not rows.has(stat):return
 var row: Dictionary=rows[stat];previewing=stat
 row.bg.color=FogPalette.RUST
 row.label.add_theme_color_override("font_color",FogPalette.BONE_BRIGHT)
 row.value.text="%s → %s"%[RunData.stat_text(stat,from),RunData.stat_text(stat,to)]
 row.value.add_theme_color_override("font_color",FogPalette.BONE_BRIGHT)
 row.value.add_theme_font_override("font",_number_font(true))
func clear_preview() -> void:
 if previewing=="" or not rows.has(previewing):previewing="";return
 var row: Dictionary=rows[previewing];previewing=""
 row.bg.color=Color(0,0,0,0)
 row.value.text=str(row.text)
 row.label.add_theme_color_override("font_color",FogPalette.ASH if row.changed else FogPalette.ASH_DIM)
 row.value.add_theme_color_override("font_color",FogPalette.BONE_BRIGHT if row.changed else FogPalette.ASH_DIM)
 row.value.add_theme_font_override("font",_number_font(row.changed))
# Text currently shown for a stat (tests compare this to the real change).
func shown_text(stat: String) -> String:return str(rows[stat].value.text) if rows.has(stat) else ""
