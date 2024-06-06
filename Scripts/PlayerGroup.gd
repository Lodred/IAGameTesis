extends Node2D

var allies: Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	allies = get_children()
	var num_allies = allies.size()
	var angle_step = 2 * PI / num_allies # Calculate the angle step
	var radius = 100 # Base radius from the center
	var center_position = Vector2(0, 0) # Assuming the center of your game area is at (0, 0)
	
	# Adjust the radius or angle step based on the number of allies
	if num_allies == 2:
		angle_step *= 0.6 # Increase the angle step to ensure they are not on the same y-axis
	
	for i in range(num_allies):
		var angle = i * angle_step # Calculate the angle for this ally
		var x = center_position.x + radius * cos(angle) # Calculate the x position
		var y = center_position.y + radius * sin(angle) # Calculate the y position
		allies[i].position = Vector2(x, y) # Set the ally's position
