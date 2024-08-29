extends Control

func _on_start_pressed():
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_simulation_pressed():
	pass # Replace with function body.

func _on_settings_pressed():
	pass # Replace with function body.

func _on_exit_pressed():
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
