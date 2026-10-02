extends CharacterBody2D
## A shooting enemy.
##
## While the player is within `detect_range` it walks slowly towards them and
## fires a projectile every `fire_interval` seconds, aimed at where the player
## is at that moment. Just before each shot it stops and flashes red for
## `windup_time` seconds as a warning. It won't walk off a ledge, and it stops
## `stop_distance` short of the player rather than walking into them. The
## projectile flies in a straight line and can't steer, so the way to dodge is
## to jump over it or step out of its path.
##
## Like the other enemies it sits on physics layer 2 ("hazards"), so touching
## it kills the player and it never blocks movement. The projectile is on the
## same layer, which is all it takes for a hit to restart the level. Like the
## jumper it has gravity and collides with layer 1 ("world").
##
## It finds the player through the "player" group, which the root node of
## player.tscn belongs to.

const PROJECTILE := preload("res://scenes/projectile.tscn")
## The tint it flashes while winding up a shot.
const WINDUP_COLOR := Color(1.0, 0.45, 0.45)

## It only fires while the player is within this many pixels. 8 px = 1 tile.
@export var detect_range := 96.0
## Walking speed (px/s). The player walks at 64.
@export var move_speed := 20.0
## It stops walking when it is this close to the player horizontally (px).
@export var stop_distance := 24.0
## Gravity (px/s²).
@export var gravity := 600.0
## Seconds between shots.
@export var fire_interval := 0.6
## Seconds it flashes before each shot. This is the warning the player gets.
@export var windup_time := 0.4
## How fast its projectiles fly (px/s). The player walks at 64.
@export var projectile_speed := 50.0

var fire_timer := 0.0     # Counts down to the next windup.
var windup_timer := 0.0   # Counts down while flashing; 0 = not winding up.

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	fire_timer = fire_interval


func _physics_process(delta: float) -> void:
	update_shooting(delta)

	# Stand still while winding up, so the flash reads as a warning.
	velocity.x = 0.0 if windup_timer > 0.0 else get_walk_direction() * move_speed
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()


# It goes: wait (fire_timer) -> flash (windup_timer) -> fire.
func update_shooting(delta: float) -> void:
	if windup_timer > 0.0:
		windup_timer -= delta
		if windup_timer <= 0.0:
			sprite.modulate = Color.WHITE
			fire()
		return

	fire_timer -= delta
	if fire_timer <= 0.0 and get_player_in_range() != null:
		windup_timer = windup_time
		sprite.modulate = WINDUP_COLOR


# Which way to walk: -1 = left, 1 = right, 0 = stay put.
func get_walk_direction() -> float:
	var player := get_player_in_range()
	if player == null or not is_on_floor():
		return 0.0
	var distance := player.global_position.x - global_position.x
	if absf(distance) <= stop_distance:
		return 0.0
	var direction := signf(distance)

	# Ledge check: test_move() asks "would I hit something if I moved by this
	# much?" without moving. From one body-width ahead, probe a tile downwards;
	# if nothing is there, the floor ends, so stay on this side of the edge.
	var ahead := global_transform.translated(Vector2(direction * 6.0, 0.0))
	if not test_move(ahead, Vector2(0.0, 8.0)):
		return 0.0
	return direction


func fire() -> void:
	fire_timer = fire_interval
	var player := get_player_in_range()
	if player == null:
		return  # The player got away during the windup; hold fire.

	var projectile := PROJECTILE.instantiate()
	projectile.direction = global_position.direction_to(player.global_position)
	projectile.speed = projectile_speed
	# Add it next to this node, not under it, so it belongs to the level and
	# is cleared with everything else when the level restarts.
	get_parent().add_child(projectile)
	projectile.global_position = global_position


func get_player_in_range() -> Node2D:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return null
	if global_position.distance_to(player.global_position) > detect_range:
		return null
	return player
