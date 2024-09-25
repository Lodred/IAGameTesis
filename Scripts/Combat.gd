extends Node2D

signal Textbox_opened
signal Textbox_closed
signal Enemies_loaded
signal Turn_completed

@onready var Menu = $PauseMenu

@onready var Textbox = $CanvasLayer/Control/Textbox
@onready var TextboxLabel = $CanvasLayer/Control/Textbox/Label
@onready var ActionPanel = $CanvasLayer/Control/CombatPanel/CombatItems/ActionPanel
@onready var PlayerHealth = $CanvasLayer/Control/CombatPanel/CombatItems/HealthPanel/PlayerHealth/PlayerHealthBar
@onready var AllyHealth = $CanvasLayer/Control/CombatPanel/CombatItems/HealthPanel/AllyHealth/AllyHealthBar
@onready var EnemyGroup = $CanvasLayer/Control/EnemyPos/EnemyGroup
@onready var PlayerGroup = $CanvasLayer/Control/PlayerPos/PlayerGroup
@onready var Tutorial = $CanvasLayer/Control/TutorialBox
@onready var Click_sound = $UI

const BaseEnemy = preload("res://Entities/BaseEnemy.gd")
@export var Enemies: Array[Resource] = []

var player_starting_hp
var ally_starting_hp

var is_paused = false # Variable to track pause state
var running = false
var battleover = false
var turn_queue: Array = []

# Q-Learning parameters
var ally_combat_number = 0
var enemy_combat_number = 0
var q_table_enemy = {}
var q_table_ally = {}
var actions = ["Attack", "Defend", "Special"]
var learning_rate = 0.1
var discount_factor = 0.9
var epsilon = 0.2

# Variables for tracking state and actions
var ally_last_state
var ally_last_action
var enemy_last_state
var enemy_last_action
var current_state

# Constants for rewards and penalties
const WIN_REWARD = 100
const LOSE_PENALTY = -100
const HEALTH_LOSS_PENALTY = -0.1
const HEALTH_LOSS_REWARD = 0.1
var ally_accumulated_reward = 0
var enemy_accumulated_reward = 0

# Constants for reward settings
const REWARD_TYPE_PENALTY = "penalty"
const REWARD_TYPE_REWARD = "reward"
const REWARD_TYPE_MIXED = "mixed"

# Variable to store the current reward type (set this based on your game settings)
var reward_type = REWARD_TYPE_MIXED

# Settings for use discrete states or continuous states
var use_discrete_states = true

# Discretization parameters
const NUM_BINS = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	load_q_tables()
	if State.Enemies.size() != 0:
		Enemies = State.Enemies
	for enemy_data in Enemies:
		if enemy_data:
			add_enemy_to_scene(enemy_data)
	emit_signal("Enemies_loaded")
	
	#print(State.ally_file_path)
	#print(State.enemy_file_path)
	
	player_starting_hp = State.Player_current_health
	ally_starting_hp = State.Ally_current_health
	reward_type = State.reward_type
	
	set_health(PlayerHealth, State.Player_current_health, State.Player_max_health)
	set_health(AllyHealth, State.Ally_current_health, State.Ally_max_health)
	
	if State.Tutorial_Combat == false:
		Tutorial.set_visible(false)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
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
		add_to_turn_queue(enemy)
	# Add player and ally to the turn queue
	for character in PlayerGroup.get_children():
		add_to_turn_queue(character)
	sort_turn_queue()

func add_to_turn_queue(character):
	turn_queue.append(character)

func sort_turn_queue():
	turn_queue.sort_custom(CharacterSort)

func CharacterSort(a, b):
	return a.speed > b.speed

func get_next_turn():
	if battleover == false:
		if turn_queue.size() > 0:
			return turn_queue[0]
		return null

#Remove from turn if dead
func handle_turns():
	while battleover == false:
		while turn_queue.size() > 0:
			# Check if the battle is over after the action
			if battleover:
				break
				
			var current_character = turn_queue.pop_front()
			
			# Skip the turn if the character is dead
			if not current_character.is_alive:
				continue
				
			# Perform the character's action (implement this based on your game logic)
			perform_action(current_character)
			await Turn_completed
			
			# Add character back to the turn queue if they're still alive
			if current_character.is_alive:
				add_to_turn_queue(current_character)
				

