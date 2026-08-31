extends Node
# owns: the entry point the engine boots into
# does not own: any real gameplay, none of the chapters have a playable scene yet

func _ready() -> void:
	print("master of none: engine booted")
	if SaveManager.has_save():
		print("boot: existing save found")
	else:
		print("boot: no existing save, would start new game flow here")
