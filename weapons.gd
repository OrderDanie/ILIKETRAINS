class_name Arsenal
extends Node3D
## First-person weapon rig: arsenal data, articulated gloved arms, layered procedural motion
## (breathing, sway, bob, ADS, sprint, lowering, recoil) and keyframed actions
## (equip, holster, reload, cycle, inspect) with smooth blending and interruption.

const S := 0.25
const ORDER := ["p9", "kestrel", "stryk", "vesper", "tundra", "harrow", "grendel", "morrow", "halberd", "sable", "northwind", "bastion", "arclight", "riveter"]
const DEFS := {
	"p9": {"name": "VARG P9", "cat": "PISTOL", "ammo": "ammo", "mag": 14, "dmg": 1.0, "rate": 0.16, "auto": false, "spread": 0.012, "pellets": 1, "kick": 1.0, "flip": 1.5, "fov": 62.0, "snd": "shot", "reload": "mag", "rtime": 1.7, "weight": 0.2, "hip": Vector3(0.15, -0.14, -0.5), "adsz": -0.42, "noise": 60.0, "sprint": "pistol", "desc": "Polymer service pistol with a weapon light. Fast handling, light recoil."},
	"kestrel": {"name": "KESTREL .44", "cat": "REVOLVER", "ammo": "ammo_mag", "mag": 6, "dmg": 3.2, "rate": 0.4, "auto": false, "spread": 0.008, "pellets": 1, "kick": 2.4, "flip": 2.4, "fov": 60.0, "snd": "shot_rev", "reload": "rev", "rtime": 2.8, "weight": 0.3, "hip": Vector3(0.15, -0.14, -0.5), "adsz": -0.42, "noise": 75.0, "sprint": "pistol", "desc": "Six-shot magnum revolver. Stops almost anything; slow to reload."},
	"stryk": {"name": "STRYK-9", "cat": "SUBMACHINE GUN", "ammo": "ammo", "mag": 30, "dmg": 0.75, "rate": 0.068, "auto": true, "spread": 0.02, "pellets": 1, "kick": 0.5, "flip": 0.7, "fov": 58.0, "snd": "shot_smg", "reload": "mag", "rtime": 1.9, "weight": 0.4, "hip": Vector3(0.16, -0.17, -0.46), "adsz": -0.5, "noise": 55.0, "sprint": "rifle", "desc": "Compact 9 mm submachine gun with a red dot. High rate of fire at close range."},
	"tundra": {"name": "TUNDRA C4", "cat": "CARBINE", "ammo": "ammo_rifle", "mag": 30, "dmg": 1.1, "rate": 0.082, "auto": true, "spread": 0.014, "pellets": 1, "kick": 0.6, "flip": 0.6, "fov": 50.0, "snd": "shot_ar", "pitch": 1.12, "reload": "mag", "rtime": 2.3, "weight": 0.5, "hip": Vector3(0.16, -0.18, -0.46), "adsz": -0.5, "noise": 65.0, "sprint": "rifle", "desc": "Bullpup carbine with an integrated optic. Short, balanced, quick to aim."},
	"harrow": {"name": "HARROW AR-7", "cat": "ASSAULT RIFLE", "ammo": "ammo_rifle", "mag": 30, "dmg": 1.3, "rate": 0.095, "auto": true, "spread": 0.012, "pellets": 1, "kick": 0.7, "flip": 0.7, "fov": 52.0, "snd": "shot_ar", "reload": "mag", "rtime": 2.2, "weight": 0.55, "hip": Vector3(0.17, -0.19, -0.47), "adsz": -0.5, "noise": 65.0, "sprint": "rifle", "desc": "Modular 5.56 rifle: holographic sight, angled foregrip, light and laser."},
	"morrow": {"name": "MORROW 12", "cat": "SHOTGUN", "ammo": "ammo_shell", "mag": 6, "dmg": 0.7, "rate": 0.25, "auto": false, "spread": 0.05, "pellets": 8, "kick": 2.6, "flip": 1.6, "fov": 62.0, "snd": "shot_sg", "reload": "shell", "rtime": 3.0, "cycle": "pump", "weight": 0.6, "hip": Vector3(0.17, -0.19, -0.5), "adsz": -0.52, "noise": 70.0, "sprint": "rifle", "desc": "Pump-action 12 gauge with a heat shield and side saddle. Devastating up close."},
	"sable": {"name": "SABLE DMR-8", "cat": "MARKSMAN RIFLE", "ammo": "ammo_rifle", "mag": 15, "dmg": 2.6, "rate": 0.24, "auto": false, "spread": 0.004, "pellets": 1, "kick": 1.3, "flip": 0.9, "fov": 26.0, "scope": true, "snd": "shot_dmr", "reload": "mag", "rtime": 2.5, "weight": 0.7, "hip": Vector3(0.17, -0.2, -0.48), "adsz": -0.4, "noise": 20.0, "sprint": "rifle", "desc": "Suppressed semi-automatic 7.62 with a scope. Quiet: draws far less attention."},
	"northwind": {"name": "NORTHWIND .338", "cat": "PRECISION RIFLE", "ammo": "ammo_mag", "mag": 5, "dmg": 7.0, "rate": 0.3, "auto": false, "spread": 0.001, "pellets": 1, "kick": 3.0, "flip": 1.2, "fov": 15.0, "scope": true, "snd": "shot_snp", "reload": "mag", "rtime": 3.0, "cycle": "bolt", "weight": 0.85, "hip": Vector3(0.17, -0.2, -0.5), "adsz": -0.42, "noise": 90.0, "sprint": "heavy", "desc": "Bolt-action .338 with a high-power scope. One round, one target."},
	"bastion": {"name": "BASTION MG-62", "cat": "MACHINE GUN", "ammo": "ammo_rifle", "mag": 100, "dmg": 1.5, "rate": 0.085, "auto": true, "spread": 0.02, "pellets": 1, "kick": 0.85, "flip": 0.5, "fov": 54.0, "snd": "shot_lmg", "reload": "belt", "rtime": 4.6, "weight": 1.0, "hip": Vector3(0.17, -0.21, -0.48), "adsz": -0.5, "noise": 80.0, "sprint": "heavy", "desc": "Belt-fed machine gun. A hundred rounds before the long reload."},
	"vesper": {"name": "VESPER PDW", "cat": "DEFENCE WEAPON", "ammo": "ammo", "mag": 40, "dmg": 0.6, "rate": 0.055, "auto": true, "spread": 0.024, "pellets": 1, "kick": 0.4, "flip": 0.6, "fov": 58.0, "snd": "shot_smg", "pitch": 1.25, "reload": "mag", "rtime": 1.8, "weight": 0.35, "hip": Vector3(0.16, -0.17, -0.46), "adsz": -0.5, "noise": 50.0, "sprint": "rifle", "desc": "Compact 9 mm with the magazine in the grip, a suppressor shroud and a holographic sight. The fastest-firing weapon on the line."},
	"grendel": {"name": "GRENDEL BR-10", "cat": "BATTLE RIFLE", "ammo": "ammo_rifle", "mag": 20, "dmg": 2.0, "rate": 0.13, "auto": true, "spread": 0.01, "pellets": 1, "kick": 1.15, "flip": 1.0, "fov": 46.0, "snd": "shot_ar", "pitch": 0.85, "reload": "mag", "rtime": 2.4, "weight": 0.68, "hip": Vector3(0.17, -0.19, -0.48), "adsz": -0.5, "noise": 72.0, "sprint": "rifle", "desc": "Wood and stamped steel, full-power 7.62. Hits half as hard again as the Harrow, with the recoil to match."},
	"halberd": {"name": "HALBERD AS-12", "cat": "AUTO SHOTGUN", "ammo": "ammo_shell", "mag": 12, "dmg": 0.6, "rate": 0.2, "auto": true, "spread": 0.06, "pellets": 8, "kick": 2.0, "flip": 1.3, "fov": 62.0, "snd": "shot_sg", "pitch": 1.1, "reload": "mag", "rtime": 2.9, "weight": 0.75, "hip": Vector3(0.17, -0.2, -0.5), "adsz": -0.52, "noise": 75.0, "sprint": "heavy", "desc": "Drum-fed automatic 12 gauge. Twelve shells as fast as you can hold the trigger."},
	"riveter": {"name": "RIVETER PR-3", "cat": "IMPROVISED", "ammo": "scrap", "per": 10, "mag": 20, "dmg": 1.6, "rate": 0.22, "auto": true, "spread": 0.02, "pellets": 1, "kick": 0.9, "flip": 0.5, "fov": 60.0, "snd": "shot_rivet", "reload": "mag", "rtime": 2.6, "weight": 0.6, "hip": Vector3(0.18, -0.2, -0.52), "adsz": -0.5, "noise": 20.0, "sprint": "rifle", "desc": "A track gang's pneumatic rivet gun, rebuilt as a weapon. Very quiet, and it feeds on Scrap Metal: ten rivets a piece."},
	"arclight": {"name": "ARCLIGHT Mk I", "cat": "EXPERIMENTAL", "ammo": "batteries", "per": 5, "pierce": true, "mag": 5, "dmg": 9.0, "rate": 0.9, "auto": false, "spread": 0.0, "pellets": 1, "kick": 1.8, "flip": 0.4, "fov": 44.0, "snd": "shot_coil", "reload": "mag", "rtime": 3.2, "weight": 0.75, "hip": Vector3(0.17, -0.2, -0.48), "adsz": -0.5, "noise": 50.0, "sprint": "rifle", "desc": "Prototype coil rifle. Each Battery Cell gives five slugs that pass straight through a target."},
}
const POSES := {
	"grip": [[20, 25, 10], [78, 88, 35], [80, 90, 35], [82, 90, 38], [12, 18]],
	"trig": [[44, 60, 25], [78, 88, 35], [80, 90, 35], [82, 90, 38], [12, 18]],
	"under": [[55, 60, 28], [58, 62, 30], [60, 62, 30], [62, 64, 32], [4, 16]],
	"cup": [[68, 74, 30], [70, 76, 30], [72, 76, 32], [74, 78, 34], [0, 10]],
	"open": [[6, 8, 5], [8, 10, 6], [10, 12, 6], [14, 14, 8], [-12, 4]],
	"pinch": [[46, 52, 24], [48, 54, 26], [52, 56, 28], [60, 60, 30], [30, 28]],
}
const SPRINTS := {"pistol": [Vector3(-0.03, -0.06, 0.1), Vector3(42, 18, 12)], "rifle": [Vector3(-0.1, -0.05, 0.08), Vector3(10, 52, 12)], "heavy": [Vector3(-0.08, -0.1, 0.1), Vector3(-14, 44, 8)]}
const R_WRIST := Vector3(0.016, -0.045, 0.088)
const ELBOW_R := Vector3(0.36, -0.62, 0.02)
const ELBOW_L := Vector3(-0.36, -0.66, -0.08)
const LP_DEF := Vector3(-0.22, -0.26, -0.34)
const Z := Vector3.ZERO
const FORE := 0.33
const SHOULDER_R := Vector3(0.28, -0.5, 0.5)
const SHOULDER_L := Vector3(-0.3, -0.5, 0.5)
const REACH_T := 0.62
const REACH_P := Vector3(-0.05, -0.1, -0.56)

