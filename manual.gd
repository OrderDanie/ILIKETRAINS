class_name ManualView
extends Control
## The field manual: a drawn, animated handbook. Every diagram reads the live state of the
## train and the player's real key bindings, so it always describes this game, right now.

const W := 992.0
const H := 470.0
const SBW := 204.0
const PX := 220.0
const PW := 770.0
const C_BG := Color(0.07, 0.075, 0.085)
const C_PAN := Color(0.12, 0.128, 0.142)
const C_LINE := Color(0.3, 0.32, 0.35)
const C_WARM := Color(0.93, 0.9, 0.84)
const C_AMBER := Color(0.88, 0.66, 0.26)
const C_RED := Color(0.84, 0.34, 0.27)
const C_DIM := Color(0.62, 0.63, 0.62)
const C_GOOD := Color(0.6, 0.8, 0.62)
const C_BLUE := Color(0.5, 0.72, 0.92)
const HULL := Color(0.26, 0.33, 0.41)
const INK := Color(0.05, 0.05, 0.06)
const NONE := Color(0, 0, 0, 0)
const AL := HORIZONTAL_ALIGNMENT_LEFT
const AC := HORIZONTAL_ALIGNMENT_CENTER
const AR := HORIZONTAL_ALIGNMENT_RIGHT

const CH := [["QUICK START", "stamina", 1], ["CONTROLS", "electronics", 1], ["THE TRAIN", "parts", 2], ["DRIVING", "diesel", 1], ["DOORS & BOARDING", "tools", 1], ["POWER & FUEL", "battery", 1], ["STAYING ALIVE", "health", 1], ["CREW & DUTIES", "crew", 1], ["REPAIRS", "tools", 1], ["SCAVENGING", "food", 1], ["WEAPONS", "ammo", 2], ["THREATS", "warn", 1], ["WORKSHOP & TRADE", "scrap", 1], ["CLOCK & WEATHER", "snow", 1], ["SAVING", "rest", 1]]
const ITEMS := ["food", "water", "medicine", "diesel", "batteries", "tools", "electronics", "parts", "scrap", "ammo", "ammo_rifle", "ammo_shell", "ammo_mag"]
const CARS := ["passenger", "storage", "medical", "kitchen", "workshop", "generator", "security", "greenhouse", "water"]
const WINDOWED := ["passenger", "medical", "kitchen", "greenhouse", "security", "workshop"]
const CAR_INFO := {
	"passenger": ["Berths for 8 survivors each. Sit on a seat to rest for an hour.", Color(0.86, 0.6, 0.16), "8 berths, rest on a seat"],
	"storage": ["+160 units of train stores. Move supplies at the racks, or from the inventory anywhere aboard.", Color(0.45, 0.47, 0.5), "+160 units of stores"],
	"medical": ["Doctors and nurses work twice as well here. Cabinet: treat your own wounds. Lets you craft medical supplies.", Color(0.9, 0.9, 0.88), "medics twice as effective"],
	"kitchen": ["A cook cuts food use by a quarter and lifts morale. Galley: eat a hot meal that also warms you.", Color(0.82, 0.6, 0.16), "food -25%, hot meals"],
	"workshop": ["Every repair restores 8% more and crew repair half as fast again. Workbench: ammunition, battery cells, upgrades.", Color(0.2, 0.33, 0.5), "better repairs, crafting"],
	"generator": ["+30 kW without the locomotive running. Burns 3 litres of diesel an hour. Switch it at its panel.", Color(0.62, 0.15, 0.11), "+30 kW, burns 3 L/h"],
	"security": ["Guards fight half as well again. Armoury: draw ammunition of every calibre from the train stores.", Color(0.1, 0.1, 0.11), "stronger guards, armoury"],
	"greenhouse": ["A farmer grows food here for as long as the power stays on. The grow lights draw 6 kW.", Color(0.2, 0.42, 0.14), "grows food (needs power)"],
	"water": ["An engineer purifies drinking water and sanitation improves. Tap: drink.", Color(0.25, 0.45, 0.7), "makes water, cleaner train"],
}
const KB := [
	[["ESC", KEY_ESCAPE, 1.3], ["1", KEY_1, 1.0], ["2", KEY_2, 1.0], ["3", KEY_3, 1.0], ["4", KEY_4, 1.0], ["5", KEY_5, 1.0], ["6", KEY_6, 1.0], ["7", KEY_7, 1.0], ["8", KEY_8, 1.0], ["9", KEY_9, 1.0], ["0", KEY_0, 1.0]],
	[["TAB", KEY_TAB, 1.6], ["Q", KEY_Q, 1.0], ["W", KEY_W, 1.0], ["E", KEY_E, 1.0], ["R", KEY_R, 1.0], ["T", KEY_T, 1.0], ["Y", KEY_Y, 1.0], ["U", KEY_U, 1.0], ["I", KEY_I, 1.0], ["O", KEY_O, 1.0], ["P", KEY_P, 1.0]],
	[["CAPS", 0, 1.9], ["A", KEY_A, 1.0], ["S", KEY_S, 1.0], ["D", KEY_D, 1.0], ["F", KEY_F, 1.0], ["G", KEY_G, 1.0], ["H", KEY_H, 1.0], ["J", KEY_J, 1.0], ["K", KEY_K, 1.0], ["L", KEY_L, 1.0]],
	[["SHIFT", KEY_SHIFT, 2.4], ["Z", KEY_Z, 1.0], ["X", KEY_X, 1.0], ["C", KEY_C, 1.0], ["V", KEY_V, 1.0], ["B", KEY_B, 1.0], ["N", KEY_N, 1.0], ["M", KEY_M, 1.0]],
	[["CTRL", 0, 1.6], ["ALT", 0, 1.3], ["SPACE", KEY_SPACE, 6.0]],
]
const LINESIDE := {"riveter": "CASE: KARSK DEPOT, IN THE SHED", "vesper": "LINESIDE: KARSK TUNNEL", "grendel": "LINESIDE: ABANDONED WAGONS", "halberd": "LINESIDE: RADIO MAST HUT"}
const GROUPS := {"move_up": 0, "move_down": 0, "move_left": 0, "move_right": 0, "jump": 0, "sprint": 0, "crouch": 0, "interact": 1, "flashlight": 1, "doors": 1, "reload": 2, "inspect": 2, "swap": 2, "inventory": 3, "map": 3, "objectives": 3, "manage": 3, "manual": 3, "horn": 4, "headlights": 4, "autopilot": 4}
const GCOL := [C_AMBER, C_GOOD, C_RED, C_BLUE, C_WARM]
const GUNS := {
	"p9": [[0.3, 0.36, 0.34, 0.2], [0.33, 0.52, 0.1, 0.38], [0.43, 0.54, 0.1, 0.07]],
	"kestrel": [[0.24, 0.4, 0.2, 0.2], [0.44, 0.41, 0.34, 0.1], [0.26, 0.56, 0.1, 0.36], [0.33, 0.36, 0.11, 0.27]],
	"stryk": [[0.25, 0.36, 0.42, 0.2], [0.67, 0.43, 0.1, 0.06], [0.42, 0.56, 0.06, 0.4], [0.3, 0.56, 0.07, 0.25], [0.08, 0.41, 0.17, 0.05], [0.08, 0.41, 0.03, 0.25], [0.42, 0.22, 0.1, 0.14]],
	"tundra": [[0.12, 0.32, 0.6, 0.26], [0.72, 0.41, 0.16, 0.06], [0.2, 0.58, 0.09, 0.36], [0.45, 0.58, 0.07, 0.26], [0.4, 0.18, 0.2, 0.1], [0.42, 0.28, 0.03, 0.05], [0.56, 0.28, 0.03, 0.05]],
	"harrow": [[0.3, 0.37, 0.3, 0.18], [0.6, 0.39, 0.24, 0.14], [0.84, 0.43, 0.1, 0.05], [0.42, 0.55, 0.08, 0.4], [0.32, 0.55, 0.06, 0.26], [0.06, 0.39, 0.24, 0.1], [0.06, 0.39, 0.05, 0.26], [0.38, 0.21, 0.1, 0.16]],
	"morrow": [[0.3, 0.39, 0.24, 0.18], [0.54, 0.39, 0.42, 0.06], [0.54, 0.48, 0.36, 0.06], [0.6, 0.46, 0.16, 0.12], [0.08, 0.45, 0.24, 0.14], [0.26, 0.55, 0.06, 0.2]],
	"sable": [[0.26, 0.39, 0.3, 0.18], [0.56, 0.41, 0.2, 0.12], [0.76, 0.41, 0.2, 0.1], [0.4, 0.57, 0.09, 0.26], [0.3, 0.57, 0.06, 0.26], [0.04, 0.41, 0.22, 0.08], [0.04, 0.41, 0.05, 0.26], [0.32, 0.18, 0.26, 0.1], [0.4, 0.28, 0.04, 0.11]],
	"northwind": [[0.2, 0.43, 0.36, 0.14], [0.56, 0.45, 0.4, 0.05], [0.92, 0.42, 0.06, 0.11], [0.02, 0.43, 0.2, 0.2], [0.22, 0.57, 0.06, 0.2], [0.24, 0.2, 0.34, 0.11], [0.3, 0.31, 0.04, 0.12], [0.5, 0.31, 0.04, 0.12], [0.36, 0.57, 0.1, 0.1]],
	"bastion": [[0.24, 0.35, 0.36, 0.24], [0.6, 0.41, 0.36, 0.07], [0.62, 0.37, 0.2, 0.16], [0.3, 0.59, 0.2, 0.3], [0.24, 0.59, 0.06, 0.26], [0.04, 0.41, 0.2, 0.08], [0.04, 0.41, 0.04, 0.24], [0.7, 0.53, 0.03, 0.36], [0.8, 0.53, 0.03, 0.36]],
	"vesper": [[0.26, 0.34, 0.36, 0.24], [0.62, 0.38, 0.2, 0.14], [0.3, 0.58, 0.07, 0.4], [0.5, 0.58, 0.05, 0.22], [0.08, 0.4, 0.18, 0.04], [0.08, 0.4, 0.03, 0.24], [0.4, 0.2, 0.1, 0.14]],
	"grendel": [[0.28, 0.38, 0.3, 0.17], [0.58, 0.38, 0.2, 0.15], [0.78, 0.43, 0.2, 0.05], [0.4, 0.55, 0.09, 0.3], [0.3, 0.55, 0.06, 0.26], [0.04, 0.4, 0.24, 0.16], [0.38, 0.22, 0.1, 0.16], [0.86, 0.33, 0.02, 0.1]],
	"halberd": [[0.24, 0.34, 0.36, 0.24], [0.6, 0.4, 0.3, 0.1], [0.9, 0.37, 0.07, 0.16], [0.42, 0.56, 0.2, 0.34], [0.26, 0.58, 0.06, 0.26], [0.04, 0.38, 0.2, 0.05], [0.04, 0.38, 0.04, 0.28], [0.36, 0.2, 0.1, 0.14]],
	"riveter": [[0.3, 0.32, 0.3, 0.26], [0.6, 0.36, 0.24, 0.18], [0.84, 0.4, 0.08, 0.1], [0.04, 0.36, 0.26, 0.18], [0.32, 0.58, 0.07, 0.28], [0.46, 0.58, 0.07, 0.26], [0.66, 0.54, 0.05, 0.26]],
	"arclight": [[0.2, 0.35, 0.3, 0.24], [0.5, 0.39, 0.46, 0.04], [0.5, 0.51, 0.46, 0.04], [0.56, 0.34, 0.05, 0.26], [0.65, 0.34, 0.05, 0.26], [0.74, 0.34, 0.05, 0.26], [0.83, 0.34, 0.05, 0.26], [0.26, 0.59, 0.06, 0.26], [0.04, 0.41, 0.16, 0.14]],
}

static var chapter := 0
static var page := 0
var main
var font: Font
var wide: Font
var t := 0.0
var mouse := Vector2(-1, -1)
var hot: Array = []
var org := Vector2.ZERO
var slots: Array = []

func _ready() -> void:
	custom_minimum_size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void: mouse = Vector2(-1, -1))
	for n in 4:
		slots.append(GS.slot_info(n))

func _process(dt: float) -> void:
	t += dt
	queue_redraw()

# ---------------- navigation ----------------
func step(dir: int) -> void:
	var pages: int = int(CH[chapter][2])
	page += dir
	if page >= pages:
		if chapter < CH.size() - 1:
			chapter += 1
			page = 0
		else:
			page = pages - 1
	elif page < 0:
		if chapter > 0:
			chapter -= 1
			page = int(CH[chapter][2]) - 1
		else:
			page = 0
	main.sfx.play("ui_click", -14.0, 1.2)

func jump(dir: int) -> void:
	go(chapter + dir)

