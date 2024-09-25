extends Control

@onready var Menu = $MainMenu
@onready var Settings = $Settings
@onready var Video = $Video
@onready var Audio = $Audio
@onready var Agents = $IAAgents
@onready var Tables = $QTables
@onready var Training = $Training
@onready var RewardType = $Training/Panel/VBoxContainer2/Reward/RewardButton
@onready var CombatNumber = $Training/Panel/VBoxContainer2/Number/SpinBox
@onready var Simulation = $Training/Panel/VBoxContainer2/Simulation/Simulate
@onready var FileSelection = $QTables/FileDialog
@onready var TrainText = $Training/Panel/VBoxContainer2/Training

func _ready():
	Menu.visible = true
	Settings.visible = false
	Video.visible = false
	Audio.visible = false
	Agents.visible = false
	Tables.visible = false
	Training.visible = false
	FileSelection.visible = false

func _on_start_pressed():
	await get_tree().create_timer(0.4).timeout
	State.reset_State()
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_settings_pressed():
	Menu.visible = false
	Settings.visible = true
	Video.visible = false

func _on_back_settings_pressed():
	Settings.visible = false
	Menu.visible = true

func _on_exit_pressed():
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _on_video_settings_pressed():
	Audio.visible = false
	Video.visible = true

func _on_save_video_pressed():
	Video.visible = false

func _on_audio_settings_pressed():
	Audio.visible = true
	Video.visible = false

func _on_save_audio_pressed():
	Audio.visible = false

func _on_fullscreen_toggled(toggled_on):
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_borderless_toggled(toggled_on):
	if toggled_on == true:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	else:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

func _on_agents_pressed():
	Menu.visible = false
	Agents.visible = true

func _on_back_agents_pressed():
	Agents.visible = false
	Menu.visible = true

func _on_q_tables_pressed():
	Training.visible = false
	Tables.visible = true

func _on_save_tables_pressed():
	Tables.visible = false

func _on_training_pressed():
	Tables.visible = false
	Training.visible = true

func _on_save_training_pressed():
	Training.visible = false

func _on_simulation_pressed():
	# Get the selected reward type from the Reward Script
	TrainText.visible = true
	await get_tree().create_timer(0.1).timeout
	var selected_reward_type = RewardType.get_selected_reward_type()
	# Start simulation with the selected reward type and number of combats
	Simulation.start_sim(CombatNumber.value, selected_reward_type)
	TrainText.visible = false

func _on_reward_button_item_selected(index):
	# Get the selected reward type from the Reward Script
	await get_tree().create_timer(0.1).timeout
	var selected_reward_type = RewardType.get_selected_reward_type()
	# Change Global Variable for reward type
	State.reward_type = selected_reward_type
