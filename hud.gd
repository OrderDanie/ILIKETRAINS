class_name HudDraw
extends Control
## Custom-drawn gameplay HUD: plates, gauges, compass, icons. Everything is drawn in _draw()
## from GS state, so nothing here can drift out of sync with the simulation.

const C_BG := Color(0.065, 0.07, 0.08, 0.74)
const C_BG2 := Color(0.03, 0.033, 0.04, 0.9)
const C_LINE := Color(0.34, 0.36, 0.39, 0.85)
const C_WARM := Color(0.93, 0.9, 0.84)
const C_AMBER := Color(0.88, 0.66, 0.26)
const C_RED := Color(0.84, 0.34, 0.27)
const C_DIM := Color(0.6, 0.61, 0.6)
const C_GOOD := Color(0.6, 0.8, 0.62)
const C_COLD := Color(0.6, 0.78, 0.92)
const AL := HORIZONTAL_ALIGNMENT_LEFT
const AR := HORIZONTAL_ALIGNMENT_RIGHT
const AC := HORIZONTAL_ALIGNMENT_CENTER

var main
var font: Font
var font_wide: Font
var t := 0.0
var prompt := ""
var last_prompt := ""
var prompt_a := 0.0
var toasts: Array = []
var radio_text := ""
var radio_t := 0.0
var radio_age := 0.0
var hit_a := 0.0
var hurt_a := 0.0
var card_title := ""
var card_sub := ""
var card_t := 0.0
var obj_idx := -1
var obj_flash := 0.0
var sm: Dictionary = {}
var vignette: TextureRect
var frost: TextureRect
var blood: TextureRect

# ---------- public ----------
func add_toast(text: String, kind: String) -> void:
	var col: Color = C_WARM
	match kind:
		"bad": col = C_RED
		"warn": col = C_AMBER
		"good": col = C_GOOD
	toasts.append({"text": text, "col": col, "life": 5.5, "age": 0.0})
	if toasts.size() > 5:
		toasts.pop_front()

func set_radio(text: String) -> void:
	radio_text = text
	radio_age = 0.0
	radio_t = clampf(4.0 + float(text.length()) / 20.0, 7.0, 14.0)

func show_card(title: String, sub: String) -> void:
	card_title = title
	card_sub = sub
	card_t = 5.5

func _smooth(key: String, target: float, k: float) -> float:
	var cur: float = sm.get(key, target)
	cur = lerpf(cur, target, clampf(k, 0.0, 1.0))
	sm[key] = cur
	return cur

func tick(dt: float, prompt_text: String) -> void:
	t += dt
	prompt = prompt_text
	if prompt_text != "":
		last_prompt = prompt_text
	prompt_a = move_toward(prompt_a, 1.0 if prompt_text != "" else 0.0, dt * 7.0)
	hit_a = maxf(0.0, hit_a - dt * 3.0)
	hurt_a = maxf(0.0, hurt_a - dt * 1.3)
	obj_flash = maxf(0.0, obj_flash - dt * 0.6)
	card_t = maxf(0.0, card_t - dt)
	if radio_t > 0.0:
		radio_t -= dt
		radio_age += dt
	var keep: Array = []
	for to: Dictionary in toasts:
		to["age"] = float(to["age"]) + dt
		to["life"] = float(to["life"]) - dt
		if float(to["life"]) > 0.0:
			keep.append(to)
	toasts = keep
	if GS.objective != obj_idx:
		if obj_idx >= 0:
			obj_flash = 1.0
		obj_idx = GS.objective
	var p: Dictionary = GS.player
	var hp: float = p["health"]
	_smooth("hp", hp, dt * 9.0)
	var ghost: float = sm.get("hp_ghost", hp)
	ghost = maxf(hp, ghost - dt * 14.0)
	sm["hp_ghost"] = ghost
	_smooth("st", float(p["stamina"]), dt * 10.0)
	_smooth("spd", float(GS.train["speed"]) * 3.6, dt * 6.0)
	if frost != null:
		frost.modulate.a = smoothstep(22.0, 80.0, float(p["cold"])) * 0.85
	if blood != null:
		var low: float = 0.0
		if hp < 30.0:
			low = 0.28 + 0.12 * sin(t * 4.0)
		blood.modulate.a = maxf(hurt_a * 0.75, low)
	queue_redraw()

# ---------- primitives ----------
func _k(action: String) -> String:
	var keys: Dictionary = GS.settings["keys"]
	return OS.get_keycode_string(int(keys.get(action, 0))).to_upper()

func _a(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, c.a * a)

func _t(pos: Vector2, text: String, fs: int, col: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0, f: Font = null) -> void:
	var ff: Font = font if f == null else f
	draw_string(ff, pos + Vector2(1, 1), text, align, width, fs, Color(0, 0, 0, 0.6 * col.a))
	draw_string(ff, pos, text, align, width, fs, col)

