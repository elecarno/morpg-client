extends Control

onready var alert_label = get_node("alert_label")
# ui_state nodes
onready var login_screen = get_node("login_screen")
onready var create_acc_screen = get_node("create_acc")
# login nodes
onready var username_input = get_node("login_screen/username")
onready var userpassword_input = get_node("login_screen/password")
onready var login_button = get_node("login_screen/login_button")
onready var create_acc_button = get_node("login_screen/create_acc_button")
# create_acc nodes
onready var create_username_input = get_node("create_acc/create_username")
onready var create_password_input = get_node("create_acc/create_password")
onready var create_password_repeat_input = get_node("create_acc/create_password_repeat")
onready var confirm_button = get_node("create_acc/confirm_button")
onready var back_button = get_node("create_acc/back_button")

func _ready():
	self.visible = true
	get_node("bg").visible = true

func _on_login_button_pressed():
	if username_input.text == "" or userpassword_input.text == "":
		# popup and stop
		print("please provide valid user id and password")
		alert_label.text = "please provide valid username and password"
	else:
		login_button.disabled = true
		create_acc_button.disabled = true
		var username = username_input.get_text()
		var password = userpassword_input.get_text()
		print("attempting to login")
		alert_label.text = "attempting to login"
		gateway.connect_to_server(username, password, false)
		var player = get_parent().get_parent().get_node("player")
		player.username = username_input.get_text()
		get_parent().get_node("player_stats").set_physics_process(true)
#		player.name_label.text = player.username

func _on_create_acc_button_pressed():
	login_screen.hide()
	create_acc_screen.show()

func _on_back_button_pressed():
	create_acc_screen.hide()
	login_screen.show()

func _on_confirm_button_pressed():
	if create_username_input.get_text() == "":
		print("please provide a valid username")
		alert_label.text = "please provide a valid username"
	elif create_password_input.get_text() == "":
		print("please provide a valid password")
		alert_label.text = "please provide a valid password"
	elif create_password_repeat_input.get_text() == "":
		print("please repeat your password")
		alert_label.text = "please repeat your password"
	elif create_password_repeat_input.get_text() != create_password_input.get_text():
		print("passwords do not match")
		alert_label.text = "passwords do not match"
	elif create_password_input.get_text().length() <= 4:
		print("password must be at least 5 characters")
		alert_label.text = "password must be at least 5 characters"
	else:
		confirm_button.disabled = true
		back_button.disabled = true
		var username = create_username_input.get_text()
		var password = create_password_input.get_text()
		gateway.connect_to_server(username, password, true)