func go(ch: int) -> void:
	chapter = clampi(ch, 0, CH.size() - 1)
	page = 0
	main.sfx.play("ui_click", -14.0)

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var mm: InputEventMouseMotion = ev
		mouse = mm.position
	elif ev is InputEventMouseButton and ev.pressed:
		var mb: InputEventMouseButton = ev
		if mb.button_index == MOUSE_BUTTON_LEFT:
			for h: Array in hot:
				var r: Rect2 = h[0]
				if r.has_point(mb.position):
					if str(h[1]) == "ch":
						go(int(h[2]))
					else:
						step(int(h[2]))
					break
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			step(1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			step(-1)
		accept_event()

# ---------------- drawing helpers (page space) ----------------
func P(x: float, y: float) -> Vector2:
	return org + Vector2(x, y)

func R(x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(org + Vector2(x, y), Vector2(w, h))

func tx(x: float, y: float, s: String, fs: int = 12, col: Color = C_WARM, al: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, w: float = -1.0, f: Font = null) -> void:
	draw_string(font if f == null else f, P(x, y), s, al, w, fs, col)

func para(x: float, y: float, s: String, w: float, fs: int = 11, col: Color = C_DIM, al: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> float:
	draw_multiline_string(font, P(x, y), s, al, w, fs, -1, col)
	return font.get_multiline_string_size(s, AL, w, fs).y

func tw(s: String, fs: int) -> float:
	return font.get_string_size(s, AL, -1, fs).x

func panel(x: float, y: float, w: float, h: float, accent: Color = Color(0, 0, 0, 0)) -> void:
	draw_rect(R(x, y, w, h), C_PAN)
	draw_rect(R(x, y, w, h), C_LINE, false, 1.0)
	if accent.a > 0.0:
		draw_rect(R(x, y, 3, h), accent)

func ico(kind: String, x: float, y: float, s: float, col: Color = C_AMBER) -> void:
	HudDraw.icon(self, kind, P(x, y), s, col)

func kn(action: String) -> String:
	var keys: Dictionary = GS.settings["keys"]
	return OS.get_keycode_string(int(keys.get(action, 0))).to_upper()

func key(x: float, y: float, label: String, col: Color = C_WARM) -> float:
	var w: float = maxf(22.0, tw(label, 11) + 12.0)
	draw_rect(R(x, y, w, 20), col)
	draw_rect(R(x, y + 17, w, 3), Color(0, 0, 0, 0.25))
	draw_string(font, P(x, y + 14), label, AC, w, 11, INK)
	return w + 6.0

func num(x: float, y: float, n: int, col: Color = C_AMBER) -> void:
	draw_circle(P(x, y), 9.0, col)
	draw_string(font, P(x - 9, y + 4), str(n), AC, 18, 11, INK)

func arrow(a: Vector2, b: Vector2, col: Color, wd: float = 2.0) -> void:
	if a.distance_to(b) < 2.0:
		return
	var d: Vector2 = (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	draw_line(org + a, org + b - d * 4.0, col, wd)
	draw_colored_polygon(PackedVector2Array([org + b, org + b - d * 9.0 + n * 5.0, org + b - d * 9.0 - n * 5.0]), col)

## An arrow with dashes that travel along it while the thing it stands for is actually flowing.
func flow(a: Vector2, b: Vector2, col: Color, on: bool) -> void:
	var ln: float = a.distance_to(b)
	if ln < 4.0:
		return
	var d: Vector2 = (b - a) / ln
	draw_line(org + a, org + b, Color(col.r, col.g, col.b, 0.3 if on else 0.14), 3.0)
	if on:
		var s: float = fmod(t * 42.0, 16.0)
		while s < ln - 8.0:
			draw_line(org + a + d * s, org + a + d * minf(s + 7.0, ln - 8.0), col, 3.0)
			s += 16.0
	var n := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([org + b, org + b - d * 9.0 + n * 5.0, org + b - d * 9.0 - n * 5.0]), col if on else Color(col.r, col.g, col.b, 0.3))

func bar(x: float, y: float, w: float, h: float, frac: float, col: Color) -> void:
	draw_rect(R(x, y, w, h), Color(0.03, 0.033, 0.04))
	draw_rect(R(x, y, w * clampf(frac, 0.0, 1.0), h), col)
	draw_rect(R(x, y, w, h), C_LINE, false, 1.0)

func ring(x: float, y: float, r: float, frac: float, col: Color, kind: String) -> void:
	draw_arc(P(x, y), r, 0.0, TAU, 32, Color(0.2, 0.21, 0.23), 4.0, true)
	draw_arc(P(x, y), r, -PI * 0.5, -PI * 0.5 + TAU * clampf(frac, 0.0, 1.0), 32, col, 4.0, true)
	ico(kind, x, y, r * 0.9, col)

func head(title: String, sub: String) -> void:
	tx(0, 26, title, 22, C_WARM, AL, -1, wide)
	tx(0, 44, sub, 11, C_AMBER)
	var pages: int = int(CH[chapter][2])
	if pages > 1:
		tx(PW - 140, 26, "PAGE %d OF %d" % [page + 1, pages], 11, C_DIM, AR, 140)
	draw_rect(R(0, 52, PW, 1), C_LINE)

## Tick drawn from two strokes, so it never depends on a font glyph.
func tick(x: float, y: float, col: Color) -> void:
	draw_line(P(x - 4, y), P(x - 1, y + 3), col, 2.0)
	draw_line(P(x - 1, y + 3), P(x + 5, y - 4), col, 2.0)

func _person(x: float, yf: float, sc: float, col: Color) -> void:
	draw_circle(P(x, yf - 1.62 * sc), 0.14 * sc, col)
	draw_line(P(x, yf - 1.46 * sc), P(x, yf - 0.8 * sc), col, 2.0)
	draw_line(P(x, yf - 0.8 * sc), P(x - 0.2 * sc, yf), col, 2.0)
	draw_line(P(x, yf - 0.8 * sc), P(x + 0.2 * sc, yf), col, 2.0)
	draw_line(P(x - 0.27 * sc, yf - 1.2 * sc), P(x + 0.27 * sc, yf - 1.2 * sc), col, 2.0)

# ---------------- frame ----------------
func _draw() -> void:
	if font == null or main == null:
		return
	hot = []
	org = Vector2.ZERO
	draw_rect(Rect2(0, 0, W, H), C_BG)
	_sidebar()
	org = Vector2(PX, 0)
	match chapter:
		0: _p_start()
		1: _p_controls()
		2:
			if page == 0:
				_p_train()
			else:
				_p_cars()
		3: _p_driving()
		4: _p_doors()
		5: _p_power()
		6: _p_alive()
		7: _p_crew()
		8: _p_repairs()
		9: _p_scav()
		10: _p_weapons()
		11: _p_threats()
		12: _p_workshop()
		13: _p_clock()
		_: _p_saving()
	org = Vector2.ZERO
	_nav()

func _sidebar() -> void:
	draw_rect(Rect2(0, 0, SBW, H), Color(0.095, 0.1, 0.112))
	draw_rect(Rect2(SBW, 0, 1, H), C_LINE)
	draw_string(wide, Vector2(12, 22), "CONTENTS", AL, -1, 12, C_AMBER)
	for i in CH.size():
		var r := Rect2(0, 34.0 + float(i) * 28.0, SBW, 27)
		var cur: bool = i == chapter
		var hov: bool = r.has_point(mouse)
		if cur:
			draw_rect(r, Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.16))
			draw_rect(Rect2(0, r.position.y, 3, 27), C_AMBER)
		elif hov:
			draw_rect(r, Color(1, 1, 1, 0.05))
		var c: Array = CH[i]
		draw_string(font, Vector2(10, r.position.y + 18), "%02d" % (i + 1), AL, -1, 10, C_DIM)
		HudDraw.icon(self, str(c[1]), Vector2(42, r.position.y + 13.5), 12.0, C_AMBER if cur else C_DIM)
		draw_string(font, Vector2(58, r.position.y + 18), str(c[0]), AL, -1, 12, C_WARM if (cur or hov) else C_DIM)
		hot.append([r, "ch", i])

func _nav() -> void:
	var y: float = H - 20.0
	draw_rect(Rect2(PX, y - 5.0, PW, 1), C_LINE)
	var total := 0
	var idx := 0
	for i in CH.size():
		if i < chapter:
			idx += int(CH[i][2])
		total += int(CH[i][2])
	idx += page
	for side in 2:
		var r := Rect2(PX if side == 0 else PX + PW - 74.0, y, 74, 19)
		var en: bool = idx > 0 if side == 0 else idx < total - 1
		var hov: bool = r.has_point(mouse) and en
		if hov:
			draw_rect(r, C_AMBER)
		draw_rect(r, C_AMBER if en else C_LINE, false, 1.0)
		draw_string(font, r.position + Vector2(0, 14), "PREVIOUS" if side == 0 else "NEXT", AC, 74, 10, INK if hov else (C_WARM if en else C_DIM))
		if en:
			hot.append([r, "step", -1 if side == 0 else 1])
	var dx: float = PX + PW * 0.5 - float(total) * 5.0
	for i in total:
		draw_circle(Vector2(dx + float(i) * 10.0 + 5.0, y + 10.0), 3.2 if i == idx else 2.0, C_AMBER if i == idx else C_LINE)
	draw_string(font, Vector2(PX + 86, y + 14), "A / D or arrows: turn the page", AL, -1, 9, C_DIM)
	draw_string(font, Vector2(PX + PW - 86 - 220, y + 14), "W / S: change chapter", AR, 220, 9, C_DIM)

# ---------------- 01 quick start ----------------
func _suggest() -> Array:
	if main.state == 0:
		return [1, "Learn the keys before you board."]
	if GS.under_attack > 0.0:
		return [11, "The train is under attack."]
	if not GS.power_ok:
		return [5, "The battery is flat."]
	if float(GS.train["diesel"]) < 80.0:
		return [5, "Diesel is running low."]
	if main.player.seated:
		return [3, "You are in the driver's seat."]
	if not main.aboard:
		return [9, "You are off the train."]
	var ws: Array = GS.worst_system()
	if float(ws[3]) < 50.0:
		return [8, "Part of the train is badly worn."]
	if GS.objective <= 1:
		return [3, "The engine is waiting to be started."]
	return [7, "Put your survivors to work."]

func _p_start() -> void:
	head("QUICK START", "YOUR FIRST TEN MINUTES ABOARD THE LAST TRAIN")
	var steps: Array = [
		["crew", "WALK TO THE CAB", "Forward through the carriage and the engine room.", "move_up"],
		["diesel", "WAKE THE ENGINE", "Look at the ENG switch on the driver's desk.", "interact"],
		["food", "SCAVENGE", "Open the doors, search every amber-tagged container.", "doors"],
		["parts", "STOCK THE TRAIN", "Back aboard: inventory, then STORE EVERYTHING.", "inventory"],
		["stamina", "DEPART", "Take the driver's seat, then engage the autopilot.", "autopilot"],
		["tools", "GROW THE TRAIN", "At each stop, couple the carriage standing behind you.", "interact"],
	]
	var omap: Array = [0, 1, 2, 3, 4, 4, 5, 6]
	var done: int = omap[clampi(GS.objective, 0, 7)]
	if main.state == 0:
		done = 0
	var y := 122.0
	draw_rect(R(14, y - 2, PW - 28, 4), C_LINE)
	for i in 41:
		draw_rect(R(18.0 + float(i) * 18.3, y - 6, 3, 12), Color(0.2, 0.21, 0.23))
	var n: int = steps.size()
	for i in n:
		var s: Array = steps[i]
		var x: float = 66.0 + float(i) * (PW - 132.0) / float(n - 1)
		var col: Color = C_GOOD if i < done else (C_AMBER if i == done else C_DIM)
		if i == done:
			draw_circle(P(x, y), 19.0 + 3.0 * sin(t * 4.0), Color(col.r, col.g, col.b, 0.22))
			draw_rect(R(x - 52, y - 11, 24, 9), HULL)
			draw_rect(R(x - 52, y - 8, 24, 2), C_AMBER)
			draw_circle(P(x - 46, y - 1), 2.5, INK)
			draw_circle(P(x - 34, y - 1), 2.5, INK)
		draw_circle(P(x, y), 15.0, C_BG)
		draw_arc(P(x, y), 15.0, 0.0, TAU, 28, col, 2.0, true)
		if i < done:
			tick(x, y, col)
		else:
			ico(str(s[0]), x, y, 14.0, col)
		tx(x - 60, y - 26, "%d" % (i + 1), 16, col, AC, 120, wide)
		tx(x - 62, y + 36, str(s[1]), 11, C_WARM if i >= done else C_DIM, AC, 124)
		var kl: String = kn(str(s[3]))
		var kw: float = maxf(22.0, tw(kl, 11) + 12.0)
		key(x - kw * 0.5, y + 44, kl, col)
		para(x - 58, y + 82, str(s[2]), 116, 10, C_DIM, AC)
	var rules: Array = [["warmth", "KEEP THEM WARM", "Heating runs on electricity. Keep the engine running, or the battery drains and the carriages freeze."], ["food", "KEEP THEM FED", "Everyone eats and drinks from the train stores. Fill them at every stop."], ["warn", "KEEP MOVING", "A lit, stopped train draws the infected. Nothing can follow it at speed."]]
	for i in 3:
		var r: Array = rules[i]
		var rx: float = float(i) * 190.0
		panel(rx, 262, 182, 124)
		ico(str(r[0]), rx + 20, 284, 18.0, C_AMBER)
		tx(rx + 38, 289, str(r[1]), 12, C_WARM)
		para(rx + 12, 312, str(r[2]), 160, 10, C_DIM)
	var sg: Array = _suggest()
	var sc: int = sg[0]
	var sr: Rect2 = R(574, 262, 196, 124)
	var hov: bool = sr.has_point(mouse)
	draw_rect(sr, Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.24 if hov else 0.12))
	draw_rect(sr, C_AMBER, false, 1.0)
	tx(586, 282, "READ NEXT", 10, C_AMBER)
	tx(586, 306, str(CH[sc][0]), 15, C_WARM, AL, -1, wide)
	para(586, 328, str(sg[1]), 172, 11, C_DIM)
	tx(586, 374, "CLICK TO OPEN", 9, C_AMBER)
	arrow(Vector2(700, 370), Vector2(752, 370), C_AMBER)
	hot.append([sr, "ch", sc])
	tx(0, 410, "THE JOURNEY", 10, C_AMBER)
	tx(96, 410, "Ten stops down the Northern Line to the Port of Kaldwick. Then the line loops north, harder every lap.", 10, C_DIM)
	var mx: float = key(0, 420, kn("manual"), C_BLUE)
	tx(mx + 2, 434, "opens this manual at any time. Every diagram shows your own train as it is right now.", 10, C_DIM)

# ---------------- 02 controls ----------------
func _p_controls() -> void:
	head("CONTROLS", "YOUR CURRENT KEY BINDINGS  -  REBIND ANY OF THEM IN SETTINGS")
	var keys: Dictionary = GS.settings["keys"]
	var grp: Dictionary = {}
	for a: String in keys.keys():
		grp[int(keys[a])] = int(GROUPS.get(a, -1))
	for d in 10:
		grp[KEY_0 + d] = 2
	grp[int(KEY_ESCAPE)] = 3
	var u := 38.0
	for r in KB.size():
		var row: Array = KB[r]
		var x := 0.0
		for k: Array in row:
			var w: float = float(k[2]) * u - 4.0
			var code: int = int(k[1])
			var g: int = int(grp.get(code, -1)) if code != 0 else -1
			var rr: Rect2 = R(x, 66.0 + float(r) * 38.0, w, 34.0)
			if g >= 0:
				var gc: Color = GCOL[g]
				draw_rect(rr, gc)
				draw_rect(Rect2(rr.position + Vector2(0, 30), Vector2(w, 4)), Color(0, 0, 0, 0.25))
				draw_string(font, rr.position + Vector2(0, 21), str(k[0]), AC, w, 11, INK)
			else:
				draw_rect(rr, Color(0.14, 0.15, 0.165))
				draw_rect(rr, Color(0.22, 0.23, 0.25), false, 1.0)
				draw_string(font, rr.position + Vector2(0, 21), str(k[0]), AC, w, 10, Color(0.42, 0.43, 0.44))
			x += float(k[2]) * u
	var legend: Array = [
		[0, "MOVEMENT", [["Move", "%s %s %s %s" % [kn("move_up"), kn("move_left"), kn("move_down"), kn("move_right")]], ["Jump  /  climb aboard", kn("jump")], ["Sprint", kn("sprint")], ["Crouch (quieter)", kn("crouch")]]],
		[1, "INTERACTION", [["Use, talk, search", kn("interact")], ["Carriage doors", kn("doors")], ["Flashlight", kn("flashlight")]]],
		[2, "WEAPONS", [["Reload", kn("reload")], ["Inspect weapon", kn("inspect")], ["Next weapon", kn("swap")], ["Weapon slots", "1 - 0"]]],
		[3, "SCREENS", [["Inventory", kn("inventory")], ["Railway map", kn("map")], ["Objectives and radio log", kn("objectives")], ["Train management", kn("manage")], ["This manual", kn("manual")], ["Pause, save, settings", "ESC"]]],
		[4, "IN THE DRIVER'S SEAT", [["Power up  /  power down, brake", "%s  %s" % [kn("move_up"), kn("move_down")]], ["Emergency brake", kn("jump")], ["Autopilot", kn("autopilot")], ["Horn", kn("horn")], ["Headlights", kn("headlights")]]],
	]
	var ly := 72.0
	for grow: Array in legend:
		var gc2: Color = GCOL[int(grow[0])]
		draw_rect(R(470, ly - 9, 10, 10), gc2)
		tx(486, ly, str(grow[1]), 10, gc2)
		ly += 15.0
		var lines: Array = grow[2]
		for ln: Array in lines:
			tx(486, ly, str(ln[0]), 10, C_DIM)
			tx(636, ly, str(ln[1]), 10, C_WARM, AR, 130)
			ly += 12.5
		ly += 5.0
	# mouse
	var mx := 16.0
	var my := 280.0
	draw_rect(R(mx, my, 80, 124), Color(0.14, 0.15, 0.165))
	draw_rect(R(mx, my, 39, 48), Color(C_RED.r, C_RED.g, C_RED.b, 0.85))
	draw_rect(R(mx + 41, my, 39, 48), Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.85))
	draw_rect(R(mx + 34, my + 10, 12, 26), C_BLUE)
	draw_rect(R(mx, my, 80, 124), C_LINE, false, 1.0)
	var rows: Array = [[C_RED, "LEFT BUTTON", "Fire. The first click locks the mouse to the view."], [C_AMBER, "RIGHT BUTTON", "Hold to aim down the sights or through the scope."], [C_BLUE, "WHEEL", "Previous or next weapon."], [C_DIM, "MOVE", "Look around. Sensitivity and field of view: Settings."]]
	for i in 4:
		var rw: Array = rows[i]
		var rc: Color = rw[0]
		draw_rect(R(116, my + 2.0 + float(i) * 31.0, 10, 10), rc)
		tx(134, my + 11.0 + float(i) * 31.0, str(rw[1]), 10, rc)
		tx(134, my + 24.0 + float(i) * 31.0, str(rw[2]), 10, C_DIM)
	tx(0, 262, "MOUSE", 10, C_AMBER)

