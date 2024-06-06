extends Node2D

signal Textbox_opened
signal Textbox_closed
signal Enemies_loaded
signal Turn_completed

@onready var Textbox = $CanvasLayer/Control/Textbox
@onready var TextboxLabel = $CanvasLayer/Control/Textbox/Label
@onready var ActionPanel = $CanvasLayer/Control/CombatPanel/CombatItems/ActionPanel
@onready var PlayerHealth = $CanvasLayer/Control/CombatPanel/CombatItems/HealthPanel/PlayerHealth/PlayerHealthBar
@onready var AllyHealth = $CanvasLayer/Control/CombatPanel/CombatItems/HealthPanel/AllyHealth/AllyHealthBar
@onready var EnemyGroup = $CanvasLayer/Control/EnemyPos/EnemyGroup
@onready var PlayerGroup = $CanvasLayer/Control/PlayerPos/PlayerGroup

const BaseEnemy = preload("res://Entities/BaseEnemy.gd")
@export var Enemies: Array[Resource] = []

var player_starting_hp
var ally_starting_hp

var running = false
var battleover = false
var turn_queue: Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	
	if State.Enemies.size() != 0:
		Enemies = State.Enemies
	for enemy_data in Enemies:
		if enemy_data:
			add_enemy_to_scene(enemy_data)
	emit_signal("Enemies_loaded")
	
	player_starting_hp = State.Player_current_health
	ally_starting_hp = State.Ally_current_health
	
	set_health(PlayerHealth, State.Player_current_health, State.Player_max_health)
	set_health(AllyHealth, State.Ally_current_health, State.Ally_max_health)
	
	Textbox.hide()
	ActionPanel.hide()
	
	display_text("A group of enemies appears!")
	await Textbox_closed
	
	#ActionPanel.show()
	
	# Initialize turn queue
	initialize_turn_queue()
	# Start handling turns
	await handle_turns()

func display_text(text):
	emit_signal("Textbox_opened")
	Textbox.show()
	TextboxLabel.text = text
	if EnemyGroup and EnemyGroup.focusing_enemy == true and EnemyGroup.has_method("hide_focus"):
		EnemyGroup.hide_focus(EnemyGroup.focused_enemy)

func add_enemy_to_scene(enemy_data: BaseEnemy):
	var combat_enemy_scene = preload("res://Entities/Scenes/EnemyCombat.tscn")  # Path to your CombatEnemy scene
	var combat_enemy_instance = combat_enemy_scene.instantiate()
	combat_enemy_instance.enemy_data = enemy_data
	
	#Have unique names for enemies
	var unique_name = enemy_data.name
	var counter = 2
	while EnemyGroup.has_node(unique_name):
		unique_name = enemy_data.name + " " + str(counter)
		counter += 1
	combat_enemy_instance.name = unique_name
	enemy_data.name = unique_name
	EnemyGroup.add_child(combat_enemy_instance)

func set_health(progress_bar, health, max_health):
	progress_bar.value = health
	progress_bar.max_value = max_health
	progress_bar.get_node("Label").text = "HP: %d/%d" % [health, max_health]

func initialize_turn_queue():
	# Add enemies to the turn queue
	for enemy in EnemyGroup.get_children():
		enemy.accumulated_speed = 0
		add_to_turn_queue(enemy)
	# Add player and ally to the turn queue
	for character in PlayerGroup.get_children():
		character.accumulated_speed = 0
		add_to_turn_queue(character)

func add_to_turn_queue(character):
	character.accumulated_speed += character.speed
	turn_queue.append(character)
	sort_turn_queue()

func sort_turn_queue():
	turn_queue.sort_custom(CharacterSort)

func CharacterSort(a, b):
	return a.accumulated_speed > b.accumulated_speed

func get_next_turn():
	if turn_queue.size() > 0:
		return turn_queue[0]
	return null

#Remove from turn if dead
func handle_turns():
	while turn_queue.size() > 0:
		var current_character = turn_queue.pop_front()
		
		# Perform the character's action (implement this based on your game logic)
		perform_action(current_character)
		await Turn_completed
		
		# Accumulate speed for all characters
		for character in turn_queue:
			character.accumulated_speed += character.speed
			
		# Reset the accumulated speed for the character who took the turn
		current_character.accumulated_speed = 0
		
		# Add character back to the turn queue
		add_to_turn_queue(current_character)

