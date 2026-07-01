extends Control

@onready var username_input: LineEdit = $MarginContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer/UsernameInput
@onready var display_name_input: LineEdit = $MarginContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer2/DisplayNameInput
@onready var password_input: LineEdit = $MarginContainer/Panel/MarginContainer/VBoxContainer/VBoxContainer3/PasswordInput
@onready var register_button: Button = $MarginContainer/Panel/MarginContainer/VBoxContainer/Button
@onready var login_button: Button = $MarginContainer/Panel/MarginContainer/VBoxContainer/LoginButton
@onready var status_label: Label = $MarginContainer/Panel/MarginContainer/VBoxContainer/StatusLabel

func _ready() -> void:
	register_button.pressed.connect(_on_register_pressed)
	if login_button:
		login_button.pressed.connect(_on_login_pressed)
		
	ApiHandler.register_success.connect(_on_register_success)
	ApiHandler.register_error.connect(_on_register_error)
	if status_label:
		status_label.text = ""

func _on_register_pressed() -> void:
	var user = username_input.text.strip_edges()
	var disp = display_name_input.text.strip_edges()
	var pass_text = password_input.text
	
	if user == "" or pass_text == "":
		if status_label: status_label.text = "Username e Password são obrigatórios!"
		return
		
	if status_label: status_label.text = "Registrando no servidor..."
	register_button.disabled = true
	ApiHandler.register(user, disp, pass_text)

func _on_login_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/login.tscn")

func _on_register_success(_data: Dictionary) -> void:
	if status_label: status_label.text = "Conta criada com sucesso!"
	get_tree().change_scene_to_file("res://scenes/UI/menu.tscn")

func _on_register_error(msg: String) -> void:
	register_button.disabled = false
	if status_label: status_label.text = msg

