class_name BasePower
extends Area2D

@onready var sprite: Sprite2D = $Sprite;
@onready var explosion: AnimatedSprite2D = $Explosion;
@onready var collision: CollisionShape2D = $Collision;

var creator_id: int;
var data: PowerData;

func _ready() -> void:
	print("_ready do base");
	monitoring = false
	
	if explosion and not explosion.animation_finished.get_connections():
		explosion.animation_finished.connect(_on_explosion_finished)
	
	await get_tree().physics_frame
	
	monitoring = true

func _physics_process(delta: float) -> void:
	if not data: return;
	if(data.is_attack):
		global_position += transform.x * data.speed * delta;

func _on_body_entered(body: Node2D) -> void:
	if body.name == str(creator_id): return;
	set_physics_process(false);
	
	sprite.visible = false;
	if explosion:
		print("ATIVOU A EXPLOSAO");
		explosion.visible = true;
		explosion.play();
	
	set_deferred("monitoring", false);
	
	if not multiplayer.is_server(): return;
	
	print(body.player_name + " Tomou");

func _on_explosion_finished() -> void:
	if multiplayer.is_server():
		queue_free();
