extends Control

var playerdata
var itemdata
var initial_load = false

onready var regen_timer = get_node("regen_timer")
onready var player = get_parent().get_parent().get_node("player")
onready var ui_anim = get_node("ui_anim")

var block_energy_regen := false
var inv_open := false

export var addition_multiplier = 300 # range of 1 - 3000
export var power_multiplier = 2 # range of 2 - 4
export var division_multiplier = 7 # range 7- 14

var holding_item = null
	
func _ready():
	ui_anim.play("close_inv")
	set_physics_process(false)
	
func _physics_process(_delta):
	if Input.is_action_just_pressed("inventory"):
		if !inv_open:
			inv_open = true
			ui_anim.play("open_inv")
			update_display()
		else:
			inv_open = false
			ui_anim.play("close_inv")
			update_display()
			
func load_playerdata(data):
	playerdata = data
	if initial_load == false:
		server.fetch_itemdata()
		#playerdata.inv = {} # solves a dumb bug where the default item data is added on every time you load back in
		get_parent().get_parent().get_node("player").position.x = playerdata.pos.x
		get_parent().get_parent().get_node("player").position.y = playerdata.pos.y
		initial_load = true
	update_display()
	if !block_energy_regen:
		begin_energy_regen()

func update_display():
	get_node("hud/hp_bar").max_value = playerdata.stats.maxhp
	get_node("hud/hp_bar").value = playerdata.stats.hp
	
	get_node("hud/energy_bar").max_value = playerdata.stats.maxenergy
	get_node("hud/energy_bar").value = playerdata.stats.energy
	
	get_node("hud/xp_bar").value = playerdata.stats.xp
	get_node("hud/xp_bar").max_value = calc_required_xp()
		
	get_node("hud/credits_label").text = str(playerdata.credits)
	get_node("hud/def_label").text = str(playerdata.stats.def)
	get_node("hud/atk_label").text = str(playerdata.stats.atk)
	get_node("hud/agi_label").text = str(playerdata.stats.agi)
	
	get_node("inv/hp_label").text = str(floor(playerdata.stats.hp)) + "/" + str(floor(playerdata.stats.maxhp))
	get_node("inv/energy_label").text = str(floor(playerdata.stats.energy)) + "/" + str(floor(playerdata.stats.maxenergy))
	get_node("inv/sp_label").text = "SP: " + str(playerdata.stats.sp)
	
	if !inv_open:
		get_node("hud/lvl_label").text = str(playerdata.lvl)
	else:
		get_node("hud/lvl_label").text = str(playerdata.lvl) + ", xp: " + str(floor(playerdata.stats.xp)) + "/" + str(calc_required_xp())
	
	get_node("inv/player_name").text = get_parent().get_parent().get_node("player").username
	
	storeposition()

func update_server_data():
	server.write_playerdata_update(playerdata)
	server.fetch_playerdata()

func gain_xp(amount):
	playerdata.stats.xp += amount
	if playerdata.stats.xp >= calc_required_xp():
		playerdata.lvl += 1
		playerdata.stats.sp += 1
		playerdata.stats.xp = 0
	server.write_playerdata_update(playerdata)
	server.fetch_playerdata()
	
func gain_credits(amount):
	playerdata.credits += amount
	server.write_playerdata_update(playerdata)
	server.fetch_playerdata()
	
func calc_required_xp() -> int:
	var solve_for_required_xp = 0
	for level_cycle in range(0, playerdata.lvl):
		solve_for_required_xp += int(floor(level_cycle + addition_multiplier * pow(power_multiplier, level_cycle / division_multiplier)))
	return solve_for_required_xp/4

func playerhit(damage):
	playerdata.stats.hp -= damage
	if playerdata.stats.hp <= 0:
		playerdata.stats.hp = 100
		get_parent().get_parent().get_node("player").position.x = playerdata.spawn.x
		get_parent().get_parent().get_node("player").position.y = playerdata.spawn.y
	if playerdata.stats.hp > playerdata.stats.maxhp:
		playerdata.stats.hp = playerdata.stats.maxhp
	server.write_playerdata_update(playerdata)
	server.fetch_playerdata()
	
func player_use_energy(amount):
	block_energy_regen = true
	playerdata.stats.energy -= amount
	if playerdata.stats.energy < 0:
		playerdata.stats.energy = 0
	if playerdata.stats.energy > playerdata.stats.maxenergy:
		playerdata.stats.energy = playerdata.stats.maxenergy
	server.write_playerdata_update(playerdata)
	server.fetch_playerdata()
	
func playerattack(usage):
	if playerdata == null:
		return
		
	playerdata.stats.energy -= usage
	if playerdata.stats.energy < 0:
		playerdata.stats.energy = 0
	begin_energy_regen()
	server.write_playerdata_update(playerdata)
	server.fetch_playerdata()
	
func begin_energy_regen():
	if !block_energy_regen:
		playerdata.stats.energy += 0.5
		regen_timer.start()

func storeposition():
	playerdata.pos.x = get_parent().get_parent().get_node("player").position.x
	playerdata.pos.y = get_parent().get_parent().get_node("player").position.y
	server.write_playerdata_update(playerdata)

func _on_regen_timer_timeout():
	if playerdata.stats.energy < playerdata.stats.maxenergy:
		playerdata.stats.energy += 1
		server.write_playerdata_update(playerdata)
		server.fetch_playerdata()
		
		if !block_energy_regen:
			regen_timer.start()

func _on_def_add_pressed():
	if playerdata.stats.sp > 0:
		playerdata.stats.def += 1
		playerdata.stats.sp -= 1
		server.write_playerdata_update(playerdata)
		server.fetch_playerdata()

func _on_atk_add_pressed():
	if playerdata.stats.sp > 0:
		playerdata.stats.atk += 1
		playerdata.stats.sp -= 1
		server.write_playerdata_update(playerdata)
		server.fetch_playerdata()

func _on_agi_add_pressed():
	if playerdata.stats.sp > 0 and playerdata.stats.agi < 200:
		playerdata.stats.agi += 1
		playerdata.stats.sp -= 1
		server.write_playerdata_update(playerdata)
		server.fetch_playerdata()