# ---------------- 03 the train ----------------
func _train_side(x0: float, y0: float, width: float) -> Array:
	var n: int = GS.cars.size()
	var total: float = 15.0 + 17.0 * float(n)
	var sc: float = minf(width / total, 12.0)
	var x: float = x0 + (width - total * sc) * 0.5
	var yb: float = y0 - 0.9 * sc
	var yt: float = y0 - 3.8 * sc
	draw_rect(R(x0, y0, width, 2), C_LINE)
	var i := 0
	while float(i) * 7.0 < width:
		draw_rect(R(x0 + float(i) * 7.0, y0 + 2, 2, 3), Color(0.2, 0.21, 0.23))
		i += 1
	var lit: bool = GS.train["lights"] and GS.power_ok
	draw_colored_polygon(PackedVector2Array([P(x, yb), P(x, yb - 1.1 * sc), P(x + 1.0 * sc, yt), P(x + 15.0 * sc, yt), P(x + 15.0 * sc, yb)]), HULL)
	draw_rect(R(x + 0.6 * sc, y0 - 2.15 * sc, 14.4 * sc, maxf(1.5, 0.14 * sc)), C_AMBER)
	draw_rect(R(x + 1.2 * sc, yt + 0.5 * sc, 1.7 * sc, 0.9 * sc), Color(0.95, 0.78, 0.45) if lit else Color(0.05, 0.07, 0.09))
	for g in 3:
		draw_rect(R(x + (6.4 + float(g) * 2.6) * sc, yt + 0.6 * sc, 2.0 * sc, 0.8 * sc), Color(0.12, 0.13, 0.15))
	for wz: float in [2.2, 4.2, 10.8, 12.8]:
		draw_circle(P(x + wz * sc, y0 - 0.46 * sc), maxf(1.5, 0.46 * sc), Color(0.1, 0.1, 0.11))
	for ci in n:
		var c: Dictionary = GS.cars[ci]
		var cx: float = x + (16.0 + float(ci) * 17.0) * sc
		var info: Array = CAR_INFO.get(c["type"], CAR_INFO["passenger"])
		var band: Color = info[1]
		draw_rect(R(cx - 1.0 * sc, yb - 2.3 * sc, 1.0 * sc, 2.3 * sc), Color(0.04, 0.04, 0.05))
		draw_rect(R(cx, yt, 16.0 * sc, yb - yt), HULL)
		draw_rect(R(cx, yt, 16.0 * sc, maxf(1.5, 0.3 * sc)), Color(0.42, 0.44, 0.47))
		draw_rect(R(cx + 2.0 * sc, y0 - 1.6 * sc, 14.0 * sc, maxf(1.5, 0.18 * sc)), band)
		draw_rect(R(cx + 0.6 * sc, yt + 0.5 * sc, 1.3 * sc, 2.2 * sc), C_AMBER if GS.train["doors_open"] else Color(0.14, 0.18, 0.24))
		if WINDOWED.has(c["type"]):
			for k in 6:
				draw_rect(R(cx + (3.0 + float(k) * 2.15) * sc, yt + 0.65 * sc, 1.6 * sc, 0.85 * sc), Color(0.95, 0.78, 0.45) if lit else Color(0.05, 0.07, 0.09))
		for wz2: float in [1.6, 3.6, 12.4, 14.4]:
			draw_circle(P(cx + wz2 * sc, y0 - 0.46 * sc), maxf(1.5, 0.46 * sc), Color(0.1, 0.1, 0.11))
	return [x, sc]

func _p_train() -> void:
	head("THE TRAIN", "YOUR TRAIN AS IT STANDS NOW  -  WHAT IS WHERE")
	var y0 := 162.0
	var ts: Array = _train_side(10, y0, PW - 20)
	var x: float = ts[0]
	var sc: float = ts[1]
	var n: int = GS.cars.size()
	var gz: float = 32.5 if n >= 2 else 15.5
	var marks: Array = [[1, 1.9, true], [2, 4.5, false], [3, 10.0, true], [4, 17.25, false], [5, 18.7, true], [6, gz, false]]
	for m: Array in marks:
		var mx: float = x + float(m[1]) * sc
		var up: bool = m[2]
		var ya: float = (y0 - 3.8 * sc - 3.0) if up else (y0 - 0.9 * sc + 6.0)
		var yn: float = (y0 - 3.8 * sc - 22.0) if up else (y0 + 22.0)
		draw_line(P(mx, ya), P(mx, yn), C_AMBER, 1.0)
		num(mx, yn, int(m[0]))
	var legend: Array = [
		[1, "DRIVER'S CAB", "Desk switches, displays and the driver's seat. See DRIVING."],
		[2, "CREW ROOM", "Bunk: sleep until rested, and save. Wall terminal: management."],
		[3, "ENGINE ROOM", "The gangway beside the engine: %s services the worst loco system." % kn("interact")],
		[4, "DOORS, BOTH SIDES", "One pair per carriage. Open anywhere once the train has stopped."],
		[5, "SERVICE PANEL", "On the vestibule wall of every carriage. %s repairs that carriage." % kn("interact")],
		[6, "GANGWAYS", "Walk from carriage to carriage, even at full speed."],
	]
	for i in 6:
		var l: Array = legend[i]
		var lx: float = float(i % 2) * 388.0
		var ly: float = 206.0 + float(i / 2) * 42.0
		num(lx + 10, ly + 6, int(l[0]))
		tx(lx + 26, ly + 10, str(l[1]), 12, C_WARM)
		para(lx + 26, ly + 24, str(l[2]), 356, 10, C_DIM)
	tx(0, 338, "YOUR CARRIAGES", 10, C_AMBER)
	tx(586, 338, "HULL", 9, C_DIM)
	tx(682, 338, "SYSTEMS", 9, C_DIM)
	for ci in n:
		var c: Dictionary = GS.cars[ci]
		var y: float = 352.0 + float(ci) * 10.6
		var info: Array = CAR_INFO.get(c["type"], CAR_INFO["passenger"])
		var band: Color = info[1]
		draw_rect(R(0, y - 7, 8, 8), band)
		tx(14, y, "CAR %d" % (ci + 1), 9, C_DIM)
		tx(58, y, str(TrainRig.TYPE_LABEL[c["type"]]), 9, C_WARM)
		tx(180, y, str(info[2]), 9, C_DIM)
		var hv: float = c["hull"]
		var sv: float = c["sys"]
		bar(586, y - 6, 60, 6, hv / 100.0, C_RED if hv < 35.0 else (C_AMBER if hv < 70.0 else C_GOOD))
		tx(650, y, "%d" % int(hv), 9, C_DIM)
		bar(682, y - 6, 60, 6, sv / 100.0, C_RED if sv < 35.0 else (C_AMBER if sv < 70.0 else C_GOOD))
		tx(746, y, "%d" % int(sv), 9, C_DIM)

