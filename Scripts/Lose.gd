extends Control

func _on_retry_pressed():
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")


func _on_exit_pressed():
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
