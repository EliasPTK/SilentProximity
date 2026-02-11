extends Node3D

var lobby_id: int = 0
var peer: SteamMultiplayerPeer
@export var player_scene: PackedScene
@onready var host_button = $CanvasLayer/Host
@onready var join_button = $CanvasLayer/Join
var is_host: bool = false
var is_joining: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(Steam.steamInit(480, true))
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	# Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func host_lobby():
	Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, 8)
	is_host = true

func _on_lobby_created(result: int, lobby_id: int):
	if result == Steam.RESULT_OK:
		print("lobby created")
		self.lobby_id = lobby_id
		
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		
		peer.create_host()
		
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_add_player)
		multiplayer.peer_disconnected.connect(_remove_player)
		_add_player()
		print(lobby_id)
func join_lobby(lobby_id : int):
	is_joining = true
	Steam.joinLobby(lobby_id)
	
func _on_lobby_joined(lobby_id: int, permissions : int, locked: bool, response: int):
	
	if(! is_joining):
		return
	self.lobby_id = lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobby_id))
	multiplayer.multiplayer_peer = peer
	is_joining = false
	
func _add_player(id: int = 1):
	print("player added")
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child",player)

func _remove_player(id: int):
	if !self.has_node(str(id)):
		return
	self.get_node(str(id)).queue_free()

func _on_host_button():
	host_lobby()
	host_button.visible = false
	join_button.visible = false
	

func _on_join_button():
	join_lobby(int(join_button.get_child(0).text))
	host_button.visible = false
	join_button.visible = false
	
	
	
		
