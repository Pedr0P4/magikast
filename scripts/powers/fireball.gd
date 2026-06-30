extends BasePower

func _ready() -> void:
	super();
	if not data:
		data = load("res://resources/fireball.tres");
