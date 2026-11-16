class_name Kit
extends RefCounted
## Mesh builder + material registry. Merges boxes / cylinders into one ArrayMesh
## per material so a whole carriage or station is a handful of draw calls.

static var mats: Dictionary = {}
static var default_bevel := 0.0
static var bevel_min := 0.009
static var bevel_max := 1000000.0

## Switches on chamfered edges for every box built until bevel_pop: size is the chamfer, and only
## boxes whose smallest side is at least mn and largest side at most mx are chamfered.
static func bevel_push(size: float, mn: float, mx: float) -> Array:
	var prev: Array = [default_bevel, bevel_min, bevel_max]
	default_bevel = size
	bevel_min = mn
	bevel_max = mx
	return prev

static func bevel_pop(prev: Array) -> void:
	default_bevel = prev[0]
	bevel_min = prev[1]
	bevel_max = prev[2]
static var texs: Dictionary = {}
static var flats: Dictionary = {}
static var font: FontFile = null

const FACES := [
	[Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)],
	[Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)],
	[Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, -1)],
	[Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
	[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
	[Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0)],
]
const ORDER := [0, 2, 1, 0, 3, 2]

var st: Dictionary = {}
var xf: Transform3D = Transform3D.IDENTITY

static func get_font() -> FontFile:
	if font == null:
		font = load("res://assets/fonts/RussoOne.ttf")
		var fb: Font = load("res://emoji_fallback/emoji_fallback_font.tres")
		if fb != null:
			font.fallbacks = [fb]
	return font

## Surfaces with a scanned PBR set (albedo, tangent-space normal, roughness) from Poly Haven.
const PBR := ["snow", "ballast", "metal", "floor", "concrete", "brick", "corrugated", "wood", "rust", "paving", "fabric"]
const RNORM := 0.8

static func tex(tname: String, normal: bool = false, strength: float = 4.0, suffix: String = "") -> Texture2D:
	var key := tname + ("_n" if normal else "") + suffix
	if texs.has(key):
		return texs[key]
	var scanned: bool = normal and PBR.has(tname)
	var fname: String = tname + ("_n" if scanned else "") + suffix
	var src: Texture2D = load("res://assets/tex/%s.png" % fname)
	var img: Image = src.get_image()
	if img.is_compressed():
		img.decompress()
	if normal and not scanned:
		img.bump_map_to_normal_map(strength)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	texs[key] = t
	return t

