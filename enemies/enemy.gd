extends AnimatableBody2D
## A simple patrolling enemy.
##
## It walks right from where you place it for `patrol_distance` pixels, turns
## around, walks back to its starting spot, and repeats forever. It ignores
## walls, floors and gravity entirely - it just slides along a straight line -
## so place it on flat ground and keep the patrol inside that flat stretch.
##
## It sits on physics layer 2 ("hazards"), the same layer the spikes use, so the
## player's Hurtbox kills the player on touch with no extra code. It is not on
## layer 1 ("world"), so it never blocks movement: you jump over it to dodge.

## How far to the right of its starting position it walks (px). 8 px = 1 tile.
@export var patrol_distance := 32.0
## Walking speed (px/s). The player walks at 64.
@export var speed := 20.0

var start_x := 0.0     # Left end of the patrol, set from where it was placed.
var direction := 1.0   # 1 = walking right, -1 = walking left.

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	start_x = position.x
	anim.play("walk")


func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta

	# Reached an end of the patrol: clamp to it and turn around.
	if position.x >= start_x + patrol_distance:
		position.x = start_x + patrol_distance
		direction = -1.0
	elif position.x <= start_x:
		position.x = start_x
		direction = 1.0
