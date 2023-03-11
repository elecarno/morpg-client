extends Control

const slot_class = preload("res://inventory/slot.gd")
onready var playerstats = get_parent()
onready var inv_slots = get_node("inventory")
onready var equip_slots = get_node("equip_slots")

func init():
	var slots = inv_slots.get_children()
	for i in range(slots.size()):
		slots[i].connect("gui_input", self, "slot_gui_input", [slots[i]])
		slots[i].slot_index = i
		
	var e_slots = equip_slots.get_children()
	for i in range(e_slots.size()):
		e_slots[i].connect("gui_input", self, "slot_gui_input", [e_slots[i]])
		e_slots[i].slot_index = i
	
	initialise_inventory()
		
func initialise_inventory():
	print("init")
	var slots = inv_slots.get_children()
	for i in range(slots.size()):
		if playerstats.playerdata.inv.has(str(i)):
			slots[i].initialise_item(playerstats.playerdata.inv[str(i)][0], playerstats.playerdata.inv[str(i)][1])
	
	var e_slots = equip_slots.get_children()
	for i in range(e_slots.size()):
		if playerstats.playerdata.equips.has(str(i)):
			e_slots[i].initialise_item(playerstats.playerdata.equips[str(i)][0], playerstats.playerdata.equips[str(i)][1])
		
func slot_gui_input(event: InputEvent, slot: slot_class):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed:
			# currently holding an item
			if playerstats.holding_item != null:
				if !slot.item:
					left_click_empty_slot(slot)
				else: 
					if playerstats.holding_item.item_name != slot.item.item_name:
						left_click_different_item(event, slot)
					else:
						left_click_same_item(slot)
			elif slot.item:
				left_click_not_holding(slot)

func _input(_event):
	if playerstats.holding_item:
		playerstats.holding_item.global_position = get_global_mouse_position()

func able_to_insert(slot: slot_class):
	var holding_item = playerstats.holding_item
	if holding_item == null:
		return
	var holding_item_category = playerstats.itemdata[holding_item.item_name]["type"]
	if slot.slot_type == "weapon":
		return holding_item_category == "weapon"
	elif slot.slot_type == "armour":
		return holding_item_category == "armour"
	elif slot.slot_type == "hat":
		return holding_item_category == "hat"
	else:
		return true

func left_click_empty_slot(slot: slot_class):
	if able_to_insert(slot):
		slot.put_into_slot(find_parent("player_stats").holding_item)
		player_inv.add_item_to_empty_slot(find_parent("player_stats").holding_item, slot)
		find_parent("player_stats").holding_item = null
	
func left_click_different_item(event: InputEvent, slot: slot_class):
	if able_to_insert(slot):
		player_inv.remove_item(slot)
		player_inv.add_item_to_empty_slot(find_parent("player_stats").holding_item, slot)
		var temp_item = slot.item
		slot.pick_from_slot()
		temp_item.global_position = event.global_position
		slot.put_into_slot(find_parent("player_stats").holding_item)
		find_parent("player_stats").holding_item = temp_item

func left_click_same_item(slot: slot_class):
	if able_to_insert(slot):
		var stack_size = int(playerstats.itemdata[slot.item.item_name]["stacksize"])
		var able_to_add = stack_size - slot.item.item_quantity
		if able_to_add >= find_parent("player_stats").holding_item.item_quantity:
			player_inv.add_item_quantity(slot, find_parent("player_stats").holding_item.item_quantity)
			slot.item.add_item_quantity(find_parent("player_stats").holding_item.item_quantity)
			find_parent("player_stats").holding_item.queue_free()
			find_parent("player_stats").holding_item = null
		else:
			player_inv.add_item_quantity(slot, able_to_add)
			slot.item.add_item_quantity(able_to_add)
			find_parent("player_stats").holding_item.remove_item_quantity(able_to_add)

func left_click_not_holding(slot: slot_class):
	player_inv.remove_item(slot)
	find_parent("player_stats").holding_item = slot.item
	slot.pick_from_slot()
	find_parent("player_stats").holding_item.global_position = get_global_mouse_position()
