extends Player

func _ready() -> void:
	super._pseudo_ready()
	setup_audio()
	self.color = "brown"
	print("initialized brown mouse")

func setup_audio():
	for child in get_tree().get_nodes_in_group("output"):
		if child.has_method("get_stream_playback"):
			output = child
	if is_multiplayer_authority():
		input = $input
		input.stream = AudioStreamMicrophone.new()
		input.play()
		idx = AudioServer.get_bus_index("Record")
		effect = AudioServer.get_bus_effect(idx, 0)
	playback = output.get_stream_playback()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		print(color + " finished attack animation")
		$Knife.visible = false
		set_physics_process(true)
	if "shoot" in anim_name:
		print(color + " finished shooting animation")
		$Gun.visible = false
		set_physics_process(true)
	if anim_name == "die":
		$Shadow.visible = false
		$Blood.visible = true
