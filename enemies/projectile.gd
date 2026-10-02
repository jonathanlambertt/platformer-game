extends CharacterBody2D
## A shot fired by the shooter enemy (shooter.gd).
##
## It flies in a straight line at a constant speed, with no gravity, spinning
## as it goes, and disappears when it hits terrain or after `lifetime` seconds.
##
## It sits on physics layer 2 ("hazards"), so the player's Hurtbox kills the
## player on touch with no extra code. Its mask is layer 1 ("world") only, so
## terrain stops it but the player and other enemies don't.

## Seconds before it disappears on its own.
@export var lifetime := 10.0
## How fast the sprite spins (turns per second). Purely for looks: only the
## Sprite2D rotates, so the round collision shape is unaffected.
@export var spin_speed := 2.0

var direction := Vector2.RIGHT  # Set by the shooter; must be normalized.
var speed := 90.0               # Set by the shooter (px/s).

@onready var sprite: Sprite2D = $Sprite2D


func _physics_process(delta: float) -> void:
	lifetime -= delta
	sprite.rotation += spin_speed * TAU * delta
	# move_and_collide() returns a collision when it hits something in its
	# mask, which can only be terrain.
	if move_and_collide(direction * speed * delta) != null or lifetime <= 0.0:
		queue_free()
