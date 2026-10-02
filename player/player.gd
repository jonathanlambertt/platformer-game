extends CharacterBody2D
## A simple Mario-style platformer controller.
##
## Everything lives in this one script on purpose, so it's easy to read and tweak.
## All numbers are in the game's virtual pixels (the game renders at 256x144 and
## one tile is 8 px), so "64 px/s" means "8 tiles per second".
##
## The things that make movement feel like Mario (instead of instant and stiff):
##   1. Momentum    - you speed up and slow down over time rather than instantly.
##   2. Skidding    - turning around brakes harder than just letting go.
##   3. Running     - holding a run button raises your top speed.
##   4. Jump height - holding jump goes higher, tapping it gives a short hop.
##   5. Heavy fall  - you fall faster than you rise, so jumps feel snappy.
##   6. Forgiveness - coyote time, jump buffering and corner correction
##                    (invisible, but you'd miss them).
##
## Every tunable value is an @export, so you can tweak them live in the Inspector.


# ---------------------------------------------------------------------------
# HORIZONTAL MOVEMENT
# ---------------------------------------------------------------------------
@export_group("Horizontal")
## Top speed when walking (px/s).
@export var walk_speed := 64.0
## Top speed while holding the "run" action (px/s). Only used if a "run" input
## action exists in Project Settings > Input Map; otherwise you always walk.
@export var run_speed := 110.0
## How fast you speed up while holding a direction on the ground (px/s²).
## At 600 you reach walk speed in about 0.1 s.
@export var ground_acceleration := 600.0
## How fast you slow down when you let go of the stick on the ground (px/s²).
## Lower = more slippery, like ice. At 700 you stop within about half a tile.
@export var ground_friction := 700.0
## How fast you brake when pressing the *opposite* direction (px/s²).
## This is Mario's "skid". Higher than friction so turning around feels responsive.
@export var skid_deceleration := 1000.0
## Multiplier for acceleration while pressing a direction in the air. Mario has
## less control mid-air, but not zero - 1.0 = same as ground, 0.0 = none at all.
@export_range(0.0, 1.0) var air_control := 0.8
## How fast you slow down in the air with no input (px/s²). Kept low so a jump
## keeps its momentum when you let go of the stick, like in Mario - this makes
## jump distances predictable.
@export var air_friction := 60.0


# ---------------------------------------------------------------------------
# JUMPING AND GRAVITY
# ---------------------------------------------------------------------------
@export_group("Jump")
# Instead of tuning velocity and gravity directly (which is hard to reason
# about), we describe the jump we WANT and let math work out the physics.
# See get_jump_velocity() and friends further down for the formulas.
## How high a full jump goes (px) from standing, not counting the small extra
## from jump_speed_bonus and the apex hang. 22 px = just under 3 tiles.
@export var jump_height := 22.0
## Seconds from takeoff to the top of a full jump. Lower = snappier.
@export var time_to_peak := 0.28
## Seconds from the top of the jump back down to takeoff height. Making this
## shorter than time_to_peak gives the classic "light up, heavy down" feel.
@export var time_to_fall := 0.21
## When you let go of jump while rising, upward speed is multiplied by this.
## Lower = shorter tap-hops. 1.0 = no cut (only the heavier gravity applies).
@export_range(0.0, 1.0) var jump_cut := 0.6
## Near the top of a held jump (vertical speed below this, in px/s), gravity is
## reduced so you "hang" briefly. This makes it easier to aim your landing.
@export var apex_threshold := 30.0
## Gravity multiplier during that hang. 1.0 disables it.
@export_range(0.0, 1.0) var apex_gravity_scale := 0.5
## Extra jump speed added per px/s of horizontal speed. Mario jumps higher when
## running fast. 0 disables it. At run speed (110) this adds 110*0.15 = ~16 px/s.
@export var jump_speed_bonus := 0.15
## Maximum falling speed (px/s), so long falls don't get uncontrollably fast.
@export var max_fall_speed := 220.0

@export_group("Forgiveness")
## Coyote time: seconds after walking off a ledge during which you can still jump.
## Named after Wile E. Coyote, who hangs in the air before noticing the drop.
@export var coyote_time := 0.1
## Jump buffer: if you press jump this many seconds *before* landing, the jump
## still happens the moment you touch the ground.
@export var jump_buffer_time := 0.12
## Corner correction: if you clip the edge of a ceiling by this many pixels or
## fewer while jumping, you get nudged sideways around it instead of bonking.
## 0 disables it.
@export var corner_correction := 3


