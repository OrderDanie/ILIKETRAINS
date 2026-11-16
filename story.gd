class_name Story
extends RefCounted
## THE NORTHLINE: the campaign. Chapters, objectives, discoveries, decisions and their consequences.
## Every piece of state lives in GS.story, so it is saved with the game and drives the objective
## screen, the map and the ending directly. Nothing in here is decorative text.

const MERIDIAN := {"name": "Meridian Central", "kind": "Traffic control", "car": "", "infected": 0, "loot": ["food", "water"]}
const CHAPTERS := [["PROLOGUE", "The Last Departure"], ["CHAPTER I", "The Signal"], ["CHAPTER II", "The Dead Junction"], ["CHAPTER III", "The Long Crossing"], ["CHAPTER IV", "The Quiet City"], ["CHAPTER V", "The Last Signal"], ["EPILOGUE", "The Northline"]]
const DISC := {
	"signal": ["The Meridian transmission", "A repeating call on the old railway band, signed MERIDIAN CENTRAL. It says Corridor Seven is recoverable, that three interlockings are dark, and that they are still there. Meridian Central is on none of your maps."],
	"timetable": ["Working timetable, Northline", "Found in the Karsk dispatch office. Corridor Seven leaves the main line at Greywater Halt and ends at MERIDIAN CENTRAL. It is not a town. It is the traffic control centre for the whole Northline: the room every signal on this railway answers to. Someone has pencilled CLOSED across the page."],
	"relay": ["The Karsk relay recording", "Through the depot relay the call comes clean. The dark interlockings have names: Haven Junction, the Varda crossing, the Greywater points. And under the Meridian carrier a second, weaker voice answers from Vostok: a woman reading out a stock list of medicines to nobody."],
	"workers": ["The Ironworks gang book", "The last entries of the permanent-way gang. They pulled the interlocking relays out of Haven Junction themselves, so that no more trains could carry the sickness south. 'Better a dead junction than a dead town.' The relays are under the cold-store floor at Depot 9."],
	"relays": ["Interlocking relays", "A crate chalked HAVEN JCN - DO NOT REFIT. Twelve relays, greased and wrapped. With these the Haven lever frame will work again."],
	"varda_orders": ["Fort Varda's standing orders", "A typed sheet under glass: HOLD THE VARDA CROSSING CLOSED UNTIL RECALLED BY MERIDIAN CENTRAL. Below it, a tally of days in pencil. It runs to four hundred and stops, as if the hand that kept it had lost the argument for counting."],
	"harbour_log": ["Harbour master's log, Kaldwick", "No ship ever came. The city emptied by rail instead: eleven convoys in nine days, every one of them routed to Meridian Central. The last line reads: 'Convoy 11 away 02:10. Told them Meridian will take everyone. God forgive me if it will not.'"],
	"recording": ["The transmission is a recording", "The platform logger has written down the Meridian call every hour, on the hour. It has not changed by one syllable in 412 days. The same breath in the same place. Nobody has been speaking. You have been following a tape."],
	"ivo": ["What Ivo Brandt knew", "Ivo was a gate officer at Meridian Central. When the convoys kept coming, Meridian shut its gates on them, and he was the one who closed them."],
	"meridian": ["Meridian Central", "Thirty-one people, a well, four glasshouses and a control room that can still set every signal on the Northline. The dispatcher whose voice you followed recorded the call a week before she died. They left it running."],
	"suitcase": ["A child's suitcase", "Left on the Nordhaven platform, never collected. The label is written in a careful adult hand: ANJA, AGE 7 - TO MERIDIAN CENTRAL - CONVOY 3. Whoever wrote it believed there was somewhere to arrive."],
	"convoy9": ["Guard's journal, Convoy 9", "The abandoned wagons are what is left of the ninth evacuation convoy. The guard's journal ends mid-page: 'Signals against us at Haven. Junction dead. Nobody will say who killed it. We are going to walk.'"],
	"voices": ["Other voices", "From the top band of the Varda mast you can hear what the train radio cannot: three more carriers, faint and far apart, each one a single voice reading out a place name and a number of people. Meridian was never the only one calling. It was only the loudest."],
}
const LABELS := {
	"c1_desk": "Search the dispatch desk", "c1_relay": "Power up the depot relay", "c1_stock": "The pharmacy stockroom",
	"c2_book": "Read the gang book", "c2_relays": "Open the crate under the floor", "c2_frame": "Haven Junction lever frame",
	"c3_orders": "Read the standing orders", "c3_light": "Cape light control panel",
	"c4_log": "Read the harbour master's log", "c4_rec": "Platform signal logger", "c4_people": "Speak to Maren Olsen",
	"c5_points": "Greywater ground frame: Corridor Seven points", "c5_edda": "Speak to the stationmaster", "c5_tx": "The transmitter",
	"s_suitcase": "Look at the suitcase", "s_van": "Read the guard's journal", "s_mast": "Listen on the mast transmitter",
}

const SIGHTS := {
	"crossing": ["A silent level crossing", "The lamps are still flashing for traffic that stopped coming."],
	"village": ["A quarantined village", "Curtains in some of those windows. I would rather not know."],
	"bridge": ["The lake bridge", "My father fished that lake. Through the ice, in a hut like a coffin."],
	"pylons": ["The dead substation", "All that copper, and not one volt in it."],
	"overbridge": ["The road bridge", "They were all driving south. Look how far they got."],
	"wagons": ["The abandoned convoy", "Do not slow down for that one."],
	"turbines": ["The wind farm", "Still turning. Nobody told them."],
	"mast": ["The Varda mast", "If that thing still has power, it can hear further than we can."],
	"tunnel": ["Karsk tunnel", "Hold your breath. We always did, as children."],
	"cutting": ["The rock cutting", "They blasted this by hand, a hundred years ago."],
	"herd": ["Reindeer on the move", "Look - look! They are racing us!"],
	"camp": ["A lineside camp", "People. Living people. Sound the horn for them."],
	"steamer": ["A steam special, left to rust", "She was the pride of this line once. Somebody still loves her - look at the brass."],
	"farm": ["A working farm", "Smoke from the chimney. Somebody is keeping that place."],
	"lake": ["Ice fishers on the lake", "One of those huts has a lamp in it."],
	"cooling": ["The Ironworks power station", "Steam. One of those towers is still warm. How?"],
	"airliner": ["The fallen airliner", "It came down the first week. Nobody ever came for it."],
	"hilltop": ["The observatory on the hill", "They say the astronomers stayed. They say they are still counting."],
	"dishes": ["The listening station", "Three ears pointed at the sky, and nobody to tell what they hear."],
	"gallery": ["The avalanche gallery", "Watch the light through the columns. I always liked this part."],
	"sawmill": ["The Karsk sawmill", "The burner is lit. Someone is cutting timber for a winter they expect to see."],
	"stacks": ["The sea stacks", "The Three Sisters. Sailors counted them going out and coming home."],
	"shipwreck": ["A freighter aground", "She tried to reach Kaldwick. Ran out of sea."],
	"rig": ["The offshore rig", "That flare has not gone out in two years. Nobody is tending it."],
	"pier": ["The fishing pier", "There is a lamp lit at the end of that pier."],
	"icefield": ["The ice field", "When that goes out in spring it sounds like artillery."],
}

static var nodes: Dictionary = {}
static var queue: Array = []
static var cur: Dictionary = {}
static var pending_ending := false

static func fresh() -> Dictionary:
	return {"ch": 0, "step": 0, "tk": -1, "mk": -1, "flags": {}, "found": [], "log": [], "done": [], "sights": []}

