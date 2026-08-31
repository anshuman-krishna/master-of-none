class_name BitmapLabel
extends Node2D
# owns: drawing one line of text with a BitmapFont face, one 1x1 rect per lit pixel, no
#   anti-aliasing and no scaling, per DESIGN.md section 3
# does not own: text reveal pacing (visible_characters is a dumb clamp; something else drives
#   it upward over time), word wrap (authoring keeps lines short enough that none is needed)

@export var face_name: String = "dialogue":
	set(value):
		face_name = value
		_reload_font()

@export var text: String = "":
	set(value):
		text = value
		queue_redraw()

@export var color: Color = Color.BLACK:
	set(value):
		color = value
		queue_redraw()

## -1 shows the full string. any other value clamps how many characters are drawn, for a
## typewriter-style reveal driven by whatever owns this label.
@export var visible_characters: int = -1:
	set(value):
		visible_characters = value
		queue_redraw()

## jack's handwriting is the dialogue face plus this deterministic vertical wobble, not a
## separate alphabet. 0 disables it (flat dialogue/document text), 1 is normal handwriting,
## 2 is a shaking hand. seed varies the wobble pattern between separate labels so they do not
## all wobble in lockstep; the same text plus the same seed always wobbles identically.
@export var wobble_amplitude: int = 0:
	set(value):
		wobble_amplitude = value
		queue_redraw()

@export var wobble_seed: int = 7:
	set(value):
		wobble_seed = value
		queue_redraw()

## the thought box's bitmap italic: each glyph's rows shift right in three steps (2px for the
## top third, 1px for the middle third, 0px for the bottom), never a true skew transform.
@export var italic: bool = false:
	set(value):
		italic = value
		queue_redraw()

var _font: BitmapFont

func _ready() -> void:
	_reload_font()

func get_line_width() -> int:
	if _font == null:
		return 0
	return _font.measure_width(text)

func _reload_font() -> void:
	_font = BitmapFont.new()
	_font.load_face(face_name)
	queue_redraw()

func _draw() -> void:
	if _font == null:
		return
	var shown: String = text
	if visible_characters >= 0 and visible_characters < text.length():
		shown = text.substr(0, visible_characters)

	var pen_x: int = 0
	for char_index: int in range(shown.length()):
		var character: String = shown[char_index]
		var row_offset: int = 0
		if wobble_amplitude != 0:
			# matches design-export/src/mon-art.js drawText(): truncation toward zero, not
			# floor, so this uses int() rather than floori() to stay bit-for-bit consistent
			# with the reference art generator's own wobble.
			row_offset = int(sin(float(char_index + wobble_seed) * 2.399) * wobble_amplitude + 0.5)
		var rows: Array = _font.rows_for(character)
		for row_index: int in range(rows.size()):
			var row: String = rows[row_index]
			var italic_shift: int = (2 - int(row_index / 3.0)) if italic else 0
			for col_index: int in range(row.length()):
				if row[col_index] == "#":
					draw_rect(Rect2(pen_x + col_index + italic_shift, row_index + row_offset, 1, 1), color, true)
		pen_x += _font.advance
