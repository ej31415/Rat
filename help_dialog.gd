extends CanvasLayer

@onready var page_idx := 0
@onready var pages := [$TableOfContents, $Controls, $Mouse, $Cheese1, $Cheese2, $Rat,
$Knife, $Stamina, $Sheriff, $Gun, $Scoring]

# Turns the help dialog page. `delta` is the number of pages to turn (sign is direction). 
func turn_page(delta: int) -> void:
	(pages[page_idx] as CanvasGroup).visible = false
	page_idx = posmod(page_idx + delta, len(pages))
	print(page_idx)
	(pages[page_idx] as CanvasGroup).visible = true
	$PageNumber.text = "[center]" + str(page_idx+1) + " / " + str(len(pages)) + "[/center]"

func turn_to(page_num: int) -> void:
	(pages[page_idx] as CanvasGroup).visible = false
	page_idx = page_num
	print(page_num)
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
	if page_idx != 0:
		$ToTOC.visible = true
	else:
		$ToTOC.visible = false

func _on_right_button_down() -> void:
	turn_page(1)

func _on_left_button_down() -> void:
	turn_page(-1)

func _on_close_button_down() -> void:
	self.visible = false

func _on_to_toc_button_down() -> void:
	turn_to(0)

# Table of Contents Functions

func _on_controller_button_down() -> void:
	turn_to(1)

func _on_scoring_button_down() -> void:
	turn_to(10)

func _on_cheese_button_down() -> void:
	turn_to(3)

func _on_knife_button_down() -> void:
	turn_to(6)

func _on_stamina_button_down() -> void:
	turn_to(7)

func _on_gun_button_down() -> void:
	turn_to(9)

func _on_mouse_button_down() -> void:
	turn_to(2)

func _on_rat_button_down() -> void:
	turn_to(5)

func _on_sheriff_button_down() -> void:
	turn_to(8)
