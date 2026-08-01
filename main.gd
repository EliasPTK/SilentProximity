extends Node3D
var lobby_id: int = 0
var peer: SteamMultiplayerPeer
@export var player_scene: PackedScene
@export var test_scene: PackedScene
var is_host: bool = false
var is_joining: bool = false
@onready var join: Button = $CanvasLayer/Join
@onready var text_edit: LineEdit = $CanvasLayer/Join/LineEdit
@onready var host: Button = $CanvasLayer/Host


var ingame = false
func _ready() -> void:
	Steam.steamInit(480, true)
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	
func _on_lobby_chat_update(lobby_id: int, changed_id: int, making_change_id: int, chat_state: int):
	# changed_id is the Steam ID of the player who just joined
	# We need to wait a moment for their peer_id data to propagate
	await get_tree().create_timer(0.5).timeout
	var peer_id_str = Steam.getLobbyMemberData(lobby_id, changed_id, "peer_id")
	if peer_id_str != "":
		PlayerManager.peer_to_steam[int(peer_id_str)] = changed_id
	print(PlayerManager.peer_to_steam, "yar, peer to steam")
func host_lobby():
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_FRIENDS_ONLY,3)
	is_host = true
	
func _send_existing_mappings(new_peer_id: int):
	for peer_id in PlayerManager.peer_to_steam:
		var steam_id = PlayerManager.peer_to_steam[peer_id]
		# Tell the new player about every existing peer
		_receive_peer_mapping.rpc_id(new_peer_id, peer_id, steam_id)

@rpc("authority", "call_remote", "reliable")
func _receive_peer_mapping(peer_id: int, steam_id: int):
	PlayerManager.peer_to_steam[peer_id] = steam_id
	# Also register the player node if it exists already
	if has_node(str(peer_id)):
		PlayerManager.register_player(steam_id, get_node(str(peer_id)))
		
func _on_lobby_created(result: int, lobby_id: int):
	if result == Steam.Result.RESULT_OK:
		self.lobby_id = lobby_id
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_add_player)
		multiplayer.peer_disconnected.connect(_remove_player)
		$CanvasLayer/LobbyID.text = "Lobby ID: " + str(lobby_id)
		
		# Store host peer id in lobby data
		Steam.setLobbyMemberData(lobby_id, "peer_id", str(multiplayer.get_unique_id()))
		PlayerManager.peer_to_steam[1] = Steam.getSteamID()
		_add_player()
		
		PlayerManager.lobby_id = lobby_id
		
func _add_player(id: int = 1):
	print(id)
	var player = player_scene.instantiate()
	player.name = str(id)

	add_child(player)
	
	call_deferred("_sync_webcam_peers")
	if multiplayer.is_server() and id != 1:
		call_deferred("_send_existing_mappings", id)

func _register_player_deferred(steam_id: int, player: Node):
	if steam_id == 0:
		steam_id = Steam.getSteamID()
	PlayerManager.register_player(steam_id, player)

func join_lobby(lobby_id: int):
	$CanvasLayer/LobbyID.text = "Lobby ID: " + str(lobby_id)
	
	is_joining = true
	Steam.joinLobby(lobby_id)

func _on_lobby_joined(lobby_id: int,permissions: int, locked: bool, response: int):
	if not is_joining:
		return
	self.lobby_id = lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobby_id))
	multiplayer.multiplayer_peer = peer
	is_joining = false
	
	PlayerManager.lobby_id = lobby_id
	
	# Store our peer id in lobby data so other players can look us up
	Steam.setLobbyMemberData(lobby_id, "peer_id", str(multiplayer.get_unique_id()))
	
func _remove_player(id: int):
	if not self.has_node(str(id)):
		return
	var player = self.get_node(str(id))
	# Find and remove from PlayerManager
	for steam_id in PlayerManager.players.keys():
		if PlayerManager.players[steam_id] == player:
			PlayerManager.players.erase(steam_id)
			break
	player.queue_free()
	
	_sync_webcam_peers()


func _on_host_pressed() -> void:
	host_lobby()
	$CanvasLayer/Host.visible = false
	$CanvasLayer/Join.visible = false
	$CanvasLayer/Invite.visible = true
	
	print("Lobby count: " + str(Steam.getNumLobbyMembers(lobby_id)))
	ingame = true


func _on_join_pressed() -> void:
	join_lobby(int(text_edit.text))
	$CanvasLayer/Host.visible = false
	$CanvasLayer/Join.visible = false
	$CanvasLayer/Invite.visible = true
	
	print("Lobby count: " + str(Steam.getNumLobbyMembers(lobby_id)))
	ingame = true

func _get_all_steam_ids() -> Array[int]:
	var ids: Array[int] = []
	var member_count = Steam.getNumLobbyMembers(lobby_id)
	#print("mem count",member_count)
	for i in range(member_count):
		var steam_id = Steam.getLobbyMemberByIndex(lobby_id, i)
		# Don't include ourselves — we don't send to ourselves
		if steam_id != Steam.getSteamID():
			ids.append(steam_id)
	return ids

func _sync_webcam_peers():
	#print("sync em boys")
	var ids = _get_all_steam_ids()
	#print(ids)
	# Find the local authority player and update their webcam node
	var local_id = multiplayer.get_unique_id()
	if self.has_node(str(local_id)):
		var webcam = self.get_node(str(local_id)).get_node_or_null("CharacterBody3D/Camera3D/Node2D/Sprite2D")
		if webcam:
			webcam.connected_steam_ids = ids
			#print(webcam.connected_steam_ids)
			
func _on_invite_pressed() -> void:
	Steam.activateGameOverlayInviteDialog(lobby_id) # Replace with function body.
