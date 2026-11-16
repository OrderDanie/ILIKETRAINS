class_name TrainRig
extends Node3D
## The train: locomotive + coupled carriages. Simulation (simulate) is separate from visuals (render).

const CL := 16.0
const GAP := 1.0
const LL := 15.0
const FY := 1.25
const CY := 3.5
const TYPE_LABEL := {"passenger": "PASSENGER", "storage": "STORAGE", "medical": "MEDICAL", "kitchen": "KITCHEN", "workshop": "WORKSHOP", "generator": "GENERATOR", "security": "SECURITY", "greenhouse": "GREENHOUSE", "water": "WATER TREATMENT"}

var main
var veh: Array = []
var wheels: Array = []
var doors: Array = []
var door_t := 0.0
var lamps: Array = []
var spots: Array = []
var wipers: Array = []
var wipe_t := 0.0
var thr_lever: Node3D
var brk_lever: Node3D
var d_speed: Label3D
var d_stat: Label3D
var d_info: Label3D
var seat_slots: Array = []
var work_slots: Dictionary = {}
var wheel_mesh: ArrayMesh
var flick := 0.0
var collided := 0.0
var low := false
var strap_pts: Array = []
var strap_mmi: MultiMeshInstance3D
var needles: Array = []
var displays: Array = []
var exhaust: CPUParticles3D
var sprays: Array = []
var beams: MeshInstance3D
var beam_mat: StandardMaterial3D
var prev_v := 0.0
var acc_s := 0.0
var anim_t := 0.0
var joint_d := 0.0
var joint_kick := 0.0
var disp_t := 0.0
var disp_i := 0
var disp_freeze := false
var loco_node: Node3D
var shadow_mat: StandardMaterial3D
var danglers: Array = []
var stacks: Array = []
var vents: Array = []
var sparks: Array = []

static func car_z(i: int) -> float:
	return GAP + float(i) * (CL + GAP)

func tail_z() -> float:
	return car_z(maxi(0, GS.cars.size() - 1)) + CL

func build() -> void:
	var kb0: Array = Kit.bevel_push(0.012, 0.04, 4.0)
	var mb := Kit.new()
	mb.cyl("steel_dk", Vector3.ZERO, 0.08, 1.9, 0, 8)
	for sgn: float in [-1.0, 1.0]:
		mb.cyl("wheel", Vector3(sgn * 0.75, 0, 0), 0.46, 0.13, 0, 28)
		mb.cyl("rail", Vector3(sgn * 0.75, 0, 0), 0.47, 0.05, 0, 28)
		mb.cyl("steel_dk", Vector3(sgn * 0.45, 0, 0), 0.3, 0.05, 0, 12)
		mb.cyl("rail", Vector3(sgn * 0.7, 0, 0), 0.5, 0.028, 0, 18)
		mb.cyl("steel", Vector3(sgn * 0.3, 0, 0), 0.31, 0.035, 0, 14)
		mb.cyl("steel_dk", Vector3(sgn * 0.83, 0, 0), 0.12, 0.05, 0, 10)
		for a in 5:
			var wa: float = float(a) * TAU / 5.0
			mb.cyl("rubber", Vector3(sgn * 0.817, cos(wa) * 0.27, sin(wa) * 0.27), 0.055, 0.006, 0, 8)
			mb.cyl("rail", Vector3(sgn * 0.857, cos(wa + 0.6) * 0.075, sin(wa + 0.6) * 0.075), 0.016, 0.012, 0, 5)
	wheel_mesh = mb.build_mesh()
	var ann_cols: Array = [Color(0.3, 1.0, 0.45), Color(1.0, 0.65, 0.15), Color(1.0, 0.15, 0.1), Color(1.0, 0.65, 0.15), Color(0.3, 1.0, 0.45), Color(1.0, 0.15, 0.1), Color(0.4, 0.7, 1.0), Color(1.0, 0.15, 0.1)]
	for i in 8:
		if not Kit.mats.has("ann_%d" % i):
			var ac: Color = ann_cols[i]
			Kit.glow("ann_%d" % i, ac, 0.04, Color(ac.r * 0.25, ac.g * 0.25, ac.b * 0.25))
	_build_loco()
	for i in GS.cars.size():
		add_carriage(i)
	Kit.bevel_pop(kb0)

func add_carriage(i: int) -> void:
	var d: Dictionary = GS.cars[i]
	var n: Node3D = make_carriage(d["type"], true, i)
	n.position = Vector3(0, 0, car_z(i))
	add_child(n)
	veh.append(n)
	rebuild_slots()
	apply_preset(int(GS.settings["preset"]))

func rebuild_slots() -> void:
	seat_slots = []
	work_slots = {}
	for n: Node3D in veh:
		var sl: Dictionary = n.get_meta("slots")
		var seats: Array = sl["seats"]
		for s: Array in seats:
			var p: Vector3 = s[0]
			seat_slots.append([p + n.position, s[1]])
		var work: Dictionary = sl["work"]
		for k: String in work.keys():
			var w: Array = work[k]
			var wp: Vector3 = w[0]
			if not work_slots.has(k):
				work_slots[k] = []
			var arr: Array = work_slots[k]
			arr.append([wp + n.position, w[1]])
	var fb: Dictionary = {"Repairs": [Vector3(0.95, FY, -6.5), PI * 0.5], "Power": [Vector3(0.95, FY, -2.6), PI * 0.5], "Guard": [Vector3(-0.8, FY, car_z(0) + 2.05), -PI * 0.5], "Medical": [Vector3(-0.7, FY, car_z(0) + 1.3), PI], "Sanitation": [Vector3(-0.8, FY, car_z(maxi(0, GS.cars.size() - 1)) + 1.4), PI * 0.5]}
	for k: String in fb.keys():
		if not work_slots.has(k):
			work_slots[k] = [fb[k]]
	seat_slots.append([Vector3(0.9, FY, -10.6), PI])
	strap_pts = []
	for n: Node3D in veh:
		var sl2: Dictionary = n.get_meta("slots")
		var st: Array = sl2.get("straps", [])
		for p: Vector3 in st:
			strap_pts.append(p + n.position)
	_build_straps()

func _build_straps() -> void:
	if strap_mmi == null:
		var mb := Kit.new()
		mb.box("rubber", Vector3(0, -0.09, 0), Vector3(0.022, 0.18, 0.005))
		mb.box("amber_paint", Vector3(0, -0.19, 0), Vector3(0.1, 0.016, 0.016))
		mb.box("amber_paint", Vector3(0, -0.27, 0), Vector3(0.1, 0.016, 0.016))
		mb.box("amber_paint", Vector3(-0.045, -0.23, 0), Vector3(0.016, 0.08, 0.016))
		mb.box("amber_paint", Vector3(0.045, -0.23, 0), Vector3(0.016, 0.08, 0.016))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mb.build_mesh()
		strap_mmi = MultiMeshInstance3D.new()
		strap_mmi.multimesh = mm
		strap_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(strap_mmi)
	strap_mmi.multimesh.instance_count = strap_pts.size()
	for i in strap_pts.size():
		var sp: Vector3 = strap_pts[i]
		strap_mmi.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, sp))

func _passenger_detail(mb: Kit, n: Node3D, straps: Array, idx: int) -> void:
	var F: float = FY
	var rng := RandomNumberGenerator.new()
	rng.seed = 311 + idx * 7
	mb.box("plastic", Vector3(0, F + 0.004, 9.2), Vector3(0.74, 0.008, 12.9))
	var bag_mats: Array = ["sack", "seat_dk", "red", "wood", "hull", "canvas"]
	for sgn: float in [-1.0, 1.0]:
		mb.box("amber_paint", Vector3(sgn * 0.39, F + 0.006, 9.2), Vector3(0.03, 0.008, 12.9))
		mb.cyl("steel", Vector3(sgn * 0.42, 3.32, 9.2), 0.014, 12.4, 2, 6)
		for k in 5:
			mb.cyl("steel", Vector3(sgn * 0.42, 3.41, 3.4 + float(k) * 2.9), 0.01, 0.18, 1, 4)
		for k in 8:
			straps.append(Vector3(sgn * 0.42, 3.31, 3.7 + float(k) * 1.5 + (0.4 if sgn > 0.0 else 0.0)))
		for k in 6:
			var a: float = 3.0 + float(k) * 2.15
			var b: float = a + 1.6
			mb.box("seat_dk", Vector3(sgn * 1.385, 2.62, a + 0.08), Vector3(0.03, 0.86, 0.16))
			mb.box("seat_dk", Vector3(sgn * 1.385, 2.62, b - 0.08), Vector3(0.03, 0.86, 0.16))
			if rng.randf() < 0.4:
				var bl: float = rng.randf_range(0.2, 0.6)
				mb.box("panel", Vector3(sgn * 1.41, 3.04 - bl * 0.5, (a + b) * 0.5), Vector3(0.012, bl, 1.3))
			if rng.randf() < 0.75:
				var bh: float = rng.randf_range(0.16, 0.3)
				var bm: String = bag_mats[rng.randi() % bag_mats.size()]
				mb.box(bm, Vector3(sgn * 1.2, 3.04 + bh * 0.5, a + rng.randf_range(0.3, 1.3)), Vector3(0.32, bh, rng.randf_range(0.4, 0.75)))
			if sgn > 0.0 or k < 5:
				var tz: float = a + 0.8
				if rng.randf() < 0.7:
					mb.cyl("white_paint", Vector3(sgn * (0.95 + rng.randf() * 0.2), F + 0.8, tz + rng.randf_range(-0.12, 0.12)), 0.035, 0.085, 1, 8)
				if rng.randf() < 0.5:
					mb.box("red" if rng.randf() < 0.5 else "hull", Vector3(sgn * 1.15, F + 0.775, tz + 0.05), Vector3(0.16, 0.035, 0.22), Basis(Vector3.UP, rng.randf() * 1.5))
				if rng.randf() < 0.3:
					mb.box("steel_dk", Vector3(sgn * 1.2, F + 0.83, tz - 0.1), Vector3(0.07, 0.14, 0.07))
					mb.box("lamp_warm", Vector3(sgn * 1.2, F + 0.84, tz - 0.1), Vector3(0.05, 0.08, 0.05))
				if rng.randf() < 0.35:
					mb.box("sack", Vector3(sgn * 0.93, F + 0.51, a + 0.34), Vector3(0.7, 0.05, 0.44))
		# route map strip above the windows
		mb.box("white_paint", Vector3(sgn * 1.398, 3.27, 8.4), Vector3(0.008, 0.2, 3.2))
		mb.box("amber_paint", Vector3(sgn * 1.393, 3.25, 8.4), Vector3(0.008, 0.02, 2.9))
		for k in 10:
			mb.box("hull_blk", Vector3(sgn * 1.39, 3.25, 7.0 + float(k) * 0.31), Vector3(0.008, 0.05, 0.05))
		Kit.text3d(n, Vector3(sgn * 1.39, 3.32, 8.4), "NORTHERN LINE   NORDHAVEN  -  KALDWICK PORT", 14, Color(0.1, 0.1, 0.12), -sgn * PI * 0.5, 0.004)
	# lived-in: a boarded window, bedding on the seats, a tally of days scratched by the door
	for i in 3:
		mb.box("wood", Vector3(-1.375, 2.32 + float(i) * 0.28, 12.4), Vector3(0.03, 0.17, 1.75), Basis(Vector3.RIGHT, 0.05 - 0.05 * float(i)))
		mb.cyl("steel_dk", Vector3(-1.355, 2.32 + float(i) * 0.28, 11.65), 0.012, 0.012, 0, 5)
		mb.cyl("steel_dk", Vector3(-1.355, 2.32 + float(i) * 0.28, 13.15), 0.012, 0.012, 0, 5)
	mb.cyl("canvas", Vector3(0.93, F + 0.61, 7.62), 0.12, 0.6, 0, 10)
	mb.box("steel_dk", Vector3(0.93, F + 0.61, 7.62), Vector3(0.05, 0.25, 0.25))
	mb.box("sack", Vector3(0.93, F + 0.53, 9.25), Vector3(0.9, 0.07, 0.46))
	mb.box("mattress", Vector3(0.75, F + 0.6, 9.28), Vector3(0.36, 0.09, 0.3))
	mb.cyl("steel", Vector3(-0.2, F + 0.06, 6.2), 0.035, 0.12, 0, 8)
	mb.cyl("steel", Vector3(0.24, F + 0.06, 10.9), 0.035, 0.12, 2, 8)
	mb.box("wood", Vector3(-0.93, F + 0.53, 5.5), Vector3(0.3, 0.09, 0.3))
	Kit.text3d(n, Vector3(-0.95, 2.42, 2.536), "DAY 41\n|||| |||| |||| ||||\n|||| |||| |||| ||||\n|", 26, Color(0.16, 0.14, 0.12), 0.0, 0.0026)
	# notices on the saloon side of the partition, litter on the floor
	mb.box("white_paint", Vector3(0.95, 3.02, 2.535), Vector3(0.5, 0.5, 0.01))
	mb.box("red", Vector3(0.95, 3.14, 2.542), Vector3(0.42, 0.14, 0.006))
	mb.box("white_paint", Vector3(-0.95, 3.02, 2.535), Vector3(0.44, 0.52, 0.01))
	mb.box("hull", Vector3(-0.95, 2.96, 2.542), Vector3(0.36, 0.3, 0.006))
	for k in 7:
		mb.box("white_paint", Vector3(rng.randf_range(-0.3, 0.3), F + 0.01, rng.randf_range(3.0, 15.5)), Vector3(0.15, 0.004, 0.2), Basis(Vector3.UP, rng.randf() * 3.0))

func work_slot(assign: String, idx: int) -> Array:
	if work_slots.has(assign):
		var arr: Array = work_slots[assign]
		return arr[idx % arr.size()]
	return []

# ---------------- shell pieces ----------------
func _pillar(mb: Kit, side: float, a: float, b: float) -> void:
	mb.box("hull_blk", Vector3(side * 1.475, 2.6, (a + b) * 0.5), Vector3(0.05, 0.9, b - a))
	mb.box("panel", Vector3(side * 1.425, 2.6, (a + b) * 0.5), Vector3(0.05, 0.9, b - a))

func _wall_run(mb: Kit, body: Node, side: float, z0: float, z1: float, wins: Array) -> void:
	var zc: float = (z0 + z1) * 0.5
	var zl: float = z1 - z0
	mb.box("hull", Vector3(side * 1.475, 1.5, zc), Vector3(0.05, 1.3, zl))
	mb.box("panel_dk", Vector3(side * 1.425, 1.7, zc), Vector3(0.05, 0.9, zl))
	mb.box("stripe", Vector3(side * 1.503, 2.07, zc), Vector3(0.012, 0.1, zl))
	mb.box("hull_lt", Vector3(side * 1.475, 3.275, zc), Vector3(0.05, 0.45, zl))
	mb.box("panel", Vector3(side * 1.425, 3.275, zc), Vector3(0.05, 0.45, zl))
	var cur: float = z0
	for w: Array in wins:
		var a: float = w[0]
		var b: float = w[1]
		if a > cur:
			_pillar(mb, side, cur, a)
		var wc: float = (a + b) * 0.5
		mb.box("glass", Vector3(side * 1.46, 2.6, wc), Vector3(0.02, 0.9, b - a))
		mb.box("rubber", Vector3(side * 1.49, 3.03, wc), Vector3(0.04, 0.05, b - a))
		mb.box("rubber", Vector3(side * 1.49, 2.17, wc), Vector3(0.04, 0.05, b - a))
		mb.box("steel_dk", Vector3(side * 1.385, 2.16, wc), Vector3(0.07, 0.03, b - a))
		mb.box("rubber", Vector3(side * 1.49, 2.6, a + 0.02), Vector3(0.04, 0.9, 0.04))
		mb.box("rubber", Vector3(side * 1.49, 2.6, b - 0.02), Vector3(0.04, 0.9, 0.04))
		cur = b
	if z1 > cur:
		_pillar(mb, side, cur, z1)
	# weathering: road grime along the sill, rust blooms, streaks under the windows, frost in the corners
	mb.box("grime", Vector3(side * 1.5042, 0.93, zc), Vector3(0.004, 0.15, zl))
	var wi: int = int(absf(z0) * 3.0) + int(zl)
	var rz: float = z0 + 0.7
	while rz < z1 - 0.5:
		wi += 1
		if wi % 3 != 1:
			mb.box("rust", Vector3(side * 1.5046, 0.98 + 0.05 * float(wi % 4), rz), Vector3(0.004, 0.1 + 0.07 * float(wi % 3), 0.18 + 0.1 * float(wi % 2)))
		if wi % 4 == 0:
			mb.box("grime", Vector3(side * 1.5044, 1.5, rz + 0.3), Vector3(0.003, 0.5 + 0.1 * float(wi % 3), 0.035))
		rz += 1.3 + 0.37 * float(wi % 3)
	for w2: Array in wins:
		var wa: float = w2[0]
		var wb: float = w2[1]
		mb.box("grime", Vector3(side * 1.5044, 1.96, wa + 0.05), Vector3(0.003, 0.34, 0.03))
		mb.box("grime", Vector3(side * 1.5044, 2.0, wb - 0.05), Vector3(0.003, 0.26, 0.03))
		mb.box("ice", Vector3(side * 1.4715, 2.24, wa + 0.2), Vector3(0.003, 0.1, 0.36))
		mb.box("ice", Vector3(side * 1.4715, 2.21, wb - 0.14), Vector3(0.003, 0.05, 0.24))
		for fz: float in [wa + 0.03, wb - 0.03]:
			mb.box("panel_dk", Vector3(side * 1.392, 2.6, fz), Vector3(0.022, 0.94, 0.05))
		mb.box("panel_dk", Vector3(side * 1.392, 3.055, (wa + wb) * 0.5), Vector3(0.022, 0.04, wb - wa))
	mb.cyl("steel_dk", Vector3(side * 1.12, 0.93, zc), 0.028, zl, 2, 6)
	mb.cyl("rust", Vector3(side * 0.95, 0.9, zc), 0.018, zl, 2, 5)
	var seam: float = z0 + 1.0
	while seam < z1 - 0.4:
		mb.box("hull_blk", Vector3(side * 1.502, 1.5, seam), Vector3(0.008, 1.26, 0.022))
		seam += 2.15
	mb.box("steel", Vector3(side * 1.503, 0.9, zc), Vector3(0.01, 0.03, zl))
	Kit.col(body, Vector3(side * 1.45, 2.3, zc), Vector3(0.1, 2.6, zl))

