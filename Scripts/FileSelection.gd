extends Control

@onready var File_Load = $FileDialog
@onready var Ally_Button = $Panel/VBoxContainer2/Ally/AllyTable
@onready var Enemy_Button = $Panel/VBoxContainer2/Enemy/EnemyTable

#var ally_file_path: String = ""
#var enemy_file_path: String = ""
#var use_tables: bool = true
var selecting_for_ally: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	File_Load.connect("file_selected", Callable(self, "_on_file_dialog_file_selected"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_file_dialog_file_selected(path: String):
	var load_file = FileAccess.open(path, FileAccess.READ)
	
	# Determine if we are selecting for the ally or enemy
	if selecting_for_ally:
		State.ally_file_path = path
		Ally_Button.text = "Ally: Selected" # Update button text to file name
	else:
		State.enemy_file_path = path
		Enemy_Button.text = "Enemy: Selected" # Update button text to file name
	
	File_Load.visible = false

func _on_ally_button_pressed():
	selecting_for_ally = true
	File_Load.visible = true  # Show file dialog

func _on_enemy_button_pressed():
	selecting_for_ally = false
	File_Load.visible = true  # Show file dialog

func _on_borderless_toggled(toggled_on):
	if toggled_on == true:
		State.use_tables = true
	else:
		State.use_tables = false
