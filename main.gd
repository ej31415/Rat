extends Node2D

class_name Main

enum modes {NORMAL, BOUNTY}

var peer = ENetMultiplayerPeer.new()
var mode = modes.NORMAL
@export var gray_mouse: PackedScene
@export var brown_mouse: PackedScene
@export var sb_mouse: PackedScene
@export var tan_mouse: PackedScene
var title_sound; var mice_active_music; var mice_victory_sound; var rat_victory_sound
var got_mice_music; var got_rat_music; var got_sheriff_music
var scrn_maze_exit; var scrn_maze_exit_addon
var scrn_sheriff; var scrn_sheriff_addon
var scrn_rat_kills; var scrn_rat_kills_addon
var scrn_timeout; var scrn_timeout_addon
var scrn_bounty_addon
var gray_head; var sb_head; var tan_head; var brown_head
var knife; var bloody_knife

var id_to_username = {}
var mice = []
var color_to_role = {}
var color_to_pts = {}
var color_to_pts_label = {}
var color_to_xhair = {}
var color_to_baseinst = {}
var color_to_color = {}
var color_to_code = {}
var color_to_kills = {}
var lb_sprites = []
var id_to_color = {}
var role_to_desc = {}
var game_ended = false
var is_host = false
var first_started = false
var player_disconnected = false
var my_color = ""
var bounty_colors = []

static var rat_killed = 0
static var sheriff_killed = 0

var POINT_THRESHOLD := 11

var quickstart_called = false

func _init() -> void:
	gray_mouse = preload("res://gray_mouse.tscn")
	brown_mouse = preload("res://brown_mouse.tscn")
	sb_mouse = preload("res://sb_mouse.tscn")
	tan_mouse = preload("res://tan_mouse.tscn")
	mice = [[gray_mouse, "gray"], [brown_mouse, "brown"], [sb_mouse, "sb"], [tan_mouse, "tan"]]
	knife = preload("res://assets/UI/Knife icon no blood.png")
	bloody_knife = preload("res://assets/UI/Knife icon blood.png")
	
	_load_music()
	_load_win_screens()

func _load_music():
	title_sound = preload("res://assets/Music/Start Title.mp3")
	got_mice_music = preload("res://assets/Music/boom.mp3")
	got_rat_music = preload("res://assets/Music/dark boom.mp3")
	got_sheriff_music = preload("res://assets/Music/Cowboy.mp3")
	mice_active_music = preload("res://assets/Music/mice_active_music.mp3")
	mice_victory_sound = preload("res://assets/Music/Mice Win Sound.mp3")
	rat_victory_sound = preload("res://assets/Music/Rat Win Sound.mp3") 
	
func _load_win_screens():
	scrn_maze_exit = preload("res://assets/Win Screens/Maze exit Win screen no rat.png")
	scrn_maze_exit_addon = preload("res://assets/Win Screens/Win screens maze exit found rat.png")
	scrn_sheriff = preload("res://assets/Win Screens/Sheriff win .png")
	scrn_sheriff_addon = preload("res://assets/Win Screens/Sheriff win text and gun.png")
	scrn_rat_kills = preload("res://assets/Win Screens/Rat win kill everybody.png")
	scrn_rat_kills_addon = preload("res://assets/Win Screens/Rat win kill everybody text and knife.png")
	scrn_timeout = preload("res://assets/Win Screens/Rat win timeout .png")
	scrn_timeout_addon = preload("res://assets/Win Screens/Rat win timeout text and clock.png")
	scrn_bounty_addon = preload("res://assets/Win Screens/Bounty claimed gun and blood.png")