# ---------------- state helpers ----------------
static func fl(key: String, def: Variant = false) -> Variant:
	var fs: Dictionary = GS.story["flags"]
	return fs.get(key, def)

static func f(key: String) -> bool:
	var v: Variant = fl(key, false)
	return typeof(v) == TYPE_BOOL and bool(v)

static func setf(key: String, v: Variant = true) -> void:
	var fs: Dictionary = GS.story["flags"]
	fs[key] = v

static func has(id: String) -> bool:
	var fd: Array = GS.story["found"]
	return fd.has(id)

static func ch() -> int:
	return int(GS.story["ch"])

static func step() -> int:
	return int(GS.story["step"])

static func ahead(idx: int) -> int:
	var k0: int = int(ceil((float(GS.train["s"]) - 30.0) / GS.SP))
	return k0 + posmod(idx - k0, GS.NLOC)

static func is_meridian(k: int) -> bool:
	return k >= 0 and int(GS.story.get("mk", -1)) == k

static func knows_meridian() -> bool:
	return has("timetable") or ch() >= 5

static func crew(cname: String) -> Dictionary:
	for c: Dictionary in GS.crew:
		if str(c["name"]) == cname:
			return c
	return {}

static func aboard(cname: String) -> bool:
	return not crew(cname).is_empty()

static func morale(d: float) -> void:
	for c: Dictionary in GS.crew:
		c["morale"] = clampf(float(c["morale"]) + d, 0.0, 100.0)

static func trust(cname: String, d: float) -> void:
	var c: Dictionary = crew(cname)
	if not c.is_empty():
		c["trust"] = clampf(float(c.get("trust", 0.0)) + d, 0.0, 100.0)

static func note(text: String) -> void:
	var lg: Array = GS.story["log"]
	lg.append({"d": GS.day(), "c": ch(), "t": text})

static func complete(text: String) -> void:
	var dn: Array = GS.story["done"]
	if not dn.has(text):
		dn.append(text)

static func _goto(st: int, target_idx: int = -1) -> void:
	GS.story["step"] = st
	if target_idx >= 0:
		GS.story["tk"] = ahead(target_idx)

static func _passed(tk: int) -> bool:
	return float(GS.train["s"]) > float(tk) * GS.SP + 60.0

static func _use(id: String) -> void:
	setf("u_" + id)
	var a: Variant = nodes.get(id)
	if a != null and is_instance_valid(a):
		var an: Node = a
		if an.has_meta("tag"):
			var tg: Variant = an.get_meta("tag")
			if tg != null and is_instance_valid(tg):
				var tn: Node = tg
				tn.queue_free()

static func label(id: String) -> String:
	return str(LABELS.get(id, "Examine"))

## Something worth looking out of the window for, the first time the train passes it.
static func sight(m, type: String) -> void:
	if not SIGHTS.has(type):
		return
	var sg: Array = GS.story["sights"]
	if sg.has(type):
		return
	sg.append(type)
	var e: Array = SIGHTS[type]
	GS.say("Sighted: %s   (%d of %d)" % [e[0], sg.size(), SIGHTS.size()], "good")
	morale(1.0)
	if m.aboard and not m.crew_nodes.is_empty() and float(GS.train["speed"]) > 1.0:
		var ca: Variant = m.crew_nodes[randi() % m.crew_nodes.size()]
		if ca != null and is_instance_valid(ca):
			ca.say(str(e[1]))

# ---------------- dialogs ----------------
static func show(m, d: Dictionary) -> void:
	if m.ui.screen == "story":
		queue.append(d)
	else:
		cur = d
		m.ui.open_story()

static func closed(m) -> void:
	if not queue.is_empty():
		var d: Dictionary = queue.pop_front()
		cur = d
		m.ui.open_story()
	elif pending_ending:
		pending_ending = false
		m.ui.open("ending", 0)

static func _kick() -> String:
	var c: Array = CHAPTERS[clampi(ch(), 0, 6)]
	return "%s   -   %s" % [c[0], str(c[1]).to_upper()]

static func discover(m, id: String) -> void:
	var first: bool = not has(id)
	if first:
		var fd: Array = GS.story["found"]
		fd.append(id)
		_use(id)
		m.sfx.play("bell", -6.0)
	var e: Array = DISC[id]
	show(m, {"id": "disc", "kicker": "DISCOVERY" if first else "DISCOVERY  -  ALREADY RECORDED", "title": str(e[0]).to_upper(), "body": [e[1]], "options": []})

static func _start(m, c: int) -> void:
	complete("%s - %s" % [CHAPTERS[ch()][0], CHAPTERS[ch()][1]])
	GS.story["ch"] = c
	GS.story["step"] = 0
	var t: Array = CHAPTERS[c]
	m.ui.title_card(str(t[1]), str(t[0]))
	m.sfx.play("bell", -3.0, 0.7)
	match c:
		1:
			_goto(0, 1)
		2:
			_goto(0, 3)
			setf("k_haven", ahead(5))
			GS.events[str(ahead(5))] = "gate"
			GS.radio("...Meridian Central. Corridor Seven is recoverable. Haven Junction is dark and set against the main line. We cannot reach it...")
		3:
			_goto(0, 6)
			setf("k_varda", ahead(6))
			GS.events[str(ahead(6))] = "blocked"
			GS.radio("...the Varda crossing is closed by order. We cannot raise the garrison. If you have a train...")
		4:
			_goto(0)
			GS.story["tk"] = int(round(float(GS.train["s"]) / GS.SP))
		5:
			_goto(0, 9)
			GS.events[str(ahead(9))] = "gate"
			GS.radio("...Corridor Seven is rec- ...the Greywater points are... we are st- ...")
	m.save_game(0)