func _floor_roof(mb: Kit, body: Node, z0: float, z1: float) -> void:
	var zc: float = (z0 + z1) * 0.5
	var zl: float = z1 - z0
	mb.box("floor", Vector3(0, FY - 0.04, zc), Vector3(2.8, 0.08, zl))
	mb.box("under", Vector3(0, 1.02, zc), Vector3(2.7, 0.3, zl))
	Kit.col(body, Vector3(0, FY - 0.2, zc), Vector3(3.0, 0.4, zl))
	# curved roof shell with a snow cap, raised seams, gutters and closed ends
	mb.loft("roof", Kit.arc(0.0, CY, 1.52, 0.34, PI, 0.0, 12), z0, z1)
	mb.loft("snow", Kit.arc(0.0, CY + 0.03, 1.52, 0.34, PI * 0.72, PI * 0.28, 6), z0 + 0.2, z1 - 0.2)
	mb.loft("grille", Kit.arc(0.0, CY + 0.014, 1.52, 0.34, 1.151, 0.896, 3), z0 + 0.6, z1 - 0.6)
	mb.loft("rust", Kit.arc(0.0, CY + 0.006, 1.52, 0.34, 2.36, 2.0, 3), zc + 0.3, zc + 1.9)
	mb.loft("grime", Kit.arc(0.0, CY + 0.005, 1.52, 0.34, 0.5, 0.12, 3), zc - 2.6, zc - 1.4)
	for ez: float in [z0 + 0.02, z1 - 0.02]:
		mb.box("roof", Vector3(0, CY + 0.07, ez), Vector3(2.92, 0.14, 0.04))
		mb.box("roof", Vector3(0, CY + 0.2, ez), Vector3(2.3, 0.14, 0.04))
		mb.box("roof", Vector3(0, CY + 0.295, ez), Vector3(1.2, 0.07, 0.04))
	for sgn: float in [-1.0, 1.0]:
		mb.box("steel_dk", Vector3(sgn * 1.535, CY + 0.012, zc), Vector3(0.05, 0.05, zl))
		mb.cyl("steel_dk", Vector3(sgn * 1.55, CY - 0.5, z0 + 0.5), 0.022, 1.0, 1, 5)
	mb.box("ceiling", Vector3(0, CY + 0.02, zc), Vector3(2.9, 0.04, zl))
	var rr: float = z0 + 1.0
	while rr < z1 - 0.5:
		mb.loft("roof", Kit.arc(0.0, CY + 0.016, 1.525, 0.342, PI, 0.0, 12), rr - 0.035, rr + 0.035)
		mb.box("steel_dk", Vector3(0, CY - 0.002, rr), Vector3(2.86, 0.006, 0.03))
		rr += 2.15
	Kit.col(body, Vector3(0, CY + 0.12, zc), Vector3(3.0, 0.24, zl))

func _end_wall(mb: Kit, body: Node, z: float, out: float) -> void:
	for sgn: float in [-1.0, 1.0]:
		mb.box("hull_blk", Vector3(sgn * 0.975, 2.2, z + out * 0.025), Vector3(1.05, 2.7, 0.05))
		mb.box("panel", Vector3(sgn * 0.975, 2.375, z - out * 0.025), Vector3(1.05, 2.25, 0.05))
		Kit.col(body, Vector3(sgn * 0.975, 2.375, z), Vector3(1.05, 2.25, 0.1))
	mb.box("hull_blk", Vector3(0, 3.42, z + out * 0.025), Vector3(0.9, 0.2, 0.05))
	mb.box("panel", Vector3(0, 3.42, z - out * 0.025), Vector3(0.9, 0.2, 0.05))
	mb.box("steel", Vector3(0.47, 2.3, z - out * 0.06), Vector3(0.03, 2.05, 0.03))
	mb.box("steel", Vector3(-0.47, 2.3, z - out * 0.06), Vector3(0.03, 2.05, 0.03))
	Kit.col(body, Vector3(0, 3.42, z), Vector3(0.9, 0.2, 0.1))

func _gangway(mb: Kit, body: Node) -> void:
	mb.box("steel_dk", Vector3(0, FY - 0.03, -0.5), Vector3(1.04, 0.06, 1.0))
	Kit.col(body, Vector3(0, FY - 0.2, -0.5), Vector3(1.2, 0.4, 1.0))
	for sgn: float in [-1.0, 1.0]:
		for k in 5:
			var off: float = 0.05 if k % 2 == 0 else 0.0
			mb.box("rubber", Vector3(sgn * (0.55 + off), 2.33, -0.9 + float(k) * 0.2), Vector3(0.08, 2.2, 0.2))
		Kit.col(body, Vector3(sgn * 0.6, 2.33, -0.5), Vector3(0.1, 2.3, 1.0))
		mb.cyl("under", Vector3(sgn * 0.95, 0.98, -0.18), 0.13, 0.36, 2, 10)
		mb.cyl("under", Vector3(sgn * 0.95, 0.98, -0.82), 0.13, 0.36, 2, 10)
		mb.cyl("rubber", Vector3(sgn * 0.45, 0.72, -0.5), 0.03, 1.2, 2, 6)
	for k in 5:
		var off2: float = 0.05 if k % 2 == 0 else 0.0
		mb.box("rubber", Vector3(0, 3.45 + off2, -0.9 + float(k) * 0.2), Vector3(1.2, 0.08, 0.2))
	Kit.col(body, Vector3(0, 3.5, -0.5), Vector3(1.3, 0.12, 1.0))
	mb.box("under", Vector3(0, 0.9, -0.5), Vector3(0.24, 0.22, 1.3))
	for sgn2: float in [-1.0, 1.0]:
		mb.cyl("rubber", Vector3(sgn2 * 0.3, 0.78, -0.72), 0.022, 0.5, 2, 5)
		mb.cyl("rubber", Vector3(sgn2 * 0.3, 0.78, -0.28), 0.022, 0.5, 2, 5)
		mb.box("red" if sgn2 > 0.0 else "amber_paint", Vector3(sgn2 * 0.3, 0.78, -0.5), Vector3(0.06, 0.06, 0.08))
		mb.cyl("rubber", Vector3(sgn2 * 0.7, CY + 0.12, -0.5), 0.03, 1.1, 2, 5)
	mb.cyl("steel_dk", Vector3(0, 0.9, -0.5), 0.17, 0.34, 0, 10)
	for sgn3: float in [-1.0, 1.0]:
		mb.box("steel_dk", Vector3(sgn3 * 0.86, 1.5, -0.03), Vector3(0.12, 0.14, 0.06))
		mb.box("steel_dk", Vector3(sgn3 * 0.86, 1.5, -0.97), Vector3(0.12, 0.14, 0.06))
		for q in 6:
			var t0: float = float(q) / 6.0
			var t1: float = float(q + 1) / 6.0
			var ya: float = 1.5 - 0.3 * sin(t0 * PI)
			var yb: float = 1.5 - 0.3 * sin(t1 * PI)
			var seg := Vector3(0, yb - ya, (t1 - t0) * 0.9)
			mb.box("rubber", Vector3(sgn3 * 0.86, (ya + yb) * 0.5, -0.95 + (t0 + t1) * 0.45), Vector3(0.035, 0.035, seg.length() + 0.012), Basis(Vector3.RIGHT, -atan2(seg.y, seg.z)))
	mb.cyl("steel", Vector3(0.6, 0.9, -0.3), 0.012, 1.2, 0, 5)
	mb.box("red", Vector3(1.22, 0.86, -0.3), Vector3(0.04, 0.12, 0.04))

func _bogie(mb: Kit, parent: Node3D, zc: float, live: bool) -> void:
	mb.box("under", Vector3(0, 0.66, zc), Vector3(2.3, 0.2, 0.45))
	for sgn: float in [-1.0, 1.0]:
		mb.box("under", Vector3(sgn * 1.08, 0.62, zc), Vector3(0.14, 0.28, 3.0))
		mb.cyl("rubber", Vector3(sgn * 1.08, 0.86, zc), 0.13, 0.26, 1, 10)
		mb.cyl("amber_paint", Vector3(sgn * 1.2, 0.72, zc + 0.6), 0.035, 0.5, 1, 6)
		mb.cyl("amber_paint", Vector3(sgn * 1.2, 0.72, zc - 0.6), 0.035, 0.5, 1, 6)
		mb.box("steel_dk", Vector3(sgn * 1.1, 0.64, zc + 1.0), Vector3(0.2, 0.2, 0.26))
		mb.box("steel_dk", Vector3(sgn * 1.1, 0.64, zc - 1.0), Vector3(0.2, 0.2, 0.26))
		mb.cyl("steel", Vector3(sgn * 1.22, 0.78, zc + 0.3), 0.022, 0.44, 1, 6)
		mb.cyl("steel", Vector3(sgn * 1.22, 0.78, zc - 0.3), 0.022, 0.44, 1, 6)
		mb.box("red", Vector3(sgn * 0.98, 0.5, zc + 1.42), Vector3(0.1, 0.16, 0.14))
		mb.box("red", Vector3(sgn * 0.98, 0.5, zc - 1.42), Vector3(0.1, 0.16, 0.14))
		mb.cyl("steel_dk", Vector3(sgn * 0.9, 0.42, zc), 0.02, 2.9, 2, 5)
		for bz: float in [-1.0, 1.0]:
			for a2 in 4:
				mb.cyl("rail", Vector3(sgn * 1.205, 0.64 + cos(float(a2) * PI * 0.5 + 0.78) * 0.07, zc + bz + sin(float(a2) * PI * 0.5 + 0.78) * 0.07), 0.014, 0.012, 0, 5)
	mb.cyl("under", Vector3(0, 0.6, zc), 0.26, 0.9, 0, 10)
	mb.box("under", Vector3(0, 0.82, zc), Vector3(0.5, 0.14, 0.7))
	# running gear: coil springs, brake blocks and hangers, track brake, yaw dampers, sand pipes, anti-roll bar
	for sgn: float in [-1.0, 1.0]:
		for bz: float in [-1.0, 1.0]:
			mb.cyl("under", Vector3(sgn * 1.1, 0.84, zc + bz), 0.035, 0.2, 1, 6)
			for c in 5:
				mb.cyl("steel", Vector3(sgn * 1.1, 0.76 + float(c) * 0.038, zc + bz), 0.062, 0.014, 1, 8)
			mb.box("rust", Vector3(sgn * 0.75, 0.62, zc + bz * 1.5), Vector3(0.15, 0.24, 0.07))
			mb.box("rust", Vector3(sgn * 0.75, 0.62, zc + bz * 0.5), Vector3(0.15, 0.24, 0.07))
			mb.box("steel_dk", Vector3(sgn * 0.75, 0.84, zc + bz * 1.5), Vector3(0.05, 0.22, 0.04))
			mb.cyl("steel", Vector3(sgn * 0.75, 0.4, zc + bz * 1.57), 0.014, 0.36, 1, 5)
		mb.box("steel_dk", Vector3(sgn * 0.75, 0.3, zc), Vector3(0.11, 0.1, 0.84))
		mb.box("amber_paint", Vector3(sgn * 0.75, 0.3, zc + 0.44), Vector3(0.12, 0.11, 0.04))
		mb.box("amber_paint", Vector3(sgn * 0.75, 0.3, zc - 0.44), Vector3(0.12, 0.11, 0.04))
		mb.cyl("steel", Vector3(sgn * 1.25, 0.93, zc + 0.2), 0.03, 1.5, 2, 6)
		mb.cyl("under", Vector3(sgn * 1.25, 0.93, zc - 0.25), 0.045, 0.6, 2, 8)
		mb.box("steel_dk", Vector3(sgn * 1.2, 0.93, zc + 0.98), Vector3(0.12, 0.1, 0.06))
	mb.cyl("steel_dk", Vector3(0, 0.48, zc + 0.55), 0.025, 2.1, 0, 5)
	for dz: float in [-1.0, 1.0]:
		var w := MeshInstance3D.new()
		w.mesh = wheel_mesh
		w.position = Vector3(0, 0.66, zc + dz)
		w.rotation.x = randf() * TAU
		parent.add_child(w)
		if live:
			wheels.append(w)

func _lamp(parent: Node3D, pos: Vector3, energy: float, rng: float) -> void:
	var l: OmniLight3D = Kit.omni(parent, pos, Color(1.0, 0.82, 0.6), energy, rng)
	l.set_meta("e", energy)
	l.set_meta("main", not parent.has_meta("lit"))
	parent.set_meta("lit", true)
	lamps.append(l)

func apply_preset(preset: int) -> void:
	low = preset == 0
	for l: OmniLight3D in lamps:
		var is_main: bool = l.get_meta("main", false)
		l.visible = not low or is_main
		l.omni_range = 14.0 if (low and is_main) else float(l.get_meta("r", l.omni_range))

