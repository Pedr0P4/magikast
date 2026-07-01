extends BasePower

func _ready() -> void:
	super();
	if not data:
		data = load("res://resources/electric_bolt.tres");

func _on_body_entered_electric(body: Node2D) -> void:
	if body.name == str(creator_id): return;
	if body.has_method("paralyze"):
		body.paralyze.rpc_id(body.player_id);
