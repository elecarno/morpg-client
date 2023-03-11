extends Control

var def_dialog_path = "res://npcs/dialog/test_dialog.json"
export var dialog_path = ""
export(float) var text_speed = 0.05

onready var timer = get_node("text_timer")
onready var text = get_node("text")

var dialog

var phrase_num := 0
var finished := false

func activate(dialog_json):
	dialog_path = dialog_json
	visible = true
	timer.wait_time = text_speed
	dialog = get_dialog()
	assert(dialog, "dialog not found")
	next_phrase()
	
func _process(_delta):
	get_node("indicator").visible = finished
	if Input.is_action_just_pressed("crouch"):
		if finished:
			next_phrase()
		else:
			text.visible_characters = len(text.text)
	
func get_dialog() -> Array:
	var f = File.new()
	assert(f.file_exists(dialog_path), "dialog file path does not exist")
	f.open(dialog_path, File.READ)
	var json = f.get_as_text()
	
	var output = parse_json(json)
	
	if typeof(output) == TYPE_ARRAY:
		return output
	else:
		return []

func next_phrase() -> void:
	if phrase_num >= len(dialog):
		visible = false
		finished = false
		phrase_num = 0
		return
	
	finished = false
	get_node("name").bbcode_text = dialog[phrase_num]["name"]
	text.bbcode_text = dialog[phrase_num]["text"]
	text.visible_characters = 0
	
	while text.visible_characters < len(text.text):
		text.visible_characters += 1
		
		timer.start()
		yield(timer, "timeout")
	
	finished = true
	phrase_num += 1
	return
