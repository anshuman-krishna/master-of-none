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

`mute` and `say`/`think` behave differently for whatever is driving the runner: a `mute` node
self-advances after its own `hold_ms` timer, but `say`/`think`/`document` wait for an explicit
`advance()` call and never move on by themselves. In game that call comes from
`DialogueBoxController.handle_advance_input()` on the `advance_dialogue` action; anything else
that drives a `DialogueRunner` (a scene script, a test) has to make that call itself, or the
runner sits on the node forever. `src/scenes/ch0/home.gd` is the first real, in-game consumer of
this whole pipeline (`DialogueRunner` + `DialogueBoxController` + `EventRegistry` wired to an
actual interactable object); everything before it only had `data/dialogue/ch0/sample_scene.json`
and test coverage to exercise it. `EventRegistry` gained `increase_skill` (`{trade, amount}`,
calling `SkillSystem.increase_level()`) for that scene's jeep-repair beat; it is duplicated by hand into
`tests/lint_dialogue.gd`'s own `REGISTERED_EVENTS` (documented there, and in the same file) since
that linter runs via `--script` and cannot touch the autoloads `EventRegistry.dispatch()` needs.

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

`src/entities/npc/` holds the first non-player entities: `father.tscn` and `mother.tscn`. They
reuse `ShadowComponent` and `HeightComponent` exactly as the player does, but sit on a
`StaticBody2D` root rather than a `CharacterBody2D`, since neither moves in the one scene that
uses them, and their `AnimatedSprite2D` just autoplays `idle` with no controller script at all
(no equivalent of `CharacterAnimator` is needed without a walk state to switch into). Each has
its own idle-only `SpriteFrames` resource (`father_idle.tres`, `mother_idle.tres`) generated the
same procedural way as the player's. Extending this to a moving NPC, or to the cats (which also
have verified idle/walk frames sitting unused in `design-export/assets/cats/anim/`, see F-026),
is not built: it would need its own controller, closer to `CharacterAnimator` than to this.

## Interaction

`Interactable` (`src/entities/interactable.gd`) is an `Area2D` that tracks whether the player
(anything in the `"player"` group; `PlayerController` adds itself to it in `_ready()`, the same
place it joins `"occludable"` for F-025) is inside its `CollisionShape2D`, and turns an
`interact` press into one `interacted` signal. It has no opinion on what happens next; a scene
script connects to that signal and decides. It is the first thing in the project that turns a
static room object into something the player can actually act on.

## Rooms

`src/scenes/ch0/home.tscn` is the first real room scene, and establishes the pattern for every
interior to follow: a background `Sprite2D` (a PNG generated by a `mon-art.js` scene function,
positioned at the room's own local origin so art pixels and collision coordinates share one
number line), `StaticBody2D` walls and furniture sized by hand to match that art, `Area2D` door
triggers at the one gap in the wall DESIGN.md allows, and `Interactable`s for anything the player
can act on. Two rooms (`Bedroom`, `Kitchen`) live as sibling `Node2D`s offset far apart in world
space, one `visible` at a time; `src/scenes/ch0/home.gd` swaps which is visible and repositions
the player during `RoomTransitionController`'s `hold_reached` signal, which is what actually
covers the swap, per DESIGN.md's "hard cut, no slide, no wipe." This is `RoomTransitionController`
and `EventRegistry.increase_skill`'s first real caller, and the reason `StatScreenController`
gained a `closed` signal and `PauseMenuController` gained a `stats` row: both existed before with
nothing that actually opened or dismissed them from gameplay.

The bedroom's background (`design-export/src/mon-art.js`'s `sceneHomeBedroom()`) is sized to
DESIGN.md 7b's actual footprint (4x4 tiles, 128x128), not the wider, explicitly-oversized
`sceneJacksRoom()` art-bible composition ("both of these have been drawn too large in reference
art. correct them in engine.") that predates it. The kitchen (`sceneHomeKitchen()`) has no such
reference to correct; its dimensions are a new, deliberately modest call, since no size is
specified anywhere in the design docs.

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

One room pair exists (the Chapter 0 home: bedroom and kitchen) with one interactable object, two
static NPCs, and one dialogue sequence wired end to end; every other room, interior, and NPC in
the game does not. Down-facing idle/walk animation exists only for the player, only for Jack, and
only from the front (see Entities above); no up/left/right facing, no run/carry/work/sit cycles,
no moving NPCs, no cat entities on screen despite the animation existing for them, no inventory
or HUD scene. `LetterSystem` and `MapSystem` are fully built and verified at the data/logic level
but have no visible presentation, since the room and HUD scenes they would render into do not
exist yet. See `testing/todos.md` for the full account of what is and is not built, and
`testing/art-asset-inventory.md` for what art exists to build against.
