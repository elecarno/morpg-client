extends StaticBody2D

export var dialog_json = ""
var active = false
onready var dialog_box = get_parent().get_parent().get_node("gui/dialog_box")
onready var s_button = get_node("s_button")

func _ready():
	set_physics_process(false)

func _on_area_body_entered(body):
	if body.name == "player":
		s_button.visible = true
		get_node("anim").play("activate")
		active = true
		set_physics_process(active)

func _physics_process(_delta):
	if !dialog_box.is_visible_in_tree() and Input.is_action_just_pressed("crouch"):
		dialog_box.activate(dialog_json)
		s_button.visible = false
	elif !dialog_box.is_visible_in_tree() and Input.is_action_just_released("crouch"):
		s_button.visible = true

func _on_area_body_exited(body):
	if body.name == "player":
		s_button.visible = true
		get_node("anim").play("deactivate")
		active = false
		set_physics_process(active)
