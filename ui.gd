class_name GameUI
extends CanvasLayer
## HUD, main menu and every management screen. Industrial palette, one theme, no default buttons.

const C_PANEL := Color(0.105, 0.112, 0.125, 0.97)
const C_LINE := Color(0.3, 0.32, 0.35)
const C_WARM := Color(0.93, 0.9, 0.84)
const C_AMBER := Color(0.86, 0.65, 0.26)
const C_RED := Color(0.78, 0.33, 0.26)
const C_DIM := Color(0.62, 0.62, 0.6)
const C_GOOD := Color(0.6, 0.78, 0.6)
const MANAGE_TABS := ["Overview", "Passengers", "Resources", "Electricity", "Carriages & Repairs", "Crafting", "Assignments"]
const TRADES := [
	{"give": {"scrap": 4}, "get": {"food": 5}},
	{"give": {"scrap": 3}, "get": {"water": 6}},
	{"give": {"electronics": 2}, "get": {"medicine": 2}},
	{"give": {"batteries": 1}, "get": {"diesel": 3}},
	{"give": {"ammo": 8}, "get": {"parts": 2}},
	{"give": {"food": 4}, "get": {"ammo": 10}},
	{"give": {"medicine": 1}, "get": {"scrap": 5}},
	{"give": {"parts": 2}, "get": {"tools": 1}},
]
const OBJECTIVES := [
	["Take command", "Walk forward through the train to the driver's cab at the front of the locomotive."],
	["Wake the engine", "Press the ENG switch on the driver's desk (look at it and press E) to start the diesel engine."],
	["Scavenge Nordhaven", "Open the carriage doors (E at a door) and search the station. Glowing amber tags mark unsearched containers. Search 3."],
	["Stock the train", "Board the train, open the Inventory (Tab) and store what you carried in the train stores."],
	["Depart", "Close the doors, sit in the driver's seat and release the brake with W - or press P for autopilot."],
	["Reach Karsk Maintenance Depot", "Follow the Northern Line. Autopilot will brake for the next stop; you may walk the train while it drives."],
	["Expand the train", "Find the abandoned carriage standing behind your train and couple it (needs a Tool Kit and 2 Repair Materials)."],
	["Find another survivor", "Search the stops along the line. Speak to survivors to offer them a place aboard."],
	["Reach Haven Junction", "A survivor settlement lies five stops down the line. They trade."],
	["Reach the Port of Kaldwick", "They say ships still leave from the Port. Get your people there."],
	["Keep the Last Train alive", "The line loops back north. Every lap is harder. Keep them warm, fed and moving."],
]

var main
var font: Font
var th: Theme
var hud: Control
var menu: Control
var win: Control
var win_title: Label
var win_tabs: HBoxContainer
var win_body: VBoxContainer
var screen := ""
var prev := ""
var tab := 0
var rebinding := ""
var notice := ""
var btn_continue: Button
var manual: ManualView = null
var talk_agent: CrewAgent = null
var talk_reply := ""
var hd: HudDraw
var font_wide: FontVariation
var win_panel: PanelContainer
var win_sub: Label
var win_foot: Label
var menu_rule: ColorRect
var menu_info: Label
var l_continue: Label
# hud refs
var l_loc: Label
var l_env: Label
var l_train: Label
var l_obj_t: Label
var l_obj: Label
var warn_box: VBoxContainer
var bars: Dictionary = {}
var l_ammo: Label
var prompt: Label
var toasts: VBoxContainer
var drive: PanelContainer
var l_drive: Label
var b_thr: ProgressBar
var b_brk: ProgressBar
var radio_p: PanelContainer
var l_radio: Label
var radio_t := 0.0
var vignette: ColorRect
var fade: ColorRect
var l_fade: Label
var cross: ColorRect
var hud_t := 0.0

func _sb(bg: Color, border: Color, bw: int = 1, mh: float = 14.0, mv: float = 7.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(2)
	s.content_margin_left = mh
	s.content_margin_right = mh
	s.content_margin_top = mv
	s.content_margin_bottom = mv
	return s

func build() -> void:
	layer = 10
	font = Kit.get_font()
	font_wide = FontVariation.new()
	font_wide.base_font = font
	font_wide.spacing_glyph = 5
	th = Theme.new()
	th.default_font = font
	th.default_font_size = 15
	th.set_stylebox("normal", "Button", _sb(Color(0.16, 0.17, 0.185), C_LINE))
	th.set_stylebox("hover", "Button", _sb(Color(0.23, 0.24, 0.26), C_AMBER))
	th.set_stylebox("pressed", "Button", _sb(Color(0.62, 0.46, 0.17), C_AMBER))
	th.set_stylebox("disabled", "Button", _sb(Color(0.11, 0.115, 0.125), Color(0.2, 0.2, 0.22)))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", C_WARM)
	th.set_color("font_hover_color", "Button", Color(1, 1, 1))
	th.set_color("font_pressed_color", "Button", Color(0.06, 0.06, 0.06))
	th.set_color("font_disabled_color", "Button", Color(0.42, 0.42, 0.42))
	th.set_color("font_color", "Label", C_WARM)
	th.set_stylebox("panel", "PanelContainer", _sb(C_PANEL, C_LINE, 1, 16, 12))
	th.set_stylebox("background", "ProgressBar", _sb(Color(0.04, 0.04, 0.05, 0.85), C_LINE, 1, 0, 0))
	th.set_stylebox("fill", "ProgressBar", _sb(C_AMBER, C_AMBER, 0, 0, 0))
	th.set_stylebox("slider", "HSlider", _sb(Color(0.04, 0.04, 0.05), C_LINE, 1, 0, 3))
	th.set_stylebox("grabber_area", "HSlider", _sb(Color(0.62, 0.46, 0.17), C_AMBER, 0, 0, 3))
	th.set_stylebox("grabber_area_highlight", "HSlider", _sb(C_AMBER, C_AMBER, 0, 0, 3))
	_build_hud()
	_build_menu()
	_build_win()

# ---------- widgets ----------
func _lbl(text: String, size: int = 15, col: Color = C_WARM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _wrap(text: String, size: int, col: Color, width: float) -> Label:
	var l: Label = _lbl(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = width
	return l

func _btn(text: String, cb: Callable, minw: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(minw, 34)
	b.pressed.connect(cb)
	b.pressed.connect(_click)
	return b

func _click() -> void:
	main.sfx.play("ui_click", -10.0)

func _bar(w: float, h: float, col: Color) -> ProgressBar:
	var p := ProgressBar.new()
	p.show_percentage = false
	p.max_value = 100.0
	p.custom_minimum_size = Vector2(w, h)
	p.add_theme_stylebox_override("fill", _sb(col, col, 0, 0, 0))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

func _rule(col: Color = C_AMBER) -> ColorRect:
	var r := ColorRect.new()
	r.color = col
	r.custom_minimum_size = Vector2(0, 2)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _row(items: Array, sep: int = 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	for i: Variant in items:
		var c: Control = i
		h.add_child(c)
	return h

func _spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _card(children: Array) -> PanelContainer:
	var p := PanelContainer.new()
	var cs: StyleBoxFlat = _sb(Color(0.135, 0.145, 0.16), Color(0.25, 0.26, 0.29), 1, 14, 9)
	cs.border_width_left = 3
	p.add_theme_stylebox_override("panel", cs)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	for i: Variant in children:
		var c: Control = i
		v.add_child(c)
	return p

func _corner(preset: int, gh: int, gv: int) -> VBoxContainer:
	var v := VBoxContainer.new()
	hud.add_child(v)
	v.set_anchors_and_offsets_preset(preset as Control.LayoutPreset, Control.PRESET_MODE_MINSIZE, 20)
	v.grow_horizontal = gh as Control.GrowDirection
	v.grow_vertical = gv as Control.GrowDirection
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 4)
	return v

# ---------- HUD ----------
func _radial(inner: Color, outer: Color, start: float) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, start, 1.0])
	g.colors = PackedColorArray([inner, inner, outer])
	var tx := GradientTexture2D.new()
	tx.gradient = g
	tx.fill = GradientTexture2D.FILL_RADIAL
	tx.fill_from = Vector2(0.5, 0.5)
	tx.fill_to = Vector2(0.5, -0.22)
	tx.width = 256
	tx.height = 144
	return tx

func _overlay(parent: Control, tx: Texture2D) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tx
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.visible = false
	add_child(hud)
	hd = HudDraw.new()
	hd.main = main
	hd.font = font
	hd.font_wide = font_wide
	hd.vignette = _overlay(hud, _radial(Color(0, 0, 0, 0), Color(0, 0, 0, 0.6), 0.5))
	hd.frost = _overlay(hud, _radial(Color(0.78, 0.9, 1.0, 0), Color(0.82, 0.93, 1.0, 0.8), 0.4))
	hd.blood = _overlay(hud, _radial(Color(0.5, 0.02, 0.02, 0), Color(0.55, 0.03, 0.02, 0.9), 0.32))
	hd.frost.modulate.a = 0.0
	hd.blood.modulate.a = 0.0
	hd.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hd)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	l_fade = _lbl("", 22, C_WARM)
	l_fade.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_fade.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l_fade.add_theme_font_override("font", font_wide)
	fade.add_child(l_fade)

func fade_pulse(text: String) -> void:
	l_fade.text = text
	fade.color = Color(0, 0, 0, 1)
	l_fade.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(fade, "color", Color(0, 0, 0, 0), 1.2)
	tw.parallel().tween_property(l_fade, "modulate:a", 0.0, 0.8)

func toast(text: String, kind: String) -> void:
	hd.add_toast(text, kind)

func show_radio(text: String) -> void:
	hd.set_radio(text)

func hurt() -> void:
	hd.hurt_a = 1.0

func hit_marker() -> void:
	hd.hit_a = 1.0

func title_card(title: String, sub: String) -> void:
	hd.show_card(title.to_upper(), sub.to_upper())

func update_hud(dt: float, prompt_text: String) -> void:
	for m: Array in GS.msgs:
		if m[1] == "radio":
			show_radio(m[0])
			main.sfx.play("radio", -8.0)
		else:
			toast(m[0], m[1])
			if m[1] == "bad":
				main.sfx.play("alarm", -12.0)
	GS.msgs.clear()
	hd.tick(dt, prompt_text)

# ---------- main menu ----------
func _menu_btn(idx: int, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = "%02d     %s" % [idx, text]
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(360, 36)
	b.add_theme_font_size_override("font_size", 16)
	var cfg: Array = [["normal", Color(0, 0, 0, 0), Color(0.34, 0.36, 0.39), 2, 16.0], ["hover", Color(0.86, 0.65, 0.26, 0.14), C_AMBER, 4, 28.0], ["pressed", Color(0.86, 0.65, 0.26, 0.9), C_AMBER, 4, 28.0], ["disabled", Color(0, 0, 0, 0), Color(0.2, 0.21, 0.23), 2, 16.0]]
	for c: Array in cfg:
		var s := StyleBoxFlat.new()
		s.bg_color = c[1]
		s.border_color = c[2]
		s.border_width_left = int(c[3])
		s.content_margin_left = float(c[4])
		s.content_margin_top = 2.0
		s.content_margin_bottom = 2.0
		b.add_theme_stylebox_override(str(c[0]), s)
	b.pressed.connect(cb)
	b.pressed.connect(_click)
	b.mouse_entered.connect(_hover)
	return b

func _hover() -> void:
	main.sfx.play("ui_switch", -24.0, 1.5)

func _build_menu() -> void:
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.theme = th
	menu.visible = false
	add_child(menu)
	_overlay(menu, _radial(Color(0, 0, 0, 0), Color(0, 0, 0, 0.7), 0.45))
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.32, 0.62])
	g.colors = PackedColorArray([Color(0.035, 0.04, 0.05, 0.96), Color(0.035, 0.04, 0.05, 0.82), Color(0.035, 0.04, 0.05, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 256
	gt.height = 4
	_overlay(menu, gt)
	var bg := Control.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(_menu_bg_input)
	menu.add_child(bg)
	for top: bool in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color(0.01, 0.012, 0.015)
		bar.custom_minimum_size.y = 44
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		menu.add_child(bar)
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE)
	var mc := MarginContainer.new()
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_theme_constant_override("margin_left", 72)
	mc.add_theme_constant_override("margin_top", 58)
	mc.add_theme_constant_override("margin_bottom", 50)
	menu.add_child(mc)
	mc.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE, Control.PRESET_MODE_MINSIZE)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 4)
	mc.add_child(v)
	var kick: Label = _lbl("NORTHERN LINE   /   FINAL SERVICE   /   4071", 12, C_AMBER)
	kick.add_theme_font_override("font", font_wide)
	v.add_child(kick)
	var title: Label = _lbl("LAST TRAIN", 68, C_WARM)
	title.add_theme_font_override("font", font_wide)
	v.add_child(title)
	menu_rule = ColorRect.new()
	menu_rule.color = C_AMBER
	menu_rule.custom_minimum_size = Vector2(0, 3)
	menu_rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	menu_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(menu_rule)
	v.add_child(_wrap("Keep the last working train, and the people aboard it, alive through a frozen country. Ten stops to the Port of Kaldwick.", 13, C_DIM, 470.0))
	var gap := Control.new()
	gap.custom_minimum_size.y = 6
	v.add_child(gap)
	btn_continue = _menu_btn(1, "CONTINUE", main.continue_game)
	v.add_child(btn_continue)
	l_continue = _lbl("", 11, C_DIM)
	var lm := MarginContainer.new()
	lm.add_theme_constant_override("margin_left", 62)
	lm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lm.add_child(l_continue)
	v.add_child(lm)
	v.add_child(_menu_btn(2, "NEW GAME", main.start_new))
	v.add_child(_menu_btn(3, "LOAD GAME", open.bind("load", 0)))
	v.add_child(_menu_btn(4, "SETTINGS", open.bind("settings", 0)))
	v.add_child(_menu_btn(5, "STATISTICS", open.bind("stats", 0)))
	v.add_child(_menu_btn(6, "CREDITS", open.bind("credits", 0)))
	v.add_child(_menu_btn(7, "FIELD MANUAL", open.bind("manual", 0)))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sp)
	v.add_child(_lbl("ENTER  /  SPACE  /  CLICK THE SCENE   -   BOARD THE TRAIN", 11, C_AMBER))
	v.add_child(_lbl("Desktop browser.  Mouse and keyboard.", 11, C_DIM))
	var slate := VBoxContainer.new()
	slate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(slate)
	menu_info = _lbl("", 12, C_WARM)
	menu_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	menu_info.add_theme_font_override("font", font_wide)
	slate.add_child(menu_info)
	var s2: Label = _lbl("LOCOMOTIVE 4071  -  PLATFORM 1", 10, C_DIM)
	s2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slate.add_child(s2)
	slate.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 64)
	slate.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	slate.grow_vertical = Control.GROW_DIRECTION_BEGIN

