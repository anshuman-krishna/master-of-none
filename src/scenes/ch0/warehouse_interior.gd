extends Node2D
# owns: the chapter 0 warehouse interior, C0-006: bare concrete, pallets waiting to become
#   Marigold's shelter (C0-021), dust shafts from the two broken windows, and the hiding
#   corner out of both. this is the only room only Jack has a reason to go to.
# does not own: Marigold herself, the shelter's four build states, or any dialogue here
#   (C0-019/C0-020/C0-021), since none of that content is written yet

const WAREHOUSE_EXTERIOR_SCENE: String = "res://src/scenes/ch0/warehouse_exterior.tscn"

@onready var _exit_trigger: Area2D = $ExitTrigger

func _ready() -> void:
	_exit_trigger.body_entered.connect(_on_exit_entered)

func _on_exit_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.set_flag("ch0_last_exit", "warehouse_interior")
	get_tree().change_scene_to_file(WAREHOUSE_EXTERIOR_SCENE)