# ---------------- carriages ----------------
func make_carriage(type: String, live: bool, idx: int) -> Node3D:
	var kbc: Array = Kit.bevel_push(0.012, 0.04, 4.0)
	var n := Node3D.new()
	var body := StaticBody3D.new()
	n.add_child(body)
	var mb := Kit.new()
	var L: float = CL
	_floor_roof(mb, body, 0.0, L)
	_end_wall(mb, body, 0.05, -1.0)
	_end_wall(mb, body, L - 0.05, 1.0)
	_gangway(mb, body)
	var wins: Array = []
	if type in ["passenger", "medical", "kitchen", "greenhouse", "security", "workshop"]:
		for k in 6:
			if type == "workshop" and k % 2 == 1:
				continue
			wins.append([3.0 + float(k) * 2.15, 4.6 + float(k) * 2.15])
	for sgn: float in [-1.0, 1.0]:
		_wall_run(mb, body, sgn, 0.0, 0.6, [])
		_wall_run(mb, body, sgn, 1.9, L, wins)
		mb.box("hull_lt", Vector3(sgn * 1.475, 3.4, 1.25), Vector3(0.05, 0.2, 1.3))
		mb.box("panel", Vector3(sgn * 1.425, 3.4, 1.25), Vector3(0.05, 0.2, 1.3))
		mb.box("amber_paint", Vector3(sgn * 1.3, FY + 0.005, 1.25), Vector3(0.2, 0.01, 1.3))
		mb.cyl("steel", Vector3(sgn * 1.3, 2.3, 0.5), 0.02, 2.1, 1, 6)
		mb.cyl("steel", Vector3(sgn * 1.3, 2.3, 2.0), 0.02, 2.1, 1, 6)
		if type in ["generator", "storage", "water"]:
			for k in 4:
				mb.box("grille", Vector3(sgn * 1.505, 2.6, 4.2 + float(k) * 3.0), Vector3(0.02, 0.7, 1.8))
		Kit.text3d(n, Vector3(sgn * 1.51, 1.62, 5.2), TYPE_LABEL[type], 72, Color(0.85, 0.83, 0.78), sgn * PI * 0.5, 0.0035)
		mb.box("under", Vector3(sgn * 1.58, 0.92, 1.25), Vector3(0.22, 0.04, 1.2))
		mb.box("under", Vector3(sgn * 1.6, 0.55, 1.25), Vector3(0.2, 0.04, 1.1))
		mb.cyl("steel", Vector3(sgn * 1.535, 2.2, 0.5), 0.016, 1.3, 1, 6)
		mb.cyl("steel", Vector3(sgn * 1.535, 2.2, 2.0), 0.016, 1.3, 1, 6)
		var skirt := PackedVector2Array([Vector2(1.502, 0.97), Vector2(1.495, 0.82), Vector2(1.46, 0.69), Vector2(1.39, 0.6)])
		if sgn < 0.0:
			skirt = PackedVector2Array([Vector2(-1.39, 0.6), Vector2(-1.46, 0.69), Vector2(-1.495, 0.82), Vector2(-1.502, 0.97)])
		mb.loft("hull_blk", skirt, 4.7, 11.3)
		mb.box("steel_dk", Vector3(sgn * 1.39, 0.59, 8.0), Vector3(0.05, 0.03, 6.6))
		for hz: float in [5.6, 7.2, 8.8, 10.4]:
			mb.box("steel_dk", Vector3(sgn * 1.5, 0.8, hz), Vector3(0.012, 0.3, 0.9))
			mb.box("steel", Vector3(sgn * 1.508, 0.8, hz + 0.36), Vector3(0.012, 0.05, 0.06))
		mb.box("glass_dark", Vector3(sgn * 1.505, 3.27, 3.5), Vector3(0.012, 0.2, 1.5))
		Kit.text3d(n, Vector3(sgn * 1.515, 3.27, 3.5), "KALDWICK PORT", 30, Color(1.0, 0.7, 0.25), sgn * PI * 0.5, 0.0035)
		mb.box("lamp_red", Vector3(sgn * 1.1, 1.7, L + 0.005), Vector3(0.22, 0.12, 0.02))
		for k in 10:
			var il: float = 0.1 + 0.16 * float((k * 7 + idx * 3) % 5) / 4.0
			mb.cyl("ice", Vector3(sgn * 1.5, 3.5 - il * 0.5, 2.6 + float(k) * 1.37 + 0.3 * float(k % 3)), 0.003, il, 1, 4, 0.02)
	mb.cyl("steel_dk", Vector3(-0.72, CY + 0.3, 8.0), 0.04, L - 1.0, 2, 6)
	mb.cyl("steel_dk", Vector3(0.5, CY + 0.62, 7.6), 0.012, 0.7, 1, 4)
	mb.cyl("steel_dk", Vector3(0.5, CY + 0.52, 8.4), 0.012, 0.5, 1, 4)
	for sgn: float in [-1.0, 1.0]:
		pass
		if not live:
			_door_leaf(mb, Vector3(sgn * 1.47, 0, 1.25))
			Kit.col(body, Vector3(sgn * 1.45, 2.3, 1.25), Vector3(0.1, 2.1, 1.3))
	if live:
		for side: float in [1.0, -1.0]:
			var dn := Node3D.new()
			dn.position = Vector3(side * 1.47, 0, 1.25)
			n.add_child(dn)
			var dmb := Kit.new()
			_door_leaf(dmb, Vector3(0.0 if side > 0.0 else -0.002, 0, 0))
			dmb.commit(dn)
			var db := StaticBody3D.new()
			dn.add_child(db)
			var dc: CollisionShape3D = Kit.col(db, Vector3(-side * 0.02, 2.3, 0), Vector3(0.1, 2.1, 1.3))
			# fold-out boarding steps, used wherever the door opens away from a platform
			var run := 1.95
			var drop: float = 1.4 if side > 0.0 else 1.22
			var ang: float = atan2(drop, run)
			var slen: float = sqrt(run * run + drop * drop)
			var rb := Basis(Vector3.BACK, -ang)
			var sroot := Node3D.new()
			sroot.position = Vector3(side * 1.5, FY, 1.25)
			if side < 0.0:
				sroot.rotation.y = PI
			n.add_child(sroot)
			var sn := Node3D.new()
			sn.visible = false
			sroot.add_child(sn)
			var smb := Kit.new()
			for sz: float in [-0.56, 0.56]:
				smb.box("steel_dk", rb * Vector3(slen * 0.5, -0.07, 0) + Vector3(0, 0, sz), Vector3(slen, 0.12, 0.05), rb)
				smb.box("steel", rb * Vector3(slen * 0.5, 0, 0) + Vector3(0, 0.92, sz), Vector3(slen, 0.035, 0.035), rb)
				for f: float in [0.06, 0.5, 0.96]:
					smb.box("steel", Vector3(run * f, -drop * f + 0.46, sz), Vector3(0.035, 0.92, 0.035))
			for i in 6:
				var f2: float = (float(i) + 0.5) / 6.0
				smb.box("grille", Vector3(run * f2, -drop * f2 - 0.01, 0), Vector3(0.3, 0.035, 1.08))
				smb.box("amber_paint", Vector3(run * f2 + 0.14, -drop * f2 - 0.005, 0), Vector3(0.03, 0.04, 1.08))
			smb.commit(sn, false)
			var sbody := StaticBody3D.new()
			sn.add_child(sbody)
			var rc: CollisionShape3D = Kit.col(sbody, rb * Vector3(slen * 0.5 + 0.1, -0.05, 0), Vector3(slen + 0.3, 0.12, 1.16), rb)
			rc.disabled = true
			doors.append({"node": dn, "col": dc, "steps": sn, "ramp": rc, "t": 0.0, "car": n, "side": side})
			var a: Area3D = Kit.interact(n, Vector3(side * 1.55, 1.9, 1.25), Vector3(0.6, 2.9, 1.2), "@doors", main.act.bind("doors", null))
			a.set_meta("door", true)
	# vestibule partition
	for sgn: float in [-1.0, 1.0]:
		mb.sbox(body, "panel", Vector3(sgn * 0.925, 2.375, 2.5), Vector3(0.95, 2.25, 0.06))
	mb.sbox(body, "panel", Vector3(0, 3.42, 2.5), Vector3(0.9, 0.2, 0.06))
	mb.box("red", Vector3(-1.25, 1.75, 2.38), Vector3(0.12, 0.45, 0.12))
	mb.box("panel_dk", Vector3(-0.95, 2.5, 2.44), Vector3(0.5, 0.7, 0.05))
	mb.box("led_green", Vector3(-1.1, 2.72, 2.41), Vector3(0.04, 0.04, 0.02))
	mb.box("led_amber", Vector3(-1.0, 2.72, 2.41), Vector3(0.04, 0.04, 0.02))
	Kit.text3d(n, Vector3(0, 3.42, 2.46), "CAR %d  %s" % [idx + 1, TYPE_LABEL[type]], 40, Color(1.0, 0.75, 0.3), PI, 0.002)
	var slots: Dictionary = {"seats": [], "work": {}}
	if live:
		Kit.interact(n, Vector3(-0.95, 2.5, 2.3), Vector3(0.6, 0.8, 0.3), "@repair", main.act.bind("repair", idx))
		mb.box("light_warm", Vector3(-0.55, CY - 0.03, 9.2), Vector3(0.16, 0.03, 12.6))
		mb.box("light_warm", Vector3(0.55, CY - 0.03, 9.2), Vector3(0.16, 0.03, 12.6))
		mb.box("light_warm", Vector3(0, CY - 0.03, 1.25), Vector3(0.5, 0.03, 0.5))
		_lamp(n, Vector3(0, 3.2, 5.4), 1.5, 7.5)
		_lamp(n, Vector3(0, 3.2, 11.6), 1.5, 7.5)
		for k in 3:
			mb.box("grille", Vector3(0, CY - 0.025, 5.0 + float(k) * 3.6), Vector3(0.42, 0.02, 0.8))
		mb.box("lamp_red", Vector3(0.38, CY - 0.03, 2.9), Vector3(0.1, 0.03, 0.06))
		mb.box("glass_dark", Vector3(0, 3.42, 2.55), Vector3(0.88, 0.17, 0.03))
		_interior_common(mb, n, L)
		var dl: Label3D = Kit.text3d(n, Vector3(0, 3.415, 2.572), "", 34, Color(1.0, 0.68, 0.2), 0.0, 0.0022)
		displays.append(dl)
		slots = _interior(type, mb, body, n, idx)
		_hang(type, n)
		_ground_shadow(n, L)
		var vent: CPUParticles3D = Kit.particles(n, Vector3(-1.4, 0.78, 3.6), 5, 2.4, Color(0.9, 0.93, 1.0, 0.13), 0.45)
		vent.direction = Vector3(-0.55, 0.8, 0.0).normalized()
		vent.spread = 22.0
		vent.initial_velocity_min = 0.4
		vent.initial_velocity_max = 0.8
		vent.emitting = false
		vents.append(vent)
	n.set_meta("slots", slots)
	_bogie(mb, n, 2.6, live)
	_bogie(mb, n, L - 2.6, live)
	mb.box("under", Vector3(0.6, 0.72, 7.0), Vector3(1.1, 0.5, 2.2))
	mb.box("under", Vector3(-0.7, 0.7, 9.6), Vector3(0.9, 0.45, 1.6))
	mb.cyl("steel_dk", Vector3(-0.8, 0.72, 6.6), 0.2, 1.6, 2, 10)
	mb.cyl("steel_dk", Vector3(0.75, 0.72, 10.2), 0.16, 1.8, 2, 10)
	# below the skirts: air reservoirs with straps and drain cocks, a finned converter, pipe runs on brackets
	for sgn: float in [-1.0, 1.0]:
		var rz: float = 8.6 + sgn * 1.2
		mb.cyl("hull_lt" if sgn > 0.0 else "steel_dk", Vector3(sgn * 0.95, 0.5, rz), 0.15, 1.7, 2, 12)
		for sz2: float in [-0.55, 0.55]:
			mb.cyl("steel_dk", Vector3(sgn * 0.95, 0.5, rz + sz2), 0.158, 0.05, 2, 12)
		mb.cyl("red", Vector3(sgn * 0.95, 0.33, rz + 0.7), 0.025, 0.06, 1, 6)
		mb.cyl("steel", Vector3(sgn * 1.28, 0.42, 8.0), 0.028, 6.4, 2, 6)
		mb.cyl("rust", Vector3(sgn * 1.2, 0.36, 8.0), 0.02, 6.4, 2, 5)
		for k in 5:
			mb.box("steel_dk", Vector3(sgn * 1.25, 0.5, 5.4 + float(k) * 1.3), Vector3(0.14, 0.2, 0.04))
	mb.box("under", Vector3(0.0, 0.47, 5.9), Vector3(1.5, 0.4, 1.3))
	for k in 9:
		mb.box("steel_dk", Vector3(0.0, 0.47, 5.34 + float(k) * 0.14), Vector3(1.56, 0.34, 0.03))
	mb.box("amber_paint", Vector3(0.76, 0.56, 5.9), Vector3(0.01, 0.1, 0.16))
	_car_identity(mb, n, type, idx, L, live)
	mb.commit(n)
	Kit.bevel_pop(kbc)
	return n

## Fittings shared by every carriage: services along the ceiling, door gear, emergency equipment and signage.
func _interior_common(mb: Kit, n: Node3D, L: float) -> void:
	var F: float = FY
	for sgn: float in [-1.0, 1.0]:
		mb.box("emerg", Vector3(sgn * 1.385, F + 0.045, 9.2), Vector3(0.016, 0.03, 12.6))
		mb.box("steel", Vector3(sgn * 1.393, F + 0.13, 9.2), Vector3(0.01, 0.14, 12.7))
		mb.box("panel_dk", Vector3(sgn * 1.32, 3.37, 1.25), Vector3(0.22, 0.17, 1.42))
		mb.box("steel", Vector3(sgn * 1.36, 3.275, 1.25), Vector3(0.03, 0.02, 1.36))
		mb.box("red", Vector3(sgn * 1.395, 2.95, 2.03), Vector3(0.03, 0.13, 0.07))
		mb.box("white_paint", Vector3(sgn * 1.397, 3.1, 2.03), Vector3(0.012, 0.1, 0.16))
		mb.box("led_green", Vector3(sgn * 1.395, 2.35, 0.47), Vector3(0.03, 0.06, 0.06))
		mb.box("steel_dk", Vector3(sgn * 1.395, 2.35, 0.47), Vector3(0.02, 0.12, 0.1))
	mb.cyl("steel", Vector3(1.32, CY - 0.075, 9.2), 0.03, 12.9, 2, 8)
	for k in 3:
		mb.cyl("rubber", Vector3(-1.34 + float(k) * 0.035, CY - 0.06, 9.2), 0.013, 12.9, 2, 5)
	for k in 7:
		mb.box("steel_dk", Vector3(1.32, CY - 0.05, 3.2 + float(k) * 2.0), Vector3(0.09, 0.07, 0.03))
		mb.box("steel_dk", Vector3(-1.305, CY - 0.045, 3.2 + float(k) * 2.0), Vector3(0.13, 0.05, 0.03))
	mb.box("steel_dk", Vector3(0, F + 0.004, 1.25), Vector3(0.62, 0.008, 0.62))
	mb.box("steel", Vector3(0.2, F + 0.01, 1.25), Vector3(0.08, 0.008, 0.03))
	mb.box("exit", Vector3(0, 3.42, L - 0.085), Vector3(0.5, 0.15, 0.02))
	Kit.text3d(n, Vector3(0, 3.42, L - 0.098), "EXIT", 44, Color(0.04, 0.12, 0.06), PI, 0.0022)
	for hz: float in [5.15, 11.6]:
		mb.box("red", Vector3(-1.39, 3.2, hz), Vector3(0.03, 0.16, 0.24))
		mb.box("steel", Vector3(-1.37, 3.2, hz), Vector3(0.016, 0.03, 0.16))
	mb.box("panel_dk", Vector3(0.95, 2.6, 2.455), Vector3(0.5, 0.62, 0.04))
	for r in 3:
		for c in 6:
			mb.box("hull_blk" if (r + c) % 4 != 0 else "red", Vector3(0.76 + float(c) * 0.075, 2.42 + float(r) * 0.16, 2.43), Vector3(0.03, 0.07, 0.02))
	mb.box("amber_paint", Vector3(0.95, 2.95, 2.432), Vector3(0.3, 0.06, 0.006))
	# far end wall: notice board of the missing, extinguisher and first-aid box
	mb.box("wood", Vector3(0.96, 2.55, L - 0.112), Vector3(0.74, 0.6, 0.02))
	mb.box("steel_dk", Vector3(0.96, 2.86, L - 0.118), Vector3(0.78, 0.03, 0.03))
	for i in 7:
		mb.box("white_paint", Vector3(0.68 + float(i % 4) * 0.18, 2.62 - float(i / 4) * 0.24, L - 0.126), Vector3(0.13, 0.17, 0.004), Basis(Vector3.BACK, 0.12 * float(i % 3) - 0.1))
		mb.box("seat_dk", Vector3(0.68 + float(i % 4) * 0.18, 2.65 - float(i / 4) * 0.24, L - 0.13), Vector3(0.07, 0.07, 0.004), Basis(Vector3.BACK, 0.12 * float(i % 3) - 0.1))
	Kit.text3d(n, Vector3(0.96, 2.8, L - 0.132), "HAVE YOU SEEN THEM?", 20, Color(0.5, 0.1, 0.08), PI, 0.0024)
	mb.cyl("red", Vector3(-0.72, 1.72, L - 0.2), 0.07, 0.42, 1, 10)
	mb.cyl("hull_blk", Vector3(-0.72, 1.97, L - 0.2), 0.03, 0.08, 1, 6)
	mb.box("steel_dk", Vector3(-0.72, 1.72, L - 0.115), Vector3(0.2, 0.05, 0.03))
	mb.box("leaf", Vector3(-1.08, 2.4, L - 0.13), Vector3(0.3, 0.24, 0.07))
	mb.box("white_paint", Vector3(-1.08, 2.4, L - 0.168), Vector3(0.14, 0.04, 0.004))
	mb.box("white_paint", Vector3(-1.08, 2.4, L - 0.168), Vector3(0.04, 0.14, 0.004))

## One crop plant standing in the planter soil: a leaf rosette, a staked vine with fruit,
## a tray seedling or a tall two-tier bush, chosen and turned by k so no two neighbours match.
func _plant(mb: Kit, pos: Vector3, hh: float, k: int) -> void:
	var kind: int = k % 4
	var mat: String = "leaf" if k % 3 != 0 else "leaf_lt"
	var a0: float = float(k) * 1.7
	if kind == 1:
		mb.cyl("wood", pos + Vector3(0, 0.36, 0), 0.008, 0.72, 1, 4)
		for i in 6:
			var b := Basis(Vector3.UP, a0 + float(i) * 2.3)
			mb.box(mat, pos + Vector3(0, 0.1 + float(i) * 0.1, 0) + b * Vector3(0, 0.02, 0.06), Vector3(0.07, 0.008, 0.13), b * Basis(Vector3.RIGHT, -0.5))
		for i in 3:
			mb.cyl("red", pos + Vector3(cos(a0 + float(i) * 2.0) * 0.05, 0.2 + float(i) * 0.14, sin(a0 + float(i) * 2.0) * 0.05), 0.026, 0.045, 1, 6)
		mb.box("white_paint", pos + Vector3(0.05, 0.05, 0.05), Vector3(0.03, 0.08, 0.004))
		return
	var n: int = 6 if kind != 2 else 4
	var h: float = hh * (0.45 if kind == 2 else (1.3 if kind == 3 else 1.0))
	var lean: float = 0.55 if kind != 3 else 0.3
	for i in n:
		var b2 := Basis(Vector3.UP, a0 + float(i) * TAU / float(n))
		var tilt := Basis(Vector3.RIGHT, lean)
		mb.box(mat, pos + b2 * (tilt * Vector3(0, h * 0.5, 0)), Vector3(0.075, h, 0.008), b2 * tilt)
	if kind == 3:
		for i in 4:
			var b3 := Basis(Vector3.UP, a0 + 0.8 + float(i) * TAU / 4.0)
			var tilt2 := Basis(Vector3.RIGHT, 0.8)
			mb.box(mat, pos + Vector3(0, h * 0.5, 0) + b3 * (tilt2 * Vector3(0, h * 0.3, 0)), Vector3(0.06, h * 0.6, 0.008), b3 * tilt2)

const BAND := {"passenger": "stripe", "storage": "steel_dk", "medical": "white_paint", "kitchen": "amber_paint", "workshop": "corr_blue", "generator": "red", "security": "hull_blk", "greenhouse": "leaf", "water": "corr_blue"}

func _ac_unit(mb: Kit, z: float) -> void:
	mb.box("roof", Vector3(0, CY + 0.39, z), Vector3(1.5, 0.2, 2.2))
	mb.box("hull_lt", Vector3(0, CY + 0.39, z), Vector3(1.53, 0.05, 2.23))
	for fz: float in [-0.52, 0.52]:
		mb.cyl("grille", Vector3(0, CY + 0.495, z + fz), 0.42, 0.012, 1, 14)
		mb.cyl("steel_dk", Vector3(0, CY + 0.507, z + fz), 0.09, 0.02, 1, 8)
		for i in 3:
			mb.box("steel_dk", Vector3(0, CY + 0.504, z + fz), Vector3(0.82, 0.008, 0.03), Basis(Vector3.UP, float(i) * PI / 3.0))
	for sgn: float in [-1.0, 1.0]:
		mb.box("grille", Vector3(sgn * 0.755, CY + 0.39, z), Vector3(0.012, 0.13, 1.9))
		mb.cyl("rubber", Vector3(sgn * 0.5, CY + 0.31, z + 1.3), 0.025, 0.5, 2, 5)

func _stack(n: Node3D, pos: Vector3, kind: String, psize: float) -> void:
	var p: CPUParticles3D = Kit.particles(n, pos, 7, 2.6, Color(0.2, 0.2, 0.22, 0.32) if kind == "gen" else Color(0.75, 0.75, 0.78, 0.2), psize)
	p.emitting = false
	stacks.append([p, kind])

