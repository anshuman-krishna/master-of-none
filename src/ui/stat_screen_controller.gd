class_name StatScreenController
extends Control
# owns: the trade/skill stat screen. per DESIGN.md, "the stat screen is the theme": every
#   trade sits at a soft cap of 70 to 85, and the capped bar reads "mastery: requires
#   certification" rather than filling further, since certification requires papers jack
#   does not have.
# does not own: what grants skill experience, or when this screen opens (see SkillSystem)

const ROW_HEIGHT: int = 22
const BAR_WIDTH: int = 220
const BAR_HEIGHT: int = 6
const LABEL_X: int = 20
const BAR_X: int = 140
const START_Y: int = 20

func _ready() -> void:
	var trade_ids: Array = SkillSystem.get_trade_ids()
	for i: int in range(trade_ids.size()):
		_build_row(trade_ids[i], START_Y + i * ROW_HEIGHT)

func _build_row(trade_id: String, y: int) -> void:
	var label: BitmapLabel = BitmapLabel.new()
	label.face_name = "institutional"
	label.color = Palette.INK
	label.position = Vector2(LABEL_X, y)
	label.text = SkillSystem.get_display_name(trade_id)
	label.visible_characters = -1
	add_child(label)

	var level: int = SkillSystem.get_level(trade_id)
	var cap: int = SkillSystem.get_cap(trade_id)

	var track: ColorRect = ColorRect.new()
	track.position = Vector2(BAR_X, y)
	track.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	track.color = Palette.STONE
	add_child(track)

	var fill: ColorRect = ColorRect.new()
	fill.position = Vector2(BAR_X, y)
	fill.size = Vector2(BAR_WIDTH * (float(level) / 100.0), BAR_HEIGHT)
	fill.color = Palette.BRASS
	add_child(fill)

	if level >= cap:
		var mastery_label: BitmapLabel = BitmapLabel.new()
		mastery_label.face_name = "institutional"
		mastery_label.color = Palette.CONCRETE
		mastery_label.position = Vector2(BAR_X, y + BAR_HEIGHT + 3)
		mastery_label.text = "mastery: requires certification"
		mastery_label.visible_characters = -1
		add_child(mastery_label)