func _tw(text: String, fs: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x

func _plate(r: Rect2, accent: Color = Color(0, 0, 0, 0), a: float = 1.0) -> void:
	draw_rect(r, _a(C_BG, a))
	draw_rect(r, _a(C_LINE, a), false, 1.0)
	draw_line(r.position + Vector2(r.size.x - 12.0, 0), r.position + Vector2(r.size.x, 0), _a(C_AMBER, a * 0.9), 2.0)
	draw_line(r.position + Vector2(r.size.x, 0), r.position + Vector2(r.size.x, 8.0), _a(C_AMBER, a * 0.9), 2.0)
	if accent.a > 0.0:
		draw_rect(Rect2(r.position, Vector2(3, r.size.y)), _a(accent, a))

func _bar(r: Rect2, frac: float, col: Color, segs: int = 0) -> void:
	draw_rect(r, C_BG2)
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(frac, 0.0, 1.0), r.size.y)), col)
	for i in range(1, segs):
		var x: float = r.position.x + r.size.x * float(i) / float(segs)
		draw_line(Vector2(x, r.position.y), Vector2(x, r.position.y + r.size.y), C_BG2, 1.5)
	draw_rect(r, C_LINE, false, 1.0)

func _chip(pos: Vector2, text: String, lit: bool, col: Color = C_AMBER) -> float:
	var w: float = _tw(text, 9) + 12.0
	var r := Rect2(pos, Vector2(w, 16))
	if lit:
		draw_rect(r, col)
		draw_string(font, pos + Vector2(6, 12), text, AL, -1, 9, Color(0.05, 0.05, 0.06))
	else:
		draw_rect(r, Color(0.2, 0.21, 0.23, 0.7), false, 1.0)
		draw_string(font, pos + Vector2(6, 12), text, AL, -1, 9, C_DIM)
	return w

## Icons are built from simple convex shapes so they stay crisp at any size.
static func icon(ci: CanvasItem, kind: String, c: Vector2, s: float, col: Color) -> void:
	match kind:
		"health", "medicine":
			ci.draw_rect(Rect2(c.x - s * 0.17, c.y - s * 0.5, s * 0.34, s), col)
			ci.draw_rect(Rect2(c.x - s * 0.5, c.y - s * 0.17, s, s * 0.34), col)
		"stamina":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.18, -0.55) * s, c + Vector2(-0.38, 0.1) * s, c + Vector2(0.06, 0.1) * s]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.18, 0.55) * s, c + Vector2(0.38, -0.1) * s, c + Vector2(-0.06, -0.1) * s]), col)
		"food":
			ci.draw_rect(Rect2(c.x - s * 0.36, c.y - s * 0.42, s * 0.72, s * 0.84), col, false, 1.5)
			ci.draw_line(c + Vector2(-0.36, -0.2) * s, c + Vector2(0.36, -0.2) * s, col, 1.5)
			ci.draw_rect(Rect2(c.x - s * 0.2, c.y - s * 0.02, s * 0.4, s * 0.26), col)
		"water":
			ci.draw_circle(c + Vector2(0, 0.16) * s, s * 0.32, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -0.55) * s, c + Vector2(-0.29, 0.06) * s, c + Vector2(0.29, 0.06) * s]), col)
		"warmth":
			ci.draw_rect(Rect2(c.x - s * 0.09, c.y - s * 0.52, s * 0.18, s * 0.7), col)
			ci.draw_circle(c + Vector2(0, 0.3) * s, s * 0.23, col)
		"rest":
			ci.draw_arc(c, s * 0.34, 0.7, 0.7 + PI * 1.25, 14, col, s * 0.22)
		"diesel":
			ci.draw_rect(Rect2(c.x - s * 0.34, c.y - s * 0.28, s * 0.68, s * 0.74), col)
			ci.draw_rect(Rect2(c.x - s * 0.34, c.y - s * 0.5, s * 0.3, s * 0.16), col)
			ci.draw_rect(Rect2(c.x + s * 0.14, c.y - s * 0.44, s * 0.2, s * 0.1), col)
		"battery", "batteries":
			ci.draw_rect(Rect2(c.x - s * 0.46, c.y - s * 0.26, s * 0.84, s * 0.52), col, false, 1.5)
			ci.draw_rect(Rect2(c.x + s * 0.4, c.y - s * 0.1, s * 0.1, s * 0.2), col)
			ci.draw_rect(Rect2(c.x - s * 0.36, c.y - s * 0.16, s * 0.34, s * 0.32), col)
		"crew":
			ci.draw_circle(c + Vector2(0, -0.27) * s, s * 0.2, col)
			ci.draw_rect(Rect2(c.x - s * 0.3, c.y + s * 0.02, s * 0.6, s * 0.44), col)
		"ammo":
			ci.draw_rect(Rect2(c.x - s * 0.14, c.y - s * 0.14, s * 0.28, s * 0.62), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.14, -0.18) * s, c + Vector2(0.14, -0.18) * s, c + Vector2(0, -0.55) * s]), col)
		"ammo_rifle":
			ci.draw_rect(Rect2(c.x - s * 0.13, c.y + s * 0.0, s * 0.26, s * 0.52), col)
			ci.draw_rect(Rect2(c.x - s * 0.085, c.y - s * 0.16, s * 0.17, s * 0.14), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.085, -0.19) * s, c + Vector2(0.085, -0.19) * s, c + Vector2(0, -0.62) * s]), col)
		"ammo_shell":
			ci.draw_rect(Rect2(c.x - s * 0.2, c.y - s * 0.5, s * 0.4, s * 0.66), col, false, 1.5)
			ci.draw_rect(Rect2(c.x - s * 0.24, c.y + s * 0.16, s * 0.48, s * 0.32), col)
		"ammo_mag":
			for o: float in [-0.2, 0.2]:
				ci.draw_rect(Rect2(c.x + s * (o - 0.12), c.y - s * 0.12, s * 0.24, s * 0.6), col)
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(o - 0.12, -0.16) * s, c + Vector2(o + 0.12, -0.16) * s, c + Vector2(o, -0.5) * s]), col)
		"tools":
			ci.draw_line(c + Vector2(-0.4, 0.4) * s, c + Vector2(0.2, -0.2) * s, col, s * 0.17)
			ci.draw_arc(c + Vector2(0.26, -0.26) * s, s * 0.2, -0.4, PI * 1.1, 10, col, s * 0.13)
		"electronics":
			ci.draw_rect(Rect2(c.x - s * 0.28, c.y - s * 0.28, s * 0.56, s * 0.56), col)
			for i in 3:
				var o: float = (float(i) - 1.0) * s * 0.2
				ci.draw_line(c + Vector2(o, -0.5 * s), c + Vector2(o, 0.5 * s), col, 1.5)
				ci.draw_line(c + Vector2(-0.5 * s, o), c + Vector2(0.5 * s, o), col, 1.5)
		"parts":
			ci.draw_arc(c, s * 0.3, 0.0, TAU, 8, col, s * 0.2)
		"scrap":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.5, 0.4) * s, c + Vector2(-0.1, -0.45) * s, c + Vector2(0.1, 0.4) * s]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.05, 0.4) * s, c + Vector2(0.35, -0.2) * s, c + Vector2(0.5, 0.4) * s]), col)
		"warn":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -0.5) * s, c + Vector2(-0.5, 0.42) * s, c + Vector2(0.5, 0.42) * s]), col)
		"snow":
			for i in 3:
				var d := Vector2(cos(float(i) * PI / 3.0), sin(float(i) * PI / 3.0)) * s * 0.48
				ci.draw_line(c - d, c + d, col, 1.6)
		_:
			ci.draw_circle(c, s * 0.3, col)