func _ready():
	color_to_pts = {
		"gray": 0,
		"sb": 0,
		"tan": 0,
		"brown": 0
	}
	color_to_xhair = {
		"gray": $HUD/ScoreBoard/GrayHeadX,
		"sb": $HUD/ScoreBoard/SBHeadX,
		"tan": $HUD/ScoreBoard/TanHeadX,
		"brown": $HUD/ScoreBoard/BrownHeadX
	}
	color_to_pts_label = {
		"gray": [$HUD/ScoreBoard/GrayPts, $WinScreen/ScoreDetails/GrayOld, $WinScreen/ScoreDetails/GrayDiff],
		"sb": [$HUD/ScoreBoard/SBPts, $WinScreen/ScoreDetails/SBOld, $WinScreen/ScoreDetails/SBDiff],
		"tan": [$HUD/ScoreBoard/TanPts, $WinScreen/ScoreDetails/TanOld, $WinScreen/ScoreDetails/TanDiff],
		"brown": [$HUD/ScoreBoard/BrownPts, $WinScreen/ScoreDetails/BrownOld, $WinScreen/ScoreDetails/BrownDiff]
	}
	color_to_baseinst = {
		"gray": gray_mouse,
		"sb": sb_mouse,
		"tan": tan_mouse,
		"brown": brown_mouse
	}
	color_to_color = {
		"tan": "green",
		"sb": "blue",
		"gray": "yellow",
		"brown": "red"
	}
	color_to_code = {
		"red": Color("#ff5e60"),
		"yellow": Color("#b69500"),
		"blue": Color("#0069ed"),
		"green": Color("#48ac4f")
	}
	lb_sprites = [
		$HUD/Leaderboard/FirstMouse,
		$HUD/Leaderboard/SecondMouse,
		$HUD/Leaderboard/ThirdMouse,
		$HUD/Leaderboard/FourthMouse
	]
	role_to_desc = {
		"mouse": "Escape!",
		"sheriff": "Kill the rat or escape!",
		"rat": "Kill or delay the mice!"
	}
	
	$output.add_to_group("output")

	# instant-start for debugging
	var args = Array(OS.get_cmdline_args())
	if args.has("--quickstart") and not quickstart_called:
		quickstart_called = true
		_quick_start() # Usage guide is immediately above the function def
	multiplayer.server_disconnected.connect(_on_server_disconnect)

# To use quick-start:
# 1. "Debug" -> "Customize Run Instances" -> Add "--quickstart" to main run arguments
# 2. Start up game with 4 instances
# 3. Press host button on one of the instances within 3 seconds. Game should then start up automatically
func _quick_start():
	_on_skip_pressed()
	await get_tree().create_timer(3).timeout
	if !is_host:
		_on_join_pressed()
	await get_tree().create_timer(0.5).timeout
	if is_host:
		_on_start_pressed()
		
func _register_username_wrapper():
	_register_username.rpc(peer.get_unique_id(), $StartMenu/username.text)
	$StartMenu/username.editable = false
	
@rpc("call_local", "reliable", "any_peer")
func _register_username(id: int, text: String):
	# probably add some error checking later
	id_to_username[id] = text
	print("Mapped " + str(id) + " to " + text)

func _on_host_pressed():
	$SoundEffects.play()
	peer.create_server(135)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)
	_add_player()
	$StartMenu/start.visible = true
	$StartMenu/num_players.visible = true
	$StartMenu/host.disabled = true
	$StartMenu/join.disabled = true
	$StartMenu/ip.editable = false
	_register_username_wrapper()
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
		$WinScreen/CheckBoxButton.disabled = false

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
	$WinScreen/RestartTimer.stop()
	$WinScreen/CheckBoxButton.uncheck()
	$WinScreen/CheckBoxButton.disabled = true

func _on_server_disconnect():
	if first_started:
		$TimerCanvasLayer.end_timer()
		$AudioStreamPlayer.stop()
		$WinScreen/Background.visible = false
		$WinScreen/Again.visible = false
		$WinScreen/WinArt.visible = false
		$WinScreen/BountyWin.visible = false
		$WinScreen/WinAddon.visible = false
		$WinScreen/PlayerDisconnected.visible = false
		$WinScreen/num_players.visible = false
		$WinScreen/CheckBoxButton.visible = false
		$WinScreen/WinDetails.visible = false
		$HUD.visible = false
		$StartMenu.visible = false
		set_physics_process(false)
		$WinScreen/RestartTimer.stop()
		$WinScreen/ServerDisconnected.visible = true

