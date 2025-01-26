extends Player

func _ready() -> void:
	super._ready()
	self.color = "gray"
	print("initialized gray mouse")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		print(color + " finished attack animation")
		set_physics_process(true)
		$AnimatedSprite2D.modulate = Color(234/255.0, 193/255.0, 0, 1)
	if "shoot" in anim_name:
		print(color + " finished shooting animation")
		set_physics_process(true)
		$AnimatedSprite2D.modulate = Color(234/255.0, 193/255.0, 0, 1)
	if anim_name == "die":
		$AnimatedSprite2D.animation = "die"