# ---------- drawing ----------
func _draw() -> void:
	if main == null or font == null or main.player == null:
		return
	var W: float = size.x
	var H: float = size.y
	var tr: Dictionary = GS.train
	var p: Dictionary = GS.player
	var seated: bool = main.player.seated
	_draw_scope(W, H)
	_draw_location(tr)
	_draw_compass(W)
	_draw_objective(W)
	_draw_vitals(H, p)
	_draw_gear(W, H)
	if seated:
		_draw_drive(W, H, tr)
	_draw_cross(W, H, seated)
	_draw_toasts(W, H, seated)
	_draw_radio(W)
	_draw_card(W, H)

func _draw_location(tr: Dictionary) -> void:
	var s: float = tr["s"]
	var k: int = int(round(s / GS.SP))
	var at: bool = absf(s - float(k) * GS.SP) < 30.0
	var title := "EN ROUTE"
	var sub := ""
	if at:
		var loc: Dictionary = GS.loc_at(k)
		title = str(loc["name"]).to_upper()
		sub = str(loc["kind"]).to_upper()
	else:
		var nk: int = int(ceil(s / GS.SP))
		var nl: Dictionary = GS.loc_at(nk)
		sub = "%s   %d M" % [str(nl["name"]).to_upper(), int(float(nk) * GS.SP - s)]
	_plate(Rect2(20, 18, 396, 50), C_AMBER)
	_t(Vector2(34, 39), title, 16, C_WARM)
	_t(Vector2(34, 57), sub, 10, C_AMBER)
	_t(Vector2(306, 40), GS.clock(), 19, C_WARM, AR, 98)
	_t(Vector2(306, 57), "DAY %d" % GS.day(), 10, C_DIM, AR, 98)
	# train status strip
	var y := 72.0
	_plate(Rect2(20, y, 396, 44))
	var temp: float = tr["temp"]
	var bat: float = tr["battery"]
	var food: int = GS.count(GS.store, "food")
	var water: int = GS.count(GS.store, "water")
	var cells: Array = [
		["diesel", "%d L" % int(tr["diesel"]), float(tr["diesel"]) / 1200.0, float(tr["diesel"]) < 80.0],
		["battery", "%d" % int(bat), bat / GS.bat_cap(), (not GS.power_ok) or (bat < 15.0 and GS.kw_gen < GS.kw_load)],
		["food", "%d" % food, float(food) / 40.0, food < 6],
		["water", "%d" % water, float(water) / 40.0, water < 6],
		["crew", "%d/%d" % [GS.crew.size(), GS.crew_cap()], GS.avg_morale() / 100.0, GS.avg_morale() < 35.0],
		["warmth", "%d C" % int(round(temp)), clampf((temp + 10.0) / 30.0, 0.0, 1.0), temp < 8.0],
	]
	for i in cells.size():
		var c: Array = cells[i]
		var x: float = 24.0 + float(i) * 65.0
		var bad: bool = c[3]
		var col: Color = C_WARM
		if bad:
			col = _a(C_RED, 0.7 + 0.3 * sin(t * 6.0))
		icon(self, str(c[0]), Vector2(x + 12.0, y + 17.0), 14.0, col if bad else C_AMBER)
		_t(Vector2(x + 24.0, y + 22.0), str(c[1]), 12, col)
		var fr: float = c[2]
		_bar(Rect2(x + 4.0, y + 33.0, 56.0, 4.0), fr, C_RED if bad else C_DIM)
		if i > 0:
			draw_line(Vector2(x, y + 6.0), Vector2(x, y + 38.0), Color(1, 1, 1, 0.07), 1.0)
	# weather line
	_plate(Rect2(20, 120, 396, 22))
	var wname: String = {"clear": "CLEAR SKY", "snow": "SNOWFALL", "blizzard": "SNOWSTORM", "sleet": "FREEZING RAIN"}.get(GS.weather, "SNOWFALL")
	icon(self, "snow", Vector2(35, 131), 12.0, C_COLD)
	_t(Vector2(48, 135), wname, 10, C_COLD if GS.weather != "clear" else C_DIM)
	_t(Vector2(150, 135), "OUTSIDE %d C" % int(round(GS.t_out)), 10, C_DIM)
	var net: float = GS.kw_gen - GS.kw_load
	_t(Vector2(280, 135), "POWER %+d KW" % int(net), 10, C_GOOD if net >= 0.0 else C_AMBER, AR, 126)