func _on_join_pressed():
	$SoundEffects.play()
	$StartMenu/ip.editable = false
	var error = peer.create_client($StartMenu/ip.text, 135)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		multiplayer.connected_to_server.connect(_register_username_wrapper)
		$StartMenu/host.disabled = true
		$StartMenu/join.disabled = true
		$StartMenu/error.visible = false
		$StartMenu/joined.visible = true
		$StartMenu/disconnect.visible = true
	else:
		$StartMenu/error.visible = true
		$StartMenu/ip.editable = true

func _on_disconnect_pressed():
	$SoundEffects.play()
	peer.close()
	multiplayer.multiplayer_peer = peer
	Player.roles = Player.roles_copy.duplicate()
	$StartMenu/disconnect.visible = false
	$StartMenu/join.disabled = false
	$StartMenu/error.visible = false
	$StartMenu/host.disabled = false
	$StartMenu/joined.visible = false
	$StartMenu/username.editable = true
	$StartMenu/ip.editable = true

func _change_roles():
	if "gray" in color_to_role:
		$WinScreen/ScoreDetails/GrayRole.text = "[center]" + color_to_role["gray"].capitalize()
	if "sb" in color_to_role:
		$WinScreen/ScoreDetails/SBRole.text = "[center]" + color_to_role["sb"].capitalize()
	if "tan" in color_to_role:
		$WinScreen/ScoreDetails/TanRole.text = "[center]" + color_to_role["tan"].capitalize()
	if "brown" in color_to_role:
		$WinScreen/ScoreDetails/BrownRole.text = "[center]" + color_to_role["brown"].capitalize()

func _disable_role_screens() -> void:
	$RoleScreen/Background/Mouse.visible = false
	$RoleScreen/Background/Sheriff.visible = false
	$RoleScreen/Background/Rat.visible = false

func _paint_role_screen(scn: CanvasGroup, color_name: String) -> void:
	scn.get_node("Role").add_theme_color_override("font_color", color_to_code[color_to_color[color_name]])
	scn.get_node("Mouse").modulate = color_to_code[color_to_color[color_name]]

func _on_start_pressed():
	$SoundEffects.play()
	var maze = $Map.get_maze()
	var offset = $Map.get_offset()
	start_helper.rpc(maze, offset, [id_to_color, color_to_role, id_to_username, color_to_pts])