# ---------------------------------------------------------------------------
# STATE (changes while playing - not meant to be tweaked in the Inspector)
# ---------------------------------------------------------------------------
var facing := "right"         # "left" or "right"; picks the run/jump animation.
var coyote_timer := 0.0       # Counts down after leaving the ground.
var jump_buffer_timer := 0.0  # Counts down after pressing jump.
var is_jumping := false       # True from the jump until landing. Lets us tell
							  # "jumped" apart from "walked off a ledge".

var is_dead := false          # Set on death so we only restart once.

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	# The Hurtbox only watches physics layer 2 ("hazards"). Spike tiles put a
	# shape on that layer, so touching one fires body_entered with the
	# TileMapLayer as the body. Spikes aren't on layer 1, so they never block
	# movement - you walk *into* them, not on top of them.
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)


func _physics_process(delta: float) -> void:
	# The order matters: read input -> change velocity -> move -> animate.
	var input_dir := Input.get_axis("move_left", "move_right")

	update_timers(delta)
	apply_gravity(delta)
	handle_jump()
	apply_horizontal_movement(input_dir, delta)
	apply_corner_correction(delta)

	# move_and_slide() moves the body using `velocity` and handles collisions.
	# It also updates is_on_floor() / is_on_wall() for the next frame.
	move_and_slide()

	update_animation(input_dir)


# ---------------------------------------------------------------------------
# TIMERS
# ---------------------------------------------------------------------------
func update_timers(delta: float) -> void:
	if is_on_floor():
		# Standing on the ground: refill coyote time and clear the jump flag.
		coyote_timer = coyote_time
		is_jumping = false
	else:
		coyote_timer -= delta

	# Remember a jump press for a short window, so an early press isn't lost.
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta


# ---------------------------------------------------------------------------
# GRAVITY
# ---------------------------------------------------------------------------
func apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	# Rising and still holding jump -> light gravity (go high).
	# Otherwise (falling, or let go of jump) -> heavy gravity (come down fast).
	var rising := velocity.y < 0.0
	var holding_jump := Input.is_action_pressed("jump")
	var gravity := get_jump_gravity() if (rising and holding_jump) else get_fall_gravity()

	# Apex hang: while holding jump near the top of the arc, soften gravity.
	if holding_jump and is_jumping and absf(velocity.y) < apex_threshold:
		gravity *= apex_gravity_scale

	velocity.y += gravity * delta
	velocity.y = minf(velocity.y, max_fall_speed)


# These turn jump_height / time_to_peak / time_to_fall into physics values.
# They come from the standard equations of motion under constant gravity:
#   height = 0.5 * gravity * time²   ->   gravity  = 2 * height / time²
#   speed  = gravity * time          ->   velocity = 2 * height / time
# They're functions (not stored values) so Inspector changes apply instantly.
# With the defaults: jump velocity ~ -157, rise gravity ~ 561, fall gravity ~ 998.
func get_jump_velocity() -> float:
	return -2.0 * jump_height / time_to_peak  # Negative = up.


func get_jump_gravity() -> float:
	return 2.0 * jump_height / (time_to_peak * time_to_peak)


func get_fall_gravity() -> float:
	return 2.0 * jump_height / (time_to_fall * time_to_fall)


# ---------------------------------------------------------------------------
# JUMPING
# ---------------------------------------------------------------------------
func handle_jump() -> void:
	# You can jump if you pressed jump recently (buffer) AND you're on the
	# ground or just left it (coyote). `not is_jumping` stops coyote time from
	# giving you a second jump right after the first.
	var wants_jump := jump_buffer_timer > 0.0
	var can_jump := coyote_timer > 0.0 and not is_jumping

	if wants_jump and can_jump:
		# Faster horizontal speed -> slightly higher jump (subtracting = more upward).
		velocity.y = get_jump_velocity() - absf(velocity.x) * jump_speed_bonus
		is_jumping = true
		# Use up both timers so this single press can't trigger another jump.
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Jump cut: letting go early chops off some upward speed right away, so a
	# quick tap gives a small hop that responds the instant you release.
	if Input.is_action_just_released("jump") and is_jumping and velocity.y < 0.0:
		velocity.y *= jump_cut

	# Bonk: if we hit a ceiling while going up, stop rising immediately.
	if is_on_ceiling() and velocity.y < 0.0:
		velocity.y = 0.0


