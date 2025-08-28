## Server_Connection.gd
## Multiplayer server manager using ENet.
## Features:
## - Handles client connections and disconnections.
## - Keeps track of connected clients in a local list.
## - Creates the ENet server and binds it to Godot's multiplayer system.
extends Node
class_name Server_Connection

## ENet peer instance for hosting the server.
var eNet = ENetMultiplayerPeer.new()
## Array storing connected client metadata (dictionaries with "id" and other info).
var ClientsData = []


## Connects ENet signals when the node enters the tree.
func _ready() -> void:
	eNet.peer_connected.connect(_ClientConnect)
	eNet.peer_disconnected.connect(_ClientDisconnect)


## Triggered when a new client connects.
## Arguments:
## - id (int): Unique peer ID of the client.
func _ClientConnect(id):
	print("Client connected with ID %s" % id)


## Triggered when a client disconnects.
## Removes the client from ClientsData if found.
## Arguments:
## - id (int): Unique peer ID of the disconnected client.
func _ClientDisconnect(id):
	printerr("Client %s disconnected." % id)
	for i in range(ClientsData.size()):
		var player = ClientsData[i]
		if player.has("id") and player["id"] == id:
			print("Removing client %s" % ClientsData[i]["id"])
			ClientsData.remove_at(i)
			break


## Creates the ENet server and binds it to Godot's multiplayer system.
## Port: 5000
## Max peers: 4000
## Channels: 4
func _create_server() -> void:
	if eNet.create_server(5000, 4000, 4) == OK:
		multiplayer.multiplayer_peer = eNet
		print_rich("[color=green]Server created")
	else:
		printerr("Server is already active.")
