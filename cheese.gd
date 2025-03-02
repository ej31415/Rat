class_name Cheese
extends Sprite2D

const dist_radius = 300 # radius for cheese preservation

var spawned_from
var consumed
var last_contact

const scene = preload("res://cheese.tscn")

static func constructor(owner: Player):
	var obj = scene.instantiate()
	obj.spawned_from = owner
	obj.consumed = false
	obj.last_contact = Time.get_unix_time_from_system()
	obj.global_position = obj.spawned_from.global_position
	obj.add_to_group("cheese")
	owner.get_parent().add_child(obj)
	print(owner.color + " placed cheese")
	return obj
	
func _process(delta: float) -> void:
	# Check for cheese interaction
	for player in get_tree().get_nodes_in_group("player"):
		if not player.has_method("get_color") or player == spawned_from: # cannot pick up own cheese
			continue
		if player.position.distance_to(self.position) < 190:
			cheese_consumed_call([player.get_color(), spawned_from.get_color()])
	
	# Despawn when owner is too far away
	if spawned_from.position.distance_to(self.position) < dist_radius:
		last_contact = Time.get_unix_time_from_system()
	if consumed or Time.get_unix_time_from_system() - last_contact > 3:
		print(spawned_from.color + " cheese despawned")
		self.queue_free()

func cheese_consumed_call(buff_colors: Array):
	for player in get_tree().get_nodes_in_group("player"):
		if not player.has_method("get_color"):
			continue
		if player.get_color() in buff_colors:
			player.buff()
			if player.cheese != null:
				player.cheese.queue_free()
				player.next_cheese_drop = Time.get_unix_time_from_system() + 30
