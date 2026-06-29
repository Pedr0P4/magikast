extends Node2D

@onready var players_node: Node = $Players;
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner;
@onready var projectile_spawner: MultiplayerSpawner = $ProjectileSpawner;

var player_scene: PackedScene = preload("res://scenes/player.tscn");

func _ready() -> void:
	player_spawner.spawn_function = _spawn;
	if multiplayer.is_server():
		var players = NetworkHandler.players
		for p in players:
			spawn_player(p, players[p]["name"]);
		multiplayer.peer_connected.connect(_on_peer_connected);
		multiplayer.peer_disconnected.connect(_on_peer_disconnected);

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

func spawn_player(id: int, player_name: String):
	player_spawner.spawn({"id": id, "name": player_name});

func _spawn(data: Variant) -> Player:
	var player: Player = player_scene.instantiate();
	player.current_power = load("res://resources/fireball.tres");
	player.player_id = data.id;
	player.name = str(data.id);
	player.player_name = data.name;
	player.global_position.x = randi_range(200, 800);
	player.set_multiplayer_authority(player.player_id);
	return player;