func _draw_compass(W: float) -> void:
	var cx: float = W * 0.5
	_plate(Rect2(cx - 172.0, 18, 344, 26))
	var bearing: float = fposmod(rad_to_deg(-main.player.yaw), 360.0)
	var names: Array = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	for i in 24:
		var d: float = wrapf(float(i) * 15.0 - bearing, -180.0, 180.0)
		if absf(d) > 62.0:
			continue
		var x: float = cx + d / 62.0 * 160.0
		var al: float = 1.0 - absf(d) / 62.0 * 0.85
		if i % 3 == 0:
			var nm: String = names[i / 3]
			var big: bool = i % 6 == 0
			_t(Vector2(x - 20.0, 37.0), nm, 13 if big else 9, _a(C_WARM if big else C_DIM, al), AC, 40.0)
		else:
			draw_line(Vector2(x, 26.0), Vector2(x, 34.0), _a(C_DIM, al * 0.8), 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(cx - 5.0, 15.0), Vector2(cx + 5.0, 15.0), Vector2(cx, 22.0)]), C_AMBER)
	if not main.aboard:
		var pp: Vector3 = main.player.global_position
		var tz: float = clampf(pp.z, -14.0, main.train.tail_z())
		var dx: float = -pp.x
		var dz: float = tz - pp.z
		var bt: float = rad_to_deg(atan2(dx, -dz))
		var dd: float = clampf(wrapf(bt - bearing, -180.0, 180.0), -62.0, 62.0)
		var mx: float = cx + dd / 62.0 * 160.0
		draw_colored_polygon(PackedVector2Array([Vector2(mx, 46.0), Vector2(mx + 6.0, 54.0), Vector2(mx - 6.0, 54.0)]), C_AMBER)
		_t(Vector2(mx - 60.0, 68.0), "TRAIN  %d M" % int(Vector2(dx, dz).length()), 10, C_AMBER, AC, 120.0)
	# the current objective, when it is something you can walk to at this stop
	var smk: Array = Story.marker()
	if smk.size() == 1:
		var op: Vector3 = smk[0]
		var pp2: Vector3 = main.player.global_position
		var odx: float = op.x - pp2.x
		var odz: float = op.z - pp2.z
		var od: float = Vector2(odx, odz).length()
		if od < 260.0 and od > 1.5:
			var ob: float = rad_to_deg(atan2(odx, -odz))
			var odd: float = clampf(wrapf(ob - bearing, -180.0, 180.0), -62.0, 62.0)
			var ox: float = cx + odd / 62.0 * 160.0
			draw_colored_polygon(PackedVector2Array([Vector2(ox, 46.0), Vector2(ox + 6.0, 53.0), Vector2(ox, 60.0), Vector2(ox - 6.0, 53.0)]), C_WARM)
			_t(Vector2(ox - 70.0, 84.0 if not main.aboard else 72.0), "OBJECTIVE  %d M" % int(od), 10, C_WARM, AC, 140.0)

func _draw_objective(W: float) -> void:
	var title := ""
	var body := ""
	var kicker := "OBJECTIVE"
	if GS.objective < 5:
		var oi: int = clampi(GS.objective, 0, GameUI.OBJECTIVES.size() - 1)
		title = GameUI.OBJECTIVES[oi][0]
		body = GameUI.OBJECTIVES[oi][1]
		kicker = "PROLOGUE   -   THE LAST DEPARTURE"
		if oi == 2:
			body += "  (%d / 3)" % mini(3, int(GS.stats["looted"]))
	else:
		var so: Dictionary = Story.objective()
		title = str(so["title"])
		body = str(so["what"])
		kicker = str(so["kicker"])
		if str(so["prog"]) != "":
			body += "\n" + str(so["prog"])
	var w := 330.0
	var bs: Vector2 = font.get_multiline_string_size(body, AL, w - 30.0, 12)
	var r := Rect2(W - 20.0 - w, 18, w, 48.0 + bs.y)
	_plate(r, C_AMBER)
	if obj_flash > 0.0:
		draw_rect(r, Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, obj_flash * 0.3))
	_t(r.position + Vector2(14, 16), kicker, 9, C_DIM)
	_t(r.position + Vector2(w - 60.0, 16), "[%s]" % _k("objectives"), 9, C_DIM, AR, 46.0)
	_t(r.position + Vector2(14, 34), title.to_upper(), 14, C_AMBER)
	draw_multiline_string(font, r.position + Vector2(14, 52), body, AL, w - 30.0, 12, -1, C_WARM)
	var y: float = r.end.y + 8.0
	var shown := 0
	for wn: Array in GS.warnings:
		if shown >= 5:
			break
		var txt: String = str(wn[0]).to_upper()
		var sev: bool = int(wn[1]) >= 2
		var col: Color = C_RED if sev else C_AMBER
		var a: float = (0.72 + 0.28 * sin(t * 6.0)) if sev else 1.0
		var tw: float = _tw(txt, 11) + 38.0
		var cr := Rect2(W - 20.0 - tw, y, tw, 22)
		draw_rect(cr, _a(C_BG, a))
		draw_rect(Rect2(cr.end.x - 3.0, y, 3, 22), _a(col, a))
		icon(self, "warn", Vector2(cr.position.x + 13.0, y + 11.0), 11.0, _a(col, a))
		_t(Vector2(cr.position.x + 24.0, y + 15.0), txt, 11, _a(col, a))
		y += 26.0
		shown += 1

