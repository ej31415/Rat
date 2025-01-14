extends Node2D

signal hit

@export var speed = 400 # pixel/sec
var screen_size # size of screen window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Set movement speed
	var velocity = Vector2.ZERO
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
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
		
	# Set position and limit to screen
	position += (velocity * delta)
	position = position.clamp(Vector2.ZERO, screen_size)
	
	# Set sprite orientation
	if velocity.x < 0:
		$AnimatedSprite2D.animation = "left"
		$AnimatedSprite2D.flip_v = false
	elif velocity.y > 0:
		$AnimatedSprite2D.animation = "down"
		$AnimatedSprite2D.flip_h = false
	elif velocity.y < 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_h = false
	elif velocity.x > 0:
		$AnimatedSprite2D.animation = "right"
		$AnimatedSprite2D.flip_v = false


func _on_body_entered(body: Node2D) -> void:
	
	hit.emit()
	$CollisionShape2D.set_deferred("disabled", true) # make sure signal only sends once
	
func start(pos):
	# pass in the start position from spawner as pos?
	position = pos
	show()
	$CollisionShape2D.disabled = false
