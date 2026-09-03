extends Node2D
# owns: the chapter 0 warehouse exterior, C0-006: the family's disused building at the lake
#   edge (STORY.md, "the family owns it, disused, at the lake edge... why nobody thinks about
#   it"), the path back to the home exterior, the path further along the shore to the pond,
#   and the door into the warehouse interior.
# does not own: what's inside (see warehouse_interior.tscn), the pond itself (see pond.tscn),
#   or anything Marigold- or Jack-speaking-her-name-related (C0-019/C0-020), since that
#   content is not written yet

const HOME_EXTERIOR_SCENE: String = "res://src/scenes/ch0/home_exterior.tscn"
const WAREHOUSE_INTERIOR_SCENE: String = "res://src/scenes/ch0/warehouse_interior.tscn"
const POND_SCENE: String = "res://src/scenes/ch0/pond.tscn"

@onready var _door_trigger: Area2D = $DoorTrigger
@onready var _path_west_trigger: Area2D = $PathWestTrigger
@onready var _path_east_trigger: Area2D = $PathEastTrigger
@onready var _player: CharacterBody2D = $Player

func _ready() -> void:
	_door_trigger.body_entered.connect(_on_door_entered)
	_path_west_trigger.body_entered.connect(_on_path_west_entered)
	_path_east_trigger.body_entered.connect(_on_path_east_entered)
	match GameState.get_flag("ch0_last_exit", ""):
		"home_exterior":
			_player.global_position = $SpawnFromHome.global_position
		"warehouse_interior":
			_player.global_position = $SpawnFromInterior.global_position
		"pond":
			_player.global_position = $SpawnFromPond.global_position

func _on_door_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.set_flag("ch0_last_exit", "warehouse_exterior")
	get_tree().change_scene_to_file(WAREHOUSE_INTERIOR_SCENE)

func _on_path_west_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.set_flag("ch0_last_exit", "warehouse_exterior")
	get_tree().change_scene_to_file(HOME_EXTERIOR_SCENE)

func _on_path_east_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.set_flag("ch0_last_exit", "warehouse_exterior")
	get_tree().change_scene_to_file(POND_SCENE)
