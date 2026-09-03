extends Node
# owns: the entry point the engine boots into: an existing save continues straight into the
#   chapter 0 home, a fresh one goes through the pronoun choice and starts at the home exterior
# does not own: any gameplay past chapter 0's home scene, since nothing past it exists yet

const PRONOUN_SELECT_SCENE: String = "res://src/scenes/shared/pronoun_select.tscn"
const HOME_EXTERIOR_SCENE: String = "res://src/scenes/ch0/home_exterior.tscn"
const HOME_SCENE: String = "res://src/scenes/ch0/home.tscn"

func _ready() -> void:
	print("master of none: engine booted")
	if SaveManager.has_save():
		print("boot: existing save found, continuing")
		SaveManager.load_game()
		# the tree is still busy processing boot's own entry into it here, so the scene swap
		# has to wait a frame; calling it synchronously errors ("parent node is busy adding/
		# removing children")
		get_tree().change_scene_to_file.call_deferred(HOME_SCENE)
	else:
		print("boot: no existing save, starting new game flow")
		_start_new_game()

func _start_new_game() -> void:
	var pronoun_select: Control = load(PRONOUN_SELECT_SCENE).instantiate()
	add_child(pronoun_select)
	pronoun_select.pronoun_chosen.connect(_on_pronoun_chosen.bind(pronoun_select), CONNECT_ONE_SHOT)

func _on_pronoun_chosen(_pronoun: GameState.Pronoun, pronoun_select: Control) -> void:
	pronoun_select.queue_free()
	get_tree().change_scene_to_file(HOME_EXTERIOR_SCENE)