# ---------------- per-tick progression ----------------
static func tick(m) -> void:
	var s: float = GS.train["s"]
	var tk: int = int(GS.story["tk"])
	var at: bool = m.at_stop == tk
	match ch():
		0:
			if GS.objective >= 5 and s > 250.0 and m.ui.screen == "":
				show(m, {"id": "transmission", "kicker": "RAILWAY BAND   -   REPEATING", "title": "INCOMING TRANSMISSION", "body": [
					"The cab radio, dead since Nordhaven, wakes on the old railway band.",
					"\"...is Meridian Central. Repeat: this is Meridian Central. We are still operating. Corridor Seven is recoverable. Three interlockings are dark and we cannot reach them. If you have a train - if anyone still has a train - bring it. We are still here. We are st-\"",
					"Static. Then the same voice, from the beginning, word for word.",
					"Mara has stopped working to listen. Nobody aboard has heard another station in over a year. Meridian Central is on none of your maps - but Karsk Maintenance Depot, the next stop, had a dispatch office, and dispatch offices keep records."], "options": []})
		1:
			match step():
				0:
					if at:
						_goto(1)
					elif _passed(tk):
						_goto(2, 2)
				1:
					if has("timetable") and has("relay"):
						GS.say("Karsk has told you what it can. The second voice came from Vostok Central.", "good")
						_goto(2, 2)
					elif _passed(tk):
						_goto(2, 2)
				2:
					if at:
						_goto(3)
					elif _passed(tk):
						setf("vostok", "passed")
						_start(m, 2)
				3:
					if _passed(tk):
						setf("vostok", "passed")
						note("Vostok Central: you passed through without stopping at the pharmacy.")
						_start(m, 2)
		2:
			# the junction is the objective wherever the chapter began: if the optional stops are
			# already behind the train, or Haven is close, go straight to it
			var kh: int = int(fl("k_haven", tk))
			if step() < 2 and (tk > kh or s > float(kh) * GS.SP - 420.0):
				GS.story["step"] = 2
				GS.story["tk"] = kh
				tk = kh
				at = m.at_stop == kh
			match step():
				0:
					if has("workers") or _passed(tk):
						_goto(1, 4)
				1:
					if f("relays") or _passed(tk):
						_goto(2, 5)
				2:
					if at:
						_goto(3)
						GS.weather = "blizzard"
						GS.weather_t = 260.0
						show(m, {"id": "info", "kicker": _kick(), "title": "SIGNAL AT DANGER", "body": [
							"The train stops itself. Across the south line a barrier is down and bolted, and the junction signal above it shows a single red lamp that has been burning, by the look of the snow on its hood, for a very long time.",
							"Haven Junction is a town built on a railway that somebody deliberately broke. Smoke rises from forty chimneys. A storm is coming in behind you; nothing is leaving here tonight until the lever frame at the south end of the yard works again.",
							"Odile, the quartermaster, watches you from her stall without coming closer."], "options": []})
		3:
			match step():
				0:
					if at:
						_goto(1)
						_hail(m)
				1:
					if not GS.events.has(str(tk)):
						if not f("varda_peace"):
							note("Fort Varda: you cleared the crossing by hand, under their guns.")
							morale(4.0)
						complete("The Varda crossing is open")
						_goto(2, 7)
				2:
					if at:
						_goto(3)
						GS.radio("Cape Halt. The causeway to Kaldwick runs along the sea wall from here. The Cape light is dark and the glass is falling.")
					elif _passed(tk):
						_storm(m)
				3:
					if _passed(tk):
						_storm(m)
				4:
					if str(fl("light", "dark")) == "dark" and float(GS.train["speed"]) > 1.0:
						GS.speed_limit = 9.0
						GS.damage_hull(0.35)
					if at:
						complete("Crossed the Kaldwick causeway")
						if str(fl("light", "dark")) == "dark":
							GS.say("Across. The sea took its share of the hull on the way.", "warn")
						else:
							GS.say("Across. The Cape light is still turning behind you.", "good")
						_start(m, 4)
		4:
			match step():
				0:
					if has("recording") and fl("truth", "") != "":
						_goto(1)
					elif _passed(tk) and m.ui.screen == "":
						_reveal(m, true)
				1:
					if _passed(tk):
						if fl("harbour", "") == "":
							setf("harbour", "left")
							note("Kaldwick: you left the people in the freighter without a word.")
						_start(m, 5)
		5:
			match step():
				0:
					var k9: int = ahead(9)
					if not GS.events.has(str(k9)) and float(k9) * GS.SP - s > 500.0:
						GS.events[str(k9)] = "gate"
						GS.story["tk"] = k9
					if at:
						_goto(1)
						GS.radio("...Meridian Cent- ...still op- ...Corridor Sev- ...")
				2:
					var mk: int = int(GS.story["mk"])
					if not f("silence") and s > float(mk - 1) * GS.SP + 320.0:
						setf("silence")
						GS.weather = "clear"
						GS.weather_t = 600.0
						GS.radio("The transmission stops in the middle of a word. Nothing replaces it. For the first time since Karsk, the railway band is silent.")
						morale(-3.0)
					if m.at_stop == mk:
						_goto(3)
						if not has("meridian"):
							var fd: Array = GS.story["found"]
							fd.append("meridian")
						show(m, {"id": "info", "kicker": _kick(), "title": "MERIDIAN CENTRAL", "body": [
							"The platform lamps are lit. All of them.",
							"There is no city. There is a marshalling yard under snow, a brick control tower with one bright window, four long glasshouses glowing pink in the dark, and washing on a line between two signal posts.",
							"A woman in a railway greatcoat stands at the platform end holding a green flag, as though the 21:40 from Nordhaven were merely late."], "options": []})
	# passenger stories that resolve by themselves
	if not f("mara_done") and GS.recruited.has("fixed9"):
		setf("mara_done")
		if aboard("Mara Lindqvist"):
			setf("mara_reunited")
			trust("Mara Lindqvist", 25.0)
			var mc: Dictionary = crew("Mara Lindqvist")
			mc["morale"] = minf(100.0, float(mc["morale"]) + 25.0)
			var jc: Dictionary = crew("Jonas Berg")
			if not jc.is_empty():
				var mr: Dictionary = mc["rel"]
				mr["Jonas Berg"] = 60.0
				var jr: Dictionary = jc["rel"]
				jr["Mara Lindqvist"] = 60.0
			note("Greywater: Mara Lindqvist found her brother Jonas alive.")
			GS.say("Mara has not let go of her brother's sleeve since Greywater.", "good")

static func _storm(m) -> void:
	_goto(4, 8)
	if fl("light", "") == "":
		setf("light", "dark")
		note("Cape Halt: you left the Cape light dark and crossed blind.")
	GS.weather = "blizzard"
	GS.weather_t = 240.0
	if str(fl("light")) == "dark":
		GS.speed_limit = 9.0
		GS.radio("The storm breaks over the causeway. No light, no signals: the sea is coming over the wall. Thirty kilometres an hour and pray.")
		morale(-4.0)
	else:
		GS.radio("The storm breaks over the causeway - and behind you the Cape light swings out across the water. Every signal to Kaldwick is readable.")

static func _hail(m) -> void:
	var can_toll: bool = float(GS.train["diesel"]) >= 100.0 and GS.can_afford({"ammo": 20})
	show(m, {"id": "c3_hail", "kicker": _kick(), "title": "FORT VARDA HAILS THE TRAIN", "speaker": "Captain Viktor Hale, Varda garrison", "body": [
		"\"Northline train, you are standing in a closed corridor. My orders are to hold the Varda crossing shut until Meridian Central recalls this garrison. The cutting ahead of you is blown. Nothing goes through.\"",
		"A long pause on the open channel. Wind across a microphone.",
		"\"Nothing has come through in four hundred days. State your business.\""], "options": [
		["Play him the Karsk relay recording and read him the timetable", "Needs the Karsk records. He has been waiting for word from Meridian as long as you have been looking for it.", has("relay") or has("timetable")],
		["Offer a toll: 60 litres of diesel and 20 rounds of 9 mm", "His sappers clear the line. Costs fuel you may want for the causeway." if can_toll else "Needs 100 L in the tank and 20 rounds.", can_toll],
		["Tell him nothing. You will clear the line yourselves.", "The garrison will fire on a stopped train and on anyone outside it. Needs a Tool Kit and an hour at the rubble.", true]]})

static func _reveal(m, en_route: bool) -> void:
	if not has("recording"):
		var fd: Array = GS.story["found"]
		fd.append("recording")
		_use("c4_rec")
	if not has("ivo"):
		var fd2: Array = GS.story["found"]
		fd2.append("ivo")
	var body: Array = []
	if en_route:
		body.append("Kaldwick is falling behind when the cab radio does something it has never done: the Meridian call ends, and begins again, and you find you can speak every word of it a half-second ahead of the voice. The same breath in the same place. It is a recording.")
	if aboard("Ivo Brandt"):
		body.append("Ivo Brandt has been standing behind you for some time.")
		body.append("\"I know that tape. I was there the week she made it. I was gate officer at Meridian Central. The convoys kept coming - eleven of them, more people than that yard could feed in a week - so the order came down, and I closed the gates. I closed them on a train from Vostok with its heating gone.\"")
		body.append("He looks at the logger, not at you. \"I don't know who is left inside. I let you all believe in a city because a train needs somewhere to be going.\"")
		if aboard("Lena Voss"):
			body.append("Lena Voss was on the train from Vostok.")
	else:
		body.append("In Ivo Brandt's kit you find a gate officer's warrant card, stamped MERIDIAN CENTRAL, and a page torn from a duty book: 'Gates closed 02:40 by order. Convoy 11 outside. I closed them.' He carried it the whole way and told nobody.")
	show(m, {"id": "c4_ivo", "kicker": _kick(), "title": "WHAT IVO BRANDT KNEW", "body": body, "options": [
		["Tell the whole train, tonight", "They will take it hard now. They will not be lied to when they arrive.", true],
		["Keep it between you until Meridian", "The train keeps its hope a little longer. Someone will have to answer for that at the gates.", true]]})

