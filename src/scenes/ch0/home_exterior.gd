extends Node2D
# owns: the chapter 0 home exterior: the yard the player starts in, the front door that leads
#   inside (per docs/STORY.md 3.6, the only door in the game that ever actually closes, though
#   that closing beat belongs to the chapter's ending, not here), the path east to the
#   family's warehouse at the lake edge, and the path south to the road out of town.
# does not own: what's inside the house (see home.tscn), the warehouse (see
#   warehouse_exterior.tscn), the road itself (see road_out_of_town.tscn), or a way back out
#   of the house, since nothing built yet needs one

const HOME_SCENE: String = "res://src/scenes/ch0/home.tscn"
const WAREHOUSE_EXTERIOR_SCENE: String = "res://src/scenes/ch0/warehouse_exterior.tscn"
const ROAD_OUT_OF_TOWN_SCENE: String = "res://src/scenes/ch0/road_out_of_town.tscn"

@onready var _door_trigger: Area2D = $DoorTrigger
@onready var _path_east_trigger: Area2D = $PathEastTrigger
@onready var _path_south_trigger: Area2D = $PathSouthTrigger
@onready var _player: CharacterBody2D = $Player

func _ready() -> void:
	_door_trigger.body_entered.connect(_on_door_entered)
	_path_east_trigger.body_entered.connect(_on_path_east_entered)
	_path_south_trigger.body_entered.connect(_on_path_south_entered)
	match GameState.get_flag("ch0_last_exit", ""):
		"warehouse_exterior":
			_player.global_position = $SpawnFromWarehouse.global_position
		"road_out_of_town":
			_player.global_position = $SpawnFromRoad.global_position

func _on_door_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	get_tree().change_scene_to_file(HOME_SCENE)

func _on_path_east_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.set_flag("ch0_last_exit", "home_exterior")
	get_tree().change_scene_to_file(WAREHOUSE_EXTERIOR_SCENE)

func _on_path_south_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.set_flag("ch0_last_exit", "home_exterior")
	get_tree().change_scene_to_file(ROAD_OUT_OF_TOWN_SCENE)
