class_name BitmapFont
extends RefCounted
# owns: loading one glyph grid ("dialogue" or "institutional") from assets/fonts/fonts.json and
#   answering which pixels are on for a given character. every pixel is drawn as a 1x1 rect by
#   whatever draws with this data; there is no anti-aliasing or scaling step to get wrong.
# does not own: where or in what colour the glyphs get drawn (see BitmapLabel)

const FONTS_PATH: String = "res://assets/fonts/fonts.json"

var cell_width: int = 0
var cell_height: int = 0
var body_width: int = 0
var advance: int = 0
var line_height: int = 0
var lowercase_only: bool = false

var _glyphs: Dictionary = {}

static var _fonts_data: Dictionary = {}

func load_face(face_name: String) -> bool:
	if _fonts_data.is_empty():
		_fonts_data = _read_fonts_json()
	if not _fonts_data.has(face_name):
		push_error("bitmap_font: unknown face '%s'" % face_name)
		return false
	var face: Dictionary = _fonts_data[face_name]
	var cell: String = face.get("cell", "0x0")
	var parts: PackedStringArray = cell.split("x")
	cell_width = int(parts[0]) if parts.size() == 2 else 0
	cell_height = int(parts[1]) if parts.size() == 2 else 0
	body_width = face.get("body", cell_width)
	advance = face.get("advance", cell_width)
	line_height = face.get("lineHeight", cell_height)
	lowercase_only = face.get("case", "") == "lowercase only by design"
	_glyphs = face.get("glyphs", {})
	return true

## returns the glyph's rows as strings of "#" and "." for the given character, or the space
## glyph if the character has no entry, so an unsupported character renders as a gap rather
## than crashing the draw call. typed Array, not PackedStringArray: JSON.parse_string produces
## plain Array values and there is no cheap conversion worth doing here.
func rows_for(character: String) -> Array:
	if _glyphs.has(character):
		return _glyphs[character]
	if _glyphs.has(" "):
		return _glyphs[" "]
	return []

func has_glyph(character: String) -> bool:
	return _glyphs.has(character)

func measure_width(text: String) -> int:
	return text.length() * advance

static func _read_fonts_json() -> Dictionary:
	var file: FileAccess = FileAccess.open(FONTS_PATH, FileAccess.READ)
	if file == null:
		push_error("bitmap_font: could not open %s" % FONTS_PATH)
		return {}
	var raw_text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("bitmap_font: %s did not parse to a dictionary" % FONTS_PATH)
		return {}
	return parsed
