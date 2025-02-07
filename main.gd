extends Node2D

class_name Main

var peer = ENetMultiplayerPeer.new()
@export var gray_mouse: PackedScene
@export var brown_mouse: PackedScene
@export var sb_mouse: PackedScene
@export var tan_mouse: PackedScene
var title_sound
var mice_active_music
var mice_victory_sound
var rat_victory_sound

var mice = []
var color_to_role = {}
var color_to_pts = {}
var color_to_pts_label = {}
var color_to_baseinst = {}
var id_to_color = {}
var game_ended = false
var is_host = false
var first_started = false
var player_disconnected = false

static var killed = 0

func _init() -> void:
	gray_mouse = preload("res://gray_mouse.tscn")
	brown_mouse = preload("res://brown_mouse.tscn")
	sb_mouse = preload("res://sb_mouse.tscn")
	tan_mouse = preload("res://tan_mouse.tscn")
	title_sound = preload("res://assets/Music/Start Title.mp3")
	mice_active_music = preload("res://assets/Music/mice_active_music.mp3")
	mice_victory_sound = preload("res://assets/Music/Mice Win Sound.mp3")
	rat_victory_sound = preload("res://assets/Music/Rat Win Sound.mp3") 
	mice = [[gray_mouse, "gray"], [brown_mouse, "brown"], [sb_mouse, "sb"], [tan_mouse, "tan"]]

func _ready():
	color_to_pts = {
		"gray": 0,
		"sb": 0,
		"tan": 0,
		"brown": 0
	}
	color_to_pts_label = {
		"gray": $HUD/ScoreBoard/GrayPts,
		"sb": $HUD/ScoreBoard/SBPts,
		"tan": $HUD/ScoreBoard/TanPts,
		"brown": $HUD/ScoreBoard/BrownPts
	}
	color_to_baseinst = {
		"gray": gray_mouse,
		"sb": sb_mouse,
		"tan": tan_mouse,
		"brown": brown_mouse
	}
	multiplayer.server_disconnected.connect(_on_server_disconnect)

func _on_host_pressed():
	peer.create_server(135)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)
	_add_player()
	$StartMenu/start.visible = true
	$StartMenu/num_players.visible = true
	$StartMenu/host.disabled = true
	$StartMenu/join.disabled = true
	is_host = true

func _add_player(id = 1):
	if len(mice) > 0:
		var rng = RandomNumberGenerator.new()
		var idx = rng.randi_range(0, len(mice) - 1)
		var mouse = mice[idx][0]
		var color = mice[idx][1]
		var player = mouse.instantiate()
		color_to_role[color] = player.get_role()
		id_to_color[id] = color
		mice.pop_at(idx)
		player.name = str(id)
		call_deferred("add_child", player)
	$StartMenu/num_players.text = "Joined: " + str(4 - len(mice)) + "/4"
	$WinScreen/num_players.text = "Joined: " + str(4 - len(mice)) + "/4"
	if len(mice) == 0:
		$WinScreen/Again.disabled = false
		$StartMenu/start.disabled = false

func _remove_player(id):
	var color = id_to_color[id]
	var interim_discon = false
	if first_started:
		interim_discon = true
	_remove_player_handler.rpc(color, interim_discon)

@rpc("call_local", "reliable")
func _remove_player_handler(color, interim_discon):
	player_disconnected = interim_discon
	color_to_role.erase(color)
	var to_remove: Node
	for child in get_tree().get_nodes_in_group("player"):
		if child.has_method("get_color") and child.get_color() == color:
			to_remove = child
			Player.roles.append(child.get_role())
			mice.append([color_to_baseinst[color], color])
	to_remove.remove_from_group("player")
	to_remove.free()
	$StartMenu/num_players.text = "Joined: " + str(4 - len(mice)) + "/4"
	$WinScreen/num_players.text = "Joined: " + str(4 - len(mice)) + "/4"
	$StartMenu/start.disabled = true
	$WinScreen/Again.disabled = true

