extends CanvasLayer

@onready var page_idx := 0
@onready var pages := [$Controls, $Mouse, $Rat, $Sheriff]

# Turns the help dialog page. `delta` is the number of pages to turn (sign is direction). 
func turn_page(delta: int) -> void:
	(pages[page_idx] as CanvasGroup).visible = false
	page_idx = posmod(page_idx + delta, len(pages))
	print(page_idx)
	(pages[page_idx] as CanvasGroup).visible = true
	$PageNumber.text = "[center]" + str(page_idx+1) + " / " + str(len(pages)) + "[/center]"
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	for page in pages:
		(page as CanvasGroup).visible = false
	turn_page(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_right_button_down() -> void:
	turn_page(1)

func _on_left_button_down() -> void:
	turn_page(-1)

func _on_close_button_down() -> void:
	self.visible = false
