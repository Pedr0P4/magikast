extends Control

@onready var username_input: LineEdit = $MarginContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer/UsernameInput
@onready var password_input: LineEdit = $MarginContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer2/PasswordInput
@onready var login_button: Button = $MarginContainer/Panel/MarginContainer/VBoxContainer/Button
@onready var register_button: Button = $MarginContainer/Panel/MarginContainer/VBoxContainer/RegisterButton
@onready var status_label: Label = $MarginContainer/Panel/MarginContainer/VBoxContainer/StatusLabel

func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)
	if register_button:
		register_button.pressed.connect(_on_register_pressed)
	
	ApiHandler.login_success.connect(_on_login_success)
	ApiHandler.login_error.connect(_on_login_error)
	if status_label:
		status_label.text = ""

func _on_login_pressed() -> void:
	var user = username_input.text.strip_edges()
	var pass_text = password_input.text
	
	if user == "" or pass_text == "":
		if status_label: status_label.text = "Preencha todos os campos!"
		return
		
	if status_label: status_label.text = "Aguardando servidor..."
	login_button.disabled = true
	ApiHandler.login(user, pass_text)

func _on_register_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/register.tscn")

func _on_login_success(_data: Dictionary) -> void:
	if status_label: status_label.text = "Login realizado com sucesso!"
	get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")

func _on_login_error(msg: String) -> void:
	login_button.disabled = false
	if status_label: status_label.text = msg