func _draw_vitals(H: float, p: Dictionary) -> void:
	_plate(Rect2(20, H - 122.0, 312, 102))
	var hp: float = sm.get("hp", 100.0)
	var ghost: float = sm.get("hp_ghost", 100.0)
	var st: float = sm.get("st", 100.0)
	var hcol: Color = C_WARM
	if hp <= 35.0:
		hcol = _a(C_RED, 0.75 + 0.25 * sin(t * 6.0))
	icon(self, "health", Vector2(38, H - 101.0), 14.0, hcol)
	var hb := Rect2(54, H - 107.0, 216, 12)
	draw_rect(hb, C_BG2)
	draw_rect(Rect2(hb.position, Vector2(hb.size.x * ghost / 100.0, hb.size.y)), Color(C_RED.r, C_RED.g, C_RED.b, 0.6))
	_bar(Rect2(hb.position, hb.size), hp / 100.0, hcol, 12)
	_t(Vector2(274, H - 96.0), "%d" % int(round(hp)), 14, hcol, AR, 46.0)
	icon(self, "stamina", Vector2(38, H - 80.0), 13.0, C_AMBER)
	_bar(Rect2(54, H - 84.0, 216, 7), st / 100.0, C_AMBER if st > 15.0 else C_RED)
	_t(Vector2(274, H - 76.0), "%d" % int(round(st)), 11, C_DIM, AR, 46.0)
	var needs: Array = [["food", 100.0 - float(p["hunger"]), "FOOD"], ["water", 100.0 - float(p["thirst"]), "WATER"], ["warmth", 100.0 - float(p["cold"]), "WARMTH"], ["rest", 100.0 - float(p["fatigue"]), "REST"]]
	for i in 4:
		var nd: Array = needs[i]
		var val: float = nd[1]
		var c := Vector2(42.0 + float(i) * 74.0, H - 45.0)
		var col: Color = C_WARM
		if val < 22.0:
			col = C_RED
		elif val < 45.0:
			col = C_AMBER
		draw_arc(c, 13.0, 0.0, TAU, 24, Color(0.2, 0.21, 0.23, 0.9), 3.0, true)
		draw_arc(c, 13.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(val / 100.0, 0.0, 1.0), 24, col, 3.0, true)
		icon(self, str(nd[0]), c, 11.0, col)
		_t(c + Vector2(19, -3), str(nd[2]), 9, C_DIM)
		_t(c + Vector2(19, 10), "%d" % int(val), 12, col)
	var chips: Array = []
	if p["bleeding"]:
		chips.append(["BLEEDING", C_RED])
	if p["sick"]:
		chips.append(["ILL", C_AMBER])
	if float(p["cold"]) > 55.0:
		chips.append(["HYPOTHERMIA", C_COLD])
	if float(p["fatigue"]) > 85.0:
		chips.append(["EXHAUSTED", C_AMBER])
	if GS.weight(GS.inv) > GS.inv_cap():
		chips.append(["OVERBURDENED", C_AMBER])
	if GS.train["doors_open"]:
		chips.append(["DOORS OPEN", C_AMBER])
	if main.player.crouched:
		chips.append(["CROUCHED", C_DIM])
	if main.player.sprinting:
		chips.append(["SPRINTING", C_DIM])
	var x := 20.0
	for ch: Array in chips:
		var cc: Color = ch[1]
		var w: float = _tw(str(ch[0]), 10) + 22.0
		var cr := Rect2(x, H - 150.0, w, 22)
		draw_rect(cr, C_BG)
		draw_rect(Rect2(x, H - 150.0, 3, 22), cc)
		_t(Vector2(x + 12.0, H - 135.0), str(ch[0]), 10, cc)
		x += w + 6.0

