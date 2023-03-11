extends Node2D

var player_spawn = preload("res://player/player_template.tscn")
var dev_enemy = preload("res://enemies/fallback_enemy.tscn")
var enemy_spawns = {
	"red_slug": preload("res://enemies/red_slug.tscn"),
	"blue_slug": preload("res://enemies/blue_slug.tscn")
}
#var pickup_spawn = preload("res://pickups/crate.tscn")
var last_world_state = 0 # is a timestamp, not an actual state

# [previous past, most recent past, nearest future, further future]
var world_state_buffer = []
const interpolation_offset = 100

func spawn_new_player(player_id, spawn_pos):
	if get_tree().get_network_unique_id() == player_id:
		pass
	else:
		if not get_node("other_players").has_node(str(player_id)):
			var new_player = player_spawn.instance()
			new_player.position = spawn_pos
			new_player.name = str(player_id)
			get_node("other_players").add_child(new_player)
			
func spawn_new_enemy(enemy_id, enemy_dict):
	var new_enemy = enemy_spawns[enemy_dict["enemy_type"]].instance()
	new_enemy.type = enemy_dict["enemy_type"]
	new_enemy.position = enemy_dict["enemy_location"]
	new_enemy.max_hp = enemy_dict["enemy_max_hp"]
	new_enemy.hp = enemy_dict["enemy_hp"]
	new_enemy.xp_drop = enemy_dict["enemy_xp_drop"]
	new_enemy.damage = enemy_dict["enemy_damage"]
	new_enemy.state = enemy_dict["enemy_state"]
	new_enemy.name = str(enemy_id)
	get_node("enemies").add_child(new_enemy, true)
	
#func spawn_new_pickup(pickup_id, pickup_dict):
#	var new_pickup = pickup_spawn.instance()
#	new_pickup.position = pickup_dict["pickup_position"]
#	new_pickup.type = pickup_dict["pickup_type"]
#	new_pickup.name = str(pickup_id)
#	get_node("pickups").add_child(new_pickup, true)

func despawn_player(player_id):
	yield(get_tree().create_timer(0.25), "timeout")
	get_node("other_players/" + str(player_id)).queue_free()
	
func despawn_pickup(pickup_id):
	yield(get_tree().create_timer(0.25), "timeout")
	get_node("pickups/" + str(pickup_id)).queue_free()
	
func update_world_state(world_state):
	if world_state["t"] > last_world_state:
		last_world_state = world_state["t"]
		world_state_buffer.append(world_state)
		
func _physics_process(_delta):
	var render_time = server.client_clock - interpolation_offset
	if world_state_buffer.size() > 1:
		while world_state_buffer.size() > 2 and render_time > world_state_buffer[2].t:
			world_state_buffer.remove(0)
		if world_state_buffer.size() > 2: # we have a future state (interpolation can be used)
			var interpolation_factor = float(render_time - world_state_buffer[1]["t"]) / float(world_state_buffer[2]["t"] - world_state_buffer[1]["t"])
			
			for player in world_state_buffer[2].keys():
				if str(player) == "t":
					continue
				if str(player) == "enemies":
					continue
#				if str(player) == "pickups":
#					continue
				if player == get_tree().get_network_unique_id():
					continue
				if not world_state_buffer[1].has(player):
					continue
				if get_node("other_players").has_node(str(player)):
					var new_position = lerp(world_state_buffer[1][player]["p"], world_state_buffer[2][player]["p"], interpolation_factor)
					get_node("other_players/" + str(player)).update_player(new_position, world_state_buffer[2][player])
				else:
					print("spawning player")
					spawn_new_player(player, world_state_buffer[2][player]["p"])
			
			for enemy in world_state_buffer[2]["enemies"].keys():
				if not world_state_buffer[1]["enemies"].has(enemy):
					continue
				if get_node("enemies").has_node(str(enemy)):
					var new_position = lerp(world_state_buffer[1]["enemies"][enemy]["enemy_location"], world_state_buffer[2]["enemies"][enemy]["enemy_location"], interpolation_factor)
					get_node("enemies/" + str(enemy)).update_enemy(new_position, world_state_buffer[1]["enemies"][enemy])
				else:
					spawn_new_enemy(enemy, world_state_buffer[2]["enemies"][enemy])
				
#			for pickup in world_state_buffer[2]["pickups"].keys():
#				if not world_state_buffer[1]["pickups"].has(pickup):
#					continue
#				if get_node("pickups").has_node(str(pickup)):
#					var new_position = lerp(world_state_buffer[1]["pickups"][pickup]["pickup_position"], world_state_buffer[2]["pickups"][pickup]["pickup_position"], interpolation_factor)
#					get_node("pickups/" + str(pickup)).update_pickup(new_position, world_state_buffer[1]["pickups"][pickup])
#				else:
#					spawn_new_pickup(pickup, world_state_buffer[2]["pickups"][pickup])
			
		elif render_time > world_state_buffer[1].t: # there is no future state and extrapolation must be used
			var extrapolation_factor = float(render_time - world_state_buffer[0]["t"]) / float(world_state_buffer[1]["t"]) - 1.00 # minus one to exclude time between world states
			for player in world_state_buffer[1].keys():
				if str(player) == "t":
					continue
				if str(player) == "enemies":
					continue
#				if str(player) == "pickups":
#					continue
				if player == get_tree().get_network_unique_id():
					continue
				if not world_state_buffer[0].has(player):
					continue
				if get_node("other_players").has_node(str(player)):
					var position_delta = (world_state_buffer[1][player]["p"] - world_state_buffer[0][player]["p"])
					var new_position = world_state_buffer[1][player]["p"] + (position_delta * extrapolation_factor)
					get_node("other_players/" + str(player)).update_player(new_position, world_state_buffer[1][player])
