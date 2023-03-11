extends Resource

class_name Item

export(String) var ITEM_NAME
export(Texture) var ITEM_TEXTURE
export(int) var QUANTITY
export(String, MULTILINE) var HOVER_TEXT

func add_quantity(amount: int):
	QUANTITY += amount

func get_texture() -> Texture:
	return ITEM_TEXTURE

func get_quantity() -> int:
	return QUANTITY
