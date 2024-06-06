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
				if index > 0:
					index -= 1
					switch_focus(index, index+1)
			if Input.is_action_just_pressed("Down"):
				if index < enemies.size() - 1:
					index += 1
					switch_focus(index, index - 1)

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

func switch_focus(x,y):
	#Change the focused enemy
	if enemies.size() > 0:
		focused_enemy = x
		enemies[x].focus()
		enemies[y].unfocus()

func remove_turn(value):
	await combat_node.remove_from_turn_queue(value)

func player_attack(value):
	if enemies.size() > 0:
		#If the enemy will be killed, kill enemy and remove from array
		if enemies[focused_enemy] and enemies[focused_enemy].current_health - value <= 0:
			combat_node.display_text(enemies[focused_enemy].enemy_name+ " was defeated!")
			enemies[focused_enemy].take_damage(value)
			remove_turn(enemies[focused_enemy].name)
			enemies.remove_at(focused_enemy)
			focused_enemy = 0
			#If the array is empty the battle is won
			if enemies.size() <= 0:
				enemies_left = false
				if combat_node and combat_node.has_method("win_battle"):
					combat_node.win_battle()
		#If the enemy will not be killed, the enemy takes damage
		elif enemies[focused_enemy] and enemies[focused_enemy].has_method("take_damage") and enemies[focused_enemy].is_alive == true:
			combat_node.display_text("You attack " + enemies[focused_enemy].enemy_name+ ", dealing %d damage!" % [value])
			enemies[focused_enemy].take_damage(value)

func ally_attack(target_enemy, value):
	if enemies.size() > 0:
		#If the enemy will be killed, kill enemy and remove from array
		if enemies[target_enemy] and enemies[target_enemy].current_health - value <= 0:
			combat_node.display_text(enemies[target_enemy].enemy_name+ " was defeated!")
			enemies[target_enemy].take_damage(value)
			remove_turn(enemies[target_enemy].name)
			enemies.remove_at(target_enemy)
			focused_enemy = 0
			#If the array is empty the battle is won
			if enemies.size() <= 0:
				enemies_left = false
				if combat_node and combat_node.has_method("win_battle"):
					combat_node.win_battle()
		#If the enemy will not be killed, the enemy takes damage
		elif enemies[target_enemy] and enemies[target_enemy].has_method("take_damage") and enemies[target_enemy].is_alive == true:
			combat_node.display_text("Witch attacks " + enemies[target_enemy].enemy_name+ ", dealing %d damage!" % [value])
			enemies[target_enemy].take_damage(value)
