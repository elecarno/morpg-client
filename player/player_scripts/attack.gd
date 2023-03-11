extends PlayerState

export (NodePath) var _anim
onready var anim: AnimationPlayer = get_node(_anim)
var previous_state = ""
var dir = 0

func enter(_msg := {}) -> void:
	player.collision_mask = 3 
	previous_state = _msg["prev"]
	anim.play("slash")
	dir = player.get_input_direction()
	player.dash.start_dash(player.dash_length/4, false)
	player.attack_timer.wait_time = anim.current_animation_length
	player.attack_timer.start()
	player.playerstats.playerattack(10)

func physics_update(delta: float) -> void:
#	player.velocity.y += player.get_gravity()/2 * delta
#	player.velocity.x = lerp(player.velocity.x, 0, 0.1)
	player.velocity.y = 0
	if player.dash.is_dashing():
		player.velocity.x = lerp(player.velocity.x, player.get_input_direction() * player.dash_speed, player.dash_accel * delta)
	else:
		player.velocity.x = lerp(player.velocity.x, 0, 0.05)
	player.velocity = player.move_and_slide(player.velocity, player.UP_DIR, true)
	if !player.is_attacking():
		player.reset_cols()
		state_machine.transition_to(previous_state, {from_attack = true})