func _draw_gear(W: float, H: float) -> void:
	var ar: Arsenal = main.player.arsenal
	if ar.cur == "":
		return
	var d: Dictionary = ar.d
	var r := Rect2(W - 292.0, H - 122.0, 272, 102)
	_plate(r)
	var x0: float = r.position.x
	var mag: int = ar.mag()
	var res: int = ar.reserve()
	var cap: int = int(d["mag"])
	var acol: Color = C_WARM
	if mag <= 0:
		acol = C_RED
	elif float(mag) <= float(cap) * 0.25:
		acol = C_AMBER
	_t(Vector2(x0 + 14.0, H - 101.0), str(d["name"]), 15, C_WARM)
	_t(Vector2(x0 + 14.0, H - 87.0), str(d["cat"]), 9, C_AMBER)
	_t(Vector2(x0 + 12.0, H - 42.0), "%d" % mag, 38, acol)
	_t(Vector2(x0 + 18.0 + _tw("%d" % mag, 38), H - 42.0), "/ %d" % res, 16, C_DIM)
	var it: Dictionary = GS.ITEMS[d["ammo"]]
	_t(Vector2(x0 + 14.0, H - 28.0), str(it["name"]).to_upper(), 9, C_DIM)
	var pips: int = mini(cap, 30)
	var lit: int = int(ceil(float(mag) / float(cap) * float(pips)))
	for i in pips:
		var pr := Rect2(x0 + 140.0 + float(i % 15) * 8.3, H - 111.0 + float(i / 15) * 15.0, 5.5, 12)
		if i < lit:
			draw_rect(pr, acol)
		else:
			draw_rect(pr, Color(0.25, 0.26, 0.28, 0.7), false, 1.0)
	var mode := "SEMI"
	if d["auto"]:
		mode = "AUTO"
	elif str(d.get("cycle", "")) == "pump":
		mode = "PUMP"
	elif str(d.get("cycle", "")) == "bolt":
		mode = "BOLT"
	var cx: float = x0 + 140.0
	cx += _chip(Vector2(cx, H - 76.0), mode, false) + 5.0
	if ar.anim_name == "reload":
		_chip(Vector2(cx, H - 76.0), "RELOADING", true, C_AMBER)
	elif mag <= 0:
		_chip(Vector2(cx, H - 76.0), "%s  RELOAD" % _k("reload"), true, C_RED)
	elif ar.anim_name == "inspect":
		_chip(Vector2(cx, H - 76.0), "INSPECTING", true, C_WARM)
	var wgt: float = GS.weight(GS.inv)
	var capw: float = GS.inv_cap()
	_t(Vector2(x0 + 140.0, H - 46.0), "LOAD  %.1f / %d KG" % [wgt, int(capw)], 9, C_AMBER if wgt > capw else C_DIM)
	_bar(Rect2(x0 + 140.0, H - 42.0, 120, 4), wgt / capw, C_AMBER if wgt > capw else C_DIM)
	var own: Array = ar.owned()
	for i in own.size():
		var pstep: float = minf(12.2, 122.0 / float(maxi(1, own.size())))
		var sr := Rect2(x0 + 140.0 + float(i) * pstep, H - 31.0, pstep - 2.2, 5)
		draw_rect(sr, C_AMBER if str(own[i]) == ar.cur else Color(0.3, 0.31, 0.33, 0.9))
	var hx: float = x0
	hx += _chip(Vector2(hx, H - 144.0), "%s INSPECT" % _k("inspect"), ar.anim_name == "inspect") + 5.0
	hx += _chip(Vector2(hx, H - 144.0), "%s SWAP" % _k("swap"), false) + 5.0
	hx += _chip(Vector2(hx, H - 144.0), "%s LIGHT" % _k("flashlight"), main.player.torch.visible) + 5.0
	_chip(Vector2(hx, H - 144.0), "%s PACK" % _k("inventory"), false)
	var gx: float = x0
	gx += _chip(Vector2(gx, H - 165.0), "%s MANUAL" % _k("manual"), false, C_COLD) + 5.0
	gx += _chip(Vector2(gx, H - 165.0), "%s DOORS" % _k("doors"), GS.train["doors_open"]) + 5.0
	gx += _chip(Vector2(gx, H - 165.0), "%s TRAIN" % _k("manage"), false) + 5.0
	_chip(Vector2(gx, H - 165.0), "%s MAP" % _k("map"), false)

func _draw_scope(W: float, H: float) -> void:
	var a: float = main.player.arsenal.scope_a
	if a <= 0.01:
		return
	var c := Vector2(W * 0.5, H * 0.5)
	var R: float = H * 0.43
	draw_arc(c, R + W, 0.0, TAU, 72, Color(0, 0, 0, a), W * 2.0)
	draw_arc(c, R, 0.0, TAU, 72, Color(0, 0, 0, a), 7.0, true)
	var lc := Color(0.02, 0.02, 0.02, a)
	for i in 4:
		var dv := Vector2(1, 0).rotated(float(i) * PI * 0.5)
		draw_line(c + dv * R, c + dv * R * 0.34, lc, 4.0)
		draw_line(c + dv * R * 0.34, c + dv * 7.0, lc, 1.2)
		for m in range(1, 5):
			draw_circle(c + dv * (R * 0.068 * float(m)), 1.6, lc)
	draw_circle(c, 1.3, Color(0.75, 0.1, 0.08, a))

