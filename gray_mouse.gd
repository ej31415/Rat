extends Player

func _ready() -> void:
	super._ready()
	print("initialized gray mouse")


func _on_hurtbox_area_entered(area: Area2D) -> void:
	print("gray mouse: OUCH!!!")
