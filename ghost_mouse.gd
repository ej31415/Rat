extends Player

var enabled := false

func _init() -> void:
	SPEED = 1500
	walk_sound = preload("res://assets/Music/ghost_moving.mp3")
	
func _ready() -> void:
	super._ready()
	super.set_physics_process(true)
	started = false
	visible = false
	$ViewSphere.energy = 1
	print("initialized ghost mouse", alive, started)