# ---------------- interaction with story objects ----------------
static func interact(m, id: String) -> void:
	match id:
		"c1_desk":
			discover(m, "timetable")
		"c1_relay":
			if not has("relay"):
				GS.radio("...forty doses of amoxicillin, expiry next spring. Twelve of morphine. This is Lena Voss at the Vostok pharmacy, and this is the list, in case anyone is writing it down...")
			discover(m, "relay")
		"c1_stock":
			if fl("vostok", "") != "":
				GS.say("The stockroom has been dealt with. Lena has stopped looking at the door.")
				return
			var body: Array = ["Forty sealed crates: antibiotics, dressings, insulin long since gone warm. Lena Voss has guarded this room for a year.", "\"There are still people in this city. They come at night, one at a time, and I give them what they need and they go. If you empty this room, they have nothing. If you leave it, you have nothing. I have stopped being able to decide.\""]
			if aboard("Tomas Reyes"):
				body.append("Tomas Reyes says, quietly, that he has already buried two people this winter for want of what is in those crates. Then he says he would bury them again before he took it from strangers. Then he says he does not know.")
			show(m, {"id": "c1_stock", "kicker": _kick(), "title": "THE PHARMACY STOCKROOM", "speaker": "Lena Voss, nurse", "body": body, "options": [
				["Take what the train needs. Leave the rest where they can find it.", "+4 Medical Supplies. The city keeps its pharmacy.", true],
				["Load all of it. The train is the only thing still moving.", "+10 Medical Supplies. Whoever comes to this door tonight finds it empty.", true],
				["Leave it all. Chalk the door so they know it is safe.", "Nothing for the train. Everything for the people you will never meet.", true]]})
		"c2_book":
			discover(m, "workers")
		"c2_relays":
			if not f("relays"):
				setf("relays")
			discover(m, "relays")
		"c2_frame":
			if fl("junction", "") != "":
				GS.say("The frame is working. The south line is yours.")
				return
			var pay: Dictionary = {"food": 6, "water": 4}
			show(m, {"id": "c2_frame", "kicker": _kick(), "title": "THE HAVEN LEVER FRAME", "body": [
				"Twenty-four levers in a rusted row, and behind them an empty relay rack with the fixing bolts still in it. Nobody wrecked this. Somebody who knew exactly what they were doing took it apart carefully and carried the pieces away.",
				"The points for the south line are locked against you. There are three ways to move them."], "options": [
				["Refit the interlocking relays from Depot 9", "The junction works as it was built to." if f("relays") else "You do not have the relays. The Ironworks gang book says where they were hidden.", f("relays")],
				["Have Sami Qureshi bridge the frame by hand", "He drew this interlocking. It will hold." if aboard("Sami Qureshi") else "Sami Qureshi, the engineer on the platform, must be aboard first.", aboard("Sami Qureshi")],
				["Pay the Haven council to bar the points over by hand", "6 Canned Food, 4 Clean Water. It will work once." if GS.can_afford(pay) else "Needs 6 Canned Food and 4 Clean Water.", GS.can_afford(pay)]]})
		"c3_orders":
			discover(m, "varda_orders")
		"c3_light":
			if fl("light", "") != "":
				GS.say("The decision about the Cape light is made.")
				return
			var niko_free: bool = not GS.recruited.has("fixed7")
			show(m, {"id": "c3_light", "kicker": _kick(), "title": "THE CAPE LIGHT", "speaker": "Niko Aalto, keeper's son" if niko_free else "", "body": [
				"The causeway to Kaldwick runs four kilometres along the sea wall. Its signals were never wired: drivers read them by the sweep of the Cape light, and the Cape light has been dark since the grid failed.",
				"Out over the water the sky has gone the colour of slate. The storm will reach the wall before you are half way across."], "options": [
				["Wire one of the train's battery cells into the lamp", "Costs 1 Battery Cell and its 15 kWh. The light runs all night." if GS.can_afford({"batteries": 1}) else "Needs 1 Battery Cell.", GS.can_afford({"batteries": 1})],
				["Ask Niko Aalto to crank the standby set until you are across", "He stays behind with the light. He cannot come with you." if niko_free else "Niko is already aboard.", niko_free],
				["Leave it dark. Crawl the causeway on dead reckoning.", "30 km/h in the storm, and the sea over the wall will wear the hull.", true]]})
		"c4_log":
			discover(m, "harbour_log")
		"c4_rec":
			if has("recording"):
				discover(m, "recording")
				return
			discover(m, "recording")
			_reveal(m, false)
		"c4_people":
			if fl("harbour", "") != "":
				GS.say("Maren Olsen nods. There is nothing more to say.")
				return
			var free_b: int = GS.crew_cap() - GS.crew.size()
			var feed: Dictionary = {"food": 6, "water": 6}
			show(m, {"id": "c4_people", "kicker": _kick(), "title": "THE PEOPLE IN THE FREIGHTER", "speaker": "Maren Olsen", "body": [
				"Nine people have been living in the hold of the grounded freighter. They heard your horn.",
				"\"We are not asking for all of us. Two of ours cannot walk the winter out. Take them, or leave us what you can spare, or go. We were told once that somewhere would take everyone. We know what being left looks like.\""], "options": [
				["Take the two aboard", "Two more mouths, two more pairs of hands." if free_b >= 2 else "Needs 2 free berths. Couple another Passenger carriage.", free_b >= 2],
				["Leave them food and water", "6 Canned Food, 6 Clean Water." if GS.can_afford(feed) else "Needs 6 Canned Food and 6 Clean Water.", GS.can_afford(feed)],
				["Tell them where Corridor Seven leaves the main line, and go", "Costs nothing. Promises nothing.", true]]})
		"c5_points":
			if ch() != 5:
				GS.say("The points are bolted and the lever will not move. Not yet.")
				return
			if step() >= 2:
				GS.say("The road is set for Corridor Seven.")
				return
			show(m, {"id": "c5_points", "kicker": _kick(), "title": "THE GREYWATER POINTS", "body": [
				"A ground frame of two levers under a tin hood. One blade of the points has not moved since the day somebody pencilled CLOSED across a timetable.",
				"Left: the main line, north, round again to Nordhaven. Right: Corridor Seven. The call from Meridian is breaking up badly now, more static than voice."], "options": [
				["Set the road for Corridor Seven", "The next stop will be Meridian Central.", true],
				["Stay on the main line for now", "The loop north. Greywater will still be here next time round.", true]]})
		"c5_edda":
			if step() < 3:
				return
			var body2: Array = [
				"\"Thirty-one of us. Four thousand came through those gates in nine days, and then the gates were shut, and then the sickness did everything the gates were meant to prevent. The woman whose voice you followed was our dispatcher. She recorded that call a week before she died, and we left it running, because switching it off felt like dying twice.\"",
				"She looks down the whole length of your train, slowly, the way a person reads a letter. \"We have glasshouses, a well, and a control room that can still set every signal on the Northline. What we have never had is a train.\""]
			if not f("edda_met"):
				setf("edda_met")
				if str(fl("truth", "")) == "kept":
					body2.append("She stops at Ivo Brandt. She knows him. Everybody on the platform sees that she knows him, and within a minute everybody on the platform knows why. Hanne Sorel says, to nobody: \"He knew. All the way down the line, he knew.\"")
					morale(-10.0)
					note("Meridian: the train learned at the gates what Ivo had kept from them.")
				elif str(fl("truth", "")) == "told":
					body2.append("Nobody on your train is surprised. They have known since Kaldwick what they were coming to, and they came anyway. Ivo Brandt steps down last, and Edda Stein holds out her hand to him first.")
					morale(6.0)
				if f("varda_dispatch"):
					body2.append("You hand her Captain Hale's dispatch. She reads it twice. \"Four hundred days. Tell him he is recalled. Tell him to open his crossing and come home.\"")
				if aboard("Lena Voss") and aboard("Ivo Brandt"):
					var lc: Dictionary = crew("Lena Voss")
					var lr: Dictionary = lc["rel"]
					lr["Ivo Brandt"] = 30.0 if str(fl("truth", "")) == "told" else -40.0
			body2.append("\"The control room is in the tower. The recorder is still turning. I think you had better be the one to decide what it says next.\"")
			show(m, {"id": "c5_edda", "kicker": _kick(), "title": "THE STATIONMASTER", "speaker": "Edda Stein, stationmaster", "body": body2, "options": []})
		"c5_tx":
			if ch() != 5 or step() < 4:
				GS.say("A reel-to-reel recorder, still turning. Speak to the stationmaster first.")
				return
			show(m, {"id": "c5_tx", "kicker": _kick(), "title": "THE LAST SIGNAL", "body": [
				"The recorder is still turning. One switch stops it. Whatever is said into this microphone next is what the Northline will hear - Haven, Varda, the people in the freighter, whoever is left in Vostok, and anyone else who still keeps a set switched on.",
				"What should people rebuild first?"], "options": [
				["A home.  \"Meridian Central is open. Come and stay.\"", "The train stops here. Its people become part of this place, and this place becomes somewhere.", true],
				["A line.  \"The Northline is running. We will come to you.\"", "The train keeps moving. Meridian sets the signals; you carry what the settlements need between them.", true],
				["The truth.  \"This is what is left, and this is what we need.\"", "No promise of a city. An honest count, broadcast live, and a request for anyone listening to answer.", true]]})
		"s_suitcase":
			discover(m, "suitcase")
		"s_van":
			discover(m, "convoy9")
		"s_mast":
			discover(m, "voices")

