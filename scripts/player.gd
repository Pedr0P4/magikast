class_name Player
extends CharacterBody2D

const DEFAULT_SPEED: float = 200.0;

@onready var power_spot: Marker2D = $PowerSpot;
@onready var cd: Timer = $PowerCooldown;
@onready var pt: Timer = $ParalyzeTime;
@onready var bt: Timer = $BurnTime;
@onready var burn_tick: Timer = $BurnTick;
@onready var name_label: Label = $Name;
@onready var paralyzed_animation: AnimatedSprite2D = $Paralyzed;
@onready var burning_effect: Node2D = $Burning;
@onready var life_bar: ProgressBar = $LifeBar;

@export var is_paralyzed: bool = false:
	set(value):
		is_paralyzed = value;
		_update_paralyzed_animation();
@export var is_burning: bool = false:
	set(value):
		is_burning = value;
		_update_burning_effect();
@export var health: int = 100:
	set(value):
		if(value <= 0):
			health = 0;
			life_bar.value = 0;
			die();
		else: 
			health = value;
			if life_bar: life_bar.value = value;
@export var shield: int = 0:
	set(value):
		if(value <= 0):
			shield = 0;
		else: shield = value;
@export var speed: float = 200.0;
var current_power: PowerData;

var can_shoot: bool = true;
var player_name: String;
var player_id: int;

func _ready() -> void:
	if paralyzed_animation:
		paralyzed_animation.visible = false
	if is_multiplayer_authority():
		life_bar.value = health;
		name_label.text = NetworkHandler.players[multiplayer.get_unique_id()]["name"];
		cd.timeout.connect(_on_cd_timeout);
		pt.timeout.connect(_on_pt_timeout);
		burn_tick.timeout.connect(_deal_burn_damage);
		bt.timeout.connect(_on_bt_timeout);

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return;
	
	if event.is_action_pressed("attack") and can_shoot and current_power:
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

func die() -> void:
	if not multiplayer.is_server(): 
		return
		
	var winner_name = "Oponente"
	
	for id in NetworkHandler.players:
		if id != self.player_id:
			winner_name = NetworkHandler.players[id]["name"]
			break
	
	var game_node = get_tree().current_scene
	if game_node.has_method("show_game_over"):
		game_node.show_game_over.rpc(winner_name)

@rpc("any_peer", "call_remote", "reliable")
func take_damage(damage: int) -> void:
	if is_multiplayer_authority():
		health -= damage;

@rpc("any_peer", "call_remote", "reliable")
func paralyze() -> void:
	if not is_multiplayer_authority(): return;
	print(player_name + " Paralisado!");
	speed = 0.0;
	can_shoot = false;
	is_paralyzed = true;
	pt.start();

@rpc("any_peer", "call_remote", "reliable")
func burn() -> void:
	if not is_multiplayer_authority(): return;
	burn_tick.start(0.5);
	bt.start();

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
	if not paralyzed_animation: return;
	
	if is_paralyzed:
		paralyzed_animation.visible = true;
		paralyzed_animation.play();
	else:
		paralyzed_animation.visible = false;
		paralyzed_animation.stop();

func _update_burning_effect() -> void:
	if not burning_effect: return;
	
	if is_burning: 
		burning_effect.visible = true;
	else: burning_effect.visible = false;

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

func _deal_burn_damage() -> void:
	if not is_multiplayer_authority(): return;
	health -= 2;

func _on_bt_timeout() -> void:
	if not is_multiplayer_authority(): return;
	is_burning = false;
	burn_tick.stop();
