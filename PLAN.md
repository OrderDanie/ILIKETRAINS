# LAST TRAIN — design contract

```
GAME ANALYSIS
─────────────
Fantasy + pillars : You are the conductor of the last working train in a frozen, infected country.
                    Pillars: WARM INSIDE / COLD OUTSIDE, the train is home, every stop is a risk.
Narrative goal    : Take the train and its survivors down the Northern Line from Nordhaven station
                    to the Port of Kaldwick (10 stops), expanding it carriage by carriage. Then keep it alive.
Signature mechanic: Walk a physically connected train, sit in the cab, drive it (throttle/brake/autopilot)
                    to the next stop, get out on foot to loot — while the train's resources drain.
MDA hypothesis    : scarce supplies + walkable home -> short risky scavenging sorties -> relief when the
                    doors close and the station disappears into the fog.
30-second arc     : wake in the warm carriage -> walk to cab, start engine (first reward: lights, sound)
                    -> choose: loot the station first or leave -> infected arrive, pressure to depart.
Core loop         : drive -> stop -> scavenge / recruit / couple carriage -> manage -> drive on.
Dimension         : 3D (gradient sky, fog, filmic tonemap, glow, key+fill, PBR textures + normal maps)
Perspective       : first-person
PRIMARY genre     : first-person survival / train management (no matching skill file — built from invariants)
Secondary traits  : light management sim (resources, crew assignments)

Technical trick   : the train is fixed at the origin; the WORLD scrolls past it. The player can walk the
                    train at 120 km/h with ordinary static collisions. Train only moves with conductor aboard.

STAGE PLAN (10 handcrafted stops on a looping line, 900 m apart, streamed in/out):
  0 Nordhaven Station (snow region, abandoned station)   5 Haven Junction (survivor settlement, trade)
  1 Karsk Maintenance Depot (workshop car)               6 Fort Varda (military, hostile faction, security car)
  2 Vostok Central (abandoned city, medical car)         7 Cape Halt (coastal railway, lighthouse, greenhouse car)
  3 Ironworks (industrial district, generator car)       8 Port of Kaldwick (port, water treatment car) = milestone win
  4 Depot 9 Warehouses (kitchen car)                     9 Greywater Halt (abandoned station, settlement outpost)
  After stop 9 the line loops (lap+1): loot respawns, threats scale -> endless.

ENTITY ROSTER: locomotive + up to 9 carriage types, survivors (procedural rigged humanoids),
  infected (pale, hunched, shambling), raiders (Fort Varda), trader, loot containers, coupling carriages.

PALETTE : charcoal #1b1d20, steel grey #6b7480, warm white #ece6d8, muted amber #d9a441, restrained red #b5493c
UI THEME: industrial, RussoOne headings, thin amber rules, flat steel panels. No emoji.
Fail/win: player health 0 = run over (reload last save). Reaching the Port = milestone, then endless laps.
Wow beat: first departure — wheels roll, the lit station slides away into the snow fog.
Riskiest : merged-mesh procedural train + world-scroll trick + FPS inside it. Prototype first.
```

Honest notes: no Tripo / 3D-generation integration exists in this environment and the asset library
has no trains or humans. Train, buildings and characters are procedural geometry with generated PBR
textures (albedo + derived normal maps). Kenney CC0 .glb vehicles are used as wrecks.