func _draw_drive(W: float, H: float, tr: Dictionary) -> void:
	var cx: float = W * 0.5
	var r := Rect2(cx - 280.0, H - 160.0, 560, 140)
	_plate(r, C_AMBER)
	var spd: float = sm.get("spd", 0.0)
	var thr: float = tr["throttle"]
	var brk: float = tr["brake"]
	# dial
	var dc := Vector2(cx, H - 82.0)
	var rad := 54.0
	var a0: float = deg_to_rad(140.0)
	var sweep: float = deg_to_rad(260.0)
	draw_arc(dc, rad, a0, a0 + sweep, 48, Color(0.22, 0.23, 0.25, 0.95), 5.0, true)
	draw_arc(dc, rad, a0, a0 + sweep * clampf(spd / 140.0, 0.0, 1.0), 48, C_AMBER, 5.0, true)
	for i in 8:
		var kv: float = float(i) * 20.0
		var an: float = a0 + sweep * kv / 140.0
		var dir := Vector2(cos(an), sin(an))
		draw_line(dc + dir * (rad - 9.0), dc + dir * (rad - 2.0), C_WARM, 1.5)
		if i % 2 == 0:
			_t(dc + dir * (rad - 19.0) + Vector2(-12, 4), "%d" % int(kv), 8, C_DIM, AC, 24.0)
	var lim: float = minf(GS.speed_limit, 33.0 * (0.4 + 0.6 * float(GS.loco["engine"]) / 100.0)) * 3.6
	var la: float = a0 + sweep * clampf(lim / 140.0, 0.0, 1.0)
	draw_line(dc + Vector2(cos(la), sin(la)) * (rad - 4.0), dc + Vector2(cos(la), sin(la)) * (rad + 6.0), C_RED, 2.5)
	var na: float = a0 + sweep * clampf(spd / 140.0, 0.0, 1.0)
	draw_line(dc, dc + Vector2(cos(na), sin(na)) * (rad - 12.0), C_WARM, 2.0)
	draw_circle(dc, 4.0, C_WARM)
	_t(Vector2(cx - 50.0, H - 44.0), "%d" % int(round(spd)), 24, C_WARM, AC, 100.0)
	_t(Vector2(cx - 50.0, H - 30.0), "KM/H", 9, C_DIM, AC, 100.0)
	# power / brake columns
	var lx: float = r.position.x + 22.0
	for i in 2:
		var val: float = thr if i == 0 else brk
		var col: Color = C_AMBER if i == 0 else C_RED
		var br := Rect2(lx + float(i) * 44.0, H - 140.0, 18, 84)
		draw_rect(br, C_BG2)
		draw_rect(Rect2(br.position.x, br.end.y - br.size.y * val, br.size.x, br.size.y * val), col)
		for n in range(1, 4):
			draw_line(Vector2(br.position.x, br.position.y + br.size.y * float(n) / 4.0), Vector2(br.end.x, br.position.y + br.size.y * float(n) / 4.0), C_BG2, 1.5)
		draw_rect(br, C_LINE, false, 1.0)
		_t(Vector2(br.position.x - 10.0, H - 42.0), "POWER" if i == 0 else "BRAKE", 9, C_DIM, AC, 38.0)
		_t(Vector2(br.position.x - 10.0, H - 29.0), "%d%%" % int(val * 100.0), 11, col, AC, 38.0)
	# lamps
	var lamps: Array = [["ENG", tr["engine_on"], C_GOOD], ["AUTO", tr["autopilot"], C_AMBER], ["DOOR", tr["doors_open"], C_RED], ["LAMP", tr["headlights"], C_WARM]]
	for i in lamps.size():
		var lm: Array = lamps[i]
		var lit: bool = lm[1]
		var lc: Color = lm[2]
		var pos := Vector2(lx + 96.0, H - 140.0 + float(i) * 22.0)
		var lr := Rect2(pos, Vector2(46, 17))
		if lit:
			draw_rect(lr, lc)
			draw_string(font, pos + Vector2(0, 13), str(lm[0]), AC, 46.0, 9, Color(0.05, 0.05, 0.06))
		else:
			draw_rect(lr, Color(0.2, 0.21, 0.23, 0.8), false, 1.0)
			draw_string(font, pos + Vector2(0, 13), str(lm[0]), AC, 46.0, 9, C_DIM)
	# next stop
	var s: float = tr["s"]
	var k: int = int(round(s / GS.SP))
	if s > float(k) * GS.SP + 4.0:
		k += 1
	var dist: float = maxf(0.0, float(k) * GS.SP - s)
	var loc: Dictionary = GS.loc_at(k)
	var rx: float = cx + 84.0
	_t(Vector2(rx, H - 138.0), "NEXT STOP", 9, C_DIM)
	_t(Vector2(rx, H - 120.0), str(loc["name"]).to_upper(), 12, C_WARM)
	_t(Vector2(rx, H - 92.0), "%d M" % int(dist), 22, C_AMBER)
	var eta := "ETA  --"
	if float(tr["speed"]) > 1.0:
		eta = "ETA  %d S" % int(dist / float(tr["speed"]))
	_t(Vector2(rx + 86.0, H - 92.0), eta, 10, C_DIM, AR, 96.0)
	var pb := Rect2(rx, H - 80.0, 182, 5)
	_bar(pb, 1.0 - dist / GS.SP, C_AMBER)
	draw_rect(Rect2(pb.position.x + pb.size.x * clampf(1.0 - dist / GS.SP, 0.0, 1.0) - 2.0, pb.position.y - 3.0, 4, 11), C_WARM)
	var mode := "MANUAL"
	var mcol: Color = C_WARM
	if not tr["engine_on"]:
		mode = "ENGINE OFF"
		mcol = C_RED
	elif tr["autopilot"]:
		mode = "AUTOPILOT"
		mcol = C_AMBER
	_t(Vector2(rx, H - 54.0), mode, 13, mcol)
	_t(Vector2(rx, H - 36.0), "LIMIT %d KM/H" % int(lim), 10, C_DIM)
	var hint: String = "%s / %s  POWER - BRAKE      %s  EMERGENCY BRAKE      %s  AUTOPILOT      %s  HORN      %s  LAMPS      %s  LEAVE SEAT" % [_k("move_up"), _k("move_down"), _k("jump"), _k("autopilot"), _k("horn"), _k("headlights"), _k("interact")]
	_t(Vector2(cx - 400.0, H - 168.0), hint, 10, C_DIM, AC, 800.0)