# ---------------------------------------------------------------------------
# HORIZONTAL MOVEMENT
# ---------------------------------------------------------------------------
func apply_horizontal_movement(input_dir: float, delta: float) -> void:
	# Top speed depends on whether the run button is held. has_action() lets this
	# work even before you've added a "run" action to the Input Map.
	var running := InputMap.has_action("run") and Input.is_action_pressed("run")
	var top_speed := run_speed if running else walk_speed
	var target_speed := input_dir * top_speed

	# Pick how quickly we move toward target_speed this frame.
	var rate: float
	if input_dir == 0.0:
		# No input: coast to a stop (much more gently in the air).
		rate = ground_friction if is_on_floor() else air_friction
	elif velocity.x != 0.0 and signf(input_dir) != signf(velocity.x):
		# Pressing against our current motion: skid!
		rate = skid_deceleration
	else:
		# Pressing the same way we're moving (or starting from rest): accelerate.
		rate = ground_acceleration

	# Pressing a direction in the air: less control than on the ground.
	if input_dir != 0.0 and not is_on_floor():
		rate *= air_control

	# move_toward() changes a value toward a target by at most `rate * delta`,
	# which gives smooth acceleration without ever overshooting the target.
	# Tip: when you let go of run at high speed, this also eases you back down
	# to walk speed instead of snapping.
	velocity.x = move_toward(velocity.x, target_speed, rate * delta)

	# Face the way the player is pressing (like Mario, you turn to face your
	# input immediately, even while still sliding the other way during a skid).
	if input_dir > 0.0:
		facing = "right"
	elif input_dir < 0.0:
		facing = "left"


# ---------------------------------------------------------------------------
# CORNER CORRECTION
# ---------------------------------------------------------------------------
# With 8 px tiles it's easy to clip a ceiling corner by a pixel or two and have
# your jump die. Mario (and most good platformers) quietly nudge you around it.
func apply_corner_correction(delta: float) -> void:
	if velocity.y >= 0.0 or corner_correction <= 0:
		return  # Only matters while moving up.

	# test_move() asks "would I hit something if I moved by this much?"
	# without actually moving. First: are we about to hit a ceiling at all?
	var motion := Vector2(0.0, velocity.y * delta)
	if not test_move(global_transform, motion):
		return

	# Try shifting 1, 2, 3... px left and right. The first spot that has room
	# to shift into AND a clear path upward wins, and we snap over to it.
	# If nothing works, it's a real ceiling and we bonk as normal.
	for offset in range(1, corner_correction + 1):
		for side in [-1, 1]:
			var shift := Vector2(offset * side, 0.0)
			var shifted := global_transform.translated(shift)
			if not test_move(global_transform, shift) and not test_move(shifted, motion):
				global_position += shift
				return


# ---------------------------------------------------------------------------
# DEATH
# ---------------------------------------------------------------------------
func _on_hurtbox_body_entered(_body: Node2D) -> void:
	die()


func die() -> void:
	if is_dead:
		return  # Touching several spike tiles at once would call this repeatedly.
	is_dead = true
	set_physics_process(false)
	# Reloading from inside a physics callback isn't allowed, so wait until
	# the end of the frame. This restarts whichever level is currently running.
	get_tree().reload_current_scene.call_deferred()


# ---------------------------------------------------------------------------
# ANIMATION
# ---------------------------------------------------------------------------
# Available animations in player.tscn: idle, run_left, run_right, jump_left, jump_right.
# Idea to extend: add a "skid" animation and play it when on the floor and
# signf(input_dir) != signf(velocity.x).
func update_animation(input_dir: float) -> void:
	anim.speed_scale = 1.0
	if not is_on_floor():
		anim.play("jump_" + facing)
		# The jump animation has 3 frames: rising, peak, falling.
		# Pick one based on vertical speed instead of playing it over time.
		if velocity.y < -50.0:
			anim.frame = 0
		elif velocity.y < 50.0:
			anim.frame = 1
		else:
			anim.frame = 2
	elif absf(velocity.x) > 1.0 or input_dir != 0.0:
		anim.play("run_" + facing)
		# Legs move faster the faster you go, so the character doesn't look
		# like it's ice skating while speeding up or slowing down.
		anim.speed_scale = clampf(absf(velocity.x) / walk_speed, 0.5, 2.0)
	else:
		anim.play("idle")
