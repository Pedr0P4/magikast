extends BasePower

func _ready() -> void:
	print("_ready do fireball");
	if not data:
		data = load("res://resources/fireball.tres");
