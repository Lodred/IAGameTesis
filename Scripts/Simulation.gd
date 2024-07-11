extends Control

signal Turn_completed

# Q-Learning parameters
var q_table_ally = {}
var q_table_enemy = {}
var ally_combat_number = 0
var enemy_combat_number = 0
var actions = ["Attack", "Defend", "Special"]
var learning_rate = 0.1
var discount_factor = 0.9
var epsilon = 0.2

# Variables for tracking state and actions
var ally_health
var enemy_health
var ally_defense = false
var enemy_defense = false
var ally_special = false
var enemy_special = false
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

# Settings for current reward type (set this based on your game settings)
var reward_type = REWARD_TYPE_MIXED

# Settings for use discrete states or continuous states
var use_discrete_states = true

# Discretization parameters
const NUM_BINS = 5

# Constants for defend action
const DEFEND_REDUCTION = 2

# Called when the node enters the scene tree for the first time.
func start_sim(value):
	# Initialize combat
	for i in range(value):  # Simulate n combats
		print("Combat ", i + 1)
		simulate_combat()

# Simulate a combat between Ally and Enemy
func simulate_combat():
	# Load Q-tables
	load_q_tables()
	
	# Initialize variables
	ally_health = 100
	enemy_health = 100
	ally_accumulated_reward = 0
	enemy_accumulated_reward = 0

	while ally_health > 0 and enemy_health > 0:
		# Ally's turn
		ally_last_state = get_combat_state(ally_health, enemy_health)
		if ally_defense == true:
			ally_defense = false
			
		if ally_special == true:
			ally_special = false
			ally_last_action = "Special"
			var damage = calculate_attack_damage(15, 25)  # Example special damage range
			if enemy_defense == true:
				print("Ally uses a special attack for ", damage-DEFEND_REDUCTION, " defense damage.")
				enemy_health -= (damage-DEFEND_REDUCTION)
			else:
				print("Ally uses a special attack for ", damage, " damage.")
				enemy_health -= damage
		else:
			ally_last_action = choose_action(ally_last_state, "ally")
			match ally_last_action:
				"Attack":
					var damage = calculate_attack_damage(5, 10)  # Example damage range
					if enemy_defense == true:
						print("Ally attacks for ", damage-DEFEND_REDUCTION, " defense damage.")
						enemy_health -= (damage-DEFEND_REDUCTION)
					else:
						print("Ally attacks for ", damage, " damage.")
						enemy_health -= damage
				"Defend":
					print("Ally defends.")
					ally_defense = true
				"Special":
					print("Ally prepares special.")
					ally_special = true
		
		# Update Q-table for ally
		current_state = get_combat_state(ally_health, enemy_health)
		var reward = calculate_immediate_reward(ally_health, enemy_health)  # Calculate reward based on enemy health
		update_q_table(ally_last_state, ally_last_action, current_state, reward, "ally")
		ally_accumulated_reward += reward

		# Enemy's turn
		enemy_last_state = get_combat_state(ally_health, enemy_health)
		if enemy_defense == true:
			enemy_defense = false
			
		if enemy_special == true:
			enemy_special = false
			enemy_last_action = "Special"
			var damage = calculate_attack_damage(15, 25)  # Example special damage range
			if ally_defense == true:
				print("Enemy uses a special attack for ", damage-DEFEND_REDUCTION, " defense damage.")
				ally_health -= (damage-DEFEND_REDUCTION)
			else:
				print("Enemy uses a special attack for ", damage, " damage.")
				ally_health -= damage
		else:
			enemy_last_action = choose_action(enemy_last_state, "enemy")
			match enemy_last_action:
				"Attack":
					var damage = calculate_attack_damage(5, 10)  # Example damage range
					if ally_defense == true:
						print("Enemy attacks for ", damage-DEFEND_REDUCTION, " defense damage.")
						ally_health -= (damage-DEFEND_REDUCTION)
					else:
						print("Enemy attacks for ", damage, " damage.")
						ally_health -= damage
				"Defend":
					print("Enemy defends.")
					enemy_defense = true
				"Special":
					print("Enemy prepares special.")
					enemy_special = true

		# Update Q-table for enemy
		current_state = get_combat_state(ally_health, enemy_health)
		reward = calculate_immediate_reward(enemy_health, ally_health)  # Calculate reward based on ally health
		update_q_table(enemy_last_state, enemy_last_action, current_state, reward, "enemy")
		enemy_accumulated_reward += reward

	# Determine the winner
	if ally_health > 0:
		win_battle()
	else:
		lose_battle()

# Function to get the current combat state
func get_combat_state(ally_health, enemy_health):
	if use_discrete_states:
		return discretize_state(ally_health, enemy_health)
	else:
		return serialize_state({
			"ally_health": ally_health,
			"enemy_health": enemy_health
		})

