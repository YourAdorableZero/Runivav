extends Node

var peer = ENetMultiplayerPeer.new()

var player_info = {"nickname": "Player", "vladiki": 10}
var players_info = {}

func _ready():
	$UI/game_name.text = ProjectSettings.get("application/config/name")
	$UI/game_version.text = ProjectSettings.get("application/config/version")
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.server_disconnected.connect(_on_disconnected)

#-------------------------------------------------------------------------------
#СЕРВЕР

func _on_player_connected(id = 1):
	pass

func _on_player_disconnected(id = 1):
	_remove_player_from_list(id)

#КЛИЕНТ

func _on_connected(id = 1):
	_show_screen("lobby")
	_add_player_to_list.rpc(player_info, multiplayer.get_unique_id())

func _on_disconnected(id = 1):
	players_info.clear()
	multiplayer.multiplayer_peer.disconnect_peer(1)
	_show_screen("menu")

#RPC шиза

@rpc("any_peer", "reliable")
func print_once_per_client():
	if multiplayer.is_server():
		print_once_per_client.rpc()

	print("I will be printed to the console once per each connected client.", multiplayer.get_unique_id())


@rpc("any_peer", "reliable")
func _add_player_to_list(new_player_info, new_player_id, server_players_info = null):
	if multiplayer.is_server():
		_add_player_to_list.rpc(new_player_info, new_player_id, players_info)
	
	if multiplayer.get_unique_id() == new_player_id:
		players_info = server_players_info

	players_info[new_player_id] = new_player_info
	_update_players_list()


@rpc("any_peer", "reliable")
func _remove_player_from_list(player_id):
	if multiplayer.is_server():
		_remove_player_from_list.rpc(player_id)

	players_info.erase(player_id)
	_update_players_list()

#-------------------------------------------------------------------------------
#РАБОТА С ВВОДОМ В МЕНЮ

func _on_host_pressed():
	var port = int($UI/menu/server_info/port_line.text)

	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	
	players_info[1] = player_info
	_update_players_list()
	_show_screen("lobby")


func _on_connect_pressed():
	var ip = $UI/menu/server_info/ip_line.text
	var port = int($UI/menu/server_info/port_line.text)

	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
	_show_screen("connecting")


func _on_disconnect_pressed():
	if multiplayer.is_server():
		multiplayer.multiplayer_peer.close()
	else:
		multiplayer.multiplayer_peer.disconnect_peer(1)
	_show_screen("menu")


func _on_cancel_pressed():
	multiplayer.multiplayer_peer.close()
	_show_screen("menu")


func _on_name_changed(new_text):
	player_info["nickname"] = $UI/menu/player_info/name.text

#-------------------------------------------------------------------------------
#РАБОТА С ИНТЕРФЕЙСОМ

func _show_screen(screen_name):
	$UI/menu.visible = screen_name == "menu"
	$UI/game_name.visible = screen_name == "menu"
	$UI/game_version.visible = screen_name == "menu"
	$UI/theme.visible = screen_name == "menu"
	
	$UI/connecting_screen.visible = screen_name == "connecting"
	
	$UI/label_lobby.visible = screen_name == "lobby"
	$UI/lobby.visible = screen_name == "lobby"


func _update_players_list():
	var players_container = $UI/lobby/scroll_container/players
	
	#TODO: Вместо полной очистки и добавления с нуля нужно работать с id в названии контейнера
	#Удаляем устаревший список игроков
	for i in range(0, players_container.get_child_count()):
		players_container.get_child(i).queue_free()

	#Добавляем актуальный список игроков
	for player_id in players_info:
		var player_info_container = preload("res://assets/player_info_container.tscn").instantiate()
		player_info_container.set_player_info(player_id, players_info[player_id]["nickname"])
		players_container.add_child(player_info_container)