var main
var rig: Node3D
var pivot: Node3D
var model: Dictionary = {}
var parts: Dictionary = {}
var rhand: Dictionary = {}
var lhand: Dictionary = {}
var rarm: Node3D
var larm: Node3D
var ruarm: Node3D
var luarm: Node3D
var reach_t := 0.0
var inert := 0.0
var prev_fwd := 0.0
var light: OmniLight3D
var flash_l: OmniLight3D
var flash_m: Node3D
var smoke: CPUParticles3D
var shells: Array = []
var shell_i := 0
var cur := ""
var d: Dictionary = {}
var r_base := Transform3D.IDENTITY
var l_base := Transform3D.IDENTITY
var l_free := Basis.IDENTITY
var l_pose := "under"
var tracks: Dictionary = {}
var events: Array = []
var vals: Dictionary = {}
var anim_name := ""
var anim_t := 0.0
var anim_len := 0.0
var anim_w := 0.0
var anim_out := false
var anim_speed := 1.0
var ev_i := 0
var queued := ""
var pending := ""
var ads := 0.0
var spr := 0.0
var low := 1.0
var raised_t := 0.0
var scope_a := 0.0
var spread_now := 0.0
var bloom := 0.0
var rec_p := Vector3.ZERO
var rec_v := Vector3.ZERO
var rec_r := Vector3.ZERO
var rec_rv := Vector3.ZERO
var sway := Vector2.ZERO
var look_acc := Vector2.ZERO
var bob_t := 0.0
var t := 0.0
var cd := 0.0
var trig_e := 0.0
var bolt_kick := 0.0
var flash_t := 0.0
var coil_t := 9.0
var shots := 0
var fire_held := false
var fire_pressed := false
var aim_held := false
var force_ads := false
var fast := false
var lean := 0.0

func _ready() -> void:
	scale = Vector3(S, S, S)
	rig = Node3D.new()
	add_child(rig)
	pivot = Node3D.new()
	pivot.position = Vector3(0, -0.02, -0.03)
	rig.add_child(pivot)
	rhand = _build_hand(1.0)
	lhand = _build_hand(-1.0)
	rig.add_child(rhand["node"])
	rig.add_child(lhand["node"])
	r_base = Transform3D(_hand_basis(Vector3(-0.05, 0.1, -1.0), Vector3(-1, 0, 0), 1.0), R_WRIST)
	l_free = _hand_basis(Vector3(0.25, 0.35, -0.9), Vector3(0.9, 0.2, 0.3), -1.0)
	rarm = _build_arm(false)
	larm = _build_arm(true)
	ruarm = _build_upper()
	luarm = _build_upper()
	light = Kit.omni(self, Vector3(-0.3, 0.2, -0.3), Color(1.0, 0.95, 0.86), 0.0, 0.7)
	light.omni_attenuation = 0.8
	flash_l = Kit.omni(self, Vector3(0.15, -0.1, -0.9), Color(1.0, 0.78, 0.45), 0.0, 9.0)
	flash_m = Node3D.new()
	add_child(flash_m)
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fm.cull_mode = BaseMaterial3D.CULL_DISABLED
	fm.albedo_texture = Kit.soft_tex()
	fm.albedo_color = Color(1.0, 0.72, 0.36, 0.95)
	for i in 3:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.2, 0.09) if i < 2 else Vector2(0.13, 0.13)
		q.mesh = qm
		q.material_override = fm
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if i == 0:
			q.rotation = Vector3(0, PI * 0.5, 0)
			q.position.z = -0.08
		elif i == 1:
			q.rotation = Vector3(PI * 0.5, PI * 0.5, 0)
			q.position.z = -0.08
		flash_m.add_child(q)
	flash_m.visible = false
	smoke = Kit.particles(self, Vector3.ZERO, 8, 0.7, Color(0.75, 0.75, 0.78, 0.22), 0.07)
	smoke.emitting = false
	smoke.initial_velocity_min = 0.15
	smoke.initial_velocity_max = 0.35
	var brass := CylinderMesh.new()
	brass.top_radius = 0.0045
	brass.bottom_radius = 0.0045
	brass.height = 0.022
	brass.radial_segments = 6
	for i in 8:
		var sm := MeshInstance3D.new()
		sm.mesh = brass
		sm.material_override = Kit.plain("gun_brass")
		sm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sm.visible = false
		add_child(sm)
		shells.append({"node": sm, "v": Vector3.ZERO, "life": 0.0, "w": Vector3.ZERO})

# ---------------- hands and arms ----------------
func _hand_basis(f: Vector3, p: Vector3, sgn: float) -> Basis:
	var z: Vector3 = -f.normalized()
	var x: Vector3 = -sgn * p
	x = (x - z * x.dot(z)).normalized()
	return Basis(x, z.cross(x), z)

func _seg(parent: Node3D, pos: Vector3, length: float, th: float, mat: String) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	var mi := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = th * 0.5
	bm.height = length + th * 0.7
	bm.radial_segments = 8
	bm.rings = 3
	mi.mesh = bm
	mi.rotation.x = PI * 0.5
	mi.position.z = -length * 0.5
	mi.material_override = Kit.plain(mat)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(mi)
	return n

func _build_hand(sgn: float) -> Dictionary:
	var n := Node3D.new()
	var mb := Kit.new()
	mb.bbox("glove", Vector3(sgn * 0.014, 0, -0.047), Vector3(0.028, 0.084, 0.094), Basis.IDENTITY, 0.011)
	mb.bbox("glove_pad", Vector3(sgn * 0.0295, 0.004, -0.058), Vector3(0.005, 0.066, 0.05), Basis.IDENTITY, 0.002)
	mb.box("glove_pad", Vector3(sgn * -0.001, -0.012, -0.05), Vector3(0.003, 0.056, 0.06))
	mb.cyl("glove_pad", Vector3(sgn * 0.03, 0.0, -0.09), 0.009, 0.078, 1, 8)
	mb.cyl("glove", Vector3(sgn * 0.014, 0, 0.012), 0.034, 0.046, 2, 12, 0.031)
	mb.cyl("glove_pad", Vector3(sgn * 0.014, 0, 0.022), 0.0355, 0.014, 2, 12)
	mb.bbox("gun_worn", Vector3(sgn * 0.03, 0.02, 0.022), Vector3(0.009, 0.012, 0.012), Basis.IDENTITY, 0.003)
	mb.commit(n, false)
	var fingers: Array = []
	var lens: Array = [[0.04, 0.026, 0.022], [0.044, 0.028, 0.023], [0.041, 0.027, 0.022], [0.033, 0.022, 0.02]]
	for i in 4:
		var ln: Array = lens[i]
		var p1: Node3D = _seg(n, Vector3(sgn * 0.014, 0.0315 - float(i) * 0.021, -0.094), float(ln[0]), 0.0185, "glove")
		var p2: Node3D = _seg(p1, Vector3(0, 0, -float(ln[0])), float(ln[1]), 0.0175, "glove")
		var p3: Node3D = _seg(p2, Vector3(0, 0, -float(ln[1])), float(ln[2]), 0.0165, "glove_pad")
		fingers.append([p1, p2, p3])
	var tb := Basis.looking_at(Vector3(-sgn * 0.5, 0.22, -0.84).normalized(), Vector3.UP)
	var t1: Node3D = _seg(n, Vector3(sgn * 0.006, 0.046, -0.028), 0.038, 0.021, "glove")
	var t2: Node3D = _seg(t1, Vector3(0, 0, -0.038), 0.03, 0.019, "glove_pad")
	return {"node": n, "f": fingers, "t": [t1, t2], "tb": tb, "sgn": sgn}

func _tube(mb: Kit, mk: String, y0: float, y1: float, r0: float, r1: float, zs: float = 1.0) -> void:
	var keep: Transform3D = mb.xf
	mb.xf = keep * Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 1.0, zs)), Vector3.ZERO)
	mb.cyl(mk, Vector3(0, (y0 + y1) * 0.5, 0), r0, y1 - y0, 1, 12, r1)
	mb.xf = keep

## Forearm from the wrist (origin) to the elbow: narrow at the cuff, fullest a third of the way up.
func _build_arm(left: bool) -> Node3D:
	var n := Node3D.new()
	add_child(n)
	var mb := Kit.new()
	_tube(mb, "glove", -0.005, 0.045, 0.029, 0.027, 0.84)
	_tube(mb, "glove_pad", 0.026, 0.042, 0.0305, 0.0305, 0.84)
	mb.bbox("gun_worn", Vector3(0.0, 0.034, 0.027), Vector3(0.014, 0.012, 0.006), Basis.IDENTITY, 0.002)
	_tube(mb, "sleeve_dk", 0.04, 0.064, 0.0295, 0.031, 0.88)
	_tube(mb, "sleeve", 0.06, 0.14, 0.029, 0.037, 0.9)
	_tube(mb, "sleeve", 0.14, 0.24, 0.037, 0.0395, 0.93)
	_tube(mb, "sleeve", 0.24, FORE, 0.0395, 0.037, 0.95)
	mb.ball("sleeve", Vector3(0, FORE, 0), Vector3(0.039, 0.042, 0.039), 10, 6)
	# cloth, not pipe: creases gathered at the cuff and the elbow, a seam, a patch pocket
	var folds: Array = [[0.078, 0.0335, 0.12], [0.098, 0.0355, -0.16], [0.128, 0.038, 0.1], [0.262, 0.0412, -0.14], [0.286, 0.0405, 0.18], [0.308, 0.0395, -0.1]]
	var keep: Transform3D = mb.xf
	for f: Array in folds:
		mb.xf = keep * Transform3D(Basis(Vector3.BACK, float(f[2])) * Basis.IDENTITY.scaled(Vector3(1.0, 1.0, 0.92)), Vector3(0, float(f[0]), 0))
		mb.cyl("sleeve_dk", Vector3.ZERO, float(f[1]), 0.007, 1, 12, float(f[1]) - 0.0012)
	mb.xf = keep
	mb.box("sleeve_dk", Vector3(0.0, 0.19, -0.0362), Vector3(0.006, 0.26, 0.004))
	mb.bbox("sleeve_dk", Vector3(0.0, 0.2, 0.0365), Vector3(0.04, 0.075, 0.008), Basis.IDENTITY, 0.003)
	mb.box("gun_worn", Vector3(0.0, 0.23, 0.0412), Vector3(0.008, 0.008, 0.004))
	if left:
		_tube(mb, "gun_rubber", 0.158, 0.178, 0.0385, 0.039, 0.93)
		mb.bbox("gun_blk", Vector3(0, 0.168, 0.0365), Vector3(0.032, 0.034, 0.008), Basis.IDENTITY, 0.003)
		mb.box("screen", Vector3(0, 0.168, 0.041), Vector3(0.024, 0.024, 0.001))
	mb.commit(n, false)
	return n

func _build_upper() -> Node3D:
	var n := Node3D.new()
	add_child(n)
	var mb := Kit.new()
	_tube(mb, "sleeve", 0.0, 0.5, 0.039, 0.052, 1.0)
	_tube(mb, "sleeve_dk", 0.06, 0.068, 0.0415, 0.0415, 1.0)
	_tube(mb, "sleeve_dk", 0.2, 0.208, 0.0455, 0.0455, 1.0)
	mb.commit(n, false)
	return n

func reach() -> void:
	if reach_t <= 0.0:
		reach_t = REACH_T

func _mix(a: Array, b: Array, w: float) -> Array:
	var o: Array = []
	for i in a.size():
		var fa: Array = a[i]
		var fb: Array = b[i]
		var r: Array = []
		for j in fa.size():
			r.append(lerpf(float(fa[j]), float(fb[j]), w))
		o.append(r)
	return o

func _apply_pose(hand: Dictionary, pose: Array) -> void:
	var sgn: float = hand["sgn"]
	var fingers: Array = hand["f"]
	for i in 4:
		var nodes: Array = fingers[i]
		var ang: Array = pose[i]
		for j in 3:
			var nd: Node3D = nodes[j]
			nd.rotation.y = sgn * deg_to_rad(float(ang[j]))
	var th: Array = hand["t"]
	var ta: Array = pose[4]
	var tb: Basis = hand["tb"]
	var t1: Node3D = th[0]
	var t2: Node3D = th[1]
	t1.basis = tb * Basis(Vector3.UP, sgn * deg_to_rad(float(ta[0])))
	t2.rotation.y = sgn * deg_to_rad(float(ta[1]))

