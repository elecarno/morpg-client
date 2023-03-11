extends PlayerState

export (NodePath) var _anim
onready var anim: AnimationPlayer = get_node(_anim)

func enter(_msg := {}) -> void:
	player.collision_mask = 3 
	player.has_attacked = false
	player.jumps_made = 0
	anim.play("idle")
	
func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.transition_to("air")
		return
	
	player.velocity.x = lerp(player.velocity.x, 0, player.friction * delta)
	player.velocity = player.move_and_slide(player.velocity, player.UP_DIR, true)
	
	if player.is_jumping and player.jump_buffer_counter > 0:
		state_machine.transition_to("air", {do_jump = true})
		player.jump_buffer_counter = player.jump_buffer_time
	elif Input.is_action_just_pressed("attack") and player.can_attack():
		state_machine.transition_to("attack", {prev = self.name})
	elif Input.is_action_just_pressed("block") and player.can_block() and player.energy >= player.block_energy:
		state_machine.transition_to("block", {prev = self.name})
	elif not is_zero_approx(player.get_input_direction()):
		if Input.is_action_pressed("sprint"):
			state_machine.transition_to("sprint")
		else:
			state_machine.transition_to("run")
	elif is_zero_approx(player.get_input_direction()):
		state_machine.transition_to("idle")