## What makes each carriage recognisable from outside: livery band, fleet number and roof equipment.
func _car_identity(mb: Kit, n: Node3D, type: String, idx: int, L: float, live: bool) -> void:
	var band: String = BAND.get(type, "stripe")
	var dark: bool = band == "white_paint" or band == "amber_paint" or band == "stripe"
	for sgn: float in [-1.0, 1.0]:
		mb.box(band, Vector3(sgn * 1.5036, 1.3, (2.0 + L) * 0.5), Vector3(0.008, 0.15, L - 2.2))
		Kit.text3d(n, Vector3(sgn * 1.513, 1.3, L - 2.4), "NL  4%d%d7" % [idx + 1, type.length()], 40, Color(0.08, 0.08, 0.1) if dark else Color(0.9, 0.88, 0.8), sgn * PI * 0.5, 0.0032)
		mb.box("hull_blk", Vector3(sgn * 1.5036, 1.08, L - 1.1), Vector3(0.006, 0.2, 0.8))
		for i in 3:
			mb.box("white_paint", Vector3(sgn * 1.508, 1.13 - float(i) * 0.05, L - 1.1), Vector3(0.004, 0.02, 0.6 - float(i) * 0.12))
	match type:
		"passenger":
			_ac_unit(mb, 4.5)
			_ac_unit(mb, 11.5)
			mb.box("steel_dk", Vector3(0.0, CY + 0.52, 8.0), Vector3(0.03, 0.36, 0.3))
		"medical":
			_ac_unit(mb, 4.5)
			mb.box("white_paint", Vector3(0, CY + 0.35, 10.6), Vector3(1.5, 0.03, 1.5))
			mb.box("red", Vector3(0, CY + 0.37, 10.6), Vector3(1.1, 0.02, 0.32))
			mb.box("red", Vector3(0, CY + 0.37, 10.6), Vector3(0.32, 0.02, 1.1))
			for sgn: float in [-1.0, 1.0]:
				mb.box("white_paint", Vector3(sgn * 1.5046, 1.66, 14.9), Vector3(0.006, 0.56, 0.56))
				mb.box("red", Vector3(sgn * 1.508, 1.66, 14.9), Vector3(0.006, 0.4, 0.12))
				mb.box("red", Vector3(sgn * 1.508, 1.66, 14.9), Vector3(0.006, 0.12, 0.4))
		"kitchen":
			_ac_unit(mb, 11.5)
			for cz: float in [4.6, 5.5]:
				mb.cyl("steel_dk", Vector3(-0.7, CY + 0.6, cz), 0.11, 0.75, 1, 10)
				mb.cyl("steel_dk", Vector3(-0.7, CY + 1.0, cz), 0.19, 0.06, 1, 10, 0.1)
				mb.cyl("rust", Vector3(-0.7, CY + 0.3, cz), 0.16, 0.06, 1, 10)
			mb.box("grille", Vector3(0.5, CY + 0.36, 6.4), Vector3(0.7, 0.12, 1.2))
			if live:
				_stack(n, Vector3(-0.7, CY + 1.15, 4.6), "galley", 0.5)
		"storage":
			for hz: float in [4.2, 8.2, 12.2]:
				mb.box("hull_lt", Vector3(0, CY + 0.37, hz), Vector3(0.95, 0.07, 0.95))
				mb.box("steel", Vector3(0, CY + 0.42, hz), Vector3(0.3, 0.03, 0.04))
				mb.box("steel_dk", Vector3(0.44, CY + 0.39, hz), Vector3(0.05, 0.05, 0.3))
			for sgn: float in [-1.0, 1.0]:
				for k in 12:
					mb.box("hull", Vector3(sgn * 1.512, 2.2, 2.7 + float(k) * 1.1), Vector3(0.03, 2.3, 0.07))
				mb.box("steel_dk", Vector3(sgn * 1.515, 2.2, 8.4), Vector3(0.04, 0.06, 12.4))
		"workshop":
			_ac_unit(mb, 4.5)
			mb.cyl("red", Vector3(-0.45, CY + 0.46, 11.0), 0.12, 1.4, 2, 10)
			mb.cyl("amber_paint", Vector3(-0.72, CY + 0.42, 11.0), 0.12, 1.4, 2, 10)
			mb.box("steel_dk", Vector3(-0.58, CY + 0.36, 11.0), Vector3(0.7, 0.04, 0.1))
			mb.cyl("amber_paint", Vector3(0.75, CY + 0.9, 11.6), 0.07, 1.2, 1, 8)
			mb.box("amber_paint", Vector3(0.0, CY + 1.46, 11.6), Vector3(1.7, 0.1, 0.1))
			mb.box("amber_paint", Vector3(0.38, CY + 1.2, 11.6), Vector3(0.9, 0.06, 0.06), Basis(Vector3.BACK, 0.6))
			mb.cyl("rubber", Vector3(-0.7, CY + 1.15, 11.6), 0.012, 0.6, 1, 4)
			mb.box("steel_dk", Vector3(-0.7, CY + 0.82, 11.6), Vector3(0.08, 0.1, 0.05))
		"generator":
			for fz: float in [7.6, 10.4]:
				mb.cyl("under", Vector3(0, CY + 0.36, fz), 0.64, 0.14, 1, 18)
				mb.cyl("grille", Vector3(0, CY + 0.435, fz), 0.56, 0.012, 1, 18)
				mb.cyl("steel_dk", Vector3(0, CY + 0.45, fz), 0.1, 0.03, 1, 8)
			for ez: float in [4.3, 5.2]:
				mb.cyl("rust", Vector3(-0.6, CY + 0.66, ez), 0.14, 0.8, 1, 10)
				mb.cyl("under", Vector3(-0.6, CY + 1.08, ez), 0.17, 0.05, 1, 10)
			mb.cyl("rubber", Vector3(0.9, CY + 0.3, 8.0), 0.05, 12.0, 2, 6)
			mb.box("amber_paint", Vector3(0, CY + 0.36, 13.2), Vector3(1.2, 0.1, 1.4))
			if live:
				_stack(n, Vector3(-0.6, CY + 1.2, 4.3), "gen", 0.9)
		"security":
			for pz: float in [4.6, 11.4]:
				mb.box("steel_dk", Vector3(0, CY + 0.37, pz), Vector3(2.0, 0.04, 3.0))
				for i in 4:
					mb.cyl("steel", Vector3(-0.9 + float(i % 2) * 1.8, CY + 0.395, pz - 1.3 + float(i / 2) * 2.6), 0.03, 0.012, 1, 6)
			for i in 6:
				mb.box("sack", Vector3(cos(float(i) * TAU / 6.0) * 0.62, CY + 0.47, 8.0 + sin(float(i) * TAU / 6.0) * 0.62), Vector3(0.5, 0.2, 0.3), Basis(Vector3.UP, -float(i) * TAU / 6.0 + PI * 0.5))
			mb.cyl("steel_dk", Vector3(0, CY + 0.62, 8.0), 0.05, 0.5, 1, 6)
			mb.cyl("hull_blk", Vector3(0, CY + 0.95, 8.0), 0.17, 0.3, 0, 12)
			mb.cyl("lamp_white", Vector3(0.156, CY + 0.95, 8.0), 0.14, 0.01, 0, 12)
			mb.cyl("steel_dk", Vector3(-0.9, CY + 1.1, 13.6), 0.012, 1.7, 1, 4)
		"greenhouse":
			for k in 5:
				var gz: float = 3.6 + float(k) * 2.5
				for sgn: float in [-1.0, 1.0]:
					var rb := Basis(Vector3.BACK, -sgn * 0.3)
					mb.box("glass", Vector3(sgn * 0.72, CY + 0.31, gz), Vector3(0.95, 0.012, 2.1), rb)
					mb.box("white_paint", Vector3(sgn * 0.72, CY + 0.315, gz - 1.08), Vector3(1.0, 0.03, 0.05), rb)
					mb.box("white_paint", Vector3(sgn * 0.72, CY + 0.315, gz + 1.08), Vector3(1.0, 0.03, 0.05), rb)
			mb.box("white_paint", Vector3(0, CY + 0.365, 8.6), Vector3(0.1, 0.05, 12.6))
			mb.box("grow", Vector3(0, CY + 0.34, 8.6), Vector3(0.5, 0.012, 12.2))
		"water":
			for tz: float in [4.6, 7.8, 11.0]:
				mb.cyl("hull_lt", Vector3(0, CY + 0.38, tz), 0.6, 0.14, 1, 16, 0.5)
				mb.cyl("steel_dk", Vector3(0, CY + 0.5, tz), 0.2, 0.12, 1, 10)
				mb.box("steel", Vector3(0.0, CY + 0.57, tz), Vector3(0.34, 0.02, 0.04))
			mb.cyl("corr_blue", Vector3(0.5, CY + 0.36, 7.8), 0.05, 7.0, 2, 6)
			for sgn: float in [-1.0, 1.0]:
				mb.cyl("corr_blue", Vector3(sgn * 1.545, 2.35, 13.4), 0.045, 2.2, 1, 6)
				mb.box("steel_dk", Vector3(sgn * 1.53, 1.6, 13.4), Vector3(0.05, 0.08, 0.14))
				mb.box("steel_dk", Vector3(sgn * 1.53, 3.0, 13.4), Vector3(0.05, 0.08, 0.14))
				mb.cyl("red", Vector3(sgn * 1.58, 1.5, 13.4), 0.06, 0.04, 0, 8)

## A soft dark pool on the track bed under each vehicle, so the train sits on the rails at night too.
func _ground_shadow(n: Node3D, length: float) -> void:
	if shadow_mat == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
		g.colors = PackedColorArray([Color(0, 0, 0, 0.62), Color(0, 0, 0, 0.55), Color(0, 0, 0, 0)])
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_SQUARE
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 64
		gt.height = 64
		shadow_mat = StandardMaterial3D.new()
		shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shadow_mat.albedo_texture = gt
	var sh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(4.8, length + 1.6)
	sh.mesh = pm
	sh.material_override = shadow_mat
	sh.position = Vector3(0, 0.215, length * 0.5)
	sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(sh)

const HANG := {
	"passenger": [["coat", Vector3(1.12, 3.0, 7.5)], ["coat", Vector3(-1.12, 3.0, 12.0)], ["bag", Vector3(1.12, 3.0, 9.7)], ["lamp", Vector3(0.0, 3.48, 15.0)]],
	"storage": [["lamp", Vector3(0.0, 3.48, 5.5)], ["lamp", Vector3(0.0, 3.48, 11.5)], ["tag", Vector3(0.74, 3.3, 7.4)], ["bag", Vector3(-0.74, 3.3, 9.6)]],
	"medical": [["iv", Vector3(-0.42, 3.48, 3.55)], ["iv", Vector3(-0.42, 3.48, 7.15)], ["iv", Vector3(-0.42, 3.48, 10.75)], ["tag", Vector3(0.8, 3.48, 12.4)]],
	"kitchen": [["pan", Vector3(-0.8, 3.06, 4.5)], ["pan", Vector3(-0.8, 3.06, 4.85)], ["pan", Vector3(-0.8, 3.06, 5.2)], ["pan", Vector3(-0.8, 3.06, 5.55)], ["lamp", Vector3(0.95, 3.48, 5.0)], ["lamp", Vector3(0.95, 3.48, 9.4)]],
	"workshop": [["lamp", Vector3(-0.95, 3.48, 6.2)], ["lamp", Vector3(-0.95, 3.48, 8.2)], ["cable", Vector3(0.9, 3.48, 7.6)], ["cable", Vector3(0.7, 3.48, 11.2)], ["tag", Vector3(1.0, 3.48, 9.4)]],
	"generator": [["tag", Vector3(0.3, 3.48, 6.5)], ["tag", Vector3(0.3, 3.48, 9.5)], ["lamp", Vector3(0.9, 3.48, 8.0)], ["cable", Vector3(0.8, 3.48, 12.0)]],
	"security": [["lamp", Vector3(0.0, 3.48, 8.2)], ["tag", Vector3(-0.85, 3.3, 4.0)], ["bag", Vector3(0.9, 3.48, 11.0)]],
	"greenhouse": [["cable", Vector3(0.0, 3.48, 5.0)], ["cable", Vector3(0.0, 3.48, 9.0)], ["cable", Vector3(0.0, 3.48, 13.0)], ["tag", Vector3(0.5, 3.48, 3.4)]],
	"water": [["cable", Vector3(0.9, 3.48, 6.6)], ["tag", Vector3(-0.1, 3.48, 4.6)], ["lamp", Vector3(0.4, 3.48, 11.0)]],
}

## Things that hang and swing with the motion of the train.
func _hang(type: String, n: Node3D) -> void:
	var items: Array = HANG.get(type, [])
	for it: Array in items:
		var piv := Node3D.new()
		var hp: Vector3 = it[1]
		piv.position = hp
		n.add_child(piv)
		var mb := Kit.new()
		match str(it[0]):
			"lamp":
				mb.cyl("rubber", Vector3(0, -0.13, 0), 0.008, 0.26, 1, 4)
				mb.cyl("steel_dk", Vector3(0, -0.28, 0), 0.05, 0.05, 1, 8, 0.02)
				mb.cyl("lamp_warm", Vector3(0, -0.345, 0), 0.035, 0.08, 1, 8)
				for i in 4:
					mb.box("steel_dk", Vector3(cos(float(i) * PI * 0.5) * 0.045, -0.35, sin(float(i) * PI * 0.5) * 0.045), Vector3(0.006, 0.1, 0.006))
			"iv":
				mb.cyl("steel", Vector3(0, -0.1, 0), 0.006, 0.2, 1, 4)
				mb.box("glass", Vector3(0, -0.3, 0), Vector3(0.11, 0.2, 0.045))
				mb.box("white_paint", Vector3(0, -0.3, 0.024), Vector3(0.07, 0.08, 0.002))
				mb.cyl("rubber", Vector3(0, -0.55, 0), 0.004, 0.3, 1, 4)
			"pan":
				mb.cyl("steel", Vector3(0, -0.06, 0), 0.006, 0.12, 1, 4)
				mb.box("plastic", Vector3(0, -0.19, 0), Vector3(0.03, 0.16, 0.02))
				mb.cyl("steel_dk", Vector3(0, -0.36, 0), 0.1, 0.03, 0, 12)
			"cable":
				mb.cyl("rubber", Vector3(-0.1, -0.2, 0), 0.012, 0.4, 1, 5)
				mb.cyl("rubber", Vector3(0.1, -0.2, 0), 0.012, 0.4, 1, 5)
				mb.cyl("rubber", Vector3(0, -0.4, 0), 0.012, 0.2, 0, 5)
				mb.box("amber_paint", Vector3(0, -0.41, 0), Vector3(0.05, 0.04, 0.04))
			"coat":
				mb.box("steel", Vector3(0, -0.02, 0), Vector3(0.02, 0.05, 0.3))
				mb.box("canvas", Vector3(0, -0.32, 0), Vector3(0.09, 0.56, 0.36))
				mb.box("canvas", Vector3(0, -0.22, 0.2), Vector3(0.07, 0.36, 0.08))
				mb.box("canvas", Vector3(0, -0.22, -0.2), Vector3(0.07, 0.36, 0.08))
			"bag":
				mb.cyl("rubber", Vector3(0, -0.09, 0), 0.008, 0.18, 1, 4)
				mb.box("sack", Vector3(0, -0.32, 0), Vector3(0.16, 0.3, 0.24))
				mb.box("seat_dk", Vector3(0, -0.2, 0), Vector3(0.17, 0.03, 0.25))
			_:
				mb.cyl("steel", Vector3(0, -0.08, 0), 0.004, 0.16, 1, 4)
				mb.box("amber_paint", Vector3(0, -0.22, 0), Vector3(0.1, 0.14, 0.004))
				mb.box("hull_blk", Vector3(0, -0.2, 0.003), Vector3(0.07, 0.03, 0.002))
		mb.commit(piv, false)
		danglers.append([piv, randf() * TAU])

func _door_leaf(mb: Kit, o: Vector3) -> void:
	mb.box("hull", o + Vector3(0, 1.76, 0), Vector3(0.06, 1.0, 1.3))
	mb.box("hull_blk", o + Vector3(0, 3.19, 0), Vector3(0.06, 0.22, 1.3))
	mb.box("hull_blk", o + Vector3(0, 2.7, -0.6), Vector3(0.06, 0.9, 0.1))
	mb.box("hull_blk", o + Vector3(0, 2.7, 0.6), Vector3(0.06, 0.9, 0.1))
	mb.box("glass", o + Vector3(0, 2.67, 0), Vector3(0.02, 0.84, 1.1))
	mb.box("stripe", o + Vector3(0.033 * signf(o.x + 0.001), 2.2, 0), Vector3(0.01, 0.08, 1.3))
	mb.box("door_led", o + Vector3(0, 2.1, 0.5), Vector3(0.08, 0.06, 0.06))
	mb.box("door_led", o + Vector3(0, 3.19, 0), Vector3(0.07, 0.05, 0.5))
	mb.box("steel", o + Vector3(-0.04 * signf(o.x + 0.001), 2.25, -0.45), Vector3(0.03, 0.5, 0.03))
	mb.box("rubber", o + Vector3(0, 2.3, 0.652), Vector3(0.07, 2.0, 0.012))
	mb.box("rubber", o + Vector3(0, 2.3, -0.652), Vector3(0.07, 2.0, 0.012))
	mb.box("grime", o + Vector3(0.032 * signf(o.x + 0.001), 1.45, 0), Vector3(0.004, 0.3, 1.2))

static var seat_prof := PackedVector2Array()

## Side profile of a seat (depth forward of the back plane, height above the floor), running
## clockwise from the rear foot: up the back, over the headrest, down the lumbar curve, along the cushion.
static func _seat_profile() -> PackedVector2Array:
	if seat_prof.is_empty():
		seat_prof = PackedVector2Array([Vector2(0.0, 0.36), Vector2(-0.015, 0.75), Vector2(-0.035, 1.15), Vector2(-0.03, 1.36), Vector2(-0.005, 1.425), Vector2(0.04, 1.44), Vector2(0.085, 1.415), Vector2(0.105, 1.36), Vector2(0.1, 1.26), Vector2(0.082, 1.17), Vector2(0.095, 0.98), Vector2(0.115, 0.74), Vector2(0.12, 0.6), Vector2(0.135, 0.515), Vector2(0.2, 0.485), Vector2(0.36, 0.49), Vector2(0.5, 0.508), Vector2(0.565, 0.495), Vector2(0.595, 0.455), Vector2(0.6, 0.4), Vector2(0.585, 0.36)])
	return seat_prof

## Contoured upholstered seat: a lofted side profile with raised bolsters, stitched seams and a headrest cover.
func _seat_shell(mb: Kit, pos: Vector3, face: float, hw: float, m_main: String, m_side: String, cover: bool) -> void:
	var prof: PackedVector2Array = _seat_profile()
	var keep: Transform3D = mb.xf
	mb.xf = keep * Transform3D(Basis(Vector3(0, 0, face), Vector3.UP, Vector3(-face, 0, 0)), pos)
	var closed: PackedVector2Array = prof.duplicate()
	closed.append(prof[0])
	var bw: float = minf(0.12, hw * 0.3)
	mb.loft(m_main, closed, -hw + bw, hw - bw)
	var fat: PackedVector2Array = Kit.offset(closed, 0.014)
	var fat_poly: PackedVector2Array = fat.slice(0, fat.size() - 1)
	var seam: PackedVector2Array = Kit.offset(prof.slice(8, 18), 0.003)
	for sgn: float in [-1.0, 1.0]:
		var za: float = minf(sgn * hw, sgn * (hw - bw))
		var zb: float = maxf(sgn * hw, sgn * (hw - bw))
		mb.loft(m_side, fat, za, zb)
		mb.caps(m_side, fat_poly, za, zb)
		var zs: float = sgn * (hw - bw) * 0.42
		mb.loft("stitch", seam, zs - 0.003, zs + 0.003)
	if cover:
		mb.loft("mattress", Kit.offset(prof.slice(3, 9), 0.004), -hw + bw + 0.03, hw - bw - 0.03)
	mb.xf = keep

func _seat_block(mb: Kit, x: float, z: float, face: float) -> void:
	# face = +1 seat faces +z, -1 faces -z
	mb.box("plastic", Vector3(x, FY + 0.17, z + face * 0.3), Vector3(0.8, 0.34, 0.3))
	mb.box("steel_dk", Vector3(x, FY + 0.02, z + face * 0.3), Vector3(0.88, 0.04, 0.07))
	mb.box("steel", Vector3(x - signf(x) * 0.45, FY + 0.2, z + face * 0.3), Vector3(0.03, 0.36, 0.3))
	mb.box("steel", Vector3(x, FY + 0.352, z + face * 0.56), Vector3(0.9, 0.025, 0.025))
	_seat_shell(mb, Vector3(x, FY, z), face, 0.47, "seat", "seat_dk", true)
	# fittings for the passenger behind: folding tray with latch, net pocket, kick plate
	mb.box("plastic", Vector3(x, FY + 1.0, z - face * 0.045), Vector3(0.5, 0.27, 0.02), Basis(Vector3.RIGHT, -face * 0.05))
	mb.box("steel", Vector3(x, FY + 1.15, z - face * 0.058), Vector3(0.05, 0.02, 0.012))
	mb.box("seat_dk", Vector3(x, FY + 0.7, z - face * 0.032), Vector3(0.6, 0.2, 0.02))
	mb.box("steel_dk", Vector3(x, FY + 0.805, z - face * 0.034), Vector3(0.62, 0.012, 0.024))
	mb.box("plastic", Vector3(x, FY + 0.45, z - face * 0.012), Vector3(0.9, 0.2, 0.02))
	var ax: float = x - signf(x) * 0.47
	mb.box("plastic", Vector3(ax, FY + 0.64, z + face * 0.3), Vector3(0.05, 0.06, 0.42))
	mb.box("steel", Vector3(ax, FY + 0.5, z + face * 0.48), Vector3(0.03, 0.26, 0.03))
	mb.cyl("steel", Vector3(ax, FY + 1.44, z + face * 0.03), 0.014, 0.2, 2, 6)

