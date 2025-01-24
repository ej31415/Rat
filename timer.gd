extends CanvasLayer

var ms_left

func start(ms: int) -> void:
	$Panel.visible = true
	$Timer.wait_time = ms/1000
	$Timer.start()
	ms_left = ms
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _pad(s: String, n_digits: int):
	var res := str(s)
	for i in range(n_digits - len(res)):
		res = "0" + res
	return res

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not $Timer.is_stopped() and ms_left and ms_left > 0:
		ms_left = max(0, ms_left - delta*1000)
		var minutes := floor(ms_left / 60000) as int
		var seconds := floor(ms_left / 1000) - minutes*60 as int
		var milliseconds := ms_left - seconds*1000 - minutes*60000 as int
		$Panel/TimeLeft.text = _pad(str(minutes), 2) + " : " + _pad(str(seconds), 2) + " : " + _pad(str(milliseconds), 3)
		if ms_left < 1000*10:
			$Panel/TimeLeft.label_settings.font_color = Color(1.0, 0, 0)

func _on_timer_timeout() -> void:
	ms_left = 0

@rpc("any_peer", "call_local", "reliable")
func end_timer() -> void:
	$Timer.stop()