func remove_from_turn_queue(value):
	for character in turn_queue:
			if character.name == value:
				turn_queue.erase(character)
				break

func perform_action(character):
	if character.has_method("player"):
		player_turn(character)
	elif character.has_method("ally"):
		ally_turn(character)
	else:
		enemy_turn(character)

func win_battle():
	battleover = true
	while Textbox.visible:
		await Textbox_closed
	
	# Calculate and apply final reward for ally
	var ally_final_reward = calculate_final_reward(true)
	var enemy_final_reward = calculate_final_reward(false)
	var current_state = get_combat_state()
	update_q_table(ally_last_state, ally_last_action, current_state, ally_final_reward, "ally")
	update_q_table(enemy_last_state, enemy_last_action, current_state, enemy_final_reward, "enemy")
	ally_accumulated_reward += ally_final_reward
	enemy_accumulated_reward += enemy_final_reward
	save_q_tables()
	display_text("All enemies have been slain!")
	#print(q_table_ally)
	await Textbox_closed
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")
	#get_tree().quit()

func lose_battle():
	battleover = true
	while Textbox.visible:
		await Textbox_closed
	
	# Calculate and apply final penalty for ally
	var ally_final_reward = calculate_final_reward(false)
	var enemy_final_reward = calculate_final_reward(true)
	var current_state = get_combat_state()
	update_q_table(ally_last_state, ally_last_action, current_state, ally_final_reward, "ally")
	update_q_table(enemy_last_state, enemy_last_action, current_state, enemy_final_reward, "enemy")
	ally_accumulated_reward += ally_final_reward
	enemy_accumulated_reward += enemy_final_reward
	save_q_tables()
	display_text("All allies have been defeated!")
	await Textbox_closed
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://Scenes/Lose.tscn")

func _input(event):
	if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and State.Tutorial_Combat:
		Click_sound.play()
		State.Tutorial_Combat = false
		Tutorial.set_visible(false)
	else:
		if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and Textbox.visible:
			Click_sound.play()
			Textbox.hide()
			await get_tree().create_timer(0.1).timeout
			emit_signal("Textbox_closed")

func calculate_attack_damage(min_damage, max_damage) -> int:
	return randi_range(min_damage, max_damage)

func enemy_turn(character):
	if battleover == false:
		while Textbox.visible:
			await Textbox_closed
		character.is_defending = false
		await get_tree().create_timer(0.3).timeout
		
		#Q Learning Code
		enemy_last_state = get_combat_state()
		
		if character.is_special == true:
			character.is_special = false
			enemy_last_action = "Special"
			var target = choose_random_ally()
			var damage = calculate_attack_damage(character.enemy_data.min_damage, character.enemy_data.max_damage)*2.5
			var end_damage = int(round(damage))
			target.take_damage(end_damage, character.name, target.name)
			character.attack()
		else:
			enemy_last_action = choose_action(enemy_last_state, "enemy")  # Choose action based on Q-table
			match enemy_last_action:
				"Attack":
					var target = choose_random_ally()
					var damage = calculate_attack_damage(character.enemy_data.min_damage, character.enemy_data.max_damage)
					target.take_damage(damage, character.name, target.name)
					character.attack()
				"Defend":
					#character.defend()
					display_text(character.name + " prepares to defend!")
					character.is_defending = true
					character.defend_sound.play()
				"Special":
					#character.preparespecial()
					display_text(character.name + " prepares a strong attack!")
					character.is_special = true
					character.special_sound.play()
		
		# Update Q-table
		current_state = get_combat_state()  # Update the state after action
		var reward = calculate_immediate_reward()*-1  # Calculate the immediate reward based on the result of the action
		update_q_table(enemy_last_state, enemy_last_action, current_state, reward, "enemy")  # Update the Q-table
		enemy_accumulated_reward += reward
		
		await Textbox_closed
		emit_signal("Turn_completed")

