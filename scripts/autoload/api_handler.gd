extends Node

signal login_success(data: Dictionary)
signal login_error(message: String)
signal register_success(data: Dictionary)
signal register_error(message: String)
signal stats_updated

const BASE_URL: String = "http://127.0.0.1:8080/auth"

var token: String = ""
var user: String = ""
var display_name: String = ""
var matches: int = 0
var victories: int = 0
var streak: int = 0
var max_streak: int = 0

func _ready() -> void:
	pass

func _parse_response(body: PackedByteArray) -> Dictionary:
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error == OK and typeof(json.data) == TYPE_DICTIONARY:
		return json.data
	return {}

func _update_user_data(data: Dictionary) -> void:
	if data.has("token") and data["token"] != null and str(data["token"]) != "":
		token = str(data["token"])
	if data.has("user") and data["user"] != null:
		user = str(data["user"])
	if data.has("displayName") and data["displayName"] != null:
		display_name = str(data["displayName"])
	if data.has("matches") and data["matches"] != null:
		matches = int(data["matches"])
	if data.has("victories") and data["victories"] != null:
		victories = int(data["victories"])
	if data.has("streak") and data["streak"] != null:
		streak = int(data["streak"])
	if data.has("maxStreak") and data["maxStreak"] != null:
		max_streak = int(data["maxStreak"])
	stats_updated.emit()

func login(username_text: String, password_text: String) -> void:
	var req = HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		req.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS:
			login_error.emit("Erro de conexão com o servidor.")
			return
		var data = _parse_response(body)
		if response_code == 200:
			_update_user_data(data)
			login_success.emit(data)
		else:
			var msg = str(data.get("message", "Falha no login."))
			login_error.emit(msg)
	)
	var url = BASE_URL + "/login"
	var headers = ["Content-Type: application/json"]
	var body_json = JSON.stringify({"user": username_text, "password": password_text})
	req.request(url, headers, HTTPClient.METHOD_POST, body_json)

func register(username_text: String, display_name_text: String, password_text: String) -> void:
	var req = HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		req.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS:
			register_error.emit("Erro de conexão com o servidor.")
			return
		var data = _parse_response(body)
		if response_code == 200:
			_update_user_data(data)
			register_success.emit(data)
		else:
			var msg = str(data.get("message", "Falha ao registrar."))
			register_error.emit(msg)
	)
	var url = BASE_URL + "/register"
	var headers = ["Content-Type: application/json"]
	var body_json = JSON.stringify({"user": username_text, "displayName": display_name_text, "password": password_text})
	req.request(url, headers, HTTPClient.METHOD_POST, body_json)

func verify_token() -> void:
	if token == "":
		return
	var req = HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		req.queue_free()
		if response_code == 200:
			var data = _parse_response(body)
			_update_user_data(data)
	)
	var url = BASE_URL + "/verify"
	var headers = ["Authorization: Bearer " + token]
	req.request(url, headers, HTTPClient.METHOD_GET)

func record_match_end(won: bool) -> void:
	if token == "":
		return
	var req = HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		req.queue_free()
		if response_code == 200:
			var data = _parse_response(body)
			_update_user_data(data)
			print("Estatísticas da partida atualizadas no backend!")
	)
	var url = BASE_URL + "/match-end"
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + token]
	var body_json = JSON.stringify({"won": won})
	req.request(url, headers, HTTPClient.METHOD_POST, body_json)

func logout() -> void:
	token = ""
	user = ""
	display_name = ""
	matches = 0
	victories = 0
	streak = 0
	max_streak = 0
	stats_updated.emit()
