extends KinematicBody2D

var rng = RandomNumberGenerator.new()

onready var anim = get_node("anim")
onready var sprite = get_node("sprite")
onready var dash = get_node("dash")
onready var name_label = get_node("player_name")
export var dash_length = 0.15

var attack_dict = {}
var state = "idle"

func _ready():
	get_node("sprite/hitbox").collision_layer = 0
	get_node("sprite/hitbox").collision_mask = 0
	dash_length = get_parent().get_parent().get_node("player").dash_length
	
func _physics_process(_delta):
	if not attack_dict == {}:
		attack()

func update_player(new_position, player_state):
	name_label.text = player_state["username"]
	anim.play(player_state["anim"])
	if anim.current_animation == "dash":
		dash.start_dash_effect(dash_length)
	sprite.scale = player_state["sprite_s"]
	set_position(new_position)

func attack():
	pass
