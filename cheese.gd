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
	
	
func _process(delta: float) -> void:
	if spawned_from.position.distance_to(self.position) < dist_radius:
		last_contact = Time.get_unix_time_from_system()
	if consumed or Time.get_unix_time_from_system() - last_contact > 3:
		print(spawned_from.color + " cheese despawned")
		self.queue_free()
