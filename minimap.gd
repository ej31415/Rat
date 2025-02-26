extends MarginContainer

var target
var canvas_scale

@onready var canvas = $Canvas
var marker = preload("res://marker.tscn")
var markers = {}
var zoom = 1.5

func _ready() -> void:
	set_process(false)
	#canvas_scale = canvas.size / (get_viewport().get_visible_rect().size * zoom)

func set_target():
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("get_role"):
			if player.get_role() == "rat":
				var new_marker = marker.instantiate()
				canvas.add_child(new_marker)
				target = player
				new_marker.modulate = player.get_color_prop()
				new_marker.position = canvas.size / 2
				new_marker.visible = true
			else:
				var new_marker = marker.instantiate()
				canvas.add_child(new_marker)
				new_marker.modulate = player.get_color_prop()
				markers[player] = new_marker
				new_marker.visible = true
	set_process(true)
	
	print(canvas.get_child_count())

func _process(delta: float) -> void:
	for item in markers:
		var obj_pos = (item.position - target.position) + canvas.size / 2
		markers[item].position = obj_pos
