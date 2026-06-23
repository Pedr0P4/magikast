extends Control

@onready var menu_buttons = $MenuButtons;
@onready var host_panel = $HostPanel;
@onready var join_panel = $JoinPanel;
@onready var back_button = $BackButton;

func _on_host_button_pressed() -> void:
	menu_buttons.visible = false;
	host_panel.visible = true;
	join_panel.visible = false;
	back_button.visible = true;
	
func _on_join_button_pressed() -> void:
	menu_buttons.visible = false;
	host_panel.visible = false;
	join_panel.visible = true;
	back_button.visible = true;

func _on_back_button_pressed() -> void:
	menu_buttons.visible = true;
	host_panel.visible = false;
	join_panel.visible = false;
	back_button.visible = false;
