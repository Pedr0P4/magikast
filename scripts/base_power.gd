class_name BasePower
extends Area2D

@export var explosion_animation: AnimatedSprite2D;

@onready var sprite: Sprite2D = $Sprite;

var creator_id: int;
var data: PowerData;

func _ready() -> void:
	if explosion_animation:
		explosion_animation.animation_finished.connect(_on_explosion_finished);
	else:
		print("ERRO: AnimatedSprite2D de explosão não está atribuído no Inspetor!");

func _physics_process(delta: float) -> void:
	if(data.is_attack):
		global_position += transform.x * data.speed * delta;

func _on_body_entered(body: Node2D) -> void:
	if body.name == str(creator_id): return;
	
	set_physics_process(false);
	
	sprite.visible = false;
	if explosion_animation:
		explosion_animation.visible = true;
		explosion_animation.play();
		print("Começou!");
	
	set_deferred("monitoring", false);
	
	if not multiplayer.is_server(): return;
	
	print(body.player_name + " Tomou");

func _on_explosion_finished() -> void:
	print("Terminou!");
	if multiplayer.is_server():
		queue_free();
		print("ACABOU A ANIMAÇÃO");
