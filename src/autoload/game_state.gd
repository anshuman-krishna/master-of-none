extends Node
# owns: the in-memory shape of a run: chapter, flags, pronoun choice, player-authored tokens
# does not own: persistence (see SaveManager), dialogue rendering, or UI

enum Pronoun { BOY, GIRL }

const MAX_TOKEN_LENGTH: int = 16
const KITTEN_TOKEN_KEYS: Array[String] = ["kitten_1", "kitten_2", "kitten_3"]

var current_chapter: int = 0
var pronoun: Pronoun = Pronoun.BOY
var flags: Dictionary = {}
var player_tokens: Dictionary = {}

func set_pronoun(value: Pronoun) -> void:
	pronoun = value

func set_flag(flag_name: String, value: Variant) -> void:
	flags[flag_name] = value
	EventBus.flag_changed.emit(flag_name, value)

func get_flag(flag_name: String, default_value: Variant = false) -> Variant:
	return flags.get(flag_name, default_value)

func set_chapter(chapter: int) -> void:
	current_chapter = chapter
	EventBus.chapter_changed.emit(chapter)

## sanitises and stores a player-authored token (kitten names, the invented surname).
## strips control characters, caps length, rejects an empty result.
func set_player_token(token_key: String, raw_value: String) -> bool:
	var cleaned: String = _sanitise_player_text(raw_value)
	if cleaned.is_empty():
		return false
	player_tokens[token_key] = cleaned
	return true

func get_player_token(token_key: String) -> String:
	return player_tokens.get(token_key, "")

func _sanitise_player_text(raw_value: String) -> String:
	var result: String = ""
	for character in raw_value:
		var code: int = character.unicode_at(0)
		# strip control characters (below 0x20, and DEL)
		if code < 0x20 or code == 0x7f:
			continue
		result += character
	result = result.strip_edges()
	if result.length() > MAX_TOKEN_LENGTH:
		result = result.substr(0, MAX_TOKEN_LENGTH)
	return result

func to_save_dict() -> Dictionary:
	return {
		"current_chapter": current_chapter,
		"pronoun": pronoun,
		"flags": flags,
		"player_tokens": player_tokens,
	}

func from_save_dict(data: Dictionary) -> void:
	current_chapter = data.get("current_chapter", 0)
	pronoun = data.get("pronoun", Pronoun.BOY) as Pronoun
	flags = data.get("flags", {})
	player_tokens = data.get("player_tokens", {})