# ---------------- weapon lifecycle ----------------
func owned() -> Array:
	var o: Array = []
	for id: String in ORDER:
		if GS.weapons.has(id):
			o.append(id)
	return o

func mag() -> int:
	return int(GS.weapons.get(cur, 0))

func reserve() -> int:
	if cur == "":
		return 0
	return GS.count(GS.inv, str(d["ammo"])) * int(d.get("per", 1))

func equip_now(id: String) -> void:
	if not DEFS.has(id):
		id = "p9"
	if model.has("node"):
		var old: Node3D = model["node"]
		old.queue_free()
	cur = id
	GS.cur_weapon = id
	d = DEFS[id]
	model = Gunsmith.build(id)
	var node: Node3D = model["node"]
	node.position = -pivot.position
	node.scale = Vector3(0.86, 1.0, 1.0)
	pivot.add_child(node)
	parts = model["parts"]
	for k: String in parts.keys():
		var pn: Node3D = parts[k]
		pn.set_meta("p0", pn.position)
		pn.set_meta("r0", pn.rotation)
	var lh: Vector3 = model["lh"]
	match str(model["lstyle"]):
		"cup":
			var b: Basis = _hand_basis(Vector3(0.72, 0.3, -0.62), Vector3(0.6, 0.05, 0.8), -1.0)
			l_base = Transform3D(b, lh - b * Vector3(0, 0, -0.05))
			l_pose = "cup"
		"vert":
			var b2: Basis = _hand_basis(Vector3(0.08, 0.12, -1.0), Vector3(1, 0, 0), -1.0)
			l_base = Transform3D(b2, lh + Vector3(-0.016, -0.04, 0.086))
			l_pose = "grip"
		_:
			var p: Vector3 = Vector3(0.38, 0.9, 0.12).normalized()
			var b3: Basis = _hand_basis(Vector3(0.62, 0.1, -0.78), p, -1.0)
			l_base = Transform3D(b3, lh - b3 * Vector3(0, 0, -0.05) - p * 0.024)
			l_pose = "under"
	bolt_kick = 0.0
	rec_p = Vector3.ZERO
	rec_r = Vector3.ZERO
	_play("equip", _anim_equip(), false)
	anim_w = 1.0

func switch_to(id: String) -> void:
	if id == cur or not GS.weapons.has(id) or not DEFS.has(id):
		return
	pending = id
	raised_t = 6.0
	if anim_name == "holster":
		return
	_play("holster", _anim_holster(), false)
	anim_w = 1.0

func cycle_weapon(dir: int) -> void:
	var o: Array = owned()
	if o.size() < 2:
		return
	var base: String = pending if anim_name == "holster" else cur
	var i: int = o.find(base)
	switch_to(str(o[posmod(i + dir, o.size())]))

func select_slot(i: int) -> void:
	var o: Array = owned()
	if i >= 0 and i < o.size():
		switch_to(str(o[i]))

func blocking() -> bool:
	return anim_name == "reload" or anim_name == "equip" or anim_name == "holster" or anim_name == "cycle"

func cancel_inspect() -> void:
	if anim_name == "inspect":
		anim_out = true

func start_inspect() -> void:
	if cur == "" or blocking() or anim_name == "inspect" or main.player.seated:
		return
	raised_t = 12.0
	if low > 0.3:
		queued = "inspect"
		return
	_play("inspect", _anim_inspect(), true)

func start_reload() -> void:
	if cur == "" or blocking():
		return
	if mag() >= int(d["mag"]):
		return
	if reserve() <= 0:
		var it: Dictionary = GS.ITEMS[d["ammo"]]
		GS.say("No %s. Check the train stores or an armoury." % it["name"], "warn")
		return
	raised_t = 6.0
	if anim_name == "inspect":
		queued = "reload"
		anim_out = true
		return
	_play("reload", _anim_reload(mag() <= 0), true)

func add_look(rel: Vector2) -> void:
	look_acc += rel

# ---------------- keyframe engine ----------------
func _play(aname: String, rows: Array, end_zero: bool) -> void:
	tracks = {}
	events = []
	vals = {}
	var prev_t := 0.0
	for row: Array in rows:
		var tt: float = row[0]
		var dct: Dictionary = row[1]
		for k: String in dct.keys():
			if k == "snd" or k == "ev":
				events.append([tt, k, dct[k]])
				continue
			if not tracks.has(k):
				var fresh: Array = []
				if tt > 0.0 and k != "lp" and k != "lq":
					if typeof(dct[k]) == TYPE_VECTOR3:
						fresh.append([prev_t, Vector3.ZERO])
					else:
						fresh.append([prev_t, 0.0])
				tracks[k] = fresh
			var ks: Array = tracks[k]
			ks.append([tt, dct[k]])
		prev_t = tt
	anim_len = prev_t
	if end_zero:
		for k: String in tracks.keys():
			var ks2: Array = tracks[k]
			var last: Array = ks2[ks2.size() - 1]
			if float(last[0]) < anim_len - 0.0001:
				if k == "spin" or k == "cspin" or k == "mr" or k == "lp" or k == "lq":
					ks2.append([anim_len, last[1]])
				elif typeof(last[1]) == TYPE_VECTOR3:
					ks2.append([anim_len, Vector3.ZERO])
				else:
					ks2.append([anim_len, 0.0])
	anim_name = aname
	anim_t = 0.0
	anim_w = 0.0
	anim_out = false
	anim_speed = 1.0
	ev_i = 0

func _sample(ch: String, tt: float) -> Variant:
	var ks: Array = tracks[ch]
	var n: int = ks.size()
	var first: Array = ks[0]
	if n == 1 or tt <= float(first[0]):
		return first[1]
	for i in range(1, n):
		var b: Array = ks[i]
		if tt <= float(b[0]):
			var a: Array = ks[i - 1]
			var at: float = a[0]
			var f: float = (tt - at) / maxf(0.0001, float(b[0]) - at)
			if ch == "wp" or ch == "wr" or ch == "cr":
				var pre: Array = ks[maxi(i - 2, 0)]
				var post: Array = ks[mini(i + 1, n - 1)]
				var va: Vector3 = a[1]
				var vb: Vector3 = b[1]
				var vp: Vector3 = pre[1]
				var vq: Vector3 = post[1]
				return va.cubic_interpolate_in_time(vb, vp, vq, f, float(b[0]) - at, float(pre[0]) - at, float(post[0]) - at)
			f = f * f * (3.0 - 2.0 * f)
			return lerp(a[1], b[1], f)
	var last: Array = ks[n - 1]
	return last[1]

func chf(k: String) -> float:
	return float(vals.get(k, 0.0)) * anim_w

func chv(k: String) -> Vector3:
	var v: Variant = vals.get(k, Vector3.ZERO)
	var vv: Vector3 = v
	return vv * anim_w

func _event(kind: String, arg: String) -> void:
	if kind == "snd":
		main.sfx.play(arg, -7.0, randf_range(0.96, 1.04))
		return
	match arg:
		"fill":
			var need: int = int(d["mag"]) - mag()
			var per: int = int(d.get("per", 1))
			var items: int = mini(int(ceil(float(need) / float(per))), GS.count(GS.inv, str(d["ammo"])))
			GS.take(GS.inv, str(d["ammo"]), items)
			GS.weapons[cur] = mag() + mini(need, items * per)
		"shell":
			_eject()
		"shells6":
			for i in 6:
				_eject()

func _anim_end() -> void:
	var was := anim_name
	anim_name = ""
	tracks = {}
	vals = {}
	anim_w = 0.0
	if was == "holster":
		equip_now(pending)
		return
	var q := queued
	queued = ""
	if q == "reload":
		start_reload()
	elif q == "inspect":
		start_inspect()

# ---------------- firing ----------------
func muzzle_world() -> Vector3:
	var node: Node3D = model["node"]
	var m: Vector3 = model["muzzle"]
	return node.global_transform * m

func _eject() -> void:
	if not model.has("node"):
		return
	var node: Node3D = model["node"]
	var e: Vector3 = model["eject"]
	var sh: Dictionary = shells[shell_i]
	shell_i = (shell_i + 1) % shells.size()
	var sn: MeshInstance3D = sh["node"]
	sn.position = to_local(node.global_transform * e)
	var big: bool = cur == "morrow" or cur == "halberd"
	sn.scale = Vector3(2.3, 2.4, 2.3) if big else (Vector3(1.4, 2.6, 1.4) if (cur == "northwind" or cur == "kestrel") else Vector3.ONE)
	sn.material_override = Kit.plain("gun_shell") if big else Kit.plain("gun_brass")
	sn.visible = true
	var side: float = -1.0 if cur == "kestrel" else 1.0
	sh["v"] = Vector3(side * randf_range(1.1, 1.9), randf_range(0.9, 1.6), randf_range(0.1, 0.6)) * (0.35 if cur == "kestrel" else 1.0)
	sh["w"] = Vector3(randf_range(-20, 20), randf_range(-20, 20), randf_range(-20, 20))
	sh["life"] = 0.7

func _try_fire() -> void:
	raised_t = 5.0
	if cur == "" or main.player.seated:
		return
	if anim_name == "inspect":
		anim_out = true
		return
	if blocking() or anim_w > 0.3 or low > 0.35 or spr > 0.5 or cd > 0.0:
		return
	if mag() <= 0:
		cd = 0.3
		if reserve() > 0:
			start_reload()
		else:
			main.sfx.play("w_click", -4.0)
			var it: Dictionary = GS.ITEMS[d["ammo"]]
			GS.say("Empty. No %s carried." % it["name"], "warn")
		return
	fire_now()

func fire_now() -> void:
	var p: PlayerRig = main.player
	GS.weapons[cur] = mag() - 1
	cd = float(d["rate"])
	shots += 1
	var k: float = d["kick"]
	var ae: float = smoothstep(0.0, 1.0, ads)
	main.sfx.play(str(d["snd"]), float(d.get("db", 0.0)), float(d.get("pitch", 1.0)) * randf_range(0.96, 1.04))
	main.noise(p.global_position, float(d["noise"]))
	var rk: float = k * lerpf(1.0, 0.6, ae)
	rec_v += Vector3(randf_range(-0.12, 0.12) * rk, 0.3 * rk, 1.15 * rk)
	rec_rv += Vector3(150.0 * rk * float(d["flip"]), randf_range(-40.0, 40.0) * rk, randf_range(-70.0, 70.0) * rk)
	p.view_kick += 0.011 * k
	p.pitch = clampf(p.pitch + 0.0035 * k, -1.45, 1.45)
	p.yaw += randf_range(-0.002, 0.002) * k
	trig_e = 1.0
	if parts.has("bolt") and not d.has("cycle"):
		bolt_kick = 1.0
	flash_t = 0.05
	flash_m.visible = scope_a < 0.5
	flash_m.rotation.z = randf() * TAU
	var fs: float = (0.45 if cur == "sable" else (0.22 if cur == "riveter" else 1.0)) * randf_range(0.8, 1.25) * (1.5 if cur == "morrow" or cur == "northwind" or cur == "halberd" else 1.0)
	flash_m.scale = Vector3(fs, fs, fs)
	flash_l.light_energy = 1.2 if cur == "sable" else (0.5 if cur == "riveter" else 5.0)
	flash_l.light_color = Color(1.0, 0.75, 0.4) if cur != "arclight" else Color(0.6, 0.8, 1.0)
	smoke.emitting = true
	coil_t = 0.0
	if not d.has("cycle") and cur != "kestrel" and cur != "arclight" and cur != "riveter":
		_eject()
	var sp: float = float(d["spread"]) * lerpf(1.0, 0.12, ae) + bloom * lerpf(1.0, 0.35, ae) + (0.02 if spr > 0.2 else 0.0)
	var hv: float = Vector2(p.velocity.x, p.velocity.z).length()
	sp += hv * 0.0035 * (1.0 - 0.6 * ae)
	var cb: Basis = p.cam.global_transform.basis
	var from: Vector3 = p.cam.global_position
	var mz: Vector3 = muzzle_world()
	for i in int(d["pellets"]):
		var dir: Vector3 = (-cb.z + cb.x * randf_range(-sp, sp) + cb.y * randf_range(-sp, sp)).normalized()
		main.shot(from, dir, float(d["dmg"]), mz, i == 0, d.has("pierce"))
	bloom = minf(0.05, bloom + float(d["spread"]) * 0.35 + 0.002)
	if d.has("cycle") and mag() > 0:
		_play("cycle", _anim_cycle(), true)
	elif d.has("cycle"):
		_eject()

