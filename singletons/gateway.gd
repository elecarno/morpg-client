extends Node

# onready var alert_label = get_node("../scene_handler/map/gui/login_system/alert_label")

var network = NetworkedMultiplayerENet.new()
var gateway_api = MultiplayerAPI.new()
var ip = "127.0.0.1"
var port = 1910

var username
var password
var new_account = false

func _ready():
	pass
	
func _process(_delta):
	if get_custom_multiplayer() == null:
		return
	if not custom_multiplayer.has_network_peer():
		return
	custom_multiplayer.poll()
	
func connect_to_server(_username, _password, _new_account):
	network = NetworkedMultiplayerENet.new()
	gateway_api = MultiplayerAPI.new()
	username = _username
	password = _password
	new_account = _new_account
	network.create_client(ip, port)
	set_custom_multiplayer(gateway_api)
	custom_multiplayer.set_root_node(self)
	custom_multiplayer.set_network_peer(network)
	
	network.connect("connection_failed", self, "_on_connection_failed")
	network.connect("connection_succeeded", self, "_on_connection_succeeded")
	
func _on_connection_failed():
	var alert_label = get_node("../scene_handler/map/gui/login_system/alert_label")
	print("failed to connect to login server")
	# print("pop-up server offline or something")
	alert_label.text = "failed to connect to login server"
	get_node("../scene_handler/map/gui/login_system").login_button.disabled = false
	get_node("../scene_handler/map/gui/login_system").create_acc_button.disabled = false
	get_node("../scene_handler/map/gui/login_system").confirm_button.disabled = false
	get_node("../scene_handler/map/gui/login_system").back_button.disabled = false
	
func _on_connection_succeeded():
	print("successfully connected to login server")
	# alert_label.text = "successfully connected to login server"
	if new_account == true:
		request_create_account()
	else:
		request_login()
	
func request_login():
	print("connecting to gateway to request login")
	# alert_label.text = "connecting to gateway to request login"
	rpc_id(1, "login_request", username, password)
	username = ""
	password = ""
	
remote func return_login_request(results, token, login_username):
	print("results received")
	if results == true:
		server.token = token
		server.playeruser = login_username
		server.connect_to_server()
	else:
		var alert_label = get_node("../scene_handler/map/gui/login_system/alert_label")
		print("please provide correct username and password")
		alert_label.text = "please provide correct username and password"
		get_node("../scene_handler/map/gui/login_system").login_button.disabled = false
		get_node("../scene_handler/map/gui/login_system").create_acc_button.disabled = false
	network.disconnect("connection_failed", self, "_on_connection_failed")
	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")
	
func request_create_account():
	print("requesting new account")
	# alert_label.text = "requesting new account"
	rpc_id(1, "create_account_request", username, password)
	username = ""
	password = ""

remote func return_create_account_request(results, message):
	print("results recieved")
	var alert_label = get_node("../scene_handler/map/gui/login_system/alert_label")
	if results == true:
		print("account created, please proceed with logging in")
		alert_label.text = "account created, please proceed with logging in"
		get_node("../scene_handler/map/gui/login_system")._on_back_button_pressed()
	else:
		if message == 1:
			print("couldn't create account, please try again")
			alert_label.text = "couldn't create account, please try again"
		elif message == 2:
			print("this username is already used, please try again with a different username")
			alert_label.text = "this username is already used, please try again with a different username"
		get_node("../scene_handler/map/gui/login_system").confirm_button.disabled = false
		get_node("../scene_handler/map/gui/login_system").back_button.disabled = false
	network.disconnect("connection_failed", self, "_on_connection_failed")
	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")
