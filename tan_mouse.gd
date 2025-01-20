extends Player

func _ready() -> void:
	print("initialized tan mouse")
	if is_multiplayer_authority():
		$Camera2D.make_current()
