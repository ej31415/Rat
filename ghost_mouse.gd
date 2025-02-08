extends Player

var enabled := false

func _init() -> void:
	SPEED = 1500
	
func _ready() -> void:
	super.set_physics_process(true)
	started = false
	visible = false
	$AnimatedSprite2D.modulate = Color("#71bdee00")
	$ViewSphere.energy = 0
	print("initialized ghost mouse", alive, started)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		print(color + " finished attack animation")
		set_physics_process(true)
		$AnimatedSprite2D.modulate = Color(91/255.0, 155/255.0, 1, 1)
	if "shoot" in anim_name:
		print(color + " finished shooting animation")
		set_physics_process(true)
		$AnimatedSprite2D.modulate = Color(91/255.0, 155/255.0, 1, 1)
	if anim_name == "die":
		$AnimatedSprite2D.animation = "die"
