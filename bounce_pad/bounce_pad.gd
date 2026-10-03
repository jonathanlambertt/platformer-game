class_name BouncePad
extends StaticBody2D
## A spring set into the ground that bounces the player.
##
## Step onto it and you get a small bounce; land on it from a jump and you get
## a big one. The player does the bouncing (see `check_bounce_pad()` in
## player/player.gd); the pad just says how high, and squashes when used.
##
## The root is solid ground (physics layer 1, "world"): its lid is flush with
## the floor, so you walk onto it like any other tile. The spring sprite hangs
## below the lid, so the pad needs a 1-tile-wide, 2-tile-deep notch in the
## TileMapLayer to sit in. Its origin is the top centre of the lid: place it
## at the centre of the notch's column, on the floor line (x = tile * 8 + 4,
## y = the floor's top edge). Pads can sit side by side in a wider notch.

## How high a bounce from stepping (or falling) onto the pad goes (px). 8 px = 1 tile.
@export var small_bounce_height := 8.0
## How high a bounce from landing on the pad in a jump goes (px). A normal
## full jump is just under 3 tiles (about 25 px).
@export var big_bounce_height := 48.0
## Seconds the spring stays squashed after a bounce.
@export var squash_time := 0.15

## Where the spring is in assets/tilemap.png (px): standing, and squashed with
## the top plate gone, so the second plate becomes the top.
const STANDING_REGION := Rect2(0, 12, 8, 16)
const SQUASHED_REGION := Rect2(0, 16, 8, 12)

@onready var sprite: Sprite2D = $Sprite2D

var _squash_left := 0.0


func _process(delta: float) -> void:
	if _squash_left > 0.0:
		_squash_left -= delta
		if _squash_left <= 0.0:
			_show_region(STANDING_REGION)


## True if `body` is standing on the lid: the bottom of its collision shapes is
## on the lid's top edge, and it overlaps the lid sideways by more than 1 px.
##
## This is worked out from positions on purpose. An Area2D's overlaps lag a
## physics frame behind, which leaves the player standing on the pad for a
## frame after landing - long enough for a buffered jump to fire instead of
## the bounce.
func is_under(body: CollisionObject2D) -> bool:
	var lid := _global_shape_rect(self)
	var feet := _global_shape_rect(body)
	return absf(feet.end.y - lid.position.y) <= 1.0 \
			and feet.position.x < lid.end.x - 1.0 \
			and feet.end.x > lid.position.x + 1.0


## Squashes the spring for `squash_time` seconds.
func squash() -> void:
	_squash_left = squash_time
	_show_region(SQUASHED_REGION)


## The bounding box of all of `body`'s enabled collision shapes, in global
## coordinates.
static func _global_shape_rect(body: CollisionObject2D) -> Rect2:
	var rect := Rect2()
	var first := true
	for owner_id in body.get_shape_owners():
		if body.is_shape_owner_disabled(owner_id):
			continue
		var xform := body.global_transform * body.shape_owner_get_transform(owner_id)
		for i in body.shape_owner_get_shape_count(owner_id):
			var shape_rect := xform * body.shape_owner_get_shape(owner_id, i).get_rect()
			rect = shape_rect if first else rect.merge(shape_rect)
			first = false
	return rect


## Shows part of the spring, bottom-aligned so the base stays on the notch floor.
func _show_region(region: Rect2) -> void:
	sprite.region_rect = region
	sprite.position.y = STANDING_REGION.size.y - region.size.y