func _interior(type: String, mb: Kit, body: Node, n: Node3D, idx: int) -> Dictionary:
	var seats: Array = []
	var work: Dictionary = {}
	var straps: Array = []
	var F: float = FY
	match type:
		"passenger":
			for sgn: float in [-1.0, 1.0]:
				var bays: int = 5 if sgn < 0.0 else 6
				for k in bays:
					var za: float = 3.0 + float(k) * 2.15
					_seat_block(mb, sgn * 0.93, za, 1.0)
					_seat_block(mb, sgn * 0.93, za + 1.6, -1.0)
					mb.box("wood", Vector3(sgn * 1.05, F + 0.74, za + 0.8), Vector3(0.7, 0.035, 0.46))
					mb.cyl("steel", Vector3(sgn * 0.85, F + 0.37, za + 0.8), 0.03, 0.72, 1, 6)
					seats.append([Vector3(sgn * 0.7, F, za + 0.26), PI])
					seats.append([Vector3(sgn * 0.7, F, za + 1.34), 0.0])
				var zl: float = float(bays) * 2.15
				Kit.col(body, Vector3(sgn * 0.93, F + 0.55, 2.9 + zl * 0.5), Vector3(0.94, 1.1, zl))
				mb.box("steel", Vector3(sgn * 1.2, 3.02, 9.2), Vector3(0.38, 0.02, 12.6))
				mb.cyl("steel", Vector3(sgn * 1.02, 3.04, 9.2), 0.012, 12.6, 2, 5)
			# luggage and supplies in the free bay
			mb.box("sack", Vector3(-1.0, F + 0.2, 14.2), Vector3(0.6, 0.4, 0.9))
			mb.box("wood", Vector3(-1.05, F + 0.25, 15.2), Vector3(0.6, 0.5, 0.6))
			mb.box("seat_dk", Vector3(-1.05, F + 0.62, 15.2), Vector3(0.5, 0.24, 0.4))
			mb.box("red", Vector3(-1.15, F + 0.55, 14.2), Vector3(0.3, 0.3, 0.5))
			Kit.col(body, Vector3(-1.05, F + 0.4, 14.8), Vector3(0.7, 0.8, 1.9))
			Kit.interact(n, Vector3(0.78, F + 0.8, 3.32), Vector3(1.0, 1.0, 0.7), "Sit and rest for an hour", main.act.bind("rest", null))
			for wsg: float in [1.0, -1.0]:
				Kit.interact(n, Vector3(wsg * 0.78, F + 0.8, 7.62), Vector3(1.0, 1.0, 0.7), "Take the window seat and watch the line go by", main.act.bind("window", [idx, 7.62, wsg]))
			_passenger_detail(mb, n, straps, idx)
			work["Sanitation"] = [Vector3(0.0, F, 14.6), PI * 0.5]
		"medical":
			for k in 3:
				var z: float = 4.2 + float(k) * 3.6
				mb.box("steel", Vector3(-0.95, F + 0.5, z), Vector3(0.86, 0.06, 2.0))
				for lx: float in [-1.33, -0.57]:
					mb.cyl("steel", Vector3(lx, F + 0.25, z - 0.9), 0.025, 0.5, 1, 6)
					mb.cyl("steel", Vector3(lx, F + 0.25, z + 0.9), 0.025, 0.5, 1, 6)
				mb.box("mattress", Vector3(-0.95, F + 0.6, z), Vector3(0.8, 0.14, 1.95))
				mb.box("white_paint", Vector3(-0.95, F + 0.71, z - 0.75), Vector3(0.5, 0.09, 0.34))
				mb.box("seat", Vector3(-0.95, F + 0.69, z + 0.35), Vector3(0.84, 0.05, 1.15))
				mb.cyl("steel", Vector3(-0.42, F + 0.95, z - 0.95), 0.014, 1.9, 1, 6)
				mb.box("glass", Vector3(-0.42, F + 1.75, z - 0.95), Vector3(0.1, 0.18, 0.05))
				mb.box("mattress", Vector3(-0.95, F + 1.3, z + 1.5), Vector3(0.9, 1.7, 0.03))
				Kit.col(body, Vector3(-0.95, F + 0.4, z), Vector3(0.86, 0.8, 2.0))
			mb.sbox(body, "panel", Vector3(1.12, F + 0.45, 7.0), Vector3(0.55, 0.9, 6.0))
			mb.box("steel", Vector3(1.12, F + 0.91, 7.0), Vector3(0.58, 0.03, 6.0))
			mb.box("panel", Vector3(1.22, F + 1.9, 7.0), Vector3(0.34, 0.5, 6.0))
			for k in 6:
				mb.box("white_paint", Vector3(1.05, F + 1.0 + 0.04, 4.6 + float(k) * 0.9), Vector3(0.2, 0.12, 0.3))
			mb.box("red", Vector3(1.04, F + 1.9, 7.0), Vector3(0.02, 0.3, 0.3))
			mb.sbox(body, "panel_dk", Vector3(1.1, F + 0.38, 12.5), Vector3(0.6, 0.76, 1.4))
			mb.box("screen", Vector3(1.2, F + 1.05, 12.5), Vector3(0.04, 0.34, 0.5))
			Kit.interact(n, Vector3(1.0, F + 1.2, 7.0), Vector3(0.5, 1.4, 2.5), "Medical cabinet: treat your wounds", main.act.bind("med", null))
			work["Medical"] = [Vector3(-0.3, F, 4.4), PI * 0.5]
			seats.append([Vector3(0.6, F, 11.0), -PI * 0.5])
		"kitchen":
			mb.sbox(body, "steel_dk", Vector3(-1.1, F + 0.45, 6.5), Vector3(0.6, 0.9, 7.0))
			mb.box("steel", Vector3(-1.1, F + 0.915, 6.5), Vector3(0.64, 0.03, 7.0))
			mb.box("plastic", Vector3(-1.1, F + 0.94, 5.0), Vector3(0.55, 0.03, 1.2))
			for k in 4:
				mb.cyl("rubber", Vector3(-1.1 + (0.14 if k % 2 == 0 else -0.14), F + 0.96, 4.7 + float(k / 2) * 0.6), 0.1, 0.02, 1, 10)
			mb.cyl("steel", Vector3(-0.96, F + 1.07, 4.7), 0.14, 0.2, 1, 12)
			mb.cyl("steel", Vector3(-1.24, F + 1.05, 5.3), 0.11, 0.16, 1, 12)
			mb.box("steel", Vector3(-1.12, F + 1.95, 5.0), Vector3(0.6, 0.3, 1.6))
			mb.box("steel_dk", Vector3(-1.1, F + 0.9, 7.6), Vector3(0.4, 0.08, 0.6))
			mb.cyl("steel", Vector3(-1.3, F + 1.1, 7.6), 0.02, 0.35, 1, 6)
			mb.box("wood", Vector3(-1.25, F + 1.6, 8.6), Vector3(0.28, 0.03, 2.4))
			for k in 10:
				mb.cyl("amber_paint" if k % 3 == 0 else ("red" if k % 3 == 1 else "steel"), Vector3(-1.25, F + 1.68, 7.6 + float(k) * 0.22), 0.045, 0.12, 1, 8)
			mb.sbox(body, "hull_lt", Vector3(-1.05, F + 0.95, 13.6), Vector3(0.7, 1.9, 0.9))
			mb.box("steel", Vector3(-0.69, F + 1.1, 13.3), Vector3(0.02, 0.5, 0.03))
			for k in 2:
				var z: float = 5.0 + float(k) * 4.4
				mb.box("wood", Vector3(0.95, F + 0.75, z), Vector3(0.85, 0.04, 1.3))
				mb.cyl("steel", Vector3(0.95, F + 0.37, z), 0.04, 0.74, 1, 6)
				mb.box("seat", Vector3(0.95, F + 0.42, z - 1.0), Vector3(0.9, 0.12, 0.42))
				mb.box("seat", Vector3(0.95, F + 0.42, z + 1.0), Vector3(0.9, 0.12, 0.42))
				mb.box("plastic", Vector3(0.95, F + 0.18, z - 1.0), Vector3(0.8, 0.36, 0.3))
				mb.box("plastic", Vector3(0.95, F + 0.18, z + 1.0), Vector3(0.8, 0.36, 0.3))
				mb.cyl("white_paint", Vector3(0.9, F + 0.79, z - 0.3), 0.11, 0.02, 1, 10)
				mb.cyl("steel", Vector3(1.05, F + 0.83, z + 0.2), 0.04, 0.1, 1, 8)
				Kit.col(body, Vector3(0.95, F + 0.4, z), Vector3(0.9, 0.8, 2.5))
				seats.append([Vector3(0.75, F, z - 1.08), PI])
				seats.append([Vector3(0.75, F, z + 1.08), 0.0])
			Kit.interact(n, Vector3(-0.95, F + 1.1, 5.0), Vector3(0.6, 0.8, 1.6), "Galley: eat a hot meal", main.act.bind("meal", null))
			work["Cooking"] = [Vector3(-0.45, F, 5.2), PI * 0.5]
		"storage":
			var rng := RandomNumberGenerator.new()
			rng.seed = 77 + idx
			for sgn: float in [-1.0, 1.0]:
				for k in 7:
					mb.box("steel_dk", Vector3(sgn * 0.82, F + 1.05, 3.0 + float(k) * 2.1), Vector3(0.05, 2.1, 0.05))
				for sh: float in [0.45, 1.15, 1.85]:
					mb.box("steel_dk", Vector3(sgn * 1.1, F + sh, 9.3), Vector3(0.58, 0.04, 12.6))
					var z: float = 3.3
					while z < 15.0:
						var w: float = rng.randf_range(0.4, 0.9)
						var hh: float = rng.randf_range(0.25, 0.55)
						var r: float = rng.randf()
						if r < 0.45:
							mb.box("wood", Vector3(sgn * 1.1, F + sh + 0.02 + hh * 0.5, z + w * 0.5), Vector3(0.5, hh, w))
						elif r < 0.6:
							mb.box("sack", Vector3(sgn * 1.1, F + sh + 0.02 + hh * 0.4, z + w * 0.5), Vector3(0.5, hh * 0.8, w))
						elif r < 0.72:
							mb.box("red", Vector3(sgn * 1.1, F + sh + 0.22, z + 0.2), Vector3(0.36, 0.4, 0.2))
						elif r < 0.82:
							mb.cyl("hull", Vector3(sgn * 1.1, F + sh + 0.27, z + 0.3), 0.22, 0.5, 1, 10)
						z += w + rng.randf_range(0.1, 0.5)
				Kit.col(body, Vector3(sgn * 1.1, F + 1.1, 9.3), Vector3(0.6, 2.2, 12.6))
			mb.box("screen", Vector3(0.78, F + 1.5, 3.4), Vector3(0.03, 0.3, 0.44))
			Kit.interact(n, Vector3(0.9, F + 1.2, 4.5), Vector3(0.5, 1.8, 3.0), "Train storage: transfer supplies", main.act.bind("store", null))
			Kit.interact(n, Vector3(-0.9, F + 1.2, 4.5), Vector3(0.5, 1.8, 3.0), "Train storage: transfer supplies", main.act.bind("store", null))
			work["Sanitation"] = [Vector3(0.0, F, 8.0), -PI * 0.5]
		"workshop":
			mb.sbox(body, "steel_dk", Vector3(-1.05, F + 0.42, 7.0), Vector3(0.7, 0.84, 6.0))
			mb.box("wood", Vector3(-1.05, F + 0.87, 7.0), Vector3(0.74, 0.06, 6.1))
			mb.box("under", Vector3(-0.9, F + 1.0, 5.0), Vector3(0.2, 0.2, 0.3))
			mb.cyl("steel", Vector3(-0.9, F + 1.05, 4.8), 0.02, 0.4, 0, 6)
			mb.box("wood", Vector3(-1.38, F + 1.7, 7.0), Vector3(0.03, 0.9, 4.0))
			for k in 9:
				mb.box("steel" if k % 2 == 0 else "red", Vector3(-1.35, F + 1.75 + (0.15 if k % 3 == 0 else -0.1), 5.3 + float(k) * 0.42), Vector3(0.03, 0.34 if k % 2 == 0 else 0.2, 0.06))
			mb.box("under", Vector3(-1.0, F + 0.98, 9.0), Vector3(0.3, 0.16, 0.5))
			mb.cyl("steel", Vector3(-1.0, F + 1.1, 9.0), 0.1, 0.04, 0, 12)
			mb.sbox(body, "hull", Vector3(1.05, F + 0.55, 6.0), Vector3(0.7, 1.1, 2.2))
			mb.cyl("steel", Vector3(0.95, F + 1.25, 5.4), 0.14, 0.4, 2, 12)
			mb.box("steel_dk", Vector3(1.05, F + 1.2, 6.5), Vector3(0.5, 0.2, 0.9))
			mb.cyl("red", Vector3(1.2, F + 0.7, 9.2), 0.12, 1.4, 1, 10)
			mb.cyl("amber_paint", Vector3(1.2, F + 0.7, 9.6), 0.12, 1.4, 1, 10)
			Kit.col(body, Vector3(1.2, F + 0.7, 9.4), Vector3(0.3, 1.4, 0.7))
			mb.sbox(body, "wood", Vector3(1.05, F + 0.3, 12.5), Vector3(0.7, 0.6, 1.2))
			mb.sbox(body, "wood", Vector3(-1.05, F + 0.3, 13.2), Vector3(0.7, 0.6, 0.9))
			Kit.interact(n, Vector3(-0.9, F + 1.1, 7.0), Vector3(0.6, 0.8, 4.0), "Workbench: crafting and upgrades", main.act.bind("craft", null))
			work["Repairs"] = [Vector3(-0.35, F, 7.4), PI * 0.5]
		"generator":
			mb.sbox(body, "amber_paint", Vector3(-0.82, F + 0.75, 8.0), Vector3(1.1, 1.5, 6.0))
			mb.box("grille", Vector3(-0.26, F + 0.8, 6.5), Vector3(0.02, 0.9, 2.0))
			mb.box("grille", Vector3(-0.26, F + 0.8, 9.5), Vector3(0.02, 0.9, 2.0))
			mb.box("stripe", Vector3(-0.262, F + 0.1, 8.0), Vector3(0.01, 0.12, 6.0))
			mb.cyl("rust", Vector3(-0.82, F + 1.9, 6.0), 0.14, 0.9, 1, 10)
			mb.cyl("steel_dk", Vector3(-0.82, F + 1.6, 9.0), 0.3, 1.6, 2, 12)
			mb.cyl("hull", Vector3(-0.9, F + 0.6, 12.6), 0.45, 1.6, 2, 14)
			Kit.col(body, Vector3(-0.9, F + 0.6, 12.6), Vector3(0.9, 1.2, 1.6))
			mb.sbox(body, "panel_dk", Vector3(1.18, F + 0.95, 5.0), Vector3(0.42, 1.9, 1.6))
			mb.box("screen", Vector3(0.96, F + 1.45, 5.0), Vector3(0.02, 0.3, 0.5))
			for k in 6:
				mb.box("led_green" if k % 2 == 0 else "led_amber", Vector3(0.96, F + 1.05, 4.5 + float(k) * 0.2), Vector3(0.02, 0.05, 0.05))
			mb.box("steel_dk", Vector3(1.25, F + 2.05, 9.0), Vector3(0.25, 0.06, 12.0))
			for k in 3:
				mb.cyl("rubber", Vector3(1.2 + float(k) * 0.06, F + 2.1, 9.0), 0.025, 12.0, 2, 5)
			Kit.interact(n, Vector3(1.0, F + 1.3, 5.0), Vector3(0.5, 1.2, 1.6), "@gen", main.act.bind("gen", null))
			work["Power"] = [Vector3(0.5, F, 5.6), -PI * 0.5]
		"security":
			for k in 5:
				mb.box("hull_blk", Vector3(-1.15, F + 0.95, 3.6 + float(k) * 0.8), Vector3(0.45, 1.9, 0.74))
				mb.box("steel", Vector3(-0.91, F + 1.0, 3.8 + float(k) * 0.8), Vector3(0.02, 0.2, 0.03))
			Kit.col(body, Vector3(-1.15, F + 0.95, 5.2), Vector3(0.45, 1.9, 4.0))
			mb.sbox(body, "steel_dk", Vector3(1.05, F + 0.4, 6.0), Vector3(0.7, 0.8, 3.4))
			for k in 3:
				mb.box("plastic", Vector3(1.28, F + 1.15, 5.0 + float(k) * 1.0), Vector3(0.06, 0.5, 0.8))
				mb.box("screen", Vector3(1.24, F + 1.15, 5.0 + float(k) * 1.0), Vector3(0.02, 0.42, 0.7))
			for sgn: float in [-1.0, 1.0]:
				for k in 6:
					mb.box("steel_dk", Vector3(sgn * 1.52, 2.85, 3.8 + float(k) * 2.15), Vector3(0.03, 0.45, 1.7))
				for k in 4:
					mb.box("sack", Vector3(sgn * 1.1, F + 0.14 + float(k % 2) * 0.26, 10.5 + float(k) * 0.5), Vector3(0.6, 0.26, 0.5))
				Kit.col(body, Vector3(sgn * 1.1, F + 0.3, 11.2), Vector3(0.6, 0.6, 2.0))
			Kit.interact(n, Vector3(-0.95, F + 1.1, 5.2), Vector3(0.5, 1.6, 4.0), "Armoury: draw 10 rounds from stores", main.act.bind("armoury", null))
			work["Guard"] = [Vector3(0.3, F, 6.0), -PI * 0.5]
		"greenhouse":
			for sgn: float in [-1.0, 1.0]:
				mb.sbox(body, "wood", Vector3(sgn * 1.0, F + 0.28, 9.0), Vector3(0.8, 0.56, 12.0))
				mb.box("soil", Vector3(sgn * 1.0, F + 0.58, 9.0), Vector3(0.7, 0.04, 11.8))
				mb.box("grow", Vector3(sgn * 1.0, F + 1.75, 9.0), Vector3(0.12, 0.03, 11.5))
				mb.cyl("steel", Vector3(sgn * 0.62, F + 0.62, 9.0), 0.02, 12.0, 2, 5)
				for k in 44:
					var px: float = sgn * (0.75 + 0.25 * float(k % 3))
					var hh: float = 0.25 + 0.22 * float((k * 7) % 5) / 4.0
					_plant(mb, Vector3(px, F + 0.6, 3.3 + float(k) * 0.265), hh, k + (0 if sgn < 0.0 else 2))
				for k in 6:
					mb.cyl("steel_dk", Vector3(sgn * 1.0, F + 1.2, 3.6 + float(k) * 2.2), 0.008, 1.1, 1, 4)
					mb.box("steel_dk", Vector3(sgn * 1.0, F + 1.73, 3.6 + float(k) * 2.2), Vector3(0.2, 0.03, 0.06))
				mb.box("white_paint", Vector3(sgn * 0.63, F + 0.5, 3.2), Vector3(0.012, 0.1, 0.16))
			mb.cyl("hull", Vector3(0.0, F + 0.5, 15.3), 0.3, 1.0, 1, 12)
			_lamp(n, Vector3(0, 2.9, 8.5), 0.8, 6.0)
			Kit.interact(n, Vector3(1.0, F + 1.0, 8.0), Vector3(0.8, 1.5, 9.0), "@harvest", main.act.bind("harvest", null))
			work["Farming"] = [Vector3(0.3, F, 7.0), -PI * 0.5]
		"water":
			for k in 3:
				var z: float = 4.6 + float(k) * 3.2
				mb.cyl("steel", Vector3(-0.75, F + 0.95, z), 0.62, 1.9, 1, 16)
				mb.cyl("hull", Vector3(-0.75, F + 0.5, z), 0.635, 0.08, 1, 16)
				mb.cyl("hull", Vector3(-0.75, F + 1.5, z), 0.635, 0.08, 1, 16)
				mb.cyl("steel_dk", Vector3(-0.75, F + 2.0, z), 0.06, 0.3, 1, 6)
				Kit.col(body, Vector3(-0.75, F + 0.95, z), Vector3(1.24, 1.9, 1.24))
			mb.cyl("steel_dk", Vector3(-0.75, F + 2.12, 7.8), 0.05, 7.2, 2, 6)
			for k in 4:
				mb.cyl("hull", Vector3(1.15, F + 0.7, 4.4 + float(k) * 0.6), 0.2, 1.2, 1, 10)
			Kit.col(body, Vector3(1.15, F + 0.7, 5.3), Vector3(0.45, 1.4, 2.4))
			mb.sbox(body, "steel_dk", Vector3(1.05, F + 0.35, 9.0), Vector3(0.6, 0.7, 1.4))
			mb.cyl("amber_paint", Vector3(1.05, F + 0.9, 9.0), 0.22, 0.6, 2, 12)
			mb.cyl("steel", Vector3(1.3, F + 1.5, 8.0), 0.04, 9.0, 2, 6)
			mb.cyl("red", Vector3(1.3, F + 1.5, 7.0), 0.09, 0.06, 2, 8)
			mb.cyl("red", Vector3(1.3, F + 1.5, 10.5), 0.09, 0.06, 2, 8)
			mb.sbox(body, "panel_dk", Vector3(1.2, F + 0.9, 12.5), Vector3(0.4, 1.8, 1.2))
			mb.box("screen", Vector3(0.99, F + 1.4, 12.5), Vector3(0.02, 0.3, 0.5))
			Kit.interact(n, Vector3(1.0, F + 1.0, 9.0), Vector3(0.6, 1.2, 1.6), "Water tap: drink", main.act.bind("tap", null))
			work["Water"] = [Vector3(0.45, F, 12.0), -PI * 0.5]
	return {"seats": seats, "work": work, "straps": straps}

