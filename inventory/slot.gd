extends TextureRect

var item_obj = preload("res://inventory/item.tscn")
var item = null
var slot_index

export var slot_type = "inv"

onready var inventory_node = find_parent("inventory")
onready var ui = find_parent("player_stats")

func pick_from_slot():
	remove_child(item)
	ui.add_child(item)
	item.scale = Vector2(4, 4)
	item.get_node("tex").mouse_filter = MOUSE_FILTER_IGNORE
	item.get_node("tooltip").visible = false
	#item.toggle_tooltip()
	item = null
	
func remove_from_slot():
	#item.toggle_tooltip()
	item.get_node("tex").mouse_filter = MOUSE_FILTER_IGNORE
	item.get_node("tooltip").visible = false
	player_inv.remove_item(self)
	remove_child(item)
	item = null

func put_into_slot(new_item):
	item = new_item
	#item.position = Vector2(24, 24)
	item.scale = Vector2(2.4, 2.4)
	if slot_type == "weapon":
		item.position = Vector2(54, 0)
	elif slot_type == "armour" or slot_type == "hat":
		item.position = Vector2(0, 0)
		item.scale = Vector2(4, 4)
	else:
		item.position = Vector2(0, 0)
	item.get_node("tex").mouse_filter = MOUSE_FILTER_STOP
	ui.remove_child(item)
	add_child(item)
	
func use_item():
	item.remove_item_quantity(1)
	if item.item_quantity <= 0:
		remove_from_slot()
	
func initialise_item(item_name, item_quantity):
	var pos
	var size
	if slot_type == "weapon":
		pos = Vector2(54, 0)
		size = Vector2(2.4, 2.4)
	elif slot_type == "armour" or slot_type == "hat":
		pos = Vector2(0, 0)
		size = Vector2(4, 4)
	else:
		pos = Vector2(0, 0)
		size = Vector2(2.4, 2.4)
	
	if item == null:
		item = item_obj.instance()
		add_child(item)
		item.set_item(item_name, item_quantity, pos, size)
	else:
		item.set_item(item_name, item_quantity, pos, size)
