extends Node2D
# owns: the chapter 0 road-out-of-town, C0-007: the final chapter 0 screen, a dirt track
#   running away from the house with a plain pair of boundary posts marking the town line
#   (docs/STORY.md 3.6) and the path back to the home exterior.
# does not own: the uninterruptible run and hard cut on crossing the line (C0-035), since that
#   depends on a run cycle that does not exist yet (C0-011); the wall at the treeline is the
#   edge of the built game, not a finished crossing.

const HOME_EXTERIOR_SCENE: String = "res://src/scenes/ch0/home_exterior.tscn"

@onready var _path_south_trigger: Area2D = $PathSouthTrigger

func _ready() -> void:
	_path_south_trigger.body_entered.connect(_on_path_south_entered)

func _on_path_south_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.set_flag("ch0_last_exit", "road_out_of_town")
	get_tree().change_scene_to_file(HOME_EXTERIOR_SCENE)
