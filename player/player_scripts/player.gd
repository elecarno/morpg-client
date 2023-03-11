extends KinematicBody2D

const UP_DIR := Vector2.UP

onready var wall_detect_r = get_node("wall_detect_r")
onready var wall_detect_l = get_node("wall_detect_l")

export var max_speed := 0
export var accel := 50.0

export var max_run_speed := 100.0
export var max_sprint_speed := 400.0
export var run_accel := 50.0

export var dash_speed := 4800.0
export var dash_accel := 100
export var dash_length = 0.15

export var max_jumps := 2
var _jumps_made := 0
var _velocity := Vector2.ZERO

export var jump_height : float = 150
export var jump_time_to_peak : float = 0.5
export var jump_time_to_descend : float = 0.45
export var jump_strength : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
export var double_jump_strength : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
export var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
export var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descend * jump_time_to_descend)) * -1.0
export var wall_slide_speed = 150

onready var dash = get_node("dash")

export var jump_buffer_time : int = 15 # 1/4 of a second
var jump_buffer_counter : int = 0

export var coyote_time : int = 15
var coyote_counter : int = 0

onready var sprite = get_node("sprite")
onready var _anim: AnimationPlayer = get_node("anim")
onready var _start_scale: Vector2 = sprite.scale

func get_gravity() -> float:
	return jump_gravity if _velocity.y < 0.0 else fall_gravity

func _physics_process(delta: float) -> void:
	var _horizontal_dir = (Input.get_action_strength("right") - Input.get_action_strength("left"))
	_velocity.y += get_gravity() * delta
	
	var is_falling := _velocity.y > 0.0 and !is_on_floor()
	
	if is_on_floor():
		coyote_counter = coyote_time
	else:
		if wall_detect_r.is_colliding():
			if wall_detect_r.get_collider().name == "ground":
				coyote_counter = coyote_time
				_jumps_made = 0
		if wall_detect_l.is_colliding():
			if wall_detect_l.get_collider().name == "ground":
				coyote_counter = coyote_time
				_jumps_made = 0
		
		if coyote_counter > 0:
			coyote_counter -= 1
			
	if !is_zero_approx(_horizontal_dir):
		_velocity.x += _horizontal_dir * accel
	else:
		_velocity.x = lerp(_velocity.x, 0, 0.2)
		
	var is_sprinting = Input.is_action_pressed("sprint")
	var is_dashing = Input.is_action_just_pressed("dash")
	var is_jumping := Input.is_action_just_pressed("jump") and coyote_counter > 0
	var is_double_jumping := Input.is_action_just_pressed("jump") and is_falling
	var is_jump_cancelled := Input.is_action_just_released("jump") and _velocity.y < 0.0
	var is_idling := is_on_floor() and is_zero_approx(_velocity.x)
	var is_running := is_on_floor() and !is_zero_approx(_velocity.x)
	#var is_stopping := is_on_floor() and is_zero_approx(_horizontal_dir)

	if is_dashing:
		dash.start_dash(dash_length, true)
		_jumps_made = 1
		
	if dash.is_dashing():
		max_speed = dash_speed
		accel = dash_accel
		_velocity.y = 0
	elif is_sprinting and !is_dashing:
		if is_jumping and max_speed != max_sprint_speed:
			max_speed = max_run_speed
		elif is_falling and max_speed != max_sprint_speed:
			max_speed = max_run_speed
		elif is_jump_cancelled and max_speed != max_sprint_speed:
			max_speed = max_run_speed
		else:
			max_speed = max_sprint_speed
	else:
		max_speed = max_run_speed
		accel = run_accel
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer_counter = jump_buffer_time
	
	if jump_buffer_counter > 0:
		jump_buffer_counter -= 1
	
	if jump_buffer_counter > 0 and is_jumping:
		_jumps_made += 1
		_velocity.y = jump_strength
		coyote_counter = 0
	elif jump_buffer_counter > 0 and is_double_jumping:
		_jumps_made += 1
		coyote_counter = 0
		if _jumps_made <= max_jumps:
			_velocity.y = double_jump_strength
	elif is_jump_cancelled:
		_velocity.y = jump_strength/4
	elif is_idling or is_running:
		_jumps_made = 0
		
	if wall_detect_r.is_colliding() and !is_jumping:
		if wall_detect_r.get_collider().name == "ground":
			if _velocity.y > wall_slide_speed:
				_velocity.y = wall_slide_speed
	if wall_detect_l.is_colliding() and !is_jumping:
		if wall_detect_l.get_collider().name == "ground":
			if _velocity.y > wall_slide_speed:
				_velocity.y = wall_slide_speed
	
	_velocity.x = clamp(_velocity.x, -max_speed, max_speed)
	_velocity = move_and_slide(_velocity, UP_DIR)
	
	if not is_zero_approx(_velocity.x):
		sprite.scale.x = sign(_velocity.x) * _start_scale.x
		
	if is_jumping:
		if _anim.get_current_animation() != "jump":
			_anim.play("jump")
	elif is_double_jumping:
		if _anim.get_current_animation() != "double_jump":
			_anim.play("double_jump")
	elif dash.is_dashing():
		if _anim.get_current_animation() != "dash":
			_anim.play("dash")
	elif is_running:
		if is_sprinting:
			if _anim.get_current_animation() != "sprint":
				_anim.play("sprint")
		else:
			if _anim.get_current_animation() != "run":
				_anim.play("run")
	elif is_falling:
		if _anim.get_current_animation() != "fall":
			_anim.play("fall")
	elif is_idling or is_zero_approx(_velocity.x):
		if _anim.get_current_animation() != "idle":
			_anim.play("idle")
 
