class_name Humanoid
extends Node3D
## Articulated human figure, modelled in code: tapered limbs, a shaped head, layered clothing
## and per-person variation. Animation is procedural: a gait cycle tied to ground speed (so feet
## do not slide), eased start and stop, and secondary motion in the spine, head and arms.

const LEG := 0.87

var kind := "survivor"
var pose := "idle"
var phase := 0.0
var move_speed := 0.0
var t := 0.0
var look_yaw := 0.0
var style := 0
var body: Node3D
var torso: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var fore_l: Node3D
var fore_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var shin_l: Node3D
var shin_r: Node3D
var foot_l: Node3D
var foot_r: Node3D
var rig: Node3D = null
var rig_holder: Node3D = null
var anim: AnimationPlayer = null
var seed_f := 0.0
var gait := 0.0
var cur: Dictionary = {}
# per-person movement character
var v_amp := 0.42
var v_arm := 1.0
var v_slouch := 0.0
var v_tilt := 0.0
var v_cad := 1.0
var gest_t := 4.0
var gest := 0.0

func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n

## An elliptical tapered tube along y: r0 at the bottom (y0), r1 at the top (y1), depth = width * zs.
func _tube(mb: Kit, mk: String, y0: float, y1: float, r0: float, r1: float, zs: float = 1.0, x: float = 0.0, z: float = 0.0, seg: int = 10) -> void:
	var keep: Transform3D = mb.xf
	mb.xf = keep * Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 1.0, zs)), Vector3(x, 0.0, z))
	mb.cyl(mk, Vector3(0, (y0 + y1) * 0.5, 0), r0, y1 - y0, 1, seg, r1)
	mb.xf = keep