func _menu_bg_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and screen == "":
		main.menu_default()
	elif ev is InputEventScreenTouch and ev.pressed and screen == "":
		main.menu_default()

func show_menu() -> void:
	menu.visible = true
	hud.visible = false
	var ls: int = GS.latest_slot()
	btn_continue.disabled = ls < 0
	l_continue.text = str(GS.slot_info(ls)["label"]) if ls >= 0 else "No saved journey yet"
	menu_info.text = "NORDHAVEN STATION    %s    %d C    SNOWFALL" % [GS.clock(), int(round(GS.t_out))]
	menu.modulate.a = 0.0
	menu_rule.custom_minimum_size.x = 0.0
	var tw := create_tween()
	tw.tween_property(menu, "modulate:a", 1.0, 1.1)
	tw.parallel().tween_property(menu_rule, "custom_minimum_size:x", 400.0, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func show_hud() -> void:
	menu.visible = false
	hud.visible = true

# ---------- modal window ----------
func _build_win() -> void:
	win = Control.new()
	win.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	win.theme = th
	win.visible = false
	add_child(win)
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.02, 0.025, 0.74)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	win.add_child(dim)
	_overlay(win, _radial(Color(0, 0, 0, 0), Color(0, 0, 0, 0.6), 0.5))
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	win.add_child(cc)
	win_panel = PanelContainer.new()
	win_panel.custom_minimum_size = Vector2(1040, 616)
	win_panel.add_theme_stylebox_override("panel", _sb(C_PANEL, C_LINE, 1, 0, 0))
	cc.add_child(win_panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	win_panel.add_child(outer)
	var top := ColorRect.new()
	top.color = C_AMBER
	top.custom_minimum_size.y = 3
	outer.add_child(top)
	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", _sb(Color(0.075, 0.08, 0.09), Color(0, 0, 0, 0), 0, 24, 12))
	outer.add_child(head)
	win_title = _lbl("", 24, C_WARM)
	win_title.add_theme_font_override("font", font_wide)
	win_sub = _lbl("", 11, C_AMBER)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	tv.add_child(win_title)
	tv.add_child(win_sub)
	var cb: Button = _btn("CLOSE   ESC", close)
	cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_row([tv, _spacer(), cb], 12))
	var mc := MarginContainer.new()
	mc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mc.add_theme_constant_override("margin_left", 24)
	mc.add_theme_constant_override("margin_right", 24)
	mc.add_theme_constant_override("margin_top", 12)
	mc.add_theme_constant_override("margin_bottom", 8)
	outer.add_child(mc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	mc.add_child(v)
	win_tabs = HBoxContainer.new()
	win_tabs.add_theme_constant_override("separation", 4)
	v.add_child(win_tabs)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	win_body = VBoxContainer.new()
	win_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	win_body.add_theme_constant_override("separation", 8)
	sc.add_child(win_body)
	var foot := PanelContainer.new()
	foot.add_theme_stylebox_override("panel", _sb(Color(0.075, 0.08, 0.09), Color(0, 0, 0, 0), 0, 24, 7))
	outer.add_child(foot)
	win_foot = _lbl("", 10, C_DIM)
	foot.add_child(win_foot)

func _icon(kind: String, col: Color = C_AMBER) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(28, 28)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(_draw_icon.bind(c, kind, col))
	return c

func _draw_icon(c: Control, kind: String, col: Color) -> void:
	c.draw_rect(Rect2(0, 0, 28, 28), Color(0.07, 0.075, 0.085))
	c.draw_rect(Rect2(0, 0, 28, 28), Color(0.26, 0.27, 0.3), false, 1.0)
	HudDraw.icon(c, kind, Vector2(14, 14), 17.0, col)

func is_open() -> bool:
	return screen != ""

func open(name: String, t: int = 0) -> void:
	if screen != "" and name in ["settings", "load", "save", "manual"]:
		prev = screen
	else:
		prev = ""
	screen = name
	tab = t
	notice = ""
	rebinding = ""
	var was: bool = win.visible
	win.visible = true
	var k: int = int(round(float(GS.train["s"]) / GS.SP))
	var loc: Dictionary = GS.loc_at(k)
	win_sub.text = "DAY %d    %s    %s" % [GS.day(), GS.clock(), str(loc["name"]).to_upper()] if main.state != 0 else "NORTHERN LINE"
	win_foot.text = "TAB  inventory      M  railway map      J  objectives      T  train management      N  field manual      ESC  close" if main.state != 0 else "ESC  close"
	if not was:
		win_panel.pivot_offset = win_panel.size * 0.5
		win_panel.modulate.a = 0.0
		win_panel.scale = Vector2(0.97, 0.97)
		var tw := create_tween()
		tw.tween_property(win_panel, "modulate:a", 1.0, 0.16)
		tw.parallel().tween_property(win_panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_rebuild()
	main.on_ui_open()

func close() -> void:
	if screen == "dead":
		return
	if screen == "story":
		var so: Array = Story.cur.get("options", [])
		if so.is_empty():
			Story.choose(main, -1)
		return
	if screen == "settings":
		GS.save_settings()
	if prev != "" and prev != screen:
		var p := prev
		prev = ""
		screen = p
		tab = 0
		_rebuild()
		return
	screen = ""
	win.visible = false
	main.on_ui_close()

func open_story() -> void:
	open("story", 0)

func close_story() -> void:
	screen = ""
	prev = ""
	win.visible = false
	main.on_ui_close()
	Story.closed(main)

func _story_pick(i: int) -> void:
	Story.choose(main, i)

func _scr_story() -> void:
	var d: Dictionary = Story.cur
	win_title.text = str(d.get("title", ""))
	win_sub.text = str(d.get("kicker", ""))
	win_foot.text = "THE NORTHLINE"
	if str(d.get("speaker", "")) != "":
		win_body.add_child(_lbl(str(d["speaker"]).to_upper(), 12, C_AMBER))
	var body: Array = d.get("body", [])
	for p: Variant in body:
		win_body.add_child(_wrap(str(p), 16, C_WARM, 960.0))
	var gap := Control.new()
	gap.custom_minimum_size.y = 6
	win_body.add_child(gap)
	var opts: Array = d.get("options", [])
	if opts.is_empty():
		win_body.add_child(_row([_spacer(), _btn("CONTINUE", _story_pick.bind(-1), 220)]))
		return
	win_body.add_child(_lbl("YOUR DECISION", 11, C_AMBER))
	for i in opts.size():
		var o: Array = opts[i]
		var b: Button = _btn(str(o[0]), _story_pick.bind(i), 960)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 40
		b.disabled = not bool(o[2])
		win_body.add_child(b)
		var hl := MarginContainer.new()
		hl.add_theme_constant_override("margin_left", 16)
		hl.add_child(_wrap(str(o[1]), 12, C_DIM if bool(o[2]) else C_RED, 930.0))
		win_body.add_child(hl)

func _scr_ending() -> void:
	win_title.text = "THE NORTHLINE"
	win_sub.text = "EPILOGUE   -   WHAT YOU REBUILT"
	win_foot.text = "The survival sandbox continues. Read this again from the Objectives screen."
	for e: Array in Story.epilogue():
		if str(e[0]) == "":
			win_body.add_child(_rule())
			win_body.add_child(_wrap(str(e[1]), 15, C_AMBER, 960.0))
		else:
			win_body.add_child(_card([_lbl(str(e[0]), 13, C_AMBER), _wrap(str(e[1]), 15, C_WARM, 930.0)]))
	win_body.add_child(_row([_spacer(), _btn("CONTINUE THE JOURNEY", close, 300)]))

func _scr_objectives() -> void:
	win_title.text = "JOURNAL"
	var chn: int = Story.ch()
	var ct: Array = Story.CHAPTERS[clampi(chn, 0, 6)]
	win_sub.text = "THE NORTHLINE   -   %s: %s" % [ct[0], str(ct[1]).to_upper()]
	# chapter track
	var track: HBoxContainer = _row([], 6)
	for i in range(1, 6):
		var c2: Array = Story.CHAPTERS[i]
		var done: bool = chn > i
		var now: bool = chn == i
		var lb: Label = _lbl("%s  %s" % [str(c2[0]).replace("CHAPTER ", ""), str(c2[1]).to_upper()], 11, C_GOOD if done else (C_AMBER if now else C_DIM))
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", _sb(Color(0.62, 0.46, 0.17, 0.25) if now else Color(0.14, 0.15, 0.165), C_AMBER if now else Color(0.25, 0.26, 0.29), 1, 10, 6))
		pc.add_child(lb)
		track.add_child(pc)
	win_body.add_child(track)
	_head("Main objective")
	if GS.objective < 5:
		var oi: int = clampi(GS.objective, 0, OBJECTIVES.size() - 1)
		win_body.add_child(_card([_row([_lbl("PROLOGUE", 11, C_AMBER), _lbl(OBJECTIVES[oi][0], 16, C_WARM)]), _wrap(OBJECTIVES[oi][1], 13, C_DIM, 930.0)]))
	else:
		var o: Dictionary = Story.objective()
		var rows: Array = [_lbl(str(o["title"]).to_upper(), 17, C_AMBER), _wrap(str(o["what"]), 14, C_WARM, 930.0)]
		if str(o["why"]) != "":
			rows.append(_row([_wrap("WHY", 10, C_DIM, 70.0), _wrap(str(o["why"]), 13, C_DIM, 850.0)]))
		if str(o["where"]) != "":
			rows.append(_row([_wrap("WHERE", 10, C_DIM, 70.0), _wrap(str(o["where"]), 13, C_WARM, 850.0)]))
		if str(o["prog"]) != "":
			rows.append(_row([_wrap("PROGRESS", 10, C_DIM, 70.0), _wrap(str(o["prog"]), 13, C_GOOD, 850.0)]))
		win_body.add_child(_card(rows))
	if str(Story.fl("end", "")) != "":
		win_body.add_child(_row([_btn("READ THE EPILOGUE AGAIN", open.bind("ending", 0), 300)]))
	_head("Optional objectives and side missions")
	for op: Array in Story.optional():
		var od: bool = op[3]
		win_body.add_child(_card([_row([_lbl("DONE" if od else "OPEN", 10, C_GOOD if od else C_AMBER), _wrap(str(op[0]), 15, C_DIM if od else C_WARM, 260.0), _wrap(str(op[1]), 12, C_DIM, 480.0), _spacer(), _lbl(str(op[2]).to_upper(), 10, C_GOOD if od else C_DIM)])]))
	var ps: Array = Story.passengers()
	if not ps.is_empty():
		_head("Passenger stories")
		for pe: Array in ps:
			win_body.add_child(_card([_row([_icon("crew"), _wrap(str(pe[0]), 15, C_AMBER, 180.0), _wrap(str(pe[1]), 13, C_WARM, 520.0), _spacer(), _lbl(str(pe[2]).to_upper(), 10, C_DIM)])]))
	var fd: Array = GS.story["found"]
	_head("Discovered information  (%d)" % fd.size())
	if fd.is_empty():
		_note("Nothing yet. Records, logs and recordings you find are kept here.")
	for i in fd.size():
		var did: String = str(fd[fd.size() - 1 - i])
		if Story.DISC.has(did):
			var de: Array = Story.DISC[did]
			win_body.add_child(_card([_lbl(str(de[0]), 14, C_AMBER), _wrap(str(de[1]), 13, C_DIM, 930.0)]))
	var lg: Array = GS.story["log"]
	_head("Decisions  (%d)" % lg.size())
	if lg.is_empty():
		_note("You have not had to choose yet.")
	for le: Variant in lg:
		var ld: Dictionary = le
		win_body.add_child(_row([_wrap("DAY %d" % int(ld.get("d", 1)), 11, C_DIM, 70.0), _wrap(str(ld.get("t", "")), 13, C_WARM, 860.0)]))
	var dn: Array = GS.story["done"]
	if not dn.is_empty():
		_head("Completed")
		for dd: Variant in dn:
			win_body.add_child(_row([_lbl("DONE", 10, C_GOOD), _lbl(str(dd), 13, C_DIM)]))
	_head("Places reached")
	var names: Array = []
	for i in GS.NLOC:
		if GS.discovered.has(str(i)):
			names.append(str(GS.LOCS[i]["name"]))
	if Story.has("meridian"):
		names.append("Meridian Central")
	_note(",  ".join(names))
	var sg: Array = GS.story["sights"]
	_head("Sights along the line  (%d of %d)" % [sg.size(), Story.SIGHTS.size()])
	if sg.is_empty():
		_note("Nothing yet. Look out of the windows as you travel; take a window seat in the passenger carriage.")
	else:
		var sn: Array = []
		for sv: Variant in sg:
			if Story.SIGHTS.has(str(sv)):
				sn.append(str(Story.SIGHTS[str(sv)][0]))
		_note(",  ".join(sn), C_WARM)
	_head("Radio log")
	if GS.radio_log.is_empty():
		_note("No transmissions received.")
	for i in GS.radio_log.size():
		_note(str(GS.radio_log[GS.radio_log.size() - 1 - i]), C_WARM)

func refresh() -> void:
	call_deferred("_rebuild")

func _set_tab(i: int) -> void:
	tab = i
	refresh()

func _note(text: String, col: Color = C_DIM) -> void:
	win_body.add_child(_wrap(text, 13, col, 900.0))

func _head(text: String) -> void:
	win_body.add_child(_lbl(text, 17, C_AMBER))

func _rebuild() -> void:
	if screen == "":
		return
	win_panel.custom_minimum_size = Vector2(1040, 652) if screen == "manual" else Vector2(1040, 616)
	for c: Node in win_body.get_children():
		c.queue_free()
	for c: Node in win_tabs.get_children():
		c.queue_free()
	if notice != "":
		_note(notice, C_AMBER)
	match screen:
		"manual":
			win_title.text = "FIELD MANUAL"
			win_sub.text = "NORTHERN LINE OPERATING HANDBOOK   -   LOCOMOTIVE 4071"
			manual = ManualView.new()
			manual.main = main
			manual.font = font
			manual.wide = font_wide
			win_body.add_child(manual)
		"pause":
			win_title.text = "PAUSED"
			var v := VBoxContainer.new()
			v.add_theme_constant_override("separation", 8)
			v.add_child(_btn("RESUME", close, 360))
			v.add_child(_btn("SAVE GAME", open.bind("save", 0), 360))
			v.add_child(_btn("LOAD GAME", open.bind("load", 0), 360))
			v.add_child(_btn("SETTINGS", open.bind("settings", 0), 360))
			v.add_child(_btn("FIELD MANUAL", open.bind("manual", 0), 360))
			v.add_child(_btn("QUIT TO MAIN MENU", main.quit_to_menu, 360))
			var cc := CenterContainer.new()
			cc.add_child(v)
			win_body.add_child(cc)
			_note("WASD move   Mouse look   Shift sprint   Space jump   C crouch   E interact   F flashlight\nLeft click fire   Right click aim   R reload   V inspect weapon   Q / wheel / 1-0 switch weapon\nG carriage doors (any time the train is stopped)   Tab inventory   M map   J objectives   T train management   N field manual   Esc pause")
		"dead":
			win_title.text = "THE LINE GOES QUIET"
			_note("You did not survive. The train stands silent in the snow.\nDay %d. %d m travelled. %d stops reached." % [GS.day(), int(GS.stats["distance"]), int(GS.stats["stops"])], C_WARM)
			win_body.add_child(_btn("LOAD LAST SAVE", main.continue_game, 360))
			win_body.add_child(_btn("MAIN MENU", main.quit_to_menu, 360))
		"save":
			win_title.text = "SAVE GAME"
			for n in [1, 2, 3]:
				var info: Dictionary = GS.slot_info(n)
				win_body.add_child(_card([_row([_lbl("SLOT %d" % n, 16, C_AMBER), _lbl(str(info["label"]), 13, C_WARM if info["ok"] else C_DIM), _spacer(), _btn("SAVE HERE", _do_save.bind(n), 130)])]))
		"load":
			win_title.text = "LOAD GAME"
			for n in [0, 1, 2, 3]:
				var info: Dictionary = GS.slot_info(n)
				var lb: Button = _btn("LOAD", main.load_slot.bind(n), 110)
				lb.disabled = not info["ok"]
				var items: Array = [_lbl("AUTOSAVE" if n == 0 else "SLOT %d" % n, 16, C_AMBER), _lbl(str(info["label"]), 13, C_RED if (info["exists"] and not info["ok"]) else C_WARM), _spacer(), lb]
				if info["exists"]:
					items.append(_btn("DELETE", _del_slot.bind(n), 90))
				win_body.add_child(_card([_row(items)]))
		"settings":
			win_title.text = "SETTINGS"
			_scr_settings()
		"stats":
			win_title.text = "STATISTICS"
			var st: Dictionary = GS.stats
			var label := "Current journey"
			if main.state == 0:
				var ls: int = GS.latest_slot()
				if ls < 0:
					_note("No journey recorded yet. Start a new game.")
					return
				var d: Variant = GS.read_slot(ls)
				var dd: Dictionary = d
				st = dd.get("stats", {})
				label = "Most recent save"
			_head(label)
			var rows: Array = [["Time survived", "%d h %d min" % [int(float(st.get("minutes", 0.0))) / 60, int(float(st.get("minutes", 0.0))) % 60]], ["Distance travelled", "%.1f km" % (float(st.get("distance", 0.0)) / 1000.0)], ["Stops reached", str(int(st.get("stops", 0)))], ["Laps of the Northern Line", str(int(st.get("laps", 0)))], ["Survivors recruited", str(int(st.get("recruited", 0)))], ["Survivors lost", str(int(st.get("lost", 0)))], ["Threats neutralised", str(int(st.get("neutralised", 0)))], ["Containers searched", str(int(st.get("looted", 0)))], ["Carriages coupled", str(int(st.get("coupled", 0)))], ["Items crafted", str(int(st.get("crafted", 0)))], ["Repairs made", str(int(st.get("repairs", 0)))]]
			for r: Array in rows:
				win_body.add_child(_row([_wrap(r[0], 14, C_DIM, 280.0), _lbl(r[1], 15, C_WARM)]))
		"credits":
			win_title.text = "CREDITS"
			_note("LAST TRAIN - a first-person survival and train management game built in Godot 4 (GDScript, WebGL 2).", C_WARM)
			_note("Surface materials: scanned PBR sets (albedo, normal, roughness) from Poly Haven, CC0 - blue_metal_plate, concrete_pavement, concrete_wall_008, corrugated_iron, fabric_pattern_07, gravel_floor_02, red_brick_03, rubber_tiles, rusty_metal_02, snow_02, weathered_brown_planks.\nSupply crate and drum models: Poly Haven, CC0 (old_military_crate, Barrel_01).\nFort Varda soldier model and its idle, walk and run clips: Adobe Mixamo 'Vanguard' (Mixamo royalty-free licence), via the three.js examples.\nVehicle wrecks: Kenney Car Kit (CC0).  Footsteps and interface clicks: Kenney audio (CC0).")
			_note("Train, carriages, stations, weapons, first-person arms, survivors and infected: geometry built in code for this game.\nEngine, rails, wind, horn, brake, weapon and creature sounds: synthesised for this game.  Typeface: Russo One (SIL OFL).")
		"inventory":
			win_title.text = "INVENTORY"
			_scr_inventory()
		"map":
			win_title.text = "RAILWAY MAP  -  NORTHERN LINE"
			_scr_map()
		"objectives":
			_scr_objectives()
		"story":
			_scr_story()
		"ending":
			_scr_ending()
		"manage":
			win_title.text = "TRAIN MANAGEMENT"
			for i in MANAGE_TABS.size():
				var b: Button = _btn(MANAGE_TABS[i], _set_tab.bind(i))
				if i == tab:
					b.add_theme_stylebox_override("normal", _sb(Color(0.62, 0.46, 0.17), C_AMBER))
					b.add_theme_color_override("font_color", Color(0.06, 0.06, 0.06))
				win_tabs.add_child(b)
			_scr_manage()
		"talk":
			_scr_talk()
		"trade":
			win_title.text = "HAVEN JUNCTION  -  QUARTERMASTER"
			if str(Story.fl("haven", "")) == "refused":
				_note("Odile's stall is shuttered. \"The train comes first. You said so yourself.\" Haven Junction will not trade with you.", C_RED)
				return
			if Story.f("haven_ally"):
				_note("Odile: \"For this train, a little over the measure.\" Every trade gives one extra unit.", C_GOOD)
			_note("Odile: \"Fair trades only. Goods go straight to your train stores.\"", C_WARM)
			for tr: Dictionary in TRADES:
				var give: Dictionary = tr["give"]
				var gt: Dictionary = tr["get"]
				var b: Button = _btn("TRADE", _do_trade.bind(give, gt), 110)
				b.disabled = not GS.can_afford(give)
				win_body.add_child(_card([_row([_wrap("Give  " + GS.cost_text(give), 14, C_WARM, 300.0), _wrap("Receive  " + GS.cost_text(gt), 14, C_GOOD, 300.0), _spacer(), b])]))

func _do_save(n: int) -> void:
	notice = "Game saved to slot %d." % n if main.save_game(n) else "Save failed: storage unavailable."
	refresh()

func _del_slot(n: int) -> void:
	DirAccess.remove_absolute(GS.slot_path(n))
	notice = "Save deleted."
	refresh()

func _do_trade(give: Dictionary, gt: Dictionary) -> void:
	if GS.pay(give):
		var bonus: int = 1 if Story.f("haven_ally") else 0
		for k: String in gt.keys():
			GS.add(GS.store, k, int(gt[k]) + bonus)
			bonus = 0
		notice = "Traded. Received " + GS.cost_text(gt) + "."
		main.sfx.play("bell", -8.0)
	refresh()

# ---------- conversation ----------
const STORIES := {
	"Mechanic": "Twenty years in the Karsk sheds. I rebuilt this class of engine twice. She will run for as long as we feed her.",
	"Doctor": "Emergency ward at Vostok General, until there was no ward left. I still count beds in my sleep.",
	"Nurse": "I stayed in the pharmacy because someone had to count what was left. Then nobody came to collect it.",
	"Engineer": "I drew the signalling for this line. Every block from Nordhaven to the Port - I know where it fails.",
	"Cook": "Station canteen at Nordhaven. I fed a thousand commuters a day. I can feed a train.",
	"Farmer": "Lost the herd in the first winter. Give me soil, light and a little warmth and I will grow something.",
	"Electrician": "I kept the Ironworks substations alive for a month on my own. Wire is wire; it does what you tell it.",
	"Security": "Transit police. I was on the last evacuation platform when the gates closed. I do not intend to see that twice.",
}
const TRAIT_LINES := {
	"Stoic": "No use dwelling on it.", "Anxious": "I keep listening for the engine to stop.", "Cheerful": "Could be worse - we could be walking.", "Gruff": "That is all you are getting.",
	"Resourceful": "Give me scrap and an hour and I will surprise you.", "Quiet": "...that is more than I usually say.", "Protective": "Nobody gets left on a platform. Not again.", "Stubborn": "I said I would see the Port and I will.",
}

func open_talk(ag: CrewAgent) -> void:
	talk_agent = ag
	talk_reply = ag.mood_line()
	ag.say(talk_reply)
	open("talk", 0)

func _trust_name(v: float) -> String:
	if v >= 60.0:
		return "LOYAL"
	if v >= 30.0:
		return "TRUSTING"
	if v >= 10.0:
		return "WARMING TO YOU"
	return "WARY"

func _advice() -> String:
	var t: Dictionary = GS.train
	if GS.under_attack > 0.0:
		return "They are at the doors. Close them and get us moving - nothing follows a train at speed."
	if not GS.power_ok:
		return "We are dark. Start the engine or we freeze - the battery is flat."
	if float(t["diesel"]) < 120.0:
		return "The tank worries me. Depots, the Ironworks and the Port carry diesel. Fill up before the long stretch."
	if GS.count(GS.store, "food") < 8:
		return "Food is thin. Warehouses and the station shops are the best bet. A greenhouse carriage would end this for good."
	if GS.count(GS.store, "water") < 8:
		return "We need water. A water treatment carriage stands at the Port; until then, search every stop."
	if float(t["temp"]) < 10.0:
		return "It is too cold in here. Keep the heating on, keep the doors shut, and patch the hull when you can."
	if GS.hull_avg() < 55.0:
		return "The hull is taking a beating. Repair materials and a mechanic on Repairs - or do it yourself at the service panels."
	if GS.count(GS.store, "medicine") < 2:
		return "If someone falls ill we have nothing to give them. The city pharmacy and the Fort are worth the risk."
	if GS.cars.size() < 4:
		return "More carriages mean more room and more work done. Look behind the train at each stop - bring a tool kit and repair materials."
	if GS.crew.size() < GS.crew_cap():
		return "There are still people out there. Watch for flares on the platforms and listen to the radio."
	return "We are holding together. You can stop on the open line too - doors open anywhere once we are at a stand, and there is salvage between the stations."

func _status_line(c: Dictionary) -> String:
	var parts: Array = []
	if c["sick"]:
		parts.append("I am running a fever and I can barely stand.")
	if float(c["health"]) < 50.0:
		parts.append("I am hurt, and it is not healing.")
	if float(c["hunger"]) > 55.0:
		parts.append("I am hungry all the time.")
	if float(c["thirst"]) > 55.0:
		parts.append("My mouth is dry as ballast.")
	if float(c["fatigue"]) > 70.0:
		parts.append("I have not slept properly in days.")
	if float(GS.train["temp"]) < 9.0:
		parts.append("The cold has got into my hands.")
	if float(c["morale"]) < 35.0:
		parts.append("Honestly? I am not sure we make it.")
	if parts.is_empty():
		if float(c["morale"]) > 65.0:
			return "Fed, warm and moving. I have no complaints, conductor."
		return "I am managing. Ask me again when we reach the next stop."
	return " ".join(parts)

func _scr_talk() -> void:
	if talk_agent == null or not is_instance_valid(talk_agent):
		win_title.text = "NO ONE THERE"
		return
	var c: Dictionary = talk_agent.data
	var first: String = str(c["name"]).split(" ")[0]
	var trust: float = float(c.get("trust", 0.0))
	win_title.text = str(c["name"]).to_upper()
	win_sub.text = "%s    SKILL %d    %s" % [str(c["job"]).to_upper(), int(c["skill"]), str(c["trait"]).to_upper()]
	var stat: HBoxContainer = _row([], 14)
	for sk: Array in [["Health", "health", false], ["Hunger", "hunger", true], ["Thirst", "thirst", true], ["Fatigue", "fatigue", true], ["Morale", "morale", false]]:
		var val: float = c[sk[1]]
		var bad: bool = (val > 65.0) if sk[2] else (val < 35.0)
		var sv := VBoxContainer.new()
		sv.add_theme_constant_override("separation", 2)
		sv.add_child(_lbl("%s  %d" % [str(sk[0]).to_upper(), int(val)], 10, C_RED if bad else C_DIM))
		var sbar: ProgressBar = _bar(150, 5, C_RED if bad else (C_AMBER if sk[2] else C_GOOD))
		sbar.value = val
		sv.add_child(sbar)
		stat.add_child(sv)
	win_body.add_child(_card([_row([_icon("crew", C_RED if c["sick"] else C_AMBER), _lbl(str(c["act"]), 15, C_WARM), _spacer(), _lbl("TRUST   %s" % _trust_name(trust), 12, C_GOOD if trust >= 30.0 else C_DIM), _lbl("OUTPUT  %d %%" % int(GS.prod(c) * 100.0), 12, C_DIM)]), stat]))
	win_body.add_child(_card([_lbl("%s SAYS" % first.to_upper(), 10, C_AMBER), _wrap("\"%s\"" % talk_reply, 17, C_WARM, 930.0)]))
	var b_food: Button = _btn("Take this. You need it more than I do.   (give 1 Canned Food)", _talk.bind("food"), 470)
	b_food.disabled = not GS.can_afford({"food": 1})
	var b_med: Button = _btn("Hold still, this will help.   (use 1 Medical Supplies)", _talk.bind("med"), 470)
	b_med.disabled = not GS.can_afford({"medicine": 1}) or (not c["sick"] and float(c["health"]) > 80.0)
	var b_rest: Button = _btn("Stand down and rest. I will cover your duty.", _talk.bind("rest"), 470)
	b_rest.disabled = str(c["assign"]) == "Idle"
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	for b: Button in [_btn("How are you holding up?", _talk.bind("status"), 440), _btn("Tell me about yourself.", _talk.bind("story"), 440), _btn("What should we do next?", _talk.bind("advice"), 440), _btn("Who do you get on with?", _talk.bind("rel"), 440), _btn("What is on your mind?", _talk.bind("mind"), 440)]:
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		left.add_child(b)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	for b: Button in [b_food, b_med, b_rest]:
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		right.add_child(b)
	var idx: int = GS.crew.find(c)
	var info: Dictionary = GS.ASSIGN[c["assign"]]
	right.add_child(_row([_lbl("DUTY", 11, C_DIM), _btn("<", _talk_duty.bind(idx, -1), 36), _wrap(str(c["assign"]).to_upper(), 15, C_AMBER, 120.0), _btn(">", _talk_duty.bind(idx, 1), 36), _wrap(str(info["desc"]), 11, C_DIM, 210.0)], 8))
	win_body.add_child(_row([left, right], 24))

func _talk_duty(idx: int, dir: int) -> void:
	if idx >= 0:
		_cycle(idx, dir)

func _talk(topic: String) -> void:
	if talk_agent == null or not is_instance_valid(talk_agent):
		return
	var c: Dictionary = talk_agent.data
	var gain := 1.0
	match topic:
		"status":
			talk_reply = _status_line(c)
		"story":
			talk_reply = "%s %s" % [STORIES.get(c["job"], "There is not much to tell."), TRAIT_LINES.get(c["trait"], "")]
		"mind":
			talk_reply = Story.mind(c)
			if not Story.f("heard_" + str(c["name"])):
				Story.setf("heard_" + str(c["name"]))
				gain = 5.0
		"advice":
			talk_reply = _advice()
		"rel":
			var rel: Dictionary = c["rel"]
			var best := ""
			var bv := 2.0
			var worst := ""
			for rk: String in rel.keys():
				if float(rel[rk]) > bv:
					bv = float(rel[rk])
					best = rk
				if float(rel[rk]) < -4.0:
					worst = rk
			if best == "" and worst == "":
				talk_reply = "I keep to my own seat, mostly. Give it time - a train makes neighbours of everyone."
			else:
				talk_reply = ("%s and I look out for each other. " % best.split(" ")[0] if best != "" else "") + ("%s and I... we do not see eye to eye." % worst.split(" ")[0] if worst != "" else "")
		"food":
			if GS.pay({"food": 1}):
				c["hunger"] = maxf(0.0, float(c["hunger"]) - 40.0)
				c["morale"] = minf(100.0, float(c["morale"]) + 7.0)
				gain = 9.0
				talk_reply = "Thank you. I will not forget this."
				main.sfx.play("bell", -10.0)
		"med":
			if GS.pay({"medicine": 1}):
				c["sick"] = false
				c["health"] = minf(100.0, float(c["health"]) + 30.0)
				c["morale"] = minf(100.0, float(c["morale"]) + 5.0)
				gain = 12.0
				talk_reply = "That is better already. You have steady hands, conductor."
				main.sfx.play("bell", -10.0)
		"rest":
			c["assign"] = "Idle"
			c["fatigue"] = maxf(0.0, float(c["fatigue"]) - 12.0)
			c["morale"] = minf(100.0, float(c["morale"]) + 4.0)
			gain = 4.0
			talk_reply = "I will not argue. Wake me if you need me."
	if gain > 1.0 or main.talk_cd <= 0.0:
		if gain <= 1.0:
			main.talk_cd = 25.0
			c["morale"] = minf(100.0, float(c["morale"]) + 3.0)
		c["trust"] = minf(100.0, float(c.get("trust", 0.0)) + gain)
	talk_agent.say(talk_reply)
	refresh()

# ---------- settings ----------
func _slider(key: String, mn: float, mx: float, step: float, fmt: String) -> void:
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = step
	s.value = float(GS.settings[key])
	s.custom_minimum_size = Vector2(320, 22)
	s.focus_mode = Control.FOCUS_NONE
	var val: Label = _lbl(fmt % float(GS.settings[key]), 14, C_AMBER)
	s.value_changed.connect(_slider_changed.bind(key, val, fmt))
	win_body.add_child(_row([_wrap(str(KEY_NAMES.get(key, key)), 14, C_WARM, 260.0), s, val], 16))

const KEY_NAMES := {"scale": "Resolution scale", "volume": "Master volume", "sens": "Mouse sensitivity", "fov": "Field of view"}

func _slider_changed(v: float, key: String, val: Label, fmt: String) -> void:
	GS.settings[key] = v
	val.text = fmt % v
	main.apply_settings()

func _scr_settings() -> void:
	_head("Graphics")
	var pr: Array = []
	pr.append(_wrap("Quality preset", 14, C_WARM, 260.0))
	for i in 3:
		var b: Button = _btn(["LOW", "MEDIUM", "HIGH"][i], _set_preset.bind(i), 110)
		if int(GS.settings["preset"]) == i:
			b.add_theme_stylebox_override("normal", _sb(Color(0.62, 0.46, 0.17), C_AMBER))
			b.add_theme_color_override("font_color", Color(0.06, 0.06, 0.06))
		pr.append(b)
	win_body.add_child(_row(pr))
	_note("Low: no shadows or bloom, sparse snow and forest. Medium: shadows and bloom. High: long shadow range, dense snow.")
	_slider("scale", 0.5, 1.0, 0.05, "%.2f x")
	win_body.add_child(_row([_wrap("Fullscreen", 14, C_WARM, 260.0), _btn("ON" if GS.settings["fullscreen"] else "OFF", _toggle_fs, 110)]))
	_slider("fov", 60.0, 100.0, 1.0, "%.0f deg")
	_head("Audio")
	_slider("volume", 0.0, 1.0, 0.05, "%.2f")
	_head("Controls")
	_slider("sens", 0.3, 2.5, 0.05, "%.2f")
	var keys: Dictionary = GS.settings["keys"]
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 6)
	for a: String in GS.KEY_LABELS.keys():
		grid.add_child(_wrap(str(GS.KEY_LABELS[a]), 13, C_DIM, 250.0))
		var txt: String = "PRESS A KEY" if rebinding == a else OS.get_keycode_string(int(keys[a]))
		grid.add_child(_btn(txt, _start_rebind.bind(a), 150))
	win_body.add_child(grid)
	win_body.add_child(_row([_btn("RESET KEY BINDINGS", _reset_keys, 220), _lbl("Left mouse: fire.  Esc: pause (fixed).", 12, C_DIM)]))

func _set_preset(i: int) -> void:
	GS.settings["preset"] = i
	main.apply_settings()
	refresh()

func _toggle_fs() -> void:
	GS.settings["fullscreen"] = not GS.settings["fullscreen"]
	main.apply_settings()
	refresh()

func _start_rebind(a: String) -> void:
	rebinding = a
	refresh()

func _reset_keys() -> void:
	var d: Dictionary = GS.default_settings()
	GS.settings["keys"] = d["keys"]
	GS.apply_keys()
	refresh()

func _input(ev: InputEvent) -> void:
	if screen == "manual" and rebinding == "" and manual != null and is_instance_valid(manual) and ev is InputEventKey and ev.pressed:
		var mk: InputEventKey = ev
		var used := true
		match mk.keycode:
			KEY_RIGHT, KEY_D, KEY_PAGEDOWN:
				manual.step(1)
			KEY_LEFT, KEY_A, KEY_PAGEUP:
				manual.step(-1)
			KEY_DOWN, KEY_S:
				manual.jump(1)
			KEY_UP, KEY_W:
				manual.jump(-1)
			_:
				used = false
		if used:
			get_viewport().set_input_as_handled()
			return
	if rebinding != "" and ev is InputEventKey and ev.pressed:
		var ke: InputEventKey = ev
		if ke.physical_keycode != KEY_ESCAPE:
			var keys: Dictionary = GS.settings["keys"]
			keys[rebinding] = int(ke.physical_keycode)
			GS.apply_keys()
		rebinding = ""
		refresh()
		get_viewport().set_input_as_handled()

# ---------- inventory ----------
func _scr_inventory() -> void:
	var aboard: bool = main.aboard
	var units := 0
	for k: String in GS.store.keys():
		units += GS.count(GS.store, k)
	win_body.add_child(_row([_lbl("CARRIED  %.1f / %d kg" % [GS.weight(GS.inv), int(GS.inv_cap())], 16, C_AMBER), _spacer(), _lbl("TRAIN STORES  %d / %d units" % [units, int(GS.store_cap())], 16, C_AMBER), _btn("STORE EVERYTHING", _store_all, 190)]))
	if not aboard:
		_note("You are away from the train. Board it to move supplies between your pack and the train stores.", C_AMBER)
	_head("Weapons")
	var ar: Arsenal = main.player.arsenal
	var slot := 1
	for wid: String in ar.owned():
		var W: Dictionary = Arsenal.DEFS[wid]
		var wit: Dictionary = GS.ITEMS[W["ammo"]]
		var eb: Button = _btn("EQUIPPED" if wid == ar.cur else "EQUIP", _equip_w.bind(wid), 110)
		eb.disabled = wid == ar.cur
		win_body.add_child(_card([_row([_icon("ammo", C_WARM if wid == ar.cur else C_AMBER), _wrap("%d    %s" % [slot % 10, W["name"]], 16, C_WARM, 200.0), _wrap(str(W["cat"]), 11, C_AMBER, 140.0), _wrap("%d / %d    %s" % [int(GS.weapons[wid]), int(W["mag"]), wit["name"]], 13, C_WARM, 230.0), _spacer(), eb]), _wrap(str(W["desc"]), 12, C_DIM, 900.0)]))
		slot += 1
	_head("Supplies")
	var any := false
	for k: String in GS.ITEMS.keys():
		var qi: int = GS.count(GS.inv, k)
		var qs: int = GS.count(GS.store, k)
		if qi + qs <= 0:
			continue
		any = true
		var it: Dictionary = GS.ITEMS[k]
		var b1: Button = _btn("STORE", _xfer.bind(k, 1, true), 80)
		var b2: Button = _btn("STORE ALL", _xfer.bind(k, 999, true), 100)
		var b3: Button = _btn("TAKE", _xfer.bind(k, 1, false), 80)
		var b4: Button = _btn("TAKE 5", _xfer.bind(k, 5, false), 80)
		b1.disabled = not aboard or qi <= 0
		b2.disabled = not aboard or qi <= 0
		b3.disabled = not aboard or qs <= 0
		b4.disabled = not aboard or qs <= 0
		var items: Array = [_icon(k), _wrap(str(it["name"]), 16, C_WARM, 170.0), _wrap("Carried  %d" % qi, 14, C_WARM if qi > 0 else C_DIM, 100.0), b1, b2, _wrap("Stored  %d" % qs, 14, C_WARM if qs > 0 else C_DIM, 100.0), b3, b4, _spacer()]
		if k in ["food", "water", "medicine"]:
			var bu: Button = _btn("USE", _use.bind(k), 70)
			bu.disabled = qi <= 0
			items.append(bu)
		win_body.add_child(_card([_row(items), _wrap("%s  (%.2f kg each)" % [it["desc"], float(it["w"])], 12, C_DIM, 900.0)]))
	if not any:
		_note("Nothing carried and nothing in the stores.")

func _equip_w(id: String) -> void:
	main.player.arsenal.raised_t = 8.0
	main.player.arsenal.switch_to(id)
	refresh()

func _xfer(item: String, n: int, to_store: bool) -> void:
	if to_store:
		var q: int = mini(n, GS.count(GS.inv, item))
		var units := 0
		for k: String in GS.store.keys():
			units += GS.count(GS.store, k)
		q = mini(q, int(GS.store_cap()) - units)
		if q <= 0:
			notice = "The train stores are full. Couple a Storage carriage for more room."
		else:
			GS.take(GS.inv, item, q)
			GS.add(GS.store, item, q)
			GS.stats["transfers"] = int(GS.stats["transfers"]) + q
	else:
		var q2: int = mini(n, GS.count(GS.store, item))
		if q2 > 0:
			GS.take(GS.store, item, q2)
			GS.add(GS.inv, item, q2)
	refresh()

func _store_all() -> void:
	if not main.aboard:
		notice = "Board the train first."
	else:
		for k: String in GS.inv.keys():
			if not k.begins_with("ammo") and GS.count(GS.inv, k) > 0:
				_xfer(k, 999, true)
	refresh()

func _use(item: String) -> void:
	if not GS.take(GS.inv, item, 1):
		return
	var p: Dictionary = GS.player
	match item:
		"food":
			p["hunger"] = maxf(0.0, float(p["hunger"]) - 45.0)
			notice = "You eat a tin of rations."
		"water":
			p["thirst"] = maxf(0.0, float(p["thirst"]) - 45.0)
			notice = "You drink a bottle of water."
		"medicine":
			p["bleeding"] = false
			p["sick"] = false
			p["health"] = minf(100.0, float(p["health"]) + 30.0)
			notice = "Wounds dressed. You feel steadier."
	refresh()

# ---------- map ----------
func _scr_map() -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(940, 400)
	c.draw.connect(_draw_map.bind(c))
	win_body.add_child(c)
	_note("Filled markers: discovered stops. Hollow: unknown. Red cross: reported obstruction. The line loops: after Greywater Halt it returns to Nordhaven.")
	var s: float = GS.train["s"]
	_note("Lap %d of the Northern Line.  Position %.2f km.  %d of %d stops discovered." % [int(floor(s / (GS.SP * float(GS.NLOC)))) + 1, s / 1000.0, GS.discovered.size(), GS.NLOC], C_WARM)

func _draw_map(c: Control) -> void:
	var w: float = c.size.x
	var n: int = GS.NLOC
	var pts: Array = []
	for i in n:
		pts.append(Vector2(60.0 + float(i) * (w - 120.0) / float(n - 1), 170.0 + sin(float(i) * 1.25) * 55.0))
	c.draw_rect(Rect2(0, 0, w, 400), Color(0.07, 0.075, 0.085))
	for gx in 12:
		c.draw_line(Vector2(float(gx) * w / 11.0, 0), Vector2(float(gx) * w / 11.0, 400), Color(1, 1, 1, 0.03), 1.0)
	for i in n - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		c.draw_line(a, b, Color(0.5, 0.53, 0.57), 4.0)
		c.draw_line(a + Vector2(0, 5), b + Vector2(0, 5), Color(0.25, 0.27, 0.3), 1.0)
	var first: Vector2 = pts[0]
	var last: Vector2 = pts[n - 1]
	var loop: Array = [last, Vector2(last.x + 30, 330), Vector2(first.x - 30, 330), first]
	for i in 3:
		var la: Vector2 = loop[i]
		var lb: Vector2 = loop[i + 1]
		c.draw_dashed_line(la, lb, Color(0.4, 0.42, 0.46), 2.0, 8.0)
	c.draw_string(font, Vector2(w * 0.5 - 150, 352), "RETURN LOOP TO NORDHAVEN", HORIZONTAL_ALIGNMENT_CENTER, 300, 11, C_DIM)
	var s: float = GS.train["s"]
	var lap: int = int(floor(s / (GS.SP * float(n))))
	for i in n:
		var p: Vector2 = pts[i]
		var known: bool = GS.discovered.has(str(i))
		var L: Dictionary = GS.LOCS[i]
		var up: bool = i % 2 == 0
		if known:
			var col: Color = C_AMBER
			if str(L["kind"]) == "Survivor settlement":
				col = C_GOOD
			elif str(L["kind"]) == "Military installation":
				col = C_RED
			c.draw_rect(Rect2(p - Vector2(8, 8), Vector2(16, 16)), col)
			c.draw_string(font, p + Vector2(-90, -34 if up else 40), str(L["name"]), HORIZONTAL_ALIGNMENT_CENTER, 180, 13, C_WARM)
			c.draw_string(font, p + Vector2(-90, -20 if up else 54), str(L["kind"]), HORIZONTAL_ALIGNMENT_CENTER, 180, 10, C_DIM)
		else:
			c.draw_rect(Rect2(p - Vector2(8, 8), Vector2(16, 16)), Color(0.07, 0.075, 0.085))
			c.draw_rect(Rect2(p - Vector2(8, 8), Vector2(16, 16)), Color(0.5, 0.53, 0.57), false, 2.0)
			c.draw_string(font, p + Vector2(-90, -24 if up else 40), "Unknown", HORIZONTAL_ALIGNMENT_CENTER, 180, 11, C_DIM)
		var ev: String = GS.events.get(str(lap * n + i), "")
		if ev == "blocked":
			c.draw_line(p + Vector2(-13, -13), p + Vector2(13, 13), C_RED, 3.0)
			c.draw_line(p + Vector2(-13, 13), p + Vector2(13, -13), C_RED, 3.0)
		elif ev == "horde" or ev == "survivor" or ev == "wreck":
			c.draw_circle(p + Vector2(14, -14), 4.0, C_RED if ev == "horde" else C_GOOD)
	var f: float = fposmod(s / GS.SP, float(n))
	var i0: int = int(floor(f))
	var fr: float = f - float(i0)
	var tp: Vector2 = pts[i0]
	if i0 < n - 1:
		var np: Vector2 = pts[i0 + 1]
		tp = tp.lerp(np, fr)
	else:
		tp = tp.lerp(Vector2(last.x + 30, 330), fr)
	var mer := Vector2(last.x - 96.0, 262.0)
	var mk: int = int(GS.story.get("mk", -1))
	if Story.knows_meridian():
		if mk >= 0:
			c.draw_line(last, mer, Color(0.5, 0.53, 0.57), 4.0)
		else:
			c.draw_dashed_line(last, mer, C_AMBER, 2.0, 7.0)
		if Story.has("meridian"):
			c.draw_rect(Rect2(mer - Vector2(9, 9), Vector2(18, 18)), C_GOOD)
		else:
			c.draw_rect(Rect2(mer - Vector2(9, 9), Vector2(18, 18)), Color(0.07, 0.075, 0.085))
			c.draw_rect(Rect2(mer - Vector2(9, 9), Vector2(18, 18)), C_AMBER, false, 2.0)
		c.draw_string(font, mer + Vector2(-190, 6), "MERIDIAN CENTRAL", HORIZONTAL_ALIGNMENT_RIGHT, 174, 13, C_WARM)
		c.draw_string(font, mer + Vector2(-190, 20), "Corridor Seven" if mk >= 0 else "Corridor Seven  -  closed", HORIZONTAL_ALIGNMENT_RIGHT, 174, 10, C_DIM)
	for i in n:
		if str(GS.events.get(str(lap * n + i), "")) == "gate":
			var gp: Vector2 = pts[i]
			c.draw_line(gp + Vector2(-13, -13), gp + Vector2(13, 13), C_RED, 3.0)
			c.draw_line(gp + Vector2(-13, 13), gp + Vector2(13, -13), C_RED, 3.0)
	var tgt: int = Story.target_idx()
	if tgt == -2 or (tgt >= 0 and tgt < n):
		var op: Vector2 = mer if tgt == -2 else pts[tgt]
		c.draw_arc(op, 17.0, 0.0, TAU, 28, C_WARM, 2.0, true)
		c.draw_string(font, op + Vector2(-60, 34 if tgt == -2 else (30 if tgt % 2 == 0 else -22)), "OBJECTIVE", HORIZONTAL_ALIGNMENT_CENTER, 120, 10, C_WARM)
	if mk >= 0 and s > float(mk - 1) * GS.SP + 4.0 and s < float(mk) * GS.SP + 40.0:
		tp = last.lerp(mer, clampf((s - float(mk - 1) * GS.SP) / GS.SP, 0.0, 1.0))
	c.draw_colored_polygon(PackedVector2Array([tp + Vector2(0, -14), tp + Vector2(9, -28), tp + Vector2(-9, -28)]), C_WARM)
	c.draw_string(font, tp + Vector2(-40, -32), "TRAIN", HORIZONTAL_ALIGNMENT_CENTER, 80, 11, C_WARM)

# ---------- train management ----------
func _kv(k: String, v: String, col: Color = C_WARM) -> void:
	win_body.add_child(_row([_wrap(k, 14, C_DIM, 300.0), _lbl(v, 15, col)]))

func _toggle(label: String, key: String, on_txt: String = "ON", off_txt: String = "OFF") -> void:
	var on: bool = GS.train[key]
	win_body.add_child(_row([_wrap(label, 14, C_WARM, 300.0), _btn(on_txt if on else off_txt, _flip.bind(key), 120)]))

func _flip(key: String) -> void:
	GS.train[key] = not GS.train[key]
	main.sfx.play("ui_switch", -8.0)
	refresh()

func _ration() -> void:
	GS.train["ration"] = 0.5 if float(GS.train["ration"]) > 0.75 else 1.0
	refresh()

func _scr_manage() -> void:
	var t: Dictionary = GS.train
	match tab:
		0:
			_head("Condition")
			_kv("Carriages", "Locomotive + %d  (%d m)" % [GS.cars.size(), int(15.0 + 17.0 * float(GS.cars.size()))])
			_kv("People aboard", "%d of %d berths" % [GS.crew.size(), GS.crew_cap()])
			_kv("Average morale", "%d %%" % int(GS.avg_morale()), C_RED if GS.avg_morale() < 35.0 else C_WARM)
			_kv("Interior temperature", "%d C  (outside %d C)" % [int(round(float(t["temp"]))), int(round(GS.t_out))], C_RED if float(t["temp"]) < 8.0 else C_WARM)
			_kv("Air quality", "%d %%" % int(t["air"]), C_RED if float(t["air"]) < 40.0 else C_WARM)
			_kv("Sanitation", "%d %%" % int(t["sanitation"]), C_RED if float(t["sanitation"]) < 30.0 else C_WARM)
			_kv("Hull integrity (average)", "%d %%" % int(GS.hull_avg()))
			_kv("Diesel", "%d / 1200 L" % int(t["diesel"]), C_RED if float(t["diesel"]) < 80.0 else C_WARM)
			_kv("Power", "%+d kW net,  battery %d / %d kWh" % [int(GS.kw_gen - GS.kw_load), int(t["battery"]), int(GS.bat_cap())], C_WARM if GS.power_ok else C_RED)
			_head("Systems")
			_toggle("Heating", "heating")
			_toggle("Ventilation", "vent")
			_toggle("Interior lighting", "lights")
			if GS.has_car("generator"):
				_toggle("Generator carriage", "gen_on", "RUNNING", "STOPPED")
			win_body.add_child(_row([_wrap("Rations", 14, C_WARM, 300.0), _btn("FULL" if float(t["ration"]) > 0.75 else "HALF", _ration, 120), _lbl("Half rations halve consumption but hurt morale and leave people hungry.", 12, C_DIM)]))
		1:
			if GS.crew.is_empty():
				_note("No one else is aboard. Search the stops along the line for survivors.")
			for c: Dictionary in GS.crew:
				var rel: Dictionary = c["rel"]
				var best := ""
				var bv := 0.0
				for rk: String in rel.keys():
					if float(rel[rk]) > bv:
						bv = float(rel[rk])
						best = rk
				var worst := ""
				for rk: String in rel.keys():
					if float(rel[rk]) < -8.0:
						worst = rk
				var relt: String = "Close to %s" % best if best != "" else "No close ties yet"
				if worst != "":
					relt += ".  Friction with %s" % worst
				var stat: HBoxContainer = _row([], 14)
				for sk: Array in [["Health", "health", false], ["Hunger", "hunger", true], ["Thirst", "thirst", true], ["Fatigue", "fatigue", true], ["Morale", "morale", false]]:
					var val: float = c[sk[1]]
					var bad: bool = (val > 65.0) if sk[2] else (val < 35.0)
					var sv := VBoxContainer.new()
					sv.add_theme_constant_override("separation", 2)
					sv.add_child(_lbl("%s  %d" % [str(sk[0]).to_upper(), int(val)], 10, C_RED if bad else C_DIM))
					var sbar: ProgressBar = _bar(150, 5, C_RED if bad else (C_AMBER if sk[2] else C_GOOD))
					sbar.value = val
					sv.add_child(sbar)
					stat.add_child(sv)
				win_body.add_child(_card([_row([_icon("crew", C_RED if c["sick"] else C_AMBER), _lbl(str(c["name"]), 17, C_AMBER), _lbl("%s, skill %d   -   %s" % [c["job"], int(c["skill"]), c["trait"]], 13, C_DIM), _spacer(), _lbl("ILL" if c["sick"] else "", 13, C_RED)]), stat, _lbl("%s    |    Assignment: %s    |    %s" % [c["act"], c["assign"], relt], 12, C_DIM)]))
		2:
			var units := 0
			for k: String in GS.store.keys():
				units += GS.count(GS.store, k)
			_kv("Train stores", "%d / %d units" % [units, int(GS.store_cap())])
			var cook: float = 0.75 if GS.staffed("Cooking") > 0.0 else 1.0
			var fday: float = (float(GS.crew.size()) * 0.11 * float(t["ration"]) * cook + 0.09) * 24.0
			var wday: float = (float(GS.crew.size()) * 0.14 * float(t["ration"]) + 0.13) * 24.0
			_kv("Food consumption", "%.1f tins per day  (%.1f days left)" % [fday, float(GS.count(GS.store, "food")) / maxf(0.1, fday)])
			_kv("Water consumption", "%.1f litres per day  (%.1f days left)" % [wday, float(GS.count(GS.store, "water")) / maxf(0.1, wday)])
			_kv("Food spoilage", "Refrigerated" if GS.power_ok else "NO POWER - spoiling five times faster", C_WARM if GS.power_ok else C_RED)
			_kv("Production", "%s%s" % ["Greenhouse growing.  " if GS.staffed("Farming") > 0.0 else "", "Water plant running." if GS.staffed("Water") > 0.0 else ""] if (GS.staffed("Farming") + GS.staffed("Water")) > 0.0 else "None. Needs Greenhouse / Water Treatment cars with staff.")
			for k: String in GS.ITEMS.keys():
				var it: Dictionary = GS.ITEMS[k]
				win_body.add_child(_card([_row([_icon(k), _wrap(str(it["name"]), 15, C_WARM, 180.0), _wrap("Stored %d" % GS.count(GS.store, k), 14, C_AMBER, 110.0), _wrap("Carried %d" % GS.count(GS.inv, k), 14, C_DIM, 110.0), _wrap(str(it["desc"]), 12, C_DIM, 440.0)])]))
		3:
			_kv("Generation", "%.1f kW" % GS.kw_gen)
			_kv("Load", "%.1f kW" % GS.kw_load)
			_kv("Net", "%+.1f kW" % (GS.kw_gen - GS.kw_load), C_WARM if GS.kw_gen >= GS.kw_load else C_AMBER)
			var bb: ProgressBar = _bar(420, 14, C_AMBER)
			bb.value = float(t["battery"]) / GS.bat_cap() * 100.0
			win_body.add_child(_row([_wrap("Battery bank", 14, C_DIM, 300.0), bb, _lbl("%d / %d kWh" % [int(t["battery"]), int(GS.bat_cap())], 14)]))
			if GS.kw_gen < GS.kw_load:
				_kv("Time until blackout", "%.1f hours" % (float(t["battery"]) / maxf(0.1, GS.kw_load - GS.kw_gen)), C_AMBER)
			_head("Sources")
			_kv("Locomotive alternator", "%.0f kW (engine %s, condition %d %%)" % [42.0 * float(GS.loco["engine"]) / 100.0 if t["engine_on"] else 0.0, "running" if t["engine_on"] else "off", int(GS.loco["engine"])])
			_kv("Generator carriage", ("Running, burns 3 L/h" if t["gen_on"] else "Stopped") if GS.has_car("generator") else "Not coupled")
			_head("Consumers  (every carriage adds load)")
			var nv: float = float(GS.cars.size() + 1)
			_kv("Lighting", "%.1f kW" % (1.5 * nv if t["lights"] else 0.0))
			_kv("Heating", "%.1f kW at %d C outside" % [3.2 * nv * clampf((18.0 - GS.t_out) / 35.0, 0.3, 1.3) if t["heating"] else 0.0, int(GS.t_out)])
			_kv("Ventilation", "%.1f kW" % (1.0 * nv if t["vent"] else 0.0))
			_kv("Wiring losses", "%d %% (electrical condition %d %%)" % [int((100.0 - float(GS.loco["electrical"])) / 1.8), int(GS.loco["electrical"])])
			_toggle("Heating", "heating")
			_toggle("Ventilation", "vent")
			_toggle("Interior lighting", "lights")
			_toggle("Headlights", "headlights")
		4:
			_note("Each repair uses 2 Repair Materials and needs a Tool Kit. You have %d materials, %d tool kits. Crew assigned to Repairs fix the worst system automatically." % [GS.count(GS.store, "parts") + GS.count(GS.inv, "parts"), GS.count(GS.store, "tools") + GS.count(GS.inv, "tools")])
			var lr: Array = [_lbl("LOCOMOTIVE  4071", 16, C_AMBER), _spacer()]
			win_body.add_child(_card([_row(lr), _sys_row(GS.loco, "engine", "Engine  (speed, generation)"), _sys_row(GS.loco, "brakes", "Brakes  (stopping distance)"), _sys_row(GS.loco, "electrical", "Electrical  (wiring losses)"), _sys_row(GS.loco, "hull", "Hull  (insulation)")]))
			for i in GS.cars.size():
				var c: Dictionary = GS.cars[i]
				win_body.add_child(_card([_lbl("CAR %d  -  %s" % [i + 1, TrainRig.TYPE_LABEL[c["type"]]], 16, C_AMBER), _sys_row(c, "hull", "Hull"), _sys_row(c, "sys", "Systems")]))
		5:
			_head("Workbench")
			for r: Dictionary in GS.RECIPES:
				var need: String = r["car"]
				var ok: bool = GS.can_afford(r["cost"]) and (need == "" or GS.has_car(need))
				var b: Button = _btn("CRAFT", _craft.bind(r), 100)
				b.disabled = not ok
				var req: String = "Needs " + GS.cost_text(r["cost"])
				if need != "":
					req += "  +  %s carriage" % str(TrainRig.TYPE_LABEL[need]).capitalize()
				win_body.add_child(_card([_row([_wrap(str(r["name"]), 15, C_WARM, 240.0), _wrap(req, 13, C_DIM if ok else C_RED, 480.0), _spacer(), b])]))
			_head("Train upgrades")
			for u: Dictionary in GS.UPGRADES:
				var lvl: int = int(GS.upgrades.get(u["id"], 0))
				var maxed: bool = lvl >= (3 if u["id"] == "battery" else 1)
				var b: Button = _btn("INSTALLED" if maxed else "INSTALL", _upgrade.bind(u), 120)
				b.disabled = maxed or not GS.can_afford(u["cost"])
				win_body.add_child(_card([_row([_wrap("%s%s" % [u["name"], "  (x%d)" % lvl if lvl > 0 and not maxed else ""], 15, C_WARM, 240.0), _wrap("%s  Needs %s" % [u["desc"], GS.cost_text(u["cost"])], 13, C_DIM, 480.0), _spacer(), b])]))
		6:
			_note("Assign each survivor a duty. Matching professions work 50% better; morale, fatigue and illness change productivity.")
			for i in GS.crew.size():
				var c: Dictionary = GS.crew[i]
				var a: String = c["assign"]
				var info: Dictionary = GS.ASSIGN[a]
				var need: String = info["car"]
				var missing: bool = need != "" and not GS.has_car(need)
				win_body.add_child(_card([_row([_wrap(str(c["name"]), 16, C_AMBER, 190.0), _wrap(str(c["job"]), 13, C_DIM, 100.0), _btn("<", _cycle.bind(i, -1), 36), _wrap(a.to_upper(), 15, C_WARM, 120.0), _btn(">", _cycle.bind(i, 1), 36), _wrap("Output %d %%" % int(GS.prod(c) * 100.0), 13, C_WARM if GS.prod(c) > 0.5 else C_AMBER, 110.0), _wrap(("CARRIAGE MISSING.  " if missing else "") + str(info["desc"]), 12, C_RED if missing else C_DIM, 290.0)])]))
			if GS.crew.is_empty():
				_note("No crew to assign.")

func _sys_row(d: Dictionary, key: String, label: String) -> HBoxContainer:
	var v: float = d[key]
	var b: ProgressBar = _bar(260, 10, C_RED if v < 35.0 else (C_AMBER if v < 70.0 else C_GOOD))
	b.value = v
	var rb: Button = _btn("REPAIR", _repair.bind(d, key), 100)
	rb.disabled = v >= 99.0 or not GS.can_afford({"parts": 2}) or (GS.count(GS.store, "tools") + GS.count(GS.inv, "tools")) <= 0
	return _row([_wrap(label, 13, C_WARM, 240.0), b, _wrap("%d %%" % int(v), 13, C_WARM, 60.0), _spacer(), rb])

func _repair(d: Dictionary, key: String) -> void:
	if main.do_repair(d, key):
		notice = "Repair complete."
	refresh()

func _craft(r: Dictionary) -> void:
	if GS.pay(r["cost"]):
		var give: Dictionary = r["give"]
		for k: String in give.keys():
			GS.add(GS.store, k, int(give[k]))
		GS.stats["crafted"] = int(GS.stats["crafted"]) + 1
		notice = "Crafted: %s. Added to the train stores." % r["name"]
		main.sfx.play("clunk", -4.0)
	refresh()

func _upgrade(u: Dictionary) -> void:
	if GS.pay(u["cost"]):
		GS.upgrades[u["id"]] = int(GS.upgrades.get(u["id"], 0)) + 1
		GS.stats["crafted"] = int(GS.stats["crafted"]) + 1
		notice = "Installed: %s." % u["name"]
		main.sfx.play("clunk", -4.0)
	refresh()

func _cycle(i: int, dir: int) -> void:
	var c: Dictionary = GS.crew[i]
	var keys: Array = GS.ASSIGN.keys()
	var idx: int = keys.find(c["assign"])
	c["assign"] = keys[posmod(idx + dir, keys.size())]
	refresh()
