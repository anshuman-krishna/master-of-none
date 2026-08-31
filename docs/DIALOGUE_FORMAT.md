# Dialogue Format

The authoring format for all spoken text, thought text and player choices. Files live in `data/dialogue/ch0/`, `ch1/`, `ch2/`. One JSON file per scene.

JSON was chosen over YAML because Godot parses it natively with `JSON.parse_string`, which means zero dependencies in a public repository.

**Do not change this schema without asking.**

---

## File shape

```json
{
  "id": "ch0_kitchen_morning",
  "chapter": 0,
  "location": "home_kitchen",
  "nodes": [ ]
}
```

## Node types

### say

```json
{
  "type": "say",
  "id": "n01",
  "speaker": "father",
  "portrait": "father_neutral",
  "text": "you left the door open again.",
  "next": "n02"
}
```

All `text` in a `say` node is lowercase. The linter enforces this.

### think

Jack's interior voice. Purple frame, no portrait.

```json
{
  "type": "think",
  "id": "n02",
  "text": "i did not.",
  "next": "n03"
}
```

### mute

Chapter 0 only, before Jack speaks. Renders the empty dialogue box with Jack's portrait, holds, then closes. Almost always followed immediately by a `think` node.

```json
{
  "type": "mute",
  "id": "n03",
  "portrait": "jack09_neutral",
  "hold_ms": 1400,
  "next": "n04"
}
```

### choice

```json
{
  "type": "choice",
  "id": "n04",
  "prompt": null,
  "options": [
    { "text": "i can work.", "next": "n05" },
    { "text": "say nothing", "next": "n09", "requires": null }
  ]
}
```

`prompt` is usually null. The dialogue that precedes the choice is the prompt.

### document

Renders in the institutional font, mixed case, in the document frame rather than the dialogue box. Letters, forms, signs, the missing persons poster.

```json
{
  "type": "document",
  "id": "n05",
  "header": "Loden Constabulary",
  "text": "MISSING. Aged 16. Last seen 14th. Any information to this office.",
  "next": "n06"
}
```

Document text is **not** lowercased. This is the only place capitals are allowed.

### set and branch

```json
{ "type": "set", "id": "n06", "flag": "met_fen", "value": true, "next": "n07" }
```

```json
{
  "type": "branch",
  "id": "n07",
  "flag": "met_fen",
  "if_true": "n08",
  "if_false": "n20"
}
```

### event

Hands control to a system: start a cutscene, give an item, advance a day, trigger a letter.

```json
{
  "type": "event",
  "id": "n08",
  "event": "give_item",
  "args": { "item": "toolbox" },
  "next": "n09"
}
```

Event names are registered in `src/systems/dialogue/event_registry.gd`. Adding a new event name requires adding it there in the same commit.

### end

```json
{ "type": "end", "id": "n09" }
```

---

## Pronoun tokens

The player picks boy or girl before Chapter 0. **Boy is Jacob, girl is Jacqueline, both called Jack.** Never write two versions of a line. Use tokens, resolved at render time from one pronoun set stored in the save.

| Token | boy | girl |
|---|---|---|
| `{they}` | he | she |
| `{them}` | him | her |
| `{their}` | his | her |
| `{theirs}` | his | hers |
| `{themself}` | himself | herself |
| `{child}` | son | daughter |
| `{kid_term}` | boy | girl |
| `{full_name}` | Jacob | Jacqueline |

Tokens capitalise from context. A token at the start of a `document` node capitalises. A token anywhere in a `say` or `think` node does not, because all dialogue is lowercase.

`{full_name}` is used **exactly twice in the whole game**, both by the mother, once in Chapter 0 and once in Chapter 5. Both are flagged in the data with `"note": "only full name line"`. Every other reference in every file uses the literal string `jack`, which needs no token at all.

The linter fails any file where `{full_name}` appears outside a node carrying that note.

## Player-authored name tokens

Two things the player types get stored and reused.

**The kitten names**, typed at the grave in Chapter 1. Tokens `{kitten_1}`, `{kitten_2}`, `{kitten_3}`. They appear on the grave marker and once more in Chapter 5. Do not use them anywhere else and do not let any character comment on them.

**The invented surname**, typed on the form in Chapter 3. Token `{surname}`. Out of scope for the first release, but reserve the token now so the save format does not need a migration later.

Sanitise both at input: strip control characters, cap at 16 characters, reject empty. Store raw, render escaped.

## Authoring rules

1. Every `say` and `think` text is lowercase. Only `document` uses capitals.
2. No em dashes anywhere. Use commas, full stops, or ellipses.
3. Node ids are `n01`, `n02` and so on, unique within the file, zero padded.
4. Every node except `end` has a valid `next` or valid branch targets. The linter catches dangling nodes.
5. Speaker ids match a file in `data/npcs/`. Portrait ids match a frame in that NPC's portrait sheet.
6. One line per box. If a line needs two boxes, write two `say` nodes. Do not rely on wrapping to pace a scene.
7. Keep a line under 120 characters. Longer means it should be two nodes.
8. Silence is content. It is correct for a scene to be mostly `mute` and `think` nodes.

---

## Linter

`tests/lint_dialogue.gd` runs over every file in `data/dialogue/` and fails on:

- any capital letter in a `say` or `think` text
- any em dash in any text field
- a dangling `next` target
- an unreachable node
- an unregistered event name
- an unknown speaker or portrait id
- a hardcoded gendered pronoun outside a token, checked against a word list

Run it before every commit. A dialogue commit that fails the linter does not get committed.
