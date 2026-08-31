extends Node
# owns: signal definitions used for cross-system communication
# does not own: game state, save data, or any node reference

signal day_advanced(day: int)
signal flag_changed(flag_name: String, value: Variant)
signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal upkeep_changed(hunger: float, hydration: float)
signal letter_received(letter_id: String)
signal letter_opened(letter_id: String)
signal skill_changed(skill_id: String, level: int)
signal chapter_changed(chapter: int)
