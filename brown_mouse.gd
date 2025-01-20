extends Player

func _ready() -> void:
	super._ready()
	self.color = "brown"
	print("initialized brown mouse")


func _on_hurtbox_area_entered(area: Area2D) -> void:
	print("brown mouse: OUCH!!!")