@rpc("call_local", "reliable")
func start_helper(maze: Array, offset: Vector2i, true_vals: Array):
	first_started = true
	player_disconnected = false
	id_to_color = true_vals[0]
	color_to_role = true_vals[1]
	id_to_username = true_vals[2]
	print(true_vals[3])
	color_to_pts = true_vals[3]
	for color in color_to_pts:
		color_to_kills[color] = 0
	
	rat_killed = 0
	sheriff_killed = 0
	
	$StartMenu.visible = false
	$HUD/ScoreBoard.visible = true
	$HUD/Leaderboard.visible = false
	$WinScreen/ScoreDetails.visible = false
	$HUD/ScoreBoard.visible = true
	$Map.erase_maze(maze, offset)
	$Map.build_maze(maze, offset)
	
	var role = "PLACEHOLDER"
	var color_player = Color(1, 1, 1)
	for child in get_tree().get_nodes_in_group("player"):
		if child.has_method("starter"):
			var spawn_pos: Vector2i = $Map.get_spawn_area(maze, 4, 4).pick_random()
			var out = child.starter(color_to_role, id_to_username, id_to_color)
			child.visible = true
			child.position = $Map/Floor.map_to_local(Vector2i(spawn_pos.y, spawn_pos.x) + offset)
			child.reset_sprite_to_defaults()
			
			# Extract necessary statuses
			if out[0] != "":
				role = out[0]
			if out[1] != Color(1, 1, 1):
				color_player = out[1]
			if out[2] != "":
				my_color = out[2]
	
	_disable_role_screens()
	$RoleScreen.visible = true
	$RoleScreen/Background.modulate.a = 1
	
	if role == "sheriff":
		$RoleScreen/Background/Sheriff.visible = true
		_paint_role_screen($RoleScreen/Background/Sheriff, my_color)
		$AudioStreamPlayer.stream = got_sheriff_music
		$AudioStreamPlayer.play()
	elif role == "rat":
		$RoleScreen/Background/Rat.visible = true
		_paint_role_screen($RoleScreen/Background/Rat, my_color)
		$AudioStreamPlayer.stream = got_rat_music
		$AudioStreamPlayer.play()
	elif role == "mouse":
		$RoleScreen/Background/Mouse.visible = true
		_paint_role_screen($RoleScreen/Background/Mouse, my_color)
		$AudioStreamPlayer.stream = got_mice_music
		$AudioStreamPlayer.play()
	
	
	await get_tree().create_timer(3).timeout
	var tween := get_tree().create_tween()
	var role_screen_color: Color = $RoleScreen/Background.modulate
	role_screen_color.a = 0
	tween.tween_property($RoleScreen/Background, "modulate", role_screen_color, 1)
	
	if color_to_pts.values() == [0,0,0,0]:
		$HUD/PointGoal.text = "First to " + str(POINT_THRESHOLD) + " points wins!"
		$HUD/PointGoal.visible = true
		$HUD/PointGoal.modulate = Color("#ffffffff")
		fade_out_point_goal()
	elif mode == modes.BOUNTY:
		if my_color in bounty_colors:
			$HUD/PointGoal.text = "YOU ARE THE BOUNTY!"
		else:
			$HUD/PointGoal.text = "KILL THE BOUNTY!"
		$HUD/PointGoal.visible = true
		$HUD/PointGoal.modulate = Color("#ffffffff")
		fade_out_point_goal()
		
	for color in color_to_pts_label:
		color_to_pts_label[color][0].text = " " + str(color_to_pts[color]) + " pts"
		if color_to_pts[color] < POINT_THRESHOLD - 3:
			color_to_pts_label[color][0].flashing = false
			color_to_pts_label[color][0].modulate.a = 1
			color_to_xhair[color].visible = false
	
	$HUD/PlayerAvatar.modulate = color_player
	$HUD/PlayerAvatar.visible = true
	$HUD/Role.text = role.capitalize()
	$HUD/Role.visible = true
	$HUD/Objective.text = role_to_desc[role]
	$HUD/Objective.visible = true
	if role == "sheriff":
		$HUD/Gun.visible = true 
		$HUD/Gun.modulate = Color(1, 1, 1, 1)
	elif role == "rat":
		$HUD/Knife.visible = true
		$HUD/Knife.modulate = Color(1, 1, 1, 1)
		$HUD/KnifeCooldown.visible = true
		$HUD/Stamina.visible = true
		$HUD/Minimap.visible = true
	elif role == "mouse":
		$HUD/Cheese.visible = true
		$HUD/Cheese.modulate = Color(1, 1, 1, 1)
		$HUD/CheeseCooldown.visible = true
	
	$TimerCanvasLayer.start(1000*60)
	$WinScreen/Background.visible = false
	$WinScreen/WinArt.visible = false
	$WinScreen/BountyWin.visible = false
	$WinScreen/WinAddon.visible = false
	$WinScreen/WinDetails.visible = false
	$WinScreen/Again.visible = false
	$WinScreen/PlayerDisconnected.visible = false
	$WinScreen/num_players.visible = false
	$WinScreen/CheckBoxButton.visible = false
	$AudioStreamPlayer.stream = mice_active_music
	$AudioStreamPlayer.play()
	$TimerCanvasLayer/Panel/TimeLeft.label_settings.font_color = Color(1.0, 1.0, 1.0)
	$HUD/Minimap/MarginContainer.set_target()
	game_ended = false
	
func fade_out_point_goal():
	await get_tree().create_timer(2).timeout
	var tween := get_tree().create_tween()
	tween.tween_property($HUD/PointGoal, "modulate", Color("#ffffff00"), 1)
	
func _on_timer_timeout() -> void:
	$TimerCanvasLayer.end_timer.rpc()
	_end_game.rpc(false, false, true, false, "", [])