# ---------------- per-frame update ----------------
func update(dt: float) -> void:
	t += dt
	if cur == "" or main == null:
		return
	var p: PlayerRig = main.player
	var wgt: float = d["weight"]
	cd = maxf(0.0, cd - dt)
	raised_t = maxf(0.0, raised_t - dt)
	bloom = maxf(0.0, bloom - dt * 0.09)
	if fire_pressed or (fire_held and bool(d["auto"])):
		_try_fire()
	fire_pressed = false
	var want_aim: bool = (aim_held or force_ads) and not p.seated
	if want_aim:
		raised_t = maxf(raised_t, 3.0)
		if anim_name == "inspect":
			anim_out = true
	var sprinting: bool = p.sprinting and not p.seated
	if sprinting and anim_name == "inspect":
		anim_out = true
	if anim_name == "inspect":
		raised_t = maxf(raised_t, 2.0)
	var want_low: bool = p.seated or (main.aboard and GS.under_attack <= 0.0 and raised_t <= 0.0 and not blocking())
	low = move_toward(low, 1.0 if want_low else 0.0, dt * (3.4 - 1.4 * wgt))
	spr = move_toward(spr, 1.0 if (sprinting and not want_low) else 0.0, dt * 5.0)
	var can_aim: bool = want_aim and not blocking() and not sprinting and low < 0.4 and (anim_name == "" or anim_w < 0.3)
	ads = move_toward(ads, 1.0 if can_aim else 0.0, dt / (0.15 + 0.22 * wgt))
	var ae: float = smoothstep(0.0, 1.0, ads)
	var se: float = smoothstep(0.0, 1.0, spr)
	var le: float = smoothstep(0.0, 1.0, low)
	scope_a = smoothstep(0.82, 1.0, ads) if d.has("scope") else 0.0
	var base_fov: float = GS.settings["fov"]
	p.cam.fov = lerpf(base_fov, base_fov * float(d["fov"]) / 75.0, ae)
	if queued != "" and anim_name == "" and low < 0.3:
		var q := queued
		queued = ""
		if q == "inspect":
			start_inspect()
		else:
			start_reload()
	# --- keyframed action
	if anim_name != "":
		if anim_out:
			anim_w = move_toward(anim_w, 0.0, dt * 6.5)
		elif anim_name != "equip" and anim_name != "holster":
			anim_w = move_toward(anim_w, 1.0, dt * 10.0)
		anim_t += dt * (30.0 if (fast and anim_speed > 0.0) else anim_speed)
		while not anim_out and ev_i < events.size():
			var ev: Array = events[ev_i]
			if float(ev[0]) > anim_t:
				break
			ev_i += 1
			_event(str(ev[1]), str(ev[2]))
		for k: String in tracks.keys():
			vals[k] = _sample(k, minf(anim_t, anim_len))
		if (anim_out and anim_w <= 0.0) or (anim_t >= anim_len and anim_speed > 0.0):
			_anim_end()
			for k2: String in tracks.keys():
				vals[k2] = _sample(k2, 0.0)
	# --- base pose
	var sight: Vector3 = model["sight"]
	var hip: Vector3 = d["hip"]
	hip += Vector3(0.012, -0.012, -0.05) if str(d["sprint"]) == "pistol" else Vector3(0.062, -0.068, -0.11)
	var pos: Vector3 = hip.lerp(Vector3(-sight.x, -sight.y, float(d["adsz"])), ae)
	var fwd_v: float = -p.velocity.dot(p.global_transform.basis.z)
	inert = lerpf(inert, clampf((fwd_v - prev_fwd) / maxf(dt, 0.001) * 0.05, -1.0, 1.0), clampf(dt * 7.0, 0.0, 1.0))
	prev_fwd = fwd_v
	pos.z += inert * 0.014 * (1.0 - 0.7 * ae)
	pos.y -= absf(inert) * 0.004
	var rot := Vector3(0.0, 4.0, -3.0) * (1.0 - ae)
	rot.x -= inert * 1.5 * (1.0 - 0.7 * ae)
	var sp: Array = SPRINTS[d["sprint"]]
	var spp: Vector3 = sp[0]
	var spr_r: Vector3 = sp[1]
	pos += spp * se + Vector3(0.04, -0.5, 0.15) * le
	rot += spr_r * se + Vector3(-42, 16, -10) * le
	var calm: float = 1.0 - 0.8 * ae
	pos.y += sin(t * 1.5) * 0.0035 * calm
	pos.x += sin(t * 0.75 + 1.0) * 0.002 * calm
	rot.x += sin(t * 1.5 + 0.7) * 0.55 * calm
	rot.z += sin(t * 0.9) * 0.45 * calm
	var hv: float = Vector2(p.velocity.x, p.velocity.z).length()
	if p.is_on_floor() and hv > 0.3:
		bob_t += dt * hv * (1.55 if sprinting else 1.9)
	var ba: float = clampf(hv / 4.0, 0.0, 1.6) * calm * (1.0 + 0.6 * wgt)
	pos.x += cos(bob_t) * 0.006 * ba * (1.0 + se)
	pos.y -= absf(sin(bob_t)) * 0.008 * ba * (1.0 + se)
	rot.z += cos(bob_t) * 1.3 * ba
	var lat: float = p.velocity.dot(p.global_transform.basis.x)
	lean = lerpf(lean, clampf(lat / 4.0, -1.0, 1.0), clampf(dt * 7.0, 0.0, 1.0))
	rot.z -= lean * 2.6 * calm
	pos.x += lean * 0.006 * calm
	rot.x += sin(bob_t * 2.0) * 0.7 * ba
	var tgt: Vector2 = (look_acc * 0.012).limit_length(1.4)
	look_acc = Vector2.ZERO
	sway = sway.lerp(tgt, clampf(dt * (9.0 - 4.0 * wgt), 0.0, 1.0))
	pos.x -= sway.x * 0.014 * calm
	pos.y += sway.y * 0.012 * calm
	rot.y += sway.x * 3.2 * calm
	rot.z += sway.x * 4.5 * calm
	rot.x -= sway.y * 3.0 * calm
	pos.y -= clampf(p.velocity.y * 0.005, -0.035, 0.035)
	# --- recoil springs
	rec_v += (-rec_p * 190.0 - rec_v * 20.0) * dt
	rec_p += rec_v * dt
	rec_rv += (-rec_r * 170.0 - rec_rv * 17.0) * dt
	rec_r += rec_rv * dt
	pos += Vector3(rec_p.x, rec_p.y, rec_p.z)
	rot += Vector3(rec_r.x, rec_r.y, rec_r.z)
	pos += chv("wp")
	rot += chv("wr")
	rig.position = pos
	rig.rotation = Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z))
	pivot.rotation.x = deg_to_rad(chf("spin"))
	var crv: Vector3 = chv("cr")
	p.insp_cam = Vector3(deg_to_rad(crv.x), deg_to_rad(crv.y), deg_to_rad(crv.z))
	# --- moving parts
	trig_e = maxf(0.0, trig_e - dt * 7.0)
	bolt_kick = maxf(0.0, bolt_kick - dt * 14.0)
	if parts.has("bolt"):
		var bn: Node3D = parts["bolt"]
		var bt: Vector3 = model["bolt_travel"]
		var p0: Vector3 = bn.get_meta("p0")
		bn.position = p0 + bt * maxf(chf("bolt"), bolt_kick)
		if cur == "northwind":
			bn.rotation.z = deg_to_rad(chf("brot"))
	if parts.has("mag"):
		var mn: Node3D = parts["mag"]
		var md: Vector3 = model["magdir"]
		var m0: Vector3 = mn.get_meta("p0")
		var r0: Vector3 = mn.get_meta("r0")
		mn.position = m0 + md * 0.26 * chf("mag")
		var mr: Vector3 = chv("mr")
		mn.rotation = r0 + Vector3(deg_to_rad(mr.x), deg_to_rad(mr.y), deg_to_rad(mr.z))
		mn.visible = chf("mh") < 0.5
	if parts.has("pump"):
		var pn: Node3D = parts["pump"]
		var pp0: Vector3 = pn.get_meta("p0")
		pn.position = pp0 + Vector3(0, 0, 0.09 * chf("pump"))
	if parts.has("cyl"):
		var cn: Node3D = parts["cyl"]
		cn.rotation.z = deg_to_rad(72.0) * chf("cyl")
		var sn: Node3D = parts["spin"]
		sn.rotation.z = deg_to_rad(chf("cspin") + float(shots) * 60.0)
		var hn: Node3D = parts["hammer"]
		hn.rotation.x = 0.6 * maxf(chf("ham"), trig_e * 0.8)
	if parts.has("cover"):
		var cv: Node3D = parts["cover"]
		cv.rotation.x = -deg_to_rad(58.0) * chf("cover")
	coil_t += dt
	var coils: Array = model["coils"]
	for i in coils.size():
		var cm: StandardMaterial3D = coils[i]
		var ph: float = coil_t * 22.0 if coil_t < 0.5 else -9.0
		var e: float = 0.5 + 6.0 * exp(-pow(ph - float(i), 2.0))
		var chg: float = float(vals.get("chg", 0.0)) * 5.5 - 0.5
		if vals.has("chg"):
			e += 5.0 * exp(-pow(chg - float(i), 2.0) * 1.5) * anim_w
		cm.emission_energy_multiplier = e
	# --- hands
	var rt: Transform3D = r_base
	rt.origin += chv("rh")
	var rhn: Node3D = rhand["node"]
	rhn.transform = rt
	var rp: Array = _mix(POSES["grip"], POSES["trig"], clampf(trig_e * 1.4, 0.0, 1.0))
	_apply_pose(rhand, _mix(rp, POSES["open"], clampf(chf("rc"), 0.0, 1.0)))
	var lt: Transform3D = l_base
	lt.origin += chv("lh")
	var lrv: Vector3 = chv("lr")
	lt.basis = lt.basis * Basis.from_euler(Vector3(deg_to_rad(lrv.x), deg_to_rad(lrv.y), deg_to_rad(lrv.z)))
	var ldw: float = clampf(chf("ld"), 0.0, 1.0)
	reach_t = maxf(0.0, reach_t - dt)
	var ru: float = 1.0 - reach_t / REACH_T
	var reach_w: float = 0.0
	if reach_t > 0.0:
		reach_w = smoothstep(0.0, 0.34, ru) * (1.0 - smoothstep(0.62, 1.0, ru))
	var reaching: bool = reach_w > ldw
	ldw = maxf(ldw, reach_w)
	if ldw > 0.001:
		var lpv: Variant = vals.get("lp", LP_DEF)
		var lp: Vector3 = lpv
		var lqv: Variant = vals.get("lq", Vector3.ZERO)
		var lq: Vector3 = lqv
		if reaching:
			lp = REACH_P + Vector3(0, 0, -0.03) * sin(clampf((ru - 0.34) / 0.28, 0.0, 1.0) * PI)
			lq = Vector3(-8, 0, 24)
		var fre := Transform3D(l_free * Basis.from_euler(Vector3(deg_to_rad(lq.x), deg_to_rad(lq.y), deg_to_rad(lq.z))), lp)
		var fr: Transform3D = rig.transform.affine_inverse() * fre
		lt.origin = lt.origin.lerp(fr.origin, ldw)
		lt.basis = lt.basis.orthonormalized().slerp(fr.basis.orthonormalized(), ldw)
	var lhn: Node3D = lhand["node"]
	lhn.transform = lt
	var lpose: Array = _mix(POSES[l_pose], POSES["open"], clampf(maxf(chf("lc"), reach_w if reaching else 0.0), 0.0, 1.0))
	_apply_pose(lhand, _mix(lpose, POSES["pinch"], clampf(maxf(chf("lg"), (reach_w * reach_w * 0.8) if reaching else 0.0), 0.0, 1.0)))
	var rw: Vector3 = rig.transform * rt.origin
	var lw: Vector3 = rig.transform * lt.origin
	var dr: Vector3 = (ELBOW_R - rw).normalized()
	var dl: Vector3 = (ELBOW_L - lw).normalized()
	rarm.position = rw
	rarm.basis = Basis(Quaternion(Vector3.UP, dr))
	larm.position = lw
	larm.basis = Basis(Quaternion(Vector3.UP, dl))
	var er2: Vector3 = rw + dr * FORE
	var el2: Vector3 = lw + dl * FORE
	ruarm.position = er2
	ruarm.basis = Basis(Quaternion(Vector3.UP, (SHOULDER_R - er2).normalized()))
	luarm.position = el2
	luarm.basis = Basis(Quaternion(Vector3.UP, (SHOULDER_L - el2).normalized()))
	# --- inspection light, muzzle effects, casings
	var lpath: float = float(vals.get("lt", 0.0))
	light.position = Vector3(-0.34, 0.16, -0.26).lerp(Vector3(0.36, 0.22, -0.52), lpath) + Vector3(0, sin(lpath * PI) * 0.12, 0)
	light.light_energy = chf("le") * 1.5 + 0.22 * (1.0 - main.world.daylight) * (1.0 - smoothstep(0.0, 1.0, low))
	flash_t -= dt
	if flash_t <= 0.0:
		flash_m.visible = false
		smoke.emitting = coil_t < 0.35
	flash_l.light_energy = lerpf(flash_l.light_energy, 0.0, clampf(dt * 28.0, 0.0, 1.0))
	if model.has("node"):
		var ml: Vector3 = to_local(muzzle_world())
		flash_m.position = ml
		flash_l.position = ml
		smoke.position = ml
	for sh: Dictionary in shells:
		var life: float = sh["life"]
		if life <= 0.0:
			continue
		life -= dt
		sh["life"] = life
		var sn2: MeshInstance3D = sh["node"]
		var v: Vector3 = sh["v"]
		v.y -= 9.0 * dt
		sh["v"] = v
		sn2.position += v * dt
		var w: Vector3 = sh["w"]
		sn2.rotation += w * dt
		if life <= 0.0:
			sn2.visible = false
	var vis: bool = le < 0.98 and scope_a < 0.5
	# with the weapon put away, a reach shows the left hand alone
	var solo: bool = not vis and reach_w > 0.01 and scope_a < 0.5
	rig.visible = vis or solo
	pivot.visible = vis
	var rhn2: Node3D = rhand["node"]
	rhn2.visible = vis
	rarm.visible = vis
	ruarm.visible = vis
	larm.visible = vis or solo
	luarm.visible = vis or solo
	spread_now = float(d["spread"]) + bloom + hv * 0.0035 + (0.02 if spr > 0.2 else 0.0)

