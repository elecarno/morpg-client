extends PlayerState

export (NodePath) var _anim
onready var anim: AnimationPlayer = get_node(_anim)
var previous_state = ""

func enter(_msg := {}) -> void:
	player.collision_mask = 3 
	previous_state = _msg["prev"]
	anim.play("block")
		
func physics_update(delta: float) -> void:
	player.velocity.x = lerp(player.velocity.x, 0, (player.friction/10) * delta)
	player.velocity.y += (player.get_gravity()/3) * delta
	player.velocity = player.move_and_slide(player.velocity, player.UP_DIR, true)
	player.playerstats.block_energy_regen = true
	player.use_energy(player.block_energy_drain)
	if Input.is_action_just_released("block") or player.energy <= 0:
		end_block()
		
func end_block():
#	player.get_node("block_cooldown").start()
	player.reset_cols()
	state_machine.transition_to(previous_state, {from_attack = true})
	player.playerstats.block_energy_regen = false
	player.playerstats.begin_energy_regen()
