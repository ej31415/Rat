extends Player

var enabled := false

func _init() -> void:
	SPEED = 1500
	
func _ready() -> void:
	super.set_physics_process(true)
	started = false
	visible = false
	$ViewSphere.energy = 0
	print("initialized ghost mouse", alive, started)
