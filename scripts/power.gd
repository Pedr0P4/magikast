extends Area2D

@onready var fireball_icon: Sprite2D = $FireballIcon;
@onready var electric_icon: Sprite2D = $ElectricIcon;

# 1. O Setter! Sempre que o servidor mudar essa variável pela rede, o visual atualiza!
@export var is_fireball: bool = true:
	set(value):
		is_fireball = value
		_atualizar_icones()

func _ready() -> void:
	# 2. APENAS o servidor tem o direito de sortear o poder!
	if multiplayer.is_server():
		var x = randi_range(1, 100);
		is_fireball = (x > 0 and x <= 50)
	else:
		# Força o cliente a atualizar a tela caso os dados de rede cheguem antes do _ready
		_atualizar_icones()

func _atualizar_icones() -> void:
	# Segurança para evitar que o Godot reclame antes dos nós carregarem
	if not fireball_icon or not electric_icon: return
	
	if is_fireball:
		fireball_icon.visible = true;
		electric_icon.visible = false;
	else:
		fireball_icon.visible = false;
		electric_icon.visible = true;

func _on_body_entered(body: Node2D) -> void:
	# 3. PROTEÇÃO DE REDE: O Cliente NÃO tem permissão de coletar nem de deletar o nó!
	if not multiplayer.is_server(): return;
	
	if not body is Player: return;
	
	if is_fireball:
		body.current_power = load("res://resources/fireball.tres");
	else:
		body.current_power = load("res://resources/electric_bolt.tres");
		
	queue_free();
