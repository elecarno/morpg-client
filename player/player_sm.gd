class_name Player
extends KinematicBody2D

var player_state

const UP_DIR := Vector2.UP
var velocity := Vector2.ZERO

onready var wall_detect_r = get_node("wall_detect_r")
onready var wall_detect_l = get_node("wall_detect_l")
onready var dash = get_node("dash")
onready var dash_cooldown = get_node("dash_cooldown")
onready var land_cooldown = get_node("land_cooldown")
onready var attack_timer = get_node("attack_timer")
onready var anim = get_node("anim")
onready var effects = get_node("effects")
onready var ground = get_node("ground")
onready var dialog_box = get_parent().get_node("gui").get_node("dialog_box")
onready var playerstats = get_parent().get_node("gui/player_stats")
onready var sfx = get_node("sfx")
#onready var name_label = get_node("sprite/player_name")

var energy = 0
export var block_energy = 30

var username = ""

export var friction = 20

var base_jump_height : float = 50
var base_run_speed : float = 100
var base_block_energy_drain = 3
var equipped_weapon_damage = 10

export var run_speed := 500 # test value 150
export var sprint_speed := 150.0 # test value 220
export var run_accel := 50.0

export var dash_speed := 550.0
export var dash_accel := 100
export var dash_length = 0.15

export var attack_speed := 250

export var jump_height : float = 50 # 80 works well
export var jump_time_to_peak : float = 0.4 # 0.4 works well
export var jump_time_to_descend : float = 0.35 # 0.35 works well

export var max_jumps := 1
export var has_dash = false
export var block_energy_drain = 3

var jump_strength : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
var double_jump_strength : float = ((2.0 * jump_height) / jump_time_to_peak)/1.5 * -1.0
var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descend * jump_time_to_descend)) * -1.0

#export var wall_slide_speed = 150

var jumps_made := 0
var has_attacked := false
var is_jumping := false
var is_grounded = false
var gravity_res

export var jump_buffer_time : int = 7
var jump_buffer_counter : int = 0

export var coyote_time : int = 7
var coyote_counter : int = 0

var against_wall = false

onready var sprite = get_node("sprite")
onready var reflection = get_node("reflection")
onready var _anim: AnimationPlayer = get_node("anim")
onready var _start_scale: Vector2 = sprite.scale

var prev_anim = ""

func is_on_ground():
	if ground.is_colliding():
		is_grounded = true

func _ready():
	set_physics_process(false)

func get_gravity() -> float:
	var grav = jump_gravity if velocity.y < 0.0 else fall_gravity
#	if gravity_res != null:
#		grav *= gravity_res
	return grav

func get_input_direction() -> float:
	var dir = (Input.get_action_strength("right") - Input.get_action_strength("left"))
	if not is_zero_approx(dir):
		sprite.scale.x = sign(dir) * _start_scale.x
		reflection.scale.x = sign(dir) * _start_scale.x
	return dir
	
func take_damage(amount: int) -> void:
	if get_node("state_machine").state == get_node("state_machine/block"):
		playerstats.player_use_energy(-100)
		playerstats.playerhit(-50)
		get_node("sprite/hit_particles").emitting = true
		randomize()
		sfx.get_node("block").pitch_scale = rand_range(0.8, 1.2)
		sfx.get_node("block").play()
		get_node("state_machine/block").end_block()
		get_node("block_cooldown").start()
	else:
		var hp = get_parent().get_node("gui/player_stats").playerdata.stats.hp
		var damage_to_take = floor(amount / ((playerstats.playerdata.stats.def + 100) / 100))
		playerstats.playerhit(damage_to_take)
		randomize()
		sfx.get_node("hit").pitch_scale = rand_range(0.8, 1.2)
		effects.play("hit")
		sfx.get_node("hit").play()
		print("client hit for " + str(amount) + ", hp is now: " + str(hp))
		
func gain_xp(amount: int) -> void:
		playerstats.gain_xp(amount)
		
