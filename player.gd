extends CharacterBody2D

class_name Player

static var roles = ["mouse", "mouse", "sheriff", "rat"]
static var rng = RandomNumberGenerator.new()

const SPEED = 400.0
var anim = "static front"
var role = ""

func _init() -> void:
	var idx = rng.randi_range(0, len(roles) - 1)
	role = roles[idx]
	roles.pop_at(idx)

func _ready() -> void:
	if is_multiplayer_authority():
		$Camera2D.make_current()
	if role == "":
		print("role not set")

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
	# Get the input direction and handle the movement/deceleration.
		var direction := Input.get_vector("LEFT", "RIGHT", "UP", "DOWN").normalized()
		if role == "rat" and Input.is_action_pressed("SHIFT"):
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
		$Vision.position = Vector2(-40, 0)
		$Vision.scale = Vector2(1.5, 1)
		$Vision.rotation_degrees = 0
	elif velocity.y > 0:
		anim = "front"
		$Vision.position = Vector2(-35, 40)
		$Vision.scale = Vector2(1.5, 1)
		$Vision.rotation_degrees = -90
	elif velocity.y < 0:
		anim = "gyatt"
		$Vision.position = Vector2(35, 10)
		$Vision.scale = Vector2(1.5, 1)
		$Vision.rotation_degrees = 90
	elif velocity.x > 0:
		anim = "right"
		$Vision.position = Vector2(40, 0)
		$Vision.scale = Vector2(-1.5, 1)
		$Vision.rotation_degrees = 0
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
