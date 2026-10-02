extends Area2D
## The goal door. Stand in front of it and press "interact" to open it and
## show the "Thanks for playing!" message.
##
## The door is a self-contained object: the Sprite2D draws it and this Area2D
## is the trigger zone around it, so it can be placed anywhere in a level.
## Its origin is the centre of the 2x2-tile door, so to stand it on the floor
## put it on a tile corner (x and y both multiples of 8).

## Seconds the open door stays on screen before the message appears.
@export var message_delay := 0.8

## Where the open door is in assets/tilemap.png (px). The closed door, which
## the Sprite2D shows to begin with, is the 16x16 block just left of it.
const OPEN_REGION := Rect2(104, 48, 16, 16)

var is_open := false

@onready var sprite: Sprite2D = $Sprite2D
## The "Thanks for playing!" box. It's on a CanvasLayer, so it stays centred
## on screen no matter where the camera is.
@onready var message: CanvasLayer = $Message


func _physics_process(_delta: float) -> void:
	if is_open or not Input.is_action_just_pressed("interact"):
		return
	# The Area2D only watches physics layer 3 ("player"), so any overlapping
	# body is the player.
	for body in get_overlapping_bodies():
		open(body)
		return


func open(player: Node2D) -> void:
	is_open = true
	# Freeze the player and make them safe, so the patrolling enemy can't
	# restart the level once the game is finished.
	player.set_physics_process(false)
	player.get_node("AnimatedSprite2D").play("idle")
	player.get_node("Hurtbox").set_deferred("monitoring", false)

	sprite.region_rect = OPEN_REGION

	await get_tree().create_timer(message_delay).timeout
	message.show()
