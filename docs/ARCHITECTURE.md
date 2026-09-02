# Architecture

How the code fits together. Kept current per `CLAUDE.md` section 11; update this file in the
same commit as any change that adds or reshapes a system.

---

## Autoloads

Three of the four permitted autoloads exist. `AudioManager` is reserved but not added; audio
bus routing and volume currently live in `SettingsSystem` instead, which does not require an
autoload.

- **`GameState`** (`src/autoload/game_state.gd`): the in-memory shape of a run. Chapter, flags,
  pronoun, player-authored tokens, and the Phase 0 systems' mutable state (hunger, hydration,
  debt, cash, skills, letters, current day, map stage). Owns none of the logic that changes
  these values, only the values themselves plus `to_save_dict()` / `from_save_dict()`.
- **`SaveManager`** (`src/autoload/save_manager.gd`): reads and writes the versioned save file
  at `user://save.json`. Delegates the actual state shape to `GameState`.
- **`EventBus`** (`src/autoload/event_bus.gd`): the signal hub. Systems that need to react to
  something in another system connect to a signal here rather than reaching into that system's
  node tree or polling it every frame.

## Static-dispatch systems

Everything under `/src/systems` that is not a `Node` follows one pattern, established by
`EventRegistry` and used for every Phase 0 gameplay system since: a `class_name Foo extends
RefCounted` with only `static func` methods, operating on `GameState` fields and firing
`EventBus` signals. No instance is ever created. This exists specifically so gameplay systems
do not need to become autoloads: `UpkeepSystem`, `DebtSystem`, `SkillSystem`, `CalendarSystem`,
`LetterSystem`, `MapSystem`, `SettingsSystem`, `FootstepBank` are all this shape. Static
`RefCounted` classes that cache parsed JSON also use a `static var` cache (`_definitions`,
`_manifest`, `_fonts_data`) so the file is only read once per process, following the pattern
`BitmapFont` established first.

A `Node`-based system (`FootstepSystem`, `RoomTransitionController`) exists only when the
system needs `_process`/`_physics_process`, a place in the scene tree, or `@export` wiring from
the editor. These still delegate their actual data and rules to a static-dispatch class where
one exists (`FootstepSystem` reads from `FootstepBank`, not from the JSON directly).

## Data flow

`/data` holds authored content as JSON: dialogue, letters, trades, footstep manifests. Nothing
in `/src` hardcodes a line of dialogue, a letter's category, a trade's cap, or an audio file
path; a static-dispatch system reads the relevant JSON file into a `static var` cache and
answers questions about it. Adding new content (a new letter type, a new trade) means adding a
row to the JSON file, not touching the system's code.

## Dialogue

`DialogueRunner` walks a dialogue JSON file node by node. `DialogueBoxController` listens to its
signals (`node_shown`, `choice_shown`, `dialogue_finished`) and decides which of four panels
(dialogue / thought / empty / document) is visible, driving the character-reveal timer.
`TokenResolver` resolves pronoun and player-authored tokens against `GameState` before text
reaches the label. `EventRegistry` is the static dispatch table `event` nodes call into. All
five are independent; the controller is the only one that touches UI nodes directly.

Text reveal speed (`DialogueBoxController.CHAR_INTERVAL`, ~30 chars/sec) is the design floor
per `docs/STORY.md`'s "slow default, skippable." `SettingsSystem.get_text_speed_multiplier()`
can only speed this up (1.0 to 2.5x), never slow it below the authored pace; the punctuation
pauses (`COMMA_PAUSE`, `PERIOD_PAUSE`, `ELLIPSIS_PAUSE`) are untouched by the multiplier so the
authored silences survive a faster setting.

## Rendering text

There is no engine `Font` resource in use anywhere. `BitmapFont` (`src/core/bitmap_font.gd`)
reads a glyph grid from `assets/fonts/fonts.json` per named face (`dialogue`, `institutional`);
`BitmapLabel` (`src/ui/bitmap_label.gd`) blits the glyph pixels as 1x1 rects at a chosen colour.
Every pixel-art text surface in the game (dialogue, documents, stat screens, the settings menu,
kitten naming) is a `BitmapLabel`, never a `Label` or `RichTextLabel`. "Handwriting" is not a
third face: it is the `dialogue` face plus `BitmapLabel.wobble_amplitude` (deterministic
per-character vertical wobble) and the pencil colour (`Palette.WALNUT`, palette index 03).

## Entities

`Player` (`src/entities/player/player.tscn`) is a `CharacterBody2D` composed of a
`PlayerController` (movement), `HeightComponent` (visual Y offset for jumps/height without
moving the collision shape or ground position), `ShadowComponent` (a contact shadow anchored to
the entity's ground position, independent of the height offset), `CameraController` (smoothed
follow), and `FootstepSystem` (distance-triggered per-surface audio). The same composition
(shadow + height + footsteps) is intended for any future NPC or cat entity, not just the player.

