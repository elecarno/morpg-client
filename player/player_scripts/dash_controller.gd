extends Node2D

onready var timer = get_node("dash_timer")
onready var ghost_timer = get_node("ghost_timer")
var dash_ghost = preload("res://player/player_scenes/dash_ghost.tscn")

func start_dash(duration, usetrail):
	timer.wait_time = duration
	timer.start()
	if usetrail:
		ghost_timer.start()
		instance_ghost()
		
func start_dash_effect(duration):
	timer.wait_time = duration
	timer.start()
	ghost_timer.start()
	instance_ghost()
	
func instance_ghost():
	var ref_sprite = get_parent().get_node("sprite")
	var ghost: Sprite = dash_ghost.instance()
	ghost.global_position = global_position
	ghost.texture = ref_sprite.texture
	ghost.vframes = ref_sprite.vframes
	ghost.hframes = ref_sprite.hframes
	ghost.frame = ref_sprite.frame
	ghost.scale = ref_sprite.scale
	get_parent().get_parent().add_child(ghost)
	
func is_dashing():
	return !timer.is_stopped()

func _on_ghost_timer_timeout():
	instance_ghost()

func _on_dash_timer_timeout():
	ghost_timer.stop()