func ascending_compare(a, b):
	if a[1] < b[1]:
		return false
	return true

func show_leaderboard():
	# get winners
	var lb := []
	for color in color_to_pts:
		lb.append([color, color_to_pts[color]])
	lb.sort_custom(ascending_compare)
	print(lb)
	var pt_labels := [
		$HUD/Leaderboard/TextureRect/PointsOne,
		$HUD/Leaderboard/TextureRect/PointsTwo,
		$HUD/Leaderboard/TextureRect/PointsThree,
		$HUD/Leaderboard/TextureRect/PointsFour
	]
			
	for i in range(len(lb)):
		lb_sprites[i].modulate = color_to_code[color_to_color[lb[i][0]]]
		pt_labels[i].text = str(color_to_pts[lb[i][0]]) + " pts"
	
	if is_host:
		$HUD/Leaderboard/TextureRect/Button.disabled = false
		$HUD/Leaderboard/TextureRect/Button.text = "Start another game"
	else:
		$HUD/Leaderboard/TextureRect/Button.disabled = true
		$HUD/Leaderboard/TextureRect/Button.text = "Waiting for host to start another game..."
	$HUD/Leaderboard.visible = true

@rpc("call_local", "reliable")
func reset_scores() -> void:
	mode = modes.NORMAL
	bounty_colors.clear()
	$HUD/ScoreBoard/GrayHeadX.visible = false
	$HUD/ScoreBoard/SBHeadX.visible = false
	$HUD/ScoreBoard/TanHeadX.visible = false
	$HUD/ScoreBoard/BrownHeadX.visible = false
	for color in color_to_pts:
		color_to_pts[color] = 0
		
func _count_kills():
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("get_color"):
			var killer = player.killer_color
			if killer != "":
				color_to_kills[killer] += 1
	print(color_to_kills)

@rpc("call_local", "reliable", "any_peer")
func _end_game(mice_win: bool, sheriff_win: bool, time_out: bool, player_discon: bool, escaped_color: String, bounty_pack: Array):
	if game_ended:
		return
	game_ended = true
	if is_host:
		_end_game_helper.rpc(mice_win, sheriff_win, time_out, player_discon, escaped_color, bounty_pack)