# ---------------- locomotive ----------------
func _build_loco() -> void:
	var n := Node3D.new()
	n.position = Vector3(0, 0, -LL)
	add_child(n)
	loco_node = n
	var body := StaticBody3D.new()
	n.add_child(body)
	var mb := Kit.new()
	var F: float = FY
	_floor_roof(mb, body, 0.9, LL)
	_end_wall(mb, body, LL - 0.05, 1.0)
	# nose
	mb.box("hull", Vector3(0, 1.5, 0.5), Vector3(2.5, 1.3, 0.85))
	for sgn: float in [-1.0, 1.0]:
		mb.box("hull", Vector3(sgn * 1.3625, 1.5, 0.6125), Vector3(0.225, 1.3, 0.625))
		mb.cyl("hull", Vector3(sgn * 1.25, 1.5, 0.3), 0.225, 1.3, 1, 16)
		mb.cyl("hull_blk", Vector3(sgn * 1.25, 1.72, 0.3), 0.229, 0.36, 1, 16)
		mb.cyl("stripe", Vector3(sgn * 1.25, 1.2, 0.3), 0.228, 0.5, 1, 16)
		mb.cyl("hull_blk", Vector3(sgn * 1.25, 0.95, 0.3), 0.24, 0.18, 1, 16)
		mb.cyl("steel", Vector3(sgn * 1.25, 1.46, 0.3), 0.231, 0.03, 1, 16)
		mb.cyl("steel", Vector3(sgn * 1.52, 1.75, 0.7), 0.016, 1.1, 1, 6)
		for rg in 3:
			mb.box("steel_dk", Vector3(sgn * 1.53, 0.45 + float(rg) * 0.26, 0.75), Vector3(0.06, 0.03, 0.34))
	mb.box("stripe", Vector3(0, 1.2, 0.07), Vector3(2.6, 0.5, 0.02))
	mb.box("hull_blk", Vector3(0, 1.72, 0.07), Vector3(2.5, 0.36, 0.02))
	mb.box("hull", Vector3(0, 2.2, 0.6), Vector3(2.9, 0.12, 0.75), Basis(Vector3.RIGHT, 0.12))
	mb.box("floor", Vector3(0, F - 0.04, 0.5), Vector3(2.8, 0.08, 0.85))
	Kit.col(body, Vector3(0, 1.6, 0.45), Vector3(3.0, 1.6, 0.9))
	mb.box("glass", Vector3(0, 2.76, 0.83), Vector3(2.6, 1.22, 0.03), Basis(Vector3.RIGHT, 0.3))
	mb.box("hull_blk", Vector3(0, 2.76, 0.81), Vector3(0.08, 1.24, 0.06), Basis(Vector3.RIGHT, 0.3))
	for sgn: float in [-1.0, 1.0]:
		mb.box("hull_blk", Vector3(sgn * 1.38, 2.76, 0.84), Vector3(0.2, 1.3, 0.2), Basis(Vector3.RIGHT, 0.3))
		mb.box("lamp_white", Vector3(sgn * 1.02, 1.72, 0.055), Vector3(0.3, 0.17, 0.03))
		mb.box("lamp_red", Vector3(sgn * 1.25, 1.72, 0.055), Vector3(0.12, 0.12, 0.03))
		mb.cyl("under", Vector3(sgn * 0.95, 0.98, 0.0), 0.14, 0.3, 2, 10)
		var sp := SpotLight3D.new()
		sp.position = Vector3(sgn * 1.02, 1.72, -0.05)
		sp.rotation.x = -0.06
		sp.spot_range = 75.0
		sp.spot_angle = 26.0
		sp.light_energy = 0.0
		sp.light_color = Color(0.95, 0.97, 1.0)
		sp.shadow_enabled = false
		n.add_child(sp)
		spots.append(sp)
	# nose detail: snowplough, valance, buffers, coupler, light clusters, number
	for sgn: float in [-1.0, 1.0]:
		mb.box("amber_paint", Vector3(sgn * 0.72, 0.42, -0.18), Vector3(1.62, 0.5, 0.07), Basis(Vector3.UP, sgn * 0.42) * Basis(Vector3.RIGHT, -0.3))
		mb.box("under", Vector3(sgn * 0.72, 0.2, -0.24), Vector3(1.64, 0.1, 0.09), Basis(Vector3.UP, sgn * 0.42))
		mb.cyl("steel_dk", Vector3(sgn * 0.95, 0.98, -0.2), 0.2, 0.08, 2, 12)
		mb.box("steel", Vector3(sgn * 1.02, 1.72, 0.045), Vector3(0.4, 0.26, 0.02))
		mb.box("hull_blk", Vector3(sgn * 1.1, 2.02, 0.06), Vector3(0.36, 0.1, 0.03))
		mb.box("steel_dk", Vector3(sgn * 1.44, 1.3, 0.3), Vector3(0.05, 0.9, 0.05))
		mb.box("rubber", Vector3(sgn * 0.5, 0.72, -0.1), Vector3(0.05, 0.05, 0.5))
	mb.box("hull_blk", Vector3(0, 0.95, 0.05), Vector3(2.5, 0.18, 0.06))
	mb.box("steel_dk", Vector3(0, 0.9, -0.42), Vector3(0.3, 0.3, 0.16))
	mb.box("steel", Vector3(0, 1.98, 0.058), Vector3(1.5, 0.03, 0.02))
	mb.box("steel", Vector3(0, 1.46, 0.058), Vector3(2.6, 0.03, 0.02))
	Kit.text3d(n, Vector3(0, 1.2, 0.055), "4071", 96, Color(0.08, 0.08, 0.09), 0.0, 0.004)
	Kit.text3d(n, Vector3(0, 3.5, 0.87), "KALDWICK", 44, Color(1.0, 0.72, 0.25), 0.0, 0.004)
	mb.box("hull_lt", Vector3(0, 3.5, 1.1), Vector3(2.95, 0.4, 0.45))
	mb.box("glass_dark", Vector3(0, 3.5, 0.868), Vector3(1.5, 0.24, 0.03))
	mb.box("lamp_white", Vector3(0, 3.72, 0.9), Vector3(0.3, 0.1, 0.03))
	Kit.col(body, Vector3(0, 2.9, 0.85), Vector3(3.0, 1.6, 0.3))
	mb.box("under", Vector3(0, 0.48, 0.25), Vector3(2.7, 0.55, 0.4), Basis(Vector3.RIGHT, 0.4))
	mb.box("under", Vector3(0, 0.9, -0.15), Vector3(0.24, 0.22, 0.5))
	# walls: cab, crew room, engine room
	for sgn: float in [-1.0, 1.0]:
		_wall_run(mb, body, sgn, 0.3, 3.4, [[1.2, 2.9]])
		_wall_run(mb, body, sgn, 3.4, 5.6, [[4.0, 5.0]])
		_wall_run(mb, body, sgn, 5.6, LL, [])
		for k in 3:
			mb.box("grille", Vector3(sgn * 1.505, 2.6, 7.4 + float(k) * 2.6), Vector3(0.02, 0.8, 2.0))
		Kit.text3d(n, Vector3(sgn * 1.51, 1.62, 10.0), "NORTHERN LINE  4071", 80, Color(0.85, 0.83, 0.78), sgn * PI * 0.5, 0.0035)
		for dz2: float in [7.4, 10.0, 12.6]:
			mb.box("hull_blk", Vector3(sgn * 1.5045, 2.07, dz2 - 1.1), Vector3(0.006, 2.02, 0.02))
			mb.box("hull_blk", Vector3(sgn * 1.5045, 2.07, dz2 + 1.1), Vector3(0.006, 2.02, 0.02))
			mb.box("hull_blk", Vector3(sgn * 1.5045, 3.08, dz2), Vector3(0.006, 0.02, 2.2))
			mb.box("hull_blk", Vector3(sgn * 1.5045, 1.06, dz2), Vector3(0.006, 0.02, 2.2))
			mb.box("steel", Vector3(sgn * 1.512, 1.9, dz2 + 0.98), Vector3(0.02, 0.16, 0.04))
			for hy: float in [1.35, 2.8]:
				mb.box("steel_dk", Vector3(sgn * 1.51, hy, dz2 - 1.08), Vector3(0.02, 0.12, 0.05))
		mb.box("hull_blk", Vector3(sgn * 1.5045, 2.0, 0.42), Vector3(0.006, 2.1, 0.02))
		mb.box("hull_blk", Vector3(sgn * 1.5045, 2.0, 1.12), Vector3(0.006, 2.1, 0.02))
		mb.box("steel", Vector3(sgn * 1.515, 1.9, 1.02), Vector3(0.025, 0.05, 0.14))
		mb.cyl("steel", Vector3(sgn * 1.47, 0.86, 7.5), 0.07, 0.12, 0, 10)
		mb.cyl("red", Vector3(sgn * 1.535, 0.86, 7.5), 0.055, 0.02, 0, 10)
		mb.box("white_paint", Vector3(sgn * 1.505, 0.86, 7.9), Vector3(0.008, 0.2, 0.08))
		mb.box("amber_paint", Vector3(sgn * 1.509, 0.82, 7.9), Vector3(0.004, 0.1, 0.03))
		mb.box("hull_blk", Vector3(sgn * 1.502, 2.2, 3.15), Vector3(0.012, 1.9, 0.03))
		mb.cyl("steel", Vector3(sgn * 1.54, 2.1, 3.3), 0.018, 1.2, 1, 6)
		mb.box("under", Vector3(sgn * 1.4, 0.5, 2.6), Vector3(0.25, 0.04, 0.6))
		mb.box("under", Vector3(sgn * 1.4, 0.8, 2.6), Vector3(0.25, 0.04, 0.6))
	# cab rear wall, door centre
	for sgn: float in [-1.0, 1.0]:
		mb.sbox(body, "panel", Vector3(sgn * 0.925, 2.375, 3.4), Vector3(0.95, 2.25, 0.06))
	mb.sbox(body, "panel", Vector3(0, 3.42, 3.4), Vector3(0.9, 0.2, 0.06))
	Kit.text3d(n, Vector3(0, 3.42, 3.44), "DRIVER'S CAB", 40, Color(1.0, 0.75, 0.3), 0.0, 0.002)
	# desk
	mb.sbox(body, "plastic", Vector3(0, F + 0.42, 1.42), Vector3(2.76, 0.84, 0.6))
	mb.box("panel_dk", Vector3(0, F + 0.9, 1.5), Vector3(2.5, 0.04, 0.5), Basis(Vector3.RIGHT, 0.35))
	mb.box("plastic", Vector3(0, F + 1.06, 1.13), Vector3(2.3, 0.34, 0.06), Basis(Vector3.RIGHT, -0.2))
	for k in 3:
		mb.box("screen", Vector3(-0.72 + float(k) * 0.72, F + 1.06, 1.165), Vector3(0.62, 0.27, 0.02), Basis(Vector3.RIGHT, -0.2))
	d_stat = Kit.text3d(n, Vector3(-0.72, F + 1.06, 1.185), "", 26, Color(0.75, 1.0, 0.9), 0.0, 0.0018)
	d_speed = Kit.text3d(n, Vector3(0, F + 1.06, 1.185), "0", 64, Color(1.0, 0.85, 0.5), 0.0, 0.0022)
	d_info = Kit.text3d(n, Vector3(0.72, F + 1.06, 1.185), "", 26, Color(0.75, 1.0, 0.9), 0.0, 0.0018)
	for l: Label3D in [d_stat, d_speed, d_info]:
		l.rotation.x = -0.2
	var sw: Array = [["engine", "ENG", -0.75], ["lights", "LAMP", -0.45], ["wipers", "WIPE", -0.15], ["doors", "DOOR", 0.15], ["auto", "AUTO", 0.45], ["horn", "HORN", 0.75]]
	for s: Array in sw:
		var sx: float = s[2]
		var key: String = s[0]
		mb.box("steel", Vector3(sx, F + 0.93, 1.56), Vector3(0.05, 0.06, 0.05))
		mb.box("led_amber" if key != "engine" else "lamp_red", Vector3(sx, F + 0.96, 1.47), Vector3(0.03, 0.02, 0.03))
		var tl: Label3D = Kit.text3d(n, Vector3(sx, F + 0.9, 1.66), s[1], 24, Color(0.9, 0.88, 0.8), 0.0, 0.0013)
		tl.rotation.x = -1.2
		Kit.interact(n, Vector3(sx, F + 0.98, 1.56), Vector3(0.26, 0.26, 0.34), "@" + key, main.act.bind(key, null))
	thr_lever = _lever(n, Vector3(1.08, F + 0.9, 1.52), "amber_paint")
	brk_lever = _lever(n, Vector3(-1.08, F + 0.9, 1.52), "red")
	mb.box("steel_dk", Vector3(1.08, F + 0.9, 1.52), Vector3(0.14, 0.05, 0.3))
	mb.box("steel_dk", Vector3(-1.08, F + 0.9, 1.52), Vector3(0.14, 0.05, 0.3))
	# driver seat
	mb.cyl("steel_dk", Vector3(0, F + 0.22, 2.5), 0.06, 0.44, 1, 8)
	_seat_shell(mb, Vector3(0, F + 0.08, 2.83), -1.0, 0.27, "seat", "seat_dk", false)
	mb.box("steel_dk", Vector3(0, F + 0.4, 2.52), Vector3(0.4, 0.08, 0.42))
	mb.box("plastic", Vector3(0.3, F + 0.7, 2.52), Vector3(0.05, 0.05, 0.4))
	mb.box("plastic", Vector3(-0.3, F + 0.7, 2.52), Vector3(0.05, 0.05, 0.4))
	Kit.col(body, Vector3(0, F + 0.4, 2.45), Vector3(0.3, 0.8, 0.3))
	Kit.interact(n, Vector3(0, F + 0.7, 2.6), Vector3(0.6, 0.9, 0.55), "@seat", main.act.bind("seat", null))
	mb.box("red", Vector3(1.3, F + 0.3, 3.2), Vector3(0.14, 0.5, 0.14))
	mb.box("light_warm", Vector3(0, CY - 0.03, 2.3), Vector3(0.3, 0.03, 0.3))
	_lamp(n, Vector3(0, 3.1, 2.6), 0.55, 4.5)
	# wipers
	for sgn: float in [-1.0, 1.0]:
		var piv := Node3D.new()
		piv.position = Vector3(sgn * 0.62, 2.22, 0.63)
		piv.rotation.x = 0.3
		n.add_child(piv)
		var arm := Node3D.new()
		piv.add_child(arm)
		var bm := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = Vector3(0.025, 0.7, 0.025)
		bm.mesh = bx
		bm.material_override = Kit.plain("rubber")
		bm.position = Vector3(0, 0.35, -0.03)
		arm.add_child(bm)
		arm.rotation.z = sgn * 1.2
		arm.set_meta("sgn", sgn)
		wipers.append(arm)
	# crew room
	mb.sbox(body, "plastic", Vector3(-0.95, F + 0.2, 4.5), Vector3(0.86, 0.4, 1.95))
	mb.box("mattress", Vector3(-0.95, F + 0.46, 4.5), Vector3(0.8, 0.12, 1.9))
	mb.box("white_paint", Vector3(-0.95, F + 0.56, 3.75), Vector3(0.5, 0.09, 0.32))
	mb.box("seat", Vector3(-0.95, F + 0.54, 4.85), Vector3(0.82, 0.05, 1.1))
	mb.box("plastic", Vector3(-0.95, F + 1.5, 4.5), Vector3(0.86, 0.06, 1.95))
	mb.box("mattress", Vector3(-0.95, F + 1.58, 4.5), Vector3(0.8, 0.1, 1.9))
	Kit.interact(n, Vector3(-0.85, F + 0.7, 4.5), Vector3(0.9, 0.7, 1.9), "Crew bunk: sleep until rested", main.act.bind("sleep", null))
	mb.sbox(body, "panel_dk", Vector3(1.14, F + 0.95, 3.9), Vector3(0.5, 1.9, 0.8))
	mb.box("plastic", Vector3(1.36, F + 1.45, 4.9), Vector3(0.06, 0.5, 0.74))
	mb.box("screen", Vector3(1.325, F + 1.45, 4.9), Vector3(0.02, 0.42, 0.66))
	Kit.text3d(n, Vector3(1.31, F + 1.45, 4.9), "TRAIN\nMANAGEMENT", 28, Color(0.8, 1.0, 0.92), -PI * 0.5, 0.0018)
	Kit.interact(n, Vector3(1.25, F + 1.45, 4.9), Vector3(0.3, 0.6, 0.8), "Train management terminal", main.act.bind("manage", null))
	_lamp(n, Vector3(0.2, 3.1, 4.6), 0.6, 4.0)
	mb.box("light_warm", Vector3(0.2, CY - 0.03, 4.5), Vector3(0.3, 0.03, 0.3))
	# engine room partition (door on +x corridor)
	mb.sbox(body, "panel_dk", Vector3(-0.45, 2.375, 5.6), Vector3(1.9, 2.25, 0.06))
	mb.sbox(body, "panel_dk", Vector3(0.95, 3.42, 5.6), Vector3(0.9, 0.2, 0.06))
	Kit.text3d(n, Vector3(0.95, 3.42, 5.56), "ENGINE ROOM", 36, Color(1.0, 0.75, 0.3), PI, 0.002)
	# engine
	mb.box("under", Vector3(-0.6, F + 0.65, 9.4), Vector3(1.5, 1.3, 5.6))
	for k in 8:
		mb.box("steel_dk", Vector3(-0.6, F + 1.42, 7.0 + float(k) * 0.68), Vector3(1.1, 0.24, 0.5))
		mb.cyl("amber_paint", Vector3(-0.1, F + 1.5, 7.0 + float(k) * 0.68), 0.04, 0.3, 1, 6)
	mb.cyl("steel_dk", Vector3(-0.6, F + 1.75, 6.5), 0.26, 0.6, 2, 12)
	mb.cyl("rust", Vector3(-0.6, F + 2.1, 6.9), 0.15, 1.0, 1, 10)
	mb.cyl("steel_dk", Vector3(-0.6, F + 0.7, 13.0), 0.6, 1.5, 2, 16)
	mb.cyl("amber_paint", Vector3(-1.28, F + 1.75, 9.5), 0.05, 6.4, 2, 6)
	mb.cyl("red", Vector3(0.12, F + 1.65, 9.5), 0.035, 6.4, 2, 6)
	mb.cyl("steel", Vector3(0.42, F + 1.0, 9.9), 0.022, 8.4, 2, 6)
	for k in 5:
		mb.cyl("steel", Vector3(0.42, F + 0.5, 5.9 + float(k) * 2.0), 0.022, 1.0, 1, 6)
	Kit.col(body, Vector3(-0.5, F + 1.1, 9.9), Vector3(1.84, 2.2, 8.5))
	mb.box("panel_dk", Vector3(0.38, F + 1.5, 13.6), Vector3(0.04, 0.8, 0.9))
	for k in 5:
		mb.box("led_green" if k % 2 == 0 else "led_amber", Vector3(0.405, F + 1.7, 13.3 + float(k) * 0.15), Vector3(0.02, 0.04, 0.04))
	Kit.interact(n, Vector3(0.3, F + 1.2, 9.5), Vector3(0.4, 1.4, 5.0), "@fixengine", main.act.bind("fixengine", null))
	var el: OmniLight3D = Kit.omni(n, Vector3(0.9, 3.0, 9.5), Color(1.0, 0.6, 0.3), 0.7, 6.0)
	el.set_meta("e", 0.7)
	lamps.append(el)
	mb.box("led_amber", Vector3(0.95, CY - 0.03, 9.5), Vector3(0.12, 0.03, 0.3))
	# roof gear
	for sgn: float in [-1.0, 1.0]:
		mb.cyl("steel", Vector3(sgn * 0.3, CY + 0.42, 1.7), 0.09, 0.5, 2, 10, 0.04)
	for fz: float in [8.0, 10.6]:
		mb.cyl("under", Vector3(0, CY + 0.34, fz), 0.62, 0.12, 1, 18)
		mb.cyl("grille", Vector3(0, CY + 0.405, fz), 0.55, 0.012, 1, 18)
		mb.cyl("steel_dk", Vector3(0, CY + 0.42, fz), 0.1, 0.03, 1, 8)
	mb.cyl("steel_dk", Vector3(0.9, CY + 0.7, 4.0), 0.012, 1.1, 1, 4)
	mb.cyl("steel_dk", Vector3(-0.9, CY + 0.45, 4.6), 0.2, 0.06, 1, 10)
	mb.cyl("rust", Vector3(-0.6, CY + 0.4, 6.9), 0.17, 0.4, 1, 10)
	mb.box("roof", Vector3(0, CY + 0.34, 13.0), Vector3(1.6, 0.2, 2.2))
	_cab_detail(mb, n)
	_ground_shadow(n, LL)
	_bogie(mb, n, 3.2, true)
	_bogie(mb, n, 11.8, true)
	mb.cyl("hull", Vector3(0, 0.66, 7.5), 0.52, 3.8, 2, 14)
	mb.box("under", Vector3(0.9, 0.75, 7.5), Vector3(0.5, 0.45, 1.6))
	mb.box("under", Vector3(-0.9, 0.75, 7.5), Vector3(0.5, 0.45, 1.6))
	mb.commit(n)

