# Master of None

A 3/4 top-down pixel art narrative life sim, built in Godot 4, about a mute teenager who runs away from home with one kitten and spends years learning trades he will never be allowed to master.

![Pond at sunset, from the reference art](docs/media/pond-sunset.png)

## Content warning

This game deals with sustained emotional abuse of a child by his parents, the death of animals, and a subplot involving drug delivery that puts a minor in danger. All of it is handled off screen or at a distance: there is no on-screen violence, no depicted animal death, and no depiction of drug use. Scenes that touch these subjects use silhouette, sound at a distance, and hard cuts rather than showing the event itself. If any of this would be difficult for you, please take care. If it sounds like the kind of thing you'd want handled with care rather than avoided, that's the intent.

---

## For players

### What it is

Master of None follows a teenager, called Jack regardless of whether the player picks the boy or the girl, who grows up in a small, quiet, unhappy household by a lake. He does not speak for the first sixteen years of his life, not because he cannot, but because his house never gave him a reason that felt safe. At sixteen, after a night that costs him almost everything he cares about, he leaves, taking one surviving kitten with him, and walks into a town he has never seen.

What follows is not a rescue story. Jack finds someone willing to teach him a trade, and the game becomes about the specific, unglamorous work of learning to be useful: carpentry, a paper route, keeping a cat fed, reading a ledger. There is no combat, no game over, and no boss fight standing between Jack and anything he wants. The obstacles are structural: money, time, and the fact that a sixteen-year-old with no paperwork is, in the eyes of every institution he meets, functionally invisible. Debt and hardship close doors in this game. They never end it.

The tone sits somewhere between Stardew Valley's readability and Night in the Woods' willingness to sit with something sad without resolving it.

### Scope

Chapters 0, 1 and 2 are being built as a complete, standalone game with a real beginning and end. Chapters 3 through 5 are outlined in the story bible and are not being built, stubbed, or scaffolded until the first three chapters ship.

### Screenshots and art

All art below is early reference and construction work, not final in-game assets. It locks silhouette, height, palette and posture; a finishing pass replaces the pixels without changing the shapes.

**Characters and cast**

| | |
|---|---|
| ![Jack across four ages, alongside the father](docs/media/lineup-ch0.png) **Jack, across the ages the story covers, next to the father.** Same silhouette weight and clothing for the boy and girl versions, on purpose. | ![Portrait sheet](docs/media/portrait-sheet.png) **Dialogue portraits.** 48x48, one shared frame geometry for every character who speaks. |

**Environments**

| | |
|---|---|
| ![Fen's carpentry shop](docs/media/fen-shop.png) **Fen's carpentry shop.** The tool wall is deliberately half-empty: the missing tools are the ones currently in someone's hands. | ![The room under the stairs, bare state](docs/media/under-stair-0.png) **The room under the stairs**, in its bare first state. It gets furnished, one small piece at a time, without ever getting bigger. |

**Objects and UI**

| | |
|---|---|
| ![The hand-drawn paper map](docs/media/map-stage-3.png) **The paper map**, drawn in Jack's own handwriting and expanded as he travels. The bottom-left corner stays folded for most of the game. | ![Fen's toolbox](docs/media/toolbox-open.png) **Fen's toolbox.** Old and well kept, not broken. It carries the crafting system for the rest of the game. |
| ![The dialogue box](docs/media/dialogue-box.png) **The dialogue box**, paper-toned, bottom third of the screen only. All spoken dialogue in the game is lowercase. | ![The thought box](docs/media/thought-box.png) **The thought box.** Purple, no portrait, Jack's interior voice. This carries most of Chapter 0, since he cannot speak for the first stretch of it. |
| ![The memory frame](docs/media/memory-frame.png) **The memory frame**, used for flashbacks. A soft cloud-edge vignette rather than a hard cut. | |

### Current state, for players

There is nothing playable yet. Early engine and systems work is underway (see below for developers), but there is no build, no demo, and no estimated release date. This section will be replaced with real instructions the moment there is something to run.

---

## For developers

### Tech

| | |
|---|---|
| Engine | Godot 4.7.2, stable channel, pinned |
| Language | GDScript, statically typed throughout |
| Dialogue and save data | Plain JSON, parsed with Godot's built-in `JSON` class |
| Version control | Git, with Git LFS for binary art and audio |

The game ships with no third-party runtime dependencies: no plugins, no C#, no external dialogue engine. This is a deliberate choice. A public repository is something a reader has to evaluate, and a project with zero third-party runtime code is one fewer thing to trust blindly.

### Engineering status

The foundation layer is in place and has been run against the actual engine, not just written:

- Project boots cleanly under `godot --headless`, autoloads included, with no errors or warnings.
- Core autoloads: `GameState` (chapter, flags, pronoun choice, player-authored tokens), `SaveManager` (JSON save/load with a versioned schema), `EventBus` (cross-system signals).
- A token resolver handles pronoun substitution and player-authored text (kitten names, an invented surname) in one pass, with correct lowercase-in-dialogue behaviour.
- A dialogue JSON runner walks all nine node types the format defines (`say`, `think`, `mute`, `choice`, `document`, `set`, `branch`, `event`, `end`), verified end to end against a sample scene.
- A standalone dialogue linter (`tests/lint_dialogue.gd`) checks every dialogue file for lowercase violations, hardcoded pronouns outside tokens, dangling links, unreachable nodes, and unregistered events, and has been proven to actually catch each of those, not just pass a clean file.
- A closed 44-colour palette is defined once, in `assets/palette.gpl`, `assets/palette.json`, and as engine constants.
- A minimal player controller (4-direction movement, pixel snapping) and a height component (the fake-depth system the art style depends on) exist and run without error, though nothing is on screen yet since no animated sprite exists.

Nearly everything visible is not built yet: no dialogue UI, no rendered environments, no character animation. That work is tracked outside the public history, since it changes daily and isn't useful to a reader here.

### Project structure

```
/
  project.godot          the Godot project
  docs/
    STORY.md               the story and systems bible
    DIALOGUE_FORMAT.md      the dialogue JSON schema and pronoun token reference
    media/                  images used by this README, tracked in git
  assets/                 production art, fonts, and the closed palette, loaded at runtime
  data/                   authored content as JSON: dialogue, NPCs, jobs, letters, items
  src/
    autoload/               the three global singletons: GameState, SaveManager, EventBus
    core/                   engine-level helpers with no game rules (palette, height component)
    entities/               player, NPC and cat scenes and scripts
    systems/                one folder per system: dialogue, upkeep, economy, and so on
    scenes/                 per-chapter scenes
    ui/                     interface code
  tests/                  the dialogue linter and any future automated checks
  ideation/               raw design and story drafts, not tracked in git
  design-export/          reference art from the design pipeline, not tracked in git
```

`ideation/` and `design-export/` are gitignored on purpose. Nothing in either is loaded at runtime; production assets get drawn or rebuilt into `assets/` deliberately, matching the silhouette, height and palette the reference art locks in.

### How to run it from source

1. Install [Godot 4.7.2](https://godotengine.org/download), stable channel.
2. Install Git LFS and initialise it for this repository:
   ```
   brew install git-lfs        # or your platform's equivalent
   git lfs install --local
   ```
3. Clone this repository and open it in Godot, or run it headless to confirm it boots:
   ```
   git clone <repository-url>
   cd master-of-none
   godot --headless --path . --quit-after 10
   ```
4. There is no playable content yet, so the above confirms the engine boots and the autoloads initialise. Opening the project in the Godot editor (`godot --editor --path .`) is the way to actually look around.
