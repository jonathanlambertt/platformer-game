extends Area2D
## The goal door. Stand in front of it and press "interact" to open it. It
## then shows the "Thanks for playing!" popup, with buttons to restart this
## level, continue to `next_scene` (only if one is set) or quit the game.
##
## The door is a self-contained object: the Sprite2D draws it and this Area2D
## is the trigger zone around it, so it can be placed anywhere in a level.
## Its origin is the centre of the 2x2-tile door, so to stand it on the floor
## put it on a tile corner (x and y both multiples of 8).

## The level this door leads to. Leave empty for the last door of the game,
## whose popup then has no Continue button and whose Restart goes back to the
## main scene.
@export_file("*.tscn") var next_scene := ""

## Seconds the open door stays on screen before the popup appears.
@export var message_delay := 0.8

## Where the open door is in assets/tilemap.png (px). The closed door, which
## the Sprite2D shows to begin with, is the 16x16 block just left of it.
const OPEN_REGION := Rect2(104, 48, 16, 16)

## The face buttons on the prompt (px): distance of each from the centre,
## their radius, and the colours of the lit (left) and unlit buttons.
const PAD_SPACING := 3.0
const PAD_RADIUS := 1.4
const PAD_LIT := Color(1, 1, 1)
const PAD_DIM := Color(0.45, 0.45, 0.55)

var is_open := false

@onready var sprite: Sprite2D = $Sprite2D
## The "Thanks for playing!" popup with its Restart, Continue and Quit
## buttons. It's on a CanvasLayer, so it stays put on screen no matter where
## the camera is, and sits in the top half so it doesn't cover the door and
## the player.
@onready var message: CanvasLayer = $Message
@onready var restart_button: Button = %RestartButton
@onready var continue_button: Button = %ContinueButton
@onready var quit_button: Button = %QuitButton
## The hint above the door, shown while the player is close enough to open
## it. `pad` is the four face buttons with the left one (X / Square) lit;
## `key` is the letter E. Whichever matches the last input device is shown.
@onready var prompt: Node2D = $Prompt
@onready var pad: Node2D = $Prompt/Pad
@onready var key: Label = $Prompt/Key


func _ready() -> void:
	pad.draw.connect(_draw_pad)
	restart_button.pressed.connect(_on_restart_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	continue_button.visible = not next_scene.is_empty()
	_link_button_focus()
	_use_pixel_font()
	# Until something is pressed, guess from whether a controller is plugged in.
	_show_pad(not Input.get_connected_joypads().is_empty())


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		_show_pad(true)
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		_show_pad(true)
	elif event is InputEventKey:
		_show_pad(false)


## Draws the four face buttons as circles in a diamond, the left one lit.
## Circles are drawn rather than built from nodes because the window is
## upscaled with `canvas_items`, so they come out round, not as pixel blocks.
func _draw_pad() -> void:
	for offset: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		var color := PAD_LIT if offset == Vector2.LEFT else PAD_DIM
		pad.draw_circle(offset * PAD_SPACING, PAD_RADIUS, color)


func _show_pad(use_pad: bool) -> void:
	pad.visible = use_pad
	key.visible = not use_pad


func _physics_process(_delta: float) -> void:
	prompt.visible = not is_open and has_overlapping_bodies()
	if is_open or not Input.is_action_just_pressed("interact"):
		return
	# The Area2D only watches physics layer 3 ("player"), so any overlapping
	# body is the player.
	for body in get_overlapping_bodies():
		open(body)
		return


func open(player: Node2D) -> void:
	is_open = true
	# Freeze the player and make them safe, so an enemy can't restart the
	# level once the door has been opened.
	player.set_physics_process(false)
	player.get_node("AnimatedSprite2D").play("idle")
	player.get_node("Hurtbox").set_deferred("monitoring", false)

	sprite.region_rect = OPEN_REGION

	await get_tree().create_timer(message_delay).timeout
	message.show()
	# Focus a button so the popup works with keyboard and gamepad too: Continue
	# if there is a next level, otherwise Restart.
	if continue_button.visible:
		continue_button.grab_focus()
	else:
		restart_button.grab_focus()


## Lets left / right cycle through the shown buttons, wrapping at the ends.
func _link_button_focus() -> void:
	var buttons := [restart_button, continue_button, quit_button].filter(
			func(button: Button) -> bool: return button.visible)
	for i in buttons.size():
		var button: Button = buttons[i]
		button.focus_neighbor_left = button.get_path_to(buttons[i - 1])
		button.focus_neighbor_right = button.get_path_to(buttons[(i + 1) % buttons.size()])


## Restarts this level, except on the last door (no `next_scene`), where it
## starts the whole game again from the main scene (Level 0).
func _on_restart_pressed() -> void:
	if next_scene.is_empty():
		get_tree().change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	else:
		get_tree().reload_current_scene()


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file(next_scene)


func _on_quit_pressed() -> void:
	get_tree().quit()


## Makes the door's text blocky. The window is upscaled with `canvas_items`,
## which normally redraws text smoothly at the window's resolution; a copy of
## the default font with antialiasing off and oversampling fixed at 1 is drawn
## at game resolution instead, so its pixels match the tiles.
func _use_pixel_font() -> void:
	var font := ThemeDB.fallback_font.duplicate() as FontFile
	if font == null:
		return
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	# These give the most even letter spacing; at 8 px this font has uneven
	# gaps whatever the settings, so the popup uses 9 px.
	font.hinting = TextServer.HINTING_NORMAL
	font.keep_rounding_remainders = false
	font.oversampling = 1.0
	var pixel_theme := Theme.new()
	pixel_theme.default_font = font
	$Message/CenterContainer.theme = pixel_theme
	key.theme = pixel_theme