func _cab_detail(mb: Kit, n: Node3D) -> void:
	var F: float = FY
	# overhead console with four analogue gauges (needles driven in render)
	mb.box("plastic", Vector3(0, 3.24, 1.34), Vector3(1.5, 0.3, 0.12), Basis(Vector3.RIGHT, 0.45))
	var kinds: Array = [["speed", "KM/H"], ["brake", "BRAKE"], ["rpm", "RPM"], ["volt", "BATT"]]
	for gi in 4:
		var g := Node3D.new()
		g.position = Vector3(-0.51 + float(gi) * 0.34, 3.209, 1.405)
		g.rotation.x = 0.45
		n.add_child(g)
		var gm := Kit.new()
		gm.cyl("steel_dk", Vector3.ZERO, 0.088, 0.02, 2, 18)
		gm.cyl("white_paint", Vector3(0, 0, 0.011), 0.074, 0.004, 2, 18)
		for a in 9:
			var an: float = lerpf(2.2, -2.2, float(a) / 8.0)
			gm.box("hull_blk", Vector3(-sin(an) * 0.06, cos(an) * 0.06, 0.014), Vector3(0.005, 0.014, 0.002), Basis(Vector3.BACK, an))
		gm.commit(g, false)
		var nd := Node3D.new()
		nd.position.z = 0.018
		nd.rotation.z = 2.2
		g.add_child(nd)
		var nm := Kit.new()
		nm.box("red", Vector3(0, 0.026, 0), Vector3(0.007, 0.064, 0.003))
		nm.cyl("hull_blk", Vector3.ZERO, 0.012, 0.006, 2, 8)
		nm.commit(nd, false)
		var kd: Array = kinds[gi]
		Kit.text3d(g, Vector3(0, -0.038, 0.016), str(kd[1]), 14, Color(0.1, 0.1, 0.12), 0.0, 0.001)
		needles.append([nd, kd[0]])
	# desk and cab props
	mb.cyl("red", Vector3(-0.62, F + 0.985, 1.4), 0.035, 0.05, 1, 10)
	mb.cyl("amber_paint", Vector3(-0.62, F + 0.95, 1.4), 0.05, 0.03, 1, 10)
	mb.cyl("steel", Vector3(-1.22, F + 0.96, 1.26), 0.045, 0.22, 1, 10)
	mb.cyl("hull_blk", Vector3(-1.22, F + 1.08, 1.26), 0.035, 0.04, 1, 10)
	mb.box("white_paint", Vector3(0.36, F + 0.862, 1.72), Vector3(0.22, 0.004, 0.3), Basis(Vector3.RIGHT, 0.35) * Basis(Vector3.UP, 0.15))
	mb.box("wood", Vector3(0.36, F + 0.858, 1.72), Vector3(0.25, 0.004, 0.33), Basis(Vector3.RIGHT, 0.35) * Basis(Vector3.UP, 0.15))
	mb.box("steel_dk", Vector3(0, F + 0.12, 1.86), Vector3(0.7, 0.04, 0.3), Basis(Vector3.RIGHT, -0.4))
	mb.box("rubber", Vector3(0, F + 0.004, 2.5), Vector3(1.6, 0.008, 1.4))
	for sgn: float in [-1.0, 1.0]:
		mb.box("panel_dk", Vector3(sgn * 1.37, F + 0.8, 2.2), Vector3(0.07, 0.34, 0.9))
		for k in 10:
			var bm: String = ["led_amber", "led_green", "steel", "red", "hull_blk"][(k * 3 + int(sgn + 1.0)) % 5]
			mb.box(bm, Vector3(sgn * 1.33, F + 0.72 + float(k / 5) * 0.14, 1.88 + float(k % 5) * 0.16), Vector3(0.014, 0.05, 0.05))
		mb.box("plastic", Vector3(sgn * 0.66, 3.3, 1.02), Vector3(1.0, 0.02, 0.28), Basis(Vector3.RIGHT, 0.55))
		mb.box("hull_blk", Vector3(sgn * 1.7, 2.9, 1.0), Vector3(0.05, 0.38, 0.2))
		mb.box("steel_dk", Vector3(sgn * 1.6, 2.9, 1.06), Vector3(0.2, 0.03, 0.03))
		mb.cyl("steel", Vector3(sgn * 1.535, 1.6, 0.9), 0.016, 1.0, 1, 6)
		mb.cyl("steel", Vector3(sgn * 1.2, 2.24, 0.12), 0.014, 0.5, 0, 6)
	mb.box("hull_blk", Vector3(1.37, F + 1.3, 3.0), Vector3(0.06, 0.22, 0.1))
	mb.cyl("rubber", Vector3(1.37, F + 1.05, 3.0), 0.012, 0.36, 1, 5)
	mb.box("panel_dk", Vector3(1.38, F + 1.34, 3.16), Vector3(0.05, 0.16, 0.14))
	mb.box("led_green", Vector3(1.35, F + 1.38, 3.16), Vector3(0.01, 0.02, 0.02))
	var prot := Basis(Vector3.RIGHT, 0.35)
	mb.box("hull_blk", Vector3(0.0, F + 0.986, 1.33), Vector3(0.76, 0.004, 0.09), prot)
	for i in 12:
		var tx: float = -0.33 + float(i) * 0.06
		var up: bool = i % 3 == 0
		mb.box("steel_dk", Vector3(tx, F + 0.992, 1.33), Vector3(0.026, 0.006, 0.03), prot)
		mb.box("steel", Vector3(tx, F + 1.008, 1.33 + (0.006 if up else -0.004)), Vector3(0.007, 0.034, 0.007), Basis(Vector3.RIGHT, 0.35 + (0.5 if up else -0.45)))
		mb.box("led_amber" if up else "led_green", Vector3(tx, F + 1.003, 1.292), Vector3(0.008, 0.006, 0.008))
		if i % 4 == 1:
			mb.box("red", Vector3(tx, F + 1.004, 1.352), Vector3(0.032, 0.03, 0.004), Basis(Vector3.RIGHT, 0.95))
	mb.box("hull_blk", Vector3(0.58, F + 0.975, 1.36), Vector3(0.13, 0.008, 0.15), prot)
	for r in 4:
		for c2 in 3:
			mb.box("steel" if (r + c2) % 5 != 0 else "amber_paint", Vector3(0.545 + float(c2) * 0.035, F + 0.995 - float(r) * 0.0113, 1.315 + float(r) * 0.031), Vector3(0.024, 0.008, 0.02), prot)
	var srot := Basis(Vector3.RIGHT, -0.2)
	for k in 3:
		var scx: float = -0.72 + float(k) * 0.72
		for j in 6:
			mb.box("steel_dk", Vector3(scx + (float(j) - 2.5) * 0.09, F + 1.06, 1.13) + srot * Vector3(0, -0.153, 0.034), Vector3(0.05, 0.016, 0.01), srot)
		for sgn2: float in [-1.0, 1.0]:
			mb.box("hull_blk", Vector3(scx + sgn2 * 0.318, F + 1.06, 1.13) + srot * Vector3(0, 0, 0.036), Vector3(0.016, 0.3, 0.012), srot)
	mb.box("steel", Vector3(0.92, F + 0.95, 1.6), Vector3(0.02, 0.07, 0.02), Basis(Vector3.RIGHT, 0.6))
	mb.cyl("steel_dk", Vector3(0.92, F + 0.915, 1.47), 0.022, 0.03, 1, 8)
	mb.box("gun_brass", Vector3(0.92, F + 0.945, 1.47), Vector3(0.006, 0.03, 0.02))
	mb.cyl("amber_paint", Vector3(-0.9, F + 0.905, 1.62), 0.03, 0.03, 1, 10)
	var keep2: Transform3D = mb.xf
	mb.xf = Transform3D(Basis(Vector3(0, 0, 1), Vector3.UP, Vector3(-1, 0, 0)), Vector3.ZERO)
	mb.loft("rubber", Kit.arc(1.72, F + 0.8, 0.05, 0.05, PI * 0.5, -PI * 0.5, 6), -1.38, 1.38)
	mb.xf = keep2
	# annunciator strip under the overhead console: each lamp follows the real state of the train
	var arot := Basis(Vector3.RIGHT, 0.45)
	var acen := Vector3(0, 3.066, 1.258)
	mb.box("plastic", acen, Vector3(1.5, 0.085, 0.1), arot)
	var anames: Array = ["ENGINE", "BATTERY", "BRAKE", "DOORS", "AUTO", "FUEL", "COLD", "ALARM"]
	for i in 8:
		var lx: float = -0.6 + float(i) * 0.1714
		mb.box("ann_%d" % i, acen + arot * Vector3(lx, 0.0, 0.052), Vector3(0.15, 0.05, 0.012), arot)
		var al: Label3D = Kit.text3d(n, acen + arot * Vector3(lx, 0.0, 0.0595), str(anames[i]), 22, Color(0.04, 0.04, 0.05), 0.0, 0.0011)
		al.rotation.x = 0.45
	# rear wall: breaker panel, pinned route map, notes, first-aid box, coat
	mb.box("panel_dk", Vector3(-0.95, F + 1.5, 3.355), Vector3(0.62, 0.72, 0.03))
	for r in 4:
		for c in 8:
			mb.box("red" if (r * 3 + c) % 7 == 0 else "hull_blk", Vector3(-1.2 + float(c) * 0.07, F + 1.24 + float(r) * 0.17, 3.335), Vector3(0.03, 0.08, 0.02))
			mb.box("led_green" if (r + c) % 5 != 0 else "led_amber", Vector3(-1.2 + float(c) * 0.07, F + 1.31 + float(r) * 0.17, 3.337), Vector3(0.012, 0.012, 0.006))
	mb.box("white_paint", Vector3(0.95, F + 1.55, 3.36), Vector3(0.66, 0.5, 0.012))
	mb.box("amber_paint", Vector3(0.95, F + 1.55, 3.352), Vector3(0.56, 0.012, 0.004))
	for k in 10:
		mb.box("hull_blk" if k != 2 else "red", Vector3(0.69 + float(k) * 0.058, F + 1.55, 3.35), Vector3(0.018, 0.03, 0.004))
	Kit.text3d(n, Vector3(0.95, F + 1.72, 3.352), "NORTHERN LINE", 26, Color(0.1, 0.1, 0.12), PI, 0.0022)
	Kit.text3d(n, Vector3(0.95, F + 1.4, 3.352), "DO NOT STOP IN VOSTOK", 24, Color(0.62, 0.1, 0.08), PI, 0.0022)
	mb.box("white_paint", Vector3(0.5, F + 1.2, 3.362), Vector3(0.16, 0.2, 0.004), Basis(Vector3.BACK, 0.12))
	mb.box("white_paint", Vector3(-1.38, F + 1.0, 2.62), Vector3(0.1, 0.24, 0.3))
	mb.box("red", Vector3(-1.327, F + 1.0, 2.62), Vector3(0.004, 0.14, 0.04))
	mb.box("red", Vector3(-1.327, F + 1.0, 2.62), Vector3(0.004, 0.04, 0.14))
	mb.box("canvas", Vector3(1.33, F + 1.35, 3.12), Vector3(0.1, 0.72, 0.36))
	mb.box("steel", Vector3(1.38, F + 1.74, 3.12), Vector3(0.04, 0.03, 0.03))
	mb.box("wood", Vector3(-0.3, F + 0.99, 1.33), Vector3(0.11, 0.09, 0.012), Basis(Vector3.RIGHT, -0.25))
	mb.box("seat", Vector3(-0.3, F + 0.99, 1.337), Vector3(0.09, 0.07, 0.004), Basis(Vector3.RIGHT, -0.25))
	mb.cyl("white_paint", Vector3(0.62, F + 0.93, 1.74), 0.035, 0.08, 1, 8)
	mb.box("seat_dk", Vector3(0, F + 1.5, 2.86), Vector3(0.3, 0.2, 0.09), Basis(Vector3.RIGHT, 0.1))
	mb.cyl("rubber", Vector3(0, F + 0.3, 2.5), 0.11, 0.14, 1, 10)
	mb.box("hull_blk", Vector3(0.9, F + 0.08, 2.9), Vector3(0.34, 0.16, 0.5))
	mb.box("amber_paint", Vector3(0.9, F + 0.165, 2.9), Vector3(0.3, 0.012, 0.1))
	for k in 6:
		mb.box("grille", Vector3(-0.9 + float(k) * 0.36, F + 0.985, 1.22), Vector3(0.22, 0.012, 0.05))
	# exhaust, wheel spray, headlight beams
	exhaust = Kit.particles(n, Vector3(-0.6, CY + 0.75, 6.9), 22, 2.4, Color(0.1, 0.1, 0.11, 0.5), 1.2)
	exhaust.emitting = false
	for sgn: float in [-1.0, 1.0]:
		var sp: CPUParticles3D = Kit.particles(n, Vector3(sgn * 1.25, 0.25, 3.8), 24, 0.7, Color(0.92, 0.95, 1.0, 0.45), 0.55)
		sp.gravity = Vector3(0, -3.0, 0)
		sp.spread = 18.0
		sp.direction = Vector3(sgn * 0.35, 0.3, 1.0).normalized()
		sp.emitting = false
		sprays.append(sp)
		var sk: CPUParticles3D = Kit.particles(n, Vector3(sgn * 0.78, 0.24, 4.3), 10, 0.32, Color(1.0, 0.72, 0.3, 1.0), 0.035, true)
		sk.gravity = Vector3(0, -6.0, 0)
		sk.spread = 16.0
		sk.direction = Vector3(sgn * 0.25, 0.22, 1.0).normalized()
		sk.emitting = false
		sparks.append(sk)
		mb.box("steel_dk", Vector3(sgn * 0.68, 1.06, 0.045), Vector3(0.18, 0.13, 0.05))
		mb.cyl("ditch_a" if sgn < 0.0 else "ditch_b", Vector3(sgn * 0.68, 1.06, 0.017), 0.05, 0.012, 2, 10)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sgn: float in [-1.0, 1.0]:
		var o := Vector3(sgn * 1.02, 1.72, -0.1)
		var e: Vector3 = o + Vector3(sgn * 1.0, -1.2, -44.0)
		var quads: Array = [[o + Vector3(-0.16, 0, 0), o + Vector3(0.16, 0, 0), e + Vector3(4.4, 0, 0), e + Vector3(-4.4, 0, 0)], [o + Vector3(0, -0.1, 0), o + Vector3(0, 0.1, 0), e + Vector3(0, 2.8, 0), e + Vector3(0, -1.0, 0)]]
		var uvs: Array = [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)]
		for q: Array in quads:
			for i: int in [0, 1, 2, 0, 2, 3]:
				var pv: Vector3 = q[i]
				var uv: Vector2 = uvs[i]
				st.set_uv(uv)
				st.set_normal(Vector3.UP)
				st.add_vertex(pv)
	var g2 := Gradient.new()
	g2.offsets = PackedFloat32Array([0.0, 0.06, 1.0])
	g2.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var gt := GradientTexture1D.new()
	gt.gradient = g2
	gt.width = 64
	beam_mat = StandardMaterial3D.new()
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam_mat.albedo_texture = gt
	beam_mat.albedo_color = Color(0.8, 0.9, 1.0, 0.0)
	beams = MeshInstance3D.new()
	beams.mesh = st.commit()
	beams.material_override = beam_mat
	beams.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beams.visible = false
	n.add_child(beams)