# Function to discretize state
func discretize_state(ally_health, enemy_health):
	const BIN_SIZE = 20
	
	# Calculate the bin index for ally health
	var ally_bin = int(floor(ally_health / BIN_SIZE))
	# Calculate the bin index for enemy health
	var enemy_bin = int(floor(enemy_health / BIN_SIZE))
	
	# Make sure the bin index does not exceed the number of bins
	ally_bin = min(ally_bin, NUM_BINS - 1)
	enemy_bin = min(enemy_bin, NUM_BINS - 1)
	
	# Calculate the range for ally health
	var ally_range_start = ally_bin * BIN_SIZE
	var ally_range_end = (ally_bin + 1) * BIN_SIZE
	
	# Calculate the range for enemy health
	var enemy_range_start = enemy_bin * BIN_SIZE
	var enemy_range_end = (enemy_bin + 1) * BIN_SIZE
	
	# Ensure the end of the range is capped at 100
	if ally_range_end > 100:
		ally_range_end = 100
	if enemy_range_end > 100:
		enemy_range_end = 100
	
	var ally_range = str(ally_range_start) + "-" + str(ally_range_end)
	var enemy_range = str(enemy_range_start) + "-" + str(enemy_range_end)
	
	return ally_range + "," + enemy_range

# Function to update the Q-table
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

# Function to choose an action based on Q-table
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

# Function to calculate attack damage
func calculate_attack_damage(min_damage, max_damage):
	return randi_range(min_damage, max_damage)

# Function to calculate immediate reward
func calculate_immediate_reward(ally_health, enemy_health):
	var ally_health_lost = 100 - ally_health
	var enemy_health_lost = 100 - enemy_health

	match reward_type:
		REWARD_TYPE_PENALTY:
			return (ally_health_lost + enemy_health_lost) * HEALTH_LOSS_PENALTY
		REWARD_TYPE_REWARD:
			return enemy_health_lost * HEALTH_LOSS_REWARD
		REWARD_TYPE_MIXED:
			return (enemy_health_lost * HEALTH_LOSS_REWARD) - (ally_health_lost * HEALTH_LOSS_PENALTY)
		_:
			return 0  # Default case if reward_type is not set correctly

func calculate_final_reward(won):
	if won == true:
		return WIN_REWARD
	else:
		return LOSE_PENALTY

# Function to serialize state into a string
func serialize_state(state):
	return str(state["ally_health"]) + "_" + str(state["enemy_health"])

# Save the Q-tables at the end of each battle
func save_q_tables():
	ally_combat_number += 1
	enemy_combat_number += 1
	save_q_table_as_json("C:/Godot/Qtables/q_table_ally.json", q_table_ally, ally_combat_number, ally_accumulated_reward)
	save_q_table_as_json("C:/Godot/Qtables/q_table_enemy.json", q_table_enemy, enemy_combat_number, enemy_accumulated_reward)

# Function to save Q-table to a JSON file with combat number
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

# Function to load Q-table from a JSON file and get the combat data
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

# Load the Q-tables at the start of the game
func load_q_tables():
	var ally_data = load_q_table_from_json("C:/Godot/Qtables/q_table_ally.json")
	var enemy_data = load_q_table_from_json("C:/Godot/Qtables/q_table_enemy.json")
	
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

# Function to end the combat with a win
func win_battle():
	print("Ally won the battle!")
	var ally_final_reward = calculate_final_reward(true)
	var enemy_final_reward = calculate_final_reward(false)
	var current_state = get_combat_state(ally_health, enemy_health)
	update_q_table(ally_last_state, ally_last_action, current_state, ally_final_reward, "ally")
	update_q_table(enemy_last_state, enemy_last_action, current_state, enemy_final_reward, "enemy")
	ally_accumulated_reward += ally_final_reward
	enemy_accumulated_reward += enemy_final_reward
	save_q_tables()
	
	print("Ally Q-table:")
	print(q_table_ally)
	print("Enemy Q-table:")
	print(q_table_enemy)

# Function to end the combat with a loss
func lose_battle():
	print("Enemy won the battle!")
	var ally_final_reward = calculate_final_reward(false)
	var enemy_final_reward = calculate_final_reward(true)
	var current_state = get_combat_state(ally_health, enemy_health)
	update_q_table(ally_last_state, ally_last_action, current_state, ally_final_reward, "ally")
	update_q_table(enemy_last_state, enemy_last_action, current_state, enemy_final_reward, "enemy")
	ally_accumulated_reward += ally_final_reward
	enemy_accumulated_reward += enemy_final_reward
	save_q_tables()
	
	print("Ally Q-table:")
	print(q_table_ally)
	print("Enemy Q-table:")
	print(q_table_enemy)
