class_name RoomTransitionController
extends CanvasLayer
# owns: the hard-cut black hold between rooms per DESIGN.md ("hard cut with short black
#   hold, no slides/wipes"). the caller swaps scene content during the `hold_reached` signal,
#   while the screen is fully covered.
# does not own: what scene loads next, or how it gets loaded

signal hold_reached
signal transition_finished

const DEFAULT_HOLD_SECONDS: float = 0.3

@onready var _cover: ColorRect = $Cover

func _ready() -> void:
	_cover.color = Palette.NIGHT
	_cover.visible = false

## covers the screen instantly (no fade), holds for hold_seconds while emitting
## hold_reached so the caller can swap scene content, then uncovers instantly.
func cut(hold_seconds: float = DEFAULT_HOLD_SECONDS) -> void:
	_cover.visible = true
	hold_reached.emit()
	await get_tree().create_timer(hold_seconds).timeout
	_cover.visible = false
	transition_finished.emit()
