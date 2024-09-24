extends Node2D

@onready var Menu = $PauseMenu

var player
var is_paused = false # Variable to track pause state

func _ready():
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player = $Player
	Menu.visible = false
	
	if State.Tutorial_Main == false:
		$CanvasLayer/TutorialBox.set_visible(false)
	
	if State.enemy_to_remove_id.size() > 0:
		if State.enemy_to_remove_id.size() == 2:
			await get_tree().create_timer(0.1).timeout
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().change_scene_to_file("res://Scenes/Win.tscn")
		else:
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

func _process(delta):
	if Input.is_action_just_pressed("Pause"):
		is_paused = !is_paused # Toggle pause state
		pause(is_paused)

func pause(state):
	if state:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Show mouse when paused
		get_tree().paused = true # Pause the game
		Menu.visible = true
		# Show the pause menu
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Hide mouse during gameplay
		get_tree().paused = false # Resume the game
		Menu.visible = false
		# Hide the pause menu