func remove_from_turn_queue(value):
	for character in turn_queue:
			if character.name == value:
				turn_queue.erase(character)
				break

func perform_action(character):
	if character.has_method("player"):
		player_turn()
	elif character.has_method("ally"):
		ally_turn()
	else:
		enemy_turn(character)

func win_battle():
	ActionPanel.hide()
	battleover = true
	display_text("All enemies have been slain!")
	await Textbox_closed
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")
	#get_tree().quit()

func _input(event):
	if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and Textbox.visible:
		Textbox.hide()
		await get_tree().create_timer(0.1).timeout
		emit_signal("Textbox_closed")

func calculate_attack_damage(min_damage, max_damage) -> int:
	return randi_range(min_damage, max_damage)

func enemy_turn(character):
	if battleover == false:
		await get_tree().create_timer(0.3).timeout
		var target = choose_random_target()
		var damage = calculate_attack_damage(character.enemy_data.min_damage, character.enemy_data.max_damage)
		target.take_damage(damage, character.name, target.name)
		#display_text(character.name + " do nothing!")
		#display_text(character.name + " attacks " + target.name + " for " + str(damage) + " damage!")
		set_health(PlayerHealth, State.Player_current_health, State.Player_max_health)
		set_health(AllyHealth, State.Ally_current_health, State.Ally_max_health)
		await Textbox_closed
		emit_signal("Turn_completed")

func ally_turn():
	if battleover == false:
		await get_tree().create_timer(0.3).timeout
		display_text("Witch do nothing!")
		await Textbox_closed
		emit_signal("Turn_completed")

func player_turn():
	if battleover == false:
		ActionPanel.show()
		if EnemyGroup and EnemyGroup.focusing_enemy == false and EnemyGroup.focused_enemy != -1 and EnemyGroup.has_method("show_focus") and running == false:
				EnemyGroup.show_focus(EnemyGroup.focused_enemy)

func choose_random_target():
	var random_index = randi() % 2  # Randomly selects 0 or 1
	if random_index == 0:
		if PlayerGroup.get_child(0).is_alive == true:
			return PlayerGroup.get_child(0)  # Player is at index 0 in PlayerGroup
		else:
			return PlayerGroup.get_child(1)  # Ally is at index 1 in PlayerGroup
	else:
		if PlayerGroup.get_child(1).is_alive == true:
			return PlayerGroup.get_child(1)  # Ally is at index 1 in PlayerGroup
		else:
			return PlayerGroup.get_child(0)  # Player is at index 0 in PlayerGroup

func _on_attack_pressed():
	#display_text("You attack enemy, dealing %d damage!" % [State.Player_damage])
	if EnemyGroup and EnemyGroup.has_method("player_attack"):
		EnemyGroup.player_attack(calculate_attack_damage(State.Player_min_damage, State.Player_max_damage))
	ActionPanel.hide()
	EnemyGroup.hide_focus(EnemyGroup.focused_enemy)
	await Textbox_closed
	emit_signal("Turn_completed")
	#End Turn

func _on_defend_pressed():
	ActionPanel.hide()
	EnemyGroup.hide_focus(EnemyGroup.focused_enemy)
	display_text("You prepare to defend!")
	await Textbox_closed
	emit_signal("Turn_completed")
	#End Turn
	pass # Replace with function body.

func _on_run_pressed():
	running = true
	display_text("Got away safely!")
	await Textbox_closed
	await get_tree().create_timer(0.8).timeout
	State.enemy_to_remove_id.remove_at(State.enemy_to_remove_id.size() - 1)
	State.Player_current_health = player_starting_hp
	State.Ally_current_health = ally_starting_hp
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")
	#get_tree().quit()

func check_for_allies():
	await Textbox_closed
	if PlayerGroup.get_child(0).is_alive == false and PlayerGroup.get_child(1).is_alive == false:
		battleover = true
		display_text("All allies have been defeated!")
		await Textbox_closed
		await get_tree().create_timer(0.8).timeout
		get_tree().quit()
