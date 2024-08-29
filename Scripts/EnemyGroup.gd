extends Node2D

var enemies: Array = []
var index: int = 0
var focusing_enemy = false
var focused_enemy = -1
var enemies_left = true
var combat_node

# Called when the node enters the scene tree for the first time.
func _ready():
	combat_node = get_node("/root/Combat")
	if combat_node and combat_node.has_method("add_enemy_to_scene"):
		await combat_node.Enemies_loaded
	#Here should wait for Combat to populate the group and then instantiate the enemies and do everything else
	enemies = get_children()
	var num_enemies = enemies.size()
	var angle_step = 2 * PI / num_enemies # Calculate the angle step
	var radius = 100 # Base radius from the center
	var center_position = Vector2(0, 0) # Assuming the center of your game area is at (0, 0)
	
	# Adjust the radius or angle step based on the number of allies
	if num_enemies == 2:
		angle_step *= 0.6 # Increase the angle step to ensure they are not on the same y-axis
	
	for i in range(num_enemies):
		var angle = i * angle_step # Calculate the angle for this enemy
		var x = center_position.x + radius * cos(angle) # Calculate the x position
		var y = center_position.y + radius * sin(angle) # Calculate the y position
		enemies[i].position = Vector2(x, y) # Set the enemy's position
	
	# Manually sort enemies based on their Y position
	for i in range(num_enemies):
		for j in range(i + 1, num_enemies):
			if enemies[i].position.y > enemies[j].position.y:
				var temp = enemies[i]
				enemies[i] = enemies[j]
				enemies[j] = temp
	
	# Now, the enemy with the highest Y position is at index 0
	if combat_node and combat_node.has_method("_input"):
		await combat_node.Textbox_closed
	enemies[0].focus()
	focused_enemy = 0
	focusing_enemy = true

func _process(_delta):
	if enemies.size() > 0:
		if focusing_enemy == true:
			if Input.is_action_just_pressed("Up"):
				switch_focus(index - 1)
			if Input.is_action_just_pressed("Down"):
				switch_focus(index + 1)

func show_focus(x):
	#Shows the focus
	if enemies.size() > 0:
		enemies[x].focus()
		focusing_enemy = true

func hide_focus(x):
	#Hides the focus
	if enemies.size() > 0:
		enemies[x].unfocus()
		focusing_enemy = false

#Check for break on only one enemy
func switch_focus(new_index):
	if enemies.size() > 0:
		# Ensure the new index is within the bounds and the enemy is alive
		new_index = clamp(new_index, 0, enemies.size() - 1)
		if is_enemy_alive(new_index):
			enemies[focused_enemy].unfocus()
			focused_enemy = new_index
			enemies[focused_enemy].focus()

# Check if the enemy at a given index is alive
func is_enemy_alive(index):
	return enemies[index] and enemies[index].is_alive

func remove_turn(value):
	await combat_node.remove_from_turn_queue(value)

func player_attack(value):
	if enemies.size() > 0:
		#If the enemy will be killed, kill enemy and remove from array
		if enemies[focused_enemy] and enemies[focused_enemy].current_health - value <= 0:
			#combat_node.display_text("You attack " + enemies[focused_enemy].enemy_name + " for " + str(value) + " damage!")
			#await combat_node.Textbox_closed
			#If enemy is defending, check if survive
			if enemies[focused_enemy].is_defending == true:
				var end_damage = int(round(value-2))
				#Even then he dies
				enemies[focused_enemy].kill_sound.play()
				if enemies[focused_enemy] and enemies[focused_enemy].current_health - value <= 0:
					enemies[focused_enemy].take_damage(value)
					combat_node.display_text("You attack " + enemies[focused_enemy].enemy_name + " for " + str(value) + " damage!")
					await combat_node.Textbox_closed
					combat_node.display_text(enemies[focused_enemy].enemy_name+ " was defeated!")
					await combat_node.Textbox_closed
					remove_turn(enemies[focused_enemy].name)
					enemies.remove_at(focused_enemy)
					focused_enemy = 0
					#If the array is empty the battle is won
					if enemies.size() <= 0:
						enemies_left = false
						if combat_node and combat_node.has_method("win_battle"):
							combat_node.battleover = true
							combat_node.win_battle()
				#He don't die but takes damage
				else:
					combat_node.display_text("You attack " + enemies[focused_enemy].enemy_name + " for " + str(value) + " damage!")
					await combat_node.Textbox_closed
					enemies[focused_enemy].hitBlock_sound.play()
					enemies[focused_enemy].take_damage(end_damage)
					combat_node.display_text(enemies[focused_enemy].enemy_name + " defended and took " + str(end_damage) + " damage!")
					await combat_node.Textbox_closed
			#If not he dies
			else:
				enemies[focused_enemy].take_damage(value)
				enemies[focused_enemy].kill_sound.play()
				combat_node.display_text("You attack " + enemies[focused_enemy].enemy_name + " for " + str(value) + " damage!")
				await combat_node.Textbox_closed
				combat_node.display_text(enemies[focused_enemy].enemy_name+ " was defeated!")
				await combat_node.Textbox_closed
				remove_turn(enemies[focused_enemy].name)
				enemies.remove_at(focused_enemy)
				focused_enemy = 0
				#If the array is empty the battle is won
				if enemies.size() <= 0:
					enemies_left = false
					if combat_node and combat_node.has_method("win_battle"):
						combat_node.battleover = true
						combat_node.win_battle()
		#If the enemy will not be killed, the enemy takes damage
		elif enemies[focused_enemy] and enemies[focused_enemy].has_method("take_damage") and enemies[focused_enemy].is_alive == true:
			#If he's defending he takes less damage
			if enemies[focused_enemy].is_defending == true:
				var end_damage = int(round(value-2))
				combat_node.display_text("You attack " + enemies[focused_enemy].enemy_name + " for " + str(value) + " damage!")
				await combat_node.Textbox_closed
				enemies[focused_enemy].hitBlock_sound.play()
				enemies[focused_enemy].take_damage(end_damage)
				combat_node.display_text(enemies[focused_enemy].enemy_name + " defended and took " + str(end_damage) + " damage!")
				await combat_node.Textbox_closed
			#If not full damage
			else:
				enemies[focused_enemy].hit_sound.play()
				enemies[focused_enemy].take_damage(value)
				combat_node.display_text("You attack " + enemies[focused_enemy].enemy_name + " for " + str(value) + " damage!")
				await combat_node.Textbox_closed

