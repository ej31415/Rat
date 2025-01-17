extends Player

func _ready() -> void:
	print("initialized gray mouse")

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		$Camera2D.make_current()
	super._physics_process(delta)
