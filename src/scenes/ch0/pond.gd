extends Node2D
# owns: the chapter 0 pond, C0-004/C0-005: the sunset lighting state as the default
#   background (`pond_sunset.png`) and the path back to the warehouse along the shore.
#   `pond_dusk.png` exists as an asset (the dusk/climax lighting state, C0-005) but nothing
#   swaps to it yet, since the pond climax scene it belongs to (C0-033) is not built.
# does not own: the dusk lighting swap, the fallen log becoming a sit/fish spot, or any
#   dialogue here (C0-023's fishing vignette, C0-033's climax), since none of that is built

const WAREHOUSE_EXTERIOR_SCENE: String = "res://src/scenes/ch0/warehouse_exterior.tscn"

@onready var _path_west_trigger: Area2D = $PathWestTrigger

func _ready() -> void:
	_path_west_trigger.body_entered.connect(_on_path_west_entered)

func _on_path_west_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.set_flag("ch0_last_exit", "pond")
	get_tree().change_scene_to_file(WAREHOUSE_EXTERIOR_SCENE)