@rpc("call_local", "reliable")
func _end_game_helper(mice_win: bool, sheriff_win: bool, time_out: bool, player_discon: bool, escaped_color: String, bounty_pack: Array) -> void:
	print("game ended!!!")
	$TimerCanvasLayer.end_timer.rpc()
	game_ended = true
	await get_tree().create_timer(1).timeout
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("die") and player.get_node("AnimationPlayer") != null:
			player.get_node("AnimationPlayer").stop()
			player.get_node("AnimationPlayer").clear_queue()
			player.get_node("SoundEffects").stop()
	_count_kills()
	$AudioStreamPlayer.stop()
	$HUD/Gun.visible = false
	$HUD/Knife.visible = false
	$HUD/KnifeCooldown.visible = false
	$HUD/Stamina.visible = false
	$HUD/Minimap.visible = false
	$HUD/Cheese.visible = false
	$HUD/CheeseCooldown.visible = false
	$WinScreen/Again.disabled = false
	$WinScreen/CheckBoxButton.check()
	_change_roles()

	if player_discon:
		$WinScreen/PlayerDisconnected.visible = true
	else:
		$WinScreen/WinAddon.modulate = Color(1, 1, 1, 1)
		if mode == modes.BOUNTY and len(bounty_pack) == 2:
			$WinScreen/WinAddon.texture = scrn_bounty_addon
			$WinScreen/BountyWin/Winner.modulate = color_to_code[color_to_color[bounty_pack[0]]]
			$WinScreen/BountyWin/Loser.modulate = color_to_code[color_to_color[bounty_pack[1]]]
			$WinScreen/WinDetails.text = ""
		elif mice_win:
			if sheriff_win:
				$WinScreen/WinArt.texture = scrn_sheriff
				$WinScreen/WinAddon.texture = scrn_sheriff_addon
				var sheriff_color
				for color in color_to_role:
					if color_to_role[color] == "rat":
						for player in get_tree().get_nodes_in_group("player"):
							if player.has_method("get_color") and player.color == color:
								sheriff_color = color_to_color[player.killer_color]
								break
				$WinScreen/WinArt.modulate = color_to_code[sheriff_color]
				$WinScreen/WinDetails.text = "[center]The sheriff has killed the rat!"
			else:
				var fixed_color = color_to_color[escaped_color]
				$WinScreen/WinArt.texture = scrn_maze_exit
				$WinScreen/WinAddon.texture = scrn_maze_exit_addon
				$WinScreen/WinArt.modulate = Color(1, 1, 1, 1)
				$WinScreen/WinAddon.modulate = color_to_code[fixed_color]
				$WinScreen/WinDetails.text = "[center]The " + fixed_color + " mouse escaped!"
			$AudioStreamPlayer.stream = mice_victory_sound
			$AudioStreamPlayer.play()
		else:
			var rat_color
			for color in color_to_role:
				if color_to_role[color] == "rat":
					rat_color = color_to_color[color]
			$TimerCanvasLayer/Panel/TimeLeft.text = "00 : 00 : 000"
			if time_out:
				$WinScreen/WinArt.texture = scrn_timeout
				$WinScreen/WinAddon.texture = scrn_timeout_addon
				$WinScreen/WinDetails.text = "[center]Time ran out . . ."
			else:
				$WinScreen/WinArt.texture = scrn_rat_kills
				$WinScreen/WinAddon.texture = scrn_rat_kills_addon
				$WinScreen/WinDetails.text = "[center]The rat killed everyone . . ."
			$WinScreen/WinArt.modulate = color_to_code[rat_color]
			$AudioStreamPlayer.stream = rat_victory_sound
			$AudioStreamPlayer.play()
		$WinScreen/Background.visible = true
		if mode == modes.BOUNTY and len(bounty_pack) != 0:
			$WinScreen/BountyWin.visible = true
		else:
			$WinScreen/WinArt.visible = true
		$WinScreen/WinAddon.visible = true
		$WinScreen/WinDetails.visible = true
	
	# reset player positions and lock
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("disable_movement"):
			player.disable_movement()
			player.reset_sprite_to_defaults()
		player.global_position = Vector2i(0, 0)
	
	bounty_colors.clear()
	
	var old_scores = self.color_to_pts.duplicate()
		
	if !player_discon:
		if mice_win:
			for color in color_to_role:
				if color_to_role[color] != "rat":
					color_to_pts[color] += 1
				if sheriff_win:
					if color_to_role[color] == "sheriff" and color == escaped_color:
						color_to_pts[color] += 3
					if color_to_role[color] == "rat":
						color_to_pts[color] -= 1
				elif color == escaped_color:
					color_to_pts[color] += 2
		else:
			for color in color_to_role:
				if color_to_role[color] == "rat" and time_out:
						color_to_pts[color] += 1
				if len(bounty_pack) != 0:
					if color == bounty_pack[0]:
						color_to_pts[color] += 2
					elif color == bounty_pack[1]:
						color_to_pts[color] -= 2
		
		# rat gets points for each kill, sheriff deducted for each kill
		for color in color_to_role:
			if color_to_role[color] == "rat":
				color_to_pts[color] += rat_killed
			elif (color_to_role[color] == "sheriff" and len(bounty_pack) == 0) or (len(bounty_pack) != 0 and color != bounty_pack[0]):
				color_to_pts[color] -= color_to_kills[color]
	
	for color in color_to_pts_label:
		color_to_pts_label[color][0].text = " " + str(color_to_pts[color]) + " pts"
		color_to_pts_label[color][1].text = " " + str(color_to_pts[color]) + " pts"
		var diff = color_to_pts[color] - old_scores[color]
		if diff > 0:
			color_to_pts_label[color][2].modulate = Color(0, 1, 0)
			color_to_pts_label[color][2].text = "(+" + str(diff) + ")"
		elif diff < 0:
			color_to_pts_label[color][2].modulate = Color(1, 0, 0)
			color_to_pts_label[color][2].text = "(" + str(diff) + ")"
		else:
			color_to_pts_label[color][2].modulate = Color(1, 1, 1)
			color_to_pts_label[color][2].text = "(" + str(diff) + ")"
	$WinScreen/ScoreDetails.visible = true
	$HUD/PlayerAvatar.visible = false
	$HUD/Role.visible = false
	$HUD/Objective.visible = false
	$HUD/ScoreBoard.visible = false
	
	var bounty_found = false
	for color in color_to_pts:
		if color_to_pts[color] >= POINT_THRESHOLD:
			$WinScreen/CheckBoxButton.uncheck()
			$WinScreen/Again.disabled = true
			await get_tree().create_timer(2).timeout
			show_leaderboard()
		if color_to_pts[color] >= POINT_THRESHOLD - 3:
			mode = modes.BOUNTY
			bounty_found = true
			bounty_colors.append(color)
			color_to_pts_label[color][0].flashing = true
			color_to_xhair[color].visible = true
		else:
			color_to_pts_label[color][0].flashing = false
			color_to_pts_label[color][0].modulate.a = 1
			color_to_xhair[color].visible = false
			
	if not bounty_found:
		mode = modes.NORMAL
	
	if is_host: # allow only host to start new game
		$WinScreen/Again.visible = true
		$WinScreen/num_players.visible = true
		$WinScreen/CheckBoxButton.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("LEFT") and $HelpControl.visible:
		$HelpControl/Left.emit_signal("button_down")
	
	if Input.is_action_just_pressed("RIGHT") and $HelpControl.visible:
		$HelpControl/Right.emit_signal("button_down")
		
	if Input.is_action_just_pressed("TOGGLE LIGHT"):
		$Darkness.visible = !$Darkness.visible
	
	if is_host and game_ended:
		refresh_play_again_button()
	
	if game_ended:
		return
		
	if player_disconnected:
		_end_game.rpc(false, false, false, true, "", [])
	
	for player in get_tree().get_nodes_in_group("player"):
		if not player.has_method("get_role"):
			continue
			
		# Check end game
		if not player.is_alive() and mode == modes.BOUNTY and bounty_colors.has(player.get_color()):
			var bounty_claimer = player.killer_color
			var bounty_claimed = player.color
			_end_game.rpc(false, false, false, false, "", [bounty_claimer, bounty_claimed])
		
		var player_tile = $Map/Exit.local_to_map(player.global_position)
		if $Map/Exit.get_cell_source_id(player_tile) != -1 and player.get_role() != "rat":
			_end_game.rpc(true, false, false, false, player.get_color(), [])
		if player.get_role() == "rat" and not player.is_alive():
			_end_game.rpc(true, true, false, false, player.killer_color, [])
			
		# Check sheriff shot
		if player.get_color() == my_color and (not player.is_alive() or player.get_shot() == true):
			$HUD/Gun.modulate = Color(60/255.0,60/255.0,60/255.0)
			
		# Check rat kill time
		if player.get_color() == my_color:
			var cooldown = player.get_kill_cooldown()
			if cooldown > 0:
				$HUD/Knife.modulate=Color(60/255.0,60/255.0,60/255.0)
				$HUD/KnifeCooldown.text = "[center]" + str(cooldown)
			else:
				$HUD/Knife.modulate=Color(1, 1, 1)
				$HUD/KnifeCooldown.clear()
			if rat_killed > 0:
				$HUD/Knife.texture = bloody_knife
			else:
				$HUD/Knife.texture = knife
		
		# Check stamina
		if $HUD/Stamina.visible and player.get_role() == "rat":
			$HUD/Stamina.value = player.get_stamina_value()
			if player.get_can_sprint():
				$HUD/Stamina.tint_progress = Color("#ffffff")
			else:
				$HUD/Stamina.tint_progress = Color("#f71f00")
		
		# Check cheese status
		if player.get_color() == my_color and player.get_role() == "mouse":
			var buff_progress_value = player.get_buff_progress()
			$HUD/Cheese.value = buff_progress_value
			if not player.is_alive():
				$HUD/Cheese.visible = false
				$HUD/CheeseCooldown.clear()
			elif buff_progress_value > 0:
				$HUD/Cheese.modulate = Color(1, 1, 1, 1)
				$HUD/Cheese.visible = true
				$HUD/Cheese.flashing = false
				$HUD/CheeseCooldown.clear()
			else:
				var cooldown = player.get_cheese_drop_cooldown()
				if player.has_buff:
					$HUD/Cheese.flashing = true
					$HUD/CheeseCooldown.clear()
				elif cooldown > 0:
					$HUD/Cheese.modulate.a = 0.5
					$HUD/CheeseCooldown.text = "[center]" + str(cooldown)
				else:
					$HUD/Cheese.flashing = false
					$HUD/Cheese.modulate = Color(1, 1, 1)
					$HUD/CheeseCooldown.clear()
	
	if rat_killed + sheriff_killed == 3:
		_end_game.rpc(false, false, false, false, "", [])