func ally_attack(target_enemy, value):
	if enemies.size() > 0:
		#If the enemy will be killed, kill enemy and remove from array
		if enemies[target_enemy] and enemies[target_enemy].current_health - value <= 0:
			#combat_node.display_text("Witch attacks " + enemies[target_enemy].enemy_name+ ", for %d damage!" % [value])
			#await combat_node.Textbox_closed
			#If enemy is defending, check if survive
			if enemies[target_enemy].is_defending == true:
				var end_damage = int(round(value-2))
				#Even then he dies
				if enemies[target_enemy] and enemies[target_enemy].current_health - value <= 0:
					enemies[target_enemy].take_damage(value)
					enemies[target_enemy].kill_sound.play()
					combat_node.display_text("Witch attacks " + enemies[target_enemy].enemy_name+ ", for %d damage!" % [value])
					await combat_node.Textbox_closed
					combat_node.display_text(enemies[target_enemy].enemy_name+ " was defeated!")
					await combat_node.Textbox_closed
					remove_turn(enemies[target_enemy].name)
					enemies.remove_at(target_enemy)
					focused_enemy = 0
					#If the array is empty the battle is won
					if enemies.size() <= 0:
						enemies_left = false
						if combat_node and combat_node.has_method("win_battle"):
							combat_node.battleover = true
							combat_node.win_battle()
				#He don't die but takes damage
				else:
					combat_node.display_text("You attack " + enemies[focused_enemy].enemy_name + " for " + str(value) + " damage!")
					await combat_node.Textbox_closed
					enemies[target_enemy].hitBlock_sound.play()
					enemies[target_enemy].take_damage(end_damage)
					combat_node.display_text(enemies[target_enemy].enemy_name + " defended and took " + str(end_damage) + " damage!")
					await combat_node.Textbox_closed
			#If not he dies
			else:
				enemies[target_enemy].take_damage(value)
				enemies[target_enemy].kill_sound.play()
				combat_node.display_text("Witch attacks " + enemies[target_enemy].enemy_name+ ", for %d damage!" % [value])
				await combat_node.Textbox_closed
				combat_node.display_text(enemies[target_enemy].enemy_name+ " was defeated!")
				await combat_node.Textbox_closed
				remove_turn(enemies[target_enemy].name)
				enemies.remove_at(target_enemy)
				focused_enemy = 0
				#If the array is empty the battle is won
				if enemies.size() <= 0:
					enemies_left = false
					if combat_node and combat_node.has_method("win_battle"):
						combat_node.battleover = true
						combat_node.win_battle()
		#If the enemy will not be killed, the enemy takes damage
		elif enemies[target_enemy] and enemies[target_enemy].has_method("take_damage") and enemies[target_enemy].is_alive == true:
			#If he's defending he takes less damage
			if enemies[target_enemy].is_defending == true:
				var end_damage = int(round(value-2))
				combat_node.display_text("You attack " + enemies[focused_enemy].enemy_name + " for " + str(value) + " damage!")
				await combat_node.Textbox_closed
				enemies[target_enemy].hitBlock_sound.play()
				enemies[target_enemy].take_damage(end_damage)
				combat_node.display_text(enemies[target_enemy].enemy_name + " defended and took " + str(end_damage) + " damage!")
				await combat_node.Textbox_closed
			#If not full damage
			else:
				enemies[target_enemy].hit_sound.play()
				enemies[target_enemy].take_damage(value)
				combat_node.display_text("Witch attacks " + enemies[target_enemy].enemy_name+ ", dealing %d damage!" % [value])
				await combat_node.Textbox_closed