func _on_server_disconnect():
	if first_started:
		$TimerCanvasLayer.end_timer()
		$AudioStreamPlayer.stop()
		$WinScreen/Again.visible = false
		$WinScreen/MiceWin.visible = false
		$WinScreen/RatWins.visible = false
		$WinScreen/PlayerDisconnected.visible = false
		$WinScreen/num_players.visible = false
		$HUD.visible = false
		$StartMenu.visible = false
		set_physics_process(false)
		$WinScreen/ServerDisconnected.visible = true

func _on_join_pressed():
	var error = peer.create_client($StartMenu/ip.text, 135)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		$StartMenu/host.disabled = true
		$StartMenu/join.disabled = true
		$StartMenu/error.visible = false
		$StartMenu/joined.visible = true
		$StartMenu/disconnect.visible = true
	else:
		$StartMenu/error.visible = true

func _on_disconnect_pressed():
	peer.close()
	multiplayer.multiplayer_peer = peer
	Player.roles = Player.roles_copy.duplicate()
	$StartMenu/disconnect.visible = false
	$StartMenu/join.disabled = false
	$StartMenu/error.visible = false
	$StartMenu/host.disabled = false
	$StartMenu/joined.visible = false

func _on_start_pressed():
	var maze = $Map.get_maze()
	var offset = $Map.get_offset()
	start_helper.rpc(maze, offset, color_to_role, color_to_pts)

@rpc("call_local", "reliable")
func start_helper(maze: Array, offset: Vector2i, true_roles: Dictionary, pts: Dictionary):
	first_started = true
	player_disconnected = false
	color_to_role = true_roles
	color_to_pts = pts
	
	killed = 0
	
	$StartMenu.visible = false
	$HUD/ScoreBoard.visible = true
	$Map.erase_maze(maze, offset)
	$Map.build_maze(maze, offset)
	
	var role = "PLACEHOLDER"
	for child in get_tree().get_nodes_in_group("player"):
		if child.has_method("starter"):
			child.starter(true_roles)
			child.visible = true
			child.position = $Map.get_start_position(maze, offset)
			child.get_node("AnimatedSprite2D").position = Vector2(0, 0)
			# spaghetti code >.<
			var temp = child.starter(true_roles)
			if temp != "":
				role = temp

	for color in color_to_pts_label:
		color_to_pts_label[color].text = "- " + str(color_to_pts[color]) + " pts"

	$HUD/Role.text = "You are a " + role + ". . ."
	if role == "sheriff":
		$HUD/Gun.visible = true 
		$HUD/Gun.modulate = Color(1,1,1)
	elif role == "rat":
		$HUD/Knife.visible = true
		$HUD/KnifeCooldown.visible = true
	
	$TimerCanvasLayer.start(1000*60)
	$WinScreen/MiceWin.visible = false
	$WinScreen/RatWins.visible = false
	$WinScreen/Again.visible = false
	$WinScreen/PlayerDisconnected.visible = false
	$WinScreen/num_players.visible = false
	$AudioStreamPlayer.stream = mice_active_music
	$AudioStreamPlayer.play()
	$TimerCanvasLayer/Panel/TimeLeft.label_settings.font_color = Color(1.0, 1.0, 1.0)
	game_ended = false

func _on_timer_timeout() -> void:
	$TimerCanvasLayer.end_timer.rpc()
	_end_game.rpc(false, false, false)

