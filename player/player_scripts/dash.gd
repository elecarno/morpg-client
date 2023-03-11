extends PlayerState

export (NodePath) var _anim
onready var anim: AnimationPlayer = get_node(_anim)

func enter(_msg := {}) -> void:
	player.has_attacked = false
	player.dash.start_dash(player.dash_length, true)
	player.jumps_made = 1
	player.collision_mask = 1 
	anim.play("dash")
	player.playerstats.player_use_energy(30)
		
func physics_update(delta: float) -> void:
	player.velocity.y = 0
	player.velocity.x = lerp(player.velocity.x, player.get_input_direction() * player.dash_speed, player.dash_accel * delta)
	player.velocity = player.move_and_slide(player.velocity, player.UP_DIR, true)
	player.dash_cooldown.start()
	if !player.dash.is_dashing():
		player.collision_mask = 3
		player.reset_cols()
		player.playerstats.block_energy_regen = false
		player.playerstats.begin_energy_regen()
		state_machine.transition_to("air")