static func choose(m, i: int) -> void:
	var id: String = str(cur.get("id", ""))
	match id:
		"transmission":
			var fd: Array = GS.story["found"]
			if not fd.has("signal"):
				fd.append("signal")
				GS.say("The legs are long. Take a window seat in the passenger carriage and watch the line go by.")
			_start(m, 1)
		"c1_stock":
			if i == 0:
				GS.add(GS.store, "medicine", 4)
				setf("vostok", "share")
				note("Vostok: you took what the train needed and left the pharmacy for the city.")
				trust("Tomas Reyes", 10.0)
				morale(2.0)
			elif i == 1:
				GS.add(GS.store, "medicine", 10)
				setf("vostok", "take")
				note("Vostok: you emptied the pharmacy.")
				var tc: Dictionary = crew("Tomas Reyes")
				if not tc.is_empty():
					tc["morale"] = maxf(0.0, float(tc["morale"]) - 12.0)
			else:
				setf("vostok", "leave")
				note("Vostok: you left the pharmacy untouched and chalked the door.")
				trust("Tomas Reyes", 18.0)
				morale(5.0)
			_use("c1_stock")
			complete("Found the voice from Vostok")
			_start(m, 2)
		"c2_frame":
			if i == 0:
				setf("junction", "relays")
				note("Haven Junction: you refitted the relays the railway gang had hidden.")
			elif i == 1:
				setf("junction", "sami")
				trust("Sami Qureshi", 15.0)
				note("Haven Junction: Sami Qureshi bridged the frame by hand.")
			else:
				GS.pay({"food": 6, "water": 4})
				setf("junction", "paid")
				note("Haven Junction: you paid the council to bar the points over.")
			_use("c2_frame")
			m.sfx.play("clunk", 2.0, 0.6)
			var body: Array = ["The lever comes over with a sound like a rifle bolt. A hundred metres away the barrier lifts, and down the whole length of the yard, one after another, signals that have shown red for a year drop to green.", "People come out of the tents to look. Odile comes last.", "\"So you've opened the south. Trains mean people, and people mean sickness - that is why the gang killed this junction in the first place. If we are to be a station again and not a camp, we need to last the winter.\" She asks for one thing."]
			show(m, {"id": "c2_haven", "kicker": _kick(), "title": "WHAT HAVEN ASKS", "speaker": "Odile, quartermaster of Haven Junction", "body": body, "options": [
				["Leave them medicine", "3 Medical Supplies." if GS.can_afford({"medicine": 3}) else "Needs 3 Medical Supplies.", GS.can_afford({"medicine": 3})],
				["Leave them diesel for their generator", "40 litres from the tank." if float(GS.train["diesel"]) >= 90.0 else "Needs 90 L in the tank.", float(GS.train["diesel"]) >= 90.0],
				["Promise to carry their name to Meridian. Nothing more.", "Costs nothing today.", true],
				["Refuse. The train comes first.", "Odile will remember it.", true]]})
		"c2_haven":
			if i == 0:
				GS.pay({"medicine": 3})
				setf("haven", "medicine")
				setf("haven_ally")
				note("Haven Junction: you left them medicine for the winter.")
			elif i == 1:
				GS.train["diesel"] = float(GS.train["diesel"]) - 40.0
				setf("haven", "diesel")
				setf("haven_ally")
				note("Haven Junction: you left them diesel for their generator.")
			elif i == 2:
				setf("haven", "word")
				note("Haven Junction: you promised to carry their name to Meridian.")
			else:
				setf("haven", "refused")
				note("Haven Junction: you refused them. Odile closed her stall to the train.")
				morale(-4.0)
			if f("haven_ally"):
				morale(4.0)
				GS.say("Haven Junction will trade generously with this train from now on.", "good")
			var k5: int = int(fl("k_haven", GS.story["tk"]))
			GS.events.erase(str(k5))
			m.world.open_gate(k5)
			complete("Haven Junction restored")
			_start(m, 3)
		"c3_hail":
			var k6: int = int(fl("k_varda", GS.story["tk"]))
			if i == 0:
				setf("varda", "told")
				setf("varda_peace")
				setf("varda_dispatch")
				note("Fort Varda: you gave Captain Hale the truth about Meridian. He gave you a dispatch to carry.")
				GS.events.erase(str(k6))
				m.world.open_gate(k6)
				show(m, {"id": "info", "kicker": _kick(), "title": "THE GARRISON STANDS DOWN", "speaker": "Captain Viktor Hale", "body": ["He listens to the whole recording without speaking. When it ends he lets it start again, and listens to that too.", "\"Sappers to the cutting. Clear it.\" Then, to you: \"I have a dispatch for Meridian Central. It asks one question. You will carry it, and if there is anyone left there to answer, you will bring the answer back down this line. That is my toll.\""], "options": []})
			elif i == 1:
				GS.train["diesel"] = float(GS.train["diesel"]) - 60.0
				GS.pay({"ammo": 20})
				setf("varda", "paid")
				setf("varda_peace")
				note("Fort Varda: you paid the toll in diesel and ammunition.")
				GS.events.erase(str(k6))
				m.world.open_gate(k6)
				GS.say("Fort Varda's sappers clear the cutting. Nobody waves.")
			else:
				setf("varda", "defied")
				GS.say("\"Then you are trespassing.\" The channel closes. Clear the rubble ahead of the locomotive.", "bad")
		"c3_light":
			if i == 0:
				GS.pay({"batteries": 1})
				setf("light", "cell")
				note("Cape Halt: you gave one of the train's battery cells to the light.")
			elif i == 1:
				setf("light", "niko")
				setf("niko_stays")
				note("Cape Halt: Niko Aalto stayed behind to keep the light burning for you.")
			else:
				setf("light", "dark")
				note("Cape Halt: you left the Cape light dark and crossed blind.")
			_use("c3_light")
			if str(fl("light")) != "dark":
				GS.say("Above the halt the great lamp shudders, catches, and begins to turn.", "good")
		"c4_ivo":
			if i == 0:
				setf("truth", "told")
				morale(-8.0)
				for c: Dictionary in GS.crew:
					c["trust"] = minf(100.0, float(c.get("trust", 0.0)) + 10.0)
				note("Kaldwick: you told the whole train that Meridian's call is a recording, and what Ivo did.")
				GS.say("Nobody sleeps. But in the morning every one of them is still aboard.", "warn")
			else:
				setf("truth", "kept")
				trust("Ivo Brandt", 15.0)
				note("Kaldwick: you and Ivo agreed to keep the truth from the train until Meridian.")
			if aboard("Lena Voss") and aboard("Ivo Brandt"):
				var lc: Dictionary = crew("Lena Voss")
				var lr: Dictionary = lc["rel"]
				lr["Ivo Brandt"] = -30.0
			complete("Learned the truth about the transmission")
		"c4_people":
			if i == 0:
				GS.crew.append(GS.mk_crew("Darius Kohl", "Electrician", 3, 411))
				GS.crew.append(GS.mk_crew("Tilda Brandt", "Cook", 2, 618))
				GS.stats["recruited"] = int(GS.stats["recruited"]) + 2
				setf("harbour", "took")
				note("Kaldwick: you took two of the freighter people aboard.")
				morale(3.0)
			elif i == 1:
				GS.pay({"food": 6, "water": 6})
				setf("harbour", "fed")
				note("Kaldwick: you left the freighter people food and water.")
			else:
				setf("harbour", "word")
				note("Kaldwick: you told the freighter people about Corridor Seven and left.")
			_use("c4_people")
		"c5_points":
			var k9: int = int(GS.story["tk"])
			GS.events.erase(str(k9))
			m.world.open_gate(k9)
			m.sfx.play("clunk", 2.0, 0.6)
			if i == 0:
				GS.story["mk"] = k9 + 1
				_goto(2)
				_use("c5_points")
				note("Greywater: you set the road for Corridor Seven.")
				GS.say("The blade moves. For the first time in four hundred days, the road is set for Meridian.", "good")
			else:
				_goto(0)
				GS.say("The main line, then. Greywater will keep.")
		"c5_edda":
			if step() == 3:
				_goto(4)
		"c5_tx":
			var kind: String = ["home", "line", "truth"][clampi(i, 0, 2)]
			setf("end", kind)
			match kind:
				"home":
					GS.add(GS.store, "food", 25)
					GS.add(GS.store, "water", 25)
					morale(20.0)
					note("Meridian: you told the Northline there was a home here.")
				"line":
					GS.train["diesel"] = minf(1200.0, float(GS.train["diesel"]) + 500.0)
					for kk: String in ["engine", "brakes", "electrical", "hull"]:
						GS.loco[kk] = 100.0
					morale(10.0)
					note("Meridian: you told the Northline the trains were running again.")
				_:
					morale(12.0)
					note("Meridian: you stopped the tape and told the Northline the truth.")
			_use("c5_tx")
			complete("CHAPTER V - The Last Signal")
			GS.story["ch"] = 6
			GS.story["step"] = 0
			pending_ending = true
			m.save_game(0)
	m.ui.close_story()

