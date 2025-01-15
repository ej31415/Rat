extends Player

signal hit

var screen_size # size of screen window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Set movement speed
	var movement = move($AnimatedSprite2D.animation)
	
	var velocity = movement[0]
		
	if velocity.length() > 0:
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
		
	# Set position and limit to screen
	position += (velocity * delta)
	position = position.clamp(Vector2.ZERO, screen_size)
	
	$AnimatedSprite2D.animation = movement[1]
	$AnimatedSprite2D.speed_scale = movement[2]


func _on_body_entered(body: Node2D) -> void:
	
	hit.emit()
	$CollisionShape2D.set_deferred("disabled", true) # make sure signal only sends once
	
func start(pos):
	# pass in the start position from spawner as pos?
	position = pos
	show()
	$CollisionShape2D.disabled = false
