extends Node2D

class_name Main

var peer = ENetMultiplayerPeer.new()
@export var gray_mouse: PackedScene
@export var brown_mouse: PackedScene
@export var sb_mouse: PackedScene
@export var tan_mouse: PackedScene
var mice_active_music

var mice = []
var color_to_role = {}
var color_to_pts = {
	"gray": 0,
	"sb": 0,
	"tan": 0,
	"brown": 0
}
var color_to_pts_label = {
	"gray": $HUD/ScoreBoard/GrayPts,
	"sb": $HUD/ScoreBoard/SBPts,
	"tan": $HUD/ScoreBoard/TanPts,
	"brown": $HUD/ScoreBoard/BrownPts
}
var game_ended = false
var is_host = false

static var killed = 0

func _init() -> void:
	gray_mouse = preload("res://gray_mouse.tscn")
	brown_mouse = preload("res://brown_mouse.tscn")
	sb_mouse = preload("res://sb_mouse.tscn")
	tan_mouse = preload("res://tan_mouse.tscn")
	mice_active_music = preload("res://assets/Music/mice_active_music.mp3")
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

func _on_host_pressed():
	peer.create_server(135)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	_add_player()
	$StartMenu/start.disabled = false
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
		mice.pop_at(idx)
		player.name = str(id)
		call_deferred("add_child", player)

func _on_join_pressed():
	peer.create_client($StartMenu/ip.text, 135)
	multiplayer.multiplayer_peer = peer
	$StartMenu/host.disabled = true
	$StartMenu/join.disabled = true

func _on_start_pressed():
	var maze = $Map.get_maze()
	var offset = $Map.get_offset()
	start_helper.rpc(maze, offset, color_to_role)

@rpc("call_local", "reliable")
func start_helper(maze: Array, offset: Vector2i, true_roles: Dictionary):
	color_to_role = true_roles
	
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
			# spaghetti code >.<
			var temp = child.starter(true_roles)
			if temp != "":
				role = temp
		
	$HUD/Role.text = "You are a " + role + ". . ."
	$TimerCanvasLayer.start(1000*120)
	$WinScreen/MiceWin.visible = false
	$WinScreen/RatWins.visible = false
	$WinScreen/Again.visible = false
	$AudioStreamPlayer2D.playing = true
	$TimerCanvasLayer/Panel/TimeLeft.label_settings.font_color = Color(1.0, 1.0, 1.0)
	game_ended = false

func _on_timer_timeout() -> void:
	$TimerCanvasLayer.end_timer.rpc()
	_end_game.rpc(false, false)

@rpc("call_local", "reliable", "any_peer")
func _end_game(mice_win: bool, sheriff_win: bool) -> void:
	if game_ended:
		return
	print("game ended!!!")
	game_ended = true
	$TimerCanvasLayer.end_timer.rpc()
	$AudioStreamPlayer2D.playing = false
	if mice_win:
		$WinScreen/MiceWin.visible = true
	else:
		$TimerCanvasLayer/Panel/TimeLeft.text = "00 : 00 : 000"
		$WinScreen/RatWins.visible = true
	
	# reset player positions and lock
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("disable_movement"):
			player.disable_movement()
		player.global_position = Vector2i(0, 0)
	
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if not player.has_method("get_role"):
			continue
		var player_tile = $Map/Exit.local_to_map(player.global_position)
		if $Map/Exit.get_cell_source_id(player_tile) != -1 and not game_ended and player.get_role() != "rat":
			_end_game.rpc(true, false)
		if player.get_role() == "rat" and not game_ended and not player.is_alive():
			_end_game.rpc(true, true)
	if killed == 3 and not game_ended:
		_end_game.rpc(false, false)
		
	if Input.is_action_just_pressed("HELP"):
		$HelpControl.visible = !$HelpControl.visible
	
	if Input.is_action_just_pressed("TOGGLE LIGHT"):
		$Darkness.visible = !$Darkness.visible

func _on_again_button_pressed() -> void:
	# make a new maze
	$Map._ready()
	var maze = $Map.get_maze()
	var offset = $Map.get_offset()
	random_role_assignment()
	start_helper.rpc(maze, offset, color_to_role)

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
	$StartMenu/host.visible = true
	$StartMenu/join.visible = true
	$StartMenu/start.visible = true
	$StartMenu/label.visible = true
	$StartMenu/ip.visible = true
