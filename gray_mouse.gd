extends CharacterBody2D

enum Roles {MOUSE, RAT, SHERIFF}

const SPEED = 400.0
var anim = "front"
var role = Roles.RAT

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	if is_multiplayer_authority():
		$Camera2D.make_current()
	
	var direction := Input.get_vector("LEFT", "RIGHT", "UP", "DOWN").normalized()
	if role == Roles.RAT and Input.is_action_pressed("SHIFT"):
		direction *= 2.0
		$AnimatedSprite2D.speed_scale = 2.0
	else:
		$AnimatedSprite2D.speed_scale = 1.0
	if is_multiplayer_authority():
		if direction:
			velocity = direction * SPEED
		else:
			velocity = Vector2.ZERO
	
	move_and_slide()
	
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
