extends Node

var players := {}
var peer_to_steam := {}  
var lobby_id = 0

func register_player(steam_id: int, node: Node):
	
	players[steam_id] = node
	print(players)
	#print(players)
	
func update_player_screen(steam_id: int, img: Image):
	print(steam_id, " ID")
	print("Players:",players.keys())
	#for i in players.values():
		
	#	if(!i.is_multiplayer_authority()):
			
	#		i.get_child(0).update_screen(img)
	var all_players = get_tree().get_nodes_in_group("players")
	for i in all_players:
		if(i.second_id == steam_id):
			i.get_child(0).update_screen(img)
	#if steam_id in players:
	#	players[steam_id].get_child(0).update_screen(img)
#		print(img)
func get_steam_id_from_peer(peer_id: int) -> int:
	return peer_to_steam.get(peer_id, 0)