func _p_cars() -> void:
	head("THE TRAIN", "CARRIAGE CATALOGUE  -  WHAT EACH ONE DOES AND WHERE IT WAITS")
	for i in CARS.size():
		var ty: String = CARS[i]
		var info: Array = CAR_INFO[ty]
		var x: float = float(i % 3) * 260.0
		var y: float = 62.0 + float(i / 3) * 126.0
		var have: int = GS.car_count(ty)
		panel(x, y, 250, 120, C_GOOD if have > 0 else NONE)
		var band: Color = info[1]
		draw_rect(R(x + 12, y + 12, 96, 22), HULL)
		draw_rect(R(x + 12, y + 10, 96, 3), Color(0.42, 0.44, 0.47))
		draw_rect(R(x + 24, y + 27, 84, 3), band)
		draw_rect(R(x + 15, y + 15, 7, 17), C_AMBER)
		if WINDOWED.has(ty):
			for k in 6:
				draw_rect(R(x + 28.0 + float(k) * 13.0, y + 16, 9, 6), Color(0.95, 0.78, 0.45))
		for wx: float in [22.0, 32.0, 88.0, 98.0]:
			draw_circle(P(x + wx, y + 37), 3.5, Color(0.04, 0.04, 0.05))
		tx(x + 120, y + 24, str(TrainRig.TYPE_LABEL[ty]), 12, C_WARM)
		if have > 0:
			tick(x + 126, y + 36, C_GOOD)
			tx(x + 136, y + 40, "COUPLED x%d" % have, 9, C_GOOD)
		else:
			tx(x + 120, y + 40, "NOT YET FOUND", 9, C_DIM)
		para(x + 12, y + 60, str(info[0]), 228, 10, C_DIM)
		var where := "Starts with the train"
		for li in GS.LOCS.size():
			var L: Dictionary = GS.LOCS[li]
			if str(L["car"]) == ty:
				where = "Stop %d  -  %s" % [li + 1, L["name"]]
		tx(x + 12, y + 111, where.to_upper(), 9, C_AMBER)

# ---------------- 04 driving ----------------
func _p_driving() -> void:
	head("DRIVING", "THE DRIVER'S DESK, BY HAND AND ON AUTOPILOT")
	var tr: Dictionary = GS.train
	draw_colored_polygon(PackedVector2Array([P(8, 262), P(392, 262), P(364, 150), P(36, 150)]), C_PAN)
	draw_polyline(PackedVector2Array([P(8, 262), P(392, 262), P(364, 150), P(36, 150), P(8, 262)]), C_LINE, 1.0)
	draw_rect(R(30, 68, 340, 80), Color(0.09, 0.095, 0.105))
	var gcol := Color(0.6, 1.0, 0.85)
	for k in 3:
		draw_rect(R(40.0 + float(k) * 110.0, 76, 100, 62), Color(0.03, 0.1, 0.085))
		draw_rect(R(40.0 + float(k) * 110.0, 76, 100, 62), C_LINE, false, 1.0)
	tx(46, 93, "ENG  %s" % ("RUN" if tr["engine_on"] else "OFF"), 10, gcol)
	tx(46, 108, "THR %d%%  BRK %d%%" % [int(float(tr["throttle"]) * 100.0), int(float(tr["brake"]) * 100.0)], 10, gcol)
	tx(46, 123, "AUTO  %s" % ("ON" if tr["autopilot"] else "OFF"), 10, gcol)
	tx(150, 118, "%d" % int(round(float(tr["speed"]) * 3.6)), 30, Color(1.0, 0.85, 0.5), AC, 100)
	tx(150, 132, "KM/H", 8, C_DIM, AC, 100)
	var s: float = tr["s"]
	var nxt: float = round(s / GS.SP) * GS.SP
	if s > nxt + 4.0:
		nxt += GS.SP
	tx(266, 93, "NEXT %dm" % int(maxf(0.0, nxt - s)), 10, gcol)
	tx(266, 108, "DIESEL %dL" % int(tr["diesel"]), 10, gcol)
	tx(266, 123, "BATT %dkWh" % int(tr["battery"]), 10, gcol)
	var sw: Array = [["ENG", tr["engine_on"]], ["LAMP", tr["headlights"]], ["WIPE", tr["wipers"]], ["DOOR", tr["doors_open"]], ["AUTO", tr["autopilot"]], ["HORN", false]]
	for i in 6:
		var se: Array = sw[i]
		var sx: float = 92.0 + float(i) * 43.0
		var lit: bool = se[1]
		draw_rect(R(sx - 9, 188, 18, 22), Color(0.2, 0.21, 0.23))
		draw_rect(R(sx - 5, 191.0 if lit else 199.0, 10, 8), C_WARM)
		draw_circle(P(sx, 178), 4.0, ((C_GOOD if i == 0 else C_AMBER) if lit else Color(0.25, 0.2, 0.12)))
		tx(sx - 20, 226, str(se[0]), 9, C_WARM, AC, 40)
	for side in 2:
		var lx: float = 46.0 if side == 0 else 354.0
		var val: float = float(tr["brake"]) if side == 0 else float(tr["throttle"])
		var col: Color = C_RED if side == 0 else C_AMBER
		draw_rect(R(lx - 10, 180, 20, 60), Color(0.07, 0.075, 0.085))
		var ky: float = 234.0 - val * 48.0
		draw_line(P(lx, 238), P(lx, ky), C_DIM, 3.0)
		draw_rect(R(lx - 9, ky - 5, 18, 10), col)
		tx(lx - 30, 256, "BRAKE" if side == 0 else "POWER", 9, col, AC, 60)
	draw_rect(R(170, 272, 60, 24), Color(0.2, 0.22, 0.27))
	draw_rect(R(176, 266, 48, 8), Color(0.26, 0.28, 0.34))
	tx(240, 290, "DRIVER'S SEAT", 9, C_DIM)
	num(92, 162, 1)
	num(150, 284, 2)
	num(46, 166, 3)
	num(354, 166, 3)
	num(264, 162, 4)
	num(307, 162, 5)
	var steps: Array = [
		["START THE ENGINE", "Look at the ENG switch and press the use key. It needs diesel in the tank.", ["interact"]],
		["TAKE THE SEAT", "Use the driver's seat. The same key lets you out again.", ["interact"]],
		["DRIVE BY HAND", "Forward releases the brake, then adds power. Back cuts power, then brakes. Jump is the emergency brake.", ["move_up", "move_down", "jump"]],
		["AUTOPILOT", "Runs to the next stop and brakes for the platform. Leave the seat and walk the train while it drives.", ["autopilot"]],
		["HORN AND HEADLIGHTS", "Both carry a long way. Headlights also draw the infected to a stopped train.", ["horn", "headlights"]],
	]
	for i in 5:
		var st: Array = steps[i]
		var y: float = 66.0 + float(i) * 48.0
		num(420, y + 8, i + 1)
		tx(436, y + 12, str(st[0]), 12, C_WARM)
		var kx := 770.0
		var acts: Array = st[2]
		for ai in acts.size():
			var lab: String = kn(str(acts[acts.size() - 1 - ai]))
			var w: float = maxf(22.0, tw(lab, 11) + 12.0)
			kx -= w
			key(kx, y - 2, lab)
			kx -= 5.0
		para(436, y + 27, str(st[1]), 330, 10, C_DIM)
	panel(0, 310, 530, 128)
	tx(10, 326, "ONE %d m LEG ON AUTOPILOT" % int(GS.SP), 10, C_AMBER)
	var gx0 := 44.0
	var gy0 := 424.0
	var gw := 470.0
	var gh := 70.0
	draw_line(P(gx0, gy0), P(gx0 + gw, gy0), C_LINE, 1.0)
	draw_line(P(gx0, gy0), P(gx0, gy0 - gh - 6.0), C_LINE, 1.0)
	var pts := PackedVector2Array()
	for i in 61:
		var ds: float = float(i) * GS.SP / 60.0
		var v: float = minf(26.0 * (1.0 - exp(-ds / 190.0)), sqrt(1.6 * maxf(0.0, GS.SP - ds)))
		pts.append(P(gx0 + ds / GS.SP * gw, gy0 - v / 30.0 * gh))
	draw_polyline(pts, C_AMBER, 2.0, true)
	var da: float = minf(fmod(t * GS.SP / 7.5, GS.SP * 1.17), GS.SP)
	var dv: float = minf(26.0 * (1.0 - exp(-da / 190.0)), sqrt(1.6 * maxf(0.0, GS.SP - da)))
	var dp: Vector2 = Vector2(gx0 + da / GS.SP * gw, gy0 - dv / 30.0 * gh)
	draw_circle(org + dp, 5.0, C_WARM)
	tx(dp.x - 30, dp.y - 10, "%d km/h" % int(dv * 3.6), 9, C_WARM, AC, 60)
	tx(gx0 + 30, gy0 - 8, "ACCELERATES", 9, C_DIM)
	tx(gx0 + 190, gy0 - gh - 6, "CRUISES", 9, C_DIM)
	tx(gx0 + 300, gy0 - 8, "BRAKES FOR THE PLATFORM", 9, C_DIM)
	tx(4, gy0 + 4, "STOP", 8, C_DIM)
	tx(gx0 + gw - 30, gy0 + 12, "NEXT STOP", 8, C_DIM)
	panel(540, 310, 230, 128)
	tx(550, 326, "GOOD TO KNOW", 10, C_AMBER)
	var notes: Array = ["Power is cut while any door is open.", "Step off and the train brakes itself to a stand.", "Top speed falls with engine damage and after a signal failure."]
	var ny := 344.0
	for nt: String in notes:
		draw_rect(R(550, ny - 7, 5, 5), C_AMBER)
		ny += para(562, ny, nt, 200, 10, C_DIM) + 6.0

# ---------------- 05 doors and boarding ----------------
func _xsec(cx: float, gy: float, sc: float, platform: bool) -> void:
	var gl: float = 2.3 if platform else 3.9
	draw_rect(R(cx - gl * sc, gy, (gl + 4.3) * sc, 2), C_LINE)
	draw_rect(R(cx - 2.3 * sc, gy - 0.27 * sc, 4.6 * sc, 0.27 * sc), Color(0.2, 0.2, 0.22))
	for sd: float in [-1.0, 1.0]:
		draw_rect(R(cx + sd * 0.75 * sc - 2.0, gy - 0.45 * sc, 4, 0.18 * sc), C_DIM)
		draw_rect(R(cx + sd * 0.75 * sc - 3.0, gy - 1.37 * sc, 6, 0.92 * sc), Color(0.1, 0.1, 0.11))
	draw_rect(R(cx - 0.75 * sc, gy - 0.94 * sc, 1.5 * sc, 3), Color(0.1, 0.1, 0.11))
	draw_colored_polygon(PackedVector2Array([P(cx - 1.5 * sc, gy - 1.2 * sc), P(cx - 1.5 * sc, gy - 3.75 * sc), P(cx - 1.15 * sc, gy - 4.0 * sc), P(cx, gy - 4.09 * sc), P(cx + 1.15 * sc, gy - 4.0 * sc), P(cx + 1.5 * sc, gy - 3.75 * sc), P(cx + 1.5 * sc, gy - 1.2 * sc)]), HULL)
	draw_rect(R(cx - 1.38 * sc, gy - 3.7 * sc, 2.76 * sc, 2.2 * sc), Color(0.95, 0.78, 0.45, 0.3))
	draw_rect(R(cx - 1.5 * sc, gy - 2.32 * sc, 3.0 * sc, maxf(2.0, 0.12 * sc)), C_AMBER)
	draw_rect(R(cx - 1.5 * sc, gy - 1.5 * sc, 3.0 * sc, 2), C_WARM)
	for sd2: float in [-1.0, 1.0]:
		draw_rect(R(cx + sd2 * 1.44 * sc - 0.07 * sc, gy - 3.55 * sc, 0.14 * sc, 2.05 * sc), Color(0.95, 0.78, 0.45, 0.6))
	if platform:
		draw_rect(R(cx + 1.62 * sc, gy - 1.5 * sc, 2.68 * sc, 1.5 * sc), Color(0.3, 0.31, 0.33))
		draw_rect(R(cx + 1.62 * sc, gy - 1.5 * sc, 2.68 * sc, 3), C_WARM)
	for sd3: float in [-1.0, 1.0]:
		if platform:
			continue
		var a := Vector2(cx + sd3 * 1.5 * sc, gy - 1.5 * sc)
		var b := Vector2(cx + sd3 * 3.45 * sc, gy - 0.05 * sc)
		draw_line(org + a, org + b, C_AMBER, 3.0)
		draw_line(org + a + Vector2(0, -0.9 * sc), org + b + Vector2(0, -0.9 * sc), C_DIM, 1.5)
		draw_line(org + b, org + b + Vector2(0, -0.9 * sc), C_DIM, 1.5)
		for q in 5:
			var sp: Vector2 = a.lerp(b, (float(q) + 0.5) / 5.0)
			draw_line(org + sp, org + sp + Vector2(sd3 * 0.3 * sc, 0), C_AMBER, 2.0)

