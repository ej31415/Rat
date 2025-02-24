extends SubViewportContainer

var target

@onready var camera = $SubViewport/Camera2D

func _ready() -> void:
	set_physics_process(false)

func set_target():
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("get_role") and player.get_role() == "rat":
			target = player
	
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	camera.position = target.position
