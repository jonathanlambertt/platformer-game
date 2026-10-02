# platformer

A small 2D pixel-art platformer built with Godot 4.7 (GDScript). It is a testbed for a Mario-style jump: variable jump height, heavier fall gravity, apex hang, coyote time, jump buffering and ceiling corner correction (all in `player/player.gd`).

Open the project in the Godot 4.7 editor and press Play. The game starts on Level 0 (the main scene). The levels are chained by their doors: Level 0 → 1 → 2 → 3, and Level 3 is the last. Run any level's scene directly to start there.

Move with the arrow keys / WASD / D-pad / left stick, jump with Space / W / Up / A (Cross), and open a door by standing in front of it and pressing E / X (Square). A small prompt above the door shows the button while you are close enough. Opening a door brings up a "Thanks for playing!" popup with **Restart** (this level), **Continue** (the next level) and **Quit**; the last level's door has no Continue, and its Restart goes back to Level 0. Pick one with the mouse, or with left / right and Enter / Space / A (Cross).
## Level 0

`levels/level_0.tscn` (215×61 tiles) is the first level and the project's main scene. It starts in a cave, drops to a deeper cavern, climbs out into the open air and ends on a hillside. Rock closes it in at both ends and underneath; only the outdoor part has sky. Each section exercises one part of the jump:

1. **Entrance chamber** – flat floor, start marker, room to try the jump.
2. **Low crawl** – a 3-tile-high tunnel with one spike; a full jump bonks the ceiling, so it wants a short hop.
3. **Steps** – two 2-tile steps up.
4. **Spike pit** – three 3-tile gaps across floating platforms, with a stalactite hanging over the middle gap.
5. **Shaft** – a climb of 2-tile gaps that also rise 2 tiles. Falling in is not fatal; a low platform leads back to the ledge.
6. **Upper gallery** – a 2-tile-wide spike patch under a 4-tile ceiling.
7. **Descent** – two drops through narrowing passages (one-way).
8. **Slope chamber** – a slope up and a 3-tile spike pit.
9. **The well** – a 14-tile drop past two platforms into the lowest cavern (one-way).
10. **Deep cavern** – a spike patch, a stalactite and a 2-tile step.
11. **Chimney** – a 16-tile zigzag climb on platforms, out through the open top into daylight.
12. **Hillside** – steps up to a peak, a 3-tile chasm with spikes at the bottom, steps down into a dip, and a slope back up.
13. **Sky route** – two optional platforms above the dip, each a 2-tile gap and 2 tiles up.
14. **Goal** – the blue door at the far right, leading to Level 1.

### Enemies

Four dark blobs patrol flat stretches of the level: the shelf after the first spike pit, the passage before the slope chamber, the first hillside ledge, and the goal plateau. Each walks back and forth over 5–6 tiles at about a third of the player's walking speed. Touching one restarts the level; jump over it. They cannot be killed.

The enemy is `enemies/enemy.tscn`. To add one, instance it under `Enemies`, put it at the left end of its patrol, and set `patrol_distance` (pixels, 8 per tile) and `speed` in the Inspector.

Two jumpers sit in the deep cavern and in the dip on the hillside. A jumper cannot walk. When the player comes within 10 tiles it crouches for a moment, then leaps in an arc aimed at where the player is standing, up to 4 tiles away, and rests for a second before the next leap. It cannot steer in the air, so step or jump out of the spot it aimed at. It is `enemies/jumper.tscn`, and its sprite is `enemies/jumper.png` (the tileset cat recoloured to match the patrolling enemy); range, jump distance, height and timings are in the Inspector.

### Decoration tiles

None of these have collision or behaviour (the door is a separate object, `door/door.tscn`); they are there to see how the tileset reads in the game.

- **Rock** – interior fill is mostly plain, with speckled variants and the occasional bone or skull tile mixed in at random.
- **Cave props** – orange plants and bowls, blue water splashes, two gems, a key and a padlock.
- **Outdoor props** – pink plants, pink bowls, two tall pink posts and two flags.
- **Sky** – clouds and small cloud puffs, three gold stars, a heart, and a magnet on the top sky platform.

## Level 1

`levels/level_1.tscn` (240×104 tiles) is a longer level that stays underground and keeps going down. It is reached through Level 0's door. It follows the same jump rules (2-tile steps, 3-tile gaps) and has three tiers:

