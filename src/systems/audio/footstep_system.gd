class_name FootstepSystem
extends Node2D
# owns: triggering a per-surface footstep sound at a fixed walking cadence, tracked by
#   distance travelled rather than by animation frame, since no walk-cycle animation exists
#   yet (see testing/todos.md F-026). re-sync this to footfall frames once animation lands.
# does not own: deciding which surface the entity stands on; the caller sets surface_id,
#   typically from a tile/area check that does not exist yet either

const STEP_DISTANCE_PX: float = 10.0
const PITCH_VARIANCE: float = 0.08

@export var target: Node2D
@export var surface_id: String = "grass"

var _player: AudioStreamPlayer
var _last_position: Vector2 = Vector2.ZERO
var _distance_since_step: float = 0.0

func _ready() -> void:
	if target == null:
		target = get_parent() as Node2D
	_player = AudioStreamPlayer.new()
	add_child(_player)
	if target != null:
		_last_position = target.global_position

func _physics_process(_delta: float) -> void:
	if target == null:
		return
	var moved: float = target.global_position.distance_to(_last_position)
	_last_position = target.global_position
	_distance_since_step += moved
	if _distance_since_step >= STEP_DISTANCE_PX:
		_distance_since_step = 0.0
		_play_step()

func _play_step() -> void:
	var clip: AudioStream = FootstepBank.get_random_clip(surface_id)
	if clip == null:
		return
	_player.stream = clip
	_player.pitch_scale = 1.0 + randf_range(-PITCH_VARIANCE, PITCH_VARIANCE)
	_player.play()
