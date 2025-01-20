extends Control

var main = preload("res://main.tscn").instantiate()
var peer = ENetMultiplayerPeer.new()

func _on_host_pressed():
	peer.create_server(135)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(main._add_player)
	main._add_player()
	$start.disabled = false

func _on_join_pressed():
	peer.create_client($ip.text, 135)
	multiplayer.multiplayer_peer = peer

func _on_start_pressed():
	start_helper.rpc()

@rpc("any_peer", "call_local")
func start_helper():
	get_tree().root.add_child(main)
	self.hide()
