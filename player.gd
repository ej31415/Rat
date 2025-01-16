extends Node2D

class_name Player

enum Roles {MOUSE, RAT, SHERIFF}

var speed = 400 # pixel/sec
var role = Roles.MOUSE

func move(anim: StringName) -> Array:
	
	var velocity = Vector2.ZERO
	var new_anim = anim
	var speed_scale = 1.0
	
	# Set movement speed
	if Input.is_action_pressed("DOWN"):
		velocity.y = 1
	if Input.is_action_pressed("LEFT"):
		velocity.x = -1
	if Input.is_action_pressed("RIGHT"):
		velocity.x = 1
	if Input.is_action_pressed("UP"):
		velocity.y = -1
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
	
	if role == Roles.RAT and Input.is_action_pressed("SHIFT"):
		velocity *= 2.0
		speed_scale = 2.0
	
	# Set sprite orientation
	if velocity.x < 0:
		new_anim = "left"
	elif velocity.y > 0:
		new_anim = "front"
	elif velocity.y < 0:
		new_anim = "gyatt"
	elif velocity.x > 0:
		new_anim = "right"
	else:
		if anim == "left":
			new_anim = "static left"
		elif anim == "right":
			new_anim = "static right"
		elif anim == "gyatt":
			new_anim = "static gyatt"
		elif anim == "front":
			new_anim = "static front"
	
	return [velocity, new_anim, speed_scale]