func setup(seed_i: int, k: String) -> void:
	kind = k
	if k == "raider" and _setup_rigged(seed_i):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i * 7919 + 13
	seed_f = rng.randf() * 10.0
	var skins: Array = [Color(0.8, 0.62, 0.5), Color(0.72, 0.53, 0.41), Color(0.56, 0.4, 0.3), Color(0.84, 0.68, 0.58), Color(0.44, 0.31, 0.24)]
	var jackets: Array = [Color(0.2, 0.25, 0.19), Color(0.14, 0.18, 0.27), Color(0.33, 0.15, 0.13), Color(0.4, 0.31, 0.18), Color(0.25, 0.26, 0.28), Color(0.17, 0.25, 0.27), Color(0.44, 0.38, 0.28), Color(0.3, 0.2, 0.26)]
	var pants: Array = [Color(0.12, 0.13, 0.16), Color(0.19, 0.17, 0.14), Color(0.11, 0.15, 0.21), Color(0.23, 0.23, 0.22), Color(0.16, 0.19, 0.15)]
	var hairs: Array = [Color(0.09, 0.07, 0.06), Color(0.26, 0.17, 0.09), Color(0.5, 0.47, 0.43), Color(0.4, 0.27, 0.14), Color(0.62, 0.52, 0.33)]
	var skin: Color = skins[rng.randi() % skins.size()]
	var jacket: Color = jackets[rng.randi() % jackets.size()]
	var second: Color = jackets[rng.randi() % jackets.size()]
	var pant: Color = pants[rng.randi() % pants.size()]
	var hair: Color = hairs[rng.randi() % hairs.size()]
	var bw: float = rng.randf_range(0.93, 1.1)
	var tall: float = rng.randf_range(0.95, 1.04)
	var outfit: int = rng.randi() % 5
	var hat: int = rng.randi() % 6
	var beard: bool = rng.randf() < 0.35
	var pack: bool = rng.randf() < 0.4
	var gloves: bool = rng.randf() < 0.6
	v_amp = rng.randf_range(0.37, 0.46)
	v_arm = rng.randf_range(0.7, 1.25)
	v_slouch = rng.randf_range(-0.02, 0.09)
	v_tilt = rng.randf_range(-0.05, 0.05)
	v_cad = rng.randf_range(0.93, 1.08)
	gest_t = rng.randf_range(3.0, 9.0)
	style = seed_i % 3
	if k == "infected":
		skin = Color(0.47, 0.52, 0.49).lerp(Color(0.58, 0.56, 0.6), rng.randf())
		jacket = jacket.lerp(Color(0.11, 0.1, 0.09), 0.55)
		second = second.lerp(Color(0.11, 0.1, 0.09), 0.55)
		pant = pant.lerp(Color(0.07, 0.07, 0.07), 0.5)
		hat = 2 if rng.randf() < 0.6 else 5
		beard = false
		pack = false
		gloves = false
		v_slouch = 0.09
	elif k == "raider":
		jacket = Color(0.15, 0.17, 0.13)
		second = Color(0.1, 0.11, 0.09)
		pant = Color(0.1, 0.11, 0.1)
		outfit = 3
		hat = 6
		beard = false
		pack = false
		gloves = true
	var m_skin: String = Kit.cmat(skin, 0.75)
	var m_shade: String = Kit.cmat(skin * 0.72, 0.8)
	var m_jacket: String = Kit.cmat(jacket, 0.93)
	var m_second: String = Kit.cmat(second, 0.93)
	var m_trim: String = Kit.cmat(jacket * 0.6, 0.9)
	var m_pant: String = Kit.cmat(pant, 0.9)
	var m_boot: String = Kit.cmat(Color(0.075, 0.065, 0.055), 0.6)
	var m_sole: String = Kit.cmat(Color(0.03, 0.03, 0.03), 0.9)
	var m_hair: String = Kit.cmat(hair, 0.85)
	var m_dark: String = Kit.cmat(Color(0.04, 0.04, 0.045), 0.5)
	var m_hand: String = Kit.cmat(Color(0.16, 0.14, 0.12), 0.8) if gloves else m_skin
	var m_sleeve: String = m_second if outfit == 3 else m_jacket
	scale = Vector3(1.0, tall, 1.0)
	var sh: float = 0.205 * bw
	body = _pivot(self, Vector3.ZERO)
	# ---- pelvis
	var mp := Kit.new()
	_tube(mp, m_pant, 0.82, 0.99, 0.15 * bw, 0.158 * bw, 0.72)
	mp.ball(m_pant, Vector3(0, 0.83, 0.01), Vector3(0.15 * bw, 0.07, 0.108))
	mp.commit(body, false)
	# ---- torso: waist to shoulders, with the garment's own shape
	torso = _pivot(body, Vector3(0, 0.97, 0))
	var mt := Kit.new()
	var hem: float = -0.16 if (outfit == 0 or outfit == 2) else -0.06
	_tube(mt, m_jacket, hem, 0.02, 0.182 * bw, 0.168 * bw, 0.66)
	_tube(mt, m_jacket, 0.02, 0.24, 0.168 * bw, 0.176 * bw, 0.63)
	_tube(mt, m_jacket, 0.24, 0.46, 0.176 * bw, 0.192 * bw, 0.62)
	mt.ball(m_jacket, Vector3(0, 0.455, 0.0), Vector3(sh + 0.012, 0.075, 0.118))
	_tube(mt, m_skin, 0.48, 0.61, 0.05, 0.047, 1.0, 0.0, 0.006, 8)
	_tube(mt, m_trim, 0.47, 0.545, 0.078, 0.066, 0.95, 0.0, 0.012, 10)
	mt.box(m_trim, Vector3(0, 0.22, -0.112 * bw), Vector3(0.014, 0.44, 0.008))
	_tube(mt, m_dark, -0.035, 0.005, 0.172 * bw, 0.172 * bw, 0.66)
	mt.box(Kit.cmat(Color(0.5, 0.48, 0.42), 0.4), Vector3(0, -0.015, -0.115 * bw), Vector3(0.034, 0.03, 0.008))
	for sgn: float in [-1.0, 1.0]:
		mt.bbox(m_trim, Vector3(sgn * 0.09 * bw, 0.1, -0.103 * bw), Vector3(0.075, 0.07, 0.014), Basis(Vector3.UP, -sgn * 0.32), 0.004)
	match outfit:
		0:
			mt.ball(m_jacket, Vector3(0, 0.5, 0.085), Vector3(0.12, 0.075, 0.075))
			_tube(mt, Kit.cmat(Color(0.5, 0.44, 0.36), 0.98), 0.5, 0.56, 0.095, 0.09, 0.9, 0.0, 0.03, 10)
		1:
			_tube(mt, "amber_paint", 0.27, 0.32, 0.181 * bw, 0.184 * bw, 0.63)
			_tube(mt, "white_paint", 0.285, 0.305, 0.183 * bw, 0.185 * bw, 0.63)
		2:
			for sgn: float in [-1.0, 1.0]:
				mt.bbox(m_trim, Vector3(sgn * 0.045, 0.4, -0.112 * bw), Vector3(0.05, 0.15, 0.012), Basis(Vector3.BACK, sgn * 0.35), 0.004)
			for i in 3:
				mt.cyl(m_dark, Vector3(0.03, 0.08 + float(i) * 0.1, -0.114 * bw), 0.009, 0.006, 2, 6)
		3:
			_tube(mt, m_trim, 0.04, 0.455, 0.184 * bw, 0.2 * bw, 0.64)
			for sgn: float in [-1.0, 1.0]:
				mt.bbox(m_dark, Vector3(sgn * 0.085 * bw, 0.32, -0.126 * bw), Vector3(0.075, 0.09, 0.02), Basis.IDENTITY, 0.004)
		_:
			_tube(mt, m_second, 0.5, 0.58, 0.09, 0.082, 0.95, 0.0, 0.01, 10)
			mt.bbox(m_second, Vector3(0.05, 0.36, -0.122 * bw), Vector3(0.07, 0.26, 0.02), Basis(Vector3.BACK, -0.08), 0.005)
	if pack:
		var m_pack: String = Kit.cmat(Color(0.2, 0.19, 0.15).lerp(second, 0.3), 0.95)
		mt.bbox(m_pack, Vector3(0, 0.27, 0.165), Vector3(0.27, 0.38, 0.13), Basis.IDENTITY, 0.03)
		mt.bbox(m_pack, Vector3(0, 0.2, 0.24), Vector3(0.2, 0.16, 0.05), Basis.IDENTITY, 0.015)
		for sgn: float in [-1.0, 1.0]:
			mt.box(m_dark, Vector3(sgn * 0.13 * bw, 0.3, -0.108 * bw), Vector3(0.035, 0.36, 0.01))
			mt.box(m_dark, Vector3(sgn * 0.13 * bw, 0.5, 0.0), Vector3(0.035, 0.012, 0.24))
	if k == "infected":
		mt.box("grime", Vector3(0.05, 0.3, -0.118 * bw), Vector3(0.14, 0.2, 0.004), Basis(Vector3.BACK, 0.3))
		mt.box("grime", Vector3(-0.07, 0.1, -0.11 * bw), Vector3(0.08, 0.14, 0.004))
	mt.commit(torso, false)
	# ---- head
	head = _pivot(torso, Vector3(0, 0.585, 0.004))
	var mh := Kit.new()
	mh.ball(m_skin, Vector3(0, 0.128, 0.006), Vector3(0.09, 0.104, 0.103), 12, 8)
	_tube(mh, m_skin, 0.018, 0.125, 0.05, 0.088, 1.04, 0.0, -0.012, 10)
	mh.ball(m_skin, Vector3(0, 0.03, -0.03), Vector3(0.05, 0.03, 0.045), 8, 5)
	mh.bbox(m_skin, Vector3(0, 0.098, -0.105), Vector3(0.024, 0.046, 0.03), Basis(Vector3.RIGHT, -0.3), 0.007)
	mh.box(m_shade, Vector3(0, 0.148, -0.092), Vector3(0.118, 0.014, 0.022))
	mh.box(m_shade, Vector3(0, 0.056, -0.084), Vector3(0.038, 0.006, 0.01))
	for sgn: float in [-1.0, 1.0]:
		mh.box("win_lit" if k == "infected" else m_dark, Vector3(sgn * 0.035, 0.131, -0.094), Vector3(0.022, 0.009, 0.01))
		mh.bbox(m_skin, Vector3(sgn * 0.09, 0.112, 0.008), Vector3(0.014, 0.042, 0.026), Basis.IDENTITY, 0.005)
	if beard:
		_tube(mh, m_hair, 0.012, 0.075, 0.054, 0.084, 1.06, 0.0, -0.014, 10)
		mh.box(m_hair, Vector3(0, 0.073, -0.092), Vector3(0.05, 0.012, 0.012))
	match hat:
		0:
			var m_hat: String = Kit.cmat(second.lerp(Color(0.3, 0.3, 0.32), 0.3), 0.98)
			mh.ball(m_hat, Vector3(0, 0.168, 0.01), Vector3(0.098, 0.082, 0.108), 12, 6)
			_tube(mh, Kit.cmat(second * 0.7, 0.98), 0.128, 0.172, 0.097, 0.099, 1.1, 0.0, 0.008, 12)
			mh.ball(m_hair, Vector3(0, 0.09, 0.055), Vector3(0.082, 0.05, 0.055), 8, 5)
		1:
			var m_cap: String = Kit.cmat(jacket.lerp(Color(0.12, 0.12, 0.13), 0.5), 0.9)
			mh.ball(m_cap, Vector3(0, 0.168, 0.006), Vector3(0.096, 0.068, 0.106), 12, 6)
			mh.bbox(m_cap, Vector3(0, 0.158, -0.135), Vector3(0.13, 0.012, 0.09), Basis(Vector3.RIGHT, -0.12), 0.005)
			mh.ball(m_hair, Vector3(0, 0.1, 0.045), Vector3(0.09, 0.06, 0.068), 8, 5)
		2:
			mh.ball(m_hair, Vector3(0, 0.152, 0.02), Vector3(0.096, 0.09, 0.106), 12, 7)
			mh.bbox(m_hair, Vector3(0.02, 0.19, -0.075), Vector3(0.1, 0.03, 0.05), Basis(Vector3.BACK, -0.15), 0.01)
		3:
			mh.ball(m_hair, Vector3(0, 0.15, 0.022), Vector3(0.098, 0.092, 0.108), 12, 7)
			mh.ball(m_hair, Vector3(0, 0.06, 0.07), Vector3(0.082, 0.12, 0.06), 10, 6)
			for sgn: float in [-1.0, 1.0]:
				mh.ball(m_hair, Vector3(sgn * 0.078, 0.09, 0.02), Vector3(0.03, 0.1, 0.06), 8, 5)
		4:
			var m_fur: String = Kit.cmat(Color(0.3, 0.25, 0.19), 0.98)
			mh.ball(Kit.cmat(Color(0.2, 0.18, 0.15), 0.95), Vector3(0, 0.172, 0.008), Vector3(0.102, 0.078, 0.11), 12, 6)
			_tube(mh, m_fur, 0.132, 0.19, 0.102, 0.104, 1.08, 0.0, 0.008, 12)
			for sgn: float in [-1.0, 1.0]:
				mh.bbox(m_fur, Vector3(sgn * 0.1, 0.085, 0.012), Vector3(0.022, 0.11, 0.09), Basis(Vector3.BACK, sgn * 0.1), 0.01)
		5:
			mh.ball(m_hair, Vector3(0, 0.105, 0.035), Vector3(0.095, 0.058, 0.096), 10, 5)
		_:
			var m_helm: String = Kit.cmat(Color(0.13, 0.15, 0.11), 0.6)
			mh.ball(m_helm, Vector3(0, 0.165, 0.008), Vector3(0.112, 0.088, 0.124), 12, 6)
			_tube(mh, m_helm, 0.128, 0.15, 0.116, 0.113, 1.1, 0.0, 0.008, 12)
			_tube(mh, m_dark, 0.01, 0.118, 0.056, 0.092, 1.06, 0.0, -0.014, 10)
			mh.box(m_dark, Vector3(0, 0.14, -0.098), Vector3(0.13, 0.03, 0.016))
	mh.commit(head, false)
	# ---- arms and legs
	arm_l = _pivot(torso, Vector3(-sh, 0.445, 0))
	arm_r = _pivot(torso, Vector3(sh, 0.445, 0))
	var torn: bool = k == "infected" and rng.randf() < 0.6
	fore_l = _arm(arm_l, -1.0, m_sleeve, m_skin if torn else m_sleeve, m_trim, m_hand, outfit == 1)
	fore_r = _arm(arm_r, 1.0, m_sleeve, m_sleeve, m_trim, m_hand, outfit == 1)
	leg_l = _pivot(body, Vector3(-0.088 * bw, 0.93, 0))
	leg_r = _pivot(body, Vector3(0.088 * bw, 0.93, 0))
	var legs: Array = [leg_l, leg_r]
	for i in 2:
		var lg: Node3D = legs[i]
		var ml := Kit.new()
		_tube(ml, m_pant, -0.44, 0.0, 0.064, 0.084, 1.05)
		ml.ball(m_pant, Vector3(0, -0.44, -0.006), Vector3(0.064, 0.06, 0.066), 8, 5)
		ml.commit(lg, false)
		var sn: Node3D = _pivot(lg, Vector3(0, -0.44, 0))
		var ms := Kit.new()
		_tube(ms, m_pant, -0.31, 0.0, 0.052, 0.062, 1.05)
		_tube(ms, m_boot, -0.43, -0.27, 0.05, 0.057, 1.05)
		_tube(ms, m_sole, -0.285, -0.265, 0.059, 0.059, 1.05)
		if k == "infected" and i == seed_i % 2:
			ms.box("grime", Vector3(0, -0.15, -0.056), Vector3(0.07, 0.16, 0.004))
		ms.commit(sn, false)
		var ft: Node3D = _pivot(sn, Vector3(0, -0.43, 0))
		var mf := Kit.new()
		mf.bbox(m_boot, Vector3(0, -0.022, -0.04), Vector3(0.09, 0.07, 0.19), Basis.IDENTITY, 0.02)
		mf.ball(m_boot, Vector3(0, -0.026, -0.128), Vector3(0.045, 0.036, 0.048), 8, 5)
		mf.bbox(m_sole, Vector3(0, -0.061, -0.05), Vector3(0.094, 0.012, 0.24), Basis.IDENTITY, 0.004)
		mf.box(m_sole, Vector3(0, -0.067, 0.04), Vector3(0.086, 0.012, 0.06))
		for q in 3:
			mf.box(m_dark, Vector3(0, 0.015, -0.05 - float(q) * 0.028), Vector3(0.05, 0.004, 0.008))
		mf.commit(ft, false)
		if i == 0:
			shin_l = sn
			foot_l = ft
		else:
			shin_r = sn
			foot_r = ft
	if k == "raider":
		var mg := Kit.new()
		mg.bbox("gun_blk", Vector3(0, -0.27, -0.16), Vector3(0.04, 0.06, 0.5), Basis.IDENTITY, 0.008)
		mg.bbox("gun_poly", Vector3(0, -0.33, -0.1), Vector3(0.028, 0.11, 0.05), Basis(Vector3.RIGHT, 0.2), 0.006)
		mg.cyl("gun_blk", Vector3(0, -0.262, -0.5), 0.01, 0.22, 2, 8)
		mg.bbox("gun_poly", Vector3(0, -0.275, 0.16), Vector3(0.034, 0.08, 0.16), Basis.IDENTITY, 0.008)
		mg.commit(fore_r, false)

