extends PlayerState

export (NodePath) var _anim
onready var anim: AnimationPlayer = get_node(_anim)

func enter(_msg := {}) -> void:
	player.collision_mask = 3 
	if !_msg.has("from_attack"):
		player.has_attacked = false
	if _msg.has("do_jump"):
		player.coyote_counter = 0
		player.jumps_made += 1
		player.velocity.y = player.jump_strength
		if player.jumps_made == 1:
			anim.play("jump")
		if player.jumps_made > 1:
			anim.play("double_jump")
	else:
		anim.play("fall")
	
func physics_update(delta: float) -> void:
	var speed_to_use
	if Input.is_action_pressed("sprint"):
		speed_to_use = player.sprint_speed
	else:
		speed_to_use = player.run_speed

	if not is_zero_approx(player.get_input_direction()):
		player.velocity.x = lerp(player.velocity.x, player.get_input_direction() * speed_to_use, player.run_accel * delta)
	else:
		player.velocity.x = lerp(player.velocity.x, 0, player.friction * delta)
		
	player.velocity.y += player.get_gravity() * delta
	player.velocity = player.move_and_slide(player.velocity, player.UP_DIR, true, 4)

	if player.jumps_made < player.max_jumps:
		if Input.is_action_just_pressed("jump") and player.jump_buffer_counter > 0:
			state_machine.transition_to("air", {do_jump = true})
		elif Input.is_action_just_released("jump"):
			player.velocity.y = player.jump_strength/4

	if Input.is_action_just_pressed("dash") and player.dash_cooldown.is_stopped() and player.has_dash:
		state_machine.transition_to("dash")
	elif Input.is_action_just_pressed("attack") and player.jumps_made and !player.has_attacked and player.can_attack():
		player.has_attacked = true
		state_machine.transition_to("attack", {prev = self.name})
	elif Input.is_action_pressed("block") and player.can_block() and player.energy >= player.block_energy:
		state_machine.transition_to("block", {prev = self.name})

	if player.is_on_floor():
		_on_land_cooldown_timeout()
#		if anim.current_animation != "land":
#			anim.play("land")
#			speed_to_use = player.run_speed
#			player.land_cooldown.wait_time = anim.current_animation_length
#			player.land_cooldown.start()

func _on_land_cooldown_timeout():
	if is_zero_approx(player.get_input_direction()):
		state_machine.transition_to("idle")
	else:
		state_machine.transition_to("run")
