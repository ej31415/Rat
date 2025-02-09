extends Player

func _ready() -> void:
	super._ready()
	self.color = "sb"
	print("initialized strawberry blonde mouse")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		print(color + " finished attack animation")
		set_physics_process(true)
	if "shoot" in anim_name:
		print(color + " finished shooting animation")
		set_physics_process(true)
	if anim_name == "die":
		$Shadow.visible = false
		$Blood.visible = true