# ---------------- objective, for the HUD, the objective screen and the map ----------------
static func objective() -> Dictionary:
	var o: Dictionary = {"kicker": _kick(), "title": "", "what": "", "why": "", "where": "", "prog": "", "obj": "", "idx": -1}
	var st: int = step()
	match ch():
		0:
			o["title"] = "Run south"
			o["what"] = "Drive the train out of Nordhaven."
			o["why"] = "Nothing is left here to stay for."
			o["idx"] = 1
		1:
			if st <= 1:
				o["title"] = "Karsk dispatch office"
				o["what"] = "Reach Karsk Maintenance Depot and search the shed for line records: the dispatch desk and the relay cabinet." if st == 0 else "Search the depot shed: the dispatch desk and the relay cabinet."
				o["why"] = "The call is signed Meridian Central, and that name is on no map you own. Dispatch offices keep the old ones."
				o["where"] = "Karsk Maintenance Depot"
				o["prog"] = "Records found: %d of 2" % (int(has("timetable")) + int(has("relay")))
				o["obj"] = "c1_desk" if not has("timetable") else "c1_relay"
				o["idx"] = 1
			else:
				o["title"] = "The voice from Vostok"
				o["what"] = "Stop at Vostok Central and find the pharmacy across the road from the station."
				o["why"] = "Somebody in the city is answering the Meridian call. She may know who is making it."
				o["where"] = "Vostok Central"
				o["obj"] = "c1_stock"
				o["idx"] = 2
		2:
			o["title"] = "The dead junction"
			o["idx"] = 5
			if st == 0:
				o["what"] = "Stop at the Ironworks and look for what the track gang left behind in their office."
				o["why"] = "Haven Junction is set against the main line. The Ironworks permanent-way gang were the last people to work on it."
				o["where"] = "Ironworks District (optional: the junction can be opened without it)"
				o["obj"] = "c2_book"
				o["idx"] = 3
			elif st == 1:
				o["what"] = "Search the Depot 9 cold store for the interlocking relays."
				o["why"] = "The gang book says they hid the relays there." if has("workers") else "The junction's relays went missing somewhere along this stretch."
				o["where"] = "Depot 9 Warehouses (optional)"
				o["obj"] = "c2_relays"
				o["idx"] = 4
			elif st == 2:
				o["what"] = "Reach Haven Junction."
				o["why"] = "The junction is locked against the south line. Nothing gets past it until the lever frame works."
				o["where"] = "Haven Junction"
			else:
				o["what"] = "Get the lever frame at the south end of the yard working: fit the relays, bring the engineer Sami Qureshi aboard, or pay the council."
				o["why"] = "The barrier across the south line will not lift any other way."
				o["where"] = "Haven Junction, lever frame"
				o["prog"] = "Relays: %s    Sami Qureshi: %s" % ["in hand" if f("relays") else "not found", "aboard" if aboard("Sami Qureshi") else "on the platform"]
				o["obj"] = "c2_frame"
		3:
			o["title"] = "The long crossing"
			if st == 0:
				o["what"] = "Reach Fort Varda."
				o["why"] = "The garrison holds the crossing closed. There is no other way south."
				o["where"] = "Fort Varda"
				o["idx"] = 6
			elif st == 1:
				o["what"] = "Clear the rubble ahead of the locomotive: a Tool Kit and an hour's work, under fire."
				o["why"] = "The garrison will not open the crossing for you."
				o["where"] = "Fort Varda, on the track ahead of the train"
				o["idx"] = 6
			elif st <= 3:
				o["what"] = "Reach Cape Halt and decide what to do about the dark lighthouse before the storm." if st == 2 else "Decide about the Cape light at the control panel in the keeper's house, then depart."
				o["why"] = "The causeway signals can only be read by the sweep of the Cape light."
				o["where"] = "Cape Halt, keeper's house"
				o["obj"] = "c3_light" if fl("light", "") == "" else ""
				o["idx"] = 7
			else:
				o["what"] = "Cross the causeway to the Port of Kaldwick."
				o["why"] = "The storm is on the sea wall."
				o["where"] = "Port of Kaldwick"
				o["prog"] = "Cape light: %s" % ("burning" if str(fl("light", "dark")) != "dark" else "dark - speed held to 30 km/h")
				o["idx"] = 8
		4:
			o["title"] = "The quiet city"
			o["idx"] = 8
			if st == 0:
				o["what"] = "Search Kaldwick: the harbour office at the far end of the yard, and the signal logger on the platform."
				o["why"] = "A whole city left by rail for Meridian. Somebody here wrote down where they went, and what answered."
				o["where"] = "Port of Kaldwick"
				o["prog"] = "Harbour log: %s    Signal logger: %s" % ["read" if has("harbour_log") else "not found", "read" if has("recording") else "not found"]
				o["obj"] = "c4_rec"
			else:
				o["what"] = "Decide what to do about the people living in the grounded freighter, then leave for Greywater Halt."
				o["why"] = "They heard your horn." if fl("harbour", "") == "" else "Kaldwick has nothing more to tell you."
				o["where"] = "Port of Kaldwick, by the cranes"
				o["prog"] = "Freighter people: %s" % ("undecided" if fl("harbour", "") == "" else "decided")
				o["obj"] = "c4_people" if fl("harbour", "") == "" else ""
		5:
			o["title"] = "The last signal"
			if st == 0:
				o["what"] = "Reach Greywater Halt."
				o["why"] = "Corridor Seven leaves the main line there." 
				o["where"] = "Greywater Halt"
				o["idx"] = 9
			elif st == 1:
				o["what"] = "Throw the Corridor Seven points at the ground frame, at the front end of the platform."
				o["why"] = "The road is still set for the loop north."
				o["where"] = "Greywater Halt, ground frame"
				o["obj"] = "c5_points"
				o["idx"] = 9
			elif st == 2:
				o["what"] = "Drive Corridor Seven to its end."
				o["why"] = "Whatever Meridian is, it is at the end of this line."
				o["where"] = "Meridian Central"
				o["idx"] = -2
			elif st == 3:
				o["what"] = "Speak to the woman on the platform."
				o["why"] = "She has been waiting for a train."
				o["where"] = "Meridian Central, platform"
				o["obj"] = "c5_edda"
				o["idx"] = -2
			else:
				o["what"] = "Go to the control room in the brick tower and decide what the Northline hears next."
				o["why"] = "The recorder is still turning."
				o["where"] = "Meridian Central, control tower"
				o["obj"] = "c5_tx"
				o["idx"] = -2
		_:
			var e: String = str(fl("end", ""))
			o["title"] = {"home": "Keep the home fires", "line": "Run the Northline", "truth": "Answer the voices"}.get(e, "The Northline")
			o["what"] = {"home": "Meridian is home now. The train still runs the loop for what the town cannot grow.", "line": "Keep the train moving between the settlements. Every lap of the line is a service now.", "truth": "People are answering the broadcast. Watch the platforms for flares."}.get(e, "Keep the train and its people alive.")
			o["why"] = "The campaign is complete. The line is yours for as long as you can keep it."
	return o

