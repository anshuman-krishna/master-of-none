# Systems

Mechanical specs as they get locked. Where `docs/STORY.md` states a rule directly, that rule is
locked and this file just points at it. Where a system needed a specific number and
`docs/STORY.md` only gives a qualitative description, the current value is a **placeholder**,
implemented and functional but not balance-tested; those are marked explicitly below and should
not be read as final.

---

## Upkeep

Source: `docs/STORY.md`, "Upkeep." Hunger and hydration are modifiers, not a health bar; zero
state triggers collapse, never death.

Locked: collapse resets both stats and schedules a `clinic_bill` letter arriving eleven days
later ("you collapse, you wake in a clinic, and eleven days later a letter arrives").

Placeholder (`src/systems/upkeep/upkeep_system.gd`):

| constant | value |
|---|---|
| `HUNGER_DECAY_PER_DAY` | 18.0 |
| `HYDRATION_DECAY_PER_DAY` | 24.0 |
| `LOW_THRESHOLD` | 30.0 (below this, action speed and skill-check odds scale down) |
| `COLLAPSE_RECOVERY_VALUE` | 45.0 (both stats reset to this on collapse) |
| `COLLAPSE_LETTER_DELAY_DAYS` | 11 (locked, from STORY.md) |

The below-threshold modifier is `lerpf(0.5, 1.0, lowest_stat / LOW_THRESHOLD)`: at zero it is a
50% penalty, scaling linearly back to no penalty at the threshold. The 50% floor itself is a
placeholder.

## Debt / economy

Source: `docs/STORY.md`: "Compounding but survivable. Debt closes options rather than ending
runs. There should be a floor below which the game becomes very hard and very sad but never
unwinnable."

Placeholder (`src/systems/economy/debt_system.gd`):

| constant | value |
|---|---|
| `DAILY_INTEREST_RATE` | 0.01 (1% daily compounding) |
| `TIER_THRESHOLDS` | [0, 100, 400, 1000] |

`get_debt_tier()` returns which band the current debt sits in; nothing currently reads the tier
to actually close an option, since no shop/job system exists yet to close. The floor STORY.md
describes is not yet implemented as a hard mechanical clamp, since it depends on which specific
options should stay open at maximum debt, which is a Chapter 1/2 content decision.

## Trades / skills

Source: `docs/STORY.md`: every trade sits at a soft cap of 70 to 85; the capped bar reads
"mastery: requires certification."

Locked: the ten trades (`data/trades/trades.json`) are exactly the list in STORY.md section 8:
carpentry, joinery, wiring, plumbing, cooking, bookkeeping, negotiation, cycling, fishing,
repair. The cap band (70-85) is locked.

Placeholder: the specific cap assigned to each trade within that band (currently 70-85,
distributed by hand, no two trades sharing a rationale beyond "somewhere in the locked range").
Which trades feel more or less capped is a balance question, not a narrative one.

## Letters

Source: `docs/STORY.md` / `data/letters/letters.json`. Eight envelope designs exist; each is
locked to a category and a `good_news` flag. The mapping from envelope art to category is fixed
by filename (`clinic-bill.png` is the clinic bill, etc.) except `good-news.png`, whose
assignment as the literal good-news envelope is a judgment call documented in
`testing/open-questions.md` item 5, trivially reassignable if the project owner picks
differently.

## Map

Source: `docs/STORY.md`. Locked: the map's home-corner refuses to open before Chapter 5 and
unlocks exactly at it (`MapSystem.HOME_CORNER_CHAPTER = 5`). The refusal line itself is
narrative content and is not written here; `MapSystem.try_open_home_corner()` only returns
whether the corner is allowed to open.

## Calendar

`CalendarSystem.advance_day()` is the single entry point that ticks upkeep, debt, and letter
delivery together, then dispatches any events scheduled for that day through the same
`EventRegistry` dialogue events already use. No system should tick upkeep or debt on its own;
everything routes through one day-advance call so the three stay in sync.

## Settings

Not gameplay-facing, but locked here since a player who wants to reset the game expects them to
survive it: `SettingsSystem` writes to `user://settings.json`, separate from `SaveManager`'s
`user://save.json`. Text-speed floor of 1.0x (the design floor, ~30 chars/sec) is locked; the
2.5x ceiling is a placeholder.

## Footstep audio

Placeholder end to end. `data/audio/footsteps.json` maps four surfaces (wood, grass, stone,
water) to three procedurally synthesised clips each. `FootstepSystem.STEP_DISTANCE_PX = 10.0`
triggers a step by distance travelled, not by animation frame, since no walk cycle exists yet
(see `testing/todos.md` F-026). Re-derive this trigger from animation frames once that lands;
the distance-based trigger is a stopgap, not a design decision.
