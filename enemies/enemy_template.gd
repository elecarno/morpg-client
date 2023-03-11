extends KinematicBody2D

var max_hp = 100
var hp = 100
var type = "null"
var state = "idle"
var damage = 5
var xp_drop = 5
var credit_drop = [1, 5]
var direction = 0
var is_attacking := false

var death_sequence_active = false

onready var anim = get_node("anim")
onready var sprite = get_node("sprite")
onready var attack_timer = get_node("attack_timer")
onready var sfx = get_node("sfx")

func _ready():
	#print("spawned " + self.name)
	if state == "idle":
		pass
	elif state == "dead":
		get_node("sprite").visible = false

func update_enemy(new_position, enemy_state):
	set_position(new_position)
	direction = enemy_state["enemy_dir"]
	state = enemy_state["enemy_state"]
	damage = enemy_state["enemy_damage"]
	xp_drop = enemy_state["enemy_xp_drop"]
	credit_drop = enemy_state["enemy_credit_drop"]
	get_node("sprite/hitbox").damage = damage
	
	sprite.scale.x = direction
	
	if state == "moving":
		is_attacking = false
		anim.play("run")
	if state == "attacking":
		if !is_attacking:
			is_attacking = true
			anim.play("attack")
	
	if hp != enemy_state["enemy_hp"]:
		hp = enemy_state["enemy_hp"]
		
	update_hp_bar()
	
	if enemy_state["enemy_state"] == "dead":
		if !death_sequence_active:
			on_death()

func update_hp_bar():
	if hp == max_hp:
		get_node("bar/hp_bar").visible = false
		get_node("bar/hp_bar_bg").visible = false
	else:
		get_node("bar/hp_bar").visible = true
		get_node("bar/hp_bar_bg").visible = true
		get_node("bar/hp_bar").max_value = max_hp
		get_node("bar/hp_bar").value = hp

func take_damage(damage_to_take): # called by player's hitbox
	get_node("effects").play("hit")
	randomize()
	sfx.get_node("hit").pitch_scale = rand_range(0.8, 1.2)
	sfx.get_node("hit").play()
	on_hit(damage_to_take)

func on_hit(damage_to_take):
	if hp > 0:
		server.npc_hit(int(get_name()), damage_to_take)
	#print("enemy hit for " + str(damage) + ", hp now: " + str(hp))

func _on_area_entered(_body):
	pass # Replace with function body.
	
func on_death():
	#print(self.name + " killed")
	death_sequence_active = true
	randomize()
	var credit_gain = rand_range(credit_drop[0], credit_drop[1])
	get_parent().get_parent().get_node("player").gain_credits(credit_gain)
	get_parent().get_parent().get_node("player").gain_xp(xp_drop)
	anim.play("death")
	get_node("col").set_deferred("disabled", true)
	get_node("bar").visible = false
	yield(get_tree().create_timer(0.2), "timeout")
	get_node("hurtbox/col").set_deferred("disabled", true)
	get_node("death_timer").start()

func _on_death_timer_timeout():
	get_node("sprite").visible = false
	print("deleted enemy " + self.name)
	queue_free()

