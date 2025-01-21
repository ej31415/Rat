extends CharacterBody2D

class_name Player

static var roles = ["mouse", "mouse", "sheriff", "rat"]
static var rng = RandomNumberGenerator.new()

const SPEED = 400.0
var anim = "static front"
var role = ""
var started = false
var color = ""

func _init() -> void:
	var idx = rng.randi_range(0, len(roles) - 1)
	role = roles[idx]
	roles.pop_at(idx)
	started = false

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready():
	add_to_group("player")
	if role == "":
		print("role not set")

func starter(color_to_roles):
	role = color_to_roles[color]
	if is_multiplayer_authority():
		$Camera2D.enabled = true
		$Camera2D.make_current()
		started = true

func get_role():
	return role

func get_color():
	return color

func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	if is_multiplayer_authority() and started:
		var direction := Input.get_vector("LEFT", "RIGHT", "UP", "DOWN").normalized()
		if role == "rat" and Input.is_action_pressed("SHIFT"):
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
			$Vision.position = Vector2(-40, 0)
			$Vision.scale = Vector2(2.5, 1.2)
			$Vision.rotation_degrees = 0
		elif velocity.y > 0:
			anim = "front"
			$Vision.position = Vector2(-35, 40)
			$Vision.scale = Vector2(2.5, 1.2)
			$Vision.rotation_degrees = -90
		elif velocity.y < 0:
			anim = "gyatt"
			$Vision.position = Vector2(35, 10)
			$Vision.scale = Vector2(2.5, 1.2)
			$Vision.rotation_degrees = 90
		elif velocity.x > 0:
			anim = "right"
			$Vision.position = Vector2(40, 0)
			$Vision.scale = Vector2(-2.5, 1.2)
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ATTACK") and role == "rat":
		set_physics_process(false)
		if anim == "left" or anim == "static left":
			$AnimationPlayer.play("attack")
		else:
			set_physics_process(true)

func die():
	print(color + " killed!!!")
