extends BasePower

func _ready() -> void:
	super();
	if not data:
		data = load("res://resources/fireball.tres");

func _on_body_entered_fireball(body: Node2D) -> void:
	if body.name == str(creator_id): return;
	if body.has_method("burn"):
		body.burn.rpc_id(body.player_id);
