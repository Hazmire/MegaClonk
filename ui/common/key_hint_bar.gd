class_name KeyHintBar
extends HBoxContainer
# Bottom key-hint row shared by menus and in-run screens. Entries are [keyboard key, action(, pad button)]; on a
# controller the key word is swapped for the button name. The device is tracked in one place (MenuScreen.pad_active).
const PAD_WORDS={"ENTER":"A","ESC":"B","Q / E":"LB / RB","TAB":"Y","↑↓":"D-PAD","↑ ↓":"D-PAD"}
var entries: Array=[]
func _init() -> void:
 name="KeyHints";add_theme_constant_override("separation",32);mouse_filter=Control.MOUSE_FILTER_IGNORE
func set_entries(value: Array) -> void:entries=value;refresh()
func refresh() -> void:
 for c in get_children():remove_child(c);c.queue_free()
 for e in entries:
  var pair=HBoxContainer.new();pair.add_theme_constant_override("separation",10);pair.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var key=String(e[0])
  if MenuScreen.pad_active():key=String(e[2]) if e.size()>2 else PAD_WORDS.get(key,key)
  MenuStyle.label(key,MenuStyle.sans(800,0.18,15),15,FogPalette.BONE,0,pair);MenuStyle.label(String(e[1]).to_upper(),MenuStyle.sans(600,0.18,15),15,FogPalette.ASH_DIM,0,pair)
  add_child(pair)