func ally_turn(character):
	if battleover == false:
		while Textbox.visible:
			await Textbox_closed
		character.is_defending = false
		await get_tree().create_timer(0.3).timeout
		
		#Q Learning Code
		ally_last_state = get_combat_state()
		
		if character.is_special == true:
			character.is_special = false
			ally_last_action = "Special"
			var target_enemy = choose_random_enemy()
			var damage = calculate_attack_damage(State.Ally_min_damage, State.Ally_max_damage)*2.5
			var end_damage = int(round(damage))
			EnemyGroup.ally_attack(target_enemy, end_damage)
			character.attack()
		else:
			ally_last_action = choose_action(ally_last_state, "ally")  # Choose action based on Q-table
			match ally_last_action:
				"Attack":
					var target_enemy = choose_random_enemy()
					var damage = calculate_attack_damage(State.Ally_min_damage, State.Ally_max_damage)
					EnemyGroup.ally_attack(target_enemy, damage)
					character.attack()
				"Defend":
					#character.defend()
					display_text("Ally prepares to defend!")
					character.is_defending = true
					character.defend_sound.play()
				"Special":
					#character.preparespecial()
					display_text("Ally prepares an ability!")
					character.is_special = true
					character.special_sound.play()
		
		#print(q_table_ally)
		
		# Update Q-table
		current_state = get_combat_state()  # Update the state after action
		var reward = calculate_immediate_reward()  # Calculate the immediate reward based on the result of the action
		update_q_table(ally_last_state, ally_last_action, current_state, reward, "ally")  # Update the Q-table
		ally_accumulated_reward += reward
		
		await Textbox_closed
		emit_signal("Turn_completed")

func player_turn(character):
	if battleover == false:
		while Textbox.visible:
			await Textbox_closed
		character.is_defending = false
		if character.is_special == true:
			character.is_special = false
			if EnemyGroup and EnemyGroup.has_method("player_attack"):
				var damage = calculate_attack_damage(State.Ally_min_damage, State.Ally_max_damage)*2.5
				var end_damage = int(round(damage))
				EnemyGroup.player_attack(end_damage)
				character.attack()
				await Textbox_closed
				emit_signal("Turn_completed")
		else:
			ActionPanel.show()
			if EnemyGroup and EnemyGroup.focusing_enemy == false and EnemyGroup.focused_enemy != -1 and EnemyGroup.has_method("show_focus") and running == false:
					EnemyGroup.show_focus(EnemyGroup.focused_enemy)

func get_combat_state():
	# Initialize health variables
	var player_health = State.Player_current_health
	var ally_health = State.Ally_current_health
	var enemies_health = []
	var enemies_max_health = []
	
	# Collect enemy healths
	for enemy in EnemyGroup.get_children():
		if enemy.current_health != null:
			enemies_health.append(enemy.current_health)
			enemies_max_health.append(enemy.max_health)
		else:
			print("Error: Enemy ", enemy.name, " does not have 'current_health' method.")
	
	# Ensure state is valid
	if player_health == null or ally_health == null or enemies_health.size() == 0:
		print("Error: Incomplete state in get_combat_state")
		print("Player health: ", player_health)
		print("Ally health: ", ally_health)
		print("Enemies healths: ", enemies_health)
		return null
	
	if use_discrete_states:
		return discretize_state(player_health, ally_health, enemies_health, enemies_max_health)
	else:
		return serialize_state({
			"player_health": player_health,
			"ally_health": ally_health,
			"enemy_healths": enemies_health
		})

# Function to discretize state
func discretize_state(player_health, ally_health, enemies_health, enemies_max_health):
	# Discretize player health
	var player_range = discretize_single_health(player_health, State.Player_max_health)
	
	# Discretize ally health
	var ally_range = discretize_single_health(ally_health, State.Ally_max_health)
	
	# Discretize enemies health (assuming an array of health values)
	var enemies_ranges = []
	for i in range(enemies_health.size()):
		enemies_ranges.append(discretize_single_health(enemies_health[i], enemies_max_health[i]))
	
	# Combine all ranges into a single state string
	var state = player_range + "," + ally_range
	for i in range(enemies_ranges.size()):
		state += "," + enemies_ranges[i]
	
	return state

