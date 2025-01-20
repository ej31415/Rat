extends Player

func _ready() -> void:
	super._ready()
	self.color = "sb"
	print("initialized strawberry blonde mouse")


func _on_hurtbox_area_entered(area: Area2D) -> void:
	print("strawberry blonde mouse: OUCH!!!")