# ---------------- animation sets ----------------
func _anim_equip() -> Array:
	var w: float = d["weight"]
	var T: float = 0.42 + 0.55 * w
	var rows: Array = [
		[0.0, {"wp": Vector3(0.06, -0.44, 0.16), "wr": Vector3(-50, 24, -18), "ld": 1.0, "lp": Vector3(-0.2, -0.52, -0.2), "lc": 0.6, "snd": "w_cloth"}],
		[T * 0.55, {"wp": Vector3(-0.012, 0.02 + 0.02 * w, 0.02), "wr": Vector3(7.0 + 5.0 * w, -3, 5), "ld": 1.0, "lp": Vector3(-0.2, -0.4, -0.3), "lc": 0.5}],
		[T * 0.8, {"wp": Vector3(0.0, -0.006 - 0.014 * w, -0.012), "wr": Vector3(-2.0 - 3.0 * w, 0, -1), "ld": 0.0, "lc": 0.0, "snd": "w_click"}],
	]
	if d.has("cycle") or str(d["reload"]) == "rev":
		rows.append([T, {"wp": Vector3.ZERO, "wr": Vector3.ZERO}])
	else:
		var B: Vector3 = model["boltpos"] - model["lh"]
		rows.append([T, {"wp": Vector3.ZERO, "wr": Vector3(2, 1, -6), "lh": Vector3.ZERO, "bolt": 0.0}])
		rows.append([T + 0.12, {"lh": B, "lg": 0.6, "bolt": 0.0}])
		rows.append([T + 0.22, {"lh": B + Vector3(0, 0, 0.014), "bolt": 0.3, "snd": "w_click"}])
		rows.append([T + 0.34, {"lh": B, "bolt": 0.0, "lg": 0.6}])
		rows.append([T + 0.5, {"wr": Vector3.ZERO, "lh": Vector3.ZERO, "lg": 0.0}])
	return rows

func _anim_holster() -> Array:
	var T: float = 0.24 + 0.3 * float(d["weight"])
	return [
		[0.0, {"snd": "w_cloth"}],
		[T, {"wp": Vector3(0.06, -0.46, 0.16), "wr": Vector3(-52, 26, -16), "ld": 1.0, "lp": Vector3(-0.2, -0.52, -0.2), "lc": 0.6}],
	]

func _anim_cycle() -> Array:
	if str(d["cycle"]) == "pump":
		return [
			[0.0, {}],
			[0.08, {"wr": Vector3(3, 0, -2), "pump": 0.0, "lh": Z, "snd": "w_pump"}],
			[0.22, {"pump": 1.0, "lh": Vector3(0, 0, 0.09), "wp": Vector3(0, -0.006, 0.014), "wr": Vector3(6, 1, -4), "ev": "shell"}],
			[0.4, {"pump": 0.0, "lh": Z, "wp": Vector3(0, 0.002, -0.01), "wr": Vector3(-1, 0, 0)}],
			[0.52, {}],
		]
	var RB: Vector3 = model["boltpos"] - Vector3(0.0, -0.04, 0.04)
	return [
		[0.0, {}],
		[0.18, {"rh": RB, "rc": 0.5, "wr": Vector3(2, -2, -6), "brot": 0.0, "snd": "w_bolt"}],
		[0.32, {"brot": 55.0, "rh": RB + Vector3(-0.012, 0.03, 0), "bolt": 0.0}],
		[0.5, {"bolt": 1.0, "brot": 55.0, "rh": RB + Vector3(-0.012, 0.03, 0.09), "wp": Vector3(0, 0, 0.012), "ev": "shell"}],
		[0.7, {"bolt": 0.0, "brot": 55.0, "rh": RB + Vector3(-0.012, 0.03, 0), "wp": Vector3(0, 0, -0.006)}],
		[0.84, {"brot": 0.0, "rh": RB, "rc": 0.5}],
		[1.05, {}],
	]

func _anim_reload(empty: bool) -> Array:
	var style: String = d["reload"]
	var T: float = float(d["rtime"]) * (1.0 if empty else 0.84)
	var M: Vector3 = model["mag"] - model["lh"]
	var B: Vector3 = model["boltpos"] - model["lh"]
	var D: Vector3 = model["magdir"]
	var bt: Vector3 = model["bolt_travel"]
	if style == "rev":
		return [
			[0.0, {"snd": "w_cloth"}],
			[0.14 * T, {"wp": Vector3(-0.05, 0.03, 0.05), "wr": Vector3(30, 14, -30), "cyl": 0.0, "lh": Z}],
			[0.22 * T, {"cyl": 1.0, "wr": Vector3(58, 12, -34), "lh": M, "lg": 0.5, "snd": "w_click"}],
			[0.32 * T, {"wr": Vector3(66, 10, -30), "wp": Vector3(-0.05, 0.02, 0.05), "ev": "shells6", "snd": "w_shell"}],
			[0.46 * T, {"wr": Vector3(-24, 16, -36), "wp": Vector3(-0.06, 0.03, 0.06), "lh": M + Vector3(-0.06, -0.16, 0.04), "cyl": 1.0}],
			[0.62 * T, {"lh": M + Vector3(-0.01, 0.0, 0.02), "lg": 1.0, "wr": Vector3(-28, 16, -38), "snd": "w_magin", "ev": "fill"}],
			[0.7 * T, {"lh": M + Vector3(-0.04, -0.03, 0.03), "cyl": 1.0, "cspin": 0.0}],
			[0.8 * T, {"wr": Vector3(10, 6, 26), "cyl": 1.0, "cspin": 180.0}],
			[0.87 * T, {"cyl": 0.0, "wr": Vector3(4, 2, -16), "lh": Z, "lg": 0.0, "snd": "w_click"}],
			[T, {}],
		]
	if style == "shell":
		var rows: Array = [
			[0.0, {"snd": "w_cloth"}],
			[0.1 * T, {"wp": Vector3(-0.02, 0.04, 0.03), "wr": Vector3(16, 10, -52), "lh": Z}],
		]
		var n: int = 4
		for i in n:
			var t0: float = (0.14 + 0.16 * float(i)) * T
			rows.append([t0, {"lh": M + Vector3(-0.05, -0.12, 0.05), "lg": 1.0}])
			rows.append([t0 + 0.09 * T, {"lh": M + Vector3(0, 0.0, 0.03), "lg": 1.0, "wp": Vector3(-0.02, 0.046, 0.03), "snd": "w_shell"}])
			rows.append([t0 + 0.12 * T, {"lh": M + Vector3(0, 0.0, -0.02), "wp": Vector3(-0.02, 0.04, 0.03)}])
		rows.append([0.8 * T, {"lh": Z, "lg": 0.0, "wr": Vector3(6, 2, -6), "pump": 0.0, "ev": "fill"}])
		if empty:
			rows.append([0.87 * T, {"pump": 1.0, "lh": Vector3(0, 0, 0.09), "wp": Vector3(0, -0.006, 0.014), "snd": "w_pump"}])
			rows.append([0.95 * T, {"pump": 0.0, "lh": Z}])
		rows.append([T, {}])
		return rows
	var rows2: Array = [
		[0.0, {"snd": "w_cloth"}],
		[0.12 * T, {"wp": Vector3(0.0, 0.02, 0.03), "wr": Vector3(12, 5, -20), "lc": 0.3, "lh": Z}],
	]
	if style == "belt":
		rows2.append([0.2 * T, {"lh": B, "lg": 0.6, "cover": 0.0}])
		rows2.append([0.27 * T, {"cover": 1.0, "lh": B + Vector3(0, 0.1, -0.06), "snd": "w_cover"}])
	var a: float = 0.3 if style == "belt" else 0.24
	var sc: float = (0.8 - a) / 0.54
	rows2.append([a * T, {"lh": M, "lg": 1.0, "lc": 0.0, "mag": 0.0, "snd": "w_magout"}])
	rows2.append([(a + 0.12 * sc) * T, {"lh": M + D * 0.16, "mag": 0.6, "wr": Vector3(14, 6, -24)}])
	rows2.append([(a + 0.22 * sc) * T, {"lh": M + D * 0.26 + Vector3(-0.06, -0.1, 0.06), "mag": 1.0, "mh": 0.0}])
	rows2.append([(a + 0.25 * sc) * T, {"mh": 1.0}])
	rows2.append([(a + 0.34 * sc) * T, {"lh": M + D * 0.26 + Vector3(-0.04, -0.06, 0.04), "mag": 1.0, "mh": 1.0}])
	rows2.append([(a + 0.36 * sc) * T, {"mh": 0.0}])
	rows2.append([(a + 0.48 * sc) * T, {"lh": M + D * 0.05, "mag": 0.2, "wr": Vector3(10, 4, -18)}])
	rows2.append([(a + 0.54 * sc) * T, {"lh": M, "mag": 0.0, "wp": Vector3(0, 0.035, 0.02), "lg": 1.0, "snd": "w_magin", "ev": "fill"}])
	if style == "belt":
		rows2.append([0.84 * T, {"lh": B + Vector3(0, 0.1, -0.06), "lg": 0.6, "cover": 1.0}])
		rows2.append([0.9 * T, {"cover": 0.0, "lh": B, "wp": Vector3(0, -0.012, 0.02), "snd": "w_cover"}])
	if empty and cur == "northwind":
		var RB: Vector3 = model["boltpos"] - Vector3(0.0, -0.04, 0.04)
		rows2.append([0.82 * T, {"lh": Z, "lg": 0.0, "rh": RB, "rc": 0.5, "brot": 0.0, "snd": "w_bolt"}])
		rows2.append([0.86 * T, {"brot": 55.0, "rh": RB + Vector3(-0.012, 0.03, 0), "bolt": 0.0}])
		rows2.append([0.91 * T, {"bolt": 1.0, "brot": 55.0, "rh": RB + Vector3(-0.012, 0.03, 0.09)}])
		rows2.append([0.95 * T, {"bolt": 0.0, "brot": 55.0, "rh": RB + Vector3(-0.012, 0.03, 0)}])
		rows2.append([0.98 * T, {"brot": 0.0, "rh": RB}])
	elif empty and style != "belt":
		rows2.append([0.86 * T, {"lh": B, "lg": 0.5, "wr": Vector3(6, 2, -8), "bolt": 0.0, "snd": "w_rack"}])
		rows2.append([0.91 * T, {"bolt": 1.0, "lh": B + bt}])
		rows2.append([0.95 * T, {"bolt": 0.0, "lh": B, "lg": 0.0}])
	rows2.append([T, {}])
	return rows2