func _arm(piv: Node3D, sgn: float, m_up: String, m_low: String, m_cuff: String, m_hand: String, hivis: bool) -> Node3D:
	var mu := Kit.new()
	mu.ball(m_up, Vector3(0, -0.005, 0), Vector3(0.062, 0.062, 0.066), 8, 5)
	_tube(mu, m_up, -0.29, 0.0, 0.049, 0.06, 1.05)
	if hivis:
		_tube(mu, "amber_paint", -0.2, -0.16, 0.054, 0.056, 1.05)
	mu.commit(piv, false)
	var f: Node3D = _pivot(piv, Vector3(0, -0.29, 0))
	var mf := Kit.new()
	mf.ball(m_up, Vector3(0, 0, 0.004), Vector3(0.05, 0.05, 0.054), 8, 5)
	_tube(mf, m_low, -0.245, 0.0, 0.037, 0.049, 1.02)
	_tube(mf, m_cuff, -0.25, -0.215, 0.041, 0.042, 1.02)
	# hand: palm, curled fingers and a thumb, palm turned toward the body
	mf.bbox(m_hand, Vector3(0, -0.295, 0), Vector3(0.03, 0.09, 0.076), Basis.IDENTITY, 0.01)
	mf.bbox(m_hand, Vector3(-sgn * 0.012, -0.368, 0.004), Vector3(0.026, 0.07, 0.07), Basis(Vector3.BACK, -sgn * 0.45), 0.01)
	mf.bbox(m_hand, Vector3(-sgn * 0.012, -0.31, -0.046), Vector3(0.022, 0.06, 0.022), Basis(Vector3.RIGHT, -0.5), 0.008)
	mf.commit(f, false)
	return f

