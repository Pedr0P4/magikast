extends Control

@onready var players_container = $Panel/MarginContainer/VBoxContainer/PlayersContainer;
@onready var start_button = $Panel/MarginContainer/VBoxContainer/StartButton;

var player_container_scene = preload("res://scenes/UI/player_container.tscn");

func _ready() -> void:
	NetworkHandler.players_changed.connect(_on_players_changed);
	NetworkHandler.server_closed.connect(_on_server_closed);
	NetworkHandler.network_error.connect(_on_network_error);
	update_players();
	
	if not multiplayer.is_server():
		start_button.visible = false;
	start_button.disabled = true;

func update_players() -> void:
	var players_connected = NetworkHandler.players;
	
	if players_connected.size() > 1 and multiplayer.is_server():
		start_button.disabled = false;
	
	for child in players_container.get_children():
		child.queue_free();
	for player in players_connected:
		var player_container = player_container_scene.instantiate();
		player_container.display_name = players_connected[player]["name"];
		players_container.add_child(player_container);

func _on_players_changed():
	update_players();

func _on_server_closed():
	NetworkHandler.show_error_dialog("A conexão com o servidor foi encerrada.", func():
		get_tree().change_scene_to_file("res://scenes/UI/menu.tscn");
	);

func _on_network_error(msg: String):
	NetworkHandler.show_error_dialog(msg, func():
		get_tree().change_scene_to_file("res://scenes/UI/menu.tscn");
	);
	
func _on_start_button_pressed() -> void:
	start_game.rpc();

@rpc("authority", "call_local", "reliable")
func start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn");