# Helper function to discretize a single health value
func discretize_single_health(health, max_health):
	const BIN_SIZE = 20
	var health_percentage = (health / max_health) * 100
	var bin_index = int(floor(health_percentage / BIN_SIZE))
	bin_index = min(bin_index, NUM_BINS - 1)
	var range_start = bin_index * BIN_SIZE
	var range_end = (bin_index + 1) * BIN_SIZE
	if range_end > 100:
		range_end = 100
	return str(range_start) + "-" + str(range_end)

func serialize_state(state):
	return str(state["ally_health"]) + "_" + str(state["enemy_health"])

#For enemies * -1
func calculate_immediate_reward():
	#If Penalty Only (-Health Lost), If Both, If Rewards only (+Enemy Health Lost) | Let the player choose on settings
	var player_health_lost = player_starting_hp - State.Player_current_health
	var ally_health_lost = ally_starting_hp - State.Ally_current_health
	var total_health_lost = player_health_lost + ally_health_lost
	
	# Calculate health lost for enemies
	var total_enemy_health_lost = 0
	for enemy in EnemyGroup.get_children():
		total_enemy_health_lost += enemy.max_health - enemy.current_health
	# Calculate the reward based on the chosen reward type
	match reward_type:
		REWARD_TYPE_PENALTY:
			return total_health_lost * HEALTH_LOSS_PENALTY
		REWARD_TYPE_REWARD:
			return total_enemy_health_lost * HEALTH_LOSS_REWARD
		REWARD_TYPE_MIXED:
			return (total_enemy_health_lost * HEALTH_LOSS_REWARD) - (total_health_lost * HEALTH_LOSS_PENALTY)
		_:
			return 0  # Default case if reward_type is not set correctly

func calculate_final_reward(won):
	if won == true:
		return WIN_REWARD
	else:
		return LOSE_PENALTY

func update_q_table(old_state, action, new_state, reward, table_type):
	var q_table = q_table_enemy if table_type == "enemy" else q_table_ally

	if !q_table.has(old_state):
		q_table[old_state] = {}

	if !q_table[old_state].has(action):
		q_table[old_state][action] = 0.0

	var max_q_value = 0.0
	if q_table.has(new_state):
		var new_state_actions = q_table[new_state]
		if new_state_actions.size() > 0:
			for value in new_state_actions.values():
				if value > max_q_value:
					max_q_value = value

	q_table[old_state][action] = q_table[old_state][action] + learning_rate * (reward + discount_factor * max_q_value - q_table[old_state][action])

func choose_action(state, table_type):
	if randf() < epsilon:
		return actions[randi() % actions.size()]  # Random action (exploration)
	else:
		var q_table = q_table_enemy if table_type == "enemy" else q_table_ally
		if q_table.has(state):
			var max_action = ""
			var max_value = -INF
			for action in q_table[state]:
				var value = q_table[state][action]
				if value > max_value:
					max_value = value
					max_action = action
			return max_action  # Best action (exploitation)
		else:
			return actions[randi() % actions.size()]  # Random action if state not in Q-table

# Function to save Q-table to a JSON file
func save_q_table_as_json(file_path, q_table, combat_number, reward):
	var data = load_q_table_from_json(file_path)
	data.append({
		"q_table": q_table,
		"reward": reward,
		"combat_number": combat_number
	})

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data)
		file.store_string(json_string)
		file.close()
	else:
		print("Failed to save Q-table")

# Function to load Q-table from a JSON file
func load_q_table_from_json(file_path):
	if !FileAccess.file_exists(file_path):
		print("File does not exist: ", file_path)
		return []

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		var result = json.parse(json_string)
		if result == OK:
			var data = json.get_data()
			return data
		else:
			print("Error parsing JSON: ", result.error_string)
	else:
		print("Failed to open file: ", file_path)
	return []

