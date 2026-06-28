class_name Player
extends CharacterBody2D

@export var speed: float = 200.0;

@onready var power_spot: Marker2D = $PowerSpot;
@onready var cd: Timer = $CooldownTest;

var can_shoot: bool = true;

var player_name: String;
var player_id: int;
var shoot_scene: PackedScene = preload("res://scenes/shoot.tscn");

func _ready() -> void:
	if is_multiplayer_authority():
		cd.timeout.connect(_on_cd_timeout);

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return;
	
	if event.is_action_pressed("attack") and can_shoot:
		request_attack.rpc_id(1, rotation, global_position);
		can_shoot = false;
		cd.start();
		print(player_name + " atirou!");

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return;
	
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down");
	
	if direction != Vector2.ZERO:
		velocity = direction * speed;
	else:
		velocity = Vector2.ZERO;
	
	move_and_slide();
	look_at(get_global_mouse_position());

@rpc("any_peer", "call_local", "reliable")
func request_attack(player_rotation: float, player_position: Vector2) -> void:
	var shoot: Area2D = shoot_scene.instantiate();
	var shooter_id: int = multiplayer.get_remote_sender_id();
	
	shoot.name = "Proj_" + str(shooter_id) + "_" + str(Time.get_ticks_usec());
	shoot.rotation = player_rotation;
	shoot.global_position = player_position;
	get_node("../../Projectiles").add_child(shoot);

func _on_cd_timeout() -> void:
	if is_multiplayer_authority():
		can_shoot = true;