func _p_doors() -> void:
	head("DOORS & BOARDING", "GETTING ON AND OFF  -  AT A PLATFORM OR ON THE OPEN LINE")
	var sc := 31.0
	var gy := 282.0
	panel(0, 62, 236, 268)
	tx(10, 80, "AT A PLATFORM", 11, C_AMBER)
	_xsec(84, gy, sc, true)
	_person(84 + 2.95 * sc + sin(t * 1.5) * 8.0, gy - 1.5 * sc, sc * 0.9, C_WARM)
	arrow(Vector2(84 + 2.4 * sc, gy - 2.5 * sc), Vector2(84 + 1.2 * sc, gy - 2.5 * sc), C_GOOD)
	para(10, 300, "The floor is level with the platform: walk straight in. The far side has steps.", 216, 9, C_DIM)
	panel(246, 62, 256, 268)
	tx(256, 80, "ON THE OPEN LINE", 11, C_AMBER)
	var cx := 368.0
	_xsec(cx, gy, sc, false)
	var u: float = clampf(fmod(t * 0.55, 1.5), 0.0, 1.0)
	var p0 := Vector2(cx + 4.0 * sc, gy)
	var p1 := Vector2(cx + 3.0 * sc, gy - 3.7 * sc)
	var p2 := Vector2(cx + 0.9 * sc, gy - 1.5 * sc)
	var prev: Vector2 = p0
	for i in range(1, 17):
		var q2: float = float(i) / 16.0
		var pt: Vector2 = p0.lerp(p1, q2).lerp(p1.lerp(p2, q2), q2)
		if i % 2 == 0:
			draw_line(org + prev, org + pt, C_GOOD, 1.5)
		prev = pt
	var pp: Vector2 = p0.lerp(p1, u).lerp(p1.lerp(p2, u), u)
	_person(pp.x, pp.y, sc * 0.9, C_GOOD)
	_person(cx - 2.5 * sc, gy - 0.78 * sc, sc * 0.9, C_WARM)
	para(256, 300, "Steps fold out on both sides. Walk up them, or jump beside the door and be carried in.", 236, 9, C_DIM)
	panel(512, 62, 258, 268)
	var stopped: bool = float(GS.train["speed"]) < 0.3
	draw_circle(P(530, 84), 7.0, C_GOOD if stopped else Color(0.2, 0.3, 0.2))
	tx(546, 88, "TRAIN STOPPED", 12, C_GOOD)
	para(524, 106, "Doors open on command, anywhere. No platform needed.", 236, 10, C_DIM)
	draw_circle(P(530, 146), 7.0, C_RED if not stopped else Color(0.3, 0.16, 0.14))
	tx(546, 150, "TRAIN MOVING", 12, C_RED)
	para(524, 168, "Doors stay locked until it is at a stand.", 236, 10, C_DIM)
	tx(650, 88, "NOW" if stopped else "", 9, C_GOOD, AR, 108)
	tx(650, 150, "" if stopped else "NOW", 9, C_RED, AR, 108)
	draw_rect(R(524, 190, 234, 1), C_LINE)
	tx(524, 210, "THREE WAYS TO WORK THEM", 10, C_AMBER)
	var kx: float = 524.0 + key(524, 220, kn("doors"), C_GOOD)
	para(kx + 2, 234, "aboard, or within a few metres outside", 236.0 - (kx - 524.0), 10, C_DIM)
	kx = 524.0 + key(524, 252, kn("interact"), C_GOOD)
	tx(kx + 2, 266, "while looking at a door", 10, C_DIM)
	draw_rect(R(524, 284, 46, 20), Color(0.2, 0.21, 0.23))
	tx(524, 298, "DOOR", 10, C_WARM, AC, 46)
	tx(578, 298, "switch on the driver's desk", 10, C_DIM)
	tx(524, 322, "A lamp on each door flashes while they are open.", 9, C_DIM)
	var tips: Array = [["CLIMB ABOARD", "Jump beside any open door. The jump is sized to land you on the vestibule floor.", "jump"], ["CLOSED DOORS", "Jump at them anyway: they open, the steps drop, and you are carried in.", "jump"], ["STILL ROLLING", "Jump beside a door and wait. You are pulled aboard the moment the train stops.", "jump"], ["THEN CLOSE THEM", "Open doors bleed heat, cut traction power and let the infected walk in.", "doors"]]
	for i in 4:
		var tp: Array = tips[i]
		var x: float = float(i) * 194.5
		panel(x, 340, 187, 98)
		tx(x + 10, 358, str(tp[0]), 11, C_WARM)
		var lab: String = kn(str(tp[2]))
		key(x + 177.0 - maxf(22.0, tw(lab, 11) + 12.0), 344, lab, C_GOOD)
		para(x + 10, 378, str(tp[1]), 167, 10, C_DIM)

# ---------------- 06 power and fuel ----------------
func _p_power() -> void:
	head("POWER & FUEL", "WHERE THE ELECTRICITY COMES FROM AND WHERE IT GOES  -  LIVE")
	var tr: Dictionary = GS.train
	var eng: bool = tr["engine_on"]
	var has_gen: bool = GS.has_car("generator")
	var gen_on: bool = has_gen and tr["gen_on"] and float(tr["diesel"]) > 0.0
	var net: float = GS.kw_gen - GS.kw_load
	var nv: float = float(GS.cars.size() + 1)
	panel(0, 66, 150, 84, C_AMBER)
	ico("diesel", 20, 86, 16.0)
	tx(36, 90, "DIESEL TANK", 11, C_WARM)
	tx(12, 114, "%d / 1200 L" % int(tr["diesel"]), 14, C_RED if float(tr["diesel"]) < 80.0 else C_WARM)
	bar(12, 124, 126, 8, float(tr["diesel"]) / 1200.0, C_AMBER)
	panel(200, 66, 170, 84, C_GOOD if eng else NONE)
	tx(212, 86, "LOCOMOTIVE ENGINE", 11, C_WARM)
	tx(212, 108, ("RUNNING  +%d kW" % int(42.0 * float(GS.loco["engine"]) / 100.0)) if eng else "STOPPED", 13, C_GOOD if eng else C_DIM)
	tx(212, 126, "Burns 4 L/h idling, 28 L/h flat out", 9, C_DIM)
	tx(212, 140, "Output falls with engine damage", 9, C_DIM)
	panel(200, 176, 170, 70, C_GOOD if gen_on else NONE)
	tx(212, 196, "GENERATOR CARRIAGE", 11, C_WARM if has_gen else C_DIM)
	tx(212, 216, ("RUNNING  +30 kW" if gen_on else "SWITCHED OFF") if has_gen else "NOT COUPLED YET", 12, C_GOOD if gen_on else C_DIM)
	tx(212, 234, "Burns 3 L/h. Found at stop 4.", 9, C_DIM)
	flow(Vector2(150, 108), Vector2(198, 108), C_AMBER, eng)
	draw_line(P(75, 150), P(75, 211), Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.3 if gen_on else 0.14), 3.0)
	flow(Vector2(75, 211), Vector2(198, 211), C_AMBER, gen_on)
	var bus: Color = C_GOOD if GS.power_ok else C_RED
	draw_rect(R(416, 66, 6, 182), Color(bus.r, bus.g, bus.b, 0.8))
	tx(392, 262, "TRAIN LINE", 8, C_DIM, AC, 54)
	flow(Vector2(370, 108), Vector2(414, 108), C_GOOD, eng)
	flow(Vector2(370, 211), Vector2(414, 211), C_GOOD, gen_on)
	panel(470, 66, 160, 74, C_BLUE)
	ico("battery", 490, 86, 16.0, C_BLUE)
	tx(506, 90, "BATTERY BANK", 11, C_WARM)
	tx(482, 112, "%d / %d kWh" % [int(tr["battery"]), int(GS.bat_cap())], 13, C_WARM)
	bar(482, 122, 136, 8, float(tr["battery"]) / GS.bat_cap(), C_BLUE)
	if net >= 0.0:
		flow(Vector2(422, 96), Vector2(468, 96), C_BLUE, net > 0.05)
	else:
		flow(Vector2(468, 96), Vector2(424, 96), C_BLUE, float(tr["battery"]) > 0.0)
	var heat_kw: float = 3.2 * nv * clampf((18.0 - GS.t_out) / 35.0, 0.3, 1.3) * (0.7 if int(GS.upgrades.get("insulation", 0)) > 0 else 1.0)
	var special := 0.0
	for c: Dictionary in GS.cars:
		special += float({"medical": 3.0, "kitchen": 4.0, "greenhouse": 6.0, "water": 5.0, "workshop": 3.0, "security": 2.0, "storage": 1.0}.get(c["type"], 0.0))
	var loads: Array = [["LIGHTING", 1.5 * nv, tr["lights"], "1.5 kW per vehicle"], ["HEATING", heat_kw, tr["heating"], "more when colder"], ["VENTILATION", 1.0 * nv, tr["vent"], "1 kW per vehicle"], ["EQUIPMENT", special, true, "1 to 6 kW a carriage"]]
	for i in 4:
		var l: Array = loads[i]
		var y: float = 152.0 + float(i) * 25.0
		var on: bool = l[2]
		var kw: float = float(l[1]) if on else 0.0
		flow(Vector2(422, y + 9), Vector2(468, y + 9), C_WARM, on and GS.power_ok and kw > 0.0)
		draw_rect(R(470, y, 160, 21), C_PAN)
		draw_rect(R(470, y, 160, 21), C_LINE, false, 1.0)
		tx(478, y + 10, str(l[0]), 9, C_WARM if on else C_DIM)
		tx(478, y + 19, str(l[3]), 7, C_DIM)
		tx(560, y + 15, ("%.1f kW" % kw) if on else "OFF", 11, C_AMBER if on else C_DIM, AR, 64)
	panel(644, 66, 126, 186, C_RED if not GS.power_ok else NONE)
	tx(654, 84, "BALANCE", 10, C_AMBER)
	tx(654, 106, "%+.1f kW" % net, 18, C_GOOD if net >= 0.0 else C_RED)
	tx(654, 122, "CHARGING" if net >= 0.0 else "DRAINING", 9, C_GOOD if net >= 0.0 else C_RED)
	if net < 0.0:
		tx(654, 138, "DARK IN %.1f H" % (float(tr["battery"]) / maxf(0.1, -net)), 10, C_AMBER)
	tx(654, 160, "WHEN IT IS FLAT", 9, C_RED)
	para(654, 174, "Red emergency lights only. Heating and ventilation stop. Food spoils five times faster. Greenhouse and water plant stop.", 110, 9, C_DIM)
	var cards: Array = [["diesel", "DIESEL CANS", "Every can in the train stores is poured into the tank by itself: +10 litres each."], ["battery", "BATTERY CELLS", "Each cell kept in the train stores adds 15 kWh to the bank. Craft them in the Workshop."], ["warmth", "SWITCH THINGS OFF", "%s, Overview tab: heating, ventilation, interior lights. Headlights draw 1.2 kW." % kn("manage")], ["tools", "UPGRADES AND CREW", "Engine overhaul: diesel -25%. Insulation: heating -30%. Bank expansion: +60 kWh. Power duty: load -10%."]]
	tx(0, 284, "MAKE MORE, BURN LESS", 10, C_AMBER)
	for i in 4:
		var cd: Array = cards[i]
		var x: float = float(i) * 194.5
		panel(x, 292, 187, 146)
		ico(str(cd[0]), x + 20, 312, 16.0)
		tx(x + 36, 316, str(cd[1]), 11, C_WARM)
		para(x + 10, 340, str(cd[2]), 167, 10, C_DIM)