@rpc("call_local", "reliable", "any_peer")
func _end_game(mice_win: bool, sheriff_win: bool, player_discon: bool) -> void:
	if game_ended:
		return
	print("game ended!!!")
	game_ended = true
	$TimerCanvasLayer.end_timer.rpc()
	$AudioStreamPlayer.stop()
	$HUD/Gun.visible = false
	$HUD/Knife.visible = false
	$HUD/KnifeCooldown.visible = false
	if player_discon:
		$WinScreen/PlayerDisconnected.visible = true
	else:
		if mice_win:
			$WinScreen/MiceWin.visible = true
			$AudioStreamPlayer.stream = mice_victory_sound
			$AudioStreamPlayer.play()
		else:
			$TimerCanvasLayer/Panel/TimeLeft.text = "00 : 00 : 000"
			$WinScreen/RatWins.visible = true
			$AudioStreamPlayer.stream = rat_victory_sound
			$AudioStreamPlayer.play()
	
	# reset player positions and lock
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("disable_movement"):
			player.disable_movement()
			player.reset_sprite_to_defaults()
		player.global_position = Vector2i(0, 0)
		
	if !player_discon:
		if mice_win:
			for color in color_to_role:
				if color_to_role[color] != "rat":
					color_to_pts[color] += 1
				if sheriff_win and color_to_role[color] == "sheriff":
					color_to_pts[color] += 1
		else:
			for color in color_to_role:
				if color_to_role[color] == "rat":
					color_to_pts[color] += 2
	
	for color in color_to_pts_label:
		color_to_pts_label[color].text = "- " + str(color_to_pts[color]) + " pts"
		
	if is_host: # allow only host to start new game
		$WinScreen/Again.visible = true
		$WinScreen/num_players.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var cooldown = -1
	if player_disconnected and not game_ended:
		_end_game.rpc(false, false, true)
	for player in get_tree().get_nodes_in_group("player"):
		if not player.has_method("get_role"):
			continue
			
		# Check end game
		var player_tile = $Map/Exit.local_to_map(player.global_position)
		if $Map/Exit.get_cell_source_id(player_tile) != -1 and not game_ended and player.get_role() != "rat":
			_end_game.rpc(true, false, false)
		if player.get_role() == "rat" and not game_ended and not player.is_alive():
			_end_game.rpc(true, true, false)
			
		# Check sheriff shot
		if player.get_shot() == true:
			$HUD/Gun.modulate=Color(60/255.0,60/255.0,60/255.0)
			
		# Check rat kill time
		cooldown = max(cooldown, player.get_kill_cooldown())
	
	if killed == 3 and not game_ended:
		_end_game.rpc(false, false, false)
		
	if cooldown > 0:
		#print(cooldown)
		$HUD/Knife.modulate=Color(60/255.0,60/255.0,60/255.0)
		$HUD/KnifeCooldown.text = "[center]" + str(cooldown)
	else:
		$HUD/Knife.modulate=Color(1, 1, 1)
		$HUD/KnifeCooldown.clear()
		
	if Input.is_action_just_pressed("HELP"):
		$HelpControl.visible = !$HelpControl.visible
	
	if Input.is_action_just_pressed("LEFT") and $HelpControl.visible:
		$HelpControl/Left.emit_signal("button_down")
	
	if Input.is_action_just_pressed("RIGHT") and $HelpControl.visible:
		$HelpControl/Right.emit_signal("button_down")
		
	if Input.is_action_just_pressed("TOGGLE LIGHT"):
		$Darkness.visible = !$Darkness.visible

func _on_again_button_pressed() -> void:
	# make a new maze
	$Map._ready()
	var maze = $Map.get_maze()
	var offset = $Map.get_offset()
	random_role_assignment()
	start_helper.rpc(maze, offset, color_to_role, color_to_pts)

# assign random roles to colors based on existing roles and colors
func random_role_assignment():
	var colors = color_to_role.keys()
	colors.shuffle()
	var roles = color_to_role.values()
	roles.shuffle()
	color_to_role.clear()
	for i in range(colors.size()):
		color_to_role[colors[i]] = roles[i]

func _on_title_screen_animation_finished():
	$StartMenu/Skip.visible = false
	$StartMenu/host.visible = true
	$StartMenu/join.visible = true
	$StartMenu/label.visible = true
	$StartMenu/ip.visible = true
	
	$AudioStreamPlayer.stream = title_sound
	$AudioStreamPlayer.play()

func _on_skip_pressed() -> void:
	show_title_menu()

func _on_title_sequence_finished() -> void:
	show_title_menu()

func show_title_menu() -> void:
	$StartMenu/VideoContainer.visible = false
	$StartMenu/TitleScreen.visible = true
	$StartMenu/Skip.visible = false
	$StartMenu/host.visible = true
	$StartMenu/join.visible = true
	$StartMenu/label.visible = true
	$StartMenu/ip.visible = true
	
	$AudioStreamPlayer.stream = title_sound
	$AudioStreamPlayer.play()
