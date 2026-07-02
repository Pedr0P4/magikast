extends Node

signal players_changed;
signal server_closed;
signal network_error(reason: String);

const MAX_PLAYERS = 2;
const DEFAULT_IP = "127.0.0.1";
const DEFAULT_PORT: int = 7777;
const JOINING = "Joining";
const JOINED = "Joined";

var peer = ENetMultiplayerPeer.new();
var current_dialog: Node = null;

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

func host_game(port: int = DEFAULT_PORT, host_name: String = "Host") -> bool:
	var err = peer.create_server(port, MAX_PLAYERS);
	if err != OK:
		print("Erro ao criar o servidor: ", err);
		var msg = "Falha ao criar a sala na porta %d (Erro: %s). A porta já pode estar em uso." % [port, _get_error_string(err)]
		network_error.emit(msg);
		return false;
	
	multiplayer.multiplayer_peer = peer;
	print("Servidor (Host) iniciado na porta ", str(port));
	players[peer.get_unique_id()] = {
		"name" : host_name,
		"status" : JOINED
	};
	return true;

func join_game(ip: String = DEFAULT_IP, port: int = DEFAULT_PORT, client_name: String = "Player") -> bool:
	var err = peer.create_client(ip, port);
	if err != OK:
		print("Erro ao configurar o cliente: ", err);
		var msg = "Falha ao inicializar o cliente de rede (Erro: %s). Verifique o IP e a porta." % _get_error_string(err)
		network_error.emit(msg);
		return false;
	
	multiplayer.multiplayer_peer = peer;
	print("Tentando conectar ao IP: ", ip);
	players[peer.get_unique_id()] = {
		"name" : client_name,
		"status" : JOINING
	};
	return true;

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
	network_error.emit("Não foi possível conectar à sala. Verifique se o IP e a porta estão corretos ou se a sala existe/está cheia.")

func _on_server_disconnected():
	# Disparado no cliente se o host fechar o jogo
	print("O servidor foi fechado.")
	players.clear();
	multiplayer.multiplayer_peer = null
	server_closed.emit()
	network_error.emit("A conexão com o servidor foi encerrada.")

# ==============================================================================
# SISTEMA DE ALERTAS / ERROS DE REDE
# ==============================================================================

func show_error_dialog(msg: String, on_close: Callable = Callable()) -> void:
	if is_instance_valid(current_dialog):
		current_dialog.queue_free();
		
	var canvas = CanvasLayer.new();
	canvas.layer = 100;
	get_tree().root.add_child(canvas);
	
	var overlay = ColorRect.new();
	overlay.color = Color(0, 0, 0, 0.6);
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);
	canvas.add_child(overlay);
	
	var panel = Panel.new();
	panel.custom_minimum_size = Vector2(420, 180);
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER);
	panel.offset_left = -210;
	panel.offset_top = -90;
	panel.offset_right = 210;
	panel.offset_bottom = 90;
	overlay.add_child(panel);
	
	var margin = MarginContainer.new();
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);
	margin.add_theme_constant_override("margin_left", 20);
	margin.add_theme_constant_override("margin_top", 20);
	margin.add_theme_constant_override("margin_right", 20);
	margin.add_theme_constant_override("margin_bottom", 20);
	panel.add_child(margin);
	
	var vbox = VBoxContainer.new();
	vbox.add_theme_constant_override("separation", 15);
	margin.add_child(vbox);
	
	var title = Label.new();
	title.text = "Aviso de Rede";
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;
	title.modulate = Color(1, 0.35, 0.35);
	vbox.add_child(title);
	
	var label = Label.new();
	label.text = msg;
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL;
	vbox.add_child(label);
	
	var btn = Button.new();
	btn.text = "OK";
	btn.custom_minimum_size = Vector2(120, 35);
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER;
	btn.size_flags_vertical = Control.SIZE_SHRINK_END;
	vbox.add_child(btn);
	
	var cleanup = func():
		if is_instance_valid(canvas):
			canvas.queue_free();
		if on_close.is_valid():
			on_close.call();
			
	btn.pressed.connect(cleanup);
	btn.grab_focus();
	
	current_dialog = canvas;

func _get_error_string(err: int) -> String:
	match err:
		ERR_ALREADY_IN_USE:
			return "Porta ou recurso já em uso";
		ERR_CANT_CREATE:
			return "Não foi possível criar o socket";
		ERR_CANT_RESOLVE:
			return "Não foi possível resolver o endereço IP";
		ERR_CONNECTION_ERROR:
			return "Erro de conexão";
		ERR_TIMEOUT:
			return "Tempo limite excedido";
		_:
			return "Código " + str(err);

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