func _on_again_button_pressed() -> void:
	$WinScreen/Again.disabled = true
	$WinScreen/CheckBoxButton.uncheck()
	$SoundEffects.play()
	# make a new maze
	$Map._ready()
	var maze = $Map.get_maze()
	var offset = $Map.get_offset()
	#random_role_assignment()
	if is_host:
		print(color_to_pts)
		random_role_assignment()
	start_helper.rpc(maze, offset, [id_to_color, color_to_role, id_to_username, color_to_pts])

# assign random roles to colors based on existing roles and colors
func random_role_assignment():
	var colors = color_to_role.keys()
	var roles = ["mouse", "mouse", "sheriff", "rat"]
	roles.shuffle()
	color_to_role.clear()
	for i in range(colors.size()):
		var role = roles[i]
		if mode == modes.BOUNTY and role != "rat":
			color_to_role[colors[i]] = "sheriff"
		else:
			color_to_role[colors[i]] = role

func _on_skip_pressed() -> void:
	$SoundEffects.play()
	$StartMenu/VideoContainer/TitleSequence.stop()
	_on_title_sequence_finished()

func _on_title_sequence_finished() -> void:
	show_title_menu()
	$HelpControl.visible = true

func show_title_menu() -> void:
	$StartMenu/VideoContainer.visible = false
	$StartMenu/TitleScreen.visible = true
	$StartMenu/Skip.visible = false
	$StartMenu/host.visible = true
	$StartMenu/join.visible = true
	$StartMenu/username.visible = true
	$StartMenu/label.visible = true
	$StartMenu/ip.visible = true
	
	$HUD/HelpMessage.visible = true
	
	$AudioStreamPlayer.stream = title_sound
	$AudioStreamPlayer.stream.loop = true
	$AudioStreamPlayer.play()

func refresh_play_again_button() -> void:
	if $WinScreen/CheckBoxButton.checked and $WinScreen/RestartTimer.is_stopped():
		$WinScreen/RestartTimer.start()
	elif (!$WinScreen/CheckBoxButton.checked and !$WinScreen/RestartTimer.is_stopped()):
		$WinScreen/RestartTimer.stop()
	
	if $WinScreen/RestartTimer.is_stopped():
		$WinScreen/Again.text = "Play Again"
	else:
		$WinScreen/Again.text = "Play Again " + "(" + str(ceil($WinScreen/RestartTimer.time_left)) + ")"

func _on_restart_timer_timeout() -> void:
	if game_ended:
		$WinScreen/Again.emit_signal("pressed")
		

func _on_lb_close_button_click() -> void:
	$WinScreen/CheckBoxButton.check()
	$WinScreen/Again.disabled = false
	$HUD/Leaderboard.visible = false
	reset_scores.rpc()
	_on_again_button_pressed()

# TODO: connect more signals to this function
func _on_any_button_click() -> void:
	$SoundEffects.play()

func _on_help_message_pressed() -> void:
	$HelpControl.visible = !$HelpControl.visible
