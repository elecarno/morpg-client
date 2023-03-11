extends Sprite

func _ready():
	get_node("tween").interpolate_property(self, "modulate:a", 1.0, 0.0, 0.5, 3, 1)
	get_node("tween").start()


func _on_tween_tween_completed(_object, _key):
	queue_free()