func _draw_cross(W: float, H: float, seated: bool) -> void:
	var c := Vector2(W * 0.5, H * 0.5)
	if not seated:
		var ar: Arsenal = main.player.arsenal
		var show: float = (1.0 - ar.ads) * (1.0 - ar.low) * (0.0 if ar.anim_name == "inspect" else 1.0)
		if show > 0.05:
			var g: float = 5.0 + ar.spread_now * 380.0
			for i in 4:
				var dv := Vector2(1, 0).rotated(float(i) * PI * 0.5)
				draw_line(c + dv * (g + 1.0), c + dv * (g + 8.0), Color(0, 0, 0, 0.5 * show), 3.0)
				draw_line(c + dv * g, c + dv * (g + 7.0), Color(1, 1, 1, 0.85 * show), 1.5)
		if ar.scope_a < 0.01:
			draw_circle(c, 1.6, Color(1, 1, 1, 0.8 * (1.0 - ar.ads)))
		if prompt_a > 0.02:
			draw_arc(c, 6.0 + 4.0 * (1.0 - prompt_a), 0.0, TAU, 24, _a(C_AMBER, prompt_a), 1.5, true)
	if hit_a > 0.0:
		for i in 4:
			var d := Vector2(1 if i % 2 == 0 else -1, 1 if i < 2 else -1)
			draw_line(c + d * 5.0, c + d * 11.0, Color(1, 1, 1, hit_a), 2.0)
	if prompt_a <= 0.02 or last_prompt == "":
		return
	var text: String = last_prompt
	var key := ""
	if text.begins_with("["):
		var e: int = text.find("]")
		if e > 0:
			key = text.substr(1, e - 1).to_upper()
			text = text.substr(e + 1).strip_edges()
	if seated and text.begins_with("Leave the driver"):
		return
	var tw: float = _tw(text, 14)
	var kw: float = 0.0
	if key != "":
		kw = maxf(24.0, _tw(key, 13) + 12.0)
	var total: float = tw + kw + (34.0 if key != "" else 26.0)
	var r := Rect2(c.x - total * 0.5, c.y + 36.0, total, 30)
	_plate(r, Color(0, 0, 0, 0), prompt_a)
	var tx: float = r.position.x + 13.0
	if key != "":
		var kr := Rect2(r.position.x + 5.0, r.position.y + 4.0, kw, 22)
		draw_rect(kr, _a(C_WARM, prompt_a))
		draw_string(font, kr.position + Vector2(0, 16), key, AC, kw, 13, Color(0.06, 0.06, 0.07, prompt_a))
		tx = kr.end.x + 9.0
	_t(Vector2(tx, r.position.y + 20.0), text, 14, _a(C_WARM, prompt_a))

func _draw_toasts(W: float, H: float, seated: bool) -> void:
	var base: float = H - 214.0 if seated else H - 50.0
	var n: int = toasts.size()
	for i in n:
		var to: Dictionary = toasts[n - 1 - i]
		var age: float = to["age"]
		var a: float = clampf(float(to["life"]), 0.0, 1.0) * clampf(age * 5.0, 0.0, 1.0)
		var txt: String = to["text"]
		var col: Color = to["col"]
		var tw: float = _tw(txt, 13) + 30.0
		var slide: float = (1.0 - clampf(age * 5.0, 0.0, 1.0)) * 26.0
		var r := Rect2(W * 0.5 - tw * 0.5, base - float(i) * 27.0 + slide, tw, 23)
		draw_rect(r, _a(C_BG, a))
		draw_rect(Rect2(r.position, Vector2(3, 23)), _a(col, a))
		_t(r.position + Vector2(15, 16), txt, 13, _a(col, a))

func _draw_radio(W: float) -> void:
	if radio_t <= 0.0:
		return
	var a: float = clampf(radio_t, 0.0, 1.0) * clampf(radio_age * 4.0, 0.0, 1.0)
	var w := 440.0
	var bs: Vector2 = font.get_multiline_string_size(radio_text, AL, w - 34.0, 13)
	var r := Rect2(W * 0.5 - w * 0.5, 76, w, 38.0 + bs.y)
	if W < 1300.0:
		r.position = Vector2(20, 150)
	_plate(r, C_AMBER, a)
	_t(r.position + Vector2(16, 17), "INCOMING TRANSMISSION", 10, _a(C_AMBER, a))
	for i in 9:
		var hh: float = 3.0 + 9.0 * absf(sin(t * (6.0 + float(i)) + float(i) * 1.7))
		draw_rect(Rect2(r.end.x - 20.0 - float(i) * 6.0, r.position.y + 19.0 - hh, 3, hh), _a(C_AMBER, a))
	var shown: String = radio_text.substr(0, int(radio_age * 55.0))
	draw_multiline_string(font, r.position + Vector2(16, 36), shown, AL, w - 34.0, 13, -1, _a(C_WARM, a))

func _draw_card(W: float, H: float) -> void:
	if card_t <= 0.0:
		return
	var a: float = clampf((5.5 - card_t) / 0.9, 0.0, 1.0) * clampf(card_t / 1.2, 0.0, 1.0)
	var y: float = H * 0.36
	var ff: Font = font_wide if font_wide != null else font
	_t(Vector2(0, y), card_title, 40, _a(C_WARM, a), AC, W, ff)
	var half: float = 190.0 * clampf((5.5 - card_t) / 1.4, 0.0, 1.0)
	draw_rect(Rect2(W * 0.5 - half, y + 14.0, half * 2.0, 2), _a(C_AMBER, a))
	_t(Vector2(0, y + 38.0), card_sub, 13, _a(C_AMBER, a), AC, W, ff)
