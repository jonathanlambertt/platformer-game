# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A 2D pixel-art platformer built with **Godot 4.7** (GDScript, GL Compatibility renderer). There is no build system, package manager, or test suite — the Godot editor/binary is the entire toolchain.

The editor binary lives at `C:\Users\jonat\Documents\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe` (not on `PATH`). Use `Godot_v4.7-stable_win64_console.exe` in the same folder when you need stdout/stderr (e.g. to see `print()` output).

## Commands

Run from the project root (`--path .` points Godot at `project.godot`):

```sh
GODOT="/c/Users/jonat/Documents/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe"

"$GODOT" --path .                        # open the editor
"$GODOT" --path . --headless --quit      # re-import assets / regenerate .godot, verify the project loads
"$GODOT" --path . scenes/level_0.tscn    # run one scene directly
"$GODOT" --path .                        # (no scene arg) runs main_scene = scenes/level_0.tscn
```

Headless `--quit` is the closest thing to a build check: it parses every script and scene and reports errors non-interactively. Do it after editing `.tscn` files or adding assets.

## Resolution and scale

The game renders at **256×144** and is upscaled to a 1280×720 window (`window_width_override`). Tiles are **8×8 px**, texture filtering is nearest (`default_texture_filter=0`), stretch mode is `canvas_items`. All gameplay numbers in `scripts/player.gd` (speed 60, jump −120, gravity 400) are in these small virtual pixels — treat ~8 px as one tile when tuning movement.

## Architecture

Five scenes, composed by instancing:

- `scenes/tile_map_layer.tscn` — a bare `TileMapLayer` with the TileSet built from `assets/tilemap.png` (8×8 atlas, 15×10 frames, physics layer 0).
- `scenes/player.tscn` — `CharacterBody2D` + `AnimatedSprite2D` (animations from `assets/playersheet.png`) + `CollisionShape2D` + a child `Camera2D` with position smoothing and no limits, so it follows the player anywhere.
- `scenes/level_0.tscn` — the main scene; instances the tilemap layer (with the actual painted `tile_map_data` and per-tile collision polygons overridden locally) and the player. It is the first level, 215×61 tiles: a cave that drops to a deeper cavern, then climbs out into an open-air hillside with clouds. Rock is 18 tiles thick at each end and 12+ below, so the limitless camera never shows past the map; the sky section is open at the top. `README.md` describes its sections and the design rules (2-tile steps, 3-tile gaps) inherited from the earlier, now-deleted levels.
- `scenes/level_1.tscn` — the second level, 240×104 tiles, built the same way as `level_0.tscn` (same node layout, its own copy of the TileSet with collision polygons). Entirely underground: three tiers joined by two one-way wells, running right, right, then back left to a door at the bottom. Rock is 18+ tiles thick on every side. It is not linked from `level_0.tscn` yet; run it directly.
- `scenes/enemy.tscn` — `AnimatableBody2D` + `scripts/enemy.gd`. Patrols right from its placed position by `patrol_distance` px and back at `speed`; no gravity or wall checks, so place it on flat ground. It is on collision layer 2 ("hazards") only, so the player's Hurtbox kills on touch and it never blocks movement. Instances live under the `Enemies` node in `level_0.tscn`.
- `scenes/jumper.tscn` — `CharacterBody2D` + `scripts/jumper.gd`. Cannot walk; rests, crouches (`windup_time`), then leaps in a fixed-height arc aimed at the player's current x, capped at `max_jump_distance`. Only acts within `detect_range`. Layer 2 ("hazards"), mask 1 ("world"). Finds the player via the `player` group on the root of `player.tscn`.
- `scenes/level_2.tscn` — the third level, 250×42 tiles, same node layout as the other levels. A linear, open-air, left-to-right course in the style of the old levels: one ground slab with raised blocks, spike pits, thin platforms and an 18-tile cliff at each end. It introduces shooters. Not linked from the other levels; run it directly.
- `scenes/level_3.tscn` — the fourth level, 280×47 tiles, same node layout and open-air style as `level_2.tscn`. Its only enemies are nine shooters. Layouts not used elsewhere: 2-tile cover walls, rock pillars over a pit, floating 2-thick rock slabs (some with shooters on top), an open-air zigzag climb, and a slab with a low tunnel underneath as an alternative route. Not linked from the other levels; run it directly.
- `scenes/shooter.tscn` — `CharacterBody2D` + `scripts/shooter.gd`. While the player is within `detect_range` it walks towards them at `move_speed` (stopping `stop_distance` short, and at ledges via a `test_move` probe), and every `fire_interval` it stands still, flashes red for `windup_time`, then instances `scenes/projectile.tscn` as a sibling, aimed at the player. Layer 2 ("hazards"), mask 1 ("world").
- `scenes/projectile.tscn` — `CharacterBody2D` + `scripts/projectile.gd`. Flies straight with no gravity while its sprite spins; frees itself when `move_and_collide` hits terrain or after `lifetime`. Layer 2 ("hazards") so the Hurtbox kills on touch, mask 1 ("world").
- `scenes/door.tscn` — `Area2D` (mask 4, "player") + `Sprite2D` + `scripts/door.gd`. The goal door as a self-contained object: the sprite is a 16×16 region of `assets/tilemap.png`, and pressing `interact` inside the area swaps it to the open-door region and shows the "Thanks for playing!" message. Its origin is the centre of the door, so it stands on the floor when placed on a tile corner. It is not painted in the TileMapLayer.

