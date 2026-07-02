extends Node2D

@onready var players_node: Node = $Players;
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner;
@onready var projectile_spawner: MultiplayerSpawner = $ProjectileSpawner;
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var winner_label: Label = $GameOverScreen/MarginContainer/WinnerLabel;

var player_scene: PackedScene = preload("res://scenes/player.tscn");
var game_over_triggered: bool = false;

func _ready() -> void:
	var viewport_size = get_viewport_rect().size
	var wall_thickness = 64.0
	
	_create_wall(
		Vector2(viewport_size.x / 2.0, -wall_thickness / 2.0), 
		Vector2(viewport_size.x, wall_thickness)
	)
	_create_wall(
		Vector2(viewport_size.x / 2.0, viewport_size.y + (wall_thickness / 2.0)), 
		Vector2(viewport_size.x, wall_thickness)
	)
	_create_wall(
		Vector2(-wall_thickness / 2.0, viewport_size.y / 2.0), 
		Vector2(wall_thickness, viewport_size.y)
	)
	_create_wall(
		Vector2(viewport_size.x + (wall_thickness / 2.0), viewport_size.y / 2.0), 
		Vector2(wall_thickness, viewport_size.y)
	)
	
	player_spawner.spawn_function = _spawn;
	NetworkHandler.network_error.connect(_on_network_error);
	NetworkHandler.server_closed.connect(_on_server_closed);
	if multiplayer.is_server():
		var players = NetworkHandler.players
		for p in players:
			spawn_player(p, players[p]["name"]);
		multiplayer.peer_connected.connect(_on_peer_connected);
		multiplayer.peer_disconnected.connect(_on_peer_disconnected);

func _create_wall(pos: Vector2, size: Vector2) -> void:
	var static_body = StaticBody2D.new()
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	
	rect_shape.size = size
	collision_shape.shape = rect_shape
	static_body.position = pos
	
	static_body.add_child(collision_shape)
	add_child(static_body)

func _on_peer_connected(id: int) -> void:
	var p_name = "Player " + str(id);
	if NetworkHandler.players.has(id):
		p_name = NetworkHandler.players[id]["name"]
	
	spawn_player(id, p_name)

func _on_peer_disconnected(id: int) -> void:
	# Deleta o boneco do jogador quando ele fechar a janela
	var player_node = players_node.get_node_or_null(str(id))
	if player_node:
		player_node.queue_free()

func _on_server_closed() -> void:
	NetworkHandler.show_error_dialog("A conexão com o servidor foi encerrada.", func():
		get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")
	)

func _on_network_error(msg: String) -> void:
	NetworkHandler.show_error_dialog(msg, func():
		get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")
	)

func spawn_player(id: int, player_name: String):
	player_spawner.spawn({"id": id, "name": player_name});

func _spawn(data: Variant) -> Player:
	var player: Player = player_scene.instantiate();
	player.player_id = data.id;
	player.name = str(data.id);
	player.player_name = data.name;
	var viewport_size = get_viewport_rect().size;
	player.global_position.x = randf_range(150.0, viewport_size.x - 150.0);
	player.global_position.y = randf_range(150.0, viewport_size.y - 150.0);
	player.set_multiplayer_authority(player.player_id);
	return player;

@rpc("any_peer", "call_local", "reliable")
func show_game_over(winner_name: String) -> void:
	if game_over_triggered:
		return;
	game_over_triggered = true;
	
	game_over_screen.visible = true
	winner_label.text = winner_name + " Venceu a Batalha!"
	
	var my_id = multiplayer.get_unique_id()
	var my_name = ""
	if NetworkHandler.players.has(my_id):
		my_name = str(NetworkHandler.players[my_id]["name"])
	var won = (winner_name == my_name)
	if ApiHandler:
		ApiHandler.record_match_end(won)
	
	get_tree().paused = true
	
	await get_tree().create_timer(4.0, true, false, true).timeout
	
	get_tree().paused = false
	
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")
