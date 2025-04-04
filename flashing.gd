extends Node

@export var speed = 5
@export var flashing = false

var default_modulate: Color

var time := 0.0

func _ready() -> void:
	default_modulate = self.modulate

func _process_flash():
	var flash_val = sin(time * speed) * 0.4 + 0.6
	if flashing:
		self.modulate.a = flash_val
	#else:
		#self.modulate.a = default_modulate.a

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	_process_flash()