`HeightComponent`'s one child, `Visual`, is an `AnimatedSprite2D` driven by
`CharacterAnimator` (`src/entities/player/character_animator.gd`), which switches between its
`idle` and `walk` animations based on `PlayerController.is_moving()`. The frames come from
`src/entities/player/jack16.tres`, a `SpriteFrames` resource pointing at
`assets/sprites/characters/jack16/`. Those PNGs are not hand-drawn: they are rendered by
`design-export/src/mon-art.js`'s `characterAnimFrame()`/`characterAnimFrames()`, which extend
the same `figure()` silhouette engine that draws every construction sprite with per-frame limb
offsets (`figureAnim()`, `idleFrames()`, `walkFrames()`) rather than a second, hand-authored
animation pipeline. Coverage is down-facing only: `figure()` draws no facial features at this
scale, so an "up" (back) view would be pixel-identical to "down", and "left/right" would need a
genuine profile silhouette rather than a mirrored guess, so those were not invented. `jack16` is
the only state copied into `assets/sprites/` and wired into a scene, since it is the only one
any scene currently needs. `jack9`, `jack15`, `jack16wet`, and `jack18` have verified frames
generated the same way, sitting in `design-export/assets/characters/anim/` alongside the rest
of that folder's construction art, not yet promoted to `assets/sprites/` since no age-swap
system exists yet to select between them at runtime. See `testing/todos.md` F-026 for exact
per-state status.

## Settings

`SettingsSystem` (`src/systems/settings/settings_system.gd`) persists to a separate
`user://settings.json`, deliberately not part of the gameplay save (`SaveManager`): settings
survive a new game and are not part of a run's state. It owns three things: audio bus volume
(`Master`/`Music`/`SFX`, defined in `assets/audio/default_bus_layout.tres` and referenced from
`project.godot`'s `[audio]` section), the text-speed multiplier, and key rebinding (primary key
only, per action, for the actions listed in `SettingsSystem.REBINDABLE_ACTIONS`; joypad bindings
are not currently rebindable through this system). `SettingsMenuController`
(`src/ui/settings_menu_controller.gd`) is the only thing that calls its setters; every other
system that cares about a setting (dialogue speed, footstep volume via the `SFX` bus) reads it
directly rather than caching a copy.

## Input

`project.godot`'s `[input]` section defines the action set: `move_up/down/left/right`,
`interact`, `advance_dialogue`, `skip_text`, `open_map`, `pause`. Every action has both a
keyboard and a joypad binding (D-pad for movement, face/shoulder/back buttons for the rest;
analog stick input is not mapped). No UI in the game reads a raw key or button directly; all
input goes through the action layer, which is what makes key rebinding possible without
touching any consuming script.

## Testing

`tests/lint_dialogue.gd` runs standalone via `godot --headless --script`, since it only reads
JSON off disk and never touches an autoload. Everything else that needs verifying reads or
writes `GameState`, `SaveManager`, or `EventBus`, and autoloads only initialise when the engine
boots a project normally, not under `--script`. `tests/system_tests.gd` is a `Node` script run
as an actual scene instead (`godot --headless --path . res://tests/system_tests.tscn`), which
gets autoloads for free without touching `project.godot`'s configured main scene. It resets
`GameState` to known values, backs up and restores the real `user://save.json` and
`user://settings.json` so a test run never leaves stray data behind, then exercises
`TokenResolver`, `GameState`'s token sanitiser, `SaveManager`'s round trip, and every Phase 0
static-dispatch system (`UpkeepSystem`, `DebtSystem`, `SkillSystem`, `LetterSystem`,
`CalendarSystem`, `MapSystem`, `SettingsSystem`, `EventRegistry`), including their zero/cap/
clamp edge cases and the invalid-input paths that are supposed to `push_error` rather than
corrupt state. It exits 1 on any failed check, so it can gate a commit the same way the dialogue
linter does. Neither test replaces actually opening the editor: both run under `--headless`,
which cannot produce a real frame, so no on-screen layout or pixel output is covered by either.

## What does not exist yet

Down-facing idle/walk animation exists only for the player, only for Jack, and only from the
front (see Entities above); no up/left/right facing, no NPC or cat entity scripts or animation,
no run/carry/work/sit cycles, no room/interior rendering, no inventory or HUD scene.
`LetterSystem` and `MapSystem` are fully built and verified at the data/logic level but have no
visible presentation, since the room and HUD scenes they would render into do not exist. See
`testing/todos.md` for the full account of what is and is not built, and
`testing/art-asset-inventory.md` for what art exists to build against.
