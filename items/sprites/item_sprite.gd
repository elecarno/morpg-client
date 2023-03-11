tool
extends TextureRect

onready var quantity_label = get_node("quantity")

export(Resource) var item setget _set_item

func _set_item(new_item: Resource):
	item = new_item
	self.texture = item.get_texture()
	#$Label.text = str(new_item.get_quantity())

func add_quantity(amount: int):
	item.add_quantity(amount)
