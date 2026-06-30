extends BasePower

func _ready() -> void:
	super();
	if not data:
		data = load("res://resources/wind_shield.tres");
