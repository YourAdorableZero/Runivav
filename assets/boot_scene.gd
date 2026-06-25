extends Control


func _ready():
	$animation_player.play("alpha")

func _load_menu():
	get_tree().change_scene_to_file("res://assets/multiplayer.tscn")
