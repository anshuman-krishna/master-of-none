class_name MapSystem
extends RefCounted
# owns: the paper map's progressive reveal stage, and the folded home corner that refuses to
#   open before chapter 5 per DESIGN.md ("the home corner stays folded until chapter 5")
# does not own: the refusal line itself, which is dialogue content and not written here

const MAX_STAGE: int = 3
const HOME_CORNER_CHAPTER: int = 5

static func get_stage() -> int:
	return GameState.map_stage

static func advance_stage() -> void:
	GameState.map_stage = clampi(GameState.map_stage + 1, 0, MAX_STAGE)
	EventBus.map_stage_changed.emit(GameState.map_stage)

## true once the story has reached the chapter where the corner is allowed to open.
static func is_home_corner_unlocked() -> bool:
	return GameState.current_chapter >= HOME_CORNER_CHAPTER

## returns true if the corner opens. before chapter 5 this always refuses; the caller is
## responsible for showing whatever chapter-specific refusal line dialogue supplies, this
## system only decides yes or no.
static func try_open_home_corner() -> bool:
	return is_home_corner_unlocked()