1. **Entrance chamber** – the open door you came in by.
2. **Low crawl** – a 3-tile-high tunnel with two spikes.
3. **Stairs down** – three 2-tile drops under a stalactite, with a patrolling enemy at the bottom.
4. **Spike pit** – five 3-tile gaps over thin platforms, a stalactite over the middle.
5. **First well** – a 26-tile drop past three platforms (one-way). A small alcove with a heart is to the left at the bottom.
6. **Deep cavern** – a spike patch, a stalactite, a jumper and a 2-tile step.
7. **Chasm** – six jumps over spikes; the middle two platforms are 2 tiles higher.
8. **Passage and slope chamber** – a patrolling enemy, a slope up, and a 3-tile spike pit.
9. **Second well** – a 30-tile drop past three platforms (one-way).
10. **Bottom cavern** – now heading left: a jumper, a spike patch, a 2-tile step down and a patrolling enemy.
11. **Last chasm** – the same six-jump crossing, right to left.
12. **Goal** – the blue door, guarded by a patrolling enemy, with a key and a padlock beside it, leading to Level 2.

## Level 2

`levels/level_2.tscn` (250×42 tiles) is a straight left-to-right run under open sky, in the style of the earlier levels described below. It is reached through Level 1's door.

1. **Start** – the orange post, then a ramp up onto the first block, where the first shooter stands.
2. **Small spike pit** – a 3-tile gap, then a patrolling enemy.
3. **Wide pit** – four platforms over spikes, the last two 2 tiles higher, with a shooter waiting on the far side.
4. **Tower** – three 2-tile steps up and a drop off the far side, towards a shooter on the ground below.
5. **Spikes on the ground** – a 2-tile patch, a patrolling enemy, then a long spike field crossed on four platforms.
6. **Jumper** – on the flat before the last block.
7. **Last block** – steps up, a shooter on top, and a 3-tile spike pit through the middle.
8. **Goal** – the blue door between two pink posts, leading to Level 3.

### Shooters

A shooter is a dark square with red eyes. When the player is within 12 tiles it walks slowly towards them, stopping 3 tiles short and never stepping off a ledge. Once a second it stops, flashes red for a moment, then fires a small spinning projectile at where the player is standing. The shot flies in a straight line at a little under walking speed, cannot steer, and disappears when it hits terrain. Being hit restarts the level, and so does touching the shooter. It is `enemies/shooter.tscn`; range, walking speed, stopping distance, firing interval, warning time and projectile speed are in the Inspector. The shot itself is `enemies/projectile.tscn`, which has the spin speed.

## Level 3

`levels/level_3.tscn` (280×47 tiles) is another open-air, left-to-right level. Its only enemies are nine shooters, and each section is built around them. It is reached through Level 2's door and is the last level.

1. **Start** – the orange post and a quiet stretch.
2. **Cover walls** – three 2-tile walls with a shooter in each of the two bays between them. A wall stops a level shot, so you can wait behind it.
3. **Pillars** – six 3-tile rock pillars over a spike pit, 3 tiles apart, with two shooters on floating slabs overhead firing down.
4. **Zigzag climb** – seven platforms up the face of a tall block, 2 tiles apart and alternating sides, with a shooter at the top edge.
5. **Block top** – a cover wall and a second shooter.
6. **Big steps** – three 4-tile drops down the far side.
7. **Two routes** – jump onto a long floating slab and cross over the top past one shooter, or drop down and take the 3-tile-high tunnel underneath past another, where there is little room to jump a shot.
8. **Platform crossing** – four platforms over spikes, with a shooter waiting on the far side.
9. **Goal** – one last cover wall, then the blue door between two pink posts. Its popup has no Continue button, since this is the last level.

## Level design notes from the earlier levels

The project used to have three open-air levels (`level_0`, `level_1`, `level_2`). They were removed when the current level replaced them. This section records what they looked like and the design rules they followed, which the current level reuses.

### Rules they shared