# ---------------- 07 staying alive ----------------
func _p_alive() -> void:
	head("STAYING ALIVE", "YOUR OWN BODY, AND THE AIR YOU ALL SHARE")
	var p: Dictionary = GS.player
	var tr: Dictionary = GS.train
	var rows: Array = [
		["health", "HEALTH", float(p["health"]), "Lost to bites, bullets, cold, hunger, bleeding. Returns when you are fed, watered and warm. Medical Supplies: +30 and stops bleeding."],
		["food", "FOOD", 100.0 - float(p["hunger"]), "Aboard, you eat from the train stores by yourself. Away from the train: %s, USE. A hot Kitchen meal fills you most." % kn("inventory")],
		["water", "WATER", 100.0 - float(p["thirst"]), "Same as food. Runs down faster. The Water carriage has a tap."],
		["warmth", "WARMTH", 100.0 - float(p["cold"]), "Drains outdoors and in an unheated train, below 6 C. Get into a heated carriage."],
		["rest", "REST", 100.0 - float(p["fatigue"]), "Under 15 you slow down. Crew bunk behind the cab: sleep, train stopped. Passenger seat: rest one hour."],
	]
	for i in 5:
		var r: Array = rows[i]
		var y: float = 66.0 + float(i) * 64.0
		var val: float = r[2]
		var col: Color = C_RED if val < 25.0 else (C_AMBER if val < 50.0 else C_GOOD)
		ring(26, y + 26, 20.0, val / 100.0, col, str(r[0]))
		tx(58, y + 16, str(r[1]), 12, C_WARM)
		tx(150, y + 16, "%d %%" % int(val), 12, col)
		para(58, y + 31, str(r[3]), 320, 10, C_DIM)
	tx(0, 398, "RED CHIPS BY YOUR HEALTH BAR", 10, C_AMBER)
	var chips: Array = [["BLEEDING", C_RED, "use Medical Supplies"], ["HYPOTHERMIA", C_BLUE, "get indoors"], ["EXHAUSTED", C_AMBER, "sleep"], ["OVERBURDENED", C_AMBER, "store your load"]]
	var cx := 0.0
	for ch: Array in chips:
		var cc: Color = ch[1]
		var w: float = tw(str(ch[0]), 9) + 14.0
		draw_rect(R(cx, 406, w, 16), C_PAN)
		draw_rect(R(cx, 406, 3, 16), cc)
		tx(cx + 8, 418, str(ch[0]), 9, cc)
		tx(cx, 434, str(ch[2]), 8, C_DIM)
		cx += maxf(w, tw(str(ch[2]), 8)) + 14.0
	# the train's climate
	panel(400, 62, 370, 226)
	tx(410, 80, "INSIDE THE TRAIN", 11, C_AMBER)
	var ty0 := 96.0
	var ty1 := 276.0
	var tmap := func(c: float) -> float:
		return lerpf(ty1, ty0, clampf((c + 30.0) / 55.0, 0.0, 1.0))
	var y8: float = tmap.call(8.0)
	var y2: float = tmap.call(2.0)
	draw_rect(R(430, ty0, 16, y8 - ty0), Color(C_GOOD.r, C_GOOD.g, C_GOOD.b, 0.7))
	draw_rect(R(430, y8, 16, y2 - y8), Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.8))
	draw_rect(R(430, y2, 16, ty1 - y2), Color(C_RED.r, C_RED.g, C_RED.b, 0.8))
	draw_rect(R(430, ty0, 16, ty1 - ty0), C_LINE, false, 1.0)
	var marks: Array = [[20.0, "20 C  heating holds it here"], [8.0, "8 C  morale drops, people fall ill"], [2.0, "2 C  the crew start losing health"], [-15.0, "-15 C  a typical night outside"]]
	for m: Array in marks:
		var my: float = tmap.call(float(m[0]))
		draw_line(P(446, my), P(456, my), C_DIM, 1.0)
		tx(460, my + 4, str(m[1]), 9, C_DIM)
	var yi: float = tmap.call(float(tr["temp"]))
	var yo: float = tmap.call(GS.t_out)
	draw_colored_polygon(PackedVector2Array([P(428, yi), P(416, yi - 6), P(416, yi + 6)]), C_WARM)
	draw_colored_polygon(PackedVector2Array([P(428, yo), P(416, yo - 6), P(416, yo + 6)]), C_BLUE)
	tx(640, 110, "ABOARD", 9, C_WARM)
	tx(640, 130, "%d C" % int(round(float(tr["temp"]))), 18, C_WARM)
	tx(640, 156, "OUTSIDE", 9, C_BLUE)
	tx(640, 176, "%d C" % int(round(GS.t_out)), 18, C_BLUE)
	para(640, 200, "Open doors and a damaged hull let the cold in.", 122, 9, C_DIM)
	var gauges: Array = [["AIR QUALITY", float(tr["air"]), 40.0, "Ventilation with power raises it. So do open doors. Under 40%: illness."], ["SANITATION", float(tr["sanitation"]), 30.0, "Falls with every person aboard. Sanitation duty and the Water carriage raise it."]]
	for i in 2:
		var g: Array = gauges[i]
		var gy: float = 300.0 + float(i) * 46.0
		var gv: float = g[1]
		var lim: float = g[2]
		tx(400, gy + 10, str(g[0]), 10, C_WARM)
		bar(500, gy + 2, 200, 9, gv / 100.0, C_RED if gv < lim else C_GOOD)
		draw_rect(R(500.0 + 2.0 * lim, gy - 1, 2, 15), C_WARM)
		tx(708, gy + 11, "%d %%" % int(gv), 11, C_RED if gv < lim else C_WARM)
		para(400, gy + 26, str(g[3]), 370, 9, C_DIM)
	var ration: float = tr["ration"]
	var cook: float = 0.75 if GS.staffed("Cooking") > 0.0 else 1.0
	var per_day: float = maxf(0.1, float(GS.crew.size()) * 0.11 * 24.0 * ration * cook)
	ico("food", 410, 408, 14.0)
	tx(424, 412, "2.6 tins and 3.4 litres per survivor per day.", 10, C_DIM)
	tx(424, 428, "FOOD LEFT:  %.1f DAYS" % (float(GS.count(GS.store, "food")) / per_day), 11, C_WARM)
	tx(600, 428, "Half rations: %s, Overview" % kn("manage"), 9, C_DIM)

# ---------------- 08 crew and duties ----------------
func _p_crew() -> void:
	head("CREW & DUTIES", "WHO DOES WHAT BEST  -  ASSIGN THEM WITH %s OR BY TALKING TO THEM" % kn("manage"))
	var profs: Array = ["Mechanic", "Doctor", "Nurse", "Engineer", "Cook", "Farmer", "Electrician", "Security"]
	var duties: Array = GS.ASSIGN.keys()
	var have: Dictionary = {}
	var on_duty: Dictionary = {}
	for c: Dictionary in GS.crew:
		have[c["job"]] = int(have.get(c["job"], 0)) + 1
		on_duty[c["assign"]] = int(on_duty.get(c["assign"], 0)) + 1
	tx(0, 70, "PROFESSION", 9, C_AMBER)
	tx(300, 70, "DUTY", 9, C_AMBER)
	for di in duties.size():
		var dn: String = duties[di]
		var info: Dictionary = GS.ASSIGN[dn]
		var y: float = 76.0 + float(di) * 29.5
		var jobs: Array = info["jobs"]
		for j: String in jobs:
			var pi: int = profs.find(j)
			if pi >= 0:
				var py: float = 89.0 + float(pi) * 33.0
				var lit: bool = have.has(j)
				draw_line(P(132, py), P(296, y + 13), Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.9 if lit else 0.3), 2.0 if lit else 1.0, true)
		draw_rect(R(298, y, 472, 26), C_PAN)
		draw_rect(R(298, y, 472, 26), C_LINE, false, 1.0)
		var cnt: int = int(on_duty.get(dn, 0))
		tx(306, y + 17, dn.to_upper(), 11, C_WARM if cnt > 0 else C_DIM)
		for k in mini(cnt, 5):
			draw_circle(P(392.0 + float(k) * 9.0, y + 13), 3.5, C_GOOD)
		var need: String = info["car"]
		var dx := 444.0
		if need != "":
			var ok: bool = GS.has_car(need)
			var lab: String = "NEEDS " + str(TrainRig.TYPE_LABEL[need])
			tx(444, y + 11, lab, 8, C_GOOD if ok else C_RED)
			tx(444, y + 22, _duty_text(dn), 8, C_DIM)
		else:
			tx(dx, y + 16, _duty_text(dn), 9, C_DIM)
	for pi2 in profs.size():
		var pn: String = profs[pi2]
		var py2: float = 76.0 + float(pi2) * 33.0
		var n: int = int(have.get(pn, 0))
		draw_rect(R(0, py2, 132, 26), Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.18) if n > 0 else C_PAN)
		draw_rect(R(0, py2, 132, 26), C_AMBER if n > 0 else C_LINE, false, 1.0)
		ico("crew", 14, py2 + 13, 12.0, C_AMBER if n > 0 else C_DIM)
		tx(28, py2 + 17, pn.to_upper(), 10, C_WARM if n > 0 else C_DIM)
		if n > 0:
			tx(96, py2 + 17, "x%d" % n, 10, C_AMBER, AR, 30)
	tx(140, 356, "A matched profession works 50% better.", 9, C_DIM)
	var blocks: Array = [[C_GOOD, "MORALE RISES", "Hot meals from a cook. Friends aboard. Reaching a stop. A new carriage. Talking to them."], [C_RED, "MORALE FALLS", "Hunger and thirst. Cold below 8 C. Darkness. Bad air and filth. Attacks. Half rations. Deaths."], [C_AMBER, "TRUST", "Talk with %s: ask after them, hand over food, treat a wound, stand them down. Trust adds up to 15%% output." % kn("interact")]]
	for i in 3:
		var b: Array = blocks[i]
		var bc: Color = b[0]
		var x: float = float(i) * 259.5
		panel(x, 364, 251, 76, bc)
		if i == 0:
			draw_colored_polygon(PackedVector2Array([P(x + 18, 374), P(x + 11, 386), P(x + 25, 386)]), bc)
		elif i == 1:
			draw_colored_polygon(PackedVector2Array([P(x + 18, 386), P(x + 11, 374), P(x + 25, 374)]), bc)
		else:
			ico("crew", x + 18, 380, 13.0, bc)
		tx(x + 32, 385, str(b[1]), 11, C_WARM)
		para(x + 10, 402, str(b[2]), 232, 9, C_DIM)

func _duty_text(dn: String) -> String:
	match dn:
		"Idle": return "Rests and keeps the others company."
		"Repairs": return "Mends the worst system. Uses materials slowly."
		"Cooking": return "Food use -25%, morale up."
		"Medical": return "Treats the sick. Uses medical supplies."
		"Farming": return "Grows food while power is on."
		"Water": return "Purifies water while power is on."
		"Power": return "Load -10%, generator output +30%."
		"Guard": return "Shoots attackers. Uses 9 mm from stores."
	return "Keeps the carriages clean."

# ---------------- 09 repairs ----------------
func _p_repairs() -> void:
	head("REPAIRS", "WHAT WEARS OUT, WHAT IT COSTS YOU, AND FOUR WAYS TO MEND IT")
	var sys: Array = [["ENGINE", "engine", "Top speed and alternator output.", "Wears under power and in collisions."], ["BRAKES", "brakes", "How quickly the train stops.", "Wear with every brake application."], ["ELECTRICAL", "electrical", "Wiring losses added to every load.", "Relays burn out at random."], ["HULL", "hull", "Keeps the heat in when power fails.", "Attacks, snowstorms, collisions."]]
	for i in 4:
		var s: Array = sys[i]
		var x: float = float(i) * 194.5
		var v: float = GS.loco[s[1]]
		var col: Color = C_RED if v < 35.0 else (C_AMBER if v < 70.0 else C_GOOD)
		panel(x, 62, 187, 96, col)
		tx(x + 12, 80, str(s[0]), 12, C_WARM)
		tx(x + 127, 80, "%d %%" % int(v), 12, col, AR, 50)
		bar(x + 12, 88, 165, 8, v / 100.0, col)
		para(x + 12, 112, str(s[2]), 165, 10, C_WARM)
		para(x + 12, 140, str(s[3]), 165, 9, C_DIM)
	tx(0, 178, "EVERY CARRIAGE ALSO HAS ITS OWN HULL AND SYSTEMS  -  SEE THE TRAIN, PAGE 1", 9, C_DIM)
	var ways: Array = [
		["SERVICE PANEL", "Vestibule wall of every carriage. Fixes the worse half of that carriage.", "interact"],
		["ENGINE ROOM", "Gangway beside the engine. Fixes the worst locomotive system.", "interact"],
		["MANAGEMENT", "Carriages & Repairs tab: choose any system on the train.", "manage"],
		["CREW ON REPAIRS", "A Mechanic or Engineer mends the worst system all day, using materials slowly.", "manage"],
	]
	for i in 4:
		var w: Array = ways[i]
		var x: float = float(i) * 194.5
		panel(x, 188, 187, 112)
		num(x + 18, 206, i + 1)
		tx(x + 34, 210, str(w[0]), 11, C_WARM)
		var lab: String = kn(str(w[2]))
		key(x + 177.0 - maxf(22.0, tw(lab, 11) + 12.0), 272, lab)
		para(x + 10, 232, str(w[1]), 167, 10, C_DIM)
	panel(0, 310, 770, 128)
	tx(12, 328, "ONE REPAIR", 10, C_AMBER)
	ico("parts", 40, 366, 26.0)
	tx(58, 372, "x2", 16, C_WARM)
	tx(14, 398, "REPAIR MATERIALS", 9, C_DIM)
	tx(98, 372, "+", 18, C_DIM)
	ico("tools", 140, 366, 26.0)
	tx(118, 398, "TOOL KIT", 9, C_DIM)
	tx(118, 410, "never used up", 8, C_GOOD)
	arrow(Vector2(190, 366), Vector2(246, 366), C_AMBER, 3.0)
	tx(258, 376, "+22 %", 26, C_GOOD)
	tx(258, 398, "TO ONE SYSTEM", 9, C_DIM)
	var bonus: Array = [["+8 %", "with a Workshop carriage", GS.has_car("workshop")], ["+18 %", "at most, with crew on Repairs", GS.staffed("Repairs") > 0.0]]
	for i in 2:
		var b: Array = bonus[i]
		var on: bool = b[2]
		tx(372, 350.0 + float(i) * 26.0, str(b[0]), 14, C_GOOD if on else C_DIM)
		tx(424, 350.0 + float(i) * 26.0, str(b[1]), 10, C_WARM if on else C_DIM)
		if on:
			tick(600, 346.0 + float(i) * 26.0, C_GOOD)
	draw_rect(R(372, 392, 386, 1), C_LINE)
	ico("scrap", 384, 410, 14.0)
	tx(398, 414, "No materials? Workbench: 3 Scrap Metal makes 2.", 10, C_DIM)
	tx(372, 430, "A Tool Kit and 2 materials also couple a carriage. A Tool Kit clears a blocked line.", 9, C_DIM)