static func target_idx() -> int:
	if GS.objective < 5:
		return -1
	return int(objective()["idx"])

static func marker() -> Array:
	if GS.objective < 5:
		return []
	var id: String = str(objective()["obj"])
	if id == "":
		return []
	var a: Variant = nodes.get(id)
	if a == null or not is_instance_valid(a):
		return []
	var an: Node3D = a
	if not an.is_inside_tree():
		return []
	return [an.global_position]

static func optional() -> Array:
	var out: Array = []
	out.append(["Grow the train", "A carriage stands abandoned behind the train at most stops. Coupling it needs a Tool Kit and 2 Repair Materials.", "%d coupled" % int(GS.stats["coupled"]), int(GS.stats["coupled"]) > 0])
	out.append(["Find more hands", "Survivors wait at the stops and answer red flares. Each one needs a berth.", "%d aboard of %d berths" % [GS.crew.size(), GS.crew_cap()], int(GS.stats["recruited"]) > 0])
	var side: Array = [["suitcase", "Left luggage", "Something was left on the Nordhaven platform."], ["convoy9", "The abandoned wagons", "A dead train stands on the second track 480 m beyond Vostok Central. Stop beside it."], ["voices", "The Varda mast", "A radio mast stands off the line 480 m beyond Fort Varda. Its hut may still have power."], ["varda_orders", "Fort Varda's orders", "Whatever keeps the garrison at its post is written down somewhere in the command bunker."]]
	for sd: Array in side:
		out.append([sd[1], sd[2], "found" if has(str(sd[0])) else "not found", has(str(sd[0]))])
	return out

static func passengers() -> Array:
	var out: Array = []
	if aboard("Mara Lindqvist") or f("mara_done"):
		out.append(["Mara Lindqvist", "Her brother Jonas was a mechanic on the Greywater relief gang. She has asked at every stop.", "Reunited at Greywater" if f("mara_reunited") else ("Jonas is aboard" if f("mara_done") else "Still looking")])
	if aboard("Tomas Reyes") and ch() >= 1:
		var v: String = str(fl("vostok", ""))
		out.append(["Tomas Reyes", "The doctor could not decide what to do about the Vostok pharmacy, and knows it.", {"share": "At peace with the half you took", "take": "Has not forgiven the empty shelves", "leave": "Proud of the chalked door", "passed": "Wonders who was calling", "": "Listening to the Vostok voice"}.get(v, "")])
	if aboard("Ivo Brandt") and ch() >= 1:
		var t: String = str(fl("truth", ""))
		out.append(["Ivo Brandt", "Goes quiet whenever the Meridian call comes on." if t == "" else "Was the gate officer who closed Meridian's gates.", {"": "Hiding something", "told": "Has told the train everything", "kept": "Carrying it to Meridian with you"}.get(t, "")])
	if aboard("Hanne Sorel") and ch() >= 2:
		out.append(["Hanne Sorel", "Does not believe in cities that call you on the radio. Cooks for the day they turn out to be empty.", "Was right, and takes no pleasure in it" if has("recording") else "Unconvinced"])
	if aboard("Lena Voss"):
		out.append(["Lena Voss", "Left Vostok on a convoy for Meridian and walked back alone. Will not say why." if not has("ivo") else "Was on the train Ivo shut the gates on.", "Has not spoken to Ivo" if (has("ivo") and not f("edda_met")) else "Aboard"])
	if aboard("Sami Qureshi"):
		out.append(["Sami Qureshi", "Drew the signalling for the whole Northline. Wants to see the control room it all answers to.", "Reached Meridian" if ch() >= 6 else "On his way"])
	return out

