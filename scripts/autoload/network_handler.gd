extends Node

signal players_changed;
signal server_closed;

const MAX_PLAYERS = 2;
const DEFAULT_IP = "127.0.0.1";
const DEFAULT_PORT: int = 7777;
const JOINING = "Joining";
const JOINED = "Joined";

var peer = ENetMultiplayerPeer.new();

var players: Dictionary;

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected);
	multiplayer.peer_disconnected.connect(_on_peer_disconnected);
	multiplayer.connected_to_server.connect(_on_connected_to_server);
	multiplayer.connection_failed.connect(_on_connection_failed);
	multiplayer.server_disconnected.connect(_on_server_disconnected);

# ==============================================================================
# MÉTODOS DE CONEXÃO
# ==============================================================================

func host_game(port: int = DEFAULT_PORT, host_name: String = "Host"):
	var err = peer.create_server(port, MAX_PLAYERS);
	if err != OK:
		print("Erro ao criar o servidor: ", err);
		return;
	
	multiplayer.multiplayer_peer = peer;
	print("Servidor (Host) iniciado na porta ", str(port));
	players[peer.get_unique_id()] = {
		"name" : host_name,
		"status" : JOINED
	};

func join_game(ip: String = DEFAULT_IP, port: int = DEFAULT_PORT, client_name: String = "Player"):
	var err = peer.create_client(ip, port);
	if err != OK:
		print("Erro ao configurar o cliente: ", err);
		return;
	
	multiplayer.multiplayer_peer = peer;
	print("Tentando conectar ao IP: ", ip);
	players[peer.get_unique_id()] = {
		"name" : client_name,
		"status" : JOINING
	};

# ==============================================================================
# CALLBACKS DOS SINAIS DE REDE
# ==============================================================================

func _on_peer_connected(id: int):
	# Disparado quando QUALQUER pessoa conecta (incluindo o host recebendo um cliente)
	print("Conectado: ", id);

func _on_peer_disconnected(id: int):
	# Disparado quando alguém sai ou a conexão cai
	print("Jogador desconectado: ", id);
	players.erase(id);
	
	if multiplayer.is_server():
		client_update_player_list.rpc(players);

func _on_connected_to_server():
	# Disparado APENAS no cliente quando ele entra na sala com sucesso
	print("Conexão com o servidor estabelecida com sucesso!");
	var id = multiplayer.get_unique_id();
	var cname = players[id]["name"];
	
	server_register_player.rpc_id(1, cname);

func _on_connection_failed():
	# Disparado no cliente se o IP/Porta não existirem ou houver bloqueio
	print("Falha ao tentar conectar. Verifique o IP ou o Firewall.")
	players.clear();
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	# Disparado no cliente se o host fechar o jogo
	print("O servidor foi fechado.")
	players.clear();
	multiplayer.multiplayer_peer = null
	server_closed.emit()

# ==============================================================================
# MÉTODOS RPC
# ==============================================================================

@rpc("any_peer", "call_remote", "reliable")
func server_register_player(client_name: String):
	var sender_id = multiplayer.get_remote_sender_id();

	# O servidor registra o cliente no dicionário dele
	players[sender_id] = {
		"name": client_name,
		"status": JOINED
	};

	# Agora que o servidor tem a lista atualizada, ele força TODOS os clientes
	# a atualizarem seus dicionários locais com a lista oficial do servidor.
	rpc("client_update_player_list", players);

@rpc("authority", "call_local", "reliable")
func client_update_player_list(server_player_dict: Dictionary):
	# Todos recebem a cópia exata do dicionário do servidor
	players = server_player_dict;
	print("Lista de jogadores atualizada na máquina ", multiplayer.get_unique_id(), ": ", players);
	players_changed.emit();