# ---------------- 10 scavenging ----------------
func _p_scav() -> void:
	head("SCAVENGING", "WHAT EACH STOP HOLDS  -  SUPPLY SURVEY OF THE NORTHERN LINE")
	for i in ITEMS.size():
		ico(str(ITEMS[i]), 204.0 + float(i) * 29.0, 76, 14.0, C_AMBER)
	tx(586, 80, "CARRIAGE", 9, C_AMBER)
	tx(676, 80, "WEAPON CASE", 9, C_AMBER)
	var s: float = GS.train["s"]
	var k: int = int(round(s / GS.SP))
	var here: int = posmod(k, GS.NLOC) if absf(s - float(k) * GS.SP) < 30.0 else -1
	for r in GS.NLOC:
		var L: Dictionary = GS.LOCS[r]
		var y: float = 92.0 + float(r) * 24.5
		if r == here:
			draw_rect(R(0, y, PW, 23), Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.16))
			draw_rect(R(0, y, 3, 23), C_AMBER)
		elif r % 2 == 0:
			draw_rect(R(0, y, PW, 23), Color(1, 1, 1, 0.025))
		var known: bool = GS.discovered.has(str(r))
		tx(8, y + 16, "%d" % (r + 1), 10, C_AMBER if known else C_DIM)
		tx(26, y + 16, str(L["name"]), 10, C_WARM if known else C_DIM)
		var loot: Array = L["loot"]
		for i in ITEMS.size():
			var cx: float = 204.0 + float(i) * 29.0
			if loot.has(ITEMS[i]):
				var cnt: int = loot.count(ITEMS[i])
				draw_circle(P(cx, y + 11.5), 4.0 + float(mini(cnt, 3)), C_AMBER)
			else:
				draw_circle(P(cx, y + 11.5), 1.5, Color(0.3, 0.31, 0.33))
		var car: String = L["car"]
		if car != "":
			var got: bool = GS.coupled.has(str(r))
			tx(586, y + 16, str(TrainRig.TYPE_LABEL[car]), 8, C_GOOD if got else C_WARM)
		var wc: Array = WorldRig.WCASES[r]
		if wc.size() > 0:
			var wid: String = wc[0]
			tx(676, y + 16, str(Arsenal.DEFS[wid]["name"]), 8, C_GOOD if GS.weapons.has(wid) else C_WARM)
	tx(0, 350, "Bigger dot: more likely. Green: already yours. Everything is restocked on the next lap of the line.", 9, C_DIM)
	panel(0, 358, 250, 82)
	var a: float = t * 1.5
	draw_colored_polygon(PackedVector2Array([P(24 + cos(a) * 10.0, 384 + sin(a) * 10.0), P(24 - sin(a) * 10.0, 384 + cos(a) * 10.0), P(24 - cos(a) * 10.0, 384 - sin(a) * 10.0), P(24 + sin(a) * 10.0, 384 - cos(a) * 10.0)]), C_AMBER)
	tx(44, 378, "AMBER TAG", 11, C_WARM)
	para(44, 392, "Marks a container nobody has searched. Look at it, press %s." % kn("interact"), 198, 9, C_DIM)
	panel(260, 358, 250, 82)
	var wgt: float = GS.weight(GS.inv)
	tx(270, 378, "YOUR PACK  %.1f / %d KG" % [wgt, int(GS.inv_cap())], 11, C_WARM)
	bar(270, 384, 230, 7, wgt / GS.inv_cap(), C_RED if wgt > GS.inv_cap() else C_AMBER)
	para(270, 406, "Full packs find nothing. Board, %s, STORE EVERYTHING." % kn("inventory"), 232, 9, C_DIM)
	panel(520, 358, 250, 82)
	tx(530, 378, "BETWEEN THE STATIONS", 11, C_WARM)
	para(530, 392, "Stop anywhere, %s, climb down. Crossings, villages, the bridge, tunnels, wagons, the mast and the cutting all hold salvage." % kn("doors"), 232, 9, C_DIM)

# ---------------- 11 weapons ----------------
func _gun(id: String, x: float, y: float, w: float, h: float, col: Color) -> void:
	var shapes: Array = GUNS.get(id, [])
	for sh: Array in shapes:
		draw_rect(R(x + float(sh[0]) * w, y + float(sh[1]) * h, float(sh[2]) * w, float(sh[3]) * h), col)

func _p_weapons() -> void:
	head("WEAPONS", "%d WEAPONS  -  CASES AT THE STOPS AND IN THE COUNTRY BETWEEN THEM" % Arsenal.ORDER.size())
	var first: int = page * 10
	for i in mini(10, Arsenal.ORDER.size() - first):
		var id: String = Arsenal.ORDER[first + i]
		var d: Dictionary = Arsenal.DEFS[id]
		var x: float = float(i % 5) * 155.5
		var y: float = 62.0 + float(i / 5) * 174.0
		var own: bool = GS.weapons.has(id)
		panel(x, y, 148, 167, C_GOOD if own else NONE)
		_gun(id, x + 8, y + 2, 132, 56, C_WARM if own else Color(0.5, 0.52, 0.55))
		tx(x + 10, y + 70, str(d["name"]), 11, C_WARM)
		tx(x + 10, y + 82, str(d["cat"]), 8, C_AMBER)
		var stats: Array = [["DAMAGE", float(d["dmg"]) * float(d["pellets"]) / 9.0], ["RATE", (1.0 / float(d["rate"])) / 15.0], ["MAGAZINE", sqrt(float(d["mag"]) / 100.0)]]
		for si in 3:
			var st: Array = stats[si]
			tx(x + 10, y + 97.0 + float(si) * 12.0, str(st[0]), 7, C_DIM)
			bar(x + 58, y + 91.0 + float(si) * 12.0, 80, 6, float(st[1]), C_AMBER)
		var it: Dictionary = GS.ITEMS[d["ammo"]]
		ico(str(d["ammo"]), x + 16, y + 136, 11.0)
		if d.has("per"):
			tx(x + 28, y + 140, "%d shots per %s" % [int(d["per"]), it["name"]], 8, C_WARM)
		else:
			tx(x + 28, y + 140, "%d x %s" % [int(d["mag"]), it["name"]], 8, C_WARM)
		var where: String = str(LINESIDE.get(id, "ISSUED TO YOU"))
		for li in WorldRig.WCASES.size():
			var wc: Array = WorldRig.WCASES[li]
			if wc.size() > 0 and str(wc[0]) == id:
				where = "CASE: " + str(GS.LOCS[li]["name"]).to_upper()
		tx(x + 10, y + 156, where, 7, C_GOOD if own else C_DIM)
		if own:
			tick(x + 134, y + 14, C_GOOD)
	var kx := 0.0
	var ctl: Array = [["LEFT CLICK", "fire"], ["RIGHT CLICK", "aim"], [kn("reload"), "reload"], [kn("inspect"), "inspect"], [kn("swap"), "next"], ["1 - 0", "pick"]]
	for c: Array in ctl:
		kx += key(kx, 412, str(c[0]), C_RED)
		tx(kx, 426, str(c[1]), 10, C_DIM)
		kx += tw(str(c[1]), 10) + 16.0

# ---------------- 12 threats ----------------
func _p_threats() -> void:
	head("THREATS", "HOW THE INFECTED FIND YOU  -  AND HOW NOT TO BE FOUND")
	var c := Vector2(160, 250)
	var sc := 5.0
	var rings: Array = [[31.0, Color(0.5, 0.12, 0.1, 0.5), "31 m  SPRINTING WITH THE FLASHLIGHT ON"], [22.0, Color(0.84, 0.34, 0.27, 0.45), "22 m  SPRINTING, OR FLASHLIGHT ON"], [13.0, Color(0.88, 0.66, 0.26, 0.5), "13 m  WALKING"], [7.0, Color(0.6, 0.8, 0.62, 0.6), "7 m  CROUCHED"]]
	for i in rings.size():
		var r: Array = rings[i]
		var rc: Color = r[1]
		draw_circle(org + c, float(r[0]) * sc, rc)
		draw_arc(org + c, float(r[0]) * sc, 0.0, TAU, 48, Color(rc.r, rc.g, rc.b, 1.0), 1.0, true)
	var pr: float = fmod(t * 30.0, 155.0)
	draw_arc(org + c, pr, 0.0, TAU, 48, Color(1, 1, 1, 0.5 * (1.0 - pr / 155.0)), 1.5, true)
	_person(c.x, c.y + 9.0, 11.0, C_WARM)
	for i in 3:
		var a: float = t * 0.2 + float(i) * 2.1
		var rr: float = 150.0 - 22.0 * float(i) + sin(t * 0.7 + float(i)) * 8.0
		_person(c.x + cos(a) * rr, c.y + sin(a) * rr * 0.9 + 9.0, 10.0, C_RED)
	tx(0, 70, "THEY NOTICE YOU INSIDE THE RING", 9, C_AMBER)
	var legend: Array = [[C_GOOD, "CROUCHED  7 m"], [C_RED, "SPRINT OR FLASHLIGHT  22 m"], [C_AMBER, "WALKING  13 m"], [Color(0.6, 0.16, 0.13), "BOTH AT ONCE  31 m"]]
	for i in 4:
		var l: Array = legend[i]
		var lc: Color = l[0]
		draw_rect(R(float(i % 2) * 120.0, 412.0 + float(i / 2) * 14.0, 9, 9), lc)
		tx(float(i % 2) * 120.0 + 14.0, 421.0 + float(i / 2) * 14.0, str(l[1]), 9, C_DIM)
	tx(350, 70, "NOISE CARRIES  -  WHO HEARS WHAT YOU DO", 9, C_AMBER)
	var noise: Array = [["Searching a container", 8.0], ["Sprinting footsteps", 14.0], ["Sable DMR-8, Riveter", 20.0], ["Opening the doors", 20.0], ["Starting the engine", 45.0], ["Arclight", 50.0], ["Stryk-9, Vesper", 55.0], ["Pistol", 60.0], ["Carbine and rifle", 65.0], ["Shotgun", 70.0], ["Revolver", 75.0], ["Machine gun", 80.0], ["Northwind .338, the horn", 90.0]]
	for i in noise.size():
		var nz: Array = noise[i]
		var y: float = 78.0 + float(i) * 13.6
		var m: float = nz[1]
		tx(350, y + 9, str(nz[0]), 9, C_DIM)
		draw_rect(R(500, y + 2, m / 90.0 * 226.0, 8), C_GOOD if m <= 20.0 else (C_AMBER if m <= 60.0 else C_RED))
		tx(500.0 + m / 90.0 * 226.0 + 5.0, y + 10, "%d m" % int(m), 8, C_WARM)
	panel(350, 262, 420, 178, C_RED if GS.under_attack > 0.0 else NONE)
	tx(360, 280, "A STOPPED TRAIN DRAWS THEM IN", 10, C_AMBER)
	var lit: Array = [["DARK", 16.0, not (GS.train["lights"] and GS.power_ok) and not GS.train["headlights"]], ["INTERIOR LIGHTS ON", 40.0, GS.train["lights"] and GS.power_ok and not GS.train["headlights"]], ["HEADLIGHTS ON", 70.0, GS.train["headlights"]]]
	for i in 3:
		var le: Array = lit[i]
		var y: float = 290.0 + float(i) * 20.0
		var now: bool = le[2]
		draw_rect(R(360, y + 3, 26, 9), HULL)
		draw_rect(R(360, y + 6, 26, 2), C_AMBER if i > 0 else Color(0.2, 0.2, 0.22))
		var m2: float = le[1]
		draw_rect(R(392, y + 4, m2 / 70.0 * 200.0, 7), Color(C_RED.r, C_RED.g, C_RED.b, 0.9 if now else 0.4))
		tx(392.0 + m2 / 70.0 * 200.0 + 6.0, y + 12, "%d m  %s" % [int(m2), le[0]], 9, C_WARM if now else C_DIM)
	para(360, 366, "They hammer on the hull. Through open doors they walk in and hurt the crew. A guard on Security duty shoots them with 9 mm from the stores. At speed, nothing can touch the train.", 400, 9, C_DIM)
	tx(360, 420, "FORT VARDA", 9, C_RED)
	tx(430, 420, "Soldiers fire on you within 36 m, and on any stopped train.", 9, C_DIM)
	tx(430, 432, "Take what you need and leave.", 9, C_DIM)

# ---------------- 13 workshop and trade ----------------
func _stack(x: float, y: float, d: Dictionary, col: Color) -> float:
	for k: String in d.keys():
		ico(k, x + 8, y, 13.0, col)
		tx(x + 17, y + 4, "x%d" % int(d[k]), 10, C_WARM if col == C_AMBER else C_DIM)
		x += 44.0
	return x

