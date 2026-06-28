extends Area2D

@export var speed: float = 600.0;

func _physics_process(delta: float) -> void:
	global_position += transform.x * speed * delta;

func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return;
	
	print(body.player_name + " Tomou");
	queue_free();
