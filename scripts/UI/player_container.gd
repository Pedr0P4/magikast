extends Panel

@export var display_name: String;

@onready var name_label = $MarginContainer/HBoxContainer/NameLabel;

func _ready() -> void:
	name_label.text = display_name if display_name else "Player";