func gain_credits(amount: int) -> void:
	playerstats.gain_credits(amount)
	
func use_energy(amount: int) -> void:
	playerstats.player_use_energy(amount)
	
func attack(prv_anim):
	anim.play("slash")
	attack_timer.wait_time = anim.current_animation_length
	attack_timer.start()
	prev_anim = prv_anim

func can_attack() -> bool:
	if playerstats.playerdata != null:
		if playerstats.playerdata.stats.energy > 5 and get_node("sprite/hitbox").damage > 0:
			return true
		else:
			return false
	else:
		return false
		
func can_block() -> bool:
	return get_node("block_cooldown").is_stopped()

func is_attacking():
	return !attack_timer.is_stopped()

func _on_attack_timer_timeout():
	anim.play(prev_anim)

func reset_cols():
	get_node("col").set_deferred("disabled", false)
	get_node("hurtbox/col").set_deferred("disabled", false)
	get_node("sprite/hitbox/col").set_deferred("disabled", true)
	get_node("sprite/block_area/block_col").set_deferred("disabled", true)

func calc_stats():
	run_speed = floor(base_run_speed + (pow(playerstats.playerdata.stats.agi, 0.5) * 16))
	sprint_speed = run_speed * 1.5
	
	jump_height = floor(base_jump_height * pow(playerstats.playerdata.stats.agi, 0.3))
	jump_strength = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
	double_jump_strength = ((2.0 * jump_height) / jump_time_to_peak)/1.5 * -1.0
	jump_gravity = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
	fall_gravity  = ((-2.0 * jump_height) / (jump_time_to_descend * jump_time_to_descend)) * -1.0
	
	block_energy_drain = base_block_energy_drain + (-1 * log(playerstats.playerdata.stats.def))
	
	var weapon_slot = playerstats.get_node("inv/equip_slots/weapon_slot")
	var weapon_item
	if weapon_slot.get_child_count() > 0:
		weapon_item = weapon_slot.get_child(0).item_name
	if weapon_item != null:
		var weapon_damage = playerstats.itemdata[weapon_item]["damage"]
		equipped_weapon_damage = weapon_damage
		attack_speed = playerstats.itemdata[weapon_item]["speed"]
		get_node("sprite/hitbox").damage = (equipped_weapon_damage + (1.5 * playerstats.playerdata.stats.atk))
	else:
		get_node("sprite/hitbox").damage = 0

func _physics_process(_delta):
	if playerstats.playerdata != null:
		energy = playerstats.playerdata.stats.energy
		calc_stats()
	
	if Input.is_action_just_pressed("crouch") and is_on_floor():
		global_position.y += 5
		get_node("state_machine").transition_to("idle")
	
	gravity_res = get_floor_normal() if is_on_floor() else Vector2.UP
	
	if !dialog_box.is_visible_in_tree():
		is_on_ground()
		movement_loop()
		define_player_state()
	
func movement_loop():
	if position.y > 1000:
		position.y = -500
		velocity.y = 0
	
	is_jumping = Input.is_action_just_pressed("jump") and coyote_counter > 0
	
	if is_grounded:
		coyote_counter = coyote_time
	else:
		if coyote_counter > 0:
			coyote_counter -= 1
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer_counter = jump_buffer_time
	if jump_buffer_counter > 0:
		jump_buffer_counter -= 1
		
	if wall_detect_r.is_colliding():
		if wall_detect_r.get_collider().name == "ground":
			against_wall = true
	if wall_detect_l.is_colliding():
		if wall_detect_l.get_collider().name == "ground":
			against_wall = true

func define_player_state():
	if playerstats.playerdata == null:
		return
	# if we have differnt maps, a map_node must be included
	player_state = {
		"t": OS.get_system_time_msecs(),
		"p": get_global_position(),
		"username": username,
		"lvl": playerstats.playerdata.lvl,
		"sprite_s": sprite.scale,
		"anim": anim.current_animation,
		"equips": playerstats.playerdata.equips
	}
	server.send_player_state(player_state)