# Save the Q-tables at the end of each battle
func save_q_tables():
	if State.use_tables == false:
		ally_combat_number += 1
		enemy_combat_number += 1
		if State.ally_file_path != "res://Qtables/q_table_ally_default.json":
			save_q_table_as_json("res://Qtables/q_table_ally_manual.json", q_table_ally, ally_combat_number, ally_accumulated_reward)
		if State.enemy_file_path != "res://Qtables/q_table_enemy_default.json":
			save_q_table_as_json("res://Qtables/q_table_enemy_manual.json", q_table_enemy, enemy_combat_number, enemy_accumulated_reward)

# Load the Q-tables at the start of the game
func load_q_tables():
	
	var ally_data = load_q_table_from_json(State.ally_file_path)
	var enemy_data = load_q_table_from_json(State.enemy_file_path)
	
	if State.use_tables == false:
		ally_data = load_q_table_from_json("")
		enemy_data = load_q_table_from_json("")
	
	if ally_data.size() > 0:
		var last_ally_entry = ally_data[ally_data.size() - 1]
		q_table_ally = last_ally_entry["q_table"]
		ally_combat_number = last_ally_entry["combat_number"]
	else:
		q_table_ally = {}
		ally_combat_number = 0
	
	if enemy_data.size() > 0:
		var last_enemy_entry = enemy_data[enemy_data.size() - 1]
		q_table_enemy = last_enemy_entry["q_table"]
		enemy_combat_number = last_enemy_entry["combat_number"]
	else:
		q_table_enemy = {}
		enemy_combat_number = 0

func choose_random_ally():
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

func choose_random_enemy():
	if battleover == false:
		var enemies = EnemyGroup.enemies
		var random_index = randi() % enemies.size()
		return random_index

func _on_attack_pressed():
	#display_text("You attack enemy, dealing %d damage!" % [State.Player_damage])
	if EnemyGroup and EnemyGroup.has_method("player_attack"):
		EnemyGroup.player_attack(calculate_attack_damage(State.Player_min_damage, State.Player_max_damage))
		PlayerGroup.get_child(0).attack()
	ActionPanel.hide()
	EnemyGroup.hide_focus(EnemyGroup.focused_enemy)
	await Textbox_closed
	emit_signal("Turn_completed")
	#End Turn

func _on_special_pressed():
	ActionPanel.hide()
	#PlayerGroup.get_child(0).preparespecial()
	PlayerGroup.get_child(0).is_special = true
	PlayerGroup.get_child(0).special_sound.play()
	display_text("You prepare to do a strong attack!")
	await Textbox_closed
	emit_signal("Turn_completed")


func _on_defend_pressed():
	ActionPanel.hide()
	EnemyGroup.hide_focus(EnemyGroup.focused_enemy)
	#PlayerGroup.get_child(0).defend()
	PlayerGroup.get_child(0).is_defending = true
	PlayerGroup.get_child(0).defend_sound.play()
	display_text("You prepare to defend!")
	await Textbox_closed
	emit_signal("Turn_completed")
	#End Turn
	pass # Replace with function body.

func _on_run_pressed():
	running = true
	ActionPanel.hide()
	EnemyGroup.hide_focus(EnemyGroup.focused_enemy)
	PlayerGroup.get_child(0).run_sound.play()
	display_text("Got away safely!")
	await Textbox_closed
	await get_tree().create_timer(0.8).timeout
	State.enemy_to_remove_id.remove_at(State.enemy_to_remove_id.size() - 1)
	State.Player_current_health = player_starting_hp
	State.Ally_current_health = ally_starting_hp
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")
	#get_tree().quit()

func check_for_allies():
	while Textbox.visible:
		await Textbox_closed
	if PlayerGroup.get_child(0).is_alive == false and PlayerGroup.get_child(1).is_alive == false:
		lose_battle()

func _process(delta):
	if Input.is_action_just_pressed("Pause"):
		is_paused = !is_paused # Toggle pause state
		pause(is_paused)

func pause(state):
	if state:
		get_tree().paused = true # Pause the game
		Menu.visible = true
		# Show the pause menu
	else:
		get_tree().paused = false # Resume the game
		Menu.visible = false
		# Hide the pause menu
