extends Player

func _ready() -> void:
	super._ready()
	print("initialized tan mouse")


func _on_hurtbox_area_entered(area: Area2D) -> void:
	print("tan mouse: OUCH!!!")
