extends Node2D

var peer = ENetMultiplayerPeer.new()
@export var gray_mouse: PackedScene
@export var brown_mouse: PackedScene
@export var sb_mouse: PackedScene
@export var tan_mouse: PackedScene
var mice = []

func _init() -> void:
	gray_mouse = preload("res://gray_mouse.tscn")
	brown_mouse = preload("res://brown_mouse.tscn")
	sb_mouse = preload("res://sb_mouse.tscn")
	tan_mouse = preload("res://tan_mouse.tscn")
	mice = [gray_mouse, brown_mouse, sb_mouse, tan_mouse]

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
		var mouse = mice[idx]
		var player = mouse.instantiate()
		mice.pop_at(idx)
		player.name = str(id)
		call_deferred("add_child", player)

func _on_join_pressed():
	peer.create_client($ip.text, 135)
	multiplayer.multiplayer_peer = peer

func _on_start_pressed():
	var maze = $Map.get_maze()
	var offset = $Map.get_offset()
	start_helper.rpc(maze, offset)

@rpc("call_local")
func start_helper(maze: Array, offset: Vector2i):
	$Map.erase_maze(maze, offset)
	$Map.build_maze(maze, offset)
	for child in get_tree().get_nodes_in_group("player"):
		if not child.has_method("starter"):
			continue
		child.starter()
		
# Constructed for testing purposes only.

## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#$GrayMouse.start($StartPosition.position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
