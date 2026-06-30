class_name Player
extends CharacterBody2D

const DEFAULT_SPEED: float = 200.0;

@export var is_paralyzed: bool = false:
	set(value):
		is_paralyzed = value
		_update_paralyzed_animation()
@export var speed: float = 200.0;
var current_power: PowerData;

@onready var power_spot: Marker2D = $PowerSpot;
@onready var cd: Timer = $PowerCooldown;
@onready var pt: Timer = $ParalyzeTime;
@onready var name_label: Label = $Name;
@onready var paralyzed_animation: AnimatedSprite2D = $Paralyzed;

var can_shoot: bool = true;
var player_name: String;
var player_id: int;

func _ready() -> void:
	if paralyzed_animation:
		paralyzed_animation.visible = false
	if is_multiplayer_authority():
		name_label.text = NetworkHandler.players[multiplayer.get_unique_id()]["name"];
		cd.timeout.connect(_on_cd_timeout);
		pt.timeout.connect(_on_pt_timeout);

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return;
	
	if event.is_action_pressed("attack") and can_shoot:
		request_attack.rpc_id(1, rotation);
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

@rpc("any_peer", "call_remote", "reliable")
func paralyze() -> void:
	if not is_multiplayer_authority(): return;
	print(player_name + " Paralisado!");
	speed = 0.0;
	can_shoot = false;
	is_paralyzed = true;
	pt.start();

@rpc("any_peer", "call_local", "reliable")
func request_attack(player_rotation: float) -> void:
	var power: BasePower = current_power.scene.instantiate();
	var sender_id: int = multiplayer.get_remote_sender_id();
	
	print(current_power.power_name);
	
	power.data = current_power;
	power.name = "Proj_" + str(sender_id) + "_" + str(Time.get_ticks_usec());
	power.rotation = player_rotation;
	power.global_position = power_spot.global_position;
	get_node("../../Projectiles").add_child(power);

func _update_paralyzed_animation() -> void:
	if not paralyzed_animation: return
	
	if is_paralyzed:
		paralyzed_animation.visible = true;
		paralyzed_animation.play();
	else:
		paralyzed_animation.visible = false;
		paralyzed_animation.stop();

func _on_cd_timeout() -> void:
	if is_multiplayer_authority():
		can_shoot = true;

func _on_pt_timeout() -> void:
	if not is_multiplayer_authority(): return;
	can_shoot = true;
	is_paralyzed = false;
	speed = DEFAULT_SPEED;
	paralyzed_animation.stop();
	paralyzed_animation.visible = false;
