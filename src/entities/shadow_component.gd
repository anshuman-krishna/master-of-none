class_name ShadowComponent
extends Sprite2D
# owns: drawing one entity's soft contact shadow at its base per DESIGN.md ("every character,
#   cat and freestanding prop gets a soft elliptical shadow at its base, drawn in the cool
#   neutral range at low opacity, never pure black")
# does not own: height offset (see HeightComponent, a sibling, not a parent of this node) or
#   y-sort configuration (set y_sort_enabled on the shared parent that holds every entity on a
#   ground plane, this node never touches sort order itself)

const SHADOW_TEXTURE_PATH: String = "res://assets/sprites/shadow.png"

func _ready() -> void:
	if texture == null:
		texture = load(SHADOW_TEXTURE_PATH)
	# the shadow always sits on the ground plane at y = 0 relative to the entity root,
	# never following HeightComponent's upward visual offset
	position = Vector2.ZERO
