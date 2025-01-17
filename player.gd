extends CharacterBody2D

class_name Player

enum Roles {MOUSE, RAT, SHERIFF}

const SPEED = 400.0
var anim = "static front"
var role = Roles.RAT

func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_vector("LEFT", "RIGHT", "UP", "DOWN").normalized()
	if role == Roles.RAT and Input.is_action_pressed("SHIFT"):
		direction *= 2.0
		$AnimatedSprite2D.speed_scale = 2.0
	else:
		$AnimatedSprite2D.speed_scale = 1.0
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
