extends MarginContainer

var target
var canvas_scale

@onready var canvas = $Canvas
var marker = preload("res://marker.tscn")
var markers = {}
var zoom = 5.0

func _ready() -> void:
	set_process(false)
	canvas_scale = canvas.size / (get_viewport().get_visible_rect().size * zoom)

func set_target():
	for player in markers:
		markers[player].queue_free()
	markers = {}
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("get_role"):
			var new_marker = marker.instantiate()
			canvas.add_child(new_marker)
			if player.get_role() == "rat":
				target = player
				new_marker.modulate = player.get_color_prop()
				new_marker.position = canvas.size / 2
			else:
				new_marker.modulate = player.get_color_prop()
			markers[player] = new_marker
			new_marker.visible = true
	set_process(true)

func _process(delta: float) -> void:
	for player in markers:
		if !is_instance_valid(player):
			continue
		var obj_pos = (player.position - target.position) * canvas_scale + canvas.size / 2
		if canvas.get_rect().has_point(obj_pos + canvas.position):
			markers[player].scale = Vector2(1, 1)
		else:
			markers[player].scale = Vector2(0.7, 0.7)
		obj_pos.x = clamp(obj_pos.x, 0, canvas.size.x)
		obj_pos.y = clamp(obj_pos.y, 0, canvas.size.y)
		markers[player].position = obj_pos
		
		if not player.is_alive() or (player.buffed and player.get_role() != "rat"):
			markers[player].visible = false
		else:
			markers[player].visible = true
