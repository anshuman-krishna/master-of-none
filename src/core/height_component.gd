class_name HeightComponent
extends Node2D
# owns: offsetting a visual node upward from the ground to fake height on the 3/4 angle,
#   per DESIGN.md section 2b. the entity's own Y position is what determines sort order and
#   where the shadow lands; this only ever moves the visual, never the entity itself.
# does not own: the contact shadow sprite, or y-sort configuration (set y_sort_enabled on the
#   parent that holds every entity sharing a ground plane, not on this node)

@export var visual: Node2D
@export var height_px: float = 0.0:
	set(value):
		height_px = value
		_apply_offset()

func _ready() -> void:
	if visual == null and get_child_count() > 0:
		visual = get_child(0) as Node2D
	_apply_offset()

func set_height(new_height_px: float) -> void:
	height_px = new_height_px

func _apply_offset() -> void:
	if visual != null:
		visual.position.y = -roundi(height_px)