**Collision shapes live in each level scene (`level_0.tscn` to `level_3.tscn`), not in `tile_map_layer.tscn`.** The shared scene's TileSet has an empty physics layer; each level's instance overrides the atlas source with `physics_layer_0/polygon_0/points` per tile. Editing collision for the terrain means editing every level scene's TileSet, not the reusable one.

**Player layer:** the player body is on physics layer 3 ("player"), not layer 1, so enemies that collide with the world (the jumper) pass through the player instead of landing on its head; contact is detected only by the Hurtbox.

**Hazards:** physics layer 1 ("world") is solid terrain; layer 2 ("hazards") is for things that kill. TileSet `physics_layer_1` has `collision_layer = 2`, and the spike tile `0:5` has a shape only on that layer, so spikes never block movement. The player's `Hurtbox` (`Area2D`, mask 2) calls `die()` in `player.gd`, which reloads the current scene. Don't set `monitorable = false` on the Hurtbox: in Godot's physics that silently stops an Area2D from detecting static bodies such as TileMapLayer colliders.

## Input

Gameplay uses custom actions defined under `[input]` in `project.godot` — `move_left`, `move_right`, `jump` — each bound to keyboard (arrows + WASD) and gamepad (D-pad, left stick, A/Cross). Deadzone is 0.2. Deliberately *not* the built-in `ui_*` actions, which double as UI focus navigation and carry a 0.5 deadzone tuned for menus.

Two non-obvious things when adding more bindings:

- **Joypad events need `device = -1`** ("any device"). A fresh `InputEventJoypadButton` defaults to `device = 0`, which binds to joypad slot 0 only and silently fails for a controller that enumerates as device 1. Keyboard events default to `device = 16`, which is correct as-is.
- Godot 4.7's built-in `ui_accept` has **no** joypad binding (only Enter/Kp Enter/Space), while `ui_left`/`ui_right` *do* ship with D-pad and stick bindings. Don't assume `ui_*` gives uniform controller coverage.

Rather than hand-writing the verbose serialized `Object(InputEvent...)` blobs in `project.godot`, add actions via a throwaway `SceneTree` script run with `--headless -s`, using `ProjectSettings.set_setting("input/<action>", {"deadzone":…, "events":[…]})` then `ProjectSettings.save()`. That lets the engine do the serialization. Verify with `InputMap.action_get_events()` and delete the helper script afterward.

## Conventions

- `.godot/` is gitignored and regenerated; never hand-edit files under it. `.uid` files next to scripts and `.import` files next to assets *are* tracked — keep them alongside their source file when moving things.
- `.gd` files use **tab** indentation (Godot's convention); `.editorconfig` only sets UTF-8 and `eol=lf` is enforced via `.gitattributes`.
- `.tscn` files are text and readable, but node `unique_id`s and `uid://` references are engine-managed — prefer editing scenes in the editor over patching them by hand, and never renumber a `uid://`.
