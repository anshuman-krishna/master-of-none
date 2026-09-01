class_name TallPropOcclusionArea
extends Area2D
# owns: fading an occludable entity's visual to a partial, never-zero alpha when it enters this
#   area, and back to opaque on exit, per DESIGN.md's tall-prop rule ("~60% transparency when
#   the player is behind a tall prop, 0.15s fade, never fully invisible"). attach this to any
#   tall prop's "behind" footprint.
# does not own: which props are tall, or where their occlusion footprint sits, since that is a
#   per-prop scene decision that depends on art that does not exist yet (see testing/todos.md
#   F-025). does not own placing or drawing the prop itself.

const OCCLUDED_ALPHA: float = 0.4
const FADE_DURATION: float = 0.15
const OCCLUDABLE_GROUP: String = "occludable"

var _active_tweens: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(OCCLUDABLE_GROUP):
		_fade_target(body, OCCLUDED_ALPHA)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(OCCLUDABLE_GROUP):
		_fade_target(body, 1.0)

func _fade_target(body: Node2D, target_alpha: float) -> void:
	var visual: Node2D = _find_visual(body)
	if visual == null:
		return
	if _active_tweens.has(body) and is_instance_valid(_active_tweens[body]):
		(_active_tweens[body] as Tween).kill()
	var tween: Tween = create_tween()
	tween.tween_property(visual, "modulate:a", target_alpha, FADE_DURATION)
	_active_tweens[body] = tween

## the shadow never fades: only the height-offset visual does, so the entity stays
## grounded-legible even at 40% opacity rather than vanishing into the prop entirely
func _find_visual(body: Node2D) -> Node2D:
	var height_component: HeightComponent = body.get_node_or_null("HeightComponent") as HeightComponent
	if height_component != null and height_component.visual != null:
		return height_component.visual
	return null
