extends Node

# network class constants
const DEFAULT_IP = "127.0.0.1"
const DEFAULT_PORT = 32023
const MAX_PLAYERS = 4

var selected_port
var selected_IP

# default local id for the player
var localPLayerId = 0
#dictionary that holds players info, sync updates info on server & client
sync var players = {} 
sync var player_data = {}

# signals to send out during disconnection states
signal playerDisconnected
signal serverDisconnected

# when script loads, signals will be instantiated
func _ready():
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("network_peer_connected", self, "_on_player_connected")

# This function creates a server for the game
func create_server():
	var peer = NetworkedMultiplayerENet.new()
	
	peer.create_server(selected_port, MAX_PLAYERS, 0, 0)
	get_tree().set_network_peer(peer)
	add_to_player_list()
	

func connect_to_server():
	var peer = NetworkedMultiplayerENet.new()
	
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	peer.create_client(selected_IP, selected_port)
	get_tree().set_network_peer(peer)
	
# A unique local player id is created for the player
func add_to_player_list():
	localPLayerId = get_tree().get_network_unique_id()
	player_data = Saved.save_data
	players[localPLayerId] = player_data
	
# Connects player to the server
func _connected_to_server():
	add_to_player_list()
	rpc("_send_player_info", localPLayerId, player_data)

remote func _send_player_info(id, player_info):
	players[id] = player_info
	if localPLayerId == 1:
		rset("players", players)
		rpc("update_waiting_room")

func _on_player_connected(id):
	if not get_tree().is_network_server():
		print(str(id) + " has connected!")

sync func update_waiting_room():
	get_tree().call_group("WaitingRoom", "refresh_players", players)

func start_game():
	rpc("load_world")

sync func load_world():
	get_tree().change_scene("res://World/World.tscn")
	
	