func _sm(key: String, target: float, rate: float, dt: float) -> float:
	var c: float = cur.get(key, target)
	c = lerpf(c, target, clampf(dt * rate, 0.0, 1.0))
	cur[key] = c
	return c

static var soldier_ps: PackedScene = null
static var soldier_tried := false

## Fort Varda's soldiers use an authored, skinned model with motion-captured clips,
## cross-faded by the engine's animation player instead of the procedural rig.
func _setup_rigged(seed_i: int) -> bool:
	if not Humanoid.soldier_tried:
		Humanoid.soldier_tried = true
		var path := "res://assets/models/chars/%s.glb" % "soldier"
		if ResourceLoader.exists(path):
			Humanoid.soldier_ps = load(path)
	if Humanoid.soldier_ps == null:
		return false
	seed_f = float(seed_i % 97) * 0.37
	rig_holder = Node3D.new()
	add_child(rig_holder)
	rig = Humanoid.soldier_ps.instantiate()
	rig_holder.add_child(rig)
	for apn: Node in rig.find_children("*", "AnimationPlayer", true, false):
		anim = apn as AnimationPlayer
		break
	if anim != null:
		for an: String in anim.get_animation_list():
			var a: Animation = anim.get_animation(an)
			a.loop_mode = Animation.LOOP_LINEAR
		_rig_play("Idle", 0.0)
		anim.seek(fmod(seed_f, 2.0), true)
	for skn: Node in rig.find_children("*", "Skeleton3D", true, false):
		var sk: Skeleton3D = skn as Skeleton3D
		for bi in sk.get_bone_count():
			if sk.get_bone_name(bi).ends_with("RightHand"):
				var ba := BoneAttachment3D.new()
				ba.bone_name = sk.get_bone_name(bi)
				sk.add_child(ba)
				var gs: float = maxf(0.0001, sk.global_transform.basis.get_scale().x)
				var gun := Node3D.new()
				gun.transform = Transform3D(Basis(Vector3.RIGHT, PI * 0.5).scaled(Vector3.ONE / gs), Vector3(0, 0.07, 0.03) / gs)
				ba.add_child(gun)
				var mg := Kit.new()
				var kb: Array = Kit.bevel_push(0.004, 0.009, 1000000.0)
				mg.box("gun_blk", Vector3(0, 0.02, -0.16), Vector3(0.04, 0.06, 0.5))
				mg.box("gun_poly", Vector3(0, -0.05, 0.0), Vector3(0.028, 0.11, 0.05), Basis(Vector3.RIGHT, 0.2))
				mg.box("gun_poly", Vector3(0, -0.08, -0.14), Vector3(0.026, 0.12, 0.05), Basis(Vector3.RIGHT, 0.25))
				mg.box("gun_poly", Vector3(0, 0.01, 0.17), Vector3(0.034, 0.08, 0.18))
				mg.cyl("gun_blk", Vector3(0, 0.03, -0.5), 0.01, 0.22, 2, 8)
				Kit.bevel_pop(kb)
				mg.commit(gun, false)
				break
		break
	return true