static func mind(c: Dictionary) -> String:
	var n: String = str(c["name"])
	match n:
		"Mara Lindqvist":
			if f("mara_reunited"):
				return "He looks older. So do I, he says. I keep checking he is still in the next seat."
			return "My brother Jonas was on the Greywater relief gang when it all stopped. Every depot we pass, I look at the names chalked on the lockers."
		"Tomas Reyes":
			match str(fl("vostok", "")):
				"take": return "Somebody knocked on that pharmacy door the night we left. I think about who."
				"share": return "We took half. I can live with half. That is a strange thing to be able to say."
				"leave": return "We left it all, and nobody on this train has died of it yet. Ask me again in the spring."
			return "If there really is a hospital at Meridian, I should like to stop being the only doctor anyone has."
		"Ivo Brandt":
			match str(fl("truth", "")):
				"told": return "They look at me differently. That is fair. They are still looking at me, which is more than I expected."
				"kept": return "Every kilometre closer, it gets heavier. Thank you for carrying half."
			return "Meridian. Yes. I have heard of it. It was a long time ago." if ch() >= 1 else "Quiet tonight. I prefer it when I can hear the doors."
		"Hanne Sorel":
			if has("recording"):
				return "A tape. We crossed half a country for a tape. Well - there are still thirty people to feed at the end of it, I suppose. That is a kitchen."
			return "A voice on the radio promising a city. I have heard promises with better evidence. I will cook for wherever we actually arrive."
		"Lena Voss":
			if has("ivo"):
				return "I stood at that gate for two days. I never saw the face of the man who shut it. Now he sits four seats from me and passes the bread."
			return "I went south once before, on a convoy. I came back. Do not ask me yet."
		"Sami Qureshi":
			return "Every signal you have passed since Nordhaven was my drawing. I would like, once, to stand in the room they all report to."
		"Jonas Berg":
			return "She kept asking at depots? I kept chalking my name on lockers. We must have missed each other by a day, twice."
	return "I think about the people we passed. Whether anyone stopped for them after us."

# ---------------- the ending ----------------
static func epilogue() -> Array:
	var out: Array = []
	var e: String = str(fl("end", ""))
	match e:
		"home":
			out.append(["A HOME", "The recorder stops at ten past six. Within the hour Edda Stein's own voice replaces it: Meridian Central is open; come and stay. Locomotive 4071 is shunted onto the turntable road and its heating main coupled to the glasshouses. By midwinter there are curtains in the carriage windows, and a child has been born in Car 2."])
		"line":
			out.append(["A LINE", "The recorder stops at ten past six. What replaces it is a timetable, read out twice a day: the Northline is running. Meridian sets the road from the tower; Locomotive 4071 carries seed south and diesel north and, once, a wedding party. Nobody calls it the last train any more. It is the 09:15."])
		_:
			out.append(["THE TRUTH", "The recorder stops at ten past six. You read out the real number - thirty-one, and the people of this train - and what Meridian has, and what it lacks. Then you ask whoever is listening to answer. For two days there is nothing. On the third, a carrier comes up out of the static, and a voice says a place name, and a number."])
	var lost: int = int(GS.stats["lost"])
	out.append(["THE TRAIN", "%d people stepped down from the train at Meridian%s. It had left Nordhaven with two carriages and arrived with %d, having run %.1f kilometres in %d days." % [GS.crew.size() + 1, (", and %d did not live to see it" % lost) if lost > 0 else ", and not one was lost on the way", GS.cars.size(), float(GS.stats["distance"]) / 1000.0, GS.day()]])
	match str(fl("vostok", "")):
		"share": out.append(["VOSTOK", "In the spring a family of four walks into Meridian from the north. They say a pharmacy in Vostok kept them alive through the winter, and that somebody had left it half full and the door unlocked."])
		"take": out.append(["VOSTOK", "The medicine you carried out of Vostok saved lives on the train. Nobody ever came down the line from the city. You do not know what that means, and Tomas has stopped guessing aloud."])
		"leave": out.append(["VOSTOK", "In the spring eleven people walk into Meridian from the north, carrying a pharmacy between them in rucksacks. On the lid of one crate somebody has copied out the chalk mark you left on the door."])
		_: out.append(["VOSTOK", "You never found out who was reading a list of medicines to the empty air in Vostok. The voice stopped some weeks later."])
	match str(fl("haven", "")):
		"medicine", "diesel": out.append(["HAVEN JUNCTION", "Haven lasted the winter. When the junction's signals dropped to green again its people painted the station name back on the platform, and Odile sent the first goods the Northline had carried in two years: forty kilos of seed potatoes, addressed to 'the train'."])
		"word": out.append(["HAVEN JUNCTION", "You carried Haven's name to Meridian as you promised. It was a hard winter there. They buried six. In March Odile asked, over the restored line telephone, whether a promise could be eaten."])
		"refused": out.append(["HAVEN JUNCTION", "Haven kept the junction working because a working junction was worth having. They did not thank you for it. The first thing they sent up the restored line was a bill."])
	match str(fl("varda", "")):
		"told": out.append(["FORT VARDA", "Captain Hale received his recall in Edda Stein's handwriting. The garrison marched out of Fort Varda in column, opened the crossing behind them, and reported to Meridian Central for orders. She put them to work on the well."])
		"paid": out.append(["FORT VARDA", "Fort Varda still holds its crossing and still takes its toll. They are waiting for an order that only you know will never come the way they expect. Somebody should tell them."])
		_: out.append(["FORT VARDA", "Fort Varda fired on the train as it passed, and you cleared their rubble with your own hands. The garrison is still there, holding a closed corridor against a railway that has reopened around it."])
	match str(fl("harbour", "")):
		"took": out.append(["KALDWICK", "Darius and Tilda, carried out of the freighter at Kaldwick, were the first of their nine to reach Meridian. The other seven followed the rails on foot and arrived in April, because two of their own had gone ahead to say it was real."])
		"fed": out.append(["KALDWICK", "The food you left at Kaldwick lasted the freighter people five weeks. It was enough to get seven of the nine to the first thaw."])
		"word": out.append(["KALDWICK", "You told the freighter people where Corridor Seven left the main line. In May a man walked into Meridian with a hand-drawn map and asked whether this was the place that would take everyone."])
		_: out.append(["KALDWICK", "You never spoke to the people in the freighter. They watched your tail lamp out of sight."])
	match str(fl("truth", "")):
		"told": out.append(["IVO BRANDT", "Ivo Brandt asked to be put on the gate. Edda Stein gave him the key to it instead, and told him its only standing order was that it stay open."])
		"kept": out.append(["IVO BRANDT", "The train learned at Meridian's gates what Ivo had done there, and that you had known. It took a long time for some of them to sit at your table again. Hanne was the last."])
	if f("mara_reunited"):
		out.append(["MARA AND JONAS", "Mara Lindqvist and her brother Jonas took over the Meridian running shed. Between them they have 4071's engine out on the floor twice a year whether it needs it or not."])
	if str(fl("light", "")) == "niko":
		out.append(["THE CAPE LIGHT", "Niko Aalto kept the Cape light turning by hand for nine hours the night you crossed. He is still there. Trains on the causeway sound their horn for him."])
	if has("voices"):
		out.append(["OTHER VOICES", "The three faint carriers you heard from the Varda mast are marked on the control room wall now, each with a pin and a question mark. Sami Qureshi has begun drawing the lines that would reach them."])
	out.append(["", "The Northline is open. The journey continues for as long as you can keep the train alive."])
	return out
