extends TextureButton

var checked := true
var checked_texture
var unchecked_texture

func _init() -> void:
	checked_texture = preload("res://assets/UI Sprites/check_box_checked.png")
	unchecked_texture = preload("res://assets/UI Sprites/check_box_unchecked.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	checked = true
	texture_normal = checked_texture

func check() -> void:
	checked = true
	texture_normal = checked_texture

func uncheck() -> void:
	checked = false
	texture_normal = unchecked_texture

func toggle() -> void:
	if checked:
		uncheck()
	else:
		check()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_up() -> void:
	toggle()


func _on_mouse_entered() -> void:
	$Tooltip.visible = true

func _on_mouse_exited() -> void:
	$Tooltip.visible = false
