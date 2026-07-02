extends Control

@onready var menu_buttons = $MenuButtons
@onready var host_panel = $HostPanel
@onready var join_panel = $JoinPanel
@onready var back_button = $BackButton
@onready var host_port_input = $HostPanel/MarginContainer/VBoxContainer/HBoxContainer/PortInput
@onready var host_name_input = $HostPanel/MarginContainer/VBoxContainer/HBoxContainer2/NameInput
@onready var client_ip_input = $JoinPanel/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/IPInput
@onready var client_port_input = $JoinPanel/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer2/PortInput
@onready var client_name_input = $JoinPanel/MarginContainer/VBoxContainer/HBoxContainer2/NameInput
@onready var user_info_label = $UserBar/UserInfoLabel
@onready var logout_button = $UserBar/LogoutButton

const PORT = 7777;
const LOCALHOST = "127.0.0.1";
const JOINING = "Joining";
const JOINED = "Joined";

func _ready() -> void:
	if logout_button:
		logout_button.pressed.connect(_on_logout_pressed)
	ApiHandler.stats_updated.connect(_update_profile_display)
	NetworkHandler.network_error.connect(_on_network_error)
	_update_profile_display()

func _on_network_error(msg: String) -> void:
	NetworkHandler.show_error_dialog(msg)

func _update_profile_display() -> void:
	var default_name = ApiHandler.display_name if ApiHandler.display_name != "" else (ApiHandler.user if ApiHandler.user != "" else "Player")
	if host_name_input and host_name_input.text == "":
		host_name_input.text = default_name
	if client_name_input and client_name_input.text == "":
		client_name_input.text = default_name
	if user_info_label:
		user_info_label.text = "Jogador: " + default_name + " | Vitórias: " + str(ApiHandler.victories) + " | Partidas: " + str(ApiHandler.matches) + " | Streak: " + str(ApiHandler.streak)

func _on_logout_pressed() -> void:
	ApiHandler.logout()
	get_tree().change_scene_to_file("res://scenes/UI/login.tscn")

func iniciar_partida_debug() -> void:
	var peer = ENetMultiplayerPeer.new()

	var erro = peer.create_server(PORT, 4)

	if erro == OK:
		multiplayer.multiplayer_peer = peer
		NetworkHandler.players[multiplayer.get_unique_id()] = {
			"name" : "HOST",
			"status" : JOINED
		}
		get_tree().call_deferred("change_scene_to_file", "res://scenes/game.tscn")
	else:
		print("Porta ocupada. Virando CLIENTE e conectando...")

		peer = ENetMultiplayerPeer.new()
		peer.create_client("127.0.0.1", PORT)
		multiplayer.multiplayer_peer = peer
		NetworkHandler.players[multiplayer.get_unique_id()] = {
			"name" : "CLIENT",
			"status" : JOINED
		}
		get_tree().call_deferred("change_scene_to_file", "res://scenes/game.tscn")

func _on_host_button_pressed() -> void:
	menu_buttons.visible = false
	host_panel.visible = true
	join_panel.visible = false
	back_button.visible = true
	
func _on_join_button_pressed() -> void:
	menu_buttons.visible = false
	host_panel.visible = false
	join_panel.visible = true
	back_button.visible = true

func _on_back_button_pressed() -> void:
	menu_buttons.visible = true
	host_panel.visible = false
	join_panel.visible = false
	back_button.visible = false

func _on_create_button_pressed() -> void:
	var default_name = ApiHandler.display_name if ApiHandler.display_name != "" else (ApiHandler.user if ApiHandler.user != "" else "HOST")
	if NetworkHandler.host_game(
		int(host_port_input.text) if client_port_input.text == "" else PORT, 
		host_name_input.text if host_name_input.text != "" else default_name):
		get_tree().change_scene_to_file("res://scenes/UI/lobby.tscn")

func _on_join_server_button_pressed() -> void:
	var default_name = ApiHandler.display_name if ApiHandler.display_name != "" else (ApiHandler.user if ApiHandler.user != "" else "CLIENT")
	if NetworkHandler.join_game(
		client_ip_input.text if client_ip_input.text else LOCALHOST, 
		int(client_port_input.text) if client_port_input.text else PORT, 
		client_name_input.text if client_name_input.text != "" else default_name
		):
		get_tree().change_scene_to_file("res://scenes/UI/lobby.tscn")
