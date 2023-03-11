extends Node

# development ip & port
const DEFAULT_IP = "127.0.0.1"
const DEFAULT_PORT = 1909

var network = NetworkedMultiplayerENet.new()
var selected_IP
var selected_port

var token
var playeruser

var local_player_id = 0
sync var players = {}
sync var player_data = {}

var client_clock = 0
var decimal_collector : float = 0
var latency_array = []
var latency = 0
var delta_latency = 0

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
		
func _physics_process(delta): # 0.01667 = 1 / 60
	client_clock += int(delta*1000) + delta_latency
	delta_latency = 0
	decimal_collector += (delta * 1000) - int(delta * 1000)
	if decimal_collector >= 1.00:
		client_clock += 1
		decimal_collector -= 1.00
		
	var unix_time = round(client_clock / 1000)
	var time : Dictionary = OS.get_datetime_from_unix_time(unix_time);
	var display_string : String = "%02d:%02d:%02d" % [time.hour, time.minute, time.second];
	# var display_string : String = "%d/%02d/%02d %02d:%02d:%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second];
	get_node("../scene_handler/map/gui/clock").text = display_string

func connect_to_server():
	get_tree().connect("connected_to_server", self, "_connected_ok")
	network.create_client(DEFAULT_IP, DEFAULT_PORT)
	get_tree().set_network_peer(network)
	
func _player_connected(id):
	print("player " + str(id) + " connected")
	
func _player_disconnected(id):
	print("player " + str(id) + " disconnected")
	
func _connected_ok():
	print("successfully connected to server")
	rpc_id(1, "fetch_server_time", OS.get_system_time_msecs())
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.connect("timeout", self, "determine_latency")
	self.add_child(timer)

remote func return_server_time(server_time, client_time):
	if get_tree().get_rpc_sender_id() == 1:
		latency = (OS.get_system_time_msecs() - client_time) / 2
		client_clock = server_time + latency

func determine_latency():
	rpc_id(1, "determine_latency", OS.get_system_time_msecs())
	
remote func return_latency(client_time):
	if get_tree().get_rpc_sender_id() == 1:
		latency_array.append((OS.get_system_time_msecs() - client_time) / 2)
		if latency_array.size() == 9:
			var total_latency = 0
			latency_array.sort()
			var mid_point = latency_array[4]
			for i in range(latency_array.size()-1, -1, -1):
				if latency_array[i] > (2 * mid_point) and latency_array[i] > 20:
					latency_array.remove(i)
				else:
					total_latency += latency_array[i]
			delta_latency = (total_latency / latency_array.size()) - latency
			latency = total_latency / latency_array.size()
			latency_array.clear()

func _connected_fail():
	print("failed to connect to server")
	
func _server_disconnected():
	print("server disconnected")
	
remote func fetch_token():
	rpc_id(1, "return_token", token)
	
remote func return_token_verification_results(result):
	if get_tree().get_rpc_sender_id() == 1:
		var alert_label = get_node("../scene_handler/map/gui/login_system/alert_label")
		if result == true:
			print("successful token verifcation")
			alert_label.text = "successful token verifcation"
			get_node("../scene_handler/map/gui/login_system").queue_free()
			get_node("../scene_handler/map/player").set_physics_process(true)
			fetch_playerdata()
		else:
			print("login failed, please try again")
			alert_label.text = "login failed, please try again"
			get_node("../scene_handler/map/gui/login_system").login_button.disabled = false
			get_node("../scene_handler/map/gui/login_system").create_acc_button.disabled = false
			playeruser = ""
		
func send_player_state(player_state):
	rpc_unreliable_id(1, "recieve_player_state", player_state)
	
#func send_pickup_state(pickup_state, pickup_id):
#	rpc_unreliable_id(1, "recieve_pickup_state", pickup_state, pickup_id)

remote func recieve_world_state(world_state):
	if get_tree().get_rpc_sender_id() == 1:
		get_node("../scene_handler/map").update_world_state(world_state)
		
remote func spawn_new_player(player_id, spawn_pos):
	if get_tree().get_rpc_sender_id() == 1:
		get_node("../scene_handler/map").spawn_new_player(player_id, spawn_pos)
	
remote func despawn_player(player_id):
	if get_tree().get_rpc_sender_id() == 1:
		get_node("../scene_handler/map").despawn_player(player_id)
	
func send_attack(position, rotation_deg, rotation):
	rpc_id(1, "attack", position, rotation_deg, rotation, client_clock)
	
remote func recieve_attack(position, rotation_deg, rotation, spawn_time, player_id):
	if get_tree().get_rpc_sender_id() == 1:
		if player_id == get_tree().get_network_unique_id():
			pass
		else:
			get_node("../scene_handler/map/other_players/" + str(player_id)).attack_dict[spawn_time] = {"position": position, "rotdeg": rotation_deg, "rot": rotation}
	
# `rpc_id()` calls `remote func fetch_shipdata()` on id 1 (the server)
#func fetch_shipdata(ship_name, requester):
#	rpc_id(1, "fetch_shipdata", ship_name, requester)
#	# print("fetching data for: " + ship_name)

# this function is a called from the server, hence the `remote` tag
# `s_` identifies variables from server, `instance_from_id` references
# the id of the initial caller from `fetch_shipdata`
#remote func return_shipdata(s_shipdata, requester):
#	if get_tree().get_rpc_sender_id() == 1:
#		# print("recieved data: " + str(s_shipdata))
#		instance_from_id(requester).setdata(s_shipdata)
	
func npc_hit(enemy_id, damage):
	rpc_id(1, "send_npc_hit", enemy_id, damage)
	
func fetch_playerdata():
	rpc_id(1, "fetch_playerdata", playeruser)

remote func return_playerdata(data):
	if get_tree().get_rpc_sender_id() == 1:
		# print("recieved data " + str(data))
		get_node("/root/scene_handler/map/gui/player_stats").load_playerdata(data)
	
func write_playerdata_update(newdata):
	rpc_id(1,"write_playerdata_update", playeruser, newdata)

func fetch_itemdata():
	print("fetching data")
	rpc_id(1, "fetch_itemdata")
	
remote func return_itemdata(data):
	if get_tree().get_rpc_sender_id() == 1:
		print("recieved itemdata")
		#print("recieved data " + str(data))
		get_node("/root/scene_handler/map/gui/player_stats").itemdata = data
		get_node("/root/scene_handler/map/gui/player_stats/inv").init()
