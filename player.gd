extends CharacterBody2D

class_name Player

static var roles = ["mouse", "mouse", "sheriff", "rat"]
static var rng = RandomNumberGenerator.new()

const SPEED = 600.0
var anim = "static front"
var role = ""
var started = false
var color = ""
var alive = true
var last_rat_kill = 0
var sheriff_shot = false

func _init() -> void:
	var idx = rng.randi_range(0, len(roles) - 1)
	role = roles[idx]
	roles.pop_at(idx)
	alive = true
	started = false

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready():
	add_to_group("player")
	if role == "":
		print("role not set")

func starter(color_to_roles):
	role = color_to_roles[color]
	alive = true
	sheriff_shot = false
	started = true
	$ViewSphere.enabled = true
	$ViewSphere.texture_scale = 1
	$Vision.enabled = true
	enable_movement()
	if is_multiplayer_authority():
		$Camera2D.enabled = true
		$Camera2D.make_current()
		return role
	return ""

func disable_movement():
	$AnimatedSprite2D.animation = "static front"
	set_physics_process(false)
	
func enable_movement():
	set_physics_process(true)

func get_player():
	return self

func get_role():
	return role

func get_color():
	return color

func is_alive():
	return alive
	
func set_vision():
	if velocity.x < 0 and velocity.y < 0:
		$Vision.position = Vector2(0, -10)
		$Vision.scale = Vector2(2.5, 1.2)
		$Vision.rotation_degrees = 45
		$Aim.rotation_degrees = 135
	elif velocity.x < 0 and velocity.y > 0:
		$Vision.position = Vector2(-40, -10)
		$Vision.scale = Vector2(2.5, 1.2)
		$Vision.rotation_degrees = -45
		$Aim.rotation_degrees = 45
	elif velocity.x > 0 and velocity.y < 0:
		$Vision.position = Vector2(-40, -10)
		$Vision.scale = Vector2(-2.5, 1.2)
		$Vision.rotation_degrees = -45
		$Aim.rotation_degrees = -135
	elif velocity.x > 0 and velocity.y > 0:
		$Vision.position = Vector2(0, -10)
		$Vision.scale = Vector2(-2.5, 1.2)
		$Vision.rotation_degrees = 45
		$Aim.rotation_degrees = -45
	elif velocity.x < 0:
		$Vision.position = Vector2(-40, -10)
		$Vision.scale = Vector2(2.5, 1.2)
		$Vision.rotation_degrees = 0
		$Aim.rotation_degrees = 90
	elif velocity.y < 0:
		$Vision.position = Vector2(42, 10)
		$Vision.scale = Vector2(2.5, 1.2)
		$Vision.rotation_degrees = 90
		$Aim.rotation_degrees = 180
	elif velocity.y > 0:
		$Vision.position = Vector2(-42, 40)
		$Vision.scale = Vector2(2.5, 1.2)
		$Vision.rotation_degrees = -90
		$Aim.rotation_degrees = 0
	elif velocity.x > 0:
		$Vision.position = Vector2(40, -10)
		$Vision.scale = Vector2(-2.5, 1.2)
		$Vision.rotation_degrees = 0
		$Aim.rotation_degrees = -90

func _physics_process(delta: float) -> void:
	if !alive:
		return
		
	# Get the input direction and handle the movement/deceleration.
	if is_multiplayer_authority() and started:
		var direction := Input.get_vector("LEFT", "RIGHT", "UP", "DOWN").normalized()
		if role == "rat" and Input.is_action_pressed("SHIFT"):
			direction *= 2.0
			$AnimatedSprite2D.speed_scale = 1.5
		else:
			$AnimatedSprite2D.speed_scale = 1.0
		if is_multiplayer_authority():
			if direction:
				velocity = direction * SPEED
			else:
				velocity = Vector2.ZERO
		
		move_and_slide()
		
		set_vision()
		
		# Set sprite orientation
		if velocity.x < 0:
			anim = "left"
		elif velocity.y > 0:
			anim = "front"
		elif velocity.y < 0:
			anim = "gyatt"
		elif velocity.x > 0:
			anim = "right"
		else:
			if anim == "left":
				anim = "static left"
			elif anim == "right":
				anim = "static right"
			elif anim == "gyatt":
				anim = "static gyatt"
			elif anim == "front":
				anim = "static front"
	
		$AnimatedSprite2D.animation = anim
		if velocity.length() > 0:
			$AnimatedSprite2D.play()
		else:
			$AnimatedSprite2D.stop()

func _unhandled_input(event: InputEvent) -> void:
	if !alive:
		return
	if is_multiplayer_authority() and started:
		if event.is_action_pressed("ATTACK"):
			if role == "rat":
				for child in get_tree().get_nodes_in_group("player"):
					if Time.get_unix_time_from_system() - last_rat_kill < 10:
						print(color + " on kill cooldown")
						break
					if child.has_method("die"):
						if child.get_role() == "rat":
							continue
						if !child.is_alive():
							continue
						if child.position.distance_to(self.position) < 190:
							die_call.rpc(child.get_color())
							last_rat_kill = Time.get_unix_time_from_system()
							add_kill.rpc()
					print(color + " attack!!!")
					set_physics_process(false)
					$AnimatedSprite2D.modulate = Color(1, 1, 1, 1)
					$AnimationPlayer.play("attack")
			elif role == "sheriff":
				var target = $Aim.get_collider()
				if sheriff_shot:
					return
				if target != null and target.has_method("die"):
					if target.get_role() == "sheriff":
						return
					if !target.is_alive():
						return
					die_call.rpc(target.get_color())
					add_kill.rpc()
				sheriff_shot = true
				print(color + " shoot!!!")
				set_physics_process(false)
				$AnimationPlayer.play(animate_shoot())

func animate_shoot() -> StringName:
	var current_anim = $AnimatedSprite2D.animation
	var new_anim = ""
	if current_anim == "left" or current_anim == "static left":
		new_anim = "shoot left"
	elif current_anim == "right" or current_anim == "static right":
		new_anim = "shoot right"
	elif current_anim == "front" or current_anim == "static front":
		new_anim = "shoot down"
	elif current_anim == "gyatt" or current_anim == "static gyatt":
		new_anim = "shoot up"
	return new_anim

@rpc("call_local", "reliable")
func die_call(color):
	for child in get_tree().get_nodes_in_group("player"):
		if child.has_method("die") and child.get_color() == color:
			child.die()

func die():
	if !alive:
		return
	print(color + " killed!!!")
	alive = false
	if is_multiplayer_authority():
		$ViewSphere.texture_scale = 8
	else:
		$ViewSphere.enabled = false
	$Vision.enabled = false
	set_physics_process(false)
	$AnimationPlayer.play("die")

@rpc("call_local", "reliable")
func add_kill():
	Main.killed += 1
