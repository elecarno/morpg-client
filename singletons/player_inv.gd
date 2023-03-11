extends Node

signal active_item_updated

const slot_class = preload("res://inventory/slot.gd")
const item_class = preload("res://inventory/item.gd")

const NUM_INV_SLOTS = 30
const NUM_HOTBAR_SLOTS = 10

var playerstats
var inventory
var equips

func add_item(item_name, item_quantity):
	var playerstats = get_node("/root/scene_handler/map/gui/player_stats")
	var inventory = playerstats.playerdata.inv
	for item in inventory:
		if inventory[item][0] == item_name:
			var stack_size = int(playerstats.itemdata[item_name]["stacksize"])
			var able_to_add = stack_size - inventory[item][1]
			if able_to_add >= item_quantity:
				inventory[item][1] += item_quantity
				update_slot_visual(item, inventory[item][0], inventory[item][1])
				return
			else:
				inventory[item][1] += able_to_add
				update_slot_visual(item, inventory[item][0], inventory[item][1])
				item_quantity = item_quantity - able_to_add
			
	# item doesn't exist in inventory yet, so add it to an empty slot
	for i in range(NUM_INV_SLOTS):
		if inventory.has(i) == false:
			inventory[i] = [item_name, item_quantity]
			update_slot_visual(i, inventory[i][0], inventory[i][1])
			return

func get_vars():
	playerstats = get_node("/root/scene_handler/map/gui/player_stats")
	inventory = playerstats.playerdata.inv
	equips = playerstats.playerdata.equips

func remove_item(slot: slot_class):
	get_vars()
	if slot.slot_type == "inv":
		inventory.erase(str(slot.slot_index))
	else:
		equips.erase(str(slot.slot_index))
	playerstats.update_server_data()

func update_slot_visual(slot_index, item_name, new_quantity):
	var slot = get_tree().root.get_node("/root/scene_handler/gui/player_stats/inv/inventory/slot_" + str(slot_index + 1))
	if slot.item != null:
		slot.item.set_item(item_name, new_quantity)
	else:
		slot.initialise_item(item_name, new_quantity)
	get_vars()
	playerstats.update_server_data()

func add_item_to_empty_slot(item: item_class, slot: slot_class):
	get_vars()
	if slot.slot_type == "inv":
		inventory[str(slot.slot_index)] = [item.item_name, item.item_quantity]
	else:
		equips[str(slot.slot_index)] = [item.item_name, item.item_quantity]
	playerstats.update_server_data()

func add_item_quantity(slot: slot_class, quantity_to_add: int):
	get_vars()
	if slot.slot_type == "inv":
		inventory[str(slot.slot_index)][1] += quantity_to_add
	else: 
		equips[str(slot.slot_index)][1] += quantity_to_add
	playerstats.update_server_data()