func _anim_inspect() -> Array:
	var M: Vector3 = model["mag"] - model["lh"]
	var B: Vector3 = model["boltpos"] - model["lh"]
	var D: Vector3 = model["magdir"]
	var bt: Vector3 = model["bolt_travel"]
	match cur:
		"p9":
			return [
				[0.0, {"snd": "w_cloth"}],
				[0.45, {"wp": Vector3(-0.09, 0.075, 0.14), "wr": Vector3(8, 64, -10), "ld": 1.0, "lp": Vector3(-0.22, -0.24, -0.3), "lc": 0.8, "le": 1.0, "lt": 0.0, "cr": Vector3(-1.5, 1.0, 0)}],
				[1.15, {"wp": Vector3(-0.1, 0.09, 0.2), "wr": Vector3(12, 74, -16), "ld": 1.0, "lt": 0.7}],
				[1.55, {"wp": Vector3(-0.07, 0.04, 0.08), "wr": Vector3(12, 8, -18), "ld": 0.0, "lh": B, "lc": 0.0, "lg": 0.8, "bolt": 0.0}],
				[1.8, {"bolt": 0.42, "lh": B + Vector3(0, 0, 0.015), "wr": Vector3(16, 4, -22), "snd": "w_click"}],
				[2.1, {"bolt": 0.0, "lh": B, "lg": 0.8, "ld": 0.0}],
				[2.5, {"wp": Vector3(-0.28, 0.085, 0.12), "wr": Vector3(10, -58, 12), "ld": 1.0, "lg": 0.0, "lc": 0.7, "lh": Z, "lt": 0.2, "cr": Vector3(1.0, -1.0, 0), "snd": "w_cloth"}],
				[3.1, {"wp": Vector3(-0.28, 0.095, 0.17), "wr": Vector3(14, -70, 18), "lt": 1.0, "ld": 1.0}],
				[3.4, {"wp": Vector3(-0.05, 0.05, 0.05), "wr": Vector3(0, 0, 8), "rc": 0.0, "spin": 0.0}],
				[3.52, {"rc": 1.0, "snd": "w_ratchet"}],
				[4.2, {"spin": 360.0, "wp": Vector3(-0.05, 0.08, 0.04), "rc": 1.0}],
				[4.32, {"rc": 0.0, "spin": 360.0, "snd": "w_click"}],
				[4.7, {"wp": Vector3(0.0, 0.02, -0.04), "wr": Vector3(-5, 0, -3), "ld": 1.0, "le": 1.0, "cr": Z}],
				[4.95, {"wp": Vector3(0, 0.004, -0.01), "wr": Vector3(1, 0, 0), "ld": 0.0, "lc": 0.0, "le": 0.3}],
				[5.2, {}],
			]
		"kestrel":
			return [
				[0.0, {"snd": "w_cloth"}],
				[0.5, {"wp": Vector3(-0.1, 0.07, 0.1), "wr": Vector3(22, 30, -40), "ld": 1.0, "lp": Vector3(-0.2, -0.22, -0.3), "lc": 0.7, "le": 1.0, "lt": 0.0, "cyl": 0.0}],
				[0.9, {"cyl": 1.0, "wr": Vector3(30, 34, -48), "cspin": 0.0, "snd": "w_click"}],
				[1.05, {"cspin": 0.0, "snd": "w_ratchet"}],
				[2.0, {"cspin": 720.0, "wp": Vector3(-0.12, 0.1, 0.14), "wr": Vector3(38, 30, -52), "lt": 0.8}],
				[2.3, {"wr": Vector3(-10, 20, -30), "wp": Vector3(-0.1, 0.04, 0.1), "cspin": 720.0, "cyl": 1.0, "cr": Vector3(1.5, 0, 0)}],
				[2.75, {"wr": Vector3(20, 16, 30), "cyl": 1.0}],
				[2.9, {"cyl": 0.0, "wr": Vector3(8, 4, -24), "wp": Vector3(-0.06, 0.05, 0.06), "snd": "w_click"}],
				[3.3, {"ham": 0.0, "wr": Vector3(14, 0, -8)}],
				[3.5, {"ham": 1.0, "snd": "w_click"}],
				[3.9, {"wp": Vector3(-0.05, 0.05, 0.05), "wr": Vector3(0, 0, 6), "rc": 0.0, "spin": 0.0, "ham": 1.0, "cr": Z}],
				[4.0, {"rc": 1.0, "snd": "w_ratchet"}],
				[4.75, {"spin": -720.0, "rc": 1.0, "wp": Vector3(-0.05, 0.09, 0.04)}],
				[4.87, {"rc": 0.0, "spin": -720.0, "ham": 0.0, "snd": "w_click"}],
				[5.4, {"wp": Vector3(0.01, 0.03, -0.05), "wr": Vector3(-6, -2, -4), "ld": 1.0, "le": 1.0, "lt": 1.0}],
				[5.7, {"wp": Vector3(0, 0.004, -0.01), "wr": Vector3(1, 0, 0), "ld": 0.0, "lc": 0.0, "le": 0.3}],
				[6.0, {}],
			]
		"stryk":
			return [
				[0.0, {"snd": "w_cloth"}],
				[0.3, {"wp": Vector3(-0.04, 0.06, 0.02), "wr": Vector3(14, 20, -84), "le": 1.0, "lt": 0.0, "lh": Z}],
				[0.55, {"lh": M, "lg": 1.0, "mag": 0.0, "wr": Vector3(18, 24, -80)}],
				[0.75, {"mag": 0.7, "lh": M + D * 0.18, "snd": "w_magout"}],
				[0.95, {"lh": M + D * 0.2 + Vector3(-0.05, -0.03, 0.02), "mag": 0.8, "mr": Z}],
				[1.4, {"mr": Vector3(360, 0, 0), "lh": M + D * 0.24 + Vector3(-0.06, 0.0, 0.02), "mag": 0.9, "lt": 0.6, "snd": "w_cloth"}],
				[1.7, {"mag": 0.0, "lh": M, "wp": Vector3(-0.04, 0.08, 0.02), "snd": "w_magin"}],
				[1.85, {"wp": Vector3(-0.04, 0.055, 0.02), "lg": 1.0, "wr": Vector3(16, 22, -82)}],
				[2.2, {"wr": Vector3(10, 6, -10), "wp": Vector3(-0.02, 0.03, 0.0), "lh": B, "lg": 0.6, "bolt": 0.0}],
				[2.4, {"bolt": 1.0, "lh": B + bt, "snd": "w_rack"}],
				[2.55, {"bolt": 0.0, "lh": B}],
				[2.9, {"wr": Vector3(12, -58, 14), "wp": Vector3(-0.3, 0.07, 0.0), "ld": 1.0, "lp": Vector3(-0.22, -0.28, -0.32), "lc": 0.6, "lh": Z, "lg": 0.0, "lt": 1.0}],
				[3.3, {"wr": Vector3(16, -68, 18), "ld": 1.0}],
				[3.75, {"wr": Vector3(-4, 0, -2), "wp": Vector3(0, 0.01, -0.03), "ld": 0.0, "lc": 0.0, "le": 0.4}],
				[4.2, {}],
			]
		"tundra":
			return [
				[0.0, {"snd": "w_cloth"}],
				[0.6, {"wp": Vector3(-0.12, 0.0, -0.02), "wr": Vector3(78, 0, 0), "ld": 1.0, "lp": Vector3(-0.2, -0.2, -0.36), "lq": Z, "lc": 0.5, "le": 1.0, "lt": 0.0}],
				[1.2, {"wr": Vector3(80, 0, -60), "wp": Vector3(-0.14, 0.02, 0.0), "lq": Vector3(0, 0, 40), "lp": Vector3(-0.16, -0.12, -0.34), "lc": 0.2}],
				[1.8, {"wr": Vector3(80, 0, 40), "lc": 0.9, "lt": 0.5, "snd": "w_cloth"}],
				[2.4, {"wr": Vector3(84, 0, 95), "lc": 0.2, "lt": 1.0, "ld": 1.0}],
				[3.0, {"wr": Vector3(40, 30, -10), "wp": Vector3(-0.04, 0.06, -0.04), "ld": 0.0, "lh": Z, "lc": 0.0}],
				[3.4, {"lh": Vector3(0, 0, 0.1), "wr": Vector3(36, 36, -14)}],
				[3.8, {"lh": Vector3(0, 0, -0.04), "wr": Vector3(30, 42, -18), "cr": Vector3(-1, 1, 0)}],
				[4.2, {"wr": Vector3(8, 8, -30), "wp": Vector3(-0.02, 0.04, 0.02), "lh": B, "lg": 0.6, "bolt": 0.0}],
				[4.45, {"bolt": 1.0, "lh": B + bt, "snd": "w_rack"}],
				[4.7, {"bolt": 0.0, "lh": B}],
				[5.0, {"lh": M, "lg": 1.0, "wr": Vector3(12, 6, -22), "snd": "w_click"}],
				[5.2, {"lh": M + Vector3(0, 0.02, 0), "wp": Vector3(-0.02, 0.055, 0.02), "snd": "w_magin"}],
				[5.6, {"wp": Vector3(0, 0.01, -0.03), "wr": Vector3(-3, 0, -1), "lh": Z, "lg": 0.0, "le": 0.4, "cr": Z}],
				[6.0, {}],
			]
		"harrow":
			return [
				[0.0, {"snd": "w_cloth"}],
				[0.6, {"wp": Vector3(-0.02, 0.07, -0.06), "wr": Vector3(38, 52, -18), "le": 1.0, "lt": 0.0, "lh": Z, "cr": Vector3(-1.5, 1.5, 0)}],
				[1.3, {"wp": Vector3(-0.07, 0.1, 0.07), "wr": Vector3(26, 64, -28), "lh": Vector3(0, 0, 0.14), "lt": 0.5}],
				[2.0, {"wp": Vector3(-0.05, 0.09, 0.03), "wr": Vector3(30, 58, -24), "lh": Vector3(0, 0, -0.1), "lt": 1.0}],
				[2.5, {"wp": Vector3(-0.12, 0.1, 0.1), "wr": Vector3(-10, 2, 4), "lh": Z, "cr": Vector3(1, 0, 0)}],
				[3.0, {"wp": Vector3(-0.13, 0.105, 0.11), "wr": Vector3(-12, 0, 0), "le": 0.5, "ld": 0.0}],
				[3.5, {"wp": Vector3(-0.34, 0.1, -0.04), "wr": Vector3(12, -56, 14), "ld": 1.0, "lp": Vector3(-0.26, -0.3, -0.3), "lc": 0.7, "le": 1.0, "lt": 0.2, "snd": "w_cloth"}],
				[4.2, {"wp": Vector3(-0.35, 0.11, 0.0), "wr": Vector3(16, -68, 20), "lt": 1.0, "ld": 1.0, "lc": 0.7}],
				[4.7, {"wp": Vector3(-0.03, 0.05, 0.02), "wr": Vector3(10, 8, -26), "ld": 0.0, "lc": 0.0, "lh": B, "lg": 0.7, "bolt": 0.0}],
				[4.95, {"bolt": 1.0, "lh": B + bt, "wr": Vector3(14, 8, -30), "snd": "w_rack"}],
				[5.3, {"bolt": 1.0, "lh": B + bt, "wp": Vector3(-0.05, 0.07, 0.06)}],
				[5.45, {"bolt": 0.0, "lh": B, "snd": "w_click"}],
				[5.8, {"lh": M, "lg": 1.0, "wr": Vector3(12, 6, -20)}],
				[5.95, {"lh": M + Vector3(0, 0.02, 0), "wp": Vector3(-0.03, 0.07, 0.02), "snd": "w_magin"}],
				[6.4, {"wp": Vector3(0.0, 0.02, -0.05), "wr": Vector3(-5, -2, -3), "lh": Z, "lg": 0.0, "cr": Z}],
				[6.7, {"wp": Vector3(0, 0.004, -0.01), "wr": Vector3(1, 0, 0), "le": 0.3}],
				[7.0, {}],
			]
		"morrow":
			return [
				[0.0, {"snd": "w_cloth"}],
				[0.5, {"wp": Vector3(-0.1, 0.09, 0.02), "wr": Vector3(12, 60, -78), "le": 1.0, "lt": 0.0, "ld": 1.0, "lp": Vector3(-0.1, -0.1, -0.4), "lq": Z, "lc": 0.3}],
				[1.1, {"wr": Vector3(16, 66, -84), "lp": Vector3(-0.02, -0.02, -0.42), "lq": Vector3(0, 0, -30), "lc": 0.1, "lt": 0.6}],
				[1.3, {"lp": Vector3(-0.02, -0.03, -0.44), "snd": "w_shell"}],
				[1.7, {"lp": Vector3(-0.16, -0.18, -0.36), "lc": 0.6, "wr": Vector3(12, 60, -78), "ld": 1.0}],
				[2.2, {"wp": Vector3(-0.02, 0.05, -0.02), "wr": Vector3(30, 40, -12), "ld": 0.0, "lh": Z, "lc": 0.0, "lt": 1.0}],
				[2.6, {"wr": Vector3(34, 44, -16), "pump": 0.0, "lh": Z}],
				[2.8, {"pump": 1.0, "lh": Vector3(0, 0, 0.09), "wp": Vector3(-0.02, 0.04, 0.0), "snd": "w_pump"}],
				[3.05, {"pump": 0.0, "lh": Z, "ld": 0.0}],
				[3.5, {"wp": Vector3(0.06, 0.16, 0.12), "wr": Vector3(64, -30, 20), "ld": 1.0, "lp": Vector3(-0.24, -0.34, -0.3), "lc": 0.6, "cr": Vector3(-1, -1, 0)}],
				[4.3, {"wp": Vector3(0.06, 0.17, 0.13), "wr": Vector3(66, -32, 22), "ld": 1.0, "le": 0.5}],
				[4.9, {"wp": Vector3(0, 0.02, -0.05), "wr": Vector3(-6, 0, -3), "ld": 0.0, "lc": 0.0, "le": 0.6, "cr": Z}],
				[5.3, {"wp": Vector3(0, 0.004, -0.01), "wr": Vector3(1, 0, 0)}],
				[5.6, {}],
			]
		"sable":
			return [
				[0.0, {"snd": "w_cloth"}],
				[0.7, {"wp": Vector3(-0.03, 0.06, -0.04), "wr": Vector3(30, 48, -20), "le": 1.0, "lt": 0.0, "lh": Z}],
				[1.4, {"wp": Vector3(-0.1, 0.08, 0.1), "wr": Vector3(8, 28, -36), "ld": 1.0, "lp": Vector3(-0.06, 0.02, -0.3), "lq": Vector3(10, 0, -40), "lc": 0.2, "lg": 0.6, "lt": 0.5}],
				[1.7, {"lq": Vector3(10, 0, -70), "snd": "w_click"}],
				[2.0, {"lq": Vector3(10, 0, -40), "snd": "w_click"}],
				[2.3, {"lq": Vector3(10, 0, -70), "ld": 1.0, "snd": "w_click"}],
				[2.8, {"wp": Vector3(-0.34, 0.1, -0.02), "wr": Vector3(12, -56, 14), "lp": Vector3(-0.24, -0.3, -0.3), "lq": Z, "lc": 0.7, "lg": 0.0, "lt": 1.0, "snd": "w_cloth"}],
				[3.5, {"wr": Vector3(16, -66, 18), "ld": 1.0, "lc": 0.7}],
				[4.0, {"wp": Vector3(-0.1, -0.02, 0.06), "wr": Vector3(72, 6, -10), "ld": 0.0, "lc": 0.0, "lh": Vector3(0, 0, -0.12)}],
				[4.6, {"wr": Vector3(76, 4, -6), "lh": Vector3(0, 0, -0.2), "cr": Vector3(-2, 0, 0)}],
				[5.1, {"wp": Vector3(-0.03, 0.05, 0.02), "wr": Vector3(10, 8, -24), "lh": M, "lg": 1.0, "mag": 0.0}],
				[5.35, {"mag": 0.5, "lh": M + D * 0.13, "snd": "w_magout"}],
				[5.7, {"mag": 0.0, "lh": M, "wp": Vector3(-0.03, 0.07, 0.02), "snd": "w_magin"}],
				[6.1, {"wp": Vector3(0, 0.015, -0.04), "wr": Vector3(-4, -1, -2), "lh": Z, "lg": 0.0, "le": 0.4, "cr": Z}],
				[6.6, {}],
			]
		"northwind":
			var RB: Vector3 = model["boltpos"] - Vector3(0.0, -0.04, 0.04)
			return [
				[0.0, {"snd": "w_cloth"}],
				[0.9, {"wp": Vector3(-0.1, 0.1, -0.02), "wr": Vector3(4, 78, -8), "le": 1.0, "lt": 0.0, "lh": Z, "cr": Vector3(-1, 2, 0)}],
				[2.0, {"wp": Vector3(-0.06, 0.11, 0.04), "wr": Vector3(6, 82, -14), "lt": 1.0, "lh": Vector3(0, 0, 0.1)}],
				[2.6, {"wp": Vector3(-0.04, 0.06, 0.02), "wr": Vector3(14, 30, -22), "lh": Z, "rh": RB, "rc": 0.5, "brot": 0.0}],
				[3.0, {"brot": 55.0, "rh": RB + Vector3(-0.012, 0.03, 0), "bolt": 0.0, "snd": "w_click"}],
				[3.5, {"bolt": 1.0, "brot": 55.0, "rh": RB + Vector3(-0.012, 0.03, 0.09), "wp": Vector3(-0.06, 0.08, 0.08), "wr": Vector3(10, 20, -40), "snd": "w_rack"}],
				[4.3, {"bolt": 1.0, "brot": 55.0, "rh": RB + Vector3(-0.012, 0.03, 0.09), "wp": Vector3(-0.07, 0.09, 0.1), "cr": Vector3(1, 0, 0)}],
				[4.7, {"bolt": 0.0, "brot": 55.0, "rh": RB + Vector3(-0.012, 0.03, 0)}],
				[4.95, {"brot": 0.0, "rh": RB, "rc": 0.5, "snd": "w_click"}],
				[5.4, {"rh": Z, "rc": 0.0, "wp": Vector3(-0.1, -0.06, 0.02), "wr": Vector3(80, 8, -6), "lh": Vector3(0, 0, -0.1)}],
				[6.3, {"wr": Vector3(84, 4, -2), "lh": Vector3(0, 0, -0.2), "lt": 0.3, "cr": Vector3(-2.5, 0, 0)}],
				[7.0, {"wp": Vector3(0, 0.03, -0.06), "wr": Vector3(-6, -2, -3), "lh": Z, "cr": Z, "le": 0.6, "lt": 1.0}],
				[7.5, {"wp": Vector3(0, 0.004, -0.01), "wr": Vector3(1, 0, 0), "le": 0.3}],
				[8.0, {}],
			]
		"bastion":
			return [
				[0.0, {"snd": "w_cloth"}],
				[0.8, {"wp": Vector3(-0.02, 0.03, -0.02), "wr": Vector3(24, 34, -14), "le": 1.0, "lt": 0.0, "lh": Z, "cr": Vector3(-1, 1, 0)}],
				[1.0, {"wp": Vector3(-0.02, 0.015, -0.02), "wr": Vector3(22, 34, -14)}],
				[1.6, {"wr": Vector3(18, 24, -30), "wp": Vector3(-0.04, 0.05, 0.04), "lh": M + Vector3(0, 0.03, 0), "lg": 0.3, "lc": 0.3}],
				[1.8, {"lh": M + Vector3(0.02, 0, 0), "snd": "w_shell"}],
				[2.0, {"lh": M + Vector3(0, 0.03, 0)}],
				[2.3, {"lh": M + Vector3(0.02, 0, 0), "snd": "w_shell"}],
				[2.8, {"lh": B, "lg": 0.6, "cover": 0.0, "wr": Vector3(10, 12, -16), "wp": Vector3(-0.04, 0.03, 0.04)}],
				[3.2, {"cover": 1.0, "lh": B + Vector3(0, 0.1, -0.06), "snd": "w_cover"}],
				[3.9, {"cover": 1.0, "wp": Vector3(-0.07, 0.07, 0.1), "wr": Vector3(-6, 8, -22), "lh": B + Vector3(-0.03, 0.02, -0.02), "lt": 0.6, "cr": Vector3(2, 0, 0)}],
				[4.5, {"cover": 1.0, "lh": B + Vector3(0, 0.1, -0.06)}],
				[4.8, {"cover": 0.0, "lh": B + Vector3(0, 0.01, 0), "wp": Vector3(-0.04, 0.0, 0.04), "wr": Vector3(4, 10, -14), "snd": "w_cover"}],
				[4.95, {"wp": Vector3(-0.04, -0.02, 0.04), "cr": Vector3(1.5, 0, 0)}],
				[5.4, {"lh": Z, "lg": 0.0, "lc": 0.0, "wr": Vector3(12, -54, 12), "wp": Vector3(-0.32, 0.07, -0.02), "ld": 1.0, "lp": Vector3(-0.24, -0.3, -0.3), "lt": 1.0}],
				[6.0, {"wr": Vector3(16, -62, 16), "ld": 1.0}],
				[6.5, {"wp": Vector3(0, -0.01, -0.03), "wr": Vector3(-4, 0, -2), "ld": 0.0, "le": 0.4, "cr": Z}],
				[7.0, {}],
			]
		"vesper":
			return [
				[0.0, {"snd": "w_cloth"}],
				[0.3, {"wp": Vector3(-0.06, 0.07, 0.06), "wr": Vector3(10, 60, -14), "le": 1.0, "lt": 0.0, "lh": Z}],
				[0.6, {"lh": M, "lg": 1.0, "mag": 0.0}],
				[0.8, {"mag": 1.0, "lh": M + D * 0.26, "snd": "w_magout"}],
				[1.2, {"mag": 1.0, "mr": Z, "lh": M + D * 0.26 + Vector3(-0.04, 0.04, 0.0), "wr": Vector3(14, 66, -18)}],
				[1.6, {"mr": Vector3(0, 360, 0), "lt": 0.6, "snd": "w_cloth"}],
				[1.9, {"mag": 0.0, "lh": M, "wp": Vector3(-0.06, 0.09, 0.06), "snd": "w_magin"}],
				[2.05, {"wp": Vector3(-0.06, 0.065, 0.06), "lg": 1.0}],
				[2.4, {"wr": Vector3(12, -56, 12), "wp": Vector3(-0.3, 0.07, 0.02), "ld": 1.0, "lp": Vector3(-0.22, -0.28, -0.32), "lc": 0.6, "lh": Z, "lg": 0.0, "lt": 1.0, "snd": "w_cloth"}],
				[2.9, {"wr": Vector3(16, -66, 16), "ld": 1.0}],
				[3.3, {"wr": Vector3(8, 6, -10), "wp": Vector3(-0.02, 0.03, 0.0), "ld": 0.0, "lc": 0.0, "lh": B, "lg": 0.6, "bolt": 0.0}],
				[3.5, {"bolt": 1.0, "lh": B + bt, "snd": "w_rack"}],
				[3.65, {"bolt": 0.0, "lh": B}],
				[4.0, {"wr": Vector3(-4, 0, -2), "wp": Vector3(0, 0.01, -0.03), "lh": Z, "lg": 0.0, "le": 0.4}],
				[4.4, {}],
			]
		"grendel":
			return [
				[0.0, {"snd": "w_cloth"}],
				[0.7, {"wp": Vector3(-0.02, 0.07, -0.06), "wr": Vector3(36, 54, -18), "le": 1.0, "lt": 0.0, "lh": Z, "cr": Vector3(-1.5, 1.5, 0)}],
				[1.4, {"wp": Vector3(-0.07, 0.1, 0.06), "wr": Vector3(24, 66, -26), "lh": Vector3(0, 0, 0.1), "lt": 0.5}],
				[2.0, {"wp": Vector3(-0.05, 0.09, 0.03), "wr": Vector3(28, 60, -22), "lh": Vector3(0, 0, -0.08), "lt": 1.0}],
				[2.5, {"wp": Vector3(-0.03, 0.05, 0.02), "wr": Vector3(10, 8, -24), "lh": M, "lg": 1.0, "mag": 0.0, "cr": Z}],
				[2.75, {"mag": 0.55, "lh": M + D * 0.14, "snd": "w_magout"}],
				[3.2, {"mag": 0.55, "lh": M + D * 0.14, "wr": Vector3(14, 14, -34), "wp": Vector3(-0.05, 0.07, 0.05)}],
				[3.5, {"mag": 0.0, "lh": M, "wp": Vector3(-0.03, 0.075, 0.02), "snd": "w_magin"}],
				[3.65, {"wp": Vector3(-0.03, 0.05, 0.02), "lh": M, "lg": 1.0}],
				[4.1, {"wp": Vector3(-0.34, 0.1, -0.04), "wr": Vector3(12, -56, 14), "ld": 1.0, "lp": Vector3(-0.26, -0.3, -0.3), "lc": 0.7, "lh": Z, "lg": 0.0, "lt": 0.2, "snd": "w_cloth"}],
				[4.8, {"wp": Vector3(-0.35, 0.11, 0.0), "wr": Vector3(16, -68, 20), "lt": 1.0, "ld": 1.0, "lc": 0.7}],
				[5.3, {"wp": Vector3(-0.03, 0.05, 0.02), "wr": Vector3(10, 8, -26), "ld": 0.0, "lc": 0.0, "lh": B, "lg": 0.7, "bolt": 0.0}],
				[5.55, {"bolt": 1.0, "lh": B + bt, "wr": Vector3(14, 8, -30), "snd": "w_rack"}],
				[5.8, {"bolt": 0.0, "lh": B, "snd": "w_click"}],
				[6.2, {"wp": Vector3(0.0, 0.02, -0.05), "wr": Vector3(-5, -2, -3), "lh": Z, "lg": 0.0}],
				[6.45, {"wp": Vector3(0, 0.004, -0.01), "wr": Vector3(1, 0, 0), "le": 0.3}],
				[6.7, {}],
			]
		"halberd":
			return [
				[0.0, {"snd": "w_cloth"}],
				[0.6, {"wp": Vector3(-0.04, 0.06, -0.02), "wr": Vector3(20, 56, -12), "le": 1.0, "lt": 0.0, "lh": Z}],
				[1.1, {"lh": M, "lg": 0.8, "mag": 0.0}],
				[1.3, {"mag": 0.5, "lh": M + D * 0.13, "snd": "w_magout"}],
				[1.6, {"mag": 0.5, "mr": Z, "snd": "w_ratchet"}],
				[2.4, {"mr": Vector3(720, 0, 0), "mag": 0.5, "lt": 0.6}],
				[2.7, {"mag": 0.0, "lh": M, "wp": Vector3(-0.04, 0.085, -0.02), "snd": "w_magin"}],
				[2.85, {"wp": Vector3(-0.04, 0.05, -0.02), "lg": 0.8}],
				[3.3, {"wp": Vector3(-0.32, 0.08, -0.04), "wr": Vector3(12, -56, 12), "ld": 1.0, "lp": Vector3(-0.26, -0.3, -0.3), "lc": 0.7, "lh": Z, "lg": 0.0, "lt": 1.0, "snd": "w_cloth"}],
				[4.0, {"wr": Vector3(16, -66, 18), "ld": 1.0}],
				[4.5, {"wp": Vector3(0.05, 0.15, 0.1), "wr": Vector3(62, -28, 18), "ld": 1.0, "lp": Vector3(-0.24, -0.34, -0.3), "lc": 0.6, "cr": Vector3(-1, -1, 0)}],
				[5.2, {"wp": Vector3(0.05, 0.16, 0.11), "wr": Vector3(64, -30, 20), "ld": 1.0, "le": 0.5}],
				[5.7, {"wp": Vector3(0, 0.02, -0.05), "wr": Vector3(-6, 0, -3), "ld": 0.0, "lc": 0.0, "le": 0.6, "cr": Z}],
				[6.1, {"wp": Vector3(0, 0.004, -0.01), "wr": Vector3(1, 0, 0)}],
				[6.4, {}],
			]
		"riveter":
			return [
				[0.0, {"snd": "w_cloth"}],
				[0.5, {"wp": Vector3(-0.06, 0.07, 0.04), "wr": Vector3(14, 58, -14), "le": 1.0, "lt": 0.0, "lh": Z}],
				[0.9, {"ld": 1.0, "lp": Vector3(-0.1, -0.06, -0.36), "lq": Vector3(0, 0, -30), "lc": 0.2, "lg": 0.6}],
				[1.05, {"lp": Vector3(-0.08, -0.05, -0.38), "snd": "w_click"}],
				[1.2, {"lp": Vector3(-0.1, -0.06, -0.36)}],
				[1.35, {"lp": Vector3(-0.08, -0.05, -0.38), "snd": "w_click"}],
				[1.6, {"lp": Vector3(-0.12, -0.08, -0.34), "ld": 1.0}],
				[2.0, {"ld": 0.0, "lh": M, "lg": 1.0, "lc": 0.0, "mag": 0.0, "wr": Vector3(18, 50, -20)}],
				[2.25, {"mag": 0.5, "lh": M + D * 0.13, "snd": "w_magout"}],
				[2.7, {"mag": 0.5, "wr": Vector3(40, 46, -24), "wp": Vector3(-0.06, 0.04, 0.06), "lt": 0.5}],
				[3.0, {"mag": 0.0, "lh": M, "snd": "w_magin", "wr": Vector3(18, 50, -20)}],
				[3.4, {"wp": Vector3(-0.02, 0.03, 0.0), "wr": Vector3(8, 6, -10), "lh": B, "lg": 0.6, "bolt": 0.0}],
				[3.6, {"bolt": 1.0, "lh": B + bt, "snd": "w_pump"}],
				[3.8, {"bolt": 0.0, "lh": B}],
				[4.0, {"bolt": 1.0, "lh": B + bt, "snd": "w_pump"}],
				[4.2, {"bolt": 0.0, "lh": B, "snd": "w_charge"}],
				[4.6, {"wr": Vector3(12, -54, 12), "wp": Vector3(-0.3, 0.07, 0.0), "ld": 1.0, "lp": Vector3(-0.22, -0.28, -0.32), "lc": 0.6, "lh": Z, "lg": 0.0, "lt": 1.0}],
				[5.0, {"wr": Vector3(16, -62, 16), "ld": 1.0}],
				[5.4, {"wr": Vector3(-4, 0, -2), "wp": Vector3(0, 0.01, -0.03), "ld": 0.0, "lc": 0.0, "le": 0.4}],
				[5.8, {}],
			]
		_:
			return [
				[0.0, {"snd": "w_cloth"}],
				[0.6, {"wp": Vector3(-0.03, 0.06, -0.05), "wr": Vector3(34, 50, -16), "le": 0.6, "lt": 0.0, "lh": Z, "chg": 0.0, "ld": 1.0, "lp": Vector3(-0.26, -0.34, -0.26), "lc": 0.6}],
				[1.0, {"chg": 0.0, "snd": "w_charge"}],
				[1.9, {"chg": 1.0, "wp": Vector3(-0.06, 0.09, 0.04), "wr": Vector3(28, 60, -24), "lt": 0.6, "ld": 1.0, "lc": 0.6}],
				[2.3, {"chg": 0.0, "lh": B, "lg": 0.5, "bolt": 0.0, "ld": 0.0, "lc": 0.0}],
				[2.6, {"bolt": 1.0, "lh": B + bt, "snd": "w_rack"}],
				[3.1, {"bolt": 1.0, "lh": M, "lg": 1.0, "mag": 0.0, "wr": Vector3(20, 40, -40), "wp": Vector3(-0.05, 0.07, 0.05)}],
				[3.4, {"mag": 0.6, "lh": M + D * 0.15, "snd": "w_magout"}],
				[3.9, {"mag": 0.6, "mr": Z, "lh": M + D * 0.15 + Vector3(0, 0.02, 0.02)}],
				[4.3, {"mr": Vector3(180, 0, 0), "lt": 1.0}],
				[4.7, {"mr": Vector3(360, 0, 0), "mag": 0.6}],
				[5.0, {"mag": 0.0, "lh": M, "snd": "w_magin"}],
				[5.3, {"bolt": 1.0, "lh": B + bt, "lg": 0.5}],
				[5.5, {"bolt": 0.0, "lh": B, "chg": 0.0, "snd": "w_click"}],
				[5.6, {"chg": 0.0, "snd": "w_charge"}],
				[6.2, {"chg": 1.0, "lh": Z, "lg": 0.0, "wr": Vector3(10, 10, -8), "wp": Vector3(-0.02, 0.03, -0.02)}],
				[6.6, {"wp": Vector3(0, 0.005, -0.02), "wr": Z, "le": 0.3, "chg": 1.0}],
				[7.0, {}],
			]