func _rig_play(want: String, blend: float) -> void:
	if anim == null:
		return
	var found := ""
	for an: String in anim.get_animation_list():
		if an == want or an.to_lower().ends_with(want.to_lower()):
			found = an
	if found != "" and anim.current_animation != found:
		anim.play(found, blend)

func _animate_rig(dt: float) -> void:
	if pose == "down":
		if anim != null and anim.is_playing():
			anim.pause()
		rig_holder.rotation.x = lerp_angle(rig_holder.rotation.x, -PI * 0.5, clampf(dt * 4.0, 0.0, 1.0))
		rig_holder.position.y = lerpf(rig_holder.position.y, 0.12, clampf(dt * 4.0, 0.0, 1.0))
		return
	var want := "Idle"
	if (pose == "walk" or pose == "shamble") and move_speed > 0.15:
		want = "Run" if move_speed > 1.3 else "Walk"
	_rig_play(want, 0.35)

func animate(dt: float) -> void:
	t += dt
	if rig_holder != null:
		_animate_rig(dt)
		return
	var speed: float = move_speed * 2.0
	var cyc: bool = pose == "walk" or pose == "shamble" or pose == "attack"
	var moving: bool = cyc and (speed > 0.08 or pose == "walk")
	gait = move_toward(gait, 1.0 if moving else 0.0, dt * (3.2 if moving else 4.2))
	var w: float = gait * gait * (3.0 - 2.0 * gait)
	var amp: float = v_amp * clampf(0.55 + speed * 0.4, 0.6, 1.25)
	var infected: bool = kind == "infected"
	if infected:
		amp = (0.3 if style == 1 else 0.4) * clampf(0.6 + speed * 0.3, 0.6, 1.3)
	# phase advances with the ground covered: one full cycle is two steps
	var stride: float = 4.0 * LEG * sin(amp)
	var rate: float = TAU * maxf(speed, 0.5 if moving else 0.0) / maxf(0.4, stride) * v_cad
	if infected and style == 2:
		rate *= 1.0 + 0.45 * sin(t * 3.1 + seed_f)
	phase += dt * rate
	var s: float = sin(phase)
	var c: float = cos(phase)
	var breathe: float = sin(t * 1.5 + seed_f)
	var sway: float = sin(t * 0.33 + seed_f) * (1.0 - w)
	# ---- static pose targets
	var ll := 0.0
	var lr := 0.0
	var sl := 0.0
	var sr := 0.0
	var al := 0.04
	var ar := 0.04
	var zl := 0.07
	var zr := 0.07
	var el := 0.18
	var er := 0.2
	var tx: float = -v_slouch
	var ty := 0.0
	var tz: float = v_tilt * 0.4
	var hx: float = v_slouch * 0.5
	var hy := 0.0
	var hz: float = v_tilt
	var by := 0.0
	var bx := 0.0
	var brx := 0.0
	var bry := 0.0
	var brz := 0.0
	var seated := false
	match pose:
		"sit", "eat":
			seated = true
			ll = 1.5
			lr = 1.5
			sl = -1.52
			sr = -1.48
			al = 0.42
			ar = 0.46
			el = 0.95
			er = 0.9
			zl = 0.02
			zr = 0.02
			by = -0.39
			tx = 0.07 - v_slouch * 0.5
			hx = -0.05
			if pose == "eat":
				var bite: float = maxf(0.0, sin(t * 1.5 + seed_f))
				ar = 0.62 + 0.45 * bite
				er = 1.25 + 0.75 * bite
				tx -= 0.1 * bite
				hx = -0.16 * bite
		"sleep":
			seated = true
			ll = 1.42
			lr = 1.5
			sl = -1.3
			sr = -1.45
			al = 0.22
			ar = 0.3
			el = 1.05
			er = 0.95
			by = -0.39
			tx = 0.26
			hx = 0.22
			hz = 0.34 if v_tilt >= 0.0 else -0.34
			tz = 0.08 if v_tilt >= 0.0 else -0.08
		"work":
			var reach: float = sin(t * 2.1 + seed_f)
			al = 0.95 + 0.28 * reach
			ar = 1.05 - 0.3 * reach
			el = 0.75 + 0.25 * sin(t * 4.3 + seed_f)
			er = 0.65 - 0.2 * reach
			tx = -0.2 - 0.05 * absf(reach)
			ty = 0.1 * reach
			hx = -0.22
			sl = -0.1
			sr = -0.08
			ll = 0.05
		"talk":
			var g1: float = sin(t * 2.2 + seed_f)
			var g2: float = sin(t * 1.3 + seed_f * 2.0)
			ar = 0.5 + 0.28 * g1
			er = 1.15 + 0.3 * sin(t * 3.1 + seed_f)
			zr = 0.12 + 0.08 * g2
			al = 0.1 + 0.1 * maxf(0.0, g2)
			el = 0.35 + 0.5 * maxf(0.0, g2)
			hz += 0.07 * g2
			hy = 0.12 * sin(t * 0.8 + seed_f)
			hx += 0.05 * g1
			ty = 0.06 * g2
		"aim":
			al = 1.28
			ar = 1.4
			el = 0.5
			er = 0.2
			zl = -0.28
			zr = 0.0
			tx = -0.06
			ty = -0.2
			hy = 0.16
			ll = 0.12
			lr = -0.16
			sr = -0.12
			bry = 0.25
		"wave":
			ar = 2.75
			zr = 0.25
			er = 0.4 + sin(t * 9.0) * 0.38
			hz += 0.08
			tz -= 0.04
		"stagger":
			tx = 0.42
			al = -0.5
			ar = -0.3
			zl = 0.35
			zr = 0.3
			el = 0.6
			er = 0.4
			hx = -0.35
			ll = -0.28
			sl = -0.34
			by = -0.03
		"down":
			ll = 0.2
			lr = -0.12
			sl = -0.3
			al = 0.6
			ar = -0.3
			zl = 0.5
			zr = 0.4
			brx = -PI * 0.5
			by = 0.12
	# ---- standing idle: weight shifts between the feet, the body breathes
	if not seated and pose != "down":
		var k_idle: float = 1.0 - w
		bx += 0.022 * sway
		brz += 0.035 * sway
		tz -= 0.03 * sway
		sl -= 0.07 * maxf(0.0, sway) * k_idle
		sr -= 0.07 * maxf(0.0, -sway) * k_idle
		by -= 0.004 * absf(sway)
	tx += 0.012 * breathe * (1.0 - w)
	zl += 0.008 * breathe
	zr += 0.008 * breathe
	if not cyc and pose != "sleep" and pose != "down":
		hy += 0.22 * sin(t * 0.21 + seed_f) * sin(t * 0.13 + seed_f * 0.7)
		hx += 0.04 * sin(t * 0.31 + seed_f)
	# an occasional small gesture so no two idle people move alike
	if pose == "idle" or pose == "sit":
		gest_t -= dt
		if gest_t <= 0.0:
			gest_t = 5.0 + fmod(seed_f * 3.7 + t, 7.0)
			gest = 1.0
	gest = maxf(0.0, gest - dt * 0.55)
	if gest > 0.0:
		var ge: float = sin(clampf(gest, 0.0, 1.0) * PI)
		al += 0.5 * ge
		el += 1.3 * ge
		hx -= 0.12 * ge
		hy -= 0.15 * ge
	# ---- infected carriage, by individual
	if infected and pose != "down":
		match style:
			0:
				tz += 0.16
				tx -= 0.14
				hz += 0.3
				al += 0.12 + 0.1 * sin(t * 1.7 + seed_f)
				zl += 0.1
			1:
				tx -= 0.24
				hx += 0.22
				al += 1.15 + 0.12 * sin(t * 4.0 + seed_f)
				ar += 1.0 + 0.14 * sin(t * 3.3)
				el += 0.2
				er += 0.35
			_:
				tx -= 0.14
				ar += 0.9 + 0.3 * sin(t * 6.0 + seed_f)
				er += 0.8
				zl += 0.16
				hy += 0.4 * signf(sin(t * 2.3 + seed_f)) * maxf(0.0, sin(t * 0.9))
				ty += 0.12 * sin(t * 5.0 + seed_f)
		if pose == "attack":
			var lunge: float = sin(t * 14.0 + seed_f)
			al = 1.45 + lunge * 0.32
			ar = 1.5 - lunge * 0.32
			el = 0.2
			er = 0.2
			tx -= 0.2
			hx += 0.2
	# ---- eased joints: limbs follow quickly, spine and head trail behind
	ll = _sm("ll", ll, 9.0, dt)
	lr = _sm("lr", lr, 9.0, dt)
	sl = _sm("sl", sl, 9.0, dt)
	sr = _sm("sr", sr, 9.0, dt)
	al = _sm("al", al, 6.5, dt)
	ar = _sm("ar", ar, 6.5, dt)
	zl = _sm("zl", zl, 6.0, dt)
	zr = _sm("zr", zr, 6.0, dt)
	el = _sm("el", el, 8.0, dt)
	er = _sm("er", er, 8.0, dt)
	tx = _sm("tx", tx, 5.0, dt)
	ty = _sm("ty", ty, 5.0, dt)
	tz = _sm("tz", tz, 4.0, dt)
	hx = _sm("hx", hx, 4.5, dt)
	hy = _sm("hy", hy + look_yaw, 4.0, dt)
	hz = _sm("hz", hz, 3.5, dt)
	by = _sm("by", by, 5.5, dt)
	bx = _sm("bx", bx, 3.0, dt)
	brx = _sm("brx", brx, 4.0, dt)
	bry = _sm("bry", bry, 5.0, dt)
	brz = _sm("brz", brz, 3.0, dt)
	# ---- the gait cycle, added on top in proportion to how much of a walk this is
	var fl := 0.0
	var fr := 0.0
	if w > 0.001:
		var al_amp: float = amp
		var ar_amp: float = amp
		var kl := 0.85
		var kr := 0.85
		if infected and style == 0:
			ar_amp = amp * 0.45
			kr = 0.1
		ll += s * al_amp * w
		lr -= s * ar_amp * w
		sl -= (0.1 + kl * maxf(0.0, c)) * w
		sr -= (0.1 + kr * maxf(0.0, -c)) * w
		# heel strike and toe-off
		fl = (0.24 * maxf(0.0, s) * maxf(0.0, s) - 0.38 * maxf(0.0, -s) * maxf(0.0, -s)) * w
		fr = (0.24 * maxf(0.0, -s) * maxf(0.0, -s) - 0.38 * maxf(0.0, s) * maxf(0.0, s)) * w
		# the hips ride the stance leg: down when the legs are spread, over the planted foot between
		by += LEG * (cos(amp * s) - 1.0) * w
		bx += 0.018 * c * w
		brz += 0.03 * c * w
		bry -= 0.08 * s * w
		ty += 0.15 * s * w
		tx -= (0.035 + 0.02 * speed) * w
		hy -= 0.08 * s * w
		hx += 0.012 * sin(phase * 2.0) * w
		if not infected:
			al -= s * 0.46 * v_arm * w
			ar += s * 0.46 * v_arm * w
			el += (0.14 + 0.3 * maxf(0.0, -s)) * w
			er += (0.14 + 0.3 * maxf(0.0, s)) * w
		elif style == 0:
			al -= s * 0.2 * w
			ar += sin(phase - 0.6) * 0.3 * w
	# ---- apply
	leg_l.rotation.x = ll
	leg_r.rotation.x = lr
	shin_l.rotation.x = sl
	shin_r.rotation.x = sr
	foot_l.rotation.x = clampf(-(ll + sl), -0.9, 0.9) + fl if not seated else clampf(-(ll + sl), -0.6, 0.6)
	foot_r.rotation.x = clampf(-(lr + sr), -0.9, 0.9) + fr if not seated else clampf(-(lr + sr), -0.6, 0.6)
	arm_l.rotation = Vector3(al, 0.0, -zl)
	arm_r.rotation = Vector3(ar, 0.0, zr)
	fore_l.rotation.x = el
	fore_r.rotation.x = er
	torso.rotation = Vector3(tx, ty, tz)
	head.rotation = Vector3(hx, clampf(hy, -1.2, 1.2), hz)
	body.position = Vector3(bx, by, 0.0)
	body.rotation = Vector3(brx, bry, brz)
