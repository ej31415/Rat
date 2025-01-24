extends Player

func _ready() -> void:
	super._ready()
	self.color = "brown"
	print("initialized brown mouse")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		print(color + " finished attack animation")
		set_physics_process(true)