- **Tile scale.** Tiles are 8×8 px and the screen is 32×18 tiles. The player is one tile.
- **Jump budget.** A full jump clears just under 3 tiles and covers a little under 5 tiles of flat ground. The levels never asked for that much: steps were at most **2 tiles** high, flat gaps at most **3 tiles** wide (level 0 had one 4-tile gap that also rose 2 tiles, which was the hardest jump in the set), and a gap that also climbed 2 tiles was normally 2 wide.
- **Open sky.** No level had a ceiling. Terrain was a thick slab of ground (10+ rows of fill under the surface) with raised blocks on top; the only overhead obstacles were floating platforms.
- **Spike pits.** Hazards were always spikes lining the bottom of a pit, one row above the pit floor. Spikes don't block movement; touching one restarts the level. Level 2 also put short runs of spikes directly on walkable ground and on top of platforms, to be hopped over.
- **Floating platforms.** Thin blue half-height platforms, usually one tile wide, were the stepping stones over pits. They are solid from below, so you cannot jump up through one.
- **Zigzag climbs.** Tall walls were climbed on thin platforms stacked 2 tiles apart, alternating sides of a narrow shaft.
- **One slope.** Each level opened with a single 4-tile ramp rising to the right onto the first raised block. Only the rising-right slope tile has collision.
- **Markers and decoration.** A 5-tile orange post marks the start, and in levels 1 and 2 also the goal at the far right. The goal is decoration only; nothing happens on reaching it. Small plants are scattered on floors with no collision.
- **Edges.** Level 0 simply stopped at both ends. Levels 1 and 2 were closed by a 2-tile-wide wall at each end.
- **Progression.** Each level was the previous one extended to the right: level 1 repeated level 0's opening, level 2 repeated level 1's and roughly doubled the length.

### Maps

Legend: `#` rock, `=` walkable top surface, `/` slope, `-` thin platform, `^` spikes, `|` start/goal post, `"` plant, `.` air. The solid fill below each map is cut off.

**Level 0** (70×20 tiles). Start, ramp up to a block, a 10-wide spike pit crossed on two single platforms, a second block, then a zigzag climb up a shaft to the final ledge.

```
.........................................===..........................
.|.......................................###===============.....======
.|............../==============...-...-..##################.....######
.|............./###############..........##################-....######
.|............/################..........##################.....######
.|."........./#################..........##################-....######
=============##################..........##################.....######
###############################^^^^^^^^^^##################....-######
###############################==========##################.....######
###########################################################=====######
######################################################################
```

**Level 1** (111×25 tiles). The same opening with a small spike notch added to the first block, a wider pit crossed on scattered platforms at several heights, a stepped tower, and a goal post on the far plateau.

```
==...........................................................................................................==
##............................................................................."...."........................##
##.........................................................................============......................##
##.........................................................................############..................|...##
##.....................................................................--..############=====.............|...##
##.|..............."...".........."........................................#################.............|...##
##.|.........../==========...==========............................--......#################=====........|...##
##.|........../###########^^^##########....................................######################..."....|...##
##.|........./############===##########======..........................--..######################============##
##.|..."..../################################........--...--...--..........####################################
##==========#################################======................========####################################
###################################################^^^^^^^^^^^^^^^^############################################
###################################################================############################################
###############################################################################################################
```

**Level 2** (200×27 tiles). Deeper pits (the floor between blocks is spikes almost everywhere), spikes on top of blocks and on the ground, a long platform crossing with a staircase ramp in the middle, a second tower, a walk over a spiked plain, a narrow pillar, and the goal.

```
==.........................................................................................................................."...".....................................................................==
##...................................................................................................................--..==========...................................................................##
##........................................"..^^.............................................................--...........##########...................................................................##
##......................................==========...........................................^^..................--......##########...^^..............................................................##
##......................................##########.............--......................../========......--...............##########========...........................................................##
##..|...................................##########...--..............--................./#########.......................##################...................................................|.......##
##..|...............................====##########........--.........................../##########..--...................##################."..^^.............................................|.......##
##..|...............................##############........................--......".../###########.......................##################========...........................................|.......##
##..|...........................====##############..............................======############.......................##########################............................===............|.......##
##..|...".....^^............."..##################..............................##################.......................##########################...^^^....^^...^^^...^^.....###........"...|.......##
##====================....======##################..............................##################.......................##########################=========================...###....================##
######################....########################..............................##################.......................###################################################...###....##################
######################....########################..............................##################.......................###################################################...###....##################
######################^^^^########################^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^##################^^^^^^^^^^^^^^^^^^^^^^^###################################################^^^###^^^^##################
######################====########################==============================##################=======================###################################################===###====##################
########################################################################################################################################################################################################
```
