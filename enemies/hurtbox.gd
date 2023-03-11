class_name hurtbox
extends Area2D

export var is_player := false

func _init() -> void:
	collision_layer = 0
	collision_mask = 8

func _ready() -> void:
	if owner.get_groups().has("players"):
		is_player = true
	connect("area_entered", self, "_on_area_entered")
	
func _on_area_entered(hitbox: hitbox) -> void:
	if hitbox == null:
		return
		
	if !is_player:
		if hitbox.owner.is_in_group("enemy"):
			return
		
	if owner.has_method("take_damage") and owner.name != hitbox.owner.name:
		owner.take_damage(hitbox.damage)
