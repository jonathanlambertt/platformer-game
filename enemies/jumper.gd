extends CharacterBody2D
## A jumping enemy.
##
## It cannot walk. It sits still, and every so often it crouches for a moment
## and then leaps in an arc aimed at where the player is standing right now.
## Once it's in the air it can't steer, so the way to dodge is to move (or jump)
## out of the spot it aimed at.
##
## Like the patrolling enemy it sits on physics layer 2 ("hazards"), so the
## player's Hurtbox kills the player on touch and it never blocks the player.
## Unlike the patrolling enemy it has gravity and collides with layer 1
## ("world"), so it lands on floors and stops at walls.
##
## It finds the player through the "player" group, which the root node of
## player.tscn belongs to.

## It only jumps while the player is within this many pixels. 8 px = 1 tile.
@export var detect_range := 80.0
## The furthest a single jump can travel on flat ground (px). If the player is
## further away than this, it jumps as far as it can in their direction.
@export var max_jump_distance := 32.0
## How high each jump goes (px). The arc is always this tall.
@export var jump_height := 20.0
## Gravity (px/s²). Higher = a quicker, snappier arc of the same height.
@export var gravity := 600.0
## Seconds it rests on the ground between jumps.
@export var rest_time := 1.0
## Seconds it crouches before leaping. This is the warning the player gets.
@export var windup_time := 0.3

var rest_timer := 0.0     # Counts down while resting on the ground.
var windup_timer := 0.0   # Counts down while crouching; 0 = not crouching.

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	rest_timer = rest_time
	anim.play("idle")


func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.x = 0.0  # No sliding after landing - it can only move by jumping.
		update_ground_state(delta)
	else:
		velocity.y += gravity * delta
		anim.play("jump")

	move_and_slide()


# On the ground it goes: rest -> crouch (windup) -> jump.
func update_ground_state(delta: float) -> void:
	face_player()

	if windup_timer > 0.0:
		windup_timer -= delta
		if windup_timer <= 0.0:
			jump_at_player()
		return

	anim.play("idle")
	rest_timer -= delta
	if rest_timer <= 0.0 and get_player_in_range() != null:
		windup_timer = windup_time
		anim.play("crouch")


func jump_at_player() -> void:
	rest_timer = rest_time
	var player := get_player_in_range()
	if player == null:
		return  # The player got away during the crouch; stay put.

	# Standard jump maths (same as player.gd): the upward speed needed to reach
	# jump_height, and how long the whole arc takes to come back down.
	var jump_speed := sqrt(2.0 * gravity * jump_height)
	var air_time := 2.0 * jump_speed / gravity

	# Aim: pick the horizontal speed that covers the distance to the player in
	# exactly that time, but never more than max_jump_distance.
	var distance := player.global_position.x - global_position.x
	distance = clampf(distance, -max_jump_distance, max_jump_distance)

	velocity = Vector2(distance / air_time, -jump_speed)


# Look towards the player. The sprite is drawn facing right, so flipping it
# horizontally makes it face left. Only called on the ground, so in the air it
# keeps facing the way it jumped.
func face_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	anim.flip_h = player.global_position.x < global_position.x

func get_player_in_range() -> Node2D:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return null
	if global_position.distance_to(player.global_position) > detect_range:
		return null
	return player
