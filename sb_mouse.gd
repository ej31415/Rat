extends Player

func _ready() -> void:
	super._ready()
	self.color = "sb"
	print("initialized strawberry blonde mouse")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if "attack" in anim_name:
		set_physics_process(true)


func _on_knife_hitbox_body_entered(body: Node2D) -> void:
	body.die()
