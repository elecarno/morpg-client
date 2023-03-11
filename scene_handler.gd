extends Node2D

var mapstart = preload("res://world/area_1.tscn")

func _ready():
	var mapstart_instance = mapstart.instance()
	add_child(mapstart_instance)
