extends Node2D

var power_up_scene: PackedScene = preload("res://scenes/power.tscn");

@onready var spawn_timer: Timer = $SpawnTimer
@onready var container_itens: Node = $"../Powers"

func _ready() -> void:
	if multiplayer.is_server():
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
		spawn_timer.start(randi_range(4, 8));
		print("Servidor iniciou o gerador de itens.")

func _on_spawn_timer_timeout() -> void:
	if not multiplayer.is_server() or not power_up_scene: 
		return
	
	var viewport_size = get_viewport_rect().size
	var padding = 64.0
	
	var random_x = randf_range(padding, viewport_size.x - padding)
	var random_y = randf_range(padding, viewport_size.y - padding)
	var pos_sorteada = Vector2(random_x, random_y)
	
	var novo_poder = power_up_scene.instantiate()
	novo_poder.global_position = pos_sorteada
	
	novo_poder.name = "PowerUp_" + str(Time.get_ticks_usec())
	
	container_itens.add_child(novo_poder)
	
	print("Novo poder gerado na posição: ", pos_sorteada)
	
	spawn_timer.start(randi_range(5, 8))
