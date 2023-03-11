extends PlayerState

export (NodePath) var _anim
onready var anim: AnimationPlayer = get_node(_anim)

func enter(_msg := {}) -> void:
	player.collision_mask = 3 
	player.has_attacked = false
	player.jumps_made = 0
	anim.play("run")
	player.sfx.get_node("walk").play()
	
func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.transition_to("air")
		return
		
	if not is_zero_approx(player.get_input_direction()):
		player.velocity.x = lerp(player.velocity.x, player.get_input_direction() * player.run_speed, player.run_accel * delta)

	player.velocity.y += player.get_gravity() * delta
	player.velocity = player.move_and_slide(player.velocity, player.UP_DIR, true)
		
	if player.is_jumping and player.jump_buffer_counter > 0:
		player.sfx.get_node("walk").stop()
		state_machine.transition_to("air", {do_jump = true})
		player.jump_buffer_counter = player.jump_buffer_time
	elif Input.is_action_just_pressed("dash") and player.dash_cooldown.is_stopped() and player.has_dash:
		player.sfx.get_node("walk").stop()
		state_machine.transition_to("dash")
	elif Input.is_action_just_pressed("attack") and player.can_attack() and player.energy >= player.block_energy:
		player.sfx.get_node("walk").stop()
		state_machine.transition_to("attack", {prev = self.name})
	elif Input.is_action_just_pressed("block") and player.can_block():
		player.sfx.get_node("walk").stop()
		state_machine.transition_to("block", {prev = self.name})
	elif Input.is_action_pressed("sprint"):
		player.sfx.get_node("walk").stop()
		state_machine.transition_to("sprint")
	elif is_zero_approx(player.get_input_direction()):
		player.sfx.get_node("walk").stop()
		state_machine.transition_to("idle")
