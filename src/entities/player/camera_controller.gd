class_name CameraController
extends Camera2D
# owns: smoothed, pixel-snapped following of one target, per DESIGN.md section 1 ("pixel
#   snapped, smoothed follow, no sub-pixel drift")
# does not own: what the target is or how it moves

@export var target: Node2D
@export var follow_speed: float = 8.0

## kept at full float precision so the lerp itself stays smooth; only the node's actual
## rendered position gets rounded, each frame, so the camera never sits at a sub-pixel offset.
var _smoothed_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	if target == null:
		target = get_parent() as Node2D
	if target != null:
		_smoothed_position = target.global_position
		global_position = _smoothed_position.round()

func _process(delta: float) -> void:
	if target == null:
		return
	var lerp_weight: float = clampf(follow_speed * delta, 0.0, 1.0)
	_smoothed_position = _smoothed_position.lerp(target.global_position, lerp_weight)
	global_position = _smoothed_position.round()
