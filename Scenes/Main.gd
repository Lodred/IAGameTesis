extends Node2D

var player

func _ready():
	player = $Player
	
	if State.Tutorial_Main == false:
		$CanvasLayer/TutorialBox.set_visible(false)
	
	if State.enemy_to_remove_id.size() > 0:
		for enemy_id in State.enemy_to_remove_id:
			remove_enemy_by_id(enemy_id)
	
	if State.Player_alive == false:
		State.Player_current_health = 10
	if State.Ally_alive == false:
		State.Ally_current_health = 10
	player.position = State.load_player_position()

func remove_enemy_by_id(id):
	var enemy_to_remove = null
	for child in get_children():
		if child.has_method("enemy") and child.id == id:
			enemy_to_remove = child
			child.queue_free()
			break

func _input(event):
	if event is InputEventKey and event.pressed:
		close_tutorial()
		
func close_tutorial():
	State.Tutorial_Main = false
	$CanvasLayer/TutorialBox.set_visible(false)
