extends CanvasLayer
## The pause screen. Pressing "pause" (Start / Escape) freezes the game and
## shows a "Game Paused" popup with buttons to restart the level or quit;
## pressing "pause" again resumes.
##
## It is an autoload, so it exists in every level without being placed in
## them. Its process mode is Always, so it keeps running while the rest of
## the tree is paused. The popup reuses the door's look: the same 9-patches
## cut from door/ui.png and the same blocky copy of the default font.

@onready var popup: Control = $Popup
@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton

## Whatever had keyboard/gamepad focus before pausing (such as a button on
## the door's popup), given back on resume so it can still be navigated.
var _previous_focus: Control


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	# Left / right wrap between the two buttons.
	restart_button.focus_neighbor_left = restart_button.get_path_to(quit_button)
	quit_button.focus_neighbor_right = quit_button.get_path_to(restart_button)
	_use_pixel_font()
	popup.hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if get_tree().paused:
			resume()
		else:
			pause()


func pause() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	get_tree().paused = true
	popup.show()
	restart_button.grab_focus()


func resume() -> void:
	popup.hide()
	get_tree().paused = false
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	_previous_focus = null


func _on_restart_pressed() -> void:
	popup.hide()
	get_tree().paused = false
	_previous_focus = null
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()


## Makes the popup's text blocky, as on the door (see `_use_pixel_font` in
## door/door.gd): a copy of the default font with antialiasing off and
## oversampling fixed at 1, so it is drawn at game resolution.
func _use_pixel_font() -> void:
	var font := ThemeDB.fallback_font.duplicate() as FontFile
	if font == null:
		return
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.hinting = TextServer.HINTING_NORMAL
	font.keep_rounding_remainders = false
	font.oversampling = 1.0
	var pixel_theme := Theme.new()
	pixel_theme.default_font = font
	popup.theme = pixel_theme