static func make(key: String, color: Color, rough: float, metal: float = 0.0, t: String = "", tile: float = 1.0, nstr: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	m.metallic_specular = 0.5
	m.vertex_color_use_as_albedo = true
	if t != "":
		m.albedo_texture = tex(t)
		m.uv1_scale = Vector3(1.0 / tile, 1.0 / tile, 1.0)
		if nstr > 0.0:
			m.normal_enabled = true
			m.normal_texture = tex(t, true, nstr)
		if PBR.has(t):
			m.roughness_texture = tex(t, false, 0.0, "_r")
			m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
			m.roughness = clampf(rough / RNORM, 0.05, 1.0)
	mats[key] = m
	return m

static func glow(key: String, color: Color, energy: float, base: Color = Color(0.9, 0.9, 0.9)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = base
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	mats[key] = m
	return m

static func flat(color: Color, rough: float = 0.85) -> StandardMaterial3D:
	var k := color.to_html() + str(rough)
	if flats.has(k):
		return flats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	flats[k] = m
	return m

static func init_materials() -> void:
	if mats.size() > 0:
		return
	make("hull", Color(0.24, 0.30, 0.37), 0.42, 0.2, "metal", 2.2, 2.5)
	make("hull_lt", Color(0.80, 0.78, 0.72), 0.48, 0.12, "metal", 2.2, 2.5)
	make("hull_blk", Color(0.07, 0.075, 0.085), 0.32, 0.2, "metal", 2.2, 1.5)
	make("stripe", Color(0.86, 0.60, 0.16), 0.5, 0.2, "metal", 2.2)
	make("roof", Color(0.36, 0.38, 0.41), 0.6, 0.15, "metal", 2.2, 3.0)
	make("under", Color(0.11, 0.11, 0.12), 0.8, 0.12, "rust", 1.6, 3.0)
	make("steel", Color(0.80, 0.82, 0.85), 0.24, 0.4, "metal", 1.0)
	make("steel_dk", Color(0.30, 0.31, 0.33), 0.45, 0.28, "metal", 1.5, 2.0)
	make("rail", Color(0.62, 0.58, 0.55), 0.3, 0.8)
	make("wheel", Color(0.2, 0.19, 0.19), 0.55, 0.6, "rust", 1.0)
	make("panel", Color(0.90, 0.86, 0.78), 0.62, 0.0, "metal", 2.6, 1.5)
	make("panel_dk", Color(0.45, 0.47, 0.50), 0.6, 0.1, "metal", 2.6, 1.5)
	make("floor", Color(0.75, 0.75, 0.78), 0.72, 0.0, "floor", 1.0, 5.0)
	make("ceiling", Color(0.82, 0.80, 0.74), 0.7, 0.0, "metal", 3.0)
	make("seat", Color(0.95, 0.95, 1.0), 0.95, 0.0, "fabric", 0.55, 3.0)
	make("seat_dk", Color(0.32, 0.33, 0.38), 0.95, 0.0, "fabric", 0.55, 3.0)
	make("mattress", Color(0.82, 0.82, 0.80), 0.95)
	make("sack", Color(0.52, 0.45, 0.33), 0.95, 0.0, "fabric", 0.8, 3.0)
	make("plastic", Color(0.10, 0.105, 0.115), 0.5)
	make("rubber", Color(0.035, 0.035, 0.04), 0.9)
	make("wood", Color(0.85, 0.8, 0.75), 0.6, 0.0, "wood", 1.3, 4.0)
	make("concrete", Color(0.78, 0.78, 0.8), 0.9, 0.0, "concrete", 3.2, 5.0)
	make("sleeper", Color(0.5, 0.5, 0.52), 0.9, 0.0, "concrete", 1.0)
	make("brick", Color(0.85, 0.82, 0.8), 0.9, 0.0, "brick", 2.6, 6.0)
	make("corr", Color(0.8, 0.82, 0.84), 0.6, 0.15, "corrugated", 2.6, 6.0)
	make("corr_red", Color(0.62, 0.22, 0.16), 0.6, 0.12, "corrugated", 2.6, 6.0)
	make("corr_blue", Color(0.2, 0.33, 0.5), 0.6, 0.12, "corrugated", 2.6, 6.0)
	make("corr_amber", Color(0.72, 0.5, 0.15), 0.6, 0.12, "corrugated", 2.6, 6.0)
	make("grille", Color(0.14, 0.15, 0.17), 0.5, 0.25, "corrugated", 0.5, 6.0)
	make("rust", Color(0.8, 0.78, 0.76), 0.85, 0.1, "rust", 2.0, 4.0)
	make("snow", Color(0.88, 0.92, 1.0), 0.82, 0.0, "snow", 4.0, 2.0)
	make("ballast", Color(0.72, 0.72, 0.76), 1.0, 0.0, "ballast", 2.0, 6.0)
	make("paving", Color(0.8, 0.8, 0.84), 0.85, 0.0, "paving", 2.6, 3.5)
	var fc: StandardMaterial3D = make("facade", Color(0.75, 0.78, 0.85), 0.85, 0.0, "facade", 14.0)
	fc.emission_enabled = true
	fc.emission_texture = tex("facade_e")
	fc.emission_energy_multiplier = 1.6
	make("pine", Color(0.07, 0.12, 0.10), 0.95)
	make("hill", Color(0.48, 0.53, 0.62), 1.0)
	make("water", Color(0.06, 0.1, 0.13), 0.22, 0.3)
	make("red", Color(0.62, 0.15, 0.11), 0.5, 0.1)
	make("amber_paint", Color(0.82, 0.6, 0.16), 0.55, 0.1)
	make("white_paint", Color(0.88, 0.87, 0.84), 0.6)
	make("soil", Color(0.11, 0.075, 0.05), 1.0)
	make("leaf", Color(0.2, 0.42, 0.14), 0.8)
	make("leaf_lt", Color(0.4, 0.58, 0.22), 0.8)
	make("canvas", Color(0.42, 0.44, 0.36), 0.95, 0.0, "fabric", 1.2, 3.0)
	make("glass_dark", Color(0.03, 0.04, 0.055), 0.08, 0.6)
	var g: StandardMaterial3D = make("glass", Color(0.1, 0.13, 0.15, 0.2), 0.04, 0.2)
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# a diagonal sheen across the panes stands in for sky reflection at no rendering cost
	var gg2 := Gradient.new()
	gg2.offsets = PackedFloat32Array([0.0, 0.4, 0.5, 0.6, 1.0])
	gg2.colors = PackedColorArray([Color(0.1, 0.13, 0.15, 0.2), Color(0.1, 0.13, 0.15, 0.2), Color(0.5, 0.58, 0.64, 0.32), Color(0.1, 0.13, 0.15, 0.2), Color(0.1, 0.13, 0.15, 0.2)])
	var gt2 := GradientTexture2D.new()
	gt2.gradient = gg2
	gt2.fill_from = Vector2(0, 0)
	gt2.fill_to = Vector2(1, 1)
	gt2.width = 64
	gt2.height = 64
	g.albedo_texture = gt2
	g.albedo_color = Color(1, 1, 1, 1)
	g.uv1_scale = Vector3(0.55, 0.55, 1.0)
	make("ice", Color(0.72, 0.84, 0.92), 0.1, 0.0)
	var wi: StandardMaterial3D = make("wetice", Color(0.74, 0.81, 0.87, 0.34), 0.1, 0.0)
	wi.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow("door_led", Color(1.0, 0.65, 0.15), 0.1, Color(0.5, 0.35, 0.1))
	glow("ditch_a", Color(1.0, 0.95, 0.85), 0.1)
	glow("ditch_b", Color(1.0, 0.95, 0.85), 0.1)
	make("icelake", Color(0.5, 0.6, 0.68), 0.16, 0.0, "snow", 9.0)
	make("asphalt", Color(0.2, 0.2, 0.22), 0.95, 0.0, "concrete", 3.0, 3.0)
	make("rock", Color(0.42, 0.43, 0.47), 0.95, 0.0, "concrete", 4.0, 6.0)
	make("bird", Color(0.03, 0.03, 0.035), 0.9)
	glow("blink_a", Color(1.0, 0.1, 0.06), 4.0, Color(0.4, 0.06, 0.05))
	glow("blink_b", Color(1.0, 0.1, 0.06), 0.05, Color(0.4, 0.06, 0.05))
	glow("sig_r", Color(1.0, 0.12, 0.08), 4.0, Color(0.35, 0.06, 0.05))
	glow("sig_g", Color(0.2, 1.0, 0.4), 0.05, Color(0.05, 0.3, 0.12))
	# weapons and first-person arms (texture scales are in metres, so wear reads at arm's length)
	make("gun_blk", Color(0.085, 0.09, 0.098), 0.44, 0.55, "metal", 0.22, 1.6)
	make("gun_steel", Color(0.4, 0.41, 0.43), 0.3, 0.8, "metal", 0.18, 2.0)
	make("gun_worn", Color(0.62, 0.62, 0.64), 0.24, 0.9)
	make("gun_white", Color(0.7, 0.7, 0.68), 0.5, 0.25, "metal", 0.2, 2.0)
	make("gun_poly", Color(0.07, 0.072, 0.078), 0.78, 0.0, "concrete", 0.3, 1.5)
	make("gun_grip", Color(0.16, 0.16, 0.17), 0.9, 0.0, "floor", 0.045, 5.0)
	make("gun_tan", Color(0.55, 0.46, 0.33), 0.72, 0.0, "concrete", 0.28, 2.0)
	make("gun_olive", Color(0.3, 0.34, 0.25), 0.74, 0.0, "concrete", 0.28, 2.0)
	make("gun_wood", Color(0.8, 0.6, 0.45), 0.48, 0.0, "wood", 0.2, 3.0)
	make("gun_rubber", Color(0.03, 0.03, 0.033), 0.95, 0.0, "floor", 0.03, 4.0)
	make("gun_brass", Color(0.78, 0.6, 0.26), 0.3, 0.9)
	make("gun_copper", Color(0.72, 0.4, 0.24), 0.35, 0.85, "metal", 0.1, 2.0)
	make("gun_lens", Color(0.08, 0.13, 0.17), 0.05, 0.7)
	make("gun_shell", Color(0.55, 0.12, 0.1), 0.5)
	var gg: StandardMaterial3D = make("gun_glass", Color(0.35, 0.55, 0.6, 0.14), 0.05)
	gg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gg.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow("gun_dot", Color(1.0, 0.12, 0.06), 3.0, Color(0.5, 0.05, 0.03))
	glow("gun_trit", Color(0.4, 1.0, 0.5), 1.4, Color(0.2, 0.5, 0.25))
	glow("gun_coil", Color(1.0, 0.62, 0.22), 0.6, Color(0.5, 0.3, 0.12))
	make("glove", Color(0.36, 0.31, 0.23), 0.9, 0.0, "fabric", 0.05, 3.0)
	make("glove_pad", Color(0.05, 0.05, 0.055), 0.6, 0.0, "floor", 0.02, 4.0)
	make("sleeve", Color(0.2, 0.225, 0.185), 0.96, 0.0, "fabric", 0.11, 3.0)
	make("sleeve_dk", Color(0.11, 0.125, 0.105), 0.96, 0.0, "fabric", 0.11, 3.0)
	for ck: String in ["glove", "sleeve", "sleeve_dk"]:
		var cmat: StandardMaterial3D = mats[ck]
		cmat.albedo_texture = null
	# train weathering and emergency lighting
	make("grime", Color(0.1, 0.09, 0.08), 0.95)
	make("bark", Color(0.2, 0.17, 0.15), 0.95)
	make("bag", Color(0.05, 0.055, 0.06), 0.45)
	make("stitch", Color(0.78, 0.74, 0.62), 0.9)
	glow("emerg", Color(1.0, 0.25, 0.1), 0.05, Color(0.45, 0.12, 0.08))
	glow("exit", Color(0.25, 1.0, 0.5), 1.6, Color(0.1, 0.4, 0.2))
	glow("light_warm", Color(1.0, 0.83, 0.58), 3.0)
	glow("lamp_warm", Color(1.0, 0.78, 0.48), 4.0)
	glow("lamp_white", Color(0.95, 0.97, 1.0), 0.3)
	glow("lamp_red", Color(1.0, 0.12, 0.08), 2.0, Color(0.5, 0.1, 0.1))
	glow("led_amber", Color(1.0, 0.65, 0.15), 2.5, Color(0.5, 0.35, 0.1))
	glow("led_green", Color(0.3, 1.0, 0.45), 2.0, Color(0.1, 0.4, 0.2))
	glow("screen", Color(0.25, 0.75, 0.62), 0.55, Color(0.02, 0.05, 0.05))
	glow("win_lit", Color(1.0, 0.72, 0.38), 1.6, Color(0.5, 0.4, 0.3))
	glow("grow", Color(1.0, 0.55, 0.85), 2.2)
	glow("fire", Color(1.0, 0.45, 0.1), 5.0, Color(0.6, 0.3, 0.1))
	glow("tag", Color(1.0, 0.7, 0.2), 3.0, Color(0.6, 0.4, 0.1))
	glow("tag_story", Color(0.92, 0.96, 1.0), 3.6, Color(0.6, 0.62, 0.66))

func _tool(mk: String) -> SurfaceTool:
	if not st.has(mk):
		var s := SurfaceTool.new()
		s.begin(Mesh.PRIMITIVE_TRIANGLES)
		st[mk] = s
	return st[mk]

func box(mk: String, c: Vector3, size: Vector3, rot: Basis = Basis.IDENTITY) -> void:
	if default_bevel > 0.0 and minf(size.x, minf(size.y, size.z)) >= bevel_min and maxf(size.x, maxf(size.y, size.z)) <= bevel_max:
		bbox(mk, c, size, rot, default_bevel)
		return
	var s: SurfaceTool = _tool(mk)
	var h := size * 0.5
	var b: Basis = xf.basis * rot
	# baked occlusion: every solid is shaded darker toward its base and on its underside
	var ey: float = maxf(0.0005, absf(rot.x.y) * h.x + absf(rot.y.y) * h.y + absf(rot.z.y) * h.z)
	var lo: float = 1.0 - clampf(ey * 0.5, 0.03, 0.3)
	for fa: Array in FACES:
		var n: Vector3 = fa[0]
		var u: Vector3 = fa[1]
		var v: Vector3 = fa[2]
		var hn: float = absf(n.dot(h))
		var hu: float = absf(u.dot(h))
		var hv: float = absf(v.dot(h))
		var fc: Vector3 = n * hn
		var wn: Vector3 = (b * n).normalized()
		var cu: float = c.dot(u)
		var cv: float = c.dot(v)
		var pts: Array = [fc - u * hu - v * hv, fc + u * hu - v * hv, fc + u * hu + v * hv, fc - u * hu + v * hv]
		var uvs: Array = [Vector2(cu - hu, -(cv - hv)), Vector2(cu + hu, -(cv - hv)), Vector2(cu + hu, -(cv + hv)), Vector2(cu - hu, -(cv + hv))]
		var down: float = 0.8 if (rot * n).y < -0.5 else 1.0
		for i: int in ORDER:
			var p: Vector3 = pts[i]
			var uv: Vector2 = uvs[i]
			var lp: Vector3 = rot * p
			var f: float = lerpf(lo, 1.0, (lp.y + ey) / (2.0 * ey)) * down
			s.set_color(Color(f, f, f))
			s.set_normal(wn)
			s.set_uv(uv)
			s.add_vertex(xf * (c + lp))

func cyl(mk: String, c: Vector3, r: float, h: float, axis: int = 1, seg: int = 10, r2: float = -1.0) -> void:
	var s: SurfaceTool = _tool(mk)
	if r2 < 0.0:
		r2 = r
	var a := Vector3.UP
	var b := Vector3.BACK
	var d := Vector3.RIGHT
	if axis == 0:
		a = Vector3.RIGHT
		b = Vector3.UP
		d = Vector3.BACK
	elif axis == 2:
		a = Vector3.BACK
		b = Vector3.RIGHT
		d = Vector3.UP
	var bot: Vector3 = c - a * h * 0.5
	var top: Vector3 = c + a * h * 0.5
	var na: Vector3 = xf.basis * a
	var cey: float = maxf(0.0005, h * 0.5 if axis == 1 else maxf(r, r2))
	var clo: float = 1.0 - clampf(cey * 0.5, 0.03, 0.3)
	for i in seg:
		var t0: float = TAU * float(i) / float(seg)
		var t1: float = TAU * float(i + 1) / float(seg)
		var d0: Vector3 = b * cos(t0) + d * sin(t0)
		var d1: Vector3 = b * cos(t1) + d * sin(t1)
		var p: Array = [bot + d0 * r, bot + d1 * r, top + d1 * r2, top + d0 * r2]
		var nn: Array = [d0, d1, d1, d0]
		var uu: Array = [Vector2(t0 * r, 0.0), Vector2(t1 * r, 0.0), Vector2(t1 * r, -h), Vector2(t0 * r, -h)]
		for k: int in ORDER:
			var pv: Vector3 = p[k]
			var nv: Vector3 = nn[k]
			var uv: Vector2 = uu[k]
			var cf: float = lerpf(clo, 1.0, clampf((pv.y - c.y + cey) / (2.0 * cey), 0.0, 1.0))
			s.set_color(Color(cf, cf, cf))
			s.set_normal(xf.basis * nv)
			s.set_uv(uv)
			s.add_vertex(xf * pv)
		if r2 > 0.001:
			var tc: Array = [top, top + d1 * r2, top + d0 * r2]
			for q: Vector3 in tc:
				var tf: float = lerpf(clo, 1.0, clampf((q.y - c.y + cey) / (2.0 * cey), 0.0, 1.0))
				s.set_color(Color(tf, tf, tf))
				s.set_normal(na)
				s.set_uv(Vector2(q.dot(b), q.dot(d)))
				s.add_vertex(xf * q)
		var bc: Array = [bot, bot + d0 * r, bot + d1 * r]
		for q: Vector3 in bc:
			var bf: float = lerpf(clo, 1.0, clampf((q.y - c.y + cey) / (2.0 * cey), 0.0, 1.0)) * (0.8 if axis == 1 else 1.0)
			s.set_color(Color(bf, bf, bf))
			s.set_normal(-na)
			s.set_uv(Vector2(q.dot(b), q.dot(d)))
			s.add_vertex(xf * q)

## Emits one triangle, wound so that it faces along n.
func _tri(s: SurfaceTool, pa: Vector3, pb: Vector3, pc: Vector3, n: Vector3, cols: Array, nrm: Array) -> void:
	var pts: Array = [pa, pb, pc]
	var order: Array = [0, 1, 2]
	if (pb - pa).cross(pc - pa).dot(n) > 0.0:
		order = [0, 2, 1]
	for i: int in order:
		var p: Vector3 = pts[i]
		var col: Color = cols[i]
		var nv: Vector3 = nrm[i]
		s.set_color(col)
		s.set_normal((xf.basis * nv).normalized())
		# planar mapping along the face's dominant axis, in metres, like the plain box
		if absf(n.y) >= absf(n.x) and absf(n.y) >= absf(n.z):
			s.set_uv(Vector2(p.x, p.z))
		elif absf(n.x) >= absf(n.z):
			s.set_uv(Vector2(p.z, -p.y))
		else:
			s.set_uv(Vector2(p.x, -p.y))
		s.add_vertex(xf * p)

## A box with its four long edges chamfered: machined and moulded parts instead of sharp slabs.
func bbox(mk: String, c: Vector3, size: Vector3, rot: Basis = Basis.IDENTITY, ch: float = 0.004) -> void:
	var s: SurfaceTool = _tool(mk)
	var h: Vector3 = size * 0.5
	var la := 0
	if size.y >= size.x and size.y >= size.z:
		la = 1
	elif size.z >= size.x and size.z >= size.y:
		la = 2
	var axes: Array = [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	var L: Vector3 = axes[la]
	var A: Vector3 = axes[(la + 1) % 3]
	var B: Vector3 = axes[(la + 2) % 3]
	var hl: float = h[la]
	var ha: float = h[(la + 1) % 3]
	var hb: float = h[(la + 2) % 3]
	var k: float = minf(ch, minf(ha, hb) * 0.56)
	var ring: Array = [Vector2(ha - k, -hb), Vector2(ha, -hb + k), Vector2(ha, hb - k), Vector2(ha - k, hb), Vector2(-ha + k, hb), Vector2(-ha, hb - k), Vector2(-ha, -hb + k), Vector2(-ha + k, -hb)]
	var ey: float = maxf(0.0005, absf(rot.x.y) * h.x + absf(rot.y.y) * h.y + absf(rot.z.y) * h.z)
	var lo: float = 1.0 - clampf(ey * 0.5, 0.03, 0.3)
	var shade := func(lp: Vector3, n: Vector3) -> Color:
		var f: float = lerpf(lo, 1.0, clampf((lp.y + ey) / (2.0 * ey), 0.0, 1.0)) * (0.8 if n.y < -0.5 else 1.0)
		return Color(f, f, f)
	for i in 8:
		var q0: Vector2 = ring[i]
		var q1: Vector2 = ring[(i + 1) % 8]
		var e: Vector2 = q1 - q0
		var n: Vector3 = rot * (A * e.y - B * e.x).normalized()
		var p00: Vector3 = rot * (A * q0.x + B * q0.y - L * hl)
		var p10: Vector3 = rot * (A * q1.x + B * q1.y - L * hl)
		var p01: Vector3 = rot * (A * q0.x + B * q0.y + L * hl)
		var p11: Vector3 = rot * (A * q1.x + B * q1.y + L * hl)
		var cs: Array = [shade.call(p00, n), shade.call(p10, n), shade.call(p11, n), shade.call(p01, n)]
		_tri(s, c + p00, c + p10, c + p11, n, [cs[0], cs[1], cs[2]], [n, n, n])
		_tri(s, c + p00, c + p11, c + p01, n, [cs[0], cs[2], cs[3]], [n, n, n])
	for sd: float in [-1.0, 1.0]:
		var n2: Vector3 = rot * (L * sd)
		var ctr: Vector3 = rot * (L * hl * sd)
		for i in 8:
			var r0: Vector2 = ring[i]
			var r1: Vector2 = ring[(i + 1) % 8]
			var pa: Vector3 = rot * (A * r0.x + B * r0.y + L * hl * sd)
			var pb: Vector3 = rot * (A * r1.x + B * r1.y + L * hl * sd)
			_tri(s, c + ctr, c + pa, c + pb, n2, [shade.call(ctr, n2), shade.call(pa, n2), shade.call(pb, n2)], [n2, n2, n2])

## A smooth ellipsoid: heads, shoulders, knees, anything grown instead of machined.
func ball(mk: String, c: Vector3, rad: Vector3, seg: int = 10, rings: int = 7) -> void:
	var s: SurfaceTool = _tool(mk)
	var lo: float = 1.0 - clampf(rad.y * 0.5, 0.03, 0.3)
	for r in rings:
		var t0: float = PI * float(r) / float(rings)
		var t1: float = PI * float(r + 1) / float(rings)
		for i in seg:
			var a0: float = TAU * float(i) / float(seg)
			var a1: float = TAU * float(i + 1) / float(seg)
			var ds: Array = [Vector3(sin(t0) * cos(a0), cos(t0), sin(t0) * sin(a0)), Vector3(sin(t0) * cos(a1), cos(t0), sin(t0) * sin(a1)), Vector3(sin(t1) * cos(a1), cos(t1), sin(t1) * sin(a1)), Vector3(sin(t1) * cos(a0), cos(t1), sin(t1) * sin(a0))]
			var ps: Array = []
			var ns: Array = []
			var cs: Array = []
			for dv: Vector3 in ds:
				ps.append(c + dv * rad)
				ns.append((dv / rad).normalized())
				var f: float = lerpf(lo, 1.0, dv.y * 0.5 + 0.5)
				cs.append(Color(f, f, f))
			var fn: Vector3 = ds[0] + ds[2]
			_tri(s, ps[0], ps[1], ps[2], fn, [cs[0], cs[1], cs[2]], [ns[0], ns[1], ns[2]])
			_tri(s, ps[0], ps[2], ps[3], fn, [cs[0], cs[2], cs[3]], [ns[0], ns[2], ns[3]])

## A plain coloured material registered for the mesh builder (shaded by the baked occlusion).
static func cmat(color: Color, rough: float = 0.9) -> String:
	var key: String = "c%s_%d" % [color.to_html(false), int(rough * 100.0)]
	if not mats.has(key):
		make(key, color, rough)
	return key

## Points on an elliptical arc, for loft profiles.
static func arc(cx: float, cy: float, rx: float, ry: float, a0: float, a1: float, n: int) -> PackedVector2Array:
	var o := PackedVector2Array()
	for i in n + 1:
		var a: float = lerpf(a0, a1, float(i) / float(n))
		o.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	return o

## Lofts an open 2D profile (x, y) along z with smooth normals: curved roofs, skirts, fairings.
## The outside of the surface is on the left of the direction the points run in.
func loft(mk: String, prof: PackedVector2Array, z0: float, z1: float) -> void:
	var s: SurfaceTool = _tool(mk)
	var n: int = prof.size()
	var nrm: Array = []
	var us: Array = []
	var acc := 0.0
	for i in n:
		var pa: Vector2 = prof[maxi(i - 1, 0)]
		var pb: Vector2 = prof[mini(i + 1, n - 1)]
		var tg: Vector2 = (pb - pa).normalized()
		nrm.append(Vector3(-tg.y, tg.x, 0.0))
		if i > 0:
			var pc: Vector2 = prof[i]
			var pd: Vector2 = prof[i - 1]
			acc += pc.distance_to(pd)
		us.append(acc)
	for i in n - 1:
		var q0: Vector2 = prof[i]
		var q1: Vector2 = prof[i + 1]
		var na: Vector3 = nrm[i]
		var nb: Vector3 = nrm[i + 1]
		var ua: float = us[i]
		var ub: float = us[i + 1]
		var a0 := Vector3(q0.x, q0.y, z0)
		var b0 := Vector3(q1.x, q1.y, z0)
		var a1 := Vector3(q0.x, q0.y, z1)
		var b1 := Vector3(q1.x, q1.y, z1)
		var quad: Array = [[a0, na, Vector2(ua, -z0)], [b0, nb, Vector2(ub, -z0)], [b1, nb, Vector2(ub, -z1)], [a1, na, Vector2(ua, -z1)]]
		var face: Vector3 = (b0 - a0).cross(a1 - a0)
		var order: Array = [0, 1, 2, 0, 2, 3]
		if face.dot(na + nb) > 0.0:
			order = [0, 2, 1, 0, 3, 2]
		for k: int in order:
			var e: Array = quad[k]
			var pv: Vector3 = e[0]
			var nv: Vector3 = e[1]
			var uv: Vector2 = e[2]
			s.set_color(Color.WHITE)
			s.set_normal((xf.basis * nv).normalized())
			s.set_uv(uv)
			s.add_vertex(xf * pv)

## Shifts a profile outward (to the left of the direction its points run in) by dist.
static func offset(prof: PackedVector2Array, dist: float) -> PackedVector2Array:
	var o := PackedVector2Array()
	var n: int = prof.size()
	for i in n:
		var pa: Vector2 = prof[maxi(i - 1, 0)]
		var pb: Vector2 = prof[mini(i + 1, n - 1)]
		var tg: Vector2 = (pb - pa).normalized()
		var p: Vector2 = prof[i]
		o.append(p + Vector2(-tg.y, tg.x) * dist)
	return o

## Flat end caps for a closed profile lofted along z. The profile must be a simple polygon.
func caps(mk: String, prof: PackedVector2Array, z0: float, z1: float) -> void:
	var s: SurfaceTool = _tool(mk)
	var idx: PackedInt32Array = Geometry2D.triangulate_polygon(prof)
	var ends: Array = [[z0, Vector3(0, 0, -1)], [z1, Vector3(0, 0, 1)]]
	for e: Array in ends:
		var z: float = e[0]
		var nv: Vector3 = e[1]
		var i := 0
		while i + 2 < idx.size():
			var q0: Vector2 = prof[idx[i]]
			var q1: Vector2 = prof[idx[i + 1]]
			var q2: Vector2 = prof[idx[i + 2]]
			var a := Vector3(q0.x, q0.y, z)
			var b := Vector3(q1.x, q1.y, z)
			var c := Vector3(q2.x, q2.y, z)
			var tri: Array = [a, b, c]
			if (b - a).cross(c - a).dot(nv) > 0.0:
				tri = [a, c, b]
			for pv: Vector3 in tri:
				s.set_color(Color.WHITE)
				s.set_normal((xf.basis * nv).normalized())
				s.set_uv(Vector2(pv.x, -pv.y))
				s.add_vertex(xf * pv)
			i += 3

func sbox(body: Node, mk: String, c: Vector3, size: Vector3, rot: Basis = Basis.IDENTITY) -> void:
	box(mk, c, size, rot)
	if body == null:
		return
	var t: Transform3D = xf * Transform3D(rot, c)
	Kit.col(body, t.origin, size, t.basis)

func build_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var idx := 0
	for mk: String in st.keys():
		var s: SurfaceTool = st[mk]
		var m: StandardMaterial3D = Kit.mats[mk]
		if m.normal_texture != null:
			s.generate_tangents()
		s.commit(mesh)
		mesh.surface_set_material(idx, m)
		idx += 1
	st.clear()
	return mesh

func commit(parent: Node, shadow: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = build_mesh()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

static func col(body: Node, c: Vector3, size: Vector3, rot: Basis = Basis.IDENTITY) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.transform = Transform3D(rot, c)
	body.add_child(cs)
	return cs

static func interact(parent: Node, c: Vector3, size: Vector3, label: String, cb: Callable) -> Area3D:
	var a := Area3D.new()
	a.collision_layer = 2
	a.collision_mask = 0
	a.monitoring = false
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	a.add_child(cs)
	a.position = c
	a.set_meta("label", label)
	a.set_meta("cb", cb)
	parent.add_child(a)
	return a

static func text3d(parent: Node, pos: Vector3, txt: String, fsize: int, color: Color, yaw: float = 0.0, px: float = 0.004) -> Label3D:
	var l := Label3D.new()
	l.text = txt
	l.font = get_font()
	l.font_size = fsize
	l.pixel_size = px
	l.modulate = color
	l.outline_size = 0
	l.shaded = false
	l.position = pos
	l.rotation.y = yaw
	parent.add_child(l)
	return l

static func omni(parent: Node, pos: Vector3, color: Color, energy: float, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.2
	l.shadow_enabled = false
	l.position = pos
	l.set_meta("r", rng)
	parent.add_child(l)
	return l

static var plains: Dictionary = {}

## The same material without baked-occlusion vertex colours, for engine primitive meshes
## (BoxMesh, PlaneMesh...) which carry no colour data of their own.
static func plain(key: String) -> StandardMaterial3D:
	if not plains.has(key):
		var m: StandardMaterial3D = mats[key].duplicate()
		m.vertex_color_use_as_albedo = false
		plains[key] = m
	return plains[key]

static var pmats: Array = []
static var prop_cache: Dictionary = {}

static func _rel_xf(n: Node3D, root: Node) -> Transform3D:
	var x := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root:
		if cur is Node3D:
			var c3: Node3D = cur
			x = c3.transform * x
		cur = cur.get_parent()
	return x

## An authored glTF prop (Poly Haven, CC0), scaled to fit inside `fit` and standing on y = 0.
static func prop(role: String, fit: Vector3) -> Node3D:
	if not prop_cache.has(role):
		var path := "res://assets/models/props/%s/%s.gltf" % [role, role]
		prop_cache[role] = load(path) if ResourceLoader.exists(path) else null
	if prop_cache[role] == null:
		return null
	var ps: PackedScene = prop_cache[role]
	var holder := Node3D.new()
	var inst: Node3D = ps.instantiate()
	holder.add_child(inst)
	var box := AABB()
	var first := true
	var list: Array = inst.find_children("*", "MeshInstance3D", true, false)
	if inst is MeshInstance3D:
		list.append(inst)
	for mn: Node in list:
		var mi: MeshInstance3D = mn
		var bb: AABB = _rel_xf(mi, inst) * mi.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	if first or box.size.x <= 0.0 or box.size.y <= 0.0 or box.size.z <= 0.0:
		return holder
	var k: float = minf(fit.x / box.size.x, minf(fit.y / box.size.y, fit.z / box.size.z))
	inst.scale = inst.scale * k
	inst.position = inst.position * k - Vector3(box.get_center().x, box.position.y, box.get_center().z) * k
	return holder

static var _soft: GradientTexture2D = null

static func soft_tex() -> GradientTexture2D:
	if _soft == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
		_soft = GradientTexture2D.new()
		_soft.gradient = g
		_soft.fill = GradientTexture2D.FILL_RADIAL
		_soft.fill_from = Vector2(0.5, 0.5)
		_soft.fill_to = Vector2(0.5, 0.0)
		_soft.width = 64
		_soft.height = 64
	return _soft

## Soft billboard particles (smoke, flame, spray). Local coords, so emitters that sit in the
## scrolling world carry their particles with them.
static func particles(parent: Node, pos: Vector3, amount: int, life: float, color: Color, psize: float, additive: bool = false) -> CPUParticles3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	# particle materials take no per-vertex or per-instance colour: tint comes from the material
	# alone and the fade from the size curve, so a bad colour buffer can never tint the scene
	m.vertex_color_use_as_albedo = false
	m.albedo_color = color
	m.albedo_texture = soft_tex()
	m.set_meta("a0", color.a)
	pmats.append(m)
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	# the quad carries its own white vertex colours, so the fade never depends on renderer defaults
	var qst := SurfaceTool.new()
	qst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hq: float = psize * 0.5
	var qp: Array = [Vector3(-hq, -hq, 0), Vector3(hq, -hq, 0), Vector3(hq, hq, 0), Vector3(-hq, hq, 0)]
	var qu: Array = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	for qi: int in [0, 2, 1, 0, 3, 2]:
		var qv: Vector3 = qp[qi]
		var quv: Vector2 = qu[qi]
		qst.set_color(Color.WHITE)
		qst.set_normal(Vector3(0, 0, 1))
		qst.set_uv(quv)
		qst.add_vertex(qv)
	qst.set_material(m)
	var p := CPUParticles3D.new()
	p.mesh = qst.commit()
	p.set_meta("mat", m)
	p.amount = amount
	p.lifetime = life
	p.local_coords = true
	p.direction = Vector3.UP
	p.spread = 10.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 1.6
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	p.color_ramp = g
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.3))
	c.add_point(Vector2(0.35, 1.0))
	c.add_point(Vector2(0.75, 0.9))
	c.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = c
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.position = pos
	parent.add_child(p)
	return p
