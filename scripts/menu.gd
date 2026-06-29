extends Control

@onready var menu_buttons = $MenuButtons;
@onready var host_panel = $HostPanel;
@onready var join_panel = $JoinPanel;
@onready var back_button = $BackButton;
@onready var host_port_input = $HostPanel/MarginContainer/VBoxContainer/HBoxContainer/PortInput;
@onready var host_name_input = $HostPanel/MarginContainer/VBoxContainer/HBoxContainer2/NameInput;
@onready var client_ip_input = $JoinPanel/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/IPInput;
@onready var client_port_input = $JoinPanel/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer2/PortInput;
@onready var client_name_input = $JoinPanel/MarginContainer/VBoxContainer/HBoxContainer2/NameInput;

const PORT = 7777;
const JOINING = "Joining";
const JOINED = "Joined";

func _ready() -> void:
	iniciar_partida_debug();

func iniciar_partida_debug() -> void:
	var peer = ENetMultiplayerPeer.new()

	# Tenta criar o servidor
	var erro = peer.create_server(PORT, 4)

	if erro == OK:
		# Deu certo! Esta é a primeira janela que abriu.
		multiplayer.multiplayer_peer = peer
		NetworkHandler.players[multiplayer.get_unique_id()] = {
			"name" : "HOST",
			"status" : JOINED
		};
		get_tree().call_deferred("change_scene_to_file", "res://scenes/game.tscn")
	else:
		# Deu erro! A porta já está sendo usada pela Janela 1.
		# Então, vamos virar cliente e conectar nela!
		print("Porta ocupada. Virando CLIENTE e conectando...")

		# Limpa o peer antigo e cria um novo como cliente
		peer = ENetMultiplayerPeer.new()
		peer.create_client("127.0.0.1", PORT)
		multiplayer.multiplayer_peer = peer
		NetworkHandler.players[multiplayer.get_unique_id()] = {
			"name" : "CLIENT",
			"status" : JOINED
		};
		get_tree().call_deferred("change_scene_to_file", "res://scenes/game.tscn")

func _on_host_button_pressed() -> void:
	menu_buttons.visible = false;
	host_panel.visible = true;
	join_panel.visible = false;
	back_button.visible = true;
	
func _on_join_button_pressed() -> void:
	menu_buttons.visible = false;
	host_panel.visible = false;
	join_panel.visible = true;
	back_button.visible = true;

func _on_back_button_pressed() -> void:
	menu_buttons.visible = true;
	host_panel.visible = false;
	join_panel.visible = false;
	back_button.visible = false;

func _on_create_button_pressed() -> void:
	NetworkHandler.host_game(int(host_port_input.text), host_name_input.text);
	get_tree().change_scene_to_file("res://scenes/UI/lobby.tscn");

func _on_join_server_button_pressed() -> void:
	NetworkHandler.join_game(client_ip_input.text, int(client_port_input.text), client_name_input.text);
	get_tree().change_scene_to_file("res://scenes/UI/lobby.tscn");