func _animate(dt: float, v: float, hl: bool, loc_name: String, dist: float, at_stop: bool) -> void:
	var t: Dictionary = GS.train
	anim_t += dt
	var acc: float = (v - prev_v) / maxf(dt, 0.001)
	prev_v = v
	acc_s = lerpf(acc_s, clampf(acc, -4.0, 4.0), clampf(dt * 3.0, 0.0, 1.0))
	var vf: float = clampf(v / 22.0, 0.0, 1.0)
	joint_d += v * dt
	if joint_d > 12.5:
		joint_d -= 12.5
		joint_kick = 1.0
	joint_kick = maxf(0.0, joint_kick - dt * 9.0)
	if strap_mmi != null:
		var mm: MultiMesh = strap_mmi.multimesh
		for i in strap_pts.size():
			var sp: Vector3 = strap_pts[i]
			var ax: float = clampf(-acc_s * 0.1, -0.5, 0.5) + sin(anim_t * 3.3 + float(i) * 1.7) * 0.03 * vf
			var az: float = sin(anim_t * 1.9 + float(i) * 0.9) * 0.1 * vf + joint_kick * 0.06 * sin(float(i) * 2.3)
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.RIGHT, ax) * Basis(Vector3.BACK, az), sp))
	var keep_d: Array = []
	for dg: Array in danglers:
		if is_instance_valid(dg[0]):
			var dn2: Node3D = dg[0]
			var ph: float = dg[1]
			dn2.rotation.x = clampf(-acc_s * 0.085, -0.45, 0.45) + sin(anim_t * 2.9 + ph) * 0.035 * vf
			dn2.rotation.z = sin(anim_t * 1.7 + ph) * 0.08 * vf + joint_kick * 0.06 * sin(ph * 3.0)
			keep_d.append(dg)
	danglers = keep_d
	var thr: float = t["throttle"]
	for nd: Array in needles:
		var node: Node3D = nd[0]
		var f := 0.0
		match str(nd[1]):
			"speed": f = v * 3.6 / 140.0
			"brake": f = float(t["brake"])
			"rpm": f = (0.2 + 0.7 * thr + sin(anim_t * 23.0) * 0.012) if t["engine_on"] else 0.0
			"volt": f = float(t["battery"]) / GS.bat_cap()
		node.rotation.z = lerp_angle(node.rotation.z, lerpf(2.2, -2.2, clampf(f, 0.0, 1.0)), clampf(dt * 5.0, 0.0, 1.0))
	disp_t -= dt
	if disp_t <= 0.0 and not disp_freeze:
		disp_t = 0.17
		disp_i += 1
		var msg: String = "   THIS STATION IS  %s   -   MIND THE GAP   -" % loc_name.to_upper()
		if not at_stop:
			msg = "   NEXT STOP  %s   -   %d M   -   NORTHERN LINE 4071   -" % [loc_name.to_upper(), int(dist)]
		var off: int = disp_i % msg.length()
		var shown: String = (msg + msg).substr(off, 26) if (t["lights"] and GS.power_ok) else ""
		for dl: Label3D in displays:
			if is_instance_valid(dl):
				dl.text = shown
	if exhaust != null:
		exhaust.emitting = t["engine_on"]
		var ev := Vector3(0.0, 2.2 + 2.4 * thr, 0.5 + v * 0.9)
		exhaust.direction = ev.normalized()
		exhaust.initial_velocity_min = ev.length() * 0.8
		exhaust.initial_velocity_max = ev.length() * 1.2
	for sp2: CPUParticles3D in sprays:
		sp2.emitting = v > 5.0
		sp2.initial_velocity_min = v * 0.35
		sp2.initial_velocity_max = v * 0.6
	var brk: float = t["brake"]
	for sk2: CPUParticles3D in sparks:
		sk2.emitting = brk > 0.5 and v > 4.0
		sk2.initial_velocity_min = 1.0 + v * 0.2
		sk2.initial_velocity_max = 2.0 + v * 0.4
	var warm: bool = t["heating"] and GS.power_ok and v < 3.0
	var keep_v: Array = []
	for vn2: Variant in vents:
		if is_instance_valid(vn2):
			var vp: CPUParticles3D = vn2
			vp.emitting = warm
			keep_v.append(vn2)
	vents = keep_v
	var keep_s: Array = []
	for se: Array in stacks:
		if is_instance_valid(se[0]):
			var spt: CPUParticles3D = se[0]
			var on2: bool = (t["gen_on"] and float(t["diesel"]) > 0.0) if str(se[1]) == "gen" else GS.power_ok
			spt.emitting = on2
			var sv2 := Vector3(0.0, 1.5, 0.3 + v * 0.9)
			spt.direction = sv2.normalized()
			spt.initial_velocity_min = sv2.length() * 0.8
			spt.initial_velocity_max = sv2.length() * 1.2
			keep_s.append(se)
	stacks = keep_s
	if beams != null:
		var wx: float = 0.0
		if GS.weather == "snow":
			wx = 0.5
		elif GS.weather == "blizzard":
			wx = 1.0
		var target: float = (0.1 + 0.14 * wx) if hl else 0.0
		beam_mat.albedo_color.a = lerpf(beam_mat.albedo_color.a, target, clampf(dt * 6.0, 0.0, 1.0))
		beams.visible = beam_mat.albedo_color.a > 0.004

func _lever(parent: Node3D, pos: Vector3, mat: String) -> Node3D:
	var piv := Node3D.new()
	piv.position = pos
	parent.add_child(piv)
	var mb := Kit.new()
	mb.cyl("steel", Vector3(0, 0.12, 0), 0.016, 0.24, 1, 6)
	mb.box(mat, Vector3(0, 0.26, 0), Vector3(0.08, 0.05, 0.05))
	mb.commit(piv, false)
	return piv

# ---------------- simulation ----------------
func simulate(dt: float, aboard: bool) -> void:
	var t: Dictionary = GS.train
	var v: float = t["speed"]
	var s: float = t["s"]
	var thr: float = t["throttle"]
	var brk: float = t["brake"]
	var eng_c: float = float(GS.loco["engine"]) / 100.0
	var brk_c: float = float(GS.loco["brakes"]) / 100.0
	var vmax: float = minf(33.0 * (0.4 + 0.6 * eng_c), GS.speed_limit)
	if t["autopilot"]:
		var dist: float = float(t["ap_target"]) - s
		var vdes: float = minf(minf(26.0, vmax), sqrt(maxf(0.0, 2.0 * 0.8 * (dist - 0.3))))
		if dist < 0.5 and v < 0.6:
			t["autopilot"] = false
			thr = 0.0
			brk = 1.0
			GS.say("Autopilot: arrived. Brakes applied.", "good")
		elif v < vdes - 0.4:
			thr = clampf((vdes - v) * 0.35, 0.25, 1.0)
			brk = 0.0
		elif v > vdes + 0.3:
			thr = 0.0
			brk = clampf((v - vdes) * 0.45, 0.08, 1.0)
		else:
			thr = 0.12
			brk = 0.0
	var thr_e: float = thr
	var brk_e: float = brk
	if not t["engine_on"] or t["doors_open"]:
		thr_e = 0.0
	if not aboard:
		thr_e = 0.0
		brk_e = 1.0
	var acc: float = thr_e * 1.7 * (0.5 + 0.5 * eng_c) * maxf(0.0, 1.0 - v / vmax)
	var dec: float = brk_e * 2.6 * (0.35 + 0.65 * brk_c) + 0.006 * v + (0.03 if v > 0.0 else 0.0)
	v = maxf(0.0, v + (acc - dec) * dt)
	s += v * dt
	GS.stats["distance"] = float(GS.stats["distance"]) + v * dt
	var k: int = int(round(s / GS.SP))
	if str(GS.events.get(str(k), "")) in ["blocked", "gate"]:
		var lim: float = float(k) * GS.SP + 18.0
		if s > lim:
			s = lim
			if v > 3.0:
				collided = v
			v = 0.0
			thr = 0.0
			t["autopilot"] = false
	t["speed"] = v
	t["s"] = s
	t["throttle"] = thr
	t["brake"] = brk

## True where a station platform stands beside the train at this z (train space).
func platform_at(z: float) -> bool:
	var s: float = GS.train["s"]
	var k0: int = int(round(s / GS.SP))
	for k: int in [k0, k0 + 1]:
		if k < 0:
			continue
		var lz: float = z - (s - float(k) * GS.SP)
		if lz > -21.0 and lz < 199.0:
			return true
	return false

## Where a jump from beside the stopped train should land: [floor height, door centre z] of the
## nearest open doorway within reach, or [] when there is none.
func board_target(pos: Vector3) -> Array:
	if float(GS.train["speed"]) > 0.5 or door_t < 0.6:
		return []
	var ax: float = absf(pos.x)
	if ax < 1.4 or ax > 4.2 or pos.y > FY - 0.25 or pos.y < -1.2:
		return []
	for d: Dictionary in doors:
		var ds: float = d["side"]
		if ds * pos.x < 0.0:
			continue
		var car: Node3D = d["car"]
		var dz: float = car.position.z + 1.25
		if absf(pos.z - dz) < 2.2:
			return [FY, dz, ds]
	return []

func door_beside(pos: Vector3) -> bool:
	var ax: float = absf(pos.x)
	if ax < 1.4 or ax > 4.2 or pos.y > FY - 0.25:
		return false
	for d: Dictionary in doors:
		var car: Node3D = d["car"]
		if absf(pos.z - (car.position.z + 1.25)) < 2.2:
			return true
	return false

func steps_out() -> int:
	var n := 0
	for d: Dictionary in doors:
		if float(d["t"]) > 0.92:
			n += 1
	return n

func engage_autopilot() -> void:
	var t: Dictionary = GS.train
	var s: float = t["s"]
	var k: int = int(round(s / GS.SP))
	var target: float = float(k) * GS.SP
	if s > target - 4.0:
		target = float(k + 1) * GS.SP
	t["ap_target"] = target
	t["autopilot"] = true

# ---------------- visuals ----------------
func render(dt: float) -> void:
	var t: Dictionary = GS.train
	var v: float = t["speed"]
	for w: Node3D in wheels:
		w.rotate_x(-v / 0.46 * dt)
	door_t = move_toward(door_t, 1.0 if t["doors_open"] else 0.0, dt * 1.1)
	var ann: Array = [t["engine_on"], (not t["engine_on"]) or GS.kw_gen < GS.kw_load, float(t["brake"]) > 0.05, t["doors_open"], t["autopilot"], float(t["diesel"]) < 80.0, float(t["temp"]) < 8.0, GS.under_attack > 0.0 and fmod(flick, 0.5) < 0.25]
	for i in 8:
		var am: StandardMaterial3D = Kit.mats["ann_%d" % i]
		var lit: bool = ann[i]
		am.emission_energy_multiplier = (2.6 if lit else 0.04) if GS.power_ok else (0.5 if lit else 0.02)
	var dled: StandardMaterial3D = Kit.mats["door_led"]
	dled.emission_energy_multiplier = (3.6 if fmod(flick, 0.5) < 0.25 else 0.3) if (t["doors_open"] or door_t > 0.02) else 0.08
	var sm: float = smoothstep(0.0, 1.0, door_t)
	for d: Dictionary in doors:
		var dn: Node3D = d["node"]
		var dside: float = d["side"]
		dn.position = Vector3(dside * (1.47 + 0.09 * minf(1.0, door_t * 5.0)), 0, 1.25 + 1.32 * sm)
		var dc: CollisionShape3D = d["col"]
		dc.disabled = door_t > 0.35
		var car: Node3D = d["car"]
		var want: float = 1.0 if (t["doors_open"] and (dside < 0.0 or not platform_at(car.position.z + 1.25))) else 0.0
		var st: float = move_toward(float(d["t"]), want, dt * 1.3)
		d["t"] = st
		var sn: Node3D = d["steps"]
		sn.visible = st > 0.02
		if sn.visible:
			var e: float = smoothstep(0.0, 1.0, st)
			sn.scale = Vector3(maxf(e, 0.03), maxf(e, 0.03), 1.0)
		var rc: CollisionShape3D = d["ramp"]
		rc.disabled = st < 0.92
	if t["wipers"]:
		wipe_t += dt * 3.2
	for a: Node3D in wipers:
		var sg: float = a.get_meta("sgn")
		var target: float = sg * 1.2 if not t["wipers"] else sg * (0.15 + 0.55 * (0.5 + 0.5 * sin(wipe_t))) * 2.0 - sg * 0.2
		a.rotation.z = lerp_angle(a.rotation.z, target, clampf(dt * 10.0, 0.0, 1.0))
	thr_lever.rotation.x = lerpf(thr_lever.rotation.x, 0.55 - 1.1 * float(t["throttle"]), clampf(dt * 8.0, 0.0, 1.0))
	brk_lever.rotation.x = lerpf(brk_lever.rotation.x, 0.55 - 1.1 * float(t["brake"]), clampf(dt * 8.0, 0.0, 1.0))
	# power state -> interior lights
	flick += dt
	var e := 0.0
	if t["lights"] and GS.power_ok:
		e = 1.0
		if float(t["battery"]) < 8.0 and GS.kw_gen < GS.kw_load:
			e = 0.55 + 0.45 * (1.0 if sin(flick * 23.0) + sin(flick * 7.3) > -0.6 else 0.2)
	var emergency: bool = not GS.power_ok
	if emergency:
		e = 0.2
	for l: OmniLight3D in lamps:
		var be: float = l.get_meta("e")
		l.light_energy = be * e * (2.4 if low else 1.0)
		l.light_color = Color(1.0, 0.24, 0.14) if emergency else Color(1.0, 0.82, 0.6)
	var em: StandardMaterial3D = Kit.mats["emerg"]
	em.emission_energy_multiplier = lerpf(em.emission_energy_multiplier, 4.0 if emergency else 0.05, clampf(dt * 3.0, 0.0, 1.0))
	if emergency:
		e = 0.0
	# carriage sway and suspension bounce, felt as relative motion against the car you stand in
	var pz: float = main.player.global_position.z if main.player != null else 0.0
	var vfs: float = clampf(v / 20.0, 0.0, 1.0)
	var idx := 0
	for vn: Node3D in [loco_node] + veh:
		idx += 1
		if vn == null:
			continue
		var zc2: float = vn.position.z + 8.0
		var away: float = clampf(absf(pz - zc2) / 9.0 - 0.7, 0.0, 1.0)
		vn.rotation.z = (sin(anim_t * 1.25 + float(idx) * 1.9) * 0.005 + joint_kick * 0.003 * sin(float(idx) * 2.1)) * vfs * away
		vn.position.y = joint_kick * 0.007 * vfs * away * sin(float(idx) * 1.3 + 1.0)
	var lm: StandardMaterial3D = Kit.mats["light_warm"]
	lm.emission_energy_multiplier = 0.03 + 3.0 * e
	var hl: bool = t["headlights"]
	var rngm: float = 130.0 if int(GS.upgrades.get("lamps", 0)) > 0 else 75.0
	for sp: SpotLight3D in spots:
		sp.light_energy = lerpf(sp.light_energy, 7.0 if hl else 0.0, clampf(dt * 6.0, 0.0, 1.0))
		sp.spot_range = rngm
	var hm: StandardMaterial3D = Kit.mats["lamp_white"]
	hm.emission_energy_multiplier = 7.0 if hl else 0.25
	var horn: bool = main.horn_cd > 0.0
	var da: StandardMaterial3D = Kit.mats["ditch_a"]
	var db2: StandardMaterial3D = Kit.mats["ditch_b"]
	var alt: bool = fmod(flick, 0.36) < 0.18
	da.emission_energy_multiplier = (7.0 if alt else 0.2) if horn else (3.0 if hl else 0.1)
	db2.emission_energy_multiplier = (0.2 if alt else 7.0) if horn else (3.0 if hl else 0.1)
	# cab displays
	d_speed.text = "%d" % int(round(v * 3.6))
	var k: int = int(round(float(t["s"]) / GS.SP))
	var nxt: float = float(k) * GS.SP
	if float(t["s"]) > nxt + 4.0:
		k += 1
		nxt = float(k) * GS.SP
	var loc: Dictionary = GS.loc_at(k)
	d_stat.text = "ENG %s\nTHR %d%%  BRK %d%%\nAUTO %s" % ["RUN" if t["engine_on"] else "OFF", int(float(t["throttle"]) * 100.0), int(float(t["brake"]) * 100.0), "ON" if t["autopilot"] else "OFF"]
	d_info.text = "NEXT %dm\nDIESEL %dL\nBATT %dkWh" % [int(maxf(0.0, nxt - float(t["s"]))), int(t["diesel"]), int(t["battery"])]
	d_info.set_meta("loc", loc["name"])
	_animate(dt, v, hl, str(loc["name"]), maxf(0.0, nxt - float(t["s"])), v < 0.3 and absf(nxt - float(t["s"])) < 30.0)
