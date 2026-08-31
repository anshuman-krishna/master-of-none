class_name TokenResolver
extends RefCounted
# owns: substituting {token} placeholders in dialogue and document text
# does not own: where the text is displayed, node walking, or the linter's schema checks

const PRONOUN_TABLE: Dictionary = {
	"they": {"boy": "he", "girl": "she"},
	"them": {"boy": "him", "girl": "her"},
	"their": {"boy": "his", "girl": "her"},
	"theirs": {"boy": "his", "girl": "hers"},
	"themself": {"boy": "himself", "girl": "herself"},
	"child": {"boy": "son", "girl": "daughter"},
	"kid_term": {"boy": "boy", "girl": "girl"},
	# stored lowercase on purpose: all spoken dialogue is lowercase with no exceptions, full
	# name included. capitalise_sentences=true (document nodes only) capitalises it like any
	# other token when it happens to open a sentence.
	"full_name": {"boy": "jacob", "girl": "jacqueline"},
}

static var _token_regex: RegEx = _build_regex()

static func _build_regex() -> RegEx:
	var regex: RegEx = RegEx.new()
	regex.compile("\\{(\\w+)\\}")
	return regex

## resolves both pronoun tokens and player-authored tokens (kitten names, surname) in one pass.
## capitalise_sentences should be true for document nodes and false for say/think nodes,
## since all spoken dialogue stays lowercase regardless of sentence position.
static func resolve(text: String, pronoun: int, player_tokens: Dictionary = {}, capitalise_sentences: bool = false) -> String:
	var pronoun_key: String = "boy" if pronoun == 0 else "girl"
	var result: String = text
	var offset_shift: int = 0
	for regex_match in _token_regex.search_all(text):
		var token_name: String = regex_match.get_string(1)
		var replacement: String = _lookup(token_name, pronoun_key, player_tokens)
		if replacement.is_empty() and not player_tokens.has(token_name):
			continue
		var start: int = regex_match.get_start() + offset_shift
		var end: int = regex_match.get_end() + offset_shift
		if capitalise_sentences and _is_sentence_start(result, start):
			replacement = _capitalise_first(replacement)
		result = result.substr(0, start) + replacement + result.substr(end)
		offset_shift += replacement.length() - (end - start)
	return result

static func _lookup(token_name: String, pronoun_key: String, player_tokens: Dictionary) -> String:
	if PRONOUN_TABLE.has(token_name):
		return PRONOUN_TABLE[token_name][pronoun_key]
	if player_tokens.has(token_name):
		return String(player_tokens[token_name])
	return ""

static func _is_sentence_start(text: String, position: int) -> bool:
	if position == 0:
		return true
	var before: String = text.substr(0, position).strip_edges(true, false)
	if before.is_empty():
		return true
	var last_char: String = before[before.length() - 1]
	return last_char == "." or last_char == "!" or last_char == "?"

static func _capitalise_first(value: String) -> String:
	if value.is_empty():
		return value
	return value[0].to_upper() + value.substr(1)
