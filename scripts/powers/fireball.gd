extends BasePower

func _ready() -> void:
	if not data:
		data = load("res://resources/fireball.tres");