func _p_workshop() -> void:
	head("WORKSHOP & TRADE", "TURN WHAT YOU FIND INTO WHAT YOU NEED")
	tx(0, 72, "CRAFT", 10, C_AMBER)
	tx(60, 72, "Workbench, or %s then Crafting" % kn("manage"), 9, C_DIM)
	for i in GS.RECIPES.size():
		var r: Dictionary = GS.RECIPES[i]
		var y: float = 80.0 + float(i) * 50.0
		var need: String = r["car"]
		var ok: bool = GS.can_afford(r["cost"]) and (need == "" or GS.has_car(need))
		panel(0, y, 250, 44, C_GOOD if ok else NONE)
		var ex: float = _stack(10, y + 15, r["cost"], C_AMBER if ok else C_DIM)
		arrow(Vector2(ex, y + 15), Vector2(ex + 24.0, y + 15), C_AMBER if ok else C_DIM)
		_stack(ex + 32.0, y + 15, r["give"], C_AMBER if ok else C_DIM)
		tx(10, y + 37, ("NEEDS " + str(TrainRig.TYPE_LABEL[need]) + " CARRIAGE") if need != "" else "ANYWHERE ABOARD", 8, (C_GOOD if GS.has_car(need) else C_RED) if need != "" else C_DIM)
	tx(0, 344, "Costs come from your pack first, then the train stores.", 9, C_DIM)
	tx(0, 356, "What you make goes into the train stores.", 9, C_DIM)
	tx(260, 72, "UPGRADES", 10, C_AMBER)
	tx(340, 72, "fitted once, for good", 9, C_DIM)
	for i in GS.UPGRADES.size():
		var u: Dictionary = GS.UPGRADES[i]
		var y: float = 80.0 + float(i) * 58.0
		var lvl: int = int(GS.upgrades.get(u["id"], 0))
		var ok2: bool = GS.can_afford(u["cost"])
		panel(260, y, 250, 53, C_GOOD if lvl > 0 else NONE)
		tx(270, y + 14, str(u["name"]).to_upper(), 10, C_WARM)
		if lvl > 0:
			tick(496, y + 11, C_GOOD)
		tx(270, y + 26, str(u["desc"]), 9, C_DIM)
		_stack(270, y + 41, u["cost"], C_AMBER if (ok2 or lvl > 0) else C_DIM)
	tx(520, 72, "TRADE", 10, C_AMBER)
	tx(576, 72, "Odile, Haven Junction, stop 6", 9, C_DIM)
	for i in GameUI.TRADES.size():
		var tr: Dictionary = GameUI.TRADES[i]
		var y: float = 80.0 + float(i) * 34.0
		var ok3: bool = GS.can_afford(tr["give"])
		panel(520, y, 250, 29, C_GOOD if ok3 else NONE)
		var ex2: float = _stack(530, y + 14, tr["give"], C_AMBER if ok3 else C_DIM)
		arrow(Vector2(maxf(ex2, 612.0), y + 14), Vector2(maxf(ex2, 612.0) + 24.0, y + 14), C_AMBER if ok3 else C_DIM)
		_stack(maxf(ex2, 612.0) + 34.0, y + 14, tr["get"], C_GOOD if ok3 else C_DIM)
	tx(520, 364, "Green bar: you can afford it now.", 9, C_DIM)
	var lx := 0.0
	tx(0, 386, "ICONS", 9, C_AMBER)
	for i in ITEMS.size():
		var it: Dictionary = GS.ITEMS[ITEMS[i]]
		var nm: String = str(it["name"])
		var col := 0 if i < 7 else 1
		if i == 7:
			lx = 0.0
		ico(str(ITEMS[i]), lx + 8, 402.0 + float(col) * 18.0, 12.0)
		tx(lx + 18, 406.0 + float(col) * 18.0, nm, 9, C_DIM)
		lx += tw(nm, 9) + 34.0

# ---------------- 14 clock and weather ----------------
func _p_clock() -> void:
	head("CLOCK & WEATHER", "THE CREW'S DAY, THE SKY, AND WHAT THE RADIO IS TELLING YOU")
	var c := Vector2(150, 222)
	var ha := func(h: float) -> float:
		return -PI * 0.5 + h / 24.0 * TAU
	draw_arc(org + c, 118.0, ha.call(6.0), ha.call(18.0), 40, Color(0.95, 0.85, 0.6, 0.8), 4.0, true)
	draw_arc(org + c, 118.0, ha.call(18.0), ha.call(30.0), 40, Color(0.25, 0.32, 0.5), 4.0, true)
	draw_arc(org + c, 98.0, 0.0, TAU, 64, Color(0.2, 0.21, 0.23), 22.0, true)
	draw_arc(org + c, 98.0, ha.call(22.5), ha.call(30.0), 32, C_BLUE, 22.0, true)
	for m: float in [7.0, 12.5, 18.5]:
		draw_arc(org + c, 98.0, ha.call(m), ha.call(m + 1.0), 8, C_AMBER, 22.0, true)
	for h in 24:
		var a: float = ha.call(float(h))
		var d := Vector2(cos(a), sin(a))
		draw_line(org + c + d * (124.0 if h % 6 == 0 else 121.0), org + c + d * 128.0, C_DIM, 1.0)
		if h % 6 == 0:
			tx(c.x + d.x * 142.0 - 15.0, c.y + d.y * 142.0 + 4.0, "%02d" % h, 10, C_WARM, AC, 30)
	var now: float = ha.call(GS.hour())
	draw_line(org + c, org + c + Vector2(cos(now), sin(now)) * 112.0, C_WARM, 2.5)
	draw_circle(org + c, 30.0, C_BG)
	tx(c.x - 40, c.y + 2, GS.clock(), 16, C_WARM, AC, 80)
	tx(c.x - 40, c.y + 16, "DAY %d" % GS.day(), 8, C_DIM, AC, 80)
	var lg: Array = [[C_BLUE, "22:30 - 06:00  the crew sleep (guards stay up)"], [C_AMBER, "07:00, 12:30, 18:30  meals, an hour each"], [Color(0.3, 0.31, 0.33), "The rest of the day  duties"], [Color(0.95, 0.85, 0.6), "06:00 - 18:00  daylight: warmer, further to see"]]
	for i in 4:
		var l: Array = lg[i]
		var lc: Color = l[0]
		draw_rect(R(0, 378.0 + float(i) * 15.0, 9, 9), lc)
		tx(14, 387.0 + float(i) * 15.0, str(l[1]), 9, C_DIM)
	var wx: Array = [["clear", "CLEAR", "Coldest. Longest views. Stars and aurora at night."], ["snow", "SNOWFALL", "Light haze. The usual weather."], ["sleet", "FREEZING RAIN", "Thick fog. Loud on the roof."], ["blizzard", "SNOWSTORM", "8 C colder. Near-blind. Wears the hull. Heating load climbs."]]
	for i in 4:
		var w: Array = wx[i]
		var x: float = 330.0 + float(i) * 111.0
		var cur: bool = GS.weather == str(w[0])
		panel(x, 62, 104, 150, C_AMBER if cur else NONE)
		var ic := Vector2(x + 52, 98)
		match i:
			0:
				draw_circle(org + ic, 12.0, C_AMBER)
				for k in 8:
					var ra: float = float(k) * TAU / 8.0 + t * 0.3
					draw_line(org + ic + Vector2(cos(ra), sin(ra)) * 16.0, org + ic + Vector2(cos(ra), sin(ra)) * 23.0, C_AMBER, 2.0)
			1:
				for k in 5:
					ico("snow", ic.x - 26.0 + float(k) * 13.0, ic.y - 12.0 + fmod(t * 14.0 + float(k) * 9.0, 28.0), 9.0, C_WARM)
			2:
				for k in 7:
					var sx: float = ic.x - 30.0 + float(k) * 10.0
					var sy: float = ic.y - 18.0 + fmod(t * 60.0 + float(k) * 11.0, 30.0)
					draw_line(P(sx, sy), P(sx - 3.0, sy + 10.0), C_BLUE, 1.5)
			_:
				for k in 9:
					var bx: float = ic.x - 34.0 + fmod(t * 70.0 + float(k) * 17.0, 68.0)
					var by: float = ic.y - 20.0 + float(k) * 4.6
					draw_line(P(bx, by), P(bx + 12.0, by + 3.0), C_WARM, 1.5)
		tx(x, 140, str(w[1]), 10, C_WARM if cur else C_DIM, AC, 104)
		if cur:
			tx(x, 152, "NOW", 8, C_AMBER, AC, 104)
		para(x + 8, 168, str(w[2]), 90, 8, C_DIM)
	tx(330, 232, "WHEN THE RADIO CRACKLES", 10, C_AMBER)
	var evs: Array = [[C_RED, 0, "TRACK BLOCKED", "Autopilot stops at the platform. Walk ahead and clear the debris: Tool Kit, one hour."], [C_RED, 1, "INFECTED MIGRATION", "Twice as many at that stop. Doors shut and lights low, or run straight through."], [C_GOOD, 1, "DISTRESS FLARE", "A survivor waits by a red flare on the platform. You need a free berth."], [C_GOOD, 1, "ABANDONED FREIGHT", "Wrecked wagons on the second track, with extra containers."], [C_AMBER, 1, "SIGNAL FAILURE", "Speed held to 50 km/h until the next stop."], [C_BLUE, 1, "WEATHER EMERGENCY", "A snowstorm is closing in. Check fuel and heating first."]]
	for i in 6:
		var e: Array = evs[i]
		var ec: Color = e[0]
		var y: float = 240.0 + float(i) * 33.0
		if int(e[1]) == 0:
			draw_line(P(334, y + 6), P(346, y + 18), ec, 3.0)
			draw_line(P(334, y + 18), P(346, y + 6), ec, 3.0)
		else:
			draw_circle(P(340, y + 12), 5.5, ec)
		tx(356, y + 12, str(e[2]), 10, C_WARM)
		tx(356, y + 25, str(e[3]), 9, C_DIM)

# ---------------- 15 saving ----------------
func _p_saving() -> void:
	head("SAVING", "YOUR JOURNEY IS KEPT IN THIS BROWSER  -  HERE IS WHAT IS ON FILE")
	for n in 4:
		var info: Dictionary = slots[n]
		var x: float = float(n) * 194.5
		var ok: bool = info["ok"]
		var bad: bool = info["exists"] and not ok
		panel(x, 62, 187, 96, C_GOOD if ok else (C_RED if bad else NONE))
		tx(x + 12, 80, "AUTOSAVE" if n == 0 else "SLOT %d" % n, 12, C_AMBER)
		para(x + 12, 100, str(info["label"]), 165, 10, C_WARM if ok else (C_RED if bad else C_DIM))
	tx(0, 180, "THE GAME SAVES ITSELF WHEN YOU", 10, C_AMBER)
	var autos: Array = [["parts", "ARRIVE AT A STOP"], ["rest", "SLEEP IN THE BUNK"], ["tools", "COUPLE A CARRIAGE"], ["stamina", "PLAY FOR 90 SECONDS"], ["crew", "QUIT TO THE MENU"]]
	for i in 5:
		var a: Array = autos[i]
		var x: float = float(i) * 155.5
		panel(x, 188, 148, 54)
		ico(str(a[0]), x + 74, 206, 16.0)
		tx(x, 232, str(a[1]), 9, C_WARM, AC, 148)
	panel(0, 254, 380, 74)
	tx(12, 272, "SAVE BY HAND", 10, C_AMBER)
	var kx: float = 12.0 + key(12, 282, "ESC")
	arrow(Vector2(kx, 292), Vector2(kx + 22.0, 292), C_DIM)
	tx(kx + 30.0, 296, "SAVE GAME", 11, C_WARM)
	arrow(Vector2(kx + 108.0, 292), Vector2(kx + 130.0, 292), C_DIM)
	tx(kx + 138.0, 296, "PICK A SLOT", 11, C_WARM)
	tx(12, 318, "CONTINUE on the main menu loads whichever save is newest.", 9, C_DIM)
	panel(390, 254, 380, 74)
	tx(402, 272, "IF A SAVE IS DAMAGED", 10, C_AMBER)
	para(402, 290, "It is marked in red and refused. It is never loaded and never overwrites a good one. Your other slots are untouched.", 356, 10, C_DIM)
	tx(0, 350, "GRAPHICS", 10, C_AMBER)
	var presets: Array = [["LOW", "No shadows, bloom or surface relief. Sparse snow and forest. For weak machines."], ["MEDIUM", "Shadows, bloom, colour grading, full forest."], ["HIGH", "Longer, finer shadows and the densest snowfall."]]
	for i in 3:
		var pr: Array = presets[i]
		var x: float = float(i) * 259.5
		var cur: bool = int(GS.settings["preset"]) == i
		panel(x, 358, 251, 60, C_AMBER if cur else NONE)
		tx(x + 12, 376, str(pr[0]), 12, C_WARM if cur else C_DIM)
		if cur:
			tx(x + 180, 376, "IN USE", 9, C_AMBER, AR, 60)
		para(x + 12, 392, str(pr[1]), 230, 9, C_DIM)
	tx(0, 436, "On first start the game times your machine and picks one. Settings: resolution scale, field of view, sensitivity, volume, every key.", 9, C_DIM)
