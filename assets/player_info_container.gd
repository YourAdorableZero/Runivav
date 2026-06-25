extends HBoxContainer

var id = 0
var nickname = "Player"

func set_player_info(new_id, new_nickname):
	id = new_id
	nickname = new_nickname

func _ready():
	name = str(id)
	$name.text = nickname
