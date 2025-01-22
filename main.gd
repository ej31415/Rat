extends Node2D

var peer = ENetMultiplayerPeer.new()
@export var gray_mouse: PackedScene
@export var brown_mouse: PackedScene
@export var sb_mouse: PackedScene
@export var tan_mouse: PackedScene
var mice = []
var color_to_role = {}
var color_to_instance = {}
var game_ended = false

func _init() -> void:
	gray_mouse = preload("res://gray_mouse.tscn")
	brown_mouse = preload("res://brown_mouse.tscn")
	sb_mouse = preload("res://sb_mouse.tscn")
	tan_mouse = preload("res://tan_mouse.tscn")
	mice = [[gray_mouse, "gray"], [brown_mouse, "brown"], [sb_mouse, "sb"], [tan_mouse, "tan"]]

func _on_host_pressed():
	peer.create_server(135)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	_add_player()
	$start.disabled = false

func _add_player(id = 1):
	if len(mice) > 0:
		var rng = RandomNumberGenerator.new()
		var idx = rng.randi_range(0, len(mice) - 1)
		var mouse = mice[idx][0]
		var color = mice[idx][1]
		var player = mouse.instantiate()
		color_to_role[color] = player.get_role()
		color_to_instance[color] = player
		mice.pop_at(idx)
		player.name = str(id)
		call_deferred("add_child", player)

func _on_join_pressed():
	peer.create_client($ip.text, 135)
	multiplayer.multiplayer_peer = peer

func _on_start_pressed():
	var maze = $Map.get_maze()
	var offset = $Map.get_offset()
	start_helper.rpc(maze, offset, color_to_role)

@rpc("call_local")
func start_helper(maze: Array, offset: Vector2i, true_roles: Dictionary):
	$label.visible = false
	$ip.visible = false
	$host.visible = false
	$join.visible = false
	$start.visible = false
	$Map.erase_maze(maze, offset)
	$Map.build_maze(maze, offset)
	for child in get_tree().get_nodes_in_group("player"):
		if child.has_method("starter"):
			child.starter(true_roles)
	$TimerCanvasLayer.start(1000*120)
		
# Constructed for testing purposes only.

## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#$GrayMouse.start($StartPosition.position)

func _end_game() -> void:
	game_ended = true
	$TimerCanvasLayer.end_timer.rpc()
	$WinScreen/MiceWin.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for player in get_tree().get_nodes_in_group("player"):
		var player_tile = $Map/Exit.local_to_map(player.global_position)
		if $Map/Exit.get_cell_source_id(player_tile) != -1 and not game_ended and player.get_role() != "rat":
			_end_game()
