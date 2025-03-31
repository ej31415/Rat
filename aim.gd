extends RayCast2D

var last_collider: Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var parent = get_parent()
	if !(parent.has_method("get_role") and parent.get_role() == "sheriff" and !parent.get_shot()):
		return
	var color = parent.get_color()
	if not is_colliding() and last_collider != null:
		last_collider.set_aim_view_visible(false)
		last_collider = null
	elif is_colliding():
		var cur_collider = get_collider()
		if cur_collider.has_method("set_aim_view_visible"):
			if cur_collider.get_color() == color:
				return
			if last_collider != null:
				last_collider.set_aim_view_visible(false)
			last_collider = cur_collider
			last_collider.set_aim_view_visible(true)
		elif last_collider != null:
			last_collider.set_aim_view_visible(false)
			last_collider = null
